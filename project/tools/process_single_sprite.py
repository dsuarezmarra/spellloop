#!/usr/bin/env python3
"""
Procesador Individual de Spritesheets - Versión Manual/Controlada
==================================================================
Procesa un spritesheet detectando frames por contenido real.
"""

import sys
from pathlib import Path
from PIL import Image
import numpy as np

def process_spritesheet_carefully(filepath, grid_cols, grid_rows, target_frame_w, target_frame_h, output_path=None):
    """
    Procesa un spritesheet de forma cuidadosa:
    1. Divide según grid especificado
    2. Detecta bounding box del contenido de cada celda
    3. Extrae y centra el contenido
    4. Reescala si es necesario (manteniendo proporción)
    5. Reconstruye el spritesheet final
    """
    img = Image.open(filepath)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    width, height = img.size
    print(f"\n{'='*60}")
    print(f"Procesando: {Path(filepath).name}")
    print(f"{'='*60}")
    print(f"Dimensiones originales: {width}x{height}")
    print(f"Grid esperado: {grid_cols}x{grid_rows} = {grid_cols * grid_rows} frames")
    print(f"Tamaño frame objetivo: {target_frame_w}x{target_frame_h}")
    print(f"Tamaño sheet objetivo: {target_frame_w * grid_cols}x{target_frame_h * grid_rows}")
    
    # Calcular tamaño de celda actual
    cell_w = width / grid_cols
    cell_h = height / grid_rows
    print(f"Tamaño celda actual: {cell_w:.1f}x{cell_h:.1f}")
    
    # Convertir a numpy para análisis
    data = np.array(img)
    alpha = data[:, :, 3]
    
    processed_frames = []
    
    for row in range(grid_rows):
        for col in range(grid_cols):
            idx = row * grid_cols + col
            
            # Posición de la celda actual
            x1 = int(col * cell_w)
            y1 = int(row * cell_h)
            x2 = int((col + 1) * cell_w)
            y2 = int((row + 1) * cell_h)
            
            # Extraer celda
            cell = img.crop((x1, y1, x2, y2))
            cell_alpha = alpha[y1:y2, x1:x2]
            
            # Detectar contenido (píxeles no transparentes)
            rows_with_content = np.any(cell_alpha > 10, axis=1)
            cols_with_content = np.any(cell_alpha > 10, axis=0)
            
            if np.any(rows_with_content) and np.any(cols_with_content):
                # Encontrar bounding box del contenido
                r_indices = np.where(rows_with_content)[0]
                c_indices = np.where(cols_with_content)[0]
                
                content_y1 = r_indices[0]
                content_y2 = r_indices[-1] + 1
                content_x1 = c_indices[0]
                content_x2 = c_indices[-1] + 1
                
                content_w = content_x2 - content_x1
                content_h = content_y2 - content_y1
                
                # Extraer solo el contenido
                content = cell.crop((content_x1, content_y1, content_x2, content_y2))
                
                # Verificar si necesita reescalado
                scale = 1.0
                if content_w > target_frame_w or content_h > target_frame_h:
                    # Escalar hacia abajo manteniendo proporción
                    scale = min(target_frame_w / content_w, target_frame_h / content_h)
                    scale *= 0.95  # Dejar pequeño margen
                    new_w = int(content_w * scale)
                    new_h = int(content_h * scale)
                    content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
                    content_w, content_h = new_w, new_h
                
                # Crear frame del tamaño objetivo y centrar
                new_frame = Image.new("RGBA", (target_frame_w, target_frame_h), (0, 0, 0, 0))
                paste_x = (target_frame_w - content_w) // 2
                paste_y = (target_frame_h - content_h) // 2
                new_frame.paste(content, (paste_x, paste_y))
                
                print(f"  Frame {idx+1}: contenido {content_x2-content_x1}x{content_y2-content_y1} -> centrado (scale: {scale:.2f})")
                processed_frames.append(new_frame)
            else:
                # Frame vacío
                print(f"  Frame {idx+1}: VACÍO")
                processed_frames.append(Image.new("RGBA", (target_frame_w, target_frame_h), (0, 0, 0, 0)))
    
    # Reconstruir spritesheet
    sheet_w = target_frame_w * grid_cols
    sheet_h = target_frame_h * grid_rows
    new_sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    for i, frame in enumerate(processed_frames):
        col = i % grid_cols
        row = i // grid_cols
        x = col * target_frame_w
        y = row * target_frame_h
        new_sheet.paste(frame, (x, y))
    
    # Guardar
    if output_path is None:
        output_path = filepath
    
    new_sheet.save(output_path, "PNG")
    print(f"\n✓ Guardado: {output_path}")
    print(f"  Nuevo tamaño: {sheet_w}x{sheet_h}")
    
    return new_sheet


