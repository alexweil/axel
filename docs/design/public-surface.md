# Superficie pública de axel — posicionamiento, idioma, licencia y evidencia

> Profundización de [../DESIGN.md](../DESIGN.md). **Procedencia**: delta de diseño escrito como unidad `design-delta` del **tercer** pipeline `/build` del 2026-07-29 — ledger [../implementation/pipeline-2026-07-29-3.md](../implementation/pipeline-2026-07-29-3.md) —, autorizado por su gate ese mismo día. Pedido literal del humano: «Dejar el repo público de axel presentable para compartirlo: README en inglés escrito para quien lo descubre, licencia MIT, y los docs de onboarding y feedback que faltan» (el texto completo, con su contexto y sus decisiones previas, vive en el bloque Gate del ledger). **Ajuste de alcance del gate que manda sobre esta unidad**: el pipeline **no toca GitHub ni pushea** — ni `git push`, ni topics, ni homepage; los comandos quedan listos y los corre el humano. **Delta posterior**: §«Estructura del README» fue reescrita el 2026-08-05 por la unidad `design-delta` del pipeline de esa fecha — su procedencia completa vive en la propia sección.

## El hueco

`DESIGN.md` no dice **nada** sobre la superficie pública: no hay decisión de licencia, ni política de idioma, ni criterio sobre qué va en el README frente a qué va en la guía de instalación, ni tratamiento de las métricas del loop como artefacto auditable. Las consecuencias están a la vista: el repo es público **sin licencia**; el README tiene 69 líneas y unas 50 son casuística de instalación —está escrito para quien ya decidió usar axel, no para quien lo descubre—; y el **agregado** de las métricas del reviewer vive en un archivo que no está versionado. Precisión que el propio contrato editorial de abajo exige: los rechazos **sí** están en el repo, uno por uno, en los review logs de `docs/implementation/*.md`, que son la memoria oficial del loop; lo que falta no es la evidencia sino su agregado auditable y re-derivable.

**Principio rector del delta**: la vidriera se sostiene con la misma vara que el método. Lo que axel ofrece es auditabilidad; una vidriera que no se puede auditar contradice el producto. De ahí salen casi todas las decisiones de abajo.

## Política de idioma — tres planos

El criterio no es una lista de archivos sino un test: **el idioma lo decide la audiencia del artefacto, no su ubicación en el árbol**.

| Plano | Audiencia | Idioma | Artefactos |
|---|---|---|---|
| **Vidriera** | quien descubre axel desde afuera | **inglés** | `README.md`, `CONTRIBUTING.md`, `.github/`, `docs/install.md`, el **informe** de métricas y — desde el delta 2026-08-05 — el doc del render de la sesión (path: bajada del feature 15) |
| **Método** | los dos agentes y el humano que operan *este* repo | **español** | `AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`, los subdirectorios de `docs/`, los mensajes de commit |
| **Prosa instalada en el destino** | el proyecto ajeno donde corre el instalador | **español hoy** — limitación declarada | las skills, el contrato de review, los mensajes de los scripts, y las cuatro plantillas documentales (`AGENTS.md`, `DESIGN.md`, `IMPLEMENTATION.md`, `STATUS.md`) |

El tercer plano se define por **prosa**, no por la frontera payload/semillas del instalador, y por dos razones. La primera es que esa frontera no parte los archivos en dos mitades limpias: `templates/settings.json` es a la vez fuente del **payload** `.claude/axel-policy.json` y de la **semilla** `.claude/settings.json`, así que «`templates/*` son semillas» contradice al instalador. La segunda es que buena parte de lo instalado **no tiene idioma**: la **lógica ejecutable** de los scripts, la policy, el `settings.json`, el symlink y la entrada de `.gitignore` quedan fuera del plano porque no hay nada que traducir en ellos. Lo que sí tiene idioma son las skills, el contrato, **los mensajes que los scripts imprimen** y las cuatro plantillas documentales. La distinción corre **dentro** de un mismo archivo: un script es lógica neutra más cadenas traducibles, y son las cadenas —lo que el usuario del destino efectivamente lee— las que pertenecen al plano. Hoy todo eso está en español, por dos vías distintas: la prosa del payload se actualiza sola con cada re-run del instalador, la de las semillas se congela en el destino desde el día uno.

