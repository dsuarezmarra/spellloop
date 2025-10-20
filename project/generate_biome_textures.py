#!/usr/bin/env python3
"""
Generador de texturas de biomas para Spellloop
Crea 24 texturas PNG (6 biomas × 4 texturas) con estilo Funko Pop + magia
Todas las texturas son seamless (512×512 px)
"""

import os
import json
import math
import random
from PIL import Image, ImageDraw
import numpy as np
from pathlib import Path

# Configuración de biomas
BIOME_CONFIG = {
    "Grassland": {
        "color_base": "#7ED957",
        "color_base_rgb": (126, 217, 87),
        "decor_colors": [
            (255, 200, 100),  # flores (amarillo-naranja)
            (100, 140, 60),   # arbustos (verde oscuro)
            (140, 120, 100)   # rocas (gris-marrón)
        ],
        "description": "Césped liso con flores, arbustos y rocas"
    },
    "Desert": {
        "color_base": "#E8C27B",
        "color_base_rgb": (232, 194, 123),
        "decor_colors": [
            (139, 115, 85),   # cactus (marrón)
            (160, 140, 120),  # rocas (gris-marrón)
            (220, 190, 140)   # dunas (arena clara)
        ],
        "description": "Arena con cactus, rocas y dunas"
    },
    "Snow": {
        "color_base": "#EAF6FF",
        "color_base_rgb": (234, 246, 255),
        "decor_colors": [
            (150, 200, 255),  # cristales (azul hielo)
            (200, 220, 255),  # montículos (blanco-azul)
            (100, 150, 200)   # carámbanos (azul oscuro)
        ],
        "description": "Nieve blanca con cristales, montículos y carámbanos"
    },
    "Lava": {
        "color_base": "#F55A33",
        "color_base_rgb": (245, 90, 51),
        "decor_colors": [
            (255, 150, 0),    # lava hirviendo (naranja)
            (50, 50, 50),     # rocas (gris oscuro)
            (255, 200, 100)   # vapor (naranja claro - con alpha)
        ],
        "description": "Lava con grietas, rocas volcánicas y vapor"
    },
    "ArcaneWastes": {
        "color_base": "#B56DDC",
        "color_base_rgb": (181, 109, 220),
        "decor_colors": [
            (200, 150, 255),  # runas flotantes (púrpura claro)
            (150, 100, 200),  # cristales (púrpura oscuro)
            (200, 100, 255)   # energía (púrpura-magenta - con alpha)
        ],
        "description": "Suelo violeta con runas, cristales y energía"
    },
    "Forest": {
        "color_base": "#306030",
        "color_base_rgb": (48, 96, 48),
        "decor_colors": [
            (100, 150, 80),   # plantas (verde medio)
            (80, 60, 40),     # troncos (marrón)
            (150, 120, 80)    # hongos (marrón claro)
        ],
        "description": "Hojas oscuras con plantas, troncos y hongos"
    }
}

# Rutas
BIOME_DIR = Path("assets/textures/biomes")
TEXTURE_SIZE = 512
TILE_SIZE = 512

def ensure_seamless(img):
    """
    Convierte una imagen en seamless usando edge wrapping.
    Mezcla los bordes opuestos para eliminar costuras.
    """
    arr = np.array(img, dtype=np.float32)
    h, w = arr.shape[:2]
    
    # Crear versión seamless
    seamless = arr.copy()
    blend_distance = 32
    
    # Mezclar bordes horizontales
    for y in range(h):
        alpha = 1.0 - (min(y, h - 1 - y) / blend_distance) if min(y, h - 1 - y) < blend_distance else 1.0
        seamless[y] = seamless[y] * (1 - alpha * 0.5) + seamless[(h - 1 - y) % h] * (alpha * 0.5)
    
    # Mezclar bordes verticales
    for x in range(w):
        alpha = 1.0 - (min(x, w - 1 - x) / blend_distance) if min(x, w - 1 - x) < blend_distance else 1.0
        seamless[:, x] = seamless[:, x] * (1 - alpha * 0.5) + seamless[:, (w - 1 - x) % w] * (alpha * 0.5)
    
    return Image.fromarray(np.clip(seamless, 0, 255).astype(np.uint8))

