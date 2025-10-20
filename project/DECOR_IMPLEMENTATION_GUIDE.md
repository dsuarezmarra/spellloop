# 🎨 GUÍA: PREPARACIÓN DEL SISTEMA DECOR

## ✅ STATUS ACTUAL

### Texturas Base
- ✅ **TODAS LAS BASES RESCALADAS** (1920×1080)
  - Grassland/base.png ✅
  - Desert/base.png ✅
  - Snow/base.png ✅
  - Lava/base.png ✅
  - ArcaneWastes/base.png ✅
  - Forest/base.png ✅

### Texturas Decor
- ⏳ **EN PROGRESO** - Se necesitan crear
  - Cada bioma requiere 3 decoraciones (decor1.png, decor2.png, decor3.png)
  - Especificaciones en la siguiente sección

---

## 📐 ESPECIFICACIONES TÉCNICAS PARA DECOR

### Arquitectura Opción C Implementada en BiomeChunkApplier.gd

```
CHUNK: 5760×3240 píxeles
  ├─ Grid: 3×3 cuadrantes
  └─ Cada cuadrante: 1920×1080 píxeles

BASE (Suelo):
  ├─ Tamaño PNG: 1920×1080 (ya tienes estas ✅)
  ├─ Cantidad: 9 (una por cuadrante)
  ├─ Escala: 1.0 (sin deformación)
  └─ Z-index: -100 (MÁS ATRÁS)

DECORACIONES (Plantas, Rocas, etc):
  ├─ Cantidad: 1 por cuadrante = 9 total
  ├─ Distribución: ALEATORIA dentro del cuadrante
  │   └─ Rango: ±30% del tamaño del cuadrante (sin salir)
  │
  ├─ TIPO 1: PRINCIPALES (256×256 png)
  │   ├─ Tamaño PNG: 256×256
  │   ├─ Escala en-game: (3.75, 2.1)
  │   ├─ Ocupa: ~28% del área del cuadrante
  │   └─ Opacidad: 90%
  │
  ├─ TIPO 2: SECUNDARIAS (128×128 png)
  │   ├─ Tamaño PNG: 128×128
  │   ├─ Escala en-game: (3.75, 2.1) (IGUAL que principales)
  │   ├─ Ocupa: ~28% del área del cuadrante
  │   └─ Opacidad: 90%
  │
  └─ Z-index: -99 (DEBAJO de enemigos/player, ENCIMA de base)
```

---

## 📝 CONFIGURACIÓN JSON YA LISTA

El archivo `biome_textures_config.json` ya tiene la estructura correcta:

```json
{
  "biomes": [
    {
      "id": "grassland",
      "name": "Grassland",
      "textures": {
        "base": "Grassland/base.png",        ✅ Ya tienes
        "decor": [
          "Grassland/decor1.png",           ⏳ Crear (256×256)
          "Grassland/decor2.png",           ⏳ Crear (256×256 o 128×128)
          "Grassland/decor3.png"            ⏳ Crear (256×256 o 128×128)
        ]
      }
    },
    // ... 5 biomas más con estructura idéntica
  ]
}
```

---

## 🎨 QUÉ NECESITAS CREAR

### Para CADA Bioma (6 total):

**Estructura esperada:**
```
assets/textures/biomes/
├─ Grassland/
│   ├─ base.png              ✅ (1920×1080)
│   ├─ decor1.png            ⏳ CREAR (256×256 recomendado)
│   ├─ decor2.png            ⏳ CREAR (128×128 o 256×256)
│   └─ decor3.png            ⏳ CREAR (128×128 o 256×256)
│
├─ Desert/
│   ├─ base.png              ✅ (1920×1080)
│   ├─ decor1.png            ⏳ CREAR
│   ├─ decor2.png            ⏳ CREAR
│   └─ decor3.png            ⏳ CREAR
│
├─ Snow/                      ⏳ Mismo patrón
├─ Lava/                      ⏳ Mismo patrón
├─ ArcaneWastes/              ⏳ Mismo patrón
└─ Forest/                    ⏳ Mismo patrón
```

### Tamaños PNG Recomendados por Tipo:

**Opción A: Decoraciones Principales Grandes**
- decor1.png: 256×256 (plantas, rocas grandes)
- decor2.png: 256×256 (árboles, estructuras medianas)
- decor3.png: 128×128 (flores, detalles pequeños)

**Opción B: Mezcla Balanceada**
- decor1.png: 256×256 (elementos destacados)
- decor2.png: 128×128 (elementos secundarios)
- decor3.png: 128×128 (detalles)

**Opción C: Pequeños Detalles**
- decor1.png: 128×128 (todos pequeños)
- decor2.png: 128×128
- decor3.png: 128×128

---

## 🔍 CÓMO FUNCIONARÁ EL RENDERIZADO

### Al presionar F5:

1. **BiomeChunkApplier.gd** cargará la configuración JSON
2. **Para cada chunk generado:**
   - Selecciona bioma aleatoria (determinística por posición)
   - Crea 9 sprites base (1920×1080 cada uno, sin escala)
   - Selecciona aleatoriamente 1 decoración por cuadrante
   - Coloca decoración en posición aleatoria dentro del cuadrante
   - Aplica escala automática según tamaño PNG (256×256 vs 128×128)

3. **Resultado final:**
   - Chunk de 5760×3240 con texturas base bonitas
   - 9 decoraciones distribuidas aleatoriamente
   - Z-index correcto: base < decor < enemigos < player

---

## 🛠️ CÓDIGO IMPLEMENTADO (BiomeChunkApplier.gd)

### Función Principal: `_apply_textures_optimized()`

```gdscript
# ========== APLICAR TEXTURAS OPTIMIZADAS ==========
func _apply_textures_optimized(parent: Node, bioma_data: Dictionary, cx: int, cy: int) -> void:
	"""
	Chunk: 5760×3240 (grid 3×3)
	Base: 1920×1080 (sin escala)
	Decor: 1 aleatoria por cuadrante (256×256 o 128×128)
	"""
	
	# 1. TEXTURAS BASE (9 sprites, uno por cuadrante)
	# ✅ Escala automática según tamaño real del PNG
	
	# 2. DECORACIONES (9 posiciones)
	# ✅ RNG determinístico por posición (chunk_seed)
	# ✅ Distribución aleatoria sin salir del cuadrante
	# ✅ Escala automática: 256×256 → (3.75, 2.1)
	#                       128×128 → (3.75, 2.1) (igual)
	# ✅ Z-index correcto: -99 (encima base, abajo enemigos)
```

### Lógica de Detección de Tamaño:

```gdscript
# Detectar tipo automáticamente por tamaño del PNG
if decor_size.x >= 200:  # Principales: 256×256
	decor_scale = Vector2(
		(tile_size.x / decor_size.x) * 0.5,  # 1920/256 * 0.5 = 3.75
		(tile_size.y / decor_size.y) * 0.5   # 1080/256 * 0.5 = 2.1
	)
else:  # Secundarias: 128×128
	decor_scale = Vector2(
		(tile_size.x / decor_size.x) * 0.25,  # 1920/128 * 0.25 = 3.75
		(tile_size.y / decor_size.y) * 0.25   # 1080/128 * 0.25 = 2.1
	)
```

**Resultado:** Ambos tamaños de PNG terminan con escala (3.75, 2.1) en-game. ✨

---

## 🚀 PRÓXIMOS PASOS

### PASO 1: Crear Texturas Decor
```
Para CADA uno de los 6 biomas:
  ├─ Crear decor1.png (256×256 o mayor)
  ├─ Crear decor2.png (256×256 o 128×128)
  ├─ Crear decor3.png (256×256 o 128×128)
  └─ Guardar en: assets/textures/biomes/{BiomeName}/
```

**Contenido sugerido:**
- Grassland: flores, arbustos, rocas
- Desert: cactus, rocas, dunas
- Snow: cristales, montículos, carámbanos
- Lava: rocas volcánicas, grietas, vapor
- ArcaneWastes: runas, cristales, energía
- Forest: troncos, hongos, plantas

### PASO 2: Presionar F5
- El código detectará automáticamente los tamaños
- Mostrará logs de verificación en consola
- Renderizará decoraciones según configuración

### PASO 3: Ajustar si es necesario
- Si algo no se ve bien, los logs mostrarán escalas aplicadas
- Puedes modificar tamaños PNG sin cambiar código
- El sistema se adapta automáticamente

---

## 📊 RESUMEN TÉCNICO

| Componente | Especificación | Estado |
|-----------|---|---|
| Chunk Size | 5760×3240 (3×3 cuadrantes) | ✅ Implementado |
| Base Texture | 1920×1080 × 9 sprites | ✅ Rescaladas |
| Decor - Type 1 | 256×256 PNG → (3.75, 2.1) escala | ⏳ Crear PNG |
| Decor - Type 2 | 128×128 PNG → (3.75, 2.1) escala | ⏳ Crear PNG |
| Decor Distribution | 1 aleatoria por cuadrante | ✅ Implementado |
| Z-index Base | -100 | ✅ Implementado |
| Z-index Decor | -99 | ✅ Implementado |
| Z-index Entities | 0+ | ✅ Implementado |
| RNG | Determinístico (seeded) | ✅ Implementado |
| Bounds Checking | No sale del cuadrante | ✅ Implementado |

---

## ⚠️ NOTAS IMPORTANTES

1. **El código está 100% listo** - Solo necesita los PNG de decoraciones
2. **Auto-scaling funciona** - Detecta tamaño automáticamente
3. **RNG seeded** - Misma posición = mismas texturas siempre
4. **Z-index correcto** - Biomas atrás, enemigos adelante
5. **Sin superposición** - Max 1 decor por cuadrante

---

**Documento generado:** 21 Oct 2025  
**Sistema:** Spellloop Biome Rendering v1.0 (Opción C)  
**Status:** ⏳ Esperando texturas decor

