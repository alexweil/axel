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

- **Identidad de invocación**: env opcional `AXEL_REVIEW_ID`, escrita tal cual en `id=`. En modo lote el hijo invoca `AXEL_REVIEW_ID=<NN>:r<M> scripts/review.sh …` (feature y ronda según su propia cuenta) y anuncia ese id en su línea de estado; el padre solo empuja ante un terminal cuyo `id` coincide **exactamente** con el anunciado. Fuera del lote la variable no se setea (`id=-`) y nada del flujo actual cambia. `round`/`review_head` van además como refuerzo de diagnóstico (`-` en los rechazos pre-invocación, donde aún no existen).
- **Atomicidad**: se escribe a un tmp en el mismo directorio y se publica con `mv -f` (rename atómico en el mismo filesystem): ningún lector ve un terminal a medias.
- **Cobertura total**: `trap … EXIT` instalado al entrar a `new|round` (inmediatamente después del case de modo). Cubre APPROVED, CHANGES_REQUESTED, NO_VERDICT, PROC_FAIL persistente, DEADLOCK, INPUT_ERROR y cualquier salida no clasificada de `set -e` (`result=ABORTED`, el default si ningún camino seteó resultado). Cada camino ya setea su resultado para `rounds-log`; la misma clasificación alimenta la variable que el trap publica. `status`, `reset-deadlock` y el uso inválido **no** escriben terminal: no son invocaciones de review — para el padre, su ausencia dentro del timeout es falla de proceso (condición de corte 1), nunca algo que adivinar.
- **Inocuidad**: el trap no altera veredicto, estado ni exit code — su cuerpo va blindado (`|| true`); si el terminal no puede escribirse, el review sale igual y el padre corta por timeout (fail-closed). Los asserts de RC existentes de la suite verifican que nada cambió para el flujo actual.

### 2. Ledger del lote (forma exacta)

**Nombre**: `docs/implementation/batch-YYYY-MM-DD.md` (fecha de autorización del gate; colisión el mismo día ⇒ sufijo `-2`, `-3`, …). **Esqueleto** (vive como sección en la skill `feature` — no como archivo en `templates/`: el ledger lo redacta el padre por corrida con contenido variable, y la skill ya viaja con el instalador — cero cambios a `install.sh`):

- **Gate**: fecha, comando invocado (`/feature all` o el rango), features autorizados en orden, exclusiones y correcciones de alcance del humano (literales), y el **SHA del commit de autorización** (el que registra el gate en el ledger) — es la base narrativa del RECAP consolidado.
- **Resúmenes autorizados**: una sección por feature con el texto **tal como se presentó** — el corte por divergencia compara contra esto.
- **Estado por feature**: tabla NN → estado (`pendiente → en curso → APPROVED — pendiente OK de lote → cerrado`) + SHAs frontera (primer commit y commit del APPROVED de cierre) — reemplazan al tag de git (decisión abajo).
- **Eventos**: arranque de cada hijo, APPROVED con ronda final, cortes con motivo y momento.
- **Cierre**: OK humano (fecha y literal) o corte final.

STATUS.md apunta al ledger mientras el lote corre (el ledger es la posición fina; STATUS conserva sus ~10 líneas).

### 3. Contrato padre↔hijo (protocolo exacto)

**Lanzamiento**: el padre lanza cada hijo como subagente del harness con contexto fresco, prompt mínimo — modo hijo + número de feature + path del ledger. El hijo reconstruye todo de los docs (su memoria son los docs; el prompt no transporta contexto del chat). Sesión de Codex fresca vía `review.sh new`, como hoy. Si el harness no ofrece subagentes con reanudación por mensaje, la skill **rechaza el modo lote** con mensaje claro y ofrece el flujo individual (fail-closed, sin degradar a un lote sin fronteras de contexto).

**El hijo** = el `/feature` de hoy con tres deltas:

1. **Gate resuelto por el lote**: no re-pide confirmación; registra en el doc del feature la autorización del gate de lote con referencia al ledger (fecha + comando), en lugar del literal individual.
2. **Reviews**: invoca `review.sh` en background con `AXEL_REVIEW_ID=<NN>:r<M>` y **termina el turno** con última línea exacta: `REVIEW LANZADA id=<NN>:r<M>`. Lo despierta el empujón del padre; lee veredicto y feedback de `.claude/state/last-verdict` y `last-review.md`.
3. **Cierre**: con el APPROVED de cierre deja «APPROVED — pendiente OK de lote» en IMPLEMENTATION + doc del feature + STATUS, commitea, y termina con última línea `FEATURE <NN> APROBADO`. Sin RECAP individual, sin push, sin chip. Ante condición de corte propia: última línea `CORTE: <motivo breve>` y el detalle en el doc del feature.

