# Feature 13 — Vidriera: `LICENSE` MIT + README en inglés + `docs/install.md`

> Bajada fina. Plan: [../IMPLEMENTATION.md](../IMPLEMENTATION.md) §13. Diseño: [../design/public-surface.md](../design/public-surface.md).

## Procedencia y autorización

**Unidad `13` (tipo `feature`) del tercer pipeline `/build` del 2026-07-29** — ledger [pipeline-2026-07-29-3.md](pipeline-2026-07-29-3.md), `gate_base` `39b377e`, SHA de arranque de la unidad `284ace4`.

- **Autorizado**: 2026-07-29, por el gate del pipeline — «dale, autorizado — el push y los topics los hago yo». No hay gate individual: la autorización global del pipeline cubre esta unidad.
- **Pedido que originó el pipeline** (literal breve; el texto completo vive en el bloque Gate del ledger): «Dejar el repo público de axel presentable para compartirlo: README en inglés escrito para quien lo descubre, licencia MIT, y los docs de onboarding y feedback que faltan.»
- **Ajuste de alcance del gate que manda sobre esta unidad** (ajuste (b)): el pipeline **no toca GitHub ni pushea** — ni `git push`, ni topics, ni homepage. Los comandos los deja listos la unidad `14` y los corre el humano. Ejecutarlos desde acá es divergencia ⇒ corte.

## Alcance

**Entra**: `LICENSE` (nuevo, MIT), `README.md` (reescrito de punta a punta, en inglés) y `docs/install.md` (nuevo, en inglés).

**No entra, por alcance del gate**: el método (`AGENTS.md` y su espejo `templates/AGENTS.md`), las skills, el instalador, los scripts, los tests, y **toda** acción sobre GitHub. Tampoco los tres arreglos del instalador —la colisión `build/`, el rechazo por árbol sucio que no lista archivos, el `modo: initial` anunciado en una adopción—: se **documentan** como problemas conocidos y no se arreglan, y por decisión explícita del humano **tampoco reciben entrada de backlog**.

**Deuda normativa que esta unidad hereda y no cierra**: `AGENTS.md` §Convenciones dice «Docs, commits y comunicación en español» sin excepción, y desde el delta de diseño esa línea es falsa. Corregirla es tocar el método ⇒ fuera de la ruta autorizada. Queda declarada en STATUS y en [../design/public-surface.md](../design/public-surface.md) §«Política de idioma», con sus dos únicas vías de cierre. **Esta unidad no la toca**: hacerlo sería ampliar en silencio el scope que el humano fijó.

## Las cuatro preguntas de la bajada, resueltas

### 1. Titular y año del copyright MIT — derivados del repo, no inventados

El diseño manda: «los confirma el humano o se derivan del repo». El humano no está en el loop a mitad de pipeline, así que se **derivan**, con el comando a la vista:

**Los dos comandos van anclados al corte `b0bdf4d`, no a `HEAD`** (corrección de la r1, punto 1): un `git log` sin revisión se mueve con cada commit del propio feature — al escribir esto `HEAD` ya tiene **216** commits contra los **212** del corte, así que la cifra citada y el comando citado dejarían de coincidir apenas se lea el doc.

| Dato | Derivación (anclada al corte) | Valor |
|---|---|---|
| Titular | `git log b0bdf4d --format='%an' \| sort -u` ⇒ **una sola línea**; coincide con el owner de la URL pública `github.com/alexweil/axel` | `alexweil` |
| Año | `git log b0bdf4d --reverse --format='%ad' --date=short \| head -1` ⇒ primer commit `2026-07-27` | `2026` |

Línea resultante: `Copyright (c) 2026 alexweil`.

**Lo que esto no resuelve, y se anota para el humano**: `alexweil` es el nombre de autor de git y el handle de GitHub, no necesariamente el nombre legal con el que quiera figurar. Cambiarlo es editar **un token en una línea** de `LICENSE` y no toca nada más. Se declara acá para que el RECAP consolidado lo pueda ofrecer; no se pregunta a mitad de unidad porque hay un valor derivable y defendible.

### 2. «Cero pérdida» cuando la mudanza es a la vez traducción — chequeo partido en dos

El diseño advierte que un diff de texto no sirve, porque el contenido cambia de idioma en el mismo movimiento. La bajada parte la verificación en dos mitades, y solo una necesita juicio:

**Baseline fijado: `284ace4:README.md`** (69 líneas) — no «el README de hoy», que ya se movió y va a seguir moviéndose dentro de este mismo feature. Todo lo de abajo se deriva de ese blob.

- **(A) Mecánica, sobre lo que no tiene idioma.** Comandos, flags, variables de entorno, paths, exit codes y las cadenas literales que imprime el instalador son **invariantes de idioma**: si están en el baseline y no están en la unión (README nuevo + `docs/install.md`), se perdieron. La r1 objetó —con razón— que «un extractor de tokens» sin algoritmo deja la selección al juicio del ejecutor, que puede omitir un token y obtener «cero faltantes». Queda fijado **el algoritmo, y la lista que produce, versionados en este doc**:

````sh
# Extractor. Entrada: markdown por stdin. Salida: un token por línea, únicos y ordenados.
# Regla cerrada, sin selección humana: (1) las líneas dentro de un fence se emiten enteras;
# (2) fuera de los fences, se emite cada span delimitado por backticks simples.
awk '
  /^```/ { infence = !infence; next }
  infence { if (length($0)) print; next }
  { line = $0
    while (match(line, /`[^`]+`/)) {
      print substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH) } }
' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' | sort -u
````

  Corrido sobre `git show 284ace4:README.md`, produce **exactamente 40 tokens**. La lista literal queda abajo, en §«Los 40 tokens del baseline», para que el chequeo sea un `grep` por línea contra la unión y no una búsqueda a ojo. Cero faltantes es el criterio; el conteo 40 es lo que impide que alguien acorte la lista y siga «cumpliendo».

