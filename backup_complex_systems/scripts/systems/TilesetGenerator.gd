# TilesetGenerator.gd
# Generates tileset assets programmatically for different biomes
# Creates tile patterns and textures for level generation

extends Node

signal tileset_generated(biome: String, tileset: TileSet)

# Tile types
enum TileType {
	FLOOR,
	WALL,
	DOOR,
	ENTRANCE,
	EXIT,
	OBSTACLE,
	DECORATION,
	HAZARD
}

# Biome definitions
const BIOME_CONFIGS = {
	"fire_caverns": {
		"primary_color": Color(0.8, 0.2, 0.1),
		"secondary_color": Color(0.6, 0.4, 0.0),
		"accent_color": Color(1.0, 0.6, 0.0),
		"texture_pattern": "volcanic"
	},
	"ice_peaks": {
		"primary_color": Color(0.7, 0.9, 1.0),
		"secondary_color": Color(0.4, 0.6, 0.8),
		"accent_color": Color(0.9, 0.95, 1.0),
		"texture_pattern": "crystalline"
	},
	"shadow_realm": {
		"primary_color": Color(0.1, 0.05, 0.2),
		"secondary_color": Color(0.2, 0.1, 0.3),
		"accent_color": Color(0.4, 0.2, 0.6),
		"texture_pattern": "dark"
	},
	"crystal_gardens": {
		"primary_color": Color(0.6, 0.8, 0.9),
		"secondary_color": Color(0.4, 0.7, 0.5),
		"accent_color": Color(0.8, 0.9, 0.7),
		"texture_pattern": "geometric"
	},
	"forest": {
		"primary_color": Color(0.2, 0.6, 0.1),
		"secondary_color": Color(0.4, 0.3, 0.1),
		"accent_color": Color(0.6, 0.8, 0.3),
		"texture_pattern": "organic"
	},
	"desert": {
		"primary_color": Color(0.9, 0.8, 0.5),
		"secondary_color": Color(0.7, 0.6, 0.3),
		"accent_color": Color(0.8, 0.7, 0.4),
		"texture_pattern": "sandy"
	}
}

# Generated tileset cache
var tileset_cache: Dictionary = {}

func _ready() -> void:
	"""Initialize tileset generator"""
	print("[TilesetGenerator] Tileset Generator initialized")

func generate_biome_tileset(biome: String) -> TileSet:
	"""Generate complete tileset for a biome"""
	if tileset_cache.has(biome):
		return tileset_cache[biome]
	
	if not BIOME_CONFIGS.has(biome):
		print("[TilesetGenerator] Warning: Unknown biome '%s', using default" % biome)
		biome = "forest"
	
	var config = BIOME_CONFIGS[biome]
	var tileset = TileSet.new()
	
	# Generate tiles for each type
	_add_floor_tiles(tileset, config)
	_add_wall_tiles(tileset, config)
	_add_door_tiles(tileset, config)
	_add_entrance_exit_tiles(tileset, config)
	_add_obstacle_tiles(tileset, config)
	_add_decoration_tiles(tileset, config)
	_add_hazard_tiles(tileset, config)
	
	tileset_cache[biome] = tileset
	tileset_generated.emit(biome, tileset)
	
	print("[TilesetGenerator] Generated tileset for biome: %s" % biome)
	return tileset

func generate_tile_texture(tile_type: TileType, biome_config: Dictionary, variant: int = 0) -> ImageTexture:
	"""Generate texture for a specific tile type"""
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)
	
	var primary_color = biome_config.get("primary_color", Color.WHITE)
	var secondary_color = biome_config.get("secondary_color", Color.GRAY)
	var accent_color = biome_config.get("accent_color", Color.LIGHT_GRAY)
	var pattern = biome_config.get("texture_pattern", "organic")
	
	match tile_type:
		TileType.FLOOR:
			_generate_floor_texture(image, primary_color, secondary_color, pattern, variant)
		TileType.WALL:
			_generate_wall_texture(image, secondary_color, accent_color, pattern, variant)
		TileType.DOOR:
			_generate_door_texture(image, primary_color, accent_color, pattern)
		TileType.ENTRANCE:
			_generate_entrance_texture(image, accent_color, primary_color)
		TileType.EXIT:
			_generate_exit_texture(image, accent_color, secondary_color)
		TileType.OBSTACLE:
			_generate_obstacle_texture(image, secondary_color, primary_color, variant)
		TileType.DECORATION:
			_generate_decoration_texture(image, accent_color, primary_color, pattern, variant)
		TileType.HAZARD:
			_generate_hazard_texture(image, Color.RED, primary_color, variant)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

