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

El baseline del trabajo del hijo es **`2985447`**, no `6ec4b48`. El primero se audita aparte y ya está verificado arriba.

### El alcance se audita **por commit**, no por diff agregado

La r2 encontró que mi mecanismo anterior seguía contradiciéndose justo en el caso que decía admitir: si el padre commiteaba al ledger dentro del rango, agregar su SHA a `AUTORIZADOS` hacía pasar el segundo chequeo, pero `git diff --name-only 2985447..HEAD` **seguía** incluyendo el ledger y hacía fallar la primera cláusula, que exige «sin el ledger». Dos chequeos que no podían ser verdaderos a la vez.

La causa es el **diff agregado**: aplana commits de dos autores con permisos distintos en una sola lista de paths, y ahí ya no hay forma de distinguir una violación de una excepción. El mecanismo pasa a ser uno solo, por commit:

**Cada commit de `2985447..HEAD` se atribuye a un autor, y cada autor tiene su lista cerrada de paths.**

| Autor | Cómo se identifica | Paths permitidos |
|---|---|---|
| **padre** | su SHA está en `AUTORIZADOS` | el ledger y/o `docs/STATUS.md` — nada más |
| **hijo** | cualquier otro commit del rango | la lista cerrada de §Alcance, que **no** incluye el ledger |

Un commit del hijo que toque el ledger **falla**. Un commit no declarado que toque el ledger **falla**. Un commit del padre declarado que toque, digamos, `README.md`, **falla**. No hay estado en que las dos cláusulas se contradigan, porque ya no hay dos cláusulas: hay una, aplicada commit por commit.

#### Por qué el instrumento importa más que la redacción — observación reusable

Vale sacarla de este feature, porque explica una clase de churn y no solo un criterio. **El diff agregado aplana commits de autores con permisos distintos**, y una vez aplanados no hay redacción que distinga una violación de una excepción autorizada: la información que hacía falta se perdió en el instrumento, antes de que el criterio la mirara. Dos redacciones sucesivas fallaron acá por eso, no por estar mal escritas.

La generalización: **cuando un criterio no cierra después de dos intentos de redacción, sospechar del instrumento antes que de las palabras**. Si la medición borra una distinción que el criterio necesita, ninguna formulación la recupera.

Tiene además valor retrospectivo, y el padre lo señaló: parte de las veinte rondas de la unidad `13` fueron exactamente esto — sus commits al ledger y los del hijo se mezclaban en un solo rango, así que cada corrección de uno movía la evidencia del otro, y el ciclo persiguió con redacciones un problema que era de instrumento.

**`AUTORIZADOS` — lista cerrada de commits del padre interiores al rango.** El contrato le deja al padre una sola excepción durante el ciclo: corregir una falsedad vigente. Cuando la usa, su SHA entra acá **en la misma ronda** en que commitea.

- `2fc4dd4` — registro del **corte por deadlock** del ciclo de bajada (r1–r5). Toca `docs/STATUS.md` y el ledger.
- `71c78be` — registro del **tercer desempate humano («a»)** que autoriza los dos bloqueantes y reanuda la unidad. Toca `docs/STATUS.md` y el ledger.
- `e5ee8f2` — **corrección de una falsedad vigente en el `## Cierre` del ledger**, que es la única excepción que el contrato le deja al padre durante un ciclo: el bloque describía el primer corte como si fuera el único —hubo **tres**— y decía que la corrida se reanuda en la unidad `13`. Toca **solo** el ledger. La detectó la r6 y el hijo **no la tocó**: se la pasó al padre, que commiteó y devolvió el SHA en el acto, que es el protocolo que la unidad `13` dejó probado.

`2985447` **no** es miembro: es la frontera del rango y `git rev-list 2985447..HEAD` no lo incluye. Se nombra acá solo para que no se lo busque en la lista.

**Auditoría por commit re-corrida al incorporarlos**, que es la razón por la que la lista existe. El resultado se publica como **procedimiento y desenlace**, no como inventario:

```sh
# por cada commit del rango, la lista que le corresponde según esté o no en AUTORIZADOS
for c in $(git rev-list 2985447..HEAD); do git show --name-only --format= "$c"; done
```

Desenlace: **pasa, fail-closed** — todo commit del padre toca solo `docs/STATUS.md` y/o el ledger, y ningún commit del hijo toca el ledger.

*(Este párrafo publicaba antes «los cinco commits del hijo» con su lista, y la r6 lo encontró **desincronizado apenas nació**: el commit que lo escribía ya era el sexto. Es la regla de contadores móviles violada dentro del párrafo que demuestra el mecanismo que la hace cumplir — la forma más pura del defecto en toda la unidad. `AUTORIZADOS` es la **única** lista necesaria, porque es cerrada por construcción: la escribe el padre cuando commitea. La del hijo se deriva.)*

**Y la observación que vale más que el caso** (pedida por el padre para el cierre, y escrita acá porque es donde ocurrió): **es la primera vez que el mecanismo se ejerce con commits reales del padre dentro del rango, y pasó. Con el diff agregado habría roto.** No es una anécdota: es la evidencia de la tesis que la r2 dejó escrita —que el instrumento importa más que la redacción— producida por el propio proceso que la tesis describe.

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

## Barrido de premisas sobre sistemas externos

La r5 volteó esta bajada por una afirmación mía sobre el esquema de GitHub que resultó falsa, y la r6 encontró **otra** en la misma tabla donde yo declaraba haber ido a la fuente. La clase es esa: **premisas sobre sistemas de terceros afirmadas de memoria**, en un doc cuyo contrato editorial exige que toda afirmación sea derivable. Se barren de una vez y el resultado queda acá, porque un barrido que no se publica no es auditable:

| Premisa | Sobre | Estado |
|---|---|---|
| forma de `options` en `dropdown` y `checkboxes`; `options[].required` como mecanismo de atestación; tipos válidos | GitHub | **verificada** contra el form schema oficial |
| causas de descarte y su texto de error (body solo-markdown, ids únicos, opciones únicas, `label` string, `value` requerido, `type` requerido, body no vacío) | GitHub | **verificada** contra «Common validation errors», con el texto exacto citado arriba |
| claves de `config.yml` y de `contact_links` (`name`/`url`/`about`), `url` absoluto | GitHub | **verificada** contra «Configuring issue templates» |
| ubicación `.github/ISSUE_TEMPLATE/*.yml` | GitHub | **verificada**, misma fuente |
| flags `--add-topic` y `--homepage` de `gh repo edit` | `gh` 2.94.0 | **verificada** contra `--help`, sin red |
| la línea final `── axel · fin: rc=N · … ──` | el instalador **de este repo** | **verificada** contra `scripts/install.sh` |
| `git rev-list A..B` excluye `A` | git | **verificada** empíricamente en la auditoría por commit |
| `ruby -ryaml` parsea YAML | esta máquina | **verificada acá**, y **no se afirma que sea universal**: si una corrida futura no lo tiene, el chequeo necesita otro parser. Es una precondición del entorno, no una propiedad de macOS |
| «GitHub levanta `CONTRIBUTING.md` desde la raíz» | GitHub | **no verificada ⇒ retirada**. El path se sostiene por convención y por el plan, no por ese comportamiento |

