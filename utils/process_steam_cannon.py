"""
Procesa sprites de Steam Cannon (6 frames en una fila).
Detecta cada frame, los normaliza al mismo tamaño y genera el spritesheet final.
"""

from PIL import Image, ImageEnhance
import numpy as np
from pathlib import Path

def find_frames_by_gaps(img, min_gap=5, alpha_threshold=30):
    """
    Detecta frames buscando gaps (columnas vacías) entre ellos.
    """
    arr = np.array(img)
    alpha = arr[:,:,3]
    
    # Columnas con contenido
    cols_content = np.any(alpha > alpha_threshold, axis=0)
    
    # Detectar frames buscando gaps
    in_frame = False
    frame_regions = []
    frame_start = 0
    gap_count = 0
    
    for i, has_content in enumerate(cols_content):
        if has_content:
            if not in_frame:
                frame_start = i
                in_frame = True
            gap_count = 0
        else:
            if in_frame:
                gap_count += 1
                if gap_count >= min_gap:
                    frame_end = i - gap_count + 1
                    frame_regions.append((frame_start, frame_end))
                    in_frame = False
                    gap_count = 0
    
    # Último frame
    if in_frame:
        # Encontrar el final real del contenido
        last_content = len(cols_content) - 1
        while last_content > frame_start and not cols_content[last_content]:
            last_content -= 1
        frame_regions.append((frame_start, last_content + 1))
    
    return frame_regions


def extract_frame_content(img, x_start, x_end, alpha_threshold=30):
    """
    Extrae el contenido de un frame, recortando el espacio vacío vertical.
    """
    region = img.crop((x_start, 0, x_end, img.height))
    arr = np.array(region)
    alpha = arr[:,:,3]
    
    # Encontrar filas con contenido
    rows_content = np.any(alpha > alpha_threshold, axis=1)
    cols_content = np.any(alpha > alpha_threshold, axis=0)
    
    if not np.any(rows_content) or not np.any(cols_content):
        return None
    
    y_min = int(np.argmax(rows_content))
    y_max = int(len(rows_content) - np.argmax(rows_content[::-1]))
    x_min = int(np.argmax(cols_content))
    x_max = int(len(cols_content) - np.argmax(cols_content[::-1]))
    
    return region.crop((x_min, y_min, x_max, y_max))


def process_steam_cannon(input_path, output_path, output_frame_size=64, target_content_size=58):
    """
    Procesa la imagen de Steam Cannon y genera el spritesheet.
    """
    print(f"Procesando: {input_path}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    print(f"Tamaño original: {img.width}x{img.height}")
    
    # Detectar frames por gaps
    frame_regions = find_frames_by_gaps(img, min_gap=3)
    print(f"\nFrames detectados: {len(frame_regions)}")
    
    # Si no detectamos 6 frames, intentar división uniforme
    if len(frame_regions) != 6:
        print("No se detectaron 6 frames por gaps, intentando división uniforme...")
        frame_width = img.width // 6
        frame_regions = [(i * frame_width, (i + 1) * frame_width) for i in range(6)]
    
    # Extraer contenido de cada frame
    frames = []
    for i, (x_start, x_end) in enumerate(frame_regions):
        content = extract_frame_content(img, x_start, x_end)
        if content:
            frames.append(content)
            print(f"  Frame {i+1}: región [{x_start}-{x_end}] -> contenido {content.width}x{content.height}")
        else:
            frames.append(None)
            print(f"  Frame {i+1}: región [{x_start}-{x_end}] -> VACÍO")
    
    # Encontrar el tamaño máximo para escala uniforme
    valid_frames = [f for f in frames if f is not None]
    if not valid_frames:
        print("ERROR: No se encontraron frames válidos")
        return
    
    max_w = max(f.width for f in valid_frames)
    max_h = max(f.height for f in valid_frames)
    print(f"\nTamaño máximo de contenido: {max_w}x{max_h}")
    
    # Calcular escala uniforme
    scale = min(target_content_size / max_w, target_content_size / max_h)
    print(f"Escala uniforme: {scale:.3f}")
    
    # Crear spritesheet de salida
    num_frames = len(valid_frames)
    output = Image.new('RGBA', (output_frame_size * num_frames, output_frame_size), (0, 0, 0, 0))
    
    print(f"\nGenerando spritesheet {output_frame_size * num_frames}x{output_frame_size}:")
    frame_idx = 0
    for i, content in enumerate(frames):
        if content is None:
            continue
        
        # Escalar con la misma proporción para todos
        new_w = max(1, int(content.width * scale))
        new_h = max(1, int(content.height * scale))
        
        scaled = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Mejorar nitidez
        enhancer = ImageEnhance.Sharpness(scaled)
        scaled = enhancer.enhance(1.2)
        
        # Centrar en el frame
        offset_x = (output_frame_size - new_w) // 2
        offset_y = (output_frame_size - new_h) // 2
        
        paste_x = frame_idx * output_frame_size + offset_x
        paste_y = offset_y
        
        output.paste(scaled, (paste_x, paste_y), scaled)
        print(f"  Frame {frame_idx + 1}: {content.width}x{content.height} -> {new_w}x{new_h}")
        frame_idx += 1
    
    # Guardar
    output.save(output_path)
    print(f"\n✓ Guardado: {output_path}")
    print(f"  Tamaño final: {output.width}x{output.height} ({frame_idx} frames)")


if __name__ == "__main__":
    base_path = Path("project/assets/sprites/projectiles/weapons/light_beam")
    
    # Buscar imágenes de entrada (archivos removebg que no sean ya spritesheets)
    input_files = sorted([
        f for f in base_path.glob("*removebg*.png") 
        if "beam_start" not in f.name and "beam_tip" not in f.name
    ])
    
    if len(input_files) >= 2:
        # Primera imagen -> beam_start
        print("="*50)
        print("PROCESANDO BEAM_START")
        print("="*50)
        output_start = base_path / "beam_start_light_beam.png"
        process_steam_cannon(input_files[0], output_start, output_frame_size=64, target_content_size=58)
        
        # Segunda imagen -> beam_tip
        print("\n" + "="*50)
        print("PROCESANDO BEAM_TIP")
        print("="*50)
        output_tip = base_path / "beam_tip_light_beam.png"
        process_steam_cannon(input_files[1], output_tip, output_frame_size=64, target_content_size=58)
        
    elif len(input_files) == 1:
        print("Solo se encontró 1 imagen, generando beam_start...")
        output_start = base_path / "beam_start_light_beam.png"
        process_steam_cannon(input_files[0], output_start, output_frame_size=64, target_content_size=58)
    else:
        print("No se encontraron imágenes PNG válidas en la carpeta")
