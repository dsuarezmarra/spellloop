# open_test_scene.ps1 - Ayuda para abrir la escena de prueba
Write-Host "🎯 GUÍA PARA ABRIR LA ESCENA DE PRUEBA" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

Write-Host "📍 UBICACIÓN DE LA ESCENA:" -ForegroundColor Cyan
Write-Host "  Archivo: TestIsaacStyle.tscn"
Write-Host "  Ruta: res://scenes/test/TestIsaacStyle.tscn"
Write-Host "  Física: C:\Users\dsuarez1\git\spellloop\project\scenes\test\TestIsaacStyle.tscn"
Write-Host ""

Write-Host "🎮 PASOS EN GODOT:" -ForegroundColor Yellow
Write-Host "  1. Panel FileSystem (abajo izquierda):"
Write-Host "     📁 res://"
Write-Host "       📁 scenes/"
Write-Host "         📁 test/"
Write-Host "           🎬 TestIsaacStyle.tscn  ← DOBLE CLIC AQUÍ"
Write-Host ""
Write-Host "  2. O usa Ctrl+O y busca: scenes/test/TestIsaacStyle.tscn"
Write-Host ""
Write-Host "  3. Ejecutar con F6 o botón ▶️ 'Play Scene'"
Write-Host ""

Write-Host "🔧 SI NO VES EL FILESYSTEM:" -ForegroundColor Red
Write-Host "  • Menú → Project → Project Settings → FileSystem"
Write-Host "  • O Dock → FileSystem (para activar el panel)"
Write-Host ""

Write-Host "🎨 ESCENAS DISPONIBLES:" -ForegroundColor Magenta
$testScenes = @(
    "TestIsaacStyle.tscn - TUS SPRITES PERSONALIZADOS ⭐",
    "IsaacSpriteViewer.tscn - Visualizador de sprites",
    "SimpleTest.tscn - Prueba básica",
    "FunkoPopTest.tscn - Prueba Funko Pop"
)

foreach ($scene in $testScenes) {
    Write-Host "  • $scene"
}

Write-Host ""
Write-Host "🎉 ¡EJECUTA TestIsaacStyle.tscn PARA VER TUS SPRITES! 🎉" -ForegroundColor Green