# Contrato de review (generador ↔ reviewer)

## Transporte

`scripts/review.sh {new|round}` con el pedido del generador por stdin.

- `new` abre una sesión nueva de Codex — se usa al arrancar una fase o un feature.
- `round` continúa la misma sesión vía `codex exec resume`: el reviewer conserva su contexto durante todo el feature, igual que el generador conserva el suyo en el chat.

## Qué recibe el reviewer en cada ronda

1. Preámbulo generado por `review.sh`: número de ronda, rango de commits desde el último APPROVED (`git log --oneline` + archivos), y punteros a AGENTS.md, STATUS.md y este contrato.
2. El pedido del generador: qué se hizo, qué revisar específicamente, y evidencia (tests corridos, salidas relevantes).

## Obligaciones del reviewer

- Verificar lo hecho contra DESIGN/IMPLEMENTATION: ¿coincide con lo documentado? ¿los docs quedaron al día?
- Puede ejecutar comandos (tests, builds, linters) para verificar por su cuenta — sandbox `workspace-write`. NO debe modificar el repo; si un comando ensucia el árbol, lo restaura.
- Feedback en puntos numerados y accionables.
- Última línea EXACTA de su respuesta: `VERDICT: APPROVED` o `VERDICT: CHANGES_REQUESTED`.

## Obligaciones del generador

- Responder cada punto numerado: corrigiendo (con commit) o argumentando por qué no. El desacuerdo se resuelve dentro del loop, no se ignora.
- No pedir review sin haber corrido sus propias verificaciones primero.
- Al menos un commit por ronda (los docs cuentan como cambio).

## Semántica del veredicto

- El veredicto es la **última línea no vacía** del mensaje del reviewer, comparada literalmente (se toleran solo espacios alrededor). Un veredicto en el medio del mensaje no cuenta: exit 2.
- Si el proceso de Codex termina con error (exit ≠ 0), **no se toma veredicto** aunque haya quedado un mensaje escrito: exit 2.
- La review queda **clavada al `REVIEW_HEAD`** capturado al armar el pedido: el rango, el log y la aprobación se refieren a ese SHA. Commits que aparezcan durante una review larga NO quedan aprobados — `review.sh` avisa y entran en el próximo rango. Se eligió esto en vez de invalidar la corrida: la review de un SHA es válida para ese SHA, y descartar una corrida xhigh por commits posteriores sería tirar trabajo bueno.
- `APPROVED` mueve la base a `REVIEW_HEAD` (`.claude/state/last-approved-sha`) y resetea la racha. Un APPROVED intermedio (p. ej. de la bajada fina) no cierra el feature; el APPROVED de cierre es contra los criterios de cierre del doc del feature.
- Sin veredicto válido → exit 2: el generador reintenta una vez y, si persiste, corta a RECAP.
- Exit codes de `review.sh`: 0 = APPROVED, 1 = CHANGES_REQUESTED, 2 = error / sin veredicto / deadlock.

## Deadlock

La regla de "5 rondas sin convergencia" se mide con una **racha de `CHANGES_REQUESTED` consecutivas** (`.claude/state/changes-streak`): se incrementa en cada ronda no convergida, se resetea con un APPROVED o al abrir ciclo con `new`. Al llegar a 5, `review.sh` **se niega a lanzar otra ronda** (exit 2, antes de gastar tokens): el generador arma un RECAP con ambas posturas para que desempate el humano, y tras el desempate corre `scripts/review.sh reset-deadlock` para continuar. `status` muestra ronda y racha.

## Commits de cierre (bookkeeping)

Tras el APPROVED final de un feature, el generador hace commits de cierre (solo docs: STATUS.md, IMPLEMENTATION.md, review log) que quedan después de la base aprobada. **No mueven la base**: aparecen al inicio del rango de la ronda 1 del ciclo siguiente, donde el reviewer los verifica como primer ítem. Así ningún commit queda sin review, sin necesidad de una corrida extra por el cierre.

## Ciclo de vida de sesiones

- `new` borra el session id guardado, corre `codex exec` y captura el id nuevo de los eventos JSONL (fallback: `resume --last`).
- `round` usa el id guardado en `.claude/state/codex-session-id`. Cambio de feature ⇒ siempre `new`.
- Config del reviewer: variables al tope de `review.sh`; overrides puntuales por env `AXEL_REVIEW_MODEL/EFFORT/SANDBOX` (p. ej. smoke tests con esfuerzo `low`).
- Reviews con esfuerzo xhigh pueden tardar >10 minutos: el generador corre `review.sh` en background y continúa cuando termina, sin duplicar la corrida.
- `review.sh` envuelve la invocación de Codex en `caffeinate -is` (scoped al proceso: la assertion muere con él), para que una review larga nunca se corte porque la máquina se durmió. La cobertura del lado del generador la da `scripts/awake.sh`.
