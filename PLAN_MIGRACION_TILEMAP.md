# 🗺️ PLAN DE MIGRACIÓN A TILEMAP - SPELLLOOP

## 📊 ESTADO ACTUAL

### Arquitectura Existente
```
Sistema de Chunks (ACTUAL)
├─ BiomeChunkApplier.gd
├─ InfiniteWorldManager.gd  
├─ Chunks de 3840×2160
└─ Texturas: 512×512 (base + 5 decor por bioma)

Biomas Disponibles:
✅ Grassland (verde)
✅ Desert (arena)
✅ Forest (bosque)
✅ ArcaneWastes (púrpura)
✅ Lava (rojo)
✅ Snow (blanco)
```

## 🎯 MIGRACIÓN A TILEMAP (3-4 HORAS)

### FASE 1: Preparar TileSet (45 min)

**1.1 Crear TileSet Resource**
- Crear: `res://assets/tilesets/world_tileset.tres`
- Tamaño de tile: **64×64 píxeles** (óptimo para tu resolución)
- Configurar atlas para cada bioma

**1.2 Importar Texturas Base como Tiles**
```
Grassland base.png (512×512) → 8×8 tiles de 64×64
Desert base.png (512×512) → 8×8 tiles de 64×64
Forest base.png (512×512) → 8×8 tiles de 64×64
... etc para cada bioma
```

**1.3 Crear Terrain Sets**
```
Terrain Set 0: "Biomes"
├─ Terrain 0: Grassland (verde)
├─ Terrain 1: Desert (amarillo)
├─ Terrain 2: Forest (verde oscuro)
├─ Terrain 3: ArcaneWastes (púrpura)
├─ Terrain 4: Lava (rojo)
└─ Terrain 5: Snow (blanco)
```

**1.4 Configurar Terrain Bits**
Para cada tile, marcar sus 8 bits de terrain:
```
   TL  T  TR
    \ | /
  L - + - R    (T=Top, B=Bottom, L=Left, R=Right)
    / | \      (TL=TopLeft, TR=TopRight, etc.)
   BL  B  BR
```

### FASE 2: Crear Sistema de Generación Procedural (60 min)

**2.1 Nuevo Script: `BiomeTileMapGenerator.gd`**

```gdscript
extends Node
class_name BiomeTileMapGenerator

@export var tilemap_layer: TileMapLayer
@export var noise: FastNoiseLite
@export var world_seed: int = 12345
@export var chunk_size: int = 32  # tiles por chunk

# Rangos de noise para cada bioma
const BIOME_RANGES = {
    "lava": {"min": -1.0, "max": -0.6, "terrain_id": 4},
    "arcane_wastes": {"min": -0.6, "max": -0.3, "terrain_id": 3},
    "desert": {"min": -0.3, "max": -0.1, "terrain_id": 1},
    "grassland": {"min": -0.1, "max": 0.3, "terrain_id": 0},
    "forest": {"min": 0.3, "max": 0.6, "terrain_id": 2},
    "snow": {"min": 0.6, "max": 1.0, "terrain_id": 5}
}

func _ready():
    # Configurar noise
    noise.seed = world_seed
    noise.frequency = 0.02  # Más bajo = biomas más grandes
    noise.fractal_octaves = 4
    noise.fractal_gain = 0.5

func generate_chunk(chunk_x: int, chunk_y: int):
    """Generar chunk de tiles con terrains"""
    var cells_to_paint = {}
    
    # Para cada tile en el chunk
    for local_x in range(chunk_size):
        for local_y in range(chunk_size):
            # Coordenadas globales
            var global_x = chunk_x * chunk_size + local_x
            var global_y = chunk_y * chunk_size + local_y
            
            # Obtener valor de noise
            var noise_value = noise.get_noise_2d(global_x, global_y)
            
            # Determinar bioma según noise
            var terrain_id = get_terrain_for_noise(noise_value)
            
            # Añadir a lista para pintar con terrains
            var tile_pos = Vector2i(global_x, global_y)
            if not cells_to_paint.has(terrain_id):
                cells_to_paint[terrain_id] = []
            cells_to_paint[terrain_id].append(tile_pos)
    
    # Pintar todos los tiles con terrain system
    for terrain_id in cells_to_paint:
        tilemap_layer.set_cells_terrain_connect(
            0,  # layer
            cells_to_paint[terrain_id],  # cells
            0,  # terrain_set
            terrain_id,  # terrain
            false  # ignore_empty_terrains
        )

func get_terrain_for_noise(value: float) -> int:
    """Convertir valor de noise a terrain_id"""
    for biome in BIOME_RANGES:
        var range_data = BIOME_RANGES[biome]
        if value >= range_data["min"] and value < range_data["max"]:
            return range_data["terrain_id"]
    return 0  # Default: Grassland

func unload_chunk(chunk_x: int, chunk_y: int):
    """Eliminar tiles de un chunk"""
    for local_x in range(chunk_size):
        for local_y in range(chunk_size):
            var global_x = chunk_x * chunk_size + local_x
            var global_y = chunk_y * chunk_size + local_y
            tilemap_layer.erase_cell(Vector2i(global_x, global_y))
```

