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
var max_trail_length: int = 18  # Estela más larga para efecto más dramático

# Estado
var _lifetime_timer: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
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
	"""Crear visual ÉPICO mejorado del proyectil con estela"""
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	# Visual se dibuja en coordenadas globales relativas al parent
	visual_node.top_level = true
	visual_node.z_index = 55  # Más visible
	add_child(visual_node)
	
	visual_node.draw.connect(_draw_projectile)

func _draw_projectile() -> void:
	"""Dibujar proyectil ÉPICO con estela y efectos mejorados según elemento"""
	var color = _get_element_color()
	var bright_color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 1.0)
	var pos = global_position
	var pulse = 0.85 + sin(_time * 12) * 0.2
	
	# === ESTELA ÉPICA CON GRADIENTE MEJORADO ===
	if trail_positions.size() > 1:
		# Estela exterior brillante
		for i in range(trail_positions.size() - 1):
			var from_pos = trail_positions[i]
			var to_pos = trail_positions[i + 1]
			var t = float(i) / float(trail_positions.size())
			var trail_alpha = (1.0 - t) * 0.5
			var trail_width = (1.0 - t) * 14.0  # Más gruesa
			
			if trail_width > 1:
				var glow_color = Color(color.r, color.g, color.b, trail_alpha * 0.3)
				visual_node.draw_line(from_pos, to_pos, glow_color, trail_width * 1.5)
		
		# Estela principal
		for i in range(trail_positions.size() - 1):
			var from_pos = trail_positions[i]
			var to_pos = trail_positions[i + 1]
			var t = float(i) / float(trail_positions.size())
			var trail_alpha = (1.0 - t) * 0.85
			var trail_width = (1.0 - t) * 10.0
			
			if trail_width > 0.5:
				var trail_color = Color(color.r, color.g, color.b, trail_alpha * 0.7)
				visual_node.draw_line(from_pos, to_pos, trail_color, trail_width)
		
		# Estela interior brillante
		for i in range(trail_positions.size() - 1):
			var from_pos = trail_positions[i]
			var to_pos = trail_positions[i + 1]
			var t = float(i) / float(trail_positions.size())
			var trail_alpha = (1.0 - t) * 0.9
			var trail_width = (1.0 - t) * 5.0
			
			if trail_width > 0.3:
				var trail_bright = Color(bright_color.r, bright_color.g, bright_color.b, trail_alpha * 0.6)
				visual_node.draw_line(from_pos, to_pos, trail_bright, trail_width)
	
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
	"""Proyectil de fuego ÉPICO - llama con cola ardiente"""
	# Aura de calor grande
	visual_node.draw_circle(pos, 22 * pulse, Color(1.0, 0.2, 0.0, 0.12))
	visual_node.draw_circle(pos, 18 * pulse, Color(1.0, 0.35, 0.05, 0.2))
	visual_node.draw_circle(pos, 14 * pulse, Color(1.0, 0.5, 0.1, 0.3))
	
	# Llama principal (forma ovalada hacia atrás)
	var flame_offset = -direction * 8
	visual_node.draw_circle(pos + flame_offset * 1.5, 10 * pulse, Color(1.0, 0.3, 0.0, 0.5))
	visual_node.draw_circle(pos + flame_offset, 9 * pulse, Color(1.0, 0.45, 0.05, 0.7))
	visual_node.draw_circle(pos, 8 * pulse, Color(1.0, 0.6, 0.2, 0.85))
	
	# Núcleo caliente brillante
	visual_node.draw_circle(pos, 5 * pulse, Color(1.0, 0.85, 0.4, 1.0))
	visual_node.draw_circle(pos, 3 * pulse, Color(1.0, 0.95, 0.7, 1.0))
	visual_node.draw_circle(pos, 1.5 * pulse, Color(1.0, 1.0, 0.95, 1.0))
	
	# Chispas voladoras más dramáticas
	for i in range(6):
		var spark_angle = _time * 8 + i * 1.2
		var spark_dist = 10 + sin(_time * 12 + i) * 5
		var spark_offset = -direction * spark_dist + Vector2(sin(spark_angle) * 6, cos(spark_angle) * 6)
		var spark_size = 2.5 + sin(_time * 15 + i) * 1.0
		visual_node.draw_circle(pos + spark_offset, spark_size, Color(1.0, 0.8, 0.3, 0.8))

