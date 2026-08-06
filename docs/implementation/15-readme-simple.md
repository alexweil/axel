# Feature 15 — README simple: reescritura según la estructura de cinco preguntas

> Bajada fina. Entrada del plan: [../IMPLEMENTATION.md](../IMPLEMENTATION.md) §«15 — README simple». Diseño que implementa (**cerrado, no se rediscute**): [../design/public-surface.md](../design/public-surface.md) §«Estructura del README».

## Procedencia y autorización

- **Unidad `feature` del pipeline `/build` del 2026-08-05** — ledger: [pipeline-2026-08-05.md](pipeline-2026-08-05.md). No hubo gate de arranque individual: la autorización es la **global del gate de pipeline**, dada el **2026-08-05** («dale, autorizado», sin ajustes de alcance).
- **Pedido del humano que originó el pipeline** (literal breve del bloque Gate; el texto completo vive ahí y en la extensión 2026-08-05 del plan): «Revisa el README y hacelo FACIL. El usuario debe entender en un parrafo para que sirve, y por qué. […] deberia ser simple, deberia ser: / Para que sirve? Por Que lo usaria? / Como lo instalo? / Como lo uso? / Lo esencial».
- **Correcciones de alcance del gate que tocan este feature**: ninguna — el gate se autorizó sin ajustes. Siguen mandando las dos restricciones de la ruta: el delta entra como **un** feature, y **GitHub no se toca** (push, topics y homepage siguen siendo del humano — pendiente inmediato de [../STATUS.md](../STATUS.md)).
- **Base del feature**: `87ee282` (SHA inicio registrado en el ledger). El `README.md` bajo reescritura es el que entregó el feature 13 y activó el 14; sus 179 líneas al arranque son el **baseline** contra el que se verifica «cero pérdida».

## Alcance

Reescribir `README.md` de punta a punta —en inglés, por la política de idioma vigente— para que conteste las preguntas del lector en el orden en que se las hace, y mudar las dos piezas que el diseño saca del README a sus destinos nombrados.

**Dentro del alcance** (cinco archivos):

| Archivo | Qué se le hace |
|---|---|
| `README.md` | reescrito completo: párrafo de apertura + cuatro bloques |
| `docs/session.md` | **nuevo** — recibe entero el render de la sesión (decisión D2) |
| `docs/install.md` | recibe el diagrama ASCII de «How it works» (decisión D6); nada más se le toca |
| `docs/DESIGN.md` | se sustituye el placeholder de path del doc del render por el path real (decisión D7) |
| `docs/design/public-surface.md` | ídem, **solo** en la fila de inventario de la tabla de idioma (decisión D7) |

Más el bookkeeping obligatorio: este doc, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` y el ledger del pipeline.

**Fuera del alcance, explícito**: GitHub (push, topics, homepage); el método (`AGENTS.md` y su espejo en `templates/`) — la deuda normativa de idioma sigue declarada y sin resolver, y cerrarla acá sería ampliar en silencio un scope que el humano fijó; las skills, el instalador, los scripts y las suites; `docs/metrics.md` (fuente única que este feature **cita**, no reescribe: si una cifra publicada no cierra contra el doc, se corrige la cita, no la fuente); `CONTRIBUTING.md`, `LICENSE` y `.github/`.

## Lo que el diseño ya fijó y esta bajada no rediscute

Copiado acá para que el loop de review tenga la vara a mano, no para reabrirlo: un párrafo de apertura y cuatro bloques en el orden de las preguntas; el test del párrafo de apertura (cero vocabulario interno, cero cifras, cero SHAs, autosuficiencia); las métricas fuera de la apertura con **mención única** dentro de «¿por qué lo usaría?»; el mapa de destinos completo de la tabla del diseño; sin pérdida operativa; política de idioma, contrato editorial, corte vidriera/manual, requisitos antes del comando y fuente única de cifras. Criterio de aceptación de la prosa: los cuatro puntos de §«Criterio de aceptación de la prosa».

## Decisiones de la bajada

### D1 — Títulos exactos en inglés de los cuatro bloques

```
## Why would I use it?
## How do I install it?
## How do I use it?
## The essentials
```

Los tres primeros son **la pregunta del lector, en su voz**, que es exactamente lo que la estructura nueva promete; el cuarto no es una pregunta porque no lo es en el pedido («Lo esencial»). Alternativa descartada: títulos nominales o imperativos (`Why use it` · `Install` · `Usage` · `Essentials`) — es la forma que tiene hoy el README y la que organiza **por temas**; volver a ella con contenido nuevo pierde la mitad del cambio, que es que el índice del doc sea el índice de las dudas.

El **párrafo de apertura no lleva título propio**: va inmediatamente bajo `# axel`, antes del primer `##`. Un encabezado «What is it?» le pondría al lector una etiqueta antes de la respuesta, y el diseño pide que el párrafo se sostenga solo.

