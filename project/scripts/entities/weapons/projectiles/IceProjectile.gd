# IceProjectile.gd
# Proyectil de hielo - REDISEÑO COMPLETO: Autodirigido + Impacto Visual + Knockback

extends Area2D

signal hit_enemy(enemy: Node, damage: int)
signal expired

# Movimiento
var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var lifetime: float = 4.0
var current_lifetime: float = 0.0

# Targeting (NUEVO)
var target_enemy: Node = null
var auto_seek_range: float = 800.0  # Distancia máxima para buscar enemigos
var auto_seek_enabled: bool = true
var seek_check_interval: float = 0.2  # Revisar objetivo cada 0.2 segundos
var seek_check_timer: float = 0.0

# Daño
var damage: int = 8
var element_type: String = "ice"

# Física
var knockback: float = 200.0  # Aumentado de 80 a 200
var pierces_enemies: bool = false
var max_pierces: int = 1
var enemies_hit: Array[Node] = []

# Efecto de hielo
var slow_duration: float = 2.0
var slow_percentage: float = 0.5

# Visual (MEJORADO)
var animated_sprite: AnimatedSprite2D = null
var animation_playing: String = "InFlight"
var impact_vfx_enabled: bool = true
var impact_scale: Vector2 = Vector2(1.2, 1.2)

# DEBUG
var debug_mode: bool = false

func _ready() -> void:
	"""Inicializar proyectil"""
	current_lifetime = 0.0
	enemies_hit.clear()
	seek_check_timer = 0.0
	
	# Z-INDEX: Proyectiles deben estar ARRIBA de biomas
	z_index = 5  # Arriba de enemigos, decoraciones, etc
	
	# CONFIGURACIÓN DE CAPAS CRÍTICA
	set_collision_layer_value(3, true)   # Este nodo está en layer 3
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	
	set_collision_mask_value(2, true)    # Detectar layer 2 (enemigos)
	set_collision_mask_value(1, false)
	set_collision_mask_value(3, false)
	
	# Crear/verificar CollisionShape2D
	var collision_shape = null
	for child in get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.shape = CircleShape2D.new()
		collision_shape.shape.radius = 8.0
		add_child(collision_shape)
	
	# Conectar señales por si acaso
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Crear visual
	_create_animated_visual()
	
	print("[IceProjectile] ✅ Proyectil inicializado (autodirigido, impacto visual, knockback)")

func _create_animated_visual() -> void:
	"""Crear AnimatedSprite2D"""
	for child in get_children():
		if child is AnimatedSprite2D:
			child.queue_free()
	
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "IcicleAnimatedSprite"
	add_child(animated_sprite)
	
	var sprite_frames = SpriteFrames.new()
	
	sprite_frames.add_animation("InFlight")
	sprite_frames.set_animation_speed("InFlight", 10)
	sprite_frames.set_animation_loop("InFlight", true)
	
	sprite_frames.add_animation("Launch")
	sprite_frames.set_animation_speed("Launch", 12)
	sprite_frames.set_animation_loop("Launch", true)
	
	sprite_frames.add_animation("Impact")
	sprite_frames.set_animation_speed("Impact", 12)
	sprite_frames.set_animation_loop("Impact", false)
	
	_create_fallback_sprite(sprite_frames)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation = animation_playing
	animated_sprite.play()

func _create_fallback_sprite(sprite_frames: SpriteFrames) -> void:
	"""Crear sprite fallback (carámbano de hielo) - MÁS GRANDE para ser visible"""
	var image = Image.create(32, 64, false, Image.FORMAT_RGBA8)  # Duplicado de tamaño
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var progress = float(y) / float(image.get_height())
			var left_bound = int(lerp(8.0, 14.0, progress))
			var right_bound = int(lerp(24.0, 18.0, progress))
			
			if x >= left_bound and x < right_bound:
				if progress < 0.3:
					var alpha = progress / 0.3
					image.set_pixel(x, y, Color(0.6, 0.8, 1.0, alpha))
				else:
					image.set_pixel(x, y, Color(0.5, 0.7, 1.0, 1.0))
	
	var texture = ImageTexture.create_from_image(image)
	for anim_name in ["Launch", "InFlight", "Impact"]:
		sprite_frames.add_frame(anim_name, texture)

func initialize(p_direction: Vector2, p_speed: float, p_damage: int, p_lifetime: float, p_element: String = "ice") -> void:
	"""Inicializar propiedades"""
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	lifetime = p_lifetime
	element_type = p_element

