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

Más el bookkeeping obligatorio del hijo: este doc, `docs/IMPLEMENTATION.md` y `docs/STATUS.md`. **El ledger del pipeline no es del hijo**: lo escribe el padre —arranque, veredicto y cierre de cada unidad— y ningún commit de esta unidad puede tocarlo. La frontera se verifica en C14a/C14b, no se declara y ya.

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
2. **`### What it is not`** — lista de **seis** ítems, **una línea cada uno**. Seis ítems, pero **siete sustancias**: el diseño obliga a conservar costo, **lentitud**, no autónomo, no probado a escala, español por debajo y no framework, y el README saliente agrega la séptima (no es un sello de goma). La que se agrupa es «no es barato», que tiene que decir **las dos cosas en su línea** —dos suscripciones pagas *y* rondas medidas en decenas de minutos—: son costos de naturaleza distinta, el segundo es el que más gente descarta, y dejarlo implícito en «caro» lo despublica de hecho. Compresión, no recorte: hoy son seis bullets de ~3 líneas y pasan a seis de una; el contrato editorial **no permite despublicar una limitación**, así que cada ítem conserva su sustancia y no su extensión. La verificación es C10, que se recorre por **sustancia** y no por bullet.
3. **Links** — la lista de punteros, que cierra el bloque y el doc.

El sexto ítem («no es un sello de goma») se conserva como limitación **sin repetir cifras**: su versión de hoy las repite, y la mención única vive en «¿por qué lo usaría?». La línea dice qué garantiza el reviewer y qué no, y remite.

### D5 — La forma de verificar «cero pérdida»

**Inventario cerrado por pieza semántica**, derivado del baseline —`README.md` al SHA de arranque `87ee282`— y no de las secciones. «Una fila por sección» no sirve: una sección puede conservar una pieza y perder otras tres y la fila igual diría «conservada». Tres niveles:

- **Nivel A — la enumeración cerrada, por rangos de línea**. La unidad **no** es «la afirmación», que exige juicio y se solapa con los links, los bloques citados y los ítems que contienen varias afirmaciones (defecto que marcó la r2). La unidad es el **bloque mecánico**, identificado por su rango de líneas en `README.md@87ee282`. Bloque mecánico es —lista cerrada, sin juicio— un encabezado, un párrafo, un ítem de lista, una fila de tabla, un bloque de código o un bloque citado. La enumeración parte el baseline en bloques **contiguos, sin huecos ni solapamiento, que cubren exactamente las líneas 1–179**, y cada entrada lleva id (`B01`, `B02`, …), **disposición** —conservada · comprimida · mudada a X · dada de baja— y **locator** en el artefacto final (archivo + encabezado + fragmento citado que permita encontrarla).

  **Agrupar está permitido solo bajo dos condiciones simultáneas**: que los bloques sean **contiguos** y que compartan **la misma disposición y el mismo destino**. Es el arreglo del agujero que encontró la r3: con «rangos elegidos por conveniencia», una sola entrada `1–179` con disposición y locator genéricos satisfacía toda la aritmética de C7 sin demostrar absolutamente nada. Con la regla nueva, agrupar es solo una abreviatura de filas que dirían lo mismo, y nunca una forma de tapar una pérdida.

  **Y para toda disposición «comprimida» o «reescrita»**, la fila debe además mapear **cada afirmación independiente y cada link** que el bloque contenía a un **fragmento final concreto**. Es donde se pierde contenido de verdad: un párrafo de cuatro afirmaciones comprimido a una línea pasa como «comprimida» aunque hayan sobrevivido dos.

  La cobertura deja de ser una promesa y pasa a ser aritmética: los rangos tienen que sumar 1–179 sin saltos, y eso se comprueba mirando la columna. Un rango sin locator es una pérdida; una disposición «dada de baja» solo es legal donde la tabla de destinos del diseño la autoriza, y va con su razón nombrada.
- **Nivel B — las dos mudanzas, con transformaciones declaradas**. El render se muda desde el rango exacto **líneas 26–74** del baseline (de `## What a session actually looks like` hasta el final de «Honest scope…»; la línea 75, en blanco, no viaja). Comparación literal contra ese rango **salvo cuatro** transformaciones, que son la lista completa de lo permitido: (1) el **desplazamiento de nivel de los encabezados** —`##` pasa a `#` y los `###` a `##`—, que es también lo que produce el título del doc (la versión anterior contaba «el título» como una cuarta transformación: era la misma que la primera contada dos veces, y aplicarlas ambas habría duplicado el título — defecto que marcó la r2); (2) el **rebase de los links relativos**, que dejan de salir de la raíz y salen de `docs/` (`docs/implementation/…` → `implementation/…`, y los de la raíz ganan `../`); (3) el **agregado de una línea de contexto** al abrir, porque el doc queda solo y ya no lo precede el README — es un agregado, nunca un reemplazo; (4) **una única sustitución deíctica, acotada y nombrada**: en las líneas 70–71 el baseline dice que el workaround de `build/` está «described below», y después de la mudanza deja de estar debajo — el README se queda con el puntero y el render se va a otro archivo. La comparación literal, sin esta autorización, **obligaría a conservar una referencia falsa**: la r3 encontró el caso, y es la demostración de que «no tocar nada» no es lo mismo que «no romper nada». Se sustituye por un link al apartado correspondiente de `docs/install.md`, y esta es la **única** deíctica autorizada — cualquier otra que aparezca al comparar es un hallazgo nuevo y se trata como tal, no se resuelve al pasar. **Separadores y saltos**: el rango viaja con sus líneas en blanco internas intactas; lo único que cambia en los bordes es que no arrastra la línea en blanco final ni gana otra. **Todo lo demás se compara carácter por carácter**: cada bloque citado, cada traducción al inglés en cursiva, cada SHA, cada link. (La versión anterior decía «cada fila de la tabla de hitos»: **es falso** — esa tabla vive en el doc de diseño, no en el README, y el render del baseline no tiene ninguna tabla. Corregido en la r2.) Para el diagrama, comparación **idéntica**, sin ninguna transformación permitida. Cualquier diferencia fuera de las cuatro es un defecto, no una mejora — reescribir de paso lo que se está mudando es exactamente cómo se pierde contenido sin que nadie lo note.
- **Nivel C — la regla operativa**: nada del **dominio operativo** queda documentado solo en el README. Se verifica en la dirección que importa: para cada afirmación operativa del README nuevo —instalación, uso, casos, problemas conocidos— existe su desarrollo en `docs/install.md`. El manual ya era el completo operativo y esta reescritura no le quita nada; el único agregado es el diagrama.

