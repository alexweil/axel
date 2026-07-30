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
# Reglas cerradas, sin selección humana: (1) las líneas dentro de un fence, enteras;
# (2) cada span entre backticks simples; (3) cada destino de link markdown ](…);
# (4) cada path o nombre de archivo **desnudo** en la prosa — se le quita a la línea lo ya
#     capturado por (2) y (3) y las URLs, y sobre ese residuo se buscan los .md/.sh/.json.
awk '
  /^```/ { infence = !infence; next }
  infence { if (length($0)) print; next }
  { line = $0
    while (match(line, /`[^`]+`/)) {
      print substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH) }
    line = $0
    while (match(line, /\]\([^)]+\)/)) {
      print substr(line, RSTART + 2, RLENGTH - 3); line = substr(line, RSTART + RLENGTH) }
    rest = $0
    gsub(/`[^`]+`/, " ", rest); gsub(/\]\([^)]+\)/, " ", rest)
    gsub(/https?:\/\/[^ )]+/, " ", rest)
    while (match(rest, /[A-Za-z0-9_~][A-Za-z0-9_~.\/-]*\.(md|sh|json)/)) {
      print substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH) } }
' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' | sort -u
````

  Corrido sobre `git show 284ace4:README.md`, produce **exactamente 45 tokens**. La lista literal queda abajo, en §«Los 45 tokens del baseline», para que el chequeo sea un `grep` por línea contra la unión y no una búsqueda a ojo. Cero faltantes es el criterio; el conteo 45 es lo que impide que alguien acorte la lista y siga «cumpliendo».

  **Las reglas 3 y 4 no son cosméticas: cada una tapó un agujero real, y las dos las encontró la review.**

  - **Regla 3 (r2)** — el extractor original solo miraba backticks, así que `AGENTS.md`, `docs/STATUS.md`, `docs/DESIGN.md` y `docs/IMPLEMENTATION.md` —que en el baseline aparecen **únicamente** como destino de link— no estaban entre los tokens. Combinado con una estructura de §9 laxa, los cuatro podían desaparecer del README nuevo y **pasar C2, C5 y C10 sin que nada lo marcara**.
  - **Regla 4 (r3)** — quedaba todavía una clase afuera: los paths **desnudos**, sin backticks ni link. El caso concreto es `CLAUDE.md`, que en la línea 50 del baseline aparece en prosa («siembra lo que falte (AGENTS.md + symlink CLAUDE.md, docs, settings)»). Sin la regla 4, C5 podía aprobar la **pérdida de la documentación del symlink sembrado**, que es una de las piezas que el instalador crea. Es 1 token más, y M10 pasa a nombrarlo explícito.

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
| M10 | 50 · qué instala —maquinaria (skills, scripts, contrato, política) y semillas, nombrando **`AGENTS.md` + el symlink `CLAUDE.md`**, docs y settings—, los tres modos, precondiciones, que no commitea, exit codes 0/1/2 con la salvedad de la corrida incompleta, y `tests/install.sh` | partido en §What gets installed, §The three modes y §Exit codes | **ampliado**: los tres modos pasan de una oración corrida a tres bloques, y los exit codes a tabla. `AGENTS.md` y el symlink `CLAUDE.md` van **nombrados explícitamente** en §What gets installed (r3): `CLAUDE.md` aparece en el baseline solo como path desnudo, y hasta la regla 4 del extractor su pérdida no la detectaba nadie |
| M11 | 54 · intro de «Para agentes (Claude Code)» | §For agents (Claude Code) | idéntico |
| M12 | 56–63 · los cinco pasos numerados del procedimiento para agentes | §For agents (Claude Code) → los mismos cinco pasos | idéntico |
| M13 | 65 · auditar antes de ejecutar: clonar **fuera** del destino | §Audit before you run | idéntico |
| M14 | 67–69 · el comando de dos pasos con `mktemp -d` | §Audit before you run | idéntico |
**Cobertura verificada**: V1–V9 cubren las líneas 1, 3, 5, 6, 7, 9, 11, 13–16, 18; M0–M14 cubren 20, 22–26, 28, 30–32, 34, 36–38, 40, 42, 44–46, 48, 50, 54, 56–63, 65, 67–69. Unión = las **36 líneas con contenido**; complemento = las 33 sin contenido enumeradas arriba. Sin huecos y sin solapamientos.

**Regla de corte que el mapa hace cumplir** (diseño §«Vidriera y manual»): en el dominio operativo nada queda documentado **solo** en el README. Los casos M1–M14 salen del README y viven completos en el manual; el README conserva de ellos **un** camino de instalación y **punteros**, nunca el caso. V8 es el caso donde esa misma regla obliga a lo contrario de lo que parecía: la referencia de uso también necesita su versión completa en el manual.

**Contenido nuevo del manual, que no viene del baseline** (no es mudanza, así que no entra en el inventario de pérdida — pero sí en los criterios de completitud C6–C9, porque «no perder nada» y «entregar lo diseñado» son cosas distintas y la r1 marcó que los criterios viejos solo cubrían la primera): §The commands in full, §Known issues con los tres puntos de fricción, §After an adoption con los cuatro docs y dos nombres, y §License notice con la limitación del aviso MIT.

#### Los 45 tokens del baseline

Salida literal del extractor sobre `git show 284ace4:README.md`. El chequeo de la mitad (A) es: cada una de estas 45 líneas aparece en la unión de `README.md` + `docs/install.md` al cerrar el feature.

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
AGENTS.md
AXEL_DEFAULT_REMOTE
AXEL_HOME
AXEL_SRC="$(mktemp -d)/axel" && git clone https://github.com/alexweil/axel "$AXEL_SRC" && "$AXEL_SRC/scripts/install.sh" "$(git rev-parse --show-toplevel)"
CLAUDE.md
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
docs/DESIGN.md
docs/IMPLEMENTATION.md
docs/STATUS.md
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

**Dos aclaraciones sobre la lista, para que el chequeo no se lea como más fuerte de lo que es.**

1. Algunos tokens son genéricos (`0`, `1`, `2`, `bash`, `git`, `curl`) y matchean casi en cualquier parte: no aportan poder discriminante, y se dejan igual porque quitarlos a mano reintroduciría exactamente la selección subjetiva que la r1 objetó.
2. Dos tokens llevan **placeholders en español** que la traducción cambia. La r2 objetó —con razón— que resolverlos como «que exista el comando equivalente» devuelve el chequeo al juicio del ejecutor. Se fija la **traducción literal esperada**, de modo que sigan siendo igualdad exacta de cadena contra un valor declarado de antemano y no una apreciación:

   | Token del baseline | Cadena exacta esperada en la unión |
   |---|---|
   | `bash -s -- --from <url-del-fork> <destino>` | `bash -s -- --from <fork-url> <destination>` |
   | `scripts/install.sh /path/al/repo-destino` | `scripts/install.sh /path/to/target-repo` |

   Cualquier otra traducción de esos dos es un fallo de C5, no una variante aceptable. Si al escribir el manual conviniera otra forma, se cambia **esta tabla primero** y queda registrado en el Review log.

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

#### Primero se normaliza a rondas contractuales; recién después se cuenta

La r2 encontró que mis reductores **contaban filas e intentos, no rondas del contrato**, y lo reprodujo sintéticamente. Dos defectos distintos en la misma familia:

- **`$2=="new"` abre ciclo con cualquier fila `new`**, pero durante un reintento el intento 1 y el intento 2 conservan los dos `mode=new` ⇒ **dos ciclos y dos «r1»**, y una de esas r1 tiene veredicto `PROC_FAIL`, que no es un veredicto.
- **Las longitudes por ciclo y por hito incrementaban por fila** ⇒ se inflaban con cada `PROC_FAIL`.

El log de hoy no tiene reintentos (las 88 filas son intento 1 y todas con veredicto), así que **los valores publicados no cambian** — pero el procedimiento habría mentido en cuanto hubiera uno, que es exactamente el escenario que el diseño anticipó y en el que nadie estaría mirando. La corrección es normalizar **antes** de contar:

````sh
# normaliza.awk — una línea por ronda contractual: ciclo, ronda, veredicto terminal, sha.
# Apertura de ciclo: la regla del contrato (la misma de review.sh §status) — un `new` con
# intento 1, o `-` para el INPUT_ERROR pre-invocación. El intento 2 de un retry NO abre ciclo.
# Ronda: solo filas con número de ronda; el desenlace es el ÚLTIMO registro de esa
# (ciclo, ronda), así que un PROC_FAIL previo al veredicto no cuenta como ronda aparte.
# Los eventos pre-invocación (DEADLOCK, INPUT_ERROR) llevan `-` en ronda y quedan fuera.
# El ciclo 0 es el tramo parcial anterior al primer `new` — se inicializa explícito, no por
# coerción de vacío a cero (r3): el esquema de salida promete un número en el campo 1.
# GUARDA DE TOPOLOGÍA, fail-closed (r3): el `rounds-log` es best-effort, así que una fila
# `new` que no llegó a escribirse fusionaría dos ciclos y sobreescribiría sus rondas en
# silencio. Se rechaza lo que es detectable desde el propio log.
function die(msg) { printf "FAIL: línea %d: %s\n", NR, msg > "/dev/stderr"; exit 1 }
BEGIN { FS = "\t"; OFS = "\t"; cyc = 0; prev = 0 }
$2 == "new" && ($4 == "1" || $4 == "-") { cyc++; prev = 0 }
$3 ~ /^[0-9]+$/ {
  cur = $3 + 0
  if (cyc >= 1 && prev == 0 && cur != 1)
    die("el ciclo " cyc " abre en la ronda " cur " y no en la 1")
  if (prev > 0 && cur < prev)
    die("la ronda retrocede de " prev " a " cur " sin frontera de ciclo (¿fila `new` perdida?)")
  if (prev > 0 && cur > prev + 1)
    die("la ronda salta de " prev " a " cur " (¿fila de ronda perdida?)")
  key = cyc SUBSEP cur
  if (!(key in seen)) { seen[key] = 1; order[++n] = key; c[key] = cyc; r[key] = cur }
  v[key] = $5; s[key] = $6
  prev = cur
}
END { for (i = 1; i <= n; i++) { k = order[i]; print c[k], r[k], v[k], s[k] } }
````

**Qué valida la guarda y qué no.** Valida las tres violaciones **detectables desde el log**: que un ciclo abierto por `new` empiece en una ronda distinta de 1; que la ronda retroceda sin frontera (el síntoma de la fila `new` perdida); y que salte más de uno (el síntoma de una fila de ronda perdida). El ciclo `0` queda exento de la primera regla, porque arrancar en la ronda 6 es precisamente lo que le pasa al tramo parcial. Lo que **no** hace es rechazar un ciclo **incompleto**: un ciclo sin `APPROVED` final es un estado legítimo —el ciclo en curso— y aparece como observable pero no cerrado, que es justo la distinción que la tabla de abajo cuenta por separado.

```sh
awk -f normaliza.awk snapshot.tsv > rondas.tsv    # 88 líneas; ciclo 0 = el parcial del arranque
mediana() { sort -n | awk '{a[NR]=$1} END{ if(NR%2) m=a[(NR+1)/2]; else m=(a[NR/2]+a[NR/2+1])/2
             print "n="NR" mediana="m" min="a[1]" peor="a[NR] }'; }
