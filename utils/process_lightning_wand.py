#!/usr/bin/env python3
"""
Procesador de sprites para Lightning Wand (Varita de Rayo)
==========================================================
Procesa las imágenes de flight e impact generadas por ChatGPT
para crear spritesheets compatibles con el sistema chain del juego.

Estructura esperada de entrada:
- flight.png: Rayo/bolt (4+ frames horizontales)
- impact.png: Efecto zap de impacto (4+ frames horizontales)

Estructura de salida:
- flight_spritesheet_lightning_wand.png (256x64, 4 frames)
- impact_spritesheet_lightning_wand.png (256x64, 4 frames)
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("="*50)
    print("ERROR: Necesitas instalar las dependencias")
    print("="*50)
    print("\nEjecuta este comando:")
    print("  pip install Pillow numpy")
    print()
    sys.exit(1)


# Configuración
INPUT_DIR = Path(r"C:\Users\dsuarez1\git\spellloop\project\assets\sprites\projectiles\weapons\lightning_wand")
OUTPUT_DIR = INPUT_DIR
FRAME_SIZE = 64
TARGET_FRAMES = 4  # Chain usa 4 frames


def find_sprites_in_image(img):
    """Detecta sprites individuales buscando gaps de transparencia."""
    arr = np.array(img)
    
    # Manejar imágenes con o sin canal alpha
    if arr.shape[2] == 4:
        alpha = arr[:, :, 3]
    else:
        # Si no hay alpha, usar luminancia para detectar contenido
        alpha = np.mean(arr[:, :, :3], axis=2)
    
    # Encontrar columnas con contenido
    col_has_content = np.any(alpha > 10, axis=0)
    
    # Encontrar rangos de sprites
    sprites = []
    in_sprite = False
    start_x = 0
    
    for x in range(len(col_has_content)):
        if col_has_content[x] and not in_sprite:
            in_sprite = True
            start_x = x
        elif not col_has_content[x] and in_sprite:
            in_sprite = False
            if x - start_x >= 15:  # Mínimo 15px de ancho
                sprites.append((start_x, x))
    
    if in_sprite:
        sprites.append((start_x, len(col_has_content)))
    
    # Obtener bounding boxes completos
    bboxes = []
    for x_start, x_end in sprites:
        region_alpha = alpha[:, x_start:x_end]
        row_has_content = np.any(region_alpha > 10, axis=1)
        y_indices = np.where(row_has_content)[0]
        if len(y_indices) > 0:
            y_start = y_indices[0]
            y_end = y_indices[-1] + 1
            bboxes.append((x_start, y_start, x_end, y_end))
    
    return bboxes


def detect_grid_frames(img, expected_frames=4):
    """
    Detecta frames asumiendo una grilla uniforme.
    Útil cuando los sprites no tienen gaps claros entre ellos.
    """
    width, height = img.size
    
    # Intentar detectar si es una tira horizontal
    if width > height:
        # Asumir tira horizontal
        frame_width = width // expected_frames
        bboxes = []
        for i in range(expected_frames):
            x1 = i * frame_width
            x2 = (i + 1) * frame_width
            bboxes.append((x1, 0, x2, height))
        return bboxes
    
    return []


def extract_and_center(img, bbox, frame_size=64):
    """Extrae un sprite y lo centra en un frame de tamaño fijo."""
    x1, y1, x2, y2 = bbox
    sprite = img.crop((x1, y1, x2, y2))
    
    # Redimensionar si es muy grande
    w, h = sprite.size
    max_size = int(frame_size * 0.90)  # 90% del frame
    
    if w > max_size or h > max_size:
        scale = min(max_size / w, max_size / h)
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
        w, h = sprite.size
    
    # Crear frame y centrar
    frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    x = (frame_size - w) // 2
    y = (frame_size - h) // 2
    frame.paste(sprite, (x, y), sprite if sprite.mode == 'RGBA' else None)
    
    return frame


def process_spritesheet(input_path, target_frames=4, duplicate_frame=None):
    """
    Procesa un spritesheet de IA.
    
    Args:
        input_path: Ruta al PNG
        target_frames: Número de frames deseado
        duplicate_frame: Índice (0-based) del frame a duplicar si faltan
    
    Returns:
        Image con el spritesheet procesado
    """
    print(f"\n{'─'*50}")
    print(f"Procesando: {Path(input_path).name}")
    print(f"{'─'*50}")
    
    # Cargar
    img = Image.open(input_path).convert('RGBA')
    print(f"  Tamaño original: {img.size[0]}x{img.size[1]}")
    
    # Detectar sprites por gaps
    bboxes = find_sprites_in_image(img)
    print(f"  Sprites detectados por gaps: {len(bboxes)}")
    
    # Si no detectamos suficientes, intentar grilla
    if len(bboxes) < 2:
        print(f"  Intentando detección por grilla...")
        bboxes = detect_grid_frames(img, target_frames)
        print(f"  Sprites detectados por grilla: {len(bboxes)}")
    
    if not bboxes:
        print("  ❌ ERROR: No se detectaron sprites")
        return None
    
    # Extraer y procesar cada sprite
    frames = []
    for i, bbox in enumerate(bboxes):
        frame = extract_and_center(img, bbox, frame_size=FRAME_SIZE)
        frames.append(frame)
        x1, y1, x2, y2 = bbox
        print(f"    Frame {i+1}: {x2-x1}x{y2-y1}px → {FRAME_SIZE}x{FRAME_SIZE}px (centrado)")
    
    # Ajustar número de frames
    current = len(frames)
    
    if current < target_frames:
        to_add = target_frames - current
        if duplicate_frame is None:
            duplicate_frame = current // 2
        duplicate_frame = min(duplicate_frame, current - 1)
        
        print(f"\n  Ajustando: {current} → {target_frames} frames")
        print(f"  Duplicando frame {duplicate_frame + 1}")
        
        for _ in range(to_add):
            frames.insert(duplicate_frame + 1, frames[duplicate_frame].copy())
    
    elif current > target_frames:
        print(f"\n  Ajustando: {current} → {target_frames} frames (recortando)")
        frames = frames[:target_frames]
    
    # Crear spritesheet horizontal
    width = FRAME_SIZE * len(frames)
    spritesheet = Image.new('RGBA', (width, FRAME_SIZE), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * FRAME_SIZE, 0))
    
    print(f"\n  ✅ Spritesheet final: {width}x{FRAME_SIZE} ({len(frames)} frames)")
    
    return spritesheet


def main():
    print("="*60)
    print("  PROCESADOR DE SPRITESHEETS - LIGHTNING WAND")  
    print("="*60)
    
    # Verificar carpeta de entrada
    if not INPUT_DIR.exists():
        print(f"\n❌ ERROR: No existe la carpeta: {INPUT_DIR}")
        return
    
    print(f"\nCarpeta: {INPUT_DIR}")
    
    # Configuración de cada animación
    configs = [
        {
            "input": "flight.png",
            "output": "flight_spritesheet_lightning_wand.png",
            "target_frames": 4,
            "duplicate_frame": 1,  # Frame 2 si falta
            "description": "FLIGHT/BOLT (rayo conectando enemigos)"
        },
        {
            "input": "impact.png",
            "output": "impact_spritesheet_lightning_wand.png",
            "target_frames": 4,
            "duplicate_frame": 1,  # Frame 2 si falta  
            "description": "IMPACT/ZAP (efecto al golpear)"
        }
    ]
    
    results = []
    
    for config in configs:
        input_path = INPUT_DIR / config["input"]
        output_path = OUTPUT_DIR / config["output"]
        
        print(f"\n>> {config['description']}")
        
        if not input_path.exists():
            print(f"   ⚠️ No encontrado: {config['input']}")
            continue
        
        try:
            result = process_spritesheet(
                str(input_path),
                config["target_frames"],
                config["duplicate_frame"]
            )
            
            if result:
                result.save(str(output_path), 'PNG')
                print(f"\n  💾 Guardado: {output_path.name}")
                results.append(config["output"])
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "="*60)
    print("  PROCESO COMPLETADO")
    print("="*60)
    
    if results:
        print(f"\nArchivos generados en:\n  {OUTPUT_DIR}")
        print("\nEstructura:")
        print("  lightning_wand/")
        for r in results:
            print(f"    ├── {r}")
        print("\nFormato: 256x64 (4 frames de 64x64)")
    else:
        print("\n⚠️ No se generaron archivos")


if __name__ == "__main__":
    main()
