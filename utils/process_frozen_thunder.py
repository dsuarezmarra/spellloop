#!/usr/bin/env python3
"""
Procesador de sprites para Frozen Thunder (Trueno Congelado)
============================================================
Ice + Lightning fusion - Procesa las imágenes de flight e impact
generadas por ChatGPT para crear spritesheets compatibles con el juego.

Los sprites de entrada son grillas de 4 columnas (612x408px).
Cada frame es de ~153px de ancho.

Estructura de salida:
- flight_spritesheet_frozen_thunder.png (256x64, 4 frames de 64x64)
- impact_spritesheet_frozen_thunder.png (256x64, 4 frames de 64x64)
"""

import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("ERROR: pip install Pillow numpy")
    sys.exit(1)


WEAPON_ID = "frozen_thunder"
INPUT_DIR = Path(r"C:\Users\dsuarez1\git\spellloop\project\assets\sprites\projectiles\fusion") / WEAPON_ID
OUTPUT_DIR = INPUT_DIR
FRAME_SIZE = 64
NUM_COLUMNS = 4  # Los sprites tienen 4 columnas


def extract_frame_from_grid(img, col_index, num_cols=4):
    """Extrae un frame de una grilla, centrándolo en 64x64."""
    width, height = img.size
    col_width = width // num_cols
    
    # Extraer la columna
    x1 = col_index * col_width
    x2 = (col_index + 1) * col_width
    column = img.crop((x1, 0, x2, height))
    
    # Encontrar el bounding box del contenido real
    arr = np.array(column)
    if arr.shape[2] == 4:
        alpha = arr[:, :, 3]
    else:
        alpha = np.mean(arr[:, :, :3], axis=2)
    
    rows_with_content = np.any(alpha > 10, axis=1)
    cols_with_content = np.any(alpha > 10, axis=0)
    
    y_indices = np.where(rows_with_content)[0]
    x_indices = np.where(cols_with_content)[0]
    
    if len(y_indices) == 0 or len(x_indices) == 0:
        # Frame vacío, devolver frame transparente
        return Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    
    # Recortar al contenido
    y1, y2 = y_indices[0], y_indices[-1] + 1
    x1_local, x2_local = x_indices[0], x_indices[-1] + 1
    sprite = column.crop((x1_local, y1, x2_local, y2))
    
    # Redimensionar si es necesario para que quepa en 64x64
    w, h = sprite.size
    max_size = int(FRAME_SIZE * 0.90)  # 90% del frame
    
    if w > max_size or h > max_size:
        scale = min(max_size / w, max_size / h)
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
        w, h = sprite.size
    
    # Centrar en frame 64x64
    frame = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x_offset = (FRAME_SIZE - w) // 2
    y_offset = (FRAME_SIZE - h) // 2
    frame.paste(sprite, (x_offset, y_offset), sprite if sprite.mode == 'RGBA' else None)
    
    return frame


def process_grid_spritesheet(input_path, output_path, description):
    """Procesa un spritesheet en grilla de 4 columnas."""
    print(f"\n{'─'*50}")
    print(f"Procesando: {Path(input_path).name}")
    print(f"{'─'*50}")
    
    img = Image.open(input_path).convert('RGBA')
    print(f"  Tamaño original: {img.size[0]}x{img.size[1]}")
    print(f"  Grilla: {NUM_COLUMNS} columnas de {img.size[0]//NUM_COLUMNS}px")
    
    # Extraer los 4 frames
    frames = []
    for i in range(NUM_COLUMNS):
        frame = extract_frame_from_grid(img, i, NUM_COLUMNS)
        frames.append(frame)
        print(f"    Frame {i+1}: extraído y centrado en {FRAME_SIZE}x{FRAME_SIZE}")
    
    # Crear spritesheet horizontal (256x64)
    spritesheet = Image.new('RGBA', (FRAME_SIZE * NUM_COLUMNS, FRAME_SIZE), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * FRAME_SIZE, 0))
    
    # Guardar
    spritesheet.save(output_path, 'PNG')
    print(f"\n  ✅ Guardado: {Path(output_path).name}")
    print(f"     Tamaño: {spritesheet.size[0]}x{spritesheet.size[1]} ({NUM_COLUMNS} frames)")
    
    return True


def main():
    print("="*60)
    print(f"  PROCESADOR DE SPRITESHEETS - {WEAPON_ID.upper()}")
    print("="*60)
    
    if not INPUT_DIR.exists():
        print(f"\n❌ ERROR: No existe la carpeta: {INPUT_DIR}")
        return
    
    print(f"\nCarpeta: {INPUT_DIR}")
    
    configs = [
        ("flight.png", f"flight_spritesheet_{WEAPON_ID}.png", "FLIGHT (rayo de hielo)"),
        ("impact.png", f"impact_spritesheet_{WEAPON_ID}.png", "IMPACT (explosión helada)")
    ]
    
    for input_name, output_name, desc in configs:
        input_path = INPUT_DIR / input_name
        output_path = OUTPUT_DIR / output_name
        
        if not input_path.exists():
            print(f"\n⚠️ No encontrado: {input_name}")
            continue
        
        try:
            process_grid_spritesheet(str(input_path), str(output_path), desc)
        except Exception as e:
            print(f"❌ Error: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "="*60)
    print("  COMPLETADO")
    print("="*60)


if __name__ == "__main__":
    main()
