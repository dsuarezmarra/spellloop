#!/usr/bin/env python3
"""
process_storm_caller.py
Procesador de sprites para Storm Caller (Invocador de Tormentas)
Lightning + Wind = Tormenta eléctrica azul-púrpura

Formato de entrada (ChatGPT/DALL-E):
- flight.png: ~612x408px con 4 frames en fila horizontal
- impact.png: similar formato

Output: spritesheet horizontal 256x64 (4 frames de 64x64)
"""

from PIL import Image
import os

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

GRID_COLS = 4
FRAME_SIZE = 64
OUTPUT_WIDTH = FRAME_SIZE * 4
OUTPUT_HEIGHT = FRAME_SIZE

# Carpeta de sprites
SPRITE_FOLDER = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\storm_caller"

# Archivos de entrada
INPUT_FILES = ["flight.png", "impact.png"]

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESAMIENTO
# ═══════════════════════════════════════════════════════════════════════════════

def extract_grid_frames(image_path: str, cols: int = 4) -> list[Image.Image]:
    """Extraer frames de una grilla uniforme horizontal"""
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size

    cell_width = width // cols
    cell_height = height  # Toda la altura

    frames = []
    for col in range(cols):
        x = col * cell_width
        y = 0

        # Extraer celda completa
        cell = img.crop((x, y, x + cell_width, y + cell_height))

        # Centrar en 64x64 (recorta al contenido y escala)
        centered = center_in_frame(cell, FRAME_SIZE, FRAME_SIZE)
        frames.append(centered)

        print(f"    Frame {col + 1}: extraído de X={x}-{x+cell_width}, centrado en {FRAME_SIZE}x{FRAME_SIZE}")

    return frames

def center_in_frame(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Centrar imagen en un frame de tamaño específico"""
    # Calcular el bounding box del contenido no transparente
    bbox = img.getbbox()

    if bbox:
        # Recortar al contenido
        img = img.crop(bbox)

    # Escalar si es necesario (manteniendo aspecto)
    img_w, img_h = img.size
    scale = min(target_w / img_w, target_h / img_h)

    if scale < 1.0:
        new_w = int(img_w * scale)
        new_h = int(img_h * scale)
        img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Crear frame transparente
    result = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))

    # Pegar centrado
    img_w, img_h = img.size
    x = (target_w - img_w) // 2
    y = (target_h - img_h) // 2
    result.paste(img, (x, y), img)

    return result

def create_spritesheet(frames: list[Image.Image], output_path: str):
    """Crear spritesheet horizontal a partir de frames"""
    spritesheet = Image.new("RGBA", (OUTPUT_WIDTH, OUTPUT_HEIGHT), (0, 0, 0, 0))

    for i, frame in enumerate(frames):
        x = i * FRAME_SIZE
        spritesheet.paste(frame, (x, 0))

    spritesheet.save(output_path)
    print(f"  ✅ Guardado: {os.path.basename(output_path)}")
    print(f"     Tamaño: {OUTPUT_WIDTH}x{OUTPUT_HEIGHT} ({len(frames)} frames)\n")

def main():
    print("=" * 60)
    print("  PROCESADOR DE SPRITESHEETS - STORM CALLER")
    print("=" * 60)
    print(f"\nCarpeta: {SPRITE_FOLDER}\n")

    # Verificar que la carpeta existe
    if not os.path.exists(SPRITE_FOLDER):
        print(f"❌ ERROR: La carpeta no existe: {SPRITE_FOLDER}")
        return

    for filename in INPUT_FILES:
        input_path = os.path.join(SPRITE_FOLDER, filename)

        if not os.path.exists(input_path):
            print(f"⚠️  Saltando {filename} (no encontrado)")
            continue

        print("─" * 50)
        print(f"Procesando: {filename}")
        print("─" * 50)

        # Obtener info de imagen
        img = Image.open(input_path)
        width, height = img.size
        cell_width = width // GRID_COLS

        print(f"  Tamaño original: {width}x{height}")
        print(f"  Grilla: {GRID_COLS} columnas de {cell_width}px")

        # Extraer frames
        frames = extract_grid_frames(input_path, GRID_COLS)

        # Crear spritesheet
        base_name = filename.replace(".png", "")
        output_filename = f"{base_name}_spritesheet_storm_caller.png"
        output_path = os.path.join(SPRITE_FOLDER, output_filename)

        create_spritesheet(frames, output_path)

    print("=" * 60)
    print("  COMPLETADO")
    print("=" * 60)

if __name__ == "__main__":
    main()
