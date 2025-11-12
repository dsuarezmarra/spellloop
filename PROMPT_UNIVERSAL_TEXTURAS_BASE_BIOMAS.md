# 🌍 PROMPT UNIVERSAL - GENERACIÓN DE TEXTURAS BASE PARA BIOMAS
## Spellloop - Sistema de Texturas Animadas Seamless

---

## 📋 RESUMEN EJECUTIVO

Este prompt sirve para generar **8 frames de textura base animada** para cualquier tipo de bioma en Spellloop.
Las texturas generadas serán procesadas automáticamente por scripts de Python y usadas en Godot Engine 4.5.

**Resultado esperado:** 8 imágenes PNG individuales que forman un ciclo de animación perfectamente seamless/tileable.

---

## 🎯 ESPECIFICACIONES TÉCNICAS OBLIGATORIAS

### 📐 Dimensiones y Formato

```yaml
Resolución por frame: 1024×1024 píxeles
Cantidad de frames: 8 frames individuales
Formato: PNG (RGB o RGBA según necesidad)
Nomenclatura: 1.png, 2.png, 3.png, 4.png, 5.png, 6.png, 7.png, 8.png
```

**CRÍTICO:** Estos archivos serán:
1. Redimensionados automáticamente a 512×512px por el script de Python
2. Combinados en un sprite sheet horizontal de 4124×512px (con padding de 4px)
3. Usados en tiles de 256×256px o 512×512px en el juego

### 🔄 Requisito SEAMLESS/TILEABLE (OBLIGATORIO)

**MUY IMPORTANTE - ESTO ES CRÍTICO:**

Las texturas DEBEN ser perfectamente **seamless/tileable**:

✅ **Borde izquierdo = Borde derecho** (píxel a píxel)
✅ **Borde superior = Borde inferior** (píxel a píxel)
✅ **Al colocar 4 copias en cuadrícula 2×2, NO se ven líneas de separación**
✅ **Patrones naturales sin simetría obvia**

**¿Por qué es crítico?**
- Las texturas se repetirán como mosaico en chunks de 15000×15000 píxeles
- Cada textura cubre tiles de 256×256px o 512×512px
- Si NO son seamless, se verán líneas/cortes entre tiles (INACEPTABLE)

**Técnicas recomendadas:**
- Usar herramientas de "offset wrap" durante la creación
- Verificar bordes con tile preview antes de exportar
- Evitar elementos grandes que se corten en los bordes

---

## 🎨 ESTILO VISUAL DEL JUEGO

### Perspectiva y Estética

```yaml
Vista: Top-down 2D (cenital, desde arriba)
Estilo: Cartoon isométrico con toque hand-painted
Inspiración: Don't Starve, Enter the Gungeon, Nuclear Throne
Calidad: High-resolution pixel art / digital painting
Iluminación: Luz cenital suave + iluminación específica del bioma
```

### Características Visuales Generales

- **Colores:** Saturados y vibrantes, paleta específica por bioma
- **Contraste:** Alto contraste para legibilidad (zonas claras vs oscuras)
- **Textura:** Rica en detalles pero no sobrecargada
- **Profundidad:** Uso de sombras sutiles para dar sensación 3D
- **Coherencia:** Mantener estilo consistente entre los 8 frames

---

## 🎬 SISTEMA DE ANIMACIÓN (8 FRAMES)

### Estructura del Ciclo de Animación

**FPS en juego:** 5 FPS (animación suave y pausada)
**Duración total:** 1.6 segundos por ciclo completo
**Loop:** Perfecto (Frame 8 → Frame 1 sin saltos)

### Patrón de Animación Recomendado

```
Frame 1 (0.0s):   Estado BASE - Inicio del ciclo
                  ↓
Frame 2 (0.2s):   Cambio SUTIL (+10% intensidad)
                  ↓
Frame 3 (0.4s):   Cambio PROGRESIVO (+20% intensidad)
                  ↓
Frame 4 (0.6s):   PICO MÁXIMO (+100% intensidad) 🔥
                  ↓
Frame 5 (0.8s):   Descenso INICIAL (-10% desde pico)
                  ↓
Frame 6 (1.0s):   Descenso PROGRESIVO (-30% desde pico)
                  ↓
Frame 7 (1.2s):   Retorno SUAVE (-50% desde pico)
                  ↓
Frame 8 (1.4s):   Preparación LOOP (similar a Frame 1, transición suave)
                  ↓
                [LOOP a Frame 1] ♻️
```

### Tipos de Movimiento por Bioma

**Elementos naturales (Grassland, Forest):**
- Ondulación sutil de vegetación
- Movimiento de hojas/flores al viento
- Cambios sutiles de luz/sombra

**Elementos líquidos (Lava, Water):**
- Burbujas emergiendo y estallando
- Ondas y flujo de líquido
- Pulsación de brillo/intensidad

**Elementos mágicos (ArcaneWastes):**
- Pulsación de energía mágica
- Runas que brillan y se apagan
- Partículas flotantes

**Elementos fríos (Snow, Ice):**
- Brillo de cristales
- Movimiento de nieve/escarcha
- Pulsación de luz reflejada

**Elementos áridos (Desert):**
- Ondas de calor (distorsión)
- Movimiento sutil de arena
- Cambios de sombra

---

## 📝 PLANTILLAS DE PROMPT

### ⚠️ IMPORTANTE: Cómo Usar con Gemini

**Gemini requiere prompts MÁS DIRECTOS** para activar la generación de imágenes.
**NO uses** la versión larga con checklist, o solo te dará una respuesta de texto.

