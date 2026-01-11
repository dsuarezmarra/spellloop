"""
Analiza el contenido real de los sprites del wizard detectando frames por contenido
"""
from PIL import Image
import os
import numpy as np

base_path = "c:/git/spellloop/project/assets/sprites/players/wizard"

def analyze_sprite_content(img_path):
    """Analiza una imagen para detectar frames basándose en columnas vacías"""
    img = Image.open(img_path).convert("RGBA")
    arr = np.array(img)
    w, h = img.size
    
    # Detectar columnas con contenido (alpha > 0)
    alpha = arr[:, :, 3]
    col_has_content = np.any(alpha > 10, axis=0)
    
    # Encontrar bordes de sprites
    frames = []
    in_sprite = False
    start_x = 0
    
    for x in range(w):
        if col_has_content[x] and not in_sprite:
            in_sprite = True
            start_x = x
        elif not col_has_content[x] and in_sprite:
            in_sprite = False
            frames.append((start_x, x))
    
    if in_sprite:
        frames.append((start_x, w))
    
    return frames, w, h, img

def get_sprite_bounds(img, x_start, x_end):
    """Obtiene los bounds exactos de un sprite dentro de una región"""
    arr = np.array(img.convert("RGBA"))
    alpha = arr[:, x_start:x_end, 3]
    
    # Encontrar filas y columnas con contenido
    rows_with_content = np.any(alpha > 10, axis=1)
    cols_with_content = np.any(alpha > 10, axis=0)
    
    if not np.any(rows_with_content):
        return None
    
    y_min = np.argmax(rows_with_content)
    y_max = len(rows_with_content) - np.argmax(rows_with_content[::-1])
    x_min = np.argmax(cols_with_content)
    x_max = len(cols_with_content) - np.argmax(cols_with_content[::-1])
    
    return {
        "x": x_start + x_min,
        "y": y_min,
        "w": x_max - x_min,
        "h": y_max - y_min
    }

print("=" * 70)
print("ANÁLISIS DETALLADO DE SPRITES DEL WIZARD")
print("=" * 70)

folders = ["walk", "cast", "hit", "death"]

for folder in folders:
    folder_path = os.path.join(base_path, folder)
    if not os.path.exists(folder_path):
        continue
    
    print(f"\n{'='*70}")
    print(f"📁 {folder.upper()}/")
    print("=" * 70)
    
    for img_file in sorted(os.listdir(folder_path)):
        if not img_file.endswith(".png"):
            continue
        
        img_path = os.path.join(folder_path, img_file)
        frames, w, h, img = analyze_sprite_content(img_path)
        
        print(f"\n📄 {img_file}")
        print(f"   Dimensiones totales: {w}x{h}")
        print(f"   Frames detectados: {len(frames)}")
        
        for i, (x_start, x_end) in enumerate(frames):
            bounds = get_sprite_bounds(img, x_start, x_end)
            if bounds:
                print(f"   Frame {i+1}: x={x_start}-{x_end} ({x_end-x_start}px ancho)")
                print(f"            Contenido: {bounds['w']}x{bounds['h']} px")

print("\n" + "=" * 70)
print("RESUMEN PARA PROCESAMIENTO")
print("=" * 70)
