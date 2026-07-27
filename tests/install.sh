#!/usr/bin/env bash
# axel · suite de invariantes del instalador (sin invocar agentes)
# Fixtures: copia del working tree de axel como fuente + repos git temporales como destinos.
# Cubre la matriz de docs/implementation/01-installer.md. Exit 0 = toda la matriz en verde.
set -euo pipefail

AXEL_REAL="$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)"
TESTS_TMP="$(mktemp -d "${TMPDIR:-/tmp}/axel-install-tests.XXXXXX")"
trap 'rm -rf "$TESTS_TMP"' EXIT

# Fuente = copia del árbol actual de axel (sin .git ni estado local), con repo propio:
# los tests jamás tocan el repo axel real, y "otro SHA de axel" es un commit en la copia.
AXEL_SRC="$TESTS_TMP/axel-src"
mkdir -p "$AXEL_SRC"
(cd "$AXEL_REAL" && tar -cf - --exclude .git --exclude .claude/state .) | (cd "$AXEL_SRC" && tar -xf -)
git -C "$AXEL_SRC" init -q -b main
git -C "$AXEL_SRC" add -A
git -C "$AXEL_SRC" -c user.email=t@t -c user.name=t commit -qm source
INSTALL="$AXEL_SRC/scripts/install.sh"

# ── Arnés ─────────────────────────────────────────────────────────────────────
PASS=0; FAIL=0; CURRENT=""
t() { CURRENT="$1"; }
ok() { PASS=$((PASS + 1)); }
ko() { FAIL=$((FAIL + 1)); echo "FAIL [$CURRENT] $1" >&2; }
assert_rc()    { [ "$RC" -eq "$1" ] && ok || ko "exit esperado $1, fue $RC · salida: $(echo "$OUT" | tail -3 | tr '\n' ' ')"; }
assert_file()  { [ -f "$1" ] && ok || ko "falta archivo: $1"; }
assert_exec()  { [ -x "$1" ] && ok || ko "sin permiso de ejecución: $1"; }
assert_no()    { { [ ! -e "$1" ] && [ ! -L "$1" ]; } && ok || ko "no debería existir: $1"; }
assert_link()  { { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; } && ok || ko "symlink incorrecto: $1 → $(readlink "$1" 2>/dev/null || echo '(no existe)')"; }
assert_same()  { cmp -s "$1" "$2" && ok || ko "difieren: $1 vs $2"; }
assert_in_file() { grep -qF "$2" "$1" 2>/dev/null && ok || ko "'$2' no está en $1"; }
assert_not_in_file() { { [ ! -f "$1" ] || ! grep -qF "$2" "$1"; } && ok || ko "'$2' NO debería estar en $1"; }
assert_out()   { printf '%s' "$OUT" | grep -qF "$1" && ok || ko "'$1' no está en la salida"; }
assert_clean() { [ -z "$(git -C "$1" status --porcelain)" ] && ok || ko "árbol con cambios: $(git -C "$1" status --porcelain | tr '\n' ' ')"; }
assert_dirty() { [ -n "$(git -C "$1" status --porcelain)" ] && ok || ko "árbol sin cambios (se esperaba diff)"; }

OUT=""; RC=0
run_install() { OUT="$("$INSTALL" "$@" 2>&1)" && RC=0 || RC=$?; }

mk_target() {
  local t="$TESTS_TMP/$1"
  mkdir -p "$t"
  git -C "$t" init -q -b main
  git -C "$t" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  printf '%s' "$t"
}
tcommit() { git -C "$1" add -A; git -C "$1" -c user.email=t@t -c user.name=t commit -qm "${2:-checkpoint}"; }
seed_settings() { mkdir -p "$1/.claude"; cp "$AXEL_SRC/templates/settings.json" "$1/.claude/settings.json"; }

# ── T1 · instalación desde cero: estructura completa, fase diseño, exit 0 ─────
t "T1 instalación desde cero"
T1="$(mk_target t1)"
run_install "$T1"
assert_rc 0
for f in adopt design feature plan recap status; do assert_file "$T1/.claude/skills/$f/SKILL.md"; done
assert_file "$T1/scripts/review.sh";  assert_exec "$T1/scripts/review.sh"
assert_file "$T1/scripts/awake.sh";   assert_exec "$T1/scripts/awake.sh"
assert_file "$T1/docs/design/review-contract.md"
for f in AGENTS.md docs/DESIGN.md docs/IMPLEMENTATION.md docs/STATUS.md .claude/settings.json; do assert_file "$T1/$f"; done
assert_link "$T1/CLAUDE.md" "AGENTS.md"
assert_in_file "$T1/.gitignore" ".claude/state/"
assert_file "$T1/.claude/axel-install"
assert_in_file "$T1/.claude/axel-install" "axel-install-format: 1"
assert_no "$T1/docs/ADOPTION.md"
assert_in_file "$T1/docs/STATUS.md" "/design"
assert_not_in_file "$T1/docs/STATUS.md" "adopción"
assert_in_file "$T1/AGENTS.md" "t1 se desarrolla"      # {{PROJECT}} sustituido
assert_not_in_file "$T1/AGENTS.md" "{{PROJECT}}"
assert_out "modo: initial"
assert_dirty "$T1"   # todo lo escrito es diff visible