Lo que el barrido enseña, más allá de las filas: la última fila es la única que se **quitó** en vez de sourcear, y es la que mejor muestra el criterio — cuando una afirmación no es necesaria para la decisión, retirarla cuesta menos que sostenerla.

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
| ciclo de plan inicial | **5** | **segunda fuente, citada aparte**: no tiene doc en `implementation/`; su memoria son los **commits del ciclo** —`6afb57d..3ab6794`, cuatro de corrección más la ronda que aprobó— y el STATUS histórico. Anclada al **cierre `3ab6794`** |

**30 + 5 = 35**, y **88 + 35 = 123**. La inferencia desde el snapshot **se conserva, degradada a contra-chequeo independiente**: la primera fila del snapshot es la ronda 6, lo que confirma desde otra fuente que al feature 03 le faltan exactamente cinco. Dos fuentes que coinciden valen más que una; lo que no vale es presentar la débil como si fuera la fuerte.

**Límite de la derivación de las 25, publicado porque existe**: sale de la **ronda de cierre** que la tabla del plan registra para cada feature, no de contar entradas del review log. No son lo mismo — el Review log de `01-installer.md` lista diez entradas y su ronda de cierre es la **11**, porque una ronda no quedó listada. La ronda de cierre es la cifra correcta y por eso es la que se usa; contar entradas daría 10 y sería un error silencioso.

Regla de publicación, fijada por el diseño y no negociable: **dos cifras rotuladas** —«88 logged rounds since instrumentation» y 123 como total histórico con su segunda fuente— y **nunca una sola cifra sin decir a cuál corresponde**.

**«Cero aprobados en ronda 1» se demuestra sobre los 23 ciclos, no sobre los 18.** El log da 18/18 `CHANGES_REQUESTED` en la r1 de cada ciclo; los **cinco** ciclos anteriores a la instrumentación hay que verificarlos en sus propias fuentes, y están verificados: `00-bootstrap.md` r1 `CHANGES_REQUESTED`, `01-installer.md` r1 `CHANGES_REQUESTED`, `02-remote-install.md` r1 `CHANGES_REQUESTED`, `03-loop-hardening.md` r1 `CHANGES_REQUESTED`, y el ciclo de plan en `git show 2f7c814:docs/STATUS.md` («la ronda 1 pidió cambios»). **18 + 5 = 23**, que es exactamente la cifra que el README publica.

**`2f7c814` sirve para esto y solo para esto** (precisión de la r3): es el commit de la **ronda 1** del ciclo de plan, así que es evidencia del veredicto de esa primera ronda — **no** es el corte del ciclo, que cierra en `3ab6794`. Yo lo había usado para las dos cosas, y anclar un conteo de cinco rondas al commit de la primera es afirmar el total desde una foto que no lo contiene.

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
| Cómo dar feedback | `CONTRIBUTING.md` | **vidriera ⇒ inglés** | la raíz, que es la ubicación convencional y la que el plan nombró. *(La versión anterior justificaba el path afirmando que «GitHub lo levanta y lo ofrece al abrir un issue o un PR» — comportamiento que **no verifiqué contra ninguna fuente**, así que se retira: el path no depende de él.)* |
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

**Relación con la matriz de C3, para que no se lean como la misma lista**: la matriz es el universo **completo** de cifras que `docs/metrics.md` publica; esta lista de «sujetas» es el subconjunto que además **aparece en la superficie pública** y por lo tanto puede desincronizarse. Las que solo viven en el informe —medianas, peor caso, el hito sin rechazo— están en la matriz y no en esta lista, y cumplen la regla por construcción: no hay segundo lugar del que puedan divergir.

## Enfoque

### `docs/metrics.md` — el informe

Inglés. Estructura:

1. **Qué es y qué no** — la foto y su corte; que no incluye las rondas de los features 13 y 14, declarado y no escondido.
2. **Las tres unidades que no se mezclan** — ronda, hito, ciclo, con la advertencia de que los `APPROVED` son **hitos y no features**, y que enunciarlo mal es lo que destruye la credibilidad.
3. **Las cifras, como matriz** `cifra → fuente(s) autoritativa(s) → corte → comando → límite de auditabilidad`. La forma la impuso la r1 —**no todas las cifras se derivan del snapshot**, así que prometer «se re-derivan sobre el snapshot versionado» era incumplible—, y la r2 la corrigió dos veces más: mi resumen decía «tres familias» y enumeraba **cuatro**, y ninguna fila expresaba las cifras **compuestas**, que necesitan el snapshot **más** las fuentes previas a la instrumentación.

   Entonces la matriz no se resume por familia: es **exhaustiva por cifra**, que es lo que C3 puede recorrer fila por fila. El universo completo, con la fuente de cada una:

   | Cifra | Fuente(s) | Corte | ¿Auditable desde un clon de axel? |
   |---|---|---|---|
   | 88 rondas registradas | snapshot | `b0bdf4d` | sí |
   | 59 rechazos | snapshot | `b0bdf4d` | sí |
   | 29 hitos aprobados | snapshot | `b0bdf4d` | sí |
   | 18 ciclos observables · 18 cerrados | snapshot | `b0bdf4d` | sí |
   | mediana 4 por ciclo · 3 por hito | snapshot | `b0bdf4d` | sí |
   | peor caso 11 por ciclo · 5 por hito | snapshot | `b0bdf4d` | sí |
   | 1 hito sin rechazo (`2dbbdfc`) | snapshot | `b0bdf4d` | sí |
   | 25 rondas de los features 00–02 | tabla del plan al corte (ronda de cierre) | `b0bdf4d` | sí |
   | 5 rondas del feature 03 previas al log | `03-loop-hardening.md`; contra-chequeo: primera fila del snapshot | `b0bdf4d` | sí |
   | 5 rondas del ciclo de plan | commits del ciclo (`6afb57d..3ab6794`) + STATUS histórico | **`3ab6794`** — el **cierre** del ciclo | sí |
   | **35 previas** — *compuesta* | 25 + 5 + 5, tres fuentes de arriba | `b0bdf4d` | sí |
   | **123 histórico** — *compuesta* | 88 (snapshot) + 35 (compuesta de arriba) | `b0bdf4d` | sí |
   | **23 ciclos** — *compuesta* | 18 (snapshot) + 5 ciclos previos a la instrumentación | `b0bdf4d` | sí |
   | **cero aprobados en ronda 1** — *compuesta* | 18/18 del snapshot **+** la r1 de los 5 ciclos previos, verificada en sus propios docs | `b0bdf4d` | sí |
   | gancho: 212 commits · 3 días · 13 features | historia git de **este** repo | `b0bdf4d` | sí |
   | 185 commits, 20 archivos, 8 archivos | historia git de **`alexweil/inquirylab`** | `4908bfb` · `846308f` | **no** — ver abajo |

   Las cuatro filas rotuladas *compuesta* son las que la r2 echó en falta: **no tienen un único comando** que las produzca, y publicarlas como si lo tuvieran sería otra afirmación más ancha que su evidencia. Cada una declara sus sumandos y el comando de cada sumando; el total es la suma declarada, no una derivación oculta.

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

