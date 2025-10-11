# Script PowerShell SÚPER EFECTIVO para eliminar fondo blanco
Add-Type -AssemblyName System.Drawing

Write-Host "🎯 ELIMINACIÓN PERFECTA DE FONDO BLANCO" -ForegroundColor Magenta
Write-Host "======================================="

$sprites = @("wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png")

foreach ($sprite in $sprites) {
    $path = "C:\Users\dsuarez1\git\spellloop\project\sprites\wizard\$sprite"
    
    if (Test-Path $path) {
        Write-Host "🧙‍♂️ Procesando: $sprite" -ForegroundColor Yellow
        
        # Cargar imagen
        $bitmap = New-Object System.Drawing.Bitmap($path)
        $width = $bitmap.Width
        $height = $bitmap.Height
        
        # Crear nueva imagen con canal alpha
        $result = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        
        # Procesar cada píxel
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                
                # Detectar fondo blanco puro (muy blanco y sin variación)
                $isBackgroundWhite = $false
                
                # Criterio 1: Blanco muy puro
                if ($pixel.R -ge 252 -and $pixel.G -ge 252 -and $pixel.B -ge 252) {
                    # Criterio 2: Está cerca de los bordes
                    if ($x -le 5 -or $x -ge ($width - 6) -or $y -le 5 -or $y -ge ($height - 6)) {
                        $isBackgroundWhite = $true
                    }
                    # Criterio 3: Área homogénea de blancos (detección de regiones grandes)
                    else {
                        $whiteNeighbors = 0
                        $totalNeighbors = 0
                        
                        # Examinar vecindario 3x3
                        for ($dy = -1; $dy -le 1; $dy++) {
                            for ($dx = -1; $dx -le 1; $dx++) {
                                $nx = $x + $dx
                                $ny = $y + $dy
                                if ($nx -ge 0 -and $nx -lt $width -and $ny -ge 0 -and $ny -lt $height) {
                                    $neighbor = $bitmap.GetPixel($nx, $ny)
                                    if ($neighbor.R -ge 250 -and $neighbor.G -ge 250 -and $neighbor.B -ge 250) {
                                        $whiteNeighbors++
                                    }
                                    $totalNeighbors++
                                }
                            }
                        }
                        
                        # Si más del 85% de vecinos son blancos, es fondo
                        if ($totalNeighbors -gt 0 -and ($whiteNeighbors / $totalNeighbors) -gt 0.85) {
                            $isBackgroundWhite = $true
                        }
                    }
                }
                
                # Aplicar píxel
                if ($isBackgroundWhite) {
                    $result.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                } else {
                    $result.SetPixel($x, $y, $pixel)
                }
            }
        }
        
        # Guardar resultado
        $result.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $bitmap.Dispose()
        $result.Dispose()
        
        Write-Host "  ✅ Fondo eliminado preservando detalles!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎉 PROCESAMIENTO COMPLETO!" -ForegroundColor Green
Write-Host "📁 Sprites actualizados en: sprites/wizard/"
Write-Host "🔄 Reinicia Godot (F5) para ver los cambios"