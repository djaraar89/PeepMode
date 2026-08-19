# Pipeline Estandarizado de Conversión de Mapas — PeepMode Factory V2

Este documento describe la especificación formal y el flujo de trabajo estandarizado para transformar cualquier mapa oficial del ladder de StarCraft II en una edición de **PeepMode** de forma segura, determinista y reproducible mediante **PeepMode Factory V2**.

---

## 1. Arquitectura de Factory V2

PeepMode Factory V2 (`tools/Build-PeepModeMap.ps1`) implementa una separación estricta entre operaciones automatizadas seguras, propuestas geométricas heurísticas, coordenadas validadas manualmente y compuertas de seguridad para publicación.

```
                  [ Mapa Ladder Limpio (SC2Components) ]
                                     │
                                     ▼
                      [ Carga de Configuración JSON ]
                       (tools/map-configs/<Map>.json)
                                     │
                                     ├────────► ¿Geometría heurística sin revisar?
                                     │          ├── SI y sin -AllowHeuristicGeometry ──► [ BLOQUEO: Exit Code 4 ]
                                     │          └── NO o con -AllowHeuristicGeometry ──► Continuar
                                     ▼
                    [ 1. Copia de Base Ladder Invariable ]
                                     │
                                     ▼
                    [ 2. Inyección Segura en Objects ]
                     (IDs >= 100000001 sin colisiones)
                                     │
                                     ▼
                    [ 3. Fusión Determinista GameData XML ]
                     (ModelData, SoundData, ActorData, etc.)
                                     │
                                     ▼
                    [ 4. Fusión Determinista ObjectStrings ]
                     (Preservación de claves ladder + PeepMode)
                                     │
                                     ▼
                    [ 5. Integración de Núcleo y Layouts ]
                     (Triggers, Galaxy, Layouts, MP3/M3 multimedia)
                                     │
                                     ▼
                    [ 6. Inyección de Texturas (Assets/Textures) ]
                     (125 texturas sin anidamiento anómalo)
                                     │
                                     ▼
                    [ 7. Textos Sanitizados (GameStrings.txt) ]
                     (Eliminación total de PII / metadatos de autor)
                                     │
                                     ▼
                    [ 8. Manifiesto y Reportes (SHA-256) ]
                     (BUILD_MANIFEST.csv, GEOMETRY_REVIEW.md, BUILD_REPORT.md)
                                     │
                                     ▼
                    [ Puerta del Editor SC2 (Empaquetado) ]
                     (Compilación Galaxy Triggers + Monolito SC2Map)
```

---

## 2. Clasificación de Operaciones y Responsabilidades

| Categoría | Operaciones Comprendidas | Nivel de Automatización |
|---|---|:---:|
| **Automáticas Seguras** | Copia de componentes invariables, fusión XML no destructiva, fusión de cadenas `ObjectStrings.txt`, inyección de layouts `.SC2Layout`, copia de multimedia (`JelloPlanet.mp3`, `Splat-Custom.m3`), copia de texturas (`Assets/Textures/`), generación de manifiesto SHA-256. | 100% Autónomo |
| **Propuestas Heurísticas** | Estimación preliminar de simetría rotacional 180°, cálculo de cámaras principales (`Point 001`/`002`), rampa (`Point 003`/`004`) y faceoff central (`Point 007` a `010`). | Prototipo (Requiere `-AllowHeuristicGeometry`) |
| **Geometría Validada** | Coordenadas exactas de cámaras de expansión natural (`Point 005`/`006`) y ajustes finos de faceoff revisados en el motor de juego y almacenados en `tools/map-configs/<Map>.json`. | Configuración JSON Aprobada |
| **Puerta del Editor SC2** | Compilación final de Triggers a `MapScript.galaxy`, serialización binaria de `MapInfo` a 10 slots (desde `Attributes`) y empaquetado a contenedor `.SC2Map`. | Manual / Supervisado |

> [!IMPORTANT]
> **Política de MapInfo y Salida PRE_EDITOR_ONLY:**
> Factory V2 genera una estructura de componentes en estado **`PRE_EDITOR_ONLY`**. El archivo binario `MapInfo` conserva la cabecera de 2 slots del mapa limpio, mientras que `Attributes` define las variantes de 10 slots. La serialización binaria de `MapInfo` a 10 slots y la compilación de `MapScript.galaxy` se ejecutan exclusivamente al abrir y guardar en el Editor de StarCraft II. **Está estrictamente prohibido publicar directamente una salida no empaquetada de Factory.**

