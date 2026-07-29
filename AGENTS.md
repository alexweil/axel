# axel — máquina de desarrollo generador/reviewer

axel es una maquinaria reusable para desarrollar proyectos (software, contenido, cualquier cosa que genere un agente) con un loop de dos agentes: **Claude Code genera, Codex revisa**, iterando hasta acuerdo, con la documentación como memoria persistente y checkpoints de OK humano. Este repo ES la maquinaria, y se desarrolla a sí misma usando su propio método.

## Cómo ubicarte rápido (leé en este orden)

1. Este archivo — el proceso y las reglas.
2. [docs/STATUS.md](docs/STATUS.md) — dónde estamos parados ahora mismo: fase, feature en curso, qué se está esperando.
3. [docs/DESIGN.md](docs/DESIGN.md) — el diseño a gran escala; profundizaciones por tema en `docs/design/*.md`.
4. [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) — plan priorizado y estado por feature; bajada fina y review log de cada uno en `docs/implementation/*.md`.

El contexto de chat es efímero y se descarta entre features; **el estado vive en estos documentos**. Cualquier sesión nueva debe poder reconstruir todo leyéndolos, siguiendo las referencias hasta el nivel de detalle que necesite.

## Roles

- **Generador**: Claude Code (hoy: esquema mixto por fase — Fable 5 para `/design` y `/plan`, Opus 5 para `/feature`, esfuerzo xhigh; lo elige el humano en la sesión). Diseña, escribe docs y código, commitea, y orquesta el loop.
- **Reviewer**: Codex, invocado como subproceso vía `scripts/review.sh` (hoy: gpt-5.6-sol, esfuerzo xhigh — config SOLO en las variables al tope de ese script). Revisa cada rango de commits, puede ejecutar tests/builds para verificar por su cuenta, y emite un veredicto. No modifica el repo.
- **Humano**: da el OK en los checkpoints (RECAP). No dirige el detalle: valida dónde estamos y qué sigue. Sus mensajes a mitad de loop tienen prioridad absoluta.

## El proceso

Fases, cada una con su skill:

1. `/design` — ping-pong de ideas con el humano → consolidar `docs/DESIGN.md` → loop de review → RECAP → OK.
2. `/plan` — `docs/IMPLEMENTATION.md` con features priorizados; el orden lo acuerdan generador y reviewer → RECAP → OK.
3. `/feature` — el siguiente feature: gate de arranque (resumen breve + confirmación humana) → bajada fina → review → implementación iterando con review → RECAP → OK. Se repite feature por feature, cada uno en sesión limpia. **Modo lote**: `/feature all` o `/feature NN..MM` corre varios features pendientes en una sola corrida — gate de lote al inicio, un subagente fresco por feature, RECAP consolidado al final cuyo OK cierra ([docs/design/batch-features.md](docs/design/batch-features.md)).
4. `/build` — **pipeline por pedido**: cuando lo pedido cruza dos o más fases, encadena los deltas necesarios (design-delta → plan-delta → feature(s)) en una sola corrida — gate único con la ruta propuesta y una autorización global, un subagente fresco por unidad con su loop de review, cada unidad aprobada queda «APPROVED — pendiente OK de pipeline», y el OK del RECAP consolidado cierra todo. Ledger versionado por corrida, como el lote. En proyecto virgen es el camino POC-first: visión → diseño borrador → plan con feature 01 = esqueleto que camina → POC visible ([docs/design/implicit-entry.md](docs/design/implicit-entry.md)).
5. `/status` — consulta en cualquier momento: lectura pura, no cambia nada. `/recap` — **checkpoint a demanda**: no es consulta (fija «esperando OK» en STATUS, commitea y frena el turno); se pide explícitamente, o lo invocan las skills de fase al cerrar.

### Ruteo: un pedido sin comando

No hace falta conocer los comandos. Ante un pedido **sin comando explícito**, leé `docs/STATUS.md` y aplicá este orden — **el primer caso que aplica gana**, y los casos de estado pendiente preceden siempre a la clasificación del pedido (un pedido nuevo no puentea una espera):

