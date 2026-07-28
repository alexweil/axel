# 04 — Notificaciones y continuidad entre sesiones

## Alcance

Calidad de vida sobre las dos costuras donde el loop se encuentra con el humano (IMPLEMENTATION §04): que **ningún camino que quede esperando un OK se quede esperando en silencio**, y que **arrancar el paso siguiente tras un OK cueste un click** (o una instrucción única donde no hay click). Tres entregables:

1. **Inventario de caminos de espera**: enumeración completa (en este doc) de los puntos donde el generador termina su turno esperando al humano, cada uno clasificado con/sin aviso según un criterio único.
2. **Protocolo de aviso unificado**: una regla, centralizada en la skill `recap`, que reemplaza las dos menciones actuales e inconsistentes de `PushNotification` (la skill `recap` condiciona con un difuso "si el humano no está activo en la sesión"; el paso 5 de `feature` avisa incondicionalmente y solo en el cierre — los RECAP de `/design`, `/plan` y todos los tempranos hoy no avisan nunca).
3. **Continuidad tras el OK**: en cada cruce de frontera de contexto (OK que cierra fase o feature → sesión limpia siguiente), facilitar el arranque: chip de spawn si la sesión tiene la herramienta (desktop), instrucción única si no.

**Fuera de alcance**:

- **Scripts y contrato**: `review.sh`, `awake.sh` y `review-contract.md` no se tocan. El push y el spawn son herramientas del harness de la sesión del generador, no subprocesos; nada de la mecánica del loop (veredictos, estado, exit codes) cambia.
- **Avisos a mitad de loop** (fin de una ronda larga de review): no hay espera humana — el generador continúa solo cuando el background termina; avisar sería ruido.
- **Garantía de entrega del push**: es best-effort del harness. El estado autoritativo sigue siendo `STATUS.md` (principio 1): quien abre una sesión reconstruye todo aunque el push nunca haya llegado.
- **Surfaces sin herramientas** (CLI pelado, harness sin push): la degradación es parte del protocolo (sin aviso / instrucción única), no un caso a resolver aparte.

## Enfoque técnico

Todo el delta es prosa: skills (`recap`, `feature`, `design`, `plan`), `AGENTS.md` + `templates/AGENTS.md` (duplicación raíz↔plantilla) y `DESIGN.md` (fila de decisión). Las skills son payload del instalador, así que los proyectos consumidores reciben el protocolo re-corriendo la instalación sin cambio adicional.

### Inventario de caminos de espera

El criterio que decide el aviso es **cómo se llegó a la espera**, no dónde: si el turno que termina esperando es la **respuesta inmediata a un mensaje que el humano acaba de mandar**, el humano está presente por construcción y el push es ruido; si el turno venía de **trabajo autónomo** (rondas de review en background, implementación larga), el humano puede llevar horas afuera y el aviso es exactamente lo que falta. Esto reemplaza la condición actual "si el humano no está activo en la sesión", que pedía adivinar presencia; el criterio nuevo se decide mirando el propio turno. Borde resuelto: si el humano mandó un mensaje a mitad del loop y después hubo rondas autónomas antes del RECAP, va aviso; en la duda, va aviso — el costo de un push redundante es trivial, el de un loop estancado se mide en horas.

El universo del inventario son los **turnos que terminan esperando una respuesta del humano** — de cualquier tipo: OK de un RECAP, desempate, o respuesta en conversación interactiva. `/status` queda fuera del universo, no clasificado como "sin aviso": responde y termina, no queda esperando nada.

**Esperas alcanzadas por trabajo autónomo** — con aviso:

| Camino | Dónde |
|---|---|
| RECAP de cierre de feature (APPROVED de cierre) | skill `feature`, paso 5 |
| RECAP terminal (sin feature siguiente) | skill `feature`, paso 6 |
| RECAP de diseño (tras el loop de review) | skill `design`, paso 4 |
| RECAP de plan (tras el loop de review) | skill `plan`, paso 3 |
| RECAP temprano: deadlock (racha 5) | reglas de `feature`/`design`/`plan` |
| RECAP temprano alcanzado tras trabajo autónomo: tope de rondas, exit 2 persistente, veredicto inválido repetido, o un cambio de scope/sorpresa que el propio loop detecta | reglas de `feature`/`design`/`plan` |

