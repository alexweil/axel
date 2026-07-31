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

**Los desempates se identifican por su letra y su SHA, no por ordinal** (r12). Yo llamaba «tercer desempate» a **dos** eventos distintos —el «a)» del primer corte de esta unidad y el «c)» del segundo—, y el ledger ya tenía asignado ese ordinal al primero. Un ordinal es un contador que el proceso mueve: cada corte nuevo lo corre, y basta un evento no contado para que toda la numeración quede mal. La letra y el SHA no se mueven.

**`AUTORIZADOS` — lista cerrada de commits del padre interiores al rango, y ahora *derivada* y no recordada.** Tras el olvido de `ae28842`, el padre adoptó el método correcto: `git log --format=%H 2985447..HEAD -- <ledger>` y declarar **todo** lo que salga. El hijo lo re-derivó por su cuenta y **las dos derivaciones coinciden**, que es lo que vuelve creíble la lista. El contrato le deja al padre una sola excepción durante el ciclo: corregir una falsedad vigente. Cuando la usa, su SHA entra acá **en la misma ronda** en que commitea.

- `2fc4dd4` — registro del **corte por deadlock** del ciclo de bajada (r1–r5). Toca `docs/STATUS.md` y el ledger.
- `71c78be` — registro del **desempate humano «a)» del primer corte de esta unidad**, que autoriza los dos bloqueantes y reanuda la unidad. Toca `docs/STATUS.md` y el ledger.
- `e5ee8f2` — **corrección de una falsedad vigente en el `## Cierre` del ledger**, que es la única excepción que el contrato le deja al padre durante un ciclo: el bloque describía el primer corte como si fuera el único y decía que la corrida se reanuda en la unidad `13`. Toca **solo** el ledger. La detectó la r6 y el hijo **no la tocó**: se la pasó al padre, que commiteó y devolvió el SHA en el acto, que es el protocolo que la unidad `13` dejó probado.
- `380eb74` — **retiro de una afirmación universal del `## Cierre`**: el bloque decía que **todos** los cortes se resolvieron con «a)», y el último fue «c)». El padre lo nombró mejor de lo que yo lo había marcado: no era «una letra mal» sino **una afirmación universal sobre un conjunto que la corrida sigue ampliando** — el defecto del contador móvil con otra forma. Retirada: la letra ya no se publica ahí y cada corte la lleva en su propio evento, con comando de derivación verificado corriéndolo y chequeado explícitamente contra el auto-matcheo. Toca **solo** el ledger.
- `7c0aa7c` — **reescritura completa del `## Cierre`**, en vez de una sexta corrección puntual. El bloque deja de publicar cantidades, letras, cuantificadores y comandos que agreguen las interrupciones, y **separa los dos dominios que el comando anterior mezclaba** —deadlock contra indisponibilidad del reviewer—, porque un comando que los cuente juntos es falso por construcción. Toca **solo** el ledger.

  > **El caso más denso del patrón que produjo el pipeline, y es del padre.** Cinco correcciones sucesivas al mismo párrafo, cada una introduciendo el defecto de la siguiente: contador → cuantificador universal → **segundo cuantificador sobrevivido dentro de la corrección del primero** → comando que se contaba a sí mismo → comando que mezclaba dominios. La salida no fue una sexta corrección puntual sino **reescribirlo entero**, que es la decisión que la tercera ya pedía.

- `84002a0` — **retiro de una segunda universal del mismo párrafo del `## Cierre`**: al sacar «todos con a)» quedó viva «ninguno terminó la corrida», que vuelve a ampliar su universo con cada corte nuevo. Lo notable es la causa que el padre declaró: **su barrido anterior buscaba esos cuantificadores solo en negrita**, y ésta no la tenía — o sea que declaró «cero afirmaciones universales vivas» sobre un barrido que no podía verlas. Rehecho sin depender del formato y **revisando los matches caso por caso en vez de declarar cero**. Toca **solo** el ledger.
- `341c957` — **desempate humano «c)» del segundo corte de esta unidad**: se reanuda la unidad con el **mismo alcance, sin recortes**, y la racha reseteada. Queda registrado que el padre había recomendado cerrar sin esta unidad y ofrecido como alternativa recortar la ambición del andamiaje de verificación —Codex declaró **sólido el contenido canónico de los YAML**, así que lo que no cerraba era la maquinaria alrededor—, y que el humano decidió seguir con el alcance intacto.
- `5053251` — **segundo corte por deadlock** (racha 5, r6–r11). Toca `docs/STATUS.md` y el ledger.
- `ae28842` — **corte de la unidad por indisponibilidad del reviewer**: la r10 salió `PROC_FAIL` en sus **dos** intentos, sin veredicto, porque Codex agotó su cuota de uso. Es `exit 2` persistente (condición 1), **no deadlock**. Toca `docs/STATUS.md` y el ledger. **Este SHA lo encontró la auditoría, no lo declaró el padre**: al reanudar pasó solo el de la reanudación. Se incorporó atribuido al padre **por evidencia y no por presunción** —formato de mensaje del padre, registra el corte que él mismo describió, y toca únicamente sus dos archivos— y se le pidió confirmación, que **dio**: es suyo. La causa que él identificó es la misma clase que esta unidad viene persiguiendo: **declaró de memoria en vez de derivar**, esta vez sobre sus propios commits; la forma correcta es `git log --format=%h <baseline>..HEAD -- <ledger>` y declarar todo lo que salga, no lo que se recuerda haber hecho.

> **Por qué se justifica `AUTORIZADOS`, y es por esta vez y no por las otras.** Hasta acá el mecanismo venía **registrando**; ésta es la vez que **detectó** — y detectó un error de quien lleva la lista, que es exactamente el caso para el que existe. Un criterio de este tipo no se justifica por las veces que pasa: se justifica por la vez que atrapa algo que ninguna lectura habría visto. Si no hubiera estado, el commit del corte habría quedado dentro del rango del hijo sin declarar y C12 habría fallado —o peor, habría pasado inadvertido.
- `140ad61` — **reanudación tras la decisión humana**: créditos de Codex recargados. La racha **no se resetea** —sigue en 4— porque la r10 nunca produjo veredicto y por lo tanto no consumió ronda del tope. Toca `docs/STATUS.md` y el ledger.
- `7f57494` — **tercera corrección del mismo bloque**: el comando de enumeración que dejó la segunda **matcheaba su propia línea** y devolvía un resultado de más. Anclado al encabezado de evento, y verificado **corriéndolo tal como queda publicado** —el anterior daba 4, el anclado da 3, que son los cortes reales—, no razonándolo. Toca **solo** el ledger.
- `68a2fe5` — **segunda corrección del mismo bloque**, y la ironía es completa: al arreglar lo anterior el padre escribió «tres cortes», un **contador móvil en prosa**, en el mismo commit donde aplicaba la regla de contadores móviles a todo el resto del archivo. Con el pipeline abierto, otro deadlock la volvía falsa. Reemplazada por referencia a los eventos más un comando de enumeración. Toca **solo** el ledger. La detectó la r7, el hijo tampoco la tocó, y el padre barrió el archivo entero al corregirla.

`2985447` **no** es miembro: es la frontera del rango y `git rev-list 2985447..HEAD` no lo incluye. Se nombra acá solo para que no se lo busque en la lista.

**El chequeo tiene que ser fail-closed de verdad, y el mío no lo era.** Al re-correrlo tras el corte por cuota, mi versión anterior recorría los commits en un `for … done | head`, así que el flag de violación quedaba en el subshell del pipe y **el chequeo imprimía «pasa» mientras había impreso una violación dos líneas arriba**. Reescrito sin pipeline y con **prueba negativa**: quitando un SHA de `AUTORIZADOS`, el chequeo devuelve `rc=1` y nombra la violación. Un verificador que nunca rechazó nada no está verificado — es el mismo criterio que la unidad aplicó a los fixtures, aplicado ahora a su propia auditoría.

**El chequeo real de C12, ejecutable y corrido.** La r11 marcó que yo declaraba el arreglo fail-closed mientras el procedimiento publicado **solo corría `git show`**: no comparaba contra `AUTORIZADOS`, no validaba allowlists, no mantenía flag y terminaba siempre en `0`. Era el segundo «mecanismo declarado que no ejecuta» de la misma ronda. El real:

