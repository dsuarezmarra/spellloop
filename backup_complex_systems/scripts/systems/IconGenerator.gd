# IconGenerator.gd
# Generates UI icons programmatically
# Creates consistent icon sets for spells, achievements, items, and UI elements

extends Node

signal icon_generated(icon_name: String, texture: ImageTexture)

# Icon types
enum IconType {
	SPELL,
	ACHIEVEMENT,
	ITEM,
	UI_ELEMENT,
	STATUS_EFFECT,
	ELEMENT
}

# Icon size presets
const ICON_SIZES = {
	"small": 32,
	"medium": 64,
	"large": 128
}

# Element colors
const ELEMENT_COLORS = {
	"fire": Color(1.0, 0.4, 0.1),
	"ice": Color(0.6, 0.9, 1.0),
	"lightning": Color(1.0, 1.0, 0.3),
	"shadow": Color(0.3, 0.1, 0.5),
	"earth": Color(0.6, 0.4, 0.2),
	"light": Color(1.0, 1.0, 0.8),
	"arcane": Color(0.8, 0.3, 0.8),
	"nature": Color(0.3, 0.8, 0.2)
}

# Generated icon cache
var icon_cache: Dictionary = {}

func _ready() -> void:
	"""Initialize icon generator"""
	print("[IconGenerator] Icon Generator initialized")

func generate_spell_icon(spell_name: String, element: String, size: String = "medium") -> ImageTexture:
	"""Generate icon for a spell"""
	var cache_key = "spell_%s_%s_%s" % [spell_name, element, size]
	if icon_cache.has(cache_key):
		return icon_cache[cache_key]
	
	var icon_size = ICON_SIZES.get(size, 64)
	var element_color = ELEMENT_COLORS.get(element, Color.WHITE)
	
	var texture = _create_spell_icon_texture(spell_name, element_color, icon_size)
	icon_cache[cache_key] = texture
	icon_generated.emit("spell_" + spell_name, texture)
	
	return texture

func generate_achievement_icon(achievement_type: String, size: String = "medium") -> ImageTexture:
	"""Generate icon for achievements"""
	var cache_key = "achievement_%s_%s" % [achievement_type, size]
	if icon_cache.has(cache_key):
		return icon_cache[cache_key]
	
	var icon_size = ICON_SIZES.get(size, 64)
	var texture = _create_achievement_icon_texture(achievement_type, icon_size)
	
	icon_cache[cache_key] = texture
	icon_generated.emit("achievement_" + achievement_type, texture)
	
	return texture

func generate_item_icon(item_type: String, rarity: String = "common", size: String = "medium") -> ImageTexture:
	"""Generate icon for items"""
	var cache_key = "item_%s_%s_%s" % [item_type, rarity, size]
	if icon_cache.has(cache_key):
		return icon_cache[cache_key]
	
	var icon_size = ICON_SIZES.get(size, 64)
	var rarity_color = _get_rarity_color(rarity)
	var texture = _create_item_icon_texture(item_type, rarity_color, icon_size)
	
	icon_cache[cache_key] = texture
	icon_generated.emit("item_" + item_type, texture)
	
	return texture

func generate_ui_icon(ui_element: String, style: String = "default", size: String = "medium") -> ImageTexture:
	"""Generate UI element icons"""
	var cache_key = "ui_%s_%s_%s" % [ui_element, style, size]
	if icon_cache.has(cache_key):
		return icon_cache[cache_key]
	
	var icon_size = ICON_SIZES.get(size, 64)
	var texture = _create_ui_icon_texture(ui_element, style, icon_size)
	
	icon_cache[cache_key] = texture
	icon_generated.emit("ui_" + ui_element, texture)
	
	return texture

func generate_status_effect_icon(effect_name: String, effect_type: String, size: String = "small") -> ImageTexture:
	"""Generate status effect icons"""
	var cache_key = "status_%s_%s_%s" % [effect_name, effect_type, size]
	if icon_cache.has(cache_key):
		return icon_cache[cache_key]
	
	var icon_size = ICON_SIZES.get(size, 32)
	var effect_color = _get_effect_color(effect_type)
	var texture = _create_status_effect_icon_texture(effect_name, effect_color, icon_size)
	
	icon_cache[cache_key] = texture
	icon_generated.emit("status_" + effect_name, texture)
	
	return texture

func generate_element_icon(element: String, size: String = "medium") -> ImageTexture:
	"""Generate elemental icons"""
	var cache_key = "element_%s_%s" % [element, size]
	if icon_cache.has(cache_key):
		return icon_cache[cache_key]
	
	var icon_size = ICON_SIZES.get(size, 64)
	var element_color = ELEMENT_COLORS.get(element, Color.WHITE)
	var texture = _create_element_icon_texture(element, element_color, icon_size)
	
	icon_cache[cache_key] = texture
	icon_generated.emit("element_" + element, texture)
	
	return texture

