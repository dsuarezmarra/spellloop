# metodos_ejecutar_script_godot.ps1 - Diferentes formas de ejecutar scripts en Godot
Write-Host "🔧 MÉTODOS PARA EJECUTAR SCRIPTS EN GODOT 4.x" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Write-Host "❌ PROBLEMA COMÚN:" -ForegroundColor Red
Write-Host "  • 'File → Run Script' no aparece en algunas versiones de Godot 4.x"
Write-Host "  • La ubicación cambió entre versiones"
Write-Host "  • Hay métodos alternativos más directos"
Write-Host ""

Write-Host "🎯 MÉTODO 1 - DOCK DE SCRIPTS (RECOMENDADO):" -ForegroundColor Green
Write-Host "  1. 📂 En Godot, ve al dock 'FileSystem' (panel izquierdo)"
Write-Host "  2. 🗂️ Navega a: scripts/editor/CreateWorkingSprites.gd"
Write-Host "  3. 🖱️ DOBLE CLICK en el archivo .gd"
Write-Host "  4. 📝 Se abrirá en el editor de scripts"
Write-Host "  5. ⚡ Presiona Ctrl+Shift+X (o botón 'Run' en la barra)"
Write-Host "  6. ✅ El script se ejecutará"
Write-Host ""

Write-Host "🎯 MÉTODO 2 - MENÚ PROYECTO:" -ForegroundColor Cyan
Write-Host "  1. 📁 En Godot, ve a: Project → Tools"
Write-Host "  2. 🔍 Busca 'Execute Script' o 'Run Script'"
Write-Host "  3. 📄 Selecciona CreateWorkingSprites.gd"
Write-Host ""

Write-Host "🎯 MÉTODO 3 - DESDE EDITOR DE SCRIPTS:" -ForegroundColor Yellow
Write-Host "  1. 📂 Abre el FileSystem dock"
Write-Host "  2. 📝 Doble click en: scripts/editor/CreateWorkingSprites.gd"
Write-Host "  3. 📜 En el editor de scripts, busca el menú 'File'"
Write-Host "  4. ⚡ Click en 'Run' o 'Execute'"
Write-Host ""

Write-Host "🎯 MÉTODO 4 - ALTERNATIVO DIRECTO:" -ForegroundColor Magenta
Write-Host "  Si no encuentras 'Run Script', usemos una escena:"
Write-Host "  1. 🎬 En Godot, abre: scenes/test/CreateTestSprites.tscn"
Write-Host "  2. ⚡ Presiona F6 (Play Scene)"
Write-Host "  3. 🎨 Esto generará sprites visualmente en pantalla"
Write-Host "  4. 📂 Los sprites se guardan automáticamente"
Write-Host ""

Write-Host "🔍 UBICACIONES POSIBLES DE 'RUN SCRIPT':" -ForegroundColor Blue
Write-Host "  • File → Run Script (Godot 4.0-4.2)"
Write-Host "  • Project → Tools → Execute Script (Godot 4.3+)"
Write-Host "  • Tools → Execute Script (algunas versiones)"
Write-Host "  • Script Editor → File → Run (cuando el script está abierto)"
Write-Host ""

Write-Host "💡 SOLUCIÓN INMEDIATA - CREAR SPRITES AHORA:" -ForegroundColor Green
Write-Host "  Como no encuentras Run Script, vamos a usar el método directo:"
Write-Host ""
Write-Host "  PASO A PASO GARANTIZADO:"
Write-Host "  1. 🎬 En Godot: FileSystem → scenes/test/CreateTestSprites.tscn"
Write-Host "  2. 🖱️ Doble click para abrir la escena"
Write-Host "  3. ⚡ Presiona F6 (Play Scene)"
Write-Host "  4. 🎨 Verás sprites generándose en pantalla"
Write-Host "  5. 🔄 Los archivos PNG se crean automáticamente"
Write-Host "  6. 📋 Ve a Project → Reload Current Project"
Write-Host "  7. 🧪 Prueba TestSpriteRobust.tscn"
Write-Host ""

Write-Host "📁 VERIFICAR CREACIÓN DE SPRITES:" -ForegroundColor Yellow
Write-Host "  Después de ejecutar CreateTestSprites.tscn:"
Write-Host "  • Revisa sprites/wizard/ en FileSystem"
Write-Host "  • Deberías ver nuevos archivos .png"
Write-Host "  • Con tamaños diferentes a los originales"
Write-Host ""

Write-Host "🎉 USA CreateTestSprites.tscn AHORA (F6)! 🎉" -ForegroundColor Green