func _process(delta: float) -> void:
	"""Mover, buscar objetivo, y detectar colisiones"""
	current_lifetime += delta
	
	if current_lifetime >= lifetime:
		_expire()
		return
	
	# AUTO-SEEK: Buscar enemigo más cercano periódicamente
	if auto_seek_enabled:
		seek_check_timer += delta
		if seek_check_timer >= seek_check_interval:
			_seek_nearest_enemy()
			seek_check_timer = 0.0
	
	# AUTO-SEEK: Si tenemos objetivo, dirigirse hacia él
	if target_enemy and is_instance_valid(target_enemy):
		var target_pos = target_enemy.global_position
		direction = (target_pos - global_position).normalized()
	
	# Mover
	global_position += direction * speed * delta
	
	# Rotar sprite hacia dirección de movimiento
	# NOTA: El offset de rotación se configura en ProjectileVisualManager.WEAPON_SPRITE_CONFIG
	if animated_sprite:
		animated_sprite.rotation = direction.angle()
	
	# CRÍTICO: Detectar colisiones manualmente
	_check_collision_with_enemies()

func _seek_nearest_enemy() -> void:
	"""Buscar el enemigo más cercano sin límite de distancia"""
	if not get_tree():
		return
	
	var nearest_enemy = null
	var nearest_distance = INF
	
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy in enemies_hit:
			continue
		
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		
		# Considerar en rango de auto-seek
		if distance < auto_seek_range and distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	
	if nearest_enemy != target_enemy:
		target_enemy = nearest_enemy

func _check_collision_with_enemies() -> void:
	"""Detectar colisiones usando get_overlapping_bodies()"""
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		# Evitar impactar dos veces al mismo enemigo
		if body in enemies_hit:
			continue
		
		# Verificar si es enemigo
		if body.is_in_group("enemies") or body.has_method("take_damage"):
			enemies_hit.append(body)
			
			# Crear efecto visual de impacto
			_create_impact_effect(body)
			
			# Aplicar daño
			_apply_damage(body)
			
			# Aplicar knockback
			_apply_knockback(body)
			
			# Si no atraviesa enemigos, expira al impactar
			if not pierces_enemies:
				_expire()
				return

func _on_body_entered(body: Node2D) -> void:
	"""Fallback: body_entered signal"""
	if body in enemies_hit:
		return
	
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		enemies_hit.append(body)
		_create_impact_effect(body)
		_apply_damage(body)
		_apply_knockback(body)
		if not pierces_enemies:
			_expire()

func _on_area_entered(area: Area2D) -> void:
	"""Fallback: area_entered signal"""
	if area in enemies_hit:
		return
	
	if area.is_in_group("enemies"):
		enemies_hit.append(area)
		_create_impact_effect(area)
		_apply_damage(area)
		_apply_knockback(area)
		if not pierces_enemies:
			_expire()

func _apply_damage(enemy: Node) -> void:
	"""Aplicar daño al enemigo"""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	_apply_ice_effect(enemy)
	hit_enemy.emit(enemy, damage)

func _apply_knockback(enemy: Node) -> void:
	"""Aplicar knockback (empujón) al enemigo"""
	if not enemy.has_method("apply_knockback"):
		return
	
	# Dirección del knockback: desde el proyectil hacia el enemigo (alejarlo)
	var knockback_direction = (enemy.global_position - global_position).normalized()
	var knockback_force = knockback_direction * knockback
	
	enemy.apply_knockback(knockback_force)

func _apply_ice_effect(enemy: Node) -> void:
	"""Aplicar ralentización de hielo"""
	# TODO: Implementar sistema de ralentización cuando se agregue StatusEffect
	pass

func _create_impact_effect(enemy: Node) -> void:
	"""Crear efecto visual de impacto"""
	if not impact_vfx_enabled:
		return
	
	# Cambiar animación del proyectil a "Impact"
	if animated_sprite:
		animated_sprite.animation = "Impact"
		animated_sprite.play()
	
	# Escalar el proyectil brevemente (efecto "pop")
	var original_scale = scale
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", impact_scale, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)
	
	# Parpadeo opcional en el sprite del enemigo si lo tiene
	if enemy.has_node("AnimatedSprite2D"):
		var enemy_sprite = enemy.get_node("AnimatedSprite2D")
		var enemy_tween = create_tween()
		var original_modulate = enemy_sprite.modulate
		enemy_tween.tween_property(enemy_sprite, "modulate", Color.WHITE.lightened(0.3), 0.05)
		enemy_tween.tween_property(enemy_sprite, "modulate", original_modulate, 0.05)

func _expire() -> void:
	"""Expirar proyectil con efecto visual"""
	# Emitir señal inmediatamente
	expired.emit()
	
	# Efecto de desaparición RÁPIDA (fade out + escala) en paralelo
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	
	# Eliminar INMEDIATAMENTE, sin esperar el tween
	queue_free()
