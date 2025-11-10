"""
Verifica la estructura de los sprite sheets generados.
Comprueba que cada frame esté exactamente en la posición correcta.
"""
from PIL import Image, ImageDraw
import numpy as np
from pathlib import Path

def analyze_spritesheet(sheet_path, expected_frame_width, expected_frame_height, num_frames):
    """Analiza un sprite sheet y verifica su estructura."""
    print(f"\n{'='*60}")
    print(f"Analizando: {sheet_path.name}")
    print(f"{'='*60}")
    
    sheet = Image.open(sheet_path)
    sheet_width, sheet_height = sheet.size
    
    print(f"Tamaño del sheet: {sheet_width}x{sheet_height}px")
    print(f"Frames esperados: {num_frames} de {expected_frame_width}x{expected_frame_height}px")
    
    # Verificar dimensiones del sheet
    expected_sheet_width = expected_frame_width * num_frames
    expected_sheet_height = expected_frame_height
    
    if sheet_width != expected_sheet_width or sheet_height != expected_sheet_height:
        print(f"❌ ERROR: Dimensiones incorrectas!")
        print(f"   Esperado: {expected_sheet_width}x{expected_sheet_height}px")
        print(f"   Real: {sheet_width}x{sheet_height}px")
        return False
    
    print(f"✅ Dimensiones correctas: {expected_sheet_width}x{expected_sheet_height}px")
    
    # Extraer y analizar cada frame
    frames_data = []
    
    for i in range(num_frames):
        x = i * expected_frame_width
        frame = sheet.crop((x, 0, x + expected_frame_width, expected_frame_height))
        
        # Calcular bbox del contenido
        frame_array = np.array(frame)
        if frame_array.shape[2] == 4:
            alpha = frame_array[:, :, 3]
        else:
            alpha = np.sum(frame_array[:, :, :3], axis=2)
        
        rows = np.any(alpha > 10, axis=1)
        cols = np.any(alpha > 10, axis=0)
        
        if rows.any() and cols.any():
            y_min, y_max = np.where(rows)[0][[0, -1]]
            x_min, x_max = np.where(cols)[0][[0, -1]]
            
            center_x = (x_min + x_max) / 2
            center_y = (y_min + y_max) / 2
            
            frames_data.append({
                'frame': i + 1,
                'bbox': (x_min, y_min, x_max, y_max),
                'center': (center_x, center_y),
                'width': x_max - x_min + 1,
                'height': y_max - y_min + 1
            })
        else:
            print(f"⚠️ Frame {i+1}: Sin contenido detectado")
            frames_data.append(None)
    
    # Analizar centros
    valid_frames = [f for f in frames_data if f is not None]
    
    if not valid_frames:
        print("❌ No se detectó contenido en ningún frame")
        return False
    
    centers = np.array([f['center'] for f in valid_frames])
    avg_center = centers.mean(axis=0)
    
    print(f"\nAnálisis de centros:")
    print(f"  Centro promedio: ({avg_center[0]:.1f}, {avg_center[1]:.1f})")
    
    # Verificar que el centro promedio esté cerca del centro del frame
    frame_center = (expected_frame_width / 2, expected_frame_height / 2)
    center_offset = np.sqrt((avg_center[0] - frame_center[0])**2 + (avg_center[1] - frame_center[1])**2)
    
    print(f"  Centro del frame: ({frame_center[0]:.1f}, {frame_center[1]:.1f})")
    print(f"  Offset del centro promedio: {center_offset:.1f}px")
    
    if center_offset > 10:
        print(f"  ⚠️ ADVERTENCIA: El contenido no está centrado en el frame")
    else:
        print(f"  ✅ Contenido bien centrado")
    
    # Calcular desviación máxima entre frames
    max_deviation = 0
    max_frame = 0
    
    for f in valid_frames:
        deviation = np.sqrt((f['center'][0] - avg_center[0])**2 + (f['center'][1] - avg_center[1])**2)
        if deviation > max_deviation:
            max_deviation = deviation
            max_frame = f['frame']
    
    print(f"  Desviación máxima entre frames: {max_deviation:.1f}px (frame {max_frame})")
    
    if max_deviation < 1:
        print(f"  ✅ Alineación excelente (<1px)")
    elif max_deviation < 3:
        print(f"  ✅ Alineación buena (<3px)")
    elif max_deviation < 10:
        print(f"  ⚠️ Alineación moderada (3-10px)")
    else:
        print(f"  ❌ Alineación mala (>10px)")
    
    # Detalles de cada frame
    print(f"\nDetalles por frame:")
    for f in valid_frames:
        deviation = np.sqrt((f['center'][0] - avg_center[0])**2 + (f['center'][1] - avg_center[1])**2)
        print(f"  Frame {f['frame']}: centro=({f['center'][0]:.1f},{f['center'][1]:.1f}) "
              f"tamaño=({f['width']}x{f['height']}) desv={deviation:.1f}px")
    
    return True

def main():
    base_dir = Path(r"C:\git\spellloop\project\assets\textures\biomes\Snow")
    
    print("\n" + "="*80)
    print("VERIFICACIÓN DE ESTRUCTURA DE SPRITE SHEETS")
    print("="*80)
    
    all_ok = True
    
    # Verificar textura base
    print("\n" + "="*80)
    print("TEXTURA BASE")
    print("="*80)
    
    base_sheet = base_dir / "base" / "snow_base_animated_sheet_f8_512.png"
    if base_sheet.exists():
        if not analyze_spritesheet(base_sheet, 512, 512, 8):
            all_ok = False
    else:
        print(f"❌ No encontrado: {base_sheet}")
        all_ok = False
    
    # Verificar decoraciones
    print("\n" + "="*80)
    print("DECORACIONES")
    print("="*80)
    
    decor_dir = base_dir / "decor"
    
    for i in range(1, 11):
        sheet_path = decor_dir / f"snow_decor{i}_sheet_f8_256.png"
        
        if sheet_path.exists():
            if not analyze_spritesheet(sheet_path, 256, 256, 8):
                all_ok = False
        else:
            print(f"❌ No encontrado: {sheet_path}")
            all_ok = False
    
    # Resumen final
    print("\n" + "="*80)
    print("RESUMEN")
    print("="*80)
    
    if all_ok:
        print("✅ Todos los sprite sheets tienen estructura correcta")
    else:
        print("❌ Se encontraron problemas en los sprite sheets")
    
    return all_ok

if __name__ == "__main__":
    main()
