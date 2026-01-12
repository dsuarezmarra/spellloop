# ? Prompts para Animaciones del PALADIN

## ?? IMPORTANTE: Cómo usar este documento

**Las IAs de imágenes NO pueden generar todos los sprites de una vez.**

### Flujo de trabajo:
1. Ejecuta el **Prompt #0** primero para establecer el estilo
2. Luego ejecuta los prompts **#1 al #8** en orden
3. Guarda cada imagen con el nombre indicado

---

## ?? Especificaciones Técnicas

- **Tamaño:** 500x500 píxeles por frame
- **Formato:** PNG con fondo transparente
- **Estilo:** Cartoon/Funko Pop
- **Vista:** Top-down con ligera perspectiva 3/4

---

## ?? NOTA CRÍTICA SOBRE ANIMACIÓN DE CAMINAR

**MUY IMPORTANTE:** El Paladin es un guerrero sagrado con armadura.

Su animación debe reflejar:
1. **Pasos firmes y dignos** - Camina con propósito, ni muy rápido ni muy lento
2. **Postura erguida** - Siempre recto, orgulloso
3. **Peso de armadura** - Se nota que lleva armadura pero no le impide moverse
4. **Gracia marcial** - Movimiento entrenado de guerrero santo
5. **Los pies deben verse claramente** - Pasos definidos bajo la capa

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
- White and gold plate armor (stylized, not realistic)
- Flowing white cape with golden trim
- Subtle halo or light aura above/behind head
- Holy symbols engraved on armor (sun, star patterns)
- Glowing sword of light OR sacred scepter as weapon
- Boots visible under short battle skirt/tabard

