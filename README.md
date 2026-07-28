# axel

Maquinaria de desarrollo con loop generador/reviewer: **Claude Code genera, Codex revisa**, iterando hasta acuerdo, con los docs como memoria persistente y checkpoints de OK humano.

- Contexto para agentes y reglas del proceso: [AGENTS.md](AGENTS.md)
- Dónde estamos parados: [docs/STATUS.md](docs/STATUS.md)
- Diseño: [docs/DESIGN.md](docs/DESIGN.md) · Plan: [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md)

## Uso

Abrí Claude Code en el repo:

- `/status` — ubicarte en 10 líneas.
- `/feature` — continuar el loop con el feature en curso o el siguiente.
- `/design`, `/plan` — fases de diseño y planificación.
- `/recap` — resumen de lo hecho desde el último OK.

El loop corre solo (commitea, pide review a Codex, itera) y se frena en cada RECAP a esperar tu OK. Podés responder desde una sesión remota. La máquina se mantiene despierta sola mientras el loop trabaja (`scripts/awake.sh` + `caffeinate` alrededor de Codex); con la tapa cerrada hace falta corriente y display externo.

## Llevar axel a otro proyecto

Sin clon previo de axel, parado adentro del repo destino:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash
```

Sin argumentos, el instalador **asume dos cosas y las anuncia antes de tocar nada**: la fuente es el repo canónico de axel y el destino es el toplevel del repo git donde estás parado. Verificá dónde estás antes de correrlo (`git rev-parse --show-toplevel`): ese repo, con el árbol limpio, es el que se va a modificar. Fuera de un repo git, la corrida se rechaza sin escribir nada. Cuando el destino es otro, o la fuente es un fork, las formas explícitas siguen valiendo igual que antes:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash -s -- --from https://github.com/alexweil/axel <repo-destino>
```

**Cómo saber que corrió**: toda corrida termina con una línea `── axel · fin: rc=N · …`. Si no la ves, lo único que podés concluir es que **no hay finalización confirmada**: lo más común es que `curl` haya fallado y `bash` recibido entrada vacía, que retorna 0 sin ejecutar nada (el pipe no propaga el fallo de `curl`), pero también puede ser una corrida interrumpida **después** de empezar a escribir — así que revisá `git status` del destino antes de reintentar. Para uso scripteado, esta variante sí propaga el fallo del transporte:

```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash'
```

**Si te equivocaste de repo**: el instalador exige árbol limpio y no commitea, así que todo lo que escribió es exactamente el diff. `git status --short` lo muestra, `git restore .` revierte lo modificado y `git clean -fd` borra lo nuevo (seguro justamente porque el árbol estaba limpio antes). Como red adicional, si el destino asumido resulta ser un clon de la propia fuente —correr el one-liner parado adentro de axel— la corrida se rechaza y te pide el destino explícito.

El script piped solo parsea argumentos, clona (o actualiza por fast-forward) un **cache de axel** en `~/.axel` (override: env `AXEL_HOME`) y delega la instalación en el `install.sh` de ese clon — lo que instala es siempre código versionado del cache, verificado contra el commit remoto. El cache se maneja fail-closed: sucio, con commits locales, divergido, en otro branch u otro origin ⇒ rechazo con instrucciones, jamás se pisa nada. Con un clon local de axel, el modo clásico hace lo mismo sin red — y ahí el destino **sigue siendo obligatorio**, porque la fuente es el clon que tenés a la vista y asumirlo no aportaría nada:

```bash
scripts/install.sh /path/al/repo-destino
```

**Forks**: un script bajado de un fork y ejecutado por stdin no puede saber que salió de un fork (no hay `$0` ni procedencia), así que sin `--from` instala el axel canónico. Para instalar desde un fork usá la forma explícita `bash -s -- --from <url-del-fork> <destino>` (o exportá `AXEL_DEFAULT_REMOTE`). El anuncio del arranque siempre dice qué fuente terminó usando.

