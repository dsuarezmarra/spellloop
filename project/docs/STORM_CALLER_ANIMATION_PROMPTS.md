# ? Prompts para Animaciones del STORM CALLER

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #6** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4
- **TODAS las animaciones:** 3 frames (1500x500 horizontal strip)

---

## ?? SISTEMA DE ANIMACIÓN (Estilo Binding of Isaac)

**Este juego usa ciclos de 3 frames en ping-pong para TODAS las animaciones:**

### Ciclo de animación:
```
Frame 1 ? Frame 2 ? Frame 3 ? Frame 2 ? Frame 1 ? ...
```

### ?? IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- **TODAS las animaciones tienen 3 frames** - Walk, Cast, Death, Hit
- Total sprites: **18 frames** (6 animaciones × 3 frames)

---

## ?? GUÍA DE ESTILO - STORM CALLER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Mujer joven |
| **Complexión** | Atlética, ágil |
| **Cabello** | Largo, azul eléctrico con destellos blancos, flotando por electricidad |
| **Expresión** | Intensa, ojos brillantes con chispas |
| **Túnica** | Azul oscuro/púrpura tormenta, corta (sobre rodillas), patrones de rayos |
| **Detalles** | Chispas eléctricas alrededor, arcos entre dedos |
| **Arma** | Bastón metálico con punta conductora, chispas constantes |

### Paleta de colores:
- **Túnica principal:** Azul tormenta (#1E3A5F)
- **Túnica sombras:** Púrpura oscuro (#2D1B4E)
- **Highlights:** Amarillo eléctrico (#FFE135)
- **Rayos/Electricidad:** Blanco-azul (#FFFFFF a #00D4FF)
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

DESIGN DETAILS:
- Young woman with athletic build
- Long electric blue hair with white streaks, defying gravity (static)
- Intense expression, confident smirk
- Eyes glow faintly yellow
- Dark blue/purple storm robe (above knees)
- Lightning bolt patterns on robe
- Silver metallic staff with constant sparks
- Small electric arcs dancing around body

COLOR PALETTE:
- Robe: Storm blue (#1E3A5F) with purple shadows (#2D1B4E)
- Lightning: Electric yellow (#FFE135)
- Hair: Electric blue (#00A8FF) with white streaks
- Skin: Light with blue tint (#E8DED5)
- Staff: Silver (#C0C0C0) with cyan sparks (#00D4FF)
- Outline: Very dark blue (#0A1628)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `storm_caller_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Female lightning mage, blue hair floating, storm robe, silver lightning staff

? 3-FRAME WALK CYCLE:
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, slight body tilt left
- Frame 2: NEUTRAL - Both legs together, standing straight, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, slight body tilt right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3...
- Exaggerate leg positions
- Robe sways with movement

SECONDARY MOTION:
- Hair floats with static electricity
- Small lightning arcs between hair strands
- Staff sparks gently

COLORS: Robe #1E3A5F, Hair #00A8FF, Sparks #FFE135, Skin #E8DED5

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Female lightning mage, long blue hair flowing, storm robe, staff

? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward, body tilts slightly
- Frame 2: NEUTRAL - Both legs together, standing straight
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, body tilts opposite

SECONDARY MOTION:
- Hair sways side to side
- Robe hem moves with leg motion
- Electric sparks trail from staff

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Female lightning mage, hair trailing behind, storm robe, staff

? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg back, front under body, leaning forward
- Frame 2: NEUTRAL - Both legs together, upright stance
- Frame 3: FRONT LEG EXTENDED - Front leg forward, rear under body, leaning forward

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Hair flows behind
- Robe trails with motion
- Electric trail behind staff

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, dramatic lightning effects

? 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Staff raised, electricity gathering, hair rising more
- Frame 2: CHANNEL - Eyes glowing bright yellow, lightning arcing around body, maximum charge
- Frame 3: RELEASE - Staff thrust forward, massive lightning bolt launching, bright flash

EFFECTS:
- Frame 1: Yellow sparkles gathering
- Frame 2: Electric arcs everywhere, glowing eyes
- Frame 3: Lightning bolt from staff, light explosion

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, colors desaturating

? 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, shocked expression, electricity sputtering
- Frame 2: COLLAPSE - Falling forward, all electricity fading, hair falling limp
- Frame 3: FALLEN - On ground, desaturated colors, no sparks, 80% opacity

EFFECTS:
- Frame 1: Disrupted electricity, flash
- Frame 2: Sparks dying, hair falling
- Frame 3: No electricity, transparency

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Storm Caller taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

? 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching backward, red damage flash, electricity disrupted
- Frame 2: RECOIL - Maximum flinch, sparks scattered, pained expression
- Frame 3: RECOVERY - Returning to stance, electricity stabilizing, determined

EFFECTS:
- Frame 1: Red tint overlay, disrupted sparks
- Frame 2: Peak damage pose
- Frame 3: Normal colors, sparks re-forming

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `storm_caller_hit_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `storm_caller_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `storm_caller_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `storm_caller_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `storm_caller_cast_strip.png` |
| Death | 3 | 1500x500 | `storm_caller_death_strip.png` |
| Hit | 3 | 1500x500 | `storm_caller_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/storm_caller/
??? walk/
?   ??? storm_caller_walk_down_1.png - storm_caller_walk_down_3.png
?   ??? storm_caller_walk_up_1.png - storm_caller_walk_up_3.png
?   ??? storm_caller_walk_right_1.png - storm_caller_walk_right_3.png
??? cast/
?   ??? storm_caller_cast_1.png - storm_caller_cast_3.png
??? death/
?   ??? storm_caller_death_1.png - storm_caller_death_3.png
??? hit/
    ??? storm_caller_hit_1.png - storm_caller_hit_3.png
```
