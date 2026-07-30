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

| Dato | Derivación | Valor |
|---|---|---|
| Titular | `git log --format='%an' \| sort -u` sobre los 212 commits ⇒ **un único autor**; coincide con el owner de la URL pública `github.com/alexweil/axel` | `alexweil` |
| Año | `git log --reverse --format='%ad' --date=short \| head -1` ⇒ primer commit `2026-07-27`; el repo entero vive en 2026 | `2026` |

Línea resultante: `Copyright (c) 2026 alexweil`.

**Lo que esto no resuelve, y se anota para el humano**: `alexweil` es el nombre de autor de git y el handle de GitHub, no necesariamente el nombre legal con el que quiera figurar. Cambiarlo es editar **un token en una línea** de `LICENSE` y no toca nada más. Se declara acá para que el RECAP consolidado lo pueda ofrecer; no se pregunta a mitad de unidad porque hay un valor derivable y defendible.

### 2. «Cero pérdida» cuando la mudanza es a la vez traducción — chequeo partido en dos

El diseño advierte que un diff de texto no sirve, porque el contenido cambia de idioma en el mismo movimiento. La bajada parte la verificación en dos mitades, y solo una necesita juicio:

- **(A) Mecánica, sobre lo que no tiene idioma.** Comandos, flags, variables de entorno, paths, exit codes y las cadenas literales que imprime el instalador son **invariantes de idioma**: si están en el README de hoy y no están en `docs/install.md`, se perdieron. Se verifica con un extractor de tokens sobre el README viejo y un `grep` de cada token contra el manual nuevo — resultado esperado: **cero faltantes**, con la lista de tokens registrada como evidencia.
- **(B) Por contenido, caso por caso, sobre la prosa.** Inventario cerrado de los casos del README actual (abajo), cada uno con su destino en el manual y su delta declarado. Se verifica leyendo, no diffeando; la tabla es lo que hace auditable esa lectura.

#### Inventario de mudanza (fuente: `README.md` en `284ace4`, 69 líneas)

| # | Caso del README actual (líneas) | Destino en `docs/install.md` | Delta |
|---|---|---|---|
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
| M15 | 18 · «el loop corre solo… se frena en cada RECAP», sesión remota, `awake.sh` + `caffeinate`, tapa cerrada | README nuevo §How it works **y** manual §Requirements (la parte de `caffeinate`) | **partido**: la mecánica del loop es vidriera; la dependencia de macOS es requisito operativo |

**Regla de corte que la tabla hace cumplir** (diseño §«Vidriera y manual»): en el dominio operativo nada queda documentado **solo** en el README. Los casos M1–M14 salen del README y viven completos en el manual; el README conserva de ellos **un** camino de instalación y **punteros**, nunca el caso.

**Contenido nuevo del manual, que no viene del README** (no es mudanza, así que no entra en el inventario de pérdida): §Known issues con los tres puntos de fricción, §After an adoption con los cuatro docs y dos nombres, y §License notice con la limitación del aviso MIT.

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

**Corte declarado: `b0bdf4d`** — head de la ronda 4 (`APPROVED`) de la unidad `plan` de este mismo pipeline. Se elige porque es **el último SHA que aparece en `.claude/state/rounds-log`** en el momento de escribir, lo que vuelve trivial y mecánica la reconstrucción del 14: *tomar las filas hasta la que lleva ese SHA, inclusive*. Verificado: `awk -F'\t' '{print} $6=="b0bdf4d"{exit}' .claude/state/rounds-log | wc -l` ⇒ **88**, que es el archivo completo de hoy. Verificado también que `b0bdf4d` es ancestro de `HEAD`.

**Consecuencia declarada** (propia de cualquier foto, no un defecto): el corte **no incluye las rondas de los features 13 y 14**. Va escrita en el README.

### Cifras derivadas al corte, con su comando

Toolchain de stock de macOS; sin `asort` (que es de gawk), el orden se resuelve con `sort`. Formato del log: `ts \t {new|round} \t ronda \t intento \t veredicto \t sha \t racha`.

