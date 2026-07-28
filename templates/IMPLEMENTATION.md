# {{PROJECT}} — Implementación

> Plan a gran escala y estado por feature; se acuerda en la fase `/plan`. La bajada fina de cada feature vive en `docs/implementation/NN-nombre.md`, con sus decisiones y su review log. La posición actual está en [STATUS.md](STATUS.md).

## Cómo se trabaja un feature

Sesión limpia → `/feature` → gate de arranque (resumen breve + confirmación humana) → bajada fina → review → implementación con loop de review → RECAP → OK humano. Reglas en [AGENTS.md](../AGENTS.md); contrato de review en [design/review-contract.md](design/review-contract.md). **Modo lote**: `/feature all` o `/feature NN..MM` — gate de lote al inicio, subagente fresco por feature (quedan «APPROVED — pendiente OK de lote»), RECAP consolidado cuyo OK cierra (detalle en la skill `feature`).

## Criterio de orden

(Explícito: qué manda al priorizar — pedidos del humano, valor desbloqueado, riesgo.)

## Features

| # | Feature | Estado | Doc |
|---|---|---|---|
