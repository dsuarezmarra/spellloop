# ? Prompts para Animaciones del STORM CALLER

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

## ?? GUÍA DE ESTILO - STORM CALLER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Mujer joven |
| **Complexión** | Atlética, ágil |
| **Cabello** | Largo, azul eléctrico con destellos blancos, flotando como electricidad estática |
| **Expresión** | Intensa, ojos brillantes con chispas |
| **Túnica** | Azul oscuro/púrpura tormenta, corta (sobre rodillas), con patrones de rayos |
| **Detalles** | Chispas eléctricas alrededor del cuerpo, arcos de electricidad entre dedos |
| **Arma** | Bastón metálico con punta conductora, chispas constantes |

### Paleta de colores:
- **Túnica principal:** Azul tormenta (#1E3A5F)
- **Túnica sombras:** Púrpura oscuro (#2D1B4E)
- **Highlights:** Amarillo eléctrico (#FFE135)
- **Rayos/Electricidad:** Blanco-azul brillante (#FFFFFF a #00D4FF)
- **Cabello:** Azul eléctrico (#00A8FF) con mechas blancas
- **Piel:** Clara con tono azulado (#E8DED5)
- **Staff metal:** Plateado (#C0C0C0)
- **Outline:** Azul muy oscuro (#0A1628)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Storm Caller - Young Adult Female, Lightning Mage

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big expressive eyes with electric spark reflections
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels
- Bold saturated colors

DESIGN DETAILS:
- Young woman with athletic build
- Long flowing electric blue hair with white streaks, defying gravity (static electricity)
- Intense expression, confident smirk
- Eyes glow faintly yellow
- Dark blue/purple storm-colored short robe (above knees)
- Lightning bolt patterns on robe trim
- Silver metallic staff with conductive tip, constant small sparks
- Small electric arcs dancing around her body
- Bare arms showing from robe sleeves

COLOR PALETTE:
- Robe: Storm blue (#1E3A5F) with purple shadows (#2D1B4E)
- Lightning/Highlights: Electric yellow (#FFE135)
- Hair: Electric blue (#00A8FF) with white streaks
- Skin: Light with blue tint (#E8DED5)
- Staff: Silver (#C0C0C0) with cyan sparks (#00D4FF)
- Outline: Very dark blue (#0A1628)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `storm_caller_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Female lightning mage, blue hair with white streaks floating upward, storm blue robe, silver lightning staff

? 3-FRAME WALK CYCLE (BINDING OF ISAAC STYLE):
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, right leg straight, slight body tilt left
- Frame 2: NEUTRAL - Both legs together, standing straight, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, left leg straight, slight body tilt right

ANIMATION NOTES:
- This creates a waddling/bouncy walk when played as: 1-2-3-2-1-2-3...
- Each frame should be CLEARLY DIFFERENT - exaggerate the leg positions
- Keep upper body relatively stable, movement is in the legs
- Robe sways with leg movement

SECONDARY MOTION:
- Hair floats with static electricity
- Small lightning arcs between hair strands
- Staff sparks gently

COLORS: Robe #1E3A5F, Hair #00A8FF, Sparks #FFE135, Skin #E8DED5

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER (from behind): Female lightning mage, long blue hair flowing down back with white streaks, storm blue robe, silver staff

? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward (visible from behind), body tilts slightly
- Frame 2: NEUTRAL - Both legs together, standing straight
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, body tilts opposite

ANIMATION NOTES:
- Mirror the front walk cycle but from behind
- Legs should be clearly visible below robe hem
- Keep the same bouncy feel as front view

SECONDARY MOTION:
- Hair sways side to side with walking rhythm
- Robe hem moves with leg motion
- Electric sparks trail from staff tip

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Female lightning mage, hair trailing behind, storm robe, staff visible

? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg stretched back, front leg under body, leaning forward into walk
- Frame 2: NEUTRAL - Both legs together under body, upright stance
- Frame 3: FRONT LEG EXTENDED - Front leg stretched forward, rear leg under body, leaning forward

ANIMATION NOTES:
- Side view shows the forward/backward leg motion
- Character leans slightly into movement direction
- This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Hair flows behind due to movement
- Robe trails with motion
- Electric trail behind staff

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, dramatic lightning effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Staff raised, electricity gathering at tip, hair rising more
- Frame 2: CHANNEL - Eyes glowing bright yellow, lightning arcing around body, storm clouds forming above
- Frame 3: RELEASE - Staff thrust forward, massive lightning bolt launching, bright flash, hair fully standing
- Frame 4: RECOVERY - Lowering staff, residual sparks dissipating, satisfied expression

EFFECTS:
- Frame 1: Yellow sparkles gathering
- Frame 2: Electric arcs surrounding body, glowing eyes
- Frame 3: Bright lightning bolt from staff, motion blur, light explosion
- Frame 4: Fading sparks, small residual arcs

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, colors desaturating progressively

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, shocked expression, electricity sputtering
- Frame 2: STAGGER - Stumbling, staff loosening, sparks dying out, hair falling
- Frame 3: COLLAPSE - Falling forward, all electricity fading, hair limp
- Frame 4: FALLEN - On ground, desaturated colors, staff beside body, no sparks

EFFECTS:
- Frame 1: Disrupted electricity, flash of light
- Frame 2: Sparks sputtering and dying
- Frame 3: Last traces of glow fading
- Frame 4: No electricity, slight transparency (80% opacity)

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

ANIMATION:
- Frame 1: IMPACT - Flinching backward, pained expression, electricity disrupted, red damage flash
- Frame 2: RECOVERY - Returning to stance, determined expression, electricity stabilizing, ready to fight

EFFECTS:
- Frame 1: Red tint overlay, disrupted sparks
- Frame 2: Normal colors returning, sparks re-forming

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, subtle movement

ANIMATION:
- Frame 1: INHALE - Slight chest expansion, electricity pulsing brighter, hair rising slightly
- Frame 2: EXHALE - Relaxed, electricity dims slightly, hair settles

EFFECTS:
- Constant small electric arcs between hair strands
- Staff tip glows steadily
- Subtle breathing motion

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `storm_caller_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `storm_caller_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `storm_caller_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `storm_caller_cast_strip.png` |
| Death | 4 | 2000x500 | `storm_caller_death_strip.png` |
| Hit | 2 | 1000x500 | `storm_caller_hit_strip.png` |
| Idle | 2 | 1000x500 | `storm_caller_idle_strip.png` |

**Total: 21 frames** (antes eran 28 con 4 frames de walk × 4 direcciones)

---

## ?? Implementación en Godot

### Ciclo de animación Walk (ping-pong):
```gdscript
# En AnimationPlayer o código:
# Frames: 0, 1, 2, 1, 0, 1, 2, 1, 0...
# Usar animation con loop mode "Ping-Pong"
```

### Walk Left:
```gdscript
# Voltear sprite_walk_right horizontalmente
sprite.flip_h = true  # cuando dirección es LEFT
sprite.flip_h = false # cuando dirección es RIGHT
```

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/storm_caller/
??? walk/
?   ??? storm_caller_walk_down_1.png
?   ??? storm_caller_walk_down_2.png
?   ??? storm_caller_walk_down_3.png
?   ??? storm_caller_walk_up_1.png
?   ??? storm_caller_walk_up_2.png
?   ??? storm_caller_walk_up_3.png
?   ??? storm_caller_walk_right_1.png
?   ??? storm_caller_walk_right_2.png
?   ??? storm_caller_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
