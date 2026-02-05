# VFX Asset Generation Prompts

Use these prompts with an AI image generator (Midjourney, DALL-E, Stable Diffusion) to create additional VFX assets for SpellLoop.

---

## 🎨 Style Guidelines (Apply to ALL prompts)

**Base style modifier (prepend to all prompts):**
```
Pixel art style, 32x32 pixel resolution per frame, retro game aesthetic, 
Vampire Survivors / Hades / Dead Cells inspired, dark fantasy theme, 
transparent background, sprite sheet format
```

---

## 1. Enemy Death Explosion Effects

### Prompt: Generic Death Explosion
```
Create a pixel art sprite sheet of an enemy death explosion effect.
8 frames in a horizontal strip (4 columns × 2 rows, 256×128 total).
Each frame 64×64 pixels.

Frame sequence:
1-2: Initial burst with white/yellow core
3-4: Expanding ring of particles and debris
5-6: Fading smoke and embers
7-8: Dissipating particles

Colors: Orange/red flames, white core flash, gray smoke
Style: Vampire Survivors pixel art death animation
Transparent background, game-ready sprite sheet
```

### Prompt: Elemental Death Variants
```
Create 5 pixel art death explosion sprite sheets for different elements.
Each sheet: 4 columns × 2 rows (256×128 total), 8 frames per element.

Elements:
1. FIRE: Orange/red flames, ember particles
2. ICE: Blue/white shards shattering, frost particles  
3. VOID: Purple/black imploding, dark wisps
4. POISON: Green toxic cloud, bubbling dissolution
5. ARCANE: Magenta/pink magic sparks, rune symbols

Pixel art style, 64×64 per frame, transparent background
Dead Cells / Vampire Survivors aesthetic
```

---

## 2. Loot & Pickup Effects

### Prompt: Item Pickup Sparkle
```
Create a pixel art sprite sheet for item pickup effect.
6 frames horizontal (384×64 total), each frame 64×64 pixels.

Animation: 
Sparkles and light rays emanating outward from center
Gold/white/yellow color scheme
Magical shine effect for when player picks up items

Retro game style, transparent background
Use in Vampire Survivors-style action RPG
```

### Prompt: XP Orb Absorption
```
Create a pixel art sprite sheet of XP orb being absorbed.
8 frames (4×2 grid, 256×128 total), 64×64 per frame.

Animation:
1-2: Glowing blue/cyan orb
3-4: Stretching toward player
5-6: Spiral absorption effect
7-8: Final flash and disappear

Pixel art, Vampire Survivors style, transparent background
```

---

## 3. Player Ability Effects (Optional Expansion)

### Prompt: Shield Break Effect
```
Pixel art sprite sheet of magical shield shattering.
8 frames (4×2, 256×128), 64×64 per frame.

Animation:
1-2: Shield intact with cracks appearing
3-4: Major fractures spreading
5-6: Explosive shatter with fragments flying
7-8: Fragments fading out

Blue/white/cyan color scheme, magical runes on fragments
Transparent background, retro RPG style
```

### Prompt: Critical Hit Impact
```
Pixel art sprite sheet for critical hit visual effect.
6 frames horizontal (384×64), 64×64 per frame.

Animation:
1: Initial flash (white/yellow)
2-3: Starburst explosion
4-5: Impact lines radiating outward
6: Fade with lingering sparks

High contrast, punchy colors (red/orange/yellow/white)
Action game style, transparent background
```

---

## 4. Environmental Effects

### Prompt: Ground Crack Effect
```
Pixel art sprite sheet of ground cracking from impact.
8 frames (4×2, 256×128), 64×64 per frame.

Animation:
1-2: Initial impact point
3-4: Cracks spreading outward
5-6: Debris/rocks rising
7-8: Settling with dust

Brown/gray stone colors, some orange/red for energy
Top-down perspective, transparent background
```

### Prompt: Summoning Circle
```
Pixel art sprite sheet of magical summoning circle.
12 frames (6×2, 384×128), 64×64 per frame.

Animation (looping):
1-4: Circle appearing with runes lighting up
5-8: Rotating inner symbols
9-12: Energy building to center

Purple/magenta primary, gold accents for runes
Dark fantasy style, transparent background
```

---

## 📐 Technical Specifications

| Asset Type | Grid | Total Size | Frame Size |
|------------|------|------------|------------|
| Standard VFX | 4×2 | 256×128 | 64×64 |
| Telegraph/Aura | 6×2 | 384×128 | 64×64 |
| Simple Effect | 4×1 | 256×64 | 64×64 |
| Large Boss VFX | 4×2 | 512×256 | 128×128 |

---

## 🔧 Post-Generation Processing

After generating images:

1. **Resize if needed** to match grid specifications
2. **Remove background** if not already transparent
3. **Adjust colors** to match game palette
4. **Save as PNG** with transparency
5. **Place in correct folder:**
   - AOE: `assets/vfx/abilities/aoe/[element]/`
   - Projectiles: `assets/vfx/abilities/projectiles/[element]/`
   - Misc: `assets/vfx/misc/`

---

## ✅ Current VFX Coverage

The game already has complete coverage for:
- ✅ All AOE effects (8 types)
- ✅ All projectile types (6 elements)
- ✅ All telegraph warnings (4 types)
- ✅ All auras (4 types)
- ✅ All beams (2 types)
- ✅ Boss-specific effects (4 types)

**Total: 29 production-ready VFX spritesheets**

The prompts above are for **optional enhancements** only.
