# 🎨 PLAN DE SPRITES DE PROYECTILES - SPELLLOOP

## 📋 Resumen del Proyecto

**Estilo Visual**: Cartoon/Funko Pop, 2D top-down
**Resolución**: 64x64 píxeles por frame
**Formato**: PNG con transparencia (fondo alpha)
**Animaciones por proyectil**:
- **Launch** (4-6 frames): Aparición/disparo inicial
- **InFlight** (6-8 frames, loop): Mientras viaja
- **Impact** (6-8 frames): Explosión/impacto

**Tipos de proyectiles**:
- **SINGLE/MULTI**: Proyectiles que viajan (orbes, bolas, dagas)
- **CHAIN**: Rayos eléctricos entre enemigos
- **BEAM**: Rayos láser continuos
- **AOE**: Efectos de área en el suelo
- **ORBIT**: Orbes que giran alrededor del jugador

---

## 🎯 Prompt Base (usar como prefijo para TODOS)

```
Create a 64x64 pixel sprite sheet for a 2D top-down game projectile.
Style: Cartoon/Funko Pop, bold black outlines (2-3px), vibrant colors, 
exaggerated highlights, soft shadows. NO realistic style.
Background: Transparent (checkerboard pattern shown).
Format: Horizontal strip of frames, each frame 64x64px.
The projectile should look "cute but deadly" - round shapes, 
expressive glow effects, thick outlines like a sticker.
```

---

## 🧊 ARMAS BASE (10)

### 1. ICE_WAND - Fragmento de Hielo
**Tipo**: SINGLE | **Color**: Cian #66CCFF | **Efecto**: Slow

```
[BASE PROMPT]
Projectile: Ice shard / frozen crystal
Colors: Cyan (#66CCFF) primary, white highlights, dark blue (#1A3A5C) outline
Shape: Pointed crystal shard, angular but cute
Effects: Sparkle particles, frost trail, icy glow

LAUNCH (4 frames): Crystal forms from snowflake, grows and sharpens
INFLIGHT (6 frames, loop): Crystal rotates slightly, sparkles shimmer, frost particles trail behind
IMPACT (6 frames): Crystal shatters into snowflakes, ice explosion, frost ring expands
```

---

### 2. FIRE_WAND - Bola de Fuego
**Tipo**: SINGLE | **Color**: Naranja #FF6611 | **Efecto**: Burn DoT

```
[BASE PROMPT]
Projectile: Fireball / flame orb
Colors: Orange (#FF6611) core, yellow (#FFCC00) highlights, dark red (#661100) outline
Shape: Round bouncy fireball with flame wisps
Effects: Ember particles, heat shimmer, warm glow

LAUNCH (4 frames): Flame sparks together, forms ball with "poof" effect
INFLIGHT (6 frames, loop): Fireball wobbles, flames flicker, embers trail
IMPACT (6 frames): Fireball explodes in flame burst, smoke puff, ember scatter
```

---

### 3. LIGHTNING_WAND - Rayo Eléctrico
**Tipo**: CHAIN | **Color**: Amarillo #FFFF4D | **Efecto**: Chain 2 enemies

```
[BASE PROMPT]
Projectile: Lightning bolt / electric spark
Colors: Yellow (#FFFF4D) core, white center, purple (#6633CC) outline
Shape: Zigzag bolt with rounded joints, orb at tip
Effects: Electric sparks, static crackle, bright flash

LAUNCH (4 frames): Spark forms, electricity crackles outward
INFLIGHT (6 frames, loop): Bolt jitters/shakes, sparks fly off randomly, bright pulse
IMPACT (6 frames): Electric burst, sparks scatter in circle, bright flash fade
```

---

### 4. ARCANE_ORB - Orbe Arcano
**Tipo**: ORBIT | **Color**: Púrpura #B34DFF | **Efecto**: Orbita al jugador

