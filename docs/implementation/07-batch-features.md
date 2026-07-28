# 07 — Batch de features: `/feature all` y `/feature NN..MM`

## Confirmación de arranque

- **2026-07-28** — gate de arranque presentado (resumen derivado de [IMPLEMENTATION.md §07](../IMPLEMENTATION.md) y del diseño cerrado en [design/batch-features.md](../design/batch-features.md)); el humano confirmó con **"OK"**, sin correcciones de alcance. Las decisiones que el diseño dejó explícitamente para la bajada (lista al final de ese doc) se resuelven acá.

## Alcance

Implementar el modo lote de `/feature` según el diseño cerrado: ejecutar varios features pendientes en una sola corrida, con los checkpoints agrupados en un gate de lote al inicio y un RECAP consolidado al final. `/feature` sin argumento **no cambia de contrato**. Entregables:

- **`scripts/review.sh`**: la **señal terminal** — registro atómico con identidad de invocación que todo camino de salida de `new|round` escribe como último acto. Es el único cambio de código ejecutable del feature.
- **Skill `feature`**: los modos `all` y `NN..MM` — validación del pedido, gate de lote, ledger, contrato padre↔hijo (lanzamiento del subagente, línea de estado, espera de la señal terminal, empujón), condiciones de corte, protocolo de reentrada fail-closed, y el camino del RECAP consolidado.
- **Skill `recap`**: el RECAP consolidado — base narrativa desde la autorización del gate (SHA registrado en el ledger), estructura por feature, no-revisados como siempre.
- **`AGENTS.md` + `templates/AGENTS.md`** (regla de sincronía): redefinición de la regla dura "nunca continuar a otro feature sin OK humano" y mención del modo lote en la línea de proceso de `/feature`.
- **`docs/design/review-contract.md`**: la señal terminal como comportamiento contractual versionado de `review.sh`.
- **`tests/loop.sh`**: clase nueva de regresión (L10) para la señal terminal.
- **Docs al día**: DESIGN (ya refleja el flujo desde el ciclo de diseño; se ajusta solo si la bajada lo desvía) e IMPLEMENTATION.

**Fuera de alcance**: cambios al instalador (`install.sh` no aprende piezas nuevas: el esqueleto del ledger vive en la skill `feature`, que ya viaja con el payload); ejecución de features en paralelo (el lote es secuencial por diseño); cambios al contrato del `/feature` individual; tags de git por feature (decisión abajo); cualquier rediscusión de lo fijado por el diseño.

## Enfoque técnico

### 1. Señal terminal en `review.sh` (forma exacta)

**Archivo**: `.claude/state/review-terminal` — uno solo, sobreescrito por invocación. **Formato**: líneas `clave=valor` (greppeable, sin parser):

```
ts=<ISO-8601 UTC>
id=<AXEL_REVIEW_ID o «-»>
mode=<new|round>
round=<N o «-»>
review_head=<sha o «-»>
result=<APPROVED|CHANGES_REQUESTED|NO_VERDICT|PROC_FAIL|DEADLOCK|INPUT_ERROR|ABORTED>
rc=<exit code real>
```

- **Identidad de invocación**: env opcional `AXEL_REVIEW_ID`, escrita tal cual en `id=`. El protocolo del lote exige **unicidad real por invocación** (r1): el hijo genera `AXEL_REVIEW_ID=<NN>:r<M>:<nonce>` — nonce fresco por lanzamiento (`uuidgen`; fallback `epoch-pid-RANDOM`) — y lo anuncia junto con el HEAD esperado en su línea de estado. `<NN>:r<M>` solo no alcanza: una salida pre-invocación no consume ronda y una reentrada puede repetir la cuenta del hijo. El matching del padre es por **identidad completa**: `id` idéntico al anunciado y, cuando el terminal trae `review_head` ≠ `-` (hubo invocación), también el SHA anunciado; en los rechazos pre-invocación (`round`/`review_head` = `-`) el nonce identifica por sí solo. Fuera del lote la variable no se setea (`id=-`) y nada del flujo actual cambia.
- **Atomicidad**: se escribe a un tmp en el mismo directorio y se publica con `mv -f` (rename atómico en el mismo filesystem): ningún lector ve un terminal a medias.
- **Cobertura total**: `trap … EXIT` instalado al entrar a `new|round` (inmediatamente después del case de modo). Cubre APPROVED, CHANGES_REQUESTED, NO_VERDICT, PROC_FAIL persistente, DEADLOCK, INPUT_ERROR y cualquier salida no clasificada de `set -e` (`result=ABORTED`, el default si ningún camino seteó resultado). Cada camino ya setea su resultado para `rounds-log`; la misma clasificación alimenta la variable que el trap publica. `status`, `reset-deadlock` y el uso inválido **no** escriben terminal: no son invocaciones de review — para el padre, su ausencia dentro del timeout es falla de proceso (condición de corte 1), nunca algo que adivinar.
- **Inocuidad**: el trap no altera veredicto, estado ni exit code — su cuerpo va blindado (`|| true`); si el terminal no puede escribirse, el review sale igual y el padre corta por timeout (fail-closed). Los asserts de RC existentes de la suite verifican que nada cambió para el flujo actual.

