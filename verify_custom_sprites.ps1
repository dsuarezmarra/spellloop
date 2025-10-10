# verify_custom_sprites.ps1 - Verificar sprites personalizados
Write-Host "🎨 VERIFICANDO TUS SPRITES PERSONALIZADOS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

$spritePath = "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\"
$requiredSprites = @("wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png")

Write-Host "📁 Carpeta de sprites: $spritePath" -ForegroundColor Cyan
Write-Host ""

$foundSprites = 0
$missingSprites = @()

foreach ($sprite in $requiredSprites) {
    $fullPath = Join-Path $spritePath $sprite
    if (Test-Path $fullPath) {
        $fileSize = (Get-Item $fullPath).Length
        Write-Host "✅ $sprite - ENCONTRADO ($([math]::Round($fileSize/1024, 1)) KB)" -ForegroundColor Green
        $foundSprites++
    } else {
        Write-Host "❌ $sprite - FALTA" -ForegroundColor Red
        $missingSprites += $sprite
    }
}

Write-Host ""

if ($foundSprites -eq 4) {
    Write-Host "🎉 ¡TODOS LOS SPRITES ENCONTRADOS!" -ForegroundColor Green
    Write-Host "Tu mago personalizado se cargará automáticamente" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🚀 PRUEBA AHORA:" -ForegroundColor Yellow
    Write-Host "  1. Abre Godot"
    Write-Host "  2. Ejecuta TestIsaacStyle.tscn con F6"
    Write-Host "  3. ¡Disfruta tus sprites personalizados!"
} elseif ($foundSprites -gt 0) {
    Write-Host "⚠️  SPRITES PARCIALES ($foundSprites/4)" -ForegroundColor Yellow
    Write-Host "Faltan: $($missingSprites -join ', ')" -ForegroundColor Red
    Write-Host "El sistema usará fallback para los que falten" -ForegroundColor Gray
} else {
    Write-Host "📝 INSTRUCCIONES:" -ForegroundColor Cyan
    Write-Host "  1. Copia tus 4 sprites PNG a: $spritePath"
    Write-Host "  2. Renómbralos exactamente como:"
    foreach ($sprite in $requiredSprites) {
        Write-Host "     • $sprite"
    }
    Write-Host "  3. Ejecuta este script otra vez para verificar"
}

Write-Host ""
Write-Host "💡 TIP: Los sprites pueden ser 32x32, 48x48 o 64x64 píxeles" -ForegroundColor Blue