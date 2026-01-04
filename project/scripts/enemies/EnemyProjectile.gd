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
	
	# CRÍTICO: Habilitar monitoring para detectar colisiones
	monitoring = true
	monitorable = true
	
	# Crear CollisionShape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0  # Aumentar hitbox para mejor detección
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

func _physics_process(delta: float) -> void:
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
	
	# CHECK MANUAL de colisión con player (más fiable que body_entered)
	_check_player_collision_distance()
	
	# Lifetime
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		queue_free()

func _check_player_collision_distance() -> void:
	"""Verificar colisión por distancia al player (más fiable)"""
	var players = get_tree().get_nodes_in_group("player")
	for player_node in players:
		if not is_instance_valid(player_node):
			continue
		var dist = global_position.distance_to(player_node.global_position)
		if dist < 20.0:  # Radio de colisión
			_hit_player(player_node)
			return

func _hit_player(player_body: Node2D) -> void:
	"""Impactar al player y destruir proyectil"""
	if player_body.has_method("take_damage"):
		# Intentar pasar el elemento, si falla usar la versión simple
		player_body.call("take_damage", damage, element_type)
		print("[EnemyProjectile] 🎯 Impacto en player: %d daño (%s)" % [damage, element_type])
	
	# Aplicar efectos según elemento
	_apply_element_effect(player_body)
	
	hit_player.emit(damage)
	
	# Efecto de impacto
	_spawn_hit_effect()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	"""Colisión con algo (backup - también tenemos check manual)"""
	# Verificar si es el player
	if body.is_in_group("player"):
		_hit_player(body)

func _apply_element_effect(target: Node) -> void:
	"""Aplicar efecto de estado según el elemento del proyectil"""
	match element_type:
		"fire":
			if target.has_method("apply_burn"):
				target.apply_burn(3.0, 2.5)  # 3 daño/tick por 2.5s
				print("[EnemyProjectile] 🔥 Aplica Burn!")
		"ice":
			if target.has_method("apply_slow"):
				target.apply_slow(0.3, 2.5)  # 30% slow por 2.5s
				print("[EnemyProjectile] ❄️ Aplica Slow!")
		"dark", "void":
			if target.has_method("apply_weakness"):
				target.apply_weakness(0.2, 3.0)  # +20% daño recibido por 3s
				print("[EnemyProjectile] 💀 Aplica Weakness!")
		"arcane":
			# Arcane tiene chance de aplicar curse
			if randf() < 0.3 and target.has_method("apply_curse"):
				target.apply_curse(0.25, 4.0)  # 30% chance, -25% curación por 4s
				print("[EnemyProjectile] ✨ Aplica Curse!")
		"poison":
			if target.has_method("apply_poison"):
				target.apply_poison(2.0, 4.0)  # 2 daño/tick por 4s
				print("[EnemyProjectile] ☠️ Aplica Poison!")

func _create_enhanced_visual() -> void:
	"""Crear visual mejorado del proyectil con estela"""
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	# Visual se dibuja en coordenadas globales relativas al parent
	visual_node.top_level = true
	add_child(visual_node)
	
	visual_node.draw.connect(_draw_projectile)

func _draw_projectile() -> void:
	"""Dibujar proyectil con estela y efectos mejorados según elemento"""
	var color = _get_element_color()
	var bright_color = Color(color.r + 0.4, color.g + 0.4, color.b + 0.4, 1.0).clamp()
	var pos = global_position
	var pulse = 0.85 + sin(_time * 10) * 0.15
	
	# === ESTELA MEJORADA CON GRADIENTE ===
	if trail_positions.size() > 1:
		for i in range(trail_positions.size() - 1):
			var from_pos = trail_positions[i]
			var to_pos = trail_positions[i + 1]
			var t = float(i) / float(trail_positions.size())
			var trail_alpha = (1.0 - t) * 0.7
			var trail_width = (1.0 - t) * 8.0
			
			if trail_width > 0.5:
				# Estela con brillo interior
				var trail_color = Color(color.r, color.g, color.b, trail_alpha * 0.6)
				var trail_bright = Color(bright_color.r, bright_color.g, bright_color.b, trail_alpha * 0.4)
				visual_node.draw_line(from_pos, to_pos, trail_color, trail_width)
				visual_node.draw_line(from_pos, to_pos, trail_bright, trail_width * 0.4)
	
	# === VISUAL ESPECÍFICO POR ELEMENTO ===
	match element_type:
		"fire":
			_draw_fire_projectile(pos, pulse, color, bright_color)
		"ice":
			_draw_ice_projectile(pos, pulse, color, bright_color)
		"dark", "shadow", "void":
			_draw_dark_projectile(pos, pulse, color, bright_color)
		"arcane":
			_draw_arcane_projectile(pos, pulse, color, bright_color)
		"poison":
			_draw_poison_projectile(pos, pulse, color, bright_color)
		"lightning":
			_draw_lightning_projectile(pos, pulse, color, bright_color)
		_:
			_draw_default_projectile(pos, pulse, color, bright_color)