### 2. Ledger del lote (forma exacta)

**Nombre**: `docs/implementation/batch-YYYY-MM-DD.md` (fecha de autorización del gate; colisión el mismo día ⇒ sufijo `-2`, `-3`, …). **Esqueleto** (vive como sección en la skill `feature` — no como archivo en `templates/`: el ledger lo redacta el padre por corrida con contenido variable, y la skill ya viaja con el instalador — cero cambios a `install.sh`):

- **Gate**: fecha, comando invocado (`/feature all` o el rango), features autorizados en orden, exclusiones y correcciones de alcance del humano (literales), y **`gate_base`**: el SHA de HEAD **al momento de autorizarse el gate, antes del commit que lo registra** — un commit no puede contener su propio SHA (r1); `gate_base..HEAD` incluye la autorización misma y es la base narrativa del RECAP consolidado.
- **Resúmenes autorizados**: una sección por feature con el texto **tal como se presentó** — el corte por divergencia compara contra esto.
- **Estado por feature**: tabla NN → estado (`pendiente → en curso → APPROVED — pendiente OK de lote → cerrado`) + SHAs frontera (primer commit y commit del APPROVED de cierre) — reemplazan al tag de git (decisión abajo).
- **Eventos**: arranque de cada hijo, APPROVED con ronda final, cortes con motivo y momento.
- **Cierre**: OK humano (fecha y literal) o corte final.

STATUS.md apunta al ledger mientras el lote corre (el ledger es la posición fina; STATUS conserva sus ~10 líneas).

### 3. Contrato padre↔hijo (protocolo exacto)

**Lanzamiento**: el padre lanza cada hijo como subagente del harness con contexto fresco, prompt mínimo — modo hijo + número de feature + path del ledger. El hijo reconstruye todo de los docs (su memoria son los docs; el prompt no transporta contexto del chat). Sesión de Codex fresca vía `review.sh new`, como hoy. Si el harness no ofrece subagentes con reanudación por mensaje, la skill **rechaza el modo lote** con mensaje claro y ofrece el flujo individual (fail-closed, sin degradar a un lote sin fronteras de contexto).

**El hijo** = el `/feature` de hoy con tres deltas:

1. **Gate resuelto por el lote**: no re-pide confirmación; registra en el doc del feature la autorización del gate de lote con referencia al ledger (fecha + comando), en lugar del literal individual.
2. **Reviews**: genera el id único (§1), escribe `.claude/state/batch-expected` (id + head + feature + `phase=launched` — el ancla de la reentrada; ciclo de vida completo abajo), invoca `review.sh` en background con `AXEL_REVIEW_ID=<id>` y **termina el turno** con última línea exacta: `REVIEW LANZADA id=<id> head=<sha del HEAD commiteado>`. Lo despierta el empujón del padre; el desenlace autoritativo es el **terminal** (r1): valida su identidad, **marca `phase=consumed` en el ancla y recién entonces actúa** (r2), leyendo `result`/`rc` — solo ante `APPROVED` o `CHANGES_REQUESTED` consume `last-verdict` y `last-review.md` como vigentes; ante `PROC_FAIL`, `NO_VERDICT`, `DEADLOCK`, `INPUT_ERROR` o `ABORTED` esos archivos quedaron deliberadamente viejos, y el camino es el de fallas del loop vigente (diagnóstico, relanzamiento único si es claramente transitorio, o condición de corte).

   **Ciclo de vida de `batch-expected`** (r2): mismo patrón de escritura que el terminal — tmp + `mv -f`, atómica — y **obligatoria**: si no puede escribirse, la review **no se lanza** (fail-closed). Transiciones: `phase=launched` al lanzar (cada lanzamiento sobreescribe el ancla anterior) → `phase=consumed` cuando el hijo validó el terminal, **antes** de actuar sobre el resultado — así un padre muerto después del empujón nunca produce reprocesamiento: lo peor que queda es un `consumed` sin acciones, y eso se reconstruye por docs (el doc del feature + git dicen si el feedback ya fue atendido). Limpieza: el hijo la borra al cerrar su feature (`FEATURE <NN> APROBADO`); ante corte se **conserva** como evidencia para el RECAP; el lanzamiento siguiente la sobreescribe en cualquier caso.
