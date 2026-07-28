---
name: recap
description: Generar un RECAP para el humano — qué se hizo desde el último OK, decisiones tomadas, estado del loop y qué viene si da el OK.
---

Armá un RECAP leyendo `docs/STATUS.md`, el doc del feature en curso (`docs/implementation/NN-*.md`, incluido su Review log) y los commits desde el último OK (`git log`).

Estructura:

1. **Qué se hizo** — en términos de resultado, con los commits como respaldo.
2. **Decisiones y review** — qué acordaron o discutieron los agentes, cuántas rondas llevó, qué cedió cada uno.
3. **Estado** — docs al día, árbol limpio, veredicto vigente. Listá siempre los commits posteriores a la última base aprobada (`git log $(cat .claude/state/last-approved-sha 2>/dev/null)..HEAD --oneline`, si existe base) marcados como **aún no revisados por Codex**. Si el RECAP es terminal (no habrá ciclo siguiente que los barra), decilo explícitamente: el OK humano es lo que los cubre, y ofrecé una mini-review previa (`scripts/review.sh round`) si tuvieron sustancia más allá de bookkeeping — camino terminal del contrato.
4. **Riesgos o pendientes** — lo que el humano debería saber antes de dar el OK.
5. **Qué viene con tu OK** — el próximo paso concreto (siguiente feature, o continuar el loop actual).

Cerrá pidiendo el OK explícitamente. Si STATUS.md no dice ya "esperando OK", actualizalo y commiteá. Aplicá el protocolo de aviso de abajo. Después del RECAP, terminá el turno: no sigas trabajando sin el OK.

## Aviso al humano (protocolo único — las demás skills refieren acá, no lo repiten)

Al terminar un turno esperando respuesta del humano, el aviso depende de **cómo se llegó a la espera**, no de dónde:

- **Espera alcanzada por trabajo autónomo** (el turno venía de rondas de review en background o implementación larga: los RECAP de cierre de feature, de diseño, de plan, y los tempranos que el loop produce solo — deadlock, tope de rondas, exit 2 persistente, sorpresa detectada por el loop) → mandá un push de una línea.
- **Respuesta directa a un mensaje que el humano acaba de mandar** (`/recap` a demanda, re-presentar el RECAP al reabrir una sesión en "esperando OK", un RECAP temprano disparado por lo que el humano acaba de decir, preguntas interactivas de `/design` o `/adopt`) → sin push: el humano está presente por construcción.
- Borde: si entre el mensaje del humano y el RECAP mediaron rondas autónomas, va aviso. En la duda, aviso — un push redundante cuesta nada; un loop estancado se mide en horas.

El aviso: **una línea en español**, `<proyecto>: <qué pasó> — <qué se espera>` (p. ej. "axel: feature 04 cerrado (APPROVED r3) — esperando tu OK"). Herramienta: la de push del harness (hoy `PushNotification`; puede requerir cargarla vía búsqueda de herramientas). Si no está disponible o la invocación falla, seguí sin aviso y sin tratarlo como error del loop: el estado autoritativo es STATUS.md — quien abra una sesión reconstruye todo aunque el push no haya llegado.
