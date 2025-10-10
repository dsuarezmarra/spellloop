# open_godot_editor.ps1 - Abre el proyecto en el editor de Godot
Write-Host "=== ABRIR PROYECTO ISAAC EN GODOT ===" -ForegroundColor Cyan

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
    Write-Host "No se encontró Godot. Intentando usar 'godot' desde PATH..." -ForegroundColor Yellow
    $godotPath = "godot"
}

Write-Host "Usando Godot: $godotPath" -ForegroundColor Green

# Cambiar al directorio del proyecto
Set-Location "c:\Users\dsuarez1\git\spellloop\project"

Write-Host ""
Write-Host "Abriendo el proyecto en el editor de Godot..." -ForegroundColor Green
Write-Host ""
Write-Host "En el editor podrás:" -ForegroundColor Yellow
Write-Host "  ✓ Ver los sprites Isaac generados" -ForegroundColor Green
Write-Host "  ✓ Ejecutar 'IsaacSpriteViewer.tscn' para ver todos los sprites" -ForegroundColor Green
Write-Host "  ✓ Ejecutar 'TestIsaacStyle.tscn' para el juego completo" -ForegroundColor Green
Write-Host "  ✓ Editar y modificar los sprites como quieras" -ForegroundColor Green
Write-Host ""

# Ejecutar Godot en modo editor
try {
    & $godotPath "--editor" "project.godot"
} catch {
    Write-Host "Error ejecutando Godot: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Yellow
    Write-Host "1. Instala Godot desde: https://godotengine.org/download" -ForegroundColor White
    Write-Host "2. Agrega Godot a tu PATH" -ForegroundColor White
    Write-Host "3. Edita este script con la ruta correcta a Godot.exe" -ForegroundColor White
}

Write-Host ""
Write-Host "¡Proyecto listo para usar!" -ForegroundColor Cyan