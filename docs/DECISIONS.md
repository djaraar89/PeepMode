# Registro de decisiones de arquitectura y diseño (DECISIONS)

> Este archivo es un registro acumulativo append-only. Las entradas anteriores no deben modificarse ni eliminarse. Toda corrección debe registrarse mediante una nueva entrada al final.

## DEC-0001 — 2026-08-18 — Flujo de trabajo protegido por ramas

- **Estado:** aceptada
- **Contexto:** Necesidad de proteger la estabilidad del proyecto, el código original de PeepMode y los mapas de StarCraft II durante el proceso de integración y actualización del map pool 2026.
- **Decisión:** Establecer un flujo de trabajo estructurado y protegido donde:
  1. La rama `master` permanecerá como referencia limpia e inmutable del repositorio original.
  2. La integración general de la rotación se llevará a cabo en la rama de integración `integration/2026-map-pool`.
  3. Cada mapa de la rotación contará posteriormente con una rama de trabajo dedicada e independiente.
  4. `Blackrock` será el primer mapa piloto para la validación de procesos y herramientas.
  5. Queda prohibida la modificación simultánea de los mapas de la rotación y los reemplazos masivos sobre carpetas `.SC2Map`.
  6. Los registros documentales (`docs/WORKLOG.md`, `CHANGELOG.md`, `docs/DECISIONS.md`) operarán bajo un régimen estricto append-only.
- **Motivo:** Prevenir regresiones, evitar corrupción en componentes binarios y XML de mapas SC2 y asegurar la trazabilidad completa de cada cambio atómico.
- **Alternativas consideradas:**
  - *Trabajar directamente en master:* descartada por alto riesgo de corrupción de la base original.
  - *Modificar simultáneamente todos los mapas de la rotación:* descartada por dificultar el aislamiento de errores y la depuración.
- **Consecuencias:** Mayor control de calidad, aislamiento seguro de fallos por mapa y registro histórico verificable; requiere disciplina estricta en la gestión de ramas y documentación acumulativa.
- **Revisar cuando:** Se complete la validación del mapa piloto `Blackrock` o se modifique la estrategia de publicación de mapas.
