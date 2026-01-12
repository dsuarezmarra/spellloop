# ??? Prompts para Animaciones del WIND RUNNER

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

## ?? NOTA CRÍTICA SOBRE ANIMACIÓN DE CAMINAR

**MUY IMPORTANTE:** El Wind Runner es EL PERSONAJE MÁS RÁPIDO del juego.

Su animación de caminar debe reflejar esto:
1. **Pasos muy dinámicos** - Postura inclinada hacia adelante, corriendo más que caminando
2. **Mayor amplitud de zancada** - Piernas más separadas en cada paso
3. **Sensación de velocidad** - Ropa y pelo muy sueltos, ondeando hacia atrás
4. **Ligereza** - Parece apenas tocar el suelo

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

## PROMPT #1 - Walk/Run Down (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, dynamic movement, wind effects

CHARACTER: Androgynous wind mage, silver hair, white/cyan outfit, floating ribbons

?? THIS IS THE FASTEST CHARACTER - RUNNING NOT WALKING:
- Frame 1: READY - Light crouch, about to spring, ribbons pulled back
- Frame 2: LEFT SPRINT - Left leg far forward, right far back, leaning into run, huge stride
- Frame 3: AIRBORNE - Both feet nearly off ground, mid-sprint leap, maximum speed pose
- Frame 4: RIGHT SPRINT - Right leg forward, left back, continuing sprint
- EXAGGERATED LEG MOVEMENT - this character RUNS, not walks
- Body leans forward into movement
- Arms pumping or held back for aerodynamics

SECONDARY MOTION:
- Hair blown completely backward
- ALL ribbons streaming behind
- Wind spirals trailing from movement
- Tunic pressed against body from speed
- Wind effect lines behind character

COLORS: Tunic #F0FFF0, Hair #E8E8E8, Eyes #00CED1, Ribbons #40E0D0

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_down_strip.png`

---

## PROMPT #2 - Walk/Run Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, speed lines

CHARACTER (from behind): Silver-haired runner, ribbons streaming, wind effects

?? RUNNING ANIMATION (BACK VIEW):
- Frame 1: READY - Crouched start position
- Frame 2: LEFT SPRINT - Left leg forward (visible from behind), huge stride
- Frame 3: AIRBORNE - Mid-sprint, feet barely touching
- Frame 4: RIGHT SPRINT - Right leg forward, continuing speed
- SHOW RUNNING MOTION with exaggerated leg positions

SECONDARY MOTION:
- Hair streaming backward (toward camera)
- Ribbons flowing toward viewer
- Wind trail effects
- Dynamic running pose

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_up_strip.png`

---

## PROMPT #3 - Walk/Run Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, extreme speed

CHARACTER (left profile): Runner in full sprint, ribbons trailing

?? RUNNING ANIMATION (SIDE VIEW - BEST FOR SHOWING SPEED):
- Frame 1: READY - Coiled to spring
- Frame 2: PUSH OFF - Back leg extended far behind, front reaching forward
- Frame 3: FLIGHT PHASE - Both legs scissored wide, nearly horizontal lean
- Frame 4: LANDING - Front foot touching, continuing momentum
- MAXIMUM LEG EXTENSION - show the speed through stride length

SECONDARY MOTION:
- Everything streams behind: hair, ribbons, wind effects
- Body leaned forward at aggressive angle
- Arms in running position
- Wind speed lines

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_left_strip.png`

---

## PROMPT #4 - Walk/Run Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner RUNNING - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, speed emphasis

CHARACTER (right profile): Full sprint pose, streaming elements

?? RUNNING ANIMATION (SIDE VIEW):
- Frame 1: READY - About to launch
- Frame 2: PUSH OFF - Maximum extension
- Frame 3: FLIGHT - Mid-air sprint
- Frame 4: LANDING - Continuing motion
- WIDE STRIDES showing fastest character

SECONDARY MOTION:
- Speed lines behind
- All loose elements trailing
- Dynamic forward lean

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_walk_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

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

## PROMPT #6 - Death Animation (4 frames)

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

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, disrupted wind

ANIMATION:
- Frame 1: IMPACT - Knocked back, wind disrupted, ribbons tangled, surprised expression
- Frame 2: RECOVERY - Quick recovery (fastest character), wind re-forming, ready to run again

EFFECTS:
- Frame 1: Red flash, wind scattered, motion stopped
- Frame 2: Wind gathering again, speed returning, determined smile

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Wind Runner idle - FACING CAMERA

ART STYLE: Funko Pop/Chibi, restless energy

ANIMATION:
- Frame 1: Bouncing slightly on toes, ribbons floating upward, eager expression
- Frame 2: Other foot, ribbons floating differently, can't stand still

EFFECTS:
- Constant small wind around feet
- Ribbons always moving
- Impatient, wants to run
- Shifting weight foot to foot

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `wind_runner_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `wind_runner_walk_down_1.png` - `wind_runner_walk_down_4.png` |
| Walk Up | 4 | `wind_runner_walk_up_1.png` - `wind_runner_walk_up_4.png` |
| Walk Left | 4 | `wind_runner_walk_left_1.png` - `wind_runner_walk_left_4.png` |
| Walk Right | 4 | `wind_runner_walk_right_1.png` - `wind_runner_walk_right_4.png` |
| Cast | 4 | `wind_runner_cast_1.png` - `wind_runner_cast_4.png` |
| Death | 4 | `wind_runner_death_1.png` - `wind_runner_death_4.png` |
| Hit | 2 | `wind_runner_hit_1.png` - `wind_runner_hit_2.png` |
| Idle | 2 | `wind_runner_idle_1.png` - `wind_runner_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/wind_runner/
??? walk/
??? cast/
??? death/
??? hit/
```