- **(B) Por contenido, tramo por tramo, sobre la prosa.** Mapa **completo** de las 69 líneas del baseline — la r1 objetó que la versión anterior cubría la línea 18 y el bloque 22–69 pero dejaba **1–17 sin mapear**, incluyendo la entrada de uso y las descripciones actuales de comandos. Ahora todo tramo con contenido tiene fila y **disposición declarada**: `mudado` (va al manual), `conservado` (sigue en el README), `partido` o `reemplazado a propósito`.

**Cobertura, derivada y no afirmada**: de las 69 líneas, **33 no llevan contenido** — 23 en blanco (`awk 'NF==0'` ⇒ 2 4 8 10 12 17 19 21 23 27 29 33 35 39 41 43 47 49 51 53 55 64 66) y 10 delimitadores de fence (`awk '/^```/'` ⇒ 24 26 30 32 36 38 44 46 67 69). Quedan **36 líneas con contenido**, y las 36 están en el mapa de abajo — incluidos los cuatro encabezados (1, 9, 20, 52), que se mapean porque nombran secciones y su destino es una decisión.

#### Mapa completo del baseline (`284ace4:README.md`, líneas 1–69)

**Tramo de vidriera (1–19), que hasta la r1 no estaba mapeado:**

| # | Línea(s) | Contenido del baseline | Disposición | Destino |
|---|---|---|---|---|
| V1 | 1 | `# axel` (título) | reemplazado a propósito | README nuevo §1 — título más una línea de posicionamiento en inglés |
| V2 | 3 | descripción de una línea de la maquinaria (loop generador/reviewer, docs como memoria, checkpoints de OK) | reemplazado a propósito | README nuevo §1 y §7 — la misma sustancia, en inglés y con las tres cifras al lado |
| V3 | 5 | link a `AGENTS.md` | conservado | README nuevo §9 Links |
| V4 | 6 | link a `docs/STATUS.md` | conservado | README nuevo §9 Links |
| V5 | 7 | links a `docs/DESIGN.md` y `docs/IMPLEMENTATION.md` | conservado | README nuevo §9 Links |
| V6 | 9 | encabezado «Uso» | reemplazado a propósito | README nuevo §6 «The commands» |
| V7 | 11 | «Abrí Claude Code en el repo» | conservado | README nuevo §6, línea de entrada de la tabla |
| V8 | 13–16 | los **cinco** comandos con su descripción de una línea (`/status`, `/feature`, `/design`, `/plan`, `/recap`) | **ampliado y duplicado** | README nuevo §6 (tabla de siete: los cinco más `/build` y `/adopt`, que hoy faltan) **y** manual §The commands in full — ver abajo por qué el manual también los lleva |
| V9 | 18 | el loop corre solo y frena en cada RECAP · sesión remota · `awake.sh` + `caffeinate` · tapa cerrada necesita corriente y display externo | **partido** | README §7 How it works (la mecánica del loop y el RECAP) + manual §Requirements (la dependencia de macOS y la limitación de la tapa) |

**Por qué V8 se duplica en vez de solo apuntar.** El diseño dice que en el **dominio operativo** —y enumera «instalación, **uso**, casos, problemas conocidos»— el manual es el completo y el README el extracto, y que nada operativo queda documentado *solo* en el README. Una tabla de comandos es uso. La r1 marcó que la versión anterior introducía la tabla en §6 sin contraparte completa en el manual, lo que dejaba la referencia de uso viviendo únicamente en la vidriera. Se resuelve con una sección **§The commands in full** en `docs/install.md` —cada comando con qué hace, cuándo se usa, qué espera y con qué estado se puede invocar—, y el README conserva la tabla de una línea por comando como **extracto con puntero**. No es duplicación de una cifra (la regla de fuente única rige para números, y acá no hay ninguno): es el extracto y el completo que el propio corte prescribe.

**Tramo operativo (20–69), que se muda entero:**

| # | Caso del README actual (líneas) | Destino en `docs/install.md` | Delta |
|---|---|---|---|
| M0 | 20 · encabezado «Llevar axel a otro proyecto» | título y encabezado del manual | reemplazado a propósito |
| M1 | 22–26 · one-liner sin argumentos | §Install → *Quick install* | idéntico |
| M2 | 28 · los dos defaults anunciados, verificar dónde estás, rechazo fuera de un repo git, existen formas explícitas | §Install → *What the defaults assume* | idéntico |
| M3 | 30–32 · forma explícita `--from <fuente> <destino>` | §Install → *Explicit form* | idéntico |
| M4 | 34 · «Cómo saber que corrió»: la línea final `── axel · fin: rc=N`, el `curl` que falla y `bash` con stdin vacío, revisar `git status` | §Did it actually run? | idéntico |
| M5 | 36–38 · variante con `pipefail` | §Did it actually run? | idéntico |
| M6 | 40 · «Si te equivocaste de repo»: árbol limpio ⇒ el diff es todo, `git status --short` / `git restore .` / `git clean -fd`, guard del destino que es la propia fuente | §If you installed into the wrong repo | idéntico |
| M7 | 42 · el cache `~/.axel`, `AXEL_HOME`, manejo fail-closed del cache, y que el modo local no usa red | §Install → *The `~/.axel` cache* | idéntico |
| M8 | 44–46 · modo clásico con clon local (destino obligatorio) | §Install → *From a local clone* | idéntico |
| M9 | 48 · forks: sin `--from` instala el canónico; `AXEL_DEFAULT_REMOTE` | §Install → *Forks* | idéntico |
| M10 | 50 · qué instala, los tres modos, precondiciones, no commitea, exit codes 0/1/2 con la salvedad de la corrida incompleta, `tests/install.sh` | partido en §What gets installed, §The three modes y §Exit codes | **ampliado**: los tres modos pasan de una oración corrida a tres bloques, y los exit codes a tabla |
| M11 | 54 · intro de «Para agentes (Claude Code)» | §For agents (Claude Code) | idéntico |
| M12 | 56–63 · los cinco pasos numerados del procedimiento para agentes | §For agents (Claude Code) → los mismos cinco pasos | idéntico |
| M13 | 65 · auditar antes de ejecutar: clonar **fuera** del destino | §Audit before you run | idéntico |
| M14 | 67–69 · el comando de dos pasos con `mktemp -d` | §Audit before you run | idéntico |
**Cobertura verificada**: V1–V9 cubren las líneas 1, 3, 5, 6, 7, 9, 11, 13–16, 18; M0–M14 cubren 20, 22–26, 28, 30–32, 34, 36–38, 40, 42, 44–46, 48, 50, 54, 56–63, 65, 67–69. Unión = las **36 líneas con contenido**; complemento = las 33 sin contenido enumeradas arriba. Sin huecos y sin solapamientos.

**Regla de corte que el mapa hace cumplir** (diseño §«Vidriera y manual»): en el dominio operativo nada queda documentado **solo** en el README. Los casos M1–M14 salen del README y viven completos en el manual; el README conserva de ellos **un** camino de instalación y **punteros**, nunca el caso. V8 es el caso donde esa misma regla obliga a lo contrario de lo que parecía: la referencia de uso también necesita su versión completa en el manual.

**Contenido nuevo del manual, que no viene del baseline** (no es mudanza, así que no entra en el inventario de pérdida — pero sí en los criterios de completitud C6–C9, porque «no perder nada» y «entregar lo diseñado» son cosas distintas y la r1 marcó que los criterios viejos solo cubrían la primera): §The commands in full, §Known issues con los tres puntos de fricción, §After an adoption con los cuatro docs y dos nombres, y §License notice con la limitación del aviso MIT.

#### Los 40 tokens del baseline

Salida literal del extractor sobre `git show 284ace4:README.md`. El chequeo de la mitad (A) es: cada una de estas 40 líneas aparece en la unión de `README.md` + `docs/install.md` al cerrar el feature.

```
$0
--from
.claude/settings.json
.claude/state/
.gitignore
/adopt
/design
/feature
/plan
/recap
/status
0
1
2
AXEL_DEFAULT_REMOTE
AXEL_HOME
AXEL_SRC="$(mktemp -d)/axel" && git clone https://github.com/alexweil/axel "$AXEL_SRC" && "$AXEL_SRC/scripts/install.sh" "$(git rev-parse --show-toplevel)"
bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash'
bash -o pipefail -c '…'
bash -s -- --from <url-del-fork> <destino>
bash -s -- --from https://github.com/alexweil/axel <toplevel>
caffeinate
curl
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh | bash -s -- --from https://github.com/alexweil/axel <repo-destino>
docs/ADOPTION.md
git
git clean -fd
git restore .
git rev-parse --show-toplevel
git status
git status --short
install.sh
python3
scripts/awake.sh
scripts/install.sh /path/al/repo-destino
tests/install.sh
~/.axel
── axel · fin: rc=N · …
```

**Dos aclaraciones sobre la lista, para que el chequeo no se lea como más fuerte de lo que es.** (1) Algunos tokens son genéricos (`0`, `1`, `2`, `bash`, `git`, `curl`) y matchean casi en cualquier parte: no aportan poder discriminante, y se dejan igual porque quitarlos a mano reintroduciría exactamente la selección subjetiva que la r1 objetó. (2) Los tokens en **español** —`bash -s -- --from <url-del-fork> <destino>`, `scripts/install.sh /path/al/repo-destino`— llevan placeholders que la traducción va a cambiar; para esos, el criterio no es la igualdad literal sino que el **comando equivalente** exista, y la fila queda anotada como excepción declarada en la evidencia del cierre. Son 2 de 40 y están nombradas acá para que no se resuelvan por criterio del momento.

### 3. Qué corrida se renderiza en el transcript — pipeline 2026-07-29 (2), en dos bloques

El diseño fija **dos bloques con procedencia propia** y **ninguna línea inventada**. La bajada elige las fuentes:

**Bloque 1 — el arco completo**: el **pipeline 2026-07-29 (2)** ([pipeline-2026-07-29-2.md](pipeline-2026-07-29-2.md)), que tiene los cinco hitos en un solo ledger. Los cinco, con su fuente durable verificada:

| Hito | Fuente | Verificado |
|---|---|---|
| pedido sin comando | bloque Gate del ledger, línea 7 — pedido en prosa; `/adopt` aparece como **mención** (el objeto que se modifica), no como primer token ⇒ ruteo implícito | sí |
| gate + autorización | ledger, línea 21 — «a) ok con tu recomendacion · b) dejalo sin registrar» | sí |
| `CHANGES_REQUESTED` verdadero | [12-adopt-close-report.md](12-adopt-close-report.md) §Review log r1, punto 2 (base `bcf34f3`, head `9412edb`) | sí |
| corrección → `APPROVED` | corrección en `f85a033` (r2); cierre en `886fe4f` (r7, «APPROVED de cierre») | sí |
| RECAP → OK | STATUS a «esperando OK» en `eabd92f`; OK registrado en `39b377e`, literal «OK» en la §Cierre del ledger | sí |

