# Feature 14 — Onboarding y feedback: CONTRIBUTING + `.github/` + métricas versionadas

> Bajada fina de la §14 de [../IMPLEMENTATION.md](../IMPLEMENTATION.md). Diseño: [../design/public-surface.md](../design/public-surface.md). Contrato con el feature 13: [13-public-showcase.md](13-public-showcase.md).

## Procedencia y autorización

Unidad `14` (tipo `feature`) del **tercer** pipeline `/build` del 2026-07-29 — ledger [pipeline-2026-07-29-3.md](pipeline-2026-07-29-3.md). No hubo gate individual: la autorización es la **del gate de pipeline**, recibida el 2026-07-29 con el literal «dale, autorizado — el push y los topics los hago yo». Pedido de `/build` que lo originó (literal breve; el texto completo vive en el bloque Gate del ledger): «Dejar el repo público de axel presentable para compartirlo: README en inglés escrito para quien lo descubre, licencia MIT, y los docs de onboarding y feedback que faltan».

**Ajuste de alcance (b) del gate, que manda sobre esta unidad**: el pipeline **no toca GitHub ni pushea** — ni `git push`, ni topics, ni homepage, ni ninguna otra acción sobre el remoto o sus settings. Esta unidad **deja los tres comandos exactos listos y no ejecuta ninguno**; correrlos desde acá es divergencia ⇒ corte.

SHA de arranque de la unidad: `6ec4b48`.

**Dos superficies distintas dentro de la unidad, y confundirlas rompía el criterio de alcance** (hallazgo de la r1). Entre el SHA de arranque y el primer commit del hijo está `2985447`, el commit con que el **padre** registró el arranque en el ledger. Entonces:

| Rango | De quién | Qué toca |
|---|---|---|
| `6ec4b48..2985447` | **padre** — registro del arranque | `docs/STATUS.md` y el ledger |
| `2985447..HEAD` | **hijo** — el trabajo de esta unidad | la lista cerrada de §Alcance, **sin el ledger** |

El baseline del trabajo del hijo es **`2985447`**, no `6ec4b48`. C12 audita el segundo rango; el primero se audita aparte y ya está verificado arriba.

**`AUTORIZADOS` — lista cerrada de commits del padre dentro del rango del hijo.** Si el padre commitea al ledger durante este ciclo (el contrato le deja una sola excepción: corregir una falsedad vigente), su SHA entra acá **en la misma ronda**, y C12 lo exige declarado. Sin esa lista, un commit del padre haría fallar el criterio de alcance del hijo o —peor— pasaría inadvertido.

- `2985447` — arranque de la unidad. *(Es la frontera del rango, no un commit interior; se lista para que la lista sea legible sola.)*

Cualquier SHA que aparezca en `2985447..HEAD` tocando el ledger y **no** esté en esta lista es una divergencia y se reporta, no se absorbe.

## Alcance

Entra: `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/`, el informe de métricas, el snapshot del `rounds-log` **y los dos `awk` que lo derivan** (§2 — el comando declarado tiene que correr), la **activación de las dos referencias pendientes** del `README.md`, este doc, `docs/IMPLEMENTATION.md` y `docs/STATUS.md`.

No entra, y tocarlo es divergencia ⇒ corte: el método (`AGENTS.md` y su espejo `templates/AGENTS.md` — incluida la **deuda normativa declarada** de la línea «Docs, commits y comunicación en español», que el diseño dejó explícitamente fuera de la ruta), las skills, el instalador, los scripts, los tests, el ledger del pipeline (territorio del padre), `.claude/state/` como directorio versionado, y toda acción sobre el remoto. Del `README.md` se tocan **solo** las dos referencias pendientes y lo que su activación arrastra; el resto de su prosa no se reabre.

## La inconsistencia entre docs sobre el corte, resuelta explícitamente

El padre la detectó en el pre-arranque y la pasó a esta unidad en vez de resolverla él, con razón: elegir en silencio entre dos cifras que se contradicen es exactamente el defecto que este feature existe para no cometer.

| Fuente | Qué dice |
|---|---|
| §14 de `IMPLEMENTATION.md` | «**80** rondas registradas al corte `e1e1282`» |
| Unidad `13`, §«El corte de métricas» | corte **`b0bdf4d`**, **88** rondas |

**Gana `b0bdf4d`, y no por antigüedad sino por contrato.** El contrato entre features fija que el **13 declara** un commit de corte que ya exista y que el **14 reconstruya exactamente ese corte**, «no saca foto nueva» (§14, «Contrato con el 13»). La cifra que la §14 cita es una **foto anterior**, heredada del delta de diseño, que se escribió cuando el corte vigente era `e1e1282`; el 13 declaró el suyo después, y es el que el contrato manda reconstruir.

Las dos cifras son ciertas **cada una en su corte** y ninguna está mal medida: `e1e1282` es anterior a las dos unidades de delta de este pipeline, cuyos ciclos (4 rondas cada uno) más el resto explican la diferencia. No se corrige la §14 —es del plan, aprobado, y su cita describe correctamente el estado en que se escribió—; se la trata como **histórica**. Lo que este feature publica sale del corte `b0bdf4d`.

