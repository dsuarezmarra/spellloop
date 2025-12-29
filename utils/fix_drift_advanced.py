"""
Script avanzado para corregir drift en spritesheets.
Usa el primer frame como referencia y alinea todos los demás frames
basándose en el centro de masa del contenido, no solo el bounding box.
"""

from PIL import Image
import numpy as np
import os
import sys
import shutil

def get_content_centroid(img_array):
    """
    Calcula el centroide (centro de masa) del contenido no transparente.
    Usa pesos basados en el alpha para un centro más preciso.
    """
    if img_array.shape[2] < 4:
        return img_array.shape[1] // 2, img_array.shape[0] // 2
    
    alpha = img_array[:, :, 3].astype(float)
    
    if alpha.sum() == 0:
        return img_array.shape[1] // 2, img_array.shape[0] // 2
    
    # Calcular centro de masa ponderado por alpha
    y_indices, x_indices = np.meshgrid(
        np.arange(img_array.shape[0]),
        np.arange(img_array.shape[1]),
        indexing='ij'
    )
    
    total_weight = alpha.sum()
    center_x = (x_indices * alpha).sum() / total_weight
    center_y = (y_indices * alpha).sum() / total_weight
    
    return center_x, center_y

def get_content_bbox(img_array):
    """Obtiene el bounding box del contenido no transparente."""
    if img_array.shape[2] < 4:
        return 0, 0, img_array.shape[1], img_array.shape[0]
    
    alpha = img_array[:, :, 3]
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)
    
    if not rows.any() or not cols.any():
        return 0, 0, img_array.shape[1], img_array.shape[0]
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return x_min, y_min, x_max + 1, y_max + 1

def get_content_base_center(img_array):
    """
    Obtiene el centro horizontal y la base del contenido.
    Más robusto que solo el centroide.
    """
    bbox = get_content_bbox(img_array)
    x_min, y_min, x_max, y_max = bbox
    
    # Centro horizontal del bounding box
    center_x = (x_min + x_max) / 2
    
    # Base del contenido (parte inferior)
    base_y = y_max
    
    return center_x, base_y

def analyze_frames(frames):
    """Analiza todos los frames y retorna sus características."""
    analysis = []
    for i, frame in enumerate(frames):
        arr = np.array(frame)
        centroid_x, centroid_y = get_content_centroid(arr)
        bbox = get_content_bbox(arr)
        base_center_x, base_y = get_content_base_center(arr)
        
        analysis.append({
            'index': i,
            'centroid_x': centroid_x,
            'centroid_y': centroid_y,
            'bbox': bbox,
            'base_center_x': base_center_x,
            'base_y': base_y,
            'width': bbox[2] - bbox[0],
            'height': bbox[3] - bbox[1]
        })
    
    return analysis

