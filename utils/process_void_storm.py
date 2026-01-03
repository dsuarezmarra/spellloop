"""
Procesa los sprites de Void Storm para el juego.
Identifica los 6 frames, los recorta, redimensiona y crea un spritesheet uniforme.
"""

from PIL import Image
import os

def find_frame_boundaries(img):
    """Encontrar los límites de cada frame basándose en contenido no transparente"""
    width, height = img.size
    pixels = img.load()
    
    # Buscar columnas con contenido (no completamente transparentes)
    cols_with_content = []
    for x in range(width):
        has_content = False
        for y in range(height):
            if pixels[x, y][3] > 10:  # Alpha > 10
                has_content = True
                break
        cols_with_content.append(has_content)
    
    # Encontrar grupos de columnas con contenido (cada grupo es un frame)
    frames = []
    in_frame = False
    frame_start = 0
    
    for x, has_content in enumerate(cols_with_content):
        if has_content and not in_frame:
            in_frame = True
            frame_start = x
        elif not has_content and in_frame:
            in_frame = False
            frames.append((frame_start, x))
    
    # Si terminamos dentro de un frame
    if in_frame:
        frames.append((frame_start, width))
    
    return frames

def find_vertical_bounds(img, x_start, x_end):
    """Encontrar límites verticales de contenido en un rango horizontal"""
    pixels = img.load()
    height = img.size[1]
    
    y_min = height
    y_max = 0
    
    for x in range(x_start, x_end):
        for y in range(height):
            if pixels[x, y][3] > 10:
                y_min = min(y_min, y)
                y_max = max(y_max, y)
    
    return y_min, y_max + 1

def process_void_storm():
    base_dir = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\void_storm"
    input_file = os.path.join(base_dir, "unnamed-removebg-preview.png")
    
    print("=" * 60)
    print("PROCESANDO VOID STORM SPRITES")
    print("=" * 60)
    
    # Cargar imagen
    img = Image.open(input_file).convert("RGBA")
    print(f"Imagen original: {img.size[0]}x{img.size[1]}")
    
    # Encontrar frames
    frame_bounds = find_frame_boundaries(img)
    print(f"Frames detectados: {len(frame_bounds)}")
    
    for i, (x1, x2) in enumerate(frame_bounds):
        print(f"  Frame {i+1}: x={x1}-{x2} (ancho={x2-x1})")
    
    # Si no detectamos exactamente 6 frames, dividir uniformemente
    if len(frame_bounds) != 6:
        print(f"\n⚠️ No se detectaron exactamente 6 frames. Dividiendo uniformemente...")
        frame_width = img.size[0] // 6
        frame_bounds = [(i * frame_width, (i + 1) * frame_width) for i in range(6)]
        print(f"Usando división uniforme: {frame_width}px por frame")
    
    # Encontrar el bounding box global vertical
    global_y_min = img.size[1]
    global_y_max = 0
    
    for x1, x2 in frame_bounds:
        y_min, y_max = find_vertical_bounds(img, x1, x2)
        global_y_min = min(global_y_min, y_min)
        global_y_max = max(global_y_max, y_max)
    
    print(f"\nLímites verticales globales: y={global_y_min}-{global_y_max}")
    
    # Extraer y procesar cada frame
    frames = []
    max_width = 0
    max_height = global_y_max - global_y_min
    
    for i, (x1, x2) in enumerate(frame_bounds):
        # Recortar frame con límites verticales globales
        frame = img.crop((x1, global_y_min, x2, global_y_max))
        
        # Encontrar bounding box real del contenido
        bbox = frame.getbbox()
        if bbox:
            # Recortar al contenido real
            frame_cropped = frame.crop(bbox)
            frames.append(frame_cropped)
            max_width = max(max_width, frame_cropped.size[0])
            print(f"  Frame {i+1}: {frame_cropped.size[0]}x{frame_cropped.size[1]}")
        else:
            # Frame vacío, crear uno transparente
            frames.append(Image.new("RGBA", (1, 1), (0, 0, 0, 0)))
            print(f"  Frame {i+1}: (vacío)")
    
    # Tamaño objetivo: 64x64 (estándar del proyecto)
    target_size = 64
    
    print(f"\n📐 Redimensionando todos los frames a {target_size}x{target_size}...")
    
    # Redimensionar cada frame manteniendo aspecto y centrando
    resized_frames = []
    for i, frame in enumerate(frames):
        if frame.size[0] <= 1:
            resized_frames.append(Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0)))
            continue
            
        # Calcular escala manteniendo aspecto
        scale = min(target_size / frame.size[0], target_size / frame.size[1])
        new_w = int(frame.size[0] * scale)
        new_h = int(frame.size[1] * scale)
        
        # Redimensionar con alta calidad
        resized = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Centrar en canvas de target_size x target_size
        canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
        offset_x = (target_size - new_w) // 2
        offset_y = (target_size - new_h) // 2
        canvas.paste(resized, (offset_x, offset_y), resized)
        
        resized_frames.append(canvas)
        print(f"  Frame {i+1}: {frame.size} → {new_w}x{new_h} (centrado en {target_size}x{target_size})")
    
    # Crear spritesheet horizontal (6 frames en fila)
    spritesheet_width = target_size * 6
    spritesheet_height = target_size
    spritesheet = Image.new("RGBA", (spritesheet_width, spritesheet_height), (0, 0, 0, 0))
    
    for i, frame in enumerate(resized_frames):
        spritesheet.paste(frame, (i * target_size, 0), frame)
    
    # Guardar spritesheet
    output_file = os.path.join(base_dir, "aoe_active_void_storm.png")
    spritesheet.save(output_file, "PNG")
    print(f"\n✅ Spritesheet guardado: {output_file}")
    print(f"   Tamaño: {spritesheet_width}x{spritesheet_height} (6 frames de {target_size}x{target_size})")
    
    # También guardar frames individuales para referencia
    frames_dir = os.path.join(base_dir, "frames")
    os.makedirs(frames_dir, exist_ok=True)
    
    for i, frame in enumerate(resized_frames):
        frame_file = os.path.join(frames_dir, f"frame_{i+1}.png")
        frame.save(frame_file, "PNG")
    
    print(f"   Frames individuales guardados en: {frames_dir}")
    
    # Crear también versión de impacto (más brillante/expandida)
    print("\n🔥 Creando versión de impacto...")
    impact_frames = []
    
    for i, frame in enumerate(resized_frames):
        # Crear versión más brillante para impacto
        impact = frame.copy()
        pixels = impact.load()
        
        for x in range(target_size):
            for y in range(target_size):
                r, g, b, a = pixels[x, y]
                if a > 0:
                    # Hacer más brillante (más blanco/cyan)
                    r = min(255, int(r * 1.3 + 40))
                    g = min(255, int(g * 1.3 + 40))
                    b = min(255, int(b * 1.3 + 60))
                    pixels[x, y] = (r, g, b, a)
        
        impact_frames.append(impact)
    
    # Spritesheet de impacto
    impact_sheet = Image.new("RGBA", (spritesheet_width, spritesheet_height), (0, 0, 0, 0))
    for i, frame in enumerate(impact_frames):
        impact_sheet.paste(frame, (i * target_size, 0), frame)
    
    impact_file = os.path.join(base_dir, "aoe_impact_void_storm.png")
    impact_sheet.save(impact_file, "PNG")
    print(f"✅ Spritesheet de impacto guardado: {impact_file}")
    
    print("\n" + "=" * 60)
    print("¡PROCESAMIENTO COMPLETADO!")
    print("=" * 60)

if __name__ == "__main__":
    process_void_storm()