---

## 3. Interfaz de Parámetros y Códigos de Salida

### Parámetros Principales de `Build-PeepModeMap.ps1`

* `-CleanMapPath <String>`: Ruta absoluta al directorio de componentes del mapa ladder limpio.
* `-OutputDir <String>`: Ruta absoluta al directorio de componentes de salida.
* `-MapTitle <String>`: Título oficial del mapa (ej. `"Blackrock LE"`).
* `-MapAuthor <String>`: Autor oficial del mapa (por defecto `"Blizzard Entertainment"`).
* `-MapConfigPath <String>`: Ruta al archivo de configuración JSON validado del mapa.
* `-DryRun`: Ejecuta la simulación completa sin escribir archivos en disco.
* `-ValidateOnly`: Audita de forma exhaustiva una carpeta construida comprobando estructura, texturas, layouts y puntos.
* `-Force`: Permite recrear el directorio de salida si ya existía.
* `-AllowHeuristicGeometry`: Permite la construcción de prototipos de laboratorio con puntos heurísticos no revisados.
* `-LoadingImageDds <String>`: Pantalla de carga personalizada en formato `.dds`.
* `-LoadingImagePng <String>`: Pantalla de carga en formato `.png` (requiere `-DdsConverterPath`).
* `-LogPath <String>`: Ruta donde guardar el log de ejecución.

### Códigos de Salida Estandarizados

| Código | Significado | Causa Típica |
|:---:|---|---|
| `0` | **Éxito** | Construcción, simulación (`DryRun`) o auditoría (`ValidateOnly`) completada sin errores. |
| `1` | **Parámetros Inválidos** | Faltan parámetros obligatorios, rutas inexistentes o combinaciones incompatibles. |
| `2` | **Estructura SC2 Inválida** | Faltan Start Locations en mapa limpio, faltan archivos en núcleo, o falla validación estructural. |
| `3` | **Violación de Seguridad de Salida** | Intento de escribir en la raíz del repo, en `src/Published/`, en la entrada o carpeta existente sin `-Force`. |
| `4` | **Release Gate Bloqueado** | Existen puntos de cámara heurísticos sin validar y no se especificó `-AllowHeuristicGeometry`. |
| `5` | **Colisión en Objects** | Detección de colisión de nombres o IDs de objetos en el archivo `Objects`. |
| `6` | **Fallo de Conversor DDS** | Error en la ejecución de la herramienta externa de conversión de imágenes. |

---

## 4. Esquema de Configuración JSON por Mapa

Cada mapa oficial cuenta con un archivo de configuración en `tools/map-configs/<MapTitle>.json` validado contra el esquema formal `tools/schemas/peepmode-map-config.schema.json`.

Ejemplo (`tools/map-configs/Blackrock.LE.json`):

```json
{
  "$schema": "../schemas/peepmode-map-config.schema.json",
  "schemaVersion": "2.0.0",
  "mapTitle": "Blackrock LE",
  "mapAuthor": "AVEX",
  "symmetryType": "Rotational180",
  "symmetryCenter": { "x": 89.0, "y": 95.0, "source": "calculated-midpoint" },
  "mapInfoStrategy": "PreserveLadderWithEditorGate",
  "gameDataConflictPolicy": "FailOnConflict",
  "points": {
    "Point 001": { "x": 141.0, "y": 142.5, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 002": { "x": 37.0, "y": 47.5, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 003": { "x": 133.0, "y": 137.0, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 004": { "x": 45.0, "y": 53.0, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 005": { "x": 111.5222, "y": 150.615, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 006": { "x": 66.4775, "y": 39.3847, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 007": { "x": 133.4274, "y": 140.6655, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 008": { "x": 105.0, "y": 83.0, "z": 0.0, "source": "symmetry-inferred", "reviewed": true },
    "Point 009": { "x": 44.5722, "y": 49.3344, "z": 0.0, "source": "manual-validated", "reviewed": true },
    "Point 010": { "x": 73.0, "y": 107.0, "z": 0.0, "source": "symmetry-inferred", "reviewed": true }
  },
  "reviewStatus": {
    "geometryReviewed": true,
    "reviewer": "PeepMode Team Validation",
    "reviewDate": "2026-08-19"
  }
}
```

