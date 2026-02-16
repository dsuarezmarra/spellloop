"""
Generate Player VFX Spritesheets
Creates spritesheet PNGs for player effects: frost nova, heal, revive, soul link, shield absorb
Each spritesheet is 4x2 frames (8 frames total) with configurable frame size
"""

import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "vfx", "abilities", "player")

def ensure_dirs():
    """Create output directories if they don't exist"""
    for subdir in ["buffs", "heal", "revive", "soul_link", "shield"]:
        path = os.path.join(OUTPUT_DIR, subdir)
        os.makedirs(path, exist_ok=True)

def create_spritesheet(frames, cols=4, rows=2):
    """Assemble individual frame images into a spritesheet"""
    if not frames:
        return None
    fw, fh = frames[0].size
    sheet = Image.new("RGBA", (fw * cols, fh * rows), (0, 0, 0, 0))
    for idx, frame in enumerate(frames):
        col = idx % cols
        row = idx // cols
        sheet.paste(frame, (col * fw, row * fh))
    return sheet


# ═══════════════════════════════════════════════════════════════════════════════
# FROST NOVA — Expanding ice ring with crystal particles
# ═══════════════════════════════════════════════════════════════════════════════

def generate_frost_nova(frame_size=128, num_frames=8):
    """Generate frost nova spritesheet: expanding ice shockwave"""
    frames = []
    cx, cy = frame_size // 2, frame_size // 2
    max_radius = frame_size * 0.45
    
    # Pre-generate crystal positions (consistent across frames)
    random.seed(42)
    crystal_angles = [random.uniform(0, 2 * math.pi) for _ in range(16)]
    crystal_offsets = [random.uniform(0.7, 1.1) for _ in range(16)]
    
    for i in range(num_frames):
        img = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        progress = i / (num_frames - 1)
        
        # Phase: expand (0→0.6), hold (0.6→0.8), fade (0.8→1.0)
        if progress < 0.6:
            expand = progress / 0.6
            alpha_mult = 1.0
        elif progress < 0.8:
            expand = 1.0
            alpha_mult = 1.0
        else:
            expand = 1.0
            alpha_mult = 1.0 - (progress - 0.8) / 0.2
        
        radius = max_radius * expand
        
        # Outer frost ring (thick, icy blue)
        if radius > 5:
            ring_alpha = int(180 * alpha_mult)
            ring_width = max(3, int(8 * (1.0 - expand * 0.4)))
            for w in range(ring_width):
                r = max(1, radius - w)
                color = (140, 210, 255, max(0, ring_alpha - w * 20))
                draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color)
            
            # Inner glow ring
            inner_r = radius * 0.7
            inner_alpha = int(100 * alpha_mult)
            draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
                         outline=(200, 240, 255, inner_alpha))
            
            # Center frost glow
            center_r = radius * 0.3
            center_alpha = int(80 * alpha_mult * (1.0 - expand * 0.5))
            draw.ellipse([cx - center_r, cy - center_r, cx + center_r, cy + center_r],
                         fill=(180, 230, 255, center_alpha))
        
        # Ice crystal particles radiating outward
        for j, angle in enumerate(crystal_angles):
            crystal_dist = radius * crystal_offsets[j] * expand
            if crystal_dist < 5:
                continue
            px = cx + math.cos(angle) * crystal_dist
            py = cy + math.sin(angle) * crystal_dist
            
            # Crystal size varies
            crystal_size = max(1, int(4 * (1.0 - expand * 0.3) * alpha_mult))
            crystal_alpha = int(220 * alpha_mult * (1.0 - expand * 0.2))
            
            # Draw diamond-shaped crystal
            points = [
                (px, py - crystal_size * 1.5),
                (px + crystal_size, py),
                (px, py + crystal_size * 1.5),
                (px - crystal_size, py)
            ]
            # Clip to frame bounds
            valid = all(0 <= p[0] < frame_size and 0 <= p[1] < frame_size for p in points)
            if valid and crystal_alpha > 0:
                draw.polygon(points, fill=(200, 240, 255, crystal_alpha))
        
        # Small snowflake dots
        random.seed(100 + i)
        for _ in range(int(12 * alpha_mult)):
            angle = random.uniform(0, 2 * math.pi)
            dist = random.uniform(radius * 0.3, radius * 1.2) if radius > 10 else random.uniform(5, 20)
            sx = int(cx + math.cos(angle) * dist)
            sy = int(cy + math.sin(angle) * dist)
            dot_size = random.randint(1, 3)
            dot_alpha = int(random.uniform(100, 220) * alpha_mult)
            if 0 <= sx < frame_size and 0 <= sy < frame_size:
                draw.ellipse([sx - dot_size, sy - dot_size, sx + dot_size, sy + dot_size],
                             fill=(220, 245, 255, dot_alpha))
        
        # Apply slight blur for glow effect
        img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
        frames.append(img)
    
    return create_spritesheet(frames)


