# Batch de features: `/feature all` y `/feature NN..MM`

> Profundización de [DESIGN.md](../DESIGN.md). Diseño acordado en ping-pong con el humano el 2026-07-28 (superficie y gate de lote confirmados explícitamente); la arquitectura padre↔hijo sale de un spike empírico (abajo). Esto es diseño: la implementación entra al plan vía `/plan` como cualquier feature.

## Objetivo

Ejecutar varios features priorizados del plan de una sola corrida, uno tras otro, sin OK humano entre features. El checkpoint humano no desaparece: se agrupa en un **gate de lote** al inicio y un **RECAP consolidado** al final.

## Superficie

- `/feature` sin argumento: contrato actual **intacto** — un feature, gate individual, RECAP, OK.
- `/feature all`: todos los features pendientes del plan, en el orden del plan.
- `/feature NN..MM`: rango contiguo de features pendientes (p. ej. `/feature 07..09`).
- El batch es opt-in explícito y visible en el comando; no hay modo batch implícito.

## Qué reemplaza al OK por feature

El OK humano por feature cumple hoy dos funciones mezcladas: **(a)** validar rumbo y **(b)** marcar la frontera de contexto. En modo lote:

- **(b)** la resuelve la maquinaria: cada feature corre en un subagente con contexto fresco (y sesión de Codex fresca vía `review.sh new`), exactamente la regla de "sesiones frescas por feature".
- **(a)** se agrupa adelante en el **gate de lote**: un solo mensaje con los N resúmenes derivados de los docs (el mismo mecanismo del gate del feature 05, batcheado) y **una autorización global**. El humano puede excluir features puntuales ("dale, pero el 09 no"); la exclusión queda registrada como corrección de alcance y el lote sigue con el resto.

### Semántica de los checkpoints (r1 de este ciclo)

Cada checkpoint cumple una función distinta; ninguno se solapa:

- El **gate de lote** es la **autorización de ejecución**: habilita encadenar los features autorizados sin frenar entre ellos. No cierra nada.
- El **APPROVED de Codex por feature no cambia**: sigue siendo el gate de calidad, con su loop completo de rondas.
- Dentro del lote, un feature con APPROVED queda en estado **«APPROVED — pendiente OK de lote»** — no "cerrado": el contrato vigente reserva "cerrado" para APPROVED + OK humano, y ese OK todavía no llegó. Su RECAP queda registrado en docs (es el registro), pero no bloquea.
- El **OK del RECAP consolidado** es el que **cierra**: con él, todos los features del lote pasan a "Cerrado" en IMPLEMENTATION (commit de cierre consolidado del padre).

Esto **redefine la regla dura** "nunca continuar a otro feature sin OK humano": la autorización del gate de lote es lo que habilita continuar dentro del lote, y el principio 4 del diseño se ajusta en consecuencia (la validación se agrupa; la frontera de contexto la aporta la maquinaria). La implementación debe reflejar la nueva redacción en `AGENTS.md` y `templates/AGENTS.md` (regla de sincronía).

## Arquitectura: orquestador supervisor + hijo trabajador

### Evidencia del spike (2026-07-28)

Entorno simulado (repo descartable, review falsa que duerme como Codex: 45–90s por ronda, una ronda de 11 min), loop completo de 8 rondas commit→review→veredicto ejecutado por un subagente:

- ✅ El subagente sostiene el loop: 8 rondas, 9 commits, veredicto siempre parseable, sin errores de herramienta ni salidas truncadas.
- ❌ **Hallazgo central**: el subagente **no se re-invoca** cuando su tarea background termina. Terminar el turno con la review corriendo lo deja huérfano (la review 1 terminó y quedó >6 min parado). Los avisos del harness le llegan *encolados* — se entregan recién en el próximo resume — y nunca lo despiertan; en la sesión principal ese mismo mecanismo sí re-invoca (el loop real de axel depende de eso a diario).
- ✅ El **resume por mensaje del orquestador** funcionó las 8 veces: contexto intacto, retoma en 7–18s del fin real de la review, sin releer ni repetir trabajo. La ronda de 11 min no degradó nada.
- ✅ Presión de contexto holgada (~15–20% de la ventana en el loop de juguete); estimación del propio subagente: 8–10 rondas reales viables sin compactación — el driver de consumo serían diffs y feedback largos, no la mecánica del loop.

