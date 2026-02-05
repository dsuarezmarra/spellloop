# VFX Missing Assets - Prompts para DALL-E

## 📁 Estructura de Carpetas Requerida

```
assets/vfx/abilities/
├── aoe/
│   ├── warning/
│   │   └── aoe_warning_circle_spritesheet.png
│   ├── explosion/
│   │   └── aoe_explosion_generic_spritesheet.png
│   ├── elite/
│   │   ├── aoe_elite_dash_charge_spritesheet.png
│   │   ├── aoe_elite_dash_trail_spritesheet.png
│   │   ├── aoe_elite_nova_charge_spritesheet.png
│   │   └── aoe_elite_summon_circle_spritesheet.png
│   └── boss/
│       └── aoe_damage_trail_spritesheet.png
├── player/
│   ├── thorns/
│   │   └── vfx_thorns_reflect_spritesheet.png
│   ├── heal/
│   │   └── vfx_heal_particles_spritesheet.png
│   ├── shield/
│   │   └── vfx_shield_absorb_spritesheet.png
│   ├── buffs/
│   │   ├── vfx_buff_speed_spritesheet.png
│   │   ├── vfx_buff_strength_spritesheet.png
│   │   └── vfx_buff_turret_spritesheet.png
│   ├── debuffs/
│   │   ├── vfx_debuff_burn_spritesheet.png
│   │   ├── vfx_debuff_poison_spritesheet.png
│   │   ├── vfx_debuff_slow_spritesheet.png
│   │   └── vfx_debuff_stun_spritesheet.png
│   ├── revive/
│   │   └── vfx_phoenix_revive_spritesheet.png
│   └── soul_link/
│       └── vfx_soul_link_beam_spritesheet.png
└── telegraphs/
    └── telegraph_boss_warning_spritesheet.png
```

---

## 🎨 PROMPTS PARA DALL-E

### ═══════════════════════════════════════════════════════════════
### CATEGORÍA 1: AOE WARNINGS Y EXPLOSIONES (BOSSES)
### ═══════════════════════════════════════════════════════════════

#### 1.1 AOE Warning Circle (Indicador de peligro)
**Archivo:** `aoe_warning_circle_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Danger warning circle indicator animation for boss attacks.
Frame sequence: pulsing red circle that grows and flashes, warning symbol in center.
Style: Semi-transparent with soft edges, cartoon/stylized aesthetic.
Colors: Deep red (#CC2222) with orange glow (#FF6600), white warning symbol.
Pulsing effect with concentric rings expanding outward.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, top-down perspective, game VFX asset.
```

#### 1.2 AOE Explosion Generic
**Archivo:** `aoe_explosion_generic_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Magical explosion effect for area damage, top-down view.
Frame sequence: bright flash → expanding wave → dissipating rings.
Style: Cartoon/painterly with soft glow, NOT pixel art.
Colors: White core (#FFFFFF) → orange (#FF8800) → red (#CC3300) outer ring.
Particles flying outward, shockwave ripples visible.
128x128 pixels per frame, single-play animation.
Transparent/black background, game VFX asset.
```

#### 1.3 Elite Dash Charge
**Archivo:** `aoe_elite_dash_charge_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Charging energy effect before elite enemy dash attack.
Frame sequence: gathering golden energy → compression → flash ready.
Style: Stylized cartoon with soft glow, funko pop aesthetic.
Colors: Gold (#FFD700), amber (#FFAA00), white highlights.
Arrows or directional energy pointing forward, pulsing glow.
128x128 pixels per frame, single-play animation.
Transparent/black background, game VFX asset.
```

#### 1.4 Elite Dash Trail
**Archivo:** `aoe_elite_dash_trail_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Speed trail effect left behind by dashing elite enemy.
Frame sequence: bright trail → fading streaks → dissipating particles.
Style: Motion blur effect with soft edges, stylized.
Colors: Gold (#FFD700) to transparent gradient, sparkle particles.
Horizontal elongated shape, movement lines visible.
128x128 pixels per frame, fade-out animation.
Transparent/black background, game VFX asset.
```

#### 1.5 Elite Nova Charge
**Archivo:** `aoe_elite_nova_charge_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Energy gathering effect before elite nova explosion.
Frame sequence: particles inward → energy compression → bright pulse.
Style: Magical energy swirl, cartoon aesthetic.
Colors: Purple (#8844CC) core, gold (#FFD700) rings, white center.
Swirling energy lines converging to center, magical runes.
128x128 pixels per frame, single-play animation.
Transparent/black background, top-down view, game VFX asset.
```

#### 1.6 Elite Summon Circle
**Archivo:** `aoe_elite_summon_circle_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Magical summoning circle effect for elite enemy spawning minions.
Frame sequence: circle appears → glowing runes → portal flash → completion.
Style: Fantasy magical circle with arcane symbols, soft glow.
Colors: Deep purple (#6633AA), magenta (#CC33FF), gold (#FFD700) runes.
Rotating inner ring, magical symbols around edge, ethereal particles.
128x128 pixels per frame, single-play animation.
Transparent/black background, top-down view, game VFX asset.
```

