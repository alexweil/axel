#!/usr/bin/env bash
# axel · suite de regresión del loop de review (sin invocar agentes reales)
# Congela las siete clases de falla que el ciclo 00 encontró a mano (docs/implementation/03-loop-hardening.md):
# L1 parser de veredicto + gate de RC · L2 estado resultado vs ciclo · L3 deadlock ·
# L4 wt_valid contra impostores · L5 tri-estado y kill_confirmed de awake.sh ·
# L6 base a REVIEW_HEAD · L7 observación congelada.
# Dobles por PATH: codex (guion secuencial), caffeinate (passthrough), pmset (dinámico por vida del pid).
# Los fixtures viven en mktemp y review.sh/awake.sh se invocan SIEMPRE con cwd dentro del fixture:
# el repo axel real jamás participa. Exit 0 = toda la matriz en verde.
set -euo pipefail

# Hermeticidad del entorno: la suite setea los overrides que necesita POR CASO (L2 modelo/
# esfuerzo, L8 retries, L9–L11 el id de invocación). Un AXEL_REVIEW_* heredado del shell
# rompe justamente los casos que verifican el default — y el shell típico es el de una review
# de lote, donde review.sh corre con AXEL_REVIEW_ID seteado (L10 falla ahí si no se limpia).
unset AXEL_REVIEW_MODEL AXEL_REVIEW_EFFORT AXEL_REVIEW_SANDBOX AXEL_REVIEW_RETRIES AXEL_REVIEW_ID

AXEL_REAL="$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)"
TESTS_TMP="$(mktemp -d "${TMPDIR:-/tmp}/axel-loop-tests.XXXXXX")"
TESTS_TMP="$(cd "$TESTS_TMP" && pwd -P)"   # canónico: los paths de `git worktree list` se comparan literales

# ── Limpieza: ningún proceso de la suite sobrevive a la corrida ───────────────
CLEANUP_PIDS=""
note_pid() { CLEANUP_PIDS="$CLEANUP_PIDS $1"; }
cleanup() {
  local p
  for p in $CLEANUP_PIDS; do kill -9 "$p" 2>/dev/null || true; done
  rm -rf "$TESTS_TMP"
}
trap cleanup EXIT

# ── Arnés ─────────────────────────────────────────────────────────────────────
PASS=0; FAIL=0; CURRENT=""
t() { CURRENT="$1"; }
ok() { PASS=$((PASS + 1)); }
ko() { FAIL=$((FAIL + 1)); echo "FAIL [$CURRENT] $1" >&2; }
assert_rc()   { [ "$RC" -eq "$1" ] && ok || ko "exit esperado $1, fue $RC · salida: $(echo "$OUT" | tail -3 | tr '\n' ' ')"; }
assert_out()  { printf '%s' "$OUT" | grep -qF "$1" && ok || ko "'$1' no está en la salida: $(echo "$OUT" | tail -3 | tr '\n' ' ')"; }
assert_eq()   { [ "$1" = "$2" ] && ok || ko "${3:-valor}: esperado '$2', fue '$1'"; }
assert_file() { [ -f "$1" ] && ok || ko "falta archivo: $1"; }
assert_no()   { { [ ! -e "$1" ] && [ ! -L "$1" ]; } && ok || ko "no debería existir: $1"; }
assert_alive() { kill -0 "$1" 2>/dev/null && ok || ko "pid $1 debería estar vivo"; }
assert_dead()  { kill -0 "$1" 2>/dev/null && ko "pid $1 debería estar muerto" || ok; }
wait_dead()    { for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$1" 2>/dev/null || return 0; sleep 0.2; done; return 1; }

# ── Dobles por PATH ───────────────────────────────────────────────────────────
STUBS="$TESTS_TMP/stubs"
mkdir -p "$STUBS"

# codex: guion secuencial por invocación (FAKE_CODEX_PLAN/N.{rc,msg,events,hook});
# las env escalares (FAKE_CODEX_RC/MSG/EVENTS/SID/HOOK) son el caso degenerado de un intento.
# Registra argv + stdin de cada invocación para los asserts. MSG "@none" ⇒ no escribe el -o.
cat > "$STUBS/codex" <<'STUB'
#!/usr/bin/env bash
LOG="${FAKE_CODEX_LOG:?FAKE_CODEX_LOG requerido}"
N=$(( $(cat "$LOG.count" 2>/dev/null || echo 0) + 1 ))
echo "$N" > "$LOG.count"
{ printf 'CALL %s ARGV:' "$N"; printf ' %q' "$@"; printf '\n'; } >> "$LOG"
cat > "$LOG.stdin.$N" || true

plan_file() {
  f="${FAKE_CODEX_PLAN:-}/$N.$1"
  if [ -n "${FAKE_CODEX_PLAN:-}" ] && [ -f "$f" ]; then printf '%s' "$f"; fi
}

RC="${FAKE_CODEX_RC:-0}"
pf="$(plan_file rc)"; [ -n "$pf" ] && RC="$(cat "$pf")"

MSG="${FAKE_CODEX_MSG-VERDICT: APPROVED}"
pf="$(plan_file msg)"; [ -n "$pf" ] && MSG="$(cat "$pf")"
OUT_FILE=""; prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && OUT_FILE="$a"
  prev="$a"
done
if [ -n "$OUT_FILE" ] && [ "$MSG" != "@none" ]; then
  printf '%s' "$MSG" > "$OUT_FILE"
fi

pf="$(plan_file events)"
if [ -n "$pf" ]; then
  cat "$pf"
elif [ -n "${FAKE_CODEX_EVENTS:-}" ]; then
  printf '%s\n' "$FAKE_CODEX_EVENTS"
else
  # fixture con la forma real: línea de stderr mezclada + thread.started con el id
  printf '%s\n' '2026-07-28T01:15:19.644843Z ERROR codex_models_manager::cache: failed to load models cache'
  printf '{"type":"thread.started","thread_id":"%s"}\n' "${FAKE_CODEX_SID:-aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee}"
  printf '{"type":"turn.started"}\n'
fi

pf="$(plan_file hook)"
if [ -n "$pf" ]; then bash "$pf"
elif [ -n "${FAKE_CODEX_HOOK:-}" ]; then bash "$FAKE_CODEX_HOOK"
fi

exit "$RC"
STUB

# caffeinate: passthrough — saltea flags (y el argumento de -t) y ejecuta el resto;
# sin comando, vive como el real (backstop 1h). FAKE_CAFFEINATE_IGNORE_TERM=1 simula
# un proceso que ignora TERM (para el camino "la señal no surtió efecto").
cat > "$STUBS/caffeinate" <<'STUB'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
  case "$1" in
    -t) shift 2 ;;
    -*) shift ;;
    *) break ;;
  esac
