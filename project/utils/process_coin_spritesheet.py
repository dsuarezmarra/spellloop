#!/usr/bin/env python3
"""
process_coin_spritesheet.py
Procesa el PNG con todos los coins y genera spritesheets individuales.

Entrada: PNG con 5 filas x 4 columnas de sprites de monedas
Salida: 5 spritesheets horizontales de 128x32 (4 frames de 32x32 cada uno)

Estructura esperada del input:
- Fila 1: Bronze coins
- Fila 2: Silver coins  
- Fila 3: Gold coins
- Fila 4: Diamond gems
- Fila 5: Purple soul gems
"""

from PIL import Image
import os

# Configuración
INPUT_PATH = "../assets/sprites/pickups/coins"
INPUT_FILE = "coins_all.png"  # Nombre del archivo original
OUTPUT_SIZE = 32  # Tamaño de cada frame individual
OUTPUT_FRAMES = 4  # Frames por animación

# Nombres de salida para cada fila
OUTPUT_NAMES = [
    "coin_bronze_spin.png",
    "coin_silver_spin.png", 
    "coin_gold_spin.png",
    "gem_diamond_spin.png",
    "gem_purple_spin.png"
]

def find_sprite_bounds(img, start_x, start_y, cell_width, cell_height):
    """Encuentra los límites del sprite dentro de una celda (bounding box del contenido no transparente)"""
    min_x, min_y = cell_width, cell_height
    max_x, max_y = 0, 0
    
    for y in range(cell_height):
        for x in range(cell_width):
            px = start_x + x
            py = start_y + y
            if px < img.width and py < img.height:
                pixel = img.getpixel((px, py))
                # Verificar si el pixel tiene alpha > 0
                if len(pixel) == 4 and pixel[3] > 10:
                    min_x = min(min_x, x)
                    min_y = min(min_y, y)
                    max_x = max(max_x, x)
                    max_y = max(max_y, y)
    
    if max_x < min_x:  # No se encontró contenido
        return None
    
    return (min_x, min_y, max_x + 1, max_y + 1)

def extract_and_center_sprite(img, start_x, start_y, cell_width, cell_height, output_size):
    """Extrae un sprite y lo centra en un frame de output_size x output_size"""
    # Crear imagen de salida con fondo transparente
    output = Image.new('RGBA', (output_size, output_size), (0, 0, 0, 0))
    
    # Encontrar bounds del sprite
    bounds = find_sprite_bounds(img, start_x, start_y, cell_width, cell_height)
    
    if bounds is None:
        print(f"  ⚠️ Celda vacía en ({start_x}, {start_y})")
        return output
    
    min_x, min_y, max_x, max_y = bounds
    sprite_width = max_x - min_x
    sprite_height = max_y - min_y
    
    # Extraer el sprite
    sprite = img.crop((
        start_x + min_x,
        start_y + min_y,
        start_x + max_x,
        start_y + max_y
    ))
    
    # Calcular posición para centrar
    paste_x = (output_size - sprite_width) // 2
    paste_y = (output_size - sprite_height) // 2
    
    # Pegar centrado
    output.paste(sprite, (paste_x, paste_y), sprite)
    
    return output

def process_coins():
    """Procesa el PNG de coins y genera los spritesheets individuales"""
    # Buscar el archivo de entrada
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_dir = os.path.normpath(os.path.join(script_dir, INPUT_PATH))
    
    # Buscar cualquier PNG en el directorio que no sea uno de los outputs
    input_file = None
    for f in os.listdir(input_dir):
        if f.endswith('.png') and f not in OUTPUT_NAMES:
            input_file = f
            break
    
    if input_file is None:
        print(f"❌ No se encontró ningún PNG en {input_dir}")
        print(f"   Archivos existentes: {os.listdir(input_dir)}")
        return
    
    input_path = os.path.join(input_dir, input_file)
    print(f"📂 Procesando: {input_path}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    print(f"   Tamaño original: {img.width}x{img.height}")
    
    # Calcular tamaño de cada celda
    cols = 4
    rows = 5
    cell_width = img.width // cols
    cell_height = img.height // rows
    print(f"   Tamaño de celda: {cell_width}x{cell_height}")
    
    # Procesar cada fila
    for row in range(rows):
        print(f"\n🪙 Procesando fila {row + 1}: {OUTPUT_NAMES[row]}")
        
        # Crear spritesheet horizontal (4 frames de 32x32 = 128x32)
        spritesheet = Image.new('RGBA', (OUTPUT_SIZE * OUTPUT_FRAMES, OUTPUT_SIZE), (0, 0, 0, 0))
        
        for col in range(cols):
            # Calcular posición de la celda en la imagen original
            start_x = col * cell_width
            start_y = row * cell_height
            
            # Extraer y centrar sprite
            sprite = extract_and_center_sprite(
                img, start_x, start_y, 
                cell_width, cell_height, 
                OUTPUT_SIZE
            )
            
            # Pegar en el spritesheet
            spritesheet.paste(sprite, (col * OUTPUT_SIZE, 0))
            print(f"   Frame {col + 1}: ✓")
        
        # Guardar spritesheet
        output_path = os.path.join(input_dir, OUTPUT_NAMES[row])
        spritesheet.save(output_path)
        print(f"   💾 Guardado: {output_path}")
    
    print(f"\n✅ ¡Proceso completado! Se generaron {rows} spritesheets.")
    print(f"   Ubicación: {input_dir}")

if __name__ == "__main__":
    process_coins()
