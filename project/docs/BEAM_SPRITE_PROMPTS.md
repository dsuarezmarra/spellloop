# 🌟 PROMPTS PARA SPRITES DE ARMAS TIPO BEAM

Este archivo contiene los prompts de IA específicos para las armas tipo BEAM (rayos instantáneos).

## Información Técnica

Las armas BEAM disparan un **rayo instantáneo** desde el jugador hacia el objetivo.
El sistema visual usa 2 sprites animados + Line2D con gradiente para el cuerpo:

1. **beam_start** - Orbe de energía en el ORIGEN del rayo (junto al jugador)
2. **beam_tip** - Punta brillante en el FINAL del rayo (donde impacta)
3. El **cuerpo del rayo** se genera **proceduralmente** con Line2D y gradiente de colores

**NO se necesitan sprites de vuelo/impacto separados** - todo es instantáneo.

### Archivos de salida esperados:
- `beam_start_[weapon_id].png` - 384x64 (6 frames de 64x64)
- `beam_tip_[weapon_id].png` - 384x64 (6 frames de 64x64)

### Lista de armas BEAM:
| ID | Nombre | Componentes | Colores |
|----|--------|-------------|---------|
| light_beam | Rayo de Luz | Base | Blanco/Dorado |
| thunder_spear | Lanza del Trueno | lightning + light | Dorado/Cyan eléctrico |
| aurora | Aurora | ice + light | Cyan/Verde aurora |
| solar_flare | Llamarada Solar | fire + light | Amarillo/Naranja solar |
| solar_bloom | Flor Solar | nature + light | Verde/Dorado |
| eclipse | Eclipse | light + void | Blanco-Dorado / Púrpura-Negro |

---

## ✨ LIGHT BEAM - Rayo de Luz (Base)

> **Elemento**: LIGHT  
> **Descripción**: Dispara un rayo de luz pura que atraviesa todo

### Beam Start - Orbe de Origen (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000) for transparency. Content centered, max 54x54px.

Subject: Holy light energy orb - the SOURCE point where a beam originates