def generate_noise_pattern(size, scale=50, seed=None):
    """Genera un patrón de ruido Perlin-like para texturas procedurales."""
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)
    
    # Generar grid de valores aleatorios
    grid_size = size // scale
    grid = np.random.rand(grid_size + 2, grid_size + 2) * 255
    
    # Interpolar para obtener imagen suave
    from scipy.interpolate import RegularGridInterpolator
    
    x = np.linspace(0, grid_size, size)
    y = np.linspace(0, grid_size, size)
    
    pattern = np.zeros((size, size))
    for i in range(size):
        for j in range(size):
            xi, yi = x[i], y[j]
            gx, gy = int(xi) % grid_size, int(yi) % grid_size
            fx, fy = xi - int(xi), yi - int(yi)
            
            # Interpolación bilineal
            v00 = grid[gy, gx]
            v10 = grid[gy, (gx + 1) % grid_size]
            v01 = grid[(gy + 1) % grid_size, gx]
            v11 = grid[(gy + 1) % grid_size, (gx + 1) % grid_size]
            
            v0 = v00 * (1 - fx) + v10 * fx
            v1 = v01 * (1 - fx) + v11 * fx
            pattern[i, j] = v0 * (1 - fy) + v1 * fy
    
    return pattern / 255.0

def create_grassland_base():
    """Crea textura base de Grassland (césped)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), BIOME_CONFIG["Grassland"]["color_base_rgb"] + (255,))
    draw = ImageDraw.Draw(img, "RGBA")
    pixels = img.load()
    
    # Agregar variaciones de color (pastos)
    noise = generate_noise_pattern(TEXTURE_SIZE, scale=40, seed=42)
    for x in range(TEXTURE_SIZE):
        for y in range(TEXTURE_SIZE):
            variation = int(noise[y, x] * 40)
            r = max(80, min(180, BIOME_CONFIG["Grassland"]["color_base_rgb"][0] + variation))
            g = max(150, min(255, BIOME_CONFIG["Grassland"]["color_base_rgb"][1] + variation))
            b = max(50, min(150, BIOME_CONFIG["Grassland"]["color_base_rgb"][2] + variation))
            pixels[x, y] = (r, g, b, 255)
    
    return ensure_seamless(img)

def create_grassland_decor1():
    """Flores para Grassland."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(101)
    for i in range(15):
        x = random.randint(10, TEXTURE_SIZE - 10)
        y = random.randint(10, TEXTURE_SIZE - 10)
        # Flores simples (círculos + tallo)
        draw.ellipse([x - 5, y - 8, x + 5, y], fill=(255, 200, 100, 200))  # flor
        draw.line([x, y, x, y + 10], fill=(100, 140, 60, 150), width=2)  # tallo
    
    return ensure_seamless(img)

def create_grassland_decor2():
    """Arbustos para Grassland."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(102)
    for i in range(8):
        x = random.randint(20, TEXTURE_SIZE - 20)
        y = random.randint(20, TEXTURE_SIZE - 20)
        # Arbustos (esferas)
        draw.ellipse([x - 15, y - 15, x + 15, y + 15], fill=(100, 140, 60, 220))
    
    return ensure_seamless(img)

def create_grassland_decor3():
    """Rocas para Grassland."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(103)
    for i in range(10):
        x = random.randint(30, TEXTURE_SIZE - 30)
        y = random.randint(30, TEXTURE_SIZE - 30)
        size = random.randint(15, 30)
        # Rocas (polígonos irregulares)
        draw.ellipse([x - size, y - size, x + size, y + size], fill=(140, 120, 100, 200))
    
    return ensure_seamless(img)

