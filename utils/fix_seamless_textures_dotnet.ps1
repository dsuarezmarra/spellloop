# Script PowerShell para hacer texturas seamless usando solo .NET
# No requiere Python - usa System.Drawing nativo

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Desert", "Death", "Both")]
    [string]$BiomeName = "Both"
)

$ErrorActionPreference = "Stop"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "CORRECCIÓN DE TEXTURAS SEAMLESS (.NET)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Add-Type -AssemblyName System.Drawing

function Make-Seamless {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$BlendSize = 64
    )

    try {
        # Cargar imagen original
        $img = [System.Drawing.Image]::FromFile($InputPath)
        $width = $img.Width
        $height = $img.Height

        # Crear bitmap de salida
        $result = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($result)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

        # Offset: dividir la imagen en 4 cuadrantes y reordenarlos
        $offsetX = [int]($width / 2)
        $offsetY = [int]($height / 2)

        # Cuadrante superior izquierdo -> inferior derecho
        $destRect1 = New-Object System.Drawing.Rectangle($offsetX, $offsetY, $width - $offsetX, $height - $offsetY)
        $srcRect1 = New-Object System.Drawing.Rectangle(0, 0, $width - $offsetX, $height - $offsetY)
        $graphics.DrawImage($img, $destRect1, $srcRect1, [System.Drawing.GraphicsUnit]::Pixel)

        # Cuadrante superior derecho -> inferior izquierdo
        $destRect2 = New-Object System.Drawing.Rectangle(0, $offsetY, $offsetX, $height - $offsetY)
        $srcRect2 = New-Object System.Drawing.Rectangle($offsetX, 0, $offsetX, $height - $offsetY)
        $graphics.DrawImage($img, $destRect2, $srcRect2, [System.Drawing.GraphicsUnit]::Pixel)

        # Cuadrante inferior izquierdo -> superior derecho
        $destRect3 = New-Object System.Drawing.Rectangle($offsetX, 0, $width - $offsetX, $offsetY)
        $srcRect3 = New-Object System.Drawing.Rectangle(0, $offsetY, $width - $offsetX, $offsetY)
        $graphics.DrawImage($img, $destRect3, $srcRect3, [System.Drawing.GraphicsUnit]::Pixel)

        # Cuadrante inferior derecho -> superior izquierdo
        $destRect4 = New-Object System.Drawing.Rectangle(0, 0, $offsetX, $offsetY)
        $srcRect4 = New-Object System.Drawing.Rectangle($offsetX, $offsetY, $offsetX, $offsetY)
        $graphics.DrawImage($img, $destRect4, $srcRect4, [System.Drawing.GraphicsUnit]::Pixel)

        $graphics.Dispose()

        # Aplicar blur en las líneas centrales para suavizar la transición
        $blurred = New-Object System.Drawing.Bitmap($width, $height)
        $gfxBlur = [System.Drawing.Graphics]::FromImage($blurred)
        $gfxBlur.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
        $gfxBlur.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        # Dibujar la imagen con un ligero blur
        $gfxBlur.DrawImage($result, 0, 0, $width, $height)
        $gfxBlur.Dispose()

        # Guardar resultado
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $blurred.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

        $img.Dispose()
        $result.Dispose()
        $blurred.Dispose()

        return $true
    }
    catch {
        Write-Host "    [ERROR] $_" -ForegroundColor Red
        if ($img) { $img.Dispose() }
        if ($result) { $result.Dispose() }
        if ($blurred) { $blurred.Dispose() }
        return $false
    }
}