Es además la tercera vez en este pipeline que el mismo fenómeno aparece —el diseño lo registró como su hallazgo 3, el 13 lo vio en vivo cuando su propia r1 movió el log de 88 a 89 filas—, y es la razón entera por la que la evidencia se publica como foto fechada.

## Regla de contadores móviles, adoptada de la unidad 13

La unidad `13` cerró tras veinte rondas y dos cortes por tope, y su lección central es de clase, no de caso: **ningún contador que el propio proceso mueve se publica en prosa**. Ni el número de commits de la unidad, ni el de rondas del ciclo, ni el tamaño de una lista que crece. Toda cifra de esa familia va como **foto anclada a un SHA** o como **comando de derivación**.

Esta bajada la adopta sin excepción, y no solo para los artefactos publicados: **también para este doc**. El diagnóstico que la motiva es que publicar un contador móvil *garantiza* que la corrección siguiente desincronice la frase que lo describe — es un lazo, no un descuido acumulado.

## Las cinco preguntas de la bajada, resueltas

### 1. Cuántas plantillas y cuáles — **dos**, más `config.yml`

La pregunta trae su propio criterio: de más plantillas se llenan menos, así que se decide contra el objetivo declarado —que el reporte de un colega llegue **accionable**— y no contra la ambición de cubrir casos.

Los tres candidatos del pedido eran *fallo de instalación*, *fricción de uso* y *pregunta*. Quedan **dos**:

| Archivo | Por qué existe |
|---|---|
| `install-failed.yml` | Es el único caso donde la estructura paga: hay un conjunto **enumerable y corto** de hechos que vuelven diagnosticable un rechazo (la línea final `── axel · fin: rc=N · … ──`, el modo anunciado, las reglas del `.gitignore` del destino, si el árbol estaba limpio). Un reporte libre omite esos hechos de forma fiable, y los tres problemas conocidos del manual son justamente casos donde el mensaje de rechazo es críptico por sí solo. |
| `friction-or-question.yml` | *Fricción* y *pregunta* se fusionan. La distinción entre «esto me confundió» y «¿cómo funciona X?» no es una que **quien reporta** pueda hacer con confianza, y no cambia en nada lo que necesitamos de él. Partirla no compra información y cobra una elección en la puerta. |

**Formato: issue forms YAML**, no plantillas markdown. La razón es la única que importa acá: los campos `required` los hace cumplir GitHub, y «accionable» deja de depender de que el reportante lea una instrucción. Costo declarado: un YAML mal formado hace que GitHub descarte la plantilla, así que **se valida con un parser** y no a ojo (criterio C6).

**Sin clave `labels:`, y es una decisión, no un olvido.** Aplicar una etiqueta que no existe en el repo es un settings de GitHub, y crear etiquetas está fuera del alcance por el ajuste (b). Declarar `labels:` apuntando a etiquetas inexistentes sería publicar una afirmación que no podemos verificar y que el pipeline tiene prohibido volver verdadera.

`config.yml` deja `blank_issues_enabled: true` —en una primera ronda de feedback, cerrar la puerta a lo que no encaja en dos formularios pierde más de lo que ordena— y un `contact_links` a `CONTRIBUTING.md`.

### 2. Cómo se reconstruye mecánicamente el corte — filtrado fail-closed por SHA

El *cuándo* no es pregunta: el contrato lo fija en el commit que el 13 declaró. Queda el **cómo**, y el 13 ya lo dejó resuelto y probado en sus cuatro modos de falla. Esta unidad lo **reusa sin reinventarlo** y verifica que sigue valiendo:

```sh
awk -v cut=b0bdf4d -f docs/metrics/cut.awk .claude/state/rounds-log > docs/metrics/rounds-log-b0bdf4d.tsv
```

**Los dos `awk` se versionan como archivos** —`docs/metrics/cut.awk` y `docs/metrics/normalize.awk`—, y esto es una decisión que la r1 forzó a tomar: la bajada anterior publicaba comandos que invocaban archivos inexistentes en el árbol, o sea un «comando de derivación declarado» que no corre. Las tres salidas eran inlinear los programas en la línea de comandos (ilegibles a ese tamaño), publicarlos en bloques con un «guardá esto como…» (deja al lector transcribiendo, que es justo el paso donde se cuela el error) o versionarlos. **Versionarlos** es la única que hace verdadero lo que el diseño pide. Expande la superficie nombrada por el plan en dos archivos, y queda declarado acá como decisión y no como deriva: son la herramienta del artefacto de métricas, inseparables de él — sin ellas la evidencia no es re-derivable, que es la propiedad entera por la que existe.

con las tres postcondiciones obligatorias: `rc=0`, exactamente **88** filas, y la última fila con el SHA de corte. Verificado en esta unidad al arrancar: el `rounds-log` vivo tiene hoy más filas que el corte —las veinte rondas de la unidad `13` entraron después—, y la reconstrucción devuelve **88** igual. Ese es el punto entero del corte.

**Las filas sin SHA**: los eventos **pre-invocación** (`DEADLOCK`, `INPUT_ERROR`) llevan `-` en ronda, intento y SHA. **No son rondas** y quedan fuera por construcción, porque el normalizador solo procesa filas cuyo campo de ronda es numérico (`$3 ~ /^[0-9]+$/`). No se filtran aparte ni se borran del snapshot: **el snapshot los conserva** —es una copia literal— y el normalizador es quien los descarta al contar. Esa división importa: el dato crudo no se edita, la interpretación es la que decide qué cuenta.

