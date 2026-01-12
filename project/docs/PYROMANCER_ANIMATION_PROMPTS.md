# ?? Prompts para Animaciones del PYROMANCER (Fire Mage)

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes (DALL-E, Midjourney, etc.) NO pueden generar todos los sprites de una vez.**

### Estrategia recomendada:
1. **DALL-E/ChatGPT:** Genera 1 imagen por prompt. Necesitarás ejecutar cada prompt por separado.
2. **Midjourney:** Genera 4 variaciones por prompt (útil para los 4 frames de walk).

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #11** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? NOTA CRÍTICA SOBRE ANIMACIÓN DE CAMINAR

**MUY IMPORTANTE:** Al generar los frames de caminar, es ESENCIAL que:
1. **Los pies se muevan claramente** - Cada frame debe mostrar una posición diferente de las piernas
2. **Transición fluida** - Los 4 frames deben formar un ciclo de caminata natural
3. **No solo mover la ropa** - El personaje debe DAR PASOS visibles, no solo balancearse
4. **Pierna adelante/atrás** - Frame 1: neutral, Frame 2: pierna izquierda adelante, Frame 3: cruzando, Frame 4: pierna derecha adelante

---

## ?? GUÍA DE ESTILO - PYROMANCER

### Características visuales del estilo Funko Pop/Cartoon:

| Característica | Descripción |
|----------------|-------------|
| **Proporciones** | Cabeza grande (~30% del cuerpo), cuerpo compacto estilizado |
| **Formas** | Redondeadas y suaves, evitar ángulos agudos |
| **Ojos** | Grandes, expresivos, brillantes con reflejos de fuego |
| **Outlines** | Contorno oscuro grueso (2-3px), ~20-25% de píxeles oscuros |
| **Colores** | Saturados y vibrantes (~85% saturación), paleta cálida |
| **Sombreado** | Cel-shading simple (2-3 niveles de sombra), luz desde arriba-izquierda |
| **Detalles** | Llamas sutiles en bordes de ropa, runas de fuego brillantes |
| **Expresiones** | Determinado pero no malvado, intenso pero carismático |

