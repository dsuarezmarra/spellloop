# Script simplificado para hacer texturas seamless
# Usa técnica de offset simple sin blend complejo

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Desert", "Death", "Both")]
    [string]$BiomeName = "Both"
)

$ErrorActionPreference = "Stop"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "CORRECCIÓN TEXTURAS SEAMLESS - MÉTODO OFFSET" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Add-Type -AssemblyName System.Drawing

function Make-Seamless-Simple {
    param(
        [string]$InputPath,
        [string]$OutputPath
    )

    try {
        # Cargar imagen
        $original = [System.Drawing.Bitmap]::new($InputPath)
        $w = $original.Width
        $h = $original.Height

        # Crear imagen de salida del mismo tamaño
        $result = New-Object System.Drawing.Bitmap($w, $h)

        # Calcular offsets (mitad de la imagen)
        $offsetX = [int]($w / 2)
        $offsetY = [int]($h / 2)

        # Copiar píxeles con offset
        for ($y = 0; $y -lt $h; $y++) {
            for ($x = 0; $x -lt $w; $x++) {
                # Calcular posición origen con wrap-around
                $srcX = ($x + $offsetX) % $w
                $srcY = ($y + $offsetY) % $h

                # Copiar píxel
                $pixel = $original.GetPixel($srcX, $srcY)
                $result.SetPixel($x, $y, $pixel)
            }
        }

        # Guardar
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $result.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

        $original.Dispose()
        $result.Dispose()

        return $true
    }
    catch {
        Write-Host "    [ERROR] $_" -ForegroundColor Red
        if ($original) { $original.Dispose() }
        if ($result) { $result.Dispose() }
        return $false
    }
}

function Create-Spritesheet {
    param(
        [string]$InputFolder,
        [string]$OutputPath,
        [int]$FrameSize
    )

    $FrameCount = 8
    $Padding = 0  # SIN PADDING - Los frames deben estar completamente pegados
    $OutputWidth = ($FrameSize * $FrameCount) + $Padding
    $OutputHeight = $FrameSize

    $outputBitmap = New-Object System.Drawing.Bitmap($OutputWidth, $OutputHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($outputBitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    try {
        for ($i = 1; $i -le 8; $i++) {
            $framePath = Join-Path $InputFolder ("{0:D2}.png" -f $i)
            if (-not (Test-Path $framePath)) {
                $framePath = Join-Path $InputFolder "$i.png"
            }

            if (-not (Test-Path $framePath)) {
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
    finally {
        $graphics.Dispose()
        $outputBitmap.Dispose()
    }
}

$downloadsBase = "C:\Users\dsuarez1\Downloads\biomes"
$projectBase = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"

$biomesToProcess = if ($BiomeName -eq "Both") { @("Desert", "Death") } else { @($BiomeName) }

foreach ($biome in $biomesToProcess) {
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "PROCESANDO: $biome" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    $inputFolder = Join-Path $downloadsBase "$biome\base"
    $seamlessFolder = Join-Path $downloadsBase "$biome\base_seamless"

    if (-not (Test-Path $seamlessFolder)) {
        New-Item -ItemType Directory -Path $seamlessFolder -Force | Out-Null
    }

    Write-Host "Aplicando offset seamless a frames..." -ForegroundColor Yellow

    $frames = Get-ChildItem -Path $inputFolder -Filter "*.png" | Where-Object { $_.Name -notlike "*_sheet_*" }

    $processed = 0
    foreach ($frame in $frames) {
        Write-Host "  $($frame.Name)..." -NoNewline

        $inputPath = $frame.FullName
        $outputPath = Join-Path $seamlessFolder $frame.Name

        if (Make-Seamless-Simple -InputPath $inputPath -OutputPath $outputPath) {
            Write-Host " [OK]" -ForegroundColor Green
            $processed++
        } else {
            Write-Host " [ERROR]" -ForegroundColor Red
        }
    }

    Write-Host "`nFrames procesados: $processed/$($frames.Count)" -ForegroundColor Cyan

    if ($processed -gt 0) {
        Write-Host "`nCreando spritesheet final..." -ForegroundColor Yellow

        $biomeNameLower = $biome.ToLower()
        $outputPath = Join-Path $projectBase "$biome\base\${biomeNameLower}_base_animated_sheet_f8_512.png"

        if (Create-Spritesheet -InputFolder $seamlessFolder -OutputPath $outputPath -FrameSize 512) {
            Write-Host "  [OK] $outputPath" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] Fallo al crear spritesheet" -ForegroundColor Red
        }
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "COMPLETADO" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "`n🎮 Prueba los tests para verificar los cambios:" -ForegroundColor Yellow
Write-Host "   - Tasks -> Test Desert Decorations" -ForegroundColor Gray
Write-Host "   - Tasks -> Test Death Decorations" -ForegroundColor Gray
