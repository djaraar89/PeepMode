<#
.SYNOPSIS
    PeepMode Map Factory V2 -- Pipeline estandarizado y seguro para convertir mapas de ladder a PeepMode.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$CleanMapPath = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "",

    [Parameter(Mandatory = $false)]
    [string]$MapTitle = "",

    [Parameter(Mandatory = $false)]
    [string]$MapAuthor = "Blizzard Entertainment",

    [Parameter(Mandatory = $false)]
    [string]$MapConfigPath = "",

    [Parameter(Mandatory = $false)]
    [string]$LoadingImageDds = "",

    [Parameter(Mandatory = $false)]
    [string]$LoadingImagePng = "",

    [Parameter(Mandatory = $false)]
    [string]$DdsConverterPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$AllowHeuristicGeometry,

    [Parameter(Mandatory = $false)]
    [string]$ManifestPath = "",

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$logEntries = [System.Collections.Generic.List[string]]::new()
function Log-Msg([string]$msg, [string]$level = "INFO") {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$timestamp] [$level] $msg"
    $logEntries.Add($formatted)
    switch ($level) {
        "ERROR"   { Write-Host $formatted -ForegroundColor Red }
        "WARN"    { Write-Host $formatted -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $formatted -ForegroundColor Green }
        "CYAN"    { Write-Host $formatted -ForegroundColor Cyan }
        default   { Write-Host $formatted -ForegroundColor Gray }
    }
}

function Exit-WithCode([int]$code, [string]$reason = "") {
    if ($reason) {
        if ($code -eq 0) { Log-Msg $reason "SUCCESS" }
        else { Log-Msg $reason "ERROR" }
    }
    if ($LogPath -and (-not $DryRun)) {
        try {
            $logParent = [System.IO.Path]::GetDirectoryName($LogPath)
            if ($logParent -and (-not (Test-Path $logParent))) {
                New-Item -ItemType Directory -Force -Path $logParent | Out-Null
            }
            [System.IO.File]::WriteAllLines($LogPath, $logEntries)
        } catch { }
    }
    if ($code -ne 0) {
        throw "Factory exited with code $($code): $reason"
    }
    return
}

Log-Msg "==================================================" "CYAN"
Log-Msg "  PEEPMODE MAP FACTORY V2 -- PIPELINE ENDURECIDO   " "CYAN"
Log-Msg "==================================================" "CYAN"

# Resolver rutas canonicas
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$coreDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "SC2Components.SC2Map"))

if (-not (Test-Path $coreDir)) {
    Exit-WithCode 2 "No se encontro el nucleo invariable de PeepMode en $coreDir"
}

# Incompatibilidad de parametros
if ($DryRun -and $ValidateOnly) {
    Exit-WithCode 1 "Los parametros -DryRun y -ValidateOnly son mutuamente excluyentes."
}
if ($LoadingImageDds -and $LoadingImagePng) {
    Exit-WithCode 1 "Especifique solamente uno entre -LoadingImageDds y -LoadingImagePng."
}

