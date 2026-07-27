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

```bash
scripts/install.sh /path/al/repo-destino
```

Instala la maquinaria (skills, scripts del loop, contrato, política de permisos) y siembra lo que falte (AGENTS.md + symlink CLAUDE.md, docs, settings). Tres modos, sin flags: instalación desde cero, **adopción** si el repo ya tiene docs propios (no pisa nada; deja `docs/ADOPTION.md` y el cierre se hace con `/adopt` en el destino), y **actualización** al re-correrlo (axel es la fuente de verdad; los archivos de maquinaria se pisan, lo del proyecto jamás). Exige repo git con árbol limpio y python3; no commitea: el diff queda para tu proceso. Exit 0 = sin pendientes, 1 = pendientes en `docs/ADOPTION.md`, 2 = rechazo sin tocar nada. Tests: `tests/install.sh`.
