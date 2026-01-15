# 🌌 Prompts para Animaciones del VOID WALKER

## 📋 IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #6** en orden
3. Guarda cada imagen con el nombre indicado

---

## 📐 Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4
- **TODAS las animaciones:** 3 frames (1500x500 horizontal strip)

---

## 🎬 SISTEMA DE ANIMACIÓN (Estilo Binding of Isaac)

**Este juego usa ciclos de 3 frames en ping-pong para TODAS las animaciones:**

### Ciclo de animación:
```
Frame 1 → Frame 2 → Frame 3 → Frame 2 → Frame 1 → ...
```

### ⚠️ IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- **TODAS las animaciones tienen 3 frames** - Walk, Cast, Death, Hit
- Total sprites: **18 frames** (6 animaciones × 3 frames)

### 🌌 NOTA ESPECIAL - VOID WALKER:
- **NO CAMINA - FLOTA/TELETRANSPORTA** a través del vacío
- Movimiento distorsionado, espacial, cósmico
- Partículas de vacío y estrellas lo rodean
- **NO USA CICLO DE PIES** - usa efecto de fase/distorsión

---

## 🎨 GUÍA DE ESTILO - VOID WALKER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Ambiguo, alienígena |
| **Complexión** | Etérea, semi-transparente, fluctuante |
| **Cabello** | Púrpura/negro cósmico con estrellas |
| **Expresión** | Ojos blancos brillantes vacíos, sereno |
| **Vestimenta** | Túnica púrpura oscura con patrones de estrellas |
| **Detalles** | Estrellas y galaxias flotando, portales pequeños |
| **Arma** | Orbe del vacío o manos que canalizan el cosmos |

