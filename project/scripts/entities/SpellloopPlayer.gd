extends CharacterBody2D
class_name SpellloopPlayer

"""
🧙‍♂️ SPELLLOOP PLAYER - PLAYER FIJO EN CENTRO
============================================

Player estilo roguelike top-down:
- Permanece fijo en el centro de la pantalla
- WASD mueve el mundo, no al player
- Auto-ataque mágico hacia enemigos
"""

signal movement_input(movement_delta: Vector2)
signal player_stats_changed(stats: Dictionary)

# Configuración
@export var movement_speed: float = 200.0
@export var health: int = 100
@export var max_health: int = 100

# Referencias a componentes
@onready var sprite: Sprite2D
@onready var collision_shape: CollisionShape2D

# Estado del player
var current_direction: String = "down"
var wizard_sprites: Dictionary = {}
var player_stats: Dictionary = {}

# Escalado usando ScaleManager
var base_sprite_size: float = 500.0
var target_size: float = 64.0

func _ready():
	print("🧙‍♂️ SpellloopPlayer inicializado")
	setup_player()
	
	# Conectar al ScaleManager
	if ScaleManager:
		ScaleManager.scale_changed.connect(_on_scale_changed)

func setup_player():
	"""Configurar el player inicial"""
	z_index = 100  # Por encima de todo
	
	# Crear sprite si no existe
	if not sprite:
		create_sprite()
	
	# Crear collider si no existe
	if not collision_shape:
		create_collision()
	
	# Cargar sprites del wizard
	load_wizard_sprites()
	
	# Inicializar stats
	update_player_stats()

func create_sprite():
	"""Crear sprite del player"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.z_index = 15
	add_child(sprite)

func create_collision():
	"""Crear collider del player"""
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	
	var circle = CircleShape2D.new()
	circle.radius = 26.0
	collision_shape.shape = circle
	
	add_child(collision_shape)

func load_wizard_sprites():
	"""Cargar sprites direccionales del wizard"""
	wizard_sprites["down"] = load("res://sprites/wizard/wizard_down.png")
	wizard_sprites["up"] = load("res://sprites/wizard/wizard_up.png")
	wizard_sprites["left"] = load("res://sprites/wizard/wizard_left.png")
	wizard_sprites["right"] = load("res://sprites/wizard/wizard_right.png")
	
	# Verificar carga
	for direction in wizard_sprites:
		if wizard_sprites[direction]:
			print("✅ Sprite cargado: ", direction)
		else:
			print("❌ Error cargando sprite: ", direction)
	
	# Establecer sprite inicial y aplicar escala
	if sprite and wizard_sprites.has("down"):
		sprite.texture = wizard_sprites["down"]
		apply_correct_scale()

func apply_correct_scale():
	"""Aplicar escalado usando ScaleManager"""
	if not sprite or not sprite.texture:
		return
	
	# Obtener escala del ScaleManager
	var scene_scale = 1.0
	if ScaleManager:
		scene_scale = ScaleManager.get_scale()
	
	# Calcular escalado final
	var sprite_original_size = sprite.texture.get_size().x
	var base_scale_factor = target_size / sprite_original_size
	var final_scale = base_scale_factor * scene_scale
	
	sprite.scale = Vector2(final_scale, final_scale)
	
	# Actualizar collider también
	update_collision_radius()
	
	print("🧙‍♂️ SpellloopPlayer escalado: ", final_scale)

func update_collision_radius():
	"""Actualizar radio del collider"""
	if collision_shape and collision_shape.shape and ScaleManager:
		var new_radius = ScaleManager.get_player_collision_radius()
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = new_radius

func _physics_process(delta):
	"""Procesar input y movimiento (que mueve el mundo)"""
	handle_movement_input(delta)
	update_sprite_direction()

func handle_movement_input(delta):
	"""Manejar input de movimiento - MUEVE EL MUNDO, NO EL PLAYER"""
	var input_vector = Vector2()
	
	# Obtener input WASD
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	
	# Si hay movimiento, emitir señal para mover el mundo
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var movement_delta = input_vector * movement_speed * delta
		
		# Emitir señal para que el mundo se mueva
		movement_input.emit(movement_delta)
		
		# Guardar velocity para animaciones (aunque el player no se mueva)
		velocity = input_vector * movement_speed
	else:
		velocity = Vector2.ZERO

func update_sprite_direction():
	"""Actualizar dirección del sprite basándose en el input"""
	if not sprite or wizard_sprites.is_empty():
		return
	
	# Cambiar sprite según la dirección del movimento
	if velocity.length() > 10:
		var old_direction = current_direction
		
		if abs(velocity.x) > abs(velocity.y):
			current_direction = "right" if velocity.x > 0 else "left"
		else:
			current_direction = "down" if velocity.y > 0 else "up"
		
		# Actualizar sprite si cambió
		if old_direction != current_direction:
			if current_direction in wizard_sprites:
				sprite.texture = wizard_sprites[current_direction]

func take_damage(amount: int):
	"""Recibir daño"""
	health = max(0, health - amount)
	update_player_stats()
	
	if health <= 0:
		die()

func heal(amount: int):
	"""Curar vida"""
	health = min(max_health, health + amount)
	update_player_stats()

func die():
	"""Muerte del player"""
	print("💀 Player ha muerto!")
	# Aquí se manejaría game over

func update_player_stats():
	"""Actualizar y emitir estadísticas del player"""
	player_stats = {
		"health": health,
		"max_health": max_health,
		"level": 1,  # Se actualizará desde ExperienceManager
		"position": position
	}
	
	player_stats_changed.emit(player_stats)

func get_stats() -> Dictionary:
	"""Obtener estadísticas del player"""
	return player_stats.duplicate()

func _on_scale_changed(new_scale: float):
	"""Responder a cambios de escala del ScaleManager"""
	apply_correct_scale()

# Función para compatibilidad con sistemas existentes
func get_facing_direction() -> String:
	return current_direction