No se reconstruye el extractor de tokens del feature 13, y la razón es la asimetría de riesgo: aquel README **inauguraba** el manual, así que podía perder contenido que no existía en ningún otro lado y hacía falta un barrido mecánico para descubrir qué. Acá el manual está entero, no se toca salvo el agregado, y el conjunto de lo que se mueve es **cerrado y chico** — dos mudanzas y un puñado de compresiones—, así que la enumeración exhaustiva del nivel A cubre el mismo hueco sin el intermediario. Lo que **no** cambia es la vara: la del 13 exigía que ninguna pieza desapareciera sin que alguien lo dijera, y eso lo sigue exigiendo el nivel A.

### D6 — Dónde aterriza el diagrama en `docs/install.md`

Subsección nueva **`### How the commands chain`** al final de §«The commands in full», después de la tabla: el lector ve primero qué hace cada comando y después cómo se encadenan. Contiene el diagrama idéntico más una o dos líneas de contexto. No se muda con él la prosa de «Inside a feature» del README: esa sustancia —el ciclo hasta `APPROVED`, el tope de cinco rondas, el worktree snapshot— se reescribe en prosa llana dentro de «¿cómo lo uso?», como manda la tabla de destinos del diseño, y su fuente canónica sigue siendo [`docs/design/review-contract.md`](../design/review-contract.md).

### D7 — Los dos placeholders de path que este feature cierra

El diseño dejó el path del doc del render como decisión de esta bajada, y **dos inventarios** lo esperan con un placeholder:

- `docs/DESIGN.md`, fila de componentes: «el doc del render de la sesión (desde el delta 2026-08-05; su path lo fija la bajada del feature 15)» → se sustituye por el path real.
- `docs/design/public-surface.md`, tabla de §«Política de idioma», fila **Vidriera**: «el doc del render de la sesión (path: bajada del feature 15)» → ídem.

**Lo que NO se toca de esos dos docs**: cualquier otra línea. En particular quedan **intactas** las dos frases narrativas del diseño que dicen que el path lo decide esta bajada (la tabla de destinos de §«Estructura del README» y §«Lo que este delta no decide»): son afirmaciones **sobre lo que aquel delta delegó**, siguen siendo ciertas, y reescribirlas sería falsificar el registro de quién decidió qué. La sustitución se limita a las dos **filas de inventario**, donde un placeholder deja el inventario incompleto. Un inventario con un hueco envejece mal; una narración histórica correcta, no.

### D8 — Dónde queda el puntero para agentes

El camino «instalá axel siguiendo \<url\>» (feature 02) tiene hoy su procedimiento completo en `docs/install.md` §«For agents (Claude Code)», y el README lo nombra al cerrar §Install. En la estructura nueva **sigue nombrado**, dentro de «¿cómo lo instalo?», en la línea que apunta al manual: es un **puntero**, no un caso, así que respeta el corte vidriera/manual. Sin destino, el camino que diseñó el feature 02 quedaría sin entrada visible desde la vidriera, que es la pérdida que el nivel C busca impedir.

## La prosa: el guion cerrado

El plan le asigna a esta bajada **la prosa concreta del README nuevo**, y decidir títulos y paths sin decidir el texto dejaría la asignación central pendiente. Entonces: el párrafo de apertura va acá **textual**, y cada bloque va como una lista **cerrada y ordenada** de las afirmaciones que su prosa tiene que hacer. La redacción final puede elegir cómo encadena las oraciones; **no** puede agregar una afirmación que no esté en su lista ni omitir una que sí — eso es lo que verifica C5, y lo que impide que «escribir el README» sea una hoja en blanco a la hora de implementarlo.

### El párrafo de apertura, textual

> **axel is a way of building a project with two AI agents instead of one.** One of them writes — code, documentation, whatever the project is made of — and a second, from a different vendor, reviews every change and runs your tests to check for itself instead of taking the first one's word. Everything they decide is written into your repository as they go, so a fresh session picks up from the repo rather than from an empty chat. At the end of the run you authorised it stops and waits for your approval, and the next run starts with both agents' contexts empty — so nothing rides forward on a summary nobody checked. No change is ever signed off by the agent that wrote it. This repository was built that way, by itself.

