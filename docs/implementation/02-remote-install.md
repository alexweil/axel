# 02 — Instalación remota: one-liner desde GitHub

## Alcance

Instalar axel en un destino **sin clon local previo**: un solo comando que baja axel desde GitHub y corre la instalación local ya aprobada en el feature 01. Concretamente:

- `scripts/install.sh` gana un **modo remoto** `--from <url>`: asegura un clon local de axel (`AXEL_HOME`, default `~/.axel`) y **delega** la instalación en el instalador de ese clon. El contrato del modo local no cambia en nada (mismo uso, mismos exits, misma seguridad).
- El **one-liner canónico** documentado en el README:

  ```bash
  curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash -s -- --from https://github.com/alexweil/axel /path/al/destino
  ```

- **Sección del README para agentes** — pensada para que "instalá axel siguiendo https://github.com/alexweil/axel" alcance como instrucción a una sesión de Claude Code: precondiciones, el comando exacto, qué significa cada exit y el próximo paso; incluye el camino **desde adentro de una sesión** en el repo destino (árbol limpio primero; las skills se cargan en caliente; el settings rige pleno recién en la sesión siguiente).
- `templates/AGENTS.md`: la nota de "maquinaria instalada desde axel" pasa a mencionar el one-liner como camino de actualización (los destinos no suelen tener clon de axel).
- **Tests del modo remoto** en `tests/install.sh`, con el mismo arnés del 01: el "remoto" es un fixture git local (`file://`), `AXEL_HOME` se overridea por env para no tocar el home real.

Fuera de alcance (v1): selección de ref/tag por flag (el pinning existe igual: lo decide la rama checkouteada del clon — ver enfoque); verificación criptográfica del bootstrap (checksums/firmas: se confía en HTTPS + GitHub, mitigado por la delegación); Windows; shellcheck (queda en el feature 03, como lo lista IMPLEMENTATION).

## Enfoque técnico

### Bootstrap mínimo, autoridad en el clon

El bloque `--from` va **al tope de `install.sh`, antes de resolver `AXEL_ROOT`**, y es lo único que ejecuta la copia bajada por curl: parsear argumentos, asegurar el clon local y re-ejecutar `exec "$AXEL_HOME/scripts/install.sh" <destino>` — sin `--from`, o sea en modo local, sin recursión posible.

Por qué así:

- Bajo `curl | bash -s`, `$0` es `bash` y `BASH_SOURCE` no apunta a ningún archivo del repo: la resolución actual de `AXEL_ROOT` (`dirname "$0"` + `rev-parse`) tomaría como fuente **el repo que contenga el cwd**. El bloque remoto corre antes y nunca la computa.
- **Toda mutación del destino la hace siempre código trackeado a un SHA conocido** (el del clon, que el marker ya registra): el preflight, el fail-closed y los tres modos del 01 se reusan enteros, sin duplicar una línea de esa lógica en el bootstrap.
- La copia curl'd puede ser vieja respecto del clon (cache de raw, rama distinta): no importa — la autoridad es el instalador del clon actualizado; el drift solo afecta la superficie mínima del parseo de `--from`.

### Ciclo de vida del clon local (`AXEL_HOME`)

- Default `~/.axel`, override por env `AXEL_HOME` (lo usan también los tests).
- **No existe** → `git clone <url> "$AXEL_HOME"` (un clone fallido lo limpia git solo; no queda estado a medias).
- **Existe** → para actualizarse con `git pull --ff-only` debe cumplir: repo git cuyo toplevel es exactamente `AXEL_HOME`, árbol limpio, HEAD en una rama con upstream, y `origin` apuntando a la URL pedida — comparación **normalizada** (`.git` y `/` finales no cuentan).
- Cualquier otro estado → **exit 2 sin tocar nada** (ni el destino ni `AXEL_HOME`): sucio, divergido (ff imposible), detached HEAD, otro `origin`, no-repo, toplevel distinto. Nunca `reset --hard` ni `clean` sobre `AXEL_HOME`: es un clon del usuario — fail-closed **no destructivo**, a diferencia del worktree de review (que sí es descartable por contrato). El mensaje de rechazo trae siempre la salida de escape: resolver a mano o `rm -rf "$AXEL_HOME"` y re-correr; sin red, correr el instalador local del clon (`"$AXEL_HOME"/scripts/install.sh <destino>`).
- **La rama del clon es el pinning del usuario**: por default queda `main` (lo que clona git); un checkout deliberado de otra rama con upstream instala eso, y el reporte + marker registran el SHA. Detached HEAD se rechaza: no hay upstream que actualizar.

