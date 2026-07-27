# 01 — Instalador: llevar axel a otro proyecto

## Alcance

Un comando, `scripts/install.sh <target-dir>`, que deja la maquinaria de axel operativa en un repo destino: instalación desde cero, **actualización** (re-correrlo con axel como fuente de verdad) y **modo adopción** para proyectos que ya venían siguiendo el proceso a mano (pedido humano 2026-07-27). Los pendientes que requieren juicio (mapear docs preexistentes, completar settings, resolver conflictos) quedan en un **handoff persistente** (`docs/ADOPTION.md`) que consume una skill nueva, `/adopt`, en el destino. El instalador vive solo en axel y se corre desde axel apuntando al destino; no se instala a sí mismo en los destinos.

Fuera de alcance (v1): merge automático de `settings.json` preexistente (la **comparación** de permisos sí está en alcance; el merge lo hace `/adopt` con el humano); manifest de versión instalada (la seguridad la dan la precondición de árbol limpio más el preflight de rutas, ver Seguridad); soporte Windows (symlink); mapeo semántico automático de docs preexistentes (lo hace `/adopt`).

## Enfoque técnico

### Payload vs. semillas

La distinción central del instalador. Cada archivo que toca es una de dos cosas:

- **Payload** — código de la maquinaria, owned por axel, se **sobreescribe** en cada corrida (así el re-run es la actualización): las seis skills (`.claude/skills/{design,plan,feature,recap,status,adopt}/SKILL.md` — `/adopt` nace en este feature y queda también en axel), `scripts/review.sh`, `scripts/awake.sh` (con permisos de ejecución) y el contrato `docs/design/review-contract.md` (es doc del método, no del proyecto; las skills y el prompt del reviewer lo referencian por esa ruta — un destino que quiera divergir de contrato hace un fork consciente que el re-run pisaría, visible por git).
- **Semillas** — contenido owned por el proyecto destino, se crean **solo si faltan** y no se tocan jamás después: `AGENTS.md` (desde plantilla), symlink `CLAUDE.md → AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` (desde plantillas), `.claude/settings.json`, y la entrada `.claude/state/` en `.gitignore` (append idempotente de la línea, nunca reescritura del archivo).

Casos borde de semillas: si `CLAUDE.md` existe y no es exactamente un symlink a `AGENTS.md`, no se toca y el conflicto va a reporte y handoff. Si `.claude/settings.json` existe, no se toca, pero el instalador **compara**: verifica la presencia (textual, sin depender de jq) de cada permiso que el loop necesita según el settings del payload; cualquier faltante es **bloqueante** — sin esos permisos el loop se frena en confirmaciones — y queda marcado así en el reporte y persistido en el handoff. El comando no declara éxito limpio con permisos faltantes.

### Plantillas

Nuevo directorio `templates/` en axel: `AGENTS.md`, `DESIGN.md`, `IMPLEMENTATION.md`, `STATUS.md`. Placeholders mínimos (`{{PROJECT}}` = basename del destino, `{{DATE}}`), sustituidos por el instalador.

`templates/AGENTS.md` es el método completo (roles, fases, loop, reglas duras, sección para el reviewer, convenciones) sin lo axel-específico ("este repo ES la maquinaria"), con encabezado del proyecto y una nota de que la maquinaria está instalada desde axel y se actualiza re-corriendo el instalador. Riesgo aceptado: el método queda duplicado entre `AGENTS.md` de axel y la plantilla; cuando el método evolucione hay que tocar ambos (mitigación en Riesgos).

Las skills se copian idénticas: donde dicen "axel" nombran a la maquinaria, no al proyecto — válido en cualquier destino. En cambio `scripts/review.sh` hoy dice "Sos el reviewer del proyecto axel" en el prompt: se parametriza con el basename del repo (único cambio a código existente de este feature).

### Seguridad: git como red + preflight de rutas

- El destino debe ser un repo git con **árbol limpio**; si no, el instalador se niega (sin override en v1). Todo lo que hace queda como diff visible y reversible.
- **Preflight de rutas** — el árbol limpio solo no alcanza: una colisión **ignorada** por gitignore se pisaría sin diff ni recuperación, y un **symlink** en una ruta de escritura escaparía del árbol. Antes de escribir nada, el instalador valida cada ruta que va a tocar (payload, semillas faltantes, handoff) y rechaza: archivos existentes no trackeados o ignorados en rutas de payload, symlinks en la ruta o en sus directorios intermedios (única excepción: un `CLAUDE.md` que ya sea exactamente el symlink esperado a `AGENTS.md`), y tipos incompatibles (directorio donde va un archivo o viceversa). Payload preexistente **trackeado** sí se pisa: eso es la actualización, con diff visible. El preflight es todo-o-nada: si algo se rechaza, no se escribió nada.
- Identidad del destino: `<target-dir>` debe resolver (realpath) exactamente al **toplevel canónico** de su repo (`git rev-parse --show-toplevel`), no a un subdirectorio; el self-install se rechaza comparando paths canónicos contra el toplevel de axel (cubre alias y symlinks al propio repo).
- El instalador **no commitea** en el destino: deja los cambios para que el humano/agente del destino los commitee con su propio proceso.
- La fuente (axel) puede estar sucia: no bloquea, pero el reporte lo avisa e incluye el SHA de axel desde el que se instaló.

