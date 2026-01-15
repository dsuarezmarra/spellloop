"""
Script GENÉRICO para procesar sprites de personajes.
Analiza spritesheets, detecta frames, los corta uniformemente y genera los archivos finales.

USO:
    python process_character_sprites.py <nombre_personaje>
    
EJEMPLOS:
    python process_character_sprites.py frost_mage
    python process_character_sprites.py pyromancer
    python process_character_sprites.py storm_caller
    
ESTRUCTURA ESPERADA:
    assets/sprites/players/{character}/
        walk/
            walk_down.png   (spritesheet con 3 frames)
            walk_up.png     (spritesheet con 3 frames)
            walk_right.png  (spritesheet con 3 frames)
        cast/
            cast.png        (spritesheet con 3 frames)
        death/
            death.png       (spritesheet con 3 frames)
        hit/
            hit.png         (spritesheet con 3 frames)

SALIDA GENERADA:
    walk/
        {character}_walk_down_1.png, {character}_walk_down_2.png, {character}_walk_down_3.png
        {character}_walk_up_1.png, {character}_walk_up_2.png, {character}_walk_up_3.png
        {character}_walk_right_1.png, {character}_walk_right_2.png, {character}_walk_right_3.png
        {character}_walk_left_1.png, {character}_walk_left_2.png, {character}_walk_left_3.png  (volteado de right)
    cast/
        {character}_cast_1.png, {character}_cast_2.png, {character}_cast_3.png
    death/
        {character}_death_1.png, {character}_death_2.png, {character}_death_3.png
    hit/
        {character}_hit_1.png, {character}_hit_2.png, {character}_hit_3.png
"""

from PIL import Image
import os
import numpy as np
import sys

# Configuración base
PROJECT_PATH = r"c:\git\spellloop\project"
SPRITES_PATH = os.path.join(PROJECT_PATH, "assets", "sprites", "players")

# Umbral mínimo de ancho de frame (para filtrar ruido)
MIN_FRAME_WIDTH = 50

# Tamaño fijo para TODOS los personajes (consistencia visual)
# Si es None, se calcula automáticamente. Si es un número, se usa ese tamaño fijo.
FIXED_FRAME_SIZE = 208  # Todos los personajes usan 208x208