```
[BASE PROMPT]
Projectile: Magic orb / arcane sphere
Colors: Purple (#B34DFF) main, pink (#FF66CC) highlights, dark violet (#330066) outline
Shape: Perfect glowing orb with inner swirl pattern
Effects: Magic runes floating around, mystical trail, soft pulsing glow

LAUNCH (5 frames): Orb materializes from magic circle, "pop" into existence
INFLIGHT (8 frames, loop): Orb pulses gently, inner pattern rotates, runes orbit around it
IMPACT (6 frames): Orb disperses into magic particles, runes scatter, purple mist
```

---

### 5. SHADOW_DAGGER - Daga Sombría
**Tipo**: SINGLE (pierce) | **Color**: Púrpura oscuro #4D1A66 | **Efecto**: Pierce 3

```
[BASE PROMPT]
Projectile: Shadow dagger / dark blade
Colors: Dark purple (#4D1A66) body, black (#1A0A26) outline, ghostly white edge
Shape: Sleek curved dagger, slightly ethereal/translucent
Effects: Shadow wisps, dark smoke trail, ghostly afterimage

LAUNCH (4 frames): Dagger forms from shadows coalescing
INFLIGHT (6 frames, loop): Dagger spins slowly, shadow wisps trail, ghostly flicker
IMPACT (6 frames): Dagger dissolves into shadow burst, dark particles scatter
```

---

### 6. NATURE_STAFF - Hoja Mágica
**Tipo**: MULTI (homing) | **Color**: Verde #4DCC33 | **Efecto**: Lifesteal

```
[BASE PROMPT]
Projectile: Magic leaf / nature sprite
Colors: Green (#4DCC33) main, yellow-green (#99FF66) highlights, dark green (#1A4D13) outline
Shape: Glowing leaf with cute face/eyes (optional), round and friendly
Effects: Petal particles, nature sparkles, green glow trail

LAUNCH (4 frames): Leaf sprouts from tiny seed, unfurls with sparkle
INFLIGHT (6 frames, loop): Leaf floats and tumbles gently, petals trail behind
IMPACT (6 frames): Leaf bursts into flower petals, nature sparkle explosion, healing shimmer
```

---

### 7. WIND_BLADE - Cuchilla de Viento
**Tipo**: MULTI (fan) | **Color**: Blanco/Cyan #E6FFFF | **Efecto**: High knockback

```
[BASE PROMPT]
Projectile: Wind blade / air slash
Colors: Light cyan (#E6FFFF) main, white highlights, light gray (#99CCCC) outline
Shape: Curved crescent blade, wispy edges, almost transparent
Effects: Air current lines, small cloud puffs, motion blur

LAUNCH (4 frames): Wind spirals into blade shape with whoosh effect
INFLIGHT (6 frames, loop): Blade spins rapidly, wind trails, subtle shimmer
IMPACT (6 frames): Blade disperses into wind burst, small tornado effect, air scatter
```

---

### 8. EARTH_SPIKE - Pico de Tierra
**Tipo**: AOE | **Color**: Marrón #996633 | **Efecto**: Stun

```
[BASE PROMPT]
Projectile: Earth spike / rock eruption (TOP-DOWN AOE VIEW)
Colors: Brown (#996633) main, tan (#CC9966) highlights, dark brown (#4D3319) outline
Shape: Circular area effect, spikes emerge from center
Effects: Dirt particles, rock debris, ground crack pattern

APPEAR (4 frames): Ground cracks appear, earth rumbles
ACTIVE (6 frames, loop): Multiple spikes emerge from ground, dust clouds, debris falls
FADE (4 frames): Spikes retract into ground, cracks close, dust settles
```

---

### 9. LIGHT_BEAM - Rayo de Luz
**Tipo**: BEAM | **Color**: Dorado #FFFFCC | **Efecto**: Crit chance

```
[BASE PROMPT]
Projectile: Light beam / holy ray (HORIZONTAL BEAM)
Colors: Golden white (#FFFFCC) core, pure white highlights, soft gold (#CCAA66) edge
Shape: Straight beam with rounded ends, star particles along length
Effects: Light particles, lens flare, divine sparkles

START (4 frames): Light gathers at origin point, brightens
ACTIVE (6 frames, loop): Beam pulses with energy, star particles travel along it
END (4 frames): Beam fades from edges to center, sparkles dissipate
```