# Private tileset generation methods
func _add_floor_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add floor tiles to tileset"""
	for variant in range(4):  # Create 4 floor variants
		var tile_id = TileType.FLOOR * 10 + variant
		var texture = generate_tile_texture(TileType.FLOOR, config, variant)
		
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0, 0))
		
		tileset.add_source(source, tile_id)

func _add_wall_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add wall tiles to tileset"""
	for variant in range(3):  # Wall variants
		var tile_id = TileType.WALL * 10 + variant
		var texture = generate_tile_texture(TileType.WALL, config, variant)
		
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0, 0))
		
		# Add collision
		var tile_data = source.get_tile_data(Vector2i(0, 0), 0)
		if tile_data:
			var collision = tile_data.get_collision_layer(0)
			var polygon = PackedVector2Array([
				Vector2(0, 0), Vector2(64, 0), Vector2(64, 64), Vector2(0, 64)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)
		
		tileset.add_source(source, tile_id)

func _add_door_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add door tiles to tileset"""
	var tile_id = TileType.DOOR * 10
	var texture = generate_tile_texture(TileType.DOOR, config)
	
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(64, 64)
	source.create_tile(Vector2i(0, 0))
	
	tileset.add_source(source, tile_id)

func _add_entrance_exit_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add entrance and exit tiles to tileset"""
	# Entrance
	var entrance_id = TileType.ENTRANCE * 10
	var entrance_texture = generate_tile_texture(TileType.ENTRANCE, config)
	
	var entrance_source = TileSetAtlasSource.new()
	entrance_source.texture = entrance_texture
	entrance_source.texture_region_size = Vector2i(64, 64)
	entrance_source.create_tile(Vector2i(0, 0))
	
	tileset.add_source(entrance_source, entrance_id)
	
	# Exit
	var exit_id = TileType.EXIT * 10
	var exit_texture = generate_tile_texture(TileType.EXIT, config)
	
	var exit_source = TileSetAtlasSource.new()
	exit_source.texture = exit_texture
	exit_source.texture_region_size = Vector2i(64, 64)
	exit_source.create_tile(Vector2i(0, 0))
	
	tileset.add_source(exit_source, exit_id)

func _add_obstacle_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add obstacle tiles to tileset"""
	for variant in range(3):  # Different obstacle types
		var tile_id = TileType.OBSTACLE * 10 + variant
		var texture = generate_tile_texture(TileType.OBSTACLE, config, variant)
		
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0, 0))
		
		# Add collision for obstacles
		var tile_data = source.get_tile_data(Vector2i(0, 0), 0)
		if tile_data:
			var polygon = PackedVector2Array([
				Vector2(16, 16), Vector2(48, 16), Vector2(48, 48), Vector2(16, 48)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)
		
		tileset.add_source(source, tile_id)

func _add_decoration_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add decoration tiles to tileset"""
	for variant in range(5):  # Various decoration types
		var tile_id = TileType.DECORATION * 10 + variant
		var texture = generate_tile_texture(TileType.DECORATION, config, variant)
		
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0, 0))
		
		tileset.add_source(source, tile_id)

func _add_hazard_tiles(tileset: TileSet, config: Dictionary) -> void:
	"""Add hazard tiles to tileset"""
	for variant in range(2):  # Different hazard types
		var tile_id = TileType.HAZARD * 10 + variant
		var texture = generate_tile_texture(TileType.HAZARD, config, variant)
		
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0, 0))
		
		tileset.add_source(source, tile_id)

# Private texture generation methods
func _generate_floor_texture(image: Image, primary_color: Color, secondary_color: Color, pattern: String, variant: int) -> void:
	"""Generate floor tile texture"""
	var size = image.get_width()
	
	# Base color
	image.fill(primary_color)
	
	match pattern:
		"volcanic":
			_add_volcanic_floor_pattern(image, secondary_color, variant)
		"crystalline":
			_add_crystalline_floor_pattern(image, secondary_color, variant)
		"dark":
			_add_dark_floor_pattern(image, secondary_color, variant)
		"geometric":
			_add_geometric_floor_pattern(image, secondary_color, variant)
		"organic":
			_add_organic_floor_pattern(image, secondary_color, variant)
		"sandy":
			_add_sandy_floor_pattern(image, secondary_color, variant)

