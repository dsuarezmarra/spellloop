# 🎮 Plan de Rediseño UI - Menús de Loopialike

## 📋 Índice
1. [Estado de Bugs](#estado-de-bugs)
2. [Filosofía de Diseño](#filosofía-de-diseño)
3. [Tipografía](#tipografía)
4. [Prompts de Assets](#prompts-de-assets)
5. [Ranking Online](#ranking-online)
6. [Implementación por Fases](#implementación-por-fases)

---

## ✅ Estado de Bugs

### Arreglados
- [x] Emoji ⚙️ en botón OPCIONES → Quitado
- [x] Emoji 🎮 en botón JUGAR → Quitado  
- [x] Emoji 🚪 en botón SALIR → Quitado
- [x] Emoji 🐞 en botón DEBUG → Quitado
- [x] Icono roto en "Borrar Progreso" → Quitado
- [x] Errores de código en EnemyAttackSystem.gd → Arreglados
- [x] Renombrado de Spellloop → Loopialike → Completado

---

## 🎨 Filosofía de Diseño

### Identidad Visual de Loopialike
Loopialike es un roguelike mágico con:
- **Dualidad elemental**: Hielo (azul/cyan) vs Fuego (naranja/rojo)
- **10 clases de magos**: Frost Mage, Pyromancer, Storm Caller, etc.
- **4 bosses épicos**: Minotauro de Fuego, Conjurador Primigenio, Corazón del Vacío, Guardián de Runas
- **7 biomas**: Grassland, Forest, Snow, Desert, Lava, Death, ArcaneWastes

### Paleta de Colores Principal
| Color | Hex | Uso |
|-------|-----|-----|
| Azul Hielo | `#5DADE2` | Protagonista, magia de hielo |
| Naranja Fuego | `#E67E22` | Enemigos, fuego, peligro |
| Púrpura Arcano | `#8E44AD` | Magia arcana, misterio |
| Oro | `#F4D03F` | Destacados, victorias, UI premium |
| Negro Profundo | `#1A1A2E` | Fondos, sombras |
| Blanco Luminoso | `#ECF0F1` | Texto, acentos brillantes |

### Estilo Visual Único
- **Bordes con glow mágico** en lugar de bordes sólidos
- **Partículas flotantes** (runas, chispas) en todos los menús
- **Transiciones con efecto portal/magia**
- **Botones con efecto cristal/gema**
- **Tipografía fantasía pero legible**

---

## 📝 Tipografía

### Fuente Recomendada: "Cinzel Decorative" + "Quicksand"

**Cinzel Decorative** (para títulos):
- Estilo: Fantasía elegante con serifs decorativos
- Descarga: https://fonts.google.com/specimen/Cinzel+Decorative
- Licencia: Open Font License (libre para juegos)

**Quicksand** (para cuerpo/stats):
- Estilo: Sans-serif redondeada, muy legible
- Descarga: https://fonts.google.com/specimen/Quicksand
- Licencia: Open Font License

### Alternativas:
- **Enchanted Land** - Muy fantasía, estilo medieval
- **Pirata One** - Aventurera, con carácter
- **Almendra** - Elegante con toque mágico

---

## 🖼️ Prompts de Assets para ChatGPT/DALL-E

### ═══════════════════════════════════════════════════════════════
### ASSET 1: Logo Principal "Loopialike"
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `logo_loopialike.png`
**Tamaño**: 1024×512 pixels (ratio 2:1)
**Fondo**: Transparente (PNG con alpha)

**PROMPT**:
```
Create a fantasy video game logo for "LOOPIALIKE". 

Design requirements:
- The word "LOOP" should have ICE/FROST theme: crystalline blue letters (#5DADE2), with icicles hanging from letters, frost particles, cold mist effect
- The letters "IA" should have a subtle AI/tech glow effect (cyan/white) representing the AI-assisted creation
- The word "LIKE" should have FIRE theme: burning orange/red letters (#E67E22), with flames coming from the letters, ember particles, heat distortion
- All parts should connect seamlessly, creating a magical transition effect with sparks
- Style: Fantasy game logo, bold 3D letters with depth
- Add subtle magical runes floating around the logo
- Include a faint magical circle/spell circle behind the text (representing the "loop")
- The overall shape should fit in a horizontal banner format (2:1 ratio)
- Background: Completely transparent (for PNG export)
- Quality: High resolution, clean edges, game-ready

Art style reference: Similar quality to Hades, Dead Cells, or Slay the Spire logos - professional indie game quality.
```

### ═══════════════════════════════════════════════════════════════
### ASSET 2: Fondo Principal del Menú
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `main_menu_bg_new.png`
**Tamaño**: 1920×1080 pixels (16:9)
**Fondo**: Completo (sin transparencia)

**PROMPT**:
```
Create a dramatic fantasy video game main menu background for "Loopialike".

Scene composition:
- CENTER: A powerful old wizard with ice magic (Frost Mage) standing heroically on ancient stone ruins, wielding a glowing ice staff. He wears a light blue hooded robe, has a long white beard. He's casting a spell with blue ice crystals forming around him.

- LEFT SIDE: A magical portal with purple arcane energy, with shadowy enemies emerging (silhouettes of monsters)

- RIGHT SIDE: A massive Fire Minotaur boss (muscular humanoid bull with armor) wreathed in flames, wielding a burning battle axe, looking menacing

- BACKGROUND: A mystical arena that transitions from frozen ice mountains on the left to volcanic lava fields on the right, symbolizing the elemental conflict

- SKY: Dark purple with magical auroras, floating magical runes, and distant spell explosions

- LIGHTING: Dramatic lighting from both the ice (blue glow, left) and fire (orange glow, right) creating a central clash point

- ATMOSPHERE: Epic, magical, dangerous but exciting

Style requirements:
- Art style: Painterly digital illustration, similar to Hearthstone or Legends of Runeterra card art
- NOT pixel art - smooth, detailed painting style
- Dramatic composition with clear focal points
- Colors should be vibrant but with dark shadows for contrast
- Resolution: 1920x1080 (16:9 ratio)
- Should leave space in the center-right for UI menu buttons

Quality: AAA mobile game or high-end indie game quality.
```

### ═══════════════════════════════════════════════════════════════
### ASSET 3: Fondo Selección de Personaje
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `character_select_bg_new.png`
**Tamaño**: 1920×1080 pixels (16:9)

**PROMPT**:
```
Create a mystical hero selection chamber background for a fantasy video game.

Scene:
- Setting: An ancient circular stone arena/colosseum with magical properties
- CENTER: A raised stone pedestal/platform with glowing arcane symbols, where the selected hero will stand (leave this area relatively empty for character sprite overlay)
- AROUND: Stone archways with different elemental themes (fire arch, ice arch, nature arch, etc.) representing different hero classes
- FLOOR: Ancient stone tiles with embedded magical crystals that glow softly
- BACKGROUND: A cosmic void with stars and magical nebulae visible through the open-roof arena
- LIGHTING: Ethereal purple and gold magical light emanating from crystals and runes
- FLOATING ELEMENTS: Ancient books, scrolls, and magical orbs floating around the edges
- ATMOSPHERE: Mystical, ancient, powerful - like standing in a hall of legendary heroes

Style:
- Art style: Rich painterly digital illustration
- Color palette: Deep purples, cosmic blues, gold accents, with warm lighting on the central platform
- Should feel like a sacred place where champions are chosen
- Leave the center clear for character sprite overlay

Resolution: 1920x1080 pixels
```

### ═══════════════════════════════════════════════════════════════
### ASSET 4: Marco/Card para Slot de Partida
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `save_slot_card_frame.png`
**Tamaño**: 400×550 pixels (vertical card ratio)
**Fondo**: Transparente

**PROMPT**:
```
Create a fantasy game save slot card frame/border for a roguelike game.

Design:
- Shape: Vertical rectangle with ornate fantasy borders (like a tarot card or trading card)
- BORDER: Ornate gold and silver metallic frame with magical gemstones at corners
- CORNERS: Small glowing crystals (blue and orange) embedded in the metal
- TOP: A decorative crown or magical symbol at the top center
- EDGES: Subtle magical runes etched into the metal border
- CENTER: Completely empty/transparent (this is where save data will be displayed)
- BOTTOM: A decorative footer area for the "PLAY" button
- STYLE: Premium fantasy game card, like Hearthstone or MTG card border
- MATERIAL: Looks like enchanted metal with a slight glow
- Background: Transparent (PNG with alpha)

The frame should look expensive, magical, and premium - like holding an ancient artifact.

Size: 400x550 pixels
```

### ═══════════════════════════════════════════════════════════════
### ASSET 5: Botón Principal (JUGAR/PLAY)
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `btn_play_normal.png`
**Tamaño**: 400×80 pixels
**Fondo**: Transparente

**PROMPT**:
```
Create a fantasy game button for the main "PLAY" action in a video game menu.

Design:
- Shape: Horizontal pill/capsule shape with pointed ends (like a gem or crystal)
- MATERIAL: Looks like a glowing magical crystal/gem, translucent with inner glow
- COLOR: Golden amber core (#F4D03F) with orange edges (#E67E22), subtle inner light
- BORDER: Thin metallic gold frame around the crystal
- EFFECTS: Subtle magical sparkles/particles embedded in the crystal
- LIGHTING: Inner glow effect, looks like it's powered by magic
- TEXT AREA: Clear center area for text overlay
- Background: Transparent (PNG)

The button should look like pressing it activates powerful magic - inviting and exciting.

Size: 400x80 pixels
```

**Nombre archivo**: `btn_play_hover.png`
**Tamaño**: 400×80 pixels

**PROMPT**:
```
Create the HOVER/ACTIVE state of a fantasy game button.

Same as the normal button but:
- BRIGHTER: The inner glow is more intense
- MORE PARTICLES: Additional magical sparkles visible
- SLIGHT SCALE: Appears 5% larger (will be scaled in-game)
- GLOW: Strong outer glow effect (gold/orange aura around the button)
- The crystal looks like it's pulsing with energy, ready to be activated

Size: 400x80 pixels, transparent background
```

### ═══════════════════════════════════════════════════════════════
### ASSET 6: Botón Secundario (Opciones, Salir, etc.)
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `btn_secondary_normal.png`
**Tamaño**: 280×60 pixels
**Fondo**: Transparente

**PROMPT**:
```
Create a secondary fantasy game button for menu options.

Design:
- Shape: Rounded rectangle, more subtle than the main button
- MATERIAL: Dark translucent crystal with silver/blue tint
- COLOR: Deep blue-gray (#2C3E50) with silver edges, subtle blue inner glow
- BORDER: Thin silver metallic frame
- EFFECTS: Very subtle magical particles, understated elegance
- STYLE: Clearly secondary to the main button, but still magical
- Background: Transparent (PNG)

Should be elegant but not compete with the main action button.

Size: 280x60 pixels
```

### ═══════════════════════════════════════════════════════════════
### ASSET 7: Partículas de Ambiente (Runas Flotantes)
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `particle_rune_sheet.png`
**Tamaño**: 256×64 pixels (4 frames de 64×64)

**PROMPT**:
```
Create a sprite sheet of 4 different magical floating runes for a fantasy game.

Layout: 4 runes in a horizontal row, each 64x64 pixels

Rune designs:
1. FIRE RUNE: Orange/red glowing circular symbol with flame motif
2. ICE RUNE: Blue/cyan glowing angular symbol with frost/crystal motif  
3. ARCANE RUNE: Purple glowing complex magical circle symbol
4. VOID RUNE: Dark purple/black with subtle glow, mysterious symbol

Each rune should:
- Have a soft glow around it
- Look like it's made of pure magical energy
- Be simple enough to read at small sizes
- Have transparent background

Total size: 256x64 pixels (4 frames of 64x64 each)
```

### ═══════════════════════════════════════════════════════════════
### ASSET 8: Partículas de Magia (Sparkles)
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `particle_magic_sparkle.png`
**Tamaño**: 128×32 pixels (4 frames de 32×32)

**PROMPT**:
```
Create a sprite sheet of 4 magical sparkle/particle effects.

Layout: 4 sparkles in a row, each 32x32 pixels

Designs:
1. Small star-shaped sparkle (white/gold)
2. Soft circular glow (cyan/blue)
3. Diamond-shaped flash (orange/gold)
4. Cross-shaped twinkle (white with color halo)

Each should:
- Be a simple, bright particle effect
- Work well when animated/moving
- Have transparent background
- Be visible against dark backgrounds

Total: 128x32 pixels
```

### ═══════════════════════════════════════════════════════════════
### ASSET 9: Icono de Ranking/Leaderboard
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `icon_ranking.png`
**Tamaño**: 64×64 pixels
**Fondo**: Transparente

**PROMPT**:
```
Create a trophy/ranking icon for a fantasy video game leaderboard.

Design:
- A magical golden trophy cup with glowing effects
- Blue and orange magical flames coming from the top
- Stars or magical particles around it
- Fantasy/magical style, not realistic
- Should clearly represent "competition" and "achievement"
- Clean design visible at small sizes

Size: 64x64 pixels, transparent background
```

### ═══════════════════════════════════════════════════════════════
### ASSET 10: Marco para Stats del Personaje
### ═══════════════════════════════════════════════════════════════

**Nombre archivo**: `stats_panel_frame.png`
**Tamaño**: 500×400 pixels
**Fondo**: Transparente (solo el marco)

**PROMPT**:
```
Create a fantasy UI panel frame for displaying character stats in a game.

Design:
- Shape: Rectangular panel with ornate fantasy borders
- STYLE: Ancient parchment/scroll look combined with magical crystal inlays
- BORDER: Metallic bronze/gold frame with magical gems at corners
- TOP: A decorative header area for the character name
- CORNERS: Small glowing crystals (blue/purple)
- TEXTURE: Subtle parchment or leather texture for the background area
- OVERALL: Should look like an ancient magical tome page
- Background of the inner area: Semi-transparent dark (so game content shows through)

Size: 500x400 pixels
```

---

## 🏆 Sistema de Ranking Online Mensual

### Arquitectura Técnica

#### Integración con Steam
```
Steam Leaderboard API
├── Leaderboard Name: "monthly_score_YYYY_MM"
├── Sort Method: Descending (mayor puntuación primero)
├── Display Type: Numeric
└── Datos adicionales vía Steam User Stats
```

#### Datos a Almacenar por Entrada
```gdscript
class RankingEntry:
    var steam_id: int           # ID de Steam del jugador
    var steam_name: String      # Nombre de Steam
    var score: int              # Puntuación de la partida
    var timestamp: int          # Fecha/hora de la partida
    var build_data: Dictionary  # Build completa del jugador
        # - character_id: String
        # - weapons: Array[WeaponData]
        # - items: Array[ItemData]  
        # - stats: Dictionary (HP, DMG, SPD, etc.)
        # - time_survived: float
        # - enemies_killed: int
        # - level_reached: int
```

#### Flujo de UI
```
MainMenu
    └── [RANKING] botón
            └── RankingScreen
                    ├── Header: "RANKING GLOBAL - ENERO 2026"
                    ├── TabBar: [TOP 100] [MI POSICIÓN] [AMIGOS]
                    ├── Lista scrolleable:
                    │   ├── #1 - PlayerName - 1,234,567 pts [VER BUILD]
                    │   ├── #2 - PlayerName - 1,100,000 pts [VER BUILD]
                    │   └── ...
                    └── BuildPopup (modal):
                            ├── [STATS] [ARMAS] [OBJETOS] tabs
                            └── Muestra exactamente lo mismo que el pause menu
```

### Consideraciones de Implementación

1. **Steam SDK**: Necesitas integrar Steamworks
2. **GodotSteam**: Plugin recomendado para Godot
3. **Límite de datos**: Steam permite ~256 bytes extra por entrada
4. **Build serializada**: Comprimir JSON de la build
5. **Cache local**: Guardar último ranking visto para carga rápida
6. **Rate limiting**: No consultar Steam cada frame

---

## 📋 Implementación por Fases

### Fase 1: Assets Básicos (AHORA)
1. [ ] Descargar fuentes Cinzel + Quicksand
2. [ ] Generar logo con prompt #1
3. [ ] Generar fondo main menu con prompt #2
4. [ ] Generar botones con prompts #5-6

### Fase 2: Implementar MainMenu Nuevo
1. [ ] Importar fuentes a Godot
2. [ ] Crear theme global con nueva tipografía
3. [ ] Implementar nuevo layout de MainMenu
4. [ ] Añadir partículas de ambiente
5. [ ] Animaciones de entrada

### Fase 3: SaveSlotSelect Upgrade
1. [ ] Generar card frame con prompt #4
2. [ ] Rediseñar cards de slots
3. [ ] Añadir avatar del personaje usado
4. [ ] Animaciones hover mejoradas

### Fase 4: CharacterSelect Upgrade
1. [ ] Generar fondo con prompt #3
2. [ ] Stats con barras visuales
3. [ ] Generar stats panel con prompt #10
4. [ ] Efecto de aparición del personaje

### Fase 5: Ranking System (Steam)
1. [ ] Integrar GodotSteam
2. [ ] Crear sistema de leaderboards
3. [ ] UI de RankingScreen
4. [ ] BuildPopup con tabs
5. [ ] Testing con Steam

---

## 📁 Estructura de Archivos Final

```
assets/
└── ui/
    ├── fonts/
    │   ├── CinzelDecorative-Regular.ttf
    │   ├── CinzelDecorative-Bold.ttf
    │   └── Quicksand-Regular.ttf
    ├── backgrounds/
    │   ├── main_menu_bg_new.png
    │   └── character_select_bg_new.png
    ├── buttons/
    │   ├── btn_play_normal.png
    │   ├── btn_play_hover.png
    │   ├── btn_secondary_normal.png
    │   └── btn_secondary_hover.png
    ├── frames/
    │   ├── save_slot_card_frame.png
    │   └── stats_panel_frame.png
    ├── particles/
    │   ├── particle_rune_sheet.png
    │   └── particle_magic_sparkle.png
    ├── icons/
    │   └── icon_ranking.png
    └── logo/
        └── logo_loopialike.png
```

---

## ❓ Próximos Pasos

1. **Genera los assets** usando los prompts de arriba
2. **Colócalos** en las rutas indicadas en la estructura de archivos
3. **Avísame** cuando estén listos y procederé a implementar el nuevo diseño

¿Alguna duda sobre los prompts o necesitas que ajuste algo?

---

## 🔍 Análisis del Estado Actual

### Pantalla 1: MainMenu (Inicio)
| Elemento | Estado Actual | Problema |
|----------|---------------|----------|
| Fondo | Ilustración estática genérica | ✅ Bien, pero estática |
| Logo | Label de texto "LOOPIALIKE" | ✅ Actualizado |
| Botones | Cuadrados con emojis (🎮⚙️🚪) | ✅ Emojis quitados |
| Layout | VBox centrado | ⚠️ Básico, sin jerarquía visual |
| Animaciones | Ninguna | ❌ Estático, sin vida |

### Pantalla 2: SaveSlotSelect (Selección de Partida)
| Elemento | Estado Actual | Problema |
|----------|---------------|----------|
| Fondo | Mismo que MainMenu | ✅ Coherente |
| Cards | Estilo "carta arcana" púrpura | ⚠️ Decente pero genérico |
| Iconos | Mezcla de PNGs e iconos rotos | ❌ Iconos pequeños desalineados |
| Info Stats | Texto plano básico | ⚠️ Podría tener más polish |
| Botón Borrar | Tiene icono trash roto | ❌ Bug visual reportado |

### Pantalla 3: CharacterSelectScreen (Selección de Héroe)
| Elemento | Estado Actual | Problema |
|----------|---------------|----------|
| Fondo | Ilustración hall arcano | ✅ Muy bueno |
| Carousel | Funcional con flechas | ⚠️ Podría tener más feedback |
| Stats Panel | Texto con stats numéricas | ⚠️ Difícil de leer rápidamente |
| Personaje | Sprite animado grande | ✅ Bien |

---

## ❌ Problemas Identificados (Bugs Inmediatos)

### Bug 1: Icono fantasma en OPCIONES
- **Archivo**: `MainMenu.tscn` línea 91
- **Causa**: Emoji `⚙️` en el texto del botón
- **Fix**: Quitar emoji, usar icono TextureRect separado o ninguno

### Bug 2: Icono roto en "Borrar Progreso"
- **Archivo**: `SaveSlotSelect.gd` línea 437
- **Causa**: `delete_btn.icon = load("res://assets/icons/ui_delete_trash.png")` - archivo no existe o formato incorrecto
- **Fix**: Quitar `delete_btn.icon` o verificar que el PNG existe

---

## 🎨 Propuesta de Rediseño

### Filosofía de Diseño
El juego es un **roguelike mágico** estilo Vampire Survivors. La UI debería transmitir:
- **Magia y misterio** (runas, partículas, glows)
- **Dinamismo** (animaciones sutiles, transiciones)
- **Claridad** (fácil de leer, jerarquía clara)
- **Personalidad** (único, memorable)

### 🏠 MainMenu - Rediseño Propuesto

#### Opción A: "Portal Arcano" (Recomendado)
```
┌──────────────────────────────────────────────┐
│                                              │
│     [Logo Loopialike animado con partículas]  │
│              ✨ efecto shimmer ✨            │
│                                              │
│         ╔═══════════════════════╗            │
│         ║   ▶ NUEVA PARTIDA    ║  ← Botón   │
│         ╚═══════════════════════╝   principal│
│                                              │
│         ┌───────────────────────┐            │
│         │    CONTINUAR          │  ← Solo si │
│         └───────────────────────┘   hay save │
│                                              │
│         OPCIONES    CRÉDITOS    SALIR        │
│             ↑ Botones secundarios pequeños   │
│                                              │
│  [Personaje animado    [Enemigo animado      │
│   lado izquierdo]       lado derecho]        │
│                                              │
│  v1.0.0          [Partículas flotantes]      │
└──────────────────────────────────────────────┘
```

**Elementos clave:**
1. **Logo Animado**: Imagen PNG del logo con shader de shimmer/glow
2. **Botón Principal Grande**: "NUEVA PARTIDA" o "CONTINUAR" destacado
3. **Botones Secundarios**: En línea horizontal abajo, más pequeños
4. **Personajes Decorativos**: Wizard y enemigo del fondo pero MÁS GRANDES y animados
5. **Partículas Ambiente**: Runas flotantes, chispas mágicas
6. **Transiciones**: Fade in escalonado de elementos

#### Opción B: "Libro de Hechizos"
- Fondo simula un libro abierto
- Botones parecen páginas/marcadores
- Más minimalista pero temático

#### Opción C: "Pantalla Título Clásica"
- Estilo retro arcade
- Press Start parpadea
- Más simple pero funcional

### 📂 SaveSlotSelect - Rediseño Propuesto

#### Estilo: "Pergaminos de Aventura"
```
┌──────────────────────────────────────────────┐
│                                              │
│         ELIGE TU AVENTURA                    │
│         ~~~~~~~~~~~~~~~~                     │
│                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │ SLOT 1  │  │ SLOT 2  │  │ SLOT 3  │      │
│  │         │  │         │  │         │      │
│  │ [Avatar]│  │ [Avatar]│  │  ✨     │      │
│  │         │  │         │  │ NUEVO   │      │
│  │ ⚔️ Guerrero│ 🧙 Mago  │  │         │      │
│  │ Nivel 15│  │ Nivel 8 │  │         │      │
│  │ 2h 30m  │  │ 45m     │  │         │      │
│  │         │  │         │  │         │      │
│  │[CONTINUAR]│ [CONTINUAR]│ [CREAR]  │      │
│  │ borrar  │  │ borrar  │  │         │      │
│  └─────────┘  └─────────┘  └─────────┘      │
│                                              │
│              [← VOLVER con ESC]              │
└──────────────────────────────────────────────┘
```

**Mejoras:**
1. **Cards más grandes** con más información visual
2. **Avatar del personaje** usado en esa partida
3. **Estadísticas visuales**: barras de progreso, iconos
4. **Animación hover**: Card sube y brilla
5. **Confirmación para borrar**: Modal popup (no borrar accidental)
6. **Último personaje jugado** visible en el slot

### 🧙 CharacterSelectScreen - Rediseño Propuesto

#### Estilo: "Arena de Selección"
```
┌──────────────────────────────────────────────┐
│                                              │
│         ELIGE TU HÉROE                       │
│                                              │
│    [◀]     🧙 MAGO DE HIELO      [▶]        │
│            "El Congelado"                    │
│                                              │
│         ╔═════════════════════╗              │
│         ║                     ║              │
│         ║   [PERSONAJE        ║              │
│         ║    ANIMADO          ║              │
│         ║    EN PEDESTAL]     ║              │
│         ║                     ║              │
│         ╚═════════════════════╝              │
│                                              │
│  ┌────────────────────────────────────┐      │
│  │ HP: ████████░░ 100                 │      │
│  │ DMG: ██████░░░░ x1.0               │      │
│  │ SPD: ████████░░ 100                │      │
│  │                                    │      │
│  │ 🔮 Arma Inicial: Varita de Hielo   │      │
│  │ ❄️ Pasiva: Aura Gélida             │      │
│  └────────────────────────────────────┘      │
│                                              │
│  [SELECCIONAR]              [← VOLVER]       │
└──────────────────────────────────────────────┘
```

**Mejoras:**
1. **Stats con barras visuales**: No solo números
2. **Flechas de navegación grandes**: Más visibles
3. **Personaje en pedestal**: Con luz/spotlight
4. **Preview de habilidades**: Iconos de arma y pasiva
5. **Indicadores de bloqueo**: Personajes no desbloqueados con candado
6. **Animación de entrada**: Personaje "aparece" con efecto mágico

---

## ➕ Funcionalidades Adicionales Sugeridas

### Para MainMenu
| Funcionalidad | Prioridad | Descripción |
|---------------|-----------|-------------|
| Daily Challenge | Alta | Modo diario con seed fija |
| Bestiario | Media | Ver enemigos derrotados |
| Logros | Media | Sistema de achievements |
| Leaderboard Local | Baja | Top 10 mejores runs |
| Galería | Baja | Ver personajes/armas |
| Música Toggle | Media | ON/OFF rápido sin ir a opciones |

### Para SaveSlotSelect
| Funcionalidad | Prioridad | Descripción |
|---------------|-----------|-------------|
| Copiar Slot | Baja | Duplicar partida |
| Estadísticas Detalladas | Media | Ver kills, tiempo, etc |
| Import/Export | Baja | Backup de saves |
| Cloud Save | Baja | Sincronización (futuro) |

### Para CharacterSelect
| Funcionalidad | Prioridad | Descripción |
|---------------|-----------|-------------|
| Preview Arma | Alta | Ver cómo ataca el arma inicial |
| Skin Selector | Media | Cambiar apariencia |
| Lore/Historia | Baja | Descripción del personaje |
| Combos Sugeridos | Media | Sinergia con otras armas |
| Random | Media | Elegir personaje al azar |

---

## 📋 Plan de Acción

### Fase 0: Fixes Inmediatos (HOY)
- [ ] **Fix Bug 1**: Quitar emoji ⚙️ de botón OPCIONES
- [ ] **Fix Bug 2**: Quitar icono roto de "Borrar Progreso"

### Fase 1: Polish Básico (1-2 días)
- [ ] Crear logo PNG real de Loopialike (si no existe)
- [ ] Unificar estilo de botones (quitar todos los emojis)
- [ ] Añadir hover effects a todos los botones
- [ ] Añadir transiciones fade entre pantallas
- [ ] Verificar que todos los iconos cargan correctamente

### Fase 2: MainMenu Upgrade (2-3 días)
- [ ] Implementar layout nuevo con botón principal grande
- [ ] Añadir partículas de ambiente (runas flotantes)
- [ ] Shader shimmer para logo
- [ ] Botón "Continuar" que aparece solo si hay save
- [ ] Animación de entrada escalonada

### Fase 3: SaveSlotSelect Upgrade (2 días)
- [ ] Rediseñar cards con avatar del personaje
- [ ] Añadir barras de progreso visuales
- [ ] Modal de confirmación para borrar
- [ ] Animaciones de hover mejoradas

### Fase 4: CharacterSelect Upgrade (2-3 días)
- [ ] Stats con barras visuales
- [ ] Preview de arma inicial (icono grande)
- [ ] Indicadores de personajes bloqueados
- [ ] Botón Random
- [ ] Efecto de aparición del personaje

### Fase 5: Nuevas Funcionalidades (Opcional)
- [ ] Daily Challenge button
- [ ] Música toggle en MainMenu
- [ ] Galería básica

---

## 🖼️ Assets Necesarios

### Imágenes a Crear/Obtener
| Asset | Tamaño Sugerido | Prioridad |
|-------|-----------------|-----------|
| `logo_loopialike.png` | 512x256 | Alta |
| `btn_play_normal.png` | 400x80 | Media |
| `btn_play_hover.png` | 400x80 | Media |
| `btn_secondary.png` | 200x50 | Media |
| `icon_options.png` | 32x32 | Baja |
| `icon_credits.png` | 32x32 | Baja |
| `icon_exit.png` | 32x32 | Baja |
| `particle_rune_1.png` | 64x64 | Media |
| `particle_rune_2.png` | 64x64 | Media |
| `particle_sparkle.png` | 32x32 | Media |
| `slot_card_bg.png` | 300x400 | Media |
| `stat_bar_fill.png` | 200x20 | Media |
| `stat_bar_empty.png` | 200x20 | Media |

### Shaders a Crear
| Shader | Uso | Prioridad |
|--------|-----|-----------|
| `shimmer.gdshader` | Logo brillante | Media |
| `glow_pulse.gdshader` | Botones hover | Media |
| `vignette.gdshader` | Bordes oscuros | Baja |

---

## ❓ Preguntas para el Usuario

1. **Logo**: ¿Tenemos ya un logo PNG de Loopialike o hay que crearlo?
2. **Estilo Botones**: ¿Prefieres botones con iconos o solo texto?
3. **Fondo MainMenu**: ¿Te gusta el fondo actual o quieres cambiarlo?
4. **Personajes Decorativos**: ¿Quieres el wizard y minotauro animados en el menú?
5. **Daily Challenge**: ¿Interesa implementar modo diario?
6. **Prioridad**: ¿Qué pantalla quieres mejorar primero?

---

## 🎯 Recomendación Inmediata

**Empezar por:**
1. ✅ Fix bugs de iconos (5 minutos)
2. ✅ Quitar emojis de botones (5 minutos)
3. ✅ Añadir hover effects básicos (30 minutos)
4. 🔄 Diseñar layout nuevo de MainMenu

¿Procedemos con los fixes inmediatos mientras decides el rediseño completo?
