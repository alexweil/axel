# 12 — Reporte de cierre de `/adopt`: inventario de archivos tocados

## Autorización

- **2026-07-29** — autorizado por el **gate de pipeline** de `/build` (no hay gate individual: el hijo de un pipeline no re-pide confirmación — contrato del modo hijo, skill `feature`). Pedido que lo originó, literal breve del bloque Gate: «Que la skill `/adopt` cierre reportándole al humano el **inventario completo de archivos que tocó**, no solo la narrativa de las decisiones que le parecieron importantes. […] Como mínimo el inventario completo de archivos tocados y qué se le hizo a cada uno (movido / fusionado / creado / borrado / editado), separando de forma visible **lo mecánico** (lo que el handoff mandaba) de **lo interpretativo** (texto que el agente escribió sobre el proyecto del humano y que conviene que ratifique). La forma exacta la decidís en el diseño.» Ledger de la corrida: [pipeline-2026-07-29-2.md](pipeline-2026-07-29-2.md) (transcripción completa del pedido en su bloque Gate y en la extensión del 2026-07-29 (pipeline 2) de [../IMPLEMENTATION.md](../IMPLEMENTATION.md)); resumen autorizado de esta unidad, ahí (§Ruta autorizada, «`12` — feature»).
- **Ajustes de alcance del gate, que mandan sobre esta bajada**: (a) el cambio queda **acotado a `/adopt`** —no se extiende a `recap`/`feature`/`design`/`plan`/`build`—, con la **condición** de que el mecanismo quede escrito de forma **reusable**, para que generalizarlo después sea adoptar un contrato y no reinventarlo; (b) la colisión `build/` del instalador queda **sin registrar** (ni implementada ni anotada). Extender el alcance a otras skills, o agregar el README público de axel o la colisión `build/`, es divergencia ⇒ corte.

## Alcance

`/adopt` cierra hoy sin ningún paso que exija reportar. El paso 6 dice «borrá `docs/ADOPTION.md`, actualizá `docs/STATUS.md` y commiteá» y la regla final remite los movimientos de archivos «al commit de cierre, visibles en el diff» — pero el humano no mira el diff: lee el mensaje con que la sesión termina el turno. El feature agrega ese paso y lo hace **derivado de git**, no de la memoria de la sesión.

Entregables:

- **Skill `adopt`** (payload, `.claude/skills/adopt/SKILL.md`): un **paso 7 de reporte** que termina el turno, y un bloque **«Reporte de cierre (contrato)»** con las tres reglas —derivación, completitud, clasificación— y el presupuesto de forma, escrito **genérico y autocontenido** para cumplir la condición de reusabilidad del gate (§5). Además, la **regla final** (hoy «Los movimientos de archivos van en el commit de cierre, visibles en el diff») deja de mandar la visibilidad al diff y apunta al reporte, conservando intacta su primera mitad («nada de lo preexistente se pisa sin decisión explícita del humano en esta sesión»).
- **`docs/DESIGN.md`**: fila de decisión del 2026-07-29 (como hicieron los features 05, 06 y 11).
- **`docs/IMPLEMENTATION.md`**: fila 12 al día con este doc enlazado. **`docs/STATUS.md`**: al día en cada commit, con el token de ronda del contrato.

**Fuera de alcance**:

- **Las otras skills que cierran con un mensaje al humano** (`recap`, `feature`, `design`, `plan`, `build`): el gate resolvió acotar. El contrato queda escrito para que adoptarlo mañana sea copiarlo/apuntarlo, no rediseñarlo (§5), pero **ninguna** de esas skills se toca.
- **`AGENTS.md` + `templates/AGENTS.md`**: **no acompañan**, con argumento explícito en §6 (el pedido pide decidirlo, no asumirlo). Criterio de cierre 5: su diff en el rango del feature debe quedar **vacío**.
- **Cambios ejecutables**: ninguno. No hay archivo nuevo de payload, así que `scripts/install.sh` y `tests/install.sh` no se tocan (§5); `scripts/review.sh`, `scripts/awake.sh` y `tests/` tampoco.
- **El instalador y el formato del handoff**: `docs/ADOPTION.md` lo escribe `scripts/install.sh` y su forma no cambia. La clasificación **consume** las tres secciones que ya genera (docs preexistentes, candidatos a mapear, pendientes mecánicos) sin pedirle nada nuevo.
- **La `description` de la skill**: intacta. Es trigger de ruteo (feature 09) y cuándo se invoca `/adopt` no cambia; tocarla movería comportamiento de despacho sin necesidad.
- **Un estado de espera nuevo**: el reporte **no** es un checkpoint. No entra «esperando ratificación» al vocabulario fijo de la línea «Esperando» del contrato ([../design/review-contract.md](../design/review-contract.md) §Reentrada, cinco esperas humanas) — §7.
- **La skill `recap`**: sin cambios. El protocolo de aviso ya clasifica las preguntas interactivas de `/adopt` como respuesta directa ⇒ sin push, y el reporte llega justo después de la última respuesta del humano (§7).

## Enfoque técnico

### 1. Qué falla hoy, con la evidencia re-verificada

La adopción de inquirylab (`/Users/alexweil/src/inquirylab`, commit `4908bfb`) tocó **8 entradas** y el reporte al humano habló de **3**. Re-verificado en el repo real:

```
$ git show --name-status -M 4908bfb
M  AGENTS.md
D  DESIGN.md
M  README.md
D  docs/ADOPTION.md
M  docs/DESIGN.md
M  docs/IMPLEMENTATION.md
M  docs/STATUS.md
R075  IMPLEMENTATION.md  docs/implementation/bitacora.md
```

**Precisión que la evidencia agrega** (y que refuerza el diagnóstico en vez de debilitarlo): el **cuerpo del commit** sí era completo — nombraba «README.md: punteros actualizados a docs/» y «AGENTS.md §Sobre este proyecto completado». O sea que la información existía en git y **el reporte al humano no la surfaceó**: se escribió desde la memoria de qué le pareció importante a la sesión, no desde lo que el commit tocó. Por eso el arreglo no es «acordate de contar mejor» sino **derivar el inventario del commit**: la completitud deja de depender del juicio de la corrida.

Las dos omisiones concretas del pedido quedan verificadas: `README.md` (6 ±: dos links reescritos a docs movidos, punteros nuevos a STATUS y AGENTS, y una fila de la tabla de mapa) **no se mencionó**; y `AGENTS.md` (18 ±) se subdeclaró como «un bloque *Disciplina propia del proyecto*» cuando el diff muestra **16 líneas nuevas** que redactan la sección «Sobre este proyecto» entera —qué es el proyecto, qué se construye, objetivo, alcance y fronteras— más esa subsección.

### 2. Derivación: de dónde sale el inventario

Un comando, sobre el commit de cierre:

```
git show --name-status -M <SHA del cierre>
```

- **`--name-status` da las dos cosas que el pedido exige**: la lista **completa** de paths y la **acción** de git por cada uno. `-M` activa la detección de renames, que es lo que hace que un movimiento aparezca como tal (`R075 IMPLEMENTATION.md docs/implementation/bitacora.md`) en vez de como un borrado y una creación sin relación.
- **Fuente declarada**: el reporte encabeza con el SHA y el comando. El humano puede re-correrlo y verificar el reporte en un paso; un reporte sin SHA es visiblemente incompleto. Esto es lo que hace auditable a la auditoría.
- **Magnitud, opcional**: si una línea gana claridad con el tamaño del cambio (`+131`, `−97`), se agrega; `--stat` es el segundo comando si la sesión lo quiere mirar. No es obligatorio y **no reemplaza** la descripción en palabras — `--stat` y `--name-status` no se combinan en una sola salida (el último formato gana), y el objetivo es una línea legible, no dos comandos.
- **El cierre es un commit normal sobre `main` lineal** (regla dura del método), así que `git show` muestra su diff completo — no hay caso de merge commit con diff vacío.

