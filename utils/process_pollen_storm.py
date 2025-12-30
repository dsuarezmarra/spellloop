#!/usr/bin/env python3
"""
Procesador de sprites para Pollen Storm (Nature + Wind).
Maneja estructuras irregulares de AI dividiendo bloques grandes.
"""

from PIL import Image
import numpy as np
from scipy import ndimage
import os

# Configuración
TARGET_FRAMES = 6
FRAME_SIZE = 64
CONTENT_MAX = 54
PADDING = 5
OUTPUT_SIZE = (TARGET_FRAMES * FRAME_SIZE, FRAME_SIZE)  # 384x64

def find_content_blocks(img_array, threshold=10):
    """Encuentra bloques de contenido separados por columnas vacías."""
    alpha = img_array[:, :, 3]
    col_has_content = np.any(alpha > threshold, axis=0)
    
    blocks = []
    in_block = False
    start = 0
    
    for i, has in enumerate(col_has_content):
        if has and not in_block:
            in_block = True
            start = i
        elif not has and in_block:
            in_block = False
            blocks.append((start, i - 1))
    
    if in_block:
        blocks.append((start, len(col_has_content) - 1))
    
    return blocks

def find_vertical_bounds(img_array, x_start, x_end, threshold=10):
    """Encuentra los límites verticales del contenido en una región."""
    alpha = img_array[:, x_start:x_end+1, 3]
    row_has_content = np.any(alpha > threshold, axis=1)
    
    y_indices = np.where(row_has_content)[0]
    if len(y_indices) == 0:
        return 0, img_array.shape[0] - 1
    
    return y_indices[0], y_indices[-1]

