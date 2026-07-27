# 02 — Instalación remota: one-liner desde GitHub

## Alcance

Instalar axel en un destino **sin clon local previo** (pedido humano 2026-07-27, al dar el OK del 01): un solo comando que baja axel desde GitHub y corre la instalación de una. Tres entregables:

- **Modo bootstrap del instalador**: `scripts/install.sh --from <url> <target-dir>` clona (o actualiza) un **cache local de axel** en `AXEL_HOME` (default `~/.axel`) y **delega** la instalación en el `install.sh` de ese clon. Toda la lógica de instalación (payload, semillas, preflight, settings) es la del feature 01 sin cambio de contrato: el modo local `install.sh <target-dir>` se comporta exactamente igual que hoy.
- **Camino piped**: `curl -fsSL <raw>/scripts/install.sh | bash -s -- --from <url> <target-dir>` funciona — el script corre sin `$0` en disco, desde cualquier cwd (incluso adentro de otro repo git), hace el clone/update del cache y ejecuta el instalador clonado.
- **README para agentes**: sección pensada para que un agente de Claude Code la lea y la siga ante "instalá axel siguiendo <url>": precondiciones, el comando, qué hacer según exit code, y el camino desde adentro de una sesión (las skills se cargan en caliente; el settings rige pleno recién en la sesión siguiente). Incluye ajuste menor de `templates/AGENTS.md`: la nota de actualización de la maquinaria menciona también el camino `--from` para destinos sin clon de axel.

Fuera de alcance (v1): verificación de integridad/firma de lo bajado (se confía en HTTPS + GitHub); pinning de versión (`--ref` o similar — siempre el branch default del remoto); soporte Windows; merge de settings (sigue siendo de `/adopt`); shellcheck (queda en el feature 03, hardening — la referencia "feature 02" que quedó en el doc del 01 era anterior a la inserción de este feature y se corrigió con esta bajada).

## Enfoque técnico

### Un solo entry point: `install.sh --from`

Se elige extender `install.sh` (como esboza IMPLEMENTATION) en vez de un script bootstrap separado: una sola URL y un solo comando que enseñar, y la delegación garantiza que **el código que instala es siempre el del clon** — versionado, auditable, idéntico al camino local. El costo de tocar el script aprobado del 01 se acota con dos reglas:

- El parseo de argumentos y el branch `--from` viven **antes de toda resolución de `AXEL_ROOT`**: en modo piped no hay `$0` en disco y el `git rev-parse` actual resolvería el repo del cwd (p. ej. el propio destino). Nada del modo bootstrap depende del entorno del script que corre.
- El modo local queda cubierto por la suite existente **sin tocar sus asserts**: mismo contrato, misma salida, mismos exit codes.

Flujo del modo `--from`:

1. **Argumentos**: `--from <url>` exige URL y `<target-dir>`. Una URL que parece opción (empieza con `-`) se **rechaza**, y en todo comando git la URL viaja después de `--` — un valor option-like jamás llega a interpretarse como flag de git. El resto de la validación del destino (toplevel, self-install, árbol limpio) sigue siendo del delegado: nada se duplica.
2. **Disjunción cache↔destino, antes de cualquier clone/pull**: ambos paths se canonicalizan (el destino debe existir como directorio, igual que exige el delegado); iguales o con relación ancestro/descendiente en cualquier dirección ⇒ **rechazo**. Sin esto, un `AXEL_HOME` adentro del destino ensuciaría el árbol que el delegado va a exigir limpio (mutación del destino en un camino que promete no mutarlo), y un destino adentro del cache podría ser modificado por el update.
3. **Lock del cache**: todo el acceso (validación, update y delegación — el delegado lee el payload del cache mientras instala) se serializa con un lock atómico `$AXEL_HOME.lock` (`mkdir` + archivo con pid). Espera acotada (default 60s; override por env para los tests); un lock huérfano —pid muerto— se limpia con aviso; timeout ⇒ rechazo con el pid en el mensaje. Se libera por trap al terminar, con éxito o sin él.
4. **Cache** (`AXEL_HOME`, default `~/.axel`, override por env — lo usan también los tests):
   - No existe → `mkdir -p` del padre + `git clone -- <url> "$AXEL_HOME"`.
   - Existe pero no es un directorio, o no es el toplevel de un repo git → **rechazo**.
   - `origin` no coincide con la URL pedida (normalizando solo `.git` y `/` finales) → **rechazo** mostrando ambas.
   - Árbol sucio → **rechazo** (podría haber trabajo humano; jamás se pisa).
   - HEAD debe estar en el **branch default del remoto** (el `origin/HEAD` del clon): detached u otro branch ⇒ **rechazo**.
   - `git fetch` + **ancestría explícita**: HEAD debe ser ancestro (o igual) de `origin/<default>`; **ahead o divergido ⇒ rechazo**. `pull --ff-only` solo no alcanza: con un commit local ahead devuelve 0 "Already up to date" y se instalaría código no publicado (repro del reviewer, ronda 1). Detrás → `git merge --ff-only origin/<default>`.
