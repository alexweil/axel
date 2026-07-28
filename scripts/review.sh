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
# El reviewer corre sobre un worktree snapshot clavado al commit bajo review, que se resetea en
# cada ronda: su observación queda congelada y el repo canónico fuera de su alcance de escritura.
# Salida: la review completa por stdout. Exit: 0=APPROVED, 1=CHANGES_REQUESTED, 2=error/sin veredicto/deadlock.
# Fallas de proceso de codex (RC≠0 o sin mensaje final) se reintentan una vez en la misma
# ronda (AXEL_REVIEW_RETRIES=0 desactiva); un veredicto inválido no se reintenta.
# Métricas locales por evento en .claude/state/rounds-log (resumen en `status`).
set -euo pipefail

# ── Config del reviewer — tunear SOLO acá cuando cambie el modelo ─────────────
REVIEW_MODEL="${AXEL_REVIEW_MODEL:-gpt-5.6-sol}"
REVIEW_EFFORT="${AXEL_REVIEW_EFFORT:-xhigh}"
REVIEW_SANDBOX="${AXEL_REVIEW_SANDBOX:-workspace-write}"  # escritura confinada al worktree snapshot

# La review no debe cortarse porque la máquina se duerma: caffeinate scoped al proceso de codex
run_codex() {
  if command -v caffeinate >/dev/null 2>&1; then
    caffeinate -is codex "$@"
  else
    codex "$@"
  fi
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
PROJECT_NAME="$(basename "$REPO_ROOT")"
STATE_DIR="$REPO_ROOT/.claude/state"
SESSION_FILE="$STATE_DIR/codex-session-id"
BASE_FILE="$STATE_DIR/last-approved-sha"
ROUND_FILE="$STATE_DIR/round"
STREAK_FILE="$STATE_DIR/changes-streak"
VERDICT_FILE="$STATE_DIR/last-verdict"
MSG_FILE="$STATE_DIR/last-review.md"
EVENTS_FILE="$STATE_DIR/last-review-events.jsonl"
FAILED_EVENTS_FILE="$STATE_DIR/last-review-events.failed.jsonl"
ROUNDS_LOG="$STATE_DIR/rounds-log"
WT_DIR="$STATE_DIR/review-worktree"
TERMINAL_FILE="$STATE_DIR/review-terminal"

mkdir -p "$STATE_DIR"
cd "$REPO_ROOT"

MODE="${1:-}"
case "$MODE" in
  status)
    echo "sesión reviewer : $(cat "$SESSION_FILE" 2>/dev/null || echo '—')"
    echo "base (últ. APPROVED): $(cat "$BASE_FILE" 2>/dev/null || echo '— (primer review)')"
    echo "ronda           : $(cat "$ROUND_FILE" 2>/dev/null || echo 0)"
    echo "racha sin converger : $(cat "$STREAK_FILE" 2>/dev/null || echo 0)"
    echo "últ. resultado validado: $(cat "$VERDICT_FILE" 2>/dev/null || echo '—')"
    # Resumen del ciclo actual, delimitado por la línea que ABRE el último ciclo: el
    # intento 1 (o el INPUT_ERROR) de un `new` — el intento 2 de un retry de `new` NO
    # abre ciclo nuevo, pertenece al mismo. Eventos = líneas · intentos = líneas con
    # intento numérico · rondas = números distintos.
    if [ -s "$ROUNDS_LOG" ]; then
      awk -F'\t' '
        $2 == "new" && ($4 == "1" || $4 == "-") { start = NR }
        { line[NR] = $0 }
        END {
          if (NR == 0) exit
          if (!start) start = 1
          ev = 0; att = 0; nr = 0
          for (i = start; i <= NR; i++) {
            split(line[i], f, "\t"); ev++
            if (f[4] ~ /^[0-9]+$/) att++
            if (f[3] ~ /^[0-9]+$/ && !(f[3] in seen)) { seen[f[3]] = 1; nr++ }
            cnt[f[5]]++
          }
          printf "ciclo actual    : %d ronda(s) · %d intento(s) · %d evento(s)\n", nr, att, ev
          s = ""
          for (k in cnt) s = s k "=" cnt[k] " "
          printf "por resultado   : %s\n", s
        }' "$ROUNDS_LOG"
      echo "últimos eventos :"
      tail -5 "$ROUNDS_LOG" | sed 's/^/  /'
    fi
    exit 0 ;;
  reset-deadlock)
    echo 0 > "$STREAK_FILE"
    echo "racha rearmada: el loop puede continuar tras el desempate humano"
    exit 0 ;;
  new|round) ;;
  *) echo "uso: $0 {new|round|status|reset-deadlock}  (pedido del generador por stdin)" >&2; exit 2 ;;
esac

