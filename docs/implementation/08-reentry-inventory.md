# 08 — Reentradas de fase y feature: inventario completo fail-closed

## Autorización

- **2026-07-29** — autorizado por el **gate de lote** de `/feature all` (features 08, 09, 10), sin exclusiones ni correcciones de alcance. Ledger de la corrida: [batch-2026-07-29.md](batch-2026-07-29.md); resumen autorizado del 08, ahí. No hay gate individual: el hijo de un lote no re-pide confirmación (contrato del modo lote, skill `feature`).

## Alcance

Cerrar el inventario de reentradas que el diseño de entrada implícita dejó a la vista ([design/implicit-entry.md](../design/implicit-entry.md), §«Reentradas — inventario real y alcance de implementación»), **antes** de que el ruteo del 09 dependa de él. Hoy `/feature` cubre «esperando OK», «esperando confirmación de arranque», «esperando autorización de lote» y la reentrada por ledger del lote; falta el **feature individual activo** (bajada, implementación, review sin desenlace consumido), y `/design` y `/plan` no tienen ninguna rama de reentrada. Reabrir una sesión caída a mitad de un loop de diseño o de plan no tiene hoy camino definido ni con comandos explícitos.

Entregables:

- **`docs/design/review-contract.md`** — **sede canónica de la parte compartida** (r1 p1): sección «Reentrada: reconstrucción tras una sesión caída» con la frontera previa, el **vocabulario del token de ronda de STATUS**, la **tabla de resolución del desenlace** con su criterio de identidad individual, y la precondición de invocar `round`. Se elige este archivo porque el instalador lo **actualiza** como payload en cada re-run; sin cambios de lógica en `review.sh`.
- **Skills `design`, `plan` y `feature`**: la rama de reentrada de cada fase — solo el mapa «estado de los docs → paso de su camino», con puntero al doc canónico. En `feature` es el **feature individual activo**, la única del inventario que faltaba ahí; en `design` y `plan`, las primeras que tienen.
- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): **una línea** de convención que nombra las reentradas y apunta al doc canónico. Es un puntero para lectores, deliberadamente **no load-bearing**: `AGENTS.md` es semilla del instalador (§5).
- **`docs/STATUS.md`**: el vocabulario del token aplicado **desde el primer commit de este feature** — se autoaplica, como el gate del 05.
- **`docs/IMPLEMENTATION.md`**: fila 08 al día.

**Fuera de alcance**:

- **Código ejecutable**: `review.sh` ya publica, desde el 07, todo lo que la reentrada necesita (señal terminal atómica con `ts`, `id`, `mode`, `round`, `review_head`, `result`, `rc`). Este feature no agrega lógica ni archivos nuevos ⇒ `scripts/install.sh` y su allowlist **no cambian**: skills y `docs/design/review-contract.md` ya son payload actualizable, y todo lo load-bearing viaja adentro de esos archivos.
- **El ruteo que entrega a estas reentradas** (feature 09) y el pipeline `/build` (feature 10). Este feature define los destinos; no define quién despacha hacia ellos.
- **La reentrada del lote**, que ya existe y **conserva precedencia** con su ancla propia (`.claude/state/batch-expected` + ledger). Acá solo se documenta la convivencia (§5) para que no haya dos criterios en conflicto.
- **`/adopt`**: no necesita rama nueva. Su estado es la existencia de `docs/ADOPTION.md`, la skill ya arranca decidiendo sobre esa señal y cada punto de juicio se pregunta al humano — es idempotente por construcción.
- **`/status`**: lee STATUS y `scripts/review.sh status`; el vocabulario nuevo mejora lo que informa sin cambiarle una línea a la skill.
- **Generalización del contrato de `AXEL_REVIEW_ID`**: declarada como superficie del feature 10 (el pipeline también la usa). Acá se toca el consumidor **sin** `id` (el individual), que es un hueco distinto — y el flujo individual exige `id=-` justamente para no pisarse con el del lote (§2).
- **Tests nuevos**: no hay código nuevo que congelar. La verificación es la matriz de reentrada de este doc (leída contra las skills por el reviewer) más las tres suites corridas como no-regresión.

## Enfoque técnico

### 1. El ancla versionada: vocabulario del token de ronda en `STATUS.md`