def create_desert_base():
    """Crea textura base de Desert (arena)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), BIOME_CONFIG["Desert"]["color_base_rgb"] + (255,))
    pixels = img.load()
    
    # Arena con textura de duna
    noise = generate_noise_pattern(TEXTURE_SIZE, scale=60, seed=201)
    for x in range(TEXTURE_SIZE):
        for y in range(TEXTURE_SIZE):
            variation = int(noise[y, x] * 35)
            r = max(180, min(255, BIOME_CONFIG["Desert"]["color_base_rgb"][0] + variation))
            g = max(150, min(230, BIOME_CONFIG["Desert"]["color_base_rgb"][1] + variation))
            b = max(80, min(180, BIOME_CONFIG["Desert"]["color_base_rgb"][2] + variation))
            pixels[x, y] = (r, g, b, 255)
    
    return ensure_seamless(img)

def create_desert_decor1():
    """Cactus para Desert."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(211)
    for i in range(6):
        x = random.randint(50, TEXTURE_SIZE - 50)
        y = random.randint(50, TEXTURE_SIZE - 50)
        # Cactus simple (rectángulo + círculos)
        draw.rectangle([x - 8, y - 30, x + 8, y + 20], fill=(139, 115, 85, 220))
        draw.ellipse([x - 12, y, x + 4, y + 16], fill=(139, 115, 85, 220))
    
    return ensure_seamless(img)

def create_desert_decor2():
    """Rocas para Desert."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(212)
    for i in range(12):
        x = random.randint(30, TEXTURE_SIZE - 30)
        y = random.randint(30, TEXTURE_SIZE - 30)
        size = random.randint(10, 25)
        draw.ellipse([x - size, y - size, x + size, y + size], fill=(160, 140, 120, 200))
    
    return ensure_seamless(img)

def create_desert_decor3():
    """Dunas para Desert."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(213)
    for i in range(5):
        x = random.randint(80, TEXTURE_SIZE - 80)
        y = random.randint(80, TEXTURE_SIZE - 80)
        # Dunas (triángulos/trapezoides)
        draw.polygon([(x - 40, y + 20), (x + 40, y + 20), (x, y - 30)], fill=(220, 190, 140, 180))
    
    return ensure_seamless(img)

def create_snow_base():
    """Crea textura base de Snow (nieve)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), BIOME_CONFIG["Snow"]["color_base_rgb"] + (255,))
    pixels = img.load()
    
    # Nieve con textura granulada
    noise = generate_noise_pattern(TEXTURE_SIZE, scale=50, seed=301)
    for x in range(TEXTURE_SIZE):
        for y in range(TEXTURE_SIZE):
            variation = int(noise[y, x] * 30)
            r = max(200, min(255, BIOME_CONFIG["Snow"]["color_base_rgb"][0] + variation))
            g = max(220, min(255, BIOME_CONFIG["Snow"]["color_base_rgb"][1] + variation))
            b = max(240, min(255, BIOME_CONFIG["Snow"]["color_base_rgb"][2] + variation))
            pixels[x, y] = (r, g, b, 255)
    
    return ensure_seamless(img)

def create_snow_decor1():
    """Cristales para Snow."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(311)
    for i in range(20):
        x = random.randint(20, TEXTURE_SIZE - 20)
        y = random.randint(20, TEXTURE_SIZE - 20)
        size = random.randint(5, 15)
        # Cristales (estrellas)
        draw.ellipse([x - size, y - size, x + size, y + size], fill=(150, 200, 255, 200))
    
    return ensure_seamless(img)

def create_snow_decor2():
    """Montículos para Snow."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(312)
    for i in range(8):
        x = random.randint(40, TEXTURE_SIZE - 40)
        y = random.randint(40, TEXTURE_SIZE - 40)
        draw.ellipse([x - 25, y - 20, x + 25, y + 30], fill=(200, 220, 255, 210))
    
    return ensure_seamless(img)

def create_snow_decor3():
    """Carámbanos para Snow."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(313)
    for i in range(10):
        x = random.randint(40, TEXTURE_SIZE - 40)
        y = random.randint(40, TEXTURE_SIZE - 40)
        # Carámbanos (triángulos)
        draw.polygon([(x - 5, y - 20), (x + 5, y - 20), (x, y + 15)], fill=(100, 150, 200, 220))
    
    return ensure_seamless(img)

