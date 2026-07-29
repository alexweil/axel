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

**Si el cierre quedó en más de un commit** (el humano pidió partirlo, un pendiente mecánico se commiteó antes, o la sesión se reabrió): el inventario cubre **la adopción entera** y necesita **dos** comandos, porque un solo `git diff <base>..HEAD` muestra el **efecto neto entre extremos** y no la unión de lo tocado — un archivo modificado y después restaurado, o el path intermedio de un `A → B → C`, desaparecería sin que nadie lo note, que es exactamente la falla del criterio (a) que este feature existe para cerrar (defecto detectado en la r1 de esta bajada):

1. **Columna vertebral: la unión de paths tocados, con sus acciones y en orden cronológico** — `git log --reverse --format='commit %H' --name-status -M <base>..HEAD` (verificado en este repo: un bloque por commit, del más viejo al más nuevo, con el marcador que separa los bloques y hace derivable el conteo). Ningún path de esa unión puede faltar en el reporte. Los tres modificadores son necesarios y ninguno es decorativo:
   - **`--name-status`** y no `--name-only`: la unión tiene que conservar **qué se hizo** en cada paso, no solo el path (defecto de la r1, corregido en la r2).
   - **`--reverse`**: `git log` entrega del más nuevo al más viejo, así que sin él la secuencia sale **invertida** — «borrado y creado» donde fue «creado y borrado» (defecto de la r2, corregido en la r3).
   - **el marcador `commit %H`** y no `--format=`: sin él las entradas quedan planas, no se sabe dónde termina un commit y el **conteo de commits que el reporte debe declarar** no es derivable de la salida (ídem).
2. **Acción reportada: el efecto neto** — `git diff --name-status -M <base>..HEAD`. Consolidación: **una línea por path**; si el path aparece en el neto, la acción de la línea es la neta.
3. Un path que está en la **unión** y no en el **neto** lleva su línea igual, con **la secuencia que muestra el comando 1** —«creado y borrado», «editado y restaurado», «renombrado de entrada y de salida»— más la marca «sin efecto neto». Decir solo «tocado» no alcanza: el pedido exige **qué se le hizo** a cada archivo, y eso vale también para lo que no dejó rastro.

Y el reporte **declara el rango y cuántos commits abarca**. Cómo se establece `<base>`, en orden:

1. Los commits que la propia sesión hizo, que tiene a la vista.
2. Si no puede establecerlos con certeza (sesión reabierta), la **frontera derivable de git**: el commit anterior al primero de la adopción es el que trajo el handoff — `git log --format=%H -- docs/ADOPTION.md | sed -n 2p` (el primero de esa lista es el cierre, que lo borra). Verificado en inquirylab: devuelve `846308f`, el commit del instalador. En ese caso el reporte **avisa** que el rango puede incluir commits ajenos: sobre-reportar declarado es aceptable, omitir no.

**Antes de reportar, `git status --porcelain` vacío.** Si quedó algo sin commitear, el reporte lo lista **aparte**, como pendiente — nunca lo omite. Es el mismo fail-closed del método: un inventario derivado del commit no puede hablar de lo que no entró en el commit, así que lo declara.

**Un archivo tocado y devuelto a su estado original**: en un cierre de **un** commit no existe como caso (un commit *es* un diff neto: si no cambió nada, no hay entrada, y no hay nada que ratificar). En el camino de **rango** sí existe, y por eso aparece declarado por la regla 3 de arriba.

### 3. Forma: una línea por entrada, dos bloques

**Una línea por entrada de `--name-status`** (en el camino de rango, una por path de la unión). Es la regla que resuelve el criterio (b) del pedido con exactitud aritmética: inquirylab ⇒ **8 entradas ⇒ 8 líneas**, que es el número que el propio pedido fijó como referencia. Cada línea trae: el path (los **dos**, si la entrada es un rename), la **acción** y media línea de qué cambió.

Vocabulario de acciones, mapeado a lo que git devuelve — el del pedido más el typechange, que `/adopt` produce de verdad al resolver el conflicto de `CLAUDE.md`:

| git | acción en el reporte |
|---|---|
| `A` | **creado** |
| `M` | **editado** (o **fusionado**, si recibió el contenido de otro archivo) |
| `D` | **borrado** (o el origen de un movimiento/fusión: la línea lo cruza con el destino) |
| `R<score>` | **movido** — un score < 100 dice además **y editado**, y es la **señal para inspeccionar** el delta antes de clasificar (§4): el score no decide el bloque |
| `T` | **convertido a symlink** (el caso `CLAUDE.md` → `AGENTS.md`) |

**Dos bloques con título visible**, en este orden: **«Mecánico — lo que mandaba el handoff»** y **«Para que ratifiques — lo que escribí yo sobre tu proyecto»**. La separación es lo que el pedido pide «de forma visible», y el orden pone último lo que el humano tiene que mirar.

**Presupuesto**: el inventario primero; la narrativa de las decisiones difíciles puede ir **después** y en pocas líneas. Lo que el pedido prohíbe es que el relato **reemplace** al inventario, no que exista.

Así se ve la adopción de inquirylab bajo esta forma (esto es el caso R1 de la matriz, resuelto contra el commit real y contra el **handoff real**, leído en `4908bfb^:docs/ADOPTION.md`):

```
Inventario del cierre — 8 archivos · commit 4908bfb (`git show --name-status -M 4908bfb`)

Mecánico — lo que mandaba el handoff
- `DESIGN.md` — borrado: su contenido pasó a `docs/DESIGN.md`
- `docs/ADOPTION.md` — borrado: handoff consumido

Para que ratifiques — lo que escribí yo sobre tu proyecto
- `AGENTS.md` — editado (+17/−1): redacté la sección «Sobre este proyecto» entera (qué es, qué se construye, objetivo, alcance y fronteras) más la subsección «Disciplina propia del proyecto»
- `docs/STATUS.md` — editado (+10/−3): derivé el estado real (Track G segunda vuelta; E4-v3 con pre-registro ratificado r9, esperando tu orden para correr e4v3-r1)
- `README.md` — editado (+4/−2): es tu README, no un doc del método; reescribí la línea de guías con los links a los docs movidos, agregué punteros a STATUS y AGENTS, y edité la fila `docs/` de la tabla de mapa
- `docs/DESIGN.md` — editado (+116/−15): recibe el `DESIGN.md` de la raíz (cuerpo intacto, links reajustados) y le **agregué la §9 «Profundizaciones»**: índice de los 15 docs de `docs/` con una glosa mía por cada uno
- `docs/IMPLEMENTATION.md` — editado (+358/−9): recibe el plan de la raíz sin la bitácora, y le **agregué el párrafo «Sobre el vocabulario»** (cómo se relacionan «milestone» y «entrega» con el loop de axel)
- `docs/implementation/bitacora.md` — movido desde `IMPLEMENTATION.md` y editado (R075, +71/−361): entradas preexistentes verbatim, y **escribí una entrada nueva** (2026-07-29) que resume la adopción y cierra el hueco de trazabilidad de la segunda vuelta de Track G con punteros a cada experimento
```