func _draw_ice_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de hielo ÉPICO - cristal brillante con destellos"""
	# Aura fría grande
	visual_node.draw_circle(pos, 20 * pulse, Color(0.3, 0.75, 1.0, 0.1))
	visual_node.draw_circle(pos, 16 * pulse, Color(0.4, 0.8, 1.0, 0.18))
	
	# Cristal hexagonal con capas
	var hex_size = 11 * pulse
	visual_node.draw_circle(pos, hex_size, Color(0.25, 0.65, 1.0, 0.65))
	visual_node.draw_circle(pos, hex_size * 0.75, Color(0.45, 0.8, 1.0, 0.8))
	visual_node.draw_circle(pos, hex_size * 0.5, Color(0.7, 0.92, 1.0, 0.9))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 4.5 * pulse, Color(0.85, 0.97, 1.0, 1.0))
	visual_node.draw_circle(pos, 2.5 * pulse, Color(1.0, 1.0, 1.0, 1.0))
	
	# Destellos de hielo orbitando
	for i in range(6):
		var angle = _time * 4 + (TAU / 6) * i
		var sparkle_dist = 10 * pulse + sin(_time * 6 + i) * 2
		var sparkle_pos = pos + Vector2(cos(angle), sin(angle)) * sparkle_dist
		visual_node.draw_circle(sparkle_pos, 2.5, Color(0.9, 0.98, 1.0, 0.85))
		visual_node.draw_circle(sparkle_pos, 1.5, Color(1.0, 1.0, 1.0, 0.95))
	
	# Cristales de hielo volando
	for i in range(3):
		var crystal_offset = -direction * (12 + i * 6) + Vector2(sin(_time * 5 + i * 2) * 4, cos(_time * 5 + i * 2) * 4)
		visual_node.draw_circle(pos + crystal_offset, 2, Color(0.8, 0.95, 1.0, 0.6))

func _draw_dark_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil oscuro ÉPICO - orbe con energía del vacío"""
	# Distorsión del vacío grande
	visual_node.draw_circle(pos, 24 * pulse, Color(0.15, 0.0, 0.25, 0.15))
	visual_node.draw_arc(pos, 20 * pulse, 0, TAU, 32, Color(0.4, 0.05, 0.5, 0.25), 3.0)
	visual_node.draw_arc(pos, 16 * pulse, _time * 3, _time * 3 + TAU * 0.6, 24, Color(0.5, 0.1, 0.6, 0.35), 2.5)
	
	# Cuerpo oscuro con gradiente
	visual_node.draw_circle(pos, 12 * pulse, Color(0.25, 0.0, 0.35, 0.75))
	visual_node.draw_circle(pos, 9 * pulse, Color(0.4, 0.05, 0.55, 0.85))
	visual_node.draw_circle(pos, 6 * pulse, Color(0.55, 0.15, 0.75, 0.92))
	
	# Núcleo con brillo púrpura intenso
	visual_node.draw_circle(pos, 4 * pulse, Color(0.75, 0.35, 1.0, 1.0))
	visual_node.draw_circle(pos, 2.5 * pulse, Color(0.9, 0.6, 1.0, 1.0))
	visual_node.draw_circle(pos, 1.2 * pulse, Color(1.0, 0.9, 1.0, 1.0))
	
	# Partículas de sombra orbitando más dramáticas
	for i in range(7):
		var angle = -_time * 5 + (TAU / 7) * i
		var orbit_r = 13 * pulse + sin(_time * 8 + i) * 3
		var shadow_pos = pos + Vector2(cos(angle), sin(angle)) * orbit_r
		visual_node.draw_circle(shadow_pos, 3, Color(0.5, 0.1, 0.6, 0.75))
		visual_node.draw_circle(shadow_pos, 1.8, Color(0.7, 0.3, 0.9, 0.9))

