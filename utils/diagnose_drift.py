"""
Script de diagnóstico visual para detectar drift en spritesheets.
Genera una imagen que superpone todos los frames para visualizar el desplazamiento.
"""

from PIL import Image, ImageDraw
import numpy as np
import os

def create_overlay_visualization(input_path, output_path):
    """
    Crea una visualización que superpone todos los frames con diferentes colores
    para mostrar el drift.
    """
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size
    
    num_frames = 8
    frame_width = width // num_frames
    frame_height = height
    
    # Extraer frames
    frames = []
    for i in range(num_frames):
        x_start = i * frame_width
        frame = img.crop((x_start, 0, x_start + frame_width, frame_height))
        frames.append(np.array(frame))
    
    # Crear imagen de comparación: todos los frames superpuestos
    overlay = np.zeros((frame_height, frame_width, 4), dtype=np.float32)
    
    for i, frame in enumerate(frames):
        # Añadir este frame al overlay
        mask = frame[:, :, 3] > 0
        overlay[:, :, 3] += mask.astype(np.float32) * 32  # Acumular alpha
        
        # Colorear según el frame
        color = [
            int((i * 37) % 256),  # R
            int((i * 71 + 100) % 256),  # G
            int((i * 113 + 50) % 256),  # B
        ]
        for c in range(3):
            overlay[:, :, c] += mask.astype(np.float32) * color[c] / num_frames
    
    # Normalizar
    overlay = np.clip(overlay, 0, 255).astype(np.uint8)
    
    # Crear imagen de salida mostrando frames individuales + overlay
    output_width = frame_width * (num_frames + 1)  # +1 para el overlay
    output_img = Image.new('RGBA', (output_width, frame_height * 2), (40, 40, 40, 255))
    
    # Primera fila: frames individuales
    for i, frame_arr in enumerate(frames):
        frame_img = Image.fromarray(frame_arr)
        output_img.paste(frame_img, (i * frame_width, 0))
    
    # Overlay al final de la primera fila
    overlay_img = Image.fromarray(overlay)
    output_img.paste(overlay_img, (num_frames * frame_width, 0))
    
    # Segunda fila: comparación frame 0 vs cada frame
    ref_frame = frames[0]
    for i in range(num_frames):
        comparison = np.zeros((frame_height, frame_width, 4), dtype=np.uint8)
        
        # Frame de referencia en rojo
        ref_mask = ref_frame[:, :, 3] > 0
        comparison[ref_mask, 0] = 255
        comparison[ref_mask, 3] = 128
        
        # Frame actual en verde
        curr_mask = frames[i][:, :, 3] > 0
        comparison[curr_mask, 1] = 255
        comparison[curr_mask, 3] = np.maximum(comparison[curr_mask, 3], 128)
        
        # Intersección en amarillo
        both_mask = ref_mask & curr_mask
        comparison[both_mask, 0] = 255
        comparison[both_mask, 1] = 255
        comparison[both_mask, 2] = 0
        comparison[both_mask, 3] = 200
        
        comp_img = Image.fromarray(comparison)
        output_img.paste(comp_img, (i * frame_width, frame_height))
    
    # Añadir líneas de referencia
    draw = ImageDraw.Draw(output_img)
    center_x = frame_width // 2
    
    # Líneas verticales centrales
    for i in range(num_frames + 1):
        x = i * frame_width + center_x
        draw.line([(x, 0), (x, frame_height)], fill=(255, 0, 0, 100), width=1)
        draw.line([(x, frame_height), (x, frame_height * 2)], fill=(255, 0, 0, 100), width=1)
    
    output_img.save(output_path)
    print(f"Diagnóstico guardado: {output_path}")

def analyze_frame_differences(input_path):
    """
    Analiza las diferencias detalladas entre frames.
    """
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size
    
    num_frames = 8
    frame_width = width // num_frames
    
    print(f"\n{'='*60}")
    print(f"ANÁLISIS DETALLADO: {os.path.basename(input_path)}")
    print(f"{'='*60}")
    
    frames = []
    for i in range(num_frames):
        x_start = i * frame_width
        frame = np.array(img.crop((x_start, 0, x_start + frame_width, height)))
        frames.append(frame)
    
    # Analizar cada frame
    print(f"\n{'Frame':<8} {'BBox X':<12} {'BBox Y':<12} {'Width':<8} {'Height':<8} {'Centroid':<16}")
    print("-" * 70)
    
    ref_centroid_x = None
    
    for i, frame in enumerate(frames):
        alpha = frame[:, :, 3]
        rows = np.any(alpha > 0, axis=1)
        cols = np.any(alpha > 0, axis=0)
        
        if rows.any() and cols.any():
            y_min, y_max = np.where(rows)[0][[0, -1]]
            x_min, x_max = np.where(cols)[0][[0, -1]]
            
            # Centroide
            y_idx, x_idx = np.meshgrid(np.arange(height), np.arange(frame_width), indexing='ij')
            total_alpha = alpha.sum()
            if total_alpha > 0:
                cx = (x_idx * alpha).sum() / total_alpha
                cy = (y_idx * alpha).sum() / total_alpha
            else:
                cx, cy = frame_width/2, height/2
            
            bbox_center_x = (x_min + x_max) / 2
            content_width = x_max - x_min + 1
            content_height = y_max - y_min + 1
            
            if ref_centroid_x is None:
                ref_centroid_x = cx
            
            drift = cx - ref_centroid_x
            drift_str = f"drift: {drift:+.1f}px" if abs(drift) > 0.5 else ""
            
            print(f"{i:<8} {x_min}-{x_max:<8} {y_min}-{y_max:<8} {content_width:<8} {content_height:<8} ({cx:.1f}, {cy:.1f}) {drift_str}")
        else:
            print(f"{i:<8} VACÍO")

def main():
    files = [
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor\death_decor1_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor\death_decor2_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Death\decor\death_decor3_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor\desert_decor1_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor\desert_decor2_sheet_f8_256.png",
        r"C:\git\spellloop\project\assets\textures\biomes\Desert\decor\desert_decor3_sheet_f8_256.png",
    ]
    
    output_dir = r"C:\git\spellloop\utils\drift_diagnosis"
    os.makedirs(output_dir, exist_ok=True)
    
    for filepath in files:
        if os.path.exists(filepath):
            analyze_frame_differences(filepath)
            
            basename = os.path.basename(filepath).replace('.png', '_diagnosis.png')
            output_path = os.path.join(output_dir, basename)
            create_overlay_visualization(filepath, output_path)

if __name__ == "__main__":
    main()
