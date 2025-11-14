# Script para crear spritesheets de Forest desde frames individuales
# Formato: X1.png a X8.png donde X es el número de decor (0-9)

param(
    [Parameter(Mandatory=$false)]
    [string]$BiomeName = "Forest",

    [Parameter(Mandatory=$false)]
    [int]$FrameSize = 256,

    [Parameter(Mandatory=$false)]
    [int]$Padding = 4
)

Add-Type -AssemblyName System.Drawing

$SourceDir = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes\$BiomeName\decor"
$OutputDir = $SourceDir

Write-Host "`n=== CREANDO SPRITESHEETS PARA $BiomeName ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Gray

# Primero, verificar qué archivos existen
$AllFiles = Get-ChildItem $SourceDir -Filter "*.png" | Where-Object { $_.Name -match '^\d+\.png$' }
Write-Host "`nArchivos encontrados: $($AllFiles.Count)" -ForegroundColor Yellow
$AllFiles | Select-Object -First 10 Name | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

# Crear 10 spritesheets (decor0 a decor9, que corresponden a frames 01-08, 11-18, ..., 91-98)
for ($decorNum = 0; $decorNum -le 9; $decorNum++) {
    $DecorFrames = @()

    # Buscar frames para este decor
    # Decor 0 -> 01-08, Decor 1 -> 11-18, Decor 2 -> 21-28, etc.
    $BaseNum = $decorNum
    if ($decorNum -eq 0) { $BaseNum = 0 } else { $BaseNum = $decorNum }

    for ($frame = 1; $frame -le 8; $frame++) {
        $FrameName = if ($decorNum -eq 0) {
            "0${frame}.png"  # 01-08
        } else {
            "${decorNum}${frame}.png"  # 11-18, 21-28, etc.
        }

        $FramePath = Join-Path $SourceDir $FrameName

        if (Test-Path $FramePath) {
            $DecorFrames += $FramePath
        } else {
            Write-Host "  ⚠️  No encontrado: $FrameName" -ForegroundColor DarkYellow
        }
    }

    if ($DecorFrames.Count -ne 8) {
        Write-Host "❌ Decor $($decorNum + 1): Solo $($DecorFrames.Count)/8 frames encontrados, saltando..." -ForegroundColor Yellow
        continue
    }

    Write-Host "`nCreando decor $($decorNum + 1):" -ForegroundColor Cyan
    foreach ($f in $DecorFrames) {
        Write-Host "  - $(Split-Path $f -Leaf)" -ForegroundColor Gray
    }

    # Calcular dimensiones del spritesheet con padding
    $TotalWidth = ($FrameSize + $Padding) * 8 - $Padding  # 2052px para 256+4 padding
    $Spritesheet = New-Object System.Drawing.Bitmap($TotalWidth, $FrameSize)
    $Graphics = [System.Drawing.Graphics]::FromImage($Spritesheet)
    $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

    # Pegar frames con padding
    $X = 0
    foreach ($FramePath in $DecorFrames) {
        $Img = [System.Drawing.Image]::FromFile($FramePath)

        # Verificar tamaño
        if ($Img.Width -ne $FrameSize -or $Img.Height -ne $FrameSize) {
            Write-Host "  ⚠️  Frame $(Split-Path $FramePath -Leaf) tiene tamaño ${Img.Width}x${Img.Height}, redimensionando..." -ForegroundColor Yellow
        }

        $Graphics.DrawImage($Img, $X, 0, $FrameSize, $FrameSize)
        $Img.Dispose()
        $X += $FrameSize + $Padding
    }

    # Guardar spritesheet
    $DecorNumDisplay = $decorNum + 1
    $OutputFile = Join-Path $OutputDir "forest_decor${DecorNumDisplay}_sheet_f8_256.png"
    $Spritesheet.Save($OutputFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $Graphics.Dispose()
    $Spritesheet.Dispose()

    Write-Host "✅ forest_decor${DecorNumDisplay}_sheet_f8_256.png (${TotalWidth}x${FrameSize})" -ForegroundColor Green
}

Write-Host "`n✅ PROCESO COMPLETADO" -ForegroundColor Cyan
