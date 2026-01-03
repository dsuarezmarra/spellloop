#!/usr/bin/env python3
"""
process_storm_caller.py
Procesador de sprites para Storm Caller (Invocador de Tormentas)
Lightning + Wind = Tormenta eléctrica azul-púrpura

Archivos de entrada (desde ChatGPT/DALL-E con fondo removido):
- unnamed-removebg-preview.png: 4 sprites de IMPACT (explosiones ~155px cuadrados)
- unnamed-removebg-preview (1).png: 4 sprites de FLIGHT (rayos horizontales ~320px)

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
SPRITE_FOLDER = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\storm_caller")

# Archivos de entrada
IMPACT_FILE = "unnamed-removebg-preview.png"
FLIGHT_FILE = "unnamed-removebg-preview (1).png"


# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

def find_components(img_array, min_area=100):
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


def extract_and_center(img, bbox, target_size):
    """Extrae un sprite y lo centra en el tamaño objetivo."""
    x1, y1, x2, y2 = bbox
    sprite = img.crop((x1, y1, x2, y2))
    
    # Crear canvas del tamaño objetivo
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Escalar si es necesario
    w, h = sprite.size
    scale = min(target_size / w, target_size / h) * 0.9  # 90% para dejar margen
    
    if scale < 1:
        new_w = int(w * scale)
        new_h = int(h * scale)
        sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Centrar
    w, h = sprite.size
    offset_x = (target_size - w) // 2
    offset_y = (target_size - h) // 2
    result.paste(sprite, (offset_x, offset_y), sprite)
    
    return result


def extract_horizontal_fit(img, bbox, target_w, target_h):
    """Extrae un sprite horizontal y lo ajusta para llenar el ancho."""
    x1, y1, x2, y2 = bbox
    sprite = img.crop((x1, y1, x2, y2))
    
    w, h = sprite.size
    
    # Para FLIGHT: queremos que llene todo el ancho (64px)
    # y se centre verticalmente
    scale_x = target_w / w
    scale_y = (target_h * 0.8) / h  # 80% de altura para dejar margen
    
    # Usar el mismo scale para mantener proporciones, priorizando ancho
    scale = scale_x
    new_w = int(w * scale)
    new_h = int(h * scale)
    
    # Limitar altura
    if new_h > target_h * 0.9:
        scale = (target_h * 0.8) / h
        new_w = int(w * scale)
        new_h = int(h * scale)
    
    sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Crear canvas
    result = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    
    # Centrar
    offset_x = (target_w - new_w) // 2
    offset_y = (target_h - new_h) // 2
    result.paste(sprite, (offset_x, offset_y), sprite)
    
    return result


# ═══════════════════════════════════════════════════════════════════════════════
# PROCESAMIENTO
# ═══════════════════════════════════════════════════════════════════════════════

def process_impact():
    """Procesa los sprites de IMPACT (explosiones cuadradas)."""
    print("\n" + "─" * 50)
    print("Procesando: IMPACT (explosiones)")
    print("─" * 50)
    
    img_path = SPRITE_FOLDER / IMPACT_FILE
    if not img_path.exists():
        print(f"  ❌ ERROR: No encontrado: {img_path}")
        return
    
    img = Image.open(img_path).convert('RGBA')
    arr = np.array(img)
    print(f"  Imagen: {img.size[0]}x{img.size[1]}")
    
    components = find_components(arr, min_area=5000)
    print(f"  Componentes encontrados: {len(components)}")
    
    # Ordenar por posición (fila primero, luego columna)
    components.sort(key=lambda c: (c['center'][1], c['center'][0]))
    
    # Crear spritesheet
    spritesheet = Image.new('RGBA', (SPRITESHEET_WIDTH, SPRITESHEET_HEIGHT), (0, 0, 0, 0))
    
    for i, comp in enumerate(components[:NUM_FRAMES]):
        print(f"    Frame {i+1}: bbox={comp['bbox']}, size={comp['size']}")
        frame = extract_and_center(img, comp['bbox'], FRAME_SIZE)
        spritesheet.paste(frame, (i * FRAME_SIZE, 0), frame)
    
    output_path = SPRITE_FOLDER / "impact_spritesheet_storm_caller.png"
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
    
    components = find_components(arr, min_area=10000)
    print(f"  Componentes encontrados: {len(components)}")
    
    # Ordenar: primero los de arriba (menor Y), luego por X
    components.sort(key=lambda c: (c['center'][1], c['center'][0]))
    
    # Crear spritesheet
    spritesheet = Image.new('RGBA', (SPRITESHEET_WIDTH, SPRITESHEET_HEIGHT), (0, 0, 0, 0))
    
    for i, comp in enumerate(components[:NUM_FRAMES]):
        print(f"    Frame {i+1}: bbox={comp['bbox']}, size={comp['size']}")
        frame = extract_horizontal_fit(img, comp['bbox'], FRAME_SIZE, FRAME_SIZE)
        spritesheet.paste(frame, (i * FRAME_SIZE, 0), frame)
    
    output_path = SPRITE_FOLDER / "flight_spritesheet_storm_caller.png"
    spritesheet.save(output_path)
    print(f"  ✅ Guardado: {output_path.name}")
    print(f"     Tamaño: {SPRITESHEET_WIDTH}x{SPRITESHEET_HEIGHT} ({NUM_FRAMES} frames)")


def main():
    print("=" * 60)
    print("  PROCESADOR DE SPRITESHEETS - STORM CALLER")
    print("=" * 60)
    print(f"\nCarpeta: {SPRITE_FOLDER}\n")
    
    # Verificar que la carpeta existe
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
