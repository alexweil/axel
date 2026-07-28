---
name: feature
description: Continuar el loop de axel con el feature en curso o el siguiente — bajada fina, implementación iterando con review de Codex, RECAP y espera del OK humano. Modo lote con `/feature all` o `/feature NN..MM`.
---

Sos el generador del loop de axel. Antes de nada leé: `docs/STATUS.md`, `AGENTS.md`, `docs/IMPLEMENTATION.md` y, si existe, el doc del feature en curso (`docs/implementation/NN-*.md`).

**Argumento**: sin argumento = un feature (los caminos de abajo). `all` o `NN..MM` = **modo lote** (su sección, abajo). Si STATUS apunta a un **ledger de lote en curso**, seguí «Reentrada del lote» — con o sin argumento.

## Si STATUS dice "esperando OK humano"

No avances trabajo nuevo: presentale al humano el RECAP pendiente (estructura y aviso: skill `recap`; acá llegás por respuesta directa a su mensaje) y esperá su respuesta.
Cuando el OK llegue: actualizá STATUS.md al siguiente paso y commiteá. Si el OK cierra el RECAP consolidado de un **lote**, ese mismo commit es el cierre consolidado (excepción del commit de registro del OK, contrato): features del lote a "Cerrado" en IMPLEMENTATION.md, cierre del ledger, STATUS — solo esa transcripción. Si el OK cierra un feature (o un lote), el siguiente arranca en **sesión limpia** — no lo implementes en esta: el contexto por feature es regla del método. Facilitá ese arranque: si la sesión tiene herramienta de spawn de sesión (hoy: el chip de spawn del desktop), creá el chip — título "Feature NN: <nombre> — sesión limpia", prompt **únicamente `/feature`** (el estado vive en los docs, el chip no lleva contexto del chat), tldr de una línea; si la herramienta no está o su invocación falla, instrucción única en el chat: sesión nueva en este repo + `/feature` (desde terminal: `claude "/feature"`). Si no queda feature siguiente en IMPLEMENTATION.md, no hay chip que crear: ofrecé `/plan` por si el humano quiere extender el plan.

## Si STATUS dice «esperando confirmación de arranque»

El gate de arranque quedó presentado sin confirmación registrada: no avances trabajo nuevo. Re-derivá el resumen de las mismas fuentes (los docs son la fuente; la presentación anterior no se persiste) y re-presentá el gate: resumen + pedido de confirmación explícito. Procedencia: respuesta directa a la reapertura del humano — aviso según skill `recap`. Con la confirmación, seguí desde el paso 3 del camino "Feature nuevo".

## Si STATUS dice «esperando autorización de lote»

El gate de lote quedó presentado sin autorización registrada: no avances trabajo nuevo. Re-derivá los N resúmenes de los docs y re-presentá el gate de lote completo (resúmenes + pedido de autorización). Procedencia: respuesta directa — aviso según skill `recap`. Con la autorización, seguí desde el bloque **«Con la autorización»** del paso 2 del modo lote — no re-presentes ni pidas una segunda autorización.

## Feature nuevo (STATUS no apunta a ninguno en curso)

1. Tomá el siguiente feature según la prioridad de IMPLEMENTATION.md.
2. **Gate de arranque** — antes de cualquier implementación: derivá un resumen breve de lo que se va a implementar desde lo disponible — la entrada del feature en IMPLEMENTATION.md (fila de la tabla y, si existe, su sección) más DESIGN.md si hace falta. Si las fuentes no alcanzan para un resumen fiel, decilo explícitamente y presentá lo que hay — sin inventar ni bloquearte. STATUS.md → «esperando confirmación de arranque» (frase literal: es el disparador de la re-presentación) + commit. Presentá el resumen y pedí la confirmación explícita; la espera es respuesta directa (el humano acaba de abrir la sesión o clickear el chip) — aviso según skill `recap`. **Terminá el turno.**
3. **Con la confirmación**: registrala en el doc del feature — fecha, literal breve y correcciones de alcance si las hubo; el doc lo crea la bajada fina, el registro viaja en su commit. Una corrección del humano manda: la bajada la incorpora. Si el humano no confirma, su mensaje tiene prioridad absoluta: seguí su indicación — y si invalida el feature, el camino es `/plan`, no forzar el arranque.
4. **Bajada fina** → `docs/implementation/NN-nombre.md`: alcance, enfoque técnico, criterios de cierre, riesgos, y una sección "Review log" vacía. STATUS.md → feature en curso. Commit.
5. **Review de la bajada**: `scripts/review.sh new` con un pedido que explique qué revisar (la bajada contra DESIGN/IMPLEMENTATION). Iterá hasta APPROVED: cada ronda es corregir o argumentar → commit → `scripts/review.sh round`.
6. **Implementación en pasos chicos**. En cada paso: cambios + doc del feature al día (decisiones al Review log) + STATUS.md → commit → `scripts/review.sh round` con un pedido que diga QUÉ verificar y la evidencia (tests corridos por vos, con salida). Respondé cada punto numerado del feedback: corrección con commit, o argumento; Codex mantiene contexto por resume, la discusión se resuelve en el loop.
7. **APPROVED de cierre** (criterios de cierre del doc cumplidos) → IMPLEMENTATION.md marca el feature cerrado, STATUS.md → "esperando OK" → commit de cierre → RECAP (estructura y aviso: skill `recap` — llegás por trabajo autónomo) → **terminá el turno**. No sigas trabajando. (Los commits de cierre no mueven la base: los verifica la ronda 1 del ciclo siguiente — regla del contrato.)
8. **Camino terminal**: si este feature es el último previsto (no queda siguiente en IMPLEMENTATION.md, o el humano indicó frenar acá), no hay ciclo que barra los commits de cierre — el RECAP debe listarlos explícitamente como no-revisados-por-Codex y tu OK es lo que los cubre; si el cierre tuvo sustancia más allá de bookkeeping, pedí antes una mini-review con `scripts/review.sh round` sobre esos commits.

