#!/usr/bin/env python3
"""
Generador de sprites de proyectiles para Spellloop
Crea 120 frames PNG (30 por proyectil × 4 proyectiles) con estilo Funko Pop
"""

from PIL import Image, ImageDraw
import math
import os

# Configuración de proyectiles
PROJECTILES = {
    'arcane_bolt': {
        'element': 'arcane',
        'color_primary': '#9B59B6',  # Violeta
        'color_accent': '#D7BDE2',
        'color_dark': '#7D3C98',
    },
    'dark_missile': {
        'element': 'dark',
        'color_primary': '#2C3E50',  # Azul-negro
        'color_accent': '#566573',
        'color_dark': '#1B2631',
    },
    'fireball': {
        'element': 'fire',
        'color_primary': '#E74C3C',  # Rojo-naranja
        'color_accent': '#F8B88B',
        'color_dark': '#C0392B',
    },
    'ice_shard': {
        'element': 'ice',
        'color_primary': '#5DADE2',  # Azul claro
        'color_accent': '#AED6F1',
        'color_dark': '#2874A6',
    },
}

SIZE = 64
CENTER = SIZE // 2
OUTLINE = 3
BLACK = '#000000'

def hex_to_rgb(hex_color):
    """Convertir hex a RGB"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def draw_with_outline(draw, shape_func, color, outline_color=BLACK, outline_width=OUTLINE):
    """Dibujar forma con contorno negro"""
    # Dibujar contorno
    for adj_x in range(-outline_width, outline_width + 1):
        for adj_y in range(-outline_width, outline_width + 1):
            if adj_x != 0 or adj_y != 0:
                shape_func(draw, outline_color, adj_x, adj_y)
    # Dibujar forma principal
    shape_func(draw, color, 0, 0)

def generate_launch_arcane(frame):
    """Animación Launch - Chispa violeta con rayo radial"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Progresión: 0-9 frames
    progress = frame / 9.0
    
    # Rayos radiantes que se expanden
    num_rays = 8
    for i in range(num_rays):
        angle = (i / num_rays) * 2 * math.pi + (progress * math.pi / 2)
        inner_r = 8 * progress
        outer_r = 12 * progress + 8
        
        x1 = CENTER + inner_r * math.cos(angle)
        y1 = CENTER + inner_r * math.sin(angle)
        x2 = CENTER + outer_r * math.cos(angle)
        y2 = CENTER + outer_r * math.sin(angle)
        
        draw.line([(x1, y1), (x2, y2)], 
                 fill=hex_to_rgb('#9B59B6'), 
                 width=2)
    
    # Núcleo central creciente
    core_radius = 4 + progress * 4
    draw.ellipse(
        [CENTER - core_radius, CENTER - core_radius, 
         CENTER + core_radius, CENTER + core_radius],
        fill=hex_to_rgb('#D7BDE2'),
        outline=BLACK
    )
    
    return img

def generate_inflight_arcane(frame):
    """Animación InFlight - Rastro energético violeta"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = (frame % 10) / 10.0
    
    # Bola principal de energía
    r = 8
    draw.ellipse(
        [CENTER - r, CENTER - r, CENTER + r, CENTER + r],
        fill=hex_to_rgb('#9B59B6'),
        outline=BLACK
    )
    
    # Estela de 3 círculos traseros
    for i in range(1, 4):
        offset = (i / 3.0) * 10
        alpha = int(255 * (1 - i/3.0))
        trail_r = r - i
        
        trail_img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
        trail_draw = ImageDraw.Draw(trail_img)
        trail_draw.ellipse(
            [CENTER - trail_r - offset, CENTER - trail_r,
             CENTER + trail_r - offset, CENTER + trail_r],
            fill=hex_to_rgb('#D7BDE2')
        )
        
        # Blend con alpha
        img.alpha_composite(trail_img, (0, 0))
    
    return img

def generate_impact_arcane(frame):
    """Animación Impact - Explosión motas violeta"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Explosión radial
    num_particles = 12
    for i in range(num_particles):
        angle = (i / num_particles) * 2 * math.pi
        distance = progress * 20
        
        x = CENTER + distance * math.cos(angle)
        y = CENTER + distance * math.sin(angle)
        
        particle_size = 3 - progress * 2
        if particle_size > 0:
            draw.ellipse(
                [x - particle_size, y - particle_size,
                 x + particle_size, y + particle_size],
                fill=hex_to_rgb('#9B59B6')
            )
    
    # Centro brillante
    center_r = 6 * (1 - progress)
    if center_r > 0:
        draw.ellipse(
            [CENTER - center_r, CENTER - center_r,
             CENTER + center_r, CENTER + center_r],
            fill=hex_to_rgb('#D7BDE2'),
            outline=BLACK
        )
    
    return img

