#!/usr/bin/env bash
# axel · wrapper del reviewer (Codex)
#
# Uso:
#   scripts/review.sh new    < pedido   # sesión nueva de reviewer (arranque de fase o feature)
#   scripts/review.sh round  < pedido   # siguiente ronda en la misma sesión (resume)
#   scripts/review.sh status            # estado del loop de review
#
# El pedido del generador entra por stdin (markdown libre: qué se hizo, qué revisar, evidencia).
# Salida: la review completa por stdout. Exit: 0=APPROVED, 1=CHANGES_REQUESTED, 2=error/sin veredicto.
set -euo pipefail

# ── Config del reviewer — tunear SOLO acá cuando cambie el modelo ─────────────
REVIEW_MODEL="${AXEL_REVIEW_MODEL:-gpt-5.6-sol}"
REVIEW_EFFORT="${AXEL_REVIEW_EFFORT:-xhigh}"
REVIEW_SANDBOX="${AXEL_REVIEW_SANDBOX:-workspace-write}"  # puede ejecutar para verificar; no debe tocar el repo

REPO_ROOT="$(git rev-parse --show-toplevel)"
STATE_DIR="$REPO_ROOT/.claude/state"
SESSION_FILE="$STATE_DIR/codex-session-id"
BASE_FILE="$STATE_DIR/last-approved-sha"
ROUND_FILE="$STATE_DIR/round"
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
    echo "últ. veredicto  : $(grep -Eo 'VERDICT: [A-Z_]+' "$MSG_FILE" 2>/dev/null | tail -1 || echo '—')"
    exit 0 ;;
  new|round) ;;
  *) echo "uso: $0 {new|round|status}  (pedido del generador por stdin)" >&2; exit 2 ;;
esac

PEDIDO="$(cat || true)"
if [ -z "$PEDIDO" ]; then
  echo "error: falta el pedido del generador por stdin" >&2
  exit 2
fi

BASE="$(cat "$BASE_FILE" 2>/dev/null || true)"
if [ -n "$BASE" ]; then
  RANGE="$BASE..HEAD"
  LOG="$(git log --oneline "$RANGE")"
  FILES="$(git diff --name-status "$RANGE")"
else
  RANGE="(todo el repo hasta HEAD — primer review)"
  LOG="$(git log --oneline)"
  FILES="$(git ls-files)"
fi

if [ "$MODE" = "new" ]; then
  ROUND=1
else
  ROUND=$(( $(cat "$ROUND_FILE" 2>/dev/null || echo 0) + 1 ))
fi
echo "$ROUND" > "$ROUND_FILE"
if [ "$ROUND" -gt 5 ]; then
  echo "AVISO: ronda $ROUND > 5 — regla de deadlock: considerar RECAP temprano" >&2
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

Reglas: verificá contra los docs de diseño/implementación; podés ejecutar comandos para comprobar (tests, linters, builds), pero NO modifiques el repo (si un comando ensucia el árbol, restauralo). Feedback en puntos numerados y accionables. Terminá tu respuesta con una línea exacta: "VERDICT: APPROVED" o "VERDICT: CHANGES_REQUESTED".
EOF
)"

COMMON_ARGS=( -m "$REVIEW_MODEL"
  -c "model_reasoning_effort=\"$REVIEW_EFFORT\""
  -c "sandbox_mode=\"$REVIEW_SANDBOX\""
  --cd "$REPO_ROOT"
  --json
  -o "$MSG_FILE" )

echo "── review ronda $ROUND · modelo $REVIEW_MODEL · esfuerzo $REVIEW_EFFORT · rango $RANGE ──"
rm -f "$MSG_FILE"
RC=0
if [ "$MODE" = "new" ]; then
  rm -f "$SESSION_FILE"
  codex exec "${COMMON_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1 || RC=$?
  SID="$(grep -m1 -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$EVENTS_FILE" || true)"
  if [ -n "$SID" ]; then
    echo "$SID" > "$SESSION_FILE"
  else
    echo "aviso: no pude capturar el session id; 'round' usará resume --last" >&2
  fi
else
  SID="$(cat "$SESSION_FILE" 2>/dev/null || true)"
  if [ -n "$SID" ]; then
    codex exec resume "$SID" "${COMMON_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1 || RC=$?
  else
    codex exec resume --last "${COMMON_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1 || RC=$?
  fi
fi

if [ ! -s "$MSG_FILE" ]; then
  echo "error: codex no produjo mensaje final (exit $RC); ver $EVENTS_FILE" >&2
  exit 2
fi

echo
cat "$MSG_FILE"
echo

VERDICT="$(grep -Eo 'VERDICT: (APPROVED|CHANGES_REQUESTED)' "$MSG_FILE" | tail -1 || true)"
case "$VERDICT" in
  "VERDICT: APPROVED")
    git rev-parse HEAD > "$BASE_FILE"
    echo "── resultado: APPROVED (base movida a $(git rev-parse --short HEAD)) ──"
    exit 0 ;;
  "VERDICT: CHANGES_REQUESTED")
    echo "── resultado: CHANGES_REQUESTED (ronda $ROUND) ──"
    exit 1 ;;
  *)
    echo "error: el reviewer no emitió veredicto parseable; ver $MSG_FILE" >&2
    exit 2 ;;
esac
