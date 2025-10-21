#Requires -Version 5.0
<#
.SYNOPSIS
    🎨 Script PowerShell v2 para redimensionar texturas PNG preservando transparencia
    
.DESCRIPTION
    Redimensiona texturas usando un enfoque que PRESERVA la transparencia:
    - Texturas con "base" en el nombre → 1920x1080 PNG
    - Texturas con "decor" en el nombre → 256x256 PNG
    
    NUEVA ESTRATEGIA: Usa herramientas externas más confiables para PNG con alpha
    
.PARAMETER BiomesPath
    Ruta a la carpeta de biomas (por defecto: ruta estándar del proyecto)
#>

param(
    [string]$BiomesPath = "C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"
)

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "🎨 RESAMPLER v2 - PNG CON TRANSPARENCIA PRESERVADA" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que la carpeta existe
if (-not (Test-Path $BiomesPath)) {
    Write-Host "❌ ERROR: La carpeta no existe: $BiomesPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Carpeta: $BiomesPath" -ForegroundColor Yellow
Write-Host ""

# Función para obtener el tipo de textura
function Get-TextureType {
    param([string]$FileName)
    
    $lower = $FileName.ToLower()
    if ($lower -like "*base*") { return "base" }
    if ($lower -like "*decor*") { return "decor" }
    return $null
}

# Función para redimensionar con ImageMagick PowerShell (si está disponible)
function Resize-With-ImageMagick {
    param(
        [string]$SourcePath,
        [int]$NewWidth,
        [int]$NewHeight,
        [string]$OutputPath
    )
    
    try {
        # Intentar usar magick (ImageMagick)
        $magickCmd = "magick `"$SourcePath`" -resize ${NewWidth}x${NewHeight} -background transparent `"$OutputPath`""
        Invoke-Expression $magickCmd
        return $true
    } catch {
        return $false
    }
}

# Función alternativa usando WPF (Windows Presentation Foundation)
function Resize-With-WPF {
    param(
        [string]$SourcePath,
        [int]$NewWidth,
        [int]$NewHeight,
        [string]$OutputPath
    )
    
    try {
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        
        # Cargar imagen original
        $uri = New-Object System.Uri($SourcePath, [System.UriKind]::Absolute)
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage($uri)
        
        # Crear transform para redimensionar
        $transform = New-Object System.Windows.Media.Imaging.TransformedBitmap($bitmap, 
            (New-Object System.Windows.Media.ScaleTransform($NewWidth / $bitmap.PixelWidth, $NewHeight / $bitmap.PixelHeight)))
        
        # Crear encoder PNG
        $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($transform))
        
        # Guardar archivo
        $fileStream = [System.IO.File]::Create($OutputPath)
        $encoder.Save($fileStream)
        $fileStream.Close()
        
        return $true
    } catch {
        return $false
    }
}

