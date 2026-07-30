# Superficie pública de axel — posicionamiento, idioma, licencia y evidencia

> Profundización de [../DESIGN.md](../DESIGN.md). **Procedencia**: delta de diseño escrito como unidad `design-delta` del **tercer** pipeline `/build` del 2026-07-29 — ledger [../implementation/pipeline-2026-07-29-3.md](../implementation/pipeline-2026-07-29-3.md) —, autorizado por su gate ese mismo día. Pedido literal del humano: «Dejar el repo público de axel presentable para compartirlo: README en inglés escrito para quien lo descubre, licencia MIT, y los docs de onboarding y feedback que faltan» (el texto completo, con su contexto y sus decisiones previas, vive en el bloque Gate del ledger). **Ajuste de alcance del gate que manda sobre esta unidad**: el pipeline **no toca GitHub ni pushea** — ni `git push`, ni topics, ni homepage; los comandos quedan listos y los corre el humano.

## El hueco

`DESIGN.md` no dice **nada** sobre la superficie pública: no hay decisión de licencia, ni política de idioma, ni criterio sobre qué va en el README frente a qué va en la guía de instalación, ni tratamiento de las métricas del loop como artefacto auditable. Las consecuencias están a la vista: el repo es público **sin licencia**; el README tiene 69 líneas y unas 50 son casuística de instalación —está escrito para quien ya decidió usar axel, no para quien lo descubre—; y el **agregado** de las métricas del reviewer vive en un archivo que no está versionado. Precisión que el propio contrato editorial de abajo exige: los rechazos **sí** están en el repo, uno por uno, en los review logs de `docs/implementation/*.md`, que son la memoria oficial del loop; lo que falta no es la evidencia sino su agregado auditable y re-derivable.

**Principio rector del delta**: la vidriera se sostiene con la misma vara que el método. Lo que axel ofrece es auditabilidad; una vidriera que no se puede auditar contradice el producto. De ahí salen casi todas las decisiones de abajo.

## Política de idioma — tres planos

El criterio no es una lista de archivos sino un test: **el idioma lo decide la audiencia del artefacto, no su ubicación en el árbol**.

| Plano | Audiencia | Idioma | Artefactos |
|---|---|---|---|
| **Vidriera** | quien descubre axel desde afuera | **inglés** | `README.md`, `CONTRIBUTING.md`, `.github/`, `docs/install.md`, y el **informe** de métricas |
| **Método** | los dos agentes y el humano que operan *este* repo | **español** | `AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`, los subdirectorios de `docs/`, los mensajes de commit |
| **Artefactos instalados en el destino** | el proyecto ajeno donde corre el instalador | **español hoy** — limitación declarada | el **payload sobreescribible** (skills, scripts, contrato, política) y las **semillas intocables** (`templates/*`) |

El tercer plano se nombra por lo que es —lo que el instalador deja en el destino— y no «semilla», porque el contrato del instalador ya usa esa palabra para una de sus dos mitades: las skills son **payload sobreescribible** (se pisan al re-correr el instalador) y `templates/*` son **semillas** (solo se siembran si faltan, no se pisan nunca). La frontera arquitectónica no se toca; lo que se agrega es que **las dos mitades hoy llevan texto en español**, y por vías distintas: el payload se actualiza solo con cada re-run, la semilla se congela en el destino desde el día uno.

**El doc de métricas tiene dos piezas y se clasifican distinto**: el **informe** (prosa, el que el README cita) es vidriera ⇒ inglés; el **snapshot crudo** del `rounds-log` no es un documento sino un dato —marcas de tiempo, veredictos y SHA— y por lo tanto es **neutro de idioma**: vivir bajo `docs/` no lo vuelve un doc del método. La bajada del feature 14 mantiene la distinción al elegir los paths.

Tres cosas más que el criterio resuelve y una lista de archivos no resolvería:

- **`docs/install.md` va en inglés**, aunque viva bajo `docs/`. Su audiencia es el mismo lector de afuera, un paso más adelante en el embudo: es la **última milla** de la vidriera. Un corte de idioma exactamente en el punto de conversión —convencer en inglés y entregar el manual en español— es el peor lugar donde ponerlo. **Costo, declarado**: la mudanza de la casuística del README a `docs/install.md` es simultáneamente una traducción, así que la verificación de «cero pérdida» del feature 13 no puede hacerse con un diff de texto — se hace contra el contenido, caso por caso.
- **Lo instalado en el destino es su propio plano.** La maquinaria es agnóstica del idioma en que trabaje el destino, pero el texto que le deja hoy está en español. Declararlo es gratis y honesto; traducirlo no está en el alcance de este pipeline. Es además la respuesta a la objeción «está todo en español»: la maquinaria no se entera del idioma, este repo eligió el suyo, y lo que se instala todavía no se tradujo.
- **Es una excepción explícita**, no una práctica tácita. `AGENTS.md` §Convenciones dice «Docs, commits y comunicación en español» sin matices, y a partir de esta decisión esa línea contradice al repo.

**Consecuencia sobre el método: este pipeline termina con una deuda normativa declarada.** Corregir esa línea de `AGENTS.md` (y su espejo obligatorio en `templates/AGENTS.md`, por la regla de sincronía) es tocar el método, que está explícitamente fuera del alcance de esta unidad, y la ruta autorizada está cerrada a los features 13 y 14 — ninguno de los dos la incluye. No se resuelve delegándola al plan: meterla en el 13 sería ampliar en silencio un scope que el humano fijó, y eso no es una decisión que le toque a esta unidad.

Entonces se declara, con todo lo necesario para que quien la levante no la re-derive:

- **Qué queda mal**: `AGENTS.md` §Convenciones afirma «Docs, commits y comunicación en español» sin excepción, y desde esta decisión el `README.md` en inglés la contradice.
- **Arreglo mínimo**: una cláusula de excepción en esa línea que apunte a esta profundización, replicada en `templates/AGENTS.md`. Es una línea por archivo; no hay diseño pendiente.
- **Atenuante, no solución**: la excepción es descubrible siguiendo el orden de lectura que el propio `AGENTS.md` manda (AGENTS → STATUS → DESIGN), donde ya está registrada. Pero la línea sigue leyéndose como absoluta para quien no baja hasta el diseño.
- **Cómo se cierra**: el humano puede autorizarla en el OK del RECAP consolidado —es del tamaño de una errata— o queda para una pasada posterior. Lo que no puede pasar es que se cierre sin que nadie la haya autorizado.

## Licencia: MIT

Hoy el repo es público sin licencia, o sea legalmente «todos los derechos reservados», lo que contradice de frente que su propuesta central sea «instalalo en tu proyecto». **MIT**: permisiva, corta, universalmente reconocida y sin fricción para el destino — es justamente la licencia que vuelve legalmente trivial la operación central del instalador, que es copiar archivos dentro del repo de otro, con su propia licencia.

Titular y año se confirman en la bajada del feature 13; no se inventan acá.

**Limitación pendiente, declarada y fuera del alcance de este pipeline**: el texto de MIT pide que el aviso de copyright y permiso se incluya en las copias o porciones sustanciales del software, y el instalador copia skills, scripts y contrato dentro de los destinos sin que hoy nada lleve ese aviso. No somos abogados y esto no bloquea publicar, pero **queda rotulado como incumplimiento pendiente, no como cumplimiento parcial**: que `docs/install.md` declare bajo qué licencia queda lo instalado **informa al usuario y no satisface el requisito** — un puntero que no viaja con el payload no es el aviso que viaja con el payload. La declaración en el manual entra igual, por útil; lo que no se hace es contarla como si cerrara el tema. Hacer que el instalador copie el aviso toca el instalador ⇒ fuera de alcance, y sin entrada de backlog porque el humano dejó ese trabajo afuera de este pipeline.

## Vidriera y manual: el criterio de corte

Test aplicable línea a línea, no un reparto puntual:

- El **README** contesta *«¿esto es para mí?»*. El **manual** (`docs/install.md`) contesta *«¿cómo lo hago andar?»*.
- **Al README solo entra lo que vale para todos.** Toda frase que empiece con «si…» o «salvo que…» describe un caso, y los casos van al manual. El README puede llevar un **puntero** a un caso; nunca el caso.
- **En el dominio operativo, el manual es el completo y el README es el extracto.** Nada **operativo** —instalación, uso, casos, problemas conocidos— queda documentado *solo* en el README: con eso la mudanza es sin pérdida por construcción y el feature 13 tiene contra qué chequearse. La regla está **acotada a ese dominio a propósito**: el posicionamiento, el transcript, la evidencia y «What this is not» viven solo en el README y **no** se duplican en el manual — pedirle completitud sobre todo el README obligaría a un `docs/install.md` que repite la vidriera, que es justo lo contrario del corte.
- **Vara de tamaño, no de líneas**: si el lector tiene que scrollear más de una pantalla para saber si esto es para él, el corte falló.
- **Orden del embudo**: los requisitos van **antes** del comando de instalación. Un lector que instala y recién después descubre que hacen falta dos suscripciones de dos proveedores es un lector perdido con razón.

