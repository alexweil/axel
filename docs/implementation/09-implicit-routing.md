# 09 — Ruteo implícito: triggers y despacho por contexto

## Autorización

- **2026-07-29** — autorizado por el **gate de lote** de `/feature all` (features 08, 09, 10), sin exclusiones ni correcciones de alcance. Ledger de la corrida: [batch-2026-07-29.md](batch-2026-07-29.md); resumen autorizado del 09, ahí. No hay gate individual: el hijo de un lote no re-pide confirmación (contrato del modo lote, skill `feature`).

## Alcance

Nivel 1 del diseño de entrada implícita ([design/implicit-entry.md](../design/implicit-entry.md), §«Nivel 1 — ruteo implícito»): que un pedido en lenguaje natural, **sin comando**, se despache a la fase correcta — sin maquinaria nueva y sin arrancar trabajo sin un punto de confirmación. El feature 08 dejó el inventario de reentradas completo, que es a donde el ruteo entrega todo pedido que llega con estado pendiente.

Entregables:

- **Descripciones-trigger** en las **seis** skills (`design`, `plan`, `feature`, `status`, `recap`, `adopt`): la `description` deja de nombrar solo la fase y pasa a decir **cuándo dispararse por contexto**, conservando el nombre de la fase (es lo que el humano lee en el listado). Es el mecanismo estándar de skills — lo único que el modelo ve antes de elegir — y es **payload**: viaja a todo destino con el re-run del instalador.
- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): sección **§Ruteo** con el orden de despacho contractual fail-closed (4 pasos), la regla de confirmación, el **interinato multifase**, el ruteo al modo lote y el «qué no hace el ruteo». Más la **corrección de la línea de `/recap`**, que hoy lo presenta junto a `/status` como «consulta … no cambian el trabajo»: su skill fija «esperando OK», commitea y frena el turno.
- **Guarda de entrada** en `design`, `plan` y `feature` (§3): dos líneas por skill que hacen valer «estado pendiente manda» **desde el payload**, aunque la sección de `AGENTS.md` falte. Es la respuesta al hallazgo de r1 del feature 08 — `AGENTS.md` es **semilla** del instalador, así que nada load-bearing puede depender solo de él.
- **Confirmación liviana de `/plan` despachado** (§4): `/plan` es la única fase sin gate propio; cuando llega por ruteo anuncia su interpretación y espera confirmación antes de escribir. La invocación explícita directa no cambia.
- **`docs/IMPLEMENTATION.md`**: fila 09 al día. **`docs/STATUS.md`**: al día en cada commit, con el token de ronda del contrato.

**Fuera de alcance**:

- **`/build` y el pipeline** (feature 10). Este feature deja el destino multifase resuelto por un **interinato** explícito que el 10 reemplaza (declarado en su superficie).
- **Código ejecutable y superficie del instalador**: cero archivos nuevos ⇒ `scripts/install.sh` y su allowlist **no cambian** (las seis skills y `templates/AGENTS.md` ya están; la skill `build` y su entrada en la allowlist son alcance declarado del 10). Sin cambios en `scripts/review.sh` ni en `scripts/awake.sh`.
- **Las reentradas** (feature 08, ya cerrado): el ruteo **entrega** a ellas, no las redefine. Ninguna rama de reentrada se toca acá.
- **Vocabulario nuevo en STATUS**: el 08 ya fijó los literales de «Esperando» y el token de la línea de ronda — que son exactamente lo que el ruteo lee. No hace falta nada más.
- **`/adopt`, `/status` y `/recap` como cuerpos de skill**: solo cambia su `description`. `adopt` ya arranca decidiendo sobre la existencia de `docs/ADOPTION.md`; `status` es lectura pura; `recap` ya se comporta como checkpoint — lo que faltaba era **decirlo** donde el ruteo lo lee.

## Enfoque técnico

### 1. Las tres capas del ruteo (y por qué la garantía no vive en la semilla)

El diseño fija dos piezas: descripciones-trigger y sección de ruteo en `AGENTS.md`. La bajada agrega una tercera por una razón concreta: **`AGENTS.md` es semilla, no payload** — el instalador la crea si falta y **no la pisa jamás** después (`SEED_SRC`/`SEED_DEST` en `scripts/install.sh`). Un proyecto instalado antes de este feature no recibe la sección al actualizar la maquinaria. El reparto queda así:

| Capa | Dónde | Qué aporta | ¿Viaja al actualizar? |
|---|---|---|---|
| **Trigger** | `description` de las 6 skills | Que un pedido sin comando **elija** una skill. Es lo único que el modelo ve antes de decidir. | **Sí** (payload) |
| **Orden** | `AGENTS.md` §Ruteo (+ espejo en la plantilla) | Que la elección sea **correcta a la primera**: precedencia de consulta y de estado pendiente, clasificación por lo que el pedido necesita, ambigüedad, interinato, lote. | Solo en instalaciones nuevas (semilla) |
| **Guarda** | `design`, `plan`, `feature` (cuerpo de la skill) | Que una elección **errada** no arranque trabajo nuevo sobre estado pendiente: la skill mira STATUS al entrar y entrega a la dueña. | **Sí** (payload) |

La capa de orden es la que hace el ruteo bueno; la capa de guarda es la que lo hace **seguro**. Sin la sección (proyecto viejo), un pedido igual dispara una skill por su trigger, y si el estado pendiente pertenece a otra fase la guarda lo entrega en vez de pisarlo: se degrada la precisión del despacho, **no** la protección. Con esto ninguna garantía fail-closed queda alojada solo en la semilla, que es la regla que el 08 fijó en su r1.

*Alternativa descartada*: mudar el orden a un archivo payload nuevo (`docs/design/routing-contract.md` en la allowlist). Es correcto pero mueve superficie del instalador —y de `tests/install.sh`— a este feature, cuando el 10 ya tiene declarada esa superficie por la skill `build`; y el orden **pertenece** al contexto raíz: es lo único que se lee *antes* de que exista una skill elegida. Se conserva el lugar que el diseño fijó y se cubre el hueco con la guarda, que es payload y además es donde la decisión realmente se ejecuta.

### 2. Orden de despacho (la sección de `AGENTS.md`)

Transcripción ejecutable del orden contractual del diseño; **el primer caso que aplica gana** y los casos de estado pendiente preceden siempre a la clasificación del pedido:

1. **Consulta** → **`/status` y nada más**. Lectura pura, disponible en cualquier estado. `/recap` **no** es consulta: se elige solo ante un pedido explícito de RECAP o checkpoint (a mitad de loop, eso equivale a pedir un checkpoint temprano — semántica existente).
2. **Estado pendiente manda** → reentrada de la skill dueña, nunca trabajo nuevo: adopción sin cerrar → `/adopt`; corte de lote registrado, OK humano pendiente, confirmación de arranque o autorización de lote pendientes, review lanzada sin desenlace consumido, o fase/feature/lote activo → la skill de esa fase por su rama de reentrada (feature 08). Rige **también** para invocaciones explícitas: ver la guarda (§3).
3. **Solo desde estado estable** se clasifica el pedido, **por lo que necesita** y no por lo que los docs tengan: diseño → `/design` (incluye «no hay `DESIGN.md` real, solo la semilla»); plan → `/plan`; features ya planificados → `/feature` (`all`/rango si pide varios de corrido); **dos o más fases** → interinato multifase (§5), que el 10 reemplaza por `/build`.
4. **Ambigüedad en cualquier paso** → **una línea** de pregunta. No adivinar.

Las fuentes que el ruteo lee son las que el 08 dejó normalizadas: la línea **«Esperando»** de STATUS (sus cinco literales) para el paso 2, y la línea de **ronda** con su token (`N · lanzada` / `N · consumida` / `—`) para saber si hay una review sin desenlace consumido. Ante contradicción entre las dos líneas gana el camino conservador — regla ya fijada en `docs/design/review-contract.md` §Reentrada; el ruteo no la reinterpreta, entrega a la reentrada y ahí se resuelve.

**Corrección de la línea de `/recap`**: en `AGENTS.md` y en `templates/AGENTS.md`, el ítem que hoy agrupa `/status` y `/recap` como consultas se parte — `/status` es lectura pura; `/recap` es **checkpoint a demanda** que fija «esperando OK» y commitea. Es alcance fijado por el diseño y además precondición del paso 1: mientras esa línea diga que `/recap` no cambia el trabajo, el ruteo tiene una fuente que lo contradice.

### 3. Guarda de entrada (payload)

Dos líneas al tope del cuerpo de `design`, `plan` y `feature`, con el contenido específico de cada una (cada skill nombra el estado **ajeno** que la frena; el propio ya lo cubren sus ramas de reentrada del 08):

