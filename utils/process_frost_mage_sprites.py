"""
Script para procesar los sprites del Frost Mage.
Analiza los spritesheets, detecta frames, los corta uniformemente y genera los archivos finales.
"""

from PIL import Image
import os
import numpy as np

# Configuración
BASE_PATH = r"c:\git\spellloop\project\assets\sprites\players\frost_mage"
OUTPUT_PATH = BASE_PATH  # Guardamos en el mismo lugar

def analyze_sprite(image_path, name):
    """Analiza un sprite para entender su estructura."""
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    print(f"\n{'='*60}")
    print(f"Analizando: {name}")
    print(f"Dimensiones: {width}x{height}")
    
    # Convertir a numpy para análisis
    data = np.array(img)
    
    # Encontrar columnas completamente transparentes (gaps entre frames)
    alpha_channel = data[:, :, 3]
    
    # Una columna es un gap si TODOS sus píxeles son transparentes
    column_has_content = np.any(alpha_channel > 10, axis=0)
    
    # Encontrar los límites de cada frame (donde hay contenido)
    raw_frames = []
    in_frame = False
    frame_start = 0
    
    for x in range(width):
        if column_has_content[x] and not in_frame:
            # Inicio de un frame
            frame_start = x
            in_frame = True
        elif not column_has_content[x] and in_frame:
            # Fin de un frame
            raw_frames.append((frame_start, x))
            in_frame = False
    
    # Si terminamos dentro de un frame
    if in_frame:
        raw_frames.append((frame_start, width))
    
    # FILTRAR: solo mantener frames con ancho >= 50px (eliminar ruido)
    MIN_FRAME_WIDTH = 50
    frames = [(start, end) for start, end in raw_frames if (end - start) >= MIN_FRAME_WIDTH]
    
    print(f"Frames detectados (raw): {len(raw_frames)}")
    print(f"Frames válidos (>={MIN_FRAME_WIDTH}px): {len(frames)}")
    for i, (start, end) in enumerate(frames):
        print(f"  Frame {i+1}: columnas {start}-{end} (ancho: {end-start}px)")
    
    if len(raw_frames) > len(frames):
        print(f"  ⚠️ Se filtraron {len(raw_frames) - len(frames)} fragmentos de ruido")
    
    # Encontrar filas con contenido para determinar altura real
    row_has_content = np.any(alpha_channel > 10, axis=1)
    content_rows = np.where(row_has_content)[0]
    
    if len(content_rows) > 0:
        top_row = content_rows[0]
        bottom_row = content_rows[-1]
        content_height = bottom_row - top_row + 1
        print(f"Contenido vertical: filas {top_row}-{bottom_row} (altura: {content_height}px)")
    
    return img, frames, (top_row, bottom_row) if len(content_rows) > 0 else (0, height-1)


def find_uniform_frame_size(all_analyses):
    """Encuentra el tamaño uniforme para todos los frames."""
    max_frame_width = 0
    max_content_height = 0
    
    for name, (img, frames, (top, bottom)) in all_analyses.items():
        for start, end in frames:
            frame_width = end - start
            if frame_width > max_frame_width:
                max_frame_width = frame_width
        
        content_height = bottom - top + 1
        if content_height > max_content_height:
            max_content_height = content_height
    
    # Añadir un pequeño padding y redondear a número par
    frame_size = max(max_frame_width, max_content_height) + 20
    frame_size = ((frame_size + 15) // 16) * 16  # Redondear al múltiplo de 16 más cercano
    
    return frame_size


def extract_and_normalize_frames(img, frames, vertical_bounds, target_size):
    """Extrae frames y los normaliza al tamaño objetivo."""
    top_row, bottom_row = vertical_bounds
    normalized_frames = []
    
    for i, (start, end) in enumerate(frames):
        # Extraer el frame con su contenido vertical
        frame_width = end - start
        content_height = bottom_row - top_row + 1
        
        # Crear imagen del tamaño objetivo con transparencia
        normalized = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
        
        # Extraer el contenido del frame original
        frame_content = img.crop((start, top_row, end, bottom_row + 1))
        
        # Centrar el contenido en el frame normalizado
        paste_x = (target_size - frame_width) // 2
        paste_y = (target_size - content_height) // 2
        
        normalized.paste(frame_content, (paste_x, paste_y))
        normalized_frames.append(normalized)
    
    return normalized_frames


def create_spritesheet(frames, name, output_dir):
    """Crea un spritesheet horizontal a partir de los frames."""
    if not frames:
        print(f"  ⚠️ No hay frames para {name}")
        return None
    
    frame_size = frames[0].size[0]
    num_frames = len(frames)
    
    # Crear spritesheet horizontal
    spritesheet = Image.new("RGBA", (frame_size * num_frames, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * frame_size, 0))
    
    # Guardar
    output_path = os.path.join(output_dir, f"{name}_strip.png")
    spritesheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path} ({spritesheet.size[0]}x{spritesheet.size[1]})")
    
    return spritesheet


def create_flipped_spritesheet(frames, name, output_dir):
    """Crea un spritesheet volteado horizontalmente (para walk_left)."""
    flipped_frames = [frame.transpose(Image.FLIP_LEFT_RIGHT) for frame in frames]
    return create_spritesheet(flipped_frames, name, output_dir)