Contra el test del diseño: **vocabulario** — «agent», «review», «tests», «repository», «session», «context», «run» son del oficio del lector y están permitidos; no aparece ninguno de los seis términos internos prohibidos (round, milestone, cycle, gate, RECAP, ledger). **Cifras y SHAs** — ninguno; «two agents» y «a second» son la descripción del mecanismo, no una métrica del loop. **Autosuficiencia** — de las seis oraciones, la primera dice **qué es**, la segunda **para qué sirve** y **las cuatro últimas** por qué importa (la memoria es el repo, el humano decide y su OK renueva los contextos, nadie firma su propio trabajo, y el repo se construyó así), sin delegar en ningún link.

**Precisión de la cuarta oración, corregida en la r3.** La versión anterior decía que la pausa de aprobación es donde los dos agentes empiezan de nuevo, y afirmaba de más por dos lados: hay pausas —la autorización inicial de una corrida— donde nadie reinicia nada, y dentro de un lote o un pipeline autorizado los contextos se renuevan **entre unidades sin aprobación humana intermedia**. La formulación fiel ancla la espera en **el cierre de la corrida autorizada** y pone el contexto limpio en la corrida siguiente, que es lo que efectivamente pasa en los tres caminos (feature suelto, lote, pipeline). Es el mismo error que la r2 me marcó en el guion del bloque 3, aparecido esta vez en el párrafo.

**Anti-genérico, enunciado con honestidad.** La versión anterior de este criterio decía que **ninguna** oración sobreviviría intacta en el README de otra herramienta, y era una vara que el propio párrafo no pasaba: la r2 encontró que «You approve at the points that matter» se publicaría igual en cualquier herramienta con checkpoint humano. Prometer una vara que el texto no cumple es peor que no prometerla. El criterio queda enunciado en dos partes, las dos verificables:

- **Del párrafo entero**: contiene al menos tres propiedades que pocas herramientas pueden reclamar — el reviewer es de **otro proveedor**, **ejecuta tus tests** en vez de leer el diff, y el repo **se construyó a sí mismo con esto**.
- **De cada oración**: ninguna es relleno genérico, o sea ninguna se limita a una virtud que cualquier herramienta reclama. La primera oración es la excepción declarada: es la **definición** y su trabajo es ser entendible, no distintiva. La cuarta se reescribió por esto — la aprobación humana ahora no es «el humano aprueba» sino **dónde se renueva el contexto de los dos agentes**, que sí es una propiedad de axel.

### Bloque 1 — «Why would I use it?»

1. Un agente solo es autor y juez de su propio trabajo, y se corrige con generosidad.
2. Y además olvida: cerrada la sesión, el razonamiento detrás de cada decisión se va con ella, y la siguiente re-litiga lo ya resuelto o lo contradice sin enterarse.
3. axel contesta las dos con estructura, no con un prompt mejor: revisa **el modelo de otro proveedor**, y revisa **ejecutando** — trabaja sobre una copia del repo clavada al commit bajo review, donde corre los tests en vez de solo leer el diff.
4. Los dos agentes tienen **contextos separados y se renuevan** al pasar de un trabajo al siguiente: no comparten ventana de contexto, así que el reviewer no arrastra el hilo de razonamiento con que el generador llegó al resultado. Dicho así por precisión (corrección de la r3): el reviewer **sí** recibe el argumento y la evidencia del generador en el pedido de review — lo que no hereda es el contexto donde ese argumento se fabricó (principio 3 del baseline).
5. **La mención única de métricas** (D3): rondas registradas, rechazos, ningún ciclo aprobado en su primera ronda, la cláusula de que los aprobados son hitos y no features, el corte inline y `docs/metrics.md` como fuente.
6. Una línea al doc del render: cómo se ve una corrida de verdad, reconstruida desde el repo → `docs/session.md`.
7. El dato externo, comprimido y sin cifras derivadas: se instaló en un repo ajeno y activo; alcance honesto —un repo, del mismo autor, y una adopción y no el loop completo—, y no pretende contestar más que «¿funciona fuera de axel?».
8. La memoria es el repo: cada commit deja los docs al día —lo que no se registró no pasó (principio 5)—, así que una sesión nueva se reconstruye leyendo unos pocos archivos. Lo que se afirma es que el razonamiento queda **recuperable sin depender del chat**, no que recuperarlo salga gratis: hay que leerlo (corrección de la r2 — «no cuesta nada» no es un hecho derivable).

### Bloque 2 — «How do I install it?»

1. **Los requisitos, antes del comando** (regla que no se toca): Claude Code y Codex CLI — dos suscripciones de dos proveedores distintos, que es el costo de la review cruzada y es deliberado, porque un modelo revisándose a sí mismo no es un reviewer.
2. macOS: `awake.sh` y el envoltorio de cada review usan `caffeinate`; ambos degradan limpio sin él, y lo verificado corrió siempre en macOS — así que fuera de macOS es **no probado**, no «no soportado».
3. git, `python3`, `curl`, y el destino es un repo git con el árbol limpio.
4. Las reviews son lentas: con esfuerzo alto una ronda **puede** pasar de diez minutos — el baseline dice «puede», y convertirlo en «pasa» fortalecería la afirmación por encima de lo derivable (corrección de la r2).
5. La línea de honestidad: es caro y sin apuro a propósito; mejor saberlo ahora que después de instalar.
6. El comando de instalación, parado dentro del repo destino.
7. El known issue de `build/`: si tu `.gitignore` ignora `build/` la instalación se rechaza, y la trampa —que `!.claude/` **no** es la línea que lo arregla— nombrada como trampa, con puntero a «Known issues» del manual. Es el **único** problema con puntero desde el README, porque es el único que bloquea.
8. El puntero al manual (D8), nombrando el camino **para agentes** a los que les dijeron «instalá axel siguiendo esta URL».