3. **Cierre**: con el APPROVED de cierre deja «APPROVED — pendiente OK de lote» en IMPLEMENTATION + doc del feature + STATUS, commitea, y termina con última línea `FEATURE <NN> APROBADO`. Sin RECAP individual, sin push, sin chip. Ante condición de corte propia: última línea `CORTE: <motivo breve>` y el detalle en el doc del feature.

**El padre** (liviano por diseño — no transporta feedback):

- Al ver `REVIEW LANZADA id=X head=H`: lanza un **watcher** en Bash background que polea `.claude/state/review-terminal` esperando la **identidad completa** (§1): `id` = X y, si el terminal trae `review_head` ≠ `-`, también H. Un terminal que **no** matchea — típicamente el de la invocación anterior, que el archivo único conserva hasta la publicación nueva (r1) — se **ignora y se sigue esperando**: el watcher vivo jamás corta por «id ajeno» de un residuo; el corte es solo por **timeout** (**45 minutos** — ≈4× la ronda xhigh más larga observada, 11 min) → condición de corte 1, sin adivinar. Match → **empujón sin contenido** al hijo: «review terminada (id=X) — el desenlace está en `.claude/state/review-terminal`; seguí según el contrato».
- **Entre features**: verifica el estado del hijo saliente (IMPLEMENTATION con «APPROVED — pendiente OK de lote», STATUS al día, commits presentes), actualiza el ledger (estado + SHAs frontera + evento), renueva `awake.sh start`, **re-deriva el resumen del feature siguiente** de los docs actuales y lo compara en sustancia con el autorizado — divergencia ⇒ corte 3; fuentes insuficientes ⇒ corte 4. Coincide ⇒ lanza el hijo siguiente.
- **Mensajes del humano a mitad de lote**: prioridad absoluta. El padre responde, y si el mensaje afecta al feature en curso lo **baja de inmediato** por mensaje al hijo (el mensaje lo despierta aunque esté esperando una review; el hijo lo atiende antes de seguir — la regla vigente del loop). Si invalida el feature o el lote ⇒ corte con registro en el ledger. Se elige bajada inmediata sobre «esperar al próximo empujón»: es la misma semántica de prioridad absoluta que ya rige, y el spike demostró que el resume por mensaje despierta al hijo sin pérdida de contexto.
- **Fin del lote**: tras el último hijo, commit del ledger + STATUS «esperando OK» → RECAP consolidado (skill `recap`) → push de una línea → fin de turno.

**Reentrada** (padre muerto, sesión nueva): STATUS apunta al ledger ⇒ la sesión lee STATUS + ledger + git y aplica el protocolo fail-closed del diseño. A diferencia del watcher vivo — que ignora no-matches y espera — la reentrada **valida y decide** (r1), con `.claude/state/batch-expected` como ancla, cubriendo los tres estados del ciclo de vida (r2):

- `phase=launched` + terminal con identidad completa coincidente ⇒ la review terminó y su desenlace **no fue consumido** ⇒ consistente: relanza un hijo fresco que retoma leyendo el terminal.
- `phase=launched` + terminal ausente o de otra identidad ⇒ review posiblemente **en vuelo** ⇒ **inconsistencia**: RECAP con lo encontrado, sin relanzar.
- `phase=consumed` ⇒ no hay review en vuelo ni desenlace pendiente («entre rondas»): consistencia normal por ledger + git + doc del feature, y el hijo relanzado reconstruye de los docs qué parte del feedback ya fue atendida (los commits lo dicen) — jamás reprocesa a ciegas.
- **Ancla ausente**: por sí sola **no prueba** «no había review en vuelo» (r2) — solo cuenta como tal si el resto del estado local del loop del feature en curso está presente y coherente (`codex-session-id`, `round`: el loop corrió en esta máquina y el ancla se habría escrito). En un entorno sin ese estado local (reentrada remota, máquina distinta), mandan STATUS + ledger, y ante cualquier duda el camino es el corte conservador: RECAP, sin relanzar.

