# Script para crear spritesheets de decoraciones Forest
# Formato: 10 decoraciones, 8 frames cada una (01-08, 11-18, ..., 91-98)

Add-Type -AssemblyName System.Drawing

$SourceDir = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes\Forest\decor"
$OutputDir = $SourceDir
$FrameSize = 256
$FramesPerDecor = 8

Write-Host "`n=== CREANDO SPRITESHEETS FOREST ===" -ForegroundColor Cyan

# 10 decoraciones: decor 0-9 (frames X1-X8 donde X es el número de decoración)
for ($DecorNum = 0; $DecorNum -le 9; $DecorNum++) {
    $DecorIndex = $DecorNum + 1  # Para el nombre del archivo (forest_decor1, forest_decor2, etc.)
    $OutputFile = Join-Path $OutputDir "forest_decor${DecorIndex}_sheet_f8_256.png"

    Write-Host "`nDecoracion ${DecorIndex}:" -ForegroundColor Yellow

    # Cargar los 8 frames de esta decoración (X1.png - X8.png)
    $Frames = @()
    for ($FrameNum = 1; $FrameNum -le 8; $FrameNum++) {
        $FrameName = "${DecorNum}${FrameNum}.png"
        $FramePath = Join-Path $SourceDir $FrameName

        if (Test-Path $FramePath) {
            $Frames += $FramePath
            Write-Host "  ✓ Frame $FrameName" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ Frame $FrameName NO ENCONTRADO" -ForegroundColor Red
        }
    }

    if ($Frames.Count -ne 8) {
        Write-Host "  ⚠ ADVERTENCIA: Solo se encontraron $($Frames.Count) frames (se esperaban 8)" -ForegroundColor Red
        continue
    }

    # Crear spritesheet horizontal con padding de 4px
    $Padding = 4
    $TotalWidth = ($FrameSize + $Padding) * $Frames.Count - $Padding
    $Spritesheet = New-Object System.Drawing.Bitmap($TotalWidth, $FrameSize)
    $Graphics = [System.Drawing.Graphics]::FromImage($Spritesheet)
    $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

    $X = 0
    foreach ($FramePath in $Frames) {
        $Image = [System.Drawing.Image]::FromFile($FramePath)
        $Graphics.DrawImage($Image, $X, 0, $FrameSize, $FrameSize)
        $Image.Dispose()
        $X += $FrameSize + $Padding
    }

    # Guardar
    $Spritesheet.Save($OutputFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $Graphics.Dispose()
    $Spritesheet.Dispose()

    Write-Host "  ✅ Spritesheet creado: ${TotalWidth}x${FrameSize}" -ForegroundColor Green
}

Write-Host "`n✅ PROCESO COMPLETADO: 10 spritesheets Forest creados" -ForegroundColor Cyan
Write-Host "   Ubicación: $OutputDir" -ForegroundColor Gray
