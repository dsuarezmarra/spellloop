"""
Verificación visual de la alineación de frames.
Extrae frames individuales de los sprite sheets para inspección visual.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import numpy as np

def extract_frames_from_sheet(sheet_path, frame_width, frame_height, num_frames):
    """Extrae frames individuales de un sprite sheet."""
    sheet = Image.open(sheet_path)
    frames = []
    
    for i in range(num_frames):
        x = i * frame_width
        frame = sheet.crop((x, 0, x + frame_width, frame_height))
        frames.append(frame)
    
    return frames

def get_content_bbox(image):
    """Calcula el bounding box del contenido."""
    img_array = np.array(image)
    
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        alpha = np.sum(img_array[:, :, :3], axis=2)
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    if not rows.any() or not cols.any():
        return None
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return (int(x_min), int(y_min), int(x_max), int(y_max))

def visualize_alignment(frames, output_path, title):
    """Crea una visualización de alineación de frames."""
    # Crear grid de frames con overlays
    num_frames = len(frames)
    frame_width, frame_height = frames[0].size
    
    # Grid: 2 filas de 4 frames
    grid_cols = 4
    grid_rows = (num_frames + grid_cols - 1) // grid_cols
    
    margin = 10
    label_height = 30
    grid_width = grid_cols * frame_width + (grid_cols + 1) * margin
    grid_height = grid_rows * (frame_height + label_height) + (grid_rows + 1) * margin
    
    canvas = Image.new('RGBA', (grid_width, grid_height), (40, 40, 40, 255))
    draw = ImageDraw.Draw(canvas)
    
    # Analizar alineación
    centers = []
    bboxes = []
    
    for frame in frames:
        bbox = get_content_bbox(frame)
        if bbox:
            bboxes.append(bbox)
            center_x = (bbox[0] + bbox[2]) / 2
            center_y = (bbox[1] + bbox[3]) / 2
            centers.append((center_x, center_y))
    
    if centers:
        avg_center = np.array(centers).mean(axis=0)
        max_deviation = max([np.sqrt((c[0]-avg_center[0])**2 + (c[1]-avg_center[1])**2) for c in centers])
    else:
        avg_center = None
        max_deviation = 0
    
    # Dibujar frames
    for i, frame in enumerate(frames):
        row = i // grid_cols
        col = i % grid_cols
        
        x = margin + col * (frame_width + margin)
        y = margin + row * (frame_height + label_height + margin)
        
        # Pegar frame
        canvas.paste(frame, (x, y), frame)
        
        # Dibujar bbox si existe
        if i < len(bboxes):
            bbox = bboxes[i]
            draw.rectangle(
                [(x + bbox[0], y + bbox[1]), (x + bbox[2], y + bbox[3])],
                outline=(0, 255, 0, 128),
                width=2
            )
            
            # Dibujar centro
            center = centers[i]
            cx = x + center[0]
            cy = y + center[1]
            draw.ellipse(
                [(cx-3, cy-3), (cx+3, cy+3)],
                fill=(255, 0, 0, 255)
            )
            
            # Línea al centro promedio
            if avg_center is not None:
                avg_x = x + avg_center[0]
                avg_y = y + avg_center[1]
                draw.line([(cx, cy), (avg_x, avg_y)], fill=(255, 255, 0, 128), width=1)
        
        # Label
        label_y = y + frame_height + 5
        draw.text((x + 5, label_y), f"F{i+1}", fill=(200, 200, 200, 255))
    
    # Título y estadísticas
    draw.text((margin, 5), title, fill=(255, 255, 255, 255))
    
    if avg_center is not None:
        stats_text = f"Desviación máx: {max_deviation:.1f}px"
        text_color = (0, 255, 0, 255) if max_deviation < 3 else (255, 165, 0, 255) if max_deviation < 10 else (255, 0, 0, 255)
        draw.text((margin, grid_height - 25), stats_text, fill=text_color)
    
    canvas.save(output_path, 'PNG')
    print(f"✅ Visualización guardada: {output_path}")
    
    return max_deviation

def main():
    base_dir = Path(r"C:\git\spellloop\project\assets\textures\biomes\Snow")
    output_dir = Path(__file__).parent / "alignment_verification"
    output_dir.mkdir(exist_ok=True)
    
    print("\n" + "="*80)
    print("VERIFICACIÓN VISUAL DE ALINEACIÓN")
    print("="*80)
    
    # Verificar decoraciones
    print("\n--- DECORACIONES ---")
    decor_dir = base_dir / "decor"
    
    results = []
    
    for i in range(1, 11):
        sheet_path = decor_dir / f"snow_decor{i}_sheet_f8_256.png"
        
        if sheet_path.exists():
            print(f"\nProcesando Decor {i}...")
            frames = extract_frames_from_sheet(sheet_path, 256, 256, 8)
            
            output_path = output_dir / f"decor{i}_alignment.png"
            deviation = visualize_alignment(frames, output_path, f"Snow Decor {i} - Alineación")
            
            results.append((f"Decor {i}", deviation))
            
            status = "✅" if deviation < 3 else "⚠️" if deviation < 10 else "❌"
            print(f"{status} Decor {i}: Desviación = {deviation:.1f}px")
    
    # Verificar textura base
    print("\n--- TEXTURA BASE ---")
    base_sheet = base_dir / "base" / "snow_base_animated_sheet_f8_512.png"
    
    if base_sheet.exists():
        print("\nProcesando Base...")
        frames = extract_frames_from_sheet(base_sheet, 512, 512, 8)
        
        output_path = output_dir / "base_alignment.png"
        deviation = visualize_alignment(frames, output_path, "Snow Base - Alineación")
        
        results.append(("Base", deviation))
        
        status = "✅" if deviation < 3 else "⚠️"
        print(f"{status} Base: Desviación = {deviation:.1f}px")
    
    # Resumen
    print("\n" + "="*80)
    print("RESUMEN")
    print("="*80)
    
    for name, dev in results:
        status = "✅ BIEN" if dev < 3 else "⚠️ MODERADO" if dev < 10 else "❌ MALO"
        print(f"{name:15} {dev:6.1f}px  {status}")
    
    print(f"\n📁 Visualizaciones guardadas en: {output_dir}")
    print("\nAbre las imágenes PNG para inspección visual detallada.")

if __name__ == "__main__":
    main()
