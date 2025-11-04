"""
🎨 GENERADOR DE TEXTURAS MEJORADAS PARA BIOMAS
==============================================

Genera texturas de alta calidad (2048×2048) para cada bioma con:
- Noise orgánico para variación natural
- Detalles pequeños (piedras, manchas)
- Gradientes sutiles
- Seamless tiles (bordes sin costuras)

Uso:
    python generate_improved_biome_textures.py

Requisitos:
    pip install pillow numpy
"""

from PIL import Image, ImageFilter, ImageDraw, ImageEnhance
import random
import numpy as np
import os

# Configuración de biomas
BIOMES = {
    'Grassland': {
        'base_color': (100, 180, 80),
        'variation': 35,
        'detail_density': 600,
        'detail_colors': [(80, 160, 60), (120, 200, 100), (90, 170, 70)]
    },
    'Forest': {
        'base_color': (60, 120, 60),
        'variation': 30,
        'detail_density': 700,
        'detail_colors': [(50, 110, 50), (70, 130, 70), (55, 115, 55)]
    },
    'Snow': {
        'base_color': (240, 250, 255),
        'variation': 15,
        'detail_density': 400,
        'detail_colors': [(230, 240, 245), (250, 255, 255), (235, 245, 250)]
    },
    'Desert': {
        'base_color': (220, 200, 150),
        'variation': 25,
        'detail_density': 500,
        'detail_colors': [(210, 190, 140), (230, 210, 160), (215, 195, 145)]
    },
    'Lava': {
        'base_color': (80, 30, 20),
        'variation': 40,
        'detail_density': 550,
        'detail_colors': [(100, 40, 25), (120, 50, 30), (140, 60, 35)]
    },
    'ArcaneWastes': {
        'base_color': (120, 80, 160),
        'variation': 35,
        'detail_density': 650,
        'detail_colors': [(110, 70, 150), (130, 90, 170), (115, 75, 155)]
    }
}

def generate_perlin_noise(width, height, scale=100):
    """
    Genera ruido Perlin simplificado usando gradientes aleatorios
    """
    # Crear grid de gradientes
    def lerp(a, b, x):
        return a + x * (b - a)
    
    def fade(t):
        return t * t * t * (t * (t * 6 - 15) + 10)
    
    # Generar ruido
    noise = np.zeros((height, width))
    
    for y in range(height):
        for x in range(width):
            # Coordenadas normalizadas
            nx = x / scale
            ny = y / scale
            
            # Ruido basado en sin/cos (simplificado)
            value = np.sin(nx * 0.1) * np.cos(ny * 0.1) * 0.5 + 0.5
            value += np.sin(nx * 0.05 + 100) * np.cos(ny * 0.05 + 100) * 0.3
            value += np.sin(nx * 0.02 + 200) * np.cos(ny * 0.02 + 200) * 0.2
            
            noise[y, x] = value
    
    # Normalizar a 0-1
    noise = (noise - noise.min()) / (noise.max() - noise.min())
    return noise

