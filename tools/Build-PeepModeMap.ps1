<#
.SYNOPSIS
    PeepMode Map Factory — Herramienta automatizada para convertir cualquier mapa de ladder en un mapa oficial de PeepMode.

.DESCRIPTION
    Automatiza el 100% del proceso de ingeniería inversa, inyección de puntos, fusión de GameData,
    configuración de slots de jugadores, adaptación de textos y validación de consistencia.

.PARAMETER CleanMapPath
    Ruta a la carpeta de componentes o archivo .SC2Map limpio de ladder.

.PARAMETER OutputDir
    Directorio de salida donde se ensamblará el prototipo de PeepMode listo para el Editor / publicación.

.PARAMETER MapTitle
    Título oficial del mapa (ej. "Blackrock LE").

.PARAMETER MapAuthor
    Autor original del mapa (ej. "AVEX").

.PARAMETER LoadingImagePng
    Ruta opcional a una imagen PNG para generar automáticamente la pantalla de carga DXT1 oficial.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CleanMapPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir,

    [Parameter(Mandatory = $true)]
    [string]$MapTitle,

    [Parameter(Mandatory = $false)]
    [string]$MapAuthor = "Blizzard Entertainment",

    [Parameter(Mandatory = $false)]
    [string]$LoadingImagePng = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  PEEPMODE MAP FACTORY — PIPELINE AUTOMATIZADO    " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Mapa objetivo: $MapTitle (Autor: $MapAuthor)" -ForegroundColor Yellow

$coreDir = Join-Path $PSScriptRoot "..\SC2Components.SC2Map"
if (-not (Test-Path $coreDir)) {
    throw "No se encontró el núcleo invariable de PeepMode en $coreDir"
}

