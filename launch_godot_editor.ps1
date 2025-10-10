# launch_godot_editor.ps1 - Abrir Godot Editor para probar sprites
Write-Host "🎮 ABRIENDO GODOT EDITOR" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""

Write-Host "📁 Verificando proyecto..." -ForegroundColor Cyan
$projectPath = "C:\Users\dsuarez1\git\spellloop\project\project.godot"

if (Test-Path $projectPath) {
    Write-Host "✓ Proyecto encontrado: $projectPath" -ForegroundColor Green
} else {
    Write-Host "❌ No se encontró project.godot" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎨 TUS SPRITES INTEGRADOS:" -ForegroundColor Yellow
Write-Host "  🧙‍♂️ Mago con sombrero azul estrellado"
Write-Host "  🧙‍♂️ Barba blanca estilo Funko Pop"
Write-Host "  🧙‍♂️ Túnica mágica azul"
Write-Host "  🧙‍♂️ Bastón con orbe cristalino"
Write-Host ""

Write-Host "🚀 INSTRUCCIONES:" -ForegroundColor Cyan
Write-Host "  1. Se abrirá Godot Editor"
Write-Host "  2. Ve a la escena: scenes/test/TestIsaacStyle.tscn"
Write-Host "  3. Presiona F6 o el botón Play Scene"
Write-Host "  4. ¡Disfruta tus sprites Isaac + Funko Pop!"
Write-Host ""

Write-Host "⌨️  CONTROLES DEL JUEGO:" -ForegroundColor Magenta
Write-Host "  WASD - Mover el mago"
Write-Host "  Shift - Dash mágico"
Write-Host "  Flechas - Disparar hechizos"
Write-Host "  Enter - Generar enemigo"
Write-Host "  ESC - Salir"
Write-Host ""

Write-Host "Abriendo Godot Editor..." -ForegroundColor Green

# Intentar abrir con explorer (abrirá con la aplicación asociada)
try {
    Start-Process "explorer.exe" -ArgumentList $projectPath
    Write-Host "✓ Godot Editor iniciado" -ForegroundColor Green
    Write-Host ""
    Write-Host "Si Godot no se abre automáticamente:" -ForegroundColor Yellow
    Write-Host "  1. Abre Godot manualmente"
    Write-Host "  2. Importa el proyecto desde: $projectPath"
    Write-Host "  3. Ejecuta la escena TestIsaacStyle.tscn"
}
catch {
    Write-Host "❌ Error abriendo: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "SOLUCIÓN MANUAL:" -ForegroundColor Yellow
    Write-Host "  1. Abre Godot desde el menú inicio"
    Write-Host "  2. Importa proyecto: $projectPath"
    Write-Host "  3. Ejecuta: scenes/test/TestIsaacStyle.tscn"
}

Write-Host ""
Write-Host "🎉 ¡TUS SPRITES ESTÁN LISTOS! 🎉" -ForegroundColor Green