def find_valley_split_point(img_array, x_start, x_end, threshold=10):
    """Encuentra el mejor punto para dividir un bloque grande usando análisis de valles."""
    alpha = img_array[:, x_start:x_end+1, 3]
    col_density = np.sum(alpha > threshold, axis=0)
    
    # Buscar el valle más profundo en el tercio central
    width = len(col_density)
    search_start = width // 4
    search_end = 3 * width // 4
    
    if search_end <= search_start:
        return x_start + width // 2
    
    min_density = float('inf')
    split_point = width // 2
    
    for i in range(search_start, search_end):
        # Buscar mínimos locales con ventana suavizada
        window_size = 5
        start_w = max(0, i - window_size // 2)
        end_w = min(width, i + window_size // 2 + 1)
        avg_density = np.mean(col_density[start_w:end_w])
        
        if avg_density < min_density:
            min_density = avg_density
            split_point = i
    
    return x_start + split_point

def split_large_block(img_array, block, num_parts, threshold=10):
    """Divide un bloque grande en partes más pequeñas."""
    x_start, x_end = block
    splits = []
    
    current_start = x_start
    remaining_parts = num_parts
    
    for i in range(num_parts - 1):
        # Calcular el ancho esperado para las partes restantes
        remaining_width = x_end - current_start + 1
        expected_part_width = remaining_width // remaining_parts
        
        # Buscar punto de división cerca de la posición esperada
        search_center = current_start + expected_part_width
        search_range = expected_part_width // 3
        
        best_split = search_center
        min_density = float('inf')
        
        alpha = img_array[:, :, 3]
        
        for pos in range(search_center - search_range, search_center + search_range + 1):
            if pos <= current_start + 20 or pos >= x_end - 20:
                continue
            
            window_size = 5
            start_w = max(current_start, pos - window_size // 2)
            end_w = min(x_end + 1, pos + window_size // 2 + 1)
            col_density = np.sum(alpha[:, start_w:end_w] > threshold)
            
            if col_density < min_density:
                min_density = col_density
                best_split = pos
        
        splits.append((current_start, best_split - 1))
        current_start = best_split
        remaining_parts -= 1
    
    # Última parte
    splits.append((current_start, x_end))
    
    return splits

def extract_and_center_frame(img_array, x_start, x_end):
    """Extrae un frame y lo centra en 64x64."""
    y_start, y_end = find_vertical_bounds(img_array, x_start, x_end)
    
    # Extraer región
    region = img_array[y_start:y_end+1, x_start:x_end+1].copy()
    
    # Calcular escala
    h, w = region.shape[:2]
    scale = min(CONTENT_MAX / w, CONTENT_MAX / h) if max(w, h) > 0 else 1
    
    if scale < 1:
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        region_img = Image.fromarray(region)
        region_img = region_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        region = np.array(region_img)
    
    # Crear frame 64x64 y centrar
    frame = np.zeros((FRAME_SIZE, FRAME_SIZE, 4), dtype=np.uint8)
    
    h, w = region.shape[:2]
    x_offset = (FRAME_SIZE - w) // 2
    y_offset = (FRAME_SIZE - h) // 2
    
    frame[y_offset:y_offset+h, x_offset:x_offset+w] = region
    
    return frame

def process_sprite(input_path, output_path, sprite_type):
    """Procesa un sprite y genera el spritesheet."""
    print(f"\n{'='*50}")
    print(f"Procesando {sprite_type}: {os.path.basename(input_path)}")
    print(f"{'='*50}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    arr = np.array(img)
    
    print(f"Tamaño original: {img.size}")
    print(f"Píxeles opacos: {np.sum(arr[:,:,3] > 10)}")
    
    # Encontrar bloques
    blocks = find_content_blocks(arr)
    print(f"Bloques encontrados: {len(blocks)}")
    
    for i, (s, e) in enumerate(blocks):
        pixels = np.sum(arr[:, s:e+1, 3] > 10)
        print(f"  Bloque {i+1}: x={s}-{e} (ancho={e-s+1}px, {pixels}px)")
    
    # Determinar frames finales
    frames_data = []
    
    if len(blocks) < TARGET_FRAMES:
        # Necesitamos dividir algunos bloques
        total_needed = TARGET_FRAMES
        blocks_to_process = list(blocks)
        
        while len(frames_data) + len(blocks_to_process) < total_needed and blocks_to_process:
            # Encontrar el bloque más grande
            widths = [(e - s + 1, i) for i, (s, e) in enumerate(blocks_to_process)]
            widths.sort(reverse=True)
            
            largest_idx = widths[0][1]
            largest_block = blocks_to_process[largest_idx]
            
            # ¿Cuántas partes necesitamos?
            remaining_needed = total_needed - len(frames_data) - len(blocks_to_process) + 1
            parts_to_split = min(remaining_needed + 1, 3)  # Máximo dividir en 3
            
            if parts_to_split > 1:
                print(f"\nDividiendo bloque {largest_idx+1} en {parts_to_split} partes...")
                sub_blocks = split_large_block(arr, largest_block, parts_to_split)
                
                # Reemplazar el bloque grande con los sub-bloques
                blocks_to_process = blocks_to_process[:largest_idx] + sub_blocks + blocks_to_process[largest_idx+1:]
            else:
                break
        
        # Ahora extraer frames
        for block in blocks_to_process:
            frames_data.append(block)
    else:
        # Tenemos suficientes bloques, filtrar los pequeños si hay más de 6
        if len(blocks) > TARGET_FRAMES:
            # Ordenar por contenido de píxeles y tomar los 6 con más contenido
            block_pixels = []
            for i, (s, e) in enumerate(blocks):
                pixels = np.sum(arr[:, s:e+1, 3] > 10)
                block_pixels.append((pixels, i, (s, e)))
            
            block_pixels.sort(reverse=True)
            selected = [bp[2] for bp in block_pixels[:TARGET_FRAMES]]
            # Reordenar por posición X
            selected.sort(key=lambda b: b[0])
            frames_data = selected
        else:
            frames_data = list(blocks)
    
    # Si aún no tenemos suficientes frames, duplicar el último
    while len(frames_data) < TARGET_FRAMES:
        frames_data.append(frames_data[-1])
    
    # Limitar a 6 frames
    frames_data = frames_data[:TARGET_FRAMES]
    
    print(f"\nFrames finales: {len(frames_data)}")
    for i, (s, e) in enumerate(frames_data):
        print(f"  Frame {i+1}: x={s}-{e} (ancho={e-s+1}px)")
    
    # Crear spritesheet
    output = Image.new('RGBA', OUTPUT_SIZE, (0, 0, 0, 0))
    
    for i, (x_start, x_end) in enumerate(frames_data):
        frame = extract_and_center_frame(arr, x_start, x_end)
        frame_img = Image.fromarray(frame)
        output.paste(frame_img, (i * FRAME_SIZE, 0))
        
        pixels = np.sum(frame[:, :, 3] > 10)
        print(f"  Frame {i+1} extraído: {pixels} píxeles opacos")
    
    # Guardar
    output.save(output_path)
    print(f"\n✓ Guardado: {output_path}")
    print(f"  Tamaño: {output.size}")
    
    return True

def main():
    base_dir = r"c:\git\spellloop\project\assets\sprites\projectiles\fusion\pollen_storm"
    
    # Procesar flight
    flight_input = os.path.join(base_dir, "flight.png")
    flight_output = os.path.join(base_dir, "flight_spritesheet_pollen_storm.png")
    
    if os.path.exists(flight_input):
        process_sprite(flight_input, flight_output, "flight")
    
    # Procesar impact
    impact_input = os.path.join(base_dir, "impact.png")
    impact_output = os.path.join(base_dir, "impact_spritesheet_pollen_storm.png")
    
    if os.path.exists(impact_input):
        process_sprite(impact_input, impact_output, "impact")
    
    print("\n" + "="*50)
    print("¡Procesamiento completo!")
    print("="*50)

if __name__ == "__main__":
    main()
