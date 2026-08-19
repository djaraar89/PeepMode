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


## DEC-0003 — 2026-08-18 — Pipeline estandarizado y automatizado para mapas de la rotación

- **Estado:** aceptada
- **Contexto:** Tras completar con éxito el ciclo de ingeniería inversa, inyección y validación del mapa piloto `Blackrock LE` (Experimento 4), se identificó que la metodología de 7 fases puede automatizarse de forma determinista para los mapas restantes del pool de mapas de StarCraft II.
- **Decisión:** Estandarizar la herramienta `tools/Build-PeepModeMap.ps1` como el mecanismo oficial para convertir mapas limpios de ladder a ediciones PeepMode, automatizando:
  1. Extracción e inventario de componentes.
  2. Cálculo del centro geométrico de simetría rotacional 180°.
  3. Inyección de `Point 001` a `Point 010` con rango de IDs seguros (`100000001` a `100000010`).
  4. Fusión no destructiva de catálogos GameData XML y cadenas de objetos.
  5. Incorporación del núcleo invariable de PeepMode (10 slots de atributos, triggers, layouts y Galaxy script).
  6. Adaptación de metadatos bilingües y codificación de pantalla de carga DXT1 con mipmaps.
- **Motivo:** Reducir a cero los errores manuales, acelerar la publicación de la rotación completa y garantizar consistencia binaria y sintáctica en todos los mapas.
- **Alternativas consideradas:**
  - *Continuar con el proceso manual en cada mapa:* descartada por ser lento, propenso a errores de tipeo y requerir intervención repetitiva.
- **Consecuencias:** Permite generar prototipos válidos en segundos y concentrar la intervención del usuario únicamente en la publicación en Battle.net.
- **Revisar cuando:** Se actualice el motor base de PeepMode o se incorporen mapas con más de 2 posiciones de inicio (ej. mapas 4P).

## DEC-0004 — 2026-08-19 — Arquitectura endurecida de PeepMode Factory V2 y separación de responsabilidades

- **Estado:** aceptada
- **Contexto:** La auditoría del Experimento 5A determinó que la primera versión del pipeline (`Build-PeepModeMap.ps1` V1) presentaba defectos estructurales (doble anidamiento en texturas, omisión de layouts y multimedia, fusión incompleta de cadenas, desvío geométrico en expansiones naturales >24u y borrado incondicional de directorios).
- **Decisión:** Implementar y estandarizar **PeepMode Factory V2** bajo los siguientes principios arquitectónicos:
  1. **Separación estricta de responsabilidades:** Distinguir explícitamente entre operaciones automáticas seguras (copia de núcleos, fusión XML/strings, layouts, texturas), propuestas geométricas heurísticas, coordenadas manuales validadas por mapa y compuertas del Editor de SC2.
  2. **Configuraciones de mapa declarativas (JSON):** Centralizar la geometría y metadatos por mapa en `tools/map-configs/<MapTitle>.json` validados contra `tools/schemas/peepmode-map-config.schema.json`.
  3. **Compuertas de seguridad (Release Gates):** Bloqueo automático (Exit Code 4) ante geometrías heurísticas no revisadas, requiriendo `-AllowHeuristicGeometry` exclusivamente para prototipado en laboratorio.
  4. **Protección estricta de rutas de salida:** Prohibición absoluta de escribir en la raíz del repositorio o dentro de `src/Published/`, y exigencia de `-Force` para reutilizar directorios existentes.
  5. **Determinismo e Idempotencia:** Garantizar que múltiples ejecuciones sobre la misma entrada produzcan exactamente los mismos hashes SHA-256 en todos los componentes del mapa.
  6. **Suite de pruebas de regresión:** Integrar `tools/tests/Test-Build-PeepModeMap.ps1` para validar automáticamente el comportamiento de la Factory antes de procesar nuevos mapas.