Ocho líneas de inventario, las dos omisiones del pedido visibles y `AGENTS.md` declarado por su **alcance real** en vez de como un bloque secundario.

**Dos correcciones factuales que la r1 forzó, y que cambian el ejemplo** (estaban mal en la primera versión de esta bajada; se registran porque son la prueba de que la regla de clasificación tiene que ser verificable contra el diff y no contra el relato del commit):

1. El handoff **sí listaba `README.md`** entre sus 21 candidatos (verificado en `4908bfb^`), así que no puede clasificarse como «archivo que el handoff no nombraba». Va a ratificar por otra razón, la de §4 (b): no es uno de los cuatro docs canónicos ni vive en `docs/` — es el repo del humano, no la memoria del loop.
2. La bitácora **no** era una mudanza verbatim: el diff del rename trae una **entrada nueva escrita por la sesión**. El mensaje del commit decía «entradas verbatim» y era cierto de las preexistentes, pero el archivo ganó texto propio ⇒ ratificar por §4 (a). Lo mismo pasa con `docs/DESIGN.md` (§9 nueva) y `docs/IMPLEMENTATION.md` (párrafo nuevo): mudanzas mandadas por el handoff **con prosa agregada** por la sesión.

**El corolario incomoda y es el punto**: el reporte real habló de 3 archivos y «dos cosas que decidí yo», cuando **6 de los 8** llevaban texto que la sesión escribió sobre el proyecto ajeno. El split no está garantizado parejo —acá sale 2/6— y eso no es un defecto de la clasificación: **es el hallazgo**.

### 4. Clasificación: una regla aplicable mirando el diff

El criterio (a) del pedido descarta el juicio libre de cada corrida. «¿Lo mandaba el handoff?» **no alcanza** como pregunta discriminante —el scan del instalador lista como candidatos *todos* los `.md` de la raíz y de `docs/` (`scripts/install.sh`, bloque `CANDIDATES`: `find -maxdepth 1 -name '*.md'` más `docs/**/*.md`), así que en una adopción inicial casi todo lo preexistente viene mandado; en inquirylab fueron **21 candidatos**, `README.md` incluido—. Lo que decide es **qué le hizo la sesión al archivo**:

**Mecánico** — la operación que el handoff mandaba, ejecutada como la mandaba:

- mover, partir, renombrar o re-titular un candidato, y ajustar **links y punteros** que la mudanza rompe;
- los pendientes mecánicos que el handoff lista: `CLAUDE.md` → symlink con su contenido propio fusionado, permisos o `defaultMode` de `.claude/settings.json`, `.gitignore`;
- sembrar un doc canónico faltante; borrar `ADOPTION.md`.

**Para que ratifiques** — cualquiera de estas tres, y la duda:

- **(a) texto que interpreta el proyecto**: qué es, qué se está construyendo, en qué estado está, qué se decidió, qué falta, cómo se trabaja. Da igual que el handoff mandara *completar* la sección: **el texto lo escribió la sesión**. Se declara por su **alcance real**, no por su título — es exactamente la subdeclaración que el pedido señala. Casos reales de inquirylab: la sección «Sobre este proyecto» de `AGENTS.md`, el `STATUS.md` derivado, la entrada nueva de la bitácora, la §9 de `docs/DESIGN.md`, el párrafo «Sobre el vocabulario» de `docs/IMPLEMENTATION.md`.
- **(b) archivos fuera de la memoria del loop**: cualquier path que **no** sea uno de los cuatro canónicos (`AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`) ni viva bajo `docs/`, y que no sea un pendiente mecánico del handoff. Los canónicos y `docs/` son la memoria del método —el humano los va a leer como parte del proceso—; el resto del repo no, y una edición ahí conviene que la ratifique. Es un test **de path**, objetivo. Caso real: `README.md` de la raíz (que el handoff **sí** listaba: por eso el test no es «¿lo nombraba?»).
  **Excepción, cruzada con su destino** (r2): el **origen puro** de un movimiento o una fusión hacia la memoria del loop —una entrada `D`, o el lado viejo de un `R`, cuyo contenido quedó en un canónico o bajo `docs/` **en este mismo cierre** y sin edición propia de la sesión— es **mecánico**, y su línea nombra el destino. Caso real: `DESIGN.md` de la raíz ⇒ `docs/DESIGN.md`. Una **edición** o una **creación** fuera de la memoria del loop no entra en la excepción: va a ratificar.
- **(c) contenido preexistente que la sesión reescribió o resumió en lo que dice sobre el proyecto, su estado o sus decisiones** — no el que solo se mudó, se partió o se re-tituló, **ni el que cambió solo en su prosa de navegación o de rol del documento**: reescribir un párrafo «Rol de este documento» para reapuntar links es mecánico (r2). **Señal para inspeccionar** (no criterio vinculante): un `R` con score < 100, o una mudanza cuyas adiciones no son solo títulos, links y punteros. Se mira el delta: si hay prosa de la sesión sobre el proyecto, es (a); si es la mudanza y su navegación y nada más, es mecánico.
- **Archivo mixto**: una entrada con partes de las dos clases va **al bloque de ratificar**, y su línea nombra las dos. Es lo que mantiene «una línea por entrada» sin perder información (caso real: `docs/IMPLEMENTATION.md`, que recibe el plan del humano *y* gana un párrafo escrito por la sesión).
- **Default fail-closed: la duda va a ratificar.** Un archivo de más en ese bloque cuesta una línea que el humano lee; uno de menos es la ceguera que el feature existe para arreglar.

**Qué hace reproducible a la regla**: (b) es un test de path (con su única excepción, el origen puro de una mudanza); (a) y (c) se deciden mirando **las adiciones del diff** y preguntando una sola cosa — *¿este texto habla del proyecto, o habla de dónde están los documentos?* Prosa de navegación (títulos, links, punteros, notas de rol de un doc) es mecánica; prosa que describe el proyecto, su estado o sus decisiones es de ratificar.

El borde fino, resuelto explícitamente porque apareció en el caso real: **un índice de documentos es navegación** (mecánico), pero **una glosa que resume de qué trata cada documento habla del proyecto** (ratificar) — es la §9 «Profundizaciones» que la sesión le agregó a `docs/DESIGN.md` en inquirylab, con una descripción propia de cada track. Lo que queda afuera de estos bordes lo resuelve el default, no una discusión.

