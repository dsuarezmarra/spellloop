# 🌍 Sistema de Biomas Orgánicos - Spellloop

## ✅ ESTADO: SISTEMA VORONOI IMPLEMENTADO

**Fecha:** 9 de noviembre de 2025  
**Versión:** 2.0 (Organic Voronoi System)

---

## 🎨 Qué es el Sistema Orgánico

El nuevo sistema de biomas utiliza **regiones Voronoi** para crear transiciones naturales e irregulares entre biomas, similar a juegos como Don't Starve.

### Diferencias con el Sistema Antiguo

| Aspecto | Sistema Antiguo | Sistema Orgánico (Actual) |
|---------|----------------|---------------------------|
| Biomas por chunk | 1 bioma uniforme | Múltiples biomas en un chunk |
| Forma de regiones | Chunks rectangulares | Regiones Voronoi irregulares |
| Bordes | Rectos (grid) | Orgánicos e impredecibles |
| Tamaño de tiles | 512×512 px | 256×256 px |
| Tiles por chunk | ~900 | ~3600 |
| Tecnología | Grid fijo | FastNoiseLite TYPE_CELLULAR |

---

## 🔧 Arquitectura del Sistema

### Componentes Principales

1. **BiomeGeneratorOrganic.gd**
   - Usa FastNoiseLite con TYPE_CELLULAR (Voronoi)
   - Genera regiones masivas de ~100,000 px
   - Frequency: 0.00001 para máxima escala
   - Jitter: 1.0 para máximo caos/irregularidad
   - Distance function: EUCLIDEAN (formas naturales)

2. **BiomeChunkApplierOrganic.gd**
   - Divide chunks en tiles de 256×256 px
   - ~60×60 = 3600 tiles por chunk
   - Cada tile detecta su bioma en el centro
   - Los bordes orgánicos se forman NATURALMENTE
   - Sin dithering artificial (no es necesario)

3. **InfiniteWorldManager.gd**
   - Gestiona chunks de 15000×15000 px
   - Máximo 9 chunks activos (3×3 grid)
   - Sistema de mundo móvil con posición virtual del jugador

### Flujo de Generación

```
1. Player entra en nuevo chunk
   ↓
2. InfiniteWorldManager detecta cambio
   ↓
3. BiomeGeneratorOrganic evalúa Voronoi en muestras 8×8
   ↓
4. BiomeChunkApplierOrganic crea ~3600 tiles de 256px
   ↓
5. Cada tile consulta Voronoi en su centro
   ↓
6. Se asigna textura del bioma correspondiente
   ↓
7. Bordes orgánicos aparecen automáticamente
   ↓
8. Se colocan decoraciones según bioma detectado
```

---

## 📊 Biomas Disponibles

| ID | Nombre | Descripción |
|----|--------|-------------|
| 0 | Grassland | Césped verde, flores silvestres |
| 1 | Desert | Arena dorada, cactus |
| 2 | Snow | Hielo blanco, cristales |
| 3 | Lava | Magma incandescente, rocas volcánicas |
| 4 | ArcaneWastes | Tierra mágica violeta, runas |
| 5 | Forest | Bosque denso, verde oscuro |

Cada bioma tiene:
- **1 textura base** (`base.png`, 512×512 px)
- **5 texturas de decoración** (`decor1.png` a `decor5.png`)
- **Configuración JSON** en `biome_textures_config.json`

---

## 🎮 Cómo Funciona

### Detección de Bioma

```gdscript
# BiomeGeneratorOrganic evalúa Voronoi en una posición
var biome_type = biome_generator.get_biome_at_world_position(world_x, world_y)

# Voronoi devuelve valor [-1.0, 1.0]
# Se normaliza a [0.0, 1.0]
# Se mapea a BiomeType [0, 5] (6 biomas)
```

### Aplicación de Texturas

```gdscript
# Para cada tile de 256×256 px:
1. Calcular posición mundial del centro del tile
2. Detectar bioma en esa posición usando Voronoi
3. Cargar textura base del bioma detectado
4. Crear Sprite2D con la textura
5. Escalar sprite para cubrir el tile completo
6. Posicionar sprite en z=-100 (fondo)
```

### Bordes Orgánicos

Los bordes NO se generan artificialmente. Aparecen naturalmente porque:

1. Voronoi crea regiones irregulares con bordes curvos
2. Tiles de 256px son lo suficientemente pequeños para seguir las curvas
3. Cada tile detecta independientemente su bioma
4. El "escalonado" de tiles sigue la forma Voronoi
5. Resultado: transiciones orgánicas y naturales

---

## 🚀 Configuración y Ajustes

### Parámetros de Voronoi (BiomeGeneratorOrganic)

```gdscript
# Frecuencia: controla tamaño de regiones
@export var cellular_frequency: float = 0.00001   # ~100,000 px por región

# Jitter: controla irregularidad
@export var cellular_jitter: float = 1.0          # 1.0 = máximo caos

# Seed: mundo único cada partida
@export var seed_value: int = 0                    # 0 = aleatorio
```

**Efectos de cambiar parámetros:**

- **Frecuencia más alta** (ej: 0.0001) → Regiones más pequeñas → Más cambios de bioma
- **Frecuencia más baja** (ej: 0.000001) → Regiones gigantes → Menos cambios
- **Jitter 0.0** → Regiones geométricas uniformes (hexágonos)
- **Jitter 1.0** → Regiones caóticas e irregulares (natural)

### Parámetros de Tiles (BiomeChunkApplierOrganic)

```gdscript
# Tamaño de cada tile de textura
@export var tile_resolution: int = 256            # 256px por tile

# Densidad de decoraciones
@export var decor_density_global: float = 1.0     # 1.0 = densidad normal
```

**Efectos de cambiar tamaño de tile:**

- **Tiles más pequeños** (128px) → Bordes MÁS suaves → Más sprites → Posible lag
- **Tiles más grandes** (512px) → Bordes más "pixelados" → Menos sprites → Mejor rendimiento

**Balance recomendado:** 256px (actual)

---

## 📂 Estructura de Archivos

```
project/
├── scripts/core/
│   ├── BiomeGeneratorOrganic.gd         ✅ Sistema Voronoi
│   ├── BiomeChunkApplierOrganic.gd      ✅ Aplicador multi-bioma
│   ├── InfiniteWorldManager.gd          ✅ Gestor de chunks
│   ├── BiomeGenerator.gd                ⚠️ OBSOLETO (legacy)
│   └── BiomeChunkApplier.gd             ⚠️ OBSOLETO (legacy)
│
├── scripts/tools/
│   ├── BiomeIntegrationTest.gd          ✅ Tests actualizados
│   └── BiomeRenderingDebug.gd           ✅ Debug actualizado
│
├── assets/textures/biomes/
│   ├── biome_textures_config.json       ✅ Config central
│   ├── Grassland/ (base.png + decor1-5)
│   ├── Desert/ (base.png + decor1-5)
│   ├── Snow/ (base.png + decor1-5)
│   ├── Lava/ (base.png + decor1-5)
│   ├── ArcaneWastes/ (base.png + decor1-5)
│   └── Forest/ (base.png + decor1-5)
│
├── README_BIOMES.md                      ⚠️ Sistema antiguo
└── README_BIOMES_ORGANIC.md             ✅ Este documento
```

---

## ✅ Verificación del Sistema

### Logs Esperados en Consola

Al iniciar el juego:

```
[BiomeGeneratorOrganic] 🎲 Seed aleatorio generado: 514208625
[BiomeGeneratorOrganic] 🔧 Configuración:
  - Frequency: 0.000010 (regiones ~100000 px)
  - Jitter: 1.00 (máximo caos/irregularidad)
  - Distance: EUCLIDEAN (formas naturales orgánicas)
[BiomeGeneratorOrganic] ✅ Inicializado con Voronoi puro
[InfiniteWorldManager] ✅ BiomeGeneratorOrganic cargado (Voronoi)
[BiomeChunkApplierOrganic] ✓ Config cargado. Biomas disponibles: 6
[InfiniteWorldManager] ✅ BiomeChunkApplierOrganic cargado (multi-bioma)
```

Al generar chunks:

```
[BiomeGeneratorOrganic] ✨ Chunk (0, 0) contiene biomas: ["Snow", "Lava", "Desert"]
[BiomeChunkApplierOrganic] 🎨 Aplicando 60×60 tiles (total: 3600)
[BiomeChunkApplierOrganic] ✓ Tiles aplicados. Biomas detectados:
  - Snow: 2784 tiles (77.3%)
  - Lava: 180 tiles (5.0%)
  - Desert: 636 tiles (17.7%)
[BiomeChunkApplierOrganic] ✓ 50 decoraciones colocadas:
  - Desert: 12 decors
  - Snow: 38 decors
```

