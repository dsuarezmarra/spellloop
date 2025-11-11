# 📚 GUÍA COMPLETA: CREACIÓN E IMPLEMENTACIÓN DE TEXTURAS DE BIOMAS

Esta guía documenta el proceso completo para crear, procesar e implementar texturas animadas de biomas en Spellloop.
Basado en el proceso exitoso utilizado para los biomas **Lava** y **Snow**.

---

## 📋 ÍNDICE

1. [Estructura de Archivos](#estructura-de-archivos)
2. [Proceso de Creación de Texturas](#proceso-de-creación-de-texturas)
3. [Procesamiento de Sprite Sheets](#procesamiento-de-sprite-sheets)
4. [Configuración en Godot](#configuración-en-godot)
5. [Pruebas y Verificación](#pruebas-y-verificación)
6. [Checklist Completo](#checklist-completo)

---

## 1. ESTRUCTURA DE ARCHIVOS

### 📁 Estructura de Directorios

```
project/assets/textures/biomes/
└── <NombreBioma>/          # Ej: ArcaneWastes, Lava, Snow
    ├── base/                # Frames de textura base (suelo)
    │   ├── 1.png            # Frame 1 (512×512px)
    │   ├── 2.png            # Frame 2
    │   ├── ...
    │   ├── 8.png            # Frame 8
    │   └── <bioma>_base_animated_sheet_f8_512.png  # ✅ OUTPUT
    │
    ├── decor/               # Frames de decoraciones
    │   ├── 01.png           # Decor 1 - Frame 1 (256×256px)
    │   ├── 02.png           # Decor 1 - Frame 2
    │   ├── ...
    │   ├── 08.png           # Decor 1 - Frame 8
    │   ├── 11.png           # Decor 2 - Frame 1
    │   ├── ...
    │   ├── 108.png          # Decor 11 - Frame 8
    │   ├── <bioma>_decor1_sheet_f8_256.png   # ✅ OUTPUT
    │   ├── <bioma>_decor2_sheet_f8_256.png   # ✅ OUTPUT
    │   ├── ...
    │   └── <bioma>_decor11_sheet_f8_256.png  # ✅ OUTPUT
    │
    └── originales/          # (Opcional) Backups de originales
```

### 📐 Especificaciones Técnicas

| Tipo | Dimensión Frame | Frames | Sheet Final | Padding |
|------|----------------|--------|-------------|---------|
| **Base** | 512×512px | 8 | ~4124×512px | 4px |
| **Decor** | 256×256px | 8 | ~2060×256px | 4px |

---

## 2. PROCESO DE CREACIÓN DE TEXTURAS

### 🎨 A. Generar Frames con IA (Gemini/DALL-E)

#### Texturas Base (Suelo)
- **Cantidad:** 8 frames
- **Tamaño:** 512×512px
- **Características:**
  - Seamless/tileable (conecta perfectamente en los bordes)
  - Estilo consistente con el bioma
  - Variación sutil entre frames para animación
  - Mantener patrones generales pero con movimiento

**Ejemplo de prompt:**
```
Create a seamless tileable texture for [biome type], 512×512px:
- Frame 1: [description]
- Include: [elements]
- Style: [aesthetic]
- Make it perfectly seamless/tileable
```

#### Decoraciones
- **Cantidad:** 11 decoraciones × 8 frames c/u = 88 frames
- **Tamaño:** 256×256px o mayor
- **Características:**
  - Fondo transparente (usar removebg.com si es necesario)
  - Cada decoración debe tener movimiento natural (flotante, pulsante, etc.)
  - Alineación al suelo (base del sprite)
  - Variaciones de tamaño y forma entre decoraciones

**Nomenclatura de frames:**
```
Decor 1:  01.png, 02.png, ..., 08.png
Decor 2:  11.png, 12.png, ..., 18.png
Decor 3:  21.png, 22.png, ..., 28.png
...
Decor 10: 91.png, 92.png, ..., 98.png
Decor 11: 101.png, 102.png, ..., 108.png
```

---

## 3. PROCESAMIENTO DE SPRITE SHEETS

### 🔧 Script de Procesamiento

**Ubicación:** `utils/process_<bioma>_textures.py`

**Ejemplo:** `utils/process_arcanewastes_textures.py`

### Ejecución

```bash
# Navegar al directorio raíz del proyecto
cd C:\Users\dsuarez1\git\spellloop

# Ejecutar script
python utils/process_<bioma>_textures.py project/assets/textures/biomes/<NombreBioma>
```

**Ejemplo:**
```bash
python utils/process_arcanewastes_textures.py project/assets/textures/biomes/ArcaneWastes
```

### ✅ Verificación del Proceso

El script debe:
1. ✅ Detectar 8 frames de base (1.png a 8.png)
2. ✅ Crear sprite sheet base: `<bioma>_base_animated_sheet_f8_512.png`
3. ✅ Detectar 11 grupos de decoraciones (88 frames totales)
4. ✅ Crear 11 sprite sheets de decor: `<bioma>_decor1_sheet_f8_256.png` ... `<bioma>_decor11_sheet_f8_256.png`

**Output esperado:**
```
🎨 PROCESADOR DE TEXTURAS DE ARCANEWASTES
======================================================================

PROCESANDO TEXTURA BASE DE ARCANEWASTES
======================================================================
Frames encontrados: 8
──────────────────────────────────────────────────────────────────────

  Frame 1: 512×512px ✓
  Frame 2: 512×512px ✓
  ...
  Frame 8: 512×512px ✓

✅ Creado: arcanewastes_base_animated_sheet_f8_512.png
   Dimensiones: 4124×512px
======================================================================

PROCESANDO DECORACIONES DE ARCANEWASTES
======================================================================

Grupos de decor encontrados: 11
──────────────────────────────────────────────────────────────────────

Processing Decor 1 (8 frames)
──────────────────────────────────────────────────────────────────────

  Frame 1: 256×256 → 256×256px ✓
  ...

✅ Creado: arcanewastes_decor1_sheet_f8_256.png
   Dimensiones: 2060×256px

... (repetir para decor 2-11)

======================================================================
✅ PROCESAMIENTO COMPLETADO
======================================================================

Textura base: ✓
Decoraciones: 11/11

======================================================================
```

---

## 4. CONFIGURACIÓN EN GODOT

### 📝 A. Configurar Importación de Texturas

Para **cada sprite sheet** generado:

1. Seleccionar archivo en Godot
2. Ir a pestaña **Import**
3. Configurar:
   ```
   Preset: 2D Pixel
   Compress > Mode: Lossless
   Mipmaps > Generate: false
   Filter: false (para pixel art) o true (para smooth)
   Repeat: Disabled
   ```
4. Click en **Reimport**

### 🎬 B. Crear Escena de Prueba

**Ubicación:** `project/assets/textures/biomes/<NombreBioma>/<Bioma>Test.tscn`

**Ejemplo:** `project/assets/textures/biomes/ArcaneWastes/ArcaneWastesTest.tscn`

**Estructura de la escena:**

```
ArcaneWastesTest (Node2D)
├── Camera2D
│   └── zoom: Vector2(0.5, 0.5)
│
├── BaseTexture (AnimatedSprite2D)
│   ├── sprite_frames: nuevo SpriteFrames
│   ├── animation: "default"
│   ├── speed_scale: 10
│   ├── playing: true
│   └── Frames: (importar sheet base)
│
├── Decor1 (AnimatedSprite2D)
│   ├── sprite_frames: nuevo SpriteFrames
│   ├── position: Vector2(200, -100)
│   ├── animation: "default"
│   ├── speed_scale: 10
│   └── playing: true
│
├── Decor2 (AnimatedSprite2D)
│   └── ... (repetir para cada decor)
│
└── ... (hasta Decor11)
```

### 🔄 C. Configurar AnimatedSprite2D

Para **cada AnimatedSprite2D**:

1. Crear nuevo **SpriteFrames**
2. En panel **SpriteFrames**:
   - Click en **Add Frames from Sprite Sheet**
   - Seleccionar el sprite sheet correspondiente
   - Configurar:
     ```
     Horizontal: 8
     Vertical: 1
     Size: 512×512 (base) o 256×256 (decor)
     Separation: 4px
     ```
   - Click **Add Frames**
3. Configurar propiedades:
   ```gdscript
   speed_scale = 10  # FPS de la animación
   playing = true
   ```

### 🎯 D. Configurar SpriteFrames en Código (Opcional)

**Script de prueba:**

```gdscript
extends Node2D

func _ready():
    # Configurar texturas base
    var base_sprite = $BaseTexture as AnimatedSprite2D
    setup_animated_sprite(base_sprite,
        "res://assets/textures/biomes/ArcaneWastes/base/arcanewastes_base_animated_sheet_f8_512.png",
        8, 1, Vector2(512, 512), 4)

    # Configurar decoraciones
    for i in range(1, 12):  # 1 a 11
        var decor_sprite = get_node("Decor%d" % i) as AnimatedSprite2D
        setup_animated_sprite(decor_sprite,
            "res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor%d_sheet_f8_256.png" % i,
            8, 1, Vector2(256, 256), 4)

func setup_animated_sprite(sprite: AnimatedSprite2D, sheet_path: String,
                          h_frames: int, v_frames: int, frame_size: Vector2, separation: int):
    var sprite_frames = SpriteFrames.new()
    var texture = load(sheet_path) as Texture2D

    sprite_frames.add_animation("default")

    for i in range(h_frames * v_frames):
        var atlas = AtlasTexture.new()
        atlas.atlas = texture

        var frame_x = i % h_frames
        var frame_y = i / h_frames

        atlas.region = Rect2(
            frame_x * (frame_size.x + separation),
            frame_y * (frame_size.y + separation),
            frame_size.x,
            frame_size.y
        )

        sprite_frames.add_frame("default", atlas)

    sprite.sprite_frames = sprite_frames
    sprite.animation = "default"
    sprite.speed_scale = 10
    sprite.play()
```

---

## 5. PRUEBAS Y VERIFICACIÓN

### ✅ A. Checklist de Pruebas Visuales

1. **Textura Base**
   - [ ] La animación es fluida (sin saltos)
   - [ ] Los bordes conectan perfectamente (seamless)
   - [ ] El color y estilo son consistentes
   - [ ] No hay artefactos visuales

2. **Decoraciones**
   - [ ] Todas las 11 decoraciones se animan correctamente
   - [ ] El movimiento es natural (flotación, pulsación, etc.)
   - [ ] Las decoraciones están alineadas al suelo
   - [ ] El fondo es completamente transparente
   - [ ] No hay desplazamiento no deseado entre frames

3. **Rendimiento**
   - [ ] FPS estable (60 FPS)
   - [ ] Sin lag al cargar múltiples decoraciones
   - [ ] Tamaño de archivos razonable (< 500KB por sheet)

### 🎮 B. Ejecutar Escena de Prueba

```bash
# Desde VS Code, ejecutar tarea
Ctrl+Shift+P → "Tasks: Run Task" → "Ejecutar Spellloop"

# O desde línea de comandos
Godot_v4.5-stable_win64.exe --path project assets/textures/biomes/ArcaneWastes/ArcaneWastesTest.tscn
```

### 📊 C. Verificar Output

**Logs esperados:**
```
[BaseTexture] Animando con 8 frames a 10 FPS
[Decor1] Animando con 8 frames a 10 FPS
...
[Decor11] Animando con 8 frames a 10 FPS
```

---

## 6. CHECKLIST COMPLETO

### 📋 Pre-Procesamiento

- [ ] **Frames de base creados** (8 frames, 512×512px, seamless)
- [ ] **Frames de decor creados** (88 frames totales: 11 decor × 8 frames)
- [ ] **Nomenclatura correcta** (1-8 para base, 01-08, 11-18, ..., 101-108 para decor)
- [ ] **Fondos de decor transparentes** (usar removebg.com si es necesario)
- [ ] **Archivos organizados** en `base/` y `decor/`

### 🔧 Procesamiento

- [ ] **Script de procesamiento creado** (`utils/process_<bioma>_textures.py`)
- [ ] **Script ejecutado correctamente**
- [ ] **Sprite sheet base generado** (`<bioma>_base_animated_sheet_f8_512.png`)
- [ ] **11 sprite sheets de decor generados** (`<bioma>_decor1-11_sheet_f8_256.png`)
- [ ] **Dimensiones verificadas** (base: ~4124×512px, decor: ~2060×256px)

### 🎮 Configuración en Godot

- [ ] **Texturas importadas** (Preset: 2D Pixel, Compress: Lossless)
- [ ] **Escena de prueba creada** (`<Bioma>Test.tscn`)
- [ ] **AnimatedSprite2D configurados** (base + 11 decor)
- [ ] **SpriteFrames creados** (8 frames horizontales, separation: 4px)
- [ ] **Propiedades configuradas** (speed_scale: 10, playing: true)

### ✅ Pruebas

- [ ] **Escena de prueba ejecutada**
- [ ] **Animaciones fluidas**
- [ ] **Sin artefactos visuales**
- [ ] **Rendimiento estable** (60 FPS)
- [ ] **Todas las decoraciones visibles y funcionando**

### 📦 Integración Final

- [ ] **Texturas añadidas al sistema de biomas** (BiomeChunkApplier.gd)
- [ ] **Configuración JSON actualizada** (biome_textures_config.json)
- [ ] **Pruebas en juego completo**
- [ ] **Commit y push a GitHub**

---

## 📌 NOTAS IMPORTANTES

### ⚠️ Errores Comunes y Soluciones

1. **Frames no seamless:**
   - Solución: Regenerar con prompt específico de "seamless tileable"

2. **Decoraciones con fondo:**
   - Solución: Usar [remove.bg](https://www.remove.bg/) o GIMP para limpiar fondo

3. **Desalineación de decoraciones:**
   - Solución: El script auto-alinea, pero verificar que base esté en la parte inferior

4. **Sprite sheets con dimensiones incorrectas:**
   - Solución: Verificar padding=4px y frame count correcto

5. **Animación con saltos:**
   - Solución: Verificar que todos los frames tengan dimensiones idénticas

### 💡 Tips de Optimización

- Usar **compresión lossless** para mantener calidad
- **No generar mipmaps** para texturas animadas
- Mantener **frames consistentes** en tamaño y estilo
- Usar **speed_scale entre 8-12** para animaciones naturales
- **Agrupar decoraciones similares** para reutilización

---

## 🔗 Referencias

### Scripts Útiles

- `utils/process_<bioma>_textures.py` - Script maestro de procesamiento
- `utils/combine_base_frames.py` - Procesar texturas base seamless
- `utils/combine_individual_frames.py` - Procesar decoraciones con alineación
- `utils/fix_spritesheet_smart.py` - Corregir sprite sheets problemáticos

### Documentación

- [Godot AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html)
- [Godot AtlasTexture](https://docs.godotengine.org/en/stable/classes/class_atlastexture.html)
- [Godot SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html)

### Recursos Externos

- [Remove.bg](https://www.remove.bg/) - Eliminar fondos automáticamente
- [GIMP](https://www.gimp.org/) - Editor de imágenes gratuito
- [Aseprite](https://www.aseprite.org/) - Editor especializado en pixel art/sprites

---

## 📝 PLANTILLA DE COMMIT

```
feat: Añadir texturas animadas de <NombreBioma>

✨ Nuevas texturas:
- Textura base animada (8 frames, 512×512px)
- 11 decoraciones animadas (8 frames c/u, 256×256px)
- Escena de prueba <Bioma>Test.tscn

🔧 Cambios técnicos:
- Sprite sheets procesados con utils/process_<bioma>_textures.py
- Configuración de AnimatedSprite2D completa
- Importación optimizada (Lossless, no mipmaps)

✅ Pruebas:
- Animaciones fluidas a 10 FPS
- Sin artefactos visuales
- Rendimiento estable (60 FPS)
```

---

## 🎉 ¡Proceso Completado!

Si has seguido todos los pasos, deberías tener:
- ✅ Texturas base animadas perfectamente seamless
- ✅ 11 decoraciones animadas con movimiento natural
- ✅ Escena de prueba funcional
- ✅ Todo integrado y optimizado para Godot

**¡Listo para crear el siguiente bioma! 🚀**
