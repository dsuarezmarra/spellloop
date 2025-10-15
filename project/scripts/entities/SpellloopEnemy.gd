extends CharacterBody2D
class_name SpellloopEnemy

"""
👹 ENEMIGO SPELLLOOP
==================

Enemigo básico que se mueve hacia el player:
- AI simple de seguimiento
- Daño por contacto
- Sistema de vida
- Drop de EXP al morir
"""

signal enemy_died(enemy: Node2D, enemy_type_id: String, exp_value: int)
signal enemy_hit_player(damage: int)

# Propiedades del enemigo
var enemy_type_id: String
var enemy_name: String
var max_health: int
var current_health: int
var movement_speed: float
var damage: int
var exp_value: int

# Referencias
var player: CharacterBody2D
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var health_bar: ProgressBar

# Estado
var is_dead: bool = false
var damage_cooldown: float = 0.0
var damage_interval: float = 1.0  # Daño cada segundo

# Configuración visual
var enemy_color: Color = Color.RED
var enemy_size: float = 32.0

func _ready():
	setup_enemy()

func initialize(enemy_type: EnemyManager.EnemyType, player_ref: CharacterBody2D):
	"""Inicializar enemigo con tipo específico"""
	enemy_type_id = enemy_type.id
	enemy_name = enemy_type.name
	max_health = enemy_type.health
	current_health = max_health
	movement_speed = enemy_type.speed
	damage = enemy_type.damage
	exp_value = enemy_type.exp_value
	enemy_color = enemy_type.color
	enemy_size = enemy_type.size
	
	player = player_ref
	
	print("👹 Enemigo inicializado: ", enemy_name)

func setup_enemy():
	"""Configurar componentes del enemigo"""
	z_index = 30  # Por encima del mundo, debajo del player
	
	# Configurar colisiones
	collision_layer = 16   # Capa de enemigos
	collision_mask = 8     # Colisiona con proyectiles
	
	# Crear sprite
	create_sprite()
	
	# Crear collider
	create_collision()
	
	# Crear barra de vida (opcional)
	#create_health_bar()

func create_sprite():
	"""Crear sprite del enemigo"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
	
	# Crear textura procedural
	create_enemy_texture()
	
	# Aplicar escala
	var scale_factor = 1.0
	if ScaleManager:
		scale_factor = ScaleManager.get_scale()
	sprite.scale = Vector2(scale_factor, scale_factor)

func create_enemy_texture():
	"""Crear textura procedural del enemigo"""
	var size = int(enemy_size)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Crear forma básica del enemigo
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2 - 2
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= radius:
				var intensity = 1.0 - (distance / radius) * 0.3
				var color = enemy_color * intensity
				color.a = 0.9
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	# Añadir algunos detalles (ojos simples)
	if size >= 32:
		add_simple_eyes(image, center, size)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func add_simple_eyes(image: Image, center: Vector2, size: int):
	"""Añadir ojos simples al enemigo"""
	var eye_size = 3
	var eye_offset_x = size / 6
	var eye_offset_y = size / 8
	
	# Ojo izquierdo
	var left_eye = center + Vector2(-eye_offset_x, -eye_offset_y)
	for dx in range(-eye_size, eye_size + 1):
		for dy in range(-eye_size, eye_size + 1):
			var eye_pos = left_eye + Vector2(dx, dy)
			if eye_pos.x >= 0 and eye_pos.x < size and eye_pos.y >= 0 and eye_pos.y < size:
				if Vector2(dx, dy).length() <= eye_size:
					image.set_pixel(int(eye_pos.x), int(eye_pos.y), Color.BLACK)
	
	# Ojo derecho
	var right_eye = center + Vector2(eye_offset_x, -eye_offset_y)
	for dx in range(-eye_size, eye_size + 1):
		for dy in range(-eye_size, eye_size + 1):
			var eye_pos = right_eye + Vector2(dx, dy)
			if eye_pos.x >= 0 and eye_pos.x < size and eye_pos.y >= 0 and eye_pos.y < size:
				if Vector2(dx, dy).length() <= eye_size:
					image.set_pixel(int(eye_pos.x), int(eye_pos.y), Color.BLACK)

func create_collision():
	"""Crear collider del enemigo"""
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	add_child(collision_shape)
	
	var circle = CircleShape2D.new()
	circle.radius = enemy_size / 2 - 2
	collision_shape.shape = circle

func _physics_process(delta):
	"""Actualizar enemigo"""
	if is_dead or not player:
		return
	
	# Actualizar cooldown de daño
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Mover hacia el player
	move_towards_player(delta)
	
	# Verificar colisión con player
	check_player_collision()

func move_towards_player(delta):
	"""Mover hacia el player"""
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * movement_speed
	move_and_slide()

func check_player_collision():
	"""Verificar colisión con el player"""
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider == player and damage_cooldown <= 0:
			deal_damage_to_player()

func deal_damage_to_player():
	"""Causar daño al player"""
	if player.has_method("take_damage"):
		player.take_damage(damage)
	
	damage_cooldown = damage_interval
	enemy_hit_player.emit(damage)
	
	print("⚔️ Enemigo ", enemy_name, " causó ", damage, " de daño al player")

func take_damage(amount: int):
	"""Recibir daño"""
	if is_dead:
		return
	
	current_health -= amount
	
	# Efecto visual de daño
	flash_damage_effect()
	
	# Verificar muerte
	if current_health <= 0:
		die()
	
	print("💥 ", enemy_name, " recibió ", amount, " de daño. Vida: ", current_health, "/", max_health)

func flash_damage_effect():
	"""Efecto visual de recibir daño"""
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE
		
		var tween = Tween.new()
		add_child(tween)
		tween.tween_property(sprite, "modulate", original_modulate, 0.1)
		tween.tween_callback(func(): tween.queue_free())

func die():
	"""Muerte del enemigo"""
	if is_dead:
		return
	
	is_dead = true
	
	# Crear efecto de muerte
	create_death_effect()
	
	# Emitir señal de muerte
	enemy_died.emit(self, enemy_type_id, exp_value)
	
	# Remover del árbol después de un breve delay
	var death_timer = Timer.new()
	add_child(death_timer)
	death_timer.wait_time = 0.2
	death_timer.one_shot = true
	death_timer.timeout.connect(func(): queue_free())
	death_timer.start()
	
	print("💀 ", enemy_name, " ha muerto")

func create_death_effect():
	"""Crear efecto visual de muerte"""
	if sprite:
		# Efecto de desvanecimiento
		var death_tween = Tween.new()
		add_child(death_tween)
		
		# Hacer el enemigo más grande y transparente
		death_tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.5, 0.2)
		death_tween.parallel().tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.2)
		
		# Desactivar colisiones
		collision_shape.set_deferred("disabled", true)

func get_health_percentage() -> float:
	"""Obtener porcentaje de vida"""
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func get_info() -> Dictionary:
	"""Obtener información del enemigo"""
	return {
		"type_id": enemy_type_id,
		"name": enemy_name,
		"health": current_health,
		"max_health": max_health,
		"position": global_position,
		"is_dead": is_dead
	}