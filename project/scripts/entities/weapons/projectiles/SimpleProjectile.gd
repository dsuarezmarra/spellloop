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
var animated_sprite: AnimatedProjectileSprite = null  # NUEVO: Visual animado
var projectile_color: Color = Color(0.4, 0.7, 1.0, 1.0)
var projectile_size: float = 12.0
var trail_particles: CPUParticles2D = null
var _weapon_id: String = ""  # Para buscar visual data

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


func _process(delta: float) -> void:
	# Actualizar lifetime
	current_lifetime += delta
	if current_lifetime >= lifetime:
		_destroy()
		return
	
	# Mover en línea recta (SIN rotación)
	global_position += direction * speed * delta
	
	# Verificar colisión con decorados
	var decor_manager = get_tree().get_first_node_in_group("decor_collision_manager")
	if decor_manager and decor_manager.has_method("check_collision_fast"):
		var push = decor_manager.check_collision_fast(global_position, 8.0)
		if push.length_squared() > 1.0:
			# Proyectil impactó con decorado - destruir
			_destroy()
			return
	
	# Actualizar dirección del sprite animado
	if animated_sprite and is_instance_valid(animated_sprite):
		animated_sprite.set_direction(direction)

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
	
	# Calcular daño final (con crítico si aplica)
	var final_damage = damage
	var crit_chance = get_meta("crit_chance", 0.0)
	var crit_damage_mult = get_meta("crit_damage", 2.0)  # Obtener multiplicador de crítico
	if randf() < crit_chance:
		final_damage *= crit_damage_mult  # Usar multiplicador variable
	
	# Aplicar multiplicador de daño condicional (damage_vs_slowed/burning/frozen)
	var conditional_mult = ProjectileFactory.get_conditional_damage_multiplier(get_tree(), target)
	if conditional_mult > 1.0:
		final_damage = int(float(final_damage) * conditional_mult)
	
	# Verificar daño contra élites
	var is_elite_target = false
	if target.has_method("is_elite") and target.is_elite():
		is_elite_target = true
	elif "is_elite" in target and target.is_elite:
		is_elite_target = true
		
	if is_elite_target:
		var ps = get_tree().get_first_node_in_group("player_stats")
		if ps and ps.has_method("get_stat"):
			var elite_mult = ps.get_stat("elite_damage_mult")
			if elite_mult > 0:
				if elite_mult < 0.1: elite_mult = 1.0 # Safety check
				final_damage = int(final_damage * elite_mult)
				# print("⚔️ Elite Hit! Damage x%.2f" % elite_mult)
	
	# Play Hit Sound
	_play_hit_sound()

	# -----------------------------------------------------------
	# LÓGICA DE NUEVOS OBJETOS (Phase 3)
	# -----------------------------------------------------------
	# Calcular distancia desde el jugador al enemigo (NO la distancia recorrida por el proyectil)
	var player_to_enemy_distance: float = 0.0
	var player = get_tree().get_first_node_in_group("player")
	if player and target:
		player_to_enemy_distance = player.global_position.distance_to(target.global_position)
	
	# 1. Tiro Certero (Sharpshooter): +damage si enemigo lejos (> 300 del jugador)
	var ps = get_tree().get_first_node_in_group("player_stats")
	if ps:
		# Check Sharpshooter - usa distancia del jugador al enemigo
		var sharpshooter_val = ps.get_stat("long_range_damage_bonus") if ps.has_method("get_stat") else 0.0
		if sharpshooter_val > 0 and player_to_enemy_distance > 300:
			final_damage = int(final_damage * (1.0 + sharpshooter_val))
			
		# 2. Peleador Callejero (Street Brawler): +damage si enemigo cerca (< 150 del jugador)
		var brawler_val = ps.get_stat("close_range_damage_bonus") if ps.has_method("get_stat") else 0.0
		if brawler_val > 0 and player_to_enemy_distance < 150:
			final_damage = int(final_damage * (1.0 + brawler_val))
			
		# 3. Verdugo (Executioner): +damage si enemigo Low HP (< 30%)
		var executioner_val = ps.get_stat("low_hp_damage_bonus") if ps.has_method("get_stat") else 0.0
		if executioner_val > 0:
			var hp_pct = 1.0
			if target.has_method("get_health_percent"):
				hp_pct = target.get_health_percent()
			elif "health_component" in target and target.health_component:
				hp_pct = target.health_component.get_health_percent()
			
			if hp_pct < 0.30: # 30% HP threshold
				final_damage = int(final_damage * (1.0 + executioner_val))
		
		# 4. Combustión Instantánea (Combustion - Rework): Burn aplica daño instantáneo
		var combustion_active = ps.get_stat("combustion_active") if ps.has_method("get_stat") else 0.0
		if combustion_active > 0:
			# Si aplicamos quemadura, aplicamos su daño total instantáneamente
			var burn_chance = get_meta("burn_chance", 0.0)
			# Asumimos que si hay status_effect manager o similar, aplicamos daño extra
			# Simplificación: +50% daño extra como "explosión" si el proyectil tiene elemento fuego
			if get_meta("element", "") == "fire" or burn_chance > 0:
				var burn_dmg = final_damage * 0.5
				target.take_damage(int(burn_dmg))
				FloatingText.spawn_custom(target.global_position + Vector2(10, -40), "COMB!", Color.ORANGE_RED)

		# 5. Ruleta Rusa (Russian Roulette): 1% chance de 4x daño, o 0 daño?
		# Descripción: "1% chance for massive damage" -> Digamos 10x daño
		var russian_roulette = ps.get_stat("russian_roulette") if ps.has_method("get_stat") else 0.0
		if russian_roulette > 0:
			if randf() < 0.01: # 1%
				final_damage *= 10.0


				FloatingText.spawn_custom(target.global_position + Vector2(0, -60), "JACKPOT!", Color.GOLD)
				_play_roulette_sound()
			# Opcional: penalización en tiros normales? "Ruleta rusa" implica riesgo.
			# Por ahora solo bonus masivo.
			
		# 9. Hemorragia (Hemorrhage): Chance de aplicar Sangrado
		var bleed_chance = ps.get_stat("bleed_on_hit_chance") if ps.has_method("get_stat") else 0.0
		if bleed_chance > 0 and randf() < bleed_chance:
			if target.has_method("apply_bleed"):
				# Daño de sangrado base o proporcional
				var bleed_dmg = max(1, damage * 0.2) # 20% del daño del golpe
				target.apply_bleed(bleed_dmg, 3.0)
				FloatingText.spawn_custom(target.global_position + Vector2(-10, -30), "BLEED", Color.RED)
	# -----------------------------------------------------------
	# -----------------------------------------------------------
	
	# Aplicar daño
	if target.has_method("take_damage"):
		target.take_damage(final_damage)
		
		# LOG: Registrar daño aplicado
		var weapon_id = get_meta("weapon_id", "unknown_projectile")
		var is_crit = final_damage > damage  # Si hay diferencia, fue crítico
		DamageLogger.log_weapon_damage(weapon_id, target.name, final_damage, {"crit": is_crit, "effect": get_meta("effect", "none")})
		
		# Aplicar life steal
		ProjectileFactory.apply_life_steal(get_tree(), final_damage)
		# Verificar execute threshold después del daño
		ProjectileFactory.check_execute(get_tree(), target)
		# Aplicar efectos de estado por probabilidad
		ProjectileFactory.apply_status_effects_chance(get_tree(), target)
	elif target.has_node("HealthComponent"):
		var hc = target.get_node("HealthComponent")
		if hc.has_method("take_damage"):
			hc.take_damage(final_damage, "physical")
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
		
		enemies_hit.append(next_target)
		current_pos = next_target.global_position
		chain_damage *= 0.8  # Reducir daño progresivamente

