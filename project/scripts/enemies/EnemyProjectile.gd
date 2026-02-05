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
	
	# Crear visual (Sprite)
	_setup_sprite_visual()
	
	# Conectar señal de colisión
	body_entered.connect(_on_body_entered)
	
	# Rotar hacia dirección de movimiento
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func _setup_sprite_visual() -> void:
	"""Configurar Sprite2D usando spritesheets por elemento"""
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	# Mapeo de elementos a spritesheets individuales
	var PROJECTILE_SHEETS = {
		"fire": {
			"path": "res://assets/vfx/abilities/projectiles/fire/projectile_fire_spritesheet.png",
			"hframes": 4, "vframes": 2
		},
		"ice": {
			"path": "res://assets/vfx/abilities/projectiles/ice/projectile_ice_spritesheet.png",
			"hframes": 4, "vframes": 2
		},
		"arcane": {
			"path": "res://assets/vfx/abilities/projectiles/arcane/projectile_arcane_spritesheet.png",
			"hframes": 4, "vframes": 2
		},
		"void": {
			"path": "res://assets/vfx/abilities/projectiles/void/projectile_void_spritesheet.png",
			"hframes": 4, "vframes": 2
		},
		"poison": {
			"path": "res://assets/vfx/abilities/projectiles/poison/projectile_poison_spritesheet.png",
			"hframes": 4, "vframes": 2
		}
	}
	
	# Mapear elemento a tipo de spritesheet
	var sheet_type = element_type
	match element_type:
		"dark", "shadow": sheet_type = "void"
		"nature": sheet_type = "poison"
		"lightning": sheet_type = "arcane"
		"physical": sheet_type = "arcane"
	
	var config = PROJECTILE_SHEETS.get(sheet_type, PROJECTILE_SHEETS["arcane"])
	var tex = load(config["path"])
	
	if tex:
		sprite.texture = tex
		sprite.hframes = config["hframes"]
		sprite.vframes = config["vframes"]
		sprite.centered = true
		
		# Escala para ser visible (64x64 frames)
		sprite.scale = Vector2(1.0, 1.0)
		
		# Iniciar animación de frames
		_start_projectile_animation(sprite, config["hframes"] * config["vframes"])
	else:
		# Fallback: crear visual procedural
		push_warning("[EnemyProjectile] Textura no encontrada: %s" % config["path"])
		_setup_fallback_visual(sprite)
	
	visual_node = sprite
	add_child(visual_node)

func _start_projectile_animation(sprite: Sprite2D, total_frames: int) -> void:
	"""Animar el sprite del proyectil en loop"""
	var tween = create_tween()
	tween.set_loops()  # Loop infinito
	tween.tween_property(sprite, "frame", total_frames - 1, 0.4).from(0)

func _setup_fallback_visual(sprite: Sprite2D) -> void:
	"""Fallback visual si no hay spritesheet"""
	# Crear textura placeholder
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.3, 1.0, 0.9))
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.scale = Vector2(1.5, 1.5)


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
	
	# Verificar colisión con decorados
	var decor_manager = get_tree().get_first_node_in_group("decor_collision_manager")
	if decor_manager and decor_manager.has_method("check_collision_fast"):
		var push = decor_manager.check_collision_fast(global_position, 8.0)
		if push.length_squared() > 1.0:
			# Proyectil enemigo impactó decorado - destruir
			queue_free()
			return
	
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
		# print("[EnemyProjectile] 🎯 Impacto en player: %d daño (%s)" % [damage, element_type])
	
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
				# print("[EnemyProjectile] 🔥 Aplica Burn!")
		"ice":
			if target.has_method("apply_slow"):
				target.apply_slow(0.3, 2.5)  # 30% slow por 2.5s
				# print("[EnemyProjectile] ❄️ Aplica Slow!")
		"dark", "void":
			if target.has_method("apply_weakness"):
				target.apply_weakness(0.2, 3.0)  # +20% daño recibido por 3s
				# print("[EnemyProjectile] 💀 Aplica Weakness!")
		"arcane":
			# Arcane tiene chance de aplicar curse
			if randf() < 0.3 and target.has_method("apply_curse"):
				target.apply_curse(0.25, 4.0)  # 30% chance, -25% curación por 4s
				# print("[EnemyProjectile] ✨ Aplica Curse!")
		"poison":
			if target.has_method("apply_poison"):
				target.apply_poison(2.0, 4.0)  # 2 daño/tick por 4s
				# print("[EnemyProjectile] ☠️ Aplica Poison!")