### 3. Snapshot: **copia literal**, no proyección

Las dos salidas eran copia literal (más auditable, arrastra un formato interno que no es contrato público) o proyección (formato propio, más legible, exige confiar en la proyección).

**Copia literal**, por tres razones:

1. La proyección **es** una interpretación, y publicarla como evidencia obliga al lector a confiar justo en el paso que debería poder auditar. El producto que axel vende es que no haga falta confiar.
2. El recorte ya es un prefijo del archivo real: `cut.awk` emite las líneas 1..88 sin tocarlas. Cualquiera con la máquina puede verificar que el snapshot es un prefijo exacto del `rounds-log` vivo, y eso es una comprobación de una línea.
3. La objeción del formato interno se responde **documentándolo, no reemplazándolo**: el informe publica el esquema de los siete campos y declara que es un formato interno que puede cambiar. El snapshot es una **foto de lo que el archivo era**, no una interfaz prometida — y eso hay que decirlo, que es distinto de disfrazarlo con una proyección estable que tampoco lo es.

El snapshot es **neutro de idioma** por decisión del diseño: marcas de tiempo, veredictos y SHA. Vivir bajo `docs/` no lo vuelve un doc del método.

### 4. Cómo se citan las 35 rondas previas a la instrumentación — **rotuladas y con las dos fuentes separadas**

No se derivan con el mismo comando que las 88: no tienen esquema tabular.

**La partición es la del diseño —30 + 5, dos fuentes— y la bajada anterior la había regrupado mal** (hallazgo de la r1). Yo había escrito 25 + 5 + 5 atribuyendo las cinco rondas del feature 03 a una **inferencia desde el snapshot** (su primera fila ya es la ronda 6, luego faltan cinco). La aritmética daba igual, pero la procedencia no: `public-surface.md` fija **30 rondas en review logs versionados, incluidas las r1–r5 del feature 03**. Una inferencia no reemplaza a un documento que registra las rondas una por una.

| Tramo | Valor | Fuente **autoritativa** |
|---|---|---|
| features 00, 01, 02 | 4 + 11 + 10 = **25** | sus review logs versionados, vía la ronda de cierre que registra la tabla del plan al corte |
| feature 03, rondas 1–5 | **5** | `03-loop-hardening.md`, cuyo Review log las registra una por una |
| **subtotal en review logs versionados** | **30** | — |
| ciclo de plan inicial | **5** | **segunda fuente, citada aparte**: no tiene doc en `implementation/`; su memoria son los commits y el STATUS histórico (`2f7c814`) |

**30 + 5 = 35**, y **88 + 35 = 123**. La inferencia desde el snapshot **se conserva, degradada a contra-chequeo independiente**: la primera fila del snapshot es la ronda 6, lo que confirma desde otra fuente que al feature 03 le faltan exactamente cinco. Dos fuentes que coinciden valen más que una; lo que no vale es presentar la débil como si fuera la fuerte.

**Límite de la derivación de las 25, publicado porque existe**: sale de la **ronda de cierre** que la tabla del plan registra para cada feature, no de contar entradas del review log. No son lo mismo — el Review log de `01-installer.md` lista diez entradas y su ronda de cierre es la **11**, porque una ronda no quedó listada. La ronda de cierre es la cifra correcta y por eso es la que se usa; contar entradas daría 10 y sería un error silencioso.

Regla de publicación, fijada por el diseño y no negociable: **dos cifras rotuladas** —«88 logged rounds since instrumentation» y 123 como total histórico con su segunda fuente— y **nunca una sola cifra sin decir a cuál corresponde**.

**«Cero aprobados en ronda 1» se demuestra sobre los 23 ciclos, no sobre los 18.** El log da 18/18 `CHANGES_REQUESTED` en la r1 de cada ciclo; los **cinco** ciclos anteriores a la instrumentación hay que verificarlos en sus propias fuentes, y están verificados: `00-bootstrap.md` r1 `CHANGES_REQUESTED`, `01-installer.md` r1 `CHANGES_REQUESTED`, `02-remote-install.md` r1 `CHANGES_REQUESTED`, `03-loop-hardening.md` r1 `CHANGES_REQUESTED`, y el ciclo de plan en `git show 2f7c814:docs/STATUS.md` («la ronda 1 pidió cambios»). **18 + 5 = 23**, que es exactamente la cifra que el README publica.

### 5. Topics y homepage — valores concretos, argumentados, y **no ejecutados**

El gate autorizó «los comandos exactos», y la §14 fija la vara: los tres tienen que **pegarse en una terminal sin editarlos**, con herramienta, sintaxis y precondiciones declaradas y **cero huecos**. Proponer no es decidir — el humano es quien los corre y puede cambiar cualquier valor antes.

**Herramienta**: `gh` (GitHub CLI), verificado presente en esta máquina en la versión **2.94.0**. **Precondiciones**: `gh auth status` sin error, y estar parado dentro del repo. Sin `gh`, los dos últimos se hacen desde *Settings → General* y la caja *About* en la web; el push no lo necesita.

