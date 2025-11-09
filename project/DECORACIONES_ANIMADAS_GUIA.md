# 🎨 SISTEMA DE DECORACIONES ANIMADAS - GUÍA DE INTEGRACIÓN

**Fecha:** 9 de noviembre de 2025  
**Estado:** ✅ Listo para integrar assets  
**Sistema:** Sprite sheets horizontales (estilo Brotato)

---

## 📁 ESTRUCTURA DE CARPETAS (Nueva)

```
project/assets/textures/biomes/
├── Lava/
│   ├── base/
│   │   ├── lava_base_a_256.png          # Seamless tile A
│   │   └── lava_base_b_256.png          # Seamless tile B (variante)
│   └── decor/
│       ├── lava_spout_sheet_f8_256.png  # ANIMADO: 8 frames
│       ├── lava_crack_static_a.png      # ESTÁTICO: variante A
│       ├── lava_rock_static_b.png       # ESTÁTICO: variante B
│       └── lava_ember_static_c.png      # ESTÁTICO: variante C
├── Snow/
│   ├── base/
│   │   ├── snow_base_a_256.png
│   │   └── snow_base_b_256.png
│   └── decor/
│       ├── snow_crystal_sheet_f6_256.png  # ANIMADO: 6 frames brillando
│       ├── snow_mound_static_a.png
│       ├── snow_rock_static_b.png
│       └── snow_tree_static_c.png
├── Desert/
│   └── ... (igual estructura)
├── Grassland/
│   └── ... (igual estructura)
├── Forest/
│   └── ... (igual estructura)
└── ArcaneWastes/
    └── ... (igual estructura)
```

---

## 🎯 ESPECIFICACIONES TÉCNICAS

### **Tiles Base (seamless):**
- **Resolución:** 256×256 px
- **Formato:** PNG
- **Variantes:** A y B por bioma (para alternar y romper patrón)
- **Seamless:** SÍ (deben repetirse sin costuras visibles)
- **Nombrado:** `{bioma}_base_{a|b}_256.png`

### **Decoraciones Animadas (spritesheets):**
- **Layout:** Horizontal strip (frames en fila)
- **Frames:** 4-8 frames por animación
- **Padding:** 4 px entre frames
- **Tamaño por frame:** 256×256 px (o el indicado en nombre)
- **FPS:** 10 FPS (configurable)
- **Pivot:** Bottom-center (pintado en la textura)
- **Nombrado:** `{bioma}_{nombre}_sheet_f{frames}_{size}.png`
- **Ejemplos:**
  - `lava_spout_sheet_f8_256.png` → 8 frames de 256×256 px
  - `snow_crystal_sheet_f6_256.png` → 6 frames de 256×256 px

### **Decoraciones Estáticas:**
- **Resolución:** 256×256 px (u otro tamaño)
- **Variantes:** a, b, c (para variedad)
- **Pivot:** Bottom-center
- **Nombrado:** `{bioma}_{nombre}_static_{variant}.png`
- **Ejemplos:**
  - `lava_rock_static_a.png`
  - `snow_mound_static_b.png`

---

## 🔧 CONVENCIONES DE NOMBRES (CRÍTICO)

El sistema detecta automáticamente el tipo por el nombre del archivo:

### **ANIMADOS (spritesheets):**
```
{biome}_decor{N}_sheet_f{frames}_{size}.png
         ↑           ↑      ↑        ↑
      número    indicador frames  tamaño
```

**Ejemplos válidos:**
- ✅ `lava_decor1_sheet_f8_256.png`
- ✅ `snow_decor2_sheet_f6_256.png`
- ✅ `desert_decor3_sheet_f4_256.png`

**Ejemplos inválidos:**
- ❌ `lava_spout_8frames.png` (no sigue patrón)
- ❌ `snow_anim.png` (falta _sheet_fN_)

### **ESTÁTICOS:**
```
{biome}_decor{N}_static_{variant}.png
         ↑              ↑
      número        variante
```

**Ejemplos válidos:**
- ✅ `lava_decor1_static_a.png`
- ✅ `snow_decor2_static_b.png`
- ✅ `forest_decor3_static_c.png`