---

## 🔍 Debugging

### Visualizar Regiones Voronoi

```gdscript
# En BiomeGeneratorOrganic.gd
func visualize_chunk_biomes(chunk_node: Node2D, chunk_pos: Vector2i, resolution: int = 100):
    # Crea grid de colores mostrando cada bioma
    # Útil para debug visual
```

Llama esta función después de `generate_chunk_async()` para ver las regiones Voronoi claramente.

### Problemas Comunes

**Problema:** Bordes aún se ven muy rectos
- **Causa:** Tiles demasiado grandes (512px)
- **Solución:** Reducir `tile_resolution` a 256px o 128px

**Problema:** Lag al generar chunks
- **Causa:** Tiles demasiado pequeños (muchos sprites)
- **Solución:** Aumentar `tile_resolution` a 384px o 512px

**Problema:** Un bioma domina todo el chunk
- **Causa:** Frequency de Voronoi demasiado baja
- **Solución:** Aumentar `cellular_frequency` (ej: 0.0001)

**Problema:** Demasiados cambios de bioma
- **Causa:** Frequency de Voronoi demasiado alta
- **Solución:** Reducir `cellular_frequency` (ej: 0.000005)

---

## 🎨 Resultado Visual

Con el sistema actual (256px tiles, Voronoi 0.00001):

- ✅ Bordes orgánicos e irregulares
- ✅ Transiciones naturales entre biomas
- ✅ Cada chunk tiene 1-3 biomas dominantes
- ✅ Formas impredecibles y únicas por seed
- ✅ Sin patrones geométricos repetitivos
- ✅ Rendimiento estable (~3600 sprites/chunk)

**Comparación con Don't Starve:**
- Don't Starve usa tiles de ~256px
- Voronoi para regiones irregulares
- Nuestro sistema usa el mismo approach

---

## 📝 Histórico de Cambios

### v2.0 (9 nov 2025) - Sistema Orgánico
- ✅ Implementado Voronoi con FastNoiseLite
- ✅ Múltiples biomas por chunk
- ✅ Tiles reducidos a 256px
- ✅ Eliminado dithering artificial
- ✅ Bordes orgánicos naturales

### v1.0 (20 oct 2025) - Sistema Grid
- ⚠️ OBSOLETO
- Un bioma por chunk
- Tiles de 512px
- Bordes rectos (grid)

---

## 🚀 Próximas Mejoras Opcionales

1. **Shader-based blending** (complejo, ~4-6 horas)
   - Mezclar texturas con gradientes en GPU
   - Transiciones ultra-suaves píxel a píxel
   - Requiere custom shader + texture arrays

2. **Decoraciones en bordes** (fácil, ~30 min)
   - Detectar bordes entre biomas
   - Colocar decoraciones mixtas (árboles muertos, plantas híbridas)
   - Disfrazar transiciones con objetos

3. **Biomas adicionales** (moderado, ~1 hora)
   - Jungle (selva tropical)
   - Swamp (pantano)
   - Crystal Caves (cuevas de cristal)

---

## 📞 Contacto y Soporte

**Documentos relacionados:**
- `SISTEMA_ORGANICO_VORONOI_COMPLETO.md` - Análisis profundo
- `BIOME_INTEGRATION_GUIDE.md` - Guía de integración
- `README_BIOMES.md` - Sistema antiguo (legacy)

**Para preguntas:**
- Sistema Voronoi: Ver código en `BiomeGeneratorOrganic.gd`
- Aplicación de texturas: Ver `BiomeChunkApplierOrganic.gd`
- Gestión de chunks: Ver `InfiniteWorldManager.gd`

---

## 🎉 Estado Final

El sistema de biomas orgánicos está completamente funcional:

✅ **Voronoi implementado** - Regiones naturales e irregulares  
✅ **Bordes orgánicos** - Transiciones naturales sin dithering  
✅ **Multi-bioma** - Varios biomas por chunk  
✅ **Optimizado** - 3600 tiles/chunk, rendimiento estable  
✅ **Documentado** - Código comentado y guías completas  
✅ **Testeado** - Sistema funcionando en producción  

**¡Disfruta de los biomas dinámicos y orgánicos!** 🌍

---

**Generado:** 9 de noviembre de 2025  
**Proyecto:** Spellloop - Organic Voronoi Biome System v2.0  
**Status:** ✅ PRODUCTION READY (ORGANIC)
