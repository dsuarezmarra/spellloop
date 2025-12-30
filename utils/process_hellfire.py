#!/usr/bin/env python3
"""
Procesa los sprites de Hellfire (Fire + Shadow) para el juego.
Usa detección de valles para encontrar los límites óptimos entre frames.
"""

from PIL import Image
import numpy as np
from scipy.ndimage import gaussian_filter1d
from scipy.signal import argrelmin
import os

def analyze_density(img_array, axis=1):
    """Analiza la densidad de píxeles no transparentes a lo largo de un eje."""
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        alpha = np.any(img_array[:, :, :3] > 0, axis=2).astype(float) * 255
    
    density = np.sum(alpha > 10, axis=0 if axis == 1 else 1)
    return density.astype(float)

def find_valleys(density, num_frames=6, smoothing=5):
    """Encuentra los valles en la densidad para separar frames."""
    smoothed = gaussian_filter1d(density, smoothing)
    
    # Encontrar mínimos locales
    minima_indices = argrelmin(smoothed, order=10)[0]
    
    if len(minima_indices) == 0:
        # Si no hay mínimos, usar división uniforme
        width = len(density)
        return [int(i * width / num_frames) for i in range(num_frames + 1)]
    
    # Filtrar y seleccionar los mejores valles
    width = len(density)
    expected_spacing = width / num_frames
    
    boundaries = [0]
    
    for i in range(1, num_frames):
        expected_pos = i * expected_spacing
        
        # Buscar el valle más cercano a la posición esperada
        best_valley = None
        best_score = float('inf')
        
        for valley in minima_indices:
            distance = abs(valley - expected_pos)
            depth = smoothed[valley]
            
            # Score combinando distancia y profundidad del valle
            score = distance + depth * 0.5
            
            if score < best_score and valley > boundaries[-1] + expected_spacing * 0.5:
                best_score = score
                best_valley = valley
        
        if best_valley is not None:
            boundaries.append(best_valley)
        else:
            boundaries.append(int(expected_pos))
    
    boundaries.append(width)
    return boundaries

def extract_frames_smart(img, num_frames=6):
    """Extrae frames usando detección inteligente de valles."""
    img_array = np.array(img)
    density = analyze_density(img_array)
    
    boundaries = find_valleys(density, num_frames)
    
    frames = []
    for i in range(len(boundaries) - 1):
        left = boundaries[i]
        right = boundaries[i + 1]
        frame = img.crop((left, 0, right, img.height))
        frames.append(frame)
    
    # Asegurar exactamente num_frames
    while len(frames) < num_frames:
        frames.append(frames[-1].copy())
    
    return frames[:num_frames]

def get_content_bbox(img):
    """Obtiene el bounding box del contenido no transparente."""
    img_array = np.array(img)
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        return img.getbbox()
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return None
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return (x_min, y_min, x_max + 1, y_max + 1)

def center_in_frame(content_img, frame_size=64, max_content=54):
    """Centra el contenido en un frame de tamaño fijo."""
    bbox = get_content_bbox(content_img)
    
    if bbox is None:
        return Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    
    content = content_img.crop(bbox)
    
    # Escalar si es necesario
    scale = min(max_content / content.width, max_content / content.height, 1.0)
    
    if scale < 1.0:
        new_width = int(content.width * scale)
        new_height = int(content.height * scale)
        content = content.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Crear frame y centrar
    frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
    x = (frame_size - content.width) // 2
    y = (frame_size - content.height) // 2
    frame.paste(content, (x, y), content if content.mode == 'RGBA' else None)
    
    return frame

def create_spritesheet(frames, frame_size=64):
    """Crea un spritesheet horizontal a partir de los frames."""
    width = frame_size * len(frames)
    height = frame_size
    
    spritesheet = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        centered = center_in_frame(frame, frame_size)
        spritesheet.paste(centered, (i * frame_size, 0))
    
    return spritesheet

def process_sprite(input_path, output_path, num_frames=6):
    """Procesa un sprite y genera el spritesheet."""
    print(f"Procesando: {input_path}")
    
    img = Image.open(input_path).convert('RGBA')
    print(f"  Tamaño original: {img.size}")
    
    # Extraer frames
    frames = extract_frames_smart(img, num_frames)
    print(f"  Frames extraídos: {len(frames)}")
    
    # Crear spritesheet
    spritesheet = create_spritesheet(frames)
    print(f"  Spritesheet: {spritesheet.size}")
    
    # Guardar
    spritesheet.save(output_path)
    print(f"  Guardado: {output_path}")
    
    return spritesheet

def main():
    base_dir = r"c:\git\spellloop\project\assets\sprites\projectiles\fusion\hellfire"
    
    sprites_to_process = [
        ("flight.png", "flight_spritesheet_hellfire.png"),
        ("impact.png", "impact_spritesheet_hellfire.png"),
    ]
    
    for input_name, output_name in sprites_to_process:
        input_path = os.path.join(base_dir, input_name)
        output_path = os.path.join(base_dir, output_name)
        
        if os.path.exists(input_path):
            process_sprite(input_path, output_path)
        else:
            print(f"No encontrado: {input_path}")
    
    print("\n✅ Procesamiento completado!")
    print(f"   Directorio: {base_dir}")

if __name__ == "__main__":
    main()
