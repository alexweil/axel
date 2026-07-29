# Contrato de review (generador ↔ reviewer)

## Transporte

`scripts/review.sh {new|round}` con el pedido del generador por stdin.

- `new` abre una sesión nueva de Codex — se usa al arrancar una fase o un feature.
- `round` continúa la misma sesión vía `codex exec resume`: el reviewer conserva su contexto durante todo el feature, igual que el generador conserva el suyo en el chat.
- **El reviewer corre sobre un worktree snapshot** (`.claude/state/review-worktree`) clavado al commit bajo review: su observación (lecturas y ejecución de tests) queda congelada en ese SHA, y su sandbox de escritura queda confinado al snapshot — el repo canónico no es su workspace. `review.sh` re-clava el worktree (`reset --hard` + `clean -fdx`) en cada ronda, lo que además deshace mecánicamente cualquier residuo de la ronda anterior. La sesión de Codex queda anclada al path del worktree (que es estable) porque `resume` no permite cambiar cwd.

## Qué recibe el reviewer en cada ronda

1. Preámbulo generado por `review.sh`: número de ronda, rango de commits desde el último APPROVED (`git log --oneline` + archivos), y punteros a AGENTS.md, STATUS.md y este contrato.
2. El pedido del generador: qué se hizo, qué revisar específicamente, y evidencia (tests corridos, salidas relevantes).

## Obligaciones del reviewer

- Verificar lo hecho contra DESIGN/IMPLEMENTATION: ¿coincide con lo documentado? ¿los docs quedaron al día?
- Puede ejecutar comandos (tests, builds, linters) para verificar por su cuenta — sandbox `workspace-write`, confinado a su worktree snapshot, que se resetea solo en cada ronda. El repo canónico no se toca. No corre `scripts/review.sh` (recursión) ni `scripts/awake.sh stop`.
- Feedback en puntos numerados y accionables.
- Última línea EXACTA de su respuesta: `VERDICT: APPROVED` o `VERDICT: CHANGES_REQUESTED`.

## Obligaciones del generador

- Responder cada punto numerado: corrigiendo (con commit) o argumentando por qué no. El desacuerdo se resuelve dentro del loop, no se ignora.
- No pedir review sin haber corrido sus propias verificaciones primero.
- Al menos un commit por ronda (los docs cuentan como cambio).

## Semántica del veredicto

- El veredicto es la **última línea no vacía** del mensaje del reviewer, comparada literalmente (se toleran solo espacios alrededor). Un veredicto en el medio del mensaje no cuenta: exit 2.
- Si el proceso de Codex termina con error (exit ≠ 0), **no se toma veredicto** aunque haya quedado un mensaje escrito: exit 2.
- La review queda **clavada al `REVIEW_HEAD`** capturado al armar el pedido, en dos planos: el rango/aprobación se refieren a ese SHA, y la **observación también** (el reviewer lee y ejecuta sobre el worktree snapshot de ese SHA, no sobre el árbol vivo). Commits que aparezcan durante una review larga no afectan lo que el reviewer ve ni quedan aprobados — `review.sh` avisa y entran en el próximo rango. Se eligió esto en vez de invalidar la corrida: la review de un SHA es válida para ese SHA, y con la observación congelada ya no existe el riesgo de aprobar un SHA viejo mirando archivos nuevos.
- `APPROVED` mueve la base a `REVIEW_HEAD` (`.claude/state/last-approved-sha`) y resetea la racha. Un APPROVED intermedio (p. ej. de la bajada fina) no cierra el feature; el APPROVED de cierre es contra los criterios de cierre del doc del feature.
- **Fallas de proceso** (codex termina con RC≠0, o no deja mensaje final): `review.sh` las **reintenta una vez automáticamente, dentro de la misma ronda**, preservando los eventos del intento fallido en `last-review-events.failed.jsonl`. La frontera de contexto se respeta: un `new` fallido que alcanzó a emitir `thread.started` se reanuda con ese id exacto; sin id se relanza un `exec` nuevo — jamás `resume --last`, que podría retomar la sesión del feature anterior; un `round` fallido reintenta el resume del id vigente. `AXEL_REVIEW_RETRIES=0` lo desactiva. Si el exit 2 persiste, el generador diagnostica con los eventos y corta a RECAP.
- Un mensaje bien entregado cuya última línea no es un veredicto válido **no se reintenta** (no es transitorio: es incumplimiento del contrato): exit 2 directo.
- Exit codes de `review.sh`: 0 = APPROVED, 1 = CHANGES_REQUESTED, 2 = error / sin veredicto / deadlock.
- `status` muestra únicamente el **último resultado validado** (`.claude/state/last-verdict`, escrito solo cuando una corrida fue aceptada con veredicto estricto); jamás parsea el mensaje crudo del reviewer, así una corrida rechazada no puede aparentar un APPROVED.

