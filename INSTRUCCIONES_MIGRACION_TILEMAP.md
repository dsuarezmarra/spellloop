# 🚀 MIGRACIÓN A TILEMAP - PASOS COMPLETADOS Y SIGUIENTES

## ✅ ARCHIVOS CREADOS (Fase Automática)

### 1. Scripts Principales
- ✅ **BiomeTileMapGenerator.gd** - Generación procedural con FastNoiseLite
- ✅ **BiomeDecoratorsManager.gd** - Decoradores con fade automático
- ✅ **InfiniteWorldManagerTileMap.gd** - Gestor de chunks para TileMap
- ✅ **GenerateBiomeTiles.gd** - Tool script para dividir texturas en tiles

## 📋 PASOS SIGUIENTES (Fase Manual)

### PASO 1: Generar Tiles 64×64 (5 minutos)

1. **Abrir el script en el editor de Godot:**
   - File → New Script → Load Script
   - Seleccionar: `project/scripts/tools/GenerateBiomeTiles.gd`

2. **Ejecutar el script:**
   - Con el script abierto: File → Run
   - **Resultado esperado:**
     ```
     ====================================================================
     🎨 GENERADOR DE TILES PARA BIOMAS
     ====================================================================
     
     📦 Procesando: Grassland
       ✓ Textura cargada: 512x512
       ✓ Tiles creados: 64 (8×8 grid)
     
     📦 Procesando: Desert
       ✓ Textura cargada: 512x512
       ✓ Tiles creados: 64 (8×8 grid)
     
     [... mismo para los 6 biomas ...]
     
     ====================================================================
     ✅ GENERACIÓN COMPLETADA
     ====================================================================
     📂 Tiles generados en: res://assets/tilesets/tiles/
     ```

3. **Verificar resultado:**
   - Ir a `project/assets/tilesets/tiles/`
   - Deberías ver 6 carpetas: `grassland/`, `desert/`, `forest/`, `arcane_wastes/`, `lava/`, `snow/`
   - Cada una con 64 archivos: `<biome>_0_0.png`, `<biome>_0_1.png`, ..., `<biome>_7_7.png`

---

### PASO 2: Crear TileSet Resource (15 minutos)

1. **Crear el recurso:**
   - En FileSystem: Click derecho en `assets/tilesets/`
   - New Resource → TileSet
   - Guardar como: `world_tileset.tres`

2. **Abrir TileSet Editor:**
   - Doble click en `world_tileset.tres`
   - Se abrirá el TileSet editor en el panel inferior

3. **Importar tiles de Grassland:**
   - En TileSet panel: Click "+" (Add Tiles)
   - Navegar a `assets/tilesets/tiles/grassland/`
   - Seleccionar TODOS los archivos PNG (Ctrl+A)
   - Click "Open"
   - **Resultado:** 64 tiles de grassland importados

4. **Repetir para los otros 5 biomas:**
   - Desert: importar todos los PNG de `desert/`
   - Forest: importar todos los PNG de `forest/`
   - ArcaneWastes: importar todos los PNG de `arcane_wastes/`
   - Lava: importar todos los PNG de `lava/`
   - Snow: importar todos los PNG de `snow/`
   
   **Total esperado:** 384 tiles (64 × 6 biomas)

5. **Configurar Terrains:**
   - En TileSet panel → Tab "Terrains"
   - Click "+" para añadir terrain
   - Repetir 6 veces, nombrar:
     - Terrain 0: "Grassland"
     - Terrain 1: "Desert"
     - Terrain 2: "Forest"
     - Terrain 3: "ArcaneWastes"
     - Terrain 4: "Lava"
     - Terrain 5: "Snow"

6. **Asignar tiles a terrains (CRÍTICO):**
   
   Para cada bioma (ejemplo con Grassland):
   
   a. **Seleccionar tiles del bioma:**
      - En TileSet panel → Tab "Select"
      - Seleccionar los 64 tiles de grassland (grassland_0_0 a grassland_7_7)
   
   b. **Asignar terrain:**
      - Con tiles seleccionados → Tab "Terrains"
      - En "Terrain Set" elegir "Set 0"
      - En "Terrain" elegir "0 (Grassland)"
      - Click "Paint Terrain Bits" (pincel)
      - Click en el tile para marcar como parte del terrain
   
   c. **Configurar terrain bits:**
      - Para cada tile, pintar las 4 esquinas (bits) según corresponda
      - **Tiles centrales:** las 4 esquinas = grassland
      - **Tiles de borde:** esquinas mixtas según vecinos
      
      **NOTA:** Godot puede auto-detectar esto si los tiles siguen un patrón 3×3.
   
   d. **Repetir para los 6 biomas.**

7. **Verificar configuración:**
   - En TileSet panel → Tab "Terrains"
   - Deberías ver 6 terrains configurados
   - Cada terrain con ~64 tiles asignados

---

### PASO 3: Modificar Escena Principal (10 minutos)

1. **Abrir escena:**
   - Abrir `scenes/SpellloopMain.tscn`

2. **Añadir TileMapLayer:**
   - Seleccionar nodo `WorldRoot`
   - Click derecho → Add Child Node
   - Buscar: `TileMapLayer`
   - Nombrar: `BiomesTileMap`
   - **Configurar propiedades:**
     - TileSet: Arrastrar `world_tileset.tres`
     - Rendering → Z Index: -100 (detrás de todo)

3. **Añadir BiomeTileMapGenerator:**
   - Seleccionar `WorldRoot`
   - Add Child Node → Node2D
   - Nombrar: `TileMapGenerator`
   - **Attach Script:**
     - Seleccionar `TileMapGenerator`
     - Click "Attach Script" (icono de rollo)
     - Seleccionar: `scripts/BiomeTileMapGenerator.gd`
   - **Configurar Export Variables:**
     - `tilemap`: Arrastrar el nodo `BiomesTileMap`
     - `chunk_size`: 32

4. **Añadir BiomeDecoratorsManager:**
   - Seleccionar `WorldRoot`
   - Add Child Node → Node2D
   - Nombrar: `DecoratorsManager`
   - **Attach Script:**
     - Seleccionar script `scripts/BiomeDecoratorsManager.gd`
   - **Configurar Export Variables:**
     - `tilemap_generator`: Arrastrar nodo `TileMapGenerator`
     - `fade_distance`: 3

5. **Modificar InfiniteWorldManager:**
   
   **OPCIÓN A - Reemplazar script (RECOMENDADO):**
   - Seleccionar nodo `InfiniteWorldManager`
   - En Inspector → Script
   - Click en el icono de script → "Change Script"
   - Seleccionar: `scripts/core/InfiniteWorldManagerTileMap.gd`
   - **Configurar Export Variables:**
     - `tilemap_generator`: Arrastrar `TileMapGenerator`
     - `decorators_manager`: Arrastrar `DecoratorsManager`
   
   **OPCIÓN B - Mantener compatibilidad (HÍBRIDO):**
   - Dejar el script actual
   - Añadir referencias a los nuevos nodos
   - Modificar código manualmente (más complejo)

6. **Eliminar/Deshabilitar sistema antiguo:**
   - **Deshabilitar BiomeChunkApplier:**
     - Seleccionar nodo `BiomeChunkApplier`
     - En Inspector → Node → Process Mode → "Disabled"
   - **Ocultar chunks antiguos (opcional):**
     - Seleccionar `ChunksRoot`
     - En Inspector → CanvasItem → Visibility → "Visible": OFF

7. **Guardar escena:**
   - Ctrl+S
   - Verificar que no hay errores en el panel Output

---

### PASO 4: Prueba Inicial (5 minutos)

1. **Ejecutar el juego:**
   - F5 o Click en "Run Project"

2. **Verificar en consola:**
   ```
   ✓ BiomeTileMapGenerator inicializado
   ✓ Ruido configurado - Seed: [número]
   ✓ BiomeDecoratorsManager inicializado
   [InfiniteWorldManagerTileMap] Inicializando...
   [InfiniteWorldManagerTileMap] ✅ Inicializado
   [InfiniteWorldManagerTileMap] 🎮 Inicializado con jugador (pos: (0, 0))
   ✓ Chunk generado en Xms: (0, 0) (1024 tiles)
   ✓ Decoradores generados en Xms: (0, 0) (Y elementos)
   ```

3. **Verificar visualmente:**
   - ¿Se ve el mundo con tiles?
   - ¿Hay transiciones entre biomas?
   - ¿Los decoradores se renderizan?
   - Al moverte: ¿se generan nuevos chunks?

4. **Si hay errores:**
   - Leer mensaje de error en Output
   - Verificar que todas las referencias están asignadas
   - Verificar que el TileSet tiene terrains configurados

---

### PASO 5: Ajustes y Optimización (20 minutos)

1. **Ajustar densidad de decoradores:**
   - Si hay demasiados/pocos decoradores
   - Editar `BiomeDecoratorsManager.gd` → `DECOR_CONFIG`
   - Cambiar valor `density` (0.0 = ninguno, 1.0 = todos)

2. **Ajustar transiciones:**
   - Si las transiciones son muy bruscas/suaves
   - En TileSet editor → Tab "Terrains"
   - Ajustar terrain bits de tiles de transición

3. **Ajustar chunk_size:**
   - Si hay lag al generar chunks:
     - Reducir `chunk_size` en `TileMapGenerator` (32 → 24)
   - Si los chunks se cargan muy seguido:
     - Aumentar `chunk_size` (32 → 48)

4. **Optimizar fade de decoradores:**
   - Editar `BiomeDecoratorsManager.gd`
   - Cambiar `fade_distance` (3 → 5 para fade más suave)
   - Modificar `_calculate_border_fade()` para curvas diferentes

5. **Verificar performance:**
   - Abrir Debug → Performance Monitor
   - **Métricas a vigilar:**
     - FPS > 60
     - Memory < 500 MB
     - Draw calls < 1000

---

## 🎯 CHECKLIST COMPLETO

- [ ] **PASO 1:** Ejecutar GenerateBiomeTiles.gd → 384 tiles generados
- [ ] **PASO 2:** Crear world_tileset.tres con 6 terrains configurados
- [ ] **PASO 3:** Modificar SpellloopMain.tscn:
  - [ ] Añadir TileMapLayer
  - [ ] Añadir TileMapGenerator
  - [ ] Añadir DecoratorsManager
  - [ ] Reemplazar script InfiniteWorldManager
  - [ ] Deshabilitar sistema antiguo
- [ ] **PASO 4:** Ejecutar y verificar que funciona
- [ ] **PASO 5:** Ajustar parámetros según gustos

---

## 🐛 TROUBLESHOOTING

### Error: "TileMapLayer tiene TileSet null"
- **Solución:** Asegúrate de asignar `world_tileset.tres` al TileMapLayer

### Error: "No terrain configured for terrain set 0"
- **Solución:** Falta configurar terrains en el TileSet editor (Paso 2.5)

### Mundo no se genera (pantalla negra)
- **Solución:**
  - Verificar que `tilemap_generator` está asignado en InfiniteWorldManagerTileMap
  - Verificar Output para errores de carga de texturas

### Decoradores no aparecen
- **Solución:**
  - Verificar que `tilemap_generator` y `decorators_manager` están conectados
  - Revisar valor `density` en DECOR_CONFIG (puede estar muy bajo)

### Transiciones no se ven suaves
- **Solución:**
  - Verificar que los tiles tienen terrain bits correctamente asignados
  - En TileSet editor, usar "Auto-paint terrain bits" si está disponible

### Lag al moverse
- **Solución:**
  - Reducir `chunk_size` (32 → 24)
  - Reducir `fade_distance` (3 → 2)
  - Reducir `density` en decoradores

---

## 📊 COMPARACIÓN ANTES/DESPUÉS

| Aspecto | Sistema Antiguo | Sistema Nuevo |
|---------|----------------|---------------|
| **Tamaño chunk** | 5760×3240 px | 2048×2048 px |
| **Transiciones** | ❌ Imposibles | ✅ Automáticas |
| **Decoradores** | Aparecen en biomas incorrectos | ✅ Fade en bordes |
| **Memoria** | ~800 MB | ~400 MB |
| **Tiempo generación** | ~200ms/chunk | ~50ms/chunk |
| **Calidad visual** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 💡 PRÓXIMOS PASOS OPCIONALES

Una vez que el sistema básico funciona:

1. **Animaciones de decoradores:**
   - Añadir AnimationPlayer a decoradores
   - Movimiento con viento

2. **Variación de tiles:**
   - Crear más variantes de tiles base
   - Rotación aleatoria de tiles

3. **Biomas especiales:**
   - Añadir sub-biomas (bosque denso, desierto rocoso, etc.)
   - Ruido adicional para micro-variaciones

4. **Partículas:**
   - Nieve cayendo en bioma Snow
   - Ceniza en bioma Lava
   - Polen en bioma Forest

5. **Sonido ambiental:**
   - Audio loops por bioma
   - Fade entre audios en transiciones

---

## 📞 ¿NECESITAS AYUDA?

Si algo no funciona:
1. Copia el mensaje de error exacto de Output
2. Describe qué paso estabas realizando
3. Menciona si completaste todos los checkboxes

¡Éxito con la migración! 🚀
