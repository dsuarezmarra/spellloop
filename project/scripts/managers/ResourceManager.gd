# ResourceManager.gd
# Gestor centralizado de recursos para evitar tirones por carga en tiempo real.
# Se encarga de pre-cargar texturas, escenas y shaders.
# 
# OPTIMIZACIÓN CRÍTICA: Precachea regiones de sprites para evitar análisis
# pixel-by-pixel durante gameplay (antes: ~80-150ms por spritesheet)

extends Node

# Cache de regiones de sprites (para AnimatedEnemySprite optimization)
# Key: path del spritesheet, Value: Array[Rect2]
var sprite_region_cache: Dictionary = {}

# Cache de texturas pre-procesadas para evitar re-análisis
var texture_cache: Dictionary = {}

# Métricas de precarga para instrumentación
var precache_stats: Dictionary = {
	"sprites_processed": 0,
	"total_time_ms": 0,
	"cache_hits": 0,
	"cache_misses": 0
}

# Recursos a pre-cargar 
const PRELOAD_PATHS = [
	"res://scenes/pickups/CoinPickup.tscn",
	# FloatingText uses class_name + lazy singleton, no .tscn needed
	"res://scripts/enemies/EnemyBase.gd",
	"res://scripts/components/HealthComponent.gd",
	"res://scripts/components/AnimatedEnemySprite.gd"
]

# Mapeo completo enemy_id -> sprite paths (sincronizado con EnemyBase._get_spritesheet_path)
const ENEMY_SPRITESHEET_PATHS = [
	# Tier 1
	"res://assets/sprites/enemies/tier_1/esqueleto_aprendiz_spritesheet.png",
	"res://assets/sprites/enemies/tier_1/duende_sombrio_spritesheet.png",
	"res://assets/sprites/enemies/tier_1/slime_arcano_spritesheet.png",
	"res://assets/sprites/enemies/tier_1/murcielago_etereo_spritesheet.png",
	"res://assets/sprites/enemies/tier_1/arana_venenosa_spritesheet.png",
	# Tier 2
	"res://assets/sprites/enemies/tier_2/guerrero_espectral_spritesheet.png",
	"res://assets/sprites/enemies/tier_2/lobo_de_cristal_spritesheet.png",
	"res://assets/sprites/enemies/tier_2/golem_runico_spritesheet.png",
	"res://assets/sprites/enemies/tier_2/hechicero_desgastado_spritesheet.png",
	"res://assets/sprites/enemies/tier_2/sombra_flotante_spritesheet.png",
	# Tier 3
	"res://assets/sprites/enemies/tier_3/caballero_del_vacio_spritesheet.png",
	"res://assets/sprites/enemies/tier_3/serpiente_de_fuego_spritesheet.png",
	"res://assets/sprites/enemies/tier_3/elemental_de_hielo_spritesheet.png",
	"res://assets/sprites/enemies/tier_3/mago_abismal_spritesheet.png",
	"res://assets/sprites/enemies/tier_3/corruptor_alado_spritesheet.png",
	# Tier 4
	"res://assets/sprites/enemies/tier_4/titan_arcano_spritesheet.png",
	"res://assets/sprites/enemies/tier_4/senor_de_las_llamas_spritesheet.png",
	"res://assets/sprites/enemies/tier_4/reina_del_hielo_spritesheet.png",
	"res://assets/sprites/enemies/tier_4/archimago_perdido_spritesheet.png",
	"res://assets/sprites/enemies/tier_4/dragon_etereo_spritesheet.png",
	# Bosses
	"res://assets/sprites/enemies/bosses/el_conjurador_primigenio_spritesheet.png",
	"res://assets/sprites/enemies/bosses/el_corazon_del_vacio_spritesheet.png",
	"res://assets/sprites/enemies/bosses/el_guardian_de_runas_spritesheet.png",
	"res://assets/sprites/enemies/bosses/minotauro_de_fuego_spritesheet.png",
]

func _ready() -> void:
	# Registrar como singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("resource_manager")
	
	# Iniciar pre-carga en background (o frame a frame)
	_preload_assets.call_deferred()

func _preload_assets() -> void:
	# Debug desactivado: print("📦 [ResourceManager] Iniciando pre-carga de assets...")
	var start_time = Time.get_ticks_msec()
	
	for path in PRELOAD_PATHS:
		if ResourceLoader.exists(path):
			var res = load(path)
			# Mantener referencia para evitar que se descargue
			texture_cache[path] = res
			
	# Pre-cargar sprites de enemigos y calcular regiones
	# CRÍTICO: Esto elimina el stutter de 80-150ms en el primer spawn de cada enemigo
	_preload_common_enemies()
	
	var time = Time.get_ticks_msec() - start_time
	precache_stats["total_time_ms"] = time
	# Debug desactivado: print("📦 [ResourceManager] Pre-carga completada en %dms (%d sprites procesados)" % [time, precache_stats["sprites_processed"]])

