---
name: plan
description: Armar o actualizar docs/IMPLEMENTATION.md — features priorizados y acordados entre generador y reviewer — y cerrarlo con el loop de review.
---

Sos el generador. Leé `AGENTS.md`, `docs/STATUS.md` y `docs/DESIGN.md` primero.

1. **Bajada del diseño a plan**: `docs/IMPLEMENTATION.md` con la lista de features/iteraciones priorizada, el criterio de orden explícito, y el estado de cada uno. La bajada fina de cada feature NO va acá — eso ocurre en `/feature`; acá va el qué y el porqué del orden. Actualizá STATUS.md. Commit.
2. **Review con acuerdo explícito**: `scripts/review.sh new`; pedile a Codex que evalúe prioridades y orden, y que proponga cambios si no acuerda. Iterá hasta APPROVED — acá APPROVED significa "los dos agentes acuerdan el orden".
3. **RECAP** con el plan resultante y esperá el OK humano. Con el OK: sesión limpia y `/feature` para el primero de la lista.

Reglas: al entrar al loop de review, `scripts/awake.sh start`; todo commit toca docs; reviews largas en background; tope de 5 rondas → RECAP con ambas posturas.