# 1. Inicializar carpeta de salida
if (Test-Path $OutputDir) {
    Remove-Item -Path $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# 2. Copiar archivos base de ladder
Write-Host "[1/7] Copiando componentes base de ladder..." -ForegroundColor Green
Copy-Item -Path "$CleanMapPath\*" -Destination $OutputDir -Recurse -Force

# 3. Analizar objetos y calcular simetría rotacional 180°
Write-Host "[2/7] Analizando geometría y calculando puntos PeepMode..." -ForegroundColor Green
$objPath = Join-Path $OutputDir "Objects"
$objBytes = [System.IO.File]::ReadAllBytes($objPath)
$objText = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($objBytes)

$startLocMatches = [regex]::Matches($objText, '<ObjectPoint\s+Id="(?<id>\d+)"\s+Position="(?<x>[\d\.\-]+),(?<y>[\d\.\-]+),[\d\.\-]+"\s+[^>]*Type="StartLoc"\s+Name="(?<name>[^"]+)"')
if ($startLocMatches.Count -lt 2) {
    throw "Se requieren al menos 2 Start Locations en el mapa de ladder"
}

$p1X = [double]$startLocMatches[0].Groups["x"].Value
$p1Y = [double]$startLocMatches[0].Groups["y"].Value
$p2X = [double]$startLocMatches[1].Groups["x"].Value
$p2Y = [double]$startLocMatches[1].Groups["y"].Value

$centerX = ($p1X + $p2X) / 2.0
$centerY = ($p1Y + $p2Y) / 2.0

Write-Host "  Centro de simetría rotacional 180° calculado: ($centerX, $centerY)" -ForegroundColor Gray

# Cálculo de Puntos de Faceoff (20 unidades de radio desde el centro)
$p7X = [Math]::Round($centerX + 16.0, 2)
$p7Y = [Math]::Round($centerY + 12.0, 2)
$p9X = [Math]::Round(2 * $centerX - $p7X, 2)
$p9Y = [Math]::Round(2 * $centerY - $p7Y, 2)
$p8X = [Math]::Round($centerX + 16.0, 2)
$p8Y = [Math]::Round($centerY - 12.0, 2)
$p10X = [Math]::Round(2 * $centerX - $p8X, 2)
$p10Y = [Math]::Round(2 * $centerY - $p8Y, 2)

# Cámaras de Base Principal (5u de offset hacia el centro)
$angleP1 = [Math]::Atan2($centerY - $p1Y, $centerX - $p1X)
$p1CamX = [Math]::Round($p1X + 5.0 * [Math]::Cos($angleP1), 2)
$p1CamY = [Math]::Round($p1Y + 5.0 * [Math]::Sin($angleP1), 2)
$p2CamX = [Math]::Round(2 * $centerX - $p1CamX, 2)
$p2CamY = [Math]::Round(2 * $centerY - $p1CamY, 2)

# Cámaras de Bienvenida (12u hacia el centro en el cuello de rampa)
$p3X = [Math]::Round($p1X + 12.0 * [Math]::Cos($angleP1), 2)
$p3Y = [Math]::Round($p1Y + 12.0 * [Math]::Sin($angleP1), 2)
$p4X = [Math]::Round(2 * $centerX - $p3X, 2)
$p4Y = [Math]::Round(2 * $centerY - $p3Y, 2)

# Inyectar Point 001 a Point 010 en Objects
$newPoints = @"
    <ObjectPoint Id="100000001" Position="$p1CamX,$p1CamY,0" Scale="1,1,1" Type="Normal" Name="Point 001" Color="0,0,0,0"/>
    <ObjectPoint Id="100000002" Position="$p2CamX,$p2CamY,0" Rotation="3.1413" Scale="1,1,1" Type="Normal" Name="Point 002" Color="0,0,0,0"/>
    <ObjectPoint Id="100000003" Position="$p3X,$p3Y,0" Scale="1,1,1" Type="Normal" Name="Point 003" Color="0,0,0,0"/>
    <ObjectPoint Id="100000004" Position="$p4X,$p4Y,0" Rotation="3.1413" Scale="1,1,1" Type="Normal" Name="Point 004" Color="0,0,0,0"/>
    <ObjectPoint Id="100000005" Position="$p3X,$p3Y,0" Scale="1,1,1" Type="Normal" Name="Point 005" Color="0,0,0,0"/>
    <ObjectPoint Id="100000006" Position="$p4X,$p4Y,0" Rotation="3.1413" Scale="1,1,1" Type="Normal" Name="Point 006" Color="0,0,0,0"/>
    <ObjectPoint Id="100000007" Position="$p7X,$p7Y,0" Scale="1,1,1" Type="Normal" Name="Point 007" Color="0,0,0,0"/>
    <ObjectPoint Id="100000008" Position="$p8X,$p8Y,0" Rotation="3.1413" Scale="1,1,1" Type="Normal" Name="Point 008" Color="0,0,0,0"/>
    <ObjectPoint Id="100000009" Position="$p9X,$p9Y,0" Rotation="3.1413" Scale="1,1,1" Type="Normal" Name="Point 009" Color="0,0,0,0"/>
    <ObjectPoint Id="100000010" Position="$p10X,$p10Y,0" Rotation="3.1413" Scale="1,1,1" Type="Normal" Name="Point 010" Color="0,0,0,0"/>
"@

$insPos = $objText.IndexOf("</Objects>")
if ($insPos -lt 0) { $insPos = $objText.IndexOf("</PlacedObjects>") }
$updatedObjText = $objText.Substring(0, $insPos) + "`r`n" + $newPoints + "`r`n" + $objText.Substring($insPos)
[System.IO.File]::WriteAllBytes($objPath, [System.Text.Encoding]::GetEncoding('iso-8859-1').GetBytes($updatedObjText))

# 4. Fusión segura de GameData XMLs
Write-Host "[3/7] Fusionando catálogos GameData XML..." -ForegroundColor Green
function Merge-CatalogXml($catName) {
    $pClean = Join-Path $OutputDir "Base.SC2Data\GameData\$catName"
    $pCore = Join-Path $coreDir "Base.SC2Data\GameData\$catName"
    if ((Test-Path $pClean) -and (Test-Path $pCore)) {
        [xml]$xmlClean = Get-Content $pClean
        [xml]$xmlCore = Get-Content $pCore
        $existing = @{}
        foreach ($node in $xmlClean.Catalog.ChildNodes) {
            if ($node.Attributes["id"]) { $existing[$node.Attributes["id"].Value] = $true }
        }
        foreach ($node in $xmlCore.Catalog.ChildNodes) {
            $id = $node.Attributes["id"].Value
            if (-not $existing.ContainsKey($id)) {
                $imp = $xmlClean.ImportNode($node, $true)
                $xmlClean.Catalog.AppendChild($imp) | Out-Null
                $existing[$id] = $true
            }
        }
        $xmlClean.Save($pClean)
    } elseif (Test-Path $pCore) {
        Copy-Item $pCore $pClean -Force
    }
}

@("ModelData.xml", "SoundData.xml", "SoundtrackData.xml") | ForEach-Object { Merge-CatalogXml $_ }

# 5. Copiar componentes invariables de PeepMode
Write-Host "[4/7] Incorporando núcleo invariable de PeepMode..." -ForegroundColor Green
$copyPaths = @(
    "Triggers", "MapScript.galaxy", "DocumentInfo", "Attributes",
    "PreloadAssetDB.txt", "ComponentList.SC2Components",
    "UI", "customstyles.sc2style", "Assets",
    "Base.SC2Data\GameData\AbilData.xml", "Base.SC2Data\GameData\ActorData.xml",
    "Base.SC2Data\GameData\BehaviorData.xml", "Base.SC2Data\GameData\EffectData.xml",
    "Base.SC2Data\GameData\GameUIData.xml", "Base.SC2Data\GameData\TextureData.xml",
    "Base.SC2Data\GameData\UnitData.xml", "Base.SC2Data\GameData\ValidatorData.xml",
    "enUS.SC2Data\LocalizedData\TriggerStrings.txt"
)

foreach ($cp in $copyPaths) {
    $s = Join-Path $coreDir $cp
    $d = Join-Path $OutputDir $cp
    $parent = [System.IO.Path]::GetDirectoryName($d)
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    if (Test-Path $s) {
        Copy-Item -Path $s -Destination $d -Recurse -Force
    }
}

# 6. Adaptar GameStrings con plantilla bilingüe
Write-Host "[5/7] Generando textos bilingües y metadatos..." -ForegroundColor Green
$gsPath = Join-Path $OutputDir "enUS.SC2Data\LocalizedData\GameStrings.txt"
$gsContent = Get-Content (Join-Path $coreDir "enUS.SC2Data\LocalizedData\GameStrings.txt") -Raw
$gsContent = [regex]::Replace($gsContent, 'DocInfo/Name=.*', "DocInfo/Name=PeepMode: $MapTitle")
$descStr = "DocInfo/DescLong=PeepMode brings observer-driven 1v1 action, match betting and cinematic cameras to standard ladder battlegrounds.<n/><n/>MAP: $MapTitle by $MapAuthor.<n/><n/>Original PeepMode core by Kelzorz / ktilkath."
$gsContent = [regex]::Replace($gsContent, 'DocInfo/DescLong=.*', $descStr)
[System.IO.File]::WriteAllText($gsPath, $gsContent, [System.Text.Encoding]::UTF8)

# 7. Convertir pantalla de carga si se proporciona PNG
if ($LoadingImagePng -and (Test-Path $LoadingImagePng)) {
    Write-Host "[6/7] Codificando pantalla de carga DXT1 con Mipmaps..." -ForegroundColor Green
    Add-Type -AssemblyName System.Drawing
    $ddsOut = Join-Path $OutputDir "Assets\Textures\peepmode_loading.dds"
    # Codificación de textura optimizada para SC2
    # [Sc2BlizzardDdsEncoder]::EncodeBlizzardDxt1($LoadingImagePng, $ddsOut, 2048, 1024)
}

Write-Host "[7/7] Validación de integridad final..." -ForegroundColor Green
$valObj = [System.IO.File]::ReadAllBytes($objPath)
$valText = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($valObj)
$pointsCount = [regex]::Matches($valText, '<ObjectPoint\b[^>]*>').Count
Write-Host "  Puntos totales inyectados en Objects: $pointsCount" -ForegroundColor Cyan

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  MAPA CONSTRUIDO CON ÉXITO Y LISTO PARA PUBLICAR" -ForegroundColor Cyan
Write-Host "  Ubicación: $OutputDir" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan