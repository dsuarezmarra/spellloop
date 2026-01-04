#!/usr/bin/env python3
"""
Procesa los sprites de Aurora (BEAM):
1. beam_body_aurora.png - tileable horizontal desde grid 2x3 (selecciona el mejor frame)
2. beam_tip_aurora.png - spritesheet de 6 frames desde grid 2x3
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


def extract_2x3_frames(img_path):
    """Extrae 6 frames de un grid 2x3."""
    img = Image.open(img_path).convert('RGBA')
    w, h = img.size
    
    rows, cols = 2, 3
    cell_w = w // cols
    cell_h = h // rows
    
    frames = []
    
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
                frames.append(content)
            else:
                frames.append(None)
    
    return frames


def process_beam_body(source_path, output_path, name):
    """
    Procesa el sprite tileable del beam_body.
    El beam_body debería ser una textura horizontal que se repite.
    """
    print(f'\n=== BEAM BODY: {name} ===')
    
    img = Image.open(source_path).convert('RGBA')
    w, h = img.size
    print(f'Fuente: {w}x{h}')
    
    # Extraer frames del grid 2x3
    frames = extract_2x3_frames(source_path)
    valid_frames = [f for f in frames if f is not None]
    
    if not valid_frames:
        print('ERROR: No se encontraron frames válidos')
        return None
    
    print(f'Frames extraídos: {len(valid_frames)}')
    for i, f in enumerate(valid_frames):
        if f:
            print(f'  Frame {i+1}: {f.width}x{f.height}')
    
    # Para beam_body tileable, necesitamos una textura que se repita bien horizontalmente.
    # El beam_body típico es de 64x32 (ancho x alto).
    # Usamos el primer frame y lo procesamos para ser tileable.
    
    # Seleccionar el frame más ancho (mejor para tileable)
    best_frame = max(valid_frames, key=lambda f: f.width)
    print(f'\nUsando frame más ancho: {best_frame.width}x{best_frame.height}')
    
    # El beam body necesita ser horizontal - más ancho que alto
    # Si el frame es más alto que ancho, hay que recortar o ajustar
    
    # Calcular el bounding box real del contenido
    arr = np.array(best_frame)
    alpha = arr[:, :, 3]
    
    rows_with = np.any(alpha > 10, axis=1)
    cols_with = np.any(alpha > 10, axis=0)
    
    if np.any(rows_with) and np.any(cols_with):
        y1, y2 = np.where(rows_with)[0][[0, -1]]
        x1, x2 = np.where(cols_with)[0][[0, -1]]
        content = best_frame.crop((x1, y1, x2 + 1, y2 + 1))
    else:
        content = best_frame
    
    print(f'Contenido recortado: {content.width}x{content.height}')
    
    # El beam_body tileable típico es 64x32
    # Escalamos el contenido para que encaje bien
    target_height = 32
    scale_factor = target_height / content.height
    new_width = int(content.width * scale_factor)
    
    # Redimensionar manteniendo calidad
    content_resized = content.resize((new_width, target_height), Image.Resampling.LANCZOS)
    
    # Hacer que el ancho sea múltiplo de 16 para mejor tiling
    final_width = ((new_width + 15) // 16) * 16
    if final_width < 64:
        final_width = 64
    
    # Crear imagen final centrada
    final = Image.new('RGBA', (final_width, target_height), (0, 0, 0, 0))
    paste_x = (final_width - content_resized.width) // 2
    final.paste(content_resized, (paste_x, 0), content_resized)
    
    # Guardar
    output_file = output_path / f'beam_body_{name}.png'
    final.save(output_file, 'PNG', optimize=False)
    print(f'\n✅ Guardado: {output_file.name} ({final.width}x{final.height})')
    
    return {'width': final.width, 'height': final.height}


def process_beam_tip(source_path, output_path, name):
    """
    Procesa el spritesheet de beam_tip.
    Extrae 6 frames del grid 2x3 y crea un spritesheet horizontal.
    """
    print(f'\n=== BEAM TIP: {name} ===')
    
    img = Image.open(source_path).convert('RGBA')
    w, h = img.size
    print(f'Fuente: {w}x{h}')
    
    # Extraer frames del grid 2x3
    rows, cols = 2, 3
    cell_w = w // cols
    cell_h = h // rows
    
    print(f'Grid 2x3: celdas de {cell_w}x{cell_h}')
    
    frames = []
    centroids = []
    
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
    
    # Guardar
    output_file = output_path / f'beam_tip_{name}.png'
    spritesheet.save(output_file, 'PNG', optimize=False)
    print(f'\n✅ Guardado: {output_file.name}')
    
    # Guardar frames individuales para debug
    frames_dir = output_path / 'tip_frames'
    frames_dir.mkdir(exist_ok=True)
    for i, frame in enumerate(final_frames):
        frame.save(frames_dir / f'tip_frame_{i+1}.png', 'PNG', optimize=False)
    
    print(f'📏 Spritesheet: {sheet_width}x{frame_size} ({len(final_frames)} frames de {frame_size}x{frame_size})')
    
    return {
        'frame_size': frame_size,
        'num_frames': len(final_frames),
        'sheet_width': sheet_width
    }


if __name__ == "__main__":
    base = Path(r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\aurora')
    
    # Procesar beam_body (tileable) - unnamed-removebg-preview.png
    body_source = base / 'unnamed-removebg-preview.png'
    if body_source.exists():
        body_result = process_beam_body(body_source, base, 'aurora')
    else:
        print(f'❌ No existe: {body_source}')
    
    # Procesar beam_tip (spritesheet) - tip.png
    tip_source = base / 'tip.png'
    if tip_source.exists():
        tip_result = process_beam_tip(tip_source, base, 'aurora')
    else:
        print(f'❌ No existe: {tip_source}')
    
    print("\n" + "="*60)
    print("RESUMEN")
    print("="*60)
    if body_result:
        print(f"beam_body_aurora.png: {body_result['width']}x{body_result['height']}")
    if tip_result:
        print(f"beam_tip_aurora.png: {tip_result['sheet_width']}x{tip_result['frame_size']} ({tip_result['num_frames']} frames)")
        print(f"\nConfig para ProjectileVisualManager.gd:")
        print(f'"aurora": {{"beam_frame_size": {tip_result["frame_size"]}, ...}}')
