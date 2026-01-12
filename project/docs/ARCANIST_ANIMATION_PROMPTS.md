# ?? Prompts para Animaciones del ARCANIST

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #8** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? NOTA CRÍTICA SOBRE ANIMACIÓN DE CAMINAR

**MUY IMPORTANTE:** Al generar los frames de caminar:
1. **Los pies se muevan claramente** - Cada frame debe mostrar posición diferente de piernas
2. **Transición fluida** - 4 frames deben formar ciclo de caminata natural
3. **No solo mover la ropa** - El personaje debe DAR PASOS visibles
4. **Ciclo:** Frame 1: neutral ? Frame 2: pierna izquierda adelante ? Frame 3: cruzando ? Frame 4: pierna derecha adelante

---

## ?? GUÍA DE ESTILO - ARCANIST

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre mayor, sabio |
| **Complexión** | Delgada pero imponente |
| **Cabello** | Calvo con barba larga blanca, runas brillando en la piel |
| **Expresión** | Sereno, sabio, ojos brillantes arcanos |
| **Túnica** | Larga púrpura real con runas flotantes, capa amplia |
| **Detalles** | Orbes arcanos orbitando a su alrededor (2-3), símbolos mágicos |
| **Arma** | Orbe arcano flotante entre sus manos, bastón ceremonial |