```

**Prueba sintética positiva, corrida** — 9 filas que juntan los seis casos que el log real no tiene (la r3 pidió sumar el prefijo parcial, `NO_VERDICT` y un retry de `round`):

| Fila | Qué caso cubre |
|---|---|
| `round/4/1 CR`, `round/5/1 APPROVED` | **prefijo parcial**: el log arranca a mitad de un ciclo ⇒ ciclo `0` |
| `new/1/1 PROC_FAIL` + `new/1/2 CR` | **retry de `new`**: los dos intentos son `mode=new` y no deben abrir dos ciclos |
| `round/2/1 NO_VERDICT` + `round/2/2 CR` | **retry de `round`** y **«último registro gana»**: la ronda 2 vale `CHANGES_REQUESTED`, no `NO_VERDICT` |
| `round/3/1 APPROVED` | cierre del ciclo 1 |
| `round/-/- DEADLOCK` | **evento pre-invocación**: no es ronda |
| `new/1/1 CR` | **ciclo incompleto**: observable, no cerrado |

| | reductor viejo | normalizador |
|---|---|---|
| ciclos | **3** | **2** observables (más el parcial `0`) |
| veredictos de «r1» | **3**, uno de ellos `PROC_FAIL` | **2**, los dos `CHANGES_REQUESTED` |
| rondas | 9 filas contadas como tales | **6** rondas contractuales |
| ronda (1,2) | dos entradas | una, con `sha=a2` — el retry supera al `NO_VERDICT` |
| ciclos cerrados | no distinguía | **1** de 2 — el incompleto no se rechaza ni se cuenta como cerrado |

**Prueba sintética negativa, corrida** — dos ciclos con la fila `new` del segundo perdida (`new/1`, `round/2 APPROVED`, `round/1`, `round/2 APPROVED`): sin guarda, el normalizador los fusionaba y **sobreescribía en silencio** las rondas 1 y 2 del primero. Con guarda: `rc=1`, `FAIL: línea 3: la ronda retrocede de 2 a 1 sin frontera de ciclo (¿fila `new` perdida?)`.

#### Cifras derivadas, todas sobre `rondas.tsv`

| Cifra | Comando | Valor |
|---|---|---|
| rondas contractuales | `wc -l < rondas.tsv` | **88** |
| `CHANGES_REQUESTED` | `awk -F'\t' '$3=="CHANGES_REQUESTED"{n++} END{print n}' rondas.tsv` | **59** |
| `APPROVED` (**hitos**, no features) | `awk -F'\t' '$3=="APPROVED"{n++} END{print n}' rondas.tsv` | **29** |
| ciclos observables completos | `awk -F'\t' '$1>=1{c[$1]=1} END{print length(c)}' rondas.tsv` | **18** (el ciclo `0` es el parcial del arranque y queda fuera por construcción) |
| …y que los 18 **cerraron** | `awk -F'\t' '$1>=1{l[$1]=$3} END{n=0; for(k in l) if(l[k]=="APPROVED") n++; print n}' rondas.tsv` | **18** — ninguno quedó abierto |
| veredicto de la **r1** de cada ciclo | `awk -F'\t' '$1>=1 && $2==1{print $3}' rondas.tsv \| sort \| uniq -c` | **18 de 18 `CHANGES_REQUESTED`** — cero aprobados en ronda 1 |
| mediana y peor caso por **ciclo** | `awk -F'\t' '$1>=1{n[$1]++} END{for(k in n) print n[k]}' rondas.tsv \| mediana` | `n=18 mediana=4 min=2 peor=11` |
| mediana y peor caso por **hito** | `awk -F'\t' '{n++} $3=="APPROVED"{print n; n=0}' rondas.tsv \| tail -n +2 \| mediana` | `n=28 mediana=3 min=1 peor=5` |
| hitos aprobados sin rechazo en su tramo | `awk -F'\t' '{n++} $3=="APPROVED"{if(n==1) print $4; n=0}' rondas.tsv` | **exactamente 1** (`2dbbdfc`, ciclo 7 ronda 4) |

**El ciclo parcial ya no se descarta a mano**: los conteos por ciclo lo excluyen con `$1>=1`, porque el normalizador le asigna el número `0` a lo que precede al primer `new`. Solo la mediana por hito conserva un `tail -n +2`, y por una razón distinta: el primer hito **sí** empieza dentro del tramo no observado, así que su longitud es desconocida y no hay campo que lo marque. Longitudes por ciclo, para lectura directa: `2 2 2 2 3 3 3 4 4 4 5 5 6 7 7 7 8 11`.

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

**Los tres comandos producen directamente el valor publicado** (corrección de la r2: dos de ellos devolvían un número intermedio que yo traducía a mano — `6` que se volvía 5, y `4` al que le sumaba el `APPROVED`; ese paso manual es justo donde se cuela un error que ningún comando detecta):

| Tramo | Derivación | Valor |
|---|---|---|
| features 00–02, ciclos completos anteriores al log | `git show b0bdf4d:docs/IMPLEMENTATION.md \| grep -E '^\| 0[0-2] \|' \| sed -E 's/.*\(r([0-9]+).*/\1/' \| awk '{s+=$1} END{print s}'` — la tabla del plan registra la **ronda de cierre** de cada feature, que es su cantidad de rondas | **25** (4 + 11 + 10) |
| feature 03, el tramo que quedó fuera del log | `awk -F'\t' 'NR==1{print $3-1}' snapshot.tsv` — el log **arranca en la ronda 6** de un ciclo en curso, así que le faltan las anteriores; el propio snapshot delata el faltante y el `-1` lo convierte en la cifra publicable | **5** |
| ciclo de plan inicial (sin doc en `implementation/`) | `echo $(( $(git log --oneline 6afb57d..3ab6794 \| grep -cE ' plan r[0-9]+:') + 1 ))` — los commits de corrección son uno por ronda que pidió cambios, y el `+1` es la ronda que aprobó y cerró el ciclo en `3ab6794` | **5** |

**Estabilidad del primero, verificada por la r2**: las tres filas `00`–`02` tienen un **único** `(rN)` cada una al corte, así que el `sed` que toma el primero no se apoya en una regularidad accidental. Es una propiedad del snapshot del plan **a ese corte**, no una garantía hacia el futuro, y por eso el comando va anclado con `git show b0bdf4d:`.

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
9. **Links** — lista cerrada, porque la r2 mostró que una estructura laxa dejaba desaparecer links que V3–V5 dicen conservar: `AGENTS.md`, `docs/STATUS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/design/review-contract.md`, `docs/install.md`, y las **dos referencias no activas** (métricas y feedback). Los cuatro primeros son los del baseline y su presencia la verifica C5 vía los tokens; nombrarlos también acá evita que C2 y C5 se contradigan.

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
| C5 | **Cero pérdida, verificada sobre los artefactos y no sobre el mapa**: cada fila V1–V9 / M0–M14 está **realizada** en el `README.md` o el `docs/install.md` finales —se recorre fila por fila localizando el contenido en su destino declarado—, y los **45 tokens** aparecen en la unión, con las 2 traducciones literales de la tabla de placeholders | recorrido fila por fila con locator + `grep` token por token sobre la lista versionada. *Que el mapa esté escrito no verifica su implementación* (r2) |
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

1. **Prosa sin harness.** No hay test que compruebe que un README convence. Mitigación: los criterios son de **verificabilidad**, no de gusto — el contrato editorial convierte «prosa auditable» en una clasificación por oración, y **C3/C13** la hacen revisable (referencia corregida en la r3: la renumeración a C1–C16 había dejado este puntero apuntando a los criterios viejos).
2. **Las cifras se mueven mientras se escribe.** Ya pasó durante la review del delta de diseño. Mitigación: corte declarado, comandos escritos, y la consecuencia (el snapshot no incluye las rondas del 13 y del 14) publicada en vez de escondida.
3. **La mediana que volvió a 4.** Riesgo concreto de que una relectura futura crea que se reintrodujo el error corregido. Mitigación: el aviso explícito de arriba, y la decisión de **no publicar la mediana en el README**.
4. **Traducir mientras se muda puede perder un caso en silencio.** Mitigación: la partición (A)/(B) — lo invariante de idioma se chequea con una lista de **45 tokens** producida por un extractor versionado, y la prosa contra un mapa que cubre las **36 líneas con contenido** del baseline, con la cobertura derivada y no afirmada.
5. **El one-liner probado corre contra el remoto, que está detrás del local.** Mitigación: declarado en §4; el README no afirma nada sobre el contenido no pusheado.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Es una línea y está a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.
7. **«No perder nada» no es «entregar lo diseñado».** Riesgo que la r1 encontró y que no estaba en esta lista: un manual podía pasar C3 y C5 con la mitad del contenido nuevo ausente. Mitigación: C6–C9, que verifican completitud contra listas cerradas —14 secciones, 3 problemas conocidos, el aviso MIT, 6 objeciones— en vez de contra el criterio de quien revisa.
8. **Un procedimiento que verifica su propio enunciado en vez del artefacto.** Es el patrón común de los tres puntos de la r1 y de dos de la r2: el mapa escrito no prueba que el mapa se haya implementado, y un reductor que cuenta filas no prueba que cuente rondas. Mitigación: C5 recorre los artefactos finales fila por fila, el normalizador tiene su prueba sintética con reintento, y la reconstrucción del corte tiene sus cuatro modos de falla probados.

## Review log

### r3 (base `284ace4`, HEAD `528a4e0`) — CHANGES_REQUESTED · 4 puntos, los 4 aceptados

Codex reprodujo por su cuenta las 88 rondas, 59 rechazos, 29 aprobaciones, 18 ciclos cerrados, las medianas y el único hito de longitud 1; también 25/5/5, 212 commits, 3 días y 13 features. Dio por buenos C6–C9, V8, y C5 «verificable sobre los artefactos una vez incorporado `CLAUDE.md`». De las dos dudas que le planteé sobre el normalizador, **descartó una y confirmó la otra con una reproducción**, que es la diferencia entre una opinión y un hallazgo.

1. **El normalizador no emitía el ciclo parcial como `0`.** Al no inicializar `cyc`, las tres primeras filas de `rondas.tsv` salían con el campo 1 **vacío**; las cifras coincidían solo porque awk coerciona vacío a cero. Es decir: el esquema documentado prometía un número y el programa entregaba otra cosa, y la exclusión del parcial quedaba implícita en una coerción. **Aceptado**: `cyc = 0` explícito en `BEGIN`, y el prefijo parcial agregado a la prueba sintética.
2. **La frontera `new` faltante sí merecía guarda** — yo había preguntado si era un estado que el contrato impide, y la respuesta es que no: el `rounds-log` es **best-effort**, así que una escritura fallida puede omitir esa fila. Lo **reprodujo**: con dos ciclos y el segundo `new` perdido, el normalizador los fusionaba y **sobreescribía en silencio** las rondas 1 y 2 del primero. **Aceptado**: guarda fail-closed de la topología detectable —un ciclo abierto por `new` empieza en la ronda 1; después, la ronda repite (retry) o avanza en uno; retroceder o saltar exige otra frontera— con `die()` y prueba negativa. Aceptada también su acotación de que **un ciclo incompleto no debe rechazarse**: la prueba demuestra que aparece observable y no cerrado. Y sumados a la prueba positiva los dos casos que pidió, `NO_VERDICT` y retry de `round`, que fijan «último registro gana».
3. **El extractor todavía omitía una ruta invariante**: `CLAUDE.md` aparece en la línea 50 del baseline **sin backticks ni link**, así que no entraba en los 44 tokens y **C5 podía aprobar la pérdida de la documentación del symlink sembrado**. Tercera clase de contenido invariante que se me escapó, después de los backticks y los links. **Aceptado**: regla 4 —paths desnudos sobre el residuo de la línea, quitando lo ya capturado y las URLs— ⇒ **45 tokens**, lista y conteo regenerados (y verificado que la lista publicada es idéntica byte a byte a la salida del extractor), y M10 pasa a nombrar `AGENTS.md` + symlink `CLAUDE.md` explícitamente.
4. **`STATUS.md` seguía fechado `2026-07-29`** con el commit bajo review del `2026-07-30`. **Aceptado**, corregido.

### r2 (base `284ace4`, HEAD `4f2a310`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

Codex dio por cerradas las correcciones de la r1 y lo verificó ejecutando: el recorte rechaza ausente, duplicado y vacío, y reconstruye 88 filas desde el log vivo que ya tiene 89; el mapa cubre exactamente las 36 líneas con contenido, sin huecos ni duplicados; C6–C9 cierran el hueco de completitud; V8 como sección completa del manual es la resolución correcta; 25/5/5 cierran; y el alcance tocó solo los dos docs. Descartó además la postcondición de orden que yo había ofrecido —el log es append-only en producción y el 14 cruza la historia igual—, así que **no** se agrega. Dos de los tres puntos nuevos son el mismo patrón que la r1, un nivel más adentro: **el procedimiento verificaba su propio enunciado en vez del artefacto**.

1. **Los reductores contaban filas e intentos, no rondas contractuales.** El punto más serio de las dos rondas, y lo **reprodujo sintéticamente** en vez de razonarlo: durante un reintento, el intento 1 y el 2 conservan los dos `mode=new`, así que mi `$2=="new"` abría **dos ciclos y dos «r1»** —una con veredicto `PROC_FAIL`, que no es un veredicto— y las longitudes por ciclo y por hito, que incrementaban **por fila**, se inflaban con cada `PROC_FAIL`. Su caso de un solo ciclo con retry salía como 2 ciclos, 2 r1 y 4 rondas. El log de hoy no tiene reintentos, así que **ninguna cifra publicada cambia** — pero el procedimiento habría mentido exactamente en el escenario que el diseño anticipó y que nadie estaría mirando. **Aceptado sin argumentar**: se normaliza **antes** de contar, con `normaliza.awk` — apertura de ciclo por la regla del contrato (`new` con intento `1` o `-`), una línea por `(ciclo, ronda)` y desenlace **terminal** de cada ronda —, y los ocho reductores pasan a correr sobre `rondas.tsv`. Agregada la **prueba sintética** con `PROC_FAIL → resultado` y evento pre-invocación, con la tabla viejo-contra-nuevo. Beneficio colateral: el ciclo parcial ya no se descarta con un `tail -n +2` a mano, porque el normalizador le asigna el ciclo `0` y los conteos lo excluyen con `$1>=1`. En el mismo punto pidió que las derivaciones históricas **produzcan el valor publicado**: la de feature 03 devolvía `6` y yo lo traducía a 5, la del plan devolvía `4` y yo le sumaba el `APPROVED`. **Aceptado**: `awk 'NR==1{print $3-1}'` y `$(( … + 1 ))`. Confirmó que el 25 de las filas 00–02 es estable al corte porque las tres tienen un único `(rN)`.
2. **C5 todavía podía aprobar una pérdida real.** El extractor no extraía **destinos de links markdown**, así que `AGENTS.md`, `docs/STATUS.md`, `docs/DESIGN.md` y `docs/IMPLEMENTATION.md` —que en el baseline aparecen solo como link— no estaban entre los tokens; y como la estructura de §9 solo exigía diseño, contrato, plan y las referencias futuras, los cuatro podían desaparecer del README y pasar **C2, C5 y C10** sin que nada lo marcara, aunque V3–V5 dijeran «conservado». **Aceptado**: regla 3 en el extractor (`](…)`) ⇒ **44 tokens**; §9 pasa a lista cerrada que los nombra; y —el punto más fino— **C5 se reescribe para contrastar los artefactos finales**, recorriendo fila por fila del mapa con locator, porque *que el mapa esté escrito no verifica su implementación*. Aceptada también la objeción a las dos excepciones de placeholder: «comando equivalente» devolvía el chequeo al juicio, así que ahora hay **traducción literal esperada** en tabla, y cualquier otra es un fallo de C5.
3. **Dos correcciones documentales.** El riesgo 1 seguía apuntando a «C3/C9» tras la renumeración a C1–C16 (va a **C3/C13**), y la lista de riesgos había quedado ordenada `1,2,3,4,7,5,6`. **Aceptadas las dos**; y se suma el riesgo **8**, que nombra el patrón común de estas dos rondas para que no haya que redescubrirlo en la implementación.

### r1 (base `284ace4`, HEAD `1c34281`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

Codex verificó por su cuenta y dio por buenas **todas las cifras declaradas** —incluida la mediana 4—, los cinco hitos del transcript, la evidencia de inquirylab, que las referencias pendientes al 14 cumplen el contrato, que P1–P4 reproducen RC 2/2/1/0 con el remoto en `88020af`, y el alcance limitado a los cuatro docs autorizados; más `lint.sh` limpio, `loop.sh` 287/0 e `install.sh` 460/0. También dio por adecuada la mitigación de la mediana (no publicarla en el README y explicarla en el informe del 14). Los tres puntos son **bloqueantes de método, no de dato**: ninguno movió una cifra, y los tres apuntan al mismo defecto de fondo — yo verifiqué a mano y escribí el resultado, en vez de dejar escrito un procedimiento que falle solo cuando el resultado sea otro.

1. **El corte no se reconstruía fail-closed.** Cierto y era el peor de los tres: el `awk` que publiqué (`{print} $6=="b0bdf4d"{exit}`) **imprime el archivo entero y sale con éxito** si el SHA no está, y no rechaza duplicados — falla abierto exactamente en el caso que existe para detectar. Y con él venían cuatro derivados: los comandos de métricas **no nombraban su input**; el conteo de features consultaba el `IMPLEMENTATION.md` vivo, que **habría devuelto 14 en cuanto cierre este feature**; las derivaciones del copyright citaban 212 commits pero corrían `git log` sin revisión sobre un `HEAD` que ya tiene 216; y faltaban comandos para las medianas, los tramos por hito y las 35 rondas históricas que C4 promete re-derivar. **Aceptado entero, sin argumentar nada.** Reescrita la reconstrucción con `hit != 1 ⇒ exit 1` y **probados los cuatro modos de falla** (corte único, ausente, duplicado, log vacío); `snapshot.tsv` pasa a ser el input explícito de toda la tabla; los comandos de gancho y de copyright quedan anclados a `b0bdf4d` (`git show b0bdf4d:docs/IMPLEMENTATION.md`, `git log b0bdf4d …`); se agregan el reductor `mediana()` y las **tres** derivaciones de las 35 históricas (25 de la tabla del plan al corte, 5 que el propio snapshot delata al arrancar en la ronda 6, 5 del ciclo de plan acotado por rango de commits). Adoptada también su formulación pública: **«13 closed features (00–12, including bootstrap)»**. Corolario que salió de acá: entre la bajada y esta corrección el `rounds-log` pasó de 88 a **89** filas por la review r1 de este mismo feature, y la reconstrucción al corte siguió dando 88 — el hallazgo 3 del diseño ocurriendo por segunda vez, ahora sobre el feature que publica las cifras.
2. **C1–C12 no alcanzaban para garantizar el entregable diseñado.** Cierto: C3 valida solo las oraciones **presentes** y C5 excluía explícitamente el contenido nuevo, así que un `docs/install.md` sin dos de los tres known issues, sin §After an adoption, sin el aviso MIT o sin contestar las seis objeciones **aprobaba igual**. Es el hueco entre «no perder nada» y «entregar lo diseñado». **Aceptado**: se agregan **C6–C9**, que verifican completitud contra listas cerradas (14 secciones del manual, 3 problemas conocidos con su ubicación, el aviso MIT como incumplimiento pendiente, las 6 objeciones con su locator), y los criterios se renumeran a C1–C16. Aceptado también el segundo hallazgo del punto, que es de diseño y no de criterio: el diseño enumera **«uso»** dentro del dominio operativo donde el manual debe ser el completo, y yo introducía la tabla de comandos en el README §6 sin contraparte. Se agrega **§The commands in full** al manual, con el README como extracto; queda como fila **V8** del mapa, con su justificación escrita para que no se lea como duplicación caprichosa.
3. **La mitad mecánica de «cero pérdida» seguía dependiendo del juicio del ejecutor.** Cierto: «un extractor de tokens» sin algoritmo ni lista cerrada permite omitir un token al seleccionarlos y obtener «cero faltantes». Y el mapa contabilizaba la línea 18 y el bloque 22–69 pero **dejaba 1–17 afuera**, incluyendo la entrada de uso y las descripciones de comandos — que es justo donde estaba el problema del punto 2. **Aceptado**: baseline fijado en `284ace4:README.md`; extractor escrito como `awk` reproducible y **su salida de 40 tokens versionada literalmente** en el doc; mapa extendido a **V1–V9 + M0–M14**, con disposición declarada por tramo (mudado / conservado / partido / reemplazado a propósito) y **cobertura derivada**: 33 líneas sin contenido (23 en blanco + 10 delimitadores de fence, ambas enumeradas por comando) y 36 con contenido, todas mapeadas, sin huecos ni solapamientos. Declaradas además las 2 excepciones de la lista de tokens (placeholders en español que la traducción cambia), para que no se resuelvan por criterio del momento.