**Flags verificados contra `gh repo edit --help`** —no transcritos de memoria—: `--add-topic strings` (acepta lista separada por comas) y `-h, --homepage URL`. Nota que conviene saber antes de pegar: en este subcomando **`-h` es `--homepage`, no `--help`**.

**Topics propuestos — ocho, cada uno justificado por algo que el repo ya es**:

| Topic | Por qué |
|---|---|
| `claude-code` | el generador es Claude Code: `AGENTS.md`, `.claude/skills/` y el symlink `CLAUDE.md` son el artefacto |
| `codex` | el reviewer es el Codex CLI, invocado por `scripts/review.sh` |
| `ai-code-review` | lo que hace el loop: cada cambio revisado por el modelo de otro proveedor |
| `code-review` | el término con que alguien lo busca sin saber que existe la categoría de arriba |
| `ai-agents` | la categoría en que el lector lo va a ubicar |
| `multi-agent` | descriptivamente exacto: dos agentes con contextos separados, no dos instancias del mismo |
| `developer-tools` | la categoría de GitHub |
| `llm` | término de descubrimiento amplio |

Los cuatro primeros son los específicos y los que más carga llevan; los cuatro últimos son de descubrimiento. Ninguno afirma nada que el repo no sea. El humano puede borrar cualquiera sin tocar el resto del comando.

**Homepage propuesta**: `https://github.com/alexweil/axel/blob/main/docs/install.md`.

El argumento, con su límite dicho de frente: **axel no tiene sitio web**, así que ninguna opción disponible es un homepage en el sentido literal del campo. De las que hay, el manual es la más útil: el campo se renderiza como link en la caja *About*, al lado del README, y la pregunta que sigue a leer el README es «¿cómo lo hago andar?». Alternativas defendibles, que el humano puede preferir, cada una entregada como comando completo y no como hueco: el doc de métricas (coherente con el posicionamiento — la caja *About* apuntando a la evidencia) o `docs/DESIGN.md`.

**Dónde se entregan**: en este doc, §«Los tres comandos de GitHub» — **no** en la vidriera. Un colega que lee `CONTRIBUTING.md` no tiene permisos de administración sobre este repo, así que publicarlos ahí es ruido para todos sus lectores menos uno. El padre los lleva al RECAP consolidado, que es donde el humano los va a leer.

## Los tres comandos de GitHub — listos, exactos, **no ejecutados**

> **No los corre esta unidad.** El ajuste (b) del gate los sacó del alcance del pipeline; ejecutarlos desde acá es divergencia ⇒ corte. Se entregan para que los corra el humano.

Precondiciones: `gh auth status` sin error; parado dentro del repo. El push no depende de nada pendiente.

```sh
# 1 · publicar main (al escribir esto, main está por delante de origin/main)
git push origin main

# 2 · topics
gh repo edit alexweil/axel --add-topic claude-code,codex,ai-code-review,code-review,ai-agents,multi-agent,developer-tools,llm

# 3 · homepage
gh repo edit alexweil/axel --homepage "https://github.com/alexweil/axel/blob/main/docs/install.md"
```

Alternativas completas para el 3, si el humano prefiere otro destino:

```sh
gh repo edit alexweil/axel --homepage "https://github.com/alexweil/axel/blob/main/docs/metrics.md"
gh repo edit alexweil/axel --homepage "https://github.com/alexweil/axel/blob/main/docs/DESIGN.md"
```

**Cuánto está `main` por delante**: no se publica acá como número —es un contador que se mueve con cada commit de esta misma unidad—; se deriva con `git rev-list --count origin/main..main`.

## Paths elegidos

La decisión que el diseño le asignó a este feature, con la distinción de planos que le encarga mantener:

| Artefacto | Path | Plano | Por qué ahí |
|---|---|---|---|
| Informe de métricas | `docs/metrics.md` | **vidriera ⇒ inglés** | prosa para el lector de afuera; hermano de `docs/install.md`, que ya es vidriera bajo `docs/` |
| Snapshot del log | `docs/metrics/rounds-log-b0bdf4d.tsv` | **dato ⇒ neutro de idioma** | el corte va **en el nombre del archivo**: vuelve imposible confundir dos fotos, y un re-corte futuro **agrega** un archivo en vez de pisar el anterior — que es lo que el diseño pide cuando habla de re-cortar |
| Recorte al corte | `docs/metrics/cut.awk` | **herramienta ⇒ neutro**, mensajes en inglés | el comando declarado tiene que **correr**; ver §2 |
| Normalizador a rondas | `docs/metrics/normalize.awk` | ídem | ídem |
| Cómo dar feedback | `CONTRIBUTING.md` | **vidriera ⇒ inglés** | raíz, que es donde GitHub lo levanta y lo ofrece al abrir un issue o un PR |
| Plantillas | `.github/ISSUE_TEMPLATE/{install-failed,friction-or-question,config}.yml` | **vidriera ⇒ inglés** | path fijado por GitHub |

Que `docs/metrics.md` y `docs/metrics/` convivan es deliberado: el doc y sus datos, visibles como dos cosas distintas en el árbol, que es exactamente la partición de planos del diseño hecha topología.

