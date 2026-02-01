# SimpleProjectile.gd
# Sistema de proyectiles con diferentes tipos de elemento
# ACTUALIZADO: Integra AnimatedProjectileSprite para visuales mejorados
# 
# Tipos soportados:
# - ice: Esquirla de hielo (rombo azul brillante)
# - fire: Bola de fuego (círculo naranja con estela)
# - arcane: Orbe arcano (esfera púrpura pulsante)
# - lightning: Rayo eléctrico (forma angular amarilla)
# - dark: Proyectil oscuro (esfera negra con aura)
# - nature: Hoja/espina verde

extends Area2D
class_name SimpleProjectile

signal hit_enemy(enemy: Node, damage: int)
signal destroyed

# === CONFIGURACIÓN ===
@export var damage: int = 10
@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var knockback_force: float = 150.0
@export var pierce_count: int = 0  # 0 = no atraviesa
@export var hit_vfx_scene: PackedScene # Escena opcional para efecto de impacto

# === TIPO DE ELEMENTO ===
@export var element_type: String = "ice"  # ice, fire, arcane, lightning, dark, nature

# === ESTADO ===
var start_pos: Vector2 = Vector2.ZERO # Recordar posición inicial para sharpshooter
var direction: Vector2 = Vector2.RIGHT
var current_lifetime: float = 0.0
var enemies_hit: Array[Node] = []
var pierces_remaining: int = 0

# === VISUAL ===
var sprite: Sprite2D = null
# FIXED: Removed explicit type hint to prevent cyclic dependency crash
var animated_sprite = null  # NUEVO: Visual animado
var projectile_color: Color = Color(0.4, 0.7, 1.0, 1.0)
var projectile_size: float = 12.0
var trail_particles: CPUParticles2D = null
var _weapon_id: String = ""  # Para buscar visual data

# === OPTIMIZATION CACHE ===
var _decor_manager: Node = null
var _audio_manager: Node = null
var _player_stats: Node = null
var _player: Node = null
var _physics_query: PhysicsShapeQueryParameters2D = null
var _physics_circle: CircleShape2D = null
var _cached_hit_sound: String = ""

# Static cache for expensive assets
static var _cached_heal_texture: Texture2D = null

# Colores por elemento
const ELEMENT_COLORS = {
	"ice": Color(0.4, 0.8, 1.0, 1.0),      # Azul hielo
	"fire": Color(1.0, 0.5, 0.1, 1.0),     # Naranja fuego
	"arcane": Color(0.7, 0.3, 1.0, 1.0),   # Púrpura arcano
	"lightning": Color(1.0, 1.0, 0.3, 1.0), # Amarillo eléctrico
	"dark": Color(0.3, 0.1, 0.4, 1.0),     # Púrpura oscuro
	"nature": Color(0.3, 0.8, 0.2, 1.0)    # Verde naturaleza
}