**Si el cierre quedó en más de un commit** (el humano pidió partirlo, un pendiente mecánico se commiteó antes, o la sesión se reabrió): el inventario cubre **la adopción entera**, con `git diff --name-status -M <base>..HEAD`, y el reporte **declara el rango y cuántos commits abarca**. Cómo se establece `<base>`, en orden:

1. Los commits que la propia sesión hizo, que tiene a la vista.
2. Si no puede establecerlos con certeza (sesión reabierta), la **frontera derivable de git**: el commit anterior al primero de la adopción es el que trajo el handoff — `git log --format=%H -- docs/ADOPTION.md | sed -n 2p` (el primero de esa lista es el cierre, que lo borra). Verificado en inquirylab: devuelve `846308f`, el commit del instalador. En ese caso el reporte **avisa** que el rango puede incluir commits ajenos: sobre-reportar declarado es aceptable, omitir no.

**Antes de reportar, `git status --porcelain` vacío.** Si quedó algo sin commitear, el reporte lo lista **aparte**, como pendiente — nunca lo omite. Es el mismo fail-closed del método: un inventario derivado del commit no puede hablar de lo que no entró en el commit, así que lo declara.

**Un archivo tocado y devuelto a su estado original no aparece** — correcto: el commit no lo cambió y no hay nada que ratificar. El inventario es de efectos, no de actividad.

### 3. Forma: una línea por entrada, dos bloques

**Una línea por entrada de `--name-status`.** Es la regla que resuelve el criterio (b) del pedido con exactitud aritmética: inquirylab ⇒ **8 entradas ⇒ 8 líneas**, que es el número que el propio pedido fijó como referencia. Cada línea trae: el path (los **dos**, si la entrada es un rename), la **acción** y media línea de qué cambió.

Vocabulario de acciones, mapeado a lo que git devuelve — el del pedido más el typechange, que `/adopt` produce de verdad al resolver el conflicto de `CLAUDE.md`:

| git | acción en el reporte |
|---|---|
| `A` | **creado** |
| `M` | **editado** (o **fusionado**, si recibió el contenido de otro archivo) |
| `D` | **borrado** (o el origen de un movimiento/fusión: la línea lo cruza con el destino) |
| `R<score>` | **movido** — un score < 100 se dice: movido **y editado** |
| `T` | **convertido a symlink** (el caso `CLAUDE.md` → `AGENTS.md`) |

**Dos bloques con título visible**, en este orden: **«Mecánico — lo que mandaba el handoff»** y **«Para que ratifiques — lo que escribí yo sobre tu proyecto»**. La separación es lo que el pedido pide «de forma visible», y el orden pone último lo que el humano tiene que mirar.

**Presupuesto**: el inventario primero; la narrativa de las decisiones difíciles puede ir **después** y en pocas líneas. Lo que el pedido prohíbe es que el relato **reemplace** al inventario, no que exista.

Así se ve la adopción de inquirylab bajo esta forma (esto es el caso R1 de la matriz, resuelto contra el commit real):

```
Inventario del cierre — 8 archivos · commit 4908bfb (`git show --name-status -M 4908bfb`)

Mecánico — lo que mandaba el handoff
- `docs/DESIGN.md` — editado: recibe el `DESIGN.md` de la raíz sobre la semilla vacía, contenido intacto (+131)
- `DESIGN.md` — borrado: su contenido pasó a `docs/DESIGN.md`
- `docs/implementation/bitacora.md` — movido desde `IMPLEMENTATION.md` y editado (R075): la bitácora se separa, entradas verbatim
- `docs/IMPLEMENTATION.md` — editado: queda la tabla de estado y los milestones (+367)
- `docs/ADOPTION.md` — borrado: handoff consumido

Para que ratifiques — lo que escribí yo sobre tu proyecto
- `AGENTS.md` — editado: redacté la sección «Sobre este proyecto» entera (qué es, qué se construye, objetivo, alcance y fronteras) más la subsección «Disciplina propia del proyecto»
- `docs/STATUS.md` — editado: derivé el estado real (Track G segunda vuelta; E4-v3 con pre-registro ratificado r9, esperando tu orden para correr e4v3-r1)
- `README.md` — editado: el handoff no lo nombraba; reescribí 2 links a los docs movidos, agregué punteros a STATUS y AGENTS, y edité una fila de la tabla de mapa
```

