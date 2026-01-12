# ? Prompts para Animaciones del STORM CALLER

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #8** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? NOTA CRÍTICA SOBRE ANIMACIÓN DE CAMINAR

**MUY IMPORTANTE:** Al generar los frames de caminar, es ESENCIAL que:
1. **Los pies se muevan claramente** - Cada frame debe mostrar una posición diferente de las piernas
2. **Transición fluida** - Los 4 frames deben formar un ciclo de caminata natural
3. **No solo mover la ropa** - El personaje debe DAR PASOS visibles, no solo balancearse
4. **Pierna adelante/atrás** - Frame 1: neutral, Frame 2: pierna izquierda adelante, Frame 3: cruzando, Frame 4: pierna derecha adelante

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

## PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Female lightning mage, blue hair with white streaks floating upward, storm blue robe, silver lightning staff

?? CRITICAL WALKING ANIMATION REQUIREMENTS:
- Frame 1: NEUTRAL - Feet together, standing straight
- Frame 2: LEFT STEP - Left foot clearly forward, right foot back, weight shifting
- Frame 3: PASSING - Feet crossing each other mid-stride, body centered
- Frame 4: RIGHT STEP - Right foot clearly forward, left foot back
- LEGS MUST BE VISIBLY DIFFERENT in each frame - show actual walking motion
- Robe sways with movement, electric sparks trail behind

SECONDARY MOTION:
- Hair floats with static electricity, moves opposite to walk direction
- Small lightning arcs between hair strands
- Staff sparks intensify on contact frames

COLORS: Robe #1E3A5F, Hair #00A8FF, Sparks #FFE135, Skin #E8DED5

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking animation - BACK TO CAMERA (walking away)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER (from behind): Female lightning mage, long blue hair flowing down back with white streaks, storm blue robe, silver staff

?? CRITICAL WALKING ANIMATION:
- Frame 1: NEUTRAL - Feet together
- Frame 2: LEFT STEP - Left leg forward (visible from behind), right leg back
- Frame 3: PASSING - Legs crossing mid-stride
- Frame 4: RIGHT STEP - Right leg forward, left back
- SHOW CLEAR LEG MOVEMENT in each frame

SECONDARY MOTION:
- Hair sways side to side with walking rhythm
- Robe hem moves with leg motion
- Electric sparks trail from staff tip

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_up_strip.png`

---

## PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (left profile): Female lightning mage, hair trailing behind, storm robe, staff in right hand

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: NEUTRAL - Standing side profile
- Frame 2: BACK LEG PUSH - Rear leg pushing off ground, front leg reaching forward
- Frame 3: MID-STRIDE - Legs scissoring, crossing each other
- Frame 4: FRONT LAND - Front leg landing, rear leg lifting
- Each frame must show DIFFERENT leg positions clearly

SECONDARY MOTION:
- Hair flows behind due to movement
- Robe trails with motion
- Electric trail behind staff

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_left_strip.png`

---

## PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Female lightning mage, hair trailing behind, storm robe, staff visible

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: NEUTRAL - Standing side profile
- Frame 2: BACK LEG PUSH - Rear leg pushing, front reaching
- Frame 3: MID-STRIDE - Legs crossing
- Frame 4: FRONT LAND - Front leg down, rear lifting
- CLEAR LEG POSITION CHANGES between frames

SECONDARY MOTION:
- Hair flows opposite to movement direction
- Lightning sparks trail behind

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

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

## PROMPT #6 - Death Animation (4 frames)

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

## PROMPT #7 - Hit Animation (2 frames)

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

## PROMPT #8 - Idle Animation (2 frames)

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

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `storm_caller_walk_down_1.png` - `storm_caller_walk_down_4.png` |
| Walk Up | 4 | `storm_caller_walk_up_1.png` - `storm_caller_walk_up_4.png` |
| Walk Left | 4 | `storm_caller_walk_left_1.png` - `storm_caller_walk_left_4.png` |
| Walk Right | 4 | `storm_caller_walk_right_1.png` - `storm_caller_walk_right_4.png` |
| Cast | 4 | `storm_caller_cast_1.png` - `storm_caller_cast_4.png` |
| Death | 4 | `storm_caller_death_1.png` - `storm_caller_death_4.png` |
| Hit | 2 | `storm_caller_hit_1.png` - `storm_caller_hit_2.png` |
| Idle | 2 | `storm_caller_idle_1.png` - `storm_caller_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/storm_caller/
??? walk/
??? cast/
??? death/
??? hit/
```
