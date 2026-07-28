# 06 — One-liner corto: defaults del bootstrap remoto

## Confirmación de arranque

- **2026-07-28** — gate de arranque presentado (resumen derivado de [IMPLEMENTATION.md §06](../IMPLEMENTATION.md)); el humano confirmó con **"OK"**, sin correcciones de alcance. Las dos decisiones que el plan dejó explícitamente para la bajada (semántica de fallo del transporte, forma de los defaults) se resuelven acá.

## Alcance

Soportar la versión corta del one-liner de instalación —

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash
```

— revisando el fail-closed del feature 02 (piped sin `--from` ⇒ exit 2) con **dos defaults independientes que declaran lo que hoy se exige**, más el contrato de éxito que hace detectable un fallo de descarga. Entregables:

- **Default de fuente**: sin `--from` y sin clon de axel en disco (modo piped), la fuente es la **URL canónica** `https://github.com/alexweil/axel`, cableada en el script (hoy vive solo en el string del README). Override por env `AXEL_DEFAULT_REMOTE` (lo usan los tests; también sirve a forks).
- **Default de destino**: en el camino de bootstrap, destino ausente ⇒ **toplevel del repo git del cwd** (`git rev-parse --show-toplevel`); cwd fuera de un árbol de trabajo git ⇒ rechazo con diagnóstico.
- **Anuncio previo**: la corrida imprime fuente y destino asumidos —marcando cuáles vinieron por defecto— **antes de tocar nada** (antes del lock, del clone y del delegado).
- **Contrato verificable de éxito**: toda corrida real termina con una línea final inconfundible (`── axel · fin: rc=N · …`), exactamente una por corrida. Es lo que permite distinguir "el instalador corrió y falló" de "el instalador nunca arrancó" cuando `curl` falla en el pipe.
- **Docs**: README (one-liner corto primero, formas explícitas conservadas, chequeo de la línea final, variante que propaga el fallo, verificación previa del cwd y cómo revertir), guía para agentes, `templates/AGENTS.md`, DESIGN e IMPLEMENTATION.

**Fuera de alcance**: cambiar el contrato del modo local (sigue exigiendo `<target-dir>`; su fuente sigue siendo el clon desde el que corre); pinning de versión (`--ref`); confirmación interactiva (imposible en piped: stdin **es** el script); verificación de firma de lo bajado; cualquier cambio a la validación existente (cache fail-closed, disjunción, lock, preflight del delegado, taxonomía 0/1/2) — todo queda intacto.

## Enfoque técnico

### Dónde viven los defaults: el camino de bootstrap, no el modo local

El plan dejó abierto si el default de destino alcanza también al modo local. **Decisión: no.** Los defaults son del camino de bootstrap remoto (el título del feature), por dos razones que además evitan una inconsistencia:

- El default de **fuente** no puede ser uniforme aunque quisiéramos: corriendo `/path/axel/scripts/install.sh <destino>` la fuente correcta es **ese clon**, no la URL canónica. Defaultear a GitHub en modo local instalaría algo distinto de lo que el usuario tiene a la vista — exactamente el efecto que este feature quiere evitar.
- El default de **destino** se justifica porque el canal piped no puede llevar argumentos. Donde pasar el path es ergonómico (tenés `$0` en disco), el error barato de hoy es preferible a un destino ambiental: `install.sh` sin argumentos sigue imprimiendo el uso y saliendo 2, que además conserva la discoverability (no hace falta agregar `--help`).

Resultado — tres caminos, uno solo nuevo:

| Invocación | Fuente | Destino |
|---|---|---|
| `--from <url>` (con o sin `$0` en disco) | la URL dada | argumento, o **toplevel del cwd** si falta |
| sin `--from`, con `$0` en disco (modo local) | el clon del que sale `$0` (como hoy) | argumento **obligatorio** (sin él: uso, exit 2) |
| sin `--from`, sin `$0` en disco (**piped**) | **URL canónica** (o `AXEL_DEFAULT_REMOTE`) | argumento, o **toplevel del cwd** si falta |

La tercera fila es la que hoy sale 2 apuntando a `--from`; el resto no cambia de comportamiento. La detección "hay clon en disco" es la que el 02 ya usa para el modo local (`BASH_SOURCE[0]` existe como archivo) y se adelanta al dispatch: es una prueba de filesystem pura, sin git ni cwd, así que **no viola la regla del 02** de no resolver `AXEL_ROOT` antes del branch `--from`. Si `$0` existe pero su repo no parece axel, se conserva el rechazo actual — no se cae al default remoto: una copia suelta de `install.sh` jamás debe tirar código de la red por su cuenta.

