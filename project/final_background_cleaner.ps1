# LIMPIADOR DE FONDO FINAL - PowerShell Ultra Efectivo
Add-Type -AssemblyName System.Drawing

Write-Host "🎯 ELIMINACIÓN FINAL DE FONDO BLANCO" -ForegroundColor Red
Write-Host "====================================="
Write-Host ""

$sprites = @("wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png")

foreach ($sprite in $sprites) {
    $path = "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\$sprite"
    $backupPath = "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\backup_$sprite"
    
    if (Test-Path $path) {
        Write-Host "🧙‍♂️ PROCESANDO: $sprite" -ForegroundColor Yellow
        
        # Crear backup
        Copy-Item $path $backupPath -Force
        
        try {
            # Cargar imagen
            $bitmap = [System.Drawing.Bitmap]::new($path)
            $width = $bitmap.Width
            $height = $bitmap.Height
            
            Write-Host "  📐 Tamaño: ${width}x${height}" -ForegroundColor Cyan
            
            # Crear nueva imagen limpia
            $clean = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            
            $pixelsRemoved = 0
            
            # Algoritmo de flood fill desde bordes
            $visited = New-Object 'bool[,]' $width, $height
            $toRemove = New-Object 'bool[,]' $width, $height
            
            # Función flood fill optimizada
            function FloodFillWhite($x, $y) {
                $stack = New-Object System.Collections.Stack
                $stack.Push(@($x, $y))
                
                while ($stack.Count -gt 0) {
                    $current = $stack.Pop()
                    $cx = $current[0]
                    $cy = $current[1]
                    
                    if ($cx -lt 0 -or $cx -ge $width -or $cy -lt 0 -or $cy -ge $height) { continue }
                    if ($visited[$cx, $cy]) { continue }
                    
                    $pixel = $bitmap.GetPixel($cx, $cy)
                    
                    # Solo procesar blancos muy puros
                    if ($pixel.R -lt 248 -or $pixel.G -lt 248 -or $pixel.B -lt 248) { continue }
                    
                    $visited[$cx, $cy] = $true
                    $toRemove[$cx, $cy] = $true
                    
                    # Agregar vecinos a la pila
                    $stack.Push(@($cx-1, $cy))
                    $stack.Push(@($cx+1, $cy))
                    $stack.Push(@($cx, $cy-1))
                    $stack.Push(@($cx, $cy+1))
                }
            }
            
            # Iniciar flood fill desde todos los bordes
            Write-Host "  🌊 Iniciando flood fill desde bordes..." -ForegroundColor Blue
            
            # Bordes superior e inferior
            for ($x = 0; $x -lt $width; $x++) {
                if (-not $visited[$x, 0]) { FloodFillWhite $x 0 }
                if (-not $visited[$x, ($height-1)]) { FloodFillWhite $x ($height-1) }
            }
            
            # Bordes izquierdo y derecho
            for ($y = 0; $y -lt $height; $y++) {
                if (-not $visited[0, $y]) { FloodFillWhite 0 $y }
                if (-not $visited[($width-1), $y]) { FloodFillWhite ($width-1) $y }
            }
            
            # Aplicar máscara de eliminación
            Write-Host "  ✂️ Aplicando transparencia..." -ForegroundColor Green
            
            for ($y = 0; $y -lt $height; $y++) {
                for ($x = 0; $x -lt $width; $x++) {
                    if ($toRemove[$x, $y]) {
                        $clean.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                        $pixelsRemoved++
                    } else {
                        $clean.SetPixel($x, $y, $bitmap.GetPixel($x, $y))
                    }
                }
            }
            
            Write-Host "  ✨ Píxeles de fondo eliminados: $pixelsRemoved" -ForegroundColor Magenta
            
            # Guardar resultado
            $clean.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "  ✅ SPRITE LIMPIADO EXITOSAMENTE!" -ForegroundColor Green
            
            # Limpiar memoria
            $bitmap.Dispose()
            $clean.Dispose()
            
        } catch {
            Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            if (Test-Path $backupPath) {
                Copy-Item $backupPath $path -Force
                Write-Host "  🔄 Backup restaurado" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
    }
}

Write-Host "🎉 PROCESAMIENTO COMPLETO!" -ForegroundColor Green
Write-Host "🧙‍♂️ Sprites wizard sin fondo blanco"
Write-Host "🔄 Reinicia Godot para ver los cambios"
Write-Host ""

# Limpiar archivos .import para forzar re-importación
Remove-Item "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\*.import" -Force -ErrorAction SilentlyContinue
Write-Host "🗑️ Archivos .import limpiados"

Write-Host ""
Write-Host "📊 VERIFICANDO RESULTADOS:"
Get-ChildItem "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\wizard_*.png" | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 1)
    Write-Host "  ✅ $($_.Name) - ${sizeKB}KB" -ForegroundColor Cyan
}