# ── T2 · install → commit → update: exit 0, sin handoff, idempotencia byte a byte
t "T2 update no-op idempotente"
tcommit "$T1" "install axel"
run_install "$T1"
assert_rc 0
assert_no "$T1/docs/ADOPTION.md"
assert_clean "$T1"   # sin diff alguno, marker incluido
assert_out "modo: update"

# ── T3 · update desde un axel con SHA distinto reescribe el marker ────────────
t "T3 update con SHA nuevo de axel"
git -C "$AXEL_SRC" -c user.email=t@t -c user.name=t commit -q --allow-empty -m bump
run_install "$T1"
assert_rc 0
assert_dirty "$T1"
assert_in_file "$T1/.claude/axel-install" "axel-sha: $(git -C "$AXEL_SRC" rev-parse HEAD)"
tcommit "$T1" "update axel"

# ── T4 · adopción: preexistentes intactos, candidatos correctos, handoff, exit 1
t "T4 adopción"
T4="$(mk_target t4)"
mkdir -p "$T4/docs/notes"
echo "# diseño propio del proyecto" > "$T4/docs/DESIGN.md"
echo "# plan viejo" > "$T4/PLAN.md"
echo "# readme" > "$T4/README.md"
echo "# notas" > "$T4/docs/notes/ideas.md"
tcommit "$T4" "docs previos"
cp "$T4/docs/DESIGN.md" "$TESTS_TMP/t4-design.ref"
run_install "$T4"
assert_rc 1
assert_same "$T4/docs/DESIGN.md" "$TESTS_TMP/t4-design.ref"     # ni un byte
assert_file "$T4/docs/IMPLEMENTATION.md"; assert_file "$T4/docs/STATUS.md"; assert_file "$T4/AGENTS.md"
assert_file "$T4/docs/ADOPTION.md"
[ "$(sed -n '1p' "$T4/docs/ADOPTION.md")" = "<!-- generated by axel installer -->" ] && ok || ko "handoff sin firma en línea 1"
assert_in_file "$T4/docs/ADOPTION.md" 'docs/DESIGN.md'
for c in PLAN.md README.md docs/notes/ideas.md; do assert_in_file "$T4/docs/ADOPTION.md" "$c"; done
assert_not_in_file "$T4/docs/ADOPTION.md" "review-contract.md"  # artefactos propios excluidos
assert_not_in_file "$T4/docs/ADOPTION.md" "CLAUDE.md"
assert_in_file "$T4/docs/STATUS.md" "adopción"
assert_out "handoff escrito: docs/ADOPTION.md"

# ── T5 · cierre de adopción (efecto mecánico de /adopt) → update no la reabre ─
t "T5 update tras adopción cerrada"
tcommit "$T4" "install axel (adopción abierta)"
rm "$T4/docs/ADOPTION.md"                                        # lo que /adopt hace al cerrar
tcommit "$T4" "cierre de adopción"
run_install "$T4"
assert_rc 0
assert_no "$T4/docs/ADOPTION.md"   # README/PLAN siguen ahí y NO reabren nada
assert_clean "$T4"

# ── T6 · update con handoff pendiente lo conserva intacto ─────────────────────
t "T6 update conserva handoff abierto"
T6="$(mk_target t6)"
echo "# diseño" > "$T6/docs-previos.md"; mv "$T6/docs-previos.md" "$T6/ARCH.md"
tcommit "$T6" "doc previo"
run_install "$T6"; assert_rc 1
tcommit "$T6" "install (adopción abierta)"
cp "$T6/docs/ADOPTION.md" "$TESTS_TMP/t6-handoff.ref"
run_install "$T6"
assert_rc 1
assert_same "$T6/docs/ADOPTION.md" "$TESTS_TMP/t6-handoff.ref"
assert_clean "$T6"

