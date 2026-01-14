# ?? Prompts para Animaciones del PYROMANCER (Fire Mage)

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

## ?? GUÍA DE ESTILO - PYROMANCER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre joven adulto |
| **Complexión** | Atlético, musculoso pero ágil |
| **Cabello** | Corto, negro azabache con reflejos rojizos, peinado hacia atrás |
| **Expresión** | Confiado, determinado, intenso |
| **Túnica** | Roja carmesí con capucha (bajada), hasta las rodillas |
| **Detalles** | Runas de fuego en los bordes, pequeñas llamas decorativas |
| **Arma** | Bastón de madera oscura con cristal ámbar incandescente |

### Paleta de colores:
- **Túnica principal:** Rojo carmesí (#C41E3A)
- **Túnica sombras:** Rojo oscuro/borgoña (#8B0000)
- **Túnica highlights:** Naranja brillante (#FF6B35)
- **Detalles dorados:** Oro (#FFD700)
- **Piel:** Bronceada cálida (#D4A574)
- **Cabello:** Negro azabache con reflejos rojizos (#1A0A0A con #4A0A0A)
- **Staff cristal:** Ámbar/Naranja incandescente (#FF8C00)
- **Staff madera:** Madera oscura quemada (#3D2314)
- **Llamas decorativas:** Gradiente naranja-amarillo (#FF4500 a #FFD700)
- **Outline:** Negro rojizo muy oscuro (#1A0A0A)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Fire Mage / Pyromancer - Young Adult Male

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big expressive eyes with fire reflection highlights
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels
- Bold saturated warm colors

DESIGN DETAILS:
- Young adult male with athletic build
- Short swept-back dark hair with subtle red highlights
- Determined expression, slight smirk
- Crimson red hooded robe reaching to knees (shorter than wizard's)
- Hood down, showing face and hair
- Golden trim and fire rune patterns on robe edges
- Ornate dark wood staff with glowing amber crystal tip
- Small decorative flames flickering at robe hem
- Staff held confidently in right hand
- Tanned/bronze skin tone

COLOR PALETTE:
- Robe: Crimson red (#C41E3A) with dark red shadows (#8B0000)
- Robe highlights/trim: Bright orange (#FF6B35)
- Gold accents: (#FFD700)
- Skin: Warm bronze (#D4A574)
- Hair: Black with red tints (#1A0A0A / #4A0A0A)
- Staff crystal: Incandescent amber-orange (#FF8C00)
- Staff wood: Dark burnt wood (#3D2314)
- Flame effects: Orange to yellow gradient (#FF4500 to #FFD700)
- Outline: Very dark red-black (#1A0A0A)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `pyromancer_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading, warm colors

CHARACTER: Young male fire mage, crimson robe, dark hair, amber crystal staff

?? 3-FRAME WALK CYCLE (BINDING OF ISAAC STYLE):
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, right leg straight, slight body tilt left
- Frame 2: NEUTRAL - Both legs together, standing straight, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, left leg straight, slight body tilt right

ANIMATION NOTES:
- This creates a waddling/bouncy walk when played as: 1-2-3-2-1-2-3...
- Each frame should be CLEARLY DIFFERENT - exaggerate the leg positions
- Keep upper body relatively stable, movement is in the legs
- Robe sways with leg movement, flames flicker

SECONDARY MOTION:
- Small flames at robe hem flicker with movement
- Staff crystal glows steadily
- Robe flows with walking motion

COLORS: Robe #C41E3A, Skin #D4A574, Hair #1A0A0A, Crystal #FF8C00, Flames #FF4500

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Male fire mage, crimson robe from back, dark hair, staff visible

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward (visible from behind), body tilts slightly
- Frame 2: NEUTRAL - Both legs together, standing straight
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, body tilts opposite

ANIMATION NOTES:
- Mirror the front walk cycle but from behind
- Legs should be clearly visible below robe hem
- Keep the same bouncy feel as front view

SECONDARY MOTION:
- Robe flows with movement
- Flames at hem trail behind
- Staff visible from behind

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Male fire mage, crimson robe profile, staff in hand

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg stretched back, front leg under body, leaning forward into walk
- Frame 2: NEUTRAL - Both legs together under body, upright stance
- Frame 3: FRONT LEG EXTENDED - Front leg stretched forward, rear leg under body, leaning forward

ANIMATION NOTES:
- Side view shows the forward/backward leg motion
- Character leans slightly into movement direction
- This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Robe trails behind with motion
- Flames flow opposite to movement
- Staff held at side

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, dramatic fire effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Staff raised, crystal beginning to glow orange, small embers forming
- Frame 2: CHANNEL - Both hands on staff, intense amber glow, fire swirling around crystal
- Frame 3: RELEASE - Staff thrust forward, fireball launching, bright flash of orange-yellow
- Frame 4: RECOVERY - Lowering staff, residual flames and embers dispersing, satisfied expression

EFFECTS:
- Frame 1: Orange sparkles and small embers around crystal
- Frame 2: Spiral of fire energy around staff, eyes reflecting flames
- Frame 3: Explosion of orange-yellow fire from crystal tip, motion blur
- Frame 4: Trailing flames, cooling embers, smoke wisps

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, colors desaturating progressively

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling from impact, shocked expression, staff loosening from grip
- Frame 2: STAGGER - Stumbling backward, flames on robe flickering and dying, staff falling
- Frame 3: COLLAPSE - Knees buckling, falling forward, all flames extinguished
- Frame 4: FALLEN - Lying on ground, faded colors, staff beside body, embers turning to ash

EFFECTS:
- Frame 1: Impact flash, flames disrupted
- Frame 2: Flames sputtering out, colors beginning to desaturate
- Frame 3: Last flames dying, motion blur on fall
- Frame 4: Slight transparency (80% opacity), ash particles floating up

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

ANIMATION:
- Frame 1: IMPACT - Flinching backward, eyes squinted in pain, red damage flash overlay, flames disrupted
- Frame 2: RECOVERY - Returning to stance, determined expression, flames stabilizing, ready to fight

EFFECTS:
- Frame 1: Red tint overlay, white impact lines, flames scattered
- Frame 2: Normal colors returning, embers resettling

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, subtle movement

ANIMATION:
- Frame 1: INHALE - Slight chest expansion, staff crystal glowing steadily, flames at hem rising slightly
- Frame 2: EXHALE - Slight chest contraction, flames settle down, relaxed but alert stance

EFFECTS:
- Subtle flame flicker on robe hem
- Crystal glow pulsing gently
- Hair slightly affected by heat shimmer

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `pyromancer_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `pyromancer_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `pyromancer_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `pyromancer_cast_strip.png` |
| Death | 4 | 2000x500 | `pyromancer_death_strip.png` |
| Hit | 2 | 1000x500 | `pyromancer_hit_strip.png` |
| Idle | 2 | 1000x500 | `pyromancer_idle_strip.png` |

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
project/assets/sprites/players/pyromancer/
??? walk/
?   ??? pyromancer_walk_down_1.png - pyromancer_walk_down_3.png
?   ??? pyromancer_walk_up_1.png - pyromancer_walk_up_3.png
?   ??? pyromancer_walk_right_1.png - pyromancer_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