### Paleta de colores:
- **Túnica principal:** Púrpura real (#5B2C6F)
- **Túnica sombras:** Púrpura oscuro (#2E1A47)
- **Runas/Orbes:** Cyan brillante (#00FFFF) y magenta (#FF00FF)
- **Detalles dorados:** Oro antiguo (#CFB53B)
- **Barba:** Blanco plateado (#E8E8E8)
- **Piel:** Pálida con tinte púrpura (#D4C4D4)
- **Orbe central:** Cyan con núcleo blanco (#00E5E5)
- **Outline:** Púrpura muy oscuro (#1A0A28)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Arcanist - Elderly Male, Arcane Scholar

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big wise eyes with arcane glow
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Elderly wise man, dignified posture
- Bald head with glowing arcane runes on scalp
- Long flowing white beard reaching chest
- Serene, knowing expression
- Long royal purple robe reaching the floor
- Wide sleeves with floating runic symbols
- 2-3 small arcane orbs orbiting around him
- Holds a glowing cyan orb between hands or ceremonial staff
- Golden trim and mystical patterns on robe

COLOR PALETTE:
- Robe: Royal purple (#5B2C6F) with dark shadows (#2E1A47)
- Runes/Orbs: Cyan (#00FFFF) and magenta (#FF00FF)
- Gold accents: Antique gold (#CFB53B)
- Beard: Silver white (#E8E8E8)
- Skin: Pale with purple tint (#D4C4D4)
- Orb: Cyan with white core (#00E5E5)
- Outline: Very dark purple (#1A0A28)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `arcanist_reference.png`

---

## PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Elderly male arcane wizard, bald with white beard, purple robe, floating orbs around him

?? CRITICAL WALKING ANIMATION REQUIREMENTS:
- Frame 1: NEUTRAL - Feet together beneath long robe, standing straight
- Frame 2: LEFT STEP - Left foot stepping forward (visible under robe), body leaning slightly
- Frame 3: PASSING - Mid-stride, robe swaying with motion
- Frame 4: RIGHT STEP - Right foot forward, beard and robe flowing
- SHOW THE FEET MOVING under the robe hem - the robe should reveal leg motion
- Long robes don't hide walking - they sway and reveal steps

SECONDARY MOTION:
- Orbiting arcane orbs continue circular motion through all frames
- Beard sways gently with movement
- Runic symbols pulse subtly
- Robe hem reveals foot steps

COLORS: Robe #5B2C6F, Orbs #00FFFF/#FF00FF, Beard #E8E8E8

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking animation - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Elderly wizard, bald head with runes, long white beard tips visible, purple flowing robe

?? CRITICAL WALKING ANIMATION:
- Frame 1: NEUTRAL - Robe hanging still
- Frame 2: LEFT STEP - Robe parts showing left leg forward
- Frame 3: PASSING - Robe swaying as legs cross
- Frame 4: RIGHT STEP - Right leg visible under robe
- THE ROBE SHOULD SWAY revealing walking motion underneath

SECONDARY MOTION:
- Orbs continue orbiting (visible from behind)
- Robe flows with each step
- Glowing runes on bald head visible from back

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_up_strip.png`

---

## PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (left profile): Elderly wizard, beard profile, purple robe, orbs orbiting

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: NEUTRAL - Standing side view
- Frame 2: BACK LEG PUSH - Rear leg pushing off, front reaching forward under robe
- Frame 3: MID-STRIDE - Legs crossing, robe swaying backward
- Frame 4: FRONT LAND - Front leg landing, robe settling
- EACH FRAME must show different leg positions despite long robe

SECONDARY MOTION:
- Beard flows with movement
- Orbs trail behind slightly then catch up
- Robe billows with motion

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_left_strip.png`

---

## PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist walking - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Elderly wizard, beard profile, purple robe, orbs around him

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: NEUTRAL - Standing
- Frame 2: BACK LEG PUSH - Legs beginning stride
- Frame 3: MID-STRIDE - Legs scissoring
- Frame 4: FRONT LAND - Completing step
- VISIBLE LEG MOTION through/under robe

SECONDARY MOTION:
- Beard trails with movement
- Orbs orbit continuously
- Robe flows opposite to movement

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_walk_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, heavy magical effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raises hands, all orbs converging to center, gathering energy
- Frame 2: CHANNEL - Orbs merge into one large orb, runic circles appearing around him, eyes glowing
- Frame 3: RELEASE - Massive arcane blast from merged orb, runic explosion, bright flash
- Frame 4: RECOVERY - Orbs separating back to orbit, residual magic fading, serene expression

EFFECTS:
- Frame 1: Orbs pulling together, growing brighter
- Frame 2: Giant unified orb, magic circles, intense glow
- Frame 3: Explosion of cyan/magenta energy, motion lines
- Frame 4: Orbs returning to normal orbit, sparkles fading

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_cast_strip.png`

---

## PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, colors fading

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, orbs scatter chaotically, surprised expression
- Frame 2: STAGGER - Stumbling, orbs flickering and dimming, runes fading
- Frame 3: COLLAPSE - Falling forward, orbs dissolving, eyes closing peacefully
- Frame 4: FALLEN - On ground, all magic gone, desaturated colors, orbs disappeared

EFFECTS:
- Frame 1: Orbs disrupted, flash of impact
- Frame 2: Magic destabilizing, colors beginning to fade
- Frame 3: Last wisps of magic dissipating
- Frame 4: No magic, slight transparency (80% opacity)

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_death_strip.png`

---

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage effect

ANIMATION:
- Frame 1: IMPACT - Flinching, orbs scatter defensively, barrier shimmer, pained expression
- Frame 2: RECOVERY - Returning to stance, orbs reforming orbit, determined expression

EFFECTS:
- Frame 1: Red damage flash, orbs disrupted, faint shield shimmer
- Frame 2: Orbs returning to position, magic stabilizing

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Arcanist idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, subtle magical animation

ANIMATION:
- Frame 1: INHALE - Slight rise, orbs higher in orbit, runes brighter
- Frame 2: EXHALE - Slight settle, orbs lower in orbit, runes dimmer

EFFECTS:
- Orbs continuously orbit (different positions each frame)
- Subtle rune pulsing
- Beard gently swaying

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `arcanist_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `arcanist_walk_down_1.png` - `arcanist_walk_down_4.png` |
| Walk Up | 4 | `arcanist_walk_up_1.png` - `arcanist_walk_up_4.png` |
| Walk Left | 4 | `arcanist_walk_left_1.png` - `arcanist_walk_left_4.png` |
| Walk Right | 4 | `arcanist_walk_right_1.png` - `arcanist_walk_right_4.png` |
| Cast | 4 | `arcanist_cast_1.png` - `arcanist_cast_4.png` |
| Death | 4 | `arcanist_death_1.png` - `arcanist_death_4.png` |
| Hit | 2 | `arcanist_hit_1.png` - `arcanist_hit_2.png` |
| Idle | 2 | `arcanist_idle_1.png` - `arcanist_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/arcanist/
??? walk/
??? cast/
??? death/
??? hit/
```
