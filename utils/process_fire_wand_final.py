"""
Script para procesar sprites de Fire Wand - Versión FINAL
Detecta tablero gris exacto: 157-171 (oscuro) y 212-224 (claro)
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


def remove_gray_checkerboard(img):
    """Eliminar el fondo gris del tablero de ajedrez"""
    img = img.convert("RGBA")
    pixels = np.array(img, dtype=np.int16)
    
    r, g, b, a = pixels[:,:,0], pixels[:,:,1], pixels[:,:,2], pixels[:,:,3]
    
    # Detectar píxeles grises (R ≈ G ≈ B)
    is_gray = (np.abs(r - g) < 15) & (np.abs(g - b) < 15)
    
    # Grises del tablero: 155-175 (oscuro) y 210-230 (claro)
    is_checkerboard = is_gray & (
        ((r >= 155) & (r <= 175)) |
        ((r >= 210) & (r <= 230))
    )
    
    # Hacer transparentes los píxeles del tablero
    result = pixels.copy().astype(np.uint8)
    result[is_checkerboard, 3] = 0
    
    return Image.fromarray(result, "RGBA")


def find_sprite_regions(img, expected_count):
    """Encontrar regiones de sprites en la imagen limpia"""
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    width = img.width
    
    # Contenido por columna
    col_content = np.sum(alpha > 30, axis=0)
    threshold = img.height * 0.01  # 1% del alto
    
    # Encontrar grupos
    in_sprite = False
    regions = []
    start_x = 0
    min_gap = 50  # 50px mínimo entre sprites
    
    for x in range(width):
        has_content = col_content[x] > threshold
        
        if has_content and not in_sprite:
            start_x = x
            in_sprite = True
        elif not has_content and in_sprite:
            gap_size = 0
            for gx in range(x, min(x + min_gap + 10, width)):
                if col_content[gx] <= threshold:
                    gap_size += 1
                else:
                    break
            
            if gap_size >= min_gap:
                regions.append((start_x, x))
                in_sprite = False
    
    if in_sprite:
        regions.append((start_x, width))
    
    print(f"  Regiones detectadas: {len(regions)}")
    for i, (s, e) in enumerate(regions):
        print(f"    [{i+1}] x={s}-{e} (ancho={e-s})")
    
    if len(regions) != expected_count:
        print(f"  ⚠️ Ajustando a {expected_count}")
        w = width // expected_count
        regions = [(i*w, (i+1)*w) for i in range(expected_count)]
    
    return regions


def extract_sprite(img, x1, x2):
    """Extraer y procesar un sprite"""
    section = img.crop((x1, 0, x2, img.height))
    sec_pixels = np.array(section)
    sec_alpha = sec_pixels[:, :, 3]
    
    rows = np.any(sec_alpha > 30, axis=1)
    cols = np.any(sec_alpha > 30, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))
    
    y1 = np.argmax(rows)
    y2 = len(rows) - np.argmax(rows[::-1])
    cx1 = np.argmax(cols)
    cx2 = len(cols) - np.argmax(cols[::-1])
    
    cropped = section.crop((cx1, y1, cx2, y2))
    
    w, h = cropped.size
    if max(w, h) > MAX_SPRITE_SIZE:
        scale = MAX_SPRITE_SIZE / max(w, h)
        cropped = cropped.resize((max(1, int(w*scale)), max(1, int(h*scale))), Image.Resampling.LANCZOS)
    
    result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))
    px = (FRAME_SIZE - cropped.width) // 2
    py = (FRAME_SIZE - cropped.height) // 2
    result.paste(cropped, (px, py), cropped)
    
    return result


def process_animation(name, config):
    input_path = os.path.join(INPUT_DIR, config["file"])
    output_path = os.path.join(OUTPUT_DIR, f"{name}.png")
    frames_count = config["frames"]
    
    print(f"\n{'='*50}")
    print(f"Procesando: {name} ({frames_count} frames)")
    
    img = Image.open(input_path)
    print(f"  Original: {img.size}")
    
    clean = remove_gray_checkerboard(img)
    
    # Guardar debug
    clean.save(os.path.join(OUTPUT_DIR, f"{name}_debug.png"))
    print(f"  Debug guardado: {name}_debug.png")
    
    regions = find_sprite_regions(clean, frames_count)
    
    frames = []
    for i, (x1, x2) in enumerate(regions):
        sprite = extract_sprite(clean, x1, x2)
        frames.append(sprite)
    
    sheet = Image.new("RGBA", (FRAME_SIZE * len(frames), FRAME_SIZE), (0,0,0,0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME_SIZE, 0))
    
    sheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path}")
    return True


def main():
    print("="*50)
    print("FIRE WAND PROCESSOR - FINAL")
    print("="*50)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for name, config in ANIMATIONS.items():
        process_animation(name, config)
    
    print("\n✅ COMPLETADO")


if __name__ == "__main__":
    main()
