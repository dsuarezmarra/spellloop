#!/usr/bin/env python3
"""
Procesa TODOS los sprites AOE usando CENTRO DE MASAS para corte correcto.
Calcula el centroide ponderado por alpha para centrar correctamente cada frame.
"""

import numpy as np
from PIL import Image, ImageEnhance
from pathlib import Path
import os


def calculate_centroid(alpha: np.ndarray) -> tuple:
    """
    Calcula el centro de masas (centroide) ponderado por alpha.
    Retorna (cx, cy) o None si está vacío.
    """
    if np.sum(alpha) == 0:
        return None
    
    # Crear coordenadas
    h, w = alpha.shape
    y_coords, x_coords = np.meshgrid(np.arange(h), np.arange(w), indexing='ij')
    
    # Normalizar alpha a [0, 1] para usar como pesos
    weights = alpha.astype(float) / 255.0
    total_weight = np.sum(weights)
    
    if total_weight == 0:
        return None
    
    cx = np.sum(x_coords * weights) / total_weight
    cy = np.sum(y_coords * weights) / total_weight
    
    return (cx, cy)


def get_content_bounds(alpha: np.ndarray, threshold: int = 10) -> tuple:
    """
    Obtiene los límites del contenido visible (bounding box).
    """
    rows_with = np.any(alpha > threshold, axis=1)
    cols_with = np.any(alpha > threshold, axis=0)
    
    if not np.any(rows_with) or not np.any(cols_with):
        return None
    
    y_min, y_max = np.where(rows_with)[0][[0, -1]]
    x_min, x_max = np.where(cols_with)[0][[0, -1]]
    
    return (x_min, y_min, x_max + 1, y_max + 1)


