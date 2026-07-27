#!/usr/bin/env bash
# axel · wrapper del reviewer (Codex)
#
# Uso:
#   scripts/review.sh new            < pedido   # sesión nueva de reviewer (arranque de fase o feature)
#   scripts/review.sh round          < pedido   # siguiente ronda en la misma sesión (resume)
#   scripts/review.sh status                    # estado del loop de review
#   scripts/review.sh reset-deadlock            # rearma la racha tras un desempate humano
#
# El pedido del generador entra por stdin (markdown libre: qué se hizo, qué revisar, evidencia).
# Salida: la review completa por stdout. Exit: 0=APPROVED, 1=CHANGES_REQUESTED, 2=error/sin veredicto.
set -euo pipefail

# ── Config del reviewer — tunear SOLO acá cuando cambie el modelo ─────────────
REVIEW_MODEL="${AXEL_REVIEW_MODEL:-gpt-5.6-sol}"
REVIEW_EFFORT="${AXEL_REVIEW_EFFORT:-xhigh}"
REVIEW_SANDBOX="${AXEL_REVIEW_SANDBOX:-workspace-write}"  # puede ejecutar para verificar; no debe tocar el repo

# La review no debe cortarse porque la máquina se duerma: caffeinate scoped al proceso de codex
run_codex() {
  if command -v caffeinate >/dev/null 2>&1; then
    caffeinate -is codex "$@"
  else
    codex "$@"
  fi
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
STATE_DIR="$REPO_ROOT/.claude/state"
SESSION_FILE="$STATE_DIR/codex-session-id"
BASE_FILE="$STATE_DIR/last-approved-sha"
ROUND_FILE="$STATE_DIR/round"
STREAK_FILE="$STATE_DIR/changes-streak"
MSG_FILE="$STATE_DIR/last-review.md"
EVENTS_FILE="$STATE_DIR/last-review-events.jsonl"

mkdir -p "$STATE_DIR"
cd "$REPO_ROOT"

MODE="${1:-}"
case "$MODE" in
  status)
    echo "sesión reviewer : $(cat "$SESSION_FILE" 2>/dev/null || echo '—')"
    echo "base (últ. APPROVED): $(cat "$BASE_FILE" 2>/dev/null || echo '— (primer review)')"
    echo "ronda           : $(cat "$ROUND_FILE" 2>/dev/null || echo 0)"
    echo "racha sin converger : $(cat "$STREAK_FILE" 2>/dev/null || echo 0)"
    echo "últ. veredicto  : $(grep -Eo 'VERDICT: [A-Z_]+' "$MSG_FILE" 2>/dev/null | tail -1 || echo '—')"
    exit 0 ;;
  reset-deadlock)
    echo 0 > "$STREAK_FILE"
    echo "racha rearmada: el loop puede continuar tras el desempate humano"
    exit 0 ;;
  new|round) ;;
  *) echo "uso: $0 {new|round|status|reset-deadlock}  (pedido del generador por stdin)" >&2; exit 2 ;;
esac

# Regla de deadlock: 5 rondas consecutivas sin convergencia bloquean el loop ANTES de gastar otra ronda.
STREAK="$(cat "$STREAK_FILE" 2>/dev/null || echo 0)"
if [ "$MODE" = "new" ]; then
  STREAK=0
  echo 0 > "$STREAK_FILE"
fi
if [ "$STREAK" -ge 5 ]; then
  echo "DEADLOCK: $STREAK rondas consecutivas sin convergencia. Armar RECAP con ambas posturas para el humano; tras su desempate, correr: scripts/review.sh reset-deadlock" >&2
  exit 2
fi

PEDIDO="$(cat || true)"
if [ -z "$PEDIDO" ]; then
  echo "error: falta el pedido del generador por stdin" >&2
  exit 2
fi

# La review queda clavada al HEAD del momento del pedido: commits que aparezcan
# durante una review larga NO quedan aprobados — entran en el próximo rango.
REVIEW_HEAD="$(git rev-parse HEAD)"
BASE="$(cat "$BASE_FILE" 2>/dev/null || true)"
if [ -n "$BASE" ]; then
  RANGE="$BASE..$REVIEW_HEAD"
  LOG="$(git log --oneline "$RANGE")"
  FILES="$(git diff --name-status "$RANGE")"
else
  RANGE="(todo el repo hasta $REVIEW_HEAD — primer review)"
  LOG="$(git log --oneline "$REVIEW_HEAD")"
  FILES="$(git ls-tree -r --name-only "$REVIEW_HEAD")"
