"""
Procesa los sprites del Wizard: extrae frames, crea versiones simétricas y genera spritesheets
"""
from PIL import Image
import os
import numpy as np

BASE_PATH = "c:/git/spellloop/project/assets/sprites/players/wizard"
OUTPUT_PATH = BASE_PATH  # Guardar en el mismo lugar

# Configuración de qué archivo es qué animación
# CORREGIDO basado en feedback del usuario:
# - 31d8c924... muestra personaje de PERFIL (side) 
# - 36771866... muestra personaje mirando hacia CÁMARA (down)
# - 8e826106... muestra personaje de ESPALDAS (up)
SPRITE_CONFIG = {
    "walk": {
        "31d8c924-da4f-483d-81a1-a54cbbc43812-md-removebg-preview.png": "side",  # Perfil - se crea left y right
        "36771866-ca19-4c7e-857b-2b313f3159f2-md-removebg-preview.png": "down",  # Mirando a cámara
        "8e826106-4e19-4ad4-bd59-c5664bcdb5ae-md-removebg-preview.png": "up",    # De espaldas
    },
    "cast": {
        "accf5e7f-fabc-4ee5-9eaf-db2da9d3c968-md-removebg-preview.png": "cast",
    },
    "hit": {
        "67eb37d2-3a7b-49e6-8b5a-cd9bee38281d-md-removebg-preview.png": "hit",
    },
    "death": {
        "59dfe9e5-b2a7-4702-ad2a-49a58fd74766-md-removebg-preview.png": "death",
    }
}

# Tamaño objetivo para los frames (cuadrado para consistencia)
TARGET_SIZE = 128  # px - tamaño estándar para sprites de juego


def detect_frames(img):
    """Detecta frames en una imagen basándose en columnas vacías"""
    arr = np.array(img.convert("RGBA"))
    alpha = arr[:, :, 3]
    col_has_content = np.any(alpha > 10, axis=0)
    
    frames = []
    in_sprite = False
    start_x = 0
    
    for x in range(img.width):
        if col_has_content[x] and not in_sprite:
            in_sprite = True
            start_x = x
        elif not col_has_content[x] and in_sprite:
            in_sprite = False
            frames.append((start_x, x))
    
    if in_sprite:
        frames.append((start_x, img.width))
    
    return frames


def get_content_bounds(img, x_start, x_end):
    """Obtiene los límites exactos del contenido en una región"""
    arr = np.array(img.convert("RGBA"))
    region = arr[:, x_start:x_end, :]
    alpha = region[:, :, 3]
    
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        return None
    
    y_min = np.argmax(rows)
    y_max = len(rows) - np.argmax(rows[::-1])
    x_min = np.argmax(cols)
    x_max = len(cols) - np.argmax(cols[::-1])
    
    return (x_start + x_min, y_min, x_start + x_min + (x_max - x_min), y_max)


def extract_and_resize_frame(img, bounds, target_size, scale_factor=0.9):
    """Extrae un frame y lo redimensiona manteniendo aspecto, centrado en canvas cuadrado
    
    scale_factor: qué porcentaje del canvas usar (0.9 = 90%)
    """
    x1, y1, x2, y2 = bounds
    frame = img.crop((x1, y1, x2, y2))
    
    w, h = frame.size
    
    # Calcular escala manteniendo aspecto
    scale = min(target_size / w, target_size / h) * scale_factor
    
    new_w = int(w * scale)
    new_h = int(h * scale)
    
    # Redimensionar con alta calidad
    frame = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Crear canvas cuadrado y centrar
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    offset_x = (target_size - new_w) // 2
    offset_y = (target_size - new_h) // 2
    canvas.paste(frame, (offset_x, offset_y), frame)
    
    return canvas