def main():
    """Función principal - procesa los archivos especificados."""
    
    # Especificaciones de cada tipo
    specs = {
        # PROYECTILES: 4x2 grid, 64x64 frames = 256x128 total
        "projectile": {"grid": (4, 2), "frame": (64, 64)},
        
        # AOE PEQUEÑO: 4x2 grid, 128x128 frames = 512x256 total  
        "aoe_small": {"grid": (4, 2), "frame": (128, 128)},
        
        # AOE GRANDE: 4x2 grid, 256x256 frames = 1024x512 total
        "aoe_large": {"grid": (4, 2), "frame": (256, 256)},
        
        # BEAMS CONE: 4x2 grid, 64x64 frames = 256x256 total
        "beam_cone": {"grid": (4, 2), "frame": (64, 64)},
        
        # BEAM HORIZONTAL: 8x1 grid, 64x64 frames = 512x64 total
        "beam_horizontal": {"grid": (8, 1), "frame": (64, 64)},
        
        # TELEGRAPHS: 4x2 grid, 64x64 frames = 256x128 total
        "telegraph": {"grid": (4, 2), "frame": (64, 64)},
        
        # AURAS GRANDES: 4x2 grid, 128x128 frames = 512x256 total
        "aura_large": {"grid": (4, 2), "frame": (128, 128)},
        
        # AURA PEQUEÑA: 4x2 grid, 64x64 frames = 256x128 total
        "aura_small": {"grid": (4, 2), "frame": (64, 64)},
        
        # BOSS: varios tamaños
        "boss_small": {"grid": (4, 2), "frame": (128, 128)},
        "boss_large": {"grid": (4, 2), "frame": (256, 256)},
    }
    
    # Mapeo de archivos a specs
    file_specs = {
        # Proyectiles
        "projectile_fire_spritesheet.png": specs["projectile"],
        "projectile_ice_spritesheet.png": specs["projectile"],
        "projectile_arcane_spritesheet.png": specs["projectile"],
        "projectile_void_spritesheet.png": specs["projectile"],
        "projectile_poison_spritesheet.png": specs["projectile"],
        "projectile_void_homing_spritesheet.png": specs["projectile"],
        
        # AOE pequeño
        "aoe_fire_stomp_spritesheet.png": specs["aoe_small"],
        "aoe_rune_blast_spritesheet.png": specs["aoe_small"],
        "aoe_ground_slam_spritesheet.png": specs["aoe_small"],
        "aoe_meteor_impact_spritesheet.png": specs["aoe_small"],
        
        # AOE grande
        "aoe_fire_zone_spritesheet.png": specs["aoe_large"],
        "aoe_freeze_zone_spritesheet.png": specs["aoe_large"],
        "aoe_arcane_nova_spritesheet.png": specs["aoe_large"],
        "aoe_void_explosion_spritesheet.png": specs["aoe_large"],
        
        # Beams
        "beam_flame_breath_spritesheet.png": specs["beam_cone"],
        "beam_void_beam_spritesheet.png": specs["beam_horizontal"],
        
        # Telegraphs
        "telegraph_circle_warning_spritesheet.png": specs["telegraph"],
        "telegraph_charge_line_spritesheet.png": specs["telegraph"],
        "telegraph_meteor_warning_spritesheet.png": specs["telegraph"],
        "telegraph_rune_prison_spritesheet.png": specs["telegraph"],
        
        # Auras
        "aura_elite_floor_spritesheet.png": specs["aura_large"],
        "aura_damage_void_spritesheet.png": specs["aura_large"],
        "aura_enrage_spritesheet.png": specs["aura_large"],
        "aura_buff_corruption_spritesheet.png": specs["aura_small"],
        
        # Boss
        "boss_summon_circle_spritesheet.png": specs["boss_small"],
        "boss_void_pull_spritesheet.png": specs["boss_large"],
        "boss_reality_tear_spritesheet.png": specs["boss_small"],
        "boss_rune_shield_spritesheet.png": specs["boss_small"],
    }
    
    if len(sys.argv) < 2:
        print("Uso: python process_single_sprite.py <ruta_imagen> [--dry-run]")
        print("\nArchivos soportados:")
        for name in sorted(file_specs.keys()):
            s = file_specs[name]
            print(f"  {name}: {s['grid'][0]}x{s['grid'][1]} grid, {s['frame'][0]}x{s['frame'][1]} frames")
        sys.exit(1)
    
    filepath = sys.argv[1]
    dry_run = "--dry-run" in sys.argv
    
    filename = Path(filepath).name
    if filename not in file_specs:
        print(f"Error: No tengo especificaciones para '{filename}'")
        sys.exit(1)
    
    spec = file_specs[filename]
    grid = spec["grid"]
    frame = spec["frame"]
    
    if dry_run:
        print(f"[DRY RUN] Procesaría {filename} con grid {grid[0]}x{grid[1]}, frames {frame[0]}x{frame[1]}")
    else:
        process_spritesheet_carefully(
            filepath,
            grid_cols=grid[0],
            grid_rows=grid[1],
            target_frame_w=frame[0],
            target_frame_h=frame[1]
        )


if __name__ == "__main__":
    main()
