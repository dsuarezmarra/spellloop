# ?? Prompts para Animaciones del GEOMANCER

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #7** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? SISTEMA DE ANIMACIÓN DE CAMINAR (Estilo Binding of Isaac)

**Este juego usa un ciclo de caminata de 3 frames en ping-pong:**

### Ciclo de animación:
```
Frame 1 ? Frame 2 ? Frame 3 ? Frame 2 ? Frame 1 ? ...
```

### Descripción de cada frame:

| Frame | Walk Down/Up (vista frontal/trasera) | Walk Right (vista lateral) |
|-------|--------------------------------------|----------------------------|
| **1** | Pierna IZQUIERDA hacia afuera | Pierna TRASERA atrás, inclinado hacia adelante |
| **2** | Piernas JUNTAS (posición neutral) | Piernas JUNTAS (posición neutral) |
| **3** | Pierna DERECHA hacia afuera | Pierna DELANTERA adelante, inclinado hacia adelante |

### ?? IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- Solo se necesitan **3 sprites por dirección**: Down, Up y Right
- Total walk sprites: **9 frames** (3 direcciones × 3 frames)

### ?? NOTA ESPECIAL - GEOMANCER:
El Geomancer es EL PERSONAJE MÁS LENTO pero más resistente. Su animación debe reflejar:
- Pasos pesados y deliberados
- Postura anclada, conectado a la tierra
- Cada paso parece hundir el suelo
- Pasos cortos pero sólidos

---

## ?? GUÍA DE ESTILO - GEOMANCER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre robusto, enano/semi-enano |
| **Complexión** | Muy corpulento, bajo y ancho, como una roca |
| **Cabello** | Corto, marrón rojizo, barba trenzada con gemas |
| **Expresión** | Estoico, imperturbable, ojos ámbar |
| **Vestimenta** | Armadura/túnica pesada de piedra y metal |
| **Detalles** | Cristales creciendo de los hombros, runas de tierra |
| **Arma** | Martillo/mazo de piedra o puños de roca |

