# 03 — Hardening del loop de review

## Alcance

Consolidar el código safety-critical de uso diario del loop (criterio 3 del plan: `review.sh` y `awake.sh` ejecutan `reset --hard`, `clean -fdx` y señales de procesos en cada ciclo). Cinco entregables, de IMPLEMENTATION §03:

1. **Suite de regresión reproducible** (`tests/loop.sh`): las siete clases de falla que el ciclo 00 encontró a mano y quedaron sin prueba automatizada, ejecutable **sin invocar a Codex** (doble del binario vía PATH) y sin tocar jamás el repo axel real.
2. **Captura robusta del session id**: anclada al evento `thread.started` del JSONL de Codex, en vez del primer UUID que aparezca en un archivo que mezcla stderr.
3. **Reintento automático ante fallas transitorias de Codex**: una vez, solo fallas de proceso, dentro de la misma ronda.
4. **Métricas de rondas**: registro local por corrida + resumen en `review.sh status`.
5. **shellcheck** instalado y corriendo como puerta (`tests/lint.sh`) sobre `scripts/` y `tests/` (el reviewer lo buscó en las 4 rondas del ciclo 00 sin encontrarlo).

Fuera de alcance: cambios al contrato de review más allá de documentar el retry (la semántica de veredicto, base y deadlock no se toca — la suite la **congela**); hardening del instalador (cubierto por su propia suite en 01/02); portabilidad de la suite fuera de macOS (mismo supuesto que `tests/install.sh`); pinning/verificación del binario codex.

## Enfoque técnico

### Orden: primero la red, después los cambios

- **Paso A** — `tests/loop.sh` congela el comportamiento **actual** de `review.sh` y `awake.sh` (las 7 clases). Recién con la suite en verde se toca código.
- **Paso B** — mejoras a `review.sh` (session id, retry, métricas), cada una con sus casos nuevos en la suite y los docs al día.
- **Paso C** — shellcheck: instalación, `tests/lint.sh` como puerta, y corrección/triage de hallazgos en `scripts/` y `tests/`.

La aceptación real contra Codex no necesita corrida aparte: **las rondas de review de este mismo ciclo corren con el `review.sh` modificado** — cada ronda del loop es el smoke real.

### La suite: `tests/loop.sh`

Mismo arnés y patrón que `tests/install.sh`: helpers `t/ok/ko/assert_*`, fixtures en `mktemp -d` con `trap` de limpieza, repos git temporales. `review.sh` resuelve el repo por `git rev-parse --show-toplevel` desde el cwd: la suite lo invoca **siempre con cwd dentro del fixture**, así todo su estado (`.claude/state/`) y sus operaciones destructivas (worktree, reset, clean) quedan confinados al fixture. El repo axel real nunca participa.

**Dobles por PATH** (un directorio de stubs antepuesto a `PATH`):

- `codex` — el doble central. Guion por variables de entorno: `FAKE_CODEX_MSG` (contenido a escribir en el archivo del flag `-o`), `FAKE_CODEX_RC` (exit code), `FAKE_CODEX_EVENTS` (JSONL a emitir por stdout; default: fixture tomado de una corrida real, con `thread.started`/`thread_id` y la línea de stderr `ERROR` que el archivo real mezcla), `FAKE_CODEX_HOOK` (script a ejecutar "durante la review" — simula commits en el canónico y observa el worktree desde adentro), y registro de cada invocación (argv + stdin) en un log para los asserts (resume con el SID correcto, modelo/esfuerzo, contenido del prompt, **no**-invocación en deadlock).
- `caffeinate` — passthrough que saltea sus flags y ejecuta el comando restante (o duerme, si no hay comando): la suite no crea assertions de sueño reales y no depende del entorno.
- `pmset` — emite lo que diga el test (archivo/env) o simula ausencia (sin salida, rc≠0), para manejar el tri-estado de `awake.sh` de forma determinista.

**Matriz por clase** (numeración de IMPLEMENTATION §03; cada caso referencia la ronda del ciclo 00 que lo encontró):