func _draw_fire_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de fuego - llama con cola ardiente"""
	# Aura de calor
	visual_node.draw_circle(pos, 16 * pulse, Color(1.0, 0.3, 0.0, 0.15))
	visual_node.draw_circle(pos, 12 * pulse, Color(1.0, 0.5, 0.1, 0.25))
	
	# Llama principal (forma ovalada hacia atrás)
	var flame_offset = -direction * 6
	visual_node.draw_circle(pos + flame_offset, 8 * pulse, Color(1.0, 0.4, 0.0, 0.6))
	visual_node.draw_circle(pos, 7 * pulse, Color(1.0, 0.6, 0.2, 0.8))
	
	# Núcleo caliente
	visual_node.draw_circle(pos, 4 * pulse, Color(1.0, 0.9, 0.5, 1.0))
	visual_node.draw_circle(pos, 2 * pulse, Color(1.0, 1.0, 0.9, 1.0))
	
	# Chispas
	for i in range(3):
		var spark_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8)) * pulse
		var spark_size = randf_range(1.5, 3.0)
		visual_node.draw_circle(pos + spark_offset - direction * 12, spark_size, Color(1.0, 0.8, 0.3, 0.7))

func _draw_ice_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de hielo - cristal brillante con destellos"""
	# Aura fría
	visual_node.draw_circle(pos, 14 * pulse, Color(0.4, 0.8, 1.0, 0.15))
	
	# Cristal hexagonal (simulado con círculos)
	var hex_size = 9 * pulse
	visual_node.draw_circle(pos, hex_size, Color(0.3, 0.7, 1.0, 0.7))
	visual_node.draw_circle(pos, hex_size * 0.7, Color(0.5, 0.85, 1.0, 0.85))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 4 * pulse, Color(0.8, 0.95, 1.0, 1.0))
	visual_node.draw_circle(pos, 2 * pulse, Color(1.0, 1.0, 1.0, 1.0))
	
	# Destellos de hielo
	for i in range(4):
		var angle = _time * 3 + (TAU / 4) * i
		var sparkle_dist = 8 * pulse
		var sparkle_pos = pos + Vector2(cos(angle), sin(angle)) * sparkle_dist
		visual_node.draw_circle(sparkle_pos, 1.5, Color(1.0, 1.0, 1.0, 0.8))

