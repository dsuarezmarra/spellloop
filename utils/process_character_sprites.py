"""
Script GENÉRICO para procesar sprites de personajes.
Detecta frames por gaps transparentes, los extrae y los escala uniformemente.

IMPORTANTE: Todos los frames de un personaje se escalan con el MISMO factor,
basado en el frame más grande. Esto garantiza consistencia visual.
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

# Umbral mínimo de ancho de frame (para filtrar ruido)
MIN_FRAME_WIDTH = 50

# Tamaño FIJO del canvas de salida
FIXED_FRAME_SIZE = 208

# Tamaño OBJETIVO del contenido más grande
# El frame más grande se escalará para caber aquí
# Los demás frames se escalarán con el MISMO factor
CONTENT_TARGET_SIZE = 170

# ============================================================
# FUNCIONES
# ============================================================

def get_character_path(character_name):
    return os.path.join(SPRITES_PATH, character_name)


def find_frame_boundaries(img):
    """
    Encuentra los límites de cada frame en un spritesheet.
    Busca columnas completamente transparentes como separadores.
    Retorna lista de (x_start, x_end) para cada frame.
    """
    data = np.array(img)
    alpha = data[:, :, 3]
    width = img.size[0]
    
    # Encontrar columnas con contenido (alpha > 10 en algún píxel)
    column_has_content = np.any(alpha > 10, axis=0)
    
    # Detectar frames
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
    
    # Filtrar ruido
    frames = [(s, e) for s, e in raw_frames if (e - s) >= MIN_FRAME_WIDTH]
    
    return frames


def get_content_bbox(img, x_start, x_end):
    """
    Obtiene el bounding box exacto del contenido dentro de un frame.
    Retorna (left, top, right, bottom, width, height) del contenido.
    """
    data = np.array(img)
    alpha = data[:, x_start:x_end, 3]
    
    # Filas con contenido
    row_has_content = np.any(alpha > 10, axis=1)
    content_rows = np.where(row_has_content)[0]
    
    # Columnas con contenido (relativas al frame)
    col_has_content = np.any(alpha > 10, axis=0)
    content_cols = np.where(col_has_content)[0]
    
    if len(content_rows) == 0 or len(content_cols) == 0:
        return None
    
    top = content_rows[0]
    bottom = content_rows[-1] + 1
    left = content_cols[0] + x_start
    right = content_cols[-1] + x_start + 1
    
    width = right - left
    height = bottom - top
    
    return (left, top, right, bottom, width, height)


def analyze_all_sprites(base_path, sprites_config):
    """
    Analiza todos los sprites de un personaje y encuentra el tamaño máximo.
    Retorna: dict con análisis de cada sprite y el tamaño máximo encontrado.
    """
    all_data = {}
    max_width = 0
    max_height = 0
    
    for name, path in sprites_config.items():
        if not os.path.exists(path):
            print(f"  ⚠️ No encontrado: {name}")
            continue
        
        img = Image.open(path).convert("RGBA")
        frames = find_frame_boundaries(img)
        
        print(f"\n  {name}: {len(frames)} frames detectados")
        
        frame_data = []
        for i, (x_start, x_end) in enumerate(frames):
            bbox = get_content_bbox(img, x_start, x_end)
            if bbox:
                left, top, right, bottom, w, h = bbox
                frame_data.append({
                    'x_start': x_start,
                    'x_end': x_end,
                    'bbox': (left, top, right, bottom),
                    'content_width': w,
                    'content_height': h
                })
                print(f"    Frame {i+1}: contenido {w}x{h}")
                
                if w > max_width:
                    max_width = w
                if h > max_height:
                    max_height = h
        
        all_data[name] = {
            'img': img,
            'frames': frame_data
        }
    
    return all_data, max_width, max_height


def process_character(character_name):
    """Procesa todos los sprites de un personaje."""
    base_path = get_character_path(character_name)
    
    if not os.path.exists(base_path):
        print(f"❌ ERROR: No se encontró: {base_path}")
        return False
    
    print("=" * 60)
    print(f"PROCESADOR DE SPRITES - {character_name.upper()}")
    print("=" * 60)
    
    # Configurar sprites a procesar
    sprites_config = {
        "walk_down": os.path.join(base_path, "walk", "walk_down.png"),
        "walk_up": os.path.join(base_path, "walk", "walk_up.png"),
        "walk_right": os.path.join(base_path, "walk", "walk_right.png"),
        "cast": os.path.join(base_path, "cast", "cast.png"),
        "death": os.path.join(base_path, "death", "death.png"),
        "hit": os.path.join(base_path, "hit", "hit.png"),
    }
    
    # PASO 1: Analizar TODOS los sprites y encontrar el tamaño máximo
    print("\n" + "=" * 60)
    print("PASO 1: ANALIZANDO TODOS LOS FRAMES")
    print("=" * 60)
    
    all_data, max_w, max_h = analyze_all_sprites(base_path, sprites_config)
    
    if not all_data:
        print("❌ No hay sprites para procesar")
        return False
    
    print(f"\n📏 Tamaño máximo encontrado: {max_w}x{max_h}")
    
    # PASO 2: Calcular el factor de escala ÚNICO
    print("\n" + "=" * 60)
    print("PASO 2: CALCULANDO ESCALA UNIFORME")
    print("=" * 60)
    
    # El frame más grande debe caber en CONTENT_TARGET_SIZE
    scale_x = CONTENT_TARGET_SIZE / max_w
    scale_y = CONTENT_TARGET_SIZE / max_h
    scale = min(scale_x, scale_y)
    
    # No agrandar si ya es pequeño
    if scale > 1.0:
        scale = 1.0
    
    print(f"Factor de escala ÚNICO para todos los frames: {scale:.4f}")
    print(f"Tamaño máximo después de escalar: {int(max_w * scale)}x{int(max_h * scale)}")
    
    # PASO 3: Procesar cada frame con el mismo factor de escala
    print("\n" + "=" * 60)
    print("PASO 3: PROCESANDO FRAMES")
    print("=" * 60)
    
    output_dirs = {
        "walk": os.path.join(base_path, "walk"),
        "cast": os.path.join(base_path, "cast"),
        "death": os.path.join(base_path, "death"),
        "hit": os.path.join(base_path, "hit"),
    }
    
    for dir_path in output_dirs.values():
        os.makedirs(dir_path, exist_ok=True)
    
    all_processed = {}
    
    for name, data in all_data.items():
        print(f"\n📦 {name.upper()}:")
        img = data['img']
        frames = data['frames']
        processed_frames = []
        
        for i, frame_info in enumerate(frames):
            left, top, right, bottom = frame_info['bbox']
            orig_w = frame_info['content_width']
            orig_h = frame_info['content_height']
            
            # Extraer contenido
            content = img.crop((left, top, right, bottom))
            
            # Escalar con el factor ÚNICO
            new_w = int(orig_w * scale)
            new_h = int(orig_h * scale)
            
            if scale < 1.0:
                content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Crear canvas y centrar
            canvas = Image.new("RGBA", (FIXED_FRAME_SIZE, FIXED_FRAME_SIZE), (0, 0, 0, 0))
            paste_x = (FIXED_FRAME_SIZE - new_w) // 2
            paste_y = (FIXED_FRAME_SIZE - new_h) // 2
            canvas.paste(content, (paste_x, paste_y))
            
            processed_frames.append(canvas)
            print(f"  Frame {i+1}: {orig_w}x{orig_h} → {new_w}x{new_h}")
        
        all_processed[name] = processed_frames
        
        # Determinar carpeta de salida
        if "walk" in name:
            output_dir = output_dirs["walk"]
        elif "cast" in name:
            output_dir = output_dirs["cast"]
        elif "death" in name:
            output_dir = output_dirs["death"]
        else:
            output_dir = output_dirs["hit"]
        
        # Guardar frames individuales
        for i, frame in enumerate(processed_frames):
            if name.startswith("walk_"):
                direction = name.replace("walk_", "")
                filename = f"{character_name}_walk_{direction}_{i+1}.png"
            else:
                filename = f"{character_name}_{name}_{i+1}.png"
            
            output_path = os.path.join(output_dir, filename)
            frame.save(output_path, "PNG")
            print(f"  ✅ {filename}")
        
        # Crear spritesheet
        if processed_frames:
            strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(processed_frames), FIXED_FRAME_SIZE), (0, 0, 0, 0))
            for i, frame in enumerate(processed_frames):
                strip.paste(frame, (i * FIXED_FRAME_SIZE, 0))
            strip_path = os.path.join(output_dir, f"{name}_strip.png")
            strip.save(strip_path, "PNG")
            print(f"  ✅ {name}_strip.png")
        
        # Generar walk_left desde walk_right
        if name == "walk_right" and processed_frames:
            print(f"\n📦 WALK_LEFT (volteado):")
            flipped = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in processed_frames]
            
            for i, frame in enumerate(flipped):
                filename = f"{character_name}_walk_left_{i+1}.png"
                output_path = os.path.join(output_dirs["walk"], filename)
                frame.save(output_path, "PNG")
                print(f"  ✅ {filename}")
            
            strip = Image.new("RGBA", (FIXED_FRAME_SIZE * len(flipped), FIXED_FRAME_SIZE), (0, 0, 0, 0))
            for i, frame in enumerate(flipped):
                strip.paste(frame, (i * FIXED_FRAME_SIZE, 0))
            strip.save(os.path.join(output_dirs["walk"], "walk_left_strip.png"), "PNG")
            print(f"  ✅ walk_left_strip.png")
    
    # Resumen
    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"✅ Personaje: {character_name}")
    print(f"✅ Canvas: {FIXED_FRAME_SIZE}x{FIXED_FRAME_SIZE}")
    print(f"✅ Tamaño máximo original: {max_w}x{max_h}")
    print(f"✅ Factor de escala aplicado: {scale:.4f}")
    print(f"✅ Todos los frames escalados uniformemente")
    
    return True


def main():
    if len(sys.argv) < 2:
        print("USO: python process_character_sprites.py <personaje>")
        print("\nPERSONAJES:")
        if os.path.exists(SPRITES_PATH):
            for d in sorted(os.listdir(SPRITES_PATH)):
                if os.path.isdir(os.path.join(SPRITES_PATH, d)):
                    print(f"  - {d}")
        return
    
    character = sys.argv[1].lower()
    success = process_character(character)
    
    if success:
        print("\n✅ Completado")
    else:
        print("\n❌ Error")
        sys.exit(1)


if __name__ == "__main__":
    main()
