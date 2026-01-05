# CoinPickup.gd
# Moneda que cae de los enemigos y el player puede recoger
# Sistema estilo Brotato: aparece en el suelo, atracción + recolección

extends Area2D
class_name CoinPickup

signal coin_collected(value: int)

# === CONFIGURACIÓN ===
@export var coin_value: int = 1
@export var lifetime: float = 45.0  # Segundos antes de desaparecer
@export var attraction_speed: float = 400.0  # Velocidad cuando es atraída
@export var base_attraction_range: float = 120.0  # Rango base de atracción

# === ESTADO ===
var is_being_attracted: bool = false
var player_ref: Node2D = null
var life_timer: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var spawn_velocity: Vector2 = Vector2.ZERO  # Velocidad inicial al spawnear
var friction: float = 5.0  # Fricción para el movimiento inicial

# === VISUAL ===
var sprite: Sprite2D = null
var animation_tween: Tween = null
var glow_tween: Tween = null

# === COLORES POR VALOR ===
const COIN_COLORS = {
	1: Color(0.85, 0.65, 0.13),    # Cobre/Bronce
	5: Color(0.75, 0.75, 0.75),    # Plata
	10: Color(1.0, 0.84, 0.0),     # Oro
	25: Color(0.0, 0.8, 0.8),      # Diamante/Cyan
	50: Color(0.7, 0.3, 1.0),      # Púrpura/Épico
}

func _ready() -> void:
	# Configurar área de colisión
	_setup_collision()
	
	# Crear visual
	_setup_visual()
	
	# Conectar señales
	body_entered.connect(_on_body_entered)
	
	# Añadir al grupo para fácil acceso
	add_to_group("coins")
	
	# Z-index para que esté sobre el suelo pero debajo de entidades
	z_index = 5

func initialize(pos: Vector2, value: int = 1, player: Node2D = null) -> void:
	"""Inicializar la moneda con posición, valor y referencia al player"""
	global_position = pos
	coin_value = value
	player_ref = player
	
	# Dar velocidad inicial aleatoria para que "salte" del enemigo
	var random_angle = randf() * TAU
	var random_force = randf_range(80.0, 150.0)
	spawn_velocity = Vector2(cos(random_angle), sin(random_angle)) * random_force
	
	# Actualizar visual según valor
	_update_visual_for_value()

func _setup_collision() -> void:
	"""Configurar el área de colisión"""
	# Capa de colisión: pickups (5)
	collision_layer = 0
	set_collision_layer_value(5, true)
	
	# Máscara: detectar player (1)
	collision_mask = 0
	set_collision_mask_value(1, true)
	
	# Crear CollisionShape si no existe
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		collision.shape = shape
		add_child(collision)

