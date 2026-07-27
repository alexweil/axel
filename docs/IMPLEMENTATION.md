# axel — Implementación

> Plan a gran escala y estado por feature. La bajada fina de cada feature vive en `docs/implementation/NN-nombre.md`, con sus decisiones y su review log. La posición actual está en [STATUS.md](STATUS.md).

## Cómo se trabaja un feature

Sesión limpia → `/feature` → bajada fina → review → implementación con loop de review → RECAP → OK humano. Reglas en [AGENTS.md](../AGENTS.md); contrato de review en [design/review-contract.md](design/review-contract.md).

## Features

| # | Feature | Estado | Doc |
|---|---|---|---|
| 00 | Bootstrap de la maquinaria | En review — esperando OK para la primera review de Codex | [implementation/00-bootstrap.md](implementation/00-bootstrap.md) |
| 01 | Instalador: llevar axel a otro proyecto | Backlog (propuesto) | — |
| 02 | Hardening del loop de review | Backlog (propuesto) | — |
| 03 | Notificaciones y continuidad entre sesiones | Backlog (propuesto) | — |

El orden 01–03 es propuesta del generador: queda para acordar con el reviewer en el próximo `/plan` (regla del método: las prioridades las acuerdan los dos agentes).

### 01 — Instalador

Un comando que instala la maquinaria en un repo destino: copia `.claude/skills/`, `scripts/review.sh` y `.claude/settings.json`, y siembra `AGENTS.md` + symlink `CLAUDE.md` + estructura `docs/` con plantillas. axel es la fuente de verdad; los proyectos consumidores se actualizan re-corriendo el instalador.

### 02 — Hardening del loop

Captura robusta del session id (hoy: primer UUID de los eventos JSONL), reintentos ante fallas transitorias de Codex, métricas de rondas por feature, y manejo de árboles sucios dejados por el reviewer.

### 03 — Notificaciones y continuidad

Push de RECAP consistente en todos los caminos, y facilitar el arranque de la siguiente sesión limpia tras el OK (chip de spawn en desktop / instrucción única).
