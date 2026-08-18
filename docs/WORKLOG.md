# Registro de trabajo (WORKLOG)

> Este archivo es un registro acumulativo append-only. Las entradas anteriores no deben modificarse ni eliminarse. Toda corrección debe registrarse mediante una nueva entrada al final.

## 2026-08-18 13:25 — Inicialización de infraestructura y flujo de trabajo protegido

- **Rama:** `integration/2026-map-pool`
- **Commit base:** `a0af730d63dc74d8a936d1ac8d31eb1831950ada`
- **Objetivo:** Establecer la infraestructura de seguridad del proyecto, versionar la Workspace Rule, crear la rama de integración `integration/2026-map-pool` e inicializar los registros acumulativos append-only sin introducir modificaciones funcionales.
- **Estado previo:** Repositorio en rama `master` en commit `a0af730`, sin registros documentales acumulativos ni Workspace Rule versionada.
- **Archivos modificados:**
  - `.agents/rules/peepmodeseguridadpermanente.md`
  - `docs/WORKLOG.md`
  - `CHANGELOG.md`
  - `docs/DECISIONS.md`
- **Cambios realizados:**
  - Creación y verificación de la rama de trabajo `integration/2026-map-pool` a partir de `master`.
  - Inclusión y versionado de la Workspace Rule de seguridad permanente en `.agents/rules/peepmodeseguridadpermanente.md`.
  - Creación del registro acumulativo append-only `docs/WORKLOG.md` con esta entrada inicial.
  - Creación del registro acumulativo `CHANGELOG.md` con aviso de ausencia de cambios funcionales iniciales.
  - Creación del registro acumulativo `docs/DECISIONS.md` documentando `DEC-0001` sobre el flujo de trabajo protegido por ramas.
  - Ausencia total de modificaciones funcionales en PeepMode y ausencia total de operaciones con el Editor de SC2.
- **Operaciones del Editor de SC2:** `Ninguna`
- **Validaciones ejecutadas:**
  - Auditoría de estado Git, remotos e historial (`git rev-parse`, `git status`, `git remote -v`, `git log`).
  - Confirmación de rama activa segura `integration/2026-map-pool`.
  - Verificación estricta de diffs (`git diff`) confirmando la ausencia de cambios en código fuente, mapas, datos, triggers y recursos funcionales.
- **Resultado:** exitoso
- **Evidencia:** Rama activa `integration/2026-map-pool` creada limpiamente sobre commit base `a0af730`. Archivos de infraestructura creados según las especificaciones append-only.
- **Problemas conocidos:** `Ninguno detectado`
- **Próximo paso recomendado:** Preparar la rama de trabajo dedicada para el mapa piloto `Blackrock` y realizar la auditoría inicial de sus componentes.
- **Mensaje de commit propuesto:** `chore: establish protected workflow and project logs`

## 2026-08-18 13:37 — Configuración de fork personal y topología de remotos

- **Rama:** `integration/2026-map-pool`
- **Commit base:** `3fdbb467ecbfa50f6dd90562e604f8664ea6e885`
- **Objetivo:** Configurar el fork personal como remoto escribible `origin`, reasignar `Kelzorz/PeepMode` al remoto `kelzorz`, preservar `ktilkath/PeepMode` en `upstream` y preparar la publicación segura de la rama de integración.
- **Estado previo:** `origin` apuntaba al repositorio de upstream de Kelzorz (`https://github.com/Kelzorz/PeepMode.git`), impidiendo la publicación directa por falta de permisos de escritura (error HTTP 403) y con imposibilidad de renombrar directamente a `upstream` debido a la preexistencia de `ktilkath/PeepMode.git` bajo dicho nombre.
- **Archivos modificados:**
  - `docs/WORKLOG.md`
  - `docs/DECISIONS.md`
- **Cambios realizados:**
  - Registro de los incidentes previos (intento fallido de publicación directa en Kelzorz con error 403 y conflicto al renombrar a `upstream` por existencia previa del remoto).
  - Creación manual y verificación del fork personal en `https://github.com/djaraar89/PeepMode.git`.
  - Reconfiguración de la topología Git: renombrado del remoto original `origin` a `kelzorz` (`https://github.com/Kelzorz/PeepMode.git`), adición del nuevo remoto `origin` apuntando al fork personal y preservación intacta del remoto `upstream` (`https://github.com/ktilkath/PeepMode.git`).
  - Sincronización de referencias mediante `git fetch --prune` para los tres remotos (`origin`, `kelzorz`, `upstream`).
  - Documentación de la decisión `DEC-0002` en `docs/DECISIONS.md`.
  - Confirmación de cero modificaciones en archivos funcionales de PeepMode y cero operaciones en el Editor de SC2.
- **Operaciones del Editor de SC2:** `Ninguna`
- **Validaciones ejecutadas:**
  - Inspección exhaustiva de remotos (`git remote -v`).
  - Verificación del árbol de trabajo y ramas (`git status --short --branch`, `git branch -vv`).
  - Comprobación de commits inmutables (`git rev-parse master`, `git rev-parse HEAD`).
  - Validación de integridad append-only en registros.
- **Resultado:** exitoso
- **Evidencia:** Remoto `origin` configurado correctamente a `djaraar89/PeepMode.git`, `kelzorz` a `Kelzorz/PeepMode.git` y `upstream` a `ktilkath/PeepMode.git`. Rama `master` intacta en `a0af730`.
- **Problemas conocidos:** `Ninguno detectado`
- **Próximo paso recomendado:** Publicar la rama `integration/2026-map-pool` hacia el remoto `origin` (`djaraar89/PeepMode`).
- **Mensaje de commit propuesto:** `chore: configure personal fork remotes`

