---
name: status
description: Consulta de ubicación en axel — leer STATUS.md, el plan y el git log, y contar dónde estamos parados y qué se está esperando. No cambia nada. Usala para cualquier pregunta de estado o avance («¿dónde estamos?», «¿qué falta?», «¿cómo viene?»): es la única entrada para consultas, no elijas recap para una pregunta.
---

Leé `docs/STATUS.md`, la tabla de features de `docs/IMPLEMENTATION.md` y `git log --oneline -10`. Si hay un loop de review en curso, corré `scripts/review.sh status`. **Si STATUS apunta a un ledger** (`docs/implementation/batch-*.md` o `pipeline-*.md`), leelo también: es donde vive el estado de una corrida orquestada.

Respondé en 5–10 líneas: fase, feature en curso, última actividad (commits), ronda y último veredicto del reviewer, y qué se está esperando (¿OK humano? ¿una review corriendo? ¿nada?). Si hay algo esperando al humano, decilo primero. Con un ledger a la vista, decí **tipo de corrida** (lote o pipeline), **unidad o feature en curso** y **progreso** (cuáles cerradas, cuáles pendientes) — en un pipeline la unidad puede ser un `design-delta` o un `plan-delta`, y entonces «feature en curso» no aplica. Si `docs/DESIGN.md` o `docs/IMPLEMENTATION.md` traen el marker **`borrador (modo POC)`**, decilo: el endurecimiento sigue pendiente. No modifiques nada.
