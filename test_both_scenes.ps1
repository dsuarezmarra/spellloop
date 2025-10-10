# test_both_scenes.ps1 - Probar ambas escenas para sprites
Write-Host "🎮 PRUEBA DE ESCENAS PARA TUS SPRITES" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

Write-Host "✅ ERROR DE PROYECTILES CORREGIDO:" -ForegroundColor Yellow
Write-Host "  • SimpleEnemyIsaac.gd línea 278 - projectile.direction ELIMINADO"
Write-Host "  • Usando Tween simple en lugar de scripts dinámicos"
Write-Host "  • Sin más errores de Area2D direction"
Write-Host ""

Write-Host "🎯 ESCENAS DISPONIBLES PARA PROBAR:" -ForegroundColor Cyan
Write-Host "  1. 🎬 TestIsaacStyle.tscn"
Write-Host "     • Juego completo con movimiento"
Write-Host "     • Controles: WASD, Shift, Flechas, Enter"
Write-Host "     • Usa SimplePlayerIsaac.gd (tu sistema de sprites)"
Write-Host ""
Write-Host "  2. 🎨 IsaacSpriteViewer.tscn"
Write-Host "     • Visualizador específico de sprites"
Write-Host "     • Enfocado en mostrar sprites claramente"
Write-Host "     • Usa WizardSpriteLoader directamente"
Write-Host ""

Write-Host "🚀 INSTRUCCIONES DE PRUEBA:" -ForegroundColor Magenta
Write-Host "  OPCIÓN A - Visualizador (recomendado para ver sprites):"
Write-Host "    1. En Godot, abre: scenes/test/IsaacSpriteViewer.tscn"
Write-Host "    2. Presiona F6"
Write-Host "    3. Deberías ver TUS sprites claramente"
Write-Host ""
Write-Host "  OPCIÓN B - Juego completo:"
Write-Host "    1. En Godot, abre: scenes/test/TestIsaacStyle.tscn"
Write-Host "    2. Presiona F6"
Write-Host "    3. Mueve con WASD para ver sprites direccionales"
Write-Host ""

Write-Host "📊 DEBUG EN CONSOLA:" -ForegroundColor Blue
Write-Host "  Busca estos mensajes en la consola de Godot:"
Write-Host "  • '[WizardSpriteLoader] 🔍 Intentando cargar:'"
Write-Host "  • '[WizardSpriteLoader] ✅ ÉXITO: Sprite cargado'"
Write-Host "  • Si ves '⚠ Archivo no encontrado' = problema de ruta"
Write-Host ""

Write-Host "🎨 TUS SPRITES VERIFICADOS:" -ForegroundColor Green
$spritePath = "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\"
$sprites = @("wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png")

foreach ($sprite in $sprites) {
    $fullPath = Join-Path $spritePath $sprite
    if (Test-Path $fullPath) {
        Write-Host "  ✅ $sprite - LISTO" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "⚠️  SI AÚN NO VES TUS SPRITES:" -ForegroundColor Red
Write-Host "  • Copia exactamente qué dice la consola de Godot"
Write-Host "  • Prueba ambas escenas (IsaacSpriteViewer y TestIsaacStyle)"
Write-Host "  • Te ayudo a diagnosticar el problema específico"
Write-Host ""

Write-Host "🎉 ¡PRUEBA IsaacSpriteViewer.tscn PRIMERO! 🎉" -ForegroundColor Green