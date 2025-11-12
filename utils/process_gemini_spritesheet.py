#!/usr/bin/env python3
"""
Script para procesar spritesheets de Gemini que vienen con bordes blancos.
Detecta automáticamente los frames, elimina bordes y crea spritesheet de Godot.
"""

import os
import sys
from PIL import Image
import numpy as np

def detect_frame_boundaries(image_array, threshold=250):
    """
    Detecta los límites de frames buscando líneas verticales blancas.
    
    Args:
        image_array: Array numpy de la imagen
        threshold: Umbral para considerar un píxel como blanco (0-255)
    
    Returns:
        Lista de tuplas (x_start, x_end) para cada frame
    """
    height, width = image_array.shape[:2]
    
    # Calcular el promedio vertical para cada columna
    if len(image_array.shape) == 3:
        vertical_avg = np.mean(image_array, axis=(0, 2))  # RGB
    else:
        vertical_avg = np.mean(image_array, axis=0)  # Grayscale
    
    # Detectar columnas blancas (separadores)
    white_columns = vertical_avg > threshold
    
    # Encontrar transiciones (inicio y fin de secciones no-blancas)
    diff = np.diff(white_columns.astype(int))
    starts = np.where(diff == -1)[0] + 1  # Cambio de blanco a contenido
    ends = np.where(diff == 1)[0]  # Cambio de contenido a blanco
    
    # Ajustar si el primer frame empieza al inicio
    if len(starts) > 0 and (len(ends) == 0 or starts[0] > ends[0]):
        starts = np.concatenate([[0], starts])
    
    # Ajustar si el último frame termina al final
    if len(ends) > 0 and (len(starts) == 0 or ends[-1] < starts[-1]):
        ends = np.concatenate([ends, [width - 1]])
    
    # Emparejar starts y ends
    frames = list(zip(starts, ends))
    
    return frames


def crop_to_square(img, x_start, x_end):
    """
    Recorta una región y la ajusta a un cuadrado centrado.
    
    Args:
        img: PIL Image
        x_start, x_end: Límites horizontales del frame
    
    Returns:
        PIL Image cuadrada
    """
    width, height = img.size
    frame_width = x_end - x_start
    
    # Si el frame es más ancho que alto, recortar horizontalmente
    # Si es más alto que ancho, recortar verticalmente
    size = min(frame_width, height)
    
    # Centrar el recorte
    x_offset = x_start + (frame_width - size) // 2
    y_offset = (height - size) // 2
    
    return img.crop((x_offset, y_offset, x_offset + size, y_offset + size))