**2.2 Integrar con InfiniteWorldManager**

Modificar `InfiniteWorldManager.gd` para usar TileMap:

```gdscript
# Reemplazar BiomeChunkApplier con BiomeTileMapGenerator
@onready var tilemap_generator = $BiomeTileMapGenerator
@onready var tilemap_layer = $TileMapLayer

func _generate_chunk(cx: int, cy: int):
    # Generar tiles con terrains
    tilemap_generator.generate_chunk(cx, cy)
    
    # Añadir decoradores ENCIMA del tilemap
    _place_decorators_for_chunk(cx, cy)

func _unload_chunk(cx: int, cy: int):
    tilemap_generator.unload_chunk(cx, cy)
    _remove_decorators_for_chunk(cx, cy)
```

### FASE 3: Sistema de Decoradores (45 min)

**3.1 Nuevo Script: `BiomeDecoratorsManager.gd`**

```gdscript
extends Node2D
class_name BiomeDecoratorsManager

@export var tilemap_layer: TileMapLayer
@export var decorators_config: Dictionary

var active_decorators = {}  # chunk_key -> [decorators]

func place_decorators_for_chunk(chunk_x: int, chunk_y: int):
    """Colocar decoradores sobre tiles del chunk"""
    var chunk_key = Vector2i(chunk_x, chunk_y)
    var decorators = []
    
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(chunk_key)
    
    # Para cada tile en el chunk
    for local_x in range(32):
        for local_y in range(32):
            var tile_pos = Vector2i(
                chunk_x * 32 + local_x,
                chunk_y * 32 + local_y
            )
            
            # Obtener bioma del tile
            var tile_data = tilemap_layer.get_cell_tile_data(tile_pos)
            if not tile_data:
                continue
            
            var biome_id = get_biome_from_tile(tile_data)
            
            # Probabilidad de decorador (ej: 10%)
            if rng.randf() > 0.1:
                continue
            
            # Crear decorador
            var decor = create_decorator(biome_id, rng)
            if decor:
                # Posición: centro del tile + offset random
                var world_pos = tilemap_layer.map_to_local(tile_pos)
                world_pos += Vector2(
                    rng.randf_range(-20, 20),
                    rng.randf_range(-20, 20)
                )
                decor.position = world_pos
                
                # Fade cerca de bordes de bioma
                var distance_to_border = get_distance_to_biome_border(tile_pos)
                if distance_to_border < 3:  # 3 tiles
                    decor.modulate.a = distance_to_border / 3.0
                
                add_child(decor)
                decorators.append(decor)
    
    active_decorators[chunk_key] = decorators

func get_distance_to_biome_border(tile_pos: Vector2i) -> int:
    """Calcular distancia al borde del bioma más cercano"""
    var center_data = tilemap_layer.get_cell_tile_data(tile_pos)
    if not center_data:
        return 999
    
    var center_biome = get_biome_from_tile(center_data)
    var min_distance = 999
    
    # Buscar en espiral hasta encontrar bioma diferente
    for radius in range(1, 10):
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                if abs(dx) != radius and abs(dy) != radius:
                    continue  # Solo bordes del cuadrado
                
                var check_pos = tile_pos + Vector2i(dx, dy)
                var check_data = tilemap_layer.get_cell_tile_data(check_pos)
                if not check_data:
                    continue
                
                if get_biome_from_tile(check_data) != center_biome:
                    min_distance = mini(min_distance, radius)
                    return min_distance
    
    return min_distance

func remove_decorators_for_chunk(chunk_x: int, chunk_y: int):
    """Eliminar decoradores de un chunk"""
    var chunk_key = Vector2i(chunk_x, chunk_y)
    if active_decorators.has(chunk_key):
        for decor in active_decorators[chunk_key]:
            decor.queue_free()
        active_decorators.erase(chunk_key)
```

### FASE 4: Estructura de Escena (30 min)