# Private icon creation methods
func _create_spell_icon_texture(spell_name: String, element_color: Color, size: int) -> ImageTexture:
	"""Create spell icon texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent background
	
	# Background circle
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2 - 4
	_draw_circle_with_border(image, center, radius, element_color.darkened(0.3), element_color, 2)
	
	# Spell-specific symbol
	match spell_name:
		"fireball":
			_draw_fireball_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
		"ice_shard":
			_draw_ice_shard_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
		"lightning_bolt":
			_draw_lightning_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
		"shadow_blast":
			_draw_shadow_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
		"healing":
			_draw_healing_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
		"teleport":
			_draw_teleport_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
		_:
			_draw_generic_spell_symbol(image, center, radius * 0.6, element_color.lightened(0.3))
	
	# Create texture
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _create_achievement_icon_texture(achievement_type: String, size: int) -> ImageTexture:
	"""Create achievement icon texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(size / 2, size / 2)
	var base_color = Color(0.8, 0.7, 0.3)  # Golden color
	var accent_color = Color(1.0, 0.9, 0.5)
	
	match achievement_type:
		"exploration":
			_draw_exploration_achievement(image, center, size * 0.4, base_color, accent_color)
		"combat":
			_draw_combat_achievement(image, center, size * 0.4, base_color, accent_color)
		"progression":
			_draw_progression_achievement(image, center, size * 0.4, base_color, accent_color)
		"collection":
			_draw_collection_achievement(image, center, size * 0.4, base_color, accent_color)
		"mastery":
			_draw_mastery_achievement(image, center, size * 0.4, base_color, accent_color)
		_:
			_draw_generic_achievement(image, center, size * 0.4, base_color, accent_color)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _create_item_icon_texture(item_type: String, rarity_color: Color, size: int) -> ImageTexture:
	"""Create item icon texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(size / 2, size / 2)
	
	# Background with rarity border
	var bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var radius = size / 2 - 4
	_draw_circle_with_border(image, center, radius, bg_color, rarity_color, 3)
	
	# Item-specific icon
	match item_type:
		"health_potion":
			_draw_potion_icon(image, center, radius * 0.7, Color.RED, Color.PINK)
		"mana_potion":
			_draw_potion_icon(image, center, radius * 0.7, Color.BLUE, Color.CYAN)
		"coin":
			_draw_coin_icon(image, center, radius * 0.7, Color.YELLOW, Color.ORANGE)
		"gem":
			_draw_gem_icon(image, center, radius * 0.7, rarity_color)
		"key":
			_draw_key_icon(image, center, radius * 0.7, Color.GOLD, Color.YELLOW)
		"scroll":
			_draw_scroll_icon(image, center, radius * 0.7, Color.WHITE, Color.BEIGE)
		"weapon":
			_draw_weapon_icon(image, center, radius * 0.7, Color.SILVER, Color.WHITE)
		"armor":
			_draw_armor_icon(image, center, radius * 0.7, Color.GRAY, Color.LIGHT_GRAY)
		_:
			_draw_generic_item_icon(image, center, radius * 0.7, rarity_color)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _create_ui_icon_texture(ui_element: String, style: String, size: int) -> ImageTexture:
	"""Create UI element icon texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(size / 2, size / 2)
	var primary_color = Color.WHITE
	var secondary_color = Color.GRAY
	
	match ui_element:
		"menu":
			_draw_menu_icon(image, center, size * 0.4, primary_color)
		"settings":
			_draw_settings_icon(image, center, size * 0.4, primary_color)
		"inventory":
			_draw_inventory_icon(image, center, size * 0.4, primary_color)
		"map":
			_draw_map_icon(image, center, size * 0.4, primary_color)
		"character":
			_draw_character_icon(image, center, size * 0.4, primary_color)
		"spells":
			_draw_spells_icon(image, center, size * 0.4, primary_color)
		"pause":
			_draw_pause_icon(image, center, size * 0.4, primary_color)
		"play":
			_draw_play_icon(image, center, size * 0.4, primary_color)
		"close":
			_draw_close_icon(image, center, size * 0.4, primary_color)
		"arrow":
			_draw_arrow_icon(image, center, size * 0.4, primary_color)
		_:
			_draw_generic_ui_icon(image, center, size * 0.4, primary_color)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _create_status_effect_icon_texture(effect_name: String, effect_color: Color, size: int) -> ImageTexture:
	"""Create status effect icon texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2 - 2
	
	# Background circle
	_draw_circle_with_border(image, center, radius, effect_color.darkened(0.5), effect_color, 1)
	
	# Effect-specific symbol
	match effect_name:
		"burn":
			_draw_flame_symbol(image, center, radius * 0.6, Color.ORANGE)
		"freeze":
			_draw_snowflake_symbol(image, center, radius * 0.6, Color.CYAN)
		"poison":
			_draw_poison_symbol(image, center, radius * 0.6, Color.GREEN)
		"shield":
			_draw_shield_symbol(image, center, radius * 0.6, Color.BLUE)
		"speed":
			_draw_speed_symbol(image, center, radius * 0.6, Color.YELLOW)
		"strength":
			_draw_strength_symbol(image, center, radius * 0.6, Color.RED)
		_:
			_draw_generic_effect_symbol(image, center, radius * 0.6, effect_color.lightened(0.3))
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _create_element_icon_texture(element: String, element_color: Color, size: int) -> ImageTexture:
	"""Create elemental icon texture"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2 - 4
	
	# Background
	_draw_circle_with_border(image, center, radius, element_color.darkened(0.4), element_color, 2)
	
	# Element-specific symbol
	match element:
		"fire":
			_draw_fire_element_symbol(image, center, radius * 0.7, Color.ORANGE)
		"ice":
			_draw_ice_element_symbol(image, center, radius * 0.7, Color.CYAN)
		"lightning":
			_draw_lightning_element_symbol(image, center, radius * 0.7, Color.YELLOW)
		"shadow":
			_draw_shadow_element_symbol(image, center, radius * 0.7, Color.PURPLE)
		"earth":
			_draw_earth_element_symbol(image, center, radius * 0.7, Color.BROWN)
		"light":
			_draw_light_element_symbol(image, center, radius * 0.7, Color.WHITE)
		"arcane":
			_draw_arcane_element_symbol(image, center, radius * 0.7, Color.MAGENTA)
		"nature":
			_draw_nature_element_symbol(image, center, radius * 0.7, Color.GREEN)
		_:
			_draw_generic_element_symbol(image, center, radius * 0.7, element_color.lightened(0.3))
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

