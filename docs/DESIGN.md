# axel — Diseño

> Este doc es el diseño a gran escala. Las profundizaciones por tema viven en `docs/design/*.md` y se referencian desde acá. La posición actual del trabajo está en [STATUS.md](STATUS.md); el plan, en [IMPLEMENTATION.md](IMPLEMENTATION.md).

## Objetivo

Maquinaria reusable para desarrollar proyectos con dos agentes en loop — un **generador** (Claude Code) y un **reviewer** (Codex) — iterando sobre cada pieza hasta acuerdo, con la documentación como memoria persistente y checkpoints de OK humano. Sirve para software o cualquier contenido generable por agentes. axel se desarrolla a sí mismo con su propio método.

## Principios

1. **El estado vive en el repo, no en el chat.** Toda sesión (nueva, local o remota) se reconstruye leyendo AGENTS.md → STATUS.md → DESIGN/IMPLEMENTATION. El contexto de chat se descarta entre features sin perder nada.
2. **La sesión de Claude Code es el proceso y el panel de control.** El loop corre adentro de la sesión, no en un orquestador externo: el humano la abre —incluso remota— y puede preguntar o desviar en cualquier momento, porque la sesión tiene el contexto vivo.
3. **Generador y reviewer separados, cada uno con su contexto.** Claude genera y commitea; Codex revisa con capacidad de ejecutar para verificar por su cuenta. Cada uno mantiene su contexto durante un feature (sesión de chat / resume de Codex) y lo renueva al cambiar de feature.
4. **El OK humano es la frontera de contexto.** RECAP → OK → sesiones frescas para el siguiente feature. El humano no dirige el detalle: valida dónde estamos, cómo venimos y qué sigue. En modo lote la validación se agrupa — autorización del gate de lote al inicio, OK consolidado que cierra al final — y la frontera de contexto la aporta la maquinaria: subagente fresco por feature ([design/batch-features.md](design/batch-features.md)).
5. **Los docs se actualizan en cada commit.** Si no quedó registrado, no pasó. El delta de docs es lo que el reviewer usa para saber qué verificar.

## Componentes

| Pieza | Qué es |
|---|---|
| `AGENTS.md` + symlink `CLAUDE.md` | Contexto raíz que ambos agentes cargan automáticamente: proceso, reglas, mapa de docs. Una sola fuente. |
| `docs/DESIGN.md` + `docs/design/*` | Diseño a gran escala y profundizaciones por tema. |
| `docs/IMPLEMENTATION.md` + `docs/implementation/*` | Plan priorizado con estado por feature; bajada fina y review log de cada uno. |
| `docs/STATUS.md` | La posición actual en ~10 líneas; se actualiza en cada commit. |
| `.claude/skills/` | Las fases del método como comandos: `/design`, `/plan`, `/feature`, `/status`, `/recap`. |
| `scripts/review.sh` | Wrapper del reviewer: config de modelo, ciclo de vida de sesiones (new/resume), rango de commits, contrato de veredicto. Detalle: [design/review-contract.md](design/review-contract.md). |
| `.claude/state/` | Estado local no versionado: session id de Codex, SHA del último APPROVED, contador de ronda, racha y el registro de métricas `rounds-log`. |
| `.claude/settings.json` | Permisos preaprobados para que el loop no se frene en confirmaciones mientras el humano no está. |
| `scripts/install.sh` + `templates/` | Instalador: lleva la maquinaria a otro repo (instalación, adopción de proyectos con proceso manual previo, actualización con axel como fuente de verdad). Detalle: [implementation/01-installer.md](implementation/01-installer.md). |
| `/adopt` + `docs/ADOPTION.md` | Cierre de adopción en el destino: el instalador deja el handoff persistente con los hallazgos y la skill lo consume con el humano (mapear docs, derivar el STATUS real). |

## El flujo

```
/design ─► DESIGN.md ─review─► RECAP ─► OK ─► /plan ─► IMPLEMENTATION.md ─review─► RECAP ─► OK
                                                              │
                 ┌────────────────────────────────────────────┘
                 ▼
        /feature (sesión limpia)
        gate de arranque: resumen ─► confirmación humana
        bajada fina ─review─► implementar ─commit─► review ─► … ─► APPROVED
                 │
                 ▼
              RECAP ─► OK humano ─► siguiente /feature (sesión limpia)
```

Dentro de un feature: cambio → commit → review → corregir o argumentar → commit → review… hasta `VERDICT: APPROVED`. Tope de 5 rondas sin convergencia → RECAP temprano para que desempate el humano.

