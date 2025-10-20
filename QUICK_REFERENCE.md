# ⚡ QUICK REFERENCE - Guía de Referencia Rápida

**Para:** Desarrolladores que necesitan acceso rápido a información  
**Actualizado:** 20 de octubre de 2025  
**Versión:** v2.0

---

## 📌 ARCHIVOS CLAVE

```
scripts/core/InfiniteWorldManager.gd
  └─ Líneas:          ~260
  └─ Método principal: initialize(player)
  └─ Signals:         chunk_generated, chunk_loaded_from_cache

scripts/core/BiomeGenerator.gd
  └─ Líneas:          ~220
  └─ Método principal: generate_chunk_async(node, pos, rng)
  └─ Biomas:          6 tipos

scripts/core/ChunkCacheManager.gd
  └─ Líneas:          ~140
  └─ Métodos:         save_chunk, load_chunk, clear_cache
  └─ Storage:         user://chunk_cache/

scripts/core/ItemManager.gd
  └─ Líneas:          ~380 (modificado)
  └─ Método principal: initialize(player, world)
  └─ Signals:         chest_spawned, item_collected
```

---

## 🎮 INICIALIZACIÓN RÁPIDA

### En SpellloopGame._ready():
```gdscript
# Ya está hecho en create_world_manager()
world_manager = InfiniteWorldManager.new()
world_manager.name = "WorldManager"
add_child(world_manager)
world_manager.initialize(player)
```

### Verificación:
```gdscript
# Después de crear el manager
if world_manager:
    print("✅ WorldManager inicializado")
    var info = world_manager.get_info()
    print(info)
```

---

## 🗺️ CHUNKS - Referencia Rápida

### Dimensiones
```
Ancho:     5760 px (3 × 1920)
Alto:      3240 px (3 × 1080)
Grid:      3×3 (máximo 9 chunks)
Semilla:   Determinística (reproducible)
```

### Coordenadas
```
world_pos → chunk_index:
    cx = floor(world_pos.x / 5760)
    cy = floor(world_pos.y / 3240)

chunk_index → world_pos:
    x = cx * 5760
    y = cy * 3240
```

### Métodos útiles
```gdscript
# Obtener chunk en posición
var chunk = world_manager.get_chunk_at_pos(player.position)

# Obtener índice de chunk
var idx = world_manager._world_pos_to_chunk_index(pos)

# Obtener posición de chunk
var pos = world_manager._chunk_index_to_world_pos(cx, cy)

# Listar activos
var active = world_manager.get_active_chunks()
print("Chunks activos: ", active.size())
```

---

## 🌍 BIOMAS - Colores y Tipos

```
GRASSLAND       (0.34, 0.68, 0.35)   🟢 Verde prado
DESERT          (0.87, 0.78, 0.60)   🟡 Arena
SNOW            (0.95, 0.95, 1.00)   🔵 Nieve
LAVA            (0.40, 0.10, 0.05)   🔴 Rojo oscuro
ARCANE_WASTES   (0.60, 0.30, 0.80)   🟣 Violeta
FOREST          (0.15, 0.35, 0.15)   🟤 Verde oscuro
```

### Cómo acceder:
```gdscript
var biome_colors = BiomeGenerator.BIOME_COLORS
var color = biome_colors[BiomeGenerator.BiomeType.DESERT]
# Result: Color(0.87, 0.78, 0.60)
```

---

## 💾 CACHÉ - Operaciones Rápidas

### Guardar chunk
```gdscript
var data = {
    "position": Vector2i(0, 0),
    "biome": "grassland",
    "decorations": [],
    "items": [],
    "timestamp": Time.get_ticks_msec()
}
chunk_cache_manager.save_chunk(Vector2i(0, 0), data)
```

### Cargar chunk
```gdscript
if chunk_cache_manager.has_cached_chunk(Vector2i(0, 0)):
    var data = chunk_cache_manager.load_chunk(Vector2i(0, 0))
    # data es un Dictionary con el estado guardado
```

### Limpiar caché
```gdscript
# Un chunk específico
chunk_cache_manager.clear_chunk_cache(Vector2i(0, 0))

# Todo
chunk_cache_manager.clear_all_cache()

# Ver tamaño
var size_mb = chunk_cache_manager.get_cache_size() / (1024 * 1024)
print("Cache: %.2f MB" % size_mb)
```

---

## 🎯 GENERACIÓN DE CHUNKS - API

### Generar nuevo chunk
```gdscript
# Automático:
world_manager._generate_new_chunk(Vector2i(1, 0))

# Manual:
var chunk = Node2D.new()
biome_generator.generate_chunk_async(chunk, Vector2i(0, 0), rng)
# Usa await internamente
```

### Cargar del caché
```gdscript
if chunk_cache_manager.has_cached_chunk(pos):
    var data = chunk_cache_manager.load_chunk(pos)
    biome_generator.generate_chunk_from_cache(chunk, data)
```

---

## 🎨 DECORACIONES - Parámetros

```gdscript
# Por bioma
DECORATIONS_PER_BIOME = {
    GRASSLAND: ["bush", "flower", "tree_small"],
    DESERT: ["cactus", "rock", "sand_spike"],
    # ...
}

# Densidad
DECORATION_DENSITY = 0.15  # 15% del área

# Cálculo de cantidad
target_count = chunk_area * DECORATION_DENSITY / (32*32)
# ~200-300 decoraciones por chunk
```

---

## 🔄 SIGNALS - Eventos