def get_character_path(character_name):
    """Obtiene la ruta base de un personaje."""
    return os.path.join(SPRITES_PATH, character_name)


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
    
    # Una columna tiene contenido si ALGÚN píxel tiene alpha > 10
    column_has_content = np.any(alpha_channel > 10, axis=0)
    
    # Encontrar los límites de cada frame (donde hay contenido)
    raw_frames = []
    in_frame = False
    frame_start = 0
    
    for x in range(width):
        if column_has_content[x] and not in_frame:
            frame_start = x
            in_frame = True
        elif not column_has_content[x] and in_frame:
            raw_frames.append((frame_start, x))
            in_frame = False
    
    if in_frame:
        raw_frames.append((frame_start, width))
    
    # Filtrar frames pequeños (ruido)
    frames = [(start, end) for start, end in raw_frames if (end - start) >= MIN_FRAME_WIDTH]
    
    print(f"Frames detectados (raw): {len(raw_frames)}")
    print(f"Frames válidos (>={MIN_FRAME_WIDTH}px): {len(frames)}")
    for i, (start, end) in enumerate(frames):
        print(f"  Frame {i+1}: columnas {start}-{end} (ancho: {end-start}px)")
    
    if len(raw_frames) > len(frames):
        print(f"  ⚠️ Se filtraron {len(raw_frames) - len(frames)} fragmentos de ruido")
    
    # Encontrar filas con contenido
    row_has_content = np.any(alpha_channel > 10, axis=1)
    content_rows = np.where(row_has_content)[0]
    
    if len(content_rows) > 0:
        top_row = content_rows[0]
        bottom_row = content_rows[-1]
        content_height = bottom_row - top_row + 1
        print(f"Contenido vertical: filas {top_row}-{bottom_row} (altura: {content_height}px)")
    else:
        top_row, bottom_row = 0, height - 1
    
    return img, frames, (top_row, bottom_row)


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
    
    # Añadir padding y redondear a múltiplo de 16
    frame_size = max(max_frame_width, max_content_height) + 20
    frame_size = ((frame_size + 15) // 16) * 16
    
    return frame_size


def extract_and_normalize_frames(img, frames, vertical_bounds, target_size):
    """Extrae frames y los normaliza al tamaño objetivo."""
    top_row, bottom_row = vertical_bounds
    normalized_frames = []
    
    for i, (start, end) in enumerate(frames):
        frame_width = end - start
        content_height = bottom_row - top_row + 1
        
        # Crear imagen con transparencia
        normalized = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
        
        # Extraer contenido
        frame_content = img.crop((start, top_row, end, bottom_row + 1))
        
        # Centrar
        paste_x = (target_size - frame_width) // 2
        paste_y = (target_size - content_height) // 2
        
        normalized.paste(frame_content, (paste_x, paste_y))
        normalized_frames.append(normalized)
    
    return normalized_frames


def create_spritesheet(frames, name, output_dir):
    """Crea un spritesheet horizontal."""
    if not frames:
        print(f"  ⚠️ No hay frames para {name}")
        return None
    
    frame_size = frames[0].size[0]
    num_frames = len(frames)
    
    spritesheet = Image.new("RGBA", (frame_size * num_frames, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * frame_size, 0))
    
    output_path = os.path.join(output_dir, f"{name}_strip.png")
    spritesheet.save(output_path, "PNG")
    print(f"  ✅ Spritesheet: {output_path} ({spritesheet.size[0]}x{spritesheet.size[1]})")
    
    return spritesheet


def save_individual_frames(frames, animation_name, output_dir, character_prefix):
    """Guarda frames individuales con formato Godot."""
    for i, frame in enumerate(frames):
        if animation_name.startswith("walk_"):
            direction = animation_name.replace("walk_", "")
            filename = f"{character_prefix}_walk_{direction}_{i+1}.png"
        else:
            filename = f"{character_prefix}_{animation_name}_{i+1}.png"
        
        output_path = os.path.join(output_dir, filename)
        frame.save(output_path, "PNG")
        print(f"  📄 {filename}")


def process_character(character_name):
    """Procesa todos los sprites de un personaje."""
    base_path = get_character_path(character_name)
    
    if not os.path.exists(base_path):
        print(f"❌ ERROR: No se encontró la carpeta del personaje: {base_path}")
        return False
    
    print("=" * 60)
    print(f"PROCESADOR DE SPRITES - {character_name.upper()}")
    print("=" * 60)
    
    # Definir sprites a procesar
    sprites = {
        "walk_down": os.path.join(base_path, "walk", "walk_down.png"),
        "walk_up": os.path.join(base_path, "walk", "walk_up.png"),
        "walk_right": os.path.join(base_path, "walk", "walk_right.png"),
        "cast": os.path.join(base_path, "cast", "cast.png"),
        "death": os.path.join(base_path, "death", "death.png"),
        "hit": os.path.join(base_path, "hit", "hit.png"),
    }
    
    # Paso 1: Analizar
    print("\n" + "=" * 60)
    print("PASO 1: ANÁLISIS DE SPRITES")
    print("=" * 60)
    
    analyses = {}
    for name, path in sprites.items():
        if os.path.exists(path):
            analyses[name] = analyze_sprite(path, name)
        else:
            print(f"⚠️ No encontrado: {path}")
    
    if not analyses:
        print("❌ ERROR: No se encontraron sprites para procesar")
        return False
    
    # Paso 2: Tamaño uniforme
    print("\n" + "=" * 60)
    print("PASO 2: DETERMINANDO TAMAÑO UNIFORME")
    print("=" * 60)
    
    if FIXED_FRAME_SIZE:
        target_size = FIXED_FRAME_SIZE
        print(f"Usando tamaño FIJO: {target_size}x{target_size} píxeles")
    else:
        target_size = find_uniform_frame_size(analyses)
        print(f"Tamaño calculado: {target_size}x{target_size} píxeles")
    
    # Paso 3: Extraer y normalizar
    print("\n" + "=" * 60)
    print("PASO 3: EXTRAYENDO Y NORMALIZANDO FRAMES")
    print("=" * 60)
    
    all_frames = {}
    for name, (img, frames, vertical_bounds) in analyses.items():
        print(f"\nProcesando {name}...")
        normalized = extract_and_normalize_frames(img, frames, vertical_bounds, target_size)
        all_frames[name] = normalized
        print(f"  Extraídos {len(normalized)} frames de {target_size}x{target_size}")
    
    # Paso 4: Generar archivos
    print("\n" + "=" * 60)
    print("PASO 4: GENERANDO SPRITESHEETS Y FRAMES")
    print("=" * 60)
    
    output_dirs = {
        "walk": os.path.join(base_path, "walk"),
        "cast": os.path.join(base_path, "cast"),
        "death": os.path.join(base_path, "death"),
        "hit": os.path.join(base_path, "hit"),
    }
    
    for dir_path in output_dirs.values():
        os.makedirs(dir_path, exist_ok=True)
    
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
            output_dir = base_path
        
        create_spritesheet(frames, name, output_dir)
        save_individual_frames(frames, name, output_dir, character_name)
        
        # Crear walk_left desde walk_right
        if name == "walk_right":
            print(f"\n📦 WALK_LEFT (volteado de walk_right):")
            flipped_frames = [frame.transpose(Image.FLIP_LEFT_RIGHT) for frame in frames]
            create_spritesheet(flipped_frames, "walk_left", output_dir)
            save_individual_frames(flipped_frames, "walk_left", output_dir, character_name)
    
    # Resumen
    print("\n" + "=" * 60)
    print("RESUMEN FINAL")
    print("=" * 60)
    print(f"✅ Personaje: {character_name}")
    print(f"✅ Tamaño de frame uniforme: {target_size}x{target_size}")
    print(f"✅ Total de animaciones procesadas: {len(all_frames)}")
    print(f"✅ walk_left generado automáticamente desde walk_right")
    print(f"\n📁 Archivos guardados en: {base_path}")
    
    return True


def main():
    if len(sys.argv) < 2:
        print("USO: python process_character_sprites.py <nombre_personaje>")
        print("\nPERSONAJES DISPONIBLES:")
        
        # Listar personajes existentes
        if os.path.exists(SPRITES_PATH):
            characters = [d for d in os.listdir(SPRITES_PATH) 
                         if os.path.isdir(os.path.join(SPRITES_PATH, d))]
            for char in sorted(characters):
                print(f"  - {char}")
        
        print("\nEJEMPLOS:")
        print("  python process_character_sprites.py frost_mage")
        print("  python process_character_sprites.py pyromancer")
        return
    
    character_name = sys.argv[1].lower()
    success = process_character(character_name)
    
    if success:
        print("\n✅ Procesamiento completado exitosamente")
    else:
        print("\n❌ Procesamiento falló")
        sys.exit(1)


if __name__ == "__main__":
    main()
