# 📏 DIMENSIONES DE CHUNKS Y TIPOS DE BIOMAS - SPELLLOOP

## 🔷 DIMENSIONES DE CHUNKS

### Tamaño del Chunk
- **CHUNK_SIZE = 5120 píxeles**
- Esto significa cada "baldosa del mundo" es un cuadrado de 5120×5120 píxeles

### Estructura de Texturas
- **TEXTURE_SIZE = 512 píxeles** (la textura que se genera y luego se escala)
- **TILE_SIZE = 32 píxeles** (cada tesela individual dentro de la textura)
- **Teselas por lado = 512 ÷ 32 = 16 teselas**
- **Total teselas por chunk = 16 × 16 = 256 teselas**

### Escala Visual
- La textura de 512×512 se escala a 5120×5120 (factor de escala **10x**)
- Esto hace que cada tesela de 32×32 píxeles se vea como 320×320 píxeles en pantalla

---

## 🎨 TIPOS DE BIOMAS (5 TOTAL)

El juego tiene **5 biomas diferentes**:

1. **SAND** (Arena/Desierto)
   - Color primario: `Color(0.956, 0.816, 0.247, 1.0)` - Amarillo arena
   - Color detalle: `Color(0.839, 0.533, 0.063, 1.0)` - Marrón oscuro
   - Nombre: "Arena"
   - Identificador en código: `"sand"`

2. **GRASS** (Prado/Hierba)
   - Color primario: `Color(0.157, 0.682, 0.376, 1.0)` - Verde hierba
   - Color detalle: `Color(0.118, 0.518, 0.286, 1.0)` - Verde oscuro
   - Nombre: "Bosque" (nomenclatura actual)
   - Identificador en código: `"grass"` (EN InfiniteWorldManager) / `"forest"` (EN BiomeTextures)
   - ⚠️ **NOTA**: Hay inconsistencia de nombres

3. **SNOW** (Nieve)
   - Color primario: `Color(0.365, 0.682, 0.882, 1.0)` - Azul cielo/hielo
   - Color detalle: `Color(0.157, 0.455, 0.651, 1.0)` - Azul oscuro
   - Nombre: "Hielo"
   - Identificador en código: `"snow"`

4. **ASH** (Ceniza/Volcánico)
   - Color primario: `Color(0.906, 0.302, 0.235, 1.0)` - Rojo fuego
   - Color detalle: `Color(0.659, 0.196, 0.149, 1.0)` - Rojo oscuro
   - Nombre: "Fuego"
   - Identificador en código: `"ash"`

5. **FOREST** (Bosque/Frondoso)
   - Color primario: `Color(0.102, 0.0, 0.2, 1.0)` - Púrpura oscuro
   - Color detalle: `Color(0.4, 0.0, 0.5, 1.0)` - Púrpura más claro
   - Nombre: "Abismo"
   - Identificador en código: `"forest"`

### Array de Biomas en InfiniteWorldManager
```gdscript
var biomes = ["sand", "grass", "snow", "ash", "forest"]
```

---

## 📊 PROBLEMA ACTUAL CON CHUNKS

### Por qué no se ven los mosaicos:

1. **Escala inapropiada**: La textura de 512×512 se escala 10x a 5120×5120
   - A esta escala, las líneas divisorias de 4px se ven como 40px (GRANDE)
   - Pero el contraste color sombra/luz es insuficiente

2. **Contraste débil actual**:
   - Sombra: `color * 0.4` (40% del color original)
   - Highlight: `color * 1.5` (150% del color original)
   - Borde: 4px de grosor
   - **PROBLEMA**: No es suficientemente visible a esa escala

3. **Lo que se ve**: 
   - Cada chunk es un color sólido (sin variación de teselas visible)
   - Los bordes son muy sutiles

### Solución propuesta:

Para que el mosaico sea **CLARAMENTE VISIBLE** a 5120×5120:

1. Aumentar aún más el tamaño de teselas (ej: 64×64 en lugar de 32×32)
2. Aumentar contraste de colores radicalmente
3. Hacer bordes más pronunciados (8-10px)
4. Posiblemente reducir número de teselas (8×8 en lugar de 16×16)
5. Usar colores más vibrantes y diferenciados

---

## 🎯 RESUMEN PARA REDISEÑO

| Aspecto | Valor Actual | Estado |
|--------|-------------|--------|
| Tamaño chunk | 5120×5120 px | ✅ Fijo |
| Textura base | 512×512 px | ✅ Fijo (bueno para rendimiento) |
| Teselas | 32×32 px (16×16 grid) | ⚠️ Muy pequeñas cuando escaladas |
| Número biomas | 5 | ✅ Fijo |
| Contraste | 0.4x sombra / 1.5x highlight | ⚠️ Insuficiente |
| Visibilidad mosaico | ❌ NULA | 🔴 **CRÍTICO** |