**Esperas interactivas** — respuesta directa a un mensaje recién mandado, sin aviso:

| Camino | Dónde |
|---|---|
| Ping-pong de `/design` (preguntas de rumbo al humano) | skill `design`, paso 1 |
| Decisiones de `/adopt` (mapeo doc por doc, pendientes mecánicos, confirmaciones) | skill `adopt` |
| RECAP temprano disparado por el mensaje humano recién recibido (el cambio de scope o la sorpresa surge de lo que el humano acaba de decir y el RECAP es la respuesta inmediata) | reglas de `feature`/`design`/`plan` |
| `/recap` a demanda | skill `recap` |
| Reapertura con STATUS "esperando OK" (re-presentar el RECAP) | skill `feature`, camino esperando-OK |

### Protocolo de aviso (centralizado en la skill `recap`)

- **Cuándo**: todo RECAP alcanzado por trabajo autónomo (tabla de arriba), al terminar el turno en espera de OK.
- **Qué**: una línea, en español: `<proyecto>: <qué pasó> — <qué se espera>` (p. ej. "axel: feature 04 cerrado (APPROVED r2) — esperando tu OK"; "axel: DEADLOCK en la ronda 5 — RECAP con ambas posturas, esperando desempate").
- **Con qué**: la herramienta de push del harness (hoy: `PushNotification`; puede requerir cargarla vía búsqueda de herramientas). Si no está disponible, se sigue sin aviso y sin mencionar la ausencia como error: la degradación es silenciosa porque el estado autoritativo es STATUS.md.
- **Dónde vive la regla**: solo en la skill `recap`. Las skills `feature`, `design` y `plan` referencian ("RECAP — estructura y aviso según la skill `recap`") sin repetir el protocolo: las dos menciones actuales de `PushNotification` fuera de `recap` desaparecen. La lección es del propio ciclo 03 (r7): los restatements divergen; una regla, un lugar.

### Continuidad tras el OK

Cruces de frontera de contexto y su paso siguiente:

| OK que cierra | Siguiente paso en sesión limpia | Skill responsable |
|---|---|---|
| OK del diseño | `/plan` | `design` |
| OK del plan | `/feature` (primero de la lista) | `plan` |
| OK de cierre de feature | `/feature` (siguiente) | `feature`, camino esperando-OK |
| OK terminal (sin siguiente en IMPLEMENTATION) | nada por default; `/plan` solo si el humano quiere extender el plan | `feature` |

Protocolo, tras registrar el OK (STATUS.md actualizado + commit):

- **Con herramienta de spawn de sesión** (hoy: el chip de spawn del desktop, `spawn_task`): crear el chip — título "Feature NN: <nombre> — sesión limpia" (o "/plan — sesión limpia"), prompt **solo el comando de la skill** (`/feature`, `/plan`), tldr de una línea. El prompt es autocontenido por el principio 1: el estado vive en los docs, la sesión nueva reconstruye todo leyéndolos — el chip no necesita (ni debe) llevar contexto del chat.
- **Sin herramienta, o con la invocación fallando**: instrucción única en el chat, parametrizada por el comando del cruce — "sesión nueva en este repo + `<comando>`" (desde terminal: `claude "/plan"` o `claude "/feature"` según el cruce). Un fallo al crear el chip degrada a la misma instrucción, mencionándolo en el chat sin tratarlo como error del loop.
- En ningún caso se implementa el siguiente feature en la sesión vieja (regla existente del método; el chip/instrucción la refuerza, no la reemplaza).

### Docs afectados

`recap` (protocolo completo), `feature`/`design`/`plan` (referencias + chip en sus caminos de OK), `AGENTS.md` y `templates/AGENTS.md` (una línea en Convenciones que **referencia** el protocolo — "aviso en esperas autónomas y chip/instrucción única tras el OK, según la skill `recap` y las skills de fase" — misma línea en ambos por la regla de duplicación; referencia de alto nivel, no una segunda formulación normativa que pueda divergir), `DESIGN.md` (la fila de decisión RECAP de 2026-07-27 se **actualiza en su lugar**: queda marcada como refinada el 2026-07-28 por el criterio de autonomía y remite a la skill `recap` como fuente del protocolo — no se agrega una fila paralela que deje viva la formulación vieja "push si está disponible"). `review-contract.md` no se toca. Las skills `status` y `adopt` tampoco cambian de texto (`/status` está fuera del universo; las esperas de `/adopt` son interactivas y ya operan así).

