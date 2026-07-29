# 11 — Modelo fijo de los subagentes por tipo de unidad

## Autorización

- **2026-07-29** — autorizado por el **gate de pipeline** de `/build`. Pedido que lo originó (literal breve del bloque Gate): «fijar el modelo de los subagentes por tipo de unidad: los hijos que corren las skills design y plan (unidades design-delta y plan-delta de un pipeline) con Fable 5, y los hijos que corren feature (tanto los del modo lote de /feature all como las unidades feature de un pipeline) con Opus 5. Hoy todos heredan el modelo de la sesión padre, y la skill build tiene un párrafo «Modelos por unidad» que documenta esa decisión y habría que reescribir.» Ledger de la corrida: [pipeline-2026-07-29.md](pipeline-2026-07-29.md); resumen autorizado de esta unidad, ahí (§Ruta derivada, «11 — feature»). No hay gate individual: el hijo de un pipeline no re-pide confirmación (contrato del modo hijo, skill `feature`).
- **Ajuste de alcance registrado en el gate** (2026-07-29, posterior a la autorización): los hijos que resten de la corrida se lanzan con Opus 5 — motivo operativo (Fable 5 sin créditos a mitad de la unidad `plan`), no de método. Es el propio mecanismo de override que este feature conserva (§6), aplicado en producción sobre la corrida que lo implementa.

## Alcance

Revertir una decisión **de bajada** —§10 de [10-build-pipeline.md](10-build-pipeline.md), «no se cablean»— y fijar en la maquinaria el modelo con el que se lanza cada subagente, según **qué skill corre el hijo**:

- hijo que corre `design` o `plan` (unidades `design-delta` / `plan-delta` de un pipeline) ⇒ **Fable**;
- hijo que corre `feature` (modo lote de `/feature all` · `NN..MM`, y unidades `feature` de un pipeline) ⇒ **Opus**.

Hoy todos heredan el modelo de la sesión padre. El diseño ya habilitaba el esquema ([design/implicit-entry.md](../design/implicit-entry.md) §«Modelos por unidad»: el padre *puede* aplicarlo, «detalle en la bajada»), así que **no hay delta de diseño**: lo que cambia es la bajada, más la fila de decisión de `DESIGN.md` que el feature agrega (como hicieron el 05 y el 06).

Entregables:

- **Skill `build`** (payload): §«Modelos por unidad» reescrita como **tabla canónica** —modelo por tipo de unidad—, con la naturaleza de los identificadores (§2), el override por gate (§6) y la regla de **degradación anunciada** ante indisponibilidad (§5); y el bullet «Lanzá el hijo» remitiendo a ella.
- **Skill `feature`** (payload): el bullet «Lanzá el hijo» del **modo lote** fija `opus` con puntero a la canónica. Nada más de esa skill cambia (§7).
- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): §Roles distingue los **dos planos** — modelo de la **sesión** (elección del humano) y modelo de los **hijos** (fijado por la maquinaria) — con el deslinde de qué parte es espejo literal y qué parte es local de axel (§4).
- **`docs/design/implicit-entry.md`**: §«Modelos por unidad» pasa de «puede» a la regla fijada, y la línea «Overrides de modelo por tipo de unidad en el subagente» de la lista de decisiones para la bajada queda marcada **resuelta**, apuntando a este doc.
- **`docs/implementation/10-build-pipeline.md` §10**: **nota de reversión** — el texto original se conserva íntegro, con la nota que dice qué la revirtió, cuándo y con qué defensas (§1). No se borra ni se reescribe la decisión anterior.
- **`docs/DESIGN.md`**: fila de decisión del 2026-07-29.
- **`docs/IMPLEMENTATION.md`**: fila 11 al día, con este doc enlazado. **`docs/STATUS.md`**: al día en cada commit, con el token de ronda del contrato.

**Fuera de alcance**:

- **Cambios ejecutables**: ninguno. No hay archivo nuevo de payload, así que `scripts/install.sh` y `tests/install.sh` no se tocan; `scripts/review.sh` y `scripts/awake.sh` tampoco. El spawn lo hace un modelo leyendo texto de skill, igual que en los features 08–10.
- **Skill `recap`**: la degradación se lista en el RECAP consolidado, pero eso es instrucción para el **padre**, que es quien lo arma — la superficie de `recap` (estructura y base del consolidado) no cambia.
- **La tabla de sustituciones del «Modo hijo de pipeline» de `feature`**: la superficie estimada del plan la nombraba; el análisis muestra que **no se toca** — el modelo lo fija el padre al spawnear y para el hijo no cambia nada, así que las **cinco** sustituciones siguen siendo cinco (§7).
- **Modelo y esfuerzo del reviewer**: se siguen tuneando solo en `scripts/review.sh` (fila de decisiones de `DESIGN.md` del 2026-07-27, intacta). Este feature es sobre el **generador hijo**, no sobre Codex.
- **El modelo de la sesión**: sigue siendo elección del humano. El feature no lo fija ni lo sugiere en la plantilla.

## Enfoque técnico

### 1. Qué se revierte, y por qué la razón de fondo dejó de bloquear

La §10 del feature 10 decidió **no cablear** modelos con dos argumentos: (a) en axel el esquema de modelo por fase es «elección del humano en la sesión», no regla de la maquinaria; (b) cablear «design-delta ⇒ modelo X» en una skill que es **payload** exportaría las preferencias de axel a todos los destinos y **quedaría desactualizada sin que nadie la mire**.

El pedido humano resuelve (a) por autoridad: pasa a ser regla de la maquinaria — y el feature instala esa distinción explícitamente en `AGENTS.md` (§4), en vez de dejarla implícita. El argumento (b) es el que la bajada debe responder, y se responde con tres hechos:

1. **Ya hay precedente cercano y aceptado**: el modelo del **reviewer** está cableado desde el feature 00 en `scripts/review.sh` (`REVIEW_MODEL="${AXEL_REVIEW_MODEL:-gpt-5.6-sol}"`), que **es payload**, con fila propia en `DESIGN.md` («Config de modelos | Variables al tope de `review.sh` (+ env `AXEL_REVIEW_*`) | Cambiar de modelo o esfuerzo = tocar una línea versionada, sin depender de config global»). axel ya exporta un modelo concreto a todos los destinos y lo considera correcto porque la constante es **visible, versionada y en un solo lugar**. **La diferencia, nombrada** (r1 p3): `review.sh` es una **constante ejecutable única** —una línea que un script lee—, mientras que acá es una **regla declarativa distribuida entre dos skills** que interpreta un modelo leyendo texto. El precedente prueba que un default de modelo puede viajar versionado sin que axel lo considere un problema; **no** prueba que una regla en dos sedes de markdown se mantenga coherente sola. Por eso la duplicación se acota a un token con canónica declarada (§3) y queda como riesgo vivo R4, en vez de darse por resuelta con la analogía.
2. **El identificador elegido no envejece** (§2): son alias de **familia**, no IDs de API con versión. La objeción «se desactualiza en silencio» apunta a `claude-opus-5`, que sí queda viejo; `opus` no.
3. **La indisponibilidad no rompe el destino** (§5): degradación anunciada y registrada, nunca corte. El peor caso en un destino sin acceso a esos modelos es una corrida que anda con el modelo de la sesión y dos líneas de registro, no una maquinaria inutilizable.

Queda un residual honesto, que se acepta y se registra como riesgo R1: un destino con otra política de modelos hereda la de axel hasta que la overridee por gate o edite la tabla. La §10 **conserva su texto** con la nota de reversión — la decisión anterior y su razón siguen legibles, que es como axel registra los cambios de opinión.

### 2. Cómo se nombra el modelo: alias de familia del harness, no ID de API

La skill no puede escribir «Opus 5» ni `claude-opus-5`: lo que el spawn acepta es el identificador del **harness**. En el harness de Claude Code de hoy, la herramienta de agentes toma un parámetro `model` cuyo dominio es el conjunto de alias de familia `sonnet | opus | haiku | fable`; el alias resuelve a la versión vigente de esa familia (hoy `opus` ⇒ Opus 5, `fable` ⇒ Fable 5). Decisión:

- La maquinaria fija la **familia** (`fable`, `opus`), no la versión. Cumple el pedido en sustancia — hoy resuelven exactamente a Fable 5 y Opus 5 — y es lo que hace que la tabla no envejezca cuando salga la familia siguiente.
- **No** se escriben IDs de API en ninguna skill. Un ID versionado es precisamente lo que la §10 temía.
- Lo que la maquinaria elige es un **perfil de capacidad** por tipo de trabajo, no un producto: razonamiento largo y escritura de docs para `design`/`plan`, implementación con loop de review para `feature`. Escribirlo así en la skill deja claro qué hay que preservar si el harness renombra sus alias.

**Fuente de la evidencia, declarada**: el dominio del parámetro `model` es observable desde el esquema de la herramienta de agentes en la sesión de Claude Code, y **no** desde el worktree del reviewer — Codex no puede ejecutar nada que lo confirme. Se declara como observación del harness, no como hecho verificable en el repo, y la defensa ante un cambio de nombre es la misma que ante indisponibilidad (§5, fila E9).

### 3. Dónde vive la regla: una tabla canónica y una fila que la referencia

Dos skills lanzan hijos: `build` (padre de pipeline, lanza los tres tipos) y `feature` (padre de lote, lanza **solo** hijos que corren `feature`).

- **Canónica**: skill `build`, §«Modelos por unidad» — el título se **conserva** (es el que nombran el pedido humano, el plan y la §10 del feature 10; renombrarlo rompería esas referencias) y el cuerpo se reescribe entero. Ahí va la tabla de tres filas, la naturaleza de los alias, el override y la degradación.
- **Referencia**: skill `feature`, bullet «Lanzá el hijo» del modo lote — declara su única fila aplicable (`opus`) **en línea**, porque el padre necesita el valor en el punto de uso, y apunta a la canónica para el resto (alias, precedencia, degradación con su encaje durable). La referencia es **resolutiva, no decorativa** (r1 p2): quien lee solo `feature` tiene que poder resolver el spawn de un lote —incluidos el override por gate de lote y el rechazo del modelo— siguiendo el puntero, con las dos únicas particularidades del lote nombradas ahí: el registro va al **ledger del lote** y el override entra como **corrección del gate de lote** (el paso 2 ya admite «exclusiones puntuales»; una corrección de modelo es una más y se registra en la línea «Exclusiones/correcciones» del ledger).

Se repite un token (`opus`) en dos archivos, no una máquina: la regla de sincronía queda escrita y el criterio de cierre 2 la verifica. **Alternativa descartada**: un archivo de payload nuevo con la tabla — obligaría a tocar las dos allowlists de `scripts/install.sh` y las aserciones de `tests/install.sh`, superficie ejecutable que ni el plan ni la ruta autorizada previeron, para evitar la duplicación de una palabra. El patrón «canónica + referencia» ya es el del feature 10 (la reentrada del pipeline referencia la del lote en vez de duplicarla).

### 4. Los dos planos en `AGENTS.md` y en la plantilla

Hoy `AGENTS.md` §Roles mezcla ambos: «Generador: Claude Code (hoy: esquema mixto por fase — Fable 5 para `/design` y `/plan`, Opus 5 para `/feature`, esfuerzo xhigh; lo elige el humano en la sesión)». Con este feature son dos cosas distintas:

- **Modelo de la sesión** — el generador que el humano abre. Sigue siendo **su elección**; en axel, hoy, el esquema mixto por fase con esfuerzo xhigh.
- **Modelo de los hijos** — los subagentes de un lote o un pipeline. Lo **fija la maquinaria** por tipo de unidad y **no se hereda** de la sesión: `fable` para los que corren `design`/`plan`, `opus` para los que corren `feature`. Se overridea puntualmente por gate.

**Deslinde de sincronía** (el criterio 4 del feature 10 pide espejo literal de las secciones tocadas, y §Roles hoy **no** lo es): lo que debe ser espejo es la **regla de la maquinaria** —los dos planos y los dos valores—, porque es maquinaria. Lo que **no** va a la plantilla es la elección concreta de la sesión de axel (Fable 5 / Opus 5 / xhigh, y el modelo del reviewer): eso es configuración local de este proyecto, y la plantilla ya lo trata así hoy («Modelo y esfuerzo los elige el humano en la sesión», sin nombrar ninguno). El feature preserva ese deslinde y lo deja escrito acá para que el diff sea auditable.

**Qué llega a cada destino, con precisión** (r1 p3 — la formulación anterior decía que la regla «viaja con el payload», y eso es falso para la plantilla): `templates/AGENTS.md` es fuente de **semilla**, no de payload (`scripts/install.sh`, bloque `SEED_SRC`: «owned por el destino, se crean solo si faltan y no se tocan jamás después»). Por lo tanto:

- **La regla operativa** —la que ejecuta el spawn— llega a **todos** los destinos, incluidos los ya instalados, porque vive en las skills `build` y `feature`, que **sí** son payload y el re-run actualiza. Es la sede que importa para el comportamiento.
- **La §Roles de la plantilla** solo aterriza en **instalaciones nuevas**. En un destino ya instalado, su `AGENTS.md` queda documentando el plano viejo aunque las skills ya apliquen el nuevo. **Limitación registrada**, no defecto de esta bajada: es el mismo régimen —y el mismo registro honesto— que el feature 10 dejó escrito para su §Ruteo («`AGENTS.md` es semilla, así que en un destino ya instalado la §Ruteo nueva no llega — pero la skill `build`, su `description` y su guarda sí, por payload», §11 de [10-build-pipeline.md](10-build-pipeline.md)).

### 5. Indisponibilidad: degradación anunciada, y su encaje con el orden durable de spawn

Un destino puede no tener acceso a una de las familias, y el harness puede renombrar o dejar de reconocer un alias. Regla base:

> Si el spawn con el modelo fijado es **rechazado de forma definitiva**, el padre **no corta la corrida**: lanza el hijo con el modelo de la sesión, registra un **evento en el ledger** («modelo `X` no disponible: unidad lanzada con el modelo de la sesión») y lo **lista en el RECAP consolidado**.

**Encaje con el orden durable** (r1 p1 — la regla base sola no era operable). El orden es `acuñar token → ledger + STATUS + commit → spawn`, así que el rechazo llega **después** del commit de arranque: el token ya está acuñado y el evento vigente ya lo registra. Cuatro precisiones, iguales para lote y pipeline:

1. **El fallback reutiliza el mismo token, sin re-acuñar y sin retirar nada.** El token no está atado al modelo: como no hubo hijo, el ancla sigue **pendiente** (nadie la reclamó) y el evento vigente ya la respalda, de modo que el segundo spawn satisface la **misma triple coincidencia** que el primero. Re-acuñar sería además ilegal: la skill prohíbe acuñar un token nuevo mientras hay uno pendiente, justamente porque sobreescribir el ancla puede duplicar un hijo.
2. **El rechazo y el fallback elegido se registran y commitean ANTES del segundo spawn** (r2 p1). El primer intento de esta bajada dijo lo contrario —«sin commit intermedio»— con el argumento de que el estado de **control** es el mismo caiga el padre antes o después. El argumento es cierto y **no alcanza**: lo que se pierde sin ese commit no es control, es **proveniencia**. Si el fallback arranca y el padre cae antes de su próximo commit, la reentrada resuelve el token pero **no sabe que el hijo corre degradado**, así que el ledger y el RECAP pueden omitirlo — y ahí se cae la garantía de registro que es la mitad entera de esta regla (§1, defensa 3). Por eso: evento de degradación en el ledger + STATUS + **commit**, y recién después el segundo spawn.

   Dos precisiones que ese commit no puede violar: (a) el evento de degradación **no es un evento de arranque** — no re-acuña nada y no desplaza al **evento vigente**, que sigue siendo el del arranque con `token=T`, de modo que la triple coincidencia del hijo resuelve igual; (b) la reentrada **no gana una rama nueva**: el estado sigue siendo «ancla pendiente `T` + evento vigente `T`» ⇒ ambiguo ⇒ RECAP, solo que ahora el RECAP tiene la degradación a la vista en vez de tener que inferirla.
3. **Rechazo definitivo vs. resultado ambiguo** — el «no corta» cubre **solo** el primero:
   - **Definitivo**: la invocación es rechazada y **no queda ningún hijo lanzado** (modelo no reconocido, sin acceso en este destino). Nadie puede reclamar el ancla ⇒ **fallback inmediato** con el mismo token y el modelo de la sesión.
   - **Ambiguo**: cualquier otro fallo en el que **no puedas afirmar que no hay hijo** (timeout, error de transporte, respuesta indeterminada). **No hay segundo spawn**: un hijo vivo más otro con el mismo token es exactamente la duplicación que el protocolo existe para evitar ⇒ **corte** y RECAP con la evidencia.
4. **Si el padre cae entre el rechazo y el fallback**: no hace falta fila nueva en la máquina de reentrada. El estado es «ancla **pendiente** `T` + evento vigente con `T`», que la tabla del token ya clasifica **ambiguo ⇒ no relanzar, RECAP con la evidencia**. Es el desenlace correcto: desde afuera ese estado no se distingue de «se lanzó y todavía no reclamó».

Por qué el «no corta» no es una excepción al fail-closed del método: el fail-closed protege lo que puede **corromper estado o duplicar trabajo** —reviews en vuelo, tokens de spawn, autorizaciones—; ahí la maquinaria frena y entrega al humano. Un modelo distinto en el hijo no es de esa clase: hace el mismo trabajo, con el mismo loop, y el **APPROVED de Codex sigue siendo el gate de calidad**, intacto. Cortar por indisponibilidad convertiría una preferencia de axel en un requisito duro del destino, que es exactamente lo que la §10 quería evitar. **Y el alcance queda acotado** (r1 p1): lo que no corta es el **rechazo definitivo del modelo sobre la corrida viva**; el resultado indeterminado corta, y la caída del padre a mitad del fallback también, por la razón de siempre — no duplicar trabajo en vuelo. «Anunciada» es la mitad que resuelve la objeción de la §10: la degradación queda en dos lugares versionados —ledger y RECAP—, así que **sí la mira alguien**.

### 6. El override por gate se conserva

La tercera pregunta de la bajada («¿el humano conserva el override puntual por gate?») se responde **sí**, con un cambio de estatus: deja de ser el único mecanismo y pasa a ser el **override sobre un default fijado**. El humano pide otro modelo para un tipo de unidad al autorizar (o durante la corrida, con su prioridad absoluta); queda como **ajuste de alcance en el ledger** y **gana sobre la tabla**. Precedencia, de mayor a menor: ajuste de alcance registrado en el ledger → tabla canónica → modelo de la sesión (solo por degradación de §5).

Que el ajuste viva en el ledger tiene una consecuencia que hay que escribir: **sobrevive a la reentrada**. Un padre que relanza un hijo tras una caída lee el ledger, ve el ajuste y lo aplica — no vuelve a la tabla. Esta misma corrida es el caso: el ajuste del 2026-07-29 mandó los hijos restantes a Opus 5 y el relanzamiento de la unidad `plan` lo respetó (fila E10).