**USA ESTAS VERSIONES:**

---

### ✅ Versión para GEMINI (RECOMENDADA)

**Instrucciones:**
1. Copia EXACTAMENTE el prompt de abajo
2. Reemplaza `[BIOME_TYPE]` y los campos entre corchetes
3. **PEGA DIRECTAMENTE en Gemini** sin añadir nada más
4. Gemini generará las imágenes una por una

```
Create 8 seamless tileable texture images for a [BIOME_TYPE] biome (top-down 2D game).

Each image must be 1024×1024px, perfectly tileable (left=right edge, top=bottom edge).

Style: Cartoon hand-painted, vibrant colors, high contrast.

Colors: [COLOR_PALETTE_HEX_CODES]

Elements: [MAIN_ELEMENT_70%] with [SECONDARY_ELEMENTS_30%]

Animation cycle (8 frames):
1. Neutral state
2. [CHANGE] +10%
3. [CHANGE] +20%
4. PEAK [CHANGE] +100% (maximum)
5. Return -10%
6. Return -30%
7. Return -50%
8. Back to neutral (loops to frame 1)

Generate image 1 of 8 now.
```

**Después de que genere la imagen 1:**
```
Generate image 2 of 8 now. [DESCRIBE CHANGE FROM FRAME 1]
```

**Continúa así hasta completar los 8 frames.**

---

### 🔧 Versión para DALL-E / Midjourney (Detallada)

Para otras IAs que soportan prompts más largos, usa esta versión:

```
Generate 8 individual seamless/tileable texture frames (1024×1024px each) for a [BIOME_TYPE] biome in a top-down 2D game.

=== CRITICAL REQUIREMENTS ===
- SEAMLESS/TILEABLE: Left edge MUST match right edge perfectly. Top edge MUST match bottom edge perfectly.
- When tiled in a 2×2 grid, NO seam lines should be visible.
- All 8 frames must maintain consistent style and seamless properties.
- Natural patterns without obvious symmetry or repetition.

=== VISUAL STYLE ===
- View: Top-down (bird's eye view), 2D isometric perspective
- Art style: Cartoon with hand-painted digital look, high-resolution pixel art aesthetic
- Color palette: [SPECIFIC_COLORS_FOR_BIOME]
- Lighting: [LIGHTING_DESCRIPTION]
- Contrast: High contrast between [LIGHT_ELEMENTS] and [DARK_ELEMENTS]
- Details: Rich texture with [SPECIFIC_DETAILS]

=== BIOME ELEMENTS ===
Primary coverage (70-80%): [MAIN_GROUND_ELEMENT]
- Description: [DETAILED_DESCRIPTION]
- Colors: [COLOR_CODES]
- Texture characteristics: [TEXTURE_DETAILS]

Secondary elements (20-30%): [SECONDARY_ELEMENTS]
- Description: [DETAILED_DESCRIPTION]
- Colors: [COLOR_CODES]
- Visual effects: [EFFECTS]

Details and accents:
- [DETAIL_1]: [DESCRIPTION]
- [DETAIL_2]: [DESCRIPTION]
- [DETAIL_3]: [DESCRIPTION]

=== ANIMATION SEQUENCE (8 FRAMES) ===
Frame 1: [BASE_STATE_DESCRIPTION] - Baseline state
Frame 2: [SUBTLE_CHANGE] - +10% intensity
Frame 3: [PROGRESSIVE_CHANGE] - +20% intensity
Frame 4: [PEAK_STATE] - MAXIMUM intensity (brightest/most active)
Frame 5: [START_DESCENT] - Return begins (-10% from peak)
Frame 6: [PROGRESSIVE_DESCENT] - Continuing return (-30% from peak)
Frame 7: [SMOOTH_RETURN] - Almost back to baseline (-50% from peak)
Frame 8: [LOOP_PREPARATION] - Smooth transition back to Frame 1 (MUST loop seamlessly)

=== ANIMATION TYPE ===
[Choose one or combine:]
- Pulsation: Elements brighten and dim cyclically
- Bubbling: Bubbles/particles appear, grow, and disappear
- Flowing: Liquid or energy flows across the surface
- Undulation: Gentle wave-like movement
- Glow cycle: Luminous elements pulse with light
- Particle drift: Small particles float and move

=== TECHNICAL SPECS ===
- Resolution: 1024×1024 pixels per frame
- Format: PNG
- Color mode: RGB (or RGBA if transparency needed)
- File naming: 1.png, 2.png, 3.png, 4.png, 5.png, 6.png, 7.png, 8.png
- Seamless: VERIFIED (test by tiling before export)

=== VERIFICATION CHECKLIST ===
Before exporting each frame, verify:
□ Frame is exactly 1024×1024px
□ Left edge matches right edge pixel-perfectly
□ Top edge matches bottom edge pixel-perfectly
□ When tiled 2×2, no visible seam lines
□ Style consistent with other frames
□ Animation flows naturally to next frame
□ Frame 8 transitions smoothly back to Frame 1
□ Colors match the specified palette
□ No artifacts or compression issues

=== OUTPUT ===
Deliver 8 separate PNG files named: 1.png, 2.png, 3.png, 4.png, 5.png, 6.png, 7.png, 8.png
```

---

## 🎨 PROMPTS LISTOS PARA USAR (GEMINI)

**⚡ COPIA Y PEGA DIRECTAMENTE - GEMINI GENERARÁ 8 IMÁGENES SEPARADAS**

---

### 🌿 GRASSLAND (VERSIÓN SIMPLIFICADA - 4 FRAMES)