- **Motivo:** Garantizar la máxima confiabilidad, repetibilidad y seguridad en la conversión de mapas de ladder, eliminando el riesgo de regresiones o corrupción de datos.
- **Alternativas consideradas:**
  - *Mantener scripts heurísticos independientes por mapa:* descartada por alta duplicación de código y mantenimiento insostenible.
  - *Automatizar la apertura del Editor de SC2 sin supervisión:* descartada por inestabilidad de la interfaz gráfica y riesgo de colisiones en Triggers.
- **Consecuencias:** Pipeline 100% reproducible, auditable e idempotente, con pruebas automatizadas y soporte seguro para la rotación completa de mapas.
- **Revisar cuando:** Se incorporen tipos de simetría adicionales (ej. simetría especular / 3 o 4 jugadores) o se modifique la estructura interna de componentes de SC2.

## DEC-0005 — 2026-08-19 — Autoridad Geométrica del Golden Master y Política de Idempotencia de Componentes

- **Estado:** aceptada
- **Contexto:** Durante la auditoría del Experimento 5C se identificó una divergencia histórica entre las propuestas teóricas del plan inicial (`BLACKROCK_PROTOTYPE_PLAN_V2.md`) para los puntos de faceoff Point 007/009 y las coordenadas reales guardadas y probadas en el Golden Master empaquetado (`src/Published/PeepVoid_Blackrock_LE.SC2Map`). Asimismo, se requirió definir una política clara para distinguir la idempotencia de componentes SC2 frente a artefactos de auditoría con marcas temporales.
- **Decisión:**
  1. **Autoridad de Coordenadas:** El Golden Master empaquetado sanitizado actual (`3D3A86CB...`) constituye la **única fuente de verdad autoritativa** para coordenadas y componentes, prevaleciendo sobre cualquier boceto heurístico preliminar.
  2. **Política de Idempotencia de Dos Niveles:** Se establece que todos los componentes de juego SC2 (198 archivos) deben ser estrictamente idempotentes e idénticos bit a bit (0 diferencias de hash SHA-256). Los artefactos de auditoría de entorno (`BUILD_REPORT.md`, `GEOMETRY_REVIEW.md`, `BUILD_MANIFEST.csv`, logs) pueden contener metadatos contextuales (rutas absolutas locales y timestamps de ejecución) y se excluyen de la prueba de idempotencia de juego.
  3. **Estado de MapInfo:** Se documenta formalmente que Factory V2 genera componentes en estado `PRE_EDITOR_ONLY`, donde `Attributes` define las variantes de 10 slots y la serialización final del binario `MapInfo` se completa en el Editor de SC2 como puerta de publicación.
- **Motivo:** Asegurar una referencia técnica inequívoca, eliminar ambigüedades en la validación y blindar el pipeline contra falsos positivos en pruebas de determinismo.
- **Alternativas consideradas:**
  - *Forzar timestamp fijo en todos los reportes de auditoría:* descartada para no perder la trazabilidad de fecha/hora en logs de auditoría en producción.
  - *Adoptar coordenadas de boceto teórico en lugar del mapa publicado:* descartada por causar regresiones visuales en el encuadre de cámaras probado en juego.
- **Consecuencias:** Reglas de validación precisas, suite de 30 tests 100% determinista y base sólida para el segundo mapa.
- **Revisar cuando:** Se incorpore un compilador o serializador nativo de binarios MapInfo sin requerir el Editor de SC2.

## DEC-0006 — 2026-08-19 — Manejo Estricto de Conflictos de Fusión de Datos y Escaneo de Caracteres de Control

