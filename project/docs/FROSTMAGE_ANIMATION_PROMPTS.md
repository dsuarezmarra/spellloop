# ❄️ Prompts para Animaciones del FROST MAGE

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

### 🦶 CICLO DE PIES PARA ANIMACIONES WALK (MUY IMPORTANTE):
Para crear una sensación natural de caminar, los 3 frames deben seguir este patrón:

| Frame | Posición de Pies | Descripción |
|-------|------------------|-------------|
| **Frame 1** | PIE IZQUIERDO ADELANTADO | El pie izquierdo está adelante, el derecho atrás |
| **Frame 2** | POSICIÓN NEUTRAL | Ambos pies juntos o alineados, postura centrada |
| **Frame 3** | PIE DERECHO ADELANTADO | El pie derecho está adelante, el izquierdo atrás |

Este ciclo en ping-pong (1-2-3-2-1-2-3...) crea la ilusión de caminar continuo.

### ⚠️ IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- **TODAS las animaciones tienen 3 frames** - Walk, Cast, Death, Hit
- Total sprites: **18 frames** (6 animaciones × 3 frames)

---

## 🎨 GUÍA DE ESTILO - FROST MAGE

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre anciano |
| **Complexión** | Delgado, encorvado ligeramente |
| **Cabello** | Barba larga blanca/plateada con escarcha |
| **Expresión** | Amable, sabio, ojos brillantes azul hielo |
| **Túnica** | Azul hielo larga hasta los pies, con capucha |
| **Detalles** | Cristales de hielo, escarcha en la ropa, aliento visible |
| **Arma** | Bastón de hielo con cristal cian brillante |

