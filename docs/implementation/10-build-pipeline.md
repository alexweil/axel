# 10 — Pipeline `/build`: unidades tipadas con gate único

## Autorización

- **2026-07-29** — autorizado por el **gate de lote** de `/feature all` (features 08, 09, 10), sin exclusiones ni correcciones de alcance. Ledger de la corrida: [batch-2026-07-29.md](batch-2026-07-29.md); resumen autorizado del 10, ahí. No hay gate individual: el hijo de un lote no re-pide confirmación (contrato del modo lote, skill `feature`).

## Alcance

Nivel 2 del diseño de entrada implícita ([design/implicit-entry.md](../design/implicit-entry.md), §«Nivel 2 — pipeline `/build`»): un pedido que cruza dos o más fases encadena los **deltas** necesarios en una sola corrida, con **un gate al inicio** y **un OK consolidado al final**. El 09 dejó el ruteo funcionando y el destino multifase resuelto por un **interinato** explícito; este feature lo reemplaza.

Entregables:

- **Skill `build` nueva** (payload): validación del pedido, gate de pipeline, ledger, loop del padre orquestador, reentrada del pipeline y RECAP consolidado. Es el **segundo padre** del mismo protocolo padre↔hijo que el lote (§1).
- **Semántica de hijo de pipeline** en `design`, `plan` y `feature`: cada skill de fase gana su sección «Modo hijo de pipeline» — la fase completa sin RECAP ni OK individual, terminando con la línea de estado del contrato. En `design` el ping-pong **no ocurre**: se comprimió en el gate. En `feature`, el Modo hijo existente se parametriza por tipo de corrida (§5).
- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): el bloque del interinato multifase sustituido por el despacho a `/build`; `/build` en la lista de fases y en la gramática posicional de comandos explícitos; y la **regla dura extendida** («ni cruzar a otra fase sin OK — salvo lote o pipeline autorizado»).
- **`description` re-redactadas** de `design`, `plan` y `feature` para desambiguarlas contra `build` — deuda declarada por el 09 (§8), no opcional.
- **Skill `recap`**: RECAP consolidado de pipeline (base `gate_base` del ledger de pipeline) y, en modo POC, los dos caminos post-OK que el diseño fija.
- **Skill `status`** (cuerpo, no `description`): ajuste mínimo para que una consulta durante un pipeline responda de verdad — leer el ledger cuando STATUS apunta a uno y reportar tipo de corrida, unidad en curso y progreso, más el marker de borrador si está (§11).
- **`docs/design/review-contract.md`** (payload): `AXEL_REVIEW_ID` generalizado de «identidad del modo lote» a «identidad de las corridas orquestadas» (lote y pipeline), con el formato de id por unidad; y **«esperando autorización de pipeline»** como quinta espera humana del vocabulario.
- **`scripts/install.sh` + `tests/install.sh`**: `.claude/skills/build/SKILL.md` en la allowlist del payload, con su cobertura. Sin esto la entrada implícita completa **no viaja** a los destinos.
- **Plantilla del ledger de pipeline** (en la skill `build`) y **discriminante `tipo:`** en el bloque Gate de ambos ledgers, con el ledger de la corrida en curso anotado (§3).
- **`docs/IMPLEMENTATION.md`**: fila 10 al día. **`docs/STATUS.md`**: al día en cada commit, con el token de ronda del contrato.

**Fuera de alcance**:

- **`docs/DESIGN.md`**: ya está al día — la fila de decisiones del 2026-07-29, el componente `.claude/skills/` (que ya nombra `/build`), el principio 4 y el párrafo «Entrada implícita» se escribieron en el ciclo de diseño. Este feature no reabre diseño.
- **`scripts/review.sh` y `scripts/awake.sh`**: sin cambios. La generalización de `AXEL_REVIEW_ID` es **de contrato, no de lógica** — `review.sh` ya publica `id=${AXEL_REVIEW_ID:--}` sin interpretar su contenido (línea 110), así que un id `design:r1:<nonce>` funciona hoy sin tocar una línea. Único cambio ejecutable del feature: la allowlist del instalador y su test.
- **El protocolo del lote**: `/feature all` / `NN..MM` no cambia de contrato. El pipeline **no lo invoca** (el diseño prohíbe el lote anidado) y **no reescribe** su máquina de estados: la reusa por referencia con sustituciones declaradas (§1, §6).
- **La `description` de `status`**: no se toca — ya declara ser la única entrada de consulta y no compite con `build` (una consulta nunca es un pedido de trabajo). Su **cuerpo** sí recibe un ajuste mínimo, que pasó a ser alcance en r1 (§11).
- **Overrides de modelo por tipo de unidad**: se resuelve por decisión explícita de no cablearlos (§10), no por implementación.

## Enfoque técnico

### 1. El pipeline es un segundo padre del mismo protocolo, no un protocolo nuevo

El diseño fija que el pipeline **reusa los contratos del lote** generalizando «feature» a **unidad tipada**. La bajada lo baja así:

| Pieza | Lote (`/feature all`) | Pipeline (`/build`) |
|---|---|---|
| **Padre** (gate, ledger, supervisión, empujón, RECAP consolidado) | skill `feature`, §Modo lote | skill `build` (nueva) |
| **Hijo** (la fase completa, con su loop de review) | skill `feature`, §Modo hijo | la skill **de la fase de la unidad**: `design`, `plan` o `feature`, §Modo hijo de pipeline |
| **Señal terminal + identidad** | `review.sh` (contrato) | idéntica, sin cambios |
| **Máquina de reentrada y token de spawn** | skill `feature`, §Reentrada del lote | **la misma tabla**, referenciada desde `build` con las sustituciones de §6 |

**Por qué el hijo vive en la skill de su fase** y no en `build`: es donde ya vive el trabajo. Un design-delta es `/design` sin ping-pong y sin RECAP; un plan-delta es `/plan` sin confirmación liviana y sin RECAP; una unidad de feature es exactamente el Modo hijo que el lote ya usa. Poner el cuerpo en `build` duplicaría tres fases enteras y las haría divergir en la primera corrección.

**Por qué la máquina de reentrada se referencia y no se copia**: es la pieza más delicada del 09 (invariante de ancla única, retiro determinístico, ocho filas, discriminante de protocolo). Ambas skills son payload, así que la referencia resuelve también en un destino instalado. Copiarla garantizaría divergencia; parametrizarla cuesta un bloque de cuatro sustituciones (§6).

### 2. Unidades tipadas: tipos, ids y orden

Tres tipos, con **id de unidad** que es lo que viaja en el ledger, en las anclas y en el id de review:

| Tipo | id | Qué hace el hijo | Skill del hijo |
|---|---|---|---|
| `design-delta` | `design` | consolida en `DESIGN.md` (y `docs/design/*.md`) **solo el delta** que el pedido autorizado necesita | `design` |
| `plan-delta` | `plan` | agrega o reordena en `IMPLEMENTATION.md` **solo** lo que el pedido necesita, priorizando resultado visible temprano | `plan` |
| `feature` | `NN` (el número del plan) | el feature completo, como en el lote | `feature` |

**Orden fijo y cardinalidad**: `design` → `plan` → features en el orden del plan. A lo sumo **una** unidad de cada delta por corrida (el pedido es uno), de donde los ids son únicos por construcción. El orden no es configurable: es la dependencia — el plan-delta lee el diseño que el design-delta acaba de consolidar, y los features leen el plan.

Una corrida puede omitir tipos (pedido que solo necesita plan + feature ⇒ dos unidades). Un pedido que necesita **una sola** unidad no es pipeline: §7.

### 3. Ledger de pipeline y el discriminante de dueño

`docs/implementation/pipeline-YYYY-MM-DD.md` (colisión ⇒ sufijo `-2`, `-3`…). Mismo contrato que el del lote: ruta autorizada con los resúmenes **tal como se autorizaron**, estado por unidad, eventos con token, cortes con motivo, cierre.

