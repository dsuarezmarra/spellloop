# ?? Prompts para Animaciones del PALADIN

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo del personaje
2. Luego ve ejecutando los prompts **#1 al #6** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop (ver guía de estilo abajo)
- **Vista:** Top-down con ligera perspectiva 3/4
- **TODAS las animaciones:** 3 frames (1500x500 horizontal strip)

---

## ?? SISTEMA DE ANIMACIÓN (Estilo Binding of Isaac)

**Este juego usa ciclos de 3 frames en ping-pong para TODAS las animaciones:**

### Ciclo de animación:
```
Frame 1 ? Frame 2 ? Frame 3 ? Frame 2 ? Frame 1 ? ...
```

### ?? IMPORTANTE:
- **Walk Left NO se genera** - Se voltea horizontalmente el sprite de Walk Right en el código
- **TODAS las animaciones tienen 3 frames** - Walk, Cast, Death, Hit
- Total sprites: **18 frames** (6 animaciones × 3 frames)

---

## ?? GUÍA DE ESTILO - PALADIN

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre adulto, noble |
| **Complexión** | Atlético, musculoso pero elegante |
| **Cabello** | Rubio dorado, corto y ordenado |
| **Expresión** | Noble, justo, ojos brillando con luz divina |
| **Vestimenta** | Armadura blanca/dorada, capa blanca |
| **Detalles** | Símbolos sagrados, halo sutil, aura luminosa |
| **Arma** | Espada de luz o cetro sagrado |