### Modo adopción: inventario primero, handoff persistente, `/adopt`

El requisito humano es detectar docs preexistentes, no pisar nada, mapear lo que ya hay, sembrar solo lo que falte y derivar el `STATUS.md` inicial del estado real. La parte de juicio no es trabajo de un script bash; la división es:

- **Inventario pre-mutación**: el barrido del árbol se toma sobre el estado original, **antes de escribir nada**, y excluye toda ruta owned por el instalador (payload, semillas, `CLAUDE.md`, `docs/ADOPTION.md`). Una instalación desde cero jamás reporta sus propios artefactos como candidatos ni termina en adopción.
- **El script decide solo sobre rutas canónicas** (`AGENTS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md`): existe → se respeta intacto y se marca "preexistente"; falta → se siembra plantilla.
- **Barrido informativo, sin decidir**: los demás `*.md` de la raíz y de `docs/**` del inventario quedan como **candidatos a mapear** (un `PLAN.md`, un `ARCHITECTURE.md`…). Cero heurística de renombrado: el script nunca adivina equivalencias.
- **Handoff persistente**: si al terminar quedan pendientes que requieren juicio (docs canónicos preexistentes, candidatos, `CLAUDE.md` en conflicto, permisos de settings faltantes), el instalador escribe `docs/ADOPTION.md` con los hallazgos y las instrucciones. Es un artefacto del instalador: se regenera en cada corrida con pendientes y lo consume y **borra** `/adopt` al cerrar la adopción. No depende de stdout ni de que `STATUS.md` haya sido sembrado — cualquier sesión futura lo retoma.
- **`/adopt`** (skill nueva, parte del payload): lee `docs/ADOPTION.md`; con el humano mapea los candidatos a la convención de axel, completa `AGENTS.md` con la descripción del proyecto, resuelve settings y `CLAUDE.md`, **deriva el `STATUS.md` real** del estado del proyecto, borra `docs/ADOPTION.md` y commitea. Sin `docs/ADOPTION.md` presente, informa que no hay adopción pendiente y no toca nada. Cuando `STATUS.md` se siembra en un destino con pendientes, arranca en fase "adopción" apuntando a `/adopt`; cuando preexiste, el handoff igual persiste la ruta completa.

### Reporte

Salida final por stdout: qué se instaló/actualizó/dejó intacto, preexistentes y candidatos, avisos (conflictos, permisos faltantes, fuente sucia), SHA de axel, y próximos pasos (revisar diff, commitear en el destino, abrir Claude Code y correr `/status`; si hubo pendientes, el detalle quedó en `docs/ADOPTION.md` y el paso siguiente es `/adopt`).

### Verificación: invariantes automatizadas + aceptación agentic

- **`tests/install.sh`** — suite bash autocontenida (repos git temporales como fixtures, sin invocar agentes), la evidencia mecánica de cada ronda, ejecutable por el reviewer en su worktree. Matriz: instalación desde cero (termina en fase diseño, sin candidatos ni `ADOPTION.md`); re-run idempotente y actualizando un payload modificado-y-commiteado (con el commit intermedio que exige la precondición de árbol limpio); adopción (docs/semillas preexistentes intactos byte a byte, candidatos correctos, `ADOPTION.md` escrito, STATUS en fase adopción); `STATUS.md` preexistente (el handoff persiste igual); `CLAUDE.md` en conflicto; settings preexistente completo e incompleto (faltante bloqueante en reporte y handoff); exclusión de artefactos propios del inventario; rechazos: no-git, árbol sucio, target subdirectorio, self-install por path canónico, colisión ignorada en ruta de payload, symlink en ruta de payload.
- **Aceptación agentic** — lo que un test sin agentes no puede demostrar: abrir Claude Code en un destino de prueba y correr `/status` (instalación limpia) y el flujo `/adopt` (fixture de adopción) de punta a punta. La evidencia (comandos y salida/resumen de esas sesiones) queda pegada en el Review log, contrastable contra los artefactos del fixture.

## Criterios de cierre

1. Instalación desde cero sobre un repo git vacío deja la maquinaria completa (payload + semillas + symlink + gitignore), reporta y no commitea; la coherencia de `/status` en el destino queda evidenciada con la corrida agentic documentada en el Review log.
2. Re-run sobre un destino ya instalado: actualiza el payload (incluido uno modificado localmente y commiteado), no toca ninguna semilla, y es idempotente (segunda corrida consecutiva: sin cambios).
3. Adopción: ningún doc/semilla preexistente cambia un byte (colisiones de **payload** siguen su regla: trackeado se actualiza, ignorado/symlink se rechaza); se siembra solo lo faltante; el handoff `docs/ADOPTION.md` queda persistido con hallazgos e instrucciones aunque `STATUS.md` preexista; `/adopt` existe en el payload y su flujo cubre mapear candidatos, completar `AGENTS.md` y settings, derivar el STATUS real y borrar el handoff.
4. Rechazos verificados: destino sin git, árbol sucio, target que no es el toplevel, self-install (por path canónico), colisión ignorada y symlink en rutas de payload.
5. `tests/install.sh` en verde cubriendo la matriz completa de invariantes (la parte mecánica de 1–4); la aceptación agentic (criterio 1 y flujo `/adopt`) evidenciada en el Review log; `bash -n` limpio sobre los scripts nuevos; docs al día: DESIGN.md (componente instalador + decisiones), IMPLEMENTATION.md (feature cerrado), README (uso del instalador).