### Parseo de argumentos

Con argumentos opcionales, un flag mal escrito ya no puede caer en la posición del destino. El parseo pasa a un loop explícito: `--from <url>` (una sola vez, con valor), `--` como fin de flags, cualquier otro `-*` ⇒ uso, y **a lo sumo un** posicional (el destino). Duplicados, flags desconocidos, `--from` sin valor y dos posicionales ⇒ uso + exit 2, sin tocar nada. La validación de la URL (no vacía, no option-like, siempre tras `--` en los comandos git) es la del 02 y corre igual venga de `--from`, del env o del default cableado.

### Resolución del destino ambiental

En el camino de bootstrap, si no hubo posicional:

```
TARGET="$(git rev-parse --show-toplevel)"   # del cwd del caller
```

Falla (fuera de un repo, dentro de `.git/`, repo bare) ⇒ **rechazo** explicando que sin destino explícito el instalador se para en el repo del directorio actual, con la invocación completa como salida. El resultado se canonicaliza igual que el argumento explícito y **entra intacto a toda la validación existente**: disjunción con cache y lock, y el preflight del delegado (toplevel real, repo git, árbol limpio, self-install por git-common-dir).

**Guard extra del destino asumido**: cuando el destino vino por defecto, si su `origin` normalizado coincide con la fuente resuelta ⇒ rechazo ("estás parado en un clon de la propia fuente; pasá el destino explícito"). Cierra el filo más agudo que abre el default —correr el one-liner parado adentro de un clon de axel, que el chequeo de self-install del 01 no ve porque compara el git-common-dir del **cache**, no el del origen remoto— y es demostrable (compara remotos, no adivina por contenido). Con destino explícito el guard no corre: ahí el usuario declaró la intención.

### Anuncio antes de actuar

Apenas resueltas fuente y destino —antes de `mkdir`, lock, `ls-remote`, clone o delegado— la corrida imprime:

```
── axel bootstrap · fuente: <url>[ (por defecto[ vía AXEL_DEFAULT_REMOTE])] · destino: <path>[ (por defecto: toplevel del cwd)] ──
```

Las marcas de "(por defecto)" aparecen solo sobre el valor efectivamente asumido, así el anuncio no puede mentir sobre de dónde salió cada cosa. La línea de bootstrap existente (cache, branch y SHA, ya con el cache validado) se conserva tal cual: informa cosas distintas y llega después.

No hay confirmación interactiva: en modo piped **stdin es el script**, así que no hay de dónde leer una respuesta. El anuncio, el árbol limpio exigido, el diff visible y el instalador que no commitea son la red; la guía lo dice explícitamente en vez de simular una confirmación que no existe.

### Semántica de fallo del transporte: se conserva el comando y se agrega contrato de éxito

El one-liner exacto corre sin `pipefail`: si `curl` falla sin producir script, `bash` recibe entrada vacía y retorna **0** (repro del reviewer en el ciclo de plan: `sh -c 'exit 22' | bash` ⇒ RC 0). El instalador no puede cubrirlo desde adentro —nunca arrancó—, así que la única defensa es out-of-band. De las dos opciones que el plan dejó abiertas se elige **conservar el comando** (es el pedido humano) y hacer el éxito **verificable**:

- **Línea final obligatoria**: toda corrida real termina imprimiendo por stdout `── axel · fin: rc=<N> · <motivo> ──`, en **todos** los caminos —0, 1, rechazos 2, delegado interrumpido, uso por argumentos inválidos e incluso una salida inesperada por `set -e`—, vía trap `EXIT` instalado al tope del script, compuesto con los traps existentes (limpieza del lock, `RENDER_TMP`) preservando el RC real.
- **Exactamente una por corrida**: el wrapper exporta un marcador interno al delegado para que este suprima la suya; el wrapper, que es el proceso que el one-liner arranca, siempre imprime la propia con el RC ya normalizado. La combinación con versiones distintas (script piped viejo del CDN + delegado nuevo del clon, o al revés) sigue dando exactamente una línea, porque el que no conoce el marcador imprime y el que lo conoce se calla — nunca ambos silenciados.
- **El chequeo publicado**: si la salida **no** termina con `── axel · fin:`, el instalador no llegó a correr — típicamente la descarga falló y `bash` recibió entrada vacía. Va al README y a la guía para agentes, con la variante para uso scripteado que sí propaga el fallo del transporte:

  ```bash
  bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash'
  ```