```
Create a SINGLE HORIZONTAL SPRITESHEET: 2048×512 pixels containing 4 animation frames.

🎯 CRITICAL SPECIFICATIONS:
- Total dimensions: 2048×512 pixels
- Layout: 4 frames arranged horizontally [Frame1][Frame2][Frame3][Frame4]
- Each frame: 512×512 pixels (SQUARE frames, NO gaps or borders between them)
- Style: Top-down 2D cartoon, hand-painted, inspired by Don't Starve
- Output: Single horizontal spritesheet image
- NOTE: These 4 frames will be duplicated later to create 8-frame animation

🔴 SEAMLESS/TILEABLE - ABSOLUTE PRIORITY #1:
Each 512×512 frame MUST tile perfectly when repeated:
- Left edge pixels = Right edge pixels (EXACT match, pixel-perfect)
- Top edge pixels = Bottom edge pixels (EXACT match, pixel-perfect)
- Imagine placing 4 copies in a 2×2 grid: you should see ZERO visible seam lines
- Use OFFSET/WRAP/TILE technique during creation
- Grass texture at edges must continue naturally on opposite edge
- NO elements cut off at borders
- THIS IS THE MOST IMPORTANT REQUIREMENT - if not seamless, the texture is UNUSABLE

⚠️ VIEW PERSPECTIVE - STRICTLY TOP-DOWN:
You are looking at grass from DIRECTLY ABOVE, like a bird or drone camera:
- See the TOP surface of grass, NEVER the side of grass blades
- Grass appears as textured ground cover, like a carpet or lawn viewed from above
- Wildflowers appear as small colored DOTS or PATCHES, not flowers with visible stems
- Think: "What does grass look like from a 10th floor window looking straight down?"
- Reference: Don't Starve ground textures, Enter the Gungeon floor tiles
- NO 3D perspective, NO angle, PURE top-down flat view

❌ COMMON MISTAKES TO AVOID:
- DO NOT show grass blades from side view (no vertical stems visible)
- DO NOT show flower stems or petals in profile
- DO NOT create obvious repeating patterns (use organic randomness)
- DO NOT make frames drastically different (animation should be VERY subtle)
- DO NOT leave seam lines at edges (TEST THIS!)
- DO NOT use perspective or 3D angle

🎨 VISUAL CONTENT (per frame):
Ground texture (75%):
- Vibrant green grass in multiple shades: #7ED957 (light), #6BC73D (medium), #5AB52E (dark)
- Dense grass texture resembling ground cover seen from above
- Visible brush stroke style for cartoon aesthetic
- Subtle color variation for organic feel
- Small shadows between grass clumps for depth
- Think: dense lawn texture, not individual grass blades

Wildflower accents (25%):
- Small colored dots scattered naturally across the grass: 
  * Yellow flowers: #FFD700, #FFA500 (3-8 pixel diameter circles/dots)
  * Pink flowers: #FF69B4, #FF1493 (3-8 pixel diameter circles/dots)
  * Orange flowers: #FF8C00, #FF7F50 (3-8 pixel diameter circles/dots)
- Random distribution (avoid grid patterns or obvious rows)
- Soft glow effect around flowers
- Tiny shadows beneath for depth

🎬 ANIMATION SEQUENCE (4 frames - Gentle Wind + Flower Glow):
The animation shows VERY SUBTLE wind movement through lighting/shadow changes and flower brightness pulsing.

Frame 1 (0-512px): BASELINE STATE
- Grass neutral, even lighting across surface
- Flowers at 40% glow intensity
- Shadows moderate and evenly distributed
- Starting point of animation cycle

Frame 2 (512-1024px): GENTLE TRANSITION
- Subtle lighting shift: right side slightly brighter (+10% light)
- Flowers 60% glow intensity
- Shadows shift very slightly to the left
- Small wind effect beginning

Frame 3 (1024-1536px): PEAK MOMENT
- Maximum brightness: right side +25% brighter than baseline
- Flowers 100% glow intensity (brightest point)
- Strong highlights visible on grass texture
- Shadows most pronounced on left side
- Peak of wind passing through

Frame 4 (1536-2048px): RETURN TO BASELINE
- Brightness returning to neutral (+5% from baseline)
- Flowers 50% glow intensity (dimming back down)
- Shadows normalizing
- MUST be similar to Frame 1 to prepare for loop (Frame 4 → Frame 1 transition)

Animation feel: Gentle breeze passing over meadow, flowers catching light and dimming in waves.
CRITICAL: Changes must be VERY SUBTLE - if you squint, all 4 frames should look nearly identical.

NOTE: These 4 frames will later be duplicated as: F1-F2-F3-F4-F4-F3-F2-F1 to create smooth 8-frame loop.

🎨 COLOR PALETTE (USE EXACT HEX CODES):
Grass greens: #7ED957, #6BC73D, #5AB52E, #4FA426
Flower yellows: #FFD700, #FFA500
Flower pinks: #FF69B4, #FF1493
Flower oranges: #FF8C00, #FF7F50
Shadow darks: #2F5016, #3A6020

💡 LIGHTING:
- Soft overhead sunlight (natural daylight)
- Directional component from top-right creating subtle shadows
- Warm tone overall
- Ambient occlusion in grass density areas

✅ QUALITY CHECKLIST (Verify before generating):
□ Total image is 2048×512 pixels (4 frames of 512×512)
□ Contains exactly 4 square frames of 512×512 each
□ Each frame tiles perfectly horizontally and vertically (TEST THIS!)
□ View is strictly top-down (like looking at floor from above)
□ Grass looks like ground texture/carpet, not individual blades
□ Flowers are small dots/patches, not recognizable flower shapes with stems
□ Animation changes are VERY subtle between frames
□ Frame 4 can transition smoothly back to Frame 1
□ Colors match specified hex codes exactly
□ Style is cartoon hand-painted
□ NO seam lines visible when tiled

🚀 GENERATION INSTRUCTION:
Generate the complete 2048×512px horizontal spritesheet NOW as a single image with all 4 frames arranged left to right with NO gaps between them.
```

