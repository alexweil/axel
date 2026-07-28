#!/usr/bin/env bash
# axel · installer: lleva la maquinaria de axel a un repo destino
#
# Uso:
#   scripts/install.sh <target-dir>                    # modo local: desde un clon de axel
#   scripts/install.sh --from <url> <target-dir>       # bootstrap remoto: sin clon previo
#   curl -fsSL <raw>/scripts/install.sh | bash -s -- --from <url> <target-dir>
#
# Con --from clona/actualiza un cache de axel (AXEL_HOME, default ~/.axel) fail-closed
# y delega en el install.sh de ese clon; el modo local no cambia de contrato.
# Tres modos de instalación, clasificados por el marker .claude/axel-install del destino:
#   - corrida inicial (sin marker): inventario, siembra, payload, handoff si hay pendientes
#   - actualización (con marker): payload + re-verificación; nunca reabre una adopción cerrada
# Detalle completo: docs/implementation/01-installer.md y 02-remote-install.md del repo axel.
#
# Exit: 0 = instalado/actualizado sin pendientes
#       1 = instalado/actualizado con pendientes (handoff en docs/ADOPTION.md; siguiente paso: /adopt)
#       2 = rechazo sin mutaciones del destino — o, señalado con aviso explícito, un
#           delegado interrumpido con RC anómalo (posible diff parcial: revisar git status)
set -euo pipefail

die() { echo "rechazo: $*" >&2; exit 2; }
canon_dir() { (cd "$1" 2>/dev/null && pwd -P); }
usage() { echo "uso: $0 [--from <url>] <target-dir>" >&2; exit 2; }

