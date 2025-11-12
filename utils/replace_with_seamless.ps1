# Script para reemplazar frames originales con versiones seamless
# Ejecutar desde la raíz del proyecto

# Copiar versiones seamless sobre originales
$seamless_dir = "project\assets\textures\biomes\Grassland\base_seamless"
$base_dir = "project\assets\textures\biomes\Grassland\base"

Write-Host "Reemplazando frames originales con versiones seamless..." -ForegroundColor Cyan

for ($i=1; $i -le 8; $i++) {
    $seamless_file = Join-Path $seamless_dir "${i}_seamless.png"
    $target_file = Join-Path $base_dir "${i}.png"
    
    if (Test-Path $seamless_file) {
        Copy-Item $seamless_file $target_file -Force
        Write-Host "  ✓ Frame $i reemplazado" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Frame $i no encontrado" -ForegroundColor Red
    }
}

Write-Host "`n✅ Frames reemplazados. Ahora regenera el spritesheet." -ForegroundColor Green
Write-Host "   python utils/create_spritesheet_like_snow.py grassland `"project/assets/textures/biomes/Grassland/base`"" -ForegroundColor Yellow