### Contrato de salida

- **Bootstrap**: exit 2 en todo rechazo propio — URL `http://` (transporte inseguro; el resto de las URLs las resuelve git: https, ssh, `file://`/path, que además habilita los fixtures), argumentos inválidos, estados de `AXEL_HOME` no resolubles, fallas de red en clone/pull. El bootstrap no mira el destino: no puede mutarlo.
- **Delegación por `exec`**: el exit del instalador local (0 = limpio, 1 = pendientes, 2 = rechazo) se propaga tal cual. El reporte del destino es el del instalador local; el bootstrap solo antepone qué clonó/actualizó y a qué SHA quedó.

### README para agentes

Sección nueva "Instalación remota (one-liner)" con una parte explícitamente dirigida a un agente que sigue el README:

1. Precondiciones verificables: destino = toplevel de un repo git con árbol limpio (en sesión: commitear/stashear lo pendiente primero), `git` y `python3` disponibles.
2. El one-liner exacto (arriba) y su variante con clon ya presente (re-correr el mismo comando actualiza; `AXEL_HOME` para ubicarlo).
3. Qué hacer según el exit: 0 → revisar diff y commitear, `/status`; 1 → además cerrar la adopción con `/adopt`; 2 → leer el rechazo, nada se escribió.
4. Camino en-sesión: las skills quedan disponibles en caliente en la misma sesión; `.claude/settings.json` rige pleno en la **sesión siguiente** — el agente debe avisarlo al humano en su reporte.

### Verificación

Bloque nuevo en `tests/install.sh` (mismo arnés: `assert_*`, `fs_digest`, `mk_target`), con el "remoto" = repo fixture local (el propio `AXEL_SRC` de la suite ya es un repo standalone) vía `file://`, y `AXEL_HOME` bajo el tmp de la suite. Matriz:

- **Camino feliz**: sin `AXEL_HOME` → clona e instala (exit 0, payload + marker en el destino, marker con el SHA HEAD del remoto). Re-run inmediato → exit 0 e idempotencia heredada del 01 (destino sin diff). **Remoto avanzado** (commit nuevo en el fixture) → re-run: `AXEL_HOME` ff-actualizado, payload nuevo en el destino, marker con el SHA nuevo — la única fuente posible de ese SHA es el clon actualizado: prueba la delegación real.
- **Propagación**: destino con doc canónico preexistente vía remoto → exit 1 y handoff escrito (el 1 del instalador local atraviesa el bootstrap).
- **Rechazos** (exit 2 + `fs_digest` sin cambios sobre destino **y** `AXEL_HOME`): clon sucio; divergido (commit local → ff imposible); detached HEAD; `origin` distinto (y el caso espejo: URL equivalente con `.git` final **pasa**); `AXEL_HOME` existente no-repo; `AXEL_HOME` subdirectorio de otro repo; URL `http://`; `--from` sin URL; sin destino.
- **Simulación curl|bash byte-idéntica**: `bash -s -- --from <file-url> <destino>` con el script por stdin y **cwd adentro de un repo git ajeno** → instala igual y ese repo no se usa como fuente (cubre `$0`/`BASH_SOURCE` sin archivo).
- **Smoke de red real** (evidencia manual en el Review log, no en la suite): clon `https://github.com/alexweil/axel` real. El one-liner **completo** contra GitHub solo es verificable cuando `--from` esté en `origin/main` (la copia curl baja de ahí): pre-merge la evidencia es la simulación byte-idéntica + el clon https; la corrida E2E real queda documentada al cerrar o como primer acto post-merge.

## Criterios de cierre