5. **Sanity del clon**: `"$AXEL_HOME/scripts/install.sh"` archivo regular, legible y ejecutable → si no, "el remoto no parece axel", rechazo.
6. **Delegación**: se invoca `"$AXEL_HOME/scripts/install.sh" <target-dir>` — sin `--from` (recursión imposible) y **sin `exec`** (el lock debe liberarse al terminar) — y se captura su RC.

**Taxonomía de salida del bootstrap**: toda falla propia, anterior al lanzamiento del delegado (argumentos, disjunción, lock, cache, red, sanity), es **exit 2 sin mutaciones del destino** — el cache sí puede haberse clonado o actualizado: es infraestructura de la máquina, no del destino, y es el punto del comando. Del delegado lanzado correctamente se propagan **solo sus RC contractuales (0/1/2)**; cualquier otro RC (126/127 de lanzamiento fallido, muerte por señal) se **normaliza a 2 con aviso**: en el caso de señal el destino puede haber quedado con el diff parcial de un instalador interrumpido, y el aviso manda a mirar `git status` en el destino (la misma exposición que ya tiene el modo local del 01 ante un kill a mitad de escritura).

### Seguridad del cache: fail-closed, nada destructivo, un solo usuario a la vez

El cache es un clon normal de axel que el bootstrap solo avanza por fast-forward y solo cuando está **exactamente** en el estado esperado: limpio, en el branch default del remoto, sin commits locales (HEAD ancestro de `origin/<default>`). Todo lo demás — sucio, ahead, divergido, detached, otro branch, otro origin, irreconocible — se rechaza con instrucción de resolverlo a mano. Nunca `reset --hard`, nunca clobber. Es la misma postura del instalador del 01 (propiedad demostrable o nada) aplicada al único directorio nuevo que este feature introduce, más el lock que serializa sesiones concurrentes sobre el cache global: dos instalaciones simultáneas no pueden pisarse la fuente mientras una de ellas la lee.

### README: one-liner + guía para agentes

La sección "Llevar axel a otro proyecto" gana el camino remoto como primera opción:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash -s -- --from https://github.com/alexweil/axel <repo-destino>
```

y conserva el modo local (con clon) como está. Subsección nueva **"Para agentes (Claude Code)"**, autocontenida para que una sesión a la que le dicen "instalá axel siguiendo <url>" pueda ejecutar de punta a punta:

- Precondiciones: destino = repo git con árbol limpio; `git`, `curl`, `python3` disponibles.
- El comando, con `<repo-destino>` = toplevel del repo (p. ej. `$(git rev-parse --show-toplevel)`).
- Reacción por exit code: `0` → revisar el diff, commitearlo con el proceso del destino, `/status`; `1` → diff + commit + cerrar la adopción con `/adopt` (handoff en `docs/ADOPTION.md`); `2` → leer el rechazo del reporte y resolver la causa — **nada se escribió en el destino** (el cache `~/.axel` sí pudo crearse o actualizarse).
- Camino en-sesión: instalado desde adentro de una sesión de Claude Code, las skills quedan disponibles en caliente; los permisos del settings sembrado rigen plenos recién en la **sesión siguiente** (hasta entonces puede haber prompts de confirmación). El instalador no commitea: el commit es del proceso del destino.
- Quien prefiera auditar antes de ejecutar: el camino en dos pasos (clonar y correr `scripts/install.sh` del clon) hace exactamente lo mismo.

### Verificación

Tests nuevos en `tests/install.sh` (misma suite y helpers; sección propia). **Sin red**: los "remotos" son repos git locales (`git clone` acepta paths) y `AXEL_HOME` se apunta a un directorio temporal por env en todos los casos. Matriz:

- **Bootstrap fresco**: sin cache → clona → delega → destino con la estructura completa del 01, exit 0; `axel-sha` del marker == HEAD del remoto local (prueba de que instaló el clon, no otra fuente).
- **Re-run con remoto avanzado**: cache existente limpio → ff-update → el update del destino registra el SHA nuevo.
- **Cache fail-closed** (exit 2; destino y cache intactos por huella de contenido): sucio; **ahead** (commit local con árbol limpio — el caso que `pull --ff-only` no ve); divergido; **detached**; **otro branch**; origin distinto; `AXEL_HOME` archivo regular; directorio no-repo.
- **Disjunción cache↔destino** (exit 2; huella del destino antes/después): `AXEL_HOME == target`; `AXEL_HOME` dentro del target; target dentro de `AXEL_HOME`.
- **URL option-like** (p. ej. `--upload-pack=…`) → exit 2 sin invocar git.
- **Remoto malformado**: clon sin `scripts/install.sh` → exit 2 (sanity); `install.sh` presente pero sin bit de ejecución → exit 2.
- **Red rota**: URL de clone inexistente (cache fresco) y fetch que falla sobre cache existente (origin apuntando a un path borrado) → exit 2; destino y cache intactos.
- **Lock**: lock en poder de un pid vivo → espera y timeout (acortado por env) → exit 2 con mensaje; lock huérfano de un pid muerto → se limpia con aviso y la corrida sigue; **smoke concurrente**: dos bootstraps simultáneos a destinos distintos comparten el cache y terminan ambos exit 0 con el mismo `axel-sha` en los dos markers.
- **Passthrough**: destino con contenido propio vía `--from` → exit 1 con handoff (adopción); destino sucio → exit 2 del delegado, atraviesa tal cual.
- **Piped**: script por stdin (`bash -s -- --from …`) con cwd adentro de **otro** repo git → instala igual (no misresuelve la fuente); piped **sin** `--from` → exit 2 con el mensaje que apunta a `--from`.
- **Modo local intacto**: la suite del 01 pasa completa sin modificar sus asserts.

Cierre con **aceptación real contra GitHub**: el **one-liner piped exacto del README** (`curl -fsSL … | bash -s -- --from https://github.com/alexweil/axel …`) sobre un repo de prueba, con `AXEL_HOME` fresco y aislado — es la única evidencia que cubre `curl`, raw.githubusercontent y el camino por stdin reales. Se registran en el Review log: comando, RC, salida, `origin` y branch del cache resultante, y la correspondencia HEAD del cache == `axel-sha` del marker del destino.