# Symbol drawing methods
func _draw_fireball_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw fireball symbol"""
	# Flame shape
	var flame_points = [
		Vector2(center.x, center.y + radius * 0.8),
		Vector2(center.x - radius * 0.3, center.y + radius * 0.2),
		Vector2(center.x - radius * 0.6, center.y - radius * 0.2),
		Vector2(center.x - radius * 0.2, center.y - radius * 0.8),
		Vector2(center.x + radius * 0.2, center.y - radius * 0.8),
		Vector2(center.x + radius * 0.6, center.y - radius * 0.2),
		Vector2(center.x + radius * 0.3, center.y + radius * 0.2)
	]
	
	_draw_polygon(image, flame_points, color)

func _draw_ice_shard_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw ice shard symbol"""
	# Crystal/shard shape
	var shard_points = [
		Vector2(center.x, center.y - radius),
		Vector2(center.x + radius * 0.3, center.y - radius * 0.2),
		Vector2(center.x + radius * 0.6, center.y + radius * 0.4),
		Vector2(center.x, center.y + radius),
		Vector2(center.x - radius * 0.6, center.y + radius * 0.4),
		Vector2(center.x - radius * 0.3, center.y - radius * 0.2)
	]
	
	_draw_polygon(image, shard_points, color)

func _draw_lightning_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw lightning bolt symbol"""
	# Zigzag lightning bolt
	var points = [
		Vector2(center.x - radius * 0.2, center.y - radius),
		Vector2(center.x + radius * 0.4, center.y - radius * 0.3),
		Vector2(center.x - radius * 0.1, center.y),
		Vector2(center.x + radius * 0.6, center.y + radius * 0.3),
		Vector2(center.x + radius * 0.2, center.y + radius),
		Vector2(center.x - radius * 0.4, center.y + radius * 0.1),
		Vector2(center.x + radius * 0.1, center.y - radius * 0.2)
	]
	
	_draw_polygon(image, points, color)

func _draw_shadow_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw shadow symbol"""
	# Dark swirl or void
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		var spiral_radius = radius * (0.3 + 0.5 * sin(deg_to_rad(angle * 3)))
		var x = center.x + cos(rad) * spiral_radius
		var y = center.y + sin(rad) * spiral_radius
		
		_draw_circle_on_image(image, Vector2(x, y), 3, color)

func _draw_healing_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw healing cross symbol"""
	var thickness = radius * 0.2
	
	# Vertical bar
	_draw_rect_on_image(image, Rect2(center.x - thickness/2, center.y - radius, thickness, radius * 2), color)
	# Horizontal bar
	_draw_rect_on_image(image, Rect2(center.x - radius, center.y - thickness/2, radius * 2, thickness), color)

func _draw_teleport_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw teleport symbol"""
	# Spiral/portal effect
	for i in range(3):
		var ring_radius = radius * (0.3 + i * 0.2)
		for angle in range(0, 270, 30):  # Incomplete circles
			var rad = deg_to_rad(angle)
			var x = center.x + cos(rad) * ring_radius
			var y = center.y + sin(rad) * ring_radius
			
			_draw_circle_on_image(image, Vector2(x, y), 2, color)

