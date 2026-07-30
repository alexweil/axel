# Superficie pública de axel — posicionamiento, idioma, licencia y evidencia

> Profundización de [../DESIGN.md](../DESIGN.md). **Procedencia**: delta de diseño escrito como unidad `design-delta` del **tercer** pipeline `/build` del 2026-07-29 — ledger [../implementation/pipeline-2026-07-29-3.md](../implementation/pipeline-2026-07-29-3.md) —, autorizado por su gate ese mismo día. Pedido literal del humano: «Dejar el repo público de axel presentable para compartirlo: README en inglés escrito para quien lo descubre, licencia MIT, y los docs de onboarding y feedback que faltan» (el texto completo, con su contexto y sus decisiones previas, vive en el bloque Gate del ledger). **Ajuste de alcance del gate que manda sobre esta unidad**: el pipeline **no toca GitHub ni pushea** — ni `git push`, ni topics, ni homepage; los comandos quedan listos y los corre el humano.

## El hueco

`DESIGN.md` no dice **nada** sobre la superficie pública: no hay decisión de licencia, ni política de idioma, ni criterio sobre qué va en el README frente a qué va en la guía de instalación, ni tratamiento de las métricas del loop como artefacto auditable. Las consecuencias están a la vista: el repo es público **sin licencia**; el README tiene 70 líneas y unas 50 son casuística de instalación —está escrito para quien ya decidió usar axel, no para quien lo descubre—; y la única evidencia dura de que el reviewer no es un sello de goma vive en un archivo que no está versionado.

**Principio rector del delta**: la vidriera se sostiene con la misma vara que el método. Lo que axel ofrece es auditabilidad; una vidriera que no se puede auditar contradice el producto. De ahí salen casi todas las decisiones de abajo.

## Política de idioma — tres planos

El criterio no es una lista de archivos sino un test: **el idioma lo decide la audiencia del artefacto, no su ubicación en el árbol**.

| Plano | Audiencia | Idioma | Artefactos |
|---|---|---|---|
| **Vidriera** | quien descubre axel desde afuera | **inglés** | `README.md`, `CONTRIBUTING.md`, `.github/`, `docs/install.md` |
| **Método** | los dos agentes y el humano que operan *este* repo | **español** | `AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`, los subdirectorios de `docs/`, los mensajes de commit |
| **Semilla** | el proyecto destino del instalador | **español hoy** — limitación declarada | `templates/*` y las skills de `.claude/skills/` |

Tres cosas que el criterio resuelve y una lista de archivos no resolvería:

- **`docs/install.md` va en inglés**, aunque viva bajo `docs/`. Su audiencia es el mismo lector de afuera, un paso más adelante en el embudo: es la **última milla** de la vidriera. Un corte de idioma exactamente en el punto de conversión —convencer en inglés y entregar el manual en español— es el peor lugar donde ponerlo. **Costo, declarado**: la mudanza de la casuística del README a `docs/install.md` es simultáneamente una traducción, así que la verificación de «cero pérdida» del feature 13 no puede hacerse con un diff de texto — se hace contra el contenido, caso por caso.
- **La semilla es su propio plano.** La maquinaria es agnóstica del idioma en que trabaje el destino, pero el texto que planta hoy está en español. Declararlo es gratis y honesto; traducirlo no está en el alcance de este pipeline. Es además la respuesta a la objeción «está todo en español»: la maquinaria no se entera del idioma, este repo eligió el suyo, y la semilla todavía no se tradujo.
- **Es una excepción explícita**, no una práctica tácita. `AGENTS.md` §Convenciones dice «Docs, commits y comunicación en español» sin matices, y a partir de esta decisión esa línea contradice al repo.

**Consecuencia sobre el método, que este delta no ejecuta**: corregir esa línea de `AGENTS.md` (y su espejo obligatorio en `templates/AGENTS.md`) es tocar el método, que está fuera del alcance de esta unidad. Queda registrada acá para que el plan decida dónde entra —el arreglo mínimo es un puntero a esta decisión— y no para que se olvide.

## Licencia: MIT

Hoy el repo es público sin licencia, o sea legalmente «todos los derechos reservados», lo que contradice de frente que su propuesta central sea «instalalo en tu proyecto». **MIT**: permisiva, corta, universalmente reconocida y sin fricción para el destino — es justamente la licencia que vuelve legalmente trivial la operación central del instalador, que es copiar archivos dentro del repo de otro, con su propia licencia.

Titular y año se confirman en la bajada del feature 13; no se inventan acá.

**Consecuencia abierta, registrada y fuera del alcance de este pipeline**: MIT pide que el aviso de copyright y permiso viaje con las porciones sustanciales del software, y el instalador copia skills, scripts y contrato dentro de los destinos sin que hoy nada lleve ese aviso. No somos abogados y esto no bloquea publicar. La mitigación barata **sí** está en alcance: `docs/install.md` declara bajo qué licencia queda lo instalado y dónde vive el aviso. Hacer que el instalador lo copie toca el instalador ⇒ fuera de alcance; queda anotado acá, sin entrada de backlog, porque el humano dejó el trabajo sobre el instalador afuera de este pipeline.

