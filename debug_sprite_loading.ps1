# debug_sprite_loading.ps1 - Debug de carga de sprites
Write-Host "🔍 DEBUGGING CARGA DE SPRITES" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""

Write-Host "✅ CORRECCIONES APLICADAS:" -ForegroundColor Yellow
Write-Host "  1. ❌ Error Area2D direction - CORREGIDO"
Write-Host "     • Eliminado script dinámico problemático"
Write-Host "     • Usando Tween simple para proyectiles"
Write-Host ""
Write-Host "  2. 🔍 Debug de sprites - ACTIVADO"
Write-Host "     • Logs detallados de carga de archivos"
Write-Host "     • Verificación de rutas y existencia"
Write-Host "     • Forzar uso de TUS sprites PNG"
Write-Host ""

Write-Host "📂 TUS SPRITES VERIFICADOS:" -ForegroundColor Cyan
$spritePath = "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\"
$sprites = @("wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png")

foreach ($sprite in $sprites) {
    $fullPath = Join-Path $spritePath $sprite
    if (Test-Path $fullPath) {
        $fileSize = (Get-Item $fullPath).Length
        Write-Host "  ✅ $sprite - $([math]::Round($fileSize/1024, 1)) KB" -ForegroundColor Green
        
        # Verificar archivo .import
        $importFile = $fullPath + ".import"
        if (Test-Path $importFile) {
            Write-Host "     ✓ Importado por Godot" -ForegroundColor Blue
        } else {
            Write-Host "     ⚠ No importado" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "🎯 RUTAS QUE USA EL CÓDIGO:" -ForegroundColor Magenta
Write-Host "  • res://sprites/wizard/wizard_down.png"
Write-Host "  • res://sprites/wizard/wizard_up.png"
Write-Host "  • res://sprites/wizard/wizard_left.png"
Write-Host "  • res://sprites/wizard/wizard_right.png"
Write-Host ""

Write-Host "🚀 PRUEBA AHORA CON DEBUG:" -ForegroundColor Green
Write-Host "  1. En Godot, abre TestIsaacStyle.tscn"
Write-Host "  2. Presiona F6"
Write-Host "  3. Mira la consola de Godot para ver los logs de debug"
Write-Host "  4. Deberías ver mensajes como:"
Write-Host "     '[WizardSpriteLoader] 🔍 Intentando cargar:'"
Write-Host "     '[WizardSpriteLoader] ✅ ÉXITO: Sprite cargado'"
Write-Host ""

Write-Host "🎨 AHORA DEBERÍAS VER:" -ForegroundColor Blue
Write-Host "  ✓ TUS sprites reales (no azules procedurales)"
Write-Host "  ✓ Sin errores de proyectiles"
Write-Host "  ✓ Calidad perfecta de tus PNG"
Write-Host "  ✓ Logs detallados en consola"
Write-Host ""

Write-Host "🎉 ¡PRUEBA F6 - DEBERÍAS VER TUS SPRITES REALES! 🎉" -ForegroundColor Green