# 05 — Confirmación previa a la implementación en `/feature` (gate de arranque)

## Gate de arranque (bootstrap, modo manual)

Este feature se aplicó a sí mismo (IMPLEMENTATION §05): la sesión que lo implementa abrió con el gate en modo manual, siguiendo la entrada del plan como instrucción — la skill todavía no lo traía.

- **Presentación** (2026-07-28, commit `06c5e6c`): STATUS pasó a esperar la confirmación con la formulación «Esperando: confirmación de arranque del humano» — **equivalente semántico** del estado, no la frase literal «esperando confirmación de arranque» que este feature fija como disparador: esa literalidad es requisito de la implementación de la skill, que en el modo manual todavía no existía. Resumen derivado de la entrada 05 de IMPLEMENTATION.md, presentado en sesión interactiva.
- **Confirmación humana** (2026-07-28): «Confirmo, arrancá con la bajada fina» — **sin correcciones de alcance**. Este registro es la primera instancia viva del mecanismo que este feature implementa, con el mismo patrón (fecha + literal breve + correcciones) que la skill va a exigir.

## Alcance

Un checkpoint nuevo y barato al arranque de cada feature (IMPLEMENTATION §05, pedido humano 2026-07-28): al abrir la sesión limpia con `/feature`, **lo primero** que ve el humano es un resumen breve de lo que se va a implementar, y su confirmación es la condición para arrancar la bajada fina. El flujo posterior no cambia; el OK final de integración no se reemplaza. Tres entregables:

1. **El gate en la skill `feature`**: paso nuevo del camino "feature nuevo" (derivación del resumen con fallback honesto, persistencia del estado, espera de confirmación y registro), más el camino de **re-presentación** cuando una sesión abre con STATUS en «esperando confirmación de arranque».
2. **Encaje con el protocolo de aviso del 04** (la pregunta abierta que dejó el plan): el gate declara su procedencia y remite a `recap`; la lista de esperas interactivas del protocolo en `recap` gana la entrada del gate.
3. **Superficies de proceso sincronizadas**: línea de `/feature` en `AGENTS.md` + `templates/AGENTS.md`, línea "Cómo se trabaja un feature" en `IMPLEMENTATION.md` + `templates/IMPLEMENTATION.md`, flujo y fila de decisiones en `DESIGN.md`.

**Fuera de alcance**:

- **Scripts y contrato**: `review.sh`, `awake.sh` y `review-contract.md` no se tocan — el gate es conducta del generador (prosa de skill), no mecánica del loop.
- **Las demás skills**: `design`, `plan`, `adopt`, `status` no cambian (`recap` solo gana un ejemplo en su lista, ver Enfoque); en particular la continuidad del 04 (chips con prompt únicamente `/feature`) queda intacta — la sesión spawneada abre con el gate porque la skill lo trae, no porque el chip lleve contexto.
- **Estado local**: nada nuevo en `.claude/state` — la persistencia del gate vive en los docs (STATUS + doc del feature), principio 1 del diseño.
- **Reaperturas post-gate**: un feature ya confirmado (STATUS apunta a feature en curso) no re-gatea: la sesión retoma el loop donde estaba. El gate es exclusivo del arranque.

## Enfoque técnico

Todo el delta es prosa: skill `feature` (el grueso), una línea de ejemplos en `recap`, y las superficies de proceso (`AGENTS.md`+plantilla, `IMPLEMENTATION.md`+plantilla, `DESIGN.md`). Las skills son payload del instalador ⇒ los proyectos consumidores reciben el gate re-corriendo la instalación, sin cambio adicional.

### Semántica del gate (camino "feature nuevo" de la skill)

Entre tomar el siguiente feature y la bajada fina:

