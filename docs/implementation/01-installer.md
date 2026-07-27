# 01 — Instalador: llevar axel a otro proyecto

## Alcance

Un comando, `scripts/install.sh <target-dir>`, que deja la maquinaria de axel operativa en un repo destino: instalación desde cero, **actualización** (re-correrlo con axel como fuente de verdad) y **modo adopción** para proyectos que ya venían siguiendo el proceso a mano (pedido humano 2026-07-27). El instalador vive solo en axel y se corre desde axel apuntando al destino; no se instala a sí mismo en los destinos.

Fuera de alcance (v1): merge automático de `settings.json` preexistente; manifest de versión instalada / detección de modificaciones locales del payload (la red de seguridad es git, ver Enfoque); soporte Windows (symlink); mapeo semántico automático de docs preexistentes (lo hace la primera sesión agentic en el destino, ver Modo adopción).

## Enfoque técnico

### Payload vs. semillas

La distinción central del instalador. Cada archivo que toca es una de dos cosas:

- **Payload** — código de la maquinaria, owned por axel, se **sobreescribe** en cada corrida (así el re-run es la actualización): las cinco skills (`.claude/skills/{design,plan,feature,recap,status}/SKILL.md`), `scripts/review.sh`, `scripts/awake.sh` (con permisos de ejecución) y el contrato `docs/design/review-contract.md` (es doc del método, no del proyecto; las skills y el prompt del reviewer lo referencian por esa ruta — un destino que quiera divergir de contrato hace un fork consciente que el re-run pisaría, visible por git).
- **Semillas** — contenido owned por el proyecto destino, se crean **solo si faltan** y no se tocan jamás después: `AGENTS.md` (desde plantilla), symlink `CLAUDE.md → AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` (desde plantillas), `.claude/settings.json`, y la entrada `.claude/state/` en `.gitignore` (append idempotente de la línea, nunca reescritura del archivo).

Casos borde de semillas: si `CLAUDE.md` existe y no es symlink a `AGENTS.md`, no se toca y se reporta el conflicto (mover su contenido a `AGENTS.md` es decisión del destino). Si `.claude/settings.json` existe, no se toca y el reporte lista los permisos que el loop necesita para que el destino los agregue a mano.

### Plantillas

Nuevo directorio `templates/` en axel: `AGENTS.md`, `DESIGN.md`, `IMPLEMENTATION.md`, `STATUS.md`. Placeholders mínimos (`{{PROJECT}}` = basename del destino, `{{DATE}}`), sustituidos por el instalador.

`templates/AGENTS.md` es el método completo (roles, fases, loop, reglas duras, sección para el reviewer, convenciones) sin lo axel-específico ("este repo ES la maquinaria"), con encabezado del proyecto y una nota de que la maquinaria está instalada desde axel y se actualiza re-corriendo el instalador. Riesgo aceptado: el método queda duplicado entre `AGENTS.md` de axel y la plantilla; cuando el método evolucione hay que tocar ambos (mitigación en Riesgos).

Las skills se copian idénticas: donde dicen "axel" nombran a la maquinaria, no al proyecto — válido en cualquier destino. En cambio `scripts/review.sh` hoy dice "Sos el reviewer del proyecto axel" en el prompt: se parametriza con el basename del repo (único cambio a código existente de este feature).

### Seguridad: git como red

- El destino debe ser un repo git con **árbol limpio**; si no, el instalador se niega (sin override en v1). Todo lo que hace queda como diff visible y reversible.
- El instalador **no commitea** en el destino: deja los cambios para que el humano/agente del destino los commitee con su propio proceso.
- Rechaza instalarse sobre el propio axel (self-install) y sobre no-repos.
- La fuente (axel) puede estar sucia: no bloquea, pero el reporte lo avisa e incluye el SHA de axel desde el que se instaló.

### Modo adopción: script mecánico + primera sesión semántica

El requisito humano es detectar docs preexistentes, no pisar nada, mapear lo que ya hay, sembrar solo lo que falte y derivar el `STATUS.md` inicial del estado real. La parte de juicio (qué doc equivale a qué, en qué estado está el proyecto) no es trabajo de un script bash: la división es