done
if [ $# -gt 0 ]; then exec "$@"; fi
if [ -n "${FAKE_CAFFEINATE_IGNORE_TERM:-}" ]; then
  trap '' TERM
  n=0; while [ "$n" -lt 3600 ]; do sleep 1; n=$((n+1)); done
  exit 0
fi
exec sleep 3600
STUB

# pmset: track = salida base SIEMPRE no vacía (como el real) + línea de assertion solo
# mientras el pid del pidfile vive — la muerte se ve como "sin match", no como mudez
# (mudez ⇒ check() caería al fallback y daría indeterminado, no muerte confirmada).
# absent = sin salida y rc 1 (pmset no disponible).
cat > "$STUBS/pmset" <<'STUB'
#!/usr/bin/env bash
case "${FAKE_PMSET_MODE:-track}" in
  absent) exit 1 ;;
  track)
    echo "Assertion status system-wide:"
    echo "   PreventUserIdleSystemSleep     0"
    echo "Listed by owning process:"
    pf="${FAKE_PMSET_PIDFILE:-}"
    if [ -n "$pf" ] && [ -f "$pf" ]; then
      pid="$(cat "$pf" 2>/dev/null || true)"
      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo "   pid ${pid}(caffeinate): [0x0001] 00:00:01 PreventUserIdleSystemSleep named: \"caffeinate command-line tool\""
      fi
    fi
    ;;
  *) exit 1 ;;
esac
STUB
# ps: con FAKE_PS_COMM imprime ese comm (congela el fallback de awake.sh de forma
# determinista, inmune a sandboxes que niegan ps); sin la variable, delega en el real.
cat > "$STUBS/ps" <<'STUB'
#!/usr/bin/env bash
if [ -n "${FAKE_PS_COMM:-}" ]; then
  printf '%s\n' "$FAKE_PS_COMM"
  exit 0
fi
exec /bin/ps "$@"
STUB
chmod +x "$STUBS/codex" "$STUBS/caffeinate" "$STUBS/pmset" "$STUBS/ps"

CODEX_LOG="$TESTS_TMP/codex.log"
export FAKE_CODEX_LOG="$CODEX_LOG"
codex_reset() { rm -f "$CODEX_LOG" "$CODEX_LOG.count" "$CODEX_LOG".stdin.* 2>/dev/null || true; }
codex_calls() { awk '/^CALL /{n++} END{print n+0}' "$CODEX_LOG" 2>/dev/null || echo 0; }
codex_argv()  { grep "^CALL $1 ARGV:" "$CODEX_LOG"; }
codex_stdin() { cat "$CODEX_LOG.stdin.$1"; }

# ── Fixtures y runners ────────────────────────────────────────────────────────
# Repo de fixture: los scripts bajo prueba copiados del working tree de axel + contenido mínimo.
mk_repo() {
  local r="$TESTS_TMP/$1"
  mkdir -p "$r/scripts" "$r/docs"
  cp "$AXEL_REAL/scripts/review.sh" "$r/scripts/review.sh"
  cp "$AXEL_REAL/scripts/awake.sh"  "$r/scripts/awake.sh"
  chmod +x "$r/scripts/review.sh" "$r/scripts/awake.sh"
  echo ".claude/state/" > "$r/.gitignore"
  echo "contenido original" > "$r/observed.txt"
  echo "doc" > "$r/docs/README.md"
  git -C "$r" init -q -b main
  git -C "$r" add -A
  git -C "$r" -c user.email=t@t -c user.name=t commit -qm base
  printf '%s' "$r"
}
tcommit() { git -C "$1" add -A; git -C "$1" -c user.email=t@t -c user.name=t commit -qm "${2:-paso}"; }

OUT=""; RC=0
run_review() { # run_review <repo> <modo> [pedido]  — cwd dentro del fixture, dobles por PATH
  local repo="$1" mode="$2" pedido="${3-}"
  OUT="$(cd "$repo" && printf '%s' "$pedido" \
        | PATH="$STUBS:$PATH" FAKE_PMSET_PIDFILE="$repo/.claude/state/caffeinate-pid" \
          scripts/review.sh "$mode" 2>&1)" && RC=0 || RC=$?
}
run_awake() { # run_awake <repo> <args...>
  local repo="$1"; shift
  OUT="$(cd "$repo" && PATH="$STUBS:$PATH" FAKE_PMSET_PIDFILE="$repo/.claude/state/caffeinate-pid" \
        scripts/awake.sh "$@" 2>&1)" && RC=0 || RC=$?
}

st() { cat "$1/.claude/state/$2" 2>/dev/null || echo "__ABSENT__"; }
# huella del estado de RESULTADO (base · racha · last-verdict): lo que ninguna salida 2 puede tocar
result_state() { printf '%s|%s|%s' "$(st "$1" last-approved-sha)" "$(st "$1" changes-streak)" "$(st "$1" last-verdict)"; }

# ── L1 · parser de veredicto + gate de RC (r1.1 del ciclo 00) ─────────────────
t "L1 APPROVED mueve base y escribe last-verdict"
R1="$(mk_repo l1)"
codex_reset
FAKE_CODEX_MSG=$'Todo bien.\n\nVERDICT: APPROVED' run_review "$R1" new "pedido de arranque"
assert_rc 0
assert_out "resultado: APPROVED"
assert_eq "$(st "$R1" last-approved-sha)" "$(git -C "$R1" rev-parse HEAD)" "base"
assert_eq "$(st "$R1" changes-streak)" "0" "racha"
assert_eq "$(st "$R1" round)" "1" "ronda"
case "$(st "$R1" last-verdict)" in "APPROVED · ronda 1"*) ok ;; *) ko "last-verdict inesperado: $(st "$R1" last-verdict)" ;; esac

t "L1 CHANGES_REQUESTED incrementa racha sin mover base"
BASE_L1="$(st "$R1" last-approved-sha)"
echo r2 >> "$R1/docs/README.md"; tcommit "$R1"
FAKE_CODEX_MSG=$'1. Punto.\n\nVERDICT: CHANGES_REQUESTED' run_review "$R1" round "correcciones"
assert_rc 1
assert_out "resultado: CHANGES_REQUESTED"
assert_eq "$(st "$R1" changes-streak)" "1" "racha"
assert_eq "$(st "$R1" last-approved-sha)" "$BASE_L1" "base intacta"
assert_eq "$(st "$R1" round)" "2" "ronda"
case "$(st "$R1" last-verdict)" in "CHANGES_REQUESTED · ronda 2"*) ok ;; *) ko "last-verdict inesperado: $(st "$R1" last-verdict)" ;; esac