# ── Señal terminal (contrato del modo lote — docs/design/review-contract.md) ──
# Todo camino de salida de new|round publica, como último acto, un registro terminal
# atómico (tmp + mv en el mismo filesystem) con la identidad de la invocación:
# id (env AXEL_REVIEW_ID, "-" si no vino), modo, ronda, REVIEW_HEAD, resultado y rc.
# Los rechazos pre-invocación (DEADLOCK, INPUT_ERROR) llevan ronda/head en "-";
# una salida no clasificada de set -e queda como ABORTED. status/reset-deadlock y el
# uso inválido no son invocaciones de review: no escriben terminal. Si el terminal no
# puede escribirse, nada más cambia (el lector corta por timeout): jamás altera
# veredicto, estado ni exit code.
TERMINAL_RESULT="ABORTED"
TERMINAL_ROUND="-"
TERMINAL_HEAD="-"
write_terminal() { # $1 = exit code real de la corrida
  local tmp="$STATE_DIR/.review-terminal.tmp.$$"
  {
    printf 'ts=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo -)"
    printf 'id=%s\n' "${AXEL_REVIEW_ID:--}"
    printf 'mode=%s\n' "$MODE"
    printf 'round=%s\n' "$TERMINAL_ROUND"
    printf 'review_head=%s\n' "$TERMINAL_HEAD"
    printf 'result=%s\n' "$TERMINAL_RESULT"
    printf 'rc=%s\n' "$1"
  } > "$tmp" 2>/dev/null && mv -f "$tmp" "$TERMINAL_FILE" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
}
trap 'write_terminal $?' EXIT

# Métricas locales (rounds-log): una línea por evento del loop, con esquema fijo
# fecha·modo·ronda·intento·resultado·sha·racha. Los eventos pre-invocación (DEADLOCK,
# INPUT_ERROR) llevan ronda/intento/sha en "-" y quedan fuera del denominador de intentos.
# Observabilidad local NO autoritativa y best-effort: si el log no puede escribirse se
# avisa por stderr y NADA más cambia — jamás altera veredicto, estado ni exit code.
log_event() { # log_event <resultado> <ronda> <intento> <sha> <racha>
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(date '+%F %T')" "$MODE" "$2" "$3" "$1" "$4" "$5" >> "$ROUNDS_LOG" 2>/dev/null \
    || echo "aviso: no pude escribir $ROUNDS_LOG (métricas locales); el resultado no cambia" >&2
}

# Regla de deadlock: 5 rondas consecutivas sin convergencia bloquean el loop ANTES de gastar otra ronda.
STREAK="$(cat "$STREAK_FILE" 2>/dev/null || echo 0)"
if [ "$MODE" = "new" ]; then
  STREAK=0
  echo 0 > "$STREAK_FILE"
fi
if [ "$STREAK" -ge 5 ]; then
  log_event DEADLOCK - - - "$STREAK"
  TERMINAL_RESULT="DEADLOCK"
  echo "DEADLOCK: $STREAK rondas consecutivas sin convergencia. Armar RECAP con ambas posturas para el humano; tras su desempate, correr: scripts/review.sh reset-deadlock" >&2
  exit 2
fi

PEDIDO="$(cat || true)"
if [ -z "$PEDIDO" ]; then
  # Deja rastro en el log aunque no haya invocación: un `new` con stdin vacío ya abrió el
  # ciclo (racha rearmada) y sin línea propia `status` resumiría el ciclo anterior.
  log_event INPUT_ERROR - - - "$STREAK"
  TERMINAL_RESULT="INPUT_ERROR"
  echo "error: falta el pedido del generador por stdin" >&2
  exit 2
fi

# La review queda clavada al HEAD del momento del pedido, y el reviewer OBSERVA ese
# mismo SHA vía worktree snapshot: commits que aparezcan durante una review larga no
# afectan lo que ve ni quedan aprobados — entran en el próximo rango.
REVIEW_HEAD="$(git rev-parse HEAD)"
REVIEW_HEAD_SHORT="$(git rev-parse --short HEAD)"
TERMINAL_HEAD="$REVIEW_HEAD"

# Worktree snapshot: se crea una vez y se re-clava (reset --hard + clean) en cada ronda,
# lo que además deshace cualquier suciedad que el reviewer haya dejado en la ronda anterior.
#
# CRÍTICO: reset/clean solo si WT_DIR es VERDADERAMENTE el worktree registrado. Un
# directorio común dentro del repo también pasa `rev-parse`, y el reset --hard caería
# sobre el repo canónico. Triple verificación antes de cualquier operación destructiva:
# toplevel == WT_DIR, git-dir bajo .git/worktrees/ del repo, y registrado en worktree list.
wt_valid() {
  [ -d "$WT_DIR" ] || return 1
  local top gitdir
  top="$(git -C "$WT_DIR" rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ "$top" = "$(cd "$WT_DIR" && pwd -P)" ] || return 1
  gitdir="$(git -C "$WT_DIR" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  case "$gitdir" in
    "$REPO_ROOT/.git/worktrees/"*) ;;
    *) return 1 ;;
  esac
  git worktree list --porcelain | grep -Fqx "worktree $top" || return 1
  return 0
}