```markdown
# Pipeline YYYY-MM-DD — `/build`

## Gate
- tipo: `pipeline`
- protocolo: `spawn-token v1`
- Pedido del humano: «<literal>»
- Modo: `normal` | `POC` (proyecto virgen: docs borrador, feature 01 = esqueleto que camina)
- Autorizado: <fecha> — «<literal breve>» · Ajustes de alcance: <literales, o «ninguno»>
- Resultado visible al final: <qué va a poder ver el humano>
- gate_base: <SHA de HEAD previo al commit que crea este ledger>

## Ruta autorizada
### <id> — <tipo> — <nombre>
<resumen del delta tal como se presentó>

## Estado
| Unidad | Tipo | Estado | SHA inicio | SHA APPROVED |
|---|---|---|---|---|
(pendiente → en curso → APPROVED — pendiente OK de pipeline → cerrada)

## Eventos
- <ts> — <arranque de hijo (con `token=<nonce>`) / APPROVED rN / corte con motivo / …>

## Cierre
- <OK humano (fecha, literal) o corte final>
```

**`tipo:` como discriminante de dueño de la reentrada**, con la misma forma de tres valores que el `protocolo:` del 09 — y por la misma razón: quién es el dueño **se declara, nunca se infiere** del nombre del archivo ni de la prosa del título.

| `tipo:` en el bloque Gate | Dueño de la reentrada |
|---|---|
| `lote` | skill `feature`, §Reentrada del lote |
| `pipeline` | skill `build`, §Reentrada del pipeline |
| ausente, vacío o cualquier otro valor | **corte** — no se asume nada. Recuperación: un humano anota el `tipo:` correcto en el bloque Gate y se relanza |

Los dos esqueletos (el del lote en la skill `feature`, el del pipeline acá) nacen con su `tipo:`. El **único ledger preexistente** es el de la corrida `2026-07-29` que está implementando este feature: **quedó anotado** con `tipo: lote` en su bloque Gate — hecho en la ronda 1 de este ciclo (p1: el doc lo afirmaba antes de que fuera cierto, y con el discriminante instalado la ausencia habría producido el corte que este mismo doc define) —, exactamente como el 09 anotó su `protocolo: legacy`. Es una anotación de compatibilidad declarada, no una inferencia.

Qué protege: que `build` relance un hijo sobre un ledger de lote, o que la reentrada del lote de `feature` consuma un ledger de pipeline. Baja probabilidad, daño real (hijo del tipo equivocado sobre una corrida ajena) y costo de una línea.

### 4. Gate de pipeline y loop del padre

Un solo mensaje con la ruta propuesta —unidades en orden, con tipo y resumen del delta de cada una—, **qué va a haber visible al final**, el modo (`normal` o `POC`) y **una autorización global**. Ajustes puntuales del humano («dale, pero el diseño dejalo como está») se registran como ajustes de alcance. Llega por respuesta directa ⇒ sin push. Fin de turno.

**Asimetría deliberada con el gate de lote**: el lote pone STATUS en «esperando autorización de lote», presenta, y al reabrir **re-deriva** los N resúmenes de `IMPLEMENTATION.md`. El pipeline **no puede**: su ruta se deriva del **pedido del humano**, que vivía en el chat y no está en ningún doc — el mismo problema que el 09 resolvió persistiendo la interpretación de `/plan` en STATUS. Acá la interpretación es demasiado grande para una línea de STATUS, así que se persiste donde corresponde:

1. **Antes de presentar**: crear el ledger con el pedido literal, la ruta propuesta con sus resúmenes, el modo y el resultado visible declarado; `gate_base` = HEAD **previo a este commit**. STATUS → «**esperando autorización de pipeline**» (literal fijo) apuntando al ledger. Commit.
2. Presentar el gate y pedir la autorización. Fin de turno.
3. **Con la autorización**: registrarla en el bloque Gate (fecha, literal, ajustes de alcance) + STATUS → pipeline en curso + commit. `scripts/awake.sh start`.
4. **Si el humano descarta o corrige de raíz**: se registra el descarte en el ledger (`## Cierre`), STATUS vuelve a estable y no queda puntero colgado. Un pedido corregido re-presenta el gate sobre el mismo ledger.

Consecuencia buscada: la **rama de reentrada** re-presenta la ruta **registrada**, no una re-derivada — no hay forma de re-derivarla. Y `gate_base` incluye el commit del gate en el relato del RECAP consolidado, que es donde corresponde: la autorización es parte de la corrida.

La quinta espera humana no lleva contenido en la línea de STATUS (a diferencia de «esperando confirmación de plan»): el contenido está en el ledger, que es versionado. El contrato lo dice así.

**Loop del padre, unidad por unidad** — es el del lote, y la skill lo escribe **completo** (r1 p4: el diseño ya fijó estos contratos y la bajada no puede dejarlos implícitos):

1. **Pre-arranque**: re-derivar el resumen de la unidad de los docs actuales y compararlo en sustancia con el autorizado en el ledger ⇒ **divergencia = corte**; fuentes insuficientes ⇒ corte. Y **renovar la ventana: `scripts/awake.sh start` al arrancar cada unidad** (una corrida larga excede las 12h).
2. **Acuñar el token** (atómica) → **ledger + STATUS + commit** del evento de arranque con `token=` → **spawn** del hijo. El orden es durable: sin evento en el ledger no hubo hijo.
3. **Supervisión**: watcher sobre `.claude/state/review-terminal` esperando **identidad completa** (`id` exacto y, si `review_head` ≠ `-`, también el HEAD), poleo ~15 s, **timeout 45 min**; un terminal que no matchea es residuo y se ignora. Match ⇒ **empujón sin contenido** al hijo. El padre **no transporta feedback**.
4. `UNIDAD <id> APROBADA` ⇒ verificar el estado (doc de la unidad al día, «APPROVED — pendiente OK de pipeline», STATUS, commits presentes, anclas limpias) ⇒ ledger + commit ⇒ unidad siguiente.
5. **Condiciones de corte — las cuatro, completas** (no solo divergencia y timeout): (1) las del loop —deadlock de 5 rondas, exit 2 persistente, veredicto inválido repetido— **más** la ausencia de señal terminal dentro del timeout; (2) cambio de scope o sorpresa que excede la unidad; (3) divergencia contra el resumen autorizado; (4) fuentes insuficientes. En todos: registrar el corte en el ledger (commit restringido por pathspec si el hijo dejó el árbol sucio), RECAP con el estado encontrado, **push de una línea**, fin de turno. Las unidades aprobadas quedan intactas.
6. **Mensajes del humano a mitad de pipeline: prioridad absoluta.** Llegan al padre —que se mantiene liviano justamente para poder conversar—: responde, y si afectan a la unidad en curso los baja **de inmediato** por mensaje al hijo (lo despierta aunque esté esperando una review); si invalidan la unidad o la corrida ⇒ corte.

**Pedido de review acotado al delta** (obligación del hijo, fijada por el diseño): cada unidad pide revisar **el delta contra el pedido autorizado y su escala declarada**, no una pasada completa del proyecto. En modo POC el pedido lo dice con todas las letras: «diseño borrador para POC — revisá que alcance para el esqueleto, no exhaustividad».

### 5. Hijos de pipeline

**Común a los tres tipos** (es el contrato del lote, sin cambios de fondo): el hijo no pide confirmación (el gate ya autorizó) y registra en su doc la autorización (fecha, comando, path del ledger); corre su loop de review completo con `AXEL_REVIEW_ID` y el handshake de señal terminal —termina el turno con `REVIEW LANZADA id=<id> head=<sha>` y lo despierta el padre—; **sin RECAP individual, sin push, sin chip**; al cerrar deja su unidad en «**APPROVED — pendiente OK de pipeline**» y termina con `UNIDAD <id> APROBADA`; ante condición de corte commitea, deja el árbol limpio y termina con `CORTE: <motivo breve>`.

**Procedencia**: idéntica al lote — triple coincidencia (evento vigente del ledger = prompt = ancla) y reclamo por rename, con las anclas de §6. El texto del prompt no otorga el rol.

**Deltas por tipo**:

- **`design-delta` (skill `design`)**: **sin ping-pong**. El diseño lo fija para POC («el ping-pong largo se comprime en el gate») y la regla de confirmación lo generaliza: el gate de pipeline **es** el punto de confirmación de esta unidad. El hijo consolida el delta acotado al pedido autorizado, review `new` → rondas → APPROVED. En modo POC el `DESIGN.md` nace **mínimo y marcado** (§9), y el pedido de review declara la escala: «diseño borrador para POC — revisá que alcance para el esqueleto, no exhaustividad» (decisión del diseño).
- **`plan-delta` (skill `plan`)**: **sin confirmación liviana** — la absorbió el gate (el diseño lo dice explícitamente para `/build` monofase; con más razón dentro del pipeline, donde la ruta entera se autorizó). El delta prioriza que el resultado visible llegue lo antes posible; en modo POC, feature 01 = esqueleto que camina.
- **`feature` (skill `feature`)**: el Modo hijo que ya existe, **parametrizado por el `tipo:` del ledger** — un bloque de **cinco** sustituciones en la propia skill `feature`: ledger, anclas, identidad de unidad, cierre/estado, y **la autorización que el hijo registra** (gate de pipeline en vez de gate de lote). No confundirlas con las **cuatro** de §6, que son otra tabla y otro destinatario: aquellas parametrizan la **máquina de reentrada** que `build` referencia. Nada más cambia.

**Guardas de `design` y `plan`**: hoy tratan «feature/lote activo» como estado **ajeno sin excepción**, que era correcto mientras esas skills nunca eran hijas de nada. Ahora pueden serlo, y la excepción **no puede apoyarse en el texto del prompt** (r1 p3 del 09). Se define sobre la **procedencia probada**: el estado de un pipeline no es ajeno a la skill de la fase de la unidad en curso **cuando el token de spawn reclama** —evento vigente = prompt = ancla, y `unit` del ancla = el id de la unidad—; sin token válido es ajeno, y la skill entra por la reentrada de la dueña sin tocar nada. Una sesión que reproduzca el prompt sin token no pasa la guarda.

### 6. Reentrada del pipeline: la misma máquina, cuatro sustituciones

`build` no reescribe la máquina de estados: declara las sustituciones y **referencia** la §Reentrada del lote de la skill `feature` (payload, presente en todo destino).

| En el lote | En el pipeline |
|---|---|
| ledger `docs/implementation/batch-*.md`, `tipo: lote` | ledger `docs/implementation/pipeline-*.md`, `tipo: pipeline` |
| anclas `.claude/state/batch-child-token{,.claimed-T,.retired-T}` y `.claude/state/batch-expected` | `.claude/state/pipeline-child-token{,.claimed-T,.retired-T}` y `.claude/state/pipeline-expected` |
| identidad de unidad `feature=NN`; cierre `FEATURE NN APROBADO` | identidad `unit=<id>`; cierre `UNIDAD <id> APROBADA` |
| doc de la unidad = `docs/implementation/NN-*.md` (con su Review log) + fila de `IMPLEMENTATION.md` | **según el tipo** (abajo) |

**Cuarta sustitución: dónde vive la memoria de la unidad** (r1 p3 — sin esto la máquina referenciada, escrita en vocabulario de feature, no se aplica literalmente a un design-delta ni a un plan-delta). La sección referenciada dice «doc del feature», «IMPLEMENTATION», «estado local del feature en curso»; leída desde el pipeline, cada aparición se resuelve por el tipo de la unidad:

| Tipo | Doc de la unidad | Memoria del ciclo de review | Estado que la reentrada consulta |
|---|---|---|---|
| `design-delta` | `docs/DESIGN.md` (+ `docs/design/*.md` que el delta toque) | las **líneas de commit del ciclo, que nombran la ronda** (`design` no tiene Review log propio — regla vigente de la skill) | ledger + STATUS + `.claude/state/` |
| `plan-delta` | `docs/IMPLEMENTATION.md` | ídem (`plan` tampoco tiene Review log propio) | ídem |
| `feature` | `docs/implementation/NN-*.md` + fila de `IMPLEMENTATION.md` | el **Review log** del doc del feature | ídem |

«Estado local **del feature** en curso» (`codex-session-id`, `round`) se lee como «de la **unidad** en curso»: es el mismo estado local, que por construcción pertenece a una sola unidad a la vez.

**Esquema exacto de `.claude/state/pipeline-expected`** (mismo contrato que `batch-expected`, con la identidad generalizada), escritura atómica (tmp + `mv -f`):

```
id=<unidad>:r<M>:<nonce>
head=<sha del HEAD del hijo al lanzar>
unit=<id>
phase=launched|consumed
```

Y `.claude/state/pipeline-child-token`: `unit=<id>`, `token=<nonce>`, `spawned_at=<ts>`; reclamada por rename a `pipeline-child-token.claimed-<token>`, retirada a `.retired-<token>`.

Todo lo demás es literal: corte **absorbente** primero (un corte sin resolución humana no se relanza aunque el ancla matchee), la máquina de `*-expected` (`launched` + terminal de identidad completa ⇒ relanzar; `launched` sin terminal ⇒ no relanzar, RECAP; `consumed` ⇒ consistencia normal; ancla ausente ⇒ solo cuenta si el resto del estado local es coherente), la tabla de ocho filas del token con el invariante de ancla única y el retiro determinístico, el **orden durable completo** en todo relanzamiento (retirar → acuñar → evento + STATUS + commit → spawn), y «nunca re-pedir el gate autorizado ni re-cerrar lo aprobado».

**Las dos máquinas se aplican en conjunción, en este orden** (r2 p3, acotado en r3 p3): corte absorbente → máquina de `*-expected` → **tabla del token**. Relanzar exige que **las dos** autoricen, y **la acción concreta la determina la fila del token**, que no es única: con `claimed-<T>` + evento `T` hay que **retirar** antes de re-acuñar (es el caso de D13), mientras que con un ancla **pendiente sin evento** —caída entre acuñar y commitear, sin spawn— se **descarta la huérfana** y se repite el orden durable, sin retiro que hacer. Lo que ninguna fila permite es concluir desde `phase=consumed` sola: eso establece únicamente que *no hay review en vuelo ni desenlace pendiente*, y saltar de ahí a «hijo fresco» es el atajo que la reentrada prohíbe.

**Por qué anclas con nombre propio** en vez de reusar las del lote: los namespaces disjuntos evitan que un residuo de una corrida de otro tipo dispare el «más de una ancla activa ⇒ RECAP» de la corrida vigente, y evitan que un archivo llamado `batch-*` gobierne un pipeline. El invariante de ancla única sigue siendo **por corrida**, que es como está escrito.

Ramas de reentrada de `build`, además de las de la máquina:

- STATUS «**esperando autorización de pipeline**» ⇒ re-presentar la ruta **registrada en el ledger** (no re-derivarla) y esperar. Respuesta directa ⇒ sin push.
- STATUS «esperando OK humano» con ledger de pipeline ⇒ re-presentar el RECAP consolidado pendiente; con el OK, cierre consolidado (excepción del commit de registro del OK).
- Inconsistencia (ledger contra git o contra los docs) ⇒ RECAP sin adivinar.

### 7. Ruteo: `/build` reemplaza el interinato, y validación del pedido

El 09 declaró el interinato como **un solo bloque semántico**: el párrafo «Multifase (interino, hasta que exista `/build`)» de §Ruteo en `AGENTS.md` y su espejo literal en la plantilla. Este feature lo sustituye por el despacho a `/build`, sin tocar ningún otro texto del 09. Además —superficie propia ya declarada— `/build` entra en la lista de fases del proceso y en la **gramática posicional** de comandos explícitos (el 09 ya la escribió con el paréntesis «y `/build` cuando exista»).

**Validación del pedido** (fail-closed, la decide `build` antes de escribir nada):

| Pedido | Qué hace `build` |
|---|---|
| **vacío** (`/build` sin argumento) | no hay pedido que rutear: **pregunta en una línea** qué querés construir. No asume «seguí con lo que hay» — eso es `/feature` |
| **que no toca ninguna fase** (consulta, charla, algo fuera del método) | no hay pipeline: entrega a `/status` si era consulta; si no, pregunta |
| **monofase** | **despacho directo** a la skill de esa fase con su punto de confirmación (y `/plan` con su confirmación liviana): `/build` **no cuenta como autorización** — la autorización es siempre de un gate. No se crea ledger |
| **con una premisa factual refutada por los docs** | lo dice y **pregunta**, sin arrancar |
| **multifase, estado estable** | gate de pipeline (§4) |

**La categoría es angosta a propósito, y se define por dos exclusiones** (r1 p2, acotada en r2 p2):

- **«Todavía no planificado» no es contradicción.** Un pedido de trabajo que el plan no contiene es el caso multifase normal que el diseño fija —«implementá X» con backlog vacío necesita un plan-delta antes de implementar ⇒ `/build`— y es la fila C2/C14. La contradicción es sobre lo **registrado**, no sobre lo ausente.
- **Pedir cambiar lo registrado tampoco es contradicción: es el trabajo.** «Cambiá cómo funciona el review» contradice `DESIGN.md` por definición y es exactamente un **design-delta legítimo** (fila C15). Un método que tratara eso como contradicción no podría evolucionar nunca.

Lo que queda es angosto y verificable: el pedido **afirma como hecho** algo que los docs registran de otro modo — «el feature 05 nunca se hizo, implementalo» contra una tabla que lo marca **Cerrado**. No se corrige ni se reinterpreta en silencio (ninguna de las dos lecturas es segura: puede ser un pedido de rehacerlo, o el humano mirando otro repo): se nombra el hecho registrado y se pregunta. Y si lo que el pedido choca es **estado pendiente**, no decide esta tabla: manda el paso 2 del orden de despacho (abajo).

**`/build` explícito no puentea estado pendiente** — asimetría fijada por el diseño y única entre los comandos: los demás comandos de fase explícitos conservan el contrato de hoy (informan el estado ajeno en una línea y sigue mandando el humano), pero `/build` entra por la reentrada de la skill dueña. La razón es que `/build` **encadena**: dejarlo arrancar sobre una espera abierta propagaría la espera sin resolver a través de N unidades. Su **guarda de entrada** lo hace valer desde el payload, aunque §Ruteo falte en el destino.

### 8. Regla dura y descripciones

**Regla dura extendida** (`AGENTS.md` + plantilla, regla de sincronía), redacción del diseño: «nunca continuar a otro feature **ni cruzar a otra fase** sin OK humano — salvo dentro de un **lote o pipeline autorizado**: la autorización del gate habilita encadenar las unidades autorizadas (cada una queda «APPROVED — pendiente OK de lote/pipeline») y el OK del RECAP consolidado es el que cierra».

**Descripciones**: el 09 declaró que agregar solo la `description` de `build` no vuelve disjuntos los triggers — «quiero una app de recetas» matchea el trigger de `design` tanto como el de `build`, y en un destino sin §Ruteo compiten sin desempate. El discriminante que ahora **sí** se puede escribir, porque el destino existe:

- **`build`**: el pedido necesita **dos o más fases** (o el proyecto está virgen y hay que ir de la visión a algo visible).
- **`design`**: el pedido necesita **solo** rumbo/diseño — y nombra que si además hay que planificar e implementar, es `build`.
- **`plan`**: el pedido necesita **solo** decidir qué hacer y en qué orden.
- **`feature`**: el pedido necesita **solo** implementar lo ya planificado.

Las `description` de `status` y `recap` **no** se tocan: su par ya está separado por el 09 y ninguno compite con `build` (una consulta o un pedido de checkpoint nunca es un pedido de trabajo multifase). Lo que sí cambia —y solo eso— es el **cuerpo** de `status`, por la razón de §11: no lee el ledger, así que durante una unidad `design`/`plan` respondería sin ubicar. `recap` no cambia de `description` **ni** de cuerpo por esta razón; su cambio es otro, el del RECAP consolidado de pipeline (alcance).

### 9. POC-first: el marker y la pasada que lo cierra

**Marker**: una línea literal al tope del doc, inmediatamente bajo el `#`, con el texto exacto **`borrador (modo POC)`** — greppable y legible:

```markdown
> **Estado: borrador (modo POC)** — escrito por `/build` el <fecha> para llegar al POC; endurecer con `/design` (o `/plan`) cuando el POC esté a la vista.
```

Lo escribe el hijo de la unidad correspondiente cuando el ledger declara `Modo: POC`: en `DESIGN.md` la unidad `design`, en `IMPLEMENTATION.md` la unidad `plan`. **La pasada que lo cierra** es una pasada normal de `/design` o `/plan`: si el doc que consolida trae el marker y esta pasada lo endurece, **borra la línea** al consolidar; si no lo endurece (delta acotado a otra cosa), la deja. Una línea en cada skill.

**Post-OK, recomendado y no forzado** (decisión del diseño): el RECAP consolidado de un pipeline en modo POC ofrece los dos caminos —endurecer (`/design`/`/plan`, que cierran el marker) o seguir iterando features sobre el borrador— y elige el humano con el POC a la vista.

### 10. Modelos por unidad: decisión de no cablearlos

El diseño deja «overrides de modelo por tipo de unidad» para la bajada. Decisión: **no se cablean**. En axel el esquema de modelo por fase es una **elección del humano en la sesión** (`AGENTS.md` §Roles lo dice así), no una regla de la maquinaria; cablear «design-delta ⇒ modelo X» en una skill que es payload exportaría las preferencias de hoy de axel a todos los proyectos destino y quedaría desactualizada sin que nadie la mire. El padre lanza cada hijo con el modelo por defecto de la sesión, y si el humano quiere otro para un tipo de unidad lo dice en el gate: queda registrado como ajuste de alcance en el ledger y el padre lo aplica al spawnear. Cero código, cero desactualización silenciosa, y el control donde el método ya lo pone.

### 11. Instalador, contrato y `status`

- **`scripts/install.sh`**: `.claude/skills/build/SKILL.md` se agrega a `PAYLOAD_SRC` y `PAYLOAD` (arrays paralelos). Es la línea sin la cual la entrada implícita **no viaja**: `AGENTS.md` es semilla, así que en un destino ya instalado la §Ruteo nueva no llega — pero la skill `build`, su `description` y su guarda sí, por payload. **`tests/install.sh`**: `build` entra en el loop de aserciones de T1 (línea 78), que es el que verifica que el payload completo aterriza.
- **`docs/design/review-contract.md`** (payload):
  - `AXEL_REVIEW_ID` deja de declararse «identidad de invocación del modo lote de `/feature`» y pasa a ser la identidad de las **corridas orquestadas** —modo lote de `/feature` y pipeline de `/build`—, con formato `<unidad>:r<M>:<nonce>` donde la unidad es `NN` (feature), `design` o `plan`. **Sin cambio de lógica**: `review.sh` publica el valor sin interpretarlo. Se conserva intacto el resto: fuera de una corrida orquestada `id=-`, y ese terminal es el que consume la reentrada individual.
  - Vocabulario de la línea «Esperando»: **«esperando autorización de pipeline»** como quinta espera humana, con la nota de que su contenido vive en el ledger (versionado) y no en la línea.
- **Skill `status`** (r1 p5 — el deslinde original no estaba demostrado): su cuerpo hoy pide reportar «fase, **feature** en curso, ronda, veredicto, qué se espera» y **no** menciona el ledger. Durante una unidad `design` o `plan` de un pipeline no hay feature en curso, así que el despacho correcto a `/status` (fila C12) daría igual una respuesta que no ubica al humano. Ajuste mínimo, dos añadidos: **si STATUS apunta a un ledger** (de lote o de pipeline), leerlo y reportar tipo de corrida, unidad o feature en curso y progreso (unidades cerradas / pendientes); y si `DESIGN.md` o `IMPLEMENTATION.md` traen el marker **«borrador (modo POC)»**, decirlo. Sigue siendo lectura pura. Se elige esto sobre la alternativa —exigirle a STATUS que duplique la información del ledger— porque duplicar estado versionado invita a que las dos copias diverjan, y el ledger ya es la fuente.

