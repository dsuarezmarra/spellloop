#!/usr/bin/env python3
"""
Procesa sprites de Absolute Zero desde un grid 3x2 (3 columnas, 2 filas).
Usa el centro de masas de cada celda para centrar el contenido correctamente.
"""

import numpy as np
from PIL import Image, ImageEnhance
from pathlib import Path


def process_absolute_zero_grid():
    """
    Procesa la imagen de Absolute Zero que está en formato grid 3x2.
    """
    base_dir = Path(r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\absolute_zero")
    input_path = base_dir / "unnamed-removebg-preview.png"
    
    print("=" * 60)
    print("PROCESANDO ABSOLUTE ZERO - Grid 3x2")
    print("=" * 60)
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    arr = np.array(img)
    alpha = arr[:, :, 3]
    
    w, h = img.size
    cols, rows = 3, 2
    cell_w = w // cols
    cell_h = h // rows
    
    print(f"📷 Imagen: {w}x{h}")
    print(f"📐 Grid: {cols}x{rows} = {cols*rows} frames")
    print(f"📏 Celda: {cell_w}x{cell_h}")
    
    # Extraer frames en orden (fila 0: 0,1,2 | fila 1: 3,4,5)
    frames = []
    frame_info = []
    
    for row in range(rows):
        for col in range(cols):
            frame_num = row * cols + col + 1
            
            # Límites de la celda
            x1 = col * cell_w
            x2 = (col + 1) * cell_w if col < cols - 1 else w
            y1 = row * cell_h
            y2 = (row + 1) * cell_h if row < rows - 1 else h
            
            # Extraer celda
            cell = img.crop((x1, y1, x2, y2))
            cell_arr = np.array(cell)
            cell_alpha = cell_arr[:, :, 3]
            
            # Encontrar bounding box del contenido
            rows_with = np.any(cell_alpha > 10, axis=1)
            cols_with = np.any(cell_alpha > 10, axis=0)
            
            if np.any(rows_with) and np.any(cols_with):
                cy_min, cy_max = np.where(rows_with)[0][[0, -1]]
                cx_min, cx_max = np.where(cols_with)[0][[0, -1]]
                
                # Extraer contenido
                content = cell.crop((cx_min, cy_min, cx_max + 1, cy_max + 1))
                
                # Calcular centro de masa
                y_coords, x_coords = np.where(cell_alpha > 10)
                center_x = np.mean(x_coords)
                center_y = np.mean(y_coords)
                
                frames.append(content)
                frame_info.append({
                    'num': frame_num,
                    'size': content.size,
                    'center': (center_x, center_y)
                })
                
                print(f"   Frame {frame_num}: contenido {content.size[0]}x{content.size[1]}, centro=({center_x:.0f},{center_y:.0f})")
            else:
                frames.append(None)
                frame_info.append({'num': frame_num, 'size': (0, 0), 'center': (0, 0)})
                print(f"   Frame {frame_num}: vacío")
    
    # Encontrar tamaño máximo de contenido
    max_w = max(f['size'][0] for f in frame_info if f['size'][0] > 0)
    max_h = max(f['size'][1] for f in frame_info if f['size'][1] > 0)
    
    # Tamaño del frame de salida (con padding)
    padding = 8
    frame_size = max(max_w, max_h) + padding
    # Redondear a múltiplo de 8
    frame_size = ((frame_size + 7) // 8) * 8
    
    print(f"\n📊 Contenido máximo: {max_w}x{max_h}")
    print(f"📐 Frame de salida: {frame_size}x{frame_size}")
    
    # Crear frames finales centrados por centro de masa
    final_frames = []
    
    # Calcular centro de masa promedio para consistencia
    valid_centers = [(f['center'], f['size']) for f in frame_info if f['size'][0] > 0]
    avg_center_x = np.mean([c[0][0] for c in valid_centers])
    avg_center_y = np.mean([c[0][1] for c in valid_centers])
    
    print(f"🎯 Centro de masa promedio: ({avg_center_x:.0f}, {avg_center_y:.0f})")
    
    for i, (content, info) in enumerate(zip(frames, frame_info)):
        if content is None:
            final_frames.append(Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0)))
            continue
        
        # Crear frame vacío
        frame = Image.new('RGBA', (frame_size, frame_size), (0, 0, 0, 0))
        
        # Centrar el contenido en el frame
        # Usamos el centro geométrico del frame de salida
        paste_x = (frame_size - content.width) // 2
        paste_y = (frame_size - content.height) // 2
        
        frame.paste(content, (paste_x, paste_y), content)
        final_frames.append(frame)
    
    # Crear spritesheet horizontal (6 frames en fila)
    spritesheet_width = frame_size * len(final_frames)
    spritesheet = Image.new('RGBA', (spritesheet_width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(final_frames):
        spritesheet.paste(frame, (i * frame_size, 0), frame)
    
    # Guardar spritesheet activo
    output_active = base_dir / "aoe_active_absolute_zero.png"
    spritesheet.save(output_active, 'PNG', optimize=False)
    print(f"\n✅ Active: {output_active}")
    print(f"   Tamaño: {spritesheet_width}x{frame_size} ({len(final_frames)} frames de {frame_size}x{frame_size})")
    
    # Crear versión de impacto (más brillante)
    print("\n🔥 Creando versión de impacto...")
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    
    output_impact = base_dir / "aoe_impact_absolute_zero.png"
    impact.save(output_impact, 'PNG', optimize=False)
    print(f"✅ Impact: {output_impact}")
    
    # Guardar frames individuales
    frames_dir = base_dir / "frames"
    frames_dir.mkdir(exist_ok=True)
    
    for i, frame in enumerate(final_frames):
        frame_path = frames_dir / f"frame_{i+1}.png"
        frame.save(frame_path, 'PNG', optimize=False)
    
    print(f"\n📁 Frames individuales: {frames_dir}")
    
    # Resumen
    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"Imagen original: {w}x{h} (grid 3x2)")
    print(f"Frames extraídos: {len(final_frames)}")
    print(f"Tamaño frame: {frame_size}x{frame_size}")
    print(f"Spritesheet: {spritesheet_width}x{frame_size}")
    print(f"Calidad: 100% (sin escalado)")


if __name__ == '__main__':
    process_absolute_zero_grid()