**El doc de métricas tiene dos piezas y se clasifican distinto**: el **informe** (prosa, el que el README cita) es vidriera ⇒ inglés; el **snapshot crudo** del `rounds-log` no es un documento sino un dato —marcas de tiempo, veredictos y SHA— y por lo tanto es **neutro de idioma**: vivir bajo `docs/` no lo vuelve un doc del método. La bajada del feature 14 mantiene la distinción al elegir los paths.

Tres cosas más que el criterio resuelve y una lista de archivos no resolvería:

- **`docs/install.md` va en inglés**, aunque viva bajo `docs/`. Su audiencia es el mismo lector de afuera, un paso más adelante en el embudo: es la **última milla** de la vidriera. Un corte de idioma exactamente en el punto de conversión —convencer en inglés y entregar el manual en español— es el peor lugar donde ponerlo. **Costo, declarado**: la mudanza de la casuística del README a `docs/install.md` es simultáneamente una traducción, así que la verificación de «cero pérdida» del feature 13 no puede hacerse con un diff de texto — se hace contra el contenido, caso por caso.
- **La prosa instalada es su propio plano.** La maquinaria es agnóstica del idioma en que trabaje el destino, pero el texto que le deja hoy está en español. Declararlo es gratis y honesto; traducirlo no está en el alcance de este pipeline. Es además la respuesta a la objeción «está todo en español»: la maquinaria no se entera del idioma, este repo eligió el suyo, y lo que se instala todavía no se tradujo.
- **Es una excepción explícita**, no una práctica tácita. `AGENTS.md` §Convenciones dice «Docs, commits y comunicación en español» sin matices, y a partir de esta decisión esa línea contradice al repo.

**Consecuencia sobre el método: este pipeline termina con una deuda normativa declarada.** Corregir esa línea de `AGENTS.md` (y su espejo obligatorio en `templates/AGENTS.md`, por la regla de sincronía) es tocar el método, que está explícitamente fuera del alcance de esta unidad, y la ruta autorizada está cerrada a los features 13 y 14 — ninguno de los dos la incluye. No se resuelve delegándola al plan: meterla en el 13 sería ampliar en silencio un scope que el humano fijó, y eso no es una decisión que le toque a esta unidad.

Entonces se declara, con todo lo necesario para que quien la levante no la re-derive:

- **Qué queda mal**: `AGENTS.md` §Convenciones afirma «Docs, commits y comunicación en español» sin excepción, y desde esta decisión el `README.md` en inglés la contradice.
- **Arreglo mínimo**: una cláusula de excepción en esa línea que apunte a esta profundización, replicada en `templates/AGENTS.md`. Es una línea por archivo; no hay diseño pendiente.
- **Atenuante, no solución**: la excepción es descubrible siguiendo el orden de lectura que el propio `AGENTS.md` manda (AGENTS → STATUS → DESIGN), donde ya está registrada. Pero la línea sigue leyéndose como absoluta para quien no baja hasta el diseño.
- **Cómo se cierra**, respetando el contrato: el commit que registra el OK consolidado es **transcripción mecánica de estados** y no puede además autorizar y ejecutar dos ediciones nuevas. Entonces hay exactamente dos caminos válidos: si el humano la quiere cerrada **antes** del cierre del pipeline, eso es cambio de scope ⇒ **corte**; si la autoriza **junto con** el OK, la ejecución va en una **unidad autorizada aparte**, posterior. Lo que no existe es cerrarla de contrabando dentro del commit del OK, ni que se cierre sin que nadie la haya autorizado.

## Licencia: MIT

Hoy el repo es público sin licencia, o sea legalmente «todos los derechos reservados», lo que contradice de frente que su propuesta central sea «instalalo en tu proyecto». **MIT**: permisiva, corta, universalmente reconocida y sin fricción para el destino — es la licencia que da el permiso amplio que la operación central del instalador necesita, que es copiar archivos dentro del repo de otro, con su propia licencia. Con una condición que hay que decir en la misma frase para no contradecirse dos párrafos después: ese permiso está **sujeto a que el aviso se conserve en las copias**, y el instalador de hoy todavía no lo transporta (ver abajo). O sea: MIT resuelve el permiso, no la mecánica.

Titular y año se confirman en la bajada del feature 13; no se inventan acá.