**El handoff se borra en el mismo commit del cierre** — y sigue legible: `git show <SHA>^:docs/ADOPTION.md` (con `^`: en `<SHA>` el archivo ya no existe y el comando falla), o el diff del propio commit, donde la entrada `D` lo trae completo. Una sesión reabierta reconstruye la clasificación sin adivinar qué mandaba el handoff.

### 5. La condición de reusabilidad: contrato nombrado dentro de la skill

El gate acotó a `/adopt` **con la condición** de que el mecanismo quede escrito de forma reusable. Se cumple así: las tres reglas y el presupuesto viven en un bloque propio, **«Reporte de cierre (contrato)»**, redactado en términos genéricos —«un cierre que edita archivos del humano y termina el turno con un mensaje»— y **autocontenido**: quien mañana lo adopte en otra skill copia o apunta ese bloque y solo sustituye qué cuenta como «mandato» (en `/adopt`, el handoff). El paso 7 lo invoca; el contrato no repite el paso.

**Alternativas descartadas**, con el motivo:

- **Doc de payload nuevo** (p. ej. `docs/design/close-report.md`): obligaría a tocar las dos allowlists de `scripts/install.sh` (`PAYLOAD_SRC`/`PAYLOAD`) y las aserciones de `tests/install.sh` — superficie **ejecutable** que ni el plan ni la ruta autorizada previeron — para un contrato con **un solo consumidor**. El patrón de axel ante esto ya está fijado por el feature 11 (§3): canónica declarada + referencia, y se promueve a sede propia cuando aparece el segundo consumidor.
- **`AGENTS.md`**: es **semilla** (`SEED_SRC` de `scripts/install.sh`: se crea solo si falta y no se toca jamás después). Un contrato de maquinaria puesto ahí **no llegaría nunca** a los destinos ya instalados y quedaría viejo en silencio en todos ellos — precisamente el riesgo R7 que el feature 11 registró para su §Roles. La skill, en cambio, es payload: el re-run la actualiza.

### 6. `AGENTS.md` + `templates/AGENTS.md`: no acompañan (decisión argumentada)

La regla de sincronía de `AGENTS.md` obliga a mantener las dos copias al día «si tocás **el proceso o las reglas**». Acá no aplica, por tres razones:

1. **Ninguna mención existente queda falsa ni incompleta.** El inventario real (grep, corregido en la r1 — la primera versión de esta bajada decía «dos menciones» y era falso):
   - **`AGENTS.md` (raíz), tres menciones, todas operativas y de ruteo**: el orden de despacho («adopción sin cerrar (`docs/ADOPTION.md`) → `/adopt`»), la lista de comandos explícitos, y la línea de puntos de confirmación («`/adopt`, pregunta cada punto de juicio»). **No** tiene entrada de fase para `/adopt`: la lista numerada de fases del método arranca en `/design`.
   - **`templates/AGENTS.md`, seis**: las tres de arriba, más el placeholder de «Sobre este proyecto» («Completar en `/adopt` o `/design`…»), la nota de precedencia («Si existe `docs/ADOPTION.md` … corré `/adopt` antes de cualquier otra fase») y —esta sí— una **entrada de fase**: «1. `/adopt` — solo si hay `docs/ADOPTION.md`: cerrar la adopción (mapear docs preexistentes, derivar el estado real) antes de todo lo demás».
   Ninguna enumera los pasos internos de la skill: la entrada de fase está a **altura de propósito y de orden** («qué fase es, cuándo corre, para qué»), no de procedimiento — a diferencia de la de `/feature`, que sí lista sus pasos («gate de arranque → bajada fina → review → implementación → RECAP → OK»). `/adopt` gana un paso de cierre; su propósito, su condición de disparo y su precedencia no cambian, así que las seis menciones siguen siendo **completas y verdaderas** sin nombrar el reporte. Agregarlo ahí sería detalle de procedimiento en un doc que deliberadamente no lo tiene para esta fase.
2. **No cambia el proceso ni una regla dura**: el grafo de fases, los checkpoints, el loop de review y las reglas duras quedan idénticos. El feature agrega **un paso de reporte al final de una skill** y no crea checkpoint (§7).
3. **Ponerlo ahí sería peor**: `templates/AGENTS.md` es semilla intocable, así que el contrato quedaría desactualizado en todos los destinos ya instalados mientras la skill —payload— aplica otra cosa. Es el R7 del feature 11, evitable acá simplemente no metiéndolo en la semilla.

La decisión queda registrada en este doc y en la fila de `DESIGN.md`; el criterio de cierre 5 la verifica por diff vacío.

### 7. Lo que el reporte **no** es

- **No es un checkpoint.** No fija «esperando» nada, no pide un OK y no frena el flujo: `/adopt` ya pregunta al humano **en cada punto de juicio** (pasos 1–5, más la regla de que nada preexistente se pisa sin decisión explícita). El reporte es la **auditoría de cierre** de decisiones ya tomadas con él presente. Agregar una sexta espera humana al vocabulario fijo del contrato ([../design/review-contract.md](../design/review-contract.md) §Reentrada) sería cambiar el contrato de reentrada por un efecto que no se pidió.
- **No lleva push.** La sesión de `/adopt` es interactiva y el reporte llega justo después de la última respuesta del humano ⇒ respuesta directa ⇒ sin aviso, tal como la skill `recap` ya lo clasifica («preguntas interactivas de `/design` o `/adopt`»). Sin delta en `recap`.
- **No se persiste como doc.** Es un rendering de git, reproducible en cualquier momento con el comando que el propio reporte declara; nada se pierde. Persistirlo pediría además un commit **posterior** al cierre, cuyo inventario no podría incluirse en sí mismo. Lo que queda versionado es lo de siempre: el commit y su mensaje.
- **No reemplaza al cuerpo del commit** ni le impone formato. En inquirylab el mensaje era sustancialmente completo —nombraba `README.md`, la sección de `AGENTS.md` y hasta la entrada nueva de la bitácora—: el hueco estaba en el turno, no en git.

## Matriz R — reporte de cierre

Como en los features 08–11 no hay harness de despacho: el comportamiento lo ejecuta un modelo leyendo texto de skill. La verificación es esta matriz, y **cada fila debe resolverse contra el texto final de `.claude/skills/adopt/SKILL.md`**, sin apelar a este doc.

