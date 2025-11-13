# Script PowerShell para añadir decoraciones a biomas Desert o Death
# Uso: .\add_decor_to_biome.ps1 -BiomeName "Desert" -DecorCount 10

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Desert", "Death")]
    [string]$BiomeName,

    [Parameter(Mandatory=$true)]
    [ValidateRange(1, 20)]
    [int]$DecorCount
)

$ErrorActionPreference = "Stop"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "AÑADIR DECORACIONES A BIOMA $BiomeName" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Configuración
Add-Type -AssemblyName System.Drawing
$downloadsBase = "C:\Users\dsuarez1\Downloads\biomes"
$projectBase = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"

$inputFolder = Join-Path $downloadsBase "$BiomeName\decor"
$outputFolder = Join-Path $projectBase "$BiomeName\decor"

Write-Host "`nVerificando frames de decoraciones..." -ForegroundColor Yellow
Write-Host "  Carpeta de entrada: $inputFolder" -ForegroundColor Gray

if (-not (Test-Path $inputFolder)) {
    Write-Host "`n❌ ERROR: No existe la carpeta $inputFolder" -ForegroundColor Red
    Write-Host "Por favor, coloca los frames de decoraciones en esa carpeta primero." -ForegroundColor Yellow
    exit 1
}

# Función para crear spritesheet (misma que en create_spritesheets_dotnet.ps1)
function Create-Spritesheet {
    param(
        [string]$InputFolder,
        [int[]]$FrameNumbers,
        [string]$OutputPath,
        [int]$FrameSize
    )

    $FrameCount = $FrameNumbers.Count
    $Padding = 0  # SIN PADDING - Los frames deben estar pegados para evitar líneas
    $OutputWidth = ($FrameSize * $FrameCount) + $Padding
    $OutputHeight = $FrameSize

    $outputBitmap = New-Object System.Drawing.Bitmap($OutputWidth, $OutputHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($outputBitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    try {
        $frameIndex = 0
        foreach ($num in $FrameNumbers) {
            $framePath = Join-Path $InputFolder ("{0:D2}.png" -f $num)
            if (-not (Test-Path $framePath)) {
                $framePath = Join-Path $InputFolder "$num.png"
            }
            if (-not (Test-Path $framePath)) {
                Write-Host "    [ERROR] No se encontro frame $num" -ForegroundColor Red
                $graphics.Dispose()
                $outputBitmap.Dispose()
                return $false
            }

            $frameImg = [System.Drawing.Image]::FromFile($framePath)
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

            $xPos = $frameIndex * $FrameSize
            $destRect = New-Object System.Drawing.Rectangle($xPos, 0, $FrameSize, $FrameSize)
            $srcRect = New-Object System.Drawing.Rectangle(0, 0, $frameImg.Width, $frameImg.Height)
            $graphics.DrawImage($frameImg, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
            $frameImg.Dispose()
            $frameIndex++
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

# Crear spritesheets
$successCount = 0
$totalCount = $DecorCount

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "CREANDO $DecorCount SPRITESHEETS DE DECORACIONES" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

for ($decorNum = 1; $decorNum -le $DecorCount; $decorNum++) {
    $startFrame = $decorNum * 10 + 1
    $frameNumbers = @()
    for ($i = 0; $i -lt 8; $i++) {
        $frameNumbers += $startFrame + $i
    }

    $biomeNameLower = $BiomeName.ToLower()
    $outputPath = Join-Path $outputFolder "${biomeNameLower}_decor${decorNum}_sheet_f8_256.png"

    Write-Host "`nDecor $decorNum (frames $($frameNumbers[0].ToString('00'))-$($frameNumbers[-1].ToString('00'))):" -ForegroundColor Yellow

    if (Create-Spritesheet -InputFolder $inputFolder -FrameNumbers $frameNumbers -OutputPath $outputPath -FrameSize 256) {
        $successCount++
        Write-Host "  [OK] $outputPath" -ForegroundColor Green
    }
    else {
        Write-Host "  [ERROR] Fallo al crear" -ForegroundColor Red
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "COMPLETADO: $successCount/$totalCount spritesheets creados" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($successCount -eq $totalCount) {
    Write-Host "`n✅ ¡Todos los spritesheets se crearon exitosamente!" -ForegroundColor Green
    Write-Host "`n📝 SIGUIENTE PASO: Actualizar test_${biomeNameLower}_decorations.gd" -ForegroundColor Yellow
    Write-Host "   Añade las rutas de los nuevos spritesheets en el array decor_paths" -ForegroundColor Gray
    exit 0
}
else {
    Write-Host "`n⚠️  $($totalCount - $successCount) spritesheets fallaron" -ForegroundColor Yellow
    exit 1
}
