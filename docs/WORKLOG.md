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

## 2026-08-19 09:05 — Sanitización de metadatos en Blackrock LE (Nuevo Golden Master)

- **Rama:** `map/blackrock`
- **Commit base:** `fb36ab9178cc652aa33f68f55a046e5bcb96848c`
- **Objetivo:** Sanitizar la descripción del mapa `src/Published/PeepVoid_Blackrock_LE.SC2Map` para remover información personal, estableciendo la versión sanitizada como nuevo Golden Master de referencia para el pipeline.
- **Archivos modificados:**
  - `src/Published/PeepVoid_Blackrock_LE.SC2Map`
  - `docs/WORKLOG.md`
  - `CHANGELOG.md`
- **Detalles técnicos de sanitización:**
  - Corrección exclusiva de textos descriptivos para eliminar información personal.
  - Cero alteraciones funcionales en geometría de terreno, mallas de colisión/placement, triggers Galaxy, inyección de cámaras (`Point 001` a `Point 010`), slots de jugadores (10 activos) o lógica de PeepMode.
  - Tamaño final sanitizado: **21.486.970 bytes** (anterior: 21.486.984 bytes).
  - SHA-256 final sanitizado: `3D3A86CB0B9154300AEFA656A282E7658DE17B7839AC1862932A8AC68C011026`.
- **Validaciones ejecutadas:**
  - Verificación de hash SHA-256 y tamaño de archivo en disco.
  - Confirmación de ausencia de cambios colaterales en el árbol de trabajo (`git status`).
- **Resultado:** exitoso
- **Evidencia:** Golden Master de Blackrock LE actualizado y validado con hash `3D3A86CB0B9154300AEFA656A282E7658DE17B7839AC1862932A8AC68C011026`.
- **Mensaje de commit propuesto:** `fix: remove personal information from Blackrock description`

## 2026-08-19 09:20 — Hardening e Implementación de PeepMode Factory V2 (Experimento 5B)

- **Rama:** `factory/hardening-v2`
- **Commit base:** `feee1ef57989392e21b203c9c9b33a042e61a6b0`
- **Objetivo:** Implementar la versión endurecida y determinista de PeepMode Factory V2 (`tools/Build-PeepModeMap.ps1`), resolver los defectos de V1 (anidamiento de texturas, layouts faltantes, multimedia faltante, colisiones de IDs, fusión incompleta de ObjectStrings y desvío de cámaras naturales), incorporar validación por esquema JSON, compuertas de seguridad (Release Gates) y validar el pipeline reconstruyendo Blackrock LE contra el nuevo Golden Master.
- **Archivos modificados / creados:**
  - `tools/Build-PeepModeMap.ps1` (reescritura completa a V2 con 14 parámetros, 6 códigos de salida, Release Gates y auditorías)
  - `tools/schemas/peepmode-map-config.schema.json` (esquema formal JSON Schema v7 para configuraciones de mapas)
  - `tools/map-configs/Blackrock.LE.json` (configuración validada de 10 puntos para Blackrock LE)
  - `tools/tests/Test-Build-PeepModeMap.ps1` (suite de 9 pruebas de regresión automatizadas)
  - `docs/AUTOMATED_MAP_PIPELINE.md` (documentación formal de arquitectura, códigos de salida y flujo de trabajo)
  - `docs/WORKLOG.md` (registro acumulativo append-only)
  - `CHANGELOG.md` (registro acumulativo append-only)
  - `docs/DECISIONS.md` (registro acumulativo append-only DEC-0004)
