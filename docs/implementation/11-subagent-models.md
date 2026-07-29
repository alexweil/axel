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

1. **Ya hay precedente exacto y aceptado**: el modelo del **reviewer** está cableado desde el feature 00 en `scripts/review.sh` (`REVIEW_MODEL="${AXEL_REVIEW_MODEL:-gpt-5.6-sol}"`), que **es payload**, con fila propia en `DESIGN.md` («Config de modelos | Variables al tope de `review.sh` (+ env `AXEL_REVIEW_*`) | Cambiar de modelo o esfuerzo = tocar una línea versionada, sin depender de config global»). axel ya exporta un modelo concreto a todos los destinos y lo considera correcto porque la constante es **visible, versionada y en un solo lugar**. Este feature aplica el mismo régimen al generador hijo; lo que sería incoherente es tratarlo distinto.
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
- **Referencia**: skill `feature`, bullet «Lanzá el hijo» del modo lote — declara su única fila aplicable (`opus`) **en línea**, porque el padre necesita el valor en el punto de uso, y apunta a la canónica para el resto (alias, override, degradación).

Se repite un token (`opus`) en dos archivos, no una máquina: la regla de sincronía queda escrita y el criterio de cierre 2 la verifica. **Alternativa descartada**: un archivo de payload nuevo con la tabla — obligaría a tocar las dos allowlists de `scripts/install.sh` y las aserciones de `tests/install.sh`, superficie ejecutable que ni el plan ni la ruta autorizada previeron, para evitar la duplicación de una palabra. El patrón «canónica + referencia» ya es el del feature 10 (la reentrada del pipeline referencia la del lote en vez de duplicarla).

### 4. Los dos planos en `AGENTS.md` y en la plantilla

Hoy `AGENTS.md` §Roles mezcla ambos: «Generador: Claude Code (hoy: esquema mixto por fase — Fable 5 para `/design` y `/plan`, Opus 5 para `/feature`, esfuerzo xhigh; lo elige el humano en la sesión)». Con este feature son dos cosas distintas:

- **Modelo de la sesión** — el generador que el humano abre. Sigue siendo **su elección**; en axel, hoy, el esquema mixto por fase con esfuerzo xhigh.
- **Modelo de los hijos** — los subagentes de un lote o un pipeline. Lo **fija la maquinaria** por tipo de unidad y **no se hereda** de la sesión: `fable` para los que corren `design`/`plan`, `opus` para los que corren `feature`. Se overridea puntualmente por gate.

**Deslinde de sincronía** (el criterio 4 del feature 10 pide espejo literal de las secciones tocadas, y §Roles hoy **no** lo es): lo que debe ser espejo es la **regla de la maquinaria** —los dos planos y los dos valores—, porque es maquinaria y viaja con el payload. Lo que **no** va a la plantilla es la elección concreta de la sesión de axel (Fable 5 / Opus 5 / xhigh, y el modelo del reviewer): eso es configuración local de este proyecto, y la plantilla ya lo trata así hoy («Modelo y esfuerzo los elige el humano en la sesión», sin nombrar ninguno). El feature preserva ese deslinde y lo deja escrito acá para que el diff sea auditable.

### 5. Indisponibilidad: degradación anunciada, nunca corte

Un destino puede no tener acceso a una de las familias, y el harness puede renombrar o dejar de reconocer un alias. Regla:

> Si el spawn con el modelo fijado es rechazado, el padre **no corta la corrida**: lanza el hijo con el modelo de la sesión, registra un **evento en el ledger** («modelo `X` no disponible: unidad lanzada con el modelo de la sesión») y lo **lista en el RECAP consolidado**.

Por qué no es una excepción al fail-closed del método: el fail-closed protege lo que puede **corromper estado o duplicar trabajo** —reviews en vuelo, tokens de spawn, autorizaciones—; ahí la maquinaria frena y entrega al humano. El modelo del hijo no es de esa clase: el hijo hace el mismo trabajo, con el mismo loop, y el **APPROVED de Codex sigue siendo el gate de calidad**, intacto. Cortar por indisponibilidad convertiría una preferencia de axel en un requisito duro del destino, que es exactamente lo que la §10 quería evitar. Y «anunciada» es la mitad que resuelve su objeción: la degradación queda en dos lugares versionados —ledger y RECAP—, así que **sí la mira alguien**.

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
| E6 | en el gate el humano pide «los hijos de `plan` con Opus» | **gana el override**: ajuste de alcance en el ledger, el padre lo aplica al spawnear | `build` §«Modelos por unidad», override + `## Gate` del ledger |
| E7 | el harness rechaza el spawn con `fable` (sin acceso en este destino) | **no corta**: lanza con el modelo de la sesión, evento en el ledger y línea en el RECAP consolidado | `build` §«Modelos por unidad», degradación |
| E8 | sale la versión siguiente de una familia (p. ej. Opus 6) | **nada que actualizar**: el valor es alias de familia, no ID de API con versión | `build` §«Modelos por unidad», nota de alias |
| E9 | el harness renombra sus alias y `fable` deja de reconocerse | cae en E7 (degradación anunciada); el arreglo es editar la tabla canónica — una línea, en un solo archivo | ídem + §3 (canónica única) |
| E10 | reentrada de un pipeline que tenía un **ajuste de alcance** de modelo; el padre relanza el hijo de una unidad | gana el **ajuste registrado en el ledger**, no la tabla ni el modelo de la sesión que reentra | precedencia escrita en `build` §«Modelos por unidad» |
| E11 | el humano pregunta con qué modelo corre la maquinaria | `AGENTS.md` §Roles distingue los **dos planos**: sesión = su elección; hijos = fijado por la maquinaria, con los dos valores | `AGENTS.md` §Roles |
| E12 | un destino instalado edita la tabla local y luego re-corre el instalador | la skill es **payload**: el re-run la pisa y la edición local se pierde — el camino soportado es el override por gate (o re-editar tras el update), igual que con `review.sh` | riesgo R5 + régimen de payload del instalador |
| E13 | proyecto destino recién instalado | `templates/AGENTS.md` §Roles trae la **regla de la maquinaria** (los dos planos y los dos valores), sin la elección concreta de axel | `templates/AGENTS.md` §Roles |
| E14 | pipeline en **modo POC** | sin excepción: los mismos modelos por tipo de unidad; el modo POC acota el **alcance** del delta, no el modelo | ausencia de excepción en `build` §«Modelos por unidad» |

