# 08 — Reentradas de fase y feature: inventario completo fail-closed

## Autorización

- **2026-07-29** — autorizado por el **gate de lote** de `/feature all` (features 08, 09, 10), sin exclusiones ni correcciones de alcance. Ledger de la corrida: [batch-2026-07-29.md](batch-2026-07-29.md); resumen autorizado del 08, ahí. No hay gate individual: el hijo de un lote no re-pide confirmación (contrato del modo lote, skill `feature`).

## Alcance

Cerrar el inventario de reentradas que el diseño de entrada implícita dejó a la vista ([design/implicit-entry.md](../design/implicit-entry.md), §«Reentradas — inventario real»), **antes** de que el ruteo del 09 dependa de él. Hoy `/feature` cubre «esperando OK», «esperando confirmación de arranque», «esperando autorización de lote» y la reentrada por ledger del lote; falta el **feature individual activo** (bajada, implementación, review sin desenlace consumido), y `/design` y `/plan` no tienen ninguna rama de reentrada. Reabrir una sesión caída a mitad de un loop de diseño o de plan no tiene hoy camino definido ni con comandos explícitos.

Entregables:

- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): sección **«Reentradas»** con las tres piezas compartidas — el invariante fail-closed, el **vocabulario de `STATUS.md`** del que depende la reconstrucción, y la **tabla de resolución del desenlace de una review**. Es la parte común a las tres fases, escrita una sola vez.
- **Skill `feature`**: rama de reentrada del **feature individual activo**, la única del inventario que faltaba en esa skill.
- **Skills `design` y `plan`**: sus ramas de reentrada (trabajo a medio consolidar, review en curso, esperando OK), inexistentes hoy.
- **`docs/design/review-contract.md`**: reconocimiento del **consumidor individual** de la señal terminal — hoy el contrato la describe como mecanismo exclusivo del lote, y a partir de este feature la reentrada de cualquier fase la lee. Sin cambios de lógica en `review.sh`.
- **`docs/STATUS.md`**: el vocabulario nuevo aplicado **desde el primer commit de este feature** — se autoaplica, como el gate del 05.
- **`docs/IMPLEMENTATION.md`**: fila 08 al día.

**Fuera de alcance**:

- **Código ejecutable**: `review.sh` ya publica, desde el 07, todo lo que la reentrada necesita (señal terminal atómica con `mode`, `round`, `review_head`, `result`, `rc`, `ts`). Este feature no agrega lógica ni archivos nuevos ⇒ `scripts/install.sh` y su allowlist **no cambian**: skills, `templates/AGENTS.md` y `docs/design/review-contract.md` ya son payload, y todo lo nuevo viaja adentro de esos archivos.
- **El ruteo que entrega a estas reentradas** (feature 09) y el pipeline `/build` (feature 10). Este feature define los destinos; no define quién despacha hacia ellos.
- **La reentrada del lote**, que ya existe y **conserva precedencia** con su ancla propia (`.claude/state/batch-expected` + ledger). Acá solo se documenta la convivencia (§5) para que no haya dos criterios en conflicto.
- **`/adopt`**: no necesita rama nueva. Su estado es la existencia de `docs/ADOPTION.md`, la skill ya arranca decidiendo sobre esa señal y cada punto de juicio se pregunta al humano — es idempotente por construcción.
- **`/status`**: lee STATUS y `scripts/review.sh status`; el vocabulario nuevo mejora lo que informa sin cambiarle una línea a la skill.
- **Generalización del contrato de `AXEL_REVIEW_ID`**: declarada como superficie del feature 10 (el pipeline también la usa). Acá se toca el consumidor **sin** `id` (el individual), que es un hueco distinto.
- **Tests nuevos**: no hay código nuevo que congelar. La verificación es la matriz de reentrada de este doc (leída contra las skills por el reviewer) más las tres suites corridas como no-regresión.

## Enfoque técnico

### 1. El ancla versionada: vocabulario de `STATUS.md`

La reconstrucción necesita una respuesta inequívoca a una sola pregunta: **¿hay una review lanzada cuyo desenlace nadie consumió?** El estado local (`.claude/state/round`) no la responde — se escribe antes de invocar a Codex y no distingue «desenlace pendiente» de «desenlace ya integrado» — y no es versionado (una máquina distinta no lo tiene).

La responde **STATUS**, que ya se actualiza en cada commit y ya se commitea inmediatamente antes de cada review (el loop es cambio → commit → `review.sh`). La línea de ronda gana un **token de fase**:

```
- **Ronda de review**: 3 · lanzada      # la ronda 3 se lanza sobre el HEAD de ESTE commit; su desenlace no fue consumido
- **Ronda de review**: 3 · consumida    # el desenlace de la ronda 3 ya se leyó (y se está atendiendo o ya se atendió)
- **Ronda de review**: —                # no hay ciclo de review abierto en esta fase/feature
```

Transiciones (una sola regla, idéntica en las tres fases): **el commit que precede a la invocación declara `N · lanzada`; el commit siguiente —el que trae la corrección, el argumento o el cierre— la pasa a `N · consumida`.** Ningún commit extra: son los que el loop ya hace.

La línea **«Esperando»** fija su vocabulario (los tres primeros literales ya son disparadores vigentes de las skills y no cambian):

| Literal | Qué frena el avance |
|---|---|
| «esperando OK humano» (y sus variantes con el RECAP nombrado) | checkpoint del humano |
| «esperando confirmación de arranque» | gate de arranque de `/feature` presentado |
| «esperando autorización de lote» | gate de lote presentado |
| «esperando el desenlace de la review (ronda N)» | review lanzada, sin desenlace consumido |
| «nada del humano — <trabajo en curso>» | el loop avanza solo |

Solo los tres primeros son esperas **humanas**: son los únicos que disparan re-presentación y aviso. El cuarto es redundante con el token de la línea de ronda **por diseño**: el ruteo del 09 clasifica leyendo «Esperando», y las reentradas resuelven leyendo la línea de ronda; ante contradicción entre ambas líneas, gana el camino conservador (§2, última fila).

### 2. Resolución del desenlace de una review (la parte compartida)

Fuentes: la línea de ronda de STATUS (arriba), `.claude/state/review-terminal` (contrato: [design/review-contract.md](../design/review-contract.md) §Señal terminal) y el HEAD actual. **Identidad de la invocación en el caso individual**: fuera del lote no hay `AXEL_REVIEW_ID` (`id=-`), así que la identidad es `round` del terminal = la ronda declarada en STATUS **y** `review_head` = HEAD actual — que es exactamente el commit que declaró `lanzada`, porque la invocación ocurre inmediatamente después de él.

| STATUS (línea de ronda) | Señal terminal | Conclusión | Acción |
|---|---|---|---|
| `N · lanzada` | `round=N` **y** `review_head` = HEAD actual | la ronda N terminó y su desenlace no se consumió | Consumir según `result`: `APPROVED`/`CHANGES_REQUESTED` ⇒ `last-verdict` y `last-review.md` están **vigentes**, seguir el loop normal. Cualquier otro resultado ⇒ esos archivos quedaron viejos: camino de fallas del loop (diagnóstico con `last-review-events.jsonl`, relanzamiento único si la causa es claramente transitoria; `DEADLOCK` **no se reintenta** — RECAP con ambas posturas). |
| `N · lanzada` | `round=-` con `result` ∈ {`DEADLOCK`, `INPUT_ERROR`} y `ts` posterior a la fecha del commit que declaró la marca (`git log -1 --format=%cI`) | rechazo **pre-invocación** de esta ronda: no hubo review | `DEADLOCK` ⇒ RECAP con ambas posturas (y `scripts/review.sh reset-deadlock` solo tras el desempate humano). `INPUT_ERROR` ⇒ relanzar la ronda con el pedido bien formado. |
| `N · lanzada` | ausente, de otra ronda, con otro `review_head`, o con `ts` anterior a la marca | **ambiguo**: la review puede estar **en vuelo** | **No relanzar ni duplicar.** Presentar al humano lo encontrado + la evidencia best-effort (abajo) y las dos salidas: **esperar** el desenlace poleando el terminal (mismo watcher del lote: cada ~15 s, tope 45 min) o **relanzar** si confirma que el proceso murió. La sesión no avanza sola. |
| `N · consumida` o `—` | irrelevante | no hay review en vuelo ni desenlace pendiente | Seguir el loop desde donde los docs dicen. El Review log del feature (o, en design/plan, los commits del ciclo) dice qué feedback ya fue atendido — **jamás reprocesar a ciegas**. |
| línea **sin token** (STATUS anterior a esta convención, o proyecto instalado que todavía no la usa) | — | **no concluyente** | Degradación conservadora: se consume como la fila 1 **solo si** el estado local del loop está presente y es coherente (`.claude/state/round` = la ronda de STATUS, `codex-session-id` presente) **y** el terminal matchea (`round` = `.claude/state/round`, `review_head` = HEAD). En cualquier otro caso: RECAP sin relanzar. |

