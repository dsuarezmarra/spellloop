# ? Prompts para Animaciones del PALADIN

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

---

## ?? GUÍA DE ESTILO - PALADIN

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre adulto, noble |
| **Complexión** | Atlético, musculoso pero elegante |
| **Cabello** | Rubio dorado, corto y ordenado |
| **Expresión** | Noble, justo, ojos brillando con luz divina |
| **Vestimenta** | Armadura blanca/dorada, capa blanca |
| **Detalles** | Símbolos sagrados, halo sutil, aura luminosa |
| **Arma** | Espada de luz o cetro sagrado |

### Paleta de colores:
- **Armadura:** Blanco plateado (#F5F5F5)
- **Detalles dorados:** Oro brillante (#FFD700)
- **Capa:** Blanco puro (#FFFFFF) con bordes dorados
- **Luz/Aura:** Amarillo suave (#FFFACD) a blanco
- **Cabello:** Rubio dorado (#DAA520)
- **Piel:** Bronceada clara (#DEB887)
- **Ojos:** Azul cielo brillante (#87CEEB)
- **Outline:** Dorado oscuro (#B8860B)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Paladin - Adult Male, Holy Warrior

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Bright blue eyes with holy glow
- Thick outline (2-3px) in golden brown
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Adult man with noble, heroic appearance
- Athletic, well-built but not bulky
- Short neat golden blonde hair
- Righteous, determined expression
- Bright glowing blue eyes
- White and gold plate armor (stylized, not realistic)
- Flowing white cape with golden trim
- Subtle halo or light aura above/behind head
- Holy symbols engraved on armor (sun, star patterns)
- Glowing sword of light OR sacred scepter as weapon
- Boots visible under short battle skirt/tabard

COLOR PALETTE:
- Armor: Silver white (#F5F5F5)
- Gold details: Bright gold (#FFD700)
- Cape: Pure white (#FFFFFF) with gold edges
- Light/Aura: Soft yellow (#FFFACD) to white
- Hair: Golden blonde (#DAA520)
- Skin: Light tan (#DEB887)
- Eyes: Bright sky blue (#87CEEB)
- Outline: Dark gold (#B8860B)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `paladin_reference.png`

---

## PROMPT #1 - Walk Down (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, holy warrior, glowing effects

CHARACTER: Noble paladin, gold/white armor, white cape, blonde hair, light aura

? 3-FRAME WALK CYCLE (BINDING OF ISAAC STYLE):
- Frame 1: LEFT LEG OUT - Left armored boot stepped outward/forward, right leg straight, slight body tilt left
- Frame 2: NEUTRAL - Both feet together, standing tall and proud, centered pose
- Frame 3: RIGHT LEG OUT - Right armored boot stepped outward/forward, left leg straight, slight body tilt right

ANIMATION NOTES:
- This creates a dignified waddling walk when played as: 1-2-3-2-1-2-3...
- SHOW ARMORED BOOTS clearly stepping - he's a warrior, not floating
- Posture always upright and proud
- Military/knightly walking rhythm

SECONDARY MOTION:
- Cape flows gracefully with each step
- Subtle light aura pulses with movement
- Holy symbols on armor glow faintly
- Sword/scepter held steadily at side

COLORS: Armor #F5F5F5, Gold #FFD700, Cape #FFFFFF, Hair #DAA520, Aura #FFFACD

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, cape prominently visible

CHARACTER (from behind): White/gold armored warrior, flowing white cape, blonde hair

? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward (boot visible), cape parting
- Frame 2: NEUTRAL - Both feet together, standing tall from behind
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, cape settling

ANIMATION NOTES:
- Mirror the front walk cycle but from behind
- ARMORED BOOTS visible with each step
- Keep noble dignified posture

SECONDARY MOTION:
- Cape dramatically billows showing back
- Halo visible from behind as soft glow
- Armor gleams with holy light

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames) - Estilo Binding of Isaac

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, noble profile

CHARACTER (right profile): Armored paladin, cape trailing, weapon visible

? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear armored boot pushing back, front leg under body, slight forward lean
- Frame 2: NEUTRAL - Both legs together under body, upright noble stance
- Frame 3: FRONT LEG EXTENDED - Front boot forward, rear leg under body, slight forward lean

ANIMATION NOTES:
- Side view shows the forward/backward leg motion
- Character maintains proud posture even while walking
- This sprite will be FLIPPED HORIZONTALLY for Walk Left
- SHOW CLEAR LEG MOVEMENT - armored legs visible

SECONDARY MOTION:
- Cape streams behind
- Weapon held at ready
- Light aura trails slightly

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin holy magic smite - FACING CAMERA

ART STYLE: Funko Pop/Chibi, divine light effects

ANIMATION SEQUENCE:
- Frame 1: PRAY - Raising weapon to sky, closing eyes, light gathering above
- Frame 2: CHANNEL - Eyes open glowing bright, divine light pouring down, halo intensifying
- Frame 3: SMITE - Weapon thrust forward/down, massive beam of holy light, blinding flash
- Frame 4: RECOVERY - Lowering weapon, light fading to sparkles, righteous expression

EFFECTS:
- Frame 1: Light gathering above
- Frame 2: Divine rays, glowing eyes
- Frame 3: Holy explosion, bright beam
- Frame 4: Settling sparkles

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_cast_strip.png`

---

## PROMPT #5 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, light fading

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, shocked, halo flickering
- Frame 2: STAGGER - Stumbling, weapon loosening, light dimming
- Frame 3: COLLAPSE - Falling to knees, aura fading
- Frame 4: FALLEN - On ground, light gone, desaturated, peaceful expression

EFFECTS:
- Frame 1: Light disrupted
- Frame 2: Aura sputtering
- Frame 3: Last glow fading
- Frame 4: Slight transparency (80% opacity)

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_death_strip.png`

---

## PROMPT #6 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

ANIMATION:
- Frame 1: IMPACT - Flinching, armor clanking, red damage flash, aura disrupted
- Frame 2: RECOVERY - Standing firm, determined expression, aura restabilizing

EFFECTS:
- Frame 1: Red tint overlay, light scattered
- Frame 2: Normal colors returning, righteous stance

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_hit_strip.png`

---

## PROMPT #7 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, steady holy glow

ANIMATION:
- Frame 1: INHALE - Slight chest expansion, aura brightening, standing proud
- Frame 2: EXHALE - Relaxed, aura dims slightly, vigilant stance

EFFECTS:
- Subtle halo pulse
- Cape gentle sway
- Noble readiness

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `paladin_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `paladin_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `paladin_walk_right_strip.png` |
| Cast | 4 | 2000x500 | `paladin_cast_strip.png` |
| Death | 4 | 2000x500 | `paladin_death_strip.png` |
| Hit | 2 | 1000x500 | `paladin_hit_strip.png` |
| Idle | 2 | 1000x500 | `paladin_idle_strip.png` |

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
project/assets/sprites/players/paladin/
??? walk/
?   ??? paladin_walk_down_1.png - paladin_walk_down_3.png
?   ??? paladin_walk_up_1.png - paladin_walk_up_3.png
?   ??? paladin_walk_right_1.png - paladin_walk_right_3.png
??? cast/
??? death/
??? hit/
??? idle/
```
