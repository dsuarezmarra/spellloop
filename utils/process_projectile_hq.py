"""
PROCESADOR DE SPRITES DE PROYECTILES - ALTA CALIDAD
====================================================
Script universal para procesar sprites de proyectiles con máxima calidad.

Uso:
    python process_projectile_hq.py <nombre_proyectil> [filas] [columnas]

Ejemplos:
    python process_projectile_hq.py glacier 2 3
    python process_projectile_hq.py void_storm 1 6
    python process_projectile_hq.py seismic_bolt 2 3

El script:
1. Detecta automáticamente la estructura de frames
2. Extrae cada frame recortando el contenido real
3. Redimensiona con LANCZOS (máxima calidad)
4. Crea spritesheet horizontal 64x64 por frame
5. Genera versión de impacto (más brillante)
"""

from PIL import Image, ImageEnhance
import os
import numpy as np
import sys

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


def process_projectile(projectile_name, expected_rows=None, expected_cols=None):
    """
    Procesa sprites de un proyectil con máxima calidad.
    
    Args:
        projectile_name: Nombre del proyectil (ej: "glacier", "void_storm")
        expected_rows: Número esperado de filas (opcional, para validación)
        expected_cols: Número esperado de columnas (opcional, para validación)
    """
    print("=" * 60)
    print(f"PROCESANDO {projectile_name.upper()} (MÁXIMA CALIDAD)")
    print("=" * 60)
    
    # Rutas
    base_dir = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion"
    input_dir = os.path.join(base_dir, projectile_name)
    input_file = os.path.join(input_dir, "unnamed-removebg-preview.png")
    
    # Verificar que existe el archivo
    if not os.path.exists(input_file):
        print(f"❌ ERROR: No se encontró {input_file}")
        return False
    
    output_active = os.path.join(input_dir, f"aoe_active_{projectile_name}.png")
    output_impact = os.path.join(input_dir, f"aoe_impact_{projectile_name}.png")
    frames_dir = os.path.join(input_dir, "frames")
    
    os.makedirs(frames_dir, exist_ok=True)
    
    # Cargar imagen
    img = Image.open(input_file).convert("RGBA")
    print(f"Imagen original: {img.width}x{img.height}")
    
    # Analizar estructura
    row_groups, col_groups = analyze_image_structure(img)
    
    print(f"\n📊 Estructura detectada:")
    print(f"   Filas: {len(row_groups)}, Columnas: {len(col_groups)}")
    
    # Validar si se especificaron dimensiones esperadas
    if expected_rows and len(row_groups) != expected_rows:
        print(f"⚠️  Advertencia: Se esperaban {expected_rows} filas, se encontraron {len(row_groups)}")
    if expected_cols and len(col_groups) != expected_cols:
        print(f"⚠️  Advertencia: Se esperaban {expected_cols} columnas, se encontraron {len(col_groups)}")
    
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
    
    total_frames = len(frames)
    print(f"\n   Total frames: {total_frames}")
    
    # ALTA CALIDAD: Usar LANCZOS
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
    spritesheet_width = target_size * len(resized_frames)
    spritesheet = Image.new("RGBA", (spritesheet_width, target_size), (0, 0, 0, 0))
    for i, frame in enumerate(resized_frames):
        spritesheet.paste(frame, (i * target_size, 0))
    
    spritesheet.save(output_active, optimize=False)
    print(f"\n✅ Spritesheet: {output_active}")
    print(f"   Tamaño: {spritesheet.width}x{spritesheet.height} ({total_frames} frames)")
    
    # Versión de impacto
    print(f"\n🔥 Creando versión de impacto...")
    impact = ImageEnhance.Brightness(spritesheet).enhance(1.3)
    impact = ImageEnhance.Color(impact).enhance(1.2)
    impact.save(output_impact, optimize=False)
    print(f"✅ Impacto: {output_impact}")
    
    print("\n" + "=" * 60)
    print(f"¡{projectile_name.upper()} COMPLETADO!")
    print("=" * 60)
    
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python process_projectile_hq.py <nombre_proyectil> [filas] [columnas]")
        print("Ejemplo: python process_projectile_hq.py glacier 2 3")
        sys.exit(1)
    
    projectile = sys.argv[1]
    rows = int(sys.argv[2]) if len(sys.argv) > 2 else None
    cols = int(sys.argv[3]) if len(sys.argv) > 3 else None
    
    process_projectile(projectile, rows, cols)