- **Validaciones ejecutadas:**
  - `Test-Build-PeepModeMap.ps1`: 9 de 9 pruebas automatizadas exitosas (100% OK).
  - Simulación `-DryRun` validada sin efectos colaterales ni escrituras en disco.
  - Reconstrucción de Blackrock LE (Run 1): 201 archivos generados en 784 ms con salida conforme.
  - Comparativa de diferencias (`BLACKROCK_V2_DIFF.csv`): 0 regresiones; defectos de V1 resueltos (125 texturas en `Assets/Textures/`, 4 layouts `.SC2Layout`, multimedia `JelloPlanet.mp3`/`Splat-Custom.m3`, 54 claves de `ObjectStrings.txt`).
  - Validación euclidiana de puntos de cámara: Error = 0.00 en todos los puntos (`Point 001` a `Point 010`).
  - Reconstrucción idempotente (Run 2 e `IDEMPOTENCE_V2_DIFF.csv`): 0 discrepancias en componentes del mapa (100% bit-for-bit idéntico).
  - Auditoría estricta con `-ValidateOnly`: Salida validada con código 0.
- **Resultado:** exitoso
- **Evidencia:** Suite de pruebas en `tools/tests/Test-Build-PeepModeMap.ps1` ejecutada al 100% satisfactoria; reportes y artefactos generados en `C:/SC2-PeepMode-Lab/factory-validation/v2/`.
- **Problemas conocidos:** Ninguno. La compilación de Galaxy triggers y el empaquetado final a contenedor `.SC2Map` monolítico continúan reservados como compuerta de validación supervisada en el Editor de SC2.
- **Próximo paso recomendado:** Integración de Factory V2 en rama de integración y procesamiento del siguiente mapa de la rotación oficial 2026.
- **Mensaje de commit propuesto:** `feat(factory): implement PeepMode Factory V2 with JSON configs, release gates and test suite`

## 2026-08-19 09:48 — Auditoría Pre-Commit de Factory V2 y Golden Master (Experimento 5C)

- **Rama:** `factory/hardening-v2`
- **Commit base:** `3e83f961e05c6f0b5164b1ef3dbf42152ad170e9`
- **Objetivo:** Resolver contradicciones entre coordenadas históricas y el Golden Master, verificar la fuente de verdad autoritativa de componentes, auditar MapInfo y pantalla de carga, expandir la suite de tests a 30 casos y validar la idempotencia bit a bit.
- **Archivos modificados / creados:**
  - `tools/Build-PeepModeMap.ps1` (limpieza de espacios, comprobación segura de propiedades en Strict Mode)
  - `tools/tests/Test-Build-PeepModeMap.ps1` (expansión a suite exhaustiva de 30 casos de prueba)
  - `docs/AUTOMATED_MAP_PIPELINE.md` (declaración de MapInfo como PRE_EDITOR_ONLY y política de idempotencia)
  - `docs/WORKLOG.md` (registro acumulativo append-only)
  - `CHANGELOG.md` (registro acumulativo append-only)
  - `docs/DECISIONS.md` (registro acumulativo append-only DEC-0005)
- **Validaciones ejecutadas:**
  - Golden Master Sanitizado verificado: `src/Published/PeepVoid_Blackrock_LE.SC2Map` (SHA-256: `3D3A86CB0B9154300AEFA656A282E7658DE17B7839AC1862932A8AC68C011026`, 21.486.970 bytes).
  - Exportación de componentes frescos realizada en Editor de SC2 y registrada en `GOLDEN_CURRENT_MANIFEST.csv`.
  - Matriz de autoridad de coordenadas (`POINT_AUTHORITY_MATRIX.csv`): Coordenadas de Point 001 a Point 010 en `tools/map-configs/Blackrock.LE.json` verificadas con Error Euclidiano = 0.0000 contra el Golden Master actual.
  - Reproducción V1 vs V2 (`V1_V2_POINT_REPRODUCTION.csv`): Corrección y aclaración de la tabla de discrepancias de V1 (errores reales reproducidos: Point 001/002: 3.37u, Point 003/004: 2.01u, Point 005/006: 24.42u, Point 007/009: 44.06u).
  - Suite de pruebas de regresión (`Test-Build-PeepModeMap.ps1`): 30 de 30 pruebas automatizadas PASSED (100% OK).
  - Verificación de formato y espacios: `git diff --check` = 0 advertencias.
  - Reconstrucción y validación completa: DryRun exitoso, Run 1 y Run 2 idénticos bit a bit en componentes SC2, ValidateOnly exitoso (Código 0).