**Evidencia best-effort, nunca autoritativa** (para que el humano decida en la fila 3): `ts` del terminal comparado con la fecha del commit de la marca; mtime de `.claude/state/last-review-events.jsonl` (Codex escribe eventos ahí mientras corre: reciente y creciendo ⇒ probablemente viva); y `pgrep -fl "codex exec"`. Ninguna de las tres decide sola: `pgrep` no ata un proceso a **este** repo (otro proyecto o worktree puede tener el suyo) y un mtime es un indicio, no un hecho. Decidir desde un indicio sería exactamente lo que el fail-closed prohíbe; por eso la evidencia se **presenta** y el humano elige.

**Frontera previa a cualquier resolución** — dos chequeos, en este orden:

1. **Árbol sucio** (`git status --porcelain` no vacío): la sesión caída dejó trabajo sin commitear. No absorberlo ni descartarlo: listarlo y preguntar. Es la misma regla de frontera limpia que el lote le exige al hijo.
2. **Sesión de Codex perdida** (`.claude/state/codex-session-id` ausente, o el ciclo local pertenece a otro feature): **no correr `round`** — sin session id cae en `resume --last`, que puede retomar la sesión del feature anterior (el contrato lo prohíbe explícitamente en el retry de `new`). Reabrir el ciclo con `scripts/review.sh new`, aclarando en el pedido que es una reentrada y qué rondas ya hubo, y anotar en el Review log que la numeración de `review.sh` vuelve a 1 y que la racha de deadlock se rearmó — la cuenta de rondas **del feature** la lleva el doc, no el script.

### 3. Ramas por fase (matriz de reentrada)

Cada skill gana una rama con su mapa «estado de los docs → paso de su camino». Las tres arrancan por §2 (frontera + desenlace) y solo divergen después.

**`/feature` — feature individual activo** (STATUS: fase feature, feature en curso, **sin** ledger de lote en curso, y «Esperando» ≠ las tres esperas humanas ya cubiertas):

| Estado encontrado | Paso siguiente |
|---|---|
| Doc del feature ausente o incompleto (faltan secciones, sin criterios de cierre) | Retomar la **bajada fina** (paso 4 del camino). La confirmación de arranque —o la autorización de lote— ya registrada **no se re-pide**. |
| Doc completo, `Ronda: —` | **Review de la bajada**: `scripts/review.sh new`. |
| Último veredicto `CHANGES_REQUESTED` consumido | Atender los puntos que el Review log **no** registre como atendidos (los commits mandan) → commit → `round`. |
| `APPROVED` de la bajada consumido | **Implementación en pasos chicos** (paso 6). |
| `APPROVED` de cierre con los criterios cumplidos | Camino de cierre (paso 7): IMPLEMENTATION + STATUS + RECAP. Si el cierre ya está escrito y STATUS dice «esperando OK», rige la rama existente. |
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

| Dónde | Qué |
|---|---|
| `AGENTS.md` + `templates/AGENTS.md` (espejo obligatorio) | Sección «Reentradas»: invariante fail-closed, vocabulario de STATUS (§1), tabla de resolución del desenlace (§2) y la frontera previa. ~25 líneas, una sola vez. Va acá porque es convención de **docs** transversal a las tres skills, AGENTS.md se carga solo en cada sesión, y el ruteo del 09 aterriza al lado. |
| `.claude/skills/{design,plan,feature}/SKILL.md` | Solo el mapa propio de la fase (§3): 5–8 líneas cada una, con puntero a la sección de AGENTS.md para la parte común. Nada de la resolución de review se duplica. |
| `docs/design/review-contract.md` | Un párrafo en §Señal terminal: el terminal también lo consume la **reentrada individual** de cualquier fase, cuya identidad es `round` + `review_head` (sin `id`, que fuera del lote es `-`); mismas garantías de identidad completa y misma prohibición de adivinar ante ausencia. Sin cambios en `review.sh`. |
| `docs/STATUS.md` | El vocabulario, aplicado desde el primer commit de este feature. |

### 5. Compatibilidad hacia atrás y convivencia con el lote

