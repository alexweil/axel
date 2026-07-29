# Entrada implícita: ruteo por contexto y pipeline `/build`

> Profundización de [DESIGN.md](../DESIGN.md). Diseño acordado en ping-pong con el humano el 2026-07-28/29: dos niveles incrementales en este orden, reencuadre del nivel 2 como pipeline por pedido (el POC como caso particular, no como la skill), nombre `/build` validado con el requisito de que pueda dispararse por contexto, sin comando. Esto es diseño: la implementación entra al plan vía `/plan` como cualquier feature.

## Objetivo

Que la maquinaria se pueda usar sin conocer sus comandos. El humano describe lo que quiere — una idea, un proyecto, una funcionalidad — y axel detecta por contexto qué fase o fases corresponden, frenando solo en los puntos de confirmación que el método ya tiene. Dos niveles:

- **Nivel 1 — ruteo implícito**: un pedido sin comando se despacha a la fase correcta. Ataca el costo de entrada (saber qué comando invocar).
- **Nivel 2 — pipeline `/build`**: un pedido que cruza varias fases las encadena de corrido con una autorización al inicio y un OK consolidado al final. Ataca la latencia entre la visión del humano y un resultado visible — en proyecto virgen, el POC.

Los comandos explícitos no cambian: la entrada implícita es una capa encima, no un reemplazo.

## Nivel 1 — ruteo implícito

### Mecanismo (dos piezas, sin maquinaria nueva)

1. **Descripciones de skills como triggers.** Hoy las `description` nombran la fase («Fase de diseño — …»); pasan a describir cuándo dispararse por contexto («cuando el humano describe una idea o proyecto nuevo, aunque no invoque /design», «cuando pide avanzar con la implementación o el siguiente paso», …). Es el mecanismo estándar de skills: el modelo invoca la que matchea la tarea.
2. **Sección de ruteo en `AGENTS.md`** (espejo obligatorio en `templates/AGENTS.md`): ante un pedido de trabajo sin comando explícito, leer `docs/STATUS.md` y despachar según la tabla. STATUS.md ya es el despachador natural — solo falta la instrucción de usarlo como tal.

### Tabla de despacho

| Situación (STATUS + docs) | Despacho |
|---|---|
| Pedido de consulta («¿dónde estamos?», «¿qué falta?») | `/status` o `/recap` |
| Adopción pendiente (`docs/ADOPTION.md` presente sin cerrar) | `/adopt` |
| Sin diseño real (no hay `DESIGN.md` o es la semilla del instalador) | `/design` |
| Diseño cerrado, sin plan o backlog vacío | `/plan` |
| Plan con features pendientes y pedido de avanzar | `/feature` (con `all`/rango si el pedido pide varios de corrido, ver abajo) |
| Pedido que cruza dos o más fases | `/build` (nivel 2) |
| STATUS en espera (OK pendiente, confirmación de arranque, lote o pipeline en curso) | el camino de reentrada que las skills ya definen — el ruteo no los puentea |
| Ambiguo entre dos despachos | preguntar en una línea; no adivinar |

### Regla de confirmación

**El ruteo nunca arranca trabajo sin un punto de confirmación.** Usa el gate propio de la fase donde existe, y donde no existe agrega uno mínimo:

- `/design`: el ping-pong ES la confirmación — la skill ya prohíbe escribir docs grandes sin validar el rumbo.
- `/feature`: gate de arranque existente (resumen + confirmación humana).
- `/build`: gate de pipeline (nivel 2, abajo).
- `/plan`: no tiene gate propio — **cuando llega ruteado**, el generador anuncia su interpretación y espera una confirmación liviana antes de escribir. La invocación explícita `/plan` no cambia.

El gate cumple así doble función: confirma el arranque y confirma que el ruteo interpretó bien el pedido.

### Ruteo al modo lote: reinterpretación del opt-in

[batch-features.md](batch-features.md) fijó «no hay modo batch implícito». Con la entrada implícita esa regla se **reinterpreta**: lo que protege el opt-in no es la forma de invocación sino la **autorización del gate de lote**. Un pedido en lenguaje natural inequívoco («hacé todos los pendientes de corrido») puede despachar a `/feature all`; el gate de lote sigue presentando los N resúmenes y la autorización global sigue siendo el habilitante. Ante un pedido dudoso sobre cuántos features abarca, el ruteo pregunta (regla de ambigüedad). La nota queda registrada también en batch-features.md.

