#!/usr/bin/env python3
"""
Procesador de Spritesheets ChatGPT para Ice Wand - Versión Manual
=================================================================
Este script procesa las imágenes de ChatGPT que tienen fondo de checkerboard
visual (no transparente) y las convierte al formato correcto para Godot.

Dado que la detección automática es complicada con el checkerboard visual,
este script permite especificar manualmente cuántos sprites hay.
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("ERROR: pip install Pillow numpy")
    sys.exit(1)


def remove_checkerboard_advanced(img):
    """
    Elimina el fondo de checkerboard usando detección de colores.
    Más agresivo para capturar todo el checkerboard.
    """
    arr = np.array(img)
    height, width = arr.shape[:2]
    
    # Crear imagen de salida con canal alpha
    result = np.zeros((height, width, 4), dtype=np.uint8)
    result[:, :, :3] = arr[:, :, :3]
    
    # Detectar píxeles de checkerboard
    r = arr[:, :, 0].astype(np.int16)
    g = arr[:, :, 1].astype(np.int16)
    b = arr[:, :, 2].astype(np.int16)
    
    # Un píxel es checkerboard si es gris (R≈G≈B) y está en rango medio
    is_gray = (np.abs(r - g) < 20) & (np.abs(r - b) < 20) & (np.abs(g - b) < 20)
    is_mid_value = (r > 140) & (r < 220)
    is_background = is_gray & is_mid_value
    
    # Establecer alpha
    result[:, :, 3] = np.where(is_background, 0, 255)
    
    return Image.fromarray(result)


def split_into_frames(img, num_frames):
    """
    Divide una imagen en el número especificado de frames.
    Detecta los sprites y los distribuye.
    """
    # Primero, remover el checkerboard
    clean = remove_checkerboard_advanced(img)
    arr = np.array(clean)
    alpha = arr[:, :, 3]
    
    height, width = alpha.shape
    
    # Encontrar la región con contenido (vertical)
    row_has_content = np.any(alpha > 128, axis=1)
    content_rows = np.where(row_has_content)[0]
    
    if len(content_rows) > 0:
        y_min = content_rows[0]
        y_max = content_rows[-1] + 1
    else:
        y_min, y_max = 0, height
    
    # Encontrar columnas con contenido para cada frame potencial
    col_has_content = np.any(alpha > 128, axis=0)
    
    # Encontrar los gaps entre sprites
    in_sprite = False
    sprite_ranges = []
    start_x = 0
    
    for x in range(width):
        if col_has_content[x]:
            if not in_sprite:
                in_sprite = True
                start_x = x
        else:
            if in_sprite:
                # Verificar si es un gap real (más de 5 píxeles)
                gap_size = 0
                for check_x in range(x, min(x + 30, width)):
                    if not col_has_content[check_x]:
                        gap_size += 1
                    else:
                        break
                
                if gap_size > 8:  # Gap real
                    in_sprite = False
                    if x - start_x > 15:
                        sprite_ranges.append((start_x, x))
    
    # Último sprite
    if in_sprite:
        content_cols = np.where(col_has_content)[0]
        if len(content_cols) > 0:
            sprite_ranges.append((start_x, content_cols[-1] + 1))
    
    print(f"  Sprites detectados automáticamente: {len(sprite_ranges)}")
    
    # Si no detectamos suficientes, dividir uniformemente
    if len(sprite_ranges) < num_frames:
        print(f"  Usando división uniforme en {num_frames} partes")
        frame_width = width // num_frames
        sprite_ranges = [(i * frame_width, (i + 1) * frame_width) for i in range(num_frames)]
    
    # Extraer cada frame
    frames = []
    for i, (x1, x2) in enumerate(sprite_ranges[:num_frames]):
        # Extraer región del sprite
        sprite_region = arr[y_min:y_max, x1:x2]
        
        # Encontrar bounding box real del contenido
        sprite_alpha = sprite_region[:, :, 3]
        rows_with_content = np.any(sprite_alpha > 128, axis=1)
        cols_with_content = np.any(sprite_alpha > 128, axis=0)
        
        row_indices = np.where(rows_with_content)[0]
        col_indices = np.where(cols_with_content)[0]
        
        if len(row_indices) > 0 and len(col_indices) > 0:
            crop_y1, crop_y2 = row_indices[0], row_indices[-1] + 1
            crop_x1, crop_x2 = col_indices[0], col_indices[-1] + 1
            sprite = Image.fromarray(sprite_region[crop_y1:crop_y2, crop_x1:crop_x2])
        else:
            sprite = Image.fromarray(sprite_region)
        
        frames.append(sprite)
        print(f"    Frame {i+1}: tamaño original {sprite.size}")
    
    return frames


def center_in_frame(sprite, frame_size=64, max_sprite_size=54):
    """Centra un sprite en un frame de tamaño fijo."""
    w, h = sprite.size
    
    # Escalar si es necesario
    if w > max_sprite_size or h > max_sprite_size:
        scale = min(max_sprite_size / w, max_sprite_size / h)
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
        w, h = sprite.size
    
    # Crear frame transparente y centrar
    frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    x = (frame_size - w) // 2
    y = (frame_size - h) // 2
    frame.paste(sprite, (x, y), sprite)
    
    return frame


def create_spritesheet(frames, frame_size=64):
    """Crea un spritesheet horizontal."""
    width = frame_size * len(frames)
    sheet = Image.new('RGBA', (width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        centered = center_in_frame(frame, frame_size)
        sheet.paste(centered, (i * frame_size, 0))
    
    return sheet


def duplicate_frame(frames, frame_index, count=1):
    """Duplica un frame específico para alcanzar el conteo deseado."""
    result = frames.copy()
    for _ in range(count):
        result.insert(frame_index + 1, frames[frame_index].copy())
    return result


def main():
    print("=" * 60)
    print("  PROCESADOR DE SPRITESHEETS - ICE WAND (ChatGPT)")
    print("=" * 60)
    
    # Rutas
    downloads = Path(r"C:\Users\Usuario\Downloads")
    output_dir = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\ice_wand")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Buscar imágenes de ChatGPT
    chatgpt_files = sorted(
        downloads.glob("ChatGPT*.png"),
        key=lambda f: f.stat().st_mtime,
        reverse=True
    )[:3]
    
    if len(chatgpt_files) < 3:
        print(f"ERROR: Solo encontré {len(chatgpt_files)} imágenes de ChatGPT")
        return
    
    # Las imágenes están ordenadas por tiempo (más reciente primero)
    # Según el análisis: la más reciente (53) es launch, luego (51) es impact, (48) es flight
    # Pero el usuario dijo: 1=flight, 2=impact, 3=launch
    # Vamos a verificar con los tamaños esperados
    
    configs = [
        {
            "file_index": 2,  # La más antigua = flight
            "name": "flight",
            "expected_frames": 5,
            "target_frames": 6,
            "duplicate_at": 2  # Duplicar frame 3
        },
        {
            "file_index": 1,  # Media = impact
            "name": "impact",
            "expected_frames": 5,
            "target_frames": 6,
            "duplicate_at": 2
        },
        {
            "file_index": 0,  # Más reciente = launch
            "name": "launch",
            "expected_frames": 4,
            "target_frames": 4,
            "duplicate_at": None
        }
    ]
    
    print(f"\nArchivos encontrados (más reciente primero):")
    for i, f in enumerate(chatgpt_files):
        print(f"  {i}: {f.name}")
    
    print("\n" + "-" * 60)
    
    for config in configs:
        print(f"\n>> Procesando {config['name'].upper()}")
        
        input_file = chatgpt_files[config["file_index"]]
        print(f"   Archivo: {input_file.name}")
        
        # Cargar imagen
        img = Image.open(input_file).convert('RGBA')
        print(f"   Tamaño: {img.size}")
        
        # Dividir en frames
        frames = split_into_frames(img, config["expected_frames"])
        
        # Duplicar frame si es necesario
        if config["duplicate_at"] is not None and len(frames) < config["target_frames"]:
            frames_needed = config["target_frames"] - len(frames)
            print(f"   Duplicando frame {config['duplicate_at']+1} ({frames_needed}x)")
            frames = duplicate_frame(frames, config["duplicate_at"], frames_needed)
        
        # Crear spritesheet
        sheet = create_spritesheet(frames)
        
        # Guardar
        output_path = output_dir / f"{config['name']}.png"
        sheet.save(str(output_path), 'PNG')
        
        print(f"   ✅ Guardado: {output_path}")
        print(f"   📐 Tamaño final: {sheet.size[0]}x{sheet.size[1]} ({len(frames)} frames)")
    
    print("\n" + "=" * 60)
    print("  PROCESO COMPLETADO")
    print("=" * 60)
    print(f"\nArchivos generados en:\n  {output_dir}")


if __name__ == "__main__":
    main()