### Paleta de colores:
- **Túnica:** Púrpura oscuro espacial (#1A0A30)
- **Efectos cósmicos:** Púrpura (#6A0DAD) a azul (#00008B)
- **Estrellas:** Blanco (#FFFFFF) y amarillo pálido (#FFFACD)
- **Ojos:** Blanco brillante vacío (#FFFFFF)
- **Portales:** Púrpura brillante (#9400D3) con borde azul
- **Piel:** Gris azulado pálido (#708090)
- **Outline:** Púrpura muy oscuro (#0D0D1A)

---

# 📝 LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Void Walker - Ambiguous Gender, Cosmic/Void Mage

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Cosmic/ethereal appearance
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Mysterious cosmic being
- Gender ambiguous, serene alien beauty
- Hair is like space itself - purple/black with tiny stars
- Empty white glowing eyes (no pupils)
- Calm, knowing, otherworldly expression
- Dark purple robes with star patterns
- Small galaxies and stars orbit around body
- Tiny void portals occasionally appear
- Lower body slightly translucent/fading
- Does NOT walk - PHASES/BLINKS through void

COLOR PALETTE:
- Robes: Space purple (#1A0A30)
- Cosmic effects: Purple (#6A0DAD) to blue (#00008B)
- Stars: White (#FFFFFF), pale yellow (#FFFACD)
- Eyes: Empty white glow (#FFFFFF)
- Portals: Bright purple (#9400D3)
- Skin: Pale blue-gray (#708090)
- Outline: Very dark purple (#0D0D1A)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

📁 **Guardar como:** `void_walker_reference.png`

---

## PROMPT #1 - Phase Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker PHASING animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, cosmic, void effects

CHARACTER: Cosmic void mage, white empty eyes, purple star robes, floating galaxies

🌌 3-FRAME PHASE CYCLE (NO WALKING - VOID PHASING):
- Frame 1: PHASE LEFT - Body partially fading/phasing to the left, void portal hint on left, stars trail to the right
- Frame 2: SOLID - Fully visible and centered, stars orbiting normally, stable cosmic form
- Frame 3: PHASE RIGHT - Body partially fading/phasing to the right, void portal hint on right, stars trail to the left

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous phasing motion
- DOES NOT WALK - phases/blinks through space
- Ethereal, dimensional shifting movement
- Always slightly floating off ground, no visible feet

SECONDARY MOTION:
- Stars and galaxies orbit and trail
- Small void portals flicker
- Cosmic particles drift

COLORS: Robes #1A0A30, Eyes #FFFFFF, Stars #FFFFFF, Portals #9400D3

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `void_walker_walk_down_strip.png`

---

## PROMPT #2 - Phase Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker PHASING - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, cosmic from behind

CHARACTER (from behind): Void mage, starry hair flowing, cosmic robes

🌌 3-FRAME PHASE CYCLE (BACK VIEW - VOID PHASING):
- Frame 1: PHASE LEFT - Body fading to the left, stars trailing behind
- Frame 2: SOLID - Fully visible from behind, stars orbiting
- Frame 3: PHASE RIGHT - Body fading to the right, stars trailing

ANIMATION NOTES:
- NO FEET - cosmic form floats
- Shows dimensional phasing from behind

SECONDARY MOTION:
- Starry hair visible from behind
- Galaxies orbiting body
- Void shimmer effect around form

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `void_walker_walk_up_strip.png`

---

## PROMPT #3 - Phase Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker PHASING - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, cosmic profile

CHARACTER (right profile): Void mage, profile showing empty eye, starry hair trailing

🌌 3-FRAME PHASE CYCLE (SIDE VIEW - VOID PHASING):
- Frame 1: TRAIL BACK - Body solid, cosmic trail behind, phasing from previous position
- Frame 2: SOLID - Fully visible in profile, centered phase, stable
- Frame 3: REACH FORWARD - Partial phase ahead, reaching into void, leading edge fading

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

ANIMATION NOTES:
- NO FEET - side profile shows floating cosmic form
- Dimensional phasing side view

SECONDARY MOTION:
- Void ripple around form
- Stars streaming behind
- Dimensional distortion effect

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `void_walker_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker void magic casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, cosmic/void effects

🌌 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising hands, void portal opening before them, eyes glowing brighter
- Frame 2: CHANNEL - Arms spread, massive void tear opening, stars being pulled in
- Frame 3: RELEASE - Hands thrust forward, void blast/beam launching, cosmic explosion

EFFECTS:
- Frame 1: Void portal forming
- Frame 2: Massive tear in space, black hole effect
- Frame 3: Void energy beam, cosmic burst

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `void_walker_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, cosmic collapse

🌌 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, cosmic energy disrupted, stars scattering
- Frame 2: COLLAPSE - Being pulled into self, collapsing into mini void
- Frame 3: VANISHED - Only a small void remnant with fading stars, 80% opacity

EFFECTS:
- Frame 1: Cosmic disruption
- Frame 2: Collapsing into void portal
- Frame 3: Gone into void, just residual stars

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `void_walker_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Void Walker taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

🌌 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching, red damage flash, cosmic field disrupted
- Frame 2: RECOIL - Partial phase out (defensive reaction), stars scattered
- Frame 3: RECOVERY - Phasing back in fully, stars realigning, ready pose

EFFECTS:
- Frame 1: Red tint overlay, cosmic disruption
- Frame 2: Partially phased out (damage avoidance)
- Frame 3: Normal colors, cosmic field restored

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `void_walker_hit_strip.png`

---

## 📊 RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Phase Down | 3 | 1500x500 | `void_walker_walk_down_strip.png` |
| Phase Up | 3 | 1500x500 | `void_walker_walk_up_strip.png` |
| Phase Right | 3 | 1500x500 | `void_walker_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `void_walker_cast_strip.png` |
| Death | 3 | 1500x500 | `void_walker_death_strip.png` |
| Hit | 3 | 1500x500 | `void_walker_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

**NOTA:** Void Walker **FLOTA/FASE**, no camina. Los archivos se llaman "walk" por consistencia con el código.

---

## 📁 Estructura de Carpetas

```
project/assets/sprites/players/void_walker/
├── walk/
│   ├── void_walker_walk_down_1.png - void_walker_walk_down_3.png
│   ├── void_walker_walk_up_1.png - void_walker_walk_up_3.png
│   └── void_walker_walk_right_1.png - void_walker_walk_right_3.png
├── cast/
│   └── void_walker_cast_1.png - void_walker_cast_3.png
├── death/
│   └── void_walker_death_1.png - void_walker_death_3.png
└── hit/
    └── void_walker_hit_1.png - void_walker_hit_3.png
```
