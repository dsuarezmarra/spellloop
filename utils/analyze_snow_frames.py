#!/usr/bin/env python3
"""
analyze_snow_frames.py
Analiza frames individuales para detectar problemas de alineación.
"""

from PIL import Image, ImageDraw
from pathlib import Path
import numpy as np

def get_content_bbox(img):
    """
    Obtener bounding box del contenido (píxeles no transparentes).
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Convertir a array numpy
    data = np.array(img)
    alpha = data[:, :, 3]
    
    # Encontrar píxeles no transparentes
    non_transparent = alpha > 10  # Threshold para evitar artifacts
    
    if not non_transparent.any():
        return None
    
    # Encontrar límites
    rows = np.any(non_transparent, axis=1)
    cols = np.any(non_transparent, axis=0)
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return (x_min, y_min, x_max + 1, y_max + 1)

def analyze_frames(directory, pattern_start, pattern_end):
    """
    Analizar una secuencia de frames.
    """
    dir_path = Path(directory)
    frames = []
    
    print(f"\n{'='*60}")
    print(f"Analizando frames {pattern_start}-{pattern_end}")
    print(f"{'='*60}\n")
    
    # Cargar frames
    for i in range(pattern_start, pattern_end + 1):
        patterns = [f"{i}.png", f"{i:02d}.png"]
        
        for pattern in patterns:
            file_path = dir_path / pattern
            if file_path.exists():
                img = Image.open(file_path)
                bbox = get_content_bbox(img)
                
                if bbox:
                    width = bbox[2] - bbox[0]
                    height = bbox[3] - bbox[1]
                    center_x = (bbox[0] + bbox[2]) / 2
                    center_y = (bbox[0] + bbox[3]) / 2
                    
                    frames.append({
                        'file': file_path.name,
                        'size': img.size,
                        'bbox': bbox,
                        'content_size': (width, height),
                        'center': (center_x, center_y)
                    })
                    
                    print(f"Frame {file_path.name}:")
                    print(f"  Tamaño imagen: {img.size}")
                    print(f"  BBox contenido: {bbox}")
                    print(f"  Tamaño contenido: {width}×{height}px")
                    print(f"  Centro: ({center_x:.1f}, {center_y:.1f})")
                else:
                    print(f"⚠️ Frame {file_path.name}: Sin contenido visible")
                
                break
    
    if not frames:
        print("❌ No se encontraron frames")
        return
    
    # Análisis de consistencia
    print(f"\n{'─'*60}")
    print("ANÁLISIS DE CONSISTENCIA")
    print(f"{'─'*60}\n")
    
    # Verificar tamaños de imagen
    sizes = [f['size'] for f in frames]
    if len(set(sizes)) > 1:
        print("⚠️ PROBLEMA: Tamaños de imagen inconsistentes:")
        for i, f in enumerate(frames):
            print(f"  Frame {i+1}: {f['size']}")
    else:
        print(f"✅ Tamaños de imagen consistentes: {sizes[0]}")
    
    # Verificar tamaños de contenido
    content_sizes = [f['content_size'] for f in frames]
    widths = [s[0] for s in content_sizes]
    heights = [s[1] for s in content_sizes]
    
    width_variance = max(widths) - min(widths)
    height_variance = max(heights) - min(heights)
    
    print(f"\nVariación en tamaño de contenido:")
    print(f"  Ancho: {min(widths)}px - {max(widths)}px (variación: {width_variance}px)")
    print(f"  Alto: {min(heights)}px - {max(heights)}px (variación: {height_variance}px)")
    
    if width_variance > 10 or height_variance > 10:
        print("  ⚠️ PROBLEMA: Variación excesiva en tamaño de contenido")
        print("  Esto causará que el objeto parezca crecer/decrecer en la animación")
    
    # Verificar centros
    centers = [f['center'] for f in frames]
    center_xs = [c[0] for c in centers]
    center_ys = [c[1] for c in centers]
    
    center_x_variance = max(center_xs) - min(center_xs)
    center_y_variance = max(center_ys) - min(center_ys)
    
    print(f"\nVariación en posición del centro:")
    print(f"  X: {min(center_xs):.1f} - {max(center_xs):.1f} (variación: {center_x_variance:.1f}px)")
    print(f"  Y: {min(center_ys):.1f} - {max(center_ys):.1f} (variación: {center_y_variance:.1f}px)")
    
    if center_x_variance > 5 or center_y_variance > 5:
        print("  ⚠️ PROBLEMA: Objeto se mueve entre frames")
        print("  Esto causará 'drift' en la animación")
    
    print(f"\n{'='*60}\n")

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("USO: python analyze_snow_frames.py <directorio>")
        sys.exit(1)
    
    directory = sys.argv[1]
    
    # Analizar todos los grupos de decor de Snow
    groups = [
        (1, 8, "Decor 1"),
        (1, 8, "Decor 2"),
        (11, 18, "Decor 3"),
        (21, 28, "Decor 4"),
        (31, 38, "Decor 5"),
        (41, 48, "Decor 6"),
        (51, 58, "Decor 7"),
        (61, 68, "Decor 8"),
        (71, 78, "Decor 9"),
        (81, 88, "Decor 10"),
    ]
    
    for start, end, name in groups:
        analyze_frames(directory, start, end)

if __name__ == "__main__":
    main()