## Deadlock

La regla de "5 rondas sin convergencia" se mide con una **racha de `CHANGES_REQUESTED` consecutivas** (`.claude/state/changes-streak`): se incrementa en cada ronda no convergida, se resetea con un APPROVED o al abrir ciclo con `new`. Al llegar a 5, `review.sh` **se niega a lanzar otra ronda** (exit 2 con `DEADLOCK` en stderr, antes de gastar tokens): el generador distingue ese caso de un error transitorio — el deadlock **no se reintenta**; arma un RECAP con ambas posturas para que desempate el humano y, tras el desempate, corre `scripts/review.sh reset-deadlock` para continuar. `status` muestra ronda y racha.

## Commits de cierre (bookkeeping)

Tras el APPROVED final de un feature, el generador hace commits de cierre (solo docs: STATUS.md, IMPLEMENTATION.md, review log) que quedan después de la base aprobada. **No mueven la base**: aparecen al inicio del rango de la ronda 1 del ciclo siguiente, donde el reviewer los verifica como primer ítem. Así ningún commit queda sin review, sin necesidad de una corrida extra por el cierre.

**Camino terminal** (no hay ciclo siguiente: fin del proyecto o pausa larga): los commits de cierre quedan cubiertos por el **OK humano del RECAP final**, que debe listarlos explícitamente como no-revisados-por-Codex; si el generador considera que el cierre tuvo sustancia más allá de bookkeeping, pide antes una mini-review (`round`) sobre esos commits.

**Excepción: el commit de registro del OK** (2026-07-28, ciclo de diseño del batch). El commit **post-OK** que solo transcribe un OK ya recibido — estados a "Cerrado" en IMPLEMENTATION, STATUS al paso siguiente, y en modo lote el cierre del ledger — no existe al presentarse el RECAP y por eso no puede viajar listado en él; queda **cubierto por el OK que registra**: su contenido está íntegramente determinado por ese OK — la autoridad es el OK, el commit es su transcripción mecánica. Condición estricta: solo esos archivos y solo esa transcripción; cualquier cosa de más no entra en la excepción — es trabajo nuevo y pasa por el loop (o pide mini-review antes). El barrido por la ronda 1 del ciclo siguiente se mantiene como auditoría normal cuando ese ciclo existe.

## Observabilidad local (métricas)

`review.sh` registra cada evento del loop en `.claude/state/rounds-log` (no versionado), con esquema fijo `fecha · modo · ronda · intento · resultado · SHA corto · racha`. Resultados con invocación (intento numérico): `APPROVED`, `CHANGES_REQUESTED`, `NO_VERDICT` (mensaje entregado con última línea inválida), `PROC_FAIL` (una línea por intento fallido de proceso). Eventos **pre-invocación** (ronda/intento/SHA en `-`): `DEADLOCK` e `INPUT_ERROR` (stdin vacío) — todo rechazo deja línea, así la frontera de ciclo siempre existe. La frontera es la línea que **abre** el último ciclo: el **intento 1 (o el `INPUT_ERROR`) de un `new`, falle o no** — el intento 2 de un retry de `new` pertenece al mismo ciclo, no abre otro. Denominadores: eventos = líneas; intentos = líneas con intento numérico; rondas = números distintos — un fallo de proceso seguido de éxito son dos intentos de la misma ronda. `status` resume el ciclo actual con esos denominadores. Es observabilidad local **no autoritativa y best-effort**: si el log no puede escribirse, `review.sh` avisa por stderr y nada más cambia — jamás altera veredicto, estado ni exit code; la memoria oficial por feature sigue siendo el Review log de los docs.

