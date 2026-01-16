extends CharacterBody2D
class_name SpellloopMagicProjectile

"""
🔮 PROYECTIL MÁGICO - SPELLLOOP STYLE
===================================

Proyectil mágico mejorado para sistema auto-ataque:
- Tracking hacia enemigos
- Efectos visuales mejorados
- Daño y eliminación automática
"""

signal projectile_hit(target: Node2D, damage: int)
signal projectile_destroyed

# Configuración del proyectil
var damage: int = 10
var projectile_speed: float = 300.0
var lifetime: float = 5.0
var auto_target: bool = true
var pierce_count: int = 0  # 0 = no piercing
var homing_strength: float = 0.0  # 0 = no homing
var projectile_color: Color = Color(0.3, 0.5, 1.0) # Default Blue

# Estado interno
var direction: Vector2
var target_position: Vector2
var life_timer: float = 0.0
var hits_made: int = 0

# Referencias visuales
@onready var sprite: Sprite2D
@onready var collision_shape: CollisionShape2D
@onready var trail_particles: GPUParticles2D

# Efectos
var glow_tween

func _ready():
	setup_projectile()
	setup_visuals()
	setup_collision()
	setup_effects()

func initialize(start_pos: Vector2, target_pos: Vector2, dmg: int, speed: float):
	"""Inicializar proyectil con parámetros"""
	global_position = start_pos
	target_position = target_pos
	damage = dmg
	projectile_speed = speed
	
	# Calcular dirección inicial
	direction = (target_position - start_pos).normalized()
	
	# Regenerar textura si el color cambió
	if sprite and projectile_color != Color(0.3, 0.5, 1.0):
		create_magic_projectile_texture()

func setup_projectile():
	"""Configurar propiedades básicas del proyectil"""
	z_index = 50  # Por encima de enemigos
	
	# Configurar capas de colisión
	collision_layer = 8    # Capa de proyectiles
	collision_mask = 16    # Colisiona con enemigos

func setup_visuals():
	"""Configurar apariencia visual"""
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Crear textura de proyectil mágico
	create_magic_projectile_texture()
	
	# Configurar escala
	var scale_factor = 1.0
	var sm = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ScaleManager"):
		sm = get_tree().root.get_node("ScaleManager")
	if sm and sm.has_method("get_scale"):
		scale_factor = sm.get_scale()
	sprite.scale = Vector2(scale_factor, scale_factor)

func create_magic_projectile_texture():
	"""Crear textura procedural para el proyectil usando projectile_color"""
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Crear orbe mágico con gradiente
	var center = Vector2(size / 2.0, size / 2.0)
	var max_radius = size / 2.0 - 1.0
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= max_radius:
				var intensity = 1.0 - (distance / max_radius)
				# Mezclar blanco (núcleo) con projectile_color (borde)
				var base_col = Color.WHITE.lerp(projectile_color, 0.3)
				var final_col = base_col.lerp(projectile_color, 1.0 - intensity)
				final_col.a = intensity * 0.95
				image.set_pixel(x, y, final_col)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func setup_collision():
	"""Configurar colisión"""
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	
	var circle = CircleShape2D.new()
	circle.radius = 6.0
	collision_shape.shape = circle

func setup_effects():
	"""Configurar efectos visuales"""
	# Efecto de brillo pulsante
	glow_tween = create_tween()
	
	start_glow_effect()

func start_glow_effect():
	"""Iniciar efecto de brillo"""
	if glow_tween and sprite:
		var glow_col = projectile_color.lightened(0.5)
		glow_tween.tween_property(sprite, "modulate", glow_col, 0.5)
		glow_tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)
		glow_tween.set_loops()

func _physics_process(delta):
	"""Actualizar proyectil"""
	life_timer += delta
	
	# Verificar tiempo de vida
	if life_timer >= lifetime:
		destroy_projectile()
		return
	
	# Actualizar movimiento
	update_movement(delta)
	
	# Mover proyectil
	velocity = direction * projectile_speed
	move_and_slide()
	
	# Verificar colisiones
	check_collisions()

func update_movement(delta):
	"""Actualizar movimiento (homing si está habilitado)"""
	if homing_strength > 0.0:
		apply_homing_behavior(delta)

func apply_homing_behavior(delta):
	"""Aplicar comportamiento de seguimiento"""
	# Buscar enemigo más cercano para seguimiento
	var nearest_enemy = find_nearest_enemy()
	if nearest_enemy:
		var to_enemy = (nearest_enemy.global_position - global_position).normalized()
		direction = direction.lerp(to_enemy, homing_strength * delta)

func find_nearest_enemy() -> Node2D:
	"""Encontrar enemigo más cercano en grupo 'enemies'"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
		
	var nearest: Node2D = null
	var min_dist: float = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		# Ignorar enemigos muertos si tienen esa propiedad
		if enemy.has_method("is_dead") and enemy.is_dead(): continue
			
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
			
	return nearest

func check_collisions():
	"""Verificar colisiones con enemigos"""
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.has_method("take_damage"):
			hit_target(collider)

func hit_target(target: Node2D):
	"""Impactar objetivo"""
	# Aplicar daño
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Emitir señal
	projectile_hit.emit(target, damage)
	
	hits_made += 1
	
	# Verificar si debe ser destruido
	if pierce_count == 0 or hits_made > pierce_count:
		destroy_projectile()
	
	# print("🎯 Proyectil impactó objetivo - Daño: ", damage)

func destroy_projectile():
	"""Destruir proyectil"""
	# Efecto de destrucción
	create_destruction_effect()
	
	# Emitir señal
	projectile_destroyed.emit()
	
	# Remover del árbol
	queue_free()

func create_destruction_effect():
	"""Crear efecto visual de destrucción"""
	# Efecto simple de parpadeo
	if sprite:
		var destroy_tween = create_tween()
		# add_child(destroy_tween)  # Ya no es necesario con create_tween()
		
		destroy_tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 0.0), 0.2)
		destroy_tween.tween_callback(func(): queue_free())

func upgrade_projectile(upgrades: Dictionary):
	"""Aplicar mejoras al proyectil"""
	if upgrades.has("damage"):
		damage += upgrades.damage
	if upgrades.has("speed"):
		projectile_speed += upgrades.speed
	if upgrades.has("pierce"):
		pierce_count += upgrades.pierce
	if upgrades.has("homing"):
		homing_strength = upgrades.homing
	if upgrades.has("lifetime"):
		lifetime += upgrades.lifetime