La línea final es aditiva: no cambia RCs ni mensajes existentes, así que los asserts de las suites del 01 y del 02 siguen valiendo sin tocarse.

### Docs

- **README**, sección "Llevar axel a otro proyecto": el one-liner corto como primera opción, con la advertencia de verificar dónde estás parado (`git rev-parse --show-toplevel`) **antes** de correrlo y cómo revertir si te equivocaste de repo (el árbol estaba limpio por precondición ⇒ todo lo escrito es el diff: `git status --short`, `git restore .` y borrar lo no trackeado); las formas explícitas (`bash -s -- --from <url> <destino>` y el modo local con clon) conservadas para destino distinto del cwd, forks y auditoría; el chequeo de la línea final y la variante `pipefail`.
- **Guía para agentes**: se agrega el paso de verificación del cwd (o pasar el destino explícito, que es lo recomendado cuando el agente no está seguro), el chequeo de la línea final antes de interpretar el RC, y la nota de fork (un script piped desde un fork **no** puede saber que salió de un fork: sin `--from`, instala el axel canónico; los forks usan `bash -s -- --from <su-url>` o `AXEL_DEFAULT_REMOTE`).
- **`templates/AGENTS.md`**: la nota de actualización de maquinaria gana el one-liner corto corrido desde el toplevel del propio proyecto.
- **DESIGN.md**: fila de decisiones con los defaults y el contrato de línea final. **IMPLEMENTATION.md**: fila del 06 en curso/cerrado y puntero a este doc. **`docs/implementation/02-remote-install.md`**: nota de revisión — su criterio "piped sin `--from` rechaza" queda superado por este feature (el doc cerrado no se reescribe: se le agrega el puntero para que nadie lo lea como vigente).

## Verificación

Tests nuevos en `tests/install.sh` (misma suite y helpers, sección **T16**), **sin red**: `AXEL_DEFAULT_REMOTE` apunta al remoto de fixture local y `AXEL_HOME` a un temporal, igual que la matriz T15. Helper nuevo `assert_final_rc N` (la salida termina con el prefijo de cierre y ese RC, y aparece **una sola vez**).

- **T16a one-liner corto**: piped sin argumentos, cwd = toplevel del destino → exit 0, estructura completa del 01, `axel-sha` == HEAD del remoto, anuncio con las dos marcas "(por defecto)", línea final `rc=0`.
- **T16b subdirectorio**: piped sin argumentos desde un subdirectorio del destino → instala en el **toplevel**, nada en el subdirectorio.
- **T16c cwd fuera de repo git**: piped sin argumentos → exit 2 con diagnóstico, cero mutaciones (huella).
- **T16d destino explícito sin `--from`** (piped): exit 0 con default de URL solo; el anuncio marca la fuente por defecto y el destino no.
- **T16e `--from` sin destino** (con `$0` en disco), cwd adentro del destino → exit 0 con default de destino solo.
- **T16f modo local sin argumentos** (con `$0` en disco) → exit 2 con el uso, cero mutaciones: el contrato local no cambió.
- **T16g guard del destino asumido**: piped sin argumentos parado adentro de un clon del remoto (origin == fuente) → exit 2 con el motivo, destino intacto.
- **T16h cache de otro origin + one-liner corto** (escenario fork): `AXEL_HOME` clonado de otro remoto → exit 2 "apunta a otro origin", sin tocar el cache ni el destino.
- **T16i parser**: `--froom`, `--from` sin valor, `--from` repetido, dos posicionales → exit 2 con el uso y sin mutaciones; `--` como fin de flags acepta el destino siguiente.
- **T16j línea final en todos los caminos**: rc 0 (T16a), rc 1 (adopción vía one-liner corto, con handoff), rc 2 (rechazo del bootstrap y rechazo del delegado por árbol sucio) — prefijo presente, RC correcto y **una sola** ocurrencia, también en modo local.
- **T16k transporte**: descarga fallida simulada (`sh -c 'exit 22' | bash`) → RC 0 y salida **sin** el prefijo final (el chequeo documentado lo detecta); la variante `bash -o pipefail -c '… | bash'` sobre el mismo fallo → RC 22 (la remediación documentada funciona).
- **Matrices previas intactas**: T1–T14 (feature 01) y T15 (feature 02) verdes sin tocar sus asserts, salvo T15s2 —"piped sin `--from` ⇒ rechazo"—, que este feature **supersede** y se reescribe como el camino corto que ahora instala.