## Señal terminal

`review.sh` publica, como **último acto de todo camino de salida** de `new|round`, un registro terminal en `.claude/state/review-terminal` — **atómico** (tmp + `mv` en el mismo filesystem: ningún lector ve un terminal a medias) y con la identidad de la invocación, una `clave=valor` por línea: `ts` (ISO-8601 UTC), `id` (env `AXEL_REVIEW_ID`, `-` si no vino), `mode` (`new|round`), `round` y `review_head` (`-` en los rechazos pre-invocación), `result` (`APPROVED | CHANGES_REQUESTED | NO_VERDICT | PROC_FAIL | DEADLOCK | INPUT_ERROR | ABORTED`) y `rc` (el exit code real). Reglas:

- `id` es la **identidad de invocación** del modo lote de `/feature` (protocolo operativo: skill `feature`; el diseño de fondo vive en el repo axel como `design/batch-features.md`, fuera del payload instalado): el invocador la pasa por env con unicidad real por invocación (`<NN>:r<M>:<nonce>`). Fuera del lote no se setea (`id=-`) y nada del flujo cambia; ese terminal es el que consume la **reentrada individual** de cualquier fase, con la identidad que define §Reentrada.
- `ABORTED` es el default para una salida no clasificada (p. ej. un fallo de `set -e` a mitad de corrida), con lo capturado hasta ahí.
- `status`, `reset-deadlock` y el uso inválido **no** son invocaciones de review: no escriben terminal.
- Para todo consumidor —el padre del lote, o la reentrada de una fase tras una sesión caída— el terminal es el **desenlace autoritativo**: `last-verdict` y `last-review.md` solo son vigentes cuando `result` es `APPROVED` o `CHANGES_REQUESTED` — ante cualquier otro resultado quedaron deliberadamente viejos.
- El consumidor solo reacciona a un terminal cuya **identidad completa** coincide con la invocación que espera (con `id`: el nonce exacto y, cuando `review_head` ≠ `-`, también el SHA; sin `id`: las cuatro condiciones de §Reentrada); un residuo de otra invocación se ignora — la ausencia de terminal se resuelve por timeout del lado del lector o entregándola al humano, jamás adivinando.
- La escritura es blindada y best-effort: si el terminal no puede publicarse, la corrida no cambia en nada (veredicto, estado y exit code intactos).

Regresión: clase L10 de `tests/loop.sh`.

## Reentrada: reconstrucción tras una sesión caída

Una sesión del generador puede morir en cualquier punto del loop (máquina reiniciada, terminal cerrada, contexto agotado). La que reabre **reconstruye antes de actuar**, fail-closed: no relanza ni duplica una review que puede estar en vuelo, no reprocesa a ciegas feedback ya atendido, no re-pide un gate ya dado ni re-cierra lo aprobado, y ante inconsistencia arma un RECAP en vez de adivinar. Lo que sigue es la parte **común a todas las fases**; el mapa «estado de los docs → paso del camino» vive en cada skill (`design`, `plan`, `feature`). El **modo lote** tiene su propia reentrada, con precedencia y ancla propias (skill `feature`): un terminal con `id` ≠ `-` nunca lo consume el camino individual.

### Token de ronda en `STATUS.md`

El estado local (`.claude/state/round`) no alcanza como ancla: se escribe **antes** de invocar a Codex, no distingue «desenlace pendiente» de «desenlace ya integrado», y no es versionado. El ancla es la línea de ronda de STATUS, que el loop ya commitea justo antes de cada review:

```
- **Ronda de review**: 3 · lanzada      # la ronda 3 se lanza sobre el HEAD de ESTE commit; su desenlace no fue consumido
- **Ronda de review**: 3 · consumida    # el desenlace de la ronda 3 se consumió y este commit NO lanza review
- **Ronda de review**: —                # no hay ciclo de review abierto en esta fase/feature
```

