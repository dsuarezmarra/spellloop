# TextureGenerator.gd
# Generates procedural textures for particles, backgrounds, and UI elements
# Creates seamless patterns and effects without requiring external art files

extends Node

signal texture_generated(texture_name: String, texture: ImageTexture)

# Texture type presets
enum TextureType {
	NOISE,
	GRADIENT,
	PATTERN,
	PARTICLE,
	SEAMLESS_TILE,
	BACKGROUND
}

# Pattern types
enum PatternType {
	DOTS,
	STRIPES,
	CHECKERBOARD,
	HEXAGON,
	CIRCUIT,
	ORGANIC
}

# Generated textures cache
var texture_cache: Dictionary = {}

func _ready() -> void:
	"""Initialize texture generator"""
	print("[TextureGenerator] Texture Generator initialized")

func generate_particle_texture(particle_type: String, size: int = 32) -> ImageTexture:
	"""Generate particle texture for visual effects"""
	var cache_key = "particle_" + particle_type + "_" + str(size)
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = size / 2
	var radius = size / 3
	
	match particle_type:
		"fire":
			_generate_fire_particle(image, center, radius)
		"ice":
			_generate_ice_particle(image, center, radius)
		"lightning":
			_generate_lightning_particle(image, center, radius)
		"shadow":
			_generate_shadow_particle(image, center, radius)
		"healing":
			_generate_healing_particle(image, center, radius)
		"explosion":
			_generate_explosion_particle(image, center, radius)
		"sparkle":
			_generate_sparkle_particle(image, center, radius)
		"smoke":
			_generate_smoke_particle(image, center, radius)
		_:
			_generate_generic_particle(image, center, radius)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	texture_cache[cache_key] = texture
	texture_generated.emit("particle_" + particle_type, texture)
	
	return texture

func generate_background_pattern(pattern_type: PatternType, size: Vector2i = Vector2i(256, 256), colors: Array = []) -> ImageTexture:
	"""Generate seamless background pattern"""
	var cache_key = "pattern_" + str(pattern_type) + "_" + str(size.x) + "x" + str(size.y)
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	# Default colors if none provided
	if colors.is_empty():
		colors = [Color(0.1, 0.1, 0.15), Color(0.15, 0.15, 0.2), Color(0.2, 0.2, 0.25)]
	
	match pattern_type:
		PatternType.DOTS:
			_generate_dots_pattern(image, colors)
		PatternType.STRIPES:
			_generate_stripes_pattern(image, colors)
		PatternType.CHECKERBOARD:
			_generate_checkerboard_pattern(image, colors)
		PatternType.HEXAGON:
			_generate_hexagon_pattern(image, colors)
		PatternType.CIRCUIT:
			_generate_circuit_pattern(image, colors)
		PatternType.ORGANIC:
			_generate_organic_pattern(image, colors)
		_:
			image.fill(colors[0])
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	texture_cache[cache_key] = texture
	texture_generated.emit("pattern_" + str(pattern_type), texture)
	
	return texture

func generate_gradient_texture(start_color: Color, end_color: Color, direction: String = "vertical", size: Vector2i = Vector2i(256, 256)) -> ImageTexture:
	"""Generate gradient texture"""
	var cache_key = "gradient_" + str(start_color) + "_" + str(end_color) + "_" + direction + "_" + str(size.x) + "x" + str(size.y)
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	for y in range(size.y):
		for x in range(size.x):
			var t: float
			match direction:
				"vertical":
					t = float(y) / float(size.y)
				"horizontal":
					t = float(x) / float(size.x)
				"diagonal":
					t = float(x + y) / float(size.x + size.y)
				"radial":
					var center = Vector2(size.x / 2, size.y / 2)
					var distance = Vector2(x, y).distance_to(center)
					var max_distance = center.length()
					t = min(distance / max_distance, 1.0)
				_:
					t = float(y) / float(size.y)
			
			var color = start_color.lerp(end_color, t)
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	texture_cache[cache_key] = texture
	texture_generated.emit("gradient", texture)
	
	return texture

func generate_noise_texture(size: Vector2i = Vector2i(256, 256), scale: float = 1.0, octaves: int = 4) -> ImageTexture:
	"""Generate noise texture using simplified noise algorithm"""
	var cache_key = "noise_" + str(size.x) + "x" + str(size.y) + "_" + str(scale) + "_" + str(octaves)
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	# Simple noise generation using sin/cos
	for y in range(size.y):
		for x in range(size.x):
			var noise_value = 0.0
			var amplitude = 1.0
			var frequency = scale
			
			for octave in range(octaves):
				var sample_x = float(x) * frequency / float(size.x)
				var sample_y = float(y) * frequency / float(size.y)
				
				# Pseudo-noise using trigonometric functions
				var noise = sin(sample_x * 12.9898 + sample_y * 78.233) * 43758.5453
				noise = noise - floor(noise)  # Get fractional part
				
				noise_value += noise * amplitude
				amplitude *= 0.5
				frequency *= 2.0
			
			noise_value = (noise_value + 1.0) * 0.5  # Normalize to 0-1
			var gray_value = clamp(noise_value, 0.0, 1.0)
			image.set_pixel(x, y, Color(gray_value, gray_value, gray_value, 1.0))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	texture_cache[cache_key] = texture
	texture_generated.emit("noise", texture)
	
	return texture