## Decisiones

- 2026-07-27 (bajada): payload sobreescribible vs. semillas intocables como eje del diseño; contrato de review viaja como payload; plantillas duplican el método (riesgo aceptado y documentado); adopción dividida en script mecánico + sesión semántica; árbol git limpio del destino como precondición; el instalador no commitea; parametrizar el nombre del proyecto en el prompt de `review.sh`.
- 2026-07-27 (ronda 1): handoff de adopción **persistente** en `docs/ADOPTION.md` + skill `/adopt` como consumidor (el stdout no es retomable y `/status`/`/feature` no contemplan adopción); inventario de candidatos **pre-mutación** con exclusión de artefactos del instalador; **preflight de rutas** (colisiones ignoradas, symlinks, tipos incompatibles, toplevel y self-install por path canónico) porque el árbol limpio solo no cubre lo que git no ve; comparación de permisos de settings con faltantes **bloqueantes** y persistidos; criterios de cierre separados en invariantes automatizadas vs. aceptación agentic con evidencia definida.

## Riesgos

- **Divergencia método ↔ plantilla**: `templates/AGENTS.md` puede quedar viejo cuando el método evolucione en axel. Mitigación: nota cruzada en ambos archivos ("si tocás el método acá, tocá también el otro") y el reviewer verifica coherencia cuando cambie AGENTS.md; consolidar una fuente única queda como mejora futura si duele.
- **Re-run pisa cambios locales de payload**: comportamiento deseado (axel es fuente de verdad) pero puede sorprender. Mitigación: precondición de árbol limpio + preflight hacen que solo se pise contenido trackeado (diff visible y reversible); la convención "cambios de maquinaria se hacen en axel" queda en el AGENTS.md plantilla.
- **Detección de adopción tímida a propósito**: un doc equivalente con otro nombre no se mapea solo — queda como candidato para `/adopt`. Es la contracara de "no pisar nada ni adivinar"; si en el uso real resulta pesado, se revisa.
- **`docs/ADOPTION.md` como ruta reservada**: un proyecto que ya tuviera un archivo con ese nombre lo vería tratado como artefacto del instalador (trackeado: regenerado con diff visible; ignorado/symlink: rechazado por preflight). Riesgo aceptado: nombre suficientemente específico.
- **Comparación textual de settings**: verificar presencia de permisos por texto (sin jq) puede dar falsos positivos ante formatos exóticos del JSON. Aceptado en v1: el caso normal es un settings generado por herramienta o por este instalador; el fallo es en dirección segura (reportar faltante de más, nunca de menos) si la comparación es por entrada exacta.
- **Plantillas pensadas para software**: axel sirve para cualquier contenido generable; las plantillas deben no asumir código (tests, builds) más allá de los ejemplos.

## Review log

- **Ronda 1: CHANGES_REQUESTED** (6 puntos, todos aceptados). Resolución:
  1. `IMPLEMENTATION.md` decía "OK humano del plan: pendiente" tras el commit que registró el OK → corregido: la línea refleja el OK del 2026-07-27.
  2. Handoff de adopción no retomable si `STATUS.md` preexistía (instrucciones solo en stdout; `/status` es read-only y `/feature` no contempla adopción) → corregido: handoff persistente `docs/ADOPTION.md` + skill nueva `/adopt` (payload) que lo consume, mapea, deriva el STATUS real y lo borra; el resultado es parte del criterio de cierre 3.
  3. El barrido de candidatos podía reportar artefactos recién escritos por el propio instalador → corregido: inventario pre-mutación sobre el árbol original + exclusión explícita de rutas owned; test de que la instalación vacía termina en diseño sin candidatos.
  4. Árbol limpio insuficiente (colisiones ignoradas sin diff, symlinks que escapan del árbol, target no canónico) → corregido: preflight de rutas todo-o-nada (ignorados/untracked en payload, symlinks salvo el CLAUDE.md esperado, tipos incompatibles) + target debe ser el toplevel canónico y self-install comparado por realpath.
  5. Promesas reconciliadas: "ni un byte" ahora se limita explícitamente a docs/semillas (payload sigue su regla); settings preexistente se compara contra los permisos requeridos, faltantes bloqueantes en reporte y handoff, casos completo/incompleto en la matriz de tests.
  6. Criterios de cierre separados: matriz automatizada ampliada (STATUS preexistente, conflictos settings/CLAUDE, exclusión de artefactos propios, colisiones ignoradas, commit intermedio entre re-runs) vs. aceptación agentic con evidencia definida (corridas de `/status` y `/adopt` documentadas en el Review log).