**Por qué esta corrida y no la que sugirió el diseño.** El diseño ofreció como candidato citable `74d3f5c` (feature 11, «tres defectos invisibles en la lectura del texto nuevo»). Se descarta a favor del pipeline (2) por una razón de sustancia: lo que la r1 del feature 12 atrapó es un **defecto lógico del entregable**, no una inconsistencia de documentación — `git diff <base>..HEAD` es el efecto **neto entre extremos**, así que un archivo tocado y restaurado, o el paso intermedio de un `A → B → C`, desaparecía sin dejar rastro, que es exactamente la falla que el feature existía para prevenir. Para un lector escéptico —la objeción es «el reviewer es un sello de goma»— un bug real pesa más que una tabla desincronizada. Los cinco hitos de la corrida del feature 11 también existen; la elección es por fuerza del ejemplo, no por disponibilidad.

**Los originales están en español y eso no se disimula.** El README es inglés, las fuentes no. Publicar solo la traducción rompería la auditabilidad: el lector no podría cotejar contra el repo. Entonces cada línea del bloque va **citada en su idioma original con su fuente al lado** (archivo o SHA) y su traducción al inglés. Es más largo y es el único formato honesto — y de paso contesta la objeción «está todo en español» mostrándola en vez de argumentándola.

**Bloque 2 — la prueba externa**: la instalación y adopción reales en `/Users/alexweil/src/inquirylab`, rotulada como lo que es. Verificado hoy en ese repo, no citado de memoria:

| Afirmación | Verificación |
|---|---|
| axel instalado en un repo activo ajeno | commit `846308f` (2026-07-29), 20 archivos, 1330 inserciones; el repo tiene 185 commits |
| era modo adopción, no instalación limpia | el commit dejó `docs/ADOPTION.md` con 21 docs preexistentes listados |
| la adopción **se cerró** con `/adopt` | commit `4908bfb`: 8 archivos (`M AGENTS.md`, `D DESIGN.md`, `M README.md`, `D docs/ADOPTION.md`, `M docs/DESIGN.md`, `M docs/IMPLEMENTATION.md`, `M docs/STATUS.md`, `R075 IMPLEMENTATION.md → docs/implementation/bitacora.md`); hoy `docs/ADOPTION.md` no existe |
| el workaround de `build/` se aplicó ahí de verdad | commit `98c70c0`, con la trampa de `!.claude/` explicada en el propio `.gitignore` |

**Alcance honesto, que va escrito en el README**: un repo, del mismo autor, y una **adopción** — no el loop completo de review. No prueba más que eso.

### 4. Cómo se prueban el one-liner y el workaround sin ensuciar el repo — ya ejecutado

En repos git descartables creados fuera de axel (bajo el scratchpad de la sesión), con `.gitignore` de template Python. **Cuatro corridas, todas ejecutadas antes de escribir esta bajada:**

| # | Setup | Comando | Resultado observado |
|---|---|---|---|
| P1 | `.gitignore` con `build/` | `scripts/install.sh <dest>` (clon local, código de hoy) | **rechazo**, nada escrito, `git status` vacío. `rechazo: .claude/skills/build/SKILL.md: nacería ignorado por las reglas del destino; nada del instalador puede quedar fuera del diff` |
| P2 | + `!.claude/` (la trampa) | ídem | **sigue rechazando**. `git check-ignore -v` responsabiliza a `.gitignore:3:build/`: la negación no re-incluye porque un directorio padre intermedio quedó excluido |
| P3 | + `!.claude/skills/build/` | ídem | **instala**. `rc=1` (modo adopción: el repo tenía un `README.md` propio) |
| P4 | repo sin docs propios, con el workaround | el one-liner publicado, `curl … \| bash` | **instala**, `rc=0`, 18 archivos + entrada `.claude/state/` en `.gitignore`; cache `~/.axel` en `main @ 88020af` |

**Corrección factual que la prueba obligó**: el pedido del gate transcribía la línea final del rechazo como `── axel · fin: rc=2 · rechazo (ver el detalle arriba) ──`. La línea **real** es `── axel · fin: rc=2 · rechazo del preflight (1 problema(s), nada escrito) ──`. Se publica la real. Es la justificación en vivo del criterio (c): transcribir de memoria produce documentación falsa.

**Nota sobre P4**: el one-liner instala lo que hay en el **remoto** (`88020af`), que está detrás del local porque el pipeline no pushea (ajuste (b) del gate). Lo que P4 prueba es que **el comando publicado funciona end-to-end**; no prueba nada sobre el contenido no pusheado, y el README no afirma otra cosa.

## El corte de métricas — `b0bdf4d`

El contrato con el feature 14 exige que el **13 declare un commit de corte que ya exista** (no el suyo) y que el 14 **reconstruya exactamente ese corte** filtrando el log, en vez de sacar una foto nueva.

**Corte declarado: `b0bdf4d`** — head de la ronda 4 (`APPROVED`) de la unidad `plan` de este mismo pipeline. Se elige porque era **el último SHA que aparecía en `.claude/state/rounds-log`** al declararlo, lo que vuelve mecánica la reconstrucción del 14: *tomar las filas hasta la que lleva ese SHA, inclusive*. Verificado que `b0bdf4d` es ancestro de `HEAD`.

### La reconstrucción, fail-closed

La r1 objetó —con razón— que la versión anterior (`awk '{print} $6=="b0bdf4d"{exit}'`) **imprimía el archivo entero y salía con éxito** si el SHA no existía, y tampoco rechazaba duplicados: es decir, fallaba abierto justo en el caso que tiene que detectar. Reemplazada por una que exige **exactamente una** fila de corte:

````sh
# recorte.awk — reconstruye el snapshot al corte. Falla si el SHA no está o está repetido.
BEGIN { FS = "\t" }
{ line[NR] = $0 }
$6 == cut { hit++; stop = NR }
END {
  if (hit != 1) {
    printf "FAIL: %d fila(s) con el SHA de corte %s; se exige exactamente 1\n", hit+0, cut > "/dev/stderr"
    exit 1
  }
  for (i = 1; i <= stop; i++) print line[i]
}
````

Invocación y postcondiciones, las tres obligatorias:

```sh
awk -v cut=b0bdf4d -f recorte.awk .claude/state/rounds-log > snapshot.tsv   # rc debe ser 0
test "$(wc -l < snapshot.tsv)" -eq 88                                       # exactamente 88 filas
test "$(tail -1 snapshot.tsv | cut -f6)" = b0bdf4d                          # la última fila ES el corte
```

**Los cuatro modos de falla, probados** (no argumentados):