**Modo lote** (`/feature all` o `/feature NN..MM`): varios features pendientes en una sola corrida — gate de lote (N resúmenes → una autorización global, con exclusiones puntuales) → un subagente por feature en secuencia, cada uno con su loop de review completo, supervisado por la sesión orquestadora; cada feature aprobado queda «APPROVED — pendiente OK de lote» → RECAP consolidado → OK humano que cierra todo. Estado durable en un ledger versionado por corrida. Detalle: [design/batch-features.md](design/batch-features.md).

## Decisiones

| Fecha | Decisión | Elección | Por qué |
|---|---|---|---|
| 2026-07-27 | Alcance del repo | axel ES la maquinaria | Se desarrolla a sí misma; llevarla a otros proyectos es un feature (instalador). |
| 2026-07-27 | Orquestación | Loop adentro de Claude Code; Codex como subproceso | La sesión es lo que el humano consulta remoto; un orquestador externo la dejaría ciega. |
| 2026-07-27 | Git | `main` lineal, un commit por paso, sin amend | La historia ES el registro del loop; el reviewer ve deltas por rango de commits. |
| 2026-07-27 | Rol del reviewer | Puede ejecutar (workspace-write), no modifica | Verificación independiente: no confía en la evidencia del generador. |
| 2026-07-27 | Config de modelos | Variables al tope de `review.sh` (+ env `AXEL_REVIEW_*`) | Cambiar de modelo o esfuerzo = tocar una línea versionada, sin depender de config global. |
| 2026-07-27, refinada 2026-07-28 (feature 04) | RECAP y esperas | El turno termina y la sesión queda esperando; el aviso sigue el criterio de autonomía (espera alcanzada por trabajo autónomo → push de una línea; respuesta directa → sin push) y tras un OK que cierra fase o feature se facilita la sesión siguiente (chip de spawn / instrucción única). Protocolo: skill `recap` y skills de fase. | El OK puede llegar desde una sesión remota en cualquier momento; presencia no se adivina — se decide por cómo se llegó a la espera. |
| 2026-07-27 | Instalador | Payload sobreescribible vs. semillas intocables; modos por marker; adopción = script mecánico + `/adopt` semántico; git + preflight como red (fail-closed) | El re-run es la actualización sin pisar lo del proyecto; nada del instalador queda fuera del diff ni se decide adivinando. Detalle: [implementation/01-installer.md](implementation/01-installer.md). |
| 2026-07-28 | One-liner corto del instalador | Defaults **solo en el camino de bootstrap** (fuente ⇒ URL canónica cuando el script corre piped; destino ⇒ toplevel del cwd), anunciados antes de actuar, con guard del destino asumido que es la propia fuente; el modo local no cambia. Finalización verificable: único terminal `finish`, línea final `── axel · fin: rc=N` y RC no contractual para la incompletitud del delegado | Un `curl … \| bash` no puede llevar argumentos, y sin `pipefail` no distingue "falló" de "nunca corrió": los defaults declaran la ambigüedad en vez de exigirla y la línea final la hace detectable. Detalle: [implementation/06-oneliner-defaults.md](implementation/06-oneliner-defaults.md). |
| 2026-07-28 | Gate de arranque de feature | `/feature` presenta un resumen derivado de los docs y espera la confirmación humana antes de la bajada fina; estado persistido en STATUS («esperando confirmación de arranque») con re-presentación al reabrir | Validar el rumbo cuando el humano está presente por construcción, antes de gastar bajada y rondas de review; el OK final de integración no se reemplaza. Detalle: [implementation/05-feature-gate.md](implementation/05-feature-gate.md). |
| 2026-07-28 | Batch de features | `/feature all` y `/feature NN..MM` (el `/feature` solo no cambia): orquestador supervisor + un subagente por feature; gate de lote = autorización de ejecución (N resúmenes, exclusiones puntuales), cada feature aprobado queda «APPROVED — pendiente OK de lote», el OK del RECAP consolidado cierra; ledger versionado por corrida con reentrada fail-closed; señal terminal atómica con identidad de invocación en `review.sh` — el APPROVED de Codex por feature no cambia | La frontera de contexto la resuelve el subagente fresco; el spike mostró que el subagente no se re-invoca al terminar su background → el padre supervisa la señal terminal y lo empuja por mensaje, sin transportar feedback. Detalle: [design/batch-features.md](design/batch-features.md). |

## Profundizaciones

- [design/review-contract.md](design/review-contract.md) — contrato generador↔reviewer: transporte, prompt, sesiones, veredictos, deadlock.
- [design/batch-features.md](design/batch-features.md) — modo lote de `/feature`: gate de lote, contrato padre↔hijo, condiciones de corte, evidencia del spike.
