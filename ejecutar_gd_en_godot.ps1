# ejecutar_gd_en_godot.ps1 - Instrucciones para ejecutar scripts .gd
Write-Host "🎯 CÓMO EJECUTAR SCRIPTS .GD EN GODOT" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

Write-Host "❌ ERROR COMÚN:" -ForegroundColor Red
Write-Host "  • Los archivos .gd NO se ejecutan desde PowerShell"
Write-Host "  • Exit Code: 1 = PowerShell no puede ejecutar archivos .gd"
Write-Host "  • Los .gd son scripts de Godot, no de sistema"
Write-Host ""

Write-Host "✅ MÉTODO CORRECTO PARA EJECUTAR .GD:" -ForegroundColor Green
Write-Host ""
Write-Host "📋 PASO A PASO PARA GenerateCompatibleSprites.gd:" -ForegroundColor Cyan
Write-Host "  1. 🎮 Abre GODOT (no PowerShell)"
Write-Host "  2. 📁 Abre tu proyecto: spellloop"
Write-Host "  3. 🔝 En la barra de menú de Godot, click en: 'File'"
Write-Host "  4. 📜 Selecciona: 'Run Script'"
Write-Host "  5. 🗂️ Navega a: scripts/editor/GenerateCompatibleSprites.gd"
Write-Host "  6. ✅ Click 'Open' o 'Abrir'"
Write-Host "  7. ⚡ El script se ejecutará automáticamente"
Write-Host ""

Write-Host "🔍 QUÉ VERÁS EN GODOT:" -ForegroundColor Yellow
Write-Host "  En la consola de Godot aparecerá:"
Write-Host "  • '🔧 GENERANDO SPRITES COMPATIBLES'"
Write-Host "  • '🎨 Generando: wizard_down.png'"
Write-Host "  • '🎨 Generando: wizard_up.png'"
Write-Host "  • '🎨 Generando: wizard_left.png'"
Write-Host "  • '🎨 Generando: wizard_right.png'"
Write-Host "  • '✅ Sprites compatibles generados'"
Write-Host ""

Write-Host "🚀 DESPUÉS DE EJECUTAR EL SCRIPT:" -ForegroundColor Magenta
Write-Host "  1. 🔄 En Godot: Project → Reload Current Project"
Write-Host "  2. ⏱️ Espera que termine la recarga"
Write-Host "  3. 🧪 Ejecuta: scenes/test/TestSpriteRobust.tscn (F6)"
Write-Host "  4. 📊 Debería mostrar: '4/4 sprites cargados'"
Write-Host ""

Write-Host "💡 ALTERNATIVA RÁPIDA:" -ForegroundColor Blue
Write-Host "  Si prefieres ver sprites inmediatamente:"
Write-Host "  1. En Godot, abre: scenes/test/CreateTestSprites.tscn"
Write-Host "  2. Presiona F6"
Write-Host "  3. Verás sprites generados programáticamente"
Write-Host ""

Write-Host "📂 UBICACIÓN DE LOS ARCHIVOS:" -ForegroundColor Green
Write-Host "  Script a ejecutar:"
Write-Host "    📄 scripts/editor/GenerateCompatibleSprites.gd"
Write-Host ""
Write-Host "  Sprites que generará:"
Write-Host "    🎨 sprites/wizard/wizard_down.png"
Write-Host "    🎨 sprites/wizard/wizard_up.png"
Write-Host "    🎨 sprites/wizard/wizard_left.png"
Write-Host "    🎨 sprites/wizard/wizard_right.png"
Write-Host ""

Write-Host "⚠️  RECORDATORIO:" -ForegroundColor Yellow
Write-Host "  • Tus sprites originales están respaldados en backup_original/"
Write-Host "  • Los nuevos sprites serán compatibles garantizado"
Write-Host "  • Una vez que funcionen, investigamos tus originales"
Write-Host ""

Write-Host "🎯 RESUMEN DE ACCIONES:" -ForegroundColor Green
Write-Host "  1. Godot → File → Run Script → GenerateCompatibleSprites.gd"
Write-Host "  2. Godot → Project → Reload Current Project"
Write-Host "  3. Godot → scenes/test/TestSpriteRobust.tscn → F6"
Write-Host ""

Write-Host "🎉 ¡AHORA HAZLO EN GODOT, NO EN POWERSHELL! 🎉" -ForegroundColor Green