func _draw_generic_spell_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw generic spell symbol"""
	# Simple star
	_draw_star(image, center, radius, 5, color)

# Achievement symbols
func _draw_exploration_achievement(image: Image, center: Vector2, radius: float, base_color: Color, accent_color: Color) -> void:
	"""Draw exploration achievement"""
	# Map/compass symbol
	_draw_circle_with_border(image, center, radius, base_color, accent_color, 3)
	
	# Compass points
	for angle in [0, 90, 180, 270]:
		var rad = deg_to_rad(angle)
		var outer = Vector2(center.x + cos(rad) * radius * 0.8, center.y + sin(rad) * radius * 0.8)
		var inner = Vector2(center.x + cos(rad) * radius * 0.4, center.y + sin(rad) * radius * 0.4)
		_draw_line_on_image(image, inner, outer, accent_color)

func _draw_combat_achievement(image: Image, center: Vector2, radius: float, base_color: Color, accent_color: Color) -> void:
	"""Draw combat achievement"""
	# Sword symbol
	_draw_circle_with_border(image, center, radius, base_color, accent_color, 3)
	
	# Sword blade
	_draw_line_on_image(image, Vector2(center.x, center.y - radius * 0.6), Vector2(center.x, center.y + radius * 0.6), accent_color)
	# Sword crossguard
	_draw_line_on_image(image, Vector2(center.x - radius * 0.3, center.y), Vector2(center.x + radius * 0.3, center.y), accent_color)

func _draw_progression_achievement(image: Image, center: Vector2, radius: float, base_color: Color, accent_color: Color) -> void:
	"""Draw progression achievement"""
	# Arrow pointing up
	_draw_circle_with_border(image, center, radius, base_color, accent_color, 3)
	
	# Arrow
	var arrow_points = [
		Vector2(center.x, center.y - radius * 0.5),
		Vector2(center.x - radius * 0.3, center.y - radius * 0.1),
		Vector2(center.x - radius * 0.1, center.y - radius * 0.1),
		Vector2(center.x - radius * 0.1, center.y + radius * 0.5),
		Vector2(center.x + radius * 0.1, center.y + radius * 0.5),
		Vector2(center.x + radius * 0.1, center.y - radius * 0.1),
		Vector2(center.x + radius * 0.3, center.y - radius * 0.1)
	]
	_draw_polygon(image, arrow_points, accent_color)

func _draw_collection_achievement(image: Image, center: Vector2, radius: float, base_color: Color, accent_color: Color) -> void:
	"""Draw collection achievement"""
	# Chest/bag symbol
	_draw_circle_with_border(image, center, radius, base_color, accent_color, 3)
	
	# Chest shape
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.4, center.y - radius * 0.2, radius * 0.8, radius * 0.6), accent_color)
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.5, center.y - radius * 0.4, radius, radius * 0.3), accent_color)

func _draw_mastery_achievement(image: Image, center: Vector2, radius: float, base_color: Color, accent_color: Color) -> void:
	"""Draw mastery achievement"""
	# Crown symbol
	_draw_circle_with_border(image, center, radius, base_color, accent_color, 3)
	
	# Crown points
	for i in range(5):
		var angle = deg_to_rad(i * 72 - 90)
		var point_height = radius * (0.4 if i % 2 == 0 else 0.6)
		var x = center.x + cos(angle) * radius * 0.3
		var y = center.y + sin(angle) * point_height
		_draw_line_on_image(image, Vector2(x, center.y + radius * 0.2), Vector2(x, y), accent_color)

func _draw_generic_achievement(image: Image, center: Vector2, radius: float, base_color: Color, accent_color: Color) -> void:
	"""Draw generic achievement"""
	# Medal with star
	_draw_circle_with_border(image, center, radius, base_color, accent_color, 3)
	_draw_star(image, center, radius * 0.5, 5, accent_color)

# Item symbols
func _draw_potion_icon(image: Image, center: Vector2, radius: float, liquid_color: Color, glass_color: Color) -> void:
	"""Draw potion bottle"""
	# Bottle body
	var bottle_width = radius * 0.6
	var bottle_height = radius * 1.2
	_draw_rect_on_image(image, Rect2(center.x - bottle_width/2, center.y - bottle_height/2, bottle_width, bottle_height), glass_color)
	
	# Liquid
	var liquid_height = bottle_height * 0.7
	_draw_rect_on_image(image, Rect2(center.x - bottle_width/2 + 2, center.y - liquid_height/2, bottle_width - 4, liquid_height), liquid_color)
	
	# Cork
	_draw_rect_on_image(image, Rect2(center.x - bottle_width/3, center.y - bottle_height/2 - 8, bottle_width * 0.66, 8), Color.BROWN)

func _draw_coin_icon(image: Image, center: Vector2, radius: float, gold_color: Color, shine_color: Color) -> void:
	"""Draw coin"""
	_draw_circle_with_border(image, center, radius, gold_color, shine_color, 2)
	
	# Coin markings
	_draw_circle_on_image(image, center, radius * 0.3, shine_color)
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.1, center.y - radius * 0.3, radius * 0.2, radius * 0.6), gold_color.darkened(0.3))

func _draw_gem_icon(image: Image, center: Vector2, radius: float, gem_color: Color) -> void:
	"""Draw gem"""
	var gem_points = [
		Vector2(center.x, center.y - radius),
		Vector2(center.x + radius * 0.5, center.y - radius * 0.3),
		Vector2(center.x + radius * 0.7, center.y + radius * 0.3),
		Vector2(center.x, center.y + radius),
		Vector2(center.x - radius * 0.7, center.y + radius * 0.3),
		Vector2(center.x - radius * 0.5, center.y - radius * 0.3)
	]
	_draw_polygon(image, gem_points, gem_color)

func _draw_key_icon(image: Image, center: Vector2, radius: float, key_color: Color, shine_color: Color) -> void:
	"""Draw key"""
	# Key head (circle)
	_draw_circle_with_border(image, Vector2(center.x - radius * 0.3, center.y), radius * 0.4, key_color, shine_color, 2)
	
	# Key shaft
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.1, center.y - radius * 0.1, radius * 0.8, radius * 0.2), key_color)
	
	# Key teeth
	_draw_rect_on_image(image, Rect2(center.x + radius * 0.5, center.y - radius * 0.1, radius * 0.2, radius * 0.3), key_color)

func _draw_scroll_icon(image: Image, center: Vector2, radius: float, paper_color: Color, text_color: Color) -> void:
	"""Draw scroll"""
	# Scroll body
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.6, center.y - radius * 0.8, radius * 1.2, radius * 1.6), paper_color)
	
	# Scroll ends
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.7, center.y - radius * 0.9, radius * 1.4, radius * 0.2), Color.BROWN)
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.7, center.y + radius * 0.7, radius * 1.4, radius * 0.2), Color.BROWN)
	
	# Text lines
	for i in range(3):
		var y_pos = center.y - radius * 0.3 + i * radius * 0.3
		_draw_rect_on_image(image, Rect2(center.x - radius * 0.4, y_pos, radius * 0.8, radius * 0.1), text_color)

func _draw_weapon_icon(image: Image, center: Vector2, radius: float, metal_color: Color, shine_color: Color) -> void:
	"""Draw weapon (sword)"""
	# Blade
	var blade_points = [
		Vector2(center.x, center.y - radius),
		Vector2(center.x + radius * 0.1, center.y),
		Vector2(center.x - radius * 0.1, center.y)
	]
	_draw_polygon(image, blade_points, metal_color)
	
	# Crossguard
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.3, center.y - radius * 0.1, radius * 0.6, radius * 0.2), shine_color)
	
	# Handle
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.05, center.y, radius * 0.1, radius * 0.6), Color.BROWN)
	
	# Pommel
	_draw_circle_on_image(image, Vector2(center.x, center.y + radius * 0.7), radius * 0.1, metal_color)

func _draw_armor_icon(image: Image, center: Vector2, radius: float, metal_color: Color, shine_color: Color) -> void:
	"""Draw armor (chestplate)"""
	# Armor body
	var armor_points = [
		Vector2(center.x - radius * 0.6, center.y - radius * 0.4),
		Vector2(center.x + radius * 0.6, center.y - radius * 0.4),
		Vector2(center.x + radius * 0.8, center.y + radius * 0.6),
		Vector2(center.x - radius * 0.8, center.y + radius * 0.6)
	]
	_draw_polygon(image, armor_points, metal_color)
	
	# Armor trim
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.5, center.y - radius * 0.3, radius, radius * 0.2), shine_color)

func _draw_generic_item_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw generic item"""
	# Simple box/package
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.6, center.y - radius * 0.6, radius * 1.2, radius * 1.2), color)
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.4, center.y - radius * 0.4, radius * 0.8, radius * 0.8), color.lightened(0.3))

