"""
process_void_bolt.py
Procesador de sprites para Void Bolt (Rayo del Vacío)
Lightning + Void fusion - CHAIN type projectile

ESTRUCTURA DE LOS ARCHIVOS:
- FLIGHT (unnamed-removebg-preview.png): 4 rayos horizontales dispuestos en FILAS VERTICALES
- IMPACT (unnamed-removebg-preview (3).png): 3 explosiones grandes (duplicamos una para tener 4)
"""

from PIL import Image
import numpy as np
from pathlib import Path
from scipy import ndimage

# Configuración
FRAME_SIZE = 64
OUTPUT_WIDTH = 256  # 4 frames * 64px


def extract_rows(img_path, num_rows=4):
    """
    Extrae frames de filas horizontales.
    Cada fila contiene un rayo horizontal completo.
    """
    img = Image.open(img_path).convert('RGBA')
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    row_height = h // num_rows
    frames = []
    
    for i in range(num_rows):
        y_start = i * row_height
        y_end = (i + 1) * row_height if i < num_rows - 1 else h
        
        row_section = arr[y_start:y_end]
        alpha = row_section[:,:,3]
        
        # Encontrar el contenido real en esta fila
        rows_with_content = np.where(alpha.max(axis=1) > 20)[0]
        cols_with_content = np.where(alpha.max(axis=0) > 20)[0]
        
        if len(rows_with_content) > 0 and len(cols_with_content) > 0:
            y1, y2 = rows_with_content[0], rows_with_content[-1] + 1
            x1, x2 = cols_with_content[0], cols_with_content[-1] + 1
            
            frame = Image.fromarray(row_section[y1:y2, x1:x2])
            frames.append(frame)
            print(f"    Fila {i+1}: extraído {frame.width}x{frame.height}px desde ({x1},{y_start+y1})")
        else:
            print(f"    Fila {i+1}: vacía")
    
    return frames


def extract_large_components(img_path, num_components=3):
    """
    Extrae los N componentes más grandes de la imagen usando detección de componentes conectados.
    """
    img = Image.open(img_path).convert('RGBA')
    arr = np.array(img)
    
    alpha = arr[:,:,3]
    binary = (alpha > 20).astype(int)
    labeled, num_features = ndimage.label(binary)
    
    components = []
    for i in range(1, num_features + 1):
        mask = labeled == i
        rows = np.where(mask.any(axis=1))[0]
        cols = np.where(mask.any(axis=0))[0]
        
        if len(rows) > 0 and len(cols) > 0:
            y1, y2 = rows[0], rows[-1] + 1
            x1, x2 = cols[0], cols[-1] + 1
            area = int(mask.sum())
            components.append((x1, y1, x2, y2, area))
    
    # Ordenar por área descendente y tomar los N más grandes
    components.sort(key=lambda c: -c[4])
    components = components[:num_components]
    
    # Ordenar de izquierda a derecha para consistencia visual
    components.sort(key=lambda c: c[0])
    
    frames = []
    for i, (x1, y1, x2, y2, area) in enumerate(components):
        frame = Image.fromarray(arr[y1:y2, x1:x2])
        frames.append(frame)
        print(f"    Componente {i+1}: {frame.width}x{frame.height}px, área={area}")
    
    return frames