def fix_drift_in_spritesheet(input_path, output_path=None):
    """
    Corrige el drift en un spritesheet alineando todos los frames
    al primer frame de referencia.
    """
    if output_path is None:
        output_path = input_path
    
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size
    
    # Determinar número de frames (asumimos 8 frames horizontales)
    num_frames = 8
    frame_width = width // num_frames
    frame_height = height
    
    print(f"\nProcesando: {os.path.basename(input_path)}")
    print(f"  Dimensiones: {width}x{height}, {num_frames} frames de {frame_width}x{frame_height}")
    
    # Extraer frames
    frames = []
    for i in range(num_frames):
        x_start = i * frame_width
        frame = img.crop((x_start, 0, x_start + frame_width, frame_height))
        frames.append(frame)
    
    # Analizar frames
    analysis = analyze_frames(frames)
    
    # Usar el primer frame como referencia
    ref = analysis[0]
    ref_center_x = ref['base_center_x']
    ref_base_y = ref['base_y']
    
    # El punto de referencia es el centro del frame
    target_center_x = frame_width / 2
    
    # Calcular la base objetivo (la base más alta entre todos los frames)
    max_base_y = max(a['base_y'] for a in analysis)
    
    print(f"  Referencia (frame 0): center_x={ref_center_x:.1f}, base_y={ref_base_y}")
    print(f"  Target center_x: {target_center_x:.1f}, max_base_y: {max_base_y}")
    
    # Crear frames corregidos
    corrected_frames = []
    corrections_made = []
    
    for i, (frame, info) in enumerate(zip(frames, analysis)):
        arr = np.array(frame)
        
        # Calcular offset necesario para alinear con el primer frame
        # Alineamos el centro horizontal y la base
        offset_x = int(round(target_center_x - info['base_center_x']))
        offset_y = int(round(max_base_y - info['base_y']))
        
        # También considerar alinear al primer frame específicamente
        # Offset relativo al primer frame
        relative_offset_x = int(round(ref_center_x - info['base_center_x']))
        
        # Usar el offset relativo para mantener consistencia
        # Pero centrado en el frame
        final_offset_x = offset_x
        final_offset_y = offset_y
        
        if final_offset_x != 0 or final_offset_y != 0:
            corrections_made.append(f"Frame {i}: dx={final_offset_x}, dy={final_offset_y}")
        
        # Crear nuevo frame con el contenido desplazado
        new_arr = np.zeros_like(arr)
        
        # Calcular rangos de copia
        src_x_start = max(0, -final_offset_x)
        src_x_end = min(frame_width, frame_width - final_offset_x)
        src_y_start = max(0, -final_offset_y)
        src_y_end = min(frame_height, frame_height - final_offset_y)
        
        dst_x_start = max(0, final_offset_x)
        dst_x_end = min(frame_width, frame_width + final_offset_x)
        dst_y_start = max(0, final_offset_y)
        dst_y_end = min(frame_height, frame_height + final_offset_y)
        
        # Verificar que los rangos son válidos
        copy_width = min(src_x_end - src_x_start, dst_x_end - dst_x_start)
        copy_height = min(src_y_end - src_y_start, dst_y_end - dst_y_start)
        
        if copy_width > 0 and copy_height > 0:
            new_arr[dst_y_start:dst_y_start+copy_height, 
                    dst_x_start:dst_x_start+copy_width] = \
                arr[src_y_start:src_y_start+copy_height, 
                    src_x_start:src_x_start+copy_width]
        
        corrected_frames.append(Image.fromarray(new_arr))
    
    if corrections_made:
        print(f"  Correcciones realizadas:")
        for c in corrections_made:
            print(f"    {c}")
    else:
        print(f"  No se necesitaron correcciones")
    
    # Reconstruir spritesheet
    new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    for i, frame in enumerate(corrected_frames):
        new_img.paste(frame, (i * frame_width, 0))
    
    # Guardar
    new_img.save(output_path)
    print(f"  Guardado: {output_path}")
    
    return corrections_made

def main():
    # Archivos a procesar (los que tienen drift según las imágenes del usuario)
    files_to_fix = [
        # Death biome
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor\death_decor1_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor\death_decor2_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor\death_decor3_sheet_f8_256.png",
        # Desert biome
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor\desert_decor1_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor\desert_decor2_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor\desert_decor3_sheet_f8_256.png",
    ]
    
    print("=" * 60)
    print("CORRECTOR DE DRIFT AVANZADO PARA SPRITESHEETS")
    print("=" * 60)
    
    total_corrections = 0
    
    for filepath in files_to_fix:
        if os.path.exists(filepath):
            # Crear backup
            backup_path = filepath + ".backup2"
            if not os.path.exists(backup_path):
                shutil.copy(filepath, backup_path)
            
            corrections = fix_drift_in_spritesheet(filepath)
            if corrections:
                total_corrections += len(corrections)
        else:
            print(f"\nArchivo no encontrado: {filepath}")
    
    print("\n" + "=" * 60)
    print(f"TOTAL: {total_corrections} correcciones realizadas")
    print("=" * 60)

if __name__ == "__main__":
    main()