Los campos van **enumerados con su tipo y su requiredness**, no descritos en prosa: es lo que C15 recorre contra el archivo final, y una descripción no es verificable.

**`install-failed.yml`**

| # | `type` | Qué pide | `required` |
|---|---|---|---|
| F1 | `markdown` | una línea de contexto: qué hace útil este reporte | — |
| F2 | `input` | sistema operativo con su versión, y versión de `git` | **sí** |
| F3 | `textarea` | la **línea final** `── axel · fin: rc=N · … ──` | **sí** |
| F4 | `textarea` | la salida completa del instalador | **sí** |
| F5 | `textarea` | las líneas del `.gitignore` del destino que mencionan `build/`, o «ninguna» | **sí** |
| F6 | `dropdown` | el **modo anunciado** (`initial` · `adoption` · `update` · no llegó a anunciarse) | **sí** |
| F7 | `checkboxes` | atestación de que el árbol estaba limpio antes de correr | **sí** |

F5 y F6 no son ornamento: son los dos problemas conocidos que el manual documenta —la colisión `build/` y el modo mal anunciado— convertidos en campos, de modo que el reporte llegue con la respuesta ya adentro en vez de costar una ida y vuelta. F7 cubre la otra causa frecuente de rechazo.

**`friction-or-question.yml`**

| # | `type` | Qué pide | `required` |
|---|---|---|---|
| G1 | `markdown` | una línea que aclare que las preguntas entran acá | — |
| G2 | `textarea` | qué estabas haciendo | **sí** |
| G3 | `textarea` | qué esperabas que pasara | **sí** |
| G4 | `textarea` | qué pasó | **sí** |
| G5 | `checkboxes` | dónde buscaste primero (README · `docs/install.md` · `CONTRIBUTING.md` · las skills · en ningún lado) | **no** |

G5 es el campo que dice si el problema es el producto o el manual, y por eso existe.

**Semántica de `required` en `checkboxes` — la versión anterior de esta bajada era factualmente falsa, y la r5 la volteó.** Yo había escrito que `validations.required: true` exige que **todas** las opciones queden marcadas. No es así, y el error no era de redacción sino de premisa: afirmé el esquema de memoria en el único lugar donde el contrato editorial exige derivarlo. **Verificado contra la [documentación oficial del form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)**:

| | `dropdown` | `checkboxes` |
|---|---|---|
| forma de `attributes.options` | lista de **strings**, no vacía, todas distintas | lista de **objetos**, cada uno con `label` (requerido) y `required` (booleano, opcional, default `false`) |
| `validations.required` a nivel elemento | existe; la fuente lo describe como bloquear el envío hasta que el elemento esté **completo** | existe, con la misma descripción |
| mecanismo de **atestación** | no aplica | **`options[].required: true`** en esa opción: bloquea hasta que **esa** casilla esté marcada |

**Sobre la fila del medio, y es una corrección de la r6 que importa más de lo que parece**: yo había glosado ese `validations.required` como «bloquea si falta selección — no si falta marcar todas». La fuente **no dice eso**: dice «completo», y mi glosa era una interpretación más específica que el documento no establece. O sea que corregí una premisa sin fuente **introduciendo otra**, en la misma tabla donde declaraba haber ido a la fuente. Queda el texto documentado y nada más. No afecta el diseño: **ningún `checkboxes` de estos formularios usa `validations.required`** —F7 usa el `required` de su única opción y G5 no usa ninguno—, así que la semántica exacta en ese caso no decide nada acá.

Consecuencias directas sobre el diseño de los dos campos, ahora derivadas y no supuestas:

- **F7** es un `checkboxes` de **una sola opción**, con **`required: true` en la opción** —no en `validations`—, que es el mecanismo documentado de atestación.
- **G5** es un `checkboxes` de multiselección con **todas sus opciones opcionales**: ninguna lleva `required`, y el elemento **no** lleva `validations.required`.

*(Aprendizaje que vale más que el dato: el contrato editorial de este pipeline pide que toda afirmación sea derivable con su comando o su fuente. Yo lo apliqué a las cifras y no al esquema de un tercero, que es igual de verificable y estaba a una consulta de distancia.)*

**`config.yml`** — `blank_issues_enabled: true` y un `contact_links` con las tres claves que el esquema exige (`name`, `url`, `about`). El `url` tiene que ser **absoluto**, así que queda fijado acá: `https://github.com/alexweil/axel/blob/main/CONTRIBUTING.md`.

**Las invariantes del esquema que el chequeo valida — lista cerrada.** La r2 marcó que enumerar `name`/`description`/`body` y llamarlo «cumple el esquema» era otra promesa más ancha que su chequeo: GitHub documenta más causas de descarte que ésas. Se enumeran, entonces, y la afirmación se acota a lo enumerado:

| # | Invariante |
|---|---|
| E1 | Raíz con `name`, `description` y `body`, los tres presentes y no vacíos |
| E2 | Claves de raíz dentro de la **allowlist** (`name`, `description`, `title`, `body`, `labels`, `assignees`, `projects`, `type`); cualquier otra falla |
| E3 | `body` es una **lista no vacía** |
| E4 | Todo elemento tiene `type` ∈ `markdown` · `input` · `textarea` · `dropdown` · `checkboxes` — **los cinco que estos formularios usan**. *(La r5 me hizo agregar `upload` y la r6 me hizo sacarlo, con razón: al agregarlo tenía que sostener también su `attributes.label` y un caso positivo que lo ejercitara, y sin eso un validador que lo rechazara siempre pasaba igual todos los fixtures. La allowlist queda **acotada y declarada**: `upload` existe en el esquema y está deliberadamente fuera del alcance de este validador, que no es de propósito general sino el de estos tres archivos. Reusarlo sobre un formulario con `upload` exige extender E4 primero.)* |
| E5 | **Al menos un elemento no-`markdown`**: un formulario que solo muestra texto no recoge nada y GitHub lo descarta |
| E6 | `markdown` exige `attributes.value`; los **otros cuatro** tipos de E4 exigen `attributes.label` |
| E7 | **`dropdown`**: `attributes.options` es lista de **strings**, no vacía y con todas las opciones **distintas** |
| **E12** | **`checkboxes`**: `attributes.options` es lista de **objetos**, cada uno con `label` string no vacío y, si aparece, `required` **booleano**; `label` distintos entre sí. *(La r5 encontró que E7 aplanaba las dos formas en una y por lo tanto aceptaba `options: [foo, bar]` en un `checkboxes`, que GitHub rechaza.)* |
| E8 | Los `id` presentes son **únicos dentro del archivo** |
| E9 | Tipos de dato correctos: strings donde van strings, listas donde van listas, `validations.required` booleano **y `options[].required` booleano** en `checkboxes` |
| E10 | `validations` no se usa en elementos `markdown` |
| E11 | `config.yml`: `blank_issues_enabled` booleano, y cada `contact_links` con `name`, `about` y `url` **absoluto** (`http`/`https`) |

