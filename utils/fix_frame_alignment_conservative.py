"""
Corrección conservadora de alineación de frames.
Alinea el contenido usando TRASLACIÓN (no recorte) para eliminar movimiento.
"""
from PIL import Image
import numpy as np
from pathlib import Path
import json

def get_content_bbox(image):
    """Calcula el bounding box del contenido no transparente."""
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
    
    return {
        'x_min': int(x_min),
        'y_min': int(y_min),
        'x_max': int(x_max),
        'y_max': int(y_max),
        'center_x': int((x_min + x_max) / 2),
        'center_y': int((y_min + y_max) / 2)
    }

def align_frames_conservative(frame_paths, target_size=None):
    """
    Alinea frames usando traslación conservadora.
    
    Args:
        frame_paths: Lista de rutas a los frames
        target_size: Tupla (width, height) opcional para redimensionar al final
    
    Returns:
        Lista de imágenes PIL alineadas
    """
    print(f"\nProcesando {len(frame_paths)} frames...")
    
    # Cargar frames y calcular bboxes
    frames = []
    bboxes = []
    
    for path in frame_paths:
        img = Image.open(path).convert("RGBA")
        bbox = get_content_bbox(img)
        if bbox:
            frames.append(img)
            bboxes.append(bbox)
    
    if not frames:
        print("❌ No se detectó contenido en los frames")
        return None
    
    # Calcular centro promedio
    centers = np.array([(b['center_x'], b['center_y']) for b in bboxes])
    avg_center = centers.mean(axis=0)
    
    print(f"Centro promedio: ({avg_center[0]:.1f}, {avg_center[1]:.1f})")
    
    # Calcular tamaño de canvas necesario (añadir padding generoso)
    original_size = frames[0].size
    
    # Calcular cuánto necesitamos expandir en cada dirección
    max_shift_x = max(abs(b['center_x'] - avg_center[0]) for b in bboxes)
    max_shift_y = max(abs(b['center_y'] - avg_center[1]) for b in bboxes)
    
    # Canvas con padding extra para evitar cualquier recorte
    padding = 20
    canvas_width = original_size[0] + int(max_shift_x * 2) + padding * 2
    canvas_height = original_size[1] + int(max_shift_y * 2) + padding * 2
    
    print(f"Canvas necesario: {canvas_width}x{canvas_height}px (original: {original_size[0]}x{original_size[1]}px)")
    
    # Alinear cada frame
    aligned_frames = []
    
    for i, (frame, bbox) in enumerate(zip(frames, bboxes), 1):
        # Calcular offset para alinear este frame al centro promedio
        offset_x = int(avg_center[0] - bbox['center_x'])
        offset_y = int(avg_center[1] - bbox['center_y'])
        
        # Crear canvas nuevo
        canvas = Image.new('RGBA', (canvas_width, canvas_height), (0, 0, 0, 0))
        
        # Posición de pegado: centro del canvas + offset
        paste_x = (canvas_width - original_size[0]) // 2 + offset_x
        paste_y = (canvas_height - original_size[1]) // 2 + offset_y
        
        # Pegar frame
        canvas.paste(frame, (paste_x, paste_y), frame)
        
        print(f"Frame {i}: offset=({offset_x:+3d}, {offset_y:+3d}px) desviación={np.sqrt(offset_x**2 + offset_y**2):.1f}px")
        
        aligned_frames.append(canvas)
    
    # Redimensionar si se especificó target_size
    if target_size:
        print(f"\nRedimensionando a {target_size[0]}x{target_size[1]}px...")
        aligned_frames = [img.resize(target_size, Image.Resampling.LANCZOS) for img in aligned_frames]
    
    return aligned_frames

