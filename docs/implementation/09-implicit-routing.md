# 09 — Ruteo implícito: triggers y despacho por contexto

## Autorización

- **2026-07-29** — autorizado por el **gate de lote** de `/feature all` (features 08, 09, 10), sin exclusiones ni correcciones de alcance. Ledger de la corrida: [batch-2026-07-29.md](batch-2026-07-29.md); resumen autorizado del 09, ahí. No hay gate individual: el hijo de un lote no re-pide confirmación (contrato del modo lote, skill `feature`).

## Alcance

Nivel 1 del diseño de entrada implícita ([design/implicit-entry.md](../design/implicit-entry.md), §«Nivel 1 — ruteo implícito»): que un pedido en lenguaje natural, **sin comando**, se despache a la fase correcta — sin maquinaria nueva y sin arrancar trabajo sin un punto de confirmación. El feature 08 dejó el inventario de reentradas completo, que es a donde el ruteo entrega todo pedido que llega con estado pendiente.

Entregables:

- **Descripciones-trigger** en las **seis** skills (`design`, `plan`, `feature`, `status`, `recap`, `adopt`): la `description` deja de nombrar solo la fase y pasa a decir **cuándo dispararse por contexto**, conservando el nombre de la fase (es lo que el humano lee en el listado). Es el mecanismo estándar de skills — lo único que el modelo ve antes de elegir — y es **payload**: viaja a todo destino con el re-run del instalador.
- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): sección **§Ruteo** con el orden de despacho contractual fail-closed (4 pasos), la regla de confirmación, el **interinato multifase**, el ruteo al modo lote y el «qué no hace el ruteo». Más la **corrección de la línea de `/recap`**, que hoy lo presenta junto a `/status` como «consulta … no cambian el trabajo»: su skill fija «esperando OK», commitea y frena el turno.
- **Guarda de entrada** en `design`, `plan`, `feature` y **`recap`** (§3): unas pocas líneas por skill que hacen valer «estado pendiente manda» **desde el payload**, aunque la sección de `AGENTS.md` falte. Es la respuesta al hallazgo de r1 del feature 08 — `AGENTS.md` es **semilla** del instalador, así que nada load-bearing puede depender solo de él. `recap` entra porque es la otra skill que **muta estado** al dispararse (r1 p1).
- **Confirmación liviana de `/plan` despachado** (§4): `/plan` es la única fase sin gate propio; cuando llega por ruteo anuncia su interpretación, **la persiste en STATUS** y espera confirmación antes de escribir, con re-presentación al reabrir. La invocación explícita directa no cambia.
- **`docs/design/review-contract.md`**: el vocabulario de la línea «Esperando» (fijado por el 08) gana el literal **«esperando confirmación de plan»** como cuarta espera humana — es payload, así que la persistencia de §4 viaja completa a los destinos.
- **`tests/loop.sh`**: una línea de higiene del arnés — neutralizar los `AXEL_REVIEW_*` heredados del entorno (§8). Sin ella, la suite corrida **desde adentro de una review de lote** hereda `AXEL_REVIEW_ID` y falla el caso L10, que es exactamente el escenario en que el reviewer la corre; el criterio de cierre 7 no es verificable si su resultado depende del entorno.
- **`docs/IMPLEMENTATION.md`**: fila 09 al día. **`docs/STATUS.md`**: al día en cada commit, con el token de ronda del contrato.

**Fuera de alcance**:

- **`/build` y el pipeline** (feature 10). Este feature deja el destino multifase resuelto por un **interinato** explícito que el 10 reemplaza (declarado en su superficie).
- **Código ejecutable y superficie del instalador**: cero archivos nuevos ⇒ `scripts/install.sh` y su allowlist **no cambian** (las seis skills, `templates/AGENTS.md` y `docs/design/review-contract.md` ya están; la skill `build` y su entrada en la allowlist son alcance declarado del 10). Sin cambios en `scripts/review.sh` ni en `scripts/awake.sh`. El único cambio ejecutable es la higiene del arnés de tests declarada arriba, que no toca la maquinaria.
- **Las reentradas** (feature 08, ya cerrado): el ruteo **entrega** a ellas, no las redefine. Ninguna rama de reentrada se toca acá.
- **El token de la línea de ronda y los cinco literales que el 08 fijó**: no se tocan — son exactamente lo que el ruteo lee. La única adición es el literal de §4, que este feature crea.
- **`/adopt` y `/status` como cuerpos de skill**: solo cambia su `description`, y no necesitan guarda (§3): `status` no muta nada, y `adopt` solo actúa si existe `docs/ADOPTION.md` —su precondición **es** el paso 1 del orden de despacho— y pregunta cada punto de juicio.