| Cifra | Comando | Valor |
|---|---|---|
| rondas registradas (dedup por ciclo y número) | `awk -F'\t' '$2=="new"{c++} $6!="-"{k=c":"$3; if(!(k in s)){s[k]=1; n++}} END{print n}'` | **88** |
| `CHANGES_REQUESTED` | `awk -F'\t' '$5=="CHANGES_REQUESTED"' \| wc -l` | **59** |
| `APPROVED` (**hitos**, no features) | `awk -F'\t' '$5=="APPROVED"' \| wc -l` | **29** |
| ciclos completos | `awk -F'\t' '$2=="new"' \| wc -l` | **18** (+1 parcial, el del arranque del log) |
| veredicto de la **r1** de cada ciclo | `awk -F'\t' '$2=="new"{print $5}' \| sort \| uniq -c` | **18 de 18 `CHANGES_REQUESTED`** — cero aprobados en ronda 1 |
| mediana de rondas por ciclo | longitudes `2 2 2 2 3 3 3 4 4 4 5 5 6 7 7 7 8 11` (18 valores) | **4** |
| peor caso por ciclo | ídem | **11** |
| mediana / peor caso por **hito** | 28 hitos observables (29 `APPROVED` menos el primero, parcial) | **3** / **5** |
| hitos aprobados sin rechazo en su tramo | recorrido de tramos | **exactamente 1** (`2dbbdfc`) |

**Aviso obligatorio para el feature 14 y para cualquier relectura: la mediana por ciclo volvió a dar 4, y no es la reaparición del error que el delta de diseño corrigió.** El diseño ([public-surface.md](../design/public-surface.md) §«La unidad de conteo») corrigió un **4** que era falso: salía de contar el ciclo **parcial** del arranque del log como si fuera completo, y sobre los 16 ciclos completos de su corte (`e1e1282`) la mediana era **4,5**. Al corte `b0bdf4d` hay **18** ciclos completos —los dos nuevos son las unidades `design` y `plan` de este pipeline, de 4 rondas cada una—, y la mediana de 18 valores es el promedio del 9.º y el 10.º, que son `4` y `4`. O sea: **mismo número, criterio distinto, corte distinto**. El ciclo parcial sigue excluido. Publicar «4» sin esta nota reintroduciría la confusión que el diseño resolvió; por eso la mediana **no va al README** —va al doc de métricas del 14, que es donde el criterio se explica— y el README publica solo la terna de titular.

### Cifras del gancho, al mismo corte

| Cifra | Comando | Valor |
|---|---|---|
| commits | `git rev-list --count b0bdf4d` | **212** |
| días | `git log b0bdf4d --format='%ad' --date=short \| sort -u \| wc -l` | **3** (2026-07-27 · 28 · 29) |
| features cerrados | `grep -cE '^\| [0-9]+ \|.*\*\*Cerrado\*\*' docs/IMPLEMENTATION.md` | **13** (00–12) |

**Precisión sobre los 13**: el bloque «Hechos del pedido» del ledger dice **12**, contando 01–12 y dejando afuera el feature **00** (bootstrap). La tabla del plan lo lista como fila cerrada igual que los demás, así que el número derivable del comando es 13. Se publica **13 con su comando**, que es lo que un tercero puede reproducir.

### Total histórico

**88 registradas** al corte + **35 anteriores a la instrumentación** = **123**. Las 35 vienen de **dos fuentes que se citan por separado** (diseño §«La unidad de conteo», hallazgo 2): **30** en los review logs versionados de los features 00–03 y **5** del ciclo de plan inicial, cuya memoria son los commits y el STATUS histórico. El README publica las dos cifras **rotuladas** y nunca una sola sin decir a cuál corresponde.

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

Secciones: Requirements · Install (*Quick install*, *What the defaults assume*, *Explicit form*, *From a local clone*, *The `~/.axel` cache*, *Forks*) · Did it actually run? · If you installed into the wrong repo · What gets installed · The three modes · After an adoption · Exit codes · For agents (Claude Code) · Audit before you run · Known issues · License notice · Tests.

**Known issues**, con el criterio del diseño (un problema se documenta donde el usuario lo choca):

