# 02 — Instalación remota: one-liner desde GitHub

## Alcance

Instalar axel en un destino **sin clon local previo** (pedido humano 2026-07-27, al dar el OK del 01): un solo comando que baja axel desde GitHub y corre la instalación de una. Tres entregables:

- **Modo bootstrap del instalador**: `scripts/install.sh --from <url> <target-dir>` clona (o actualiza) un **cache local de axel** en `AXEL_HOME` (default `~/.axel`) y **delega** la instalación en el `install.sh` de ese clon. Toda la lógica de instalación (payload, semillas, preflight, settings) es la del feature 01 sin cambio de contrato: el modo local `install.sh <target-dir>` se comporta exactamente igual que hoy.
- **Camino piped**: `curl -fsSL <raw>/scripts/install.sh | bash -s -- --from <url> <target-dir>` funciona — el script corre sin `$0` en disco, desde cualquier cwd (incluso adentro de otro repo git), hace el clone/update del cache y re-ejecuta el instalador clonado.
- **README para agentes**: sección pensada para que un agente de Claude Code la lea y la siga ante "instalá axel siguiendo <url>": precondiciones, el comando, qué hacer según exit code, y el camino desde adentro de una sesión (las skills se cargan en caliente; el settings rige pleno recién en la sesión siguiente). Incluye ajuste menor de `templates/AGENTS.md`: la nota de actualización de la maquinaria menciona también el camino `--from` para destinos sin clon de axel.

Fuera de alcance (v1): verificación de integridad/firma de lo bajado (se confía en HTTPS + GitHub); pinning de versión (`--ref` o similar — siempre el branch default del remoto); soporte Windows; merge de settings (sigue siendo de `/adopt`); shellcheck (queda en el feature 03, hardening — la referencia "feature 02" que quedó en el doc del 01 era anterior a la inserción de este feature y se corrige con esta bajada).

## Enfoque técnico

### Un solo entry point: `install.sh --from`

Se elige extender `install.sh` (como esboza IMPLEMENTATION) en vez de un script bootstrap separado: una sola URL y un solo comando que enseñar, y la delegación garantiza que **el código que instala es siempre el del clon** — versionado, auditable, idéntico al camino local. El costo de tocar el script aprobado del 01 se acota con dos reglas:

- El parseo de argumentos y el branch `--from` viven **antes de toda resolución de `AXEL_ROOT`**: en modo piped no hay `$0` en disco y el `git rev-parse` actual resolvería el repo del cwd (p. ej. el propio destino). Nada del modo bootstrap depende del entorno del script que corre.
- El modo local queda cubierto por la suite existente **sin tocar sus asserts**: mismo contrato, misma salida, mismos exit codes.

Flujo del modo `--from`:

1. **Argumentos**: `--from <url>` exige URL y `<target-dir>`; el target se pasa al delegado tal cual (el delegado valida existencia, toplevel, self-install, árbol limpio — nada se duplica).
2. **Cache** (`AXEL_HOME`, default `~/.axel`, override por env — lo usan también los tests):
   - No existe → `mkdir -p` del padre + `git clone <url> "$AXEL_HOME"`.
   - Existe pero no es un directorio, o no es el toplevel de un repo git → **rechazo**.
   - `origin` no coincide con la URL pedida (normalizando solo `.git` y `/` finales) → **rechazo** mostrando ambas.
   - Árbol sucio → **rechazo** (podría haber trabajo humano; jamás se pisa).
   - Limpio → `git pull --ff-only`; si no es fast-forward (divergió) → **rechazo**.
3. **Sanity del clon**: `"$AXEL_HOME/scripts/install.sh"` existe → si no, "el remoto no parece axel", rechazo.
4. **Delegación**: `exec "$AXEL_HOME/scripts/install.sh" <target-dir>` — sin `--from` (recursión imposible); el exit code del delegado atraviesa tal cual (0/1/2). Como el cache está limpio por construcción, el SHA que el delegado registra en el marker es el HEAD del cache.

Los rechazos propios del bootstrap son exit 2 con la semántica "sin mutaciones **del destino**": el clone/update del cache sí puede haber ocurrido (es infraestructura de la máquina, no del destino — y es el punto del comando). Un fallo de red o de clone deja el destino intacto.

**Modo local endurecido, mismo contrato**: `install.sh <target>` sin `--from` exige ahora correr desde un script en disco dentro de un clon de axel (`BASH_SOURCE` existente y estructura esperada); piped sin `--from` ⇒ rechazo con mensaje que apunta a `--from`. Hoy ese caso caería en errores confusos de "fuente inconsistente" resueltos contra el repo del cwd.

### Seguridad del cache: fail-closed, nada destructivo

El cache es un clon normal de axel que el bootstrap **solo** avanza por fast-forward y **solo** cuando está limpio. Nunca `reset --hard`, nunca clobber: sucio, divergido, con otro origin o irreconocible ⇒ rechazo con instrucción de resolverlo a mano. Es la misma postura del instalador del 01 (propiedad demostrable o nada), aplicada al único directorio nuevo que este feature introduce.

### README: one-liner + guía para agentes

La sección "Llevar axel a otro proyecto" gana el camino remoto como primera opción:

```bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash -s -- --from https://github.com/alexweil/axel <repo-destino>
```

y conserva el modo local (con clon) como está. Subsección nueva **"Para agentes (Claude Code)"**, autocontenida para que una sesión a la que le dicen "instalá axel siguiendo <url>" pueda ejecutar de punta a punta:

- Precondiciones: destino = repo git con árbol limpio; `git`, `curl`, `python3` disponibles.
- El comando, con `<repo-destino>` = toplevel del repo (p. ej. `$(git rev-parse --show-toplevel)`).
- Reacción por exit code: `0` → revisar el diff, commitearlo con el proceso del destino, `/status`; `1` → diff + commit + cerrar la adopción con `/adopt` (handoff en `docs/ADOPTION.md`); `2` → leer el rechazo del reporte y resolver la causa (nada se escribió).
- Camino en-sesión: instalado desde adentro de una sesión de Claude Code, las skills quedan disponibles en caliente; los permisos del settings sembrado rigen plenos recién en la **sesión siguiente** (hasta entonces puede haber prompts de confirmación). El instalador no commitea: el commit es del proceso del destino.
- Quien prefiera auditar antes de ejecutar: el camino en dos pasos (clonar y correr `scripts/install.sh` del clon) hace exactamente lo mismo.

### Verificación

Tests nuevos en `tests/install.sh` (misma suite y helpers; sección propia). **Sin red**: los "remotos" son repos git locales (`git clone` acepta paths) y `AXEL_HOME` se apunta a un directorio temporal por env en todos los casos. Matriz:

- **Bootstrap fresco**: sin cache → clona → delega → destino con la estructura completa del 01, exit 0; `axel-sha` del marker == HEAD del remoto local (prueba de que instaló el clon, no otra fuente).
- **Re-run con remoto avanzado**: cache existente limpio → ff-update → el update del destino registra el SHA nuevo.
- **Cache fail-closed** (exit 2; destino y cache intactos por huella de contenido): sucio; divergido (commit local); origin distinto; `AXEL_HOME` archivo regular; directorio no-repo.
- **Passthrough**: destino con contenido propio vía `--from` → exit 1 con handoff (adopción); destino sucio → exit 2 del delegado, atraviesa.
- **Piped**: script por stdin (`bash -s -- --from …`) con cwd adentro de **otro** repo git → instala igual (no misresuelve la fuente); piped **sin** `--from` → exit 2 con el mensaje que apunta a `--from`.
- **Red rota**: URL de clone inexistente → exit 2, destino intacto.
- **Modo local intacto**: la suite del 01 pasa completa sin modificar sus asserts.

Cierre con **aceptación real contra GitHub**: una corrida `--from https://github.com/alexweil/axel` sobre un repo de prueba, con comando y salida pegados en el Review log (la única evidencia que los tests sin red no pueden dar).

## Criterios de cierre

1. **Bootstrap de punta a punta**: `install.sh --from <url> <target>` sin clon previo deja el destino idéntico a una corrida local del 01 (estructura completa, marker con el SHA del remoto), exit 0; re-corrida con el remoto avanzado hace ff-update del cache y actualiza el destino al SHA nuevo.
2. **Piped robusto**: el script por stdin instala igual desde cwd arbitrario (incluso dentro de otro repo git); piped sin `--from` rechaza con mensaje que apunta a `--from`.
3. **Cache fail-closed**: `AXEL_HOME` no-repo, con origin distinto, sucio o divergido ⇒ exit 2 sin tocar destino ni cache (verificado por huella de contenido); solo ff-update de un cache limpio; fallo de clone/red ⇒ exit 2 con destino intacto.
4. **Contrato intacto y passthrough**: el modo local no cambia (suite del 01 verde, asserts existentes sin tocar); los exit 0/1/2 del instalador delegado atraviesan el bootstrap tal cual, incluido el 1 de adopción con su handoff.
5. **Docs y evidencia**: matriz nueva en verde en `tests/install.sh`; `bash -n` limpio sobre los scripts tocados; README con el one-liner y la sección para agentes (camino en-sesión incluido); `templates/AGENTS.md` con la nota de actualización remota; DESIGN/IMPLEMENTATION/STATUS al día; la aceptación real contra GitHub documentada en el Review log.

## Decisiones

- 2026-07-27 (bajada): **un solo entry point** (`install.sh --from`) en vez de bootstrap separado — una URL para enseñar y la garantía de que lo que instala es siempre el clon versionado; el riesgo de tocar el script aprobado se acota moviendo args/`--from` antes de toda resolución de fuente y dejando el contrato local cubierto por la suite existente. **Clone completo** (no shallow): repo chico, cero sorpresas en pulls posteriores. **ff-only + rechazo de cache sucio/divergido/ajeno**: nada destructivo sobre un directorio que podría tener trabajo humano. **Sin `--ref`** en v1: branch default del remoto; pinning es hardening futuro si duele. **Los agentes usan el mismo `--from`** que los humanos: un solo flujo con todas las validaciones (nada de `clone || pull` a mano en el README que las esquive).

## Riesgos

- **`curl | bash` ejecuta código sin review previa**: mitigado porque en `--from` el script piped solo parsea args, clona y delega — mínimo auditable; lo que instala es el clon versionado, y el README ofrece el camino en dos pasos para auditar antes de correr.
- **Cache ≠ checkout de desarrollo**: `~/.axel` es un clon más de axel y alguien podría trabajar ahí. Mitigado: fail-closed (sucio/divergido jamás se pisa, solo ff), y el README lo llama cache y apunta el desarrollo a un clon propio.
- **El one-liner cablea `main` y la URL del repo**: cambio de branch default o de dueño rompe el string del README. Aceptado: es un string en un solo lugar, visible.
- **Deriva piped ↔ clonado**: el script bajado (p. ej. cacheado por el CDN de raw.githubusercontent) puede ser más viejo que el clon que instala. Benigno por diseño: la delegación re-ejecuta siempre el del clon; el piped solo necesita estabilidad en el parseo de `--from` y el manejo del cache.

## Review log
