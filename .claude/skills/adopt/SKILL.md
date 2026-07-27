---
name: adopt
description: Cerrar la adopción de un proyecto instalado con axel — consumir docs/ADOPTION.md, mapear los docs preexistentes a la convención, derivar el STATUS real y dejar el loop operativo.
---

Sos el generador. Esta skill cierra la adopción que el instalador de axel dejó pendiente.

Si **no existe** `docs/ADOPTION.md`: informá que no hay adopción pendiente y no toques nada.

Si existe, leé `docs/ADOPTION.md`, `AGENTS.md` y los docs que liste, y cerrá la adopción **con el humano** — cada punto que requiera juicio se pregunta, no se adivina:

1. **Mapear los candidatos**: por cada doc listado como candidato, decidí con el humano si equivale a un doc canónico (moverlo/fusionarlo a `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, etc.), si es una profundización (`docs/design/*.md`) o si se queda donde está.
2. **Completar `AGENTS.md`**: la sección "Sobre este proyecto" con qué es el proyecto, objetivo y alcance.
3. **Resolver los pendientes mecánicos** que el handoff liste: conflicto de `CLAUDE.md` (su contenido propio se fusiona en `AGENTS.md` y `CLAUDE.md` queda como symlink), permisos o `defaultMode` faltantes en `.claude/settings.json` (agregarlos, con confirmación del humano — son los que el loop necesita para no frenarse).
4. **Derivar el `STATUS.md` real**: leyendo los docs ya mapeados y el estado del repo, escribí el STATUS que refleje dónde está parado el proyecto de verdad (fase, trabajo en curso, qué se espera) — no dejes el texto plantilla.
5. **Re-verificar lo mecánico** antes de cerrar — esto cubre también pendientes surgidos después de escrito el handoff (p. ej. una política nueva tras actualizar la maquinaria): `CLAUDE.md` es symlink a `AGENTS.md`; `.claude/settings.json` cumple la política del loop instalada en `.claude/axel-policy.json` (cada permiso de su `allow` presente y no denegado, y su `defaultMode`); los cuatro docs canónicos existen; `.gitignore` cubre `.claude/state/`. Cualquier faltante se resuelve ahora.
6. **Cerrar**: borrá `docs/ADOPTION.md`, actualizá `docs/STATUS.md` y commiteá. Desde acá el proyecto sigue el flujo normal (`/status`, `/design`, `/plan`, `/feature`).

Regla: nada de lo preexistente se pisa sin decisión explícita del humano en esta sesión. Los movimientos de archivos van en el commit de cierre, visibles en el diff.
