# 🎨 PROMPTS PARA GEMINI - VFX DE HABILIDADES DE ENEMIGOS

## Información del Proyecto

**Estilo Visual:** Cartoon / Funko Pop / Chubby
- Personajes y efectos con aspecto cute/adorable
- Formas redondeadas y suaves
- Colores vibrantes con outlines definidos
- Resolución base: 64x64px (proyectiles), 128x128px (AOE pequeño), 256x256px (AOE grande)
- Formato: PNG con transparencia (RGBA)
- Spritesheets: Cuadrados (4x2 = 8 frames) excepto beams (horizontal 8x1)

**Paleta de Colores por Elemento:**
| Elemento | Primary | Secondary | Accent | Outline |
|----------|---------|-----------|--------|---------|
| Fire 🔥 | #FF6611 | #FFCC00 | #FF9944 | #661100 |
| Ice ❄️ | #66CCFF | #FFFFFF | #99EEFF | #1A3A5C |
| Arcane ✨ | #B34DFF | #FF66CC | #DD99FF | #330066 |
| Void 🌑 | #330033 | #660066 | #990099 | #1A001A |
| Poison ☠️ | #4DCC33 | #99FF66 | #CCFF99 | #1A4D13 |
| Lightning ⚡ | #FFFF4D | #FFFFFF | #FFFF99 | #6633CC |
| Rune/Gold 🛡️ | #FFD700 | #FFF8DC | #FFEC8B | #8B6914 |

---

## CATEGORÍA 1: PROYECTILES DE ENEMIGOS
**Carpeta destino:** `assets/vfx/abilities/projectiles/{elemento}/`
**Tamaño:** 64x64px por frame
**Formato:** Spritesheet 4x2 (8 frames totales)
**Animaciones:** 4 frames vuelo (loop) + 4 frames impacto

---

