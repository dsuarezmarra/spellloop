# ? Prompts para Animaciones del ARCANIST

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

## ?? GUÍA DE ESTILO - ARCANIST

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre joven |
| **Complexión** | Delgado, estudioso |
| **Cabello** | Corto, desordenado, púrpura oscuro |
| **Expresión** | Curioso, concentrado, ojos brillantes púrpura |
| **Túnica** | Púrpura/violeta con runas arcanas brillantes |
| **Detalles** | Runas flotantes, energía arcana, libro de hechizos |
| **Arma** | Orbe arcano flotante o tomo mágico |

### Paleta de colores:
- **Túnica principal:** Púrpura profundo (#6A0DAD)
- **Túnica sombras:** Violeta oscuro (#4B0082)
- **Highlights:** Lavanda brillante (#E6E6FA)
- **Runas/Magia:** Rosa arcano (#FF00FF) a púrpura
- **Cabello:** Púrpura oscuro (#483D8B)
- **Piel:** Pálida (#FAF0E6)
- **Orbe arcano:** Rosa brillante (#FF69B4)
- **Outline:** Púrpura muy oscuro (#1A0033)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Arcanist - Young Adult Male, Arcane Scholar

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Curious eyes with arcane glow
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Young scholarly man, thin build
- Short messy purple hair
- Curious, focused expression
- Eyes glow soft purple/pink
- Deep purple robe with glowing arcane runes
- Floating magical symbols around him
- Arcane orb or spell tome as focus
- Slightly hunched scholarly posture

COLOR PALETTE:
- Robe: Deep purple (#6A0DAD) with dark violet shadows (#4B0082)
- Arcane effects: Pink (#FF00FF) to purple
- Hair: Dark purple (#483D8B)
- Skin: Pale (#FAF0E6)
- Orb: Bright pink (#FF69B4)
- Outline: Very dark purple (#1A0033)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `arcanist_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Young arcane scholar, purple robe with glowing runes, floating arcane orb

? 3-FRAME WALK CYCLE:
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, scholarly stride, body tilt left
- Frame 2: NEUTRAL - Both legs together, slightly hunched, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, curious walk, body tilt right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3...
- Slightly bookish walking motion
- Robe sways with movement

SECONDARY MOTION:
- Arcane runes float and orbit
- Orb bobs gently
- Magical particles trail

COLORS: Robe #6A0DAD, Hair #483D8B, Orb #FF69B4, Runes #FF00FF

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Arcane scholar, purple robe, floating orb, glowing runes

? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward, scholarly stride
- Frame 2: NEUTRAL - Both legs together, studying posture
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, curious walk

SECONDARY MOTION:
- Runes visible on back of robe
- Orb trails behind
- Magical particles drift

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Arcane scholar, profile view, orb floating ahead, runes trailing

? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg back, front under body, leaning forward curiously
- Frame 2: NEUTRAL - Both legs together, studious stance
- Frame 3: FRONT LEG EXTENDED - Front leg forward, rear under body, eager stride

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Robe trails behind
- Orb floats alongside
- Runes orbit around

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist arcane spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, arcane magic effects

? 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising hands/orb, arcane symbols gathering, eyes glowing bright
- Frame 2: CHANNEL - Orb raised high, massive arcane circle forming, runes spinning
- Frame 3: RELEASE - Hands thrust forward, arcane beam/burst launching, symbol explosion

EFFECTS:
- Frame 1: Runes gathering, pink glow intensifying
- Frame 2: Arcane circle, spinning symbols, maximum energy
- Frame 3: Arcane explosion, beam effect, magical burst

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, magic fading

? 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, shocked, runes shattering, orb flickering
- Frame 2: COLLAPSE - Falling forward, all magic fading, orb falling
- Frame 3: FALLEN - On ground, no runes, desaturated colors, 80% opacity

EFFECTS:
- Frame 1: Runes shattering like glass
- Frame 2: Magic dissipating, orb dimming
- Frame 3: No magical effects, transparency

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

? 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching backward, red damage flash, runes scattered
- Frame 2: RECOIL - Maximum flinch, orb flickering, surprised expression
- Frame 3: RECOVERY - Returning to stance, runes reforming, focused expression

EFFECTS:
- Frame 1: Red tint overlay, runes scattered
- Frame 2: Peak damage pose
- Frame 3: Normal colors, magic stabilizing

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_hit_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `arcanist_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `arcanist_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `arcanist_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `arcanist_cast_strip.png` |
| Death | 3 | 1500x500 | `arcanist_death_strip.png` |
| Hit | 3 | 1500x500 | `arcanist_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/arcanist/
??? walk/
?   ??? arcanist_walk_down_1.png - arcanist_walk_down_3.png
?   ??? arcanist_walk_up_1.png - arcanist_walk_up_3.png
?   ??? arcanist_walk_right_1.png - arcanist_walk_right_3.png
??? cast/
?   ??? arcanist_cast_1.png - arcanist_cast_3.png
??? death/
?   ??? arcanist_death_1.png - arcanist_death_3.png
??? hit/
    ??? arcanist_hit_1.png - arcanist_hit_3.png
```