```bash
#!/bin/bash
# C12 — alcance por commit, fail-closed. Identidad por SHA COMPLETO: `--short`
# depende de core.abbrev y de colisiones de prefijo, asi que no es identidad.
AUT="7c0aa7c455b85a6e4a540967566027f10751a8a9 84002a0009fcf00c550e2575ebb44f3cf0f8db55 380eb749b6a635c76d5093286c60557b8128855d 341c9577afdd816e189171cdfc192682039ac7f0 505325120381ba7e66c0471f1ad2489fee5f1166 140ad61ef2aa553b8ba73f7db06d995accb5ec40 ae2884223eb103f73deaf4880e9ba22d6e4eeb0f 7f5749495bc2ba4d15ce79ddea7d0dbe7f6b2b31 68a2fe52f33cd604f8ee54ecd9558cfb3621bbc2 e5ee8f23f4e6891ecc12679147d7219bb15ce339 71c78bee5dd2db85daccc8de87543a5ea9d9e4da 2fc4dd47e07db0064b99d6d658cfffecec31a792"
LEDGER='docs/implementation/pipeline-2026-07-29-3.md'
HIJO='docs/STATUS.md
docs/IMPLEMENTATION.md
docs/implementation/14-onboarding-feedback.md
CONTRIBUTING.md
README.md
docs/metrics.md
docs/metrics/rounds-log-b0bdf4d.tsv
docs/metrics/cut.awk
docs/metrics/normalize.awk
.github/ISSUE_TEMPLATE/config.yml
.github/ISSUE_TEMPLATE/install-failed.yml
.github/ISSUE_TEMPLATE/friction-or-question.yml'
BASE="${1:-2985447}"
viol=0
if ! commits=$(git rev-list "$BASE..HEAD" 2>/dev/null); then
  echo "FALLA: git rev-list $BASE..HEAD no pudo ejecutarse"; exit 1
fi
[ -z "$commits" ] && { echo "FALLA: rango vacio; se esperaba al menos un commit"; exit 1; }
while read -r c; do
  if ! paths=$(git show --no-renames --name-only --format= ${GITSHOW_OPTS:-} "$c" 2>/dev/null); then
    echo "FALLA: git show de $c no pudo ejecutarse"; exit 1
  fi
  [ -z "$paths" ] && { echo "FALLA: $c no declara paths; un commit vacio no es auditable"; exit 1; }
  if [[ " $AUT " == *" $c "* ]]; then
    while read -r p; do [ -z "$p" ] && continue
      case "$p" in "$LEDGER"|docs/STATUS.md) ;; *) echo "VIOLACION padre ${c:0:7}: $p"; viol=1;; esac
    done <<< "$paths"
  else
    while read -r p; do [ -z "$p" ] && continue
      grep -qxF "$p" <<< "$HIJO" || { echo "VIOLACION hijo ${c:0:7}: $p"; viol=1; }
    done <<< "$paths"
  fi
done <<< "$commits"
# Todo entregable versionado debe ser archivo REGULAR: un symlink entra con modo
# 120000 y las lecturas lo siguen, asi que el chequeo de contenido no lo ve.
while read -r p; do [ -z "$p" ] && continue
  m=$(git ls-files -s -- "$p" | awk '{print $1}')
  [ -z "$m" ] && continue
  [ "$m" = "100644" ] || { echo "VIOLACION modo: $p es $m y no un archivo regular"; viol=1; }
done <<< "$HIJO"
[ "$viol" -eq 0 ] && { echo "C12 PASA"; exit 0; } || { echo "C12 FALLA"; exit 1; }
```

**Corrido**: `C12 PASA`, `rc=0`. **Prueba negativa corrida**: quitando `ae28842` de `AUTORIZADOS`, devuelve `rc=1` y `VIOLACION hijo ae28842: docs/implementation/pipeline-2026-07-29-3.md`. Un verificador que nunca rechazó nada no está verificado.

**El chequeo anterior fallaba abierto, y es el peor modo posible.** Recorría los commits en un `for … done | head`, así que el flag moría en el subshell del pipe: imprimió `VIOLACION: ae28842` y **dos líneas después** `C12 pasa`. Ruidoso y aprobatorio a la vez — quien lee se queda con el veredicto. La forma de arriba no tiene pipeline y por eso el flag sobrevive.

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
| charset de `id`: solo alfanuméricos, `-` y `_` | GitHub | **verificada** — «`'id' can only contain numbers, letters, -, _`» ⇒ E8b (agregada en la r7) |
| claves no permitidas dentro de un elemento y dentro de `attributes` | GitHub | **verificada** — «`'x' is not a permitted key`» / «`'x' is not a permitted attribute`» ⇒ E14 y, para los atributos, la fijación de C15 |
| strings vacíos o solo-whitespace rechazados | GitHub | **verificada** — «`Empty strings, or strings consisting of only whitespaces, are not permissible when the field expects a string`» ⇒ E13 |
| **cuándo aparecen los errores de validación** | GitHub | **verificada, y corrige una afirmación mía**: «*when creating, saving, or viewing issue forms*» — o sea que GitHub **sí** avisa. Lo que no podemos es verlo sin pushear, que es una limitación **nuestra** y no de la herramienta |
| «`name` exige más de tres caracteres» | GitHub | **verificada — y yo la había declarado inexistente.** La documentación lo dice literal: «*The `name` field must be more than 3 characters. If it's not, the template won't be shown when creating an issue*». En la r7 consulté la fuente, no lo encontré, y publiqué **«buscada y no encontrada»** como si eso zanjara la cuestión. Ver la nota de abajo |
| unicidad de `label` entre campos de entrada, y de las opciones de un `checkboxes` entre sí y frente a otros inputs | GitHub | **verificada** |
| labels «demasiado similares» (dos distintos que se parametrizan al mismo string) | GitHub | **verificada** |
| términos prohibidos en `label` (los usados por atacantes, p. ej. `password`) | GitHub | **verificada** |
| `None` como palabra reservada en `options` de `dropdown` | GitHub | **verificada** |
| unicidad de `name` entre plantillas del repo | GitHub | **buscada en las tres páginas y no documentada en ellas.** Se registra como **no verificada**, no como inexistente — que es la distinción que me costó el punto de arriba |

Dos cosas que el barrido enseña, más allá de las filas:

- La fila retirada (`CONTRIBUTING.md`) es la que mejor muestra el criterio: **cuando una afirmación no es necesaria para la decisión, retirarla cuesta menos que sostenerla**.
- **«Buscada y no encontrada» es una afirmación sobre mi búsqueda, no sobre el mundo — y la publiqué como si fuera lo segundo.** Es la lección de la r8 y la más incómoda de la unidad. En la r7 sostuve contra el reviewer que el mínimo de tres caracteres para `name` no estaba documentado; **sí lo está**, textual, en una de las páginas que yo mismo había consultado. Mi error no fue discutir —discutir con evidencia es correcto, y el criterio que invoqué («encodear una restricción sin fuente es el mismo defecto con la autoridad cambiada de lado») sigue siendo cierto—: fue **tratar el resultado negativo de mi búsqueda como un hecho verificado**, cuando una búsqueda fallida no distingue «no existe» de «no lo encontré». La forma correcta de lo que podía afirmar era la de la última fila: *buscada y no documentada **en las páginas que consulté***, con la duda a mi cargo y no a cargo de quien la señaló.

*(El tamaño de este inventario no se publica en prosa: crece con cada ronda que encuentra una premisa nueva, y ya me costó un punto publicarlo. La tabla es la lista.)*

## El defecto dentro del acto de corregirlo

> Sección con nombre propio a pedido del padre, porque sirve más allá de este feature y se diluía entre los criterios.

Una y otra vez en esta unidad, un defecto apareció **dentro del acto de corregir otro del mismo tipo**. No en el mismo archivo ni en la misma semana: en el mismo commit, y en el párrafo que declaraba el remedio.

| Ocurrencia | Dónde apareció |
|---|---|
| una premisa sobre GitHub sin fuente | en la tabla donde yo declaraba **haber ido a la fuente** |
| un contador móvil publicado en prosa | en el párrafo que demuestra el **mecanismo que lo prohíbe** |
| «tres cortes» en el ledger | en el commit con que el padre **arreglaba otra falsedad del mismo bloque**, aplicando la regla al resto del archivo |
| la matriz de fixtures incompleta | en la corrección que declaraba **haberla vuelto completa** |
| «buscada y no encontrada» sobre `name` | en el barrido cuyo propósito era **no afirmar sin fuente** |
| el comando de enumeración que se auto-matchea | en la corrección que **reemplazaba un contador por ese comando** |
| un bloque de código que no compila | en la corrección que **publicaba el verificador**, con la verificación cortando donde yo quería y no donde el bloque terminaba |
| una universal viva sin negrita | en el barrido que **declaraba cero universales vivas**, y que solo miraba negrita |

**No es descuido, y tratarlo como descuido es lo que hace perder rondas.** Corregir *es* escribir, y escribir es donde el defecto nace. Un autor que acaba de identificar una clase de error está, en ese preciso momento, produciendo texto nuevo — texto que ninguna revisión ha visto y que la atención puesta en el defecto anterior no protege. La probabilidad de reincidir no baja durante la corrección: **sube**, porque hay más superficie nueva por unidad de tiempo que en cualquier otro momento.

**Y un refinamiento del método que salió de la r12, formulado por el padre**: *hermanos de la clase* no reemplaza a *hermanos del síntoma* — **son dos barridos distintos y hay que hacer los dos**. En la r12 cerré la clase con éxito (los tres «mecanismos declarados que no ejecutan», incluido uno que todavía no había sido señalado) y **el síntoma se escapó por el otro lado**: cambié las secciones y no los criterios que las citaban. Barrer la clase responde «¿dónde más cometí este tipo de error?»; barrer el síntoma responde «¿qué más apunta al texto que acabo de cambiar?». La segunda pregunta es mecánica y es la que se saltea cuando la primera sale bien.

#### El barrido del síntoma, mecanizado (r15)

El padre formuló la distinción clase/síntoma como **aprendizaje**, y en la r14 la cité y no la apliqué: cerré los symlinks dentro de `.github/` sin preguntarme qué otros entregables tenían la misma superficie. Su lectura, que es la correcta y lo incluye: **una lección que depende de acordarse es exactamente la clase de garantía que esta unidad viene moviendo del autor al mecanismo**. Entonces deja de ser lección:

```bash
#!/bin/bash
# Barrido de HERMANOS DEL SINTOMA, mecanizado: toda referencia §«...» de la PROSA
# debe resolver a un encabezado existente. Es el defecto de la r12 —criterios
# citando secciones que ya no existian— convertido en chequeo en vez de leccion.
# Excluye los bloques de codigo: si no, el propio script publicado se lee a si
# mismo y sus literales de regex aparecen como referencias huerfanas.
DOC="${1:-docs/implementation/14-onboarding-feedback.md}"
[ -r "$DOC" ] || { echo "FALLA: doc no legible"; exit 1; }
norm() { sed -E 's/[*`]+//g'; }
sin_codigo() { awk '/^`{3,4}/{f=!f; next} !f'; }
encabezados=$(cat "$DOC" docs/implementation/13-public-showcase.md docs/design/public-surface.md 2>/dev/null \
              | grep -E '^#{2,4} ' | sed -E 's/^#+ //' | norm)