| Caso | Resultado |
|---|---|
| corte presente una vez | `rc=0`, 88 filas, última fila `b0bdf4d` |
| SHA inexistente (`deadbee`) | `rc=1`, `FAIL: 0 fila(s)…` |
| SHA duplicado | `rc=1`, `FAIL: 2 fila(s)…` |
| log vacío | `rc=1`, `FAIL: 0 fila(s)…` |

**Demostración en vivo de que el corte sirve**: entre que escribí la bajada y llegó esta corrección, la review r1 de este mismo feature agregó su fila y el `rounds-log` pasó de **88 a 89** filas. La reconstrucción al corte siguió dando **88**. Es el tercer hallazgo del diseño ocurriendo por segunda vez, ahora sobre el feature que publica las cifras.

**De acá en adelante, `snapshot.tsv` es el input nombrado de todos los comandos de métricas** — otra corrección de la r1: los comandos anteriores no decían sobre qué archivo corrían, y corridos sobre el `rounds-log` vivo darían valores distintos cada día.

**Consecuencia declarada** (propia de cualquier foto, no un defecto): el corte **no incluye las rondas de los features 13 y 14**. Va escrita en el README.

### Cifras derivadas al corte, con su comando

Toolchain de stock de macOS; sin `asort` (que es de gawk), el orden se resuelve con `sort`. Formato del log: `ts \t {new|round} \t ronda \t intento \t veredicto \t sha \t racha`.

Todos toman **`snapshot.tsv`** como input explícito. Los de tramos usan un reductor común, `mediana()`, que también se declara — la r1 marcó que las medianas y los tramos por hito se afirmaban sin comando:

```sh
mediana() { sort -n | awk '{a[NR]=$1} END{ if(NR%2) m=a[(NR+1)/2]; else m=(a[NR/2]+a[NR/2+1])/2
             print "n="NR" mediana="m" min="a[1]" peor="a[NR] }'; }
```

| Cifra | Comando (input: `snapshot.tsv`) | Valor |
|---|---|---|
| rondas registradas (dedup por ciclo y número) | `awk -F'\t' '$2=="new"{c++} $6!="-"{k=c":"$3; if(!(k in s)){s[k]=1; n++}} END{print n}' snapshot.tsv` | **88** |
| `CHANGES_REQUESTED` | `awk -F'\t' '$5=="CHANGES_REQUESTED"{n++} END{print n}' snapshot.tsv` | **59** |
| `APPROVED` (**hitos**, no features) | `awk -F'\t' '$5=="APPROVED"{n++} END{print n}' snapshot.tsv` | **29** |
| ciclos completos | `awk -F'\t' '$2=="new"{n++} END{print n}' snapshot.tsv` | **18** (+1 parcial, el del arranque del log) |
| veredicto de la **r1** de cada ciclo | `awk -F'\t' '$2=="new"{print $5}' snapshot.tsv \| sort \| uniq -c` | **18 de 18 `CHANGES_REQUESTED`** — cero aprobados en ronda 1 |
| mediana y peor caso por **ciclo** | `awk -F'\t' '$2=="new"{if(c)print c; c=0}{c++} END{if(c)print c}' snapshot.tsv \| tail -n +2 \| mediana` | `n=18 mediana=4 peor=11` |
| mediana y peor caso por **hito** | `awk -F'\t' '{n++} $5=="APPROVED"{print n; n=0}' snapshot.tsv \| tail -n +2 \| mediana` | `n=28 mediana=3 min=1 peor=5` |
| hitos aprobados sin rechazo en su tramo | `awk -F'\t' '{n++} $5=="APPROVED"{if(n==1) print $6; n=0}' snapshot.tsv` | **exactamente 1** (`2dbbdfc`) |

**Por qué los dos `tail -n +2`**: el primer valor que emite cada uno corresponde al tramo **parcial** con que arranca el log —el ciclo que ya venía en curso cuando se instrumentó, y su primer hito—, cuya longitud real no es observable. Descartarlo es la misma decisión que el diseño tomó para la mediana por ciclo; hacerlo con un comando en vez de a mano es lo que la vuelve auditable. Longitudes por ciclo, para lectura directa: `2 2 2 2 3 3 3 4 4 4 5 5 6 7 7 7 8 11`.

**Aviso obligatorio para el feature 14 y para cualquier relectura: la mediana por ciclo volvió a dar 4, y no es la reaparición del error que el delta de diseño corrigió.** El diseño ([public-surface.md](../design/public-surface.md) §«La unidad de conteo») corrigió un **4** que era falso: salía de contar el ciclo **parcial** del arranque del log como si fuera completo, y sobre los 16 ciclos completos de su corte (`e1e1282`) la mediana era **4,5**. Al corte `b0bdf4d` hay **18** ciclos completos —los dos nuevos son las unidades `design` y `plan` de este pipeline, de 4 rondas cada una—, y la mediana de 18 valores es el promedio del 9.º y el 10.º, que son `4` y `4`. O sea: **mismo número, criterio distinto, corte distinto**. El ciclo parcial sigue excluido. Publicar «4» sin esta nota reintroduciría la confusión que el diseño resolvió; por eso la mediana **no va al README** —va al doc de métricas del 14, que es donde el criterio se explica— y el README publica solo la terna de titular.

### Cifras del gancho, al mismo corte

| Cifra | Comando (anclado al corte) | Valor |
|---|---|---|
| commits | `git rev-list --count b0bdf4d` | **212** |
| días | `git log b0bdf4d --format='%ad' --date=short \| sort -u \| wc -l` | **3** (2026-07-27 · 28 · 29) |
| features cerrados | `git show b0bdf4d:docs/IMPLEMENTATION.md \| grep -cE '^\| [0-9]+ \|.*\*\*Cerrado\*\*'` | **13** |

**El conteo de features va contra el `IMPLEMENTATION.md` del corte, no contra el del árbol** (corrección de la r1): el archivo vivo se mueve, y **devolvería 14 en cuanto este mismo feature cierre**, dejando el README afirmando una cifra que su propio comando desmiente. `git show b0bdf4d:…` lo clava.