func _find_chain_target(from_pos: Vector2, exclude: Array) -> Node:
	"""Buscar siguiente objetivo para chain (OPTIMIZADO: Spatial Partitioning)"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	var range_val = 250.0 # Rango de chain aumentado para facilitar conexiones
	
	circle.radius = range_val
	query.shape = circle
	query.transform = Transform2D(0, from_pos)
	
	# Mascara 2 (Layer 2) = Enemies, Mascara 6 (Layer 2+3) = Enemies + Bosses
	query.collision_mask = 2 | 4 
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	# Query espacial eficiente (Max 12 candidatos cercanos)
	var results = space_state.intersect_shape(query, 12)
	
	var closest: Node = null
	var closest_dist_sq = range_val * range_val
	
	for res in results:
		var collider = res.collider
		if collider in exclude or not is_instance_valid(collider):
			continue
			
		# Verificación extra de grupo por seguridad
		if not collider.is_in_group("enemies"):
			continue
			
		var dist_sq = from_pos.distance_squared_to(collider.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = collider
			
	return closest


func _spawn_chain_lightning_visual(from_pos: Vector2, to_pos: Vector2) -> void:
	"""Crear efecto visual de rayo entre posiciones"""
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = projectile_color
	line.default_color.a = 0.9
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.z_index = 100
	get_tree().current_scene.add_child(line)
	
	# Desvanecer y eliminar
	var tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	if get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			return players[0]
	return null
	
	# Efecto de impacto
	_spawn_hit_effect()
	
	# Verificar pierce
	if pierces_remaining > 0:
		pierces_remaining -= 1
	else:
		_destroy()

func _spawn_hit_effect() -> void:
	"""Crear efecto visual simple al impactar"""
	# OPTIMIZACIÓN: Límite global de partículas de impacto
	const MAX_HIT_PARTICLES: int = 40
	if SimpleProjectile._active_hit_particle_count >= MAX_HIT_PARTICLES:
		return

	SimpleProjectile._active_hit_particle_count += 1

	# Partículas simples de impacto
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.3
	particles.direction = -direction
	particles.spread = 45.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = projectile_color
	
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	
	# Instanciar efecto visual extra si existe
	if hit_vfx_scene:
		var effect = hit_vfx_scene.instantiate()
		effect.global_position = global_position
		get_tree().root.add_child(effect)
	
	# Auto-destruir partículas y decrementar contador
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
		SimpleProjectile._active_hit_particle_count = maxi(0, SimpleProjectile._active_hit_particle_count - 1)
	)

func _spawn_lifesteal_effect(player: Node) -> void:
	"""Crear efecto visual de lifesteal - partículas verdes volando hacia el jugador"""
	if not is_instance_valid(player):
		return
	
	var start_pos = global_position
	var end_pos = player.global_position
	
	# Crear partículas verdes que van hacia el jugador
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 12
	particles.lifetime = 0.5
	
	# Dirección hacia el jugador
	var dir_to_player = (end_pos - start_pos).normalized()
	particles.direction = dir_to_player
	particles.spread = 25.0
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 250.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	
	# Color verde brillante para lifesteal
	particles.color = Color(0.3, 1.0, 0.4, 1.0)
	
	# Gradiente para fade out
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.3, 1.0, 0.4, 1.0))
	gradient.set_color(1, Color(0.2, 0.8, 0.3, 0.0))
	particles.color_ramp = gradient
	
	particles.global_position = start_pos
	get_tree().current_scene.add_child(particles)
	
	# Crear también un flash verde en el jugador
	_spawn_heal_flash(player)
	
	# Auto-destruir partículas
	var timer = get_tree().create_timer(0.8)
	timer.timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _spawn_heal_flash(player: Node) -> void:
	"""Crear flash verde en el jugador al recibir curación"""
	if not is_instance_valid(player):
		return
	
	# Crear un sprite temporal con efecto de curación
	var flash = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Dibujar un círculo verde suave
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 14:
				var alpha = 1.0 - (dist / 14.0)
				img.set_pixel(x, y, Color(0.3, 1.0, 0.4, alpha * 0.7))
	
	flash.texture = ImageTexture.create_from_image(img)
	flash.z_index = 100
	flash.scale = Vector2(2.0, 2.0)
	
	player.add_child(flash)
	
	# Animar el flash (crecer y desvanecerse)
	var tween = player.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(4.0, 4.0), 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(flash.queue_free)

func _destroy() -> void:
	# Si tenemos visual animado, reproducir impacto
	if animated_sprite and is_instance_valid(animated_sprite):
		# Detener movimiento
		set_process(false)
		# Reproducir animación de impacto
		animated_sprite.play_impact()
		# Esperar a que termine
		await animated_sprite.impact_finished
	
	destroyed.emit()
	
	# OPTIMIZACIÓN: Devolver al pool en lugar de destruir
	# Esto permite reutilizar el proyectil sin crear uno nuevo
	if has_meta("_pooled") and get_meta("_pooled") == true:
		ProjectilePool.release(self)
	else:
		queue_free()

func _play_hit_sound() -> void:
	"""Reproducir sonido de impacto basado en metadata o elemento"""
	# 1. Intentar sonido específico del arma
	var hit_sound = get_meta("hit_sound", "")
	
	# 2. Si no hay específico, usar genérico por elemento
	if hit_sound == "":
		match element_type:
			"ice": hit_sound = "sfx_ice_hit"
			"fire": hit_sound = "sfx_fire_hit"
			"arcane": hit_sound = "sfx_arcane_hit"
			"lightning": hit_sound = "sfx_lightning_hit"
			"nature": hit_sound = "sfx_nature_hit"
			"dark": hit_sound = "sfx_shadow_hit" # Dark maps to Shadow SFX
			_: hit_sound = "sfx_hit_flesh" # Default fallback
			
	# 3. Reproducir si AudioManager está disponible
	if hit_sound != "":
		var audio_manager = get_tree().get_first_node_in_group("audio_manager")
		if audio_manager and audio_manager.has_method("play_sfx_random_pitch"):
			# Prefer random pitch for variety
			audio_manager.play_sfx_random_pitch(hit_sound)
		elif audio_manager and audio_manager.has_method("play"):
			audio_manager.play(hit_sound)

