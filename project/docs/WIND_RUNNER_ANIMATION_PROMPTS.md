# 💨 Prompts para Animaciones del WIND RUNNER

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

### 🦶 CICLO DE PIES PARA ANIMACIONES RUN/WALK (MUY IMPORTANTE):
Para crear una sensación natural de correr, los 3 frames deben seguir este patrón:

| Frame | Posición de Pies | Descripción |
|-------|------------------|-------------|
| **Frame 1** | PIE IZQUIERDO ADELANTADO | El pie izquierdo está muy adelante, el derecho muy atrás (zancada amplia) |
| **Frame 2** | POSICIÓN NEUTRAL/AIRE | Ambos pies pasando, casi flotando (momento de vuelo) |
| **Frame 3** | PIE DERECHO ADELANTADO | El pie derecho está muy adelante, el izquierdo muy atrás (zancada amplia) |

Este ciclo en ping-pong (1-2-3-2-1-2-3...) crea la ilusión de correr continuo.

### ⚠️ IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- **TODAS las animaciones tienen 3 frames** - Walk, Cast, Death, Hit
- Total sprites: **18 frames** (6 animaciones × 3 frames)

### 💨 NOTA ESPECIAL - WIND RUNNER:
- **Es el personaje MÁS RÁPIDO** del juego
- Sus pasos son RÁPIDOS y ligeros
- Casi parece que corre/vuela sobre el suelo
- Movimiento muy exagerado y dinámico
- Zancadas más amplias que otros personajes

---

## 🎨 GUÍA DE ESTILO - WIND RUNNER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Mujer joven, ágil |
| **Complexión** | Muy delgada, atlética, ligera |
| **Cabello** | Largo, celeste/blanco, fluye como viento |
| **Expresión** | Alegre, libre, ojos celestes brillantes |
| **Vestimenta** | Túnica ligera celeste/blanca, muy fluida |
| **Detalles** | Corrientes de viento visibles, plumas flotando |
| **Arma** | Arco de viento o cuchillas de aire |

