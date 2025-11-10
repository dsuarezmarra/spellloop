#!/usr/bin/env python3
"""
fix_spritesheet_smart.py
Versión mejorada que detecta frames por contenido visual, no por división matemática.
"""

import sys
from pathlib import Path
from PIL import Image
import numpy as np

def detect_frame_boundaries(img, min_gap=5):
    """
    Detectar los límites de cada frame analizando el contenido real.
    Busca columnas vacías (gaps) entre frames.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Obtener canal alpha
    alpha = np.array(img.split()[3])
    width, height = img.size
    
    # Analizar columnas para encontrar gaps (columnas completamente transparentes)
    column_content = []
    for x in range(width):
        has_content = np.any(alpha[:, x] > 10)  # Threshold para detectar contenido
        column_content.append(has_content)
    
    # Encontrar los límites de frames (transiciones entre contenido y vacío)
    frames_bounds = []
    in_frame = False
    frame_start = 0
    
    for x in range(width):
        if column_content[x] and not in_frame:
            # Inicio de un frame
            frame_start = x
            in_frame = True
        elif not column_content[x] and in_frame:
            # Fin de un frame
            frames_bounds.append((frame_start, x))
            in_frame = False
    
    # Si termina en un frame
    if in_frame:
        frames_bounds.append((frame_start, width))
    
    return frames_bounds

def detect_content_bbox(img):
    """Detectar el bounding box del contenido real (sin transparencia)."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return bbox

def extract_frames_smart(img, expected_frames=None):
    """
    Extraer frames detectando automáticamente sus límites por contenido visual.
    """
    width, height = img.size
    
    print(f"  📐 Analizando imagen: {width}×{height} px")
    
    # Detectar contenido general
    overall_bbox = detect_content_bbox(img)
    if not overall_bbox:
        print(f"  ❌ Imagen completamente transparente")
        return None
    
    x1, y1, x2, y2 = overall_bbox
    print(f"  📦 Contenido detectado en: ({x1},{y1}) → ({x2},{y2})")
    print(f"     Área: {x2-x1}×{y2-y1} px")
    
    # Detectar límites de frames
    frame_bounds = detect_frame_boundaries(img)
    num_detected = len(frame_bounds)
    
    print(f"  🔍 Frames detectados visualmente: {num_detected}")
    
    if expected_frames and num_detected != expected_frames:
        print(f"  ⚠️ Esperados {expected_frames} frames, detectados {num_detected}")
        
        # Si detectó menos frames, puede ser un grid vertical
        if num_detected < expected_frames:
            print(f"  🔄 Intentando detectar como grid vertical...")
            return extract_frames_grid(img, expected_frames)
    
    # Extraer cada frame
    frames = []
    for i, (start_x, end_x) in enumerate(frame_bounds):
        frame_width = end_x - start_x
        
        # Extraer el frame completo (toda la altura)
        frame = img.crop((start_x, 0, end_x, height))
        
        # Detectar el contenido real del frame (recortar espacio vacío vertical)
        frame_bbox = detect_content_bbox(frame)
        if frame_bbox:
            fx1, fy1, fx2, fy2 = frame_bbox
            # Recortar al contenido real
            frame = frame.crop((fx1, fy1, fx2, fy2))
            print(f"    Frame {i+1}: {start_x}→{end_x} ({frame_width}px ancho) → contenido {fx2-fx1}×{fy2-fy1} px")
        else:
            print(f"    Frame {i+1}: VACÍO")
            continue
        
        frames.append(frame)
    
    return frames

