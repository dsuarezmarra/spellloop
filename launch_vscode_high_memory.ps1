# Script para lanzar VS Code con memoria aumentada
# Ejecutar este script para abrir VS Code con configuración optimizada

$env:NODE_OPTIONS = "--max-old-space-size=32768"
$env:ELECTRON_RUN_AS_NODE = "1"

# Buscar la ruta de Code.exe
$codePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles(x86)\Microsoft VS Code\Code.exe"
)

$codeExe = $codePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($codeExe) {
    Write-Host "🚀 Lanzando VS Code con 32GB de memoria..." -ForegroundColor Cyan
    Write-Host "Ejecutable: $codeExe" -ForegroundColor Gray
    Write-Host "NODE_OPTIONS: $env:NODE_OPTIONS" -ForegroundColor Green
    
    # Lanzar VS Code con argumentos adicionales
    & $codeExe `
        --max-memory=32768 `
        --js-flags="--max-old-space-size=32768" `
        "c:\git\spellloop"
    
    Write-Host "✅ VS Code iniciado correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ No se encontró Code.exe" -ForegroundColor Red
    Write-Host "Rutas buscadas:" -ForegroundColor Yellow
    $codePaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}