**El padre** (liviano por diseño — no transporta feedback):

- Al ver `REVIEW LANZADA id=X`: lanza un **watcher** en Bash background que espera la aparición de `.claude/state/review-terminal` con `id=X` (poll; **timeout 45 minutos** — ≈4× la ronda xhigh más larga observada, 11 min). Terminal con id coincidente → **empujón sin contenido** al hijo: «review terminada (id=X) — leé `.claude/state/last-verdict` y `last-review.md` y seguí según el contrato». Timeout o id ajeno → condición de corte 1, sin adivinar.
- **Entre features**: verifica el estado del hijo saliente (IMPLEMENTATION con «APPROVED — pendiente OK de lote», STATUS al día, commits presentes), actualiza el ledger (estado + SHAs frontera + evento), renueva `awake.sh start`, **re-deriva el resumen del feature siguiente** de los docs actuales y lo compara en sustancia con el autorizado — divergencia ⇒ corte 3; fuentes insuficientes ⇒ corte 4. Coincide ⇒ lanza el hijo siguiente.
- **Mensajes del humano a mitad de lote**: prioridad absoluta. El padre responde, y si el mensaje afecta al feature en curso lo **baja de inmediato** por mensaje al hijo (el mensaje lo despierta aunque esté esperando una review; el hijo lo atiende antes de seguir — la regla vigente del loop). Si invalida el feature o el lote ⇒ corte con registro en el ledger. Se elige bajada inmediata sobre «esperar al próximo empujón»: es la misma semántica de prioridad absoluta que ya rige, y el spike demostró que el resume por mensaje despierta al hijo sin pérdida de contexto.
- **Fin del lote**: tras el último hijo, commit del ledger + STATUS «esperando OK» → RECAP consolidado (skill `recap`) → push de una línea → fin de turno.

**Reentrada** (padre muerto, sesión nueva): STATUS apunta al ledger ⇒ la sesión lee STATUS + ledger + git y aplica el protocolo fail-closed del diseño — estado consistente ⇒ relanza un hijo fresco para el feature en curso; cualquier inconsistencia (terminal ausente o de otra identidad con review posiblemente corriendo, ledger contradictorio con git/IMPLEMENTATION) ⇒ RECAP con lo encontrado, sin relanzar. Nunca re-pide el gate autorizado ni re-cierra lo aprobado.

### 4. Validación del pedido (`all` / `NN..MM`)

Contra la tabla de IMPLEMENTATION.md, fail-closed:

- `all` ⇒ todos los features en estado **Pendiente**, en el orden de la tabla. Cero pendientes ⇒ no hay lote: mensaje + ofrecer `/plan`.
- `NN..MM` ⇒ las filas existentes con NN ≤ # ≤ MM. Rechazo con diagnóstico si: un extremo no existe en la tabla, NN > MM, o **algún feature del rango no está Pendiente** (cerrado o en curso — un lote no retoma features a medias ni saltea cerrados intercalados: para eso están dos lotes o `all`). Números sin fila entre los extremos no son error (la tabla manda). Lote de un solo feature: válido (gate y RECAP consolidado triviales, semántica intacta).

### 5. Decisiones cerradas de la lista del diseño

| Decisión abierta | Resolución |
|---|---|
| Forma del registro terminal | `.claude/state/review-terminal`, `clave=valor`, tmp + `mv -f`, trap EXIT — §1 |
| Forma del ledger | `docs/implementation/batch-YYYY-MM-DD.md`, esqueleto en la skill `feature` — §2 |
| Empujón / línea de estado | `REVIEW LANZADA id=<NN>:r<M>` / empujón sin contenido con el id; `FEATURE <NN> APROBADO`; `CORTE: <motivo>` — §3 |
| Timeout del padre | 45 min por review (≈4× la ronda xhigh más larga observada) — §3 |
| Tag de git por feature | **No**: los SHAs frontera en el ledger dan la misma identificación sin ensuciar el namespace de tags de los proyectos consumidores; el revert del sufijo opera por SHAs igual |
| Mensaje humano a mitad de feature | Bajada inmediata por mensaje al hijo (no espera al próximo empujón) — §3 |
| Validación del rango | Contra la tabla, todos Pendiente, fail-closed — §4 |

## Criterios de cierre

1. `review.sh` escribe la señal terminal en todo camino de salida de `new|round` — atómica, con identidad — y los caminos existentes conservan exit codes y estado: **L10 en verde y la suite completa en verde** (`tests/loop.sh`, `tests/install.sh`, `tests/lint.sh`).
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

## Review log