1. **Derivar el resumen** de lo disponible al momento del gate: la entrada del feature en `IMPLEMENTATION.md` (fila de la tabla y, si existe, su sección) más `DESIGN.md` si hace falta. **Fallback honesto** (decisión de plan, r1 de su ciclo): si las fuentes no alcanzan para un resumen fiel, el gate lo dice explícitamente y presenta lo que hay — sin inventar ni bloquearse. (Los planes adoptados con entradas pobres son el caso previsto.)
2. **Persistir antes de presentar**: STATUS → «esperando confirmación de arranque» (frase literal — es el disparador de la re-presentación) + commit. Así una sesión que muera después del commit re-presenta en vez de saltear.
3. **Presentar y terminar el turno**: resumen + pedido de confirmación explícito. Procedencia: respuesta directa (el humano acaba de abrir la sesión o clickear el chip) — aviso según skill `recap`.
4. **Con la confirmación**: registrarla en el doc del feature (fecha, literal breve y correcciones de alcance si las hubo — la bajada fina crea el doc con ese registro) y seguir con el flujo idéntico al actual. Una corrección de alcance del humano manda: la bajada la incorpora y el registro la documenta. Si el humano no confirma (redirige o frena), rige la regla existente de prioridad absoluta de sus mensajes: se sigue su indicación — y si invalida el feature, el camino es `/plan`, no forzar el arranque.

### Re-presentación

Camino nuevo en la skill, análogo a "esperando OK humano": si STATUS dice «esperando confirmación de arranque», no se avanza trabajo nuevo — se re-deriva el resumen de las mismas fuentes (los docs son la fuente; la presentación textual no se persiste) y se re-presenta el gate. Procedencia: respuesta directa (la reapertura la inicia el humano) — aviso según `recap`.

### Encaje con el protocolo de aviso del 04 (pregunta abierta del plan, resuelta)

La espera del gate **se alcanza siempre interactivamente, por construcción**: el gate es lo primero de una sesión que el humano acaba de abrir (o spawnear con el chip), y la re-presentación es la respuesta inmediata a la reapertura. No existe camino autónomo hacia esta espera ⇒ procedencia "respuesta directa", sin push, en ambos momentos. Conforme a la invariante del 04 (r4 de su ciclo): la skill declara **solo la procedencia** y remite a `recap`; el resultado push/sin-push se deriva únicamente allí. La lista de ejemplos interactivos del protocolo en `recap` gana una entrada — presentación o re-presentación del gate de arranque de `/feature` — para que el inventario siga cubriendo todas las esperas. El doc del 04 no se edita: es el registro histórico de aquel ciclo; el inventario vivo es el protocolo de `recap`.

### Docs afectados

| Superficie | Cambio |
|---|---|
| `.claude/skills/feature/SKILL.md` | Gate como paso nuevo del camino "feature nuevo" (renumera los pasos), camino de re-presentación, registro de la confirmación en el doc del feature |
| `.claude/skills/recap/SKILL.md` | La lista de esperas interactivas del protocolo gana el ejemplo del gate |
| `AGENTS.md` + `templates/AGENTS.md` | La línea de proceso de `/feature` gana el gate (misma línea en ambos — regla de duplicación) |
| `docs/IMPLEMENTATION.md` + `templates/IMPLEMENTATION.md` | Línea "Cómo se trabaja un feature" con el gate (misma formulación en ambos) |
| `docs/DESIGN.md` | Diagrama del flujo con el gate dentro de `/feature`; fila nueva en Decisiones |

`scripts/`, `tests/`, `review-contract.md`, skills `design`/`plan`/`adopt`/`status`: intactos.

### Implementación en un paso

Como el 04: delta chico y coherente de prosa interdependiente — un solo paso de implementación tras el APPROVED de la bajada (skill `feature` + `recap` + AGENTS/plantilla + IMPLEMENTATION/plantilla + DESIGN en un commit), y luego el cierre.

## Criterios de cierre

1. **Gate completo en la skill `feature`**: derivación con fallback honesto, persistencia previa (STATUS con la frase literal + commit), presentación con fin de turno, registro de la confirmación (fecha + correcciones) en el doc del feature, camino de re-presentación para «esperando confirmación de arranque», y flujo post-confirmación idéntico al actual (el OK final de integración intacto).
2. **Aviso sin restatement**: el gate (presentación y re-presentación) declara solo la procedencia y remite a `recap`; la lista interactiva del protocolo en `recap` incluye el gate; el resultado push/sin-push no aparece en las **skills de fase** — el alcance real de la invariante del 04 (las skills declaran procedencia; solo `recap` deriva el resultado). Las superficies de referencia de alto nivel (AGENTS.md, DESIGN.md, los docs de implementación) pueden nombrar el resultado sin ser norma del protocolo y quedan fuera del criterio.
3. **Superficies sincronizadas**: línea de `/feature` idéntica en `AGENTS.md` y `templates/AGENTS.md` (verificable por diff); línea "Cómo se trabaja un feature" con la misma formulación en `IMPLEMENTATION.md` y `templates/IMPLEMENTATION.md`; `DESIGN.md` con el gate en el diagrama y la fila de decisión nueva.
4. **Bootstrap registrado fielmente**: la sección "Gate de arranque (bootstrap)" de este doc registra la instancia manual tal como ocurrió — la presentación con su formulación real de STATUS (equivalente semántico, previa a la frase literal que la skill fija) y la confirmación con el patrón fecha + literal breve + correcciones. No se le atribuye al bootstrap la literalidad que recién introduce la implementación.
5. **Verificación en verde**: `tests/lint.sh` y `tests/install.sh` pasan tras el delta (las skills son payload del instalador); IMPLEMENTATION/STATUS al día.