### Paleta de colores:
- **Armadura:** Blanco plateado (#F5F5F5)
- **Detalles dorados:** Oro brillante (#FFD700)
- **Capa:** Blanco puro (#FFFFFF) con bordes dorados
- **Luz/Aura:** Amarillo suave (#FFFACD) a blanco
- **Cabello:** Rubio dorado (#DAA520)
- **Piel:** Bronceada clara (#DEB887)
- **Ojos:** Azul cielo brillante (#87CEEB)
- **Outline:** Dorado oscuro (#B8860B)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Paladin - Adult Male, Holy Warrior

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Bright blue eyes with holy glow
- Thick outline (2-3px) in golden brown
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Adult man with noble, heroic appearance
- Athletic, well-built but not bulky
- Short neat golden blonde hair
- Righteous, determined expression
- Bright glowing blue eyes
- White and gold plate armor (stylized)
- Flowing white cape with golden trim
- Subtle halo or light aura
- Holy symbols on armor (sun, star patterns)
- Glowing sword of light OR sacred scepter

COLOR PALETTE:
- Armor: Silver white (#F5F5F5)
- Gold details: Bright gold (#FFD700)
- Cape: Pure white (#FFFFFF) with gold edges
- Light/Aura: Soft yellow (#FFFACD)
- Hair: Golden blonde (#DAA520)
- Skin: Light tan (#DEB887)
- Eyes: Bright sky blue (#87CEEB)
- Outline: Dark gold (#B8860B)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `paladin_reference.png`

---

## PROMPT #1 - Walk Down (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking animation - FACING CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, holy warrior, glowing effects

CHARACTER: Noble paladin, gold/white armor, white cape, blonde hair, light aura

?? 3-FRAME WALK CYCLE:
- Frame 1: LEFT LEG OUT - Left armored boot stepped outward, slight body tilt left
- Frame 2: NEUTRAL - Both feet together, standing proud, centered pose
- Frame 3: RIGHT LEG OUT - Right armored boot stepped outward, slight body tilt right

ANIMATION NOTES:
- Ping-pong cycle: 1-2-3-2-1-2-3...
- Dignified, military walking rhythm
- Show armored boots clearly stepping

SECONDARY MOTION:
- Cape flows gracefully
- Subtle light aura pulses
- Holy symbols on armor glow

COLORS: Armor #F5F5F5, Gold #FFD700, Cape #FFFFFF, Hair #DAA520

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - BACK TO CAMERA (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, cape prominently visible

CHARACTER (from behind): White/gold armored warrior, flowing white cape, blonde hair

?? 3-FRAME WALK CYCLE (BACK VIEW):
- Frame 1: LEFT LEG OUT - Left leg stepped outward, cape parting
- Frame 2: NEUTRAL - Both feet together, standing tall
- Frame 3: RIGHT LEG OUT - Right leg stepped outward, cape settling

SECONDARY MOTION:
- Cape dramatically shows back
- Halo visible as soft glow
- Armor gleams with holy light

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_up_strip.png`

---

## PROMPT #3 - Walk Right (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - RIGHT SIDE PROFILE (Binding of Isaac style)

ART STYLE: Funko Pop/Chibi, noble profile

CHARACTER (right profile): Armored paladin, cape trailing, weapon visible

?? 3-FRAME WALK CYCLE (SIDE VIEW):
- Frame 1: BACK LEG EXTENDED - Rear boot pushing back, slight forward lean
- Frame 2: NEUTRAL - Both legs together, upright noble stance
- Frame 3: FRONT LEG EXTENDED - Front boot forward, slight forward lean

NOTE: This sprite will be FLIPPED HORIZONTALLY for Walk Left

SECONDARY MOTION:
- Cape streams behind
- Weapon held at ready
- Light aura trails

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_right_strip.png`

---

## PROMPT #4 - Cast Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin holy magic smite - FACING CAMERA

ART STYLE: Funko Pop/Chibi, divine light effects

?? 3-FRAME CAST CYCLE:
- Frame 1: CHARGE - Raising weapon to sky, light gathering above, eyes closing
- Frame 2: CHANNEL - Eyes open glowing bright, divine light pouring down, halo intensifying
- Frame 3: RELEASE - Weapon thrust forward, massive beam of holy light, blinding flash

EFFECTS:
- Frame 1: Light gathering above
- Frame 2: Divine rays, glowing eyes, maximum energy
- Frame 3: Holy explosion, bright beam

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_cast_strip.png`

---

## PROMPT #5 - Death Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, light fading

?? 3-FRAME DEATH SEQUENCE:
- Frame 1: HIT - Recoiling, shocked, halo flickering, armor dented
- Frame 2: COLLAPSE - Falling to knees, aura fading, weapon loosening
- Frame 3: FALLEN - On ground, light gone, desaturated, 80% opacity

EFFECTS:
- Frame 1: Light disrupted
- Frame 2: Aura fading, last glow
- Frame 3: No light, peaceful expression

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_death_strip.png`

---

## PROMPT #6 - Hit Animation (3 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, damage flash effect

?? 3-FRAME HIT CYCLE:
- Frame 1: IMPACT - Flinching, armor clanking, red damage flash, aura disrupted
- Frame 2: RECOIL - Maximum flinch, light scattered, surprised expression
- Frame 3: RECOVERY - Standing firm, determined, aura restabilizing

EFFECTS:
- Frame 1: Red tint overlay, light scattered
- Frame 2: Peak damage pose
- Frame 3: Normal colors, righteous stance

OUTPUT: Horizontal strip 1500x500 (3 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_hit_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Tamaño Strip | Archivo |
|-----------|--------|--------------|---------|
| Walk Down | 3 | 1500x500 | `paladin_walk_down_strip.png` |
| Walk Up | 3 | 1500x500 | `paladin_walk_up_strip.png` |
| Walk Right | 3 | 1500x500 | `paladin_walk_right_strip.png` |
| Cast | 3 | 1500x500 | `paladin_cast_strip.png` |
| Death | 3 | 1500x500 | `paladin_death_strip.png` |
| Hit | 3 | 1500x500 | `paladin_hit_strip.png` |

**Total: 18 frames** (6 animaciones × 3 frames)

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/paladin/
??? walk/
?   ??? paladin_walk_down_1.png - paladin_walk_down_3.png
?   ??? paladin_walk_up_1.png - paladin_walk_up_3.png
?   ??? paladin_walk_right_1.png - paladin_walk_right_3.png
??? cast/
?   ??? paladin_cast_1.png - paladin_cast_3.png
??? death/
?   ??? paladin_death_1.png - paladin_death_3.png
??? hit/
    ??? paladin_hit_1.png - paladin_hit_3.png
```
