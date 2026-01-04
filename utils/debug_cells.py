#!/usr/bin/env python3
"""Debug: guarda cada celda para ver qué hay"""

from PIL import Image
import numpy as np
from pathlib import Path

def debug_1x6(path, name):
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    
    print(f'=== {name} ({w}x{h}) ===')
    
    # Crear directorio debug
    debug_dir = Path(path).parent / "debug_cells"
    debug_dir.mkdir(exist_ok=True)
    
    # 1 fila, 6 columnas
    cols = 6
    cell_w = w // cols
    
    print(f'Dividiendo en {cols} columnas de {cell_w}px cada una')
    
    for col in range(cols):
        x1 = col * cell_w
        x2 = (col + 1) * cell_w if col < cols - 1 else w
        
        # Guardar celda cruda
        cell = img.crop((x1, 0, x2, h))
        cell.save(debug_dir / f"cell_{col+1}_raw.png")
        
        # Analizar contenido
        cell_arr = np.array(cell)
        cell_alpha = cell_arr[:,:,3]
        
        rows_with = np.any(cell_alpha > 10, axis=1)
        cols_with = np.any(cell_alpha > 10, axis=0)
        
        if np.any(rows_with) and np.any(cols_with):
            cy1, cy2 = np.where(rows_with)[0][[0,-1]]
            cx1, cx2 = np.where(cols_with)[0][[0,-1]]
            content = cell.crop((cx1, cy1, cx2+1, cy2+1))
            content.save(debug_dir / f"cell_{col+1}_content.png")
            print(f'  Celda {col+1}: x={x1}-{x2}, contenido {content.size[0]}x{content.size[1]} en ({cx1},{cy1})-({cx2},{cy2})')
        else:
            print(f'  Celda {col+1}: x={x1}-{x2}, SIN CONTENIDO')
    
    print(f'Celdas guardadas en: {debug_dir}')

sources = [
    (r'C:\git\spellloop\project\assets\sprites\projectiles\weapons\void_pulse\unnamed-removebg-preview.png', 'void_pulse'),
    (r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\seismic_bolt\unnamed-removebg-preview.png', 'seismic_bolt'),
    (r'C:\git\spellloop\project\assets\sprites\projectiles\fusion\glacier\unnamed-removebg-preview.png', 'glacier'),
]

for path, name in sources:
    debug_1x6(path, name)
    print()
