extends Area2D

# IsaacItem.gd
# Objetos coleccionables estilo Isaac que modifican las estadísticas del jugador

class_name IsaacItem

# Tipos de objetos disponibles
enum ItemType {
	FIRE_UP,        # Añade efecto de fuego a proyectiles
	ICE_UP,         # Añade efecto de hielo (slow)
	LIGHTNING_UP,   # Añade efecto de rayo (piercing)
	DAMAGE_UP,      # Aumenta daño base
	FIRE_RATE_UP,   # Reduce cooldown de disparos
	MULTI_SHOT,     # Añade proyectiles extra
	HEALTH_UP,      # Aumenta vida máxima
	SPEED_UP        # Aumenta velocidad de movimiento
}

# Propiedades del objeto
@export var item_type: ItemType = ItemType.DAMAGE_UP
@export var item_name: String = "Damage Up"
@export var item_description: String = "Increases damage"
@export var pickup_sound: String = "item_pickup"

# Valores de mejora
var stat_values = {
	ItemType.FIRE_UP: {"fire_effect": true},
	ItemType.ICE_UP: {"ice_effect": true},
	ItemType.LIGHTNING_UP: {"lightning_effect": true},
	ItemType.DAMAGE_UP: {"damage": 5.0},
	ItemType.FIRE_RATE_UP: {"fire_rate": -0.05},  # Reduce cooldown
	ItemType.MULTI_SHOT: {"multi_shot": 1},
	ItemType.HEALTH_UP: {"max_health": 20},
	ItemType.SPEED_UP: {"speed": 50.0}
}

# Colores para cada tipo de objeto
var item_colors = {
	ItemType.FIRE_UP: Color.RED,
	ItemType.ICE_UP: Color.CYAN,
	ItemType.LIGHTNING_UP: Color.YELLOW,
	ItemType.DAMAGE_UP: Color.ORANGE,
	ItemType.FIRE_RATE_UP: Color.GREEN,
	ItemType.MULTI_SHOT: Color.PURPLE,
	ItemType.HEALTH_UP: Color.PINK,
	ItemType.SPEED_UP: Color.BLUE
}

# Componentes visuales
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var pickup_area: Area2D

func _ready():
	print("[IsaacItem] Creating item of type: ", ItemType.keys()[item_type])
	setup_visuals()
	setup_collision()
	setup_signals()
	
	# Configurar propiedades del Area2D
	collision_layer = 16  # Item layer (bit 5)
	collision_mask = 1    # Player layer (bit 1)
	
	# Añadir un poco de movimiento flotante
	create_float_animation()

func setup_visuals():
	"""Crear sprite visual para el objeto"""
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	
	# Color según el tipo de objeto
	var color = item_colors.get(item_type, Color.WHITE)
	image.fill(color)
	
	# Añadir un borde negro para que se vea mejor
	for x in range(24):
		for y in range(24):
			if x == 0 or x == 23 or y == 0 or y == 23:
				image.set_pixel(x, y, Color.BLACK)
	
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func setup_collision():
	"""Configurar área de colisión para recolección"""
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)  # Ligeramente más grande que el sprite
	collision_shape.shape = shape
	add_child(collision_shape)

func setup_signals():
	"""Configurar señales para detectar cuando el jugador toca el objeto"""
	# Conectar señal cuando algo entra en el área
	body_entered.connect(_on_body_entered)

