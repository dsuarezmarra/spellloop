# ?? Prompts para Animaciones del DRUID

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

## ?? GUÍA DE ESTILO - DRUID

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Mujer madura |
| **Complexión** | Curvilínea, maternal |
| **Cabello** | Largo castaño con hojas y flores entrelazadas |
| **Expresión** | Amable, serena, ojos verdes brillantes |
| **Vestimenta** | Túnica verde/marrón natural, con enredaderas vivas |
| **Detalles** | Pequeñas flores brotan de su ropa, hojas flotando |
| **Arma** | Bastón de madera viva con hojas brotando |

### Paleta de colores:
- **Túnica principal:** Verde bosque (#228B22)
- **Túnica sombras:** Verde oscuro (#006400)
- **Acentos marrón:** Marrón corteza (#8B4513)
- **Hojas/Detalles:** Verde lima (#32CD32) y dorado otoñal (#DAA520)
- **Flores:** Rosa suave (#FFB6C1) y blanco (#FFFFFF)
- **Cabello:** Castaño cálido (#8B6914)
- **Piel:** Bronceada cálida (#D4A574)
- **Staff madera:** Marrón vivo (#5D4037)
- **Outline:** Marrón muy oscuro (#2D1B0E)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Druid - Mature Female, Nature Guardian

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big warm green eyes
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Mature woman with kind, motherly appearance
- Curvy, grounded build
- Long wavy brown hair with leaves and small flowers woven in
- Serene, gentle smile
- Bright green eyes with nature glow
- Green and brown natural fabric robe, mid-length
- Living vines wrapped around arms and robe
- Small flowers blooming on her clothing
- Wooden staff with living branches and leaves sprouting from top
- Barefoot or natural sandals
- Few floating leaves around her

COLOR PALETTE:
- Robe: Forest green (#228B22) with dark shadows (#006400)
- Brown accents: Bark brown (#8B4513)
- Leaves: Lime green (#32CD32) and golden autumn (#DAA520)
- Flowers: Soft pink (#FFB6C1) and white
- Hair: Warm brown (#8B6914)
- Skin: Warm tan (#D4A574)
- Staff: Living wood brown (#5D4037)
- Outline: Very dark brown (#2D1B0E)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `druid_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading, nature theme

CHARACTER: Mature female druid, brown hair with flowers, green robe, living wood staff

?? 3-FRAME WALK CYCLE (BINDING OF ISAAC STYLE):
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, right leg straight, slight body tilt left
- Frame 2: NEUTRAL - Both legs together, standing straight, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, left leg straight, slight body tilt right

ANIMATION NOTES:
- This creates a waddling/bouncy walk when played as: 1-2-3-2-1-2-3...
- Each frame should be CLEARLY DIFFERENT - exaggerate the leg positions
- Barefoot/sandals should be visible moving
- Grounded, connected-to-earth movement style

SECONDARY MOTION:
- Flowers on robe gently bobbing
- Leaves floating around her following movement
- Staff leaves rustling
- Hair with flower accessories swaying

COLORS: Robe #228B22, Hair #8B6914, Skin #D4A574, Staff #5D4037

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading, nature elements

CHARACTER (from behind): Female druid, long brown hair with leaves/flowers, green robe, wooden staff

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward (visible from behind), body tilts slightly
- Frame 2: NEUTRAL - Both legs together, standing straight
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, body tilts opposite

ANIMATION NOTES:
- Mirror the front walk cycle but from behind
- Visible leg movement through robe
- Keep the same bouncy feel as front view

SECONDARY MOTION:
- Long hair swaying side to side
- Flowers in hair bobbing
- Floating leaves trailing behind
- Staff held in right hand

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading, nature elements

CHARACTER (right profile): Female druid, hair flowing behind, staff in leading hand

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg stretched back, front leg under body, leaning forward into walk
- Frame 2: NEUTRAL - Both legs together under body, upright stance
- Frame 3: FRONT LEG EXTENDED - Front leg stretched forward, rear leg under body, leaning forward

ANIMATION NOTES:
- Side view shows the forward/backward leg motion
- Character leans slightly into movement direction
- This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Hair and flowers flow behind
- Leaves trail in wake
- Robe sways with walking rhythm
- Staff moves with arm swing

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, magical nature effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raising staff, leaves swirling upward, flowers on robe blooming brighter
- Frame 2: CHANNEL - Staff glowing green, nature energy spiraling, eyes glowing, more leaves materializing
- Frame 3: RELEASE - Staff thrust forward, burst of green energy and petals, magical seeds/orbs launching
- Frame 4: RECOVERY - Lowering staff, petals falling gently, serene satisfied expression

EFFECTS:
- Frame 1: Leaves gathering
- Frame 2: Green magical spiral, glowing
- Frame 3: Burst of nature energy, petals explosion
- Frame 4: Settling petals and leaves

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, nature wilting effect

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, shocked expression, flowers wilting
- Frame 2: STAGGER - Stumbling, leaves falling dead, staff dimming
- Frame 3: COLLAPSE - Falling, all greenery turning brown/dying
- Frame 4: FALLEN - On ground, desaturated colors, wilted flowers around body

EFFECTS:
- Frame 1: Impact, flowers shocked
- Frame 2: Nature elements dying
- Frame 3: Last leaves falling
- Frame 4: Slight transparency (80% opacity), peaceful expression

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

ANIMATION:
- Frame 1: IMPACT - Flinching backward, pained expression, flowers disrupted, red damage flash
- Frame 2: RECOVERY - Returning to stance, determined expression, nature stabilizing

EFFECTS:
- Frame 1: Red tint overlay, leaves scattering
- Frame 2: Normal colors returning, nature calming

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, gentle nature movement

ANIMATION:
- Frame 1: INHALE - Slight chest expansion, flowers opening, leaves rising
- Frame 2: EXHALE - Relaxed, flowers gently closing, leaves settling

EFFECTS:
- Gentle floating leaves
- Flowers subtly blooming
- Peaceful expression

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `druid_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `druid_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `druid_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `druid_cast_strip.png` |
| Death | 4 | 2000x500 | `druid_death_strip.png` |
| Hit | 2 | 1000x500 | `druid_hit_strip.png` |
| Idle | 2 | 1000x500 | `druid_idle_strip.png` |

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
project/assets/sprites/players/druid/
??? walk/
?   ??? druid_walk_down_1.png - druid_walk_down_3.png
?   ??? druid_walk_up_1.png - druid_walk_up_3.png
?   ??? druid_walk_right_1.png - druid_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
