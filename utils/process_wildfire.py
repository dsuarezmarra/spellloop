#!/usr/bin/env python3
"""
Procesador de sprites de Wildfire
Detecta frames automáticamente usando análisis de densidad y genera spritesheets 384x64
"""

import numpy as np
from PIL import Image
from pathlib import Path
from scipy.ndimage import gaussian_filter1d
from scipy.signal import argrelmin

def analyze_image(img_path: Path) -> tuple:
    """Analizar imagen y mostrar información"""
    img = Image.open(img_path).convert('RGBA')
    arr = np.array(img)
    alpha = arr[:, :, 3]
    
    print(f"\n{'='*60}")
    print(f"Analizando: {img_path.name}")
    print(f"Tamaño: {img.size}")
    print(f"Píxeles con contenido: {np.sum(alpha > 10)}")
    
    return img, arr, alpha

def find_frame_boundaries_by_density(alpha: np.ndarray, num_frames: int = 6) -> list:
    """
    Encontrar los límites de los frames usando análisis de densidad vertical.
    Busca los 'valles' (zonas con menos contenido) para separar frames.
    """
    # Calcular densidad horizontal (suma de alpha por columna)
    density = np.sum(alpha > 10, axis=0).astype(float)
    
    # Suavizar para evitar ruido
    density_smooth = gaussian_filter1d(density, sigma=5)
    
    # Encontrar mínimos locales (valles)
    minima_indices = argrelmin(density_smooth, order=20)[0]
    
    # Filtrar mínimos que realmente son valles significativos
    mean_density = np.mean(density_smooth)
    significant_minima = [i for i in minima_indices if density_smooth[i] < mean_density * 0.5]
    
    print(f"Mínimos encontrados: {len(minima_indices)}")
    print(f"Mínimos significativos: {len(significant_minima)}")
    
    # Si encontramos suficientes valles, usarlos como separadores
    if len(significant_minima) >= num_frames - 1:
        # Tomar los num_frames-1 valles más profundos y ordenarlos
        valley_depths = [(i, density_smooth[i]) for i in significant_minima]
        valley_depths.sort(key=lambda x: x[1])  # Ordenar por profundidad (menor = más profundo)
        best_valleys = sorted([v[0] for v in valley_depths[:num_frames-1]])
        
        # Crear límites: inicio, valles, fin
        boundaries = [0] + best_valleys + [alpha.shape[1]]
        print(f"Límites por valles: {boundaries}")
        return boundaries
    
    # Fallback: división uniforme
    width = alpha.shape[1]
    frame_width = width // num_frames
    boundaries = [i * frame_width for i in range(num_frames + 1)]
    boundaries[-1] = width
    print(f"Límites uniformes (fallback): {boundaries}")
    return boundaries

def extract_and_resize_frames(img: Image.Image, alpha: np.ndarray, 
                              boundaries: list, target_size: int = 64,
                              content_size: int = 54) -> list:
    """
    Extraer frames según los límites y redimensionar a target_size x target_size
    con contenido de content_size centrado.
    """
    frames = []
    padding = (target_size - content_size) // 2
    
    for i in range(len(boundaries) - 1):
        x1, x2 = boundaries[i], boundaries[i + 1]
        
        # Extraer región del frame
        frame_region = img.crop((x1, 0, x2, img.height))
        frame_alpha = alpha[:, x1:x2]
        
        # Encontrar bounding box del contenido real
        rows = np.any(frame_alpha > 10, axis=1)
        cols = np.any(frame_alpha > 10, axis=0)
        
        if not np.any(rows) or not np.any(cols):
            # Frame vacío, crear frame transparente
            frames.append(Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0)))
            continue
        
        y_min, y_max = np.where(rows)[0][[0, -1]]
        x_min, x_max = np.where(cols)[0][[0, -1]]
        
        # Recortar al contenido
        content = frame_region.crop((x_min, y_min, x_max + 1, y_max + 1))
        
        # Calcular escala para que quepa en content_size
        scale = min(content_size / content.width, content_size / content.height)
        new_width = int(content.width * scale)
        new_height = int(content.height * scale)
        
        # Redimensionar
        content_resized = content.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Crear frame final con padding
        final_frame = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
        
        # Centrar contenido
        paste_x = (target_size - new_width) // 2
        paste_y = (target_size - new_height) // 2
        
        final_frame.paste(content_resized, (paste_x, paste_y))
        frames.append(final_frame)
        
        print(f"  Frame {i+1}: región ({x1}-{x2}), contenido {content.size} -> {new_width}x{new_height}")
    
    return frames

def create_spritesheet(frames: list, output_path: Path) -> None:
    """Crear spritesheet horizontal"""
    if not frames:
        print(f"ERROR: No hay frames para {output_path}")
        return
    
    frame_size = frames[0].size[0]
    sheet_width = frame_size * len(frames)
    sheet_height = frame_size
    
    spritesheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * frame_size, 0))
    
    spritesheet.save(output_path)
    print(f"✓ Guardado: {output_path} ({sheet_width}x{sheet_height})")

def process_wildfire():
    """Procesar sprites de wildfire"""
    base_path = Path("project/assets/sprites/projectiles/fusion/wildfire")
    
    # Procesar flight
    flight_path = base_path / "flight.png"
    if flight_path.exists():
        img, arr, alpha = analyze_image(flight_path)
        boundaries = find_frame_boundaries_by_density(alpha, num_frames=6)
        frames = extract_and_resize_frames(img, alpha, boundaries)
        
        # Backup original y guardar spritesheet procesado
        original_backup = base_path / "flight_original.png"
        if not original_backup.exists():
            img.save(original_backup)
        
        output_path = base_path / "flight.png"
        create_spritesheet(frames, output_path)
    
    # Procesar impact
    impact_path = base_path / "impact.png"
    if impact_path.exists():
        img, arr, alpha = analyze_image(impact_path)
        boundaries = find_frame_boundaries_by_density(alpha, num_frames=6)
        frames = extract_and_resize_frames(img, alpha, boundaries)
        
        # Backup original y guardar spritesheet procesado
        original_backup = base_path / "impact_original.png"
        if not original_backup.exists():
            img.save(original_backup)
        
        output_path = base_path / "impact.png"
        create_spritesheet(frames, output_path)

if __name__ == "__main__":
    import os
    os.chdir(r"C:\git\spellloop")
    process_wildfire()
    print("\n✅ Procesamiento completado!")
