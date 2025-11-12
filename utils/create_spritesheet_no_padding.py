#!/usr/bin/env python3
"""
create_spritesheet_no_padding.py
Crea spritesheet SIN padding y SIN modificar los frames.
Solo combina los frames tal cual están.
"""

from PIL import Image
from pathlib import Path
import sys

def create_spritesheet_simple(directory, biome_name, frame_size=512):
    """
    Crear spritesheet SIN padding, SIN modificaciones.
    Solo pegar los frames uno al lado del otro.
    """
    dir_path = Path(directory)
    
    print(f"\n{'='*70}")
    print(f"CREANDO SPRITESHEET SIMPLE: {biome_name.upper()}")
    print(f"{'='*70}\n")
    
    frames = []
    
    # Cargar frames sin modificar
    print("Cargando frames:")
    for i in range(1, 9):
        frame_path = dir_path / f"{i}.png"
        
        if not frame_path.exists():
            print(f"  ❌ No encontrado: {frame_path.name}")
            continue
        
        print(f"  📄 {frame_path.name}")
        img = Image.open(frame_path)
        
        # Convertir a RGBA
        if img.mode != 'RGBA':
            print(f"     Convirtiendo {img.mode} → RGBA")
            img = img.convert('RGBA')
        
        # Redimensionar si necesario
        if img.size != (frame_size, frame_size):
            print(f"     Redimensionando {img.size} → {frame_size}×{frame_size}px")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
        
        frames.append(img)
        print(f"     ✅ Cargado")
    
    if len(frames) != 8:
        print(f"\n❌ Error: Se esperaban 8 frames, solo se cargaron {len(frames)}")
        return False
    
    print(f"\n✅ 8 frames cargados\n")
    
    # Crear spritesheet SIN padding (frames directamente uno al lado del otro)
    num_frames = len(frames)
    sheet_width = frame_size * num_frames  # SIN padding
    sheet_height = frame_size
    
    print(f"Creando spritesheet:")
    print(f"  • Frames: {num_frames}")
    print(f"  • Tamaño por frame: {frame_size}×{frame_size}px")
    print(f"  • Padding: 0px (SIN espacios entre frames)")
    print(f"  • Dimensiones finales: {sheet_width}×{sheet_height}px")
    
    # Crear imagen con fondo transparente
    spritesheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
    
    # Pegar frames directamente sin padding
    x_offset = 0
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (x_offset, 0), frame.split()[3])
        x_offset += frame_size  # Siguiente frame sin espacio
    
    # Guardar
    output_name = f"{biome_name.lower()}_base_animated_sheet_f8_{frame_size}.png"
    output_path = dir_path / output_name
    
    spritesheet.save(output_path, 'PNG', compress_level=6)
    
    print(f"\n✅ Spritesheet guardado: {output_name}")
    
    # Verificar
    result = Image.open(output_path)
    file_size = output_path.stat().st_size / (1024 * 1024)
    
    print(f"\nVerificación:")
    print(f"  • Dimensiones: {result.size}")
    print(f"  • Modo: {result.mode}")
    print(f"  • Tamaño: {file_size:.2f} MB")
    
    print(f"\n{'='*70}")
    print(f"✅ COMPLETADO - Frames originales sin modificar")
    print(f"{'='*70}\n")
    
    return True

def main():
    if len(sys.argv) < 3:
        print("="*70)
        print("CREAR SPRITESHEET SIMPLE (SIN PADDING)")
        print("="*70)
        print("\nUSO:")
        print("  python create_spritesheet_no_padding.py <biome_name> <directory>")
        print("\nEJEMPLO:")
        print('  python create_spritesheet_no_padding.py lava "C:\\path\\to\\Lava\\base"')
        print("\nCARACTERÍSTICAS:")
        print("  • SIN padding entre frames (tiles contiguos)")
        print("  • SIN modificación de frames originales")
        print("  • Perfecto para texturas que ya son seamless")
        print("\n" + "="*70)
        sys.exit(1)
    
    biome_name = sys.argv[1]
    directory = sys.argv[2]
    
    if not Path(directory).exists():
        print(f"❌ Error: No existe el directorio: {directory}")
        sys.exit(1)
    
    success = create_spritesheet_simple(directory, biome_name, frame_size=512)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
