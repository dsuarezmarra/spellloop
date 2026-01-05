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

def find_sprite_columns_in_row(img, start_y, row_height, min_gap=5):
    """Encuentra las regiones de sprites en una fila detectando gaps"""
    row = img.crop((0, int(start_y), img.width, int(start_y + row_height)))

    # Encontrar todas las columnas con contenido
    cols_with_content = []
    for x in range(row.width):
        col = row.crop((x, 0, x+1, row.height))
        if col.getbbox():
            cols_with_content.append(x)

    if not cols_with_content:
        return []

    # Agrupar columnas contiguas en regiones
    regions = []
    region_start = cols_with_content[0]
    prev = cols_with_content[0]

    for x in cols_with_content[1:]:
        if x - prev > min_gap:
            # Gap detectado, cerrar región actual
            regions.append((region_start, prev + 1))
            region_start = x
        prev = x

    # Cerrar última región
    regions.append((region_start, prev + 1))

    return regions

def extract_and_center_sprite(img, start_x, start_y, cell_width, cell_height, output_size):
    """Extrae un sprite y lo centra en un frame de output_size x output_size"""
    # Crear imagen de salida con fondo transparente
    output = Image.new('RGBA', (output_size, output_size), (0, 0, 0, 0))

    # Extraer la celda completa primero
    cell = img.crop((
        int(start_x),
        int(start_y),
        int(start_x + cell_width),
        int(start_y + cell_height)
    ))

    # Encontrar bounds del sprite dentro de la celda
    bbox = cell.getbbox()

    if bbox is None:
        print(f"  Warning: Celda vacia en ({start_x}, {start_y})")
        return output

    min_x, min_y, max_x, max_y = bbox
    sprite_width = max_x - min_x
    sprite_height = max_y - min_y

    print(f"      Bounds en celda: {bbox}, size: {sprite_width}x{sprite_height}")

    # Extraer solo el sprite (recortar de la celda, no de la imagen original)
    sprite = cell.crop(bbox)

    # Escalar si es necesario para que quepa en 32x32 con padding
    max_dim = max(sprite_width, sprite_height)
    target_size = output_size - 4  # 2px padding por lado

    if max_dim > target_size:
        scale = target_size / max_dim
        new_width = max(1, int(sprite_width * scale))
        new_height = max(1, int(sprite_height * scale))
        sprite = sprite.resize((new_width, new_height), Image.Resampling.LANCZOS)
        sprite_width, sprite_height = new_width, new_height

    # Calcular posición para centrar EN EL FRAME DE SALIDA
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

    rows = 5
    row_height = img.height / rows
    print(f"   Altura de fila: {row_height}")

    # Crear directorio de salida si no existe
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Procesar cada fila
    for row in range(rows):
        print(f"\nProcesando fila {row + 1}: {OUTPUT_NAMES[row]}")

        start_y = row * row_height

        # Detectar regiones de sprites en esta fila
        regions = find_sprite_columns_in_row(img, start_y, row_height, min_gap=8)
        print(f"   Regiones detectadas: {regions}")

        # Crear spritesheet horizontal (4 frames de 32x32 = 128x32)
        spritesheet = Image.new('RGBA', (OUTPUT_SIZE * OUTPUT_FRAMES, OUTPUT_SIZE), (0, 0, 0, 0))

        # Extraer cada región como un frame
        frames = []
        for i, (rx_start, rx_end) in enumerate(regions[:4]):  # Max 4 frames
            # Extraer y centrar este sprite
            sprite = extract_and_center_sprite(
                img, rx_start, start_y,
                rx_end - rx_start, row_height,
                OUTPUT_SIZE
            )
            frames.append(sprite)
            print(f"   Frame {i + 1}: region ({rx_start}-{rx_end})")

        # Si tenemos menos de 4 frames, duplicar para llenar
        while len(frames) < 4:
            frames.append(frames[len(frames) % len(frames)] if frames else Image.new('RGBA', (OUTPUT_SIZE, OUTPUT_SIZE), (0, 0, 0, 0)))

        # Colocar frames en el spritesheet
        for i, frame in enumerate(frames[:4]):
            spritesheet.paste(frame, (i * OUTPUT_SIZE, 0))

        # Guardar spritesheet
        output_path = os.path.join(OUTPUT_DIR, OUTPUT_NAMES[row])
        spritesheet.save(output_path)
        print(f"   Guardado: {output_path}")

    print(f"\n¡Proceso completado! Se generaron {rows} spritesheets.")
    print(f"   Ubicacion: {OUTPUT_DIR}")

if __name__ == "__main__":
    process_coins()