**Limitación pendiente, declarada y fuera del alcance de este pipeline**: el texto de MIT pide que el aviso de copyright y permiso se incluya en las copias o porciones sustanciales del software, y el instalador copia skills, scripts y contrato dentro de los destinos sin que hoy nada lleve ese aviso. No somos abogados y esto no bloquea publicar, pero **queda rotulado como incumplimiento pendiente, no como cumplimiento parcial**: que `docs/install.md` declare bajo qué licencia queda lo instalado **informa al usuario y no satisface el requisito** — un puntero que no viaja con el payload no es el aviso que viaja con el payload. La declaración en el manual entra igual, por útil; lo que no se hace es contarla como si cerrara el tema. Hacer que el instalador copie el aviso toca el instalador ⇒ fuera de alcance, y sin entrada de backlog porque el humano dejó ese trabajo afuera de este pipeline.

## Vidriera y manual: el criterio de corte

Test aplicable línea a línea, no un reparto puntual:

- El **README** contesta *«¿esto es para mí?»*. El **manual** (`docs/install.md`) contesta *«¿cómo lo hago andar?»*.
- **Al README solo entra lo que vale para todos.** Toda frase que empiece con «si…» o «salvo que…» describe un caso, y los casos van al manual. El README puede llevar un **puntero** a un caso; nunca el caso.
- **En el dominio operativo, el manual es el completo y el README es el extracto.** Nada **operativo** —instalación, uso, casos, problemas conocidos— queda documentado *solo* en el README: con eso la mudanza es sin pérdida por construcción y el feature 13 tiene contra qué chequearse. La regla está **acotada a ese dominio a propósito**: el posicionamiento, el render de la sesión, la evidencia y las limitaciones declaradas viven en la **vidriera** —el README o el doc de vidriera al que el README apunta (desde el delta 2026-08-05, el render de la sesión tiene doc propio)— y **no** se duplican en el manual — pedirle completitud sobre todo el README obligaría a un `docs/install.md` que repite la vidriera, que es justo lo contrario del corte.
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
- **Segunda y tercera fuente, independientes del log** — los **review logs versionados** de `docs/implementation/*.md` registran las rondas de cada **feature** en el repo mismo; y el **ciclo de plan**, que no tiene doc propio en `implementation/`, deja su memoria en los **commits y el STATUS histórico**. Las dos sirven para cruzar el `rounds-log` y, como se ve abajo, para cubrir el tramo que el log no alcanza — pero son fuentes distintas y se citan por separado.
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
2. **Las cifras del log son una muestra, no el total — y el faltante es recuperable.** La primera fila es `2026-07-28 00:10` y ya es la `round 6` de un ciclo en curso: el registro de métricas llegó con el feature 03. Lo que queda afuera **no** se pierde, pero viene de **dos fuentes distintas** y hay que citarlas separadas: **30 rondas** en los review logs versionados de features —feature 00 (4), feature 01 (11), feature 02 (10) y las rondas 1–5 del feature 03 (5)— y **5 rondas** del ciclo de plan inicial, que no tiene doc en `implementation/` y cuya memoria son los **commits y el STATUS histórico**. En total, **35 rondas anteriores** y un histórico de **115**. Ninguna de las 35 es «solo un conteo»: las 30 tienen su review log ronda por ronda con los puntos de cada una, y las 5 del plan están narradas en el STATUS de su momento; lo que a todas les falta es el esquema tabular del `rounds-log` —marca de tiempo, intento, SHA, racha—, que es lo que permite derivarlas con un comando. El doc publica las dos cifras rotuladas —«80 logged rounds since instrumentation» como la muestra derivable fila por fila, y 115 como el total histórico con su segunda fuente— y **nunca** una sola cifra sin decir a cuál corresponde.

   La afirmación de los aprobados en ronda 1 se sostiene sobre **ambas** fuentes, pero **se demuestra mirando la r1 de cada ciclo, no su ronda de cierre**: que un ciclo cerrara en r11 no prueba nada sobre su primera ronda, porque un ciclo contiene varios hitos y su r1 podría haber aprobado uno intermedio. La evidencia correcta es el veredicto registrado de cada primera ronda, y en los cinco ciclos previos a la instrumentación es `CHANGES_REQUESTED` en todos: `implementation/00-bootstrap.md` (r1, 6 puntos), el STATUS histórico del ciclo de plan en `2f7c814` («la ronda 1 pidió cambios, 2 puntos»), `implementation/01-installer.md` (r1, 6 puntos), `implementation/02-remote-install.md` (r1, 6 puntos) y `implementation/03-loop-hardening.md` (r1, 5 puntos). Con eso son **21 ciclos** sin un solo aprobado de entrada.
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