def create_spritesheet(frames, direction="horizontal"):
    """Crea un spritesheet a partir de una lista de frames"""
    if not frames:
        return None
    
    frame_size = frames[0].size[0]  # Asumimos cuadrados
    
    if direction == "horizontal":
        sheet = Image.new("RGBA", (frame_size * len(frames), frame_size), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            sheet.paste(frame, (i * frame_size, 0), frame)
    else:
        sheet = Image.new("RGBA", (frame_size, frame_size * len(frames)), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            sheet.paste(frame, (0, i * frame_size), frame)
    
    return sheet


# Factores de escala por tipo de animación
SCALE_FACTORS = {
    "walk": 0.9,
    "side": 0.9,
    "down": 0.9,
    "up": 0.9,
    "cast": 0.9,  # Mismo que los demás, compensar en el juego
    "hit": 0.9,
    "death": 0.9,
}

def process_all_sprites():
    """Procesa todos los sprites según la configuración"""
    
    all_spritesheets = {}
    
    for folder, files in SPRITE_CONFIG.items():
        folder_path = os.path.join(BASE_PATH, folder)
        
        for filename, anim_type in files.items():
            filepath = os.path.join(folder_path, filename)
            
            if not os.path.exists(filepath):
                print(f"❌ No encontrado: {filepath}")
                continue
            
            print(f"\n📄 Procesando: {folder}/{filename}")
            print(f"   Tipo: {anim_type}")
            
            img = Image.open(filepath).convert("RGBA")
            frame_regions = detect_frames(img)
            
            print(f"   Frames detectados: {len(frame_regions)}")
            
            # Obtener factor de escala para este tipo de animación
            scale_factor = SCALE_FACTORS.get(anim_type, 0.9)
            print(f"   Factor de escala: {scale_factor}")
            
            # Extraer frames individuales
            frames = []
            for i, (x_start, x_end) in enumerate(frame_regions):
                bounds = get_content_bounds(img, x_start, x_end)
                if bounds:
                    frame = extract_and_resize_frame(img, bounds, TARGET_SIZE, scale_factor)
                    frames.append(frame)
                    print(f"   Frame {i+1}: extraído y redimensionado a {TARGET_SIZE}x{TARGET_SIZE}")
            
            # Guardar frames individuales y crear spritesheets
            if folder == "walk":
                if anim_type == "side":
                    # Crear versiones left y right
                    # El sprite original mira hacia la derecha, lo usamos como right
                    # y flip horizontal para left
                    
                    # RIGHT (original)
                    right_frames = frames
                    spritesheet_right = create_spritesheet(right_frames)
                    
                    # LEFT (flip horizontal)
                    left_frames = [f.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for f in frames]
                    spritesheet_left = create_spritesheet(left_frames)
                    
                    # Guardar frames individuales
                    for i, frame in enumerate(right_frames):
                        out_path = os.path.join(folder_path, f"wizard_walk_right_{i+1}.png")
                        frame.save(out_path)
                        print(f"   ✓ Guardado: wizard_walk_right_{i+1}.png")
                    
                    for i, frame in enumerate(left_frames):
                        out_path = os.path.join(folder_path, f"wizard_walk_left_{i+1}.png")
                        frame.save(out_path)
                        print(f"   ✓ Guardado: wizard_walk_left_{i+1}.png")
                    
                    # Guardar spritesheets
                    spritesheet_right.save(os.path.join(folder_path, "wizard_walk_right.png"))
                    spritesheet_left.save(os.path.join(folder_path, "wizard_walk_left.png"))
                    print(f"   ✓ Spritesheet: wizard_walk_right.png ({len(right_frames)} frames)")
                    print(f"   ✓ Spritesheet: wizard_walk_left.png ({len(left_frames)} frames)")
                    
                    all_spritesheets["walk_right"] = spritesheet_right
                    all_spritesheets["walk_left"] = spritesheet_left
                    
                else:
                    # down o up
                    for i, frame in enumerate(frames):
                        out_path = os.path.join(folder_path, f"wizard_walk_{anim_type}_{i+1}.png")
                        frame.save(out_path)
                        print(f"   ✓ Guardado: wizard_walk_{anim_type}_{i+1}.png")
                    
                    spritesheet = create_spritesheet(frames)
                    sheet_path = os.path.join(folder_path, f"wizard_walk_{anim_type}.png")
                    spritesheet.save(sheet_path)
                    print(f"   ✓ Spritesheet: wizard_walk_{anim_type}.png ({len(frames)} frames)")
                    
                    all_spritesheets[f"walk_{anim_type}"] = spritesheet
            
            else:
                # cast, hit, death
                for i, frame in enumerate(frames):
                    out_path = os.path.join(folder_path, f"wizard_{anim_type}_{i+1}.png")
                    frame.save(out_path)
                    print(f"   ✓ Guardado: wizard_{anim_type}_{i+1}.png")
                
                spritesheet = create_spritesheet(frames)
                sheet_path = os.path.join(folder_path, f"wizard_{anim_type}.png")
                spritesheet.save(sheet_path)
                print(f"   ✓ Spritesheet: wizard_{anim_type}.png ({len(frames)} frames)")
                
                all_spritesheets[anim_type] = spritesheet
    
    print("\n" + "=" * 60)
    print("RESUMEN DE SPRITESHEETS GENERADOS")
    print("=" * 60)
    for name, sheet in all_spritesheets.items():
        print(f"  ✓ {name}: {sheet.size[0]}x{sheet.size[1]} px")
    
    return all_spritesheets


if __name__ == "__main__":
    print("=" * 60)
    print("PROCESADOR DE SPRITES DEL WIZARD")
    print("=" * 60)
    
    process_all_sprites()
    
    print("\n✅ Procesamiento completado!")
    print("\nEstructura de archivos generada:")
    print("""
wizard/
├── walk/
│   ├── wizard_walk_down.png (spritesheet)
│   ├── wizard_walk_down_1.png ... wizard_walk_down_4.png
│   ├── wizard_walk_up.png (spritesheet)
│   ├── wizard_walk_up_1.png ... wizard_walk_up_4.png
│   ├── wizard_walk_left.png (spritesheet)
│   ├── wizard_walk_left_1.png ... wizard_walk_left_4.png
│   ├── wizard_walk_right.png (spritesheet)
│   └── wizard_walk_right_1.png ... wizard_walk_right_4.png
├── cast/
│   ├── wizard_cast.png (spritesheet)
│   └── wizard_cast_1.png ... wizard_cast_4.png
├── hit/
│   ├── wizard_hit.png (spritesheet)
│   └── wizard_hit_1.png, wizard_hit_2.png
└── death/
    ├── wizard_death.png (spritesheet)
    └── wizard_death_1.png ... wizard_death_4.png
""")
