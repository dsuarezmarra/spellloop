#!/usr/bin/env python3
"""
Procesa AOE sprites 1x6 correctamente.
Extrae el contenido de cada celda SIN redimensionar, solo centrando por centroide.
"""

from PIL import Image, ImageEnhance
import numpy as np
from pathlib import Path


def process_1x6_correct(path, name, output_base):
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    
    print(f'=== {name} ({w}x{h}) ===')
    
    # 1 fila, 6 columnas
    cols = 6
    cell_w = w // cols
    
    print(f'Grid 1x6: celdas de {cell_w}x{h}')
    
    frames = []
    
    for col in range(cols):
        x1 = col * cell_w
        x2 = (col + 1) * cell_w if col < cols - 1 else w
        
        cell = img.crop((x1, 0, x2, h))
        cell_arr = np.array(cell)
        cell_alpha = cell_arr[:,:,3]
        
        # Encontrar bounding box del contenido
        rows_with = np.any(cell_alpha > 10, axis=1)
        cols_with = np.any(cell_alpha > 10, axis=0)
        
        if np.any(rows_with) and np.any(cols_with):
            cy1, cy2 = np.where(rows_with)[0][[0,-1]]
            cx1, cx2 = np.where(cols_with)[0][[0,-1]]
            content = cell.crop((cx1, cy1, cx2+1, cy2+1))
            
            # Calcular centroide del contenido
            content_alpha = np.array(content)[:,:,3].astype(float) / 255.0
            ch, cw = content_alpha.shape
            y_coords, x_coords = np.meshgrid(np.arange(ch), np.arange(cw), indexing='ij')
            total = np.sum(content_alpha)
            
            if total > 0:
                centroid_x = np.sum(x_coords * content_alpha) / total
                centroid_y = np.sum(y_coords * content_alpha) / total
            else:
                centroid_x = content.width / 2
                centroid_y = content.height / 2
            
            frames.append({
                'content': content,
                'centroid': (centroid_x, centroid_y)
            })
            print(f'  Frame {col+1}: {content.width}x{content.height}, centroide=({centroid_x:.1f}, {centroid_y:.1f})')
        else:
            print(f'  Frame {col+1}: vacío')
    
    if not frames:
        print('ERROR: No se encontraron frames')
        return None
    
    # Calcular frame_size basado en las distancias máximas desde el centroide
    max_left = max(f['centroid'][0] for f in frames)
    max_right = max(f['content'].width - f['centroid'][0] for f in frames)
    max_top = max(f['centroid'][1] for f in frames)
    max_bottom = max(f['content'].height - f['centroid'][1] for f in frames)
    
    # Frame size = máxima distancia * 2 + padding
    frame_size = int(max(max_left + max_right, max_top + max_bottom)) + 8
    frame_size = ((frame_size + 7) // 8) * 8  # Múltiplo de 8
    
    print(f'\nDistancias desde centroide: L={max_left:.0f}, R={max_right:.0f}, T={max_top:.0f}, B={max_bottom:.0f}')
    print(f'Frame size: {frame_size}x{frame_size}')
    
    center = frame_size // 2
    
    # Crear frames finales centrados por centroide
    final_frames = []
    for f in frames:
        content = f['content']
        cx, cy = f['centroid']
        
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        
        # Posición para que el centroide quede en el centro del frame
        paste_x = int(center - cx)
        paste_y = int(center - cy)
        
        frame.paste(content, (paste_x, paste_y), content)
        final_frames.append(frame)
    
    # Crear spritesheet horizontal
    sheet_width = frame_size * len(final_frames)
    spritesheet = Image.new('RGBA', (sheet_width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(final_frames):
        spritesheet.paste(frame, (i * frame_size, 0), frame)
    
    # Guardar active
    output_path = Path(output_base)
    active_path = output_path / f"aoe_active_{name}.png"
    spritesheet.save(active_path, 'PNG', optimize=False)
    print(f'\n✅ Guardado: {active_path.name}')
    
    # Crear y guardar impact (más brillante)
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    impact_path = output_path / f"aoe_impact_{name}.png"
    impact.save(impact_path, 'PNG', optimize=False)
    print(f'✅ Guardado: {impact_path.name}')
    
    # Guardar frames individuales
    frames_dir = output_path / "frames"
    frames_dir.mkdir(exist_ok=True)
    for i, frame in enumerate(final_frames):
        frame.save(frames_dir / f"frame_{i+1}.png", 'PNG', optimize=False)
    
    sprite_scale = round(64 / frame_size, 2)
    
    print(f'\n📏 Spritesheet: {sheet_width}x{frame_size} ({len(final_frames)} frames de {frame_size}x{frame_size})')
    print(f'🎮 Config: frame_size={frame_size}, sprite_scale={sprite_scale}')
    
    return {
        'frame_size': frame_size,
        'sprite_scale': sprite_scale,
        'num_frames': len(final_frames)
    }


if __name__ == "__main__":
    sources = [
        (r'C:\git\spellloop\project\assets\sprites\projectiles\weapons\void_pulse\unnamed-removebg-preview.png',
         'void_pulse',
         r'C:\git\spellloop\project\assets\sprites\projectiles\weapons\void_pulse'),
        
        (r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\seismic_bolt\unnamed-removebg-preview.png',
         'seismic_bolt',
         r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\seismic_bolt'),
        
        (r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\glacier\unnamed-removebg-preview.png',
         'glacier',
         r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\glacier'),
    ]
    
    results = {}
    
    for path, name, output in sources:
        result = process_1x6_correct(path, name, output)
        if result:
            results[name] = result
        print()
    
    print("="*60)
    print("CONFIG PARA ProjectileVisualManager.gd")
    print("="*60)
    for name, data in results.items():
        print(f'"{name}": {{"frame_size": {data["frame_size"]}, "sprite_scale": {data["sprite_scale"]}}},')