t "L1 veredicto en el medio no cuenta"
RS_L1="$(result_state "$R1")"
FAKE_CODEX_MSG=$'VERDICT: APPROVED\ny un agregado después' run_review "$R1" round p
assert_rc 2
assert_out "no es un veredicto válido"
assert_eq "$(result_state "$R1")" "$RS_L1" "estado de resultado"

t "L1 comparación literal: sufijo, minúsculas, prefijo, sin espacio"
for m in 'VERDICT: APPROVED.' 'verdict: approved' 'EL VERDICT: APPROVED' 'VERDICT:APPROVED'; do
  FAKE_CODEX_MSG="$m" run_review "$R1" round p
  assert_rc 2
done
assert_eq "$(result_state "$R1")" "$RS_L1" "estado de resultado"

t "L1 tolerancia: espacios y CRLF alrededor de la última línea"
echo r3 >> "$R1/docs/README.md"; tcommit "$R1"
FAKE_CODEX_MSG=$'ok\n  VERDICT: APPROVED  \r\n\n' run_review "$R1" round p
assert_rc 0
assert_eq "$(st "$R1" last-approved-sha)" "$(git -C "$R1" rev-parse HEAD)" "base"

t "L1 gate de RC: codex muere y el mensaje escrito no cuenta"
RS_L1="$(result_state "$R1")"
SID_L1="$(st "$R1" codex-session-id)"
FAKE_CODEX_RC=7 FAKE_CODEX_MSG=$'VERDICT: APPROVED' run_review "$R1" round p
assert_rc 2
assert_out "codex terminó con exit 7"
assert_eq "$(result_state "$R1")" "$RS_L1" "estado de resultado"
assert_eq "$(st "$R1" codex-session-id)" "$SID_L1" "SID intacto"

t "L1 mensaje ausente y mensaje vacío"
FAKE_CODEX_MSG=@none run_review "$R1" round p
assert_rc 2
assert_out "no produjo mensaje final"
FAKE_CODEX_MSG='' run_review "$R1" round p
assert_rc 2
assert_eq "$(result_state "$R1")" "$RS_L1" "estado de resultado"

t "L1 pedido vacío: rechazo pre-invocación"
CALLS_L1="$(codex_calls)"
run_review "$R1" round ""
assert_rc 2
assert_out "falta el pedido"
assert_eq "$(codex_calls)" "$CALLS_L1" "codex no invocado"

# ── L2 · estado de resultado vs estado de ciclo (r2.2) ────────────────────────
t "L2 new captura el session id de los eventos"
R2="$(mk_repo l2)"
codex_reset
FAKE_CODEX_SID="aaaaaaaa-1111-4111-8111-111111111111" run_review "$R2" new p
assert_rc 0
assert_eq "$(st "$R2" codex-session-id)" "aaaaaaaa-1111-4111-8111-111111111111" "SID capturado"
codex_argv 1 | grep -q ' resume ' && ko "new no debería resumir" || ok
codex_argv 1 | grep -q -- '--cd' && ok || ko "new sin --cd al worktree"

t "L2 round resume con el SID guardado"
BASE_L2="$(st "$R2" last-approved-sha)"
FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$R2" round p
assert_rc 1
codex_argv 2 | grep -q 'exec resume aaaaaaaa-1111-4111-8111-111111111111' && ok || ko "argv sin resume del SID: $(codex_argv 2)"

t "L2 round fallido: resultado y SID intactos, ronda consumida"
RS_L2="$(result_state "$R2")"
FAKE_CODEX_RC=1 run_review "$R2" round p
assert_rc 2
assert_eq "$(result_state "$R2")" "$RS_L2" "estado de resultado"
assert_eq "$(st "$R2" codex-session-id)" "aaaaaaaa-1111-4111-8111-111111111111" "SID intacto"
assert_eq "$(st "$R2" round)" "3" "ronda consumida"

t "L2 round con stdin vacío: ni siquiera consume ronda"
run_review "$R2" round ""
assert_rc 2
assert_eq "$(st "$R2" round)" "3" "ronda intacta"
assert_eq "$(result_state "$R2")" "$RS_L2" "estado de resultado"

t "L2 status muestra solo el último resultado validado"
FAKE_CODEX_MSG=$'cuerpo que dice VERDICT: APPROVED en el medio\núltima línea que no es veredicto' run_review "$R2" round p
assert_rc 2
run_review "$R2" status
assert_rc 0
assert_out "CHANGES_REQUESTED · ronda 2"

t "L2 new fallido con thread.started: racha rearmada, SID recapturado, ronda 1"
assert_eq "$(st "$R2" changes-streak)" "1" "precondición: racha 1"
FAKE_CODEX_RC=9 FAKE_CODEX_SID="bbbbbbbb-2222-4222-8222-222222222222" run_review "$R2" new p
assert_rc 2
assert_eq "$(st "$R2" changes-streak)" "0" "racha rearmada por la apertura, aunque falló"
assert_eq "$(st "$R2" codex-session-id)" "bbbbbbbb-2222-4222-8222-222222222222" "SID del intento fallido recapturado"
assert_eq "$(st "$R2" round)" "1" "la apertura escribió ronda 1"
assert_eq "$(st "$R2" last-approved-sha)" "$BASE_L2" "base intacta"
case "$(st "$R2" last-verdict)" in "CHANGES_REQUESTED · ronda 2"*) ok ;; *) ko "last-verdict debió quedar intacto: $(st "$R2" last-verdict)" ;; esac

t "L2 new fallido sin UUID en los eventos: sin session file y con aviso"
FAKE_CODEX_RC=9 FAKE_CODEX_EVENTS='{"type":"error","message":"sin thread"}' run_review "$R2" new p
assert_rc 2
assert_eq "$(st "$R2" codex-session-id)" "__ABSENT__" "sin session file"
assert_out "no pude capturar el session id"

t "L2 round sin session file cae a resume --last"
run_review "$R2" round p
assert_rc 0
codex_argv "$(codex_calls)" | grep -q 'exec resume --last' && ok || ko "sin resume --last: $(codex_argv "$(codex_calls)")"

t "L2 overrides AXEL_REVIEW_MODEL/EFFORT llegan al argv"
AXEL_REVIEW_MODEL=modelo-x AXEL_REVIEW_EFFORT=low run_review "$R2" round p
assert_rc 0
codex_argv "$(codex_calls)" | grep -q -- '-m modelo-x' && ok || ko "sin -m modelo-x"
codex_argv "$(codex_calls)" | grep -qE 'model_reasoning_effort[^ ]*low' && ok || ko "sin effort low"