La reconstrucción necesita una respuesta inequívoca a una sola pregunta: **¿hay una review lanzada cuyo desenlace nadie consumió?** El estado local (`.claude/state/round`) no la responde — se escribe antes de invocar a Codex y no distingue «desenlace pendiente» de «desenlace ya integrado» — y no es versionado (una máquina distinta no lo tiene).

La responde **STATUS**, que ya se actualiza en cada commit y ya se commitea inmediatamente antes de cada review (el loop es cambio → commit → `review.sh`). La línea de ronda gana un **token de fase**:

```
- **Ronda de review**: 3 · lanzada      # la ronda 3 se lanza sobre el HEAD de ESTE commit; su desenlace no fue consumido
- **Ronda de review**: 3 · consumida    # el desenlace de la ronda 3 se consumió y este commit NO lanza review
- **Ronda de review**: —                # no hay ciclo de review abierto en esta fase/feature
```

**El número es siempre el de `review.sh`** — el mismo que el terminal publica en `round=` —, nunca un acumulado: de eso depende que la identidad de §2 cierre. Y no se elige del relato del feature: se **deriva de `.claude/state/round`**, la misma fuente de la que `review.sh round` calcula el suyo (`ROUND = round + 1`), bajo la precondición de §2 (r2 p2).

**Transiciones** (r1 p3 — sin commits extra: alcanzan los que el loop ya hace):

| Commit | Token que escribe |
|---|---|
| El que precede a una invocación | `N · lanzada` |
| El siguiente al desenlace, **si vuelve a invocar** (corrección o argumento → nueva ronda) | `N+1 · lanzada` — el salto de número **es** el hecho «N consumida y N+1 lanzada»: los dos ocurren en el mismo commit y no pueden escribirse por separado |
| El siguiente al desenlace, **si no invoca** (APPROVED consumido, paso intermedio, cierre, RECAP) | `N · consumida` |
| Cierre del ciclo de la fase/feature | `—` |

**Ciclo reabierto con `new`** (sesión de Codex perdida — §2, precondición): el número de `review.sh` vuelve a **1**, y eso es lo que STATUS escribe (`1 · lanzada`), porque el token debe coincidir con el `round` del terminal. La cuenta **acumulada** del feature no se pierde: vive en el Review log de su doc (`r6 — ronda 1 del ciclo reabierto`), y en design/plan en la línea de commit de la ronda. También se anota ahí que `new` rearmó la racha de deadlock, para que la regla de las 5 rondas siga leyéndose a nivel del feature.

La línea **«Esperando»** fija su vocabulario (los tres primeros literales ya son disparadores vigentes de las skills y no cambian):

| Literal | Qué frena el avance |
|---|---|
| «esperando OK humano» (y sus variantes con el RECAP nombrado) | checkpoint del humano |
| «esperando confirmación de arranque» | gate de arranque de `/feature` presentado |
| «esperando autorización de lote» | gate de lote presentado |
| «esperando el desenlace de la review (ronda N)» | review lanzada, sin desenlace consumido |
| «nada del humano — <trabajo en curso>» | el loop avanza solo |

Solo los tres primeros son esperas **humanas**: son los únicos que disparan re-presentación y aviso. El cuarto es redundante con el token de la línea de ronda **por diseño**: el ruteo del 09 clasifica leyendo «Esperando», y las reentradas resuelven leyendo la línea de ronda; ante contradicción entre ambas líneas gana el camino conservador (§2, fila 2).

### 2. Resolución del desenlace de una review (la parte compartida)

**Frontera previa — un solo chequeo**: **árbol sucio** (`git status --porcelain` no vacío). La sesión caída dejó trabajo sin commitear: no absorberlo ni descartarlo — listarlo y preguntar. Es la misma regla de frontera limpia que el lote le exige al hijo. *(La validación de la sesión de Codex **no** va acá: ver la precondición al final de esta sección — r1 p2.)*

Fuentes: la línea de ronda de STATUS (§1), `.claude/state/review-terminal` ([design/review-contract.md](../design/review-contract.md) §Señal terminal) y el HEAD actual.

**Identidad de la invocación en el flujo individual** — las cuatro condiciones, todas necesarias (r1 p5):

