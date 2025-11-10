#!/usr/bin/env python3
"""
combine_individual_frames.py
Combina frames individuales en sprite sheets perfectos.
Elimina fondos, alinea y genera sheets con padding correcto.
"""

from pathlib import Path
from PIL import Image
import re
from collections import defaultdict

def remove_background(img, threshold=30):
    """
    Asegurar que el fondo es completamente transparente.
    Elimina píxeles con alpha bajo y limpia bordes agresivamente.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    pixels = img.load()
    width, height = img.size
    
    # Hacer transparentes los píxeles con alpha bajo (threshold más alto para limpiar mejor)
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < threshold:
                pixels[x, y] = (0, 0, 0, 0)
            # También limpiar píxeles casi negros (fondos residuales)
            elif r < 20 and g < 20 and b < 20 and a < 150:
                pixels[x, y] = (0, 0, 0, 0)
    
    return img

def get_content_bbox(img):
    """Obtener el bounding box del contenido real."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return bbox

def align_frame_to_canvas(img, target_size=256):
    """
    Alinear frame a un canvas cuadrado de tamaño objetivo.
    Centrado horizontalmente, alineado al fondo verticalmente.
    """
    # Limpiar fondo
    img = remove_background(img)
    
    # Obtener contenido
    bbox = get_content_bbox(img)
    if not bbox:
        # Imagen completamente vacía
        return Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Recortar al contenido
    content = img.crop(bbox)
    orig_w, orig_h = content.size
    
    # Crear canvas transparente
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Calcular escala (ajustar dentro del target sin distorsión)
    scale = min(target_size / orig_w, target_size / orig_h)
    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)
    
    # Redimensionar
    resized = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Posicionar: centrado horizontalmente, alineado al fondo
    x_offset = (target_size - new_w) // 2
    y_offset = target_size - new_h
    
    canvas.paste(resized, (x_offset, y_offset), resized)
    
    return canvas

def group_frames_by_prefix(directory):
    """
    Agrupar frames por su prefijo común.
    Detecta patrones como: Gemini_Generated_Image_HASH-removebg-preview.png
    y variantes numeradas: Gemini_Generated_Image_HASH__N_-removebg-preview.png
    """
    files = list(Path(directory).glob("Gemini_Generated_Image_*-removebg-preview.png"))
    
    # Extraer prefijos únicos
    groups = defaultdict(list)
    
    for file in files:
        # Extraer el hash base (sin __N_)
        # Patrón: Gemini_Generated_Image_{hash}-removebg-preview o Gemini_Generated_Image_{hash}__N_-removebg-preview
        match = re.match(r"Gemini_Generated_Image_(\w+?)(?:__\d+_)?-removebg-preview", file.name)
        if match:
            prefix = match.group(1)  # Solo el hash
            groups[prefix].append(file)
    
    # Ordenar frames dentro de cada grupo por nombre completo
    for prefix in groups:
        groups[prefix] = sorted(groups[prefix], key=lambda f: f.name)
    
    return groups

def create_spritesheet(frames, output_path, frame_size=256, padding=4):
    """
    Crear sprite sheet horizontal perfectamente alineado.
    """
    num_frames = len(frames)
    
    print(f"\n  🔧 Procesando {num_frames} frames:")
    
    # Procesar cada frame
    processed_frames = []
    for i, frame_path in enumerate(frames):
        img = Image.open(frame_path)
        
        # Verificar dimensiones originales
        orig_size = img.size
        
        # Alinear a canvas 256×256
        aligned = align_frame_to_canvas(img, frame_size)
        processed_frames.append(aligned)
        
        print(f"    Frame {i+1}: {orig_size[0]}×{orig_size[1]} → {frame_size}×{frame_size}px")
    
    # Crear sprite sheet horizontal con fondo completamente transparente
    total_width = (frame_size * num_frames) + (padding * (num_frames - 1))
    spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
    
    x = 0
    for frame in processed_frames:
        # Pegar frame usando su propio canal alpha como máscara para evitar artefactos
        spritesheet.paste(frame, (x, 0), frame.split()[3])
        x += frame_size + padding
    
    # Guardar
    spritesheet.save(output_path, 'PNG')
    
    return spritesheet.size

def process_all_frames(directory, output_directory=None):
    """
    Procesar todos los grupos de frames en sprite sheets.
    """
    if output_directory is None:
        output_directory = directory
    
    output_dir = Path(output_directory)
    
    # Agrupar frames
    groups = group_frames_by_prefix(directory)
    
    print(f"\n{'='*70}")
    print(f"COMBINANDO FRAMES INDIVIDUALES EN SPRITE SHEETS")
    print(f"{'='*70}")
    print(f"\n📁 Encontrados {len(groups)} grupos de frames\n")
    
    # Procesar cada grupo
    results = []
    for i, (prefix, frames) in enumerate(sorted(groups.items())):
        decor_num = i + 1
        num_frames = len(frames)
        
        output_name = f"lava_decor{decor_num}_sheet_f{num_frames}_256.png"
        output_path = output_dir / output_name
        
        print(f"{'─'*70}")
        print(f"📄 Grupo {decor_num}: {prefix}")
        print(f"   Frames: {num_frames}")
        print(f"   Salida: {output_name}")
        print(f"{'─'*70}")
        
        # Crear sprite sheet
        final_size = create_spritesheet(frames, output_path, frame_size=256, padding=4)
        
        print(f"\n  ✅ Creado: {output_name}")
        print(f"     Dimensiones: {final_size[0]}×{final_size[1]}px\n")
        
        results.append((output_name, num_frames, final_size))
    
    # Resumen
    print(f"{'='*70}")
    print(f"RESUMEN")
    print(f"{'='*70}\n")
    
    for name, frames, size in results:
        print(f"  ✓ {name} - {frames} frames - {size[0]}×{size[1]}px")
    
    print(f"\n{'='*70}\n")
    
    return results

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("USO: python combine_individual_frames.py <directorio>")
        sys.exit(1)
    
    directory = sys.argv[1]
    process_all_frames(directory)

if __name__ == "__main__":
    main()