t "L2 new con stdin vacío: abre ciclo (racha 0) sin tocar ronda ni SID"
FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$R2" round p
assert_rc 1
ROUND_L2="$(st "$R2" round)"; SID_L2="$(st "$R2" codex-session-id)"; CALLS_L2="$(codex_calls)"
run_review "$R2" new ""
assert_rc 2
assert_out "falta el pedido"
assert_eq "$(st "$R2" changes-streak)" "0" "racha rearmada (apertura)"
assert_eq "$(st "$R2" round)" "$ROUND_L2" "ronda intacta"
assert_eq "$(st "$R2" codex-session-id)" "$SID_L2" "SID intacto"
assert_eq "$(codex_calls)" "$CALLS_L2" "codex no invocado"

# ── L3 · deadlock (r1.3, r2.3) ────────────────────────────────────────────────
t "L3 racha 5: aviso previo y bloqueo sin invocar"
R3="$(mk_repo l3)"
codex_reset
FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$R3" new p
assert_rc 1
for _ in 2 3 4; do
  FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$R3" round p
  assert_rc 1
done
assert_eq "$(st "$R3" changes-streak)" "4" "racha 4"
FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$R3" round p
assert_rc 1
assert_out "AVISO: racha de 4"
assert_eq "$(st "$R3" changes-streak)" "5" "racha 5"
run_review "$R3" status
assert_out "racha sin converger : 5"
CALLS_L3="$(codex_calls)"; ROUND_L3="$(st "$R3" round)"
run_review "$R3" round p
assert_rc 2
assert_out "DEADLOCK"
assert_eq "$(codex_calls)" "$CALLS_L3" "codex no invocado en deadlock"
assert_eq "$(st "$R3" round)" "$ROUND_L3" "ronda intacta"

t "L3 reset-deadlock rearma el loop"
run_review "$R3" reset-deadlock
assert_rc 0
assert_eq "$(st "$R3" changes-streak)" "0" "racha 0"
FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$R3" round p
assert_rc 1

t "L3 new no hereda la racha"
echo 5 > "$R3/.claude/state/changes-streak"
run_review "$R3" new p
assert_rc 0
assert_eq "$(st "$R3" changes-streak)" "0" "racha rearmada por new"

# ── L4 · wt_valid contra impostores (r3.1) — las tres invariantes ─────────────
t "L4 (a) subdir común: hereda el repo padre y wt_valid lo rechaza"
R4="$(mk_repo l4)"
codex_reset
WT4="$R4/.claude/state/review-worktree"
mkdir -p "$WT4"
echo impostor > "$WT4/impostor.txt"
echo "modificación local sin commit" >> "$R4/observed.txt"
echo untracked > "$R4/untracked-sentinel.txt"
# precondición (a): el subdir hereda el repo padre — toplevel ≠ WT_DIR (la invariante que cae)
assert_eq "$(git -C "$WT4" rev-parse --show-toplevel)" "$R4" "precondición (a): toplevel heredado del padre"
run_review "$R4" new p
assert_rc 0
grep -q "modificación local sin commit" "$R4/observed.txt" && ok || ko "reset --hard cayó sobre el canónico"
assert_file "$R4/untracked-sentinel.txt"
assert_no "$WT4/impostor.txt"
assert_eq "$(git -C "$WT4" rev-parse HEAD)" "$(git -C "$R4" rev-parse HEAD)" "worktree clavado al HEAD"
git -C "$R4" worktree list --porcelain | grep -qx "worktree $WT4" && ok || ko "worktree no registrado"

t "L4 (b) repo git independiente anidado: git-dir fuera de .git/worktrees"
git -C "$R4" worktree remove --force "$WT4"
mkdir -p "$WT4"
git -C "$WT4" init -q -b main
echo nested > "$WT4/nested.txt"
git -C "$WT4" add -A
git -C "$WT4" -c user.email=t@t -c user.name=t commit -qm nested
echo "segunda modificación local" >> "$R4/observed.txt"
# precondiciones (b): toplevel SÍ coincide; el git-dir queda fuera de .git/worktrees del repo
assert_eq "$(git -C "$WT4" rev-parse --show-toplevel)" "$WT4" "precondición (b): toplevel coincide"
case "$(git -C "$WT4" rev-parse --absolute-git-dir)" in
  "$R4/.git/worktrees/"*) ko "precondición (b): el git-dir no debería estar bajo .git/worktrees" ;;
  *) ok ;;
esac
run_review "$R4" round p
assert_rc 0
grep -q "segunda modificación local" "$R4/observed.txt" && ok || ko "reset tocó el canónico (repo anidado)"
assert_file "$R4/untracked-sentinel.txt"
assert_no "$WT4/nested.txt"
assert_eq "$(git -C "$WT4" rev-parse HEAD)" "$(git -C "$R4" rev-parse HEAD)" "worktree recreado al HEAD"

t "L4 (c) worktree movido: toplevel y git-dir pasan, el registro lo delata"
git -C "$R4" worktree remove --force "$WT4"
git -C "$R4" worktree add --detach "$R4/.claude/state/other-wt" HEAD >/dev/null 2>&1
mv "$R4/.claude/state/other-wt" "$WT4"
echo "tercera modificación local" >> "$R4/observed.txt"
# precondiciones (c): las dos primeras invariantes PASAN; solo el registro delata el path viejo
assert_eq "$(git -C "$WT4" rev-parse --show-toplevel)" "$WT4" "precondición (c): toplevel coincide"
case "$(git -C "$WT4" rev-parse --absolute-git-dir)" in
  "$R4/.git/worktrees/"*) ok ;;
  *) ko "precondición (c): el git-dir debería estar bajo .git/worktrees ($(git -C "$WT4" rev-parse --absolute-git-dir))" ;;
esac
git -C "$R4" worktree list --porcelain | grep -qx "worktree $WT4" && ko "precondición (c): el registro no debería apuntar a WT_DIR" || ok
run_review "$R4" round p
assert_rc 0
grep -q "tercera modificación local" "$R4/observed.txt" && ok || ko "reset tocó el canónico (worktree movido)"
assert_file "$R4/untracked-sentinel.txt"
git -C "$R4" worktree list --porcelain | grep -qx "worktree $R4/.claude/state/other-wt" && ko "el registro viejo no fue podado" || ok
git -C "$R4" worktree list --porcelain | grep -qx "worktree $WT4" && ok || ko "worktree final no registrado"
assert_eq "$(git -C "$WT4" rev-parse HEAD)" "$(git -C "$R4" rev-parse HEAD)" "worktree recreado al HEAD"

t "L4 worktree válido se reusa (git-dir administrativo sobrevive) y re-clava"
ADMIN4="$(git -C "$WT4" rev-parse --absolute-git-dir)"
echo centinela > "$ADMIN4/suite-sentinel"   # fuera del alcance de reset/clean: solo muere si se recrea el worktree
echo junk > "$WT4/junk.txt"
run_review "$R4" round p
assert_rc 0
assert_no "$WT4/junk.txt"
assert_file "$ADMIN4/suite-sentinel"

