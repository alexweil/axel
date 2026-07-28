# {{PROJECT}} — proceso de desarrollo (método axel)

{{PROJECT}} se desarrolla con **axel**, una maquinaria de dos agentes en loop: **Claude Code genera, Codex revisa**, iterando hasta acuerdo, con la documentación como memoria persistente y checkpoints de OK humano.

> **Maquinaria instalada desde axel.** Las skills (`.claude/skills/`), los scripts del loop (`scripts/review.sh`, `scripts/awake.sh`), la política del loop (`.claude/axel-policy.json`) y el contrato de review (`docs/design/review-contract.md`) son archivos de la maquinaria: se actualizan re-corriendo el instalador de axel y **no se editan acá** — los cambios de maquinaria se hacen en axel. Sin un clon local de axel, la actualización es el mismo one-liner remoto de la instalación (`install.sh --from <url> <repo-destino>`, comando completo en el README de axel): clona/actualiza el cache `~/.axel` y re-corre la instalación sobre este repo. (Si tocás el método en axel, actualizá también su `templates/AGENTS.md`.)

## Sobre este proyecto

(Completar en `/adopt` o `/design`: qué es este proyecto, su objetivo y su alcance.)

## Cómo ubicarte rápido (leé en este orden)

1. Este archivo — el proceso y las reglas.
2. [docs/STATUS.md](docs/STATUS.md) — dónde estamos parados ahora mismo: fase, feature en curso, qué se está esperando.
3. [docs/DESIGN.md](docs/DESIGN.md) — el diseño a gran escala; profundizaciones por tema en `docs/design/*.md`.
4. [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) — plan priorizado y estado por feature; bajada fina y review log de cada uno en `docs/implementation/*.md`.

El contexto de chat es efímero y se descarta entre features; **el estado vive en estos documentos**. Cualquier sesión nueva debe poder reconstruir todo leyéndolos, siguiendo las referencias hasta el nivel de detalle que necesite.

Si existe `docs/ADOPTION.md`, la adopción de este proyecto quedó a medio cerrar: corré `/adopt` antes de cualquier otra fase.

## Roles

- **Generador**: Claude Code. Diseña, escribe docs y contenido, commitea, y orquesta el loop. Modelo y esfuerzo los elige el humano en la sesión.
- **Reviewer**: Codex, invocado como subproceso vía `scripts/review.sh` (config SOLO en las variables al tope de ese script). Revisa cada rango de commits, puede ejecutar tests/builds para verificar por su cuenta, y emite un veredicto. No modifica el repo.
- **Humano**: da el OK en los checkpoints (RECAP). No dirige el detalle: valida dónde estamos y qué sigue. Sus mensajes a mitad de loop tienen prioridad absoluta.

## El proceso

Fases, cada una con su skill:

1. `/adopt` — solo si hay `docs/ADOPTION.md`: cerrar la adopción (mapear docs preexistentes, derivar el estado real) antes de todo lo demás.
2. `/design` — ping-pong de ideas con el humano → consolidar `docs/DESIGN.md` → loop de review → RECAP → OK.
3. `/plan` — `docs/IMPLEMENTATION.md` con features priorizados; el orden lo acuerdan generador y reviewer → RECAP → OK.
4. `/feature` — el siguiente feature: bajada fina → review → implementación iterando con review → RECAP → OK. Se repite feature por feature, cada uno en sesión limpia.
5. `/status` y `/recap` — consulta en cualquier momento, no cambian el trabajo.

### El loop dentro de un feature

cambio → commit → `scripts/review.sh` → si `CHANGES_REQUESTED`: corregir o argumentar cada punto → commit → review (misma sesión de Codex, vía resume) → … hasta `VERDICT: APPROVED`. Tope de 5 rondas sin convergencia → RECAP temprano con las dos posturas para que desempate el humano. Contrato completo: [docs/design/review-contract.md](docs/design/review-contract.md).

### Reglas duras

- **Todo commit toca algún doc** (DESIGN/IMPLEMENTATION/STATUS o sus subdirectorios). Si hiciste algo, quedó registrado; el delta de docs es lo que el reviewer usa para saber qué verificar.
- Historia lineal en `main`, un commit por paso del loop, sin amend: el reviewer ve los deltas por rango.
- Contexto por feature: la misma sesión de Claude y la misma sesión de Codex durante todo un feature; sesiones frescas al arrancar otro.
- Nunca continuar a otro feature sin OK humano. RECAP temprano ante cambio de scope, deadlock o sorpresa grande.
- `docs/STATUS.md` se actualiza en cada commit.

## Si sos el reviewer (Codex leyendo esto durante una review)

- Tu insumo: el rango de commits indicado en el pedido, los docs modificados y el mensaje del generador.
- Verificá contra el diseño y el plan: ¿lo hecho coincide con lo documentado? ¿los docs quedaron al día?
- Trabajás sobre un **worktree snapshot** clavado al commit bajo review (se resetea solo en cada ronda): ahí podés ejecutar comandos (tests, builds, linters) para verificar por tu cuenta. El repo canónico no es tu workspace — no lo modifiques. No corras `scripts/review.sh` (recursión) ni `scripts/awake.sh stop`.
- Feedback en puntos numerados y accionables. Terminá SIEMPRE tu respuesta con una línea exacta: `VERDICT: APPROVED` o `VERDICT: CHANGES_REQUESTED`.

## Convenciones

- Docs, commits y comunicación en español. Código, nombres de archivos e identificadores en inglés.
- Modelo/esfuerzo del reviewer se tunean SOLO en `scripts/review.sh` (overrides puntuales por env `AXEL_REVIEW_*`).
- Estado local no versionado (session id de Codex, SHA del último APPROVED, ronda/racha y el registro de métricas `rounds-log`) en `.claude/state/`.
- Reviews con esfuerzo xhigh pueden tardar >10 minutos: el generador las corre en background y continúa cuando terminan.
- **La máquina no debe dormirse mientras el loop trabaja** — ni generando ni revisando. Al entrar a un loop, el generador corre `scripts/awake.sh start` (ventana renovable de 12h como backstop) y la deja corriendo durante la espera de OK; además `review.sh` envuelve cada invocación de Codex en `caffeinate`. Límite físico: tapa cerrada duerme igual, salvo con corriente y display externo.