---

### 🔥 LAVA

```
Create a SINGLE HORIZONTAL SPRITESHEET image containing 8 seamless/tileable animation frames.

DIMENSIONS: 8192×1024 pixels (8 frames of 1024×1024 arranged horizontally)
STYLE: Top-down 2D cartoon, hand-painted, Don't Starve inspired
VIEW: Directly from above (bird's eye view)

LAYOUT: [Frame1][Frame2][Frame3][Frame4][Frame5][Frame6][Frame7][Frame8]
Each frame is 1024×1024px, arranged left to right with NO gaps or borders between them.

CONTENT PER FRAME:
- 70% dark volcanic rock (#2B1F1F, #3D2A2A, #4A3535) with rough texture
- 30% glowing lava cracks/veins (#FF4500, #FF6347, #FFA500, #FFCC00) 
- Bright yellow highlights (#FFFF00, #FFF8DC) at hottest points
- Small lava bubbles rising and bursting
- Ambient orange glow illuminating nearby rock

ANIMATION SEQUENCE (lava pulsation + bubbles):
Frame 1 (0px-1024px): Medium glow, few small bubbles
Frame 2 (1024px-2048px): +10% brighter, bubbles appear
Frame 3 (2048px-3072px): +20% brighter, bubbles grow
Frame 4 (3072px-4096px): +100% brightest (PEAK), bubbles largest, maximum glow
Frame 5 (4096px-5120px): -10% from peak, bubbles start bursting
Frame 6 (5120px-6144px): -30% from peak, bubbles fading
Frame 7 (6144px-7168px): -50% from peak, few bubbles remain
Frame 8 (7168px-8192px): Medium glow (MUST match Frame 1 for perfect loop)

🔴 CRITICAL SEAMLESS REQUIREMENTS:
1. Each individual frame (1024×1024) MUST be seamless/tileable:
   - Left edge = Right edge (pixel-perfect horizontal wrap)
   - Top edge = Bottom edge (pixel-perfect vertical wrap)
2. Lava cracks must continue naturally when wrapped at edges
3. Use OFFSET/WRAP technique to verify no visible seams
4. Test by mentally tiling 2×2 - should see NO break lines
5. Frame 8 must transition smoothly back to Frame 1 (perfect loop)

LIGHTING: Warm glow from lava cracks, casting orange light on surrounding rock

Generate the complete 8192×1024px spritesheet NOW as a single image.
```

---

### ❄️ SNOW

```
Create a SINGLE HORIZONTAL SPRITESHEET image containing 8 seamless/tileable animation frames.

DIMENSIONS: 8192×1024 pixels (8 frames of 1024×1024 arranged horizontally)
STYLE: Top-down 2D cartoon, hand-painted, Don't Starve inspired
VIEW: Directly from above (bird's eye view)

LAYOUT: [Frame1][Frame2][Frame3][Frame4][Frame5][Frame6][Frame7][Frame8]
Each frame is 1024×1024px, arranged left to right with NO gaps or borders between them.

CONTENT PER FRAME:
- 80% white/light blue snow surface (#EAF6FF, #F0F8FF, #FFFFFF) with subtle texture
- 20% scattered ice crystals and frost patches (#B0E0E6, #ADD8E6, #87CEEB)
- Cyan sparkles and highlights (#E0FFFF, #F0FFFF) on crystals
- Soft blue shadows for depth
- Natural frost patterns (avoiding obvious repetition)

ANIMATION SEQUENCE (crystal shimmer):
Frame 1 (0px-1024px): Soft ambient glow, crystals dim, few sparkles
Frame 2 (1024px-2048px): +10% brighter, sparkles increase
Frame 3 (2048px-3072px): +20% brighter, more visible crystals
Frame 4 (3072px-4096px): +100% brightest (PEAK), maximum sparkles, crystal glow
Frame 5 (4096px-5120px): -10% from peak, sparkles fading
Frame 6 (5120px-6144px): -30% from peak
Frame 7 (6144px-7168px): -50% from peak, dim glow
Frame 8 (7168px-8192px): Soft glow (MUST match Frame 1 for perfect loop)

🔴 CRITICAL SEAMLESS REQUIREMENTS:
1. Each individual frame (1024×1024) MUST be seamless/tileable:
   - Left edge = Right edge (pixel-perfect horizontal wrap)
   - Top edge = Bottom edge (pixel-perfect vertical wrap)
2. Ice crystals/frost patterns must continue naturally at edges
3. Use OFFSET/WRAP technique to verify no visible seams
4. Test by mentally tiling 2×2 - should see NO break lines
5. Frame 8 must transition smoothly back to Frame 1 (perfect loop)

LIGHTING: Cool ambient light with reflective highlights on ice

Generate the complete 8192×1024px spritesheet NOW as a single image.
```

---

### 🏜️ DESERT