# ═══════════════════════════════════════════════════════════════════════════════
# HEAL — Rising green particles with sparkles
# ═══════════════════════════════════════════════════════════════════════════════

def generate_heal(frame_size=128, num_frames=8):
    """Generate heal spritesheet: green particles rising with sparkles"""
    frames = []
    cx, cy = frame_size // 2, frame_size // 2
    
    # Pre-generate particle paths
    random.seed(55)
    num_particles = 14
    particles = []
    for _ in range(num_particles):
        particles.append({
            "start_x": random.uniform(-25, 25),
            "start_y": random.uniform(10, 30),
            "speed_y": random.uniform(-50, -90),
            "wobble": random.uniform(0, 2 * math.pi),
            "wobble_amp": random.uniform(5, 15),
            "size": random.uniform(3, 6),
            "delay": random.uniform(0, 0.3),
            "hue_shift": random.uniform(-10, 10),
        })
    
    for i in range(num_frames):
        img = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        progress = i / (num_frames - 1)
        
        # Central green glow (appears first, fades)
        glow_alpha = int(60 * (1.0 - progress * 0.7))
        glow_r = 20 + progress * 10
        draw.ellipse([cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r],
                     fill=(80, 220, 100, glow_alpha))
        
        # Plus/cross symbol in center (early frames)
        if progress < 0.5:
            cross_alpha = int(200 * (1.0 - progress * 2))
            cross_size = 8
            cross_width = 3
            draw.rectangle([cx - cross_width, cy - cross_size, cx + cross_width, cy + cross_size],
                           fill=(150, 255, 150, cross_alpha))
            draw.rectangle([cx - cross_size, cy - cross_width, cx + cross_size, cy + cross_width],
                           fill=(150, 255, 150, cross_alpha))
        
        # Rising particles
        for p in particles:
            t = max(0, progress - p["delay"])
            if t <= 0:
                continue
            
            px = cx + p["start_x"] + math.sin(t * 5 + p["wobble"]) * p["wobble_amp"]
            py = cy + p["start_y"] + p["speed_y"] * t
            
            # Fade out as they rise
            particle_alpha = int(220 * max(0, 1.0 - t * 1.2))
            if particle_alpha <= 0:
                continue
            
            size = p["size"] * (1.0 - t * 0.5)
            if size < 1:
                continue
            
            # Green particle with slight variation
            g = min(255, int(200 + p["hue_shift"]))
            r = min(255, max(0, int(80 + p["hue_shift"])))
            
            if 0 <= px < frame_size and 0 <= py < frame_size:
                draw.ellipse([px - size, py - size, px + size, py + size],
                             fill=(r, g, 80, particle_alpha))
                # Bright center
                if size > 2:
                    draw.ellipse([px - size * 0.4, py - size * 0.4, px + size * 0.4, py + size * 0.4],
                                 fill=(200, 255, 200, min(255, particle_alpha + 50)))
        
        # Sparkle stars
        random.seed(200 + i)
        num_sparkles = int(6 * max(0.2, 1.0 - progress * 0.5))
        for _ in range(num_sparkles):
            sx = cx + random.uniform(-30, 30)
            sy = cy + random.uniform(-40, 20) - progress * 30
            sparkle_size = random.uniform(1, 3)
            sparkle_alpha = int(random.uniform(150, 255) * max(0, 1.0 - progress * 0.8))
            if 0 <= sx < frame_size and 0 <= sy < frame_size and sparkle_alpha > 0:
                # 4-point star
                draw.line([(sx - sparkle_size * 2, sy), (sx + sparkle_size * 2, sy)],
                          fill=(255, 255, 200, sparkle_alpha), width=1)
                draw.line([(sx, sy - sparkle_size * 2), (sx, sy + sparkle_size * 2)],
                          fill=(255, 255, 200, sparkle_alpha), width=1)
        
        img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
        frames.append(img)
    
    return create_spritesheet(frames)


