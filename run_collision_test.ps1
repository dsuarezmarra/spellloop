# Script para ejecutar test de colisión

$godotPath = "C:\Program Files\Godot Engine\Godot_v4.5.3-stable_win64.exe"
$projectPath = "C:\Users\dsuarez1\git\spellloop\project"

Write-Host "🔧 EJECUTANDO TEST DIRECTO DE COLISIÓN" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 Ruta Godot: $godotPath" -ForegroundColor Yellow
Write-Host "📁 Proyecto: $projectPath" -ForegroundColor Yellow
Write-Host ""

if (Test-Path $godotPath) {
    Write-Host "✅ Godot encontrado" -ForegroundColor Green
    Write-Host "🚀 Ejecutando test..." -ForegroundColor Green
    
    & $godotPath --path $projectPath
} else {
    Write-Host "❌ No se encontró Godot en: $godotPath" -ForegroundColor Red
    Write-Host "🔍 Buscando Godot en otras ubicaciones..." -ForegroundColor Yellow
    
    $possiblePaths = @(
        "C:\Godot\Godot_v4.5.3-stable_win64.exe",
        "C:\Program Files (x86)\Godot Engine\Godot_v4.5.3-stable_win64.exe",
        ".\Godot_v4.5.3-stable_win64.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Host "✅ Godot encontrado en: $path" -ForegroundColor Green
            & $path --path $projectPath
            break
        }
    }
}