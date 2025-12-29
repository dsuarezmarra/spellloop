"""
Script UNIVERSAL para procesar sprites con fondo de tablero gris
Detecta CUALQUIER gris puro (R=G=B) como fondo
"""

from PIL import Image
import numpy as np
import os

INPUT_DIR = r"C:\git\spellloop\utils\fire_wand_raw"
OUTPUT_DIR = r"C:\git\spellloop\project\assets\sprites\projectiles\fire_wand"
FRAME_SIZE = 64
MAX_SPRITE_SIZE = 52

ANIMATIONS = {
    "flight": {"frames": 6, "file": "flight_raw.png"},
    "impact": {"frames": 6, "file": "impact_raw.png"},
    "launch": {"frames": 4, "file": "launch_raw.png"}
}


def detect_checkerboard_colors(img):
    """Detectar automáticamente los colores del tablero de ajedrez"""
    pixels = np.array(img)
    
    # Tomar muestras de las esquinas (que deberían ser fondo)
    h, w = pixels.shape[:2]
    corners = [
        pixels[10:100, 10:100],      # Superior izquierda
        pixels[10:100, w-100:w-10],  # Superior derecha
        pixels[h-100:h-10, 10:100],  # Inferior izquierda
        pixels[h-100:h-10, w-100:w-10]  # Inferior derecha
    ]
    
    grays = []
    for corner in corners:
        flat = corner.reshape(-1, 4)
        for r, g, b, a in flat:
            # Si es gris puro
            if abs(int(r) - int(g)) <= 3 and abs(int(g) - int(b)) <= 3:
                grays.append(int(r))
    
    if not grays:
        return set()
    
    # Los dos grises más comunes son los del tablero
    from collections import Counter
    c = Counter(grays)
    top = c.most_common(10)
    
    # Agrupar grises similares (±10)
    gray_ranges = set()
    for gray_val, _ in top:
        for g in range(gray_val - 10, gray_val + 11):
            gray_ranges.add(g)
    
    return gray_ranges


def remove_checkerboard(img, gray_values):
    """Remover píxeles que son grises puros del tablero"""
    pixels = np.array(img, dtype=np.int16)
    r, g, b, a = pixels[:,:,0], pixels[:,:,1], pixels[:,:,2], pixels[:,:,3]
    
    # Grises puros
    is_pure_gray = (np.abs(r - g) <= 5) & (np.abs(g - b) <= 5)
    
    # Está en el rango del tablero
    gray_min = min(gray_values) if gray_values else 0
    gray_max = max(gray_values) if gray_values else 255
    in_range = (r >= gray_min - 5) & (r <= gray_max + 5)
    
    is_checkerboard = is_pure_gray & in_range
    
    result = pixels.copy().astype(np.uint8)
    result[is_checkerboard, 3] = 0
    
    removed = np.sum(is_checkerboard)
    print(f"  Tablero removido: {removed} píxeles ({100*removed/pixels[:,:,0].size:.1f}%)")
    
    return Image.fromarray(result, "RGBA")


def extract_sprite(img, x1, x2):
    """Extraer sprite de una región"""
    section = img.crop((x1, 0, x2, img.height))
    pixels = np.array(section)
    alpha = pixels[:, :, 3]
    
    # Encontrar bounding box del contenido
    rows = np.any(alpha > 30, axis=1)
    cols = np.any(alpha > 30, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))
    
    y1 = np.argmax(rows)
    y2 = len(rows) - np.argmax(rows[::-1])
    cx1 = np.argmax(cols)
    cx2 = len(cols) - np.argmax(cols[::-1])
    
    cropped = section.crop((cx1, y1, cx2, y2))
    
    # Escalar si es muy grande
    w, h = cropped.size
    print(f"    Sprite: {w}x{h}", end="")
    
    if max(w, h) > MAX_SPRITE_SIZE:
        scale = MAX_SPRITE_SIZE / max(w, h)
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        cropped = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        print(f" → {new_w}x{new_h}")
    else:
        print()
    
    # Centrar en frame
    result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))
    px = (FRAME_SIZE - cropped.width) // 2
    py = (FRAME_SIZE - cropped.height) // 2
    result.paste(cropped, (px, py), cropped)
    
    return result


def process_animation(name, config):
    input_path = os.path.join(INPUT_DIR, config["file"])
    output_path = os.path.join(OUTPUT_DIR, f"{name}.png")
    frames_count = config["frames"]
    
    print(f"\n{'='*60}")
    print(f"Procesando: {name} ({frames_count} frames)")
    
    img = Image.open(input_path).convert("RGBA")
    print(f"  Original: {img.size}")
    
    # Detectar colores del tablero automáticamente
    gray_values = detect_checkerboard_colors(img)
    print(f"  Grises detectados: {min(gray_values)}-{max(gray_values)}" if gray_values else "  No se detectaron grises")
    
    # Remover tablero
    clean = remove_checkerboard(img, gray_values)
    
    # Dividir en frames
    frame_width = img.width // frames_count
    
    frames = []
    for i in range(frames_count):
        x1 = i * frame_width
        x2 = (i + 1) * frame_width
        print(f"  Frame {i+1}: x={x1}-{x2}")
        sprite = extract_sprite(clean, x1, x2)
        frames.append(sprite)
    
    # Crear spritesheet
    sheet = Image.new("RGBA", (FRAME_SIZE * len(frames), FRAME_SIZE), (0,0,0,0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME_SIZE, 0))
    
    sheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path}")


def main():
    print("="*60)
    print("PROCESADOR UNIVERSAL DE SPRITES")
    print("="*60)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for name, config in ANIMATIONS.items():
        process_animation(name, config)
    
    print("\n" + "="*60)
    print("✅ COMPLETADO - Verificando:")
    for name in ANIMATIONS:
        path = os.path.join(OUTPUT_DIR, f"{name}.png")
        if os.path.exists(path):
            img = Image.open(path)
            p = np.array(img)
            opaque = np.sum(p[:,:,3] > 30)
            print(f"  {name}.png: {img.size}, {opaque} px opacos")


if __name__ == "__main__":
    main()