COLOR PALETTE:
- Armor: Silver white (#F5F5F5)
- Gold details: Bright gold (#FFD700)
- Cape: Pure white (#FFFFFF) with gold edges
- Light/Aura: Soft yellow (#FFFACD) to white
- Hair: Golden blonde (#DAA520)
- Skin: Light tan (#DEB887)
- Eyes: Bright sky blue (#87CEEB)
- Outline: Dark gold (#B8860B)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `paladin_reference.png`

---

## PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, holy warrior, glowing effects

CHARACTER: Noble paladin, gold/white armor, white cape, blonde hair, light aura

?? CRITICAL WALKING ANIMATION REQUIREMENTS:
- Frame 1: ATTENTION - Standing tall, feet together, cape resting
- Frame 2: LEFT STEP - Left armored boot forward, cape beginning to flow, dignified stride
- Frame 3: PASSING - Feet crossing mid-stride, cape billowing, steady pace
- Frame 4: RIGHT STEP - Right boot forward, completing noble walk cycle
- SHOW ARMORED BOOTS clearly stepping - he's a warrior, not floating
- Posture always upright and proud
- Military/knightly walking rhythm

SECONDARY MOTION:
- Cape flows gracefully with each step
- Subtle light aura pulses with movement
- Holy symbols on armor glow faintly
- Sword/scepter held steadily at side
- Hair barely moves (short and orderly)

COLORS: Armor #F5F5F5, Gold #FFD700, Cape #FFFFFF, Hair #DAA520, Aura #FFFACD

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, cape prominently visible

CHARACTER (from behind): White/gold armored warrior, flowing white cape, blonde hair

?? CRITICAL WALKING ANIMATION:
- Frame 1: ATTENTION - Standing tall from behind
- Frame 2: LEFT STEP - Left leg forward (boot visible), cape parting
- Frame 3: PASSING - Mid-stride, cape flowing to side
- Frame 4: RIGHT STEP - Right leg forward, cape settling
- ARMORED BOOTS visible with each step

SECONDARY MOTION:
- Cape dramatically billows showing back
- Halo visible from behind as soft glow
- Armor gleams with holy light

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_up_strip.png`

---

## PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, noble profile

CHARACTER (left profile): Armored paladin, cape trailing, weapon visible

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: STANDING - Upright profile
- Frame 2: BACK LEG PUSH - Rear armored boot pushing off, front reaching
- Frame 3: MID-STRIDE - Legs crossing, cape flowing behind
- Frame 4: FRONT LAND - Front boot landing firmly
- SHOW CLEAR LEG MOVEMENT - armored legs visible under tabard

SECONDARY MOTION:
- Cape streams behind
- Weapon held at ready
- Light aura trails slightly

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_left_strip.png`

---

## PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin walking - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, heroic profile

CHARACTER (right profile): Armored warrior, cape, weapon

?? CRITICAL WALKING ANIMATION (SIDE VIEW):
- Frame 1: STANDING - Noble stance
- Frame 2: BACK LEG PUSH - Beginning stride
- Frame 3: MID-STRIDE - Legs in motion
- Frame 4: FRONT LAND - Completing step
- VISIBLE ARMORED FOOTSTEPS

SECONDARY MOTION:
- Cape flows opposite to movement
- Light radiating subtly

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_walk_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin holy magic smite - FACING CAMERA

ART STYLE: Funko Pop/Chibi, divine light effects

ANIMATION SEQUENCE:
- Frame 1: PRAY - Raising weapon to sky, closing eyes, light gathering above
- Frame 2: CHANNEL - Eyes open glowing bright, divine light pouring down, halo intensifying
- Frame 3: SMITE - Weapon thrust forward/down, massive beam of holy light, blinding flash
- Frame 4: RECOVERY - Lowering weapon, light fading to sparkles, righteous expression

EFFECTS:
- Frame 1: Light particles gathering, soft glow building
- Frame 2: Intense golden-white light, divine circle appearing
- Frame 3: EXPLOSIVE holy beam, screen filled with light, cross/star patterns
- Frame 4: Gentle sparkles falling, afterglow, holy satisfaction

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_cast_strip.png`

---

## PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, light fading

ANIMATION SEQUENCE:
- Frame 1: HIT - Staggering but still fighting, light flickering, surprised expression
- Frame 2: FALTER - Dropping to one knee, weapon lowering, light dimming, accepting fate
- Frame 3: COLLAPSE - Falling forward, cape spreading, light nearly gone
- Frame 4: FALLEN - Lying peacefully, cape spread like wings, faint holy glow remaining, at peace

EFFECTS:
- Frame 1: Light disrupted, armor flash
- Frame 2: Divine light weakening, halo fading
- Frame 3: Last light leaving
- Frame 4: Soft afterglow, peaceful death, slight transparency

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_death_strip.png`

---

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, holy resistance

ANIMATION:
- Frame 1: IMPACT - Bracing against hit, holy shield shimmer, light flaring defensively
- Frame 2: RECOVERY - Standing firm, shield fading, even more determined expression

EFFECTS:
- Frame 1: Golden shield flash blocking some damage, red minimal, light protecting
- Frame 2: Shield dissipating, holy aura restabilizing, ready to continue

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Paladin idle/standing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, noble presence

ANIMATION:
- Frame 1: Standing at attention, light aura steady, cape resting, serene vigilance
- Frame 2: Subtle shift, aura pulsing slightly, cape moving from unseen breeze

EFFECTS:
- Constant soft holy glow
- Halo gently pulsing
- Cape slight movement
- Eyes watching, protective stance

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `paladin_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `paladin_walk_down_1.png` - `paladin_walk_down_4.png` |
| Walk Up | 4 | `paladin_walk_up_1.png` - `paladin_walk_up_4.png` |
| Walk Left | 4 | `paladin_walk_left_1.png` - `paladin_walk_left_4.png` |
| Walk Right | 4 | `paladin_walk_right_1.png` - `paladin_walk_right_4.png` |
| Cast | 4 | `paladin_cast_1.png` - `paladin_cast_4.png` |
| Death | 4 | `paladin_death_1.png` - `paladin_death_4.png` |
| Hit | 2 | `paladin_hit_1.png` - `paladin_hit_2.png` |
| Idle | 2 | `paladin_idle_1.png` - `paladin_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/paladin/
??? walk/
??? cast/
??? death/
??? hit/
```