El número es **siempre el de `review.sh`** (el que el terminal publica en `round=`), nunca un acumulado, y se **deriva** de `.claude/state/round` — la misma fuente de la que `review.sh round` calcula el suyo (ver «Precondición de la ronda siguiente»). Transiciones, sin commits extra:

| Commit | Token |
|---|---|
| El que precede a una invocación | `N · lanzada` |
| El siguiente al desenlace, **si vuelve a invocar** | `N+1 · lanzada` — el salto **es** el hecho «N consumida y N+1 lanzada»: ocurren en el mismo commit |
| El siguiente al desenlace, **si no invoca** (APPROVED consumido, paso intermedio, cierre, RECAP) | `N · consumida` |
| Cierre del ciclo | `—` |

Un ciclo reabierto con `new` vuelve a `1`, y eso escribe STATUS; la cuenta acumulada de la fase o feature vive en su Review log (features) o en las líneas de commit del ciclo, que nombran la ronda (design/plan), junto con el registro de que `new` rearmó la racha de deadlock.

La línea **«Esperando»** usa vocabulario fijo: «esperando OK humano», «esperando confirmación de arranque», «esperando autorización de lote», «esperando confirmación de plan» (las cuatro esperas **humanas**: las únicas que disparan re-presentación y aviso), «esperando el desenlace de la review (ronda N)», o «nada del humano — \<trabajo en curso\>». La cuarta la fija el ruteo implícito —`/plan` despachado por contexto no tiene gate propio— y es la única que **lleva contenido en la línea**: la interpretación del pedido, que no es derivable de los docs porque su fuente era el chat; las otras tres re-derivan su presentación de los docs.

### Frontera previa

Un solo chequeo antes de resolver nada: **árbol sucio** (`git status --porcelain` no vacío) ⇒ la sesión caída dejó trabajo sin commitear. Ni absorberlo ni descartarlo: listarlo y preguntar. *(El estado local de la sesión de Codex **no** se evalúa acá: ver la precondición del final.)*

### Resolución del desenlace de una review

Fuentes: la línea de ronda de STATUS, `.claude/state/review-terminal` y el HEAD actual. **Identidad de la invocación individual** — las cuatro condiciones, todas necesarias:

1. `id=-` (un terminal con id es de un lote y no es de este camino);
2. `mode` coherente con la ronda declarada (`1 ⇒ new`, `>1 ⇒ round`);
3. `round` = la ronda declarada en STATUS;
4. `review_head` = HEAD actual.

HEAD no siempre es el SHA que se lanzó — el contrato admite commits durante una review; cuando eso pasa, la condición 4 falla y el caso degrada a ambiguo, que es el resultado seguro.

| STATUS | Terminal | Acción |
|---|---|---|
| `N · lanzada` | las **cuatro** condiciones | La ronda N terminó sin consumirse. Actuar según `result`: `APPROVED`/`CHANGES_REQUESTED` ⇒ `last-verdict` y `last-review.md` vigentes, seguir el loop; cualquier otro ⇒ quedaron viejos: camino de fallas del loop (`DEADLOCK` no se reintenta). |
| `N · lanzada` | cualquier otra cosa: ausente, `id` ≠ `-`, `mode` incoherente, otra ronda, otro `review_head`, o un rechazo pre-invocación (`round=-`, `review_head=-`) | **Ambiguo**: la review puede estar en vuelo. **No relanzar ni duplicar** — entregarlo al humano con la evidencia y dos salidas: esperar el desenlace poleando el terminal (~15 s, tope 45 min) o relanzar si confirma que el proceso murió. |
| `N · consumida` o `—` | irrelevante | No hay review en vuelo ni desenlace pendiente: seguir el loop desde donde los docs dicen. El Review log y los commits dicen qué feedback ya fue atendido — **jamás reprocesar a ciegas**. |
| Línea **sin token** (STATUS previo a esta convención) | — | **No concluyente**: se consume como la fila 1 solo si el estado local está presente y coherente y el terminal cumple las cuatro condiciones **contra él** (`round` = `.claude/state/round`, `mode` coherente, `id=-`, `review_head` = HEAD). Si no: RECAP sin relanzar. |