**Formulación pública, con la precisión que pidió la r1**: se publica **«13 closed features (00–12, including bootstrap)»**. El bloque «Hechos del pedido» del ledger dice 12 porque cuenta 01–12 y deja afuera el feature **00**; la tabla del plan lo lista como fila cerrada igual que los demás, así que el número derivable es 13. Nombrar el rango y el bootstrap en la misma línea evita que la diferencia se lea como inflado.

### Total histórico

**88 registradas** al corte + **35 anteriores a la instrumentación** = **123**. Las 35 vienen de **dos fuentes que se citan por separado** (diseño §«La unidad de conteo», hallazgo 2). La r1 objetó que C4 prometía re-derivarlas sin dar comando; quedan las tres derivaciones escritas, y todas verificadas:

| Tramo | Derivación | Valor |
|---|---|---|
| features 00–02, ciclos completos anteriores al log | `git show b0bdf4d:docs/IMPLEMENTATION.md \| grep -E '^\| 0[0-2] \|' \| sed -E 's/.*\(r([0-9]+).*/\1/' \| awk '{s+=$1} END{print s}'` — la tabla del plan registra la **ronda de cierre** de cada feature, que es su cantidad de rondas | **25** (4 + 11 + 10) |
| feature 03, el tramo que quedó fuera del log | `head -1 snapshot.tsv \| cut -f3` ⇒ `6`: el log **arranca en la ronda 6** de un ciclo en curso, así que le faltan las 1–5 de ese ciclo. El propio snapshot delata el faltante | **5** |
| ciclo de plan inicial (sin doc en `implementation/`) | `git log --oneline 6afb57d..3ab6794 \| grep -cE ' plan r[0-9]+:'` ⇒ **4** commits de corrección, más la ronda que aprobó y cerró el ciclo en `3ab6794` | **5** |

**25 + 5 + 5 = 35**, y **88 + 35 = 123**. La tercera fila es la que el diseño manda citar aparte: no tiene esquema tabular ni doc en `implementation/`, y su memoria son los commits y el STATUS histórico — verificado en `git show 2f7c814:docs/STATUS.md`, que registra «la ronda 1 pidió cambios (2 puntos, resueltos)» para ese ciclo. El README publica las dos cifras **rotuladas** —«88 logged rounds since instrumentation» y 123 como histórico con su segunda fuente— y nunca una sola sin decir a cuál corresponde.

## Enfoque

### `LICENSE`

Texto MIT estándar, sin modificar, con `Copyright (c) 2026 alexweil`.

### `README.md` — nueve secciones, inglés, objetivo ~120 líneas

Estructura aprobada por el diseño, con sus cuatro refinamientos (cifras con su unidad en el título; requisitos **antes** de instalar; Install lleva puntero y no casos; «What this is not» se queda en §8):

1. **Title + one line + the three figures** — las tres del reviewer, con su unidad nombrada y su commit de corte, y la marca visible de que el artefacto auditable llega en el feature 14.
2. **The problem** (~6 líneas) — un agente solo no se audita a sí mismo y pierde el hilo entre sesiones.
3. **What a session actually looks like** — los dos bloques, con procedencia por línea.
4. **Requirements, honestly** — Claude Code **y** Codex CLI (dos suscripciones, dos proveedores), macOS (`caffeinate`), git, python3, y que una review en xhigh puede tardar >10 min.
5. **Install** — el one-liner, el puntero de una línea al known issue de `build/`, el puntero al manual, y el puntero de una línea **para agentes**.
6. **The commands** — tabla de los seis (`/design`, `/plan`, `/feature`, `/build`, `/status`, `/recap`) más `/adopt` como fila aparte y rotulada, porque `DESIGN.md` lo trata como componente separado.
7. **How it works** — el diagrama de flujo de `DESIGN.md` y los cinco principios comprimidos.
8. **What this is not** — las seis objeciones contestadas.
9. **Links** — diseño, contrato de review, plan, y las **dos referencias no activas** (métricas y feedback).

**Las dos referencias hacia adelante, según el contrato con el 14**: se nombran **en prosa, sin linkear**, con una marca **visible** —no una nota al pie— de que el artefacto llega en el feature 14. La forma elegida: un bloque `> **Coming in the next feature (14):** …` en §9, más el sufijo `(not yet published — feature 14)` en la línea de las cifras del título. Los **paths** no se eligen acá: son decisión del 14.

**Las seis objeciones y dónde se contestan** (criterio de aceptación de la prosa: cada una contestada **antes** de que el lector la formule):

| Objeción | Sección | Cómo |
|---|---|---|
| «cuesta una fortuna» | §4 Requirements | dos suscripciones de dos proveedores y reviews largas, declarado antes del comando |
| «el reviewer es otro LLM» | §1 y §8 | las cifras + que Codex **ejecuta** tests en un worktree snapshot |
| «es un montón de markdown» | §8 | sí, y es la virtud: sin dependencias, sin lock-in |
| «está todo en español» | §3 y §8 | se **muestra** en el transcript (original + traducción) y se declara: vidriera en inglés, método en español, prosa instalada en español como limitación |
| «macOS only» | §4 | qué se rompe (`caffeinate` / `awake.sh`) y qué no |
| «¿funciona fuera de axel?» | §3 bloque 2 | inquirylab, con su alcance honesto |

### `docs/install.md` — inglés, el manual completo

**Lista cerrada de secciones** — es lista cerrada porque C6 la verifica una por una, y la r1 mostró que sin eso los criterios permitían aprobar un manual al que le faltara la mitad:

1. Requirements
2. Install — *Quick install* · *What the defaults assume* · *Explicit form* · *From a local clone* · *The `~/.axel` cache* · *Forks*
3. Did it actually run?
4. If you installed into the wrong repo
5. What gets installed
6. The three modes
7. After an adoption
8. Exit codes
9. **The commands in full** — la referencia operativa completa de los siete comandos, de la que el README §6 es el extracto (ver V8 arriba)
10. For agents (Claude Code)
11. Audit before you run
12. Known issues
13. License notice
14. Tests