func _generate_wall_texture(image: Image, primary_color: Color, accent_color: Color, pattern: String, variant: int) -> void:
	"""Generate wall tile texture"""
	var size = image.get_width()
	
	# Base wall color
	image.fill(primary_color)
	
	# Add wall pattern based on biome
	match pattern:
		"volcanic":
			_add_volcanic_wall_pattern(image, accent_color, variant)
		"crystalline":
			_add_crystalline_wall_pattern(image, accent_color, variant)
		"dark":
			_add_dark_wall_pattern(image, accent_color, variant)
		"geometric":
			_add_geometric_wall_pattern(image, accent_color, variant)
		"organic":
			_add_organic_wall_pattern(image, accent_color, variant)
		"sandy":
			_add_sandy_wall_pattern(image, accent_color, variant)

func _generate_door_texture(image: Image, base_color: Color, accent_color: Color, pattern: String) -> void:
	"""Generate door tile texture"""
	var size = image.get_width()
	
	# Door background
	image.fill(base_color.darkened(0.3))
	
	# Door frame
	var frame_width = 8
	for x in range(frame_width):
		for y in range(size):
			image.set_pixel(x, y, accent_color)
			image.set_pixel(size - 1 - x, y, accent_color)
	
	for y in range(frame_width):
		for x in range(size):
			image.set_pixel(x, y, accent_color)
			image.set_pixel(x, size - 1 - y, accent_color)
	
	# Door handle
	var handle_x = size - 16
	var handle_y = size / 2
	for dx in range(-2, 3):
		for dy in range(-4, 5):
			if handle_x + dx >= 0 and handle_x + dx < size and handle_y + dy >= 0 and handle_y + dy < size:
				image.set_pixel(handle_x + dx, handle_y + dy, accent_color.lightened(0.5))

func _generate_entrance_texture(image: Image, primary_color: Color, secondary_color: Color) -> void:
	"""Generate entrance tile texture"""
	var size = image.get_width()
	
	# Gradient from center
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x - size/2, y - size/2).length()
			var max_distance = size / 2
			var factor = 1.0 - (distance / max_distance)
			factor = clamp(factor, 0.0, 1.0)
			
			var color = primary_color.lerp(secondary_color, factor)
			image.set_pixel(x, y, color)
	
	# Add glowing effect
	var center = size / 2
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		var end_x = center + cos(rad) * (center - 8)
		var end_y = center + sin(rad) * (center - 8)
		_draw_line_on_image(image, Vector2(center, center), Vector2(end_x, end_y), primary_color.lightened(0.3))

func _generate_exit_texture(image: Image, primary_color: Color, secondary_color: Color) -> void:
	"""Generate exit tile texture"""
	var size = image.get_width()
	
	# Base color
	image.fill(secondary_color)
	
	# Exit portal effect
	var center = size / 2
	for radius in range(8, center, 4):
		for angle in range(0, 360, 5):
			var rad = deg_to_rad(angle)
			var x = center + cos(rad) * radius
			var y = center + sin(rad) * radius
			
			if x >= 0 and x < size and y >= 0 and y < size:
				var factor = float(radius) / center
				var color = primary_color.lerp(secondary_color, factor)
				image.set_pixel(x, y, color)

func _generate_obstacle_texture(image: Image, primary_color: Color, accent_color: Color, variant: int) -> void:
	"""Generate obstacle tile texture"""
	var size = image.get_width()
	
	# Base transparent or floor-like color
	image.fill(primary_color.darkened(0.2))
	
	match variant:
		0:  # Rock/boulder
			_draw_circle_on_image(image, Vector2(size/2, size/2), size/3, accent_color)
			_draw_circle_on_image(image, Vector2(size/2, size/2), size/4, accent_color.lightened(0.2))
		1:  # Crystal formation
			_draw_crystal_on_image(image, accent_color)
		2:  # Debris
			_draw_debris_on_image(image, accent_color)