# UI element symbols
func _draw_menu_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw hamburger menu icon"""
	var line_width = radius * 0.1
	var line_length = radius * 1.2
	
	for i in range(3):
		var y_pos = center.y - radius * 0.4 + i * radius * 0.4
		_draw_rect_on_image(image, Rect2(center.x - line_length/2, y_pos - line_width/2, line_length, line_width), color)

func _draw_settings_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw gear/settings icon"""
	# Central circle
	_draw_circle_on_image(image, center, radius * 0.3, color)
	
	# Gear teeth
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		var inner = Vector2(center.x + cos(rad) * radius * 0.5, center.y + sin(rad) * radius * 0.5)
		var outer = Vector2(center.x + cos(rad) * radius * 0.8, center.y + sin(rad) * radius * 0.8)
		_draw_line_on_image(image, inner, outer, color)

func _draw_inventory_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw inventory bag icon"""
	# Bag body
	var bag_points = [
		Vector2(center.x - radius * 0.6, center.y - radius * 0.2),
		Vector2(center.x + radius * 0.6, center.y - radius * 0.2),
		Vector2(center.x + radius * 0.4, center.y + radius * 0.8),
		Vector2(center.x - radius * 0.4, center.y + radius * 0.8)
	]
	_draw_polygon(image, bag_points, color)
	
	# Bag handles
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.3, center.y - radius * 0.5, radius * 0.1, radius * 0.4), color)
	_draw_rect_on_image(image, Rect2(center.x + radius * 0.2, center.y - radius * 0.5, radius * 0.1, radius * 0.4), color)

func _draw_map_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw map icon"""
	# Map outline
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.8, center.y - radius * 0.6, radius * 1.6, radius * 1.2), color)
	
	# Map details (roads/paths)
	_draw_line_on_image(image, Vector2(center.x - radius * 0.6, center.y - radius * 0.2), Vector2(center.x + radius * 0.6, center.y + radius * 0.2), color.darkened(0.3))
	_draw_line_on_image(image, Vector2(center.x - radius * 0.2, center.y - radius * 0.4), Vector2(center.x + radius * 0.2, center.y + radius * 0.4), color.darkened(0.3))