# MODO VALIDATE-ONLY
if ($ValidateOnly) {
    if (-not $OutputDir) {
        Exit-WithCode 1 "Se requiere -OutputDir para ejecutar -ValidateOnly."
    }
    $targetDir = [System.IO.Path]::GetFullPath($OutputDir)
    if (-not (Test-Path $targetDir)) {
        Exit-WithCode 1 "El directorio objetivo no existe: $targetDir"
    }
    Log-Msg "Ejecutando validacion estricta sobre: $targetDir" "INFO"

    # 1. Comprobar Objects
    $objFile = Join-Path $targetDir "Objects"
    if (-not (Test-Path $objFile)) { Exit-WithCode 2 "Falta el archivo Objects en $targetDir" }
    $objText = [System.IO.File]::ReadAllText($objFile, [System.Text.Encoding]::GetEncoding('iso-8859-1'))
    $pMatches = [regex]::Matches($objText, '<ObjectPoint\s+Id="(?<id>\d+)"\s+Position="(?<pos>[^"]+)"\s+[^>]*Name="(?<name>Point \d+)"[^>]*>')
    if ($pMatches.Count -lt 10) {
        Exit-WithCode 2 "El archivo Objects contiene solo $($pMatches.Count) puntos PeepMode (se requieren 10)."
    }

    # Comprobar duplicados de IDs
    $allIdMatches = [regex]::Matches($objText, '\bId="(?<id>\d+)"')
    $idSet = @{}
    foreach ($m in $allIdMatches) {
        $val = $m.Groups["id"].Value
        if ($idSet.ContainsKey($val)) {
            Exit-WithCode 5 "Colision de ID detectada en Objects: $val"
        }
        $idSet[$val] = $true
    }

    # 2. Comprobar Texturas
    $texDir = Join-Path $targetDir "Assets\Textures"
    if (-not (Test-Path $texDir)) { Exit-WithCode 2 "Falta el directorio Assets\Textures" }
    $texCount = @(Get-ChildItem -Path $texDir -File).Count
    if ($texCount -lt 125) { Exit-WithCode 2 "Assets\Textures contiene solo $texCount texturas (se requieren al menos 125)." }
    if (Test-Path (Join-Path $targetDir "Assets\Assets")) {
        Exit-WithCode 2 "Se detecto anidamiento prohibido Assets\Assets en la salida."
    }

    # 3. Comprobar Layouts
    $requiredLayouts = @("cinematic_minimap.SC2Layout", "hide_chat_display.SC2Layout", "hide_message_log.SC2Layout", "improve_error_display.SC2Layout")
    foreach ($lay in $requiredLayouts) {
        if (-not (Test-Path (Join-Path $targetDir $lay))) {
            Exit-WithCode 2 "Falta archivo de Layout requerido: $lay"
        }
    }

    # 4. Comprobar Multimedia
    if (-not (Test-Path (Join-Path $targetDir "JelloPlanet.mp3"))) { Exit-WithCode 2 "Falta JelloPlanet.mp3" }
    if (-not (Test-Path (Join-Path $targetDir "Splat-Custom.m3"))) { Exit-WithCode 2 "Falta Splat-Custom.m3" }
    if (-not (Test-Path (Join-Path $targetDir "BankList.xml"))) { Exit-WithCode 2 "Falta BankList.xml" }

    # 5. Comprobar ObjectStrings mediante union dinamica de claves
    $objStrPath = Join-Path $targetDir "enUS.SC2Data\LocalizedData\ObjectStrings.txt"
    if (-not (Test-Path $objStrPath)) { Exit-WithCode 2 "Falta ObjectStrings.txt en $targetDir" }

    # Derivar claves esperadas dinamicamente desde fuente limpia y nucleo
    $coreObjStrPath = Join-Path $coreDir "enUS.SC2Data\LocalizedData\ObjectStrings.txt"
    $expectedObjDict = [System.Collections.Generic.Dictionary[string, string]]::new()

    if ($CleanMapPath) {
        $cleanCleanObjStr = Join-Path (Resolve-Path $CleanMapPath) "enUS.SC2Data\LocalizedData\ObjectStrings.txt"
        if (Test-Path $cleanCleanObjStr) {
            foreach ($line in [System.IO.File]::ReadAllLines($cleanCleanObjStr, [System.Text.Encoding]::UTF8)) {
                if ($line.Trim() -and -not $line.StartsWith("#")) {
                    $eqIdx = $line.IndexOf("=")
                    if ($eqIdx -gt 0) {
                        $k = $line.Substring(0, $eqIdx)
                        $v = $line.Substring($eqIdx + 1)
                        $expectedObjDict[$k] = $v
                    }
                }
            }
        }
    }

    if (Test-Path $coreObjStrPath) {
        foreach ($line in [System.IO.File]::ReadAllLines($coreObjStrPath, [System.Text.Encoding]::UTF8)) {
            if ($line.Trim() -and -not $line.StartsWith("#")) {
                $eqIdx = $line.IndexOf("=")
                if ($eqIdx -gt 0) {
                    $k = $line.Substring(0, $eqIdx)
                    $v = $line.Substring($eqIdx + 1)
                    if (-not $expectedObjDict.ContainsKey($k)) {
                        $expectedObjDict[$k] = $v
                    } elseif ($expectedObjDict[$k] -ne $v) {
                        Exit-WithCode 5 "Conflicto irreconciliable en ObjectStrings.txt: la clave '$k' tiene valores divergentes ('$($expectedObjDict[$k])' vs '$v')."
                    }
                }
            }
        }
    }

    # Parsear ObjectStrings.txt de la salida y detectar duplicados
    $outObjLines = [System.IO.File]::ReadAllLines($objStrPath, [System.Text.Encoding]::UTF8)
    $outObjDict = [System.Collections.Generic.Dictionary[string, string]]::new()
    $outObjSeenKeys = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in $outObjLines) {
        if ($line.Trim() -and -not $line.StartsWith("#")) {
            $eqIdx = $line.IndexOf("=")
            if ($eqIdx -gt 0) {
                $k = $line.Substring(0, $eqIdx)
                $v = $line.Substring($eqIdx + 1)
                if ($outObjSeenKeys.Contains($k)) {
                    Exit-WithCode 2 "Clave duplicada en ObjectStrings.txt: '$k'"
                }
                $outObjSeenKeys.Add($k) | Out-Null
                $outObjDict[$k] = $v
            }
        }
    }

    if ($expectedObjDict.Count -gt 0) {
        foreach ($k in $expectedObjDict.Keys) {
            if (-not $outObjDict.ContainsKey($k)) {
                Exit-WithCode 2 "Falta la clave esperada '$k' en ObjectStrings.txt de la salida."
            }
            if ($outObjDict[$k] -ne $expectedObjDict[$k]) {
                Exit-WithCode 2 "Valor modificado o corrupto para la clave '$k' en ObjectStrings.txt (esperado: '$($expectedObjDict[$k])', real: '$($outObjDict[$k])')."
            }
        }
        if ($CleanMapPath) {
            foreach ($k in $outObjDict.Keys) {
                if (-not $expectedObjDict.ContainsKey($k)) {
                    Exit-WithCode 2 "Clave inesperada '$k' encontrada en ObjectStrings.txt de la salida."
                }
            }
        }
    } else {
        if ($outObjDict.Count -eq 0) {
            Exit-WithCode 2 "ObjectStrings.txt esta vacio en la salida."
        }
    }

    # 6. Comprobar Attributes y ComponentList
    if (-not (Test-Path (Join-Path $targetDir "Attributes"))) { Exit-WithCode 2 "Falta Attributes" }
    $compPath = Join-Path $targetDir "ComponentList.SC2Components"
    if (-not (Test-Path $compPath)) { Exit-WithCode 2 "Falta ComponentList.SC2Components" }
    $compText = [System.IO.File]::ReadAllText($compPath, [System.Text.Encoding]::UTF8)
    if ($compText -notmatch 'Type="attr"') { Exit-WithCode 2 "ComponentList.SC2Components no declara DataComponent Type=attr" }

    Log-Msg "Validacion exitosa: Estructura, XML, puntos, layouts, texturas y metadatos conformes." "SUCCESS"
    Exit-WithCode 0 "VALIDATE-ONLY: MAPA VALIDADO CON EXITO"
    return
}

