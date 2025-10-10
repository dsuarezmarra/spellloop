# SpriteGenerator.gd
# Procedural sprite generator for rapid prototyping
# Creates simple geometric shapes and basic sprites for testing
# This tool generates placeholder sprites until final art is created

extends Node

# Sprite generation functions
static func generate_player_sprite() -> ImageTexture:
	"""Generate a simple player sprite"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw player as a blue circle with simple details
	_draw_circle(image, Vector2(16, 16), 12, Color.DODGER_BLUE)
	_draw_circle(image, Vector2(16, 16), 8, Color.CYAN)
	
	# Add simple eyes
	_draw_circle(image, Vector2(12, 12), 2, Color.WHITE)
	_draw_circle(image, Vector2(20, 12), 2, Color.WHITE)
	_draw_circle(image, Vector2(12, 12), 1, Color.BLACK)
	_draw_circle(image, Vector2(20, 12), 1, Color.BLACK)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_fireball_sprite() -> ImageTexture:
	"""Generate a fireball projectile sprite"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw fireball as orange/red gradient
	_draw_circle(image, Vector2(8, 8), 6, Color.ORANGE_RED)
	_draw_circle(image, Vector2(8, 8), 4, Color.ORANGE)
	_draw_circle(image, Vector2(8, 8), 2, Color.YELLOW)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_ice_shard_sprite() -> ImageTexture:
	"""Generate an ice shard projectile sprite"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw ice shard as blue diamond
	var points = [
		Vector2(8, 2),   # Top
		Vector2(14, 8),  # Right
		Vector2(8, 14),  # Bottom
		Vector2(2, 8)    # Left
	]
	
	_draw_polygon(image, points, Color.LIGHT_BLUE)
	_draw_polygon(image, points, Color.CYAN, false)  # Outline
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_lightning_sprite() -> ImageTexture:
	"""Generate a lightning bolt sprite"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw lightning as zigzag
	var points = [
		Vector2(8, 2),
		Vector2(10, 6),
		Vector2(6, 8),
		Vector2(10, 12),
		Vector2(8, 14)
	]
	
	# Draw thick lightning bolt
	for i in range(points.size() - 1):
		_draw_line(image, points[i], points[i + 1], Color.YELLOW, 3)
	
	# Add white core
	for i in range(points.size() - 1):
		_draw_line(image, points[i], points[i + 1], Color.WHITE, 1)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_basic_enemy_sprite() -> ImageTexture:
	"""Generate a basic enemy sprite"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw enemy as red/purple creature
	_draw_circle(image, Vector2(12, 12), 10, Color.DARK_RED)
	_draw_circle(image, Vector2(12, 12), 8, Color.CRIMSON)
	
	# Add angry eyes
	_draw_circle(image, Vector2(8, 8), 2, Color.RED)
	_draw_circle(image, Vector2(16, 8), 2, Color.RED)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_wall_texture() -> ImageTexture:
	"""Generate a wall texture"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Create brick pattern
	image.fill(Color.SADDLE_BROWN)
	
	# Add brick lines
	for y in range(0, 64, 16):
		_draw_line(image, Vector2(0, y), Vector2(64, y), Color.DARK_GOLDENROD, 2)
	
	for x in range(0, 64, 32):
		for y in range(0, 64, 32):
			_draw_line(image, Vector2(x, y), Vector2(x, y + 16), Color.DARK_GOLDENROD, 2)
			_draw_line(image, Vector2(x + 16, y + 16), Vector2(x + 16, y + 32), Color.DARK_GOLDENROD, 2)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Helper drawing functions