Ocho líneas de inventario, las dos omisiones del pedido visibles y `AGENTS.md` declarado por su **alcance real** en vez de como un bloque secundario.

### 4. Clasificación: una regla aplicable mirando el diff

El criterio (a) del pedido descarta el juicio libre de cada corrida, así que la asignación se decide con **dos preguntas** y un default:

1. **¿Lo mandaba el handoff?** — está listado en `docs/ADOPTION.md` (candidato a mapear, pendiente mecánico, doc canónico preexistente o faltante) o es la consecuencia forzada de una de esas operaciones.
2. **¿El cambio incluye prosa que la sesión redactó sobre el proyecto del humano?**

- **Mecánico** = (1) sí **y** (2) no: mover, renombrar o fusionar un candidato; `CLAUDE.md` → symlink con su contenido propio fusionado; permisos o `defaultMode` de `.claude/settings.json`; `.gitignore`; sembrar un canónico faltante; borrar `ADOPTION.md`.
- **Para que ratifiques** = todo lo demás, y **siempre** estos tres casos:
  - **(a) prosa nueva sobre el proyecto ajeno** — la sección «Sobre este proyecto» de `AGENTS.md` (paso 2) y el `STATUS.md` derivado (paso 4). Aunque el handoff los mande: lo que el handoff manda es *completarlos*; **el texto lo escribió la sesión**. Se declaran por su **alcance real**, no por su título — es exactamente la subdeclaración que el pedido señala.
  - **(b) archivos preexistentes del humano que el handoff no nombraba** y la sesión decidió tocar (típico: `README.md` con links a docs movidos). Que el cambio fuera necesario no lo vuelve mecánico: la decisión de editarlo fue de la sesión.
  - **(c) contenido preexistente que quedó modificado** en un movimiento o una fusión — no solo mudado de lugar (un `R` con score < 100 es la señal barata).
- **Archivo mixto**: una entrada con partes de las dos clases va **al bloque de ratificar**, y su línea nombra las dos. Es lo que mantiene «una línea por entrada» sin perder información (caso real: `AGENTS.md`, que fusiona `CLAUDE.md` *y* redacta «Sobre este proyecto»).
- **Default fail-closed: la duda va a ratificar.** Un archivo de más en ese bloque cuesta una línea que el humano lee; uno de menos es la ceguera que el feature existe para arreglar.

**El handoff se borra en el mismo commit del cierre** — y sigue legible: su contenido está en el diff de ese commit (la entrada `D`), recuperable con `git show <SHA>:docs/ADOPTION.md` desde el padre. Una sesión reabierta puede reconstruir la clasificación sin adivinar qué mandaba el handoff.

### 5. La condición de reusabilidad: contrato nombrado dentro de la skill

El gate acotó a `/adopt` **con la condición** de que el mecanismo quede escrito de forma reusable. Se cumple así: las tres reglas y el presupuesto viven en un bloque propio, **«Reporte de cierre (contrato)»**, redactado en términos genéricos —«un cierre que edita archivos del humano y termina el turno con un mensaje»— y **autocontenido**: quien mañana lo adopte en otra skill copia o apunta ese bloque y solo sustituye qué cuenta como «mandato» (en `/adopt`, el handoff). El paso 7 lo invoca; el contrato no repite el paso.

**Alternativas descartadas**, con el motivo:

- **Doc de payload nuevo** (p. ej. `docs/design/close-report.md`): obligaría a tocar las dos allowlists de `scripts/install.sh` (`PAYLOAD_SRC`/`PAYLOAD`) y las aserciones de `tests/install.sh` — superficie **ejecutable** que ni el plan ni la ruta autorizada previeron — para un contrato con **un solo consumidor**. El patrón de axel ante esto ya está fijado por el feature 11 (§3): canónica declarada + referencia, y se promueve a sede propia cuando aparece el segundo consumidor.
- **`AGENTS.md`**: es **semilla** (`SEED_SRC` de `scripts/install.sh`: se crea solo si falta y no se toca jamás después). Un contrato de maquinaria puesto ahí **no llegaría nunca** a los destinos ya instalados y quedaría viejo en silencio en todos ellos — precisamente el riesgo R7 que el feature 11 registró para su §Roles. La skill, en cambio, es payload: el re-run la actualiza.

