# 04 — Notificaciones y continuidad entre sesiones

## Alcance

Calidad de vida sobre las dos costuras donde el loop se encuentra con el humano (IMPLEMENTATION §04): que **ningún camino que quede esperando un OK se quede esperando en silencio**, y que **arrancar el paso siguiente tras un OK cueste un click** (o una instrucción única donde no hay click). Tres entregables:

1. **Inventario de caminos de espera**: enumeración completa (en este doc) de los puntos donde el generador termina su turno esperando al humano, cada uno clasificado con/sin aviso según un criterio único.
2. **Protocolo de aviso unificado**: una regla, centralizada en la skill `recap`, que reemplaza las dos menciones actuales e inconsistentes de `PushNotification` (la skill `recap` condiciona con un difuso "si el humano no está activo en la sesión"; el paso 5 de `feature` avisa incondicionalmente y solo en el cierre — los RECAP de `/design`, `/plan` y todos los tempranos hoy no avisan nunca).
3. **Continuidad tras el OK**: en cada cruce de frontera de contexto (OK que cierra fase o feature → sesión limpia siguiente), facilitar el arranque: chip de spawn si la sesión tiene la herramienta (desktop), instrucción única si no.

**Fuera de alcance**:

- **Scripts y contrato**: `review.sh`, `awake.sh` y `review-contract.md` no se tocan. El push y el spawn son herramientas del harness de la sesión del generador, no subprocesos; nada de la mecánica del loop (veredictos, estado, exit codes) cambia.
- **Avisos a mitad de loop** (fin de una ronda larga de review): no hay espera humana — el generador continúa solo cuando el background termina; avisar sería ruido.
- **Garantía de entrega del push**: es best-effort del harness. El estado autoritativo sigue siendo `STATUS.md` (principio 1): quien abre una sesión reconstruye todo aunque el push nunca haya llegado.
- **Surfaces sin herramientas** (CLI pelado, harness sin push): la degradación es parte del protocolo (sin aviso / instrucción única), no un caso a resolver aparte.

## Enfoque técnico

Todo el delta es prosa: skills (`recap`, `feature`, `design`, `plan`), `AGENTS.md` + `templates/AGENTS.md` (duplicación raíz↔plantilla) y `DESIGN.md` (fila de decisión). Las skills son payload del instalador, así que los proyectos consumidores reciben el protocolo re-corriendo la instalación sin cambio adicional.

### Inventario de caminos de espera

El criterio que decide el aviso es **cómo se llegó a la espera**, no dónde: si el turno que termina esperando es la **respuesta inmediata a un mensaje que el humano acaba de mandar**, el humano está presente por construcción y el push es ruido; si el turno venía de **trabajo autónomo** (rondas de review en background, implementación larga), el humano puede llevar horas afuera y el aviso es exactamente lo que falta. Esto reemplaza la condición actual "si el humano no está activo en la sesión", que pedía adivinar presencia; el criterio nuevo se decide mirando el propio turno. Borde resuelto: si el humano mandó un mensaje a mitad del loop y después hubo rondas autónomas antes del RECAP, va aviso; en la duda, va aviso — el costo de un push redundante es trivial, el de un loop estancado se mide en horas.

| Camino | Dónde | Aviso |
|---|---|---|
| RECAP de cierre de feature (APPROVED de cierre) | skill `feature`, paso 5 | **Sí** |
| RECAP terminal (sin feature siguiente) | skill `feature`, paso 6 | **Sí** |
| RECAP de diseño (tras el loop de review) | skill `design`, paso 4 | **Sí** |
| RECAP de plan (tras el loop de review) | skill `plan`, paso 3 | **Sí** |
| RECAP temprano: deadlock (racha 5) | reglas de `feature`/`design`/`plan` | **Sí** |
| RECAP temprano: tope de rondas, cambio de scope, sorpresa, exit 2 persistente, veredicto inválido repetido | reglas de `feature`/`design`/`plan` | **Sí** |
| `/recap` a demanda | skill `recap` | No — pedido directo |
| Reapertura con STATUS "esperando OK" (re-presentar el RECAP) | skill `feature`, camino esperando-OK | No — el humano acaba de escribir |
| `/status`, `/adopt` | consulta / sesión interactiva | No — pedido directo |

### Protocolo de aviso (centralizado en la skill `recap`)

- **Cuándo**: todo RECAP alcanzado por trabajo autónomo (tabla de arriba), al terminar el turno en espera de OK.
- **Qué**: una línea, en español: `<proyecto>: <qué pasó> — <qué se espera>` (p. ej. "axel: feature 04 cerrado (APPROVED r2) — esperando tu OK"; "axel: DEADLOCK en la ronda 5 — RECAP con ambas posturas, esperando desempate").
- **Con qué**: la herramienta de push del harness (hoy: `PushNotification`; puede requerir cargarla vía búsqueda de herramientas). Si no está disponible, se sigue sin aviso y sin mencionar la ausencia como error: la degradación es silenciosa porque el estado autoritativo es STATUS.md.
- **Dónde vive la regla**: solo en la skill `recap`. Las skills `feature`, `design` y `plan` referencian ("RECAP — estructura y aviso según la skill `recap`") sin repetir el protocolo: las dos menciones actuales de `PushNotification` fuera de `recap` desaparecen. La lección es del propio ciclo 03 (r7): los restatements divergen; una regla, un lugar.

### Continuidad tras el OK

Cruces de frontera de contexto y su paso siguiente:

| OK que cierra | Siguiente paso en sesión limpia | Skill responsable |
|---|---|---|
| OK del diseño | `/plan` | `design` |
| OK del plan | `/feature` (primero de la lista) | `plan` |
| OK de cierre de feature | `/feature` (siguiente) | `feature`, camino esperando-OK |
| OK terminal (sin siguiente en IMPLEMENTATION) | nada por default; `/plan` solo si el humano quiere extender el plan | `feature` |

