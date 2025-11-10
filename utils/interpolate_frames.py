#!/usr/bin/env python3
"""
interpolate_frames.py
Crea frames intermedios entre frames existentes para suavizar animaciones.
Usa interpolación lineal para crear transiciones suaves.
"""

from pathlib import Path
from PIL import Image
import sys

def interpolate_frames(input_path: Path, output_dir: Path, interpolation_steps: int = 1):
    """
    Crear frames intermedios entre frames existentes de un sprite sheet.
    
    Args:
        input_path: Sprite sheet horizontal de entrada
        output_dir: Directorio donde guardar frames individuales
        interpolation_steps: Número de frames intermedios entre cada par (1 = duplicar frames)
    """
    print(f"\n{'='*70}")
    print(f"INTERPOLACIÓN DE FRAMES PARA ANIMACIÓN SUAVE")
    print(f"{'='*70}")
    print(f"Entrada:       {input_path.name}")
    print(f"Interpolación: {interpolation_steps} frame(s) intermedio(s)")
    print(f"{'='*70}\n")
    
    # Cargar sprite sheet
    img = Image.open(input_path)
    width, height = img.size
    
    # Detectar número de frames y tamaño
    # Asumiendo patrón: 8 frames de 512px + 7 separadores de 4px = 4124px
    frame_size = 512
    padding = 4
    num_frames = (width + padding) // (frame_size + padding)
    
    print(f"Sprite sheet: {width}×{height}px")
    print(f"Frames detectados: {num_frames}")
    print(f"Tamaño por frame: {frame_size}×{frame_size}px\n")
    
    # Extraer frames originales
    original_frames = []
    x = 0
    for i in range(num_frames):
        frame = img.crop((x, 0, x + frame_size, height))
        original_frames.append(frame)
        x += frame_size + padding
    
    print(f"Extrayendo {len(original_frames)} frames originales...")
    
    # Crear frames interpolados
    interpolated_frames = []
    
    for i in range(len(original_frames)):
        # Añadir frame original
        interpolated_frames.append(original_frames[i])
        
        # Añadir frames intermedios (excepto después del último)
        if i < len(original_frames) - 1:
            frame_a = original_frames[i]
            frame_b = original_frames[i + 1]
            
            for step in range(1, interpolation_steps + 1):
                alpha = step / (interpolation_steps + 1)
                interpolated = Image.blend(frame_a, frame_b, alpha)
                interpolated_frames.append(interpolated)
    
    # Añadir interpolación entre último y primero (loop)
    frame_a = original_frames[-1]
    frame_b = original_frames[0]
    for step in range(1, interpolation_steps + 1):
        alpha = step / (interpolation_steps + 1)
        interpolated = Image.blend(frame_a, frame_b, alpha)
        interpolated_frames.append(interpolated)
    
    print(f"✓ Frames totales después de interpolar: {len(interpolated_frames)}")
    print(f"  (Original: {num_frames}, Interpolados: {len(interpolated_frames) - num_frames})\n")
    
    # Crear nuevo sprite sheet
    total_frames = len(interpolated_frames)
    new_width = (frame_size * total_frames) + (padding * (total_frames - 1))
    new_spritesheet = Image.new('RGBA', (new_width, height), (0, 0, 0, 0))
    
    x = 0
    for i, frame in enumerate(interpolated_frames):
        new_spritesheet.paste(frame, (x, 0))
        x += frame_size + padding
    
    # Guardar con nombre apropiado
    output_name = f"{input_path.stem.replace(f'_f{num_frames}_', f'_f{total_frames}_')}_smooth{input_path.suffix}"
    output_path = output_dir / output_name
    
    new_spritesheet.save(output_path, 'PNG')
    
    print(f"✅ Sprite sheet suavizado creado:")
    print(f"   {output_path}")
    print(f"   Dimensiones: {new_width}×{height}px")
    print(f"   Frames: {total_frames}")
    print(f"\n{'='*70}\n")
    
    return output_path, total_frames

def main():
    if len(sys.argv) < 2:
        print("USO: python interpolate_frames.py <spritesheet.png> [steps]")
        print("\nEjemplos:")
        print("  python interpolate_frames.py lava_base_animated_sheet_f8_512.png")
        print("  python interpolate_frames.py lava_base_animated_sheet_f8_512.png 2")
        print("\nSteps: Número de frames intermedios entre cada par")
        print("  1 = duplica frames (8 → 16 frames)")
        print("  2 = triplica frames (8 → 24 frames)")
        print("  3 = cuadruplica frames (8 → 32 frames)")
        sys.exit(1)
    
    input_path = Path(sys.argv[1])
    steps = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    
    if not input_path.exists():
        print(f"ERROR: Archivo no encontrado: {input_path}")
        sys.exit(1)
    
    output_dir = input_path.parent
    interpolate_frames(input_path, output_dir, steps)

if __name__ == "__main__":
    main()
