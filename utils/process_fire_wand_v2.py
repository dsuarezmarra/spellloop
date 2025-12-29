"""
Script para procesar sprites de Fire Wand - Versión 2
Enfoque simple: detectar el tablero de ajedrez gris y hacerlo transparente
"""

from PIL import Image
import numpy as np
import os

# Configuración
INPUT_DIR = r"C:\git\spellloop\utils\fire_wand_raw"
OUTPUT_DIR = r"C:\git\spellloop\project\assets\sprites\projectiles\fire_wand"
FRAME_SIZE = 64
MAX_SPRITE_SIZE = 52

# Configuración por animación
ANIMATIONS = {
    "flight": {"frames": 6, "file": "flight_raw.png"},
    "impact": {"frames": 6, "file": "impact_raw.png"},
    "launch": {"frames": 4, "file": "launch_raw.png"}
}


def is_checkerboard_pixel(r, g, b, a):
    """Detectar si un píxel pertenece al tablero de ajedrez gris"""
    if a < 128:
        return True  # Ya es transparente
    
    # El tablero de ajedrez tiene dos tonos de gris
    # Típicamente: gris claro (~200-210) y gris oscuro (~150-160)
    
    # Verificar si es gris (R ≈ G ≈ B)
    if abs(int(r) - int(g)) > 15 or abs(int(g) - int(b)) > 15:
        return False  # No es gris, tiene color
    
    # Grises típicos del tablero
    avg = (int(r) + int(g) + int(b)) // 3
    
    # Tablero claro: ~200-215
    # Tablero oscuro: ~145-165
    if (195 <= avg <= 220) or (140 <= avg <= 170):
        return True
    
    return False


def remove_checkerboard(img):
    """Eliminar el fondo de tablero de ajedrez"""
    img = img.convert("RGBA")
    pixels = np.array(img)
    
    # Crear máscara de píxeles que NO son tablero
    h, w = pixels.shape[:2]
    result = pixels.copy()
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[y, x]
            if is_checkerboard_pixel(r, g, b, a):
                result[y, x] = [0, 0, 0, 0]
    
    return Image.fromarray(result, "RGBA")


def find_sprites_in_image(img, expected_count):
    """Encontrar los sprites individuales en la imagen"""
    img = img.convert("RGBA")
    
    # Primero, eliminar el tablero de ajedrez
    clean = remove_checkerboard(img)
    pixels = np.array(clean)
    alpha = pixels[:, :, 3]
    
    width, height = clean.size
    
    # Encontrar columnas con contenido
    col_has_content = np.any(alpha > 20, axis=0)
    
    # Encontrar grupos de columnas consecutivas con contenido
    sprites = []
    in_sprite = False
    start_x = 0
    min_gap = 20  # Mínimo espacio entre sprites
    
    for x in range(width):
        if col_has_content[x] and not in_sprite:
            start_x = x
            in_sprite = True
        elif not col_has_content[x] and in_sprite:
            # Verificar si es un gap real
            gap_size = 0
            for gx in range(x, min(x + min_gap + 1, width)):
                if not col_has_content[gx]:
                    gap_size += 1
                else:
                    break
            
            if gap_size >= min_gap:
                sprites.append((start_x, x))
                in_sprite = False
    
    if in_sprite:
        sprites.append((start_x, width))
    
    print(f"  Sprites detectados: {len(sprites)}")
    for i, (s, e) in enumerate(sprites):
        print(f"    Sprite {i+1}: x={s}-{e} (ancho={e-s})")
    
    # Si no detectamos el número correcto, dividir equitativamente
    if len(sprites) != expected_count:
        print(f"  ⚠️ Ajustando a {expected_count} sprites (división equitativa)")
        sprite_width = width // expected_count
        sprites = [(i * sprite_width, (i + 1) * sprite_width) for i in range(expected_count)]
    
    return sprites, clean


def find_vertical_bounds(img):
    """Encontrar los límites verticales del contenido"""
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    
    rows_with_content = np.any(alpha > 20, axis=1)
    
    if not np.any(rows_with_content):
        return 0, img.height
    
    y_min = np.argmax(rows_with_content)
    y_max = len(rows_with_content) - np.argmax(rows_with_content[::-1])
    
    return y_min, y_max


def extract_and_process_sprite(img, x_start, x_end, y_min, y_max):
    """Extraer un sprite y procesarlo"""
    # Recortar el sprite
    sprite = img.crop((x_start, y_min, x_end, y_max))
    
    # Encontrar el bounding box exacto del contenido
    pixels = np.array(sprite)
    alpha = pixels[:, :, 3]
    
    rows = np.any(alpha > 20, axis=1)
    cols = np.any(alpha > 20, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    
    y1 = np.argmax(rows)
    y2 = len(rows) - np.argmax(rows[::-1])
    x1 = np.argmax(cols)
    x2 = len(cols) - np.argmax(cols[::-1])
    
    # Recortar al contenido exacto
    cropped = sprite.crop((x1, y1, x2, y2))
    
    # Escalar si es necesario
    w, h = cropped.size
    max_dim = max(w, h)
    
    if max_dim > MAX_SPRITE_SIZE:
        scale = MAX_SPRITE_SIZE / max_dim
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        cropped = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Centrar en frame final
    result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    paste_x = (FRAME_SIZE - cropped.width) // 2
    paste_y = (FRAME_SIZE - cropped.height) // 2
    result.paste(cropped, (paste_x, paste_y), cropped)
    
    return result


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
    
    # Encontrar sprites y limpiar imagen
    sprite_regions, clean_img = find_sprites_in_image(img, expected_frames)
    
    # Encontrar límites verticales del contenido
    y_min, y_max = find_vertical_bounds(clean_img)
    print(f"  Límites verticales: y={y_min}-{y_max}")
    
    # Procesar cada sprite
    frames = []
    for i, (x_start, x_end) in enumerate(sprite_regions):
        frame = extract_and_process_sprite(clean_img, x_start, x_end, y_min, y_max)
        frames.append(frame)
        print(f"  Frame {i+1}: procesado ({frame.size})")
    
    # Crear spritesheet
    total_width = FRAME_SIZE * len(frames)
    spritesheet = Image.new("RGBA", (total_width, FRAME_SIZE), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * FRAME_SIZE, 0))
    
    spritesheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path} ({total_width}x{FRAME_SIZE})")
    
    return True


def main():
    print("="*60)
    print("PROCESADOR DE SPRITES - FIRE WAND v2")
    print("="*60)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    success = 0
    for anim_name, config in ANIMATIONS.items():
        if process_animation(anim_name, config):
            success += 1
    
    print(f"\n{'='*60}")
    print(f"COMPLETADO: {success}/{len(ANIMATIONS)} animaciones")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