# ═══════════════════════════════════════════════════════════════════════════════
# REVIVE — Golden phoenix explosion
# ═══════════════════════════════════════════════════════════════════════════════

def generate_revive(frame_size=192, num_frames=8):
    """Generate revive spritesheet: golden phoenix burst"""
    frames = []
    cx, cy = frame_size // 2, frame_size // 2
    max_radius = frame_size * 0.42
    
    random.seed(77)
    spark_angles = [random.uniform(0, 2 * math.pi) for _ in range(20)]
    spark_speeds = [random.uniform(0.6, 1.3) for _ in range(20)]
    
    for i in range(num_frames):
        img = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        progress = i / (num_frames - 1)
        
        # Phase: flash (0→0.2), expand (0.2→0.6), fade (0.6→1.0)
        if progress < 0.2:
            flash = progress / 0.2
            expand = flash * 0.3
            alpha_mult = flash
        elif progress < 0.6:
            expand = 0.3 + (progress - 0.2) / 0.4 * 0.7
            alpha_mult = 1.0
        else:
            expand = 1.0
            alpha_mult = 1.0 - (progress - 0.6) / 0.4
        
        radius = max_radius * expand
        
        # Bright center flash (golden white)
        if progress < 0.4:
            flash_alpha = int(200 * (1.0 - progress / 0.4))
            flash_r = 15 + expand * 20
            draw.ellipse([cx - flash_r, cy - flash_r, cx + flash_r, cy + flash_r],
                         fill=(255, 250, 200, flash_alpha))
        
        # Golden ring
        if radius > 5:
            ring_alpha = int(200 * alpha_mult)
            for w in range(5):
                r = max(1, radius - w)
                a = max(0, ring_alpha - w * 30)
                draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                             outline=(255, 200, 50, a))
            
            # Inner warm glow
            inner_r = radius * 0.5
            draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
                         fill=(255, 180, 50, int(50 * alpha_mult)))
        
        # Radiating golden sparks
        for j, angle in enumerate(spark_angles):
            spark_dist = radius * spark_speeds[j] * expand
            if spark_dist < 3:
                continue
            sx = cx + math.cos(angle) * spark_dist
            sy = cy + math.sin(angle) * spark_dist
            
            spark_size = max(1, int(4 * alpha_mult * (1.0 - expand * 0.3)))
            spark_alpha = int(255 * alpha_mult * (1.0 - expand * 0.3))
            
            if 0 <= sx < frame_size and 0 <= sy < frame_size and spark_alpha > 0:
                # Golden spark (elongated along direction)
                end_x = sx + math.cos(angle) * spark_size * 3
                end_y = sy + math.sin(angle) * spark_size * 3
                if 0 <= end_x < frame_size and 0 <= end_y < frame_size:
                    draw.line([(sx, sy), (end_x, end_y)],
                              fill=(255, 220, 80, spark_alpha), width=max(1, spark_size))
                draw.ellipse([sx - spark_size, sy - spark_size, sx + spark_size, sy + spark_size],
                             fill=(255, 240, 150, spark_alpha))
        
        # Phoenix wing hints (V-shaped golden wisps)
        if 0.1 < progress < 0.7:
            wing_alpha = int(150 * alpha_mult * min(1.0, (progress - 0.1) / 0.2))
            wing_spread = 20 + expand * 30
            wing_height = 15 + expand * 20
            # Left wing
            draw.line([(cx, cy), (cx - wing_spread, cy - wing_height)],
                      fill=(255, 180, 50, wing_alpha), width=3)
            draw.line([(cx - wing_spread, cy - wing_height), (cx - wing_spread * 0.6, cy - wing_height * 1.3)],
                      fill=(255, 200, 80, wing_alpha), width=2)
            # Right wing
            draw.line([(cx, cy), (cx + wing_spread, cy - wing_height)],
                      fill=(255, 180, 50, wing_alpha), width=3)
            draw.line([(cx + wing_spread, cy - wing_height), (cx + wing_spread * 0.6, cy - wing_height * 1.3)],
                      fill=(255, 200, 80, wing_alpha), width=2)
        
        img = img.filter(ImageFilter.GaussianBlur(radius=1.2))
        frames.append(img)
    
    return create_spritesheet(frames)