### PROMPT 1.1: Proyectiles de Fuego

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Cute, chubby, rounded cartoon style (think Funko Pop meets Vampire Survivors)
- Thick dark outlines (#661100)
- Soft shading with no hard edges
- Solid black background (PNG with alpha)

CONTENT - FIRE PROJECTILE:
Row 1 (Flight Animation - 4 frames, loops):
- Frame 1-4: A bouncy round fireball with flickering flame wisps
- Primary color: #FF6611 (orange-red)
- Secondary color: #FFCC00 (bright yellow core)
- Accent: #FF9944 (highlights)
- Add small ember particles floating around
- Subtle pulsing/breathing animation between frames
- Cute "face" optional - two small dot eyes looking forward

Row 2 (Impact Animation - 4 frames, plays once):
- Frame 1: Initial contact, squash effect
- Frame 2: Explosion outward with flame burst
- Frame 3: Flames dissipating into sparks
- Frame 4: Final wisps fading out

OUTPUT: Single PNG file, 256x128 pixels, named "projectile_fire_spritesheet.png"
```

---

### PROMPT 1.2: Proyectiles de Hielo

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Cute, chubby, rounded cartoon style (Funko Pop aesthetic)
- Thick dark outlines (#1A3A5C)
- Soft shading, crystalline appearance
- Solid black background (PNG with alpha)

CONTENT - ICE PROJECTILE:
Row 1 (Flight Animation - 4 frames, loops):
- Frame 1-4: A pointed ice crystal shard, but with cute rounded joints
- Primary color: #66CCFF (ice blue)
- Secondary color: #FFFFFF (bright white core/highlights)
- Accent: #99EEFF (frost shimmer)
- Sparkle particles and frost trail effect
- Gentle rotation between frames
- Optional cute element: tiny snowflake particles

Row 2 (Impact Animation - 4 frames, plays once):
- Frame 1: Crystal hitting and cracking
- Frame 2: Shattering into smaller crystals
- Frame 3: Ice shards flying outward
- Frame 4: Frost cloud dissipating with sparkles

OUTPUT: Single PNG file, 256x128 pixels, named "projectile_ice_spritesheet.png"
```

---

### PROMPT 1.3: Proyectiles Arcanos

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Cute, mystical cartoon style (Funko Pop aesthetic)
- Thick dark outlines (#330066)
- Magical glow effects
- Solid black background (PNG with alpha)

CONTENT - ARCANE PROJECTILE:
Row 1 (Flight Animation - 4 frames, loops):
- Frame 1-4: A perfect glowing magical orb with inner swirl pattern
- Primary color: #B34DFF (magical purple)
- Secondary color: #FF66CC (pink energy core)
- Accent: #DD99FF (highlights and runes)
- Small floating rune symbols orbiting the orb
- Mystical trail with star particles
- Pulsing glow animation between frames

Row 2 (Impact Animation - 4 frames, plays once):
- Frame 1: Orb flattening on impact
- Frame 2: Magical burst with rune circle appearing
- Frame 3: Energy waves expanding
- Frame 4: Sparkles and runes fading

OUTPUT: Single PNG file, 256x128 pixels, named "projectile_arcane_spritesheet.png"
```

---

### PROMPT 1.4: Proyectiles del Vacío

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Cute but slightly ominous cartoon style
- Thick dark outlines (#1A001A)
- Dark energy with distortion effect
- Solid black background (PNG with alpha)

CONTENT - VOID PROJECTILE:
Row 1 (Flight Animation - 4 frames, loops):
- Frame 1-4: A dark orb with particles being sucked INTO it (reverse particle effect)
- Primary color: #330033 (deep purple-black)
- Secondary color: #660066 (dark purple glow)
- Accent: #990099 (bright purple edges)
- Distortion waves around the orb
- Small dots/particles spiraling inward
- Subtle wobble animation between frames

Row 2 (Impact Animation - 4 frames, plays once):
- Frame 1: Orb imploding slightly
- Frame 2: Dark energy explosion outward
- Frame 3: Void tendrils reaching out then retracting
- Frame 4: Dark wisps fading into nothing

OUTPUT: Single PNG file, 256x128 pixels, named "projectile_void_spritesheet.png"
```

---

### PROMPT 1.5: Proyectiles de Veneno

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Cute, gooey cartoon style (Funko Pop aesthetic)
- Thick dark outlines (#1A4D13)
- Slimy, bubbly appearance
- Solid black background (PNG with alpha)

CONTENT - POISON PROJECTILE:
Row 1 (Flight Animation - 4 frames, loops):
- Frame 1-4: A gooey poison glob with bubbles popping
- Primary color: #4DCC33 (toxic green)
- Secondary color: #99FF66 (bright green highlights)
- Accent: #CCFF99 (glowing bubbles)
- Dripping slime trail effect
- Bubbles forming and popping between frames
- Cute but gross aesthetic - maybe skull pattern in the goo

Row 2 (Impact Animation - 4 frames, plays once):
- Frame 1: Glob splatting and spreading
- Frame 2: Poison splash with droplets
- Frame 3: Toxic puddle forming with bubbles
- Frame 4: Fumes rising and fading

OUTPUT: Single PNG file, 256x128 pixels, named "projectile_poison_spritesheet.png"
```

---

### PROMPT 1.6: Orbes Homing del Vacío (Boss: Corazón del Vacío)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Cute but menacing cartoon style
- Thick dark outlines (#1A001A)
- Pulsating, alive appearance
- Solid black background (PNG with alpha)

CONTENT - VOID HOMING ORB (Tracks the player):
Row 1 (Flight Animation - 4 frames, loops):
- Frame 1-4: A dark pulsating orb with a single "eye" that follows
- Primary color: #330033 (void black-purple)
- Secondary color: #660066 (inner glow)
- Accent: #990099 (eye and highlights)
- Single menacing but cute eye in the center
- Dark tendrils trailing behind
- Pulsing/breathing animation, eye blinks in frame 3

Row 2 (Impact Animation - 4 frames, plays once):
- Frame 1: Eye closing, orb squashing
- Frame 2: Dark explosion with eye fragments
- Frame 3: Void energy scattering
- Frame 4: Dark particles fading

OUTPUT: Single PNG file, 256x128 pixels, named "projectile_void_homing_spritesheet.png"
```

---

## CATEGORÍA 2: EFECTOS DE ÁREA (AOE)
**Carpeta destino:** `assets/vfx/abilities/aoe/{elemento}/`
**Tamaño pequeño:** 128x128px por frame
**Tamaño grande:** 256x256px por frame
**Formato:** Spritesheet 4x2 (8 frames totales)
**Animaciones:** 2 frames appear + 4 frames active (loop) + 2 frames fade

---

### PROMPT 2.1: Fire Stomp (Minotauro + Élites)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Cute, impactful cartoon style
- Thick dark outlines (#661100)
- Dynamic fire effects
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW (player looks from above)

CONTENT - FIRE STOMP AOE (radius: 160px in-game):
Row 1 (Appear + Active frames 1-4):
- Frame 1: Ground cracking with initial impact lines
- Frame 2: Fire erupting from cracks, flames starting
- Frame 3: Full fire ring with flames dancing (active loop start)
- Frame 4: Flames at peak with ember particles (active loop)

Row 2 (Active + Fade frames 5-8):
- Frame 5: Flames waving, still dangerous (active loop)
- Frame 6: Fire starting to recede (active loop end)
- Frame 7: Flames dying down, embers floating
- Frame 8: Final smoke wisps and cooling cracks

Colors:
- Primary: #FF6611 (fire orange)
- Secondary: #FFCC00 (yellow flames)
- Accent: #FF9944 (highlights)
- Ground cracks: #661100 with #FFaa00 glow inside

OUTPUT: Single PNG file, 512x256 pixels, named "aoe_fire_stomp_spritesheet.png"
```

---

### PROMPT 2.2: Fire Zone (Señor de las Llamas)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 1024x512 pixels (4 columns x 2 rows, each cell 256x256 pixels).

STYLE REQUIREMENTS:
- Cute but dangerous-looking fire zone
- Thick dark outlines (#661100)
- Persistent fire pool effect
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW

CONTENT - FIRE ZONE (radius: 80px, persists 5 seconds):
Row 1 (Appear + Active frames 1-4):
- Frame 1: Fire starting from center, spreading outward
- Frame 2: Fire pool forming, flames appearing
- Frame 3: Full fire zone active, dancing flames (loop start)
- Frame 4: Fire at full intensity with sparks (loop)

Row 2 (Active + Fade frames 5-8):
- Frame 5: Flames continuing to dance (loop)
- Frame 6: Fire still active but starting to flicker (loop end)
- Frame 7: Flames shrinking, some areas cooling
- Frame 8: Last embers, smoke wisps, zone ending

Colors:
- Primary: #FF6611 (orange fire)
- Secondary: #FFCC00 (bright yellow)
- Ground: Dark scorched marks with lava-like glow
- Outer ring: Darker, cooler flames

OUTPUT: Single PNG file, 1024x512 pixels, named "aoe_fire_zone_spritesheet.png"
```

---

### PROMPT 2.3: Freeze Zone (Reina del Hielo)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 1024x512 pixels (4 columns x 2 rows, each cell 256x256 pixels).

STYLE REQUIREMENTS:
- Beautiful, crystalline ice effect
- Thick dark outlines (#1A3A5C)
- Freezing, slowing visual
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW

CONTENT - FREEZE ZONE (radius: 120px, 50% slow):
Row 1 (Appear + Active frames 1-4):
- Frame 1: Frost spreading from center, ice crystals forming
- Frame 2: Ice spreading outward in beautiful patterns
- Frame 3: Full frozen area with ice spikes (loop start)
- Frame 4: Snowflakes falling, crystals glinting (loop)

Row 2 (Active + Fade frames 5-8):
- Frame 5: Ice continuing to sparkle (loop)
- Frame 6: Ice still active, slight melting edges (loop end)
- Frame 7: Ice cracking, melting starts
- Frame 8: Final frost fading, water puddles

Colors:
- Primary: #66CCFF (ice blue)
- Secondary: #FFFFFF (pure white crystals)
- Accent: #99EEFF (sparkles)
- Cracks: #1A3A5C

OUTPUT: Single PNG file, 1024x512 pixels, named "aoe_freeze_zone_spritesheet.png"
```

---

### PROMPT 2.4: Arcane Nova (El Conjurador Primigenio)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 1024x512 pixels (4 columns x 2 rows, each cell 256x256 pixels).

STYLE REQUIREMENTS:
- Magical, explosive purple energy
- Thick dark outlines (#330066)
- Expanding wave pattern
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW

CONTENT - ARCANE NOVA (radius: 140-180px, burst damage):
Row 1 (Charge + Burst frames 1-4):
- Frame 1: Energy gathering in center, runes appearing
- Frame 2: Magical circle forming, energy intensifying
- Frame 3: EXPLOSION outward - bright flash
- Frame 4: Expanding ring of arcane energy

Row 2 (Expand + Fade frames 5-8):
- Frame 5: Energy wave at maximum, runes floating
- Frame 6: Wave passing, leaving magical residue
- Frame 7: Energy dissipating, sparkles remaining
- Frame 8: Final runes fading, sparkles gone

Colors:
- Primary: #B34DFF (arcane purple)
- Secondary: #FF66CC (pink energy core)
- Accent: #DD99FF (highlights)
- Runes: #FFD700 golden symbols

OUTPUT: Single PNG file, 1024x512 pixels, named "aoe_arcane_nova_spritesheet.png"
```

---

### PROMPT 2.5: Void Explosion (El Corazón del Vacío)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 1024x512 pixels (4 columns x 2 rows, each cell 256x256 pixels).

STYLE REQUIREMENTS:
- Dark, ominous void energy
- Thick dark outlines (#1A001A)
- Implosion then explosion effect
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW

CONTENT - VOID EXPLOSION (radius: 180px, high damage):
Row 1 (Implode + Explode frames 1-4):
- Frame 1: Particles being SUCKED toward center
- Frame 2: Center glowing with compressed void energy
- Frame 3: EXPLOSION - dark energy bursting outward
- Frame 4: Void tendrils reaching out in all directions

Row 2 (Expand + Fade frames 5-8):
- Frame 5: Tendrils at maximum reach
- Frame 6: Tendrils retracting, energy collapsing
- Frame 7: Dark wisps remaining
- Frame 8: Final darkness fading to nothing

Colors:
- Primary: #330033 (void black)
- Secondary: #660066 (dark purple glow)
- Accent: #990099 (bright edges)
- Center core: White/bright flash during explosion

OUTPUT: Single PNG file, 1024x512 pixels, named "aoe_void_explosion_spritesheet.png"
```

---

### PROMPT 2.6: Rune Blast (El Guardián de Runas)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Golden, ancient rune magic
- Thick dark outlines (#8B6914)
- Geometric, runic patterns
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW

CONTENT - RUNE BLAST (radius: 100px, stuns 0.5s):
Row 1 (Charge + Blast frames 1-4):
- Frame 1: Runic circle appearing on ground
- Frame 2: Runes glowing brighter, energy gathering
- Frame 3: BLAST - golden light exploding
- Frame 4: Concentric rune rings expanding

Row 2 (Expand + Fade frames 5-8):
- Frame 5: Rune energy at maximum
- Frame 6: Rings passing, leaving golden dust
- Frame 7: Runes fading, sparkles floating
- Frame 8: Final golden particles disappearing

Colors:
- Primary: #FFD700 (gold)
- Secondary: #FFF8DC (cream/white)
- Accent: #FFEC8B (light gold)
- Rune symbols: Ancient geometric shapes

OUTPUT: Single PNG file, 512x256 pixels, named "aoe_rune_blast_spritesheet.png"
```

---

### PROMPT 2.7: Ground Slam (Gólem Rúnico + Titán Arcano)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Heavy, earthy impact
- Thick dark outlines (#4D3319)
- Ground-breaking effect
- Solid black background (PNG with alpha)
- TOP-DOWN VIEW

CONTENT - GROUND SLAM (radius: 100-120px):
Row 1 (Impact + Shockwave frames 1-4):
- Frame 1: Initial impact crater forming
- Frame 2: Cracks spreading outward from center
- Frame 3: Rock debris flying up (shown as shadows/pieces)
- Frame 4: Shockwave ring expanding

Row 2 (Debris + Settle frames 5-8):
- Frame 5: Maximum crack spread, debris falling
- Frame 6: Debris settling, cracks visible
- Frame 7: Dust cloud settling
- Frame 8: Final cracks remaining, dust fading

Colors:
- Primary: #996633 (brown earth)
- Secondary: #CC9966 (light stone)
- Accent: #DDBB88 (highlights)
- Cracks: Dark #4D3319 with subtle inner glow

OUTPUT: Single PNG file, 512x256 pixels, named "aoe_ground_slam_spritesheet.png"
```

---

### PROMPT 2.8: Meteor Impact Warning + Impact

```
Create TWO sprite sheets for a cartoon/funko pop style game.

SHEET 1 - WARNING INDICATOR (256x128 pixels, 4x2 grid, 64x64 cells):
Row 1-2 (8 frames looping warning):
- Pulsating red/orange circle indicating where meteor will land
- Danger symbol (!) in center
- Circle shrinks slightly each frame then expands
- Colors: Red #FF3333 with orange #FF9933 edges
- Very visible, cute but alarming

OUTPUT: "telegraph_meteor_warning_spritesheet.png"

SHEET 2 - METEOR IMPACT (512x256 pixels, 4x2 grid, 128x128 cells):
Row 1 (Approach + Impact frames 1-4):
- Frame 1: Meteor shadow appearing (it's coming down!)
- Frame 2: Meteor visible, trailing fire
- Frame 3: IMPACT - huge fiery explosion
- Frame 4: Fire expanding outward

Row 2 (Explosion + Fade frames 5-8):
- Frame 5: Maximum explosion radius
- Frame 6: Fire receding, debris flying
- Frame 7: Smoke and embers remaining
- Frame 8: Final smoke wisps fading

Colors: Fire palette (#FF6611, #FFCC00, #FF9944)
Meteor: Dark rock with glowing cracks

OUTPUT: "aoe_meteor_impact_spritesheet.png"
```

---

## CATEGORÍA 3: BEAMS Y CONOS
**Carpeta destino:** `assets/vfx/abilities/beams/`
**Tamaño:** 512x64px (beam) o 256x256px (cone)
**Formato:** Spritesheet horizontal 8x1 para beams

---

### PROMPT 3.1: Flame Breath (Minotauro + Dragón Etéreo)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (2 columns x 4 rows, each cell 256x64 pixels for the beam, but we want a CONE shape).

ACTUALLY - Create 256x256 sprite sheet (4x2 grid, 64x64 cells) showing TOP-DOWN CONE BREATH:

STYLE REQUIREMENTS:
- Cartoon fire breath in cone shape
- Thick outlines (#661100)
- 45-55 degree spread angle
- Solid black background
- TOP-DOWN VIEW - cone spreading from left side to right

CONTENT - FLAME BREATH CONE:
Row 1 (Start + Active frames 1-4):
- Frame 1: Flames starting to emerge from source point (left)
- Frame 2: Cone of fire expanding outward
- Frame 3: Full cone of flames (loop start)
- Frame 4: Flames dancing within cone (loop)

Row 2 (Active + End frames 5-8):
- Frame 5: Fire still roaring (loop)
- Frame 6: Flames continuing (loop end)
- Frame 7: Fire receding back toward source
- Frame 8: Final embers, breath ending

The cone should show SPREAD - narrow at source, wide at the end.
Colors: Fire palette (#FF6611, #FFCC00, #FF9944)

OUTPUT: Single PNG file, 256x256 pixels, named "beam_flame_breath_spritesheet.png"
```

---

### PROMPT 3.2: Void Beam (El Corazón del Vacío)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x64 pixels (8 columns x 1 row, each cell 64x64 pixels - HORIZONTAL BEAM).

STYLE REQUIREMENTS:
- Dark void energy beam
- Thick outlines (#1A001A)
- Channeled/continuous beam effect
- Solid black background
- SIDE VIEW of beam (horizontal)

CONTENT - VOID BEAM (2.5 second channel, high damage):
Frames 1-8 (Start → Active → End):
- Frame 1: Beam starting, energy gathering at source (left)
- Frame 2: Beam extending, dark energy crackling
- Frame 3: Beam at full length, stable (loop start)
- Frame 4: Beam pulsing with void energy (loop)
- Frame 5: Energy intensifying along beam (loop)
- Frame 6: Beam still active, particles absorbed (loop end)
- Frame 7: Beam weakening, becoming unstable
- Frame 8: Beam dissipating into wisps

The beam should have:
- Concentrated dark core
- Lighter purple edges/glow
- Particles being sucked INTO the beam
- Distortion effect around it

Colors: Void palette (#330033 core, #660066 glow, #990099 edges)

OUTPUT: Single PNG file, 512x64 pixels, named "beam_void_beam_spritesheet.png"
```

---

## CATEGORÍA 4: INDICADORES DE ADVERTENCIA (TELEGRAPHS)
**Carpeta destino:** `assets/vfx/abilities/telegraphs/`
**Tamaño:** 64x64px (pequeño) o 128x128px (grande)
**Formato:** Spritesheet 4x2 (8 frames loop)

---

### PROMPT 4.1: Telegraph Circular Genérico (Warning antes de AOE)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Clearly visible warning indicator
- Pulsating animation
- Universal "danger" look
- Solid black background
- TOP-DOWN VIEW

CONTENT - CIRCULAR WARNING (generic AOE telegraph):
8 frames looping animation:
- Frames 1-2: Circle at minimum size, dim
- Frames 3-4: Circle expanding, brightening
- Frames 5-6: Circle at maximum size, brightest
- Frames 7-8: Circle contracting back

Features:
- Red/orange danger color (#FF4444 main, #FF8800 secondary)
- Dashed or segmented circle edge (like a loading ring)
- Small danger symbol (!) in center
- Subtle rotation effect between frames
- Cute but clearly dangerous looking

OUTPUT: Single PNG file, 256x128 pixels, named "telegraph_circle_warning_spritesheet.png"
```

---

### PROMPT 4.2: Telegraph Línea de Carga (Charge Attack warning)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels) - but the content represents a LINE/ARROW.

STYLE REQUIREMENTS:
- Linear charge attack warning
- Shows direction of incoming attack
- Pulsating animation
- Solid black background
- TOP-DOWN VIEW

CONTENT - CHARGE LINE WARNING:
8 frames looping animation showing a horizontal arrow/line:
- The line pulses and the arrow flashes
- Shows the enemy is about to dash in this direction
- Frames alternate between dim and bright

Features:
- Red danger color (#FF4444)
- Arrow pointing right (enemy charges this direction)
- Dashed line body
- Speed lines suggesting motion
- Can be rotated in-game for any direction

OUTPUT: Single PNG file, 256x128 pixels, named "telegraph_charge_line_spritesheet.png"
```

---

### PROMPT 4.3: Telegraph Rune Prison (Atrapamiento)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Magical prison/trap warning
- Golden rune aesthetics
- Pulsating rune circle
- Solid black background
- TOP-DOWN VIEW

CONTENT - RUNE PRISON WARNING:
8 frames showing rune trap forming:
- Frame 1-2: Faint rune circle appearing
- Frame 3-4: Runes becoming visible, glowing
- Frame 5-6: Full runic cage forming (bars of light)
- Frame 7-8: Prison complete, pulsing dangerously

Features:
- Golden rune color (#FFD700)
- Geometric rune symbols
- Cage/prison bar effect
- Ancient magical aesthetic

OUTPUT: Single PNG file, 256x128 pixels, named "telegraph_rune_prison_spritesheet.png"
```

---

## CATEGORÍA 5: AURAS Y BUFFS
**Carpeta destino:** `assets/vfx/abilities/auras/`
**Tamaño:** 128x128px
**Formato:** Spritesheet 4x2 (8 frames loop)

---

### PROMPT 5.1: Aura de Élite (Golden Glow)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Powerful, elite enemy aura
- Pulsating golden glow
- Goes UNDER the enemy sprite
- Solid black background
- TOP-DOWN VIEW

CONTENT - ELITE AURA (placed beneath elite enemies):
8 frames looping animation:
- Subtle pulsing golden glow
- Slight rotation of outer ring
- Inner circle stays centered
- Particles occasionally floating up

Features:
- Primary: #FFD700 (gold)
- Secondary: #FFF8DC (light cream)
- Soft edges, no harsh lines
- Semi-transparent (enemy shows through)
- Subtle but noticeable

OUTPUT: Single PNG file, 512x256 pixels, named "aura_elite_floor_spritesheet.png"
```

---

### PROMPT 5.2: Aura de Daño (Damage Aura - Corazón del Vacío)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Damaging void aura
- Dark, ominous pulsing
- Goes AROUND the enemy
- Solid black background
- TOP-DOWN VIEW

CONTENT - DAMAGE AURA (hurts player on contact):
8 frames looping animation:
- Dark purple energy pulsing outward
- Void tendrils occasionally reaching out
- Center hollow (enemy goes here)
- Particles being sucked inward

Features:
- Primary: #330033 (void dark)
- Secondary: #660066 (purple glow)
- Accent: #990099 (bright edges when pulsing)
- Threatening but cute aesthetic
- Clear danger indication

OUTPUT: Single PNG file, 512x256 pixels, named "aura_damage_void_spritesheet.png"
```

---

### PROMPT 5.3: Aura de Enrage (Minotauro Fury Mode)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Angry, enraged state aura
- Red pulsating flames
- Intense and threatening
- Solid black background
- TOP-DOWN VIEW

CONTENT - ENRAGE AURA (boss is angry, +50% damage, +30% speed):
8 frames looping animation:
- Intense red flames surrounding the character
- Flames flicker and pulse aggressively
- Small lightning/anger marks appearing
- Steam/smoke rising

Features:
- Primary: #FF2200 (angry red)
- Secondary: #FF6600 (orange flames)
- Accent: #FFFF00 (yellow hot spots)
- Very visible "this enemy is MAD" effect
- Fast pulsing animation

OUTPUT: Single PNG file, 512x256 pixels, named "aura_enrage_spritesheet.png"
```

---

### PROMPT 5.4: Buff de Aliados (Corruptor Alado)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 256x128 pixels (4 columns x 2 rows, each cell 64x64 pixels).

STYLE REQUIREMENTS:
- Supportive buff effect
- Goes on buffed enemies
- Green corruption theme
- Solid black background
- TOP-DOWN VIEW

CONTENT - ALLY BUFF AURA (+25% damage, +15% speed):
8 frames looping animation:
- Subtle green glow around the buffed enemy
- Small corruption symbols floating
- Gentle pulsing effect
- Wings or corruption marks occasionally appearing

Features:
- Primary: #4DCC33 (corruption green)
- Secondary: #99FF66 (bright green)
- Softer, less intense than damage auras
- Shows "this enemy is being boosted"

OUTPUT: Single PNG file, 256x128 pixels, named "aura_buff_corruption_spritesheet.png"
```

---

## CATEGORÍA 6: HABILIDADES ESPECÍFICAS DE BOSSES
**Carpeta destino:** `assets/vfx/abilities/boss_specific/{boss_name}/`

---

### PROMPT 6.1: Void Pull (Corazón del Vacío)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 1024x512 pixels (4 columns x 2 rows, each cell 256x256 pixels).

STYLE REQUIREMENTS:
- Massive void pull/suction effect
- Spiraling inward motion
- Covers large area (radius 450px in-game)
- Solid black background
- TOP-DOWN VIEW

CONTENT - VOID PULL (sucks player toward boss):
Row 1 (Start + Pull frames 1-4):
- Frame 1: Void spiral starting to form
- Frame 2: Spiral intensifying, pulling particles inward
- Frame 3: Full spiral active, strong pull (loop start)
- Frame 4: Spiral at maximum, particles rushing to center (loop)

Row 2 (Pull + End frames 5-8):
- Frame 5: Pull continuing, distortion visible (loop)
- Frame 6: Pull still active (loop end)
- Frame 7: Spiral weakening, particles slowing
- Frame 8: Effect ending, final wisps

Features:
- Void colors (#330033, #660066, #990099)
- Clear INWARD spiral motion
- Speed lines pointing to center
- Very large effect

OUTPUT: Single PNG file, 1024x512 pixels, named "boss_void_pull_spritesheet.png"
```

---

### PROMPT 6.2: Rune Shield (El Guardián de Runas)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Protective rune barrier
- Hexagonal/geometric shape
- Golden rune magic
- Solid black background
- Can overlay on boss

CONTENT - RUNE SHIELD (absorbs 4-5 hits):
Row 1 (Appear + Active frames 1-4):
- Frame 1: Runes appearing, connecting to form hexagon
- Frame 2: Shield forming, golden glow
- Frame 3: Full shield active (loop start)
- Frame 4: Shield pulsing, runes rotating (loop)

Row 2 (Active + Break frames 5-8):
- Frame 5: Shield still strong (loop)
- Frame 6: Shield flickering slightly (loop end / hit taken)
- Frame 7: Shield cracking, losing integrity
- Frame 8: Shield shattering into rune fragments

Features:
- Golden colors (#FFD700, #FFF8DC)
- Hexagonal shape with runes at vertices
- Visible "charges" (small orbs or marks showing remaining hits)
- Satisfying break animation

OUTPUT: Single PNG file, 512x256 pixels, named "boss_rune_shield_spritesheet.png"
```

---

### PROMPT 6.3: Summon Circle (El Conjurador Primigenio)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Magical summoning circle
- Arcane purple magic
- Where minions appear from
- Solid black background
- TOP-DOWN VIEW

CONTENT - SUMMON CIRCLE (spawns enemy minions):
Row 1 (Form + Summon frames 1-4):
- Frame 1: Circle lines appearing on ground
- Frame 2: Runes lighting up around the circle
- Frame 3: Portal opening in center (swirling)
- Frame 4: Energy rising from portal (summoning!)

Row 2 (Summon + Close frames 5-8):
- Frame 5: Minion silhouette rising (just shadow shape)
- Frame 6: Full summoning energy burst
- Frame 7: Portal closing, energy receding
- Frame 8: Circle fading, final sparkles

Features:
- Arcane colors (#B34DFF, #FF66CC)
- Pentacle or complex magic circle design
- Rising energy effect in center
- Mystical, magical feeling

OUTPUT: Single PNG file, 512x256 pixels, named "boss_summon_circle_spritesheet.png"
```

---

### PROMPT 6.4: Reality Tear (Corazón del Vacío - Persistent Zone)

```
Create a sprite sheet for a cartoon/funko pop style game. The sheet should be 512x256 pixels (4 columns x 2 rows, each cell 128x128 pixels).

STYLE REQUIREMENTS:
- Dimensional tear/rift effect
- Persists on ground dealing damage
- Void/dark energy
- Solid black background
- TOP-DOWN VIEW

CONTENT - REALITY TEAR (DPS zone, 7 seconds):
Row 1 (Appear + Active frames 1-4):
- Frame 1: Crack in reality appearing
- Frame 2: Tear widening, void energy leaking
- Frame 3: Full tear open (loop start)
- Frame 4: Void energy pulsing from tear (loop)

Row 2 (Active + Close frames 5-8):
- Frame 5: Tear still open, dangerous (loop)
- Frame 6: Void energy fluctuating (loop end)
- Frame 7: Tear starting to seal
- Frame 8: Reality healing, final wisps

Features:
- Void colors with reality-bending distortion
- Jagged tear shape (not a clean circle)
- Particles being pulled into the tear
- Very dangerous looking

OUTPUT: Single PNG file, 512x256 pixels, named "boss_reality_tear_spritesheet.png"
```

---

## CATEGORÍA 7: IMPACTOS
**Carpeta destino:** `assets/vfx/abilities/impacts/{elemento}/`
**Tamaño:** 64x64px
**Formato:** Spritesheet 4x1 (4 frames, plays once)

---

### PROMPT 7.1: Impactos Elementales (Batch de 6)

```
Create 6 separate sprite sheets for impact effects. Each sheet is 256x64 pixels (4 columns x 1 row, each cell 64x64 pixels).

STYLE REQUIREMENTS (all):
- Quick impact burst effect
- Cartoon/funko pop style
- 4 frames: initial hit → burst → dissipate → fade
- Solid black background

CREATE THESE 6 IMPACT SHEETS:

1. FIRE IMPACT - "impact_fire_spritesheet.png"
- Colors: #FF6611, #FFCC00
- Flame burst with sparks
- Frames: spark → fire burst → flames spread → embers fade

2. ICE IMPACT - "impact_ice_spritesheet.png"
- Colors: #66CCFF, #FFFFFF
- Crystal shatter effect
- Frames: crack → crystals burst → shards fly → frost fade

3. ARCANE IMPACT - "impact_arcane_spritesheet.png"
- Colors: #B34DFF, #FF66CC
- Magical burst with runes
- Frames: flash → rune circle → energy disperse → sparkles fade

4. VOID IMPACT - "impact_void_spritesheet.png"
- Colors: #330033, #660066, #990099
- Dark implosion effect
- Frames: dark flash → void burst → tendrils → wisps fade

5. POISON IMPACT - "impact_poison_spritesheet.png"
- Colors: #4DCC33, #99FF66
- Toxic splash effect
- Frames: splat → bubbles burst → toxic mist → fumes fade

6. LIGHTNING IMPACT - "impact_lightning_spritesheet.png"
- Colors: #FFFF4D, #FFFFFF
- Electric burst effect
- Frames: flash → electric arcs → sparks → static fade

OUTPUT: 6 separate PNG files, each 256x64 pixels
```

---

## 📁 ESTRUCTURA DE CARPETAS FINAL

```
assets/vfx/abilities/
├── projectiles/
│   ├── fire/
│   │   └── projectile_fire_spritesheet.png
│   ├── ice/
│   │   └── projectile_ice_spritesheet.png
│   ├── arcane/
│   │   └── projectile_arcane_spritesheet.png
│   ├── void/
│   │   ├── projectile_void_spritesheet.png
│   │   └── projectile_void_homing_spritesheet.png
│   ├── poison/
│   │   └── projectile_poison_spritesheet.png
│   └── lightning/
│       └── (usar impact como referencia)
│
├── aoe/
│   ├── fire/
│   │   ├── aoe_fire_stomp_spritesheet.png
│   │   ├── aoe_fire_zone_spritesheet.png
│   │   └── aoe_meteor_impact_spritesheet.png
│   ├── ice/
│   │   └── aoe_freeze_zone_spritesheet.png
│   ├── arcane/
│   │   └── aoe_arcane_nova_spritesheet.png
│   ├── void/
│   │   └── aoe_void_explosion_spritesheet.png
│   ├── earth/
│   │   └── aoe_ground_slam_spritesheet.png
│   └── rune/
│       └── aoe_rune_blast_spritesheet.png
│
├── beams/
│   ├── beam_flame_breath_spritesheet.png
│   └── beam_void_beam_spritesheet.png
│
├── telegraphs/
│   ├── telegraph_circle_warning_spritesheet.png
│   ├── telegraph_charge_line_spritesheet.png
│   ├── telegraph_meteor_warning_spritesheet.png
│   └── telegraph_rune_prison_spritesheet.png
│
├── impacts/
│   ├── fire/
│   │   └── impact_fire_spritesheet.png
│   ├── ice/
│   │   └── impact_ice_spritesheet.png
│   ├── arcane/
│   │   └── impact_arcane_spritesheet.png
│   ├── void/
│   │   └── impact_void_spritesheet.png
│   ├── poison/
│   │   └── impact_poison_spritesheet.png
│   └── lightning/
│       └── impact_lightning_spritesheet.png
│
├── auras/
│   ├── aura_elite_floor_spritesheet.png
│   ├── aura_damage_void_spritesheet.png
│   ├── aura_enrage_spritesheet.png
│   └── aura_buff_corruption_spritesheet.png
│
└── boss_specific/
    ├── conjurador/
    │   └── boss_summon_circle_spritesheet.png
    ├── corazon_vacio/
    │   ├── boss_void_pull_spritesheet.png
    │   └── boss_reality_tear_spritesheet.png
    ├── guardian_runas/
    │   └── boss_rune_shield_spritesheet.png
    └── minotauro/
        └── (usa aoe_fire_stomp, aura_enrage, beam_flame_breath)
```

---

## 📋 CHECKLIST DE ASSETS (25 archivos)

| # | Archivo | Tamaño | Categoría |
|---|---------|--------|-----------|
| 1 | projectile_fire_spritesheet.png | 256x128 | Proyectiles |
| 2 | projectile_ice_spritesheet.png | 256x128 | Proyectiles |
| 3 | projectile_arcane_spritesheet.png | 256x128 | Proyectiles |
| 4 | projectile_void_spritesheet.png | 256x128 | Proyectiles |
| 5 | projectile_poison_spritesheet.png | 256x128 | Proyectiles |
| 6 | projectile_void_homing_spritesheet.png | 256x128 | Proyectiles |
| 7 | aoe_fire_stomp_spritesheet.png | 512x256 | AOE |
| 8 | aoe_fire_zone_spritesheet.png | 1024x512 | AOE |
| 9 | aoe_freeze_zone_spritesheet.png | 1024x512 | AOE |
| 10 | aoe_arcane_nova_spritesheet.png | 1024x512 | AOE |
| 11 | aoe_void_explosion_spritesheet.png | 1024x512 | AOE |
| 12 | aoe_rune_blast_spritesheet.png | 512x256 | AOE |
| 13 | aoe_ground_slam_spritesheet.png | 512x256 | AOE |
| 14 | aoe_meteor_impact_spritesheet.png | 512x256 | AOE |
| 15 | beam_flame_breath_spritesheet.png | 256x256 | Beams |
| 16 | beam_void_beam_spritesheet.png | 512x64 | Beams |
| 17 | telegraph_circle_warning_spritesheet.png | 256x128 | Telegraphs |
| 18 | telegraph_charge_line_spritesheet.png | 256x128 | Telegraphs |
| 19 | telegraph_meteor_warning_spritesheet.png | 256x128 | Telegraphs |
| 20 | telegraph_rune_prison_spritesheet.png | 256x128 | Telegraphs |
| 21 | aura_elite_floor_spritesheet.png | 512x256 | Auras |
| 22 | aura_damage_void_spritesheet.png | 512x256 | Auras |
| 23 | aura_enrage_spritesheet.png | 512x256 | Auras |
| 24 | aura_buff_corruption_spritesheet.png | 256x128 | Auras |
| 25 | boss_summon_circle_spritesheet.png | 512x256 | Boss |
| 26 | boss_void_pull_spritesheet.png | 1024x512 | Boss |
| 27 | boss_reality_tear_spritesheet.png | 512x256 | Boss |
| 28 | boss_rune_shield_spritesheet.png | 512x256 | Boss |
| 29 | impact_fire_spritesheet.png | 256x64 | Impacts |
| 30 | impact_ice_spritesheet.png | 256x64 | Impacts |
| 31 | impact_arcane_spritesheet.png | 256x64 | Impacts |
| 32 | impact_void_spritesheet.png | 256x64 | Impacts |
| 33 | impact_poison_spritesheet.png | 256x64 | Impacts |
| 34 | impact_lightning_spritesheet.png | 256x64 | Impacts |

---

*Documento generado el 4 de febrero de 2026*
*Total de prompts: 20*
*Total de assets a generar: 34 archivos*
