# 00 — Bootstrap de la maquinaria

## Alcance

Montar el esqueleto completo de axel para que el método pueda correr de punta a punta: contexto raíz (`AGENTS.md` + symlink `CLAUDE.md`), estructura `docs/` (DESIGN, IMPLEMENTATION, STATUS, `design/`, `implementation/`), las cinco skills (`/design`, `/plan`, `/feature`, `/status`, `/recap`), el wrapper del reviewer (`scripts/review.sh`), el guardián de sueño (`scripts/awake.sh`) y los permisos (`.claude/settings.json`).

## Criterios de cierre

1. Un agente sin contexto puede ubicarse leyendo AGENTS.md → STATUS.md → DESIGN/IMPLEMENTATION, siguiendo referencias hasta el detalle fino.
2. `scripts/review.sh` funciona de punta a punta contra Codex real: `new` captura la sesión, `round` resume con contexto conservado, veredictos parseados, exit codes correctos.
3. La primera review real de Codex sobre el bootstrap termina en APPROVED (con las correcciones que surjan en el loop).

## Decisiones

- 2026-07-27 (humano): alcance = maquinaria reusable; git `main` lineal; reviewer con capacidad de ejecución (workspace-write); montar el esqueleto ya.
- 2026-07-27 (generador): fases como skills del proyecto; estado local en `.claude/state/` gitignoreado; contrato de veredicto en texto plano parseable (`VERDICT: …` como última línea); smoke tests baratos vía override `AXEL_REVIEW_EFFORT=low`.
- 2026-07-27 (humano, feedback al primer RECAP): la máquina no debe dormirse ni generando ni revisando → `scripts/awake.sh` (assertion con ventana renovable de 12h, arrancada al entrar al loop y mantenida durante la espera de OK) + `caffeinate` scoped alrededor de cada invocación de Codex en `review.sh`. Además, el instalador (feature 01) es prioritario y debe soportar **modo adopción** de proyectos existentes con proceso manual.

## Verificación

- `bash -n scripts/review.sh`: OK.
- Smoke test 2026-07-27 con `AXEL_REVIEW_EFFORT=low` contra Codex real: `new` capturó session id y parseó `VERDICT: APPROVED` (exit 0); `round` resumió la sesión conservando contexto (el reviewer recordó el mensaje anterior). El camino de error también quedó ejercitado: un flag inválido en resume produjo exit 2 con puntero a los eventos JSONL, se diagnosticó y se corrigió (`--cd` no existe en `codex exec resume`; el cwd lo garantiza el `cd` del script).
- `.claude/state/` reseteado tras el smoke para que la primera review real arranque limpia.
- `scripts/awake.sh` 2026-07-27: `start` deja el proceso caffeinate vivo entre llamadas (verificado con `pmset -g assertions`: `PreventUserIdleSystemSleep` + `PreventSystemSleep`, timeout 43200s registrado); `status` y pidfile consistentes.

## Review log

- 2026-07-27 — OK humano recibido para arrancar el loop de review.
- **Ronda 1: CHANGES_REQUESTED** (6 puntos, todos aceptados como problemas reales). Resolución:
  1. Veredicto laxo + RC ignorado → corregido tal cual: exit ≠ 0 de Codex invalida la corrida, y el veredicto se compara literalmente contra la última línea no vacía.
  2. Base movida al HEAD vivo (TOCTOU) → corregido con variante argumentada: la review queda clavada a `REVIEW_HEAD` (rango y aprobación); commits durante la review no quedan aprobados y entran al próximo rango, en vez de invalidar la corrida como proponía el reviewer.
  3. Deadlock mal contado → corregido: racha de `CHANGES_REQUESTED` consecutivas (resetea con APPROVED o `new`), bloqueo en 5 antes de gastar la ronda, `reset-deadlock` para continuar tras el desempate humano.
  4. Commits de cierre post-APPROVED fuera del rango → resuelto por diseño (opción "excepción explícita" del reviewer): no mueven la base y los verifica la ronda 1 del ciclo siguiente; documentado en el contrato.
  5. STATUS ↔ IMPLEMENTATION desincronizados → corregido; convención nueva: la tabla de features usa estados gruesos y el detalle fino vive solo en STATUS.md.
  6. awake.sh: pidfile huérfano/pid reciclado y validación tardía → corregido: identidad de proceso verificada antes de señalizar, horas validadas antes de tocar la assertion vigente.
- **Ronda 2: CHANGES_REQUESTED** (5 puntos; el reviewer validó las correcciones principales y afinó los bordes). Resolución:
  1. La variante `REVIEW_HEAD` no congelaba la **observación** (Codex leía el árbol vivo) → aceptado su contra-argumento, adoptada su opción más fuerte: el reviewer corre sobre un worktree snapshot clavado al SHA bajo review, re-clavado en cada ronda (`reset --hard` + `clean -fdx`). Beneficio extra: su sandbox de escritura queda confinado al snapshot y el residuo de rondas anteriores se limpia mecánicamente.
  2. `status` conservaba el parser laxo y podía mostrar APPROVED tras una corrida rechazada → corregido: resultado validado persistido aparte (`last-verdict`), escrito solo al aceptar la corrida; `status` no parsea más el mensaje crudo.
  3. Las skills trataban todo exit 2 como reintentable → corregido: distinguen `DEADLOCK` (no reintentar; RECAP; `reset-deadlock` tras el desempate) de error transitorio, en `/feature`, `/design` y `/plan`.
  4. `alive()` de awake.sh daba falso negativo bajo sandbox (señales/ps denegados) y `status` podía borrar el pidfile de una assertion viva — detectado por el reviewer al probarlo en su propio sandbox → corregido: `pmset -g assertions` como fuente primaria de verdad, tri-estado con "indeterminado" que nunca limpia ni señaliza.
  5. La excepción de bookkeeping dependía de que exista un ciclo siguiente → corregido: camino terminal documentado — el OK humano del RECAP final cubre los commits de cierre, listados explícitamente como no-revisados; mini-review opcional si el cierre tuvo sustancia.
