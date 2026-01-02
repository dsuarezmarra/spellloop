# 🎨 Prompts para Generar Sprites de Proyectiles con IA

## Instrucciones de Uso

1. **Copia el PROMPT BASE primero** - Establece el contexto del estilo
2. **Luego copia cada prompt individual** - Genera cada proyectil por separado
3. **Guarda cada resultado** en la carpeta correspondiente
4. **Formato requerido**: PNG con transparencia, 64x64 píxeles por frame

---

## 🎯 PROMPT BASE (Usar al inicio de cada sesión)

```
I need you to create Cartoon sprites for a roguelike video game. 

STYLE REQUIREMENTS:
- Art style: Cartoon/Funko Pop - cute, round shapes with big cute features
- Resolution: 64x64 pixels per frame
- Format: Horizontal sprite strip (frames side by side)
- Background: Transparent (checkerboard pattern to show transparency)
- Outline: 1-2 pixel dark outline around all shapes
- Colors: Bold, saturated colors with clear highlights
- Feel: Friendly but magical, suitable for all ages

TECHNICAL REQUIREMENTS:
- Each animation should be a horizontal strip
- Frames should be evenly spaced
- Keep designs centered in each frame
- Leave 2-4 pixels padding from edges
- Use consistent lighting (light from top-left)
```

---

## 🧊 1. ICE WAND - Cristal de Hielo

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: A cute ice crystal shard projectile

