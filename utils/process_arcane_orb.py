#!/usr/bin/env python3
"""
Procesar sprites orbitales
Detecta automáticamente los límites de cada frame basándose en el contenido
Uso: python process_arcane_orb.py [weapon_id] [base_path]
"""

from PIL import Image
import numpy as np
from pathlib import Path
import sys

# Configuración por defecto
WEAPON_ID = sys.argv[1] if len(sys.argv) > 1 else "arcane_orb"
BASE_PATH = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(r"C:\git\spellloop\project\assets\sprites\projectiles\weapons\arcane_orb")
INPUT_PATH = BASE_PATH / "orbit_raw.png"
OUTPUT_PATH = BASE_PATH / f"orbit_spritesheet_{WEAPON_ID}.png"

FRAME_SIZE = 64  # Tamaño final de cada frame
NUM_FRAMES = 8   # Número de frames esperados
OUTPUT_WIDTH = FRAME_SIZE * NUM_FRAMES  # 512px


def remove_gray_background(img):
    """Remover píxeles grises puros (fondo de tablero de ajedrez)"""
    pixels = np.array(img, dtype=np.int16)
    
    if pixels.shape[2] == 3:
        alpha = np.full((pixels.shape[0], pixels.shape[1], 1), 255, dtype=np.int16)
        pixels = np.concatenate([pixels, alpha], axis=2)
    
    r, g, b = pixels[:,:,0], pixels[:,:,1], pixels[:,:,2]
    
    # Detectar grises puros (R≈G≈B) con tolerancia
    is_gray = (np.abs(r - g) <= 10) & (np.abs(g - b) <= 10) & (np.abs(r - b) <= 10)
    
    # Solo remover grises oscuros y claros típicos de tablero (0-30 y 200-255)
    is_dark_gray = is_gray & (r <= 35)
    is_light_gray = is_gray & (r >= 200)
    is_checkerboard = is_dark_gray | is_light_gray
    
    result = pixels.copy().astype(np.uint8)
    result[is_checkerboard, 3] = 0
    
    removed = np.sum(is_checkerboard)
    total = r.size
    print(f"  Fondo gris removido: {removed} píxeles ({100*removed/total:.1f}%)")
    
    return Image.fromarray(result, 'RGBA')


