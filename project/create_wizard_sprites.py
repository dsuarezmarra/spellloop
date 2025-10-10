#!/usr/bin/env python3
# create_wizard_sprites.py - Crea sprites PNG basados en las imágenes del usuario
import os
from PIL import Image, ImageDraw
import math

def create_sprite_directory():
    """Crear directorio de sprites si no existe"""
    os.makedirs("sprites/wizard", exist_ok=True)
    print("✓ Directorio sprites/wizard creado")

def draw_oval(draw, x, y, width, height, color):
    """Dibuja un óvalo"""
    draw.ellipse([x, y, x + width, y + height], fill=color)

def draw_star(draw, x, y, size, color):
    """Dibuja una estrella de 5 puntas"""
    points = []
    for i in range(10):
        angle = i * math.pi / 5
        if i % 2 == 0:
            r = size
        else:
            r = size // 2
        px = x + r * math.cos(angle - math.pi/2)
        py = y + r * math.sin(angle - math.pi/2)
        points.append((px, py))
    draw.polygon(points, fill=color)

def create_wizard_down():
    """Crea sprite del mago mirando hacia abajo (imagen 1 del usuario)"""
    image = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Colores basados en las imágenes del usuario
    skin_color = (255, 235, 205)
    hat_color = (51, 128, 230)
    hat_band_color = (38, 51, 153)
    beard_color = (255, 255, 255)
    robe_color = (51, 128, 230)
    belt_color = (102, 64, 26)
    staff_color = (102, 64, 26)
    orb_color = (77, 179, 255)
    boot_color = (26, 26, 26)
    
    # Cabeza ovalada (estilo Isaac)
    draw_oval(draw, 18, 12, 28, 24, skin_color)
    
    # Sombrero azul con estrellas
    draw_oval(draw, 16, 5, 32, 20, hat_color)
    # Punta del sombrero
    draw.polygon([(32, 2), (25, 15), (39, 15)], fill=hat_color)
    # Banda del sombrero
    draw.rectangle([18, 18, 46, 22], fill=hat_band_color)
    
    # Estrellas en el sombrero
    draw_star(draw, 22, 10, 3, (255, 255, 255))
    draw_star(draw, 30, 8, 3, (255, 255, 255))
    draw_star(draw, 38, 12, 3, (255, 255, 255))
    draw_star(draw, 26, 15, 3, (255, 255, 255))
    # Estrella flotante
    draw_star(draw, 48, 8, 4, (204, 230, 255))
    
    # Ojos grandes (estilo Funko Pop)
    draw.ellipse([24, 18, 30, 24], fill=(0, 0, 0))
    draw.ellipse([34, 18, 40, 24], fill=(0, 0, 0))
    
    # Barba blanca
    draw_oval(draw, 22, 26, 20, 16, beard_color)
    
    # Túnica azul
    draw_oval(draw, 20, 42, 24, 18, robe_color)
    
    # Cinturón marrón
    draw.rectangle([24, 48, 40, 52], fill=belt_color)
    # Bolsas del cinturón
    draw_oval(draw, 20, 50, 6, 8, belt_color)
    draw_oval(draw, 38, 50, 6, 8, belt_color)
    
    # Brazos
    draw_oval(draw, 12, 38, 10, 16, robe_color)
    draw_oval(draw, 40, 38, 10, 16, robe_color)
    
    # Bastón mágico
    draw.rectangle([46, 28, 50, 52], fill=staff_color)
    draw.ellipse([43, 22, 53, 32], fill=orb_color)
    draw.ellipse([45, 24, 51, 30], fill=(153, 204, 255))
    
    # Botas negras
    draw_oval(draw, 26, 58, 8, 6, boot_color)
    draw_oval(draw, 32, 58, 8, 6, boot_color)
    
    image.save("sprites/wizard/wizard_down.png")
    print("✓ wizard_down.png creado")

def create_wizard_left():
    """Crea sprite del mago perfil izquierda (imagen 2 del usuario)"""
    image = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    skin_color = (255, 235, 205)
    hat_color = (51, 128, 230)
    hat_band_color = (38, 51, 153)
    beard_color = (255, 255, 255)
    robe_color = (51, 128, 230)
    belt_color = (102, 64, 26)
    staff_color = (102, 64, 26)
    orb_color = (77, 179, 255)
    boot_color = (26, 26, 26)
    
    # Cabeza en perfil
    draw_oval(draw, 24, 12, 22, 24, skin_color)
    
    # Sombrero en perfil
    draw_oval(draw, 22, 5, 28, 20, hat_color)
    # Punta curvada hacia la izquierda
    draw.polygon([(18, 8), (22, 20), (15, 12)], fill=hat_color)
    draw.rectangle([24, 18, 48, 22], fill=hat_band_color)
    
    # Estrellas
    draw_star(draw, 30, 10, 3, (255, 255, 255))
    draw_star(draw, 38, 12, 3, (255, 255, 255))
    draw_star(draw, 16, 8, 4, (204, 230, 255))
    
    # Ojo visible en perfil
    draw.ellipse([30, 18, 36, 24], fill=(0, 0, 0))
    
    # Barba en perfil
    draw_oval(draw, 20, 26, 18, 14, beard_color)
    
    # Túnica en perfil
    draw_oval(draw, 24, 42, 20, 18, robe_color)
    
    # Cinturón
    draw.rectangle([26, 48, 40, 52], fill=belt_color)
    draw_oval(draw, 36, 50, 6, 8, belt_color)
    
    # Bastón visible
    draw.rectangle([42, 28, 46, 52], fill=staff_color)
    draw.ellipse([39, 22, 49, 32], fill=orb_color)
    
    # Pies en perfil
    draw_oval(draw, 28, 58, 10, 6, boot_color)
    draw_oval(draw, 34, 58, 8, 6, boot_color)
    
    image.save("sprites/wizard/wizard_left.png")
    print("✓ wizard_left.png creado")

