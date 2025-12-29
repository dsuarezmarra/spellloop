"""
Script para procesar sprites de Fire Wand generados por IA
Detecta colores de fuego (naranja, rojo, amarillo) y elimina el fondo de tablero de ajedrez
"""

from PIL import Image
import numpy as np
import os

# Configuración
INPUT_DIR = r"C:\git\spellloop\utils\fire_wand_raw"  # Carpeta con imágenes originales
OUTPUT_DIR = r"C:\git\spellloop\project\assets\sprites\projectiles\fire_wand"
FRAME_SIZE = 64  # Tamaño final de cada frame

# Configuración por animación
ANIMATIONS = {
    "flight": {"frames": 6, "file": "flight_raw.png"},
    "impact": {"frames": 6, "file": "impact_raw.png"},
    "launch": {"frames": 4, "file": "launch_raw.png"}
}


def is_fire_color(r, g, b, a):
    """Detectar si un píxel es color de fuego (naranja, rojo, amarillo)"""
    if a < 30:  # Transparente
        return False
    
    # Normalizar a 0-1
    r_n, g_n, b_n = r / 255.0, g / 255.0, b / 255.0
    
    # Amarillo brillante (núcleo del fuego): alto R, alto G, bajo B
    if r_n > 0.8 and g_n > 0.7 and b_n < 0.5:
        return True
    
    # Naranja: alto R, medio G, bajo B
    if r_n > 0.7 and g_n > 0.3 and g_n < 0.8 and b_n < 0.4:
        return True
    
    # Rojo: alto R, bajo G, bajo B
    if r_n > 0.6 and g_n < 0.5 and b_n < 0.4:
        return True
    
    # Rojo oscuro/marrón (humo): medio R, bajo G, bajo B
    if r_n > 0.3 and r_n < 0.7 and g_n < 0.3 and b_n < 0.3:
        return True
    
    # Negro (contornos): muy oscuro
    if r_n < 0.2 and g_n < 0.2 and b_n < 0.2 and a > 200:
        return True
    
    # Gris oscuro (humo/sombras)
    if r_n < 0.5 and g_n < 0.5 and b_n < 0.5 and abs(r_n - g_n) < 0.15 and abs(g_n - b_n) < 0.15 and a > 150:
        # Solo si tiene algo de transparencia o está junto a fuego
        return True
    
    return False


def is_checkerboard_gray(r, g, b, a):
    """Detectar si es el gris del tablero de ajedrez"""
    if a < 200:  # Si ya es transparente, no es tablero
        return False
    
    # Grises del tablero de ajedrez (normalmente ~128 y ~192, o ~153 y ~204)
    gray_values = [128, 153, 154, 192, 204, 205]
    tolerance = 15
    
    # Verificar si es gris (R ≈ G ≈ B)
    if abs(r - g) < 10 and abs(g - b) < 10:
        for gray in gray_values:
            if abs(r - gray) < tolerance:
                return True
    
    return False


def remove_checkerboard_background(img):
    """Eliminar el fondo de tablero de ajedrez y mantener solo el fuego"""
    img = img.convert("RGBA")
    pixels = np.array(img)
    
    height, width = pixels.shape[:2]
    result = np.zeros((height, width, 4), dtype=np.uint8)
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[y, x]
            
            if is_checkerboard_gray(r, g, b, a):
                # Es fondo de tablero -> transparente
                result[y, x] = [0, 0, 0, 0]
            elif is_fire_color(r, g, b, a):
                # Es fuego -> mantener
                result[y, x] = [r, g, b, a]
            elif a > 200:
                # Píxel opaco que no es ni tablero ni fuego claro
                # Podría ser humo o sombra - verificar si está cerca de píxeles de fuego
                result[y, x] = [r, g, b, a]
            else:
                # Transparente o semi-transparente
                result[y, x] = [r, g, b, a]
    
    return Image.fromarray(result, "RGBA")


def find_sprite_bounds(img):
    """Encontrar los límites del sprite (bounding box del contenido no transparente)"""
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    
    # Encontrar filas y columnas con contenido
    rows_with_content = np.any(alpha > 10, axis=1)
    cols_with_content = np.any(alpha > 10, axis=0)
    
    if not np.any(rows_with_content) or not np.any(cols_with_content):
        return None
    
    y_min = np.argmax(rows_with_content)
    y_max = len(rows_with_content) - np.argmax(rows_with_content[::-1]) - 1
    x_min = np.argmax(cols_with_content)
    x_max = len(cols_with_content) - np.argmax(cols_with_content[::-1]) - 1
    
    return (x_min, y_min, x_max + 1, y_max + 1)


