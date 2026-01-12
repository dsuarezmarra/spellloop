# ?? Prompts para Animaciones del GEOMANCER

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

**MUY IMPORTANTE:** El Geomancer es EL PERSONAJE MÁS LENTO pero más resistente.

Su animación de caminar debe reflejar esto:
1. **Pasos pesados y deliberados** - Movimiento lento pero poderoso
2. **Postura anclada** - Parece inamovible, conectado a la tierra
3. **Peso visible** - Cada paso parece hundir el suelo
4. **Menos amplitud** - Pasos cortos pero sólidos
5. **Transición clara pero lenta** - Los pies se mueven claramente pero con calma

---

## ?? GUÍA DE ESTILO - GEOMANCER

### Características del personaje:

| Característica | Descripción |
|----------------|-------------|
| **Género** | Hombre robusto, enano/semi-enano |
| **Complexión** | Muy corpulento, bajo y ancho, como una roca |
| **Cabello** | Corto, marrón rojizo, barba trenzada con gemas |
| **Expresión** | Estoico, imperturbable, ojos ámbar |
| **Vestimenta** | Armadura/túnica pesada de piedra y metal |
| **Detalles** | Cristales creciendo de los hombros, runas de tierra |
| **Arma** | Martillo/mazo de piedra o puños de roca |