# Función usando solo PowerShell nativo con mejor manejo de transparencia
function Resize-With-Native-PNG {
    param(
        [string]$SourcePath,
        [int]$NewWidth,  
        [int]$NewHeight,
        [string]$OutputPath
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        # Cargar imagen original
        $originalImage = [System.Drawing.Image]::FromFile($SourcePath)
        
        # Crear bitmap con formato específico que soporte alpha
        $newBitmap = New-Object System.Drawing.Bitmap($NewWidth, $NewHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        
        # Graphics con configuración optimizada para transparencia
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        
        # Dibujar imagen redimensionada
        $graphics.DrawImage($originalImage, 0, 0, $NewWidth, $NewHeight)
        
        # Limpiar graphics
        $graphics.Dispose()
        
        # Guardar con formato PNG específico
        $newBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Limpiar recursos
        $newBitmap.Dispose()
        $originalImage.Dispose()
        
        return $true
    } catch {
        return $false
    }
}

# Diccionario de tamaños objetivo
$textureSizes = @{
    "base" = @(1920, 1080)
    "decor" = @(128, 128)
}

$processedCount = 0
$skippedCount = 0
$errorCount = 0

# Buscar todos los archivos PNG
$pngFiles = Get-ChildItem -Path $BiomesPath -Filter "*.png" -Recurse

Write-Host "🔍 Encontrados $($pngFiles.Count) archivos PNG"
Write-Host ""

# Verificar si ImageMagick está disponible
$hasImageMagick = $false
try {
    $null = Get-Command "magick" -ErrorAction SilentlyContinue
    $hasImageMagick = $true
    Write-Host "✅ ImageMagick detectado - Usando método preferido" -ForegroundColor Green
} catch {
    Write-Host "⚠️  ImageMagick no detectado - Usando método nativo" -ForegroundColor Yellow
}
Write-Host ""

# Procesar cada archivo
foreach ($file in $pngFiles) {
    try {
        # Determinar tipo de textura
        $textureType = Get-TextureType -FileName $file.Name
        
        if ($null -eq $textureType) {
            Write-Host "⏭️  Omitido: $($file.Name) (tipo desconocido)" -ForegroundColor Gray
            $skippedCount++
            continue
        }
        
        # Obtener dimensiones objetivo
        $targetSize = $textureSizes[$textureType]
        $newWidth = $targetSize[0]
        $newHeight = $targetSize[1]
        
        # Verificar tamaño actual
        Add-Type -AssemblyName System.Drawing
        $img = [System.Drawing.Image]::FromFile($file.FullName)
        $currentWidth = $img.Width
        $currentHeight = $img.Height
        $img.Dispose()
        
        # Si ya tiene el tamaño correcto, omitir
        if ($currentWidth -eq $newWidth -and $currentHeight -eq $newHeight) {
            Write-Host "✅ Correcto: $($file.Name) (${currentWidth}x${currentHeight})" -ForegroundColor Green
            $skippedCount++
            continue
        }
        
        Write-Host "📂 Procesando: $($file.Name)" -ForegroundColor Cyan
        Write-Host "   📏 Actual: ${currentWidth}x${currentHeight}" -ForegroundColor Gray
        Write-Host "   🎯 Objetivo: ${newWidth}x${newHeight} ($textureType)" -ForegroundColor Gray
        
        # Crear respaldo del archivo original
        $backupPath = $file.FullName + ".backup"
        Copy-Item $file.FullName $backupPath
        
        $success = $false
        
        # Método 1: ImageMagick (más confiable para transparencia)
        if ($hasImageMagick) {
            Write-Host "   🔄 Intentando con ImageMagick..." -ForegroundColor Yellow
            $success = Resize-With-ImageMagick -SourcePath $file.FullName -NewWidth $newWidth -NewHeight $newHeight -OutputPath $file.FullName
        }
        
        # Método 2: WPF (fallback)
        if (-not $success) {
            Write-Host "   🔄 Intentando con WPF..." -ForegroundColor Yellow
            $success = Resize-With-WPF -SourcePath $backupPath -NewWidth $newWidth -NewHeight $newHeight -OutputPath $file.FullName
        }
        
        # Método 3: Nativo mejorado (último recurso)
        if (-not $success) {
            Write-Host "   🔄 Intentando método nativo mejorado..." -ForegroundColor Yellow
            $success = Resize-With-Native-PNG -SourcePath $backupPath -NewWidth $newWidth -NewHeight $newHeight -OutputPath $file.FullName
        }
        
        if ($success) {
            # Verificar que el archivo resultante existe y tiene tamaño correcto
            if (Test-Path $file.FullName) {
                $newImg = [System.Drawing.Image]::FromFile($file.FullName)
                $resultWidth = $newImg.Width
                $resultHeight = $newImg.Height
                $newImg.Dispose()
                
                if ($resultWidth -eq $newWidth -and $resultHeight -eq $newHeight) {
                    Write-Host "   ✅ Redimensionado exitosamente: ${resultWidth}x${resultHeight}" -ForegroundColor Green
                    $processedCount++
                    Remove-Item $backupPath -Force
                } else {
                    throw "Tamaño incorrecto después de redimensionar: ${resultWidth}x${resultHeight}"
                }
            } else {
                throw "Archivo de salida no existe"
            }
        } else {
            # Restaurar archivo original
            Move-Item $backupPath $file.FullName -Force
            throw "Todos los métodos de redimensionamiento fallaron"
        }
        
    } catch {
        Write-Host "   ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
        
        # Restaurar archivo original si existe el backup
        $backupPath = $file.FullName + ".backup"
        if (Test-Path $backupPath) {
            Move-Item $backupPath $file.FullName -Force
        }
    }
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "📊 RESUMEN FINAL" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "✅ Procesados exitosamente: $processedCount" -ForegroundColor Green
Write-Host "⏭️  Ya tenían tamaño correcto: $skippedCount" -ForegroundColor Yellow
Write-Host "❌ Errores: $errorCount" -ForegroundColor Red
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "✨ ¡COMPLETADO SIN ERRORES!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎮 PRÓXIMO PASO:" -ForegroundColor Green
    Write-Host "   Abre Godot para que reimporte las texturas PNG" -ForegroundColor Yellow
    Write-Host "   Las transparencias deberían estar preservadas" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Completado CON $errorCount errores" -ForegroundColor Red
    Write-Host "Los archivos con error mantienen su tamaño original" -ForegroundColor Gray
}