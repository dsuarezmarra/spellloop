#!/usr/bin/env python3
"""
Script para generar texturas de biomas PNG válidas y correctamente formateadas.
Reemplaza los archivos corruptos con versiones nuevas y válidas.
"""

import os
from PIL import Image, ImageDraw
import json

# Definición de biomas con colores y patrones
BIOMES = {
    "Grassland": {
        "color_base": (126, 217, 87),  # Verde
        "pattern_colors": [(100, 180, 60), (80, 160, 50)],
    },
    "Desert": {
        "color_base": (232, 194, 123),  # Naranja/Arena
        "pattern_colors": [(200, 160, 90), (220, 180, 110)],
    },
    "Snow": {
        "color_base": (234, 246, 255),  # Azul claro/Blanco
        "pattern_colors": [(200, 230, 250), (220, 240, 255)],
    },
    "Lava": {
        "color_base": (245, 90, 51),  # Rojo/Naranja
        "pattern_colors": [(255, 120, 80), (220, 60, 30)],
    },
    "ArcaneWastes": {
        "color_base": (181, 109, 220),  # Púrpura
        "pattern_colors": [(160, 80, 200), (200, 130, 240)],
    },
    "Forest": {
        "color_base": (48, 96, 48),  # Verde oscuro
        "pattern_colors": [(40, 80, 40), (60, 110, 60)],
    },
}

def create_gradient_pattern(size, color1, color2):
    """Crear patrón degradado simple para usar como base."""
    img = Image.new("RGB", size, color1)
    draw = ImageDraw.Draw(img, "RGBA")
    
    # Crear patrón de gradiente vertical
    for y in range(0, size[1], 20):
        alpha = int((y / size[1]) * 100)
        draw.rectangle([(0, y), (size[0], y + 20)], fill=(*color2, alpha // 2))
    
    return img

def create_textured_biome(biome_name, size=(1920, 1080)):
    """Crear textura con patrón para un bioma específico."""
    biome_info = BIOMES[biome_name]
    base_color = biome_info["color_base"]
    pattern_colors = biome_info["pattern_colors"]
    
    # Crear imagen base
    img = Image.new("RGB", size, base_color)
    draw = ImageDraw.Draw(img)
    
    # Agregar patrón
    import random
    random.seed(hash(biome_name))  # Determinístico
    
    for _ in range(100):  # 100 formas aleatorias
        x = random.randint(0, size[0])
        y = random.randint(0, size[1])
        w = random.randint(50, 200)
        h = random.randint(50, 200)
        color = random.choice(pattern_colors)
        alpha = random.randint(30, 80)
        
        # Dibujar rectángulo con transparencia
        draw.rectangle([(x, y), (x + w, y + h)], fill=color, width=2)
    
    return img

def create_decoration(size=(256, 256), color_base=(200, 200, 200)):
    """Crear una decoración simple (pequeño patrón)."""
    img = Image.new("RGBA", size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Círculo simple como decoración
    draw.ellipse([(50, 50), (200, 200)], fill=color_base + (200,), outline=color_base)
    
    return img

def main():
    project_path = r"c:\Users\dsuarez1\git\spellloop\project"
    biomes_path = os.path.join(project_path, "assets", "textures", "biomes")
    
    print("🎨 Generando texturas de biomas PNG válidas...")
    print(f"   Directorio: {biomes_path}\n")
    
    for biome_name, biome_info in BIOMES.items():
        biome_dir = os.path.join(biomes_path, biome_name)
        os.makedirs(biome_dir, exist_ok=True)
        
        # Generar textura base (1920x1080)
        base_img = create_textured_biome(biome_name, size=(1920, 1080))
        base_path = os.path.join(biome_dir, "base.png")
        base_img.save(base_path, "PNG")
        print(f"✓ {biome_name}/base.png ({base_img.size})")
        
        # Generar 3 decoraciones (256x256)
        for i in range(1, 4):
            decor_img = create_decoration(size=(256, 256), color_base=biome_info["pattern_colors"][0])
            decor_path = os.path.join(biome_dir, f"decor{i}.png")
            decor_img.save(decor_path, "PNG")
            print(f"  ✓ decor{i}.png")
        
        print()
    
    print("✅ Todas las texturas generadas correctamente como PNG válidos")

if __name__ == "__main__":
    main()