## Vidriera y manual: el criterio de corte

Test aplicable línea a línea, no un reparto puntual:

- El **README** contesta *«¿esto es para mí?»*. El **manual** (`docs/install.md`) contesta *«¿cómo lo hago andar?»*.
- **Al README solo entra lo que vale para todos.** Toda frase que empiece con «si…» o «salvo que…» describe un caso, y los casos van al manual. El README puede llevar un **puntero** a un caso; nunca el caso.
- **El manual es el completo; el README es el extracto.** Nada queda documentado *solo* en el README — con lo cual la mudanza es sin pérdida por construcción, y el criterio de verificación del feature 13 tiene contra qué chequearse.
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
- **Contra-chequeo independiente** — cada fila del log nombra un SHA. Un tercero puede verificar que esos commits existen en `main` y que sus fechas cierran: la métrica no se apoya solo en «confiá en el archivo», se cruza contra una historia lineal y sin amend que nadie reescribió.
- **Re-corte** — una corrida futura vuelve a correr el comando sobre un snapshot fresco. El criterio queda escrito, así que no se reinventa.

### La unidad de conteo, que es lo que decide la credibilidad

Hay **tres** unidades y no se mezclan:

| Unidad | Qué es | Al corte `e1e1282` |
|---|---|---|
| **ronda** | una invocación de `review.sh` con veredicto | **80** |
| **hito** | un tramo que termina en `APPROVED` (bajada fina, implementación, un ciclo de plan o de diseño) | **27** |
| **ciclo** | una sesión de Codex, de `new` hasta su cierre — hoy ≈ un feature o una unidad de pipeline | **16** |

Los `APPROVED` son **hitos, no features**: por eso hay más aprobados que features, y enunciarlo mal es exactamente lo que destruye credibilidad. Dos hallazgos de este delta que el doc de métricas tiene que incorporar, porque fijan el criterio y no solo el número:

1. **«Cero aprobados en ronda 1» es cierto por ciclo y falso por hito.** Ningún ciclo volvió `APPROVED` en su primera ronda; pero hay exactamente **un hito** aprobado sin ningún rechazo en su tramo (`2dbbdfc`, feature 07 «paso A», 2026-07-28, aprobado en la ronda 4 inmediatamente después del `APPROVED` de la ronda 3). Lo mismo pasa con las otras dos cifras: la mediana es **4 por ciclo** y **3 por hito**, y el peor caso **11 por ciclo** y **5 por hito**. Publicar una mediana de una unidad al lado de un conteo de otra es precisamente el error contra el que advertía el pedido. **La formulación defendible nombra la unidad**: «80 review rounds, 53 rejections, zero review cycles approved on the first round».
2. **El log arranca el día 2: las cifras son un piso, no un total.** La primera fila es `2026-07-28 00:10` y ya es la `round 6` de un ciclo en curso — el registro de métricas llegó con el feature 03, así que todo el 2026-07-27 (49 commits, y las rondas de review de los features 00 y 01) queda afuera. El número real de rondas es **mayor** que el publicado. Subdeclara, así que declararlo no cuesta nada y cierra el agujero antes de que lo encuentre otro.

Además, por criterio: las filas de eventos **pre-invocación** (`DEADLOCK`, `INPUT_ERROR`) llevan `-` en ronda, intento y SHA, y **no** cuentan como rondas. Hoy no hay ninguna, pero el criterio debe decirlo para que un re-corte futuro no infle el conteo sin darse cuenta.

**El gancho tiene el mismo problema que las métricas.** «Se construyó a sí mismo: N commits en tres días, M features» son cifras que se mueven con cada corrida —este pipeline incluido— y les rige la misma regla: corte, comando y fuente única.

## El transcript de «What a session actually looks like»

El gate delegó esta pregunta explícitamente a esta unidad. Los candidatos eran la adopción de inquirylab (real y externa, pero es un `/adopt` y no el loop con `CHANGES_REQUESTED` → RECAP → OK que la sección promete), un loop real de axel (tiene el ciclo completo, pero axel diseñándose a sí mismo es recursivo y confuso para quien recién llega), o un compuesto declarado como tal (la recomendación no vinculante del padre).

**Decisión: dos bloques uno al lado del otro, cada uno con su procedencia — no una sesión mezclada.**

La razón sale del propio principio de axel: el chat es efímero y la memoria es el repo. **No hay transcript de sesión que capturar**, y publicar un log de chat con aspecto de reconstruido, en un proyecto cuya propuesta central es la auditabilidad, es lo más dañino que podría hacer. Entonces:

- **Bloque 1 — el loop**, renderizado desde el repo: el rango de commits, la ronda que volvió `CHANGES_REQUESTED` con lo que atrapó, la corrección y el `APPROVED`. Candidato citable que trae el pedido: `74d3f5c` («feature 11 r5: … tres defectos invisibles en la lectura del texto nuevo») — que es el commit de la **corrección**, así que la bajada debe citar también la ronda que los encontró, no solo el arreglo. Es recursivo por construcción —axel sobre axel— y eso es el gancho, declarado, no escondido.
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
