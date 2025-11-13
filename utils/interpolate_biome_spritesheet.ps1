# Script para interpolar frames de biomas y crear spritesheet de 24 frames
# Interpola 3 frames entre cada par de frames originales (8 -> 24)

param(
    [Parameter(Mandatory=$true)]
    [string]$BiomeName,  # "Desert" o "Death"
    
    [Parameter(Mandatory=$false)]
    [int]$FrameSize = 1024
)

Add-Type -AssemblyName System.Drawing

$SourceDir = "C:\Users\dsuarez1\Downloads\biomes\$BiomeName\base_seamless"
$OutputFile = "c:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes\$BiomeName\base\${BiomeName}_base_animated_sheet_f24_${FrameSize}.png"

Write-Host "`n=== INTERPOLANDO SPRITESHEET: $BiomeName ===" -ForegroundColor Cyan

# Cargar frames originales (8 frames)
$OriginalFrames = Get-ChildItem $SourceDir -Filter "*.png" | Sort-Object { 
    if ($_.Name -match '(\d+)\.png') { [int]$matches[1] } 
}

if ($OriginalFrames.Count -eq 0) {
    Write-Host "ERROR: No se encontraron frames en $SourceDir" -ForegroundColor Red
    exit 1
}

Write-Host "Frames originales: $($OriginalFrames.Count)" -ForegroundColor Green

# Función para interpolar linealmente entre dos imágenes
function Interpolate-Frame {
    param($Img1, $Img2, $BlendFactor)
    
    $Result = New-Object System.Drawing.Bitmap($Img1.Width, $Img1.Height)
    
    for ($y = 0; $y -lt $Img1.Height; $y++) {
        for ($x = 0; $x -lt $Img1.Width; $x++) {
            $P1 = $Img1.GetPixel($x, $y)
            $P2 = $Img2.GetPixel($x, $y)
            
            $R = [Math]::Round($P1.R * (1 - $BlendFactor) + $P2.R * $BlendFactor)
            $G = [Math]::Round($P1.G * (1 - $BlendFactor) + $P2.G * $BlendFactor)
            $B = [Math]::Round($P1.B * (1 - $BlendFactor) + $P2.B * $BlendFactor)
            $A = [Math]::Round($P1.A * (1 - $BlendFactor) + $P2.A * $BlendFactor)
            
            $Result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($A, $R, $G, $B))
        }
    }
    
    return $Result
}

# Cargar todas las imágenes originales
$Images = @()
foreach ($Frame in $OriginalFrames) {
    $Images += [System.Drawing.Image]::FromFile($Frame.FullName)
}

Write-Host "Interpolando frames (3 entre cada par)..." -ForegroundColor Yellow

# Crear lista de frames interpolados (24 total)
$InterpolatedFrames = @()

for ($i = 0; $i -lt $Images.Count; $i++) {
    $CurrentImg = $Images[$i]
    $NextImg = $Images[($i + 1) % $Images.Count]  # Loop al primero
    
    # Añadir frame original
    $InterpolatedFrames += $CurrentImg
    
    # Añadir 2 frames interpolados (total 3 frames por segmento = 8*3 = 24)
    for ($step = 1; $step -le 2; $step++) {
        $BlendFactor = $step / 3.0  # 0.333, 0.666
        Write-Host "  Interpolando entre frame $($i+1) y $(($i+1)%8+1): blend=$([Math]::Round($BlendFactor,3))" -ForegroundColor Gray
        $InterpolatedFrames += (Interpolate-Frame $CurrentImg $NextImg $BlendFactor)
    }
}

Write-Host "`nTotal frames interpolados: $($InterpolatedFrames.Count)" -ForegroundColor Green

# Crear spritesheet horizontal
$TotalWidth = $FrameSize * $InterpolatedFrames.Count
$Spritesheet = New-Object System.Drawing.Bitmap($TotalWidth, $FrameSize)
$Graphics = [System.Drawing.Graphics]::FromImage($Spritesheet)
$Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

Write-Host "Creando spritesheet: ${TotalWidth}x${FrameSize}" -ForegroundColor Cyan

$X = 0
for ($i = 0; $i -lt $InterpolatedFrames.Count; $i++) {
    $Graphics.DrawImage($InterpolatedFrames[$i], $X, 0, $FrameSize, $FrameSize)
    $X += $FrameSize
}

# Guardar
$Spritesheet.Save($OutputFile, [System.Drawing.Imaging.ImageFormat]::Png)

# Limpiar memoria
$Graphics.Dispose()
$Spritesheet.Dispose()
foreach ($Img in $Images) { $Img.Dispose() }
foreach ($Img in $InterpolatedFrames) { if ($Img -ne $null) { $Img.Dispose() } }

Write-Host "`n✅ SPRITESHEET CREADO: $OutputFile" -ForegroundColor Green
Write-Host "   Dimensiones: ${TotalWidth}x${FrameSize}" -ForegroundColor Green
Write-Host "   Frames: $($InterpolatedFrames.Count) (8 originales + 16 interpolados)" -ForegroundColor Green