# ── T7 · update pisa payload modificado-y-commiteado (con commit intermedio) ──
t "T7 update actualiza payload local"
echo "# hack local" >> "$T1/scripts/awake.sh"
tcommit "$T1" "mod local de payload"
run_install "$T1"
assert_rc 0
assert_same "$T1/scripts/awake.sh" "$AXEL_SRC/scripts/awake.sh"
assert_dirty "$T1"
tcommit "$T1" "payload restaurado"

# ── T8 · STATUS.md preexistente: intacto y el handoff persiste igual ──────────
t "T8 STATUS preexistente"
T8="$(mk_target t8)"
mkdir -p "$T8/docs"; echo "# status propio" > "$T8/docs/STATUS.md"
tcommit "$T8" "status previo"
cp "$T8/docs/STATUS.md" "$TESTS_TMP/t8-status.ref"
run_install "$T8"
assert_rc 1
assert_same "$T8/docs/STATUS.md" "$TESTS_TMP/t8-status.ref"
assert_file "$T8/docs/ADOPTION.md"
assert_in_file "$T8/docs/ADOPTION.md" "docs/STATUS.md"

# ── T9 · CLAUDE.md en conflicto: intacto, pendiente en el handoff ─────────────
t "T9 CLAUDE.md en conflicto"
T9="$(mk_target t9)"
echo "# instrucciones propias" > "$T9/CLAUDE.md"
tcommit "$T9" "claude propio"
run_install "$T9"
assert_rc 1
[ ! -L "$T9/CLAUDE.md" ] && ok || ko "CLAUDE.md fue reemplazado por symlink"
assert_in_file "$T9/CLAUDE.md" "instrucciones propias"
assert_in_file "$T9/docs/ADOPTION.md" "CLAUDE.md preexistente"

# ── T10 · settings: política efectiva, fail-closed ────────────────────────────
t "T10a settings completo"
TA="$(mk_target t10a)"; seed_settings "$TA"; tcommit "$TA" "settings"
run_install "$TA"; assert_rc 0; assert_no "$TA/docs/ADOPTION.md"

t "T10b settings incompleto"
TB="$(mk_target t10b)"
mkdir -p "$TB/.claude"
printf '{"permissions": {"defaultMode": "acceptEdits", "allow": ["Bash(git add:*)"]}}\n' > "$TB/.claude/settings.json"
tcommit "$TB" "settings parcial"
run_install "$TB"
assert_rc 1
assert_in_file "$TB/docs/ADOPTION.md" "permiso faltante"
assert_out "permiso faltante"

t "T10c settings reformateado equivalente"
TC="$(mk_target t10c)"
mkdir -p "$TC/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$TC/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["allow"] = list(reversed(d["permissions"]["allow"]))
print(json.dumps(d, indent=8))
PY
tcommit "$TC" "settings reformateado"
run_install "$TC"; assert_rc 0

t "T10d settings JSON inválido"
TD="$(mk_target t10d)"
mkdir -p "$TD/.claude"; echo '{ nope' > "$TD/.claude/settings.json"
tcommit "$TD" "settings roto"
run_install "$TD"
assert_rc 1
assert_in_file "$TD/docs/ADOPTION.md" "invalido"

t "T10e permiso solo bajo deny"
TE="$(mk_target t10e)"
mkdir -p "$TE/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$TE/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
allow = d["permissions"]["allow"]
d["permissions"]["deny"] = ["Bash(codex exec:*)"]
d["permissions"]["allow"] = [p for p in allow if p != "Bash(codex exec:*)"]
print(json.dumps(d))
PY
tcommit "$TE" "deny only"
run_install "$TE"
assert_rc 1
assert_in_file "$TE/docs/ADOPTION.md" "permiso faltante en permissions.allow: Bash(codex exec:*)"

t "T10f permiso en allow y deny (deny gana)"
TF="$(mk_target t10f)"
mkdir -p "$TF/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$TF/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["Bash(codex exec:*)"]
print(json.dumps(d))
PY
tcommit "$TF" "allow+deny"
run_install "$TF"
assert_rc 1
assert_in_file "$TF/docs/ADOPTION.md" "deny gana"

t "T10g defaultMode ausente"
TG="$(mk_target t10g)"
mkdir -p "$TG/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$TG/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
del d["permissions"]["defaultMode"]
print(json.dumps(d))
PY
tcommit "$TG" "sin defaultMode"
run_install "$TG"
assert_rc 1
assert_in_file "$TG/docs/ADOPTION.md" "defaultMode"