1. **Consulta** («¿dónde estamos?», «¿qué falta?», «¿cómo viene?») → **`/status` y nada más**: lectura pura, disponible en cualquier estado. `/recap` **no** es consulta: se elige solo ante un pedido explícito de RECAP o checkpoint — a mitad de loop, eso equivale a pedir un checkpoint temprano.
2. **Estado pendiente manda** → el pedido entra por la **reentrada de la skill dueña**, nunca como trabajo nuevo: adopción sin cerrar (`docs/ADOPTION.md`) → `/adopt`; corte de lote registrado, OK humano pendiente, confirmación de plan pendiente, confirmación de arranque o autorización de lote pendientes, review lanzada sin desenlace consumido, o fase/feature/lote activo → la skill de esa fase, por su rama de reentrada.
3. **Solo desde estado estable** (nada activo ni esperando) se clasifica el pedido, **por lo que necesita** y no por lo que los docs tengan: armar o extender el diseño → `/design` (incluye: no hay `DESIGN.md` real, solo la semilla del instalador); armar, extender o repriorizar el plan → `/plan`; avanzar con features ya planificados → `/feature` (con `all` o rango si pide varios de corrido); pedido que necesita **dos o más fases** → `/build` (ver «Multifase», abajo).
4. **Ambigüedad en cualquier paso** → preguntá **en una línea**. No adivines.

**Qué cuenta como comando explícito** (regla posicional, no interpretativa): tras los espacios iniciales, el **primer token** del pedido es `/adopt`, `/design`, `/plan`, `/feature`, `/build`, `/status` o `/recap`, con o sin argumentos. Solo eso es invocación explícita, y esos caminos funcionan **igual que hoy**. El comando en cualquier otra posición es **mención**, no invocación («¿qué hace `/feature` cuando se corta un lote?»): no se ejecuta — se responde o se pregunta.

**El ruteo nunca arranca trabajo sin un punto de confirmación**: usa el de la fase donde existe (`/feature`, gate de arranque; `/design`, el ping-pong; `/build`, gate de pipeline; `/adopt`, pregunta cada punto de juicio) y donde no existe lo agrega — `/plan` despachado registra su interpretación en STATUS, la presenta y espera una confirmación liviana antes de escribir; la invocación explícita directa de `/plan` queda como hoy.

**Multifase → `/build`**: si el pedido necesita dos o más fases, va al **pipeline** — un gate único presenta la ruta (qué fases, el resumen de cada delta, qué habrá **visible** al final) y una autorización global habilita encadenarlas, con un subagente fresco por unidad y un RECAP consolidado cuyo OK cierra. Pedido de **una sola** fase ⇒ despacho directo a la skill de esa fase con su punto de confirmación: `/build` **no cuenta como autorización** — la autorización es siempre la de un gate. Y `/build` es el **único** comando explícito que **no puentea estado pendiente**: sobre una espera abierta entra por la reentrada de la skill dueña (encadenaría la espera sin resolver a través de N unidades).

**Modo lote**: un pedido inequívoco de correr varios features de corrido («hacé todos los pendientes») puede despachar a `/feature all` o a un rango — lo que habilita el lote es la **autorización del gate**, no la forma de invocación. Si no está claro cuántos features abarca, preguntá.

Lo que el ruteo **no** hace: no rutea mensajes a mitad de loop (la prioridad absoluta del humano ya los cubre; si cambian el scope, RECAP temprano), no saltea esperas, y no reemplaza los comandos. Cada skill trae además su **guarda de entrada**, que hace valer «estado pendiente manda» aunque esta sección falte.

### El loop dentro de un feature

cambio → commit → `scripts/review.sh` → si `CHANGES_REQUESTED`: corregir o argumentar cada punto → commit → review (misma sesión de Codex, vía resume) → … hasta `VERDICT: APPROVED`. Tope de 5 rondas sin convergencia → RECAP temprano con las dos posturas para que desempate el humano. Contrato completo: [docs/design/review-contract.md](docs/design/review-contract.md).

