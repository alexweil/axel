# 01 — Instalador · evidencia de aceptación agentic (2026-07-27)

> Registro auditable de las dos corridas de aceptación del criterio 1 y del flujo `/adopt` (criterio 3), exigido por la sección "Aceptación agentic" de [01-installer.md](01-installer.md). Fuente de la maquinaria: axel `6671cab`. Los fixtures son repos git temporales; lo contrastable quedó acá: comandos, prompts, RCs, salidas y hashes de objetos git.

## Alcance de lo demostrado

- `/status` sobre instalación limpia: **de punta a punta**.
- `/adopt`: **flujo semántico completado por la sesión; el commit de cierre ejecutado externamente** — en headless sin trust del workspace, Claude Code ignora el allowlist del settings sembrado (aviso literal: `Ignoring 18 permissions.allow entries from .claude/settings.json: this workspace has not been trusted.`), así que la sesión aplicó todo el flujo y dejó el commit indicado; la "mano humana" lo dio el harness por fuera. Limitación del entorno de prueba, no del instalador: en uso interactivo el trust se acepta al abrir el proyecto.

## Corrida 1 — instalación limpia + `/status`

Fixture y siembra (RC de cada paso entre paréntesis):

```bash
mkdir -p accept/fresh && cd accept/fresh
git init -qb main && git commit -q --allow-empty -m init
/Users/alexweil/src/axel/scripts/install.sh .        # RC=0, reporte "modo: initial", 18 rutas instaladas
git add -A && git commit -qm "instalar axel"         # → 296497c
```

Historia resultante: `296497c instalar axel` · `f468928 init`.

Sesión (RC=0):

```bash
claude -p "/status"
```

Salida íntegra de la sesión (tras el aviso de trust):

> **Esperando al humano: arrancar la fase de diseño con `/design`.**
>
> - **Fase**: instalación de axel recién completada; no hay diseño ni plan todavía.
> - **Feature en curso**: ninguno — la tabla de features en `docs/IMPLEMENTATION.md` está vacía.
> - **Última actividad**: 2 commits (`f468928 init`, `296497c instalar axel`); nada más desde entonces.
> - **Loop de review**: no hay ninguno en curso — nunca se corrió una ronda de Codex (no hay ronda ni veredicto previo).
> - **Qué sigue**: primera sesión de diseño — ping-pong de ideas con vos para consolidar `docs/DESIGN.md`. Nada corriendo en background; el proyecto está limpio y listo para empezar.

Contraste: fase, tabla vacía, commits y ausencia de loop coinciden con el estado real del fixture.

## Corrida 2 — adopción + flujo `/adopt`

Fixture "recetario" (proyecto previo a axel):

```bash
mkdir -p accept/adopt && cd accept/adopt && git init -qb main
# README.md: "Colección de recetas de cocina de la familia, en markdown."
# docs/DESIGN.md: "Cada receta es un .md con frontmatter (tiempo, porciones). El índice se regenera con un script."
# PLAN.md: "- [x] estructura base / - [ ] indexador automático / - [ ] fotos por receta"
git add -A && git commit -qm "proyecto previo a axel"          # → d70fccb
/Users/alexweil/src/axel/scripts/install.sh .                  # RC=1 (pendientes)
git add -A && git commit -qm "instalar axel (adopción abierta)" # → 2e67617
```

El handoff generado (`2e67617:docs/ADOPTION.md`) listó exactamente: preexistente `docs/DESIGN.md`; candidatos `PLAN.md` y `README.md`; sin pendientes mecánicos. (`CLAUDE.md` y el payload correctamente excluidos del inventario.)

Sesión (RC=0) — prompt con las cinco decisiones del humano dadas:

```bash
claude -p "/adopt — Las decisiones del humano ya están tomadas, aplicalas sin preguntar: (1) docs/DESIGN.md preexistente se queda como está (ya cumple el rol de diseño; podés completarle el encabezado de convención si falta); (2) PLAN.md se fusiona en docs/IMPLEMENTATION.md como features priorizados y PLAN.md se elimina; (3) README.md se queda donde está; (4) en AGENTS.md completá 'Sobre este proyecto' con: recetario familiar en markdown, con índice regenerado por script; (5) derivá docs/STATUS.md del estado real (estructura base hecha, siguiente feature: indexador automático)."
```

Resumen de la salida de la sesión: aplicó las cinco decisiones, borró `docs/ADOPTION.md`, re-verificó lo mecánico contra `.claude/axel-policy.json` ("todos los allow presentes, sin deny/ask, defaultMode: acceptEdits", symlink y docs canónicos OK) y reportó que el commit le fue denegado por el harness, dejando el comando exacto. Commit de cierre dado por fuera → `b51b6f0`.

Contraste sobre el árbol (no sobre el reporte de la sesión):

```
git diff --stat 2e67617 b51b6f0
 AGENTS.md              |  2 +-     ← "Sobre este proyecto" completado
 PLAN.md                |  5 -----  ← eliminado (fusionado)
 docs/ADOPTION.md       | 19 ------ ← handoff consumido
 docs/DESIGN.md         |  2 ++    ← SOLO el encabezado de convención pedido
 docs/IMPLEMENTATION.md |  5 ++++-  ← tabla: 1 estructura base (hecho) · 2 indexador (siguiente) · 3 fotos
 docs/STATUS.md         |  7 ++++--- ← derivado: fase implementación, esperando /feature del indexador
```

Invariantes por hash de objeto git:

- `README.md` **idéntico** entre el estado previo (`d70fccb`) y el cierre (`b51b6f0`): blob `77a1fe5` en ambos.
- `docs/DESIGN.md`: `856b59d` → `c1f6ea7`; el diff completo entre previo y cierre son exactamente las 2 líneas del encabezado de convención (decisión 1 del humano); el contenido original intacto.
- Árbol limpio tras el cierre (`git status --porcelain` vacío) y sin `docs/ADOPTION.md` ni `PLAN.md`.