def create_wizard_up():
    """Crea sprite del mago mirando hacia arriba (imagen 3 del usuario)"""
    image = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    skin_color = (255, 235, 205)
    hat_color = (51, 128, 230)
    hat_band_color = (38, 51, 153)
    beard_color = (255, 255, 255)
    robe_color = (51, 128, 230)
    belt_color = (102, 64, 26)
    staff_color = (102, 64, 26)
    orb_color = (77, 179, 255)
    boot_color = (26, 26, 26)
    
    # Cabeza
    draw_oval(draw, 18, 12, 28, 24, skin_color)
    
    # Sombrero más prominente
    draw_oval(draw, 15, 3, 34, 22, hat_color)
    draw.polygon([(32, 1), (24, 16), (40, 16)], fill=hat_color)
    draw.rectangle([17, 18, 47, 22], fill=hat_band_color)
    
    # Más estrellas visibles
    draw_star(draw, 20, 8, 3, (255, 255, 255))
    draw_star(draw, 28, 6, 3, (255, 255, 255))
    draw_star(draw, 36, 9, 3, (255, 255, 255))
    draw_star(draw, 42, 12, 3, (255, 255, 255))
    draw_star(draw, 50, 6, 4, (204, 230, 255))
    
    # Ojos
    draw.ellipse([24, 18, 30, 24], fill=(0, 0, 0))
    draw.ellipse([34, 18, 40, 24], fill=(0, 0, 0))
    
    # Barba
    draw_oval(draw, 22, 26, 20, 16, beard_color)
    
    # Túnica
    draw_oval(draw, 20, 42, 24, 18, robe_color)
    
    # Cinturón y bolsas
    draw.rectangle([24, 48, 40, 52], fill=belt_color)
    draw_oval(draw, 20, 50, 6, 8, belt_color)
    draw_oval(draw, 38, 50, 6, 8, belt_color)
    
    # Bastón
    draw.rectangle([46, 28, 50, 52], fill=staff_color)
    draw.ellipse([43, 22, 53, 32], fill=orb_color)
    
    # Pies
    draw_oval(draw, 26, 58, 8, 6, boot_color)
    draw_oval(draw, 32, 58, 8, 6, boot_color)
    
    image.save("sprites/wizard/wizard_up.png")
    print("✓ wizard_up.png creado")

def create_wizard_right():
    """Crea sprite del mago desde espaldas (imagen 4 del usuario)"""
    image = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    skin_color = (255, 235, 205)
    hat_color = (51, 128, 230)
    hat_band_color = (38, 51, 153)
    beard_color = (255, 255, 255)
    robe_color = (51, 128, 230)
    belt_color = (102, 64, 26)
    staff_color = (102, 64, 26)
    orb_color = (77, 179, 255)
    boot_color = (26, 26, 26)
    
    # Sombrero desde atrás
    draw_oval(draw, 16, 5, 32, 22, hat_color)
    draw.polygon([(32, 2), (26, 18), (38, 18)], fill=hat_color)
    draw.rectangle([18, 20, 46, 24], fill=hat_band_color)
    
    # Estrellas visibles desde atrás
    draw_star(draw, 22, 10, 3, (255, 255, 255))
    draw_star(draw, 30, 8, 3, (255, 255, 255))
    draw_star(draw, 38, 11, 3, (255, 255, 255))
    draw_star(draw, 48, 8, 4, (204, 230, 255))
    
    # Cabeza menos visible
    draw_oval(draw, 20, 15, 24, 20, skin_color)
    
    # Pelo/barba visible por los lados
    draw_oval(draw, 16, 22, 6, 10, beard_color)
    draw_oval(draw, 42, 22, 6, 10, beard_color)
    
    # Túnica desde atrás
    draw_oval(draw, 20, 40, 24, 20, robe_color)
    
    # Cinturón desde atrás
    draw.rectangle([24, 48, 40, 52], fill=belt_color)
    draw_oval(draw, 38, 50, 6, 8, belt_color)
    
    # Bastón visible por el lado
    draw.rectangle([42, 30, 46, 52], fill=staff_color)
    draw.ellipse([40, 24, 48, 32], fill=orb_color)
    
    # Pies
    draw_oval(draw, 26, 58, 8, 6, boot_color)
    draw_oval(draw, 32, 58, 8, 6, boot_color)
    
    image.save("sprites/wizard/wizard_right.png")
    print("✓ wizard_right.png creado")

def main():
    print("=== CREANDO SPRITES DEL MAGO BASADOS EN TUS IMÁGENES ===")
    
    # Crear directorio
    create_sprite_directory()
    
    # Crear cada sprite
    create_wizard_down()    # Tu imagen 1: frente
    create_wizard_left()    # Tu imagen 2: perfil izquierda
    create_wizard_up()      # Tu imagen 3: arriba/frente
    create_wizard_right()   # Tu imagen 4: espaldas
    
    print("\n✅ SPRITES CREADOS EXITOSAMENTE")
    print("📁 Ubicación: project/sprites/wizard/")
    print("📋 Archivos:")
    print("   - wizard_down.png  (imagen 1: frente)")
    print("   - wizard_left.png  (imagen 2: perfil izq)")
    print("   - wizard_up.png    (imagen 3: arriba)")
    print("   - wizard_right.png (imagen 4: espaldas)")
    print("\n🎮 Ahora puedes ejecutar el juego con: .\\run_isaac_test.ps1")

if __name__ == "__main__":
    main()