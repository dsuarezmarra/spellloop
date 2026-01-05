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

# Configuración - RUTAS ABSOLUTAS
INPUT_DIR = r"C:\Users\dsuarez1\git\spellloop\project\assets\sprites\pickups\coins"
OUTPUT_DIR = r"C:\Users\dsuarez1\git\spellloop\project\assets\sprites\pickups\coins"
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

    for y in range(int(cell_height)):
        for x in range(int(cell_width)):
            px = int(start_x + x)
            py = int(start_y + y)
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

    return (int(min_x), int(min_y), int(max_x + 1), int(max_y + 1))

def extract_and_center_sprite(img, start_x, start_y, cell_width, cell_height, output_size):
    """Extrae un sprite y lo centra en un frame de output_size x output_size"""
    # Crear imagen de salida con fondo transparente
    output = Image.new('RGBA', (output_size, output_size), (0, 0, 0, 0))

    # Encontrar bounds del sprite
    bounds = find_sprite_bounds(img, start_x, start_y, cell_width, cell_height)

    if bounds is None:
        print(f"  Warning: Celda vacia en ({start_x}, {start_y})")
        return output

    min_x, min_y, max_x, max_y = bounds
    sprite_width = max_x - min_x
    sprite_height = max_y - min_y

    # Extraer el sprite
    sprite = img.crop((
        int(start_x + min_x),
        int(start_y + min_y),
        int(start_x + max_x),
        int(start_y + max_y)
    ))

    # Escalar si es necesario para que quepa en 32x32 con padding
    max_dim = max(sprite_width, sprite_height)
    target_size = output_size - 4  # 2px padding por lado

    if max_dim > target_size:
        scale = target_size / max_dim
        new_width = int(sprite_width * scale)
        new_height = int(sprite_height * scale)
        sprite = sprite.resize((new_width, new_height), Image.Resampling.LANCZOS)
        sprite_width, sprite_height = new_width, new_height

    # Calcular posición para centrar
    paste_x = (output_size - sprite_width) // 2
    paste_y = (output_size - sprite_height) // 2

    # Pegar centrado
    output.paste(sprite, (paste_x, paste_y), sprite)

    return output

def process_coins():
    """Procesa el PNG de coins y genera los spritesheets individuales"""
    # Buscar el archivo de entrada (cualquier PNG que no sea uno de los outputs)
    input_file = None
    for f in os.listdir(INPUT_DIR):
        if f.endswith('.png') and f not in OUTPUT_NAMES:
            input_file = f
            break

    if input_file is None:
        print(f"ERROR: No se encontro ningun PNG en {INPUT_DIR}")
        print(f"   Archivos existentes: {os.listdir(INPUT_DIR)}")
        return

    input_path = os.path.join(INPUT_DIR, input_file)
    print(f"Procesando: {input_path}")

    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    print(f"   Tamano original: {img.width}x{img.height}")

    # Calcular tamaño de cada celda
    cols = 4
    rows = 5
    cell_width = img.width / cols
    cell_height = img.height / rows
    print(f"   Tamano de celda: {cell_width}x{cell_height}")

    # Crear directorio de salida si no existe
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Procesar cada fila
    for row in range(rows):
        print(f"\nProcesando fila {row + 1}: {OUTPUT_NAMES[row]}")

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
            print(f"   Frame {col + 1}: OK")

        # Guardar spritesheet
        output_path = os.path.join(OUTPUT_DIR, OUTPUT_NAMES[row])
        spritesheet.save(output_path)
        print(f"   Guardado: {output_path}")

    print(f"\n¡Proceso completado! Se generaron {rows} spritesheets.")
    print(f"   Ubicacion: {OUTPUT_DIR}")

if __name__ == "__main__":
    process_coins()
