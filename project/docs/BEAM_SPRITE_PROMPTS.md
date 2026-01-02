# BEAM Weapon Sprite Prompts

Este documento contiene los prompts para generar sprites de armas tipo BEAM en Spellloop.

## Arquitectura de Sprites BEAM

Las armas BEAM requieren **2 tipos de sprites**:

| Tipo | Archivo | Dimensiones | Descripción |
|------|---------|-------------|-------------|
| **BODY** | `beam_body_[weapon].png` | 64×32 (tileable) | Textura del rayo (se repite) |
| **TIP** | `beam_tip_[weapon].png` | 384×64 (6 frames de 64×64) | Destello de impacto animado |

### Ubicación de Archivos
```
res://assets/sprites/projectiles/weapons/[weapon_id]/
├── beam_body_[weapon_id].png
└── beam_tip_[weapon_id].png
```

---

## Lista de Armas BEAM

| ID | Nombre | Elementos | Paleta de Colores |
|----|--------|-----------|-------------------|
| light_beam | Light Beam | Light | Blanco (#FFFFFF), Dorado (#FFD700), Amarillo pálido (#FFFACD) |
| thunder_spear | Thunder Spear | Lightning + Light | Cyan (#00FFFF), Dorado (#FFD700), Blanco eléctrico |
| aurora | Aurora | Ice + Light | Cyan (#00FFFF), Verde aurora (#50FA7B), Blanco hielo |
| solar_flare | Solar Flare | Fire + Light | Naranja (#FF8C00), Amarillo (#FFD700), Blanco solar |
| solar_bloom | Solar Bloom | Nature + Light | Verde (#50FA7B), Dorado (#FFD700), Amarillo |
| eclipse | Eclipse | Light + Void | Blanco/Dorado ↔ Púrpura (#9B59B6)/Negro |

---

# PROMPTS POR ARMA

---

## 1. LIGHT BEAM (Luz Pura)

### beam_body_light_beam.png
```
Pixel art seamless tileable texture, 64x32 pixels.
Horizontal light beam ray body for a holy beam weapon.
Pure white and golden color palette (#FFFFFF, #FFD700, #FFFACD).
Bright white core in the center (brightest line).
Golden glow fading outward toward edges.
Soft particle sparkles scattered throughout.
Must tile seamlessly horizontally (left edge connects to right edge).
Transparent background, clean pixel art style.
Ethereal holy energy feel, luminous and divine appearance.
```

### beam_tip_light_beam.png
```
Pixel art spritesheet, 384x64 pixels total, 6 frames of 64x64 each arranged horizontally.
Animation of holy light impact/endpoint of a beam attack.
Pure white and golden color palette (#FFFFFF, #FFD700, #FFFACD).
Frame 1: Initial contact point, small bright flash
Frame 2: Expanding light burst with golden sparks
Frame 3: Full radiant explosion with light rays
Frame 4: Peak brightness with divine cross pattern
Frame 5: Dispersing light particles and sparkles
Frame 6: Fading glow with lingering golden motes
Transparent background, clean pixel art style, 16-bit aesthetic.
Holy magical impact feel, dramatic radiance, purifying energy.
```

---

## 2. THUNDER SPEAR (Trueno Divino)

### beam_body_thunder_spear.png
```
Pixel art seamless tileable texture, 64x32 pixels.
Horizontal lightning beam ray body for divine thunder weapon.
Cyan and golden electric color palette (#00FFFF, #FFD700, #FFFFFF).
Jagged electric core line in bright cyan (not straight, lightning-like).
Golden electric glow around the edges.
Small spark particles scattered throughout.
Must tile seamlessly horizontally (left edge connects to right edge).
Transparent background, clean pixel art style.
Electric energy feel, crackling thunder, divine lightning appearance.
```

### beam_tip_thunder_spear.png
```
Pixel art spritesheet, 384x64 pixels total, 6 frames of 64x64 each arranged horizontally.
Animation of divine thunder impact at endpoint of lightning beam.
Cyan and golden electric color palette (#00FFFF, #FFD700, #FFFFFF).
Frame 1: Initial electric contact, small spark burst
Frame 2: Expanding lightning branches in all directions
Frame 3: Full electric explosion with multiple bolts
Frame 4: Peak discharge with bright golden-cyan flash
Frame 5: Electric arcs dissipating outward
Frame 6: Fading sparks and lingering static energy
Transparent background, clean pixel art style, 16-bit aesthetic.
Thunder strike impact, electric explosion, divine judgment.
```

---

## 3. AURORA (Luz Helada)

### beam_body_aurora.png
```
Pixel art seamless tileable texture, 64x32 pixels.
Horizontal aurora beam ray body for ice-light weapon.
Cyan, green aurora, and white palette (#00FFFF, #50FA7B, #E0FFFF).
Gradient bands of cyan and green (aurora borealis effect).
Subtle ice crystal sparkles embedded in the beam.
Soft wavy pattern suggesting aurora movement.
Must tile seamlessly horizontally (left edge connects to right edge).
Transparent background, clean pixel art style.
Northern lights energy, frozen elegance, mystical ice-light.
```

### beam_tip_aurora.png
```
Pixel art spritesheet, 384x64 pixels total, 6 frames of 64x64 each arranged horizontally.
Animation of aurora light impact at endpoint of ice-light beam.
Cyan, green aurora, and white ice palette (#00FFFF, #50FA7B, #E0FFFF).
Frame 1: Initial contact with ice crystal formation
Frame 2: Expanding aurora burst with cyan-green swirls
Frame 3: Full aurora explosion with dancing lights
Frame 4: Peak brightness with ice shards and color waves
Frame 5: Dispersing aurora wisps and ice particles
Frame 6: Fading glow with lingering ice sparkles
Transparent background, clean pixel art style, 16-bit aesthetic.
Aurora impact, frozen light burst, elegant icy explosion.
```

---

## 4. SOLAR FLARE (Llamarada Solar)

### beam_body_solar_flare.png
```
Pixel art seamless tileable texture, 64x32 pixels.
Horizontal solar plasma beam ray body for fire-light weapon.
Orange, yellow, and white-hot palette (#FF8C00, #FFD700, #FFFFFF).
White-hot bright core in the center.
Orange and yellow plasma flames along the edges.
Small ember particles and heat distortion suggestion.
Must tile seamlessly horizontally (left edge connects to right edge).
Transparent background, clean pixel art style.
Solar plasma energy, blazing heat ray, stellar fire beam.
```

### beam_tip_solar_flare.png
```
Pixel art spritesheet, 384x64 pixels total, 6 frames of 64x64 each arranged horizontally.
Animation of solar plasma impact at endpoint of fire-light beam.
Orange, yellow, and white-hot palette (#FF8C00, #FFD700, #FFFFFF, #FF4500).
Frame 1: Initial plasma contact, small solar burst
Frame 2: Expanding solar flare with erupting flames
Frame 3: Full plasma explosion with corona effect
Frame 4: Peak intensity with white-hot flash and embers
Frame 5: Dispersing solar particles and flame wisps
Frame 6: Fading heat glow with lingering embers
Transparent background, clean pixel art style, 16-bit aesthetic.
Solar explosion impact, plasma burst, stellar devastation.
```

---

## 5. SOLAR BLOOM (Florecimiento Solar)

### beam_body_solar_bloom.png
```
Pixel art seamless tileable texture, 64x32 pixels.
Horizontal nature-light beam ray body for solar bloom weapon.
Green, golden, and yellow palette (#50FA7B, #FFD700, #ADFF2F).
Bright golden-green core in the center.
Leaf-like patterns and vine suggestions along edges.
Small pollen sparkles and life energy particles.
Must tile seamlessly horizontally (left edge connects to right edge).
Transparent background, clean pixel art style.
Life energy beam, photosynthesis ray, nature-light fusion.
```

### beam_tip_solar_bloom.png
```
Pixel art spritesheet, 384x64 pixels total, 6 frames of 64x64 each arranged horizontally.
Animation of nature-light impact at endpoint of life energy beam.
Green, golden, and yellow palette (#50FA7B, #FFD700, #ADFF2F, #98FB98).
Frame 1: Initial contact with sprouting energy burst
Frame 2: Expanding bloom explosion with petals of light
Frame 3: Full flower burst with golden pollen cloud
Frame 4: Peak radiance with leaves and light rays
Frame 5: Dispersing pollen particles and leaf wisps
Frame 6: Fading glow with lingering nature sparkles
Transparent background, clean pixel art style, 16-bit aesthetic.
Life energy burst, blooming explosion, natural magic impact.
```

---

## 6. ECLIPSE (Eclipse)

### beam_body_eclipse.png
```
Pixel art seamless tileable texture, 64x32 pixels.
Horizontal eclipse beam ray body for light-void weapon.
Dual palette: White/Gold AND Purple/Black gradient.
One half of beam is bright white-gold light energy.
Other half is deep purple-black void energy.
Swirling boundary between light and dark in the middle.
Must tile seamlessly horizontally (left edge connects to right edge).
Transparent background, clean pixel art style.
Cosmic duality beam, light and shadow intertwined, eclipse energy.
```

### beam_tip_eclipse.png
```
Pixel art spritesheet, 384x64 pixels total, 6 frames of 64x64 each arranged horizontally.
Animation of light-void impact at endpoint of eclipse beam.
Dual palette: White/Gold (#FFFFFF, #FFD700) AND Purple/Black (#9B59B6, #2D1B4E).
Frame 1: Initial contact with light-dark flash
Frame 2: Expanding duality burst with interweaving energies
Frame 3: Full eclipse explosion with corona of both forces
Frame 4: Peak contrast with brilliant white and deep void
Frame 5: Dispersing light and shadow particles spiraling
Frame 6: Fading glow with lingering cosmic duality motes
Transparent background, clean pixel art style, 16-bit aesthetic.
Cosmic impact, duality explosion, light-void annihilation.
```

---

## Notas de Implementación

### Para ChatGPT/DALL-E:
1. Generar cada sprite por separado (BODY, TIP)
2. Verificar dimensiones exactas antes de guardar
3. El BODY debe ser tileable horizontalmente

### Para Verificar Tileability del BODY:
```python
# Test visual de tileable
from PIL import Image
img = Image.open("beam_body_xxx.png")
# Crear imagen repetida 4 veces
tiled = Image.new('RGBA', (256, 32))
for i in range(4):
    tiled.paste(img, (i * 64, 0))
tiled.save("test_tiled.png")
```

### Ubicación Final en Proyecto:
```
project/assets/sprites/projectiles/weapons/[weapon_id]/
├── beam_body_[weapon_id].png    # 64x32 (tileable)
└── beam_tip_[weapon_id].png     # 384x64 (6 frames)
```

### Checklist por Arma:
- [ ] light_beam (BODY / TIP)
- [ ] thunder_spear (BODY / TIP)
- [ ] aurora (BODY / TIP)
- [ ] solar_flare (BODY / TIP)
- [ ] solar_bloom (BODY / TIP)
- [ ] eclipse (BODY / TIP)
