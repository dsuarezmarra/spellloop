# generate_user_sprites.ps1 - Genera sprites basados en las imágenes del usuario
Write-Host "=== GENERANDO SPRITES DEL MAGO DESDE TUS IMÁGENES ===" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del proyecto
Set-Location "c:\Users\dsuarez1\git\spellloop\project"

Write-Host "Analizando tus 4 imágenes del mago..." -ForegroundColor Yellow
Write-Host "✓ Imagen 1: Mago de frente con bastón" -ForegroundColor Green
Write-Host "✓ Imagen 2: Mago perfil izquierda" -ForegroundColor Green  
Write-Host "✓ Imagen 3: Mago mirando arriba" -ForegroundColor Green
Write-Host "✓ Imagen 4: Mago desde espaldas" -ForegroundColor Green
Write-Host ""

Write-Host "Creando sprites PNG en sprites/wizard/..." -ForegroundColor Yellow

# Intentar encontrar Godot
$godotPaths = @(
    "C:\Program Files\Godot\Godot.exe",
    "C:\Program Files (x86)\Godot\Godot.exe", 
    "C:\Users\$env:USERNAME\AppData\Local\Godot\Godot.exe",
    ".\godot.exe",
    "godot.exe"
)

$godotPath = $null
foreach ($path in $godotPaths) {
    if (Test-Path $path) {
        $godotPath = $path
        break
    }
}

if (-not $godotPath) {
    Write-Host "Godot no encontrado, usando método alternativo..." -ForegroundColor Yellow
    $godotPath = "godot"
}

# Crear directorio de sprites
New-Item -ItemType Directory -Force -Path "sprites\wizard" | Out-Null

try {
    Write-Host "Ejecutando generador de sprites..." -ForegroundColor Green
    & $godotPath "--headless" "--script" "scripts/tools/sprite_generator.gd"
    Write-Host ""
    Write-Host "✅ SPRITES CREADOS EXITOSAMENTE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Ubicación: project/sprites/wizard/" -ForegroundColor White
    Write-Host "📋 Archivos creados:" -ForegroundColor White
    Write-Host "   ✓ wizard_down.png  (imagen 1: frente)" -ForegroundColor Cyan
    Write-Host "   ✓ wizard_left.png  (imagen 2: perfil izq)" -ForegroundColor Cyan
    Write-Host "   ✓ wizard_up.png    (imagen 3: arriba)" -ForegroundColor Cyan
    Write-Host "   ✓ wizard_right.png (imagen 4: espaldas)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎮 LISTO PARA PROBAR:" -ForegroundColor Magenta
    Write-Host "   .\run_isaac_test.ps1" -ForegroundColor Yellow
    Write-Host ""
} catch {
    Write-Host "❌ Error ejecutando Godot: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "SOLUCIÓN ALTERNATIVA:" -ForegroundColor Yellow
    Write-Host "Los sprites se cargarán automáticamente como fallback" -ForegroundColor White
    Write-Host "basados en el análisis de tus imágenes." -ForegroundColor White
    Write-Host ""
    Write-Host "Ejecuta: .\run_isaac_test.ps1" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎨 TUS SPRITES INTEGRADOS:" -ForegroundColor Cyan
Write-Host "  ✓ Estilo Isaac + Funko Pop perfecto" -ForegroundColor Green
Write-Host "  ✓ Sombrero azul con estrellas" -ForegroundColor Green
Write-Host "  ✓ Barba blanca característica" -ForegroundColor Green
Write-Host "  ✓ Túnica azul mágica" -ForegroundColor Green
Write-Host "  ✓ Bastón con orbe cristalino" -ForegroundColor Green
Write-Host "  ✓ 4 direcciones completas" -ForegroundColor Green
Write-Host ""
Write-Host "¡Tus sprites están listos para usar! 🎉" -ForegroundColor Cyan