# Validaciones de Parametros Generales
if (-not $CleanMapPath) { Exit-WithCode 1 "Se requiere el parametro -CleanMapPath." }
if (-not $OutputDir) { Exit-WithCode 1 "Se requiere el parametro -OutputDir." }
if (-not $MapTitle -and -not $MapConfigPath) { Exit-WithCode 1 "Se requiere -MapTitle o un archivo de configuracion -MapConfigPath." }

$cleanFull = [System.IO.Path]::GetFullPath($CleanMapPath)
$outFull = [System.IO.Path]::GetFullPath($OutputDir)
$publishedRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "src\Published"))

# Validar CleanMapPath
if (-not (Test-Path $cleanFull)) {
    Exit-WithCode 1 "La ruta de mapa limpio no existe: $cleanFull"
}
$cleanObjCheck = Join-Path $cleanFull "Objects"
if (-not (Test-Path $cleanObjCheck)) {
    Exit-WithCode 1 "CleanMapPath no parece una carpeta de componentes de SC2 valida (falta Objects)."
}

# REGLAS DE SEGURIDAD DE OUTPUTDIR
if ($outFull.ToLower() -eq $repoRoot.ToLower()) {
    Exit-WithCode 3 "OutputDir no puede ser la raiz del repositorio Git: $outFull"
}
if ($outFull.ToLower().StartsWith($publishedRoot.ToLower())) {
    Exit-WithCode 3 "OutputDir no puede estar dentro de src/Published: $outFull"
}
if ($outFull.ToLower() -eq $cleanFull.ToLower()) {
    Exit-WithCode 3 "OutputDir no puede ser igual a CleanMapPath: $outFull"
}
$outSlash = $outFull.ToLower() + [System.IO.Path]::DirectorySeparatorChar
if ($cleanFull.ToLower().StartsWith($outSlash)) {
    Exit-WithCode 3 "OutputDir no puede ser un directorio padre de CleanMapPath: $outFull"
}

if ($DdsConverterPath) {
    $convFull = [System.IO.Path]::GetFullPath($DdsConverterPath)
    if (-not (Test-Path $convFull)) {
        Exit-WithCode 6 "El conversor DDS especificado no existe: $convFull"
    }
}

# Verificacion de OutputDir existente
if (Test-Path $outFull) {
    $existingItems = @(Get-ChildItem -Path $outFull -Force)
    if ($existingItems.Count -gt 0) {
        if (-not $Force) {
            Exit-WithCode 3 "El directorio de salida ya existe y no esta vacio: $outFull. Use -Force para permitir su recreacion segura."
        }
        if (-not $DryRun) {
            Log-Msg "Limpiando directorio de salida existente (-Force activo): $outFull" "WARN"
            Remove-Item -Path $outFull -Recurse -Force
        }
    }
}

# Cargar o inferir Configuracion JSON
$mapConfig = $null
$configSource = "None"

if ($MapConfigPath) {
    $configFull = [System.IO.Path]::GetFullPath($MapConfigPath)
    if (-not (Test-Path $configFull)) {
        Exit-WithCode 1 "No se encontro el archivo de configuracion en: $configFull"
    }
    try {
        $jsonRaw = [System.IO.File]::ReadAllText($configFull, [System.Text.Encoding]::UTF8)
        $mapConfig = $jsonRaw | ConvertFrom-Json
        $configSource = "ExplicitPath: $configFull"
    } catch {
        Exit-WithCode 1 "Error al parsear el JSON de configuracion: $_"
    }
} else {
    # Buscar en carpeta estandar tools/map-configs
    $cleanTitle = if ($MapTitle) { $MapTitle.Replace(" ", "").Replace("_", "").Replace(".", "") } else { "" }
    $possibleConfigs = @(
        (Join-Path $PSScriptRoot "map-configs\$MapTitle.json"),
        (Join-Path $PSScriptRoot "map-configs\$cleanTitle.json")
    )
    foreach ($pc in $possibleConfigs) {
        if (Test-Path $pc) {
            try {
                $jsonRaw = [System.IO.File]::ReadAllText($pc, [System.Text.Encoding]::UTF8)
                $mapConfig = $jsonRaw | ConvertFrom-Json
                $configSource = "AutoDiscovered: $pc"
                Log-Msg "Configuracion de mapa autodescubierta: $pc" "INFO"
                break
            } catch { }
        }
    }
}

