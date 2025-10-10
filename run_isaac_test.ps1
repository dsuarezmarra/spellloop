# run_isaac_test.ps1 - Script para ejecutar la prueba de sprites Isaac
Write-Host "=== SPRITES ESTILO ISAAC CON FUNKO POP ===" -ForegroundColor Cyan
Write-Host "Iniciando prueba de sprites..." -ForegroundColor Yellow

# Intentar encontrar Godot
$godotPaths = @(
    "C:\Users\dsuarez1\Downloads\Godot_v4.5-stable_win64.exe",
    "C:\Program Files\Godot\Godot.exe",
    "C:\Program Files (x86)\Godot\Godot.exe",
    "C:\Users\dsuarez1\AppData\Local\Godot\Godot.exe",
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
    Write-Host "No se encontró Godot. Intentando usar 'godot' desde PATH..." -ForegroundColor Yellow
    $godotPath = "godot"
}

Write-Host "Usando Godot: $godotPath" -ForegroundColor Green

# Cambiar al directorio del proyecto
Set-Location "c:\Users\dsuarez1\git\spellloop\project"

# Preguntar qué versión ejecutar
Write-Host ""
Write-Host "¿Qué versión quieres ejecutar?" -ForegroundColor Magenta
Write-Host "1 - Visualizador de Sprites (recomendado si Godot no está instalado)" -ForegroundColor Yellow
Write-Host "2 - Juego completo interactivo" -ForegroundColor Yellow
Write-Host ""
$choice = Read-Host "Elige (1 o 2)"

if ($choice -eq "1") {
    Write-Host "Ejecutando visualizador de sprites Isaac..." -ForegroundColor Green
    $sceneFile = "scenes/test/IsaacSpriteViewer.tscn"
} else {
    Write-Host "Ejecutando la prueba de sprites Isaac..." -ForegroundColor Green
    $sceneFile = "scenes/test/TestIsaacStyle.tscn"
}
Write-Host ""
Write-Host "CONTROLES:" -ForegroundColor Magenta
Write-Host "  WASD - Mover el mago" -ForegroundColor White
Write-Host "  Shift - Dash mágico" -ForegroundColor White
Write-Host "  Flechas - Disparar hechizos" -ForegroundColor White
Write-Host "  Enter - Generar enemigo aleatorio" -ForegroundColor White
Write-Host "  ESC - Salir" -ForegroundColor White
Write-Host ""
Write-Host "Los sprites ahora tienen:" -ForegroundColor Yellow
Write-Host "  ✓ Cabeza grande estilo Isaac" -ForegroundColor Green
Write-Host "  ✓ Cuerpo pequeño" -ForegroundColor Green
Write-Host "  ✓ Características Funko Pop" -ForegroundColor Green
Write-Host "  ✓ Temática de magia (sombreros, túnicas)" -ForegroundColor Green
Write-Host "  ✓ 4 tipos de enemigos mágicos" -ForegroundColor Green
Write-Host ""

# Ejecutar Godot
try {
    & $godotPath $sceneFile
} catch {
    Write-Host "Error ejecutando Godot: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Si tienes Godot instalado, asegurate de que esté en tu PATH" -ForegroundColor Yellow
    Write-Host "o edita este script con la ruta correcta." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "¡Prueba completada!" -ForegroundColor Cyan