### Paleta de colores:
- **Armadura:** Marrón piedra (#8B7355)
- **Sombras:** Marrón oscuro (#5D4037)
- **Cristales:** Ámbar (#FFB300) y topacio (#FF8F00)
- **Metal:** Bronce oxidado (#CD7F32)
- **Barba/Cabello:** Marrón rojizo (#A0522D)
- **Piel:** Bronceada oscura (#B8860B)
- **Runas:** Naranja tierra (#E65100)
- **Outline:** Marrón muy oscuro (#3E2723)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Geomancer - Stocky Dwarf-like Male, Earth Tank

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body) - but also very wide
- Small stern amber eyes
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Short, stocky, incredibly wide dwarf-like man
- Built like a boulder - width almost equals height
- Short reddish-brown hair
- Long braided beard with small gems/crystals woven in
- Stern, unshakeable expression
- Amber eyes that glow faintly
- Heavy stone and metal armor covering most of body
- Crystals growing from shoulder pauldrons
- Earth runes carved into armor, glowing orange
- Massive stone hammer or rock fists
- Feet firmly planted, grounded stance

COLOR PALETTE:
- Armor: Stone brown (#8B7355) with dark shadows (#5D4037)
- Crystals: Amber (#FFB300) and topaz (#FF8F00)
- Metal: Oxidized bronze (#CD7F32)
- Beard/Hair: Reddish brown (#A0522D)
- Skin: Dark tan (#B8860B)
- Runes: Earth orange (#E65100)
- Outline: Very dark brown (#3E2723)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `geomancer_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, heavy and grounded

CHARACTER: Stocky dwarf earth mage, braided beard, stone armor, crystals on shoulders

?? 3-FRAME WALK CYCLE - SLOW HEAVY STEPS:
- Frame 1: LEFT LEG OUT - Left heavy foot stepped outward, weight on left, body tilts slightly
- Frame 2: NEUTRAL - Both feet firmly planted together, solid stance, immovable
- Frame 3: RIGHT LEG OUT - Right heavy foot stepped outward, weight on right, body tilts slightly

ANIMATION NOTES:
- This creates a heavy, grounded walk when played as: 1-2-3-2-1-2-3...
- SHOW HEAVY FOOTFALLS - each step looks like it could crack the ground
- Short stride length - he doesn't need to move fast
- Body barely tilts - extremely stable
- Slowest character - convey WEIGHT

SECONDARY MOTION:
- Crystals on shoulders glow with each step
- Beard sways minimally - too heavy
- Runes pulse with walking rhythm
- Small dust/pebbles implied from footsteps

COLORS: Armor #8B7355, Crystals #FFB300, Beard #A0522D, Runes #E65100

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, massive back

CHARACTER (from behind): Wide dwarf, massive back armor, braided beard tips visible

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left heavy foot out, minimal movement
- Frame 2: NEUTRAL - Solid planted stance
- Frame 3: RIGHT LEG OUT - Right heavy foot out, completing slow cycle

ANIMATION NOTES:
- MINIMAL MOVEMENT - stability is key
- Show the massive width of this character
- Heavy deliberate steps

SECONDARY MOTION:
- Back crystals glowing
- Wide shoulders barely moving
- Runes pulsing on back armor

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, wide profile

CHARACTER (right profile): Massive wide dwarf, stone hammer visible, heavy armor

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg back, very short stride, heavy feel
- Frame 2: NEUTRAL - Both legs solid under body
- Frame 3: FRONT LEG EXTENDED - Front leg forward slightly, maintaining stability

ANIMATION NOTES:
- SHORT STRIDES - very little forward lean
- This sprite will be FLIPPED HORIZONTALLY for Walk Left
- EACH STEP looks powerful but slow

SECONDARY MOTION:
- Hammer held steady (barely moves - too heavy)
- Beard swings slightly
- Implied dust from footfalls

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer earth magic attack - FACING CAMERA

ART STYLE: Funko Pop/Chibi, earthquake effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raising hammer/fists, crystals glowing intensely, ground cracking
- Frame 2: CHANNEL - Pulling earth energy upward, rocks floating around him, eyes blazing
- Frame 3: SLAM - Hammer/fists hitting ground, massive earth spike eruption, screen shake effect
- Frame 4: RECOVERY - Standing from slam, rocks settling, earth returning to calm

EFFECTS:
- Frame 1: Ground cracks, crystals glow
- Frame 2: Floating rocks, intense orange energy
- Frame 3: Earth explosion, spikes, dust
- Frame 4: Settling rocks, residual glow

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, crumbling effect

ANIMATION SEQUENCE:
- Frame 1: HIT - Massive impact, recoiling, crystals cracking
- Frame 2: STAGGER - Stumbling, armor crumbling at edges, runes flickering
- Frame 3: COLLAPSE - Falling heavily, ground shakes, crystals shattering
- Frame 4: FALLEN - On ground, armor partially crumbled, crystals dark, still like a fallen statue

EFFECTS:
- Frame 1: Impact crack on armor
- Frame 2: Pieces falling off
- Frame 3: Heavy fall
- Frame 4: Slight transparency (80% opacity), statue-like

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, armor impact

ANIMATION:
- Frame 1: IMPACT - Barely flinching, red damage flash, armor absorbing hit, crystals flickering
- Frame 2: RECOVERY - Immediate solid stance, unfazed expression, crystals restabilizing

EFFECTS:
- Frame 1: Red tint overlay, minimal movement (he's tanky!)
- Frame 2: Normal colors, ready to continue

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, stone-solid presence

ANIMATION:
- Frame 1: INHALE - Minimal chest expansion (armor), crystals glowing steadily
- Frame 2: EXHALE - Nearly identical, crystals pulse slightly, immovable stance

EFFECTS:
- Crystal glow pulse
- Runes subtle glow
- Rock-solid stance

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `geomancer_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `geomancer_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `geomancer_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `geomancer_cast_strip.png` |
| Death | 4 | 2000x500 | `geomancer_death_strip.png` |
| Hit | 2 | 1000x500 | `geomancer_hit_strip.png` |
| Idle | 2 | 1000x500 | `geomancer_idle_strip.png` |

**Total: 21 frames**

---

## ?? Implementación en Godot

### Ciclo de animación Walk (ping-pong):
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

## ?? Estructura de Carpetas

```
project/assets/sprites/players/geomancer/
??? walk/
?   ??? geomancer_walk_down_1.png - geomancer_walk_down_3.png
?   ??? geomancer_walk_up_1.png - geomancer_walk_up_3.png
?   ??? geomancer_walk_right_1.png - geomancer_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