## Decisiones

- 2026-07-28 (bajada): **La espera del gate es interactiva por construcción** — no existe camino autónomo hacia ella; presentación y re-presentación llevan procedencia "respuesta directa" y remiten a `recap`; la pregunta abierta del plan queda resuelta sin tocar el doc del 04 (registro histórico) — el inventario vivo es el protocolo de `recap`, que gana el ejemplo. **Persistir antes de presentar** (STATUS + commit primero): una sesión muerta entre el commit y la lectura humana re-presenta, nunca saltea. **Dos commits por gate** (presentación = STATUS; confirmación = doc del feature con el registro, junto a la bajada): la ronda 1 del ciclo del feature los barre a ambos. **Registro de la confirmación en el doc del feature** con fecha, literal breve y correcciones de alcance — el doc nace con la bajada, el registro viaja en ella. **Sin re-gateo post-confirmación**: STATUS en "feature en curso" retoma el loop donde estaba. **La no-confirmación no es un estado nuevo**: rige la prioridad absoluta de los mensajes del humano; si la redirección invalida el feature, el camino es `/plan`.
- Heredadas del ciclo de plan (2026-07-28): resumen **derivado** por `/feature` con fallback honesto (sin contrato nuevo para `/plan` — los planes adoptados no lo cumplirían); persistencia del estado del gate en docs con re-presentación al reabrir; bootstrap autoaplicado (sección "Gate de arranque" de este doc).

## Riesgos

- **Prosa no verificable por suite** (mismo perfil que el 04): mitigación — los criterios de cierre son el checklist explícito; el reviewer lee las skills en su worktree.
- **Fricción deliberada**: un stop más por feature; barato porque el humano está presente por construcción (acaba de abrir la sesión). Si el humano quisiera eliminarlo, es un cambio de método (→ `/plan` o `/design`), no un ajuste de este feature.
- **La frase-estado es el disparador**: si STATUS parafrasea «esperando confirmación de arranque», una sesión nueva podría no reconocer el camino de re-presentación — mitigación: la skill fija la frase literal y este ciclo la usa igual.
- **Proyectos consumidores con entradas de plan pobres** (adopciones): el fallback honesto existe exactamente para eso — el gate degrada a "presentar lo que hay", sin bloquear ni inventar.

## Review log

- **Ronda 1: CHANGES_REQUESTED** (2 puntos, ambos aceptados; el reviewer verificó además el bookkeeping del cierre del plan, el rango solo-Markdown sin cambios fuera de los tres docs declarados, y corrió `git diff --check` + `tests/lint.sh` limpios, `tests/install.sh` 321/0 y `tests/loop.sh` 238/0 — smoke no contractual omitido por su sandbox, como documenta el proyecto). Resolución:
  1. El bootstrap atribuía retroactivamente la frase literal «esperando confirmación de arranque» al commit `06c5e6c`, que en realidad escribió «Esperando: confirmación de arranque del humano» → corregido: el registro cita la formulación real como equivalente semántico del modo manual; la literalidad queda como requisito de la implementación de la skill, y el criterio 4 ya no se la atribuye al bootstrap.
  2. El criterio 2 exigía "ningún resultado push/sin-push fuera de `recap`" — invariante más amplia que la aprobada en el ciclo 04, y que el propio rango viola (este doc, DESIGN y AGENTS nombran el resultado) → corregido: criterio acotado a las skills de fase (ellas declaran procedencia; solo `recap` deriva el resultado); las superficies de referencia de alto nivel quedan explícitamente fuera.
