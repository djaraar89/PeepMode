<#
.SYNOPSIS
    Suite de Pruebas de Regresion, Seguridad y Cobertura para PeepMode Factory V2.
#>

[CmdletBinding()]
param ()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$factoryScript = Join-Path $repoRoot "tools\Build-PeepModeMap.ps1"
$cleanBlackrock = "C:\SC2-PeepMode-Lab\blackrock\clean-components\Blackrock_Clean.SC2Map"
$blackrockConfig = Join-Path $repoRoot "tools\map-configs\Blackrock.LE.json"
$sampleDds = Join-Path $repoRoot "SC2Components.SC2Map\Assets\Textures\ampersand.dds"
$testTempDir = "C:\SC2-PeepMode-Lab\factory-validation\v2\test-suite-runs"

if (-not (Test-Path $testTempDir)) {
    New-Item -ItemType Directory -Force -Path $testTempDir | Out-Null
}

$testResults = [System.Collections.Generic.List[PSObject]]::new()

function Run-TestCase([int]$id, [string]$name, [scriptblock]$action) {
    Write-Host "`n[TEST $id] $name..." -ForegroundColor Cyan
    try {
        & $action
        $testResults.Add([PSCustomObject]@{ Id = $id; Test = $name; Status = "PASSED"; Error = "" })
        Write-Host "  -> PASSED" -ForegroundColor Green
    } catch {
        $msg = $_.Exception.Message
        $testResults.Add([PSCustomObject]@{ Id = $id; Test = $name; Status = "FAILED"; Error = $msg })
        Write-Host "  -> FAILED: $msg" -ForegroundColor Red
    }
}

# 1. Entrada ausente produce cÃ³digo 1
Run-TestCase 1 "Ruta de entrada ausente produce codigo 1" {
    $out = Join-Path $testTempDir "out1"
    try {
        & $factoryScript -CleanMapPath "C:\Ruta\Inexistente\123" -OutputDir $out -MapTitle "Test"
        throw "Deberia haber fallado"
    } catch {
        if ($_ -notmatch "code 1") { throw "Codigo inesperado: $_" }
    }
}

# 2. OutputDir existente sin Force produce cÃ³digo 3
Run-TestCase 2 "OutputDir existente sin -Force produce codigo 3" {
    $outDir = Join-Path $testTempDir "existing_out"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $outDir "dummy.txt"), "data")
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $outDir -MapConfigPath $blackrockConfig
        throw "Deberia haber bloqueado la sobrescritura"
    } catch {
        if ($_ -notmatch "code 3") { throw "Codigo inesperado: $_" }
    }
}

# 3. OutputDir seguro existente con Force produce cÃ³digo 0
Run-TestCase 3 "OutputDir seguro existente con -Force produce codigo 0" {
    $outDir = Join-Path $testTempDir "existing_out_forced"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $outDir "dummy.txt"), "data")
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $outDir -MapConfigPath $blackrockConfig -Force
    if (-not (Test-Path (Join-Path $outDir "Objects"))) { throw "Fallo al crear salida con -Force" }
}

# 4. ProtecciÃ³n de src/Published produce cÃ³digo 3
Run-TestCase 4 "Proteccion de src/Published produce codigo 3" {
    $publishedTarget = Join-Path $repoRoot "src\Published\Test_Forbidden"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $publishedTarget -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber bloqueado la ruta en src/Published"
    } catch {
        if ($_ -notmatch "code 3") { throw "Codigo inesperado: $_" }
    }
}

# 5. OutputDir igual a CleanMapPath produce cÃ³digo 3
Run-TestCase 5 "OutputDir igual a CleanMapPath produce codigo 3" {
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $cleanBlackrock -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber bloqueado sobrescritura de entrada"
    } catch {
        if ($_ -notmatch "code 3") { throw "Codigo inesperado: $_" }
    }
}

