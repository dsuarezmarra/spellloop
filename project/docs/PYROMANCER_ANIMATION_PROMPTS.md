# ?? Prompts para Animaciones del PYROMANCER

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

## ?? GUÍA DE ESTILO - PYROMANCER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre adulto |
| **Complexión** | Musculoso, imponente |
| **Cabello** | Corto, negro con puntas de fuego/naranja |
| **Expresión** | Confiado, intenso, ojos con llamas |
| **Túnica** | Roja/naranja con bordes de fuego, hasta rodillas |
| **Detalles** | Llamas pequeñas flotando alrededor, tatuajes de fuego |
| **Arma** | Cetro de fuego con llama viva en la punta |

### Paleta de colores:
- **Túnica principal:** Rojo fuego (#C41E3A)
- **Túnica sombras:** Rojo oscuro (#8B0000)
- **Highlights:** Naranja brillante (#FF6600)
- **Llamas:** Amarillo (#FFD700) a naranja (#FF4500) a rojo
- **Cabello:** Negro (#1A1A1A) con puntas naranja
- **Piel:** Bronceada (#D2691E)
- **Staff llama:** Naranja vivo (#FF8C00)
- **Outline:** Marrón muy oscuro (#2D1B00)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Pyromancer - Adult Male, Fire Mage

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Intense eyes with flame reflections
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Muscular adult man with confident stance
- Short black hair with orange/fire tips
- Intense expression, slight smirk
- Eyes glow with inner fire
- Red/orange robe reaching to knees
- Fire patterns on robe edges
- Small flames floating around body
- Fire staff with living flame at tip
- Flame tattoos visible on arms

COLOR PALETTE:
- Robe: Fire red (#C41E3A) with dark shadows (#8B0000)
- Flames: Yellow (#FFD700) to orange (#FF4500)
- Hair: Black (#1A1A1A) with orange tips
- Skin: Tanned (#D2691E)
- Staff flame: Vivid orange (#FF8C00)
- Outline: Very dark brown (#2D1B00)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `pyromancer_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Muscular fire mage, red/orange robe, fire staff with living flame

?? 3-FRAME WALK CYCLE:
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, confident stride, body tilt left
- Frame 2: NEUTRAL - Both legs together, standing proud, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, powerful stride, body tilt right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3...
- Confident, powerful walking motion
- Robe sways with movement

SECONDARY MOTION:
- Small flames orbit around him
- Staff flame flickers with each step
- Hair fire tips dance

COLORS: Robe #C41E3A, Skin #D2691E, Flames #FF8C00, Hair tips #FF4500

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Fire mage, red robe, fire staff, flames around body

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward, powerful stride
- Frame 2: NEUTRAL - Both legs together, standing strong
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, confident movement

SECONDARY MOTION:
- Flames trail behind as he walks
- Staff flame visible from behind
- Robe flows with movement

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Fire mage, robe profile, fire staff forward, flames trailing

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg back, front under body, aggressive forward lean
- Frame 2: NEUTRAL - Both legs together, proud stance
- Frame 3: FRONT LEG EXTENDED - Front leg forward, rear under body, powerful stride

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Flames stream behind from movement
- Staff held forward aggressively

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer fire spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, intense fire effects

?? 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising fire staff, flames gathering at tip, eyes glowing intensely
- Frame 2: CHANNEL - Staff raised high, massive fireball forming, flames erupting around body
- Frame 3: RELEASE - Staff thrust forward, fireball launching with explosion, fire trail

EFFECTS:
- Frame 1: Flames gathering, heat shimmer
- Frame 2: Massive fire orb, all flames intense
- Frame 3: Fire explosion, motion blur, sparks everywhere

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, flames dying out

?? 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, shocked, flames sputtering and disrupted
- Frame 2: COLLAPSE - Falling forward, all flames dying out, staff falling
- Frame 3: FALLEN - On ground, no flames, desaturated colors, 80% opacity

EFFECTS:
- Frame 1: Flames disrupted, sparks flying
- Frame 2: Flames extinguishing, smoke
- Frame 3: Cold/dark appearance, no fire

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Pyromancer taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

?? 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching, red damage flash, flames scattered
- Frame 2: RECOIL - Maximum flinch, flames disrupted, angry expression
- Frame 3: RECOVERY - Returning to stance, flames re-igniting, furious expression

EFFECTS:
- Frame 1: Red tint overlay, flames disrupted
- Frame 2: Peak damage pose
- Frame 3: Flames returning stronger (angry)

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `pyromancer_hit_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `pyromancer_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `pyromancer_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `pyromancer_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `pyromancer_cast_strip.png` |
| Death | 3 | 1500x500 | `pyromancer_death_strip.png` |
| Hit | 3 | 1500x500 | `pyromancer_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/pyromancer/
??? walk/
?   ??? pyromancer_walk_down_1.png - pyromancer_walk_down_3.png
?   ??? pyromancer_walk_up_1.png - pyromancer_walk_up_3.png
?   ??? pyromancer_walk_right_1.png - pyromancer_walk_right_3.png
??? cast/
?   ??? pyromancer_cast_1.png - pyromancer_cast_3.png
??? death/
?   ??? pyromancer_death_1.png - pyromancer_death_3.png
??? hit/
    ??? pyromancer_hit_1.png - pyromancer_hit_3.png
```