Design:
- Shape: Pointed ice crystal, angular but with slightly rounded edges
- Main body: Light cyan (#66CCFF)
- Highlights: White (#FFFFFF) streaks and sparkles
- Inner glow: Pale blue (#99EEFF)
- Outline: Dark blue (#1A3A5C)

Animation: Crystal spinning/rotating as it flies
- Frame 1: Pointing right
- Frame 2-5: Rotating clockwise showing different angles
- Frame 6: Return to pointing right

Effects:
- Small frost sparkles trailing behind
- Subtle glow pulse on each frame
- 2-3 tiny ice particles floating nearby
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Ice crystal impact/shatter effect

Design:
- Same color palette: cyan (#66CCFF), white (#FFFFFF), pale blue (#99EEFF)
- Dark blue outline (#1A3A5C)

Animation: Ice shard hitting and exploding into smaller pieces
- Frame 1: Crystal just hit, starting to crack
- Frame 2: Cracks spreading, ice fragments starting to fly
- Frame 3: Full shatter, pieces flying outward in all directions
- Frame 4: Fragments spreading wider, some fading
- Frame 5: Smaller particles, mostly dispersed
- Frame 6: Final sparkles and frost mist fading away

Effects:
- Frost mist/cloud appearing at impact point
- Ice shards flying radially outward
- White sparkle particles
```

---

## 🔥 2. FIRE WAND - Bola de Fuego

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: A bouncy, cute fireball projectile

Design:
- Shape: Round/spherical flame orb with flickering edges
- Core: Bright yellow-white (#FFCC00)
- Main body: Bright orange (#FF6611)
- Outer flames: Orange-red (#FF9944)
- Outline: Dark red-brown (#661100)

Animation: Flame flickering and pulsing as it travels
- Frames 1-6: Flames dancing around the core
- Core stays relatively stable while outer flames shift shape
- Slight size pulse (breathing effect)

Effects:
- Small ember particles trailing behind
- Heat shimmer lines (wavy)
- Warm yellow glow around entire projectile
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Fireball explosion impact

Design:
- Same color palette: yellow (#FFCC00), orange (#FF6611), red-orange (#FF9944)
- Dark outline (#661100)

Animation: Fireball hitting and exploding into flames
- Frame 1: Ball compressing on impact
- Frame 2: Explosion burst begins, flames spreading
- Frame 3: Maximum explosion size, flames everywhere
- Frame 4: Flames separating into smaller fires
- Frame 5: Flames shrinking and embers flying
- Frame 6: Final embers and smoke wisps fading

Effects:
- Bright white-yellow flash at center in frame 2-3
- Ember particles shooting outward
- Small smoke puffs
```

---

## ⚡ 3. LIGHTNING WAND - Rayo

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: A cute lightning bolt projectile with energy orb

Design:
- Shape: Zigzag bolt with a round energy orb at the tip
- Bolt: Bright yellow (#FFFF4D)
- Core/orb: White (#FFFFFF)
- Electric glow: Pale yellow (#FFFF99)
- Outline: Purple (#6633CC)

Animation: Electric energy crackling and orb pulsing
- Frames 1-6: The bolt shape stays similar but electricity crackles
- Orb pulses bright on alternating frames
- Small electric arcs appear and disappear around the bolt

Effects:
- Electric spark particles jumping around
- Small lightning branches extending and retracting
- Glow intensity fluctuating
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Lightning strike impact

Design:
- Same palette: yellow (#FFFF4D), white (#FFFFFF), pale yellow (#FFFF99)
- Purple outline (#6633CC)

Animation: Lightning bolt striking and electricity dispersing
- Frame 1: Bright flash, bolt hitting target area
- Frame 2: Maximum brightness, electric arcs radiating outward
- Frame 3: Central bolt fading, arcs at maximum spread
- Frame 4: Electricity breaking into smaller sparks
- Frame 5: Sparks dissipating, residual glow
- Frame 6: Final sparkles fading away

Effects:
- Bright white flash in center
- Electric arcs in radial pattern
- Small spark particles
```

---

## 💫 4. ARCANE ORB - Orbe Arcano (ORBITAL)

> ⚠️ **TIPO ESPECIAL: ORBITAL**
> Este arma NO dispara proyectiles. Los orbes orbitan ALREDEDOR del jugador y hacen daño por contacto.
> Solo necesita animación de **ORBIT** (loop infinito mientras gira).

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Mystical arcane orb with pulsing magical energy - orbits around player

Design:
- Shape: Perfect glowing sphere with rotating inner magical swirl
- Main body: Rich purple (#9933FF) with magical depth
- Inner swirl: Bright pink-magenta (#FF66CC) energy spiral that ROTATES
- Core glow: White-lavender (#E6CCFF) pulsing at center
- Floating runes: Pale purple (#CC99FF) symbols orbiting the sphere
- Outline: Deep dark purple (#2A0A4D), 2 pixels

Animation: Orb with ROTATING internal energy and PULSING glow (LOOPS INFINITELY)
- Frames 1-8: The inner swirl pattern rotates 360° through the 8 frames
- Core brightness PULSES: dim → bright → dim through the cycle
- 2-3 arcane runes slowly orbit AROUND the orb (different positions each frame)
- Subtle size "breathing" effect (99% → 101% → 99%)

Frame-by-frame breakdown:
- Frame 1: Swirl at 0°, core at minimum brightness, runes at position A
- Frame 2: Swirl at 45°, core brightening
- Frame 3: Swirl at 90°, core bright
- Frame 4: Swirl at 135°, core at maximum brightness, magical flash
- Frame 5: Swirl at 180°, core starting to dim
- Frame 6: Swirl at 225°, core dimming
- Frame 7: Swirl at 270°, core dim
- Frame 8: Swirl at 315°, core at minimum, ready to loop back to frame 1

Key concept: A LIVING magical orb with constantly swirling internal energy

Effects:
- Inner pink swirl clearly visible rotating inside purple sphere
- Pulsing core brightness (like a magical heartbeat)
- 2-3 small arcane rune symbols floating around (☆, ✦, ◇ shapes)
- Soft purple glow halo that pulses with core brightness
- Magical sparkle particles occasionally appearing
- The orb feels ALIVE and full of magical energy

Style: Cartoon/Funko Pop, clean shapes, bold outlines, no anti-aliasing on edges.
This animation must loop SEAMLESSLY from frame 8 back to frame 1.

Output file: orbit_spritesheet_arcane_orb.png (512x64)
```

---

## 🗡️ 5. SHADOW DAGGER - Daga de Sombra

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: A ghostly shadow dagger projectile

Design:
- Shape: Sleek curved dagger, slightly ethereal/translucent
- Main body: Dark purple (#4D1A66)
- Shadow core: Near black (#1A0A26)
- Ghost highlight: Pale blue-white (#CCCCFF)
- Outline: Very dark (#1A0A26)

Animation: Dagger spinning with ghostly afterimages
- Frames 1-6: Dagger rotating showing slightly translucent effect
- Shadow wisps trailing behind
- Ghostly afterimage effect on each frame

Effects:
- Dark smoke/shadow wisps flowing from the blade
- Translucent/ghost-like appearance
- Ethereal glow on cutting edge
- Subtle afterimage echo behind main dagger
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Shadow dagger impact with darkness burst

Design:
- Same palette: dark purple (#4D1A66), black (#1A0A26), pale (#CCCCFF)

Animation: Dagger piercing and dispersing into shadows
- Frame 1: Dagger hitting, starting to phase through
- Frame 2: Dark energy bursting from impact point
- Frame 3: Maximum shadow burst, tendrils spreading
- Frame 4: Shadow wisps dissipating
- Frame 5: Darkness fading, ghost particles
- Frame 6: Final shadow particles disappearing

Effects:
- Shadow tendrils reaching outward
- Ghostly particles floating up
- Dark smoke effect
```

---

## 🌿 6. NATURE STAFF - Hoja Mágica

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: A magical glowing leaf projectile

Design:
- Shape: Round, friendly leaf shape with slight glow
- Main body: Bright green (#4DCC33)
- Highlights: Light green (#99FF66)
- Glow: Pale yellow-green (#CCFF99)
- Outline: Dark green (#1A4D13)

Animation: Leaf spinning and glowing as it flies
- Frames 1-6: Leaf gently tumbling/rotating
- Soft pulsing glow effect
- Small nature particles following

Effects:
- Tiny petal/flower particles trailing behind
- Nature sparkle effects
- Soft green glow aura
- Possible small dewdrop highlight
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Magic leaf impact with nature burst

Design:
- Same palette: green (#4DCC33), light green (#99FF66), pale green (#CCFF99)
- Dark green outline (#1A4D13)

Animation: Leaf hitting and bursting into nature energy
- Frame 1: Leaf landing, starting to glow brighter
- Frame 2: Nature energy burst, petals flying
- Frame 3: Maximum bloom, flower petals everywhere
- Frame 4: Petals spreading outward
- Frame 5: Petals fading, sparkles remain
- Frame 6: Final nature sparkles disappearing

Effects:
- Flower petals flying outward
- Nature sparkle particles
- Soft green glow flash
```

---

## 💨 7. WIND BLADE - Corte de Viento

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: A curved wind slash/blade projectile

Design:
- Shape: Crescent blade shape, wispy edges, semi-transparent
- Main body: Pale cyan (#E6FFFF)
- Core: Pure white (#FFFFFF)
- Edge glow: Light cyan (#CCFFFF)
- Outline: Muted teal (#99CCCC)

Animation: Wind blade spinning with air currents
- Frames 1-6: Crescent rotating/slicing through air
- Air current lines flowing around blade
- Semi-transparent appearance

Effects:
- Motion blur lines showing speed
- Small cloud puff particles
- Wispy air current trails
- Slightly see-through/ethereal look
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Wind blade dispersing into air

Design:
- Same palette: pale cyan (#E6FFFF), white (#FFFFFF), light cyan (#CCFFFF)
- Muted teal outline (#99CCCC)

Animation: Wind blade dissolving into air currents
- Frame 1: Blade hitting, starting to disperse
- Frame 2: Wind burst, air currents radiating
- Frame 3: Maximum wind burst, wispy tendrils everywhere
- Frame 4: Air currents spiraling outward
- Frame 5: Wisps fading, small clouds remain
- Frame 6: Final wisps and cloud puffs fading

Effects:
- Spiral wind patterns
- Small cloud puffs
- Wispy air current lines
```

---

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 SECCIÓN AOE (ÁREA DE EFECTO)
# ═══════════════════════════════════════════════════════════════════════════════
# 
# INSTRUCCIONES PARA GENERAR SPRITES AOE:
# 1. Todos los AOE son vista TOP-DOWN (desde arriba)
# 2. Fondo 100% TRANSPARENTE - NO dibujar suelo, terreno ni superficie
# 3. Solo el EFECTO VISUAL: partículas, energía, fracturas luminosas, etc.
# 4. SEMITRANSPARENCIA: Los efectos deben ser semi-transparentes para integrarse
# 5. Estilo: Cartoon/Funko Pop - formas redondeadas, colores saturados
# 6. Outline sutil de 1-2 píxeles para definir formas
# 7. Efecto circular/radial centrado en el frame
#
# ⚠️ IMPORTANTE: NO incluir suelo, piedras, tierra, hierba ni ningún terreno.
# El efecto debe poder superponerse sobre CUALQUIER bioma del juego.
#
# FORMATO DE ARCHIVOS:
# - Active: 6 frames @ 64x64 = 384x64 total (LOOP)
# - El sistema usa tweens procedurales para appear (scale 0→1) y fade (alpha→0)
#
# ═══════════════════════════════════════════════════════════════════════════════

## 🪨 AOE-01. EARTH SPIKE - Pico de Tierra

> Arma base: earth_spike
> Picos de roca emergiendo del suelo, aturde enemigos
> Archivo: `weapons/earth_spike/aoe_active_earth_spike.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Rock spikes ONLY - NO ground/terrain. Just the spikes emerging upward as seen from above, floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground, floor, dirt, stones or terrain. ONLY the rock spikes themselves with dust particles. The effect must overlay on any game biome.

COLOR PALETTE:
- Primary: Brown rock (#996633) - semi-transparent edges
- Secondary: Tan highlights (#CC9966)
- Accent: Light brown dust particles (#DDBB88) - very transparent
- Outline: Dark brown (#4D3319)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Spikes visible from above, dust floating
- Frame 3-4: Spikes pulse slightly, more dust
- Frame 5-6: Spikes settle, dust dissipates

EFFECTS:
- Rock spikes as circular arrangement seen from top
- Floating semi-transparent dust particles
- NO ground texture - pure transparent background
- Spikes should have some transparency at edges
```

---

## 🌀 AOE-02. VOID PULSE - Pulso del Vacío

> Arma base: void_pulse
> Singularidad oscura que succiona y daña, efecto pull
> Archivo: `weapons/void_pulse/aoe_active_void_pulse.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Void singularity energy ONLY - NO ground. Swirling dark energy vortex floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or surface. ONLY the void energy effect itself. Pure ethereal dark energy.

COLOR PALETTE:
- Primary: Deep purple-black (#1A001A) - core
- Secondary: Dark violet (#330033) - swirls
- Accent: Bright purple energy (#9933FF) - semi-transparent wisps
- Outline: Near-black (#0D000D)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Void vortex stable, particles drifting inward
- Frame 3-4: Vortex pulses larger, energy intensifies
- Frame 5-6: Vortex contracts, energy ripples outward

EFFECTS:
- Swirling dark energy (semi-transparent)
- Purple energy wisps being sucked to center
- Distortion rings (transparent)
- NO ground - pure void energy floating
```

---

## 💨🔥 AOE-03. STEAM CANNON - Cañón de Vapor

> Fusión: ice_wand + fire_wand
> Explosión de vapor ardiente, mezcla de agua y fuego
> Archivo: `fusion/steam_cannon/aoe_active_steam_cannon.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Steam cloud ONLY - NO ground. Billowing steam and vapor floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or surface. ONLY the steam/vapor clouds themselves. Pure atmospheric effect.

COLOR PALETTE:
- Primary: White steam (#FFFFFF) - semi-transparent (50-70% opacity)
- Secondary: Light gray mist (#CCCCCC) - very transparent
- Accent: Orange-red heat glow (#FF6633) - subtle, transparent
- Outline: Gray-blue (#667788) - subtle

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Steam clouds billowing, heat shimmer
- Frame 3-4: Steam intensifies, orange glow at center
- Frame 5-6: Steam disperses slightly, cycle resets

EFFECTS:
- Billowing semi-transparent steam clouds
- Heat shimmer (wavy transparent distortion)
- NO ground - clouds floating on transparency
- Warm orange undertones in center
```

---

## 🌋💀 AOE-04. RIFT QUAKE - Terremoto Dimensional

> Fusión: earth_spike + void_pulse
> Fisuras dimensionales en la tierra, combina tierra y vacío
> Archivo: `fusion/rift_quake/aoe_active_rift_quake.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Glowing dimensional cracks ONLY - NO ground. Purple energy fissures floating on transparent background, like cracks in reality itself.

⚠️ CRITICAL: Do NOT draw any ground, earth or terrain. ONLY the glowing crack lines with void energy. The cracks are pure energy, not physical ground.

COLOR PALETTE:
- Primary: Bright purple void energy (#9933FF) - the crack lines
- Secondary: Deep purple glow (#330033) - aura around cracks
- Accent: White-violet core (#CC99FF) - brightest parts
- Outline: Dark purple (#2D0033)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Energy cracks stable, void glowing within
- Frame 3-4: Cracks pulse brighter, energy surges
- Frame 5-6: Energy settles, cracks dim slightly

EFFECTS:
- Glowing crack lines (semi-transparent energy)
- Void tendrils emerging from fissures
- Purple energy particles
- NO ground - pure energy cracks floating
```

---

## 🌀💨 AOE-05. VOID STORM - Tormenta del Vacío

> Fusión: void_pulse + wind_blade
> Vórtice dimensional con vientos del vacío
> Archivo: `fusion/void_storm/aoe_active_void_storm.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Swirling void vortex ONLY - NO ground. Dark energy tornado with cyan wind streaks floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or surface. ONLY the swirling vortex energy itself.

COLOR PALETTE:
- Primary: Deep void black (#1A001A) - core, semi-transparent
- Secondary: Cyan wind streaks (#66FFFF) - semi-transparent
- Accent: Dark purple (#330033) - energy wisps
- Outline: Black (#000000) - subtle

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Vortex spinning, void center stable
- Frame 3-4: Spin accelerates, wind streaks prominent
- Frame 5-6: Vortex pulses, energy disperses slightly

EFFECTS:
- Spiral wind lines (semi-transparent cyan)
- Dark void center (semi-transparent)
- Energy particles spinning
- NO ground - pure floating vortex
```

---

## ❄️🪨 AOE-06. GLACIER - Glaciar

> Fusión: ice_wand + earth_spike
> Espinas de hielo cristalizado emergiendo del suelo
> Archivo: `fusion/glacier/aoe_active_glacier.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Ice crystal spikes ONLY - NO ground. Crystalline ice formations floating on transparent background as seen from above.

⚠️ CRITICAL: Do NOT draw any ground, snow or terrain. ONLY the ice crystals/spikes themselves with frost particles.

COLOR PALETTE:
- Primary: Light cyan ice (#66FFFF) - semi-transparent crystals
- Secondary: White frost (#FFFFFF) - highlights, transparent
- Accent: Pale blue-gray (#B3D9E6) - depth
- Outline: Dark cyan-blue (#1A5C66)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Ice crystals gleaming, frost particles floating
- Frame 3-4: Crystal reflections shift, sparkles appear
- Frame 5-6: Sparkles flash, frost settles

EFFECTS:
- Semi-transparent ice crystals seen from above
- Floating frost particles
- Crystalline sparkle effects
- NO ground - crystals on pure transparency
```

---

## ❄️🌀 AOE-07. ABSOLUTE ZERO - Cero Absoluto

> Fusión: ice_wand + void_pulse
> Congelación absoluta del espacio-tiempo
> Archivo: `fusion/absolute_zero/aoe_active_absolute_zero.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Frozen void singularity ONLY - NO ground. Dark void core surrounded by frozen ice crystals, all floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or surface. ONLY the void-ice energy effect itself.

COLOR PALETTE:
- Primary: Deep black-purple void (#0D0019) - core, semi-transparent
- Secondary: Pale cyan ice (#99CCFF) - frozen particles, transparent
- Accent: Dark purple-blue (#330066) - energy
- Outline: Near black (#0A0A1A)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Frozen void stable, ice crystals suspended
- Frame 3-4: Void pulses, crystals shimmer
- Frame 5-6: Cold energy radiates outward

EFFECTS:
- Semi-transparent void core
- Floating frozen particles (time-stopped feeling)
- Ice crystals suspended in air
- NO ground - pure ethereal frozen void
```

---

## 🔥🪨 AOE-08. VOLCANO - Volcán

> Fusión: fire_wand + earth_spike
> Erupción volcánica con lava y rocas fundidas
> Archivo: `fusion/volcano/aoe_active_volcano.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Lava eruption ONLY - NO ground/crater. Splashing lava, flames and embers floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground, crater or rock surface. ONLY the lava splashes, flames and ember particles themselves.

COLOR PALETTE:
- Primary: Bright orange lava (#FF6600) - semi-transparent
- Secondary: Red-orange magma (#CC3300) - glowing
- Accent: Yellow-white hot core (#FFCC00) - brightest
- Outline: Dark red (#661100)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Lava splashes at peak, embers floating
- Frame 3-4: More splashes erupt, flames dance
- Frame 5-6: Lava falls back, embers scatter

EFFECTS:
- Lava splash droplets (semi-transparent)
- Rising ember particles
- Flame wisps
- NO ground/crater - pure lava effect floating
```

---

## 🔥🌀 AOE-09. DARK FLAME - Llama Oscura

> Fusión: fire_wand + void_pulse
> Llamas del vacío que queman y succionan
> Archivo: `fusion/dark_flame/aoe_active_dark_flame.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Dark void flames ONLY - NO ground. Purple-red ethereal fire floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or surface. ONLY the dark flame effect itself.

COLOR PALETTE:
- Primary: Dark purple-red flames (#660033) - semi-transparent
- Secondary: Deep crimson (#990033) - fire core
- Accent: Black-purple void (#1A001A) - wisps
- Outline: Near black (#0D000D)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Dark flames flickering, void wisps floating
- Frame 3-4: Flames spiral inward, intensity increases
- Frame 5-6: Flames dance outward, cycle resets

EFFECTS:
- Semi-transparent dark fire
- Void energy wisps being pulled to center
- Soul-like ethereal particles
- NO ground - pure floating dark flames
```

---

## ⚡🪨 AOE-10. SEISMIC BOLT - Descarga Sísmica

> Fusión: lightning_wand + earth_spike
> Descarga eléctrica que fractura el suelo
> Archivo: `fusion/seismic_bolt/aoe_active_seismic_bolt.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Electric crack lines ONLY - NO ground. Glowing yellow lightning fractures floating on transparent background, like cracks of pure electricity.

⚠️ CRITICAL: Do NOT draw any ground, rocks or terrain. ONLY the electric crack energy lines themselves.

COLOR PALETTE:
- Primary: Bright yellow lightning (#FFFF00) - the crack lines
- Secondary: Orange-yellow glow (#FFAA00) - aura around cracks
- Accent: White-yellow core (#FFFFCC) - brightest centers
- Outline: Dark amber (#664400)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Electric cracks glowing, arcs jumping
- Frame 3-4: Arcs intensify, more branches appear
- Frame 5-6: Electricity crackles, settles

EFFECTS:
- Glowing electric crack lines (semi-transparent glow)
- Lightning arcs jumping between cracks
- Electric sparkle particles
- NO ground - pure floating electricity
```

---

## 🌿🪨 AOE-11. GAIA - Gaia

> Fusión: nature_staff + earth_spike
> Poder primordial de la tierra viva
> Archivo: `fusion/gaia/aoe_active_gaia.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Glowing roots and nature energy ONLY - NO ground. Living vines/roots with green energy floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or terrain. ONLY the roots, vines and nature energy particles themselves.

COLOR PALETTE:
- Primary: Moss green-brown roots (#668844) - semi-transparent
- Secondary: Root brown (#886633)
- Accent: Bright nature green energy (#66FF66) - glowing, transparent
- Outline: Dark green-brown (#2D3319)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Roots visible, green energy glowing
- Frame 3-4: Roots pulse with life, energy intensifies
- Frame 5-6: Healing waves radiate, settles

EFFECTS:
- Semi-transparent root structures
- Green glowing energy particles
- Floating leaf particles
- NO ground - roots on pure transparency
```

---

## 🌿🌀 AOE-12. DECAY - Decadencia

> Fusión: nature_staff + void_pulse
> Descomposición dimensional, naturaleza corrupta
> Archivo: `fusion/decay/aoe_active_decay.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Corrupted vines and void energy ONLY - NO ground. Sickly green-purple tendrils with drain effect floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or terrain. ONLY the corrupted vine energy and void particles.

COLOR PALETTE:
- Primary: Sickly green-brown vines (#556622) - semi-transparent
- Secondary: Dark purple void (#330033) - corruption
- Accent: Yellow-green rot glow (#99AA33) - decay energy
- Outline: Near black-green (#0D1A0D)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Dead vines visible, void energy pulsing
- Frame 3-4: Vines twitch, life drain particles toward center
- Frame 5-6: Decay spreads, void contracts

EFFECTS:
- Semi-transparent corrupted tendrils
- Life drain particles (green to purple)
- Void core pulsing
- NO ground - pure floating corruption
```

---

## 🪨✨ AOE-13. RADIANT STONE - Piedra Radiante

> Fusión: earth_spike + light_beam
> Pilares de cristal divino emergiendo del suelo
> Archivo: `fusion/radiant_stone/aoe_active_radiant_stone.png`

### Active Animation (6 frames)
```
Create a horizontal sprite strip for a 2D roguelike game.
FORMAT: 6 frames, 64x64 pixels each = 384x64 total. 100% TRANSPARENT background.
STYLE: Cartoon/Funko Pop - cute, bold colors, 1-2px dark outline on shapes.
VIEW: TOP-DOWN (looking straight down)

SUBJECT: Glowing divine crystals ONLY - NO ground. Holy light crystal formations floating on transparent background.

⚠️ CRITICAL: Do NOT draw any ground or terrain. ONLY the radiant crystal formations and light particles.

COLOR PALETTE:
- Primary: Pale gold-white crystals (#FFFFCC) - semi-transparent
- Secondary: Pure white light (#FFFFFF) - glow
- Accent: Tan-gold stone (#DDAA77) - crystal depth
- Outline: Muted gold (#AA8855)

ANIMATION SEQUENCE (LOOP):
- Frame 1-2: Crystals gleaming, holy light stable
- Frame 3-4: Light pulses through crystals, sparkles appear
- Frame 5-6: Divine glow breathes, settles

EFFECTS:
- Semi-transparent radiant crystals
- Holy light sparkle particles
- Light pulse waves (very transparent)
- NO ground - crystals on pure transparency
```

---


## ✨ 9. LIGHT BEAM - Rayo de Luz

### Start Animation (4 frames)
```
Create a horizontal sprite strip of 4 frames (64x64 each = 256x64 total).

Subject: Holy light beam forming

Design:
- Main beam: Pale yellow (#FFFFCC)
- Core: Pure white (#FFFFFF)
- Glow: Soft yellow (#FFFF99)
- Outline: Gold (#CCAA66)

Animation: Beam charging and forming
- Frame 1: Small point of light appearing
- Frame 2: Light expanding, beam starting to form
- Frame 3: Beam extending, sparkles appearing
- Frame 4: Full beam formed, divine glow

Effects:
- Light particles gathering
- Star/sparkle effects
- Divine glow halo
```

### Active Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Holy light beam active/sustained

Design:
- Same palette: pale yellow (#FFFFCC), white (#FFFFFF), yellow (#FFFF99)
- Gold outline (#CCAA66)

Animation: Beam pulsing with holy energy
- Frames 1-6: Beam intensity pulsing
- Star particles flowing through beam
- Soft shimmer effect

Effects:
- Flowing light particles within beam
- Small star sparkles
- Soft warm glow around beam
- Lens flare effects
```

### End Animation (4 frames)
```
Create a horizontal sprite strip of 4 frames (64x64 each = 256x64 total).

Subject: Holy light beam dissipating

Design:
- Same color palette as above

Animation: Beam fading away gracefully
- Frame 1: Full beam starting to dim
- Frame 2: Beam breaking into light particles
- Frame 3: Particles spreading, beam mostly gone
- Frame 4: Final sparkles fading away

Effects:
- Particles rising upward
- Soft glow lingering
- Final divine sparkles
```

---

## � FUSIONES PRINCIPALES

---

## ⚡💨 12. STORM CALLER (Lightning + Wind) - CHAIN

### Flight Animation (4 frames)
```
Create a pixel art horizontal sprite sheet of a STORM LIGHTNING BOLT projectile for a 2D game, in cute chibi/Funko Pop cartoon style. LAYOUT: 4 frames in a single horizontal strip, each frame in its own cell of approximately 150x100 pixels. Total image around 600x400 pixels. Transparent background. THE PROJECTILE: A crackling lightning bolt surrounded by swirling cyan wind currents - electricity meets storm winds. The bolt should have a wind vortex spiraling around it. COLOR PALETTE: - Core: Bright white (#FFFFFF) - Primary: Electric yellow (#FFFF33 / #FFFF66) - Secondary: Cyan wind (#66FFFF / #99FFFF) - Accent: White-blue sparks - Outline: Blue-gray (#334466) ANIMATION SEQUENCE (4 frames): Frame 1: Lightning bolt forming with wind currents beginning to swirl Frame 2: Bolt crackles, wind vortex tightens around it, sparks fly Frame 3: Maximum intensity, bright electric core with cyan wind spiral at peak Frame 4: Energy pulse, wind currents disperse slightly, cycle back IMPORTANT DETAILS: - Orientation: Bolt pointing RIGHT (→) as if flying toward target - Electric crackling with visible wind current lines - Combination of sharp lightning with flowing wind - Storm particles and mini cloud puffs around the bolt - Cartoon-cute but powerful stormy appearance - Each frame clearly separated in its own cell
```

### Impact Animation (4 frames)
```
Create a pixel art horizontal sprite sheet of a STORM LIGHTNING EXPLOSION IMPACT for a 2D game, in cute chibi/Funko Pop cartoon style. LAYOUT: 4 frames in a single horizontal strip, each frame in its own cell of approximately 150x100 pixels. Total image around 600x400 pixels. Transparent background. THE EFFECT: A burst of electric storm energy when hitting an enemy - yellow lightning arcs with cyan wind bursting outward in a spiral pattern. COLOR PALETTE: - Core: Bright white flash (#FFFFFF) - Primary: Electric yellow (#FFFF33 / #FFFF66) - Secondary: Cyan wind (#66FFFF / #99FFFF) - Accent: White-blue electric sparks - Outline: Blue-gray (#334466) ANIMATION SEQUENCE (4 frames): Frame 1: Initial flash - white-yellow burst center with wind beginning to spiral outward Frame 2: Expansion - lightning arcs shoot outward with wind currents spiraling between them Frame 3: Maximum spread - storm explosion with electric sparks and swirling wind particles Frame 4: Dissipation - energy fades, last sparks, lingering wind wisps IMPORTANT DETAILS: - Radial burst pattern with spiral wind motion - Lightning arcs mixed with cyan wind swirls - Storm cloud puff particles - Feeling of "electric tornado" explosion - Cartoon-cute style with clear, readable shapes - Each frame clearly separated in its own cell
```

---

## 💀🌿 13. SOUL REAPER (Shadow + Nature) - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Small spectral scythe projectile

Design:
- Blade: Dark purple (#4D1A4D)
- Soul energy: Green (#66CC33)
- Glow: Bright green (#99FF66)
- Outline: Very dark (#1A0A1A)

Animation: Mini scythe spinning with soul wisps
- Frames 1-6: Scythe rotating
- Green soul energy flowing around blade
- Shadow smoke trailing

Effects:
- Green soul wisps flowing
- Shadow smoke particles
- Ethereal glow on blade edge
- Ghostly afterimage
```

---

## ⭐✨ 14. COSMIC BARRIER (Arcane + Light) - ORBIT

> Fusión: arcane_orb + light_beam
> Escudo orbital brillante - combina magia arcana con luz divina

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Star-shaped magical orb with divine light - protective barrier orbital

Design:
- Shape: Star-orb hybrid - spherical core with 4-6 pointed rays extending outward
- Main body: Pale golden-cream (#FFFFCC) with warm glow
- Magic swirl: Light purple-pink (#CC99FF) inside the core
- Ray tips: Pure white (#FFFFFF) divine light
- Sparkles: Golden (#FFE066) star particles
- Outline: Muted purple-gold (#996688), 2 pixels

Animation: Star-orb ROTATING with rays pulsing and divine light shimmering
- Frames 1-8: Star shape rotates 360° through the animation
- Rays PULSE: extend outward then retract slightly
- Internal purple swirl rotates opposite to outer star
- Core brightness cycles: warm → bright white → warm

Frame-by-frame breakdown:
- Frame 1: Star at 0°, rays at normal length, core warm
- Frame 2: Star at 45°, rays starting to extend
- Frame 3: Star at 90°, rays at maximum extension, bright flash
- Frame 4: Star at 135°, core at peak brightness
- Frame 5: Star at 180°, rays retracting
- Frame 6: Star at 225°, core dimming
- Frame 7: Star at 270°, rays at minimum
- Frame 8: Star at 315°, ready to loop

Key concept: DIVINE PROTECTION orb - warm, inviting, defensive feel

Effects:
- Pointed star rays that glow with divine light
- Inner purple magic swirl (arcane heritage)
- Golden star sparkle particles floating around
- Soft white-gold halo surrounding the orb
- Protective, benevolent energy feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_cosmic_barrier.png (512x64)
```

---

## ❄️🌿 16. FROSTVINE (Ice + Nature) - Enredadera de Hielo - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Frozen seed/pod with ice vines growing from it - a living frost projectile

Design:
- Shape: Oval seed pod with 2-3 curling ice tendrils/vines extending outward
- Main body (seed): Mint green ice (#66FFCC), semi-translucent
- Ice vines: Cyan gradient (#99FFFF to #66DDDD), organic curved shapes
- Nature core: Bright pale mint glow inside seed (#CCFFEE)
- Frost crystals: Small ice thorns along vines (#AAFFEE)
- Outline: Deep teal (#336655), 1-2 pixels, consistent on all elements

Animation: Seed pulses while vines writhe and reach forward
- Frame 1: Seed compact, vines curled close, core dim
- Frame 2: Core starts glowing, vines begin unfurling rightward
- Frame 3: Vines extending further, frost crystals forming on tips
- Frame 4: Maximum extension, core brightest, vines reaching hungrily
- Frame 5: Vines retracting slightly, preparing for next pulse
- Frame 6: Returning to compact form, core dimming, cycle ready to loop

Effects:
- 2-3 small frost leaf particles floating nearby
- Core pulsing (brightness changes like heartbeat)
- Ice sparkles at vine tips when extended
- Vines move organically like living tentacles
- Frost mist trail behind the seed
- Living/organic feel - this projectile is ALIVE and hungry

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Frostvine seed BURSTS and ice vines rapidly grow outward to ensnare target

Design:
- Same palette: Mint green (#66FFCC), cyan (#99FFFF), pale mint (#CCFFEE)
- Ice vines: Teal to cyan (#448866 to #66FFCC)
- Frost thorns: Bright cyan (#AAFFEE)
- Outline: Deep teal (#336655)

Animation: Seed explodes into rapidly growing frost vines that spread in all directions
- Frame 1: Seed impacts - bright flash at center, cracks appear on pod
- Frame 2: Pod splits open, 4-5 ice vines BURST outward in radial pattern
- Frame 3: Vines growing rapidly longer, frost crystals forming, center glowing
- Frame 4: Maximum vine spread (fills most of frame), thorns visible, peak frost
- Frame 5: Vines start crystallizing/hardening, becoming more jagged ice
- Frame 6: Vines shatter into frost mist and frozen leaf particles, dissipating

Key visual concept: NOT a simple explosion - vines GROW outward like time-lapse of plant growth, then freeze solid and shatter

Effects:
- Vines grow in organic curves, not straight lines
- Frost crystals/thorns appear along vine length
- Central burst of nature energy (mint-white flash)
- Ice particles spreading outward in final frames
- Frozen leaf/petal shapes mixed with ice shards
- Feeling of entangling/grabbing before shattering

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🔥🌿 17. WILDFIRE (Fire + Nature) - Fuego Salvaje - MULTI (Homing)

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Living flame with plant-like organic form - fire that grows like vegetation

Design:
- Shape: Flame with leaf/petal-like fire tongues, organic curves instead of sharp flames
- Main fire body: Bright orange (#FF6611) with yellow core (#FFCC00)
- Leaf-flame tips: Yellow-green transitioning to orange (#CCFF33 fading to #FF8822)
- Inner glow: Bright yellow-white (#FFEE66)
- Ember particles: Orange-red (#FF4400)
- Outline: Deep burnt orange (#993300), 1-2 pixels

Animation: Living flame that breathes and reaches outward like growing plant
- Frame 1: Compact flame, leaf-shaped tongues curled inward
- Frame 2: Flame expanding, leaf-tongues unfurling rightward (seeking prey)
- Frame 3: Maximum reach, 3-4 leaf-shaped flame tendrils extended
- Frame 4: Flame pulsing brighter, tendrils at peak extension
- Frame 5: Tendrils retracting, preparing for next pulse
- Frame 6: Returning to compact form, embers trailing

Key concept: This fire BEHAVES like a plant - it grows, reaches, and spreads organically

Effects:
- Flame tongues shaped like leaves/petals, not jagged fire
- Organic flowing motion, not chaotic flickering
- Small ember seeds floating around (like burning pollen)
- Yellow-green tinge at the tips (nature influence)
- Warm glow that pulses with the animation
- Homing feel - the flame reaches TOWARD something

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Wildfire impact - flame bursts and SPREADS like rapidly growing fire vegetation

Design:
- Same palette: Orange (#FF6611), yellow (#FFCC00), yellow-green tips (#CCFF33)
- Spreading flames: Orange-red (#FF4400)
- Ember seeds: Bright yellow (#FFEE44)
- Outline: Burnt orange (#993300)

Animation: Fire hits and spreads outward like wildfire consuming dry grass
- Frame 1: Impact flash - bright yellow-white burst at center
- Frame 2: Fire splashes outward in 4-5 leaf-shaped flame bursts
- Frame 3: Flames SPREADING further, growing like vegetation consuming ground
- Frame 4: Maximum spread - ring of organic flames, burning seed particles flying
- Frame 5: Outer flames turning to embers, center still burning
- Frame 6: Embers and burning leaf particles floating away, dissipating

Key visual concept: Fire that SPREADS and GROWS, not just explodes - like watching grass fire in fast-forward

Effects:
- Flames spread in organic patterns, not circular explosion
- Leaf-shaped flame tongues reaching outward
- Burning seed/pollen particles scattering (spreading the fire)
- Ground-hugging spread pattern (wildfire behavior)
- Yellow-green hints at flame tips (nature magic)
- Embers that look like they could start new fires

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🌪️🔥 18. FIRESTORM (Fire + Wind) - Tormenta de Fuego - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Spinning fire tornado projectile - a miniature firestorm

Design:
- Shape: Compact spiral/vortex of flames, funnel-like tornado shape from above
- Fire body: Bright orange (#FF6600) with red-orange core (#FF4400)
- Wind spiral: Pale orange-white (#FFCC99) showing air movement
- Inner core: Bright yellow-white (#FFEE66) at the center (hot spot)
- Ember particles: Orange-red sparks (#FF5500)
- Outline: Deep red-brown (#662200), 1-2 pixels

Animation: Fire tornado spinning rapidly and pulsing with heat
- Frame 1: Spiral tight, flames concentrated
- Frame 2: Spinning, flames start spreading outward from rotation
- Frame 3: Maximum spin visible, wind lines showing rotation
- Frame 4: Flames flaring outward from centrifugal force
- Frame 5: Spiral tightening again, intense heat at center
- Frame 6: Return to tight form, ready to loop

Key concept: SPINNING fire - the wind element creates ROTATIONAL motion

Effects:
- Clear spiral/vortex pattern visible from above
- Wind lines (lighter color) showing rotation direction
- Embers flying off tangentially from the spin
- Heat shimmer around the tornado
- Pulsing intensity as it spins
- High speed, high knockback feel

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Fire tornado impact - explosive spiral burst with massive knockback

Design:
- Same palette: Orange (#FF6600), red-orange (#FF4400), yellow-white core (#FFEE66)
- Wind burst: Pale orange-white (#FFCC99)
- Flying embers: Bright orange-red (#FF5500)
- Outline: Deep red-brown (#662200)

Animation: Spinning fire explodes outward in spiral pattern
- Frame 1: Impact - tornado compresses, bright flash at center
- Frame 2: Spiral explosion begins - flames shoot outward in CURVED paths (following spin)
- Frame 3: Maximum burst - spiral arms of fire expanding, wind visible
- Frame 4: Flames continuing outward in curved trajectories, embers everywhere
- Frame 5: Spiral arms dissipating, embers still flying in curves
- Frame 6: Final ember sparks curving away, smoke wisps fading

Key visual concept: Explosion follows SPIRAL pattern, not radial - flames curve as they fly out

Effects:
- Curved flame trails showing the spin momentum
- Wind burst lines in spiral pattern
- Embers flying in curved paths (tangential)
- Central heat flash
- Smoke/ash wisps spinning outward
- High-energy, violent dispersal feel

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🔥💀 19. HELLFIRE (Fire + Shadow) - Fuego Infernal - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Dark demonic flame projectile - corrupted fire with shadow essence

Design:
- Shape: Flame orb with jagged, aggressive flame tongues reaching outward
- Main fire body: Deep crimson red (#990033) with dark red core (#660022)
- Shadow wisps: Near black tendrils (#1A0A0A) weaving through the flames
- Fire highlights: Bright orange-red (#FF4422) at flame tips
- Inner glow: Sinister magenta-red (#CC2244)
- Outline: Very dark purple-red (#330011), 1-2 pixels

Animation: Demonic flame flickering aggressively with shadow tendrils writhing
- Frame 1: Compact dark flame, shadow wisps curled close
- Frame 2: Flames flare outward, shadow tendrils start reaching
- Frame 3: Maximum aggression - jagged flame tongues, shadows spreading
- Frame 4: Flame pulses brighter, shadows at peak extension
- Frame 5: Flames retracting slightly, shadows coiling back
- Frame 6: Return to compact form, ready to loop

Key concept: This fire is CORRUPTED - shadows and flames intertwine like fighting/dancing together

Effects:
- Shadow wisps/tendrils weaving through the fire (not separate, intertwined)
- Jagged, aggressive flame shapes (not friendly rounded flames)
- Dark smoke particles trailing
- Sinister red-orange glow
- Embers that look like tiny dark sparks
- Menacing, evil appearance - this fire wants to hurt

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Hellfire impact - dark flame explosion that burns and corrupts

Design:
- Same palette: Deep crimson (#990033), dark red (#660022), orange-red (#FF4422)
- Shadow burst: Near black (#1A0A0A)
- Dark embers: Deep red (#881122)
- Outline: Very dark purple-red (#330011)

Animation: Corrupted fire explodes with shadow tendrils bursting outward
- Frame 1: Impact flash - sinister red-white burst at center
- Frame 2: Dark flames burst outward, shadow tendrils shoot in all directions
- Frame 3: Maximum explosion - ring of hellfire with shadows reaching like claws
- Frame 4: Flames spreading further, shadows grasping outward
- Frame 5: Fire turning to dark embers, shadow tendrils dissipating
- Frame 6: Final dark sparks and shadow wisps fading

Key visual concept: Fire and shadow EXPLODE TOGETHER - not just fire with shadow on top

Effects:
- Shadow tendrils bursting outward like dark fingers/claws
- Dark flames spreading in aggressive patterns
- Sinister red-magenta flash at center
- Dark ember particles flying
- Smoke/shadow wisps curling away
- Feeling of corruption spreading from impact point

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## ⚡🗡️ 20. DARK LIGHTNING (Lightning + Shadow) - Rayo Oscuro - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Dark electric dagger projectile - shadow-infused lightning bolt

Design:
- Shape: Sleek dagger/bolt shape with electric energy crackling along the edges
- Main body: Deep purple (#6633AA) with dark violet core (#4422AA)
- Electric arcs: Pale lavender-white (#DDCCFF) crackling along the blade
- Shadow wisps: Near black (#1A0A1A) trailing from the dagger
- Inner glow: Electric violet (#9966FF)
- Outline: Very dark purple (#220033), 1-2 pixels

Animation: Electric dagger spinning with shadow trail and crackling energy
- Frame 1: Dagger compact, shadow wisps curled, sparks minimal
- Frame 2: Electric arcs intensify, shadow trail extends
- Frame 3: Maximum crackling - arcs jumping around blade, shadows flowing
- Frame 4: Electric pulse bright, blade seems to vibrate with energy
- Frame 5: Arcs retracting, shadows coiling
- Frame 6: Return to base state, ready to loop

Key concept: Lightning CORRUPTED by shadow - electric energy with dark undertones

Effects:
- Electric arcs crackling along the blade edges (white-purple)
- Shadow wisps trailing behind like dark smoke
- Ghostly afterimage effect
- Electric sparks jumping off periodically
- Dark aura around the bright electric core
- Fast, deadly appearance - chain lightning feel

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Dark Lightning impact - electric burst with shadow dispersion

Design:
- Same palette: Deep purple (#6633AA), dark violet (#4422AA), pale lavender (#DDCCFF)
- Shadow burst: Near black (#1A0A1A)
- Electric flash: Bright white-purple (#EEDDFF)
- Outline: Very dark purple (#220033)

Animation: Electric dagger strikes and releases dark lightning in chain pattern
- Frame 1: Impact flash - bright purple-white electric burst at center
- Frame 2: Electric arcs shoot outward in zigzag patterns, shadows disperse
- Frame 3: Maximum spread - lightning arcs reaching out (chain effect visual), shadows everywhere
- Frame 4: Arcs start fragmenting into smaller sparks, shadows fading
- Frame 5: Residual sparks jumping, shadow wisps dissipating
- Frame 6: Final electric sparkles and dark particles fading

Key visual concept: Electric explosion with DARK ENERGY - not just lightning, but corrupted lightning

Effects:
- Zigzag electric arcs shooting outward (showing chain effect)
- Shadow tendrils mixing with the lightning
- Bright purple-white flash at center
- Electric spark particles flying
- Dark smoke/shadow wisps curling away
- Feeling of electricity jumping to nearby targets

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## ⚡🌿 21. THUNDER BLOOM (Lightning + Nature) - Flor del Trueno - MULTI (Homing)

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Living lightning flower projectile - electric energy in plant form

Design:
- Shape: Flower bud/bloom shape with electric petals radiating outward
- Main body: Bright electric green (#73D930) with yellow-green core (#99FF44)
- Electric petals: Glowing yellow-white tips (#FFFFAA) crackling with energy
- Leaf accents: Darker green (#339922) at base
- Lightning veins: Bright yellow (#FFFF66) running through petals
- Outline: Deep forest green (#225511), 1-2 pixels

Animation: Living flower pulsing with electric life energy, petals opening and closing
- Frame 1: Bud compact, petals closed around glowing core
- Frame 2: Petals starting to open, electric veins becoming visible
- Frame 3: Half-open bloom, lightning arcing between petal tips
- Frame 4: Full bloom - petals spread wide, maximum electric glow
- Frame 5: Petals retracting slightly, energy gathering back to core
- Frame 6: Return to semi-closed state, ready to loop

Key concept: A FLOWER made of LIGHTNING - organic plant shape with electric energy

Effects:
- Electric arcs jumping between petal tips (yellow-white)
- Glowing pollen particles floating around (electric green sparkles)
- Pulsing inner core like a heartbeat
- Leaf-shaped petals with lightning vein patterns
- Nature meets electricity - alive and crackling
- Homing feel - flower "faces" toward target

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Thunder Bloom impact - electric flower bursts into healing lightning storm

Design:
- Same palette: Electric green (#73D930), yellow-green (#99FF44), yellow-white (#FFFFAA)
- Petal fragments: Bright green (#66DD33)
- Lightning burst: Bright yellow (#FFFF66) with white core
- Outline: Deep forest green (#225511)

Animation: Flower blooms fully and explodes into electric petal storm with chain lightning
- Frame 1: Impact - flower fully opens, bright flash at center
- Frame 2: Petals burst outward, lightning arcs shoot in multiple directions (chain effect)
- Frame 3: Maximum spread - petal fragments and lightning bolts everywhere
- Frame 4: Electric chains connecting between fragments, healing energy visible (green glow)
- Frame 5: Fragments fading, residual lightning sparks
- Frame 6: Final electric pollen and green sparkles dissipating

Key visual concept: BLOOMING EXPLOSION - flower opens and releases stored electric nature energy

Effects:
- Petal-shaped fragments flying outward (organic shapes)
- Lightning bolts connecting fragments (chain lightning visual)
- Green healing energy particles rising (lifesteal effect)
- Electric pollen/spore particles scattering
- Yellow-white flash at center
- Feeling of life energy being released

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 💀🌿 22. SOUL REAPER (Shadow + Nature) - Segador de Almas - MULTI (Homing)

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Spectral scythe projectile - ghostly death blade with nature corruption

Design:
- Shape: Small curved scythe/sickle blade with ethereal wisps trailing
- Main blade: Dark purple-gray (#3D3347) with ghostly translucent edges
- Shadow core: Near black (#1A1520) at blade center
- Nature corruption: Sickly green (#66AA44) vines/veins running through blade
- Soul wisps: Pale green-white (#CCDDAA) ghostly energy trailing
- Outline: Very dark purple (#1A0A1A), 1-2 pixels

Animation: Spectral scythe spinning while soul wisps flow around it
- Frame 1: Scythe compact, wisps close, blade dim
- Frame 2: Blade rotating, green veins start glowing, wisps extending
- Frame 3: Mid-rotation, soul energy intensifying, nature corruption visible
- Frame 4: Blade at peak glow, wisps at maximum reach, harvesting feel
- Frame 5: Rotation continuing, wisps retracting slightly
- Frame 6: Return to start position, ready to loop

Key concept: A DEATH SCYTHE corrupted by NATURE - harvests souls AND life force

Effects:
- Ghostly soul wisps trailing behind (pale green-white)
- Green nature veins pulsing through dark blade
- Translucent/ethereal blade edges
- Small soul orb particles floating around
- Dark aura surrounding the bright nature corruption
- Menacing, life-draining appearance - this weapon FEEDS

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Soul Reaper impact - spectral blade harvests soul with nature drain

Design:
- Same palette: Dark purple-gray (#3D3347), near black (#1A1520), sickly green (#66AA44)
- Soul burst: Pale green-white (#CCDDAA)
- Life drain: Bright green (#88DD55) energy streams
- Outline: Very dark purple (#1A0A1A)

Animation: Scythe strikes and rips out soul energy in a harvesting motion
- Frame 1: Impact - blade cuts, bright green-white flash at strike point
- Frame 2: Soul energy RIPPING outward - green wisps being torn from impact
- Frame 3: Maximum harvest - soul fragments and nature energy swirling
- Frame 4: Life energy streams flowing BACK toward where player would be (lifesteal visual)
- Frame 5: Soul fragments dissipating, green energy fading
- Frame 6: Final wisps and dark particles fading

Key visual concept: HARVESTING souls - not just damage, but DRAINING life essence

Effects:
- Soul fragments being ripped outward then pulled back (lifesteal)
- Green life energy streams showing the drain effect
- Dark shadow burst at center
- Ghostly wisps swirling
- Nature vine fragments mixed with soul particles
- Feeling of something being TAKEN, not just destroyed

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 👻💨 23. PHANTOM BLADE (Shadow + Wind) - Hoja Fantasma - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Ghostly wind dagger projectile - spectral blade that phases through matter

Design:
- Shape: Sleek curved dagger/blade with semi-transparent ghostly edges
- Main body: Pale blue-gray (#7788AA) with translucent appearance
- Ghost core: Darker purple-gray (#3D3850) at center
- Wind trails: Cyan-white wisps (#CCDDEE) flowing around blade
- Spectral glow: Pale lavender (#AABBCC) along edges
- Outline: Dark slate blue (#2A2A40), 1-2 pixels, slightly faded

Animation: Ghost blade spinning rapidly with wind and spectral afterimages
- Frame 1: Blade solid, wind wisps tight around it
- Frame 2: Spinning, ghostly afterimage appearing behind
- Frame 3: Mid-spin, wind trails extending, blade becoming more translucent
- Frame 4: Maximum transparency, multiple afterimages visible, peak speed feel
- Frame 5: Blade reforming slightly more solid, afterimages fading
- Frame 6: Return to start, wind gathering for next spin

Key concept: A GHOST BLADE carried by WIND - phases through reality, impossibly fast

Effects:
- Ghostly afterimages trailing (semi-transparent copies)
- Wind current lines flowing around blade
- Semi-transparent/ethereal appearance throughout
- Speed blur effect on edges
- Pale cyan wind particles
- Feeling of something that CANNOT BE STOPPED - phases through everything

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Phantom Blade impact - ghost blade phases through and disperses into wind

Design:
- Same palette: Pale blue-gray (#7788AA), purple-gray (#3D3850), cyan-white (#CCDDEE)
- Wind burst: Pale cyan (#DDEEFF)
- Ghost fragments: Translucent blue-purple (#6677AA with alpha)
- Outline: Dark slate blue (#2A2A40)

Animation: Ghost blade passes through target, leaving spectral wind burst
- Frame 1: Impact moment - blade partially phased, bright flash
- Frame 2: Blade fragmenting into ghost shards AND wind burst simultaneously
- Frame 3: Maximum dispersal - ghost fragments and wind spiraling outward
- Frame 4: Ghost shards fading, wind currents dominant
- Frame 5: Wind wisps spiraling away, few ghost particles remain
- Frame 6: Final wisps and spectral sparkles vanishing

Key visual concept: NOT a solid impact - blade PHASES THROUGH and disperses into wind

Effects:
- Ghost fragments flying outward (semi-transparent shards)
- Wind spiral burst pattern
- Spectral afterimages lingering briefly
- Cyan wind current lines
- Ethereal fade-out (not hard edges)
- Feeling of something passing THROUGH, not hitting

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🗡️🪨 24. STONE FANG (Shadow + Earth) - Colmillo de Piedra - SINGLE

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Obsidian fang projectile - dark crystal tooth forged from shadow and earth

Design:
- Shape: Sharp curved fang/tooth shape with jagged obsidian texture
- Main body: Dark charcoal gray (#403340) with obsidian sheen
- Obsidian core: Near black (#332833) at center
- Earth veins: Brown-gray (#665850) cracks running through surface
- Shadow wisps: Very dark purple (#2A1F2A) trailing from base
- Highlights: Glassy obsidian shine (#807080) on edges
- Outline: Very dark (#1A1518), 1-2 pixels

Animation: Obsidian fang flying straight with subtle shadow trail and glassy shimmer
- Frame 1: Fang sharp and solid, minimal shadow trail
- Frame 2: Shadow wisps extending, obsidian catching light
- Frame 3: Maximum shadow trail, glassy highlights shifting
- Frame 4: Shadow pulsing darker, earth cracks glowing faintly
- Frame 5: Shadows retracting, fang solidifying
- Frame 6: Return to base state, ready to loop

Key concept: A TOOTH of obsidian - sharp, deadly, formed from SHADOW and EARTH combined

Effects:
- Glassy obsidian reflections shifting on surface
- Shadow wisps trailing behind like dark smoke
- Subtle earth-brown cracks pulsing with energy
- Sharp, predatory appearance
- Dark aura surrounding the fang
- Feeling of ancient, primal weapon

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Stone Fang impact - obsidian shatters into shadow and rock fragments

Design:
- Same palette: Dark charcoal (#403340), near black (#332833), brown-gray (#665850)
- Shatter fragments: Obsidian shards (#504050) with glassy edges
- Shadow burst: Very dark purple (#2A1F2A)
- Dust cloud: Brown-gray (#5A4A45)
- Outline: Very dark (#1A1518)

Animation: Obsidian fang pierces and shatters, releasing shadow and stone
- Frame 1: Impact - fang pierces, cracks spreading, flash of obsidian light
- Frame 2: Fang shattering, obsidian shards flying, shadow bursting outward
- Frame 3: Maximum spread - sharp obsidian fragments everywhere, dust cloud forming
- Frame 4: Shards spinning outward, shadow wisps mixing with earth dust
- Frame 5: Fragments falling, dust settling, shadows dissipating
- Frame 6: Final obsidian sparkles and dust particles fading

Key visual concept: OBSIDIAN EXPLOSION - sharp glass-like shards with shadow and earth dust

Effects:
- Sharp obsidian shards flying outward (glassy, reflective)
- Shadow burst at impact point
- Earth dust/debris cloud
- Glassy reflection flashes on fragments
- Dark smoke mixing with brown dust
- Feeling of something PIERCING then SHATTERING

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🌅🌙 25. TWILIGHT (Shadow + Light) - Crepúsculo - SINGLE

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Twilight orb projectile - duality sphere of shadow and light intertwined

Design:
- Shape: Spherical orb split/swirling between light and dark halves
- Light half: Warm golden-cream (#CCB8A0) with white highlights (#E5DCD0)
- Shadow half: Soft purple (#806698) with dark core (#4D3355)
- Swirl boundary: Where light meets dark - gradient mixing zone
- Accent particles: Golden sparkles on light side, purple wisps on dark side
- Outline: Medium purple-gray (#553D5D), 1-2 pixels

Animation: Twilight orb spinning with light and shadow halves flowing into each other
- Frame 1: Clear division - light on one side, shadow on other
- Frame 2: Halves starting to swirl, boundary blurring
- Frame 3: Maximum mixing - yin-yang spiral pattern forming
- Frame 4: Colors interweaving, golden and purple particles mixing
- Frame 5: Separation beginning, halves pulling apart
- Frame 6: Return to start division, ready to loop

Key concept: Neither light nor dark - the MOMENT BETWEEN them, eternally balanced

Effects:
- Golden light particles on one half
- Purple shadow wisps on the other half
- Swirling boundary where they meet
- Both colors glowing but not overpowering each other
- Serene, balanced appearance
- Feeling of DUALITY - two forces in harmony

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Twilight impact - orb bursts releasing both light and shadow energy

Design:
- Same palette: Golden-cream (#CCB8A0), white (#E5DCD0), soft purple (#806698), dark purple (#4D3355)
- Light burst: Warm white-gold (#F0E8D8)
- Shadow burst: Purple-black (#3D2645)
- Outline: Medium purple-gray (#553D5D)

Animation: Twilight orb explodes, releasing light and shadow in spiraling pattern
- Frame 1: Impact - orb cracks, both colors flashing simultaneously
- Frame 2: Light and shadow bursting outward in opposite spirals
- Frame 3: Maximum spread - golden rays and purple tendrils interweaving
- Frame 4: Both energies creating beautiful pattern, neither dominating
- Frame 5: Light fading upward, shadows fading downward
- Frame 6: Final sparkles of both colors dissipating together

Key visual concept: BALANCED EXPLOSION - equal light and shadow, beautiful duality

Effects:
- Golden rays expanding on one axis
- Purple shadow wisps on perpendicular axis
- Spiraling interweave pattern
- Both colors at equal intensity
- Peaceful yet powerful appearance
- Feeling of RELEASE - trapped duality finally free

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🕳️👁️ 26. ABYSS (Shadow + Void) - Abismo - SINGLE

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Abyss maw projectile - a tiny black hole mouth consuming everything

Design:
- Shape: Circular void mouth with jagged edges like teeth/maw opening
- Core: Absolute void black (#0D0310) - TRUE darkness at center
- Inner ring: Very dark purple (#1F1028) surrounding the void
- Outer maw: Dark purple teeth/edges (#38204D) reaching outward
- Consuming effect: Faint purple-red (#5D2D50) being pulled INTO the center
- Outline: Almost invisible dark (#100810), 1 pixel, broken/distorted

Animation: Void maw pulsing and consuming, edges writhing like a hungry mouth
- Frame 1: Maw slightly closed, void core small but intense
- Frame 2: Maw opening wider, void expanding, pulling effect visible
- Frame 3: Maximum opening - teeth-like edges spread wide, void hungriest
- Frame 4: Things being pulled in (particle streams toward center)
- Frame 5: Maw contracting, void core pulsing darker
- Frame 6: Return to smaller state, ready to consume again

Key concept: A MOUTH of the VOID - it doesn't just damage, it CONSUMES existence

Effects:
- Particle streams being pulled INTO center (reverse of normal effects!)
- Jagged maw edges writhing like teeth
- Absolute black void at core (darker than background)
- Distortion effect around edges
- Faint purple glow at the event horizon
- Feeling of HUNGER - this wants to DEVOUR

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Abyss impact - void maw opens fully and implodes, consuming the area

Design:
- Same palette: Absolute void (#0D0310), dark purple (#1F1028), maw edges (#38204D)
- Implosion effect: Everything being pulled to center
- Void flash: Inverse light - darkness pulsing outward then IN
- Final remnant: Tiny void scar (#150818)
- Outline: Almost invisible

Animation: Void maw fully opens then IMPLODES - not explosion, but IMPLOSION
- Frame 1: Impact - maw opens WIDE, void core exposed
- Frame 2: Everything rushing INWARD toward center (reverse explosion)
- Frame 3: Maximum consumption - all particles being devoured
- Frame 4: Void PULSING - single frame of total darkness spreading
- Frame 5: Implosion completing, void collapsing on itself
- Frame 6: Tiny void scar fading, reality reasserting itself

Key visual concept: IMPLOSION not explosion - everything gets PULLED IN and consumed

Effects:
- Particles rushing INWARD (opposite of normal impact!)
- Void pulse that briefly darkens the whole frame
- Reality distortion at edges
- Teeth-like maw edges collapsing inward
- Brief moment of absolute darkness
- Feeling of something being ERASED from existence

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🌸💨 27. POLLEN STORM (Nature + Wind) - Tormenta de Polen - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Pollen cloud projectile - swirling mass of golden pollen carried by wind

Design:
- Shape: Cloud-like mass with visible pollen particles swirling within
- Main cloud: Yellow-green (#B3D966) with soft edges
- Pollen particles: Golden yellow (#F2E066) dots scattered throughout
- Wind currents: Pale mint-green (#B3CCB3) swirl lines
- Core glow: Bright lime (#CCFF80) at center
- Outline: Olive green (#5A7340), soft/broken edges

Animation: Pollen cloud drifting with wind currents, particles swirling chaotically
- Frame 1: Cloud compact, pollen gathered, wind lines minimal
- Frame 2: Wind picking up, pollen starting to spread
- Frame 3: Maximum swirl - pollen particles spinning in vortex pattern
- Frame 4: Cloud expanding, pollen at widest distribution
- Frame 5: Wind shifting, pollen regathering
- Frame 6: Return to compact state, ready to loop

Key concept: A LIVING CLOUD of pollen - nature's seeds carried by playful wind

Effects:
- Golden pollen particles drifting in wind patterns
- Wind current lines showing air movement
- Soft, fluffy cloud edges
- Pollen density varying (thicker at center)
- Gentle, nature-magic appearance
- Feeling of ALLERGENS but magical - irritating and damaging

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Pollen Storm impact - cloud bursts into wind-scattered pollen explosion

Design:
- Same palette: Yellow-green (#B3D966), golden yellow (#F2E066), pale mint (#B3CCB3)
- Pollen burst: Bright golden (#FFEE88)
- Wind spirals: Cyan-white (#DDEEBB)
- Outline: Olive green (#5A7340)

Animation: Pollen cloud bursts, scattering seeds in all directions on wind currents
- Frame 1: Impact - cloud compresses then bursts
- Frame 2: Pollen explosion - particles flying outward on wind currents
- Frame 3: Maximum spread - pollen EVERYWHERE, wind spirals visible
- Frame 4: Pollen settling, wind currents carrying particles further
- Frame 5: Most pollen dispersed, lingering golden sparkles
- Frame 6: Final pollen drifting away, wind calming

Key visual concept: POLLEN EXPLOSION - sneeze-inducing cloud of nature particles

Effects:
- Hundreds of tiny pollen particles scattering
- Wind spiral patterns carrying pollen
- Golden shimmer in the air
- Soft, organic feel to explosion
- No hard impacts - everything floats and drifts
- Feeling of NATURE RELEASED - seeds spreading everywhere

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## 🏜️🌪️ 28. SANDSTORM (Wind + Earth) - Tormenta de Arena - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Sand vortex projectile - mini tornado of swirling desert sand

Design:
- Shape: Vertical cone/vortex shape with sand particles spiraling around
- Sand particles: Various tan/brown (#CCB380, #A68A60, #BFA870)
- Wind core: Pale yellow-brown (#E6D8BF) at center
- Dust cloud: Sandy beige (#D9C9A3) surrounding vortex
- Occasional rock bits: Darker brown (#806040) small chunks
- Outline: Brown (#73604A), broken/dusty edges

Animation: Sand vortex spinning rapidly with particles flying around chaotically
- Frame 1: Vortex tight, sand concentrated, minimal spread
- Frame 2: Spinning faster, sand particles spreading outward
- Frame 3: Maximum spin - sand flying in wide spiral pattern
- Frame 4: Vortex at peak intensity, rock bits visible
- Frame 5: Spin maintaining, some sand settling
- Frame 6: Return to tight formation, ready to loop

Key concept: A DESERT TORNADO - wind harnessing earth's sand into a weapon

Effects:
- Sand particles spiraling in vortex pattern
- Wind lines showing rotation
- Dust cloud at base
- Small rock chunks mixed in
- Dry, abrasive appearance
- Feeling of BLINDING STORM - sand getting everywhere

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Sandstorm impact - vortex explodes into blinding sand burst

Design:
- Same palette: Tan/brown (#CCB380, #A68A60), pale yellow (#E6D8BF), beige (#D9C9A3)
- Sand burst: Bright sandy yellow (#F2E6CC)
- Rock fragments: Dark brown (#806040)
- Outline: Brown (#73604A)

Animation: Sand vortex hits and explodes into massive sand cloud
- Frame 1: Impact - vortex compresses, sand concentrates
- Frame 2: Explosion outward - sand flying in all directions
- Frame 3: Maximum spread - entire frame filled with sand particles
- Frame 4: Sand cloud expanding, visibility-obscuring density
- Frame 5: Sand settling, particles drifting down
- Frame 6: Final sand particles falling, dust clearing

Key visual concept: SANDBLAST EXPLOSION - abrasive, blinding cloud of desert fury

Effects:
- Sand particles flying radially outward
- Dust cloud obscuring center
- Rock chunks tumbling
- Wind spiral remnants
- Dry, rough appearance
- Feeling of being HIT BY DESERT - gritty and blinding

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## ✨💨 29. PRISM WIND (Wind + Light) - Viento Prismático - MULTI

### Flight Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Prismatic wind gust projectile - light-refracting wind blade

Design:
- Shape: Curved crescent/blade of swirling wind with prismatic light within
- Wind body: Near-white with slight cyan tint (#D9F2F2)
- Prism colors: Rainbow hints - pale red (#FFDDDD), yellow (#FFFFDD), blue (#DDDDFF)
- Light sparkles: Pure white (#FFFFFF) stars scattered throughout
- Wind trails: Pale silver (#E6E6EE) flowing lines
- Outline: Light gray (#8899AA), subtle and flowing

Animation: Wind blade spinning with rainbow light refracting through it
- Frame 1: Blade compact, prism colors concentrated at center
- Frame 2: Spinning, light beginning to refract, colors spreading
- Frame 3: Rainbow effect visible - colors separating along blade
- Frame 4: Maximum refraction - full spectrum visible, sparkling
- Frame 5: Colors blending back together
- Frame 6: Return to concentrated state, ready to loop

Key concept: WIND that BENDS LIGHT - a blade of pure air refracting rainbow

Effects:
- Rainbow prismatic colors shifting along the blade
- Wind current lines flowing
- Light sparkle particles
- Ethereal, almost invisible appearance
- Beautiful, magical aesthetics
- Feeling of PURE BEAUTY - deadly but gorgeous

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

### Impact Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Prism Wind impact - wind blade shatters into rainbow light burst

Design:
- Same palette: Cyan-white (#D9F2F2), rainbow hints, pure white (#FFFFFF)
- Light burst: Bright white with color fringes
- Prism fragments: Tiny rainbow sparkles
- Wind spiral: Silver-white (#F0F0F8)
- Outline: Light gray (#8899AA)

Animation: Wind blade disperses into spectacular prismatic light show
- Frame 1: Impact - blade shatters, white flash
- Frame 2: Light refracting outward in multiple colors
- Frame 3: Maximum rainbow - colors separating in radial pattern
- Frame 4: Prismatic sparkles everywhere, wind spiraling
- Frame 5: Colors fading to white, sparkles diminishing
- Frame 6: Final white sparkles and wind wisps fading

Key visual concept: RAINBOW EXPLOSION - light shattering into its component colors

Effects:
- Rainbow light rays spreading outward
- Wind spiral carrying the colors
- Prismatic sparkle particles
- Brief flash of brilliant white at center
- Ethereal, magical fade-out
- Feeling of LIGHT RELEASED - wind freeing captured rainbows

Style: Cartoon, clean shapes, no anti-aliasing on edges.
```

---

## ⚡✨ 30. THUNDER SPEAR (Lightning + Light) - BEAM

### Active Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Divine golden lightning beam

Design:
- Beam body: Golden yellow (#FFD700)
- Core: White (#FFFFFF)
- Glow: Pale yellow (#FFFF99)
- Outline: Dark gold (#CC9900)

Animation: Powerful golden beam with spear tip
- Frames 1-6: Beam pulsing with golden lightning
- Holy sparkles flowing through
- Divine energy crackling

Effects:
- Golden lightning arcs
- Holy sparkle particles
- Power surge pulses
- Spear tip at end of beam
```

---

## 💎🔮 22. CRYSTAL GUARDIAN (Earth + Arcane) - ORBIT

> Fusión: earth_spike + arcane_orb
> Cristales mágicos orbitantes - tierra infundida con magia arcana

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Geometric magic crystal with glowing arcane core - defensive earth orbital

Design:
- Shape: Hexagonal/geometric crystal with faceted surfaces
- Crystal body: Amber/tan (#CC9966) with rocky texture
- Magic core: Purple arcane glow (#9966CC) visible inside
- Facet highlights: Light purple (#DDAAFF) on edges
- Earth particles: Brown (#886644) dust floating around
- Outline: Dark brown (#553311), 2 pixels, angular

Animation: Crystal ROTATING to show facets, arcane core PULSING
- Frames 1-8: Crystal rotates showing different faceted faces
- Internal purple glow PULSES like magical heartbeat
- Earth particles orbit around the crystal
- Facet highlights shimmer as they catch "light"

Frame-by-frame breakdown:
- Frame 1: Front facet visible, core dim
- Frame 2: Crystal rotating 45°, core brightening
- Frame 3: Side facet prominent, core bright
- Frame 4: Edge visible, core at maximum, flash on facets
- Frame 5: Opposite facet, core dimming
- Frame 6: Continuing rotation, earth particles visible
- Frame 7: Almost full rotation, core dim
- Frame 8: Nearly back to start, ready to loop

Key concept: EARTH MAGIC crystal - solid, protective, with arcane power inside

Effects:
- Sharp geometric facets with reflective highlights
- Purple arcane glow pulsing from within
- 2-3 small earth/dust particles orbiting
- Occasional arcane rune appearing near crystal
- Sturdy, defensive feel with magical mystery

Style: Cartoon/Funko Pop, clean shapes, angular edges for crystal facets.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_crystal_guardian.png (512x64)
```

---

## ❄️⚡ 23. FROZEN THUNDER (Ice + Lightning) - CHAIN

### Flight Animation (4 frames)
```
Create a pixel art horizontal sprite sheet of a FROZEN LIGHTNING BOLT projectile for a 2D game, in cute chibi/Funko Pop cartoon style. LAYOUT: 4 frames in a single horizontal strip, each frame in its own cell of approximately 150x100 pixels. Total image around 600x400 pixels. Transparent background. THE PROJECTILE: A jagged ice crystal bolt with an electric yellow core - frozen lightning that crackles with cold electricity. The bolt should look like crystallized lightning made of ice. COLOR PALETTE: - Core: Electric yellow glow (#FFFF66 / #FFFF99) - Primary: Cyan ice (#66FFFF / #99FFFF) - Secondary: White frost (#FFFFFF / #E6FFFF) - Accent: Yellow electric sparks through ice - Outline: Teal (#336666) ANIMATION SEQUENCE (4 frames): Frame 1: Ice bolt forming with yellow electric core flickering inside Frame 2: Frost intensifies, electric arcs visible through transparent ice Frame 3: Maximum intensity, bright yellow core pulsing through crystalline ice Frame 4: Energy crackle effect, ice particles and sparks, cycle back IMPORTANT DETAILS: - Orientation: Bolt pointing RIGHT (→) as if flying toward target - Transparent ice effect showing electric core inside - Mix of sharp ice crystals with lightning zigzag shape - Frost particles and electric sparks around the bolt - Cartoon-cute but cold and electric appearance - Each frame clearly separated in its own cell
```

### Impact Animation (4 frames)
```
Create a pixel art horizontal sprite sheet of a FROZEN LIGHTNING EXPLOSION IMPACT for a 2D game, in cute chibi/Funko Pop cartoon style. LAYOUT: 4 frames in a single horizontal strip, each frame in its own cell of approximately 150x100 pixels. Total image around 600x400 pixels. Transparent background. THE EFFECT: A burst of ice and electricity when hitting an enemy - cyan ice shards exploding outward with yellow electric arcs between them. COLOR PALETTE: - Core: Bright white-yellow flash (#FFFFFF / #FFFFCC) - Primary: Cyan ice (#66FFFF / #99FFFF) - Secondary: White frost (#FFFFFF / #E6FFFF) - Electric accents: Yellow sparks (#FFFF66) - Outline: Teal (#336666) ANIMATION SEQUENCE (4 frames): Frame 1: Initial flash - white-cyan burst center with ice beginning to shatter Frame 2: Expansion - ice shards shoot outward with electric arcs jumping between them Frame 3: Maximum spread - frozen explosion with ice crystals and electric discharge Frame 4: Dissipation - ice fades, last frost sparkles, lingering electric crackle IMPORTANT DETAILS: - Radial burst pattern (centered explosion expanding outward) - Ice crystal shards mixed with lightning sparks - Frost mist particles in cyan/white tones - Feeling of "frozen electricity" shattering - Cartoon-cute style with clear, readable shapes - Each frame clearly separated in its own cell
```

---

## 🔥⚡ 24. PLASMA (Fire + Lightning) - CHAIN

### Flight Animation (4 frames)
```
Create a pixel art horizontal sprite sheet of a PLASMA LIGHTNING BOLT projectile for a 2D game, in cute chibi/Funko Pop cartoon style. LAYOUT: 4 frames in a single horizontal strip, each frame in its own cell of approximately 150x100 pixels. Total image around 600x400 pixels. Transparent background. THE PROJECTILE: An electrified plasma bolt - a jagged lightning shape made of hot pink/magenta plasma energy. The bolt should look like superheated electrical fire with plasma particles. COLOR PALETTE: - Core: White-pink glow (#FFFFFF to #FFF2FF) - Primary: Hot pink/magenta (#FF66CC / #FFB3E6) - Secondary: Deep magenta (#E666B3) - Accent: Electric white-pink sparks - Outline: Dark magenta (#804066) ANIMATION SEQUENCE (4 frames): Frame 1: Plasma bolt forming with small energy particles gathering Frame 2: Bolt intensifies, plasma particles swirl around the zigzag shape Frame 3: Maximum intensity, bright core with plasma tendrils radiating Frame 4: Energy pulse effect, particles disperse slightly, cycle back IMPORTANT DETAILS: - Orientation: Bolt pointing RIGHT (→) as if flying toward target - Hot plasma energy with electric crackle effects - Mix of fire-like fluidity with lightning sharpness - Pink/magenta glowing particles around the bolt - Cartoon-cute but powerful appearance - Each frame clearly separated in its own cell
```

### Impact Animation (4 frames)
```
Create a pixel art horizontal sprite sheet of a PLASMA EXPLOSION IMPACT for a 2D game, in cute chibi/Funko Pop cartoon style. LAYOUT: 4 frames in a single horizontal strip, each frame in its own cell of approximately 150x100 pixels. Total image around 600x400 pixels. Transparent background. THE EFFECT: A burst of plasma energy when hitting an enemy - hot pink electric fire expanding outward with sparks and plasma particles. COLOR PALETTE: - Core: Bright white-pink flash (#FFFFFF / #FFF2FF) - Primary: Hot pink (#FF66CC / #FFB3E6) - Secondary: Pale pink (#FFE6F7) - Electric accents: White-magenta sparks - Outline: Dark magenta (#804066) ANIMATION SEQUENCE (4 frames): Frame 1: Initial flash - white-pink burst center with plasma beginning to expand Frame 2: Expansion - plasma tendrils shoot outward with electric arcs between them Frame 3: Maximum spread - plasma explosion with bright sparkling particles, electric discharge Frame 4: Dissipation - energy fades, last pink sparkles, lingering plasma mist IMPORTANT DETAILS: - Radial burst pattern (centered explosion expanding outward) - Plasma tendrils mixed with lightning sparks - Hot energy particles in pink/magenta tones - Feeling of "superheated electricity" - fire and lightning combined - Cartoon-cute style with clear, readable shapes - Each frame clearly separated in its own cell
```

---

## 🔥🔮 25. INFERNO ORB (Fire + Arcane) - ORBIT

> Fusión: fire_wand + arcane_orb
> Orbe de fuego infernal - llamas potenciadas con magia arcana

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Blazing fireball infused with purple arcane magic - offensive fire orbital

Design:
- Shape: Spherical flame orb with dancing fire tongues
- Fire body: Bright orange (#FF6600) with yellow highlights
- Arcane infusion: Purple (#9933FF) swirls weaving through flames
- Core: Bright yellow-white (#FFCC00) hot center
- Fire tips: Orange-red (#FF4400) flame edges
- Outline: Dark red-brown (#552200), 2 pixels

Animation: Fireball FLICKERING with arcane purple swirls rotating inside
- Frames 1-8: Fire tongues dance chaotically
- Purple arcane swirl rotates 360° through the flames
- Core brightness PULSES with heat intensity
- Occasional purple rune appears in the flames

Frame-by-frame breakdown:
- Frame 1: Flames at rest position, purple swirl at 0°
- Frame 2: Flames flare outward, swirl at 45°
- Frame 3: Maximum flame size, swirl at 90°, core bright
- Frame 4: Flames dancing, swirl at 135°, purple rune visible
- Frame 5: Flames contract slightly, swirl at 180°
- Frame 6: New flame pattern, swirl at 225°
- Frame 7: Flames shifting, swirl at 270°
- Frame 8: Returning to start shape, swirl at 315°

Key concept: MAGICAL FIRE - chaotic flames with controlled arcane power

Effects:
- Orange-yellow flames flickering chaotically
- Purple arcane energy swirling through the fire
- Ember particles flying off
- Occasional purple magical rune appearing
- Hot, aggressive, but magically controlled feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_inferno_orb.png (512x64)
```

---

## ❄️🔮 26. FROST ORB (Ice + Arcane) - ORBIT

> Fusión: ice_wand + arcane_orb
> Orbe de escarcha - hielo cristalino con magia arcana interior

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Frozen crystal sphere with purple arcane magic inside - icy orbital

Design:
- Shape: Perfect ice sphere with crystalline surface patterns
- Ice body: Light cyan-blue (#99CCFF) semi-translucent
- Arcane core: Light purple (#CC99FF) swirl visible inside
- Ice highlights: White (#FFFFFF) frost sparkles on surface
- Frost particles: Pale cyan (#CCFFFF) snowflake shapes
- Outline: Blue-gray (#334466), 2 pixels

Animation: Ice sphere ROTATING with internal purple magic swirling
- Frames 1-8: Surface frost patterns shift as sphere rotates
- Internal purple arcane swirl rotates visibly through translucent ice
- Ice highlights SHIMMER and move across surface
- Frost particles drift around the sphere

Frame-by-frame breakdown:
- Frame 1: Ice surface pattern A, purple swirl at 0°
- Frame 2: Surface pattern shifting, swirl at 45°, frost sparkle
- Frame 3: New ice pattern, swirl at 90°
- Frame 4: Purple core at maximum visibility, 135°
- Frame 5: Surface frost forming, swirl at 180°
- Frame 6: Ice pattern C, swirl at 225°
- Frame 7: Frost particles prominent, swirl at 270°
- Frame 8: Returning to pattern A, swirl at 315°

Key concept: FROZEN MAGIC - cold, crystalline beauty with arcane mystery within

Effects:
- Translucent ice effect (purple visible inside)
- Frost sparkles shimmering on surface
- 2-3 small snowflake particles floating around
- Purple arcane glow from within
- Cold, elegant, magically enhanced feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_frost_orb.png (512x64)
```

---

## ⚡🔮 27. ARCANE STORM (Lightning + Arcane) - ORBIT

> Fusión: lightning_wand + arcane_orb
> Tormenta arcana - electricidad canalizada por magia arcana

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Crackling electric orb with arcane purple energy - storm orbital

Design:
- Shape: Spherical energy orb with electric arcs jumping on surface
- Electric body: Bright yellow (#FFFF33) with white core
- Arcane infusion: Purple (#9933FF) energy weaving through electricity
- Lightning arcs: White-yellow (#FFFFCC) bolts jumping around
- Sparkles: Electric blue-white (#CCFFFF) sparks
- Outline: Purple-blue (#4422AA), 2 pixels

Animation: Electric orb CRACKLING with purple arcane energy swirling
- Frames 1-8: Lightning arcs jump to different positions each frame
- Purple arcane swirl rotates 360° inside the electric ball
- Core brightness FLASHES irregularly (electric feel)
- Electric sparks fly off in different directions each frame

Frame-by-frame breakdown:
- Frame 1: Arc at top, swirl at 0°, medium brightness
- Frame 2: Arc jumps to right, swirl at 45°, spark flies
- Frame 3: Arc at bottom-right, swirl at 90°, bright flash
- Frame 4: Multiple small arcs, swirl at 135°, maximum glow
- Frame 5: Arc at left, swirl at 180°, dimming
- Frame 6: Arc at top-left, swirl at 225°, spark flies
- Frame 7: Arc at bottom, swirl at 270°, medium
- Frame 8: Arc returning to top, swirl at 315°

Key concept: ELECTRIC MAGIC - chaotic lightning contained by arcane control

Effects:
- Lightning arcs jumping unpredictably on surface
- Purple magic swirl visible inside yellow-white electricity
- Electric sparks flying off
- Bright flashing core
- Dangerous, energetic, but magically controlled feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_arcane_storm.png (512x64)
```

---

## 🗡️🔮 28. SHADOW ORBS (Arcane + Shadow) - ORBIT

> Fusión: arcane_orb + shadow_dagger
> Orbes de sombra - magia arcana corrompida por oscuridad

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Dark ethereal orb with ghostly purple-black energy - shadow orbital

Design:
- Shape: Spherical orb with wispy shadow tendrils extending outward
- Shadow body: Dark purple-gray (#3D2850) semi-translucent
- Arcane core: Dim purple (#7744AA) glow visible inside
- Shadow wisps: Near-black (#1A1020) tendrils reaching outward
- Ghost highlights: Pale lavender (#CCBBDD) on edges
- Outline: Very dark purple (#1A0A20), 2 pixels

Animation: Shadow orb PULSING with dark tendrils writhing slowly
- Frames 1-8: Shadow tendrils reach outward then retract
- Internal purple core PULSES dimly
- Ghostly afterimage effect (translucent duplicates)
- Wisps move in organic, serpentine patterns

Frame-by-frame breakdown:
- Frame 1: Tendrils close, core dim
- Frame 2: Tendrils starting to extend, core brightening
- Frame 3: Tendrils reaching outward, ghostly trail
- Frame 4: Maximum extension, core at peak glow
- Frame 5: Tendrils at peak, starting to retract
- Frame 6: Tendrils pulling back, shadow mist
- Frame 7: Tendrils mostly retracted, core dimming
- Frame 8: Returning to compact form

Key concept: CORRUPTED MAGIC - dark, sinister, but beautiful in a ghostly way

Effects:
- Shadow tendrils moving organically like smoke
- Dim purple arcane glow from within
- Ghostly semi-transparent appearance
- Dark smoke particles drifting off
- Ethereal, haunting, dangerous feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_shadow_orbs.png (512x64)
```

---

## 🌿🔮 29. LIFE ORBS (Arcane + Nature) - ORBIT

> Fusión: arcane_orb + nature_staff
> Orbes de vida - magia arcana infundida con energía vital

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Living nature orb with green-purple magical energy - life orbital

Design:
- Shape: Spherical orb with small leaves/petals floating around it
- Nature body: Bright green (#66DD44) with life energy
- Arcane core: Purple (#9944CC) magic swirl inside
- Leaf accents: Light green (#99FF66) small leaves orbiting
- Life sparkles: Yellow-green (#CCFF66) healing particles
- Outline: Dark forest green (#224411), 2 pixels

Animation: Life orb BREATHING with leaves orbiting and life energy pulsing
- Frames 1-8: Size subtly "breathes" (grows and shrinks)
- 2-3 small leaves orbit around the orb
- Internal purple-green swirl rotates
- Life energy particles pulse outward

Frame-by-frame breakdown:
- Frame 1: Normal size, leaves at position A, swirl at 0°
- Frame 2: Slightly larger, leaves orbiting, swirl at 45°
- Frame 3: Maximum size (breathing in), life sparkle
- Frame 4: Still large, leaves moving, swirl at 135°
- Frame 5: Shrinking, swirl at 180°
- Frame 6: Smaller (breathing out), leaves continuing
- Frame 7: Minimum size, swirl at 270°
- Frame 8: Returning to normal, swirl at 315°

Key concept: LIVING MAGIC - alive, nurturing, full of growth energy

Effects:
- Subtle size pulsing like breathing
- Small leaf shapes orbiting the orb
- Green-yellow life energy sparkles
- Purple arcane core visible inside green
- Warm, healing, nurturing feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_life_orbs.png (512x64)
```

---

## 💨🔮 30. WIND ORBS (Arcane + Wind) - ORBIT

> Fusión: arcane_orb + wind_blade
> Orbes de viento - magia arcana potenciada por corrientes de aire

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Swirling wind orb with cyan-purple magical energy - wind orbital

Design:
- Shape: Spherical orb with visible wind currents swirling around it
- Wind body: Pale cyan (#CCFFEE) semi-translucent
- Arcane core: Light purple (#BB88DD) visible inside
- Wind lines: White (#FFFFFF) curved lines showing air flow
- Air particles: Pale green-cyan (#DDFFEE) wisps
- Outline: Teal (#446666), 2 pixels

Animation: Wind orb with AIR CURRENTS spiraling around it rapidly
- Frames 1-8: Wind lines spiral around the orb (fast rotation feel)
- Internal purple swirl rotates opposite direction
- Air wisps fly off in the wind's direction
- Slight "vibration" effect (position micro-shifts)

Frame-by-frame breakdown:
- Frame 1: Wind spiral at 0°, core at center
- Frame 2: Spiral at 45°, wisp flies off
- Frame 3: Spiral at 90°, core shifting slightly left
- Frame 4: Spiral at 135°, maximum wind effect
- Frame 5: Spiral at 180°, core shifting right
- Frame 6: Spiral at 225°, wisp flies off
- Frame 7: Spiral at 270°, core returning to center
- Frame 8: Spiral at 315°, ready to loop

Key concept: MAGICAL WIND - fast, light, always in motion

Effects:
- Visible wind current lines spiraling around
- Semi-translucent body (can see through slightly)
- Air wisp particles being blown off
- Purple arcane glow inside
- Light, airy, fast-moving feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_wind_orbs.png (512x64)
```

---

## 🌀🔮 31. COSMIC VOID (Arcane + Void) - ORBIT

> Fusión: arcane_orb + void_pulse
> Vacío cósmico - magia arcana fusionada con energía del vacío

### Orbit Animation (8 frames, LOOP)
```
Create a horizontal sprite strip of 8 frames (64x64 each = 512x64 total).
TOP-DOWN VIEW for 2D game. Black background (#000000).
Each frame CENTERED in its 64x64 cell. Content max 54x54px with 5px padding.

Subject: Void singularity orb with arcane purple energy at edges - void orbital

Design:
- Shape: Spherical void with dark center pulling inward
- Void center: Absolute black (#0A0510) - darker than background
- Arcane edge: Purple (#8833AA) energy ring around the void
- Event horizon: Dark purple-red (#4D1535) transition zone
- Distortion particles: Dark magenta (#331133) being pulled in
- Outline: Very dark purple (#200820), 2 pixels

Animation: Void orb PULLING particles inward with arcane edge pulsing
- Frames 1-8: Particles are drawn TOWARD the center (reverse of normal)
- Purple arcane ring rotates around the void
- Core darkness PULSES (seems to get darker/lighter)
- Distortion effect at edges

Frame-by-frame breakdown:
- Frame 1: Void at normal intensity, ring at 0°
- Frame 2: Particles being pulled in, ring at 45°
- Frame 3: Void darker, particles closer, ring at 90°
- Frame 4: Maximum void intensity, ring at 135°
- Frame 5: Void slightly lighter, ring at 180°
- Frame 6: New particles appearing at edges, ring at 225°
- Frame 7: Particles mid-pull, ring at 270°
- Frame 8: Returning to start, ring at 315°

Key concept: CONSUMING VOID - dark, ominous, pulls everything in

Effects:
- Particles moving INWARD (opposite of normal effects!)
- Purple arcane ring containing the void
- Central darkness that's darker than the background
- Distortion/warping effect at event horizon
- Ominous, powerful, dangerous feel

Style: Cartoon/Funko Pop, clean shapes, bold outlines.
This animation must loop SEAMLESSLY.

Output file: orbit_spritesheet_cosmic_void.png (512x64)
```

---

## ❄️✨ 32. AURORA (Ice + Light) - BEAM

### Active Animation (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).

Subject: Beautiful aurora borealis beam

Design:
- Main beam: Mint green (#66FFCC)
- Secondary: Pink (#FF99FF)
- Highlights: White (#FFFFFF)
- Outline: Soft teal (#336655)

Animation: Flowing aurora light beam
- Frames 1-6: Rainbow-like colors flowing through beam
- Northern lights shimmer effect
- Magical ice sparkles

Effects:
- Multiple soft colors flowing
- Aurora wave pattern
- Ice sparkle particles
- Dreamy, ethereal beauty
```

---

## 📋 Lista Completa de Fusiones Restantes

Las siguientes fusiones también necesitan sprites. Usa los colores base de los componentes combinados:

| ID | Nombre | Componentes | Tipo |
|---|---|---|---|
| flame_tornado | Tornado de Fuego | fire + wind | AOE |
| toxic_cloud | Nube Tóxica | nature + void | AOE |
| light_orb | Orbe de Luz | light + arcane | ORBIT |
| earth_wall | Muro de Tierra | earth + light | BEAM |
| frost_wind | Viento Helado | ice + wind | MULTI |
| flame_dagger | Daga de Fuego | fire + shadow | SINGLE |
| thunder_leaf | Hoja Trueno | lightning + nature | MULTI |

---

| void_orb | Orbe del Vacío | void + arcane | ORBIT |
| earth_wind | Tierra Ventosa | earth + wind | AOE |
| ice_spike | Espina de Hielo | ice + earth | AOE |
| solar_flare | Llamarada Solar | fire + light | BEAM |
| dark_storm | Tormenta Oscura | shadow + wind | MULTI |
| nature_light | Luz Natural | nature + light | BEAM |
| void_dagger | Daga del Vacío | void + shadow | SINGLE |
| rock_orb | Orbe de Roca | earth + arcane | ORBIT |
| frost_bolt | Rayo de Escarcha | ice + lightning | CHAIN |
| inferno_wind | Viento Infernal | fire + wind | AOE |
| shadow_leaf | Hoja Sombría | shadow + nature | MULTI |
| thunder_orb | Orbe Trueno | lightning + arcane | ORBIT |
| void_spike | Espina del Vacío | void + earth | AOE |
| ice_beam | Rayo de Hielo | ice + light | BEAM |
| flame_bolt | Rayo de Fuego | fire + lightning | CHAIN |
| shadow_orb | Orbe de Sombra | shadow + arcane | ORBIT |
| nature_spike | Espina Natural | nature + earth | AOE |
| light_wind | Viento de Luz | light + wind | MULTI |
| void_beam | Rayo del Vacío | void + light | BEAM |
| ice_dagger | Daga de Hielo | ice + shadow | SINGLE |
| flame_spike | Espina de Fuego | fire + earth | AOE |
| thunder_wind | Viento Trueno | lightning + wind | MULTI |

Para cada una, combina las paletas de colores de los dos elementos base y adapta los efectos al tipo de proyectil.

---

## 🔧 Post-Procesamiento

Después de generar los sprites:

1. **Redimensionar si es necesario**: A 64x64 exactos por frame
2. **Verificar transparencia**: Fondo completamente transparente
3. **Guardar como PNG**: En carpetas correspondientes
4. **Nomenclatura de archivos**: 
   - Proyectiles normales:
     - `flight_spritesheet_[weapon_id].png` - animación de vuelo
     - `impact_spritesheet_[weapon_id].png` - animación de impacto
   - **Proyectiles orbitales** (arcane_orb y fusiones):
     - `orbit_spritesheet_[weapon_id].png` - animación de órbita (8 frames, 512x64)

### Estructura de carpetas:
```
assets/sprites/projectiles/
├── weapons/
│   ├── ice_wand/
│   │   ├── flight_spritesheet_ice_wand.png
│   │   └── impact_spritesheet_ice_wand.png
│   ├── fire_wand/
│   │   ├── flight_spritesheet_fire_wand.png
│   │   └── impact_spritesheet_fire_wand.png
│   ├── arcane_orb/                              # ← ORBITAL
│   │   └── orbit_spritesheet_arcane_orb.png     # Solo necesita orbit!
│   └── ... (cada arma base)
├── fusion/
│   ├── frostvine/
│   │   ├── flight_spritesheet_frostvine.png
│   │   └── impact_spritesheet_frostvine.png
│   ├── cosmic_barrier/                          # ← ORBITAL
│   │   └── orbit_spritesheet_cosmic_barrier.png
│   ├── frost_orb/                               # ← ORBITAL
│   │   └── orbit_spritesheet_frost_orb.png
│   ├── inferno_orb/                             # ← ORBITAL
│   │   └── orbit_spritesheet_inferno_orb.png
│   ├── crystal_guardian/                        # ← ORBITAL
│   │   └── orbit_spritesheet_crystal_guardian.png
│   ├── arcane_storm/                            # ← ORBITAL
│   │   └── orbit_spritesheet_arcane_storm.png
│   ├── shadow_orbs/                             # ← ORBITAL
│   │   └── orbit_spritesheet_shadow_orbs.png
│   ├── life_orbs/                               # ← ORBITAL
│   │   └── orbit_spritesheet_life_orbs.png
│   ├── wind_orbs/                               # ← ORBITAL
│   │   └── orbit_spritesheet_wind_orbs.png
│   ├── cosmic_void/                             # ← ORBITAL
│   │   └── orbit_spritesheet_cosmic_void.png
│   └── ... (cada fusión)
```

### Resumen de tipos de sprites por tipo de proyectil:

| Tipo | Archivos necesarios | Frames | Tamaño total |
|------|---------------------|--------|--------------|
| SINGLE/MULTI/HOMING | flight + impact | 6 cada uno | 384x64 + 384x64 |
| CHAIN | flight + impact | 4 cada uno | 256x64 + 256x64 |
| AOE | appear + active + fade | 4/6/4 | varía |
| BEAM | start + active + end | 4/6/4 | varía |
| **ORBIT** | **orbit** | **8 frames** | **512x64** |

