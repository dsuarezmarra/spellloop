#!/usr/bin/env python3
"""
fix_spritesheet_dimensions.py
Herramienta para corregir automáticamente las dimensiones de sprite sheets
que no cumplan con las especificaciones requeridas.

Detecta automáticamente el layout actual (grid o horizontal) y reorganiza
los frames en una tira horizontal correcta con las dimensiones esperadas.
"""

import os
import sys
from pathlib import Path
from PIL import Image
import re

def parse_filename(filename):
    """
    Extraer información del nombre del archivo.
    Formato: {biome}_decor{N}_sheet_f{frames}_{size}.png
    """
    pattern = r"(.+)_decor(\d+)_sheet_f(\d+)_(\d+)\.png"
    match = re.match(pattern, filename)
    
    if not match:
        return None
    
    return {
        'biome': match.group(1),
        'decor_num': int(match.group(2)),
        'frames': int(match.group(3)),
        'frame_size': int(match.group(4))
    }

def calculate_expected_dimensions(frames, frame_size, padding=4):
    """Calcular dimensiones esperadas del sprite sheet."""
    width = (frame_size * frames) + (padding * (frames - 1))
    height = frame_size
    return width, height

def detect_current_layout(img, expected_frames, frame_size):
    """
    Detectar el layout actual de la imagen.
    Analiza también el contenido real para detectar mejor el layout.
    Retorna: 'correct', 'horizontal', 'grid', 'wrong_size', o 'unknown'
    """
    width, height = img.size
    expected_width, expected_height = calculate_expected_dimensions(expected_frames, frame_size)
    
    # Verificar si ya es correcto
    if abs(width - expected_width) <= 4 and abs(height - expected_height) <= 4:
        return 'correct'
    
    # Detectar contenido no transparente si es RGBA
    content_bbox = None
    if img.mode == 'RGBA':
        alpha = img.split()[3]
        content_bbox = alpha.getbbox()
    
    # Si el contenido está en una franja horizontal delgada, es layout horizontal
    if content_bbox:
        x1, y1, x2, y2 = content_bbox
        content_width = x2 - x1
        content_height = y2 - y1
        
        # Si el contenido es muy ancho y poco alto, es horizontal
        if content_width > content_height * 3:
            return 'horizontal'
    
    # Detectar grid (casi cuadrado)
    aspect_ratio = width / height if height > 0 else 0
    if 0.5 < aspect_ratio < 2.0:
        return 'grid'
    
    # Detectar tamaño incorrecto pero horizontal
    if width > height * 2:
        return 'wrong_size'
    
    return 'unknown'

