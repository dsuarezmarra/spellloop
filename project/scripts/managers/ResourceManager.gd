# ResourceManager.gd
# Gestor centralizado de recursos para evitar tirones por carga en tiempo real.
# Se encarga de pre-cargar texturas, escenas y shaders.

extends Node

# Cache de regiones de sprites (para AnimatedEnemySprite optimization)
# Key: path del spritesheet, Value: Array[Rect2]
var sprite_region_cache: Dictionary = {}

# Cache de texturas pre-procesadas para evitar re-análisis
var texture_cache: Dictionary = {}

# Recursos a pre-cargar 
const PRELOAD_PATHS = [
    "res://scenes/pickups/CoinPickup.tscn",
    "res://scenes/ui/FloatingText.tscn",
    "res://scripts/enemies/EnemyBase.gd",
    "res://scripts/components/HealthComponent.gd",
    "res://scripts/components/AnimatedEnemySprite.gd"
    # Añadir sprites comunes aquí si se requiere
]

func _ready() -> void:
    # Registrar como singleton
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group("resource_manager")
    
    # Iniciar pre-carga en background (o frame a frame)
    _preload_assets.call_deferred()

func _preload_assets() -> void:
    print("📦 [ResourceManager] Iniciando pre-carga de assets...")
    var start_time = Time.get_ticks_msec()
    
    for path in PRELOAD_PATHS:
        if ResourceLoader.exists(path):
            var res = load(path)
            # Mantener referencia para evitar que se descargue
            texture_cache[path] = res
            
    # Pre-cargar sprites de enemigos comunes (si hay una lista conocida)
    # Esto evita el lag de análisis de imagen en el primer spawn
    _preload_common_enemies()
    
    var time = Time.get_ticks_msec() - start_time
    print("📦 [ResourceManager] Pre-carga completada en %dms" % time)

func _preload_common_enemies() -> void:
    # Obtener lista de enemigos básicos del EnemyDatabase si es posible
    # Por ahora hardcodeamos algunos comunes si sabemos sus rutas
    pass

# API para AnimatedEnemySprite
func get_cached_regions(path: String) -> Array:
    if sprite_region_cache.has(path):
        return sprite_region_cache[path]
    return []

func cache_regions(path: String, regions: Array) -> void:
    sprite_region_cache[path] = regions

func get_resource(path: String) -> Resource:
    if texture_cache.has(path):
        return texture_cache[path]
    
    if ResourceLoader.exists(path):
        var res = load(path)
        texture_cache[path] = res
        return res
    return null
