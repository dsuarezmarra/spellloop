# VFX Generation Prompts - Loopialike

Este documento contiene prompts específicos para generar los VFX faltantes del juego usando herramientas de generación de sprites (como AI image generators o herramientas de pixel art).

## 📋 Especificaciones Técnicas Globales

Todos los spritesheets deben seguir estas especificaciones:

- **Formato**: PNG con transparencia (RGBA)
- **Resolución base para AOE**: 128x128 o 256x256 píxeles por frame
- **Resolución base para Projectiles**: 64x64 píxeles por frame
- **Resolución base para Auras**: 128x128 píxeles por frame
- **Layout de spritesheet**: Horizontal (4-8 frames en fila) o Grid (4x2 = 8 frames)
- **Estilo visual**: Cartoon/Funko Pop, colores vibrantes, bordes definidos
- **Duración típica**: 0.4-0.8 segundos por animación completa

---

## 🎯 CATEGORÍA 1: VFX DE PLAYER (Prioridad Alta)

### 1.1 Thorns - Daño de Espinas Reflejado
**Carpeta destino**: `assets/vfx/abilities/player/thorns/`

```
PROMPT:
Create a cartoon-style spritesheet for a "thorns damage reflection" visual effect.
The effect should show green/nature spikes emanating outward from a central point when damage is reflected.

Specifications:
- 8 frames horizontal layout (1024x128 total, 128x128 per frame)
- Color palette: Forest green (#4A7C23), lime (#8BC34A), brown thorns (#5D4E37)
- Animation: Frame 1-3: spikes emerge from center, Frame 4-5: spikes at full extension with glow pulse, Frame 6-8: spikes retract and fade
- Style: Cartoony, cel-shaded with dark outlines
- Elements: 4-6 organic thorny spikes radiating outward, subtle leaf/vine details
- Background: Transparent (PNG)

Name file: player_thorns_spritesheet.png
```

### 1.2 Healing/Curación 
**Carpeta destino**: `assets/vfx/abilities/player/heal/`

```
PROMPT:
Create a cartoon-style spritesheet for a "healing" visual effect for a top-down survivor game.
The effect should show a soft green/golden glow with floating symbols rising upward.

Specifications:
- 8 frames horizontal layout (1024x128 total, 128x128 per frame)
- Color palette: Soft green (#7FFF7F), gold (#FFD700), white highlights
- Animation: Frame 1-2: soft glow appears at base, Frame 3-5: plus signs/hearts float upward, Frame 6-8: particles dissipate with sparkles
- Style: Soft cartoon, gentle glow, friendly appearance
- Elements: 3-4 floating health symbols (+), subtle sparkle particles, radial glow at center
- Background: Transparent (PNG)

Name file: player_heal_spritesheet.png
```

### 1.3 Shield/Barrier (Escudo de Absorción)
**Carpeta destino**: `assets/vfx/abilities/player/shield/`

```
PROMPT:
Create a cartoon-style spritesheet for a "magical shield barrier" visual effect.
The effect should show a protective bubble/hexagonal shield around a character.

Specifications:
- 12 frames horizontal layout (1536x128 total, 128x128 per frame)
- Color palette: Cyan (#00FFFF), blue (#4169E1), white highlights, subtle gold runes
- Animation phases:
  - APPEAR (frames 1-4): Shield materializes with hexagonal segments forming
  - LOOP (frames 5-8): Shield pulses gently, runes glow rhythmically
  - BREAK (frames 9-12): Shield shatters into fragments that dissolve
- Style: Fantasy cartoon, translucent bubble with visible hex grid pattern
- Elements: Hexagonal honeycomb pattern, floating arcane runes, energy ripples
- Background: Transparent (PNG)

Name files:
- shield_appear_spritesheet.png (4 frames)
- shield_loop_spritesheet.png (4 frames)
- shield_break_spritesheet.png (4 frames)
```

### 1.4 Revive/Phoenix (Resurrección)
**Carpeta destino**: `assets/vfx/abilities/player/revive/`

```
PROMPT:
Create a cartoon-style spritesheet for a "phoenix resurrection" visual effect.
The effect should show a dramatic golden/fiery rebirth animation.

Specifications:
- 8 frames horizontal layout (1024x128 total, 128x128 per frame)
- Color palette: Gold (#FFD700), orange (#FF8C00), white core, subtle red accents
- Animation: Frame 1-2: dark/collapsed state with single ember, Frame 3-4: golden light burst from center, Frame 5-6: phoenix wings made of fire spread outward, Frame 7-8: energy solidifies and fades leaving golden sparkles
- Style: Dramatic cartoon, epic feel with warm colors
- Elements: Central burst, wing-like flame shapes, rising embers, golden particles
- Background: Transparent (PNG)

Name file: player_revive_spritesheet.png
```