```
Create a SINGLE HORIZONTAL SPRITESHEET image containing 8 seamless/tileable animation frames.

DIMENSIONS: 8192×1024 pixels (8 frames of 1024×1024 arranged horizontally)
STYLE: Top-down 2D cartoon, hand-painted, Don't Starve inspired
VIEW: Directly from above (bird's eye view)

LAYOUT: [Frame1][Frame2][Frame3][Frame4][Frame5][Frame6][Frame7][Frame8]
Each frame is 1024×1024px, arranged left to right with NO gaps or borders between them.

CONTENT PER FRAME:
- 80% sandy terrain (#E8C27B, #DEB887, #F4A460) with dune ripples/patterns
- 20% scattered brown rocks (#CD853F, #A0826D, #D2691E) of various sizes
- Subtle sand texture showing wind patterns
- Small sand particles drifting
- Warm ambient light creating soft shadows

ANIMATION SEQUENCE (heat shimmer + sand drift):
Frame 1 (0px-1024px): Calm sand, subtle shimmer, minimal heat distortion
Frame 2 (1024px-2048px): +10% heat distortion, light sand particles visible
Frame 3 (2048px-3072px): +20% distortion, more particles drifting
Frame 4 (3072px-4096px): +100% maximum distortion (PEAK), visible heat waves, sand swirling
Frame 5 (4096px-5120px): -10% from peak, distortion reducing, particles settling
Frame 6 (5120px-6144px): -30% from peak
Frame 7 (6144px-7168px): -50% from peak, shimmer fading
Frame 8 (7168px-8192px): Calm sand (MUST match Frame 1 for perfect loop)

🔴 CRITICAL SEAMLESS REQUIREMENTS:
1. Each individual frame (1024×1024) MUST be seamless/tileable:
   - Left edge = Right edge (pixel-perfect horizontal wrap)
   - Top edge = Bottom edge (pixel-perfect vertical wrap)
2. Dune patterns and rocks must continue naturally at edges
3. Use OFFSET/WRAP technique to verify no visible seams
4. Test by mentally tiling 2×2 - should see NO break lines
5. Frame 8 must transition smoothly back to Frame 1 (perfect loop)

LIGHTING: Warm desert sun from above creating natural shadows

Generate the complete 8192×1024px spritesheet NOW as a single image.
```

---

### 🌲 FOREST

```
Create a SINGLE HORIZONTAL SPRITESHEET image containing 8 seamless/tileable animation frames.

DIMENSIONS: 8192×1024 pixels (8 frames of 1024×1024 arranged horizontally)
STYLE: Top-down 2D cartoon, hand-painted, Don't Starve inspired
VIEW: Directly from above (bird's eye view)

LAYOUT: [Frame1][Frame2][Frame3][Frame4][Frame5][Frame6][Frame7][Frame8]
Each frame is 1024×1024px, arranged left to right with NO gaps or borders between them.

CONTENT PER FRAME:
- 70% dark leaf-covered ground (#306030, #2D5016, #1F3A1F) with organic texture
- 30% fallen logs (#8B4513, #654321), red mushrooms (#FF6347, #DC143C), small plants
- Moss patches (#4A6741, #556B2F) on logs
- Shadows under logs and mushrooms for depth
- Natural forest floor clutter (twigs, stones)

ANIMATION SEQUENCE (leaf rustle + mushroom glow):
Frame 1 (0px-1024px): Leaves still, mushrooms dim glow
Frame 2 (1024px-2048px): Leaves shift slightly, mushrooms +10% brighter
Frame 3 (2048px-3072px): Leaves move more, mushrooms +20% brighter
Frame 4 (3072px-4096px): Maximum leaf movement (PEAK), mushrooms +100% brightest
Frame 5 (4096px-5120px): Leaves settling, mushrooms -10% from peak
Frame 6: almost still, -30% from peak
Frame 7: nearly stopped, -50% from peak
Frame 8: still, dim glow (MUST match Frame 1 for perfect loop)

🔴 CRITICAL SEAMLESS REQUIREMENTS:
1. Each individual frame (1024×1024) MUST be seamless/tileable:
   - Left edge = Right edge (pixel-perfect horizontal wrap)
   - Top edge = Bottom edge (pixel-perfect vertical wrap)
2. Logs and mushrooms at edges must continue naturally when wrapped
3. Use OFFSET/WRAP technique to verify no visible seams
4. Test by mentally tiling 2×2 - should see NO break lines
5. Frame 8 must transition smoothly back to Frame 1 (perfect loop)

LIGHTING: Dappled forest light filtering through canopy, mysterious mushroom glow

Generate the complete 8192×1024px spritesheet NOW as a single image.
```

---

### 🔮 ARCANE WASTES