- Vale **igual si la invocación fue explícita o ruteada**. Un `/feature` tipeado sobre un ciclo de diseño abierto es tan inconsistente como uno ruteado: la skill dice qué encontró y entrega, no arranca en silencio. Esto **no** cambia el contrato de los comandos explícitos en el caso normal (estado estable ⇒ camino idéntico al de hoy); solo cubre el caso que hoy no tiene respuesta.
- La acción es **entregar, no bloquear**: nombrar el estado encontrado y entrar por la reentrada de la skill dueña. Si el humano, viendo eso, indica otra cosa, su mensaje tiene prioridad absoluta (regla existente).
- **No aplica al modo hijo de un lote/pipeline**: el hijo recibe su fase por prompt explícito del padre y el estado del lote es **suyo**, no ajeno. La guarda de `feature` lo dice, y su rama de lote ya tiene precedencia declarada.

### 4. Regla de confirmación y la confirmación liviana de `/plan`

El ruteo nunca arranca trabajo sin un punto de confirmación. Tres de las cuatro fases ya lo tienen: `/design` (el ping-pong ES la confirmación — la skill prohíbe escribir docs grandes sin validar el rumbo), `/feature` (gate de arranque del 05), `/adopt` (pregunta cada punto de juicio). `/plan` es el hueco: **cuando llega despachado** anuncia en pocas líneas cómo interpretó el pedido y qué va a plasmar, y espera una confirmación liviana antes de escribir. La invocación explícita directa de `/plan` queda como hoy (decisión del diseño).

**No se persiste en STATUS** — decisión de esta bajada, con su argumento:

- La confirmación se presenta en el **mismo turno** en que el ruteo clasifica, **antes de commitear nada**: no hay estado que perder ni trabajo que proteger. Si la sesión muere, STATUS sigue estable y el pedido se vuelve a rutear (y a confirmar) desde cero.
- Persistirla no protegería ningún checkpoint de ser salteado en silencio: la única forma de reabrir sin re-confirmar es que el humano invoque `/plan` **explícito**, camino que por diseño ya no pide confirmación. El modo de falla es «el humano reescribe una frase», no «se escribe un plan sin validar».
- El costo de persistir sería un commit + un literal nuevo en el vocabulario de «Esperando» + una rama de re-presentación en la skill, para ese beneficio nulo.

*Contraste con el gate del 05*, que sí persiste: ahí la espera se alcanza **después** de que `/feature` ya decidió arrancar un feature concreto, y reabrir con `/feature` —el camino natural— saltearía el gate silenciosamente y entraría a la bajada fina. La asimetría es real, no una inconsistencia.

### 5. Interinato multifase

Mientras `/build` no exista, un pedido que necesita dos o más fases (paso 3 del orden) recibe este comportamiento, fijado y fail-closed:

1. **Decirlo**: nombrar la ruta completa que el pedido necesita (p. ej. «esto necesita diseño → plan → un feature»).
2. **Arrancar solo por la primera fase**, con su punto de confirmación (§4) — que es también donde el humano corrige si el ruteo interpretó mal.
3. **No encadenar**: cerrada esa fase con su OK, el humano decide. La regla dura sigue intacta hasta el 10.

Se elige esta variante sobre la otra candidata del plan (pregunta de una línea y nada más) porque **cumple la misma garantía con menos fricción**: el anuncio de la ruta + el punto de confirmación de la primera fase ya le da al humano toda la información y el poder de veto que le daría la pregunta, y además avanza. La pregunta de una línea sigue disponible para el caso genuinamente ambiguo (paso 4), que es donde corresponde.

### 6. Ruteo al modo lote

Reinterpretación del opt-in ya registrada en el diseño ([design/batch-features.md](../design/batch-features.md) y [design/implicit-entry.md](../design/implicit-entry.md)): lo que protege el opt-in es la **autorización del gate de lote**, no la forma de invocación. Un pedido inequívoco de correr varios features de corrido puede despachar a `/feature all` o a un rango; el gate sigue presentando los N resúmenes y su autorización global sigue siendo el habilitante. Pedido dudoso sobre cuántos features abarca ⇒ regla de ambigüedad (preguntar). Los dos docs de diseño ya lo registran: acá solo se implementa.

### 7. Descripciones-trigger: criterio de redacción

Cada `description` conserva el nombre de la fase (el humano las lee en el listado) y agrega **cuándo dispararse**, con un **discriminante** que la separa de las demás. Los dos pares que se pisan si no se separan explícitamente:

- **`status` vs. `recap`**: `status` declara ser la única entrada para preguntas de estado; `recap` declara que **no** es consulta, que fija «esperando OK» y commitea, y que solo se elige ante un pedido explícito de RECAP/checkpoint o cuando una skill de fase lo invoca al cerrar.
- **`design` vs. `plan` vs. `feature`**: se separan por lo que el pedido **necesita** — rumbo/idea nueva (o no hay diseño real) vs. qué hacer y en qué orden vs. avanzar con lo ya planificado.

