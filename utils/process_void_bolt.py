"""
process_void_bolt.py
Procesador de sprites para Void Bolt (Rayo del Vacío)
Lightning + Void fusion - CHAIN type projectile
"""

from PIL import Image
import os

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

# Configuración de entrada (sprites generados por IA)
INPUT_WIDTH = 612   # Ancho aproximado de imagen generada
INPUT_HEIGHT = 408  # Alto aproximado de imagen generada
INPUT_FRAMES = 4    # 4 frames horizontales

# Configuración de salida (formato del juego)
OUTPUT_FRAME_SIZE = 64   # Cada frame será 64x64
OUTPUT_WIDTH = 256       # 4 frames * 64px = 256px
OUTPUT_HEIGHT = 64       # Una fila

# Carpeta de sprites
SPRITE_FOLDER = r"C:\git\spellloop\project\assets\sprites\projectiles\fusion\void_bolt"

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES
# ═══════════════════════════════════════════════════════════════════════════════

def find_content_bounds(img, frame_x, frame_width, padding=2):
    """Encontrar los límites del contenido real en un frame (ignorando transparencia)"""
    pixels = img.load()
    width, height = img.size
    
    start_x = frame_x
    end_x = min(frame_x + frame_width, width)
    
    min_x, max_x = end_x, start_x
    min_y, max_y = height, 0
    
    for x in range(start_x, end_x):
        for y in range(height):
            pixel = pixels[x, y]
            # Verificar si el pixel tiene contenido (alpha > 0)
            if len(pixel) >= 4 and pixel[3] > 10:  # Umbral de alpha
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
    
    # Añadir padding
    min_x = max(start_x, min_x - padding)
    max_x = min(end_x, max_x + padding)
    min_y = max(0, min_y - padding)
    max_y = min(height, max_y + padding)
    
    return min_x, min_y, max_x, max_y

def extract_and_resize_frame(img, frame_index, frame_width, output_size):
    """Extraer un frame, encontrar su contenido y redimensionar a tamaño fijo"""
    frame_x = frame_index * frame_width
    
    # Encontrar bounds del contenido real
    bounds = find_content_bounds(img, frame_x, frame_width)
    min_x, min_y, max_x, max_y = bounds
    
    # Si no hay contenido, devolver frame vacío
    if min_x >= max_x or min_y >= max_y:
        return Image.new('RGBA', (output_size, output_size), (0, 0, 0, 0))
    
    # Extraer el contenido
    content = img.crop((min_x, min_y, max_x, max_y))
    
    # Calcular escala manteniendo aspecto
    content_width, content_height = content.size
    scale = min(output_size / content_width, output_size / content_height) * 0.85
    
    new_width = int(content_width * scale)
    new_height = int(content_height * scale)
    
    # Redimensionar
    content_resized = content.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Crear frame de salida y centrar contenido
    output_frame = Image.new('RGBA', (output_size, output_size), (0, 0, 0, 0))
    paste_x = (output_size - new_width) // 2
    paste_y = (output_size - new_height) // 2
    output_frame.paste(content_resized, (paste_x, paste_y), content_resized)
    
    return output_frame

def process_spritesheet(input_path, output_path, num_frames=4):
    """Procesar un spritesheet de entrada y generar el formato de salida"""
    print(f"  Procesando: {os.path.basename(input_path)}")
    
    # Cargar imagen
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size
    print(f"    Tamaño entrada: {width}x{height}")
    
    # Calcular ancho de cada frame de entrada
    frame_width = width // num_frames
    print(f"    Ancho por frame: {frame_width}px")
    
    # Crear imagen de salida
    output = Image.new('RGBA', (OUTPUT_WIDTH, OUTPUT_HEIGHT), (0, 0, 0, 0))
    
    # Procesar cada frame
    for i in range(num_frames):
        frame = extract_and_resize_frame(img, i, frame_width, OUTPUT_FRAME_SIZE)
        output.paste(frame, (i * OUTPUT_FRAME_SIZE, 0))
        print(f"    Frame {i+1}/{num_frames} procesado")
    
    # Guardar
    output.save(output_path, 'PNG')
    print(f"    ✓ Guardado: {os.path.basename(output_path)}")
    print(f"    Tamaño salida: {OUTPUT_WIDTH}x{OUTPUT_HEIGHT}")

def main():
    print("=" * 60)
    print("  PROCESADOR DE SPRITESHEETS - VOID BOLT")
    print("  Lightning + Void Fusion - Chain Projectile")
    print("=" * 60)
    
    # Buscar archivos de entrada
    flight_input = None
    impact_input = None
    
    for file in os.listdir(SPRITE_FOLDER):
        lower = file.lower()
        if lower.endswith('.png') and 'spritesheet' not in lower:
            if 'flight' in lower or 'bolt' in lower or 'ray' in lower:
                flight_input = os.path.join(SPRITE_FOLDER, file)
            elif 'impact' in lower or 'explosion' in lower or 'hit' in lower or 'zap' in lower:
                impact_input = os.path.join(SPRITE_FOLDER, file)
    
    # Procesar flight
    if flight_input:
        print(f"\n📦 Procesando FLIGHT sprite...")
        output_path = os.path.join(SPRITE_FOLDER, "flight_spritesheet_void_bolt.png")
        process_spritesheet(flight_input, output_path)
    else:
        print("\n⚠️ No se encontró archivo flight (buscar: flight, bolt, ray)")
    
    # Procesar impact
    if impact_input:
        print(f"\n💥 Procesando IMPACT sprite...")
        output_path = os.path.join(SPRITE_FOLDER, "impact_spritesheet_void_bolt.png")
        process_spritesheet(impact_input, output_path)
    else:
        print("\n⚠️ No se encontró archivo impact (buscar: impact, explosion, hit, zap)")
    
    print("\n" + "=" * 60)
    if flight_input and impact_input:
        print("  ✓ PROCESO COMPLETADO")
    else:
        print("  ⚠️ PROCESO INCOMPLETO - Faltan archivos de entrada")
        print(f"\n  Coloca los sprites en: {SPRITE_FOLDER}")
        print("  Nombres esperados:")
        print("    - flight.png (o bolt.png, ray.png)")
        print("    - impact.png (o explosion.png, hit.png, zap.png)")
    print("=" * 60)

if __name__ == "__main__":
    main()
