# 🌍 BIOME TEXTURES SPECIFICATION - Spellloop

## 📋 Resumen

Sistema de texturas tileables para 6 biomas del juego Spellloop. Cada bioma requiere:
- **1 textura base** (512×512 px, seamless/tileable)
- **3 texturas decorativas** (512×512 px o menor, tileables)
- Estilo: Cartoon/Funko Pop con contornos negros suaves

---

## 🎨 BIOMAS Y ESPECIFICACIONES

### 1. **GRASSLAND** (Verde Brillante)
**Color Base:** `#7ED957`  
**Descripción:** Pradera verde con hierba y flores  

**Textura Base:**
- Patrón de hierba ondulada
- Variaciones ligeras de saturación/valor para evitar monotonía
- Pequeñas flores de colores brillantes esparcidas
- Dimensiones: 512×512 px

**Decoraciones:**
1. `decor1.png` - Flores grandes: margaritas, tulipanes
2. `decor2.png` - Arbustos pequeños: trebol, plantas bajas
3. `decor3.png` - Piedras/rocas cubiertas de musgo

**Tiling:** Seamless 2×2 o 3×3 para cubrir chunk (5760×3240 px)

---

### 2. **DESERT** (Arena Dorada)
**Color Base:** `#E8C27B`  
**Descripción:** Desierto con dunas y cactus  

**Textura Base:**
- Patrón de arena con pequeñas grietas/líneas de dunas
- Variaciones de tonos beige/marrón claro
- Pequeñas piedritas dispersas
- Dimensiones: 512×512 px

**Decoraciones:**
1. `decor1.png` - Cactus pequeños: saguaro, prickly pear
2. `decor2.png` - Rocas lisas: piedras redondeadas, cantos
3. `decor3.png` - Dunas de arena con sombras

**Tiling:** Seamless, sin líneas visibles entre repeticiones

---

### 3. **SNOW** (Blanco-Azulado)
**Color Base:** `#EAF6FF`  
**Descripción:** Nieve con hielo y cristales  

**Textura Base:**
- Nieve compactada con pequeñas grietas/irregularidades
- Tonos blanco, azul claro, gris pálido
- Brillo/reflejo sutil
- Dimensiones: 512×512 px

**Decoraciones:**
1. `decor1.png` - Cristales de hielo: cristales brillantes
2. `decor2.png` - Pilas de nieve: bancos y montículos
3. `decor3.png` - Estalactitas/carámbanos colgantes

**Tiling:** Seamless, efecto frío/limpio

---

### 4. **LAVA** (Rojo-Naranja)
**Color Base:** `#F55A33`  
**Descripción:** Lava con grietas oscuras  

**Textura Base:**
- Grietas entrelazadas en negro oscuro (`#2A1A0A`)
- Zonas incandescentes naranja-amarillo (`#FF9500`, `#FFCC00`)
- Efecto de temperatura visual
- Dimensiones: 512×512 px

**Decoraciones:**
1. `decor1.png` - Charcos de lava hirviendo: zonas activas
2. `decor2.png` - Rocas de lava congelada: piedra oscura
3. `decor3.png` - Vapor/humo subiendo (semi-transparente)

**Tiling:** Seamless, líneas de lava deben conectar perfectamente
**Nota:** Potencial para animación (shader u overlay pulsante)

---

### 5. **ARCANE WASTES** (Violeta)
**Color Base:** `#B56DDC`  
**Descripción:** Ruinas arcanas con símbolos brillantes  

**Textura Base:**
- Suelo violeta mullido/texturizado
- Runas brillantes claras (`#E0B0FF`, `#C099FF`) esparcidas
- Patrón mágico sutil entrelazado
- Dimensiones: 512×512 px

**Decoraciones:**
1. `decor1.png` - Runas flotantes: símbolos mágicos brillantes
2. `decor2.png` - Cristales arcanos: cristales violeta-claros
3. `decor3.png` - Energía mágica: auras/partículas sutiles

**Tiling:** Seamless, runas deben alinearse con patrón base
**Nota:** Efecto mágico (luz/brillo opcional)

---

### 6. **FOREST** (Verde Oscuro)
**Color Base:** `#306030`  
**Descripción:** Bosque denso con vegetación  

**Textura Base:**
- Suelo oscuro cubierto de hojas/musgo
- Raíces visibles, ramitas pequeñas
- Tonos verde muy oscuro, marrón, gris
- Dimensiones: 512×512 px

**Decoraciones:**
1. `decor1.png` - Plantas altas: helechos, hierbas altas
2. `decor2.png` - Árboles caídos/troncos: madera oscura
3. `decor3.png` - Hongos/setas: fungi de colores

**Tiling:** Seamless, efecto denso/oscuro

---

## 🛠️ ESPECIFICACIONES TÉCNICAS

### Formato
- **Formato:** PNG sin compresión (o PNG con compresión leve)
- **Tamaño:** 512×512 px para todas las texturas
- **Canal Alpha:** Solo para decoraciones con transparencia (decor*.png)
- **Resolución:** 72-96 DPI

### Tiling/Seamless
- **Método:** Los bordes izquierdo/derecho y superior/inferior deben ser idénticos
- **Herramientas sugeridas:** Krita, Substance Designer, offset filter en GIMP
- **Validación:** Repetir 2×2 en editor y verificar sin líneas visibles

### Estilo Visual
- **Líneas de contorno:** Negro suave (`#1A1A1A`) alrededor de formas principales
- **Formas:** Simples, geométricas, tipo Funko Pop
- **Colores:** Saturados pero no opacos; variaciones sutiles de value/saturation
- **Sombras:** Suaves, difuminadas, integradas en la textura

### Rendimiento
- **Compresión en Godot:** VRAM compressed (recomendado)
- **Mipmaps:** Habilitados para distancias variables
- **Filter:** Linear (suavizado)
- **Memory:** ~1 MB por bioma (6 texturas × 512×512 PNG)

---

## 📦 ESTRUCTURA DE CARPETAS

```
assets/textures/biomes/
├── biome_textures_config.json  (configuración central)
├── Grassland/
│   ├── base.png                (512×512)
│   ├── decor1.png              (flores grandes)
│   ├── decor2.png              (arbustos)
│   └── decor3.png              (rocas)
├── Desert/
│   ├── base.png
│   ├── decor1.png              (cactus)
│   ├── decor2.png              (rocas)
│   └── decor3.png              (dunas)
├── Snow/
│   ├── base.png
│   ├── decor1.png              (cristales)
│   ├── decor2.png              (montículos)
│   └── decor3.png              (carámbanos)
├── Lava/
│   ├── base.png
│   ├── decor1.png              (lava hirviendo)
│   ├── decor2.png              (rocas)
│   └── decor3.png              (vapor)
├── ArcaneWastes/
│   ├── base.png
│   ├── decor1.png              (runas)
│   ├── decor2.png              (cristales)
│   └── decor3.png              (energía)
└── Forest/
    ├── base.png
    ├── decor1.png              (plantas altas)
    ├── decor2.png              (troncos)
    └── decor3.png              (hongos)
```

---

## ✅ CHECKLIST DE ENTREGA

Para cada bioma, verificar:

- [ ] **Base texture** 512×512, seamless, color base correcto, estilo Funko Pop
- [ ] **Decor 1-3** 512×512, tileables, con alpha donde corresponda
- [ ] **Sin líneas de corte** visibles al repetir 2×2
- [ ] **Contornos negros** suaves en elementos principales
- [ ] **Variación de color** para evitar monotonía
- [ ] **Archivos nombrados correctamente** en carpetas (base.png, decor1.png, etc.)
- [ ] **JSON config** actualizado con rutas correctas
- [ ] **Importar en Godot** sin warnings de compresión

---

## 🔧 INTEGRACIÓN EN GODOT 4.5.1

### Pasos:
1. Copiar texturas a `assets/textures/biomes/{BiomeName}/`
2. En Godot, importar cada PNG:
   - Filter: Linear
   - Mipmaps: ON
   - Compress: VRAM Compressed (VRAM S3TC)
3. BiomeChunkApplier.gd cargará automáticamente desde config.json
4. Llamar `on_player_position_changed()` desde InfiniteWorldManager

### Ejemplo en script:
```gdscript
var biome_applier = BiomeChunkApplier.new()
biome_applier.on_player_position_changed(player_position)
```

---

## 📝 NOTAS FINALES

- Las texturas deben ser **determinísticas**: mismo chunk siempre mismo bioma
- Usar `RandomNumberGenerator` con seed basado en (cx, cy) para reproducibilidad
- Optimización: texturas pequeñas (512×512) x 6 biomas = bajo footprint
- Decoraciones con alpha (~40% opacity) para evitar occlusión de gameplay
- Chunks lejanos se descargan automáticamente (máximo 9 activos)

¡Listo para crear las texturas! 🎨