### Implementación en un paso

El delta es chico y coherente (prosa interdependiente): un solo paso de implementación tras el APPROVED de la bajada — skills + AGENTS + plantilla + DESIGN en un commit — y luego el cierre. La aceptación tiene dos planos con frontera explícita:

- **Dentro del rango que revisa Codex**: en el paso de implementación se ejercita la herramienta real de push desde esta sesión con un aviso de prueba de una línea, y el resultado (disponibilidad, carga, envío, respuesta de la herramienta) queda registrado en este doc — evidencia verificable en la review.
- **Post-APPROVED**: el ejercicio vivo del protocolo completo (push del RECAP de cierre + rama terminal de continuidad) ocurre necesariamente después del APPROVED de cierre, así que **no es criterio de cierre ni condición del veredicto de Codex**: vive en la sección «Aceptación terminal» (tras los criterios), cubierto por el OK humano terminal.

## Criterios de cierre

1. **Inventario completo y aplicado**: el inventario cubre todos los turnos de las skills que terminan esperando respuesta del humano (autónomos e interactivos), cada uno clasificado por el criterio de autonomía; las skills quedan tales que cada espera con aviso alcanza la regla (directamente o por referencia a `recap`).
2. **Protocolo en un solo lugar**: formato, criterio y degradación viven solo en la skill `recap`; `feature`/`design`/`plan` referencian sin restatement; la condición ambigua actual ("si el humano no está activo") y la mención suelta del paso 5 de `feature` eliminadas.
3. **Continuidad documentada**: las **tres transiciones con spawn** (diseño→`/plan`, plan→`/feature`, feature→`/feature` siguiente), cada una en su skill con chip + fallback de instrucción única parametrizada por el comando del cruce, **más la rama terminal sin spawn por default** (ofrecimiento de `/plan` en el texto del RECAP); el prompt del chip es solo el comando de la skill; la degradación cubre tanto ausencia de la herramienta como fallo de su invocación.
4. **Docs sincronizados**: `AGENTS.md` y `templates/AGENTS.md` con la misma convención nueva (duplicación raíz↔plantilla verificable por diff de la sección); `DESIGN.md` con la fila RECAP actualizada en su lugar (sin formulación vieja residual); IMPLEMENTATION/STATUS al día.
5. **Prueba real del push dentro del rango**: durante el paso de implementación se ejercita la herramienta real de push desde esta sesión con un aviso de prueba de una línea, y el resultado (disponibilidad, carga, envío, respuesta de la herramienta) queda registrado en este doc — evidencia verificable por Codex en la review.

Los cinco criterios son verificables por Codex al momento del APPROVED de cierre. Lo que ocurre después vive en la sección siguiente y **no** es condición de ese APPROVED.

## Aceptación terminal (post-APPROVED, fuera de los criterios de cierre)

El ejercicio vivo del protocolo completo — el push del RECAP de cierre del 04 y la rama terminal de la continuidad (sin chip por default, ofrecimiento de `/plan`) — ocurre necesariamente después del APPROVED de cierre, así que no puede ser condición de ese veredicto. Queda cubierto por el **OK humano terminal** (camino terminal del contrato: no hay 05 en IMPLEMENTATION que barra el cierre del 04): el RECAP terminal registra explícitamente el resultado del push junto a los commits de cierre listados como no-revisados-por-Codex, y el OK del humano es lo que cubre ambos.

## Decisiones