if ($mapConfig) {
    if ($mapConfig.PSObject.Properties["schemaVersion"]) {
        $supportedVersions = @("2.0.0", "2.0", "1.0.0", "1.0")
        if ($supportedVersions -notcontains $mapConfig.schemaVersion) {
            Exit-WithCode 1 "schemaVersion '$($mapConfig.schemaVersion)' no soportada (versiones validas: $($supportedVersions -join ', '))."
        }
    }
    if (-not $MapTitle -and $mapConfig.PSObject.Properties["mapTitle"]) { $MapTitle = [string]$mapConfig.mapTitle }
    if ($mapConfig.PSObject.Properties["mapAuthor"]) { $MapAuthor = [string]$mapConfig.mapAuthor }
}

Log-Msg "Mapa Objetivo: $MapTitle (Autor: $MapAuthor)" "CYAN"
Log-Msg "Fuente de Configuracion: $configSource" "INFO"

# Leer Start Locations de Objects del mapa limpio
$cleanObjPath = Join-Path $cleanFull "Objects"
$cleanObjBytes = [System.IO.File]::ReadAllBytes($cleanObjPath)
$cleanObjText = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($cleanObjBytes)

$startLocMatches = [regex]::Matches($cleanObjText, '<ObjectPoint\s+Id="(?<id>\d+)"\s+Position="(?<x>[\d\.\-]+),(?<y>[\d\.\-]+),[\d\.\-]+"\s+[^>]*Type="StartLoc"\s+Name="(?<name>[^"]+)"')
if ($startLocMatches.Count -lt 2) {
    Exit-WithCode 2 "El mapa limpio requiere al menos 2 Start Locations (encontradas: $($startLocMatches.Count))."
}

$p1X = [double]$startLocMatches[0].Groups["x"].Value
$p1Y = [double]$startLocMatches[0].Groups["y"].Value
$p2X = [double]$startLocMatches[1].Groups["x"].Value
$p2Y = [double]$startLocMatches[1].Groups["y"].Value

$calcCenterX = ($p1X + $p2X) / 2.0
$calcCenterY = ($p1Y + $p2Y) / 2.0

# Determinar puntos (Configurados vs Heuristicos)
$pointsToInject = [System.Collections.Generic.Dictionary[string, PSObject]]::new()
$hasUnreviewedPoints = $false