t "T10h python3 no disponible (fail-closed)"
TH="$(mk_target t10h)"; seed_settings "$TH"; tcommit "$TH" "settings"
OUT="$(AXEL_INSTALL_PYTHON=/nonexistent-python "$INSTALL" "$TH" 2>&1)" && RC=0 || RC=$?
assert_rc 1
assert_in_file "$TH/docs/ADOPTION.md" "inverificable"

# ── T11 · rechazos: exit 2 y cero mutaciones ──────────────────────────────────
reject_case() {  # $1 = target; corre install y verifica exit 2 + árbol limpio
  run_install "$1"
  assert_rc 2
  assert_clean "$1"
}

t "T11a destino sin git"
NG="$TESTS_TMP/no-git"; mkdir -p "$NG"
run_install "$NG"; assert_rc 2; assert_no "$NG/AGENTS.md"

t "T11b árbol sucio"
T11B="$(mk_target t11b)"; echo x > "$T11B/pending.txt"
run_install "$T11B"; assert_rc 2; assert_no "$T11B/AGENTS.md"

t "T11c target subdirectorio"
T11C="$(mk_target t11c)"; mkdir -p "$T11C/sub"
run_install "$T11C/sub"; assert_rc 2; assert_clean "$T11C"

t "T11d self-install"
run_install "$AXEL_SRC"; assert_rc 2; assert_clean "$AXEL_SRC"

t "T11e worktree del propio axel"
git -C "$AXEL_SRC" worktree add -q "$TESTS_TMP/axel-wt" >/dev/null 2>&1
reject_case "$TESTS_TMP/axel-wt"
git -C "$AXEL_SRC" worktree remove --force "$TESTS_TMP/axel-wt" >/dev/null 2>&1

t "T11f colisión ignorada en ruta de payload"
T11F="$(mk_target t11f)"
echo "scripts/" > "$T11F/.gitignore"; tcommit "$T11F" ignore
mkdir -p "$T11F/scripts"; echo "propio" > "$T11F/scripts/review.sh"   # ignorado: árbol sigue limpio
reject_case "$T11F"
assert_in_file "$T11F/scripts/review.sh" "propio"   # no fue pisado

t "T11g ruta a crear nacería ignorada"
T11G="$(mk_target t11g)"
echo ".claude/" > "$T11G/.gitignore"; tcommit "$T11G" ignore
reject_case "$T11G"; assert_no "$T11G/AGENTS.md"

t "T11h symlink en ruta de payload"
T11H="$(mk_target t11h)"
mkdir -p "$TESTS_TMP/outside-scripts"
ln -s "$TESTS_TMP/outside-scripts" "$T11H/scripts"; tcommit "$T11H" symlink
reject_case "$T11H"
assert_no "$TESTS_TMP/outside-scripts/review.sh"    # nada escapó del árbol

t "T11i ADOPTION.md preexistente sin firma"
T11I="$(mk_target t11i)"
mkdir -p "$T11I/docs"; echo "# adopción legal del proyecto" > "$T11I/docs/ADOPTION.md"
tcommit "$T11I" "doc propio"
reject_case "$T11I"
assert_in_file "$T11I/docs/ADOPTION.md" "adopción legal"

t "T11j marker que no parsea"
T11J="$(mk_target t11j)"
mkdir -p "$T11J/.claude"; echo "basura" > "$T11J/.claude/axel-install"
tcommit "$T11J" "marker roto"
reject_case "$T11J"

t "T11k marker válido pero ignorado (untracked)"
T11K="$(mk_target t11k)"
echo ".claude/" > "$T11K/.gitignore"; tcommit "$T11K" ignore
mkdir -p "$T11K/.claude"
printf 'axel-install-format: 1\naxel-sha: %s\n' "$(git -C "$AXEL_SRC" rev-parse HEAD)" > "$T11K/.claude/axel-install"
reject_case "$T11K"

t "T11l handoff con firma pero ignorado"
T11L="$(mk_target t11l)"
echo "docs/ADOPTION.md" > "$T11L/.gitignore"; tcommit "$T11L" ignore
mkdir -p "$T11L/docs"
printf '<!-- generated by axel installer -->\nresto\n' > "$T11L/docs/ADOPTION.md"
reject_case "$T11L"

t "T11m .gitignore él mismo ignorado"
T11M="$(mk_target t11m)"
echo ".gitignore" > "$T11M/.git/info/exclude"   # path absoluto: --git-dir devuelve rutas relativas al repo
echo "algo-propio/" > "$T11M/.gitignore"    # existe, sin la línea, invisible para git
reject_case "$T11M"
assert_not_in_file "$T11M/.gitignore" ".claude/state/"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo
echo "── tests/install.sh: $PASS ok · $FAIL fail ──"
[ "$FAIL" -eq 0 ]
