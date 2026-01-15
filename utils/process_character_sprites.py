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

# ============================================================
# CONFIGURACIÓN - AJUSTAR ESTOS VALORES
# ============================================================

PROJECT_PATH = r"c:\git\spellloop\project"
SPRITES_PATH = os.path.join(PROJECT_PATH, "assets", "sprites", "players")

# Umbral mínimo de ancho de frame (para filtrar ruido)
MIN_FRAME_WIDTH = 50

# Tamaño FIJO del canvas de salida (todos los personajes usan el mismo)
FIXED_FRAME_SIZE = 208

# Tamaño FIJO del contenido dentro del canvas
# El sprite se escalará para que quepa en este tamaño, manteniendo proporciones
# Esto garantiza que todos los personajes se vean del mismo tamaño visual
CONTENT_TARGET_SIZE = 180  # El contenido ocupará máximo 180x180 dentro de 208x208

# ============================================================
# FUNCIONES
# ============================================================

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
    alpha_channel = data[:, :, 3]
    
    # Encontrar columnas con contenido
    column_has_content = np.any(alpha_channel > 10, axis=0)
    
    # Encontrar los límites de cada frame
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


def get_frame_content_bounds(img, frame_x_start, frame_x_end):
    """
    Obtiene los límites exactos del contenido de un frame específico.
    Retorna (left, top, right, bottom) del bounding box del contenido.
    """
    data = np.array(img)
    alpha = data[:, :, 3]
    
    # Recortar al área del frame
    frame_alpha = alpha[:, frame_x_start:frame_x_end]
    
    # Encontrar filas con contenido
    row_has_content = np.any(frame_alpha > 10, axis=1)
    content_rows = np.where(row_has_content)[0]
    
    # Encontrar columnas con contenido
    col_has_content = np.any(frame_alpha > 10, axis=0)
    content_cols = np.where(col_has_content)[0]
    
    if len(content_rows) == 0 or len(content_cols) == 0:
        return None
    
    top = content_rows[0]
    bottom = content_rows[-1]
    left = content_cols[0] + frame_x_start
    right = content_cols[-1] + frame_x_start
    
    return (left, top, right + 1, bottom + 1)


def extract_and_normalize_frames(img, frames, target_canvas_size, target_content_size):
    """
    Extrae frames, los escala para que el contenido tenga un tamaño uniforme,
    y los centra en el canvas.
    """
    normalized_frames = []
    
    for i, (frame_start, frame_end) in enumerate(frames):
        # Obtener bounding box exacto del contenido de este frame
        bounds = get_frame_content_bounds(img, frame_start, frame_end)
        
        if bounds is None:
            print(f"    ⚠️ Frame {i+1} vacío")
            # Crear frame vacío
            normalized = Image.new("RGBA", (target_canvas_size, target_canvas_size), (0, 0, 0, 0))
            normalized_frames.append(normalized)
            continue
        
        left, top, right, bottom = bounds
        content_width = right - left
        content_height = bottom - top
        
        # Extraer el contenido exacto
        frame_content = img.crop((left, top, right, bottom))
        
        # Calcular escala para que el contenido quepa en target_content_size
        scale_x = target_content_size / content_width
        scale_y = target_content_size / content_height
        scale = min(scale_x, scale_y)  # Mantener proporción, usar el menor
        
        # No escalar si ya es más pequeño (evitar agrandar demasiado)
        if scale > 1.0:
            scale = 1.0
        
        # Escalar el contenido
        new_width = int(content_width * scale)
        new_height = int(content_height * scale)
        
        if scale < 1.0:
            frame_content = frame_content.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Crear canvas y centrar
        normalized = Image.new("RGBA", (target_canvas_size, target_canvas_size), (0, 0, 0, 0))
        paste_x = (target_canvas_size - new_width) // 2
        paste_y = (target_canvas_size - new_height) // 2
        
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
    print(f"Canvas: {FIXED_FRAME_SIZE}x{FIXED_FRAME_SIZE}")
    print(f"Contenido objetivo: {CONTENT_TARGET_SIZE}x{CONTENT_TARGET_SIZE}")
    
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
    
    # Paso 2: Extraer y normalizar con tamaño fijo
    print("\n" + "=" * 60)
    print("PASO 2: EXTRAYENDO Y NORMALIZANDO FRAMES")
    print("=" * 60)
    print(f"Todos los frames serán {FIXED_FRAME_SIZE}x{FIXED_FRAME_SIZE}")
    print(f"Contenido escalado a máximo {CONTENT_TARGET_SIZE}x{CONTENT_TARGET_SIZE}")
    
    all_frames = {}
    for name, (img, frames, vertical_bounds) in analyses.items():
        print(f"\nProcesando {name}...")
        normalized = extract_and_normalize_frames(
            img, frames, 
            FIXED_FRAME_SIZE, 
            CONTENT_TARGET_SIZE
        )
        all_frames[name] = normalized
        print(f"  Extraídos {len(normalized)} frames")
    
    # Paso 3: Generar archivos
    print("\n" + "=" * 60)
    print("PASO 3: GENERANDO SPRITESHEETS Y FRAMES")
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
    print(f"✅ Canvas: {FIXED_FRAME_SIZE}x{FIXED_FRAME_SIZE}")
    print(f"✅ Contenido normalizado a: {CONTENT_TARGET_SIZE}x{CONTENT_TARGET_SIZE} máximo")
    print(f"✅ Total de animaciones procesadas: {len(all_frames)}")
    print(f"✅ walk_left generado automáticamente desde walk_right")
    print(f"\n📁 Archivos guardados en: {base_path}")
    
    return True


def main():
    if len(sys.argv) < 2:
        print("USO: python process_character_sprites.py <nombre_personaje>")
        print("\nPERSONAJES DISPONIBLES:")
        
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