1. `id=-` — fuera del lote no se setea `AXEL_REVIEW_ID`; un terminal **con** id es de una invocación de lote (o de pipeline, 10) y no es nuestro.
2. `mode` coherente con la ronda declarada: `1 ⇒ new`, `>1 ⇒ round`.
3. `round` = la ronda declarada en STATUS.
4. `review_head` = HEAD actual.

No se afirma que HEAD sea siempre el SHA que se lanzó: el contrato admite explícitamente commits durante una review. Cuando eso pasa, la condición 4 falla y el caso **degrada a ambiguo** — que es precisamente el resultado seguro.

| STATUS (línea de ronda) | Señal terminal | Conclusión | Acción |
|---|---|---|---|
| `N · lanzada` | las **cuatro** condiciones de identidad | la ronda N terminó y su desenlace no se consumió | Consumir según `result`: `APPROVED`/`CHANGES_REQUESTED` ⇒ `last-verdict` y `last-review.md` están **vigentes**, seguir el loop normal. Cualquier otro resultado ⇒ esos archivos quedaron viejos: camino de fallas del loop (diagnóstico con `last-review-events.jsonl`, relanzamiento único si la causa es claramente transitoria; `DEADLOCK` **no se reintenta**). |
| `N · lanzada` | cualquier otra cosa: terminal ausente, `id` ≠ `-`, `mode` incoherente, otra ronda, otro `review_head`, o un rechazo pre-invocación (`round=-`, `review_head=-`: `DEADLOCK`, `INPUT_ERROR`) | **ambiguo**: la review puede estar **en vuelo** | **No relanzar ni duplicar.** Presentar al humano lo encontrado + la evidencia best-effort (abajo) y las dos salidas: **esperar** el desenlace poleando el terminal (mismo watcher del lote: cada ~15 s, tope 45 min) o **relanzar** si confirma que el proceso murió. La sesión no avanza sola. |
| `N · consumida` o `—` | irrelevante | no hay review en vuelo ni desenlace pendiente | Seguir el loop desde donde los docs dicen. El Review log del feature (o, en design/plan, los commits del ciclo) dice qué feedback ya fue atendido — **jamás reprocesar a ciegas**. |
| línea **sin token** (STATUS anterior a esta convención, o proyecto instalado que todavía no la usa) | — | **no concluyente** | Degradación conservadora: se consume como la fila 1 **solo si** el estado local del loop está presente y es coherente y el terminal cumple las cuatro condiciones **contra ese estado local** (`round` = `.claude/state/round`, `mode` coherente con él, `id=-`, `review_head` = HEAD). En cualquier otro caso: RECAP sin relanzar. |

**Por qué los rechazos pre-invocación caen en «ambiguo»** (r1 p4): `DEADLOCK` e `INPUT_ERROR` publican `round=-` y `review_head=-`, así que no hay nada que atar a la ronda declarada; un `ts` posterior al commit prueba **orden temporal, no identidad**, y una invocación posterior sobre el mismo commit puede haberlos sobreescrito. Fail-closed manda: se entregan al humano como el resto de los ambiguos. Como evidencia se suma `.claude/state/changes-streak` — en ≥ 5 `review.sh` se niega a lanzar y el único camino es el desempate humano seguido de `scripts/review.sh reset-deadlock`.

**Evidencia best-effort, nunca autoritativa** (para que el humano decida en la fila 2): `ts` del terminal comparado con la fecha del commit de la marca (`git log -1 --format=%cI`); mtime de `.claude/state/last-review-events.jsonl` (Codex escribe eventos ahí mientras corre: reciente y creciendo ⇒ probablemente viva); `pgrep -fl "codex exec"`; y `changes-streak`. Ninguna decide sola: `pgrep` no ata un proceso a **este** repo (otro proyecto o worktree puede tener el suyo) y un mtime es un indicio, no un hecho. Decidir desde un indicio sería exactamente lo que el fail-closed prohíbe; por eso la evidencia se **presenta** y el humano elige.

**Precondición de la ronda siguiente** (r1 p2, r2 p2 — se evalúa **antes de elegir el token y commitear**, al lanzar; **jamás** en la reentrada). Dos chequeos sobre el estado local, porque de él salen los dos números que tienen que coincidir:

