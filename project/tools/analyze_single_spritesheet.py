#!/usr/bin/env python3
"""
Analizador Visual de Spritesheets
==================================
Analiza un spritesheet individual y genera un mapa visual de detección de frames.
"""

import sys
from pathlib import Path
from PIL import Image
import numpy as np

def analyze_spritesheet(filepath):
    """Analiza un spritesheet y detecta frames automáticamente."""
    img = Image.open(filepath)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    width, height = img.size
    print(f"\n{'='*60}")
    print(f"ARCHIVO: {Path(filepath).name}")
    print(f"{'='*60}")
    print(f"Dimensiones: {width}x{height}")
    
    # Convertir a numpy para análisis
    data = np.array(img)
    alpha = data[:, :, 3]
    
    # Detectar columnas y filas con contenido
    col_has_content = np.any(alpha > 10, axis=0)  # Por columna
    row_has_content = np.any(alpha > 10, axis=1)  # Por fila
    
    # Encontrar gaps verticales (separadores de columnas)
    v_gaps = find_gaps(col_has_content)
    h_gaps = find_gaps(row_has_content)
    
    print(f"\nGaps verticales detectados: {len(v_gaps)}")
    for i, gap in enumerate(v_gaps):
        print(f"  Gap V{i+1}: columnas {gap[0]} a {gap[1]} (ancho: {gap[1]-gap[0]+1}px)")
    
    print(f"\nGaps horizontales detectados: {len(h_gaps)}")
    for i, gap in enumerate(h_gaps):
        print(f"  Gap H{i+1}: filas {gap[0]} a {gap[1]} (alto: {gap[1]-gap[0]+1}px)")
    
    # Detectar regiones de frames
    frames = detect_frames_from_gaps(width, height, v_gaps, h_gaps)
    print(f"\nFrames detectados: {len(frames)}")
    
    for i, frame in enumerate(frames):
        x, y, w, h = frame
        # Analizar contenido del frame
        frame_data = alpha[y:y+h, x:x+w]
        content_pixels = np.sum(frame_data > 10)
        total_pixels = w * h
        fill_ratio = content_pixels / total_pixels * 100
        
        # Calcular bounding box del contenido
        rows_with_content = np.any(frame_data > 10, axis=1)
        cols_with_content = np.any(frame_data > 10, axis=0)
        
        if np.any(rows_with_content) and np.any(cols_with_content):
            r_indices = np.where(rows_with_content)[0]
            c_indices = np.where(cols_with_content)[0]
            content_bbox = (c_indices[0], r_indices[0], 
                          c_indices[-1] - c_indices[0] + 1, 
                          r_indices[-1] - r_indices[0] + 1)
            
            # Centro de masas
            y_coords, x_coords = np.where(frame_data > 10)
            if len(x_coords) > 0:
                center_x = np.mean(x_coords)
                center_y = np.mean(y_coords)
            else:
                center_x, center_y = w/2, h/2
        else:
            content_bbox = None
            center_x, center_y = w/2, h/2
        
        print(f"\n  Frame {i+1}:")
        print(f"    Posición: ({x}, {y})")
        print(f"    Tamaño celda: {w}x{h}")
        if content_bbox:
            print(f"    Contenido bbox: {content_bbox[2]}x{content_bbox[3]} en ({content_bbox[0]}, {content_bbox[1]})")
            print(f"    Centro de masas: ({center_x:.1f}, {center_y:.1f})")
        print(f"    Fill ratio: {fill_ratio:.1f}%")
    
    # Sugerir grid
    if len(frames) > 0:
        cols = len(v_gaps) + 1 if v_gaps else 1
        rows = len(h_gaps) + 1 if h_gaps else 1
        
        # Ajustar si hay múltiples frames
        if len(frames) != cols * rows:
            # Intentar detectar grid por tamaño uniforme
            if len(frames) == 8:
                if width > height:
                    cols, rows = 4, 2
                else:
                    cols, rows = 2, 4
        
        print(f"\n{'='*60}")
        print(f"GRID SUGERIDO: {cols}x{rows} = {cols*rows} frames")
        print(f"Tamaño frame estimado: {width//cols}x{height//rows}")
        print(f"{'='*60}")
    
    return frames


def find_gaps(has_content_array):
    """Encuentra gaps (secuencias de False) en un array booleano."""
    gaps = []
    in_gap = False
    gap_start = 0
    min_gap_size = 3  # Mínimo 3 píxeles para considerar gap
    
    for i, has_content in enumerate(has_content_array):
        if not has_content:
            if not in_gap:
                in_gap = True
                gap_start = i
        else:
            if in_gap:
                gap_end = i - 1
                if gap_end - gap_start + 1 >= min_gap_size:
                    gaps.append((gap_start, gap_end))
                in_gap = False
    
    # Cerrar gap final si existe
    if in_gap:
        gap_end = len(has_content_array) - 1
        if gap_end - gap_start + 1 >= min_gap_size:
            gaps.append((gap_start, gap_end))
    
    return gaps


def detect_frames_from_gaps(width, height, v_gaps, h_gaps):
    """Detecta frames basándose en los gaps encontrados."""
    # Crear límites de columnas
    col_bounds = [0]
    for gap in v_gaps:
        col_bounds.append(gap[0])
        col_bounds.append(gap[1] + 1)
    col_bounds.append(width)
    
    # Crear límites de filas
    row_bounds = [0]
    for gap in h_gaps:
        row_bounds.append(gap[0])
        row_bounds.append(gap[1] + 1)
    row_bounds.append(height)
    
    # Generar frames
    frames = []
    for r in range(0, len(row_bounds) - 1, 2):
        for c in range(0, len(col_bounds) - 1, 2):
            x = col_bounds[c]
            y = row_bounds[r]
            w = col_bounds[c + 1] - x
            h = row_bounds[r + 1] - y
            if w > 10 and h > 10:  # Ignorar frames muy pequeños
                frames.append((x, y, w, h))
    
    return frames


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python analyze_single_spritesheet.py <ruta_imagen>")
        sys.exit(1)
    
    analyze_spritesheet(sys.argv[1])
