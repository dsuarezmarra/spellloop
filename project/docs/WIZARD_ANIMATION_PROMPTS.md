# ?? Prompts para Animaciones del Wizard

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

## ?? GUÍA DE ESTILO - SPELLLOOP (MUY IMPORTANTE)

### Características visuales del estilo Funko Pop/Cartoon:

| Característica | Descripción |
|----------------|-------------|
| **Proporciones** | Cabeza grande (~30% del cuerpo), cuerpo compacto estilizado |
| **Formas** | Redondeadas y suaves, evitar ángulos agudos |
| **Ojos** | Grandes, expresivos, brillantes (estilo anime/cartoon) |
| **Outlines** | Contorno oscuro grueso (2-3px), ~20-25% de píxeles oscuros |
| **Colores** | Saturados y vibrantes (~85% saturación), paleta limitada |
| **Sombreado** | Cel-shading simple (2-3 niveles de sombra), luz desde arriba-izquierda |
| **Detalles** | Simplificados pero expresivos, sin texturas realistas |
| **Expresiones** | Cute/adorable incluso en personajes serios |

### Paleta de colores del Wizard actual:
- **Túnica principal:** Azul profundo (#4A7A9C)
- **Túnica sombras:** Azul oscuro (#3A5A7C)
- **Túnica highlights:** Azul claro (#6A9ABC)
- **Piel:** Beige cálido (#E8D4B8)
- **Barba/Pelo:** Blanco grisáceo (#E0E0E0)
- **Staff cristal:** Cian brillante (#66CCFF)
- **Staff madera:** Marrón (#8B6914)
- **Outline:** Negro/Gris muy oscuro (#1A1A2E)

### Referencias de estilo (buscar en Google):
- "Funko Pop wizard"
- "Chibi mage character"
- "Cute cartoon wizard game sprite"
- "Vampire Survivors character style"

---

# ?? LISTA DE PROMPTS (Ejecutar en orden)

---

## PROMPT #0 - Referencia de Estilo (EJECUTAR PRIMERO)

> **Propósito:** Establece el diseño base del personaje. Guarda esta imagen como referencia.

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Fantasy Wizard/Mage

ART STYLE (CRITICAL - FOLLOW EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized head (approximately 30% of total body height)
- Big cute expressive eyes with shine highlights
- Rounded, soft shapes - NO sharp angles
- Thick dark outline (2-3 pixels) around all forms
- Cel-shading with 2-3 shadow levels
- Bold saturated colors
- Simple but charming details
- Friendly and cute appearance even for a wise old wizard

DESIGN DETAILS:
- Long flowing purple-blue hooded robe reaching to feet
- Large hood partially shadowing face
- Long white/silver beard (stylized, not realistic)
- Kind elderly face with rosy cheeks
- Ornate wooden magical staff with glowing cyan crystal tip
- Staff held in right hand
- Robe has subtle magical rune patterns

COLOR PALETTE:
- Robe: Deep blue (#4A7A9C) with darker shadows (#3A5A7C)
- Skin: Warm beige (#E8D4B8)
- Beard: Light gray-white (#E0E0E0)
- Staff crystal: Bright cyan glow (#66CCFF)
- Staff wood: Warm brown (#8B6914)
- Outline: Very dark blue-black (#1A1A2E)

LAYOUT: Show character from 4 angles in a 2x2 grid:
- Top-left: Front view (facing camera)
- Top-right: Back view (facing away)
- Bottom-left: Left side profile
- Bottom-right: Right side profile

OUTPUT: Single 1024x1024 image, transparent/checkered background, consistent proportions and colors across all 4 views.
```

?? **Guardar como:** `wizard_reference.png` (solo referencia, no se usa en el juego)

---

## ?? ANIMACIONES DE CAMINAR (Walk)

---

### PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character walking animation - FACING CAMERA (walking downward)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Big expressive eyes with shine
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated colors
- Rounded soft shapes, NO sharp angles

CHARACTER DESIGN:
- Purple-blue hooded wizard robe, flowing with movement
- Long white stylized beard
- Wooden staff with glowing cyan crystal
- Kind elderly face, rosy cheeks
- Hood partially covering head

ANIMATION (4 frames, left to right):
- Frame 1: Neutral standing pose, feet together
- Frame 2: Left foot stepping forward, robe swaying right
- Frame 3: Feet passing each other mid-stride
- Frame 4: Right foot stepping forward, robe swaying left

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Crystal #66CCFF, Outline #1A1A2E

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `wizard_walk_down_strip.png`
?? **Cortar en:** `wizard_walk_down_1.png`, `wizard_walk_down_2.png`, `wizard_walk_down_3.png`, `wizard_walk_down_4.png`

---

### PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character walking animation - BACK TO CAMERA (walking upward/away)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated colors
- Rounded soft shapes

CHARACTER DESIGN (from behind):
- Purple-blue hooded wizard robe, hood up visible from back
- Robe flowing with walking movement
- Staff held in right hand, visible from behind
- White beard peeking from sides

ANIMATION (4 frames, left to right):
- Frame 1: Neutral standing pose from behind
- Frame 2: Left foot stepping forward, robe trailing
- Frame 3: Feet crossing mid-stride
- Frame 4: Right foot stepping forward

COLORS: Robe #4A7A9C, Beard #E0E0E0, Crystal glow #66CCFF, Outline #1A1A2E

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `wizard_walk_up_strip.png`
?? **Cortar en:** `wizard_walk_up_1.png`, `wizard_walk_up_2.png`, `wizard_walk_up_3.png`, `wizard_walk_up_4.png`

---

### PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character walking animation - LEFT SIDE PROFILE (walking left)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Big expressive eye visible in profile
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated colors
- Rounded soft shapes

CHARACTER DESIGN (side view):
- Purple-blue hooded wizard robe flowing behind
- Long white beard in profile
- Staff held in leading hand
- Hood partially visible
- Rosy cheek visible

ANIMATION (4 frames, left to right):
- Frame 1: Neutral standing side pose
- Frame 2: Front leg stepping forward, robe trailing behind
- Frame 3: Legs crossing mid-stride
- Frame 4: Back leg coming forward

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Crystal #66CCFF, Outline #1A1A2E

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `wizard_walk_left_strip.png`
?? **Cortar en:** `wizard_walk_left_1.png`, `wizard_walk_left_2.png`, `wizard_walk_left_3.png`, `wizard_walk_left_4.png`

---
### PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character walking animation - RIGHT SIDE PROFILE (walking right)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Big expressive eye visible in profile
- Thick dark outline (2-3px) around all shapes
- Cel-shading (2-3 shadow levels)
- Bold saturated colors
- Rounded soft shapes

CHARACTER DESIGN (side view, mirrored from left):
- Purple-blue hooded wizard robe flowing behind
- Long white beard in profile
- Staff held in leading hand
- Hood partially visible
- Rosy cheek visible

ANIMATION (4 frames, left to right):
- Frame 1: Neutral standing side pose facing right
- Frame 2: Front leg stepping forward, robe trailing
- Frame 3: Legs crossing mid-stride
- Frame 4: Back leg coming forward

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Crystal #66CCFF, Outline #1A1A2E

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.

```

?? **Guardar como:** `wizard_walk_right_strip.png`
?? **Cortar en:** `wizard_walk_right_1.png`, `wizard_walk_right_2.png`, `wizard_walk_right_3.png`, `wizard_walk_right_4.png`

---

## ? ANIMACIÓN DE CASTING (Lanzar hechizo)

---

### PROMPT #9 - Cast Animation (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character SPELL CASTING animation - FACING CAMERA

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head (~30% of body)
- Big expressive eyes (determined/focused expression)
- Thick dark outline (2-3px)
- Cel-shading (2-3 shadow levels)
- Bold saturated colors, rounded shapes

CHARACTER DESIGN:
- Purple-blue hooded wizard robe billowing with magical energy
- Long white stylized beard
- Staff with INTENSELY glowing cyan crystal
- Determined magical expression

ANIMATION (4 frames, dramatic casting):
- Frame 1: Raising staff upward, magical sparkles beginning to gather at crystal
- Frame 2: Staff raised high above head, intense magical orb forming at crystal tip, robe flowing upward
- Frame 3: Staff thrust forward releasing spell, bright cyan energy burst, robe blown back dramatically
- Frame 4: Recovery pose, staff lowering, fading magical sparkles around

MAGICAL EFFECTS:
- Cyan (#66CCFF) magical particles and sparkles
- White (#FFFFFF) energy highlights
- Glowing aura around crystal intensifying through frames

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Magic #66CCFF + #FFFFFF, Outline #1A1A2E

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `wizard_cast_strip.png`
?? **Cortar en:** `wizard_cast_1.png`, `wizard_cast_2.png`, `wizard_cast_3.png`, `wizard_cast_4.png`

---

## ?? ANIMACIÓN DE DAÑO (Hit)

---

### PROMPT #10 - Hit Animation (2 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character TAKING DAMAGE reaction - FACING CAMERA

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head
- Big expressive eyes (pained/surprised expression)
- Thick dark outline (2-3px)
- Cel-shading, bold colors

CHARACTER DESIGN:
- Purple-blue hooded wizard robe disturbed by impact
- Long white beard
- Staff gripped defensively
- Pained cute expression (>_<) style

ANIMATION (2 frames, damage reaction):
- Frame 1: Body recoiling backward from impact, eyes squeezed shut in pain, robe disturbed, RED damage flash overlay effect
- Frame 2: Recovery pose, slightly hunched defensive stance, determined expression returning, gripping staff tightly

DAMAGE EFFECTS:
- Frame 1: Slight red tint/flash on character
- Small impact stars or pain indicators

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Damage flash #FF6666, Outline #1A1A2E

OUTPUT: Horizontal strip 1000x500 pixels (2 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `wizard_hit_strip.png`
?? **Cortar en:** `wizard_hit_1.png`, `wizard_hit_2.png`

---

## ?? ANIMACIÓN DE MUERTE (Death)

---

### PROMPT #11 - Death Animation (4 frames)

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: Wizard character DEATH animation - FACING CAMERA (top-down view of falling)

ART STYLE (MATCH EXACTLY):
- Funko Pop / Chibi cartoon style
- Oversized cute head
- Expressive eyes (peaceful/fading)
- Thick dark outline (2-3px)
- Cel-shading, bold colors

CHARACTER DESIGN:
- Purple-blue hooded wizard robe spreading out as falling
- Long white beard
- Staff falling beside character
- Peaceful resigned expression

ANIMATION (4 frames, dramatic death sequence):
- Frame 1: Dramatic backward lean from fatal blow, staff slipping from grasp, surprised expression
- Frame 2: Knees buckling, body falling, staff dropping beside, eyes closing
- Frame 3: Collapsed on ground lying on back (top-down view), robe spread out around body, staff beside
- Frame 4: Fading away - character becoming semi-transparent/ghostly, magical cyan particles dispersing upward, peaceful expression

DEATH EFFECTS:
- Frame 4: 50% transparency, cyan magical particles floating up
- Soft ethereal glow

COLORS: Robe #4A7A9C, Skin #E8D4B8, Beard #E0E0E0, Ghost particles #66CCFF, Outline #1A1A2E

OUTPUT: Horizontal strip 2000x500 pixels (4 frames of 500x500 each), transparent background.
```

?? **Guardar como:** `wizard_death_strip.png`
?? **Cortar en:** `wizard_death_1.png`, `wizard_death_2.png`, `wizard_death_3.png`, `wizard_death_4.png`

---

# ?? ALTERNATIVA: Prompts Individuales (Si los strips no funcionan)

Si la IA no genera bien los sprite strips, usa estos prompts frame por frame:

---

### PROMPT ALTERNATIVO - Walk Down Frame Individual

**Frame 1:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard character. Facing camera, neutral standing pose feet together. Oversized cute head (~30% body), big expressive eyes with shine, thick dark outline (2-3px), cel-shading. Purple-blue hooded robe (#4A7A9C), white beard (#E0E0E0), wooden staff with glowing cyan crystal (#66CCFF). Warm beige skin (#E8D4B8), rosy cheeks. 500x500 pixels, transparent background.
```

**Frame 2:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard character. Facing camera, walking pose - left foot forward mid-step, robe flowing right. Oversized cute head, big expressive eyes, thick dark outline, cel-shading. Purple-blue hooded robe (#4A7A9C), white beard, staff with glowing cyan crystal. Same character as reference. 500x500 pixels, transparent background.
```

**Frame 3:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard character. Facing camera, walking pose - feet passing each other mid-stride. Oversized cute head, big expressive eyes, thick dark outline, cel-shading. Purple-blue hooded robe (#4A7A9C), white beard, staff with glowing cyan crystal. Same character as reference. 500x500 pixels, transparent background.
```

**Frame 4:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard character. Facing camera, walking pose - right foot forward mid-step, robe flowing left. Oversized cute head, big expressive eyes, thick dark outline, cel-shading. Purple-blue hooded robe (#4A7A9C), white beard, staff with glowing cyan crystal. Same character as reference. 500x500 pixels, transparent background.
```

---

### PROMPT ALTERNATIVO - Cast Frame Individual

**Frame 1:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard casting spell. Facing camera, raising staff upward, magical cyan sparkles gathering at crystal tip. Oversized cute head, determined expression, thick dark outline, cel-shading. Purple-blue hooded robe (#4A7A9C), white beard, glowing staff. 500x500 pixels, transparent background.
```

**Frame 2:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard casting spell. Facing camera, staff raised high above head, intense magical orb glowing at crystal tip, robe billowing with magical wind. Oversized cute head, focused expression, thick dark outline. Purple-blue robe, bright cyan magic glow (#66CCFF). 500x500 pixels, transparent background.
```

**Frame 3:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard casting spell. Facing camera, staff thrust forward releasing spell, bright cyan energy burst emanating, robe blown back dramatically. Oversized cute head, intense expression, thick dark outline. Purple-blue robe, powerful magic effects. 500x500 pixels, transparent background.
```

**Frame 4:**
```
2D game sprite, Funko Pop/Chibi cartoon style wizard post-spell. Facing camera, staff lowering to rest position, fading cyan magical sparkles around. Oversized cute head, satisfied expression, thick dark outline, cel-shading. Purple-blue robe settling, recovering pose. 500x500 pixels, transparent background.
```

---

# ?? Resumen y Checklist

## Sprites a generar:

| # | Prompt | Resultado | Sprites Finales |
|---|--------|-----------|-----------------|
| 0 | Referencia | 1 imagen | (solo referencia) |
| 1 | Walk Down | 1 strip | 4 sprites |
| 2 | Walk Up | 1 strip | 4 sprites |
| 3 | Walk Left | 1 strip | 4 sprites |
| 4 | Walk Right | 1 strip | 4 sprites |
| 5 | Idle Down | 1 strip | 3 sprites |
| 6 | Idle Up | 1 strip | 3 sprites |
| 7 | Idle Left | 1 strip | 3 sprites |
| 8 | Idle Right | 1 strip | 3 sprites |
| 9 | Cast | 1 strip | 4 sprites |
| 10 | Hit | 1 strip | 2 sprites |
| 11 | Death | 1 strip | 4 sprites |
| **TOTAL** | **12 prompts** | **12 imágenes** | **38 sprites** |

## Prioridad de ejecución:

1. ?? **#0** ? Referencia (obligatorio primero)
2. ?? **#1-4** ? Walk (16 sprites) - Mayor impacto
3. ?? **#9** ? Cast (4 sprites) - Feedback combate
4. ?? **#5-8** ? Idle (12 sprites) - Pulido
5. ?? **#10** ? Hit (2 sprites) - Feedback daño
6. ?? **#11** ? Death (4 sprites) - Completitud

---

## ??? Post-procesamiento

Después de generar las imágenes, necesitarás:

1. **Cortar los strips** en frames individuales (usa cualquier editor de imágenes)
2. **Verificar consistencia** de colores y tamaños entre frames
3. **Guardar** en `assets/sprites/players/wizard/` con la estructura:
   ```
   wizard/
   ??? walk/
   ?   ??? wizard_walk_down_1.png ... wizard_walk_down_4.png
   ?   ??? wizard_walk_up_1.png ... wizard_walk_up_4.png
   ?   ??? wizard_walk_left_1.png ... wizard_walk_left_4.png
   ?   ??? wizard_walk_right_1.png ... wizard_walk_right_4.png
   ??? idle/
   ?   ??? ... (similar estructura)
   ??? cast/
   ?   ??? wizard_cast_1.png ... wizard_cast_4.png
   ??? hit/
   ?   ??? wizard_hit_1.png, wizard_hit_2.png
   ??? death/
       ??? wizard_death_1.png ... wizard_death_4.png
   ```

---

# ?? PLANTILLA BASE PARA NUEVOS PERSONAJES

## Copia este prompt y reemplaza los valores en [CORCHETES] para crear cualquier personaje nuevo:

```
2D game sprite sheet for roguelike game, horizontal strip format.

SUBJECT: [NOMBRE_PERSONAJE] character [TIPO_ANIMACIÓN] animation - [DIRECCIÓN]

ART STYLE (CRITICAL - MATCH SPELLLOOP STYLE):
- Funko Pop / Chibi cartoon style
- Oversized cute head (approximately 30% of total body height)
- Big expressive eyes with white shine highlights
- Thick dark outline (2-3 pixels) around ALL shapes
- Cel-shading with 2-3 shadow levels (no gradients)
- Bold saturated colors (85%+ saturation)
- Rounded soft shapes - NO sharp angles
- Friendly cute appearance even for serious characters

CHARACTER DESIGN:
- [DESCRIPCIÓN_ROPA_PRINCIPAL]
- [DESCRIPCIÓN_ACCESORIOS]
- [DESCRIPCIÓN_ARMA_O_ITEM]
- [TIPO_CUERPO: compacto/esbelto/robusto]
- [EXPRESIÓN_FACIAL]

ANIMATION ([N_FRAMES] frames, [TIPO_MOVIMIENTO]):
- Frame 1: [DESCRIPCIÓN_FRAME_1]
- Frame 2: [DESCRIPCIÓN_FRAME_2]
- Frame 3: [DESCRIPCIÓN_FRAME_3]
- Frame 4: [DESCRIPCIÓN_FRAME_4] (si aplica)

COLOR PALETTE:
- Main color: [HEX_PRINCIPAL]
- Secondary: [HEX_SECUNDARIO]
- Accent: [HEX_ACENTO]
- Skin: [HEX_PIEL]
- Outline: #1A1A2E (siempre usar este para consistencia)

OUTPUT: Horizontal strip [ANCHO_TOTAL]x500 pixels ([N_FRAMES] frames of 500x500 each), transparent background.
```

## Ejemplos de valores para reemplazar:

### Para un ROGUE/ASSASSIN:
- NOMBRE_PERSONAJE: Rogue
- ROPA_PRINCIPAL: Dark hooded cloak with leather armor underneath
- ACCESORIOS: Belt with pouches, face mask
- ARMA: Twin daggers with purple poison glow
- TIPO_CUERPO: Esbelto/ágil
- COLOR_PRINCIPAL: #2D2D44 (gris oscuro)
- COLOR_ACENTO: #9944FF (púrpura veneno)

### Para un WARRIOR/KNIGHT:
- NOMBRE_PERSONAJE: Knight
- ROPA_PRINCIPAL: Shiny plate armor with blue cloth accents
- ACCESORIOS: Cape, helmet with visor
- ARMA: Large sword and shield
- TIPO_CUERPO: Robusto/fornido
- COLOR_PRINCIPAL: #7799BB (acero azulado)
- COLOR_ACENTO: #FFD700 (dorado)

### Para un ARCHER/RANGER:
- NOMBRE_PERSONAJE: Ranger
- ROPA_PRINCIPAL: Green hooded tunic, brown leather vest
- ACCESORIOS: Quiver of arrows on back
- ARMA: Wooden bow with green magical string
- TIPO_CUERPO: Atlético/equilibrado
- COLOR_PRINCIPAL: #4A7A4A (verde bosque)
- COLOR_ACENTO: #8B4513 (marrón cuero)

---

## ?? Especificaciones Técnicas Estándar (TODOS los personajes)

| Propiedad | Valor | Notas |
|-----------|-------|-------|
| Tamaño frame | 500x500 px | Contenido centrado |
| Outline | 2-3 px | Color #1A1A2E |
| Proporción cabeza | ~30% altura | Estilo Funko/Chibi |
| Saturación colores | 85%+ | Colores vibrantes |
| Sombras | 2-3 niveles | Cel-shading, sin gradientes |
| Ojos | Grandes, expresivos | Con brillo blanco |
| Formas | Redondeadas | Sin ángulos agudos |

## ?? Referencia cruzada

Este documento complementa:
- [AI_SPRITE_PROMPTS.md](AI_SPRITE_PROMPTS.md) - Prompts para proyectiles y efectos
- Los sprites de enemigos siguen el mismo estilo en `assets/sprites/enemies/`
