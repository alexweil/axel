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
4. `/status` y `/recap` — consulta en cualquier momento, no cambian el trabajo.

### El loop dentro de un feature

cambio → commit → `scripts/review.sh` → si `CHANGES_REQUESTED`: corregir o argumentar cada punto → commit → review (misma sesión de Codex, vía resume) → … hasta `VERDICT: APPROVED`. Tope de 5 rondas sin convergencia → RECAP temprano con las dos posturas para que desempate el humano. Contrato completo: [docs/design/review-contract.md](docs/design/review-contract.md).

### Reglas duras

- **Todo commit toca algún doc** (DESIGN/IMPLEMENTATION/STATUS o sus subdirectorios). Si hiciste algo, quedó registrado; el delta de docs es lo que el reviewer usa para saber qué verificar.
- Historia lineal en `main`, un commit por paso del loop, sin amend: el reviewer ve los deltas por rango.
- Contexto por feature: la misma sesión de Claude y la misma sesión de Codex durante todo un feature; sesiones frescas al arrancar otro.
- Nunca continuar a otro feature sin OK humano — salvo dentro de un **lote autorizado**: en `/feature all` / `NN..MM` la autorización del gate de lote habilita encadenar los features autorizados (cada uno queda «APPROVED — pendiente OK de lote») y el OK del RECAP consolidado es el que cierra. RECAP temprano ante cambio de scope, deadlock o sorpresa grande.
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
