"""
Script para procesar sprites de personajes.
TODOS los frames se escalan para tener el MISMO tamaño de contenido final.
"""

from PIL import Image
import os
import numpy as np
import sys

# ============================================================
# CONFIGURACIÓN
# ============================================================

PROJECT_PATH = r"c:\git\spellloop\project"
SPRITES_PATH = os.path.join(PROJECT_PATH, "assets", "sprites", "players")

MIN_FRAME_WIDTH = 50
FIXED_FRAME_SIZE = 208

# Tamaño FINAL del contenido - TODOS los frames se escalan a esto
TARGET_HEIGHT = 160  # Todos los sprites tendrán esta altura

# ============================================================
# FUNCIONES
# ============================================================

def find_frame_boundaries(img):
    """Encuentra frames por columnas transparentes."""
    data = np.array(img)
    alpha = data[:, :, 3]
    width = img.size[0]
    
    column_has_content = np.any(alpha > 10, axis=0)
    
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
    
    return [(s, e) for s, e in raw_frames if (e - s) >= MIN_FRAME_WIDTH]


def get_content_bbox(img, x_start, x_end):
    """Obtiene bounding box del contenido."""
    data = np.array(img)
    alpha = data[:, x_start:x_end, 3]
    
    row_has_content = np.any(alpha > 10, axis=1)
    content_rows = np.where(row_has_content)[0]
    
    col_has_content = np.any(alpha > 10, axis=0)
    content_cols = np.where(col_has_content)[0]
    
    if len(content_rows) == 0 or len(content_cols) == 0:
        return None
    
    top = content_rows[0]
    bottom = content_rows[-1] + 1
    left = content_cols[0] + x_start
    right = content_cols[-1] + x_start + 1
    
    return (left, top, right, bottom)


def process_character(character_name):
    """Procesa todos los sprites de un personaje."""
    base_path = os.path.join(SPRITES_PATH, character_name)
    
    if not os.path.exists(base_path):
        print(f"❌ ERROR: No se encontró: {base_path}")
        return False
    
    print("=" * 60)
    print(f"PROCESADOR - {character_name.upper()}")
    print(f"Todos los frames se escalarán a altura {TARGET_HEIGHT}px")
    print("=" * 60)
    
    sprites_config = {
        "walk_down": os.path.join(base_path, "walk", "walk_down.png"),
        "walk_up": os.path.join(base_path, "walk", "walk_up.png"),
        "walk_right": os.path.join(base_path, "walk", "walk_right.png"),
        "cast": os.path.join(base_path, "cast", "cast.png"),
        "death": os.path.join(base_path, "death", "death.png"),
        "hit": os.path.join(base_path, "hit", "hit.png"),
    }
    
    output_dirs = {
        "walk": os.path.join(base_path, "walk"),
        "cast": os.path.join(base_path, "cast"),
        "death": os.path.join(base_path, "death"),
        "hit": os.path.join(base_path, "hit"),
    }
    
    for d in output_dirs.values():
        os.makedirs(d, exist_ok=True)
    
    for name, path in sprites_config.items():
        if not os.path.exists(path):
            print(f"\n⚠️ {name}: No encontrado")
            continue
        
        print(f"\n📦 {name.upper()}:")
        
        img = Image.open(path).convert("RGBA")
        frames = find_frame_boundaries(img)
        
        if "walk" in name:
            output_dir = output_dirs["walk"]
        elif "cast" in name:
            output_dir = output_dirs["cast"]
        elif "death" in name:
            output_dir = output_dirs["death"]
        else:
            output_dir = output_dirs["hit"]
        
        processed_frames = []
        
        for i, (x_start, x_end) in enumerate(frames):
            bbox = get_content_bbox(img, x_start, x_end)
            if not bbox:
                continue
            
            left, top, right, bottom = bbox
            orig_w = right - left
            orig_h = bottom - top
            
            # Extraer contenido
            content = img.crop((left, top, right, bottom))
            
            # Escalar para que la ALTURA sea TARGET_HEIGHT
            scale = TARGET_HEIGHT / orig_h
            new_h = TARGET_HEIGHT
            new_w = int(orig_w * scale)
            
            content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Centrar en canvas
            canvas = Image.new("RGBA", (FIXED_FRAME_SIZE, FIXED_FRAME_SIZE), (0, 0, 0, 0))
            paste_x = (FIXED_FRAME_SIZE - new_w) // 2
            paste_y = (FIXED_FRAME_SIZE - new_h) // 2
            canvas.paste(content, (paste_x, paste_y))
            
            processed_frames.append(canvas)
            print(f"  Frame {i+1}: {orig_w}x{orig_h} → {new_w}x{new_h}")
        
        # Guardar frames
        for i, frame in enumerate(processed_frames):
            if name.startswith("walk_"):
                direction = name.replace("walk_", "")
                filename = f"{character_name}_walk_{direction}_{i+1}.png"
            else:
                filename = f"{character_name}_{name}_{i+1}.png"
            
            frame.save(os.path.join(output_dir, filename), "PNG")
            print(f"  ✅ {filename}")
        
        # Spritesheet
        if processed_frames:
            strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(processed_frames), FIXED_FRAME_SIZE), (0, 0, 0, 0))
            for i, f in enumerate(processed_frames):
                strip.paste(f, (i * FIXED_FRAME_SIZE, 0))
            strip.save(os.path.join(output_dir, f"{name}_strip.png"), "PNG")
        
        # walk_left desde walk_right
        if name == "walk_right" and processed_frames:
            print(f"\n📦 WALK_LEFT (flip):")
            flipped = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in processed_frames]
            for i, f in enumerate(flipped):
                filename = f"{character_name}_walk_left_{i+1}.png"
                f.save(os.path.join(output_dirs["walk"], filename), "PNG")
                print(f"  ✅ {filename}")
            
            strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(flipped), FIXED_FRAME_SIZE), (0, 0, 0, 0))
            for i, f in enumerate(flipped):
                strip.paste(f, (i * FIXED_FRAME_SIZE, 0))
            strip.save(os.path.join(output_dirs["walk"], "walk_left_strip.png"), "PNG")
    
    print(f"\n✅ {character_name} completado - todos los frames tienen altura {TARGET_HEIGHT}px")
    return True


def main():
    if len(sys.argv) < 2:
        print("USO: python process_character_sprites.py <personaje>")
        return
    
    process_character(sys.argv[1].lower())


if __name__ == "__main__":
    main()