#### 1.7 Boss Damage Trail
**Archivo:** `aoe_damage_trail_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Persistent damage zone left by boss movement.
Frame sequence: ground crack appears → glowing danger → pulsing hazard.
Style: Corrupted ground effect, dark fantasy aesthetic.
Colors: Dark gray (#444444), deep red (#990000), ember orange (#FF4400).
Cracks in ground, small flames or energy wisps, danger aura.
128x128 pixels per frame, looping animation.
Transparent/black background, top-down view, game VFX asset.
```

---

### ═══════════════════════════════════════════════════════════════
### CATEGORÍA 2: EFECTOS DEL JUGADOR
### ═══════════════════════════════════════════════════════════════

#### 2.1 Thorns Reflect Damage
**Archivo:** `vfx_thorns_reflect_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Thorn/spike effect when player reflects damage to attacker.
Frame sequence: thorny spikes appear → flash outward → retract.
Style: Nature-based with sharp edges, cartoon aesthetic.
Colors: Brown (#664422) thorns, green (#44AA44) glow, red (#CC3333) damage flash.
Sharp thorn spikes radiating outward, nature energy particles.
128x128 pixels per frame, single-play animation.
Transparent/black background, top-down view, game VFX asset.
```

#### 2.2 Heal Particles
**Archivo:** `vfx_heal_particles_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Healing effect with floating green particles rising upward.
Frame sequence: particles spawn → float up → fade out.
Style: Soft glowing particles, magical healing aesthetic.
Colors: Bright green (#44FF66), light green (#88FF88), white (#FFFFFF) sparkles.
Plus symbols, hearts, or leaf-like particles floating upward.
128x128 pixels per frame, single-play animation.
Transparent/black background, game VFX asset.
```

#### 2.3 Shield Absorb
**Archivo:** `vfx_shield_absorb_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Shield absorption effect when blocking damage completely.
Frame sequence: hexagonal shield flash → ripple effect → fade.
Style: Energy barrier, sci-fi/fantasy hybrid aesthetic.
Colors: Cyan (#00CCFF), blue (#0066FF), white (#FFFFFF) core flash.
Hexagonal pattern, energy ripples, protective barrier visual.
128x128 pixels per frame, single-play animation.
Transparent/black background, game VFX asset.
```

#### 2.4 Phoenix Revive
**Archivo:** `vfx_phoenix_revive_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Phoenix resurrection effect when player revives from death.
Frame sequence: fiery explosion → phoenix silhouette → golden rebirth.
Style: Dramatic fire/light effect, epic fantasy aesthetic.
Colors: Gold (#FFD700), orange (#FF8800), red (#FF3300), white (#FFFFFF) core.
Phoenix wing shapes, rising flames, divine light rays.
128x128 pixels per frame, single-play animation.
Transparent/black background, game VFX asset.
```

#### 2.5 Soul Link Beam
**Archivo:** `vfx_soul_link_beam_spritesheet.png`
**Dimensiones:** 512x256 (4x2 frames de 128x128)

```
2D game VFX spritesheet, 8 frames arranged in 4x2 grid.
Magical connection beam linking player to enemies.
Frame sequence: beam appears → pulsing energy flow → fade out.
Style: Ethereal energy connection, magical aesthetic.
Colors: Magenta (#CC33CC), purple (#9933FF), white (#FFFFFF) core.
Wavy energy line, soul particles flowing, mystical connection.
128x128 pixels per frame, can be stretched horizontally.
Transparent/black background, game VFX asset.
```

---

### ═══════════════════════════════════════════════════════════════
### CATEGORÍA 3: BUFFS DEL JUGADOR
### ═══════════════════════════════════════════════════════════════

#### 3.1 Speed Buff
**Archivo:** `vfx_buff_speed_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Speed boost aura effect surrounding player.
Frame sequence: looping wind/speed lines swirling around character.
Style: Motion energy, cartoon aesthetic with soft glow.
Colors: Cyan (#00CCCC), light blue (#66DDFF), white (#FFFFFF) streaks.
Speed lines, wind swirls, motion blur particles.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, top-down view, game VFX asset.
```

#### 3.2 Strength Buff
**Archivo:** `vfx_buff_strength_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Strength boost aura effect surrounding player.
Frame sequence: looping red/orange power energy pulsing.
Style: Fiery power aura, cartoon aesthetic.
Colors: Red (#FF3300), orange (#FF8800), yellow (#FFCC00) core.
Flame-like energy, power symbols, muscular aura effect.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, top-down view, game VFX asset.
```

#### 3.3 Turret Mode
**Archivo:** `vfx_buff_turret_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Stationary turret mode indicator aura around player.
Frame sequence: looping defensive stance energy field.
Style: Mechanical/magical hybrid, glowing rings.
Colors: Gold (#FFD700), bronze (#CC8800), white (#FFFFFF) highlights.
Rotating targeting circles, defensive runes, power-up glow.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, top-down view, game VFX asset.
```

---

### ═══════════════════════════════════════════════════════════════
### CATEGORÍA 4: DEBUFFS DEL JUGADOR
### ═══════════════════════════════════════════════════════════════

