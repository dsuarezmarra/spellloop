#!/usr/bin/env python3
"""
Script para procesar spritesheets generados por DALL-E 3 (8192×1024px)
y convertirlos al formato requerido por Godot (4124×512px con padding).

DALL-E genera: 8192×1024px (8 frames de 1024×1024 sin padding)
Godot necesita: 4124×512px (8 frames de 512×512 con 4px padding entre frames)
"""

import os
import sys
from PIL import Image

def process_dalle_spritesheet(input_path, output_dir, biome_name):
    """
    Procesa un spritesheet de DALL-E y lo convierte al formato de Godot.
    
    Args:
        input_path: Ruta al archivo PNG generado por DALL-E (8192×1024)
        output_dir: Directorio donde guardar el resultado
        biome_name: Nombre del bioma (para nombrar archivo de salida)
    """
    print(f"\n{'='*70}")
    print(f"PROCESANDO SPRITESHEET DE DALL-E → GODOT")
    print(f"{'='*70}")
    print(f"Input:  {input_path}")
    print(f"Bioma:  {biome_name}")
    print(f"Output: {output_dir}\n")
    
    # Verificar que el archivo existe
    if not os.path.exists(input_path):
        print(f"❌ Error: Archivo no encontrado: {input_path}")
        return False
    
    # Crear directorio de salida si no existe
    os.makedirs(output_dir, exist_ok=True)
    
    try:
        # Cargar imagen
        img = Image.open(input_path)
        width, height = img.size
        
        print(f"📄 Imagen cargada: {width}×{height}px ({img.mode})")
        
        # Verificar dimensiones esperadas
        if width != 8192 or height != 1024:
            print(f"⚠️  ADVERTENCIA: Dimensiones inesperadas. Esperado: 8192×1024, Obtenido: {width}×{height}")
            print(f"    Intentando procesar de todas formas...")
        
        # Convertir a RGBA si es necesario
        if img.mode != 'RGBA':
            print(f"   Convirtiendo {img.mode} → RGBA")
            img = img.convert('RGBA')
        
        # Dimensiones finales
        frame_size_final = 512  # Tamaño de cada frame en spritesheet final
        padding = 4
        final_width = (frame_size_final * 8) + (padding * 7)  # 4124px
        final_height = frame_size_final  # 512px
        
        print(f"\n🔧 Procesando frames:")
        print(f"   Spritesheet final: {final_width}×{final_height}px")
        print(f"   Frames: 8 × {frame_size_final}×{frame_size_final}px")
        print(f"   Padding: {padding}px entre frames\n")
        
        # Crear spritesheet final
        final_sheet = Image.new('RGBA', (final_width, final_height), (0, 0, 0, 0))
        
        # Calcular tamaño de frame en imagen original
        frame_size_original = width // 8  # Debería ser 1024
        
        # Procesar cada frame
        for i in range(8):
            # Extraer frame de imagen original
            x_start = i * frame_size_original
            frame = img.crop((x_start, 0, x_start + frame_size_original, height))
            
            # Redimensionar frame a 512×512
            frame_resized = frame.resize((frame_size_final, frame_size_final), Image.Resampling.LANCZOS)
            
            # Calcular posición en spritesheet final (con padding)
            x_position = i * (frame_size_final + padding)
            
            # Pegar frame en spritesheet final
            final_sheet.paste(frame_resized, (x_position, 0))
            
            print(f"   ✅ Frame {i+1}/8: {frame_size_original}×{height}px → {frame_size_final}×{frame_size_final}px")
        
        # Guardar resultado
        output_filename = f"{biome_name.lower()}_base_animated_sheet_f8_512.png"
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
        print(f"Modo: {final_sheet.mode}\n")
        
        print(f"💡 SIGUIENTE PASO:")
        print(f"   1. Verifica que el archivo .import existe (si no, créalo)")
        print(f"   2. Abre Godot y prueba la animación")
        print(f"   3. Verifica que NO hay costuras entre tiles (seamless)\n")
        
        return True
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("❌ Uso: python process_dalle_spritesheet.py <biome_name> <input_dalle_png>")
        print("\nEjemplos:")
        print('  python process_dalle_spritesheet.py grassland "dalle_grassland.png"')
        print('  python process_dalle_spritesheet.py lava "C:/Downloads/dalle_lava_spritesheet.png"')
        print("\nEl script:")
        print("  1. Toma el spritesheet de DALL-E (8192×1024px)")
        print("  2. Divide en 8 frames de 1024×1024")
        print("  3. Redimensiona cada frame a 512×512")
        print("  4. Crea spritesheet final 4124×512 con padding de 4px")
        print('  5. Guarda en "project/assets/textures/biomes/<BIOME>/base/"')
        sys.exit(1)
    
    biome_name = sys.argv[1]
    input_path = sys.argv[2]
    
    # Construir ruta de salida
    output_dir = f"project/assets/textures/biomes/{biome_name.capitalize()}/base"
    
    success = process_dalle_spritesheet(input_path, output_dir, biome_name)
    
    sys.exit(0 if success else 1)