### 1.5 Soul Link (Conexión de Almas)
**Carpeta destino**: `assets/vfx/abilities/player/soul_link/`

```
PROMPT:
Create a cartoon-style spritesheet for a "soul link tether" visual effect.
The effect should show a magical connection beam between two points that transfers damage.

Specifications:
- 8 frames horizontal layout (1024x128 total, 128x128 per frame)
- Color palette: Purple (#9932CC), magenta (#FF00FF), white pulses, dark purple (#4B0082)
- Animation: Looping animation showing energy pulsing along a chain-like tether
- Frame 1-2: Base tether with subtle glow
- Frame 3-4: Energy pulse traveling along tether (left to right)
- Frame 5-6: Pulse reaches end, flash
- Frame 7-8: Return to base state
- Style: Mystical cartoon, ethereal chains or spirit threads
- Elements: Chain links made of light, flowing particles along path, glowing orbs at endpoints
- Background: Transparent (PNG)

Note: This is designed as a tileable beam segment to be stretched between player and linked enemy.

Name file: soul_link_beam_spritesheet.png
```

### 1.6 Buff Aura (Aura de Mejoras)
**Carpeta destino**: `assets/vfx/abilities/player/buffs/`

```
PROMPT:
Create a cartoon-style spritesheet for a "buff aura" visual effect that glows beneath/around a character.
The effect should be subtle but visible, indicating the player has active buffs.

Specifications:
- 6 frames horizontal layout (768x128 total, 128x128 per frame)
- Color palette: Gold (#FFD700), white (#FFFFFF), soft yellow (#FFFACD)
- Animation: Gentle looping glow that pulses every ~0.8 seconds
- Style: Subtle cartoon, placed beneath character (z-index -1)
- Elements: Soft circular glow, tiny floating particles rising, gentle sparkles
- Opacity: Semi-transparent (alpha ~0.4-0.6)
- Background: Transparent (PNG)

Name file: buff_aura_spritesheet.png
```

### 1.7 Debuff Aura (Aura de Debuffs)
**Carpeta destino**: `assets/vfx/abilities/player/debuffs/`

```
PROMPT:
Create a cartoon-style spritesheet for a "debuff/curse aura" visual effect.
The effect should show a negative aura indicating the player is weakened or cursed.

Specifications:
- 6 frames horizontal layout (768x128 total, 128x128 per frame)
- Color palette: Dark purple (#4B0082), sickly green (#9ACD32), black smoke
- Animation: Slow looping drip/decay effect
- Style: Ominous cartoon, creeping darkness
- Elements: Dripping dark energy, skull wisps, floating debuff symbols (skull, broken shield)
- Opacity: Semi-transparent
- Background: Transparent (PNG)

Name file: debuff_aura_spritesheet.png
```

---

## 🎯 CATEGORÍA 2: VFX DE ENEMIGOS (Prioridad Media)

### 2.1 Lightning Projectile
**Carpeta destino**: `assets/vfx/abilities/projectiles/lightning/`

```
PROMPT:
Create a cartoon-style spritesheet for a "lightning ball" projectile for a top-down game.
The projectile should look like crackling electrical energy.

Specifications:
- 8 frames horizontal layout (512x64 total, 64x64 per frame)
- Color palette: Electric yellow (#FFFF00), white core (#FFFFFF), blue electricity (#00BFFF)
- Animation: Crackling ball of lightning with arcs jumping around it
- Style: Cartoony, high energy, zippy
- Elements: Central bright orb, 4-6 small lightning bolts arcing around it, sparkle particles
- Background: Transparent (PNG)

Name file: projectile_lightning_spritesheet.png
```

### 2.2 Lightning AOE Impact
**Carpeta destino**: `assets/vfx/abilities/aoe/lightning/` (crear carpeta)

```
PROMPT:
Create a cartoon-style spritesheet for a "lightning strike AOE" impact effect.
The effect should show a powerful electrical discharge hitting the ground.

Specifications:
- 8 frames horizontal layout (1024x128 total, 128x128 per frame)
- Color palette: Electric yellow (#FFFF00), white flash (#FFFFFF), blue (#00BFFF), purple hints (#9370DB)
- Animation: Frame 1: Thin bolt strikes from top, Frame 2-3: Impact flash expands, Frame 4-5: Electric arcs spread outward on ground, Frame 6-8: Residual sparks dissipate
- Style: Dramatic cartoon, high contrast
- Elements: Central strike point, radiating electric arcs, floating spark particles
- Background: Transparent (PNG)

Name file: aoe_lightning_strike_spritesheet.png
```