def create_flight_spritesheet(frames, frame_size=FRAME_SIZE):
    """
    Crea spritesheet de FLIGHT para rayos horizontales.
    Los rayos deben llenar el ancho del frame para verse bien al estirarse entre enemigos.
    """
    spritesheet = Image.new('RGBA', (frame_size * 4, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        w, h = frame.size
        
        # Para FLIGHT: escalar para llenar el ancho, centrar verticalmente
        scale = frame_size / w
        new_w = frame_size
        new_h = max(1, int(h * scale))
        
        # Si queda muy alto, ajustar proporcionalmente
        if new_h > frame_size:
            scale = frame_size / h
            new_h = frame_size
            new_w = max(1, int(w * scale))
        
        resized = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Centrar en el frame
        x_offset = (frame_size - new_w) // 2
        y_offset = (frame_size - new_h) // 2
        
        spritesheet.paste(resized, (i * frame_size + x_offset, y_offset), resized)
    
    return spritesheet


def create_impact_spritesheet(frames, frame_size=FRAME_SIZE):
    """
    Crea spritesheet de IMPACT para explosiones.
    Las explosiones deben estar centradas y escaladas uniformemente.
    """
    # Encontrar el tamaño máximo para escalar todos igual
    max_size = max(max(f.width, f.height) for f in frames)
    
    spritesheet = Image.new('RGBA', (frame_size * 4, frame_size), (0, 0, 0, 0))
    
    for i, frame in enumerate(frames):
        w, h = frame.size
        
        # Escalar manteniendo proporción, basado en el más grande
        scale = (frame_size * 0.95) / max_size  # 95% para dejar margen
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        
        resized = frame.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Centrar en el frame
        x_offset = (frame_size - new_w) // 2
        y_offset = (frame_size - new_h) // 2
        
        spritesheet.paste(resized, (i * frame_size + x_offset, y_offset), resized)
    
    return spritesheet

def main():
    print("=" * 60)
    print("  PROCESADOR DE SPRITESHEETS - VOID BOLT")
    print("  Lightning + Void Fusion - Chain Projectile")
    print("=" * 60)
    
    base_path = Path("project/assets/sprites/projectiles/fusion/void_bolt")
    output_path = Path("project/assets/sprites/projectiles/fusion")
    
    flight_file = base_path / "unnamed-removebg-preview.png"
    impact_file = base_path / "unnamed-removebg-preview (3).png"
    
    # ===== FLIGHT =====
    print("\n📦 Procesando FLIGHT (rayos en filas verticales)...")
    print(f"  Archivo: {flight_file}")
    
    if flight_file.exists():
        flight_frames = extract_rows(flight_file, num_rows=4)
        print(f"  Extraídos {len(flight_frames)} frames de FLIGHT")
        
        if len(flight_frames) == 4:
            flight_sheet = create_flight_spritesheet(flight_frames)
            flight_output = output_path / "flight_spritesheet_void_bolt.png"
            flight_sheet.save(flight_output)
            print(f"  ✓ Guardado: {flight_output} ({flight_sheet.width}x{flight_sheet.height})")
        else:
            print(f"  ⚠ Se esperaban 4 frames, se obtuvieron {len(flight_frames)}")
    else:
        print(f"  ⚠ Archivo no encontrado: {flight_file}")
    
    # ===== IMPACT =====
    print("\n💥 Procesando IMPACT (explosiones)...")
    print(f"  Archivo: {impact_file}")
    
    if impact_file.exists():
        impact_frames = extract_large_components(impact_file, num_components=3)
        print(f"  Extraídos {len(impact_frames)} componentes grandes")
        
        if len(impact_frames) == 3:
            # Duplicar el frame del medio para tener 4
            print("  Duplicando frame central para completar 4 frames...")
            impact_frames.insert(2, impact_frames[1].copy())
            print(f"  Ahora tenemos {len(impact_frames)} frames")
        
        if len(impact_frames) >= 4:
            impact_sheet = create_impact_spritesheet(impact_frames[:4])
            impact_output = output_path / "impact_spritesheet_void_bolt.png"
            impact_sheet.save(impact_output)
            print(f"  ✓ Guardado: {impact_output} ({impact_sheet.width}x{impact_sheet.height})")
        else:
            print(f"  ⚠ Se esperaban al menos 4 frames, se obtuvieron {len(impact_frames)}")
    else:
        print(f"  ⚠ Archivo no encontrado: {impact_file}")
    
    print("\n" + "=" * 60)
    print("  ✓ PROCESO COMPLETADO")
    print("=" * 60)


if __name__ == "__main__":
    main()
