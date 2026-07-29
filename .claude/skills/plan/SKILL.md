---
name: plan
description: Armar o actualizar docs/IMPLEMENTATION.md — features priorizados y acordados entre generador y reviewer — y cerrarlo con el loop de review.
---

Sos el generador. Leé `AGENTS.md`, `docs/STATUS.md` y `docs/DESIGN.md` primero.

## Reentrada (STATUS ya muestra un ciclo de plan en curso)

No arranques de cero ni reescribas el plan a ciegas. Reconstruí primero con el protocolo común —frontera previa, token de ronda de STATUS, resolución del desenlace, precondición de la ronda siguiente— de `docs/design/review-contract.md` §Reentrada: **no relanzar jamás una review que puede estar en vuelo**. Con el desenlace resuelto, el paso sale del estado de los docs:

- **Bajada a medias** (IMPLEMENTATION.md sin la entrada o la extensión del ciclo en curso): retomá el paso 1 desde lo que DESIGN.md y el propio plan ya registran.
- **Escrito, `Ronda: —`**: paso 2 (`scripts/review.sh new`).
- **`CHANGES_REQUESTED` consumido**: corregí o argumentá lo pendiente → commit → `round`. Los commits del ciclo dicen qué ya se atendió: jamás reproceses a ciegas. Si el contenido del feedback se perdió (`.claude/state/last-review.md` ausente) y los commits no alcanzan, pedile al reviewer que lo reemita sobre el rango vigente.
- **`APPROVED` consumido, sin RECAP**: paso 3.
- **STATUS «esperando OK»**: re-presentá el RECAP pendiente y esperá (respuesta directa ⇒ sin push). No avances trabajo nuevo.
- **Inconsistencia** (STATUS contra IMPLEMENTATION.md o el git log): RECAP con lo encontrado, sin adivinar.

1. **Bajada del diseño a plan**: `docs/IMPLEMENTATION.md` con la lista de features/iteraciones priorizada, el criterio de orden explícito, y el estado de cada uno. La bajada fina de cada feature NO va acá — eso ocurre en `/feature`; acá va el qué y el porqué del orden. Actualizá STATUS.md. Commit.
2. **Review con acuerdo explícito**: `scripts/review.sh new`; pedile a Codex que evalúe prioridades y orden, y que proponga cambios si no acuerda. Iterá hasta APPROVED — acá APPROVED significa "los dos agentes acuerdan el orden".
3. **RECAP** con el plan resultante (estructura y aviso: skill `recap` — llegás por trabajo autónomo) y esperá el OK humano. Con el OK: registralo en STATUS y commiteá; el siguiente paso es `/feature` para el primero de la lista, en sesión limpia — si la sesión tiene herramienta de spawn de sesión (hoy: el chip del desktop), creá el chip: título "Feature NN: <nombre> — sesión limpia" (el primero de la lista), prompt **únicamente `/feature`**, tldr de una línea; si no está o falla, instrucción única: sesión nueva + `/feature` (desde terminal: `claude "/feature"`).

Reglas: al entrar al loop de review, `scripts/awake.sh start`; todo commit toca docs; **el commit previo a cada review declara el token de ronda en STATUS** — con `new`, `1 · lanzada` **sin derivar** (`new` publica siempre 1, y el contador puede traer el valor del ciclo anterior); con `round`, `N` = `.claude/state/round` + 1 bajo la precondición del contrato y su línea de commit **nombra la ronda** (`… r2: …`) — son la memoria del ciclo que la reentrada lee, porque el plan no tiene Review log propio; reviews largas en background; si `review.sh` reporta `DEADLOCK` (5 rondas sin converger) no reintentes — RECAP con ambas posturas y, tras el desempate humano, `scripts/review.sh reset-deadlock`; las fallas de proceso de codex las reintenta `review.sh` una sola vez (exit 2 persistente ⇒ diagnóstico con los eventos y RECAP), y un veredicto inválido no se reintenta (relanzá recordando el contrato, o RECAP si se repite); todo RECAP sigue la skill `recap` (estructura y aviso).
