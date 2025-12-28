#!/usr/bin/env python3
"""
Script para añadir padding transparente entre frames de spritesheets.
Esto evita el "sangrado" de píxeles entre frames adyacentes en Godot.

Formato entrada: 612x408 (3 frames de 204x408)
Formato salida: 636x408 (3 frames de 204x408 + 8px padding entre cada frame)
"""

import os
import sys
from PIL import Image
from pathlib import Path

# Configuración
FRAME_COUNT = 3
PADDING_PIXELS = 8  # Píxeles de padding transparente entre frames
INPUT_FRAME_WIDTH = 204
INPUT_FRAME_HEIGHT = 408

def add_padding_to_spritesheet(input_path: str, output_path: str = None) -> bool:
    """
    Añade padding transparente entre frames de un spritesheet.
    
    Args:
        input_path: Ruta al spritesheet original
        output_path: Ruta de salida (si es None, sobrescribe el original)
    
    Returns:
        True si tuvo éxito, False en caso de error
    """
    if output_path is None:
        output_path = input_path
    
    try:
        # Abrir imagen original
        img = Image.open(input_path)
        
        # Verificar dimensiones
        orig_width, orig_height = img.size
        expected_width = INPUT_FRAME_WIDTH * FRAME_COUNT
        
        if orig_width != expected_width:
            print(f"  ⚠ Ancho inesperado: {orig_width} (esperado {expected_width})")
            # Calcular ancho de frame dinámicamente
            frame_width = orig_width // FRAME_COUNT
        else:
            frame_width = INPUT_FRAME_WIDTH
        
        frame_height = orig_height
        
        # Calcular nuevo tamaño con padding
        # Padding solo ENTRE frames, no en los bordes externos
        total_padding = PADDING_PIXELS * (FRAME_COUNT - 1)  # 2 espacios entre 3 frames
        new_width = orig_width + total_padding
        new_height = frame_height
        
        # Crear nueva imagen con fondo transparente
        new_img = Image.new('RGBA', (new_width, new_height), (0, 0, 0, 0))
        
        # Convertir a RGBA si no lo es
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Copiar cada frame con el offset del padding
        for i in range(FRAME_COUNT):
            # Posición en imagen original
            src_x = i * frame_width
            
            # Posición en nueva imagen (con padding acumulado)
            dst_x = i * (frame_width + PADDING_PIXELS)
            
            # Extraer frame
            frame = img.crop((src_x, 0, src_x + frame_width, frame_height))
            
            # Pegar en nueva posición
            new_img.paste(frame, (dst_x, 0))
        
        # Guardar
        new_img.save(output_path, 'PNG')
        return True
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def process_all_spritesheets(base_dir: str, dry_run: bool = False):
    """
    Procesa todos los spritesheets de enemigos en el directorio dado.
    """
    sprites_dir = Path(base_dir) / "assets" / "sprites" / "enemies"
    
    if not sprites_dir.exists():
        print(f"Error: No se encontró el directorio {sprites_dir}")
        return
    
    # Buscar todos los spritesheets
    spritesheets = list(sprites_dir.glob("**/*_spritesheet.png"))
    
    print(f"Encontrados {len(spritesheets)} spritesheets")
    print(f"Padding a añadir: {PADDING_PIXELS}px entre frames")
    print(f"{'[DRY RUN] ' if dry_run else ''}Procesando...\n")
    
    success_count = 0
    error_count = 0
    
    for spritesheet in sorted(spritesheets):
        rel_path = spritesheet.relative_to(base_dir)
        
        # Verificar tamaño actual
        try:
            img = Image.open(spritesheet)
            width, height = img.size
            img.close()
            
            # Detectar si ya tiene padding (ancho mayor a 612)
            expected_no_padding = INPUT_FRAME_WIDTH * FRAME_COUNT
            expected_with_padding = expected_no_padding + PADDING_PIXELS * (FRAME_COUNT - 1)
            
            if width == expected_with_padding:
                print(f"  ⊘ {rel_path} - Ya tiene padding ({width}x{height})")
                continue
            elif width != expected_no_padding:
                print(f"  ⚠ {rel_path} - Tamaño inusual ({width}x{height}), procesando igual...")
            
            print(f"  → {rel_path} ({width}x{height})", end="")
            
            if dry_run:
                print(" [SKIP - dry run]")
                continue
            
            if add_padding_to_spritesheet(str(spritesheet)):
                # Verificar nuevo tamaño
                img = Image.open(spritesheet)
                new_width, new_height = img.size
                img.close()
                print(f" → ({new_width}x{new_height}) ✓")
                success_count += 1
            else:
                error_count += 1
                
        except Exception as e:
            print(f"  ✗ {rel_path} - Error: {e}")
            error_count += 1
    
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Completado: {success_count} procesados, {error_count} errores")

def main():
    # Determinar directorio base del proyecto
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent / "project"
    
    if not project_dir.exists():
        print(f"Error: No se encontró el directorio del proyecto en {project_dir}")
        sys.exit(1)
    
    print("=" * 60)
    print("AÑADIR PADDING A SPRITESHEETS")
    print("=" * 60)
    print(f"Directorio: {project_dir}")
    print()
    
    # Verificar si hay argumento --dry-run
    dry_run = "--dry-run" in sys.argv
    
    process_all_spritesheets(str(project_dir), dry_run=dry_run)

if __name__ == "__main__":
    main()