# Procedural drawing removed in favor of Sprites

func _draw_fire_projectile(pos: Vector2, pulse: float, color: Color, bright_color: Color) -> void:
	"""Proyectil de fuego ÉPICO"""
	# Halo de calor intenso
	visual_node.draw_circle(pos, 28 * pulse, Color(1.0, 0.2, 0.0, 0.15))
	visual_node.draw_circle(pos, 22 * pulse, Color(1.0, 0.4, 0.0, 0.3))
	
	# Núcleo de fuego multicapa
	visual_node.draw_circle(pos, 14 * pulse, Color(1.0, 0.1, 0.0, 0.8)) # Rojo base
	visual_node.draw_circle(pos, 10 * pulse, Color(1.0, 0.6, 0.0, 0.9)) # Naranja medio
	visual_node.draw_circle(pos, 6 * pulse, Color(1.0, 1.0, 0.0, 1.0))  # Amarillo centro
	visual_node.draw_circle(pos, 3 * pulse, Color(1.0, 1.0, 1.0, 1.0))  # Blanco puro
	
	# Partículas de brasas (aleatorias en cada frame para simular caos)
	for i in range(5):
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		visual_node.draw_circle(pos + offset, 2.0, Color(1, 0.8, 0, 0.8))

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
	"""Crear efecto visual de impacto usando spritesheets AOE existentes"""
	var effect = Node2D.new()
	effect.global_position = global_position
	effect.top_level = true
	effect.z_index = 60
	
	var parent = get_parent()
	if parent:
		parent.add_child(effect)
	else:
		effect.queue_free()
		return
	
	# Mapear elemento a spritesheet AOE apropiado para el impacto
	var impact_sheets = {
		"fire": "res://assets/vfx/abilities/aoe/fire/aoe_fire_stomp_spritesheet.png",
		"ice": "res://assets/vfx/abilities/aoe/ice/aoe_freeze_zone_spritesheet.png",
		"arcane": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png",
		"void": "res://assets/vfx/abilities/aoe/void/aoe_void_explosion_spritesheet.png",
		"poison": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png",
		"lightning": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png"
	}
	
	var sheet_path = impact_sheets.get(element_type, "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png")
	
	var sprite = Sprite2D.new()
	var tex = load(sheet_path)
	
	if tex:
		sprite.texture = tex
		sprite.hframes = 4  # Todos los AOE sheets son 4x2
		sprite.vframes = 2
		sprite.frame = 0
		sprite.scale = Vector2(0.5, 0.5)  # Más pequeño para impacto de proyectil
		sprite.modulate = _get_element_color()
		
		effect.add_child(sprite)
		
		# Animar frames
		var total_frames = 8
		var tween = effect.create_tween()
		tween.tween_method(func(f: int):
			sprite.frame = f
		, 0, total_frames - 1, 0.25)
		
		tween.tween_callback(func():
			if is_instance_valid(effect):
				effect.queue_free()
		)
		
		# SAFETY TIMEOUT: Eliminar efecto después de 1 segundo si el tween falla
		var tree = effect.get_tree()
		if tree:
			tree.create_timer(1.0).timeout.connect(func():
				if is_instance_valid(effect):
					effect.queue_free()
			, CONNECT_ONE_SHOT)
	else:
		# Fallback: dibujo procedural simple
		var fallback = Node2D.new()
		effect.add_child(fallback)
		var color = _get_element_color()
		var progress = 0.0
		
		fallback.draw.connect(func():
			var r = 15.0 * (1.0 + progress)
			fallback.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.5 * (1.0 - progress)))
		)
		
		var tween = effect.create_tween()
		tween.tween_method(func(p: float):
			progress = p
			if is_instance_valid(fallback):
				fallback.queue_redraw()
		, 0.0, 1.0, 0.2)
		tween.tween_callback(func():
			if is_instance_valid(effect):
				effect.queue_free()
		)
		
		# SAFETY TIMEOUT: Eliminar efecto después de 1 segundo si el tween falla
		var tree2 = effect.get_tree()
		if tree2:
			tree2.create_timer(1.0).timeout.connect(func():
				if is_instance_valid(effect):
					effect.queue_free()
			, CONNECT_ONE_SHOT)

# Sprite impact logic handles visuals now.

# _draw_lightning_impact and _draw_default_impact removed.
