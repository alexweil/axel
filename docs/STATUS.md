# STATUS

- **Fase**: **pipeline `/build`** — fin de corrida, las dos unidades aprobadas · ledger: [implementation/pipeline-2026-07-29-2.md](implementation/pipeline-2026-07-29-2.md) (ruta: plan-delta → feature 12) · `gate_base` `88020af`
- **Unidad en curso**: ninguna — la unidad `12` (feature) quedó **APPROVED — pendiente OK de pipeline** (APPROVED de Codex en la r7: bajada en r4, implementación en r7; [implementation/12-adopt-close-report.md](implementation/12-adopt-close-report.md)). La unidad previa `plan` (plan-delta) también. Las dos unidades de la ruta están cerradas por review: lo que falta es el **OK humano del RECAP consolidado** del pipeline, que lo arma el padre
- **Ronda de review**: 7 · consumida
- **Último veredicto**: APPROVED · ronda 7 · base `6f2c04a` (head `886fe4f`) — **APPROVED de cierre**, los nueve criterios cumplidos, sin observaciones accionables
- **Esperando**: **esperando OK** humano del RECAP consolidado del pipeline (base `gate_base` `88020af`), cuyo OK cierra las **dos** unidades
- **Actualizado**: 2026-07-29

> Vigente desde el feature 11: el modelo de los **hijos** (subagentes de lote o pipeline) lo fija la maquinaria por tipo de unidad —`fable` para `design`/`plan`, `opus` para `feature`—, no se hereda de la sesión, y el humano lo overridea por gate. Tabla canónica: skill `build`, §«Modelos por unidad».
