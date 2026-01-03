#!/usr/bin/env python3
"""Script para actualizar la sección VOID BOLT en AI_SPRITE_PROMPTS.md"""

import re

# Leer el archivo
with open('../project/docs/AI_SPRITE_PROMPTS.md', 'r', encoding='utf-8') as f:
    content = f.read()

# Buscar la sección de VOID BOLT
old_section_pattern = r'## .{1,20}25\. VOID BOLT \(Lightning \+ Void\) - CHAIN.*?(?=\n---\n\n## |\Z)'

new_section = """## 🕳️⚡ 25. VOID BOLT (Lightning + Void) - CHAIN

> Fusión: lightning_wand + void_pulse
> Rayo del vacío que encadena y atrae enemigos hacia portales oscuros
> Ubicación: `res://assets/sprites/projectiles/fusion/void_bolt/`
> ⚠️ IMPORTANTE: El flight sprite es el ARCO que conecta enemigos (se escala horizontalmente)

### flight_spritesheet_void_bolt.png (256x64, 4 frames)
```
Create a cartoon art horizontal sprite sheet of a HORIZONTAL VOID LIGHTNING ARC for a 2D game chain weapon, in cute chibi/Funko Pop cartoon style.

LAYOUT: 4 frames in a single horizontal strip, 256x64 pixels total. Each frame is 64x64. Solid black background (#000000).

⚠️ CRITICAL: This sprite will be STRETCHED HORIZONTALLY to connect two enemies. It must be a HORIZONTAL VOID LIGHTNING BOLT that goes from LEFT EDGE to RIGHT EDGE of each frame.

THE CHAIN ARC: A dark ethereal lightning bolt spanning the FULL WIDTH of each 64x64 frame, going from left to right. Dark purple void energy with reality-bending distortion. This is the visual "chain" that connects enemy A to enemy B.

SHAPE CONCEPT:
- A HORIZONTAL zigzag lightning bolt made of VOID energy from X=0 to X=64
- Starts at LEFT edge, ends at RIGHT edge
- Vertically centered (around Y=32)
- Classic lightning bolt shape with 3-5 zigzag segments
- The bolt is DARK - deep purple/violet with subtle glow
- Small void distortion effect around the bolt (darker areas)
- Particles being PULLED TOWARD the bolt (reverse particle direction)
- Small energy orbs at both ends (connection points)

COLOR PALETTE:
- Core: White-purple (#FFFFFF fading to #CCAAFF)
- Primary: Deep purple-violet (#6633CC / #9966FF)
- Void areas: Very dark purple (#1A001A / #330033)
- Distortion: Darker spots showing "reality bending"
- Outline: Near-black purple (#0D000D), 2 pixels

ANIMATION SEQUENCE (4 frames):
Frame 1: Void arc at rest - dark zigzag bolt with ethereal glow
Frame 2: Arc JITTERS - zigzag shifts, void energy PULSES darker
Frame 3: Maximum intensity - core brightens, distortion at peak, particles pulled in
Frame 4: Arc shifts again - void stabilizes, ready to loop

IMPORTANT DETAILS:
- MUST span full width LEFT to RIGHT (this gets stretched between enemies)
- Vertically centered in frame
- DARK ethereal appearance - mysterious and dangerous
- Particles moving TOWARD the bolt (void pull effect)
- Each frame clearly separated
- Animation shows "dark electricity" effect
```

### impact_spritesheet_void_bolt.png (256x64, 4 frames)
```
Create a cartoon art horizontal sprite sheet of a VOID IMPACT BURST for a 2D game, in cute chibi/Funko Pop cartoon style.

LAYOUT: 4 frames in a single horizontal strip, 256x64 pixels total. Each frame is 64x64. Solid black background (#000000).

THE EFFECT: A void burst at the point where the chain lightning hits an enemy. Creates a small void portal effect that pulls particles inward.

SHAPE CONCEPT:
- CENTERED in each 64x64 frame
- Small circular void portal forming at center
- Purple-white electric sparks around the portal edge
- Particles being SUCKED INWARD (reverse explosion)
- Compact effect - about 40-50px diameter max

COLOR PALETTE:
- Core: Very dark (#1A001A / #330033) void center
- Edge: Purple-white (#9966FF / #CCAAFF) glow ring
- Sparks: White-purple particles
- Distortion: Darker areas around
- Outline: Near-black purple (#0D000D)

ANIMATION SEQUENCE (4 frames):
Frame 1: Initial BURST - flash at center, small dark portal beginning to form
Frame 2: Portal forms - circular void with glowing purple edge, particles pulling in
Frame 3: Maximum pull - portal at peak darkness, particles spiraling inward
Frame 4: Portal closes - void shrinks and fades, last particles absorbed

IMPORTANT DETAILS:
- CENTERED in frame (this appears at hit location)
- Creates small VOID PORTAL effect (circular darkness)
- Particles move INWARD (unique pull mechanic visual)
- Dark, ethereal, otherworldly
- Quick, snappy animation
- Each frame clearly separated
```

"""

# Buscar si existe la sección
match = re.search(old_section_pattern, content, flags=re.DOTALL)
if match:
    print(f"Encontrada sección VOID BOLT en posición {match.start()}-{match.end()}")
    new_content = re.sub(old_section_pattern, new_section, content, flags=re.DOTALL)
    
    with open('../project/docs/AI_SPRITE_PROMPTS.md', 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("VOID BOLT actualizado correctamente")
else:
    print("No se encontró la sección VOID BOLT")
    # Buscar cualquier mención
    if 'VOID BOLT' in content:
        idx = content.find('VOID BOLT')
        print(f"Encontrado 'VOID BOLT' en posición {idx}")
        print(f"Contexto: {content[idx-50:idx+100]}")
