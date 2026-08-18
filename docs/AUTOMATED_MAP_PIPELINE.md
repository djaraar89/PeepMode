# Pipeline Estandarizado de Conversión de Mapas — PeepMode Factory

Este documento describe la especificación formal y el flujo de trabajo estandarizado para transformar cualquier mapa oficial del ladder de StarCraft II en una edición oficial de **PeepMode** de forma autónoma y reproducible.

---

## 1. Arquitectura del Pipeline

El proceso consta de 7 fases modulares automatizadas:

```
[ Mapa Ladder Limpio ]
         │
         ▼
[ 1. Extracción e Inventario ] ────────► Validación de integridad y dependencias
         │
         ▼
[ 2. Análisis de Geometría ] ──────────► Centro de simetría rotacional 180° y Start Locations
         │
         ▼
[ 3. Inyección de Cámaras ] ───────────► Point 001 a Point 010 calculados matemáticamente
         │
         ▼
[ 4. Fusión de GameData XML ] ─────────► ModelData, SoundData, SoundtrackData y ObjectStrings
         │
         ▼
[ 5. Integración Núcleo PeepMode ] ────► Triggers, Galaxy Script, Layouts, 10 Slots Attributes
         │
         ▼
[ 6. Pantalla de Carga y Textos ] ─────► Textos bilingües + Codificación DDS DXT1 Mipmapped
         │
         ▼
[ 7. Validación y Empaquetado ] ───────► SC2Map monolítico listo para publicación en BNet
```

---

## 2. Parámetros de Simetría y Posicionamiento de Puntos

Dado un mapa con Start Locations $P_1(X_1, Y_1)$ y $P_2(X_2, Y_2)$, el centro de simetría rotacional es:
$$X_c = \frac{X_1 + X_2}{2}, \quad Y_c = \frac{Y_1 + Y_2}{2}$$

La transformación para cualquier punto $P(X, Y)$ hacia su contraparte simétrica $P'(X', Y')$ es:
$$X' = 2X_c - X, \quad Y' = 2Y_c - Y$$

### Funciones de los Puntos Estándar:
* **`Point 001` / `Point 002`:** Cámara de la base principal P1/P2 (desplazamiento 5u hacia el centro enfocando Town Hall y minerales).
* **`Point 003` / `Point 004`:** Paneo de bienvenida P1/P2 (posicionado en el cuello de la rampa de salida).
* **`Point 005` / `Point 006`:** Cámara de la expansión natural P1/P2 (centro del Town Hall de la natural).
* **`Point 007` / `Point 009`:** Puntos cinemáticos de Faceoff en la zona central abierta (radio 20u desde el centro).
* **`Point 008` / `Point 010`:** Puntos auxiliares cuadrangulares para soporte de modos multijugador extendidos.

---

## 3. Ejecución del Pipeline Automatizado

Para procesar cualquier mapa nuevo de ladder de forma completamente automática:

```powershell
.\tools\Build-PeepModeMap.ps1 `
    -CleanMapPath "C:/SC2-PeepMode-Lab/sample-map/clean-components/SampleMap.SC2Map" `
    -OutputDir "C:/SC2-PeepMode-Lab/sample-map/prototype/PeepVoid_SampleMap_LE.SC2Map" `
    -MapTitle "Sample Map LE" `
    -MapAuthor "Map Maker" `
    -LoadingImagePng "C:/path/to/custom_loading_screen.png"
```

---

## 4. Publicación en Battle.net (Todos los Servidores)

Para desplegar la versión definitiva a nivel global:
1. Abrir el archivo empaquetado final `.SC2Map` en el Editor de SC2.
2. Ir a **`File → Publish...`**.
3. Seleccionar región: **Americas**, **Europe** y **Asia** sucesivamente.
4. Establecer visibilidad **Public** y guardar.