### Bloque 3 — «How do I use it?»

1. Abrís Claude Code en el repo y usás los comandos — o no: un pedido en lenguaje llano se rutea por contexto, y nunca arranca trabajo sin pasar antes por un punto de confirmación.
2. La tabla de los siete comandos, una línea cada uno (la del baseline, conservada).
3. El ciclo en prosa llana: el generador escribe y commitea, el reviewer revisa ese rango y pide cambios o aprueba, el generador corrige **o argumenta**, y así hasta que hay acuerdo.
4. Dónde frena a esperarte: si no convergen en cinco vueltas, se detiene y te entrega las dos posturas para que desempates; y al terminar **la corrida que autorizaste** te presenta el resumen y no sigue sin tu OK. Dicho así a propósito: cuando lo autorizado es un lote o un pipeline, la espera es **al cierre de la corrida**, no al de cada unidad — decir «al cerrar cada tramo» sería falso para esos dos caminos (corrección de la r2).
5. La sesión es también el tablero: podés abrirla desde donde estés y **redirigirla a mitad de camino**, y lo que digas tiene prioridad sobre lo que estuviera haciendo (principio 2 del baseline).
6. Punteros: la referencia completa de los comandos y el diagrama del flujo en `docs/install.md`; el contrato entre los dos agentes en `docs/design/review-contract.md`.

### Bloque 4 — «The essentials»

1. Qué es materialmente: markdown y dos scripts de shell; no agrega dependencias a tu proyecto y no hay nada que importar.
2. `### What it is not` — seis ítems de una línea, con las **siete sustancias** de C10.
3. **La lista de links, cerrada** (nueve entradas, en este orden, cada una con su frase descriptiva; «cerrada» quiere decir que no se agrega ni se quita ninguna en la implementación — la r2 marcó, con razón, que «la lista de links» dejaba eso abierto):

   | # | Destino | Qué dice su frase |
   |---|---|---|
   | 1 | `AGENTS.md` | el proceso y las reglas, que cargan los dos agentes |
   | 2 | `docs/STATUS.md` | dónde está parado este repo ahora mismo |
   | 3 | `docs/DESIGN.md` · `docs/IMPLEMENTATION.md` | el diseño · el plan (una sola línea, como en el baseline) |
   | 4 | `docs/design/review-contract.md` | el contrato generador↔reviewer |
   | 5 | `docs/session.md` | **nuevo**: cómo se ve una corrida, reconstruida desde el repo |
   | 6 | `docs/install.md` | el manual de instalación |
   | 7 | `docs/metrics.md` | los números de esta página, con el comando detrás de cada uno |
   | 8 | `CONTRIBUTING.md` | cómo dar feedback y qué se está buscando en esta etapa |
   | 9 | `LICENSE` | MIT |

   Ocho de las nueve salen del baseline sin cambio de sustancia — todas menos la quinta; la única entrada nueva es `docs/session.md`, que es donde aterriza la mudanza. La entrada 7 sigue diciendo «los números de esta página» y sigue siendo cierta: la página tiene números — una vez, en «¿por qué lo usaría?».

## Enfoque: en qué orden se hace

Pasos chicos, cada uno con su commit y su ronda de review cuando corresponda:

1. **Bajada fina** (este doc) → review hasta `APPROVED`.
2. **`docs/session.md`** — el render mudado íntegro, más el encabezado y la línea de contexto que necesita al quedar solo. Es la mudanza de mayor superficie y la que el nivel A verifica más duro.
3. **`docs/install.md`** — el diagrama en su subsección nueva.
4. **`README.md`** — la reescritura completa, que es el corazón del feature.
5. **Los dos placeholders de path** (D7) + la enumeración cerrada del nivel A y la evidencia de los veinte criterios de cierre, escritas en este doc.

Los pasos 2 y 3 van antes del 4 a propósito: cuando se escriba el README nuevo, los destinos de las mudanzas ya existen y sus links se pueden chequear de verdad en vez de prometerse.

## Criterios de cierre

Ninguno es «lo leí y me gustó»: cada uno dice con qué se comprueba. No hay harness para prosa, así que la evidencia es inspección declarada, y donde se puede, un comando.