def extract_frames_grid(img, expected_frames):
    """
    Extraer frames de un grid detectando filas y columnas por contenido.
    """
    width, height = img.size
    
    # Detectar posibles configuraciones de grid
    possible_grids = [
        (expected_frames, 1),
        (1, expected_frames),
        (expected_frames // 2, 2),
        (2, expected_frames // 2),
        (expected_frames // 3, 3),
        (3, expected_frames // 3),
        (expected_frames // 4, 4),
        (4, expected_frames // 4),
        (4, 2) if expected_frames == 8 else (0, 0),
        (3, 2) if expected_frames == 6 else (0, 0),
        (4, 3) if expected_frames == 12 else (0, 0),
        (6, 2) if expected_frames == 12 else (0, 0),
    ]
    
    frames = []
    
    for cols, rows in possible_grids:
        if cols * rows != expected_frames or cols == 0:
            continue
        
        frame_w = width // cols
        frame_h = height // rows
        
        print(f"  📊 Probando grid {cols}×{rows} (frames de {frame_w}×{frame_h} px)")
        
        temp_frames = []
        all_valid = True
        
        for row in range(rows):
            for col in range(cols):
                x = col * frame_w
                y = row * frame_h
                
                cell = img.crop((x, y, x + frame_w, y + frame_h))
                
                # Detectar contenido en la celda
                bbox = detect_content_bbox(cell)
                if bbox:
                    cx1, cy1, cx2, cy2 = bbox
                    content = cell.crop(bbox)
                    temp_frames.append(content)
                else:
                    all_valid = False
                    break
            
            if not all_valid:
                break
        
        if all_valid and len(temp_frames) == expected_frames:
            print(f"  ✅ Grid válido encontrado: {cols}×{rows}")
            return temp_frames
    
    return None

def resize_and_center_frame(frame, target_size):
    """
    Redimensionar frame manteniendo aspecto y centrarlo en un canvas cuadrado.
    Alinea al fondo para decoraciones de suelo.
    """
    orig_w, orig_h = frame.size
    
    # Crear canvas transparente
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Calcular escala (ajustar al tamaño objetivo manteniendo aspecto)
    scale = min(target_size / orig_w, target_size / orig_h)
    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)
    
    # Redimensionar con alta calidad
    resized = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Centrar horizontalmente, alinear verticalmente al fondo
    x_offset = (target_size - new_w) // 2
    y_offset = target_size - new_h
    
    result.paste(resized, (x_offset, y_offset), resized)
    
    return result

def process_spritesheet_smart(input_path, output_path, expected_frames, frame_size=256, padding=4):
    """
    Procesar sprite sheet detectando frames inteligentemente.
    """
    print(f"\n{'='*70}")
    print(f"📄 Procesamiento inteligente: {Path(input_path).name}")
    print(f"{'='*70}")
    
    img = Image.open(input_path)
    
    # Extraer frames inteligentemente
    frames = extract_frames_smart(img, expected_frames)
    
    if not frames or len(frames) != expected_frames:
        print(f"  ❌ No se pudieron extraer {expected_frames} frames correctamente")
        return False
    
    print(f"\n  ✅ {len(frames)} frames extraídos correctamente")
    print(f"  🔧 Redimensionando a {frame_size}×{frame_size} px y creando sprite sheet...")
    
    # Redimensionar y centrar cada frame
    processed_frames = []
    for i, frame in enumerate(frames):
        resized = resize_and_center_frame(frame, frame_size)
        processed_frames.append(resized)
        print(f"    Frame {i+1}: {frame.size} → {frame_size}×{frame_size} px")
    
    # Crear sprite sheet horizontal
    total_width = (frame_size * len(processed_frames)) + (padding * (len(processed_frames) - 1))
    spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
    
    x = 0
    for frame in processed_frames:
        spritesheet.paste(frame, (x, 0))
        x += frame_size + padding
    
    # Guardar
    spritesheet.save(output_path, 'PNG')
    print(f"  ✅ Guardado: {Path(output_path).name}")
    print(f"     Dimensiones finales: {spritesheet.size[0]}×{spritesheet.size[1]} px\n")
    
    return True

def main():
    if len(sys.argv) < 4:
        print("USO: python fix_spritesheet_smart.py <input.png> <output.png> <frames>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    expected_frames = int(sys.argv[3])
    
    process_spritesheet_smart(input_path, output_path, expected_frames)

if __name__ == "__main__":
    main()
