"""
Script para procesar sprites de thunder_bloom
Detecta grises puros como fondo de tablero de ajedrez
"""

from PIL import Image
import numpy as np
import os

INPUT_DIR = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\thunder_bloom"
OUTPUT_DIR = INPUT_DIR
FRAME_SIZE = 64
MAX_SPRITE_SIZE = 54  # 5px padding on each side

ANIMATIONS = {
    "flight": {"frames": 6, "file": "flight.png"},
    "impact": {"frames": 6, "file": "impact.png"},
}


def detect_checkerboard_colors(img):
    """Detectar automáticamente los colores del tablero de ajedrez"""
    pixels = np.array(img)
    
    h, w = pixels.shape[:2]
    sample_size = min(50, h//4, w//4)
    
    corners = [
        pixels[5:sample_size, 5:sample_size],
        pixels[5:sample_size, w-sample_size:w-5],
        pixels[h-sample_size:h-5, 5:sample_size],
        pixels[h-sample_size:h-5, w-sample_size:w-5]
    ]
    
    grays = []
    for corner in corners:
        flat = corner.reshape(-1, 4) if len(corner.shape) == 3 else corner.reshape(-1, 3)
        for pixel in flat:
            r, g, b = pixel[0], pixel[1], pixel[2]
            if abs(int(r) - int(g)) <= 5 and abs(int(g) - int(b)) <= 5:
                grays.append(int(r))
    
    if not grays:
        return set()
    
    from collections import Counter
    c = Counter(grays)
    top = c.most_common(10)
    
    checker_grays = set()
    for val, count in top:
        if count > 50:
            for nearby in range(val - 8, val + 9):
                checker_grays.add(nearby)
    
    return checker_grays


def remove_checkerboard(img, checker_grays):
    """Eliminar fondo de tablero de ajedrez"""
    pixels = np.array(img)
    
    for y in range(pixels.shape[0]):
        for x in range(pixels.shape[1]):
            r, g, b = pixels[y, x, 0], pixels[y, x, 1], pixels[y, x, 2]
            
            if abs(int(r) - int(g)) <= 5 and abs(int(g) - int(b)) <= 5:
                if int(r) in checker_grays:
                    pixels[y, x, 3] = 0
    
    return Image.fromarray(pixels)


def find_valleys(projection, num_frames):
    """Encontrar valles en la proyección para separar frames"""
    from scipy.ndimage import gaussian_filter1d
    from scipy.signal import argrelmin
    
    smooth = gaussian_filter1d(projection.astype(float), sigma=3)
    
    valleys, = argrelmin(smooth, order=10)
    
    if len(valleys) < num_frames - 1:
        valleys, = argrelmin(smooth, order=5)
    
    expected_width = len(projection) / num_frames
    filtered_valleys = []
    
    for v in valleys:
        expected_pos = expected_width * (len(filtered_valleys) + 1)
        if abs(v - expected_pos) < expected_width * 0.4:
            filtered_valleys.append(v)
            if len(filtered_valleys) >= num_frames - 1:
                break
    
    return filtered_valleys


def extract_sprite(img, x1, x2):
    """Extraer un sprite de la imagen"""
    region = img.crop((x1, 0, x2, img.height))
    pixels = np.array(region)
    
    alpha = pixels[:, :, 3]
    rows = np.any(alpha > 30, axis=1)
    cols = np.any(alpha > 30, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        return result
    
    y1, y2 = np.where(rows)[0][[0, -1]]
    x1_content, x2_content = np.where(cols)[0][[0, -1]]
    
    content = region.crop((x1_content, y1, x2_content + 1, y2 + 1))
    
    # Escalar si es necesario
    w, h = content.size
    if w > MAX_SPRITE_SIZE or h > MAX_SPRITE_SIZE:
        scale = min(MAX_SPRITE_SIZE / w, MAX_SPRITE_SIZE / h)
        new_w, new_h = int(w * scale), int(h * scale)
        content = content.resize((new_w, new_h), Image.NEAREST)
    
    # Centrar en frame
    result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x_off = (FRAME_SIZE - content.width) // 2
    y_off = (FRAME_SIZE - content.height) // 2
    result.paste(content, (x_off, y_off))
    
    return result


def process_animation(name, config):
    input_path = os.path.join(INPUT_DIR, config["file"])
    output_path = os.path.join(OUTPUT_DIR, f"{name}_spritesheet_thunder_bloom.png")
    num_frames = config["frames"]
    
    print(f"\n{'='*60}")
    print(f"Procesando: {name} ({num_frames} frames)")
    
    if not os.path.exists(input_path):
        print(f"  ❌ No existe: {input_path}")
        return
    
    img = Image.open(input_path).convert("RGBA")
    print(f"  Tamaño original: {img.size}")
    
    checker_grays = detect_checkerboard_colors(img)
    print(f"  Grises detectados: {len(checker_grays)} tonos")
    
    if checker_grays:
        clean = remove_checkerboard(img, checker_grays)
    else:
        clean = img
    
    # Encontrar frames usando valles
    pixels = np.array(clean)
    projection = np.sum(pixels[:, :, 3] > 30, axis=0)
    
    valleys = find_valleys(projection, num_frames)
    print(f"  Valles encontrados: {valleys}")
    
    # Crear límites de frames
    boundaries = [0] + valleys + [img.width]
    
    if len(boundaries) < num_frames + 1:
        print(f"  ⚠️ Usando división uniforme")
        frame_width = img.width // num_frames
        boundaries = [i * frame_width for i in range(num_frames + 1)]
    
    frames = []
    for i in range(num_frames):
        x1 = boundaries[i]
        x2 = boundaries[i + 1] if i + 1 < len(boundaries) else img.width
        print(f"  Frame {i+1}: x={x1}-{x2}")
        sprite = extract_sprite(clean, x1, x2)
        frames.append(sprite)
    
    # Crear spritesheet
    sheet = Image.new("RGBA", (FRAME_SIZE * len(frames), FRAME_SIZE), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME_SIZE, 0))
    
    sheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path}")


def main():
    print("="*60)
    print("PROCESADOR DE SPRITES - THUNDER BLOOM")
    print("="*60)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for name, config in ANIMATIONS.items():
        process_animation(name, config)
    
    print("\n" + "="*60)
    print("✅ COMPLETADO - Verificando:")
    for name in ANIMATIONS:
        path = os.path.join(OUTPUT_DIR, f"{name}_spritesheet_thunder_bloom.png")
        if os.path.exists(path):
            img = Image.open(path)
            p = np.array(img)
            opaque = np.sum(p[:, :, 3] > 30)
            print(f"  {name}_spritesheet_thunder_bloom.png: {img.size}, {opaque} px opacos")


if __name__ == "__main__":
    main()