def create_lava_base():
    """Crea textura base de Lava (grietas)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), BIOME_CONFIG["Lava"]["color_base_rgb"] + (255,))
    pixels = img.load()
    
    # Lava con grietas
    noise = generate_noise_pattern(TEXTURE_SIZE, scale=40, seed=401)
    for x in range(TEXTURE_SIZE):
        for y in range(TEXTURE_SIZE):
            variation = int(noise[y, x] * 45)
            r = max(200, min(255, BIOME_CONFIG["Lava"]["color_base_rgb"][0] + variation))
            g = max(50, min(150, BIOME_CONFIG["Lava"]["color_base_rgb"][1] + variation))
            b = max(20, min(80, BIOME_CONFIG["Lava"]["color_base_rgb"][2] + variation))
            pixels[x, y] = (r, g, b, 255)
    
    # Grietas oscuras
    for i in range(TEXTURE_SIZE):
        line_y = int((noise[i, :].mean() * TEXTURE_SIZE))
        if 0 <= line_y < TEXTURE_SIZE:
            pixels[i, line_y] = (30, 20, 10, 255)
    
    return ensure_seamless(img)

def create_lava_decor1():
    """Lava hirviendo para Lava."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(411)
    for i in range(12):
        x = random.randint(30, TEXTURE_SIZE - 30)
        y = random.randint(30, TEXTURE_SIZE - 30)
        size = random.randint(10, 25)
        draw.ellipse([x - size, y - size, x + size, y + size], fill=(255, 150, 0, 200))
    
    return ensure_seamless(img)

def create_lava_decor2():
    """Rocas volcánicas para Lava."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(412)
    for i in range(10):
        x = random.randint(40, TEXTURE_SIZE - 40)
        y = random.randint(40, TEXTURE_SIZE - 40)
        size = random.randint(15, 30)
        draw.ellipse([x - size, y - size, x + size, y + size], fill=(50, 50, 50, 220))
    
    return ensure_seamless(img)

def create_lava_decor3():
    """Vapor para Lava (con alpha)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(413)
    for i in range(8):
        x = random.randint(40, TEXTURE_SIZE - 40)
        y = random.randint(40, TEXTURE_SIZE - 40)
        # Vapor semitransparente
        draw.ellipse([x - 30, y - 30, x + 30, y + 30], fill=(255, 200, 100, 100))
    
    return ensure_seamless(img)

def create_arcanewastes_base():
    """Crea textura base de ArcaneWastes (suelo violeta + runas)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), BIOME_CONFIG["ArcaneWastes"]["color_base_rgb"] + (255,))
    pixels = img.load()
    
    # Suelo violeta con runas ligeras
    noise = generate_noise_pattern(TEXTURE_SIZE, scale=50, seed=501)
    for x in range(TEXTURE_SIZE):
        for y in range(TEXTURE_SIZE):
            variation = int(noise[y, x] * 40)
            r = max(150, min(220, BIOME_CONFIG["ArcaneWastes"]["color_base_rgb"][0] + variation))
            g = max(80, min(160, BIOME_CONFIG["ArcaneWastes"]["color_base_rgb"][1] + variation))
            b = max(180, min(255, BIOME_CONFIG["ArcaneWastes"]["color_base_rgb"][2] + variation))
            pixels[x, y] = (r, g, b, 255)
    
    return ensure_seamless(img)

def create_arcanewastes_decor1():
    """Runas flotantes para ArcaneWastes."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(511)
    for i in range(10):
        x = random.randint(40, TEXTURE_SIZE - 40)
        y = random.randint(40, TEXTURE_SIZE - 40)
        # Runas (símbolos simples)
        draw.ellipse([x - 12, y - 12, x + 12, y + 12], outline=(200, 150, 255, 200), width=2)
        draw.line([x - 8, y, x + 8, y], fill=(200, 150, 255, 200), width=1)
    
    return ensure_seamless(img)