### D2 — Path y título del doc del render de la sesión

**`docs/session.md`**, con título `# What a session actually looks like` (el mismo de la sección que se muda, que ya está probado como promesa y como ancla mental).

Criterio del nombre: la vidriera bajo `docs/` ya tiene una convención observable —`install.md` contesta «¿cómo lo hago andar?», `metrics.md` es «los números»—, sustantivo inglés en minúscula, una palabra. `session.md` cae en esa serie sin inventar una regla nueva. Alternativas descartadas:

- `docs/transcript.md` — **descartada por falsa**, y es la más importante de descartar: la decisión de diseño que produjo el contenido de ese doc dice literalmente que **no hay transcript de sesión que capturar** y que publicar un log con aspecto de reconstruido sería lo más dañino posible. Un archivo llamado `transcript.md` contradice en el nombre lo que el doc explica en la primera línea.
- `docs/what-a-session-looks-like.md` — el título es bueno, el path es largo y rompe la serie de una palabra.
- `docs/a-session.md` — artículo en un nombre de archivo; nada gana.

### D3 — La mención única de métricas, y cómo cita su corte

**La oración nombra el corte inline** (`b0bdf4d`) y linkea [`docs/metrics.md`](../metrics.md) como fuente de la derivación. La regla vigente del delta anterior —«ninguna cifra de la vidriera se publica sin su corte»— **no fue revertida** por el delta 2026-08-05: lo que ese delta movió es *dónde* aparecen las cifras, no si viajan con su corte. Delegar el corte al link publicaría en la vidriera cifras cuya fecha de foto vive solo detrás de un click, que es justo lo que la regla evita.

**Costo declarado**: un SHA vuelve al README. Es admisible porque la prohibición de SHAs es **del párrafo de apertura**, y esta mención vive en el segundo bloque con el contexto ya pagado. No se crea una segunda fuente: el README **cita** el corte y el valor; la derivación (comando, fuente, auditabilidad de cada fila) sigue viviendo entera en `docs/metrics.md`.

**Qué cifras entran** y con qué unidad en la misma oración, contra la tabla de `docs/metrics.md` §«The figures» al corte `b0bdf4d`: rondas registradas **88** (dichas «logged», porque el histórico completo es 123 y publicar 88 sin rótulo sería publicar una muestra como total), rechazos **59**, aprobados **29** con la cláusula de que son **hitos y no features**, y «ningún ciclo aprobado en su primera ronda» **nombrando la unidad ciclo** (18 de 18 registrados; el compuesto de 23 vive en `metrics.md`). El glosario de unidades **no** vuelve: queda a un link, en `docs/metrics.md` §«Three units, never mixed».

**Frontera de «mención única», declarada porque el criterio se verifica mecánicamente**: la regla rige las **cifras del loop** —la familia rondas / rechazos / aprobados / ciclos / medianas / peor caso, más commits, días y features al corte—, que es la que contesta la objeción del sello de goma. No cuentan como segunda mención los números que no salen de esa familia: los **dos** proveedores y las **dos** suscripciones de los requisitos, los **siete** comandos, y el calificador de alcance del dato externo («un repo, del mismo autor, una adopción»), que **el propio diseño exige** conservar en esa forma en su tabla de destinos. El dato externo entra **sin cifras derivadas** (no van los 185 commits, ni los 20 archivos instalados, ni los 8 mapeados): su función en el README es contestar «¿funciona fuera de axel?» con su alcance honesto, y los números de esa fila viven en `docs/metrics.md`.

### D4 — La compresión de «What this is not» dentro de «lo esencial»

«The essentials» queda con tres partes, en este orden:

1. **Qué es materialmente**, una o dos líneas: markdown y dos scripts de shell, sin dependencias ni nada que importar.
2. **`### What it is not`** — lista de **seis** ítems, **una línea cada uno**, uno por limitación declarada del README saliente: no es un framework · no es barato · no es autónomo · no está probado a escala · por debajo está en español · el reviewer no es un sello de goma. Compresión, no recorte: hoy son seis bullets de ~3 líneas, pasan a seis de una. El contrato editorial **no permite despublicar una limitación**, así que cada ítem tiene que conservar su sustancia, no su extensión — la verificación es la tabla V4 de abajo, limitación por limitación.
3. **Links** — la lista de punteros, que cierra el bloque y el doc.

El sexto ítem («no es un sello de goma») se conserva como limitación **sin repetir cifras**: su versión de hoy las repite, y la mención única vive en «¿por qué lo usaría?». La línea dice qué garantiza el reviewer y qué no, y remite.

### D5 — La forma de verificar «cero pérdida»

**Inventario caso por caso**, heredado de la vara del 13 y acotado a lo que este feature realmente mueve. El baseline es `README.md` al SHA de arranque `87ee282`. Tres niveles:

- **Nivel A — piezas mudadas, íntegras**: el render de la sesión y el diagrama ASCII se verifican **contra el texto**, no contra la intención: cada bloque citado, cada procedencia, cada SHA y cada link del render existen en `docs/session.md`; el diagrama entra en `docs/install.md` **carácter por carácter idéntico** al del baseline.
- **Nivel B — piezas conservadas o comprimidas**: tabla que enumera **cada sección del baseline** con su destino y con la evidencia de dónde sobrevive su sustancia. Una sección sin fila es un hueco; una fila sin evidencia localizable, también.
- **Nivel C — la regla operativa**: nada del **dominio operativo** queda documentado solo en el README. Se verifica en la dirección que importa: para cada afirmación operativa del README nuevo —instalación, uso, casos, problemas conocidos— existe su desarrollo en `docs/install.md`. El manual ya era el completo operativo y esta reescritura no le quita nada; el único agregado es el diagrama.

No se reconstruye el extractor de tokens del feature 13: aquel README **inauguraba** el manual y podía perder contenido que no existía en ningún otro lado. Acá el manual está entero y no se toca (salvo el agregado), así que el riesgo real es de las dos mudanzas y de las compresiones, que es exactamente lo que cubren A, B y C. Queda declarado como decisión, no como olvido.

### D6 — Dónde aterriza el diagrama en `docs/install.md`

Subsección nueva **`### How the commands chain`** al final de §«The commands in full», después de la tabla: el lector ve primero qué hace cada comando y después cómo se encadenan. Contiene el diagrama idéntico más una o dos líneas de contexto. No se muda con él la prosa de «Inside a feature» del README: esa sustancia —el ciclo hasta `APPROVED`, el tope de cinco rondas, el worktree snapshot— se reescribe en prosa llana dentro de «¿cómo lo uso?», como manda la tabla de destinos del diseño, y su fuente canónica sigue siendo [`docs/design/review-contract.md`](../design/review-contract.md).

### D7 — Los dos placeholders de path que este feature cierra

El diseño dejó el path del doc del render como decisión de esta bajada, y **dos inventarios** lo esperan con un placeholder:

- `docs/DESIGN.md`, fila de componentes: «el doc del render de la sesión (desde el delta 2026-08-05; su path lo fija la bajada del feature 15)» → se sustituye por el path real.
- `docs/design/public-surface.md`, tabla de §«Política de idioma», fila **Vidriera**: «el doc del render de la sesión (path: bajada del feature 15)» → ídem.

**Lo que NO se toca de esos dos docs**: cualquier otra línea. En particular quedan **intactas** las dos frases narrativas del diseño que dicen que el path lo decide esta bajada (la tabla de destinos de §«Estructura del README» y §«Lo que este delta no decide»): son afirmaciones **sobre lo que aquel delta delegó**, siguen siendo ciertas, y reescribirlas sería falsificar el registro de quién decidió qué. La sustitución se limita a las dos **filas de inventario**, donde un placeholder deja el inventario incompleto. Un inventario con un hueco envejece mal; una narración histórica correcta, no.

### D8 — Dónde queda el puntero para agentes

El camino «instalá axel siguiendo \<url\>» (feature 02) tiene hoy su procedimiento completo en `docs/install.md` §«For agents (Claude Code)», y el README lo nombra al cerrar §Install. En la estructura nueva **sigue nombrado**, dentro de «¿cómo lo instalo?», en la línea que apunta al manual: es un **puntero**, no un caso, así que respeta el corte vidriera/manual. Sin destino, el camino que diseñó el feature 02 quedaría sin entrada visible desde la vidriera, que es la pérdida que el nivel C busca impedir.

## Enfoque: en qué orden se hace

Pasos chicos, cada uno con su commit y su ronda de review cuando corresponda:

1. **Bajada fina** (este doc) → review hasta `APPROVED`.
2. **`docs/session.md`** — el render mudado íntegro, más el encabezado y la línea de contexto que necesita al quedar solo. Es la mudanza de mayor superficie y la que el nivel A verifica más duro.
3. **`docs/install.md`** — el diagrama en su subsección nueva.
4. **`README.md`** — la reescritura completa, que es el corazón del feature.
5. **Los dos placeholders de path** (D7) + el inventario de verificación (V1–V10) escrito en este doc con su evidencia.

Los pasos 2 y 3 van antes del 4 a propósito: cuando se escriba el README nuevo, los destinos de las mudanzas ya existen y sus links se pueden chequear de verdad en vez de prometerse.

## Criterios de cierre

Ninguno es «lo leí y me gustó»: cada uno dice con qué se comprueba. No hay harness para prosa, así que la evidencia es inspección declarada, y donde se puede, un comando.

| # | Criterio | Cómo se verifica |
|---|---|---|
| **C1** | **Estructura**: `README.md` tiene el párrafo de apertura sin título y exactamente los cuatro `##` de D1, en ese orden | listado de encabezados del archivo |
| **C2** | **Test del párrafo de apertura**, oración por oración: cero vocabulario interno (`round`, `milestone`, `cycle`, `gate`, `RECAP`, `ledger`), cero cifras, cero SHAs, y autosuficiencia | barrido mecánico del bloque (lista de términos + dígitos + patrón de SHA corto) **más** el juicio de autosuficiencia declarado oración por oración, que ningún grep decide |
| **C3** | **Mención única de métricas**: exactamente una en todo el README, con la unidad en la misma oración, con su corte y con `docs/metrics.md` como fuente | barrido de la familia de cifras del loop sobre el archivo entero; la frontera declarada en D3 se aplica explícitamente a cada match |
| **C4** | **Cifras correctas**: cada valor publicado coincide con `docs/metrics.md` §«The figures» al corte `b0bdf4d` | comparación fila por fila contra el doc de métricas |
| **C5** | **Cada pregunta se contesta dentro de su bloque**: el lector no necesita salir del README para saber si esto es para él | inspección declarada, bloque por bloque, nombrando qué contesta cada uno |
| **C6** | **Las seis objeciones** contestadas en el bloque que el diseño les asignó (costo y macOS → requisitos; sello de goma → mención única + «el reviewer ejecuta»; montón de markdown y todo en español → «lo esencial»; ¿funciona fuera de axel? → línea de inquirylab) | tabla objeción → bloque → línea |
| **C7** | **Nivel A**: el render está íntegro en `docs/session.md` (cada bloque citado, procedencia, SHA y link) y el diagrama está en `docs/install.md` **idéntico** al baseline | comparación de texto contra el baseline `87ee282` |
| **C8** | **Nivel B**: toda sección del baseline tiene fila en el inventario con destino y evidencia | tabla completa en este doc; cero secciones sin fila |
| **C9** | **Nivel C**: ninguna afirmación operativa del README nuevo carece de desarrollo en `docs/install.md` | recorrido de las afirmaciones operativas con su sección destino |
| **C10** | **Las seis limitaciones declaradas sobreviven en sustancia** dentro de «lo esencial» | tabla limitación → línea nueva → sustancia conservada |
| **C11** | **Cero link roto**: todo destino relativo y toda ancla interna de `README.md`, `docs/session.md` y `docs/install.md` resuelve | chequeo mecánico de destinos + derivación del slug de cada ancla contra los encabezados reales |
| **C12** | **Contrato editorial**: cada oración de la prosa nueva es hecho derivable, limitación declarada u opinión marcada | clasificación declarada; se reporta el conteo por clase y se nombran las opiniones marcadas |
| **C13** | **Idioma**: `README.md` y `docs/session.md` en inglés; este doc, el plan, STATUS y el ledger en español | inspección |
| **C14** | **Alcance**: el diff del feature toca solo los cinco archivos de la tabla de alcance más el bookkeeping (este doc, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`, el ledger) — cero cambios en método, skills, instalador, scripts, tests, `docs/metrics.md` o remoto | `git diff --stat` contra `87ee282`, con la lista de paths cerrada |
| **C15** | **Vara de tamaño**: el párrafo de apertura solo contesta «¿es esto para mí?», y llegar al final de «¿por qué lo usaría?» no exige más de una pantalla | declarado, con el tamaño resultante reportado como dato — **no** como criterio de líneas |
| **C16** | **Higiene**: `git diff --check` limpio y `tests/lint.sh` sigue en verde | comandos, con su salida |

## Riesgos

1. **La compresión despublica una limitación sin que se note.** Es el riesgo más caro: el contrato editorial prohíbe exactamente eso, y una línea comprimida «parece» conservar. Mitigación: C10 es una tabla explícita, limitación por limitación, y la sustancia se enuncia antes de comprimir.
2. **La mención única se multiplica sin querer.** Cualquier cifra suelta en otro bloque rompe C3, y el criterio es mecánico. Mitigación: la frontera de D3 está declarada por adelantado —qué familia cuenta y qué no— para que el barrido no se resuelva a ojo cuando aparezca un match.
3. **El párrafo de apertura sale genérico.** El riesgo de sacarle todo el vocabulario interno es escribir marketing vacío que no dice nada. Mitigación: el test exige que el lector pueda decir **qué es** y **por qué le importaría**; una frase que sobreviviría en el README de cualquier otra herramienta falla el test aunque no use ninguna palabra prohibida.
4. **Cifras que envejecen.** El README cita un corte fijo mientras el `rounds-log` sigue creciendo — este mismo feature agrega rondas. Mitigación: es exactamente para lo que existe la foto fechada; la cita nombra su corte y no promete estar viva.
5. **La mudanza del render pierde procedencia.** Al salir del README, los bloques quedan sin el contexto que los rodeaba. Mitigación: nivel A verifica cada procedencia y cada SHA, y el doc nuevo abre explicando por qué está renderizado desde el repo y no capturado de un chat.
6. **Alcance**: la tentación de arreglar de paso la deuda normativa de idioma o algún roce del instalador. Está fuera de la ruta autorizada y sería divergencia ⇒ corte. C14 lo vuelve mecánico.

## Review log

(vacío — se completa ronda por ronda)
