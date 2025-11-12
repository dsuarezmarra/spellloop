#!/usr/bin/env python3
"""
Script para convertir texturas NO-seamless en texturas seamless/tileable.
Usa técnica de offset y blend en los bordes para eliminar costuras visibles.
"""

import os
import sys
from PIL import Image, ImageFilter
import numpy as np

def make_seamless(image, blend_size=64):
    """
    Convierte una imagen en seamless usando técnica de offset y blend.
    
    Args:
        image: PIL Image object
        blend_size: Píxeles de blend en cada borde (default: 64)
    
    Returns:
        PIL Image seamless
    """
    width, height = image.size
    
    # Convertir a numpy array para procesamiento
    img_array = np.array(image)
    
    # Crear imagen con offset (rotar la mitad)
    offset_x = width // 2
    offset_y = height // 2
    
    # Crear nueva imagen con los cuadrantes rotados
    result = np.zeros_like(img_array)
    
    # Cuadrante superior izquierdo va a inferior derecho
    result[offset_y:, offset_x:] = img_array[:height-offset_y, :width-offset_x]
    # Cuadrante superior derecho va a inferior izquierdo
    result[offset_y:, :offset_x] = img_array[:height-offset_y, offset_x:]
    # Cuadrante inferior izquierdo va a superior derecho
    result[:offset_y, offset_x:] = img_array[offset_y:, :width-offset_x]
    # Cuadrante inferior derecho va a superior izquierdo
    result[:offset_y, :offset_x] = img_array[offset_y:, offset_x:]
    
    # Aplicar blur en la "cruz" central donde se unen los bordes
    result_img = Image.fromarray(result)
    
    # Crear máscaras para el blend
    mask_h = np.zeros((height, width), dtype=float)
    mask_v = np.zeros((height, width), dtype=float)
    
    # Máscara horizontal (blend en centro vertical)
    for i in range(blend_size):
        alpha = i / blend_size
        mask_h[offset_y - blend_size//2 + i, :] = alpha
        mask_h[offset_y + blend_size//2 - i - 1, :] = alpha
    
    # Máscara vertical (blend en centro horizontal)
    for i in range(blend_size):
        alpha = i / blend_size
        mask_v[:, offset_x - blend_size//2 + i] = alpha
        mask_v[:, offset_x + blend_size//2 - i - 1] = alpha
    
    # Aplicar blur solo en las áreas de transición
    blurred = result_img.filter(ImageFilter.GaussianBlur(radius=blend_size//4))
    blurred_array = np.array(blurred)
    
    # Blend basado en las máscaras
    for c in range(img_array.shape[2] if len(img_array.shape) > 2 else 1):
        if len(img_array.shape) > 2:
            result[:, :, c] = (result[:, :, c] * (1 - mask_h) + 
                              blurred_array[:, :, c] * mask_h).astype(np.uint8)
            result[:, :, c] = (result[:, :, c] * (1 - mask_v) + 
                              blurred_array[:, :, c] * mask_v).astype(np.uint8)
        else:
            result = (result * (1 - mask_h) + blurred_array * mask_h).astype(np.uint8)
            result = (result * (1 - mask_v) + blurred_array * mask_v).astype(np.uint8)
    
    return Image.fromarray(result)


def process_frames(input_dir, output_dir=None, blend_size=64):
    """
    Procesa todos los frames en un directorio para hacerlos seamless.
    
    Args:
        input_dir: Directorio con frames originales (1.png - 8.png)
        output_dir: Directorio de salida (None = sobrescribir originales)
        blend_size: Tamaño del blend en píxeles
    """
    if output_dir is None:
        output_dir = input_dir
    else:
        os.makedirs(output_dir, exist_ok=True)
    
    print(f"\n{'='*60}")
    print(f"PROCESANDO FRAMES PARA SEAMLESS")
    print(f"{'='*60}")
    print(f"Input:  {input_dir}")
    print(f"Output: {output_dir}")
    print(f"Blend:  {blend_size} píxeles\n")
    
    frames_processed = 0
    
    for i in range(1, 9):  # Frames 1-8
        input_path = os.path.join(input_dir, f"{i}.png")
        output_path = os.path.join(output_dir, f"{i}_seamless.png")
        
        if not os.path.exists(input_path):
            print(f"⚠️  Frame {i}: No encontrado - {input_path}")
            continue
        
        try:
            # Cargar imagen
            img = Image.open(input_path)
            original_mode = img.mode
            width, height = img.size
            
            print(f"📄 Frame {i}: {width}×{height}px ({original_mode})")
            
            # Procesar para seamless
            seamless_img = make_seamless(img, blend_size=blend_size)
            
            # Guardar
            seamless_img.save(output_path, format='PNG')
            
            # Verificar tamaño de archivo
            file_size = os.path.getsize(output_path) / (1024 * 1024)
            print(f"   ✅ Guardado: {output_path} ({file_size:.2f} MB)")
            
            frames_processed += 1
            
        except Exception as e:
            print(f"   ❌ Error procesando frame {i}: {e}")
    
    print(f"\n{'='*60}")
    print(f"✅ COMPLETADO: {frames_processed}/8 frames procesados")
    print(f"{'='*60}\n")
    
    if frames_processed == 8:
        print("💡 SIGUIENTE PASO:")
        print(f"   1. Revisa los archivos *_seamless.png en {output_dir}")
        print(f"   2. Si se ven bien, renómbralos (1_seamless.png → 1.png)")
        print(f"   3. Regenera el spritesheet con create_spritesheet_like_snow.py")
    else:
        print("⚠️  ADVERTENCIA: No se procesaron todos los frames")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Uso: python make_seamless.py <directorio_frames> [output_dir] [blend_size]")
        print("\nEjemplos:")
        print('  python make_seamless.py "project/assets/textures/biomes/Grassland/base"')
        print('  python make_seamless.py "project/assets/textures/biomes/Grassland/base" "output" 80')
        sys.exit(1)
    
    input_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None
    blend_size = int(sys.argv[3]) if len(sys.argv) > 3 else 64
    
    if not os.path.exists(input_dir):
        print(f"❌ Error: Directorio no encontrado: {input_dir}")
        sys.exit(1)
    
    process_frames(input_dir, output_dir, blend_size)