1. **`.claude/state/round`**: presente y **numérico**. El token `N` se **deriva** de ahí (`N` = `round` + 1), que es exactamente lo que `review.sh round` va a calcular, y ese valor debe además coincidir con la ronda cuyo desenlace se acaba de consumir (`round` = `N-1`). El primer lanzamiento de un ciclo no necesita derivación **y no debe derivarse** (r4 p1): `new` publica siempre `1` y el token es `1 · lanzada` — hasta que la invocación reescriba el contador, este puede conservar el valor del ciclo anterior (cambio de fase o de feature), así que derivar ahí daría un token distinto del publicado.
2. **`.claude/state/codex-session-id`**: presente y del ciclo vigente. Si falta, no invocar `round` — caería en `resume --last`, que puede retomar la sesión de otro feature (el contrato lo prohíbe explícitamente hasta en el retry de `new`).

Desenlaces:

- **Pérdida del estado local** (`round` ausente o no numérico, o `codex-session-id` ausente): no se invoca `round`. Se reabre el ciclo con `scripts/review.sh new`, se declara **`1 · lanzada`** y se registra en el Review log la ronda acumulada del feature y que `new` rearmó la racha (§1).
- **`round` numérico pero distinto del esperado**: hubo una invocación que este ciclo no registra (otra sesión, un lanzamiento perdido). No se invoca nada: **corte conservador** — RECAP con lo encontrado. Es el mismo criterio que la reentrada; un estado local incoherente no se repara adivinando, y menos gastando una review cuyo desenlace la identidad va a rechazar después.

**La ausencia del session id no prueba que la sesión murió**: `review.sh` lo borra al arrancar un `new` y lo reescribe recién al capturar `thread.started`, así que durante todo un `new` en vuelo su ausencia es normal. Por eso esta precondición vive en el momento de lanzar y no en la reentrada, cuyo orden es: árbol sucio → resolver el desenlace → y solo si el paso siguiente **realmente** necesita una ronda nueva, esta precondición. Un terminal ya publicado se consume igual aunque el estado local se haya perdido: el desenlace no depende ni de la sesión ni del contador.

### 3. Ramas por fase (matriz de reentrada)

Cada skill gana una rama con su mapa «estado de los docs → paso de su camino». Las tres arrancan por §2 (frontera + desenlace) y solo divergen después.

**`/feature` — feature individual activo** (STATUS: fase feature, feature en curso, **sin** ledger de lote en curso, y «Esperando» ≠ las tres esperas humanas ya cubiertas):

| Estado encontrado | Paso siguiente |
|---|---|
| Doc del feature ausente o incompleto (faltan secciones, sin criterios de cierre) | Retomar la **bajada fina** (paso 4 del camino). La confirmación de arranque —o la autorización de lote— ya registrada **no se re-pide**. |
| Doc completo, `Ronda: —` | **Review de la bajada**: `scripts/review.sh new`. |
| Último veredicto `CHANGES_REQUESTED` consumido | Atender los puntos que el Review log **no** registre como atendidos (los commits mandan) → commit → `round`. |
| `APPROVED` consumido con los **criterios de cierre todavía incompletos** — el de la bajada o el de cualquier paso intermedio de implementación (r4 p2) | **Implementación en pasos chicos** (paso 6), desde el punto que marque el Review log. |
| `APPROVED` consumido con los **criterios de cierre cumplidos** | Camino de cierre (paso 7): IMPLEMENTATION + STATUS + RECAP. Si el cierre ya está escrito y STATUS dice «esperando OK», rige la rama existente. |
| Inconsistencia (STATUS contradice IMPLEMENTATION o el git log; el feature en curso no coincide con el doc) | RECAP con lo encontrado, sin adivinar. |

**`/design`** (STATUS: fase diseño con trabajo en curso):

| Estado encontrado | Paso siguiente |
|---|---|
| Ping-pong a medias (DESIGN.md sin consolidar el tema en curso) | **No inventar el ping-pong perdido**: el chat era efímero y no está en los docs. Resumir en pocas líneas lo que los docs y los commits sí registran, decir explícitamente qué falta definir, y retomar el ping-pong con el humano (respuesta directa ⇒ sin push). |
| Consolidado, `Ronda: —` | `scripts/review.sh new` con el pedido del ciclo de diseño. |
| `CHANGES_REQUESTED` consumido | Corregir o argumentar lo pendiente → commit → `round`. |
| `APPROVED` consumido, sin RECAP | RECAP y esperar el OK (paso 4 de la skill). |
| STATUS «esperando OK» | Re-presentar el RECAP pendiente y esperar (respuesta directa ⇒ sin push). Rama nueva: hoy `/design` no la tiene. |