---

### 10. VOID_PULSE - Pulso del Vacío
**Tipo**: AOE (pull) | **Color**: Negro/Púrpura #330033 | **Efecto**: Pull enemies

```
[BASE PROMPT]
Projectile: Void pulse / dark singularity (TOP-DOWN AOE VIEW)
Colors: Deep purple-black (#330033) core, dark magenta (#660066) mid, black outline
Shape: Circular void/black hole effect, things being pulled inward
Effects: Distortion waves, particles being sucked in, dark energy crackle

APPEAR (4 frames): Dark point appears, expands with distortion
ACTIVE (6 frames, loop): Void pulses, particles spiral inward, distortion waves
FADE (4 frames): Void collapses inward, final flash, reality "snaps" back
```

---

## ⚡ FUSIONES PRINCIPALES (45 total - Mostrando las más importantes)

### STEAM_CANNON (Ice + Fire)
**Tipo**: AOE | **Colores**: Gris/Blanco con tonos naranjas y azules

```
[BASE PROMPT]
Projectile: Steam explosion / vapor burst
Colors: White-gray (#E6E6E6) steam, hints of blue (#99CCFF) and orange (#FFAA66)
Shape: Puffy cloud explosion, round steam puffs
Effects: Steam wisps, water droplets, heat shimmer

LAUNCH (4 frames): Ice and fire collide, steam erupts
INFLIGHT (6 frames): Steam cloud billows, wobbles as it travels
IMPACT (6 frames): Massive steam explosion, cloud expands, droplets scatter
```

---

### STORM_CALLER (Lightning + Wind)
**Tipo**: CHAIN (multiple) | **Colores**: Amarillo con cyan

```
[BASE PROMPT]
Projectile: Storm bolt / thunder wind
Colors: Yellow (#FFFF33) lightning, cyan (#66FFFF) wind, dark blue outline
Shape: Bolt surrounded by wind spiral
Effects: Lightning crackle, wind current, storm particles

LAUNCH (4 frames): Wind spiral forms, lightning charges within
INFLIGHT (6 frames, loop): Bolt spins in wind vortex, sparks and wind trails
IMPACT (6 frames): Lightning + wind burst, electric tornado effect
```

---

### SOUL_REAPER (Shadow + Nature)
**Tipo**: MULTI (homing) | **Colores**: Púrpura oscuro con verde

```
[BASE PROMPT]
Projectile: Spectral scythe / soul blade
Colors: Dark purple (#4D1A4D) shadow, sickly green (#66CC33) life energy
Shape: Small curved scythe blade with ghostly trail
Effects: Soul wisps (green), shadow smoke, ethereal glow

LAUNCH (4 frames): Shadow forms blade, green energy infuses it
INFLIGHT (6 frames, loop): Blade spins, souls trail behind, ghostly afterimage
IMPACT (6 frames): Blade releases captured souls, green burst, shadow disperses
```

---

### COSMIC_BARRIER (Arcane + Light)
**Tipo**: ORBIT | **Colores**: Blanco/dorado con púrpura

```
[BASE PROMPT]
Projectile: Cosmic orb / star sphere
Colors: White-gold (#FFFFCC) light, purple (#CC99FF) arcane shimmer
Shape: Glowing star/orb hybrid, pointed rays
Effects: Starlight particles, cosmic dust, divine glow

LAUNCH (5 frames): Star materializes from cosmic dust
INFLIGHT (8 frames, loop): Star pulses, rays rotate, cosmic trail
IMPACT (6 frames): Star explodes into constellation pattern, light scatter
```

---

### RIFT QUAKE (Earth + Void)
**Tipo**: AOE (huge) | **Colores**: Marrón oscuro con púrpura