## Enfoque técnico

### 1. Las tres capas del ruteo (y por qué la garantía no vive en la semilla)

El diseño fija dos piezas: descripciones-trigger y sección de ruteo en `AGENTS.md`. La bajada agrega una tercera por una razón concreta: **`AGENTS.md` es semilla, no payload** — el instalador la crea si falta y **no la pisa jamás** después (`SEED_SRC`/`SEED_DEST` en `scripts/install.sh`). Un proyecto instalado antes de este feature no recibe la sección al actualizar la maquinaria. El reparto queda así:

| Capa | Dónde | Qué aporta | ¿Viaja al actualizar? |
|---|---|---|---|
| **Trigger** | `description` de las 6 skills | Que un pedido sin comando **elija** una skill. Es lo único que el modelo ve antes de decidir. | **Sí** (payload) |
| **Orden** | `AGENTS.md` §Ruteo (+ espejo en la plantilla) | Que la elección sea **correcta a la primera**: precedencia de consulta y de estado pendiente, clasificación por lo que el pedido necesita, ambigüedad, interinato, lote. | Solo en instalaciones nuevas (semilla) |
| **Guarda** | `design`, `plan`, `feature`, `recap` (cuerpo de la skill) | Que una elección **errada** no mute estado: las cuatro skills que escriben (docs, STATUS, commits) miran STATUS al entrar y entregan a la dueña sin tocar nada. | **Sí** (payload) |

La capa de orden es la que hace el ruteo bueno; la capa de guarda es la que lo hace **seguro**. Sin la sección (proyecto viejo), un pedido igual dispara una skill por su trigger, y si el estado pendiente pertenece a otra fase la guarda lo entrega en vez de pisarlo: se degrada la precisión del despacho, **no** la protección. Con esto ninguna garantía fail-closed queda alojada solo en la semilla, que es la regla que el 08 fijó en su r1.

**Por qué la guarda cubre las cuatro skills que mutan, no solo las tres de fase** (r1 p1): el criterio no es «ser una fase» sino **escribir**. `recap` fija «esperando OK» en STATUS y **commitea de inmediato**; disparado por error durante una review lanzada mueve HEAD, y con eso el `review_head` del terminal deja de coincidir y el desenlace pasa a resolverse por el camino conservador (contrato §Reentrada). Sin guarda en `recap`, la afirmación «un ruteo errado cuesta un mensaje» era falsa y la garantía no viajaba entera en el payload. Las otras dos skills no mutan sin condición previa: `status` es lectura pura y `adopt` exige `docs/ADOPTION.md` —su propia precondición es el primer caso del orden de despacho— y pregunta cada punto de juicio.

*Alternativa descartada*: mudar el orden a un archivo payload nuevo (`docs/design/routing-contract.md` en la allowlist). Es correcto pero mueve superficie del instalador —y de `tests/install.sh`— a este feature, cuando el 10 ya tiene declarada esa superficie por la skill `build`; y el orden **pertenece** al contexto raíz: es lo único que se lee *antes* de que exista una skill elegida. Se conserva el lugar que el diseño fijó y se cubre el hueco con la guarda, que es payload y además es donde la decisión realmente se ejecuta.

### 2. Orden de despacho (la sección de `AGENTS.md`)

Transcripción ejecutable del orden contractual del diseño; **el primer caso que aplica gana** y los casos de estado pendiente preceden siempre a la clasificación del pedido:

1. **Consulta** → **`/status` y nada más**. Lectura pura, disponible en cualquier estado. `/recap` **no** es consulta: se elige solo ante un pedido explícito de RECAP o checkpoint (a mitad de loop, eso equivale a pedir un checkpoint temprano — semántica existente).
2. **Estado pendiente manda** → reentrada de la skill dueña, nunca trabajo nuevo: adopción sin cerrar → `/adopt`; corte de lote registrado, OK humano pendiente, confirmación de arranque o autorización de lote pendientes, review lanzada sin desenlace consumido, o fase/feature/lote activo → la skill de esa fase por su rama de reentrada (feature 08). Rige **también** para invocaciones explícitas: ver la guarda (§3).
3. **Solo desde estado estable** se clasifica el pedido, **por lo que necesita** y no por lo que los docs tengan: diseño → `/design` (incluye «no hay `DESIGN.md` real, solo la semilla»); plan → `/plan`; features ya planificados → `/feature` (`all`/rango si pide varios de corrido); **dos o más fases** → interinato multifase (§5), que el 10 reemplaza por `/build`.
4. **Ambigüedad en cualquier paso** → **una línea** de pregunta. No adivinar.

