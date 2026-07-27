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

- Ronda 1: pendiente — esperando OK humano para correr la primera review de Codex sobre todo el bootstrap.
