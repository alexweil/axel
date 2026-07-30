# Feature 14 — Onboarding y feedback: CONTRIBUTING + `.github/` + métricas versionadas

> Bajada fina de la §14 de [../IMPLEMENTATION.md](../IMPLEMENTATION.md). Diseño: [../design/public-surface.md](../design/public-surface.md). Contrato con el feature 13: [13-public-showcase.md](13-public-showcase.md).

## Procedencia y autorización

Unidad `14` (tipo `feature`) del **tercer** pipeline `/build` del 2026-07-29 — ledger [pipeline-2026-07-29-3.md](pipeline-2026-07-29-3.md). No hubo gate individual: la autorización es la **del gate de pipeline**, recibida el 2026-07-29 con el literal «dale, autorizado — el push y los topics los hago yo». Pedido de `/build` que lo originó (literal breve; el texto completo vive en el bloque Gate del ledger): «Dejar el repo público de axel presentable para compartirlo: README en inglés escrito para quien lo descubre, licencia MIT, y los docs de onboarding y feedback que faltan».

**Ajuste de alcance (b) del gate, que manda sobre esta unidad**: el pipeline **no toca GitHub ni pushea** — ni `git push`, ni topics, ni homepage, ni ninguna otra acción sobre el remoto o sus settings. Esta unidad **deja los tres comandos exactos listos y no ejecuta ninguno**; correrlos desde acá es divergencia ⇒ corte.

SHA de arranque de la unidad: `6ec4b48`.

## Alcance