def generate_launch_dark(frame):
    """Animación Launch - Aura oscura creciente"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Anillos de aura oscura
    for ring in range(3):
        ring_r = 4 + (ring * 4) + progress * 6
        ring_width = 2
        draw.ellipse(
            [CENTER - ring_r, CENTER - ring_r,
             CENTER + ring_r, CENTER + ring_r],
            outline=hex_to_rgb('#566573'),
            width=ring_width
        )
    
    # Núcleo oscuro
    core_r = 6 + progress * 2
    draw.ellipse(
        [CENTER - core_r, CENTER - core_r,
         CENTER + core_r, CENTER + core_r],
        fill=hex_to_rgb('#2C3E50'),
        outline=BLACK
    )
    
    return img

def generate_inflight_dark(frame):
    """Animación InFlight - Misil oscuro con estela"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Cuerpo del misil
    draw.ellipse(
        [CENTER - 7, CENTER - 5, CENTER + 7, CENTER + 5],
        fill=hex_to_rgb('#2C3E50'),
        outline=BLACK
    )
    
    # Punta afilada
    points = [CENTER + 8, CENTER, CENTER + 7, CENTER - 4, CENTER + 7, CENTER + 4]
    draw.polygon(points, fill=hex_to_rgb('#1B2631'), outline=BLACK)
    
    # Estela azul oscura
    for i in range(1, 4):
        trail_offset = i * 3
        trail_alpha = 60 - i * 15
        draw.ellipse(
            [CENTER - 4 - trail_offset, CENTER - 3,
             CENTER - trail_offset + 4, CENTER + 3],
            fill=hex_to_rgb('#566573')
        )
    
    return img

def generate_impact_dark(frame):
    """Animación Impact - Explosión de motas azul-gris"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Partículas volando
    num_particles = 16
    for i in range(num_particles):
        angle = (i / num_particles) * 2 * math.pi
        distance = progress * 22
        
        x = CENTER + distance * math.cos(angle)
        y = CENTER + distance * math.sin(angle)
        
        particle_size = 2 - progress * 1.5
        if particle_size > 0:
            draw.ellipse(
                [x - particle_size, y - particle_size,
                 x + particle_size, y + particle_size],
                fill=hex_to_rgb('#566573')
            )
    
    return img

def generate_launch_fire(frame):
    """Animación Launch - Bola de fuego creciente"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Capas de fuego expandiéndose
    for layer in range(3):
        layer_r = 4 + progress * 8 + layer * 2
        layer_color = ['#F8B88B', '#E74C3C', '#C0392B'][layer]
        
        draw.ellipse(
            [CENTER - layer_r, CENTER - layer_r,
             CENTER + layer_r, CENTER + layer_r],
            fill=hex_to_rgb(layer_color)
        )
    
    # Contorno negro
    final_r = 4 + progress * 10
    draw.ellipse(
        [CENTER - final_r, CENTER - final_r,
         CENTER + final_r, CENTER + final_r],
        outline=BLACK,
        width=OUTLINE
    )
    
    return img

def generate_inflight_fire(frame):
    """Animación InFlight - Fuego volador con estela naranja"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = (frame % 10) / 10.0
    
    # Bola de fuego principal
    r = 9
    draw.ellipse(
        [CENTER - r, CENTER - r, CENTER + r, CENTER + r],
        fill=hex_to_rgb('#E74C3C'),
        outline=BLACK
    )
    
    # Interno más claro
    inner_r = 6
    draw.ellipse(
        [CENTER - inner_r, CENTER - inner_r,
         CENTER + inner_r, CENTER + inner_r],
        fill=hex_to_rgb('#F8B88B')
    )
    
    # Estela de humo
    for i in range(1, 4):
        trail_offset = i * 4
        draw.ellipse(
            [CENTER - 5 - trail_offset, CENTER - 5,
             CENTER + 5 - trail_offset, CENTER + 5],
            fill=hex_to_rgb('#F8B88B')
        )
    
    return img

def generate_impact_fire(frame):
    """Animación Impact - Explosión chispas fuego"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Chispas radiantes
    num_sparks = 20
    for i in range(num_sparks):
        angle = (i / num_sparks) * 2 * math.pi
        distance = progress * 24
        
        x = CENTER + distance * math.cos(angle)
        y = CENTER + distance * math.sin(angle)
        
        spark_size = 3 - progress * 2
        if spark_size > 0:
            color = ['#E74C3C', '#F8B88B', '#C0392B'][i % 3]
            draw.ellipse(
                [x - spark_size, y - spark_size,
                 x + spark_size, y + spark_size],
                fill=hex_to_rgb(color)
            )
    
    return img