## Criterios de cierre

1. `.claude/skills/build/SKILL.md` conserva el título §«Modelos por unidad» y su cuerpo tiene: la **tabla de tres filas** (`design-delta` ⇒ `fable`, `plan-delta` ⇒ `fable`, `feature` ⇒ `opus`), el enunciado de que lo fija la maquinaria y **no** se hereda de la sesión, la naturaleza de **alias de familia** (no ID de API) con el perfil de capacidad que justifica cada elección, el **override por gate** con su precedencia de tres niveles, y la **degradación anunciada** (no cortar + evento en el ledger + línea en el RECAP). El bullet «Lanzá el hijo» remite a esa sección.
2. `.claude/skills/feature/SKILL.md`: el bullet «Lanzá el hijo» del modo lote fija `opus` y apunta a la canónica. El **resto del diff de esa skill es vacío**; en particular la tabla del «Modo hijo de pipeline» sigue con **cinco** sustituciones y el texto que las cuenta sigue diciendo cinco.
3. `AGENTS.md` §Roles distingue los dos planos con los dos valores y el override; `templates/AGENTS.md` §Roles trae la misma regla de maquinaria y **no** la elección concreta de axel (ni modelos de sesión, ni el del reviewer). El deslinde es el de §4 y se verifica por `diff` de la sección.
4. `docs/design/implicit-entry.md`: §«Modelos por unidad» enuncia la regla fijada (ya no «puede») y la línea de la lista de decisiones para la bajada queda marcada resuelta; ambas apuntan a este doc.
5. `docs/implementation/10-build-pipeline.md` §10 conserva su texto original **íntegro** y suma una nota de reversión con fecha, feature y las defensas que la habilitan. Nada borrado ni reescrito.
6. `docs/DESIGN.md` suma la fila de decisión del 2026-07-29, con su «por qué» y el puntero a este doc.
7. La **matriz E** se resuelve entera contra el texto final instalado, sin apelar a este doc.
8. **Sin cambios ejecutables**: `git diff` de `scripts/` y de `tests/` **vacío** en el rango del feature; el payload del instalador no cambia. Las tres suites (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`) en verde como no-regresión.
9. `docs/IMPLEMENTATION.md` tiene la fila 11 al día con este doc enlazado, y `docs/STATUS.md` quedó al día en cada commit, con el token de ronda del contrato.

## Riesgos

- **R1 — La preferencia de axel viaja al destino** (el residual de la §10, aceptado): un proyecto instalado hereda `fable`/`opus` aunque su equipo use otra política. Lo acotan las tres defensas: alias de familia que no envejece, override por gate, y degradación anunciada que impide que un destino sin acceso quede bloqueado. Mismo régimen —y misma aceptación— que el modelo del reviewer cableado en `review.sh` desde el feature 00.
- **R2 — La maquinaria fija familia, no versión**: si una versión nueva de la familia es peor o más cara para el caso, el hijo la toma sin aviso. Se acepta: el APPROVED de Codex sigue siendo el gate de calidad, y fijar versión reintroduciría exactamente el envejecimiento silencioso que la §10 señaló.
- **R3 — La evidencia del dominio de alias no es verificable por el reviewer**: el esquema del parámetro `model` es observable desde la sesión de Claude Code, no desde el worktree snapshot. Se declara como observación del harness (§2). Si el harness cambia el dominio, el efecto es E9 y la defensa es la degradación anunciada.
- **R4 — Duplicación del valor `opus` en dos skills**: pueden divergir en un cambio futuro. Mitigación: canónica declarada + puntero explícito + criterio de cierre 2. Alternativa (archivo payload propio) descartada por superficie ejecutable, §3.
- **R5 — El re-run del instalador pisa una edición local de la tabla** (E12): es el régimen de payload de axel, idéntico al de `review.sh`; se documenta en la propia sección para que el destino sepa que el camino soportado es el override por gate.
- **R6 — Un pipeline mixto podría quedar a mitad con dos modelos distintos** si una familia cae a mitad de corrida (pasó en esta misma corrida). No es un riesgo nuevo del feature: el ajuste por gate lo resuelve y queda registrado en el ledger; la matriz lo cubre en E6/E10.

## Review log

_(vacío — la review de la bajada abre el ciclo)_
