# Script para aumentar memoria de VS Code
# Ejecutar como Administrador

Write-Host "Configurando límites de memoria para VS Code..." -ForegroundColor Cyan

# Opción 1: Variable de entorno de usuario (requiere reiniciar VS Code)
[System.Environment]::SetEnvironmentVariable(
    "NODE_OPTIONS",
    "--max-old-space-size=32768",
    [System.EnvironmentVariableTarget]::User
)

Write-Host "✅ Variable NODE_OPTIONS configurada a 32GB" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Yellow
Write-Host "1. Cierra COMPLETAMENTE VS Code (todas las ventanas)" -ForegroundColor White
Write-Host "2. Abre el Administrador de Tareas y verifica que no hay procesos 'Code.exe'" -ForegroundColor White
Write-Host "3. Vuelve a abrir VS Code" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar que funcionó, ejecuta en el terminal de VS Code:" -ForegroundColor Cyan
Write-Host '  $env:NODE_OPTIONS' -ForegroundColor Gray
Write-Host ""
Write-Host "Valores recomendados según tu RAM (64GB):" -ForegroundColor Yellow
Write-Host "  - 8192 MB (8GB) - Uso moderado" -ForegroundColor White
Write-Host "  - 16384 MB (16GB) - Uso intensivo" -ForegroundColor White
Write-Host "  - 32768 MB (32GB) - Máximo rendimiento (CONFIGURADO)" -ForegroundColor Green
Write-Host ""
Write-Host "Para cambiar el valor, edita este script y vuelve a ejecutarlo." -ForegroundColor Gray