- **El script decide solo sobre rutas canónicas** (`AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`): existe → se respeta intacto y se marca "preexistente"; falta → se siembra plantilla.
- **Barrido informativo, sin decidir**: lista todos los `*.md` de la raíz y de `docs/**` que no sean canónicos como **candidatos a mapear** (un `PLAN.md`, un `ARCHITECTURE.md`…). Cero heurística de renombrado: el script nunca adivina equivalencias.
- **La primera sesión de Claude en el destino hace el mapeo semántico**: cuando hubo preexistentes o candidatos, el `STATUS.md` sembrado arranca en fase "adopción", con la lista de hallazgos y la instrucción de mapear candidatos a la convención, completar `AGENTS.md` con la descripción del proyecto y derivar el STATUS real. Así el flujo normal (`/status`, `/feature`) guía la adopción sin skills nuevas. Si `STATUS.md` ya existía, esas instrucciones van solo al reporte.

### Reporte

Salida final por stdout: qué se instaló/actualizó/dejó intacto, preexistentes y candidatos a mapear, avisos (CLAUDE.md en conflicto, settings preexistente, fuente sucia), SHA de axel, y próximos pasos (revisar diff, commitear en el destino, abrir Claude Code y correr `/status`).

### Verificación propia

`tests/install.sh`: suite bash autocontenida (repos git temporales como fixtures, sin invocar Codex ni Claude) que cubre instalación desde cero, re-run idempotente y que actualiza payload modificado, adopción (docs preexistentes intactos byte a byte, candidatos reportados, STATUS en fase adopción), y los rechazos (no-git, árbol sucio, self-install). Es la evidencia de cada ronda y el reviewer puede ejecutarla en su worktree. El feature 02 podrá sumar su suite de regresión al mismo directorio `tests/`.

## Criterios de cierre

1. Instalación desde cero sobre un repo git vacío deja la maquinaria completa: payload + semillas + symlink + gitignore, `install.sh` reporta y no commitea; abrir Claude Code en el destino y correr `/status` da un resultado coherente ("fase: diseño, arrancar con /design").
2. Re-run sobre un destino ya instalado: actualiza el payload (incluido uno modificado localmente), no toca ninguna semilla, y es idempotente (segunda corrida sin cambios).
3. Adopción sobre un repo con docs preexistentes y candidatos: nada preexistente cambia ni un byte, se siembra solo lo faltante, `STATUS.md` sembrado queda en fase adopción con hallazgos, y el reporte lista candidatos e instrucciones.
4. Rechazos verificados: destino sin git, árbol sucio, self-install sobre axel.
5. `tests/install.sh` en verde cubriendo 1–4; `bash -n` limpio sobre los scripts nuevos; docs al día: DESIGN.md (componente instalador + decisiones), IMPLEMENTATION.md (feature cerrado), README (uso del instalador).

## Decisiones

- 2026-07-27 (bajada): payload sobreescribible vs. semillas intocables como eje del diseño; contrato de review viaja como payload; plantillas duplican el método (riesgo aceptado y documentado); adopción dividida en script mecánico + primera sesión semántica guiada por el STATUS sembrado; árbol git limpio del destino como precondición y única red de seguridad (sin manifest en v1); el instalador no commitea; parametrizar el nombre del proyecto en el prompt de `review.sh`.

## Riesgos

- **Divergencia método ↔ plantilla**: `templates/AGENTS.md` puede quedar viejo cuando el método evolucione en axel. Mitigación: nota cruzada en ambos archivos ("si tocás el método acá, tocá también el otro") y el reviewer verifica coherencia cuando cambie AGENTS.md; consolidar una fuente única queda como mejora futura si duele.
- **Re-run pisa cambios locales de payload**: comportamiento deseado (axel es fuente de verdad) pero puede sorprender. Mitigación: precondición de árbol limpio hace el pisado visible y reversible; la convención "cambios de maquinaria se hacen en axel" queda en el AGENTS.md plantilla.
- **Detección de adopción tímida a propósito**: un doc equivalente con otro nombre no se mapea solo — queda como candidato para la sesión semántica. Es la contracara de "no pisar nada ni adivinar"; si en el uso real resulta pesado, se revisa.
- **`settings.json` preexistente sin permisos del loop**: el loop se frenaría en confirmaciones. Mitigado por reporte explícito; merge automático queda fuera de v1.
- **Plantillas pensadas para software**: axel sirve para cualquier contenido generable; las plantillas deben no asumir código (tests, builds) más allá de los ejemplos.

## Review log

(vacío — arranca con la ronda 1 del ciclo 01)