func _generate_decoration_texture(image: Image, primary_color: Color, secondary_color: Color, pattern: String, variant: int) -> void:
	"""Generate decoration tile texture"""
	var size = image.get_width()
	
	# Transparent base
	image.fill(Color(0, 0, 0, 0))
	
	match variant:
		0:  # Small rocks/gems
			_draw_small_decorations(image, primary_color, 3)
		1:  # Vegetation/crystals
			_draw_vegetation_decoration(image, primary_color, pattern)
		2:  # Markings/runes
			_draw_markings_decoration(image, primary_color)
		3:  # Scattered elements
			_draw_scattered_decoration(image, primary_color)
		4:  # Pattern decoration
			_draw_pattern_decoration(image, primary_color, pattern)

func _generate_hazard_texture(image: Image, hazard_color: Color, base_color: Color, variant: int) -> void:
	"""Generate hazard tile texture"""
	var size = image.get_width()
	
	# Base color
	image.fill(base_color)
	
	match variant:
		0:  # Spikes/dangerous terrain
			_draw_spikes_on_image(image, hazard_color)
		1:  # Lava/acid pools
			_draw_pool_on_image(image, hazard_color)

# Pattern generation utilities
func _add_volcanic_floor_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add volcanic floor pattern"""
	var size = image.get_width()
	
	# Random cracks and fissures
	for i in range(5 + variant * 2):
		var start_x = randi() % size
		var start_y = randi() % size
		var end_x = start_x + (randi() % 20) - 10
		var end_y = start_y + (randi() % 20) - 10
		
		end_x = clamp(end_x, 0, size - 1)
		end_y = clamp(end_y, 0, size - 1)
		
		_draw_line_on_image(image, Vector2(start_x, start_y), Vector2(end_x, end_y), color.darkened(0.3))

func _add_crystalline_floor_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add crystalline floor pattern"""
	var size = image.get_width()
	
	# Crystal formations
	for i in range(3 + variant):
		var center_x = randi() % size
		var center_y = randi() % size
		var crystal_size = 4 + (randi() % 8)
		
		_draw_crystal_formation(image, Vector2(center_x, center_y), crystal_size, color.lightened(0.2))

func _add_dark_floor_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add dark floor pattern"""
	var size = image.get_width()
	
	# Shadowy wisps
	for i in range(8 + variant * 2):
		var x = randi() % size
		var y = randi() % size
		var wisp_size = 2 + (randi() % 4)
		
		_draw_circle_on_image(image, Vector2(x, y), wisp_size, color.darkened(0.5))

func _add_geometric_floor_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add geometric floor pattern"""
	var size = image.get_width()
	var step = 16
	
	# Grid pattern
	for x in range(0, size, step):
		for y in range(0, size, step):
			if (x / step + y / step + variant) % 2 == 0:
				_draw_rect_on_image(image, Rect2(x, y, step - 2, step - 2), color.darkened(0.1))

func _add_organic_floor_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add organic floor pattern"""
	var size = image.get_width()
	
	# Organic spots
	for i in range(6 + variant * 2):
		var center_x = randi() % size
		var center_y = randi() % size
		var spot_size = 3 + (randi() % 6)
		
		_draw_circle_on_image(image, Vector2(center_x, center_y), spot_size, color.darkened(0.2))

func _add_sandy_floor_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add sandy floor pattern"""
	var size = image.get_width()
	
	# Sand grain texture
	for i in range(20 + variant * 5):
		var x = randi() % size
		var y = randi() % size
		var brightness = (randf() - 0.5) * 0.2
		
		image.set_pixel(x, y, color.lightened(brightness))

# Wall pattern methods (similar structure)
func _add_volcanic_wall_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add volcanic wall pattern"""
	var size = image.get_width()
	
	# Lava veins
	for i in range(3 + variant):
		var start_x = randi() % size
		var start_y = 0
		var end_x = randi() % size
		var end_y = size - 1
		
		_draw_line_on_image(image, Vector2(start_x, start_y), Vector2(end_x, end_y), color.lightened(0.3))

func _add_crystalline_wall_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add crystalline wall pattern"""
	var size = image.get_width()
	
	# Crystal veins
	for i in range(4 + variant):
		var x = randi() % size
		var y = randi() % size
		_draw_crystal_formation(image, Vector2(x, y), 6, color)

