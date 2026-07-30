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
2. **Tres** tokens llevan **placeholders en español** que la traducción cambia. La r2 objetó —con razón— que resolverlos como «que exista el comando equivalente» devuelve el chequeo al juicio del ejecutor. Se fija la **traducción literal esperada**, de modo que sigan siendo igualdad exacta de cadena contra un valor declarado de antemano y no una apreciación:

   | Token del baseline | Cadena exacta esperada en la unión |
   |---|---|
   | `bash -s -- --from <url-del-fork> <destino>` | `bash -s -- --from <fork-url> <destination>` |
   | `scripts/install.sh /path/al/repo-destino` | `scripts/install.sh /path/to/target-repo` |
   | `curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh \| bash -s -- --from https://github.com/alexweil/axel <repo-destino>` | `curl -fsSL https://raw.githubusercontent.com/alexweil/axel/main/scripts/install.sh \| bash -s -- --from https://github.com/alexweil/axel <destination>` |

   La tercera fila la agregó la **r6**: el token largo de la forma explícita también lleva un
   placeholder en español, y como el resto de la cadena es idéntica el `grep` de C5 pasaba con
   `<repo-destino>` intacto — o sea, «cero pérdida» y la política de idioma se contradecían y el
   conflicto se estaba resolviendo a mano, sin quedar escrito. Con la fila, la sustitución es
   obligatoria y verificable.

   Las dos cadenas de la tercera fila van **completas y sin abreviar**, porque el encabezado promete cadenas exactas y un `…` no se puede comparar (corrección de la r7). Cualquier otra traducción de los tres es un fallo de C5, no una variante aceptable. Si al escribir el manual conviniera otra forma, se cambia **esta tabla primero** y queda registrado en el Review log.

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
function die(msg) { printf "FAIL: línea %d: %s\n", NR, msg > "/dev/stderr"; failed = 1; exit 1 }
BEGIN { FS = "\t"; OFS = "\t"; cyc = 0; prev = 0; failed = 0 }
$2 == "new" && ($4 == "1" || $4 == "-") { cyc++; prev = 0 }
$3 ~ /^[0-9]+$/ {
  cur = $3 + 0; att = $4 + 0
  if (cyc >= 1 && prev == 0 && cur != 1)
    die("el ciclo " cyc " abre en la ronda " cur " y no en la 1")
  if (prev > 0 && cur < prev)
    die("la ronda retrocede de " prev " a " cur " sin frontera de ciclo (¿fila `new` perdida?)")
  if (prev > 0 && cur > prev + 1)
    die("la ronda salta de " prev " a " cur " (¿fila de ronda perdida?)")
  if (prev > 0 && cur == prev) {          # una ronda solo se repite por retry, y el retry
    if (pverd != "PROC_FAIL" || $2 != pmode || $6 != psha || att != patt + 1)
      die("la ronda " cur " se repite sin ser un retry válido (exige intento " patt + 1 \
          " tras un PROC_FAIL del mismo modo y SHA; vino intento " att " tras " pverd \
          " modo " $2 " sha " $6 ")")
  }
  key = cyc SUBSEP cur
  if (!(key in seen)) { seen[key] = 1; order[++n] = key; c[key] = cyc; r[key] = cur }
  v[key] = $5; s[key] = $6
  prev = cur; patt = att; pverd = $5; pmode = $2; psha = $6
}
END { if (failed) exit 1        # fail-closed de verdad: ante rechazo no se emite NADA (r4),
      for (i = 1; i <= n; i++)  # porque `exit` en una regla igual pasa por END y dejaba un
        { k = order[i]; print c[k], r[k], v[k], s[k] } }   # artefacto parcial consumible
````

```sh
awk -f normaliza.awk snapshot.tsv > rondas.tsv   # rc DEBE ser 0: es postcondición, no cortesía
```

**Qué valida la guarda y qué no.** Valida las **cuatro** violaciones detectables desde el log: que un ciclo abierto por `new` empiece en una ronda distinta de 1; que la ronda retroceda sin frontera (síntoma de la fila `new` perdida); que salte más de uno (síntoma de una fila de ronda perdida); y —la que agregó la r4— que una ronda **se repita sin ser un retry válido**. El ciclo `0` queda exento de la primera regla, porque arrancar en la ronda 6 es precisamente lo que le pasa al tramo parcial.

**La gramática del retry, que es lo que cierra el último agujero.** Yo mismo había preguntado por el caso de dos ciclos de una sola ronda con el `new` del segundo perdido: ahí no hay retroceso ni salto, así que las tres guardas anteriores lo dejaban pasar y el normalizador **sobreescribía un `APPROVED`** en silencio. Codex lo reprodujo (`new/1/1 APPROVED` → `round/1/1 CHANGES_REQUESTED` daba `rc=0`) y señaló que **sí** es detectable, porque una ronda repetida solo es legítima si es un reintento, y un reintento tiene forma fija: mismo número de ronda, **mismo modo**, **mismo SHA**, intento que **incrementa**, y verdicto anterior **`PROC_FAIL`**. Dos filas con `attempt=1` no son eso. Verificado contra `scripts/review.sh` antes de implementarlo: las filas `PROC_FAIL` **sí llevan el SHA** (`log_event PROC_FAIL "$ROUND" "$ATTEMPT" "$REVIEW_HEAD_SHORT"`), así que la identidad de SHA es chequeable y no hubo que debilitar la regla.

Lo que la guarda **no** hace es rechazar un ciclo **incompleto**: un ciclo sin `APPROVED` final es un estado legítimo —el ciclo en curso— y aparece como observable pero no cerrado, que es justo la distinción que la tabla de abajo cuenta por separado.

```sh
awk -f normaliza.awk snapshot.tsv > rondas.tsv    # 88 líneas; ciclo 0 = el parcial del arranque
mediana() { sort -n | awk '{a[NR]=$1} END{ if(NR%2) m=a[(NR+1)/2]; else m=(a[NR/2]+a[NR/2+1])/2
             print "n="NR" mediana="m" min="a[1]" peor="a[NR] }'; }
```

**Prueba sintética positiva, corrida** — 10 filas crudas que juntan los siete casos que el log real no tiene:

| Fila(s) | Qué caso cubre |
|---|---|
| `round/4/1 CR p1`, `round/5/1 APPROVED p2` | **prefijo parcial**: el log arranca a mitad de un ciclo ⇒ ciclo `0` |
| `new/1/1 PROC_FAIL a1` + `new/1/2 CR a1` | **retry de `new`**: los dos intentos son `mode=new` y no deben abrir dos ciclos |
| `round/2/1 NO_VERDICT a2` | **veredicto inválido como desenlace propio**: `review.sh` **no lo reintenta**, así que es la ronda entera y el ciclo sigue en la ronda 3 (corrección de la r4: mi fixture anterior lo usaba como si se reintentara, que es un estado que la maquinaria no produce) |
| `round/3/1 PROC_FAIL a3` + `round/3/2 CR a3` | **retry de `round`** y **«último registro gana»**: la ronda 3 vale `CHANGES_REQUESTED` |
| `round/4/1 APPROVED a4` | cierre del ciclo 1 |
| `round/-/- DEADLOCK` | **evento pre-invocación**: no es ronda |
| `new/1/1 CR b1` | **ciclo incompleto**: observable, no cerrado |