def process_gemini_spritesheet(input_path, output_dir, biome_name, expected_frames=8):
    """
    Procesa un spritesheet de Gemini con bordes blancos.
    
    Args:
        input_path: Ruta al spritesheet de Gemini
        output_dir: Directorio donde guardar frames y spritesheet final
        biome_name: Nombre del bioma
        expected_frames: Número esperado de frames (default: 8)
    """
    print(f"\n{'='*70}")
    print(f"PROCESANDO SPRITESHEET DE GEMINI → GODOT")
    print(f"{'='*70}")
    print(f"Input:  {input_path}")
    print(f"Bioma:  {biome_name}")
    print(f"Output: {output_dir}\n")
    
    # Verificar que el archivo existe
    if not os.path.exists(input_path):
        print(f"❌ Error: Archivo no encontrado: {input_path}")
        return False
    
    # Crear directorio de salida
    os.makedirs(output_dir, exist_ok=True)
    
    try:
        # Cargar imagen
        img = Image.open(input_path)
        original_width, original_height = img.size
        
        print(f"📄 Imagen cargada: {original_width}×{original_height}px ({img.mode})")
        
        # Convertir a array para detección
        img_array = np.array(img)
        
        # Detectar límites de frames
        print(f"\n🔍 Detectando frames...")
        frame_boundaries = detect_frame_boundaries(img_array)
        
        num_frames = len(frame_boundaries)
        print(f"   ✅ Detectados {num_frames} frames")
        
        if num_frames != expected_frames:
            print(f"   ⚠️  ADVERTENCIA: Se esperaban {expected_frames} frames, se encontraron {num_frames}")
        
        # Extraer y procesar cada frame
        frames = []
        print(f"\n📐 Extrayendo frames:")
        
        for i, (x_start, x_end) in enumerate(frame_boundaries, 1):
            frame_width = x_end - x_start
            print(f"   Frame {i}: x={x_start}-{x_end} (ancho: {frame_width}px)")
            
            # Recortar frame y ajustar a cuadrado
            frame_square = crop_to_square(img, x_start, x_end)
            frames.append(frame_square)
            
            # Guardar frame individual (opcional, para verificación)
            frame_path = os.path.join(output_dir, f"frame_{i}_extracted.png")
            frame_square.save(frame_path)
        
        # Crear spritesheet final de Godot
        print(f"\n🎨 Creando spritesheet para Godot:")
        
        frame_size_final = 512  # Tamaño de cada frame en spritesheet final
        padding = 4
        final_width = (frame_size_final * num_frames) + (padding * (num_frames - 1))
        final_height = frame_size_final
        
        print(f"   Dimensiones finales: {final_width}×{final_height}px")
        print(f"   Frames: {num_frames} × {frame_size_final}×{frame_size_final}px")
        print(f"   Padding: {padding}px entre frames\n")
        
        # Crear spritesheet final
        final_sheet = Image.new('RGBA', (final_width, final_height), (0, 0, 0, 0))
        
        for i, frame in enumerate(frames):
            # Redimensionar frame a 512×512
            frame_resized = frame.resize((frame_size_final, frame_size_final), Image.Resampling.LANCZOS)
            
            # Convertir a RGBA si es necesario
            if frame_resized.mode != 'RGBA':
                frame_resized = frame_resized.convert('RGBA')
            
            # Calcular posición en spritesheet final (con padding)
            x_position = i * (frame_size_final + padding)
            
            # Pegar frame en spritesheet final
            final_sheet.paste(frame_resized, (x_position, 0))
            
            print(f"   ✅ Frame {i+1}/{num_frames}: Redimensionado y colocado")
        
        # Guardar resultado
        output_filename = f"{biome_name.lower()}_base_animated_sheet_f{num_frames}_512.png"
        output_path = os.path.join(output_dir, output_filename)
        
        final_sheet.save(output_path, format='PNG')
        
        # Verificar tamaño de archivo
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        
        print(f"\n{'='*70}")
        print(f"✅ COMPLETADO")
        print(f"{'='*70}")
        print(f"Archivo guardado: {output_path}")
        print(f"Tamaño: {file_size:.2f} MB")
        print(f"Dimensiones: {final_width}×{final_height}px")
        print(f"Frames: {num_frames}\n")
        
        print(f"💡 SIGUIENTE PASO:")
        print(f"   1. Verifica el spritesheet generado")
        print(f"   2. Si el .import no existe, créalo")
        print(f"   3. Abre Godot y prueba en test_grassland_decorations.tscn")
        print(f"   4. CRÍTICO: Verifica que NO hay costuras entre tiles\n")
        
        return True
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("❌ Uso: python process_gemini_spritesheet.py <biome_name> <input_gemini_png>")
        print("\nEjemplos:")
        print('  python process_gemini_spritesheet.py grassland "gemini_grassland.png"')
        print('  python process_gemini_spritesheet.py lava "C:/Downloads/gemini_lava_spritesheet.png"')
        print("\nEl script:")
        print("  1. Detecta automáticamente los frames separados por líneas blancas")
        print("  2. Elimina los bordes blancos")
        print("  3. Extrae cada frame y lo ajusta a cuadrado")
        print("  4. Redimensiona cada frame a 512×512")
        print("  5. Crea spritesheet final con padding de 4px")
        print('  6. Guarda en "project/assets/textures/biomes/<BIOME>/base/"')
        sys.exit(1)
    
    biome_name = sys.argv[1]
    input_path = sys.argv[2]
    
    # Construir ruta de salida
    output_dir = f"project/assets/textures/biomes/{biome_name.capitalize()}/base"
    
    success = process_gemini_spritesheet(input_path, output_dir, biome_name)
    
    sys.exit(0 if success else 1)