1. `install.sh --from <url> <destino>` instala de punta a punta desde un remoto git sin clon previo, delegando toda mutación del destino en el instalador del clon; el contrato local del 01 queda intacto — la matriz previa de `tests/install.sh` pasa sin cambios.
2. Ciclo de vida del clon demostrado: creación, update `--ff-only`, pinning por rama del usuario, y remoto avanzado reflejado en payload y marker del destino (delegación real, no copia del bootstrap).
3. Bootstrap fail-closed: exit 2 con **cero mutaciones** (destino y `AXEL_HOME`, verificado por `fs_digest`) en toda la matriz de rechazos: sucio, divergido, detached, origin distinto, no-repo, no-toplevel, `http://`, argumentos inválidos.
4. Propagación fiel de 0/1/2 a través del bootstrap; la simulación curl|bash byte-idéntica (script por stdin, cwd en repo ajeno) instala sin usar el repo del cwd como fuente.
5. README con el one-liner y la sección para agentes (incluido el camino en-sesión y la nota de settings-en-sesión-siguiente); `templates/AGENTS.md` al día; `tests/install.sh` en verde con los casos remotos; `bash -n` limpio; smoke de red real evidenciado en el Review log (y la corrida E2E del one-liner documentada al cerrar si `origin/main` ya la puede servir).

## Decisiones

- 2026-07-27 (bajada): **bootstrap mínimo + delegación por `exec`** al instalador del clon — la autoridad es siempre código trackeado a SHA conocido y la seguridad del 01 se reusa sin duplicarse; `AXEL_HOME` (`~/.axel`, override env) como clon-caché compartido; fail-closed **no destructivo** sobre `AXEL_HOME` (nunca `reset --hard`; sucio/divergido/detached/origin-distinto ⇒ exit 2 con salida de escape en el mensaje); rechazo explícito de `http://`; la rama checkouteada del clon como mecanismo de pinning (sin flag de ref en v1); `file://` habilita los fixtures de la suite.

## Riesgos

- **curl|bash confía en HTTPS + GitHub**: quien controle el transporte o el repo controla el bootstrap. Mitigación: bootstrap mínimo que no toca el destino y delega en código clonado auditable a SHA registrado en el marker; firmas/checksums fuera de alcance v1.
- **Drift bootstrap viejo ↔ clon nuevo**: la copia curl'd puede quedar cacheada o venir de otra rama. La delegación lo neutraliza para todo salvo el parseo de `--from`: cambios futuros a ese contrato deben mantener compatibilidad de parseo (superficie chica y estable a propósito).
- **`AXEL_HOME` compartido entre proyectos**: actualizarlo para el proyecto A adelanta el clon que verá B — deseado (axel es fuente de verdad única), pero puede sorprender; el reporte lo hace visible con el SHA en cada corrida.
- **Sin red en el update**: `clone`/`pull` fallan ⇒ exit 2; la salida de escape (instalador local del clon existente) va en el propio mensaje de error.
- **Evidencia E2E real limitada pre-merge**: el one-liner literal recién funciona cuando `--from` llegue a `origin/main`. Mitigación: simulación byte-idéntica en la suite + smoke de red real, y la corrida E2E documentada al cerrar o inmediatamente post-merge.

## Review log

- **Ronda 1: no ejecutable en este entorno** (2026-07-27). La bajada se commiteó (`c793298`) y se corrió `scripts/review.sh new` con el pedido (bookkeeping del cierre del 01 + bajada contra DESIGN/IMPLEMENTATION), pero esta sesión corre en un contenedor remoto de Claude Code web **sin el CLI `codex` ni credenciales OpenAI** (verificado: PATH, `~/.codex`, env). Evidencia: exit 2 de `review.sh`, `codex terminó con exit 127`, `last-review-events.jsonl` = `codex: command not found`. No es fallo transitorio ⇒ sin reintento; RECAP temprano para que el humano decida dónde corre el loop. Nota adicional: `.claude/state/` no viaja (no versionado por diseño), así que en este entorno la ronda 1 tampoco tendría la base `fb23165` — cubriría todo el repo.
