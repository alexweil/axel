# STATUS

- **Fase**: ninguna en curso — **pipeline `/build` 2026-08-05 cerrado** (design-delta + plan-delta + feature 15) con OK humano el 2026-08-06 · ledger: [implementation/pipeline-2026-08-05.md](implementation/pipeline-2026-08-05.md)
- **Feature en curso**: ninguno — backlog vacío: los dieciséis features del plan (00–15) están cerrados
- **Ronda de review**: —
- **Último veredicto**: APPROVED de cierre · ronda 10 · head `12bd6ff` (unidad 15, pipeline 2026-08-05)
- **Esperando**: nada — el paso siguiente lo elige el humano: `/plan` para extender el backlog, o `/build` para un pedido que cruce fases
- **Actualizado**: 2026-08-06

> **Resuelto el 2026-08-06**: los tres comandos de GitHub (ajuste (b) del gate del pipeline 2026-07-29 (3), escritos en [implementation/14-onboarding-feedback.md](implementation/14-onboarding-feedback.md) §«Los tres comandos de GitHub») se corrieron por pedido explícito del humano («corre los comandos»): push de `main` (`88e1971..14ec6ba` — primera publicación del README nuevo), los ocho topics y la homepage apuntando a `docs/install.md`. Verificado con `gh repo view`.

> **Dos pendientes anotados, sin registrar en el backlog**: (1) la **deuda normativa declarada** — `AGENTS.md` §Convenciones dice «docs, commits y comunicación en español» y la política de idioma de [design/public-surface.md](design/public-surface.md) la volvió parcialmente falsa; su cierre exige una unidad autorizada aparte (más el espejo en `templates/AGENTS.md`), nunca un commit mecánico; (2) el **fix de la colisión `build/`** del instalador (decisión humana del pipeline 2026-07-29 (2): sin registrar).

> Vigente desde el pipeline 2026-07-29 (3): la **superficie pública** tiene diseño propio ([design/public-surface.md](design/public-surface.md)) — vidriera en inglés (`README.md`, `docs/install.md`, `CONTRIBUTING.md`, `.github/` y — desde el pipeline 2026-08-05 — el doc del render de la sesión, [session.md](session.md), path elegido por la bajada del feature 15), método en español, licencia MIT, y la evidencia del reviewer publicada como foto anclada ([metrics.md](metrics.md) + snapshot al corte `b0bdf4d`).

> Vigente desde el feature 12: el cierre de `/adopt` reporta el **inventario derivado de git** de los archivos que tocó. Contrato reusable en `.claude/skills/adopt/SKILL.md` §«Reporte de cierre (contrato)».

> Vigente desde el feature 11: el modelo de los **hijos** lo fija la maquinaria por tipo de unidad —`fable` para `design`/`plan`, `opus` para `feature`—; tabla canónica en la skill `build` §«Modelos por unidad».