## Contrato editorial de la vidriera

Toda afirmación publicada es exactamente una de tres:

1. **hecho derivable del repo**, con un comando declarado que lo deriva;
2. **limitación declarada**;
3. **opinión marcada como tal**.

Lo que no entra en ninguna de las tres no se publica. Esto es lo que vuelve verificable la «prosa auditable» que los features 13 y 14 prometen: deja de ser un juicio de gusto y pasa a ser una clasificación por oración.

Y **una sola fuente para los números**: toda cifra de la vidriera vive en el doc de métricas y el README la cita. Dos lugares con el mismo número son dos lugares para envejecer distinto.

## La evidencia del loop como artefacto versionado

El problema de fondo: `.claude/state/rounds-log` está en `.gitignore`. **Nadie de afuera puede auditar lo que no puede leer** — publicadas así, las métricas del reviewer son un número que tecleó el autor.

La decisión es que la evidencia sea una **foto fechada versionada, no un contador vivo**:

- **Snapshot versionado** — una copia del `rounds-log` al corte, bajo `docs/`. Explícitamente **no** se desversiona `.claude/state/`: el loop escribe ahí en cada ronda, y versionarlo metería su propio ruido en todos los commits. El path exacto lo fija la bajada.
- **Commit de corte declarado** — la foto dice de qué commit y qué fecha es. Ninguna cifra de la vidriera se publica sin su corte.
- **Comando de derivación declarado** — el comando exacto que produce cada cifra desde el snapshot, corriendo con el toolchain de stock de macOS. Verificado al escribir este delta: el `awk` del sistema **no** tiene `asort` (es de gawk), así que el comando no puede depender de él; el orden se resuelve con `sort`.
- **Contra-chequeo independiente** — cada fila del log nombra un SHA. Un tercero puede verificar que esos commits existen en `main`, que sus fechas cierran y que la historia publicada es **lineal**: la métrica no se apoya solo en «confiá en el archivo». Lo que ese chequeo **no** prueba es que nadie la haya reescrito —un force-push anterior a la publicación es indetectable desde un clon—, así que se afirma lo primero y no lo segundo.
- **Segunda fuente, independiente del log** — los **review logs versionados** de `docs/implementation/*.md` registran las rondas de cada feature en el repo mismo. Sirven para cruzar el `rounds-log` y, como se ve abajo, para cubrir el tramo que el log no alcanza.
- **Re-corte** — una corrida futura vuelve a correr el comando sobre un snapshot fresco. El criterio queda escrito, así que no se reinventa.

### La unidad de conteo, que es lo que decide la credibilidad

Hay **tres** unidades y no se mezclan:

| Unidad | Qué es | En el `rounds-log` al corte `e1e1282` |
|---|---|---|
| **ronda** | una ronda del contrato de review — **no** una fila del log | **80** registradas |
| **hito** | un tramo que termina en `APPROVED` (bajada fina, implementación, un ciclo de plan o de diseño) | **27** |
| **ciclo** | una sesión de Codex, de `new` hasta su cierre — hoy ≈ un feature o una unidad de pipeline | **16 completos observables**, más uno parcial |

Los `APPROVED` son **hitos, no features**: por eso hay más aprobados que features, y enunciarlo mal es exactamente lo que destruye credibilidad.

**Criterio de conteo de rondas.** La ronda es la unidad del **contrato**, no la fila del log: una misma ronda puede dejar más de una fila, porque `review.sh` reintenta una vez ante falla de proceso —registrando `PROC_FAIL` antes del veredicto— y un veredicto inválido queda como `NO_VERDICT`. El conteo **deduplica por (ciclo, número de ronda)**. Contar filas con veredicto da hoy el mismo número —las 80 filas son todas `APPROVED`/`CHANGES_REQUESTED` y todas con intento 1— y dejaría de darlo apenas haya un reintento, que es justo cuando nadie estaría mirando. Aparte, los eventos **pre-invocación** (`DEADLOCK`, `INPUT_ERROR`) llevan `-` en ronda, intento y SHA y no son rondas.