---

## 5. Flujo de Trabajo para Nuevos Mapas

### Paso 1: Prototipado Heurístico (Laboratorio)
Generar la primera versión con simetría estimada para inspección visual:
```powershell
.\tools\Build-PeepModeMap.ps1 `
    -CleanMapPath "C:/SC2-PeepMode-Lab/<map>/clean-components/<Map>.SC2Map" `
    -OutputDir "C:/SC2-PeepMode-Lab/<map>/prototype/<Map>_Proto.SC2Map" `
    -MapTitle "<Map Title>" `
    -AllowHeuristicGeometry `
    -Force
```

### Paso 2: Validación de Geometría
1. Abrir el prototipo en el Editor de StarCraft II.
2. Comprobar la ubicación de los Town Halls naturales (`Point 005` y `Point 006`).
3. Crear o actualizar `tools/map-configs/<MapTitle>.json` con las coordenadas verificadas y marcar `"reviewed": true`.

### Paso 3: Construcción de Producción Validada
Construir con la configuración revisada pasando el Release Gate:
```powershell
.\tools\Build-PeepModeMap.ps1 `
    -CleanMapPath "C:/SC2-PeepMode-Lab/<map>/clean-components/<Map>.SC2Map" `
    -OutputDir "C:/SC2-PeepMode-Lab/<map>/build/<Map>_V2.SC2Map" `
    -MapConfigPath "tools/map-configs/<MapTitle>.json" `
    -Force
```

### Paso 4: Validación y Empaquetado
1. Ejecutar auditoría automatizada:
   ```powershell
   .\tools\Build-PeepModeMap.ps1 -OutputDir "C:/SC2-PeepMode-Lab/<map>/build/<Map>_V2.SC2Map" -ValidateOnly
   ```
2. Abrir en el Editor de SC2 para compilar scripts Galaxy y guardar como `.SC2Map` monolítico final.

---

## 6. Validación Dinámica de Cadenas de Objetos (ObjectStrings.txt)

A partir de la versión 1.1.3, `ValidateOnly` utiliza un algoritmo de validación dinámica por unión exacta de claves:

1. **Derivación de Claves:** Se calculan las claves esperadas uniendo dinámicamente las cadenas del mapa limpio (`$CleanMapPath`) y las 33 cadenas declarativas del núcleo PeepMode (`SC2Components.SC2Map`).
2. **Detección de Conflictos (Exit Code 5):** Si una clave común entre el mapa limpio y el núcleo posee valores divergentes, la validación aborta con código 5.
3. **Comprobación de Salida (Exit Code 2):** Se verifica que la salida contenga el 100% de las claves esperadas, con valores idénticos, sin claves duplicadas y sin claves inesperadas.
4. **Independencia del Map Pool:** No existen umbrales mínimos fijos ni acoplamiento a la cantidad de cadenas de un mapa particular (ej. Blackrock = 93 claves, Washout = 33 claves).

---

## 7. Requisitos de Configuración Pre-Publicación en el Editor

Para cada nuevo mapa procesado, al abrir en el Editor de StarCraft II antes de la publicación final en Arcade, deben aplicarse obligatoriamente las tres configuraciones estandarizadas (DEC-0008):

1. **Publishing Options:** En `Map Properties → Options`, seleccionar **`(*) Arcade Map`** (desactiva automáticamente `Automatically Add Multiplayer Data` y evita el bloqueo de dependencias de Blizzard).
2. **Estructura de 10 Slots:** En `Map → Player Properties` (`Ctrl + Shift + P`), definir **Player 1 al Player 10** con `Control: User`, y en `Map → Game Variants` verificar que la variante `Other - PeepMode` tenga `Max Team Size: 10` y los 10 jugadores incluidos.
3. **Supresión de Cuenta Regresiva:** Marcar `[x] Disable Countdown Timer` en `Map Properties → Options` y en `Map → Game Variants` (fijando `Flags2 = 0x01` en `MapInfo`), permitiendo que el mapa arranque de inmediato en la cinemática de Faceoff de PeepMode sin la cuenta regresiva 3-2-1 del motor de SC2.