**Procedencia de cada invariante, con el texto de error que GitHub publica** (barrido de la r6; antes las tenía enumeradas pero no todas sourced):

| Invariante | Error documentado |
|---|---|
| E3 · lista vacía | «Body cannot be empty» |
| E4 · `type` ausente | «Body[i]: required key type is missing» |
| E5 | «Body must contain at least one non-markdown field» |
| E6 · `label` | «Body[i]: label must be a string» |
| E6 · `markdown` | «Body[i]: required attribute key `value` is missing» |
| E7 · repetida, E12 · `label` duplicado | «Body[i]: `options` must be unique» — la fuente lo enuncia para **dropdowns y checkboxes** |
| E8 | «Body must have unique ids» |

Fuentes: [form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema), [errores comunes de validación](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/common-validation-errors-when-creating-issue-forms) y [configuración de plantillas](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository), esta última para E11 y para la ubicación `.github/ISSUE_TEMPLATE/`.

**Límite declarado**: el validador de GitHub es la autoridad final y no se lo puede correr sin pushear, cosa que esta unidad tiene prohibida. El chequeo cubre las causas de descarte documentadas que están enumeradas arriba — **no el esquema en su totalidad**, y C6 se enuncia así y no de otra manera.

**Un fixture negativo por cada condición enumerada en la tabla de invariantes**, no «casos negativos» en general (r3, afinado en la r5 y otra vez en la r6). La formulación original se satisfacía con uno o dos fixtures mientras E7, E8 o E10 no rechazaban nunca: un validador con ramas que jamás se ejecutan puede aprobar cualquier cosa que caiga en ellas, y el criterio no se enteraría. **Cada fixture aísla su condición** —falla ésa y pasa las otras—, que es la misma disciplina de precondición por caso que el feature 03 usó para las tres invariantes de `wt_valid`:

| Invariante · condición | Fixture negativo | Esperado |
|---|---|---|
| E1 · falta una clave | formulario sin `description` | rechazo por E1 |
| E1 · presente pero vacía | formulario con `name: ""` | rechazo por E1 |
| E2 | clave de raíz fuera de la allowlist (`colour:`) | rechazo por E2 |
| E3 · no es lista | `body:` con un mapa | rechazo por E3 |
| E3 · lista vacía | `body: []` | rechazo por E3 |
| E4 · `type` ausente | elemento sin `type` | rechazo por E4 |
| E4 · `type` desconocido | elemento con `type: paragraph` | rechazo por E4 |
| E5 | `body` con un único elemento `markdown` | rechazo por E5 |
| E6 · `markdown` | `markdown` sin `attributes.value` | rechazo por E6 |
| E6 · no-`markdown` | `textarea` sin `attributes.label` | rechazo por E6 |
| E7 · ausente | `dropdown` sin `attributes.options` | rechazo por E7 |
| E7 · vacía | `dropdown` con `options: []` | rechazo por E7 |
| E7 · no son strings | `dropdown` cuyas `options` son objetos | rechazo por E7 |
| E7 · repetida | `dropdown` con dos opciones iguales | rechazo por E7 |
| E8 | dos elementos con el mismo `id` | rechazo por E8 |
| E9 · elemento | `validations.required: "yes"` — string donde va booleano | rechazo por E9 |
| E9 · opción | `checkboxes` con `options[].required: "true"` | rechazo por E9 |
| E10 | `markdown` con `validations` | rechazo por E10 |
| E11 · flag | `blank_issues_enabled: "true"` — string donde va booleano | rechazo por E11 |
| E11 · clave faltante | `contact_links` sin `about` | rechazo por E11 |
| E11 · url relativo | `contact_links` con `url: CONTRIBUTING.md` | rechazo por E11 |
| E12 · no son objetos | `checkboxes` con `options: [foo, bar]` | rechazo por E12 |
| E12 · sin `label` | `checkboxes` con una opción sin `label` | rechazo por E12 |
| E12 · `label` duplicado | `checkboxes` con dos opciones de igual `label` | rechazo por E12 |
| **positivo** | los **tres archivos reales** | aceptación, `rc=0` |