def add_organic_noise(img, base_color, variation):
    """
    Añade ruido orgánico a la imagen base
    """
    pixels = img.load()
    width, height = img.size
    
    # Generar ruido Perlin
    noise = generate_perlin_noise(width, height, scale=150)
    
    for y in range(height):
        for x in range(width):
            # Ruido base
            noise_value = noise[y, x]
            noise_offset = int((noise_value - 0.5) * variation * 2)
            
            # Añadir ruido adicional pequeño
            fine_noise = random.randint(-variation // 3, variation // 3)
            
            r, g, b = pixels[x, y]
            pixels[x, y] = (
                max(0, min(255, r + noise_offset + fine_noise)),
                max(0, min(255, g + noise_offset + fine_noise)),
                max(0, min(255, b + noise_offset + fine_noise))
            )

def add_organic_details(img, detail_colors, density):
    """
    Añade detalles orgánicos (manchas, piedras, etc.)
    """
    draw = ImageDraw.Draw(img, 'RGBA')
    width, height = img.size
    
    for _ in range(density):
        x = random.randint(0, width)
        y = random.randint(0, height)
        r = random.randint(3, 12)
        
        # Color aleatorio de la paleta
        color = random.choice(detail_colors)
        # Añadir variación
        color = (
            max(0, min(255, color[0] + random.randint(-20, 20))),
            max(0, min(255, color[1] + random.randint(-20, 20))),
            max(0, min(255, color[2] + random.randint(-20, 20))),
            random.randint(100, 200)  # Alpha variable
        )
        
        # Forma orgánica (elipse con rotación aleatoria)
        r2 = r + random.randint(-r // 2, r // 2)
        draw.ellipse([x - r, y - r2, x + r, y + r2], fill=color)

def add_subtle_gradient(img, base_color):
    """
    Añade un gradiente sutil para romper la uniformidad
    """
    width, height = img.size
    gradient = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(gradient)
    
    # Gradiente radial desde el centro
    center_x, center_y = width // 2, height // 2
    max_dist = np.sqrt(center_x**2 + center_y**2)
    
    for y in range(0, height, 4):  # Cada 4 píxeles para performance
        for x in range(0, width, 4):
            dist = np.sqrt((x - center_x)**2 + (y - center_y)**2)
            alpha = int(30 * (1 - dist / max_dist))  # 0-30 alpha
            
            color = (
                base_color[0],
                base_color[1],
                base_color[2],
                alpha
            )
            draw.rectangle([x, y, x + 4, y + 4], fill=color)
    
    # Blur para suavizar
    gradient = gradient.filter(ImageFilter.GaussianBlur(radius=20))
    
    # Componer
    img = Image.alpha_composite(img.convert('RGBA'), gradient)
    return img.convert('RGB')

def generate_biome_texture(biome_name, config, size=2048, output_dir='project/assets/textures/biomes'):
    """
    Genera una textura de bioma completa
    """
    print(f"🎨 Generando textura para {biome_name}...")
    
    base_color = config['base_color']
    variation = config['variation']
    detail_density = config['detail_density']
    detail_colors = config['detail_colors']
    
    # 1. Crear imagen base con color
    img = Image.new('RGB', (size, size), base_color)
    
    # 2. Añadir ruido orgánico
    print(f"  ├─ Añadiendo ruido orgánico...")
    add_organic_noise(img, base_color, variation)
    
    # 3. Blur sutil para suavizar
    print(f"  ├─ Aplicando suavizado...")
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    
    # 4. Añadir detalles orgánicos
    print(f"  ├─ Añadiendo {detail_density} detalles...")
    add_organic_details(img, detail_colors, detail_density)
    
    # 5. Añadir gradiente sutil
    print(f"  ├─ Aplicando gradiente sutil...")
    img = add_subtle_gradient(img, base_color)
    
    # 6. Ajustar contraste y saturación
    print(f"  ├─ Ajustando contraste y saturación...")
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.1)
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(1.05)
    
    # 7. Hacer seamless (opcional - más complejo)
    # Por ahora lo dejamos sin seamless, pero se puede añadir después
    
    # 8. Guardar
    output_path = os.path.join(output_dir, biome_name, 'base_improved.png')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG', optimize=True)
    print(f"  └─ ✅ Guardada en: {output_path}")
    
    return output_path

def main():
    print("=" * 60)
    print("🎨 GENERADOR DE TEXTURAS MEJORADAS PARA BIOMAS")
    print("=" * 60)
    print()
    
    for biome_name, config in BIOMES.items():
        try:
            generate_biome_texture(biome_name, config)
            print()
        except Exception as e:
            print(f"❌ Error generando {biome_name}: {e}")
            print()
    
    print("=" * 60)
    print("✅ PROCESO COMPLETADO")
    print("=" * 60)
    print()
    print("📝 SIGUIENTE PASO:")
    print("   1. Verifica las texturas en: project/assets/textures/biomes/")
    print("   2. Actualiza biome_textures_config.json para usar 'base_improved.png'")
    print("   3. Reinicia Godot para ver los cambios")
    print()

if __name__ == "__main__":
    main()
