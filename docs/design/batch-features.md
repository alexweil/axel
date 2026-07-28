# Batch de features: `/feature all` y `/feature NN..MM`

> Profundización de [DESIGN.md](../DESIGN.md). Diseño acordado en ping-pong con el humano el 2026-07-28 (superficie y gate de lote confirmados explícitamente); la arquitectura padre↔hijo sale de un spike empírico (abajo). Esto es diseño: la implementación entra al plan vía `/plan` como cualquier feature.

## Objetivo

Ejecutar varios features priorizados del plan de una sola corrida, uno tras otro, sin OK humano entre features. El checkpoint humano no desaparece: se agrupa en un **gate de lote** al inicio y un **RECAP consolidado** al final.

## Superficie

- `/feature` sin argumento: contrato actual **intacto** — un feature, gate individual, RECAP, OK.
- `/feature all`: todos los features pendientes del plan, en el orden del plan.
- `/feature NN..MM`: rango contiguo de features pendientes (p. ej. `/feature 07..09`).
- El batch es opt-in explícito y visible en el comando; no hay modo batch implícito.

## Qué reemplaza al OK por feature

El OK humano por feature cumple hoy dos funciones mezcladas: **(a)** validar rumbo y **(b)** marcar la frontera de contexto. En modo lote:

- **(b)** la resuelve la maquinaria: cada feature corre en un subagente con contexto fresco (y sesión de Codex fresca vía `review.sh new`), exactamente la regla de "sesiones frescas por feature".
- **(a)** se agrupa adelante: el **gate de lote** presenta en un solo mensaje los N resúmenes derivados de los docs (el mismo mecanismo del gate del feature 05, batcheado) y pide **un OK global**. El humano puede excluir features puntuales ("dale, pero el 09 no"); la exclusión queda registrada como corrección de alcance y el lote sigue con el resto.
- El **APPROVED de Codex por feature no cambia**: sigue siendo el gate de calidad, con su loop completo de rondas por feature.
- Cada feature deja su RECAP registrado en docs como siempre (es el registro), pero **no bloquea**; al final, un RECAP consolidado del lote → OK humano que cubre todo.

Esto **redefine la regla dura** "nunca continuar a otro feature sin OK humano": el OK del gate de lote ES el OK para los features autorizados del lote. La implementación debe reflejar la nueva redacción en `AGENTS.md` y `templates/AGENTS.md` (regla de sincronía).

## Arquitectura: orquestador supervisor + hijo trabajador

### Evidencia del spike (2026-07-28)

Entorno simulado (repo descartable, review falsa que duerme como Codex: 45–90s por ronda, una ronda de 11 min), loop completo de 8 rondas commit→review→veredicto ejecutado por un subagente:

- ✅ El subagente sostiene el loop: 8 rondas, 9 commits, veredicto siempre parseable, sin errores de herramienta ni salidas truncadas.
- ❌ **Hallazgo central**: el subagente **no se re-invoca** cuando su tarea background termina. Terminar el turno con la review corriendo lo deja huérfano (la review 1 terminó y quedó >6 min parado). Los avisos del harness le llegan *encolados* — se entregan recién en el próximo resume — y nunca lo despiertan; en la sesión principal ese mismo mecanismo sí re-invoca (el loop real de axel depende de eso a diario).
- ✅ El **resume por mensaje del orquestador** funcionó las 8 veces: contexto intacto, retoma en 7–18s del fin real de la review, sin releer ni repetir trabajo. La ronda de 11 min no degradó nada.
- ✅ Presión de contexto holgada (~15–20% de la ventana en el loop de juguete); estimación del propio subagente: 8–10 rondas reales viables sin compactación — el driver de consumo serían diffs y feedback largos, no la mecánica del loop.

### Contrato por ronda

