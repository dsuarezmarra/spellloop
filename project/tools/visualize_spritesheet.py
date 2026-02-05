#!/usr/bin/env python3
"""
Visualizador de Spritesheets - Genera imagen de análisis con bounding boxes
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def visualize_spritesheet(filepath, output_suffix="_analysis"):
    """Genera una imagen de análisis mostrando los frames detectados."""
    img = Image.open(filepath)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    # Crear copia para dibujar
    vis = img.copy()
    draw = ImageDraw.Draw(vis)
    
    width, height = img.size
    data = np.array(img)
    alpha = data[:, :, 3]
    
    # Para cada posible grid, detectar contenido
    print(f"\nAnalizando: {Path(filepath).name}")
    print(f"Dimensiones: {width}x{height}")
    
    # Probar grid 4x2
    cols, rows = 4, 2
    cell_w = width / cols
    cell_h = height / rows
    
    print(f"\nProbando grid {cols}x{rows} (celdas de {cell_w:.1f}x{cell_h:.1f}):")
    
    colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0),
              (255, 0, 255), (0, 255, 255), (255, 128, 0), (128, 0, 255)]
    
    frame_info = []
    
    for row in range(rows):
        for col in range(cols):
            idx = row * cols + col
            color = colors[idx % len(colors)]
            
            x1 = int(col * cell_w)
            y1 = int(row * cell_h)
            x2 = int((col + 1) * cell_w)
            y2 = int((row + 1) * cell_h)
            
            # Dibujar borde de celda
            draw.rectangle([x1, y1, x2, y2], outline=color, width=2)
            
            # Analizar contenido de la celda
            cell_alpha = alpha[y1:y2, x1:x2]
            
            if np.any(cell_alpha > 10):
                rows_with_content = np.any(cell_alpha > 10, axis=1)
                cols_with_content = np.any(cell_alpha > 10, axis=0)
                
                r_indices = np.where(rows_with_content)[0]
                c_indices = np.where(cols_with_content)[0]
                
                if len(r_indices) > 0 and len(c_indices) > 0:
                    content_x1 = x1 + c_indices[0]
                    content_y1 = y1 + r_indices[0]
                    content_x2 = x1 + c_indices[-1] + 1
                    content_y2 = y1 + r_indices[-1] + 1
                    
                    content_w = content_x2 - content_x1
                    content_h = content_y2 - content_y1
                    
                    # Dibujar bounding box del contenido
                    draw.rectangle([content_x1, content_y1, content_x2, content_y2], 
                                 outline=(255, 255, 255), width=1)
                    
                    # Centro de masas
                    y_coords, x_coords = np.where(cell_alpha > 10)
                    center_x = x1 + np.mean(x_coords)
                    center_y = y1 + np.mean(y_coords)
                    
                    # Dibujar centro
                    draw.ellipse([center_x-3, center_y-3, center_x+3, center_y+3], 
                               fill=(255, 255, 255))
                    
                    # Etiqueta
                    draw.text((x1 + 5, y1 + 5), f"F{idx+1}", fill=color)
                    
                    frame_info.append({
                        'idx': idx + 1,
                        'cell': (x1, y1, x2-x1, y2-y1),
                        'content': (content_x1, content_y1, content_w, content_h),
                        'center': (center_x, center_y)
                    })
                    
                    print(f"  Frame {idx+1}: celda ({x1},{y1}) {int(cell_w)}x{int(cell_h)} -> contenido {content_w}x{content_h}")
    
    # Guardar visualización
    output_path = filepath.replace(".png", f"{output_suffix}.png")
    vis.save(output_path)
    print(f"\nVisualización guardada: {output_path}")
    
    return frame_info


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python visualize_spritesheet.py <ruta_imagen>")
        sys.exit(1)
    
    visualize_spritesheet(sys.argv[1])
