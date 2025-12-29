"""
Script para procesar sprites de Fire Wand - Versión 3
Detecta tablero gris 221 y 174-177
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
    pixels = np.array(img, dtype=np.int16)  # int16 para evitar overflow
    
    r, g, b, a = pixels[:,:,0], pixels[:,:,1], pixels[:,:,2], pixels[:,:,3]
    
    # Detectar píxeles grises (R ≈ G ≈ B)
    is_gray = (np.abs(r - g) < 20) & (np.abs(g - b) < 20)
    
    # Los grises del tablero están en rangos específicos
    avg_gray = (r + g + b) // 3
    is_checkerboard = is_gray & (
        ((avg_gray >= 165) & (avg_gray <= 185)) |  # Gris oscuro ~174-177
        ((avg_gray >= 210) & (avg_gray <= 230))    # Gris claro ~221
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
    threshold = img.height * 0.02  # 2% del alto debe tener contenido
    
    # Encontrar grupos de columnas con contenido
    in_sprite = False
    regions = []
    start_x = 0
    
    for x in range(width):
        has_content = col_content[x] > threshold
        
        if has_content and not in_sprite:
            start_x = x
            in_sprite = True
        elif not has_content and in_sprite:
            # Verificar gap
            gap_end = x
            while gap_end < width and col_content[gap_end] <= threshold:
                gap_end += 1
                if gap_end - x > 30:  # Gap de más de 30px
                    break
            
            if gap_end - x > 30 or gap_end >= width:
                regions.append((start_x, x))
                in_sprite = False
    
    if in_sprite:
        regions.append((start_x, width))
    
    print(f"  Regiones detectadas: {len(regions)}")
    
    # Si no coincide, dividir equitativamente
    if len(regions) != expected_count:
        print(f"  ⚠️ Ajustando a {expected_count} (división uniforme)")
        w = width // expected_count
        regions = [(i*w, (i+1)*w) for i in range(expected_count)]
    
    return regions


def extract_sprite(img, x1, x2):
    """Extraer y procesar un sprite individual"""
    pixels = np.array(img)
    alpha = pixels[:, :, 3]
    
    # Recortar horizontalmente
    section = img.crop((x1, 0, x2, img.height))
    sec_pixels = np.array(section)
    sec_alpha = sec_pixels[:, :, 3]
    
    # Encontrar bounds del contenido
    rows = np.any(sec_alpha > 30, axis=1)
    cols = np.any(sec_alpha > 30, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))
    
    y1 = np.argmax(rows)
    y2 = len(rows) - np.argmax(rows[::-1])
    cx1 = np.argmax(cols)
    cx2 = len(cols) - np.argmax(cols[::-1])
    
    # Recortar al contenido
    cropped = section.crop((cx1, y1, cx2, y2))
    
    # Escalar si necesario
    w, h = cropped.size
    if max(w, h) > MAX_SPRITE_SIZE:
        scale = MAX_SPRITE_SIZE / max(w, h)
        cropped = cropped.resize((max(1, int(w*scale)), max(1, int(h*scale))), Image.Resampling.LANCZOS)
    
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
    
    print(f"\n{'='*50}")
    print(f"Procesando: {name} ({frames_count} frames)")
    
    img = Image.open(input_path)
    print(f"  Original: {img.size}")
    
    # Limpiar tablero
    clean = remove_gray_checkerboard(img)
    
    # Debug: guardar imagen limpia
    # clean.save(os.path.join(OUTPUT_DIR, f"{name}_clean.png"))
    
    # Encontrar regiones
    regions = find_sprite_regions(clean, frames_count)
    
    # Extraer sprites
    frames = []
    for i, (x1, x2) in enumerate(regions):
        sprite = extract_sprite(clean, x1, x2)
        frames.append(sprite)
        print(f"  Frame {i+1}: x={x1}-{x2}")
    
    # Crear spritesheet
    sheet = Image.new("RGBA", (FRAME_SIZE * len(frames), FRAME_SIZE), (0,0,0,0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME_SIZE, 0))
    
    sheet.save(output_path, "PNG")
    print(f"  ✅ Guardado: {output_path}")
    return True


def main():
    print("="*50)
    print("FIRE WAND SPRITE PROCESSOR v3")
    print("="*50)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for name, config in ANIMATIONS.items():
        process_animation(name, config)
    
    print("\n" + "="*50)
    print("COMPLETADO")


if __name__ == "__main__":
    main()