`batch-expected` vive en `.claude/state/` (estado local no versionado, como el resto del estado del loop). Nunca se re-pide el gate autorizado ni se re-cierra lo aprobado.

### 4. Validación del pedido (`all` / `NN..MM`)

Contra la tabla de IMPLEMENTATION.md, fail-closed:

- `all` ⇒ todos los features en estado **Pendiente**, en el orden de la tabla. Cero pendientes ⇒ no hay lote: mensaje + ofrecer `/plan`.
- `NN..MM` ⇒ las filas existentes con NN ≤ # ≤ MM. Rechazo con diagnóstico si: un extremo no existe en la tabla, NN > MM, o **algún feature del rango no está Pendiente** (cerrado o en curso — un lote no retoma features a medias ni saltea cerrados intercalados: para eso están dos lotes o `all`). Números sin fila entre los extremos no son error (la tabla manda). Lote de un solo feature: válido (gate y RECAP consolidado triviales, semántica intacta).

### 5. Decisiones cerradas de la lista del diseño

| Decisión abierta | Resolución |
|---|---|
| Forma del registro terminal | `.claude/state/review-terminal`, `clave=valor`, tmp + `mv -f`, trap EXIT — §1 |
| Forma del ledger | `docs/implementation/batch-YYYY-MM-DD.md`, esqueleto en la skill `feature`, `gate_base` = HEAD previo al commit del gate — §2 |
| Empujón / línea de estado | `REVIEW LANZADA id=<NN>:r<M>:<nonce> head=<sha>` / empujón sin contenido con el id; `FEATURE <NN> APROBADO`; `CORTE: <motivo>`; ancla de reentrada en `.claude/state/batch-expected` con ciclo de vida `launched → consumed → borrada al cierre` (atómica y obligatoria: sin ancla no se lanza) — §3 |
| Timeout del padre | 45 min por review (≈4× la ronda xhigh más larga observada) — §3 |
| Tag de git por feature | **No**: los SHAs frontera en el ledger dan la misma identificación sin ensuciar el namespace de tags de los proyectos consumidores; el revert del sufijo opera por SHAs igual |
| Mensaje humano a mitad de feature | Bajada inmediata por mensaje al hijo (no espera al próximo empujón) — §3 |
| Validación del rango | Contra la tabla, todos Pendiente, fail-closed — §4 |

## Criterios de cierre

