# 00 — Bootstrap de la maquinaria

## Alcance

Montar el esqueleto completo de axel para que el método pueda correr de punta a punta: contexto raíz (`AGENTS.md` + symlink `CLAUDE.md`), estructura `docs/` (DESIGN, IMPLEMENTATION, STATUS, `design/`, `implementation/`), las cinco skills (`/design`, `/plan`, `/feature`, `/status`, `/recap`), el wrapper del reviewer (`scripts/review.sh`) y los permisos (`.claude/settings.json`).

## Criterios de cierre

1. Un agente sin contexto puede ubicarse leyendo AGENTS.md → STATUS.md → DESIGN/IMPLEMENTATION, siguiendo referencias hasta el detalle fino.
2. `scripts/review.sh` funciona de punta a punta contra Codex real: `new` captura la sesión, `round` resume con contexto conservado, veredictos parseados, exit codes correctos.
3. La primera review real de Codex sobre el bootstrap termina en APPROVED (con las correcciones que surjan en el loop).

## Decisiones

- 2026-07-27 (humano): alcance = maquinaria reusable; git `main` lineal; reviewer con capacidad de ejecución (workspace-write); montar el esqueleto ya.
- 2026-07-27 (generador): fases como skills del proyecto; estado local en `.claude/state/` gitignoreado; contrato de veredicto en texto plano parseable (`VERDICT: …` como última línea); smoke tests baratos vía override `AXEL_REVIEW_EFFORT=low`.

## Verificación

- `bash -n scripts/review.sh`: pendiente.
- Smoke test `new` + `round` con esfuerzo low (valida sesión, resume con contexto, veredicto y exit codes): pendiente.
- Tras el smoke, `.claude/state/` se resetea para que la primera review real arranque limpia.

## Review log

- Ronda 1: pendiente — esperando OK humano para correr la primera review de Codex sobre todo el bootstrap.
