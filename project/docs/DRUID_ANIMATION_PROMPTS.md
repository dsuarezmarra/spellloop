# ?? Prompts para Animaciones del DRUID

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

**MUY IMPORTANTE:** Al generar los frames de caminar:
1. **Los pies se muevan claramente** - Cada frame debe mostrar posición diferente de piernas
2. **Transición fluida** - 4 frames deben formar ciclo de caminata natural
3. **No solo mover la ropa** - El personaje debe DAR PASOS visibles
4. **Ciclo:** Frame 1: neutral ? Frame 2: pierna izquierda adelante ? Frame 3: cruzando ? Frame 4: pierna derecha adelante

---

## ?? GUÍA DE ESTILO - DRUID

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Mujer madura |
| **Complexión** | Curvilínea, maternal |
| **Cabello** | Largo castaño con hojas y flores entrelazadas |
| **Expresión** | Amable, serena, ojos verdes brillantes |
| **Vestimenta** | Túnica verde/marrón natural, con enredaderas vivas |
| **Detalles** | Pequeñas flores brotan de su ropa, hojas flotando |
| **Arma** | Bastón de madera viva con hojas brotando |

### Paleta de colores:
- **Túnica principal:** Verde bosque (#228B22)
- **Túnica sombras:** Verde oscuro (#006400)
- **Acentos marrón:** Marrón corteza (#8B4513)
- **Hojas/Detalles:** Verde lima (#32CD32) y dorado otoñal (#DAA520)
- **Flores:** Rosa suave (#FFB6C1) y blanco (#FFFFFF)
- **Cabello:** Castaño cálido (#8B6914)
- **Piel:** Bronceada cálida (#D4A574)
- **Staff madera:** Marrón vivo (#5D4037)
- **Outline:** Marrón muy oscuro (#2D1B0E)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Druid - Mature Female, Nature Guardian

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Big warm green eyes
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Mature woman with kind, motherly appearance
- Curvy, grounded build
- Long wavy brown hair with leaves and small flowers woven in
- Serene, gentle smile
- Bright green eyes with nature glow
- Green and brown natural fabric robe, mid-length
- Living vines wrapped around arms and robe
- Small flowers blooming on her clothing
- Wooden staff with living branches and leaves sprouting from top
- Barefoot or natural sandals
- Few floating leaves around her

COLOR PALETTE:
- Robe: Forest green (#228B22) with dark shadows (#006400)
- Brown accents: Bark brown (#8B4513)
- Leaves: Lime green (#32CD32) and golden autumn (#DAA520)
- Flowers: Soft pink (#FFB6C1) and white
- Hair: Warm brown (#8B6914)
- Skin: Warm tan (#D4A574)
- Staff: Living wood brown (#5D4037)
- Outline: Very dark brown (#2D1B0E)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `druid_reference.png`

---

## PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, nature theme, thick outline

CHARACTER: Mature female druid, brown hair with flowers, green robe, living wood staff

?? CRITICAL WALKING ANIMATION REQUIREMENTS:
- Frame 1: NEUTRAL - Feet together, standing calmly, leaves floating gently
- Frame 2: LEFT STEP - Left foot stepping forward clearly, sandal/bare foot visible, robe swaying
- Frame 3: PASSING - Feet crossing mid-stride, body in motion
- Frame 4: RIGHT STEP - Right foot forward, completing the step cycle
- SHOW CLEAR FOOT MOVEMENT - barefoot/sandals should be visible moving
- This is a grounded, connected-to-earth character - her steps should feel deliberate

SECONDARY MOTION:
- Flowers on robe gently bobbing
- Leaves floating around her following movement
- Staff leaves rustling
- Hair with flower accessories swaying
- Vines on arms shifting with arm swing

COLORS: Robe #228B22, Hair #8B6914, Skin #D4A574, Staff #5D4037

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking animation - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, nature theme

CHARACTER (from behind): Female druid, long brown hair with leaves/flowers, green robe, wooden staff

?? CRITICAL WALKING ANIMATION:
- Frame 1: NEUTRAL - Standing still from behind
- Frame 2: LEFT STEP - Left leg forward, robe parting to show step
- Frame 3: PASSING - Legs crossing, hair swaying
- Frame 4: RIGHT STEP - Right leg forward, completing cycle
- VISIBLE LEG MOVEMENT through robe

SECONDARY MOTION:
- Long hair swaying side to side
- Flowers in hair bobbing
- Floating leaves trailing behind
- Staff held in right hand

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_up_strip.png`

---

## PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, nature elements

CHARACTER (left profile): Female druid, hair flowing behind, staff in leading hand

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: NEUTRAL - Side standing pose
- Frame 2: BACK LEG PUSH - Rear foot pushing off, front reaching
- Frame 3: MID-STRIDE - Legs scissoring past each other
- Frame 4: FRONT LAND - Front foot landing, weight shifting
- EACH FRAME shows different leg position clearly

SECONDARY MOTION:
- Hair and flowers flow behind
- Leaves trail in wake
- Robe sways with walking rhythm
- Staff moves with arm swing

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_left_strip.png`

---

## PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid walking - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, nature elements

CHARACTER (right profile): Female druid, flowing hair, nature staff

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: NEUTRAL - Standing side view
- Frame 2: BACK LEG PUSH - Beginning stride
- Frame 3: MID-STRIDE - Legs crossing
- Frame 4: FRONT LAND - Step completing
- CLEAR LEG MOVEMENT in each frame

SECONDARY MOTION:
- Hair trails behind
- Floating leaves follow
- Gentle, grounded movement style

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_walk_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid spell casting - FACING CAMERA

ART STYLE: Funko Pop/Chibi, magical nature effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raising staff, leaves swirling upward, flowers on robe blooming brighter
- Frame 2: CHANNEL - Staff glowing green, nature energy spiraling, eyes glowing, more leaves materializing
- Frame 3: RELEASE - Staff thrust forward, burst of green energy and petals, magical seeds/orbs launching
- Frame 4: RECOVERY - Lowering staff, petals falling gently, serene satisfied expression

EFFECTS:
- Frame 1: Green sparkles gathering, leaves rising
- Frame 2: Swirling green energy, flower blooms, bright glow
- Frame 3: Explosion of petals and green magic, motion lines
- Frame 4: Petals falling like snow, gentle afterglow

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_cast_strip.png`

---

## PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, wilting nature theme

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, flowers wilting, leaves scattering
- Frame 2: STAGGER - Stumbling, vines loosening, colors beginning to brown/fade
- Frame 3: COLLAPSE - Falling, flowers dropping off, staff falling
- Frame 4: FALLEN - On ground, muted autumn colors, scattered petals around, peaceful expression

EFFECTS:
- Frame 1: Impact, flowers react by wilting
- Frame 2: Green colors shifting to yellow/brown
- Frame 3: Leaves falling off, final wilt
- Frame 4: Desaturated, slight transparency, fallen flowers around

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_death_strip.png`

---

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, nature reacting

ANIMATION:
- Frame 1: IMPACT - Flinching, flowers momentarily wilt, leaves scatter, pained but resilient expression
- Frame 2: RECOVERY - Returning to stance, flowers perking back up, determined maternal expression

EFFECTS:
- Frame 1: Red damage tint, flowers droop, leaves blown away
- Frame 2: Green returning, flowers recovering, new leaves forming

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Druid idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, peaceful nature

ANIMATION:
- Frame 1: INHALE - Slight rise, flowers open more, leaves float upward, serene
- Frame 2: EXHALE - Slight settle, flowers relax, leaves gently descend

EFFECTS:
- Constant slow leaf floating
- Flowers gently opening and closing
- Peaceful breathing rhythm
- Staff leaves rustling softly

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `druid_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `druid_walk_down_1.png` - `druid_walk_down_4.png` |
| Walk Up | 4 | `druid_walk_up_1.png` - `druid_walk_up_4.png` |
| Walk Left | 4 | `druid_walk_left_1.png` - `druid_walk_left_4.png` |
| Walk Right | 4 | `druid_walk_right_1.png` - `druid_walk_right_4.png` |
| Cast | 4 | `druid_cast_1.png` - `druid_cast_4.png` |
| Death | 4 | `druid_death_1.png` - `druid_death_4.png` |
| Hit | 2 | `druid_hit_1.png` - `druid_hit_2.png` |
| Idle | 2 | `druid_idle_1.png` - `druid_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/druid/
??? walk/
??? cast/
??? death/
??? hit/
```
