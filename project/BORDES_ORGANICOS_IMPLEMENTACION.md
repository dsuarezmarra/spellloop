# 🎨 IMPLEMENTACIÓN: BORDES ORGÁNICOS CON DECORACIONES DENSAS

**Fecha:** 9 de noviembre de 2025  
**Sistema:** Opción A - Tiles pequeños + decoraciones densas en bordes  
**Archivo modificado:** `scripts/core/BiomeChunkApplierOrganic.gd`

---

## 📋 PROBLEMA IDENTIFICADO

**Síntoma:** Bordes entre biomas "muy rectos y nada orgánicos" con transiciones escalonadas visibles.

**Causa raíz:** 
- Sistema de tiles binarios: cada tile de 512px detecta bioma en su centro y se pinta entero
- Resultado: bordes en "escalera" de 512px de ancho
- Sin sistema de transición o blending entre biomas

**Comparación Don't Starve:**
- Usa tiles 128-256px (escalones más pequeños)
- Aplica máscaras de transición en bordes
- Decoraciones densas que ocultan transiciones
- Voronoi con jitter alto + perturbación con noise

---

## ✅ SOLUCIÓN IMPLEMENTADA: Opción A

### **Estrategia:**
1. **Tiles más pequeños** (256px en lugar de 512px)
   - Reduce el "tamaño del escalón" a la mitad
   - 3600 tiles por chunk (vs 900 antes)
   
2. **Detección automática de tiles de borde**
   - Algoritmo que identifica tiles con vecinos de diferente bioma
   - ~20-30% de tiles suelen ser bordes en chunks multi-bioma

3. **Decoraciones extra en bordes**
   - 4x más densidad en tiles de borde (8 decoraciones/tile)
   - Decoraciones más pequeñas y semi-transparentes
   - Camuflaje visual de las transiciones escalonadas

4. **Aumento de decoraciones base**
   - De 50 → 120 decoraciones por chunk
   - Mundo más denso y visualmente rico

---

## 🔧 CAMBIOS TÉCNICOS

### **1. Parámetros ajustados:**

```gdscript
# BiomeChunkApplierOrganic.gd - Línea 32-36
@export var tile_resolution: int = 256  # 512 → 256 (escalones más pequeños)
@export var border_decor_multiplier: float = 4.0  # NUEVO: 4x más denso en bordes
```

**Impacto:**
- Tiles por chunk: 900 → 3600 (+300%)
- Sprites base por chunk: ~900 → ~3600
- Decoraciones base: 50 → 120 (+140%)
- Decoraciones en bordes: +8 por tile de borde (~200-300 extra)

**Total estimado:** ~4000-4200 sprites por chunk (manejable)

---

### **2. Nuevas funciones:**

#### **`_detect_border_tiles()`** (Línea 380-413)
```gdscript
func _detect_border_tiles(tile_biome_map: Dictionary, tiles_x: int, tiles_y: int) -> Array
```

**Algoritmo:**
1. Itera sobre todos los tiles del chunk
2. Para cada tile, revisa 4 vecinos (arriba, abajo, izq, der)
3. Si algún vecino tiene diferente bioma → es tile de borde
4. Retorna array de posiciones `Vector2i(tx, ty)`

**Complejidad:** O(n) donde n = número de tiles (~3600)

---

#### **`_apply_border_decorations()`** (Línea 415-478)
```gdscript
func _apply_border_decorations(parent, border_tiles, tile_biome_map, tile_size, chunk_world_x, chunk_world_y)
```

**Lógica:**
1. Para cada tile de borde detectado
2. Coloca 8 decoraciones aleatorias (4x multiplicador × 2)
3. Posiciones aleatorias dentro del tile
4. Escala reducida: 80-180px (vs 100-250px normales)
5. Alpha más bajo: 0.7-0.9 (más transparentes)
6. z_index: -95 (encima de decoraciones normales)

**Resultado:** Bordes visualmente "difuminados" por decoraciones superpuestas

---

### **3. Flujo de generación modificado:**

**ANTES (512px sin detección de bordes):**
```
1. Aplicar 900 tiles base (512px)
2. Aplicar 50 decoraciones aleatorias
   ✗ Bordes visibles de 512px
```

**DESPUÉS (256px con decoraciones en bordes):**
```
1. Aplicar 3600 tiles base (256px)
2. Construir mapa de biomas por tile
3. Detectar tiles de borde (4-vecinos diferentes)
4. Aplicar decoraciones extra en bordes (4x densidad)
5. Aplicar 120 decoraciones base aleatorias
   ✓ Bordes camuflados con decoraciones
   ✓ Escalones más pequeños (256px vs 512px)
```

---

## 📊 MÉTRICAS ESPERADAS

### **Performance:**
| Métrica | Antes (512px) | Después (256px) | Impacto |
|---------|---------------|-----------------|---------|
| Tiles por chunk | 900 | 3600 | +300% |
| Decoraciones base | 50 | 120 | +140% |
| Decoraciones borde | 0 | ~250 | +nuevo |
| Total sprites/chunk | ~950 | ~4000 | +320% |
| Memoria por chunk | ~5 MB | ~20 MB | +300% |