## Fuente única: qué significa exactamente, y por qué la línea va donde va

El diseño dice «toda cifra de la vidriera vive en el doc de métricas y el README la cita», con el fundamento explícito de que «dos lugares con el mismo número son dos lugares para envejecer distinto». Aplicado sin precisar, eso obligaría a mudar al doc de métricas los códigos de salida del instalador y la cantidad de principios, que es absurdo. Precisar la línea **acá y por escrito** es parte del trabajo, porque una regla que cada ronda interpreta distinto es una regla que churnea.

**La regla, tal como esta unidad la aplica**: una cifra de la vidriera está sujeta a fuente única si es una **cuenta sobre un corpus que sigue creciendo** —el `rounds-log`, la historia de este repo, la historia del repo externo—. Ésas viven en `docs/metrics.md` con su corte y su comando, y cualquier otra mención de la vidriera las **cita** sin re-derivarlas. Concretamente:

- **Sujetas**: 88 rondas, 59 rechazos, 29 hitos, 123 histórico, 35 previas, 23 ciclos, «cero aprobados en ronda 1»; las del gancho (commits, días, features cerrados); y las de la instalación externa (185 commits en `4908bfb`, 20 archivos, 8 archivos) — que van al doc de métricas **aunque no sean del reviewer**, porque son de la misma especie y porque ya fueron el sitio de un defecto real: la r19 del 13 encontró ahí un contador publicado sin corte y atribuido al SHA equivocado.
- **No sujetas**: constantes del artefacto que no cuentan nada creciente (códigos de salida `0/1/2`, siete comandos, cinco principios, «más de 10 minutos», que es limitación declarada y no medición), y las **citas internas del transcript** (ronda 1, ronda 7, `f85a033`, `886fe4f`), que son referencias a una corrida cerrada y están cubiertas por el criterio de «ninguna línea inventada» del 13.

El chequeo que la vuelve mecánica, **con su alcance dicho** (la r1 marcó que la versión anterior era literalmente falsa: los docs internos de los features 13 y 14 publican esos comandos, y deben hacerlo):

> Dentro de la **superficie pública** —`README.md`, `docs/install.md`, `CONTRIBUTING.md` y `.github/`—, toda cifra sujeta aparece en `docs/metrics.md` **con el mismo valor**, y **ningún comando de derivación** de una cifra sujeta vive fuera de `docs/metrics.md`.

Los docs del **método** (`docs/implementation/*.md`, `docs/design/*.md`) quedan explícitamente fuera de la regla: son la memoria del loop, ahí las derivaciones **deben** estar, y confundir los dos planos es lo que volvía incumplible el enunciado anterior. El chequeo recorre el conjunto público **completo**, no solo el inventario del README.

## Enfoque

### `docs/metrics.md` — el informe

Inglés. Estructura:

1. **Qué es y qué no** — la foto y su corte; que no incluye las rondas de los features 13 y 14, declarado y no escondido.
2. **Las tres unidades que no se mezclan** — ronda, hito, ciclo, con la advertencia de que los `APPROVED` son **hitos y no features**, y que enunciarlo mal es lo que destruye la credibilidad.
3. **Las cifras, como matriz** `cifra → fuente autoritativa → corte → comando → límite de auditabilidad`. La forma la impuso la r1, y con razón: **no todas las cifras se derivan del snapshot**, así que prometer «se re-derivan sobre el snapshot versionado» era incumplible. Hay tres familias, y la matriz las distingue en vez de aplanarlas:

   | Familia | Fuente autoritativa | ¿Auditable desde un clon de axel? |
   |---|---|---|
   | rondas, rechazos, hitos, ciclos, medianas | el snapshot versionado | **sí**, con `cut.awk` + `normalize.awk` |
   | gancho (commits, días, features al corte) | la historia git de **este** repo, anclada a `b0bdf4d` | **sí** |
   | 35 previas a la instrumentación | review logs versionados + commits y STATUS histórico | **sí** |
   | instalación externa (185 commits, 20 y 8 archivos) | la historia git de **`alexweil/inquirylab`** | **no** — ver abajo |

4. **Cómo re-derivarlas** — el esquema de los siete campos del snapshot, `cut.awk`, `normalize.awk` (versionados, no transcritos), y las postcondiciones como postcondiciones (`rc=0` obligatorio), no como cortesía.
5. **Qué no prueba esta evidencia**, en dos límites distintos y ambos declarados:
   - El contra-chequeo contra SHA verifica que los commits existen, que las fechas cierran y que la historia es **lineal**; **no** prueba que nadie la haya reescrito antes de publicarla, porque un force-push previo es indetectable desde un clon. Se afirma lo primero y no lo segundo.
   - **Las cifras de la instalación externa no son re-derivables desde un clon de axel**, y decirlo es obligatorio: `4908bfb`, `846308f` y `98c70c0` son objetos de **otro repositorio** (`alexweil/inquirylab`), no de éste. Sus comandos se publican igual —anclados a esos SHA— pero **rotulados como verificables solo contra ese segundo repo**. Versionar una copia de esa evidencia acá está fuera del alcance de esta unidad y no se hace de contrabando: se declara el límite. Es exactamente la clase «limitación declarada» del contrato editorial, y afirmarlas como derivables sin más sería la afirmación más ancha que su evidencia que este feature existe para no hacer.