func _ready() -> void:
	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# INITIALIZE CACHE
	var tree = get_tree()
	if tree:
		_decor_manager = tree.get_first_node_in_group("decor_collision_manager")
		_audio_manager = tree.get_first_node_in_group("audio_manager")
		_player_stats = tree.get_first_node_in_group("player_stats")
		var players = tree.get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
			
	# Reuse physics objects
	_physics_query = PhysicsShapeQueryParameters2D.new()
	_physics_circle = CircleShape2D.new()
	_physics_query.shape = _physics_circle
	_physics_query.collision_mask = 2 | 4 # Default mask
	
	# Configuración básica
	z_index = 10
	pierces_remaining = pierce_count
	
	# DEBUG: Mostrar metadatos de efectos al crear
	var _effect = get_meta("effect", "none")
	var _effect_value = get_meta("effect_value", 0.0)
	var _effect_dur = get_meta("effect_duration", 0.0)
	var _wid = get_meta("weapon_id", "")
	if _effect != "none":
		# Debug desactivado: print("[SimpleProjectile] 🆕 Creado - weapon: %s, effect: %s (val=%.2f, dur=%.2f)" % [_wid, _effect, _effect_value, _effect_dur])
		pass
	
	# Obtener color: priorizar color del arma sobre color del elemento
	if has_meta("weapon_color"):
		projectile_color = get_meta("weapon_color")
	elif ELEMENT_COLORS.has(element_type):
		projectile_color = ELEMENT_COLORS[element_type]
	
	# Configurar colisiones
	_setup_collision()
	
	# Inicializar visuales (llamado aquí para primera vez, y externamente para pooling)
	initialize_visuals()
	
	# Conectar señales
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func initialize_visuals() -> void:
	"""Crear/Recrear los visuales del proyectil (Soporte para pooling)"""
	# Limpiar visuales anteriores si existen (seguridad extra)
	if is_instance_valid(animated_sprite):
		animated_sprite.queue_free()
		animated_sprite = null
	if is_instance_valid(sprite):
		sprite.queue_free()
		sprite = null
	
	# NUEVO: Intentar crear visual animado primero
	var used_animated = _try_create_animated_visual()
	
	if not used_animated:
		# Crear visual según tipo de elemento (fallback)
		_create_visual()
	
	# Siempre recrear trail (partículas)
	if is_instance_valid(trail_particles):
		trail_particles.queue_free()
	_create_trail()

func _try_create_animated_visual() -> bool:
	"""Intentar crear visual animado usando ProjectileVisualManager"""
	# Obtener weapon_id desde metadata
	_weapon_id = get_meta("weapon_id", "")
	if _weapon_id.is_empty():
		return false
	
	# AGREGAR A GRUPO PARA GESTIÓN DE ORBITALES (Seguridad para pooling)
	var group_name = "weapon_projectiles_" + _weapon_id
	if not is_in_group(group_name):
		add_to_group(group_name)
	
	# Buscar el ProjectileVisualManager
	var visual_manager = ProjectileVisualManager.instance
	if visual_manager == null:
		return false
	
	# Obtener weapon_data para el visual
	var weapon_data = WeaponDatabase.get_weapon_data(_weapon_id)
	if weapon_data.is_empty():
		return false
	
	# Crear el visual animado
	animated_sprite = visual_manager.create_projectile_visual(_weapon_id, weapon_data)
	if animated_sprite == null:
		return false
	
	add_child(animated_sprite)
	
	# Iniciar animación de vuelo
	animated_sprite.play_flight()
	
	# Aplicar rotación inmediatamente basada en la dirección actual
	animated_sprite.set_direction(direction)
	
	return true

func _physics_process(delta: float) -> void:
	# ═══════════════════════════════════════════════════════════════════════════════
	# OPTIMIZACIÓN: Collision LOD & Physics Throttling
	# ═══════════════════════════════════════════════════════════════════════════════
	var pool = ProjectilePool.instance
	if pool:
		var deg_level = pool.degradation_level
		
		# Nivel 2 (Hard Limit): Actualizar física solo en frames alternos
		# Reducir carga de CPU a la mitad para proyectiles masivos
		if deg_level >= 2:
			var frame = Engine.get_physics_frames()
			# Usar ID de instancia para distribuir carga (par/impar)
			if (get_instance_id() + frame) % 2 == 0:
				return 
				# NOTA: Al saltar frame, se mueve "menos" distancia visualmente si no compensamos,
				# pero para proyectiles masivos es preferible "slowdown" a "stutter".
				# Alternativa: mover double distance next frame, pero eso rompe colisiones.

		# Nivel 3 (Critical): Desactivar partículas si no son esenciales
		if deg_level >= 3:
			if trail_particles and trail_particles.emitting:
				trail_particles.emitting = false

	# ═══════════════════════════════════════════════════════════════════════════════
	# MOVIMIENTO
	# ═══════════════════════════════════════════════════════════════════════════════
	global_position += direction * speed * delta
	
	# Gestionar rotación visual continuada (si es necesario)
	if animated_sprite:
		animated_sprite.rotation = direction.angle()

	# ═══════════════════════════════════════════════════════════════════════════════
	# LIFETIME
	# ═══════════════════════════════════════════════════════════════════════════════
	current_lifetime += delta
	if current_lifetime >= lifetime:
		# Return to pool instead of queue_free
		_destroy()