func _setup_visual() -> void:
	"""Crear el sprite de la moneda"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	# Intentar cargar sprite real, si no existe usar fallback
	var sprite_path = "res://assets/sprites/pickups/coins/coin_gold.png"
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		_create_fallback_texture()
	
	sprite.centered = true
	
	# Iniciar animación de flotación
	_start_float_animation()

func _create_fallback_texture() -> void:
	"""Crear textura procedural si no hay sprite"""
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 1.0
	
	# Color según valor
	var coin_color = _get_color_for_value()
	var highlight_color = coin_color.lightened(0.4)
	var shadow_color = coin_color.darkened(0.3)
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius:
				# Dentro del círculo
				var intensity = 1.0 - (dist / radius)
				
				# Crear efecto 3D con highlight arriba-izquierda
				var angle_to_center = atan2(y - center.y, x - center.x)
				var highlight_factor = max(0, -sin(angle_to_center - PI/4)) * 0.5
				
				var final_color = coin_color.lerp(highlight_color, highlight_factor + intensity * 0.3)
				
				# Borde más oscuro
				if dist > radius - 2:
					final_color = shadow_color
				
				image.set_pixel(x, y, final_color)
			elif dist <= radius + 1:
				# Borde con antialiasing
				var alpha = 1.0 - (dist - radius)
				image.set_pixel(x, y, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

func _get_color_for_value() -> Color:
	"""Obtener color según el valor de la moneda"""
	# Buscar el color más cercano según el valor
	var best_color = COIN_COLORS[1]
	var best_threshold = 1
	
	for threshold in COIN_COLORS.keys():
		if coin_value >= threshold and threshold >= best_threshold:
			best_color = COIN_COLORS[threshold]
			best_threshold = threshold
	
	return best_color

func _update_visual_for_value() -> void:
	"""Actualizar visual cuando cambia el valor"""
	if sprite:
		# Si es fallback, recrear textura
		if not ResourceLoader.exists("res://assets/sprites/pickups/coins/coin_gold.png"):
			_create_fallback_texture()
		
		# Escalar según valor
		var scale_factor = 1.0
		if coin_value >= 50:
			scale_factor = 1.4
		elif coin_value >= 25:
			scale_factor = 1.3
		elif coin_value >= 10:
			scale_factor = 1.2
		elif coin_value >= 5:
			scale_factor = 1.1
		
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Añadir glow para monedas valiosas
		if coin_value >= 10:
			_add_glow_effect()

func _start_float_animation() -> void:
	"""Animación de flotación suave"""
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_loops()
	animation_tween.tween_property(sprite, "position:y", -3.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	animation_tween.tween_property(sprite, "position:y", 3.0, 0.5).set_ease(Tween.EASE_IN_OUT)

func _add_glow_effect() -> void:
	"""Añadir efecto de brillo pulsante para monedas valiosas"""
	if glow_tween:
		glow_tween.kill()
	
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(sprite, "modulate:a", 0.7, 0.3)
	glow_tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func _process(delta: float) -> void:
	# Actualizar timer de vida
	life_timer += delta
	
	# Parpadear cuando está por desaparecer
	if life_timer > lifetime - 5.0:
		_blink_warning()
	
	if life_timer >= lifetime:
		queue_free()
		return
	
	# Aplicar velocidad inicial (decae con fricción)
	if spawn_velocity.length() > 1.0:
		global_position += spawn_velocity * delta
		spawn_velocity = spawn_velocity.lerp(Vector2.ZERO, friction * delta)
	
	# Buscar player si no tenemos referencia
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = _find_player()
	
	if not player_ref:
		return
	
	# Calcular distancia al player
	var distance = global_position.distance_to(player_ref.global_position)
	
	# Obtener rango de atracción dinámicamente del player
	var attraction_range = _get_player_pickup_range()
	
	# Atracción
	if distance <= attraction_range:
		is_being_attracted = true
		var direction = (player_ref.global_position - global_position).normalized()
		
		# Velocidad aumenta mientras más cerca
		var speed_multiplier = 1.0 + (1.0 - distance / attraction_range) * 2.0
		global_position += direction * attraction_speed * speed_multiplier * delta

func _get_player_pickup_range() -> float:
	"""Obtener el rango de recolección del player (respeta mejoras)"""
	if player_ref and player_ref.has_method("get_pickup_range"):
		return player_ref.get_pickup_range()
	elif player_ref and _has_property(player_ref, "pickup_radius"):
		var base = player_ref.pickup_radius
		var mult = player_ref.magnet if _has_property(player_ref, "magnet") else 1.0
		return base * mult
	return base_attraction_range

func _find_player() -> Node2D:
	"""Buscar el player en el árbol"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _blink_warning() -> void:
	"""Parpadear para indicar que va a desaparecer"""
	if sprite and not is_being_attracted:
		var blink_speed = 0.15
		var should_hide = int(life_timer / blink_speed) % 2 == 0
		sprite.visible = not should_hide

func _on_body_entered(body: Node2D) -> void:
	"""Cuando el player toca la moneda"""
	if body.is_in_group("player"):
		_collect(body)

func _collect(collector: Node2D) -> void:
	"""Recolectar la moneda"""
	# Emitir señal
	coin_collected.emit(coin_value)
	
	# Efecto visual de recolección
	_spawn_collection_effect()
	
	# Notificar al ExperienceManager si existe
	var exp_manager = _find_experience_manager()
	if exp_manager and exp_manager.has_method("on_coin_collected"):
		exp_manager.on_coin_collected(coin_value, global_position)
	
	print("🪙 Moneda recogida: +%d" % coin_value)
	
	# Destruir
	queue_free()

func _spawn_collection_effect() -> void:
	"""Crear efecto visual al recoger"""
	# Crear texto flotante "+X"
	var text_scene_path = "res://scenes/ui/FloatingText.tscn"
	if ResourceLoader.exists(text_scene_path):
		var text_scene = load(text_scene_path)
		var text_instance = text_scene.instantiate()
		get_tree().current_scene.add_child(text_instance)
		text_instance.global_position = global_position
		if text_instance.has_method("setup"):
			text_instance.setup("+%d" % coin_value, _get_color_for_value())
	else:
		# Fallback: crear texto simple
		_create_simple_floating_text()

func _create_simple_floating_text() -> void:
	"""Crear texto flotante simple sin escena"""
	var label = Label.new()
	label.text = "+%d" % coin_value
	label.add_theme_color_override("font_color", _get_color_for_value())
	label.add_theme_font_size_override("font_size", 14)
	label.global_position = global_position - Vector2(10, 20)
	get_tree().current_scene.add_child(label)
	
	# Animación de subir y desaparecer
	var tween = label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 30, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _find_experience_manager() -> Node:
	"""Buscar ExperienceManager en el árbol"""
	var tree = get_tree()
	if tree and tree.root:
		# Buscar como hermano del Game
		var game = tree.root.get_node_or_null("Game")
		if game:
			return game.get_node_or_null("ExperienceManager")
		# Buscar en root
		return tree.root.get_node_or_null("ExperienceManager")
	return null

func _has_property(obj: Object, prop_name: String) -> bool:
	"""Verificar si un objeto tiene una propiedad"""
	if not obj:
		return false
	for p in obj.get_property_list():
		if p.has("name") and p.name == prop_name:
			return true
	return false