1. **Parser de veredicto + gate de RC** (r1.1): última línea `VERDICT: APPROVED` → exit 0; `VERDICT: CHANGES_REQUESTED` → exit 1; tolerancia de espacios/CRLF/líneas vacías finales; veredicto en el medio con otra última línea → exit 2; sin veredicto, con sufijo (`APPROVED.`), minúsculas → exit 2 (comparación literal); mensaje vacío o ausente → exit 2; **RC≠0 de codex con mensaje válido ya escrito → exit 2 sin tomar veredicto**.
2. **Consistencia del estado** (r2.2): APPROVED escribe base=`REVIEW_HEAD`, racha=0 y `last-verdict`; CHANGES_REQUESTED incrementa racha sin mover base; toda corrida exit 2 deja base, racha, `last-verdict` y session id **intactos** (huella del estado antes/después); `status` muestra solo el último resultado validado (tras una corrida rechazada con "APPROVED" en el cuerpo del mensaje, `status` no cambia); `new` resetea ronda=1 y racha, borra y recaptura el session id; `round` incrementa ronda y resume con el SID guardado (assert sobre el argv del doble); sin session file → `resume --last`.
3. **Deadlock** (r1.3, r2.3): racha 4 → aviso; racha 5 → `round` sale 2 con `DEADLOCK` en stderr **sin invocar a codex** (el log del doble queda vacío); `reset-deadlock` rearma; `new` no hereda la racha.
4. **`wt_valid` contra impostores** (r3.1) — las tres invariantes, cada una con su caso determinista: (a) **subdirectorio común** del repo en `WT_DIR` (pasa `rev-parse` heredando el repo padre; falla `toplevel == WT_DIR`); (b) **repo git independiente** anidado en `WT_DIR` (toplevel coincide; falla git-dir bajo `.git/worktrees/` del repo); (c) **worktree movido** (`mv` de un worktree válido del fixture a `WT_DIR`: toplevel y git-dir pasan; `worktree list` registra el path viejo — falla la tercera). En los tres: el canónico del fixture con un tracked modificado sin commit + un untracked de centinela **sobrevive intacto** (ni `reset --hard` ni `clean -fdx` lo tocan), el impostor se reemplaza y la review corre. Más: `WT_DIR` borrado se recrea; `WT_DIR` válido se reusa (el residuo desaparece, el worktree es el mismo).
5. **Tri-estado y `kill_confirmed` de awake.sh** (r1.6, r2.4, r3.2): `status` en los tres estados (viva por pmset; muerta confirmada → limpia pidfile huérfano; **indeterminado** — pmset ausente + pid vivo que no es caffeinate — no toca nada); `stop` viva → muerte confirmada y pidfile borrado; `stop` indeterminado → exit 2 con pidfile y proceso intactos; `stop` con proceso que ignora TERM → exit 2 conservando el pidfile (la señal no surtió efecto); `start` con horas inválidas (texto, 0) → exit 2 **antes** de tocar la assertion vigente; `start` sobre viva → mata confirmando y arranca nueva; `start` indeterminado → exit 2 sin arrancar ni pisar el pidfile. El caso "fallback sin pmset con caffeinate vivo" usa una copia de `sleep` renombrada `caffeinate` para que el `comm` real coincida.
6. **Movimiento de base a `REVIEW_HEAD`** (r1.2): el hook del doble commitea en el canónico durante la "review" y el mensaje aprueba → la base queda en el `REVIEW_HEAD` del pedido (no el HEAD nuevo), sale el aviso de commits posteriores no aprobados, y el próximo `round` los incluye en su rango (assert sobre el prompt).
7. **Congelamiento de la observación** (r2.1): con el mismo hook, mientras el canónico avanza, el worktree sigue clavado al `REVIEW_HEAD` del pedido (el hook registra desde adentro `rev-parse HEAD` del worktree y el contenido viejo del archivo cambiado); regresión de residuo: lo que una ronda deja en el worktree (untracked + tracked modificado) no existe al arrancar la siguiente.

### Captura robusta del session id (paso B)

Hoy: primer UUID del archivo de eventos — que mezcla stderr de codex (`2>&1`): una línea de error con un UUID anterior al evento real capturaría un id falso. Cambio: extraer `thread_id` **del evento `thread.started`** (formato verificado contra una corrida real de este repo). Sin `thread.started` → aviso y fallback `resume --last`, como hoy; el grep laxo de "cualquier UUID" desaparece (era exactamente la fragilidad). Regresión en la suite: eventos con UUID espurio en una línea de error previa al `thread.started` → se captura el `thread_id` correcto (el comportamiento actual fallaría este caso).

### Retry transitorio (paso B)

`review.sh` reintenta **una vez, dentro de la misma ronda**, solo ante **falla de proceso**: RC≠0 de codex, o mensaje final ausente/vacío con RC 0. Un mensaje bien entregado con veredicto inválido **no** se reintenta (no es transitorio: es incumplimiento de contrato → exit 2 directo). Antes de reintentar, los eventos del intento fallido se preservan (`last-review-events.failed.jsonl`) y se anota el reintento en stderr. `AXEL_REVIEW_RETRIES` (default 1, `0` desactiva — lo usan los tests). El contador de ronda no se duplica (se escribió antes de invocar). Docs al día: el contrato pasa de "el generador reintenta una vez" a "review.sh reintenta una vez las fallas de proceso; si el exit 2 persiste, el generador diagnostica con los eventos y corta a RECAP" — se ajustan `review-contract.md` y las skills que instruían el reintento manual.

Efecto lateral aceptado: si el primer intento murió a mitad de sesión, el resume del retry le repite el prompt al reviewer — el mismo efecto que ya tiene el reintento manual documentado hoy.