### Reglas duras

- **Todo commit toca algún doc** (DESIGN/IMPLEMENTATION/STATUS o sus subdirectorios). Si hiciste algo, quedó registrado; el delta de docs es lo que el reviewer usa para saber qué verificar.
- Historia lineal en `main`, un commit por paso del loop, sin amend: el reviewer ve los deltas por rango.
- Contexto por feature: la misma sesión de Claude y la misma sesión de Codex durante todo un feature; sesiones frescas al arrancar otro.
- Nunca continuar a otro feature **ni cruzar a otra fase** sin OK humano — salvo dentro de un **lote o pipeline autorizado**: la autorización del gate (de lote en `/feature all` / `NN..MM`, de pipeline en `/build`) habilita encadenar las unidades autorizadas (cada una queda «APPROVED — pendiente OK de lote» o «— pendiente OK de pipeline») y el OK del RECAP consolidado es el que cierra. RECAP temprano ante cambio de scope, deadlock o sorpresa grande.
- `docs/STATUS.md` se actualiza en cada commit.

## Si sos el reviewer (Codex leyendo esto durante una review)

- Tu insumo: el rango de commits indicado en el pedido, los docs modificados y el mensaje del generador.
- Verificá contra el diseño y el plan: ¿lo hecho coincide con lo documentado? ¿los docs quedaron al día?
- Trabajás sobre un **worktree snapshot** clavado al commit bajo review (se resetea solo en cada ronda): ahí podés ejecutar comandos (tests, builds, linters) para verificar por tu cuenta. El repo canónico no es tu workspace — no lo modifiques. No corras `scripts/review.sh` (recursión) ni `scripts/awake.sh stop`.
- Feedback en puntos numerados y accionables. Terminá SIEMPRE tu respuesta con una línea exacta: `VERDICT: APPROVED` o `VERDICT: CHANGES_REQUESTED`.

## Convenciones

- Docs, commits y comunicación en español. Código, nombres de archivos e identificadores en inglés.
- **El método está duplicado en `templates/AGENTS.md`** (lo que el instalador siembra en otros proyectos): si tocás el proceso o las reglas en este archivo, actualizá también la plantilla — y viceversa.
- Modelo/esfuerzo del reviewer se tunean SOLO en `scripts/review.sh` (overrides puntuales por env `AXEL_REVIEW_*`).
- Estado local no versionado (session id de Codex, SHA del último APPROVED, ronda/racha y el registro de métricas `rounds-log`) en `.claude/state/`.
- **Reentradas fail-closed**: si una sesión muere a mitad de un loop, la que reabre reconstruye desde STATUS + los docs + `.claude/state/` — sin relanzar una review que pueda estar en vuelo y sin adivinar. El contrato (token de ronda en STATUS, resolución del desenlace, precondición de la ronda siguiente) vive en [docs/design/review-contract.md](docs/design/review-contract.md) §Reentrada; el mapa por fase, en cada skill.
- Reviews con esfuerzo xhigh pueden tardar >10 minutos: el generador las corre en background y continúa cuando terminan.
- Avisos y continuidad: una espera de OK alcanzada por trabajo autónomo se avisa al humano con un push de una línea, y tras un OK que cierra fase o feature se facilita el arranque de la sesión limpia siguiente (chip de spawn o instrucción única). El protocolo vive en la skill `recap` y en las skills de fase — esta línea solo lo referencia.
- **La máquina no debe dormirse mientras el loop trabaja** — ni generando ni revisando. Al entrar a un loop, el generador corre `scripts/awake.sh start` (ventana renovable de 12h como backstop) y la deja corriendo durante la espera de OK; además `review.sh` envuelve cada invocación de Codex en `caffeinate`. Límite físico: tapa cerrada duerme igual, salvo con corriente y display externo.