## Modo lote (`/feature all` · `/feature NN..MM`)

Varios features pendientes en una sola corrida: gate de lote al inicio, un **subagente fresco por feature** (vos sos el padre orquestador), RECAP consolidado al final cuyo OK cierra. El protocolo operativo completo vive en esta skill; la señal terminal es contrato de `review.sh` (`docs/design/review-contract.md`, instalado con la maquinaria). El diseño de fondo es un doc del repo axel (`docs/design/batch-features.md` allá), no parte del payload instalado.

**Requisito de harness**: subagentes en background reanudables por mensaje (hoy: la herramienta de agentes + SendMessage). Si la sesión no los tiene, decilo y ofrecé el flujo individual — no degrades a un lote sin fronteras de contexto.

1. **Validación** — contra la tabla de IMPLEMENTATION.md, fail-closed: `all` = todos los features **Pendiente** en el orden de la tabla (cero pendientes ⇒ no hay lote: ofrecé `/plan`); `NN..MM` = las filas existentes con NN ≤ # ≤ MM — rechazo con diagnóstico si un extremo no existe, NN > MM, o algún feature del rango no está Pendiente (un lote no retoma features a medias ni saltea cerrados intercalados). Números sin fila entre los extremos no son error (la tabla manda). Lote de 1: válido.
2. **Gate de lote**: derivá los N resúmenes (el mecanismo del gate individual, por feature; si las fuentes no alcanzan para el feature K, decilo — el humano decide si lo excluye o frena). STATUS.md → «esperando autorización de lote» (frase literal) + commit. Presentá los N resúmenes y pedí **una autorización global** — exclusiones puntuales bienvenidas («dale, pero el 09 no»). Respuesta directa ⇒ sin push. **Terminá el turno.**
   **Con la autorización**: anotá `gate_base` = SHA de HEAD **en este momento, antes del commit siguiente**. Creá el ledger (esqueleto abajo) con comando, features autorizados en orden, exclusiones/correcciones literales, los N resúmenes **tal como se autorizaron** y `gate_base`. STATUS → lote en curso, apuntando al ledger. Commit. `scripts/awake.sh start`.
