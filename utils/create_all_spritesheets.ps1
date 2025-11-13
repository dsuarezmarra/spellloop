# Script para crear todos los spritesheets necesarios
# Ejecuta el script Python para cada conjunto de frames

$ErrorActionPreference = "Stop"

Write-Host "`n🎨 CREADOR DE SPRITESHEETS - GRASSLAND DECOR + DESERT/DEATH BASE" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

# Buscar Python
$pythonCmd = $null
$pythonPaths = @("python3", "python", "py")
foreach ($cmd in $pythonPaths) {
    try {
        $version = & $cmd --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $pythonCmd = $cmd
            Write-Host "✅ Python encontrado: $cmd ($version)" -ForegroundColor Green
            break
        }
    } catch {
        continue
    }
}

if (-not $pythonCmd) {
    Write-Host "❌ ERROR: No se encontró Python instalado" -ForegroundColor Red
    exit 1
}

$scriptPath = "create_grassland_and_base_spritesheets.py"

Write-Host "`n🚀 Ejecutando script Python..." -ForegroundColor Yellow
Write-Host "   Script: $scriptPath`n" -ForegroundColor Gray

try {
    & $pythonCmd $scriptPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Todos los spritesheets creados exitosamente!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  El script finalizó con errores (código $LASTEXITCODE)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "`n❌ ERROR al ejecutar el script: $_" -ForegroundColor Red
    exit 1
}