Las fuentes que el ruteo lee son las que el 08 dejó normalizadas: la línea **«Esperando»** de STATUS para el paso 2 —sus cinco literales más el que §4 agrega, «esperando confirmación de plan»— y la línea de **ronda** con su token (`N · lanzada` / `N · consumida` / `—`) para saber si hay una review sin desenlace consumido. Ante contradicción entre las dos líneas gana el camino conservador — regla ya fijada en `docs/design/review-contract.md` §Reentrada; el ruteo no la reinterpreta, entrega a la reentrada y ahí se resuelve.

**Corrección de la línea de `/recap`**: en `AGENTS.md` y en `templates/AGENTS.md`, el ítem que hoy agrupa `/status` y `/recap` como consultas se parte — `/status` es lectura pura; `/recap` es **checkpoint a demanda** que fija «esperando OK» y commitea. Es alcance fijado por el diseño y además precondición del paso 1: mientras esa línea diga que `/recap` no cambia el trabajo, el ruteo tiene una fuente que lo contradice.

### 3. Guarda de entrada (payload)

Unas pocas líneas al tope del cuerpo de `design`, `plan`, `feature` y `recap`, con el contenido específico de cada una: **cada skill nombra el estado ajeno que la frena** (el propio ya lo cubren sus ramas de reentrada del 08).

**Alcance de la guarda: solo el ruteo implícito** (r1 p2). El diseño aprobado fija que el ruteo es para pedidos **sin comando**, que no rutea mensajes a mitad de loop y que `/design`, `/plan` y `/feature` explícitos «funcionan exactamente igual que hoy» ([implicit-entry.md](../design/implicit-entry.md) §«Qué NO hace el ruteo»). La bajada no puede redefinir eso. Entonces:

- **Invocación por ruteo** (pedido sin comando): si STATUS registra estado pendiente de otra fase, la skill **no arranca trabajo nuevo** — nombra lo que encontró y entra por la reentrada de la skill dueña. Es el paso 2 del orden, ejecutado desde el payload.
- **Invocación explícita** (`/feature`, `/design`, `/plan` tipeados): el camino es **el de hoy**, sin cambio de contrato. Lo único que la skill agrega es **informar en una línea** el estado ajeno que ve, porque callarlo sería peor; a partir de ahí manda el humano (prioridad absoluta, regla existente) y, si su indicación implica cambio de scope sobre un ciclo abierto, aplica el RECAP temprano — también regla existente. Ningún comando explícito se bloquea ni se redirige por decisión de esta bajada.

**Nada de esto se apoya en un sentinel de texto** (r1 p3). La guarda se define sobre **estado ajeno**, y el estado de un lote **no es ajeno a `feature`**: por construcción la guarda de `feature` nunca se dispara contra un hijo de lote, así que no hace falta —ni existe— una excepción que un prompt pueda forjar escribiendo «Modo hijo del lote». Lo que sí se endurece es la **precondición del hijo**, que es observable: antes de trabajar, el hijo verifica que STATUS apunte al ledger de la corrida y que el ledger registre **su NN** como «en curso» **sin corte pendiente**; si no coincide, no arranca (es corte). Un prompt forjado sin ese estado detrás cae en las ramas conservadoras que ya existen —por ejemplo, con STATUS en «esperando OK humano» manda esa rama de `feature`, que re-presenta el RECAP y no arranca nada— y con eso el texto del prompt deja de otorgar autoridad alguna. Las guardas de `design` y `plan` tratan «feature/lote activo» como ajeno **sin excepción**: en el 09 esas dos skills nunca son hijas de nada; la semántica de **hijo de pipeline** es alcance declarado del feature 10.

**Guarda de `recap`** (r1 p1) — es la única que además restringe **cuándo mutar**, porque `recap` escribe STATUS y commitea apenas se dispara:

- Muta solo en dos casos: **pedido explícito** del humano de RECAP o checkpoint, o **invocación desde una skill de fase** al cerrar (APPROVED de cierre, RECAP temprano, corte de lote).
- Cualquier otra entrada —una pregunta de estado, un pedido de trabajo, un ruteo dudoso— **no toca nada**: entrega a `/status` si era consulta, o a la skill dueña del estado pendiente si lo había.
- Si la línea de ronda de STATUS dice `N · lanzada`, lo **dice antes de commitear**: el commit del RECAP mueve HEAD y el desenlace de esa review pasará a resolverse por el camino conservador del contrato. Es información para el humano, no un bloqueo — un checkpoint pedido a mitad de loop es legítimo (semántica fijada por el diseño).