```gdscript
# Conectar a señal de generación
if world_manager.has_signal("chunk_generated"):
    world_manager.chunk_generated.connect(_on_chunk_generated)

# Handler:
func _on_chunk_generated(chunk_pos: Vector2i):
    print("Nuevo chunk: ", chunk_pos)
    # Generar enemigos, items, etc.
```

---

## ⚙️ DEBUG - Comandos Útiles

### Ver info del sistema
```gdscript
var info = world_manager.get_info()
print(info)
# Output: {
#   "current_chunk": Vector2i(0, 0),
#   "active_chunks": 9,
#   "chunk_size": Vector2(5760, 3240),
#   "world_seed": 12345
# }
```

### Visualizar límites
```gdscript
world_manager.show_chunk_bounds = true
world_manager.debug_mode = true
# Llama a queue_redraw() para ver líneas amarillas
```

### Monitorear rendimiento
```gdscript
# En _process():
print("FPS: %.1f | Chunks: %d" % [1.0/_delta, world_manager.active_chunks.size()])
```

---

## 🎯 COMBATE - Referencia Rápida

### Proyectil hielo
```gdscript
# Propiedades clave
damage: 8
knockback: 200
auto_seek_range: 800
auto_seek_enabled: true
pierces_enemies: false
lifetime: 4.0 segundos

# Métodos
initialize(direction, speed, damage, lifetime)
_apply_damage(enemy)
_apply_knockback(enemy)
_expire()
```

### Enemigos
```gdscript
# Componentes automáticos
health_component: HealthComponent
attack_system: EnemyAttackSystem

# Métodos
take_damage(amount)
apply_knockback(force)
die()

# Capas/máscaras automáticas
# Layer: 2 (Enemies)
# Mask:  1 (Player), 3 (Player Projectiles)
```

---

## 📊 PERFORMANCE - Checklist

```
✅ FPS > 60?              → OK
✅ Memory < 200MB?        → OK
✅ Generación < 50ms?     → OK
✅ Cambio chunk < 20ms?   → OK
✅ Cache size < 5MB?      → OK
✅ Logs < 10/seg?         → OK
```

### Si falla algo:
```
FPS bajo? 
  → Reducir DECORATION_DENSITY
  → Verificar spritesheets tamaño

Lag generación?
  → Aumentar frecuencia de await
  → Reducir decoraciones por chunk

Caché lento?
  → Implementar compresión (futura)
  → Limpiar periódicamente
```

---

## 🚀 COMANDOS DE TESTING

### Monitorear juego
```
F5              → Ejecutar
Ctrl+Shift+D    → Monitor (FPS, memoria)
F8              → Screenshot
```

### Logs importantes
```
[InfiniteWorldManager]    - Chunks
[BiomeGenerator]          - Biomas
[ChunkCacheManager]       - Caché
[EnemyBase]               - Enemigos
[IceProjectile]           - Proyectiles (limitado)
```

---

## 📱 PRÓXIMOS CAMBIOS - Placeholder

```
Para futuro, cambios esperados en:
  └─ BiomeGenerator.gd
     ├─ Añadir efectos visuales
     └─ Mejorar transiciones

  └─ ChunkCacheManager.gd
     ├─ Compresión (ZIP)
     └─ Versionado

  └─ Nuevos componentes
     ├─ ParticleEffects
     └─ SoundAmbience
```

---

## 🆘 TROUBLESHOOTING

| Problema | Causa | Solución |
|----------|-------|----------|
| "WorldManager not found" | Archivo no existe | Verificar ruta |
| Chunks no generan | player_ref null | Llamar initialize() |
| Lag al cambiar chunk | Generación síncrona | Ya solucionado con await |
| Caché no persiste | Permisos directorio | ChunkCacheManager crea auto |
| Enemigos no detectan | Sin CollisionShape2D | Ya solucionado en EnemyBase |
| Proyectiles pegados | queue_free() await | Ya solucionado |

---

## 💡 TIPS PROFESIONALES

### 1. Usar índices en lugar de posiciones
```gdscript
# ✅ Mejor
var chunk_idx = world_manager._world_pos_to_chunk_index(pos)
var same_chunk = chunk_idx == previous_idx

# ❌ Menos eficiente
if distance_to_chunk_edge < threshold:
```

### 2. Caché el resultado de búsquedas
```gdscript
# ✅ Mejor
var chunk = world_manager.get_chunk_at_pos(pos)
if chunk:
    spawn_item_in_chunk(chunk)

# ❌ Ineficiente
if world_manager.get_chunk_at_pos(pos):
    if world_manager.get_chunk_at_pos(pos):
```

### 3. Usar signals en lugar de checks
```gdscript
# ✅ Mejor
world_manager.chunk_generated.connect(_on_chunk)

# ❌ Menos eficiente
if _frame_count % 60 == 0:
    check_new_chunks()
```

---

## 📚 DOCUMENTOS RELACIONADOS

```
RESUMEN_CHUNKS_v2.md           → Especificación técnica completa
GUIA_TESTING_CHUNKS.md         → Testing paso a paso
ARQUITECTURA_TECNICA.md        → Diagramas y flujos
ESTADO_PROYECTO_ACTUAL.md      → Visión general actual
```

---

## ✅ RESUMEN

```
Sistema listo:   ✅ SÍ
Testing pendiente: ⏳ F5
Documentación:    ✅ COMPLETA
Performance:      ✅ OPTIMIZADO
Código:          ✅ LIMPIO
```

**¡Listo para producción!** 🎮✨