# ═══════════════════════════════════════════════════════════════════════════════
# OPTIMIZACIÓN: Cache de texturas para evitar generación procedural por instancia
# ═══════════════════════════════════════════════════════════════════════════════
static var _texture_cache: Dictionary = {}

func _setup_collision() -> void:
	# Capa 4 = proyectiles del jugador
	collision_layer = 0
	set_collision_layer_value(4, true)
	
	# Máscara: Enemigos (2), Breakables (3), Barriers (4, 5, 8)
	collision_mask = 0
	set_collision_mask_value(2, true) # Enemies
	set_collision_mask_value(3, true) # Breakables / Special Enemies
	set_collision_mask_value(4, true) # Low Barriers / Props
	set_collision_mask_value(5, true) # Mid Barriers
	set_collision_mask_value(8, true) # High Barriers/Decorations
	
	# Crear collision shape si no existe
	var shape = get_node_or_null("CollisionShape2D")
	if not shape:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle = CircleShape2D.new()
		
		# AUMENTO DE HITBOX (Mejora de "Game Feel")
		# Multiplicador base: 25% más grande que el sprite visual por defecto
		var hitbox_mult = 1.25
		
		# Ajustes por tipo de elemento
		match element_type:
			"ice": hitbox_mult = 1.15
			"fire": hitbox_mult = 1.35
			"arcane": hitbox_mult = 1.3
			"nature": hitbox_mult = 1.2
			"dark": hitbox_mult = 1.25
			"lightning": hitbox_mult = 1.4
		
		# Calcular radio final
		circle.radius = (projectile_size * 0.5) * hitbox_mult
		shape.shape = circle
		add_child(shape)
		
		# Debug visual (solo visible si 'Visible Collision Shapes' está activo en Debug)
		shape.modulate = Color(1, 0, 0, 0.5)

