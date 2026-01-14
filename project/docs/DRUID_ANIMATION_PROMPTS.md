# ?? Prompts para Animaciones del DRUID

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

---

## ?? GUÍA DE ESTILO - DRUID

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Mujer adulta |
| **Complexión** | Esbelta, grácil, conectada con la naturaleza |
| **Cabello** | Largo, verde oscuro con flores y hojas entrelazadas |
| **Expresión** | Serena, sabia, ojos verdes brillantes |
| **Túnica** | Verde bosque con patrones de hojas, hasta los pies |
| **Detalles** | Hojas flotando, pequeñas flores brotando, aura verde |
| **Arma** | Bastón de madera viva con brotes y hojas |

### Paleta de colores:
- **Túnica principal:** Verde bosque (#228B22)
- **Túnica sombras:** Verde oscuro (#006400)
- **Highlights:** Verde lima (#32CD32)
- **Hojas/Naturaleza:** Verde claro (#90EE90) a oscuro
- **Cabello:** Verde oscuro (#2E8B57) con flores rosas (#FFB6C1)
- **Piel:** Clara con tono verdoso (#F5F5DC)
- **Staff madera:** Marrón vivo (#8B4513) con brotes verdes
- **Outline:** Verde muy oscuro (#013220)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Druid - Adult Female, Nature Mage

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Bright green eyes with leaf reflections
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Graceful adult woman connected to nature
- Long dark green hair with small flowers and leaves woven in
- Serene, wise expression
- Eyes glow soft green
- Forest green robe with leaf patterns, flowing to feet
- Small leaves and petals floating around her
- Living wood staff with growing vines and leaves
- Barefoot or simple sandals

COLOR PALETTE:
- Robe: Forest green (#228B22) with dark shadows (#006400)
- Nature elements: Light green (#90EE90) to dark
- Hair: Dark green (#2E8B57) with pink flowers (#FFB6C1)
- Skin: Light with green tint (#F5F5DC)
- Staff: Living brown (#8B4513) with green shoots
- Outline: Very dark green (#013220)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `druid_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, oversized head, thick outline, cel-shading

CHARACTER: Female nature mage, green hair with flowers, forest robe, living wood staff

?? 3-FRAME WALK CYCLE:
- Frame 1: LEFT LEG OUT - Left leg stepped outward/forward, graceful stride, body tilt left
- Frame 2: NEUTRAL - Both legs together, standing serene, centered pose
- Frame 3: RIGHT LEG OUT - Right leg stepped outward/forward, flowing movement, body tilt right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3...
- Graceful, flowing walking motion
- Robe sways like leaves in wind

SECONDARY MOTION:
- Leaves and petals float around her
- Staff vines sway gently
- Hair flowers bob with movement

COLORS: Robe #228B22, Hair #2E8B57, Flowers #FFB6C1, Skin #F5F5DC

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking animation - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (from behind): Female druid, long green hair flowing, forest robe, staff

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward, graceful stride
- Frame 2: NEUTRAL - Both legs together, serene stance
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, flowing movement

SECONDARY MOTION:
- Hair and leaves trail behind
- Robe flows naturally
- Leaves drift around her path

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, thick outline, cel-shading

CHARACTER (right profile): Female druid, hair trailing, robe flowing, staff forward

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear leg back, front under body, gentle forward lean
- Frame 2: NEUTRAL - Both legs together, graceful stance
- Frame 3: FRONT LEG EXTENDED - Front leg forward, rear under body, flowing stride

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Robe and hair flow behind
- Leaves trail with movement
- Staff held gently forward

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid nature spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, nature magic effects

?? 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising staff, leaves and vines gathering, eyes glowing green
- Frame 2: CHANNEL - Staff raised high, nature energy spiraling, flowers blooming around
- Frame 3: RELEASE - Staff thrust forward, vine/thorn burst launching, petals exploding

EFFECTS:
- Frame 1: Leaves gathering, green glow
- Frame 2: Spiraling vines, blooming flowers
- Frame 3: Nature explosion, thorns and petals

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, nature wilting

?? 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, shocked, flowers wilting, leaves scattering
- Frame 2: COLLAPSE - Falling forward, all plants dying, staff falling
- Frame 3: FALLEN - On ground, wilted appearance, brown/gray colors, 80% opacity

EFFECTS:
- Frame 1: Leaves scattering, flowers wilting
- Frame 2: Plants dying, autumn colors
- Frame 3: Wilted, desaturated, transparency

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

?? 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching backward, red damage flash, leaves scattered
- Frame 2: RECOIL - Maximum flinch, flowers drooping, pain expression
- Frame 3: RECOVERY - Returning to stance, nature re-growing, determined

EFFECTS:
- Frame 1: Red tint overlay, leaves scattered
- Frame 2: Peak damage pose
- Frame 3: Normal colors, flowers re-blooming

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_hit_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `druid_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `druid_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `druid_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `druid_cast_strip.png` |
| Death | 3 | 1500x500 | `druid_death_strip.png` |
| Hit | 3 | 1500x500 | `druid_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/druid/
??? walk/
?   ??? druid_walk_down_1.png - druid_walk_down_3.png
?   ??? druid_walk_up_1.png - druid_walk_up_3.png
?   ??? druid_walk_right_1.png - druid_walk_right_3.png
??? cast/
?   ??? druid_cast_1.png - druid_cast_3.png
??? death/
?   ??? druid_death_1.png - druid_death_3.png
??? hit/
    ??? druid_hit_1.png - druid_hit_3.png
```