### 7. Lo que no se toca, y por qué

- **Tabla de sustituciones del «Modo hijo de pipeline» de `feature`**: el modelo lo fija el **padre** al spawnear; para el hijo, correr con `opus` en un lote o en un pipeline es idéntico. Ninguna sustitución nueva ⇒ siguen siendo **cinco**, y el conteo declarado en el cuerpo de la skill, en la §5 del feature 10 y en su fila D3 no se mueve. (El feature 10 corrigió en su r6 exactamente un desajuste de este conteo: se deja explícito para que la review pueda verificarlo sin recontarlo a ciegas.)
- **Modo hijo (lote) de `feature`**: el hijo no elige su modelo ni lo verifica — no tiene forma de saber con qué lo lanzaron, y hacerlo dependiente de eso agregaría un chequeo sin defensa detrás.
- **`design` y `plan`**: no spawnean; sus secciones «Modo hijo de pipeline» no mencionan modelo y no lo van a mencionar.
- **`docs/design/batch-features.md`**: no habla de modelos (verificado por grep) — el lote hereda la regla por la skill, sin delta de diseño.
- **`scripts/`, `tests/`, allowlists del instalador**: sin cambios (§Fuera de alcance).

### 8. Docs de diseño y de bajada

- `docs/design/implicit-entry.md` §«Modelos por unidad»: de «el padre **puede** aplicar el esquema por tipo de unidad … Detalle en la bajada» a la regla fijada, con puntero a este doc. Y en «Decisiones que quedan para la bajada», la línea «Overrides de modelo por tipo de unidad en el subagente» se marca **resuelta** con el mismo puntero, para que la lista no siga anunciando una pregunta abierta que ya tiene respuesta.
- `10-build-pipeline.md` §10: texto original intacto + nota de reversión con fecha, feature que la revierte y las tres defensas de §1.
- `DESIGN.md`: fila nueva en la tabla de decisiones (2026-07-29), con el detalle apuntando acá.

## Matriz E — modelo del hijo

Como en los features 08–10 no hay harness de despacho: el comportamiento lo ejecuta un modelo leyendo texto. La verificación es esta matriz, y **cada fila debe resolverse contra el texto final instalado** —la §«Modelos por unidad» de `build`, el bullet de spawn de `feature`, o §Roles de `AGENTS.md`/`templates/AGENTS.md`—, sin apelar a este doc.

| # | Situación | Qué debe pasar | Dónde se resuelve |
|---|---|---|---|
| E1 | lote `/feature all` autorizado; el padre arranca el hijo del feature 03 | spawn con **`opus`**, no con el modelo de la sesión | `feature`, bullet «Lanzá el hijo» del modo lote |
| E2 | pipeline, arranca la unidad `design-delta` | spawn con **`fable`** | `build` §«Modelos por unidad», fila `design-delta` |
| E3 | pipeline, arranca la unidad `plan-delta` | spawn con **`fable`** | ídem, fila `plan-delta` |
| E4 | pipeline, arranca una unidad `feature` | spawn con **`opus`** | ídem, fila `feature` |
| E5 | la sesión padre corre en un modelo distinto (p. ej. Sonnet) y lanza una unidad `feature` | **`opus` igual**: el hijo no hereda el modelo de la sesión | «lo fija la maquinaria, no la sesión» en ambas skills |
| E6 | en el gate de **pipeline** el humano pide «los hijos de `plan` con Opus» | **gana el override**: ajuste de alcance en el ledger, el padre lo aplica al spawnear | `build` §«Modelos por unidad», precedencia + `## Gate` del ledger |
| E6b | en el gate de **lote** el humano pide «los hijos con Sonnet» | **gana el override**, por la misma precedencia: entra como **corrección** del gate de lote y se registra en la línea «Exclusiones/correcciones» del ledger del lote | `feature`, bullet de spawn del modo lote + paso 2 del modo lote |
| E7 | pipeline: el harness rechaza el spawn con `fable` (sin acceso en este destino) | **no corta**: lanza con el modelo de la sesión, evento en el ledger de pipeline y línea en el RECAP consolidado | `build` §«Modelos por unidad», degradación |
| E7b | **lote**: el harness rechaza el spawn con `opus` en el padre de lote | idéntico, en su sede: no corta, modelo de la sesión, evento en el **ledger del lote** y línea en el RECAP consolidado del lote | `feature`, bullet de spawn del modo lote (regla resolutiva vía puntero) |
| E7c | el spawn falla con **resultado indeterminado** (timeout, transporte) — no se puede afirmar que no haya hijo | **no hay fallback**: segundo spawn con el mismo token duplicaría un hijo posiblemente vivo ⇒ **corte** + RECAP con la evidencia | `build` §«Modelos por unidad», definitivo vs. ambiguo (y su puntero desde `feature`) |
| E7d | el padre cae **entre** el rechazo definitivo y el fallback | sin fila nueva: el estado es ancla **pendiente** `T` + evento vigente `T` ⇒ la tabla del token lo clasifica **ambiguo** ⇒ no relanzar, RECAP | tabla del token de `feature` §«Reentrada del lote» (y sus sustituciones en `build`) |
| E7e | el fallback tras un rechazo definitivo | **mismo token**, sin re-acuñar y sin retirar; y el rechazo + el modelo elegido **se registran y commitean antes** del segundo spawn — el evento de degradación no es de arranque, así que no desplaza al evento vigente | `build` §«Modelos por unidad», encaje durable |
| E7f | el padre cae **después** del fallback, antes de su commit siguiente | la degradación **ya está registrada** (se commiteó antes del spawn): la reentrada la ve y el RECAP la reporta, en vez de perderla | ídem — es la razón por la que el commit va antes |
| E8 | sale la versión siguiente de una familia (p. ej. Opus 6) | **nada que actualizar**: el valor es alias de familia, no ID de API con versión | `build` §«Modelos por unidad», nota de alias |
| E9 | el harness renombra sus alias y `fable` deja de reconocerse | la propia sección lo dice: un alias renombrado **es** un rechazo definitivo ⇒ mismo camino que E7, y el arreglo es editar la tabla — **una línea, un solo archivo** | `build` §«Modelos por unidad», frase explícita del renombre + «esta tabla es la canónica» |
| E10 | reentrada de un **pipeline** con un ajuste de alcance de modelo; el padre relanza el hijo de una unidad | gana el **ajuste registrado en el ledger**, no la tabla ni el modelo de la sesión que reentra | precedencia escrita en `build` §«Modelos por unidad» |
| E10b | reentrada de un **lote** con una corrección de modelo registrada; el padre relanza el hijo de un feature | ídem: gana la corrección del **ledger del lote** sobre la fila `opus` | `feature`, bullet de spawn (precedencia vía puntero) + ledger del lote |
| E11 | el humano pregunta con qué modelo corre la maquinaria | `AGENTS.md` §Roles distingue los **dos planos**: sesión = su elección; hijos = fijado por la maquinaria, con los dos valores | `AGENTS.md` §Roles |
| E12 | un destino instalado edita la tabla local y luego re-corre el instalador | la propia sección lo advierte: la skill es **payload** y el re-run la reescribe — el camino soportado para una política distinta es el **override por gate** (o re-editar tras el update) | `build` §«Modelos por unidad», nota de payload sobreescribible |
| E13 | proyecto destino recién instalado | `templates/AGENTS.md` §Roles trae la **regla de la maquinaria** (los dos planos y los dos valores), sin la elección concreta de axel | `templates/AGENTS.md` §Roles |
| E13b | destino **ya instalado** que re-corre el instalador | la **regla operativa** llega (skills = payload) pero su `AGENTS.md` §Roles **no** se actualiza (semilla intocable): el comportamiento es el nuevo y su doc local queda viejo — limitación conocida, igual que la §Ruteo del feature 10 | régimen `SEED_SRC` de `scripts/install.sh` + §4 de esta bajada (limitación registrada, no comportamiento) |
| E14 | pipeline en **modo POC** | la sección lo **afirma**: el modo POC no cambia los modelos — acota el alcance del delta, no con qué modelo corre el hijo | `build` §«Modelos por unidad», frase explícita del modo POC |

