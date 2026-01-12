# ??? Prompts para Animaciones del SHADOW BLADE

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

## ?? NOTA ESPECIAL: ESTE PERSONAJE FLOTA

**El Shadow Blade es un asesino espectral que FLOTA en lugar de caminar.**

En lugar de animaciones de "walk", tiene animaciones de "float":
- No hay movimiento de piernas visibles
- Su capa/túnica cubre las piernas que parecen desvanecerse en sombras
- Se mueve deslizándose como un fantasma
- Pequeñas partículas de sombra se desprenden mientras se mueve

---

## ?? GUÍA DE ESTILO - SHADOW BLADE

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Ambiguo, andrógino |
| **Complexión** | Delgada, etérea, parcialmente incorpórea |
| **Cabello** | Largo y negro, fluyendo como humo |
| **Rostro** | Parcialmente oculto por capucha, solo ojos brillantes visibles |
| **Ojos** | Brillan en púrpura intenso |
| **Túnica** | Negra con bordes que se desvanecen en sombras |
| **Detalles** | Parte inferior del cuerpo se funde en niebla oscura, dagas flotantes |
| **Arma** | Daga sombría que brilla con energía oscura |

### Paleta de colores:
- **Túnica/Capa:** Negro profundo (#0D0D0D)
- **Sombras activas:** Púrpura oscuro (#2D1B4E)
- **Ojos/Brillo:** Púrpura neón (#9D00FF)
- **Partículas sombra:** Negro-púrpura (#1A0A28)
- **Daga energía:** Púrpura brillante (#7B00FF) a negro
- **Neblina inferior:** Gradiente negro a transparente
- **Outline:** Negro puro (#000000)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Shadow Blade - Spectral Assassin, Gender Ambiguous

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body)
- Only glowing purple eyes visible under hood
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Mysterious hooded figure
- Androgynous, neither clearly male nor female
- Hood covering most of face, only bright purple glowing eyes visible
- Long black cloak/robe that fades into shadow mist at the bottom
- NO VISIBLE LEGS - lower body dissolves into dark smoke/shadows
- Long flowing black hair like smoke emerging from hood
- Holds a shadowy dagger with purple energy glow
- Small shadow particles constantly falling off body
- Floats slightly above ground - NOT touching the floor

COLOR PALETTE:
- Cloak: Deep black (#0D0D0D)
- Active shadows: Dark purple (#2D1B4E)
- Eyes/Glow: Neon purple (#9D00FF)
- Shadow particles: Black-purple (#1A0A28)
- Dagger energy: Bright purple (#7B00FF) fading to black
- Lower mist: Black gradient to transparent
- Outline: Pure black (#000000)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `shadow_blade_reference.png`

---

## PROMPT #1 - Float Down (4 frames) - REEMPLAZA WALK

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade floating animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, thick outline, ghostly effects

CHARACTER: Spectral assassin, hooded with glowing purple eyes, black cloak fading to mist, NO LEGS VISIBLE

?? THIS CHARACTER FLOATS - NO WALKING ANIMATION:
- Frame 1: Floating neutral, slight hover, shadow mist calm
- Frame 2: Bobbing up slightly, mist spreading outward, shadow particles trailing left
- Frame 3: Peak of bob, mist compressed, particles rising
- Frame 4: Bobbing down, mist expanding, particles trailing right
- The character should have a smooth ghostly glide motion
- Lower body is always shadowy mist - NO FEET

SECONDARY MOTION:
- Cloak ripples like smoke in each frame
- Shadow particles constantly falling/floating
- Hair flows like black smoke
- Dagger glows with pulsing purple energy

COLORS: Cloak #0D0D0D, Eyes #9D00FF, Mist #2D1B4E, Particles #1A0A28

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_float_down_strip.png`

---

## PROMPT #2 - Float Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade floating - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, thick outline, ghostly

CHARACTER (from behind): Hooded spectral figure, black cloak, lower body is shadow mist

FLOATING ANIMATION (BACK VIEW):
- Frame 1: Floating neutral, mist calm
- Frame 2: Slight bob up, mist trailing behind
- Frame 3: Peak bob, shadow particles dispersing
- Frame 4: Bob down, mist settling
- GHOSTLY GLIDE - no leg motion, just hovering movement

SECONDARY MOTION:
- Cloak billows showing back
- Shadow trail behind the figure
- Hood slightly visible from behind

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_float_up_strip.png`

---

## PROMPT #3 - Float Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade floating - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, ghostly silhouette

CHARACTER (left profile): Hooded figure, cloak trailing, dagger visible, shadow mist below

FLOATING ANIMATION (SIDE VIEW):
- Frame 1: Floating neutral, side profile
- Frame 2: Gliding forward, leaning slightly into movement, mist trailing behind
- Frame 3: Mid-glide, shadow particles streaming behind
- Frame 4: Settling, mist catching up
- SMOOTH GHOSTLY GLIDE - no steps, ethereal movement

SECONDARY MOTION:
- Cloak streams behind like smoke
- Dagger in leading hand
- Shadow particles trail in opposite direction of movement

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_float_left_strip.png`

---

## PROMPT #4 - Float Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade floating - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, ghostly silhouette

CHARACTER (right profile): Hooded figure, dagger held ready, shadow mist below

FLOATING ANIMATION (SIDE VIEW):
- Frame 1: Floating neutral
- Frame 2: Gliding, leaning into movement
- Frame 3: Mid-glide, particles trailing
- Frame 4: Settling back
- ETHEREAL GLIDE - no walking, spectral movement

SECONDARY MOTION:
- Cloak flows opposite to movement
- Dagger glows in hand
- Shadow mist trails behind

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_float_right_strip.png`

---

## PROMPT #5 - Cast/Attack Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade dagger attack - FACING CAMERA

ART STYLE: Funko Pop/Chibi, intense shadow effects

ANIMATION SEQUENCE:
- Frame 1: PREPARE - Dagger raised, shadows gathering around blade, eyes intensify
- Frame 2: CHARGE - Arm pulled back, shadow energy spiraling around dagger, multiple shadow daggers appearing
- Frame 3: STRIKE - Thrusting forward, shadow daggers launching, dark purple energy blast
- Frame 4: RECOVERY - Returning to stance, shadow daggers fading, residual dark energy

EFFECTS:
- Frame 1: Purple glow intensifying on dagger
- Frame 2: Shadow energy vortex, multiple spectral daggers forming
- Frame 3: Motion blur, dark energy explosion, daggers flying
- Frame 4: Wisps of shadow dissipating

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_cast_strip.png`

---

## PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, dissolving into shadows

ANIMATION SEQUENCE:
- Frame 1: HIT - Recoiling, form destabilizing, shadows scattering
- Frame 2: DESTABILIZE - Body becoming more transparent, edges fraying into shadow particles
- Frame 3: DISSOLVE - Form breaking apart, becoming mostly shadow mist
- Frame 4: VANISH - Almost completely dissolved, only faint outline and floating dagger remain

EFFECTS:
- Frame 1: Flash of light disrupting shadow form
- Frame 2: Body pixelating/dissolving at edges
- Frame 3: 50% opacity, form breaking into particles
- Frame 4: 20% opacity, scattered shadow wisps, dagger falling

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_death_strip.png`

---

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, shadow disruption

ANIMATION:
- Frame 1: IMPACT - Form destabilizes, flickers like static, shadows scatter, eyes flare bright
- Frame 2: RECOVERY - Reforming, shadows pulling back together, determined glowing eyes

EFFECTS:
- Frame 1: White/purple flash, form becoming semi-transparent, particles exploding outward
- Frame 2: Shadows reconverging, solid form returning

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Shadow Blade idle/hover - FACING CAMERA

ART STYLE: Funko Pop/Chibi, subtle hovering

ANIMATION:
- Frame 1: Floating slightly higher, shadows rising, eyes glowing steadily
- Frame 2: Floating slightly lower, shadows settling, eyes pulsing

EFFECTS:
- Constant shadow particles falling from form
- Mist at bottom gently swirling
- Dagger pulsing with dark energy

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `shadow_blade_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Float Down | 4 | `shadow_blade_float_down_1.png` - `shadow_blade_float_down_4.png` |
| Float Up | 4 | `shadow_blade_float_up_1.png` - `shadow_blade_float_up_4.png` |
| Float Left | 4 | `shadow_blade_float_left_1.png` - `shadow_blade_float_left_4.png` |
| Float Right | 4 | `shadow_blade_float_right_1.png` - `shadow_blade_float_right_4.png` |
| Cast | 4 | `shadow_blade_cast_1.png` - `shadow_blade_cast_4.png` |
| Death | 4 | `shadow_blade_death_1.png` - `shadow_blade_death_4.png` |
| Hit | 2 | `shadow_blade_hit_1.png` - `shadow_blade_hit_2.png` |
| Idle | 2 | `shadow_blade_idle_1.png` - `shadow_blade_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/shadow_blade/
??? float/  ? En lugar de walk/
??? cast/
??? death/
??? hit/
```

---

## ?? NOTA DE IMPLEMENTACIÓN

En el código del juego, este personaje usará las animaciones "float" en lugar de "walk". El sistema de animación deberá mapear:
- `walk_down` ? `float_down`
- `walk_up` ? `float_up`
- `walk_left` ? `float_left`
- `walk_right` ? `float_right`