### **FALLBACK (formato antiguo, aún soportado):**
```
decor{N}.png  (en carpeta assets/textures/biomes/{Biome}/)
```
- ✅ `decor1.png`
- ✅ `decor2.png`

---

## 🎨 CONFIGURACIÓN DE IMPORT EN GODOT

### **Para Tiles Base (seamless):**

1. Seleccionar archivo PNG en FileSystem
2. Click derecho → "Edit Import..."
3. **Configurar:**
   ```
   Compress Mode: VRAM Compressed
   Repeat: Enabled          ← IMPORTANTE (para seamless)
   Filter: Enabled
   Mipmaps: Enabled
   sRGB: On
   Fix Alpha Border: On
   ```

### **Para Decoraciones (animadas/estáticas):**

1. Seleccionar archivo PNG en FileSystem
2. Click derecho → "Edit Import..."
3. **Configurar:**
   ```
   Compress Mode: VRAM Compressed
   Repeat: Disabled         ← IMPORTANTE (no queremos repeat)
   Filter: Enabled
   Mipmaps: Enabled
   sRGB: On
   Fix Alpha Border: On
   ```

### **Aplicar a múltiples archivos:**

Seleccionar múltiples PNGs → Edit Import → Set as Default → Reimport

---

## 🚀 CÓMO FUNCIONA EL SISTEMA

### **1. AutoFrames.gd (Utilidad de carga)**

```gdscript
# Detecta automáticamente frames de un spritesheet
var frames = AutoFrames.from_sheet("lava_spout_sheet_f8_256.png", 10.0)
# Retorna SpriteFrames con animación "default" lista
```

**Características:**
- ✅ Lee automáticamente el número de frames del nombre
- ✅ Aplica padding de 4 px entre frames
- ✅ Configura FPS (default 10.0)
- ✅ Valida dimensiones esperadas

### **2. DecorFactory.gd (Fabricador de nodos)**

```gdscript
# Crea automáticamente Sprite2D o AnimatedSprite2D
var decor = DecorFactory.make_decor("lava_spout_sheet_f8_256.png")
# Retorna AnimatedSprite2D si es spritesheet
# Retorna Sprite2D si es estático
```

**Características:**
- ✅ Detecta tipo por nombre de archivo
- ✅ Pivot bottom-center automático
- ✅ Animaciones desincronizadas (frame inicial aleatorio)
- ✅ Speed variado (0.9-1.1x) para naturalidad

### **3. BiomeChunkApplierOrganic.gd (Integración)**

```gdscript
# Se integra automáticamente en el sistema de biomas
func _create_random_biome_decor_node(biome_type, rng) -> Node2D:
    # Busca decoraciones disponibles (animadas y estáticas)
    # Selecciona una aleatoriamente
    # Crea nodo con DecorFactory
    # Retorna listo para añadir a la escena
```

**Características:**
- ✅ Busca primero spritesheets animados
- ✅ Luego busca estáticos con variantes
- ✅ Fallback a formato antiguo (decorN.png)
- ✅ Escala aleatoria (100-250 px)
- ✅ Modulación de color sutil
- ✅ Z-index correcto (-96 normal, -95 bordes)

---

## 📊 EJEMPLO COMPLETO: BIOMA LAVA

### **Archivos necesarios:**

```
project/assets/textures/biomes/Lava/
├── base/
│   ├── lava_base_a_256.png          [256×256, seamless]
│   └── lava_base_b_256.png          [256×256, seamless]
└── decor/
    ├── lava_spout_sheet_f8_256.png  [2084×256, 8 frames + padding]
    ├── lava_crack_static_a.png      [256×256]
    ├── lava_rock_static_b.png       [256×256]
    └── lava_ember_static_c.png      [256×256]
```

### **Cálculo del ancho del spritesheet:**

Para `lava_spout_sheet_f8_256.png` con 8 frames:
- Frames: 8
- Tamaño por frame: 256 px
- Padding entre frames: 4 px
- **Ancho total:** (256 × 8) + (4 × 7) = 2048 + 28 = **2076 px**
- Último frame puede no llevar padding → **2048-2076 px** (flexible)