- **Hijo** = el `/feature` de hoy casi sin cambios: gate resuelto por el lote, bajada fina, implementación, commits, y corre `scripts/review.sh` él mismo (misma sesión de Codex durante su feature, vía resume — como hoy). **Delta único**: donde la sesión de hoy espera el fin del background, el hijo **termina el turno** con una línea de estado ("review N lanzada"); lo despierta el orquestador.
- **Padre**: detecta el fin de cada review por filesystem — `review.sh` ya persiste por ronda la review completa (`.claude/state/last-review.md`), el veredicto (`last-verdict`) y la ronda (`round`); el padre observa ese estado, sin tocar `review.sh` — y manda un **empujón sin contenido** ("review N terminada, seguí"). El hijo lee veredicto y feedback de los archivos. El padre no transporta feedback → no acumula contexto de N features × M rondas y llega liviano al final del lote.
- **Entre features**: el padre verifica el cierre (IMPLEMENTATION marca cerrado, STATUS al día, commit de cierre presente), renueva la ventana de `awake.sh`, y lanza el subagente del siguiente feature con contexto fresco.

### El padre es el panel de control

La sesión que el humano abrió es el padre (principio 2 del diseño: la sesión es el proceso y el panel de control). Un mensaje del humano a mitad de lote llega al padre y tiene prioridad absoluta: el padre responde, y si el mensaje afecta al feature en curso, lo baja al hijo en el próximo empujón (o lo corta). El padre se mantiene liviano justamente para poder conversar a mitad de lote.

## Condiciones de corte

El lote se frena solo y espera al humano ante cualquiera de estas — sin esta lista el batch es una máquina de propagar errores:

1. Las del loop actual: deadlock (5 rondas), exit 2 persistente, veredicto inválido repetido.
2. Cambio de scope o sorpresa que excede el feature en curso.
3. **Divergencia**: el resumen re-derivado al arrancar el feature N no coincide en sustancia con lo autorizado en el gate de lote — los docs cambiaron por los features anteriores y la autorización quedó vieja.
4. Fuentes insuficientes para un resumen honesto del feature N.

En todos los casos: RECAP (con las posturas si hubo desacuerdo) + push de una línea + fin de turno. Los features ya cerrados quedan intactos.

## Riesgo aceptado

Un error del feature N se propaga a N+1 y N+2 antes del ojo humano, y la auditoría es por lote: el rollback es más caro que en el modo actual. Se acepta porque: historia lineal + un commit por paso + cierre por feature identificable (el commit de cierre que marca IMPLEMENTATION) hacen el rollback **por feature, no por lote**; y el gate de lote + las condiciones de corte acotan el radio. La divergencia (corte 3) cubre específicamente el caso "el 08 dependía de cómo saliera el 07".

## Encaje con reglas existentes

- **Avisos** (protocolo del feature 04, skill `recap`): el gate de lote es respuesta directa (el humano acaba de invocar `/feature all`) → sin push; el RECAP consolidado y todo corte llegan por trabajo autónomo → push de una línea.
- **awake.sh**: ventana renovable de 12h — el padre la renueva al arrancar cada feature del lote (un lote largo puede excederla).
- **Métricas**: `rounds-log` por feature, como hoy.
- **Commits de cierre no revisados**: dentro del lote los barre la ronda 1 del feature siguiente (regla vigente del contrato); los del último feature quedan cubiertos por el camino terminal de siempre (listados en el RECAP consolidado).

## Decisiones que quedan para la bajada (no exhaustivo)

- Señal exacta de fin de review que observa el padre (mtime/contenido de qué archivo; si conviene un marker explícito, es un cambio chico y versionado en `review.sh`).
- Forma exacta del empujón y de la línea de estado del hijo (protocolo mínimo probado en el spike: `REVIEW N LANZADA` / `REVIEW N TERMINADA`).
- Si el cierre de cada feature lleva tag de git además del commit identificable.
- Cómo baja exactamente al hijo un mensaje del humano a mitad de feature (empujón enriquecido vs. corte y relanzamiento).
- Validación del rango `NN..MM` (features inexistentes, no contiguos, ya cerrados).
