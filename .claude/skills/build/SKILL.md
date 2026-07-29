---
name: build
description: Pipeline de axel — un pedido que cruza dos o más fases (diseño, plan, features) encadenado en una sola corrida: gate único con la ruta propuesta, un subagente fresco por unidad con su loop de review, y RECAP consolidado cuyo OK cierra todo. Usala cuando lo que el humano pide necesita **más de una fase** para quedar hecho: una idea que hay que diseñar, planificar e implementar; algo que implementar sin feature en el plan; un proyecto virgen del que se quiere un POC visible — aunque no escriba /build. Si el pedido necesita una sola fase, la skill de esa fase, no esta.
---

Sos el generador del loop de axel y el **padre orquestador** de un pipeline. Antes de nada leé: `docs/STATUS.md`, `AGENTS.md`, `docs/DESIGN.md` y `docs/IMPLEMENTATION.md`.

**Guarda de entrada.** Un pipeline encadena fases, así que **jamás** arranca sobre estado pendiente: si STATUS registra adopción sin cerrar (`docs/ADOPTION.md`), cualquiera de las esperas humanas, una review lanzada sin desenlace consumido, o una fase/feature/lote/pipeline activo, no valides ni presentes nada — decí qué encontraste y entrá por la reentrada de la skill dueña (si el estado es de un **pipeline**, es tuyo: «Reentrada del pipeline», abajo). Esto vale **también con `/build` explícito**, y es la única asimetría del método: los demás comandos de fase tipeados conservan su contrato (informan el estado ajeno y manda el humano), pero `/build` no lo puentea — dejarlo arrancar sobre una espera abierta la propagaría sin resolver a través de N unidades. Es lo que fija el diseño; esta guarda lo hace valer aunque `AGENTS.md` §Ruteo falte (es semilla del instalador).

**Requisito de harness**: subagentes en background reanudables por mensaje (hoy: la herramienta de agentes + SendMessage). Sin eso, decilo y ofrecé el camino fase por fase — no degrades a un pipeline sin fronteras de contexto.

## 1. Validación del pedido (fail-closed, antes de escribir nada)

| Pedido | Qué hacés |
|---|---|
| **vacío** (`/build` sin argumento) | no hay pedido que rutear: **preguntá en una línea** qué quiere construir. No asumas «seguí con lo que hay» — eso es `/feature` |
| **que no toca ninguna fase** (consulta, charla, algo fuera del método) | no hay pipeline: entregá a `/status` si era consulta; si no, preguntá |
| **monofase** | **despacho directo** a la skill de esa fase, con su punto de confirmación (y `/plan` con su confirmación liviana). `/build` **no cuenta como autorización**: la autorización es siempre de un gate. No se crea ledger |
| **con una premisa factual refutada por los docs** | nombrá el hecho registrado y **preguntá**, sin arrancar |
| **multifase, estado estable** | gate de pipeline (paso 2) |

La categoría de premisa refutada es **angosta**: el pedido **afirma como hecho** algo que los docs registran de otro modo («el feature 05 nunca se hizo, implementalo» contra una tabla que lo marca Cerrado). Dos cosas que **no** son contradicción: que el plan **todavía no tenga** lo pedido (eso es el caso multifase normal — «implementá X» con backlog vacío necesita un plan-delta antes de implementar), y **pedir cambiar lo registrado**, que es precisamente el trabajo (un pedido de cambiar una decisión de `DESIGN.md` es un design-delta legítimo).

## 2. Ruta y gate de pipeline

**Derivá la ruta** leyendo STATUS/DESIGN/IMPLEMENTATION: ¿el pedido cambia el diseño? → unidad `design-delta`. ¿Agrega o reordena features? → `plan-delta`. ¿Implementa? → una unidad `feature` por cada uno. Cada fase trabaja un **delta acotado al pedido**, no una pasada completa del proyecto, y el plan-delta prioriza que el **resultado visible llegue lo antes posible**.