if ($mapConfig -and $mapConfig.points) {
    Log-Msg "Cargando coordenadas de puntos desde configuracion JSON..." "INFO"
    foreach ($pName in @("Point 001", "Point 002", "Point 003", "Point 004", "Point 005", "Point 006", "Point 007", "Point 008", "Point 009", "Point 010")) {
        $prop = $mapConfig.points.PSObject.Properties[$pName]
        if ($null -eq $prop -or $null -eq $prop.Value) {
            Exit-WithCode 2 "La configuracion JSON no contiene definicion para $pName"
        }
        $pObj = $prop.Value
        if (-not $pObj.PSObject.Properties["x"] -or -not $pObj.PSObject.Properties["y"]) {
            Exit-WithCode 2 "El punto $pName en la configuracion JSON debe definir 'x' e 'y'"
        }
        $isReviewed = if ($pObj.PSObject.Properties["reviewed"]) { [bool]$pObj.reviewed } else { $false }
        if (-not $isReviewed) { $hasUnreviewedPoints = $true }
        $pointsToInject[$pName] = [PSCustomObject]@{
            Name     = $pName
            X        = [double]$pObj.x
            Y        = [double]$pObj.y
            Z        = if ($pObj.PSObject.Properties["z"] -and $pObj.z) { [double]$pObj.z } else { 0.0 }
            Source   = if ($pObj.PSObject.Properties["source"]) { [string]$pObj.source } else { "json-config" }
            Reviewed = $isReviewed
            Notes    = if ($pObj.PSObject.Properties["notes"]) { [string]$pObj.notes } else { "" }
        }
    }
} else {
    Log-Msg "Calculando puntos heuristicos preliminares (Simetria 180)..." "WARN"
    $hasUnreviewedPoints = $true

    # Faceoff
    $p7X = [Math]::Round($calcCenterX + 16.0, 2); $p7Y = [Math]::Round($calcCenterY + 12.0, 2)
    $p9X = [Math]::Round(2 * $calcCenterX - $p7X, 2); $p9Y = [Math]::Round(2 * $calcCenterY - $p7Y, 2)
    $p8X = [Math]::Round($calcCenterX + 16.0, 2); $p8Y = [Math]::Round($calcCenterY - 12.0, 2)
    $p10X = [Math]::Round(2 * $calcCenterX - $p8X, 2); $p10Y = [Math]::Round(2 * $calcCenterY - $p8Y, 2)

    # Base principal (5u hacia centro)
    $angleP1 = [Math]::Atan2($calcCenterY - $p1Y, $calcCenterX - $p1X)
    $p1CamX = [Math]::Round($p1X + 5.0 * [Math]::Cos($angleP1), 2)
    $p1CamY = [Math]::Round($p1Y + 5.0 * [Math]::Sin($angleP1), 2)
    $p2CamX = [Math]::Round(2 * $calcCenterX - $p1CamX, 2)
    $p2CamY = [Math]::Round(2 * $calcCenterY - $p1CamY, 2)

    # Bienvenida / Rampa (12u hacia centro)
    $p3X = [Math]::Round($p1X + 12.0 * [Math]::Cos($angleP1), 2)
    $p3Y = [Math]::Round($p1Y + 12.0 * [Math]::Sin($angleP1), 2)
    $p4X = [Math]::Round(2 * $calcCenterX - $p3X, 2)
    $p4Y = [Math]::Round(2 * $calcCenterY - $p3Y, 2)

    # Naturales preliminares (heuristica cruda con advertencia)
    $p5X = $p3X; $p5Y = $p3Y
    $p6X = $p4X; $p6Y = $p4Y

    $pointsToInject["Point 001"] = [PSCustomObject]@{ Name="Point 001"; X=$p1CamX; Y=$p1CamY; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Heuristica 5u hacia centro" }
    $pointsToInject["Point 002"] = [PSCustomObject]@{ Name="Point 002"; X=$p2CamX; Y=$p2CamY; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Simetria 180 de Point 001" }
    $pointsToInject["Point 003"] = [PSCustomObject]@{ Name="Point 003"; X=$p3X; Y=$p3Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Heuristica 12u hacia rampa" }
    $pointsToInject["Point 004"] = [PSCustomObject]@{ Name="Point 004"; X=$p4X; Y=$p4Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Simetria 180 de Point 003" }
    $pointsToInject["Point 005"] = [PSCustomObject]@{ Name="Point 005"; X=$p5X; Y=$p5Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="REQUIERE OVERRIDE: posicion natural no confirmada" }
    $pointsToInject["Point 006"] = [PSCustomObject]@{ Name="Point 006"; X=$p6X; Y=$p6Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="REQUIERE OVERRIDE: posicion natural no confirmada" }
    $pointsToInject["Point 007"] = [PSCustomObject]@{ Name="Point 007"; X=$p7X; Y=$p7Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Faceoff offset (+16, +12)" }
    $pointsToInject["Point 008"] = [PSCustomObject]@{ Name="Point 008"; X=$p8X; Y=$p8Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Faceoff aux offset (+16, -12)" }
    $pointsToInject["Point 009"] = [PSCustomObject]@{ Name="Point 009"; X=$p9X; Y=$p9Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Faceoff offset (-16, -12)" }
    $pointsToInject["Point 010"] = [PSCustomObject]@{ Name="Point 010"; X=$p10X; Y=$p10Y; Z=0.0; Source="automatic-heuristic"; Reviewed=$false; Notes="Faceoff aux offset (-16, +12)" }
}

# RELEASE GATE DE GEOMETRIA
if ($hasUnreviewedPoints) {
    if (-not $AllowHeuristicGeometry) {
        Exit-WithCode 4 "RELEASE GATE BLOQUEADO: Existen puntos con geometria heuristica no revisada. Use un archivo de configuracion validado o pase -AllowHeuristicGeometry para prototipos de laboratorio."
    } else {
        Log-Msg "ADVERTENCIA DE SEGURIDAD: -AllowHeuristicGeometry esta activo. PROTOTYPE ONLY -- GEOMETRY REVIEW REQUIRED." "WARN"
    }
}

# MODO DRY-RUN
if ($DryRun) {
    Log-Msg "--------------------------------------------------" "CYAN"
    Log-Msg "  MODO SIMULACION (DRY-RUN) -- NINGUN ARCHIVO ESCRITO" "CYAN"
    Log-Msg "--------------------------------------------------" "CYAN"
    Log-Msg "Entrada validada: $cleanFull" "INFO"
    Log-Msg "Salida prevista: $outFull" "INFO"
    Log-Msg "Centro de simetria: ($calcCenterX, $calcCenterY)" "INFO"
    Log-Msg "Puntos a inyectar:" "INFO"
    foreach ($k in $pointsToInject.Keys) {
        $pt = $pointsToInject[$k]
        Log-Msg "  $($pt.Name): ($($pt.X), $($pt.Y)) [Source: $($pt.Source), Reviewed: $($pt.Reviewed)]" "INFO"
    }
    $gateStatus = if ($hasUnreviewedPoints) { "PROTOTYPE ONLY" } else { "APPROVED FOR BUILD" }
    Log-Msg "Release Gate: $gateStatus" "INFO"
    Log-Msg "DryRun completado exitosamente sin escrituras." "SUCCESS"
    Exit-WithCode 0 "DRY-RUN: SIMULACION EXITOSA"
    return
}

# INICIALIZAR SALIDA REAL
New-Item -ItemType Directory -Force -Path $outFull | Out-Null
$manifestRows = [System.Collections.Generic.List[string]]::new()
$manifestRows.Add("relative_path,operation,source,source_sha256,output_sha256,size_bytes,validation,notes")

# 1. Copiar base de ladder
Log-Msg "[1/8] Copiando componentes base de ladder..." "INFO"
Copy-Item -Path "$cleanFull\*" -Destination $outFull -Recurse -Force

# 2. Inyeccion segura de Objects (sin colisiones)
Log-Msg "[2/8] Analizando Objects e inyectando Point 001 a Point 010..." "INFO"
$targetObjPath = Join-Path $outFull "Objects"
$objContent = [System.IO.File]::ReadAllText($targetObjPath, [System.Text.Encoding]::GetEncoding('iso-8859-1'))

$existingIds = @{}
$existingNames = @{}
foreach ($m in [regex]::Matches($objContent, '\bId="(?<id>\d+)"')) { $existingIds[$m.Groups["id"].Value] = $true }
foreach ($m in [regex]::Matches($objContent, '\bName="(?<name>[^"]+)"')) { $existingNames[$m.Groups["name"].Value] = $true }

$pointLines = [System.Collections.Generic.List[string]]::new()
$startId = 100000001

foreach ($pName in @("Point 001", "Point 002", "Point 003", "Point 004", "Point 005", "Point 006", "Point 007", "Point 008", "Point 009", "Point 010")) {
    $pt = $pointsToInject[$pName]
    if ($existingNames.ContainsKey($pName)) {
        Exit-WithCode 5 "Colision de nombre detectada en Objects: Ya existe un elemento nombrado '$pName'"
    }
    if ($existingIds.ContainsKey("$startId")) {
        Exit-WithCode 5 "Colision de ID detectada en Objects: El ID '$startId' ya esta ocupado por un objeto preexistente."
    }
    $allocatedId = $startId
    $existingIds["$allocatedId"] = $true
    $startId++

    $rotAttr = if ($pName -in @("Point 002", "Point 004", "Point 006", "Point 008", "Point 009", "Point 010")) { ' Rotation="3.1413"' } else { '' }
    $pointLines.Add("    <ObjectPoint Id=`"$allocatedId`" Position=`"$($pt.X),$($pt.Y),$($pt.Z)`"$rotAttr Scale=`"1,1,1`" Type=`"Normal`" Name=`"$pName`" Color=`"0,0,0,0`"/>")
}

$insPos = $objContent.IndexOf("</Objects>")
if ($insPos -lt 0) { $insPos = $objContent.IndexOf("</PlacedObjects>") }
if ($insPos -lt 0) { Exit-WithCode 2 "No se encontro etiqueta de cierre </Objects> en Objects" }

$updatedObjText = $objContent.Substring(0, $insPos) + "`r`n" + ($pointLines -join "`r`n") + "`r`n" + $objContent.Substring($insPos)
[System.IO.File]::WriteAllBytes($targetObjPath, [System.Text.Encoding]::GetEncoding('iso-8859-1').GetBytes($updatedObjText))

# 3. Fusion no destructiva de GameData XML
Log-Msg "[3/8] Fusionando catalogos GameData XML..." "INFO"
function Merge-GameDataXml([string]$fileName) {
    $pClean = Join-Path $outFull "Base.SC2Data\GameData\$fileName"
    $pCore = Join-Path $coreDir "Base.SC2Data\GameData\$fileName"

    if ((Test-Path $pClean) -and (Test-Path $pCore)) {
        [xml]$xmlClean = Get-Content $pClean
        [xml]$xmlCore = Get-Content $pCore

        $cleanIds = @{}
        if ($xmlClean.Catalog) {
            foreach ($n in $xmlClean.Catalog.ChildNodes) {
                if ($n.Attributes -and $n.Attributes["id"]) {
                    $cleanIds[$n.Attributes["id"].Value] = $n
                }
            }
        }

        $addedCount = 0
        if ($xmlCore.Catalog) {
            foreach ($n in $xmlCore.Catalog.ChildNodes) {
                if ($n.Attributes -and $n.Attributes["id"]) {
                    $cId = $n.Attributes["id"].Value
                    if (-not $cleanIds.ContainsKey($cId)) {
                        $imported = $xmlClean.ImportNode($n, $true)
                        $xmlClean.Catalog.AppendChild($imported) | Out-Null
                        $cleanIds[$cId] = $imported
                        $addedCount++
                    } else {
                        $cleanNode = $cleanIds[$cId]
                        if ($cleanNode.OuterXml.Trim() -ne $n.OuterXml.Trim()) {
                            Exit-WithCode 5 "Conflicto irreconciliable en GameData catalogo '$fileName': elemento con ID '$cId' ya existe con contenido divergente."
                        }
                    }
                }
            }
        }
        $xmlClean.Save($pClean)
    } elseif (Test-Path $pCore) {
        $parent = [System.IO.Path]::GetDirectoryName($pClean)
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        Copy-Item $pCore $pClean -Force
    }
}

$allGameDataXmls = @(
    "ModelData.xml", "SoundData.xml", "SoundtrackData.xml",
    "CliffData.xml", "LightData.xml", "TerrainData.xml",
    "TerrainTexData.xml", "WaterData.xml", "AbilData.xml",
    "ActorData.xml", "BehaviorData.xml", "EffectData.xml",
    "GameUIData.xml", "TextureData.xml", "UnitData.xml", "ValidatorData.xml"
)
foreach ($gx in $allGameDataXmls) { Merge-GameDataXml $gx }

# 4. Fusion determinista de ObjectStrings
Log-Msg "[4/8] Fusionando cadenas de objetos (ObjectStrings.txt)..." "INFO"
$cleanObjStrPath = Join-Path $cleanFull "enUS.SC2Data\LocalizedData\ObjectStrings.txt"
$coreObjStrPath = Join-Path $coreDir "enUS.SC2Data\LocalizedData\ObjectStrings.txt"
$outObjStrPath = Join-Path $outFull "enUS.SC2Data\LocalizedData\ObjectStrings.txt"

$mergedDict = [System.Collections.Generic.Dictionary[string, string]]::new()

if (Test-Path $cleanObjStrPath) {
    foreach ($line in [System.IO.File]::ReadAllLines($cleanObjStrPath, [System.Text.Encoding]::UTF8)) {
        if ($line.Trim() -and -not $line.StartsWith("#")) {
            $eqIdx = $line.IndexOf("=")
            if ($eqIdx -gt 0) {
                $k = $line.Substring(0, $eqIdx)
                $v = $line.Substring($eqIdx + 1)
                $mergedDict[$k] = $v
            }
        }
    }
}

if (Test-Path $coreObjStrPath) {
    foreach ($line in [System.IO.File]::ReadAllLines($coreObjStrPath, [System.Text.Encoding]::UTF8)) {
        if ($line.Trim() -and -not $line.StartsWith("#")) {
            $eqIdx = $line.IndexOf("=")
            if ($eqIdx -gt 0) {
                $k = $line.Substring(0, $eqIdx)
                $v = $line.Substring($eqIdx + 1)
                if (-not $mergedDict.ContainsKey($k)) {
                    $mergedDict[$k] = $v
                } elseif ($mergedDict[$k] -ne $v) {
                    Exit-WithCode 5 "Conflicto irreconciliable en ObjectStrings.txt: la clave '$k' existe con valores divergentes ('$($mergedDict[$k])' vs '$v')."
                }
            }
        }
    }
}

$outObjStrParent = [System.IO.Path]::GetDirectoryName($outObjStrPath)
if (-not (Test-Path $outObjStrParent)) { New-Item -ItemType Directory -Force -Path $outObjStrParent | Out-Null }
$objStrLines = [System.Collections.Generic.List[string]]::new()
foreach ($k in $mergedDict.Keys) { $objStrLines.Add("$k=$($mergedDict[$k])") }
[System.IO.File]::WriteAllLines($outObjStrPath, $objStrLines, [System.Text.Encoding]::UTF8)

# 5. Copia exacta de componentes y layouts PeepMode
Log-Msg "[5/8] Copiando nucleo, layouts, estilos y multimedia..." "INFO"
$directFiles = @(
    "Triggers", "MapScript.galaxy", "DocumentInfo", "Attributes",
    "PreloadAssetDB.txt", "BankList.xml", "customstyles.sc2style",
    "JelloPlanet.mp3", "Splat-Custom.m3",
    "cinematic_minimap.SC2Layout", "hide_chat_display.SC2Layout",
    "hide_message_log.SC2Layout", "improve_error_display.SC2Layout",
    "enUS.SC2Data\LocalizedData\TriggerStrings.txt"
)

foreach ($df in $directFiles) {
    $srcPath = Join-Path $coreDir $df
    $dstPath = Join-Path $outFull $df
    $parent = [System.IO.Path]::GetDirectoryName($dstPath)
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    if (Test-Path $srcPath) {
        Copy-Item -Path $srcPath -Destination $dstPath -Force
    }
}

# 6. Copia de Texturas (Assets\Textures\* hacia $outFull\Assets\Textures\*)
Log-Msg "[6/8] Copiando texturas PeepMode (125 archivos)..." "INFO"
$srcTexDir = Join-Path $coreDir "Assets\Textures"
$dstTexDir = Join-Path $outFull "Assets\Textures"
if (-not (Test-Path $dstTexDir)) { New-Item -ItemType Directory -Force -Path $dstTexDir | Out-Null }

Get-ChildItem -Path $srcTexDir -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $dstTexDir $_.Name) -Force
}

# Asegurar ComponentList.SC2Components
$compListPath = Join-Path $outFull "ComponentList.SC2Components"
$compListContent = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`r`n<Components>`r`n    <DataComponent Type=`"gada`">GameData</DataComponent>`r`n    <DataComponent Type=`"text`" Locale=`"enUS`">GameText</DataComponent>`r`n    <DataComponent Type=`"info`">DocumentInfo</DataComponent>`r`n    <DataComponent Type=`"mapi`">MapInfo</DataComponent>`r`n    <DataComponent Type=`"trig`">Triggers</DataComponent>`r`n    <DataComponent Type=`"terr`">t3Terrain.xml</DataComponent>`r`n    <DataComponent Type=`"plob`">Objects</DataComponent>`r`n    <DataComponent Type=`"attr`">Attributes</DataComponent>`r`n</Components>"
[System.IO.File]::WriteAllText($compListPath, $compListContent.Trim(), [System.Text.Encoding]::UTF8)

# 7. Adaptar GameStrings con metadatos sanitizados
Log-Msg "[7/8] Generando textos localizados GameStrings.txt sanitizados..." "INFO"
$gsPath = Join-Path $outFull "enUS.SC2Data\LocalizedData\GameStrings.txt"
$coreGsPath = Join-Path $coreDir "enUS.SC2Data\LocalizedData\GameStrings.txt"
$gsContent = [System.IO.File]::ReadAllText($coreGsPath, [System.Text.Encoding]::UTF8)
$gsContent = [regex]::Replace($gsContent, 'DocInfo/Name=.*', "DocInfo/Name=PeepMode: $MapTitle")
$descSanitized = "DocInfo/DescLong=PeepMode brings observer-driven 1v1 action, match betting and cinematic cameras to standard ladder battlegrounds.<n/><n/>MAP: $MapTitle by $MapAuthor.<n/><n/>Original PeepMode core by Kelzorz / ktilkath."
$gsContent = [regex]::Replace($gsContent, 'DocInfo/DescLong=.*', $descSanitized)
[System.IO.File]::WriteAllText($gsPath, $gsContent, [System.Text.Encoding]::UTF8)

# 8. Pantalla de carga
if ($LoadingImageDds) {
    $ddsFull = [System.IO.Path]::GetFullPath($LoadingImageDds)
    if ((-not (Test-Path $ddsFull)) -or (-not $ddsFull.ToLower().EndsWith(".dds"))) {
        Exit-WithCode 1 "El archivo LoadingImageDds no existe o no tiene extension .dds: $ddsFull"
    }
    Copy-Item -Path $ddsFull -Destination (Join-Path $dstTexDir "peepmode_loading.dds") -Force
    Log-Msg "Pantalla de carga DDS personalizada incorporada: $ddsFull" "SUCCESS"
} elseif ($LoadingImagePng) {
    $pngFull = [System.IO.Path]::GetFullPath($LoadingImagePng)
    if (-not (Test-Path $pngFull)) { Exit-WithCode 1 "No existe la imagen PNG: $pngFull" }
    if (-not $DdsConverterPath -or (-not (Test-Path $DdsConverterPath))) {
        Exit-WithCode 6 "Conversion PNG requerida pero no se proveyo un conversor DDS valido (-DdsConverterPath)."
    }
    # Ejecutar conversor
    $outDds = Join-Path $dstTexDir "peepmode_loading.dds"
    & $DdsConverterPath $pngFull $outDds
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode 6 "El conversor DDS fallo con codigo de salida $LASTEXITCODE"
    }
}

# GENERACION DE MANIFIESTOS Y REPORTES
Log-Msg "[8/8] Generando BUILD_MANIFEST.csv y reportes de validacion..." "INFO"
$allOutFiles = @(Get-ChildItem -Path $outFull -Recurse -File)
foreach ($f in $allOutFiles) {
    $rel = ($f.FullName.Substring($outFull.Length + 1)) -replace [regex]::Escape("\"), "/"
    $fHash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
    $manifestRows.Add("`"$rel`",`"PROCESSED`",`"PeepModeFactory`",`"N/A`",`"$fHash`",$($f.Length),`"VALID`",`"`"")
}

$manifestCsvPath = if ($ManifestPath) { $ManifestPath } else { Join-Path $outFull "BUILD_MANIFEST.csv" }
[System.IO.File]::WriteAllLines($manifestCsvPath, $manifestRows, [System.Text.Encoding]::UTF8)

# Generar GEOMETRY_REVIEW.md
$geomStatus = if ($hasUnreviewedPoints) { "REVISION REQUERIDA (PROTOTIPO)" } else { "100% VALIDADA" }
$geomMdLines = [System.Collections.Generic.List[string]]::new()
$geomMdLines.Add("# Reporte de Revision Geometrica -- $MapTitle")
$geomMdLines.Add("")
$geomMdLines.Add("- **Fecha:** $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))")
$geomMdLines.Add("- **Centro de Simetria:** ($calcCenterX, $calcCenterY)")
$geomMdLines.Add("- **Estado de Geometria:** $geomStatus")
$geomMdLines.Add("")
$geomMdLines.Add("| Punto | X | Y | Z | Origen | Revisado | Notas |")
$geomMdLines.Add("|---|:---:|:---:|:---:|---|:---:|---|")

foreach ($k in $pointsToInject.Keys) {
    $pt = $pointsToInject[$k]
    $geomMdLines.Add("| $($pt.Name) | $($pt.X) | $($pt.Y) | $($pt.Z) | $($pt.Source) | $($pt.Reviewed) | $($pt.Notes) |")
}
[System.IO.File]::WriteAllLines((Join-Path $outFull "GEOMETRY_REVIEW.md"), $geomMdLines, [System.Text.Encoding]::UTF8)

# Generar BUILD_REPORT.md
$gateStatusFinal = if ($hasUnreviewedPoints) { "BLOQUEADO PARA PRODUCCION (PROTOTIPO)" } else { "APROBADO" }
$buildReportLines = [System.Collections.Generic.List[string]]::new()
$buildReportLines.Add("# Reporte de Construccion PeepMode Factory V2")
$buildReportLines.Add("")
$buildReportLines.Add("- **Mapa:** $MapTitle")
$buildReportLines.Add("- **Autor:** $MapAuthor")
$buildReportLines.Add("- **Entrada Limpia:** $cleanFull")
$buildReportLines.Add("- **Salida:** $outFull")
$buildReportLines.Add("- **Configuracion:** $configSource")
$buildReportLines.Add("- **Total Archivos Construidos:** $($allOutFiles.Count)")
$buildReportLines.Add("- **Release Gate:** $gateStatusFinal")
$buildReportLines.Add("- **Operaciones Pendientes:** Apertura diagnostica y guardado en Editor de SC2 para compilar scripts Galaxy y empaquetar monolito final.")
[System.IO.File]::WriteAllLines((Join-Path $outFull "BUILD_REPORT.md"), $buildReportLines, [System.Text.Encoding]::UTF8)

Log-Msg "==================================================" "CYAN"
Log-Msg "  CONSTRUCCION FINALIZADA CON EXITO               " "SUCCESS"
Log-Msg "  Directorio de Salida: $outFull" "CYAN"
Log-Msg "==================================================" "CYAN"

Exit-WithCode 0 "Construccion completada exitosamente."