| # | Criterio | Cómo se verifica |
|---|---|---|
| **C1** | **Estructura**: `README.md` tiene el párrafo de apertura sin título y exactamente los cuatro `##` de D1, en ese orden | listado de encabezados del archivo |
| **C2** | **Test del párrafo de apertura**, oración por oración: cero vocabulario interno (`round`, `milestone`, `cycle`, `gate`, `RECAP`, `ledger`), cero cifras, cero SHAs, y autosuficiencia | barrido mecánico del bloque (lista de términos + dígitos + patrón de SHA corto) **más** el juicio de autosuficiencia declarado oración por oración, que ningún grep decide |
| **C3** | **Mención única de métricas**: exactamente una en todo el README, con la unidad en la misma oración, con su corte y con `docs/metrics.md` como fuente | barrido de la familia de cifras del loop sobre el archivo entero; la frontera declarada en D3 se aplica explícitamente a cada match |
| **C4** | **Cifras correctas**: cada valor publicado coincide con `docs/metrics.md` §«The figures» al corte `b0bdf4d` | comparación fila por fila contra el doc de métricas |
| **C5a** | **El párrafo de apertura es el de §«La prosa», literal** — mismo texto salvo el plegado de líneas | comparación literal contra el guion, normalizando solo saltos de línea; cualquier otra diferencia es defecto |
| **C5b** | **Correspondencia 1:1 y en orden** entre la lista cerrada de cada bloque y su prosa final: cada afirmación aparece, ninguna se agrega, y en ese orden | recorrido afirmación por afirmación, con el fragmento del README que la realiza; una afirmación sin fragmento es una omisión, y un fragmento que afirma algo fuera de la lista es un agregado — los dos son defecto |
| **C5c** | **Cada pregunta se contesta dentro de su bloque**: el lector no necesita salir del README para saber si esto es para él | inspección declarada, bloque por bloque, nombrando qué contesta cada uno |
| **C6** | **Las seis objeciones** contestadas en el bloque que el diseño les asignó (costo y macOS → requisitos; sello de goma → mención única + «el reviewer ejecuta»; montón de markdown y todo en español → «lo esencial»; ¿funciona fuera de axel? → línea de inquirylab) | tabla objeción → bloque → línea |
| **C7** | **Nivel A — cobertura aritmética y unidades mecánicas**, las tres condiciones: (i) los rangos cubren **exactamente las líneas 1–179** del baseline `87ee282`, contiguos y sin solapamiento; (ii) cada entrada es un **bloque mecánico** o una agrupación de bloques **contiguos con igual disposición y destino** — nunca un rango elegido por conveniencia; (iii) toda entrada «comprimida» o «reescrita» mapea **cada afirmación independiente y cada link** que contenía a un fragmento final concreto | tabla en este doc: los extremos encadenan (fin de `Bn` + 1 = inicio de `Bn+1`, primero en 1, último en 179); cada agrupación declara qué comparten sus bloques; cero entradas sin locator y cero compresiones sin su mapeo interno; toda baja con su autorización del diseño citada |
| **C8** | **Nivel B — las dos mudanzas**: el render coincide con las líneas 26–74 del baseline salvo las **cuatro** transformaciones declaradas, y el diagrama es idéntico sin ninguna | comparación de texto contra `87ee282`, reportando cada diferencia y a cuál de las cuatro corresponde; una diferencia que no encaje en ninguna es defecto |
| **C9** | **Nivel C**: ninguna afirmación operativa del README nuevo carece de desarrollo en `docs/install.md` | recorrido de las afirmaciones operativas con su sección destino |
| **C10** | **Las siete sustancias sobreviven** dentro de «lo esencial» — framework · costo · **lentitud** · autonomía · escala · idioma · sello de goma —, aunque queden agrupadas en seis ítems | tabla **sustancia** por sustancia (no bullet por bullet) → línea del README nuevo → qué conserva; una sustancia sin línea es una limitación despublicada |
| **C11** | **Cero link roto**: todo destino relativo y toda ancla interna de `README.md`, `docs/session.md` y `docs/install.md` resuelve | chequeo mecánico de destinos + derivación del slug de cada ancla contra los encabezados reales |
| **C12** | **Contrato editorial**: cada oración de la prosa nueva es hecho derivable, limitación declarada u opinión marcada | clasificación declarada; se reporta el conteo por clase y se nombran las opiniones marcadas |
| **C13** | **Idioma**: `README.md` y `docs/session.md` en inglés; este doc, el plan, STATUS y el ledger en español | inspección |
| **C14a** | **Paths del hijo**: la unión de paths de los commits **que no tocan el ledger** está contenida en la lista cerrada de ocho — `README.md`, `docs/session.md`, `docs/install.md`, `docs/DESIGN.md`, `docs/design/public-surface.md`, `docs/implementation/15-readme-simple.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` — o sea cero cambios en método, skills, instalador, scripts, tests o `docs/metrics.md` | `git log --name-only` sobre `87ee282..HEAD`, particionando por path; se reporta la unión observada contra la lista, **sin publicar un conteo de commits** (un contador envejece con la ronda siguiente) |
| **C14b** | **Frontera de autoría**, dos condiciones y hacen falta las dos: (i) todo commit que toca el ledger toca **solo** el ledger y `docs/STATUS.md` —único path compartido, y lo es por protocolo—; y (ii) el conjunto de commits que tocan el ledger **coincide exactamente** con la lista cerrada de SHAs del padre, hoy `{88f23af}` (el arranque de la unidad; el cierre del padre es posterior a mi último commit y queda fuera del rango) | la partición por path para (i), fail-closed y decidida por path y nunca por el mensaje; comparación de conjuntos contra la lista nombrada para (ii). La r2 mostró por qué (i) sola no alcanza: un commit **mío** que tocara únicamente ledger y STATUS la pasaría, y es justo la violación que el criterio existe para atrapar. Un SHA observado que no esté en la lista obliga a re-derivarla, no a ampliarla en silencio |
| **C14c** | **GitHub intacto** — invariancia externa **declarada**, no conclusión del diff: `origin/main` sigue en `88e1971`, el valor con que arrancó el pipeline, y esta unidad no corrió ningún comando que escriba en el remoto ni en sus settings | `git rev-parse origin/main`, cuyo valor esperado es **fijo**, como prueba **del lado del estado** (precedente: el ajuste (b) del pipeline 2026-07-29 (3)). **No** se publica el `rev-list --count origin/main..main`: es un contador móvil —la r2 lo encontró en 16 cuando mi evidencia de la r1 decía 15, y las dos eran ciertas al medirse—, exactamente lo que C14a prohíbe. El diff local no puede probar nada sobre GitHub y no se lo invoca para eso |
| **C15** | **Vara de tamaño, falsable**: el título más el párrafo de apertura entran en **≤ 18 líneas plegadas a 80 columnas**, y el párrafo dice **qué es, para qué sirve y por qué importa** — el enunciado del contrato, más preciso que «¿es esto para mí?» | `sed -n '1,/^## /p' README.md \| fold -s -w 80 \| wc -l`, reportando el número obtenido contra el umbral. El umbral es un **proxy declarado** —80 columnas × 24 líneas es la pantalla clásica de terminal, y el render de GitHub es más ancho, así que el proxy es conservador—: sin renderer, viewport y zoom fijos, «una pantalla» no es medible, y una condición reproducible y algo estricta es preferible a una declaración de buena voluntad |
| **C16** | **Higiene**: `git diff --check` limpio y `tests/lint.sh` sigue en verde | comandos, con su salida |