3. **Loop del padre**, por cada feature autorizado en orden:
   - **Pre-arranque**: re-derivá el resumen del feature de los docs actuales y comparalo en sustancia con el autorizado en el ledger — divergencia ⇒ corte (condición 3); fuentes insuficientes ⇒ corte (condición 4). Renovó la ventana: `scripts/awake.sh start`.
   - Registrá el arranque en el ledger (estado «en curso» + evento) + STATUS + commit.
   - **Lanzá el hijo**: subagente fresco en background, prompt mínimo sin contexto del chat: «Modo hijo del lote: feature NN. Ledger: docs/implementation/batch-<fecha>.md. Leé docs/STATUS.md, AGENTS.md, docs/IMPLEMENTATION.md y el ledger, y seguí la sección "Modo hijo" de la skill feature.»
   - **Supervisión**: cuando el hijo termine un turno con `REVIEW LANZADA id=X head=H`, lanzá un watcher en Bash background que polee `.claude/state/review-terminal` (cada ~15 s, **timeout 45 min**) esperando la **identidad completa**: `id` = X exacto y, si el terminal trae `review_head` ≠ `-`, también H. Un terminal que no matchea es un residuo de otra invocación: **ignoralo y seguí esperando** — solo el timeout corta (condición 1). Match ⇒ **empujón sin contenido** al hijo: «review terminada (id=X) — el desenlace está en `.claude/state/review-terminal`; seguí según el contrato». Ejemplo de watcher (adaptá ID/HEAD):

     ```bash
     T=.claude/state/review-terminal; deadline=$(($(date +%s)+2700))
     while [ "$(date +%s)" -lt "$deadline" ]; do
       if grep -qxF "id=ID_ESPERADO" "$T" 2>/dev/null; then
         H="$(grep '^review_head=' "$T" | cut -d= -f2-)"
         { [ "$H" = "-" ] || [ "$H" = "HEAD_ESPERADO" ]; } && { cat "$T"; exit 0; }
       fi
       sleep 15
     done; echo "TIMEOUT: sin terminal id=ID_ESPERADO"; exit 1
     ```
   - `FEATURE NN APROBADO` ⇒ verificá el estado (IMPLEMENTATION con «APPROVED — pendiente OK de lote», STATUS al día, commits presentes, `batch-expected` borrada) ⇒ ledger (estado, SHAs frontera, evento con ronda final) + commit ⇒ siguiente feature.
   - `CORTE: <motivo>` del hijo, o corte propio (condiciones: las del loop actual + timeout de terminal; cambio de scope; divergencia; fuentes insuficientes) ⇒ **verificá el árbol antes de commitear**: si el hijo dejó cambios sin commitear (staged o unstaged — violación del handshake), no los absorbas — registrá el corte en el ledger y commiteá **restringido por pathspec**: `git commit --only -- docs/implementation/batch-<fecha>.md -m "…"`, que ignora el index para todo lo demás y preserva intacta la suciedad del hijo (un `git add <ledger>` + commit normal arrastraría lo staged); reportá la suciedad en el RECAP. Luego: RECAP con el estado encontrado (posturas de ambos agentes si hubo desacuerdo) + **push de una línea** + fin de turno. Los features ya aprobados quedan intactos.
   - **Mensajes del humano a mitad de lote**: prioridad absoluta. Respondé; si afecta al feature en curso, bajalo **de inmediato** por mensaje al hijo (lo despierta aunque espere una review; lo atiende antes de seguir); si invalida el feature o el lote ⇒ corte.
4. **Fin del lote**: ledger con todos los estados finales + STATUS «esperando OK» + commit → **RECAP consolidado** (skill `recap`: base `gate_base`, estructura por feature, no-revisados listados) → push de una línea → **fin de turno**.
5. **OK del RECAP consolidado** ⇒ el camino "esperando OK humano" de arriba (cierre consolidado en el commit de registro + facilitar la sesión siguiente).

### Modo hijo

Sos el hijo de un lote: tu feature es NN y tu memoria son los docs (STATUS, AGENTS, IMPLEMENTATION, el ledger, y el doc de tu feature cuando exista). Seguís el camino «Feature nuevo» con tres deltas:

1. **Gate**: no pidas confirmación — el gate de lote ya autorizó. Registrá en el doc del feature la autorización (fecha, comando del lote, path del ledger) en lugar del literal individual; las correcciones de alcance del gate que toquen tu feature mandan.
2. **Reviews**: generá un id único `<NN>:r<M>:<nonce>` (`uuidgen`; fallback `$(date +%s)-$$-$RANDOM`). Escribí `.claude/state/batch-expected` **atómica** (tmp + `mv -f`; contenido: `id=`, `head=`, `feature=NN`, `phase=launched`) — si no puede escribirse, **no lances**: es corte. Lanzá `AXEL_REVIEW_ID=<id> scripts/review.sh {new|round}` en background y **terminá el turno** con última línea exacta: `REVIEW LANZADA id=<id> head=<sha de tu HEAD>`. Al despertar por el empujón: validá la identidad del terminal (id, y head si ≠ `-`), marcá `phase=consumed` en el ancla (reescritura atómica) **antes de actuar**, y actuá según `result`: `APPROVED`/`CHANGES_REQUESTED` ⇒ `last-verdict` y `last-review.md` están vigentes — seguí el loop normal; cualquier otro resultado ⇒ esos archivos quedaron viejos — camino de fallas del loop vigente (diagnóstico, relanzamiento único si es claramente transitorio; deadlock o falla persistente ⇒ `CORTE:`).
3. **Cierre**: con el APPROVED de cierre dejá IMPLEMENTATION en «**APPROVED — pendiente OK de lote**» (no "Cerrado": ese estado exige el OK humano), doc del feature y STATUS al día, borrá `batch-expected`, commit, y terminá con última línea `FEATURE NN APROBADO`. **Sin RECAP individual, sin push, sin chip.** Ante condición de corte: registrá el detalle en el doc de tu feature, **commiteá y dejá el árbol limpio** — el handshake exige frontera limpia: nada tuyo sin commitear — y terminá con última línea `CORTE: <motivo breve>` (el ledger lo registra el padre).