func _draw_arcane_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil arcano ÉPICO - esfera mágica con runas"""
	# Aura mágica grande
	visual_node.draw_circle(pos, 22 * pulse, Color(0.75, 0.15, 1.0, 0.12))
	visual_node.draw_circle(pos, 18 * pulse, Color(0.8, 0.25, 1.0, 0.2))
	
	# Anillos de runas dobles
	visual_node.draw_arc(pos, 14 * pulse, _time * 3, _time * 3 + TAU * 0.75, 20, Color(0.9, 0.5, 1.0, 0.55), 2.5)
	visual_node.draw_arc(pos, 11 * pulse, -_time * 2.5, -_time * 2.5 + TAU * 0.6, 16, Color(1.0, 0.7, 1.0, 0.45), 2.0)
	
	# Cuerpo mágico con gradiente
	visual_node.draw_circle(pos, 10 * pulse, Color(0.65, 0.15, 0.85, 0.7))
	visual_node.draw_circle(pos, 7 * pulse, Color(0.8, 0.35, 0.95, 0.85))
	visual_node.draw_circle(pos, 5 * pulse, Color(0.9, 0.5, 1.0, 0.92))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 3.5 * pulse, Color(1.0, 0.8, 1.0, 1.0))
	visual_node.draw_circle(pos, 2 * pulse, Color(1.0, 0.95, 1.0, 1.0))
	visual_node.draw_circle(pos, 1 * pulse, Color(1.0, 1.0, 1.0, 1.0))
	
	# Destellos mágicos orbitando
	for i in range(8):
		var angle = _time * 6 + (TAU / 8) * i
		var dist = 12 * pulse + sin(_time * 10 + i * 0.8) * 3
		var sparkle = pos + Vector2(cos(angle), sin(angle)) * dist
		var sparkle_size = 2.2 + sin(_time * 12 + i) * 0.8
		visual_node.draw_circle(sparkle, sparkle_size, Color(1.0, 0.75, 1.0, 0.7))

func _draw_poison_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de veneno ÉPICO - burbuja tóxica"""
	# Neblina tóxica grande
	visual_node.draw_circle(pos, 20 * pulse, Color(0.25, 0.75, 0.08, 0.12))
	visual_node.draw_circle(pos, 16 * pulse, Color(0.3, 0.8, 0.12, 0.2))
	
	# Burbuja principal con gradiente
	visual_node.draw_circle(pos, 11 * pulse, Color(0.18, 0.65, 0.08, 0.6))
	visual_node.draw_circle(pos, 8 * pulse, Color(0.35, 0.85, 0.18, 0.75))
	visual_node.draw_circle(pos, 6 * pulse, Color(0.5, 0.95, 0.3, 0.85))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 4 * pulse, Color(0.6, 1.0, 0.4, 1.0))
	visual_node.draw_circle(pos, 2.5 * pulse, Color(0.8, 1.0, 0.65, 1.0))
	visual_node.draw_circle(pos, 1.2 * pulse, Color(0.95, 1.0, 0.9, 1.0))
	
	# Gotitas de veneno cayendo + burbujas orbitando
	for i in range(5):
		var drop_offset = Vector2(sin(_time * 4 + i * 1.5) * 5, fmod(_time * 25 + i * 15, 18) - 3)
		visual_node.draw_circle(pos + drop_offset, 2.5, Color(0.35, 0.92, 0.22, 0.6))
	
	# Burbujas tóxicas orbitando
	for i in range(5):
		var angle = _time * 3.5 + (TAU / 5) * i
		var bubble_dist = 12 * pulse + sin(_time * 7 + i) * 2
		var bubble_pos = pos + Vector2(cos(angle), sin(angle)) * bubble_dist
		visual_node.draw_circle(bubble_pos, 2.8, Color(0.28, 0.85, 0.15, 0.7))
		visual_node.draw_circle(bubble_pos, 1.5, Color(0.5, 1.0, 0.35, 0.85))

