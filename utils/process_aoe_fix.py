#!/usr/bin/env python3
"""
Procesa sprites AOE problemáticos con detección automática de grid y centrado por centroide.
Maneja grids irregulares y diferentes layouts.
"""

import numpy as np
from PIL import Image, ImageEnhance
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


def get_content_bounds(alpha: np.ndarray, threshold: int = 10) -> tuple:
    """Obtiene bounding box del contenido visible."""
    rows_with = np.any(alpha > threshold, axis=1)
    cols_with = np.any(alpha > threshold, axis=0)
    
    if not np.any(rows_with) or not np.any(cols_with):
        return None
    
    y_min, y_max = np.where(rows_with)[0][[0, -1]]
    x_min, x_max = np.where(cols_with)[0][[0, -1]]
    
    return (x_min, y_min, x_max + 1, y_max + 1)


def extract_frames_from_grid(img: Image.Image, cols: int, rows: int) -> list:
    """
    Extrae frames de un grid, manejando divisiones no exactas.
    """
    arr = np.array(img)
    w, h = img.size
    
    frames_data = []
    
    for row in range(rows):
        for col in range(cols):
            # Calcular bordes de celda (maneja divisiones no exactas)
            x1 = (col * w) // cols
            x2 = ((col + 1) * w) // cols
            y1 = (row * h) // rows
            y2 = ((row + 1) * h) // rows
            
            cell = img.crop((x1, y1, x2, y2))
            cell_arr = np.array(cell)
            cell_alpha = cell_arr[:, :, 3]
            
            bounds = get_content_bounds(cell_alpha)
            
            if bounds:
                bx1, by1, bx2, by2 = bounds
                content = cell.crop(bounds)
                
                # Centroide dentro del contenido recortado
                content_alpha = np.array(content)[:, :, 3]
                centroid = calculate_centroid(content_alpha)
                
                if centroid:
                    frames_data.append({
                        'content': content,
                        'size': content.size,
                        'centroid': centroid
                    })
                    print(f"   Frame {len(frames_data)}: {content.size[0]}x{content.size[1]}, centroide=({centroid[0]:.1f}, {centroid[1]:.1f})")
    
    return frames_data


def process_aoe_smart(weapon_id: str, base_path: Path, cols: int, rows: int, target_display_size: int = 64):
    """
    Procesa un AOE con grid específico usando centro de masas.
    """
    input_path = base_path / "unnamed-removebg-preview.png"
    
    if not input_path.exists():
        print(f"❌ {weapon_id}: No existe imagen fuente")
        return None
    
    print(f"\n{'='*60}")
    print(f"PROCESANDO: {weapon_id.upper()}")
    print(f"{'='*60}")
    
    img = Image.open(input_path).convert('RGBA')
    w, h = img.size
    
    print(f"📷 Imagen original: {w}x{h}")
    print(f"📐 Grid detectado: {cols}x{rows} = {cols*rows} frames")
    
    # Extraer frames
    frames_data = extract_frames_from_grid(img, cols, rows)
    
    if not frames_data:
        print(f"❌ {weapon_id}: No se encontraron frames válidos")
        return None
    
    print(f"\n📊 Frames extraídos: {len(frames_data)}")
    
    # Encontrar dimensiones máximas
    max_w = max(f['size'][0] for f in frames_data)
    max_h = max(f['size'][1] for f in frames_data)
    
    # Calcular distancias máximas desde centroide
    max_dist_left = max(f['centroid'][0] for f in frames_data)
    max_dist_right = max(f['size'][0] - f['centroid'][0] for f in frames_data)
    max_dist_top = max(f['centroid'][1] for f in frames_data)
    max_dist_bottom = max(f['size'][1] - f['centroid'][1] for f in frames_data)
    
    # Frame size basado en centroide
    frame_w = int(max_dist_left + max_dist_right) + 16
    frame_h = int(max_dist_top + max_dist_bottom) + 16
    frame_size = max(frame_w, frame_h)
    frame_size = ((frame_size + 7) // 8) * 8  # Múltiplo de 8
    
    print(f"📏 Contenido máximo: {max_w}x{max_h}")
    print(f"📐 Frame de salida: {frame_size}x{frame_size}")
    
    output_center = frame_size // 2
    
    # Crear frames centrados por centroide
    final_frames = []
    
    for f in frames_data:
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        content = f['content']
        cx, cy = f['centroid']
        
        paste_x = int(output_center - cx)
        paste_y = int(output_center - cy)
        
        frame.paste(content, (paste_x, paste_y), content)
        final_frames.append(frame)
    
    # Crear spritesheet
    spritesheet_width = frame_size * len(final_frames)
    spritesheet = Image.new('RGBA', (spritesheet_width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(final_frames):
        spritesheet.paste(frame, (i * frame_size, 0), frame)
    
    # Guardar archivos
    output_active = base_path / f"aoe_active_{weapon_id}.png"
    spritesheet.save(output_active, 'PNG', optimize=False)
    print(f"\n✅ Active: {output_active.name}")
    
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    output_impact = base_path / f"aoe_impact_{weapon_id}.png"
    impact.save(output_impact, 'PNG', optimize=False)
    print(f"✅ Impact: {output_impact.name}")
    
    # Guardar frames individuales
    frames_dir = base_path / "frames"
    frames_dir.mkdir(exist_ok=True)
    for i, frame in enumerate(final_frames):
        frame.save(frames_dir / f"frame_{i+1}.png", 'PNG', optimize=False)
    
    sprite_scale = target_display_size / frame_size
    
    print(f"\n📏 Spritesheet: {spritesheet_width}x{frame_size} ({len(final_frames)} frames)")
    print(f"🎮 Recomendado: frame_size={frame_size}, sprite_scale={sprite_scale:.2f}")
    
    return {
        'frame_size': frame_size,
        'sprite_scale': round(sprite_scale, 2),
        'num_frames': len(final_frames)
    }


def main():
    fusion_base = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\fusion")
    weapons_base = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\weapons")
    
    # Configuración específica por arma (cols, rows)
    aoes_config = {
        # Estos estaban mal - tienen grid 2x2, no 3x2
        'glacier': (fusion_base / 'glacier', 2, 2),
        'seismic_bolt': (fusion_base / 'seismic_bolt', 2, 2),
        # void_storm tiene 3x2 pero con celdas irregulares
        'void_storm': (fusion_base / 'void_storm', 3, 2),
        # void_pulse tiene 2x3 (2 columnas, 3 filas)
        'void_pulse': (weapons_base / 'void_pulse', 2, 3),
    }
    
    TARGET_DISPLAY_SIZE = 64
    results = {}
    
    for weapon_id, (base_path, cols, rows) in aoes_config.items():
        result = process_aoe_smart(weapon_id, base_path, cols, rows, TARGET_DISPLAY_SIZE)
        if result:
            results[weapon_id] = result
    
    # Resumen
    print("\n" + "="*60)
    print("CONFIGURACIÓN PARA ProjectileVisualManager.gd")
    print("="*60)
    
    for weapon_id, data in results.items():
        print(f'"{weapon_id}": {{"frame_size": {data["frame_size"]}, "sprite_scale": {data["sprite_scale"]}}},')


if __name__ == "__main__":
    main()