| Tipo | id | Skill del hijo |
|---|---|---|
| `design-delta` | `design` | `design` |
| `plan-delta` | `plan` | `plan` |
| `feature` | `NN` (el número del plan) | `feature` |

Orden fijo `design` → `plan` → features en el orden del plan (es la dependencia, no una preferencia), a lo sumo **una** unidad de cada delta por corrida. **Sin lote anidado**: si hay varios features, son unidades **hermanas** del pipeline — un padre, un ledger; nunca `/feature all` adentro.

**Proyecto virgen ⇒ modo POC**: si `DESIGN.md` es solo la semilla del instalador (o no hay plan real), el pedido es la visión entera — el design-delta será un `DESIGN.md` **mínimo marcado borrador**, el plan nace con feature 01 = **esqueleto que camina**, y el resultado visible es el POC. El ping-pong largo de `/design` se **comprime en este gate**.

**El ledger nace ANTES de presentar el gate.** El gate de lote puede re-derivar sus resúmenes de `IMPLEMENTATION.md`; la ruta de un pipeline sale del **pedido del humano**, que vivía en el chat y no está en ningún doc — si la espera cruza sesiones, no hay de dónde re-derivarla. Por eso:

1. Anotá `gate_base` = SHA de HEAD **ahora, antes del commit siguiente**. Creá el ledger (esqueleto abajo) con el pedido literal, la ruta propuesta con el resumen de cada unidad, el modo, el resultado visible declarado y `gate_base`. STATUS → «**esperando autorización de pipeline**» (frase literal: es el disparador de la re-presentación) apuntando al ledger. Commit.
2. Presentá el gate —ruta, resumen por unidad, qué va a haber **visible** al final— y pedí **una autorización global**. Ajustes puntuales bienvenidos. Respuesta directa ⇒ sin push. **Terminá el turno.**
3. **Con la autorización**: registrala en el bloque Gate (fecha, literal breve, ajustes de alcance) + STATUS → pipeline en curso + commit. `scripts/awake.sh start`.
4. **Si el humano descarta**: registrá el descarte en `## Cierre`, STATUS vuelve a estable, sin puntero colgado. Si corrige el pedido, re-presentá el gate sobre el mismo ledger.

**Modelos por unidad**: lanzá cada hijo con el modelo por defecto de la sesión. El esquema de modelo por fase es elección del humano, no regla de la maquinaria: si quiere otro para un tipo de unidad, lo dice en el gate, queda como ajuste de alcance en el ledger y lo aplicás al spawnear.

## Si STATUS dice «esperando autorización de pipeline»

El gate quedó presentado sin autorización registrada: no avances trabajo nuevo. **Re-presentá la ruta registrada en el ledger** — no la re-derives: el pedido era chat y no es reconstruible — y esperá. Respuesta directa ⇒ sin push. Con la autorización, seguí desde el paso 3 de arriba; no pidas una segunda.

## 3. Loop del padre, unidad por unidad

Sos supervisor, no trabajador: **no transportás feedback** y te mantenés liviano para poder conversar a mitad de corrida.

