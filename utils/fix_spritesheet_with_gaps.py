#!/usr/bin/env python3
"""
Script inteligente para añadir gaps entre sprites en spritesheets.

Este script:
1. Detecta los sprites individuales analizando columnas con contenido no-transparente
2. Encuentra los límites REALES de cada sprite (bounding box)
3. Extrae cada sprite sin cortar contenido
4. Reconstruye el spritesheet con gaps de 8px entre sprites

Uso: python fix_spritesheet_with_gaps.py [ruta_imagen]
Si no se especifica ruta, procesa todos los spritesheets de enemigos.
"""

import os
import sys
from PIL import Image
import numpy as np

# Configuración
GAP_SIZE = 8  # Pixels de separación entre sprites
NUM_SPRITES = 3  # Número de sprites por spritesheet (front, side, back)

def find_sprite_columns(img_array):
    """
    Encuentra las columnas que contienen contenido no-transparente.
    
    Args:
        img_array: Array numpy de la imagen (RGBA)
    
    Returns:
        Lista de índices de columnas con contenido
    """
    # Obtener el canal alpha (4to canal en RGBA)
    alpha = img_array[:, :, 3]
    
    # Una columna tiene contenido si hay algún pixel con alpha > 0
    columns_with_content = []
    for col_idx in range(alpha.shape[1]):
        if np.any(alpha[:, col_idx] > 0):
            columns_with_content.append(col_idx)
    
    return columns_with_content

def find_sprite_regions(columns_with_content, min_gap=5):
    """
    Agrupa las columnas con contenido en regiones de sprites separadas.
    
    Args:
        columns_with_content: Lista de índices de columnas con contenido
        min_gap: Mínimo espacio entre regiones para considerarlas separadas
    
    Returns:
        Lista de tuplas (start_col, end_col) para cada sprite
    """
    if not columns_with_content:
        return []
    
    regions = []
    start = columns_with_content[0]
    prev = columns_with_content[0]
    
    for col in columns_with_content[1:]:
        # Si hay un gap significativo, es un nuevo sprite
        if col - prev > min_gap:
            regions.append((start, prev))
            start = col
        prev = col
    
    # Añadir la última región
    regions.append((start, prev))
    
    return regions

def find_sprite_rows(img_array, col_start, col_end):
    """
    Encuentra las filas con contenido para un sprite específico.
    
    Args:
        img_array: Array numpy de la imagen (RGBA)
        col_start: Columna inicial del sprite
        col_end: Columna final del sprite
    
    Returns:
        Tupla (row_start, row_end) del bounding box vertical
    """
    alpha = img_array[:, col_start:col_end+1, 3]
    
    rows_with_content = []
    for row_idx in range(alpha.shape[0]):
        if np.any(alpha[row_idx, :] > 0):
            rows_with_content.append(row_idx)
    
    if not rows_with_content:
        return (0, img_array.shape[0] - 1)
    
    return (rows_with_content[0], rows_with_content[-1])

def extract_sprite(img, col_start, col_end, row_start, row_end):
    """
    Extrae un sprite de la imagen usando su bounding box.
    
    Args:
        img: Imagen PIL
        col_start, col_end: Límites horizontales
        row_start, row_end: Límites verticales
    
    Returns:
        Imagen PIL del sprite extraído
    """
    return img.crop((col_start, row_start, col_end + 1, row_end + 1))

