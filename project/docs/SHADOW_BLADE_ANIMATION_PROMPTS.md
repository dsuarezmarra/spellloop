# ??? Prompts para Animaciones del SHADOW BLADE

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

### ??? NOTA ESPECIAL - SHADOW BLADE:
- **NO CAMINA - FLOTA/DESLIZA** sobre las sombras
- Movimiento fluido, etéreo, espectral
- Sombras se mueven con él como tentáculos

---

## ?? GUÍA DE ESTILO - SHADOW BLADE

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Ambiguo, misterioso |
| **Complexión** | Esbelta, ágil, semi-transparente |
| **Cabello** | Negro como sombra, fluye como humo |
| **Expresión** | Ojos rojos brillantes, resto del rostro oscuro |
| **Vestimenta** | Capa negra que se funde con sombras |
| **Detalles** | Sombras vivientes, fragmentos oscuros flotando |
| **Arma** | Dagas gemelas de sombra solidificada |

### Paleta de colores:
- **Cuerpo/Capa:** Negro profundo (#1A1A1A)
- **Sombras activas:** Gris oscuro (#333333) a negro
- **Ojos:** Rojo brillante (#FF0000)
- **Destellos:** Púrpura oscuro (#4B0082)
- **Bordes etéreos:** Gris humo (#696969)
- **Dagas:** Negro con filo rojo (#8B0000)
- **Outline:** Negro puro (#000000)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Shadow Blade - Ambiguous Gender, Shadow Assassin

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- ONLY eyes visible (glowing red)
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Mysterious figure made of living shadows
- Gender ambiguous, slender silhouette
- Black smoky hair that flows like darkness
- Only bright red glowing eyes visible
- Rest of face hidden in darkness
- Black cloak that merges into shadow tendrils
- Shadow fragments floating around
- Twin daggers made of solid shadow
- Lower body fades into shadow/smoke
- Does NOT walk - FLOATS on shadows

COLOR PALETTE:
- Body/Cloak: Deep black (#1A1A1A)
- Active shadows: Dark gray (#333333) to black
- Eyes: Bright red (#FF0000)
- Highlights: Dark purple (#4B0082)
- Ethereal edges: Smoke gray (#696969)
- Daggers: Black with red edge (#8B0000)
- Outline: Pure black (#000000)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `shadow_blade_reference.png`

---

## PROMPT #1 - Float Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade FLOATING animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, shadowy, ethereal

CHARACTER: Shadow assassin, red glowing eyes, black cloak, shadow tendrils, twin daggers

??? 3-FRAME FLOAT CYCLE (NO WALKING):
- Frame 1: SHADOW LEFT - Shadow tendrils extend left, slight tilt, eyes drift left
- Frame 2: NEUTRAL - Centered floating, shadows coiled beneath, eyes forward
- Frame 3: SHADOW RIGHT - Shadow tendrils extend right, slight tilt, eyes drift right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3...
- DOES NOT WALK - glides on shadow pool
- Ethereal, ghostly movement
- Lower body is shadowy/smoky

SECONDARY MOTION:
- Shadow tendrils writhe and shift
- Cloak billows like smoke
- Dark particles float around

COLORS: Body #1A1A1A, Eyes #FF0000, Shadows #333333, Highlights #4B0082

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_walk_down_strip.png`

---

## PROMPT #2 - Float Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade FLOATING - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, shadowy from behind

CHARACTER (from behind): Shadow figure, cloak flowing, shadow pool beneath

??? 3-FRAME FLOAT CYCLE (BACK VIEW):
- Frame 1: SHADOW LEFT - Shadows extending left
- Frame 2: NEUTRAL - Centered, shadows pooled
- Frame 3: SHADOW RIGHT - Shadows extending right

SECONDARY MOTION:
- Cloak/shadows form back
- Shadow tendrils visible
- Ethereal dark particles

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_walk_up_strip.png`

---

## PROMPT #3 - Float Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade FLOATING - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, shadow profile

CHARACTER (right profile): Shadow assassin, single red eye visible, daggers ready

??? 3-FRAME FLOAT CYCLE (SIDE VIEW):
- Frame 1: LEAN FORWARD - Body tilting forward, shadows trailing
- Frame 2: NEUTRAL - Straight floating, shadows centered
- Frame 3: LEAN BACK - Body tilting back, shadows leading

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Shadow trail behind
- Cloak streaming
- Dagger held ready

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade shadow magic attack - FACING CAMERA

ART STYLE: Funko Pop/Chibi, shadow magic effects

??? 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising daggers, shadows gathering densely, eyes glowing brighter
- Frame 2: CHANNEL - Daggers crossed, massive shadow vortex forming, tendrils swirling
- Frame 3: RELEASE - Daggers thrust forward, shadow blades/wave launching, darkness exploding

EFFECTS:
- Frame 1: Shadows condensing
- Frame 2: Shadow vortex, maximum darkness
- Frame 3: Shadow blade projectiles, dark explosion

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, shadow dissipating

??? 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, shadows scattering, red eyes flickering
- Frame 2: COLLAPSE - Dissolving into shadow particles, form losing cohesion
- Frame 3: DISSIPATED - Just a shadow puddle with fading red glow, 80% opacity

EFFECTS:
- Frame 1: Shadows fragmenting
- Frame 2: Body dissolving into darkness
- Frame 3: Only shadow residue, eyes fading

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

??? 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching, red damage flash, shadows disrupted
- Frame 2: RECOIL - Form fragmenting briefly, eyes flickering
- Frame 3: RECOVERY - Shadows reforming, eyes steady, ready to strike

EFFECTS:
- Frame 1: Red tint overlay, shadows scattered
- Frame 2: Peak damage, partial dissolution
- Frame 3: Normal colors, shadows reconsolidating

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_hit_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Float Down | 3 | 1500x500 | `shadow_blade_walk_down_strip.png` |
| Float Up | 3 | 1500x500 | `shadow_blade_walk_up_strip.png` |
| Float Right | 3 | 1500x500 | `shadow_blade_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `shadow_blade_cast_strip.png` |
| Death | 3 | 1500x500 | `shadow_blade_death_strip.png` |
| Hit | 3 | 1500x500 | `shadow_blade_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

**NOTA:** Shadow Blade **FLOTA**, no camina. Los archivos se llaman "walk" por consistencia con el código.

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/shadow_blade/
??? walk/
?   ??? shadow_blade_walk_down_1.png - shadow_blade_walk_down_3.png
?   ??? shadow_blade_walk_up_1.png - shadow_blade_walk_up_3.png
?   ??? shadow_blade_walk_right_1.png - shadow_blade_walk_right_3.png
??? cast/
?   ??? shadow_blade_cast_1.png - shadow_blade_cast_3.png
??? death/
?   ??? shadow_blade_death_1.png - shadow_blade_death_3.png
??? hit/
    ??? shadow_blade_hit_1.png - shadow_blade_hit_3.png
```