```
[BASE PROMPT]
Projectile: Rift quake / seismic void (TOP-DOWN AOE)
Colors: Dark brown (#4D3319) earth, purple-black (#330033) void energy
Shape: Large circular area, cracks and void rifts
Effects: Ground shatter, void tendrils opening, dimensional cracks

APPEAR (4 frames): Ground cracks with void energy seeping through
ACTIVE (6 frames, loop): Earth rises and falls, void pulses, massive destruction
FADE (4 frames): Ground settles, void closes, dust cloud
```

---

### FROZEN_THUNDER (Ice + Lightning)
**Tipo**: CHAIN | **Colores**: Cyan con amarillo

```
[BASE PROMPT]
Projectile: Frozen lightning / ice bolt
Colors: Cyan (#66FFFF) ice, yellow (#FFFF66) lightning core
Shape: Jagged ice crystal with electric core
Effects: Ice shards, electric sparks, frost lightning

LAUNCH (4 frames): Ice forms around lightning spark
INFLIGHT (6 frames, loop): Crystal bolt crackles, ice particles, electric trail
IMPACT (6 frames): Shatters into ice + lightning burst, frost shock wave
```

---

### HELLFIRE (Fire + Shadow)
**Tipo**: MULTI (pierce) | **Colores**: Rojo oscuro con negro

```
[BASE PROMPT]
Projectile: Dark flame / hellfire bolt
Colors: Dark red (#990000) fire, black (#1A0A0A) shadow, orange (#FF6600) highlights
Shape: Flame with demonic face/shape, aggressive look
Effects: Black smoke, red embers, evil glow

LAUNCH (4 frames): Dark flames erupt from shadow
INFLIGHT (6 frames, loop): Hellfire flickers menacingly, shadow trails
IMPACT (6 frames): Demonic explosion, dark fire scatter, smoke burst
```

---

### THUNDER_SPEAR (Lightning + Light)
**Tipo**: BEAM | **Colores**: Dorado brillante con blanco

```
[BASE PROMPT]
Projectile: Divine thunder / golden spear beam
Colors: Bright gold (#FFD700) main, white core, orange (#FF9900) edges
Shape: Powerful beam with spear tip, divine patterns
Effects: Golden lightning, holy sparkles, power surge

START (4 frames): Light gathers, forms spear shape
ACTIVE (6 frames, loop): Beam blazes with golden lightning, divine power pulses
END (4 frames): Spear disperses into golden particles
```

---

### VOID_STORM (Void + Wind)
**Tipo**: AOE (pull) | **Colores**: Negro con cyan

```
[BASE PROMPT]
Projectile: Void tornado / dark vortex (TOP-DOWN AOE)
Colors: Black-purple (#1A001A) void, cyan (#66FFFF) wind edges
Shape: Swirling vortex, things pulled to center
Effects: Wind spiral, void distortion, debris caught in spin

APPEAR (4 frames): Wind forms, void appears in center
ACTIVE (6 frames, loop): Tornado spins, void pulses, maximum suction
FADE (4 frames): Wind disperses, void collapses
```

---

### CRYSTAL_GUARDIAN (Earth + Arcane)
**Tipo**: ORBIT | **Colores**: Marrón cristalino con púrpura

```
[BASE PROMPT]
Projectile: Magic crystal / arcane gemstone
Colors: Amber-brown (#CC9966) crystal, purple (#9966CC) magic glow
Shape: Geometric crystal with inner glow
Effects: Crystal sparkle, magic runes, earth particles

LAUNCH (5 frames): Crystal grows from earth with magic infusion
INFLIGHT (8 frames, loop): Crystal rotates, magic pulses within, rune particles
IMPACT (6 frames): Crystal shatters into gem fragments, magic burst
```

---

## 📝 LISTA COMPLETA DE PROYECTILES (55 total)

### Armas Base (10):
1. ice_wand - Ice Shard
2. fire_wand - Fireball
3. lightning_wand - Lightning Bolt
4. arcane_orb - Arcane Orb
5. shadow_dagger - Shadow Dagger
6. nature_staff - Nature Leaf
7. wind_blade - Wind Blade
8. earth_spike - Earth Spike (AOE)
9. light_beam - Light Beam
10. void_pulse - Void Pulse (AOE)

