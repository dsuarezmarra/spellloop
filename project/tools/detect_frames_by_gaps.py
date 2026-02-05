#!/usr/bin/env python3
"""
Detecta frames en un spritesheet buscando gaps transparentes.
Analiza columnas y filas vacías para encontrar los límites reales de cada frame.
"""

from PIL import Image
import numpy as np
import sys
import os

def find_gaps(alpha_array, axis, min_gap_size=5, min_content_size=20):
    """
    Encuentra los gaps (zonas completamente transparentes) en un eje.
    axis=0: busca columnas vacías (gaps verticales)
    axis=1: busca filas vacías (gaps horizontales)
    
    min_gap_size: tamaño mínimo de un gap para considerarlo separador
    min_content_size: tamaño mínimo de contenido para considerarlo frame
    
    Retorna lista de rangos donde hay contenido (no gaps).
    """
    # Sumar a lo largo del eje opuesto
    sums = np.sum(alpha_array, axis=axis)
    
    # Encontrar donde hay contenido (suma > 0)
    has_content = sums > 0
    
    # Primera pasada: encontrar todos los rangos
    raw_ranges = []
    in_content = False
    start = 0
    
    for i, has in enumerate(has_content):
        if has and not in_content:
            start = i
            in_content = True
        elif not has and in_content:
            raw_ranges.append((start, i))
            in_content = False
    
    if in_content:
        raw_ranges.append((start, len(has_content)))
    
    if not raw_ranges:
        return []
    
    # Segunda pasada: fusionar rangos separados por gaps pequeños
    merged_ranges = [raw_ranges[0]]
    for start, end in raw_ranges[1:]:
        prev_start, prev_end = merged_ranges[-1]
        gap_size = start - prev_end
        
        if gap_size < min_gap_size:
            # Gap muy pequeño, fusionar con el anterior
            merged_ranges[-1] = (prev_start, end)
        else:
            merged_ranges.append((start, end))
    
    # Tercera pasada: filtrar rangos muy pequeños (ruido)
    final_ranges = [(s, e) for s, e in merged_ranges if (e - s) >= min_content_size]
    
    return final_ranges

def analyze_spritesheet(image_path):
    """
    Analiza un spritesheet y detecta los frames por gaps transparentes.
    """
    img = Image.open(image_path).convert('RGBA')
    data = np.array(img)
    alpha = data[:, :, 3]  # Canal alpha
    
    print(f"\nAnalizando: {os.path.basename(image_path)}")
    print(f"Dimensiones: {img.width}x{img.height}")
    print("=" * 60)
    
    # Encontrar gaps verticales (columnas vacías) -> nos da rangos X de frames
    # axis=0 suma cada columna verticalmente
    x_ranges = find_gaps(alpha, axis=0)
    print(f"\nRangos X (columnas con contenido): {len(x_ranges)}")
    for i, (start, end) in enumerate(x_ranges):
        print(f"  Columna {i+1}: X={start} a {end} (ancho: {end-start})")
    
    # Encontrar gaps horizontales (filas vacías) -> nos da rangos Y de frames
    # axis=1 suma cada fila horizontalmente
    y_ranges = find_gaps(alpha, axis=1)
    print(f"\nRangos Y (filas con contenido): {len(y_ranges)}")
    for i, (start, end) in enumerate(y_ranges):
        print(f"  Fila {i+1}: Y={start} a {end} (alto: {end-start})")
    
    # Calcular frames como intersección de rangos X e Y
    print(f"\nFrames detectados: {len(x_ranges)} x {len(y_ranges)} = {len(x_ranges) * len(y_ranges)}")
    
    frames = []
    for row_idx, (y_start, y_end) in enumerate(y_ranges):
        for col_idx, (x_start, x_end) in enumerate(x_ranges):
            frame_num = row_idx * len(x_ranges) + col_idx + 1
            width = x_end - x_start
            height = y_end - y_start
            frames.append({
                'num': frame_num,
                'x': x_start,
                'y': y_start,
                'width': width,
                'height': height,
                'row': row_idx,
                'col': col_idx
            })
            print(f"  Frame {frame_num}: ({x_start},{y_start}) size {width}x{height}")
    
    return {
        'x_ranges': x_ranges,
        'y_ranges': y_ranges,
        'frames': frames,
        'grid': (len(x_ranges), len(y_ranges)),
        'image': img
    }

def visualize_detection(image_path, output_path=None):
    """
    Crea una visualización mostrando los frames detectados.
    """
    from PIL import ImageDraw
    
    result = analyze_spritesheet(image_path)
    img = result['image'].copy()
    draw = ImageDraw.Draw(img)
    
    # Dibujar rectángulos alrededor de cada frame
    colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080']
    
    for frame in result['frames']:
        color = colors[(frame['num'] - 1) % len(colors)]
        x, y = frame['x'], frame['y']
        w, h = frame['width'], frame['height']
        
        # Dibujar rectángulo
        draw.rectangle([x, y, x + w - 1, y + h - 1], outline=color, width=2)
        
        # Número del frame
        draw.text((x + 5, y + 5), str(frame['num']), fill=color)
    
    if output_path is None:
        base = os.path.splitext(image_path)[0]
        output_path = f"{base}_detected.png"
    
    img.save(output_path)
    print(f"\n✓ Visualización guardada: {output_path}")
    
    return result

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python detect_frames_by_gaps.py <imagen.png> [--visualize]")
        sys.exit(1)
    
    image_path = sys.argv[1]
    visualize = "--visualize" in sys.argv or "-v" in sys.argv
    
    if visualize:
        visualize_detection(image_path)
    else:
        analyze_spritesheet(image_path)
