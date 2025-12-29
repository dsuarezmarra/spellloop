# ProjectileFactory.gd
# Fábrica centralizada para crear proyectiles de todas las armas
# Se integra con SimpleProjectile existente y añade nuevos tipos

extends Node
class_name ProjectileFactory

# Referencia a la escena de proyectil base
static var _projectile_scene: PackedScene = null

# ═══════════════════════════════════════════════════════════════════════════════
# MAPEO DE ELEMENTOS
# ═══════════════════════════════════════════════════════════════════════════════

# Convertir elemento de WeaponDatabase a string para SimpleProjectile
const ELEMENT_TO_STRING: Dictionary = {
	0: "ice",       # ICE
	1: "fire",      # FIRE
	2: "lightning", # LIGHTNING
	3: "arcane",    # ARCANE
	4: "dark",      # SHADOW
	5: "nature",    # NATURE
	6: "ice",       # WIND (usar ice como fallback)
	7: "nature",    # EARTH (usar nature como fallback)
	8: "arcane",    # LIGHT (usar arcane como fallback)
	9: "dark"       # VOID (usar dark como fallback)
}

# ═══════════════════════════════════════════════════════════════════════════════
# CREACIÓN DE PROYECTILES
# ═══════════════════════════════════════════════════════════════════════════════