# ── Bootstrap remoto (--from): corre ANTES de toda resolución de AXEL_ROOT ────
# En modo piped no hay $0 en disco: nada de este bloque depende del entorno del
# script que corre — la fuente que instala es siempre el clon del cache.
FROM_MODE=""
FROM_URL=""
if [ "${1:-}" = "--from" ]; then
  [ $# -eq 3 ] || usage
  FROM_MODE=1
  FROM_URL="$2"
  shift 2
fi
[ $# -eq 1 ] || usage

if [ -n "$FROM_MODE" ]; then
  # el flag de modo es independiente del contenido: --from "" jamás cae al modo local
  [ -n "$FROM_URL" ] || die "--from: la URL no puede ser vacía"
  case "$FROM_URL" in
    -*) die "--from: la URL no puede empezar con '-' (se confundiría con una opción de git): $FROM_URL" ;;
  esac
  [ -d "$1" ] || die "el destino no existe o no es un directorio: $1"
  BOOT_TARGET="$(canon_dir "$1")" || die "no pude resolver el path del destino: $1"

  # Canonicaliza aunque el path no exista: ancestro existente más profundo + resto.
  # Así un cache/lock planeado adentro del destino con padres sin crear también se detecta.
  canon_path() {
    local p="$1" rest="" d=""
    while ! d="$(canon_dir "$p")"; do
      rest="/$(basename "$p")$rest"
      p="$(dirname "$p")"
    done
    [ "$d" = "/" ] && d=""
    # normalización léxica de . y .. en el sufijo inexistente (el ancestro ya es
    # canónico): sin esto un ../ en el sufijo esquiva la disjunción y el clone
    # aterriza en otro lado (p. ej. adentro del destino)
    local out="$d" comp oldIFS="$IFS"
    set -f; IFS='/'
    for comp in $rest; do
      case "$comp" in
        '' | '.') ;;
        '..') out="${out%/*}" ;;
        *) out="$out/$comp" ;;
      esac
    done
    set +f; IFS="$oldIFS"
    printf '%s' "$out"
  }
  path_overlaps() {  # iguales o uno dentro del otro
    case "$1" in "$2" | "$2"/*) return 0 ;; esac
    case "$2" in "$1"/*) return 0 ;; esac
    return 1
  }
  BOOT_CACHE="$(canon_path "${AXEL_HOME:-$HOME/.axel}")"
  BOOT_LOCK="$BOOT_CACHE.lock"
  if path_overlaps "$BOOT_CACHE" "$BOOT_TARGET"; then
    die "cache y destino no son disjuntos ($BOOT_CACHE vs $BOOT_TARGET); el bootstrap no puede mutar el destino — usá otro AXEL_HOME"
  fi
  if path_overlaps "$BOOT_LOCK" "$BOOT_TARGET"; then
    die "el lock del cache y el destino no son disjuntos ($BOOT_LOCK vs $BOOT_TARGET) — usá otro AXEL_HOME"
  fi

  # Lock: symlink atómico con la propiedad en el target (pid + host). Jamás se libera
  # con el delegado vivo; pid muerto o lock ajeno ⇒ rechazo sin borrar nada (fail-closed).
  mkdir -p "$(dirname "$BOOT_CACHE")" || die "no pude crear el directorio padre del cache: $(dirname "$BOOT_CACHE")"
  LOCK_TOKEN="axel-bootstrap pid=$$ host=$(hostname)"
  BOOT_CHILD=""
  boot_cleanup() {
    if [ -n "$BOOT_CHILD" ] && kill -0 "$BOOT_CHILD" 2>/dev/null; then
      kill -TERM "$BOOT_CHILD" 2>/dev/null || true
      wait "$BOOT_CHILD" 2>/dev/null || true   # esperar la muerte del hijo antes de soltar
    fi
    [ "$(readlink "$BOOT_LOCK" 2>/dev/null)" = "$LOCK_TOKEN" ] && rm -f "$BOOT_LOCK"
    return 0
  }
  boot_on_signal() {
    boot_cleanup
    echo "rechazo: bootstrap interrumpido por señal" >&2
    exit 2
  }
  lock_wait=0
  lock_timeout="${AXEL_BOOTSTRAP_LOCK_TIMEOUT:-60}"
  while :; do
    # ln -s sobre un directorio existente crearía el link ADENTRO (no falla): el caso
    # directorio-ajeno se rechaza antes de intentar, y la adquisición se verifica después.
    if [ -d "$BOOT_LOCK" ] && [ ! -L "$BOOT_LOCK" ]; then
      die "$BOOT_LOCK: existe y no es un lock de axel (directorio ajeno); no lo borro — verificá y movelo a mano"
    fi
    if ln -s "$LOCK_TOKEN" "$BOOT_LOCK" 2>/dev/null; then
      [ "$(readlink "$BOOT_LOCK" 2>/dev/null)" = "$LOCK_TOKEN" ] && break
      rm -f "$BOOT_LOCK/$LOCK_TOKEN" 2>/dev/null || true   # residuo propio dentro de un dir ajeno aparecido en el medio
      die "$BOOT_LOCK: apareció un objeto ajeno mientras tomaba el lock; verificá y movelo a mano"
    fi
    if [ ! -L "$BOOT_LOCK" ]; then
      [ -e "$BOOT_LOCK" ] || continue   # desapareció entre el intento y el chequeo: reintentar
      die "$BOOT_LOCK: existe y no es un lock de axel (¿archivo ajeno?); no lo borro — verificá y movelo a mano"
    fi
    lock_tok="$(readlink "$BOOT_LOCK" 2>/dev/null || true)"
    lock_pid="$(printf '%s' "$lock_tok" | sed -n 's/^axel-bootstrap pid=\([0-9][0-9]*\) host=..*$/\1/p')"
    [ -n "$lock_pid" ] || die "$BOOT_LOCK: symlink sin formato de lock de axel; no lo borro — verificá y movelo a mano"
    lock_host="${lock_tok##* host=}"
    [ "$lock_host" = "$(hostname)" ] \
      || die "$BOOT_LOCK: lock tomado desde otro host ($lock_host); no puedo verificar su proceso — resolvelo a mano"
    kill -0 "$lock_pid" 2>/dev/null \
      || die "$BOOT_LOCK: lock de un proceso que ya no existe (pid $lock_pid); verificá que no corra otra instalación y borralo a mano: rm '$BOOT_LOCK'"
    [ "$lock_wait" -lt "$lock_timeout" ] \
      || die "$BOOT_LOCK: en poder del pid $lock_pid tras ${lock_timeout}s de espera; reintentá cuando termine"
    sleep 1
    lock_wait=$((lock_wait + 1))
  done
  trap boot_cleanup EXIT
  trap boot_on_signal INT TERM

  # La verdad del branch default y de su tip viene del remoto, jamás de metadata
  # local del cache (origin/HEAD, upstream y remote.*.fetch son adulterables).
  symref_out="$(git ls-remote --symref -- "$FROM_URL" HEAD 2>/dev/null)" \
    || die "no pude consultar el remoto: $FROM_URL (¿URL o red?)"
  DEFAULT_BRANCH="$(printf '%s\n' "$symref_out" | sed -n 's|^ref: refs/heads/\(..*\)[[:space:]]HEAD$|\1|p' | head -1)"
  [ -n "$DEFAULT_BRANCH" ] || die "el remoto no informa su branch default (symref de HEAD); la fuente no es demostrable — fail-closed"

  url_norm() { local u="${1%/}"; printf '%s' "${u%.git}"; }
  if [ -e "$BOOT_CACHE" ] || [ -L "$BOOT_CACHE" ]; then
    [ -d "$BOOT_CACHE" ] || die "AXEL_HOME existe y no es un directorio: $BOOT_CACHE; no lo piso — resolvelo a mano"
    git -C "$BOOT_CACHE" rev-parse --show-toplevel >/dev/null 2>&1 \
      || die "AXEL_HOME existe y no es un repo git: $BOOT_CACHE; no lo piso — resolvelo a mano"
    cache_top="$(canon_dir "$(git -C "$BOOT_CACHE" rev-parse --show-toplevel)")"
    [ "$cache_top" = "$BOOT_CACHE" ] || die "AXEL_HOME no es el toplevel de su repo ($cache_top): $BOOT_CACHE"
    cache_origin="$(git -C "$BOOT_CACHE" remote get-url origin 2>/dev/null)" \
      || die "AXEL_HOME no tiene remote origin: $BOOT_CACHE; no puedo demostrar su procedencia — resolvelo a mano"
    [ "$(url_norm "$cache_origin")" = "$(url_norm "$FROM_URL")" ] \
      || die "AXEL_HOME apunta a otro origin ($cache_origin, pedido: $FROM_URL); usá otro AXEL_HOME o resolvelo a mano"
    [ -z "$(git -C "$BOOT_CACHE" status --porcelain)" ] \
      || die "AXEL_HOME tiene cambios sin commitear ($BOOT_CACHE); no piso trabajo que podría ser tuyo — resolvelo a mano"
  else
    git -c core.hooksPath=/dev/null clone --quiet --template= -- "$FROM_URL" "$BOOT_CACHE" >/dev/null 2>&1 \
      || die "git clone falló: $FROM_URL → $BOOT_CACHE (¿URL o red?)"
  fi

  cur_branch="$(git -C "$BOOT_CACHE" symbolic-ref --quiet --short HEAD)" \
    || die "AXEL_HOME está en detached HEAD y el default real del remoto es '$DEFAULT_BRANCH' ($BOOT_CACHE); resolvelo a mano"
  [ "$cur_branch" = "$DEFAULT_BRANCH" ] \
    || die "AXEL_HOME está en el branch '$cur_branch' y el default real del remoto es '$DEFAULT_BRANCH' ($BOOT_CACHE); resolvelo a mano"

  git -C "$BOOT_CACHE" -c core.hooksPath=/dev/null fetch --no-tags --quiet -- "$FROM_URL" "refs/heads/$DEFAULT_BRANCH" 2>/dev/null \
    || die "git fetch falló: $FROM_URL (¿red?)"
  remote_tip="$(git -C "$BOOT_CACHE" rev-parse FETCH_HEAD)" || die "no pude leer FETCH_HEAD tras el fetch"
  if [ "$(git -C "$BOOT_CACHE" rev-parse HEAD)" != "$remote_tip" ]; then
    # Ancestría explícita: pull --ff-only devuelve 0 con commits locales ahead
    git -C "$BOOT_CACHE" merge-base --is-ancestor HEAD "$remote_tip" \
      || die "AXEL_HOME tiene commits que el remoto no conoce (ahead o divergido); no instalo código no publicado — resolvelo a mano: $BOOT_CACHE"
    git -C "$BOOT_CACHE" -c core.hooksPath=/dev/null merge --ff-only --quiet "$remote_tip" >/dev/null 2>&1 \
      || die "fast-forward del cache falló; resolvelo a mano: $BOOT_CACHE"
  fi

  # El árbol real debe ser el del commit remoto, demostrado SIN pasar por el index:
  # skip-worktree/assume-unchanged (sparse incluido) ocultan reemplazos a git status,
  # así que los flags rechazan, y cada entrada del commit se compara contra el archivo
  # real por hash y modo. Corre DESPUÉS del merge (con hooks deshabilitados): también
  # ataja lo que un hook hubiera logrado modificar.
  bad_flags="$(git -C "$BOOT_CACHE" ls-files -v | grep -v '^H ' || true)"
  [ -z "$bad_flags" ] \
    || die "AXEL_HOME tiene paths con flags que ocultan cambios del árbol (skip-worktree/assume-unchanged); resolvelo a mano: $BOOT_CACHE"
  tree_list="$(git -C "$BOOT_CACHE" ls-tree -r "$remote_tip")" \
    || die "no pude listar el árbol del commit remoto en el cache"
  [ -n "$tree_list" ] || die "el commit remoto tiene un árbol vacío; no parece axel"
  verify_tree() {  # imprime la primera discrepancia; salida vacía = árbol idéntico.
    # Lee TODO el listado por herestring — sin pipes ni salidas tempranas: un consumidor
    # que corta antes le mete SIGPIPE a ls-tree y pipefail lo convertiría en un RC 141
    # fuera de la taxonomía. hash-object corre con -C: el object-format es el del cache,
    # no el del repo que rodee al cwd del caller (un caller SHA-256 daría falso rechazo).
    local TAB line meta mode sha path err=""
    TAB="$(printf '\t')"
    while IFS= read -r line; do
      if [ -n "$err" ]; then continue; fi
      meta="${line%%"$TAB"*}"; path="${line#*"$TAB"}"
      mode="${meta%% *}"; sha="${meta##* }"
      case "$mode" in
        120000)
          if [ ! -L "$BOOT_CACHE/$path" ] \
             || [ "$(printf '%s' "$(readlink "$BOOT_CACHE/$path")" | git -C "$BOOT_CACHE" hash-object --stdin)" != "$sha" ]; then
            err="$path (symlink distinto al commit)"
          fi ;;
        100644 | 100755)
          if [ -L "$BOOT_CACHE/$path" ] || [ ! -f "$BOOT_CACHE/$path" ] \
             || [ "$(git -C "$BOOT_CACHE" hash-object -- "$BOOT_CACHE/$path")" != "$sha" ]; then
            err="$path (contenido distinto al commit)"
          elif [ "$mode" = "100755" ] && [ ! -x "$BOOT_CACHE/$path" ]; then
            err="$path (perdió el bit de ejecución)"
          elif [ "$mode" = "100644" ] && [ -x "$BOOT_CACHE/$path" ]; then
            err="$path (bit de ejecución inesperado)"
          fi ;;
        *) err="$path (tipo $mode inesperado en axel)" ;;
      esac
    done <<< "$tree_list"
    printf '%s' "$err"
  }
  tree_err="$(verify_tree)"
  [ -z "$tree_err" ] \
    || die "el árbol del cache no coincide con el commit remoto — $tree_err; resolvelo a mano: $BOOT_CACHE"

  BOOT_DELEGATE="$BOOT_CACHE/scripts/install.sh"
  { [ ! -L "$BOOT_DELEGATE" ] && [ -f "$BOOT_DELEGATE" ] && [ -r "$BOOT_DELEGATE" ] && [ -x "$BOOT_DELEGATE" ]; } \
    || die "el remoto no parece axel: falta scripts/install.sh regular y ejecutable (un symlink no cuenta) en $BOOT_CACHE"

  echo "── axel bootstrap · remoto: $FROM_URL · cache: $BOOT_CACHE ($DEFAULT_BRANCH @ $(git -C "$BOOT_CACHE" rev-parse --short HEAD)) ──"
  # Delegación en background + wait: una señal al wrapper interrumpe el wait y el
  # trap reenvía TERM al delegado y espera su muerte antes de soltar el lock.
  set +e
  "$BOOT_DELEGATE" "$BOOT_TARGET" &
  BOOT_CHILD=$!
  wait "$BOOT_CHILD"
  boot_rc=$?
  set -e
  BOOT_CHILD=""
  case "$boot_rc" in
    0 | 1 | 2) exit "$boot_rc" ;;
    *)
      echo "aviso: el instalador delegado terminó con un código anómalo ($boot_rc) — pudo quedar interrumpido a mitad de escritura; revisá 'git -C $BOOT_TARGET status' antes de seguir" >&2
      exit 2 ;;
  esac
fi

# ── Modo local: exige correr desde un clon real de axel en disco ──────────────
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
{ [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; } \
  || die "no estoy corriendo desde un clon de axel en disco (¿piped por stdin?); usá: install.sh --from <url> <target-dir>"
AXEL_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && git rev-parse --show-toplevel)" \
  || die "no pude resolver el repo de axel desde $SCRIPT_PATH"
[ -f "$AXEL_ROOT/scripts/install.sh" ] && [ -d "$AXEL_ROOT/templates" ] \
  || die "la fuente no parece un clon de axel: $AXEL_ROOT"

# ── Qué instala ───────────────────────────────────────────────────────────────
# Payload: owned por axel, se sobreescribe en cada corrida (el re-run ES la actualización).
# Arrays paralelos fuente→destino: la política del loop viaja como .claude/axel-policy.json
# para que /adopt y las sesiones del destino puedan re-verificar settings sin acceso a axel.
PAYLOAD_SRC=(
  .claude/skills/adopt/SKILL.md
  .claude/skills/design/SKILL.md
  .claude/skills/feature/SKILL.md
  .claude/skills/plan/SKILL.md
  .claude/skills/recap/SKILL.md
  .claude/skills/status/SKILL.md
  scripts/awake.sh
  scripts/review.sh
  docs/design/review-contract.md
  templates/settings.json
)
PAYLOAD=(
  .claude/skills/adopt/SKILL.md
  .claude/skills/design/SKILL.md
  .claude/skills/feature/SKILL.md
  .claude/skills/plan/SKILL.md
  .claude/skills/recap/SKILL.md
  .claude/skills/status/SKILL.md
  scripts/awake.sh
  scripts/review.sh
  docs/design/review-contract.md
  .claude/axel-policy.json
)
# Semillas: owned por el destino, se crean solo si faltan y no se tocan jamás después.
# Fuente: templates/ de axel (settings incluido: templates/settings.json define además
# la política que la verificación exige a un settings preexistente).
SEED_SRC=(
  templates/AGENTS.md
  templates/DESIGN.md
  templates/IMPLEMENTATION.md
  templates/STATUS.md
  templates/settings.json
)
SEED_DEST=(
  AGENTS.md
  docs/DESIGN.md
  docs/IMPLEMENTATION.md
  docs/STATUS.md
  .claude/settings.json
)
CANONICAL_DOCS=( AGENTS.md docs/DESIGN.md docs/IMPLEMENTATION.md docs/STATUS.md )
MARKER_REL=".claude/axel-install"
HANDOFF_REL="docs/ADOPTION.md"
HANDOFF_SIGNATURE="<!-- generated by axel installer -->"
GITIGNORE_LINE=".claude/state/"

# ── Destino ───────────────────────────────────────────────────────────────────
[ -d "$1" ] || die "el destino no existe o no es un directorio: $1"
TARGET="$(canon_dir "$1")" || die "no pude resolver el path del destino: $1"

# ── Precondiciones de identidad (nada se escribe si fallan) ───────────────────
git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 \
  || die "el destino no es un repo git: $TARGET (el diff de git es la red de seguridad del instalador)"

TARGET_TOP="$(canon_dir "$(git -C "$TARGET" rev-parse --show-toplevel)")"
[ "$TARGET" = "$TARGET_TOP" ] \
  || die "el destino debe ser el toplevel del repo ($TARGET_TOP), no un subdirectorio: $TARGET"

# Identidad por git common dir: cubre alias, symlinks y worktrees del propio axel
target_common="$(git -C "$TARGET" rev-parse --git-common-dir)"
case "$target_common" in /*) ;; *) target_common="$TARGET/$target_common" ;; esac
axel_common="$(git -C "$AXEL_ROOT" rev-parse --git-common-dir)"
case "$axel_common" in /*) ;; *) axel_common="$AXEL_ROOT/$axel_common" ;; esac
[ "$(canon_dir "$target_common")" != "$(canon_dir "$axel_common")" ] \
  || die "self-install: el destino es el propio axel (o un worktree suyo)"

[ -z "$(git -C "$TARGET" status --porcelain)" ] \
  || die "el árbol del destino no está limpio; commiteá o stasheá antes de instalar (todo lo que hace el instalador debe quedar como diff visible)"

# ── Contexto de la corrida ────────────────────────────────────────────────────
PROJECT="$(basename "$TARGET")"
TODAY="$(date +%F)"
AXEL_SHA="$(git -C "$AXEL_ROOT" rev-parse HEAD)"
AXEL_SHA_SHORT="$(git -C "$AXEL_ROOT" rev-parse --short HEAD)"
MARKER_CONTENT="axel-install-format: 1
axel-sha: $AXEL_SHA"

WARNINGS=()
if [ -n "$(git -C "$AXEL_ROOT" status --porcelain)" ]; then
  WARNINGS+=("la fuente (axel) tiene cambios sin commitear: se instala el árbol de trabajo, no $AXEL_SHA_SHORT")
fi

# Clasificación de modo: el marker es la señal, sin heurísticas
MARKER_PATH="$TARGET/$MARKER_REL"
marker_parses() {
  [ -f "$1" ] || return 1
  [ "$(sed -n '1p' "$1")" = "axel-install-format: 1" ] || return 1
  sed -n '2p' "$1" | grep -qE '^axel-sha: [0-9a-f]{7,40}$' || return 1
}
MODE="initial"
if [ -e "$MARKER_PATH" ] || [ -L "$MARKER_PATH" ]; then
  MODE="update"   # si el marker no parsea, el preflight rechaza antes de escribir
fi

is_tracked() { git -C "$TARGET" ls-files --error-unmatch "$1" >/dev/null 2>&1; }
is_ignored() { git -C "$TARGET" check-ignore -q "$1"; }
bad_parent() {
  # imprime el primer componente PADRE inválido del path relativo: symlink (escaparía del
  # árbol) o existente-y-no-directorio (mkdir -p fallaría a mitad de escritura)
  local rel="$1" cur="$TARGET" comp
  local parts; IFS='/' read -r -a parts <<< "$rel"
  local last=$(( ${#parts[@]} - 1 )) i
  for i in "${!parts[@]}"; do
    comp="${parts[$i]}"
    cur="$cur/$comp"
    [ "$i" -eq "$last" ] && break
    if [ -L "$cur" ]; then echo "${cur#"$TARGET"/} (symlink)"; return 0; fi
    if [ -e "$cur" ] && [ ! -d "$cur" ]; then echo "${cur#"$TARGET"/} (no es un directorio)"; return 0; fi
  done
  return 1
}

# ── Inventario pre-mutación (solo corrida inicial, sobre el árbol original) ───
PREEXISTING=()      # docs canónicos que ya estaban: se respetan intactos
CANDIDATES=()       # *.md no canónicos ni owned: los mapea /adopt con el humano
if [ "$MODE" = "initial" ]; then
  OWNED=( "${PAYLOAD[@]}" "${SEED_DEST[@]}" CLAUDE.md "$HANDOFF_REL" "$MARKER_REL" )
  is_owned() {
    local rel="$1" o
    for o in "${OWNED[@]}"; do [ "$rel" = "$o" ] && return 0; done
    return 1
  }
  for rel in "${CANONICAL_DOCS[@]}"; do
    [ -e "$TARGET/$rel" ] && PREEXISTING+=("$rel")
  done
  while IFS= read -r f; do
    rel="${f#"$TARGET"/}"
    is_owned "$rel" && continue
    case " ${CANONICAL_DOCS[*]} " in *" $rel "*) continue ;; esac
    CANDIDATES+=("$rel")
  done < <( { find "$TARGET" -maxdepth 1 -name '*.md' -type f
              [ -d "$TARGET/docs" ] && find "$TARGET/docs" -name '*.md' -type f; } | sort )
fi

# ── Preflight: todo-o-nada — si algo se rechaza, no se escribió nada ──────────
ERRORS=()
CREATE_SEEDS=()     # índices de semillas a sembrar (faltantes)
CLAUDE_ACTION="none"   # none | create | conflict
GITIGNORE_ACTION="none" # none | create | append
PENDING_MECH=()     # pendientes mecánicos (van a reporte y handoff)

# La fuente completa se valida ANTES de escribir: una fuente incompleta (p. ej. axel sucio
# al que le falta un payload) no puede producir mutaciones parciales.
for src in "${PAYLOAD_SRC[@]}" "${SEED_SRC[@]}"; do
  [ -f "$AXEL_ROOT/$src" ] || ERRORS+=("fuente inconsistente: falta $src en axel (¿árbol de axel incompleto?)")
done

# La policy fuente es la verdad del loop en el destino (semilla de settings + axel-policy):
# si no parsea o no tiene la forma esperada, se rechaza antes de escribir nada (fail-closed;
# sin python3 la validez no es demostrable y también se rechaza).
check_policy_source() {
  local policy="$AXEL_ROOT/templates/settings.json"
  local py="${AXEL_INSTALL_PYTHON:-python3}"
  if ! command -v "$py" >/dev/null 2>&1; then
    echo "python3 no disponible: la validez de la policy fuente no es demostrable"
    return 0
  fi
  "$py" - "$policy" <<'PY' 2>/dev/null || echo "error al validar la policy fuente"
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"templates/settings.json no parsea como JSON: {e}")
    sys.exit(0)
def overlaps(rule, perm):
    def tool_of(s):
        head = s.split("(", 1)[0]
        return head if head and "*" not in head and "?" not in head else None
    def cmd_prefix(s):
        if s.endswith(":*)"):
            body = s[:-3]
            if "*" not in body and "?" not in body:
                return body
        return None
    if not isinstance(rule, str) or not rule:
        return True
    rt, pt = tool_of(rule), tool_of(perm)
    if rt and pt and rt != pt:
        return False
    r, p = cmd_prefix(rule), cmd_prefix(perm)
    if r is None or p is None:
        return True
    return p.startswith(r) or r.startswith(p)

ok = isinstance(d, dict) and isinstance(d.get("permissions"), dict)
p = d.get("permissions", {}) if ok else {}
if not ok:
    print("templates/settings.json: falta el objeto permissions")
elif not (isinstance(p.get("allow"), list) and p.get("allow") and all(isinstance(x, str) for x in p["allow"])):
    print("templates/settings.json: permissions.allow debe ser una lista no vacia de strings")
elif "deny" in p and not (isinstance(p["deny"], list) and all(isinstance(x, str) for x in p["deny"])):
    print("templates/settings.json: permissions.deny debe ser una lista de strings")
elif "ask" in p and not (isinstance(p["ask"], list) and all(isinstance(x, str) for x in p["ask"])):
    print("templates/settings.json: permissions.ask debe ser una lista de strings")
elif p.get("defaultMode") != "acceptEdits":
    # el valor es contractual (la bajada lo exige): un typo acá se sembraria en cada destino
    print(f"templates/settings.json: permissions.defaultMode debe ser \"acceptEdits\" (actual: {p.get('defaultMode')!r})")
else:
    conflicts = [(r, a) for r in p.get("deny", []) + p.get("ask", []) for a in p["allow"] if overlaps(r, a)]
    if conflicts:
        print(f"templates/settings.json: conflicto interno — deny/ask solapa permisos del propio allow: {conflicts}")
PY
}
if [ -f "$AXEL_ROOT/templates/settings.json" ]; then
  POLICY_ERR="$(check_policy_source)"
  [ -n "$POLICY_ERR" ] && ERRORS+=("policy fuente inválida — $POLICY_ERR")
fi

for i in "${!PAYLOAD[@]}"; do
  rel="${PAYLOAD[$i]}"
  if bad="$(bad_parent "$rel")"; then
    ERRORS+=("$rel: componente '$bad' — escribir ahí mutaría a medias o escaparía del árbol")
    continue
  fi
  dest="$TARGET/$rel"
  if [ -L "$dest" ]; then
    ERRORS+=("$rel: es un symlink; el payload debe ser un archivo regular trackeado")
  elif [ -d "$dest" ]; then
    ERRORS+=("$rel: es un directorio; tipo incompatible con el payload")
  elif [ -e "$dest" ]; then
    is_tracked "$rel" || ERRORS+=("$rel: existe pero no está trackeado (¿ignorado?); pisarlo no dejaría diff")
  else
    is_ignored "$rel" && ERRORS+=("$rel: nacería ignorado por las reglas del destino; nada del instalador puede quedar fuera del diff")
  fi
done

for i in "${!SEED_DEST[@]}"; do
  rel="${SEED_DEST[$i]}"
  dest="$TARGET/$rel"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    continue  # semilla existente: no se toca (settings preexistente se verifica aparte)
  fi
  if bad="$(bad_parent "$rel")"; then
    ERRORS+=("$rel: componente '$bad' — escribir ahí mutaría a medias o escaparía del árbol")
    continue
  fi
  is_ignored "$rel" && { ERRORS+=("$rel: nacería ignorado por las reglas del destino"); continue; }
  CREATE_SEEDS+=("$i")
done

# CLAUDE.md: symlink esperado a AGENTS.md; cualquier otra cosa preexistente es conflicto (no se toca)
claude_path="$TARGET/CLAUDE.md"
if [ -L "$claude_path" ]; then
  if [ "$(readlink "$claude_path")" = "AGENTS.md" ]; then
    CLAUDE_ACTION="none"
  else
    CLAUDE_ACTION="conflict"
  fi
elif [ -e "$claude_path" ]; then
  CLAUDE_ACTION="conflict"
else
  if is_ignored "CLAUDE.md"; then
    ERRORS+=("CLAUDE.md: nacería ignorado por las reglas del destino")
  else
    CLAUDE_ACTION="create"
  fi
fi
[ "$CLAUDE_ACTION" = "conflict" ] && PENDING_MECH+=("CLAUDE.md preexistente con contenido propio: fusionarlo en AGENTS.md y dejar CLAUDE.md como symlink (lo guía /adopt)")

# .gitignore: append idempotente de la línea; mutarlo exige que produzca diff
gitignore_path="$TARGET/.gitignore"
if [ -L "$gitignore_path" ]; then
  ERRORS+=(".gitignore: es un symlink; no se muta a través de symlinks")
elif [ -f "$gitignore_path" ]; then
  if ! grep -qxF "$GITIGNORE_LINE" "$gitignore_path"; then
    if is_tracked ".gitignore"; then
      GITIGNORE_ACTION="append"
    else
      ERRORS+=(".gitignore: existe pero no está trackeado (¿ignorado vía info/exclude?); mutarlo no dejaría diff")
    fi
  fi
elif [ -e "$gitignore_path" ]; then
  ERRORS+=(".gitignore: no es un archivo regular")
else
  if is_ignored ".gitignore"; then
    ERRORS+=(".gitignore: nacería ignorado; no puedo asegurar la entrada $GITIGNORE_LINE dentro del diff")
  else
    GITIGNORE_ACTION="create"
  fi
fi

# Estado del instalador: propiedad demostrable y siempre dentro del diff
if [ -e "$MARKER_PATH" ] || [ -L "$MARKER_PATH" ]; then
  if [ -L "$MARKER_PATH" ] || ! marker_parses "$MARKER_PATH"; then
    ERRORS+=("$MARKER_REL: existe pero no parsea como marker de axel; no lo piso — movelo o borralo a mano")
  elif ! is_tracked "$MARKER_REL"; then
    ERRORS+=("$MARKER_REL: el marker controla la clasificación y debe estar trackeado (untracked/ignorado quedaría fuera del diff)")
  fi
else
  is_ignored "$MARKER_REL" && ERRORS+=("$MARKER_REL: nacería ignorado por las reglas del destino")
fi
handoff_path="$TARGET/$HANDOFF_REL"
if [ -e "$handoff_path" ] || [ -L "$handoff_path" ]; then
  if [ -L "$handoff_path" ] || [ ! -f "$handoff_path" ] || [ "$(sed -n '1p' "$handoff_path")" != "$HANDOFF_SIGNATURE" ]; then
    ERRORS+=("$HANDOFF_REL: existe pero no lo generó este instalador (sin firma); no piso un documento cuya propiedad no puedo probar — movelo o renombralo")
  elif ! is_tracked "$HANDOFF_REL"; then
    ERRORS+=("$HANDOFF_REL: el handoff es estado persistente y debe estar trackeado")
  fi
else
  if bad="$(bad_parent "$HANDOFF_REL")"; then
    ERRORS+=("$HANDOFF_REL: componente '$bad'")
  elif is_ignored "$HANDOFF_REL"; then
    ERRORS+=("$HANDOFF_REL: nacería ignorado por las reglas del destino")
  fi
fi

if [ "${#ERRORS[@]}" -gt 0 ]; then
  echo "── preflight: ${#ERRORS[@]} problema(s); no se escribió nada ──" >&2
  for e in "${ERRORS[@]}"; do echo "rechazo: $e" >&2; done
  exit 2
fi

# ── Verificación de settings (estructural, fail-closed) ───────────────────────
# Compara la política efectiva del settings preexistente contra templates/settings.json
# (la misma que se instala como .claude/axel-policy.json): cada permiso requerido en allow,
# ningún deny que pueda solaparlo (deny gana; solapamiento por prefijo, conservador), y
# defaultMode correcto. JSON inválido, shapes inesperados, python3 ausente o cualquier
# caso no demostrable ⇒ faltante (fail-closed).
check_settings() {
  local existing="$1" required="$AXEL_ROOT/templates/settings.json"
  local py="${AXEL_INSTALL_PYTHON:-python3}"
  if ! command -v "$py" >/dev/null 2>&1; then
    echo "settings inverificable (python3 no disponible): tratá la política del loop como faltante — compará a mano con .claude/axel-policy.json"
    return 0
  fi
  "$py" - "$required" "$existing" <<'PY' 2>/dev/null || echo "settings inverificable (error al analizar): tratá la política del loop como faltante"
import json, sys

def overlaps(rule, perm):
    # Conservador: solo se declara disjunto cuando se puede DEMOSTRAR. Claude Code evalua
    # deny -> ask -> allow, admite "*" en cualquier posicion y tiene selectores por
    # parametro del mismo tool (p. ej. "Bash(run_in_background:true)"), asi que:
    #   - tools literales distintos => disjuncion demostrable (las reglas son por tool)
    #   - mismo tool: solo si AMBOS lados son patrones de prefijo de comando explicitos
    #     ("...:*)") sin wildcards internos y ningun prefijo contiene al otro
    #   - todo lo demas (selector por parametro, comando exacto, wildcard medio,
    #     shape raro) => interseccion no demostrable => bloquea
    def tool_of(s):
        head = s.split("(", 1)[0]
        return head if head and "*" not in head and "?" not in head else None
    def cmd_prefix(s):
        # patron de prefijo de comando explicito: "Tool(algo:*)" -> "Tool(algo"; si no, None
        if s.endswith(":*)"):
            body = s[:-3]
            if "*" not in body and "?" not in body:
                return body
        return None
    if not isinstance(rule, str) or not rule:
        return True  # entrada rara: no demostrable => bloquea
    rt, pt = tool_of(rule), tool_of(perm)
    if rt and pt and rt != pt:
        return False  # tools literales distintos: disjuncion demostrable
    r, p = cmd_prefix(rule), cmd_prefix(perm)
    if r is None or p is None:
        return True  # no demostrable (selector por parametro, comando exacto, wildcard...)
    return p.startswith(r) or r.startswith(p)

try:
    req = json.load(open(sys.argv[1]))
except Exception:
    print("settings inverificable (templates/settings.json de axel no parsea)")
    sys.exit(0)
try:
    ex = json.load(open(sys.argv[2]))
except Exception:
    print("settings.json invalido: no parsea como JSON; la politica del loop no es demostrable")
    sys.exit(0)
rp = req.get("permissions", {}) if isinstance(req, dict) else {}
if not isinstance(ex, dict) or ("permissions" in ex and not isinstance(ex["permissions"], dict)):
    print("settings inverificable: permissions no tiene la forma esperada (fail-closed)")
    sys.exit(0)
ep = ex.get("permissions", {})
allow = ep.get("allow", [])
deny = ep.get("deny", [])
ask = ep.get("ask", [])
if not isinstance(allow, list):
    print("settings inverificable: permissions.allow no es una lista (fail-closed)")
    sys.exit(0)
if not isinstance(deny, list):
    print("settings inverificable: permissions.deny no es una lista (fail-closed)")
    sys.exit(0)
if not isinstance(ask, list):
    print("settings inverificable: permissions.ask no es una lista (fail-closed)")
    sys.exit(0)
for perm in rp.get("allow", []):
    if perm not in allow:
        print(f"permiso faltante en permissions.allow: {perm}")
        continue
    blockers = [d for d in deny if overlaps(d, perm)]
    if blockers:
        print(f"permiso en allow pero un deny puede cubrirlo (deny gana): {perm} vs {blockers}")
    askers = [a for a in ask if overlaps(a, perm)]
    if askers:
        print(f"permiso en allow pero un ask puede frenarlo (pide confirmacion): {perm} vs {askers}")
want_mode = rp.get("defaultMode", "acceptEdits")
mode = ep.get("defaultMode")
if mode != want_mode:
    print(f"permissions.defaultMode debe ser \"{want_mode}\" (actual: {mode!r}); sin eso el loop se frena en cada edicion")
PY
}

SETTINGS_ISSUES=""
settings_path="$TARGET/.claude/settings.json"
if [ -L "$settings_path" ] || { [ -e "$settings_path" ] && [ ! -f "$settings_path" ]; }; then
  PENDING_MECH+=("settings: .claude/settings.json existe pero no es un archivo regular; la política del loop no es demostrable (fail-closed)")
elif [ -f "$settings_path" ]; then
  SETTINGS_ISSUES="$(check_settings "$settings_path")"
  if [ -n "$SETTINGS_ISSUES" ]; then
    while IFS= read -r line; do PENDING_MECH+=("settings: $line"); done <<< "$SETTINGS_ISSUES"
  fi
fi

# ── Escritura ─────────────────────────────────────────────────────────────────
INSTALLED=(); UPDATED=(); UNCHANGED=(); SKIPPED=()

for i in "${!PAYLOAD[@]}"; do
  src="$AXEL_ROOT/${PAYLOAD_SRC[$i]}"; rel="${PAYLOAD[$i]}"; dest="$TARGET/$rel"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    UNCHANGED+=("$rel")
  else
    if [ -e "$dest" ]; then UPDATED+=("$rel"); else INSTALLED+=("$rel"); fi
    cp "$src" "$dest"
  fi
  case "$rel" in scripts/*.sh) chmod +x "$dest" ;; esac
done

# Plantillas: {{PROJECT}}, {{DATE}} y {{STATE_LINES}} (solo STATUS). El bloque multilínea
# entra por archivo (sed r+d): BSD awk no acepta -v con newlines y así no hay escapes que cuidar.
RENDER_TMP="$(mktemp -d "${TMPDIR:-/tmp}/axel-install.XXXXXX")"
trap 'rm -rf "$RENDER_TMP"' EXIT
if [ "$MODE" = "initial" ] && { [ "${#PREEXISTING[@]}" -gt 0 ] || [ "${#CANDIDATES[@]}" -gt 0 ] || [ "${#PENDING_MECH[@]}" -gt 0 ]; }; then
  STATE_LINES="- **Fase**: adopción — este proyecto tiene contenido previo a axel; correr \`/adopt\` para mapearlo y derivar el estado real
- **Pendientes**: ver [ADOPTION.md](ADOPTION.md) — hallazgos e instrucciones del instalador
- **Esperando**: sesión de \`/adopt\` con el humano"
else
  STATE_LINES="- **Fase**: instalación completada — arrancar con \`/design\` (ping-pong de ideas con el humano)
- **Feature en curso**: ninguno
- **Esperando**: primera sesión de diseño"
fi
printf '%s\n' "$STATE_LINES" > "$RENDER_TMP/state-lines"
PROJECT_SED="$(printf '%s' "$PROJECT" | sed -e 's/[&\\/]/\\&/g')"
render_seed() {
  sed -e "/{{STATE_LINES}}/r $RENDER_TMP/state-lines" -e "/{{STATE_LINES}}/d" "$1" \
    | sed -e "s/{{PROJECT}}/$PROJECT_SED/g" -e "s/{{DATE}}/$TODAY/g" > "$2"
}
for i in ${CREATE_SEEDS[@]+"${CREATE_SEEDS[@]}"}; do   # guard: bash 3.2 + set -u con array vacío
  src="$AXEL_ROOT/${SEED_SRC[$i]}"; rel="${SEED_DEST[$i]}"; dest="$TARGET/$rel"
  mkdir -p "$(dirname "$dest")"
  render_seed "$src" "$dest"
  INSTALLED+=("$rel (semilla)")
done
for i in "${!SEED_DEST[@]}"; do
  case " ${CREATE_SEEDS[*]+"${CREATE_SEEDS[*]}"} " in
    *" $i "*) ;;
    *) SKIPPED+=("${SEED_DEST[$i]} (preexistente, intacto)") ;;
  esac
done

if [ "$CLAUDE_ACTION" = "create" ]; then
  ln -s AGENTS.md "$claude_path"
  INSTALLED+=("CLAUDE.md → AGENTS.md (symlink)")
fi
case "$GITIGNORE_ACTION" in
  create) printf '%s\n' "$GITIGNORE_LINE" > "$gitignore_path"; INSTALLED+=(".gitignore (entrada $GITIGNORE_LINE)") ;;
  append)
    # un .gitignore sin newline final concatenaría la entrada a la última regla
    [ -s "$gitignore_path" ] && [ "$(tail -c1 "$gitignore_path")" != "" ] && printf '\n' >> "$gitignore_path"
    printf '%s\n' "$GITIGNORE_LINE" >> "$gitignore_path"
    UPDATED+=(".gitignore (entrada $GITIGNORE_LINE)") ;;
esac

# Marker: serialización estable, se reescribe solo si el contenido cambia
if [ ! -f "$MARKER_PATH" ] || [ "$(cat "$MARKER_PATH")" != "$MARKER_CONTENT" ]; then
  mkdir -p "$(dirname "$MARKER_PATH")"
  printf '%s\n' "$MARKER_CONTENT" > "$MARKER_PATH"
  if [ "$MODE" = "initial" ]; then INSTALLED+=("$MARKER_REL"); else UPDATED+=("$MARKER_REL (axel $AXEL_SHA_SHORT)"); fi
else
  UNCHANGED+=("$MARKER_REL")
fi

# Handoff: en inicial se (re)genera si hay pendientes; en update se conserva el existente
# (su dueño de cierre es /adopt) y solo se crea si hay pendientes mecánicos y no había handoff.
HANDOFF_WRITTEN=""
write_handoff() {
  {
    printf '%s\n' "$HANDOFF_SIGNATURE"
    echo "# Adopción pendiente — $PROJECT"
    echo
    echo "> Handoff del instalador de axel (corrida del $TODAY, axel \`$AXEL_SHA_SHORT\`). Lo consume y borra \`/adopt\`;"
    echo "> se regenera si el instalador vuelve a correr con pendientes. No editar a mano: las decisiones van al repo."
    echo
    if [ "${#PREEXISTING[@]}" -gt 0 ]; then
      echo "## Docs canónicos preexistentes (respetados intactos)"
      echo
      for p in "${PREEXISTING[@]}"; do echo "- \`$p\` — evaluar en \`/adopt\` si refleja la convención o necesita completarse"; done
      echo
    fi
    if [ "${#CANDIDATES[@]}" -gt 0 ]; then
      echo "## Candidatos a mapear (decidir con el humano; el instalador no adivina equivalencias)"
      echo
      for c in "${CANDIDATES[@]}"; do echo "- \`$c\`"; done
      echo
    fi
    if [ "${#PENDING_MECH[@]}" -gt 0 ]; then
      echo "## Pendientes mecánicos"
      echo
      for m in "${PENDING_MECH[@]}"; do echo "- $m"; done
      echo
    fi
    echo "## Cómo cerrar"
    echo
    echo "Corré \`/adopt\` en Claude Code: mapea los candidatos, completa \`AGENTS.md\`, resuelve los"
    echo "pendientes mecánicos, deriva el \`docs/STATUS.md\` real, borra este archivo y commitea."
  } > "$handoff_path"
  HANDOFF_WRITTEN=1
}
HAS_PENDING=""
if [ "$MODE" = "initial" ]; then
  if [ "${#PREEXISTING[@]}" -gt 0 ] || [ "${#CANDIDATES[@]}" -gt 0 ] || [ "${#PENDING_MECH[@]}" -gt 0 ]; then
    mkdir -p "$(dirname "$handoff_path")"
    write_handoff
    HAS_PENDING=1
  fi
else
  if [ -f "$handoff_path" ]; then
    SKIPPED+=("$HANDOFF_REL (adopción abierta: la cierra /adopt)")
    HAS_PENDING=1
  elif [ "${#PENDING_MECH[@]}" -gt 0 ]; then
    mkdir -p "$(dirname "$handoff_path")"
    PREEXISTING=(); CANDIDATES=()   # en update no hay inventario: el handoff lleva solo lo mecánico
    write_handoff
    HAS_PENDING=1
  fi
fi

# ── Reporte ───────────────────────────────────────────────────────────────────
echo "── axel installer · modo: $MODE · destino: $TARGET · axel $AXEL_SHA_SHORT ──"
report_list() {
  local title="$1"; shift
  [ $# -gt 0 ] || return 0
  echo "$title:"
  local x; for x in "$@"; do echo "  - $x"; done
}
report_list "instalado"    ${INSTALLED[@]+"${INSTALLED[@]}"}
report_list "actualizado"  ${UPDATED[@]+"${UPDATED[@]}"}
report_list "sin cambios"  ${UNCHANGED[@]+"${UNCHANGED[@]}"}
report_list "intacto"      ${SKIPPED[@]+"${SKIPPED[@]}"}
report_list "preexistente (adopción)" ${PREEXISTING[@]+"${PREEXISTING[@]}"}
report_list "candidatos a mapear"     ${CANDIDATES[@]+"${CANDIDATES[@]}"}
report_list "pendientes"   ${PENDING_MECH[@]+"${PENDING_MECH[@]}"}
report_list "avisos"       ${WARNINGS[@]+"${WARNINGS[@]}"}
[ -n "$HANDOFF_WRITTEN" ] && echo "handoff escrito: $HANDOFF_REL"
echo
echo "próximos pasos: revisá el diff (git -C $TARGET status), commitealo con tu proceso,"
if [ -n "$HAS_PENDING" ]; then
  echo "y abrí Claude Code en el destino: la adopción se cierra con /adopt (ver $HANDOFF_REL)."
  exit 1
else
  echo "y abrí Claude Code en el destino: /status para ubicarte, /design para arrancar."
  exit 0
fi