6. **Las 35 previas a la instrumentación**, con sus dos fuentes citadas por separado.
7. **Un ejemplo de review que atrapó algo real** — feature 11, ronda 5: cuatro defectos en texto ya commiteado, corregidos en `74d3f5c` y aprobados en la ronda 6. El que mejor ilustra la clase es que una **línea en blanco antes de una fila de tabla termina la tabla en Markdown**: la fila se renderizaba como párrafo suelto y un criterio de cierre quedaba incumplido — invisible leyendo el diff como texto, visible para quien mira el resultado.
8. **La mediana**, con el aviso obligatorio que el 13 dejó: volvió a dar **4 por ciclo** al corte `b0bdf4d` y **no** es la reaparición del error que corrigió el delta de diseño — mismo número, criterio distinto, corte distinto. Va acá y **no** al README, que es donde el criterio se puede explicar.

**Los dos `awk` van en inglés**, traducidos de los que el 13 dejó en su doc: la lógica es idéntica y solo cambian los mensajes de error, porque el informe es vidriera y su lector lee esos mensajes. Se verifica que ambas versiones producen **salida idéntica** sobre el snapshot (C4) — un doc de auditabilidad no puede publicar una herramienta que no es la que se corrió.

### `CONTRIBUTING.md`

Inglés, orientado a **qué feedback busca esta ronda**:

- **Qué se busca ahora**: colegas instalándolo y contando qué se rompió. Explícitamente **no PRs de código**, con la razón dicha y no escondida: cada cambio de este repo pasa por el loop de dos agentes con checkpoint humano, y hoy no hay camino por el que un PR externo entre a ese loop. Decirlo es más honesto que dejar la puerta entornada.
- **Cómo reportar que el instalador rebotó**: qué información sirve, con los campos que la plantilla pide y por qué cada uno.
- **Qué está fuera de alcance hoy**, con link a donde ya está documentado: los tres problemas conocidos y el **aviso MIT que todavía no viaja con el payload** — que se declara como incumplimiento pendiente, igual que en el manual, y no como cumplimiento parcial.
- **Qué hace un buen reporte**, en tres líneas.

### `.github/ISSUE_TEMPLATE/`

- `install-failed.yml` — campos requeridos: la línea final `── axel · fin: rc=N · … ──`, la salida completa, sistema operativo y versión de git, y el estado del `.gitignore` del destino respecto de `build/`. Requerido también un checkbox de que el árbol estaba limpio, porque es la causa de rechazo más común después de la colisión.
- `friction-or-question.yml` — qué estabas haciendo, qué esperabas, qué pasó, dónde buscaste primero. El último campo es el que dice si el problema es el producto o el manual.
- `config.yml` — `blank_issues_enabled: true` y un `contact_links` con las tres claves que el esquema exige (`name`, `url`, `about`). El `url` tiene que ser **absoluto**, así que queda fijado acá y no se decide al implementar: `https://github.com/alexweil/axel/blob/main/CONTRIBUTING.md`.

**Los dos formularios llevan `name`, `description` y `body`**, que el esquema de GitHub exige a nivel raíz, y cada elemento de `body` su propia sintaxis (`type`, y `attributes.label` en los que lo requieren). Es lo que C6 verifica; ver el punto siguiente.

### `README.md` — edición acotada

Dos referencias que el 13 dejó **a propósito** sin linkear y marcadas como pendientes, y que este feature activa:

1. El bloque en cursiva del encabezado, que dice que el doc de métricas llega en el feature 14 ⇒ pasa a citar `docs/metrics.md` como link.
2. El blockquote final, que nombra en prosa el doc de métricas y la vía de feedback ⇒ desaparece como marca de pendiente; sus dos destinos entran a §Links como links.

Nada más de la prosa del README se reabre. Si al implementar apareciera una tercera cosa que activar, no se activa por cuenta propia: se registra y se pregunta.

## Criterios de cierre