def extract_frames_auto(img, expected_frames):
    """Extraer frames automáticamente detectando separaciones"""
    img = img.convert("RGBA")
    width, height = img.size
    pixels = np.array(img)
    
    # Buscar columnas completamente transparentes o de fondo
    alpha = pixels[:, :, 3]
    
    # Encontrar el área vertical con contenido
    rows_with_content = np.any(alpha > 10, axis=1)
    if not np.any(rows_with_content):
        return []
    
    y_start = np.argmax(rows_with_content)
    y_end = len(rows_with_content) - np.argmax(rows_with_content[::-1])
    
    # Buscar separaciones entre frames (columnas sin contenido significativo)
    col_content = np.sum(alpha > 10, axis=0)
    
    # Encontrar grupos de columnas con contenido
    in_sprite = False
    sprite_regions = []
    start_x = 0
    
    min_gap = 5  # Mínimo gap entre sprites
    min_content = height * 0.05  # Mínimo contenido para considerar parte del sprite
    
    for x in range(width):
        has_content = col_content[x] > min_content
        
        if has_content and not in_sprite:
            start_x = x
            in_sprite = True
        elif not has_content and in_sprite:
            # Verificar si es un gap real o solo un hueco pequeño
            gap_end = x
            while gap_end < width and col_content[gap_end] <= min_content:
                gap_end += 1
            
            if gap_end - x >= min_gap or gap_end >= width:
                sprite_regions.append((start_x, x))
                in_sprite = False
    
    if in_sprite:
        sprite_regions.append((start_x, width))
    
    print(f"  Regiones detectadas: {len(sprite_regions)}")
    
    # Si no detectamos el número correcto de frames, dividir equitativamente
    if len(sprite_regions) != expected_frames:
        print(f"  Ajustando a {expected_frames} frames (división equitativa)")
        frame_width = width // expected_frames
        sprite_regions = [(i * frame_width, (i + 1) * frame_width) for i in range(expected_frames)]
    
    # Extraer cada frame
    frames = []
    for i, (x_start, x_end) in enumerate(sprite_regions):
        frame = img.crop((x_start, 0, x_end, height))
        frames.append(frame)
        print(f"  Frame {i+1}: x={x_start}-{x_end}, size={frame.size}")
    
    return frames


def process_frame(frame, target_size=64, max_sprite_size=52):
    """Procesar un frame: limpiar fondo, escalar y centrar"""
    # Limpiar fondo de tablero
    clean = remove_checkerboard_background(frame)
    
    # Encontrar bounds del sprite
    bounds = find_sprite_bounds(clean)
    if bounds is None:
        # Frame vacío
        return Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    
    # Recortar al contenido
    cropped = clean.crop(bounds)
    
    # Escalar si es necesario
    w, h = cropped.size
    max_dim = max(w, h)
    
    if max_dim > max_sprite_size:
        scale = max_sprite_size / max_dim
        new_w = int(w * scale)
        new_h = int(h * scale)
        cropped = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Crear frame final centrado
    result = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - cropped.width) // 2
    paste_y = (target_size - cropped.height) // 2
    result.paste(cropped, (paste_x, paste_y), cropped)
    
    return result


def create_spritesheet(frames, output_path):
    """Crear spritesheet horizontal desde lista de frames"""
    if not frames:
        print(f"  ERROR: No hay frames para crear spritesheet")
        return False
    
    frame_size = frames[0].size[0]
    total_width = frame_size * len(frames)
    
    spritesheet = Image.new("RGBA", (total_width, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * frame_size, 0))
    
    spritesheet.save(output_path, "PNG")
    print(f"  Guardado: {output_path} ({total_width}x{frame_size})")
    return True


def process_animation(anim_name, config):
    """Procesar una animación completa"""
    input_path = os.path.join(INPUT_DIR, config["file"])
    output_path = os.path.join(OUTPUT_DIR, f"{anim_name}.png")
    expected_frames = config["frames"]
    
    print(f"\n{'='*60}")
    print(f"Procesando: {anim_name} ({expected_frames} frames)")
    print(f"{'='*60}")
    
    if not os.path.exists(input_path):
        print(f"  ERROR: No se encontró {input_path}")
        return False
    
    # Cargar imagen
    img = Image.open(input_path)
    print(f"  Imagen original: {img.size}")
    
    # Extraer frames
    raw_frames = extract_frames_auto(img, expected_frames)
    
    if len(raw_frames) != expected_frames:
        print(f"  ADVERTENCIA: Se extrajeron {len(raw_frames)} frames, esperados {expected_frames}")
        # Ajustar si es necesario
        if len(raw_frames) < expected_frames:
            # Duplicar el último frame
            while len(raw_frames) < expected_frames:
                raw_frames.append(raw_frames[-1].copy())
        else:
            raw_frames = raw_frames[:expected_frames]
    
    # Procesar cada frame
    processed_frames = []
    for i, frame in enumerate(raw_frames):
        processed = process_frame(frame, FRAME_SIZE, max_sprite_size=52)
        processed_frames.append(processed)
    
    # Crear spritesheet
    return create_spritesheet(processed_frames, output_path)


def main():
    print("="*60)
    print("PROCESADOR DE SPRITES - FIRE WAND")
    print("="*60)
    
    # Crear directorios
    os.makedirs(INPUT_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print(f"\nDirectorio de entrada: {INPUT_DIR}")
    print(f"Directorio de salida: {OUTPUT_DIR}")
    
    # Verificar archivos de entrada
    missing_files = []
    for anim_name, config in ANIMATIONS.items():
        input_path = os.path.join(INPUT_DIR, config["file"])
        if not os.path.exists(input_path):
            missing_files.append(config["file"])
    
    if missing_files:
        print(f"\n⚠️  Archivos faltantes en {INPUT_DIR}:")
        for f in missing_files:
            print(f"   - {f}")
        print("\nPor favor, copia las imágenes generadas a esa carpeta con los nombres:")
        print("   - flight_raw.png (imagen de vuelo)")
        print("   - impact_raw.png (imagen de impacto)")
        print("   - launch_raw.png (imagen de lanzamiento)")
        return
    
    # Procesar cada animación
    success_count = 0
    for anim_name, config in ANIMATIONS.items():
        if process_animation(anim_name, config):
            success_count += 1
    
    print(f"\n{'='*60}")
    print(f"COMPLETADO: {success_count}/{len(ANIMATIONS)} animaciones procesadas")
    print(f"Sprites guardados en: {OUTPUT_DIR}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