if wt_valid; then
  git -C "$WT_DIR" reset --hard "$REVIEW_HEAD" >/dev/null
  git -C "$WT_DIR" clean -fdx >/dev/null
else
  rm -rf "$WT_DIR"
  git worktree prune >/dev/null 2>&1 || true
  git worktree add --detach "$WT_DIR" "$REVIEW_HEAD" >/dev/null 2>&1
fi

BASE="$(cat "$BASE_FILE" 2>/dev/null || true)"
if [ -n "$BASE" ]; then
  RANGE="$BASE..$REVIEW_HEAD"
  LOG="$(git log --oneline "$RANGE")"
  FILES="$(git diff --name-status "$RANGE")"
else
  RANGE="(todo el repo hasta $REVIEW_HEAD_SHORT — primer review)"
  LOG="$(git log --oneline "$REVIEW_HEAD")"
  FILES="$(git ls-tree -r --name-only "$REVIEW_HEAD")"
fi

if [ "$MODE" = "new" ]; then
  ROUND=1
else
  ROUND=$(( $(cat "$ROUND_FILE" 2>/dev/null || echo 0) + 1 ))
fi
echo "$ROUND" > "$ROUND_FILE"
TERMINAL_ROUND="$ROUND"
if [ "$STREAK" -ge 4 ]; then
  echo "AVISO: racha de $STREAK sin converger — si esta ronda no converge, se dispara la regla de deadlock" >&2
fi

PROMPT="$(cat <<EOF
Sos el reviewer del proyecto $PROJECT_NAME, desarrollado con el método axel. Ronda de review: $ROUND.
Tu workspace es un worktree snapshot clavado al commit bajo review ($REVIEW_HEAD_SHORT): $WT_DIR
Ahí leés y ejecutás todo lo que necesites; se resetea automáticamente en cada ronda. El repo canónico ($REPO_ROOT) no es tu workspace: no lo modifiques. No corras scripts/review.sh (recursión) ni scripts/awake.sh stop.
Contexto y contrato: leé AGENTS.md, docs/STATUS.md y docs/design/review-contract.md en tu worktree.

Cambios a revisar — rango: $RANGE
$LOG

Archivos del rango:
$FILES

Pedido del generador:
$PEDIDO

Reglas: verificá contra los docs de diseño/implementación; podés ejecutar comandos para comprobar (tests, linters, builds). Feedback en puntos numerados y accionables. La ÚLTIMA línea de tu respuesta debe ser exactamente "VERDICT: APPROVED" o "VERDICT: CHANGES_REQUESTED", sin nada después.
EOF
)"

# resume no acepta --cd: la sesión queda anclada al cwd de su creación, por eso
# new ancla en el worktree (--cd) y las rondas siguientes se invocan desde ahí.
COMMON_ARGS=( -m "$REVIEW_MODEL"
  -c "model_reasoning_effort=\"$REVIEW_EFFORT\""
  -c "sandbox_mode=\"$REVIEW_SANDBOX\""
  --json
  -o "$MSG_FILE" )
NEW_ARGS=( "${COMMON_ARGS[@]}" --cd "$WT_DIR" )

invoke_new() {
  run_codex exec "${NEW_ARGS[@]}" - <<<"$PROMPT" > "$EVENTS_FILE" 2>&1
}
invoke_resume() { # $1 = session id, o --last como último recurso
  (cd "$WT_DIR" && run_codex exec resume "$1" "${COMMON_ARGS[@]}" - <<<"$PROMPT") > "$EVENTS_FILE" 2>&1
}
# El session id es el thread_id del evento thread.started — nunca "el primer UUID del
# archivo": los eventos mezclan el stderr de codex, y un UUID espurio en una línea de
# error capturaría una sesión falsa. Sin thread.started no hay id (aviso; resume --last).
capture_sid() {
  SID="$(awk -F'"thread_id":"' '/"type":"thread.started"/ && NF > 1 { split($2, a, "\""); print a[1]; exit }' "$EVENTS_FILE" 2>/dev/null || true)"
  if [ -n "$SID" ]; then
    echo "$SID" > "$SESSION_FILE"
  else
    echo "aviso: no pude capturar el session id; 'round' usará resume --last" >&2
  fi
}
proc_ok() { [ "$RC" -eq 0 ] && [ -s "$MSG_FILE" ]; }

