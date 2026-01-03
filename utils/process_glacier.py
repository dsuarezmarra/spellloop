from PIL import Image, ImageEnhance
import os
import numpy as np

def analyze_image_structure(img):
    """Analiza la imagen para encontrar las regiones con contenido."""
    data = np.array(img)
    
    # Obtener canal alpha
    if data.shape[2] == 4:
        alpha = data[:, :, 3]
    else:
        alpha = np.mean(data[:, :, :3], axis=2)
    
    # Encontrar filas y columnas con contenido
    row_has_content = np.any(alpha > 10, axis=1)
    col_has_content = np.any(alpha > 10, axis=0)
    
    # Encontrar grupos de filas con contenido
    row_groups = []
    in_group = False
    start = 0
    for i, has_content in enumerate(row_has_content):
        if has_content and not in_group:
            start = i
            in_group = True
        elif not has_content and in_group:
            row_groups.append((start, i - 1))
            in_group = False
    if in_group:
        row_groups.append((start, len(row_has_content) - 1))
    
    # Encontrar grupos de columnas con contenido
    col_groups = []
    in_group = False
    start = 0
    for i, has_content in enumerate(col_has_content):
        if has_content and not in_group:
            start = i
            in_group = True
        elif not has_content and in_group:
            col_groups.append((start, i - 1))
            in_group = False
    if in_group:
        col_groups.append((start, len(col_has_content) - 1))
    
    return row_groups, col_groups

def process_glacier():
    print("=" * 60)
    print("PROCESANDO GLACIER SPRITES (MÁXIMA CALIDAD)")
    print("=" * 60)
    
    # Rutas
    input_dir = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\glacier"
    input_file = os.path.join(input_dir, "unnamed-removebg-preview.png")
    output_active = os.path.join(input_dir, "aoe_active_glacier.png")
    output_impact = os.path.join(input_dir, "aoe_impact_glacier.png")
    frames_dir = os.path.join(input_dir, "frames")
    
    os.makedirs(frames_dir, exist_ok=True)
    
    # Cargar imagen
    img = Image.open(input_file).convert("RGBA")
    print(f"Imagen original: {img.width}x{img.height}")
    
    # Analizar estructura
    row_groups, col_groups = analyze_image_structure(img)
    
    print(f"\n📊 Estructura detectada:")
    print(f"   Filas: {len(row_groups)}, Columnas: {len(col_groups)}")
    
    # Extraer frames
    frames = []
    print(f"\n🎯 Extrayendo frames:")
    
    frame_num = 1
    for row_idx, (row_start, row_end) in enumerate(row_groups):
        for col_idx, (col_start, col_end) in enumerate(col_groups):
            frame = img.crop((col_start, row_start, col_end + 1, row_end + 1))
            frames.append(frame)
            print(f"   Frame {frame_num}: {frame.width}x{frame.height}")
            frame_num += 1
    
    # ALTA CALIDAD: Usar LANCZOS (mejor interpolación)
    target_size = 64
    resized_frames = []
    
    print(f"\n📐 Redimensionando a {target_size}x{target_size} con LANCZOS...")
    
    for i, frame in enumerate(frames):
        # Recortar contenido real (quitar padding transparente)
        bbox = frame.getbbox()
        if bbox:
            content = frame.crop(bbox)
        else:
            content = frame
        
        # Calcular escala para que quepa con un pequeño margen
        usable_size = target_size - 4  # 2px margen cada lado
        scale = min(usable_size / content.width, usable_size / content.height)
        new_w = max(1, int(content.width * scale))
        new_h = max(1, int(content.height * scale))
        
        # LANCZOS = máxima calidad de interpolación
        resized = content.resize((new_w, new_h), Image.LANCZOS)
        
        # Crear canvas 64x64 y centrar
        canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
        paste_x = (target_size - new_w) // 2
        paste_y = (target_size - new_h) // 2
        canvas.paste(resized, (paste_x, paste_y))
        
        resized_frames.append(canvas)
        print(f"   Frame {i+1}: {content.width}x{content.height} → {new_w}x{new_h}")
        
        # Guardar frame individual
        canvas.save(os.path.join(frames_dir, f"frame_{i+1}.png"))
    
    # Crear spritesheet horizontal
    spritesheet = Image.new("RGBA", (target_size * len(resized_frames), target_size), (0, 0, 0, 0))
    for i, frame in enumerate(resized_frames):
        spritesheet.paste(frame, (i * target_size, 0))
    
    spritesheet.save(output_active, optimize=False)
    print(f"\n✅ Spritesheet: {output_active}")
    print(f"   Tamaño: {spritesheet.width}x{spritesheet.height}")
    
    # Versión de impacto
    print(f"\n🔥 Creando versión de impacto...")
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    impact.save(output_impact, optimize=False)
    print(f"✅ Impacto: {output_impact}")
    
    print("\n" + "=" * 60)
    print("¡COMPLETADO CON MÁXIMA CALIDAD!")
    print("=" * 60)

if __name__ == "__main__":
    process_glacier()
