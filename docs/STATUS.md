# STATUS

- **Fase**: pipeline `/build` 2026-08-05 **en curso** — autorizado el 2026-08-05 («dale, autorizado», sin ajustes) · ruta: design-delta (README de cinco preguntas) → plan-delta (feature 15) → feature 15 (reescritura del README) · ledger: [implementation/pipeline-2026-08-05.md](implementation/pipeline-2026-08-05.md)
- **Feature en curso**: **15 — README simple**, unidad `feature` del pipeline **cerrada por el hijo** (token `0F7F8469…` retirado, SHA inicio `87ee282`); **APPROVED — pendiente OK de pipeline** (r10, head `12bd6ff`; bajada aprobada en la r5) — [implementation/15-readme-simple.md](implementation/15-readme-simple.md). Entregado: `README.md` reescrito (179 → 156 líneas), `docs/session.md` nuevo y `docs/install.md` ampliado, con el inventario de 40 rangos y los 20 criterios verificados; unidades `design` y `plan` **APPROVED — pendiente OK de pipeline** (design: r3, head `4a60531`; plan: r2, head `75e192a`)
- **Ronda de review**: 10 · consumida
- **Último veredicto**: APPROVED · ronda 10 · head `12bd6ff` (unidad `feature` 15, pipeline 2026-08-05) — **la unidad queda aprobada**, sin bloqueantes. Ciclo completo: 10 rondas, 33 pedidos, los 33 aceptados sin argumentar
- **Esperando**: nada del humano — el pipeline corre autorizado; próximo checkpoint: RECAP consolidado al cierre de las tres unidades
- **Actualizado**: 2026-08-06

> **Pendiente inmediato del humano** (ajuste (b) del gate del pipeline 2026-07-29 (3)): correr los tres comandos de GitHub —push, topics, homepage— escritos en [implementation/14-onboarding-feedback.md](implementation/14-onboarding-feedback.md) §«Los tres comandos de GitHub».

> **Dos pendientes anotados, sin registrar en el backlog**: (1) la **deuda normativa declarada** — `AGENTS.md` §Convenciones dice «docs, commits y comunicación en español» y la política de idioma de [design/public-surface.md](design/public-surface.md) la volvió parcialmente falsa; su cierre exige una unidad autorizada aparte (más el espejo en `templates/AGENTS.md`), nunca un commit mecánico; (2) el **fix de la colisión `build/`** del instalador (decisión humana del pipeline 2026-07-29 (2): sin registrar).

> Vigente desde el pipeline 2026-07-29 (3): la **superficie pública** tiene diseño propio ([design/public-surface.md](design/public-surface.md)) — vidriera en inglés (`README.md`, `docs/install.md`, `CONTRIBUTING.md`, `.github/` y — desde el pipeline 2026-08-05 — el doc del render de la sesión, [session.md](session.md), path elegido por la bajada del feature 15), método en español, licencia MIT, y la evidencia del reviewer publicada como foto anclada ([metrics.md](metrics.md) + snapshot al corte `b0bdf4d`).

> Vigente desde el feature 12: el cierre de `/adopt` reporta el **inventario derivado de git** de los archivos que tocó. Contrato reusable en `.claude/skills/adopt/SKILL.md` §«Reporte de cierre (contrato)».

> Vigente desde el feature 11: el modelo de los **hijos** lo fija la maquinaria por tipo de unidad —`fable` para `design`/`plan`, `opus` para `feature`—; tabla canónica en la skill `build` §«Modelos por unidad».
