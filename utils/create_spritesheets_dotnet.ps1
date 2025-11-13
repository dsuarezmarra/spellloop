# Script PowerShell para crear spritesheets usando .NET System.Drawing
# NO requiere Python ni ImageMagick

$ErrorActionPreference = "Stop"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "CREADOR DE SPRITESHEETS - .NET System.Drawing" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Cargar ensamblado de System.Drawing
Add-Type -AssemblyName System.Drawing

function Create-Spritesheet {
    param(
        [string]$InputFolder,
        [int[]]$FrameNumbers,
        [string]$OutputPath,
        [int]$FrameSize
    )

    Write-Host "    Iniciando creacion de spritesheet..." -ForegroundColor Gray

    $FrameCount = $FrameNumbers.Count
    $Padding = 0  # SIN PADDING - Los frames deben estar pegados para evitar líneas
    $OutputWidth = ($FrameSize * $FrameCount) + $Padding
    $OutputHeight = $FrameSize

    # Crear bitmap de salida
    $outputBitmap = New-Object System.Drawing.Bitmap($OutputWidth, $OutputHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($outputBitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)

    # Configurar interpolación de alta calidad
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    try {
        $frameIndex = 0
        foreach ($num in $FrameNumbers) {
            # Intentar con ceros a la izquierda primero
            $framePath = Join-Path $InputFolder ("{0:D2}.png" -f $num)

            if (-not (Test-Path $framePath)) {
                # Intentar sin ceros
                $framePath = Join-Path $InputFolder "$num.png"
            }

            if (-not (Test-Path $framePath)) {
                Write-Host "    [ERROR] No se encontro frame $num en $InputFolder" -ForegroundColor Red
                $graphics.Dispose()
                $outputBitmap.Dispose()
                return $false
            }

            Write-Host "    Procesando frame $num..." -ForegroundColor Gray

            # Cargar imagen
            $frameImg = [System.Drawing.Image]::FromFile($framePath)

            # Si no es cuadrada, recortar al centro
            $width = $frameImg.Width
            $height = $frameImg.Height

            if ($width -ne $height) {
                $minDim = [Math]::Min($width, $height)
                $left = [int](($width - $minDim) / 2)
                $top = [int](($height - $minDim) / 2)

                $croppedBitmap = New-Object System.Drawing.Bitmap($minDim, $minDim)
                $croppedGraphics = [System.Drawing.Graphics]::FromImage($croppedBitmap)
                $destRectCrop = New-Object System.Drawing.Rectangle(0, 0, $minDim, $minDim)
                $srcRectCrop = New-Object System.Drawing.Rectangle($left, $top, $minDim, $minDim)
                $croppedGraphics.DrawImage($frameImg, $destRectCrop, $srcRectCrop, [System.Drawing.GraphicsUnit]::Pixel)
                $croppedGraphics.Dispose()
                $frameImg.Dispose()
                $frameImg = $croppedBitmap
            }

            # Calcular posición en el spritesheet
            $xPos = $frameIndex * $FrameSize

            # Dibujar frame redimensionado en el spritesheet
            $destRect = New-Object System.Drawing.Rectangle($xPos, 0, $FrameSize, $FrameSize)
            $srcRect = New-Object System.Drawing.Rectangle(0, 0, $frameImg.Width, $frameImg.Height)
            $graphics.DrawImage($frameImg, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

            $frameImg.Dispose()
            $frameIndex++
        }

        # Crear directorio si no existe
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Guardar spritesheet
        Write-Host "    Guardando: $OutputPath" -ForegroundColor Gray
        $outputBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

        Write-Host "    [OK] Spritesheet guardado: ${OutputWidth}x${OutputHeight} px" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Host "    [ERROR] $_" -ForegroundColor Red
        return $false
    }
    finally {
        $graphics.Dispose()
        $outputBitmap.Dispose()
    }
}

# ==================== CONFIGURACIÓN ====================

$downloadsBase = "C:\Users\dsuarez1\Downloads\biomes"
$projectBase = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"

$successCount = 0
$totalCount = 0

Write-Host "`nRutas configuradas:" -ForegroundColor Yellow
Write-Host "  Entrada: $downloadsBase" -ForegroundColor Gray
Write-Host "  Salida: $projectBase" -ForegroundColor Gray

# ==================== GRASSLAND DECOR ====================

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "PROCESANDO GRASSLAND DECOR (10 decoraciones)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$grasslandDecorInput = Join-Path $downloadsBase "Grassland\decor"
$grasslandDecorOutput = Join-Path $projectBase "Grassland\decor"

for ($decorNum = 1; $decorNum -le 10; $decorNum++) {
    $totalCount++
    $startFrame = $decorNum * 10 + 1
    $frameNumbers = @()
    for ($i = 0; $i -lt 8; $i++) {
        $frameNumbers += $startFrame + $i
    }

    $outputPath = Join-Path $grasslandDecorOutput "grassland_decor${decorNum}_sheet_f8_256.png"

    Write-Host "`nDecor $decorNum (frames $($frameNumbers[0].ToString('00'))-$($frameNumbers[-1].ToString('00'))):" -ForegroundColor Yellow
    Write-Host "  Input: $grasslandDecorInput" -ForegroundColor Gray
    Write-Host "  Output: $outputPath" -ForegroundColor Gray

    if (Create-Spritesheet -InputFolder $grasslandDecorInput -FrameNumbers $frameNumbers -OutputPath $outputPath -FrameSize 256) {
        $successCount++
        Write-Host "  [OK] Creado exitosamente" -ForegroundColor Green
    }
    else {
        Write-Host "  [ERROR] Fallo al crear" -ForegroundColor Red
    }
}

# ==================== DESERT BASE ====================

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "PROCESANDO DESERT BASE" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$totalCount++

$desertInput = Join-Path $downloadsBase "Desert\base"
$desertOutput = Join-Path $projectBase "Desert\base"
$desertOutputFile = Join-Path $desertOutput "desert_base_animated_sheet_f8_512.png"

$desertFrames = @(1, 2, 3, 4, 5, 6, 7, 8)

Write-Host "`nTextura base (frames 01-08):" -ForegroundColor Yellow
Write-Host "  Input: $desertInput" -ForegroundColor Gray
Write-Host "  Output: $desertOutputFile" -ForegroundColor Gray

if (Create-Spritesheet -InputFolder $desertInput -FrameNumbers $desertFrames -OutputPath $desertOutputFile -FrameSize 512) {
    $successCount++
    Write-Host "  [OK] Creado exitosamente" -ForegroundColor Green
}
else {
    Write-Host "  [ERROR] Fallo al crear" -ForegroundColor Red
}

# ==================== DEATH BASE ====================

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "PROCESANDO DEATH BASE" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$totalCount++

$deathInput = Join-Path $downloadsBase "Death\base"
$deathOutput = Join-Path $projectBase "Death\base"
$deathOutputFile = Join-Path $deathOutput "death_base_animated_sheet_f8_512.png"

$deathFrames = @(1, 2, 3, 4, 5, 6, 7, 8)

Write-Host "`nTextura base (frames 1-8):" -ForegroundColor Yellow
Write-Host "  Input: $deathInput" -ForegroundColor Gray
Write-Host "  Output: $deathOutputFile" -ForegroundColor Gray

if (Create-Spritesheet -InputFolder $deathInput -FrameNumbers $deathFrames -OutputPath $deathOutputFile -FrameSize 512) {
    $successCount++
    Write-Host "  [OK] Creado exitosamente" -ForegroundColor Green
}
else {
    Write-Host "  [ERROR] Fallo al crear" -ForegroundColor Red
}

# ==================== RESUMEN ====================

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "COMPLETADO: $successCount/$totalCount spritesheets creados" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($successCount -eq $totalCount) {
    Write-Host "`n[EXITO] Todos los spritesheets se crearon exitosamente!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n[ADVERTENCIA] $($totalCount - $successCount) spritesheets fallaron" -ForegroundColor Yellow
    exit 1
}