def generate_launch_ice(frame):
    """Animación Launch - Fragmento hielo formándose"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Cristal de hielo principal
    size = 4 + progress * 6
    points = [
        CENTER, CENTER - size,  # Top
        CENTER + size, CENTER - size/2,  # Top-Right
        CENTER + size, CENTER + size/2,  # Bottom-Right
        CENTER, CENTER + size,  # Bottom
        CENTER - size, CENTER + size/2,  # Bottom-Left
        CENTER - size, CENTER - size/2,  # Top-Left
    ]
    draw.polygon(points, fill=hex_to_rgb('#5DADE2'), outline=BLACK)
    
    # Brillo interno
    inner_size = size * 0.5
    draw.polygon([
        CENTER, CENTER - inner_size,
        CENTER + inner_size, CENTER,
        CENTER, CENTER + inner_size,
        CENTER - inner_size, CENTER,
    ], fill=hex_to_rgb('#AED6F1'))
    
    return img

def generate_inflight_ice(frame):
    """Animación InFlight - Cristal de hielo con estela de bruma"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Cristal principal (forma de rombo)
    size = 7
    points = [
        CENTER, CENTER - size,
        CENTER + size, CENTER,
        CENTER, CENTER + size,
        CENTER - size, CENTER,
    ]
    draw.polygon(points, fill=hex_to_rgb('#5DADE2'), outline=BLACK)
    
    # Brillo
    inner_points = [
        CENTER, CENTER - 4,
        CENTER + 4, CENTER,
        CENTER, CENTER + 4,
        CENTER - 4, CENTER,
    ]
    draw.polygon(inner_points, fill=hex_to_rgb('#AED6F1'))
    
    # Estela de bruma
    for i in range(1, 3):
        trail_r = 3 + i
        draw.ellipse(
            [CENTER - trail_r - i*3, CENTER - trail_r,
             CENTER + trail_r - i*3, CENTER + trail_r],
            fill=hex_to_rgb('#AED6F1')
        )
    
    return img

def generate_impact_ice(frame):
    """Animación Impact - Explosión cristales hielo"""
    img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    progress = frame / 9.0
    
    # Cristales volando
    num_crystals = 12
    for i in range(num_crystals):
        angle = (i / num_crystals) * 2 * math.pi
        distance = progress * 20
        
        x = CENTER + distance * math.cos(angle)
        y = CENTER + distance * math.sin(angle)
        
        cryst_size = 3 - progress * 2
        if cryst_size > 0:
            # Mini rombo
            points = [
                x, y - cryst_size,
                x + cryst_size, y,
                x, y + cryst_size,
                x - cryst_size, y,
            ]
            draw.polygon(points, fill=hex_to_rgb('#5DADE2'), outline=BLACK)
    
    return img

# Mapa de generadores
GENERATORS = {
    'arcane_bolt': {
        'Launch': generate_launch_arcane,
        'InFlight': generate_inflight_arcane,
        'Impact': generate_impact_arcane,
    },
    'dark_missile': {
        'Launch': generate_launch_dark,
        'InFlight': generate_inflight_dark,
        'Impact': generate_impact_dark,
    },
    'fireball': {
        'Launch': generate_launch_fire,
        'InFlight': generate_inflight_fire,
        'Impact': generate_impact_fire,
    },
    'ice_shard': {
        'Launch': generate_launch_ice,
        'InFlight': generate_inflight_ice,
        'Impact': generate_impact_ice,
    },
}

def generate_all():
    """Generar todos los sprites"""
    base_path = os.path.dirname(os.path.abspath(__file__))
    
    for projectile_name, generators in GENERATORS.items():
        projectile_path = os.path.join(base_path, projectile_name)
        os.makedirs(projectile_path, exist_ok=True)
        
        for anim_type, generator_func in generators.items():
            for frame in range(10):
                img = generator_func(frame)
                filename = f"{anim_type}_{projectile_name}_{frame+1:02d}.png"
                filepath = os.path.join(projectile_path, filename)
                img.save(filepath)
                print(f"✓ {filename}")

if __name__ == '__main__':
    print("🎨 Generando sprites de proyectiles...")
    generate_all()
    print("\n✅ 120 sprites generados exitosamente!")