- **Estado:** aceptada
- **Contexto:** Durante el cierre técnico del Experimento 5D se evaluó el riesgo de resolución silenciosa ante colisiones de claves en `ObjectStrings.txt` o registros divergentes en catálogos `GameData` XML, así como la posibilidad de bytes de control C0 no visibles introducidos por herramientas de edición.
- **Decisión:**
  1. **Fallo Estricto ante Divergencias (Exit Code 5):** Ante cualquier colisión en `ObjectStrings.txt` (misma clave con valores diferentes) o en catálogos `GameData` XML (mismo ID con contenido XML diferente), la Factory aborta inmediatamente con código de salida 5 en lugar de favorecer silenciosamente a ladder o a PeepMode.
  2. **Política de Caracteres de Control C0:** Se prohíbe la presencia de caracteres de control C0 (0x00–0x08, 0x0B, 0x0C, 0x0E–0x1F) en los archivos del repositorio, garantizando texto plano UTF-8 limpio y portable.
  3. **Límite Explícito de Conversión PNG:** La conversión de imágenes de carga `.png` a `.dds` requiere la provisión explícita de un ejecutable mediante `-DdsConverterPath`, abortando con código 6 si no está disponible, sin simular conversiones ficticias.
- **Motivo:** Evitar corrupciones silenciosas de metadatos, prevenir divergencias de datos no supervisadas y garantizar la integridad estricta del pipeline de compilación.
- **Alternativas consideradas:**
  - *Sobrescribir silenciosamente con valores de PeepMode:* descartada por riesgo de romper strings específicos de ladder no identificados.
  - *Permitir conversor PNG simulado:* descartada por violar la política de validación real verificable.
- **Consecuencias:** Detección instantánea de incompatibilidades en mapas complejos y control absoluto sobre los componentes generados.
- **Revisar cuando:** Se implemente un módulo de resolución interactiva o reglas semánticas de merge configurables por JSON.

## DEC-0007 — 2026-08-19 — Validación Dinámica de ObjectStrings.txt por Unión Exacta de Claves

- **Estado:** aceptada
- **Contexto:** En el Experimento 6D se detectó que la compuerta de validación `ValidateOnly` utilizaba un umbral estático mínimo (`$objStrLines -lt 50`), calibrado específicamente para Blackrock LE (que contenía 60 claves de ladder + 33 de PeepMode = 93 claves). Al procesar mapas limpios con pocas cadenas de ladder (como Washout LE, que solo declara 1 clave para luces), el total fusionado resultante de 33 claves provocaba un falso positivo con código 2 a pesar de que la fusión era 100% íntegra y completa.
- **Decisión:**
  1. **Eliminación de Umbrales Estáticos:** Se elimina cualquier umbral o conteo numérico rígido global para `ObjectStrings.txt`.
  2. **Validación Dinámica por Unión de Claves:** El conjunto esperado de claves se deriva dinámicamente en tiempo de ejecución a partir de la unión exacta entre las claves de la fuente limpia (`$CleanMapPath`) y las del núcleo PeepMode (`$coreDir`).
  3. **Control Estricto de Integridad (Exit Code 2):** Se verifica la presencia obligatoria de todas las claves esperadas, la coincidencia exacta de sus valores, la ausencia de claves duplicadas y la inexistencia de claves inesperadas en la salida. Cualquier discrepancia aborta con código de salida 2.
  4. **Control Estricto de Conflictos de Valor (Exit Code 5):** Si una clave común entre la fuente limpia y el núcleo posee valores divergentes, la validación aborta inmediatamente con código de salida 5.
- **Motivo:** Garantizar que la validación sea universal, agnóstica a la cantidad de cadenas de cada mapa del pool 2026 y matemáticamente rigurosa.
- **Alternativas consideradas:**
  - *Reducir el umbral estático a 33:* descartada por transferir el acoplamiento a Washout y fallar ante cualquier mapa con menos claves.
  - *Omitir la validación de claves en ValidateOnly:* descartada por debilitar las garantías de integridad.
- **Consecuencias:** Validación 100% determinista, escalable a cualquier mapa del pool y cubierta por una suite de 40 pruebas automatizadas.
- **Revisar cuando:** Se incorpore soporte de localización multilingüe adicional fuera de `enUS`.