func _draw_character_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw character/person icon"""
	# Head
	_draw_circle_on_image(image, Vector2(center.x, center.y - radius * 0.4), radius * 0.3, color)
	
	# Body
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.2, center.y - radius * 0.1, radius * 0.4, radius * 0.6), color)
	
	# Arms
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.6, center.y, radius * 0.3, radius * 0.1), color)
	_draw_rect_on_image(image, Rect2(center.x + radius * 0.3, center.y, radius * 0.3, radius * 0.1), color)
	
	# Legs
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.15, center.y + radius * 0.5, radius * 0.1, radius * 0.3), color)
	_draw_rect_on_image(image, Rect2(center.x + radius * 0.05, center.y + radius * 0.5, radius * 0.1, radius * 0.3), color)

func _draw_spells_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw spells/magic icon"""
	# Magic wand
	_draw_line_on_image(image, Vector2(center.x - radius * 0.5, center.y + radius * 0.5), Vector2(center.x + radius * 0.5, center.y - radius * 0.5), color)
	
	# Magic sparkles
	for i in range(3):
		var spark_x = center.x + (i - 1) * radius * 0.3
		var spark_y = center.y - (i - 1) * radius * 0.3
		_draw_star(image, Vector2(spark_x, spark_y), radius * 0.2, 4, color)

func _draw_pause_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw pause icon"""
	var bar_width = radius * 0.3
	var bar_height = radius * 1.2
	
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.4, center.y - bar_height/2, bar_width, bar_height), color)
	_draw_rect_on_image(image, Rect2(center.x + radius * 0.1, center.y - bar_height/2, bar_width, bar_height), color)

func _draw_play_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw play icon"""
	var play_points = [
		Vector2(center.x - radius * 0.4, center.y - radius * 0.6),
		Vector2(center.x + radius * 0.6, center.y),
		Vector2(center.x - radius * 0.4, center.y + radius * 0.6)
	]
	_draw_polygon(image, play_points, color)

func _draw_close_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw close (X) icon"""
	_draw_line_on_image(image, Vector2(center.x - radius * 0.6, center.y - radius * 0.6), Vector2(center.x + radius * 0.6, center.y + radius * 0.6), color)
	_draw_line_on_image(image, Vector2(center.x - radius * 0.6, center.y + radius * 0.6), Vector2(center.x + radius * 0.6, center.y - radius * 0.6), color)

func _draw_arrow_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw arrow icon"""
	var arrow_points = [
		Vector2(center.x + radius * 0.6, center.y),
		Vector2(center.x + radius * 0.2, center.y - radius * 0.4),
		Vector2(center.x + radius * 0.2, center.y - radius * 0.2),
		Vector2(center.x - radius * 0.6, center.y - radius * 0.2),
		Vector2(center.x - radius * 0.6, center.y + radius * 0.2),
		Vector2(center.x + radius * 0.2, center.y + radius * 0.2),
		Vector2(center.x + radius * 0.2, center.y + radius * 0.4)
	]
	_draw_polygon(image, arrow_points, color)