**La fila positiva importa tanto como las negativas**: un validador que rechaza todo también tiene todas sus ramas verdes. Y **la promesa se enuncia contra esta tabla y no al revés** (corrección de la r6): «un fixture por cada condición enumerada en la tabla de invariantes, más el caso positivo». Antes decía «por cada rama» mientras la matriz dejaba condiciones sin caso —`dropdown` con `options` vacías, entre otras—, que es la misma clase de promesa más ancha que su evidencia, ahora dentro del mecanismo que la detecta.

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
| C3 | `docs/metrics.md` publica sus cifras como matriz **exhaustiva por cifra** —`cifra → fuente(s) → corte → comando → límite de auditabilidad`—, cuyo universo es el de §Enfoque·3 y que **no deja ninguna cifra publicada sin fila**. Toda cifra auditable desde un clon de axel **se re-deriva y coincide**; las **compuestas** declaran sus sumandos y el comando de cada uno, sin presentar el total como derivación única; las de la instalación externa quedan **rotuladas como verificables solo contra `alexweil/inquirylab`**, nunca prometidas como re-derivables desde acá | re-corrida fila por fila, más la **prueba de cobertura**: cada cifra publicada en la superficie pública y en el propio informe tiene su fila; una cifra sin fila falla el criterio |
| C4 | Los `awk` publicados en inglés producen salida **idéntica** a los del 13 sobre el mismo snapshot | diff de las dos salidas; debe ser vacío |
| C5 | **Fuente única, acotada a la superficie pública**: en `README.md`, `docs/install.md`, `CONTRIBUTING.md` y `.github/`, toda cifra sujeta (definición de §«Fuente única») aparece en `docs/metrics.md` con el mismo valor, y ningún comando de derivación de una cifra sujeta vive fuera de `docs/metrics.md`. Los docs del método quedan fuera de la regla, por definición y no por excepción | inventario de cifras del **conjunto público completo** —los cuatro, no solo el README—, una por una |
| C6 | Los tres YAML de `.github/ISSUE_TEMPLATE/` **parsean** *y* **cumplen las invariantes E1–E12** de §Enfoque —con `dropdown` y `checkboxes` validados **por separado**, que es lo que la r5 volteó—, que son las causas de descarte documentadas por GitHub que este chequeo cubre. **No se afirma «cumplen el esquema» a secas**: el validador de GitHub es la autoridad final, no se lo puede correr sin pushear —prohibido en esta unidad— y el límite se publica junto al criterio. Parsear no es validar: un archivo puede ser YAML legal y no ser un issue form | `ruby -ryaml` (stock de macOS) para el parseo, **más** un validador de E1–E12 corrido sobre los tres archivos, con **la matriz completa `EN → fixture negativo` de §Enfoque: uno por cada rama, cada uno aislando la suya**, más el camino positivo sobre los tres archivos reales. «Casos negativos» a secas no alcanzaba: se satisface con dos fixtures mientras el resto de las ramas nunca se ejecuta, y una rama que nunca corrió aprueba lo que sea que caiga en ella. Referencias: [sintaxis de issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms), [form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema) y [errores comunes de validación](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/common-validation-errors-when-creating-issue-forms) |
| C7 | **Las dos referencias del 13 son links que resuelven**, y no queda ninguna marca de «pendiente para el 14» en el README | inspección de los dos puntos + chequeo de destinos |
| C8 | **Cero link roto** en el conjunto completo — `README.md`, `CONTRIBUTING.md`, `docs/metrics.md`, `docs/install.md` | chequeo mecánico de todo destino relativo y de toda ancla interna contra los encabezados reales |
| C9 | **Cero afirmación no verificable**: toda oración de `CONTRIBUTING.md` y `docs/metrics.md` cae en una de las tres clases del contrato editorial (hecho derivable con su comando · limitación declarada · opinión marcada) | pasada por oración, registrada en el Review log |
| C10 | `CONTRIBUTING.md` declara **qué está fuera de alcance hoy** incluyendo el aviso MIT como **incumplimiento pendiente**, no como cumplimiento parcial | lectura literal |
| C11 | Los **tres comandos de GitHub** están escritos pegables sin editar, con herramienta, sintaxis y precondiciones declaradas y cero huecos. Sintaxis y completitud se verifican **offline**: cada flag existe en `gh repo edit --help`, cada valor está presente, ningún hueco | inspección contra la salida de `--help`, sin red |
| **C11b** | **No-ejecución**: ninguno de los tres se corrió contra el remoto | **Invariante operativa del pipeline, no evidencia derivable del commit** — y rotularla como prueba mecánica era una afirmación más ancha que su evidencia (hallazgo de la r1): un push no deja «commits de push», `origin/main..main` no tiene baseline versionado y no dice nada de topics ni homepage, y el repo no registra qué invocaciones de `gh` ocurrieron. Lo que sí se puede asentar, y es lo que se asienta: el registro explícito de que la unidad no las ejecutó, con las únicas invocaciones de `gh` declaradas (`--help`), verificable por el padre contra el ledger y por el humano contra el estado del repo remoto cuando vaya a correrlos |
| C12 | **Alcance, auditado por commit y no por diff agregado** (§«El alcance se audita por commit»): para cada commit de `2985447..HEAD`, si su SHA está en `AUTORIZADOS` toca solo el ledger y/o `docs/STATUS.md`; si no está, toca solo la lista cerrada de §Alcance, que **no** incluye el ledger. Cero cambios en método, skills, instalador, scripts, tests o remoto | recorrido de `git rev-list 2985447..HEAD`, y por cada SHA `git show --name-only --format= <sha>` contra la lista que le corresponde según esté o no en `AUTORIZADOS`. Un solo commit fuera de su lista falla el criterio. **El diff agregado no se usa**: aplanar dos autores con permisos distintos es lo que volvía el criterio autocontradictorio |
| C13 | **La inconsistencia del corte quedó resuelta por escrito**, con la razón contractual y no por preferencia | §«La inconsistencia entre docs», presente y citada desde el informe si corresponde |
| C14 | No-regresión: `tests/lint.sh`, `tests/loop.sh` y `tests/install.sh` limpios | corrida de las tres suites |
| **C15** | **Completitud contra los artefactos.** Los criterios anteriores verifican que lo publicado sea correcto, y **ninguno verifica que esté entregado lo diseñado** — hueco que la r4 expuso con un contraejemplo que pasaba C3, C6 y C8–C10: un informe con solo la matriz, un `CONTRIBUTING.md` con solo el aviso MIT y dos formularios válidos con un textarea genérico. Existen **y entregan lo diseñado**: (a) los **ocho** componentes del informe de §Enfoque·`docs/metrics.md`; (b) los **cuatro** bloques de `CONTRIBUTING.md`; (c) los campos **F1–F7** y **G1–G5**, cada uno contrastado en su **tupla completa** —`type` **+** el significado que la fila declara **+** sus opciones cuando las tiene **+** su requiredness **+** su ubicación en el archivo—, incluido que F7 sea `checkboxes` de una opción con `required` **en la opción** y que G5 no tenga ninguna requerida; (d) `config.yml` con el contenido ya fijado, URL absoluto incluido; (e) **el idioma**: `docs/metrics.md`, `CONTRIBUTING.md` y `.github/` en **inglés**, que es lo que el diseño manda para toda la vidriera | recorrido de las listas cerradas **localizando cada elemento en el archivo final** y comparando la **tupla entera**, no solo su presencia — la r5 mostró que cardinalidad y requiredness correctas admiten igual dos formularios con textareas genéricos, o todos los artefactos escritos en español. Se registra el locator de cada fila. *Que la lista esté escrita en esta bajada no verifica que esté implementada*: es el defecto que el feature 13 tuvo que corregir con sus C6–C9, y se hereda el remedio en vez de redescubrirlo |

## Riesgos