def create_arcanewastes_decor2():
    """Cristales para ArcaneWastes."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(512)
    for i in range(12):
        x = random.randint(30, TEXTURE_SIZE - 30)
        y = random.randint(30, TEXTURE_SIZE - 30)
        size = random.randint(8, 18)
        draw.ellipse([x - size, y - size, x + size, y + size], fill=(150, 100, 200, 220))
    
    return ensure_seamless(img)

def create_arcanewastes_decor3():
    """Energía pulsante para ArcaneWastes (con alpha)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(513)
    for i in range(6):
        x = random.randint(60, TEXTURE_SIZE - 60)
        y = random.randint(60, TEXTURE_SIZE - 60)
        # Energía semitransparente
        draw.ellipse([x - 35, y - 35, x + 35, y + 35], fill=(200, 100, 255, 120))
    
    return ensure_seamless(img)

def create_forest_base():
    """Crea textura base de Forest (hojas oscuras)."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), BIOME_CONFIG["Forest"]["color_base_rgb"] + (255,))
    pixels = img.load()
    
    # Hojas oscuras con variación
    noise = generate_noise_pattern(TEXTURE_SIZE, scale=45, seed=601)
    for x in range(TEXTURE_SIZE):
        for y in range(TEXTURE_SIZE):
            variation = int(noise[y, x] * 50)
            r = max(30, min(80, BIOME_CONFIG["Forest"]["color_base_rgb"][0] + variation))
            g = max(60, min(140, BIOME_CONFIG["Forest"]["color_base_rgb"][1] + variation))
            b = max(30, min(80, BIOME_CONFIG["Forest"]["color_base_rgb"][2] + variation))
            pixels[x, y] = (r, g, b, 255)
    
    return ensure_seamless(img)

def create_forest_decor1():
    """Plantas para Forest."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(611)
    for i in range(15):
        x = random.randint(20, TEXTURE_SIZE - 20)
        y = random.randint(20, TEXTURE_SIZE - 20)
        # Plantas (formas orgánicas)
        draw.ellipse([x - 8, y - 12, x + 8, y + 8], fill=(100, 150, 80, 210))
    
    return ensure_seamless(img)

