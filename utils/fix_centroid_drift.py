"""
Script para corregir drift basándose en el centroide del contenido.
Alinea todos los frames para que sus centroides coincidan.
"""

from PIL import Image
import numpy as np
import os
import shutil

def get_centroid(frame_arr):
    """Calcula el centroide ponderado por alpha."""
    alpha = frame_arr[:, :, 3].astype(float)
    
    if alpha.sum() == 0:
        return frame_arr.shape[1] // 2, frame_arr.shape[0] // 2
    
    h, w = alpha.shape
    y_idx, x_idx = np.meshgrid(np.arange(h), np.arange(w), indexing='ij')
    
    total = alpha.sum()
    cx = (x_idx * alpha).sum() / total
    cy = (y_idx * alpha).sum() / total
    
    return cx, cy

def get_bbox(frame_arr):
    """Obtiene el bounding box del contenido."""
    alpha = frame_arr[:, :, 3]
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)
    
    if not rows.any() or not cols.any():
        return 0, 0, frame_arr.shape[1], frame_arr.shape[0]
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return x_min, y_min, x_max + 1, y_max + 1

def shift_frame(frame_arr, dx, dy):
    """Desplaza el contenido del frame."""
    h, w = frame_arr.shape[:2]
    new_frame = np.zeros_like(frame_arr)
    
    dx = int(round(dx))
    dy = int(round(dy))
    
    # Calcular rangos de copia
    src_x1 = max(0, -dx)
    src_x2 = min(w, w - dx)
    src_y1 = max(0, -dy)
    src_y2 = min(h, h - dy)
    
    dst_x1 = max(0, dx)
    dst_x2 = min(w, w + dx)
    dst_y1 = max(0, dy)
    dst_y2 = min(h, h + dy)
    
    # Asegurar que los rangos son válidos
    copy_w = min(src_x2 - src_x1, dst_x2 - dst_x1)
    copy_h = min(src_y2 - src_y1, dst_y2 - dst_y1)
    
    if copy_w > 0 and copy_h > 0:
        new_frame[dst_y1:dst_y1+copy_h, dst_x1:dst_x1+copy_w] = \
            frame_arr[src_y1:src_y1+copy_h, src_x1:src_x1+copy_w]
    
    return new_frame

def fix_spritesheet_drift(input_path, output_path=None, tolerance=1.5):
    """
    Corrige el drift alineando los centroides de todos los frames.
    """
    if output_path is None:
        output_path = input_path
    
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size
    
    num_frames = 8
    frame_width = width // num_frames
    frame_height = height
    
    print(f"\nProcesando: {os.path.basename(input_path)}")
    print(f"  Tamaño: {width}x{height}, {num_frames} frames de {frame_width}x{frame_height}")
    
    # Extraer frames
    frames = []
    centroids = []
    
    for i in range(num_frames):
        x_start = i * frame_width
        frame = np.array(img.crop((x_start, 0, x_start + frame_width, frame_height)))
        frames.append(frame)
        cx, cy = get_centroid(frame)
        centroids.append((cx, cy))
    
    # Calcular centroide promedio (objetivo)
    avg_cx = np.mean([c[0] for c in centroids])
    avg_cy = np.mean([c[1] for c in centroids])
    
    print(f"  Centroide promedio: ({avg_cx:.1f}, {avg_cy:.1f})")
    
    # También considerar la base común
    bases = []
    for frame in frames:
        bbox = get_bbox(frame)
        bases.append(bbox[3])  # y_max
    max_base = max(bases)
    
    # Corregir cada frame
    corrected_frames = []
    corrections = []
    
    for i, (frame, (cx, cy)) in enumerate(zip(frames, centroids)):
        # Calcular desplazamiento necesario para alinear centroide horizontal
        dx = avg_cx - cx
        
        # Para Y, alinear la base en lugar del centroide
        bbox = get_bbox(frame)
        current_base = bbox[3]
        dy = max_base - current_base
        
        if abs(dx) >= tolerance or abs(dy) >= tolerance:
            corrections.append(f"Frame {i}: dx={dx:+.1f}, dy={dy:+.1f}")
            corrected_frame = shift_frame(frame, dx, dy)
        else:
            corrected_frame = frame
        
        corrected_frames.append(Image.fromarray(corrected_frame))
    
    if corrections:
        print(f"  Correcciones aplicadas:")
        for c in corrections:
            print(f"    {c}")
    else:
        print(f"  No se requieren correcciones (drift < {tolerance}px)")
    
    # Reconstruir spritesheet
    new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    for i, frame in enumerate(corrected_frames):
        new_img.paste(frame, (i * frame_width, 0))
    
    new_img.save(output_path)
    print(f"  Guardado: {output_path}")
    
    return len(corrections)

def main():
    # Todos los archivos de decor en Death y Desert
    base_paths = [
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor",
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor",
    ]
    
    print("=" * 70)
    print("CORRECTOR DE DRIFT POR CENTROIDE")
    print("=" * 70)
    
    total_corrections = 0
    files_processed = 0
    
    for base_path in base_paths:
        if not os.path.exists(base_path):
            print(f"\nDirectorio no encontrado: {base_path}")
            continue
        
        for filename in sorted(os.listdir(base_path)):
            if filename.endswith('.png') and '_sheet_' in filename:
                filepath = os.path.join(base_path, filename)
                
                # Crear backup si no existe
                backup_path = filepath + ".backup_centroid"
                if not os.path.exists(backup_path):
                    shutil.copy(filepath, backup_path)
                
                corrections = fix_spritesheet_drift(filepath, tolerance=1.5)
                total_corrections += corrections
                files_processed += 1
    
    print("\n" + "=" * 70)
    print(f"RESUMEN: {files_processed} archivos procesados, {total_corrections} frames corregidos")
    print("=" * 70)

if __name__ == "__main__":
    main()