| # | Criterio | Cómo se verifica |
|---|---|---|
| C1 | El snapshot es la **reconstrucción exacta** del corte `b0bdf4d` que declaró el 13: `rc=0`, **88** filas, última fila con ese SHA | corrida de `cut.awk` con sus tres postcondiciones |
| C2 | El snapshot es **prefijo literal** del `rounds-log` vivo — ni una línea editada | comparación mecánica contra las primeras 88 líneas del archivo vivo |
| C3 | `docs/metrics.md` publica sus cifras como **matriz** `cifra → fuente autoritativa → corte → comando → límite de auditabilidad`, y **toda cifra cuya fuente sea auditable desde un clon de axel se re-deriva y coincide**. Las que no lo son —las de la instalación externa, que viven en otro repositorio— quedan **rotuladas como verificables solo contra ese repo**, nunca prometidas como re-derivables desde acá | re-corrida de la matriz, fila por fila; para las no auditables, inspección del rótulo |
| C4 | Los `awk` publicados en inglés producen salida **idéntica** a los del 13 sobre el mismo snapshot | diff de las dos salidas; debe ser vacío |
| C5 | **Fuente única, acotada a la superficie pública**: en `README.md`, `docs/install.md`, `CONTRIBUTING.md` y `.github/`, toda cifra sujeta (definición de §«Fuente única») aparece en `docs/metrics.md` con el mismo valor, y ningún comando de derivación de una cifra sujeta vive fuera de `docs/metrics.md`. Los docs del método quedan fuera de la regla, por definición y no por excepción | inventario de cifras del **conjunto público completo** —los cuatro, no solo el README—, una por una |
| C6 | Los tres YAML de `.github/ISSUE_TEMPLATE/` **parsean** *y* **cumplen el esquema de issue forms de GitHub**: los dos formularios con `name`, `description` y `body` en la raíz y cada elemento de `body` con su `type` y los atributos que ese tipo exige; `config.yml` con `blank_issues_enabled` y cada `contact_links` con `name`, `url` **absoluto** y `about`. Parsear no es validar: un archivo puede ser YAML legal y no ser un issue form | `ruby -ryaml` (stock de macOS) para el parseo **más** una validación estructural del esquema, contra la [sintaxis oficial](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms); los campos requeridos, uno por uno |
| C7 | **Las dos referencias del 13 son links que resuelven**, y no queda ninguna marca de «pendiente para el 14» en el README | inspección de los dos puntos + chequeo de destinos |
| C8 | **Cero link roto** en el conjunto completo — `README.md`, `CONTRIBUTING.md`, `docs/metrics.md`, `docs/install.md` | chequeo mecánico de todo destino relativo y de toda ancla interna contra los encabezados reales |
| C9 | **Cero afirmación no verificable**: toda oración de `CONTRIBUTING.md` y `docs/metrics.md` cae en una de las tres clases del contrato editorial (hecho derivable con su comando · limitación declarada · opinión marcada) | pasada por oración, registrada en el Review log |
| C10 | `CONTRIBUTING.md` declara **qué está fuera de alcance hoy** incluyendo el aviso MIT como **incumplimiento pendiente**, no como cumplimiento parcial | lectura literal |
| C11 | Los **tres comandos de GitHub** están escritos pegables sin editar, con herramienta, sintaxis y precondiciones declaradas y cero huecos. Sintaxis y completitud se verifican **offline**: cada flag existe en `gh repo edit --help`, cada valor está presente, ningún hueco | inspección contra la salida de `--help`, sin red |
| **C11b** | **No-ejecución**: ninguno de los tres se corrió contra el remoto | **Invariante operativa del pipeline, no evidencia derivable del commit** — y rotularla como prueba mecánica era una afirmación más ancha que su evidencia (hallazgo de la r1): un push no deja «commits de push», `origin/main..main` no tiene baseline versionado y no dice nada de topics ni homepage, y el repo no registra qué invocaciones de `gh` ocurrieron. Lo que sí se puede asentar, y es lo que se asienta: el registro explícito de que la unidad no las ejecutó, con las únicas invocaciones de `gh` declaradas (`--help`), verificable por el padre contra el ledger y por el humano contra el estado del repo remoto cuando vaya a correrlos |
| C12 | **Alcance**: el diff del **trabajo del hijo** —`2985447..HEAD`, no `6ec4b48..HEAD`— toca solo la lista cerrada de §Alcance, **sin el ledger**; cero cambios en método, skills, instalador, scripts, tests o remoto. Todo commit del padre dentro del rango está declarado en `AUTORIZADOS` | `git diff --name-only 2985447..HEAD` contra la lista cerrada, más `git log --format=%h 2985447..HEAD -- docs/implementation/pipeline-2026-07-29-3.md` contrastado contra `AUTORIZADOS`: cualquier SHA no declarado falla el criterio |
| C13 | **La inconsistencia del corte quedó resuelta por escrito**, con la razón contractual y no por preferencia | §«La inconsistencia entre docs», presente y citada desde el informe si corresponde |
| C14 | No-regresión: `tests/lint.sh`, `tests/loop.sh` y `tests/install.sh` limpios | corrida de las tres suites |

## Riesgos

1. **La regla de fuente única es interpretable, y una regla interpretable churnea.** Es el riesgo más probable de esta unidad. Mitigación: la línea está **fijada por escrito antes de implementar** (§«Fuente única»), con la clase incluida, la clase excluida y el chequeo mecánico que la aplica. Si el reviewer no acepta la línea, se discute la línea una vez — no cifra por cifra.
2. **Contadores móviles reapareciendo en prosa.** Es la causa de las dos rachas de la unidad 13. Mitigación: la regla adoptada arriba, aplicada también a este doc; donde hace falta un número que se mueve, va el comando.
3. **YAML que GitHub descarta en silencio.** Un formulario mal formado no avisa: simplemente no aparece. Mitigación: C6 valida con un parser real, no a ojo.
4. **Tentación de correr los comandos de GitHub** —están escritos, verificados y a un `Enter` de distancia—. Mitigación: el corte está declarado como consecuencia, y C11b **no finge** que la no-ejecución sea demostrable desde el commit: es una invariante operativa que se sostiene por el contrato del pipeline y se asienta como registro, no como prueba. Prometer una prueba mecánica que no existe habría sido peor que no prometer nada — daba una garantía falsa exactamente donde importa.
5. **El corte envejece mientras se trabaja.** Las rondas de esta misma unidad entran al `rounds-log`. Mitigación: es exactamente lo que el corte neutraliza; la consecuencia (el snapshot no incluye las rondas de los features 13 y 14) se **publica**.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Sigue siendo una línea a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.
7. **Ampliar la edición del README.** El contrato dice «activar dos referencias», no «revisar la vidriera». Mitigación: C7 acota, y ante una tercera cosa que parezca necesaria se registra y se pregunta en vez de decidir solo.