1. **La colisión `build/`** — el rechazo literal verificado en P1, el workaround `!.claude/skills/build/`, y la trampa de `!.claude/` explicada con la evidencia de `git check-ignore -v`. Único que además se gana un puntero desde el README, por ser el único que **bloquea** la promesa de «instalalo sin volver a preguntar».
2. **El rechazo por árbol sucio no lista los archivos sucios**, y `git stash` sin `-u` no toca untracked — que es el caso más común en un repo activo.
3. **`modo: initial` anunciado cuando lo ejecutado fue una adopción** (verificado en P3, que anunció `initial` y salió con `rc=1` y `ADOPTION.md`), con su consecuencia visible: el destino queda con cuatro docs y dos nombres sin aviso de cuál manda. Va en §After an adoption, que es donde se choca.

**§License notice** declara la limitación como **incumplimiento pendiente y no como cumplimiento parcial**: MIT pide que el aviso viaje en las copias, el instalador copia skills, scripts y contrato sin llevarlo, y decirlo en el manual **informa y no satisface el requisito**.

## Criterios de cierre

| # | Criterio | Cómo se verifica |
|---|---|---|
| C1 | `LICENSE` existe, es MIT estándar y dice `Copyright (c) 2026 alexweil` | lectura + las dos derivaciones de §1 |
| C2 | `README.md` en inglés, las nueve secciones en el orden aprobado, requisitos antes del comando de instalación | lectura contra la estructura de arriba |
| C3 | **Cero afirmación no verificable**: toda oración del README y del manual cae en una de las tres clases del contrato editorial (hecho derivable con su comando · limitación declarada · opinión marcada) | pasada por oración, registrada en el Review log |
| C4 | Toda cifra publicada lleva su **commit de corte** y su comando, y coincide con la derivación de §«El corte de métricas» | re-derivación con los comandos de la tabla |
| C5 | **Cero pérdida**: los 15 casos M1–M15 tienen destino y están completos; cero tokens invariantes de idioma faltantes | tabla de mudanza + extractor/`grep` de tokens |
| C6 | **Cero link roto**: todo link del README y del manual resuelve | chequeo mecánico de cada destino relativo |
| C7 | Las **dos** referencias a artefactos del 14 están **sin linkear** y marcadas como pendientes de forma visible | inspección de §1 y §9 |
| C8 | El one-liner y el workaround publicados son los **probados** (P1–P4), incluida la línea final real del rechazo | comparación literal contra la evidencia de §4 |
| C9 | El transcript no tiene **ninguna línea inventada**: cada una rastrea a un commit, un evento de ledger o un review log, citado en su idioma original | tabla de fuentes de §3, verificada una por una |
| C10 | **Alcance**: el diff del feature toca solo `LICENSE`, `README.md`, `docs/install.md`, este doc, `docs/IMPLEMENTATION.md`, `docs/STATUS.md` y el ledger — cero cambios en método, skills, instalador, scripts, tests o remoto | `git diff --stat` contra el SHA de arranque |
| C11 | El README conserva el **puntero de una línea para agentes**, para que el camino «instalá axel siguiendo \<url\>» del feature 02 no aterrice en una página sin procedimiento | inspección de §5 |
| C12 | No-regresión: `tests/lint.sh`, `tests/loop.sh` y `tests/install.sh` siguen limpios | corrida de las tres suites |

## Riesgos

1. **Prosa sin harness.** No hay test que compruebe que un README convence. Mitigación: los criterios son de **verificabilidad**, no de gusto — el contrato editorial convierte «prosa auditable» en una clasificación por oración, y C3/C9 la hacen revisable.
2. **Las cifras se mueven mientras se escribe.** Ya pasó durante la review del delta de diseño. Mitigación: corte declarado, comandos escritos, y la consecuencia (el snapshot no incluye las rondas del 13 y del 14) publicada en vez de escondida.
3. **La mediana que volvió a 4.** Riesgo concreto de que una relectura futura crea que se reintrodujo el error corregido. Mitigación: el aviso explícito de arriba, y la decisión de **no publicar la mediana en el README**.
4. **Traducir mientras se muda puede perder un caso en silencio.** Mitigación: la partición (A)/(B) — lo invariante de idioma se chequea mecánicamente, y lo demás contra una tabla cerrada de 15 casos.
5. **El one-liner probado corre contra el remoto, que está detrás del local.** Mitigación: declarado en §4; el README no afirma nada sobre el contenido no pusheado.
6. **Tentación de cerrar la deuda normativa de `AGENTS.md`.** Es una línea y está a la vista. Mitigación: está fuera de la ruta autorizada — tocarla es divergencia ⇒ corte.

## Review log

_(vacío)_
