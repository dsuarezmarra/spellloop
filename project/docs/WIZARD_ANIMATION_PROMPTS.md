# ?? Prompts para Animaciones del WIZARD

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

## ?? GUÍA DE ESTILO - WIZARD

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre anciano |
| **Complexión** | Delgado, encorvado ligeramente |
| **Cabello** | Barba larga blanca/plateada |
| **Expresión** | Amable, sabio, ojos brillantes |
| **Túnica** | Azul púrpura larga hasta los pies, con capucha |
| **Detalles** | Runas mágicas sutiles en la ropa |
| **Arma** | Bastón de madera con cristal cian brillante |

### Paleta de colores:
- **Túnica principal:** Azul profundo (#4A7A9C)
- **Túnica sombras:** Azul oscuro (#3A5A7C)
- **Túnica highlights:** Azul claro (#6A9ABC)
- **Piel:** Beige cálido (#E8D4B8)
- **Barba/Pelo:** Blanco grisáceo (#E0E0E0)
- **Staff cristal:** Cian brillante (#66CCFF)
- **Staff madera:** Marrón (#8B6914)
- **Outline:** Negro/Gris muy oscuro (#1A1A2E)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Fantasy Wizard/Mage - Elderly Male

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big cute expressive eyes with shine highlights
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels
- Bold saturated colors

DESIGN DETAILS:
- Long flowing purple-blue hooded robe reaching to feet
- Large hood partially shadowing face
- Long white/silver beard (stylized, not realistic)
- Kind elderly face with rosy cheeks
- Ornate wooden magical staff with glowing cyan crystal tip
- Staff held in right hand
- Robe has subtle magical rune patterns

COLOR PALETTE:
- Robe: Deep blue (#4A7A9C) with darker shadows (#3A5A7C)
- Skin: Warm beige (#E8D4B8)
- Beard: Light gray-white (#E0E0E0)
- Staff crystal: Bright cyan glow (#66CCFF)
- Staff wood: Warm brown (#8B6914)
- Outline: Very dark blue-black (#1A1A2E)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `wizard_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Elderly wizard, purple-blue robe, white beard, wooden staff with cyan crystal

?? 3-FRAME WALK CYCLE (BINDING OF ISAAC STYLE):
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, right leg straight, slight body tilt left
- Frame 2: NEUTRAL - Both legs together, standing straight, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, left leg straight, slight body tilt right

ANIMATION NOTES:
- This creates a waddling/bouncy walk when played as: 1-2-3-2-1-2-3...
- Each frame should be CLEARLY DIFFERENT - exaggerate the leg positions
- Keep upper body relatively stable, movement is in the legs
- Long robe sways with leg movement, showing feet underneath

SECONDARY MOTION:
- Beard sways gently with movement
- Staff crystal glows steadily
- Robe hem reveals walking feet

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Crystal #66CCFF

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Elderly wizard, purple-blue robe, hood visible, staff in hand

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward (visible from behind), body tilts slightly
- Frame 2: NEUTRAL - Both legs together, standing straight
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, body tilts opposite

ANIMATION NOTES:
- Mirror the front walk cycle but from behind
- Robe should show leg movement underneath
- Keep the same bouncy feel as front view

SECONDARY MOTION:
- Robe flows with movement
- Hood slightly visible from behind
- Beard tips visible from sides

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Elderly wizard, robe profile, beard visible, staff in leading hand

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg stretched back, front leg under body, leaning forward into walk
- Frame 2: NEUTRAL - Both legs together under body, upright stance
- Frame 3: FRONT LEG EXTENDED - Front leg stretched forward, rear leg under body, leaning forward

ANIMATION NOTES:
- Side view shows the forward/backward leg motion
- Character leans slightly into movement direction
- This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Robe flows behind
- Beard trails with movement
- Staff held forward

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, magical effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raising staff upward, magical sparkles beginning to gather at crystal
- Frame 2: CHANNEL - Staff raised high above head, intense magical orb forming at crystal tip, robe flowing upward
- Frame 3: RELEASE - Staff thrust forward releasing spell, bright cyan energy burst, robe blown back dramatically
- Frame 4: RECOVERY - Lowering staff, magical sparkles dissipating, calm expression returning

EFFECTS:
- Frame 1: Cyan sparkles gathering
- Frame 2: Intense orb of energy, robe billowing
- Frame 3: Burst of magical energy, motion lines
- Frame 4: Fading sparkles, settling robes

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, colors desaturating

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, surprised expression, staff loosening
- Frame 2: STAGGER - Stumbling, staff falling, robe deflating
- Frame 3: COLLAPSE - Falling forward, crystal light fading
- Frame 4: FALLEN - On ground, desaturated colors, staff beside body

EFFECTS:
- Frame 1: Impact flash
- Frame 2: Crystal flickering
- Frame 3: Light fading
- Frame 4: Slight transparency (80% opacity)

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

ANIMATION:
- Frame 1: IMPACT - Flinching backward, surprised expression, red damage flash
- Frame 2: RECOVERY - Returning to stance, determined expression, ready to continue

EFFECTS:
- Frame 1: Red tint overlay
- Frame 2: Normal colors returning

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wizard idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, subtle movement

ANIMATION:
- Frame 1: INHALE - Slight chest expansion, crystal glowing brighter, beard rising slightly
- Frame 2: EXHALE - Relaxed, crystal dims slightly, beard settles

EFFECTS:
- Gentle crystal glow pulsing
- Subtle breathing motion
- Beard gentle sway

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `wizard_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `wizard_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `wizard_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `wizard_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `wizard_cast_strip.png` |
| Death | 4 | 2000x500 | `wizard_death_strip.png` |
| Hit | 2 | 1000x500 | `wizard_hit_strip.png` |
| Idle | 2 | 1000x500 | `wizard_idle_strip.png` |

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
project/assets/sprites/players/wizard/
??? walk/
?   ??? wizard_walk_down_1.png - wizard_walk_down_3.png
?   ??? wizard_walk_up_1.png - wizard_walk_up_3.png
?   ??? wizard_walk_right_1.png - wizard_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
