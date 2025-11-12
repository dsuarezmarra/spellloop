#!/usr/bin/env python3
"""
Process 8 individual frame images into a Godot-compatible animated spritesheet.
Creates a 4124x512px spritesheet with 8 frames (512x512 each) + 4px padding.
"""

import sys
from pathlib import Path
from PIL import Image

def process_frames(input_folder: str, output_path: str):
    """
    Process 8 individual frames into a single spritesheet.
    
    Args:
        input_folder: Folder containing 1.png through 8.png
        output_path: Path for output spritesheet
    """
    input_dir = Path(input_folder)
    
    # Verificar que existen los 8 frames
    frame_files = []
    for i in range(1, 9):
        frame_path = input_dir / f"{i}.png"
        if not frame_path.exists():
            print(f"❌ ERROR: No se encontró {frame_path}")
            sys.exit(1)
        frame_files.append(frame_path)
    
    print(f"✅ Encontrados 8 frames en {input_dir}")
    
    # Configuración del spritesheet final
    FRAME_SIZE = 512
    PADDING = 4
    NUM_FRAMES = 8
    OUTPUT_WIDTH = (FRAME_SIZE * NUM_FRAMES) + PADDING
    OUTPUT_HEIGHT = FRAME_SIZE
    
    # Crear imagen de salida
    output = Image.new('RGBA', (OUTPUT_WIDTH, OUTPUT_HEIGHT), (0, 0, 0, 0))
    
    print(f"📐 Creando spritesheet {OUTPUT_WIDTH}x{OUTPUT_HEIGHT}px...")
    
    # Procesar cada frame
    for i, frame_path in enumerate(frame_files):
        print(f"  Procesando frame {i+1}/8: {frame_path.name}")
        
        # Cargar imagen
        img = Image.open(frame_path)
        
        # Convertir a RGBA si es necesario
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Verificar tamaño
        width, height = img.size
        print(f"    Tamaño original: {width}x{height}px")
        
        # Si no es cuadrada, recortar al centro
        if width != height:
            min_dim = min(width, height)
            left = (width - min_dim) // 2
            top = (height - min_dim) // 2
            img = img.crop((left, top, left + min_dim, top + min_dim))
            print(f"    Recortada a: {min_dim}x{min_dim}px (cuadrada)")
        
        # Redimensionar a 512x512 si es necesario
        if img.size != (FRAME_SIZE, FRAME_SIZE):
            img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.LANCZOS)
            print(f"    Redimensionada a: {FRAME_SIZE}x{FRAME_SIZE}px")
        
        # Pegar en el spritesheet
        x_pos = i * FRAME_SIZE
        output.paste(img, (x_pos, 0))
        print(f"    ✅ Pegado en posición x={x_pos}")
    
    # Guardar resultado
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_file, 'PNG', optimize=True)
    
    file_size_mb = output_file.stat().st_size / (1024 * 1024)
    print(f"\n✅ Spritesheet creado exitosamente:")
    print(f"   📁 {output_file}")
    print(f"   📐 {OUTPUT_WIDTH}x{OUTPUT_HEIGHT}px")
    print(f"   💾 {file_size_mb:.2f} MB")
    print(f"   🎬 {NUM_FRAMES} frames @ {FRAME_SIZE}x{FRAME_SIZE}px + {PADDING}px padding")

def main():
    if len(sys.argv) != 3:
        print("Uso: python process_individual_frames.py <carpeta_con_frames> <ruta_salida>")
        print("\nEjemplo:")
        print('  python process_individual_frames.py "$env:USERPROFILE\\Downloads" "project/assets/textures/biomes/Grassland/base/grassland_base_animated_sheet_f8_512.png"')
        sys.exit(1)
    
    input_folder = sys.argv[1]
    output_path = sys.argv[2]
    
    print("🌿 PROCESADOR DE FRAMES INDIVIDUALES → SPRITESHEET")
    print("=" * 60)
    
    process_frames(input_folder, output_path)
    
    print("\n✨ ¡Listo! Ahora puedes probar en Godot con test_grassland_decorations.tscn")

if __name__ == "__main__":
    main()
