#!/usr/bin/env python3
"""
Procesador directo para las imágenes de Ice Wand de ChatGPT
===========================================================
Arrastra las 3 imágenes PNG a este script o ejecútalo y te pedirá las rutas.

Las imágenes de ChatGPT tienen:
- Flight: 5 frames -> necesitamos 6 (duplicar frame 3)
- Impact: 5 frames -> necesitamos 6 (duplicar frame 3) 
- Launch: 4 frames -> perfecto, no cambiar
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
    input("Presiona Enter para salir...")
    sys.exit(1)


def find_sprites_in_image(img):
    """Detecta sprites individuales buscando gaps de transparencia."""
    arr = np.array(img)
    alpha = arr[:, :, 3]
    
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


def extract_and_center(img, bbox, frame_size=64):
    """Extrae un sprite y lo centra en un frame de tamaño fijo."""
    x1, y1, x2, y2 = bbox
    sprite = img.crop((x1, y1, x2, y2))
    
    # Redimensionar si es muy grande
    w, h = sprite.size
    max_size = int(frame_size * 0.85)
    
    if w > max_size or h > max_size:
        scale = min(max_size / w, max_size / h)
        sprite = sprite.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)
        w, h = sprite.size
    
    # Crear frame y centrar
    frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    x = (frame_size - w) // 2
    y = (frame_size - h) // 2
    frame.paste(sprite, (x, y), sprite)
    
    return frame


def process_spritesheet(input_path, target_frames, duplicate_frame=None):
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
    
    # Detectar sprites
    bboxes = find_sprites_in_image(img)
    print(f"  Sprites detectados: {len(bboxes)}")
    
    if not bboxes:
        print("  ❌ ERROR: No se detectaron sprites")
        return None
    
    # Extraer y procesar cada sprite
    frames = []
    for i, bbox in enumerate(bboxes):
        frame = extract_and_center(img, bbox, frame_size=64)
        frames.append(frame)
        x1, y1, x2, y2 = bbox
        print(f"    Frame {i+1}: {x2-x1}x{y2-y1}px → 64x64px (centrado)")
    
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
    width = 64 * len(frames)
    spritesheet = Image.new('RGBA', (width, 64), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * 64, 0))
    
    print(f"\n  ✅ Spritesheet final: {width}x64 ({len(frames)} frames)")
    
    return spritesheet


def main():
    print("="*60)
    print("  PROCESADOR DE SPRITESHEETS - ICE WAND (ChatGPT)")  
    print("="*60)
    
    # Carpeta de salida
    output_dir = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\ice_wand")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Configuración de cada animación
    configs = [
        {
            "name": "flight",
            "target_frames": 6,
            "duplicate_frame": 2,  # Frame 3 (mitad de la rotación)
            "prompt": "FLIGHT (cristal volando, 5 frames → 6)"
        },
        {
            "name": "impact",
            "target_frames": 6, 
            "duplicate_frame": 2,  # Frame 3 (explosión máxima)
            "prompt": "IMPACT (cristal rompiéndose, 5 frames → 6)"
        },
        {
            "name": "launch",
            "target_frames": 4,
            "duplicate_frame": None,  # Ya tiene 4
            "prompt": "LAUNCH (cristal formándose, 4 frames)"
        }
    ]
    
    # Obtener rutas de entrada
    downloads = Path(r"C:\Users\Usuario\Downloads")
    
    # Listar PNGs recientes
    png_files = sorted(downloads.glob("*.png"), key=os.path.getmtime, reverse=True)[:20]
    
    if png_files:
        print("\nArchivos PNG recientes en Downloads:")
        for i, f in enumerate(png_files, 1):
            print(f"  [{i:2d}] {f.name}")
    
    print("\n" + "─"*60)
    
    for config in configs:
        print(f"\n>> {config['prompt']}")
        
        try:
            choice = input(f"   Número del archivo (0=saltar, ruta=directa): ").strip()
            
            if choice == "0" or not choice:
                print("   Saltando...")
                continue
            
            # Determinar ruta de entrada
            if choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(png_files):
                    input_path = png_files[idx]
                else:
                    print(f"   ❌ Índice inválido")
                    continue
            else:
                input_path = Path(choice.strip('"'))
                if not input_path.exists():
                    print(f"   ❌ Archivo no encontrado: {input_path}")
                    continue
            
            # Procesar
            result = process_spritesheet(
                str(input_path),
                config["target_frames"],
                config["duplicate_frame"]
            )
            
            if result:
                output_path = output_dir / f"{config['name']}.png"
                result.save(str(output_path), 'PNG')
                print(f"\n  💾 Guardado: {output_path}")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "="*60)
    print("  PROCESO COMPLETADO")
    print("="*60)
    print(f"\nArchivos generados en:\n  {output_dir}")
    print("\nEstructura esperada:")
    print("  ice_wand/")
    print("    ├── flight.png  (384x64, 6 frames)")
    print("    ├── impact.png  (384x64, 6 frames)")
    print("    └── launch.png  (256x64, 4 frames)")
    
    input("\nPresiona Enter para salir...")


if __name__ == "__main__":
    main()
