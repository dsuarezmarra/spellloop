#!/usr/bin/env python3
"""
Script para corregir el alineamiento de frames en spritesheets animados.

El problema: Los frames no están perfectamente centrados, causando un efecto
de "salto" o desplazamiento durante la animación porque cada frame tiene
el contenido en una posición ligeramente diferente.

La solución: 
1. Analizar el bounding box del contenido (píxeles no transparentes) de cada frame
2. Encontrar un bounding box global que cubra todo el contenido de todos los frames
3. Centrar ese contenido global en cada frame, manteniendo la base en la misma posición Y

Esto asegura que todos los frames compartan el mismo centro/pivote.
"""

import os
import sys
from pathlib import Path
from PIL import Image
import argparse

def get_content_bbox(img):
    """
    Obtiene el bounding box del contenido no transparente de una imagen.
    Retorna (left, top, right, bottom) o None si está vacía.
    """
    # Asegurar que tiene canal alpha
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Obtener el canal alpha
    alpha = img.split()[3]
    
    # Obtener el bounding box de los píxeles no transparentes
    bbox = alpha.getbbox()
    return bbox

def analyze_spritesheet(img_path, frame_width=256, num_frames=8):
    """
    Analiza un spritesheet y retorna información sobre cada frame.
    """
    img = Image.open(img_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    frames_info = []
    
    for i in range(num_frames):
        left = i * frame_width
        right = left + frame_width
        
        frame = img.crop((left, 0, right, img.height))
        bbox = get_content_bbox(frame)
        
        if bbox:
            # Convertir a coordenadas absolutas
            abs_bbox = (
                left + bbox[0],  # left
                bbox[1],         # top
                left + bbox[2],  # right
                bbox[3]          # bottom
            )
            # Bounding box relativo al frame
            rel_bbox = bbox
            content_width = bbox[2] - bbox[0]
            content_height = bbox[3] - bbox[1]
            content_center_x = bbox[0] + content_width / 2
            content_center_y = bbox[1] + content_height / 2
        else:
            abs_bbox = None
            rel_bbox = None
            content_width = 0
            content_height = 0
            content_center_x = frame_width / 2
            content_center_y = img.height / 2
        
        frames_info.append({
            'frame_index': i,
            'abs_bbox': abs_bbox,
            'rel_bbox': rel_bbox,
            'content_width': content_width,
            'content_height': content_height,
            'content_center_x': content_center_x,
            'content_center_y': content_center_y,
            'bottom_y': bbox[3] if bbox else img.height
        })
    
    return frames_info, img

def calculate_global_bounds(frames_info, frame_width=256, frame_height=256):
    """
    Calcula los límites globales del contenido a través de todos los frames.
    """
    min_left = frame_width
    max_right = 0
    min_top = frame_height
    max_bottom = 0
    
    for info in frames_info:
        if info['rel_bbox']:
            bbox = info['rel_bbox']
            min_left = min(min_left, bbox[0])
            max_right = max(max_right, bbox[2])
            min_top = min(min_top, bbox[1])
            max_bottom = max(max_bottom, bbox[3])
    
    if min_left >= max_right or min_top >= max_bottom:
        return None
    
    global_width = max_right - min_left
    global_height = max_bottom - min_top
    global_center_x = min_left + global_width / 2
    global_center_y = min_top + global_height / 2
    
    return {
        'left': min_left,
        'right': max_right,
        'top': min_top,
        'bottom': max_bottom,
        'width': global_width,
        'height': global_height,
        'center_x': global_center_x,
        'center_y': global_center_y
    }

def check_alignment(frames_info, tolerance=2):
    """
    Verifica si los frames están correctamente alineados.
    Retorna True si hay problemas de alineamiento.
    """
    if not frames_info:
        return False
    
    # Obtener centros X de todos los frames con contenido
    centers_x = [f['content_center_x'] for f in frames_info if f['rel_bbox']]
    bottoms = [f['bottom_y'] for f in frames_info if f['rel_bbox']]
    
    if not centers_x:
        return False
    
    # Verificar variación en centros X
    max_center_x = max(centers_x)
    min_center_x = min(centers_x)
    center_variation = max_center_x - min_center_x
    
    # Verificar variación en posición Y inferior (la base del sprite)
    max_bottom = max(bottoms)
    min_bottom = min(bottoms)
    bottom_variation = max_bottom - min_bottom
    
    has_alignment_issue = center_variation > tolerance or bottom_variation > tolerance
    
    return has_alignment_issue, center_variation, bottom_variation

def fix_alignment(img_path, output_path, frame_width=256, num_frames=8, mode='center_bottom'):
    """
    Corrige el alineamiento de los frames en un spritesheet.
    
    Modos:
    - 'center_bottom': Centra horizontalmente y alinea la base (ideal para decoraciones)
    - 'center_center': Centra tanto horizontal como verticalmente
    """
    frames_info, original_img = analyze_spritesheet(img_path, frame_width, num_frames)
    global_bounds = calculate_global_bounds(frames_info, frame_width, original_img.height)
    
    if not global_bounds:
        print(f"  No se encontró contenido en {img_path}")
        return False
    
    # Crear nueva imagen del mismo tamaño
    new_img = Image.new('RGBA', original_img.size, (0, 0, 0, 0))
    
    # Calcular la posición objetivo para centrar
    target_center_x = frame_width / 2
    
    for i in range(num_frames):
        left = i * frame_width
        right = left + frame_width
        
        # Extraer el frame original
        frame = original_img.crop((left, 0, right, original_img.height))
        info = frames_info[i]
        
        if not info['rel_bbox']:
            # Frame vacío, copiar tal cual
            new_img.paste(frame, (left, 0))
            continue
        
        # Calcular el desplazamiento necesario
        current_center_x = info['content_center_x']
        current_bottom = info['bottom_y']
        
        # Desplazamiento X para centrar
        offset_x = int(target_center_x - current_center_x)
        
        # Desplazamiento Y para alinear la base con el máximo global
        if mode == 'center_bottom':
            # Alinear la base de todos los frames al mismo punto
            target_bottom = global_bounds['bottom']
            offset_y = int(target_bottom - current_bottom)
        else:
            offset_y = 0
        
        # Crear un nuevo frame y pegar el contenido desplazado
        new_frame = Image.new('RGBA', (frame_width, original_img.height), (0, 0, 0, 0))
        
        # Extraer solo el contenido (no todo el frame)
        bbox = info['rel_bbox']
        content = frame.crop(bbox)
        
        # Calcular nueva posición
        new_x = bbox[0] + offset_x
        new_y = bbox[1] + offset_y
        
        # Asegurar que no se salga de los límites
        new_x = max(0, min(new_x, frame_width - (bbox[2] - bbox[0])))
        new_y = max(0, min(new_y, original_img.height - (bbox[3] - bbox[1])))
        
        # Pegar el contenido en la nueva posición
        new_frame.paste(content, (int(new_x), int(new_y)))
        
        # Pegar el frame corregido en la imagen final
        new_img.paste(new_frame, (left, 0))
    
    # Guardar la imagen corregida
    new_img.save(output_path, 'PNG')
    return True

def analyze_and_report(folder_path, frame_width=256, num_frames=8, tolerance=2):
    """
    Analiza todos los spritesheets en una carpeta y reporta problemas.
    """
    folder = Path(folder_path)
    png_files = sorted(folder.glob('*_sheet_f*.png'))
    
    results = []
    
    for png_file in png_files:
        frames_info, img = analyze_spritesheet(png_file, frame_width, num_frames)
        has_issue, center_var, bottom_var = check_alignment(frames_info, tolerance)
        
        results.append({
            'file': png_file.name,
            'path': str(png_file),
            'has_issue': has_issue,
            'center_variation': center_var,
            'bottom_variation': bottom_var
        })
    
    return results

def process_folder(folder_path, frame_width=256, num_frames=8, backup=True, dry_run=False, fix_all=False, tolerance=2):
    """
    Procesa todos los spritesheets en una carpeta.
    """
    folder = Path(folder_path)
    png_files = sorted(folder.glob('*_sheet_f*.png'))
    
    print(f"\nAnalizando carpeta: {folder_path}")
    print(f"Encontrados {len(png_files)} spritesheets\n")
    
    fixed_count = 0
    skipped_count = 0
    
    for png_file in png_files:
        frames_info, img = analyze_spritesheet(png_file, frame_width, num_frames)
        has_issue, center_var, bottom_var = check_alignment(frames_info, tolerance)
        
        status = "⚠️ DESALINEADO" if has_issue else "✓ OK"
        print(f"{png_file.name}: {status}")
        print(f"  Variación centro X: {center_var:.1f}px, Variación base Y: {bottom_var:.1f}px")
        
        if has_issue or fix_all:
            if dry_run:
                print(f"  [DRY-RUN] Se corregiría")
            else:
                if backup:
                    backup_path = png_file.with_suffix('.png.backup')
                    if not backup_path.exists():
                        import shutil
                        shutil.copy2(png_file, backup_path)
                        print(f"  Backup creado: {backup_path.name}")
                
                if fix_alignment(str(png_file), str(png_file), frame_width, num_frames):
                    print(f"  ✓ Corregido")
                    fixed_count += 1
                else:
                    print(f"  ✗ Error al corregir")
        else:
            skipped_count += 1
    
    print(f"\nResumen: {fixed_count} corregidos, {skipped_count} sin cambios")
    return fixed_count

def main():
    parser = argparse.ArgumentParser(
        description='Corrige el alineamiento de frames en spritesheets animados'
    )
    parser.add_argument('folder', nargs='?', help='Carpeta a procesar')
    parser.add_argument('--frame-width', type=int, default=256, 
                        help='Ancho de cada frame (default: 256)')
    parser.add_argument('--num-frames', type=int, default=8,
                        help='Número de frames (default: 8)')
    parser.add_argument('--no-backup', action='store_true',
                        help='No crear backup de archivos originales')
    parser.add_argument('--dry-run', action='store_true',
                        help='Solo analizar, no modificar archivos')
    parser.add_argument('--fix-all', action='store_true',
                        help='Corregir todos los archivos, no solo los desalineados')
    parser.add_argument('--tolerance', type=int, default=2,
                        help='Tolerancia en píxeles para detectar desalineamiento (default: 2)')
    parser.add_argument('--analyze-only', action='store_true',
                        help='Solo mostrar análisis detallado')
    
    args = parser.parse_args()
    
    # Carpetas predeterminadas si no se especifica
    if not args.folder:
        base_path = Path(__file__).parent.parent / 'project' / 'assets' / 'textures' / 'biomes'
        folders = [
            base_path / 'Desert' / 'decor',
            base_path / 'Death' / 'decor'
        ]
    else:
        folders = [Path(args.folder)]
    
    for folder in folders:
        if not folder.exists():
            print(f"Carpeta no encontrada: {folder}")
            continue
        
        if args.analyze_only:
            results = analyze_and_report(folder, args.frame_width, args.num_frames, args.tolerance)
            print(f"\n{'='*60}")
            print(f"Análisis de: {folder}")
            print(f"{'='*60}")
            for r in results:
                status = "⚠️ DESALINEADO" if r['has_issue'] else "✓ OK"
                print(f"{r['file']}: {status}")
                print(f"  Centro X var: {r['center_variation']:.1f}px | Base Y var: {r['bottom_variation']:.1f}px")
        else:
            process_folder(
                folder,
                args.frame_width,
                args.num_frames,
                backup=not args.no_backup,
                dry_run=args.dry_run,
                fix_all=args.fix_all,
                tolerance=args.tolerance
            )

if __name__ == '__main__':
    main()