t "L4 worktree borrado se recrea (el git-dir administrativo es otro)"
rm -rf "$WT4"
run_review "$R4" round p
assert_rc 0
assert_eq "$(git -C "$WT4" rev-parse HEAD)" "$(git -C "$R4" rev-parse HEAD)" "worktree recreado tras borrado"
assert_no "$ADMIN4/suite-sentinel"   # prune + add: el centinela del admin viejo no sobrevive una recreación

# ── L5 · tri-estado y kill_confirmed de awake.sh (r1.6, r2.4, r3.2) ───────────
t "L5 start fresco deja proceso vivo y pidfile"
R5="$(mk_repo l5)"
run_awake "$R5" start
assert_rc 0
assert_out "máquina despierta"
P1="$(st "$R5" caffeinate-pid)"; note_pid "$P1"
assert_alive "$P1"

t "L5 status: despierta"
run_awake "$R5" status
assert_rc 0
assert_out "despierta (pid $P1)"

t "L5 start renueva: viejo muerto confirmado, nuevo vivo"
run_awake "$R5" start 6
assert_rc 0
P2="$(st "$R5" caffeinate-pid)"; note_pid "$P2"
assert_dead "$P1"
assert_alive "$P2"
[ "$P1" != "$P2" ] && ok || ko "el pidfile no cambió"

t "L5 horas inválidas: rechazo antes de tocar la assertion vigente"
run_awake "$R5" start abc
assert_rc 2
run_awake "$R5" start 0
assert_rc 2
assert_alive "$P2"
assert_eq "$(st "$R5" caffeinate-pid)" "$P2" "pidfile intacto"

t "L5 stop: transición viva→muerta confirmada dentro de la misma corrida"
run_awake "$R5" stop
assert_rc 0
assert_out "assertion liberada"
assert_dead "$P2"
assert_eq "$(st "$R5" caffeinate-pid)" "__ABSENT__" "pidfile borrado"

t "L5 stop sin assertion"
run_awake "$R5" stop
assert_rc 0
assert_out "no había assertion activa"

t "L5 status limpia el pidfile huérfano solo con muerte confirmada"
echo "$P2" > "$R5/.claude/state/caffeinate-pid"
run_awake "$R5" status
assert_rc 0
assert_out "sin assertion"
assert_eq "$(st "$R5" caffeinate-pid)" "__ABSENT__" "huérfano limpiado"

t "L5 stop con proceso que ignora TERM: conserva el rastro"
FAKE_CAFFEINATE_IGNORE_TERM=1 run_awake "$R5" start
assert_rc 0
P3="$(st "$R5" caffeinate-pid)"; note_pid "$P3"
run_awake "$R5" stop
assert_rc 2
assert_out "la señal no surtió efecto"
assert_eq "$(st "$R5" caffeinate-pid)" "$P3" "pidfile conservado"
assert_alive "$P3"
kill -9 "$P3" 2>/dev/null || true
rm -f "$R5/.claude/state/caffeinate-pid"

t "L5 indeterminado (sin pmset, pid vivo no-caffeinate): no tocar nada"
sleep 300 & SL=$!; disown; note_pid "$SL"
echo "$SL" > "$R5/.claude/state/caffeinate-pid"
FAKE_PMSET_MODE=absent run_awake "$R5" status
assert_rc 0
assert_out "indeterminado"
assert_eq "$(st "$R5" caffeinate-pid)" "$SL" "pidfile intacto"
FAKE_PMSET_MODE=absent run_awake "$R5" stop
assert_rc 2
assert_eq "$(st "$R5" caffeinate-pid)" "$SL" "pidfile intacto tras stop"
assert_alive "$SL"
FAKE_PMSET_MODE=absent run_awake "$R5" start
assert_rc 2
assert_eq "$(st "$R5" caffeinate-pid)" "$SL" "start no pisó el pidfile"
kill -9 "$SL" 2>/dev/null || true
rm -f "$R5/.claude/state/caffeinate-pid"

t "L5 fallback sin pmset (ps doblado): despierta; stop señaliza pero no confirma"
# camino contractual con el doble de ps: determinista incluso en sandboxes que niegan ps
sleep 300 & FP=$!; disown; note_pid "$FP"
echo "$FP" > "$R5/.claude/state/caffeinate-pid"
FAKE_PMSET_MODE=absent FAKE_PS_COMM=caffeinate run_awake "$R5" status
assert_rc 0
assert_out "despierta (pid $FP)"
# congelado conservador: sin pmset la muerte no es confirmable (kill -0 a un pid muerto
# ⇒ indeterminado, no muerte confirmada) — stop señaliza, el proceso MUERE, el pidfile queda
FAKE_PMSET_MODE=absent FAKE_PS_COMM=caffeinate run_awake "$R5" stop
assert_rc 2
assert_out "la señal no surtió efecto"
assert_eq "$(st "$R5" caffeinate-pid)" "$FP" "pidfile conservado (fail-closed sin pmset)"
wait_dead "$FP" || true
assert_dead "$FP"   # la señal salió de verdad: no fue denegada ni ignorada
rm -f "$R5/.claude/state/caffeinate-pid"

t "L5 smoke de identidad real (no contractual): caffeinate y ps verdaderos"
# solo corre donde ps funciona (fuera de sandboxes); una copia renombrada de sleep no sirve:
# muere por firma en macOS sellado — se usa el caffeinate real, lanzado por la suite
if [ -x /usr/bin/caffeinate ] && [ -n "$(/bin/ps -p $$ -o comm= 2>/dev/null)" ]; then
  /usr/bin/caffeinate -t 300 & CP=$!; disown; note_pid "$CP"
  echo "$CP" > "$R5/.claude/state/caffeinate-pid"
  FAKE_PMSET_MODE=absent run_awake "$R5" status
  assert_rc 0
  assert_out "despierta (pid $CP)"
  FAKE_PMSET_MODE=absent run_awake "$R5" stop
  assert_rc 2
  assert_out "la señal no surtió efecto"
  assert_eq "$(st "$R5" caffeinate-pid)" "$CP" "pidfile conservado (fail-closed sin pmset)"
  wait_dead "$CP" || true
  assert_dead "$CP"
  kill -9 "$CP" 2>/dev/null || true
  rm -f "$R5/.claude/state/caffeinate-pid"
else
  echo "SKIP [$CURRENT]: sin caffeinate real o ps denegado (sandbox) — el camino contractual quedó cubierto con el doble de ps" >&2
fi

