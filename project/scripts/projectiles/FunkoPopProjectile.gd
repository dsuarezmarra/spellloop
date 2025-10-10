# FunkoPopProjectile.gd
# Creates Funko Pop style magical projectiles

extends Node2D
class_name FunkoPopProjectile

enum ProjectileType {
	BASIC,
	FIRE,
	ICE,
	LIGHTNING
}

func create_projectile_sprite(type: ProjectileType, effects: Array = []) -> Sprite2D:
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw the magical projectile based on type and effects
	_draw_projectile_on_image(image, type, effects)
	
	texture.set_image(image)
	sprite.texture = texture
	return sprite

func _draw_projectile_on_image(image: Image, type: ProjectileType, effects: Array):
	var center = Vector2(8, 8)
	var base_color = _get_base_color(type, effects)
	var glow_color = _get_glow_color(type, effects)
	
	# Core orb (Funko Pop style - simple but colorful)
	_draw_circle_on_image(image, center, 5, base_color)
	_draw_circle_on_image(image, center, 3, glow_color)
	_draw_circle_on_image(image, Vector2(center.x - 1, center.y - 1), 2, Color.WHITE)
	
	# Add effect-specific details
	_add_effect_details(image, center, effects)
	
	# Magic sparkle trail
	_add_sparkle_trail(image, center, base_color)

func _get_base_color(type: ProjectileType, effects: Array) -> Color:
	# Determine color based on effects
	if "burn" in effects:
		return Color(1.0, 0.3, 0.1)  # Bright red-orange
	elif "slow" in effects:
		return Color(0.2, 0.8, 1.0)  # Bright cyan
	elif "pierce" in effects:
		return Color(1.0, 1.0, 0.2)  # Bright yellow
	else:
		return Color(0.8, 0.2, 1.0)  # Bright purple (default magic)

func _get_glow_color(type: ProjectileType, effects: Array) -> Color:
	var base = _get_base_color(type, effects)
	return Color(base.r + 0.3, base.g + 0.3, base.b + 0.3).clamp()

func _add_effect_details(image: Image, center: Vector2, effects: Array):
	# Add visual effects based on active effects
	if "burn" in effects:
		_add_fire_effect(image, center)
	if "slow" in effects:
		_add_ice_effect(image, center)
	if "pierce" in effects:
		_add_lightning_effect(image, center)

func _add_fire_effect(image: Image, center: Vector2):
	# Small flame wisps around the orb
	var flame_color = Color(1.0, 0.6, 0.0)
	var positions = [
		Vector2(center.x - 3, center.y - 6),
		Vector2(center.x + 2, center.y - 5),
		Vector2(center.x - 1, center.y + 6)
	]
	
	for pos in positions:
		_draw_flame_wisp(image, pos, flame_color)

func _add_ice_effect(image: Image, center: Vector2):
	# Small ice crystals around the orb
	var ice_color = Color(0.7, 0.9, 1.0)
	var positions = [
		Vector2(center.x - 5, center.y - 2),
		Vector2(center.x + 5, center.y + 1),
		Vector2(center.x, center.y - 6),
		Vector2(center.x + 2, center.y + 5)
	]
	
	for pos in positions:
		_draw_ice_crystal(image, pos, ice_color)

func _add_lightning_effect(image: Image, center: Vector2):
	# Small lightning bolts around the orb
	var lightning_color = Color(1.0, 1.0, 0.5)
	_draw_lightning_bolt(image, Vector2(center.x - 4, center.y - 3), lightning_color)
	_draw_lightning_bolt(image, Vector2(center.x + 3, center.y + 2), lightning_color)

func _add_sparkle_trail(image: Image, center: Vector2, color: Color):
	# Small trailing sparkles
	var trail_positions = [
		Vector2(center.x - 6, center.y),
		Vector2(center.x - 4, center.y + 1),
		Vector2(center.x - 5, center.y - 1)
	]
	
	for pos in trail_positions:
		if pos.x >= 0 and pos.x < image.get_width() and pos.y >= 0 and pos.y < image.get_height():
			image.set_pixel(pos.x, pos.y, color)

func _draw_circle_on_image(image: Image, center: Vector2, radius: int, color: Color):
	for x in range(max(0, center.x - radius), min(image.get_width(), center.x + radius + 1)):
		for y in range(max(0, center.y - radius), min(image.get_height(), center.y + radius + 1)):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= radius:
				image.set_pixel(x, y, color)

func _draw_flame_wisp(image: Image, pos: Vector2, color: Color):
	# Small flame shape
	if pos.x >= 0 and pos.x < image.get_width() and pos.y >= 0 and pos.y < image.get_height():
		image.set_pixel(pos.x, pos.y, color)
		if pos.y + 1 < image.get_height():
			image.set_pixel(pos.x, pos.y + 1, Color(color.r, color.g * 0.7, color.b * 0.3))

func _draw_ice_crystal(image: Image, pos: Vector2, color: Color):
	# Small cross-shaped ice crystal
	var offsets = [Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	for offset in offsets:
		var pixel_pos = pos + offset
		if pixel_pos.x >= 0 and pixel_pos.x < image.get_width() and pixel_pos.y >= 0 and pixel_pos.y < image.get_height():
			image.set_pixel(pixel_pos.x, pixel_pos.y, color)

func _draw_lightning_bolt(image: Image, start_pos: Vector2, color: Color):
	# Simple zigzag lightning
	var positions = [
		start_pos,
		start_pos + Vector2(1, 1),
		start_pos + Vector2(0, 2),
		start_pos + Vector2(1, 3)
	]
	
	for pos in positions:
		if pos.x >= 0 and pos.x < image.get_width() and pos.y >= 0 and pos.y < image.get_height():
			image.set_pixel(pos.x, pos.y, color)