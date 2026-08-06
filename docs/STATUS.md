# STATUS

- **Fase**: pipeline `/build` 2026-08-05 **en curso** — autorizado el 2026-08-05 («dale, autorizado», sin ajustes) · ruta: design-delta (README de cinco preguntas) → plan-delta (feature 15) → feature 15 (reescritura del README) · ledger: [implementation/pipeline-2026-08-05.md](implementation/pipeline-2026-08-05.md)
- **Feature en curso**: **15 — README simple**, unidad `feature` del pipeline **en curso**, token reclamado por el hijo (`0F7F8469…`, SHA inicio `87ee282`); **bajada fina APROBADA** en la r5 ([implementation/15-readme-simple.md](implementation/15-readme-simple.md)); implementación **completa** — las dos mudanzas, los dos placeholders y el `README.md` reescrito (179 → 156 líneas), con el inventario de 40 rangos y los 20 criterios verificados; unidades `design` y `plan` **APPROVED — pendiente OK de pipeline** (design: r3, head `4a60531`; plan: r2, head `75e192a`)
- **Ronda de review**: 10 · lanzada
- **Último veredicto**: CHANGES_REQUESTED · ronda 9 · head `e6249b2` — **un solo bloqueante** (contradicción del manual sobre `/status`), aceptado sin argumentar; Codex dio por verificados los 40 rangos, los locators, C8, C12, C15, links y bookkeeping. Racha 4: si la ronda 10 no converge se dispara la regla de deadlock
- **Esperando**: nada del humano — el pipeline corre autorizado; próximo checkpoint: RECAP consolidado al cierre de las tres unidades
- **Actualizado**: 2026-08-06

> **Pendiente inmediato del humano** (ajuste (b) del gate del pipeline 2026-07-29 (3)): correr los tres comandos de GitHub —push, topics, homepage— escritos en [implementation/14-onboarding-feedback.md](implementation/14-onboarding-feedback.md) §«Los tres comandos de GitHub».

> **Dos pendientes anotados, sin registrar en el backlog**: (1) la **deuda normativa declarada** — `AGENTS.md` §Convenciones dice «docs, commits y comunicación en español» y la política de idioma de [design/public-surface.md](design/public-surface.md) la volvió parcialmente falsa; su cierre exige una unidad autorizada aparte (más el espejo en `templates/AGENTS.md`), nunca un commit mecánico; (2) el **fix de la colisión `build/`** del instalador (decisión humana del pipeline 2026-07-29 (2): sin registrar).

> Vigente desde el pipeline 2026-07-29 (3): la **superficie pública** tiene diseño propio ([design/public-surface.md](design/public-surface.md)) — vidriera en inglés (`README.md`, `docs/install.md`, `CONTRIBUTING.md`, `.github/` y — desde el pipeline 2026-08-05 — el doc del render de la sesión, [session.md](session.md), path elegido por la bajada del feature 15), método en español, licencia MIT, y la evidencia del reviewer publicada como foto anclada ([metrics.md](metrics.md) + snapshot al corte `b0bdf4d`).

> Vigente desde el feature 12: el cierre de `/adopt` reporta el **inventario derivado de git** de los archivos que tocó. Contrato reusable en `.claude/skills/adopt/SKILL.md` §«Reporte de cierre (contrato)».

> Vigente desde el feature 11: el modelo de los **hijos** lo fija la maquinaria por tipo de unidad —`fable` para `design`/`plan`, `opus` para `feature`—; tabla canónica en la skill `build` §«Modelos por unidad».