# ── L6 · base a REVIEW_HEAD (r1.2) ────────────────────────────────────────────
t "L6 commits durante la review no quedan aprobados"
R6="$(mk_repo l6)"
codex_reset
HOOK6="$TESTS_TMP/hook-l6.sh"
cat > "$HOOK6" <<EOF
#!/usr/bin/env bash
echo "cambio durante la review" >> "$R6/observed.txt"
git -C "$R6" add -A
git -C "$R6" -c user.email=t@t -c user.name=t commit -qm "commit durante la review"
EOF
HEAD_L6="$(git -C "$R6" rev-parse HEAD)"
FAKE_CODEX_HOOK="$HOOK6" run_review "$R6" new p
assert_rc 0
assert_eq "$(st "$R6" last-approved-sha)" "$HEAD_L6" "base en el REVIEW_HEAD del pedido"
[ "$(git -C "$R6" rev-parse HEAD)" != "$HEAD_L6" ] && ok || ko "el hook no llegó a commitear"
assert_out "NO están aprobados"

t "L6 el commit intermedio entra en el próximo rango"
run_review "$R6" round p
assert_rc 0
codex_stdin "$(codex_calls)" | grep -q "commit durante la review" && ok || ko "el rango no incluye el commit intermedio"

# ── L7 · observación congelada (r2.1) ─────────────────────────────────────────
t "L7 el worktree queda clavado al REVIEW_HEAD aunque el canónico avance"
R7="$(mk_repo l7)"
codex_reset
WT7="$R7/.claude/state/review-worktree"
OBS7="$TESTS_TMP/l7-obs"
HOOK7="$TESTS_TMP/hook-l7.sh"
cat > "$HOOK7" <<EOF
#!/usr/bin/env bash
# avanza el canónico DURANTE la review y recién después observa el worktree desde adentro
echo "contenido nuevo" > "$R7/observed.txt"
git -C "$R7" add -A
git -C "$R7" -c user.email=t@t -c user.name=t commit -qm "avance durante la review"
git -C "$WT7" rev-parse HEAD > "$OBS7.head"
cat "$WT7/observed.txt" > "$OBS7.content"
EOF
HEAD_L7="$(git -C "$R7" rev-parse HEAD)"
FAKE_CODEX_HOOK="$HOOK7" run_review "$R7" new p
assert_rc 0
assert_eq "$(cat "$OBS7.head")" "$HEAD_L7" "observación clavada al REVIEW_HEAD"
assert_eq "$(cat "$OBS7.content")" "contenido original" "contenido viejo, no el del canónico avanzado"

t "L7 el residuo de una ronda no llega a la siguiente"
cat > "$HOOK7" <<EOF
#!/usr/bin/env bash
echo basura > "$WT7/residue.txt"
echo "modificado por el reviewer" >> "$WT7/observed.txt"
EOF
FAKE_CODEX_HOOK="$HOOK7" run_review "$R7" round p
assert_rc 0
cat > "$HOOK7" <<EOF
#!/usr/bin/env bash
if [ -e "$WT7/residue.txt" ]; then echo PRESENTE > "$OBS7.residue"; else echo AUSENTE > "$OBS7.residue"; fi
git -C "$WT7" status --porcelain > "$OBS7.status"
EOF
FAKE_CODEX_HOOK="$HOOK7" run_review "$R7" round p
assert_rc 0
assert_eq "$(cat "$OBS7.residue")" "AUSENTE" "residuo limpiado"
assert_eq "$(cat "$OBS7.status")" "" "worktree limpio al arrancar la ronda"

# ── L8 · session id por thread.started + retry transitorio (paso B) ──────────
t "L8 UUID espurio en stderr antes de thread.started: se captura el thread_id"
R8="$(mk_repo l8)"
codex_reset
SPUR=$'2026-07-28T01:15:19Z ERROR request 99999999-9999-4999-8999-999999999999 fallo transitorio\n{"type":"thread.started","thread_id":"cccccccc-3333-4333-8333-333333333333"}\n{"type":"turn.started"}'
FAKE_CODEX_EVENTS="$SPUR" run_review "$R8" new p
assert_rc 0
assert_eq "$(st "$R8" codex-session-id)" "cccccccc-3333-4333-8333-333333333333" "thread_id correcto, no el UUID espurio"

t "L8 retry de new con SID: resume exacto de la sesión del intento fallido"
codex_reset
PLAN8="$TESTS_TMP/plan-l8a"; rm -rf "$PLAN8"; mkdir -p "$PLAN8"
echo 9 > "$PLAN8/1.rc"
FAKE_CODEX_PLAN="$PLAN8" FAKE_CODEX_SID="dddddddd-4444-4444-8444-444444444444" run_review "$R8" new p
assert_rc 0
assert_eq "$(codex_calls)" "2" "dos intentos"
assert_out "reintento único"
codex_argv 2 | grep -q 'exec resume dddddddd-4444-4444-8444-444444444444' && ok || ko "el retry no resumió la sesión exacta: $(codex_argv 2)"
assert_eq "$(st "$R8" round)" "1" "misma ronda"
assert_eq "$(st "$R8" last-approved-sha)" "$(git -C "$R8" rev-parse HEAD)" "el veredicto del intento 2 escribió estado"
assert_file "$R8/.claude/state/last-review-events.failed.jsonl"
grep -q '"type":"thread.started"' "$R8/.claude/state/last-review-events.failed.jsonl" && ok || ko "los eventos del intento fallido no se preservaron"

t "L8 retry de new sin SID: exec nuevo, jamás resume --last"
codex_reset
PLAN8="$TESTS_TMP/plan-l8b"; rm -rf "$PLAN8"; mkdir -p "$PLAN8"
echo 9 > "$PLAN8/1.rc"
printf '%s\n' '{"type":"error","message":"murió antes de abrir sesión"}' > "$PLAN8/1.events"
FAKE_CODEX_PLAN="$PLAN8" FAKE_CODEX_SID="eeeeeeee-5555-4555-8555-555555555555" run_review "$R8" new p
assert_rc 0
assert_eq "$(codex_calls)" "2" "dos intentos"
codex_argv 2 | grep -q ' resume ' && ko "el retry sin SID no debe resumir: $(codex_argv 2)" || ok
codex_argv 2 | grep -q -- '--cd' && ok || ko "el retry sin SID debe ser un exec nuevo (con --cd)"
assert_eq "$(st "$R8" codex-session-id)" "eeeeeeee-5555-4555-8555-555555555555" "SID capturado del intento 2"

