extends CharacterBody2D

# Velocidad del jugador
@export var speed = 200.0

# Referencias a los sprites direccionales
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

# Variables de estado
var current_direction = "down"

# Sistema de vida y experiencia
var max_health: int = 100
var current_health: int = 100
var experience: int = 0
var level: int = 1
var status_effects: Dictionary = {}

# Estadísticas modificables por items
var stats = {
	"magic_damage": 1.0,
	"move_speed": 1.0,
	"max_health": 100,
	"max_mana": 50,
	"luck": 1.0,
	"damage_resistance": 0.0
}

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

# ========== MÉTODOS PARA SISTEMA DE ENEMIGOS ==========

func take_damage(amount: int):
	"""Recibir daño de enemigos"""
	# Aplicar resistencia
	var final_damage = int(amount * (1.0 - stats.damage_resistance))
	current_health = max(0, current_health - final_damage)
	
	print("💔 Player recibe ", final_damage, " de daño. Vida: ", current_health, "/", max_health)
	
	# Efecto visual de daño
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Verificar muerte
	if current_health <= 0:
		player_death()
	
	# Actualizar UI
	update_health_ui()

func apply_status_effect(effect_name: String, duration: float, intensity: int):
	"""Aplicar efectos de estado (veneno, ralentización, etc.)"""
	status_effects[effect_name] = {
		"duration": duration,
		"intensity": intensity,
		"timer": 0.0
	}
	
	print("🔮 Efecto aplicado: ", effect_name, " por ", duration, "s (intensidad: ", intensity, ")")

func modify_stat(stat_name: String, value):
	"""Modificar estadísticas por items"""
	if stat_name in stats:
		if typeof(value) == TYPE_FLOAT and value < 10.0:
			# Es un multiplicador
			stats[stat_name] *= value
		else:
			# Es un valor aditivo
			stats[stat_name] += value
		
		print("📊 Stat modificada: ", stat_name, " = ", stats[stat_name])
		
		# Aplicar cambios específicos
		match stat_name:
			"max_health":
				max_health = int(stats[stat_name])
				current_health = min(current_health, max_health)
			"move_speed":
				speed = 200.0 * stats[stat_name]

func apply_special_effect(effect_name: String, item_data: Dictionary):
	"""Aplicar efectos especiales de items únicos"""
	print("✨ Efecto especial aplicado: ", effect_name)
	
	match effect_name:
		"phoenix_rebirth":
			# Implementar renacimiento del fénix
			pass
		"time_manipulation":
			# Implementar manipulación temporal
			pass
		"vampiric_crown":
			# Implementar robo de vida
			pass
		# Agregar más efectos según sea necesario

func gain_experience(amount: int):
	"""Ganar experiencia de orbes XP"""
	experience += amount
	print("⭐ XP ganada: +", amount, " (Total: ", experience, ")")
	
	# Verificar subida de nivel
	check_level_up()
	
	# Actualizar UI
	update_experience_ui()

func check_level_up():
	"""Verificar si el jugador sube de nivel"""
	var required_xp = level * 100  # XP requerida para siguiente nivel
	
	if experience >= required_xp:
		level += 1
		experience -= required_xp
		print("🎉 ¡NIVEL SUBIDO! Nuevo nivel: ", level)
		
		# Aumentar vida al subir de nivel
		max_health += 10
		current_health = max_health
		
		# Trigger para mostrar opciones de mejora
		show_level_up_options()

func show_level_up_options():
	"""Mostrar opciones de mejora al subir nivel"""
	# Pausar el juego y mostrar opciones
	if UIManager and UIManager.has_method("show_level_up_screen"):
		UIManager.show_level_up_screen()

func player_death():
	"""Manejar muerte del jugador"""
	print("💀 GAME OVER")
	
	# Pausar el juego
	get_tree().paused = true
	
	# Mostrar pantalla de game over
	if UIManager and UIManager.has_method("show_game_over"):
		UIManager.show_game_over()

func update_health_ui():
	"""Actualizar UI de salud"""
	if UIManager and UIManager.has_method("update_health"):
		UIManager.update_health(current_health, max_health)

func update_experience_ui():
	"""Actualizar UI de experiencia"""
	if UIManager and UIManager.has_method("update_experience"):
		UIManager.update_experience(experience, level)

# Procesar efectos de estado cada frame
func _process(delta):
	process_status_effects(delta)

func process_status_effects(delta):
	"""Procesar efectos de estado activos"""
	var effects_to_remove = []
	
	for effect_name in status_effects.keys():
		var effect = status_effects[effect_name]
		effect.timer += delta
		
		# Aplicar efecto
		match effect_name:
			"poison":
				if fmod(effect.timer, 1.0) < delta:  # Cada segundo
					take_damage(effect.intensity)
			"slow":
				speed = 200.0 * 0.5  # Ralentizar 50%
			"burn":
				if fmod(effect.timer, 0.5) < delta:  # Cada 0.5 segundos
					take_damage(effect.intensity)
		
		# Remover efecto si expiró
		if effect.timer >= effect.duration:
			effects_to_remove.append(effect_name)
	
	# Limpiar efectos expirados
	for effect_name in effects_to_remove:
		status_effects.erase(effect_name)
		print("🔮 Efecto removido: ", effect_name)
		
		# Restaurar stats afectados
		if effect_name == "slow":
			speed = 200.0 * stats.move_speed