[ -z "$encabezados" ] && { echo "FALLA: cero encabezados; el patron no puede estar bien"; exit 1; }
refs=$(sin_codigo < "$DOC" | grep -oE '§«[^»]+»' | sed -E 's/^§«//; s/»$//' | norm | sort -u)
[ -z "$refs" ] && { echo "FALLA: cero referencias; el patron no puede estar bien"; exit 1; }
viol=0
while read -r r; do
  [ -z "$r" ] && continue
  grep -qF "$r" <<< "$encabezados" || { echo "HUERFANA: §«$r» no resuelve a ningun encabezado"; viol=1; }
done <<< "$refs"
[ "$viol" -eq 0 ] && { echo "HERMANOS OK"; exit 0; } || { echo "HERMANOS FALLA"; exit 1; }
```

Verifica lo que la r12 rompió —criterios citando secciones que ya no existían— y **corre en cada ronda**, no cuando alguien se acuerde. Probado en los dos sentidos: pasa sobre el doc actual y falla al renombrar una sección efectivamente citada.

*(Su calibración vale como caso, y necesitó **tres** pasadas: la primera versión marcó dos huérfanas que eran **falsos positivos** —el énfasis markdown dentro de un encabezado, y una referencia cruzada legítima al doc del feature 13—, y mi primera prueba negativa renombraba una sección **que nadie referencia**, así que no probaba nada. Un chequeo que grita sin motivo es tan inútil como uno que nunca rechaza, y una prueba negativa que no ejercita la rama es la misma trampa una vez más. Y la tercera: **al publicar el script dentro del doc que revisa, sus propios literales de regex se leyeron como referencias huérfanas** — un chequeo que se rompe al ser publicado, que es la autorreferencia de esta unidad en su forma más literal. Cerrado excluyendo los bloques de código.)*

De ahí la única salida que funciona: **mover la garantía del autor al mecanismo**. Que la propiedad no dependa de que alguien recuerde aplicarla, sino de que su violación sea detectable —o imposible— por construcción. Las formas que esta unidad terminó usando son ejemplos de lo mismo:

- **auditar por commit y no por diff agregado** — el instrumento conserva la distinción que el criterio necesita, en vez de exigir que la redacción la recupere;
- **no publicar contadores móviles** — la cifra se deriva o se ancla, así que no hay prosa que pueda desincronizarse;
- **fijar el contenido literal en vez de enumerar lo prohibido** — la condición de cierre pasa de un conjunto abierto ajeno a un artefacto cerrado propio.

**Alcance de la observación, dicho para no repetir el defecto que describe**: sale de una unidad y de un ciclo de review; no está medida contra otras. Lo que sí es verificable es la lista de arriba, y que las veinte rondas de la unidad `13` —donde los commits del padre y los del hijo se mezclaban en un rango común y cada corrección movía la evidencia del otro— son de esta forma.

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

### La especificación literal — los tres archivos, completos

La r9 encontró que **C15 prometía una especificación literal que no existía**: las tablas fijaban propósito, tipo y requiredness, pero ningún valor —ni `name`, ni `id`, ni `label`, ni los textos—, así que C6 no tenía contra qué comparar. Es el mismo defecto que C15 fue creado para atrapar, ocurriendo dentro de C15. Se materializa acá: **estos bloques son los archivos**, y la implementación los copia sin editar.

`.github/ISSUE_TEMPLATE/install-failed.yml`

```yaml
name: Install failed
description: The installer refused, errored, or wrote something unexpected
body:
  - type: markdown
    attributes:
      value: |
        Thanks for trying axel. The fields below are the ones that make a failed
        install diagnosable without a round trip.
  - type: input
    id: environment
    attributes:
      label: Operating system and git version
      placeholder: macOS 15.5, git 2.49.0
    validations:
      required: true
  - type: textarea
    id: final-line
    attributes:
      label: The installer's final line
      description: "The line beginning with `── axel · fin: rc=`"
    validations:
      required: true
  - type: textarea
    id: full-output
    attributes:
      label: Full installer output
    validations:
      required: true
  - type: textarea
    id: gitignore-rules
    attributes:
      label: Lines in the destination .gitignore that mention build/
      description: Write "none" if there are no such lines.
    validations:
      required: true
  - type: dropdown
    id: announced-mode
    attributes:
      label: Which mode did the installer announce?
      options:
        - initial
        - adoption
        - update
        - it did not get that far
    validations:
      required: true
  - type: checkboxes
    id: clean-tree
    attributes:
      label: Destination state before running
      options:
        - label: The destination repository had a clean working tree
          required: true
```

`.github/ISSUE_TEMPLATE/friction-or-question.yml`

```yaml
name: Friction or a question
description: Something was unclear, harder than it should be, or you are not sure how it is meant to work
body:
  - type: markdown
    attributes:
      value: |
        Questions belong here too. If the answer was not obvious from the README
        or the install manual, that is a documentation bug worth reporting.
  - type: textarea
    id: what-you-were-doing
    attributes:
      label: What you were doing
    validations:
      required: true
  - type: textarea
    id: what-you-expected
    attributes:
      label: What you expected to happen
    validations:
      required: true
  - type: textarea
    id: what-happened
    attributes:
      label: What happened instead
    validations:
      required: true
  - type: checkboxes
    id: where-you-looked
    attributes:
      label: Where you looked first
      options:
        - label: The README
        - label: The install manual
        - label: The contributing guide
        - label: The skill files
        - label: Nowhere yet
```

`.github/ISSUE_TEMPLATE/config.yml`

```yaml
blank_issues_enabled: true
contact_links:
  - name: How to give feedback
    url: https://github.com/alexweil/axel/blob/main/CONTRIBUTING.md
    about: What this round of feedback is looking for, and what is out of scope today.