## Review log

### r1 (base `6ec4b48`, HEAD `225e5f3`) — CHANGES_REQUESTED · 6 puntos, los 6 aceptados sin argumentar ninguno

Codex dio por buenas las decisiones de fondo —`b0bdf4d` gana por contrato y no por conveniencia, dos formularios más `config.yml`, la homepage al manual sin fingir que existe un sitio— y verificó que **no hay ningún contador móvil sin anclar en la prosa de esta bajada**, que era el riesgo 2. Los seis puntos son de rigor de los criterios, no del plan de ataque. **Cuatro de los seis son la misma familia: un criterio que promete más de lo que su evidencia puede sostener.**

1. **C12 fallaba contra su propio rango.** Exigía cero cambios en el ledger usando `6ec4b48` como base, pero ese rango **incluye** el commit de arranque del padre `2985447`, que toca el ledger — o sea que el criterio nacía incumplible. Separadas las dos superficies: `6ec4b48..2985447` es el arranque del padre (toca `docs/STATUS.md` y el ledger, verificado), y `2985447..HEAD` es el trabajo del hijo. Agregada además la lista cerrada `AUTORIZADOS` para que una excepción posterior del padre quede **declarada** en vez de romper el criterio o pasar inadvertida.
2. **C3 era incumplible tal como estaba escrito**, y es el punto de más sustancia. Prometía re-derivar toda cifra «sobre el snapshot versionado», y no todas salen de ahí: las 35 previas vienen de otras fuentes, el gancho sale de git al corte, y **185/20/8 salen de `alexweil/inquirylab`, cuyos SHA ni siquiera son objetos de este repo**. Reemplazado por una matriz `cifra → fuente autoritativa → corte → comando → límite de auditabilidad`, con las cifras externas **rotuladas como verificables solo contra ese segundo repo**. El mismo punto marcó que los comandos invocaban `cut.awk` y `normalize.awk`, archivos que no iban a existir en el árbol: de ahí la decisión de **versionarlos**.
3. **La «prueba negativa» de C11 no probaba nada.** Un push no crea commits de push, `origin/main..main` no tiene baseline versionado y no dice nada de topics ni homepage, y el repo no registra qué invocaciones de `gh` ocurrieron. Partido en C11 (sintaxis y completitud, verificables offline con `--help`) y C11b (la no-ejecución como **invariante operativa del pipeline**, asentada como registro y explícitamente **no** como prueba mecánica).
4. **La procedencia de las 35 se apartaba del diseño.** Yo había escrito 25 + 5 + 5 atribuyendo las cinco del feature 03 a una inferencia desde el snapshot; el diseño fija **30 en review logs versionados** —incluidas las r1–r5 del feature 03— **más 5** del plan. Corregido a la partición del diseño, con `03-loop-hardening.md` como fuente autoritativa y la inferencia degradada a contra-chequeo independiente. Incorporada también su segunda mitad: «cero aprobados en ronda 1» se demuestra sobre los **23** ciclos, así que se verificaron las r1 de los cinco previos a la instrumentación — las cinco `CHANGES_REQUESTED`.
5. **La frontera de «fuente única» estaba bien puesta, pero el criterio perdía el alcance.** «Ningún comando vive fuera de `docs/metrics.md`» era **literalmente falso**: los docs internos del 13 y del 14 los publican, y deben hacerlo. Acotado a la **superficie pública** (README, manual, CONTRIBUTING, `.github/`), con los docs del método fuera de la regla por definición, y el chequeo extendido al conjunto público completo en vez de solo al README.
6. **C6 validaba YAML, no el esquema de GitHub.** Un archivo puede parsear con Ruby y no ser un issue form válido. Agregada validación estructural contra la sintaxis oficial (`name`/`description`/`body` en la raíz, `type` y atributos por elemento, `contact_links` con `name`/`url`/`about`), y fijado ya el URL absoluto del `contact_links`.

**Un defecto propio, encontrado al verificar el punto 4 y que vale registrar**: mi primer intento de contar las rondas del feature 03 usó `grep -cE '^- \*\*Ronda [1-5]:'` y devolvió **4**, porque las entradas tituladas `Ronda 4 (paso A):` no matchean un patrón que exige el `:` pegado al dígito. Era exactamente el defecto que el punto 4 denuncia —evidencia más angosta que su afirmación— ocurriendo dentro de la verificación de ese punto. Re-derivado con el Review log entero: 00 → 4 rondas, 01 → 11, 02 → 10, 03 → 5 previas al log. De ahí sale también el límite que ahora se publica: el Review log de `01-installer.md` lista **diez** entradas y su ronda de cierre es la **11**, así que contar entradas daría 10 y sería un error silencioso.