### 4. Regla de confirmación y la confirmación liviana de `/plan`

El ruteo nunca arranca trabajo sin un punto de confirmación. Tres de las cuatro fases ya lo tienen: `/design` (el ping-pong ES la confirmación — la skill prohíbe escribir docs grandes sin validar el rumbo), `/feature` (gate de arranque del 05), `/adopt` (pregunta cada punto de juicio). `/plan` es el hueco: **cuando llega despachado** anuncia en pocas líneas cómo interpretó el pedido y qué va a plasmar, y espera una confirmación liviana antes de escribir. La invocación explícita directa de `/plan` queda como hoy (decisión del diseño).

**La espera se persiste**, como el gate del 05 (r1 p4 — la bajada anterior decía lo contrario y estaba mal). El argumento que la sostenía —«el único camino de reapertura sin re-confirmar es `/plan` explícito»— es falso: la espera **sí cruza turnos**. Si la sesión cae después de presentar la interpretación, una sesión fresca puede recibir solo «dale» o «seguí», sin el pedido original ni la interpretación (eran chat, y el chat es efímero); con STATUS estable y triggers heurísticos, ese «seguí» puede despacharse como «el siguiente paso» a cualquier fase. Mecanismo:

1. Antes de presentar: STATUS → **«esperando confirmación de plan»** (literal fijo, cuarta espera humana del vocabulario) **con la interpretación mínima en la misma línea**, y commit. La interpretación se persiste porque —a diferencia del resumen del gate del 05, que se re-deriva de los docs— **no es derivable**: su fuente es el pedido del humano, que vive en el chat.
2. Presentar la interpretación y pedir la confirmación liviana. Respuesta directa ⇒ sin push (protocolo de la skill `recap`). Terminar el turno.
3. **Rama de re-presentación** en la skill `plan`: con STATUS en ese literal no se avanza trabajo nuevo — se re-presenta **la interpretación registrada en STATUS** (no se re-deriva) y se espera. Un «dale» que llega en una sesión fresca entra por el paso 2 del orden de despacho, no por clasificación de pedido.
4. Con la confirmación: se registra en el commit del plan (fecha + literal breve + correcciones de alcance) y sigue el paso 1 de la skill. Una corrección del humano manda.

Esto deja la persistencia **entera en el payload**: el literal nuevo va al vocabulario de `docs/design/review-contract.md` §Reentrada y la rama va a la skill `plan` — los dos viajan con el re-run del instalador, así que un destino sin §Ruteo en su `AGENTS.md` igual queda protegido. Es exactamente la asimetría que antes se argumentaba al revés: `/plan` despachado necesita **más** persistencia que el gate del 05, no menos, porque su contexto no se puede reconstruir de los docs.

### 5. Interinato multifase

Mientras `/build` no exista, un pedido que necesita dos o más fases (paso 3 del orden) recibe este comportamiento, fijado y fail-closed:

1. **Decirlo**: nombrar la ruta completa que el pedido necesita (p. ej. «esto necesita diseño → plan → un feature»).
2. **Arrancar solo por la primera fase**, con su punto de confirmación (§4) — que es también donde el humano corrige si el ruteo interpretó mal.
3. **No encadenar**: cerrada esa fase con su OK, el humano decide. La regla dura sigue intacta hasta el 10.

Se elige esta variante sobre la otra candidata del plan (pregunta de una línea y nada más) porque **cumple la misma garantía con menos fricción**: el anuncio de la ruta + el punto de confirmación de la primera fase ya le da al humano toda la información y el poder de veto que le daría la pregunta, y además avanza. La pregunta de una línea sigue disponible para el caso genuinamente ambiguo (paso 4), que es donde corresponde.

**Qué exactamente reemplaza el feature 10** (r1 p5c). El interinato es **un solo bloque semántico**: el párrafo «Multifase (interino, hasta que exista `/build`)» de §Ruteo en `AGENTS.md` **y su espejo literal** en `templates/AGENTS.md` (la regla de sincronía hace que los dos cuenten como un bloque). El 10 lo sustituye por el despacho a `/build` sin tocar ningún otro texto de este feature. Lo que el 10 **inevitablemente** agrega además —y que **no** cuenta como parte de ese reemplazo, porque es superficie propia suya ya declarada en el plan— es: la skill `build` nueva con su `description`, su entrada en la allowlist de `scripts/install.sh` y la cobertura en `tests/install.sh`, la extensión de la regla dura («ni cruzar a otra fase sin OK — salvo lote o pipeline autorizado») en `AGENTS.md` + plantilla, la semántica de hijo de pipeline en `design`/`plan`/`feature`, y la generalización de `AXEL_REVIEW_ID` en el contrato. La única costura entre ambos es que las `description`s de `design`/`plan`/`feature` **no nombran** el destino multifase (§7): el interinato vive solo en la sección de orden, así que el 10 no necesita reescribirlas para desambiguar contra `build` — le alcanza con que la suya declare su propio disparador.