t "L8 retry de round: mismo SID, misma ronda, veredicto del intento 2"
codex_reset
PLAN8="$TESTS_TMP/plan-l8c"; rm -rf "$PLAN8"; mkdir -p "$PLAN8"
echo 9 > "$PLAN8/1.rc"
printf 'VERDICT: CHANGES_REQUESTED' > "$PLAN8/2.msg"
ROUND_L8="$(st "$R8" round)"
SID_L8="$(st "$R8" codex-session-id)"
FAKE_CODEX_PLAN="$PLAN8" run_review "$R8" round p
assert_rc 1
assert_eq "$(codex_calls)" "2" "dos intentos"
codex_argv 1 | grep -q "exec resume $SID_L8" && ok || ko "intento 1 sin resume del SID vigente"
codex_argv 2 | grep -q "exec resume $SID_L8" && ok || ko "intento 2 sin resume del mismo SID"
assert_eq "$(st "$R8" round)" "$((ROUND_L8 + 1))" "una sola ronda consumida"
assert_eq "$(st "$R8" changes-streak)" "1" "racha del veredicto del intento 2"

t "L8 dos fallas consecutivas: exit 2 y resultado intacto"
codex_reset
PLAN8="$TESTS_TMP/plan-l8d"; rm -rf "$PLAN8"; mkdir -p "$PLAN8"
echo 9 > "$PLAN8/1.rc"; echo 9 > "$PLAN8/2.rc"
RS_L8="$(result_state "$R8")"
FAKE_CODEX_PLAN="$PLAN8" run_review "$R8" round p
assert_rc 2
assert_eq "$(codex_calls)" "2" "dos intentos y no más"
assert_eq "$(result_state "$R8")" "$RS_L8" "estado de resultado intacto"

t "L8 mensaje vacío con RC 0 también se reintenta"
codex_reset
PLAN8="$TESTS_TMP/plan-l8e"; rm -rf "$PLAN8"; mkdir -p "$PLAN8"
printf '@none' > "$PLAN8/1.msg"
printf 'VERDICT: CHANGES_REQUESTED' > "$PLAN8/2.msg"
FAKE_CODEX_PLAN="$PLAN8" run_review "$R8" round p
assert_rc 1
assert_eq "$(codex_calls)" "2" "reintentado tras mensaje ausente"
assert_out "sin mensaje final"

t "L8 veredicto inválido NO se reintenta"
codex_reset
FAKE_CODEX_MSG='una review entregada sin línea de veredicto' run_review "$R8" round p
assert_rc 2
assert_eq "$(codex_calls)" "1" "sin retry ante veredicto inválido"

t "L8 AXEL_REVIEW_RETRIES=0 desactiva el retry"
codex_reset
AXEL_REVIEW_RETRIES=0 FAKE_CODEX_RC=9 run_review "$R8" round p
assert_rc 2
assert_eq "$(codex_calls)" "1" "sin retry con retries=0"

# ── L9 · métricas: rounds-log y resumen de status (paso B) ────────────────────
t "L9 esquema: new + fallo→éxito comparten número de ronda (una ronda, dos intentos)"
R9="$(mk_repo l9)"
codex_reset
run_review "$R9" new p
assert_rc 0
PLAN9="$TESTS_TMP/plan-l9"; rm -rf "$PLAN9"; mkdir -p "$PLAN9"
echo 9 > "$PLAN9/1.rc"
printf 'VERDICT: CHANGES_REQUESTED' > "$PLAN9/2.msg"
codex_reset   # el contador del doble es global: el plan numera desde esta invocación
FAKE_CODEX_PLAN="$PLAN9" run_review "$R9" round p
assert_rc 1
RL9="$R9/.claude/state/rounds-log"
assert_file "$RL9"
assert_eq "$(wc -l < "$RL9" | tr -d ' ')" "3" "tres eventos"
awk -F'\t' 'NR==1 { exit !($2=="new" && $3=="1" && $4=="1" && $5=="APPROVED" && $7=="0") }' "$RL9" && ok || ko "línea 1 inesperada: $(sed -n 1p "$RL9")"
awk -F'\t' 'NR==2 { exit !($2=="round" && $3=="2" && $4=="1" && $5=="PROC_FAIL") }' "$RL9" && ok || ko "línea 2 inesperada: $(sed -n 2p "$RL9")"
awk -F'\t' 'NR==3 { exit !($2=="round" && $3=="2" && $4=="2" && $5=="CHANGES_REQUESTED" && $7=="1") }' "$RL9" && ok || ko "línea 3 inesperada: $(sed -n 3p "$RL9")"

t "L9 NO_VERDICT, DEADLOCK e INPUT_ERROR quedan en el log"
FAKE_CODEX_MSG='sin veredicto' run_review "$R9" round p
assert_rc 2
awk -F'\t' 'END { exit !($5=="NO_VERDICT" && $4=="1") }' "$RL9" && ok || ko "NO_VERDICT no quedó: $(tail -1 "$RL9")"
echo 5 > "$R9/.claude/state/changes-streak"
run_review "$R9" round p
assert_rc 2
awk -F'\t' 'END { exit !($5=="DEADLOCK" && $3=="-" && $4=="-" && $6=="-" && $7=="5") }' "$RL9" && ok || ko "DEADLOCK no quedó: $(tail -1 "$RL9")"
run_review "$R9" new ""
assert_rc 2
awk -F'\t' 'END { exit !($2=="new" && $5=="INPUT_ERROR" && $3=="-" && $4=="-" && $7=="0") }' "$RL9" && ok || ko "INPUT_ERROR no quedó: $(tail -1 "$RL9")"

t "L9 status: el new fallido delimita el ciclo y los pre-invocación no cuentan como intentos"
run_review "$R9" status
assert_rc 0
assert_out "0 ronda(s) · 0 intento(s) · 1 evento(s)"
assert_out "INPUT_ERROR=1"

t "L9 status tras ciclo nuevo con retry: denominadores correctos"
run_review "$R9" new p
assert_rc 0
codex_reset
FAKE_CODEX_PLAN="$PLAN9" run_review "$R9" round p
assert_rc 1
run_review "$R9" status
assert_rc 0
assert_out "2 ronda(s) · 3 intento(s) · 3 evento(s)"
assert_out "PROC_FAIL=1"
assert_out "CHANGES_REQUESTED=1"

t "L9 retry durante new: el intento 2 no abre ciclo — el ciclo arranca en el intento 1"
codex_reset
PLAN9B="$TESTS_TMP/plan-l9b"; rm -rf "$PLAN9B"; mkdir -p "$PLAN9B"
echo 9 > "$PLAN9B/1.rc"
FAKE_CODEX_PLAN="$PLAN9B" run_review "$R9" new p
assert_rc 0
awk -F'\t' 'END { exit !($2=="new" && $3=="1" && $4=="2" && $5=="APPROVED") }' "$RL9" && ok || ko "última línea inesperada: $(tail -1 "$RL9")"
run_review "$R9" status
assert_rc 0
assert_out "1 ronda(s) · 2 intento(s) · 2 evento(s)"
assert_out "PROC_FAIL=1"
assert_out "APPROVED=1"

