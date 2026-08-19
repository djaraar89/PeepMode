# Registro de cambios (CHANGELOG)

> Este archivo es un registro acumulativo append-only. Las entradas anteriores no deben modificarse ni eliminarse. Toda corrección debe registrarse mediante una nueva entrada al final.

Actualmente no existen cambios funcionales registrados en el proyecto.

## [Unreleased] — 2026-08-18

### Añadido
- **Mapa Oficial:** Incorporación de `src/Published/PeepVoid_Blackrock_LE.SC2Map` para StarCraft II Legacy of the Void (PeepMode Edition con 10 slots, cámaras cinemáticas, apuestas y pantalla de carga bilingüe).
- **Herramientas de Automatización:** Script `tools/Build-PeepModeMap.ps1` para la conversión y ensamblado automatizado de mapas de ladder a PeepMode.
- **Documentación Técnica:** `docs/AUTOMATED_MAP_PIPELINE.md` con la especificación matemática de simetría rotacional 180°, matrices de inyección de puntos y arquitectura de fusión de catálogos.

## [1.0.1] — 2026-08-19

### Modificado
- **Sanitización de Metadatos:** Corrección de la descripción en `src/Published/PeepVoid_Blackrock_LE.SC2Map` para eliminar información personal (nuevo hash SHA-256: `3D3A86CB0B9154300AEFA656A282E7658DE17B7839AC1862932A8AC68C011026`, 21.486.970 bytes) sin alteraciones funcionales en terreno, triggers ni lógica de juego.

## [1.1.0] — 2026-08-19

### Añadido
- **PeepMode Factory V2:** Rediseño integral de `tools/Build-PeepModeMap.ps1` con arquitectura determinista, 14 parámetros, 6 códigos de salida estandarizados, compuertas de seguridad (`-AllowHeuristicGeometry`), simulación (`-DryRun`) y modo de auditoría estricta (`-ValidateOnly`).
- **Esquema de Configuración JSON:** Esquema JSON formal `tools/schemas/peepmode-map-config.schema.json` y configuración de mapa validada `tools/map-configs/Blackrock.LE.json`.
- **Suite de Pruebas Automatizadas:** `tools/tests/Test-Build-PeepModeMap.ps1` con 9 pruebas de regresión automáticas para validación de compuertas, integridad de paths, prevención de sobrescritura e idempotencia bit a bit.
- **Manifiestos SHA-256:** Generación automática de `BUILD_MANIFEST.csv`, `GEOMETRY_REVIEW.md` y `BUILD_REPORT.md` en cada compilación.

### Corregido
- **Estructura de Texturas:** Corrección del defecto de doble anidamiento de V1 (`Assets/Assets/Textures`), ubicando las 125 texturas directamente en `Assets/Textures/`.
- **Layouts y Multimedia:** Inclusión íntegra en la raíz de los 4 archivos `.SC2Layout`, `JelloPlanet.mp3` y `Splat-Custom.m3`.
- **Fusión de Cadenas:** Fusión determinista no destructiva de `ObjectStrings.txt` integrando las 54 claves de ladder y PeepMode sin pérdida de datos.
- **Geometría de Cámaras:** Eliminación de aproximaciones heurísticas erróneas en expansiones naturales mediante configuraciones JSON validadas.

## [1.1.1] — 2026-08-19

### Añadido
- **Suite de Pruebas Expandida:** Ampliación de `tools/tests/Test-Build-PeepModeMap.ps1` a 30 casos de prueba automatizados cubriendo el 100% de la matriz de seguridad y manejo de errores (códigos 0 a 6).
- **Soporte y Pruebas de Pantalla de Carga:** Validación de parámetros `-LoadingImageDds` y `-LoadingImagePng` con control de conversor DDS.
- **Auditoría Pre-Commit de Golden Master:** Verificación autoritativa de coordenadas de Point 001 a Point 010 y establecimiento de la política formal de idempotencia de componentes SC2.

## [1.1.2] — 2026-08-19

### Añadido
- **Manejo Estricto de Conflictos:** Detección y bloqueo automático (Exit Code 5) ante colisiones de claves en `ObjectStrings.txt` o discrepancias XML en catálogos `GameData`.
- **Suite de Pruebas Ampliada:** 34 pruebas automatizadas en `tools/tests/Test-Build-PeepModeMap.ps1` cubriendo el 100% de los códigos de salida y compuertas de seguridad.
- **Auditoría de Caracteres de Control:** Validación y verificación de ausencia total de bytes de control C0 prohibidos en todos los archivos de trabajo.

## [1.1.3] — 2026-08-19

### Añadido
- **Validación Dinámica de ObjectStrings:** Implementación de algoritmo por unión exacta de claves en `ValidateOnly`, eliminando umbrales mínimos rígidos y desacoplando la validación de la cantidad de cadenas de un mapa particular.
- **Suite de 40 Pruebas Automatizadas:** 6 nuevas pruebas de regresión en `tools/tests/Test-Build-PeepModeMap.ps1` (casos 35 a 40) cubriendo validación de conjuntos exactos, detección de claves eliminadas, valores corruptos, duplicados y conflictos de datos.
- **Configuración Validada de Washout LE:** Incorporación de `tools/map-configs/Washout.LE.json` con 10 puntos de cámara calibrados y simetría rotacional 180° verificada (error < 0.0005 u).