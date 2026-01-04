#!/usr/bin/env python3
"""
Procesa los nuevos sprites AOE con estructura 2x3 (2 filas, 3 columnas).
Batch 2: gaia, glacier, seismic_bolt, void_storm
"""

from PIL import Image, ImageEnhance
import numpy as np
from pathlib import Path


def calculate_centroid(alpha: np.ndarray) -> tuple:
    """Calcula el centro de masas ponderado por alpha."""
    if np.sum(alpha) == 0:
        return None
    
    h, w = alpha.shape
    y_coords, x_coords = np.meshgrid(np.arange(h), np.arange(w), indexing='ij')
    weights = alpha.astype(float) / 255.0
    total_weight = np.sum(weights)
    
    if total_weight == 0:
        return None
    
    cx = np.sum(x_coords * weights) / total_weight
    cy = np.sum(y_coords * weights) / total_weight
    
    return (cx, cy)


def process_2x3(path, name, output_base):
    """
    Procesa sprite con grid 2x3 (2 filas, 3 columnas = 6 frames).
    Lee de izquierda a derecha, de arriba a abajo.
    """
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    
    print(f'=== {name} ({w}x{h}) ===')
    
    # 2 filas, 3 columnas
    rows, cols = 2, 3
    cell_w = w // cols
    cell_h = h // rows
    
    print(f'Grid 2x3: celdas de {cell_w}x{cell_h}')
    
    frames = []
    centroids = []
    
    # Recorrer fila por fila, columna por columna
    for row in range(rows):
        for col in range(cols):
            x1 = col * cell_w
            x2 = (col + 1) * cell_w if col < cols - 1 else w
            y1 = row * cell_h
            y2 = (row + 1) * cell_h if row < rows - 1 else h
            
            cell = img.crop((x1, y1, x2, y2))
            cell_arr = np.array(cell)
            cell_alpha = cell_arr[:, :, 3]
            
            # Bounding box del contenido
            rows_with = np.any(cell_alpha > 10, axis=1)
            cols_with = np.any(cell_alpha > 10, axis=0)
            
            if np.any(rows_with) and np.any(cols_with):
                cy1, cy2 = np.where(rows_with)[0][[0, -1]]
                cx1, cx2 = np.where(cols_with)[0][[0, -1]]
                content = cell.crop((cx1, cy1, cx2 + 1, cy2 + 1))
                
                # Centroide del contenido
                content_alpha = np.array(content)[:, :, 3]
                centroid = calculate_centroid(content_alpha)
                
                if centroid:
                    frames.append(content)
                    centroids.append(centroid)
                    frame_num = row * cols + col + 1
                    print(f'  Frame {frame_num}: {content.width}x{content.height}, centroide=({centroid[0]:.1f}, {centroid[1]:.1f})')
            else:
                frame_num = row * cols + col + 1
                print(f'  Frame {frame_num}: vacío')
    
    if not frames:
        print('ERROR: No se encontraron frames')
        return None
    
    # Calcular frame_size basado en distancias desde centroide
    max_left = max(c[0] for c in centroids)
    max_right = max(f.width - c[0] for f, c in zip(frames, centroids))
    max_top = max(c[1] for c in centroids)
    max_bottom = max(f.height - c[1] for f, c in zip(frames, centroids))
    
    frame_size = int(max(max_left + max_right, max_top + max_bottom)) + 8
    frame_size = ((frame_size + 7) // 8) * 8  # Múltiplo de 8
    
    print(f'\nDistancias desde centroide: L={max_left:.0f}, R={max_right:.0f}, T={max_top:.0f}, B={max_bottom:.0f}')
    print(f'Frame size: {frame_size}x{frame_size}')
    
    center = frame_size // 2
    
    # Crear frames finales centrados por centroide
    final_frames = []
    for content, (cx, cy) in zip(frames, centroids):
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
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
    
    # Crear y guardar impact
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
    base = Path(r'C:\git\spellloop\project\assets\sprites\projectiles\fusion')
    
    sources = [
        (base / 'gaia' / 'unnamed-removebg-preview.png', 'gaia', base / 'gaia'),
        (base / 'glacier' / 'unnamed-removebg-preview (1).png', 'glacier', base / 'glacier'),
        (base / 'seismic_bolt' / 'unnamed-removebg-preview.png', 'seismic_bolt', base / 'seismic_bolt'),
        (base / 'void_storm' / 'unnamed-removebg-preview.png', 'void_storm', base / 'void_storm'),
    ]
    
    results = {}
    
    for path, name, output in sources:
        if path.exists():
            result = process_2x3(str(path), name, str(output))
            if result:
                results[name] = result
        else:
            print(f'❌ No existe: {path}')
        print()
    
    print("="*60)
    print("CONFIG PARA ProjectileVisualManager.gd")
    print("="*60)
    for name, data in results.items():
        print(f'"{name}": {{"frame_size": {data["frame_size"]}, "sprite_scale": {data["sprite_scale"]}}},')
