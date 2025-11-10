#!/usr/bin/env python3
"""
combine_base_frames.py
Combina frames de textura base en sprite sheet horizontal.
Específico para texturas base seamless (sin recorte ni alineación).
"""

from pathlib import Path
from PIL import Image
import re
from collections import defaultdict

def group_frames_by_prefix(directory):
    """
    Agrupar frames por su prefijo común.
    """
    files = list(Path(directory).glob("Gemini_Generated_Image_*.png"))
    
    # Extraer prefijos únicos
    groups = defaultdict(list)
    
    for file in files:
        # Extraer el patrón base
        match = re.match(r"Gemini_Generated_Image_(\w+)", file.stem)
        if match:
            prefix = match.group(1)
            groups[prefix].append(file)
    
    # Ordenar frames dentro de cada grupo
    for prefix in groups:
        groups[prefix] = sorted(groups[prefix], key=lambda f: f.stem)
    
    return groups

def create_spritesheet(frames, output_path, frame_size=512, padding=4):
    """
    Crear sprite sheet horizontal desde frames de textura base.
    NO hace recorte ni alineación, solo combina los frames tal cual.
    Redimensiona frames si no tienen el tamaño correcto.
    """
    num_frames = len(frames)
    
    print(f"\n  Procesando {num_frames} frames de textura base:")
    
    # Cargar frames y redimensionar si es necesario
    processed_frames = []
    for i, frame_path in enumerate(frames):
        img = Image.open(frame_path)
        
        # Asegurar modo RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Redimensionar si no tiene el tamaño correcto
        if img.size != (frame_size, frame_size):
            print(f"    Frame {i+1}: {img.size} → Redimensionando a {frame_size}×{frame_size}px")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
        else:
            print(f"    Frame {i+1}: {frame_size}×{frame_size}px ✓")
        
        processed_frames.append(img)
    
    # Crear sprite sheet horizontal con fondo transparente
    total_width = (frame_size * num_frames) + (padding * (num_frames - 1))
    spritesheet = Image.new('RGBA', (total_width, frame_size), (0, 0, 0, 0))
    
    x = 0
    for frame in processed_frames:
        # Pegar frame usando canal alpha como máscara
        spritesheet.paste(frame, (x, 0), frame.split()[3] if frame.mode == 'RGBA' else None)
        x += frame_size + padding
    
    # Guardar
    spritesheet.save(output_path, 'PNG')
    
    return spritesheet.size

def process_base_texture_frames(directory, output_directory=None):
    """
    Procesar frames de textura base en sprite sheet.
    """
    if output_directory is None:
        output_directory = directory
    
    output_dir = Path(output_directory)
    
    # Agrupar frames
    groups = group_frames_by_prefix(directory)
    
    print(f"\n{'='*70}")
    print(f"PROCESANDO FRAMES DE TEXTURA BASE")
    print(f"{'='*70}")
    print(f"\nEncontrados {len(groups)} grupos de frames\n")
    
    if len(groups) == 0:
        print("ERROR: No se encontraron frames para procesar")
        return []
    
    # Procesar cada grupo
    results = []
    for i, (prefix, frames) in enumerate(sorted(groups.items())):
        num_frames = len(frames)
        
        output_name = f"lava_base_animated_sheet_f{num_frames}_512.png"
        output_path = output_dir / output_name
        
        print(f"{'─'*70}")
        print(f"Grupo: {prefix}")
        print(f"Frames: {num_frames}")
        print(f"Salida: {output_name}")
        print(f"{'─'*70}")
        
        # Crear sprite sheet
        final_size = create_spritesheet(frames, output_path, frame_size=512, padding=4)
        
        print(f"\nCreado: {output_name}")
        print(f"Dimensiones: {final_size[0]}×{final_size[1]}px\n")
        
        results.append((output_name, num_frames, final_size))
    
    # Resumen
    print(f"{'='*70}")
    print(f"RESUMEN")
    print(f"{'='*70}\n")
    
    for name, frames, size in results:
        print(f"  {name} - {frames} frames - {size[0]}×{size[1]}px")
    
    print(f"\n{'='*70}\n")
    
    return results

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("USO: python combine_base_frames.py <directorio>")
        sys.exit(1)
    
    directory = sys.argv[1]
    process_base_texture_frames(directory)

if __name__ == "__main__":
    main()