## Matrices de verificación

Como en el 08 y el 09 no hay harness de despacho: el comportamiento lo ejecuta un modelo leyendo texto. La verificación son estas dos matrices, y **cada fila debe resolverse contra el texto final instalado** —§Ruteo de `AGENTS.md`, una `description`, o la guarda/sección de una skill—, sin apelar a este doc.

### Matriz C — despacho con `/build`

Reemplaza y extiende las filas del interinato de la matriz A del 09 (10, 14, 18); las demás filas de aquella matriz siguen valiendo sin cambios.

| # | Estado en STATUS | Pedido | Destino esperado | Regla que decide |
|---|---|---|---|---|
| C1 | estable, `DESIGN.md` es solo la semilla | «quiero una app para organizar recetas» | `/build` en **modo POC**: gate con la ruta design→plan→feature 01 y el POC como resultado visible | paso 3 + §4/§9 |
| C2 | estable, backlog vacío | «implementá el export a CSV» | `/build`: gate con ruta plan-delta → feature | paso 3 + §2 |
| C3 | estable | «cambiá cómo funciona el review y después implementalo» | `/build`: gate con ruta design→plan→feature | paso 3 |
| C4 | estable, diseño cerrado sin plan | «bajá esto a plan» | **monofase** ⇒ `/plan` con confirmación liviana; **no** hay ledger ni gate de pipeline | §7 |
| C5 | estable, plan con pendientes | «dale con lo que sigue» | `/feature` (gate de arranque) — monofase | §7 + `description` de `feature` |
| C6 | estable | `/build` **sin argumento** | pregunta de una línea; no crea ledger | §7 |
| C7 | estable | `/build ¿cómo viene esto?` | no toca ninguna fase ⇒ entrega a `/status` | §7 |
| C8 | **esperando OK humano** (feature cerrado) | `/build` **explícito** con un pedido multifase | **no arranca**: entra por la reentrada de la dueña (`/feature`, re-presenta el RECAP). Único comando explícito que no puentea | §7 + guarda de `build` |
| C9 | lote en curso | «armá una app nueva encima de esto» | reentrada de `feature` (lote activo manda), no `build` | paso 2 |
| C10 | estable | «hacé todos los pendientes de corrido» | `/feature all` (lote), **no** `/build`: una sola fase | §7 + §6 del 09 |
| C11 | **esperando autorización de pipeline** | «dale» en sesión fresca | `/build` → re-presenta la ruta **registrada en el ledger**; con el sí, arranca | paso 2 + §6 |
| C12 | pipeline en curso, unidad `design` en su ronda 2 | «¿dónde estamos?» | `/status` (la consulta precede a todo), **y su respuesta identifica** corrida de pipeline, unidad en curso y progreso — no «feature en curso: —» | paso 1 + §11 |
| C13 | estable, la tabla del plan marca el feature 05 **Cerrado** | `/build el feature 05 nunca se hizo: implementalo y actualizá el diseño` (**explícito**, y multifase por su forma — llega a la validación de `build` sin pasar por el despacho) | **premisa factual refutada**: nombra el hecho registrado (05 Cerrado) y **pregunta**; no abre gate ni despacha a `/feature` | §7, validación |
| C14 | estable, backlog vacío | «implementá el export a CSV» | **no** es contradicción sino multifase: gate de pipeline con ruta plan-delta → feature (es C2; queda acá el contraste explícito) | §7 |
| C15 | estable, `DESIGN.md` registra «review por sesión única de Codex»; **el plan no tiene un feature para ese cambio** | «cambiá eso: que cada ronda abra sesión nueva, y después implementalo» | **no** es contradicción: pedir cambiar lo registrado **es** el trabajo ⇒ `/build` con ruta **design-delta → plan-delta → feature** (el plan-delta hace falta porque el feature todavía no existe — misma derivación que C3) | §7, segunda exclusión + §2 |
| C16 | pipeline **en modo POC** cerrado, `DESIGN.md` con el marker `borrador (modo POC)` | «¿cómo viene esto?» | `/status`, que además **dice el marker** y que el endurecimiento sigue pendiente | paso 1 + §11 |

### Matriz D — pipeline: unidades, cortes y defensas

| # | Situación | Qué debe pasar | Regla que decide |
|---|---|---|---|
| D1 | gate autorizado, unidad `design` arranca | hijo fresco de la skill `design`, **sin ping-pong**, review `new`, cierre con `UNIDAD design APROBADA` y estado «APPROVED — pendiente OK de pipeline» | §5 |
| D2 | unidad `plan` arranca tras el design-delta | hijo de la skill `plan`, **sin confirmación liviana** (la absorbió el gate) | §5 |
| D3 | unidad de feature `03` dentro del pipeline | hijo de la skill `feature`, §Modo hijo de pipeline, con sus **cinco** sustituciones (las de §6 son otras: parametrizan la reentrada); **no** se abre un lote anidado | §1 + §6 |
| D4 | el design-delta aprobado invalidó el resumen autorizado del plan-delta | **corte por divergencia** al arrancar la unidad: RECAP + push + corte en el ledger; las unidades aprobadas quedan intactas | condiciones de corte del lote + divergencia |
| D5 | el padre no ve señal terminal en 45 min | corte por timeout (condición 1), sin adivinar | contrato de la señal terminal |
| D6 | prompt «Modo hijo del pipeline: unidad design, token T» con ledger `tipo: pipeline`, evento vigente `token=T` y ancla `pipeline-child-token` con `unit=design`, `token=T` | triple coincidencia ⇒ gana el rename y trabaja; cualquier diferencia entre los tres ⇒ **corte sin reclamar** | §5 + §6 |
| D7 | mismo prompt **replayado** (ancla ya reclamada) | no adopta el rol (ENOENT) ⇒ entra por la reentrada del pipeline | §6 |
| D8 | ledger con `tipo:` **ausente o desconocido** | **corte**, con la instrucción de recuperación (un humano anota el `tipo:` y se relanza). La ausencia no habilita nada | §3 |
| D9 | `build` encuentra un ledger `tipo: lote` en curso | no es suyo: entrega a `/feature` (dueña) sin relanzar | §3 |
| D10 | reentrada del pipeline sobre un ledger con **corte registrado** sin resolución humana | corte **absorbente**: no relanza aunque ancla y terminal matcheen; re-presenta el RECAP del corte | §6 |
| D11 | fin del pipeline | ledger con estados finales + STATUS «esperando OK» + RECAP consolidado (base `gate_base`, por unidad, no-revisados listados) + push + fin de turno | §4 + skill `recap` |
| D12 | OK del RECAP consolidado en modo POC | cierre consolidado (unidades a «Cerrada», ledger cerrado, STATUS) **y** los dos caminos post-OK ofrecidos: endurecer o seguir iterando | §9 + excepción del commit de registro del OK |
| D13 | reentrada del pipeline sobre la unidad `design`, con el **estado completo**: ledger sin corte pendiente; ancla activa **única** `pipeline-child-token.claimed-<T>`; **evento vigente** de la unidad con `token=T`; `pipeline-expected` legible, **con `unit=design`** (el de esta unidad, no un residuo de otra) y `phase=consumed` | **la única combinación que autoriza relanzar** acá: retirar (`mv …claimed-T …retired-T`) → acuñar `U` → registrar el evento vigente con `token=U` + STATUS → **commit** → spawn con `U`. El hijo fresco reconstruye lo ya atendido de **`DESIGN.md` + las líneas de commit del ciclo, que nombran la ronda** (design no tiene Review log) — jamás reprocesa a ciegas | §6: máquina del token (fila `claimed-T` + evento `T` + expected legible) **y** máquina de `*-expected` |
| D13b | misma unidad, `phase=consumed`, pero ancla **pendiente** `T` con evento `T` (o ancla ausente, o `claimed-<T>` sin evento `T`, o dos anclas activas, o un `pipeline-expected` de **otra** unidad) | **no relanzar**: `phase=consumed` prueba que no hay review en vuelo, **no** resuelve el token. Ambigüedad o inconsistencia ⇒ RECAP con la evidencia | §6: la tabla del token decide, no `*-expected` sola |
| D13c | ancla **pendiente** `T` **sin** evento con `T` en el ledger (el padre cayó entre acuñar y commitear ⇒ no hubo spawn) | **sí** se relanza, por una fila distinta: **descartar la huérfana** (no hay nada que retirar) y repetir el orden durable completo | §6: la acción la fija la fila del token |
| D14 | mensaje del humano a mitad de pipeline | **prioridad absoluta**: el padre responde y, si afecta a la unidad en curso, lo baja de inmediato por mensaje al hijo (lo despierta aunque espere una review); si invalida la unidad o la corrida ⇒ corte | §4, paso 6 |
| D15 | una unidad llega a **deadlock** (5 rondas sin converger) o a exit 2 persistente / veredicto inválido repetido | **corte** (condición 1), **sin reintentar** el deadlock: RECAP con las dos posturas + push; el desempate lo da el humano y sigue `reset-deadlock` | §4, paso 5 |
| D16 | arranque de cada unidad | `scripts/awake.sh start` renovado antes del spawn | §4, paso 1 |
| D17 | pedido de review de cualquier unidad | acotado **al delta autorizado y su escala declarada**, no a una pasada completa; en modo POC lo declara explícitamente | §4, cierre |