- **Resultado:** exitoso
- **Evidencia:** `FACTORY_V2_PRECOMMIT_AUDIT.md`, `POINT_AUTHORITY_MATRIX.csv`, `V1_V2_POINT_REPRODUCTION.csv`, `GOLDEN_CURRENT_MANIFEST.csv`, `IDEMPOTENCE_POLICY.md` en `C:/SC2-PeepMode-Lab/factory-validation/v2/precommit-audit/`.
- **Problemas conocidos:** Ninguno. MapInfo se conserva como `PRE_EDITOR_ONLY` (2 slots en pipeline / 10 slots al compilar en Editor).
- **Próximo paso recomendado:** Realizar commit de Factory V2 en rama `factory/hardening-v2` y proceder con la preparación del segundo mapa de la rotación como prototipo.
- **Mensaje de commit propuesto:** `feat(factory): harden PeepMode Factory V2 with JSON configs, release gates and 30-case test suite`

## 2026-08-19 09:58 — Cierre Técnico Previo al Commit de Factory V2 (Experimento 5D)

- **Rama:** `factory/hardening-v2`
- **Commit base:** `3e83f961e05c6f0b5164b1ef3dbf42152ad170e9`
- **Objetivo:** Ejecutar escaneo exhaustivo de caracteres de control C0, añadir tests independientes para colisiones de ID/nombre y conflictos de GameData/ObjectStrings (fallo estricto con Exit Code 5), clasificar la brecha de 6 componentes Pre-Editor y emitir el dictamen final de Commit Gate.
- **Archivos modificados / creados:**
  - `tools/Build-PeepModeMap.ps1` (bloqueo estricto con Exit Code 5 ante colisiones y divergencias de datos, validación temprana de DdsConverterPath, soporte explícito de schemaVersion 2.0.0 y 1.0.0)
  - `tools/tests/Test-Build-PeepModeMap.ps1` (ampliación a 34 casos de prueba automatizados)
  - `docs/AUTOMATED_MAP_PIPELINE.md` (declaración formal de política de MapInfo y límite PRE_EDITOR_ONLY)
  - `docs/WORKLOG.md` (registro acumulativo append-only)
  - `CHANGELOG.md` (registro acumulativo append-only)
  - `docs/DECISIONS.md` (registro acumulativo append-only DEC-0006)
- **Validaciones ejecutadas:**
  - Escaneo de caracteres de control C0 (`CONTROL_CHARACTER_SCAN.md`): 0 bytes de control inesperados en el 100% de los archivos a incluir en el commit.
  - Suite de pruebas automatizadas (`Test-Build-PeepModeMap.ps1`): 34 de 34 pruebas PASSED (100% OK).
  - Brecha de componentes Pre-Editor (`PRE_EDITOR_COMPONENT_GAP.csv`): 0 archivos clasificados como `UNEXPECTED_MISSING`; las 6 diferencias respecto al Golden Master corresponden a metadatos de versión y empaquetado del Editor de SC2.
  - Determinismo e Idempotencia: 198 de 198 componentes SC2 idénticos bit a bit entre ejecuciones sucesivas.
  - Validación de coordenadas: Error Euclidiano Máximo = 0.0000 u en los 10 puntos respecto al Golden Master sanitizado.
  - `git diff --check`: 0 advertencias de espacios en blanco.
- **Resultado:** exitoso
- **Evidencia:** `FACTORY_V2_COMMIT_GATE.md`, `CONTROL_CHARACTER_SCAN.md`, `PRE_EDITOR_COMPONENT_GAP.csv` en `C:/SC2-PeepMode-Lab/factory-validation/v2/precommit-audit/`.
- **Problemas conocidos:** Ninguno.
- **Próximo paso recomendado:** Realizar el commit formal de Factory V2 en `factory/hardening-v2` e iniciar el trabajo del segundo mapa como prototipo.
- **Mensaje de commit propuesto:** `feat(factory): finalize hardened Factory V2 with 34-test suite, conflict gates and clean pre-editor boundary`