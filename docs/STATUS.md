# STATUS

- **Fase**: **pipeline `/build`** — gate presentado, sin autorizar · ledger: [implementation/pipeline-2026-07-29-3.md](implementation/pipeline-2026-07-29-3.md) (`gate_base` `39b377e`)
- **Feature en curso**: ninguno — backlog vacío (los doce features del plan cerrados); la ruta propuesta agrega los features 13 y 14
- **Ronda de review**: —
- **Último veredicto**: APPROVED de cierre · ronda 7 · base `6f2c04a` (feature 12)
- **Esperando**: **autorización de pipeline** — ruta de cuatro unidades (`design` → `plan` → `13` → `14`) para dejar el repo público presentable: README en inglés, licencia MIT, `docs/install.md`, CONTRIBUTING, `.github/` y las métricas del reviewer versionadas. El pendiente restante sigue sin registrar: el fix de la colisión `build/` del instalador (fuera de alcance por decisión del humano)
- **Actualizado**: 2026-07-29

> Vigente desde el feature 12: el cierre de `/adopt` reporta el **inventario derivado de git** de los archivos que tocó, separando lo mecánico de lo que el humano debe ratificar. Contrato reusable (hoy con un único consumidor) en `.claude/skills/adopt/SKILL.md` §«Reporte de cierre (contrato)».

> Vigente desde el feature 11: el modelo de los **hijos** (subagentes de lote o pipeline) lo fija la maquinaria por tipo de unidad —`fable` para `design`/`plan`, `opus` para `feature`—, no se hereda de la sesión, y el humano lo overridea por gate. Tabla canónica: skill `build`, §«Modelos por unidad».