## Criterios de cierre

1. **Bootstrap de punta a punta**: `install.sh --from <url> <target>` sin clon previo deja el destino idéntico a una corrida local del 01 (estructura completa, marker con el SHA del remoto), exit 0; re-corrida con el remoto avanzado hace ff-update del cache y actualiza el destino al SHA nuevo.
2. **Piped robusto**: el script por stdin instala igual desde cwd arbitrario (incluso dentro de otro repo git); piped sin `--from` rechaza con mensaje que apunta a `--from`.
3. **Cache fail-closed y disjunto**: no-repo, origin distinto, sucio, **ahead, divergido, detached u otro branch** ⇒ exit 2 sin tocar destino ni cache (verificado por huella de contenido); la disjunción cache↔destino se verifica **antes de cualquier clone/pull** (igualdad y ancestro/descendiente, paths canónicos); solo ff-update de un cache limpio en el branch default; fallo de clone/red ⇒ exit 2 con destino intacto.
4. **Contrato intacto, passthrough y taxonomía de RCs**: el modo local no cambia (suite del 01 verde, asserts existentes sin tocar); del delegado lanzado correctamente atraviesan **solo** sus RC contractuales 0/1/2 (incluido el 1 de adopción con su handoff); toda falla propia del bootstrap y todo RC no contractual (126/127, señales) ⇒ exit 2, este último con aviso.
5. **Concurrencia**: el acceso al cache (validación + update + delegación) está serializado por lock con recuperación de huérfanos documentada; las regresiones de lock (vivo ⇒ timeout, huérfano ⇒ recuperado) y el smoke concurrente pasan.
6. **Docs y evidencia**: matriz nueva en verde en `tests/install.sh`; `bash -n` limpio sobre los scripts tocados; README con el one-liner y la sección para agentes (camino en-sesión y "nada se escribió **en el destino**" incluidos); `templates/AGENTS.md` con la nota de actualización remota; DESIGN/IMPLEMENTATION/STATUS al día; la aceptación real = one-liner piped exacto con cache fresco, registrada en el Review log.

## Decisiones

