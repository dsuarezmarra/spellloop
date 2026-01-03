#!/usr/bin/env python3
"""
process_plasma.py
Procesador de sprites para Plasma (Rayo de Plasma)
Fire + Lightning = Plasma eléctrico naranja-amarillo

Archivos de entrada (desde ChatGPT/DALL-E con fondo removido):
- unnamed-removebg-preview.png: 4 sprites de FLIGHT (rayos horizontales ~330px)
- unnamed-removebg-preview2.png: 4 sprites de IMPACT (explosiones en grilla 2x2)

Output: spritesheet horizontal 256x64 (4 frames de 64x64)
"""

from PIL import Image
import numpy as np
from scipy import ndimage
from pathlib import Path

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

FRAME_SIZE = 64
NUM_FRAMES = 4
SPRITESHEET_WIDTH = FRAME_SIZE * NUM_FRAMES  # 256
SPRITESHEET_HEIGHT = FRAME_SIZE  # 64

# Carpeta de sprites
SPRITE_FOLDER = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\plasma")

# Archivos de entrada
FLIGHT_FILE = "unnamed-removebg-preview.png"
IMPACT_FILE = "unnamed-removebg-preview2.png"


# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

def find_components(img_array, min_area=500):
    """Encuentra componentes conectados en la imagen."""
    alpha = img_array[:, :, 3]
    binary = (alpha > 20).astype(int)
    labeled, num_features = ndimage.label(binary)
    
    components = []
    for i in range(1, num_features + 1):
        mask = labeled == i
        rows = np.where(mask.any(axis=1))[0]
        cols = np.where(mask.any(axis=0))[0]
        
        if len(rows) > 0 and len(cols) > 0:
            y1, y2 = rows[0], rows[-1] + 1
            x1, x2 = cols[0], cols[-1] + 1
            area = int(mask.sum())
            
            if area > min_area:
                components.append({
                    'bbox': (x1, y1, x2, y2),
                    'size': (x2 - x1, y2 - y1),
                    'area': area,
                    'center': ((x1 + x2) // 2, (y1 + y2) // 2)
                })
    
    return components


def extract_horizontal_fit(img, bbox, target_w, target_h):
    """Extrae un sprite horizontal y lo ajusta para llenar el ancho."""
    x1, y1, x2, y2 = bbox
    sprite = img.crop((x1, y1, x2, y2))
    
    w, h = sprite.size
    
    scale_x = target_w / w
    scale_y = (target_h * 0.8) / h
    
    scale = scale_x
    new_w = int(w * scale)
    new_h = int(h * scale)
    
    if new_h > target_h * 0.9:
        scale = (target_h * 0.8) / h
        new_w = int(w * scale)
        new_h = int(h * scale)
    
    sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    result = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    offset_x = (target_w - new_w) // 2
    offset_y = (target_h - new_h) // 2
    result.paste(sprite, (offset_x, offset_y), sprite)
    
    return result


def extract_grid_region(img, row, col, rows=2, cols=2):
    """Extrae una región de una grilla implícita y recorta al contenido."""
    w, h = img.size
    cell_w = w // cols
    cell_h = h // rows
    
    x1 = col * cell_w
    y1 = row * cell_h
    x2 = (col + 1) * cell_w
    y2 = (row + 1) * cell_h
    
    region = img.crop((x1, y1, x2, y2))
    
    # Encontrar contenido real
    arr = np.array(region)
    alpha = arr[:, :, 3]
    rows_content = np.where(alpha.max(axis=1) > 20)[0]
    cols_content = np.where(alpha.max(axis=0) > 20)[0]
    
    if len(rows_content) == 0 or len(cols_content) == 0:
        return None
    
    cy1, cy2 = rows_content[0], rows_content[-1] + 1
    cx1, cx2 = cols_content[0], cols_content[-1] + 1
    
    return region.crop((cx1, cy1, cx2, cy2))


# ═══════════════════════════════════════════════════════════════════════════════
# PROCESAMIENTO
# ═══════════════════════════════════════════════════════════════════════════════

def process_impact():
    """Procesa los sprites de IMPACT usando extracción por grilla 2x2."""
    print("\n" + "─" * 50)
    print("Procesando: IMPACT (explosiones)")
    print("─" * 50)
    
    img_path = SPRITE_FOLDER / IMPACT_FILE
    if not img_path.exists():
        print(f"  ❌ ERROR: No encontrado: {img_path}")
        return
    
    img = Image.open(img_path).convert('RGBA')
    print(f"  Imagen: {img.size[0]}x{img.size[1]}")
    print(f"  Usando extracción por grilla 2x2")
    
    spritesheet = Image.new('RGBA', (SPRITESHEET_WIDTH, SPRITESHEET_HEIGHT), (0, 0, 0, 0))
    
    positions = [(0, 0), (0, 1), (1, 0), (1, 1)]  # row, col
    frame_idx = 0
    
    for row, col in positions:
        sprite = extract_grid_region(img, row, col, rows=2, cols=2)
        if sprite is None:
            print(f"    Frame {frame_idx+1}: vacío")
            frame_idx += 1
            continue
        
        print(f"    Frame {frame_idx+1}: grid[{row},{col}] -> {sprite.size}")
        
        # Centrar en 64x64
        result = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        w, h = sprite.size
        scale = min(FRAME_SIZE / w, FRAME_SIZE / h) * 0.9
        
        if scale < 1:
            new_w = int(w * scale)
            new_h = int(h * scale)
            sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        w, h = sprite.size
        offset_x = (FRAME_SIZE - w) // 2
        offset_y = (FRAME_SIZE - h) // 2
        result.paste(sprite, (offset_x, offset_y), sprite)
        
        spritesheet.paste(result, (frame_idx * FRAME_SIZE, 0), result)
        frame_idx += 1
    
    output_path = SPRITE_FOLDER / "impact_spritesheet_plasma.png"
    spritesheet.save(output_path)
    print(f"  ✅ Guardado: {output_path.name}")
    print(f"     Tamaño: {SPRITESHEET_WIDTH}x{SPRITESHEET_HEIGHT} ({NUM_FRAMES} frames)")


def process_flight():
    """Procesa los sprites de FLIGHT (rayos horizontales)."""
    print("\n" + "─" * 50)
    print("Procesando: FLIGHT (rayos horizontales)")
    print("─" * 50)
    
    img_path = SPRITE_FOLDER / FLIGHT_FILE
    if not img_path.exists():
        print(f"  ❌ ERROR: No encontrado: {img_path}")
        return
    
    img = Image.open(img_path).convert('RGBA')
    arr = np.array(img)
    print(f"  Imagen: {img.size[0]}x{img.size[1]}")
    
    components = find_components(arr, min_area=5000)
    print(f"  Componentes encontrados: {len(components)}")
    
    components.sort(key=lambda c: (c['center'][1], c['center'][0]))
    
    spritesheet = Image.new('RGBA', (SPRITESHEET_WIDTH, SPRITESHEET_HEIGHT), (0, 0, 0, 0))
    
    for i, comp in enumerate(components[:NUM_FRAMES]):
        print(f"    Frame {i+1}: bbox={comp['bbox']}, size={comp['size']}")
        frame = extract_horizontal_fit(img, comp['bbox'], FRAME_SIZE, FRAME_SIZE)
        spritesheet.paste(frame, (i * FRAME_SIZE, 0), frame)
    
    output_path = SPRITE_FOLDER / "flight_spritesheet_plasma.png"
    spritesheet.save(output_path)
    print(f"  ✅ Guardado: {output_path.name}")
    print(f"     Tamaño: {SPRITESHEET_WIDTH}x{SPRITESHEET_HEIGHT} ({NUM_FRAMES} frames)")


def main():
    print("=" * 60)
    print("  PROCESADOR DE SPRITESHEETS - PLASMA")
    print("=" * 60)
    print(f"\nCarpeta: {SPRITE_FOLDER}\n")
    
    if not SPRITE_FOLDER.exists():
        print(f"❌ ERROR: La carpeta no existe: {SPRITE_FOLDER}")
        return
    
    process_impact()
    process_flight()
    
    print("\n" + "=" * 60)
    print("  ✓ COMPLETADO")
    print("=" * 60)


if __name__ == "__main__":
    main()