### 6. Ruteo al modo lote

Reinterpretación del opt-in ya registrada en el diseño ([design/batch-features.md](../design/batch-features.md) y [design/implicit-entry.md](../design/implicit-entry.md)): lo que protege el opt-in es la **autorización del gate de lote**, no la forma de invocación. Un pedido inequívoco de correr varios features de corrido puede despachar a `/feature all` o a un rango; el gate sigue presentando los N resúmenes y su autorización global sigue siendo el habilitante. Pedido dudoso sobre cuántos features abarca ⇒ regla de ambigüedad (preguntar). Los dos docs de diseño ya lo registran: acá solo se implementa.

### 7. Descripciones-trigger: criterio de redacción

Cada `description` conserva el nombre de la fase (el humano las lee en el listado) y agrega **cuándo dispararse**, con un **discriminante** que la separa de las demás. Los dos pares que se pisan si no se separan explícitamente:

- **`status` vs. `recap`**: `status` declara ser la única entrada para preguntas de estado; `recap` declara que **no** es consulta, que fija «esperando OK» y commitea, y que solo se elige ante un pedido explícito de RECAP/checkpoint o cuando una skill de fase lo invoca al cerrar.
- **`design` vs. `plan` vs. `feature`**: se separan por lo que el pedido **necesita** — rumbo/idea nueva (o no hay diseño real) vs. qué hacer y en qué orden vs. avanzar con lo ya planificado.

`adopt` declara su precedencia (existe `docs/ADOPTION.md` ⇒ manda). `feature` menciona el modo lote para que un pedido de varios features de corrido lo alcance (§6). Ninguna `description` nombra el destino **multifase**: eso vive solo en la sección de orden (§5), para que el 10 lo reemplace sin reescribir descripciones.

### 8. Higiene del arnés de tests

`tests/loop.sh` cubre en L10 el caso «sin `AXEL_REVIEW_ID`: `id=-` y flujo intacto», pero la suite **no neutraliza el entorno**: corrida desde adentro de una review de lote —donde `review.sh` se invocó con `AXEL_REVIEW_ID` seteado— hereda la variable y L10 falla (287 casos: 286/1; hallazgo del reviewer en r1, que la sorteó neutralizándola a mano). Ese es exactamente el entorno en el que el reviewer corre las suites durante un lote, así que el criterio de cierre 7 («las tres suites en verde como no-regresión») no es verificable mientras el resultado dependa de qué variables trajo el shell.

Fix: `unset` de los `AXEL_REVIEW_*` en el preámbulo de la suite, con el comentario que explica por qué. La suite ya setea los overrides que necesita **por caso** (`AXEL_REVIEW_MODEL`/`EFFORT` en L2, `AXEL_REVIEW_RETRIES` en L8, `AXEL_REVIEW_ID` en L9–L11), así que neutralizar en el preámbulo no le quita cobertura a nada: le devuelve hermeticidad, que es la propiedad que la suite ya persigue con los dobles por PATH y los fixtures en `mktemp`. No toca la maquinaria (`scripts/` sigue con diff vacío).

## Matriz de ruteo (verificación)

No hay harness de despacho: el ruteo lo ejecuta el modelo leyendo `AGENTS.md` y las descripciones. La verificación es esta matriz — **cada fila debe resolverse leyendo el texto final instalado**: §Ruteo de `AGENTS.md`, una `description`, o la guarda/rama de la skill correspondiente (las tres son texto que viaja; las dos últimas, payload). Ninguna fila puede depender de este doc. Cubre los cuatro pasos del orden, los cuatro puntos de confirmación, las cuatro esperas humanas, el interinato, el lote y la ambigüedad. La columna «regla» dice **dónde** vive la decisión, que es lo que el reviewer comprueba.