**Known issues**, con el criterio del diseño (un problema se documenta donde el usuario lo choca):

1. **La colisión `build/`** — el rechazo literal verificado en P1, el workaround `!.claude/skills/build/`, y la trampa de `!.claude/` explicada con la evidencia de `git check-ignore -v`. Único que además se gana un puntero desde el README, por ser el único que **bloquea** la promesa de «instalalo sin volver a preguntar».
2. **El rechazo por árbol sucio no lista los archivos sucios**, y `git stash` sin `-u` no toca untracked — que es el caso más común en un repo activo.
3. **`modo: initial` anunciado cuando lo ejecutado fue una adopción** (verificado en P3, que anunció `initial` y salió con `rc=1` y `ADOPTION.md`), con su consecuencia visible: el destino queda con cuatro docs y dos nombres sin aviso de cuál manda. Va en §After an adoption, que es donde se choca.

**§License notice** declara la limitación como **incumplimiento pendiente y no como cumplimiento parcial**: MIT pide que el aviso viaje en las copias, el instalador copia skills, scripts y contrato sin llevarlo, y decirlo en el manual **informa y no satisface el requisito**.

## Criterios de cierre

La r1 objetó que los criterios anteriores garantizaban **no perder nada** pero no **entregar lo diseñado**: C3 solo validaba las oraciones presentes y C5 excluía explícitamente el contenido nuevo, así que un `docs/install.md` sin dos de los tres known issues, sin §After an adoption, sin el aviso MIT o sin contestar las seis objeciones podía aprobar igual. Se agregan los cuatro criterios de **completitud** que faltaban (C6–C9) y se numeran de nuevo.

