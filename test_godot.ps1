# test_godot.ps1 - Prueba simple de Godot
Write-Host "Probando Godot..." -ForegroundColor Yellow

$godotPath = "C:\Users\dsuarez1\Downloads\Godot_v4.5-stable_win64.exe"

if (Test-Path $godotPath) {
    Write-Host "✓ Archivo encontrado: $godotPath" -ForegroundColor Green
    
    # Intentar ejecutar directamente
    Write-Host "Intentando ejecutar Godot directamente..." -ForegroundColor Cyan
    
    try {
        # Cambiar al directorio del proyecto primero
        cd "project"
        
        # Ejecutar Godot en modo headless para verificar el proyecto
        & $godotPath --headless --quit project.godot
        
        Write-Host "✓ Godot ejecutado exitosamente" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error ejecutando Godot: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ No se encontró Godot en: $godotPath" -ForegroundColor Red
}