1. **La regla de fuente única es interpretable, y una regla interpretable churnea.** Es el riesgo más probable de esta unidad. Mitigación: la línea está **fijada por escrito antes de implementar** (§«Fuente única»), con la clase incluida, la clase excluida y el chequeo mecánico que la aplica. Si el reviewer no acepta la línea, se discute la línea una vez — no cifra por cifra.
2. **Contadores móviles reapareciendo en prosa.** Es la causa de las dos rachas de la unidad 13. Mitigación: la regla adoptada arriba, aplicada también a este doc; donde hace falta un número que se mueve, va el comando.
3. **YAML que GitHub descarta en silencio.** Un formulario mal formado no avisa: simplemente no aparece. Mitigación parcial y declarada como parcial: C6 valida con un parser real **y** con las invariantes **E1–E12**, que son las causas de descarte documentadas, con un fixture negativo **por rama**; el validador de GitHub sigue siendo la autoridad final y no se lo puede correr sin pushear. El riesgo se reduce, no se elimina, y el criterio lo dice. *(Las menciones de «E1–E11» dentro del Review log se conservan: describen el estado de su ronda, y E12 entró recién en la r5.)*
4. **Tentación de correr los comandos de GitHub** —están escritos, verificados y a un `Enter` de distancia—. Mitigación: el corte está declarado como consecuencia, y C11b **no finge** que la no-ejecución sea demostrable desde el commit: es una invariante operativa que se sostiene por el contrato del pipeline y se asienta como registro, no como prueba. Prometer una prueba mecánica que no existe habría sido peor que no prometer nada — daba una garantía falsa exactamente donde importa.
5. **El corte envejece mientras se trabaja.** Las rondas de esta misma unidad entran al `rounds-log`. Mitigación: es exactamente lo que el corte neutraliza; la consecuencia (el snapshot no incluye las rondas de los features 13 y 14) se **publica**.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Sigue siendo una línea a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.
7. **Ampliar la edición del README.** El contrato dice «activar dos referencias», no «revisar la vidriera». Mitigación: C7 acota, y ante una tercera cosa que parezca necesaria se registra y se pregunta en vez de decidir solo.
8. **«Todo lo publicado es correcto» no es «está entregado lo diseñado».** Riesgo que la r4 encontró y que no estaba en esta lista: catorce criterios de correctitud dejaban pasar artefactos semánticamente incompletos, porque ninguno miraba la ausencia. Es **el mismo riesgo 7 de la unidad `13`**, que ahí costó agregar cuatro criterios en su r1. Mitigación: C15, contra cuatro listas cerradas y con locator en el artefacto final — no contra el criterio de quien revisa, y no contra la lista escrita en esta bajada.

## Review log

### r6 (base `6ec4b48`, HEAD `52850e3`) — CHANGES_REQUESTED · **2 bloqueantes, cero preferencias**, más un pendiente del ledger que es del padre

**C15 quedó cerrado correctamente**, y Codex no dejó preferencias opcionales. Los dos bloqueantes son de la misma clase que este ciclo viene persiguiendo, y los dos ocurrieron **dentro del mecanismo que existe para detectarlos** — que es lo que los vuelve interesantes y no solo molestos.

1. **Corregí una premisa sin fuente introduciendo otra.** Al traer el esquema oficial glosé el `validations.required` de `checkboxes` como «bloquea si falta selección — no si falta marcar todas». La fuente **no dice eso**: dice que bloquea hasta que el elemento esté **completo**, y mi versión era una interpretación más específica que el documento no establece. Retirada; queda el texto documentado. No afecta el diseño, porque **ningún `checkboxes` de estos formularios usa `validations.required`**. De arrastre: E4 había sumado `upload` sin que E6 lo contemplara («los otros cuatro» cuando ya eran cinco) y **sin caso positivo**, así que un validador que rechazara `upload` siempre pasaba igual todos los fixtures; y la promesa «un fixture por rama» no tenía caso para `dropdown` con `options` vacías, entre otros. Resuelto **retirando `upload`** —la allowlist queda acotada y declarada a los cinco tipos que estos formularios usan— y reescribiendo la matriz de fixtures para que enumere **cada condición**, con la promesa enunciada contra la tabla y no al revés.
2. **La auditoría publicada de C12 nació desincronizada.** El párrafo decía «los cinco commits del hijo» con su lista, y el commit que lo escribía ya era el sexto. Es la **regla de contadores móviles violada dentro del párrafo que demuestra el mecanismo que la hace cumplir** — la forma más pura del defecto en toda la unidad, y la escribí yo tres rondas después de adoptar la regla. Reemplazado por procedimiento + desenlace fail-closed, con `AUTORIZADOS` como única lista, que es cerrada por construcción porque la escribe el padre al commitear.
3. **Pendiente del ledger, que es territorio del padre y no lo toqué**: el `## Cierre` decía que la corrida se reanuda en la unidad `13`, cuando el último evento y STATUS dicen `14`. Se lo pasé en vez de corregirlo, frenando el lanzamiento de la r7 —una ronda con un defecto conocido adentro tiene el desenlace cantado—, y el padre commiteó `e5ee8f2` y devolvió el SHA en el acto. **El defecto era peor de lo que yo había señalado**: el bloque no solo nombraba la unidad equivocada, sino que **describía el primer corte como si fuera el único cuando hubo tres**. Quedó con los tres registrados y el texto anterior tachado y conservado. `e5ee8f2` entra a `AUTORIZADOS` y la auditoría por commit se re-corrió: pasa.

   *(Segunda vez que el protocolo padre-hijo sobre el ledger se ejerce en esta unidad, y la primera en que lo dispara un hallazgo de review. Vale por lo mismo que C12: la frontera de territorios no es ceremonia — el hijo detectó una falsedad que no podía arreglar, y la vía para arreglarla existía.)*

**Barrido de premisas externas, hecho de una vez** (§«Barrido de premisas sobre sistemas externos»): a pedido del padre, en vez de esperar a que aparezcan de a una. Nueve premisas inventariadas — ocho verificadas contra su fuente, y una **retirada** por no ser verificable ni necesaria. De ahí salieron además los textos de error exactos que GitHub publica para siete de las invariantes, que ahora el validador puede usar como expectativa.

### r5 (base `6ec4b48`, HEAD `fdd2f41`) — CHANGES_REQUESTED · **2 bloqueantes, cero preferencias** · **corte por tope** → tercer desempate humano «a)»

Codex contestó las dos distinciones que le pedí: **«no encontré mejoras meramente opcionales»**, y de los dos dijo explícitamente que **no** son bookkeeping diferible por la vía de «no revisados» del RECAP. La racha llegó a 5, la corrida se detuvo, y el humano desempató con **«a)»**: se autorizan los dos y la unidad se reanuda con la racha reseteada. *(Queda registrado, porque es parte de la historia de la decisión: el padre había recomendado cerrar el pipeline **sin** esta unidad, y el humano eligió completarla.)*

1. **Una premisa factual falsa sobre el esquema de GitHub, escrita por mí en la r4.** Yo había afirmado que `validations.required: true` en un `checkboxes` exige marcar **todas** las opciones. Es falso: cada opción es un **objeto** con su propio `required`, y **ése** es el mecanismo de atestación; el `validations.required` del elemento bloquea si falta selección. De arrastre, E7 aplanaba `dropdown` y `checkboxes` en una sola invariante y por lo tanto aceptaba `options: [foo, bar]` en un `checkboxes` — o sea que C6 podía aprobar YAML que GitHub rechaza. **Corregido verificando contra la [documentación oficial](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)**, no de memoria: E7 queda para `dropdown` (strings distintos), entra **E12** para `checkboxes` (objetos con `label`, `required` opcional booleano), E9 cubre el tipo de `options[].required`, E4 suma `upload` a la allowlist de tipos, y F7/G5 quedan definidos por el mecanismo correcto.

   **Es un defecto de clase nueva en este ciclo**, y por eso invalidó mi predicción de que una ronda más alcanzaba: los cuatro puntos anteriores eran criterios que prometían de más, éste es una **afirmación sobre el mundo que resultó falsa**. La lección tiene nombre propio: el contrato editorial de este pipeline pide que toda afirmación sea derivable con su comando o su fuente, y yo lo apliqué a las cifras y no al esquema de un tercero, que era igual de verificable y estaba a una consulta de distancia.