Protocolo, tras registrar el OK (STATUS.md actualizado + commit):

- **Con herramienta de spawn de sesión** (hoy: el chip de spawn del desktop, `spawn_task`): crear el chip — título "Feature NN: <nombre> — sesión limpia" (o "/plan — sesión limpia"), prompt **solo el comando de la skill** (`/feature`, `/plan`), tldr de una línea. El prompt es autocontenido por el principio 1: el estado vive en los docs, la sesión nueva reconstruye todo leyéndolos — el chip no necesita (ni debe) llevar contexto del chat.
- **Sin herramienta**: instrucción única en el chat — "sesión nueva en este repo + `/feature`" (desde terminal: `claude "/feature"`).
- En ningún caso se implementa el siguiente feature en la sesión vieja (regla existente del método; el chip/instrucción la refuerza, no la reemplaza).

### Docs afectados

`recap` (protocolo completo), `feature`/`design`/`plan` (referencias + chip en sus caminos de OK), `AGENTS.md` y `templates/AGENTS.md` (una línea en Convenciones: aviso en RECAPs autónomos y chip/instrucción única tras el OK — misma línea en ambos, regla de duplicación), `DESIGN.md` (fila de decisión: criterio de autonomía + continuidad; la fila RECAP de 2026-07-27 queda como antecedente). `review-contract.md` no se toca. Las skills `status` y `adopt` tampoco (inventariadas arriba como sin-aviso, sin cambio de texto).

### Implementación en un paso

El delta es chico y coherente (prosa interdependiente): un solo paso de implementación tras el APPROVED de la bajada — skills + AGENTS + plantilla + DESIGN en un commit — y luego el cierre. La aceptación real del protocolo es este mismo ciclo: el RECAP de cierre del 04 se alcanza por trabajo autónomo ⇒ ejercita el push real (resultado al Review log). El cierre del 04 es **terminal** (no hay 05 en IMPLEMENTATION): sigue el camino terminal del contrato — el RECAP lista los commits de cierre como no-revisados-por-Codex — y demuestra la rama terminal de la tabla de continuidad (sin chip por default, ofrecimiento de `/plan`).

## Criterios de cierre

1. **Inventario completo y aplicado**: la tabla de caminos de espera cubre todos los finales de turno en espera de OK de las skills, cada camino clasificado por el criterio de autonomía; las skills quedan tales que cada camino con aviso alcanza la regla (directamente o por referencia a `recap`).
2. **Protocolo en un solo lugar**: formato, criterio y degradación viven solo en la skill `recap`; `feature`/`design`/`plan` referencian sin restatement; la condición ambigua actual ("si el humano no está activo") y la mención suelta del paso 5 de `feature` eliminadas.
3. **Continuidad documentada en los cuatro cruces**: diseño→plan, plan→feature, feature→siguiente y terminal, cada uno en su skill con chip + fallback de instrucción única; el prompt del chip es solo el comando de la skill.
4. **Docs sincronizados**: `AGENTS.md` y `templates/AGENTS.md` con la misma convención nueva (duplicación raíz↔plantilla verificable por diff de la sección); `DESIGN.md` con la decisión registrada; IMPLEMENTATION/STATUS al día.
5. **Aceptación real en este ciclo**: el RECAP de cierre del 04 ejercita el protocolo de punta a punta — push enviado si la herramienta está disponible en esta sesión (resultado registrado en el Review log) — y sigue el camino terminal del contrato (commits de cierre listados como no-revisados).

## Decisiones

- 2026-07-28 (bajada): **Criterio de autonomía** para el aviso — push si la espera se alcanzó por trabajo autónomo, no si responde a un pedido directo del humano; reemplaza la condición de presencia ("humano no activo") que pedía adivinar, por una que se decide mirando el turno; en la duda, aviso. **Protocolo centralizado en `recap`** con referencias desde las otras skills — lección del r7 del ciclo 03: los restatements divergen. **Chip con prompt autocontenido** (solo `/feature` o `/plan`): el estado vive en los docs (principio 1), llevar contexto de chat en el chip lo violaría. **Sin cambios en scripts ni contrato**: las herramientas son del harness; el loop mecánico no cambia. **Sin tests automatizados**: el delta es lenguaje natural en skills; un grep sobre prosa sería frágil y falso — la verificación es el inventario de este doc contra las skills, en la review. **Caso terminal sin chip por default**: sin siguiente feature no hay comando obvio que spawnear; se ofrece `/plan` en el texto del RECAP.

## Riesgos

- **Las herramientas del harness varían por surface y versión** (nombres y disponibilidad de push/spawn): las skills nombran la capacidad con el nombre actual como ejemplo y siempre con degradación explícita; la ausencia de una herramienta jamás bloquea el loop ni se reporta como error.
- **El chip de spawn está pensado para tareas out-of-scope**, no para continuidad de fases: funcionalmente es lo pedido ("chip de spawn en desktop" — un click abre sesión propia con el prompt). Si en la práctica no encaja (p. ej. la sesión spawneada no queda utilizable como sesión del feature), el fallback es la instrucción única y el hallazgo se registra en este doc.
- **Prosa no verificable por suite**: mitigado con el inventario como checklist explícito para el reviewer (puede leer las seis skills en su worktree) y con la centralización, que reduce los puntos a mantener a uno.
- **El criterio de autonomía tiene bordes** (mensaje humano a mitad de loop): resuelto en la bajada — media ronda autónoma entre el mensaje y el RECAP ⇒ aviso; en la duda, aviso (asimetría de costos documentada).

## Review log