| | reductor viejo | normalizador |
|---|---|---|
| ciclos | **3** | **2** observables (más el parcial `0`) |
| veredictos de «r1» | **3**, uno de ellos `PROC_FAIL` | **2**, los dos `CHANGES_REQUESTED` |
| rondas | 10 filas contadas como tales | **7** rondas contractuales |
| ronda (1,3) | dos entradas | una, con `sha=a3` — el retry supera al `PROC_FAIL` |
| ronda (1,2) | — | `NO_VERDICT`, que es una ronda pero **ni rechazo ni aprobación** |
| ciclos cerrados | no distinguía | **1** de 2 — el incompleto no se rechaza ni se cuenta como cerrado |

**Dos pruebas sintéticas negativas, corridas**, y ninguna emite una sola fila:

| Caso | Resultado |
|---|---|
| dos ciclos con el `new` del segundo perdido (`new/1`, `round/2 APPROVED`, `round/1`, `round/2 APPROVED`) — sin guarda, el normalizador los fusionaba y sobreescribía las rondas 1 y 2 del primero | `rc=1`, `FAIL: línea 3: la ronda retrocede de 2 a 1 sin frontera de ciclo…`, **0 filas emitidas** |
| **dos ciclos de una sola ronda** con el `new` perdido (`new/1/1 APPROVED x1`, `round/1/1 CR x2`) — el caso que las tres guardas anteriores dejaban pasar, porque no hay retroceso ni salto | `rc=1`, `FAIL: línea 2: la ronda 1 se repite sin ser un retry válido (exige intento 2 tras un PROC_FAIL del mismo modo y SHA; vino intento 1 tras APPROVED modo round sha x2)`, **0 filas emitidas** |

**«0 filas emitidas» es parte de la prueba, no una observación al pasar** (r4): `exit` dentro de una regla de awk **igual pasa por `END`**, así que la versión anterior rechazaba el input con `rc=1` y a la vez dejaba un `rondas.tsv` parcial de dos filas, perfectamente consumible por el comando siguiente. Un normalizador fail-closed no puede dejar un artefacto detrás de un rechazo: de ahí la bandera `failed` y el `rc=0` como postcondición declarada de la invocación.

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
14. **Language** — agregada durante la implementación, y se declara acá para que C6 no quede desincronizado de su artefacto (que es el defecto que este doc viene persiguiendo). Razón: la objeción «está todo en español» de §8 del README necesita aterrizar en algún lado, y el destino natural es el manual — el README declara la política en una línea y el manual la explica en sus tres planos. Sin esta sección, ese puntero sería el único caso del README que apunta a nada
15. Tests

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
| C5 | **Cero pérdida, verificada sobre los artefactos y no sobre el mapa**: cada fila V1–V9 / M0–M14 está **realizada** en el `README.md` o el `docs/install.md` finales —se recorre fila por fila localizando el contenido en su destino declarado—, y los **45 tokens** aparecen en la unión, con las **3** traducciones literales de la tabla de placeholders | recorrido fila por fila con locator + `grep` token por token sobre la lista versionada. *Que el mapa esté escrito no verifica su implementación* (r2) |
| **C6** | **Completitud del manual**: existen y tienen contenido las **15 secciones** de la lista cerrada de §Enfoque, incluida §The commands in full con los **siete** comandos | recorrido de la lista, una por una |
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
7. **«No perder nada» no es «entregar lo diseñado».** Riesgo que la r1 encontró y que no estaba en esta lista: un manual podía pasar C3 y C5 con la mitad del contenido nuevo ausente. Mitigación: C6–C9, que verifican completitud contra listas cerradas —**15** secciones, 3 problemas conocidos, el aviso MIT, 6 objeciones— en vez de contra el criterio de quien revisa. (El «14» que decía acá era el conteo de la bajada; §Language entró durante la implementación y C6 se actualizó, pero esta mitigación había quedado atrás. Las menciones de 14 dentro del Review log **se conservan**: describen el estado de su ronda.)
8. **Un procedimiento que verifica su propio enunciado en vez del artefacto.** Es el patrón común de los tres puntos de la r1 y de dos de la r2: el mapa escrito no prueba que el mapa se haya implementado, y un reductor que cuenta filas no prueba que cuente rondas. Mitigación: C5 recorre los artefactos finales fila por fila, el normalizador tiene su prueba sintética con reintento, y la reconstrucción del corte tiene sus cuatro modos de falla probados.

## Verificación del cierre

Los tres artefactos existen. Tamaños **medidos con `wc -l` / `wc -c` sobre el commit de cierre de esta ronda**, y rotulados en **bytes** —no en «caracteres», que es como los llamé mal hasta la r7—:

| Artefacto | Líneas | Bytes |
|---|---|---|
| `LICENSE` | 21 | 1 065 |
| `README.md` | 183 | 10 989 |
| `docs/install.md` | 374 | 21 148 |

Evidencia por criterio.

**C1 — `LICENSE`.** MIT estándar, sin modificar, `Copyright (c) 2026 alexweil`, con las dos derivaciones ancladas de §1 corridas al corte.

**C2 — estructura del README.** Las nueve secciones, en el orden aprobado y con los requisitos **antes** del comando: título+cifras (§1, sin encabezado), `The problem`, `What a session actually looks like`, `Requirements, honestly`, `Install`, `The commands`, `How it works`, `What this is not`, `Links`. Verificado con `grep -n '^## ' README.md`.

**Desvío de tamaño, declarado.** El objetivo era «~120 líneas» y el resultado son **183**. No es inflado: es un cambio de unidad de medida que la bajada no anticipó. El baseline tiene 69 líneas **sin wrappear**, con líneas de hasta **1070 bytes**; el README nuevo está wrappeado a ~100, y su línea más larga es de **338 bytes**. Comparado por **bytes** —`wc -c`, que es lo reproducible; la r7 marcó que yo los llamaba «caracteres», y en UTF-8 no son lo mismo: el baseline da 7971 caracteres Unicode contra 8142 bytes—, pasa de **8142** a **10 989** bytes — **+35.0 %**, derivado con las mismas magnitudes de la tabla y no estimado a ojo (la r8 marcó que mi «30 %» había envejecido al crecer el README), cargando además todo lo que el viejo no tenía (posicionamiento, transcript bilingüe, requisitos, seis objeciones) y habiendo mudado 50 líneas de casuística al manual. La vara del diseño no es de líneas sino de pantallas —«si el lector tiene que scrollear más de una pantalla para saber si esto es para él, el corte falló»—, y el gancho, las tres cifras y `The problem` entran en la primera.

**C3 — cero afirmación no verificable.** Pasada por oración sobre los dos artefactos, clasificando cada una en las tres clases del contrato editorial. Los casos que no son trivialmente «hecho derivable»:

| Afirmación | Clase | Sustento |
|---|---|---|
| «88 logged review rounds · 59 rejections · zero first-round approvals», «29 approvals», «123», «35», «23 cycles» | hecho derivable | comandos de §«El corte de métricas», corte `b0bdf4d` |
| «185 commits», «20 files», «8 files» de la prueba externa | hecho derivable | commits `846308f`, `4908bfb`, `98c70c0`, verificados en ese repo |
| «a round can take more than 10 minutes» | **limitación declarada** | `AGENTS.md` §Convenciones; no se publica como cifra medida |
| «closing the lid still sleeps the machine, unless it is on power *and* driving an external display» | **limitación declarada** | `AGENTS.md` §Convenciones, «límite físico» |
| «two subscriptions, from two different vendors» | hecho derivable | `scripts/review.sh` invoca `codex`; la sesión es Claude Code |
| «two things are known to degrade cleanly» fuera de macOS, y **nada más** | hecho derivable | `scripts/awake.sh` imprime `caffeinate no disponible (no es macOS): nada que hacer` y retorna sin error; `review.sh` llama a `codex` sin envolver. **Corregido en la r6**: yo había escrito «everything else works» y «portable shell», que esas dos ramas **no** demuestran. Ahora dice que el resto está *untested*, no *supported* |
| «GitHub's Python and Gradle templates both do» (ignorar `build/`) | hecho derivable, **con evidencia fail-closed** | verificado el 2026-07-30 corriendo `git check-ignore -v .claude/skills/build/SKILL.md` contra cada template. **Corregido dos veces**: en la r6 cayó la versión del pedido —«every Python, Node, Java, Gradle, Maven and C template»—, y en la **r7** cayó mi propia corrección, que decía «solo Python». **Gradle sí ignora**, con `**/build/`, y mi verificación de la r6 no lo vio porque grepeé un patrón que no cubría `**/`. Node tiene `build/Release`, que no matchea; Java, C, Maven, Go y Rust no tienen regla que matchee. **Tercera corrección, en la r9**: el script que publiqué como evidencia **fallaba abierto** — sin guarda en el `curl`, una descarga fallida dejaba el template anterior en `.gitignore` y el loop atribuía ese resultado al siguiente. Reproducido con un SHA inválido: `curl` devolvió 56 y el script informó que **Node** ignora `build/`, que es la regla de Python, saliendo 0. Ahora lleva `set -euo pipefail`, `rm -f .gitignore` por iteración y descarga-a-temporal-y-`mv`, sobre un `mktemp -d`: una falla de transporte o un template ausente **abortan** en vez de producir una matriz verosímil. Verificado el camino feliz (Python y Gradle ignoran, seis negativos, `rc=0`) y el de falla (`rc=1`, `FAIL: could not fetch …`), corriendo el script **tal como queda publicado** |
| «una sesión reconstruye leyendo **cuatro** archivos» | hecho derivable | `AGENTS.md` §«Cómo ubicarte rápido» enumera cuatro. **Corregido en la r6**: decía tres |
| «readable in an afternoon», «that is the point, not an apology», «expensive and unhurried on purpose» | **opinión marcada** | van en «What this is not», que es la sección declarada de juicio |
| «the worst thing we could do» (sobre publicar un chat reconstruido) | **opinión marcada** | argumento del diseño, presentado como tal |
| «Not fixed in this pipeline», y sin entrada de backlog | **limitación declarada** | **Corregido en la r6**: yo había escrito «This will be fixed», que no es una limitación sino una **promesa a futuro sin feature ni backlog que la respalde** — y contradice de frente la decisión registrada en [public-surface.md](../design/public-surface.md) §«Los tres puntos de fricción», que dejó esos arreglos afuera **y sin registrar**. La vidriera no puede prometer en nombre de un plan que no existe |
| «not partial compliance, an open gap» (aviso MIT) | **limitación declarada** | exigido literalmente por el diseño |

**C4 — cifras con corte y comando.** Re-derivadas con la reconstrucción fail-closed y el normalizador: snapshot **88**, rondas **88**, `CHANGES_REQUESTED` **59**, hitos **29**, ciclos **18**, cerrados **18**, r1 **18/18 `CHANGES_REQUESTED`**. Históricas **25+5+5 = 35** ⇒ **123**. Gancho: **212** commits, **3** días, **13** features al corte. El README publica el corte `b0bdf4d` en la propia línea de las cifras. Los **23 ciclos** de «What this is not» son los 18 del log más los 5 previos a la instrumentación.

**C5 — cero pérdida, contra los artefactos.**

- *(A) Tokens*: los **45** aparecen en la unión `README.md` + `docs/install.md`. **0 faltantes**, con las **tres** traducciones literales declaradas sustituidas según la tabla.
- *(B) Mapa, fila por fila, con locator en el artefacto final*:

| Fila | Realizada en |
|---|---|
| V1, V2 | README §1 (título, una línea de posicionamiento, las tres cifras) |
| V3, V4, V5 | README §Links (`AGENTS.md`, `docs/STATUS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`) |
| V6, V7 | README §The commands: el encabezado, y la línea de entrada «Open Claude Code in the repo and use any of these», **agregada en la r6** — el mapa la daba por conservada y no estaba en el artefacto |
| V8 | README §The commands (tabla de 7) **y** manual §The commands in full (tabla completa con cuándo y precondición) |
| V9 | README §How it works (loop y RECAP) **y** manual §Requirements — macOS, `caffeinate`, `scripts/awake.sh`, más el párrafo de la **tapa cerrada** (necesita corriente y display externo), **agregado en la r6**: el mapa lo exigía y no estaba en ningún artefacto |
| M0 | manual, título y encabezado |
| M1 | manual §Install → *Quick install* |
| M2 | manual §Install → *What the defaults assume*, con las tres líneas de anuncio reales |
| M3 | manual §Install → *Explicit form* |
| M4 | manual §Did it actually run? |
| M5 | manual §Did it actually run? (bloque `pipefail`) |
| M6 | manual §If you installed into the wrong repo |
| M7 | manual §Install → *The `~/.axel` cache* (el cache, `AXEL_HOME`, el manejo fail-closed) **y** *From a local clone* (que el modo local no usa red) — locator corregido en la r6: el contenido está completo, pero repartido en dos secciones y yo había publicado una sola |
| M8 | manual §Install → *From a local clone* |
| M9 | manual §Install → *Forks* |
| M10 | manual §What gets installed (con `AGENTS.md` + symlink `CLAUDE.md` nombrados), §The three modes y §Exit codes |
| M11, M12 | manual §For agents (Claude Code), los cinco pasos |
| M13, M14 | manual §Audit before you run |

**C6 — completitud del manual.** Las **15** secciones presentes y con contenido; §The commands in full lista los **siete** comandos.

**C7 — los tres problemas conocidos, cada uno donde el diseño manda.** (1) Colisión `build/` en §Known issues, con el rechazo literal **probado** en P1, el workaround y la trampa de `!.claude/` explicada con la evidencia de `git check-ignore -v`; más el puntero de una línea desde el README §Install. (2) Rechazo por árbol sucio en §Known issues, con la nota de `git stash -u`. (3) `modo: initial` en una adopción en §After an adoption, que es donde se choca, con §Known issues 3 apuntando ahí.

**C8 — aviso MIT.** §License notice dice literalmente que un puntero que no viaja con el payload no es el aviso que tiene que viajar con el payload, y lo rotula «**not partial compliance, an open gap**».

**C9 — las seis objeciones, con locator.**