**4.1 Nueva Jerarquía en SpellloopMain.tscn**

```
SpellloopMain (Node2D)
├─ UI (CanvasLayer)
│  ├─ DebugLabel
│  └─ InfoLabel
│
└─ WorldRoot (Node2D)
   ├─ TileMapLayer (nuevo!)
   │  └─ [TileSet configurado con terrains]
   │
   ├─ BiomeTileMapGenerator (Node)
   │  └─ Script: res://scripts/core/BiomeTileMapGenerator.gd
   │
   ├─ DecoratorsRoot (Node2D)
   │  └─ Script: BiomeDecoratorsManager.gd
   │
   ├─ EnemiesRoot (Node2D)
   ├─ PickupsRoot (Node2D)
   └─ Camera2D
```

### FASE 5: Configuración del TileSet (60 min - LA MÁS IMPORTANTE)

**5.1 Crear tiles de transición**

Para cada bioma, necesitas crear tiles que conecten con otros biomas:

```
Ejemplo: Grassland → Desert

Tiles necesarios:
├─ Full Grassland (interior)
├─ Full Desert (interior)
├─ Grassland con borde Desert arriba
├─ Grassland con borde Desert abajo
├─ Grassland con borde Desert izquierda
├─ Grassland con borde Desert derecha
├─ Esquinas (4 variantes)
└─ ... etc (total ~15-20 tiles por par de biomas)
```

**5.2 Configurar terrain bits automáticamente**

Godot puede auto-configurar terrain bits si organizas bien el atlas:

```
En el TileSet editor:
1. Seleccionar tiles del mismo bioma
2. Click derecho → "Create Terrain"
3. Asignar color al terrain
4. Godot detecta automáticamente los bits
```

## 📦 RECURSOS NECESARIOS

### Herramientas para Crear Tiles de Transición

**Opción A: Automático (Recomendado)**
- Script GDScript que genera tiles de transición mezclando texturas
- Lo puedo crear para ti (10 min)

**Opción B: Manual**
- Aseprite / Photoshop para crear tiles manualmente
- ~2-3 horas de trabajo artístico

**Opción C: Usar texturas actuales**
- Dividir base.png (512×512) en grid 8×8 de 64×64
- Usar como están (sin transiciones perfectas pero funcional)

## 🚀 PASOS DE IMPLEMENTACIÓN

### DÍA 1: Setup Básico (2 horas)

1. ✅ Crear TileSet resource
2. ✅ Importar texturas base divididas en tiles
3. ✅ Crear terrain sets (6 biomas)
4. ✅ Configurar terrain bits básicos

### DÍA 2: Generación Procedural (2 horas)

5. ✅ Crear BiomeTileMapGenerator.gd
6. ✅ Configurar FastNoiseLite
7. ✅ Integrar con InfiniteWorldManager
8. ✅ Probar generación de chunks

### DÍA 3: Decoradores y Polish (2 horas)

9. ✅ Crear BiomeDecoratorsManager.gd
10. ✅ Implementar fade en bordes
11. ✅ Ajustar densidad por bioma
12. ✅ Testing y optimización

## 🎯 RESULTADO ESPERADO

Después de la migración tendrás:

✅ **Transiciones automáticas** entre biomas (engine hace el trabajo)
✅ **Performance mejorada** (~10x más rápido que chunks)
✅ **Código más simple** (menos 500 líneas)
✅ **Fácil de mantener** (añadir biomas = trivial)
✅ **Decoradores con fade** (desaparecen suavemente en bordes)
✅ **Colisiones integradas** (TileMap tiene colisiones built-in)

## ❓ DECISIONES QUE NECESITO

**1. Tamaño de Tile**
- Opción A: 64×64 (recomendado, balance perfecto)
- Opción B: 32×32 (más detalle, más tiles)
- Opción C: 128×128 (menos tiles, menos detalle)

**2. Tiles de Transición**
- Opción A: Generar automáticamente con script (rápido)
- Opción B: Crear manualmente pixel art (mejor calidad)
- Opción C: Sin transiciones smooth (más simple pero menos bonito)

**3. Mantener Sistema Actual**
- Opción A: Reemplazar completamente chunks
- Opción B: Coexistir (TileMap para terreno, chunks para fondos)

---

## 📞 SIGUIENTE PASO

**¿Qué prefieres?**

A) Empezar YA con implementación automática (elijo yo las opciones óptimas)
B) Revisar cada decisión primero
C) Ver un prototipo simple primero antes de migrar todo

Dime y empezamos! 🚀