# ═══════════════════════════════════════════════════════════════════════════════
# SOUL LINK — Purple energy chains connecting outward
# ═══════════════════════════════════════════════════════════════════════════════

def generate_soul_link(frame_size=128, num_frames=8):
    """Generate soul link spritesheet: purple energy chains radiating outward"""
    frames = []
    cx, cy = frame_size // 2, frame_size // 2
    max_radius = frame_size * 0.44
    
    random.seed(99)
    chain_angles = [i * 2 * math.pi / 6 + random.uniform(-0.2, 0.2) for i in range(6)]
    
    for i in range(num_frames):
        img = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        progress = i / (num_frames - 1)
        
        # Expand then fade
        if progress < 0.5:
            expand = progress / 0.5
            alpha_mult = min(1.0, expand * 1.5)
        else:
            expand = 1.0
            alpha_mult = 1.0 - (progress - 0.5) / 0.5
        
        # Center purple orb
        orb_r = 8 + expand * 4
        orb_alpha = int(180 * alpha_mult)
        draw.ellipse([cx - orb_r, cy - orb_r, cx + orb_r, cy + orb_r],
                     fill=(160, 80, 220, orb_alpha))
        draw.ellipse([cx - orb_r * 0.5, cy - orb_r * 0.5, cx + orb_r * 0.5, cy + orb_r * 0.5],
                     fill=(220, 180, 255, int(orb_alpha * 0.8)))
        
        # Radiating chains (segmented lines)
        for angle in chain_angles:
            chain_len = max_radius * expand
            num_segments = 6
            
            for seg in range(num_segments):
                t = seg / num_segments
                next_t = (seg + 1) / num_segments
                
                # Wavy chain
                wave = math.sin(t * 3 * math.pi + progress * 4) * 5
                next_wave = math.sin(next_t * 3 * math.pi + progress * 4) * 5
                
                x1 = cx + math.cos(angle) * chain_len * t + math.cos(angle + math.pi / 2) * wave
                y1 = cy + math.sin(angle) * chain_len * t + math.sin(angle + math.pi / 2) * wave
                x2 = cx + math.cos(angle) * chain_len * next_t + math.cos(angle + math.pi / 2) * next_wave
                y2 = cy + math.sin(angle) * chain_len * next_t + math.sin(angle + math.pi / 2) * next_wave
                
                seg_alpha = int(180 * alpha_mult * (1.0 - t * 0.5))
                if seg_alpha > 0:
                    draw.line([(x1, y1), (x2, y2)],
                              fill=(180, 100, 255, seg_alpha), width=2)
            
            # End node
            end_x = cx + math.cos(angle) * chain_len
            end_y = cy + math.sin(angle) * chain_len
            node_r = 3
            node_alpha = int(200 * alpha_mult * (1.0 - expand * 0.2))
            if 0 <= end_x < frame_size and 0 <= end_y < frame_size and node_alpha > 0:
                draw.ellipse([end_x - node_r, end_y - node_r, end_x + node_r, end_y + node_r],
                             fill=(220, 150, 255, node_alpha))
        
        # Pulse ring
        pulse_r = max_radius * expand * 0.6
        pulse_alpha = int(80 * alpha_mult)
        if pulse_r > 5:
            draw.ellipse([cx - pulse_r, cy - pulse_r, cx + pulse_r, cy + pulse_r],
                         outline=(200, 130, 255, pulse_alpha))
        
        img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
        frames.append(img)
    
    return create_spritesheet(frames)


# ═══════════════════════════════════════════════════════════════════════════════
# SHIELD ABSORB — Blue shield flash/ripple
# ═══════════════════════════════════════════════════════════════════════════════