- **Proyectos instalados y historia previa**: un STATUS sin el token no rompe nada — cae en la última fila de §2 (degradación conservadora). El token no es un requisito de formato: es una marca que, cuando está, **decide**; cuando falta, obliga al camino conservador.
- **Modo lote**: la **reentrada del lote conserva precedencia absoluta** — STATUS apunta al ledger, el corte registrado es absorbente y el ancla es `.claude/state/batch-expected`. El hijo de un lote escribe igual el token (es el mismo loop de `/feature`), pero en lote **manda el ancla**: el `id`/nonce es lo que identifica una invocación cuando hay un padre supervisando, y el padre puede commitear el ledger mientras la review del hijo está en vuelo — con lo cual `review_head` = HEAD deja de ser garantía. Fuera del lote no hay padre ni commits ajenos concurrentes, y el par STATUS+HEAD alcanza. Las dos anclas tienen la misma semántica (`lanzada`/`launched` → `consumida`/`consumed`); ninguna reemplaza a la otra.
- **Sin maquinaria nueva**: el token de STATUS y las ramas son texto en archivos que ya viajan. Cero archivos nuevos, cero cambios al instalador, cero lógica nueva en los scripts.

## Decisiones (las dos preguntas que el plan dejó abiertas)

1. **Cómo distingue la reentrada una review en vuelo de una muerta.** No la distingue por sí sola, **y no debe**: la señal terminal se escribe al salir, así que su ausencia es genuinamente ambigua, y las únicas señales disponibles (proceso vivo, mtime del archivo de eventos) son heurísticas que no atan un proceso a este repo. Se elige la segunda opción del diseño: **entrega fail-closed al humano en la duda**, enriquecida con la evidencia best-effort y con dos salidas concretas ofrecidas (esperar poleando el terminal, o relanzar tras confirmar la muerte). Lo que la reentrada **sí** resuelve sola es el caso frecuente y decidible: la review terminó y nadie consumió el desenlace (identidad completa ⇒ se consume). Descartado: hacer autoritativa la detección de proceso vivo — decidir desde un indicio contradice el fail-closed que el diseño fija, y el costo del falso negativo (relanzar una review que corre) es duplicar trabajo del reviewer y ensuciar el estado del loop.
2. **Cuánta reconstrucción es compartible.** Casi toda: la frontera previa (árbol sucio, sesión de Codex perdida), el vocabulario de STATUS y la tabla de resolución del desenlace son **idénticas** en las tres fases y se documentan una sola vez en AGENTS.md. Lo específico por fase es únicamente el mapa «estado de los docs → paso del camino», que es corto y vive en cada skill. Descartado: un archivo compartido nuevo (obligaría a tocar la allowlist del instalador para algo que entra en 25 líneas de un archivo que ya viaja) y duplicar la tabla en las tres skills (tres copias que se desincronizan).

## Criterios de cierre

1. Las tres skills tienen rama de reentrada y entre las tres cubren **todo** el inventario de la matriz (§3), sin huecos y con el mismo criterio fail-closed; ninguna rama lanza `review.sh` sobre un estado `lanzada` sin desenlace confirmado.
2. La parte compartida está documentada **una sola vez** (AGENTS.md §Reentradas) y referenciada desde las tres skills; `templates/AGENTS.md` es espejo exacto (regla de sincronía).
3. El vocabulario de STATUS está definido y **aplicado en este mismo feature**: cada commit previo a una review declara `N · lanzada` y el siguiente la pasa a `N · consumida`.
4. `review-contract.md` reconoce al consumidor individual del terminal, sin cambios de lógica en `review.sh` (el diff del script es vacío).
5. Compatibilidad hacia atrás explícita: STATUS sin token ⇒ camino conservador documentado; la reentrada del lote conserva precedencia y su ancla.
6. Las tres suites en verde como no-regresión (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) y el payload del instalador sin cambios (ningún archivo nuevo).

## Riesgos

- **El token depende de la disciplina del generador**: si un commit previo a una review no lo escribe, la reentrada cae en la degradación conservadora (RECAP en vez de continuar). Es el modo de falla correcto —cuesta una intervención humana, no una review duplicada— y el costo de escribirlo es nulo (el commit ya toca STATUS).
- **Instrucciones en prosa no se testean**: las skills no tienen suite. La verificación es la matriz de este doc leída contra el texto final por el reviewer, más las suites de código corridas como no-regresión. Queda registrado honestamente: este feature no agrega cobertura automatizada porque no agrega código.
- **La evidencia de liveness es best-effort** y puede inducir al humano a error (un `codex exec` de otro proyecto parece «la review viva»). Mitigación: se presenta siempre etiquetada como no concluyente y con las dos salidas explícitas.
- **Ventana entre consumir y commitear**: si la sesión muere después de leer el desenlace y antes del commit siguiente, la reentrada vuelve a consumir el mismo terminal. Es inocuo por construcción —nada se commiteó, y el Review log más los commits dicen qué se atendió— y el árbol sucio, si lo hay, frena antes en la frontera previa.

## Review log

(pendiente)