```

**Los bloques de arriba son la autoridad, y lo que no está en ellos no está.** La versión anterior enumeraba «las claves opcionales omitidas» como si esa lista pudiera ser completa, y la r11 mostró que no lo era —faltaban `value` en `input`/`textarea` y `default` en `dropdown`, entre otras—. **Volver a enumerar la especificación de un tercero es exactamente lo que la inversión manda no hacer**: es la misma condición de cierre abierta que costó cuatro rondas, reapareciendo en la sección que la reemplazó.

Entonces no se enumeran las omisiones. Se conserva **una sola**, porque necesita justificación local y no se deduce de los bloques:

- **`labels` queda fuera a propósito.** Aplicar una etiqueta que no existe en el repo es un settings de GitHub, y crear etiquetas está fuera del alcance por el ajuste (b) del gate. Declarar `labels` apuntando a etiquetas inexistentes sería publicar una afirmación que no podemos verificar ni volver verdadera.

**Cómo se valida, y por qué esto cambió en la r8.** Hasta la r7 el chequeo era «enumerar las causas por las que GitHub descarta un formulario y verificar que ninguna ocurra». Las rondas r5, r6, r7 y r8 encontraron, cada una, **causas nuevas que la enumeración anterior no tenía** — y no por descuido: la lista de causas es de GitHub, vive en su documentación, y **yo no puedo acotarla**. Un criterio cuya condición de cierre es «haber agotado la especificación de un tercero» no cierra nunca. Es exactamente la clase abierta que esta unidad diagnosticó, alojada dentro del criterio que debía cerrarla.

**La inversión, que es lo que la vuelve acotada**: el chequeo deja de preguntar *«¿viola alguna regla de GitHub?»* —conjunto abierto, ajeno— y pasa a preguntar *«¿contiene exactamente lo que la bajada fijó?»* —conjunto cerrado, nuestro—.

| | Antes (r2–r7) | Desde la r8 |
|---|---|---|
| pregunta | ¿viola alguna causa documentada? | ¿coincide con la especificación literal de C15? |
| dueño del conjunto | GitHub | esta bajada |
| condición de cierre | agotar una spec ajena | cubrir nuestros propios campos |
| cómo se satisfacen las reglas de GitHub | verificándolas una por una | **eligiendo contenido que las satisface por construcción**, con la elección registrada contra su regla |

No es una rebaja: **fijar el contenido literal completo es más exigente que chequear invariantes**, porque no deja ningún valor sin decidir. Y es la misma jugada que el hallazgo de §«El defecto dentro del acto de corregirlo», un nivel más arriba: mover la condición de cierre de un conjunto abierto ajeno a un artefacto cerrado propio.

**C15 fija la especificación literal completa** de los tres archivos: cada clave, cada valor, cada atributo de cada campo `F1–F7` y `G1–G5`, y el contenido entero de `config.yml`. **C6 verifica dos cosas y nada más**: que los tres archivos **parsean**, y que **coinciden con esa especificación** — sin una clave de más, sin una de menos, sin un tipo ni un valor distinto.

### Las reglas documentadas de GitHub, satisfechas por construcción

Siguen importando: si el contenido que elegimos violara una, el formulario no aparecería. La diferencia es que ahora **cada regla se satisface eligiendo el contenido**, y la elección queda registrada con su fuente. No se chequean; se cumplen por cómo están escritos los archivos, y esta tabla es lo que hace auditable esa afirmación.

| Regla documentada | Cómo la satisface el contenido fijado |
|---|---|
| `name` debe superar **3 caracteres**, o la plantilla **no se muestra** | `Install failed` (14) y `Friction or a question` (22) |
| **`name` único entre todas las plantillas del repo**, incluidas las Markdown (regla que faltaba, señalada en la r9) | los dos literales son distintos, y **no hay otras plantillas** en `.github/ISSUE_TEMPLATE/` |
| claves de raíz requeridas (`name`, `description`, `body`) y sin claves ajenas | C15 fija el conjunto de claves de raíz de cada archivo |
| `body` no vacío y con **al menos un campo no-`markdown`** | `F1–F7` y `G1–G5` incluyen seis y cuatro campos de entrada |
| `type` presente y válido en cada elemento | C15 fija el `type` de cada campo |
| atributos requeridos por tipo (`value` en `markdown`, `label` en el resto) | C15 fija los atributos de cada campo |
| `options` de `dropdown`: lista de strings, no vacía, distintas | solo F6 es `dropdown`; C15 fija sus cuatro opciones |
| **`None` es palabra reservada** en un `options` de `dropdown` — «*is used to indicate non-choice when a `dropdown` is not required*» | ninguna opción de F6 es `None`, y F6 es `required` |
| `options` de `checkboxes`: lista de objetos con `label`, `required` booleano opcional | F7 y G5 son los únicos `checkboxes`; C15 fija sus opciones |
| **`label` único entre todos los campos de entrada**, y los de un `checkboxes` únicos **entre sí y frente a otros tipos de input** | C15 fija los labels; se eligen distintos entre los doce campos y entre las opciones |
| **labels «demasiado similares»** — dos labels distintos pueden parametrizarse al mismo string | los labels fijados no colapsan al parametrizarse; queda como criterio explícito al elegirlos |
| **términos prohibidos en `label`** (los usados por atacantes, p. ej. `password`) — para que no se publiquen credenciales | ningún campo pide credenciales; el formulario de instalación pide salida de consola y reglas de `.gitignore` |
| `id` únicos y con charset `alfanumérico`, `-`, `_` | C15 fija los `id`; se eligen en minúscula con guiones |
| strings no vacíos ni solo-whitespace | C15 fija valores literales, ninguno vacío |
| tipos de dato correctos (`required` booleano, `options` lista) | C15 fija los tipos |
| `config.yml`: `blank_issues_enabled` booleano y `contact_links` con `name`, `about` y `url` absoluto | C15 fija el archivo completo, URL incluido |

**Límite declarado, y ahora es honesto porque el chequeo ya no promete lo contrario**: el validador de GitHub es la autoridad final y no se lo puede correr sin pushear, cosa prohibida en esta unidad. Esta tabla registra **las reglas que la documentación publica y que conocemos**; que GitHub tenga otras no documentadas es posible y no se puede descartar desde acá. Lo que sí se garantiza es lo acotado: los archivos coinciden con una especificación cerrada, y esa especificación fue elegida contra las reglas de arriba.

### El verificador de plantillas — ejecutable, corrido, con sus casos negativos

La r11 encontró que el comparador que yo había publicado **no era ejecutable**: invocaba un `extraer_bloque` que no existe, y además `diff <(extractor) archivo` **falla abierto respecto del extractor** —un extractor que imprime los bytes correctos y sale con `rc=1` deja a `diff` devolver `0`—. Era la tercera vez en la unidad que publicaba un **mecanismo declarado que no ejecuta**. Se reemplaza por un validador único, real, y **corrido**:

````ruby
#!/usr/bin/env ruby
# verify-templates.rb <spec.md> <dir>
# Extrae los bloques canonicos de la bajada, exige exactamente uno por archivo,
# compara byte a byte, rechaza lo que no sea archivo regular, parsea, y exige
# que el directorio sea un directorio real con exactamente esos tres archivos.
require 'yaml'
spec_path, dir = ARGV[0], ARGV[1]
NAMES = %w[config.yml friction-or-question.yml install-failed.yml].freeze
failed = false
def bad(m) warn "FAIL: #{m}"; end

abort("FAIL: spec no legible: #{spec_path}") unless File.readable?(spec_path)
spec = File.read(spec_path, encoding: "UTF-8")

begin
  dst = File.lstat(dir)
  bad("#{dir}: no es un directorio real (#{dst.ftype})") || failed = true unless dst.directory?
rescue SystemCallError
  bad "#{dir}: ausente"; failed = true
end

if !failed
  actual = Dir.children(dir).sort
  if actual != NAMES.sort
    bad "inventario != esperado: #{actual.inspect} vs #{NAMES.sort.inspect}"; failed = true
  end
end

NAMES.each do |n|
  marker = "`.github/ISSUE_TEMPLATE/#{n}`"
  re = /^#{Regexp.escape(marker)}\s*\n+```yaml\n(.*?)^```\s*$/m
  blocks = spec.scan(re).map(&:first)
  if blocks.size != 1
    bad "#{n}: se exige exactamente 1 bloque canonico, hay #{blocks.size}"; failed = true; next
  end
  canon = blocks.first
  path = File.join(dir, n)
  begin
    st = File.lstat(path)
  rescue SystemCallError
    bad "#{n}: archivo ausente"; failed = true; next
  end
  unless st.file?
    bad "#{n}: no es un archivo regular (#{st.ftype}) — git versionaria eso y no el YAML"; failed = true; next
  end
  if File.read(path, encoding: "UTF-8") != canon
    bad "#{n}: difiere del bloque canonico"; failed = true; next
  end
  begin
    YAML.load(canon)
  rescue => e
    bad "#{n}: el bloque canonico no parsea: #{e.class}"; failed = true
  end
end

if failed then warn "VERIFY: FAIL"; exit 1 else puts "VERIFY: OK"; exit 0 end
````

**Un solo programa hace las cuatro cosas** que antes estaban repartidas entre comandos que no se comprobaban entre sí: exige **exactamente un** bloque canónico por archivo, compara **byte a byte**, **parsea**, y verifica el **inventario exacto del directorio** — que es el punto 3 de la r11: sin él, un cuarto `.github/ISSUE_TEMPLATE/extra.yml` quedaba dentro del alcance permitido y ningún `diff` lo miraba. El inventario vuelve mecánica además la unicidad de `name` **entre todas las plantillas**, porque no puede haber una plantilla que la spec no fije.

**Corrido, con su camino positivo y los casos negativos de la tabla de abajo** —sin publicar la cantidad, que crece cada vez que una ronda encuentra una vía nueva (ya pasó en la r12 y en la r13)—, y esto reemplaza a la tabla de «familias de mutación» que era la tercera declaración sin ejecutar:

| Caso | Resultado |
|---|---|
| los tres archivos idénticos a sus bloques | `VERIFY: OK`, `rc=0` |
| un byte cambiado (`blank_issues_enabled: true` → `false`) | `rc=1`, «difiere del bloque canonico» |
| **clave duplicada** (`name: injected` antepuesto) — lo que un comparador estructural no ve | `rc=1`, «difiere del bloque canonico» |
| **un archivo es symlink** con los bytes canónicos — git versionaría el enlace | `rc=1`, «no es un archivo regular (link)» |
| **el directorio entero es symlink** a uno externo con los tres archivos (r13) | `rc=1`, «no es un directorio real (link)» |
| directorio con el nombre de una plantilla | `rc=1`, «no es un archivo regular (directory)» |
| archivo de más en el directorio | `rc=1`, «inventario != esperado» |
| archivo ausente | `rc=1`, archivo ausente |
| bloque ausente en la spec | `rc=1`, «se exige exactamente 1 bloque canonico, hay 0» |
| bloque duplicado en la spec | `rc=1`, «…hay 2» |
| spec ilegible | `rc=1`, aborta |
| **el bloque publicado no compila** | el harness aborta antes de correrlo |

**El harness que extrae y corre — publicado, porque sin él «corrido tal como se publica» es otra declaración sin ejecutar** (r13):

```bash
#!/bin/bash
set -euo pipefail
DOC="$1"; DIR="$2"; TMP=$(mktemp -d)
test "$(grep -c '^````ruby$' "$DOC")" -eq 1 || { echo "FALLA: se exige exactamente 1 bloque ruby"; exit 1; }
awk '/^````ruby$/{f=1;next} f&&/^````$/{exit} f' "$DOC" > "$TMP/v.rb"
/usr/bin/ruby -c "$TMP/v.rb" >/dev/null || { echo "FALLA: el bloque publicado no compila"; exit 1; }
/usr/bin/ruby "$TMP/v.rb" "$DOC" "$DIR"
```