Tres hallazgos de este delta que el doc de métricas tiene que incorporar, porque fijan el criterio y no solo el número:

1. **«Cero aprobados en ronda 1» es cierto por ciclo y falso por hito.** Ningún ciclo volvió `APPROVED` en su primera ronda; pero hay exactamente **un hito** aprobado sin ningún rechazo en su tramo (`2dbbdfc`, feature 07 «paso A», 2026-07-28, aprobado en la ronda 4 inmediatamente después del `APPROVED` de la ronda 3). Lo mismo con las otras cifras: la mediana es **4,5 por ciclo** y **3 por hito**; el peor caso, **11 por ciclo** y **5 por hito**. La mediana por ciclo se calcula sobre los **16 completos** (longitudes `2,2,2,2,3,3,3,4,5,5,6,7,7,7,8,11`) y da 4,5 — el «4» que traía el pedido salía de contar el ciclo **parcial** del arranque del log como si fuera completo; si se prefiere la mediana inferior hay que nombrarla como tal, no publicarla como «la mediana». Publicar una mediana de una unidad al lado de un conteo de otra es precisamente el error contra el que advertía el pedido: **la formulación defendible nombra la unidad**.
2. **Las cifras del log son una muestra, no el total — y el faltante es recuperable.** La primera fila es `2026-07-28 00:10` y ya es la `round 6` de un ciclo en curso: el registro de métricas llegó con el feature 03. Lo que queda afuera **no** se pierde, porque los review logs versionados lo registran: feature 00 (4 rondas), el ciclo de plan inicial (5), feature 01 (11), feature 02 (10) y las rondas 1–5 del feature 03 = **35 rondas anteriores**. Total histórico **115**, de las cuales 80 tienen detalle por ronda y 35 solo el conteo. El doc publica las dos cosas rotuladas —«80 logged rounds since instrumentation» como la muestra auditada fila por fila, y 115 como el total histórico con su segunda fuente— y **nunca** una sola cifra sin decir a cuál corresponde. La afirmación de los aprobados en ronda 1 se sostiene sobre **ambas**: los cinco ciclos previos cerraron en r4, r5, r11, r10 y r8, así que ninguno aprobó en la primera ronda tampoco — son **21 ciclos** sin un solo aprobado de entrada.
3. **El corte no es una formalidad: las cifras se movieron mientras se escribía esto.** La review de la ronda 1 de esta misma unidad agregó su fila al `rounds-log` — 80 pasaron a 81 y apareció un ciclo nuevo en curso — entre que se consolidó el delta y que llegó el veredicto. Es la demostración en vivo de por qué la evidencia se publica como foto fechada con su commit de corte y no como un número suelto.

**El gancho tiene el mismo problema que las métricas.** «Se construyó a sí mismo: N commits en tres días, M features» son cifras que se mueven con cada corrida —este pipeline incluido— y les rige la misma regla: corte, comando y fuente única.

## El transcript de «What a session actually looks like»

El gate delegó esta pregunta explícitamente a esta unidad. Los candidatos eran la adopción de inquirylab (real y externa, pero es un `/adopt` y no el loop con `CHANGES_REQUESTED` → RECAP → OK que la sección promete), un loop real de axel (tiene el ciclo completo, pero axel diseñándose a sí mismo es recursivo y confuso para quien recién llega), o un compuesto declarado como tal (la recomendación no vinculante del padre).

**Decisión: dos bloques uno al lado del otro, cada uno con su procedencia — no una sesión mezclada.**

La razón sale del propio principio de axel: el chat es efímero y la memoria es el repo. **No hay transcript de sesión que capturar**, y publicar un log de chat con aspecto de reconstruido, en un proyecto cuya propuesta central es la auditabilidad, es lo más dañino que podría hacer. Entonces:

- **Bloque 1 — la sesión completa**, renderizada desde el repo. La sección promete *«pedido sin comando → gate → un `CHANGES_REQUESTED` verdadero → RECAP → OK»*, y el arco entero tiene que estar: mostrar solo el tramo de review dejaría afuera los **checkpoints humanos**, que son justamente lo que distingue a axel de un agente que corre suelto. Los cinco hitos son recuperables, cada uno de una fuente durable:

  | Hito | De dónde sale |
  |---|---|
  | pedido sin comando | el pedido literal del humano, transcrito en el bloque Gate del ledger de la corrida |
  | gate y autorización | el evento de autorización del ledger, con las palabras exactas del humano |
  | `CHANGES_REQUESTED` verdadero | el review log del feature y el commit de la ronda |
  | corrección → `APPROVED` | el commit que corrige y el que cierra, con su número de ronda |
  | RECAP → OK | el STATUS en «esperando OK» y el commit que registra el OK, que cita su literal |

  Un **pipeline** es la fuente natural, porque su ledger tiene los cinco en un solo lugar. Candidato citable que trae el pedido para el tramo de review: `74d3f5c` («feature 11 r5: … tres defectos invisibles en la lectura del texto nuevo») — que es el commit de la **corrección**, así que hay que citar también la ronda que los encontró y no solo el arreglo. El bloque es recursivo por construcción —axel sobre axel— y eso es el gancho, declarado, no escondido.

  Si al escribir el feature 13 alguna corrida no tuviera el arco completo, la salida **no** es rellenar el hueco: es cambiar explícitamente la promesa del título de la sección para que describa lo que el bloque muestra de verdad.
- **Bloque 2 — la prueba externa**: la adopción real de inquirylab, rotulada como lo que es — un repo, del mismo autor, una adopción y no el loop completo. Contesta «¿funciona en algo que no sea axel mismo?» y no pretende contestar más que eso.

**Regla dura: ninguna línea inventada.** Cada línea rastrea a un commit, a un evento de ledger o a un review log. Lo que no sea recuperable no se reconstruye de memoria: se omite o se declara. Renderizarlo desde el repo no es un sustituto de un transcript — es exactamente lo que una sesión deja atrás en axel.

## Estructura del README

Las nueve secciones que propone el pedido se sostienen. Lo que este delta refina:

1. **Las cifras del título necesitan su unidad ahí mismo.** «80 review rounds» no significa nada sin saber qué es una ronda, y la precisión «hitos, no features» se pierde justo en la línea que más se cita. Una cláusula que la califique, más el link al doc de métricas.
2. **Requisitos antes de instalar** (§4 antes que §5): se confirma — es el embudo honesto.
3. **Install lleva un puntero** a los problemas conocidos, no los problemas.
4. **«What this is not» se queda donde está** (§8): quien llegó hasta ahí quiere primero la mecánica y después los límites.

Las seis objeciones que lista el pedido quedan como **criterio de aceptación de la prosa**: cada una tiene que estar contestada por el README **antes** de que el lector la formule. La de «¿funciona fuera de axel?» ahora tiene respuesta —inquirylab— con su alcance honesto: un repo, del mismo autor.

## Los tres puntos de fricción: dónde se declaran

Criterio: **un problema conocido se documenta donde el usuario lo choca**, no en un apéndice.

| Fricción | Dónde se choca | Dónde se declara |
|---|---|---|
| Colisión de `build/` con el `.gitignore` del destino | instalando, al primer intento, en cualquier repo Python/Node/Java/Gradle/Maven/C | «Known issues» de `docs/install.md`, con el workaround `!.claude/skills/build/` y la trampa de `!.claude/` explicada; más un **puntero de una línea** desde el README |
| Rechazo por árbol sucio que no lista los archivos sucios (y `git stash` sin `-u` no toca untracked) | instalando, en un repo activo | «Known issues» de `docs/install.md` |
| `modo: initial` anunciado cuando lo ejecutado fue una adopción; el destino queda con cuatro docs y dos nombres, sin aviso de cuál manda | después de instalar, adoptando | sección de adopción de `docs/install.md`: qué vas a ver, qué significa, cuál manda y que `/adopt` lo resuelve |

El de `build/` es el **único** que se gana un puntero desde el README, porque es el único que **bloquea** la promesa que el README hace («podés instalarlo sin volver a preguntar»). Los otros dos son fricción, no pared.

Arreglar los tres está fuera de alcance por decisión del humano y —también por decisión explícita, en el gate del pipeline anterior y en este— **tampoco reciben entrada de backlog**. Queda registrado acá para que «no arreglado» sea una decisión asentada y no un descuido.

## Lo que este delta no decide

El contenido concreto del README, de `docs/install.md` y de `CONTRIBUTING.md` (features 13 y 14); el titular y el año de la licencia; el path exacto del snapshot de métricas y la forma final de su comando; y **nada sobre GitHub** — sin push, sin topics, sin homepage, por el ajuste de alcance del gate. Los arreglos del instalador siguen afuera.
