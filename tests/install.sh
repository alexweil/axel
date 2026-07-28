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
# también paths ignorados (invisibles para git status), directorios vacíos y modos
fs_digest() {
  (cd "$1" && find . -name .git -prune -o \( -type f -o -type l -o -type d \) -print | LC_ALL=C sort | while IFS= read -r p; do
    if [ -L "$p" ]; then
      printf 'L %s -> %s\n' "$p" "$(readlink "$p")"
    elif [ -d "$p" ]; then
      printf 'D %s %s\n' "$(ls -ld "$p" | awk '{print $1}')" "$p"
    else
      printf 'F %s %s %s\n' "$(ls -ld "$p" | awk '{print $1}')" "$p" "$(shasum "$p" | cut -d' ' -f1)"
    fi
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

t "T10h python3 no disponible (fail-closed: rechazo, la policy fuente no es demostrable)"
TH="$(mk_target t10h)"; seed_settings "$TH"; tcommit "$TH" "settings"
before="$(fs_digest "$TH")"
OUT="$(AXEL_INSTALL_PYTHON=/nonexistent-python "$INSTALL" "$TH" 2>&1)" && RC=0 || RC=$?
assert_rc 2
[ "$before" = "$(fs_digest "$TH")" ] && ok || ko "mutaciones tras rechazo sin python3"
printf '%s' "$OUT" | grep -qF "no es demostrable" && ok || ko "falta el motivo del rechazo en la salida"

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
reject_case "$AXEL_SRC"

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

# ── T13 · huecos cerrados en la ronda 6 ───────────────────────────────────────
t "T13a deny con wildcard medio (intersección no demostrable)"
T13A="$(mk_target t13a)"
mkdir -p "$T13A/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T13A/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["Bash(git * .)"]
print(json.dumps(d))
PY
tcommit "$T13A" "deny wildcard medio"
run_install "$T13A"
assert_rc 1
assert_in_file "$T13A/docs/ADOPTION.md" "deny gana"

t "T13a2 deny de otra herramienta literal (disjunto demostrable)"
T13A2="$(mk_target t13a2)"
mkdir -p "$T13A2/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T13A2/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["WebFetch(domain:*.example.com)"]
print(json.dumps(d))
PY
tcommit "$T13A2" "deny disjunto"
run_install "$T13A2"
assert_rc 0

t "T13b policy fuente con JSON inválido: rechazo sin mutaciones"
AXEL_BADPOL="$TESTS_TMP/axel-badpol"
cp -R "$AXEL_SRC" "$AXEL_BADPOL"
echo '{ nope' > "$AXEL_BADPOL/templates/settings.json"
T13B="$(mk_target t13b)"
before="$(fs_digest "$T13B")"
OUT="$("$AXEL_BADPOL/scripts/install.sh" "$T13B" 2>&1)" && RC=0 || RC=$?
assert_rc 2
[ "$before" = "$(fs_digest "$T13B")" ] && ok || ko "mutaciones tras rechazo por policy fuente"
printf '%s' "$OUT" | grep -qF "policy fuente inválida" && ok || ko "falta el motivo en la salida"

t "T13c policy fuente con estructura inválida: rechazo sin mutaciones"
AXEL_BADPOL2="$TESTS_TMP/axel-badpol2"
cp -R "$AXEL_SRC" "$AXEL_BADPOL2"
printf '{"permissions": {"defaultMode": "acceptEdits", "allow": "todo"}}\n' > "$AXEL_BADPOL2/templates/settings.json"
T13C="$(mk_target t13c)"
before="$(fs_digest "$T13C")"
OUT="$("$AXEL_BADPOL2/scripts/install.sh" "$T13C" 2>&1)" && RC=0 || RC=$?
assert_rc 2
[ "$before" = "$(fs_digest "$T13C")" ] && ok || ko "mutaciones tras rechazo por estructura de policy"
printf '%s' "$OUT" | grep -qF "permissions.allow debe ser una lista" && ok || ko "falta el motivo en la salida"

# ── T14 · huecos cerrados en la ronda 7 ───────────────────────────────────────
t "T14a ask solapante frena el loop"
T14A="$(mk_target t14a)"
mkdir -p "$T14A/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T14A/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["ask"] = ["Bash(git add:*)"]
print(json.dumps(d))
PY
tcommit "$T14A" "ask solapante"
run_install "$T14A"
assert_rc 1
assert_in_file "$T14A/docs/ADOPTION.md" "ask puede frenarlo"

t "T14b selector por parámetro del mismo tool en deny"
T14B="$(mk_target t14b)"
mkdir -p "$T14B/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T14B/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["Bash(run_in_background:true)"]
print(json.dumps(d))
PY
tcommit "$T14B" "deny por parámetro"
run_install "$T14B"
assert_rc 1
assert_in_file "$T14B/docs/ADOPTION.md" "deny gana"

t "T14c deny de comando disjunto demostrable (mismo tool, ambos :*)"
T14C="$(mk_target t14c)"
mkdir -p "$T14C/.claude"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_SRC/templates/settings.json" > "$T14C/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["Bash(rm -rf:*)"]
print(json.dumps(d))
PY
tcommit "$T14C" "deny disjunto mismo tool"
run_install "$T14C"
assert_rc 0

t "T14d policy fuente con defaultMode fuera de contrato"
AXEL_BADMODE="$TESTS_TMP/axel-badmode"
cp -R "$AXEL_SRC" "$AXEL_BADMODE"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_BADMODE/templates/settings.json" > "$AXEL_BADMODE/templates/settings.json.new" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["defaultMode"] = "typo-mode"
print(json.dumps(d, indent=2))
PY
mv "$AXEL_BADMODE/templates/settings.json.new" "$AXEL_BADMODE/templates/settings.json"
T14D="$(mk_target t14d)"
before="$(fs_digest "$T14D")"
OUT="$("$AXEL_BADMODE/scripts/install.sh" "$T14D" 2>&1)" && RC=0 || RC=$?
assert_rc 2
[ "$before" = "$(fs_digest "$T14D")" ] && ok || ko "mutaciones tras rechazo por defaultMode"
printf '%s' "$OUT" | grep -qF 'defaultMode debe ser "acceptEdits"' && ok || ko "falta el motivo en la salida"

t "T14e policy fuente con conflicto interno deny/allow"
AXEL_CONFL="$TESTS_TMP/axel-confl"
cp -R "$AXEL_SRC" "$AXEL_CONFL"
"${AXEL_INSTALL_PYTHON:-python3}" - "$AXEL_CONFL/templates/settings.json" > "$AXEL_CONFL/templates/settings.json.new" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["permissions"]["deny"] = ["Bash(git:*)"]
print(json.dumps(d, indent=2))
PY
mv "$AXEL_CONFL/templates/settings.json.new" "$AXEL_CONFL/templates/settings.json"
T14E="$(mk_target t14e)"
before="$(fs_digest "$T14E")"
OUT="$("$AXEL_CONFL/scripts/install.sh" "$T14E" 2>&1)" && RC=0 || RC=$?
assert_rc 2
[ "$before" = "$(fs_digest "$T14E")" ] && ok || ko "mutaciones tras rechazo por conflicto interno"
printf '%s' "$OUT" | grep -qF "conflicto interno" && ok || ko "falta el motivo en la salida"

# ── T15 · bootstrap remoto (--from): fixtures locales, sin red ────────────────
# El "remoto" es un clon local de la fuente (git clone acepta paths); AXEL_HOME se
# apunta a un directorio temporal por caso. La huella de "cache intacto" cubre el
# worktree (sin .git): la promesa es no pisar trabajo, no congelar refs internas.
R15="$TESTS_TMP/r15"
git clone -q -- "$AXEL_SRC" "$R15"
BOOT_TIMEOUT=3
run_boot() {  # $1=AXEL_HOME $2=url $3=target
  OUT="$(AXEL_HOME="$1" AXEL_BOOTSTRAP_LOCK_TIMEOUT="$BOOT_TIMEOUT" "$INSTALL" --from "$2" "$3" 2>&1)" && RC=0 || RC=$?
}
boot_reject() {  # rc2 y cero mutaciones de destino (y de cache, si existe como dir)
  local before_t before_c=""
  before_t="$(fs_digest "$3")"
  [ -d "$1" ] && before_c="$(fs_digest "$1")"
  run_boot "$1" "$2" "$3"
  assert_rc 2
  [ "$before_t" = "$(fs_digest "$3")" ] && ok || ko "mutaciones en el destino tras el rechazo"
  if [ -n "$before_c" ]; then
    [ "$before_c" = "$(fs_digest "$1")" ] && ok || ko "mutaciones en el worktree del cache tras el rechazo"
  fi
}
mk_stub_remote() {  # $1=nombre $2=contenido de scripts/install.sh (stub de delegado)
  local r="$TESTS_TMP/$1"
  mkdir -p "$r/scripts"
  printf '%s\n' "$2" > "$r/scripts/install.sh"
  chmod +x "$r/scripts/install.sh"
  git -C "$r" init -q -b main
  tcommit "$r" stub
  printf '%s' "$r"
}

t "T15a bootstrap fresco: clona (padre inexistente fuera del destino), delega, marker == HEAD del remoto"
H15A="$TESTS_TMP/home15a/axel"       # el padre home15a/ no existe: se crea
T15A="$(mk_target t15a)"
run_boot "$H15A" "$R15" "$T15A"
assert_rc 0
assert_file "$T15A/AGENTS.md"
assert_file "$T15A/scripts/review.sh"
assert_in_file "$T15A/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"
assert_no "$H15A.lock"               # lock liberado
assert_out "modo: initial"
assert_out "axel bootstrap"

t "T15b re-run con remoto avanzado: ff-update del cache y SHA nuevo en el destino"
tcommit "$T15A" "install inicial"
echo "avance remoto" >> "$R15/README.md"
tcommit "$R15" "avance"
run_boot "$H15A" "$R15" "$T15A"
assert_rc 0
assert_out "modo: update"
[ "$(git -C "$H15A" rev-parse HEAD)" = "$(git -C "$R15" rev-parse HEAD)" ] && ok || ko "el cache no quedó en el tip del remoto"
assert_in_file "$T15A/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"
assert_dirty "$T15A"                 # el update del destino registró el SHA nuevo

t "T15c cache sucio: rechazo, trabajo intacto"
H15C="$TESTS_TMP/home15c"
git clone -q -- "$R15" "$H15C"
echo "trabajo humano" >> "$H15C/README.md"
T15C="$(mk_target t15c)"
boot_reject "$H15C" "$R15" "$T15C"
assert_out "cambios sin commitear"
assert_in_file "$H15C/README.md" "trabajo humano"

t "T15d cache ahead (commit local, árbol limpio): el caso que pull --ff-only no ve"
H15D="$TESTS_TMP/home15d"
git clone -q -- "$R15" "$H15D"
echo "no publicado" > "$H15D/local.txt"
tcommit "$H15D" "commit local"
ahead_sha="$(git -C "$H15D" rev-parse HEAD)"
T15D="$(mk_target t15d)"
boot_reject "$H15D" "$R15" "$T15D"
assert_out "commits que el remoto no conoce"
[ "$(git -C "$H15D" rev-parse HEAD)" = "$ahead_sha" ] && ok || ko "el commit local fue movido"

t "T15e cache divergido"
H15E="$TESTS_TMP/home15e"
git clone -q -- "$R15" "$H15E"
echo "rama local" > "$H15E/local.txt"; tcommit "$H15E" "local"
echo "el remoto avanza" >> "$R15/README.md"; tcommit "$R15" "remoto avanza"
T15E="$(mk_target t15e)"
boot_reject "$H15E" "$R15" "$T15E"
assert_out "commits que el remoto no conoce"

t "T15f cache detached"
H15F="$TESTS_TMP/home15f"
git clone -q -- "$R15" "$H15F"
git -C "$H15F" checkout -q --detach
T15F="$(mk_target t15f)"
boot_reject "$H15F" "$R15" "$T15F"
assert_out "detached HEAD"

t "T15g cache en otro branch"
H15G="$TESTS_TMP/home15g"
git clone -q -- "$R15" "$H15G"
git -C "$H15G" checkout -q -b feature
T15G="$(mk_target t15g)"
boot_reject "$H15G" "$R15" "$T15G"
assert_out "default real del remoto"

t "T15h cache con otro origin"
H15H="$TESTS_TMP/home15h"
git clone -q -- "$R15" "$H15H"
git -C "$H15H" remote set-url origin "$TESTS_TMP/otro-lado"
T15H="$(mk_target t15h)"
boot_reject "$H15H" "$R15" "$T15H"
assert_out "apunta a otro origin"

t "T15i AXEL_HOME archivo regular / directorio no-repo"
H15I="$TESTS_TMP/home15i"; echo "propio" > "$H15I"
T15I="$(mk_target t15i)"
run_boot "$H15I" "$R15" "$T15I"
assert_rc 2; assert_out "no es un directorio"; assert_in_file "$H15I" "propio"
rm "$H15I"; mkdir -p "$H15I"; echo "propio" > "$H15I/cosa.txt"
boot_reject "$H15I" "$R15" "$T15I"
assert_out "no es un repo git"; assert_in_file "$H15I/cosa.txt" "propio"

t "T15k1 metadata local adulterada: origin/HEAD + branch + upstream hacia 'feature' (repro r2)"
H15K="$TESTS_TMP/home15k"
git clone -q -- "$R15" "$H15K"
git -C "$H15K" branch -q feature
git -C "$H15K" checkout -q feature
git -C "$H15K" update-ref refs/remotes/origin/feature "$(git -C "$H15K" rev-parse HEAD)"
git -C "$H15K" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/feature
git -C "$H15K" config branch.feature.remote origin
git -C "$H15K" config branch.feature.merge refs/heads/feature
T15K="$(mk_target t15k)"
boot_reject "$H15K" "$R15" "$T15K"
assert_out "default real del remoto"

t "T15k2 remote.origin.fetch adulterado: inocuo (fetch por URL con refspec explícito)"
H15K2="$TESTS_TMP/home15k2"
git clone -q -- "$R15" "$H15K2"
git -C "$H15K2" config remote.origin.fetch '+refs/heads/nonexistent:refs/remotes/origin/main'
echo "otro avance" >> "$R15/README.md"; tcommit "$R15" "avance 2"
T15K2="$(mk_target t15k2)"
run_boot "$H15K2" "$R15" "$T15K2"
assert_rc 0
assert_in_file "$T15K2/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"

t "T15k3 remoto que no informa symref de HEAD (bare detached): fail-closed"
BARE15="$TESTS_TMP/bare15"
git clone -q --bare -- "$R15" "$BARE15"
git --git-dir="$BARE15" update-ref --no-deref HEAD "$(git --git-dir="$BARE15" rev-parse refs/heads/main)"
H15K3="$TESTS_TMP/home15k3"
T15K3="$(mk_target t15k3)"
before="$(fs_digest "$T15K3")"
run_boot "$H15K3" "$BARE15" "$T15K3"
assert_rc 2
assert_out "no informa su branch default"
[ "$before" = "$(fs_digest "$T15K3")" ] && ok || ko "mutaciones en el destino"
assert_no "$H15K3"                   # ni siquiera se clonó

t "T15l1 disjunción: AXEL_HOME == destino"
T15L1="$(mk_target t15l1)"
boot_reject "$T15L1" "$R15" "$T15L1"
assert_out "no son disjuntos"

t "T15l2 disjunción: AXEL_HOME adentro del destino con padres inexistentes (pre-mkdir)"
T15L2="$(mk_target t15l2)"
boot_reject "$T15L2/a/b/axel" "$R15" "$T15L2"
assert_out "no son disjuntos"
assert_no "$T15L2/a"

t "T15l3 disjunción: destino adentro del cache"
H15L3="$TESTS_TMP/home15l3"
git clone -q -- "$R15" "$H15L3"
mkdir -p "$H15L3/subdestino"
run_boot "$H15L3" "$R15" "$H15L3/subdestino"
assert_rc 2; assert_out "no son disjuntos"

t "T15l4 disjunción: el lock coincide con el destino"
P15L4="$TESTS_TMP/l4"; mkdir -p "$P15L4/x.lock"
run_boot "$P15L4/x" "$R15" "$P15L4/x.lock"
assert_rc 2; assert_out "lock del cache y el destino no son disjuntos"

t "T15l5 disjunción: '..' en el sufijo inexistente de AXEL_HOME no la esquiva (repro r5)"
T15L5="$(mk_target t15l5)"
boot_reject "$TESTS_TMP/missing15/../t15l5/cache" "$R15" "$T15L5"
assert_out "no son disjuntos"
assert_no "$T15L5/cache"

t "T15m URL option-like: rechazada antes de invocar git"
H15M="$TESTS_TMP/home15m"
T15M="$(mk_target t15m)"
run_boot "$H15M" "--upload-pack=/bin/true" "$T15M"
assert_rc 2; assert_out "no puede empezar con '-'"; assert_no "$H15M"

t "T15n1 remoto malformado: sin scripts/install.sh"
RN15="$TESTS_TMP/rn15"; mkdir -p "$RN15"
echo "no soy axel" > "$RN15/README.md"
git -C "$RN15" init -q -b main; tcommit "$RN15" "no axel"
H15N="$TESTS_TMP/home15n"
T15N="$(mk_target t15n)"
run_boot "$H15N" "$RN15" "$T15N"
assert_rc 2; assert_out "no parece axel"

t "T15n2 remoto con install.sh sin bit de ejecución"
RN15B="$TESTS_TMP/rn15b"; mkdir -p "$RN15B/scripts"
echo "#!/usr/bin/env bash" > "$RN15B/scripts/install.sh"   # sin chmod +x
git -C "$RN15B" init -q -b main; tcommit "$RN15B" "sin bit x"
H15NB="$TESTS_TMP/home15nb"
T15NB="$(mk_target t15nb)"
run_boot "$H15NB" "$RN15B" "$T15NB"
assert_rc 2; assert_out "no parece axel"

t "T15o red rota: remoto inexistente (fresco) y remoto desaparecido (cache existente)"
H15O="$TESTS_TMP/home15o"
T15O="$(mk_target t15o)"
run_boot "$H15O" "$TESTS_TMP/no-existe-remoto" "$T15O"
assert_rc 2; assert_out "no pude consultar el remoto"; assert_no "$H15O"
R15GONE="$TESTS_TMP/r15gone"
git clone -q -- "$R15" "$R15GONE"
git clone -q -- "$R15GONE" "$H15O"
rm -rf "$R15GONE"
boot_reject "$H15O" "$R15GONE" "$T15O"
assert_out "no pude consultar el remoto"

t "T15p1 lock de pid vivo: espera y timeout, sin borrar"
H15P="$TESTS_TMP/home15p"
git clone -q -- "$R15" "$H15P"
ln -s "axel-bootstrap pid=$$ host=$(hostname)" "$H15P.lock"
T15P="$(mk_target t15p)"
run_boot "$H15P" "$R15" "$T15P"
assert_rc 2; assert_out "en poder del pid $$"
assert_link "$H15P.lock" "axel-bootstrap pid=$$ host=$(hostname)"
rm "$H15P.lock"

t "T15p2 lock de pid muerto: rechazo inmediato sin borrar"
sleep 0 & DEAD15=$!
wait "$DEAD15" 2>/dev/null || true
ln -s "axel-bootstrap pid=$DEAD15 host=$(hostname)" "$H15P.lock"
run_boot "$H15P" "$R15" "$T15P"
assert_rc 2; assert_out "ya no existe"
assert_link "$H15P.lock" "axel-bootstrap pid=$DEAD15 host=$(hostname)"
rm "$H15P.lock"

t "T15p3 lock ajeno (directorio / archivo / symlink inválido): rechazo sin borrar"
mkdir "$H15P.lock"
run_boot "$H15P" "$R15" "$T15P"
assert_rc 2; assert_out "no es un lock de axel"
[ -d "$H15P.lock" ] && ok || ko "el directorio ajeno fue borrado"
rmdir "$H15P.lock"
echo "ajeno" > "$H15P.lock"
run_boot "$H15P" "$R15" "$T15P"
assert_rc 2; assert_out "no es un lock de axel"; assert_in_file "$H15P.lock" "ajeno"
rm "$H15P.lock"
ln -s "cualquier-cosa" "$H15P.lock"
run_boot "$H15P" "$R15" "$T15P"
assert_rc 2; assert_out "sin formato de lock"
assert_link "$H15P.lock" "cualquier-cosa"
rm "$H15P.lock"

t "T15p4 señal al wrapper con delegado vivo: el lock persiste hasta la muerte del hijo"
RSLOW="$(mk_stub_remote rslow '#!/usr/bin/env bash
trap "" TERM
echo started > "$1/.boot-started"
sleep 3
exit 0')"
H15P4="$TESTS_TMP/home15p4"
T15P4="$(mk_target t15p4)"
AXEL_HOME="$H15P4" "$INSTALL" --from "$RSLOW" "$T15P4" > "$TESTS_TMP/p4.out" 2>&1 & WRAP15=$!
p4_waited=0
until [ -f "$T15P4/.boot-started" ] || [ "$p4_waited" -ge 50 ]; do sleep 0.1; p4_waited=$((p4_waited + 1)); done
[ -f "$T15P4/.boot-started" ] && ok || ko "el delegado stub nunca arrancó"
kill -TERM "$WRAP15"
sleep 0.5
[ -L "$H15P4.lock" ] && ok || ko "el lock se soltó con el delegado vivo"
rc15p4=0; wait "$WRAP15" || rc15p4=$?
[ "$rc15p4" -eq 2 ] && ok || ko "wrapper señalado: exit esperado 2, fue $rc15p4"
assert_no "$H15P4.lock"              # liberado recién tras la muerte del hijo
grep -qF "interrumpido por señal" "$TESTS_TMP/p4.out" && ok || ko "falta el aviso de interrupción"

t "T15p5 smoke concurrente: dos bootstraps comparten cache, ambos exit 0"
H15P5="$TESTS_TMP/home15p5"
T15P5A="$(mk_target t15p5a)"; T15P5B="$(mk_target t15p5b)"
AXEL_HOME="$H15P5" "$INSTALL" --from "$R15" "$T15P5A" > "$TESTS_TMP/p5a.out" 2>&1 & P5A=$!
AXEL_HOME="$H15P5" "$INSTALL" --from "$R15" "$T15P5B" > "$TESTS_TMP/p5b.out" 2>&1 & P5B=$!
rc5a=0; wait "$P5A" || rc5a=$?
rc5b=0; wait "$P5B" || rc5b=$?
[ "$rc5a" -eq 0 ] && ok || ko "bootstrap concurrente A: exit $rc5a · $(tail -2 "$TESTS_TMP/p5a.out" | tr '\n' ' ')"
[ "$rc5b" -eq 0 ] && ok || ko "bootstrap concurrente B: exit $rc5b · $(tail -2 "$TESTS_TMP/p5b.out" | tr '\n' ' ')"
sha5a="$(sed -n '2p' "$T15P5A/.claude/axel-install")"
sha5b="$(sed -n '2p' "$T15P5B/.claude/axel-install")"
{ [ -n "$sha5a" ] && [ "$sha5a" = "$sha5b" ]; } && ok || ko "markers con SHA distinto: '$sha5a' vs '$sha5b'"
assert_no "$H15P5.lock"

t "T15q1 passthrough exit 1: adopción a través del bootstrap"
H15Q="$TESTS_TMP/home15q"
T15Q="$(mk_target t15q)"
echo "# notas del proyecto" > "$T15Q/NOTAS.md"
tcommit "$T15Q" "doc propio"
run_boot "$H15Q" "$R15" "$T15Q"
assert_rc 1
assert_file "$T15Q/docs/ADOPTION.md"
assert_in_file "$T15Q/docs/ADOPTION.md" "NOTAS.md"

t "T15q2 passthrough exit 2 del delegado: destino sucio"
T15Q2="$(mk_target t15q2)"
echo "pendiente" > "$T15Q2/pendiente.txt"
run_boot "$H15Q" "$R15" "$T15Q2"
assert_rc 2; assert_out "no está limpio"

t "T15r1 delegado con RC no contractual: normalizado a 2 con aviso, lock liberado"
RNC15="$(mk_stub_remote rnc15 '#!/usr/bin/env bash
exit 7')"
H15R="$TESTS_TMP/home15r"
T15R="$(mk_target t15r)"
run_boot "$H15R" "$RNC15" "$T15R"
assert_rc 2; assert_out "código anómalo (7)"; assert_no "$H15R.lock"

t "T15r2 delegado que no lanza (bad interpreter): normalizado a 2"
RBI15="$(mk_stub_remote rbi15 '#!/nonexistent-interp-xyz
exit 0')"
H15R2="$TESTS_TMP/home15r2"
T15R2="$(mk_target t15r2)"
run_boot "$H15R2" "$RBI15" "$T15R2"
assert_rc 2; assert_out "código anómalo"; assert_no "$H15R2.lock"

t "T15r3 delegado que muta el destino y muere por señal: 2 + aviso + diff parcial visible"
RSK15="$(mk_stub_remote rsk15 '#!/usr/bin/env bash
echo mutacion > "$1/parcial.txt"
kill -KILL $$')"
H15R3="$TESTS_TMP/home15r3"
T15R3="$(mk_target t15r3)"
run_boot "$H15R3" "$RSK15" "$T15R3"
assert_rc 2; assert_out "código anómalo"; assert_out "revisá"
assert_file "$T15R3/parcial.txt"     # el diff parcial queda visible para git status
assert_dirty "$T15R3"
assert_no "$H15R3.lock"

t "T15s1 piped (bash -s por stdin) con cwd adentro de otro repo git"
H15S="$TESTS_TMP/home15s"
T15S="$(mk_target t15s)"
OUT="$(cd "$T15S" && AXEL_HOME="$H15S" AXEL_BOOTSTRAP_LOCK_TIMEOUT="$BOOT_TIMEOUT" bash -s -- --from "$R15" "$T15S" < "$INSTALL" 2>&1)" && RC=0 || RC=$?
assert_rc 0
assert_file "$T15S/AGENTS.md"
assert_in_file "$T15S/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"

t "T15s2 piped sin --from: rechazo con mensaje que apunta a --from"
T15S2="$(mk_target t15s2)"
OUT="$(cd "$T15S2" && bash -s -- "$T15S2" < "$INSTALL" 2>&1)" && RC=0 || RC=$?
assert_rc 2
assert_out "usá: install.sh --from"
assert_clean "$T15S2"

t "T15t1 skip-worktree oculta un reemplazo del delegado: rechazo (repro r5)"
H15T1="$TESTS_TMP/home15t1"
git clone -q -- "$R15" "$H15T1"
git -C "$H15T1" update-index --skip-worktree scripts/install.sh
printf '#!/usr/bin/env bash\necho pwned > "$1/COMPROMISED"\nexit 0\n' > "$H15T1/scripts/install.sh"
[ -z "$(git -C "$H15T1" status --porcelain)" ] && ok || ko "precondición: el reemplazo debía ser invisible para git status"
T15T1="$(mk_target t15t1)"
boot_reject "$H15T1" "$R15" "$T15T1"
assert_out "ocultan cambios"
assert_no "$T15T1/COMPROMISED"

t "T15t2 assume-unchanged oculta un reemplazo: rechazo"
H15T2="$TESTS_TMP/home15t2"
git clone -q -- "$R15" "$H15T2"
git -C "$H15T2" update-index --assume-unchanged scripts/install.sh
printf '#!/usr/bin/env bash\nexit 0\n' > "$H15T2/scripts/install.sh"
T15T2="$(mk_target t15t2)"
boot_reject "$H15T2" "$R15" "$T15T2"
assert_out "ocultan cambios"

t "T15t3 post-merge hook del cache: deshabilitado durante el ff-update"
H15T3="$TESTS_TMP/home15t3"
git clone -q -- "$R15" "$H15T3"
mkdir -p "$H15T3/.git/hooks"
printf '#!/bin/sh\necho pwned > "$(git rev-parse --show-toplevel)/HOOKED"\n' > "$H15T3/.git/hooks/post-merge"
chmod +x "$H15T3/.git/hooks/post-merge"
echo "avance 3" >> "$R15/README.md"; tcommit "$R15" "avance 3"   # deja el cache behind: el ff-merge sucede
T15T3="$(mk_target t15t3)"
run_boot "$H15T3" "$R15" "$T15T3"
assert_rc 0
assert_no "$H15T3/HOOKED"            # el hook no corrió
assert_in_file "$T15T3/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"

t "T15t4 delegado symlink en el remoto (apunta fuera del clon): rechazo sin ejecutar (repro r5)"
EVIL15="$TESTS_TMP/evil15.sh"
printf '#!/bin/sh\necho pwned > "$1/SYMLINK_EXECUTED"\nexit 0\n' > "$EVIL15"
chmod +x "$EVIL15"
REXT15="$TESTS_TMP/rext15"; mkdir -p "$REXT15/scripts"
ln -s "$EVIL15" "$REXT15/scripts/install.sh"
git -C "$REXT15" init -q -b main; tcommit "$REXT15" "delegado symlink"
H15T4="$TESTS_TMP/home15t4"
T15T4="$(mk_target t15t4)"
run_boot "$H15T4" "$REXT15" "$T15T4"
assert_rc 2
assert_out "no parece axel"
assert_no "$T15T4/SYMLINK_EXECUTED"

t "T15t5 --from con URL vacía: rechazo, jamás cae al modo local (repro r5)"
T15T5="$(mk_target t15t5)"
OUT="$("$INSTALL" --from "" "$T15T5" 2>&1)" && RC=0 || RC=$?
assert_rc 2
assert_out "no puede ser vacía"
assert_no "$T15T5/AGENTS.md"
assert_clean "$T15T5"

t "T15t6 gitlink primero + árbol grande: RC 2 contractual con diagnóstico, sin SIGPIPE (repro r6)"
RBIG15="$TESTS_TMP/rbig15"; mkdir -p "$RBIG15/files"
git -C "$RBIG15" init -q -b main
git -C "$RBIG15" update-index --add --cacheinfo "160000,$(git -C "$R15" rev-parse HEAD),000sub"
i=1; while [ "$i" -le 2000 ]; do echo "relleno $i" > "$RBIG15/files/f$i"; i=$((i + 1)); done
git -C "$RBIG15" add files
git -C "$RBIG15" -c user.email=t@t -c user.name=t commit -qm "gitlink + arbol grande"
H15T6="$TESTS_TMP/home15t6"
T15T6="$(mk_target t15t6)"
before="$(fs_digest "$T15T6")"
run_boot "$H15T6" "$RBIG15" "$T15T6"
assert_rc 2
assert_out "tipo 160000 inesperado"
[ "$before" = "$(fs_digest "$T15T6")" ] && ok || ko "mutaciones en el destino"
assert_no "$H15T6.lock"

t "T15t7 caller desde un repo SHA-256: los hashes se computan en el contexto del cache (repro r6)"
SR15="$TESTS_TMP/sha256repo"; mkdir -p "$SR15"
git -C "$SR15" init -q --object-format=sha256 -b main
H15T7="$TESTS_TMP/home15t7"
T15T7="$(mk_target t15t7)"
OUT="$(cd "$SR15" && AXEL_HOME="$H15T7" AXEL_BOOTSTRAP_LOCK_TIMEOUT="$BOOT_TIMEOUT" "$INSTALL" --from "$R15" "$T15T7" 2>&1)" && RC=0 || RC=$?
assert_rc 0
assert_in_file "$T15T7/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"

t "T15t8 reference-transaction hook en fetch: deshabilitado; tags implícitos no entran (repro r6)"
H15T8="$TESTS_TMP/home15t8"
git clone -q -- "$R15" "$H15T8"
mkdir -p "$H15T8/.git/hooks"
printf '#!/bin/sh\ntouch "%s/FETCH_HOOKED"\n' "$TESTS_TMP" > "$H15T8/.git/hooks/reference-transaction"
chmod +x "$H15T8/.git/hooks/reference-transaction"
echo "avance 4" >> "$R15/README.md"; tcommit "$R15" "avance 4"
git -C "$R15" tag v-test15   # tag alcanzable: el auto-follow lo traería
T15T8="$(mk_target t15t8)"
run_boot "$H15T8" "$R15" "$T15T8"
assert_rc 0
[ ! -e "$TESTS_TMP/FETCH_HOOKED" ] && ok || ko "el hook reference-transaction corrió durante el fetch"
[ -z "$(git -C "$H15T8" tag -l v-test15)" ] && ok || ko "el tag implícito entró al cache pese a --no-tags"
assert_in_file "$T15T8/.claude/axel-install" "axel-sha: $(git -C "$R15" rev-parse HEAD)"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo
echo "── tests/install.sh: $PASS ok · $FAIL fail ──"
[ "$FAIL" -eq 0 ]