Design:
- Shape: Perfect glowing sphere, bright and divine
- Core: Pure white (#FFFFFF) - intensely bright center
- Inner glow: Pale gold-yellow (#FFFACC) 
- Outer glow: Soft yellow (#FFFF99)
- Halo effect: Pale white-yellow (#FFFFEE) aura extending outward
- Outline: Soft gold (#CCAA66), 2 pixels

Animation: Energy orb PULSING with holy light (6-frame LOOP)
- Frame 1: Orb at normal size, soft glow
- Frame 2: Orb brightening, glow expanding
- Frame 3: Maximum brightness, halo at peak, small lens flare
- Frame 4: Holding bright, star particles visible
- Frame 5: Starting to dim slightly
- Frame 6: Returning to normal, ready to loop

Key details:
- The orb is WHERE THE BEAM STARTS (at the caster)
- Very bright, divine, holy appearance
- 2-3 small star/sparkle particles floating around
- Soft lens flare effect at peak brightness
- Should look like concentrated holy energy about to fire

Style: Cartoon/Funko Pop, clean shapes, bold but soft outlines
Output: beam_start_light_beam.png (384x64)
```

### Beam Tip - Punta del Rayo (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000) for transparency. Content centered, max 54x54px.

Subject: Holy light beam TIP - the END point where the beam hits

Design:
- Shape: Elongated energy burst pointing LEFT (toward the beam body)
- Core: Pure white (#FFFFFF)
- Main body: Pale gold (#FFFACC)
- Energy trails: Soft yellow (#FFFF99)
- Impact sparkles: White (#FFFFFF)
- Outline: Soft gold (#CCAA66), 2 pixels

Animation: Impact point PULSING with dispersing energy (6-frame LOOP)
- Frame 1: Sharp point of impact, energy concentrated
- Frame 2: Energy expanding at impact point
- Frame 3: Maximum expansion, sparkles flying outward
- Frame 4: Energy dispersing in radial pattern
- Frame 5: Particles spreading, glow dimming
- Frame 6: Returning to concentrated point, loop ready

Key details:
- Points LEFT because it's at the END of a beam going RIGHT
- Looks like concentrated light energy hitting something
- Small star particles ejecting radially
- Softer/more diffuse than the start orb
- Divine holy energy dispersing on impact

Style: Cartoon/Funko Pop, clean shapes
Output: beam_tip_light_beam.png (384x64)
```

---

## 🔱 THUNDER SPEAR - Lanza del Trueno

> **Fusión**: lightning_wand + light_beam  
> **Descripción**: Un rayo divino que aniquila todo en su camino

### Beam Start - Orbe de Tormenta Divina (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Divine thunder energy orb - lightning meets holy light

Design:
- Shape: Electric sphere with divine radiance
- Core: Pure white (#FFFFFF) with electric crackles
- Primary: Bright gold-yellow (#FFE033) divine energy
- Secondary: Electric cyan-white (#EEFFFF) lightning
- Electric arcs: Bright yellow (#FFFF33)
- Outline: Deep gold (#AA8833), 2 pixels

Animation: Thunder orb CRACKLING with divine electricity (6-frame LOOP)
- Frame 1: Orb stable, small electric arcs
- Frame 2: Lightning arcs intensifying, glow expanding
- Frame 3: Maximum power, multiple electric bolts around orb
- Frame 4: Divine flash, peak energy
- Frame 5: Arcs diminishing
- Frame 6: Returning to stable, loop ready

Key details:
- Combination of holy light (gold/white) + lightning (cyan/yellow)
- 3-4 small lightning bolts crackling around the sphere
- Divine halo effect behind
- More intense/powerful than basic light_beam
- Electric sparks jumping around

Style: Cartoon/Funko Pop
Output: beam_start_thunder_spear.png (384x64)
```

### Beam Tip - Punta de Lanza Electrica (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Divine thunder spear TIP - electric impact point

Design:
- Shape: Spear-point shape pointing LEFT, electric and sharp
- Core: Pure white (#FFFFFF) concentrated point
- Main: Gold-yellow (#FFE033) 
- Electric: Cyan-white (#EEFFFF) arcs
- Sparks: Bright yellow (#FFFF33)
- Outline: Deep gold (#AA8833), 2 pixels

Animation: Electric spear tip STRIKING and sparking (6-frame LOOP)
- Frame 1: Sharp point concentrated
- Frame 2: Electric discharge beginning
- Frame 3: Maximum discharge, lightning arcs flying out
- Frame 4: Sparks shooting in all directions
- Frame 5: Energy dispersing
- Frame 6: Returning to point

Key details:
- More SHARP/ANGULAR than light_beam tip (it's a spear)
- Electric arcs shooting outward radially
- Combination of holy + electric energy
- High intensity impact effect

Output: beam_tip_thunder_spear.png (384x64)
```

---

## ❄️ AURORA - Luz Helada

> **Fusion**: ice_wand + light_beam  
> **Descripcion**: Un rayo de luz fria que congela todo en su camino

### Beam Start - Orbe de Aurora Boreal (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Frozen light energy orb - ice crystals with holy light

Design:
- Shape: Crystalline sphere with ice facets and inner glow
- Core: Pure white (#FFFFFF) bright light
- Primary: Pale cyan ice (#CCFFFF)
- Secondary: Soft aurora green (#99FFCC)
- Ice crystals: Light blue (#99DDFF)
- Outline: Deep teal (#336666), 2 pixels

Animation: Aurora orb SHIMMERING with ice and light (6-frame LOOP)
- Frame 1: Orb glowing softly, ice crystals visible
- Frame 2: Aurora colors shifting (cyan to green)
- Frame 3: Peak brightness, frost particles visible
- Frame 4: Colors shifting back
- Frame 5: Ice crystals sparkling
- Frame 6: Return to start

Key details:
- Beautiful aurora borealis color shifting effect
- Small ice crystal fragments floating around
- Soft, ethereal, cold beauty
- Frost mist particles
- Divine light filtered through ice

Style: Cartoon/Funko Pop
Output: beam_start_aurora.png (384x64)
```

### Beam Tip - Cristal de Aurora (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Aurora beam TIP - ice crystal impact with light

Design:
- Shape: Ice crystal burst pointing LEFT
- Core: White (#FFFFFF)
- Primary: Pale cyan (#CCFFFF)
- Secondary: Aurora green (#99FFCC)
- Ice shards: Light blue (#99DDFF)
- Outline: Deep teal (#336666), 2 pixels

Animation: Ice crystal tip SHATTERING with light (6-frame LOOP)
- Frame 1: Crystal point concentrated
- Frame 2: Frost burst beginning
- Frame 3: Ice shards exploding outward with light
- Frame 4: Maximum spread, aurora colors visible
- Frame 5: Shards fading
- Frame 6: Return to crystal point

Key details:
- Ice crystals breaking apart at impact
- Aurora color shimmer in the frost
- Snowflake particles
- Cold, beautiful, deadly

Output: beam_tip_aurora.png (384x64)
```

---

## ☀️ SOLAR FLARE - Llamarada Solar

> **Fusion**: fire_wand + light_beam  
> **Descripcion**: Un rayo de fuego solar que incinera todo

### Beam Start - Orbe Solar (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Solar fire energy orb - sun-like intense heat and light

Design:
- Shape: Blazing sphere like a miniature sun
- Core: Pure white (#FFFFFF) - nuclear hot center
- Primary: Bright yellow-white (#FFEE55)
- Secondary: Intense orange (#FF8822)
- Solar flares: Red-orange (#FF5500) wisps extending out
- Outline: Deep orange-red (#993300), 2 pixels

Animation: Solar orb FLARING with sun-like eruptions (6-frame LOOP)
- Frame 1: Sun orb stable, small flares
- Frame 2: Solar flare extending, brightness increasing
- Frame 3: Maximum flare, corona visible, intense white center
- Frame 4: Holding peak, heat shimmer effect
- Frame 5: Flares retracting
- Frame 6: Return to stable

Key details:
- Looks like a MINIATURE SUN
- Solar flare wisps extending outward
- Intense heat shimmer/corona effect
- Much more intense than basic light_beam
- Nuclear hot appearance

Style: Cartoon/Funko Pop
Output: beam_start_solar_flare.png (384x64)
```

### Beam Tip - Impacto Solar (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Solar flare beam TIP - fiery light explosion

Design:
- Shape: Explosive burst pointing LEFT
- Core: White-hot (#FFFFFF)
- Primary: Bright yellow (#FFEE55)
- Secondary: Orange flames (#FF8822)
- Embers: Red-orange (#FF5500)
- Outline: Deep orange (#993300), 2 pixels

Animation: Solar impact EXPLODING with fire and light (6-frame LOOP)
- Frame 1: Concentrated point of impact
- Frame 2: Fire burst starting
- Frame 3: Maximum explosion, flames and light everywhere
- Frame 4: Embers flying outward
- Frame 5: Flames dispersing
- Frame 6: Return to point

Key details:
- Solar explosion at impact point
- Fire + light combined
- Embers/sparks shooting radially
- Intense, incinerating energy

Output: beam_tip_solar_flare.png (384x64)
```

---

## 🌻 SOLAR BLOOM - Flor Solar

> **Fusion**: nature_staff + light_beam  
> **Descripcion**: Un rayo de energia vital que cura mientras destruye

### Beam Start - Orbe de Vida Solar (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Life-light energy orb - nature magic meets holy light

Design:
- Shape: Organic glowing sphere with leaf/petal patterns inside
- Core: Bright yellow-white (#FFFFCC) life energy
- Primary: Bright green (#66FF66) nature energy
- Secondary: Soft gold (#FFEE88) sunlight
- Leaf particles: Light green (#99FF99)
- Outline: Forest green (#336633), 2 pixels

Animation: Life orb BLOOMING with nature energy (6-frame LOOP)
- Frame 1: Orb stable with inner leaves visible
- Frame 2: Energy expanding, flower petals appearing
- Frame 3: Full bloom, maximum green-gold glow
- Frame 4: Sparkles and leaf particles flying
- Frame 5: Petals retracting
- Frame 6: Return to stable

Key details:
- Combination of NATURE (green) + LIGHT (gold)
- Small flower petals/leaves floating around
- Healing/life energy feel
- Warm, nurturing, but powerful

Style: Cartoon/Funko Pop
Output: beam_start_solar_bloom.png (384x64)
```

### Beam Tip - Floracion de Luz (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Solar bloom beam TIP - flower burst with light

Design:
- Shape: Flower-burst shape pointing LEFT
- Core: Yellow-white (#FFFFCC)
- Primary: Green (#66FF66)
- Secondary: Gold (#FFEE88)
- Petals: Pink-white (#FFCCEE)
- Outline: Forest green (#336633), 2 pixels

Animation: Flower burst BLOOMING at impact (6-frame LOOP)
- Frame 1: Bud-like concentrated point
- Frame 2: Flower starting to bloom
- Frame 3: Full flower bloom, petals radiating
- Frame 4: Petals floating outward
- Frame 5: Petals fading, sparkles
- Frame 6: Return to bud

Key details:
- Flower/bloom effect at impact
- Nature + light combined
- Healing sparkles mixed with damage
- Beautiful, organic energy

Output: beam_tip_solar_bloom.png (384x64)
```

---

## 🌑 ECLIPSE - Eclipse Total

> **Fusion**: light_beam + void_pulse  
> **Descripcion**: El equilibrio entre luz y oscuridad, destruccion pura

### Beam Start - Orbe de Eclipse (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Eclipse energy orb - light and void swirling together

Design:
- Shape: Sphere split between light and dark, swirling
- Light side: White-gold (#FFFFCC) holy light
- Dark side: Deep purple-black (#1A0033) void
- Corona: Pale purple (#CC99FF) where they meet
- Void wisps: Dark purple (#4D0099)
- Outline: Gray-purple (#443355), 2 pixels

Animation: Eclipse orb with SWIRLING light/dark balance (6-frame LOOP)
- Frame 1: Light on top, dark on bottom
- Frame 2: Swirling clockwise, energies mixing
- Frame 3: 90 degrees rotation, intense corona where they meet
- Frame 4: Continue rotation, void pulling light
- Frame 5: Almost inverted
- Frame 6: Return to start position

Key details:
- YIN-YANG style swirl of light and dark
- Corona/ring effect where the two energies meet
- Both holy and ominous appearance
- Very powerful, unique visual
- Total annihilation energy

Style: Cartoon/Funko Pop
Output: beam_start_eclipse.png (384x64)
```

### Beam Tip - Aniquilacion Eclipse (6 frames)
```
Create a horizontal sprite strip of 6 frames (64x64 each = 384x64 total).
Black background (#000000). Content centered, max 54x54px.

Subject: Eclipse beam TIP - light and void annihilation

Design:
- Shape: Explosive ring shape pointing LEFT
- Light parts: White-gold (#FFFFCC)
- Dark parts: Purple-black (#1A0033)
- Corona ring: Pale purple (#CC99FF)
- Void tendrils: Dark purple (#4D0099)
- Outline: Gray-purple (#443355), 2 pixels

Animation: Eclipse impact ANNIHILATING target (6-frame LOOP)
- Frame 1: Point of contact, both energies compressed
- Frame 2: Explosion starting, light/dark separating
- Frame 3: Maximum explosion, ring of purple corona
- Frame 4: Void tendrils and light rays shooting out
- Frame 5: Energies dispersing
- Frame 6: Return to point

Key details:
- DUAL explosion effect - light + void simultaneously
- Purple corona ring at the boundary
- Both divine and sinister
- Ultimate destruction visual
- Execute effect (kills low HP enemies)

Output: beam_tip_eclipse.png (384x64)
```

---

## Estructura de Carpetas

Crear carpetas para cada arma:
```
project/assets/sprites/projectiles/weapons/
├── light_beam/
│   ├── beam_start_light_beam.png
│   └── beam_tip_light_beam.png
├── thunder_spear/
│   ├── beam_start_thunder_spear.png
│   └── beam_tip_thunder_spear.png
├── aurora/
│   ├── beam_start_aurora.png
│   └── beam_tip_aurora.png
├── solar_flare/
│   ├── beam_start_solar_flare.png
│   └── beam_tip_solar_flare.png
├── solar_bloom/
│   ├── beam_start_solar_bloom.png
│   └── beam_tip_solar_bloom.png
└── eclipse/
    ├── beam_start_eclipse.png
    └── beam_tip_eclipse.png
```

## Colores por Arma (Resumen para Line2D)

Estos colores se usan para el gradiente del Line2D que forma el cuerpo del rayo:

| Arma | Primary | Secondary | Core | Outline |
|------|---------|-----------|------|---------|
| light_beam | #FFFACC | #FFFF99 | #FFFFFF | #CCAA66 |
| thunder_spear | #FFE033 | #EEFFFF | #FFFFFF | #AA8833 |
| aurora | #CCFFFF | #99FFCC | #FFFFFF | #336666 |
| solar_flare | #FFEE55 | #FF8822 | #FFFFFF | #993300 |
| solar_bloom | #66FF66 | #FFEE88 | #FFFFCC | #336633 |
| eclipse | #FFFFCC / #1A0033 | #CC99FF | #FFFFFF | #443355 |
