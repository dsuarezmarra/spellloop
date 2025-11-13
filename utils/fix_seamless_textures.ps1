# Script PowerShell para hacer seamless las texturas base y recrear spritesheets
# Texturas de Desert y Death tienen costuras visibles

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Desert", "Death", "Both")]
    [string]$BiomeName = "Both"
)

$ErrorActionPreference = "Stop"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "CORRECCIÓN DE TEXTURAS SEAMLESS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Verificar Python
$pythonCmd = $null
$pythonPaths = @("python3", "python", "py")
foreach ($cmd in $pythonPaths) {
    try {
        $version = & $cmd --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $pythonCmd = $cmd
            Write-Host "✅ Python encontrado: $cmd" -ForegroundColor Green
            break
        }
    } catch {
        continue
    }
}

if (-not $pythonCmd) {
    Write-Host "`n❌ ERROR: Python no está instalado" -ForegroundColor Red
    Write-Host "Este script requiere Python con Pillow instalado." -ForegroundColor Yellow
    Write-Host "Por favor instala Python desde Microsoft Store o python.org" -ForegroundColor Yellow
    Write-Host "Luego ejecuta: pip install Pillow" -ForegroundColor Yellow
    exit 1
}

# Verificar Pillow
Write-Host "Verificando Pillow..." -ForegroundColor Yellow
try {
    & $pythonCmd -c "from PIL import Image; import numpy as np" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Pillow está instalado" -ForegroundColor Green
    } else {
        throw "Pillow no está disponible"
    }
} catch {
    Write-Host "`n❌ ERROR: Pillow no está instalado" -ForegroundColor Red
    Write-Host "Ejecuta: pip install Pillow numpy" -ForegroundColor Yellow
    exit 1
}

$downloadsBase = "C:\Users\dsuarez1\Downloads\biomes"
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

    # Crear carpeta para versiones seamless
    if (-not (Test-Path $seamlessFolder)) {
        New-Item -ItemType Directory -Path $seamlessFolder -Force | Out-Null
        Write-Host "✅ Carpeta creada: $seamlessFolder" -ForegroundColor Green
    }

    # Procesar cada frame
    Write-Host "`nHaciendo frames seamless..." -ForegroundColor Yellow

    $frames = Get-ChildItem -Path $inputFolder -Filter "*.png" | Where-Object { $_.Name -notlike "*_sheet_*" }

    foreach ($frame in $frames) {
        $inputPath = $frame.FullName
        $outputPath = Join-Path $seamlessFolder $frame.Name

        Write-Host "  Procesando: $($frame.Name)" -ForegroundColor Gray

        & $pythonCmd "..\..\utils\make_seamless.py" $inputPath $outputPath 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Seamless creado" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] Fallo al procesar" -ForegroundColor Red
        }
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "RECREANDO SPRITESHEETS CON TEXTURAS SEAMLESS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Ahora recrear los spritesheets usando las versiones seamless
Add-Type -AssemblyName System.Drawing

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
            # Intentar con ceros primero
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

$projectBase = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"

foreach ($biome in $biomesToProcess) {
    Write-Host "`nRecreando spritesheet de $biome..." -ForegroundColor Yellow

    $seamlessFolder = Join-Path $downloadsBase "$biome\base_seamless"
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

Write-Host "`n✅ Las texturas seamless están en:" -ForegroundColor Green
foreach ($biome in $biomesToProcess) {
    $seamlessFolder = Join-Path $downloadsBase "$biome\base_seamless"
    Write-Host "   - $seamlessFolder" -ForegroundColor Gray
}

Write-Host "`n📝 Los spritesheets actualizados están en el proyecto" -ForegroundColor Yellow
Write-Host "   Prueba los tests para verificar que ya no hay costuras visibles" -ForegroundColor Gray