## Criterios de cierre

1. Existe `.claude/skills/build/SKILL.md` con: guarda de entrada (incluida la asimetría de `/build` explícito), validación del pedido en sus cinco casos —con «todavía no planificado» tratado como multifase y **no** como contradicción—, gate de pipeline con el ledger creado **antes** de presentar, y el **loop del padre completo**: pre-arranque con divergencia y fuentes insuficientes, `awake.sh start` al arrancar **cada** unidad, acuñado del token en el orden durable, supervisión por señal terminal con timeout de 45 min, empujón sin contenido, **las cuatro condiciones de corte enteras** (las del loop —deadlock, exit 2 persistente, veredicto inválido repetido— más timeout, cambio de scope, divergencia y fuentes insuficientes), **mensajes del humano con prioridad absoluta** bajados al hijo, reentrada del pipeline y cierre con RECAP consolidado.
2. La máquina de reentrada y el token de spawn **no están duplicados**: `build` declara las **cuatro** sustituciones (ledger, anclas, identidad/cierre, y doc/memoria de la unidad **por tipo**, con el esquema exacto de `pipeline-expected`) y referencia la §Reentrada del lote de `feature`, que **no cambió de contrato**. Cada aparición de «doc del feature», «IMPLEMENTATION» y «estado local del feature» de la sección referenciada tiene resolución escrita para `design-delta` y `plan-delta`. El `diff` de la skill `feature` se limita a: el bloque de parametrización del Modo hijo, `tipo: lote` en el esqueleto del ledger, la `description`, y la guarda para el caso hijo-de-pipeline.
3. `design`, `plan` y `feature` tienen «Modo hijo de pipeline» con la línea de estado del contrato, sin RECAP ni OK individual; en `design` el ping-pong no ocurre y en `plan` no hay confirmación liviana, con la razón escrita (el gate las absorbió); **cada una pide su review acotada al delta autorizado y su escala declarada** (modo borrador incluido). Las guardas de `design` y `plan` admiten el estado de pipeline **solo** con token de spawn reclamado — nunca por el texto del prompt.
4. `AGENTS.md` y `templates/AGENTS.md` son espejo literal (`diff` de las secciones tocadas vacío) y contienen: `/build` en las fases, `/build` en la gramática posicional, el despacho multifase a `/build` **en el mismo bloque** que ocupaba el interinato (que ya no existe en ninguno de los dos archivos), y la regla dura extendida a «ni cruzar a otra fase».
5. Las cuatro `description` (`build`, `design`, `plan`, `feature`) son disjuntas por el discriminante monofase/multifase: **ninguna fila de la matriz C admite dos ganadoras**, y las de `design`/`plan`/`feature` nombran el destino multifase — la deuda que el 09 declaró queda saldada.
6. El ledger de pipeline tiene plantilla en la skill, con `tipo: pipeline`, `protocolo: spawn-token v1`, pedido literal, modo, resultado visible y `gate_base`; el esqueleto del lote tiene `tipo: lote`; el ledger de la corrida `2026-07-29` está anotado. El discriminante de tres valores corta ante ausencia o valor desconocido.
7. `docs/design/review-contract.md` generaliza `AXEL_REVIEW_ID` a las corridas orquestadas con el formato por unidad, sin cambio de lógica en `review.sh` (`git diff` de `scripts/` **vacío**), y suma «esperando autorización de pipeline» al vocabulario de esperas.
8. `scripts/install.sh` lleva `.claude/skills/build/SKILL.md` en los dos arrays del payload y `tests/install.sh` lo verifica. Las **tres suites** (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión.
9. La skill `status` sigue siendo lectura pura y, con STATUS apuntando a un ledger, su respuesta identifica **tipo de corrida, unidad o feature en curso y progreso** (fila C12); y con el marker `borrador (modo POC)` presente en `DESIGN.md` o `IMPLEMENTATION.md`, lo **dice** (fila C16). Las dos filas se resuelven contra el cuerpo instalado de la skill.
10. Las dos matrices se resuelven **enteras** contra el texto final instalado, sin apelar a este doc.

## Riesgos

- **Superficie de prosa grande sin suite que la congele**: el feature toca seis skills, dos `AGENTS.md`, el contrato y el instalador, y solo lo último es verificable por test. Mismo riesgo que el 08 y el 09, un escalón más arriba. Mitigación: las matrices como control de lectura, la referencia (en vez de copia) de la máquina de reentrada, y el `diff` acotado de `feature` como criterio explícito.
- **Referencia cruzada entre skills**: `build` depende de que la §Reentrada del lote de `feature` esté presente y no cambie de forma. Si un feature futuro la reescribe, `build` queda apuntando a algo distinto. Mitigación: la referencia nombra la sección y las sustituciones exactas, y el criterio 2 fija que el contrato del lote no cambia acá. Alternativa descartada: mudar la máquina a un doc payload propio — mueve superficie del instalador y desarma la cohesión de la skill que la ejecuta.
- **Radio de propagación del pipeline** (aceptado por el diseño): un error del design-delta invalida el plan y los features, y en proyecto virgen puede ser la corrida completa. Lo acotan el gate explícito, el corte por divergencia entre unidades y que el camino con OK por fase sigue disponible. Sin rollback automático: el humano decide con el RECAP a la vista.
- **El gate concentra toda la validación humana de una corrida multifase**: es más carga cognitiva en un solo mensaje que la del lote (donde cada resumen sale de un plan ya aprobado). Mitigación: el gate declara **qué habrá visible al final**, que es lo que el humano puede juzgar sin leer los deltas; y los ajustes de alcance quedan registrados.
- **Modo POC = docs deliberadamente flojos**: un `DESIGN.md` borrador aprobado por Codex «para el esqueleto» puede quedar como diseño de facto si nadie endurece. Mitigación: el marker literal queda visible en el doc hasta que una pasada lo borre, y el RECAP consolidado ofrece el endurecimiento como primer camino. Aceptado por el diseño: recomendado, no forzado.
- **`/build` explícito se comporta distinto de los demás comandos explícitos** (no puentea estado pendiente). Es una asimetría que un humano puede no esperar. Mitigación: está fijada por el diseño, escrita en §Ruteo y en la guarda de la skill, y el caso se resuelve informando qué se encontró — no en silencio.
- **Dos discriminantes declarativos en el mismo bloque Gate** (`tipo:` y `protocolo:`): más superficie para que una corrida nazca malformada. Mitigación: los dos esqueletos los traen escritos, y los dos cortan fail-closed con instrucción de recuperación — una corrida malformada no avanza en silencio.

## Review log

### r1 (base `ee20a57`, HEAD `490c833`) — CHANGES_REQUESTED · 5 puntos, los 5 aceptados

Codex aprobó de entrada las decisiones de fondo (ledger propio, segundo padre, gate persistido antes de presentar, POC, no cablear modelos) y dos de los tres deslindes (`DESIGN.md`, `review.sh`). Lo que pidió:

1. **El ledger vivo no tenía `tipo: lote`** aunque el doc lo afirmaba y el criterio 6 lo exigía. Aceptado y **hecho en esta ronda**: anotado en el bloque Gate de `batch-2026-07-29.md`, con la referencia al p1. El doc pasa a decir lo que es cierto (§3).
2. **Contradicción interna en la validación del pedido**: la fila «contradictorio con STATUS» contaba como contradicción pedir algo que el plan no tiene, pero eso es exactamente el caso multifase que el diseño fija y que la matriz resuelve como gate de pipeline. Aceptado: la fila se reescribe sobre **estado registrado** (feature ya Cerrado, decisión asentada en `DESIGN.md`) y se separa explícitamente de «todavía no planificado»; entran las filas **C13** (contradicción real) y **C14** (el contraste).
3. **Las tres sustituciones no alcanzaban** para aplicar literalmente la máquina de reentrada a `design` y `plan`: la sección referenciada habla de «doc del feature», `IMPLEMENTATION` y «estado local del feature». Aceptado: se agrega la **cuarta sustitución** —doc y memoria del ciclo **por tipo de unidad**, con `design`/`plan` resolviendo a `DESIGN.md`/`IMPLEMENTATION.md` y a las líneas de commit que nombran la ronda (no tienen Review log)— más el **esquema exacto** de `pipeline-expected` y `pipeline-child-token`, y la fila **D13** que congela la reentrada `phase=consumed` de una unidad `design`.
4. **Los criterios permitían cerrar omitiendo contratos que el diseño ya fijó**: mensajes del humano con prioridad absoluta, **todas** las condiciones de corte (no solo divergencia y timeout), `awake.sh` por unidad y pedido de review acotado al delta y su escala. Aceptado: §4 pasa a ser «Gate de pipeline y loop del padre» con los seis pasos del padre escritos, el criterio 1 los exige enteros, el criterio 3 suma el pedido acotado, y entran las filas **D14–D17**.
5. **El deslinde de `status` no estaba demostrado**: su cuerpo pide reportar «feature en curso» y no lee el ledger, así que durante una unidad `design`/`plan` el despacho correcto daría una respuesta que no ubica. Aceptado: entra un ajuste mínimo al cuerpo de `status` (leer el ledger si STATUS apunta a uno; decir el marker de borrador), con el criterio **9** y la fila **C12** reforzada. Se prefirió eso a duplicar el ledger en STATUS: dos copias de estado versionado divergen.

### r2 (base `ee20a57`, HEAD `cf95ef4`) — CHANGES_REQUESTED · 4 ajustes contractuales, los 4 aceptados

Codex dio por incorporados los cambios de fondo de r1 y verificó que la anotación `tipo: lote` existe en el ledger vivo. Los cuatro ajustes:

1. **Cuatro referencias residuales a «tres sustituciones»** contradecían la cuarta recién agregada y el criterio 2. Aceptado: §1, §5, el título de §6 y D3 pasan a «cuatro», con la aclaración de que en una unidad de feature la cuarta se resuelve trivialmente (su doc es el del feature, como en el lote).
2. **C13 no llegaba a la validación de `build`** —«implementá el feature 05» parece monofase y podía despachar a `/feature` antes de ejecutar §7—, y la categoría era demasiado ancha: «pedir lo contrario de una decisión de `DESIGN.md`» es un design-delta legítimo, no una contradicción. Aceptado en las dos mitades: C13 pasa a ser `/build` **explícito** con forma multifase, la categoría se acota a **premisa factual refutada por los docs** y se define por dos exclusiones escritas (ausencia ≠ contradicción; pedir cambiar lo registrado **es** el trabajo), con la fila **C15** congelando el caso legítimo.
3. **D13 subespecificada**: `phase=consumed` prueba que no hay review en vuelo, pero no resuelve el token. Aceptado: D13 declara el **estado completo** que autoriza relanzar (sin corte pendiente + ancla única `claimed-<T>` + evento vigente `token=T` + expected legible en `consumed`) y el orden durable que sigue; entra **D13b** con los vecinos que **no** autorizan (pendiente ambigua, ancla ausente, `claimed` sin evento, dos anclas); y §6 fija explícitamente que las dos máquinas se aplican **en conjunción y en orden**, porque concluir «hijo fresco» desde `phase=consumed` sola es el atajo que la reentrada prohíbe.
4. **El criterio 9 exigía el marker POC pero C12 no lo cubría.** Aceptado: entra la fila **C16** (pipeline en modo POC cerrado, docs con marker ⇒ `/status` lo dice) y el criterio 9 se reparte entre C12 (tipo de corrida, unidad, progreso) y C16 (marker).

### r3 (base `ee20a57`, HEAD `beba891`) — CHANGES_REQUESTED · 3 contradicciones internas, las 3 aceptadas

Codex dio por cerradas las cuatro de r2 y por suficientemente angosta la categoría de §7 (C13/C14/C15 sin doble ganadora). Lo que quedaba eran contradicciones del propio doc:

1. **§8 seguía diciendo que `status` «no se toca»**, contra el alcance, §11 y el criterio 9. Aceptado: la frase distingue ahora **`description` vs. cuerpo** — no cambian las `description` de `status` ni de `recap`; sí el **cuerpo** de `status` (§11), y el cambio de `recap` es otro (el RECAP consolidado), no este.
2. **C15 saltaba el plan-delta**: la precondición no declaraba un feature pendiente para ese cambio, así que por la derivación normativa —y por analogía con C3— la ruta es `design-delta → plan-delta → feature`. Aceptado: se corrige la ruta y se explicita en la precondición que el plan **no** tiene ese feature.
3. **El párrafo de conjunción de §6 universalizaba la rama `claimed-T`**: presentaba «ancla activa + evento coincidente + retiro» como requisito de todo relanzamiento, cuando la tabla canónica también autoriza recuperar con un **ancla pendiente sin evento** (caída entre acuñar y commitear, sin spawn) descartándola, sin retiro. Aceptado: el párrafo pasa a decir que **las dos máquinas deben autorizar** y que **la acción concreta la fija la fila del token**, con los requisitos `claimed`/evento/retiro acotados a D13; entra la fila **D13c** con la rama de la huérfana. Y D13 explicita que el `pipeline-expected` legible es el de **`unit=design`**, no un residuo de otra unidad (D13b suma ese caso).

### r4 (base `ee20a57` → `239a95e`) — **APPROVED de la bajada**

Sin observaciones bloqueantes. Codex verificó que D13/D13b/D13c **particionan** el caso `phase=consumed` sin dobles ganadoras ni combinaciones sin destino (los demás estados los sigue resolviendo la tabla canónica de ocho filas referenciada en §6), que C15 deriva correctamente `design-delta → plan-delta → feature`, y que §8 distingue consistentemente las `description` del cambio en el cuerpo de `status`. Verificación propia del reviewer: `git diff --check` limpio, `tests/lint.sh` limpio, árbol limpio, HEAD correcto. La aprobación es **de la bajada**: la implementación y sus suites quedan para la etapa siguiente.

## Implementación (2026-07-29, paso único)

Como en el 08 y el 09, el cambio es **texto interdependiente** —la skill `build` referencia secciones de `feature`, las tres skills de fase referencian el protocolo de `build`, y §Ruteo nombra a todas— así que va en un solo paso: partirlo dejaría punteros a secciones inexistentes.

| Archivo | Qué recibió |
|---|---|
| `.claude/skills/build/SKILL.md` (**nuevo**) | Guarda de entrada con la asimetría de `/build` explícito; validación del pedido en cinco casos; derivación de la ruta y tipos de unidad; gate con el **ledger creado antes de presentar**; rama «esperando autorización de pipeline»; loop del padre completo (pre-arranque + divergencia, `awake` por unidad, orden durable del token, watcher con timeout 45 min, empujón sin contenido, las cuatro condiciones de corte, mensajes del humano); fin del pipeline y cierre con el OK; **reentrada por referencia** con las cuatro sustituciones y la conjunción de las dos máquinas; esqueleto del ledger. |
| `.claude/skills/feature/SKILL.md` | `description` con el discriminante monofase; guarda que admite el pipeline **solo con token reclamado**; `tipo:` como primera línea del paso 0 de procedencia y de la reentrada del lote; **§Modo hijo de pipeline** (las **cinco** sustituciones —ledger, anclas, identidad, cierre/estado y la autorización registrada— + el pedido de review acotado); `tipo: lote` en el esqueleto del ledger. |
| `.claude/skills/design/SKILL.md` | `description` con el discriminante; guarda con la excepción por token; **§Modo hijo de pipeline** (procedencia, **sin ping-pong**, marker POC, reviews con `unit=design`, cierre `UNIDAD design APROBADA`); cierre del marker en la consolidación normal. |
| `.claude/skills/plan/SKILL.md` | Ídem, con **sin confirmación liviana** (la absorbió el gate), feature 01 = esqueleto en POC, `unit=plan`, cierre `UNIDAD plan APROBADA`; cierre del marker en el paso 1. |
| `.claude/skills/recap/SKILL.md` | RECAP consolidado generalizado a **lote o pipeline**: base `gate_base`, relato **por unidad** (con la memoria de design/plan en las líneas de commit), «qué quedó visible» en pipeline, y los **dos caminos post-OK** en modo POC. |
| `.claude/skills/status/SKILL.md` | Cuerpo: leer el ledger cuando STATUS lo apunta y reportar tipo de corrida, unidad o feature en curso y progreso; decir el marker `borrador (modo POC)` si está. Sigue siendo lectura pura; la `description` no cambia. |
| `AGENTS.md` + `templates/AGENTS.md` (espejo) | `/build` como fase; `/build` en la gramática posicional y en la regla de confirmación; el bloque del interinato **sustituido** por «Multifase → `/build`» (mismo lugar, misma extensión); **regla dura extendida** a «ni cruzar a otra fase … salvo lote o pipeline autorizado». `diff` de §Ruteo entre los dos archivos: vacío. |
| `docs/design/review-contract.md` | `AXEL_REVIEW_ID` como identidad de **corrida orquestada** (lote y pipeline) con el formato `<unidad>:r<M>:<nonce>` y la aclaración de que `review.sh` publica el valor **sin interpretarlo**; «esperando autorización de pipeline» como **quinta** espera humana, con la razón de que su contenido viva en el ledger. |
| `scripts/install.sh` + `tests/install.sh` | `.claude/skills/build/SKILL.md` en `PAYLOAD_SRC` y `PAYLOAD`; la aserción de T1 lo verifica. |
| `docs/implementation/batch-2026-07-29.md` | `tipo: lote` en el bloque Gate (r1 p1). |

**Suites (no-regresión)**: `tests/lint.sh` limpio · `tests/install.sh` **460 ok / 0 fail** (+1 por la aserción nueva) · `tests/loop.sh` **293 ok / 0 fail**. `git diff` de `scripts/review.sh` y `scripts/awake.sh`: **vacío** — el único cambio ejecutable es la allowlist del instalador.

### r5 (base `239a95e`, HEAD `b751f7e`) — CHANGES_REQUESTED · 2 puntos sobre la implementación, los 2 aceptados

Codex verificó como correctos las `description` disjuntas, la máquina de reentrada referenciada, los discriminantes, el espejo de §Ruteo, la allowlist y el contrato; suites en su worktree: lint limpio, install 460/0, loop 287/0 (L5 omitido por falta de `caffeinate`/permiso de `ps` en su sandbox — acá corre y da 293/0), `diff --check` limpio y `review.sh`/`awake.sh` sin cambios. Los dos huecos:

1. **§Ruteo no enumeraba los estados de pipeline** en «Estado pendiente manda»: nombraba corte, autorización y actividad **de lote**, así que la fila **C11** (STATUS «esperando autorización de pipeline» + «dale» en sesión fresca) no se resolvía — la rama existe en `build`, pero ninguna regla la seleccionaba primero. Aceptado: la fila se generaliza a corte, autorización y actividad **de lote o de pipeline**, con el puntero de dueño (`pipeline` ⇒ `/build`, `lote` ⇒ `/feature`), en **los dos espejos**.
2. **Trazabilidad de la autorización en los hijos**, en dos mitades. (a) El «Modo hijo» que reusa `feature` exige registrar «gate/comando **del lote**» y las cuatro sustituciones no lo traducían ⇒ **D3 no se aplicaba literalmente**: entra una **quinta sustitución** (la autorización registrada es la del gate de pipeline: fecha, pedido de `/build`, path del ledger). (b) Los modos hijo de `design` y `plan` pasaban directo a escribir el delta sin registrar la autorización, contra el contrato común: entra en ambos un paso 1 explícito con la sede donde cada doc ya lleva su procedencia —la fila de Decisiones o el encabezado del `docs/design/<tema>.md` en `design`; un párrafo «Extensión \<fecha\> (pipeline)» en `plan`— y con los ajustes de alcance del gate mandando. El padre lo **verifica** entre unidades.

**Infracción registrada de la regla dura** (2026-07-29): el commit `0e960c2` (correcciones de r5) **no tocó `docs/STATUS.md`**, contra «STATUS se actualiza en cada commit». Es la misma falla que el hijo del 09 registró en `b6b2563`. No se corrige con amend —la historia lineal sin amend es regla— sino en el commit siguiente, que además declara el token de la ronda 6. Queda anotado acá para que el rango sea auditable.

### r6 (base `239a95e`, HEAD `098924d`) — CHANGES_REQUESTED · 1 punto, aceptado

Codex dio por **funcionalmente cerrados** los dos de r5 (C11 ya selecciona `/build` desde sesión fresca, los espejos coinciden, y los tres hijos registran la autorización de forma verificable por el padre) y por correcto el manejo de la infracción de `0e960c2` (registrada y reparada en el commit lineal siguiente, sin reescribir historia). Lo que quedaba era **una contradicción de conteo en el contrato instalado**: la quinta sustitución entró en la tabla de §Modo hijo de pipeline de `feature`, pero el texto seguía anunciando «cuatro» ahí y en §5, D3 y el resumen de implementación de este doc — con lo cual **D3 no coincidía literalmente con el texto ejecutable** y el criterio 10 no cerraba. Aceptado: esas cuatro sedes pasan a **cinco**, y en las tres de este doc se distingue explícitamente de las **cuatro sustituciones de §6**, que son otra tabla y otro destinatario (parametrizan la máquina de **reentrada** que `build` referencia, no el Modo hijo).

### r7 (base `239a95e` → `2c64c8a`) — **APPROVED de cierre**

Sin observaciones bloqueantes. Codex verificó que las **cinco** sustituciones del Modo hijo y las **cuatro** de la reentrada quedaron correctamente diferenciadas y que **D3 coincide literalmente** con `feature/SKILL.md` — el bloqueo del criterio 10 —, que los hallazgos de r5 y r6 están cerrados, y que **las matrices C/D y los nueve criterios de cierre se resuelven contra los artefactos instalados**. Verificación propia del reviewer: lint limpio, install 460/0, loop 287/0 (L5 omitido por el sandbox — acá corre y da 293/0), `diff --check` limpio, espejo de §Ruteo idéntico, árbol limpio y HEAD correcto.

**Cierre del feature**: siete rondas (bajada APPROVED en r4, implementación APPROVED en r7), cuatro con cambios pedidos y **todos aceptados sin argumentar en contra**: los cinco de r1 (ledger vivo sin anotar, contradicción de la validación, sustituciones insuficientes para design/plan, contratos del diseño omitidos de los criterios, deslinde de `status` no demostrado), los cuatro de r2, las tres contradicciones internas de r3, los dos de r5 (§Ruteo sin estados de pipeline, trazabilidad de la autorización en los hijos) y el conteo de r6. Queda **«APPROVED — pendiente OK de lote»**: el OK humano llega con el RECAP consolidado del lote `/feature all` (08, 09, 10), que arma el padre.