def create_spritesheet(frames, output_path, frames_per_row=None, padding=4):
    """Crea un sprite sheet horizontal con los frames y padding entre ellos."""
    if not frames:
        return False
    
    frame_width, frame_height = frames[0].size
    num_frames = len(frames)
    
    if frames_per_row is None:
        frames_per_row = num_frames
    
    # Calcular ancho con padding: frame1 + padding + frame2 + padding + ... + frameN
    # Total padding = (num_frames - 1) * padding
    sheet_width = frame_width * frames_per_row + padding * (frames_per_row - 1)
    sheet_height = frame_height * ((num_frames + frames_per_row - 1) // frames_per_row)
    
    sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        # Posición X con padding acumulado
        x = (i % frames_per_row) * (frame_width + padding)
        y = (i // frames_per_row) * frame_height
        sheet.paste(frame, (x, y))
    
    sheet.save(output_path, 'PNG')
    print(f"✅ Sprite sheet guardado: {output_path}")
    print(f"   Tamaño: {sheet_width}x{sheet_height}px, {num_frames} frames, {padding}px padding")
    
    return True

def process_decor_group(frame_paths, output_path, group_name):
    """Procesa un grupo de decoraciones."""
    print(f"\n{'='*60}")
    print(f"Procesando: {group_name}")
    print(f"{'='*60}")
    
    # Alinear frames conservadoramente y redimensionar a 256x256
    aligned_frames = align_frames_conservative(frame_paths, target_size=(256, 256))
    
    if aligned_frames:
        # Crear sprite sheet
        success = create_spritesheet(aligned_frames, output_path)
        return success
    
    return False

def process_base_texture(frame_paths, output_path):
    """
    Procesa la textura base.
    Para seamless, solo redimensiona SIN alineación.
    """
    print(f"\n{'='*60}")
    print(f"Procesando: Textura Base (seamless)")
    print(f"{'='*60}")
    
    frames = []
    for i, path in enumerate(frame_paths, 1):
        img = Image.open(path).convert("RGBA")
        # Solo redimensionar, NO alinear
        resized = img.resize((512, 512), Image.Resampling.LANCZOS)
        frames.append(resized)
        print(f"Frame {i}: {img.size[0]}x{img.size[1]}px -> 512x512px")
    
    if frames:
        success = create_spritesheet(frames, output_path)
        return success
    
    return False

def main():
    # Cargar diagnóstico
    diagnosis_file = Path(__file__).parent / "frame_movement_diagnosis.json"
    
    if not diagnosis_file.exists():
        print("❌ Ejecuta primero diagnose_frame_movement.py")
        return
    
    with open(diagnosis_file, 'r') as f:
        diagnosis = json.load(f)
    
    base_dir = Path(r"C:\git\spellloop\project\assets\textures\biomes\Snow")
    
    # Procesar textura base
    print("\n" + "="*80)
    print("PROCESANDO TEXTURA BASE")
    print("="*80)
    
    base_frames = sorted((base_dir / "base").glob("[0-9]*.png"))
    if base_frames:
        output_base = base_dir / "base" / "snow_base_animated_sheet_f8_512.png"
        process_base_texture(base_frames, output_base)
    
    # Procesar solo decoraciones que necesitan corrección (>5px)
    print("\n" + "="*80)
    print("PROCESANDO DECORACIONES")
    print("="*80)
    
    decor_dir = base_dir / "decor"
    
    # Agrupar frames por set
    decor_groups = {}
    for png_file in decor_dir.glob("*.png"):
        if 'sheet' in png_file.name:
            continue
        
        import re
        match = re.search(r'(\d+)', png_file.stem)
        if match:
            num = int(match.group(1))
            group = (num // 10) * 10 + 1
            if group not in decor_groups:
                decor_groups[group] = []
            decor_groups[group].append(png_file)
    
    # Procesar cada grupo
    processed = 0
    for group_num in sorted(decor_groups.keys()):
        frames = sorted(decor_groups[group_num])
        
        # Buscar en diagnóstico si necesita corrección
        group_name = f"Decor Group {group_num}"
        needs_fix = False
        
        for analysis in diagnosis['analysis']:
            if analysis['set_name'] == group_name:
                if analysis['max_deviation'] > 5:
                    needs_fix = True
                break
        
        if needs_fix or True:  # Procesar todos para consistencia
            # Determinar número de decor (1-10)
            decor_num = (group_num // 10) if group_num > 10 else 1
            if group_num >= 11:
                decor_num = (group_num - 1) // 10 + 1
            
            output_path = decor_dir / f"snow_decor{decor_num}_sheet_f8_256.png"
            
            if process_decor_group(frames, output_path, group_name):
                processed += 1
    
    print("\n" + "="*80)
    print("COMPLETADO")
    print("="*80)
    print(f"Decoraciones procesadas: {processed}")
    print(f"Textura base: Redimensionada sin alineación (preserva seamless)")

if __name__ == "__main__":
    main()