| # | Caso | Qué debe pasar | Dónde se resuelve |
|---|---|---|---|
| R1 | **Retrospectivo**: la adopción de inquirylab (`4908bfb`, 8 entradas) corrida con el texto nuevo | **8 líneas** de inventario, con el split **2 mecánico / 6 ratificar** del §3: mecánico `DESIGN.md` y `docs/ADOPTION.md` (borrados puros); ratificar `AGENTS.md`, `docs/STATUS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md` y la bitácora por (a) —cada uno con la prosa que la sesión agregó, declarada por su alcance real— y `README.md` por (b) | paso 7 (una línea por entrada) + contrato, regla 3 con (a) y (b) |
| R2 | La sesión está convencida de que solo importan 3 de los 8 archivos | Salen los **8**: la lista la produce el comando, no su juicio | contrato, reglas 1 y 2 («ninguna entrada puede faltar») |
| R3 | Rename detectado con score < 100 y **prosa nueva** en el delta (el caso real: `R075 IMPLEMENTATION.md → docs/implementation/bitacora.md`, con una entrada escrita por la sesión) | **Una** línea con **los dos** paths, acción «movido **y editado**», y **bloque ratificar** por (a): el score dispara la inspección, la inspección encuentra prosa propia y **esa** decide | paso 7, fila `R<score>` (señal, no criterio) + contrato, regla 3, casos (a) y (c) |
| R3b | Delta que son **solo** título, links, punteros o una reescritura del párrafo «Rol de este documento» reajustada por la mudanza | **Mecánico** — es prosa de navegación, no de proyecto; el score se declara como inspeccionado. Vale igual para un `R` o para un `M` | contrato, regla 3: lista de mecánico + (c) «ni el que cambió solo en su prosa de navegación o de rol» |
| R3c | La sesión agrega un **índice de los otros docs**: solo la lista de paths, o la lista **con una glosa propia de qué trata cada uno** (caso real: §9 de `docs/DESIGN.md`) | Índice pelado ⇒ **mecánico** (navegación); índice **con glosas** ⇒ **ratificar** (habla del proyecto) | contrato, regla 3, borde explícito índice/glosa |
| R4 | Movimiento que git ve como `D` + `M` (`DESIGN.md` → `docs/DESIGN.md`, pisando la semilla) | **Dos** líneas cruzadas entre sí. El `D` es **mecánico** aunque el path esté fuera de la memoria del loop: es el **origen puro** de una mudanza hacia ella, la excepción de (b), y su línea nombra el destino. El destino va donde lo manden sus adiciones (en inquirylab, ratificar por la §9 nueva) | paso 7, filas `D` y `M` + contrato, regla 3, excepción de (b) |
| R5 | Conflicto de `CLAUDE.md`: su contenido propio se fusiona en `AGENTS.md` y queda como symlink | `CLAUDE.md` como **convertido a symlink** (`T`) en mecánico; `AGENTS.md` en **ratificar** con las dos cosas en su línea (fusión + prosa nueva) | paso 7, fila `T` + regla del **archivo mixto** |
| R6 | Pendientes mecánicos del handoff: permisos de `.claude/settings.json`, `.gitignore` | Una línea cada uno en **mecánico** | contrato, regla 3 (lista de mecánico) |
| R7 | `docs/ADOPTION.md` borrado al consumirse | Línea en **mecánico**: «borrado: handoff consumido» | ídem |
| R8 | `README.md` de la raíz: el handoff **sí** lo listaba entre sus candidatos, y sin editarlo quedaban links rotos | **Ratificar**, por (b): no es canónico ni vive en `docs/` — es el repo del humano. Que estuviera mandado y que el cambio fuera necesario **no** lo vuelve mecánico | contrato, regla 3, caso (b) — test de path |
| R8b | Archivo que el scan del handoff **no alcanza** (no es `.md` de la raíz ni de `docs/`: p. ej. `inquirybench/README.md`, un `Makefile`) y la sesión decidió tocar | **Ratificar**, por (b), por el mismo test de path | ídem |
| R9 | El cierre quedó en **más de un commit** | Inventario sobre el rango con **dos** comandos —unión de paths con sus acciones **en orden cronológico y con marcador de commit** (`git log --reverse --format='commit %H' --name-status -M`) como columna vertebral, y el efecto neto para la acción reportada—, consolidado a una línea por path, con el rango y el conteo de commits **declarados** (el conteo sale de los marcadores de la misma salida) | paso 7, cláusula de rango (reglas 1–3) |
| R10 | Al cerrar quedó algo **sin commitear** | Se declara **aparte** como pendiente; no se omite ni se mezcla con el inventario | paso 7, chequeo de `git status --porcelain` |
| R11 | Sesión reabierta que no puede establecer sus propios commits | Frontera derivable de git (`git log --format=%H -- docs/ADOPTION.md \| sed -n 2p`) y **aviso** de que el rango puede incluir commits ajenos | paso 7, cláusula de rango, punto 2 |
| R12 | Adopción de update, sin candidatos: solo un pendiente mecánico + STATUS derivado | Inventario corto (2–3 líneas), con el STATUS derivado en **ratificar** | contrato, presupuesto + regla 3 caso (a) |
| R13 | La sesión quiere contar las dos decisiones difíciles que tomó | Puede, **después** del inventario y en pocas líneas — el relato no lo reemplaza | contrato, presupuesto |
| R14 | Cierre de **un** commit: un archivo se tocó y se volvió a dejar como estaba | **No** aparece — dentro de un commit el caso no existe: un commit es un diff neto y no hay entrada que reportar (ni nada que ratificar) | paso 7: el inventario **son** las entradas de `git show --name-status`, y un archivo sin cambio neto no tiene entrada (no hace falta cláusula propia — atribución corregida al implementar) |
| R14b | Cierre de **varios** commits: un path tocado y restaurado, creado y borrado, o el path intermedio de un `A → B → C` | **Aparece igual**, y con **qué se le hizo, en el orden en que pasó**: la secuencia que muestra la unión cronológica («editado y restaurado», «creado y borrado», «renombrado de entrada y de salida») más la marca «sin efecto neto». Decir solo «tocado» no cumple, y decirlo al revés tampoco — por eso el comando lleva `--reverse` | paso 7, cláusula de rango, reglas 1 y 3 |
| R15 | `/adopt` corre sin `docs/ADOPTION.md` | Informa que no hay adopción pendiente y **no toca nada**: no hay cierre, no hay reporte | línea de guarda de la skill, intacta |
| R16 | Mañana otra skill quiere el mismo cierre auditable | Adopta el bloque «Reporte de cierre (contrato)» tal como está —genérico y autocontenido— sustituyendo solo qué cuenta como mandato | bloque de contrato de la skill |

## Criterios de cierre

