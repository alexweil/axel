---
name: recap
description: Generar un RECAP para el humano — qué se hizo desde el último OK, decisiones tomadas, estado del loop y qué viene si da el OK.
---

Armá un RECAP leyendo `docs/STATUS.md`, el doc del feature en curso (`docs/implementation/NN-*.md`, incluido su Review log) y los commits desde el último OK (`git log`).

Estructura:

1. **Qué se hizo** — en términos de resultado, con los commits como respaldo.
2. **Decisiones y review** — qué acordaron o discutieron los agentes, cuántas rondas llevó, qué cedió cada uno.
3. **Estado** — docs al día, árbol limpio, veredicto vigente.
4. **Riesgos o pendientes** — lo que el humano debería saber antes de dar el OK.
5. **Qué viene con tu OK** — el próximo paso concreto (siguiente feature, o continuar el loop actual).

Cerrá pidiendo el OK explícitamente. Si STATUS.md no dice ya "esperando OK", actualizalo y commiteá. Si la herramienta PushNotification está disponible y el humano no está activo en la sesión, mandá un aviso de una línea. Después del RECAP, terminá el turno: no sigas trabajando sin el OK.
