#!/usr/bin/env python3
"""
Script para procesar spritesheets de Gemini dividiendo en partes iguales.
Asume que el spritesheet tiene frames del mismo tamaño dispuestos horizontalmente.
"""

import os
import sys
from PIL import Image

def process_gemini_spritesheet_equal(input_path, output_dir, biome_name, num_frames=8):
    """
    Procesa un spritesheet dividiendo en partes iguales.
    
    Args:
        input_path: Ruta al spritesheet de Gemini
        output_dir: Directorio donde guardar frames y spritesheet final
        biome_name: Nombre del bioma
        num_frames: Número de frames esperados (default: 8)
    """
    print(f"\n{'='*70}")
    print(f"PROCESANDO SPRITESHEET DE GEMINI → GODOT (División Igual)")
    print(f"{'='*70}")
    print(f"Input:  {input_path}")
    print(f"Bioma:  {biome_name}")
    print(f"Output: {output_dir}")
    print(f"Frames: {num_frames}\n")
    
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
        
        # Calcular ancho de cada frame
        frame_width = original_width // num_frames
        
        print(f"\n📐 Dividiendo en {num_frames} frames de {frame_width}×{original_height}px")
        
        # Extraer cada frame
        frames = []
        for i in range(num_frames):
            x_start = i * frame_width
            x_end = x_start + frame_width
            
            # Recortar frame
            frame = img.crop((x_start, 0, x_end, original_height))
            
            # Hacer cuadrado (tomar el centro si es rectangular)
            if frame_width != original_height:
                size = min(frame_width, original_height)
                
                # Centrar el recorte
                if frame_width > original_height:
                    # Más ancho que alto
                    x_offset = (frame_width - size) // 2
                    frame = frame.crop((x_offset, 0, x_offset + size, size))
                else:
                    # Más alto que ancho
                    y_offset = (original_height - size) // 2
                    frame = frame.crop((0, y_offset, size, y_offset + size))
            
            frames.append(frame)
            print(f"   ✅ Frame {i+1}/{num_frames} extraído")
        
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
        
        return True
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("❌ Uso: python process_gemini_spritesheet_v2.py <biome_name> <input_gemini_png>")
        sys.exit(1)
    
    biome_name = sys.argv[1]
    input_path = sys.argv[2]
    
    # Construir ruta de salida
    output_dir = f"project/assets/textures/biomes/{biome_name.capitalize()}/base"
    
    success = process_gemini_spritesheet_equal(input_path, output_dir, biome_name)
    
    sys.exit(0 if success else 1)