func _add_dark_wall_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add dark wall pattern"""
	var size = image.get_width()
	
	# Dark tendrils
	for i in range(5 + variant):
		var start_x = randi() % size
		var start_y = randi() % size
		var length = 10 + (randi() % 15)
		var angle = randf() * PI * 2
		
		var end_x = start_x + cos(angle) * length
		var end_y = start_y + sin(angle) * length
		
		end_x = clamp(end_x, 0, size - 1)
		end_y = clamp(end_y, 0, size - 1)
		
		_draw_line_on_image(image, Vector2(start_x, start_y), Vector2(end_x, end_y), color.darkened(0.3))

func _add_geometric_wall_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add geometric wall pattern"""
	var size = image.get_width()
	
	# Geometric shapes
	for i in range(3 + variant):
		var x = randi() % (size - 10)
		var y = randi() % (size - 10)
		var rect_size = 6 + (randi() % 8)
		
		_draw_rect_on_image(image, Rect2(x, y, rect_size, rect_size), color)

func _add_organic_wall_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add organic wall pattern"""
	var size = image.get_width()
	
	# Organic growths
	for i in range(4 + variant):
		var x = randi() % size
		var y = randi() % size
		var growth_size = 4 + (randi() % 6)
		
		_draw_circle_on_image(image, Vector2(x, y), growth_size, color.lightened(0.1))

func _add_sandy_wall_pattern(image: Image, color: Color, variant: int) -> void:
	"""Add sandy wall pattern"""
	var size = image.get_width()
	
	# Sand erosion marks
	for i in range(6 + variant * 2):
		var start_x = 0
		var start_y = randi() % size
		var end_x = size - 1
		var end_y = start_y + (randi() % 10) - 5
		
		end_y = clamp(end_y, 0, size - 1)
		
		_draw_line_on_image(image, Vector2(start_x, start_y), Vector2(end_x, end_y), color.darkened(0.2))

# Drawing utilities
func _draw_line_on_image(image: Image, start: Vector2, end: Vector2, color: Color) -> void:
	"""Draw a line on the image"""
	var distance = start.distance_to(end)
	var steps = int(distance)
	
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var point = start.lerp(end, t)
		var x = int(point.x)
		var y = int(point.y)
		
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)

func _draw_circle_on_image(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw a circle on the image"""
	var size = image.get_width()
	
	for x in range(max(0, center.x - radius), min(size, center.x + radius + 1)):
		for y in range(max(0, center.y - radius), min(size, center.y + radius + 1)):
			var distance = Vector2(x - center.x, y - center.y).length()
			if distance <= radius:
				image.set_pixel(x, y, color)

func _draw_rect_on_image(image: Image, rect: Rect2, color: Color) -> void:
	"""Draw a rectangle on the image"""
	var size = image.get_width()
	
	for x in range(max(0, rect.position.x), min(size, rect.position.x + rect.size.x)):
		for y in range(max(0, rect.position.y), min(size, rect.position.y + rect.size.y)):
			image.set_pixel(x, y, color)

func _draw_crystal_formation(image: Image, center: Vector2, size_val: int, color: Color) -> void:
	"""Draw a crystal formation"""
	# Simple diamond shape
	for i in range(-size_val, size_val + 1):
		for j in range(-size_val + abs(i), size_val - abs(i) + 1):
			var x = center.x + i
			var y = center.y + j
			
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_crystal_on_image(image: Image, color: Color) -> void:
	"""Draw crystal obstacle"""
	var size = image.get_width()
	var center = Vector2(size / 2, size / 2)
	
	# Multiple crystal points
	for i in range(3):
		var offset_x = (randi() % 20) - 10
		var offset_y = (randi() % 20) - 10
		var crystal_center = center + Vector2(offset_x, offset_y)
		var crystal_size = 4 + (randi() % 6)
		
		_draw_crystal_formation(image, crystal_center, crystal_size, color)

func _draw_debris_on_image(image: Image, color: Color) -> void:
	"""Draw debris pattern"""
	var size = image.get_width()
	
	# Random debris pieces
	for i in range(8):
		var x = randi() % size
		var y = randi() % size
		var debris_size = 2 + (randi() % 4)
		
		_draw_circle_on_image(image, Vector2(x, y), debris_size, color)

