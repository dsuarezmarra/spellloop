#!/usr/bin/env python3
"""
Procesador de Spritesheets ChatGPT v2 - Detección por color
============================================================
Detecta los sprites de hielo por su color característico cyan/azul.
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


def is_ice_color(r, g, b):
    """Detecta si un color es parte del sprite de hielo (cyan/azul)."""
    # Colores de hielo: cyan brillante, azul, blanco con tinte azul
    is_cyan = (b > 150) and (g > 150) and (b > r + 20)  # Cyan
    is_blue = (b > 100) and (b > r + 30) and (b > g * 0.7)  # Azul
    is_white_blue = (r > 200) and (g > 200) and (b > 220)  # Blanco con tinte
    is_dark_blue = (b > 50) and (r < 80) and (g < 80)  # Azul oscuro (outline)
    is_sparkle = (r > 240) and (g > 240) and (b > 240)  # Destellos blancos
    
    return is_cyan or is_blue or is_white_blue or is_dark_blue or is_sparkle


def detect_ice_sprites(img):
    """Detecta sprites de hielo basándose en el color."""
    arr = np.array(img)
    height, width = arr.shape[:2]
    
    # Crear máscara de contenido de hielo
    ice_mask = np.zeros((height, width), dtype=bool)
    
    for y in range(height):
        for x in range(width):
            r, g, b = int(arr[y, x, 0]), int(arr[y, x, 1]), int(arr[y, x, 2])
            ice_mask[y, x] = is_ice_color(r, g, b)
    
    # Encontrar columnas con contenido de hielo
    col_has_ice = np.any(ice_mask, axis=0)
    
    # Encontrar sprites (grupos de columnas con contenido)
    sprites = []
    in_sprite = False
    start_x = 0
    gap = 0
    
    for x in range(width):
        if col_has_ice[x]:
            if not in_sprite:
                in_sprite = True
                start_x = x
            gap = 0
        else:
            if in_sprite:
                gap += 1
                if gap > 25:  # Gap de más de 25px = nuevo sprite
                    in_sprite = False
                    end_x = x - gap
                    if end_x - start_x > 25:
                        sprites.append((start_x, end_x, ice_mask))
    
    if in_sprite:
        # Encontrar el último píxel con contenido
        last_col = np.where(col_has_ice)[0]
        if len(last_col) > 0:
            sprites.append((start_x, last_col[-1] + 1, ice_mask))
    
    return sprites, ice_mask


def extract_sprite_by_color(img, x1, x2, ice_mask):
    """Extrae un sprite usando la máscara de color."""
    arr = np.array(img)
    height = arr.shape[0]
    
    # Encontrar rango vertical con contenido
    region_mask = ice_mask[:, x1:x2]
    rows_with_content = np.any(region_mask, axis=1)
    row_indices = np.where(rows_with_content)[0]
    
    if len(row_indices) == 0:
        return None
    
    y1, y2 = row_indices[0], row_indices[-1] + 1
    
    # Extraer región
    sprite_region = arr[y1:y2, x1:x2].copy()
    
    # Convertir a RGBA y hacer transparente lo que no es hielo
    result = np.zeros((y2-y1, x2-x1, 4), dtype=np.uint8)
    result[:, :, :3] = sprite_region[:, :, :3]
    
    # Establecer alpha basado en si es hielo o no
    for y in range(y2-y1):
        for x in range(x2-x1):
            r, g, b = int(sprite_region[y, x, 0]), int(sprite_region[y, x, 1]), int(sprite_region[y, x, 2])
            if is_ice_color(r, g, b):
                result[y, x, 3] = 255
            else:
                result[y, x, 3] = 0
    
    return Image.fromarray(result)


def center_in_frame(sprite, frame_size=64, max_sprite_size=52):
    """Centra un sprite en un frame."""
    if sprite is None:
        return Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    
    w, h = sprite.size
    
    # Escalar si es muy grande
    if w > max_sprite_size or h > max_sprite_size:
        scale = min(max_sprite_size / w, max_sprite_size / h)
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        sprite = sprite.resize((new_w, new_h), Image.Resampling.LANCZOS)
        w, h = sprite.size
    
    # Crear frame y centrar
    frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    x = (frame_size - w) // 2
    y = (frame_size - h) // 2
    frame.paste(sprite, (x, y), sprite)
    
    return frame


def process_ice_spritesheet(input_path, expected_frames, target_frames, duplicate_frame=None):
    """Procesa un spritesheet de hielo."""
    print(f"\n  Procesando: {Path(input_path).name}")
    
    img = Image.open(input_path).convert('RGB')
    print(f"  Tamaño: {img.size}")
    
    # Detectar sprites por color
    sprite_ranges, ice_mask = detect_ice_sprites(img)
    print(f"  Sprites detectados por color: {len(sprite_ranges)}")
    
    for i, (x1, x2, _) in enumerate(sprite_ranges):
        print(f"    Sprite {i+1}: x={x1}-{x2} (ancho={x2-x1}px)")
    
    # Extraer frames
    frames = []
    for x1, x2, mask in sprite_ranges[:expected_frames]:
        sprite = extract_sprite_by_color(img, x1, x2, mask)
        if sprite:
            frames.append(sprite)
            print(f"    → Extraído: {sprite.size}")
    
    if len(frames) < expected_frames:
        print(f"  ⚠️ Solo se detectaron {len(frames)} sprites de {expected_frames} esperados")
        # Intentar dividir la imagen uniformemente
        width = img.size[0]
        frame_width = width // expected_frames
        print(f"  Intentando división uniforme ({frame_width}px por frame)")
        
        frames = []
        for i in range(expected_frames):
            x1 = i * frame_width
            x2 = (i + 1) * frame_width
            sprite = extract_sprite_by_color(img, x1, x2, ice_mask)
            if sprite:
                frames.append(sprite)
    
    # Duplicar frame si es necesario
    if len(frames) < target_frames and duplicate_frame is not None:
        dup_idx = min(duplicate_frame, len(frames) - 1)
        while len(frames) < target_frames:
            frames.insert(dup_idx + 1, frames[dup_idx].copy())
        print(f"  Duplicado frame {dup_idx + 1} para alcanzar {target_frames} frames")
    
    # Crear spritesheet
    sheet = Image.new('RGBA', (64 * len(frames), 64), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        centered = center_in_frame(frame)
        sheet.paste(centered, (i * 64, 0))
    
    print(f"  Spritesheet final: {sheet.size[0]}x{sheet.size[1]} ({len(frames)} frames)")
    
    return sheet


def main():
    print("=" * 60)
    print("  ICE WAND PROCESSOR v2 - Detección por Color")
    print("=" * 60)
    
    downloads = Path(r"C:\Users\Usuario\Downloads")
    output_dir = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\ice_wand")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Archivos de ChatGPT (más reciente primero)
    files = sorted(downloads.glob("ChatGPT*.png"), key=lambda f: f.stat().st_mtime, reverse=True)[:3]
    
    print(f"\nArchivos encontrados:")
    for i, f in enumerate(files):
        print(f"  [{i}] {f.name}")
    
    # Configuración basada en el análisis previo:
    # - Imagen más reciente (índice 0) = launch (4 frames)
    # - Imagen media (índice 1) = impact (5 frames -> 6)
    # - Imagen más antigua (índice 2) = flight (5 frames -> 6)
    
    configs = [
        ("flight", files[2], 5, 6, 2),   # Flight: 5->6 frames, duplicar frame 3
        ("impact", files[1], 5, 6, 2),   # Impact: 5->6 frames, duplicar frame 3
        ("launch", files[0], 4, 4, None) # Launch: 4 frames exactos
    ]
    
    print("\n" + "-" * 60)
    
    for name, file_path, expected, target, dup in configs:
        print(f"\n>> {name.upper()}")
        sheet = process_ice_spritesheet(str(file_path), expected, target, dup)
        
        output_path = output_dir / f"{name}.png"
        sheet.save(str(output_path), 'PNG')
        print(f"  ✅ Guardado: {output_path}")
    
    print("\n" + "=" * 60)
    print("  ✅ COMPLETADO")
    print("=" * 60)


if __name__ == "__main__":
    main()