- 2026-07-28 (bajada): **Criterio de autonomía** para el aviso — push si la espera se alcanzó por trabajo autónomo, no si responde a un pedido directo del humano; reemplaza la condición de presencia ("humano no activo") que pedía adivinar, por una que se decide mirando el turno; en la duda, aviso. **Protocolo centralizado en `recap`** con referencias desde las otras skills — lección del r7 del ciclo 03: los restatements divergen. **Chip con prompt autocontenido** (solo `/feature` o `/plan`): el estado vive en los docs (principio 1), llevar contexto de chat en el chip lo violaría. **Sin cambios en scripts ni contrato**: las herramientas son del harness; el loop mecánico no cambia. **Sin tests automatizados**: el delta es lenguaje natural en skills; un grep sobre prosa sería frágil y falso — la verificación es el inventario de este doc contra las skills, en la review. **Caso terminal sin chip por default**: sin siguiente feature no hay comando obvio que spawnear; se ofrece `/plan` en el texto del RECAP.
- 2026-07-28 (ronda 2): **la procedencia manda incluso en el RECAP temprano** — un cambio de scope/sorpresa que surge del mensaje humano recién recibido produce un RECAP interactivo (sin aviso: el humano está ahí); la fila autónoma queda para lo que el propio loop detecta. **La aceptación post-APPROVED sale de los criterios de cierre**: el criterio 5 retiene solo la prueba del push dentro del rango (verificable por Codex al aprobar); el ejercicio terminal pasa a sección propia cubierta por el OK humano — Codex debe poder afirmar los cinco criterios al dar el APPROVED de cierre.
- 2026-07-28 (ronda 1): **el universo del inventario son las esperas de respuesta, de cualquier tipo** — incluye las interactivas (ping-pong de `/design`, decisiones de `/adopt`) clasificadas sin aviso por respuesta directa; `/status` sale del inventario porque no espera nada. **La fila RECAP de DESIGN se actualiza en su lugar** (refinada + remisión a `recap`), no se deja como antecedente con la formulación vieja viva; la línea de AGENTS/plantilla es referencia de alto nivel, no norma paralela. **Instrucción única parametrizada por el comando del cruce** y degradación que cubre también el fallo de invocación del chip. **Aceptación en dos planos**: prueba real del push dentro del rango revisado (paso de implementación, resultado en este doc) + ejercicio vivo post-APPROVED cubierto por el OK humano terminal — el criterio original era circular: el push del RECAP de cierre ocurre después del APPROVED que debía verificarlo.

## Riesgos

- **Las herramientas del harness varían por surface y versión** (nombres y disponibilidad de push/spawn): las skills nombran la capacidad con el nombre actual como ejemplo y siempre con degradación explícita; la ausencia de una herramienta jamás bloquea el loop ni se reporta como error.
- **El chip de spawn está pensado para tareas out-of-scope**, no para continuidad de fases: funcionalmente es lo pedido ("chip de spawn en desktop" — un click abre sesión propia con el prompt). Si en la práctica no encaja (p. ej. la sesión spawneada no queda utilizable como sesión del feature), el fallback es la instrucción única y el hallazgo se registra en este doc.
- **Prosa no verificable por suite**: mitigado con el inventario como checklist explícito para el reviewer (puede leer las seis skills en su worktree) y con la centralización, que reduce los puntos a mantener a uno.
- **El criterio de autonomía tiene bordes** (mensaje humano a mitad de loop): resuelto en la bajada — media ronda autónoma entre el mensaje y el RECAP ⇒ aviso; en la duda, aviso (asimetría de costos documentada).

## Verificación — resultados

