#Requires -Version 5.0
<#
.SYNOPSIS
    🎨 Script PowerShell para convertir texturas de biomas a PNG
    
.DESCRIPTION
    Convierte todas las imágenes JPG en la carpeta biomes a PNG.
    NOTA: Para redimensionar automáticamente, usa el script Python en su lugar.
    
.PARAMETER BiomesPath
    Ruta a la carpeta de biomas (por defecto: ruta estándar del proyecto)
    
.EXAMPLE
    .\convert_textures_to_png.ps1
    .\convert_textures_to_png.ps1 -BiomesPath "C:\Custom\Path\biomes"
#>

param(
    [string]$BiomesPath = "C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"
)

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "🎨 CONVERTIDOR DE TEXTURAS - PowerShell (Conversión a PNG)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que la carpeta existe
if (-not (Test-Path $BiomesPath)) {
    Write-Host "❌ ERROR: La carpeta no existe: $BiomesPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Carpeta: $BiomesPath" -ForegroundColor Yellow
Write-Host ""

# Cargar assemblies de Windows
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$processedCount = 0
$skippedCount = 0
$errorCount = 0

# Buscar todas las imágenes
$imageFiles = Get-ChildItem -Path $BiomesPath -Recurse -Include @("*.jpg", "*.jpeg", "*.png", "*.bmp") -File

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
        
        # Si ya es PNG, omitir
        if ($imageFile.Extension -eq ".png") {
            Write-Host "⏭️  OMITIDO: $filename (ya es PNG)" -ForegroundColor Gray
            $skippedCount++
            continue
        }
        
        Write-Host "📂 Procesando: $filename" -ForegroundColor White
        
        # Cargar imagen
        $image = [System.Drawing.Image]::FromFile($imageFile.FullName)
        $width = $image.Width
        $height = $image.Height
        
        Write-Host "   📏 Tamaño: $($width)x$($height)" -ForegroundColor Gray
        Write-Host "   🔄 Convirtiendo a PNG..." -ForegroundColor Gray
        
        # Ruta de salida
        $outputPath = Join-Path $directory "$($baseName).png"
        
        # Guardar como PNG
        $image.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $image.Dispose()
        
        # Eliminar original si es diferente
        if ($imageFile.FullName -ne $outputPath) {
            Remove-Item -Path $imageFile.FullName -Force
            Write-Host "   🗑️  Eliminado original" -ForegroundColor Gray
        }
        
        Write-Host "   ✅ Guardado como PNG" -ForegroundColor Green
        $processedCount++
        Write-Host ""
        
    } catch {
        Write-Host "   ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

# Resumen
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "📊 RESUMEN" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "✅ Convertidas: $processedCount imágenes" -ForegroundColor Green
Write-Host "⏭️  Omitidas: $skippedCount imágenes" -ForegroundColor Yellow
Write-Host "❌ Errores: $errorCount imágenes" -ForegroundColor Red
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "✨ ¡Proceso completado exitosamente!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Se encontraron errores durante el procesamiento" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ℹ️  NOTA: Este script solo convierte a PNG." -ForegroundColor Yellow
Write-Host "Para redimensionar automáticamente, usa: python resample_biome_textures.py" -ForegroundColor Yellow
Write-Host ""