Cierre con **aceptación real contra GitHub**: el **one-liner corto exacto del README** (`curl -fsSL … | bash`, sin argumentos ni env salvo `AXEL_HOME` para aislar el cache) parado adentro de un repo de prueba, registrando en el Review log comando, cwd, RC, salida (anuncio de defaults y línea final incluidos), `origin`/branch del cache y la correspondencia HEAD del cache == `axel-sha` del marker del destino. Es la única evidencia que cubre `curl`, raw.githubusercontent, el camino por stdin y el default de URL cableado.

## Criterios de cierre

1. **One-liner corto de punta a punta**: `curl … | bash` sin argumentos, parado en un repo git limpio, instala en el toplevel de ese repo desde la URL canónica y sale 0, con el anuncio de fuente y destino asumidos **antes** de cualquier mutación y `axel-sha` == HEAD del cache.
2. **Defaults independientes**: `--from <url>` sin destino y destino sin `--from` (piped) funcionan por separado; desde un subdirectorio se instala en el toplevel; cwd fuera de un árbol git ⇒ exit 2 sin escribir nada.
3. **Contrato local intacto**: con `$0` en disco y sin `--from`, la fuente sigue siendo el clon (nunca la URL canónica) y el destino sigue siendo obligatorio (sin argumentos ⇒ uso, exit 2); las suites del 01 y del 02 quedan verdes sin tocar asserts, salvo el de T15s2 superado y reescrito.
4. **Validación intacta y parser cerrado**: cache fail-closed, disjunción cache/lock↔destino, lock, preflight del delegado y taxonomía 0/1/2 sin cambios (T15 completa verde); flags desconocidos, `--from` duplicado o sin valor y posicionales de más ⇒ uso + exit 2 sin mutaciones.
5. **Destino ambiental acotado y documentado**: el destino asumido cuyo `origin` es la propia fuente se rechaza; el riesgo residual (repo limpio equivocado) queda documentado en README y guía para agentes con la verificación previa y la reversión, y cubierto en la matriz.
6. **Fallo del transporte resuelto**: el comando exacto se conserva; toda corrida real termina con `── axel · fin: rc=N · …`, **una sola vez**, en todos los caminos; la guía publica el chequeo y la variante `pipefail`, y los tests cubren tanto la ausencia de la línea ante entrada vacía como la variante que sí propaga el fallo.
7. **Docs y evidencia**: matriz T16 en verde, `bash -n` limpio sobre lo tocado, README + guía para agentes + `templates/AGENTS.md` + DESIGN + IMPLEMENTATION + STATUS al día, `02-remote-install.md` anotado como revisado, y la aceptación real con el one-liner corto exacto registrada en el Review log.

## Riesgos

- **Destino ambiental**: corrido desde el repo limpio equivocado, todos los preflights pasan y ese repo se modifica. Mitigado —no eliminado— por el anuncio previo, el guard de "clon de la propia fuente", el árbol limpio exigido, el diff visible y el instalador que no commitea; documentado con la verificación previa y la reversión. Aceptado en el plan (r1 del ciclo de extensión).
- **Falso éxito del transporte**: `curl | bash` sin `pipefail` retorna 0 si la descarga falla. Mitigado con el contrato de línea final y la variante `pipefail` documentada; no se puede cerrar desde adentro del instalador.
- **URL canónica cableada**: cambio de dueño o de host rompe el default silenciosamente (el rechazo vendría del clone). Aceptado: es una constante visible, ahora en el script además del README, y `--from`/`AXEL_DEFAULT_REMOTE` la sobreescriben.
- **`AXEL_DEFAULT_REMOTE` como superficie**: un env hostil cambiaría la fuente del camino corto. Acotado: solo aplica cuando `--from` está ausente, el anuncio imprime la URL efectiva y marca que vino del env, y quien controla el env del caller ya controla `PATH` y `AXEL_HOME`.
- **Fork piped**: un `install.sh` servido desde un fork y ejecutado por stdin no puede saberlo (no hay `$0` ni procedencia); sin `--from` instala el axel canónico. Documentado, con la forma explícita como remedio.
- **Edge de `BASH_SOURCE`**: un cwd que contenga un archivo llamado `bash` puede hacer que el modo piped se lea como local (`$0` = "bash"); el camino termina en el rechazo "no parece un clon de axel" — fail-closed y con salida clara, no en una instalación silenciosa.

## Review log

_(vacío — se completa en el loop de review)_