**Layout visual:**
```
[Frame1][4px][Frame2][4px][Frame3][4px][Frame4][4px][Frame5][4px][Frame6][4px][Frame7][4px][Frame8]
  256px   4px   256px   4px   256px   4px   256px   4px   256px   4px   256px   4px   256px   4px   256px
```

---

## 🧪 TESTING

### **1. Verificar carga de spritesheets:**

En consola deberías ver:
```
[AutoFrames] ✅ Cargado: lava_spout_sheet_f8_256.png (8 frames @ 10 FPS)
```

### **2. Verificar creación de decoraciones:**

En scene tree deberías ver nodos como:
- `BiomeDecor_0` (AnimatedSprite2D o Sprite2D)
- `BiomeDecor_1` (AnimatedSprite2D o Sprite2D)
- `BorderDecor_12_15_0` (decoraciones en bordes)

### **3. Verificar animaciones:**

Si es AnimatedSprite2D:
- Debería reproducir automáticamente
- Cada instancia en frame diferente (desincronizado)
- Speed ligeramente variado

---

## ⚠️ TROUBLESHOOTING

### **"No se encontraron decoraciones para {Bioma}"**

**Causa:** No hay archivos en `assets/textures/biomes/{Bioma}/decor/`

**Solución:**
1. Crear carpeta `decor/` si no existe
2. Añadir al menos 1 decoración (animada o estática)
3. Verificar nombrado según convención

### **"Nombre no sigue la convención *_sheet_fN_SIZE.png"**

**Causa:** Spritesheet mal nombrado

**Solución:**
Renombrar archivo:
- ❌ `lava_anim.png`
- ✅ `lava_spout_sheet_f8_256.png`

### **"Dimensiones no coinciden"**

**Causa:** Ancho del spritesheet no es correcto

**Solución:**
Para 8 frames de 256 px con padding 4 px:
- Ancho esperado: ~2076 px
- Verificar en editor de imágenes (Photoshop/GIMP/Aseprite)

### **Animaciones no se reproducen**

**Causa:** Import settings incorrectos

**Solución:**
1. Seleccionar PNG → Edit Import
2. Verificar: `Repeat: Disabled`, `Filter: Enabled`
3. Reimportar (Reimport button)

---

## 🎯 PRIORIDAD DE IMPLEMENTACIÓN

Según ChatGPT, el orden recomendado es:

1. **Lava** (primer pack)
2. **Snow**
3. **Grassland**
4. **Forest**
5. **ArcaneWastes**
6. **Desert**

**Razón:** Lava y Snow son los más visuales y llamativos.

---

## 📝 CHECKLIST DE INTEGRACIÓN

### **Por cada bioma:**

- [ ] Crear carpeta `base/`
- [ ] Crear 2 tiles seamless: `{bioma}_base_a_256.png` y `_b_256.png`
- [ ] Configurar import (Repeat: Enabled)
- [ ] Crear carpeta `decor/`
- [ ] Crear 1 decoración animada: `{bioma}_decor1_sheet_f8_256.png`
- [ ] Crear 3 decoraciones estáticas: `_static_a.png`, `_static_b.png`, `_static_c.png`
- [ ] Configurar import (Repeat: Disabled)
- [ ] Testear en juego
- [ ] Verificar animaciones funcionando
- [ ] Ajustar escala/colores si necesario

---

## 🚀 SIGUIENTES PASOS

1. **Recibir assets de ChatGPT** (spritesheets + estáticos)
2. **Copiar a carpetas según estructura**
3. **Configurar import settings en Godot**
4. **Lanzar juego y verificar**
5. **Ajustar parámetros** (`border_decor_multiplier`, `base_decor_count`, etc.)
6. **Repetir para cada bioma**

---

## 📚 ARCHIVOS CREADOS

- ✅ `scripts/utils/AutoFrames.gd` - Carga automática de spritesheets
- ✅ `scripts/utils/DecorFactory.gd` - Fabricador de nodos de decoración
- ✅ `scripts/core/BiomeChunkApplierOrganic.gd` - Integrado con nuevo sistema

**Estado:** Código listo, esperando assets para testear.

---

¿Listo para subir los assets? 🎮
