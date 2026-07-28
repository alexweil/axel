# STATUS

- **Fase**: feature 02 (instalación remota one-liner) — paso A corregido tras r6, en review
- **Feature en curso**: 02 — [implementation/02-remote-install.md](implementation/02-remote-install.md): bajada aprobada (r4); paso A = `install.sh --from` + matriz T15 (321 asserts, 0 fallas). Falta paso B: README para agentes + `templates/AGENTS.md` + aceptación real contra GitHub
- **Ronda de review**: 7 del ciclo 02 — lanzándose; la ronda 6 dio CHANGES_REQUESTED (3 puntos, todos aceptados y reproducidos: hash-object dependía del cwd — falso rechazo SHA-256 —, fetch corría hooks vía auto-follow de tags, verify_tree escapaba con RC 141 por SIGPIPE)
- **Último veredicto**: CHANGES_REQUESTED · ronda 6 del ciclo 02 · base `6010ed2` (racha 2; paso A convergiendo 4→3)
- **Esperando**: veredicto de Codex sobre las correcciones
- **Actualizado**: 2026-07-27