- **Paso único de implementación** (2026-07-28): delta solo-prosa, según el mapa de "Docs afectados". Skill `recap`: sección nueva «Aviso al humano (protocolo único)» con el criterio de autonomía, los dos grupos de esperas, el borde, el formato de una línea y la degradación (ausencia o fallo ⇒ seguir sin aviso; autoritativo es STATUS.md); la condición vieja "si el humano no está activo" eliminada. Skill `feature`: camino esperando-OK con chip de spawn (título "Feature NN: <nombre> — sesión limpia", prompt únicamente `/feature`, tldr de una línea) + instrucción única + rama terminal (ofrecer `/plan`); paso 5 referencia a `recap` (la mención suelta de PushNotification eliminada); regla del RECAP temprano con la referencia. Skills `design`/`plan`: RECAP con referencia declarando solo la procedencia, continuidad hacia `/plan` y `/feature` con chip (título/prompt/tldr) o instrucción única, y la cláusula "todo RECAP sigue la skill `recap`" en sus reglas. Tras r4: las skills de fase no enuncian el resultado push/sin-push — solo procedencia y remisión. `AGENTS.md` + `templates/AGENTS.md`: línea idéntica en Convenciones (verificado por diff), referencia de alto nivel sin norma paralela. `DESIGN.md`: fila RECAP refinada en su lugar (sin "push si está disponible" residual). `scripts/`, `tests/`, contrato y skills `status`/`adopt`: intactos.
- **Prueba real del push (criterio 5)** (2026-07-28, en esta sesión): la herramienta `PushNotification` estaba deferred en el harness — cargada vía búsqueda de herramientas (un paso, sin fricción); invocación con el aviso de prueba "axel: prueba del protocolo de aviso (feature 04, dentro del rango de review) — no requiere acción" → respuesta de la herramienta: **"Mobile push requested."**. Lo observado prueba disponibilidad, carga e invocación **aceptada por el harness**; la entrega efectiva en el dispositivo no es observable desde la sesión y su garantía está expresamente fuera de alcance (el autoritativo es STATUS.md). Hallazgo documental — de la descripción de la herramienta, no observado en esta invocación: se auto-suprime cuando el humano está activo en la terminal y reporta "not sent" como resultado esperado, no como error — coherente con el criterio de autonomía y con la degradación silenciosa de la bajada.

## Review log

- **Ronda 5: APPROVED (cierre)** — los 4 puntos de r4 cerrados a juicio del reviewer: inventario aplicado (esperas autónomas alcanzan `recap`; interactivas solo declaran procedencia), protocolo centralizado (el resultado push/sin-push vive únicamente en `recap`), continuidad completa (tres chips con título/prompt exclusivo/tldr, fallback por ausencia/fallo, rama terminal sin chip), memoria sincronizada y evidencia del push acotada. Verificación independiente: `git diff --check`, `tests/lint.sh` y `tests/install.sh` (321 ok, 0 fail) limpios; archivos fuera de alcance intactos. **Los cinco criterios de cierre satisfechos** — APPROVED de cierre del feature 04; resta la aceptación terminal post-APPROVED bajo el OK humano. Base: `04b7212`. Convergencia del ciclo: bajada 5→2→0 (r1–r3), implementación 4→0 (r4–r5).
- **Ronda 4 (implementación): CHANGES_REQUESTED** (4 puntos, todos aceptados; el reviewer verificó línea de Convenciones idéntica, archivos fuera de alcance intactos, `git diff --check`, `tests/lint.sh` y `tests/install.sh` — 321 ok — en verde). Resolución:
  1. Restatements residuales en las skills de fase ("va push"/"sin push" junto a la referencia) contradecían la centralización → corregido: cada camino declara solo la **procedencia** (trabajo autónomo / respuesta directa) y remite a `recap`; el resultado push/sin-push se deriva únicamente allí.
  2. El chip omitía dos campos definidos por la bajada (título y tldr; las skills solo fijaban el prompt) → corregido: las tres transiciones especifican título ("Feature NN: <nombre> — sesión limpia" / "/plan — sesión limpia"), prompt únicamente el comando, y tldr de una línea.
  3. Memoria oficial desincronizada (IMPLEMENTATION aún "bajada fina en review"; el Review log sin la ronda 3) → corregido: fila 04 con bajada APPROVED (r3) e implementación en review; entrada de la ronda 3 con su convergencia 5→2→0.
  4. La evidencia del push sobreafirmaba ("entregando, de punta a punta") y mezclaba el hallazgo documental con lo observado → corregido: lo observado es disponibilidad, carga e invocación aceptada por el harness; la entrega no es observable y su garantía está fuera de alcance; la auto-supresión queda marcada como hallazgo documental de la descripción de la herramienta.