`adopt` declara su precedencia (existe `docs/ADOPTION.md` ⇒ manda). `feature` menciona el modo lote para que un pedido de varios features de corrido lo alcance (§6).

## Matriz de ruteo (verificación)

No hay harness de despacho: el ruteo lo ejecuta el modelo leyendo `AGENTS.md` y las descripciones. La verificación es esta matriz — **cada fila debe resolverse leyendo el texto final** (sección §Ruteo + `description`s + guardas), y eso es lo que el reviewer comprueba. Cubre los cuatro pasos del orden, los tres puntos de confirmación, el interinato, el lote y la ambigüedad.

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
| 9 | ciclo de diseño abierto (`CHANGES_REQUESTED` consumido) | `/feature` **explícito** | guarda de entrada de `feature`: nombra el ciclo de diseño abierto y entrega a `/design` | §3 |
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
| 20 | lote en curso, hijo trabajando su feature | prompt «Modo hijo del lote: feature NN» | el hijo sigue su fase; la guarda **no** lo frena (el estado del lote es suyo) | §3, excepción del modo hijo |

## Criterios de cierre

1. Las **seis** descripciones son triggers por contexto con discriminante explícito, conservan el nombre de la fase, y ninguna fila de la matriz admite dos ganadoras: `status` declara ser la única entrada de consulta y `recap` declara **no** serlo (con su efecto: fija «esperando OK» y commitea).
2. `AGENTS.md` tiene §Ruteo con los cuatro pasos del orden contractual, la regla de confirmación, el interinato multifase, el ruteo al lote y el «qué no hace»; `templates/AGENTS.md` la **espeja** (regla de sincronía) y ambos corrigen la línea que hoy presenta `/recap` como consulta que no cambia el trabajo.
3. La garantía «estado pendiente manda» **no depende de la semilla**: `design`, `plan` y `feature` traen guarda de entrada en el payload, con la excepción del modo hijo declarada; la degradación de un proyecto instalado antes de este feature (pierde precisión de despacho, conserva la protección) queda documentada.
4. `/plan` despachado pide confirmación liviana antes de escribir; la invocación explícita directa no cambia; la no-persistencia está argumentada y contrastada con el gate del 05.
5. El interinato multifase está fijado (anunciar ruta → arrancar solo la primera fase con su confirmación → no encadenar) y es reemplazable por el 10 sin tocar nada más que esa parte.
6. La matriz de ruteo se resuelve **entera** contra el texto final, sin apelar a este doc: cada fila tiene su regla en `AGENTS.md` o en una `description`.
7. Sin código nuevo: `scripts/` sin cambios y payload del instalador sin archivos nuevos. Las tres suites (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión.

## Riesgos

- **El trigger es heurístico**: el modelo puede elegir mal la skill, y ningún texto lo garantiza. Es el riesgo estructural del feature. Mitigación en profundidad: la guarda impide arrancar sobre estado pendiente, y la regla de confirmación impide arrancar trabajo sin validación — un ruteo errado cuesta **un mensaje**, no trabajo perdido ni estado corrompido.
- **Inflación de triggers**: seis descripciones que compiten por el mismo pedido degradan la elección. Mitigación: discriminante explícito por skill (§7) y la matriz como control; el par peligroso (`status`/`recap`) se separa nombrándose mutuamente.
- **La sección de ruteo no llega a proyectos ya instalados** (semilla). Documentado; el remedio manual es copiarla al `AGENTS.md` del destino — el instalador nunca lo pisa, por diseño. Se acepta porque la protección viaja igual (§1).
- **Prosa sin suite**: como en el 08, no hay test que congele el comportamiento; la verificación es la matriz leída contra el texto por el reviewer, más las suites de código como no-regresión. Queda registrado honestamente.
- **El interinato es texto con fecha de vencimiento**: si el 10 se posterga, queda como comportamiento vigente (correcto, solo menos ágil); si el 10 llega, hay que borrarlo — está declarado en su superficie, y el criterio de cierre 5 pide que sea reemplazable en un solo lugar.
- **Ruteo al lote sobre-entusiasta**: un pedido vago podría abrir un lote de N features. Mitigación: regla de ambigüedad (fila 13 de la matriz) y el gate de lote, que presenta los N resúmenes antes de cualquier trabajo.

## Review log

(vacío — se completa con cada ronda)