func _draw_lightning_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de rayo ÉPICO - esfera eléctrica con arcos"""
	# Aura eléctrica grande pulsante
	visual_node.draw_circle(pos, 22 * pulse, Color(1.0, 1.0, 0.2, 0.1))
	visual_node.draw_circle(pos, 18 * pulse, Color(1.0, 1.0, 0.35, 0.18))
	visual_node.draw_circle(pos, 14 * pulse, Color(1.0, 1.0, 0.5, 0.25))
	
	# Cuerpo eléctrico con gradiente
	visual_node.draw_circle(pos, 10 * pulse, Color(0.9, 0.95, 0.3, 0.7))
	visual_node.draw_circle(pos, 7 * pulse, Color(1.0, 1.0, 0.55, 0.85))
	visual_node.draw_circle(pos, 5 * pulse, Color(1.0, 1.0, 0.75, 0.92))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 3.5 * pulse, Color(1.0, 1.0, 0.9, 1.0))
	visual_node.draw_circle(pos, 2 * pulse, Color(1.0, 1.0, 0.98, 1.0))
	visual_node.draw_circle(pos, 1 * pulse, Color(1.0, 1.0, 1.0, 1.0))
	
	# Rayitos saliendo dramáticos con bifurcaciones
	for i in range(6):
		var base_angle = _time * 10 + (TAU / 6) * i
		var angle_variation = sin(_time * 15 + i * 2) * 0.35
		var angle = base_angle + angle_variation
		var bolt_length = (14 + sin(_time * 20 + i) * 4) * pulse
		var bolt_mid = pos + Vector2(cos(angle), sin(angle)) * bolt_length * 0.6
		var bolt_end = pos + Vector2(cos(angle), sin(angle)) * bolt_length
		
		# Rayo principal
		visual_node.draw_line(pos, bolt_mid, Color(1.0, 1.0, 0.6, 0.85), 2.5)
		visual_node.draw_line(bolt_mid, bolt_end, Color(1.0, 1.0, 0.7, 0.7), 2.0)
		
		# Bifurcación
		var branch_angle = angle + (randf() - 0.5) * 1.0
		var branch_end = bolt_mid + Vector2(cos(branch_angle), sin(branch_angle)) * bolt_length * 0.35
		visual_node.draw_line(bolt_mid, branch_end, Color(1.0, 1.0, 0.8, 0.5), 1.5)
	
	# Arco eléctrico circular pulsante
	visual_node.draw_arc(pos, 11 * pulse, _time * 8, _time * 8 + TAU * 0.4, 12, Color(1.0, 1.0, 0.5, 0.55), 2.0)
	visual_node.draw_arc(pos, 8 * pulse, -_time * 6, -_time * 6 + TAU * 0.5, 10, Color(1.0, 1.0, 0.7, 0.45), 1.5)

func _draw_default_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil genérico ÉPICO mejorado"""
	# Brillo exterior grande
	visual_node.draw_circle(pos, 20 * pulse, Color(color.r, color.g, color.b, 0.12))
	visual_node.draw_circle(pos, 16 * pulse, Color(color.r, color.g, color.b, 0.2))
	
	# Anillo decorativo
	visual_node.draw_arc(pos, 13 * pulse, _time * 4, _time * 4 + TAU * 0.7, 16, Color(bright_color.r, bright_color.g, bright_color.b, 0.4), 2.0)
	
	# Cuerpo medio con gradiente
	visual_node.draw_circle(pos, 11 * pulse, Color(color.r, color.g, color.b, 0.55))
	visual_node.draw_circle(pos, 8 * pulse, Color(color.r * 1.1, color.g * 1.1, color.b * 1.1, 0.75))
	
	# Núcleo brillante
	visual_node.draw_circle(pos, 5.5 * pulse, bright_color)
	visual_node.draw_circle(pos, 3.5 * pulse, Color(min(bright_color.r + 0.2, 1), min(bright_color.g + 0.2, 1), min(bright_color.b + 0.2, 1), 1.0))
	
	# Centro blanco
	visual_node.draw_circle(pos, 2 * pulse, Color(1, 1, 1, 0.95))
	visual_node.draw_circle(pos, 1 * pulse, Color(1, 1, 1, 1.0))
	
	# Partículas decorativas orbitando
	for i in range(6):
		var angle = _time * 5.5 + (TAU / 6) * i
		var orbit_radius = 12 * pulse + sin(_time * 8 + i) * 2
		var particle_pos = pos + Vector2(cos(angle), sin(angle)) * orbit_radius
		visual_node.draw_circle(particle_pos, 2.5, Color(bright_color.r, bright_color.g, bright_color.b, 0.7))
		visual_node.draw_circle(particle_pos, 1.5, Color(1, 1, 1, 0.5))

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
	
	# Animar y destruir - duración más larga
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(effect):
			effect.queue_redraw()
	, 0.0, 1.0, 0.5)  # 0.35 -> 0.5 para ver mejor el efecto
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _draw_fire_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de fuego ÉPICO - explosión masiva con llamas"""
	var radius = 45 * progress  # Más grande
	
	# Múltiples ondas de calor
	effect.draw_arc(Vector2.ZERO, radius * 1.4, 0, TAU, 32, Color(1.0, 0.3, 0.0, alpha * 0.25), 4.0)
	effect.draw_arc(Vector2.ZERO, radius * 1.2, 0, TAU, 32, Color(1.0, 0.45, 0.0, alpha * 0.35), 3.5)
	effect.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.55, 0.1, alpha * 0.45), 3.0)
	
	# Explosión de fuego con gradiente
	effect.draw_circle(Vector2.ZERO, radius * 0.85, Color(1.0, 0.35, 0.0, alpha * 0.45))
	effect.draw_circle(Vector2.ZERO, radius * 0.65, Color(1.0, 0.5, 0.05, alpha * 0.6))
	effect.draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 0.7, 0.2, alpha * 0.75))
	effect.draw_circle(Vector2.ZERO, radius * 0.25, Color(1.0, 0.9, 0.5, alpha * 0.9))
	effect.draw_circle(Vector2.ZERO, radius * 0.1, Color(1.0, 1.0, 0.85, alpha))
	
	# Chispas voladoras más dramáticas
	for i in range(12):
		var angle = (TAU / 12) * i + progress * 2.5
		var spark_dist = radius * (0.4 + progress * 0.65)
		var spark_pos = Vector2(cos(angle), sin(angle)) * spark_dist
		var spark_size = 5.5 * (1.0 - progress)
		effect.draw_circle(spark_pos, spark_size, Color(1.0, 0.75, 0.25, alpha * 0.9))
		effect.draw_circle(spark_pos, spark_size * 0.5, Color(1.0, 0.95, 0.7, alpha))
	
	# Llamas saliendo hacia afuera
	for i in range(8):
		var flame_angle = (TAU / 8) * i
		var flame_length = radius * 0.7 * progress
		var flame_end = Vector2(cos(flame_angle), sin(flame_angle)) * flame_length
		effect.draw_line(Vector2.ZERO, flame_end, Color(1.0, 0.5, 0.1, alpha * 0.6), 4.0 * (1.0 - progress * 0.5))

func _draw_ice_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de hielo ÉPICO - cristales rompiéndose espectacularmente"""
	var radius = 40 * progress  # Más grande
	
	# Múltiples ondas de frío
	effect.draw_arc(Vector2.ZERO, radius * 1.3, 0, TAU, 32, Color(0.3, 0.7, 1.0, alpha * 0.3), 3.5)
	effect.draw_arc(Vector2.ZERO, radius * 1.1, 0, TAU, 32, Color(0.45, 0.8, 1.0, alpha * 0.4), 3.0)
	effect.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.55, 0.88, 1.0, alpha * 0.5), 2.5)
	
	# Centro helado con gradiente
	effect.draw_circle(Vector2.ZERO, radius * 0.7, Color(0.4, 0.85, 1.0, alpha * 0.5))
	effect.draw_circle(Vector2.ZERO, radius * 0.5, Color(0.6, 0.92, 1.0, alpha * 0.65))
	effect.draw_circle(Vector2.ZERO, radius * 0.3, Color(0.8, 0.97, 1.0, alpha * 0.8))
	effect.draw_circle(Vector2.ZERO, radius * 0.12, Color(1.0, 1.0, 1.0, alpha))
	
	# Fragmentos de hielo más dramáticos
	for i in range(10):
		var angle = (TAU / 10) * i + progress * 0.5
		var frag_dist = radius * (0.35 + progress * 0.7)
		var frag_pos = Vector2(cos(angle), sin(angle)) * frag_dist
		var frag_size = 7 * (1.0 - progress * 0.8)
		effect.draw_circle(frag_pos, frag_size, Color(0.65, 0.93, 1.0, alpha * 0.85))
		effect.draw_circle(frag_pos, frag_size * 0.55, Color(0.9, 1.0, 1.0, alpha * 0.95))
		effect.draw_circle(frag_pos, frag_size * 0.25, Color(1.0, 1.0, 1.0, alpha))
	
	# Cristales de hielo volando
	for i in range(6):
		var crystal_angle = (TAU / 6) * i + PI / 6
		var crystal_dist = radius * progress * 0.9
		var crystal_end = Vector2(cos(crystal_angle), sin(crystal_angle)) * crystal_dist
		effect.draw_line(Vector2.ZERO, crystal_end, Color(0.75, 0.95, 1.0, alpha * 0.5), 2.5 * (1.0 - progress * 0.5))