- **Ronda 3: APPROVED (bajada)** — los 2 puntos de r2 cerrados a juicio del reviewer: la procedencia del RECAP temprano quedó decidible y coherente (detección autónoma avisa; respuesta inmediata no), y la aceptación terminal quedó fuera de los cinco criterios de cierre — Codex puede verificarlos íntegramente antes del APPROVED, con el ejercicio posterior bajo el OK humano terminal. Verificó delta solo documental, archivos protegidos intactos, `git diff --check` y `tests/lint.sh` limpios. Base movida a `496d9bd`. Convergencia de la bajada: 5→2→0 (r1–r3). Habilita el paso único de implementación; no cierra el feature.
- **Ronda 2: CHANGES_REQUESTED** (2 puntos, ambos aceptados; convergiendo 5→2 — el reviewer dio por bien resueltos el bookkeeping y las correcciones de DESIGN/continuidad, y verificó delta solo-Markdown, archivos protegidos intactos, `git diff --check` y `tests/lint.sh` limpios). Resolución:
  1. El inventario contradecía su propio criterio ("cómo se llegó, no dónde"): la fila de RECAP temprano clasificaba "cambio de scope, sorpresa" siempre como autónoma, pero esos casos pueden ser la respuesta inmediata a un mensaje humano a mitad del loop → corregido: la fila autónoma queda para lo detectado por el propio loop, y las esperas interactivas ganan la rama del RECAP temprano disparado por el mensaje recién recibido.
  2. La circularidad del criterio 5 no estaba eliminada estructuralmente (el contrato exige que el APPROVED de cierre se dé contra los criterios, y el 5 incluía una acción post-APPROVED: Codex no podría afirmar los cinco al cerrar) → corregido: el criterio 5 retiene solo la prueba real del push dentro del rango; el ejercicio del RECAP terminal se mueve a la sección nueva «Aceptación terminal (post-APPROVED, fuera de los criterios de cierre)», cubierta por el OK humano y explícitamente no-condición del APPROVED.
- **Ronda 1: CHANGES_REQUESTED** (5 puntos, todos aceptados; el reviewer verificó además el bookkeeping del cierre del 03 contra su APPROVED de r8, que el rango es solo Markdown con scripts/skills/contrato intactos, y `git diff --check` + `tests/lint.sh` limpios). Resolución:
  1. IMPLEMENTATION desactualizada (fila 03 aún "esperando OK humano" pese a `3c0e410`; fila 04 en Backlog sin link pese a STATUS y la bajada ya existente — y la evidencia del pedido afirmaba un link que no estaba) → corregido: ambas filas al día (03 cerrado con OK; 04 en curso con link).
  2. El inventario no cumplía su propia promesa ("turnos que terminan esperando al humano"): faltaba el ping-pong de `/design`, y `/adopt` estaba mal agrupado con `/status` (que no espera nada) → corregido: universo definido explícitamente como esperas de respuesta de cualquier tipo, en dos grupos (autónomas con aviso / interactivas sin aviso, incluidas `/design` paso 1 y `/adopt`); `/status` fuera del universo con la razón.
  3. Contradicción residual en DESIGN ("push si está disponible" seguía vivo como "antecedente") → corregido: la fila RECAP se actualiza en su lugar (refinada por el criterio de autonomía, remite a `recap`); la línea de AGENTS/plantilla queda como referencia de alto nivel, no segunda norma.
  4. Continuidad internamente inconsistente (fallback fijado a `/feature` que no cubría diseño→`/plan`; criterio 3 exigía chip en "los cuatro cruces" contra el terminal-sin-chip del enfoque; degradación sin cubrir fallo de invocación) → corregido: instrucción única parametrizada por comando, criterio reformulado como tres transiciones con spawn + rama terminal sin spawn, degradación por ausencia y por fallo.
  5. Criterio de cierre 5 circular (el push del RECAP de cierre ocurre después del APPROVED que debía verificarlo, en commits terminales que Codex no revisa) → corregido: aceptación en dos planos — prueba real del push dentro del rango revisado (implementación, resultado en este doc) y ejercicio vivo post-APPROVED cubierto por el OK humano terminal, registrado en el RECAP.

## Cierre

Feature cerrado el 2026-07-28 con el APPROVED de Codex en la ronda 5. **Cierre terminal**: no queda feature siguiente en IMPLEMENTATION.md, así que no hay ciclo que barra este commit de cierre — queda cubierto por el OK humano del RECAP terminal, que lo lista como no-revisado-por-Codex (camino terminal del contrato). El cierre es bookkeeping puro (solo docs: esta sección, Review log r5, IMPLEMENTATION, STATUS). La aceptación terminal (push del RECAP de cierre y rama terminal de la continuidad: sin chip, ofrecimiento de `/plan`) se ejercita en el RECAP y su resultado queda registrado ahí, bajo el OK humano.