#### 4.1 Burn Debuff
**Archivo:** `vfx_debuff_burn_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Burning effect on player taking fire damage over time.
Frame sequence: looping flames around character silhouette.
Style: Cartoon fire, soft glow edges.
Colors: Orange (#FF6600), red (#FF2200), yellow (#FFCC00) tips.
Small flames rising, ember particles, heat distortion effect.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, game VFX asset.
```

#### 4.2 Poison Debuff
**Archivo:** `vfx_debuff_poison_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Poison effect on player taking toxic damage over time.
Frame sequence: looping toxic bubbles and dripping effect.
Style: Slimy/toxic aesthetic, cartoon style.
Colors: Toxic green (#66CC33), dark green (#338822), purple (#993399) accent.
Bubbles rising, dripping slime, skull/toxic symbols.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, game VFX asset.
```

#### 4.3 Slow Debuff
**Archivo:** `vfx_debuff_slow_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Slowing ice/cold effect on movement-impaired player.
Frame sequence: looping frost crystals and cold mist.
Style: Icy/frozen aesthetic, cartoon style.
Colors: Light blue (#88CCFF), white (#FFFFFF), pale cyan (#AAEEFF).
Ice crystals forming, cold mist swirling, snowflake particles.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, game VFX asset.
```

#### 4.4 Stun Debuff
**Archivo:** `vfx_debuff_stun_spritesheet.png`
**Dimensiones:** 768x128 (6x1 frames de 128x128)

```
2D game VFX spritesheet, 6 frames arranged in horizontal row.
Stun effect with stars/symbols circling player head.
Frame sequence: looping stars and dizzy symbols rotating.
Style: Classic cartoon stun effect, playful.
Colors: Yellow (#FFDD00), white (#FFFFFF), red (#FF3333) accents.
Stars, spirals, birds, or lightning bolts circling.
128x128 pixels per frame, seamless loop animation.
Transparent/black background, game VFX asset.
```

---

## 📋 RESUMEN DE ASSETS REQUERIDOS

| Categoría | Asset | Frames | Tamaño Frame | Archivo |
|-----------|-------|--------|--------------|---------|
| **AOE Warning** | Warning Circle | 8 (4x2) | 128x128 | aoe_warning_circle_spritesheet.png |
| **AOE Warning** | Explosion Generic | 8 (4x2) | 128x128 | aoe_explosion_generic_spritesheet.png |
| **Elite** | Dash Charge | 8 (4x2) | 128x128 | aoe_elite_dash_charge_spritesheet.png |
| **Elite** | Dash Trail | 8 (4x2) | 128x128 | aoe_elite_dash_trail_spritesheet.png |
| **Elite** | Nova Charge | 8 (4x2) | 128x128 | aoe_elite_nova_charge_spritesheet.png |
| **Elite** | Summon Circle | 8 (4x2) | 128x128 | aoe_elite_summon_circle_spritesheet.png |
| **Boss** | Damage Trail | 8 (4x2) | 128x128 | aoe_damage_trail_spritesheet.png |
| **Player** | Thorns Reflect | 8 (4x2) | 128x128 | vfx_thorns_reflect_spritesheet.png |
| **Player** | Heal Particles | 8 (4x2) | 128x128 | vfx_heal_particles_spritesheet.png |
| **Player** | Shield Absorb | 8 (4x2) | 128x128 | vfx_shield_absorb_spritesheet.png |
| **Player** | Phoenix Revive | 8 (4x2) | 128x128 | vfx_phoenix_revive_spritesheet.png |
| **Player** | Soul Link Beam | 8 (4x2) | 128x128 | vfx_soul_link_beam_spritesheet.png |
| **Buff** | Speed | 6 (6x1) | 128x128 | vfx_buff_speed_spritesheet.png |
| **Buff** | Strength | 6 (6x1) | 128x128 | vfx_buff_strength_spritesheet.png |
| **Buff** | Turret Mode | 6 (6x1) | 128x128 | vfx_buff_turret_spritesheet.png |
| **Debuff** | Burn | 6 (6x1) | 128x128 | vfx_debuff_burn_spritesheet.png |
| **Debuff** | Poison | 6 (6x1) | 128x128 | vfx_debuff_poison_spritesheet.png |
| **Debuff** | Slow | 6 (6x1) | 128x128 | vfx_debuff_slow_spritesheet.png |
| **Debuff** | Stun | 6 (6x1) | 128x128 | vfx_debuff_stun_spritesheet.png |

**Total: 19 spritesheets**

---

## 🔧 NOTAS DE INTEGRACIÓN

Una vez generados los assets, se deben:

1. Colocar en las carpetas indicadas en la estructura
2. Registrar en `VFXManager.gd` los nuevos tipos en `AOE_CONFIG` o `AURA_CONFIG`
3. Actualizar las funciones de spawn en `EnemyAttackSystem.gd` para usar VFXManager
4. Actualizar `BasePlayer.gd` / `LoopiaLikePlayer.gd` para usar los nuevos sprites en lugar de CPUParticles2D
