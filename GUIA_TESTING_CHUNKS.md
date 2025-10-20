# 🧪 GUÍA RÁPIDA DE TESTING - SISTEMA DE CHUNKS v2.0

## ⚡ INICIO RÁPIDO

### 1. Verificar que los archivos están en su lugar
```
✅ c:\Users\dsuarez1\git\spellloop\project\scripts\core\InfiniteWorldManager.gd
✅ c:\Users\dsuarez1\git\spellloop\project\scripts\core\BiomeGenerator.gd
✅ c:\Users\dsuarez1\git\spellloop\project\scripts\core\ChunkCacheManager.gd
```

### 2. Ejecutar el juego (F5 en Godot)
- El juego debe iniciarse sin errores
- Debe cargar los 9 chunks iniciales (3×3)
- Verificar console para logs de inicialización

---

## 🔍 TESTS DE VALIDACIÓN

### TEST 1: Generación de chunks
**Objetivo:** Verificar que se generan chunks al moverse

**Pasos:**
1. Ejecutar juego (F5)
2. Buscar en console:
   ```
   [InfiniteWorldManager] ✅ Inicializado (chunk_size: (5760, 3240))
   [InfiniteWorldManager] 🎮 Sistema de chunks inicializado
   ```
3. Mover jugador hacia norte (W)
4. Cuando alcance el borde, buscar logs similares a:
   ```
   [InfiniteWorldManager] ✨ Chunk -1,0 generado
   ```

**Criterio de éxito:**
- ✅ Se generan nuevos chunks sin lag
- ✅ Se ven biomas diferentes
- ✅ No hay tirones visuales

---

### TEST 2: Caché persistente
**Objetivo:** Verificar que chunks se guardan y cargan correctamente

**Pasos:**
1. Ejecutar juego
2. Recopilar un cofre si es posible (notar posición)
3. Alejarse significativamente del chunk (>8000 px)
4. Volver al chunk original
5. Verificar console para:
   ```
   [InfiniteWorldManager] 📂 Chunk 0,0 cargado del caché
   [ChunkCacheManager] 📂 Chunk 0,0 cargado del caché
   ```

**Criterio de éxito:**
- ✅ El cofre aparece en la misma posición
- ✅ Se cargan del caché (logs visibles)

---

### TEST 3: Rendimiento
**Objetivo:** Verificar que no hay tirones

**Pasos:**
1. Ejecutar juego
2. Abrir Monitor de rendimiento (Ctrl+Shift+D)
3. Mover rápidamente entre chunks (presionar direcciones)
4. Observar FPS durante 30 segundos
5. Verificar console para errores

**Criterio de éxito:**
- ✅ FPS > 50 consistentemente
- ✅ Sin tirones visibles
- ✅ Sin errores en console

---

### TEST 4: Biomas y decoraciones
**Objetivo:** Verificar variedad de biomas

**Pasos:**
1. Ejecutar juego
2. Mover a través de varios chunks
3. Observar cambios de color del suelo
4. Buscar decoraciones (arbustos, cactus, etc.)
5. Verificar transiciones suaves entre biomas

**Criterio de éxito:**
- ✅ Se ven al menos 3 biomas diferentes
- ✅ Colores cambian gradualmente
- ✅ Hay decoraciones visuales
- ✅ Decoraciones no causan colisión

---

### TEST 5: Límite de chunks activos
**Objetivo:** Verificar que solo hay 9 chunks activos

**Pasos:**
1. Ejecutar juego
2. Mover jugador lentamente en línea recta
3. Monitorear console
4. Buscar logs de destrucción:
   ```
   [InfiniteWorldManager] 🗑️ Chunk X,Y descargado
   ```

**Criterio de éxito:**
- ✅ Solo 9 chunks activos máximo
- ✅ Chunks lejanos se descargan
- ✅ Sin memory leaks (observar RAM)

---

## 📊 LOGS ESPERADOS EN CONSOLE

### Al iniciar
```
[InfiniteWorldManager] Inicializando...
[BiomeGenerator] ✅ Inicializado
[ChunkCacheManager] ✅ Inicializado (dir: user://chunk_cache/)
[InfiniteWorldManager] BiomeGenerator cargado
[InfiniteWorldManager] ChunkCacheManager cargado
[InfiniteWorldManager] ✅ Inicializado (chunk_size: (5760, 3240))
[InfiniteWorldManager] 🎮 Sistema de chunks inicializado
```

### Al generar chunks
```
[InfiniteWorldManager] ✨ Chunk 0,0 generado
[InfiniteWorldManager] 💾 Chunk 0,0 guardado en caché
```

### Al cargar del caché
```
[InfiniteWorldManager] 📂 Chunk 0,0 cargado del caché
[ChunkCacheManager] 📂 Chunk 0,0 cargado del caché
```

### Al descargar chunks
```
[InfiniteWorldManager] 🗑️ Chunk -1,-1 descargado
```

---

## 🔧 DEBUG MODE

### Activar visualización de límites de chunks
Agregar en `_ready()` de SpellloopGame:
```gdscript
if world_manager:
    world_manager.show_chunk_bounds = true
    world_manager.debug_mode = true
```

Esto mostrará líneas amarillas alrededor de los límites de chunks.

---

## ⚠️ PROBLEMAS COMUNES Y SOLUCIONES

### Problema: "InfiniteWorldManager not found"
**Causa:** El archivo no está en la ruta correcta  
**Solución:** Verificar que existe `res://scripts/core/InfiniteWorldManager.gd`

### Problema: Chunks no se generan
**Causa:** player_ref es null  
**Solución:** Verificar que `world_manager.initialize(player)` se llama en SpellloopGame

### Problema: Lag al generar chunks
**Causa:** Generación síncrona de decoraciones  
**Solución:** Ya está arreglado con `await`, verificar logs

### Problema: Caché no funciona
**Causa:** Directorio user://chunk_cache/ no existe  
**Solución:** ChunkCacheManager lo crea automáticamente en `_ready()`

---

## 📈 MÉTRICAS A MONITOREAR

- **FPS:** Debe ser > 50 en todo momento
- **Memoria:** < 200 MB
- **Tiempo generación chunk:** < 50ms
- **Tamaño caché:** < 5 MB por chunk

---

## ✅ CONCLUSIÓN

El sistema de chunks está **listo para testing completo**.

**Próximos pasos:**
1. Ejecutar juego con F5
2. Validar los 5 tests anteriores
3. Reportar resultados
4. Ajustar parámetros según sea necesario

¡A probar! 🎮✨
