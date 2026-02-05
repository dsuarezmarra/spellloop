#!/usr/bin/env python3
"""
Procesa spritesheets de Gemini con detección inteligente de frames.
- Detecta filas por gaps transparentes
- Divide horizontalmente por número esperado de columnas
- Redimensiona y reconstruye al tamaño objetivo
"""

from PIL import Image
import numpy as np
import sys
import os

def find_row_gaps(alpha_array, min_gap_size=3, min_content_size=30):
    """
    Encuentra filas con contenido buscando gaps horizontales transparentes.
    Retorna lista de rangos Y donde hay contenido.
    """
    # Sumar cada fila horizontalmente (axis=1)
    row_sums = np.sum(alpha_array, axis=1)
    has_content = row_sums > 0
    
    # Encontrar rangos de contenido
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
    
    # Fusionar rangos separados por gaps pequeños
    merged_ranges = [raw_ranges[0]]
    for start, end in raw_ranges[1:]:
        prev_start, prev_end = merged_ranges[-1]
        gap_size = start - prev_end
        
        if gap_size < min_gap_size:
            merged_ranges[-1] = (prev_start, end)
        else:
            merged_ranges.append((start, end))
    
    # Filtrar rangos muy pequeños (ruido)
    final_ranges = [(s, e) for s, e in merged_ranges if (e - s) >= min_content_size]
    
    return final_ranges


def process_spritesheet(input_path, output_path, expected_cols, expected_rows, target_frame_size, verbose=True):
    """
    Procesa un spritesheet:
    1. Detecta filas por gaps transparentes
    2. Divide cada fila en expected_cols columnas iguales
    3. Extrae cada frame, lo redimensiona a target_frame_size
    4. Reconstruye el spritesheet final
    
    Args:
        input_path: Ruta al spritesheet original
        output_path: Ruta de salida
        expected_cols: Número de columnas esperadas (frames por fila)
        expected_rows: Número de filas esperadas
        target_frame_size: Tupla (ancho, alto) del frame objetivo
        verbose: Mostrar info de depuración
    """
    # Abrir imagen
    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)
    alpha = data[:, :, 3]
    
    if verbose:
        print(f"\n{'='*60}")
        print(f"Procesando: {os.path.basename(input_path)}")
        print(f"Dimensiones originales: {img.width}x{img.height}")
        print(f"Grid esperado: {expected_cols}x{expected_rows}")
        print(f"Tamaño frame objetivo: {target_frame_size[0]}x{target_frame_size[1]}")
    
    # Detectar filas por gaps
    y_ranges = find_row_gaps(alpha)
    
    if verbose:
        print(f"\nFilas detectadas: {len(y_ranges)}")
        for i, (y_start, y_end) in enumerate(y_ranges):
            print(f"  Fila {i+1}: Y={y_start} a {y_end} (alto: {y_end-y_start})")
    
    # Validar numero de filas
    if len(y_ranges) != expected_rows:
        print(f"[!] ADVERTENCIA: Se detectaron {len(y_ranges)} filas, se esperaban {expected_rows}")
        # Si detectamos menos filas, dividir el contenido uniformemente
        if len(y_ranges) < expected_rows:
            # Encontrar el rango total de contenido
            if y_ranges:
                y_min = y_ranges[0][0]
                y_max = y_ranges[-1][1]
            else:
                # No hay contenido claro, usar toda la imagen
                y_min = 0
                y_max = img.height
            
            # Dividir uniformemente
            total_height = y_max - y_min
            row_height = total_height // expected_rows
            y_ranges = [(y_min + i * row_height, y_min + (i + 1) * row_height) for i in range(expected_rows)]
            print(f"  Dividiendo uniformemente en {expected_rows} filas de {row_height}px")
    
    # Encontrar el ancho total del contenido para cada fila
    frames = []
    
    for row_idx, (y_start, y_end) in enumerate(y_ranges[:expected_rows]):
        # Extraer la fila
        row_alpha = alpha[y_start:y_end, :]
        
        # Encontrar los límites X del contenido en esta fila
        col_sums = np.sum(row_alpha, axis=0)
        has_content = col_sums > 0
        
        # Encontrar x_min y x_max
        content_cols = np.where(has_content)[0]
        if len(content_cols) == 0:
            print(f"  [!] Fila {row_idx+1} sin contenido")
            continue
        
        x_min = content_cols[0]
        x_max = content_cols[-1] + 1
        content_width = x_max - x_min
        
        if verbose:
            print(f"\n  Fila {row_idx+1}: contenido X={x_min} a {x_max} (ancho: {content_width})")
        
        # Dividir el contenido en expected_cols columnas iguales
        col_width = content_width / expected_cols
        
        for col_idx in range(expected_cols):
            frame_x = x_min + int(col_idx * col_width)
            frame_x_end = x_min + int((col_idx + 1) * col_width)
            
            # Extraer frame
            frame = img.crop((frame_x, y_start, frame_x_end, y_end))
            
            if verbose:
                print(f"    Frame {row_idx * expected_cols + col_idx + 1}: "
                      f"X={frame_x}-{frame_x_end} ({frame_x_end-frame_x}px) "
                      f"Y={y_start}-{y_end} ({y_end-y_start}px)")
            
            # Redimensionar al tamaño objetivo
            frame_resized = frame.resize(target_frame_size, Image.Resampling.LANCZOS)
            
            frames.append({
                'image': frame_resized,
                'row': row_idx,
                'col': col_idx
            })
    
    # Verificar que tenemos suficientes frames
    total_expected = expected_cols * expected_rows
    if len(frames) < total_expected:
        print(f"[!] ADVERTENCIA: Solo se extrajeron {len(frames)} frames de {total_expected} esperados")
    
    # Crear el spritesheet final
    final_width = target_frame_size[0] * expected_cols
    final_height = target_frame_size[1] * expected_rows
    
    final_sheet = Image.new('RGBA', (final_width, final_height), (0, 0, 0, 0))
    
    for frame_data in frames:
        x = frame_data['col'] * target_frame_size[0]
        y = frame_data['row'] * target_frame_size[1]
        final_sheet.paste(frame_data['image'], (x, y))
    
    # Guardar
    final_sheet.save(output_path)
    
    if verbose:
        print(f"\n[OK] Guardado: {output_path}")
        print(f"  Dimensiones finales: {final_width}x{final_height}")
        print(f"  Frames: {len(frames)}")
    
    return final_sheet


def main():
    """Procesar un spritesheet individual."""
    if len(sys.argv) < 5:
        print("Uso: python process_spritesheet_smart.py <input> <output> <cols> <rows> <frame_width> <frame_height>")
        print("Ejemplo: python process_spritesheet_smart.py projectile_fire.png out.png 4 2 64 64")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    cols = int(sys.argv[3])
    rows = int(sys.argv[4])
    frame_w = int(sys.argv[5]) if len(sys.argv) > 5 else 64
    frame_h = int(sys.argv[6]) if len(sys.argv) > 6 else frame_w
    
    process_spritesheet(input_path, output_path, cols, rows, (frame_w, frame_h))


if __name__ == '__main__':
    main()