**El fence del validador es de cuatro backticks a propósito, y ésa es la raíz del defecto de la r13.** El programa contiene la cadena ` ```yaml ` dentro de su propio regex, así que **un extractor que corta en la primera línea de tres backticks se detiene ahí**. Eso fue exactamente lo que pasó: mi extractor cortaba justo al final del programa nuevo y devolvía algo válido, mientras el bloque publicado arrastraba una cola huérfana del validador anterior y **no compilaba**. Mi verificación coincidía con lo que yo quería publicar, no con lo publicado — y el harness de arriba lo cierra, porque exige **exactamente un** bloque, corta con el fence largo y comprueba `ruby -c` **antes** de correr.

**Cómo se reproducen los negativos**: se extraen los tres bloques a un directorio temporal —el camino positivo—, y cada negativo es **una** alteración de ese estado. Ninguno toca el repo.

**El validador aceptaba symlinks, y eso lo encontró la r12 reproduciéndolo**: `Dir.children`, `File.readable?` y `File.read` **siguen enlaces**, así que reemplazar `config.yml` por un symlink a un archivo externo con los bytes canónicos daba `VERIFY: OK`. Git versionaría el enlace y no el YAML que GitHub necesita — o sea que el verificador aprobaba un artefacto defectuoso. Cerrado con `File.lstat` y el rechazo explícito de todo lo que no sea archivo regular, con sus dos negativos corridos.

**Dos defectos que encontró la corrida y ninguna lectura habría visto**: el Ruby de sistema lee en **US-ASCII** por defecto, así que `File.read` sin `encoding:` explotaba con `invalid byte sequence` sobre los guiones largos del doc; y la comparación tenía que ser de texto en la misma codificación, no `binread` contra un string UTF-8. Es la tercera vez en la unidad que correr encuentra lo que razonar no.

### `README.md` — edición acotada, y ahora **verificada como diff cerrado**

Dos referencias que el 13 dejó **a propósito** sin linkear y marcadas como pendientes, que este feature activa. La r14 encontró que «acotada» **no estaba verificado por nada**: `README.md` está en la allowlist de C12, así que una reescritura arbitraria devolvía `C12 PASA` —lo reprodujo—, y C7 solo exigía los dos links y la desaparición de la marca. Una implementación podía conservar los links y cambiar toda la prosa alrededor, incumpliendo §Alcance.

**La edición se fija como literal, igual que los YAML**, y C7 la verifica como **diff cerrado**: el conjunto de líneas quitadas y el de agregadas deben ser **exactamente** los declarados.

Líneas que se quitan:

````readme-quita
with the earlier 35 recovered from a separate source. *Coming in feature 14: the metrics document
that publishes the snapshot and the exact command behind every figure — not yet published, so for
now these numbers are only as good as this repo's git history, which you can read.*
> **Coming in feature 14, and deliberately not linked yet:** the **reviewer metrics document** — the
> versioned round-log snapshot, the cut commit, and the exact command behind every figure on this
> page — and **how to give feedback**, a `CONTRIBUTING.md` plus issue templates. Both are named here
> in prose on purpose: this page ships with zero broken links, and these two become links when the
> artefacts exist.
````

Líneas que se agregan:

````readme-pone
with the earlier 35 recovered from a separate source. Every figure on this page is derived in
[docs/metrics.md](docs/metrics.md), which publishes the versioned snapshot, the cut commit and the
exact command behind each one.
- [docs/metrics.md](docs/metrics.md) — the numbers on this page, with the command behind each
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to give feedback, and what this round is looking for
````

Los conjuntos salieron de **simular la edición en un worktree descartable** y capturar el diff real, no de escribirlos a mano — que es la misma disciplina de los bloques canónicos: el literal se deriva del artefacto, no al revés.

```bash
#!/bin/bash
# C7 — la edicion del README es ACOTADA, verificada como diff cerrado.
# El conjunto de lineas quitadas y agregadas debe ser EXACTAMENTE el declarado.
BASE="${1:-2985447}"; DOC="${2:-docs/implementation/14-onboarding-feedback.md}"
esperado_quita=$(awk '/^````readme-quita$/{f=1;next} f&&/^````$/{exit} f' "$DOC")
esperado_pone=$(awk '/^````readme-pone$/{f=1;next} f&&/^````$/{exit} f' "$DOC")
[ -z "$esperado_quita" ] && { echo "FALLA: no se pudo extraer el bloque readme-quita"; exit 1; }
[ -z "$esperado_pone" ]  && { echo "FALLA: no se pudo extraer el bloque readme-pone"; exit 1; }
if ! d=$(git diff "$BASE..HEAD" -- README.md 2>/dev/null); then
  echo "FALLA: git diff no pudo ejecutarse"; exit 1