**¿Es manejable?** ✅ SÍ
- Godot 4.x maneja 4k sprites por chunk sin problemas
- Sistema de chunks descarga chunks lejanos (solo 9 activos)
- Carga total: ~36k sprites máximo (9 chunks × 4k)

---

### **Calidad visual:**
| Aspecto | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Tamaño de escalón | 512px | 256px | ✅ 50% más suave |
| Camuflaje de bordes | Ninguno | 4x decoraciones | ✅ Transiciones ocultas |
| Densidad mundo | Baja (50 decor) | Alta (120 + 250) | ✅ +640% decoraciones |
| Organicidad | ⭐⭐ | ⭐⭐⭐⭐ | ✅ Mucho mejor |

---

## 🧪 TESTING

### **Cómo verificar:**
1. Lanzar el juego
2. Moverse entre biomas (especialmente Desert↔Snow, Lava↔ArcaneWastes)
3. **Observar:**
   - Escalones más pequeños (256px en lugar de 512px)
   - Decoraciones densas en las zonas de transición
   - Bordes visualmente más irregulares/orgánicos
   - Mundo más denso en general

### **Logs a revisar:**
```
[BiomeChunkApplierOrganic] 🎨 Aplicando 59×59 tiles (total: 3481)
[BiomeChunkApplierOrganic] 🔍 Bordes detectados: XXX tiles en transición
[BiomeChunkApplierOrganic] 🎨 XXX decoraciones de borde colocadas (x4.0 densidad)
[BiomeChunkApplierOrganic] ✓ 120 decoraciones colocadas
```

---

## 🔄 AJUSTES DISPONIBLES

Si el resultado no es satisfactorio, ajustar estos parámetros:

### **En `BiomeChunkApplierOrganic.gd`:**

```gdscript
# Tamaño de tiles (línea 34)
@export var tile_resolution: int = 256  
# ↓ Probar: 128 (más suave, +sprites), 320 (intermedio), 384 (casi 512)

# Multiplicador de decoraciones en bordes (línea 36)
@export var border_decor_multiplier: float = 4.0  
# ↓ Probar: 6.0 (aún más denso), 2.0 (menos decoraciones)

# Decoraciones base (línea 262)
var base_decor_count = 120
# ↓ Probar: 80 (menos denso), 200 (mundo muy poblado)
```

---

## 🚀 ALTERNATIVAS FUTURAS (si Opción A no es suficiente)

### **Opción B: Máscaras de transición** (1-2 días)
- Detectar dirección del borde (N/S/E/W)
- Aplicar sprites de transición con alpha blending
- Mezclar texturas de 2 biomas adyacentes
- **Calidad:** ⭐⭐⭐⭐⭐ (como Don't Starve)
- **Complejidad:** Alta (necesita texturas de transición)

### **Opción C: Voronoi perturbado con Perlin** (4-6 horas)
- Segundo layer de Perlin noise que "ondula" los bordes
- Offset de detección basado en noise
- Bordes naturalmente irregulares sin más sprites
- **Calidad:** ⭐⭐⭐⭐
- **Complejidad:** Media (solo código, no texturas)

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [x] Reducir tile_resolution de 512px a 256px
- [x] Añadir parámetro `border_decor_multiplier`
- [x] Implementar `_detect_border_tiles()`
- [x] Implementar `_apply_border_decorations()`
- [x] Construir `tile_biome_map` durante aplicación de tiles
- [x] Aumentar `base_decor_count` de 50 a 120
- [x] Integrar detección de bordes en flujo principal
- [x] Verificar sintaxis (sin errores)
- [ ] **Testing en juego** (pendiente usuario)

---

## 📝 NOTAS TÉCNICAS

### **Por qué no máscaras de transición (Opción B)?**
- Requiere 20-30 texturas de transición adicionales
- Lógica compleja de detección de dirección de borde
- Mayor tiempo de implementación (1-2 días)
- Opción A es más rápida y probablemente suficiente

### **Por qué no Perlin overlay (Opción C)?**
- Puede fragmentar demasiado los biomas
- Requiere ajuste fino de parámetros
- Puede crear "islas" de biomas indeseadas
- Opción A es más predecible

### **Performance:**
- 4k sprites/chunk es estándar en juegos 2D modernos
- Godot usa batching automático para sprites similares
- Sistema de chunks limita a 9 chunks activos máximo
- No debería afectar FPS en hardware moderno

---

## 🎯 RESULTADO ESPERADO

**Visual:**
- Bordes entre biomas más suaves (escalones de 256px vs 512px)
- Transiciones camufladas por decoraciones densas
- Mundo visualmente más rico y poblado
- Aspecto más orgánico similar a Don't Starve

**Técnico:**
- Sin cambios en la lógica de Voronoi (cellular noise)
- Sin nuevas texturas requeridas
- Performance manejable (~4k sprites/chunk)
- Fácil de revertir o ajustar parámetros

---

**Próximo paso:** Testear en juego y ajustar parámetros según feedback visual del usuario.