- **Pre-arranque**: re-derivá el resumen de la unidad de los docs actuales y comparalo en sustancia con el autorizado en el ledger — divergencia ⇒ corte (condición 3); fuentes insuficientes ⇒ corte (condición 4). Renová la ventana: `scripts/awake.sh start` **en cada unidad**.
- **Acuñá el token de spawn** (la procedencia del hijo — el texto del prompt no otorga el rol): nonce (`uuidgen`; fallback `$(date +%s)-$$-$RANDOM`) y escritura **atómica** de `.claude/state/pipeline-child-token` (tmp + `mv -f`; contenido: `unit=<id>`, `token=<nonce>`, `spawned_at=<ts>`). Si no puede escribirse, **no lances**: es corte.
- Registrá el arranque en el ledger (estado «en curso» + evento **con `token=<nonce>`**) + STATUS + commit. **El orden importa**: acuñar → ledger+commit → spawn. Como el spawn ocurre después del commit, un ledger sin evento de arranque prueba que no hubo hijo.
- **Lanzá el hijo**: subagente fresco en background, prompt mínimo sin contexto del chat: «Modo hijo del pipeline: unidad \<id\> (tipo \<tipo\>), token \<nonce\>. Ledger: docs/implementation/pipeline-\<fecha\>.md. Leé docs/STATUS.md, AGENTS.md, docs/DESIGN.md, docs/IMPLEMENTATION.md y el ledger, y seguí la sección "Modo hijo de pipeline" de la skill \<design|plan|feature\>.»
- **Supervisión**: cuando el hijo termine un turno con `REVIEW LANZADA id=X head=H`, lanzá un watcher en Bash background que polee `.claude/state/review-terminal` (cada ~15 s, **timeout 45 min**) esperando la **identidad completa**: `id` = X exacto y, si el terminal trae `review_head` ≠ `-`, también H. Un terminal que no matchea es residuo de otra invocación: **ignoralo y seguí esperando** — solo el timeout corta (condición 1). Match ⇒ **empujón sin contenido**: «review terminada (id=X) — el desenlace está en `.claude/state/review-terminal`; seguí según el contrato». Ejemplo de watcher (adaptá ID/HEAD):

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
- `UNIDAD <id> APROBADA` ⇒ verificá el estado (doc de la unidad al día **con la autorización registrada** —fecha, el pedido de `/build` que la originó y el path de este ledger—, «APPROVED — pendiente OK de pipeline», STATUS, commits presentes, `pipeline-expected` y el `pipeline-child-token.claimed-*` borrados) ⇒ ledger (estado, SHAs frontera, evento con ronda final) + commit ⇒ unidad siguiente.
- **Condiciones de corte — las cuatro**: (1) las del loop — deadlock de 5 rondas, exit 2 persistente, veredicto inválido repetido — **más** la ausencia de señal terminal dentro del timeout; (2) cambio de scope o sorpresa que excede la unidad; (3) **divergencia** contra el resumen autorizado; (4) fuentes insuficientes. En todos: **verificá el árbol antes de commitear** — si el hijo dejó cambios sin commitear (violación del handshake), no los absorbas: registrá el corte en el ledger y commiteá **restringido por pathspec**, `git commit --only -m "…" -- docs/implementation/pipeline-<fecha>.md` (el `-m` va **antes** del `--`), que preserva intacta la suciedad del hijo, y reportala en el RECAP. Luego: RECAP con el estado encontrado (posturas de ambos agentes si hubo desacuerdo) + **push de una línea** + fin de turno. Las unidades ya aprobadas quedan intactas.
- **Mensajes del humano a mitad de pipeline**: prioridad absoluta. Respondé; si afecta a la unidad en curso, bajalo **de inmediato** por mensaje al hijo (lo despierta aunque esté esperando una review; lo atiende antes de seguir); si invalida la unidad o la corrida ⇒ corte.

## 4. Fin del pipeline y OK

Ledger con todos los estados finales + STATUS «esperando OK» + commit → **RECAP consolidado** (skill `recap`: base `gate_base`, estructura por unidad, no-revisados listados; en modo POC, los dos caminos post-OK) → push de una línea → **fin de turno**.

**Con el OK**: ese mismo commit es el cierre consolidado (excepción del commit de registro del OK, contrato) — unidades a «Cerrada» en el ledger, features del pipeline a «Cerrado» en `IMPLEMENTATION.md`, cierre del ledger, STATUS al paso siguiente. Solo esa transcripción. Después, facilitá la sesión limpia siguiente igual que `/feature` (chip de spawn con prompt mínimo, o instrucción única).

## Reentrada del pipeline

STATUS apunta a un ledger de pipeline en curso y no hay padre vivo. Es **la misma máquina** de la §«Reentrada del lote» de la skill `feature` — no la repitas: leela allá y aplicá estas **cuatro sustituciones**.

