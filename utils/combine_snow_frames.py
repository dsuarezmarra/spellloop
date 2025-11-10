#!/usr/bin/env python3
"""
combine_snow_frames.py
Combina frames numerados en sprite sheets horizontales.
"""

from pathlib import Path
from PIL import Image
import re

def combine_frames(directory, prefix, start, end, output_name, frame_size=256):
    """
    Combinar frames numerados en un sprite sheet.
    
    Args:
        directory: Directorio con los frames
        prefix: Prefijo de los archivos (ej: '' para '1.png', '01' para '01.png')
        start: Número inicial
        end: Número final  
        output_name: Nombre del archivo de salida
        frame_size: Tamaño de cada frame
    """
    dir_path = Path(directory)
    frames = []
    
    # Cargar frames
    for i in range(start, end + 1):
        # Intentar diferentes formatos de numeración
        patterns = [
            f"{prefix}{i}.png",
            f"{prefix}{i:02d}.png",
            f"{prefix}{i:03d}.png"
        ]
        
        found = False
        for pattern in patterns:
            file_path = dir_path / pattern
            if file_path.exists():
                print(f"  Cargando: {file_path.name}")
                img = Image.open(file_path)
                
                # Convertir a RGBA si es necesario
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                
                # Redimensionar si es necesario
                if img.size != (frame_size, frame_size):
                    print(f"    Redimensionando {img.size} → {frame_size}×{frame_size}px")
                    img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
                
                frames.append(img)
                found = True
                break
        
        if not found:
            print(f"  ⚠️ No encontrado: frame {i}")
    
    if not frames:
        print(f"❌ No se encontraron frames")
        return False
    
    # Crear sprite sheet horizontal
    num_frames = len(frames)
    sheet_width = frame_size * num_frames
    sheet_height = frame_size
    
    sprite_sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
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
        print("USO: python combine_snow_frames.py <directorio>")
        print("\nEjemplo:")
        print("  python combine_snow_frames.py C:\\path\\to\\Snow\\base")
        print("  python combine_snow_frames.py C:\\path\\to\\Snow\\decor")
        sys.exit(1)
    
    directory = sys.argv[1]
    dir_path = Path(directory)
    
    if not dir_path.exists():
        print(f"❌ Error: El directorio no existe: {directory}")
        sys.exit(1)
    
    print("=" * 60)
    print("PROCESANDO FRAMES DE SNOW")
    print("=" * 60)
    print()
    
    # Detectar si es base o decor
    if 'base' in str(directory).lower():
        print("📁 Modo: TEXTURA BASE")
        print("-" * 60)
        combine_frames(directory, '', 1, 8, 'snow_base_animated_sheet_f8_512.png', frame_size=512)
    
    elif 'decor' in str(directory).lower():
        print("📁 Modo: DECORACIONES")
        print("-" * 60)
        
        # Detectar todos los grupos de decoraciones
        decor_groups = [
            ('', 1, 8, 1, 256),      # Decor 1: 01-08
            ('', 1, 8, 2, 256),      # Decor 2: 1-8
            ('', 11, 18, 3, 256),    # Decor 3: 11-18
            ('', 21, 28, 4, 256),    # Decor 4: 21-28
            ('', 31, 38, 5, 256),    # Decor 5: 31-38
            ('', 41, 48, 6, 256),    # Decor 6: 41-48
            ('', 51, 58, 7, 256),    # Decor 7: 51-58
            ('', 61, 68, 8, 256),    # Decor 8: 61-68
            ('', 71, 78, 9, 256),    # Decor 9: 71-78
            ('', 81, 88, 10, 256),   # Decor 10: 81-88
            ('', 91, 98, 11, 256),   # Decor 11: 91-98
        ]
        
        for prefix, start, end, decor_num, size in decor_groups:
            output = f"snow_decor{decor_num}_sheet_f8_{size}.png"
            print(f"\n🎨 Decor {decor_num}: frames {start}-{end}")
            print("-" * 60)
            combine_frames(directory, prefix, start, end, output, frame_size=size)
    
    else:
        print("❌ Error: No se pudo determinar si es 'base' o 'decor'")
        print("   El directorio debe contener 'base' o 'decor' en su ruta")
        sys.exit(1)
    
    print("=" * 60)
    print("✅ PROCESO COMPLETADO")
    print("=" * 60)

if __name__ == "__main__":
    main()