### 6. `AGENTS.md` + `templates/AGENTS.md`: no acompañan (decisión argumentada)

La regla de sincronía de `AGENTS.md` obliga a mantener las dos copias al día «si tocás **el proceso o las reglas**». Acá no aplica, por tres razones:

1. **No hay nada que sincronizar**: `AGENTS.md` no describe los pasos internos de `/adopt`. Lo menciona dos veces —en el orden de ruteo («adopción sin cerrar (`docs/ADOPTION.md`) → `/adopt`») y en la lista de comandos explícitos— y ninguna de las dos cambia. Verificable por grep sobre ambos archivos.
2. **No cambia el proceso ni una regla dura**: el grafo de fases, los checkpoints, el loop de review y las reglas duras quedan idénticos. El feature agrega **un paso de reporte al final de una skill** y no crea checkpoint (§7).
3. **Ponerlo ahí sería peor**: `templates/AGENTS.md` es semilla intocable, así que el contrato quedaría desactualizado en todos los destinos ya instalados mientras la skill —payload— aplica otra cosa. Es el R7 del feature 11, evitable acá simplemente no metiéndolo en la semilla.

La decisión queda registrada en este doc y en la fila de `DESIGN.md`; el criterio de cierre 5 la verifica por diff vacío.

### 7. Lo que el reporte **no** es

- **No es un checkpoint.** No fija «esperando» nada, no pide un OK y no frena el flujo: `/adopt` ya pregunta al humano **en cada punto de juicio** (pasos 1–5, más la regla de que nada preexistente se pisa sin decisión explícita). El reporte es la **auditoría de cierre** de decisiones ya tomadas con él presente. Agregar una sexta espera humana al vocabulario fijo del contrato ([../design/review-contract.md](../design/review-contract.md) §Reentrada) sería cambiar el contrato de reentrada por un efecto que no se pidió.
- **No lleva push.** La sesión de `/adopt` es interactiva y el reporte llega justo después de la última respuesta del humano ⇒ respuesta directa ⇒ sin aviso, tal como la skill `recap` ya lo clasifica («preguntas interactivas de `/design` o `/adopt`»). Sin delta en `recap`.
- **No se persiste como doc.** Es un rendering de git, reproducible en cualquier momento con el comando que el propio reporte declara; nada se pierde. Persistirlo pediría además un commit **posterior** al cierre, cuyo inventario no podría incluirse en sí mismo. Lo que queda versionado es lo de siempre: el commit y su mensaje.
- **No reemplaza al cuerpo del commit** ni le impone formato. En inquirylab el mensaje ya era completo; el hueco estaba en el turno.

## Matriz R — reporte de cierre

Como en los features 08–11 no hay harness de despacho: el comportamiento lo ejecuta un modelo leyendo texto de skill. La verificación es esta matriz, y **cada fila debe resolverse contra el texto final de `.claude/skills/adopt/SKILL.md`**, sin apelar a este doc.