func _draw_small_decorations(image: Image, color: Color, count: int) -> void:
	"""Draw small decorative elements"""
	var size = image.get_width()
	
	for i in range(count):
		var x = randi() % size
		var y = randi() % size
		var dec_size = 1 + (randi() % 3)
		
		_draw_circle_on_image(image, Vector2(x, y), dec_size, color)

func _draw_vegetation_decoration(image: Image, color: Color, pattern: String) -> void:
	"""Draw vegetation-like decoration"""
	var size = image.get_width()
	var center = Vector2(size / 2, size / 2)
	
	# Simple plant/crystal growth
	_draw_line_on_image(image, Vector2(center.x, size - 5), Vector2(center.x, center.y), color)
	_draw_line_on_image(image, center, Vector2(center.x - 8, center.y - 8), color.lightened(0.2))
	_draw_line_on_image(image, center, Vector2(center.x + 8, center.y - 8), color.lightened(0.2))

func _draw_markings_decoration(image: Image, color: Color) -> void:
	"""Draw marking/rune decoration"""
	var size = image.get_width()
	var center = Vector2(size / 2, size / 2)
	
	# Simple runic pattern
	_draw_circle_on_image(image, center, 8, color)
	_draw_line_on_image(image, Vector2(center.x - 6, center.y), Vector2(center.x + 6, center.y), color.lightened(0.3))
	_draw_line_on_image(image, Vector2(center.x, center.y - 6), Vector2(center.x, center.y + 6), color.lightened(0.3))

func _draw_scattered_decoration(image: Image, color: Color) -> void:
	"""Draw scattered decorative elements"""
	var size = image.get_width()
	
	for i in range(5):
		var x = randi() % size
		var y = randi() % size
		image.set_pixel(x, y, color)

func _draw_pattern_decoration(image: Image, color: Color, pattern: String) -> void:
	"""Draw pattern-based decoration"""
	var size = image.get_width()
	
	match pattern:
		"geometric":
			# Geometric pattern
			for i in range(0, size, 8):
				_draw_line_on_image(image, Vector2(i, 0), Vector2(i, size), color.darkened(0.3))
		"organic":
			# Organic swirl
			var center = Vector2(size / 2, size / 2)
			for angle in range(0, 360, 30):
				var rad = deg_to_rad(angle)
				var end_x = center.x + cos(rad) * (size / 3)
				var end_y = center.y + sin(rad) * (size / 3)
				_draw_line_on_image(image, center, Vector2(end_x, end_y), color)
		_:
			# Default dot pattern
			for i in range(0, size, 16):
				for j in range(0, size, 16):
					_draw_circle_on_image(image, Vector2(i, j), 2, color)

func _draw_spikes_on_image(image: Image, color: Color) -> void:
	"""Draw spikes for hazard"""
	var size = image.get_width()
	
	# Draw several spike formations
	for i in range(4):
		var base_x = i * (size / 4) + 8
		var base_y = size - 8
		var tip_x = base_x
		var tip_y = base_y - 16
		
		# Spike body
		_draw_line_on_image(image, Vector2(base_x - 4, base_y), Vector2(tip_x, tip_y), color)
		_draw_line_on_image(image, Vector2(base_x + 4, base_y), Vector2(tip_x, tip_y), color)
		_draw_line_on_image(image, Vector2(base_x - 4, base_y), Vector2(base_x + 4, base_y), color)

func _draw_pool_on_image(image: Image, color: Color) -> void:
	"""Draw liquid pool for hazard"""
	var size = image.get_width()
	var center = Vector2(size / 2, size / 2)
	
	# Pool with animated-looking ripples
	_draw_circle_on_image(image, center, size / 3, color)
	_draw_circle_on_image(image, center, size / 4, color.lightened(0.2))
	_draw_circle_on_image(image, center, size / 6, color.lightened(0.4))

func clear_cache() -> void:
	"""Clear the tileset cache"""
	tileset_cache.clear()
	print("[TilesetGenerator] Tileset cache cleared")

func get_cached_tileset(biome: String) -> TileSet:
	"""Get a cached tileset by biome name"""
	return tileset_cache.get(biome, null)

func get_available_biomes() -> Array:
	"""Get list of available biome names"""
	return BIOME_CONFIGS.keys()