### Qué NO hace el ruteo

- **No rutea mensajes a mitad de loop.** La prioridad absoluta del humano ya cubre ese caso; si el mensaje implica cambio de scope, aplica el RECAP temprano (regla existente).
- **No saltea esperas.** STATUS en espera manda: el ruteo entrega al camino de reentrada de la skill correspondiente, nunca lo puentea.
- **No reemplaza los comandos.** `/design`, `/plan`, `/feature` explícitos funcionan exactamente igual que hoy.

## Nivel 2 — pipeline `/build`

### Superficie

- `/build <pedido>` explícito, o **disparo implícito** vía nivel 1 — requisito del diseño: el humano describe lo que quiere y el pipeline se ofrece solo, sin que exista obligación de conocer el comando.
- Pedido que toca **una sola fase** → no hay pipeline: despacho directo a la skill de esa fase, con su gate. Un `/build` explícito monofase lo anuncia y despacha igual.

### Alcance por pedido

El generador lee STATUS/DESIGN/IMPLEMENTATION y deriva la **ruta**: ¿el pedido cambia el diseño? → delta de design. ¿Agrega o reordena features? → delta de plan. ¿Implementa? → feature(s). Cada fase trabaja un **delta acotado al pedido**, no una pasada completa del proyecto. El plan-delta prioriza que el **resultado visible llegue lo antes posible** — es el principio POC-first generalizado: primero lo que el humano puede ver y sobre lo que puede iterar.

### Gate de pipeline

Análogo al gate de lote: un solo mensaje con la ruta propuesta — qué fases, el resumen del delta de cada una (derivado de los docs), qué features y qué va a haber **visible** al final — y **una autorización global** habilita encadenar. Correcciones puntuales del humano quedan registradas como ajustes de alcance en el ledger. El gate llega por respuesta directa → sin push.

### Semántica de los checkpoints

Idéntica en estructura a la del lote:

- El **gate de pipeline** es la **autorización de ejecución**. No cierra nada.
- El **APPROVED de Codex por unidad no cambia**: gate de calidad con su loop completo de rondas.
- Una unidad aprobada queda **«APPROVED — pendiente OK de pipeline»**.
- El **OK del RECAP consolidado cierra todo**; su transcripción de cierre usa la excepción del commit de registro del OK ([review-contract.md](review-contract.md)), como en el lote.

Esto **extiende la regla dura** redefinida por el lote: «nunca continuar a otro feature (ni cruzar a otra fase) sin OK humano — salvo dentro de un **lote o pipeline autorizado**». La implementación refleja la redacción en `AGENTS.md` y `templates/AGENTS.md` (regla de sincronía).

### Arquitectura: el patrón del lote con unidades tipadas

El pipeline **reusa los contratos de [batch-features.md](batch-features.md)** generalizando la unidad de trabajo de «feature» a **unidad tipada**: `design-delta`, `plan-delta` o `feature`.

- **Padre orquestador** = la sesión que el humano abrió: panel de control, liviano, supervisa la señal terminal de `review.sh` y empuja sin transportar feedback. Mensajes del humano a mitad de pipeline llegan al padre con prioridad absoluta.
- **Hijo fresco por unidad** (la frontera de contexto que el método exige): corre la fase completa él mismo — consolidación o implementación, commits, su loop de review vía `review.sh` (`new` al arrancar la unidad, `round` en cada ronda) — y termina el turno con la línea de estado del contrato del lote.
- **Sin lote anidado**: si la etapa de implementación tiene varios features, cada uno es una **unidad hermana** del pipeline — un solo padre, un solo ledger por corrida. No hay orquestadores dentro de orquestadores.
- **Ledger versionado por corrida** con el mismo contrato del lote: ruta autorizada con los resúmenes tal como se autorizaron, estado por unidad, cortes con motivo, reentrada **fail-closed** idéntica (estado consistente → relanzar hijo fresco; inconsistencia → RECAP sin adivinar; nunca re-pedir el gate de lo autorizado ni re-cerrar lo aprobado).
- **Condiciones de corte**: las del lote — fallas del loop, cambio de scope o sorpresa, **divergencia** (el resumen re-derivado al arrancar la unidad N no coincide en sustancia con el autorizado — cubre el caso «el design-delta aprobado invalidó lo que se autorizó para el plan-delta»), fuentes insuficientes — con RECAP + push + corte registrado en el ledger.
- Si el modo lote actual y el pipeline convergen en una sola implementación (orquestador/ledger comunes) es decisión de la bajada; el diseño fija que **los contratos son los mismos**.

