# ?? Prompts para Animaciones del VOID WALKER

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo
2. Luego ejecuta los prompts **#1 al #8** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? NOTA ESPECIAL: ESTE PERSONAJE FLOTA

**El Void Walker es un ser parcialmente consumido por el vacío que FLOTA.**

En lugar de animaciones de "walk", tiene animaciones de "float":
- No tiene piernas visibles - su cuerpo se desvanece en energía del vacío
- Se mueve distorsionando el espacio a su alrededor
- Efecto de "glitch" y distorsión de realidad
- Partículas de vacío (púrpura/negro con estrellas) lo rodean

---

## ?? GUÍA DE ESTILO - VOID WALKER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Indefinido/Corrompido |
| **Complexión** | Delgada, parcialmente desintegrada |
| **Cabello** | Inexistente o desintegrándose en partículas |
| **Rostro** | Máscara o rostro sin rasgos, solo ojos de vacío |
| **Ojos** | Agujeros brillando con luz de estrellas |
| **Vestimenta** | Túnica desgarrada que se funde con el vacío |
| **Detalles** | Cuerpo parcialmente transparente, estrellas dentro |
| **Arma** | Energía de vacío pura, agujeros en la realidad |

### Paleta de colores:
- **Túnica:** Púrpura muy oscuro (#1A0033)
- **Vacío interior:** Negro con estrellas (#000011)
- **Energía vacío:** Púrpura brillante (#9933FF) y rosa cósmico (#FF00FF)
- **Ojos/Brillo:** Blanco estelar (#FFFFFF) con púrpura
- **Distorsión:** Efecto de onda, bordes pixelados
- **Partículas:** Pequeñas estrellas brillantes
- **Outline:** Negro puro con brillo (#000000 con glow)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Void Walker - Void-Touched Entity, Cosmic Horror Mage

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body) but DISTORTED
- Eyes are void portals with stars inside
- Thick outline (2-3px) that GLITCHES
- Cel-shading with reality distortion effects

DESIGN DETAILS:
- Humanoid figure corrupted by void energy
- Form unclear, shifting, partially transparent
- No visible hair - head fades into void particles
- Face is blank except for two void-portal eyes (white stars in purple-black)
- Tattered dark purple robe that disintegrates into void at edges
- NO LEGS - lower body completely dissolves into cosmic void energy
- Inside body is visible: dark space with tiny stars
- Hands may be clawed or energy tendrils
- Reality bends around this character (warped space effect)
- Small "glitches" in outline (pixelation, displacement)

COLOR PALETTE:
- Robe: Very dark purple (#1A0033)
- Void interior: Black with stars (#000011)
- Void energy: Bright purple (#9933FF) and cosmic pink (#FF00FF)
- Eyes: White starlight (#FFFFFF) in purple void
- Glitch effects: Random bright pixels
- Particles: Tiny white/purple stars
- Outline: Pure black with purple glow

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `void_walker_reference.png`

---

## PROMPT #1 - Float Down (4 frames) - REEMPLAZA WALK

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker floating animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, cosmic horror, reality distortion

CHARACTER: Void entity, starry void eyes, tattered purple robe, NO LEGS - fades to void

?? THIS CHARACTER FLOATS AND DISTORTS REALITY:
- Frame 1: Floating stable, void energy swirling calmly below
- Frame 2: Phasing slightly left, reality bending, glitch effect on outline
- Frame 3: Reforming center, stars inside body shifting
- Frame 4: Phasing slightly right, void particles trailing
- Movement should feel like teleporting/phasing rather than smooth gliding
- Include small "glitch" artifacts in each frame
- Body slightly transparent - stars visible inside

SECONDARY MOTION:
- Robe edges constantly disintegrating and reforming
- Stars inside body slowly moving
- Void energy tendrils below where legs would be
- Reality distortion waves around body
- Occasional pixel glitch on outline

COLORS: Robe #1A0033, Void #000011, Energy #9933FF/#FF00FF, Eyes white with stars

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_float_down_strip.png`

---

## PROMPT #2 - Float Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker floating - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, cosmic void effects

CHARACTER (from behind): Void entity, tattered robe from back, void below, no legs

FLOATING ANIMATION (BACK VIEW):
- Frame 1: Stable float, robe trailing
- Frame 2: Phase shift, body glitching
- Frame 3: Reforming, void trail behind
- Frame 4: Stable again, stars visible through transparent back
- REALITY DISTORTION effects in each frame

SECONDARY MOTION:
- Robe edges dissolving into space
- Void energy streaming behind
- Glitch artifacts

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_float_up_strip.png`

---

## PROMPT #3 - Float Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker floating - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, otherworldly

CHARACTER (left profile): Void being, profile showing void inside body, no lower body

FLOATING ANIMATION (SIDE VIEW):
- Frame 1: Stable side profile
- Frame 2: Leaning into movement, phasing forward
- Frame 3: Stretching/distorting toward movement direction
- Frame 4: Reforming, void trail behind
- SHOW PHASING MOVEMENT - not normal motion

SECONDARY MOTION:
- Body partially transparent showing stars inside
- Reality warping around figure
- Void particles trailing opposite direction

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_float_left_strip.png`

---

## PROMPT #4 - Float Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker floating - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, cosmic horror

CHARACTER (right profile): Void entity phasing right

FLOATING ANIMATION (SIDE VIEW):
- Frame 1: Stable profile
- Frame 2: Beginning phase shift
- Frame 3: Mid-phase, distorted
- Frame 4: Reforming
- REALITY BENDING movement

SECONDARY MOTION:
- Void energy trailing
- Glitch effects on form
- Stars shifting inside body

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_float_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker void magic attack - FACING CAMERA

ART STYLE: Funko Pop/Chibi, reality-breaking effects

ANIMATION SEQUENCE:
- Frame 1: REACH - Arms/tendrils extending, small void portals opening, eyes glowing brighter
- Frame 2: TEAR - Literally tearing a hole in reality, purple-pink energy exploding, stars pouring out
- Frame 3: RELEASE - Void energy erupting from tear, black hole effect, everything being pulled toward it
- Frame 4: CLOSE - Reality sealing back, residual glitches, satisfied void stare

EFFECTS:
- Frame 1: Small purple portals forming around hands
- Frame 2: Reality cracking like glass, void visible through cracks
- Frame 3: MASSIVE void explosion, black hole visual, stars everywhere
- Frame 4: Reality glitching back together, scattered star particles

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_cast_strip.png`

---

## PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, being consumed by void

ANIMATION SEQUENCE:
- Frame 1: HIT - Form destabilizing violently, massive glitch, eyes flickering
- Frame 2: COLLAPSE - Body folding in on itself, being sucked into internal void
- Frame 3: IMPLODE - Collapsing into a point, stars and void energy compressing
- Frame 4: VANISH - Only a small void portal remains for a moment, then fades

EFFECTS:
- Frame 1: Reality shattering around impact, form losing cohesion
- Frame 2: Body parts dissolving into void, spiraling inward
- Frame 3: Miniature black hole forming where body was
- Frame 4: Small purple sparkle where entity was, then nothing

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_death_strip.png`

---

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, reality glitch

ANIMATION:
- Frame 1: IMPACT - Form glitching violently, breaking into pixels, void inside disrupted
- Frame 2: RECOVERY - Reforming from scattered pieces, void stabilizing, ready to continue

EFFECTS:
- Frame 1: Massive glitch effect, body fragmenting, red interference
- Frame 2: Pieces pulling back together, void re-centering

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker idle/hovering - FACING CAMERA

ART STYLE: Funko Pop/Chibi, unsettling stillness

ANIMATION:
- Frame 1: Floating still, void swirling slowly, stars inside drifting, occasional glitch
- Frame 2: Slight flicker, different star positions inside, outline glitching differently

EFFECTS:
- Constant subtle reality distortion
- Stars slowly rotating inside body
- Random small glitch pixels
- Void energy gently swirling below

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `void_walker_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Float Down | 4 | `void_walker_float_down_1.png` - `void_walker_float_down_4.png` |
| Float Up | 4 | `void_walker_float_up_1.png` - `void_walker_float_up_4.png` |
| Float Left | 4 | `void_walker_float_left_1.png` - `void_walker_float_left_4.png` |
| Float Right | 4 | `void_walker_float_right_1.png` - `void_walker_float_right_4.png` |
| Cast | 4 | `void_walker_cast_1.png` - `void_walker_cast_4.png` |
| Death | 4 | `void_walker_death_1.png` - `void_walker_death_4.png` |
| Hit | 2 | `void_walker_hit_1.png` - `void_walker_hit_2.png` |
| Idle | 2 | `void_walker_idle_1.png` - `void_walker_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/void_walker/
??? float/  ? En lugar de walk/
??? cast/
??? death/
??? hit/
```

---

## ?? NOTA DE IMPLEMENTACIÓN

Este personaje:
1. Usa `float` en lugar de `walk` (igual que Shadow Blade)
2. Tiene regeneración NEGATIVA (-0.5 HP/seg) - pierde vida constantemente
3. Se cura matando enemigos (+2 HP por kill)
4. Es el personaje más difícil de desbloquear y de jugar

El sistema de animación deberá mapear:
- `walk_down` ? `float_down`
- `walk_up` ? `float_up`
- `walk_left` ? `float_left`
- `walk_right` ? `float_right`
