# axel — Implementación

> Plan a gran escala y estado por feature. La bajada fina de cada feature vive en `docs/implementation/NN-nombre.md`, con sus decisiones y su review log. La posición actual está en [STATUS.md](STATUS.md).

## Cómo se trabaja un feature

Sesión limpia → `/feature` → bajada fina → review → implementación con loop de review → RECAP → OK humano. Reglas en [AGENTS.md](../AGENTS.md); contrato de review en [design/review-contract.md](design/review-contract.md).

## Criterio de orden

1. **Restricciones humanas fijan posiciones**: los pedidos explícitos del humano no se discuten entre agentes (hoy: instalador 01 primero, 2026-07-27).
2. **Valor desbloqueado antes que pulido**: primero lo que habilita uso nuevo (llevar axel a otros proyectos) sobre lo que mejora lo que ya funciona.
3. **Robustez cuando muerde**: los ítems de hardening suben de prioridad apenas un hueco empieza a doler en el uso real; hoy nada está roto y los gaps conocidos tienen mitigación (fallback `--last`, timeout de awake).

## Features

| # | Feature | Estado | Doc |
|---|---|---|---|
| 00 | Bootstrap de la maquinaria | **Cerrado** — APPROVED de Codex (r4) + OK humano, 2026-07-27 | [implementation/00-bootstrap.md](implementation/00-bootstrap.md) |
| 01 | Instalador: llevar axel a otro proyecto | **Siguiente** — orden 1º (criterio 1: restricción humana; caso de uso real esperando) | — |
| 02 | Hardening del loop de review | Backlog — orden 2º (criterio 3: se usa a diario, pero nada muerde aún) | — |
| 03 | Notificaciones y continuidad entre sesiones | Backlog — orden 3º (calidad de vida; el push ya funciona vía harness) | — |

Orden en acuerdo: ciclo de `/plan` en curso — el APPROVED del reviewer sella el acuerdo entre agentes (la posición de 01 es restricción humana y no se discute; 02 vs 03 y el contenido de cada uno, sí).

### 01 — Instalador

Un comando que instala la maquinaria en un repo destino: copia `.claude/skills/`, `scripts/` (review.sh, awake.sh) y `.claude/settings.json`, y siembra `AGENTS.md` + symlink `CLAUDE.md` + estructura `docs/` con plantillas. axel es la fuente de verdad; los proyectos consumidores se actualizan re-corriendo el instalador.

Requisito clave (pedido humano 2026-07-27): **modo adopción** para proyectos existentes que ya vienen siguiendo el proceso a mano — detectar docs preexistentes (DESIGN/IMPLEMENTATION o equivalentes), no pisar nada, mapear lo que ya hay a la convención de axel, sembrar solo lo que falte y derivar el `STATUS.md` inicial del estado real del proyecto.

### 02 — Hardening del loop

Captura robusta del session id (hoy: primer UUID de los eventos JSONL, con fallback `resume --last`), reintentos ante fallas transitorias de Codex, métricas de rondas por feature, y `shellcheck` instalado y corriendo sobre los scripts (el reviewer lo buscó en las 4 rondas del ciclo 00 sin encontrarlo).

### 03 — Notificaciones y continuidad

Push de RECAP consistente en todos los caminos, y facilitar el arranque de la siguiente sesión limpia tras el OK (chip de spawn en desktop / instrucción única).
