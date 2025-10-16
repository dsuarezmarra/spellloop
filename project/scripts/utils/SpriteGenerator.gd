# SpriteGenerator.gd
# Utility class for generating procedural sprites for testing
# Provides basic shapes and patterns for placeholder graphics

extends Node
class_name SpriteGeneratorUtils

# Sprite types
enum SpriteType {
	PLAYER,
	ENEMY,
	PROJECTILE,
	PICKUP,
	WALL
}

# Sprite configurations
static var sprite_configs = {
	SpriteType.PLAYER: {
		"size": Vector2(32, 32),
		"base_color": Color.BLUE,
		"pattern": "circle_with_cross"
	},
	SpriteType.ENEMY: {
		"size": Vector2(24, 24),
		"base_color": Color.RED,
		"pattern": "circle"
	},
	SpriteType.PROJECTILE: {
		"size": Vector2(8, 8),
		"base_color": Color.YELLOW,
		"pattern": "circle"
	},
	SpriteType.PICKUP: {
		"size": Vector2(16, 16),
		"base_color": Color.GREEN,
		"pattern": "diamond"
	},
	SpriteType.WALL: {
		"size": Vector2(32, 32),
		"base_color": Color.GRAY,
		"pattern": "square"
	}
}

static func create_sprite_texture(sprite_type: SpriteType, custom_color: Color = Color.WHITE) -> ImageTexture:
	"""Create a procedural sprite texture"""
	if not sprite_configs.has(sprite_type):
		print("[SpriteGenerator] ERROR: Unknown sprite type: ", sprite_type)
		return null
	
	var config = sprite_configs[sprite_type]
	var size = config.size as Vector2
	var color = custom_color if custom_color != Color.WHITE else config.base_color as Color
	var pattern = config.pattern as String
	
	# Create image
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw pattern
	match pattern:
		"circle":
			_draw_circle(image, size, color)
		"circle_with_cross":
			_draw_circle_with_cross(image, size, color)
		"diamond":
			_draw_diamond(image, size, color)
		"square":
			_draw_square(image, size, color)
		_:
			_draw_circle(image, size, color)  # Default fallback
	
	# Create texture
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	return texture

static func apply_sprite_to_node(node: Node, sprite_type_string: String, custom_color: Color = Color.WHITE) -> void:
	"""Apply a procedural sprite to a node with a Sprite2D child"""
	var sprite_node = null
	
	# Find Sprite2D child
	for child in node.get_children():
		if child is Sprite2D:
			sprite_node = child
			break
	
	if not sprite_node:
		print("[SpriteGenerator] ERROR: No Sprite2D found in node: ", node.name)
		return
	
	# Convert string to enum
	var sprite_type: SpriteType
	match sprite_type_string.to_lower():
		"player":
			sprite_type = SpriteType.PLAYER
		"enemy":
			sprite_type = SpriteType.ENEMY
		"projectile":
			sprite_type = SpriteType.PROJECTILE
		"pickup":
			sprite_type = SpriteType.PICKUP
		"wall":
			sprite_type = SpriteType.WALL
		_:
			sprite_type = SpriteType.ENEMY  # Default
	
	# Apply texture
	var texture = create_sprite_texture(sprite_type, custom_color)
	if texture:
		sprite_node.texture = texture
		print("[SpriteGenerator] Applied ", sprite_type_string, " sprite to ", node.name)

static func _draw_circle(image: Image, size: Vector2, color: Color) -> void:
	"""Draw a filled circle"""
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - 2
	
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, color)
			elif distance <= radius + 1:
				# Anti-aliasing edge
				var alpha = 1.0 - (distance - radius)
				var edge_color = Color(color.r, color.g, color.b, color.a * alpha)
				image.set_pixel(x, y, edge_color)

static func _draw_circle_with_cross(image: Image, size: Vector2, color: Color) -> void:
	"""Draw a circle with a cross inside"""
	_draw_circle(image, size, color)
	
	var center = size / 2
	var cross_size = min(size.x, size.y) / 4
	var cross_color = Color.WHITE
	
	# Horizontal line
	for x in range(int(center.x - cross_size), int(center.x + cross_size)):
		if x >= 0 and x < size.x:
			image.set_pixel(x, int(center.y), cross_color)
			if center.y - 1 >= 0:
				image.set_pixel(x, int(center.y - 1), cross_color)
			if center.y + 1 < size.y:
				image.set_pixel(x, int(center.y + 1), cross_color)
	
	# Vertical line
	for y in range(int(center.y - cross_size), int(center.y + cross_size)):
		if y >= 0 and y < size.y:
			image.set_pixel(int(center.x), y, cross_color)
			if center.x - 1 >= 0:
				image.set_pixel(int(center.x - 1), y, cross_color)
			if center.x + 1 < size.x:
				image.set_pixel(int(center.x + 1), y, cross_color)

static func _draw_diamond(image: Image, size: Vector2, color: Color) -> void:
	"""Draw a diamond shape"""
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - 2
	
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var manhattan_distance = abs(x - center.x) + abs(y - center.y)
			if manhattan_distance <= radius:
				image.set_pixel(x, y, color)
			elif manhattan_distance <= radius + 1:
				# Anti-aliasing edge
				var alpha = 1.0 - (manhattan_distance - radius)
				var edge_color = Color(color.r, color.g, color.b, color.a * alpha)
				image.set_pixel(x, y, edge_color)

static func _draw_square(image: Image, size: Vector2, color: Color) -> void:
	"""Draw a filled square"""
	var border = 2
	
	for x in range(border, int(size.x) - border):
		for y in range(border, int(size.y) - border):
			image.set_pixel(x, y, color)
	
	# Draw border
	var border_color = color.darkened(0.3)
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			if x < border or x >= size.x - border or y < border or y >= size.y - border:
				image.set_pixel(x, y, border_color)