func _draw_dark_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto oscuro ÉPICO - vórtice colapsando dramáticamente"""
	var radius = 42 * progress  # Más grande
	
	# Anillos del vacío múltiples
	for i in range(5):
		var ring_r = radius * (1.0 - i * 0.17)
		var ring_alpha = alpha * (1.0 - i * 0.18)
		var ring_width = 3.0 - i * 0.4
		effect.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32, Color(0.55, 0.12, 0.75, ring_alpha), ring_width)
	
	# Espirales de energía oscura
	for i in range(3):
		var spiral_angle = progress * 6 + (TAU / 3) * i
		var spiral_r = radius * 0.7
		var spiral_end = Vector2(cos(spiral_angle), sin(spiral_angle)) * spiral_r
		effect.draw_line(Vector2.ZERO, spiral_end, Color(0.7, 0.25, 0.9, alpha * 0.6), 2.5)
	
	# Núcleo oscuro que colapsa con gradiente
	var collapse = 1.0 - progress
	effect.draw_circle(Vector2.ZERO, 18 * collapse, Color(0.15, 0.0, 0.22, alpha * 0.75))
	effect.draw_circle(Vector2.ZERO, 12 * collapse, Color(0.3, 0.05, 0.42, alpha * 0.85))
	effect.draw_circle(Vector2.ZERO, 7 * collapse, Color(0.55, 0.18, 0.75, alpha * 0.95))
	effect.draw_circle(Vector2.ZERO, 3 * collapse, Color(0.8, 0.45, 1.0, alpha))
	
	# Partículas de sombra dispersándose
	for i in range(12):
		var angle = (TAU / 12) * i - progress * 4
		var shadow_dist = radius * 0.75
		var shadow_pos = Vector2(cos(angle), sin(angle)) * shadow_dist
		var shadow_size = 5 * (1.0 - progress * 0.7)
		effect.draw_circle(shadow_pos, shadow_size, Color(0.45, 0.05, 0.55, alpha * 0.7))
		effect.draw_circle(shadow_pos, shadow_size * 0.5, Color(0.65, 0.25, 0.85, alpha * 0.85))

func _draw_arcane_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto arcano ÉPICO - runas brillando intensamente"""
	var radius = 40 * progress  # Más grande
	
	# Círculos mágicos concéntricos
	effect.draw_arc(Vector2.ZERO, radius * 1.2, 0, TAU, 32, Color(0.85, 0.35, 1.0, alpha * 0.35), 3.5)
	effect.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.9, 0.45, 1.0, alpha * 0.5), 3.0)
	effect.draw_arc(Vector2.ZERO, radius * 0.75, 0, TAU, 32, Color(0.93, 0.55, 1.0, alpha * 0.55), 2.5)
	effect.draw_arc(Vector2.ZERO, radius * 0.5, 0, TAU, 32, Color(0.95, 0.65, 1.0, alpha * 0.45), 2.0)
	
	# Destellos centrales con gradiente
	effect.draw_circle(Vector2.ZERO, radius * 0.45, Color(0.85, 0.55, 1.0, alpha * 0.5))
	effect.draw_circle(Vector2.ZERO, radius * 0.3, Color(0.92, 0.7, 1.0, alpha * 0.7))
	effect.draw_circle(Vector2.ZERO, radius * 0.15, Color(1.0, 0.88, 1.0, alpha * 0.9))
	effect.draw_circle(Vector2.ZERO, radius * 0.06, Color(1.0, 1.0, 1.0, alpha))
	
	# Runas/símbolos dispersándose más elaborados
	for i in range(10):
		var angle = (TAU / 10) * i + progress * 5
		var rune_dist = radius * 0.65
		var rune_pos = Vector2(cos(angle), sin(angle)) * rune_dist
		var rune_size = 4.5 * (1.0 - progress * 0.4)
		effect.draw_circle(rune_pos, rune_size, Color(0.95, 0.75, 1.0, alpha * 0.8))
		effect.draw_circle(rune_pos, rune_size * 0.5, Color(1.0, 0.92, 1.0, alpha))
	
	# Rayos mágicos hacia afuera
	for i in range(6):
		var ray_angle = (TAU / 6) * i + progress * 2
		var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * radius
		effect.draw_line(Vector2.ZERO, ray_end, Color(1.0, 0.8, 1.0, alpha * 0.5), 2.0 * (1.0 - progress * 0.5))

