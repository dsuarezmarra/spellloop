#!/usr/bin/env python3
"""
Procesa TODOS los sprites AOE desde sus imágenes fuente originales.
Extrae frames desde grid 3x2 sin pérdida de calidad.
"""

import numpy as np
from PIL import Image, ImageEnhance
from pathlib import Path
import os


def process_aoe_grid(weapon_id: str, cols: int = 3, rows: int = 2):
    """
    Procesa un AOE desde su imagen fuente en formato grid.
    """
    base_dir = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\fusion") / weapon_id
    input_path = base_dir / "unnamed-removebg-preview.png"
    
    if not input_path.exists():
        print(f"❌ {weapon_id}: No existe imagen fuente")
        return None
    
    print(f"\n{'='*60}")
    print(f"PROCESANDO: {weapon_id.upper()}")
    print(f"{'='*60}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    arr = np.array(img)
    alpha = arr[:, :, 3]
    
    w, h = img.size
    cell_w = w // cols
    cell_h = h // rows
    num_frames = cols * rows
    
    print(f"📷 Imagen: {w}x{h}")
    print(f"📐 Grid: {cols}x{rows} = {num_frames} frames")
    print(f"📏 Celda: {cell_w}x{cell_h}")
    
    # Extraer frames
    frames = []
    frame_info = []
    
    for row in range(rows):
        for col in range(cols):
            frame_num = row * cols + col + 1
            
            x1 = col * cell_w
            x2 = (col + 1) * cell_w if col < cols - 1 else w
            y1 = row * cell_h
            y2 = (row + 1) * cell_h if row < rows - 1 else h
            
            cell = img.crop((x1, y1, x2, y2))
            cell_arr = np.array(cell)
            cell_alpha = cell_arr[:, :, 3]
            
            rows_with = np.any(cell_alpha > 10, axis=1)
            cols_with = np.any(cell_alpha > 10, axis=0)
            
            if np.any(rows_with) and np.any(cols_with):
                cy_min, cy_max = np.where(rows_with)[0][[0, -1]]
                cx_min, cx_max = np.where(cols_with)[0][[0, -1]]
                
                content = cell.crop((cx_min, cy_min, cx_max + 1, cy_max + 1))
                frames.append(content)
                frame_info.append({
                    'num': frame_num,
                    'size': content.size
                })
                print(f"   Frame {frame_num}: {content.size[0]}x{content.size[1]}")
            else:
                frames.append(None)
                frame_info.append({'num': frame_num, 'size': (0, 0)})
                print(f"   Frame {frame_num}: vacío")
    
    # Tamaño máximo de contenido
    max_w = max(f['size'][0] for f in frame_info if f['size'][0] > 0)
    max_h = max(f['size'][1] for f in frame_info if f['size'][1] > 0)
    
    # Frame de salida con padding
    padding = 8
    frame_size = max(max_w, max_h) + padding
    frame_size = ((frame_size + 7) // 8) * 8  # Múltiplo de 8
    
    print(f"\n📊 Contenido máximo: {max_w}x{max_h}")
    print(f"📐 Frame de salida: {frame_size}x{frame_size}")
    
    # Crear frames finales centrados
    final_frames = []
    
    for content in frames:
        if content is None:
            final_frames.append(Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0)))
            continue
        
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        paste_x = (frame_size - content.width) // 2
        paste_y = (frame_size - content.height) // 2
        frame.paste(content, (paste_x, paste_y), content)
        final_frames.append(frame)
    
    # Crear spritesheet
    spritesheet_width = frame_size * len(final_frames)
    spritesheet = Image.new('RGBA', (spritesheet_width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(final_frames):
        spritesheet.paste(frame, (i * frame_size, 0), frame)
    
    # Guardar active
    output_active = base_dir / f"aoe_active_{weapon_id}.png"
    spritesheet.save(output_active, 'PNG', optimize=False)
    print(f"\n✅ Active: {output_active.name}")
    
    # Crear y guardar impact (más brillante)
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    
    output_impact = base_dir / f"aoe_impact_{weapon_id}.png"
    impact.save(output_impact, 'PNG', optimize=False)
    print(f"✅ Impact: {output_impact.name}")
    
    # Guardar frames individuales
    frames_dir = base_dir / "frames"
    frames_dir.mkdir(exist_ok=True)
    
    for i, frame in enumerate(final_frames):
        frame_path = frames_dir / f"frame_{i+1}.png"
        frame.save(frame_path, 'PNG', optimize=False)
    
    print(f"📁 Frames: {frames_dir}")
    print(f"📏 Spritesheet: {spritesheet_width}x{frame_size} ({len(final_frames)} frames de {frame_size}x{frame_size})")
    
    return frame_size


def main():
    # AOEs con imagen fuente original
    aoes_to_process = [
        'decay',
        'gaia', 
        'glacier',
        'radiant_stone',
        'rift_quake',
        'seismic_bolt',
        'void_storm'
    ]
    
    results = {}
    
    print("\n" + "=" * 60)
    print("PROCESANDO TODOS LOS AOE SPRITES")
    print("=" * 60)
    
    for aoe in aoes_to_process:
        frame_size = process_aoe_grid(aoe)
        if frame_size:
            results[aoe] = frame_size
    
    # Resumen final
    print("\n" + "=" * 60)
    print("RESUMEN - Configuración para ProjectileVisualManager.gd")
    print("=" * 60)
    
    for weapon_id, frame_size in results.items():
        # Calcular sprite_scale para que visualmente sea ~64px
        sprite_scale = round(64.0 / frame_size, 2)
        print(f'"{weapon_id}": {{"frame_size": {frame_size}, "sprite_scale": {sprite_scale}}}')


if __name__ == '__main__':
    main()