### 2.3 Poison/Nature AOE
**Carpeta destino**: `assets/vfx/abilities/aoe/nature/` (crear carpeta)

```
PROMPT:
Create a cartoon-style spritesheet for a "poison cloud/nature AOE" effect.
The effect should show a toxic/natural area of effect spreading.

Specifications:
- 8 frames horizontal layout (1024x128 total, 128x128 per frame)
- Color palette: Sickly green (#9ACD32), purple poison (#8B008B), dark green (#228B22)
- Animation: Frame 1-2: Bubbles/spores emerge from ground, Frame 3-5: Cloud expands with swirling motion, Frame 6-8: Cloud thins and fades
- Style: Cartoony but slightly ominous
- Elements: Bubbling base, swirling cloud particles, floating spores/leaves
- Background: Transparent (PNG)

Name file: aoe_poison_cloud_spritesheet.png
```

---

## 🎯 CATEGORÍA 3: VFX DE ELITE/BOSS (Prioridad Media-Baja)

### 3.1 Rune Blast (existe asset pero no se usa)
El asset `aoe_rune_blast_spritesheet.png` ya existe pero el código no lo usa. Este es un problema de código, no de assets.

### 3.2 Elite Nova (necesita variantes por elemento)
Actualmente el Elite Nova usa un color dorado genérico. Idealmente necesitaría variantes:

```
PROMPT (Fire variant):
Create a cartoon-style spritesheet for a "fire nova shockwave" AOE effect.
Represents an elite enemy releasing a fiery explosion.

Specifications:
- 8 frames (1024x128 total, 128x128 per frame)
- Color palette: Orange (#FF8C00), red (#FF4500), yellow core (#FFFF00)
- Animation: Expanding ring of fire with flame tongues
- Background: Transparent (PNG)

Name file: elite_nova_fire_spritesheet.png
```

```
PROMPT (Ice variant):
Create a cartoon-style spritesheet for an "ice nova shockwave" AOE effect.
Represents an elite enemy releasing a freezing blast.

Specifications:
- 8 frames (1024x128 total, 128x128 per frame)
- Color palette: Cyan (#00FFFF), white (#FFFFFF), light blue (#87CEEB)
- Animation: Expanding ring of frost crystals with cold mist
- Background: Transparent (PNG)

Name file: elite_nova_ice_spritesheet.png
```

---

## 📝 Notas de Implementación

### Para cada asset generado:

1. Guarda el PNG en la carpeta indicada
2. Godot generará automáticamente el archivo `.import`
3. Actualiza el código correspondiente en `VFXManager.gd` para añadir la configuración

### Configuración típica en VFXManager.gd:

```gdscript
# Ejemplo para añadir thorns VFX
var PLAYER_VFX_CONFIG = {
    "thorns": {
        "path": "res://assets/vfx/abilities/player/thorns/player_thorns_spritesheet.png",
        "hframes": 8, "vframes": 1, "frame_size": Vector2(128, 128), "duration": 0.5
    },
    # ... etc
}
```

---

## 🔧 Correcciones de Código Necesarias

Además de los assets, hay problemas de código que deben corregirse:

### 1. Rune Blast no usa VFXManager
**Archivo**: `EnemyAttackSystem.gd` línea ~2864
**Problema**: `_spawn_rune_blast_visual()` nunca llama a `_try_spawn_via_vfxmanager("rune_blast", "aoe", ...)`
**Solución**: Añadir llamada a VFXManager antes del fallback procedural

### 2. Lightning fallback incorrecto
**Archivo**: `VFXManager.gd` línea ~201
**Problema**: `"lightning" -> "arcane"` debería tener su propio asset
**Solución**: Crear projectile_lightning_spritesheet.png y mapear correctamente

### 3. Elite abilities sin mapeo de elemento
**Archivo**: `EnemyAttackSystem.gd`
**Problema**: Elite novas/slams usan color dorado genérico en vez del elemento del enemigo
**Solución**: Pasar elemento del enemigo al VFX y usar variantes por elemento

### 4. Mappings faltantes en ABILITY_TO_AOE
**Archivo**: `VFXManager.gd`
**Problema**: "elite_slam", "damage_zone_fire", "damage_zone_void" existen en AOE_CONFIG pero no en ABILITY_TO_AOE
**Solución**: Añadir los mapeos faltantes