```
Create a SINGLE HORIZONTAL SPRITESHEET image containing 8 seamless/tileable animation frames.

DIMENSIONS: 8192×1024 pixels (8 frames of 1024×1024 arranged horizontally)
STYLE: Top-down 2D cartoon, hand-painted, Don't Starve inspired
VIEW: Directly from above (bird's eye view)

LAYOUT: [Frame1][Frame2][Frame3][Frame4][Frame5][Frame6][Frame7][Frame8]
Each frame is 1024×1024px, arranged left to right with NO gaps or borders between them.

CONTENT PER FRAME:
- 65% corrupted purple soil (#B56DDC, #9B4DCA, #8A2BE2) with cracks and corruption
- 35% glowing magical runes (#FF00FF, #DA70D6) carved in ground
- Cyan arcane crystals (#00FFFF, #7FFFD4) jutting from earth
- Floating magical particles and energy wisps
- Purple mist effects near rune clusters
- Ethereal glow casting light on surrounding ground

ANIMATION SEQUENCE (magical energy pulsation):
Frame 1 (0px-1024px): Runes dim glow, few floating particles
Frame 2 (1024px-2048px): +10% brighter, particles increase
Frame 3 (2048px-3072px): +20% brighter, more particles swirling
Frame 4 (3072px-4096px): +100% brightest (PEAK), maximum particles, intense glow
Frame 5 (4096px-5120px): -10% from peak, particles dispersing
Frame 6 (5120px-6144px): -30% from peak
Frame 7 (6144px-7168px): -50% from peak, few particles remain
Frame 8 (7168px-8192px): Dim glow (MUST match Frame 1 for perfect loop)

🔴 CRITICAL SEAMLESS REQUIREMENTS:
1. Each individual frame (1024×1024) MUST be seamless/tileable:
   - Left edge = Right edge (pixel-perfect horizontal wrap)
   - Top edge = Bottom edge (pixel-perfect vertical wrap)
2. Runes and crystals at edges must continue naturally when wrapped
3. Use OFFSET/WRAP technique to verify no visible seams
4. Test by mentally tiling 2×2 - should see NO break lines
5. Frame 8 must transition smoothly back to Frame 1 (perfect loop)

LIGHTING: Magical purple/cyan glow emanating from runes and crystals

Generate the complete 8192×1024px spritesheet NOW as a single image.
```

---

## 🎨 EJEMPLOS POR TIPO DE BIOMA (REFERENCIA DE COLORES)

### 🔥 LAVA / VOLCANIC

```yaml
Main element: Dark volcanic rock (70%)
Colors: #2B1F1F, #3D2A2A, #4A3535 (dark browns/blacks)

Secondary element: Glowing lava cracks (30%)
Colors: #FF4500, #FF6347, #FF7F50 (bright oranges)
       #FFA500, #FFB347, #FFCC00 (yellows)
       #FFFF00, #FFF8DC (bright highlights)

Animation: Lava glow pulsation + bubbles emerging and bursting
Lighting: Warm glow from cracks, ambient orange light
```

### ❄️ SNOW / ICE

```yaml
Main element: Snow surface (80%)
Colors: #EAF6FF, #F0F8FF, #FFFFFF (whites/light blues)

Secondary element: Ice crystals and frost (20%)
Colors: #B0E0E6, #ADD8E6, #87CEEB (light blues)
       #E0FFFF, #F0FFFF (cyan highlights)

Animation: Crystal glow pulsation + subtle snow shimmer
Lighting: Cool ambient light, reflective highlights
```

### 🌿 GRASSLAND / MEADOW

```yaml
Main element: Green grass (75%)
Colors: #7ED957, #6BC73D, #5AB52E (vibrant greens)

Secondary element: Flowers and vegetation (25%)
Colors: #FFD700, #FFA500 (yellow flowers)
       #FF69B4, #FF1493 (pink flowers)

Animation: Gentle wind undulation + flower swaying
Lighting: Natural daylight, soft shadows
```

### 🏜️ DESERT / SAND

```yaml
Main element: Sand surface (80%)
Colors: #E8C27B, #DEB887, #F4A460 (sandy tans)

Secondary element: Rocks and dunes (20%)
Colors: #CD853F, #A0826D (browns)
       #D2691E (reddish rocks)

Animation: Heat wave distortion + sand particle drift
Lighting: Bright sun, strong shadows
```

### 🌲 FOREST / DARK WOODS

```yaml
Main element: Leaf-covered ground (70%)
Colors: #306030, #2D5016, #1F3A1F (dark greens)

Secondary element: Logs and mushrooms (30%)
Colors: #8B4513, #654321 (browns)
       #FF6347, #DC143C (red mushrooms)

Animation: Subtle leaf movement + mushroom glow
Lighting: Dappled shade, low ambient light
```

### 🔮 ARCANE WASTES / MAGICAL

```yaml
Main element: Corrupted soil (65%)
Colors: #B56DDC, #9B4DCA, #8A2BE2 (purples)

Secondary element: Glowing runes and crystals (35%)
Colors: #FF00FF, #DA70D6 (bright magentas)
       #00FFFF, #7FFFD4 (cyan accents)

Animation: Rune glow pulsation + magical particles
Lighting: Eerie magical glow, ethereal ambiance
```

---

## ⚠️ ERRORES COMUNES A EVITAR

### ❌ NO HACER:

1. **Bordes con líneas visibles**
   - Solución: Usar técnicas de "wrap" y verificar siempre con tile preview

2. **Frames con tamaños inconsistentes**
   - Solución: Verificar que TODOS los frames sean exactamente 1024×1024px

3. **Cambios bruscos entre frames**
   - Solución: Mantener variaciones sutiles (10-20% de cambio por frame)

4. **Frame 8 que no conecta con Frame 1**
   - Solución: Diseñar Frame 8 como transición suave hacia Frame 1

5. **Patrones simétricos obvios**
   - Solución: Usar ruido aleatorio y variación natural

6. **Elementos grandes cortados en los bordes**
   - Solución: Mantener elementos grandes lejos de los bordes o continuar en el lado opuesto

7. **Colores fuera de la paleta**
   - Solución: Ceñirse estrictamente a los códigos de color especificados

8. **Estilo inconsistente entre frames**
   - Solución: Usar el mismo pipeline/técnica para todos los frames

---

## 🔍 PROCESO DE VERIFICACIÓN

### Checklist Post-Generación

Antes de considerar las texturas completas, verificar:

#### Técnico
- [ ] 8 archivos PNG nombrados correctamente (1.png - 8.png)
- [ ] Cada archivo es exactamente 1024×1024px
- [ ] Modo de color correcto (RGB o RGBA según bioma)
- [ ] Sin artefactos de compresión o ruido inesperado