**`/plan`**: idéntica, con una sola diferencia en la primera fila — no hay ping-pong: si IMPLEMENTATION.md no tiene todavía la entrada o la extensión del ciclo en curso, se retoma la bajada del plan (paso 1 de la skill) desde lo que DESIGN.md y el propio plan ya registran.

**Memoria del ciclo en design/plan**: los features tienen «Review log» en su doc; design y plan no tienen doc de ciclo. Su memoria por ronda es (a) la línea de commit, que **nombra la ronda** — convención ya vigente en este repo (`plan entrada implícita r1: …`), que esta bajada hace explícita en las dos skills — y (b) STATUS («Último veredicto»). Si además hace falta el **contenido** del feedback y `last-review.md` se perdió (máquina distinta, estado local borrado) y los commits no alcanzan para saber qué quedó sin atender, el camino no es adivinar: se relanza la ronda pidiéndole al reviewer que reemita su feedback sobre el rango vigente —la fuente autoritativa del feedback es el reviewer, no el recuerdo— y ante cualquier duda sobre el estado, RECAP.

### 4. Reparto de la superficie

| Dónde | Qué | Por qué ahí |
|---|---|---|
| `docs/design/review-contract.md` | **Canónico**: §Reentrada — frontera previa, vocabulario del token (§1), identidad y tabla de resolución (§2), precondición de `round`, y el reconocimiento del consumidor individual del terminal. | Es **payload**: el instalador lo sobreescribe en cada re-run, así que un proyecto ya instalado recibe la sección al actualizar la maquinaria. Además el estado que se resuelve acá es estado del loop de review, que es lo que ese contrato ya gobierna. |
| `.claude/skills/{design,plan,feature}/SKILL.md` | Solo el mapa propio de la fase (§3): 5–8 líneas cada una, con puntero al doc canónico. Nada de la resolución se duplica. | También payload; y las skills son el lugar por donde el generador entra a la fase. |
| `AGENTS.md` + `templates/AGENTS.md` (espejo obligatorio) | **Una línea** en Convenciones: existen reentradas fail-closed y el contrato vive en `docs/design/review-contract.md`. | Puntero para lectores, **no load-bearing** (r1 p1): `AGENTS.md` es **semilla**, no payload — el instalador no pisa el de un proyecto existente, así que nada que las skills necesiten puede vivir solo ahí. |

### 5. Compatibilidad hacia atrás y convivencia con el lote

- **Proyectos instalados**: al re-correr el instalador reciben skills **y** `review-contract.md` actualizados — el par completo, sin depender de que su `AGENTS.md` (semilla intocable) sepa nada de esto. Ninguna skill referencia una sección que el destino pueda no tener.
- **Historia previa y STATUS sin token**: no rompe nada — cae en la última fila de §2 (degradación conservadora). El token no es un requisito de formato: es una marca que, cuando está, **decide**; cuando falta, obliga al camino conservador.
- **Modo lote**: la **reentrada del lote conserva precedencia absoluta** — STATUS apunta al ledger, el corte registrado es absorbente y el ancla es `.claude/state/batch-expected`. El hijo de un lote escribe igual el token (es el mismo loop de `/feature`), pero en lote **manda el ancla**: el `id`/nonce identifica la invocación cuando hay un padre supervisando, y el padre puede commitear el ledger mientras la review del hijo está en vuelo — con lo cual `review_head` = HEAD deja de ser garantía. La separación es explícita en las dos direcciones: el flujo individual exige `id=-`, así que jamás consume un terminal de lote. Las dos anclas tienen la misma semántica (`lanzada`/`launched` → `consumida`/`consumed`); ninguna reemplaza a la otra.
- **Sin maquinaria nueva**: el token de STATUS y las ramas son texto en archivos que ya viajan. Cero archivos nuevos, cero cambios al instalador, cero lógica nueva en los scripts.

## Decisiones (las dos preguntas que el plan dejó abiertas)