| En el lote | En el pipeline |
|---|---|
| ledger `docs/implementation/batch-*.md`, `tipo: lote` | ledger `docs/implementation/pipeline-*.md`, `tipo: pipeline` |
| anclas `.claude/state/batch-child-token{,.claimed-T,.retired-T}` y `batch-expected` | `.claude/state/pipeline-child-token{,.claimed-T,.retired-T}` y `pipeline-expected` |
| identidad `feature=NN`; cierre `FEATURE NN APROBADO` | identidad `unit=<id>`; cierre `UNIDAD <id> APROBADA` |
| doc de la unidad = `docs/implementation/NN-*.md` (con su Review log) + fila de `IMPLEMENTATION.md` | **según el tipo**: `design` ⇒ `docs/DESIGN.md` (+ `docs/design/*`), con la memoria del ciclo en **las líneas de commit que nombran la ronda** (no hay Review log); `plan` ⇒ `docs/IMPLEMENTATION.md`, ídem; `feature` ⇒ como en el lote |

«Estado local **del feature** en curso» (`codex-session-id`, `round`) se lee como «de la **unidad** en curso». Todo lo demás es literal: corte **absorbente** primero, máquina de `*-expected`, tabla de ocho filas del token con el invariante de ancla única y el retiro determinístico, **orden durable completo** en todo relanzamiento, y nunca re-pedir el gate autorizado ni re-cerrar lo aprobado.

**Las dos máquinas se aplican en conjunción**: `phase=consumed` establece que no hay review en vuelo ni desenlace pendiente — **no** autoriza a relanzar. Quien fija la acción es la fila del token: con `claimed-<T>` + evento `T` hay que **retirar** antes de re-acuñar; con un ancla **pendiente sin evento** (caída entre acuñar y commitear, sin spawn) se **descarta la huérfana** y se repite el orden durable, sin retiro. Verificá además que el `pipeline-expected` legible sea el de **tu unidad**, no un residuo de otra.

Y las ramas propias: STATUS «esperando autorización de pipeline» ⇒ re-presentar la ruta registrada (arriba); STATUS «esperando OK» ⇒ re-presentar el RECAP consolidado pendiente; ledger `tipo: lote` ⇒ **no es tuyo**, entregá a `/feature`; ledger sin `tipo:` o con valor desconocido ⇒ **corte**, con la instrucción de recuperación (un humano anota el `tipo:` correcto y se relanza); cualquier otra inconsistencia ⇒ RECAP sin adivinar.

## Esqueleto del ledger (`docs/implementation/pipeline-YYYY-MM-DD.md`; colisión ⇒ sufijo `-2`, `-3`…)

```markdown
# Pipeline YYYY-MM-DD — `/build`

## Gate
- tipo: `pipeline`
- protocolo: `spawn-token v1`
- Pedido del humano: «<literal>»
- Modo: `normal` | `POC`
- Autorizado: <fecha> — «<literal breve>» · Ajustes de alcance: <literales, o «ninguno»>
- Resultado visible al final: <qué va a poder ver el humano>
- gate_base: <SHA de HEAD previo al commit que crea este ledger>

## Ruta autorizada
### <id> — <tipo> — <nombre>
<resumen del delta tal como se presentó>

## Estado
| Unidad | Tipo | Estado | SHA inicio | SHA APPROVED |
|---|---|---|---|---|
(pendiente → en curso → APPROVED — pendiente OK de pipeline → cerrada)

## Eventos
- <ts> — <arranque de hijo (con `token=<nonce>`) / APPROVED rN / corte con motivo / …>

## Cierre
- <OK humano (fecha, literal) o corte final>
```

## Reglas del loop

- `scripts/awake.sh start` al entrar y al arrancar **cada** unidad; dejala corriendo durante la espera de OK.
- Todo commit toca algún doc. `main` lineal, sin amend.
- El **token de ronda** en STATUS lo declara el hijo en su loop; el padre no lo mueve — sus commits (arranque, cierre de unidad, ledger) no lanzan review y dejan la línea como esté.
- Todo RECAP sigue la skill `recap` (estructura y aviso). Mensajes del humano: prioridad absoluta.
