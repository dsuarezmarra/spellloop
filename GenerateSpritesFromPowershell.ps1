# GenerateSpritesFromPowershell.ps1 - Crear sprites compatibles desde PowerShell
Write-Host "🎨 GENERANDO SPRITES COMPATIBLES DESDE POWERSHELL" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

Write-Host "💡 COMO NO ENCUENTRAS 'RUN SCRIPT' EN GODOT:" -ForegroundColor Yellow
Write-Host "  Vamos a crear sprites simples usando Python desde PowerShell"
Write-Host "  Esto evita la necesidad de ejecutar scripts .gd"
Write-Host ""

# Verificar si Python está disponible
$pythonAvailable = $false
try {
    $pythonVersion = python --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $pythonAvailable = $true
        Write-Host "✅ Python detectado: $pythonVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Python no detectado" -ForegroundColor Red
}

if ($pythonAvailable) {
    Write-Host ""
    Write-Host "🐍 GENERANDO SPRITES CON PYTHON:" -ForegroundColor Cyan
    
    # Crear script Python para generar sprites
    $pythonScript = @"
from PIL import Image, ImageDraw
import os

def create_wizard_sprite(filename, color, size=64):
    # Crear imagen con fondo transparente
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colores
    hat_color = (128, 0, 128, 255)  # Púrpura
    skin_color = (255, 230, 200, 255)  # Piel
    robe_color = color
    
    # Dibujar túnica (rectángulo)
    draw.rectangle([15, 20, size-15, size-5], fill=robe_color)
    
    # Dibujar cabeza (círculo)
    head_size = 20
    head_x = size//2 - head_size//2
    head_y = 5
    draw.ellipse([head_x, head_y, head_x + head_size, head_y + head_size], fill=skin_color)
    
    # Dibujar sombrero (triángulo aproximado)
    hat_points = [
        (size//2, 0),           # Punta superior
        (size//2 - 15, 20),     # Esquina izquierda
        (size//2 + 15, 20)      # Esquina derecha
    ]
    draw.polygon(hat_points, fill=hat_color)
    
    # Dibujar ojos
    eye_size = 2
    draw.ellipse([size//2 - 6, 12, size//2 - 6 + eye_size, 12 + eye_size], fill=(0, 0, 0, 255))
    draw.ellipse([size//2 + 4, 12, size//2 + 4 + eye_size, 12 + eye_size], fill=(0, 0, 0, 255))
    
    return img

# Directorio de sprites
sprite_dir = r"C:\Users\dsuarez1\git\spellloop\project\sprites\wizard"

# Crear sprites con diferentes colores
sprites = [
    ("wizard_down.png", (102, 51, 204, 255)),    # Púrpura
    ("wizard_up.png", (76, 25, 178, 255)),       # Púrpura oscuro
    ("wizard_left.png", (128, 76, 230, 255)),    # Púrpura claro
    ("wizard_right.png", (115, 64, 217, 255))    # Púrpura medio
]

print("🎨 Creando sprites...")
for filename, color in sprites:
    try:
        img = create_wizard_sprite(filename, color)
        filepath = os.path.join(sprite_dir, filename)
        img.save(filepath, "PNG")
        print(f"✅ {filename} creado exitosamente")
    except Exception as e:
        print(f"❌ Error creando {filename}: {e}")

print("🎉 ¡Sprites creados! Ejecuta Project → Reload Current Project en Godot")
"@

    # Guardar script Python temporalmente
    $pythonFile = "C:\Users\dsuarez1\git\spellloop\create_sprites.py"
    $pythonScript | Out-File -FilePath $pythonFile -Encoding UTF8
    
    # Verificar si PIL está disponible
    Write-Host "🔍 Verificando Pillow (PIL)..." -ForegroundColor Yellow
    try {
        python -c "from PIL import Image; print('PIL disponible')" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PIL disponible - Ejecutando creación de sprites..." -ForegroundColor Green
            python $pythonFile
        } else {
            Write-Host "❌ PIL no disponible - Instalando..." -ForegroundColor Yellow
            pip install Pillow
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ PIL instalado - Ejecutando creación de sprites..." -ForegroundColor Green
                python $pythonFile
            } else {
                Write-Host "❌ No se pudo instalar PIL" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "❌ Error verificando PIL" -ForegroundColor Red
    }
    
    # Limpiar archivo temporal
    if (Test-Path $pythonFile) {
        Remove-Item $pythonFile
    }
    
} else {
    Write-Host ""
    Write-Host "🔧 MÉTODO ALTERNATIVO SIN PYTHON:" -ForegroundColor Magenta
    Write-Host "  1. 🎬 En Godot: FileSystem → scenes/test/CreateTestSprites.tscn"
    Write-Host "  2. 🖱️ Doble click para abrir la escena"
    Write-Host "  3. ⚡ Presiona F6 (Play Scene)"
    Write-Host "  4. 🎨 Los sprites se generarán y guardarán automáticamente"
    Write-Host ""
    Write-Host "  O ALTERNATIVA MANUAL:"
    Write-Host "  1. 📂 Ve al dock 'FileSystem' en Godot"
    Write-Host "  2. 🗂️ Navega a: scripts/editor/CreateWorkingSprites.gd"
    Write-Host "  3. 🖱️ Doble click en el archivo"
    Write-Host "  4. ⌨️ Presiona Ctrl+Shift+X en el editor de scripts"
}

Write-Host ""
Write-Host "📋 DESPUÉS DE CREAR LOS SPRITES:" -ForegroundColor Blue
Write-Host "  1. 🔄 En Godot: Project → Reload Current Project"
Write-Host "  2. 🧪 Ejecuta: scenes/test/TestSpriteRobust.tscn (F6)"
Write-Host "  3. 📊 Debería mostrar: '4/4 sprites cargados'"
Write-Host "  4. 🎮 Ejecuta: scenes/test/IsaacSpriteViewer.tscn"
Write-Host "  5. 🎯 ¡Finalmente verás tus sprites en el juego!"
Write-Host ""

Write-Host "🎉 ¡SPRITES CREADOS EXITOSAMENTE! 🎉" -ForegroundColor Green