def create_forest_decor2():
    """Troncos para Forest."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(612)
    for i in range(6):
        x = random.randint(50, TEXTURE_SIZE - 50)
        y = random.randint(50, TEXTURE_SIZE - 50)
        # Troncos (rectángulos)
        draw.rectangle([x - 15, y - 40, x + 15, y + 40], fill=(80, 60, 40, 220))
    
    return ensure_seamless(img)

def create_forest_decor3():
    """Hongos para Forest."""
    img = Image.new("RGBA", (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    random.seed(613)
    for i in range(10):
        x = random.randint(30, TEXTURE_SIZE - 30)
        y = random.randint(30, TEXTURE_SIZE - 30)
        # Hongos (círculo + rectángulo)
        draw.ellipse([x - 12, y - 15, x + 12, y - 5], fill=(150, 120, 80, 220))  # sombrero
        draw.rectangle([x - 4, y - 5, x + 4, y + 10], fill=(150, 120, 80, 220))   # tallo
    
    return ensure_seamless(img)

# Mapeo de funciones de generación
TEXTURE_GENERATORS = {
    "Grassland": {
        "base": create_grassland_base,
        "decor1": create_grassland_decor1,
        "decor2": create_grassland_decor2,
        "decor3": create_grassland_decor3,
    },
    "Desert": {
        "base": create_desert_base,
        "decor1": create_desert_decor1,
        "decor2": create_desert_decor2,
        "decor3": create_desert_decor3,
    },
    "Snow": {
        "base": create_snow_base,
        "decor1": create_snow_decor1,
        "decor2": create_snow_decor2,
        "decor3": create_snow_decor3,
    },
    "Lava": {
        "base": create_lava_base,
        "decor1": create_lava_decor1,
        "decor2": create_lava_decor2,
        "decor3": create_lava_decor3,
    },
    "ArcaneWastes": {
        "base": create_arcanewastes_base,
        "decor1": create_arcanewastes_decor1,
        "decor2": create_arcanewastes_decor2,
        "decor3": create_arcanewastes_decor3,
    },
    "Forest": {
        "base": create_forest_base,
        "decor1": create_forest_decor1,
        "decor2": create_forest_decor2,
        "decor3": create_forest_decor3,
    },
}

def main():
    """Genera todas las texturas y el JSON de configuración."""
    
    print("🎨 Generador de Texturas de Biomas - Spellloop")
    print("=" * 60)
    
    # Asegurar que el directorio existe
    BIOME_DIR.mkdir(parents=True, exist_ok=True)
    
    # Generar texturas para cada bioma
    for biome_name, generators in TEXTURE_GENERATORS.items():
        print(f"\n📦 Generando texturas para {biome_name}...")
        
        biome_path = BIOME_DIR / biome_name
        biome_path.mkdir(exist_ok=True)
        
        # Generar base y decoraciones
        textures = {}
        for texture_type, generator_func in generators.items():
            print(f"  • Generando {texture_type}.png...", end=" ")
            texture = generator_func()
            texture_path = biome_path / f"{texture_type}.png"
            texture.save(texture_path, "PNG")
            textures[texture_type] = str(texture_path)
            print("✅")
    
    # Generar JSON de configuración
    print("\n📝 Generando biome_textures_config.json...", end=" ")
    
    config = {
        "metadata": {
            "version": "1.0",
            "author": "Spellloop Biome System",
            "created": "2025-10-20",
            "description": "Configuration for procedurally generated biome textures"
        },
        "biomes": []
    }
    
    for biome_name in BIOME_CONFIG.keys():
        biome_entry = {
            "id": biome_name.lower(),
            "name": biome_name,
            "color_base": BIOME_CONFIG[biome_name]["color_base"],
            "description": BIOME_CONFIG[biome_name]["description"],
            "textures": {
                "base": f"{biome_name}/base.png",
                "decor": [
                    f"{biome_name}/decor1.png",
                    f"{biome_name}/decor2.png",
                    f"{biome_name}/decor3.png"
                ]
            },
            "tile_size": [TILE_SIZE, TILE_SIZE],
            "decorations": [
                {"type": "decor1", "scale": 1.0, "opacity": 0.8, "offset": [0, 0]},
                {"type": "decor2", "scale": 1.0, "opacity": 0.75, "offset": [256, 128]},
                {"type": "decor3", "scale": 1.0, "opacity": 0.6, "offset": [128, 256]}
            ]
        }
        config["biomes"].append(biome_entry)
    
    config_path = BIOME_DIR / "biome_textures_config.json"
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
    
    print("✅")
    
    # Resumen
    print("\n" + "=" * 60)
    print("✨ ¡Texturas generadas exitosamente!")
    print("=" * 60)
    print(f"\n📂 Ubicación: {BIOME_DIR.resolve()}")
    print(f"\n📊 Estadísticas:")
    print(f"   • Biomas: {len(BIOME_CONFIG)}")
    print(f"   • Texturas por bioma: 4 (base + 3 decoraciones)")
    print(f"   • Total PNG: {len(BIOME_CONFIG) * 4} (24 texturas)")
    print(f"   • Resolución: {TEXTURE_SIZE}×{TEXTURE_SIZE} px")
    print(f"   • Tipo: Seamless (sin costuras visibles)")
    print(f"\n📋 Archivos creados:")
    
    # Listar biomas
    for biome_name in BIOME_CONFIG.keys():
        biome_path = BIOME_DIR / biome_name
        if biome_path.exists():
            png_count = len(list(biome_path.glob("*.png")))
            print(f"   ✓ {biome_name}: {png_count} PNG")
    
    print(f"   ✓ biome_textures_config.json")
    print("\n🚀 Próximos pasos:")
    print("   1. Abre el proyecto en Godot")
    print("   2. Importa las texturas con configuración VRAM Compressed")
    print("   3. Conecta BiomeChunkApplier a InfiniteWorldManager")
    print("   4. ¡Prueba los biomas en el juego!")
    
if __name__ == "__main__":
    main()