t "L9 métricas best-effort: log inescribible no altera RC ni estado"
rm -f "$RL9"; mkdir "$RL9"   # rounds-log convertido en directorio: el append falla
run_review "$R9" round p
assert_rc 0
assert_out "no pude escribir"
assert_eq "$(st "$R9" last-approved-sha)" "$(git -C "$R9" rev-parse HEAD)" "APPROVED movió la base igual"
run_review "$R9" new ""
assert_rc 2
assert_out "falta el pedido"
echo 5 > "$R9/.claude/state/changes-streak"
run_review "$R9" round p
assert_rc 2
assert_out "DEADLOCK"
rmdir "$RL9"

# ── L10 · señal terminal (feature 07): todo camino de new|round publica identidad ──
term_get() { # term_get <repo> <clave>
  grep "^$2=" "$1/.claude/state/review-terminal" 2>/dev/null | cut -d= -f2- || true
}
assert_no_tmp() { # la publicación es atómica: jamás queda tmp residual
  find "$1/.claude/state" -maxdepth 1 -name '.review-terminal.tmp.*' 2>/dev/null | grep -q . \
    && ko "tmp residual del terminal" || ok
}

t "L10 APPROVED publica terminal completo con id propagado"
RT="$(mk_repo l10)"
codex_reset
AXEL_REVIEW_ID="07:r1:nonce-a" run_review "$RT" new p
assert_rc 0
assert_eq "$(term_get "$RT" id)" "07:r1:nonce-a" "id"
assert_eq "$(term_get "$RT" mode)" "new" "mode"
assert_eq "$(term_get "$RT" round)" "1" "round"
assert_eq "$(term_get "$RT" review_head)" "$(git -C "$RT" rev-parse HEAD)" "review_head"
assert_eq "$(term_get "$RT" result)" "APPROVED" "result"
assert_eq "$(term_get "$RT" rc)" "0" "rc"
assert_no_tmp "$RT"

t "L10 sin AXEL_REVIEW_ID: id=- y flujo intacto"
echo l10b >> "$RT/docs/README.md"; tcommit "$RT"
FAKE_CODEX_MSG=$'VERDICT: CHANGES_REQUESTED' run_review "$RT" round p
assert_rc 1
assert_eq "$(term_get "$RT" id)" "-" "id ausente"
assert_eq "$(term_get "$RT" result)" "CHANGES_REQUESTED" "result"
assert_eq "$(term_get "$RT" rc)" "1" "rc"
assert_eq "$(term_get "$RT" round)" "2" "round"

t "L10 NO_VERDICT: terminal con head del pedido y rc=2"
AXEL_REVIEW_ID="07:r3:nonce-b" FAKE_CODEX_MSG='mensaje sin veredicto' run_review "$RT" round p
assert_rc 2
assert_eq "$(term_get "$RT" id)" "07:r3:nonce-b" "id"
assert_eq "$(term_get "$RT" result)" "NO_VERDICT" "result"
assert_eq "$(term_get "$RT" rc)" "2" "rc"
assert_eq "$(term_get "$RT" review_head)" "$(git -C "$RT" rev-parse HEAD)" "review_head"

t "L10 PROC_FAIL persistente (doble falla): terminal con la falla"
FAKE_CODEX_RC=9 run_review "$RT" round p
assert_rc 2
assert_eq "$(term_get "$RT" result)" "PROC_FAIL" "result"
assert_eq "$(term_get "$RT" rc)" "2" "rc"

t "L10 DEADLOCK pre-invocación: round y head en «-», id presente"
echo 5 > "$RT/.claude/state/changes-streak"
AXEL_REVIEW_ID="07:r9:nonce-dead" run_review "$RT" round p
assert_rc 2
assert_eq "$(term_get "$RT" id)" "07:r9:nonce-dead" "id en pre-invocación"
assert_eq "$(term_get "$RT" result)" "DEADLOCK" "result"
assert_eq "$(term_get "$RT" round)" "-" "round pre-invocación"
assert_eq "$(term_get "$RT" review_head)" "-" "head pre-invocación"
assert_eq "$(term_get "$RT" rc)" "2" "rc"
run_review "$RT" reset-deadlock
assert_rc 0

t "L10 INPUT_ERROR pre-invocación y sobreescritura por invocación"
AXEL_REVIEW_ID="07:r4:nonce-c" run_review "$RT" round ""
assert_rc 2
assert_eq "$(term_get "$RT" id)" "07:r4:nonce-c" "id del último"
assert_eq "$(term_get "$RT" result)" "INPUT_ERROR" "result"
assert_eq "$(term_get "$RT" round)" "-" "round pre-invocación"
AXEL_REVIEW_ID="07:r4:nonce-d" run_review "$RT" round p
assert_rc 0
assert_eq "$(term_get "$RT" id)" "07:r4:nonce-d" "el terminal viejo no sobrevive"
assert_eq "$(term_get "$RT" result)" "APPROVED" "result nuevo"
assert_no_tmp "$RT"

t "L10 status y reset-deadlock no tocan el terminal"
SNAP_T="$(cat "$RT/.claude/state/review-terminal")"
run_review "$RT" status
assert_rc 0
run_review "$RT" reset-deadlock
assert_rc 0
assert_eq "$(cat "$RT/.claude/state/review-terminal")" "$SNAP_T" "terminal intacto"

t "L10 salida no clasificada de set -e: ABORTED con head capturado"
echo deadbeef > "$RT/.claude/state/last-approved-sha"   # base corrupta: git log revienta tras capturar REVIEW_HEAD
AXEL_REVIEW_ID="07:r5:nonce-e" run_review "$RT" round p
[ "$RC" -ne 0 ] && ok || ko "debía fallar con base corrupta"
assert_eq "$(term_get "$RT" id)" "07:r5:nonce-e" "id"
assert_eq "$(term_get "$RT" result)" "ABORTED" "result"
assert_eq "$(term_get "$RT" review_head)" "$(git -C "$RT" rev-parse HEAD)" "head capturado antes del abort"
assert_eq "$(term_get "$RT" round)" "-" "round aún no computada"
[ "$(term_get "$RT" rc)" != "0" ] && ok || ko "rc del terminal no puede ser 0 en un abort"

t "L10 uso inválido y consultas no escriben terminal"
RTB="$(mk_repo l10b)"
run_review "$RTB" badmode
assert_rc 2
assert_no "$RTB/.claude/state/review-terminal"
run_review "$RTB" status
assert_rc 0
assert_no "$RTB/.claude/state/review-terminal"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo
echo "── loop.sh: $PASS ok · $FAIL fail ──"
[ "$FAIL" -eq 0 ]
