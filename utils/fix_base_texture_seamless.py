#!/usr/bin/env python3
"""
fix_base_texture_seamless.py
Procesa texturas base seamless asegurando que NO haya movimiento.
Para texturas seamless, el contenido debe llenar todo el frame.
"""

from PIL import Image
from pathlib import Path

def process_base_texture(directory, start=1, end=8, output_name="snow_base_animated_sheet_f8_512.png", frame_size=512):
    """
    Procesar textura base seamless.
    
    Para texturas seamless:
    - Todos los frames deben ser exactamente del mismo tamaño
    - El contenido debe llenar el frame completo
    - NO debe haber recorte ni movimiento
    """
    dir_path = Path(directory)
    frames = []
    
    print(f"\n{'='*60}")
    print(f"PROCESANDO TEXTURA BASE SEAMLESS")
    print(f"{'='*60}\n")
    
    # Cargar frames
    for i in range(start, end + 1):
        patterns = [f"{i}.png", f"{i:02d}.png"]
        
        for pattern in patterns:
            file_path = dir_path / pattern
            if file_path.exists():
                print(f"  Cargando: {file_path.name}")
                img = Image.open(file_path)
                
                # Convertir a RGBA si es necesario
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                
                # Verificar y ajustar tamaño
                if img.size != (frame_size, frame_size):
                    print(f"    Redimensionando {img.size} → {frame_size}×{frame_size}px")
                    img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
                
                frames.append(img)
                break
    
    if not frames:
        print(f"❌ No se encontraron frames")
        return False
    
    print(f"\n  Frames procesados: {len(frames)}")
    
    # Verificar que todos tengan el mismo tamaño
    sizes = [f.size for f in frames]
    if len(set(sizes)) > 1:
        print(f"  ⚠️ Inconsistencia en tamaños: {set(sizes)}")
    else:
        print(f"  ✅ Tamaños consistentes: {sizes[0]}")
    
    # Crear sprite sheet
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
    
    print(f"\n✅ Creado: {output_name}")
    print(f"   Dimensiones: {sheet_width}×{sheet_height}px")
    print(f"   Frames: {num_frames}")
    print(f"\n{'='*60}\n")
    
    return True

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("USO: python fix_base_texture_seamless.py <directorio>")
        print("\nEjemplo:")
        print("  python fix_base_texture_seamless.py C:\\path\\to\\Snow\\base")
        sys.exit(1)
    
    directory = sys.argv[1]
    process_base_texture(directory)

if __name__ == "__main__":
    main()