2. **C15 seguía admitiendo implementaciones contrarias al diseño.** Exigía existencia, contenido y requiredness, pero no que cada fila coincidiera en `type`, significado y opciones — y **no miraba el idioma**. Dos formularios con la cardinalidad y la requiredness correctas pero textareas genéricos, o **todos los artefactos escritos en español**, aprobaban igual. C15 pasa a contrastar la **tupla completa** por fila (`type` + significado + opciones + requiredness + ubicación) y a verificar el **inglés** de `docs/metrics.md`, `CONTRIBUTING.md` y `.github/`, que es lo que el diseño manda para toda la vidriera.

**Los dos SHA del padre entran a `AUTORIZADOS`** —`2fc4dd4` (el corte) y `71c78be` (el desempate)— y la auditoría por commit se re-corrió: pasan. Vale anotarlo porque es la primera vez que el mecanismo se ejerce de verdad, y con el diff agregado que la r2 descartó estos dos commits habrían roto el criterio.

### r4 (base `6ec4b48`, HEAD `e0b1136`) — CHANGES_REQUESTED · **1 punto**, aceptado sin argumentar

Las dos correcciones de la r3 quedaron **cerradas y verificadas**: `3ab6794` prueba el ciclo completo y `2f7c814` quedó acotado a la r1; E1–E11 tienen fixture negativo aislado y camino positivo. C12 sigue pasando sobre los cuatro commits del hijo. Sin contadores móviles nuevos.

1. **Los catorce criterios permitían artefactos semánticamente incompletos** — el único hallazgo, y bloqueante. Todos verificaban que **lo publicado fuera correcto**; ninguno verificaba que **estuviera entregado lo diseñado**, o sea que ninguno miraba la **ausencia**. El contraejemplo de Codex es concreto y pasa: un informe compuesto solo por la matriz, un `CONTRIBUTING.md` con únicamente el aviso MIT y dos formularios válidos con un textarea genérico satisfacen C3, C6, C8–C10 y el resto, incumpliendo el plan entero. Cerrado con **C15**, que recorre cuatro listas cerradas —los ocho componentes del informe, los cuatro bloques de `CONTRIBUTING.md`, los campos F1–F7 y G1–G5 con su requiredness exacta, y `config.yml`— **localizando cada elemento en el archivo final**. Aproveché para convertir la descripción en prosa de los formularios en dos tablas con tipo y requiredness por campo, porque una descripción no es verificable; y quedó fijada de paso la semántica de `required` en `checkboxes` (exige **todas** las opciones marcadas), que decide que F7 sea de una sola opción y que G5 no pueda ser requerido — confundirlo produce un formulario que nadie puede enviar.

   **Es el riesgo 7 de la unidad `13`**, literalmente («no perder nada» no es «entregar lo diseñado»), que allá costó cuatro criterios nuevos en su r1. Se hereda el remedio en vez de redescubrirlo, y se agrega como riesgo 8 de esta bajada para que quede en la lista y no solo en el criterio.

**Señal de churn, condición aplicada por segunda vez: no se cumple, y además se revirtió.** El punto **no reabre nada** —las dos correcciones de la r3 están cerradas— y **no cae sobre una corrección previa**: Codex declara explícitamente que «pertenece a los criterios originales y debí señalarlo antes; no fue introducido por la corrección de la r3». O sea que la señal que existía en la r2 y la r3 desapareció en esta. Con la profundidad bajando **6 → 3 → 2 → 1** y el último hallazgo apuntando al plan original en vez de a las correcciones, el régimen es de convergencia.

### r3 (base `6ec4b48`, HEAD `9f56b39`) — CHANGES_REQUESTED · 2 puntos, los 2 aceptados sin argumentar ninguno

**C12 quedó cerrado, y verificado sobre el artefacto**: Codex recorrió los tres commits de `2985447..HEAD` y confirmó que todos sus paths pertenecen a la lista del hijo, sin ledger ni commit interior del padre. La matriz cubre el universo previsto y no aparecieron contadores móviles nuevos.

1. **Corte incorrecto para las cinco rondas del ciclo de plan.** Yo había anclado esa fila en `2f7c814`, que es el commit de la **ronda 1** — después existen r2–r4 y el cierre `3ab6794`. Anclar un conteo de cinco rondas al commit de la primera es afirmar un total desde una foto que no lo contiene. Corregido al cierre **`3ab6794`**, con la derivación ya fijada por el 13 (`6afb57d..3ab6794`); `2f7c814` **se conserva, acotado** a lo único que prueba: el veredicto de la primera ronda, que es lo que la cifra compuesta de «cero aprobados en ronda 1» necesita.
2. **«Con casos negativos» no cubría cada rama.** Se satisfacía con uno o dos fixtures mientras E7, E8 o E10 no rechazaban nunca, y una rama que jamás se ejecuta aprueba lo que sea que caiga en ella — el mismo validador podía volver a aprobar por no haber corrido la rama defectuosa. Reemplazado por una **matriz `E1…E11 → fixture negativo`**, uno por invariante y **cada uno aislando la suya**, más el camino positivo sobre los tres archivos reales: un validador que rechaza todo también tiene todas sus ramas verdes. Es la misma disciplina de precondición por caso que el feature 03 usó para `wt_valid`.

**Sobre la señal de churn, aplicando la condición que yo mismo puse antes de esta ronda.** La condición era: si los puntos vuelven a caer sobre las correcciones anteriores **sin cerrar nada nuevo**, se nombra como lazo. **No se cumple, y por lo tanto no es un lazo.** Los dos puntos sí caen sobre correcciones previas —Codex lo dice explícitamente y coincidimos en que la señal existe—, pero los dos son **contraejemplos concretos y locales**: un SHA de corte objetivamente equivocado y una cobertura de ramas que no existía. Ninguno reabre algo ya cerrado y ninguno es bookkeeping vacío. La profundidad además baja monótonamente —6 → 3 → 2— y esta ronda **cerró** un criterio (C12) en vez de moverlo. Eso es convergencia, no el lazo de la unidad `13`.

### r2 (base `6ec4b48`, HEAD `f266844`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados sin argumentar ninguno

**La pregunta de alcance quedó resuelta a favor**: versionar `cut.awk` y `normalize.awk` es «detalle legítimo y necesario para que los comandos sean ejecutables, **no scope creep**». Codex dio además por bien cerrados la partición 30+5, las cinco r1 previas a la instrumentación, la frontera pública de fuente única y el par C11/C11b. Sin contadores móviles nuevos.

Los tres puntos son **la misma familia que los cuatro de la r1**, una vuelta más adentro: un criterio que promete más de lo que su chequeo entrega. Que reaparezca en las correcciones de la ronda anterior es la señal a vigilar, y está anotada abajo.