def save_individual_frames(frames, name, output_dir, character_prefix="frost_mage"):
    """Guarda los frames individuales con el formato correcto para Godot.
    
    Formato esperado por Godot:
    - Walk: {prefix}_walk_{direction}_{frame}.png
    - Cast/Hit/Death: {prefix}_{animation}_{frame}.png
    """
    for i, frame in enumerate(frames):
        # Determinar nombre correcto para Godot
        if name.startswith("walk_"):
            # walk_down -> frost_mage_walk_down_1.png
            direction = name.replace("walk_", "")
            filename = f"{character_prefix}_walk_{direction}_{i+1}.png"
        else:
            # cast, hit, death -> frost_mage_cast_1.png
            filename = f"{character_prefix}_{name}_{i+1}.png"
        
        output_path = os.path.join(output_dir, filename)
        frame.save(output_path, "PNG")
        print(f"  📄 Frame {i+1}: {filename}")


def main():
    print("="*60)
    print("PROCESADOR DE SPRITES - FROST MAGE")
    print("="*60)
    
    # Lista de sprites a procesar
    sprites = {
        "walk_down": os.path.join(BASE_PATH, "walk", "walk_down.png"),
        "walk_up": os.path.join(BASE_PATH, "walk", "walk_up.png"),
        "walk_right": os.path.join(BASE_PATH, "walk", "walk_right.png"),
        "cast": os.path.join(BASE_PATH, "cast", "cast.png"),
        "death": os.path.join(BASE_PATH, "death", "death.png"),
        "hit": os.path.join(BASE_PATH, "hit", "hit.png"),
    }
    
    # Paso 1: Analizar todos los sprites
    print("\n" + "="*60)
    print("PASO 1: ANÁLISIS DE SPRITES")
    print("="*60)
    
    analyses = {}
    for name, path in sprites.items():
        if os.path.exists(path):
            analyses[name] = analyze_sprite(path, name)
        else:
            print(f"⚠️ No encontrado: {path}")
    
    # Paso 2: Determinar tamaño uniforme
    print("\n" + "="*60)
    print("PASO 2: DETERMINANDO TAMAÑO UNIFORME")
    print("="*60)
    
    target_size = find_uniform_frame_size(analyses)
    print(f"Tamaño de frame uniforme: {target_size}x{target_size} píxeles")
    
    # Paso 3: Extraer y normalizar frames
    print("\n" + "="*60)
    print("PASO 3: EXTRAYENDO Y NORMALIZANDO FRAMES")
    print("="*60)
    
    all_frames = {}
    for name, (img, frames, vertical_bounds) in analyses.items():
        print(f"\nProcesando {name}...")
        normalized = extract_and_normalize_frames(img, frames, vertical_bounds, target_size)
        all_frames[name] = normalized
        print(f"  Extraídos {len(normalized)} frames de {target_size}x{target_size}")
    
    # Paso 4: Crear spritesheets y frames individuales
    print("\n" + "="*60)
    print("PASO 4: GENERANDO SPRITESHEETS Y FRAMES")
    print("="*60)
    
    # Crear directorios de salida si no existen
    output_dirs = {
        "walk": os.path.join(OUTPUT_PATH, "walk"),
        "cast": os.path.join(OUTPUT_PATH, "cast"),
        "death": os.path.join(OUTPUT_PATH, "death"),
        "hit": os.path.join(OUTPUT_PATH, "hit"),
    }
    
    for dir_path in output_dirs.values():
        os.makedirs(dir_path, exist_ok=True)
    
    # Procesar cada tipo de animación
    for name, frames in all_frames.items():
        print(f"\n📦 {name.upper()}:")
        
        if "walk" in name:
            output_dir = output_dirs["walk"]
        elif "cast" in name:
            output_dir = output_dirs["cast"]
        elif "death" in name:
            output_dir = output_dirs["death"]
        elif "hit" in name:
            output_dir = output_dirs["hit"]
        else:
            output_dir = OUTPUT_PATH
        
        # Crear spritesheet
        create_spritesheet(frames, name, output_dir)
        
        # Guardar frames individuales (con prefijo de personaje)
        save_individual_frames(frames, name, output_dir, "frost_mage")
        
        # Si es walk_right, crear también walk_left (volteado)
        if name == "walk_right":
            print(f"\n📦 WALK_LEFT (volteado de walk_right):")
            create_flipped_spritesheet(frames, "walk_left", output_dir)
            # También guardar frames individuales volteados
            flipped_frames = [frame.transpose(Image.FLIP_LEFT_RIGHT) for frame in frames]
            save_individual_frames(flipped_frames, "walk_left", output_dir, "frost_mage")
    
    # Resumen final
    print("\n" + "="*60)
    print("RESUMEN FINAL")
    print("="*60)
    print(f"✅ Tamaño de frame uniforme: {target_size}x{target_size}")
    print(f"✅ Total de animaciones procesadas: {len(all_frames)}")
    print(f"✅ walk_left generado automáticamente desde walk_right")
    
    return target_size, all_frames


if __name__ == "__main__":
    main()