## Riesgos

0. **Escribir el README y desviarse del guion sin que nadie lo note.** Riesgo que la r2 hizo visible: un guion cerrado que ningún criterio hace cumplir es una intención, no un contrato — la prosa final podía cambiar el párrafo, omitir una afirmación o agregar otra y pasar igual. Mitigación: C5a compara el párrafo literalmente y C5b exige correspondencia 1:1 y en orden con cada lista.
1. **La compresión despublica una limitación sin que se note.** Es el riesgo más caro: el contrato editorial prohíbe exactamente eso, y una línea comprimida «parece» conservar. Mitigación: C10 es una tabla explícita, limitación por limitación, y la sustancia se enuncia antes de comprimir.
2. **La mención única se multiplica sin querer.** Cualquier cifra suelta en otro bloque rompe C3, y el criterio es mecánico. Mitigación: la frontera de D3 está declarada por adelantado —qué familia cuenta y qué no— para que el barrido no se resuelva a ojo cuando aparezca un match.
3. **El párrafo de apertura sale genérico.** El riesgo de sacarle todo el vocabulario interno es escribir marketing vacío que no dice nada. Mitigación: el criterio anti-genérico en sus dos partes —tres propiedades distintivas en el párrafo entero, y ninguna oración de puro relleno—, con la **excepción declarada** de la primera oración, que es la definición y cuyo trabajo es ser entendible y no distintiva. Enunciado así y no como «cualquier oración reutilizable falla» (que era la versión anterior de este riesgo, contradictoria con el criterio corregido en la r2 — la r3 la encontró todavía en pie acá).
4. **Cifras que envejecen.** El README cita un corte fijo mientras el `rounds-log` sigue creciendo — este mismo feature agrega rondas. Mitigación: es exactamente para lo que existe la foto fechada; la cita nombra su corte y no promete estar viva.
5. **La mudanza del render pierde procedencia.** Al salir del README, los bloques quedan sin el contexto que los rodeaba. Mitigación: nivel A verifica cada procedencia y cada SHA, y el doc nuevo abre explicando por qué está renderizado desde el repo y no capturado de un chat.
6. **Alcance**: la tentación de arreglar de paso la deuda normativa de idioma o algún roce del instalador. Está fuera de la ruta autorizada y sería divergencia ⇒ corte. C14 lo vuelve mecánico.

## Review log

### r1 — `CHANGES_REQUESTED` (base `87ee282`, head `cbe9e20`)

Cinco puntos, **los cinco aceptados sin argumentar**. Le había pedido explícitamente que atacara tres decisiones, y las tres las dio por buenas: **D3** (el SHA inline satisface mejor «ninguna cifra sin su corte», y la queja del humano se resuelve moviendo la métrica y dándole contexto, no ocultando el corte), **la frontera de mención única** para cifras del loop, y **D7** (completar dos inventarios que delegan explícitamente el path no cambia sustancia de diseño). Verificó además el bookkeeping —fechas locales, estado del plan, token, ronda, propiedad del ledger— y reprodujo por su cuenta `88/59/29` y los `18/18` ciclos rechazados en r1, con `git diff --check` y `tests/lint.sh` limpios. Lo corregido:

1. **La bajada no decidía la prosa concreta, que es lo que el plan le asignaba.** Cierto y era el hueco central: D1–D8 fijaban títulos, paths, métricas, compresión y controles —incluidas dos decisiones derivadas como D6 y D7— mientras la asignación principal quedaba para «el paso 4». Corregido con §«La prosa: el guion cerrado»: el **párrafo de apertura va textual** —con su verificación contra el test del diseño oración por oración, incluida la prueba anti-genérico— y cada bloque va como **lista cerrada y ordenada de afirmaciones**, donde la redacción elige el encadenado pero no puede agregar ni omitir una afirmación.
2. **Los niveles de D5 podían aprobar una pérdida.** Dos defectos reales: «una fila por sección» permite que una sección conserve una pieza y pierda tres con la fila diciendo «conservada», y verificar citas, SHAs y links **no** prueba que el render se haya mudado entero. Además `V1–V10` era una referencia colgada: los criterios son `C1–C16`. Corregido: el nivel A pasa a ser una **enumeración cerrada por pieza semántica** derivada de `87ee282`, con regla de corte declarada para que sea reproducible, id, disposición y **locator** obligatorio por pieza; el nivel B pasa a ser la comparación literal de las dos mudanzas **salvo cuatro transformaciones declaradas** (nivel de encabezado, rebase de links relativos, línea de contexto agregada, título), con todo lo demás carácter por carácter; y la referencia colgada, eliminada.
3. **D4/C10 no preservaban inequívocamente la lentitud.** El diseño exige conservar costo **y** lentitud, y mi lista de seis limitaciones las metía juntas en «no es barato» sin obligar a que la línea dijera las dos. Corregido: seis ítems pero **siete sustancias** enumeradas —framework, costo, lentitud, autonomía, escala, idioma, sello de goma—, con «no es barato» obligado a decir las dos cosas en su línea, y C10 recorrido **por sustancia** y no por bullet.
4. **C15 no era falsable.** Reportar el tamaño y declarar «una pantalla» no demuestra nada sin renderer, viewport y zoom; y «solo contesta ¿es esto para mí?» era menos preciso que el contrato. Corregido: condición reproducible con su comando y su umbral —título más párrafo en ≤ 18 líneas plegadas a 80 columnas—, declarada como **proxy conservador** y no como medida de pantalla real, y el enunciado del criterio pasa a «qué es, para qué sirve y por qué importa». C2 lo dio por verificable como estaba.
5. **C14 no controlaba la frontera de autoría ni podía hablar del remoto.** El defecto era mío y de fondo: mi §Alcance listaba el ledger como bookkeeping **del hijo**, cuando el ledger es del padre; tal como estaba, C14 habría aprobado que esta unidad lo tocara. Y `git diff --stat` no puede demostrar que GitHub no se modificó. Corregido: §Alcance declara que el ledger no es del hijo, y C14 se parte en tres — **C14a** paths del hijo contra una lista cerrada de ocho, **C14b** partición por path fail-closed (todo commit que toca el ledger toca solo ledger y STATUS, único path compartido y por protocolo), y **C14c** GitHub como **invariancia externa declarada** con prueba del lado del estado (`origin/main` en `88e1971`), siguiendo el precedente del ajuste (b) del pipeline 2026-07-29 (3). Sin contadores móviles en ninguno de los tres.

### r2 — `CHANGES_REQUESTED` (base `87ee282`, head `a7adbf6`)

Seis puntos, **los seis aceptados sin argumentar**. Codex dio por cerrados D4/C10 (las siete sustancias) y C15 —midió el párrafo propuesto con el comando publicado: **13 líneas**, contra un umbral de 18, así que el proxy no fuerza prosa telegráfica— y confirmó que la partición de paths coincide con el protocolo, que `origin/main` sigue en `88e1971`, y que `git diff --check` y `tests/lint.sh` están limpios. Lo corregido:

1. **El guion cerrado no lo hacía cumplir ningún criterio.** Yo decía que C5 detectaría agregados u omisiones, y C5 solo comprobaba que cada pregunta se contestara dentro de su bloque: el README podía cambiar el párrafo textual, omitir una afirmación o agregar otra y pasar igual. Un guion que ningún criterio hace cumplir es una intención, no un contrato. Corregido: C5 se parte en **C5a** (párrafo literal, normalizando solo el plegado), **C5b** (correspondencia **1:1 y en orden** entre cada lista cerrada y la prosa, con el fragmento que realiza cada afirmación) y **C5c** (el criterio original). Se agrega el riesgo 0, que es el que esto mitiga.
2. **El párrafo pasaba el test normativo pero no el anti-genérico que yo mismo me había impuesto.** «You approve at the points that matter» se publicaría intacta en cualquier herramienta con checkpoint humano — y la vara que yo había escrito era «ninguna oración sobreviviría intacta en el README de otra herramienta». Prometer una vara que el texto no cumple es peor que no prometerla. Corregido en los dos frentes: la oración se reescribió para que la aprobación humana no sea «el humano aprueba» sino **dónde se renueva el contexto de los dos agentes** —que sí es propiedad de axel—, y el criterio se re-enunció con honestidad en dos partes (tres propiedades distintivas en el párrafo entero; ninguna oración de puro relleno, con la **definición** de la primera oración declarada como excepción).
3. **El guion omitía o deformaba sustancia que el diseño manda conservar.** Cinco correcciones: (a) faltaban dos de los cinco principios —el control remoto y la redirección a mitad de camino, que entra en «¿cómo lo uso?», y los contextos separados y renovados entre trabajos, que entra en «¿por qué lo usaría?»— y agrego además el quinto (los docs al día en cada commit) donde sostiene la afirmación de la memoria; (b) «la lista de links» no era una lista cerrada: ahora son **nueve entradas nombradas, en orden, con su frase**, y la única nueva es `docs/session.md`; (c) «el contexto que se pierde no cuesta nada» **no es un hecho derivable** —recuperarlo cuesta releer el repo—, así que la afirmación pasa a «recuperable sin depender del chat»; (d) «una ronda pasa de diez minutos» fortalecía el baseline, que dice «puede»; (e) «al cerrar un tramo no sigue hasta tu OK» es falso para lotes y pipelines, donde la espera es **al cierre de la corrida autorizada**, no de cada unidad.
4. **La enumeración del nivel A todavía no era reproducible.** «Afirmación de nivel oración» exige juicio y se solapa con los links, los bloques citados y los ítems que contienen varias afirmaciones. Corregido: la unidad pasa a ser el **rango de líneas**, con la enumeración partiendo el baseline en rangos contiguos que cubren **exactamente 1–179**, así la cobertura se verifica por aritmética y no por confianza (C7 comprueba que los extremos encadenen). En el nivel B, dos defectos más: las transformaciones 1 y 4 eran **la misma** —convertir `##` en `#` ya produce el título, y aplicar las dos lo habría duplicado—, así que quedan **tres**; faltaban el rango exacto (**26–74**) y el tratamiento de separadores y saltos, ambos fijados; y «cada fila de la tabla de hitos» era **factualmente falso**: esa tabla vive en el doc de diseño y el render del baseline no tiene ninguna. Las tres, corregidas y anotadas en el propio texto para que no vuelvan.
5. **C14b validaba la forma de los commits con ledger, no su autoría.** Un commit **mío** que tocara únicamente ledger y STATUS lo pasaba — que es justo la violación que el criterio existe para atrapar. Corregido: se conserva la restricción de paths (compatible con todos los caminos legítimos del protocolo) y se le suma una **lista cerrada de SHAs del padre**, hoy `{88f23af}`, contra la que el conjunto observado debe coincidir; un SHA de más obliga a re-derivarla, no a ampliarla en silencio. Sin publicar su cantidad.
6. **`STATUS.md` quedó con una fecha vieja**: decía «Actualizado: 2026-08-05» y `a7adbf6` se commiteó el 2026-08-06 a las 00:01:30 -03:00. Corregido a la fecha local. Es la segunda vez en este pipeline que una fecha se desalinea en el mismo cruce de medianoche — la unidad `plan` lo tuvo en su r1, por UTC.