func _draw_dark_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil oscuro - orbe con energía del vacío"""
	# Distorsión del vacío (anillos oscuros)
	visual_node.draw_circle(pos, 18 * pulse, Color(0.2, 0.0, 0.3, 0.2))
	visual_node.draw_arc(pos, 14 * pulse, 0, TAU, 24, Color(0.5, 0.1, 0.6, 0.3), 2.0)
	
	# Cuerpo oscuro
	visual_node.draw_circle(pos, 10 * pulse, Color(0.3, 0.0, 0.4, 0.8))
	visual_node.draw_circle(pos, 7 * pulse, Color(0.5, 0.1, 0.7, 0.9))
	
	# Núcleo con brillo púrpura
	visual_node.draw_circle(pos, 4 * pulse, Color(0.7, 0.3, 1.0, 1.0))
	visual_node.draw_circle(pos, 2 * pulse, Color(0.9, 0.7, 1.0, 1.0))
	
	# Partículas de sombra orbitando
	for i in range(5):
		var angle = -_time * 4 + (TAU / 5) * i
		var orbit_r = 11 * pulse + sin(_time * 6 + i) * 2
		var shadow_pos = pos + Vector2(cos(angle), sin(angle)) * orbit_r
		visual_node.draw_circle(shadow_pos, 2.5, Color(0.4, 0.0, 0.5, 0.7))

func _draw_arcane_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil arcano - esfera mágica con runas"""
	# Aura mágica
	visual_node.draw_circle(pos, 16 * pulse, Color(0.8, 0.2, 1.0, 0.15))
	
	# Anillo de runas (simulado)
	visual_node.draw_arc(pos, 12 * pulse, _time * 2, _time * 2 + TAU * 0.7, 16, Color(0.9, 0.5, 1.0, 0.5), 2.0)
	
	# Cuerpo mágico
	visual_node.draw_circle(pos, 9 * pulse, Color(0.7, 0.2, 0.9, 0.7))
	visual_node.draw_circle(pos, 6 * pulse, Color(0.85, 0.4, 1.0, 0.9))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 3.5 * pulse, Color(1.0, 0.8, 1.0, 1.0))
	visual_node.draw_circle(pos, 1.5 * pulse, Color(1.0, 1.0, 1.0, 1.0))
	
	# Destellos mágicos
	for i in range(6):
		var angle = _time * 5 + (TAU / 6) * i
		var dist = 10 * pulse
		var sparkle = pos + Vector2(cos(angle), sin(angle)) * dist
		var sparkle_size = 1.5 + sin(_time * 8 + i) * 0.5
		visual_node.draw_circle(sparkle, sparkle_size, Color(1.0, 0.7, 1.0, 0.6))

func _draw_poison_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de veneno - burbuja tóxica"""
	# Neblina tóxica
	visual_node.draw_circle(pos, 15 * pulse, Color(0.3, 0.8, 0.1, 0.15))
	
	# Burbuja principal
	visual_node.draw_circle(pos, 10 * pulse, Color(0.2, 0.7, 0.1, 0.6))
	visual_node.draw_circle(pos, 7 * pulse, Color(0.4, 0.9, 0.2, 0.8))
	
	# Núcleo
	visual_node.draw_circle(pos, 4 * pulse, Color(0.6, 1.0, 0.4, 1.0))
	visual_node.draw_circle(pos, 2 * pulse, Color(0.9, 1.0, 0.7, 1.0))
	
	# Gotitas de veneno cayendo
	for i in range(3):
		var drop_offset = Vector2(randf_range(-6, 6), fmod(_time * 30 + i * 20, 15))
		visual_node.draw_circle(pos + drop_offset, 2.0, Color(0.3, 0.9, 0.2, 0.5))

func _draw_lightning_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de rayo - esfera eléctrica"""
	# Aura eléctrica
	visual_node.draw_circle(pos, 14 * pulse, Color(1.0, 1.0, 0.3, 0.2))
	
	# Cuerpo eléctrico
	visual_node.draw_circle(pos, 9 * pulse, Color(1.0, 1.0, 0.4, 0.7))
	visual_node.draw_circle(pos, 6 * pulse, Color(1.0, 1.0, 0.7, 0.9))
	
	# Núcleo
	visual_node.draw_circle(pos, 3 * pulse, Color(1.0, 1.0, 0.9, 1.0))
	visual_node.draw_circle(pos, 1.5 * pulse, Color(1.0, 1.0, 1.0, 1.0))
	
	# Rayitos saliendo
	for i in range(4):
		var angle = _time * 8 + (TAU / 4) * i + randf_range(-0.3, 0.3)
		var bolt_length = 12 * pulse
		var bolt_end = pos + Vector2(cos(angle), sin(angle)) * bolt_length
		visual_node.draw_line(pos, bolt_end, Color(1.0, 1.0, 0.5, 0.7), 1.5)

