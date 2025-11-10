#!/usr/bin/env python3
"""
reduce_brightness.py
Reduce el brillo/intensidad de un sprite sheet PNG.
Útil para texturas base que tienen demasiada luminosidad.
"""

from pathlib import Path
from PIL import Image, ImageEnhance
import sys

def reduce_brightness(image_path: Path, output_path: Path, factor: float = 0.5):
    """
    Reducir el brillo de una imagen.
    
    Args:
        image_path: Ruta a la imagen de entrada
        output_path: Ruta donde guardar la imagen procesada
        factor: Factor de brillo (0.5 = mitad del brillo, 0.25 = cuarto, etc.)
    """
    print(f"\n{'='*70}")
    print(f"REDUCIENDO BRILLO DE TEXTURA")
    print(f"{'='*70}")
    print(f"Entrada:  {image_path.name}")
    print(f"Salida:   {output_path.name}")
    print(f"Factor:   {factor} ({int(factor*100)}% del brillo original)")
    print(f"{'='*70}\n")
    
    # Cargar imagen
    img = Image.open(image_path)
    original_mode = img.mode
    
    print(f"Dimensiones: {img.size[0]}×{img.size[1]}px")
    print(f"Modo:        {original_mode}")
    
    # Convertir a RGBA si no lo está ya
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Separar canales
    r, g, b, a = img.split()
    
    # Reducir brillo de RGB (no tocar alpha)
    rgb_img = Image.merge('RGB', (r, g, b))
    brightness_enhancer = ImageEnhance.Brightness(rgb_img)
    darkened_rgb = brightness_enhancer.enhance(factor)
    
    # Combinar de nuevo con alpha original
    r_new, g_new, b_new = darkened_rgb.split()
    result = Image.merge('RGBA', (r_new, g_new, b_new, a))
    
    # Guardar
    result.save(output_path, 'PNG')
    
    print(f"\n✅ Procesado completado")
    print(f"   Archivo guardado: {output_path}")
    print(f"{'='*70}\n")

def main():
    if len(sys.argv) < 2:
        print("USO: python reduce_brightness.py <archivo.png> [factor]")
        print("\nEjemplos:")
        print("  python reduce_brightness.py lava_base_animated_sheet_f8_512.png")
        print("  python reduce_brightness.py lava_base_animated_sheet_f8_512.png 0.5")
        print("  python reduce_brightness.py lava_base_animated_sheet_f8_512.png 0.7")
        print("\nFactor: 0.5 = mitad del brillo (default), 0.25 = cuarto del brillo, etc.")
        sys.exit(1)
    
    input_path = Path(sys.argv[1])
    factor = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
    
    if not input_path.exists():
        print(f"ERROR: Archivo no encontrado: {input_path}")
        sys.exit(1)
    
    # Crear nombre de salida con sufijo
    output_path = input_path.parent / f"{input_path.stem}_dimmed{input_path.suffix}"
    
    # Si ya existe un archivo _dimmed, sobrescribir el original
    if "_dimmed" in input_path.stem:
        # Ya es un archivo procesado, sobrescribir
        output_path = input_path
        print("⚠️  Sobrescribiendo archivo existente")
    
    reduce_brightness(input_path, output_path, factor)
    
    print(f"Para usar en el juego, renombra o mueve:")
    print(f"  {output_path.name}")
    print(f"  → {input_path.name}")

if __name__ == "__main__":
    main()
