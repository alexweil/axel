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

El loop corre solo (commitea, pide review a Codex, itera) y se frena en cada RECAP a esperar tu OK. Podés responder desde una sesión remota. Para tiradas largas la máquina tiene que quedar despierta (`caffeinate`).