1. **C12 seguía contradiciéndose exactamente en el caso que decía admitir.** Si el padre commiteaba al ledger dentro del rango, declarar su SHA en `AUTORIZADOS` hacía pasar el segundo chequeo mientras `git diff --name-only 2985447..HEAD` **seguía** incluyendo el ledger y hacía fallar la primera cláusula («sin el ledger»). Dos cláusulas que no podían ser verdaderas a la vez. **La causa era el diff agregado**, que aplana commits de dos autores con permisos distintos hasta volver indistinguible una violación de una excepción. Reemplazado por auditoría **por commit**: cada commit se atribuye a un autor y cada autor tiene su lista de paths. Una sola cláusula, sin estado contradictorio posible.
2. **La matriz de C3 no cubría su propio universo.** Dos defectos: la prosa decía «tres familias» y la tabla enumeraba **cuatro** —cardinalidad fija mal escrita, no un contador móvil—, y ninguna fila expresaba las cifras **compuestas** (`123`, `35`, `23 ciclos`, «cero aprobados en ronda 1»), que necesitan el snapshot **más** las fuentes previas a la instrumentación y por lo tanto **no tienen un comando único**. Reemplazada por una matriz **exhaustiva por cifra** —una fila por cifra, cada una con sus fuentes y su corte—, con las compuestas rotuladas como tales, declarando sus sumandos en vez de fingir una derivación única. *(No publico acá cuántas filas tiene: es una cardinalidad que se mueve si el universo cambia, y acabo de corregir un defecto de esa forma exacta.)* C3 suma ahora una **prueba de cobertura**: una cifra publicada sin fila falla el criterio.
3. **C6 seguía prometiendo «el esquema» con una validación parcial.** Los campos que yo enumeraba no cubren las demás causas de descarte documentadas: cuerpo vacío o solo-markdown, claves o tipos inválidos, `id` duplicados, tipos de dato incorrectos, opciones repetidas. Enumeradas como lista cerrada **E1–E11**, y la afirmación acotada a lo enumerado, con el límite publicado al lado: el validador de GitHub es la autoridad final y no se lo puede correr sin pushear, cosa prohibida en esta unidad. Agregado además que el validador propio debe traer **casos negativos** — uno que nunca rechazó nada no está verificado.

### r1 (base `6ec4b48`, HEAD `225e5f3`) — CHANGES_REQUESTED · 6 puntos, los 6 aceptados sin argumentar ninguno

Codex dio por buenas las decisiones de fondo —`b0bdf4d` gana por contrato y no por conveniencia, dos formularios más `config.yml`, la homepage al manual sin fingir que existe un sitio— y verificó que **no hay ningún contador móvil sin anclar en la prosa de esta bajada**, que era el riesgo 2. Los seis puntos son de rigor de los criterios, no del plan de ataque. **Cuatro de los seis son la misma familia: un criterio que promete más de lo que su evidencia puede sostener.**

1. **C12 fallaba contra su propio rango.** Exigía cero cambios en el ledger usando `6ec4b48` como base, pero ese rango **incluye** el commit de arranque del padre `2985447`, que toca el ledger — o sea que el criterio nacía incumplible. Separadas las dos superficies: `6ec4b48..2985447` es el arranque del padre (toca `docs/STATUS.md` y el ledger, verificado), y `2985447..HEAD` es el trabajo del hijo. Agregada además la lista cerrada `AUTORIZADOS` para que una excepción posterior del padre quede **declarada** en vez de romper el criterio o pasar inadvertida.
2. **C3 era incumplible tal como estaba escrito**, y es el punto de más sustancia. Prometía re-derivar toda cifra «sobre el snapshot versionado», y no todas salen de ahí: las 35 previas vienen de otras fuentes, el gancho sale de git al corte, y **185/20/8 salen de `alexweil/inquirylab`, cuyos SHA ni siquiera son objetos de este repo**. Reemplazado por una matriz `cifra → fuente autoritativa → corte → comando → límite de auditabilidad`, con las cifras externas **rotuladas como verificables solo contra ese segundo repo**. El mismo punto marcó que los comandos invocaban `cut.awk` y `normalize.awk`, archivos que no iban a existir en el árbol: de ahí la decisión de **versionarlos**.
3. **La «prueba negativa» de C11 no probaba nada.** Un push no crea commits de push, `origin/main..main` no tiene baseline versionado y no dice nada de topics ni homepage, y el repo no registra qué invocaciones de `gh` ocurrieron. Partido en C11 (sintaxis y completitud, verificables offline con `--help`) y C11b (la no-ejecución como **invariante operativa del pipeline**, asentada como registro y explícitamente **no** como prueba mecánica).
4. **La procedencia de las 35 se apartaba del diseño.** Yo había escrito 25 + 5 + 5 atribuyendo las cinco del feature 03 a una inferencia desde el snapshot; el diseño fija **30 en review logs versionados** —incluidas las r1–r5 del feature 03— **más 5** del plan. Corregido a la partición del diseño, con `03-loop-hardening.md` como fuente autoritativa y la inferencia degradada a contra-chequeo independiente. Incorporada también su segunda mitad: «cero aprobados en ronda 1» se demuestra sobre los **23** ciclos, así que se verificaron las r1 de los cinco previos a la instrumentación — las cinco `CHANGES_REQUESTED`.
5. **La frontera de «fuente única» estaba bien puesta, pero el criterio perdía el alcance.** «Ningún comando vive fuera de `docs/metrics.md`» era **literalmente falso**: los docs internos del 13 y del 14 los publican, y deben hacerlo. Acotado a la **superficie pública** (README, manual, CONTRIBUTING, `.github/`), con los docs del método fuera de la regla por definición, y el chequeo extendido al conjunto público completo en vez de solo al README.
6. **C6 validaba YAML, no el esquema de GitHub.** Un archivo puede parsear con Ruby y no ser un issue form válido. Agregada validación estructural contra la sintaxis oficial (`name`/`description`/`body` en la raíz, `type` y atributos por elemento, `contact_links` con `name`/`url`/`about`), y fijado ya el URL absoluto del `contact_links`.

**Un defecto propio, encontrado al verificar el punto 4 y que vale registrar**: mi primer intento de contar las rondas del feature 03 usó `grep -cE '^- \*\*Ronda [1-5]:'` y devolvió **4**, porque las entradas tituladas `Ronda 4 (paso A):` no matchean un patrón que exige el `:` pegado al dígito. Era exactamente el defecto que el punto 4 denuncia —evidencia más angosta que su afirmación— ocurriendo dentro de la verificación de ese punto. Re-derivado con el Review log entero: 00 → 4 rondas, 01 → 11, 02 → 10, 03 → 5 previas al log. De ahí sale también el límite que ahora se publica: el Review log de `01-installer.md` lista **diez** entradas y su ronda de cierre es la **11**, así que contar entradas daría 10 y sería un error silencioso.
