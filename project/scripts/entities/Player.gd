extends CharacterBody2D

# Velocidad del jugador
@export var speed = 200.0

# Referencias a los sprites direccionales
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

# Variables de estado
var current_direction = "down"

# Texturas de sprites direccionales
var wizard_sprites = {}

# Escalado genérico usando ScaleManager
var base_sprite_size = 500.0  # Tamaño original de los sprites del wizard
var target_size = 64.0        # Tamaño objetivo en píxeles

func _ready():
	print("Player inicializado")
	z_index = 10  # Asegurar que el wizard esté por encima de las paredes
	
	# Conectar al ScaleManager para escalado automático
	if ScaleManager:
		ScaleManager.scale_changed.connect(_on_scale_changed)
	
	load_wizard_sprites()

func load_wizard_sprites(custom_scale_factor: float = 0.0):
	# Cargar los sprites del wizard
	wizard_sprites["down"] = load("res://sprites/wizard/wizard_down.png")
	wizard_sprites["up"] = load("res://sprites/wizard/wizard_up.png")
	wizard_sprites["left"] = load("res://sprites/wizard/wizard_left.png")
	wizard_sprites["right"] = load("res://sprites/wizard/wizard_right.png")
	
	# Verificar que se cargaron correctamente
	for direction in wizard_sprites:
		if wizard_sprites[direction]:
			print("Sprite cargado: ", direction, " - ", wizard_sprites[direction].get_size())
		else:
			print("Error cargando sprite: ", direction)
	
	# Establecer sprite inicial y escalar
	if sprite:
		sprite.texture = wizard_sprites["down"]
		sprite.z_index = 15  # Sprite del wizard por encima de todo
		
		# Aplicar escalado usando ScaleManager
		apply_correct_scale()

func apply_correct_scale():
	"""Aplicar escalado correcto usando ScaleManager"""
	if not sprite or not sprite.texture:
		return
		
	# Obtener escala actual del ScaleManager
	var scene_scale = 1.0
	if ScaleManager:
		scene_scale = ScaleManager.get_scale()
	
	# Calcular escalado basándose en el tamaño original del sprite
	var sprite_original_size = sprite.texture.get_size().x  # Asumiendo sprite cuadrado
	var base_scale_factor = target_size / sprite_original_size
	
	# Aplicar escala combinada: base + escala de escena
	var final_scale = base_scale_factor * scene_scale
	sprite.scale = Vector2(final_scale, final_scale)
	
	# Actualizar también el collider si existe
	update_collision_radius()
	
	print("🧙‍♂️ Wizard escalado - Original: ", sprite_original_size, 
		  " → Objetivo: ", target_size, 
		  " × Escena: ", scene_scale, 
		  " = Final: ", final_scale)

func update_collision_radius():
	"""Actualizar radio del collider usando ScaleManager"""
	if collision_shape and collision_shape.shape and ScaleManager:
		var new_radius = ScaleManager.get_player_collision_radius()
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = new_radius
			print("🔵 Collider actualizado - Radio: ", new_radius)

func _physics_process(delta):
	handle_movement(delta)
	update_sprite_direction()

func handle_movement(delta):
	# Obtener dirección de movimiento con WASD
	var input_vector = Vector2()
	
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	
	# Normalizar y aplicar velocidad
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 3)
	
	# Mover con colisiones
	move_and_slide()

func update_sprite_direction():
	if not sprite or wizard_sprites.is_empty():
		return
		
	# Determinar dirección basada en la velocidad
	if velocity.length() > 10:  # Solo cambiar si hay movimiento significativo
		var old_direction = current_direction
		if abs(velocity.x) > abs(velocity.y):
			# Movimiento horizontal dominante
			current_direction = "right" if velocity.x > 0 else "left"
		else:
			# Movimiento vertical dominante
			current_direction = "down" if velocity.y > 0 else "up"
		
		# Actualizar sprite solo si cambió la dirección
		if old_direction != current_direction:
			if current_direction in wizard_sprites:
				sprite.texture = wizard_sprites[current_direction]
				print("Sprite cambiado a: ", current_direction)

func get_facing_direction():
	return current_direction

# Función para actualizar la escala del wizard desde el sistema de habitaciones
func update_scale(scale_factor: float = 0.0):
	"""Actualizar escala del wizard - usa ScaleManager si no se proporciona factor"""
	if scale_factor > 0.0:
		# Usar factor personalizado si se proporciona
		if sprite:
			sprite.scale = Vector2(scale_factor, scale_factor)
			print("Escala del wizard actualizada a factor personalizado: ", scale_factor)
	else:
		# Usar ScaleManager para escalado automático
		apply_correct_scale()

func _on_scale_changed(new_scale: float):
	"""Responder automáticamente a cambios de escala del ScaleManager"""
	print("🔄 Wizard respondiendo a cambio de escala: ", new_scale)
	apply_correct_scale()