fi
real_quita=$(printf '%s\n' "$d" | grep '^-' | grep -v '^---' | sed 's/^-//')
real_pone=$(printf '%s\n' "$d"  | grep '^+' | grep -v '^+++' | sed 's/^+//')
rc=0
diff <(printf '%s\n' "$esperado_quita") <(printf '%s\n' "$real_quita") >/dev/null || { echo "FALLA: las lineas QUITADAS no son las declaradas"; rc=1; }
diff <(printf '%s\n' "$esperado_pone")  <(printf '%s\n' "$real_pone")  >/dev/null || { echo "FALLA: las lineas AGREGADAS no son las declaradas"; rc=1; }
[ "$rc" -eq 0 ] && echo "C7 PASA" || echo "C7 FALLA"
exit $rc
```

Nada más de la prosa del README se reabre. Si al implementar apareciera una tercera cosa que activar, no se activa por cuenta propia: se registra y se pregunta, y el diff cerrado la haría fallar de todos modos.

## Criterios de cierre

| # | Criterio | Cómo se verifica |
|---|---|---|
| C1 | El snapshot es la **reconstrucción exacta** del corte `b0bdf4d` que declaró el 13: `rc=0`, **88** filas, última fila con ese SHA | corrida de `cut.awk` con sus tres postcondiciones |
| C2 | El snapshot es **prefijo literal** del `rounds-log` vivo — ni una línea editada | comparación mecánica contra las primeras 88 líneas del archivo vivo |
| C3 | `docs/metrics.md` publica sus cifras como matriz **exhaustiva por cifra** —`cifra → fuente(s) → corte → comando → límite de auditabilidad`—, cuyo universo es el de §Enfoque·3 y que **no deja ninguna cifra publicada sin fila**. Toda cifra auditable desde un clon de axel **se re-deriva y coincide**; las **compuestas** declaran sus sumandos y el comando de cada uno, sin presentar el total como derivación única; las de la instalación externa quedan **rotuladas como verificables solo contra `alexweil/inquirylab`**, nunca prometidas como re-derivables desde acá | re-corrida fila por fila, más la **prueba de cobertura**: cada cifra publicada en la superficie pública y en el propio informe tiene su fila; una cifra sin fila falla el criterio |
| C4 | Los `awk` publicados en inglés producen salida **idéntica** a los del 13 sobre el mismo snapshot | diff de las dos salidas; debe ser vacío |
| C5 | **Fuente única, acotada a la superficie pública**: en `README.md`, `docs/install.md`, `CONTRIBUTING.md` y `.github/`, toda cifra sujeta (definición de §«Fuente única») aparece en `docs/metrics.md` con el mismo valor, y ningún comando de derivación de una cifra sujeta vive fuera de `docs/metrics.md`. Los docs del método quedan fuera de la regla, por definición y no por excepción | inventario de cifras del **conjunto público completo** —los cuatro, no solo el README—, una por una |
| C6 | Los tres YAML de `.github/ISSUE_TEMPLATE/` son **byte a byte idénticos** a los bloques canónicos de §Enfoque·«La especificación literal», **son archivos regulares**, **parsean**, y el directorio **no contiene nada más**. La r8 invirtió la carga —de «¿viola alguna regla de GitHub?», conjunto abierto y ajeno, a «¿coincide con lo que la bajada fija?», cerrado y nuestro—; la r9 la materializó con los bloques literales y la r11 la volvió **ejecutable**. Las reglas documentadas se satisfacen **por construcción**, verificadas sobre los bloques y registradas con su fuente | **el validador de §Enfoque·«El verificador de plantillas», corrido**: un único programa que exige exactamente un bloque canónico por archivo, compara byte a byte, rechaza lo que no sea archivo regular, parsea y verifica el inventario exacto del directorio. Evidencia de cierre = su camino positivo **más los casos negativos publicados en la tabla de esa sección**, cada uno reproducible con el procedimiento que la tabla declara |
| C7 | **Las dos referencias del 13 son links que resuelven**, y no queda ninguna marca de «pendiente para el 14» en el README | inspección de los dos puntos + chequeo de destinos |
| C8 | **Cero link roto** en el conjunto completo — `README.md`, `CONTRIBUTING.md`, `docs/metrics.md`, `docs/install.md` | chequeo mecánico de todo destino relativo y de toda ancla interna contra los encabezados reales |
| C9 | **Cero afirmación no verificable**: toda oración de `CONTRIBUTING.md` y `docs/metrics.md` cae en una de las tres clases del contrato editorial (hecho derivable con su comando · limitación declarada · opinión marcada) | pasada por oración, registrada en el Review log |
| C10 | `CONTRIBUTING.md` declara **qué está fuera de alcance hoy** incluyendo el aviso MIT como **incumplimiento pendiente**, no como cumplimiento parcial | lectura literal |
| C11 | Los **tres comandos de GitHub** están escritos pegables sin editar, con herramienta, sintaxis y precondiciones declaradas y cero huecos. Sintaxis y completitud se verifican **offline**: cada flag existe en `gh repo edit --help`, cada valor está presente, ningún hueco | inspección contra la salida de `--help`, sin red |
| **C11b** | **No-ejecución**: ninguno de los tres se corrió contra el remoto | **Invariante operativa del pipeline, no evidencia derivable del commit** — y rotularla como prueba mecánica era una afirmación más ancha que su evidencia (hallazgo de la r1): un push no deja «commits de push», `origin/main..main` no tiene baseline versionado y no dice nada de topics ni homepage, y el repo no registra qué invocaciones de `gh` ocurrieron. Lo que sí se puede asentar, y es lo que se asienta: el registro explícito de que la unidad no las ejecutó, con las únicas invocaciones de `gh` declaradas (`--help`), verificable por el padre contra el ledger y por el humano contra el estado del repo remoto cuando vaya a correrlos |
| C12 | **Alcance, auditado por commit y no por diff agregado** (§«El alcance se audita por commit»): para cada commit de `2985447..HEAD`, si su SHA está en `AUTORIZADOS` toca solo el ledger y/o `docs/STATUS.md`; si no está, toca solo la lista cerrada de §Alcance, que **no** incluye el ledger. Cero cambios en método, skills, instalador, scripts, tests o remoto | recorrido de `git rev-list 2985447..HEAD`, y por cada SHA `git show --name-only --format= <sha>` contra la lista que le corresponde según esté o no en `AUTORIZADOS`. Un solo commit fuera de su lista falla el criterio. **El diff agregado no se usa**: aplanar dos autores con permisos distintos es lo que volvía el criterio autocontradictorio |
| C13 | **La inconsistencia del corte quedó resuelta por escrito**, con la razón contractual y no por preferencia | §«La inconsistencia entre docs», presente y citada desde el informe si corresponde |
| C14 | No-regresión: `tests/lint.sh`, `tests/loop.sh` y `tests/install.sh` limpios | corrida de las tres suites |
| **C15** | **Especificación literal completa, y completitud contra los artefactos.** (i) §Enfoque·«La especificación literal» **contiene los tres archivos enteros**, con todos sus valores — es la referencia de C6, y la r9 encontró que yo la prometía sin haberla escrito, que es el defecto que C15 existe para atrapar ocurriendo dentro de C15. **No se enumeran las claves omitidas**: los bloques son la autoridad y lo que no está en ellos no está; se conserva una sola omisión declarada —`labels`— porque necesita justificación local (r11). (ii) Existen **y entregan lo diseñado**: los **ocho** componentes del informe de §Enfoque·`docs/metrics.md`; los **cuatro** bloques de `CONTRIBUTING.md`; los campos `F1–F7` y `G1–G5` contrastados en su **tupla completa** contra los bloques canónicos; y **el idioma**: `docs/metrics.md`, `CONTRIBUTING.md` y `.github/` en **inglés** | recorrido de las listas cerradas **localizando cada elemento en el archivo final** y comparando la tupla entera. Para los YAML el contraste lo hace C6 por byte, que es más fuerte que cualquier recorrido. Se registra el locator de cada fila. *Que la lista esté escrita en esta bajada no verifica que esté implementada* |

## Riesgos

1. **La regla de fuente única es interpretable, y una regla interpretable churnea.** Es el riesgo más probable de esta unidad. Mitigación: la línea está **fijada por escrito antes de implementar** (§«Fuente única»), con la clase incluida, la clase excluida y el chequeo mecánico que la aplica. Si el reviewer no acepta la línea, se discute la línea una vez — no cifra por cifra.
2. **Contadores móviles reapareciendo en prosa.** Es la causa de las dos rachas de la unidad 13. Mitigación: la regla adoptada arriba, aplicada también a este doc; donde hace falta un número que se mueve, va el comando.
3. **YAML que GitHub rechaza y nosotros no vemos.** El riesgo real no es que GitHub calle —la fuente dice que los errores pueden aparecer «*when creating, saving, or viewing issue forms*»—, sino que **nosotros no llegamos a verlos**: mirarlos exige que el archivo esté en el remoto, y esta unidad tiene prohibido pushear. Ésa es la asimetría, y la afirmación anterior («no avisa, simplemente no aparece») era una generalización sobre GitHub que la fuente no sostiene — otra premisa externa, corregida en la r7. Mitigación parcial y declarada como parcial: C6 valida con un parser real **y** verifica conformidad con la especificación literal de C15, mientras las reglas documentadas se satisfacen por construcción con su elección registrada (§Enfoque). El validador de GitHub sigue siendo la autoridad final, y **puede tener reglas que su documentación no publica** — eso no se descarta desde acá. El riesgo se reduce, no se elimina, y el criterio lo dice. *(Las menciones de rangos viejos de invariantes dentro del Review log se conservan: describen el estado de su ronda.)*
4. **Tentación de correr los comandos de GitHub** —están escritos, verificados y a un `Enter` de distancia—. Mitigación: el corte está declarado como consecuencia, y C11b **no finge** que la no-ejecución sea demostrable desde el commit: es una invariante operativa que se sostiene por el contrato del pipeline y se asienta como registro, no como prueba. Prometer una prueba mecánica que no existe habría sido peor que no prometer nada — daba una garantía falsa exactamente donde importa.
5. **El corte envejece mientras se trabaja.** Las rondas de esta misma unidad entran al `rounds-log`. Mitigación: es exactamente lo que el corte neutraliza; la consecuencia (el snapshot no incluye las rondas de los features 13 y 14) se **publica**.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Sigue siendo una línea a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.
7. **Ampliar la edición del README.** El contrato dice «activar dos referencias», no «revisar la vidriera». Mitigación: C7 acota, y ante una tercera cosa que parezca necesaria se registra y se pregunta en vez de decidir solo.
8. **«Todo lo publicado es correcto» no es «está entregado lo diseñado».** Riesgo que la r4 encontró y que no estaba en esta lista: catorce criterios de correctitud dejaban pasar artefactos semánticamente incompletos, porque ninguno miraba la ausencia. Es **el mismo riesgo 7 de la unidad `13`**, que ahí costó agregar cuatro criterios en su r1. Mitigación: C15, contra cuatro listas cerradas y con locator en el artefacto final — no contra el criterio de quien revisa, y no contra la lista escrita en esta bajada.

## Review log

### r14 (base `6ec4b48`, HEAD `511c803`) — CHANGES_REQUESTED · **4 bloqueantes, cero preferencias**

**El harness aguantó el ataque, y ésa es la primera evidencia positiva de la unidad.** Codex lo atacó a pedido mío y reporta: «*extraído literalmente devuelve `VERIFY: OK`, y rechaza bloque no compilable, opener duplicado y directorio-symlink*» — incluidos dos ataques que yo no había corrido. **La clase «lo que corro puede diferir de lo que publico» quedó cerrada**, que es lo que sostiene el diagnóstico de convergencia frente a los dos anteriores, que se apoyaban en que los puntos bajaban.

Los cuatro puntos nuevos son de **otra forma**: no verificadores que fallan sobre sí mismos, sino **verificación cuyo alcance no cubría lo que decía cubrir**.

1. **C12 usaba una abreviatura configurable como identidad.** `AUTORIZADOS` tenía SHA de siete caracteres y la identidad salía de `git rev-parse --short`, que depende de `core.abbrev`. Reproducido con `core.abbrev=12`: los once autorizados pasan a doce caracteres, ninguno coincide, y **C12 falla sobre un rango válido**. Más el riesgo de colisión de prefijo. Cerrado comparando los **SHA completos** que produce `rev-list`; la abreviatura queda solo para los mensajes. Verificado en las dos versiones: con `core.abbrev=12` la anterior falla y la nueva pasa.
2. **La edición «acotada» del README no estaba verificada por nada.** `README.md` está en la allowlist de C12, así que una **reescritura arbitraria** devolvía `C12 PASA` —Codex lo reprodujo—, y C7 solo exigía los dos links. Cerrado convirtiendo C7 en un **diff cerrado**: las líneas quitadas y las agregadas deben ser exactamente las declaradas, y los dos conjuntos se derivaron **simulando la edición en un worktree descartable**, no escribiéndolos a mano. Probado en los dos sentidos: acepta la edición prevista exacta y **rechaza esa misma edición más una sola línea de prosa cambiada**.
3. **El barrido del síntoma «symlink» había quedado limitado a los YAML.** Codex creó el snapshot de métricas como enlace: git lo registró con modo `120000`, las lecturas siguieron el enlace y C12 aprobó. **Es exactamente el barrido de síntoma que el padre me había enseñado a hacer dos rondas antes y que no hice**: cerré la clase dentro de `.github/` y no me pregunté qué otros entregables tenían la misma superficie. Cerrado exigiendo modo `100644` a **todos** los paths de §Alcance vía `git ls-files -s`.
4. **La corrección del ledger conserva el defecto denunciado** —«cada corte lleva su desenlace» sigue siendo universal sobre un conjunto creciente— y su comando mezcla dominios: devuelve también el corte que fue **por indisponibilidad y no por deadlock**. Es del padre y no se toca.

### r13 (base `6ec4b48`, HEAD `6ff155c`) — CHANGES_REQUESTED · **5 bloqueantes, cero preferencias**

Volví a pedir ojo adversarial sobre los dos verificadores corregidos. **No volvieron limpios, y es el mismo camino: verificador que falla abierto por una vía no probada.** Pero el primero es de otro orden, porque **invalidó mi verificación misma**.

1. **El bloque Ruby publicado no compilaba, y yo había afirmado haberlo corrido «tal como se publica».** El programa contiene la cadena ` ```yaml ` dentro de su propio regex, así que **mi extractor cortaba en esa línea** — justo al final del programa nuevo— y devolvía algo válido, mientras el bloque publicado arrastraba una **cola huérfana** del validador anterior y no compilaba. La verificación coincidía con lo que yo quería publicar, no con lo publicado. Cerrado en la raíz: **fence de cuatro backticks** (que el feature 13 ya usaba por esta misma razón) y un **harness publicado** que exige exactamente un bloque, corta con el fence largo y comprueba `ruby -c` **antes** de correr.
2. **El validador aceptaba que el propio directorio fuera un symlink.** Yo hacía `lstat` de los hijos pero `Dir.exist?`/`Dir.children` **siguen el enlace del directorio**, así que un `ISSUE_TEMPLATE` que fuera enlace a una carpeta externa con los tres archivos daba `VERIFY: OK`. Cerrado con `File.lstat(dir)` y su negativo corrido.
3. **C12 rechazaba el alcance legítimo y ocultaba renames prohibidos.** La allowlist del hijo tenía solo los tres docs internos, así que **el primer commit de la implementación —el que agrega `CONTRIBUTING.md`— habría fallado el criterio**: literalmente impedía empezar. Y con detección de renames activa, mover `scripts/awake.sh` a `CONTRIBUTING.md` mostraba **solo el destino permitido** — reproducido: sin `--no-renames` sale `CONTRIBUTING.md`; con `--no-renames` salen los dos. Cerrado con todos los paths finales de §Alcance y `--no-renames`.
4. **Dos conteos desincronizados** («siete casos negativos» contra una tabla de nueve). Retirados de la sección vigente y de STATUS; se conservan solo donde son historia anclada a su ronda.
5. **Otra universal viva en el `## Cierre` del ledger** —«ninguno terminó la corrida»—, que vuelve a ampliar su universo con cada corte nuevo. Es del padre y no se toca.

**Dos defectos propios encontrados al corregir, y los dos de la misma forma que el punto 1**: mi allowlist multi-línea no matcheaba con `grep -qxF` porque tres paths compartían la primera línea, y **mi prueba negativa devolvía el `rc` de `tail` en vez del script** — el fallo abierto del pipe, otra vez, ahora en el arnés de prueba.