### Fusiones (45):
11. steam_cannon (Ice+Fire)
12. storm_caller (Lightning+Wind)
13. soul_reaper (Shadow+Nature)
14. cosmic_barrier (Arcane+Light)
15. rift_quake (Earth+Void)
16. frostvine (Ice+Nature)
17. hellfire (Fire+Shadow)
18. thunder_spear (Lightning+Light)
19. void_storm (Void+Wind)
20. crystal_guardian (Earth+Arcane)
21. frozen_thunder (Ice+Lightning)
22. frost_orb (Ice+Arcane)
23. frostbite (Ice+Shadow)
24. blizzard (Ice+Wind)
25. glacier (Ice+Earth)
26. aurora (Ice+Light)
27. absolute_zero (Ice+Void)
28. plasma (Fire+Lightning)
29. inferno_orb (Fire+Arcane)
30. wildfire (Fire+Nature)
31. firestorm (Fire+Wind)
32. volcano (Fire+Earth)
33. solar_flare (Fire+Light)
34. dark_flame (Fire+Void)
35. arcane_storm (Lightning+Arcane)
36. dark_lightning (Lightning+Shadow)
37. thunder_bloom (Lightning+Nature)
38. seismic_bolt (Lightning+Earth)
39. void_bolt (Lightning+Void)
40. shadow_orbs (Arcane+Shadow)
41. life_orbs (Arcane+Nature)
42. wind_orbs (Arcane+Wind)
43. cosmic_void (Arcane+Void) - duplicate?
44. phantom_blade (Shadow+Wind)
45. stone_fang (Shadow+Earth)
46. twilight (Shadow+Light)
47. abyss (Shadow+Void)
48. pollen_storm (Nature+Wind)
49. gaia (Nature+Earth)
50. solar_bloom (Nature+Light)
51. decay (Nature+Void)
52. sandstorm (Wind+Earth)
53. prism_wind (Wind+Light)
54. radiant_stone (Earth+Light)
55. eclipse (Light+Void)

---

## 🔧 NOTAS TÉCNICAS

### Estructura de archivos esperada:
```
assets/sprites/projectiles/
├── ice_wand/
│   ├── launch.png (strip 4 frames)
│   ├── flight.png (strip 6 frames)
│   └── impact.png (strip 6 frames)
├── fire_wand/
│   └── ...
└── [weapon_id]/
    └── ...
```

### Configuración de importación (Godot):
- Filter: Nearest (pixel art)
- Repeat: Disabled
- Compress: Lossless

### Consideraciones para mejoras futuras:
- Los sprites deben verse bien al 100%, 150% y 200% de escala
- Los colores deben ser distinguibles para diferentes niveles de arma
- Dejar espacio para "variantes" (ej: nivel 8 = versión más brillante)

---

## 🎮 ORDEN DE PRIORIDAD SUGERIDO

**Fase 1 - Armas Base (CRÍTICO)**:
1. ice_wand, fire_wand, lightning_wand (las más comunes)
2. arcane_orb, shadow_dagger (siguiente tier)
3. nature_staff, wind_blade, earth_spike
4. light_beam, void_pulse

**Fase 2 - Fusiones Principales**:
5. steam_cannon, storm_caller, hellfire
6. cosmic_barrier, rift_quake, thunder_spear
7. frozen_thunder, void_storm, soul_reaper
8. crystal_guardian, frostvine

**Fase 3 - Fusiones Restantes**:
9-55. El resto de fusiones en orden de uso probable

---

## 💡 TIPS PARA GENERAR CON IA

1. **Generar como sprite strip horizontal**
2. **Pedir "pixel art style" o "low resolution crisp edges"**
3. **Especificar "black outline, cartoon style, no antialiasing"**
4. **Si sale muy detallado, pedir "simplified, bold shapes"**
5. **Para AOE top-down, especificar "viewed from directly above"**
6. **Para beams, especificar "horizontal beam, source on left"**
