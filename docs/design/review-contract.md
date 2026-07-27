# Contrato de review (generador ↔ reviewer)

## Transporte

`scripts/review.sh {new|round}` con el pedido del generador por stdin.

- `new` abre una sesión nueva de Codex — se usa al arrancar una fase o un feature.
- `round` continúa la misma sesión vía `codex exec resume`: el reviewer conserva su contexto durante todo el feature, igual que el generador conserva el suyo en el chat.
- **El reviewer corre sobre un worktree snapshot** (`.claude/state/review-worktree`) clavado al commit bajo review: su observación (lecturas y ejecución de tests) queda congelada en ese SHA, y su sandbox de escritura queda confinado al snapshot — el repo canónico no es su workspace. `review.sh` re-clava el worktree (`reset --hard` + `clean -fdx`) en cada ronda, lo que además deshace mecánicamente cualquier residuo de la ronda anterior. La sesión de Codex queda anclada al path del worktree (que es estable) porque `resume` no permite cambiar cwd.

## Qué recibe el reviewer en cada ronda

1. Preámbulo generado por `review.sh`: número de ronda, rango de commits desde el último APPROVED (`git log --oneline` + archivos), y punteros a AGENTS.md, STATUS.md y este contrato.
2. El pedido del generador: qué se hizo, qué revisar específicamente, y evidencia (tests corridos, salidas relevantes).

## Obligaciones del reviewer

- Verificar lo hecho contra DESIGN/IMPLEMENTATION: ¿coincide con lo documentado? ¿los docs quedaron al día?
- Puede ejecutar comandos (tests, builds, linters) para verificar por su cuenta — sandbox `workspace-write`, confinado a su worktree snapshot, que se resetea solo en cada ronda. El repo canónico no se toca. No corre `scripts/review.sh` (recursión) ni `scripts/awake.sh stop`.
- Feedback en puntos numerados y accionables.
- Última línea EXACTA de su respuesta: `VERDICT: APPROVED` o `VERDICT: CHANGES_REQUESTED`.

## Obligaciones del generador

- Responder cada punto numerado: corrigiendo (con commit) o argumentando por qué no. El desacuerdo se resuelve dentro del loop, no se ignora.
- No pedir review sin haber corrido sus propias verificaciones primero.
- Al menos un commit por ronda (los docs cuentan como cambio).

## Semántica del veredicto

- El veredicto es la **última línea no vacía** del mensaje del reviewer, comparada literalmente (se toleran solo espacios alrededor). Un veredicto en el medio del mensaje no cuenta: exit 2.
- Si el proceso de Codex termina con error (exit ≠ 0), **no se toma veredicto** aunque haya quedado un mensaje escrito: exit 2.
- La review queda **clavada al `REVIEW_HEAD`** capturado al armar el pedido, en dos planos: el rango/aprobación se refieren a ese SHA, y la **observación también** (el reviewer lee y ejecuta sobre el worktree snapshot de ese SHA, no sobre el árbol vivo). Commits que aparezcan durante una review larga no afectan lo que el reviewer ve ni quedan aprobados — `review.sh` avisa y entran en el próximo rango. Se eligió esto en vez de invalidar la corrida: la review de un SHA es válida para ese SHA, y con la observación congelada ya no existe el riesgo de aprobar un SHA viejo mirando archivos nuevos.
- `APPROVED` mueve la base a `REVIEW_HEAD` (`.claude/state/last-approved-sha`) y resetea la racha. Un APPROVED intermedio (p. ej. de la bajada fina) no cierra el feature; el APPROVED de cierre es contra los criterios de cierre del doc del feature.
- Sin veredicto válido → exit 2: el generador reintenta una vez y, si persiste, corta a RECAP.
- Exit codes de `review.sh`: 0 = APPROVED, 1 = CHANGES_REQUESTED, 2 = error / sin veredicto / deadlock.
- `status` muestra únicamente el **último resultado validado** (`.claude/state/last-verdict`, escrito solo cuando una corrida fue aceptada con veredicto estricto); jamás parsea el mensaje crudo del reviewer, así una corrida rechazada no puede aparentar un APPROVED.

## Deadlock

La regla de "5 rondas sin convergencia" se mide con una **racha de `CHANGES_REQUESTED` consecutivas** (`.claude/state/changes-streak`): se incrementa en cada ronda no convergida, se resetea con un APPROVED o al abrir ciclo con `new`. Al llegar a 5, `review.sh` **se niega a lanzar otra ronda** (exit 2 con `DEADLOCK` en stderr, antes de gastar tokens): el generador distingue ese caso de un error transitorio — el deadlock **no se reintenta**; arma un RECAP con ambas posturas para que desempate el humano y, tras el desempate, corre `scripts/review.sh reset-deadlock` para continuar. `status` muestra ronda y racha.

## Commits de cierre (bookkeeping)

Tras el APPROVED final de un feature, el generador hace commits de cierre (solo docs: STATUS.md, IMPLEMENTATION.md, review log) que quedan después de la base aprobada. **No mueven la base**: aparecen al inicio del rango de la ronda 1 del ciclo siguiente, donde el reviewer los verifica como primer ítem. Así ningún commit queda sin review, sin necesidad de una corrida extra por el cierre.

**Camino terminal** (no hay ciclo siguiente: fin del proyecto o pausa larga): los commits de cierre quedan cubiertos por el **OK humano del RECAP final**, que debe listarlos explícitamente como no-revisados-por-Codex; si el generador considera que el cierre tuvo sustancia más allá de bookkeeping, pide antes una mini-review (`round`) sobre esos commits.

## Ciclo de vida de sesiones

- `new` borra el session id guardado, corre `codex exec` y captura el id nuevo de los eventos JSONL (fallback: `resume --last`).
- `round` usa el id guardado en `.claude/state/codex-session-id`. Cambio de feature ⇒ siempre `new`.
- Config del reviewer: variables al tope de `review.sh`; overrides puntuales por env `AXEL_REVIEW_MODEL/EFFORT/SANDBOX` (p. ej. smoke tests con esfuerzo `low`).
- Reviews con esfuerzo xhigh pueden tardar >10 minutos: el generador corre `review.sh` en background y continúa cuando termina, sin duplicar la corrida.
- `review.sh` envuelve la invocación de Codex en `caffeinate -is` (scoped al proceso: la assertion muere con él), para que una review larga nunca se corte porque la máquina se durmió. La cobertura del lado del generador la da `scripts/awake.sh`.