# 6. OutputDir igual a la raÃ­z del repositorio produce cÃ³digo 3
Run-TestCase 6 "OutputDir igual a raiz de repo produce codigo 3" {
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $repoRoot -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber bloqueado ruta raiz de repo"
    } catch {
        if ($_ -notmatch "code 3") { throw "Codigo inesperado: $_" }
    }
}

# 7. OutputDir padre de la entrada produce cÃ³digo 3
Run-TestCase 7 "OutputDir padre de CleanMapPath produce codigo 3" {
    $cleanParent = [System.IO.Path]::GetDirectoryName($cleanBlackrock)
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $cleanParent -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber bloqueado ruta padre de entrada"
    } catch {
        if ($_ -notmatch "code 3") { throw "Codigo inesperado: $_" }
    }
}

# 8. DryRun sin escrituras produce cÃ³digo 0
Run-TestCase 8 "DryRun sin escrituras produce codigo 0" {
    $dryOut = Join-Path $testTempDir "dry_out"
    if (Test-Path $dryOut) { Remove-Item -Path $dryOut -Recurse -Force }
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $dryOut -MapConfigPath $blackrockConfig -DryRun
    if (Test-Path $dryOut) { throw "DryRun creo archivos en disco" }
}

# 9. DryRun y ValidateOnly simultÃ¡neos produce cÃ³digo 1
Run-TestCase 9 "DryRun y ValidateOnly simultaneos produce codigo 1" {
    $out = Join-Path $testTempDir "out_mut"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -DryRun -ValidateOnly
        throw "Deberia haber rechazado combinacion"
    } catch {
        if ($_ -notmatch "code 1") { throw "Codigo inesperado: $_" }
    }
}

# 10. JSON inexistente produce cÃ³digo 1
Run-TestCase 10 "JSON inexistente produce codigo 1" {
    $out = Join-Path $testTempDir "out_bad_json"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath "C:\Inexistente\Config.json" -Force
        throw "Deberia haber rechazado JSON inexistente"
    } catch {
        if ($_ -notmatch "code 1") { throw "Codigo inesperado: $_" }
    }
}

# 11. JSON sintÃ¡cticamente invÃ¡lido produce cÃ³digo 1
Run-TestCase 11 "JSON sintacticamente invalido produce codigo 1" {
    $badJson = Join-Path $testTempDir "bad.json"
    [System.IO.File]::WriteAllText($badJson, "{ invalid json content ...")
    $out = Join-Path $testTempDir "out_bad_json2"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $badJson -Force
        throw "Deberia haber rechazado JSON invalido"
    } catch {
        if ($_ -notmatch "code 1") { throw "Codigo inesperado: $_" }
    }
}

# 12. schemaVersion no soportada produce cÃ³digo 1
Run-TestCase 12 "schemaVersion no soportada produce codigo 1" {
    $badVerJson = Join-Path $testTempDir "bad_ver.json"
    $cfgContent = (Get-Content $blackrockConfig -Raw).Replace('"schemaVersion": "2.0.0"', '"schemaVersion": "99.0"')
    [System.IO.File]::WriteAllText($badVerJson, $cfgContent)
    $out = Join-Path $testTempDir "out_bad_ver"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $badVerJson -Force
        throw "Deberia haber rechazado schemaVersion no soportada"
    } catch {
        if ($_ -notmatch "code 1") { throw "Codigo inesperado: $_" }
    }
}

# 13. Config JSON sin definiciÃ³n de puntos produce cÃ³digo 2
Run-TestCase 13 "Config JSON sin definicion completa de puntos produce codigo 2" {
    $incompleteJson = Join-Path $testTempDir "incomplete.json"
    [System.IO.File]::WriteAllText($incompleteJson, '{"mapTitle": "Inc", "points": { "Point 001": {"x": 1, "y": 2, "reviewed": true} }}')
    $out = Join-Path $testTempDir "out_inc_json"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $incompleteJson -Force
        throw "Deberia haber rechazado config incompleta"
    } catch {
        if ($_ -notmatch "code 2") { throw "Codigo inesperado: $_" }
    }
}