func _draw_generic_ui_icon(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw generic UI icon"""
	_draw_rect_on_image(image, Rect2(center.x - radius * 0.6, center.y - radius * 0.6, radius * 1.2, radius * 1.2), color)

# Status effect symbols
func _draw_flame_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw flame symbol"""
	var flame_points = [
		Vector2(center.x, center.y + radius),
		Vector2(center.x - radius * 0.3, center.y),
		Vector2(center.x - radius * 0.1, center.y - radius * 0.7),
		Vector2(center.x + radius * 0.1, center.y - radius * 0.7),
		Vector2(center.x + radius * 0.3, center.y)
	]
	_draw_polygon(image, flame_points, color)

func _draw_snowflake_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw snowflake symbol"""
	# Main cross
	_draw_line_on_image(image, Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), color)
	_draw_line_on_image(image, Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), color)
	
	# Diagonal lines
	_draw_line_on_image(image, Vector2(center.x - radius * 0.7, center.y - radius * 0.7), Vector2(center.x + radius * 0.7, center.y + radius * 0.7), color)
	_draw_line_on_image(image, Vector2(center.x - radius * 0.7, center.y + radius * 0.7), Vector2(center.x + radius * 0.7, center.y - radius * 0.7), color)

func _draw_poison_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw poison drop symbol"""
	# Teardrop shape
	_draw_circle_on_image(image, Vector2(center.x, center.y + radius * 0.3), radius * 0.6, color)
	
	var drop_tip = Vector2(center.x, center.y - radius * 0.7)
	var drop_left = Vector2(center.x - radius * 0.3, center.y)
	var drop_right = Vector2(center.x + radius * 0.3, center.y)
	
	_draw_polygon(image, [drop_tip, drop_left, drop_right], color)

func _draw_shield_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw shield symbol"""
	var shield_points = [
		Vector2(center.x, center.y - radius),
		Vector2(center.x + radius * 0.6, center.y - radius * 0.4),
		Vector2(center.x + radius * 0.6, center.y + radius * 0.2),
		Vector2(center.x, center.y + radius),
		Vector2(center.x - radius * 0.6, center.y + radius * 0.2),
		Vector2(center.x - radius * 0.6, center.y - radius * 0.4)
	]
	_draw_polygon(image, shield_points, color)

func _draw_speed_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw speed/wind lines symbol"""
	for i in range(3):
		var y_offset = (i - 1) * radius * 0.3
		var start_x = center.x - radius * 0.6
		var end_x = center.x + radius * 0.6 - i * radius * 0.2
		
		_draw_line_on_image(image, Vector2(start_x, center.y + y_offset), Vector2(end_x, center.y + y_offset), color)

func _draw_strength_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw strength/muscle symbol"""
	# Flexed arm silhouette
	var arm_points = [
		Vector2(center.x - radius * 0.4, center.y + radius * 0.6),
		Vector2(center.x - radius * 0.6, center.y),
		Vector2(center.x - radius * 0.2, center.y - radius * 0.8),
		Vector2(center.x + radius * 0.2, center.y - radius * 0.6),
		Vector2(center.x + radius * 0.6, center.y - radius * 0.2),
		Vector2(center.x + radius * 0.4, center.y + radius * 0.6)
	]
	_draw_polygon(image, arm_points, color)

func _draw_generic_effect_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw generic effect symbol"""
	_draw_star(image, center, radius, 6, color)

# Element symbols
func _draw_fire_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw fire element symbol"""
	_draw_flame_symbol(image, center, radius, color)

func _draw_ice_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw ice element symbol"""
	_draw_snowflake_symbol(image, center, radius, color)

func _draw_lightning_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw lightning element symbol"""
	var bolt_points = [
		Vector2(center.x - radius * 0.2, center.y - radius),
		Vector2(center.x + radius * 0.4, center.y - radius * 0.2),
		Vector2(center.x, center.y),
		Vector2(center.x + radius * 0.2, center.y + radius),
		Vector2(center.x - radius * 0.4, center.y + radius * 0.2),
		Vector2(center.x, center.y)
	]
	_draw_polygon(image, bolt_points, color)

func _draw_shadow_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw shadow element symbol"""
	# Crescent moon
	_draw_circle_on_image(image, center, radius, color)
	_draw_circle_on_image(image, Vector2(center.x + radius * 0.3, center.y), radius * 0.8, Color(0, 0, 0, 1))

func _draw_earth_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw earth element symbol"""
	# Mountain/rock shape
	var mountain_points = [
		Vector2(center.x, center.y - radius),
		Vector2(center.x + radius * 0.8, center.y + radius),
		Vector2(center.x - radius * 0.8, center.y + radius)
	]
	_draw_polygon(image, mountain_points, color)

func _draw_light_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw light element symbol"""
	# Sun with rays
	_draw_circle_on_image(image, center, radius * 0.4, color)
	
	for angle in range(0, 360, 45):
		var rad = deg_to_rad(angle)
		var inner = Vector2(center.x + cos(rad) * radius * 0.5, center.y + sin(rad) * radius * 0.5)
		var outer = Vector2(center.x + cos(rad) * radius * 0.9, center.y + sin(rad) * radius * 0.9)
		_draw_line_on_image(image, inner, outer, color)

func _draw_arcane_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw arcane element symbol"""
	# Mystical sigil
	_draw_circle_on_image(image, center, radius * 0.8, color)
	_draw_circle_on_image(image, center, radius * 0.4, color)
	
	for angle in range(0, 360, 60):
		var rad = deg_to_rad(angle)
		var point = Vector2(center.x + cos(rad) * radius * 0.6, center.y + sin(rad) * radius * 0.6)
		_draw_line_on_image(image, center, point, color)

func _draw_nature_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw nature element symbol"""
	# Leaf shape
	var leaf_points = [
		Vector2(center.x, center.y - radius),
		Vector2(center.x + radius * 0.5, center.y - radius * 0.3),
		Vector2(center.x + radius * 0.3, center.y + radius * 0.5),
		Vector2(center.x, center.y + radius),
		Vector2(center.x - radius * 0.3, center.y + radius * 0.5),
		Vector2(center.x - radius * 0.5, center.y - radius * 0.3)
	]
	_draw_polygon(image, leaf_points, color)
	
	# Leaf vein
	_draw_line_on_image(image, Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), color.darkened(0.3))