def extract_frames_from_grid(img, expected_frames):
    """
    Extraer frames de un grid (detectando automáticamente las dimensiones).
    """
    width, height = img.size
    
    # Intentar detectar el grid
    # Probar diferentes configuraciones comunes
    possible_grids = [
        (expected_frames, 1),  # Horizontal
        (1, expected_frames),  # Vertical
        (expected_frames // 2, 2),  # 2 filas
        (2, expected_frames // 2),  # 2 columnas
        (expected_frames // 3, 3),  # 3 filas
        (3, expected_frames // 3),  # 3 columnas
        (4, 2),  # 4×2 para 8 frames
        (2, 4),  # 2×4 para 8 frames
        (3, 2),  # 3×2 para 6 frames
        (2, 3),  # 2×3 para 6 frames
    ]
    
    frames = []
    best_match = None
    best_score = float('inf')
    
    for cols, rows in possible_grids:
        if cols * rows != expected_frames:
            continue
        
        frame_w = width // cols
        frame_h = height // rows
        
        # Calcular cuán cuadrados son los frames (score: 0 = perfecto)
        aspect_ratio = frame_w / frame_h if frame_h > 0 else 0
        score = abs(1.0 - aspect_ratio)  # Cuánto se desvía de 1:1
        
        if score < best_score:
            best_score = score
            best_match = (cols, rows, frame_w, frame_h)
    
    # Usar la mejor coincidencia (incluso si no es perfecta)
    if best_match:
        cols, rows, frame_w, frame_h = best_match
        print(f"  📊 Grid detectado: {cols}×{rows} (frames de {frame_w}×{frame_h} px)")
        
        # Extraer frames
        for row in range(rows):
            for col in range(cols):
                x = col * frame_w
                y = row * frame_h
                frame = img.crop((x, y, x + frame_w, y + frame_h))
                frames.append(frame)
        
        return frames
    
    print(f"  ⚠️ No se pudo detectar grid automáticamente")
    return None

def extract_frames_from_horizontal(img, expected_frames, padding=4):
    """
    Extraer frames de una tira horizontal (con o sin padding).
    """
    width, height = img.size
    
    # Calcular ancho de frame estimado
    total_padding = padding * (expected_frames - 1)
    frame_width = (width - total_padding) // expected_frames
    
    print(f"  📏 Tira horizontal detectada: {expected_frames} frames de ~{frame_width}×{height} px")
    
    frames = []
    x = 0
    
    for i in range(expected_frames):
        frame = img.crop((x, 0, x + frame_width, height))
        frames.append(frame)
        x += frame_width + padding
    
    return frames

def resize_frame(frame, target_size):
    """
    Redimensionar un frame al tamaño objetivo manteniendo transparencia y aspecto.
    Centra el contenido si el frame original no es cuadrado.
    """
    orig_w, orig_h = frame.size
    
    # Si ya es del tamaño correcto, retornar
    if orig_w == target_size and orig_h == target_size:
        return frame
    
    # Crear canvas transparente del tamaño objetivo
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Calcular escala manteniendo aspecto (fit dentro del target)
    scale = min(target_size / orig_w, target_size / orig_h)
    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)
    
    # Redimensionar frame con alta calidad
    resized_frame = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Centrar en el canvas (pegar en la parte inferior-centro para decoraciones)
    x_offset = (target_size - new_w) // 2
    y_offset = target_size - new_h  # Alinear al fondo (bottom)
    
    result.paste(resized_frame, (x_offset, y_offset), resized_frame)
    
    return result

def create_horizontal_spritesheet(frames, frame_size, padding=4):
    """
    Crear sprite sheet horizontal con padding correcto.
    """
    num_frames = len(frames)
    width = (frame_size * num_frames) + (padding * (num_frames - 1))
    height = frame_size
    
    # Crear imagen con transparencia
    spritesheet = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    
    x = 0
    for frame in frames:
        # Redimensionar frame si es necesario
        if frame.size != (frame_size, frame_size):
            frame = resize_frame(frame, frame_size)
        
        spritesheet.paste(frame, (x, 0))
        x += frame_size + padding
    
    return spritesheet

def fix_spritesheet(input_path, output_path=None, backup=True):
    """
    Corregir un sprite sheet con dimensiones incorrectas.
    """
    input_path = Path(input_path)
    
    if not input_path.exists():
        print(f"❌ Archivo no encontrado: {input_path}")
        return False
    
    # Parsear nombre del archivo
    info = parse_filename(input_path.name)
    if not info:
        print(f"❌ Nombre de archivo no válido: {input_path.name}")
        print(f"   Debe seguir formato: {{biome}}_decor{{N}}_sheet_f{{frames}}_{{size}}.png")
        return False
    
    print(f"\n📄 Procesando: {input_path.name}")
    print(f"  ℹ️ Especificaciones:")
    print(f"    - Bioma: {info['biome']}")
    print(f"    - Decoración: #{info['decor_num']}")
    print(f"    - Frames esperados: {info['frames']}")
    print(f"    - Tamaño por frame: {info['frame_size']}×{info['frame_size']} px")
    
    # Calcular dimensiones esperadas
    expected_width, expected_height = calculate_expected_dimensions(
        info['frames'], info['frame_size']
    )
    print(f"    - Dimensiones esperadas: {expected_width}×{expected_height} px")
    
    # Cargar imagen
    try:
        img = Image.open(input_path)
    except Exception as e:
        print(f"❌ Error al cargar imagen: {e}")
        return False
    
    actual_width, actual_height = img.size
    print(f"  📏 Dimensiones actuales: {actual_width}×{actual_height} px")
    
    # Detectar layout actual
    layout = detect_current_layout(img, info['frames'], info['frame_size'])
    
    if layout == 'correct':
        print(f"  ✅ Las dimensiones ya son correctas. No se requiere corrección.")
        return True
    
    print(f"  🔍 Layout detectado: {layout}")
    
    # Extraer frames según el layout
    frames = None
    
    if layout == 'horizontal':
        frames = extract_frames_from_horizontal(img, info['frames'])
    elif layout == 'grid':
        frames = extract_frames_from_grid(img, info['frames'])
    elif layout in ['wrong_size', 'unknown']:
        # Intentar primero horizontal, luego grid
        frames = extract_frames_from_horizontal(img, info['frames'])
        if frames is None or len(frames) != info['frames']:
            frames = extract_frames_from_grid(img, info['frames'])
    
    if frames is None or len(frames) != info['frames']:
        print(f"  ❌ No se pudieron extraer {info['frames']} frames correctamente")
        if frames:
            print(f"     Se extrajeron {len(frames)} frames")
        return False
    
    print(f"  ✅ {len(frames)} frames extraídos correctamente")
    
    # Crear nuevo sprite sheet horizontal
    print(f"  🔧 Creando sprite sheet corregido...")
    new_spritesheet = create_horizontal_spritesheet(
        frames, info['frame_size'], padding=4
    )
    
    # Determinar ruta de salida
    if output_path is None:
        output_path = input_path
    else:
        output_path = Path(output_path)
    
    # Hacer backup si es necesario
    if backup and output_path.exists():
        backup_path = output_path.with_suffix('.png.backup')
        if backup_path.exists():
            backup_path.unlink()
        output_path.rename(backup_path)
        print(f"  💾 Backup creado: {backup_path.name}")
    
    # Guardar sprite sheet corregido
    try:
        new_spritesheet.save(output_path, 'PNG')
        print(f"  ✅ Sprite sheet corregido guardado: {output_path.name}")
        print(f"     Dimensiones finales: {new_spritesheet.size[0]}×{new_spritesheet.size[1]} px")
        return True
    except Exception as e:
        print(f"  ❌ Error al guardar: {e}")
        return False

def process_directory(directory, pattern="*_sheet_f*_*.png", backup=True):
    """
    Procesar todos los sprite sheets en un directorio.
    """
    directory = Path(directory)
    
    if not directory.exists():
        print(f"❌ Directorio no encontrado: {directory}")
        return
    
    print(f"\n🔍 Buscando sprite sheets en: {directory}")
    files = list(directory.glob(pattern))
    
    if not files:
        print(f"⚠️ No se encontraron archivos con patrón: {pattern}")
        return
    
    print(f"📁 Encontrados {len(files)} archivos")
    
    success_count = 0
    skip_count = 0
    error_count = 0
    
    for file_path in files:
        result = fix_spritesheet(file_path, backup=backup)
        if result is True:
            success_count += 1
        elif result is None:
            skip_count += 1
        else:
            error_count += 1
    
    print(f"\n{'='*60}")
    print(f"📊 RESUMEN:")
    print(f"  ✅ Corregidos: {success_count}")
    print(f"  ⏭️ Ya correctos: {skip_count}")
    print(f"  ❌ Errores: {error_count}")
    print(f"{'='*60}\n")

def main():
    if len(sys.argv) < 2:
        print("USO:")
        print(f"  python {sys.argv[0]} <archivo.png>")
        print(f"  python {sys.argv[0]} <directorio>")
        print()
        print("EJEMPLOS:")
        print(f"  python {sys.argv[0]} lava_decor2_sheet_f7_256.png")
        print(f"  python {sys.argv[0]} ../project/assets/textures/biomes/Lava/decor/")
        print()
        print("OPCIONES:")
        print("  --no-backup    No crear archivos de respaldo")
        sys.exit(1)
    
    target = sys.argv[1]
    backup = '--no-backup' not in sys.argv
    
    target_path = Path(target)
    
    if target_path.is_file():
        fix_spritesheet(target_path, backup=backup)
    elif target_path.is_dir():
        process_directory(target_path, backup=backup)
    else:
        print(f"❌ No se encontró archivo o directorio: {target}")
        sys.exit(1)

if __name__ == "__main__":
    main()