static func _draw_circle(image: Image, center: Vector2, radius: int, color: Color) -> void:
	"""Draw a filled circle on an image"""
	for y in range(max(0, center.y - radius), min(image.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(image.get_width(), center.x + radius + 1)):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= radius:
				image.set_pixel(x, y, color)

static func _draw_line(image: Image, from: Vector2, to: Vector2, color: Color, thickness: int = 1) -> void:
	"""Draw a line on an image"""
	var distance = from.distance_to(to)
	var direction = (to - from).normalized()
	
	for i in range(int(distance)):
		var point = from + direction * i
		
		# Draw thickness
		for dy in range(-thickness/2, thickness/2 + 1):
			for dx in range(-thickness/2, thickness/2 + 1):
				var pixel_pos = point + Vector2(dx, dy)
				if pixel_pos.x >= 0 and pixel_pos.x < image.get_width() and pixel_pos.y >= 0 and pixel_pos.y < image.get_height():
					image.set_pixel(int(pixel_pos.x), int(pixel_pos.y), color)

static func _draw_polygon(image: Image, points: Array, color: Color, filled: bool = true) -> void:
	"""Draw a polygon on an image"""
	if points.size() < 3:
		return
	
	if filled:
		# Simple polygon fill (basic scanline)
		var min_y = points[0].y
		var max_y = points[0].y
		
		for point in points:
			min_y = min(min_y, point.y)
			max_y = max(max_y, point.y)
		
		for y in range(int(min_y), int(max_y) + 1):
			var intersections = []
			
			for i in range(points.size()):
				var p1 = points[i]
				var p2 = points[(i + 1) % points.size()]
				
				if (p1.y <= y and p2.y > y) or (p2.y <= y and p1.y > y):
					var x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
					intersections.append(x)
			
			intersections.sort()
			
			for i in range(0, intersections.size(), 2):
				if i + 1 < intersections.size():
					for x in range(int(intersections[i]), int(intersections[i + 1]) + 1):
						if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
							image.set_pixel(x, y, color)
	else:
		# Draw outline
		for i in range(points.size()):
			var p1 = points[i]
			var p2 = points[(i + 1) % points.size()]
			_draw_line(image, p1, p2, color, 1)

# Save sprites to files
static func save_all_sprites() -> void:
	"""Save all generated sprites to assets folder"""
	print("[SpriteGenerator] Generating and saving sprites...")
	
	# Ensure directories exist
	DirAccess.open("res://").make_dir_recursive("assets/sprites/characters")
	DirAccess.open("res://").make_dir_recursive("assets/sprites/projectiles")
	DirAccess.open("res://").make_dir_recursive("assets/sprites/enemies")
	DirAccess.open("res://").make_dir_recursive("assets/sprites/ui")
	
	# Generate and save sprites
	var player_sprite = generate_player_sprite()
	player_sprite.get_image().save_png("res://assets/sprites/characters/player.png")
	
	var fireball_sprite = generate_fireball_sprite()
	fireball_sprite.get_image().save_png("res://assets/sprites/projectiles/fireball.png")
	
	var ice_shard_sprite = generate_ice_shard_sprite()
	ice_shard_sprite.get_image().save_png("res://assets/sprites/projectiles/ice_shard.png")
	
	var lightning_sprite = generate_lightning_sprite()
	lightning_sprite.get_image().save_png("res://assets/sprites/projectiles/lightning_bolt.png")
	
	var enemy_sprite = generate_basic_enemy_sprite()
	enemy_sprite.get_image().save_png("res://assets/sprites/enemies/basic_enemy.png")
	
	var wall_texture = generate_wall_texture()
	wall_texture.get_image().save_png("res://assets/sprites/ui/wall_texture.png")
	
	print("[SpriteGenerator] Sprites saved to assets/sprites/")

# Apply sprites to nodes
static func apply_sprite_to_node(node: Node2D, sprite_type: String) -> void:
	"""Apply a generated sprite to a node"""
	var sprite_node = node.get_node("Sprite2D") as Sprite2D
	if not sprite_node:
		return
	
	var texture: ImageTexture
	
	match sprite_type:
		"player":
			texture = generate_player_sprite()
		"fireball":
			texture = generate_fireball_sprite()
		"ice_shard":
			texture = generate_ice_shard_sprite()
		"lightning":
			texture = generate_lightning_sprite()
		"enemy":
			texture = generate_basic_enemy_sprite()
		_:
			print("[SpriteGenerator] Unknown sprite type: ", sprite_type)
			return
	
	sprite_node.texture = texture
	print("[SpriteGenerator] Applied ", sprite_type, " sprite to ", node.name)

# Additional sprite generation methods
static func generate_enemy_sprite(enemy_type: String) -> ImageTexture:
	"""Generate enemy sprite based on type"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	match enemy_type:
		"ice":
			_draw_circle(image, Vector2(16, 16), 12, Color.CYAN)
			_draw_circle(image, Vector2(16, 16), 8, Color.LIGHT_BLUE)
			# Ice spikes
			_draw_line(image, Vector2(16, 4), Vector2(16, 0), Color.WHITE)
			_draw_line(image, Vector2(4, 16), Vector2(0, 16), Color.WHITE)
			_draw_line(image, Vector2(28, 16), Vector2(32, 16), Color.WHITE)
		"fire":
			_draw_circle(image, Vector2(16, 16), 12, Color.ORANGE_RED)
			_draw_circle(image, Vector2(16, 16), 8, Color.ORANGE)
			_draw_circle(image, Vector2(16, 16), 4, Color.YELLOW)
		"shadow":
			_draw_circle(image, Vector2(16, 16), 12, Color.PURPLE)
			_draw_circle(image, Vector2(16, 16), 8, Color.DARK_MAGENTA)
			# Glowing eyes
			_draw_circle(image, Vector2(12, 12), 2, Color.MAGENTA)
			_draw_circle(image, Vector2(20, 12), 2, Color.MAGENTA)
		"crystal":
			# Diamond shape
			var points = [
				Vector2(16, 4),   # Top
				Vector2(28, 16),  # Right
				Vector2(16, 28),  # Bottom
				Vector2(4, 16)    # Left
			]
			_draw_polygon(image, points, Color.CYAN)
			_draw_polygon(image, [Vector2(16, 8), Vector2(24, 16), Vector2(16, 24), Vector2(8, 16)], Color.WHITE)
		_:
			return generate_basic_enemy_sprite()
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_pickup_sprite(pickup_type: String) -> ImageTexture:
	"""Generate pickup item sprite"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	match pickup_type:
		"health":
			# Red cross
			image.fill_rect(Rect2(10, 6, 4, 12), Color.RED)
			image.fill_rect(Rect2(6, 10, 12, 4), Color.RED)
			# White outline
			image.fill_rect(Rect2(9, 5, 6, 14), Color.WHITE)
			image.fill_rect(Rect2(5, 9, 14, 6), Color.WHITE)
			image.fill_rect(Rect2(10, 6, 4, 12), Color.RED)
			image.fill_rect(Rect2(6, 10, 12, 4), Color.RED)
		"mana":
			# Blue star
			_draw_star(image, Vector2(12, 12), 8, Color.BLUE)
			_draw_circle(image, Vector2(12, 12), 4, Color.CYAN)
		"experience":
			# Golden diamond
			var points = [
				Vector2(12, 4),   # Top
				Vector2(20, 12),  # Right
				Vector2(12, 20),  # Bottom
				Vector2(4, 12)    # Left
			]
			_draw_polygon(image, points, Color.GOLD)
			_draw_polygon(image, [Vector2(12, 8), Vector2(16, 12), Vector2(12, 16), Vector2(8, 12)], Color.YELLOW)
		"coin":
			# Gold coin
			_draw_circle(image, Vector2(12, 12), 8, Color.GOLD)
			_draw_circle(image, Vector2(12, 12), 6, Color.YELLOW)
			image.fill_rect(Rect2(10, 8, 4, 8), Color.GOLD)
		_:
			# Default pickup (green orb)
			_draw_circle(image, Vector2(12, 12), 8, Color.GREEN)
			_draw_circle(image, Vector2(12, 12), 5, Color.LIME)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func generate_ui_element(element_type: String, size: Vector2i = Vector2i(32, 32)) -> ImageTexture:
	"""Generate UI element sprites"""
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	match element_type:
		"button_normal":
			_draw_rounded_rect(image, Rect2(0, 0, size.x, size.y), 4, Color(0.3, 0.3, 0.3, 0.8))
			_draw_rounded_rect_outline(image, Rect2(0, 0, size.x, size.y), 4, Color.WHITE, 2)
		"button_hover":
			_draw_rounded_rect(image, Rect2(0, 0, size.x, size.y), 4, Color(0.4, 0.4, 0.4, 0.9))
			_draw_rounded_rect_outline(image, Rect2(0, 0, size.x, size.y), 4, Color.CYAN, 2)
		"button_pressed":
			_draw_rounded_rect(image, Rect2(0, 0, size.x, size.y), 4, Color(0.2, 0.2, 0.2, 0.9))
			_draw_rounded_rect_outline(image, Rect2(0, 0, size.x, size.y), 4, Color.GRAY, 2)
		"panel":
			_draw_rounded_rect(image, Rect2(0, 0, size.x, size.y), 8, Color(0.1, 0.1, 0.15, 0.9))
			_draw_rounded_rect_outline(image, Rect2(0, 0, size.x, size.y), 8, Color(0.4, 0.4, 0.4), 1)
		"progress_bar_bg":
			_draw_rounded_rect(image, Rect2(0, 0, size.x, size.y), 4, Color(0.2, 0.2, 0.2, 0.8))
		"progress_bar_fill":
			_draw_rounded_rect(image, Rect2(0, 0, size.x, size.y), 4, Color.GREEN)
		_:
			image.fill_rect(Rect2(0, 0, size.x, size.y), Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Enhanced drawing utilities
static func _draw_star(image: Image, center: Vector2, radius: int, color: Color) -> void:
	"""Draw a star shape"""
	var points = []
	var outer_radius = radius
	var inner_radius = radius * 0.4
	
	for i in range(10):
		var angle = (i * PI) / 5.0
		var r = outer_radius if i % 2 == 0 else inner_radius
		var x = center.x + r * cos(angle)
		var y = center.y + r * sin(angle)
		points.append(Vector2(x, y))
	
	_draw_polygon(image, points, color, true)

static func _draw_rounded_rect(image: Image, rect: Rect2, radius: int, color: Color) -> void:
	"""Draw a rounded rectangle"""
	# Draw the main rectangle
	image.fill_rect(Rect2(rect.position.x + radius, rect.position.y, rect.size.x - 2 * radius, rect.size.y), color)
	image.fill_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, rect.size.y - 2 * radius), color)
	
	# Draw rounded corners
	_draw_quarter_circle(image, Vector2(rect.position.x + radius, rect.position.y + radius), radius, color, 0)
	_draw_quarter_circle(image, Vector2(rect.position.x + rect.size.x - radius, rect.position.y + radius), radius, color, 1)
	_draw_quarter_circle(image, Vector2(rect.position.x + rect.size.x - radius, rect.position.y + rect.size.y - radius), radius, color, 2)
	_draw_quarter_circle(image, Vector2(rect.position.x + radius, rect.position.y + rect.size.y - radius), radius, color, 3)