func _draw_generic_element_symbol(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw generic element symbol"""
	_draw_circle_on_image(image, center, radius, color)

# Utility methods
func _get_rarity_color(rarity: String) -> Color:
	"""Get color based on item rarity"""
	match rarity:
		"common":
			return Color.WHITE
		"uncommon":
			return Color.GREEN
		"rare":
			return Color.BLUE
		"epic":
			return Color.PURPLE
		"legendary":
			return Color.ORANGE
		"mythic":
			return Color.RED
		_:
			return Color.GRAY

func _get_effect_color(effect_type: String) -> Color:
	"""Get color based on effect type"""
	match effect_type:
		"buff":
			return Color.GREEN
		"debuff":
			return Color.RED
		"neutral":
			return Color.BLUE
		_:
			return Color.GRAY

# Drawing utilities
func _draw_circle_with_border(image: Image, center: Vector2, radius: float, fill_color: Color, border_color: Color, border_width: int) -> void:
	"""Draw a circle with border"""
	# Fill
	_draw_circle_on_image(image, center, radius, fill_color)
	
	# Border
	for i in range(border_width):
		_draw_circle_outline(image, center, radius - i, border_color)

func _draw_circle_outline(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw circle outline"""
	var size = image.get_width()
	
	for angle in range(0, 360, 2):
		var rad = deg_to_rad(angle)
		var x = int(center.x + cos(rad) * radius)
		var y = int(center.y + sin(rad) * radius)
		
		if x >= 0 and x < size and y >= 0 and y < size:
			image.set_pixel(x, y, color)

func _draw_circle_on_image(image: Image, center: Vector2, radius: float, color: Color) -> void:
	"""Draw filled circle on image"""
	var size = image.get_width()
	
	for x in range(max(0, center.x - radius), min(size, center.x + radius + 1)):
		for y in range(max(0, center.y - radius), min(size, center.y + radius + 1)):
			var distance = Vector2(x - center.x, y - center.y).length()
			if distance <= radius:
				image.set_pixel(x, y, color)

func _draw_rect_on_image(image: Image, rect: Rect2, color: Color) -> void:
	"""Draw filled rectangle on image"""
	var size = image.get_width()
	
	for x in range(max(0, rect.position.x), min(size, rect.position.x + rect.size.x)):
		for y in range(max(0, rect.position.y), min(size, rect.position.y + rect.size.y)):
			image.set_pixel(x, y, color)

func _draw_line_on_image(image: Image, start: Vector2, end: Vector2, color: Color) -> void:
	"""Draw line on image"""
	var distance = start.distance_to(end)
	var steps = int(distance)
	
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var point = start.lerp(end, t)
		var x = int(point.x)
		var y = int(point.y)
		
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)

func _draw_polygon(image: Image, points: Array, color: Color) -> void:
	"""Draw filled polygon on image"""
	if points.size() < 3:
		return
	
	# Simple polygon fill using scanline method
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
				var start_x = int(intersections[i])
				var end_x = int(intersections[i + 1])
				
				for x in range(start_x, end_x + 1):
					if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
						image.set_pixel(x, y, color)

func _draw_star(image: Image, center: Vector2, radius: float, points: int, color: Color) -> void:
	"""Draw star shape"""
	var star_points = []
	var angle_step = 2 * PI / points
	
	for i in range(points):
		var angle = i * angle_step - PI / 2
		var outer_x = center.x + cos(angle) * radius
		var outer_y = center.y + sin(angle) * radius
		star_points.append(Vector2(outer_x, outer_y))
		
		var inner_angle = angle + angle_step / 2
		var inner_x = center.x + cos(inner_angle) * radius * 0.5
		var inner_y = center.y + sin(inner_angle) * radius * 0.5
		star_points.append(Vector2(inner_x, inner_y))
	
	_draw_polygon(image, star_points, color)

func clear_cache() -> void:
	"""Clear the icon cache"""
	icon_cache.clear()
	print("[IconGenerator] Icon cache cleared")

func get_cached_icon(icon_name: String) -> ImageTexture:
	"""Get a cached icon by name"""
	return icon_cache.get(icon_name, null)

func get_available_icon_sizes() -> Array:
	"""Get available icon sizes"""
	return ICON_SIZES.keys()

func get_available_elements() -> Array:
	"""Get available element types"""
	return ELEMENT_COLORS.keys()