### Contrato por ronda

- **Hijo** = el `/feature` de hoy casi sin cambios: gate resuelto por el lote, bajada fina, implementación, commits, y corre `scripts/review.sh` él mismo (misma sesión de Codex durante su feature, vía resume — como hoy). **Delta único**: donde la sesión de hoy espera el fin del background, el hijo **termina el turno** con una línea de estado ("review N lanzada"); lo despierta el orquestador.
- **Padre**: espera la **señal terminal** de la review (abajo) y manda un **empujón sin contenido** ("review N terminada, seguí"). El hijo lee veredicto y feedback de los archivos que `review.sh` persiste (`.claude/state/last-review.md`, `last-verdict`). El padre no transporta feedback → no acumula contexto de N features × M rondas y llega liviano al final del lote.
- **Entre features**: el padre verifica el estado (IMPLEMENTATION marca «APPROVED — pendiente OK de lote», STATUS al día, commit de estado presente), actualiza el ledger, renueva la ventana de `awake.sh`, y lanza el subagente del siguiente feature con contexto fresco.

### La señal terminal (r1 de este ciclo)

El estado que `review.sh` persiste hoy **no alcanza** como señal: `round` se escribe *antes* de lanzar Codex y `last-verdict` solo se actualiza ante un veredicto válido — un exit 2 deja estado viejo, y tras una reentrada un `last-verdict` del feature anterior puede parecer actual. El diseño fija la semántica (la forma exacta es de la bajada, e implica un cambio chico y versionado en `review.sh` — la afirmación inicial de "cero cambios" no se sostiene):

- **Terminal total**: todo camino de salida de `review.sh` (APPROVED, CHANGES_REQUESTED y exit 2 en todas sus variantes) escribe un registro terminal **atómico** como último acto.
- **Identidad de invocación**: el terminal lleva feature, ronda y `REVIEW_HEAD`. El padre solo empuja al ver un terminal cuya identidad coincide con la invocación que espera — nunca por mtime, ausencia de proceso ni heurísticas.
- **Sin terminal no hay empujón**: timeout del padre ⇒ se trata como falla de proceso (condición de corte 1), no se adivina.

### Estado durable del lote (r1 de este ciclo)

El lote tiene un **ledger versionado** — un doc por corrida, commiteado al autorizarse el gate (nombre y plantilla los fija la bajada; vive bajo `docs/implementation/`) — con todo lo necesario para reconstruir el lote sin el chat:

- lista y orden autorizados, exclusiones y correcciones de alcance del gate;
- **los N resúmenes tal como se autorizaron** — el corte por divergencia compara contra esto, no contra memoria de sesión;
- el feature en curso y el estado de cada uno (pendiente → en curso → APPROVED — pendiente OK de lote → cerrado);
- los cortes, con motivo y momento.

STATUS.md apunta al ledger mientras el lote corre.

**Protocolo de reentrada (fail-closed)**: si el padre muere, la sesión nueva lee STATUS + ledger + git y decide sin adivinar:

- estado consistente ("feature en curso", sin review huérfana, git coincide con el ledger) → relanza un hijo fresco para ese feature — el hijo es reconstruible por diseño: su memoria son los docs;
- cualquier inconsistencia (review corriendo o terminal ausente/de otra identidad, ledger contradictorio con git o IMPLEMENTATION) → **no relanzar**: RECAP con el estado encontrado y esperar al humano.