1. **Cómo distingue la reentrada una review en vuelo de una muerta.** No la distingue por sí sola, **y no debe**: la señal terminal se escribe al salir, así que su ausencia es genuinamente ambigua, y las únicas señales disponibles (proceso vivo, mtime del archivo de eventos) son heurísticas que no atan un proceso a este repo. Se elige la segunda opción del diseño: **entrega fail-closed al humano en la duda**, enriquecida con la evidencia best-effort y con dos salidas concretas ofrecidas (esperar poleando el terminal, o relanzar tras confirmar la muerte). Lo que la reentrada **sí** resuelve sola es el caso frecuente y decidible: la review terminó y nadie consumió el desenlace (identidad completa ⇒ se consume). Descartado: hacer autoritativa la detección de proceso vivo — decidir desde un indicio contradice el fail-closed que el diseño fija, y el costo del falso negativo (relanzar una review que corre) es duplicar trabajo del reviewer y ensuciar el estado del loop.
2. **Cuánta reconstrucción es compartible.** Casi toda: la frontera previa, el vocabulario del token, la identidad, la tabla de resolución y la precondición de `round` son **idénticas** en las tres fases y se documentan una sola vez, en `docs/design/review-contract.md`. Lo específico por fase es únicamente el mapa «estado de los docs → paso del camino», corto, en cada skill. Descartado: **`AGENTS.md` como sede canónica** (r1 p1) — es semilla del instalador, así que las skills actualizadas de un proyecto existente apuntarían a una sección que ese proyecto nunca recibiría; y **duplicar la tabla en las tres skills** — tres copias que se desincronizan. Un archivo nuevo en la allowlist era viable, pero agrega superficie al instalador (y a `tests/install.sh`) para algo que entra como sección en un contrato que ya viaja y que ya gobierna este estado.

## Criterios de cierre

1. Las tres skills tienen rama de reentrada y entre las tres cubren **todo** el inventario de la matriz (§3), sin huecos y con el mismo criterio fail-closed; ninguna rama lanza `review.sh` sobre un estado `lanzada` sin desenlace confirmado, y ninguna infiere «sesión muerta» de la ausencia de `codex-session-id`.
2. La parte compartida está **una sola vez** en `docs/design/review-contract.md` (payload actualizable), referenciada desde las tres skills; ninguna skill depende de contenido que solo exista en `AGENTS.md`. La línea de `AGENTS.md` está espejada en `templates/AGENTS.md` (regla de sincronía).
3. El vocabulario del token está definido con sus transiciones ejecutables (`N · lanzada` → `N+1 · lanzada` cuando el commit vuelve a invocar; `N · consumida` cuando no) y **aplicado en este mismo feature**, con el número siempre igual al `round` que publica el terminal. Eso lo garantiza la precondición de §2: el token se deriva de `.claude/state/round` (numérico y coincidente con la ronda consumida) antes de commitearse; pérdida del estado local ⇒ `new` + `1 · lanzada`; contador incoherente ⇒ corte conservador, sin gastar una review.
4. El criterio de identidad individual exige las cuatro condiciones (`id=-`, `mode` coherente, `round`, `review_head`) y todo lo demás —incluidos los rechazos pre-invocación— degrada a ambiguo, sin excepción por `ts`.
5. `review-contract.md` reconoce al consumidor individual del terminal, sin cambios de lógica en `review.sh` (el diff del script es vacío); la reentrada del lote conserva precedencia y su ancla, y las dos no pueden confundirse (`id=-` vs. `id` con nonce).
6. Las tres suites en verde como no-regresión (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) y el payload del instalador sin cambios (ningún archivo nuevo).

## Riesgos

- **El token depende de la disciplina del generador**: si un commit previo a una review no lo escribe, la reentrada cae en la degradación conservadora (RECAP en vez de continuar). Es el modo de falla correcto —cuesta una intervención humana, no una review duplicada— y el costo de escribirlo es nulo (el commit ya toca STATUS).
- **Instrucciones en prosa no se testean**: las skills no tienen suite. La verificación es la matriz de este doc leída contra el texto final por el reviewer, más las suites de código corridas como no-regresión. Queda registrado honestamente: este feature no agrega cobertura automatizada porque no agrega código.
- **La evidencia de liveness es best-effort** y puede inducir al humano a error (un `codex exec` de otro proyecto parece «la review viva»). Mitigación: se presenta siempre etiquetada como no concluyente y con las dos salidas explícitas.
- **Ventana entre consumir y commitear**: si la sesión muere después de leer el desenlace y antes del commit siguiente, la reentrada vuelve a consumir el mismo terminal. Es inocuo por construcción —nada se commiteó, y el Review log más los commits dicen qué se atendió— y el árbol sucio, si lo hay, frena antes en la frontera previa.
- **Conservadurismo en los rechazos pre-invocación**: un `DEADLOCK` real reentrado se presenta como ambiguo en vez de nombrarse solo. Es el precio de no atribuir por `ts`; el desenlace práctico coincide (el deadlock termina en RECAP con las dos posturas de todas formas) y `changes-streak` viaja como evidencia.

