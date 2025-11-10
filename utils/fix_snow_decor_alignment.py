#!/usr/bin/env python3
"""
fix_snow_decor_alignment.py
Corrige problemas de alineación en decoraciones animadas.
Asegura que todos los frames tengan el objeto en la misma posición.
"""

from PIL import Image, ImageDraw
from pathlib import Path
import numpy as np

def get_content_bbox(img):
    """Obtener bounding box del contenido no transparente."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    data = np.array(img)
    alpha = data[:, :, 3]
    non_transparent = alpha > 10
    
    if not non_transparent.any():
        return None
    
    rows = np.any(non_transparent, axis=1)
    cols = np.any(non_transparent, axis=0)
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return (x_min, y_min, x_max + 1, y_max + 1)

def align_frames(frames_paths, output_size=256):
    """
    Alinear todos los frames para que el contenido esté centrado.
    
    Estrategia:
    1. Encontrar el bounding box de todos los frames combinados
    2. Calcular el centro común
    3. Reposicionar cada frame para que su contenido esté en ese centro
    """
    frames = []
    bboxes = []
    
    # Cargar frames y obtener bboxes
    for path in frames_paths:
        img = Image.open(path)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        bbox = get_content_bbox(img)
        if bbox:
            frames.append(img)
            bboxes.append(bbox)
        else:
            print(f"⚠️ Frame sin contenido: {path.name}")
    
    if not frames:
        return []
    
    # Calcular bounding box global (máxima extensión)
    global_x_min = min(b[0] for b in bboxes)
    global_y_min = min(b[1] for b in bboxes)
    global_x_max = max(b[2] for b in bboxes)
    global_y_max = max(b[3] for b in bboxes)
    
    global_width = global_x_max - global_x_min
    global_height = global_y_max - global_y_min
    
    # Calcular centro objetivo (centro del canvas de salida)
    target_center_x = output_size / 2
    target_center_y = output_size / 2
    
    # Alinear cada frame
    aligned_frames = []
    
    for i, (img, bbox) in enumerate(zip(frames, bboxes)):
        # Centro actual del contenido
        content_center_x = (bbox[0] + bbox[2]) / 2
        content_center_y = (bbox[1] + bbox[3]) / 2
        
        # Calcular offset para centrar
        offset_x = int(target_center_x - content_center_x)
        offset_y = int(target_center_y - content_center_y)
        
        # Crear nuevo frame con contenido centrado
        new_frame = Image.new('RGBA', (output_size, output_size), (0, 0, 0, 0))
        new_frame.paste(img, (offset_x, offset_y), img)
        
        aligned_frames.append(new_frame)
        
        print(f"  Frame {i+1}: Offset ({offset_x:+d}, {offset_y:+d})")
    
    return aligned_frames

def create_aligned_spritesheet(directory, prefix, start, end, output_name, frame_size=256):
    """
    Crear sprite sheet con frames alineados correctamente.
    """
    dir_path = Path(directory)
    
    # Recolectar paths de frames
    frame_paths = []
    for i in range(start, end + 1):
        patterns = [f"{prefix}{i}.png", f"{prefix}{i:02d}.png", f"{prefix}{i:03d}.png"]
        
        for pattern in patterns:
            file_path = dir_path / pattern
            if file_path.exists():
                frame_paths.append(file_path)
                break
    
    if not frame_paths:
        print(f"❌ No se encontraron frames {start}-{end}")
        return False
    
    print(f"\n🔧 Procesando frames {start}-{end}:")
    print(f"  Frames encontrados: {len(frame_paths)}")
    
    # Alinear frames
    aligned_frames = align_frames(frame_paths, frame_size)
    
    if not aligned_frames:
        print(f"❌ Error al alinear frames")
        return False
    
    # Crear sprite sheet
    num_frames = len(aligned_frames)
    sheet_width = frame_size * num_frames
    sheet_height = frame_size
    
    sprite_sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
    
    for i, frame in enumerate(aligned_frames):
        x_offset = i * frame_size
        sprite_sheet.paste(frame, (x_offset, 0))
    
    # Guardar
    output_path = dir_path / output_name
    sprite_sheet.save(output_path, 'PNG')
    
    print(f"✅ Creado: {output_name}")
    print(f"   Dimensiones: {sheet_width}×{sheet_height}px")
    print(f"   Frames: {num_frames}\n")
    
    return True

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("USO: python fix_snow_decor_alignment.py <directorio>")
        print("\nEjemplo:")
        print("  python fix_snow_decor_alignment.py C:\\path\\to\\Snow\\decor")
        sys.exit(1)
    
    directory = sys.argv[1]
    
    print("=" * 60)
    print("CORRIGIENDO ALINEACIÓN DE DECORACIONES SNOW")
    print("=" * 60)
    
    # Grupos de decoraciones con sus rangos
    decor_groups = [
        ('', 1, 8, 1, 256),      # Decor 1: 01-08
        ('', 1, 8, 2, 256),      # Decor 2: 1-8 (puede solaparse con el anterior)
        ('', 11, 18, 3, 256),    # Decor 3: 11-18
        ('', 21, 28, 4, 256),    # Decor 4: 21-28
        ('', 31, 38, 5, 256),    # Decor 5: 31-38
        ('', 41, 48, 6, 256),    # Decor 6: 41-48
        ('', 51, 58, 7, 256),    # Decor 7: 51-58
        ('', 61, 68, 8, 256),    # Decor 8: 61-68
        ('', 71, 78, 9, 256),    # Decor 9: 71-78
        ('', 81, 88, 10, 256),   # Decor 10: 81-88
    ]
    
    for prefix, start, end, decor_num, size in decor_groups:
        output = f"snow_decor{decor_num}_sheet_f8_{size}_FIXED.png"
        create_aligned_spritesheet(directory, prefix, start, end, output, frame_size=size)
    
    print("=" * 60)
    print("✅ PROCESO COMPLETADO")
    print("=" * 60)
    print("\nArchivos creados con sufijo '_FIXED'")
    print("Si el resultado es correcto, renombra los archivos _FIXED")
    print("para reemplazar los originales.")

if __name__ == "__main__":
    main()
