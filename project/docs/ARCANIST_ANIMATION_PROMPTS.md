# ?? Prompts para Animaciones del ARCANIST

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #7** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? SISTEMA DE ANIMACIÓN DE CAMINAR (Estilo Binding of Isaac)

**Este juego usa un ciclo de caminata de 3 frames en ping-pong:**

### Ciclo de animación:
```
Frame 1 ? Frame 2 ? Frame 3 ? Frame 2 ? Frame 1 ? ...
```

### Descripción de cada frame:

| Frame | Walk Down/Up (vista frontal/trasera) | Walk Right (vista lateral) |
|-------|--------------------------------------|----------------------------|
| **1** | Pierna IZQUIERDA hacia afuera | Pierna TRASERA atrás, inclinado hacia adelante |
| **2** | Piernas JUNTAS (posición neutral) | Piernas JUNTAS (posición neutral) |
| **3** | Pierna DERECHA hacia afuera | Pierna DELANTERA adelante, inclinado hacia adelante |

### ?? IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- Solo se necesitan **3 sprites por dirección**: Down, Up y Right
- Total walk sprites: **9 frames** (3 direcciones × 3 frames)

---

## ?? GUÍA DE ESTILO - ARCANIST

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre mayor, sabio |
| **Complexión** | Delgada pero imponente |
| **Cabello** | Calvo con barba larga blanca, runas brillando en la piel |
| **Expresión** | Sereno, sabio, ojos brillantes arcanos |
| **Túnica** | Larga púrpura real con runas flotantes, capa amplia |
| **Detalles** | Orbes arcanos orbitando a su alrededor (2-3), símbolos mágicos |
| **Arma** | Orbe arcano flotante entre sus manos, bastón ceremonial |