| Objeción | Dónde |
|---|---|
| cuesta una fortuna | §Requirements, primer ítem, **antes** del comando de instalación |
| el reviewer es otro LLM | §1 (las cifras) y §What this is not, último ítem |
| es un montón de markdown | §What this is not, primer ítem |
| está todo en español | §What a session (transcript bilingüe, que lo muestra) y §What this is not, quinto ítem |
| macOS only | §Requirements, segundo ítem — qué se rompe y qué no |
| ¿funciona fuera de axel? | §What a session → *Does it work outside axel?*, con el alcance honesto |

**C10 — cero link roto.** Todos los destinos relativos de los dos artefactos resuelven, y las **siete anclas internas** usadas (`#known-issues`, `#language`, `#the-commands-in-full`, `#exit-codes`, `#after-an-adoption`, `#1-the-build-collision`, `#3-the-announced-mode-can-be-wrong`) corresponden a encabezados reales del manual, verificado derivando el slug de cada encabezado.

**C11 — las dos referencias del 14, sin linkear y marcadas.** El bloque `> **Coming in feature 14, and deliberately not linked yet:**` al pie de §Links nombra en prosa el doc de métricas y `CONTRIBUTING.md`, y la línea de cifras de §1 lleva su propia marca. Ninguna de las dos es un link.

**C12 — one-liner y workaround probados.** Publicados exactamente como salieron de P1–P4, incluida la línea final real del rechazo (`── axel · fin: rc=2 · rechazo del preflight (1 problema(s), nada escrito) ──`), que no es la que traía el pedido.

**C13 — transcript sin línea inventada.** Los cinco hitos citados en su idioma original con su fuente, y las citas **comparadas mecánicamente** contra el original —normalizando espacios y marcas de énfasis— en vez de leídas a ojo:

| Hito | Fuente | Cita idéntica al original |
|---|---|---|
| pedido sin comando | bloque Gate de `pipeline-2026-07-29-2.md` | sí |
| gate y autorización | evento de autorización del mismo ledger | sí |
| `CHANGES_REQUESTED` verdadero | §Review log r1, punto 2, de `12-adopt-close-report.md` | sí |
| corrección → `APPROVED` | `f85a033` (r2) y `886fe4f` (r7) | SHAs verificados con `git cat-file -e` |
| RECAP → OK | `eabd92f` (STATUS a «esperando OK») y `39b377e` (registro del OK), literal «OK» en §Cierre del ledger | SHAs verificados |

Los ocho SHA citados en el README existen: los cinco de axel con `git cat-file -e`, y los tres de la prueba externa (`846308f`, `4908bfb`, `98c70c0`) contra ese repo. El README **no** cita la frase con que el ledger enmarca el OK, solo el literal del humano.

**C16 — no-regresión.** `tests/lint.sh` **limpio** (shellcheck 0.11.0), `tests/loop.sh` **293 ok · 0 fail**, `tests/install.sh` **460 ok · 0 fail**. Es no-regresión pura: el delta no toca scripts ni tests. El reviewer obtuvo **287** en `loop.sh` por la causa conocida —su sandbox saltea los seis asserts del smoke no contractual de `caffeinate`—, no por una divergencia.

**C14 — alcance, verificado fail-closed contra una lista cerrada.** Tercera versión de este criterio, y las dos anteriores fallaron por la misma razón de fondo: **la evidencia se apoyaba en algo que se mueve**. La primera publicaba «seis archivos, un commit del padre» y envejeció cuando el padre commiteó al ledger. La segunda —r11— particionaba por «toca el ledger o no» y afirmaba no depender de mensajes de commit, pero su cuarto comando decidía la autoría con `grep -c '^feature 13'`: leía el mensaje, se contradecía con su propia afirmación, **habría reclasificado como «del padre» un commit del hijo sobre el ledger con otro asunto** —dando 0 igual— y encima ese `grep -c` imprime 0 con `rc=1`.

La salida estable, que es la que señaló la r11: **comparar el conjunto de commits que tocan el ledger contra una lista cerrada de los SHA autorizados del padre** — hoy **siete**. Esa lista no envejece con commits nuevos del hijo, y **un octavo** commit sobre el ledger falla **sea cual sea su mensaje o su autoría declarada**. (La r11 la propuso cuando eran cinco; el número es el **estado de la lista**, no una propiedad del criterio, y por eso se mueve sin que el criterio cambie.)

```sh
#!/usr/bin/env bash
set -euo pipefail
L=docs/implementation/pipeline-2026-07-29-3.md
R=284ace4..HEAD
# Lista CERRADA de los commits del padre autorizados a tocar el ledger.
AUTORIZADOS="ee1e8ca 10e8f1f a0e9fa8 49ceb0b 573814d f6fce39 a24abac"

esperado=$(for c in $AUTORIZADOS; do git rev-parse "$c"; done | sort)
observado=$(git log --format=%H "$R" -- "$L" | sort)
if [ "$esperado" != "$observado" ]; then
  echo "FAIL: commits sobre el ledger fuera del conjunto autorizado" >&2
  diff <(printf '%s\n' "$esperado") <(printf '%s\n' "$observado") >&2 || true
  exit 1
fi

git log --format= --name-only "$R" | grep -v '^$' | sort -u                    # 7 paths
git log --format=%H "$R" | grep -vxF "$esperado" | while read -r c; do         # los del hijo:
  git show --format= --name-only "$c"; done | grep -v '^$' | sort -u           # el rango menos la lista
```