### r12 (base `6ec4b48`, HEAD `8d97931`) — CHANGES_REQUESTED · **4 bloqueantes, cero preferencias** · **el ojo adversarial sobre los verificadores nuevos dio resultado**

Le pedí explícitamente que atacara los dos verificadores recién publicados, por ser la superficie más fresca. **Encontró que los dos fallaban abierto**, cada uno por un camino que yo no había probado. La respuesta a «¿el andamiaje quedó cerrado?» es **no, seguía produciendo** — y por eso valía preguntarlo.

1. **C12 fallaba abierto ante errores de git.** Si `git rev-list` falla, el loop procesa **cero** commits y termina en `C12 PASA`; si cada `git show` falla, las sustituciones quedan vacías y también aprueba. Codex lo reprodujo: rango inválido y `git show --bad-option` imprimen `fatal` y **devuelven `rc=0`**. Cerrado capturando y comprobando el rc de `git rev-list`, de cada `git rev-parse` y de cada `git show`, más el rechazo de un rango vacío y de un commit sin paths. **Dos negativos nuevos corridos**: `rev-list` roto y `git show` roto, los dos `rc=1`.
2. **El validador aceptaba symlinks**, y éste sí permitía aprobar un artefacto defectuoso: `Dir.children`, `File.readable?` y `File.read` **siguen enlaces**, así que un `config.yml` que fuera symlink a un archivo externo con los bytes canónicos daba `VERIFY: OK`. Git versionaría el enlace, no el YAML. Cerrado con `File.lstat` y rechazo de todo lo que no sea archivo regular; **dos negativos nuevos corridos**: symlink y directorio.
3. **C6 y C15 conservaban los mecanismos que la ronda anterior decía haber retirado** — C6 seguía prescribiendo el viejo `diff` y las «mutaciones por sitio», y C15 seguía exigiendo «las claves opcionales omitidas declaradas», contradiciendo la decisión de no enumerarlas tomada en la misma ronda. **Es el hermano que no barrí**: cambié las secciones y no los criterios que las citaban. Ambas filas actualizadas al mecanismo vigente, y la evidencia de cierre pasa a ser el positivo más los negativos publicados, con su procedimiento de reproducción.
4. **El desempate nuevo dejó dos falsedades sincronizadas**: el ledger afirma que todos los cortes se resolvieron con «a)» cuando el último fue «c)» —esa mitad es del padre—, y STATUS y este doc llamaban «tercero» al desempate «c)» cuando el ledger ya tenía asignado ese ordinal al «a)» anterior. **Yo llamaba «tercer desempate» a dos eventos distintos.** Corregido dejando de numerarlos: se identifican por **letra y SHA**, porque un ordinal es un contador que el proceso mueve y basta un evento no contado para que toda la numeración quede mal.

**Los dos scripts quedaron verificados corriéndolos tal como se publican** —extraídos del propio doc, no de mi copia de trabajo—, con su camino positivo y sus negativos. Es la disciplina que el padre usó para el comando del ledger, aplicada a código que yo publico.

### r11 (base `6ec4b48`, HEAD `8c941ad`) — CHANGES_REQUESTED · **5 puntos, cero preferencias** · **segundo corte por tope** → desempate humano «c)»

Codex declaró **sólido el contenido canónico de los YAML** frente a la documentación pública. Lo que no cerraba era **la maquinaria alrededor**, y los cinco puntos tienen un nombre que esta unidad ya había acuñado: **mecanismo declarado que no ejecuta**. El humano eligió «c)» — reanudar con el alcance intacto, sin recortes, habiendo el padre recomendado cerrar sin la unidad y ofrecido recortar el andamiaje.

1. **El comparador publicado no era ejecutable**: invocaba un `extraer_bloque` inexistente, y además `diff <(extractor) archivo` **falla abierto respecto del extractor** —uno que imprime los bytes correctos y sale con `rc=1` deja a `diff` devolver `0`—. Reemplazado por **un validador Ruby único, real y corrido**, con camino positivo y **siete casos negativos**, todos ejecutados.
2. **El chequeo fail-closed de C12 estaba declarado pero no publicado**: el procedimiento del doc solo corría `git show`, sin comparar contra `AUTORIZADOS`, sin allowlists, sin flag, terminando siempre en `0`. Materializado, corrido, y con **prueba negativa corrida**.
3. **C6/C15 no exigían el inventario completo del directorio**: un cuarto `.github/ISSUE_TEMPLATE/extra.yml` quedaba dentro del alcance permitido y ningún `diff` lo miraba. El validador lo cubre, y de paso vuelve mecánica la unicidad de `name` entre todas las plantillas.
4. **Hermano del contador móvil** en STATUS («Los tres son del mismo bloque»), retirado.
5. **La lista de «claves opcionales omitidas» se presentaba como completa y no lo era.** La salida coherente con la inversión no es completarla sino **dejar de enumerar la spec ajena**: los bloques literales son la autoridad, y se conserva una sola omisión —`labels`— porque necesita justificación local.

**El tercero de la clase, cerrado en la misma ronda.** El padre observó que los puntos 1 y 2 eran ambos «mecanismo declarado que no ejecuta» y sugirió buscar un tercero antes de que apareciera solo. Lo había: **la tabla de «familias de mutación»** de los fixtures —descritas en prosa, sin generador—. Queda disuelta: las mutaciones son ahora los siete casos negativos **ejecutados** del validador.

**Y otra vez, correr encontró lo que leer no**: el Ruby de sistema lee en **US-ASCII** por defecto, así que el validador explotaba con `invalid byte sequence` sobre los guiones largos del doc antes de comparar un solo byte. Es la tercera aparición del mismo fenómeno en la unidad.

### r9 (base `6ec4b48`, HEAD `3f270ff`) — CHANGES_REQUESTED · **4 bloqueantes, cero preferencias** · la ronda que materializó la inversión

**La respuesta a la pregunta que hice, que era lo que más importaba de la ronda**: «*La inversión de C6 es conceptualmente válida, pero todavía no está materializada*». O sea que **el corte quedó bien puesto** —no hay un camino estructural por el que un archivo conforme a C15 sea rechazado—, y el límite residual que declaré es el correcto: «*aun con todo esto, la conformidad local no prueba aceptación por GitHub; su esquema sigue en public preview y GitHub conserva la autoridad final*». Lo que faltaba no era el diseño sino su realización.

1. **C15 prometía una especificación literal que no existía.** Las tablas fijaban propósito, tipo y requiredness, y **ningún valor**: ni `name`, ni `id`, ni `label`, ni los textos, ni las opciones, ni `contact_links`. Sin eso C6 no tenía contra qué comparar. **Es el defecto que C15 fue creado para atrapar, ocurriendo dentro de C15** —«que la lista esté escrita no verifica que esté implementada», aplicado a la lista misma—. Materializado: §«La especificación literal» trae **los tres archivos enteros**, más las **claves opcionales omitidas declaradas**, porque «completa» tiene que incluir lo que no está.
2. **«Coincide» necesitaba un comparador que preservara la literalidad**, y Codex lo reprodujo: parsear y comparar objetos **no detecta claves duplicadas** — `name: injected` seguido de `name: expected` da el mismo objeto que `name: expected`. Un archivo con una clave de más pasaba. Reemplazado por **`diff` byte a byte** contra el bloque canónico, más el parseo como chequeo independiente. Los dos prueban cosas distintas y los dos hacen falta; y la política sobre aliases, documentos múltiples y claves repetidas deja de necesitar redacción, porque todos son diferencias de bytes.
3. **Faltaba una regla oficial**: cada `name` debe ser **único entre todas las plantillas del repo**, incluidas las Markdown. Agregada a la tabla por construcción, con los dos literales distintos y la constatación de que no hay otras plantillas.
4. **Reaparecieron contadores móviles**: «Cinco veces» cuando la tabla ya enumeraba seis, «Las tres formas», y «Los tres pendientes del ledger» en STATUS. Los tres reemplazados por formulaciones sin cantidad, conservando las listas como fuente.

**Un defecto real que encontró el chequeo corrido, y que el razonado no habría visto**: al validar los bloques recién escritos, **el primero no parseaba**. La `description` del campo `final-line` contenía `fin: rc=` sin comillas, y los dos puntos seguidos de espacio hacían que YAML lo leyera como un mapa anidado. Es la misma disciplina con que el padre verificó el comando del ledger —correrlo, no razonarlo— dando el mismo tipo de resultado. Corregido, y las reglas documentadas quedaron **verificadas mecánicamente sobre los bloques**: longitudes de `name`, unicidad de labels e `id`, charset, ausencia de `None`, ausencia de términos prohibidos, tipos de `options` y claves de `config.yml`.

### r8 (base `6ec4b48`, HEAD `03947c2`) — CHANGES_REQUESTED · **4 bloqueantes, cero preferencias** · **la ronda que obligó a invertir el criterio**

1. **El desacuerdo sobre `name` se resolvió contra mí, y con razón.** La documentación lo dice textual: «*The `name` field must be more than 3 characters. If it's not, the template won't be shown when creating an issue*». Yo había consultado esa misma página en la r7, no lo encontré, y publiqué **«buscada y no encontrada»** como si fuera un hecho establecido. **El criterio que invoqué sigue siendo correcto** —encodear una restricción sin fuente es el mismo defecto con la autoridad cambiada de lado— pero lo apliqué sobre una premisa falsa: *una búsqueda fallida no distingue «no existe» de «no lo encontré»*, y la carga de esa duda era mía. Corregido en el barrido, junto con la fila simétrica: la unicidad de `name` entre plantillas queda registrada como **no documentada en las páginas que consulté**, que es lo que sí puedo afirmar.

2. **La «frontera única» tampoco enumeraba todas las causas** — faltaban la unicidad de `label` entre campos de entrada y entre opciones de un `checkboxes` frente a otros inputs, los labels «demasiado similares», los términos prohibidos en `label` y `None` como opción reservada de `dropdown`. Todas verificadas y todas reales.