## Estructura del README — un párrafo y cuatro bloques

> **Procedencia de esta sección**: reescrita el 2026-08-05 como unidad `design-delta` del pipeline `/build` de esa fecha — ledger: [../implementation/pipeline-2026-08-05.md](../implementation/pipeline-2026-08-05.md) —, autorizado por su gate el mismo día («dale, autorizado», sin ajustes de alcance). Pedido literal del humano (los saltos de línea del original se marcan con «/»): «Revisa el README y hacelo FACIL. El usuario debe entender en un parrafo para que sirve, y por qué. No se por que en el README de hoy se habla de commits, y despues habla de rounds y no se que más. POR QUE ESTA DICIENDO ESTO? deberia ser simple, deberia ser: / Para que sirve? Por Que lo usaria? / Como lo instalo? / Como lo uso? / Lo esencial». Reemplaza la estructura de nueve secciones que esta sección fijó en el pipeline 2026-07-29 (3); el resto de este doc sigue vigente, con los dos ajustes que esta reescritura declara (la cláusula de la vidriera en §«Vidriera y manual» y el agregado en §«Lo que este delta no decide»).

El README deja de organizarse por temas y pasa a contestar **las preguntas del lector en el orden en que se las hace**: un **párrafo de apertura** que contesta *¿para qué sirve?* y *¿por qué lo usaría?*, y **cuatro bloques** — **¿por qué lo usaría?** (la evidencia detrás del párrafo) · **¿cómo lo instalo?** · **¿cómo lo uso?** · **lo esencial**. Los títulos exactos en inglés los elige la bajada del feature 15; qué contesta cada bloque y con qué contenido, esta sección.

### El test del párrafo de apertura

Quien nunca oyó hablar de axel, leyendo **solo ese párrafo**, puede decir qué es, para qué sirve y por qué le importaría — sin seguir ningún link. Tres reglas verificables oración por oración:

- **Cero vocabulario interno del método**: ni round, ni milestone, ni cycle, ni gate, ni RECAP, ni ledger. El vocabulario permitido es el del oficio del lector — agente, review, tests, repo.
- **Cero cifras y cero SHAs**: nada del párrafo exige contexto del repo para significar algo.
- **Autosuficiente**: el párrafo no delega su función en el bloque que sigue; el bloque la profundiza.

### Las métricas dejan la apertura

Las cifras del loop aparecen en el README **exactamente una vez** —no es opcional ni repetible: la objeción del sello de goma (criterio de aceptación, abajo) se contesta con esa mención—, dentro de «¿por qué lo usaría?», con qué cuentan dicho en la misma oración y con [../metrics.md](../metrics.md) como fuente única (regla vigente del delta anterior: ninguna cifra sin su corte y su comando). El **glosario de unidades no vuelve al README**: vive en `docs/metrics.md` §«Three units, never mixed», a un link. La precisión que decide la credibilidad —los aprobados son **hitos, no features**— sobrevive como cláusula de esa única mención, no como párrafo propio.

Esto **revierte el refinamiento 1 del delta 2026-07-29** («las cifras del título necesitan su unidad ahí mismo»). Aquella resolución era correcta en su premisa —una cifra sin unidad no significa nada— y equivocada en su consecuencia: puso cifra, unidad y glosario en la línea más alta del doc, cobrándole al lector el contexto antes de decirle qué es axel; el pedido de este pipeline es la factura de ese costo. La premisa queda: **la unidad acompaña a la cifra donde sea que aparezca**. Lo que cambia es el dónde — una sola vez, más abajo, con el contexto ya pagado.

### Mapa: de dónde sale cada bloque