func _draw_default_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil genérico mejorado"""
	# Brillo exterior
	visual_node.draw_circle(pos, 14 * pulse, Color(color.r, color.g, color.b, 0.2))
	
	# Cuerpo medio
	visual_node.draw_circle(pos, 9 * pulse, Color(color.r, color.g, color.b, 0.6))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 5 * pulse, bright_color)
	
	# Centro blanco
	visual_node.draw_circle(pos, 2.5 * pulse, Color(1, 1, 1, 0.9))
	
	# Partículas decorativas
	for i in range(4):
		var angle = _time * 5 + (TAU / 4) * i
		var orbit_radius = 10 * pulse
		var particle_pos = pos + Vector2(cos(angle), sin(angle)) * orbit_radius
		visual_node.draw_circle(particle_pos, 2, Color(bright_color.r, bright_color.g, bright_color.b, 0.6))

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
	"""Crear efecto visual de impacto espectacular según elemento"""
	var color = _get_element_color()
	var bright_color = Color(color.r + 0.4, color.g + 0.4, color.b + 0.4, 1.0).clamp()
	var elem = element_type
	
	# Crear efecto de explosión
	var effect = Node2D.new()
	effect.global_position = global_position
	effect.top_level = true
	
	var parent = get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var impact_time = 0.0
	
	effect.draw.connect(func():
		var alpha = (1.0 - anim_progress) * 0.9
		
		match elem:
			"fire":
				_draw_fire_impact(effect, anim_progress, alpha)
			"ice":
				_draw_ice_impact(effect, anim_progress, alpha)
			"dark", "shadow", "void":
				_draw_dark_impact(effect, anim_progress, alpha)
			"arcane":
				_draw_arcane_impact(effect, anim_progress, alpha)
			"poison":
				_draw_poison_impact(effect, anim_progress, alpha)
			"lightning":
				_draw_lightning_impact(effect, anim_progress, alpha)
			_:
				_draw_default_impact(effect, anim_progress, alpha, color, bright_color)
	)
	
	# Animar y destruir
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(effect):
			effect.queue_redraw()
	, 0.0, 1.0, 0.35)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _draw_fire_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de fuego - explosión con llamas"""
	var radius = 30 * progress
	
	# Onda de calor
	effect.draw_arc(Vector2.ZERO, radius * 1.2, 0, TAU, 24, Color(1.0, 0.5, 0.0, alpha * 0.4), 3.0)
	
	# Explosión de fuego
	effect.draw_circle(Vector2.ZERO, radius * 0.8, Color(1.0, 0.4, 0.0, alpha * 0.5))
	effect.draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 0.7, 0.2, alpha * 0.7))
	effect.draw_circle(Vector2.ZERO, radius * 0.2, Color(1.0, 1.0, 0.7, alpha))
	
	# Chispas volando
	for i in range(8):
		var angle = (TAU / 8) * i + progress * 2
		var spark_dist = radius * (0.5 + progress * 0.5)
		var spark_pos = Vector2(cos(angle), sin(angle)) * spark_dist
		var spark_size = 4 * (1.0 - progress)
		effect.draw_circle(spark_pos, spark_size, Color(1.0, 0.8, 0.3, alpha))

func _draw_ice_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de hielo - cristales rompiéndose"""
	var radius = 25 * progress
	
	# Onda de frío
	effect.draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(0.4, 0.8, 1.0, alpha * 0.5), 2.5)
	
	# Centro helado
	effect.draw_circle(Vector2.ZERO, radius * 0.6, Color(0.5, 0.9, 1.0, alpha * 0.6))
	effect.draw_circle(Vector2.ZERO, radius * 0.3, Color(0.8, 1.0, 1.0, alpha * 0.8))
	
	# Fragmentos de hielo
	for i in range(6):
		var angle = (TAU / 6) * i
		var frag_dist = radius * (0.4 + progress * 0.6)
		var frag_pos = Vector2(cos(angle), sin(angle)) * frag_dist
		# Fragmento triangular simulado
		effect.draw_circle(frag_pos, 5 * (1.0 - progress), Color(0.7, 0.95, 1.0, alpha))
		effect.draw_circle(frag_pos, 3 * (1.0 - progress), Color(1.0, 1.0, 1.0, alpha))

func _draw_dark_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto oscuro - vórtice colapsando"""
	var radius = 28 * progress
	
	# Anillos del vacío
	for i in range(3):
		var ring_r = radius * (1.0 - i * 0.25)
		var ring_alpha = alpha * (1.0 - i * 0.3)
		effect.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(0.5, 0.1, 0.7, ring_alpha), 2.0)
	
	# Núcleo oscuro que colapsa
	var collapse = 1.0 - progress
	effect.draw_circle(Vector2.ZERO, 12 * collapse, Color(0.2, 0.0, 0.3, alpha * 0.8))
	effect.draw_circle(Vector2.ZERO, 6 * collapse, Color(0.6, 0.2, 0.8, alpha))
	
	# Partículas de sombra dispersándose
	for i in range(8):
		var angle = (TAU / 8) * i - progress * 3
		var shadow_dist = radius * 0.8
		var shadow_pos = Vector2(cos(angle), sin(angle)) * shadow_dist
		effect.draw_circle(shadow_pos, 4 * (1.0 - progress), Color(0.4, 0.0, 0.5, alpha * 0.7))