### Paleta de colores:
- **Túnica principal:** Púrpura real (#5B2C6F)
- **Túnica sombras:** Púrpura oscuro (#2E1A47)
- **Runas/Orbes:** Cyan brillante (#00FFFF) y magenta (#FF00FF)
- **Detalles dorados:** Oro antiguo (#CFB53B)
- **Barba:** Blanco plateado (#E8E8E8)
- **Piel:** Pálida con tinte púrpura (#D4C4D4)
- **Orbe central:** Cyan con núcleo blanco (#00E5E5)
- **Outline:** Púrpura muy oscuro (#1A0A28)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Arcanist - Elderly Male, Arcane Scholar

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big wise eyes with arcane glow
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Elderly wise man, dignified posture
- Bald head with glowing arcane runes on scalp
- Long flowing white beard reaching chest
- Serene, knowing expression
- Long royal purple robe reaching the floor
- Wide sleeves with floating runic symbols
- 2-3 small arcane orbs orbiting around him
- Holds a glowing cyan orb between hands or ceremonial staff
- Golden trim and mystical patterns on robe

COLOR PALETTE:
- Robe: Royal purple (#5B2C6F) with dark shadows (#2E1A47)
- Runes/Orbs: Cyan (#00FFFF) and magenta (#FF00FF)
- Gold accents: Antique gold (#CFB53B)
- Beard: Silver white (#E8E8E8)
- Skin: Pale with purple tint (#D4C4D4)
- Orb: Cyan with white core (#00E5E5)
- Outline: Very dark purple (#1A0A28)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `arcanist_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Elderly male arcane wizard, bald with runes on head, white beard, purple robe, floating orbs around him

?? 3-FRAME WALK CYCLE (BINDING OF ISAAC STYLE):
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, right leg straight, slight body tilt left
- Frame 2: NEUTRAL - Both legs together, standing straight, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, left leg straight, slight body tilt right

ANIMATION NOTES:
- This creates a waddling/bouncy walk when played as: 1-2-3-2-1-2-3...
- Each frame should be CLEARLY DIFFERENT - exaggerate the leg positions
- Long robe should reveal leg motion at hem
- Orbs continue orbiting throughout

SECONDARY MOTION:
- Orbiting arcane orbs continue circular motion through all frames
- Beard sways gently with movement
- Runic symbols pulse subtly
- Robe hem reveals foot steps

COLORS: Robe #5B2C6F, Orbs #00FFFF/#FF00FF, Beard #E8E8E8

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Elderly wizard, bald head with runes, long white beard tips visible, purple flowing robe

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward (visible from behind), body tilts slightly
- Frame 2: NEUTRAL - Both legs together, standing straight
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, body tilts opposite

ANIMATION NOTES:
- Mirror the front walk cycle but from behind
- Robe should sway revealing walking motion underneath
- Orbs continue orbiting (visible from behind)

SECONDARY MOTION:
- Orbs continue orbiting
- Robe flows with each step
- Glowing runes on bald head visible from back

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Elderly wizard, beard profile, purple robe, orbs orbiting

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg stretched back, front leg under body, leaning forward into walk
- Frame 2: NEUTRAL - Both legs together under body, upright stance
- Frame 3: FRONT LEG EXTENDED - Front leg stretched forward, rear leg under body, leaning forward

ANIMATION NOTES:
- Side view shows the forward/backward leg motion
- Character leans slightly into movement direction
- This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Beard flows with movement
- Orbs trail behind slightly then catch up
- Robe billows with motion

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, heavy magical effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raises hands, all orbs converging to center, gathering energy
- Frame 2: CHANNEL - Orbs merge into one large orb, runic circles appearing around him, eyes glowing
- Frame 3: RELEASE - Massive arcane blast from merged orb, runic explosion, bright flash
- Frame 4: RECOVERY - Orbs separating back to orbit, residual magic fading, serene expression

EFFECTS:
- Frame 1: Orbs pulling together, growing brighter
- Frame 2: Giant unified orb, magic circles, intense glow
- Frame 3: Explosion of cyan/magenta energy, motion lines
- Frame 4: Orbs returning to normal orbit, sparkles fading

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, magic fading

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, surprised, orbs flickering
- Frame 2: STAGGER - Stumbling, orbs spinning erratically, runes dimming
- Frame 3: COLLAPSE - Falling, orbs scattering and fading
- Frame 4: FALLEN - On ground, all orbs gone, runes dark, desaturated

EFFECTS:
- Frame 1: Orbs disrupted
- Frame 2: Magic destabilizing
- Frame 3: Orbs dispersing into particles
- Frame 4: Slight transparency (80% opacity), peaceful

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

ANIMATION:
- Frame 1: IMPACT - Flinching backward, orbs disrupted, red damage flash
- Frame 2: RECOVERY - Returning to stance, orbs stabilizing, ready to continue

EFFECTS:
- Frame 1: Red tint overlay, orbs scattered
- Frame 2: Normal colors returning, orbs realigning

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, subtle arcane movement

ANIMATION:
- Frame 1: INHALE - Slight chest expansion, orbs glowing brighter, runes pulsing
- Frame 2: EXHALE - Relaxed, orbs dim slightly, calm

EFFECTS:
- Orbs slowly orbiting
- Runes gentle pulse
- Serene floating feeling

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `arcanist_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `arcanist_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `arcanist_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `arcanist_cast_strip.png` |
| Death | 4 | 2000x500 | `arcanist_death_strip.png` |
| Hit | 2 | 1000x500 | `arcanist_hit_strip.png` |
| Idle | 2 | 1000x500 | `arcanist_idle_strip.png` |

**Total: 21 frames**

---

## ?? Implementación en Godot

### Ciclo de animación Walk (ping-pong):
```gdscript
# Frames: 0, 1, 2, 1, 0, 1, 2, 1, 0...
# Usar animation con loop mode "Ping-Pong"
```

### Walk Left:
```gdscript
sprite.flip_h = true  # cuando dirección es LEFT
sprite.flip_h = false # cuando dirección es RIGHT
```

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/arcanist/
??? walk/
?   ??? arcanist_walk_down_1.png - arcanist_walk_down_3.png
?   ??? arcanist_walk_up_1.png - arcanist_walk_up_3.png
?   ??? arcanist_walk_right_1.png - arcanist_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