La reentrada nunca re-pide el gate para lo ya autorizado ni re-cierra lo ya aprobado.

### El padre es el panel de control

La sesión que el humano abrió es el padre (principio 2 del diseño: la sesión es el proceso y el panel de control). Un mensaje del humano a mitad de lote llega al padre y tiene prioridad absoluta: el padre responde, y si el mensaje afecta al feature en curso, lo baja al hijo en el próximo empujón (o lo corta). El padre se mantiene liviano justamente para poder conversar a mitad de lote.

## Condiciones de corte

El lote se frena solo y espera al humano ante cualquiera de estas — sin esta lista el batch es una máquina de propagar errores:

1. Las del loop actual: deadlock (5 rondas), exit 2 persistente, veredicto inválido repetido — y la ausencia de señal terminal dentro del timeout del padre.
2. Cambio de scope o sorpresa que excede el feature en curso.
3. **Divergencia**: el resumen re-derivado al arrancar el feature N no coincide en sustancia con el autorizado en el ledger — los docs cambiaron por los features anteriores y la autorización quedó vieja.
4. Fuentes insuficientes para un resumen honesto del feature N.

En todos los casos: RECAP (con las posturas si hubo desacuerdo) + push de una línea + fin de turno, con el corte registrado en el ledger. Los features ya aprobados quedan intactos.

## Riesgo aceptado

Un error del feature N se propaga a N+1 y N+2 antes del ojo humano, y la auditoría es por lote. **El radio real** (r1 de este ciclo): los commits delimitados por feature permiten *identificar* el tramo de N, pero no revertirlo aisladamente con seguridad cuando N+1/N+2 dependen de él — lo normal es revertir o revalidar **el sufijo completo desde N**. Y el corte por divergencia detecta cambios visibles en el resumen re-derivado; no detecta errores latentes ni decisiones de implementación compatibles con el resumen que el humano habría rechazado en un OK por feature. **Recuperación conservadora**: ante un rechazo en el OK consolidado (total o de un feature puntual), corte **sin rollback automático** — el humano decide con el RECAP a la vista, y lo que siga (revert del sufijo, replan vía `/plan`, revalidación) es trabajo explícito del método, no limpieza silenciosa. Se acepta el modo lote con ese radio documentado porque el gate de lote y las condiciones de corte lo acotan — y la alternativa con OK por feature sigue disponible: `/feature` solo no cambia.

## Encaje con reglas existentes

- **Avisos** (protocolo del feature 04, skill `recap`): el gate de lote es respuesta directa (el humano acaba de invocar `/feature all`) → sin push; el RECAP consolidado y todo corte llegan por trabajo autónomo → push de una línea.
- **awake.sh**: ventana renovable de 12h — el padre la renueva al arrancar cada feature del lote (un lote largo puede excederla).
- **Métricas**: `rounds-log` por feature, como hoy.
- **Commits de estado no revisados**: dentro del lote los barre la ronda 1 del feature siguiente (regla vigente del contrato); los del último feature y el cierre consolidado quedan cubiertos por el camino terminal de siempre (listados en el RECAP consolidado).

## Decisiones que quedan para la bajada (no exhaustivo)

- Forma exacta del registro terminal (archivo, formato, escritura atómica) y del ledger (nombre, plantilla) — la semántica de ambos ya está fijada arriba.
- Forma exacta del empujón y de la línea de estado del hijo (protocolo mínimo probado en el spike: `REVIEW N LANZADA` / `REVIEW N TERMINADA`).
- Timeout del padre para la señal terminal (y su relación con la duración esperable de una review xhigh).
- Si el cierre de cada feature lleva tag de git además del commit identificable.
- Cómo baja exactamente al hijo un mensaje del humano a mitad de feature (empujón enriquecido vs. corte y relanzamiento).
- Validación del rango `NN..MM` (features inexistentes, no contiguos, ya cerrados).
