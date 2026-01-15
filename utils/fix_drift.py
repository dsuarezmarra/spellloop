"""
Script para corregir el drift de animaciones.
Alinea todos los frames de una animación usando la BASE (pies) como punto de anclaje.
"""

from PIL import Image
import numpy as np
import os

FIXED_FRAME_SIZE = 208
TARGET_HEIGHT = 160

def get_content_bounds_and_base(img, x_start, x_end):
    """Obtiene bounds y punto base (centro inferior) del contenido."""
    data = np.array(img)
    alpha = data[:, x_start:x_end, 3]
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    row_idx = np.where(rows)[0]
    col_idx = np.where(cols)[0]
    
    if len(row_idx) == 0 or len(col_idx) == 0:
        return None
    
    top = row_idx[0]
    bottom = row_idx[-1] + 1
    left = col_idx[0] + x_start
    right = col_idx[-1] + x_start + 1
    
    # Centro horizontal del contenido
    center_x = (left + right) // 2
    
    return {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
        'width': right - left,
        'height': bottom - top,
        'center_x': center_x,
        'base_y': bottom  # La base (pies) es el punto de anclaje
    }


def find_frames(img):
    """Encuentra los límites de cada frame."""
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
            if x - frame_start >= 50:
                frames.append((frame_start, x))
            in_frame = False
    
    if in_frame and width - frame_start >= 50:
        frames.append((frame_start, width))
    
    return frames


def process_animation_aligned(img_path, output_dir, char_name, anim_name):
    """Procesa una animación alineando todos los frames por la base."""
    
    if not os.path.exists(img_path):
        print(f"  ⚠️ No encontrado: {img_path}")
        return []
    
    img = Image.open(img_path).convert("RGBA")
    frame_bounds = find_frames(img)
    
    if not frame_bounds:
        print(f"  ⚠️ No se encontraron frames")
        return []
    
    # Paso 1: Analizar todos los frames
    frame_data = []
    for x_start, x_end in frame_bounds:
        data = get_content_bounds_and_base(img, x_start, x_end)
        if data:
            frame_data.append({
                'x_start': x_start,
                'x_end': x_end,
                **data
            })
    
    if not frame_data:
        return []
    
    # Paso 2: Calcular el centro X común (promedio de todos los frames)
    # Esto mantiene el personaje en el mismo lugar horizontalmente
    avg_center_offset = sum(
        (fd['center_x'] - fd['x_start']) - (fd['x_end'] - fd['x_start']) / 2 
        for fd in frame_data
    ) / len(frame_data)
    
    # Paso 3: Procesar cada frame
    processed = []
    
    for i, fd in enumerate(frame_data):
        # Extraer contenido original
        content = img.crop((fd['left'], fd['top'], fd['right'], fd['bottom']))
        
        # Escalar a altura TARGET_HEIGHT
        scale = TARGET_HEIGHT / fd['height']
        new_w = int(fd['width'] * scale)
        new_h = TARGET_HEIGHT
        
        content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Crear canvas
        canvas = Image.new("RGBA", (FIXED_FRAME_SIZE, FIXED_FRAME_SIZE), (0, 0, 0, 0))
        
        # Centrar horizontalmente (mismo X para todos)
        paste_x = (FIXED_FRAME_SIZE - new_w) // 2
        
        # Alinear por la BASE (pies en la misma posición Y)
        # Los pies deben estar a una distancia fija del borde inferior
        feet_margin = 20  # Margen desde el borde inferior hasta los pies
        paste_y = FIXED_FRAME_SIZE - feet_margin - new_h
        
        canvas.paste(content, (paste_x, paste_y))
        processed.append(canvas)
        
        print(f"  Frame {i+1}: {fd['width']}x{fd['height']} → {new_w}x{new_h}")
    
    # Guardar frames
    for i, frame in enumerate(processed):
        if anim_name.startswith("walk_"):
            direction = anim_name.replace("walk_", "")
            filename = f"{char_name}_walk_{direction}_{i+1}.png"
        else:
            filename = f"{char_name}_{anim_name}_{i+1}.png"
        
        frame.save(os.path.join(output_dir, filename), "PNG")
        print(f"  ✅ {filename}")
    
    # Spritesheet
    if processed:
        strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(processed), FIXED_FRAME_SIZE), (0, 0, 0, 0))
        for i, f in enumerate(processed):
            strip.paste(f, (i * FIXED_FRAME_SIZE, 0))
        strip.save(os.path.join(output_dir, f"{anim_name}_strip.png"), "PNG")
    
    return processed


def fix_geomancer():
    """Arregla el drift en las animaciones del Geomancer."""
    base_path = r"c:\git\spellloop\project\assets\sprites\players\geomancer"
    walk_path = os.path.join(base_path, "walk")
    
    print("=" * 60)
    print("CORRIGIENDO DRIFT - GEOMANCER")
    print("=" * 60)
    
    # Procesar walk_up
    print("\n📦 WALK_UP:")
    process_animation_aligned(
        os.path.join(walk_path, "walk_up.png"),
        walk_path, "geomancer", "walk_up"
    )
    
    # Procesar walk_right
    print("\n📦 WALK_RIGHT:")
    frames_right = process_animation_aligned(
        os.path.join(walk_path, "walk_right.png"),
        walk_path, "geomancer", "walk_right"
    )
    
    # Generar walk_left desde walk_right
    if frames_right:
        print("\n📦 WALK_LEFT (flip):")
        flipped = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in frames_right]
        for i, f in enumerate(flipped):
            filename = f"geomancer_walk_left_{i+1}.png"
            f.save(os.path.join(walk_path, filename), "PNG")
            print(f"  ✅ {filename}")
        
        strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(flipped), FIXED_FRAME_SIZE), (0, 0, 0, 0))
        for i, f in enumerate(flipped):
            strip.paste(f, (i * FIXED_FRAME_SIZE, 0))
        strip.save(os.path.join(walk_path, "walk_left_strip.png"), "PNG")
    
    print("\n✅ Drift corregido")


if __name__ == "__main__":
    fix_geomancer()