### Paleta de colores:
- **Túnica:** Celeste claro (#87CEEB)
- **Detalles tela:** Blanco (#FFFFFF)
- **Viento/Efectos:** Celeste pálido (#ADD8E6) a blanco
- **Cabello:** Celeste pálido (#B0E0E6) a blanco
- **Piel:** Muy clara, etérea (#FFF5EE)
- **Ojos:** Celeste brillante (#00BFFF)
- **Outline:** Celeste oscuro (#4682B4)

---

# 📝 LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Wind Runner - Young Female, Wind Mage/Scout

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Slender, elegant body
- Thick outline (2-3px) in steel blue
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Young slender woman, very light and agile
- Long flowing sky blue/white hair (always flowing like in wind)
- Joyful, free-spirited expression
- Eyes glow bright cyan
- Light flowing sky blue robes
- Robes and scarves always flowing in wind
- Wind currents visible around her
- Small feathers floating
- Wind bow or air blades as weapon
- Feet barely touching ground

COLOR PALETTE:
- Robes: Light sky blue (#87CEEB), white accents
- Wind effects: Pale blue (#ADD8E6) to white
- Hair: Pale blue (#B0E0E6) fading to white
- Skin: Very light ethereal (#FFF5EE)
- Eyes: Bright cyan (#00BFFF)
- Outline: Steel blue (#4682B4)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

📁 **Guardar como:** `wind_runner_reference.png`

---

## PROMPT #1 - Run Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, ethereal, wind effects

CHARACTER: Young wind mage, flowing blue hair, light robes, wind currents

💨 3-FRAME RUN CYCLE (FASTEST CHARACTER) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Dynamic running pose, left leg extended FAR forward, right leg FAR back, body tilted forward aggressively, wide stride
- Frame 2: BOTH FEET PASSING/AIR - Mid-air moment, both legs tucked under body passing each other, almost floating/flying, minimal ground contact
- Frame 3: RIGHT FOOT FORWARD - Dynamic running pose, right leg extended FAR forward, left leg FAR back, body tilted forward, wide stride opposite

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous running motion
- FASTEST character - EXAGGERATED running motion
- Very light, almost floating over ground
- Speed lines and wind trails
- Zancadas MUY amplias - pies muy separados en frames 1 y 3

SECONDARY MOTION:
- Hair flowing dramatically behind
- Robes streaming back from speed
- Wind gusts and feathers trailing behind

COLORS: Robes #87CEEB, Hair #B0E0E6, Wind #ADD8E6, Skin #FFF5EE

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `wind_runner_walk_down_strip.png`

---

## PROMPT #2 - Run Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, wind effects prominent

CHARACTER (from behind): Slender wind mage, hair and robes streaming forward

💨 3-FRAME RUN CYCLE (BACK VIEW - FAST) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Dynamic run from behind, left leg extended forward (visible extending down-left), right leg back, aggressive lean
- Frame 2: BOTH FEET PASSING/AIR - Mid-air moment, floating/flying pose, both legs passing, minimal contact
- Frame 3: RIGHT FOOT FORWARD - Dynamic run from behind, right leg extended forward (visible extending down-right), left leg back, wide stride

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous running motion
- From behind, show leg positions clearly through robe movement
- Speed emphasis - wide strides visible

SECONDARY MOTION:
- Hair streaming ahead (from her perspective)
- Wind visible from behind
- Speed trail effect

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `wind_runner_walk_up_strip.png`

---

## PROMPT #3 - Run Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, dynamic side profile

CHARACTER (right profile): Wind mage in full sprint, hair trailing, robes flowing

💨 3-FRAME RUN CYCLE (SIDE VIEW - FAST) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left leg reaching FAR forward in front of body, right leg extended FAR back behind body, leaning FAR forward aggressively, full sprint
- Frame 2: BOTH FEET PASSING/AIR - Mid-air moment, both legs passing under body, floating/flying pose, graceful aerial moment
- Frame 3: RIGHT FOOT FORWARD - Right leg reaching FAR forward in front of body, left leg extended FAR back behind body, graceful powerful stride

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

ANIMATION NOTES:
- Ping-pong cycle creates continuous running motion
- Side view should clearly show WIDE leg extension front and back
- This is a SPRINT, not a walk - exaggerate everything

SECONDARY MOTION:
- Everything streams behind dramatically from speed
- Wind trail and feathers trailing
- Almost horizontal running pose

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `wind_runner_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner wind magic casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, wind/air effects

💨 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Arms drawing back, winds gathering, hair swirling up
- Frame 2: CHANNEL - Spinning, tornado forming around her, eyes glowing bright
- Frame 3: RELEASE - Arms thrust forward, wind blades/gust launching, air explosion

EFFECTS:
- Frame 1: Winds gathering, feathers swirling
- Frame 2: Mini tornado, spinning air currents
- Frame 3: Wind slash/gust projectile, air burst

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `wind_runner_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, wind fading

💨 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, wind disrupted, feathers scattering
- Frame 2: COLLAPSE - Drifting down gently (wind mage), hair falling flat
- Frame 3: FALLEN - On ground gently, no wind, still pose, 80% opacity

EFFECTS:
- Frame 1: Wind disrupted, feathers scattering
- Frame 2: Gentle floating descent
- Frame 3: Peaceful stillness, transparency

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `wind_runner_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

💨 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching back, red damage flash, wind scattered
- Frame 2: RECOIL - Maximum flinch, hair wild, surprised expression
- Frame 3: RECOVERY - Quick recovery (fast character), winds returning, determined look

EFFECTS:
- Frame 1: Red tint overlay, wind disrupted
- Frame 2: Peak damage pose
- Frame 3: Normal colors, wind reforming quickly

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `wind_runner_hit_strip.png`

---

## 📊 RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Run Down | 3 | 1500x500 | `wind_runner_walk_down_strip.png` |
| Run Up | 3 | 1500x500 | `wind_runner_walk_up_strip.png` |
| Run Right | 3 | 1500x500 | `wind_runner_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `wind_runner_cast_strip.png` |
| Death | 3 | 1500x500 | `wind_runner_death_strip.png` |
| Hit | 3 | 1500x500 | `wind_runner_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## 📁 Estructura de Carpetas

```
project/assets/sprites/players/wind_runner/
├── walk/
│   ├── wind_runner_walk_down_1.png - wind_runner_walk_down_3.png
│   ├── wind_runner_walk_up_1.png - wind_runner_walk_up_3.png
│   └── wind_runner_walk_right_1.png - wind_runner_walk_right_3.png
├── cast/
│   └── wind_runner_cast_1.png - wind_runner_cast_3.png
├── death/
│   └── wind_runner_death_1.png - wind_runner_death_3.png
└── hit/
    └── wind_runner_hit_1.png - wind_runner_hit_3.png
```