## Implementación (2026-07-29, paso único)

El cambio es todo texto interdependiente —la sección canónica y los punteros de las skills— así que va en un solo paso: partirlo dejaría referencias colgadas a una sección que todavía no existe.

| Archivo | Qué recibió |
|---|---|
| `docs/design/review-contract.md` | Sección nueva **§Reentrada: reconstrucción tras una sesión caída** (canónica: token de ronda, frontera previa, identidad + tabla de resolución, precondición de la ronda siguiente), y dos ajustes en §Señal terminal — `id=-` es lo que consume la reentrada individual, y el bullet del consumidor deja de ser exclusivo del padre del lote. |
| `.claude/skills/design/SKILL.md` | Rama «Reentrada» (5 estados + inconsistencia) y, en Reglas, el token de ronda + la línea de commit que nombra la ronda como memoria del ciclo (el diseño no tiene Review log propio). |
| `.claude/skills/plan/SKILL.md` | Ídem, con «bajada a medias» en lugar del ping-pong. |
| `.claude/skills/feature/SKILL.md` | Rama nueva «Si STATUS apunta a un feature individual activo» (6 estados), precedencia explícita de la reentrada del lote con su ancla en la sección que ya existía, y el token de ronda en las Reglas del loop. |
| `AGENTS.md` + `templates/AGENTS.md` | Una línea espejada en Convenciones, puntero al contrato (no load-bearing). |

Sin cambios en `scripts/` ni en `tests/`: el diff de código es vacío y el payload del instalador no incorpora archivos.

## Review log