func _draw_poison_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de veneno ÉPICO - salpicadura tóxica masiva"""
	var radius = 38 * progress  # Más grande
	
	# Neblina tóxica expandiéndose
	effect.draw_circle(Vector2.ZERO, radius * 1.2, Color(0.25, 0.7, 0.08, alpha * 0.2))
	effect.draw_circle(Vector2.ZERO, radius, Color(0.28, 0.75, 0.1, alpha * 0.3))
	
	# Mancha principal con gradiente
	effect.draw_circle(Vector2.ZERO, radius * 0.75, Color(0.22, 0.72, 0.08, alpha * 0.45))
	effect.draw_circle(Vector2.ZERO, radius * 0.55, Color(0.35, 0.85, 0.15, alpha * 0.6))
	effect.draw_circle(Vector2.ZERO, radius * 0.35, Color(0.48, 0.93, 0.25, alpha * 0.75))
	effect.draw_circle(Vector2.ZERO, radius * 0.15, Color(0.65, 1.0, 0.4, alpha * 0.9))
	
	# Gotas salpicando más dramáticas
	for i in range(12):
		var angle = (TAU / 12) * i + sin(progress * 3 + i) * 0.2
		var drop_dist = radius * (0.3 + progress * 0.75)
		var drop_pos = Vector2(cos(angle), sin(angle)) * drop_dist
		var drop_size = (6.5 - (i % 4) * 0.8) * (1.0 - progress * 0.6)
		effect.draw_circle(drop_pos, max(drop_size, 1.5), Color(0.38, 0.92, 0.18, alpha * 0.8))
		effect.draw_circle(drop_pos, max(drop_size * 0.5, 0.8), Color(0.55, 1.0, 0.35, alpha * 0.9))
	
	# Burbujas tóxicas emergiendo
	for i in range(6):
		var bubble_pos = Vector2(sin(progress * 8 + i * 2) * radius * 0.4, cos(progress * 8 + i * 2) * radius * 0.4)
		var bubble_size = 4 * (0.5 + sin(progress * 10 + i) * 0.3)
		effect.draw_circle(bubble_pos, bubble_size, Color(0.35, 0.88, 0.2, alpha * 0.6))

func _draw_lightning_impact(effect: Node2D, progress: float, alpha: float) -> void:
	"""Impacto de rayo ÉPICO - descarga eléctrica masiva"""
	var radius = 38 * progress  # Más grande
	
	# Flash central masivo
	effect.draw_circle(Vector2.ZERO, radius * 0.7, Color(1.0, 1.0, 0.45, alpha * 0.45))
	effect.draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 1.0, 0.65, alpha * 0.6))
	effect.draw_circle(Vector2.ZERO, radius * 0.3, Color(1.0, 1.0, 0.82, alpha * 0.8))
	effect.draw_circle(Vector2.ZERO, radius * 0.12, Color(1.0, 1.0, 0.95, alpha))
	
	# Rayos saliendo más elaborados con bifurcaciones
	for i in range(10):
		var base_angle = (TAU / 10) * i
		var angle_var = sin(progress * 15 + i * 2) * 0.25
		var angle = base_angle + angle_var
		var bolt_end = Vector2(cos(angle), sin(angle)) * radius
		var bolt_mid = bolt_end * 0.55 + Vector2(sin(i + progress * 10) * 6, cos(i + progress * 10) * 6)
		
		# Rayo principal
		effect.draw_line(Vector2.ZERO, bolt_mid, Color(1.0, 1.0, 0.55, alpha * 0.9), 3.0)
		effect.draw_line(bolt_mid, bolt_end, Color(1.0, 1.0, 0.4, alpha * 0.7), 2.0)
		
		# Bifurcación
		var branch_angle = angle + (0.5 if i % 2 == 0 else -0.5)
		var branch_end = bolt_mid + Vector2(cos(branch_angle), sin(branch_angle)) * radius * 0.3
		effect.draw_line(bolt_mid, branch_end, Color(1.0, 1.0, 0.7, alpha * 0.5), 1.5)
	
	# Chispas voladoras
	for i in range(8):
		var spark_angle = (TAU / 8) * i + progress * 6
		var spark_dist = radius * (0.4 + progress * 0.4)
		var spark_pos = Vector2(cos(spark_angle), sin(spark_angle)) * spark_dist
		effect.draw_circle(spark_pos, 3.5 * (1.0 - progress * 0.7), Color(1.0, 1.0, 0.85, alpha * 0.75))
	
	# Arco eléctrico exterior
	effect.draw_arc(Vector2.ZERO, radius * 0.9, 0, TAU, 24, Color(1.0, 1.0, 0.5, alpha * 0.4), 2.5)

func _draw_default_impact(effect: Node2D, progress: float, alpha: float, color: Color, bright_color: Color) -> void:
	"""Impacto genérico ÉPICO mejorado"""
	var radius = 42 * progress  # Más grande
	
	# Anillos expansivos múltiples
	for i in range(4):
		var ring_radius = radius * (1.15 - i * 0.22)
		var ring_alpha = alpha * (1.0 - i * 0.2)
		var ring_width = 3.5 - i * 0.6
		if ring_radius > 0:
			effect.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 28, Color(color.r, color.g, color.b, ring_alpha * 0.65), ring_width)
	
	# Centro brillante con gradiente
	effect.draw_circle(Vector2.ZERO, radius * 0.55, Color(color.r, color.g, color.b, alpha * 0.4))
	effect.draw_circle(Vector2.ZERO, radius * 0.4, Color(bright_color.r, bright_color.g, bright_color.b, alpha * 0.6))
	effect.draw_circle(Vector2.ZERO, radius * 0.25, Color(min(bright_color.r + 0.2, 1), min(bright_color.g + 0.2, 1), min(bright_color.b + 0.2, 1), alpha * 0.8))
	effect.draw_circle(Vector2.ZERO, radius * 0.1, Color(1, 1, 1, alpha))
	
	# Partículas de explosión más elaboradas
	for i in range(12):
		var angle = (TAU / 12) * i + progress * 1.5
		var particle_dist = radius * (0.45 + progress * 0.35)
		var particle_pos = Vector2(cos(angle), sin(angle)) * particle_dist
		var particle_size = 5 * (1.0 - progress * 0.7)
		effect.draw_circle(particle_pos, particle_size, Color(bright_color.r, bright_color.g, bright_color.b, alpha * 0.8))
		effect.draw_circle(particle_pos, particle_size * 0.5, Color(1, 1, 1, alpha * 0.9))
	
	# Rayos hacia afuera
	for i in range(6):
		var ray_angle = (TAU / 6) * i
		var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * radius * 0.85
		effect.draw_line(Vector2.ZERO, ray_end, Color(bright_color.r, bright_color.g, bright_color.b, alpha * 0.45), 2.0 * (1.0 - progress * 0.6))