Los rechazos **pre-invocación** (`DEADLOCK`, `INPUT_ERROR`) publican `round=-` y `review_head=-`: no hay nada que atarlos a la ronda declarada, y un `ts` posterior prueba orden temporal, **no identidad** — por eso caen en ambiguo como el resto. **Evidencia best-effort para el humano, nunca autoritativa**: `ts` del terminal contra la fecha del commit de la marca (`git log -1 --format=%cI`), mtime de `.claude/state/last-review-events.jsonl` (Codex escribe ahí mientras corre), `pgrep -fl "codex exec"` y `.claude/state/changes-streak` (en ≥ 5 el loop está bloqueado por deadlock y el camino es el desempate humano + `reset-deadlock`). Ninguna decide sola: `pgrep` no ata un proceso a **este** repo y un mtime es un indicio. Decidir desde un indicio es lo que el fail-closed prohíbe.

### Precondición de la ronda siguiente

Se evalúa **antes de elegir el token y commitear**, al lanzar — jamás en la reentrada. Dos chequeos sobre el estado local, del que salen los dos números que tienen que coincidir:

1. `.claude/state/round` presente y **numérico**: el token se deriva de ahí (`N` = `round` + 1, lo mismo que `review.sh round` va a calcular) y debe coincidir con la ronda recién consumida (`round` = `N-1`). El primer lanzamiento de un ciclo no necesita derivación **y no debe derivarse**: `new` publica siempre `1`, y hasta que la invocación reescriba el contador este puede conservar el valor del ciclo anterior — derivar ahí daría un token distinto del `round=1` publicado.
2. `.claude/state/codex-session-id` presente y del ciclo vigente — sin él, `round` cae en `resume --last` y puede retomar la sesión de otro feature.

Desenlaces: **pérdida** del estado local (contador ausente o no numérico, o session id ausente) ⇒ no invocar `round`: reabrir con `new`, declarar `1 · lanzada` y registrar la ronda acumulada y la racha rearmada. **Contador numérico pero distinto del esperado** ⇒ hubo una invocación que el ciclo no registra ⇒ corte conservador (RECAP), sin invocar nada: un estado local incoherente no se repara adivinando, ni gastando una review cuyo desenlace la identidad va a rechazar.

La ausencia del session id **no prueba** que la sesión murió: `review.sh` lo borra al arrancar un `new` y lo reescribe recién al capturar `thread.started`, así que durante un `new` en vuelo su ausencia es normal. Por eso el orden de la reentrada es: árbol sucio → resolver el desenlace → y solo si el paso siguiente necesita una ronda nueva, esta precondición. Un terminal ya publicado se consume igual aunque el contador o la sesión se hayan perdido: el desenlace no depende de ninguno de los dos.

## Ciclo de vida de sesiones

- `new` borra el session id guardado, corre `codex exec` y captura el id nuevo como el **`thread_id` del evento `thread.started`** de los eventos JSONL — nunca "el primer UUID del archivo", que mezcla el stderr de codex y podría contener uno espurio (fallback sin `thread.started`: aviso y `resume --last`).
- `round` usa el id guardado en `.claude/state/codex-session-id`. Cambio de feature ⇒ siempre `new`.
- Config del reviewer: variables al tope de `review.sh`; overrides puntuales por env `AXEL_REVIEW_MODEL/EFFORT/SANDBOX` (p. ej. smoke tests con esfuerzo `low`).
- Reviews con esfuerzo xhigh pueden tardar >10 minutos: el generador corre `review.sh` en background y continúa cuando termina, sin duplicar la corrida.
- `review.sh` envuelve la invocación de Codex en `caffeinate -is` (scoped al proceso: la assertion muere con él), para que una review larga nunca se corte porque la máquina se durmió. La cobertura del lado del generador la da `scripts/awake.sh`.
