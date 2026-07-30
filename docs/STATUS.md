# STATUS

- **Fase**: **pipeline `/build` en curso** — autorizado el 2026-07-29 · ledger: [implementation/pipeline-2026-07-29-3.md](implementation/pipeline-2026-07-29-3.md) (`gate_base` `39b377e`)
- **Unidad en curso**: `design` (design-delta) — superficie pública de axel: posicionamiento, política de idioma, licencia y evidencia auditable. **Delta consolidado** en [design/public-surface.md](design/public-surface.md) + tres filas de decisión y la fila de componentes en [DESIGN.md](DESIGN.md). Corre con `opus` (degradación anunciada: `fable` rechazado por falta de créditos en la cuenta; registrada en el ledger). Backlog vacío (los doce features del plan cerrados); la ruta agrega los features 13 y 14
- **Ronda de review**: 4 · lanzada
- **Último veredicto**: CHANGES_REQUESTED · ronda 3 · base `886fe4f` — tres puntos de precisión, los tres aceptados y corregidos en r4
- **Esperando**: desenlace de la review r4 de la unidad `design`. El pipeline corre sus cuatro unidades (`design` → `plan` → `13` → `14`) y frena en el RECAP consolidado, cuyo OK las cierra. Ajuste de alcance del gate: el pipeline **no pushea ni toca los settings de GitHub** (topics/homepage) — eso lo hace el humano. Sigue sin registrar el fix de la colisión `build/` del instalador (fuera de alcance por decisión del humano)
- **Actualizado**: 2026-07-29

> Vigente desde este delta (pendiente de review): la **superficie pública** tiene diseño propio — idioma por audiencia en tres planos (vidriera en inglés, método en español, **prosa instalada** en el destino declarada como limitación), licencia MIT, corte README/manual, y la evidencia del reviewer como foto versionada con commit de corte y comando de derivación. Detalle: [design/public-surface.md](design/public-surface.md).

> Vigente desde el feature 12: el cierre de `/adopt` reporta el **inventario derivado de git** de los archivos que tocó, separando lo mecánico de lo que el humano debe ratificar. Contrato reusable (hoy con un único consumidor) en `.claude/skills/adopt/SKILL.md` §«Reporte de cierre (contrato)».

> Vigente desde el feature 11: el modelo de los **hijos** (subagentes de lote o pipeline) lo fija la maquinaria por tipo de unidad —`fable` para `design`/`plan`, `opus` para `feature`—, no se hereda de la sesión, y el humano lo overridea por gate. Tabla canónica: skill `build`, §«Modelos por unidad».