function Create-Spritesheet-From-Seamless {
    param(
        [string]$InputFolder,
        [string]$OutputPath,
        [int]$FrameSize
    )

    $FrameCount = 8
    $Padding = 4
    $OutputWidth = ($FrameSize * $FrameCount) + $Padding
    $OutputHeight = $FrameSize

    $outputBitmap = New-Object System.Drawing.Bitmap($OutputWidth, $OutputHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($outputBitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

    try {
        for ($i = 1; $i -le 8; $i++) {
            $framePath = Join-Path $InputFolder ("{0:D2}.png" -f $i)
            if (-not (Test-Path $framePath)) {
                $framePath = Join-Path $InputFolder "$i.png"
            }

            if (-not (Test-Path $framePath)) {
                Write-Host "    [ERROR] No se encontró frame $i" -ForegroundColor Red
                return $false
            }

            $frameImg = [System.Drawing.Image]::FromFile($framePath)
            $xPos = ($i - 1) * $FrameSize
            $destRect = New-Object System.Drawing.Rectangle($xPos, 0, $FrameSize, $FrameSize)
            $srcRect = New-Object System.Drawing.Rectangle(0, 0, $frameImg.Width, $frameImg.Height)
            $graphics.DrawImage($frameImg, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
            $frameImg.Dispose()
        }

        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $outputBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
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

$downloadsBase = "C:\Users\dsuarez1\Downloads\biomes"
$projectBase = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"

$biomesToProcess = @()
if ($BiomeName -eq "Both") {
    $biomesToProcess = @("Desert", "Death")
} else {
    $biomesToProcess = @($BiomeName)
}

foreach ($biome in $biomesToProcess) {
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "PROCESANDO BIOMA: $biome" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    $inputFolder = Join-Path $downloadsBase "$biome\base"
    $seamlessFolder = Join-Path $downloadsBase "$biome\base_seamless"

    if (-not (Test-Path $seamlessFolder)) {
        New-Item -ItemType Directory -Path $seamlessFolder -Force | Out-Null
        Write-Host "✅ Carpeta creada: $seamlessFolder" -ForegroundColor Green
    }

    Write-Host "`nHaciendo frames seamless..." -ForegroundColor Yellow

    $frames = Get-ChildItem -Path $inputFolder -Filter "*.png" | Where-Object { $_.Name -notlike "*_sheet_*" }

    $successCount = 0
    foreach ($frame in $frames) {
        $inputPath = $frame.FullName
        $outputPath = Join-Path $seamlessFolder $frame.Name

        Write-Host "  Procesando: $($frame.Name)" -ForegroundColor Gray

        if (Make-Seamless -InputPath $inputPath -OutputPath $outputPath -BlendSize 64) {
            Write-Host "    [OK] Seamless creado" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "    [ERROR] Fallo al procesar" -ForegroundColor Red
        }
    }

    Write-Host "`n  Total procesados: $successCount/$($frames.Count)" -ForegroundColor Cyan

    Write-Host "`nRecreando spritesheet con texturas seamless..." -ForegroundColor Yellow
    $outputPath = Join-Path $projectBase "$biome\base\$($biome.ToLower())_base_animated_sheet_f8_512.png"

    if (Create-Spritesheet-From-Seamless -InputFolder $seamlessFolder -OutputPath $outputPath -FrameSize 512) {
        Write-Host "  [OK] Spritesheet recreado: $outputPath" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Fallo al recrear spritesheet" -ForegroundColor Red
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "PROCESO COMPLETADO" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "`n✅ Texturas seamless guardadas en:" -ForegroundColor Green
foreach ($biome in $biomesToProcess) {
    $seamlessFolder = Join-Path $downloadsBase "$biome\base_seamless"
    Write-Host "   - $seamlessFolder" -ForegroundColor Gray
}

Write-Host "`n📝 Spritesheets actualizados en el proyecto" -ForegroundColor Yellow
Write-Host "   Prueba los tests para verificar que ya no hay costuras" -ForegroundColor Gray
Write-Host "`n🎮 Ejecuta: Tasks -> Test Desert Decorations" -ForegroundColor Cyan
Write-Host "          o: Tasks -> Test Death Decorations" -ForegroundColor Cyan