func _create_visual() -> void:
	"""Crear visual según tipo de elemento (Optimizado con Cache)"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	# Generar clave única para el cache
	var size = int(projectile_size * 2.5)
	var cache_key = "%s_%d_%s" % [element_type, size, projectile_color.to_html()]
	
	var texture: Texture2D
	
	if _texture_cache.has(cache_key):
		# HIT CACHE: Usar textura existente
		texture = _texture_cache[cache_key]
	else:
		# MISS CACHE: Generar textura costosa UNA sola vez
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(size / 2.0, size / 2.0)
		
		match element_type:
			"ice":
				_draw_ice_shard(image, size, center)
			"fire":
				_draw_fireball(image, size, center)
			"arcane":
				_draw_arcane_orb(image, size, center)
			"lightning":
				_draw_lightning_bolt(image, size, center)
			"dark":
				_draw_dark_orb(image, size, center)
			"nature":
				_draw_leaf(image, size, center)
			_:
				_draw_default_orb(image, size, center)
		
		texture = ImageTexture.create_from_image(image)
		_texture_cache[cache_key] = texture
	
	sprite.texture = texture
	sprite.centered = true
	add_child(sprite)

func _draw_ice_shard(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar esquirla de hielo (forma de diamante/rombo)"""
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var px = x - half
			var py = y - half
			# Forma de rombo: |x| + |y| <= radio
			var diamond_dist = abs(px) * 0.8 + abs(py)
			if diamond_dist <= half * 0.85:
				var intensity = 1.0 - (diamond_dist / (half * 0.85)) * 0.4
				var color = Color(
					0.7 * intensity + 0.3,
					0.9 * intensity + 0.1,
					1.0,
					1.0 if diamond_dist < half * 0.6 else 0.85
				)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_fireball(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar bola de fuego (círculo con gradiente cálido)"""
	var radius = size / 2.0 - 2.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = dist / radius
				# Gradiente: centro amarillo -> naranja -> rojo exterior
				var color: Color
				if t < 0.3:
					color = Color(1.0, 1.0, 0.5, 1.0)  # Amarillo centro
				elif t < 0.6:
					color = Color(1.0, 0.6, 0.1, 1.0)  # Naranja
				else:
					color = Color(1.0, 0.3, 0.0, 0.9)  # Rojo exterior
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_arcane_orb(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar orbe arcano (esfera púrpura con brillo)"""
	var radius = size / 2.0 - 2.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = 1.0 - dist / radius
				var color = Color(
					0.6 + t * 0.4,
					0.2 + t * 0.3,
					1.0,
					0.8 + t * 0.2
				)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_lightning_bolt(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar rayo eléctrico (forma angular)"""
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var px = (x - half) / half
			var py = (y - half) / half
			# Forma de rayo zigzag
			var in_bolt = abs(px) < 0.4 and abs(py) < 0.9
			in_bolt = in_bolt or (abs(px - 0.2) < 0.3 and py > -0.3 and py < 0.3)
			if in_bolt:
				var intensity = 0.8 + randf() * 0.2
				image.set_pixel(x, y, Color(1.0, 1.0, 0.3 * intensity, 1.0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_dark_orb(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar orbe oscuro (núcleo oscuro con aura púrpura)"""
	var radius = size / 2.0 - 1.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = dist / radius
				if t < 0.5:
					# Núcleo oscuro
					image.set_pixel(x, y, Color(0.15, 0.05, 0.2, 1.0))
				else:
					pass  # Bloque else
					# Aura púrpura
					var alpha = 1.0 - (t - 0.5) * 1.5
					image.set_pixel(x, y, Color(0.5, 0.1, 0.6, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_leaf(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar hoja/espina de naturaleza"""
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var px = (x - half) / half
			var py = (y - half) / half
			# Forma de hoja: elipse con punta
			var leaf_shape = (px * px * 2.0 + py * py) < 0.7 and py < 0.8
			if leaf_shape:
				var intensity = 0.7 + abs(px) * 0.3
				image.set_pixel(x, y, Color(0.2, 0.7 * intensity, 0.1, 1.0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_default_orb(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar orbe por defecto"""
	var radius = size / 2.0 - 1.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var intensity = 1.0 - (dist / radius) * 0.5
				var color = Color(
					projectile_color.r * intensity + 0.3,
					projectile_color.g * intensity + 0.3,
					projectile_color.b * intensity,
					1.0 if dist < radius * 0.8 else 0.8
				)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

# OPTIMIZACIÓN: Límite global de sistemas de partículas activos
const MAX_ACTIVE_TRAILS: int = 30
static var _active_trail_count: int = 0
static var _active_hit_particle_count: int = 0 # Counter for active hit particles

func _create_trail() -> void:
	"""Crear partículas de estela según elemento (con límite global)"""
	# OPTIMIZACIÓN: No crear más trails si alcanzamos el límite
	if SimpleProjectile._active_trail_count >= MAX_ACTIVE_TRAILS:
		return
	
	SimpleProjectile._active_trail_count += 1

	
	trail_particles = CPUParticles2D.new()
	trail_particles.name = "Trail"
	trail_particles.emitting = true
	trail_particles.amount = 6  # Reducido de 8 a 6 para mejor rendimiento
	trail_particles.lifetime = 0.25  # Reducido de 0.3
	trail_particles.speed_scale = 1.5
	trail_particles.explosiveness = 0.0
	trail_particles.direction = Vector2(-1, 0)  # Hacia atrás
	trail_particles.spread = 15.0
	trail_particles.gravity = Vector2.ZERO
	trail_particles.initial_velocity_min = 20.0
	trail_particles.initial_velocity_max = 40.0
	trail_particles.scale_amount_min = 0.3
	trail_particles.scale_amount_max = 0.6
	trail_particles.color = projectile_color
	
	# Conectar para decrementar contador cuando se destruya
	trail_particles.tree_exited.connect(_on_trail_destroyed)
	
	add_child(trail_particles)

func _on_trail_destroyed() -> void:
	"""Callback cuando un trail se destruye"""
	SimpleProjectile._active_trail_count = maxi(0, SimpleProjectile._active_trail_count - 1)



func configure_and_launch(data: Dictionary, start_pos: Vector2, target_vec: Vector2, is_direction: bool = true) -> void:
	"""
	Método UNIFICADO para inicializar, configurar y lanzar un proyectil.
	Reemplaza la lógica fragmentada anterior para garantizar consistencia total (Zero-Ghosting Policy).
	"""
	# 1. Aplicar Stats Base (Sobrescribir siempre)
	damage = int(data.get("damage", 10))
	speed = data.get("speed", 400.0)
	var proj_range = data.get("range", 300.0)
	# Calcular lifetime exacto según velocidad (mínimo 1.0 para evitar div/0)
	lifetime = proj_range / maxf(speed, 1.0)
	knockback_force = data.get("knockback", 150.0)
	pierce_count = data.get("pierce", 0)
	pierces_remaining = pierce_count
	
	# 2. Configurar Elemento
	var element_int = data.get("element", 3)
	# Usar helper estático de ProjectileFactory directamente
	element_type = ProjectileFactory.get_element_string(element_int)
	
	# 3. Configurar Color (Prioridad: Arma > Elemento)
	if data.has("color"):
		projectile_color = data.get("color")
		set_meta("weapon_color", projectile_color)
	else:
		projectile_color = ELEMENT_COLORS.get(element_type, Color.WHITE)
	
	# 4. Configurar Efectos (Metadata)
	set_meta("effect", data.get("effect", "none"))
	set_meta("effect_value", data.get("effect_value", 0.0))
	set_meta("effect_duration", data.get("effect_duration", 0.0))
	set_meta("crit_chance", data.get("crit_chance", 0.0))
	set_meta("crit_damage", data.get("crit_damage", 2.0))
	set_meta("weapon_id", data.get("weapon_id", ""))
	
	# 5. Configurar Movimiento
	global_position = start_pos
	if is_direction:
		direction = target_vec
	else:
		direction = (target_vec - start_pos).normalized()
	
	# CACHE SOUND
	_cached_hit_sound = "" # Reset
	
	# Resetear estado de ejecución
	current_lifetime = 0.0
	enemies_hit.clear()
	
	# 6. Reconstruir Visuales (Ahora que tenemos todos los datos)
	initialize_visuals()
	
	# 7. Activar Lógica y Señales
	set_process(true)
	
	# Reconectar señales (Pooling cleanup fix)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# 8. Trigger Animación
	if animated_sprite and is_instance_valid(animated_sprite):
		animated_sprite.set_direction(direction)
		animated_sprite.play_flight()

func set_color(color: Color) -> void:
	"""Cambiar color del proyectil (Runtime override)"""
	projectile_color = color
	if sprite:
		sprite.modulate = color

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area2D) -> void:
	# DEBUG: Ver qué entra
	# print("Proj hit area: ", area.name, " Parent: ", area.get_parent().name)
	
	# Si el área tiene un parent que es enemigo
	if area.get_parent() and area.get_parent().is_in_group("enemies"):
		_handle_hit(area.get_parent())

func _handle_hit(target: Node) -> void:
	# Ignorar si ya golpeamos este enemigo
	if target in enemies_hit:
		return
	
	# Verificar que es un enemigo
	if not target.is_in_group("enemies"):
		return
	
	# Debug desactivado por spam: print("🎯 Proj Hit Target: ", target.name)
	enemies_hit.append(target)
	
	# Calcular daño final usando el sistema centralizado
	# Esto aplica: Crit, Sharpehooter, Brawler, Executioner, Elite Damage
	# Refresh cached player ref if needed
	if not is_instance_valid(_player):
		_player = _get_player()

	# Calcular daño final usando el sistema centralizado
	# NOTA: _player puede ser null en tests sintéticos, DamageCalculator debe manejarlo
	var damage_result = DamageCalculator.calculate_final_damage(
		damage, target, _player, 
		get_meta("crit_chance", 0.0), 
		get_meta("crit_damage", 2.0)
	)
	var final_damage = damage_result.final_damage # Keep float for further multipliers

	# -----------------------------------------------------------
	# LÓGICA DE NUEVOS OBJETOS (Phase 3 Extra Effects)
	# -----------------------------------------------------------
	# Use cached Player Stats (re-fetch if invalid)
	if not is_instance_valid(_player_stats):
		if get_tree():
			_player_stats = get_tree().get_first_node_in_group("player_stats")
			
	if _player_stats and _player_stats.has_method("get_stat"):
		# 4. Combustión Instantánea (Combustion - Rework): Burn aplica daño instantáneo
		var combustion_active = _player_stats.get_stat("combustion_active")
		if combustion_active > 0:
			# Si aplicamos quemadura, aplicamos su daño total instantáneamente
			var burn_chance = get_meta("burn_chance", 0.0)
			# Simplificación: +50% daño extra como "explosión" si el proyectil tiene elemento fuego
			if get_meta("element", "") == "fire" or burn_chance > 0:
				var burn_dmg = final_damage * 0.5
				if target.has_method("take_damage"):
					target.take_damage(int(burn_dmg))
				FloatingText.spawn_custom(target.global_position + Vector2(10, -40), "COMB!", Color.ORANGE_RED)

		# 5. Ruleta Rusa (Russian Roulette): 1% chance de 10x daño
		var russian_roulette = _player_stats.get_stat("russian_roulette")
		if russian_roulette > 0:
			if randf() < 0.01: # 1%
				final_damage *= 10.0
				FloatingText.spawn_custom(target.global_position + Vector2(0, -60), "JACKPOT!", Color.GOLD)
				_play_roulette_sound()

		# 9. Hemorragia (Hemorrhage): Chance de aplicar Sangrado
		var bleed_chance = _player_stats.get_stat("bleed_on_hit_chance")
		if bleed_chance > 0 and randf() < bleed_chance:
			if target.has_method("apply_bleed"):
				# Daño de sangrado base o proporcional
				var bleed_dmg = max(1, damage * 0.2) # 20% del daño BASE
				target.apply_bleed(bleed_dmg, 3.0)
				FloatingText.spawn_custom(target.global_position + Vector2(-10, -30), "BLEED", Color.RED)
	# -----------------------------------------------------------
	
	# Conditional Multiplier (Status Effects) -> NOW HANDLED IN DamageCalculator
	# var conditional_mult = ProjectileFactory.get_conditional_damage_multiplier(get_tree(), target)
	# if conditional_mult > 1.0:
	#	final_damage *= conditional_mult
	# 

	# Aplicar daño
	if target.has_method("take_damage"):
		target.take_damage(int(final_damage))
		
		# LOG: Registrar daño aplicado
		var weapon_id = get_meta("weapon_id", "unknown_projectile")
		DamageLogger.log_weapon_damage(weapon_id, target.name, int(final_damage), {"crit": damage_result.is_crit, "effect": get_meta("effect", "none")})
		
		# Aplicar life steal
		ProjectileFactory.apply_life_steal(get_tree(), final_damage)
		# Verificar execute threshold después del daño
		ProjectileFactory.check_execute(get_tree(), target)
		# Aplicar efectos de estado por probabilidad
		ProjectileFactory.apply_status_effects_chance(get_tree(), target)
	elif target.has_node("HealthComponent"):
		var hc = target.get_node("HealthComponent")
		if hc.has_method("take_damage"):
			hc.take_damage(int(final_damage), "physical")
			# Aplicar life steal
			ProjectileFactory.apply_life_steal(get_tree(), final_damage)
			# Verificar execute threshold después del daño
			ProjectileFactory.check_execute(get_tree(), target)
			# Aplicar efectos de estado por probabilidad
			ProjectileFactory.apply_status_effects_chance(get_tree(), target)
	
	# Calcular knockback real (con bonus si aplica)
	var final_knockback = knockback_force
	var effect = get_meta("effect", "none")
	var effect_value = get_meta("effect_value", 0.0)
	if effect == "knockback_bonus":
		final_knockback *= effect_value  # effect_value es el multiplicador
	
	# Aplicar knockback
	if final_knockback > 0 and target.has_method("apply_knockback"):
		target.apply_knockback(direction * final_knockback)
	elif final_knockback > 0 and target is CharacterBody2D:
		target.velocity += direction * final_knockback
	
	# Aplicar efectos especiales
	_apply_effect(target)
	
	# Emitir señal
	hit_enemy.emit(target, final_damage)
	
	# Efecto de impacto
	_spawn_hit_effect()
	
	# Verificar pierce
	if pierces_remaining > 0:
		pierces_remaining -= 1
	else:
		_destroy()

func _apply_effect(target: Node) -> void:
	"""Aplicar efecto especial del proyectil al objetivo"""
	var effect = get_meta("effect", "none")
	var effect_value = get_meta("effect_value", 0.0)
	var effect_duration = get_meta("effect_duration", 0.0)
	
	if effect == "none":
		return
	
	match effect:
		"slow":
			if target.has_method("apply_slow"):
				target.apply_slow(effect_value, effect_duration)
		"burn":
			if target.has_method("apply_burn"):
				target.apply_burn(effect_value, effect_duration)
		"freeze":
			if target.has_method("apply_freeze"):
				target.apply_freeze(effect_value, effect_duration)
			elif target.has_method("apply_slow"):
				target.apply_slow(effect_value, effect_duration)
		"stun":
			if target.has_method("apply_stun"):
				target.apply_stun(effect_duration)
		"pull":
			# Pull hacia el punto de impacto del proyectil (no hacia el jugador)
			if target.has_method("apply_pull"):
				target.apply_pull(global_position, effect_value, effect_duration)
		"blind":
			if target.has_method("apply_blind"):
				target.apply_blind(effect_duration)
		"steam":
			# Combinación de slow + burn
			if target.has_method("apply_slow"):
				target.apply_slow(0.3, effect_duration)
			if target.has_method("apply_burn"):
				target.apply_burn(effect_value, effect_duration)
		"freeze_chain":
			if target.has_method("apply_freeze"):
				target.apply_freeze(effect_value, effect_duration)
			elif target.has_method("apply_slow"):
				target.apply_slow(effect_value, effect_duration)
		"burn_chain":
			if target.has_method("apply_burn"):
				target.apply_burn(effect_value, effect_duration)
		"lifesteal":
			var player = _get_player()
			if player and player.has_method("heal"):
				var heal_amount = roundi(effect_value)
				player.heal(heal_amount)
				_spawn_lifesteal_effect(player)
				# También mostrar número flotante verde directamente
				FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
		"lifesteal_chain":
			# Primero el lifesteal
			var player = _get_player()
			if player and player.has_method("heal"):
				var heal_amount = roundi(effect_value)
				player.heal(heal_amount)
				_spawn_lifesteal_effect(player)
				FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
			# Luego la cadena de daño (3 saltos por defecto)
			_apply_chain_damage(target, 3)
		"execute":
			if target.has_method("get_info"):
				var info = target.get_info()
				var hp = info.get("hp", 100)
				var max_hp = info.get("max_hp", 100)
				var hp_percent = float(hp) / float(max_hp)
				if hp_percent <= effect_value:
					if target.has_method("take_damage"):
						target.take_damage(hp)  # Matar instantáneamente
		"knockback_bonus", "crit_chance":
			pass  # Ya manejados en otro lugar
		"chain":
			# Crear salto de daño a enemigos cercanos
			_apply_chain_damage(target, roundi(effect_value))
		"bleed":
			if target.has_method("apply_bleed"):
				target.apply_bleed(effect_value, effect_duration)
		"shadow_mark":
			if target.has_method("apply_shadow_mark"):
				target.apply_shadow_mark(effect_value, effect_duration)

func _play_roulette_sound() -> void:
	"""Reproducir sonido de jackpot para Russian Roulette"""
	# Placeholder: Si existe AudioManager usarlo, sino solo log/visual
	# print("💰 JACKPOT SOUND!")
	if ClassDB.class_exists("AudioManager"):
		# AudioManager.play_sfx("jackpot") 
		pass

func _apply_chain_damage(first_target: Node, chain_count: int) -> void:
	"""Aplicar daño encadenado a enemigos cercanos"""
	var enemies_hit = [first_target]
	var current_pos = first_target.global_position
	var chain_damage = damage * 0.6  # Daño reducido para chains
	
	for i in range(chain_count):
		var next_target = _find_chain_target(current_pos, enemies_hit)
		if next_target == null:
			break
		
		# Aplicar daño al siguiente objetivo
		if next_target.has_method("take_damage"):
			next_target.take_damage(int(chain_damage))
			# Aplicar life steal y execute para chains
			ProjectileFactory.apply_life_steal(get_tree(), chain_damage)
			ProjectileFactory.check_execute(get_tree(), next_target)
			# Aplicar efectos de estado por probabilidad
			ProjectileFactory.apply_status_effects_chance(get_tree(), next_target)
		
		# Crear efecto visual de rayo entre objetivos
		_spawn_chain_lightning_visual(current_pos, next_target.global_position)
		
		# Actualizar para siguiente salto
		current_pos = next_target.global_position
		enemies_hit.append(next_target)

func _find_chain_target(pos: Vector2, exclude_list: Array) -> Node:
	"""Buscar un objetivo cercano para Chain, excluyendo los ya golpeados"""
	var range_radius = 200.0
	var best_target = null
	var best_dist = range_radius * range_radius
	
	# Usar grupo "enemies"
	var candidates = get_tree().get_nodes_in_group("enemies")
	for enemy in candidates:
		if enemy in exclude_list or not is_instance_valid(enemy):
			continue
			
		var d = pos.distance_squared_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best_target = enemy
			
	return best_target

func _spawn_chain_lightning_visual(from: Vector2, to: Vector2) -> void:
	"""Crear efecto visual de rayo (simple Line2D temporal)"""
	# Usar FXManager si existe, o crear nodo temporal
	var visual_manager = ProjectileVisualManager.instance
	if visual_manager and visual_manager.has_method("spawn_chain_lightning"):
		visual_manager.spawn_chain_lightning(from, to)
	else:
		# Fallback: crear Line2D y destruirlo
		var line = Line2D.new()
		line.points = [from, to]
		line.width = 3.0
		line.default_color = Color(0.5, 0.8, 1.0, 0.8)
		get_tree().root.add_child(line)
		
		var tween = create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.3)
		tween.tween_callback(line.queue_free)

func _spawn_hit_effect() -> void:
	"""Crear efecto visual de impacto"""
	if hit_vfx_scene:
		var vfx = hit_vfx_scene.instantiate()
		vfx.global_position = global_position
		get_tree().root.add_child(vfx)
	else:
		# Fallback: partículas genéricas si existen
		pass

func _spawn_lifesteal_effect(player: Node) -> void:
	"""Efecto visual de robo de vida en el jugador"""
	pass # Implementación visual simple o delegar a FXManager

func _destroy() -> void:
	"""Destruir proyectil (o devolver al pool)"""
	hit_enemy.emit(self, 0) # Emitir con 0 daño para indicar fin sin golpe? No necesario.
	destroyed.emit()
	
	# Limpiar
	if is_instance_valid(animated_sprite):
		animated_sprite.queue_free()
	if is_instance_valid(sprite):
		sprite.queue_free()
	
	# Usar pooling si disponible?
	queue_free()

func _get_player() -> Node:
	if is_instance_valid(_player):
		return _player
	if get_tree():
		var p = get_tree().get_first_node_in_group("player")
		if p:
			_player = p
			return p
	return null
