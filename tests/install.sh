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

# Huella del contenido real del filesystem (sin .git): "cero mutaciones" debe cubrir
# también paths ignorados, que git status no observa
fs_digest() {
  (cd "$1" && find . -name .git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r p; do
    if [ -L "$p" ]; then printf 'L %s -> %s\n' "$p" "$(readlink "$p")"; else shasum "$p"; fi
  done | shasum | cut -d' ' -f1)
}

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
assert_file "$T1/.claude/axel-policy.json"
assert_same "$T1/.claude/axel-policy.json" "$AXEL_SRC/templates/settings.json"
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

# ── T11 · rechazos: exit 2 y cero mutaciones (huella de contenido antes/después)
reject_case() {  # $1 = target del install; $2 (opcional) = raíz a la que se le toma la huella
  local tgt="$1" root="${2:-$1}" before after
  before="$(fs_digest "$root")"
  run_install "$tgt"
  assert_rc 2
  after="$(fs_digest "$root")"
  [ "$before" = "$after" ] && ok || ko "mutaciones tras el rechazo (la huella del filesystem difiere)"
}

t "T11a destino sin git"
NG="$TESTS_TMP/no-git"; mkdir -p "$NG"; echo propio > "$NG/keep.txt"
reject_case "$NG"

t "T11b árbol sucio"
T11B="$(mk_target t11b)"; echo x > "$T11B/pending.txt"
reject_case "$T11B"

t "T11c target subdirectorio"
T11C="$(mk_target t11c)"; mkdir -p "$T11C/sub"
reject_case "$T11C/sub" "$T11C"

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

# ── T12 · huecos cerrados en la ronda 5 ───────────────────────────────────────
t "T12a componente padre regular (archivo llamado scripts)"
T12A="$(mk_target t12a)"
echo "soy un archivo" > "$T12A/scripts"
tcommit "$T12A" "archivo scripts"
reject_case "$T12A"
assert_in_file "$T12A/scripts" "soy un archivo"

t "T12b fuente axel incompleta: rechazo sin mutaciones"
AXEL_BROKEN="$TESTS_TMP/axel-broken"
cp -R "$AXEL_SRC" "$AXEL_BROKEN"
rm "$AXEL_BROKEN/scripts/awake.sh"
T12B="$(mk_target t12b)"
before="$(fs_digest "$T12B")"
OUT="$("$AXEL_BROKEN/scripts/install.sh" "$T12B" 2>&1)" && RC=0 || RC=$?
assert_rc 2
[ "$before" = "$(fs_digest "$T12B")" ] && ok || ko "mutaciones tras rechazo por fuente incompleta"
printf '%s' "$OUT" | grep -qF "fuente inconsistente" && ok || ko "'fuente inconsistente' no está en la salida"

t "T12c settings existente como directorio (inverificable)"
T12C="$(mk_target t12c)"
mkdir -p "$T12C/.claude/settings.json"; echo x > "$T12C/.claude/settings.json/x"
tcommit "$T12C" "settings dir"
run_install "$T12C"
assert_rc 1
assert_in_file "$T12C/docs/ADOPTION.md" "no es un archivo regular"

t "T12d .gitignore trackeado sin newline final"
T12D="$(mk_target t12d)"
printf 'propio/' > "$T12D/.gitignore"    # sin salto de línea final
tcommit "$T12D" "gitignore sin newline"
run_install "$T12D"
assert_rc 0
grep -qxF 'propio/' "$T12D/.gitignore" && ok || ko "la regla previa quedó rota por el append"
grep -qxF '.claude/state/' "$T12D/.gitignore" && ok || ko "falta la entrada .claude/state/"

t "T12e deny de tipo inválido (no lista)"
T12E="$(mk_target t12e)"
mkdir -p "$T12E/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T12E/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = "Bash"
print(json.dumps(d))
PY
tcommit "$T12E" "deny string"
run_install "$T12E"
assert_rc 1
assert_in_file "$T12E/docs/ADOPTION.md" "permissions.deny no es una lista"

t "T12f deny más amplio que el permiso requerido"
T12F="$(mk_target t12f)"
mkdir -p "$T12F/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T12F/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["Bash(git:*)"]
print(json.dumps(d))
PY
tcommit "$T12F" "deny amplio"
run_install "$T12F"
assert_rc 1
assert_in_file "$T12F/docs/ADOPTION.md" "deny gana"

t "T12g política nueva con handoff abierto: persistida como payload"
AXEL_MOD="$TESTS_TMP/axel-mod"
cp -R "$AXEL_SRC" "$AXEL_MOD"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_MOD/templates/settings.json" > "$AXEL_MOD/templates/settings.json.new" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["allow"].append("Bash(true:*)")
print(json.dumps(d, indent=2))
PY
mv "$AXEL_MOD/templates/settings.json.new" "$AXEL_MOD/templates/settings.json"
T12G="$(mk_target t12g)"
echo "# notas" > "$T12G/apuntes.md"
tcommit "$T12G" "doc previo"
run_install "$T12G"; assert_rc 1               # instala con política vieja, adopción abierta
tcommit "$T12G" "install (adopción abierta)"
cp "$T12G/docs/ADOPTION.md" "$TESTS_TMP/t12g-handoff.ref"
OUT="$("$AXEL_MOD/scripts/install.sh" "$T12G" 2>&1)" && RC=0 || RC=$?
assert_rc 1
assert_same "$T12G/docs/ADOPTION.md" "$TESTS_TMP/t12g-handoff.ref"        # handoff intacto
assert_in_file "$T12G/.claude/axel-policy.json" "Bash(true:*)"            # política nueva persistida
printf '%s' "$OUT" | grep -qF "Bash(true:*)" && ok || ko "el pendiente nuevo no se reportó"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo
echo "── tests/install.sh: $PASS ok · $FAIL fail ──"
[ "$FAIL" -eq 0 ]