func _draw_arcane_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto arcano - runas brillando"""
	var radius = 26 * progress
	
	# Círculo mágico
	effect.draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(0.9, 0.4, 1.0, alpha * 0.6), 2.5)
	effect.draw_arc(Vector2.ZERO, radius * 0.7, 0, TAU, 24, Color(0.8, 0.3, 1.0, alpha * 0.4), 1.5)
	
	# Destellos centrales
	effect.draw_circle(Vector2.ZERO, radius * 0.4, Color(0.9, 0.6, 1.0, alpha * 0.5))
	effect.draw_circle(Vector2.ZERO, radius * 0.15, Color(1.0, 0.9, 1.0, alpha))
	
	# Runas/símbolos dispersándose
	for i in range(6):
		var angle = (TAU / 6) * i + progress * 4
		var rune_dist = radius * 0.6
		var rune_pos = Vector2(cos(angle), sin(angle)) * rune_dist
		effect.draw_circle(rune_pos, 3 * (1.0 - progress * 0.5), Color(1.0, 0.8, 1.0, alpha * 0.8))

func _draw_poison_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de veneno - salpicadura tóxica"""
	var radius = 24 * progress
	
	# Mancha principal
	effect.draw_circle(Vector2.ZERO, radius * 0.7, Color(0.3, 0.8, 0.1, alpha * 0.4))
	effect.draw_circle(Vector2.ZERO, radius * 0.4, Color(0.4, 0.9, 0.2, alpha * 0.6))
	
	# Gotas salpicando
	for i in range(7):
		var angle = (TAU / 7) * i + randf_range(-0.2, 0.2)
		var drop_dist = radius * (0.3 + progress * 0.7)
		var drop_pos = Vector2(cos(angle), sin(angle)) * drop_dist
		var drop_size = (5 - i * 0.5) * (1.0 - progress * 0.7)
		effect.draw_circle(drop_pos, max(drop_size, 1), Color(0.4, 0.95, 0.2, alpha * 0.8))

func _draw_lightning_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de rayo - descarga eléctrica"""
	var radius = 22 * progress
	
	# Flash central
	effect.draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 1.0, 0.6, alpha * 0.6))
	effect.draw_circle(Vector2.ZERO, radius * 0.2, Color(1.0, 1.0, 1.0, alpha))
	
	# Rayos saliendo
	for i in range(6):
		var angle = (TAU / 6) * i + randf_range(-0.3, 0.3)
		var bolt_end = Vector2(cos(angle), sin(angle)) * radius
		var bolt_mid = bolt_end * 0.5 + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		effect.draw_line(Vector2.ZERO, bolt_mid, Color(1.0, 1.0, 0.5, alpha), 2.5)
		effect.draw_line(bolt_mid, bolt_end, Color(1.0, 1.0, 0.3, alpha * 0.7), 1.5)
	
	# Chispas
	for i in range(4):
		var spark_pos = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		effect.draw_circle(spark_pos, 2 * (1.0 - progress), Color(1.0, 1.0, 0.8, alpha * 0.6))

func _draw_default_impact(effect: Node2D, progress: float, alpha: float, color: Color, bright_color: Color) -> void:
	"""Impacto genérico mejorado"""
	var radius = 25 * progress
	
	# Anillos expansivos
	for i in range(3):
		var ring_radius = radius * (1.0 - i * 0.2)
		var ring_alpha = alpha * (1.0 - i * 0.25)
		if ring_radius > 0:
			effect.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 20, Color(color.r, color.g, color.b, ring_alpha), 3.0 - i)
	
	# Centro brillante
	effect.draw_circle(Vector2.ZERO, radius * 0.3, Color(bright_color.r, bright_color.g, bright_color.b, alpha * 0.6))
	
	# Partículas de explosión
	for i in range(8):
		var angle = (TAU / 8) * i
		var particle_dist = radius * 0.7
		var particle_pos = Vector2(cos(angle), sin(angle)) * particle_dist
		var particle_size = 4 * (1.0 - progress)
		effect.draw_circle(particle_pos, particle_size, Color(1, 1, 1, alpha * 0.8))