func generate_ui_texture(ui_element: String, size: Vector2i = Vector2i(64, 64)) -> ImageTexture:
	"""Generate UI element textures"""
	var cache_key = "ui_" + ui_element + "_" + str(size.x) + "x" + str(size.y)
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]
	
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	match ui_element:
		"button_normal":
			_generate_button_texture(image, Color(0.3, 0.3, 0.3, 0.9), Color(0.5, 0.5, 0.5))
		"button_hover":
			_generate_button_texture(image, Color(0.4, 0.4, 0.4, 0.9), Color(0.6, 0.6, 0.6))
		"button_pressed":
			_generate_button_texture(image, Color(0.2, 0.2, 0.2, 0.9), Color(0.3, 0.3, 0.3))
		"panel":
			_generate_panel_texture(image, Color(0.1, 0.1, 0.15, 0.9))
		"health_bar":
			_generate_gradient_rect(image, Color.RED, Color.DARK_RED)
		"mana_bar":
			_generate_gradient_rect(image, Color.BLUE, Color(0, 0, 0.5))
		"experience_bar":
			_generate_gradient_rect(image, Color.GOLD, Color.ORANGE)
		_:
			image.fill(Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	texture_cache[cache_key] = texture
	texture_generated.emit("ui_" + ui_element, texture)
	
	return texture

# Private particle generation methods
func _generate_fire_particle(image: Image, center: int, radius: int) -> void:
	"""Generate fire particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var heat = 1.0 - (distance / radius) * 0.7
				var color = Color(1.0, heat * 0.8, heat * 0.3, alpha * alpha)
				image.set_pixel(x, y, color)

func _generate_ice_particle(image: Image, center: int, radius: int) -> void:
	"""Generate ice particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var coolness = 1.0 - (distance / radius) * 0.5
				var color = Color(coolness * 0.3, coolness * 0.8, 1.0, alpha * alpha)
				image.set_pixel(x, y, color)

func _generate_lightning_particle(image: Image, center: int, radius: int) -> void:
	"""Generate lightning particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var electric = 1.0 - (distance / radius) * 0.3
				var color = Color(electric, electric, 0.3, alpha * alpha * 1.5)
				image.set_pixel(x, y, color)

func _generate_shadow_particle(image: Image, center: int, radius: int) -> void:
	"""Generate shadow particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var darkness = 0.3 + (1.0 - distance / radius) * 0.7
				var color = Color(darkness * 0.5, 0.2, darkness, alpha * alpha)
				image.set_pixel(x, y, color)

func _generate_healing_particle(image: Image, center: int, radius: int) -> void:
	"""Generate healing particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var vitality = 1.0 - (distance / radius) * 0.4
				var color = Color(vitality * 0.3, 1.0, vitality * 0.5, alpha * alpha)
				image.set_pixel(x, y, color)

func _generate_explosion_particle(image: Image, center: int, radius: int) -> void:
	"""Generate explosion particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var intensity = 1.0 - (distance / radius) * 0.6
				var color = Color(1.0, intensity * 0.7, intensity * 0.2, alpha * alpha * 1.2)
				image.set_pixel(x, y, color)

func _generate_sparkle_particle(image: Image, center: int, radius: int) -> void:
	"""Generate sparkle particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var sparkle = 1.0 - (distance / radius) * 0.2
				var color = Color(sparkle, sparkle, 1.0, alpha * alpha * 1.5)
				image.set_pixel(x, y, color)

func _generate_smoke_particle(image: Image, center: int, radius: int) -> void:
	"""Generate smoke particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = (1.0 - (distance / radius)) * 0.6
				var gray = 0.2 + (1.0 - distance / radius) * 0.3
				var color = Color(gray, gray, gray, alpha)
				image.set_pixel(x, y, color)

func _generate_generic_particle(image: Image, center: int, radius: int) -> void:
	"""Generate generic particle texture"""
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance = Vector2(x - center, y - center).length()
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				var color = Color(1.0, 1.0, 1.0, alpha * alpha)
				image.set_pixel(x, y, color)

# Private pattern generation methods
func _generate_dots_pattern(image: Image, colors: Array) -> void:
	"""Generate dots pattern"""
	var dot_size = 8
	var spacing = 16
	
	image.fill(colors[0])
	
	for y in range(0, image.get_height(), spacing):
		for x in range(0, image.get_width(), spacing):
			var dot_color = colors[1] if colors.size() > 1 else Color.WHITE
			_draw_circle_on_image(image, Vector2i(x + spacing/2, y + spacing/2), dot_size/2, dot_color)

func _generate_stripes_pattern(image: Image, colors: Array) -> void:
	"""Generate stripes pattern"""
	var stripe_width = 16
	var color_index = 0
	
	for x in range(image.get_width()):
		var color = colors[color_index % colors.size()]
		if x % stripe_width == 0:
			color_index += 1
		
		for y in range(image.get_height()):
			image.set_pixel(x, y, color)

func _generate_checkerboard_pattern(image: Image, colors: Array) -> void:
	"""Generate checkerboard pattern"""
	var tile_size = 32
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var tile_x = x / tile_size
			var tile_y = y / tile_size
			var color_index = (tile_x + tile_y) % 2
			var color = colors[color_index % colors.size()]
			image.set_pixel(x, y, color)

func _generate_hexagon_pattern(image: Image, colors: Array) -> void:
	"""Generate hexagon pattern"""
	# Simplified hexagon approximation using circles
	var hex_radius = 24
	var spacing = hex_radius * 1.5
	
	image.fill(colors[0])
	
	for y in range(0, image.get_height(), int(spacing)):
		for x in range(0, image.get_width(), int(spacing)):
			var offset_x = (spacing / 2) if (y / int(spacing)) % 2 == 1 else 0
			var hex_color = colors[1] if colors.size() > 1 else Color.WHITE
			_draw_circle_on_image(image, Vector2i(x + offset_x, y), hex_radius/2, hex_color)

func _generate_circuit_pattern(image: Image, colors: Array) -> void:
	"""Generate circuit board pattern"""
	image.fill(colors[0])
	
	var line_color = colors[1] if colors.size() > 1 else Color.GREEN
	var line_width = 2
	var spacing = 32
	
	# Horizontal lines
	for y in range(0, image.get_height(), spacing):
		for x in range(image.get_width()):
			for w in range(line_width):
				if y + w < image.get_height():
					image.set_pixel(x, y + w, line_color)
	
	# Vertical lines
	for x in range(0, image.get_width(), spacing):
		for y in range(image.get_height()):
			for w in range(line_width):
				if x + w < image.get_width():
					image.set_pixel(x + w, y, line_color)

func _generate_organic_pattern(image: Image, colors: Array) -> void:
	"""Generate organic/cellular pattern"""
	# Use simple noise-like algorithm for organic feel
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var noise_val = sin(x * 0.1) * cos(y * 0.1) + sin(x * 0.05) * sin(y * 0.05)
			var color_index = 0 if noise_val > 0 else 1
			var color = colors[color_index % colors.size()]
			image.set_pixel(x, y, color)

# UI texture generation methods
func _generate_button_texture(image: Image, base_color: Color, highlight_color: Color) -> void:
	"""Generate button texture with highlight"""
	var width = image.get_width()
	var height = image.get_height()
	
	for y in range(height):
		for x in range(width):
			var gradient = float(y) / float(height)
			var color = base_color.lerp(highlight_color, 1.0 - gradient)
			image.set_pixel(x, y, color)

func _generate_panel_texture(image: Image, base_color: Color) -> void:
	"""Generate panel texture with subtle gradient"""
	var width = image.get_width()
	var height = image.get_height()
	
	for y in range(height):
		for x in range(width):
			var edge_factor = min(min(x, width - x), min(y, height - y)) / 10.0
			edge_factor = clamp(edge_factor, 0.0, 1.0)
			var color = base_color.lerp(base_color.lightened(0.1), edge_factor)
			image.set_pixel(x, y, color)

func _generate_gradient_rect(image: Image, start_color: Color, end_color: Color) -> void:
	"""Generate gradient rectangle"""
	var height = image.get_height()
	
	for y in range(height):
		var t = float(y) / float(height)
		var color = start_color.lerp(end_color, t)
		for x in range(image.get_width()):
			image.set_pixel(x, y, color)

func _draw_circle_on_image(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	"""Draw a circle on an image"""
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px = center.x + x
				var py = center.y + y
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, color)

func clear_cache() -> void:
	"""Clear the texture cache"""
	texture_cache.clear()
	print("[TextureGenerator] Texture cache cleared")

func get_cached_texture(texture_name: String) -> ImageTexture:
	"""Get a cached texture by name"""
	return texture_cache.get(texture_name, null)