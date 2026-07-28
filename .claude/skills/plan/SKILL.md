---
name: plan
description: Armar o actualizar docs/IMPLEMENTATION.md — features priorizados y acordados entre generador y reviewer — y cerrarlo con el loop de review.
---

Sos el generador. Leé `AGENTS.md`, `docs/STATUS.md` y `docs/DESIGN.md` primero.

1. **Bajada del diseño a plan**: `docs/IMPLEMENTATION.md` con la lista de features/iteraciones priorizada, el criterio de orden explícito, y el estado de cada uno. La bajada fina de cada feature NO va acá — eso ocurre en `/feature`; acá va el qué y el porqué del orden. Actualizá STATUS.md. Commit.
2. **Review con acuerdo explícito**: `scripts/review.sh new`; pedile a Codex que evalúe prioridades y orden, y que proponga cambios si no acuerda. Iterá hasta APPROVED — acá APPROVED significa "los dos agentes acuerdan el orden".
3. **RECAP** con el plan resultante (estructura y aviso: skill `recap` — llegás por trabajo autónomo) y esperá el OK humano. Con el OK: registralo en STATUS y commiteá; el siguiente paso es `/feature` para el primero de la lista, en sesión limpia — si la sesión tiene herramienta de spawn de sesión (hoy: el chip del desktop), creá el chip: título "Feature NN: <nombre> — sesión limpia" (el primero de la lista), prompt **únicamente `/feature`**, tldr de una línea; si no está o falla, instrucción única: sesión nueva + `/feature` (desde terminal: `claude "/feature"`).

Reglas: al entrar al loop de review, `scripts/awake.sh start`; todo commit toca docs; reviews largas en background; si `review.sh` reporta `DEADLOCK` (5 rondas sin converger) no reintentes — RECAP con ambas posturas y, tras el desempate humano, `scripts/review.sh reset-deadlock`; las fallas de proceso de codex las reintenta `review.sh` una sola vez (exit 2 persistente ⇒ diagnóstico con los eventos y RECAP), y un veredicto inválido no se reintenta (relanzá recordando el contrato, o RECAP si se repite); todo RECAP sigue la skill `recap` (estructura y aviso).
