#Requires -Version 5.0
<#
.SYNOPSIS
    🎨 Script PowerShell para redimensionar texturas de biomas automáticamente
    SIN DEPENDENCIAS EXTERNAS - Solo .NET nativo
    
.DESCRIPTION
    Redimensiona automáticamente las texturas de biomas basándose en su nombre:
    - Texturas con "base" en el nombre → 1920x1080
    - Texturas con "decor" en el nombre → 256x256
    
    Utiliza solo .NET nativo, sin Python ni dependencias externas.
    
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
Write-Host "🎨 RESAMPLER DE TEXTURAS DE BIOMAS (PowerShell - Sin dependencias)" -ForegroundColor Cyan
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
        $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
        
        # Crear bitmap con nuevo tamaño
        $newBitmap = New-Object System.Drawing.Bitmap($NewWidth, $NewHeight)
        
        # Crear graphics context
        $g = [System.Drawing.Graphics]::FromImage($newBitmap)
        
        # Configurar calidad de renderizado
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        
        # Dibujar la imagen redimensionada
        $g.DrawImage($sourceImage, 0, 0, $NewWidth, $NewHeight)
        
        # Guardar la imagen (se prueba primero como PNG)
        try {
            # Intenta guardar como PNG
            $newBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } catch {
            # Si falla PNG, intenta JPEG como fallback
            Write-Host "       ⚠️  PNG falló, intentando como JPEG..." -ForegroundColor Yellow
            $jpegPath = $OutputPath -replace '\.png$', '.jpg'
            $newBitmap.Save($jpegPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
            $OutputPath = $jpegPath
        }
        
        # Limpiar recursos
        $g.Dispose()
        $sourceImage.Dispose()
        $newBitmap.Dispose()
        
        return $true
    }
    catch {
        Write-Host "       ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Buscar todas las imágenes PNG
$imageFiles = Get-ChildItem -Path $BiomesPath -Recurse -Include @("*.png") -File | Sort-Object FullName

if ($imageFiles.Count -eq 0) {
    Write-Host "⚠️  No se encontraron imágenes PNG" -ForegroundColor Yellow
    exit 0
}

Write-Host "🔍 Encontradas $($imageFiles.Count) imágenes PNG" -ForegroundColor Green
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
        try {
            $image = [System.Drawing.Image]::FromFile($imageFile.FullName)
            $currentWidth = $image.Width
            $currentHeight = $image.Height
            $image.Dispose()
        } catch {
            Write-Host "   ❌ ERROR al leer imagen: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        Write-Host "   📏 Tamaño actual: $($currentWidth)x$($currentHeight)" -ForegroundColor Gray
        Write-Host "   🎯 Tipo detectado: $($textureType.ToUpper())" -ForegroundColor Gray
        Write-Host "   📐 Tamaño objetivo: $($targetWidth)x$($targetHeight)" -ForegroundColor Gray
        
        # Si ya tiene el tamaño correcto, omitir
        if ($currentWidth -eq $targetWidth -and $currentHeight -eq $targetHeight) {
            Write-Host "   ✅ Ya está en tamaño correcto" -ForegroundColor Green
            $skippedCount++
            Write-Host ""
            continue
        }
        
        # Redimensionar
        Write-Host "   🔄 Redimensionando..." -ForegroundColor Gray
        
        $outputPath = $imageFile.FullName
        
        if (Resize-Image -SourcePath $imageFile.FullName -NewWidth $targetWidth -NewHeight $targetHeight -OutputPath $outputPath) {
            
            # Obtener nuevo tamaño
            try {
                $newSize = (Get-Item $outputPath -ErrorAction SilentlyContinue).Length
                $originalSize = $imageFile.Length
                
                if ($newSize) {
                    $totalOriginalSize += $originalSize
                    $totalNewSize += $newSize
                    
                    $originalSizeKB = [math]::Round($originalSize / 1024, 2)
                    $newSizeKB = [math]::Round($newSize / 1024, 2)
                    
                    Write-Host "   ✅ Redimensionado exitosamente" -ForegroundColor Green
                    Write-Host "   💾 Tamaño: $($originalSizeKB) KB → $($newSizeKB) KB" -ForegroundColor Gray
                }
            } catch {
                Write-Host "   ✅ Redimensionado (no se pudo verificar tamaño)" -ForegroundColor Green
            }
            
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
Write-Host "✅ Redimensionadas: $processedCount imágenes" -ForegroundColor Green
Write-Host "⏭️  Omitidas: $skippedCount imágenes" -ForegroundColor Yellow
Write-Host "❌ Errores: $errorCount imágenes" -ForegroundColor Red

if ($totalOriginalSize -gt 0) {
    $originalSizeMB = [math]::Round($totalOriginalSize / 1MB, 2)
    $newSizeMB = [math]::Round($totalNewSize / 1MB, 2)
    if ($totalOriginalSize -gt 0) {
        $reduction = [math]::Round(((($totalOriginalSize - $totalNewSize) / $totalOriginalSize) * 100), 1)
        Write-Host ""
        Write-Host "💾 Tamaño original: $($originalSizeMB) MB" -ForegroundColor Gray
        Write-Host "💾 Tamaño nuevo: $($newSizeMB) MB" -ForegroundColor Gray
        Write-Host "📉 Reducción: $reduction%" -ForegroundColor Gray
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($errorCount -eq 0 -and $processedCount -gt 0) {
    Write-Host "✨ ¡Proceso completado exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ PRÓXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "   1. Recarga el Editor de Godot completamente" -ForegroundColor Yellow
    Write-Host "   2. Godot reimportará automáticamente las texturas" -ForegroundColor Yellow
    Write-Host "   3. Verifica que las texturas se ven en el juego" -ForegroundColor Yellow
} elseif ($errorCount -gt 0) {
    Write-Host "⚠️  Se encontraron errores durante el procesamiento" -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  No se procesaron imágenes (todas están en tamaño correcto)" -ForegroundColor Gray
}

Write-Host ""