## 2026-08-18 13:42 — Creación de rama Blackrock y auditoría arquitectural

- **Rama:** `map/blackrock`
- **Commit base:** `4487f910d2f05e711a0f0e597a80ac4a614b2d4c`
- **Objetivo:** Crear y publicar la rama de trabajo aislada `map/blackrock` y auditar en modo de solo lectura la estructura arquitectural del repositorio, los componentes de PeepMode, el flujo histórico de incorporación de mapas ladder y los riesgos operativos asociados al Editor de StarCraft II.
- **Estado previo:** Rama `integration/2026-map-pool` activa y publicada en `origin`. Sin rama específica para el mapa piloto Blackrock.
- **Archivos modificados:**
  - `docs/WORKLOG.md`
- **Cambios realizados:**
  - Creación de la rama `map/blackrock` a partir de `integration/2026-map-pool` (`4487f91`) y publicación exclusiva en el fork personal `origin`.
  - Auditoría de arquitectura en modo solo lectura de `README.md`, `_config.yml`, `SC2Components.SC2Map/`, `src/` (`Published`/`Deprecated`), `reference/` (`PeepMode.c`, `TriggerMap.md`) y `export/` (`Assets/`, layouts y estilos).
  - Inspección del historial Git de commits de rotación e importación de mapas (`bc03813`, `c688809`, `34d7c0b`, `1994b58`, `653227a`, `e3d0e80`, `f3bc76a`).
  - Identificación de los componentes esenciales de PeepMode (triggers XML de 495k líneas, Galaxy script, GameData XML, layouts de observador, texturas de interfaz y 10 slots de jugador) vs. componentes de mapa ladder base (terreno, mallas de pathing/placement, doodads, iluminación).
  - Formulación de la estrategia preliminar no destructiva y reversible para la integración de Blackrock como mapa piloto.
  - Cero operaciones con el Editor de SC2, cero descargas/importaciones de mapas y cero modificaciones en archivos funcionales.
- **Operaciones del Editor de SC2:** `Ninguna`
- **Validaciones ejecutadas:**
  - Verificación del árbol de trabajo y ramas (`git branch -vv`, `git status --short --branch`, `git rev-parse HEAD`).
  - Verificación de publicación en remoto `origin/map/blackrock`.
  - Comprobación estricta de diffs para garantizar integridad append-only y ausencia total de modificaciones funcionales.
- **Resultado:** exitoso
- **Evidencia:** Rama `map/blackrock` activa con tracking a `origin/map/blackrock`. Arquitectura documentada y comprendida exhaustivamente. Registros append-only íntegros.
- **Problemas conocidos:** `Ninguno detectado`
- **Próximo paso recomendado:** Presentar la propuesta preliminar de incorporación de Blackrock para validación antes de cualquier manipulación de archivos de mapa.
- **Mensaje de commit propuesto:** `docs: record Blackrock branch and architecture audit`



## 2026-08-18 — Experimento 4: Integración, validación y estandarización del mapa piloto Blackrock LE

- **Objetivo:** Completar el ciclo de vida completo de ingeniería inversa, ensamblado de componentes, validación en Editor, prueba funcional local y multijugador, y estandarizar el pipeline automatizado para los mapas de la rotación.
- **Rama activa:** `map/blackrock`
- **Archivos creados o modificados:**
  - `src/Published/PeepVoid_Blackrock_LE.SC2Map` (Versión definitiva para publicación pública)
  - `tools/Build-PeepModeMap.ps1` (Herramienta de automatización end-to-end de mapas PeepMode)
  - `docs/AUTOMATED_MAP_PIPELINE.md` (Especificación técnica del pipeline automatizado)
  - `docs/DECISIONS.md` (DEC-0003)
  - `CHANGELOG.md`
  - `docs/WORKLOG.md`
- **Operaciones del Editor de SC2:**
  - Primera apertura diagnóstica limpia (dependencia `VoidMulti.SC2Mod`, 0 errores XML).
  - Corrección precisa de coordenadas de expansiones naturales (`Point 005` al Oeste de P1, `Point 006` al Este de P2) con simetría rotacional 180° exacta `(89.0, 95.0)`.
  - Configuración nativa de 10 slots activos de jugadores en `MapInfo`.
  - Prueba funcional local (`Ctrl+F9`) validando interfaz, cámaras, apuestas y lógica de juego.
  - Empaquetado a formato `.SC2Map` y verificación round-trip de componentes sin corrupción.
  - Configuración de pantalla de carga bilingüe (Inglés/Español) y codificación DXT1 de texturas.
- **Validaciones ejecutadas:**
  - Verificación estricta de hashes SHA-256 en todas las fases del laboratorio.
  - Comprobación de ausencia total de colisiones en GameData XML y ObjectStrings.
  - Reconciliación de los 4 mensajes de runtime (`AlternateTime`, `ChatDisplayNormal`, `gt_PeriodicBettingCountdowns_Func`, `Observe Everyone`) clasificados como `IDENTICAL_TO_REFERENCE`.
  - Verificación de integridad del repositorio (`git status`).
- **Resultado:** exitoso
- **Evidencia:** `PeepVoid_Blackrock_LE.SC2Map` generado y validado con 10 slots y cero errores de Galaxy. Herramienta `Build-PeepModeMap.ps1` lista para procesar los siguientes mapas.
- **Problemas conocidos:** `Ninguno`
- **Próximo paso recomendado:** Publicación pública global en Battle.net (Americas, Europe, Asia) y aplicación del pipeline automatizado al siguiente mapa de la rotación.
- **Mensaje de commit propuesto:** `feat: publish PeepVoid_Blackrock_LE and establish automated map factory pipeline`