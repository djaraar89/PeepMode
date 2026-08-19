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