def detect_frame_boundaries(img):
    """Detectar los límites X de cada frame buscando valles de densidad entre frames"""
    pixels = np.array(img)
    alpha = pixels[:,:,3]
    w, h = img.size
    
    # Calcular densidad de píxeles por columna (suma de alpha)
    col_density = np.sum(alpha > 10, axis=0).astype(float)
    
    # Suavizar la densidad para evitar ruido
    kernel_size = 5
    kernel = np.ones(kernel_size) / kernel_size
    col_density_smooth = np.convolve(col_density, kernel, mode='same')
    
    # Estimar ancho aproximado de cada frame
    estimated_frame_width = w // NUM_FRAMES
    
    # Buscar los valles (mínimos locales) entre frames
    # Dividimos en regiones y buscamos el mínimo en cada frontera
    boundaries = [0]  # Empezamos desde 0
    
    for i in range(1, NUM_FRAMES):
        # Zona donde buscar el valle (alrededor de la frontera esperada)
        expected_boundary = i * estimated_frame_width
        search_start = max(0, expected_boundary - estimated_frame_width // 3)
        search_end = min(w, expected_boundary + estimated_frame_width // 3)
        
        # Encontrar el mínimo de densidad en esa zona
        search_region = col_density_smooth[search_start:search_end]
        min_idx = np.argmin(search_region)
        actual_boundary = search_start + min_idx
        
        boundaries.append(actual_boundary)
    
    boundaries.append(w)  # Terminamos en el ancho total
    
    # Crear lista de frames
    frames = []
    for i in range(NUM_FRAMES):
        frames.append((boundaries[i], boundaries[i + 1]))
    
    return frames


def detect_vertical_bounds(img, x_start, x_end):
    """Detectar los límites Y del contenido en una región X"""
    pixels = np.array(img)
    alpha = pixels[:, x_start:x_end, 3]
    
    threshold = 10
    row_has_content = np.any(alpha > threshold, axis=1)
    
    rows_with_content = np.where(row_has_content)[0]
    if len(rows_with_content) == 0:
        return 0, img.size[1]
    
    return rows_with_content[0], rows_with_content[-1] + 1


def extract_frame_content(img, x_start, x_end):
    """Extraer el contenido de un frame con sus límites exactos"""
    y_start, y_end = detect_vertical_bounds(img, x_start, x_end)
    
    # Recortar el frame
    frame = img.crop((x_start, y_start, x_end, y_end))
    return frame


def center_in_square(content, target_size):
    """Centrar el contenido en un cuadrado del tamaño objetivo"""
    content_w, content_h = content.size
    
    if content_w == 0 or content_h == 0:
        return Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    
    # Calcular escala para que quepa manteniendo proporción
    # Usar 90% del espacio para dejar un pequeño margen
    max_dim = int(target_size * 0.90)
    scale = min(max_dim / content_w, max_dim / content_h)
    
    # Solo escalar si es necesario reducir
    if scale < 1.0:
        new_w = max(1, int(content_w * scale))
        new_h = max(1, int(content_h * scale))
        content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Crear imagen cuadrada y centrar
    result = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - content.width) // 2
    paste_y = (target_size - content.height) // 2
    result.paste(content, (paste_x, paste_y), content)
    
    return result


def process_orbital_sprite():
    """Procesar el sprite orbital completo"""
    print(f"\n{'='*60}")
    print(f"Procesando: {WEAPON_ID}")
    print(f"{'='*60}")
    
    if not INPUT_PATH.exists():
        print(f"❌ ERROR: No se encontró {INPUT_PATH}")
        return False
    
    # Cargar imagen
    print(f"\n📂 Cargando: {INPUT_PATH.name}")
    img = Image.open(INPUT_PATH)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    print(f"  Dimensiones: {img.size[0]}x{img.size[1]}")
    
    # Remover fondo gris
    print("\n🎨 Removiendo fondo...")
    img = remove_gray_background(img)
    
    # Detectar límites de cada frame
    print(f"\n🔍 Detectando frames...")
    frame_bounds = detect_frame_boundaries(img)
    print(f"  Frames encontrados: {len(frame_bounds)}")
    
    for i, (x_start, x_end) in enumerate(frame_bounds):
        print(f"    Frame {i+1}: x={x_start}-{x_end} (ancho={x_end-x_start})")
    
    if len(frame_bounds) != NUM_FRAMES:
        print(f"\n⚠️ ADVERTENCIA: Se esperaban {NUM_FRAMES} frames, se encontraron {len(frame_bounds)}")
    
    # Extraer y procesar cada frame
    print(f"\n✂️ Extrayendo frames...")
    processed_frames = []
    
    for i, (x_start, x_end) in enumerate(frame_bounds[:NUM_FRAMES]):
        # Extraer contenido exacto del frame
        frame_content = extract_frame_content(img, x_start, x_end)
        
        # Centrar en cuadrado 64x64
        final_frame = center_in_square(frame_content, FRAME_SIZE)
        processed_frames.append(final_frame)
        
        print(f"    Frame {i+1}: {frame_content.size[0]}x{frame_content.size[1]} → {FRAME_SIZE}x{FRAME_SIZE} ✓")
    
    # Crear spritesheet horizontal
    print(f"\n📐 Creando spritesheet...")
    spritesheet = Image.new('RGBA', (OUTPUT_WIDTH, FRAME_SIZE), (0, 0, 0, 0))
    
    for i, frame in enumerate(processed_frames):
        x = i * FRAME_SIZE
        spritesheet.paste(frame, (x, 0))
    
    # Guardar
    spritesheet.save(OUTPUT_PATH, 'PNG')
    print(f"\n✅ Guardado: {OUTPUT_PATH}")
    print(f"   Tamaño final: {OUTPUT_WIDTH}x{FRAME_SIZE} ({len(processed_frames)} frames)")
    
    # Guardar frames individuales para verificación
    debug_dir = INPUT_PATH.parent / "debug_frames"
    debug_dir.mkdir(exist_ok=True)
    for i, frame in enumerate(processed_frames):
        frame.save(debug_dir / f"frame_{i+1}.png", 'PNG')
    print(f"   Frames individuales guardados en: {debug_dir}")
    
    return True


if __name__ == "__main__":
    success = process_orbital_sprite()
    if success:
        print("\n🎉 ¡Procesamiento completado!")
    else:
        print("\n❌ Error en el procesamiento")
