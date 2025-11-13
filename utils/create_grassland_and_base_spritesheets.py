#!/usr/bin/env python3
"""
Script para crear todos los spritesheets necesarios:
- 10 decoraciones de Grassland (frames 01-08, 11-18, ..., 91-98)
- Textura base de Desert (frames 01-08)
- Textura base de Death (frames 1-8)
"""

import sys
from pathlib import Path
from PIL import Image

def create_spritesheet_from_frames(input_folder: Path, frame_numbers: list, output_path: Path, frame_size: int = 256):
    """
    Crea un spritesheet a partir de una lista de números de frame.

    Args:
        input_folder: Carpeta con los frames
        frame_numbers: Lista de números de frame a procesar (ej: [1, 2, 3, 4, 5, 6, 7, 8])
        output_path: Ruta del spritesheet de salida
        frame_size: Tamaño de cada frame (256 o 512)
    """
    # Verificar que existen todos los frames
    frame_files = []
    for num in frame_numbers:
        # Intentar con y sin ceros a la izquierda
        frame_path = input_folder / f"{num:02d}.png"
        if not frame_path.exists():
            frame_path = input_folder / f"{num}.png"

        if not frame_path.exists():
            print(f"❌ ERROR: No se encontró frame {num} en {input_folder}")
            return False
        frame_files.append(frame_path)

    print(f"✅ Encontrados {len(frame_files)} frames")

    # Configuración del spritesheet
    PADDING = 4
    NUM_FRAMES = len(frame_files)
    OUTPUT_WIDTH = (frame_size * NUM_FRAMES) + PADDING
    OUTPUT_HEIGHT = frame_size

    # Crear imagen de salida
    output = Image.new('RGBA', (OUTPUT_WIDTH, OUTPUT_HEIGHT), (0, 0, 0, 0))

    print(f"📐 Creando spritesheet {OUTPUT_WIDTH}x{OUTPUT_HEIGHT}px...")

    # Procesar cada frame
    for i, frame_path in enumerate(frame_files):
        # Cargar imagen
        img = Image.open(frame_path)

        # Convertir a RGBA si es necesario
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Si no es cuadrada, recortar al centro
        width, height = img.size
        if width != height:
            min_dim = min(width, height)
            left = (width - min_dim) // 2
            top = (height - min_dim) // 2
            img = img.crop((left, top, left + min_dim, top + min_dim))

        # Redimensionar al tamaño correcto si es necesario
        if img.size != (frame_size, frame_size):
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)

        # Pegar en el spritesheet
        x_pos = i * frame_size
        output.paste(img, (x_pos, 0))

    # Guardar resultado
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path, 'PNG', optimize=True)

    file_size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"✅ Spritesheet creado: {output_path.name} ({file_size_mb:.2f} MB)")

    return True

def main():
    print("🎨 CREADOR DE SPRITESHEETS - GRASSLAND DECOR + DESERT/DEATH BASE")
    print("=" * 70)

    # Rutas base
    downloads = Path("C:/Users/dsuarez1/Downloads/biomes")
    project_assets = Path("c:/Users/dsuarez1/git/spellloop/project/assets/textures/biomes")

    success_count = 0
    total_count = 0

    # ===== GRASSLAND DECOR (10 decoraciones, 256x256) =====
    print("\n📦 PROCESANDO GRASSLAND DECOR...")
    print("-" * 70)

    grassland_decor_folder = downloads / "Grassland" / "decor"
    grassland_output_folder = project_assets / "Grassland" / "decor"

    # 10 decoraciones: frames 01-08, 11-18, 21-28, ..., 91-98
    for decor_num in range(1, 11):
        total_count += 1
        start_frame = decor_num * 10 + 1
        frame_numbers = list(range(start_frame, start_frame + 8))

        output_path = grassland_output_folder / f"grassland_decor{decor_num}_sheet_f8_256.png"

        print(f"\n🌿 Decor {decor_num} (frames {frame_numbers[0]:02d}-{frame_numbers[-1]:02d}):")

        if create_spritesheet_from_frames(grassland_decor_folder, frame_numbers, output_path, frame_size=256):
            success_count += 1

    # ===== DESERT BASE (512x512) =====
    print("\n\n🏜️  PROCESANDO DESERT BASE...")
    print("-" * 70)

    desert_base_folder = downloads / "Desert" / "base"
    desert_output_folder = project_assets / "Desert" / "base"
    desert_output = desert_output_folder / "desert_base_animated_sheet_f8_512.png"

    total_count += 1
    print("\n🏜️  Textura base (frames 01-08):")
    if create_spritesheet_from_frames(desert_base_folder, list(range(1, 9)), desert_output, frame_size=512):
        success_count += 1

    # ===== DEATH BASE (512x512) =====
    print("\n\n💀 PROCESANDO DEATH BASE...")
    print("-" * 70)

    death_base_folder = downloads / "Death" / "base"
    death_output_folder = project_assets / "Death" / "base"
    death_output = death_output_folder / "death_base_animated_sheet_f8_512.png"

    total_count += 1
    print("\n💀 Textura base (frames 1-8):")
    if create_spritesheet_from_frames(death_base_folder, list(range(1, 9)), death_output, frame_size=512):
        success_count += 1

    # ===== RESUMEN =====
    print("\n" + "=" * 70)
    print(f"✅ COMPLETADO: {success_count}/{total_count} spritesheets creados")
    print("=" * 70)

    if success_count == total_count:
        print("\n🎉 ¡Todos los spritesheets se crearon exitosamente!")
        return 0
    else:
        print(f"\n⚠️  {total_count - success_count} spritesheets fallaron")
        return 1

if __name__ == "__main__":
    sys.exit(main())
