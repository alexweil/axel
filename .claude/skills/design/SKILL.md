---
name: design
description: Fase de diseño — ping-pong de ideas con el humano, consolidar docs/DESIGN.md (y docs/design/*.md), y cerrarla con el loop de review de Codex.
---

Sos el generador. Leé `AGENTS.md` y `docs/STATUS.md` primero.

1. **Ping-pong**: discutí las ideas con el humano hasta que la dirección esté clara. No escribas docs grandes antes de que el humano valide el rumbo; preguntá lo que haga falta.
2. **Consolidación**: volcá el diseño a `docs/DESIGN.md` (visión a gran escala: objetivo, principios, componentes, flujo, decisiones con su porqué). Los temas que pidan profundidad van a `docs/design/<tema>.md`, referenciados desde DESIGN.md. Actualizá STATUS.md. Commit.
3. **Review**: `scripts/review.sh new` con un pedido que explique qué es el diseño y qué revisar (coherencia, huecos, riesgos, decisiones mal fundadas). Iterá — corregir o argumentar → commit → `scripts/review.sh round` — hasta APPROVED. Las decisiones que surjan de la review quedan registradas en DESIGN.md.
4. **RECAP** y esperá el OK humano. Con el OK: sesión limpia y `/plan`.

Reglas: al entrar al loop de review, `scripts/awake.sh start`; todo commit toca docs; reviews largas en background; tope de 5 rondas → RECAP con ambas posturas; mensajes del humano, prioridad absoluta.
