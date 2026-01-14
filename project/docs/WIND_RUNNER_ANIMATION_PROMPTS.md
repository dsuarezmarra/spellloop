# ?? Prompts para Animaciones del WIND RUNNER

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

### ?? NOTA ESPECIAL - WIND RUNNER:
El Wind Runner es EL PERSONAJE MÁS RÁPIDO del juego. Su animación debe reflejar:
- Postura inclinada hacia adelante, corriendo más que caminando
- Mayor amplitud de zancada - piernas más separadas
- Sensación de velocidad - ropa y pelo ondeando hacia atrás
- Ligereza - parece apenas tocar el suelo

---

## ?? GUÍA DE ESTILO - WIND RUNNER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Joven andrógino/no binario |
| **Complexión** | Muy delgada, ágil, atlética |
| **Cabello** | Corto y puntiagudo, blanco plateado, siempre hacia atrás por el viento |
| **Expresión** | Alegre, travieso, ojos brillantes |
| **Vestimenta** | Ropa ligera, túnica corta blanca/cyan, cintas flotando |
| **Detalles** | Cintas y telas flotando constantemente, espirales de viento |
| **Arma** | Cuchillas de viento/abanicos de combate |

### Paleta de colores:
- **Túnica principal:** Blanco verdoso (#F0FFF0)
- **Acentos:** Cyan claro (#E0FFFF)
- **Detalles viento:** Blanco brillante (#FFFFFF) con cyan (#00CED1)
- **Cintas:** Turquesa claro (#40E0D0)
- **Cabello:** Blanco plateado (#E8E8E8)
- **Piel:** Muy clara (#FFF5EE)
- **Ojos:** Cyan brillante (#00CED1)
- **Outline:** Gris azulado (#4A6572)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Wind Runner - Young Androgynous, Wind Speedster

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big bright cyan eyes, playful expression
- Thick outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Young androgynous person, neither clearly male nor female
- Very slim, athletic build optimized for speed
- Short spiky silver-white hair, always windswept backward
- Mischievous, playful smile
- Bright cyan glowing eyes
- Light, short white/cyan tunic (above knees for running)
- Multiple flowing ribbons and sashes attached to outfit
- All fabric constantly flowing as if in strong wind
- Light sandals or bare feet
- Wind spirals around them constantly
- Wind blades or combat fans as weapons

COLOR PALETTE:
- Tunic: Mint white (#F0FFF0) with cyan accents (#E0FFFF)
- Wind details: White (#FFFFFF) with cyan (#00CED1)
- Ribbons: Light turquoise (#40E0D0)
- Hair: Silver white (#E8E8E8)
- Skin: Very pale (#FFF5EE)
- Eyes: Bright cyan (#00CED1)
- Outline: Blue-gray (#4A6572)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `wind_runner_reference.png`

---

## PROMPT #1 - Walk/Run Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, dynamic movement, wind effects

CHARACTER: Androgynous wind mage, silver hair, white/cyan outfit, floating ribbons

?? 3-FRAME RUN CYCLE - FASTEST CHARACTER:
- Frame 1: LEFT LEG OUT - Left leg stretched far outward/forward, EXAGGERATED stride, body leaning left, speed pose
- Frame 2: NEUTRAL - Both legs together but body still leaning forward, ready to spring
- Frame 3: RIGHT LEG OUT - Right leg stretched far outward/forward, EXAGGERATED stride, body leaning right

ANIMATION NOTES:
- This creates a FAST bouncy run when played as: 1-2-3-2-1-2-3...
- EXAGGERATED LEG MOVEMENT - this character RUNS, not walks
- Body leans forward into movement even in neutral
- Arms pumping or held back for aerodynamics
- MORE DYNAMIC than other characters

SECONDARY MOTION:
- Hair blown completely backward
- ALL ribbons streaming behind
- Wind spirals trailing from movement
- Tunic pressed against body from speed

COLORS: Tunic #F0FFF0, Hair #E8E8E8, Eyes #00CED1, Ribbons #40E0D0

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_down_strip.png`

---

## PROMPT #2 - Walk/Run Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, speed effects

CHARACTER (from behind): Silver-haired runner, ribbons streaming, wind effects

?? 3-FRAME RUN CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg far out (visible from behind), huge dynamic stride
- Frame 2: NEUTRAL - Legs together, body leaning forward
- Frame 3: RIGHT LEG OUT - Right leg far out, continuing speed

ANIMATION NOTES:
- SHOW RUNNING MOTION with exaggerated leg positions
- Dynamic forward-leaning posture
- Mirror the front view energy

SECONDARY MOTION:
- Hair streaming backward (toward camera)
- Ribbons flowing toward viewer
- Wind trail effects

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_up_strip.png`

---

## PROMPT #3 - Walk/Run Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, extreme speed

CHARACTER (right profile): Runner in full sprint, ribbons trailing

?? 3-FRAME RUN CYCLE (SIDE VIEW - BEST FOR SHOWING SPEED):
- Frame 1: BACK LEG EXTENDED - Back leg extended FAR behind, front reaching forward, aggressive lean
- Frame 2: NEUTRAL - Legs together under body, still leaning forward
- Frame 3: FRONT LEG EXTENDED - Front leg extended FAR forward, nearly horizontal lean

ANIMATION NOTES:
- MAXIMUM LEG EXTENSION - show the speed through stride length
- This sprite will be FLIPPED HORIZONTALLY for Run Left
- Body leaned forward at aggressive angle
- Arms in running position

SECONDARY MOTION:
- Everything streams behind: hair, ribbons, wind effects
- Wind speed lines implied
- Light, barely-touching-ground feel

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner wind magic attack - FACING CAMERA

ART STYLE: Funko Pop/Chibi, tornado effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Arms sweeping back, wind gathering, hair rising
- Frame 2: CHANNEL - Spinning motion beginning, wind vortex forming around body
- Frame 3: RELEASE - Arms thrust forward, massive wind blade/tornado launching, extreme motion blur
- Frame 4: RECOVERY - Follow-through pose, residual wind spirals, ribbons settling

EFFECTS:
- Frame 1: Wind gathering, spiral patterns
- Frame 2: Tornado forming, everything spinning
- Frame 3: Wind explosion, blade shapes, motion lines everywhere
- Frame 4: Dissipating spirals, settling movement

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, wind dying down

ANIMATION SEQUENCE:
- Frame 1: HIT - Momentum stopped suddenly, hair and ribbons snapping forward from sudden stop
- Frame 2: STAGGER - Losing balance, wind dying, ribbons falling limp
- Frame 3: COLLAPSE - Falling, all movement stopping, stillness
- Frame 4: FALLEN - On ground, no wind, ribbons limp, desaturated colors, peaceful

EFFECTS:
- Frame 1: Sudden stop effect, whiplash on ribbons
- Frame 2: Wind fading, elements becoming still
- Frame 3: Last breeze fading
- Frame 4: Complete stillness, 80% opacity, no wind effects

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, disrupted wind

ANIMATION:
- Frame 1: IMPACT - Flinching, wind disrupted, ribbons chaotic, red damage flash
- Frame 2: RECOVERY - Returning to ready stance, wind restabilizing, determination

EFFECTS:
- Frame 1: Red tint overlay, scattered wind patterns
- Frame 2: Normal colors returning, wind reforming

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, constant wind movement

ANIMATION:
- Frame 1: INHALE - Light bounce on toes, wind swirling, ribbons floating up, playful energy
- Frame 2: EXHALE - Slight settle, wind calms slightly, ribbons drift, ready to sprint

EFFECTS:
- Constant subtle wind around them
- Ribbons never fully still
- Impatient, ready-to-run energy

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `wind_runner_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `wind_runner_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `wind_runner_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `wind_runner_cast_strip.png` |
| Death | 4 | 2000x500 | `wind_runner_death_strip.png` |
| Hit | 2 | 1000x500 | `wind_runner_hit_strip.png` |
| Idle | 2 | 1000x500 | `wind_runner_idle_strip.png` |

**Total: 21 frames**

---

## ?? Implementación en Godot

### Ciclo de animación Walk (ping-pong):
```gdscript
# Frames: 0, 1, 2, 1, 0, 1, 2, 1, 0...
# Usar animation con loop mode "Ping-Pong"
# Para Wind Runner: usar velocidad de animación MÁS RÁPIDA que otros personajes
```

### Walk Left:
```gdscript
sprite.flip_h = true  # cuando dirección es LEFT
sprite.flip_h = false # cuando dirección es RIGHT
```

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/wind_runner/
??? walk/
?   ??? wind_runner_walk_down_1.png - wind_runner_walk_down_3.png
?   ??? wind_runner_walk_up_1.png - wind_runner_walk_up_3.png
?   ??? wind_runner_walk_right_1.png - wind_runner_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