| # | Caso | Qué debe pasar | Dónde se resuelve |
|---|---|---|---|
| R1 | **Retrospectivo**: la adopción de inquirylab (`4908bfb`, 8 entradas) corrida con el texto nuevo | **8 líneas** de inventario; `README.md` y `AGENTS.md` presentes; `README.md` en «para que ratifiques» por (b); `AGENTS.md` declarado por su **alcance real** (la sección entera), no como bloque secundario | paso 7 (una línea por entrada) + contrato, regla 3 con sus casos (a) y (b) |
| R2 | La sesión está convencida de que solo importan 3 de los 8 archivos | Salen los **8**: la lista la produce el comando, no su juicio | contrato, reglas 1 y 2 («ninguna entrada puede faltar») |
| R3 | Rename detectado (`R075 IMPLEMENTATION.md docs/implementation/bitacora.md`) | **Una** línea con **los dos** paths, acción «movido **y editado**» (score < 100) | paso 7, tabla de acciones (`R<score>`) |
| R4 | Movimiento que git ve como `D` + `M` (`DESIGN.md` → `docs/DESIGN.md`, pisando la semilla) | **Dos** líneas, cruzadas entre sí (origen y destino se nombran) | paso 7, filas `D` y `M` de la tabla |
| R5 | Conflicto de `CLAUDE.md`: su contenido propio se fusiona en `AGENTS.md` y queda como symlink | `CLAUDE.md` como **convertido a symlink** (`T`) en mecánico; `AGENTS.md` en **ratificar** con las dos cosas en su línea (fusión + prosa nueva) | paso 7, fila `T` + regla del **archivo mixto** |
| R6 | Pendientes mecánicos del handoff: permisos de `.claude/settings.json`, `.gitignore` | Una línea cada uno en **mecánico** | contrato, regla 3 (lista de mecánico) |
| R7 | `docs/ADOPTION.md` borrado al consumirse | Línea en **mecánico**: «borrado: handoff consumido» | ídem |
| R8 | `README.md` del humano: el handoff no lo nombraba, pero sin editarlo quedaban links rotos | **Ratificar**, por (b) — necesario ≠ mecánico | contrato, regla 3, caso (b) |
| R9 | El cierre quedó en **más de un commit** | Inventario sobre el **rango**, con el rango y el conteo de commits **declarados** | paso 7, cláusula de rango |
| R10 | Al cerrar quedó algo **sin commitear** | Se declara **aparte** como pendiente; no se omite ni se mezcla con el inventario | paso 7, chequeo de `git status --porcelain` |
| R11 | Sesión reabierta que no puede establecer sus propios commits | Frontera derivable de git (`git log --format=%H -- docs/ADOPTION.md \| sed -n 2p`) y **aviso** de que el rango puede incluir commits ajenos | paso 7, cláusula de rango, punto 2 |
| R12 | Adopción de update, sin candidatos: solo un pendiente mecánico + STATUS derivado | Inventario corto (2–3 líneas), con el STATUS derivado en **ratificar** | contrato, presupuesto + regla 3 caso (a) |
| R13 | La sesión quiere contar las dos decisiones difíciles que tomó | Puede, **después** del inventario y en pocas líneas — el relato no lo reemplaza | contrato, presupuesto |
| R14 | Un archivo se tocó y se volvió a dejar como estaba | **No** aparece: el commit no lo cambió | paso 7 (el inventario es de lo que el commit tocó) |
| R15 | `/adopt` corre sin `docs/ADOPTION.md` | Informa que no hay adopción pendiente y **no toca nada**: no hay cierre, no hay reporte | línea de guarda de la skill, intacta |
| R16 | Mañana otra skill quiere el mismo cierre auditable | Adopta el bloque «Reporte de cierre (contrato)» tal como está —genérico y autocontenido— sustituyendo solo qué cuenta como mandato | bloque de contrato de la skill |

## Criterios de cierre