static func _draw_rounded_rect_outline(image: Image, rect: Rect2, radius: int, color: Color, thickness: int) -> void:
	"""Draw a rounded rectangle outline"""
	# Draw the edges
	for t in range(thickness):
		# Top and bottom edges
		_draw_line(image, Vector2(rect.position.x + radius, rect.position.y + t), 
				  Vector2(rect.position.x + rect.size.x - radius, rect.position.y + t), color)
		_draw_line(image, Vector2(rect.position.x + radius, rect.position.y + rect.size.y - 1 - t), 
				  Vector2(rect.position.x + rect.size.x - radius, rect.position.y + rect.size.y - 1 - t), color)
		
		# Left and right edges
		_draw_line(image, Vector2(rect.position.x + t, rect.position.y + radius), 
				  Vector2(rect.position.x + t, rect.position.y + rect.size.y - radius), color)
		_draw_line(image, Vector2(rect.position.x + rect.size.x - 1 - t, rect.position.y + radius), 
				  Vector2(rect.position.x + rect.size.x - 1 - t, rect.position.y + rect.size.y - radius), color)

static func _draw_quarter_circle(image: Image, center: Vector2, radius: int, color: Color, quadrant: int) -> void:
	"""Draw a quarter circle in specified quadrant"""
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var draw_x = center.x
				var draw_y = center.y
				
				match quadrant:
					0: # Top-left
						if x <= 0 and y <= 0:
							draw_x += x
							draw_y += y
						else:
							continue
					1: # Top-right
						if x >= 0 and y <= 0:
							draw_x += x
							draw_y += y
						else:
							continue
					2: # Bottom-right
						if x >= 0 and y >= 0:
							draw_x += x
							draw_y += y
						else:
							continue
					3: # Bottom-left
						if x <= 0 and y >= 0:
							draw_x += x
							draw_y += y
						else:
							continue
				
				if draw_x >= 0 and draw_x < image.get_width() and draw_y >= 0 and draw_y < image.get_height():
					image.set_pixel(int(draw_x), int(draw_y), color)