| # | Estado en STATUS | Pedido (sin comando, salvo donde se aclara) | Destino esperado | Regla que decide |
|---|---|---|---|---|
| 1 | cualquiera | «¿dónde estamos?» | `/status` | paso 1 |
| 2 | feature activo, ronda 2 lanzada | «¿cómo viene esto?» | `/status` (**no** `/recap`) | paso 1 + `description` de `recap` |
| 3 | cualquiera | «dame un recap» / «pará y hacé un checkpoint» | `/recap` (con su semántica: fija «esperando OK», commitea) | paso 1, pedido explícito |
| 4 | existe `docs/ADOPTION.md` | «arrancá con el diseño» | `/adopt` | paso 2 (precedencia de adopción) |
| 5 | esperando OK humano (feature 08 cerrado) | «seguí con el 09» | `/feature` → rama «esperando OK»: re-presenta el RECAP pendiente | paso 2 |
| 6 | esperando confirmación de arranque | «avancemos» | `/feature` → re-derivar y re-presentar el gate | paso 2 |
| 7 | feature activo, ronda 3 **lanzada** | «cambiá el diseño de X» | `/feature` → reentrada del feature activo (resuelve el desenlace; **no** relanza review ni abre `/design`) | paso 2 (estado pendiente precede a la clasificación) |
| 8 | lote en curso con **corte** registrado en el ledger | «seguí con el lote» | `/feature` → reentrada de lote: corte absorbente, re-presenta el RECAP | paso 2 |
| 9 | ciclo de diseño abierto (`CHANGES_REQUESTED` consumido) | «seguí con el feature» (sin comando) | guarda de `feature`: nombra el ciclo de diseño abierto y entrega a `/design` sin arrancar nada | guarda de `feature` (§3) |
| 9b | ciclo de diseño abierto | `/feature` **explícito** | camino de hoy: la skill **informa en una línea** el ciclo abierto y sigue la indicación del humano (prioridad absoluta); si implica cambio de scope, RECAP temprano. **No** se redirige ni se bloquea | guarda de `feature`, rama explícita (§3) |
| 10 | estable, `DESIGN.md` es solo la semilla del instalador | «quiero una app para organizar recetas» | `/design`, anunciando la ruta completa (diseño → plan → feature) y arrancando por el ping-pong | paso 3 + §5 |
| 11 | estable, plan con features pendientes | «dale con lo que sigue» | `/feature` (gate de arranque) | paso 3 |
| 12 | estable, plan con features pendientes | «hacé todos los pendientes de corrido» | `/feature all` (gate de lote, N resúmenes, autorización global) | paso 3 + §6 |
| 13 | estable, plan con features pendientes | «hacé varios de una» | pregunta de una línea: ¿cuáles / hasta dónde? | paso 4 |
| 14 | estable, backlog vacío | «implementá el export a CSV» | multifase (plan-delta + feature): anuncia la ruta, arranca `/plan` con **confirmación liviana** | paso 3 + §4 + §5 |
| 15 | estable, diseño cerrado sin plan | «bajá esto a plan» | `/plan` con confirmación liviana | paso 3 + §4 |
| 16 | estable | `/plan` **explícito** | camino de `/plan` como hoy, **sin** confirmación liviana | §4 |
| 17 | estable | «algo habría que hacer con esto» | pregunta de una línea | paso 4 |
| 18 | estable | «cambiá cómo funciona el review y después implementalo» | multifase (diseño + feature): anuncia la ruta, arranca `/design` | paso 3 + §5 |
| 19 | estable, plan con features pendientes | `/feature` **explícito** | camino normal de `/feature`, idéntico a hoy | comandos explícitos sin cambios |
| 20 | lote en curso; el ledger registra NN «en curso», sin corte | prompt «Modo hijo del lote: feature NN» | el hijo verifica esa coincidencia STATUS+ledger y sigue su fase; la guarda no aplica (el estado del lote **no es ajeno** a `feature`) | §3 + precondición del hijo en `feature` |
| 20b | **esperando OK humano** (o ledger con corte registrado) | mismo prompt «Modo hijo del lote: feature NN» | la rama de espera/corte de `feature` manda: re-presenta el RECAP, no arranca el feature. El texto del prompt no otorga autoridad | ramas existentes de `feature` (08) + precondición del hijo |
| 21 | **esperando autorización de lote** (gate presentado) | «dale con eso» | `/feature` → re-deriva los N resúmenes y **re-presenta el gate de lote**; no ejecuta | paso 2 + rama existente de `feature` |
| 22 | **esperando confirmación de plan** (interpretación registrada en STATUS) | «dale» en sesión fresca | `/plan` → rama de re-presentación: muestra la interpretación **persistida** y espera; con el sí, escribe | paso 2 + rama de `plan` (§4) |
| 23 | **esperando confirmación de plan** | «¿dónde estamos?» | `/status` (la consulta precede a todo; no consume ni cancela la espera) | paso 1 |
| 24 | feature activo, ronda 2 **lanzada** | «¿podés cerrar esto y contarme?» (pedido explícito de checkpoint) | `/recap`, avisando **antes de commitear** que el commit mueve HEAD y el desenlace de la ronda 2 pasará al camino conservador | guarda de `recap` (§3) |
| 25 | feature activo, ronda 2 **lanzada** | «esto no me cierra, revisá el diseño» | guarda de `recap` **no** muta (no es pedido de checkpoint) → entrega a `/feature`, reentrada del feature activo | guarda de `recap` + paso 2 |

