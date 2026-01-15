"""
Procesar sprites de Paladin y Shadow Blade.
Usa alineamiento por BASE (pies) para evitar drift en animaciones.
"""

from PIL import Image
import numpy as np
import os

FIXED_FRAME_SIZE = 208
TARGET_HEIGHT = 160
MIN_FRAME_WIDTH = 50
FEET_MARGIN = 20  # Margen desde el borde inferior hasta los pies


def get_content_bounds(img, x_start, x_end):
    """Obtiene los bounds del contenido en una región."""
    data = np.array(img)
    alpha = data[:, x_start:x_end, 3]
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    row_idx = np.where(rows)[0]
    col_idx = np.where(cols)[0]
    
    if len(row_idx) == 0 or len(col_idx) == 0:
        return None
    
    return {
        'left': col_idx[0] + x_start,
        'top': row_idx[0],
        'right': col_idx[-1] + x_start + 1,
        'bottom': row_idx[-1] + 1,
        'width': col_idx[-1] - col_idx[0] + 1,
        'height': row_idx[-1] - row_idx[0] + 1,
        'center_x': (col_idx[0] + col_idx[-1]) // 2 + x_start
    }


def find_frames(img):
    """Detecta frames por gaps transparentes."""
    data = np.array(img)
    alpha = data[:, :, 3]
    width = img.size[0]
    
    column_has_content = np.any(alpha > 10, axis=0)
    
    frames = []
    in_frame = False
    frame_start = 0
    
    for x in range(width):
        if column_has_content[x] and not in_frame:
            frame_start = x
            in_frame = True
        elif not column_has_content[x] and in_frame:
            if x - frame_start >= MIN_FRAME_WIDTH:
                frames.append((frame_start, x))
            in_frame = False
    
    if in_frame and width - frame_start >= MIN_FRAME_WIDTH:
        frames.append((frame_start, width))
    
    return frames


def process_animation(img_path, output_dir, char_name, anim_name):
    """Procesa una animación alineando por base."""
    
    if not os.path.exists(img_path):
        print(f"  ⚠️ No encontrado: {img_path}")
        return []
    
    img = Image.open(img_path).convert("RGBA")
    frame_bounds = find_frames(img)
    
    if not frame_bounds:
        print(f"  ⚠️ No se detectaron frames en {anim_name}")
        return []
    
    print(f"  Detectados {len(frame_bounds)} frames")
    
    # Analizar todos los frames
    frame_data = []
    for x_start, x_end in frame_bounds:
        bounds = get_content_bounds(img, x_start, x_end)
        if bounds:
            frame_data.append({
                'x_start': x_start,
                'x_end': x_end,
                **bounds
            })
    
    if not frame_data:
        return []
    
    # Procesar cada frame
    processed = []
    
    for i, fd in enumerate(frame_data):
        # Extraer contenido
        content = img.crop((fd['left'], fd['top'], fd['right'], fd['bottom']))
        
        # Escalar a altura TARGET_HEIGHT
        scale = TARGET_HEIGHT / fd['height']
        new_w = int(fd['width'] * scale)
        new_h = TARGET_HEIGHT
        
        content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Crear canvas
        canvas = Image.new("RGBA", (FIXED_FRAME_SIZE, FIXED_FRAME_SIZE), (0, 0, 0, 0))
        
        # Centrar horizontalmente
        paste_x = (FIXED_FRAME_SIZE - new_w) // 2
        
        # Alinear por BASE (pies) - todos los frames tienen los pies en la misma Y
        paste_y = FIXED_FRAME_SIZE - FEET_MARGIN - new_h
        
        canvas.paste(content, (paste_x, paste_y))
        processed.append(canvas)
        
        print(f"    Frame {i+1}: {fd['width']}x{fd['height']} → {new_w}x{new_h}")
    
    # Guardar frames individuales
    for i, frame in enumerate(processed):
        if anim_name.startswith("walk_"):
            direction = anim_name.replace("walk_", "")
            filename = f"{char_name}_walk_{direction}_{i+1}.png"
        else:
            filename = f"{char_name}_{anim_name}_{i+1}.png"
        
        frame.save(os.path.join(output_dir, filename), "PNG")
    
    # Crear spritesheet
    if processed:
        strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(processed), FIXED_FRAME_SIZE), (0, 0, 0, 0))
        for i, f in enumerate(processed):
            strip.paste(f, (i * FIXED_FRAME_SIZE, 0))
        strip.save(os.path.join(output_dir, f"{anim_name}_strip.png"), "PNG")
        print(f"    ✅ {anim_name}_strip.png")
    
    return processed


def process_character(char_name):
    """Procesa todas las animaciones de un personaje."""
    base_path = rf"c:\git\spellloop\project\assets\sprites\players\{char_name}"
    
    print(f"\n{'='*60}")
    print(f"PROCESANDO: {char_name.upper()}")
    print(f"{'='*60}")
    
    # Walk animations
    walk_path = os.path.join(base_path, "walk")
    if os.path.exists(walk_path):
        print("\n📁 WALK:")
        
        # Walk Down
        print("\n  🚶 walk_down:")
        process_animation(
            os.path.join(walk_path, "walk_down.png"),
            walk_path, char_name, "walk_down"
        )
        
        # Walk Up
        print("\n  🚶 walk_up:")
        process_animation(
            os.path.join(walk_path, "walk_up.png"),
            walk_path, char_name, "walk_up"
        )
        
        # Walk Right
        print("\n  🚶 walk_right:")
        frames_right = process_animation(
            os.path.join(walk_path, "walk_right.png"),
            walk_path, char_name, "walk_right"
        )
        
        # Walk Left (flip de walk_right)
        if frames_right:
            print("\n  🚶 walk_left (flip):")
            flipped = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in frames_right]
            for i, f in enumerate(flipped):
                f.save(os.path.join(walk_path, f"{char_name}_walk_left_{i+1}.png"), "PNG")
            
            strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(flipped), FIXED_FRAME_SIZE), (0, 0, 0, 0))
            for i, f in enumerate(flipped):
                strip.paste(f, (i * FIXED_FRAME_SIZE, 0))
            strip.save(os.path.join(walk_path, "walk_left_strip.png"), "PNG")
            print(f"    ✅ walk_left_strip.png")
    
    # Cast
    cast_path = os.path.join(base_path, "cast")
    if os.path.exists(cast_path):
        cast_file = os.path.join(cast_path, "cast.png")
        if os.path.exists(cast_file):
            print("\n📁 CAST:")
            print("\n  ✨ cast:")
            process_animation(cast_file, cast_path, char_name, "cast")
    
    # Death
    death_path = os.path.join(base_path, "death")
    if os.path.exists(death_path):
        death_file = os.path.join(death_path, "death.png")
        if os.path.exists(death_file):
            print("\n📁 DEATH:")
            print("\n  💀 death:")
            process_animation(death_file, death_path, char_name, "death")
    
    # Hit
    hit_path = os.path.join(base_path, "hit")
    if os.path.exists(hit_path):
        hit_file = os.path.join(hit_path, "hit.png")
        if os.path.exists(hit_file):
            print("\n📁 HIT:")
            print("\n  💥 hit:")
            process_animation(hit_file, hit_path, char_name, "hit")
    
    print(f"\n✅ {char_name.upper()} completado")


def main():
    """Procesa Paladin y Shadow Blade."""
    process_character("paladin")
    process_character("shadow_blade")
    
    print("\n" + "="*60)
    print("✅ TODOS LOS PERSONAJES PROCESADOS")
    print("="*60)


if __name__ == "__main__":
    main()
