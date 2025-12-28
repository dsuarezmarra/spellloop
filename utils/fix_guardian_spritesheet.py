"""
Script específico para procesar el spritesheet del Guardián de Runas
que tiene los sprites muy juntos y no puede ser detectado automáticamente.

Este spritesheet tiene 3 vistas claras (frente, lado, espalda) pero sin gaps claros.
Usamos división equitativa ya que los sprites están uniformemente distribuidos.
"""
from PIL import Image
import os

GAP_SIZE = 8

def process_guardian_spritesheet(input_path, output_path):
    """Procesa el spritesheet dividiendo en 3 partes iguales"""
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size
    
    print(f"Imagen original: {width}x{height}")
    
    # Encontrar el bounding box real (sin transparencia)
    bbox = img.getbbox()
    if bbox:
        print(f"Bounding box del contenido: {bbox}")
        # Recortar la imagen al contenido real
        img = img.crop(bbox)
        width, height = img.size
        print(f"Tamaño después de recortar: {width}x{height}")
    
    # Dividir en 3 partes iguales
    sprite_width = width // 3
    
    sprites = []
    for i in range(3):
        left = i * sprite_width
        right = (i + 1) * sprite_width if i < 2 else width
        
        # Extraer sprite
        sprite = img.crop((left, 0, right, height))
        
        # Encontrar el bounding box real del sprite individual
        sprite_bbox = sprite.getbbox()
        if sprite_bbox:
            sprite = sprite.crop(sprite_bbox)
        
        sprites.append(sprite)
        print(f"Sprite {i+1}: {sprite.size[0]}x{sprite.size[1]}")
    
    # Encontrar la altura máxima para normalizar
    max_height = max(s.size[1] for s in sprites)
    
    # Calcular el ancho total con gaps
    total_width = sum(s.size[0] for s in sprites) + (len(sprites) - 1) * GAP_SIZE
    
    # Crear la nueva imagen
    new_img = Image.new('RGBA', (total_width, max_height), (0, 0, 0, 0))
    
    # Colocar cada sprite
    x_offset = 0
    for i, sprite in enumerate(sprites):
        # Centrar verticalmente si es más pequeño
        y_offset = (max_height - sprite.size[1]) // 2
        new_img.paste(sprite, (x_offset, y_offset))
        x_offset += sprite.size[0] + GAP_SIZE
    
    # Guardar
    new_img.save(output_path)
    print(f"\n✅ Guardado: {output_path}")
    print(f"   Tamaño final: {total_width}x{max_height}")
    print(f"   Sprites: 3, Gap: {GAP_SIZE}px")

if __name__ == "__main__":
    # Rutas
    input_file = r"C:\git\spellloop\project\assets\sprites\enemies\bosses\el_guardian_de_runas_spritesheet.png"
    output_file = input_file  # Sobrescribir
    
    process_guardian_spritesheet(input_file, output_file)