1. `.claude/skills/adopt/SKILL.md` tiene un **paso 7 de reporte** que: termina el turno; nombra el **comando exacto** del caso normal (`git show --name-status -M <SHA>`) y los **dos** del camino de rango (unión de paths con sus acciones **en orden cronológico y con marcador de commit** vía `git log --reverse --format='commit %H' --name-status -M <base>..HEAD`, acción reportada vía `git diff --name-status -M <base>..HEAD`), con el rango y el conteo de commits declarados —derivable de los marcadores— y la línea obligatoria para un path de la unión **sin efecto neto**, que lleva **la secuencia intermedia en el orden en que pasó** y no un genérico «tocado»; exige el chequeo de `git status --porcelain` con lo no commiteado declarado aparte; fija **una línea por entrada** (o por path de la unión) con path(s), acción del vocabulario de cinco filas —`T` ⇒ symlink; `R<score>` < 100 ⇒ movido y editado, **como señal para inspeccionar y no como criterio de bloque**— y media línea de qué cambió; y fija los **dos bloques con título** en el orden mecánico → ratificar.
2. La skill trae el bloque **«Reporte de cierre (contrato)»** con las **tres reglas** (derivación con fuente declarada, completitud sin omisiones, clasificación) y el **presupuesto**, redactado **genérico y autocontenido** (R16), con la mención de que hoy su único consumidor es el paso 7.
3. La **clasificación** es aplicable mirando el diff: la lista de lo **mecánico** (mover/partir/re-titular un candidato con sus links y punteros; los pendientes mecánicos; sembrar un canónico; borrar el handoff), los **tres casos** que siempre van a ratificar —(a) texto que **interpreta el proyecto**, declarado por su alcance real; (b) **test de path**: fuera de los cuatro canónicos y de `docs/` y sin ser pendiente mecánico, **con la excepción del origen puro de una mudanza hacia la memoria del loop**, cruzado con su destino; (c) contenido preexistente reescrito o resumido **en lo que dice sobre el proyecto, su estado o sus decisiones** —no en su navegación ni en su nota de rol—, con el score < 100 como señal de inspección—, la regla del **archivo mixto**, el **default fail-closed** («la duda va a ratificar»), la pregunta que hace reproducible a (a)/(c) —*¿el texto nuevo habla del proyecto o de dónde están los documentos?*— y el borde **índice pelado vs. índice con glosas**. Más la nota de que el handoff, borrado en el cierre, sigue legible con `git show <SHA>^:docs/ADOPTION.md` o en el diff del propio commit. **Lo que la clasificación no puede usar** como discriminante: «¿lo nombraba el handoff?» — el scan lista todos los `.md` de la raíz y de `docs/`.
4. La **regla final** de la skill ya no manda la visibilidad al diff —apunta al reporte— y **conserva** su primera mitad: nada de lo preexistente se pisa sin decisión explícita del humano en esta sesión.
5. **`AGENTS.md` y `templates/AGENTS.md` con diff vacío** en el rango del feature (`git diff <base> -- AGENTS.md templates/AGENTS.md`), y la decisión de que no acompañan argumentada en §6 de este doc.
6. **Matriz R resuelta entera** (las **20** filas: R1–R16 más R3b, R3c, R8b y R14b) contra el texto final de la skill, sin apelar a este doc. R1 se resuelve además **contra el commit real** `4908bfb` de inquirylab y contra su **handoff real** (`4908bfb^:docs/ADOPTION.md`): el inventario que el texto nuevo produce entra en **8 líneas**, con el split 2 mecánico / 6 ratificar, y contiene `README.md` y `AGENTS.md` con su alcance real. Es retrospectivo **e hipotético**: re-correr el instalador sobre inquirylab propaga la skill pero **no reabre** una adopción cerrada (`tests/install.sh` T5), así que el inventario real se verá en la próxima adopción. **Conteo de filas, acotado a cada sección** —un `grep -c '^| R'` sobre el archivo entero devuelve **40**, porque las dos matrices tienen 20 filas cada una—: `awk '/^## Matriz R — reporte de cierre/,/^## Criterios de cierre/' <doc> | grep -c '^| R'` ⇒ 20 y `awk '/^### Matriz R resuelta contra el texto instalado/,/^### Verificación de los criterios mecánicos/' <doc> | grep -c '^| R'` ⇒ 20.
7. **Presupuesto de legibilidad**: la skill queda **≤ 40 líneas** — quedó en **39** (eran **19** antes del feature). El criterio (b) del pedido aplica también al texto de la maquinaria: un paso que no se lee no se cumple.
8. **Sin cambios ejecutables**: `git diff <base> -- scripts/ tests/ templates/` **vacío**; las tres suites (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión.
9. `docs/DESIGN.md` suma la fila de decisión del 2026-07-29 con su «por qué» y el puntero a este doc; `docs/IMPLEMENTATION.md` tiene la fila 12 al día con este doc enlazado; `docs/STATUS.md` quedó al día en cada commit con el token de ronda del contrato.

## Riesgos

- **R1 — La clasificación la hace un modelo, no un tipo de dato.** De los tres tests, (b) es objetivo (path); (a) y (c) exigen leer las adiciones del diff. **Riesgo demostrado, no teórico**: la primera versión de esta bajada clasificó mal dos archivos —`README.md` por una premisa falsa sobre el handoff y la bitácora por creerle al mensaje del commit en vez de al diff— y las dos las cazó la r1. Lo que lo hace aceptable es la asimetría: el **default fail-closed** manda la duda a «ratificar» (costo: una línea), y la **completitud** —lo que el pedido exige— no depende del juicio en ningún caso: la da el comando.
- **R2 — Rango sobre-inclusivo en el camino de reentrada** (R11): si el humano commiteó trabajo propio entre la instalación y el cierre, el rango derivado lo incluye. Se acepta declarándolo: el reporte avisa, y sobre-reportar es recuperable de un vistazo mientras omitir es la ceguera original.
- **R3 — El efecto no se ve hasta la próxima adopción real.** La skill es payload: llega a un destino al re-correr el instalador, y una adopción **ya cerrada no se reabre** (`tests/install.sh` T5). Inquirylab queda como caso retrospectivo hipotético; el pipeline lo dice en su ledger.
- **R4 — El contrato reusable vive dentro de `adopt`.** Si mañana otra skill lo adopta, hay que promoverlo o referenciarlo y podría divergir. Mitigación: bloque nombrado, genérico y autocontenido, más el patrón ya fijado por el feature 11 (canónica + referencia). Alternativa (payload propio) descartada por superficie ejecutable, §5.
- **R5 — Una línea por archivo no dice cuánto cambió por dentro.** Un cambio de 3 líneas y uno de 300 se ven parecidos. Mitigación: la media línea de descripción, la magnitud opcional y el SHA declarado, que lleva al diff en un comando. Es el precio deliberado del criterio (b).
- **R6 — Nada obliga mecánicamente a correr el comando**: es texto de skill interpretado por un modelo, el mismo régimen de los features 08–11. Lo acota que el paso nombre el comando exacto y que el reporte deba **declarar su fuente**: un reporte sin SHA ni conteo es visiblemente incompleto para el humano que lo lee, que es quien pidió el feature.

## Implementación (2026-07-29, paso único)

Dos sedes, ninguna ejecutable.

1. **`.claude/skills/adopt/SKILL.md`** (payload) — **cuatro** cambios, y nada más:
   - **Paso 7 nuevo**, «Reportar el inventario de lo que tocaste», con cuatro bullets: chequeo de `git status --porcelain` con lo no commiteado declarado aparte; derivación con `git show --name-status -M <SHA>` y encabezado con la fuente (`N archivos · commit <SHA>` + el comando); **una línea por entrada** con el vocabulario de cinco acciones —`A`/`M`/`D`/`R`/`T`, con «el score es señal, no criterio» escrito en la fila del rename—; y el **camino de rango** con sus dos comandos, el conteo derivable de los marcadores, la secuencia en el orden en que pasó para un path sin efecto neto, y el fallback de `<base>` con su aviso.
   - **Paso 6**: suma «**todo el cierre en un commit**», que es la precondición del camino normal del paso 7.
   - **Regla final**: conserva íntegra su primera mitad («nada de lo preexistente se pisa sin decisión explícita del humano en esta sesión») y su segunda mitad deja de mandar la visibilidad al diff — ahora los movimientos quedan «en el diff del commit de cierre **y en el reporte del paso 7**, que es donde el humano los ve».
   - **Sección nueva `## Reporte de cierre (contrato)`**, genérica y autocontenida: las tres reglas (derivación con fuente declarada, completitud, clasificación en dos bloques con título) y el presupuesto. Encabezado explícito de reusabilidad: «Vale para **cualquier** cierre que edite archivos del humano y termine el turno con un mensaje; hoy su único consumidor es el paso 7 de esta skill».
   - Y lo que **no** cambia, para que el conteo de cuatro sea verificable: la **`description`** (es trigger de ruteo del feature 09) y los **pasos 1–5**, literales.
2. **`docs/DESIGN.md`** — fila de decisión del 2026-07-29, después de la del feature 11.

### Matriz R resuelta contra el texto instalado

Las 20 filas, con el texto de `.claude/skills/adopt/SKILL.md` que las decide. Ninguna apela a este doc.

| # | Resuelta por | Texto que la decide |
|---|---|---|
| R1 | paso 7 + contrato, regla 3 | «**Una línea por entrada**» + los dos títulos de bloque + (a)/(b) ⇒ las 8 líneas y el split 2/6 del §3 |
| R2 | contrato, reglas 1–2 | «el inventario sale de **git**, nunca de tu memoria» · «la completitud la da el comando, no tu criterio» |
| R3 | paso 7, fila `R` + contrato (a) | «con score < 100, «movido **y editado**», y **mirá el delta** antes de clasificar: el score es señal, no criterio» |
| R3b | contrato, (c) | «ni el que cambió solo en su prosa de navegación o en su nota de rol» |
| R3c | contrato, pregunta que decide (a)/(c) | «Un índice **con glosas** de qué trata cada doc ya habla del proyecto» |
| R4 | paso 7, filas `D`/`M` + excepción de (b) | «el **origen puro** de un movimiento o fusión *hacia* esa memoria … es mecánico, y su línea **nombra el destino**» |
| R5 | paso 7, fila `T` + archivo mixto | «**convertido a symlink** (`T`)» · «Un archivo con partes de las dos clases va **al bloque de ratificar**, y su línea nombra las dos» |
| R6 | contrato, lista de mecánico | «los pendientes mecánicos (symlink de `CLAUDE.md`, permisos de `.claude/settings.json`, `.gitignore`)» |
| R7 | ídem | «borrar `ADOPTION.md`» |
| R8 | contrato, (b) | «todo archivo que no sea uno de los cuatro canónicos …, no viva bajo `docs/` y no sea un pendiente mecánico» + «el instalador lista como candidatos **todos** los `.md` de la raíz y de `docs/`» |
| R8b | ídem | el mismo test de path, que no depende de que el handoff lo nombrara |
| R9 | paso 7, bullet de rango | los dos comandos + «**declarás el rango y cuántos commits abarca** (los marcadores lo dan)» |
| R10 | paso 7, bullet 1 | «Verificá `git status --porcelain` **vacío** … listalo **aparte** como pendiente: no lo omitas» |
| R11 | paso 7, bullet de rango | «si no podés establecerlo, `git log --format=%H -- docs/ADOPTION.md \| sed -n 2p` es el del instalador — usalo avisando que el rango puede incluir commits ajenos» |
| R12 | contrato, presupuesto + (a) | «**una línea por entrada**» ⇒ inventario corto; el STATUS derivado entra por (a) |
| R13 | contrato, presupuesto | «la narrativa … **después** del inventario y en pocas líneas. El relato no reemplaza al inventario» |
| R14 | paso 7, derivación | el inventario **son** las entradas de `git show --name-status`: sin cambio neto no hay entrada |
| R14b | paso 7, bullet de rango | «con la secuencia **en el orden en que pasó** … y la marca «sin efecto neto»» |
| R15 | guarda, línea 8 (intacta) | «Si **no existe** `docs/ADOPTION.md`: informá que no hay adopción pendiente y no toques nada» |
| R16 | encabezado del contrato | «Vale para **cualquier** cierre que edite archivos del humano … hoy su único consumidor es el paso 7 de esta skill» |

### Verificación de los criterios mecánicos

- **C5** — `git diff bcf34f3 -- AGENTS.md templates/`: **vacío**. La decisión de §6 se cumple en el diff, no solo en el argumento.
- **C7** — `wc -l .claude/skills/adopt/SKILL.md`: **39 líneas** (≤ 40; eran 19). El paso 7 y el contrato suman 20 líneas y los pasos 1–5 quedan intactos.
- **C8** — `git diff bcf34f3 -- scripts/ tests/`: **vacío**. Las tres suites como no-regresión: `tests/lint.sh` limpio (shellcheck 0.11.0), `tests/loop.sh` **293 ok · 0 fail**, `tests/install.sh` **460 ok · 0 fail**. (El conteo de `loop.sh` en el sandbox del reviewer da 287 porque ahí se saltea la clase L5 — causa cerrada en la r5 del feature 11.)
- **C6** — matriz resuelta arriba. Conteos **acotados a cada sección**, porque desde que existen las dos tablas un `grep -c '^| R'` sobre el archivo entero devuelve **40** y no 20 (evidencia corregida en la r5): `awk '/^## Matriz R — reporte de cierre/,/^## Criterios de cierre/' <doc> | grep -c '^| R'` ⇒ **20** (matriz de casos) y `awk '/^### Matriz R resuelta contra el texto instalado/,/^### Verificación de los criterios mecánicos/' <doc> | grep -c '^| R'` ⇒ **20** (matriz resuelta). Las dos tablas tienen las mismas 20 filas, que es lo que el criterio exige.

## Review log

### r1 (base `bcf34f3`, HEAD `9412edb`) — CHANGES_REQUESTED · 5 puntos, los 5 aceptados

Codex dio por buenas las dos decisiones estructurales —la sede reusable dentro de `adopt` para un único consumidor, y el vocabulario `A/M/D/R/T` como cobertura de las operaciones reales de la skill— y verificó por su cuenta `loop.sh` 287/0, `install.sh` 460/0, lint y `git diff --check` limpios. Los cinco puntos, todos verificados por mí antes de aceptar; **dos tumbaron clasificaciones factuales del ejemplo retrospectivo**, que es exactamente el tipo de error que el feature existe para prevenir:

1. **Inconsistencia factual en el cierre previo** (barrido de los commits de cierre de la unidad `plan`, que este ciclo cubre por contrato): la extensión del pipeline 2 en `IMPLEMENTATION.md` decía «cinco pedidos» y enumeraba siete (cinco en r1, dos en r2), como bien dice el ledger. **Aceptado**: corregido a «siete pedidos —cinco en la r1 y dos en la r2—».
2. **El camino multicommit podía omitir archivos en silencio.** Cierto y grave: `git diff <base>..HEAD` es el **efecto neto entre extremos**, no la unión de lo tocado — un archivo modificado y restaurado, o el path intermedio de un `A → B → C`, desaparecía sin dejar rastro, que es justo la falla del criterio (a). **Aceptado con la primera de las dos salidas que ofreció** (derivar la unión, no limitarse a efectos netos): el camino de rango pasa a **dos comandos** —unión de paths (`git log --format= --name-only -M`, verificado en este repo) como columna vertebral y `--name-status` neto para la acción—, con línea obligatoria «tocado, sin efecto neto (paso intermedio)» para lo que está en la unión y no en el neto. Alineados R9, R14 (queda acotado al cierre de **un** commit, donde el caso no existe), la nueva R14b y el criterio 1.
3. **El caso retrospectivo clasificaba `README.md` sobre una premisa falsa.** Verificado en `4908bfb^:docs/ADOPTION.md`: el handoff **sí** lo listaba, entre **21 candidatos** —y el scan del instalador lista todos los `.md` de la raíz y de `docs/`, así que «¿lo nombraba el handoff?» no discrimina nada en una adopción inicial—. **Aceptado**: el caso (b) se redefine como **test de path** (fuera de los cuatro canónicos y de `docs/`, sin ser pendiente mecánico) con su razón —la memoria del loop vs. el resto del repo del humano—, `README.md` queda en ratificar por ese test, R8 se reescribe y se suma R8b. Corregido también `git show <SHA>:docs/ADOPTION.md` ⇒ **`<SHA>^:`** (en el commit del cierre el archivo ya no existe).
4. **La clasificación no era reproducible en un caso central.** El `R075` de la bitácora estaba en «Mecánico» mientras la regla (c) mandaba a ratificar todo contenido preexistente modificado. Fui a ver el diff real y el reviewer tenía razón por una razón más fuerte que la que planteó: el rename **contiene una entrada nueva escrita por la sesión** (2026-07-29, resumen de la adopción y del hueco de trazabilidad de Track G) — y lo mismo pasa con `docs/DESIGN.md` (§9 «Profundizaciones» nueva) y `docs/IMPLEMENTATION.md` (párrafo «Sobre el vocabulario» nuevo). **Aceptado**: (c) se reformula a «contenido que la sesión **reescribió o resumió**, no el que solo se mudó, se partió o se re-tituló», el score < 100 queda como **señal para inspeccionar y no criterio vinculante**, R3/R4 declaran el bloque esperado y se suma R3b. El ejemplo retrospectivo se corrige entero: el split real es **2 mecánico / 6 ratificar**, y ese corolario —el reporte original habló de 3 archivos y 2 decisiones cuando 6 de 8 llevaban texto propio— pasa a ser parte del hallazgo.
5. **El argumento factual de §6 era falso** aunque la decisión se sostenga: no son «dos menciones». **Aceptado**: inventario real por grep — `AGENTS.md` tiene **tres** menciones operativas y **ninguna** entrada de fase (la lista de fases arranca en `/design`); `templates/AGENTS.md` tiene **seis**, incluida una **entrada de fase**. El argumento se reescribe sobre la altura del texto: ninguna de las seis enumera pasos internos —la entrada de fase está a altura de propósito y orden, a diferencia de la de `/feature`, que sí lista los suyos—, así que ninguna queda falsa ni incompleta al agregar un paso de cierre, y meter procedimiento en la semilla reintroduciría el R7 del feature 11.

### r2 (base `bcf34f3`, HEAD `f85a033`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

Codex dio por incorporadas las cinco correcciones de la r1 y verificó 19 filas, árbol y `git diff --check` limpios, lint limpio y diff vacío de `AGENTS.md`, `templates/`, `scripts/`, `tests/` y `docs/DESIGN.md`. Los tres puntos nuevos son **consecuencias de las correcciones de la r1**: cada arreglo dejó un borde sin cerrar.

1. **La unión garantizaba los paths pero perdía la acción.** `--name-only` vuelve indistinguibles «editado y restaurado», «creado y borrado» y «renombrado de entrada y de salida»: todos terminaban como «tocado, sin efecto neto», y eso no cumple el «qué se le hizo a cada archivo» del pedido. **Aceptado** con la primera salida que ofreció: la unión pasa a `git log --format= --name-status -M <base>..HEAD` (verificado: imprime un bloque por commit, consolidable por path), la línea de un path sin efecto neto lleva **la secuencia intermedia** en vez de un genérico, y quedan alineados R9, R14b y el criterio 1.
2. **El test de path (b) contradecía su propio caso R1**: `DESIGN.md` de la raíz no es canónico ni vive en `docs/`, así que la regla lo mandaba a ratificar mientras el ejemplo, R1 y R4 lo clasificaban como origen mecánico de la mudanza. Contradicción real. **Aceptado** con la excepción que propuso, escrita con su límite: el **origen puro** de un movimiento o fusión hacia la memoria del loop —`D`, o el lado viejo de un `R`, sin edición propia y con el contenido aterrizando en un canónico o en `docs/` en el mismo cierre— es mecánico y su línea **nombra el destino**; una edición o una creación fuera de la memoria del loop **no** entra en la excepción.
3. **El límite entre (c) y navegación admitía dos resultados.** Una reescritura del párrafo «Rol de este documento» satisfacía a la vez «contenido preexistente reescrito» ⇒ ratificar y «prosa de navegación» ⇒ mecánico — y es un caso frecuente, no un borde raro. **Aceptado**: (c) queda acotado a reescritura o resumen **de lo que el contenido dice sobre el proyecto, su estado o sus decisiones**, con la reescritura de navegación o de rol declarada mecánica; R3b lo cubre explícitamente y se suma **R3c** para el borde que el caso real trajo — un índice de documentos es navegación, un índice **con glosas** de qué trata cada uno habla del proyecto. Matriz a **20** filas.

### r3 (base `bcf34f3`, HEAD `59ed016`) — CHANGES_REQUESTED · 1 punto, aceptado

**Las tres correcciones de clasificación quedaron cerradas** según el reviewer: la excepción de origen puro está acotada, **las ocho líneas del ejemplo se derivan de §4** (la verificación que más me importaba pedir) y la matriz contiene sus 20 casos, con STATUS y `git diff --check` limpios. Queda un solo punto, y es de la mecánica del comando:

1. **El camino multicommit no producía la secuencia que promete.** `git log --format= --name-status -M` entrega los commits **del más nuevo al más viejo** y `--format=` borra encabezados y separadores. Dos consecuencias, las dos verificadas en mi propia evidencia de la r2 sin que las viera: el archivo de esta bajada aparecía como `M, M, A` cuando su secuencia real es `A, M, M` —así R14b podía informar «borrado y creado» donde fue «creado y borrado»—, y las entradas quedaban planas, sin forma de derivar el **conteo de commits** que el reporte debe declarar. **Aceptado**, con el comando que propuso: `git log --reverse --format='commit %H' --name-status -M <base>..HEAD` (verificado: seis bloques cronológicos con marcador, conteo derivable con `grep -c '^commit '`). §2 queda con los **tres** modificadores justificados uno por uno —`--name-status` (r2), `--reverse` y el marcador (r3)—, para que una relectura futura no los tome por decorativos y los pierda; alineados R9, R14b y el criterio 1.

### r4 (base `bcf34f3`, HEAD `6f2c04a`) — **APPROVED de la bajada**

Sin observaciones accionables: «El comando nuevo produce bloques cronológicos, conserva `A → M → M` y permite derivar el conteo. §2, R9, R14b y el criterio 1 quedaron alineados; el comando anterior solo aparece en el historial explicativo de review» y «la matriz mantiene 20 filas coherentes … no hay cambios fuera del alcance autorizado». Con esto arranca la implementación (un paso, dos sedes). *(Entrada agregada en la r5: el Review log terminaba en la r3 y omitía esta transición, de la que ya dependían STATUS e IMPLEMENTATION — punto 3 de esa ronda.)*

**Cuatro rondas de bajada, todas convergentes**: 5 → 3 → 1 → 0 puntos, **los nueve aceptados sin argumentar**. La sustancia (derivar de git, dos bloques, alcance acotado, contrato reusable, `AGENTS.md` sin acompañar) no se discutió en ninguna; lo que costó cuatro rondas fue hacer la regla **reproducible** y el comando **correcto** — dos clasificaciones factuales mías estaban mal (r1), cada arreglo abría un borde nuevo (r2, r3) y el comando de unión invertía la secuencia y no permitía derivar el conteo (r3).

### r5 (base `6f2c04a`, HEAD `15251b7`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

Primera ronda sobre la **implementación**. El reviewer la dio por buena en lo sustantivo —«la implementación funcional sí cumple C1–C4 y C7; **las 20 filas y el caso retrospectivo 2/6 se resuelven desde la skill**»— con lint, `loop.sh`, `install.sh`, `git diff --check` y los negativos de alcance limpios. Los tres puntos son defectos de **bookkeeping de este doc**, ninguno del texto de la skill:

1. **La evidencia de C6 quedó falsa al agregar la segunda tabla**: `grep -c '^| R'` sobre el archivo devuelve **40**, no 20, porque ahora hay dos matrices de 20 filas. **Aceptado**: la evidencia pasa a **conteos acotados a cada sección** (con `awk` de rango + `grep -c`), con los dos resultados registrados y la razón del 40 explicada, para que la próxima relectura no la lea como regresión.
2. **«Tres cambios» que enumeraban cuatro** (paso 7, paso 6, regla final, contrato). **Aceptado**: corregido a **cuatro**, y el bullet de cierre pasa a decir explícitamente qué **no** cambia (`description` y pasos 1–5) para que el conteo sea verificable contra el diff.
3. **El Review log omitía el `APPROVED` de la r4**, del que STATUS e IMPLEMENTATION ya dependían. **Aceptado**: entrada de la r4 agregada —con la nota de que se agregó en esta ronda— y ubicada **dentro** del Review log, después de la r3. La memoria persistente del feature queda completa antes de registrar la ronda de implementación.

### r6 (base `6f2c04a`, HEAD `aa1d4ea`) — CHANGES_REQUESTED · 2 puntos, los 2 aceptados

El reviewer dio por corregidos los tres de la r5 y por cumplidos **C1–C5, C8 y C9**, con la skill idéntica, las matrices en 20/20 y el Review log ordenado. Los dos puntos son el **bloque normativo** de criterios, que había quedado desincronizado de su propia evidencia — el mismo tipo de defecto que el feature busca eliminar del cierre de `/adopt`, esta vez en la memoria del feature:

1. **C6 seguía contradiciéndose**: el criterio decía que las 20 filas se verifican con `grep -c '^| R'`, comando que devuelve **40** desde que existen las dos matrices. Estaba corregido en la evidencia (§Verificación) pero no en el criterio. **Aceptado**: el criterio 6 lleva ahora los mismos **conteos acotados por sección**, con la razón del 40 escrita en la línea.
2. **C7 conservaba un valor pre-implementación** («hoy 19») cuando la skill instalada tiene **39**. **Aceptado**: el criterio queda «≤ 40 líneas — quedó en **39** (eran **19** antes del feature)», que es a la vez el criterio y su valor verificado.
