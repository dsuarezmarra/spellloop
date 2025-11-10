"""
Diagnóstico de movimiento de contenido entre frames.
Analiza cuánto se mueve el contenido sin modificar los archivos.
"""
from PIL import Image
import numpy as np
from pathlib import Path
import json

def get_content_bbox(image):
    """Calcula el bounding box del contenido no transparente."""
    img_array = np.array(image)
    
    # Si tiene alpha channel
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        # Si no tiene alpha, usar suma de RGB para detectar contenido
        alpha = np.sum(img_array[:, :, :3], axis=2)
    
    # Encontrar coordenadas de contenido
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    
    if not rows.any() or not cols.any():
        return None
    
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]
    
    return {
        'x_min': int(x_min),
        'y_min': int(y_min),
        'x_max': int(x_max),
        'y_max': int(y_max),
        'width': int(x_max - x_min + 1),
        'height': int(y_max - y_min + 1),
        'center_x': int((x_min + x_max) / 2),
        'center_y': int((y_min + y_max) / 2)
    }

def analyze_frame_set(frame_paths, set_name):
    """Analiza un conjunto de frames y calcula estadísticas de movimiento."""
    print(f"\n{'='*60}")
    print(f"Analizando: {set_name}")
    print(f"{'='*60}")
    
    bboxes = []
    centers = []
    
    for i, frame_path in enumerate(frame_paths, 1):
        img = Image.open(frame_path)
        bbox = get_content_bbox(img)
        
        if bbox:
            bboxes.append(bbox)
            centers.append((bbox['center_x'], bbox['center_y']))
            print(f"Frame {i}: bbox=({bbox['x_min']},{bbox['y_min']})->({bbox['x_max']},{bbox['y_max']}) "
                  f"size=({bbox['width']}x{bbox['height']}) center=({bbox['center_x']},{bbox['center_y']})")
        else:
            print(f"Frame {i}: ⚠️ Sin contenido detectado")
    
    if not centers:
        print("❌ No se detectó contenido en ningún frame")
        return None
    
    # Calcular estadísticas
    centers_array = np.array(centers)
    avg_center = centers_array.mean(axis=0)
    
    # Calcular movimiento máximo respecto al centro promedio
    max_deviation = 0
    max_frame = 0
    for i, center in enumerate(centers, 1):
        deviation = np.sqrt((center[0] - avg_center[0])**2 + (center[1] - avg_center[1])**2)
        if deviation > max_deviation:
            max_deviation = deviation
            max_frame = i
    
    # Calcular rango de movimiento
    x_centers = [c[0] for c in centers]
    y_centers = [c[1] for c in centers]
    x_range = max(x_centers) - min(x_centers)
    y_range = max(y_centers) - min(y_centers)
    
    # Calcular bbox union (tamaño mínimo necesario para contener todo)
    union_bbox = {
        'x_min': min(b['x_min'] for b in bboxes),
        'y_min': min(b['y_min'] for b in bboxes),
        'x_max': max(b['x_max'] for b in bboxes),
        'y_max': max(b['y_max'] for b in bboxes)
    }
    union_bbox['width'] = union_bbox['x_max'] - union_bbox['x_min'] + 1
    union_bbox['height'] = union_bbox['y_max'] - union_bbox['y_min'] + 1
    
    print(f"\n📊 Estadísticas:")
    print(f"  Centro promedio: ({avg_center[0]:.1f}, {avg_center[1]:.1f})")
    print(f"  Rango de movimiento: X={x_range}px, Y={y_range}px")
    print(f"  Desviación máxima: {max_deviation:.1f}px (frame {max_frame})")
    print(f"  Bbox union necesario: {union_bbox['width']}x{union_bbox['height']}px")
    
    # Evaluación
    if max_deviation < 3:
        print(f"  ✅ Movimiento mínimo (<3px) - probablemente aceptable")
    elif max_deviation < 10:
        print(f"  ⚠️ Movimiento moderado (3-10px) - se notará levemente")
    else:
        print(f"  ❌ Movimiento significativo (>10px) - requiere corrección")
    
    return {
        'set_name': set_name,
        'frame_count': len(bboxes),
        'avg_center': avg_center.tolist(),
        'movement_range': {'x': x_range, 'y': y_range},
        'max_deviation': max_deviation,
        'union_bbox': union_bbox,
        'bboxes': bboxes
    }

def main():
    base_dir = Path(r"C:\git\spellloop\project\assets\textures\biomes\Snow")
    
    results = {
        'timestamp': '2025-11-10',
        'analysis': []
    }
    
    # Analizar textura base
    print("\n" + "="*80)
    print("ANÁLISIS DE TEXTURA BASE")
    print("="*80)
    
    base_dir_path = base_dir / "base"
    base_frames = sorted([f for f in base_dir_path.glob("*.png") if not 'sheet' in f.name])
    
    if base_frames:
        base_result = analyze_frame_set(base_frames, "Base Texture")
        if base_result:
            results['analysis'].append(base_result)
    else:
        print("⚠️ No se encontraron frames de textura base")
    
    # Analizar decoraciones
    print("\n" + "="*80)
    print("ANÁLISIS DE DECORACIONES")
    print("="*80)
    
    decor_dir = base_dir / "decor"
    
    # Detectar grupos de decoraciones
    decor_groups = {}
    for png_file in decor_dir.glob("*.png"):
        if 'sheet' in png_file.name:
            continue
        
        # Extraer número de grupo (01-08, 11-18, etc.)
        name = png_file.stem
        # Buscar patrón de números
        import re
        match = re.search(r'(\d+)', name)
        if match:
            num = int(match.group(1))
            group = (num // 10) * 10 + 1  # 01->1, 08->1, 11->11, 18->11, etc.
            if group not in decor_groups:
                decor_groups[group] = []
            decor_groups[group].append(png_file)
    
    # Analizar cada grupo
    for group_num in sorted(decor_groups.keys()):
        frames = sorted(decor_groups[group_num])
        if len(frames) >= 4:  # Mínimo 4 frames para análisis significativo
            decor_result = analyze_frame_set(frames, f"Decor Group {group_num}")
            if decor_result:
                results['analysis'].append(decor_result)
    
    # Guardar resultados
    results_file = Path(__file__).parent / "frame_movement_diagnosis.json"
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print("\n" + "="*80)
    print("RESUMEN GENERAL")
    print("="*80)
    
    if results['analysis']:
        avg_deviation = np.mean([r['max_deviation'] for r in results['analysis']])
        max_deviation_overall = max([r['max_deviation'] for r in results['analysis']])
        
        print(f"\nSets analizados: {len(results['analysis'])}")
        print(f"Desviación promedio: {avg_deviation:.1f}px")
        print(f"Desviación máxima: {max_deviation_overall:.1f}px")
        
        needs_fix = [r for r in results['analysis'] if r['max_deviation'] > 5]
        if needs_fix:
            print(f"\n⚠️ {len(needs_fix)} sets requieren corrección (>5px desviación):")
            for r in needs_fix:
                print(f"  - {r['set_name']}: {r['max_deviation']:.1f}px")
        else:
            print("\n✅ Todos los sets tienen movimiento aceptable (<5px)")
        
        print(f"\n📄 Resultados detallados guardados en: {results_file}")
    else:
        print("\n❌ No se pudo analizar ningún set de frames")

if __name__ == "__main__":
    main()
