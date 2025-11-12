#!/usr/bin/env python3
"""
create_base_spritesheet_with_padding.py
Crea spritesheets de texturas base CON padding de 4px entre frames.
Replica exactamente el formato de snow_base_animated_sheet_f8_512.png que funciona.
"""

from pathlib import Path
from PIL import Image
import sys

def create_spritesheet_with_padding(directory, biome_name, frame_size=512, padding=4):
    """
    Crear spritesheet con padding entre frames (igual que Snow).
    
    Args:
        directory: Directorio con frames 1.png a 8.png
        biome_name: Nombre del bioma (lava, arcanewastes, etc.)
        frame_size: Tamaño de cada frame (default: 512)
        padding: Espaciado entre frames (default: 4)
    """
    dir_path = Path(directory)
    frames = []
    
    print(f"\n{'='*70}")
    print(f"CREANDO SPRITESHEET: {biome_name.upper()}")
    print(f"{'='*70}\n")
    
    # Cargar frames del 1 al 8
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
        
        # Redimensionar si es necesario
        if img.size != (frame_size, frame_size):
            print(f"     Redimensionando {img.size} → {frame_size}×{frame_size}px")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
        
        frames.append(img)
    
    if len(frames) != 8:
        print(f"\n❌ Error: Se esperaban 8 frames, solo se encontraron {len(frames)}")
        return False
    
    print(f"\n✅ 8 frames cargados correctamente\n")
    
    # Calcular dimensiones del spritesheet
    # Formula: (frame_size * num_frames) + (padding * (num_frames - 1))
    num_frames = len(frames)
    sheet_width = (frame_size * num_frames) + (padding * (num_frames - 1))
    sheet_height = frame_size
    
    print(f"Creando spritesheet:")
    print(f"  • Frames: {num_frames}")
    print(f"  • Tamaño por frame: {frame_size}×{frame_size}px")
    print(f"  • Padding entre frames: {padding}px")
    print(f"  • Dimensiones finales: {sheet_width}×{sheet_height}px")
    
    # Crear imagen con fondo transparente
    sprite_sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
    
    # Pegar frames con padding
    x_offset = 0
    for i, frame in enumerate(frames):
        sprite_sheet.paste(frame, (x_offset, 0), frame.split()[3])  # Usar canal alpha como máscara
        x_offset += frame_size + padding
    
    # Guardar
    output_name = f"{biome_name.lower()}_base_animated_sheet_f8_{frame_size}.png"
    output_path = dir_path / output_name
    sprite_sheet.save(output_path, 'PNG', optimize=True)
    
    print(f"\n✅ Spritesheet guardado: {output_name}")
    print(f"   Ruta: {output_path}")
    
    # Verificar resultado
    result_img = Image.open(output_path)
    print(f"\nVerificación:")
    print(f"  • Dimensiones: {result_img.size}")
    print(f"  • Modo: {result_img.mode}")
    print(f"  • Tamaño archivo: {output_path.stat().st_size / 1024:.1f} KB")
    
    print(f"\n{'='*70}")
    print(f"✅ PROCESO COMPLETADO")
    print(f"{'='*70}\n")
    
    return True

def main():
    if len(sys.argv) < 3:
        print("=" * 70)
        print("CREAR SPRITESHEET CON PADDING")
        print("=" * 70)
        print("\nUSO:")
        print("  python create_base_spritesheet_with_padding.py <biome_name> <directory>")
        print("\nEJEMPLOS:")
        print('  python create_base_spritesheet_with_padding.py lava "C:\\path\\to\\Lava\\base"')
        print('  python create_base_spritesheet_with_padding.py arcanewastes "C:\\path\\to\\ArcaneWastes\\base"')
        print("\nNOTA:")
        print("  El directorio debe contener frames numerados: 1.png, 2.png, ..., 8.png")
        print("  Crea spritesheet CON padding de 4px (igual que Snow)")
        print("\n" + "=" * 70)
        sys.exit(1)
    
    biome_name = sys.argv[1]
    directory = sys.argv[2]
    
    dir_path = Path(directory)
    if not dir_path.exists():
        print(f"❌ Error: El directorio no existe: {directory}")
        sys.exit(1)
    
    success = create_spritesheet_with_padding(directory, biome_name)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
