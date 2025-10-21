#Requires -Version 5.0
<#
.SYNOPSIS
    🎨 Script PowerShell para redimensionar texturas de biomas automáticamente
    
.DESCRIPTION
    Redimensiona automáticamente las texturas de biomas basándose en su nombre:
    - Texturas con "base" → 1920x1080 PNG
    - Texturas con "decor" → 256x256 PNG
    
    Utiliza solo .NET nativo, sin dependencias externas.
    
.PARAMETER BiomesPath
    Ruta a la carpeta de biomas (por defecto: ruta estándar del proyecto)
    
.EXAMPLE
    .\resample_biome_textures.ps1
    .\resample_biome_textures.ps1 -BiomesPath "C:\Custom\Path\biomes"
#>

param(
    [string]$BiomesPath = "C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"
)

# Cargar assemblies requeridos
Add-Type -AssemblyName System.Drawing

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "🎨 RESAMPLER DE TEXTURAS DE BIOMAS (PowerShell)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que la carpeta existe
if (-not (Test-Path $BiomesPath)) {
    Write-Host "❌ ERROR: La carpeta no existe: $BiomesPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Carpeta: $BiomesPath" -ForegroundColor Yellow
Write-Host ""

# Diccionario de tamaños objetivo
$textureSizes = @{
    "base" = @(1920, 1080)
    "decor" = @(256, 256)
}

$processedCount = 0
$skippedCount = 0
$errorCount = 0
$totalOriginalSize = 0
$totalNewSize = 0

# Función para obtener el tipo de textura
function Get-TextureType {
    param([string]$FileName)
    
    $lower = $FileName.ToLower()
    if ($lower -like "*base*") { return "base" }
    if ($lower -like "*decor*") { return "decor" }
    return $null
}

# Función para redimensionar imagen
function Resize-Image {
    param(
        [string]$SourcePath,
        [int]$NewWidth,
        [int]$NewHeight,
        [string]$OutputPath
    )
    
    try {
        # Cargar imagen original
        $image = [System.Drawing.Image]::FromFile($SourcePath)
        
        # Crear bitmap redimensionado
        $bitmap = New-Object System.Drawing.Bitmap($NewWidth, $NewHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Configurar propiedades de renderizado de alta calidad
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        
        # Dibujar imagen redimensionada
        $rectangle = New-Object System.Drawing.Rectangle(0, 0, $NewWidth, $NewHeight)
        $graphics.DrawImage($image, $rectangle)
        
        # Obtener codificador PNG
        $encoders = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()
        $pngEncoder = $null
        foreach ($encoder in $encoders) {
            if ($encoder.MimeType -eq "image/png") {
                $pngEncoder = $encoder
                break
            }
        }
        
        if ($null -eq $pngEncoder) {
            throw "No PNG encoder found"
        }
        
        # Configurar parámetros de codificación
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 95)
        
        # Guardar como PNG
        $bitmap.Save($OutputPath, $pngEncoder, $encoderParams)
        
        # Limpiar recursos
        $encoderParams.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
        $image.Dispose()
        
        return $true
    }
    catch {
        Write-Host "       ❌ ERROR en redimensionamiento: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Buscar todas las imágenes
$imageFiles = Get-ChildItem -Path $BiomesPath -Recurse -Include @("*.jpg", "*.jpeg", "*.png", "*.bmp") -File | Sort-Object FullName

if ($imageFiles.Count -eq 0) {
    Write-Host "⚠️  No se encontraron imágenes" -ForegroundColor Yellow
    exit 0
}

Write-Host "🔍 Encontradas $($imageFiles.Count) imágenes" -ForegroundColor Green
Write-Host ""

# Procesar cada imagen
foreach ($imageFile in $imageFiles) {
    try {
        $filename = $imageFile.Name
        $baseName = $imageFile.BaseName
        $directory = $imageFile.Directory.FullName
        
        # Obtener tipo de textura
        $textureType = Get-TextureType $filename
        
        if ($null -eq $textureType) {
            Write-Host "⏭️  OMITIDO: $filename (no es 'base' ni 'decor')" -ForegroundColor Gray
            $skippedCount++
            continue
        }
        
        # Obtener tamaño objetivo
        $targetSize = $textureSizes[$textureType]
        $targetWidth = $targetSize[0]
        $targetHeight = $targetSize[1]
        
        Write-Host "📂 Procesando: $filename" -ForegroundColor White
        
        # Cargar imagen para obtener tamaño actual
        $image = [System.Drawing.Image]::FromFile($imageFile.FullName)
        $currentWidth = $image.Width
        $currentHeight = $image.Height
        $currentFormat = $image.RawFormat
        $image.Dispose()
        
        Write-Host "   📏 Tamaño actual: $($currentWidth)x$($currentHeight)" -ForegroundColor Gray
        Write-Host "   🎯 Tipo detectado: $($textureType.ToUpper())" -ForegroundColor Gray
        Write-Host "   📐 Tamaño objetivo: $($targetWidth)x$($targetHeight) PNG" -ForegroundColor Gray
        
        # Si ya tiene el tamaño correcto
        if ($currentWidth -eq $targetWidth -and $currentHeight -eq $targetHeight -and $imageFile.Extension -eq ".png") {
            Write-Host "   ✅ Ya está en formato y tamaño correcto" -ForegroundColor Green
            $skippedCount++
            continue
        }
        
        # Redimensionar
        Write-Host "   🔄 Redimensionando..." -ForegroundColor Gray
        
        $outputPath = Join-Path $directory "$($baseName).png"
        
        if (Resize-Image -SourcePath $imageFile.FullName -NewWidth $targetWidth -NewHeight $targetHeight -OutputPath $outputPath) {
            
            # Obtener información de tamaños de archivo
            $originalSize = $imageFile.Length
            $newSize = (Get-Item $outputPath).Length
            
            $totalOriginalSize += $originalSize
            $totalNewSize += $newSize
            
            # Eliminar original si es diferente
            if ($imageFile.FullName -ne $outputPath) {
                Remove-Item -Path $imageFile.FullName -Force
                Write-Host "   🗑️  Eliminado original" -ForegroundColor Gray
            }
            
            # Mostrar información
            $originalSizeKB = [math]::Round($originalSize / 1024, 2)
            $newSizeKB = [math]::Round($newSize / 1024, 2)
            
            Write-Host "   ✅ Guardado como PNG" -ForegroundColor Green
            Write-Host "   💾 Tamaño: $($originalSizeKB) KB → $($newSizeKB) KB" -ForegroundColor Gray
            
            $processedCount++
        } else {
            $errorCount++
        }
        
        Write-Host ""
        
    } catch {
        Write-Host "   ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
        Write-Host ""
    }
}

# Resumen
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "📊 RESUMEN" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "✅ Procesadas: $processedCount imágenes" -ForegroundColor Green
Write-Host "⏭️  Omitidas: $skippedCount imágenes" -ForegroundColor Yellow
Write-Host "❌ Errores: $errorCount imágenes" -ForegroundColor Red

if ($totalOriginalSize -gt 0) {
    $originalSizeMB = [math]::Round($totalOriginalSize / 1MB, 2)
    $newSizeMB = [math]::Round($totalNewSize / 1MB, 2)
    $reduction = [math]::Round(((($totalOriginalSize - $totalNewSize) / $totalOriginalSize) * 100), 1)
    
    Write-Host ""
    Write-Host "💾 Tamaño original: $($originalSizeMB) MB" -ForegroundColor Gray
    Write-Host "💾 Tamaño nuevo: $($newSizeMB) MB" -ForegroundColor Gray
    Write-Host "📉 Reducción: $reduction%" -ForegroundColor Gray
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($errorCount -eq 0 -and $processedCount -gt 0) {
    Write-Host "✨ ¡Proceso completado exitosamente!" -ForegroundColor Green
} elseif ($errorCount -gt 0) {
    Write-Host "⚠️  Se encontraron errores durante el procesamiento" -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  No se procesaron imágenes" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ PRÓXIMO PASO: Recarga el Editor de Godot para reimportar las texturas" -ForegroundColor Cyan
Write-Host ""