func create_float_animation():
	"""Crear animación de flotación para hacer el objeto más atractivo"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", -5, 1.0)
	tween.tween_property(sprite, "position:y", 5, 1.0)

func _on_body_entered(body):
	"""Cuando el jugador toca el objeto"""
	if body.has_method("collect_item"):  # Verificar que es el jugador
		body.collect_item(self)
		pickup_item()

func pickup_item():
	"""Manejar la recolección del objeto"""
	print("[IsaacItem] Item collected: ", get_item_name())
	
	# Aplicar efectos al PlayerStats
	apply_stat_changes()
	
	# Efectos visuales de recolección ANTES de eliminar
	create_pickup_effect()
	
	# Reproducir sonido (si hay sistema de audio)
	play_pickup_sound()
	
	# Eliminar el objeto DESPUÉS de los efectos
	queue_free()

func apply_stat_changes():
	"""Aplicar cambios a las estadísticas del jugador"""
	var changes = stat_values.get(item_type, {})
	
	for stat_name in changes:
		var value = changes[stat_name]
		
		match stat_name:
			"fire_effect":
				if value:
					PlayerStats.add_fire_effect()
					print("  + Fire effect added!")
			"ice_effect":
				if value:
					PlayerStats.add_ice_effect()
					print("  + Ice effect added!")
			"lightning_effect":
				if value:
					PlayerStats.add_lightning_effect()
					print("  + Lightning effect added!")
			"damage":
				PlayerStats.damage += value
				print("  + Damage increased by ", value, " (now: ", PlayerStats.damage, ")")
			"fire_rate":
				PlayerStats.fire_rate += value  # Negative values reduce cooldown
				PlayerStats.fire_rate = max(0.05, PlayerStats.fire_rate)  # Minimum fire rate
				print("  + Fire rate improved by ", abs(value), " (now: ", PlayerStats.fire_rate, ")")
			"multi_shot":
				PlayerStats.multi_shot += value
				print("  + Multi-shot increased by ", value, " (now: ", PlayerStats.multi_shot, ")")
			"speed":
				# This would need to be applied to the player directly
				print("  + Speed boost: ", value, " (needs player integration)")

func create_pickup_effect():
	"""Crear efecto visual cuando se recoge el objeto"""
	# Crear un efecto de partículas simple
	var effect_sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Llenar con color semi-transparente
	var color = item_colors.get(item_type, Color.WHITE)
	color.a = 0.7
	image.fill(color)
	
	texture.set_image(image)
	effect_sprite.texture = texture
	effect_sprite.global_position = global_position
	
	# Añadir al padre para que persista después de que se elimine este objeto
	var parent = get_parent()
	if parent:
		parent.add_child(effect_sprite)
		
		# Crear el tween en el padre, no en este objeto que se va a destruir
		var tween = parent.create_tween()
		tween.parallel().tween_property(effect_sprite, "scale", Vector2(2, 2), 0.3)
		tween.parallel().tween_property(effect_sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(effect_sprite.queue_free)

func play_pickup_sound():
	"""Reproducir sonido de recolección (placeholder)"""
	print("[Audio] Playing pickup sound: ", pickup_sound)

func get_item_name() -> String:
	"""Obtener nombre legible del objeto"""
	match item_type:
		ItemType.FIRE_UP:
			return "Fire Power"
		ItemType.ICE_UP:
			return "Ice Power"
		ItemType.LIGHTNING_UP:
			return "Lightning Power"
		ItemType.DAMAGE_UP:
			return "Damage Up"
		ItemType.FIRE_RATE_UP:
			return "Fire Rate Up"
		ItemType.MULTI_SHOT:
			return "Multi Shot"
		ItemType.HEALTH_UP:
			return "Health Up"
		ItemType.SPEED_UP:
			return "Speed Up"
		_:
			return "Unknown Item"

func get_item_description() -> String:
	"""Obtener descripción del objeto"""
	match item_type:
		ItemType.FIRE_UP:
			return "Your tears burn enemies!"
		ItemType.ICE_UP:
			return "Your tears slow enemies!"
		ItemType.LIGHTNING_UP:
			return "Your tears pierce through enemies!"
		ItemType.DAMAGE_UP:
			return "Damage +5"
		ItemType.FIRE_RATE_UP:
			return "Tears up!"
		ItemType.MULTI_SHOT:
			return "Double shot!"
		ItemType.HEALTH_UP:
			return "Health +20"
		ItemType.SPEED_UP:
			return "Speed up!"
		_:
			return "Mystery item"

# Función estática para crear objetos aleatorios
static func create_random_item() -> IsaacItem:
	"""Crear un objeto aleatorio"""
	var item = IsaacItem.new()
	var random_type = randi() % ItemType.size()
	item.item_type = random_type
	return item