### Paleta de colores del Pyromancer:
- **Túnica principal:** Rojo carmesí (#C41E3A)
- **Túnica sombras:** Rojo oscuro/borgoña (#8B0000)
- **Túnica highlights:** Naranja brillante (#FF6B35)
- **Detalles dorados:** Oro (#FFD700)
- **Piel:** Bronceada cálida (#D4A574)
- **Cabello:** Negro azabache con reflejos rojizos (#1A0A0A con #4A0A0A)
- **Staff cristal:** Ámbar/Naranja incandescente (#FF8C00)
- **Staff madera:** Madera oscura quemada (#3D2314)
- **Llamas decorativas:** Gradiente naranja-amarillo (#FF4500 a #FFD700)
- **Outline:** Negro rojizo muy oscuro (#1A0A0A)

### Diferencias visuales con el Frost Mage:
- **Más joven** - Adulto joven en lugar de anciano, sin barba
- **Más dinámico** - Pose más agresiva/confiada
- **Cabello corto/medio** - Peinado hacia atrás por el calor
- **Túnica más corta** - Hasta las rodillas, más práctica para combate
- **Efectos de fuego** - Pequeñas llamas en los bordes de la ropa
- **Complexión atlética** - Más musculoso que el mago tradicional

---

# ?? LISTA DE PROMPTS (Ejecutar en orden)

---

## PROMPT #0 - Referencia de Estilo (EJECUTAR PRIMERO)

> **Propósito:** Establece el diseño base del personaje. Guarda esta imagen como referencia.

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Fire Mage / Pyromancer - Young Adult Male

ART STYLE (CRITICAL - FOLLOW EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized head (approximately 30% of total body height)
- Big expressive eyes with fire reflection highlights
- Rounded, soft shapes - NO sharp angles
- Thick dark outline (2-3 pixels) around all forms
- Cel-shading with 2-3 shadow levels
- Bold saturated warm colors
- Simple but charming details
- Confident and intense but not evil appearance

DESIGN DETAILS:
- Young adult male with athletic build
- Short swept-back dark hair with subtle red highlights
- Determined expression, slight smirk
- Crimson red hooded robe reaching to knees (shorter than wizard's)
- Hood down, showing face and hair
- Golden trim and fire rune patterns on robe edges
- Ornate dark wood staff with glowing amber crystal tip
- Small decorative flames flickering at robe hem
- Staff held confidently in right hand
- Tanned/bronze skin tone

COLOR PALETTE:
- Robe: Crimson red (#C41E3A) with dark red shadows (#8B0000)
- Robe highlights/trim: Bright orange (#FF6B35)
- Gold accents: (#FFD700)
- Skin: Warm bronze (#D4A574)
- Hair: Black with red tints (#1A0A0A / #4A0A0A)
- Staff crystal: Incandescent amber-orange (#FF8C00)
- Staff wood: Dark burnt wood (#3D2314)
- Flame effects: Orange to yellow gradient (#FF4500 to #FFD700)
- Outline: Very dark red-black (#1A0A0A)

LAYOUT: Show character from 4 angles in a 2x2 grid:
- Top-left: Front view (facing camera)
- Top-right: Back view (facing away)
- Bottom-left: Left side profile
- Bottom-right: Right side profile

OUTPUT: Single 1024x1024 image, transparent/checkered background, consistent proportions and colors across all 4 views.
```

?? **Guardar como:** `pyromancer_reference.png` (solo referencia, no se usa en el juego)

---

## ?? ANIMACIONES DE CAMINAR (Walk)

---

### PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer walking animation - FACING CAMERA (walking downward)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Big expressive eyes with fire reflection
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated warm colors
- Rounded soft shapes, NO sharp angles

CHARACTER DESIGN:
- Young adult male, athletic build
- Crimson red hooded robe (knee length), hood down
- Short dark hair swept back with red highlights
- Confident expression
- Dark wood staff with glowing amber crystal
- Golden trim on robe with fire rune patterns
- Small flames at robe hem

ANIMATION (4 frames, left to right):
- Frame 1: Neutral standing pose, feet together
- Frame 2: Left foot stepping forward, robe swaying, flames flicker
- Frame 3: Feet passing each other mid-stride
- Frame 4: Right foot stepping forward, robe swaying opposite

COLORS: Robe #C41E3A, Skin #D4A574, Hair #1A0A0A, Crystal #FF8C00, Flames #FF4500, Outline #1A0A0A

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_walk_down_strip.png`
?? **Cortar en:** `pyromancer_walk_down_1.png` a `pyromancer_walk_down_4.png`

---

### PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer walking animation - BACK TO CAMERA (walking upward/away)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated warm colors
- Rounded soft shapes

CHARACTER DESIGN (from behind):
- Crimson red hooded robe, hood down visible from back
- Short dark hair with red highlights
- Robe flowing with walking movement
- Staff held in right hand, visible from behind
- Golden trim and fire patterns on robe back
- Small flames at robe hem trailing with movement

ANIMATION (4 frames, left to right):
- Frame 1: Neutral standing pose from behind
- Frame 2: Left foot stepping forward, robe trailing
- Frame 3: Feet crossing mid-stride
- Frame 4: Right foot stepping forward

COLORS: Robe #C41E3A, Hair #1A0A0A, Crystal glow #FF8C00, Flames #FF4500, Outline #1A0A0A

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_walk_up_strip.png`
?? **Cortar en:** `pyromancer_walk_up_1.png` a `pyromancer_walk_up_4.png`

---

### PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer walking animation - LEFT SIDE PROFILE (walking left)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated warm colors

CHARACTER DESIGN (left profile):
- Crimson red robe visible from side
- Dark hair profile with swept-back style
- Staff in right hand (closer to camera)
- Athletic stance, confident posture
- Robe flows behind during movement
- Flames trail at hem

ANIMATION (4 frames, left to right):
- Frame 1: Standing profile, neutral
- Frame 2: Back leg pushing off, leaning into walk
- Frame 3: Mid-stride, legs crossing
- Frame 4: Front leg landing, robe swaying

COLORS: Robe #C41E3A, Skin #D4A574, Hair #1A0A0A, Crystal #FF8C00, Outline #1A0A0A

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_walk_left_strip.png`
?? **Cortar en:** `pyromancer_walk_left_1.png` a `pyromancer_walk_left_4.png`

---

### PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer walking animation - RIGHT SIDE PROFILE (walking right)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated warm colors

CHARACTER DESIGN (right profile):
- Crimson red robe visible from side
- Dark hair profile, swept-back style
- Staff in right hand (further from camera)
- Athletic stance, confident posture
- Robe flows behind during movement

ANIMATION (4 frames, left to right):
- Frame 1: Standing profile, neutral
- Frame 2: Back leg pushing off
- Frame 3: Mid-stride, legs crossing
- Frame 4: Front leg landing

COLORS: Robe #C41E3A, Skin #D4A574, Hair #1A0A0A, Crystal #FF8C00, Outline #1A0A0A

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_walk_right_strip.png`
?? **Cortar en:** `pyromancer_walk_right_1.png` a `pyromancer_walk_right_4.png`

---

## ? ANIMACIÓN DE CASTEO (Cast)

---

### PROMPT #5 - Cast Animation (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer spell casting animation - FACING CAMERA

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized head, big expressive eyes
- Thick dark outline (2-3px)
- Cel-shading, bold warm colors
- Dramatic fire magic effects

CHARACTER: Young fire mage in crimson robe, dark hair

ANIMATION SEQUENCE (4 frames, left to right):
- Frame 1: CHARGE - Staff raised, crystal beginning to glow orange, small embers forming
- Frame 2: CHANNEL - Both hands on staff, intense amber glow, fire swirling around crystal
- Frame 3: RELEASE - Staff thrust forward, fireball launching, bright flash of orange-yellow
- Frame 4: RECOVERY - Lowering staff, residual flames and embers dispersing, satisfied expression

MAGIC EFFECTS:
- Frame 1: Orange sparkles and small embers around crystal
- Frame 2: Spiral of fire energy around staff, eyes reflecting flames
- Frame 3: Explosion of orange-yellow fire from crystal tip, motion blur
- Frame 4: Trailing flames, cooling embers, smoke wisps

COLORS: Robe #C41E3A, Skin #D4A574, Crystal #FF8C00, Fire #FF4500 to #FFD700, Outline #1A0A0A

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_cast_strip.png`
?? **Cortar en:** `pyromancer_cast_1.png` a `pyromancer_cast_4.png`

---

## ?? ANIMACIÓN DE MUERTE (Death)

---

### PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer death animation - FACING CAMERA

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized head, expressive even in defeat
- Thick dark outline (2-3px)
- Cel-shading, colors desaturating through animation
- Dramatic but not gory

ANIMATION SEQUENCE (4 frames, left to right):
- Frame 1: HIT - Recoiling from impact, shocked expression, staff loosening from grip
- Frame 2: STAGGER - Stumbling backward, flames on robe flickering and dying, staff falling
- Frame 3: COLLAPSE - Knees buckling, falling forward, all flames extinguished
- Frame 4: FALLEN - Lying on ground, faded colors, staff beside body, embers turning to ash

VISUAL EFFECTS:
- Frame 1: Impact flash, flames disrupted
- Frame 2: Flames sputtering out, colors beginning to desaturate
- Frame 3: Last flames dying, motion blur on fall
- Frame 4: Slight transparency (80% opacity), ash particles floating up

COLORS: Start with normal palette, progressively desaturate. Final frame ~70% saturation.

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_death_strip.png`
?? **Cortar en:** `pyromancer_death_1.png` a `pyromancer_death_4.png`

---

## ?? ANIMACIÓN DE GOLPE RECIBIDO (Hit)

---

### PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer taking damage animation - FACING CAMERA

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized head, pained expression
- Thick dark outline (2-3px)
- Cel-shading, slight red flash effect

ANIMATION SEQUENCE (2 frames, left to right):
- Frame 1: IMPACT - Flinching backward, eyes squinted in pain, red damage flash overlay, flames disrupted
- Frame 2: RECOVERY - Returning to stance, determined expression, flames stabilizing, slight forward lean ready to fight

VISUAL EFFECTS:
- Frame 1: Red tint overlay (multiply blend), white impact lines, flames scattered
- Frame 2: Normal colors returning, embers resettling

COLORS: Robe #C41E3A with red flash, Skin #D4A574, damage flash overlay subtle red tint

OUTPUT: Horizontal strip 1000x500 pixels (2 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_hit_strip.png`
?? **Cortar en:** `pyromancer_hit_1.png`, `pyromancer_hit_2.png`

---

## ?? IDLE ANIMATION (Opcional)

---

### PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Fire Mage/Pyromancer idle/breathing animation - FACING CAMERA

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Subtle breathing movement
- Thick dark outline (2-3px)
- Cel-shading, living fire effects

ANIMATION SEQUENCE (2 frames, left to right):
- Frame 1: INHALE - Slight chest expansion, staff crystal glowing steadily, flames at hem rising slightly
- Frame 2: EXHALE - Slight chest contraction, flames settle down, relaxed but alert stance

VISUAL EFFECTS:
- Subtle flame flicker on robe hem
- Crystal glow pulsing gently
- Hair slightly affected by heat shimmer

COLORS: Robe #C41E3A, Skin #D4A574, Crystal #FF8C00 pulsing, Flames #FF4500

OUTPUT: Horizontal strip 1000x500 pixels (2 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `pyromancer_idle_strip.png`
?? **Cortar en:** `pyromancer_idle_1.png`, `pyromancer_idle_2.png`

---

## ?? RESUMEN DE ARCHIVOS NECESARIOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `pyromancer_walk_down_1.png` - `pyromancer_walk_down_4.png` |
| Walk Up | 4 | `pyromancer_walk_up_1.png` - `pyromancer_walk_up_4.png` |
| Walk Left | 4 | `pyromancer_walk_left_1.png` - `pyromancer_walk_left_4.png` |
| Walk Right | 4 | `pyromancer_walk_right_1.png` - `pyromancer_walk_right_4.png` |
| Cast | 4 | `pyromancer_cast_1.png` - `pyromancer_cast_4.png` |
| Death | 4 | `pyromancer_death_1.png` - `pyromancer_death_4.png` |
| Hit | 2 | `pyromancer_hit_1.png` - `pyromancer_hit_2.png` |
| Idle | 2 | `pyromancer_idle_1.png` - `pyromancer_idle_2.png` |

**Total: 28 frames** (26 obligatorios + 2 idle opcionales)

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/pyromancer/
??? walk/
?   ??? pyromancer_walk_down_1.png
?   ??? pyromancer_walk_down_2.png
?   ??? ...
?   ??? pyromancer_walk_right_4.png
??? cast/
?   ??? pyromancer_cast_1.png
?   ??? ...
??? death/
?   ??? pyromancer_death_1.png
?   ??? ...
??? hit/
?   ??? pyromancer_hit_1.png
?   ??? pyromancer_hit_2.png
??? idle/
    ??? pyromancer_idle_1.png
    ??? pyromancer_idle_2.png
```

---

## ?? Post-procesado

Después de generar los sprites, usar el script de procesamiento:
```bash
python utils/process_wizard_sprites.py --character pyromancer
```

Esto:
1. Normaliza tamaños a 500x500
2. Centra los sprites
3. Optimiza la transparencia
4. Genera los archivos `.import` para Godot
