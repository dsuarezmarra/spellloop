# EnemyProjectile.gd
# Proyectil genérico disparado por enemigos hacia el player
# Soporta diferentes tipos visuales y efectos con estela animada

extends Area2D
class_name EnemyProjectile

signal hit_player(damage: int)

# Configuración
var direction: Vector2 = Vector2.ZERO
var speed: float = 200.0
var damage: int = 10
var lifetime: float = 5.0
var element_type: String = "physical"  # physical, fire, ice, dark, arcane

# Visual
var visual_node: Node2D = null
var trail_positions: Array = []
var max_trail_length: int = 12

# Estado
var _lifetime_timer: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	# Configurar colisión: layer 4 (EnemyProjectile), mask 1 (Player)
	collision_layer = 0
	set_collision_layer_value(4, true)
	collision_mask = 0
	set_collision_mask_value(1, true)
	
	# Crear CollisionShape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	
	# Crear visual mejorado
	_create_enhanced_visual()
	
	# Conectar señal de colisión
	body_entered.connect(_on_body_entered)
	
	# Rotar hacia dirección de movimiento
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func initialize(p_direction: Vector2, p_speed: float, p_damage: int, p_lifetime: float = 5.0, p_element: String = "physical") -> void:
	"""Inicializar el proyectil con parámetros"""
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	lifetime = p_lifetime
	element_type = p_element
	_lifetime_timer = lifetime
	
	# Limpiar trail al reinicializar
	trail_positions.clear()
	
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func _process(delta: float) -> void:
	_time += delta
	
	# Guardar posición actual para trail
	if trail_positions.size() == 0 or global_position.distance_to(trail_positions[0]) > 5:
		trail_positions.insert(0, global_position)
		if trail_positions.size() > max_trail_length:
			trail_positions.pop_back()
	
	# Mover
	global_position += direction * speed * delta
	
	# Actualizar visual
	if visual_node:
		visual_node.queue_redraw()
	
	# Lifetime
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	"""Colisión con algo"""
	# Verificar si es el player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("[EnemyProjectile] 🎯 Impacto en player: %d daño (%s)" % [damage, element_type])
		hit_player.emit(damage)
		
		# Efecto de impacto
		_spawn_hit_effect()
		queue_free()

func _create_enhanced_visual() -> void:
	"""Crear visual mejorado del proyectil con estela"""
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	# Visual se dibuja en coordenadas globales relativas al parent
	visual_node.top_level = true
	add_child(visual_node)
	
	visual_node.draw.connect(_draw_projectile)

func _draw_projectile() -> void:
	"""Dibujar proyectil con estela y efectos"""
	var color = _get_element_color()
	var bright_color = Color(color.r + 0.4, color.g + 0.4, color.b + 0.4, 1.0).clamp()
	
	# Dibujar estela
	if trail_positions.size() > 1:
		for i in range(trail_positions.size() - 1):
			var from_pos = trail_positions[i]
			var to_pos = trail_positions[i + 1]
			var t = float(i) / float(trail_positions.size())
			var trail_alpha = (1.0 - t) * 0.6
			var trail_width = (1.0 - t) * 6.0
			
			if trail_width > 0.5:
				var trail_color = Color(color.r, color.g, color.b, trail_alpha)
				visual_node.draw_line(from_pos, to_pos, trail_color, trail_width)
	
	# Dibujar núcleo del proyectil
	var pos = global_position
	var pulse = 0.9 + sin(_time * 12) * 0.1
	
	# Brillo exterior
	visual_node.draw_circle(pos, 12 * pulse, Color(color.r, color.g, color.b, 0.2))
	
	# Cuerpo medio
	visual_node.draw_circle(pos, 8 * pulse, Color(color.r, color.g, color.b, 0.5))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 5 * pulse, bright_color)
	
	# Centro blanco
	visual_node.draw_circle(pos, 2 * pulse, Color(1, 1, 1, 0.9))
	
	# Partículas decorativas alrededor
	var particle_count = 4
	for i in range(particle_count):
		var angle = _time * 5 + (TAU / particle_count) * i
		var orbit_radius = 10 + sin(_time * 8 + i) * 3
		var particle_pos = pos + Vector2(cos(angle), sin(angle)) * orbit_radius
		var particle_size = 2 + sin(_time * 10 + i * 2) * 0.5
		visual_node.draw_circle(particle_pos, particle_size, Color(bright_color.r, bright_color.g, bright_color.b, 0.6))

func _get_element_color() -> Color:
	"""Obtener color según elemento - más vibrantes"""
	match element_type:
		"fire":
			return Color(1.0, 0.35, 0.1)
		"ice":
			return Color(0.2, 0.75, 1.0)
		"dark", "shadow", "void":
			return Color(0.6, 0.15, 0.9)
		"arcane":
			return Color(0.9, 0.3, 1.0)
		"poison":
			return Color(0.25, 0.9, 0.2)
		"lightning":
			return Color(1.0, 1.0, 0.25)
		_:
			return Color(0.85, 0.85, 0.9)

func _spawn_hit_effect() -> void:
	"""Crear efecto visual de impacto"""
	var color = _get_element_color()
	
	# Crear efecto de explosión
	var effect = Node2D.new()
	effect.global_position = global_position
	effect.top_level = true
	
	var parent = get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	
	effect.draw.connect(func():
		var radius = 20 * anim_progress
		var alpha = (1.0 - anim_progress) * 0.8
		
		# Anillos expansivos
		for i in range(3):
			var ring_radius = radius * (1.0 - i * 0.2)
			var ring_alpha = alpha * (1.0 - i * 0.25)
			if ring_radius > 0:
				effect.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 16, Color(color.r, color.g, color.b, ring_alpha), 3.0 - i)
		
		# Partículas de explosión
		var particle_count = 6
		for i in range(particle_count):
			var angle = (TAU / particle_count) * i
			var particle_dist = radius * 0.8
			var particle_pos = Vector2(cos(angle), sin(angle)) * particle_dist
			var particle_size = 3 * (1.0 - anim_progress)
			effect.draw_circle(particle_pos, particle_size, Color(1, 1, 1, alpha))
	)
	
	# Animar y destruir
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(effect):
			effect.queue_redraw()
	, 0.0, 1.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)