def process_spritesheet(input_path, output_path=None):
    """
    Procesa un spritesheet añadiendo gaps entre sprites.
    
    Args:
        input_path: Ruta al spritesheet original
        output_path: Ruta de salida (si es None, sobrescribe el original)
    
    Returns:
        True si se procesó correctamente, False en caso contrario
    """
    if output_path is None:
        output_path = input_path
    
    print(f"\nProcesando: {os.path.basename(input_path)}")
    
    try:
        # Cargar imagen
        img = Image.open(input_path)
        
        # Asegurar modo RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        img_array = np.array(img)
        
        # Paso 1: Encontrar columnas con contenido
        columns_with_content = find_sprite_columns(img_array)
        
        if not columns_with_content:
            print(f"  ⚠ No se encontró contenido en la imagen")
            return False
        
        # Paso 2: Identificar regiones de sprites
        sprite_regions = find_sprite_regions(columns_with_content)
        
        print(f"  📊 Sprites detectados: {len(sprite_regions)}")
        
        if len(sprite_regions) != NUM_SPRITES:
            print(f"  ⚠ Se esperaban {NUM_SPRITES} sprites, se encontraron {len(sprite_regions)}")
            # Intentar con un gap más pequeño
            sprite_regions = find_sprite_regions(columns_with_content, min_gap=2)
            print(f"  📊 Reintento con min_gap=2: {len(sprite_regions)} sprites")
            
            if len(sprite_regions) != NUM_SPRITES:
                print(f"  ❌ No se pudo detectar correctamente los sprites")
                return False
        
        # Paso 3: Calcular bounding boxes completos de cada sprite
        sprites_data = []
        for i, (col_start, col_end) in enumerate(sprite_regions):
            row_start, row_end = find_sprite_rows(img_array, col_start, col_end)
            
            sprite_width = col_end - col_start + 1
            sprite_height = row_end - row_start + 1
            
            sprites_data.append({
                'col_start': col_start,
                'col_end': col_end,
                'row_start': row_start,
                'row_end': row_end,
                'width': sprite_width,
                'height': sprite_height
            })
            
            print(f"  Sprite {i+1}: cols [{col_start}-{col_end}], rows [{row_start}-{row_end}], size {sprite_width}x{sprite_height}")
        
        # Paso 4: Calcular dimensiones del nuevo spritesheet
        # Todos los sprites tendrán la misma altura (la máxima)
        max_height = max(s['height'] for s in sprites_data)
        total_width = sum(s['width'] for s in sprites_data) + GAP_SIZE * (NUM_SPRITES - 1)
        
        print(f"  📐 Nueva dimensión: {total_width}x{max_height} (con gaps de {GAP_SIZE}px)")
        
        # Paso 5: Crear nueva imagen y colocar sprites
        new_img = Image.new('RGBA', (total_width, max_height), (0, 0, 0, 0))
        
        x_offset = 0
        for i, sprite_info in enumerate(sprites_data):
            # Extraer sprite
            sprite = extract_sprite(
                img,
                sprite_info['col_start'],
                sprite_info['col_end'],
                sprite_info['row_start'],
                sprite_info['row_end']
            )
            
            # Centrar verticalmente si es necesario
            y_offset = (max_height - sprite_info['height']) // 2
            
            # Pegar sprite
            new_img.paste(sprite, (x_offset, y_offset))
            
            # Avanzar posición
            x_offset += sprite_info['width']
            
            # Añadir gap (excepto después del último sprite)
            if i < NUM_SPRITES - 1:
                x_offset += GAP_SIZE
        
        # Paso 6: Guardar imagen
        new_img.save(output_path, 'PNG')
        print(f"  ✅ Guardado: {output_path}")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Función principal."""
    
    # Si se proporciona una ruta específica, procesar solo esa
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
        if os.path.exists(input_path):
            process_spritesheet(input_path)
        else:
            print(f"Error: No se encontró el archivo {input_path}")
        return
    
    # Directorios de enemigos
    base_dir = r"c:\git\spellloop\project\assets\sprites\enemies"
    tier_dirs = ['tier_1', 'tier_2', 'tier_3', 'tier_4']
    
    processed = 0
    errors = 0
    
    print("=" * 60)
    print("PROCESAMIENTO DE SPRITESHEETS CON DETECCIÓN INTELIGENTE")
    print("=" * 60)
    
    for tier in tier_dirs:
        tier_path = os.path.join(base_dir, tier)
        if not os.path.exists(tier_path):
            continue
            
        print(f"\n📁 Procesando {tier}...")
        
        for filename in os.listdir(tier_path):
            if filename.endswith('_spritesheet.png'):
                filepath = os.path.join(tier_path, filename)
                
                if process_spritesheet(filepath):
                    processed += 1
                else:
                    errors += 1
    
    print("\n" + "=" * 60)
    print(f"RESUMEN: {processed} procesados, {errors} errores")
    print("=" * 60)

if __name__ == "__main__":
    main()
