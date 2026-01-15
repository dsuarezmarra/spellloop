# 🪨 Prompts para Animaciones del GEOMANCER

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

### 🪨 NOTA ESPECIAL - GEOMANCER:
- **Es el personaje MÁS LENTO** del juego
- Sus pasos son PESADOS y deliberados
- Cada paso tiene más "peso" visual

---

## 🎨 GUÍA DE ESTILO - GEOMANCER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre mayor, tipo enano |
| **Complexión** | Bajo, muy robusto, musculoso |
| **Cabello** | Calvo, barba larga gris con gemas |
| **Expresión** | Gruñón pero sabio, ojos brillando ámbar |
| **Vestimenta** | Armadura de piedra/metal pesada, corta |
| **Detalles** | Cristales incrustados, gemas flotantes, polvo de piedra |
| **Arma** | Martillo de cristal o guantes de piedra |

### Paleta de colores:
- **Armadura:** Gris piedra (#696969)
- **Detalles piedra:** Marrón roca (#8B4513)
- **Cristales/Gemas:** Naranja ámbar (#FF8C00) y amarillo (#FFD700)
- **Barba:** Gris con destellos (#C0C0C0)
- **Piel:** Bronceada curtida (#D2691E)
- **Ojos:** Ámbar brillante (#FFBF00)
- **Outline:** Gris muy oscuro (#2F2F2F)

---

# 📝 LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Geomancer - Elderly Male Dwarf, Earth Mage

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Small but VERY sturdy body
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Short stocky dwarf (shortest character)
- Completely bald head with runes
- Long gray beard with small gems woven in
- Grumpy but wise expression
- Eyes glow amber/orange
- Heavy stone and metal armor
- Crystals and gems embedded in armor
- Small floating crystal fragments
- Crystal hammer or stone gauntlets
- Dust particles around feet

COLOR PALETTE:
- Armor: Stone gray (#696969)
- Stone details: Rock brown (#8B4513)
- Crystals: Amber orange (#FF8C00), yellow (#FFD700)
- Beard: Gray with sparkle (#C0C0C0)
- Skin: Weathered tan (#D2691E)
- Eyes: Bright amber (#FFBF00)
- Outline: Very dark gray (#2F2F2F)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

📁 **Guardar como:** `geomancer_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, stocky dwarf, heavy movement

CHARACTER: Elderly dwarf earth mage, stone armor, gray beard with gems, floating crystals

🪨 3-FRAME WALK CYCLE (SLOW AND HEAVY) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left heavy boot clearly STOMPED forward, right foot planted back, body shifted left, ground impact visual
- Frame 2: NEUTRAL STANCE - Both feet together in sturdy wide stance, catching balance, centered heavy pose
- Frame 3: RIGHT FOOT FORWARD - Right heavy boot clearly STOMPED forward, left foot planted back, body shifted right, ground impact visual

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous walking
- SLOWEST character - emphasize WEIGHT in each step
- Wide, deliberate, heavy footfalls
- Ground dust/cracks on each footfall
- EXAGGERATE foot positions - boots should be CLEARLY visible in forward position

SECONDARY MOTION:
- Crystals bob heavily with steps
- Beard swings with momentum
- Ground cracks/dust on impact

COLORS: Armor #696969, Crystals #FF8C00, Beard #C0C0C0, Skin #D2691E

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `geomancer_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, heavy dwarf from behind

CHARACTER (from behind): Stocky dwarf, stone armor, beard visible at sides, crystals floating

🪨 3-FRAME WALK CYCLE (BACK VIEW - HEAVY) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left boot stomped forward (visible extending down-left), wide heavy stance, body shifted left
- Frame 2: NEUTRAL STANCE - Both feet together, sturdy balanced stance, centered pose
- Frame 3: RIGHT FOOT FORWARD - Right boot stomped forward (visible extending down-right), ground impact, body shifted right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3... creates continuous walking
- Show heavy footsteps even from behind

SECONDARY MOTION:
- Heavy back armor visible
- Crystal trail behind
- Dust clouds at feet

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `geomancer_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, heavy dwarf profile

CHARACTER (right profile): Stocky dwarf, beard prominent, hammer/weapon forward

🪨 3-FRAME WALK CYCLE (SIDE VIEW - HEAVY) - FOOT POSITIONS ARE CRITICAL:
- Frame 1: LEFT FOOT FORWARD - Left boot extended forward in front of body, right leg pushing back behind, heavy lean forward
- Frame 2: NEUTRAL STANCE - Both legs together, wide sturdy stance, balanced passing position
- Frame 3: RIGHT FOOT FORWARD - Right boot extended forward in front of body, left leg back behind, deliberate heavy step

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

ANIMATION NOTES:
- Ping-pong cycle creates continuous walking motion
- Side view should clearly show leg extension front and back
- Emphasize weight and slow deliberate movement

SECONDARY MOTION:
- Beard swings with movement
- Weapon bounces with steps
- Ground dust trail

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `geomancer_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer earth magic casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, earth/crystal magic effects

🪨 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - STOMPING ground, crystals rising from below, eyes glowing amber
- Frame 2: CHANNEL - Raising hands, massive crystals emerging, earth trembling
- Frame 3: RELEASE - Hands thrust down, crystal/stone explosion upward, ground shattering

EFFECTS:
- Frame 1: Ground cracking, small crystals emerging
- Frame 2: Large crystals rising, earth magic aura
- Frame 3: Crystal explosion, rock fragments flying

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `geomancer_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, crystals shattering

🪨 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling back, crystals cracking, armor denting
- Frame 2: COLLAPSE - Falling heavily, crystals shattering, weapon dropping
- Frame 3: FALLEN - On ground, crystals crumbled, desaturated, 80% opacity

EFFECTS:
- Frame 1: Crystals cracking
- Frame 2: Crystals shattering into fragments
- Frame 3: Just dust and broken gems, transparency

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `geomancer_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

🪨 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching slightly (he's tough), red damage flash, crystals rattled
- Frame 2: RECOIL - Slight flinch, armor taking hit, grumpy expression
- Frame 3: RECOVERY - Standing firm, crystals re-stabilizing, stubborn stance

EFFECTS:
- Frame 1: Red tint overlay, minimal flinch (tank character)
- Frame 2: Peak damage pose (still standing strong)
- Frame 3: Normal colors, defiant stance

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

📁 **Guardar como:** `geomancer_hit_strip.png`

---

## 📊 RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `geomancer_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `geomancer_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `geomancer_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `geomancer_cast_strip.png` |
| Death | 3 | 1500x500 | `geomancer_death_strip.png` |
| Hit | 3 | 1500x500 | `geomancer_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## 📁 Estructura de Carpetas

```
project/assets/sprites/players/geomancer/
├── walk/
│   ├── geomancer_walk_down_1.png - geomancer_walk_down_3.png
│   ├── geomancer_walk_up_1.png - geomancer_walk_up_3.png
│   └── geomancer_walk_right_1.png - geomancer_walk_right_3.png
├── cast/
│   └── geomancer_cast_1.png - geomancer_cast_3.png
├── death/
│   └── geomancer_death_1.png - geomancer_death_3.png
└── hit/
    └── geomancer_hit_1.png - geomancer_hit_3.png
```