| Pieza del README saliente | Destino |
|---|---|
| título + línea de posicionamiento | el párrafo de apertura absorbe su función; la prosa la decide la bajada bajo el test de arriba |
| línea de métricas + párrafo-glosario | fuera de la apertura: mención única en «¿por qué lo usaría?»; el glosario queda en `metrics.md` |
| «The problem» | se comprime dentro de «¿por qué lo usaría?» |
| «What a session actually looks like» (los dos bloques con procedencia) | **se muda entero** a un doc propio de la vidriera bajo `docs/` (inglés; path exacto: bajada del 15). Sus reglas viajan con él: dos bloques con su procedencia, ninguna línea inventada, cada línea rastreable. «¿Por qué lo usaría?» lo referencia en una línea |
| el dato externo (inquirylab) | **se queda en el README**, comprimido a una o dos líneas con su alcance honesto —un repo, del mismo autor, una adopción— dentro de «¿por qué lo usaría?»: es la respuesta a la objeción «¿funciona fuera de axel?» y no puede quedar a un link de distancia |
| «Requirements, honestly» | intacta en sustancia; **abre** «¿cómo lo instalo?» — requisitos antes del comando, regla que no se toca |
| «Install» | cierra «¿cómo lo instalo?»: el one-liner, el puntero al known issue de `build/` (sigue siendo el único problema con puntero desde el README) y el puntero al manual |
| «The commands» + el ruteo sin comandos | «¿cómo lo uso?» |
| diagrama ASCII de «How it works» | deja el README y se muda a `docs/install.md` (junto a la referencia completa de los comandos, que es el completo operativo); «¿cómo lo uso?» describe el ciclo en prosa llana — qué hace el loop y dónde frena a esperarte |
| los cinco principios de «How it works» | dejan el README como lista: su sustancia queda repartida en «¿por qué lo usaría?» (los diferenciales) y el original vive en `DESIGN.md`. No son contenido operativo: comprimirse no viola el corte |
| «What this is not» | **se comprime** en «lo esencial»: cada limitación declarada se conserva en sustancia —costo, lentitud, no autónomo, no probado a escala, español por debajo, no framework— porque el contrato editorial no permite despublicar una limitación declarada; la forma la decide la bajada |
| «Links» | cierra «lo esencial» |

**Sin pérdida operativa, verificable**: nada del dominio operativo queda documentado solo en el README ni se pierde en la mudanza — el manual ya era el completo operativo y esta reescritura no le quita nada; las dos piezas que se mudan (render de la sesión, diagrama) tienen destino nombrado en la tabla. La verificación puntual es del loop de review del feature 15.

### Lo que no cambia

- **Política de idioma**: el README y el doc del render siguen en inglés — el doc nuevo es vidriera por audiencia, igual que el README que lo referencia.
- **Contrato editorial** sobre toda la prosa nueva: hecho derivable, limitación declarada u opinión marcada.
- **Corte vidriera/manual**: el manual sigue siendo el completo en el dominio operativo y el README el extracto; al README solo entra lo que vale para todos.
- **Requisitos antes del comando de instalación.**
- **Fuente única de cifras** en `docs/metrics.md`.

### Criterio de aceptación de la prosa

1. El test del párrafo de apertura, oración por oración.
2. Cada pregunta contestada **dentro de su bloque**: el lector no necesita salir del README para saber si esto es para él; los links profundizan, no completan.
3. Las **seis objeciones** del pedido del pipeline 2026-07-29 (3) siguen vigentes como criterio — cada una contestada antes de que el lector la formule — y ahora tienen bloque asignado: costo y macOS → los requisitos de «¿cómo lo instalo?»; «el reviewer es un sello de goma» → la mención única de métricas más «el reviewer ejecuta»; «es un montón de markdown» y «está todo en español» → «lo esencial»; «¿funciona fuera de axel?» → la línea de inquirylab en «¿por qué lo usaría?».
4. **Vara de tamaño, reforzada**: una pantalla para saber si esto es para vos sigue siendo la vara — y ahora el párrafo de apertura solo ya tiene que contestarlo; la pantalla es el margen, no la meta.

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

**Delta 2026-08-05** (la reescritura de §«Estructura del README»): tampoco decide la prosa concreta del README nuevo ni el path del doc al que se muda el render de la sesión — ambos son de la bajada del feature 15, con el criterio de aceptación de esa sección como vara. Todo lo demás queda fuera de su ruta autorizada, GitHub incluido (los tres comandos pendientes siguen siendo del humano).