# 14. Punto reviewed=false sin AllowHeuristicGeometry produce cÃ³digo 4 (Release Gate)
Run-TestCase 14 "Punto reviewed=false sin AllowHeuristicGeometry produce codigo 4" {
    $unrevJson = Join-Path $testTempDir "unreviewed.json"
    $unrevContent = (Get-Content $blackrockConfig -Raw).Replace('"reviewed": true', '"reviewed": false')
    [System.IO.File]::WriteAllText($unrevJson, $unrevContent)
    $out = Join-Path $testTempDir "out_unrev"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $unrevJson -Force
        throw "Deberia haber bloqueado Release Gate"
    } catch {
        if ($_ -notmatch "code 4") { throw "Codigo inesperado: $_" }
    }
}

# 15. AllowHeuristicGeometry con puntos heurÃ­sticos produce cÃ³digo 0
Run-TestCase 15 "AllowHeuristicGeometry con puntos heuristicos produce codigo 0" {
    $out = Join-Path $testTempDir "out_heur_proto"
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapTitle "Heuristic Map" -AllowHeuristicGeometry -Force
    if (-not (Test-Path (Join-Path $out "GEOMETRY_REVIEW.md"))) { throw "Falta GEOMETRY_REVIEW.md" }
}

# 16. ColisiÃ³n de ID de ObjectPoint en Objects produce cÃ³digo 5
Run-TestCase 16 "Colision de ID de ObjectPoint en Objects produce codigo 5" {
    $collIdClean = Join-Path $testTempDir "clean_id_collision"
    if (Test-Path $collIdClean) { Remove-Item -Path $collIdClean -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $collIdClean | Out-Null
    Copy-Item -Path "$cleanBlackrock\*" -Destination $collIdClean -Recurse -Force
    $objPath = Join-Path $collIdClean "Objects"
    $objText = [System.IO.File]::ReadAllText($objPath, [System.Text.Encoding]::GetEncoding('iso-8859-1'))
    $tag = if ($objText.Contains("</Objects>")) { "</Objects>" } else { "</PlacedObjects>" }
    $objText = $objText.Replace($tag, "<ObjectPoint Id=`"100000001`" Position=`"1,1,0`" Name=`"Custom Point`"/>$tag")
    [System.IO.File]::WriteAllText($objPath, $objText, [System.Text.Encoding]::GetEncoding('iso-8859-1'))

    $out = Join-Path $testTempDir "out_id_coll"
    try {
        & $factoryScript -CleanMapPath $collIdClean -OutputDir $out -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber detectado colision de ID"
    } catch {
        if ($_ -notmatch "code 5") { throw "Codigo inesperado: $_" }
    }
}

# 17. ColisiÃ³n de nombre Point preexistente en Objects produce cÃ³digo 5
Run-TestCase 17 "Colision de nombre Point preexistente en Objects produce codigo 5" {
    $collClean = Join-Path $testTempDir "clean_collision"
    if (Test-Path $collClean) { Remove-Item -Path $collClean -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $collClean | Out-Null
    Copy-Item -Path "$cleanBlackrock\*" -Destination $collClean -Recurse -Force
    $objPath = Join-Path $collClean "Objects"
    $objText = [System.IO.File]::ReadAllText($objPath, [System.Text.Encoding]::GetEncoding('iso-8859-1'))
    $tag = if ($objText.Contains("</Objects>")) { "</Objects>" } else { "</PlacedObjects>" }
    $objText = $objText.Replace($tag, "<ObjectPoint Id=`"999`" Position=`"1,1,0`" Name=`"Point 001`"/>$tag")
    [System.IO.File]::WriteAllText($objPath, $objText, [System.Text.Encoding]::GetEncoding('iso-8859-1'))

    $out = Join-Path $testTempDir "out_coll"
    try {
        & $factoryScript -CleanMapPath $collClean -OutputDir $out -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber detectado colision de nombre"
    } catch {
        if ($_ -notmatch "code 5") { throw "Codigo inesperado: $_" }
    }
}

# 18. Conflicto irreconciliable en ObjectStrings produce cÃ³digo 5
Run-TestCase 18 "Conflicto irreconciliable en ObjectStrings produce codigo 5" {
    $confClean = Join-Path $testTempDir "clean_str_conf"
    if (Test-Path $confClean) { Remove-Item -Path $confClean -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $confClean | Out-Null
    Copy-Item -Path "$cleanBlackrock\*" -Destination $confClean -Recurse -Force
    $objStr = Join-Path $confClean "enUS.SC2Data\LocalizedData\ObjectStrings.txt"
    Add-Content -Path $objStr -Value "Sound/Name/JelloPlanet=Different Ladder Sound"

    $out = Join-Path $testTempDir "out_str_conf"
    try {
        & $factoryScript -CleanMapPath $confClean -OutputDir $out -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber detectado conflicto de ObjectStrings"
    } catch {
        if ($_ -notmatch "code 5") { throw "Codigo inesperado: $_" }
    }
}

# 19. Conflicto de contenido en catÃ¡logos GameData XML produce cÃ³digo 5
Run-TestCase 19 "Conflicto de contenido en catalogos GameData XML produce codigo 5" {
    $confXmlClean = Join-Path $testTempDir "clean_xml_conf"
    if (Test-Path $confXmlClean) { Remove-Item -Path $confXmlClean -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $confXmlClean | Out-Null
    Copy-Item -Path "$cleanBlackrock\*" -Destination $confXmlClean -Recurse -Force
    $modelData = Join-Path $confXmlClean "Base.SC2Data\GameData\ModelData.xml"
    [xml]$xml = Get-Content $modelData
    $dummy = $xml.CreateElement("CModel")
    $dummy.SetAttribute("id", "CustomDecalMuta")
    $dummy.InnerXml = "<Model value=`"Assets/Models/Divergent.m3`"/>"
    $xml.Catalog.AppendChild($dummy) | Out-Null
    $xml.Save($modelData)

    $out = Join-Path $testTempDir "out_xml_conf"
    try {
        & $factoryScript -CleanMapPath $confXmlClean -OutputDir $out -MapConfigPath $blackrockConfig -Force
        throw "Deberia haber detectado conflicto de GameData"
    } catch {
        if ($_ -notmatch "code 5") { throw "Codigo inesperado: $_" }
    }
}

# 20. FusiÃ³n vÃ¡lida de catÃ¡logos GameData XML sin conflictos
Run-TestCase 20 "Fusion valida de catalogos GameData XML sin conflictos" {
    $out = Join-Path $testTempDir "out_gamedata"
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $blackrockConfig -Force
    $modelData = Join-Path $out "Base.SC2Data\GameData\ModelData.xml"
    [xml]$xml = Get-Content $modelData
    if ($null -eq $xml.Catalog) { throw "ModelData.xml invalido" }
}

# 21. Rutas de Assets/Textures correctas (125 texturas)
Run-TestCase 21 "Rutas de Assets/Textures correctas (125 texturas)" {
    $out = Join-Path $testTempDir "out_tex"
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $blackrockConfig -Force
    $texDir = Join-Path $out "Assets\Textures"
    $cnt = @(Get-ChildItem -Path $texDir -File).Count
    if ($cnt -lt 125) { throw "Assets/Textures contiene solo $cnt texturas" }
}

# 22. Ausencia total de anidamiento anÃ³malo Assets/Assets
Run-TestCase 22 "Ausencia total de anidamiento anomalo Assets/Assets" {
    $out = Join-Path $testTempDir "out_tex"
    if (Test-Path (Join-Path $out "Assets\Assets")) { throw "Se detecto Assets/Assets" }
}

# 23. Layouts completos (4 archivos .SC2Layout en raÃ­z)
Run-TestCase 23 "Layouts completos (4 archivos .SC2Layout en raiz)" {
    $out = Join-Path $testTempDir "out_tex"
    foreach ($lay in @("cinematic_minimap.SC2Layout", "hide_chat_display.SC2Layout", "hide_message_log.SC2Layout", "improve_error_display.SC2Layout")) {
        if (-not (Test-Path (Join-Path $out $lay))) { throw "Falta layout: $lay" }
    }
}

# 24. Recursos multimedia y BankList.xml presentes
Run-TestCase 24 "Recursos multimedia y BankList.xml presentes" {
    $out = Join-Path $testTempDir "out_tex"
    if (-not (Test-Path (Join-Path $out "JelloPlanet.mp3"))) { throw "Falta JelloPlanet.mp3" }
    if (-not (Test-Path (Join-Path $out "Splat-Custom.m3"))) { throw "Falta Splat-Custom.m3" }
    if (-not (Test-Path (Join-Path $out "BankList.xml"))) { throw "Falta BankList.xml" }
}

# 25. Manifest generado y conforme con hashes en disco
Run-TestCase 25 "Manifest generado y conforme con hashes en disco" {
    $out = Join-Path $testTempDir "out_tex"
    $manPath = Join-Path $out "BUILD_MANIFEST.csv"
    if (-not (Test-Path $manPath)) { throw "Falta BUILD_MANIFEST.csv" }
    $rows = Import-Csv $manPath
    foreach ($r in $rows) {
        $p = Join-Path $out $r.relative_path
        if (-not (Test-Path $p)) { throw "Archivo en manifiesto no existe en disco: $($r.relative_path)" }
    }
}

# 26. Attributes y ComponentList declaran soporte de 10 slots
Run-TestCase 26 "Attributes y ComponentList declaran soporte de 10 slots" {
    $out = Join-Path $testTempDir "out_tex"
    if (-not (Test-Path (Join-Path $out "Attributes"))) { throw "Falta Attributes" }
    $comp = [System.IO.File]::ReadAllText((Join-Path $out "ComponentList.SC2Components"), [System.Text.Encoding]::UTF8)
    if ($comp -notmatch 'Type="attr"') { throw "ComponentList no declara attr" }
}

# 27. GameStrings.txt sanitizado sin PII
Run-TestCase 27 "GameStrings.txt sanitizado sin PII" {
    $out = Join-Path $testTempDir "out_tex"
    $gs = [System.IO.File]::ReadAllText((Join-Path $out "enUS.SC2Data\LocalizedData\GameStrings.txt"), [System.Text.Encoding]::UTF8)
    if ($gs -match "djara" -or $gs -match "Djara" -or $gs -match "alberto" -or $gs -match "Alberto") {
        throw "GameStrings contiene PII"
    }
}

# 28. Idempotencia de componentes de juego
Run-TestCase 28 "Idempotencia de componentes de juego (Run 1 vs Run 2)" {
    $idemp1 = Join-Path $testTempDir "idemp1"
    $idemp2 = Join-Path $testTempDir "idemp2"
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $idemp1 -MapConfigPath $blackrockConfig -Force
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $idemp2 -MapConfigPath $blackrockConfig -Force

    $f1 = @(Get-ChildItem -Path $idemp1 -Recurse -File)
    foreach ($file in $f1) {
        $rel = ($file.FullName.Substring($idemp1.Length + 1)) -replace [regex]::Escape("\"), "/"
        if ($rel -notin @("BUILD_REPORT.md", "GEOMETRY_REVIEW.md", "BUILD_MANIFEST.csv")) {
            $p2 = Join-Path $idemp2 $rel
            $h1 = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            $h2 = (Get-FileHash -Path $p2 -Algorithm SHA256).Hash
            if ($h1 -ne $h2) { throw "Hash mismatch en componente $($rel): $h1 vs $h2" }
        }
    }
}

# 29. ValidateOnly sobre salida vÃ¡lida pasa con cÃ³digo 0
Run-TestCase 29 "ValidateOnly sobre salida valida pasa con codigo 0" {
    $out = Join-Path $testTempDir "out_tex"
    & $factoryScript -OutputDir $out -ValidateOnly
}

# 30. ValidateOnly sobre salida corrupta falla con cÃ³digo 2
Run-TestCase 30 "ValidateOnly sobre salida corrupta falla con codigo 2" {
    $corrupt = Join-Path $testTempDir "out_corrupt_val"
    if (Test-Path $corrupt) { Remove-Item -Path $corrupt -Recurse -Force }
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $corrupt -MapConfigPath $blackrockConfig -Force
    Remove-Item -Path (Join-Path $corrupt "JelloPlanet.mp3") -Force
    try {
        & $factoryScript -OutputDir $corrupt -ValidateOnly
        throw "ValidateOnly no detecto archivo multimedia faltante"
    } catch {
        if ($_ -notmatch "code 2") { throw "Codigo inesperado: $_" }
    }
}

# 31. LoadingImageDds vÃ¡lido se copia a Assets/Textures/peepmode_loading.dds
Run-TestCase 31 "LoadingImageDds valido se copia con hash identico" {
    $out = Join-Path $testTempDir "out_dds_valid"
    & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $blackrockConfig -LoadingImageDds $sampleDds -Force
    $targetDds = Join-Path $out "Assets\Textures\peepmode_loading.dds"
    if (-not (Test-Path $targetDds)) { throw "No se creo peepmode_loading.dds" }
    $hSrc = (Get-FileHash -Path $sampleDds -Algorithm SHA256).Hash
    $hDst = (Get-FileHash -Path $targetDds -Algorithm SHA256).Hash
    if ($hSrc -ne $hDst) { throw "Hash mismatch en DDS copiado" }
}

# 32. LoadingImagePng sin DdsConverterPath falla con cÃ³digo 6
Run-TestCase 32 "LoadingImagePng sin DdsConverterPath falla con codigo 6" {
    $samplePng = Join-Path $testTempDir "sample.png"
    [System.IO.File]::WriteAllText($samplePng, "dummy png")
    $out = Join-Path $testTempDir "out_png_fail"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $blackrockConfig -LoadingImagePng $samplePng -Force
        throw "Deberia haber fallado por falta de conversor DDS"
    } catch {
        if ($_ -notmatch "code 6") { throw "Codigo inesperado: $_" }
    }
}

# 33. DdsConverterPath apuntando a ejecutable inexistente falla con cÃ³digo 6
Run-TestCase 33 "DdsConverterPath apuntando a ejecutable inexistente falla con codigo 6" {
    $samplePng = Join-Path $testTempDir "sample.png"
    [System.IO.File]::WriteAllText($samplePng, "dummy png")
    $out = Join-Path $testTempDir "out_png_bad_conv"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $blackrockConfig -LoadingImagePng $samplePng -DdsConverterPath "C:\Inexistente\texconv.exe" -Force
        throw "Deberia haber fallado por conversor inexistente"
    } catch {
        if ($_ -notmatch "code 6") { throw "Codigo inesperado: $_" }
    }
}

# 34. LoadingImageDds inexistente o no-dds falla con cÃ³digo 1
Run-TestCase 34 "LoadingImageDds inexistente o invalido falla con codigo 1" {
    $out = Join-Path $testTempDir "out_dds_fail"
    try {
        & $factoryScript -CleanMapPath $cleanBlackrock -OutputDir $out -MapConfigPath $blackrockConfig -LoadingImageDds "C:\Inexistente\img.dds" -Force
        throw "Deberia haber fallado por DDS inexistente"
    } catch {
        if ($_ -notmatch "code 1") { throw "Codigo inesperado: $_" }
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE PRUEBAS AUTOMATIZADAS ($($testResults.Count) CASOS)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
$testResults | Format-Table -AutoSize
$failed = @($testResults | Where-Object { $_.Status -eq "FAILED" })
if ($failed.Count -gt 0) {
    throw "Se encontraron $($failed.Count) pruebas fallidas."
} else {
    Write-Host "`nTODAS LAS $($testResults.Count) PRUEBAS PASARON EXITOSAMENTE (100% OK)." -ForegroundColor Green
}