**Un hallazgo que me aplico a mí mismo**: Codex observó de paso que el `ahead` de `origin` es **16** y mi evidencia de la r1 decía **15**. Las dos eran ciertas al medirse —mi commit de la r2 lo movió—, y eso es exactamente la definición de contador móvil que C14a prohíbe. Lo tenía publicado en mi propio C14c: quedó eliminado, y el criterio se apoya solo en `git rev-parse origin/main`, cuyo valor esperado es fijo.

### r3 — `CHANGES_REQUESTED` (base `87ee282`, head `2ed7112`)

Cuatro puntos —tres sustantivos y uno de consistencia—, **los cuatro aceptados sin argumentar**. Codex dio por cerrado el resto: C5a/C5b es ejercitable con una tabla de fragmentos más un recorrido inverso para detectar agregados, y no resulta desproporcionado; C15 mide **15** líneas plegadas contra el máximo de 18 (subió de 13 al reescribirse la cuarta oración, y el margen sigue siendo razonable); C14b quedó fail-closed para esta unidad, sin ningún caso legítimo del protocolo que exija mezclar el ledger con otros paths del hijo; y STATUS, token y ronda son coherentes, con `git diff --check` y `tests/lint.sh` limpios.

1. **C7 todavía permitía aprobar un inventario inútil.** El agujero estaba en una frase mía de D5: los rangos se elegían «por conveniencia», así que **una sola entrada `1–179`** con disposición y locator genéricos satisfacía toda la aritmética de C7 sin demostrar nada. Corregido: la unidad pasa a ser el **bloque mecánico** —encabezado, párrafo, ítem de lista, fila de tabla, bloque de código, bloque citado: lista cerrada, sin juicio—, agrupar queda permitido **solo** entre bloques contiguos con **igual disposición y destino** (o sea, agrupar es abreviar filas que dirían lo mismo, nunca tapar), y toda disposición «comprimida» o «reescrita» debe mapear **cada afirmación independiente y cada link** a un fragmento final concreto. C7 pasa a tener las tres condiciones explícitas.
2. **Al nivel B le faltaba una cuarta transformación, y es un defecto real de la mudanza.** Las líneas 70–71 del baseline dicen que el workaround de `build/` está «described below», y después de mudar 26–74 a `docs/session.md` deja de estar debajo: el README se queda con el puntero y el render se va a otro archivo. Con las tres transformaciones que tenía, la comparación literal **obligaba a conservar una referencia falsa** — «no tocar nada» no es lo mismo que «no romper nada». Autorizada la **única** sustitución deíctica, acotada y nombrada, por un link al apartado correspondiente del manual; cualquier otra deíctica que aparezca al comparar es hallazgo nuevo y se trata como tal.
3. **La cuarta oración del párrafo afirmaba de más sobre los contextos.** Decía que la pausa de aprobación es donde los dos agentes empiezan de nuevo, y eso falla por dos lados: hay pausas —la autorización inicial— donde nadie reinicia nada, y dentro de un lote o un pipeline autorizado los contextos se renuevan **entre unidades, sin aprobación humana intermedia**. Es el mismo error que la r2 me marcó en el guion del bloque 3, reaparecido en el párrafo. Reescrita anclando la espera en **el cierre de la corrida autorizada** y el contexto limpio en la corrida siguiente, que es lo que pasa en los tres caminos. Y por la misma razón se precisó la afirmación 4 del bloque 1: el reviewer **no comparte ventana de contexto** con el generador, pero **sí recibe** su argumento y su evidencia en el pedido de review — decir «no hereda el razonamiento» era falso.
4. **Tres contradicciones internas**, las tres sincronizadas: la explicación del párrafo decía «las tres últimas» cuando son seis oraciones y quedan cuatro; la tabla de links decía «las ocho primeras salen del baseline» cuando la entrada nueva es la **quinta** (son ocho de las nueve); y el riesgo 3 seguía declarando que falla cualquier oración reutilizable, que es exactamente la vara que la r2 había hecho corregir en el criterio y que acá había quedado en pie.