- 2026-07-27 (bajada): **un solo entry point** (`install.sh --from`) en vez de bootstrap separado — una URL para enseñar y la garantía de que lo que instala es siempre el clon versionado; el riesgo de tocar el script aprobado se acota moviendo args/`--from` antes de toda resolución de fuente y dejando el contrato local cubierto por la suite existente. **Clone completo** (no shallow): repo chico, cero sorpresas en pulls posteriores. **ff-only + rechazo de cache sucio/divergido/ajeno**: nada destructivo sobre un directorio que podría tener trabajo humano. **Sin `--ref`** en v1: branch default del remoto; pinning es hardening futuro si duele. **Los agentes usan el mismo `--from`** que los humanos: un solo flujo con todas las validaciones (nada de `clone || pull` a mano en el README que las esquive).
- 2026-07-27 (ronda 1): **ancestría explícita** en vez de confiar en `pull --ff-only` (no detecta commits locales ahead — repro del reviewer) y estado exacto requerido del cache (branch default, no detached); **disjunción canónica cache↔destino antes de cualquier clone/pull**; **taxonomía de RCs** — solo 0/1/2 del delegado lanzado atraviesan, todo lo propio y los RC no contractuales se normalizan a 2 (con aviso si el delegado murió a mitad); **lock atómico** por `mkdir` con pid, espera acotada y recuperación de huérfanos — y por eso la delegación deja de usar `exec` (el lock se libera por trap al terminar); URL siempre tras `--` y rechazo de URLs option-like; la aceptación real pasa a ser el **one-liner piped exacto** del README con cache fresco aislado.

## Riesgos

- **`curl | bash` ejecuta código sin review previa**: mitigado porque en `--from` el script piped solo parsea args, clona y delega — mínimo auditable; lo que instala es el clon versionado, y el README ofrece el camino en dos pasos para auditar antes de correr.
- **Cache ≠ checkout de desarrollo**: `~/.axel` es un clon más de axel y alguien podría trabajar ahí. Mitigado: fail-closed (sucio/ahead/divergido jamás se pisa, solo ff), y el README lo llama cache y apunta el desarrollo a un clon propio.
- **El one-liner cablea `main` y la URL del repo**: cambio de branch default o de dueño rompe el string del README. Aceptado: es un string en un solo lugar, visible.
- **Deriva piped ↔ clonado**: el script bajado (p. ej. cacheado por el CDN de raw.githubusercontent) puede ser más viejo que el clon que instala. Benigno por diseño: la delegación ejecuta siempre el del clon; el piped solo necesita estabilidad en el parseo de `--from` y el manejo del cache.
- **Delegado interrumpido (señal/kill)**: el destino puede quedar con un diff parcial; el bootstrap sale 2 con aviso de mirar `git status` en el destino. Misma exposición que el modo local del 01; el diff visible de git sigue siendo la red.

## Review log

- **Ronda 1: CHANGES_REQUESTED** (6 puntos, todos aceptados; bookkeeping del cierre del 01 verificado sin observaciones). Resolución:
  1. `pull --ff-only` no detecta un cache con commits locales ahead (repro del reviewer: devuelve 0 "Already up to date" y se instalaría código no publicado) → corregido: validación explícita de branch default, upstream y **ancestría** (HEAD ancestro de `origin/<default>`); ahead, divergido, detached y otro branch rechazan; los cuatro casos en la matriz.
  2. Validar el destino solo en el delegado permitía mutarlo antes del rechazo (`AXEL_HOME` adentro del target, o target == cache) → corregido: **disjunción canónica cache↔destino antes de cualquier clone/pull** (igualdad y ancestro/descendiente); tres topologías en la matriz con huella del destino.
  3. Taxonomía de errores abierta (git devuelve 1/128; un `exec` fallido termina 126/127) → corregido: toda falla propia del bootstrap ⇒ exit 2; del delegado lanzado atraviesan solo 0/1/2 y los RC no contractuales se normalizan a 2 con aviso; sanity exige regular+legible+ejecutable; URL tras `--` y option-like rechazada; remoto malformado, no-ejecutable y red rota sobre cache existente en la matriz.
  4. Cache global sin contrato de concurrencia → corregido: lock atómico (`mkdir` + pid) sobre validación+update+delegación, espera acotada con override por env, recuperación de lock huérfano documentada; regresiones deterministas (lock vivo ⇒ timeout; huérfano ⇒ recuperado) + smoke concurrente; la delegación deja de usar `exec` para poder liberar el lock por trap.
  5. La aceptación con red no cubría `curl`/raw/stdin → corregido: la evidencia de cierre es el **one-liner piped exacto del README** con `AXEL_HOME` fresco y aislado, registrando comando, RC, salida, origin/branch del cache y HEAD == `axel-sha` del marker.
  6. Inconsistencias documentales → corregidas: la guía de agentes dice "nada se escribió **en el destino**"; IMPLEMENTATION §02 ya no presenta el enfoque como "a definir" y el párrafo del orden acordado distingue la numeración original del plan del override humano posterior.