1. `.claude/skills/adopt/SKILL.md` tiene un **paso 7 de reporte** que: termina el turno; nombra el **comando exacto** (`git show --name-status -M <SHA>`, y `git diff --name-status -M <base>..HEAD` con rango declarado si fueron varios commits); exige el chequeo de `git status --porcelain` con lo no commiteado declarado aparte; fija **una línea por entrada** con path(s), acción del vocabulario de cinco filas (incluido `T` ⇒ symlink y el `R<score>` < 100 ⇒ movido y editado) y media línea de qué cambió; y fija los **dos bloques con título** en el orden mecánico → ratificar.
2. La skill trae el bloque **«Reporte de cierre (contrato)»** con las **tres reglas** (derivación con fuente declarada, completitud sin omisiones, clasificación) y el **presupuesto**, redactado **genérico y autocontenido** (R16), con la mención de que hoy su único consumidor es el paso 7.
3. La **clasificación** es aplicable mirando el diff: las **dos preguntas**, la lista de lo mecánico, los **tres casos** que siempre van a ratificar (prosa nueva sobre el proyecto ajeno declarada por su alcance real; archivo preexistente que el mandato no nombraba; contenido preexistente modificado en un movimiento o fusión), la regla del **archivo mixto** y el **default fail-closed** («la duda va a ratificar»). Más la nota de que el handoff, borrado en el cierre, sigue legible en el diff de ese commit.
4. La **regla final** de la skill ya no manda la visibilidad al diff —apunta al reporte— y **conserva** su primera mitad: nada de lo preexistente se pisa sin decisión explícita del humano en esta sesión.
5. **`AGENTS.md` y `templates/AGENTS.md` con diff vacío** en el rango del feature (`git diff <base> -- AGENTS.md templates/AGENTS.md`), y la decisión de que no acompañan argumentada en §6 de este doc.
6. **Matriz R resuelta entera** (las 16 filas) contra el texto final de la skill, sin apelar a este doc. R1 se resuelve además **contra el commit real** `4908bfb` de inquirylab: el inventario que el texto nuevo produce entra en **8 líneas** y contiene `README.md` y `AGENTS.md` con su alcance real. Es retrospectivo **e hipotético**: re-correr el instalador sobre inquirylab propaga la skill pero **no reabre** una adopción cerrada (`tests/install.sh` T5), así que el inventario real se verá en la próxima adopción.
7. **Presupuesto de legibilidad**: la skill queda **≤ 40 líneas** (hoy 19) — el criterio (b) del pedido aplica también al texto de la maquinaria: un paso que no se lee no se cumple.
8. **Sin cambios ejecutables**: `git diff <base> -- scripts/ tests/ templates/` **vacío**; las tres suites (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión.
9. `docs/DESIGN.md` suma la fila de decisión del 2026-07-29 con su «por qué» y el puntero a este doc; `docs/IMPLEMENTATION.md` tiene la fila 12 al día con este doc enlazado; `docs/STATUS.md` quedó al día en cada commit con el token de ronda del contrato.

## Riesgos

- **R1 — La clasificación la hace un modelo, no un tipo de dato.** Las dos preguntas se aplican leyendo el diff, y un caso raro puede caer del lado equivocado. Lo acota el **default fail-closed**: la duda va a «ratificar», cuyo costo es una línea de más. La **completitud**, que es lo que el pedido exige, no depende del juicio: la da el comando.
- **R2 — Rango sobre-inclusivo en el camino de reentrada** (R11): si el humano commiteó trabajo propio entre la instalación y el cierre, el rango derivado lo incluye. Se acepta declarándolo: el reporte avisa, y sobre-reportar es recuperable de un vistazo mientras omitir es la ceguera original.
- **R3 — El efecto no se ve hasta la próxima adopción real.** La skill es payload: llega a un destino al re-correr el instalador, y una adopción **ya cerrada no se reabre** (`tests/install.sh` T5). Inquirylab queda como caso retrospectivo hipotético; el pipeline lo dice en su ledger.
- **R4 — El contrato reusable vive dentro de `adopt`.** Si mañana otra skill lo adopta, hay que promoverlo o referenciarlo y podría divergir. Mitigación: bloque nombrado, genérico y autocontenido, más el patrón ya fijado por el feature 11 (canónica + referencia). Alternativa (payload propio) descartada por superficie ejecutable, §5.
- **R5 — Una línea por archivo no dice cuánto cambió por dentro.** Un cambio de 3 líneas y uno de 300 se ven parecidos. Mitigación: la media línea de descripción, la magnitud opcional y el SHA declarado, que lleva al diff en un comando. Es el precio deliberado del criterio (b).
- **R6 — Nada obliga mecánicamente a correr el comando**: es texto de skill interpretado por un modelo, el mismo régimen de los features 08–11. Lo acota que el paso nombre el comando exacto y que el reporte deba **declarar su fuente**: un reporte sin SHA ni conteo es visiblemente incompleto para el humano que lo lee, que es quien pidió el feature.

## Review log

(pendiente)