### Paleta de colores:
- **Túnica principal:** Azul hielo (#4A9CC9)
- **Túnica sombras:** Azul profundo (#2A6A9C)
- **Túnica highlights:** Blanco azulado (#B0E0FF)
- **Piel:** Beige pálido (#E8E4D8)
- **Barba/Pelo:** Blanco con tinte azulado (#E8F4FF)
- **Staff cristal:** Cian brillante (#66CCFF)
- **Staff:** Hielo cristalizado (#A0D8FF)
- **Outline:** Azul muy oscuro (#1A2A3E)

---

# 📝 LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Frost Mage / Ice Wizard - Elderly Male

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big cute expressive eyes with ice-blue shine highlights
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Long flowing ice-blue hooded robe reaching to feet
- Large hood partially shadowing face with frost crystals
- Long white/silver beard with ice crystals frozen in it
- Kind elderly face with pale cheeks
- Glowing ice-blue eyes
- Crystalline ice staff with glowing cyan crystal tip
- Robe has frost patterns and snowflake designs
- Small ice crystals floating around him

COLOR PALETTE:
- Robe: Ice blue (#4A9CC9) with deeper shadows (#2A6A9C)
- Skin: Pale beige (#E8E4D8)
- Beard: White with blue tint (#E8F4FF)
- Staff crystal: Bright cyan glow (#66CCFF)
- Staff body: Crystalline ice (#A0D8FF)
- Outline: Very dark blue (#1A2A3E)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

📁 **Guardar como:** `frost_mage_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Frost Mage walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Elderly ice wizard, ice-blue robe, white beard with frost, crystalline ice staff

❄️ 3-FRAME WALK CYCLE - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left foot/leg clearly stepped forward, right leg straight back, slight body tilt left
- Frame 2: NEUTRAL STANCE - Both feet together side by side, standing straight, centered balanced pose
- Frame 3: RIGHT FOOT FORWARD - Right foot/leg clearly stepped forward, left leg straight back, slight body tilt right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous walking
- EXAGGERATE foot positions for clarity - make the forward foot CLEARLY visible ahead
- Elderly but steady walking motion
- Long robe sways with leg movement

SECONDARY MOTION:
- Beard sways gently with each step
- Ice crystals orbit staff
- Small frost particles trail behind

COLORS: Robe #4A9CC9, Skin #E8E4D8, Beard #E8F4FF, Crystal #66CCFF

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `frost_mage_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Frost Mage walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Elderly ice wizard, ice-blue robe, hood visible, ice staff

❄️ 3-FRAME WALK CYCLE (BACK VIEW) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left leg stepped forward (visible extending down-left), body tilts slightly left
- Frame 2: NEUTRAL STANCE - Both legs together, standing straight, centered balanced pose
- Frame 3: RIGHT FOOT FORWARD - Right leg stepped forward (visible extending down-right), body tilts slightly right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous walking
- From behind, show leg positions clearly through robe movement

SECONDARY MOTION:
- Robe flows with movement, frost patterns visible
- Ice staff crystal glows

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `frost_mage_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Frost Mage walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Elderly ice wizard, robe profile, frost beard, ice staff

❄️ 3-FRAME WALK CYCLE (SIDE VIEW) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left leg extended forward in front of body, right leg stretched back behind, leaning forward
- Frame 2: NEUTRAL STANCE - Both legs together under body, upright balanced stance, passing position
- Frame 3: RIGHT FOOT FORWARD - Right leg extended forward in front of body, left leg stretched back behind, leaning forward

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

ANIMATION NOTES:
- Ping-pong cycle creates continuous walking motion
- Side view should clearly show leg extension front and back

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `frost_mage_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Frost Mage ice spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, magical ice effects

❄️ 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising ice staff, frost particles gathering at crystal tip, cold mist rising
- Frame 2: CHANNEL - Staff raised high, intense ice orb at tip, eyes glowing, maximum energy
- Frame 3: RELEASE - Staff thrust forward, ice burst with snowflakes exploding, bright flash

EFFECTS:
- Frame 1: Frost gathering, cold vapor
- Frame 2: Intense ice orb, robe billowing
- Frame 3: Ice explosion, snowflakes, motion lines

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `frost_mage_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Frost Mage death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, colors becoming frozen/desaturated

❄️ 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling backward, shocked expression, ice staff cracking, frost disrupted
- Frame 2: COLLAPSE - Falling forward, crystal light fading, freezing effect spreading
- Frame 3: FALLEN - On ground, partially frozen, ice crystals around body, 80% opacity

EFFECTS:
- Frame 1: Impact flash, cold burst
- Frame 2: Freezing over, light fading
- Frame 3: Frozen appearance, slight transparency

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `frost_mage_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Frost Mage taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

❄️ 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching backward, surprised expression, red damage flash, ice disrupted
- Frame 2: RECOIL - Maximum flinch position, ice crystals scattered, pain expression
- Frame 3: RECOVERY - Returning to stance, determined expression, ice reforming

EFFECTS:
- Frame 1: Red tint overlay, ice scattered
- Frame 2: Peak damage pose
- Frame 3: Normal colors returning, frost stabilizing

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `frost_mage_hit_strip.png`

---

## 📊 RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `frost_mage_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `frost_mage_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `frost_mage_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `frost_mage_cast_strip.png` |
| Death | 3 | 1500x500 | `frost_mage_death_strip.png` |
| Hit | 3 | 1500x500 | `frost_mage_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## 🎮 Implementación en Godot

### Todas las animaciones (ping-pong):
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

## 📁 Estructura de Carpetas

```
project/assets/sprites/players/frost_mage/
├── walk/
│   ├── frost_mage_walk_down_1.png - frost_mage_walk_down_3.png
│   ├── frost_mage_walk_up_1.png - frost_mage_walk_up_3.png
│   └── frost_mage_walk_right_1.png - frost_mage_walk_right_3.png
├── cast/
│   └── frost_mage_cast_1.png - frost_mage_cast_3.png
├── death/
│   └── frost_mage_death_1.png - frost_mage_death_3.png
└── hit/
    └── frost_mage_hit_1.png - frost_mage_hit_3.png
```