1. `review.sh` escribe la señal terminal en todo camino de salida de `new|round` — atómica, con identidad — y los caminos existentes conservan exit codes y estado: **L10 en verde y la suite completa en verde** (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`). L10 congela además las carreras de la r1: **sobreescritura por invocación** (el terminal viejo no sobrevive a la publicación nueva, sin tmp residual), el `id` propagado exacto desde el env, y `review_head`/`round` correctos en ambos regímenes (con invocación, y `-` en pre-invocación).
2. Skill `feature` con los dos modos completos: validación, gate de lote, ledger (esqueleto incluido), contrato padre↔hijo, condiciones de corte, reentrada fail-closed, camino del RECAP consolidado.
3. Skill `recap` con el RECAP consolidado (base desde la autorización del gate, estructura por feature, no-revisados listados como siempre).
4. `AGENTS.md` y `templates/AGENTS.md` sincronizados: regla dura redefinida + modo lote referenciado.
5. `review-contract.md` documenta la señal terminal como comportamiento contractual.
6. DESIGN e IMPLEMENTATION al día; `shellcheck` verde sobre los scripts tocados.

## Riesgos

- **La aceptación real es diferida**: tras el 07 el backlog queda vacío — no hay features pendientes con los que correr un lote de verdad dentro de este feature. La mecánica padre↔hijo quedó probada empíricamente en el spike del diseño y la señal terminal entra a la suite; la skill (instrucciones) se valida en la primera corrida real, cuando el plan se extienda. Mismo patrón que el 05 (el gate se validó en el arranque del 06).
- **Dependencia del harness**: el modo lote necesita subagentes reanudables por mensaje. Mitigación: detección y rechazo explícito con fallback al flujo individual (§3).
- **El trap EXIT toca todos los caminos de `review.sh`** — el script más safety-critical del repo. Mitigación: cuerpo blindado (`|| true`), sin escritura de estado de resultado, y los asserts de RC/estado existentes de la suite corren sobre el script modificado (regresión directa).
- **Radio de daño del lote** (aceptado en el diseño): un error de N se propaga hasta el corte o el RECAP; recuperación conservadora sin rollback automático — documentado en el diseño, el ledger da los SHAs para el revert del sufijo.

## Implementación

- **Paso A — señal terminal + L10 + contrato** (2026-07-28): `review.sh` con `write_terminal` en `trap EXIT` instalado al entrar a `new|round` — publicación atómica (tmp + `mv -f`), blindada (`return 0`, jamás toca veredicto/estado/exit code), clasificación por camino vía `TERMINAL_RESULT` (default `ABORTED`) y `round`/`review_head` capturados donde nacen. L10 en `tests/loop.sh`: todo camino publicado (APPROVED, CHANGES_REQUESTED, NO_VERDICT, PROC_FAIL doble, DEADLOCK, INPUT_ERROR), id propagado exacto (incluida pre-invocación), sobreescritura por invocación sin tmp residual, inocuidad de `status`/`reset-deadlock`, uso inválido sin terminal, y `ABORTED` inducido de verdad (base corrupta ⇒ `git log` revienta tras capturar el head). `review-contract.md` con la sección «Señal terminal» (comportamiento contractual + reglas del consumidor). Suites: loop **293 ok · 0 fail**, install **459 ok · 0 fail**, lint limpio.
- **Paso B — skills + reglas** (pendiente): skill `feature` (modos `all`/`NN..MM`, gate de lote, ledger, contrato padre↔hijo, reentrada), skill `recap` (RECAP consolidado), `AGENTS.md` + `templates/AGENTS.md` (regla dura), ajustes DESIGN/IMPLEMENTATION si hacen falta.

## Review log

- **r1** (2026-07-28, `CHANGES_REQUESTED`, rango `0c2ee58..ba8694e`): tres bloqueos, los tres aceptados y corregidos en la bajada — (1) el «SHA del commit de autorización» era autorreferencial (un commit no puede contener su propio SHA) ⇒ `gate_base` = HEAD previo al commit del gate, con `gate_base..HEAD` incluyendo la autorización; (2) identidad insuficiente y carrera con el terminal viejo (el archivo único conserva el de la ronda anterior; `<NN>:r<M>` puede repetirse) ⇒ nonce único por invocación, matching por identidad completa (id + head anunciados), watcher vivo que ignora no-matches y corta solo por timeout, y `.claude/state/batch-expected` como ancla para que la reentrada valide fail-closed — L10 congela la sobreescritura y la identidad; (3) el hijo leía `last-verdict`/`last-review.md` directo, que quedan viejos ante fallas ⇒ el terminal es el desenlace autoritativo: esos archivos solo son vigentes ante `APPROVED`/`CHANGES_REQUESTED`. Higiene: blank line al EOF removida. Codex validó explícitamente: esqueleto del ledger en la skill (sin tocar `install.sh`), timeout de 45 min, sin tags de git, bajada inmediata de mensajes humanos, validación fail-closed del rango, y el registro honesto de la aceptación diferida.
- **r2** (2026-07-28, `CHANGES_REQUESTED`, rango `0c2ee58..c339b09`): las resoluciones de r1 validadas (gate_base realizable, nonce inequívoco, watcher que ignora residuos, matching pre-invocación seguro, terminal autoritativo); un bloqueo nuevo, aceptado — el ciclo de vida de `batch-expected` estaba incompleto: un padre muerto **después** del empujón dejaba el ancla matcheando el terminal y la reentrada reprocesaría el desenlace. Fijado (§3): escritura atómica y obligatoria antes de lanzar (si falla, no se lanza), transición `launched → consumed` marcada por el hijo **antes** de actuar sobre el resultado, borrado al cierre del feature y conservación ante corte; reentrada con los tres estados cubiertos («esperando terminal», «terminal consumido», «entre rondas») y la ausencia del ancla degradada a señal no concluyente — solo cuenta con el resto del estado local presente; sin estado local mandan STATUS/ledger o el corte conservador.