| # | Criterio | Cómo se verifica |
|---|---|---|
| C1 | `LICENSE` existe, es MIT estándar y dice `Copyright (c) 2026 alexweil` | lectura + las dos derivaciones ancladas de §1 |
| C2 | `README.md` en inglés, las nueve secciones en el orden aprobado, requisitos **antes** del comando de instalación | lectura contra la estructura de arriba |
| C3 | **Cero afirmación no verificable**: toda oración del README y del manual cae en una de las tres clases del contrato editorial (hecho derivable con su comando · limitación declarada · opinión marcada) | pasada por oración, registrada en el Review log |
| C4 | Toda cifra publicada lleva su **commit de corte** y su comando; las cifras se re-derivan con los comandos de §«El corte de métricas» **sobre `snapshot.tsv`** y coinciden. Incluye las tres derivaciones de las 35 históricas | re-corrida de la tabla de comandos, con la reconstrucción fail-closed y sus tres postcondiciones |
| C5 | **Cero pérdida**: las **36 líneas con contenido** del baseline `284ace4:README.md` están en el mapa V1–V9 / M0–M14 con destino, y los **40 tokens** del extractor aparecen en la unión README + manual (con las 2 excepciones de placeholder declaradas) | mapa + `grep` token por token sobre la lista versionada |
| **C6** | **Completitud del manual**: existen y tienen contenido las **14 secciones** de la lista cerrada de §Enfoque, incluida §The commands in full con los **siete** comandos | recorrido de la lista, una por una |
| **C7** | **Los tres problemas conocidos están**, cada uno donde el diseño lo manda: la colisión `build/` con su workaround y la trampa de `!.claude/` en §Known issues; el rechazo por árbol sucio en §Known issues; el `modo: initial` en una adopción en §After an adoption | inspección por punto, contra la tabla del diseño |
| **C8** | **El aviso MIT está declarado como incumplimiento pendiente**, no como cumplimiento parcial: §License notice dice que el aviso no viaja con el payload y que declararlo en el manual informa pero **no** satisface el requisito | lectura literal de la sección |
| **C9** | **Las seis objeciones están contestadas** en el README, cada una en la sección donde la tabla de §Enfoque la ubica | recorrido de las seis, con el locator de cada respuesta |
| C10 | **Cero link roto**: todo link del README y del manual resuelve | chequeo mecánico de cada destino relativo |
| C11 | Las **dos** referencias a artefactos del 14 están **sin linkear** y marcadas como pendientes de forma visible | inspección de §1 y §9 |
| C12 | El one-liner y el workaround publicados son los **probados** (P1–P4), incluida la línea final real del rechazo | comparación literal contra la evidencia de §4 |
| C13 | El transcript no tiene **ninguna línea inventada**: cada una rastrea a un commit, un evento de ledger o un review log, citado en su idioma original | tabla de fuentes de §3, verificada una por una |
| C14 | **Alcance**: el diff del feature toca solo `LICENSE`, `README.md`, `docs/install.md`, este doc, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` y el ledger — cero cambios en método, skills, instalador, scripts, tests o remoto | `git diff --stat` contra el SHA de arranque `284ace4` |
| C15 | El README conserva el **puntero de una línea para agentes**, para que el camino «instalá axel siguiendo \<url\>» del feature 02 no aterrice en una página sin procedimiento | inspección de §5 |
| C16 | No-regresión: `tests/lint.sh`, `tests/loop.sh` y `tests/install.sh` siguen limpios | corrida de las tres suites |

## Riesgos

1. **Prosa sin harness.** No hay test que compruebe que un README convence. Mitigación: los criterios son de **verificabilidad**, no de gusto — el contrato editorial convierte «prosa auditable» en una clasificación por oración, y C3/C9 la hacen revisable.
2. **Las cifras se mueven mientras se escribe.** Ya pasó durante la review del delta de diseño. Mitigación: corte declarado, comandos escritos, y la consecuencia (el snapshot no incluye las rondas del 13 y del 14) publicada en vez de escondida.
3. **La mediana que volvió a 4.** Riesgo concreto de que una relectura futura crea que se reintrodujo el error corregido. Mitigación: el aviso explícito de arriba, y la decisión de **no publicar la mediana en el README**.
4. **Traducir mientras se muda puede perder un caso en silencio.** Mitigación: la partición (A)/(B) — lo invariante de idioma se chequea con una lista de **40 tokens** producida por un extractor versionado, y la prosa contra un mapa que cubre las **36 líneas con contenido** del baseline, con la cobertura derivada y no afirmada.
7. **«No perder nada» no es «entregar lo diseñado».** Riesgo que la r1 encontró y que no estaba en esta lista: un manual podía pasar C3 y C5 con la mitad del contenido nuevo ausente. Mitigación: C6–C9, que verifican completitud contra listas cerradas —14 secciones, 3 problemas conocidos, el aviso MIT, 6 objeciones— en vez de contra el criterio de quien revisa.
5. **El one-liner probado corre contra el remoto, que está detrás del local.** Mitigación: declarado en §4; el README no afirma nada sobre el contenido no pusheado.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Es una línea y está a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.

## Review log

### r1 (base `284ace4`, HEAD `1c34281`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

Codex verificó por su cuenta y dio por buenas **todas las cifras declaradas** —incluida la mediana 4—, los cinco hitos del transcript, la evidencia de inquirylab, que las referencias pendientes al 14 cumplen el contrato, que P1–P4 reproducen RC 2/2/1/0 con el remoto en `88020af`, y el alcance limitado a los cuatro docs autorizados; más `lint.sh` limpio, `loop.sh` 287/0 e `install.sh` 460/0. También dio por adecuada la mitigación de la mediana (no publicarla en el README y explicarla en el informe del 14). Los tres puntos son **bloqueantes de método, no de dato**: ninguno movió una cifra, y los tres apuntan al mismo defecto de fondo — yo verifiqué a mano y escribí el resultado, en vez de dejar escrito un procedimiento que falle solo cuando el resultado sea otro.

1. **El corte no se reconstruía fail-closed.** Cierto y era el peor de los tres: el `awk` que publiqué (`{print} $6=="b0bdf4d"{exit}`) **imprime el archivo entero y sale con éxito** si el SHA no está, y no rechaza duplicados — falla abierto exactamente en el caso que existe para detectar. Y con él venían cuatro derivados: los comandos de métricas **no nombraban su input**; el conteo de features consultaba el `IMPLEMENTATION.md` vivo, que **habría devuelto 14 en cuanto cierre este feature**; las derivaciones del copyright citaban 212 commits pero corrían `git log` sin revisión sobre un `HEAD` que ya tiene 216; y faltaban comandos para las medianas, los tramos por hito y las 35 rondas históricas que C4 promete re-derivar. **Aceptado entero, sin argumentar nada.** Reescrita la reconstrucción con `hit != 1 ⇒ exit 1` y **probados los cuatro modos de falla** (corte único, ausente, duplicado, log vacío); `snapshot.tsv` pasa a ser el input explícito de toda la tabla; los comandos de gancho y de copyright quedan anclados a `b0bdf4d` (`git show b0bdf4d:docs/IMPLEMENTATION.md`, `git log b0bdf4d …`); se agregan el reductor `mediana()` y las **tres** derivaciones de las 35 históricas (25 de la tabla del plan al corte, 5 que el propio snapshot delata al arrancar en la ronda 6, 5 del ciclo de plan acotado por rango de commits). Adoptada también su formulación pública: **«13 closed features (00–12, including bootstrap)»**. Corolario que salió de acá: entre la bajada y esta corrección el `rounds-log` pasó de 88 a **89** filas por la review r1 de este mismo feature, y la reconstrucción al corte siguió dando 88 — el hallazgo 3 del diseño ocurriendo por segunda vez, ahora sobre el feature que publica las cifras.
2. **C1–C12 no alcanzaban para garantizar el entregable diseñado.** Cierto: C3 valida solo las oraciones **presentes** y C5 excluía explícitamente el contenido nuevo, así que un `docs/install.md` sin dos de los tres known issues, sin §After an adoption, sin el aviso MIT o sin contestar las seis objeciones **aprobaba igual**. Es el hueco entre «no perder nada» y «entregar lo diseñado». **Aceptado**: se agregan **C6–C9**, que verifican completitud contra listas cerradas (14 secciones del manual, 3 problemas conocidos con su ubicación, el aviso MIT como incumplimiento pendiente, las 6 objeciones con su locator), y los criterios se renumeran a C1–C16. Aceptado también el segundo hallazgo del punto, que es de diseño y no de criterio: el diseño enumera **«uso»** dentro del dominio operativo donde el manual debe ser el completo, y yo introducía la tabla de comandos en el README §6 sin contraparte. Se agrega **§The commands in full** al manual, con el README como extracto; queda como fila **V8** del mapa, con su justificación escrita para que no se lea como duplicación caprichosa.
3. **La mitad mecánica de «cero pérdida» seguía dependiendo del juicio del ejecutor.** Cierto: «un extractor de tokens» sin algoritmo ni lista cerrada permite omitir un token al seleccionarlos y obtener «cero faltantes». Y el mapa contabilizaba la línea 18 y el bloque 22–69 pero **dejaba 1–17 afuera**, incluyendo la entrada de uso y las descripciones de comandos — que es justo donde estaba el problema del punto 2. **Aceptado**: baseline fijado en `284ace4:README.md`; extractor escrito como `awk` reproducible y **su salida de 40 tokens versionada literalmente** en el doc; mapa extendido a **V1–V9 + M0–M14**, con disposición declarada por tramo (mudado / conservado / partido / reemplazado a propósito) y **cobertura derivada**: 33 líneas sin contenido (23 en blanco + 10 delimitadores de fence, ambas enumeradas por comando) y 36 con contenido, todas mapeadas, sin huecos ni solapamientos. Declaradas además las 2 excepciones de la lista de tokens (placeholders en español que la traducción cambia), para que no se resuelvan por criterio del momento.
