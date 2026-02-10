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
var _trail_line: Line2D = null
var trail_positions: Array = []
var max_trail_length: int = 18  # Estela más larga para efecto más dramático

# Estado
var _lifetime_timer: float = 0.0
var _time: float = 0.0

# Cache de referencias
var _cached_decor_manager: Node = null

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
	
	# NOTA: El visual (sprite + trail) se crea en initialize() para que use
	# el element_type correcto. _ready() se ejecuta al hacer add_child() ANTES
	# de que initialize() asigne el elemento, lo que causaba que todos los
	# proyectiles usaran el visual de "physical" (mapeado a arcane/púrpura).
	
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
		},
		"lightning": {
			"path": "res://assets/vfx/abilities/projectiles/lightning/projectile_lightning_spritesheet.png",
			"hframes": 4, "vframes": 2
		}
	}
	
	# Mapear elemento a tipo de spritesheet
	var sheet_type = element_type
	match element_type:
		"dark", "shadow": sheet_type = "void"
		"nature": sheet_type = "poison"
		"physical": sheet_type = "arcane"
	
	var config = PROJECTILE_SHEETS.get(sheet_type, PROJECTILE_SHEETS["arcane"])
	var tex = load(config["path"])
	
	if tex:
		sprite.texture = tex
		sprite.hframes = config["hframes"]
		sprite.vframes = config["vframes"]
		sprite.centered = true
		
		# FIX: Los frames reales son ~153x204, escalar para tamaño apropiado (~48x64)
		# Esto corrige el tamaño visual de los proyectiles de enemigos
		sprite.scale = Vector2(0.3, 0.3)
		
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

func _setup_trail() -> void:
	"""Crear Line2D para renderizar la estela del proyectil"""
	_trail_line = Line2D.new()
	_trail_line.top_level = true  # Coordenadas globales
	_trail_line.z_index = -1
	_trail_line.width = 6.0
	_trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Gradient de color: según elemento, de opaco a transparente
	var color = _get_element_color()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.8))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	_trail_line.gradient = grad
	
	# Ancho decreciente
	var width_curve = Curve.new()
	width_curve.add_point(Vector2(0.0, 1.0))
	width_curve.add_point(Vector2(1.0, 0.1))
	_trail_line.width_curve = width_curve
	
	add_child(_trail_line)


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
	
	# Crear visual con el elemento correcto (movido de _ready)
	# Eliminar visual anterior si existe (reuso de proyectiles)
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
		visual_node = null
	if _trail_line and is_instance_valid(_trail_line):
		_trail_line.queue_free()
		_trail_line = null
	
	_setup_sprite_visual()
	_setup_trail()
	
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
	
	# Verificar colisión con decorados (referencia cacheada)
	if not is_instance_valid(_cached_decor_manager):
		_cached_decor_manager = get_tree().get_first_node_in_group("decor_collision_manager")
	if _cached_decor_manager and _cached_decor_manager.has_method("check_collision_fast"):
		var push = _cached_decor_manager.check_collision_fast(global_position, 8.0)
		if push.length_squared() > 1.0:
			queue_free()
			return
	
	# Actualizar trail visual (convertir posiciones globales a locales del Line2D)
	if _trail_line and trail_positions.size() > 1:
		_trail_line.clear_points()
		for pos in trail_positions:
			_trail_line.add_point(pos)
	
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
		"poison", "nature":
			if target.has_method("apply_poison"):
				target.apply_poison(2.0, 4.0)  # 2 daño/tick por 4s
				# print("[EnemyProjectile] ☠️ Aplica Poison!")
		"lightning":
			# Lightning tiene chance de aplicar stun breve
			if randf() < 0.2 and target.has_method("apply_stun"):
				target.apply_stun(0.8)  # 20% chance, 0.8s stun
				# print("[EnemyProjectile] ⚡ Aplica Stun!")

# ══════════════════════════════════════════════════════════════════════════════
# VISUAL UTILITIES
# ══════════════════════════════════════════════════════════════════════════════

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
		"poison", "nature":
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
	effect.z_index = 5
	
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
		"dark": "res://assets/vfx/abilities/aoe/void/aoe_void_explosion_spritesheet.png",
		"shadow": "res://assets/vfx/abilities/aoe/void/aoe_void_explosion_spritesheet.png",
		"poison": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png",
		"nature": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png",
		"lightning": "res://assets/vfx/abilities/aoe/rune/aoe_rune_blast_spritesheet.png",
		"physical": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png"
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