| Comprobación | Resultado |
|---|---|
| el conjunto que toca el ledger **es** el autorizado | **sí**, **siete** — `ee1e8ca` (arranque), `10e8f1f` y `a0e9fa8` (anomalías del id), `49ceb0b` (corte), `573814d` (desempate), `f6fce39` (corrección del conteo) y `a24abac` (compromiso reenunciado como regla) |
| paths del rango completo | **7**: `LICENSE`, `README.md`, `docs/install.md`, `docs/implementation/13-public-showcase.md`, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` y el ledger |
| paths de los commits del hijo (rango **menos la lista cerrada**, sin definición circular) | **6** — el ledger **no** aparece |
| qué tocan los del padre | solo el ledger y `docs/STATUS.md`, los dos territorio suyo |
| **la lista creció dos veces, y ese es el mecanismo funcionando** | el sexto y el séptimo SHA entraron **porque el padre corrigió falsedades vigentes en el ledger**: sin la lista cerrada esos commits habrían pasado inadvertidos; con ella, cada uno obligó a una actualización explícita y verificable |
| **la regla que gobierna el crecimiento** | el padre no commitea al ledger durante el ciclo **salvo para corregir una falsedad vigente**, y en ese caso el SHA entra a `AUTORIZADOS` en la misma ronda (`a24abac`). Un compromiso absoluto estaba mal enunciado, porque dejar en pie una falsedad conocida no es una opción disponible |

**Los dos caminos probados**, no argumentados: con la lista completa ⇒ `rc=0` y las dos listas de paths; sacando un SHA de la lista para simular un commit no autorizado ⇒ `rc=1`, `FAIL: commits sobre el ledger fuera del conjunto autorizado` **y el `diff` del conjunto**, que el script ahora efectivamente imprime — la r12 marcó que la evidencia lo prometía y el bloque publicado no lo producía.

Cero cambios en método, skills, instalador, scripts, tests o remoto — y **ningún push**. Y **no se publica el total de commits del rango**: crece con cada corrección del hijo, y publicarlo es lo que envejeció la primera versión.

**C15 — puntero para agentes.** README §Install cierra nombrando «the full procedure **for agents** told to "install axel following this URL"» con link al manual, de modo que el camino que diseñó el feature 02 aterriza en el procedimiento completo.

## Review log

### r13 (base `61a6c32`, HEAD `45cc35f`) — CHANGES_REQUESTED · 3 puntos · 2 corregidos, 1 escalado

Codex verificó que el bloque de C14 funciona con el conjunto de seis —`rc=0`, 7 paths totales y 6 del hijo; quitando `f6fce39`, `rc=1` con el `diff`— y dio por coincidentes 28 pedidos, seis SHA autorizados, 15 secciones, los tamaños `21/1065`, `183/10989` y `374/21148`, el alcance por commit y `git diff --check` limpio. Sin observaciones de preferencia. Los tres puntos son de la misma familia otra vez, y esta vez la ironía es completa: **el commit que arregló una cifra dejó desincronizadas otras tres**.

1. **C14 conservaba el conteo anterior**: el mecanismo estaba bien pero el texto seguía diciendo «cinco SHA» y que falla «un sexto», cuando tras `f6fce39` son **seis** y lo que falla es **un séptimo**. **Aceptado**: corregido, y de paso el texto ahora dice que el número es **el estado de la lista y no una propiedad del criterio**, para que la próxima incorporación no vuelva a dejarlo viejo. Las menciones históricas de la r11 se conservan, como marcó.
2. **El compromiso vigente del padre contradecía `f6fce39`.** STATUS y el ledger seguían prometiendo que el padre **no** commitearía al ledger durante el ciclo abierto, y `f6fce39` hizo exactamente eso. La corrección era necesaria y estaba autorizada; lo que faltaba era **registrar la excepción** y reformular el compromiso. **Aceptado**: en STATUS pasa a «**ningún commit adicional después de `f6fce39`**», con la excepción declarada y su razón —era la corrección del conteo del propio ledger, que el hijo no podía hacer y que el reviewer no dejaba pasar—. **La formulación equivalente dentro del ledger la sincroniza el padre**: es su archivo y su compromiso; el hijo lo reporta y no lo reescribe. Escalado.
3. **El conteo de caídas por `529` no coincidía**: el pedido de la r13 decía **tres** y STATUS decía **dos**. Codex marcó además el punto de fondo, que es el que importa: **el snapshot no contiene con qué arbitrarlo**. Las caídas de sesión no dejan rastro en ningún artefacto versionado. **Aceptado con la segunda de sus dos salidas** —fijar el número desde la fuente autoritativa, o **eliminarlo si no puede reconstruirse**—: se elimina. Publicar una cifra no derivable del repo es exactamente lo que este feature le prohíbe a la vidriera, y no hay razón para que el doc del feature juegue con otras reglas. Queda la afirmación que **sí** es derivable y es la que importa: la racha contractual, que `.claude/state/changes-streak` fija en **3**.

### r12 (base `61a6c32`, HEAD `b7bf446`) — CHANGES_REQUESTED · 3 puntos · 2 corregidos, 1 escalado al padre

Codex dio por cerrado el agujero sustantivo de C14 —ejecutó el bloque publicado: 7/6 paths con `rc=0`, y con un SHA fuera de la lista abortó con `rc=1` y el mensaje esperado— y no dejó observaciones de preferencia.

1. **STATUS no había consumido el resultado de la r11**: la racha debía ser 1 y decía 0, la línea seguía anunciando la r11 cuando la r12 ya estaba lanzada, y —lo peor— **conservaba «veintinueve» mientras la línea de al lado afirmaba que STATUS ya estaba corregido a 28**. Un doc que se contradice consigo mismo en dos líneas contiguas. **Aceptado y corregido**, con la racha ahora en **2** y las dos caídas por `529` declaradas como lo que son: fallas de servidor que **no** cuentan para el tope.
2. **El conteo falso sigue vigente en el ledger** (`pipeline-2026-07-29-3.md`, «veintinueve» donde la derivación cerrada da `13 + 15 = 28`). Codex **coincide en que el hijo no debe editar territorio del padre**, y a la vez plantea el límite correcto: reportarlo no corrige el estado versionado, y no puede aprobar un documento que sabe falso. Su salida es explícita: **lo corrige el padre, y ese commit nuevo sobre el ledger tiene que incorporarse a la lista cerrada de C14**. Escalado al padre — el hijo no lo tocó ni lo declaró resuelto por su cuenta.

   **Resuelto**: el padre corrigió el ledger en `f6fce39` (toca **solo** ese archivo, verificado), dejando el texto original **tachado y conservado** con la derivación escrita. `f6fce39` entra a la lista cerrada, que pasa a **seis** SHA, y los dos caminos del script quedan re-corridos. Vale registrar el razonamiento que el padre corrigió al hacerlo, porque es reusable: él trataba «no romper C14» como la restricción dura y la falsedad del ledger como algo que podía esperar al cierre. **Es al revés — el doc falso es el defecto y C14 es el mecanismo que lo detecta; diferir la corrección para no hacer sonar la alarma es apagar la alarma.** La salida correcta satisface las dos cosas a la vez: el commit entra y la lista cerrada se actualiza en la misma ronda, que es exactamente para lo que sirve tener la lista.
3. **La evidencia de C14 prometía una salida que el script no producía**: decía que el camino negativo muestra «el `diff` del conjunto», y el bloque publicado solo imprimía la línea de `FAIL`. Es la versión chica del mismo defecto de siempre —afirmar sobre el artefacto sin correrlo—, esta vez sobre una promesa de salida. **Aceptado**: el script publica ahora el `diff`, verificado corriendo el bloque literal (`rc=1`, la línea de FAIL y `2a3 > 573814d…`).

### r11 (base `61a6c32`, HEAD `64c96e8`) — CHANGES_REQUESTED · 2 puntos, los 2 aceptados · primera tras el desempate

Alcance acotado por el desempate a los dos puntos de la r10; Codex se mantuvo dentro y no dejó observaciones de preferencia. Dio por buena la corrección de 14→15 secciones.

1. **La partición de C14 seguía pudiendo fallar abierta, y por una razón que yo no vi.** Los cuatro comandos imprimían 7, 6, 5 y 0 como declaraba, pero: el comando 2 definía «míos» de forma **circular** (los que no tocan el ledger), el comando 4 decidía la autoría con `grep -c '^feature 13'` —o sea **leía el mensaje**, contradiciendo la afirmación central de que la partición no lo hacía—, **un commit del hijo sobre el ledger con otro asunto habría quedado reclasificado como del padre** dando 0 igual, y ese `grep -c` imprime 0 con `rc=1`. Tercera versión de C14 y la tercera falla de la misma familia: la evidencia se apoyaba en algo que se mueve o que se puede eludir. **Aceptado con su salida**: comparar el conjunto de commits que tocan el ledger contra una **lista cerrada de los cinco SHA autorizados del padre**, que no envejece con commits del hijo y donde un sexto commit falla sea cual sea su mensaje. Los commits del hijo pasan a definirse como **el rango menos esa lista**, sin circularidad. **Los dos caminos probados**: lista completa ⇒ `rc=0` con las dos listas de paths; con un SHA fuera de la lista ⇒ `rc=1` y el `diff` del conjunto. El bloque publicado corrido literal da 7 paths en el rango y 6 en los del hijo, sin el ledger.
2. **El barrido de conteos encontró dos cifras vigentes incorrectas**, las dos derivables de mis propios encabezados de ronda: la implementación r6–r10 suma `4+4+4+1+2 = 15` puntos y yo publicaba **10**; y el total del ciclo es `13 + 15 = 28`, no 29. **Aceptado y corregido en lo mío** —STATUS y este review log pasan a 15, con el desglose por ronda escrito para que la cifra sea re-derivable y no haya que confiar en ella—. **La tercera ocurrencia vive en el ledger** (`pipeline-2026-07-29-3.md`, «los veintinueve pedidos»), que es **territorio del padre**: no la toco y la reporto, con la derivación, para que la corrija quien es dueño del archivo.

### r10 (base `61a6c32`, HEAD `c826776`) — CHANGES_REQUESTED · 2 puntos, los 2 aceptados · **la que llegó al tope**

Fue la quinta ronda sin converger, así que el padre **cortó la unidad** y llevó las dos posturas al humano. El desempate fue **«a)»**: se autorizan las dos correcciones, la unidad se reanuda con la racha reseteada por el camino contractual (`scripts/review.sh reset-deadlock`, no edición del contador), la numeración **no** se reinicia, y el alcance queda acotado a estos dos puntos — ampliar es divergencia. No es el OK consolidado del pipeline: `design` y `plan` siguen esperándolo.

Vale registrar qué clase de deadlock fue, porque no fue de desacuerdo: **los quince puntos de las cinco rondas —4 en r6, 4 en r7, 4 en r8, 1 en r9 y 2 en r10— se aceptaron sin argumentar ninguno**, y Codex verificó el correctivo de la r9 ejecutando el script publicado —camino feliz con Python y Gradle positivos, seis negativos y `rc=0`; falla con `rc=1`, salida estándar vacía, diagnóstico explícito y limpieza del temporal—. Dio además por cerrados 45/45 tokens, cero links rotos, tamaños, 35,0 %, 15 secciones, lint, `loop.sh` 287/0 e `install.sh` 460/0, y **sin observaciones de preferencia**. El tope se alcanzó por acumulación de bookkeeping, no por dos posturas irreconciliables.

1. **C14 publicaba evidencia de alcance que ya no coincidía con sus propios comandos.** `git diff --name-only ee1e8ca..HEAD` devuelve **siete** archivos y no seis, y los commits del padre sobre el ledger son **cinco** y no uno. El alcance real siguió siendo válido en todo momento —los siete paths están autorizados y los cambios del ledger son del padre—, pero una evidencia que se contradice al ejecutarla no es evidencia. **Aceptado**: C14 reescrito para demostrar el **estado real**, con una partición **mecánica** («toca el ledger o no») que no depende de leer mensajes de commit ni de confiar en la autoría, y con los cuatro comandos corridos literales. Corrección propia agregada encima: **se quitó el total de commits del rango**, porque crece con cada corrección mía y habría vuelto a envejecer la evidencia por tercera vez; lo que se publica son los paths y la partición, invariantes bajo mis commits siguientes.
2. **Un conteo vigente desincronizado**: el riesgo 7 seguía diciendo que C6–C9 cubren **14** secciones cuando C6, la lista cerrada y el manual tienen **15**. **Aceptado**, con su acotación de que las menciones de 14 **dentro del Review log se conservan** porque describen el estado de su ronda.

### r9 (base `61a6c32`, HEAD `30766b3`) — CHANGES_REQUESTED · 1 punto, aceptado · **sin observaciones de preferencia**

Le pedí explícitamente que separara lo bloqueante de la preferencia, porque la racha iba en 3 y quedaban pocas rondas. Respondió con **un solo punto, bloqueante, y ninguna preferencia**; todo lo demás lo dio por cerrado: la matriz con sus dos positivos y seis negativos, los tamaños 21/1065 · 183/10 989 · 358/20 064, el aumento de 35,0 %, la racha 3, C5(A) 45/45, C5(B), C6–C9, links y alcance. Suites: lint limpio, `install.sh` 460/0, `loop.sh` 287/0 con el smoke no contractual omitido.

1. **El script que publiqué como evidencia de la matriz externa fallaba abierto** — la misma clase de defecto que la reconstrucción del corte en la r1, ahora en el artefacto publicado y después de nueve rondas persiguiéndola. Cada `curl` iba sin guarda, así que una descarga fallida dejaba **el template anterior** en `.gitignore`, el loop seguía y `git check-ignore` atribuía ese resultado al template siguiente. Lo **reprodujo**: `curl` devolvió 56, el `.gitignore` conservó el mismo hash y el script informó «ignored» para el template equivocado, saliendo **0**. Evidencia que puede fallar abierta no es evidencia. **Aceptado con las tres guardas que sugirió y una cuarta**: `set -euo pipefail`, `curl … || exit 1`, repositorio de prueba en `mktemp -d` con `trap` de limpieza, y —agregada por mí— `rm -f .gitignore` en cada iteración más descarga a temporal y `mv` recién al cerrar bien, de modo que un `.gitignore` heredado sea **estructuralmente imposible** y no solo esté vigilado. Verificados los dos caminos corriendo el script **tal como queda publicado en el manual**: feliz ⇒ Python y Gradle ignoran, seis negativos, `rc=0`; falla ⇒ `rc=1` con `FAIL: could not fetch …`. El manual publica además **por qué** están las guardas, con el fallo reproducido, para que nadie las quite por parecer decorativas.

### r8 (base `61a6c32`, HEAD `b94e6e7`) — CHANGES_REQUESTED · 4 puntos, los 4 aceptados

Codex dio por cerrados los tamaños de la tabla, C5(A) 45/45, C5(B) completo, las 15 secciones, links y placeholders limpios, y verificó que el rango tiene cinco commits: **uno del padre, exclusivamente sobre el ledger**, y cuatro míos sobre los cuatro docs declarados. Suites: lint limpio, `install.sh` 460/0, `loop.sh` 287/0 con el smoke no contractual omitido.

1. **La tabla de tamaños cerraba pero el porcentaje derivado de ella, no.** `11 002 / 8142` es **+35 %**, no el 30 % que yo seguía publicando: la frase había envejecido al crecer el README en las propias correcciones. **Aceptado**: el porcentaje se **deriva** de las mismas magnitudes de la tabla, con el número recalculado al cierre en vez de estimado. De paso quedaron rotuladas en bytes las dos medidas de línea más larga, que seguían diciendo «caracteres».
2. **Dos formulaciones todavía más amplias que su evidencia.** (a) El README llamaba «stock Unix tools» a los requisitos restantes, y `git`, `python3` y `curl` **no** son herramientas garantizadas por el sistema ⇒ «the command-line tools listed above». (b) La apertura del manual prometía «the failure modes the installer reports» como conjunto **completo**, y el instalador tiene decenas de rechazos concretos mientras el manual documenta clases y casos seleccionados ⇒ «the main failure modes».
3. **La matriz de templates era correcta pero no reconstruible al corte.** Publicaba fecha, el comando y un link a `github/gitignore` sobre **`main`** — que se mueve. Un tercero no podía reproducir la matriz del 2026-07-30. Es exactamente el criterio que este feature le exige a sus propias cifras («ninguna cifra sin su corte»), aplicado a una fuente **externa**, y yo no lo había extendido ahí. **Aceptado con la primera de sus dos salidas**: el manual fija el commit `57286c3` de `github/gitignore`, publica el **script completo** que instala cada template como `.gitignore` de un repo de prueba y corre `git check-ignore`, y presenta el resultado como **snapshot de ese commit**, no como afirmación perpetua sobre cada ecosistema.
4. **La racha durable de STATUS estaba desactualizada.** El `APPROVED` de la r5 la reseteó, pero r6 y r7 fueron dos rechazos consecutivos: al lanzar la r8 STATUS debía declarar **2** y seguía diciendo 0. **Aceptado**: el commit que lanza la r9 declara **3**. Es un defecto de mi bookkeeping, no del contador de `review.sh`, que venía bien.

### r7 (base `61a6c32`, HEAD `7540ca1`) — CHANGES_REQUESTED · 4 puntos, los 4 aceptados

Codex dio por cerrados **C5(B) completo** —las tres correcciones de V7/V9/M7 realizadas—, C5(A) 45/45, cero links rotos, el transcript ya cronológicamente correcto, el aviso MIT, el workaround y el alcance exacto en los cuatro docs. Suites: lint limpio, `install.sh` 460/0, `loop.sh` 287/0 con el smoke no contractual omitido.

1. **Mi propia corrección de la r6 seguía siendo falsa, y es el punto más instructivo del feature.** Había dicho «solo Python ignora `build/`» tras «verificarlo», y **Gradle también ignora**: su template trae `**/build/` en la segunda línea. Mi verificación de la r6 no lo vio porque grepeé el patrón `^!?/?build/?$|^!?/?build/`, que no cubre el prefijo `**/`. O sea: corregí una afirmación falsa del pedido con otra afirmación falsa mía, producida por un comando demasiado estrecho cuyo resultado reporté como hecho — **la misma clase de defecto que este ciclo lleva siete rondas persiguiendo, esta vez dentro de la propia corrección**. **Aceptado**: re-verificado con la prueba **autoritativa** en vez de leyendo patrones — `git check-ignore -v .claude/skills/build/SKILL.md` contra cada template en un repo de prueba — con el resultado **Python y Gradle**; Node tiene `build/Release`, que no matchea; Java, C, Maven, Go y Rust no tienen regla que matchee. Sincronizado en el README, el manual, la tabla C3, el review log y STATUS, y el manual publica ahora **el método** de verificación además del resultado.
2. **Tres afirmaciones públicas más amplias que su evidencia.** (a) «axel has only ever been run on macOS» es una universal histórica que el repo no puede demostrar ⇒ «every recorded run … has been on macOS». (b) «No dependencies» **contradice la propia sección Requirements**, que enumera dos CLIs, git, python3 y curl ⇒ ahora dice que no agrega paquetes al proyecto y que no hay nada que importar, nombrando lo que sí hace falta. (c) «every path, every failure mode» en la apertura del manual promete una exhaustividad que C6 no verifica ⇒ «the supported paths, the failure modes the installer reports, and the known issues». **Aceptadas las tres**: las tres eran mías y ninguna venía del pedido.
3. **La tercera excepción de C5 no había quedado fail-closed.** Agregué la fila a la tabla pero dejé el texto diciendo «Dos tokens» y «esos dos», el criterio C5 diciendo «2 traducciones» y la evidencia diciendo «dos» — y la fila nueva **abreviaba el token con `…`** y expresaba el resultado como «idéntico, con…», cuando el encabezado promete cadenas exactas y un `…` no se puede comparar. **Aceptado**: las dos cadenas completas, y las cinco referencias sincronizadas a **tres**.
4. **Tamaños desactualizados y mal rotulados.** STATUS seguía en 178/325 contra los 182/338 reales, y —lo que importa más— yo llamaba «caracteres» a lo que `wc -c` devuelve, que son **bytes**: en UTF-8 no son lo mismo, y el baseline da 7971 caracteres Unicode contra 8142 bytes contra 8142 y 10 845 bytes. **Aceptado** con la primera de sus dos salidas: se adopta `wc -c` y se lo llama **bytes**, en los dos extremos de la comparación, con los caracteres Unicode citados al lado para que la diferencia quede a la vista.

### r6 (base `61a6c32`, HEAD `bb45c04`) — CHANGES_REQUESTED · 4 puntos, los 4 aceptados

Primera ronda con los artefactos delante, y es exactamente donde el reviewer dijo en la r5 que había que verificar C3 y C5. Dio por cerrados: alcance en los seis archivos, ledger tocado **solo** por `ee1e8ca` (confirmó mi lectura), 45/45 tokens, links y anclas sin roturas, 15 secciones, el workaround reproducible y suficiente, el aviso MIT inequívocamente presentado como incumplimiento abierto, y el repo externo con sus tres SHA. Corrió `lint` limpio, `install.sh` 460/0 y `loop.sh` **287/0** — la diferencia con mis 293 es la conocida: su sandbox saltea los seis asserts del smoke no contractual de `caffeinate`.

Los cuatro puntos, y el patrón vuelve a ser el mismo: **declaré verificado lo que no había verificado contra el artefacto**.

1. **C5(B) no estaba cumplido**, y es el criterio que la r2 me hizo reescribir justamente para que mirara los artefactos. Tres filas del mapa afirmaban cosas que no estaban: **V7** («abrí Claude Code en el repo») no aparecía en ninguna parte del README nuevo; **V9** exigía la limitación de la **tapa cerrada** —necesita corriente y display externo— y no estaba ni en el README ni en el manual, aunque la §Verificación la daba por realizada; y el contenido de **M7** sobre que el modo local no usa red sí existía, pero bajo *From a local clone* y no bajo el locator que yo había publicado. **Aceptados los tres**: agregada la línea de entrada a §The commands, agregado el párrafo de la tapa cerrada a §Requirements del manual, y corregido el locator de M7 para nombrar las dos secciones. Escribir el recorrido no es hacerlo.
2. **C3 tenía hechos falsos o más amplios que su evidencia** — cuatro, y el primero es el peor porque lo transcribí del pedido sin verificarlo, que es literalmente el fallo contra el que existe el criterio (c):
   - «every Python, Node, Java, Gradle, Maven and C template» ignora `build/`. **Falso.** Verificado contra `github/gitignore`: solo **Python** tiene `build/`; **Node** tiene `build/Release`, que **no** matchea; **Java**, **C**, **Maven** y **Gradle** no tienen la regla. La afirmación pasa a ser **condicional** («cuando tu `.gitignore` ignora `build/`») y el manual publica la verificación completa con su fecha.
   - El README decía que una sesión reconstruye leyendo **tres** archivos; `AGENTS.md` enumera **cuatro**.
   - «Everything else … is portable shell» y «everything else works» fuera de macOS: las dos ramas de `caffeinate` prueban que `awake.sh` y el wrapper **degradan limpiamente**, y nada más. Ahora el texto dice que el resto está **untested, no supported**.
   - «This will be fixed» **no es una limitación declarada**: es una promesa a futuro sin feature ni backlog que la respalde, y contradice de frente la decisión registrada en el diseño de dejar esos arreglos afuera **y sin registrar**. Reemplazada por «**not fixed in this pipeline**», con la aclaración de que tampoco hay backlog y de que eso fue una decisión.
3. **El manual no había quedado íntegramente en inglés**: la forma explícita conservaba `<repo-destino>`. Es una **tercera** traducción de placeholder que la tabla cerrada no exceptuaba — y como el resto de la cadena es idéntica, el `grep` de C5 pasaba con el placeholder en español intacto. O sea: «cero pérdida» y la política de idioma se contradecían, y el conflicto se estaba resolviendo a mano sin quedar escrito. **Aceptado**: `<destination>`, y la sustitución entra a la tabla cerrada.
4. **La cronología del transcript no cerraba**: tras la corrección de la r2 quedan cinco rondas hasta el `APPROVED` de la r7, no «six more». **Aceptado** con su formulación: cinco rondas más, seis en total después del primer rechazo.

### r5 (base `284ace4`, HEAD `61a6c32`) — **APPROVED de la bajada**

Sin observaciones accionables. Codex reprodujo la matriz positiva (10 eventos → 7 rondas, `NO_VERDICT` terminal y retries válidos solo tras `PROC_FAIL`), **las dos negativas** (retroceso y repetición inválida ⇒ `rc=1` y **exactamente 0 filas**), el snapshot real con sus 88 rondas y todas las cifras, los 45 tokens byte a byte, la coherencia de `STATUS.md`, el alcance en los dos docs y `lint.sh` limpio. Dejó anotado que **C3 y C5 se verifican durante la implementación** contra el README y el manual reales, que es lo que el propio criterio establece.

**Cinco rondas, trece pedidos —3 en r1, 3 en r2, 4 en r3, 3 en r4—, los trece aceptados sin argumentar ninguno, y ninguno movió una sola cifra publicada.** Los trece fueron la misma clase de defecto, cada vez un nivel más adentro: **procedimientos que verificaban su propio enunciado en vez del artefacto**. La reconstrucción del corte fallaba abierta; los reductores contaban filas y no rondas del contrato; el extractor se comía tres clases de contenido invariante, una por ronda (backticks, links, paths desnudos); la guarda de topología dejaba pasar el caso que yo mismo había señalado; y `die()` rechazaba el input pero igual dejaba el artefacto escrito. En dos de esas rondas la diferencia entre una opinión y un hallazgo la puso el reviewer **reproduciendo el daño** en vez de argumentarlo, incluida una duda que yo había planteado y él contestó sobreescribiendo un `APPROVED` en un fixture. Quedó como riesgo 8 del doc para que la implementación no lo redescubra.

Nota de cierre del ciclo: la racha llegó a **4** —la r5 era la última que `review.sh` permitía antes de bloquear por deadlock— y el `APPROVED` la devolvió a 0.

### r4 (base `284ace4`, HEAD `aa6c910`) — CHANGES_REQUESTED · 3 puntos, los 3 aceptados

**Dos cierres explícitos**, que es lo que esta ronda aporta además de los tres puntos: el **extractor quedó cerrado** —45 tokens, lista publicada idéntica byte a byte, `CLAUDE.md` incluido, y «no encontré otra clase invariante perdida; los encabezados y demás prosa corresponden al mapa semántico»—, y **C3 y el recorrido de C5 quedaron aceptados como verificaciones humanas legítimas**, «porque operan contra los artefactos finales y listas cerradas». Las dos eran preguntas mías. Cifras reproducidas sin cambios, alcance en los dos docs, `lint.sh` limpio.

1. **La guarda de topología todavía aceptaba el caso que yo mismo había marcado.** Le había preguntado por dos ciclos de una sola ronda con el `new` perdido —donde no hay retroceso ni salto—, y en vez de opinar lo **reprodujo**: `new/1/1 APPROVED` → `round/1/1 CHANGES_REQUESTED` devolvía `rc=0`, fusionaba los ciclos y **sobreescribía el `APPROVED`**. Y mostró que sí es detectable, por un camino que yo no había visto: una ronda repetida solo es legítima si es un **retry**, y el retry tiene forma fija —mismo número, **mismo modo**, **mismo SHA**, intento que **incrementa**, `PROC_FAIL` previo—; dos filas con `attempt=1` no son eso. **Aceptado**: cuarta guarda con esa gramática. Verificado antes de implementarla que las filas `PROC_FAIL` **llevan el SHA** (`log_event PROC_FAIL … "$REVIEW_HEAD_SHORT"` en `scripts/review.sh`), así que la identidad de SHA es chequeable y no hubo que debilitar la regla. **Segundo hallazgo del mismo punto, y es un error factual mío sobre la maquinaria**: mi prueba positiva usaba `NO_VERDICT → intento 2` como retry de `round`, y `review.sh` **no reintenta un veredicto inválido** (`TERMINAL_RESULT="NO_VERDICT"`, sin relanzar). O sea, había escrito un fixture de un estado que la maquinaria no produce. **Aceptado**: `NO_VERDICT` pasa a ser desenlace propio de su ronda —el ciclo sigue en la ronda siguiente— y el retry de `round` se prueba con `PROC_FAIL → intento 2`.
2. **`die()` dejaba salida parcial.** Cierto y es el tipo de defecto que este mismo doc viene persiguiendo: `exit` dentro de una regla de awk **igual pasa por `END`**, así que la prueba negativa devolvía `rc=1` **y a la vez** escribía dos filas en `rondas.tsv` — un artefacto perfectamente consumible por el comando siguiente, detrás de un rechazo. Fail-closed a medias no es fail-closed. **Aceptado**: bandera `failed` verificada en `END`, `rc=0` declarado como **postcondición** de la invocación, y «0 filas emitidas» incorporado a las dos pruebas negativas como aserción, no como comentario.
3. **`STATUS.md` había quedado con dos campos de veredicto**: r3 como «Veredicto anterior» y una línea «Último veredicto: —» que además arrastraba pegado el relato obsoleto de r2. **Aceptado**: un único «Último veredicto», el de r3 —ahora el de r4—, más una línea de racha explícita.

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
3. **La mitad mecánica de «cero pérdida» seguía dependiendo del juicio del ejecutor.** Cierto: «un extractor de tokens» sin algoritmo ni lista cerrada permite omitir un token al seleccionarlos y obtener «cero faltantes». Y el mapa contabilizaba la línea 18 y el bloque 22–69 pero **dejaba 1–17 afuera**, incluyendo la entrada de uso y las descripciones de comandos — que es justo donde estaba el problema del punto 2. **Aceptado**: baseline fijado en `284ace4:README.md`; extractor escrito como `awk` reproducible y **su salida de 40 tokens versionada literalmente** en el doc; mapa extendido a **V1–V9 + M0–M14**, con disposición declarada por tramo (mudado / conservado / partido / reemplazado a propósito) y **cobertura derivada**: 33 líneas sin contenido (23 en blanco + 10 delimitadores de fence, ambas enumeradas por comando) y 36 con contenido, todas mapeadas, sin huecos ni solapamientos. Declaradas además las excepciones de la lista de tokens (placeholders en español que la traducción cambia; en la r7 pasaron a ser tres), para que no se resuelvan por criterio del momento.