### Reviews por unidad: loop completo, criterio acotado al delta

Cada unidad mantiene su loop de review completo hasta APPROVED — el corazón de dos agentes no se negocia. Lo que cambia es el **marco del pedido de review**: revisar el delta contra el pedido autorizado y su escala declarada. En modo borrador (proyecto virgen): «diseño borrador para POC — revisá que alcance para el esqueleto, no exhaustividad». *(Decisión tomada por el generador ante silencio del humano en el ping-pong; revisable.)*

### Caso particular: proyecto virgen (POC-first)

El caso que motivó el diseño, resuelto como instancia del pipeline y no como skill aparte:

- El pedido es **la visión entera** del humano.
- El delta de design es un `DESIGN.md` **mínimo, marcado «borrador (modo POC)»**: honesto sobre su escala, endurecible después.
- El plan nace con **feature 01 = esqueleto que camina**; el resultado visible del pipeline es el POC.
- El ping-pong largo de `/design` se **comprime en el gate de pipeline**: visión + boceto + autorización. La conversación profunda se recupera en el endurecimiento, con el POC a la vista — mejor insumo para plasmar la visión del humano que un diseño en abstracto.
- **Post-OK: endurecimiento recomendado, no forzado.** El RECAP consolidado ofrece dos caminos — endurecer design/plan (pasadas de `/design`/`/plan` que cierran el marker) o seguir iterando features sobre el borrador — y elige el humano con el POC a la vista. El marker «borrador» queda visible en los docs hasta que una pasada lo cierre. *(Decisión tomada por el generador ante silencio del humano; revisable.)*

### Encaje con reglas existentes

- **Avisos** (skill `recap`): gate de pipeline = respuesta directa → sin push; RECAP consolidado y todo corte = trabajo autónomo → push de una línea.
- **awake.sh**: el padre renueva la ventana al arrancar cada unidad.
- **Métricas**: `rounds-log` por unidad, como hoy.
- **Commits no revisados**: mismo esquema del lote — los commits de estado de una unidad los barre la r1 de la unidad siguiente; los del final quedan listados en el RECAP consolidado (el OK los cubre); el cierre post-OK usa la excepción del commit de registro del OK.
- **Modelos por unidad**: hoy el humano elige modelo por sesión/fase; en pipeline el padre puede aplicar el esquema por tipo de unidad (override de modelo del subagente). Detalle en la bajada.
- **Instalador**: las skills y `templates/AGENTS.md` son payload — la entrada implícita completa (triggers, ruteo, `/build`) viaja a los proyectos destino con el re-run de actualización.

### Riesgo aceptado

Extiende el del lote: un error en el delta de design se propaga al plan y a los features antes del ojo humano, y el radio de recuperación es el **sufijo desde la unidad errada** (mismo análisis y misma recuperación conservadora: corte sin rollback automático, el humano decide con el RECAP a la vista). Lo acotan el gate (la ruta se autoriza explícita, con los deltas resumidos), el corte por divergencia entre unidades, y que el camino con OK por fase sigue disponible — los comandos explícitos no cambian. En proyecto virgen el radio es menor: no hay docs previos que corromper y el POC mismo es la validación.

## Decisiones que quedan para la bajada (no exhaustivo)

- Redacción exacta de las descripciones-trigger y de la sección de ruteo en `AGENTS.md` (+ espejo en `templates/AGENTS.md`).
- Forma exacta de la confirmación liviana de `/plan` ruteado.
- Ledger de pipeline: ¿generalización del ledger del lote o uno propio con el mismo contrato? Nombre, plantilla, tipos de unidad.
- Relación de implementación entre `/feature all` y la etapa multi-feature del pipeline (contratos ya unificados por diseño; código a decidir).
- Forma del marker «borrador (modo POC)» y de la pasada que lo cierra.
- Overrides de modelo por tipo de unidad en el subagente.
- Validación del pedido de `/build` (vacío, que no toca ninguna fase, contradictorio con STATUS).