func _preload_common_enemies() -> void:
	"""
	Precarga todos los spritesheets de enemigos y calcula las regiones de cada pose.
	Esto evita el análisis pixel-by-pixel durante gameplay que causaba stuttering.
	
	Complejidad: O(n * width * height) donde n = número de sprites
	Tiempo típico: ~200-400ms total en la pantalla de carga vs ~100ms por sprite durante gameplay
	"""
	for path in ENEMY_SPRITESHEET_PATHS:
		if not ResourceLoader.exists(path):
			continue
		
		# Cargar y cachear textura
		var texture = load(path) as Texture2D
		if not texture:
			continue
		texture_cache[path] = texture
		
		# Calcular regiones de sprites (análisis costoso, solo una vez)
		var regions = _detect_sprite_regions_for_texture(texture)
		if regions.size() == 3:
			sprite_region_cache[path] = regions
		else:
			# Fallback a división simple si la detección falla
			var img = texture.get_image()
			var simple_width = float(img.get_width()) / 3.0
			var img_height = img.get_height()
			sprite_region_cache[path] = [
				Rect2(0, 0, simple_width, img_height),
				Rect2(simple_width, 0, simple_width, img_height),
				Rect2(simple_width * 2, 0, simple_width, img_height)
			]
		
		precache_stats["sprites_processed"] += 1

func _detect_sprite_regions_for_texture(texture: Texture2D) -> Array[Rect2]:
	"""
	Detectar las 3 regiones de sprites en la textura analizando el canal alpha.
	Réplica de AnimatedEnemySprite._detect_sprite_regions para usar en precarga.
	"""
	var img = texture.get_image()
	var width = img.get_width()
	var height = img.get_height()
	
	# Encontrar columnas con contenido (alpha > 0)
	var columns_with_content: Array[int] = []
	for x in range(width):
		var has_content = false
		for y in range(height):
			if img.get_pixel(x, y).a > 0.01:
				has_content = true
				break
		if has_content:
			columns_with_content.append(x)
	
	if columns_with_content.is_empty():
		return []
	
	# Agrupar columnas consecutivas en regiones
	var regions: Array[Rect2] = []
	var region_start = columns_with_content[0]
	var region_end = columns_with_content[0]
	
	for i in range(1, columns_with_content.size()):
		var col = columns_with_content[i]
		# Si hay un gap de más de 4 píxeles, es una nueva región
		if col - region_end > 4:
			var y_bounds = _find_vertical_bounds_for_image(img, region_start, region_end)
			regions.append(Rect2(region_start, y_bounds.x, region_end - region_start + 1, y_bounds.y - y_bounds.x + 1))
			region_start = col
		region_end = col
	
	# Agregar la última región
	var y_bounds_final = _find_vertical_bounds_for_image(img, region_start, region_end)
	regions.append(Rect2(region_start, y_bounds_final.x, region_end - region_start + 1, y_bounds_final.y - y_bounds_final.x + 1))
	
	return regions

func _find_vertical_bounds_for_image(img: Image, col_start: int, col_end: int) -> Vector2:
	"""Encontrar el bounding box vertical para un rango de columnas"""
	var height = img.get_height()
	var min_y = height
	var max_y = 0
	
	for x in range(col_start, col_end + 1):
		for y in range(height):
			if img.get_pixel(x, y).a > 0.01:
				min_y = min(min_y, y)
				max_y = max(max_y, y)
	
	return Vector2(min_y, max_y)

# === API PÚBLICA ===

func get_cached_regions(path: String) -> Array:
	"""
	Obtener regiones cacheadas para un spritesheet.
	Returns: Array[Rect2] con las 3 regiones, o vacío si no existe en cache.
	"""
	if sprite_region_cache.has(path):
		precache_stats["cache_hits"] += 1
		return sprite_region_cache[path]
	precache_stats["cache_misses"] += 1
	return []

func cache_regions(path: String, regions: Array) -> void:
	"""Cachear regiones calculadas (llamado desde AnimatedEnemySprite si no existían)"""
	sprite_region_cache[path] = regions

func get_resource(path: String) -> Resource:
	"""Obtener recurso de cache o cargar si no existe"""
	if texture_cache.has(path):
		return texture_cache[path]
	
	if ResourceLoader.exists(path):
		var res = load(path)
		texture_cache[path] = res
		return res
	return null

func get_precache_stats() -> Dictionary:
	"""Obtener métricas de precarga para instrumentación/debugging"""
	return precache_stats.duplicate()

func is_sprite_precached(path: String) -> bool:
	"""Verificar si un sprite está precacheado (útil para tests)"""
	return sprite_region_cache.has(path) and texture_cache.has(path)