## Criterios de cierre

1. Las **seis** descripciones son triggers por contexto con discriminante explícito, conservan el nombre de la fase, y ninguna fila de la matriz admite dos ganadoras: `status` declara ser la única entrada de consulta y `recap` declara **no** serlo (con su efecto: fija «esperando OK» y commitea). Ninguna nombra el destino multifase.
2. `AGENTS.md` tiene §Ruteo con los cuatro pasos del orden contractual, la regla de confirmación, el interinato multifase, el ruteo al lote y el «qué no hace»; `templates/AGENTS.md` la **espeja** (regla de sincronía) y ambos corrigen la línea que hoy presenta `/recap` como consulta que no cambia el trabajo.
3. La garantía **no depende de la semilla y cubre todas las skills que mutan**: `design`, `plan`, `feature` y `recap` traen guarda en el payload; la de `recap` acota además *cuándo* mutar. La guarda rige solo para invocaciones **ruteadas** — un comando explícito conserva su contrato de hoy (informa el estado ajeno, no se bloquea ni se redirige) — y no existe excepción activable por texto de prompt: la habilitación del hijo de lote es la coincidencia observable STATUS+ledger. Queda documentada la degradación de un proyecto instalado antes de este feature (pierde precisión de despacho, conserva la protección).
4. `/plan` despachado **persiste** la espera y su interpretación en STATUS («esperando confirmación de plan», cuarta espera humana del vocabulario del contrato) antes de presentarla, y la skill tiene rama de re-presentación; la invocación explícita directa no cambia. Ningún camino de reapertura consume esa confirmación sin contexto durable.
5. El interinato multifase está fijado (anunciar ruta → arrancar solo la primera fase con su confirmación → no encadenar) y vive en **un solo bloque semántico** (el párrafo de §Ruteo y su espejo en la plantilla). El doc declara qué cambios del 10 quedan fuera de ese reemplazo por ser superficie propia suya.
6. La matriz se resuelve **entera** contra el **texto final instalado** —§Ruteo, una `description`, o la guarda/rama de una skill—, sin apelar a este doc, y cubre las cuatro esperas humanas.
7. Sin cambios en la maquinaria: `scripts/` con diff vacío y payload del instalador sin archivos nuevos. Único cambio ejecutable: el `unset` de `AXEL_REVIEW_*` en el preámbulo de `tests/loop.sh` (§8). Las tres suites (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión **con el entorno del lote** (`AXEL_REVIEW_ID` seteado), que es lo que ese fix vuelve verificable.

## Riesgos

- **El trigger es heurístico**: el modelo puede elegir mal la skill, y ningún texto lo garantiza. Es el riesgo estructural del feature. Mitigación en profundidad: las cuatro skills que mutan tienen guarda, y la regla de confirmación impide arrancar trabajo sin validación — un ruteo errado cuesta **un mensaje**, no trabajo perdido ni estado corrompido. El costo real que queda acotado, no eliminado: un `/recap` legítimo pedido a mitad de review mueve HEAD igual, y el desenlace de esa ronda se resuelve por el camino conservador (aviso previo, no bloqueo).
- **La guarda distingue invocación ruteada de explícita, y eso también lo juzga el modelo**: si confunde las dos, el modo de falla es informar de más (nombrar un estado ajeno en un comando explícito), nunca bloquear un comando ni arrancar sobre estado pendiente. Se acepta: el error cae del lado seguro.
- **Inflación de triggers**: seis descripciones que compiten por el mismo pedido degradan la elección. Mitigación: discriminante explícito por skill (§7) y la matriz como control; el par peligroso (`status`/`recap`) se separa nombrándose mutuamente.
- **La sección de ruteo no llega a proyectos ya instalados** (semilla). Documentado; el remedio manual es copiarla al `AGENTS.md` del destino — el instalador nunca lo pisa, por diseño. Se acepta porque la protección viaja igual (§1).
- **Prosa sin suite**: como en el 08, no hay test que congele el comportamiento; la verificación es la matriz leída contra el texto por el reviewer, más las suites de código como no-regresión. Queda registrado honestamente.
- **El interinato es texto con fecha de vencimiento**: si el 10 se posterga, queda como comportamiento vigente (correcto, solo menos ágil); si el 10 llega, hay que borrarlo — está declarado en su superficie, y el criterio de cierre 5 pide que sea reemplazable en un solo lugar.
- **Ruteo al lote sobre-entusiasta**: un pedido vago podría abrir un lote de N features. Mitigación: regla de ambigüedad (fila 13 de la matriz) y el gate de lote, que presenta los N resúmenes antes de cualquier trabajo.

## Review log

- **r1** (2026-07-29, `CHANGES_REQUESTED`, rango `a2f673d..a6af7ab`): review de la bajada. Codex validó los commits de cierre del 08 y de arranque del 09, y corrió las tres suites (lint limpio, install 459/0, loop 287/0 tras neutralizar el entorno). **Cinco puntos, los cinco aceptados**:
  1. **La guarda no cubría todas las skills que mutan.** `recap` fija «esperando OK» y commitea apenas se dispara: ruteado por error durante una review lanzada mueve HEAD y vuelve ambiguo su desenlace — con lo cual «un ruteo errado cuesta un mensaje» era falso y la garantía no viajaba entera en el payload. Aceptado: `recap` gana guarda ejecutable (muta solo ante pedido explícito de checkpoint o invocación de una skill de fase al cerrar; cualquier otra entrada entrega a `/status` o a la dueña sin tocar estado, y avisa si hay una ronda `lanzada`), y el criterio pasa de «ser una fase» a **«escribir»** (§1, §3). `status` y `adopt` quedan analizados y sin guarda, con su razón.
  2. **La guarda aplicada a comandos explícitos contradecía el diseño aprobado** («no rutea mensajes a mitad de loop»; «`/design`/`/plan`/`/feature` explícitos funcionan exactamente igual que hoy»). La fila 9 redefinía eso desde la bajada. Aceptado: la guarda se acota al **ruteo implícito**; el comando explícito conserva su contrato —la skill solo informa en una línea el estado ajeno y manda el humano, con RECAP temprano si hay cambio de scope— y la matriz se parte en 9 (ruteada) y 9b (explícita).
  3. **La excepción del modo hijo no tenía predicado fail-closed**: el mero texto «Modo hijo del lote…» la activaba. Aceptado y resuelto **eliminando la excepción** en vez de blindarla: la guarda se define sobre estado **ajeno**, y el lote no es ajeno a `feature`, así que nunca se dispara contra un hijo y no hay nada que forjar. Lo que se endurece es la **precondición observable** del hijo (STATUS apunta al ledger + el ledger registra su NN «en curso» sin corte pendiente; si no coincide, corte), con la matriz mostrando el prompt forjado cayendo en las ramas conservadoras existentes (20/20b). Los hijos de **pipeline** quedan explícitamente en el 10.
  4. **La no-persistencia de la confirmación de `/plan` omitía una reentrada real**: la espera cruza turnos, y una sesión fresca que recibe solo «dale» no tiene ni el pedido ni la interpretación — y en un destino viejo tampoco tiene §Ruteo. Aceptado: se **persiste** la espera **y la interpretación** en STATUS («esperando confirmación de plan», cuarta espera humana en el vocabulario del contrato — payload), con rama de re-presentación en la skill `plan` y filas 22/23 en la matriz. La asimetría con el gate del 05 se invierte y queda argumentada: la interpretación **no es derivable de los docs**, así que necesita más persistencia, no menos.
  5. **Criterios de cierre no ejecutables**: (a) faltaba la fila de «esperando autorización de lote» ⇒ fila 21; (b) el criterio 6 exigía que toda fila viviera en `AGENTS.md` o una `description`, pero 9 y 20 dependen de guardas ⇒ el criterio pasa a «texto final **instalado**: §Ruteo, `description`, o guarda/rama de skill», que es igual de exigible y honesto sobre las tres sedes; (c) el criterio 5 prometía reemplazo «en un solo lugar» ⇒ se define el **bloque semántico único** (el párrafo del interinato + su espejo) y se enumeran los cambios inevitables del 10 que no cuentan como parte del reemplazo (skill `build` + allowlist + tests, regla dura, hijo de pipeline, `AXEL_REVIEW_ID`), más la costura que lo hace posible: ninguna `description` nombra el destino multifase.

  **Drive-by de la verificación de Codex** (no era uno de los puntos): `tests/loop.sh` heredó `AXEL_REVIEW_ID` de la review del lote y falló L10 (286/1) hasta neutralizarla a mano. Ese es el entorno normal del reviewer durante un lote, así que el criterio de cierre 7 no era verificable; entra a alcance el `unset` de los `AXEL_REVIEW_*` en el preámbulo de la suite (§8), aplicado en este mismo commit para que la corrida de r2 sea hermética.