def generate_shield_absorb(frame_size=128, num_frames=8):
    """Generate shield absorb spritesheet: blue shield flash with ripple"""
    frames = []
    cx, cy = frame_size // 2, frame_size // 2
    max_radius = frame_size * 0.42
    
    for i in range(num_frames):
        img = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        progress = i / (num_frames - 1)
        
        # Phase: flash (0→0.3), ripple (0.3→0.7), fade (0.7→1.0)
        if progress < 0.3:
            flash = progress / 0.3
            alpha_mult = flash
        elif progress < 0.7:
            alpha_mult = 1.0
        else:
            alpha_mult = 1.0 - (progress - 0.7) / 0.3
        
        # Shield dome (semi-circle top) - layered
        shield_r = max_radius * min(1.0, progress / 0.2 if progress < 0.2 else 1.0)
        
        if shield_r > 5:
            # Outer glow
            for layer in range(4):
                r = shield_r + layer * 3
                a = max(0, int(40 * alpha_mult) - layer * 10)
                if a > 0:
                    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                                 outline=(80, 150, 255, a))
            
            # Main shield fill (semi-transparent blue)
            fill_alpha = int(50 * alpha_mult)
            draw.ellipse([cx - shield_r, cy - shield_r, cx + shield_r, cy + shield_r],
                         fill=(60, 130, 255, fill_alpha))
            
            # Shield border (bright)
            border_alpha = int(200 * alpha_mult)
            for w in range(3):
                r = max(1, shield_r - w)
                a = max(0, border_alpha - w * 50)
                draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                             outline=(100, 180, 255, a))
        
        # Hexagonal pattern hint
        if 0.1 < progress < 0.8:
            hex_alpha = int(60 * alpha_mult)
            hex_r = shield_r * 0.7
            for h in range(6):
                angle1 = h * math.pi / 3
                angle2 = (h + 1) * math.pi / 3
                x1 = cx + math.cos(angle1) * hex_r
                y1 = cy + math.sin(angle1) * hex_r
                x2 = cx + math.cos(angle2) * hex_r
                y2 = cy + math.sin(angle2) * hex_r
                draw.line([(x1, y1), (x2, y2)],
                          fill=(150, 200, 255, hex_alpha), width=1)
        
        # Ripple waves (expanding outward from impact point)
        if progress > 0.15:
            ripple_progress = (progress - 0.15) / 0.85
            for r_idx in range(3):
                rp = ripple_progress - r_idx * 0.15
                if 0 < rp < 1:
                    ripple_r = shield_r * (0.3 + rp * 0.8)
                    ripple_alpha = int(100 * (1.0 - rp) * alpha_mult)
                    if ripple_alpha > 0 and ripple_r > 3:
                        draw.ellipse([cx - ripple_r, cy - ripple_r, cx + ripple_r, cy + ripple_r],
                                     outline=(180, 220, 255, ripple_alpha))
        
        # Impact sparkles
        if progress < 0.4:
            random.seed(300 + i)
            for _ in range(5):
                angle = random.uniform(0, 2 * math.pi)
                dist = shield_r * random.uniform(0.5, 1.0)
                sx = cx + math.cos(angle) * dist
                sy = cy + math.sin(angle) * dist
                s_size = random.randint(1, 3)
                s_alpha = int(random.uniform(150, 255) * alpha_mult)
                if 0 <= sx < frame_size and 0 <= sy < frame_size:
                    draw.ellipse([sx - s_size, sy - s_size, sx + s_size, sy + s_size],
                                 fill=(200, 230, 255, s_alpha))
        
        img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
        frames.append(img)
    
    return create_spritesheet(frames)


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    ensure_dirs()
    
    effects = [
        ("Frost Nova", generate_frost_nova, 128, 
         os.path.join(OUTPUT_DIR, "buffs", "vfx_player_frost_nova_spritesheet.png")),
        ("Heal", generate_heal, 128,
         os.path.join(OUTPUT_DIR, "heal", "vfx_player_heal_spritesheet.png")),
        ("Revive", generate_revive, 192,
         os.path.join(OUTPUT_DIR, "revive", "vfx_player_revive_spritesheet.png")),
        ("Soul Link", generate_soul_link, 128,
         os.path.join(OUTPUT_DIR, "soul_link", "vfx_player_soul_link_spritesheet.png")),
        ("Shield Absorb", generate_shield_absorb, 128,
         os.path.join(OUTPUT_DIR, "shield", "vfx_player_shield_absorb_spritesheet.png")),
    ]
    
    for name, gen_func, size, path in effects:
        print(f"Generating {name} ({size}x{size} per frame)...")
        sheet = gen_func(frame_size=size)
        if sheet:
            sheet.save(path, "PNG")
            print(f"  ✓ Saved: {path}")
            print(f"    Sheet size: {sheet.size[0]}x{sheet.size[1]}")
        else:
            print(f"  ✗ Failed to generate {name}")
    
    print("\nAll spritesheets generated!")

if __name__ == "__main__":
    main()
