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

## DEC-0002 — 2026-08-18 — Topología de remotos Git

- **Estado:** aceptada
- **Contexto:** El repositorio local fue clonado originalmente desde `Kelzorz/PeepMode.git` (asignado como `origin`), mientras `upstream` ya apuntaba al repositorio raíz de `ktilkath/PeepMode.git`. Para realizar publicaciones remotas y pull requests sin permisos de escritura directos sobre el repositorio de Kelzorz (que genera error HTTP 403), se requiere un fork personal como destino de escritura sin perder las referencias upstream.
- **Decisión:** Establecer una topología de tres remotos con roles claramente delimitados:
  1. `origin` (`https://github.com/djaraar89/PeepMode.git`): Fork personal con permisos de escritura donde se publicarán todas las ramas de integración y trabajo.
  2. `kelzorz` (`https://github.com/Kelzorz/PeepMode.git`): Repositorio base funcional del proyecto PeepMode del cual se obtienen actualizaciones y al cual se dirigirán eventualmente los pull requests.
  3. `upstream` (`https://github.com/ktilkath/PeepMode.git`): Repositorio raíz histórico original de PeepMode.
  4. Queda estrictamente prohibido realizar operaciones de `git push` hacia `kelzorz` o hacia `upstream`.
- **Motivo:** Garantizar un destino remoto escribible para respaldar y compartir el progreso del proyecto, preservando simultáneamente la capacidad de sincronización con la base activa (`kelzorz`) y el historial raíz (`upstream`).
- **Alternativas consideradas:**
  - *Sobrescribir `upstream` con Kelzorz y usar `origin` para el fork:* descartada para no perder la referencia histórica al repositorio original de ktilkath y evitar colisiones de nombrado.
  - *Intentar push directo a Kelzorz:* descartada por falta de credenciales de mantenedor (error 403).
- **Consecuencias:** Permite el flujo de publicación seguro vía forks y pull requests; exige verificar explícitamente el destino de los comandos `git push` para apuntar siempre a `origin`.
- **Revisar cuando:** Se modifique la titularidad del repositorio de desarrollo o se integren nuevos mantenedores principales.

