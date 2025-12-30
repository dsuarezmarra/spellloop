#!/usr/bin/env python3
"""
Procesador de sprites para Stone Fang (Shadow + Earth)
Colmillo de Piedra - obsidian fang projectile

Colores clave:
- Main body: Dark charcoal gray (#403340)
- Obsidian core: Near black (#332833)
- Earth veins: Brown-gray (#665850)
- Shadow wisps: Very dark purple (#2A1F2A)
- Highlights: Glassy obsidian shine (#807080)
"""

from PIL import Image
import numpy as np
from scipy.ndimage import gaussian_filter1d
from scipy.signal import argrelmin
import os

def find_valleys_in_density(density_profile, min_distance=50):
    """Encuentra valles en el perfil de densidad usando mínimos locales."""
    smoothed = gaussian_filter1d(density_profile.astype(float), sigma=3)
    valleys = argrelmin(smoothed, order=min_distance//2)[0]
    
    if len(valleys) == 0:
        return []
    
    valley_scores = []
    for v in valleys:
        depth = smoothed[v]
        valley_scores.append((v, depth))
    
    valley_scores.sort(key=lambda x: x[1])
    return [v[0] for v in valley_scores]

def extract_frames_by_valleys(img, num_frames=6):
    """Extrae frames usando detección de valles en la densidad de píxeles."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    arr = np.array(img)
    alpha = arr[:, :, 3]
    
    density_profile = np.sum(alpha > 10, axis=0)
    
    valleys = find_valleys_in_density(density_profile, min_distance=50)
    
    width = img.width
    
    if len(valleys) >= num_frames - 1:
        boundaries = [0] + sorted(valleys[:num_frames-1]) + [width]
    else:
        frame_width = width // num_frames
        boundaries = [i * frame_width for i in range(num_frames + 1)]
        boundaries[-1] = width
    
    frames = []
    for i in range(len(boundaries) - 1):
        left = boundaries[i]
        right = boundaries[i + 1]
        frame = img.crop((left, 0, right, img.height))
        frames.append(frame)
    
    return frames[:num_frames]

def center_content_in_frame(frame, target_size=64, max_content=54):
    """Centra el contenido en un frame de tamaño fijo."""
    if frame.mode != 'RGBA':
        frame = frame.convert('RGBA')
    
    arr = np.array(frame)
    alpha = arr[:, :, 3]
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    content = frame.crop((x_min, y_min, x_max + 1, y_max + 1))
    
    content_w, content_h = content.size
    scale = min(max_content / content_w, max_content / content_h, 1.0)
    
    if scale < 1.0:
        new_w = int(content_w * scale)
        new_h = int(content_h * scale)
        content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    paste_x = (target_size - content.width) // 2
    paste_y = (target_size - content.height) // 2
    
    result.paste(content, (paste_x, paste_y), content)
    
    return result

def create_spritesheet(frames, frame_size=64):
    """Crea un spritesheet horizontal a partir de los frames."""
    num_frames = len(frames)
    spritesheet = Image.new('RGBA', (frame_size * num_frames, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        centered = center_content_in_frame(frame, frame_size, max_content=54)
        spritesheet.paste(centered, (i * frame_size, 0))
    
    return spritesheet

def process_sprite(input_path, output_path, num_frames=6):
    """Procesa un sprite y genera el spritesheet."""
    print(f"Procesando: {input_path}")
    
    img = Image.open(input_path).convert('RGBA')
    print(f"  Tamaño original: {img.size}")
    
    # Contar píxeles opacos
    arr = np.array(img)
    opaque_pixels = np.sum(arr[:, :, 3] > 10)
    print(f"  Píxeles opacos: {opaque_pixels}")
    
    frames = extract_frames_by_valleys(img, num_frames)
    print(f"  Frames extraídos: {len(frames)}")
    
    spritesheet = create_spritesheet(frames)
    print(f"  Spritesheet: {spritesheet.size}")
    
    spritesheet.save(output_path)
    print(f"  Guardado: {output_path}")
    
    return spritesheet

def main():
    base_path = r"c:\git\spellloop\project\assets\sprites\projectiles\fusion\stone_fang"
    
    flight_input = os.path.join(base_path, "flight.png")
    flight_output = os.path.join(base_path, "flight_spritesheet_stone_fang.png")
    
    impact_input = os.path.join(base_path, "impact.png")
    impact_output = os.path.join(base_path, "impact_spritesheet_stone_fang.png")
    
    print("=" * 60)
    print("PROCESANDO STONE FANG (Shadow + Earth)")
    print("Colmillo de Piedra - Obsidian Fang")
    print("=" * 60)
    
    if os.path.exists(flight_input):
        process_sprite(flight_input, flight_output, num_frames=6)
    else:
        print(f"No encontrado: {flight_input}")
    
    print()
    
    if os.path.exists(impact_input):
        process_sprite(impact_input, impact_output, num_frames=6)
    else:
        print(f"No encontrado: {impact_input}")
    
    print()
    print("=" * 60)
    print("¡Stone Fang procesado!")
    print("=" * 60)

if __name__ == "__main__":
    main()