Entra: `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/`, el informe de métricas, el snapshot del `rounds-log`, la **activación de las dos referencias pendientes** del `README.md`, este doc, `docs/IMPLEMENTATION.md` y `docs/STATUS.md`.

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
awk -v cut=b0bdf4d -f cut.awk .claude/state/rounds-log > docs/metrics/rounds-log-b0bdf4d.tsv
```

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

No se derivan con el mismo comando que las 88: no tienen esquema tabular. El 13 dejó **tres derivaciones**, cada una produciendo directamente el valor publicado, y esta unidad las reusa y re-verifica:

| Tramo | Valor | Fuente |
|---|---|---|
| features 00–02 (ciclos completos anteriores al log) | 25 | los review logs versionados, vía la ronda de cierre que registra la tabla del plan al corte |
| feature 03, el tramo previo al arranque del log | 5 | el propio snapshot delata el faltante: su primera fila ya es la ronda 6 |
| ciclo de plan inicial | 5 | **segunda fuente, citada aparte**: no tiene doc en `implementation/`; su memoria son los commits y el STATUS histórico |

**25 + 5 + 5 = 35**, y **88 + 35 = 123**. La regla de publicación es la que fijó el diseño y no se negocia: **dos cifras rotuladas** —«88 logged rounds since instrumentation» y 123 como total histórico con su segunda fuente— y **nunca una sola cifra sin decir a cuál corresponde**. La tercera fila se cita separada de las otras dos porque es de otra fuente, no por prolijidad.

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
| Cómo dar feedback | `CONTRIBUTING.md` | **vidriera ⇒ inglés** | raíz, que es donde GitHub lo levanta y lo ofrece al abrir un issue o un PR |
| Plantillas | `.github/ISSUE_TEMPLATE/{install-failed,friction-or-question,config}.yml` | **vidriera ⇒ inglés** | path fijado por GitHub |

Que `docs/metrics.md` y `docs/metrics/` convivan es deliberado: el doc y sus datos, visibles como dos cosas distintas en el árbol, que es exactamente la partición de planos del diseño hecha topología.

## Fuente única: qué significa exactamente, y por qué la línea va donde va

El diseño dice «toda cifra de la vidriera vive en el doc de métricas y el README la cita», con el fundamento explícito de que «dos lugares con el mismo número son dos lugares para envejecer distinto». Aplicado sin precisar, eso obligaría a mudar al doc de métricas los códigos de salida del instalador y la cantidad de principios, que es absurdo. Precisar la línea **acá y por escrito** es parte del trabajo, porque una regla que cada ronda interpreta distinto es una regla que churnea.

**La regla, tal como esta unidad la aplica**: una cifra de la vidriera está sujeta a fuente única si es una **cuenta sobre un corpus que sigue creciendo** —el `rounds-log`, la historia de este repo, la historia del repo externo—. Ésas viven en `docs/metrics.md` con su corte y su comando, y cualquier otra mención de la vidriera las **cita** sin re-derivarlas. Concretamente:

- **Sujetas**: 88 rondas, 59 rechazos, 29 hitos, 123 histórico, 35 previas, 23 ciclos, «cero aprobados en ronda 1»; las del gancho (commits, días, features cerrados); y las de la instalación externa (185 commits en `4908bfb`, 20 archivos, 8 archivos) — que van al doc de métricas **aunque no sean del reviewer**, porque son de la misma especie y porque ya fueron el sitio de un defecto real: la r19 del 13 encontró ahí un contador publicado sin corte y atribuido al SHA equivocado.
- **No sujetas**: constantes del artefacto que no cuentan nada creciente (códigos de salida `0/1/2`, siete comandos, cinco principios, «más de 10 minutos», que es limitación declarada y no medición), y las **citas internas del transcript** (ronda 1, ronda 7, `f85a033`, `886fe4f`), que son referencias a una corrida cerrada y están cubiertas por el criterio de «ninguna línea inventada» del 13.

El chequeo que la vuelve mecánica: toda cifra sujeta que aparezca en `README.md` aparece en `docs/metrics.md` **con el mismo valor**, y **ningún comando de derivación** de una cifra sujeta vive fuera de `docs/metrics.md`.

## Enfoque

### `docs/metrics.md` — el informe

Inglés. Estructura:

1. **Qué es y qué no** — la foto y su corte; que no incluye las rondas de los features 13 y 14, declarado y no escondido.
2. **Las tres unidades que no se mezclan** — ronda, hito, ciclo, con la advertencia de que los `APPROVED` son **hitos y no features**, y que enunciarlo mal es lo que destruye la credibilidad.
3. **Las cifras**, cada una con su comando.
4. **Cómo re-derivarlas** — el esquema de los siete campos del snapshot, `cut.awk`, `normalize.awk`, y las postcondiciones como postcondiciones (`rc=0` obligatorio), no como cortesía.
5. **Qué no prueba esta evidencia** — el contra-chequeo contra SHA verifica que los commits existen, que las fechas cierran y que la historia es **lineal**; **no** prueba que nadie la haya reescrito antes de publicarla, porque un force-push previo es indetectable desde un clon. Se afirma lo primero y no lo segundo.
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
- `config.yml` — `blank_issues_enabled: true` y un `contact_links` a `CONTRIBUTING.md`.

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
| C3 | Toda cifra publicada en `docs/metrics.md` **se re-deriva** con el comando que el propio doc declara, sobre el snapshot versionado, y coincide | re-corrida de la tabla completa de comandos |
| C4 | Los `awk` publicados en inglés producen salida **idéntica** a los del 13 sobre el mismo snapshot | diff de las dos salidas; debe ser vacío |
| C5 | **Fuente única**: toda cifra sujeta (definición de §«Fuente única») que aparece en el `README.md` aparece en `docs/metrics.md` con el mismo valor, y ningún comando de derivación de una cifra sujeta vive fuera de `docs/metrics.md` | recorrido del inventario de cifras del README, una por una |
| C6 | Los tres YAML de `.github/ISSUE_TEMPLATE/` **parsean**, y los dos formularios traen los campos requeridos que el enfoque enumera | `ruby -ryaml` (toolchain de stock de macOS) + inspección campo por campo |
| C7 | **Las dos referencias del 13 son links que resuelven**, y no queda ninguna marca de «pendiente para el 14» en el README | inspección de los dos puntos + chequeo de destinos |
| C8 | **Cero link roto** en el conjunto completo — `README.md`, `CONTRIBUTING.md`, `docs/metrics.md`, `docs/install.md` | chequeo mecánico de todo destino relativo y de toda ancla interna contra los encabezados reales |
| C9 | **Cero afirmación no verificable**: toda oración de `CONTRIBUTING.md` y `docs/metrics.md` cae en una de las tres clases del contrato editorial (hecho derivable con su comando · limitación declarada · opinión marcada) | pasada por oración, registrada en el Review log |
| C10 | `CONTRIBUTING.md` declara **qué está fuera de alcance hoy** incluyendo el aviso MIT como **incumplimiento pendiente**, no como cumplimiento parcial | lectura literal |
| C11 | Los **tres comandos de GitHub** están escritos pegables sin editar, con herramienta, sintaxis y precondiciones declaradas y cero huecos, **y ninguno fue ejecutado** | inspección + prueba negativa: cero commits de push, `git rev-list --count origin/main..main` sin cambio atribuible a esta unidad, y sin llamadas a `gh` fuera de `--help` |
| C12 | **Alcance**: el diff de la unidad toca solo los paths de §Alcance — cero cambios en método, skills, instalador, scripts, tests, ledger o remoto | `git diff --stat` contra `6ec4b48`, con la lista de paths esperados como lista cerrada |
| C13 | **La inconsistencia del corte quedó resuelta por escrito**, con la razón contractual y no por preferencia | §«La inconsistencia entre docs», presente y citada desde el informe si corresponde |
| C14 | No-regresión: `tests/lint.sh`, `tests/loop.sh` y `tests/install.sh` limpios | corrida de las tres suites |

## Riesgos

1. **La regla de fuente única es interpretable, y una regla interpretable churnea.** Es el riesgo más probable de esta unidad. Mitigación: la línea está **fijada por escrito antes de implementar** (§«Fuente única»), con la clase incluida, la clase excluida y el chequeo mecánico que la aplica. Si el reviewer no acepta la línea, se discute la línea una vez — no cifra por cifra.
2. **Contadores móviles reapareciendo en prosa.** Es la causa de las dos rachas de la unidad 13. Mitigación: la regla adoptada arriba, aplicada también a este doc; donde hace falta un número que se mueve, va el comando.
3. **YAML que GitHub descarta en silencio.** Un formulario mal formado no avisa: simplemente no aparece. Mitigación: C6 valida con un parser real, no a ojo.
4. **Tentación de correr los comandos de GitHub** —están escritos, verificados y a un `Enter` de distancia—. Mitigación: C11 incluye una **prueba negativa**, y el corte está declarado como consecuencia.
5. **El corte envejece mientras se trabaja.** Las rondas de esta misma unidad entran al `rounds-log`. Mitigación: es exactamente lo que el corte neutraliza; la consecuencia (el snapshot no incluye las rondas de los features 13 y 14) se **publica**.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Sigue siendo una línea a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.
7. **Ampliar la edición del README.** El contrato dice «activar dos referencias», no «revisar la vidriera». Mitigación: C7 acota, y ante una tercera cosa que parezca necesaria se registra y se pregunta en vez de decidir solo.

## Review log

_(vacío — se completa ronda por ronda)_
