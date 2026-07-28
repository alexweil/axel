# axel — Implementación

> Plan a gran escala y estado por feature. La bajada fina de cada feature vive en `docs/implementation/NN-nombre.md`, con sus decisiones y su review log. La posición actual está en [STATUS.md](STATUS.md).

## Cómo se trabaja un feature

Sesión limpia → `/feature` → bajada fina → review → implementación con loop de review → RECAP → OK humano. Reglas en [AGENTS.md](../AGENTS.md); contrato de review en [design/review-contract.md](design/review-contract.md).

## Criterio de orden

1. **Restricciones humanas fijan posiciones**: los pedidos explícitos del humano no se discuten entre agentes (hoy: instalador 01 primero, 2026-07-27).
2. **Valor desbloqueado antes que pulido**: primero lo que habilita uso nuevo (llevar axel a otros proyectos) sobre lo que mejora lo que ya funciona.
3. **Núcleo antes que confort**: desbloqueado el valor nuevo, primero consolidar el código safety-critical de uso diario — prioridad por riesgo × centralidad × radio de daño (`review.sh` y `awake.sh` ejecutan `reset --hard`, `clean -fdx` y señales de procesos en cada ciclo) — y recién después la calidad de vida.

## Features

| # | Feature | Estado | Doc |
|---|---|---|---|
| 00 | Bootstrap de la maquinaria | **Cerrado** — APPROVED de Codex (r4) + OK humano, 2026-07-27 | [implementation/00-bootstrap.md](implementation/00-bootstrap.md) |
| 01 | Instalador: llevar axel a otro proyecto | **Cerrado** — APPROVED de Codex (r11) + OK humano, 2026-07-27 | [implementation/01-installer.md](implementation/01-installer.md) |
| 02 | Instalación remota: one-liner desde GitHub | **Cerrado** — APPROVED de Codex (r10) + OK humano, 2026-07-27 | [implementation/02-remote-install.md](implementation/02-remote-install.md) |
| 03 | Hardening del loop de review | **Cerrado** — APPROVED de Codex (r8) + OK humano, 2026-07-28 | [implementation/03-loop-hardening.md](implementation/03-loop-hardening.md) |
| 04 | Notificaciones y continuidad entre sesiones | **En curso** — bajada APPROVED (r3); implementación en review, 2026-07-28 | [implementation/04-notifications-continuity.md](implementation/04-notifications-continuity.md) |

**Orden acordado** entre generador y reviewer: APPROVED del ciclo de `/plan` en su ronda 5 (2026-07-27, base `5b1bc02`) — "queda acordado el plan: 01 instalador → 02 hardening con suite de regresión central → 03 notificaciones, derivado de los tres criterios documentados". OK humano del plan: recibido el 2026-07-27 (registrado en `860c80b`). **Nota de numeración**: esa cita usa la numeración original del plan; con el OK del 01 (2026-07-27) el humano insertó *instalación remota* como 02 (criterio 1), corriendo hardening a 03 y notificaciones a 04 — el orden relativo acordado entre agentes no cambió.

### 01 — Instalador

Un comando que instala la maquinaria en un repo destino: copia `.claude/skills/`, `scripts/` (review.sh, awake.sh) y `.claude/settings.json`, y siembra `AGENTS.md` + symlink `CLAUDE.md` + estructura `docs/` con plantillas. axel es la fuente de verdad; los proyectos consumidores se actualizan re-corriendo el instalador.

Requisito clave (pedido humano 2026-07-27): **modo adopción** para proyectos existentes que ya vienen siguiendo el proceso a mano — detectar docs preexistentes (DESIGN/IMPLEMENTATION o equivalentes), no pisar nada, mapear lo que ya hay a la convención de axel, sembrar solo lo que falte y derivar el `STATUS.md` inicial del estado real del proyecto.

### 02 — Instalación remota (one-liner)

Pedido humano (2026-07-27, al dar el OK del 01): instalar axel en un destino **sin clon local previo** — un solo comando que baje axel (GitHub) y corra la instalación de una, más la sección del README pensada para que un agente en Claude Code la lea y la siga ("instalá axel siguiendo <url>"), cubriendo también el camino desde adentro de una sesión (las skills se cargan en caliente; el settings rige pleno en la sesión siguiente). Prerequisito **cumplido** (2026-07-27, pedido y visibilidad confirmados por el humano): axel publicado en https://github.com/alexweil/axel (público, `main` como remote `origin`). Enfoque decidido en la bajada (2026-07-27): `install.sh --from <url>` con cache fail-closed en `AXEL_HOME` (default `~/.axel`) — solo ff-update de un cache limpio en el branch default real del remoto (ancestría explícita contra `ls-remote`/fetch por URL, sin confiar en metadata local), disjunción cache/lock↔destino pre-clone, lock atómico sin auto-reclaim — que delega en el `install.sh` del clon propagando solo sus exit codes contractuales (0/1/2); el instalador local no cambia de contrato. Bajada fina: [implementation/02-remote-install.md](implementation/02-remote-install.md).

### 03 — Hardening del loop

Pieza central (pedido del reviewer en el ciclo de plan): **suite de regresión reproducible** para el estado del loop y sus caminos de seguridad — las siete clases de falla que el ciclo 00 encontró a mano y quedaron sin prueba automatizada: parser de veredicto + gate de RC, consistencia del estado (`last-verdict`, base, racha), bloqueo de deadlock, `wt_valid` contra directorios impostores, tri-estado y `kill_confirmed` de awake.sh, movimiento de base a `REVIEW_HEAD`, y **congelamiento de la observación**: el worktree del reviewer queda re-clavado al `REVIEW_HEAD` del pedido aunque el HEAD canónico avance durante la review (regresión distinta del movimiento de base y del rechazo de impostores). Ejecutable sin invocar a Codex (doble del binario vía PATH).

Además: captura robusta del session id (hoy: primer UUID de los eventos JSONL, con fallback `resume --last`), reintentos ante fallas transitorias de Codex, métricas de rondas por feature, y `shellcheck` instalado y corriendo sobre los scripts (el reviewer lo buscó en las 4 rondas del ciclo 00 sin encontrarlo).

### 04 — Notificaciones y continuidad

Push de RECAP consistente en todos los caminos, y facilitar el arranque de la siguiente sesión limpia tras el OK (chip de spawn en desktop / instrucción única).
