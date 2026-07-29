---
name: design
description: Fase de diseño de axel — ping-pong de ideas con el humano, consolidar docs/DESIGN.md (y docs/design/*.md) y cerrarla con el loop de review de Codex. Usala cuando el humano describe una idea, un proyecto o un rumbo nuevo, o pide repensar o extender el diseño, aunque no escriba /design; también cuando no hay un DESIGN.md real (solo la semilla del instalador) y el pedido necesita uno.
---

Sos el generador. Leé `AGENTS.md` y `docs/STATUS.md` primero.

**Guarda de entrada.** Si el pedido llegó **sin comando** (ruteo) y STATUS registra estado pendiente de **otra** fase —adopción sin cerrar (`docs/ADOPTION.md`), feature o lote activo, cualquier espera de OK humano, ciclo de plan abierto, confirmación de plan pendiente—, no arranques trabajo nuevo: decí qué encontraste y entrá por la reentrada de la skill dueña. Con `/design` **explícito** (el comando es el primer token del pedido) el camino es el de hoy: informá en una línea el estado ajeno que veas y seguí la indicación del humano — prioridad absoluta —, con RECAP temprano si implica cambio de scope sobre un ciclo abierto. El orden completo vive en `AGENTS.md` §Ruteo; esta guarda lo hace valer aunque esa sección falte (`AGENTS.md` es semilla del instalador: un proyecto ya instalado no la recibe al actualizar).

## Reentrada (STATUS ya muestra un ciclo de diseño en curso)

No arranques de cero ni re-consolides a ciegas. Reconstruí primero con el protocolo común —frontera previa, token de ronda de STATUS, resolución del desenlace, precondición de la ronda siguiente— de `docs/design/review-contract.md` §Reentrada: **no relanzar jamás una review que puede estar en vuelo**. Con el desenlace resuelto, el paso sale del estado de los docs:

- **Ping-pong a medias** (DESIGN.md sin consolidar el tema en curso): no inventes lo que se habló — ese chat era efímero y no está en los docs. Resumí en pocas líneas lo que docs y commits sí registran, decí explícitamente qué falta definir, y retomá el ping-pong con el humano (respuesta directa ⇒ sin push).
- **Consolidado, `Ronda: —`**: paso 3 (`scripts/review.sh new`).
- **`CHANGES_REQUESTED` consumido**: corregí o argumentá lo pendiente → commit → `round`. Los commits del ciclo dicen qué ya se atendió: jamás reproceses a ciegas. Si el contenido del feedback se perdió (`.claude/state/last-review.md` ausente) y los commits no alcanzan, pedile al reviewer que lo reemita sobre el rango vigente — la fuente autoritativa es él, no el recuerdo.
- **`APPROVED` consumido, sin RECAP**: paso 4.
- **STATUS «esperando OK»**: re-presentá el RECAP pendiente y esperá (respuesta directa ⇒ sin push). No avances trabajo nuevo.
- **Inconsistencia** (STATUS contra DESIGN.md o el git log): RECAP con lo encontrado, sin adivinar.

1. **Ping-pong**: discutí las ideas con el humano hasta que la dirección esté clara. No escribas docs grandes antes de que el humano valide el rumbo; preguntá lo que haga falta.
2. **Consolidación**: volcá el diseño a `docs/DESIGN.md` (visión a gran escala: objetivo, principios, componentes, flujo, decisiones con su porqué). Los temas que pidan profundidad van a `docs/design/<tema>.md`, referenciados desde DESIGN.md. Actualizá STATUS.md. Commit.
3. **Review**: `scripts/review.sh new` con un pedido que explique qué es el diseño y qué revisar (coherencia, huecos, riesgos, decisiones mal fundadas). Iterá — corregir o argumentar → commit → `scripts/review.sh round` — hasta APPROVED. Las decisiones que surjan de la review quedan registradas en DESIGN.md.
4. **RECAP** (estructura y aviso: skill `recap` — llegás por trabajo autónomo) y esperá el OK humano. Con el OK: registralo en STATUS y commiteá; el siguiente paso es `/plan` en sesión limpia — si la sesión tiene herramienta de spawn de sesión (hoy: el chip del desktop), creá el chip: título "/plan — sesión limpia", prompt **únicamente `/plan`**, tldr de una línea; si no está o falla, instrucción única: sesión nueva + `/plan` (desde terminal: `claude "/plan"`).

Reglas: al entrar al loop de review, `scripts/awake.sh start`; todo commit toca docs; **el commit previo a cada review declara el token de ronda en STATUS** — con `new`, `1 · lanzada` **sin derivar** (`new` publica siempre 1, y el contador puede traer el valor del ciclo anterior); con `round`, `N` = `.claude/state/round` + 1 bajo la precondición del contrato y su línea de commit **nombra la ronda** (`… r2: …`) — son la memoria del ciclo que la reentrada lee, porque el diseño no tiene Review log propio; reviews largas en background; si `review.sh` reporta `DEADLOCK` (5 rondas sin converger) no reintentes — RECAP con ambas posturas y, tras el desempate humano, `scripts/review.sh reset-deadlock`; las fallas de proceso de codex las reintenta `review.sh` una sola vez (exit 2 persistente ⇒ diagnóstico con los eventos y RECAP), y un veredicto inválido no se reintenta (relanzá recordando el contrato, o RECAP si se repite); todo RECAP sigue la skill `recap` (estructura y aviso); mensajes del humano, prioridad absoluta.