#### Seamless
- [ ] Borde izquierdo = borde derecho en todos los frames
- [ ] Borde superior = borde inferior en todos los frames
- [ ] Prueba de tile 2×2: NO se ven líneas de separación
- [ ] Prueba de tile 4×4: Patrón natural sin repetición obvia

#### Animación
- [ ] Los 8 frames forman un ciclo coherente
- [ ] Frame 1 → 2 → 3 → 4 (ascenso suave)
- [ ] Frame 4 es el pico máximo de intensidad
- [ ] Frame 5 → 6 → 7 → 8 (descenso suave)
- [ ] Frame 8 → 1 (loop perfecto sin saltos)
- [ ] Movimiento natural según el tipo de bioma

#### Estético
- [ ] Colores coinciden con la paleta especificada
- [ ] Estilo cartoon/isométrico consistente
- [ ] Nivel de detalle apropiado (no demasiado simple ni sobrecargado)
- [ ] Contraste adecuado para legibilidad
- [ ] Iluminación coherente con el bioma

---

## 🚀 FLUJO DE TRABAJO RECOMENDADO

### Paso 1: Preparación
1. Leer este documento completo
2. Identificar el tipo de bioma a crear
3. Seleccionar la paleta de colores apropiada
4. Definir los elementos principales y secundarios

### Paso 2: Generación
1. Usar el prompt completo adaptado al bioma
2. Generar los 8 frames en orden
3. Verificar seamless en cada frame antes de continuar

### Paso 3: Verificación
1. Hacer tile test 2×2 con cada frame
2. Reproducir animación completa a 5 FPS
3. Verificar el loop (Frame 8 → 1)
4. Ajustar si es necesario

### Paso 4: Exportación
1. Exportar como PNG sin compresión
2. Nombrar: 1.png, 2.png, ..., 8.png
3. Colocar en carpeta: `project/assets/textures/biomes/[NombreBioma]/base/`

### Paso 5: Procesamiento
1. Ejecutar script de Python: `utils/create_spritesheet_like_snow.py`
2. Verificar sprite sheet resultante (4124×512px)
3. Crear archivo `.import` en Godot
4. Probar en escena de test

---

## 💡 TIPS PARA MEJORES RESULTADOS

### Técnicas de Generación

**Para texturas más realistas:**
- Usar múltiples capas de ruido (Perlin + Simplex)
- Aplicar distorsión sutil para organicidad
- Añadir variación de color dentro de la paleta

**Para animaciones más naturales:**
- No animar todo a la vez (efectos escalonados)
- Usar curvas ease-in/ease-out (no lineales)
- Añadir elementos aleatorios (posición de burbujas, partículas)

**Para mejor seamless:**
- Trabajar con resolución 2048×2048 y reducir a 1024×1024
- Usar filtros de "offset" durante el diseño
- Verificar en múltiples escalas de zoom

### Optimización

**Para mejor rendimiento en juego:**
- Mantener contraste alto (legibilidad)
- Evitar detalles microscópicos (se pierden al escalar)
- Usar colores saturados pero no estridentes

**Para mejor integración:**
- Mantener estilo consistente entre biomas
- Respetar la paleta de colores del bioma
- Considerar cómo se verá junto a decoraciones

---

## 📊 MÉTRICAS DE CALIDAD

### Estándar de Calidad Spellloop

Una textura base está lista cuando cumple:

✅ **Técnico:** 10/10
- Dimensiones exactas
- Seamless perfecto
- Sin artefactos

✅ **Animación:** 9/10
- Ciclo fluido
- Loop perfecto
- Movimiento natural

✅ **Estética:** 9/10
- Colores correctos
- Estilo consistente
- Nivel de detalle apropiado

✅ **Integración:** 9/10
- Compatible con decoraciones
- Funciona en tiles pequeños
- Rendimiento óptimo

**Meta:** ≥ 37/40 puntos totales

---

## 📞 TROUBLESHOOTING

### Problema: "Las texturas no son seamless"
**Solución:**
1. Usar herramienta "offset" durante diseño
2. Verificar bordes manualmente píxel a píxel
3. Usar scripts de verificación automática
4. Regenerar con emphasis en "perfectly tileable"

### Problema: "La animación tiene saltos"
**Solución:**
1. Verificar que Frame 8 sea muy similar a Frame 1
2. Reducir intensidad de cambios entre frames
3. Usar transiciones ease-in/ease-out
4. Probar a 5 FPS en Godot antes de continuar

### Problema: "Colores no coinciden con el bioma"
**Solución:**
1. Usar exact color codes en el prompt
2. Ajustar post-generación con editor de imágenes
3. Aplicar LUT o color grading consistente
4. Regenerar con paleta más específica

### Problema: "Textura demasiado repetitiva al hacer tile"
**Solución:**
1. Añadir más variación aleatoria
2. Evitar patrones simétricos
3. Usar múltiples elementos de tamaños variados
4. Aplicar distorsión sutil no uniforme

---

## 🎓 EJEMPLOS DE PROMPTS COMPLETADOS

### Ejemplo 1: Lava Biome (Usado Exitosamente)