def process_aoe_with_centroid(weapon_id: str, cols: int = 3, rows: int = 2, target_display_size: int = 64):
    """
    Procesa un AOE usando centro de masas para centrar correctamente.
    
    Args:
        weapon_id: ID del arma
        cols: Columnas del grid
        rows: Filas del grid
        target_display_size: Tamaño deseado en pantalla (para calcular sprite_scale)
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
    
    w, h = img.size
    cell_w = w // cols
    cell_h = h // rows
    num_frames = cols * rows
    
    print(f"📷 Imagen original: {w}x{h}")
    print(f"📐 Grid: {cols}x{rows} = {num_frames} frames")
    print(f"📏 Celda teórica: {cell_w}x{cell_h}")
    
    # Extraer frames y calcular centroides
    frames_data = []
    
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
            
            bounds = get_content_bounds(cell_alpha)
            centroid = calculate_centroid(cell_alpha)
            
            if bounds and centroid:
                bx1, by1, bx2, by2 = bounds
                content = cell.crop(bounds)
                
                # Centroide relativo al contenido recortado
                rel_cx = centroid[0] - bx1
                rel_cy = centroid[1] - by1
                
                frames_data.append({
                    'num': frame_num,
                    'content': content,
                    'size': content.size,
                    'centroid': (rel_cx, rel_cy),
                    'centroid_original': centroid
                })
                print(f"   Frame {frame_num}: {content.size[0]}x{content.size[1]}, centroide=({centroid[0]:.1f}, {centroid[1]:.1f})")
            else:
                frames_data.append({
                    'num': frame_num,
                    'content': None,
                    'size': (0, 0),
                    'centroid': None
                })
                print(f"   Frame {frame_num}: vacío")
    
    # Encontrar el contenido más grande
    valid_frames = [f for f in frames_data if f['content'] is not None]
    if not valid_frames:
        print(f"❌ {weapon_id}: Todos los frames están vacíos")
        return None
    
    max_w = max(f['size'][0] for f in valid_frames)
    max_h = max(f['size'][1] for f in valid_frames)
    
    # Calcular el centroide promedio para usar como referencia
    avg_cx = np.mean([f['centroid'][0] for f in valid_frames])
    avg_cy = np.mean([f['centroid'][1] for f in valid_frames])
    
    print(f"\n📊 Contenido máximo: {max_w}x{max_h}")
    print(f"🎯 Centroide promedio relativo: ({avg_cx:.1f}, {avg_cy:.1f})")
    
    # Calcular el tamaño de frame necesario para que todos los centroides queden alineados
    # Necesitamos espacio para el contenido más grande centrado en su centroide
    
    # Distancia máxima desde el centroide a cada borde
    max_dist_left = 0
    max_dist_right = 0
    max_dist_top = 0
    max_dist_bottom = 0
    
    for f in valid_frames:
        if f['content']:
            w, h = f['size']
            cx, cy = f['centroid']
            
            max_dist_left = max(max_dist_left, cx)
            max_dist_right = max(max_dist_right, w - cx)
            max_dist_top = max(max_dist_top, cy)
            max_dist_bottom = max(max_dist_bottom, h - cy)
    
    # Tamaño de frame basado en distancias máximas desde centroide
    frame_w = int(max_dist_left + max_dist_right) + 16  # padding
    frame_h = int(max_dist_top + max_dist_bottom) + 16
    frame_size = max(frame_w, frame_h)
    frame_size = ((frame_size + 7) // 8) * 8  # Múltiplo de 8
    
    print(f"📐 Frame de salida: {frame_size}x{frame_size}")
    print(f"   Distancias desde centroide: L={max_dist_left:.0f}, R={max_dist_right:.0f}, T={max_dist_top:.0f}, B={max_dist_bottom:.0f}")
    
    # Centro del frame de salida
    output_center = frame_size // 2
    
    # Crear frames finales centrados por centroide
    final_frames = []
    
    for f in frames_data:
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        
        if f['content'] is None:
            final_frames.append(frame)
            continue
        
        content = f['content']
        cx, cy = f['centroid']
        
        # Posición de pegado: el centroide del contenido debe quedar en el centro del frame
        paste_x = int(output_center - cx)
        paste_y = int(output_center - cy)
        
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
    
    # Crear y guardar impact
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    
    output_impact = base_dir / f"aoe_impact_{weapon_id}.png"
    impact.save(output_impact, 'PNG', optimize=False)
    print(f"✅ Impact: {output_impact.name}")
    
    # Guardar frames individuales para debug
    frames_dir = base_dir / "frames"
    frames_dir.mkdir(exist_ok=True)
    
    for i, frame in enumerate(final_frames):
        frame_path = frames_dir / f"frame_{i+1}.png"
        frame.save(frame_path, 'PNG', optimize=False)
    
    # Calcular sprite_scale recomendado
    sprite_scale = target_display_size / frame_size
    
    print(f"\n📁 Frames guardados: {frames_dir}")
    print(f"📏 Spritesheet: {spritesheet_width}x{frame_size} ({len(final_frames)} frames de {frame_size}x{frame_size})")
    print(f"🎮 sprite_scale recomendado: {sprite_scale:.2f} (para ~{target_display_size}px en pantalla)")
    
    return {
        'frame_size': frame_size,
        'sprite_scale': round(sprite_scale, 2),
        'spritesheet_size': (spritesheet_width, frame_size),
        'num_frames': len(final_frames)
    }


def main():
    # Todos los AOEs con imagen fuente
    aoes_to_process = [
        'absolute_zero',
        'decay',
        'gaia', 
        'glacier',
        'radiant_stone',
        'rift_quake',
        'seismic_bolt',
        'void_storm'
    ]
    
    # Tamaño deseado en pantalla para AOE (un poco más grande que proyectiles normales)
    TARGET_DISPLAY_SIZE = 64
    
    results = {}
    
    for weapon_id in aoes_to_process:
        result = process_aoe_with_centroid(weapon_id, target_display_size=TARGET_DISPLAY_SIZE)
        if result:
            results[weapon_id] = result
    
    # Resumen final
    print("\n" + "="*60)
    print("RESUMEN - CONFIGURACIÓN RECOMENDADA")
    print("="*60)
    print("\nPara agregar a AOE_SPRITE_CONFIG en ProjectileVisualManager.gd:")
    print()
    
    for weapon_id, data in results.items():
        print(f'"{weapon_id}": {{"frame_size": {data["frame_size"]}, "sprite_scale": {data["sprite_scale"]}}},')
    
    print("\n" + "="*60)
    print("DETALLES POR ARMA")
    print("="*60)
    
    for weapon_id, data in results.items():
        print(f"\n{weapon_id}:")
        print(f"  Frame size: {data['frame_size']}x{data['frame_size']}")
        print(f"  Spritesheet: {data['spritesheet_size'][0]}x{data['spritesheet_size'][1]}")
        print(f"  sprite_scale: {data['sprite_scale']} -> ~{int(data['frame_size'] * data['sprite_scale'])}px en pantalla")


if __name__ == "__main__":
    main()
