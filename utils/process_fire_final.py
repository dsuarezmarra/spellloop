"""
Script FINAL para procesar sprites de Fire Wand
Con detección robusta del área de contenido principal
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


def detect_and_remove_checkerboard(img):
    """Detectar y remover tablero de ajedrez gris"""
    pixels = np.array(img, dtype=np.int16)
    
    # Tomar esquinas para detectar grises del tablero
    h, w = pixels.shape[:2]
    corners = [
        pixels[10:100, 10:100],
        pixels[10:100, w-100:w-10],
        pixels[h-100:h-10, 10:100],
        pixels[h-100:h-10, w-100:w-10]
    ]
    
    from collections import Counter
    grays = []
    for corner in corners:
        for row in corner:
            for r, g, b, a in row:
                if abs(int(r)-int(g)) <= 5 and abs(int(g)-int(b)) <= 5:
                    grays.append(int(r))
    
    c = Counter(grays)
    top_grays = [g for g, _ in c.most_common(20)]
    gray_min = min(top_grays) - 10 if top_grays else 0
    gray_max = max(top_grays) + 10 if top_grays else 255
    
    # Remover grises puros en el rango
    r, g, b, a = pixels[:,:,0], pixels[:,:,1], pixels[:,:,2], pixels[:,:,3]
    is_pure_gray = (np.abs(r - g) <= 5) & (np.abs(g - b) <= 5)
    in_range = (r >= gray_min) & (r <= gray_max)
    is_checkerboard = is_pure_gray & in_range
    
    pixels[is_checkerboard, 3] = 0
    
    print(f"  Grises del tablero: {gray_min}-{gray_max}")
    print(f"  Removidos: {np.sum(is_checkerboard)} px ({100*np.sum(is_checkerboard)/is_checkerboard.size:.1f}%)")
    
    return Image.fromarray(pixels.astype(np.uint8), "RGBA")


def find_main_content_band(img):
    """Encontrar la banda horizontal principal de contenido"""
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    
    # Contenido por fila
    row_content = np.sum(alpha > 50, axis=1)
    
    # Buscar la banda con más contenido (usando ventana deslizante)
    best_start = 0
    best_content = 0
    window_size = 400  # Ventana de 400px de alto
    
    for y in range(len(row_content) - window_size):
        content = np.sum(row_content[y:y+window_size])
        if content > best_content:
            best_content = content
            best_start = y
    
    # Expandir la banda hasta encontrar los límites reales
    threshold = np.max(row_content) * 0.05  # 5% del máximo
    
    y1 = best_start
    while y1 > 0 and row_content[y1-1] > threshold:
        y1 -= 1
    
    y2 = best_start + window_size
    while y2 < len(row_content) and row_content[y2] > threshold:
        y2 += 1
    
    print(f"  Banda de contenido: Y={y1}-{y2} (alto={y2-y1})")
    return y1, y2


def extract_sprite(img, x1, x2, y1, y2):
    """Extraer un sprite de la región especificada"""
    # Recortar a la región del frame
    section = img.crop((x1, y1, x2, y2))
    pixels = np.array(section)
    alpha = pixels[:, :, 3]
    
    # Encontrar bounds del contenido dentro de esta sección
    rows = np.any(alpha > 50, axis=1)
    cols = np.any(alpha > 50, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))
    
    sy1 = np.argmax(rows)
    sy2 = len(rows) - np.argmax(rows[::-1])
    sx1 = np.argmax(cols)
    sx2 = len(cols) - np.argmax(cols[::-1])
    
    cropped = section.crop((sx1, sy1, sx2, sy2))
    
    # Mostrar tamaño original
    w, h = cropped.size
    print(f"    Sprite: {w}x{h}", end="")
    
    # Escalar si es necesario
    if max(w, h) > MAX_SPRITE_SIZE:
        scale = MAX_SPRITE_SIZE / max(w, h)
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        cropped = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        print(f" → {cropped.width}x{cropped.height}")
    else:
        print()
    
    # Centrar en frame 64x64
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
    
    # Remover tablero
    clean = detect_and_remove_checkerboard(img)
    
    # Encontrar banda de contenido principal
    y1, y2 = find_main_content_band(clean)
    
    # Dividir horizontalmente
    frame_width = img.width // frames_count
    
    frames = []
    for i in range(frames_count):
        x1 = i * frame_width
        x2 = (i + 1) * frame_width
        print(f"  Frame {i+1}: x={x1}-{x2}, y={y1}-{y2}")
        sprite = extract_sprite(clean, x1, x2, y1, y2)
        frames.append(sprite)
    
    # Crear spritesheet
    sheet = Image.new("RGBA", (FRAME_SIZE * frames_count, FRAME_SIZE), (0,0,0,0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME_SIZE, 0))
    
    sheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path}")


def main():
    print("="*60)
    print("FIRE WAND - PROCESADOR FINAL")
    print("="*60)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for name, config in ANIMATIONS.items():
        process_animation(name, config)
    
    print("\n" + "="*60)
    print("VERIFICACIÓN:")
    for name in ANIMATIONS:
        path = os.path.join(OUTPUT_DIR, f"{name}.png")
        if os.path.exists(path):
            img = Image.open(path)
            p = np.array(img)
            opaque = np.sum(p[:,:,3] > 30)
            print(f"  {name}.png: {img.size}, {opaque} px opacos")
    print("="*60)


if __name__ == "__main__":
    main()