```
Generate 8 individual seamless/tileable texture frames (1024×1024px each) for a LAVA/VOLCANIC biome in a top-down 2D game.

=== CRITICAL REQUIREMENTS ===
- SEAMLESS/TILEABLE: Left edge MUST match right edge perfectly. Top edge MUST match bottom edge perfectly.
- When tiled in a 2×2 grid, NO seam lines should be visible.

=== VISUAL STYLE ===
- View: Top-down, 2D isometric
- Art style: Cartoon hand-painted, high-res pixel art aesthetic
- Color palette: Dark volcanic rocks (#2B1F1F, #3D2A2A, #4A3535) with bright orange/yellow lava (#FF4500, #FF6347, #FFA500, #FFCC00)
- Lighting: Warm glow from lava cracks, ambient orange light
- Contrast: High between dark rocks and glowing lava

=== BIOME ELEMENTS ===
Primary (70%): Dark volcanic rock surface with cracks
- Rough, textured surface
- Irregular organic shapes
- Some rocks 100-150px, others 30-50px
- Subtle color variation

Secondary (30%): Glowing lava-filled cracks
- Interconnected network between rocks
- 10-40px wide
- Gradient from yellow center to orange edges
- Depth effect with shadows

Details:
- Bubbles: 5-20px circles, yellow/orange
- Embers: 2-3px floating particles
- Heat distortion: Subtle near cracks

=== ANIMATION SEQUENCE ===
Frame 1: Medium lava glow, moderate cracks brightness
Frame 2: Glow +10%, new small bubbles appear
Frame 3: Glow +20%, bubbles grow slightly
Frame 4: PEAK - Glow +100%, bubbles largest, brightest state
Frame 5: Glow -10%, some bubbles start disappearing
Frame 6: Glow -30%, bubbles reducing
Frame 7: Glow -50%, few bubbles remain
Frame 8: Similar to Frame 1 but 10% dimmer, smooth loop prep

Animation type: Lava glow pulsation + bubbles emerging/bursting

=== TECHNICAL SPECS ===
- 1024×1024px PNG
- RGB mode
- Files: 1.png through 8.png
- Verify seamless by tiling before export
```

### Ejemplo 2: Grassland Biome

```
Generate 8 individual seamless/tileable texture frames (1024×1024px each) for a GRASSLAND/MEADOW biome in a top-down 2D game.

=== CRITICAL REQUIREMENTS ===
[mismo que arriba]

=== VISUAL STYLE ===
- View: Top-down, 2D isometric
- Art style: Cartoon hand-painted, vibrant and cheerful
- Color palette: Vibrant greens (#7ED957, #6BC73D, #5AB52E) with colorful flowers (#FFD700, #FF69B4)
- Lighting: Bright natural daylight, soft shadows
- Contrast: Medium, pleasant and inviting

=== BIOME ELEMENTS ===
Primary (75%): Green grass coverage
- Short to medium length grass
- Varied green tones for naturalness
- Subtle texture variation
- Clumps and patches

Secondary (25%): Wildflowers and small plants
- Small flowers: yellow, pink, white (5-15px)
- Distributed randomly but naturally
- Some in clusters, some isolated
- Small rocks (20-40px) occasionally

Details:
- Flower petals swaying
- Grass tips movement
- Light/shadow variation
- Subtle color shifts

=== ANIMATION SEQUENCE ===
Frame 1: Grass neutral position, flowers centered
Frame 2: Grass bends slightly right, flowers +5° right
Frame 3: Grass bends more right (+15°), flowers +10° right
Frame 4: PEAK - Maximum bend right (+25°), flowers +15° right
Frame 5: Grass returning, flowers -5° from peak
Frame 6: Grass almost neutral, flowers -10° from peak
Frame 7: Grass neutral, flowers almost centered
Frame 8: Perfect neutral, ready for Frame 1 loop

Animation type: Gentle wind undulation

=== TECHNICAL SPECS ===
[mismo que arriba]
```

---

## 📚 RECURSOS ADICIONALES

### Herramientas Recomendadas

**Para generación:**
- Gemini 2.0 Flash (recomendado)
- DALL-E 3
- Midjourney v6
- Stable Diffusion XL

**Para verificación:**
- GIMP (verificar seamless con offset)
- Aseprite (preview de animación)
- Python + PIL (scripts automáticos)

### Documentación Relacionada

- `GUIA_COMPLETA_TEXTURAS_BIOMAS.md` - Proceso completo
- `README_BIOMES_ORGANIC.md` - Sistema de biomas
- `utils/create_spritesheet_like_snow.py` - Script de procesamiento

---

## ✅ CHECKLIST FINAL

Antes de considerar un set de texturas base COMPLETO:

- [ ] **8 frames generados** (1.png - 8.png)
- [ ] **Seamless verificado** en cada frame
- [ ] **Animación fluida** probada a 5 FPS
- [ ] **Loop perfecto** (Frame 8 → 1)
- [ ] **Colores correctos** según paleta
- [ ] **Estilo consistente** entre frames
- [ ] **Dimensiones exactas** (1024×1024px)
- [ ] **Sin artefactos** visuales
- [ ] **Archivos organizados** en carpeta correcta
- [ ] **Documentación** del proceso

---

## 🎉 ¡LISTO PARA CREAR!

Con este prompt universal puedes generar texturas base para cualquier bioma en Spellloop.

**Recuerda los 3 pilares:**
1. ✅ **SEAMLESS** - Bordes perfectos sin costuras
2. ✅ **ANIMACIÓN** - 8 frames con ciclo fluido
3. ✅ **ESTILO** - Cartoon isométrico consistente

**¡Buena suerte creando biomas increíbles! 🚀🌍**

---

**Documento generado:** 12 de noviembre de 2025  
**Versión:** 1.0  
**Proyecto:** Spellloop - Biome Texture Generation System  
**Estado:** ✅ PRODUCTION READY