static func create_projectile(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear un proyectil básico
	data requiere: direction, start_position, damage, speed, pierce, etc.
	"""
	var projectile = _create_base_projectile(data)
	if projectile == null:
		return null
	
	projectile.global_position = data.get("start_position", owner.global_position)
	projectile.direction = data.get("direction", Vector2.RIGHT)
	
	# Rotar hacia la dirección
	projectile.rotation = data.direction.angle()
	
	# Añadir al árbol
	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(projectile)
	else:
		owner.get_parent().add_child(projectile)
	
	return projectile

static func create_beam(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear un rayo instantáneo
	Daña todo en su camino inmediatamente
	"""
	var beam = BeamEffect.new()
	beam.setup(data)
	beam.global_position = data.get("start_position", owner.global_position)
	beam.direction = data.get("direction", Vector2.RIGHT)
	
	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(beam)
	
	# El beam se procesa instantáneamente y aplica daño
	beam.fire(owner)
	
	return beam

static func create_aoe(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear área de efecto
	"""
	var aoe = AOEEffect.new()
	aoe.setup(data)
	aoe.global_position = data.get("position", owner.global_position)
	
	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(aoe)
	
	# Activar el AOE
	aoe.activate(owner)
	
	return aoe

static func create_orbitals(owner: Node2D, data: Dictionary) -> void:
	"""
	Crear proyectiles orbitantes alrededor del jugador
	Verifica si ya existen orbitales del mismo tipo
	"""
	var orbital_manager = owner.get_node_or_null("OrbitalManager")
	
	if orbital_manager == null:
		orbital_manager = OrbitalManager.new()
		orbital_manager.name = "OrbitalManager"
		owner.add_child(orbital_manager)
	
	orbital_manager.update_orbitals(data)

static func create_chain_projectile(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear proyectil que encadena entre enemigos
	"""
	var chain = ChainProjectile.new()
	chain.setup(data)
	chain.global_position = owner.global_position
	chain.first_target = data.get("first_target")
	
	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(chain)
	
	chain.start_chain()
	
	return chain

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func _create_base_projectile(data: Dictionary) -> SimpleProjectile:
	"""Crear instancia base de SimpleProjectile con los datos"""
	var projectile = SimpleProjectile.new()
	
	# Stats básicos
	projectile.damage = int(data.get("damage", 10))
	projectile.speed = data.get("speed", 300.0)
	projectile.lifetime = data.get("range", 300.0) / data.get("speed", 300.0)  # Calcular lifetime basado en rango
	projectile.knockback_force = data.get("knockback", 50.0)
	projectile.pierce_count = data.get("pierce", 0)
	
	# Elemento
	var element_int = data.get("element", 3)  # Default arcane
	projectile.element_type = ELEMENT_TO_STRING.get(element_int, "arcane")
	
	# Efecto especial (almacenar en metadata)
	projectile.set_meta("effect", data.get("effect", "none"))
	projectile.set_meta("effect_value", data.get("effect_value", 0.0))
	projectile.set_meta("effect_duration", data.get("effect_duration", 0.0))
	projectile.set_meta("crit_chance", data.get("crit_chance", 0.0))
	projectile.set_meta("weapon_id", data.get("weapon_id", ""))
	
	return projectile

static func get_element_string(element_enum: int) -> String:
	"""Convertir enum de elemento a string"""
	return ELEMENT_TO_STRING.get(element_enum, "arcane")


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: BeamEffect
# ═══════════════════════════════════════════════════════════════════════════════

class BeamEffect extends Node2D:
	var damage: float = 25.0
	var beam_range: float = 600.0
	var beam_width: float = 10.0
	var duration: float = 0.3
	var pierce: int = 999
	var knockback: float = 0.0
	var color: Color = Color.WHITE
	var effect: String = "none"
	var effect_value: float = 0.0
	var effect_duration: float = 0.0
	var crit_chance: float = 0.0
	var direction: Vector2 = Vector2.RIGHT
	
	var _timer: float = 0.0
	var _has_fired: bool = false
	
	func setup(data: Dictionary) -> void:
		damage = data.get("damage", 25.0)
		beam_range = data.get("range", 600.0)
		beam_width = data.get("area", 1.0) * 20.0
		duration = data.get("duration", 0.3)
		knockback = data.get("knockback", 0.0)
		color = data.get("color", Color.WHITE)
		effect = data.get("effect", "none")
		effect_value = data.get("effect_value", 0.0)
		effect_duration = data.get("effect_duration", 0.0)
		crit_chance = data.get("crit_chance", 0.0)
	
	func fire(owner: Node2D) -> void:
		if _has_fired:
			return
		_has_fired = true
		
		# Usar raycast para encontrar todos los enemigos en la línea
		var space_state = owner.get_world_2d().direct_space_state
		var end_pos = global_position + direction * beam_range
		
		# Query para el rayo
		var query = PhysicsRayQueryParameters2D.create(global_position, end_pos)
		query.collision_mask = 2  # Capa de enemigos
		query.collide_with_areas = true
		query.collide_with_bodies = true
		
		# Encontrar todos los enemigos en el camino
		var enemies_hit = []
		var current_pos = global_position
		
		for i in range(50):  # Límite de iteraciones
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				break
			
			var collider = result.collider
			if collider.is_in_group("enemies"):
				enemies_hit.append(collider)
				_apply_damage(collider)
			
			# Mover el punto de inicio más allá
			current_pos = result.position + direction * 5.0
			query = PhysicsRayQueryParameters2D.create(current_pos, end_pos)
			query.collision_mask = 2
			query.exclude = [collider.get_rid()]
		
		# Crear visual del rayo
		_create_beam_visual(end_pos)
	
	func _apply_damage(enemy: Node) -> void:
		var final_damage = damage
		
		# Verificar crítico
		if randf() < crit_chance:
			final_damage *= 2.0
		
		if enemy.has_method("take_damage"):
			enemy.take_damage(int(final_damage))
		
		# Aplicar knockback
		if knockback != 0 and enemy.has_method("apply_knockback"):
			var kb_dir = (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(kb_dir * knockback)
	
	func _create_beam_visual(end_pos: Vector2) -> void:
		# Crear línea visual
		var line = Line2D.new()
		line.width = beam_width
		line.default_color = color
		line.add_point(Vector2.ZERO)
		line.add_point(to_local(end_pos))
		add_child(line)
		
		# Efecto de fade out
		var tween = create_tween()
		tween.tween_property(line, "modulate:a", 0.0, duration)
		tween.tween_callback(queue_free)
	
	func _process(delta: float) -> void:
		_timer += delta
		if _timer >= duration:
			queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: AOEEffect
# ═══════════════════════════════════════════════════════════════════════════════

class AOEEffect extends Node2D:
	var damage: float = 20.0
	var aoe_radius: float = 100.0
	var duration: float = 0.5
	var knockback: float = 150.0
	var color: Color = Color(0.6, 0.4, 0.2)
	var effect: String = "none"
	var effect_value: float = 0.0
	var effect_duration: float = 0.0
	var crit_chance: float = 0.0
	
	var _timer: float = 0.0
	var _activated: bool = false
	var _enemies_damaged: Array = []
	
	func setup(data: Dictionary) -> void:
		damage = data.get("damage", 20.0)
		aoe_radius = data.get("area", 1.0) * 80.0  # Escalar área
		duration = data.get("duration", 0.5)
		knockback = data.get("knockback", 150.0)
		color = data.get("color", Color(0.6, 0.4, 0.2))
		effect = data.get("effect", "none")
		effect_value = data.get("effect_value", 0.0)
		effect_duration = data.get("effect_duration", 0.0)
		crit_chance = data.get("crit_chance", 0.0)
	
	func activate(owner: Node2D) -> void:
		if _activated:
			return
		_activated = true
		
		# Crear área de colisión
		var area = Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2  # Enemigos
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = aoe_radius
		shape.shape = circle
		area.add_child(shape)
		add_child(area)
		
		# Conectar señal
		area.body_entered.connect(_on_body_entered)
		area.area_entered.connect(_on_area_entered)
		
		# Crear visual
		_create_aoe_visual()
		
		# Activar daño inicial a enemigos ya en área
		await get_tree().process_frame
		_damage_enemies_in_area()
	
	func _on_body_entered(body: Node2D) -> void:
		if body.is_in_group("enemies") and body not in _enemies_damaged:
			_apply_damage(body)
	
	func _on_area_entered(area: Area2D) -> void:
		var parent = area.get_parent()
		if parent and parent.is_in_group("enemies") and parent not in _enemies_damaged:
			_apply_damage(parent)
	
	func _damage_enemies_in_area() -> void:
		if not get_tree():
			return
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy in _enemies_damaged:
				continue
			
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= aoe_radius:
				_apply_damage(enemy)
	
	func _apply_damage(enemy: Node) -> void:
		if enemy in _enemies_damaged:
			return
		_enemies_damaged.append(enemy)
		
		var final_damage = damage
		if randf() < crit_chance:
			final_damage *= 2.0
		
		if enemy.has_method("take_damage"):
			enemy.take_damage(int(final_damage))
		
		# Aplicar knockback (puede ser negativo para pull)
		if knockback != 0 and enemy.has_method("apply_knockback"):
			var kb_dir = (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(kb_dir * knockback)
		
		# Aplicar efectos especiales
		_apply_effect(enemy)
	
	func _apply_effect(enemy: Node) -> void:
		if effect == "none":
			return
		
		match effect:
			"stun":
				if enemy.has_method("apply_stun"):
					enemy.apply_stun(effect_duration)
			"pull":
				if enemy.has_method("apply_pull"):
					enemy.apply_pull(global_position, effect_value, effect_duration)
	
	func _create_aoe_visual() -> void:
		# Crear círculo visual
		var canvas = Node2D.new()
		canvas.name = "AOEVisual"
		add_child(canvas)
		
		# Animación de expansión y fade
		var tween = create_tween()
		tween.tween_property(canvas, "scale", Vector2(1.2, 1.2), duration * 0.8)
		tween.parallel().tween_property(canvas, "modulate:a", 0.0, duration)
		tween.tween_callback(queue_free)
	
	func _draw() -> void:
		# Dibujar círculo del AOE
		draw_circle(Vector2.ZERO, aoe_radius, Color(color.r, color.g, color.b, 0.4))
		draw_arc(Vector2.ZERO, aoe_radius, 0, TAU, 32, color, 3.0)
	
	func _process(delta: float) -> void:
		_timer += delta
		queue_redraw()
		
		if _timer >= duration:
			queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: OrbitalManager
# ═══════════════════════════════════════════════════════════════════════════════

class OrbitalManager extends Node2D:
	var orbitals: Array = []
	var orbital_weapon_id: String = ""
	var orbital_count: int = 3
	var orbital_radius: float = 120.0
	var orbital_damage: float = 8.0
	var orbital_speed: float = 200.0
	var color: Color = Color(0.7, 0.3, 1.0)
	var crit_chance: float = 0.0
	
	var _rotation_angle: float = 0.0
	var _last_hit_times: Dictionary = {}  # enemy_id -> last_hit_time
	var _hit_cooldown: float = 0.5  # Tiempo entre hits al mismo enemigo
	
	func update_orbitals(data: Dictionary) -> void:
		"""Actualizar o crear orbitales con nuevos datos"""
		var new_weapon_id = data.get("weapon_id", "")
		var new_count = data.get("orbital_count", 3)
		
		# Si es la misma arma, actualizar stats
		if new_weapon_id == orbital_weapon_id:
			orbital_damage = data.get("damage", orbital_damage)
			orbital_radius = data.get("orbital_radius", orbital_radius)
			
			# Actualizar conteo si cambió
			if new_count != orbital_count:
				orbital_count = new_count
				_recreate_orbitals()
			return
		
		# Nueva arma orbital
		orbital_weapon_id = new_weapon_id
		orbital_count = new_count
		orbital_radius = data.get("orbital_radius", 120.0)
		orbital_damage = data.get("damage", 8.0)
		orbital_speed = data.get("speed", 200.0)
		color = data.get("color", Color(0.7, 0.3, 1.0))
		crit_chance = data.get("crit_chance", 0.0)
		
		_recreate_orbitals()
	
	func _recreate_orbitals() -> void:
		# Limpiar orbitales existentes
		for orbital in orbitals:
			if is_instance_valid(orbital):
				orbital.queue_free()
		orbitals.clear()
		
		# Crear nuevos orbitales
		for i in range(orbital_count):
			var orbital = _create_orbital(i)
			orbitals.append(orbital)
			add_child(orbital)
	
	func _create_orbital(index: int) -> Node2D:
		var orbital = Area2D.new()
		orbital.name = "Orbital_%d" % index
		orbital.collision_layer = 0
		orbital.set_collision_layer_value(4, true)  # Proyectiles
		orbital.collision_mask = 0
		orbital.set_collision_mask_value(2, true)  # Enemigos
		
		# Collision shape
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		orbital.add_child(shape)
		
		# Visual
		var visual = _create_orbital_visual()
		orbital.add_child(visual)
		
		# Conectar señales
		orbital.body_entered.connect(_on_orbital_hit.bind(orbital))
		orbital.area_entered.connect(_on_orbital_area_hit.bind(orbital))
		
		return orbital
	
	func _create_orbital_visual() -> Node2D:
		var sprite = Sprite2D.new()
		
		# Crear imagen circular
		var size = 30
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(size / 2.0, size / 2.0)
		var radius = size / 2.0 - 2.0
		
		for x in range(size):
			for y in range(size):
				var pos = Vector2(x, y)
				var dist = pos.distance_to(center)
				if dist <= radius:
					var t = dist / radius
					var alpha = 1.0 - t * 0.5
					image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
				else:
					image.set_pixel(x, y, Color(0, 0, 0, 0))
		
		sprite.texture = ImageTexture.create_from_image(image)
		return sprite
	
	func _on_orbital_hit(body: Node2D, orbital: Node2D) -> void:
		if body.is_in_group("enemies"):
			_damage_enemy(body)
	
	func _on_orbital_area_hit(area: Area2D, orbital: Node2D) -> void:
		var parent = area.get_parent()
		if parent and parent.is_in_group("enemies"):
			_damage_enemy(parent)
	
	func _damage_enemy(enemy: Node) -> void:
		var enemy_id = enemy.get_instance_id()
		var current_time = Time.get_ticks_msec() / 1000.0
		
		# Verificar cooldown de hit
		if _last_hit_times.has(enemy_id):
			if current_time - _last_hit_times[enemy_id] < _hit_cooldown:
				return
		
		_last_hit_times[enemy_id] = current_time
		
		var final_damage = orbital_damage
		if randf() < crit_chance:
			final_damage *= 2.0
		
		if enemy.has_method("take_damage"):
			enemy.take_damage(int(final_damage))
	
	func _process(delta: float) -> void:
		# Rotar orbitales
		_rotation_angle += orbital_speed * delta * 0.01
		
		# Posicionar cada orbital
		for i in range(orbitals.size()):
			if not is_instance_valid(orbitals[i]):
				continue
			
			var angle = _rotation_angle + (TAU / orbitals.size()) * i
			orbitals[i].position = Vector2(
				cos(angle) * orbital_radius,
				sin(angle) * orbital_radius
			)


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: ChainProjectile
# ═══════════════════════════════════════════════════════════════════════════════

class ChainProjectile extends Node2D:
	var damage: float = 15.0
	var chain_count: int = 2
	var chain_range: float = 150.0
	var speed: float = 600.0
	var color: Color = Color(1.0, 1.0, 0.3)
	var knockback: float = 40.0
	var crit_chance: float = 0.0
	var effect: String = "none"
	var effect_value: float = 0.0
	
	var first_target: Node2D = null
	var current_target: Node2D = null
	var chains_remaining: int = 0
	var enemies_hit: Array = []
	
	var _moving: bool = false
	var _visual: Line2D = null
	
	func setup(data: Dictionary) -> void:
		damage = data.get("damage", 15.0)
		chain_count = data.get("chain_count", 2)
		chain_range = data.get("range", 150.0) * 0.5  # Rango de chain más corto
		speed = data.get("speed", 600.0)
		color = data.get("color", Color(1.0, 1.0, 0.3))
		knockback = data.get("knockback", 40.0)
		crit_chance = data.get("crit_chance", 0.0)
		effect = data.get("effect", "chain")
		effect_value = data.get("effect_value", 2)
	
	func start_chain() -> void:
		if first_target == null or not is_instance_valid(first_target):
			queue_free()
			return
		
		chains_remaining = chain_count
		current_target = first_target
		_moving = true
		
		# Crear visual del rayo
		_visual = Line2D.new()
		_visual.width = 4.0
		_visual.default_color = color
		add_child(_visual)
	
	func _process(delta: float) -> void:
		if not _moving:
			return
		
		if current_target == null or not is_instance_valid(current_target):
			_try_chain_to_next()
			return
		
		# Mover hacia el objetivo
		var direction = (current_target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		
		# Actualizar visual
		if _visual:
			_visual.clear_points()
			_visual.add_point(Vector2.ZERO)
			_visual.add_point(to_local(current_target.global_position))
		
		# Verificar si llegamos
		var dist = global_position.distance_to(current_target.global_position)
		if dist < 20.0:
			_hit_target()
	
	func _hit_target() -> void:
		if current_target == null or not is_instance_valid(current_target):
			_try_chain_to_next()
			return
		
		enemies_hit.append(current_target)
		
		# Aplicar daño
		var final_damage = damage
		if randf() < crit_chance:
			final_damage *= 2.0
		
		if current_target.has_method("take_damage"):
			current_target.take_damage(int(final_damage))
		
		# Aplicar knockback
		if knockback != 0 and current_target.has_method("apply_knockback"):
			var kb_dir = (current_target.global_position - global_position).normalized()
			current_target.apply_knockback(kb_dir * knockback)
		
		# Intentar encadenar
		_try_chain_to_next()
	
	func _try_chain_to_next() -> void:
		chains_remaining -= 1
		
		if chains_remaining <= 0:
			_finish_chain()
			return
		
		# Buscar siguiente objetivo
		var next_target = _find_next_target()
		if next_target == null:
			_finish_chain()
			return
		
		# Crear efecto de "salto"
		_create_chain_effect()
		
		current_target = next_target
	
	func _find_next_target() -> Node2D:
		if not get_tree():
			return null
		var enemies = get_tree().get_nodes_in_group("enemies")
		var best_target: Node2D = null
		var best_dist: float = chain_range
		
		for enemy in enemies:
			if enemy in enemies_hit:
				continue
			if not is_instance_valid(enemy):
				continue
			
			var dist = global_position.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best_target = enemy
		
		return best_target
	
	func _create_chain_effect() -> void:
		# Flash visual en la posición actual
		var flash = Sprite2D.new()
		# Crear pequeño destello
		var size = 20
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		for x in range(size):
			for y in range(size):
				var dist = Vector2(x, y).distance_to(Vector2(size/2, size/2))
				if dist < size / 2:
					image.set_pixel(x, y, color)
		flash.texture = ImageTexture.create_from_image(image)
		flash.global_position = global_position
		get_parent().add_child(flash)
		
		# Fade out
		var tween = flash.create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.2)
		tween.tween_callback(flash.queue_free)
	
	func _finish_chain() -> void:
		_moving = false
		
		# Fade out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