### Métricas de rondas (paso B)

`.claude/state/rounds-log` (no versionado): una línea por intento — fecha, modo, ronda, resultado (`APPROVED`/`CHANGES_REQUESTED`/`NO_VERDICT`/`ERROR`/`DEADLOCK`), SHA corto, racha. `review.sh status` agrega el resumen del ciclo actual (desde el último `new`: rondas, distribución) y las últimas líneas del log. Es **observabilidad local**: la memoria oficial por feature sigue siendo el Review log de los docs; se documenta en el contrato como estado local, junto a los demás archivos de `.claude/state/`.

### shellcheck (paso C)

- Instalación por brew, con evidencia (versión) en este doc.
- `tests/lint.sh`: puerta que corre `shellcheck --severity=warning` sobre `scripts/*.sh` y `tests/*.sh`. **Fail-closed**: shellcheck ausente → exit ≠ 0 con la instrucción de instalación (una puerta que se salta en silencio no es puerta).
- Hallazgos: los de severidad error/warning se corrigen (o se silencian con `# shellcheck disable=SCnnnn` + comentario justificando, caso por caso); los info/style se triagean — se aplican los que son señal real y el resto queda inventariado en este doc con el criterio. Gate en `warning`: el volumen de style sobre `install.sh` (40 KB con heredocs) es ruido que no justifica arriesgar refactors sobre contrato aprobado en 01/02.

## Criterios de cierre

1. **Suite del loop en verde y aislada**: `tests/loop.sh` cubre las 7 clases con la matriz de arriba, corre sin Codex real (doble por PATH, con su log de invocaciones asertado), jamás toca el repo axel real, y pasa **3 corridas consecutivas completas**.
2. **Las 3 invariantes de `wt_valid` ejercitadas** cada una por su caso (subdir impostor, repo anidado, worktree movido), con el canónico del fixture demostrado intacto por centinelas en los tres.
3. **Session id por `thread.started`**: capturado del evento (no "primer UUID"), con la regresión del UUID espurio en verde y el fallback `resume --last` intacto.
4. **Retry transitorio**: un reintento automático solo ante falla de proceso, misma ronda, eventos del intento fallido preservados; veredicto inválido no se reintenta; contrato y skills actualizados sin contradicciones.
5. **Métricas**: `rounds-log` registra cada intento con su resultado y `status` resume el ciclo actual; documentado como estado local no versionado.
6. **Lint como puerta**: shellcheck instalado (evidencia), `tests/lint.sh` en verde sobre `scripts/` y `tests/`, hallazgos corregidos o justificados uno a uno.
7. **Aceptación real**: las rondas de review de este ciclo corridas con el `review.sh` modificado (registradas en el Review log); DESIGN/IMPLEMENTATION/STATUS y el contrato al día.

## Decisiones

- 2026-07-27 (bajada): **suite separada** (`tests/loop.sh`) en vez de anexar a `tests/install.sh` — objeto distinto (loop vs instalador), dobles propios. **Orden A→B→C**: la red de regresión congela el comportamiento actual antes de tocar `review.sh`. **Retry solo de fallas de proceso** (RC≠0 / mensaje ausente), nunca de veredictos inválidos: transitorio ≠ incumplimiento. **Session id anclado a `thread.started`** con fallback `resume --last`, eliminando el grep laxo de UUID. **Métricas como estado local** no versionado (la memoria oficial es el Review log). **Gate de lint en `--severity=warning`** con triage documentado de info/style. **Invariante c de `wt_valid` testeada vía worktree movido** (toplevel y git-dir pasan; el registro delata el path viejo).

## Riesgos

- **El doble de codex diverge del real** → eventos de fixture tomados de una corrida real de este repo (formato `thread.started` verificado hoy), y la aceptación real es el propio loop del ciclo corriendo con el script modificado.
- **Semántica de procesos macOS en los tests de awake** (comm de `ps`, señales, timing) → dobles de `pmset`/`caffeinate`, procesos efímeros propios de la suite, y la copia renombrada de `sleep` para el caso de comm real; si un caso no se puede hacer determinista, se documenta el hueco antes que aceptar un flake (lección de T15t6 en el 02).
- **Tests que ejecutan `reset --hard`/`clean -fdx`** → confinados a fixtures `mktemp` con el patrón ya probado de la suite del instalador, y con centinelas que demuestran que el canónico del fixture no sufre efectos; cwd siempre dentro del fixture.
- **El retry repite el prompt en la sesión del reviewer** si el intento murió a mitad → aceptado, único, mismo efecto que el reintento manual actual.
- **shellcheck sobre `install.sh` pide cambios masivos** → gate en warning y triage: nada de refactors grandes sobre el contrato aprobado del 01/02; el residuo queda inventariado.

## Review log

(pendiente — arranca con la review de esta bajada)