- **r1** (2026-07-29, `CHANGES_REQUESTED`, rango `cfc5dd2..82e7d55`): cinco puntos, los cinco aceptados y corregidos en la bajada — (1) `AGENTS.md` no puede ser sede canónica: es **semilla** del instalador (un `AGENTS.md` preexistente no se pisa), así que un proyecto que actualiza la maquinaria recibiría skills apuntando a una sección inexistente ⇒ la parte compartida se muda a `docs/design/review-contract.md`, que sí es payload actualizable, y en AGENTS/plantilla queda solo un puntero declarado no load-bearing; (2) evaluar `codex-session-id` en la frontera previa podía **duplicar la review que protege** — `review.sh` borra ese archivo antes de `invoke_new` y lo reescribe recién al capturar `thread.started`, así que durante un `new` en vuelo su ausencia es normal ⇒ el chequeo pasa a ser **precondición de invocar `round`**, evaluada al lanzar, y el orden queda árbol sucio → desenlace → (solo si hace falta `round`) sesión; un terminal publicado se consume igual aunque la sesión se haya perdido; (3) la transición del token no era ejecutable: el commit que atiende un `CHANGES_REQUESTED` es a la vez el previo a la ronda siguiente y no puede declarar `N · consumida` y `N+1 · lanzada` ⇒ se define `N · lanzada → N+1 · lanzada` como **un solo hecho** (el salto implica el consumo) y `N · consumida` queda para los commits que no invocan; (4) el `ts` posterior al commit no atribuye un `DEADLOCK`/`INPUT_ERROR` (`round=-`, `review_head=-`: prueba orden, no identidad, y otra invocación puede sobreescribirlos) ⇒ esa fila cae en «ambiguo» como el resto, con `changes-streak` sumado a la evidencia; (5) la identidad post-invocación se endurece a **cuatro** condiciones (`id=-` para no consumir terminales de lote/pipeline, `mode` coherente con la ronda, `round`, `review_head`), se corrige la afirmación de que HEAD es siempre el SHA lanzado (el contrato admite commits durante una review: ese caso degrada a ambiguo, y por eso es seguro), y se documenta que un ciclo reabierto con `new` escribe `1` en STATUS mientras la ronda acumulada del feature vive en el Review log. Codex validó explícitamente la entrega humana de la duda «en vuelo vs. muerta», la ausencia de huecos en la matriz de fases y que la bajada no invade el alcance del 09/10.
- **r2** (2026-07-29, `CHANGES_REQUESTED`, rango `cfc5dd2..4ba8b55`): los cinco puntos de r1 validados como cerrados («la sede canónica es ahora payload actualizable, la sesión se valida después de resolver el desenlace, las transiciones del token son ejecutables, los rechazos pre-invocación son ambiguos y la identidad exige las cuatro condiciones»). Un punto nuevo, aceptado: la precondición miraba solo `codex-session-id`, pero el número que `review.sh round` publica sale de `.claude/state/round` (`ROUND = round + 1`) — con ese archivo ausente, no numérico o desincronizado y el session id presente, el commit podía declarar `N · lanzada` mientras el terminal publicaba otro número: la identidad lo rechaza después, pero ya se gastó una review cuyo desenlace no puede consumirse. Fijado (§1 y §2): el token **se deriva** de `.claude/state/round` en vez de elegirse del relato, la precondición se evalúa **antes de commitear el token**, exige el contador numérico y coincidente con la ronda recién consumida, y reparte los desenlaces — pérdida del estado local ⇒ `new` + `1 · lanzada` con el registro de la ronda acumulada; contador numérico incoherente ⇒ corte conservador sin invocar nada. Criterio de cierre 3 actualizado. Codex acotó además el hallazgo: fuera de pérdida o desincronización del estado local no encontró otro camino normal de divergencia entre token y terminal.
- **r3** (2026-07-29, **`APPROVED` de la bajada**, rango `cfc5dd2..7f1cca3`): «token y `review.sh round` derivan ahora de `.claude/state/round`, validado antes del commit. La pérdida de estado abre `new` con ronda 1; una discrepancia numérica corta sin invocar. §1, §2, la matriz y el criterio de cierre 3 son consistentes. No encontré otro camino normal de divergencia ni regresiones sobre las correcciones anteriores. La bajada fina está lista para implementar». Base a `7f1cca3`.
- **r4** (2026-07-29, `CHANGES_REQUESTED`, rango `7f1cca3..464aad4`): implementación completa revisada; Codex validó el contrato común, la precedencia del lote y la distribución payload/semilla, y marcó dos huecos de **ejecutabilidad de las skills**, los dos aceptados — (1) las reglas de las tres skills decían «el token se deriva de `.claude/state/round`» sin la excepción del primer `new`: al cambiar de fase o de feature el contador conserva el valor del ciclo anterior hasta que la invocación lo reescriba, así que derivar ahí produciría un token distinto del `round=1` que `new` publica ⇒ las tres reglas ahora separan los casos (`new` ⇒ `1 · lanzada` sin derivar; `round` ⇒ contador + 1 con la precondición) y el contrato explicita el motivo; (2) faltaba una rama alcanzable en `/feature` — el `APPROVED` de un **paso intermedio** de implementación, que no es ni el de la bajada ni el de cierre ⇒ la fila se generalizó por criterios de cierre («incompletos ⇒ paso 6 desde donde marque el Review log» / «cumplidos ⇒ paso 7»), en la skill y en la matriz de §3.
- **r5** (2026-07-29, **`APPROVED` de cierre**, rango `7f1cca3..a2f673d`): «las tres skills distinguen explícitamente `new` (`1 · lanzada`, sin derivación) de `round` (contador + 1 bajo precondición), y el contrato documenta correctamente el motivo»; «la rama de `APPROVED` en `/feature` ahora es exhaustiva: criterios incompletos retoman el paso 6 desde el Review log; criterios cumplidos avanzan al cierre. No deja huecos ni se solapa con `CHANGES_REQUESTED`»; «contrato, skills y matriz de bajada quedaron consistentes… Los seis criterios de cierre están satisfechos». Base a `a2f673d`. Ciclo del feature: **5 rondas** (r3 APPROVED de la bajada · r5 APPROVED de cierre). Estado: **APPROVED — pendiente OK de lote** (lote [batch-2026-07-29.md](batch-2026-07-29.md)).