echo "── review ronda $ROUND · modelo $REVIEW_MODEL · esfuerzo $REVIEW_EFFORT · rango $RANGE ──"
rm -f "$MSG_FILE"
RC=0
ATTEMPT=1
if [ "$MODE" = "new" ]; then
  rm -f "$SESSION_FILE"
  invoke_new || RC=$?
  capture_sid   # también tras un intento fallido: si alcanzó a emitir thread.started, la sesión existe
else
  SID="$(cat "$SESSION_FILE" 2>/dev/null || true)"
  invoke_resume "${SID:---last}" || RC=$?
fi

# Reintento único ante FALLA DE PROCESO (RC≠0, o mensaje final ausente/vacío), en la misma
# ronda. Un mensaje bien entregado con veredicto inválido NO es transitorio: no se reintenta.
RETRIES="${AXEL_REVIEW_RETRIES:-1}"
if ! proc_ok && [ "$RETRIES" -ge 1 ]; then
  echo "aviso: falla de proceso de codex (exit $RC$([ -s "$MSG_FILE" ] || echo ', sin mensaje final')); reintento único en la misma ronda — eventos del intento fallido en $FAILED_EVENTS_FILE" >&2
  log_event PROC_FAIL "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT" "$STREAK"
  mv -f "$EVENTS_FILE" "$FAILED_EVENTS_FILE" 2>/dev/null || true
  rm -f "$MSG_FILE"
  RC=0
  ATTEMPT=2
  if [ "$MODE" = "new" ]; then
    # Frontera de contexto: con thread_id capturado se reanuda ESA sesión exacta; sin él
    # se lanza un exec nuevo — jamás resume --last, que podría retomar la sesión del
    # feature anterior.
    SID="$(cat "$SESSION_FILE" 2>/dev/null || true)"
    if [ -n "$SID" ]; then
      invoke_resume "$SID" || RC=$?
    else
      invoke_new || RC=$?
      capture_sid
    fi
  else
    invoke_resume "${SID:---last}" || RC=$?
  fi
fi

# Un error de codex invalida la corrida aunque haya quedado un mensaje escrito: no se toma veredicto.
if [ "$RC" -ne 0 ]; then
  log_event PROC_FAIL "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT" "$STREAK"
  TERMINAL_RESULT="PROC_FAIL"
  echo "error: codex terminó con exit $RC; no se toma veredicto. Ver $EVENTS_FILE" >&2
  exit 2
fi
if [ ! -s "$MSG_FILE" ]; then
  log_event PROC_FAIL "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT" "$STREAK"
  TERMINAL_RESULT="PROC_FAIL"
  echo "error: codex no produjo mensaje final; ver $EVENTS_FILE" >&2
  exit 2
fi

echo
cat "$MSG_FILE"
echo

# Contrato estricto: el veredicto es la ÚLTIMA línea no vacía del mensaje, comparada literalmente.
# El resultado validado se persiste aparte (last-verdict); status jamás parsea el mensaje crudo.
VERDICT="$(awk 'NF {line=$0} END {print line}' "$MSG_FILE" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
case "$VERDICT" in
  "VERDICT: APPROVED")
    echo "$REVIEW_HEAD" > "$BASE_FILE"
    echo 0 > "$STREAK_FILE"
    echo "APPROVED · ronda $ROUND · $REVIEW_HEAD_SHORT · $(date +%F)" > "$VERDICT_FILE"
    log_event APPROVED "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT" 0
    TERMINAL_RESULT="APPROVED"
    echo "── resultado: APPROVED (base movida a $REVIEW_HEAD_SHORT) ──"
    if [ "$(git rev-parse HEAD)" != "$REVIEW_HEAD" ]; then
      echo "AVISO: hay commits posteriores a $REVIEW_HEAD_SHORT hechos durante la review — NO están aprobados; entran en el próximo rango" >&2
    fi
    exit 0 ;;
  "VERDICT: CHANGES_REQUESTED")
    echo "$((STREAK + 1))" > "$STREAK_FILE"
    echo "CHANGES_REQUESTED · ronda $ROUND · racha $((STREAK + 1)) · $(date +%F)" > "$VERDICT_FILE"
    log_event CHANGES_REQUESTED "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT" "$((STREAK + 1))"
    TERMINAL_RESULT="CHANGES_REQUESTED"
    echo "── resultado: CHANGES_REQUESTED (ronda $ROUND, racha $((STREAK + 1))) ──"
    exit 1 ;;
  *)
    log_event NO_VERDICT "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT" "$STREAK"
    TERMINAL_RESULT="NO_VERDICT"
    echo "error: la última línea del mensaje no es un veredicto válido (\"$VERDICT\"); ver $MSG_FILE" >&2
    exit 2 ;;
esac
