---
name: feature
description: Continuar el loop de axel con el feature en curso o el siguiente — bajada fina, implementación iterando con review de Codex, RECAP y espera del OK humano.
---

Sos el generador del loop de axel. Antes de nada leé: `docs/STATUS.md`, `AGENTS.md`, `docs/IMPLEMENTATION.md` y, si existe, el doc del feature en curso (`docs/implementation/NN-*.md`).

## Si STATUS dice "esperando OK humano"

No avances trabajo nuevo: presentale al humano el RECAP pendiente (estructura y aviso: skill `recap`; acá llegás por respuesta directa a su mensaje) y esperá su respuesta.
Cuando el OK llegue: actualizá STATUS.md al siguiente paso y commiteá. Si el OK cierra un feature, el siguiente arranca en **sesión limpia** — no lo implementes en esta: el contexto por feature es regla del método. Facilitá ese arranque: si la sesión tiene herramienta de spawn de sesión (hoy: el chip de spawn del desktop), creá el chip — título "Feature NN: <nombre> — sesión limpia", prompt **únicamente `/feature`** (el estado vive en los docs, el chip no lleva contexto del chat), tldr de una línea; si la herramienta no está o su invocación falla, instrucción única en el chat: sesión nueva en este repo + `/feature` (desde terminal: `claude "/feature"`). Si no queda feature siguiente en IMPLEMENTATION.md, no hay chip que crear: ofrecé `/plan` por si el humano quiere extender el plan.

## Feature nuevo (STATUS no apunta a ninguno en curso)

1. Tomá el siguiente feature según la prioridad de IMPLEMENTATION.md.
2. **Bajada fina** → `docs/implementation/NN-nombre.md`: alcance, enfoque técnico, criterios de cierre, riesgos, y una sección "Review log" vacía. STATUS.md → feature en curso. Commit.
3. **Review de la bajada**: `scripts/review.sh new` con un pedido que explique qué revisar (la bajada contra DESIGN/IMPLEMENTATION). Iterá hasta APPROVED: cada ronda es corregir o argumentar → commit → `scripts/review.sh round`.
4. **Implementación en pasos chicos**. En cada paso: cambios + doc del feature al día (decisiones al Review log) + STATUS.md → commit → `scripts/review.sh round` con un pedido que diga QUÉ verificar y la evidencia (tests corridos por vos, con salida). Respondé cada punto numerado del feedback: corrección con commit, o argumento; Codex mantiene contexto por resume, la discusión se resuelve en el loop.
5. **APPROVED de cierre** (criterios de cierre del doc cumplidos) → IMPLEMENTATION.md marca el feature cerrado, STATUS.md → "esperando OK" → commit de cierre → RECAP (estructura y aviso: skill `recap` — llegás por trabajo autónomo) → **terminá el turno**. No sigas trabajando. (Los commits de cierre no mueven la base: los verifica la ronda 1 del ciclo siguiente — regla del contrato.)
6. **Camino terminal**: si este feature es el último previsto (no queda siguiente en IMPLEMENTATION.md, o el humano indicó frenar acá), no hay ciclo que barra los commits de cierre — el RECAP debe listarlos explícitamente como no-revisados-por-Codex y tu OK es lo que los cubre; si el cierre tuvo sustancia más allá de bookkeeping, pedí antes una mini-review con `scripts/review.sh round` sobre esos commits.

## Reglas del loop

- Al entrar al loop corré `scripts/awake.sh start` (renueva la ventana de 12h para que la máquina no se duerma; cubre generación y review). Dejala corriendo durante la espera de OK — el backstop es el timeout; `scripts/awake.sh stop` solo si el humano lo pide.
- Reviews largas (xhigh puede tardar >10 min): corré `scripts/review.sh` con Bash en background (`run_in_background`) y continuá cuando termine. No dupliques una review en curso.
- Tope de 5 rondas sin convergencia, cambio de scope, o algo roto que excede el feature → cortá a RECAP temprano con las posturas de ambos agentes. Todo RECAP sigue la skill `recap` (estructura y aviso — el criterio de cuándo va push vive ahí).
- `review.sh` exit 2: mirá el stderr. Si dice `DEADLOCK` **no reintentes**: armá el RECAP con ambas posturas y esperá el desempate humano; con su OK corré `scripts/review.sh reset-deadlock` y seguí según lo que él decida. Si fue una falla de proceso (codex caído, sin mensaje final), `review.sh` **ya la reintentó una vez** — diagnosticá con `.claude/state/last-review-events.jsonl` (y `last-review-events.failed.jsonl`, el intento fallido); solo si la causa es claramente transitoria relanzá la ronda una vez más, y si persiste, RECAP con el problema. Si fue un veredicto inválido (mensaje entregado sin la línea exacta), no es transitorio: relanzá una ronda recordándole el contrato al reviewer, y si se repite, RECAP.
- Todo commit toca algún doc. `main` lineal, sin amend.
- Mensajes del humano a mitad del loop: prioridad absoluta — respondé y ajustá antes de seguir.