### Paleta de colores:
- **Armadura:** Marrón piedra (#8B7355)
- **Sombras:** Marrón oscuro (#5D4037)
- **Cristales:** Ámbar (#FFB300) y topacio (#FF8F00)
- **Metal:** Bronce oxidado (#CD7F32)
- **Barba/Cabello:** Marrón rojizo (#A0522D)
- **Piel:** Bronceada oscura (#B8860B)
- **Runas:** Naranja tierra (#E65100)
- **Outline:** Marrón muy oscuro (#3E2723)

---

# ?? LISTA DE PROMPTS

---

## PROMPT #0 - Referencia de Estilo

```
Character reference sheet for a 2D top-down roguelike game.

CHARACTER: Geomancer - Stocky Dwarf-like Male, Earth Tank

ART STYLE (CRITICAL):
- Funko Pop / Chibi cartoon style
- Oversized head (~30% of body) - but also very wide
- Small stern amber eyes
- Thick dark outline (2-3px)
- Cel-shading with 2-3 shadow levels

DESIGN DETAILS:
- Short, stocky, incredibly wide dwarf-like man
- Built like a boulder - width almost equals height
- Short reddish-brown hair
- Long braided beard with small gems/crystals woven in
- Stern, unshakeable expression
- Amber eyes that glow faintly
- Heavy stone and metal armor covering most of body
- Crystals growing from shoulder pauldrons
- Earth runes carved into armor, glowing orange
- Massive stone hammer or rock fists
- Feet firmly planted, grounded stance

COLOR PALETTE:
- Armor: Stone brown (#8B7355) with dark shadows (#5D4037)
- Crystals: Amber (#FFB300) and topaz (#FF8F00)
- Metal: Oxidized bronze (#CD7F32)
- Beard/Hair: Reddish brown (#A0522D)
- Skin: Dark tan (#B8860B)
- Runes: Earth orange (#E65100)
- Outline: Very dark brown (#3E2723)

LAYOUT: 4 angles in 2x2 grid (front, back, left, right profile)
OUTPUT: 1024x1024, transparent background
```

?? **Guardar como:** `geomancer_reference.png`

---

## PROMPT #1 - Walk Down (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, heavy and grounded

CHARACTER: Stocky dwarf earth mage, braided beard, stone armor, crystals on shoulders

?? THIS IS THE SLOWEST CHARACTER - HEAVY DELIBERATE STEPS:
- Frame 1: PLANTED - Both feet firmly on ground, solid stance
- Frame 2: LEFT STEP - Left foot lifting slowly, short step forward, weight shifting
- Frame 3: WEIGHT TRANSFER - Left foot landing with impact, right preparing
- Frame 4: RIGHT STEP - Right foot forward, same slow deliberate motion
- SHOW HEAVY FOOTFALLS - each step looks like it could crack the ground
- Short stride length - he doesn't need to move fast
- Body barely tilts - extremely stable

SECONDARY MOTION:
- Crystals on shoulders glow with each step
- Beard sways minimally - too heavy
- Runes pulse with walking rhythm
- Small dust/pebbles kick up from footsteps
- Armor barely moves - too heavy and solid

COLORS: Armor #8B7355, Crystals #FFB300, Beard #A0522D, Runes #E65100

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_down_strip.png`

---

## PROMPT #2 - Walk Up (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - BACK TO CAMERA

ART STYLE: Funko Pop/Chibi, massive back

CHARACTER (from behind): Wide dwarf, massive back armor, braided beard tips visible

?? SLOW HEAVY WALKING (BACK VIEW):
- Frame 1: PLANTED - Solid stance
- Frame 2: LEFT STEP - Short, heavy step
- Frame 3: WEIGHT TRANSFER - Landing with weight
- Frame 4: RIGHT STEP - Completing slow cycle
- MINIMAL MOVEMENT - stability is key

SECONDARY MOTION:
- Back crystals glowing
- Wide shoulders barely moving
- Runes pulsing on back armor

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_up_strip.png`

---

## PROMPT #3 - Walk Left (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - LEFT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, wide profile

CHARACTER (left profile): Massive wide dwarf, stone hammer visible, heavy armor

?? SLOW WALKING (SIDE VIEW):
- Frame 1: PLANTED - Standing solid
- Frame 2: LIFT - One leg slowly lifting for short step
- Frame 3: FORWARD - Leg moving forward slowly
- Frame 4: LAND - Heavy foot placement, ground impact
- SHORT STRIDES - very little forward lean
- EACH STEP looks powerful but slow

SECONDARY MOTION:
- Hammer held steady (barely moves - too heavy)
- Beard swings slightly
- Dust from footfalls

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_left_strip.png`

---

## PROMPT #4 - Walk Right (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer walking - RIGHT SIDE PROFILE

ART STYLE: Funko Pop/Chibi, stocky profile

CHARACTER (right profile): Wide dwarf, armor, weapon

?? SLOW DELIBERATE WALKING (SIDE VIEW):
- Frame 1: PLANTED - Solid stance
- Frame 2: LIFT - Heavy leg lifting
- Frame 3: FORWARD - Moving slowly
- Frame 4: LAND - Heavy landing
- POWERFUL but UNHURRIED movement

SECONDARY MOTION:
- Everything moves minimally
- Ground impact effects

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_walk_right_strip.png`

---

## PROMPT #5 - Cast Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer earth magic attack - FACING CAMERA

ART STYLE: Funko Pop/Chibi, earthquake effects

ANIMATION SEQUENCE:
- Frame 1: CHARGE - Raising hammer/fists, crystals glowing intensely, ground cracking
- Frame 2: CHANNEL - Pulling earth energy upward, rocks floating around him, eyes blazing
- Frame 3: SLAM - Hammer/fists hitting ground, massive earth spike eruption, screen shake effect
- Frame 4: RECOVERY - Standing from slam, rocks settling, earth returning to calm

EFFECTS:
- Frame 1: Cracks forming on ground, orange glow from below
- Frame 2: Rocks and debris floating, energy swirling
- Frame 3: MASSIVE earth spikes erupting, explosion of rock and dust
- Frame 4: Debris falling, dust settling, satisfied expression

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_cast_strip.png`

---

## PROMPT #6 - Death Animation (4 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer death animation - FACING CAMERA

ART STYLE: Funko Pop/Chibi, crumbling stone

ANIMATION SEQUENCE:
- Frame 1: HIT - Finally staggered (takes a lot!), cracks appearing in armor, crystals flickering
- Frame 2: CRUMBLE - Armor pieces beginning to fall off, crystals dimming, runes fading
- Frame 3: COLLAPSE - Falling to knees (still upright momentarily), armor breaking apart
- Frame 4: FALLEN - Down but looking like a fallen monument, armor scattered, peaceful

EFFECTS:
- Frame 1: Impact on someone who usually never flinches
- Frame 2: Stone armor cracking, pieces falling
- Frame 3: More crumbling, light fading
- Frame 4: Stillness, scattered stone pieces, dim crystals

OUTPUT: Horizontal strip 2000x500 (4 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_death_strip.png`

---

## PROMPT #7 - Hit Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer taking damage - FACING CAMERA

ART STYLE: Funko Pop/Chibi, barely affected

ANIMATION:
- Frame 1: IMPACT - Barely flinches, small crack in armor, crystals flicker, annoyed expression
- Frame 2: RECOVERY - Immediately stable again, crack sealing, even more determined

EFFECTS:
- Frame 1: Minimal red flash (tough character), small armor crack
- Frame 2: Earth magic healing the crack, stoic return

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_hit_strip.png`

---

## PROMPT #8 - Idle Animation (2 frames)

```
2D game sprite sheet, horizontal strip format.

SUBJECT: Geomancer idle/breathing - FACING CAMERA

ART STYLE: Funko Pop/Chibi, immovable stance

ANIMATION:
- Frame 1: Standing like a statue, crystals glowing steadily, runes pulsing
- Frame 2: Identical but crystals pulse differently, subtle rune shift

EFFECTS:
- Barely any movement - he IS the mountain
- Only crystals and runes show life
- Occasional small pebble floating near feet
- Beard might shift slightly

OUTPUT: Horizontal strip 1000x500 (2 frames of 500x500), transparent background
```

?? **Guardar como:** `geomancer_idle_strip.png`

---

## ?? RESUMEN DE ARCHIVOS

| Animación | Frames | Archivos |
|-----------|--------|----------|
| Walk Down | 4 | `geomancer_walk_down_1.png` - `geomancer_walk_down_4.png` |
| Walk Up | 4 | `geomancer_walk_up_1.png` - `geomancer_walk_up_4.png` |
| Walk Left | 4 | `geomancer_walk_left_1.png` - `geomancer_walk_left_4.png` |
| Walk Right | 4 | `geomancer_walk_right_1.png` - `geomancer_walk_right_4.png` |
| Cast | 4 | `geomancer_cast_1.png` - `geomancer_cast_4.png` |
| Death | 4 | `geomancer_death_1.png` - `geomancer_death_4.png` |
| Hit | 2 | `geomancer_hit_1.png` - `geomancer_hit_2.png` |
| Idle | 2 | `geomancer_idle_1.png` - `geomancer_idle_2.png` |

**Total: 28 frames**

---

## ?? Estructura de Carpetas

```
project/assets/sprites/players/geomancer/
??? walk/
??? cast/
??? death/
??? hit/
```