3. **La biyección era entre identificadores, no entre sitios ejecutados.** `comm` daba conjuntos iguales mientras invariantes compuestas tenían un solo fixture: E1 probaba una de tres claves, E6b un tipo de cuatro, E9c un string de seis. Un validador que ignorara `label`, `value`, `about` o `url` pasaba la matriz entera. La clave de comparación tenía que ser **el sitio**, no la invariante.

4. **STATUS volvió a desincronizarse** —conservaba la r6 como último veredicto y la racha en 1 cuando era 2— y **volvió a publicar un contador móvil** («cinco defectos»). Corregido. La cuarta parte del punto es del ledger y se le pasó al padre: su `grep` de enumeración matchea **su propia línea**, así que devuelve un resultado de más.

**Lo que esta ronda cambió de fondo, y es la decisión más importante de la bajada.** Los puntos 1 y 2 son la cuarta ronda consecutiva que encuentra **causas documentadas nuevas**. Eso dejó de ser información sobre mi prolijidad y pasó a ser información sobre el criterio: **C6 tenía como condición de cierre «haber agotado la especificación de GitHub», que es un conjunto abierto y ajeno.** No cierra nunca, y ninguna cantidad de barridos lo cierra — que es exactamente lo que yo mismo había concluido en la r7 sin ver que mi propio criterio era el caso.

La salida es **invertir la carga**: C6 deja de preguntar *«¿viola alguna regla de GitHub?»* y pasa a *«¿coincide con la especificación literal que fija C15?»*. El conjunto pasa a ser cerrado y nuestro. Las reglas documentadas siguen valiendo y se satisfacen **por construcción**, con cada elección registrada contra su regla — y eso disuelve además el punto 3, porque los fixtures pasan a ser **mutaciones por sitio** de los archivos reales, derivables de la especificación en vez de declarados.

No es una rebaja: fijar el contenido literal completo es **más** exigente que chequear invariantes, porque no deja ningún valor sin decidir.

### r7 (base `6ec4b48`, HEAD `7903df2`) — CHANGES_REQUESTED · **3 bloqueantes, cero preferencias**

La corrección de `checkboxes`, el retiro de `upload` y C12 quedaron bien. **El pedido adversarial sobre el barrido dio resultado, y ésa es la información más útil de la ronda**: la clase de «premisa externa sin fuente» **no estaba agotada** — el barrido de la r6 se había dejado cuatro afuera.

1. **Cuatro causas documentadas que ninguna invariante cubría**, todas verificadas ahora contra la fuente y agregadas: el **charset de `id`** (E8b — «`'id' can only contain numbers, letters, -, _`»), los **strings vacíos o solo-whitespace** (E13), las **claves no permitidas** dentro de un elemento (E14) y dentro de `attributes` (neutralizada por C15). Más dos hermanos: el riesgo 3 afirmaba que GitHub «no avisa», y la fuente dice que los errores aparecen «*when creating, saving, or viewing*» — la limitación es **nuestra**, no de la herramienta, y ahora lo dice así; y C6 conservaba «stock de macOS» para `ruby`, contradiciendo el límite de entorno que el propio barrido declara.

   **El único punto de todo el ciclo donde no acepto sin más**: la r7 afirma que GitHub exige más de tres caracteres para `name`. Fui a la fuente y **no pude sostenerlo** — marca `name` como requerido y no documenta longitud mínima; lo que sí documenta es el rechazo de strings vacíos o solo-whitespace, que es lo que codifica E13. Codifico lo respaldado y no el umbral, porque **encodear una restricción sin fuente es el mismo defecto con la autoridad cambiada de lado**. El contraejemplo queda cerrado igual por la vía que la propia r7 ofreció: C15 fija los valores literales.

2. **La matriz seguía sin cubrir cada condición que prometía.** E12 exigía `label` string no vacío y solo probaba su ausencia; E7 exigía lista y no probaba `options: foo`; E9 prometía tipos genéricamente sin caso para `description: true`. Y C6 y el riesgo 3 **todavía decían «por rama»** después de que la r6 declarara haber reemplazado esa promesa. Resuelto **atomizando** las invariantes (`E3a/b`, `E4a/b`, `E6a/b`, `E7a–d`, `E8a/b`, `E9a–c`, `E11a–c`, `E12a–c`) y exigiendo que la tabla condición→fixture sea **biyectiva** — propiedad chequeable comparando identificadores, no argumentable.

   De acá salió también la **frontera única**, que es mejor que seguir agregando invariantes de a una: *para cada causa documentada, o hay invariante con fixture, o C15 fija el valor que la vuelve imposible*.

3. **La reparación volvió a publicar contadores móviles.** STATUS duplicaba `AUTORIZADOS` como «los tres SHA» —justo después de declarar que fuera la única lista— y publicaba el tamaño del barrido, que este mismo feedback amplió. Los dos reemplazados por referencia. **La tercera instancia era del ledger**: el `## Cierre` quedó diciendo «tres cortes» con el pipeline abierto. No se tocó; se le pasó al padre, que commiteó `68a2fe5` y **barrió el archivo entero**. La ironía es del mismo orden que las dos mías: el padre escribió ese contador **en el commit con que arreglaba otra falsedad del mismo bloque**, mientras aplicaba la regla al resto del archivo.

   **Los tres casos —dos míos, uno suyo— tienen la misma forma**: el defecto aparece dentro del acto de corregirlo. No es descuido de ninguno de los dos; es que corregir *es* escribir, y escribir es donde el defecto nace. Por eso la salida no es más cuidado sino la frontera única: mover la garantía del autor al mecanismo.

**Balance de la ronda, que vale anotar**: los tres puntos son la misma clase que el ciclo persigue, y **los tres cayeron sobre correcciones de la ronda anterior** — pero ninguno reabre algo cerrado y los tres traen contraejemplo concreto. Lo que cambió respecto de mi lectura de la r4 es que ya no sostengo que la clase se agote con un barrido: se agota cuando el mecanismo la vuelve imposible, y eso es lo que intenta la frontera única.

### r6 (base `6ec4b48`, HEAD `52850e3`) — CHANGES_REQUESTED · **2 bloqueantes, cero preferencias**, más un pendiente del ledger que es del padre

**C15 quedó cerrado correctamente**, y Codex no dejó preferencias opcionales. Los dos bloqueantes son de la misma clase que este ciclo viene persiguiendo, y los dos ocurrieron **dentro del mecanismo que existe para detectarlos** — que es lo que los vuelve interesantes y no solo molestos.

1. **Corregí una premisa sin fuente introduciendo otra.** Al traer el esquema oficial glosé el `validations.required` de `checkboxes` como «bloquea si falta selección — no si falta marcar todas». La fuente **no dice eso**: dice que bloquea hasta que el elemento esté **completo**, y mi versión era una interpretación más específica que el documento no establece. Retirada; queda el texto documentado. No afecta el diseño, porque **ningún `checkboxes` de estos formularios usa `validations.required`**. De arrastre: E4 había sumado `upload` sin que E6 lo contemplara («los otros cuatro» cuando ya eran cinco) y **sin caso positivo**, así que un validador que rechazara `upload` siempre pasaba igual todos los fixtures; y la promesa «un fixture por rama» no tenía caso para `dropdown` con `options` vacías, entre otros. Resuelto **retirando `upload`** —la allowlist queda acotada y declarada a los cinco tipos que estos formularios usan— y reescribiendo la matriz de fixtures para que enumere **cada condición**, con la promesa enunciada contra la tabla y no al revés.
2. **La auditoría publicada de C12 nació desincronizada.** El párrafo decía «los cinco commits del hijo» con su lista, y el commit que lo escribía ya era el sexto. Es la **regla de contadores móviles violada dentro del párrafo que demuestra el mecanismo que la hace cumplir** — la forma más pura del defecto en toda la unidad, y la escribí yo tres rondas después de adoptar la regla. Reemplazado por procedimiento + desenlace fail-closed, con `AUTORIZADOS` como única lista, que es cerrada por construcción porque la escribe el padre al commitear.
3. **Pendiente del ledger, que es territorio del padre y no lo toqué**: el `## Cierre` decía que la corrida se reanuda en la unidad `13`, cuando el último evento y STATUS dicen `14`. Se lo pasé en vez de corregirlo, frenando el lanzamiento de la r7 —una ronda con un defecto conocido adentro tiene el desenlace cantado—, y el padre commiteó `e5ee8f2` y devolvió el SHA en el acto. **El defecto era peor de lo que yo había señalado**: el bloque no solo nombraba la unidad equivocada, sino que **describía el primer corte como si fuera el único cuando hubo tres**. Quedó con los tres registrados y el texto anterior tachado y conservado. `e5ee8f2` entra a `AUTORIZADOS` y la auditoría por commit se re-corrió: pasa.

   *(Segunda vez que el protocolo padre-hijo sobre el ledger se ejerce en esta unidad, y la primera en que lo dispara un hallazgo de review. Vale por lo mismo que C12: la frontera de territorios no es ceremonia — el hijo detectó una falsedad que no podía arreglar, y la vía para arreglarla existía.)*

**Barrido de premisas externas, hecho de una vez** (§«Barrido de premisas sobre sistemas externos»): a pedido del padre, en vez de esperar a que aparezcan de a una. Nueve premisas inventariadas — ocho verificadas contra su fuente, y una **retirada** por no ser verificable ni necesaria. De ahí salieron además los textos de error exactos que GitHub publica para siete de las invariantes, que ahora el validador puede usar como expectativa.

### r5 (base `6ec4b48`, HEAD `fdd2f41`) — CHANGES_REQUESTED · **2 bloqueantes, cero preferencias** · **corte por tope** → desempate humano «a)»

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
