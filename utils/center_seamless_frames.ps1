# Script para centrar frames por centro de masas manteniendo seamless
param(
    [Parameter(Mandatory=$true)]
    [string]$BiomeName
)

Add-Type -AssemblyName System.Drawing

$BaseDir = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes\$BiomeName\base"

if (-not (Test-Path $BaseDir)) {
    Write-Host "❌ ERROR: No existe el directorio $BaseDir" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== CENTRANDO FRAMES $($BiomeName.ToUpper()) (MANTENIENDO SEAMLESS) ===`n" -ForegroundColor Cyan

# Función para calcular centro de masas
function Get-CenterOfMass {
    param($Bitmap)
    
    $TotalWeight = 0
    $WeightedX = 0
    $WeightedY = 0
    
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $Pixel = $Bitmap.GetPixel($x, $y)
            $Weight = $Pixel.A  # Usar alpha como peso
            
            $TotalWeight += $Weight
            $WeightedX += $x * $Weight
            $WeightedY += $y * $Weight
        }
        
        # Progreso cada 10%
        if ($y % [Math]::Floor($Bitmap.Height / 10) -eq 0) {
            $Progress = [Math]::Round(($y / $Bitmap.Height) * 100)
            Write-Host -NoNewline "`r    Analizando frame... $Progress%" -ForegroundColor DarkGray
        }
    }
    Write-Host -NoNewline "`r    Analizando frame... 100%`n" -ForegroundColor DarkGray
    
    if ($TotalWeight -eq 0) {
        return @{
            X = $Bitmap.Width / 2
            Y = $Bitmap.Height / 2
        }
    }
    
    return @{
        X = [Math]::Round($WeightedX / $TotalWeight)
        Y = [Math]::Round($WeightedY / $TotalWeight)
    }
}

# Función para hacer shift con wrap-around (seamless)
function Shift-Seamless {
    param($Bitmap, $OffsetX, $OffsetY)
    
    $Width = $Bitmap.Width
    $Height = $Bitmap.Height
    
    $Result = New-Object System.Drawing.Bitmap($Width, $Height)
    
    for ($y = 0; $y -lt $Height; $y++) {
        for ($x = 0; $x -lt $Width; $x++) {
            # Calcular posición de origen con wrap-around
            $SrcX = ($x - $OffsetX + $Width) % $Width
            $SrcY = ($y - $OffsetY + $Height) % $Height
            
            $Pixel = $Bitmap.GetPixel($SrcX, $SrcY)
            $Result.SetPixel($x, $y, $Pixel)
        }
        
        # Progreso
        if ($y % [Math]::Floor($Height / 10) -eq 0) {
            $Progress = [Math]::Round(($y / $Height) * 100)
            Write-Host -NoNewline "`r    Desplazando... $Progress%" -ForegroundColor DarkGray
        }
    }
    Write-Host -NoNewline "`r    Desplazando... 100%`n" -ForegroundColor DarkGray
    
    return $Result
}

# Cargar frames
$Frames = @()
$FramePaths = @()

for ($i = 1; $i -le 8; $i++) {
    $FramePath = Join-Path $BaseDir "$i.png"
    if (-not (Test-Path $FramePath)) {
        Write-Host "❌ ERROR: No se encuentra $FramePath" -ForegroundColor Red
        exit 1
    }
    
    $Img = [System.Drawing.Bitmap]::FromFile($FramePath)
    $Frames += $Img
    $FramePaths += $FramePath
    Write-Host "  ✓ Cargado frame $i.png ($($Img.Width)x$($Img.Height))" -ForegroundColor Gray
}

# Calcular centros de masas
Write-Host "`nCalculando centros de masas..." -ForegroundColor Yellow
$Centers = @()

for ($i = 0; $i -lt $Frames.Count; $i++) {
    Write-Host "  Frame $($i+1):" -ForegroundColor Cyan
    $Center = Get-CenterOfMass $Frames[$i]
    $Centers += $Center
    Write-Host "    Centro en ($([Math]::Round($Center.X)), $([Math]::Round($Center.Y)))" -ForegroundColor Gray
}

# Calcular centro promedio
$AvgCX = [Math]::Round(($Centers | Measure-Object -Property X -Average).Average)
$AvgCY = [Math]::Round(($Centers | Measure-Object -Property Y -Average).Average)

$ImgCenterX = $Frames[0].Width / 2
$ImgCenterY = $Frames[0].Height / 2

Write-Host "`nCentro de masas promedio: ($AvgCX, $AvgCY)" -ForegroundColor Cyan
Write-Host "Centro de imagen: ($ImgCenterX, $ImgCenterY)" -ForegroundColor Cyan

$GlobalOffsetX = [Math]::Round($ImgCenterX - $AvgCX)
$GlobalOffsetY = [Math]::Round($ImgCenterY - $AvgCY)

Write-Host "Offset global a aplicar: ($GlobalOffsetX, $GlobalOffsetY)" -ForegroundColor Yellow

if ($GlobalOffsetX -eq 0 -and $GlobalOffsetY -eq 0) {
    Write-Host "`n✅ Los frames ya están centrados, no se requieren cambios" -ForegroundColor Green
    foreach ($Img in $Frames) { $Img.Dispose() }
    exit 0
}

# Crear backup
$BackupDir = Join-Path $BaseDir "backup_before_center"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

Write-Host "`nAplicando offset con wrap-around (seamless)..." -ForegroundColor Yellow

for ($i = 0; $i -lt $Frames.Count; $i++) {
    $FrameNum = $i + 1
    
    # Backup
    $BackupPath = Join-Path $BackupDir "$FrameNum.png"
    $Frames[$i].Save($BackupPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Aplicar shift seamless
    Write-Host "  Frame $FrameNum`:" -ForegroundColor Cyan
    $Shifted = Shift-Seamless $Frames[$i] $GlobalOffsetX $GlobalOffsetY
    
    # Guardar
    $Shifted.Save($FramePaths[$i], [System.Drawing.Imaging.ImageFormat]::Png)
    $Shifted.Dispose()
    
    Write-Host "    ✓ Centrado y guardado" -ForegroundColor Green
}

# Limpiar
foreach ($Img in $Frames) { $Img.Dispose() }

Write-Host "`n✅ PROCESO COMPLETADO" -ForegroundColor Green
Write-Host "   Backup guardado en: $BackupDir" -ForegroundColor Gray
Write-Host "   Frames centrados con offset ($GlobalOffsetX, $GlobalOffsetY)" -ForegroundColor Gray
Write-Host "   Propiedad seamless PRESERVADA (wrap-around aplicado)" -ForegroundColor Gray
Write-Host "`n⚠️  Ahora regenera el spritesheet con los frames centrados" -ForegroundColor Yellow
