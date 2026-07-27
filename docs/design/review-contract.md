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

- `APPROVED` mueve la base: el próximo rango arranca en el HEAD aprobado (`review.sh` guarda `last-approved-sha`). Un APPROVED intermedio (p. ej. de la bajada fina) no cierra el feature; el APPROVED de cierre es contra los criterios de cierre del doc del feature.
- Sin línea de veredicto → exit 2: el generador reintenta una vez y, si persiste, corta a RECAP.
- Exit codes de `review.sh`: 0 = APPROVED, 1 = CHANGES_REQUESTED, 2 = error o sin veredicto.

## Deadlock

5 rondas sin convergencia → el generador corta y arma un RECAP con ambas posturas para que desempate el humano. El contador vive en `.claude/state/round` y lo muestra `scripts/review.sh status`.

## Ciclo de vida de sesiones

- `new` borra el session id guardado, corre `codex exec` y captura el id nuevo de los eventos JSONL (fallback: `resume --last`).
- `round` usa el id guardado en `.claude/state/codex-session-id`. Cambio de feature ⇒ siempre `new`.
- Config del reviewer: variables al tope de `review.sh`; overrides puntuales por env `AXEL_REVIEW_MODEL/EFFORT/SANDBOX` (p. ej. smoke tests con esfuerzo `low`).
- Reviews con esfuerzo xhigh pueden tardar >10 minutos: el generador corre `review.sh` en background y continúa cuando termina, sin duplicar la corrida.