fi

if [ "$MODE" = "new" ]; then
  ROUND=1
else
  ROUND=$(( $(cat "$ROUND_FILE" 2>/dev/null || echo 0) + 1 ))
fi
echo "$ROUND" > "$ROUND_FILE"
if [ "$STREAK" -ge 4 ]; then
  echo "AVISO: racha de $STREAK sin converger — si esta ronda no converge, se dispara la regla de deadlock" >&2
fi

PROMPT="$(cat <<EOF
Sos el reviewer del proyecto axel (repo: $REPO_ROOT). Ronda de review: $ROUND.
Contexto y contrato: leé AGENTS.md, docs/STATUS.md y docs/design/review-contract.md.

Cambios a revisar — rango: $RANGE
$LOG

Archivos del rango:
$FILES

Pedido del generador:
$PEDIDO

Reglas: verificá contra los docs de diseño/implementación; podés ejecutar comandos para comprobar (tests, linters, builds), pero NO modifiques el repo (si un comando ensucia el árbol, restauralo). Feedback en puntos numerados y accionables. La ÚLTIMA línea de tu respuesta debe ser exactamente "VERDICT: APPROVED" o "VERDICT: CHANGES_REQUESTED", sin nada después.
EOF
)"

# resume no acepta --cd; el cwd correcto lo garantiza el cd de arriba
COMMON_ARGS=( -m "$REVIEW_MODEL"
  -c "model_reasoning_effort=\"$REVIEW_EFFORT\""
  -c "sandbox_mode=\"$REVIEW_SANDBOX\""
  --json
  -o "$MSG_FILE" )
NEW_ARGS=( "${COMMON_ARGS[@]}" --cd "$REPO_ROOT" )

echo "── review ronda $ROUND · modelo $REVIEW_MODEL · esfuerzo $REVIEW_EFFORT · rango $RANGE ──"
rm -f "$MSG_FILE"
RC=0
if [ "$MODE" = "new" ]; then
  rm -f "$SESSION_FILE"
  run_codex exec "${NEW_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1 || RC=$?
  SID="$(grep -m1 -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$EVENTS_FILE" || true)"
  if [ -n "$SID" ]; then
    echo "$SID" > "$SESSION_FILE"
  else
    echo "aviso: no pude capturar el session id; 'round' usará resume --last" >&2
  fi
else
  SID="$(cat "$SESSION_FILE" 2>/dev/null || true)"
  if [ -n "$SID" ]; then
    run_codex exec resume "$SID" "${COMMON_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1 || RC=$?
  else
    run_codex exec resume --last "${COMMON_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1 || RC=$?
  fi
fi

# Un error de codex invalida la corrida aunque haya quedado un mensaje escrito: no se toma veredicto.
if [ "$RC" -ne 0 ]; then
  echo "error: codex terminó con exit $RC; no se toma veredicto. Ver $EVENTS_FILE" >&2
  exit 2
fi
if [ ! -s "$MSG_FILE" ]; then
  echo "error: codex no produjo mensaje final; ver $EVENTS_FILE" >&2
  exit 2
fi

echo
cat "$MSG_FILE"
echo

# Contrato estricto: el veredicto es la ÚLTIMA línea no vacía del mensaje, comparada literalmente.
VERDICT="$(awk 'NF {line=$0} END {print line}' "$MSG_FILE" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
case "$VERDICT" in
  "VERDICT: APPROVED")
    echo "$REVIEW_HEAD" > "$BASE_FILE"
    echo 0 > "$STREAK_FILE"
    echo "── resultado: APPROVED (base movida a $(git rev-parse --short "$REVIEW_HEAD")) ──"
    if [ "$(git rev-parse HEAD)" != "$REVIEW_HEAD" ]; then
      echo "AVISO: hay commits posteriores a $(git rev-parse --short "$REVIEW_HEAD") hechos durante la review — NO están aprobados; entran en el próximo rango" >&2
    fi
    exit 0 ;;
  "VERDICT: CHANGES_REQUESTED")
    echo "$((STREAK + 1))" > "$STREAK_FILE"
    echo "── resultado: CHANGES_REQUESTED (ronda $ROUND, racha $((STREAK + 1))) ──"
    exit 1 ;;
  *)
    echo "error: la última línea del mensaje no es un veredicto válido (\"$VERDICT\"); ver $MSG_FILE" >&2
    exit 2 ;;
esac