Mensajes bajados por el padre a mitad de feature: prioridad absoluta — atendelos antes de seguir.

### Reentrada del lote

STATUS apunta a un ledger en curso y no hay padre vivo. Leé STATUS + ledger + git y decidí **fail-closed**. **Primero el ledger**: si registra un corte sin resolución humana posterior, el corte es **absorbente** — no relances nada aunque el ancla y el terminal matcheen (el ancla se conserva como evidencia justamente en ese caso): re-presentá el RECAP del corte (respuesta directa — sin push) y esperá al humano. Solo sin corte pendiente aplica la máquina de estados de `.claude/state/batch-expected`:

- `phase=launched` + terminal con identidad completa coincidente ⇒ la review terminó sin consumirse: relanzá un hijo fresco para ese feature — retoma leyendo el terminal.
- `phase=launched` + terminal ausente o de otra identidad ⇒ review posiblemente en vuelo: **no relances** — RECAP con lo encontrado.
- `phase=consumed` ⇒ no hay review en vuelo ni desenlace pendiente: consistencia normal (ledger + git + doc del feature); el hijo relanzado reconstruye de los docs qué feedback ya fue atendido — jamás reprocesa a ciegas.
- **Ancla ausente**: solo cuenta como «no había review en vuelo» si el resto del estado local del loop del feature en curso está presente y coherente (`codex-session-id`, `round`). Sin ese estado local (máquina distinta), mandan STATUS + ledger y, ante cualquier duda, el corte conservador: RECAP sin relanzar.

Nunca re-pidas el gate autorizado ni re-cierres lo aprobado. El resto de las inconsistencias (ledger contradictorio con git o IMPLEMENTATION) ⇒ RECAP.

### Esqueleto del ledger (`docs/implementation/batch-YYYY-MM-DD.md`; colisión ⇒ sufijo `-2`, `-3`…)

```markdown
# Lote YYYY-MM-DD — `/feature <comando>`

## Gate
- Autorizado: <fecha> — «<literal breve del humano>»
- Features (en orden): NN, NN…  · Exclusiones/correcciones: <literales, o «ninguna»>
- gate_base: <SHA de HEAD al autorizarse, previo al commit de este ledger>

## Resúmenes autorizados
### NN — <nombre>
<resumen tal como se presentó>

## Estado
| # | Feature | Estado | SHA inicio | SHA APPROVED |
|---|---|---|---|---|
(pendiente → en curso → APPROVED — pendiente OK de lote → cerrado)

## Eventos
- <ts> — <arranque de hijo / APPROVED rN / corte con motivo / …>

## Cierre
- <OK humano (fecha, literal) o corte final>
```

## Reglas del loop

- Al entrar al loop corré `scripts/awake.sh start` (renueva la ventana de 12h para que la máquina no se duerma; cubre generación y review). Dejala corriendo durante la espera de OK — el backstop es el timeout; `scripts/awake.sh stop` solo si el humano lo pide. En modo lote el padre la renueva al arrancar cada feature.
- Reviews largas (xhigh puede tardar >10 min): corré `scripts/review.sh` con Bash en background (`run_in_background`) y continuá cuando termine. No dupliques una review en curso.
- Tope de 5 rondas sin convergencia, cambio de scope, o algo roto que excede el feature → cortá a RECAP temprano con las posturas de ambos agentes. Todo RECAP sigue la skill `recap` (estructura y aviso — el criterio de cuándo va push vive ahí).
- `review.sh` exit 2: mirá el stderr. Si dice `DEADLOCK` **no reintentes**: armá el RECAP con ambas posturas y esperá el desempate humano; con su OK corré `scripts/review.sh reset-deadlock` y seguí según lo que él decida. Si fue una falla de proceso (codex caído, sin mensaje final), `review.sh` **ya la reintentó una vez** — diagnosticá con `.claude/state/last-review-events.jsonl` (y `last-review-events.failed.jsonl`, el intento fallido); solo si la causa es claramente transitoria relanzá la ronda una vez más, y si persiste, RECAP con el problema. Si fue un veredicto inválido (mensaje entregado sin la línea exacta), no es transitorio: relanzá una ronda recordándole el contrato al reviewer, y si se repite, RECAP.
- Todo commit toca algún doc. `main` lineal, sin amend.
- Mensajes del humano a mitad del loop: prioridad absoluta — respondé y ajustá antes de seguir.