Instala la maquinaria (skills, scripts del loop, contrato, política de permisos) y siembra lo que falte (AGENTS.md + symlink CLAUDE.md, docs, settings). Tres modos, sin flags: instalación desde cero; **adopción** si el repo ya tiene docs propios — los docs y semillas preexistentes quedan intactos, los hallazgos van a `docs/ADOPTION.md` y el cierre se hace con `/adopt` en el destino —; y **actualización** al re-correrlo, con axel como fuente de verdad: los archivos de **maquinaria** (skills, scripts, contrato, política) se sobreescriben aunque los hayas tocado, los docs y settings del proyecto no se tocan nunca, y a `.gitignore` solo se le agrega la entrada `.claude/state/` si falta. Exige repo git con árbol limpio y python3; no commitea: el diff queda para tu proceso. Exit 0 = sin pendientes, 1 = pendientes en `docs/ADOPTION.md`, 2 = rechazo sin tocar el destino — salvo los casos, señalados con aviso explícito, de un instalador interrumpido o que no llegó a completarse a mitad de escritura (revisar `git status`). Tests: `tests/install.sh`.

### Para agentes (Claude Code)

Si te pidieron "instalá axel siguiendo esta URL", este es tu procedimiento completo:

1. **Precondiciones**: el destino es un repo git con **árbol limpio** (commiteá o stasheá antes); `git`, `curl` y `python3` disponibles. El destino es el **toplevel** del repo: `git rev-parse --show-toplevel`.
2. **Corré el one-liner** de arriba. Si tenés certeza de estar parado en el repo destino, la forma corta sin argumentos alcanza (asume ese toplevel y lo anuncia); **si no estás seguro, pasá el destino explícito** con `bash -s -- --from https://github.com/alexweil/axel <toplevel>` — el destino asumido es la única parte del comando que depende de dónde estés parado. No necesitás clonar axel: el comando baja y cachea todo en `~/.axel`.
3. **Chequeá primero la línea final**: la salida de una corrida real termina en `── axel · fin: rc=N · …`. Si esa línea no está, no hay **finalización confirmada** y el exit code no dice nada sobre la instalación: lo más común es que fallara la descarga y `bash` recibiera entrada vacía (retorna 0 sin ejecutar nada), pero una corrida interrumpida después de escribir deja diff parcial — **revisá `git status` del destino antes de reintentar**, y usá `bash -o pipefail -c '…'` si querés que el fallo del transporte se propague.
4. **Reaccioná según el exit code**:
   - `0` — instalado sin pendientes: revisá el diff (`git status`), commitealo con el proceso del proyecto y corré `/status` para ubicarte (`/design` si el proyecto arranca de cero).
   - `1` — instalado con pendientes: revisá y commiteá el diff igual, y cerrá la adopción con `/adopt` (los hallazgos están en `docs/ADOPTION.md`).
   - `2` — leé el reporte: si es un **rechazo** (precondiciones, preflight, cache, destino asumido fuera de un repo git o que resulta ser la propia fuente), no se escribió nada en el destino (el cache `~/.axel` sí pudo crearse o actualizarse) — resolvé la causa y reintentá; si el aviso dice que el instalador fue **interrumpido** o que **no llegó a completarse**, revisá `git status` del destino antes de seguir: puede haber diff parcial.
5. **Desde adentro de una sesión de Claude Code**: las skills instaladas (`/status`, `/design`, `/adopt`, …) se cargan en caliente y podés usarlas ya; los permisos del `.claude/settings.json` sembrado rigen plenos recién en la **sesión siguiente** — hasta entonces puede haber prompts de confirmación. El instalador nunca commitea: el commit es tuyo, con el proceso del destino.

Para auditar antes de ejecutar: el camino en dos pasos hace exactamente lo mismo, con el instalador a la vista. Cloná axel **fuera del destino** (adentro ensuciaría el árbol que el instalador exige limpio) y pasale el toplevel:

```bash
AXEL_SRC="$(mktemp -d)/axel" && git clone https://github.com/alexweil/axel "$AXEL_SRC" && "$AXEL_SRC/scripts/install.sh" "$(git rev-parse --show-toplevel)"
```