## Criterios de cierre

1. `.claude/skills/build/SKILL.md` conserva el título §«Modelos por unidad» y su cuerpo tiene: la **tabla de tres filas** (`design-delta` ⇒ `fable`, `plan-delta` ⇒ `fable`, `feature` ⇒ `opus`), el enunciado de que lo fija la maquinaria y **no** se hereda de la sesión, la naturaleza de **alias de familia** (no ID de API) con el perfil de capacidad que justifica cada elección, el **override por gate** con su precedencia de tres niveles, y la **degradación** completa: rechazo **definitivo** vs. resultado **ambiguo** (el segundo corta), fallback **con el mismo token y sin re-acuñar**, con el rechazo y el modelo elegido **registrados y commiteados antes del segundo spawn** (y la nota de que ese evento no es de arranque, así que no desplaza al evento vigente), más la línea en el RECAP. Además, tres afirmaciones que la matriz necesita resolver **contra la skill** y no contra este doc: un **alias renombrado** es un rechazo definitivo y el arreglo es editar esa tabla (E9); la tabla es **payload sobreescribible** por el re-run del instalador, y el camino soportado para otra política es el override por gate (E12); el **modo POC no cambia los modelos** (E14). El bullet «Lanzá el hijo» remite a la sección.
2. `.claude/skills/feature/SKILL.md`: el bullet «Lanzá el hijo» del modo lote fija `opus`, nombra sus dos particularidades —registro en el **ledger del lote**, override como **corrección del gate de lote**— y apunta a la canónica para el resto, de modo que E6b, E7b y E10b se resuelvan **desde esa skill** siguiendo el puntero. El **resto del diff de esa skill es vacío**; en particular la tabla del «Modo hijo de pipeline» sigue con **cinco** sustituciones y el texto que las cuenta sigue diciendo cinco.
3. `AGENTS.md` §Roles distingue los dos planos con los dos valores y el override; `templates/AGENTS.md` §Roles trae la misma regla de maquinaria y **no** la elección concreta de axel (ni modelos de sesión, ni el del reviewer). El deslinde es el de §4 y se verifica por `diff` de la sección. La **limitación de semilla** (la §Roles nueva no llega a destinos ya instalados; la regla operativa sí, por las skills) queda registrada en §4 de esta bajada.
4. `docs/design/implicit-entry.md`: §«Modelos por unidad» enuncia la regla fijada (ya no «puede») y la línea de la lista de decisiones para la bajada queda marcada resuelta; ambas apuntan a este doc.
5. `docs/implementation/10-build-pipeline.md` §10 conserva su texto original **íntegro** y suma una nota de reversión con fecha, feature y las defensas que la habilitan. Nada borrado ni reescrito.
6. `docs/DESIGN.md` suma la fila de decisión del 2026-07-29, con su «por qué» y el puntero a este doc.
7. La **matriz E** se resuelve **entera** —las **22** filas (E1–E14 más E6b, E7b, E7c, E7d, E7e, E7f, E10b, E13b)— contra el texto final instalado, sin apelar a este doc. Única excepción declarada: E13b, cuyo **comportamiento** se resuelve contra el régimen `SEED_SRC` de `scripts/install.sh` y cuya *limitación* es lo que esta bajada registra.
8. **Sin cambios ejecutables**: `git diff` de `scripts/` y de `tests/` **vacío** en el rango del feature; el payload del instalador no cambia. Las tres suites (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión.
9. `docs/IMPLEMENTATION.md` tiene la fila 11 al día con este doc enlazado, y `docs/STATUS.md` quedó al día en cada commit, con el token de ronda del contrato.

## Riesgos

- **R1 — La preferencia de axel viaja al destino** (el residual de la §10, aceptado): un proyecto instalado hereda `fable`/`opus` aunque su equipo use otra política. Lo acotan las tres defensas: alias de familia que no envejece, override por gate, y degradación anunciada que impide que un destino sin acceso quede bloqueado. Mismo régimen —y misma aceptación— que el modelo del reviewer cableado en `review.sh` desde el feature 00.
- **R2 — La maquinaria fija familia, no versión**: si una versión nueva de la familia es peor o más cara para el caso, el hijo la toma sin aviso. Se acepta: el APPROVED de Codex sigue siendo el gate de calidad, y fijar versión reintroduciría exactamente el envejecimiento silencioso que la §10 señaló.
- **R3 — La evidencia del dominio de alias no es verificable por el reviewer**: el esquema del parámetro `model` es observable desde la sesión de Claude Code, no desde el worktree snapshot. Se declara como observación del harness (§2). Si el harness cambia el dominio, el efecto es E9 y la defensa es la degradación anunciada.
- **R4 — Duplicación del valor `opus` en dos skills**: pueden divergir en un cambio futuro. Mitigación: canónica declarada + puntero explícito + criterio de cierre 2. Alternativa (archivo payload propio) descartada por superficie ejecutable, §3.
- **R5 — El re-run del instalador pisa una edición local de la tabla** (E12): es el régimen de payload de axel, idéntico al de `review.sh`; se documenta en la propia sección para que el destino sepa que el camino soportado es el override por gate.
- **R6 — Un pipeline mixto podría quedar a mitad con dos modelos distintos** si una familia cae a mitad de corrida (pasó en esta misma corrida). No es un riesgo nuevo del feature: el ajuste por gate lo resuelve y queda registrado en el ledger; la matriz lo cubre en E6/E10.
- **R7 — Doc local desactualizado en destinos ya instalados** (r1 p3): tras un re-run, las skills aplican la regla nueva pero el `AGENTS.md` del destino —semilla intocable— sigue describiendo el plano viejo, así que su doc y su comportamiento divergen hasta que alguien lo edite a mano. Se acepta con registro: es el régimen de semillas del instalador, ya asumido por el feature 10 para su §Ruteo, y el costo de la alternativa (que el instalador pise `AGENTS.md`) es mucho peor — borraría las reglas propias del destino.
- **R8 — El fallback depende de distinguir un rechazo definitivo de uno ambiguo** (§5): esa clasificación la hace un modelo leyendo el error del harness, no un código de retorno tipado. Ante la duda, la regla escrita empuja al lado seguro (ambiguo ⇒ corte), que cuesta una corrida frenada y nunca un hijo duplicado; es la asimetría deliberada del fail-closed.

## Implementación (2026-07-29, paso único)

Las seis sedes, escritas tal como las fijó la bajada. Sin cambios ejecutables.

1. **`.claude/skills/build/SKILL.md`** — la §«Modelos por unidad» pasa de párrafo dentro del gate a **sección propia** (`## Modelos por unidad`), ubicada entre la rama «esperando autorización de pipeline» y el loop del padre: es donde se usa, y como sección tiene ancla estable para que `feature` la referencie. Trae la tabla de tres filas con su columna «por qué» (el perfil de capacidad), el enunciado de que la fija la maquinaria y no se hereda, los alias de familia, la precedencia de tres niveles, la degradación completa en tres pasos numerados —registro **y commit antes** del segundo spawn, fallback con el mismo token sin re-acuñar, línea en el RECAP—, la nota de que el evento de degradación no desplaza al evento vigente, el deslinde «resultado indeterminado ⇒ corte», el renombre de alias con su arreglo, el modo POC sin excepción y la nota de payload sobreescribible. El bullet «Lanzá el hijo» remite a la sección.
2. **`.claude/skills/feature/SKILL.md`** — **una sola línea** cambiada, el bullet «Lanzá el hijo» del modo lote: fija `opus`, dice que lo fija la maquinaria y no la sesión, y nombra las dos únicas particularidades del lote (registro en el ledger del lote; override como corrección del gate de lote, que gana también al relanzar por reentrada), con puntero a la canónica para el resto. `git diff --stat` de la skill: **1 insertion, 1 deletion**.
3. **`AGENTS.md` + `templates/AGENTS.md`** — §Roles reescrita con los dos planos. La regla de la maquinaria es **espejo literal** (verificado por `diff` de la línea); lo que difiere es solo lo local de axel: la línea del plano de sesión nombra el esquema mixto y el esfuerzo, la de la plantilla no.
4. **`docs/design/implicit-entry.md`** — §«Modelos por unidad» enuncia la regla fijada y apunta a este doc; la línea de la lista de decisiones para la bajada queda **tachada y marcada resuelta**, con la historia completa (el 10 decidió no cablearlos, el 11 lo revirtió).
5. **`docs/implementation/10-build-pipeline.md` §10** — nota de reversión al tope de la sección, en blockquote; el texto original queda **íntegro debajo**, sin una palabra cambiada.
6. **`docs/DESIGN.md`** — fila de decisión del 2026-07-29 con los dos planos, el mecanismo y el «por qué».

### Matriz E resuelta contra el texto instalado

Las 22 filas, con la sede que las resuelve. Ninguna apela a este doc (única excepción declarada por el criterio 7: E13b, cuyo comportamiento vive en `scripts/install.sh`).

| # | Resuelta por | Texto que la decide |
|---|---|---|
| E1 | `feature`, bullet de spawn del lote | «subagente fresco en background **con modelo `opus`**» |
| E2 | `build` §Modelos por unidad, tabla | fila `design-delta` ⇒ `fable` |
| E3 | ídem, tabla | fila `plan-delta` ⇒ `fable` |
| E4 | ídem, tabla | fila `feature` ⇒ `opus` |
| E5 | ambas skills | «lanzá cada hijo con el modelo de **su tipo de unidad**, no con el de tu sesión» / «lo fija la maquinaria por tipo de unidad, no la sesión» |
| E6 | `build`, precedencia (1) | «ajuste de alcance registrado en el ledger … gana sobre la tabla» |
| E6b | `feature`, bullet de spawn | «el override del humano entra como **corrección del gate de lote** (paso 2), en la línea «Exclusiones/correcciones» del ledger» |
| E7 | `build`, degradación | «**no cortes la corrida**» + los tres pasos |
| E7b | `feature`, bullet de spawn | «en un lote cambian solo dos cosas: el registro va al **ledger del lote**…» + puntero a la canónica |
| E7c | `build` | «**Resultado indeterminado ≠ rechazo definitivo** … no hay segundo spawn ⇒ **corte**» |
| E7d | `feature` §Reentrada del lote, tabla del token (sin cambios) | fila «pendiente `T` · evento con `T` ⇒ **ambiguo** … no relances» |
| E7e | `build`, pasos 1–2 | «**antes** del segundo spawn» + «reutilizando el mismo token … **No re-acuñes**» + «no es un evento de arranque» |
| E7f | `build`, paso 1 | «sin ese commit, un padre que cae después del fallback deja al hijo corriendo degradado **sin registro**» |
| E8 | `build`, nota de alias | «alias de familia … la tabla no envejece cuando sale una versión nueva» |
| E9 | `build`, rechazo + cierre del bloque | «incluido el caso de que el harness los **renombre**» + «el arreglo de fondo es actualizar **esta tabla** — una línea, en este único archivo» |
| E10 | `build`, precedencia (1) | «queda escrito en el bloque Gate, así que **sobrevive a la reentrada**» |
| E10b | `feature`, bullet de spawn | «desde donde gana sobre `opus` también al relanzar por reentrada» |
| E11 | `AGENTS.md` §Roles | los dos bullets: «**De la sesión** — lo **elige el humano**» / «**De los hijos** … lo **fija la maquinaria**» |
| E12 | `build`, nota final | «**Esta tabla es payload**: un re-run del instalador la reescribe … el camino soportado es el **override por gate**» |
| E13 | `templates/AGENTS.md` §Roles | los mismos dos bullets, sin la elección concreta de axel |
| E13b | `scripts/install.sh`, `SEED_SRC` | «Semillas: owned por el destino, se crean solo si faltan y no se tocan jamás después» ⇒ la §Roles nueva no llega a destinos ya instalados; la regla operativa sí, por `PAYLOAD` |
| E14 | `build`, nota de POC | «**Modo POC**: sin excepción — los mismos modelos por tipo de unidad» |

### Verificación de los criterios mecánicos

- **C2** — `git diff --stat` de `.claude/skills/feature/SKILL.md`: **1 file changed, 1 insertion(+), 1 deletion(-)**. La tabla del «Modo hijo de pipeline» conserva sus **cinco** filas (contadas sobre el archivo) y el texto sigue diciendo «con cinco sustituciones».
- **C3** — `diff` de la línea «De los hijos» entre `AGENTS.md` y `templates/AGENTS.md`: **sin diferencias**.
- **C8** — `git diff <base> -- scripts/ tests/`: **vacío**. Las tres suites en verde: `tests/loop.sh` **293 ok · 0 fail**, `tests/install.sh` **460 ok · 0 fail**, `tests/lint.sh` limpio.
  **Nota sobre el conteo de `loop.sh`, cerrada**: el reviewer reporta 287 y en el repo canónico dan 293. No es una regresión ni un efecto del feature. Primero se verificó corriendo la misma suite en un worktree del commit `9f338fd` —el que Codex revisó en la r4—, donde también da **293**: mismo contenido, distinto entorno. La **causa exacta** la confirmó Codex en la r5: en su sandbox se **saltea la clase L5**, y esos son los seis casos de diferencia. La comparación válida es mismo-commit contra mismo-entorno, y ahí el número es idéntico antes y después de la implementación.

## Review log

### r1 (base `e6d26e2`, HEAD `316628b`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

Codex acordó la sustancia de la bajada desde la primera ronda —alias de familia, override por gate conservado, ninguna sexta sustitución, y el deslinde entre la configuración local de axel y el texto genérico de la plantilla— y dio por suficiente, para esta etapa, la observación declarada del esquema del harness protegida por el fallback (riesgo R3). Verificó además las tres suites por su cuenta: `tests/loop.sh` 287 ok, `tests/install.sh` 460 ok, `tests/lint.sh` limpio. Los tres puntos, todos de completitud:

1. **La degradación no estaba integrada con el protocolo durable de spawn.** Tras `acuñar → ledger+commit → spawn`, un rechazo deja token pendiente y evento de arranque ya commiteado, y la bajada no decía si el fallback reutiliza ese token, si el evento de degradación se commitea antes del segundo spawn, ni qué hace la reentrada si el padre cae entre rechazo y fallback. **Aceptado**: §5 gana el encaje durable con cuatro precisiones — reuso del **mismo** token sin re-acuñar ni retirar (re-acuñar sobre un pendiente es ilegal por la propia skill), «sin commit intermedio» (**corregido en r2**: ver abajo), **rechazo definitivo vs. resultado ambiguo** con el segundo cortando, y la caída entre rechazo y fallback resuelta **sin fila nueva** por la fila «pendiente `T` + evento `T` ⇒ ambiguo ⇒ RECAP» que ya existe. Se acota además el «nunca corte» como pidió el punto: cubre el rechazo definitivo sobre la corrida viva, no un spawn indeterminado.
2. **La matriz E no satisfacía su propio criterio 7.** E7 solo probaba `fable` en `build`, faltaban override y reentrada del **lote**, E9/E12 apelaban a secciones de esta bajada en vez de al texto instalado, y E14 se apoyaba en una *ausencia* de excepción. **Aceptado**: la matriz pasa de 14 a **21 filas** (E6b, E7b, E7c, E7d, E7e, E10b, E13b — el conteo salió mal escrito como «20» y lo corrigió la r2) y E9, E12 y E14 se re-atribuyen a **afirmaciones explícitas que la skill debe traer** —renombre de alias, tabla payload sobreescribible, modo POC sin excepción—, incorporadas al criterio de cierre 1. La §3 aclara además que el puntero de `feature` a la canónica es **resolutivo**: E6b, E7b y E10b tienen que poder resolverse leyendo esa skill y siguiendo el puntero.
3. **El deslinde payload/semilla de §4 era incorrecto.** `templates/AGENTS.md` es fuente de **semilla** (`SEED_SRC`: se crea solo si falta y no se toca jamás), así que la §Roles nueva **no** llega a destinos ya instalados — llega la regla operativa, por las skills, que sí son payload. **Aceptado**: §4 se reescribe con esa precisión, la limitación queda registrada con el precedente literal de la §11 del feature 10 (misma situación con su §Ruteo), entra al criterio de cierre 3, suma la fila E13b y el riesgo R7. También se modera «precedente exacto» de §1 a **precedente cercano** con la diferencia nombrada: `review.sh` es una constante ejecutable única; esto es una regla declarativa distribuida en dos skills e interpretada por un modelo — lo que sostiene a R4 como riesgo vivo en lugar de darlo por resuelto con la analogía.

### r2 (base `e6d26e2`, HEAD `bfa8956`) — CHANGES_REQUESTED · 2 puntos, los 2 aceptados

Codex dio por bien resuelto todo lo demás de la r1 —definitivo vs. ambiguo, mismo token, cobertura del lote, las atribuciones positivas de E9/E12/E14, el precedente moderado y el deslinde payload/semilla— y validó explícitamente la excepción del criterio 7: E13b es legítima porque su comportamiento se verifica contra `SEED_SRC`. Verificó árbol limpio, `git diff --check` limpio y diff de `scripts/`/`tests/` vacío, sin repetir las suites por no haber delta ejecutable.

1. **«Sin commit intermedio» perdía la degradación ante una caída del padre.** El punto es correcto y desarma mi argumento de la r1: el estado de **control** sí es idéntico antes y después de ese commit, pero la **proveniencia** no. Si el fallback arranca y el padre cae antes de su próximo commit, la reentrada resuelve el token pero no sabe que el hijo corre degradado, así que ledger y RECAP pueden omitirlo — y eso contradice la garantía de registro que es la mitad entera de §5 (sin ella, la objeción de la §10 vuelve intacta). **Aceptado y revertido**: el rechazo definitivo y el modelo elegido se **registran y commitean antes** del segundo spawn, con el mismo token. Dos precisiones que ese commit no puede violar y que quedan escritas: el evento de degradación **no es de arranque** (no desplaza al evento vigente, así que la triple coincidencia del hijo resuelve igual) y la reentrada **no gana rama nueva** (sigue siendo «pendiente `T` + evento `T` ⇒ ambiguo ⇒ RECAP», solo que ahora con la degradación a la vista). Suma la fila **E7f** — el caso que el punto describe — y actualiza el criterio de cierre 1.
2. **Conteo de la matriz mal**: eran **21** filas, no 20 (las 14 originales más las 7 nuevas). Cierto — error de aritmética mío al escribir el r1. Corregido en el Review log, y con la fila E7f de este punto el total pasa a **22**, verificado contando la tabla en vez de a mano (`awk` sobre las filas `E*`). Criterio 7 y STATUS al día.

### r3 (base `e6d26e2`, HEAD `00222a1`) — CHANGES_REQUESTED · 1 punto, aceptado

**La bajada sustantiva quedó lista** según el reviewer: proveniencia commiteada antes del fallback, mismo token, evento vigente intacto y matriz verificada en 22 filas. Árbol y `git diff --check` limpios, sin delta en `scripts/` ni `tests/`.

1. **Review log estructuralmente desordenado (r3).** El punto 3 de la r1 —el del deslinde payload/semilla— había quedado **después** del encabezado de la r2, de modo que r1 anunciaba tres puntos y contenía dos, y r2 anunciaba dos y contenía tres. Causa: la entrada de la r2 se insertó tomando como ancla el final del punto 2 de la r1, que en ese momento era el último bloque escrito. **Aceptado**: el punto vuelve a su lugar, antes de `### r2`, con el contenido intacto (se le quita solo la marca «(r1 p3)», que existía para señalar la pertenencia que el orden ya no dejaba ver).

### r4 (base `e6d26e2`, HEAD `9f338fd`) — **APPROVED de la bajada**

Sin observaciones accionables: «el Review log quedó consistente: r1/r2/r3 contienen 3/2/1 puntos respectivamente. La matriz conserva 22 filas, el delta sustantivo permanece intacto … La bajada está lista para implementar». Con esto arranca la implementación (un paso, las seis sedes).

### r5 (base `e6d26e2`, HEAD `6cfbcaf`) — CHANGES_REQUESTED · 4 puntos, los 4 aceptados

Primera ronda sobre la **implementación**. El reviewer dio por bien implementada la maquinaria principal —sección canónica completa, puntero resolutivo desde `feature`, cinco sustituciones preservadas, reversión de §10 sin reescritura— y los cuatro puntos fueron defectos puntuales, tres de ellos invisibles en la lectura del texto nuevo:

1. **`docs/design/implicit-entry.md` seguía diciendo que `templates/AGENTS.md` es payload.** Línea preexistente del feature 10, que ahora **contradice** el deslinde que este feature acababa de instalar en §4, E13b y `SEED_SRC`. **Aceptado**: reescrita — payload son las skills; la plantilla es semilla, así que su contenido nuevo llega a instalaciones nuevas y no a las existentes, y lo que gobierna el comportamiento en todos los casos son las skills.
2. **La fila de `DESIGN.md` no era una fila.** Había quedado una **línea en blanco** entre la última fila de la tabla y la nueva, lo que en Markdown **termina la tabla**: el texto se renderizaba como párrafo suelto y C6 no se cumplía. **Aceptado**: línea eliminada, tabla continua verificada.
3. **`IMPLEMENTATION.md` desactualizado**: la fila 11 seguía diciendo «bajada fina escrita, en review» cuando la bajada ya estaba APPROVED en r4 y lo que estaba en review era la implementación (C9 y concordancia con STATUS). **Aceptado**: fila al día.
4. **La matriz resuelta declaraba 22 filas y tenía 21 físicas**: E2 y E3 estaban combinadas en una sola línea. Sin hueco de cobertura, pero C7 exige el conteo literal. **Aceptado**: separadas; ambas matrices verificadas por conteo en **22** filas.

**Dato que cierra la discrepancia de `loop.sh`**: Codex confirmó que en su sandbox se **saltea la clase L5** — esos son los seis casos entre sus 287 y los 293 del repo canónico. La nota de verificación queda actualizada con la causa, ya no como diferencia inexplicada.

### r6 (base `e6d26e2` → `74d3f5c`) — **APPROVED de cierre**

Sin observaciones accionables: «Los cuatro puntos de r5 quedaron corregidos y los **nueve criterios de cierre se cumplen**». Verificación independiente del reviewer: ambas matrices con 22 filas, cinco sustituciones, diff mínimo de `feature`, espejo de la regla entre `AGENTS.md` y plantilla, fila de `DESIGN.md` integrada en la tabla, §10 preservada con su nota de reversión, docs de estado coherentes, árbol y `git diff --check` limpios, y ningún cambio en `scripts/` ni `tests/` (las suites habían quedado verificadas en la r5; este commit solo tocaba documentación).

**Seis rondas, dos ciclos**: r1–r4 sobre la bajada (APPROVED en r4) y r5–r6 sobre la implementación. La sustancia se acordó temprano en cada uno —Codex aceptó desde la r1 los alias de familia, el override por gate y el deslinde de la plantilla, y desde la r5 la maquinaria implementada—; los pedidos fueron de completitud y de precisión: el encaje de la degradación con el orden durable de spawn (r1–r2, el más valioso: la proveniencia se perdía sin commitear antes del fallback), la autosuficiencia de la matriz (r1), el deslinde payload/semilla (r1, r5) y cuatro defectos periféricos de la implementación (r5). El feature queda **APPROVED — pendiente OK de pipeline**: el OK humano llega con el RECAP consolidado, no individual.
