# OrbitalManager.gd
# Gestiona proyectiles orbitantes alrededor del jugador (arcane_orb, etc.)
# Extraído de ProjectileFactory.gd para mejor organización
#
# NOTA IMPORTANTE SOBRE COLISIONES:
# - Los orbitales son Area2D en layer 4 con máscara para layer 2 (enemigos)
# - Los enemigos son CharacterBody2D en layer 2
# - Para que body_entered funcione:
#   1. Area2D.monitoring = true
#   2. Ambos deben tener CollisionShape2D activos
#   3. La máscara del Area2D debe incluir la capa del CharacterBody2D
# - Las señales se conectan DESPUÉS de añadir al árbol para evitar bugs

extends Node2D
class_name OrbitalManager

var orbitals: Array = []
var orbital_weapon_id: String = ""
var orbital_count: int = 3
var orbital_radius: float = 120.0
var orbital_damage: float = 8.0
var orbital_speed: float = 200.0
var color: Color = Color(0.7, 0.3, 1.0)
var crit_chance: float = 0.0
var crit_damage: float = 2.0
var knockback: float = 20.0

# Efectos especiales
var effect: String = "none"
var effect_value: float = 0.0
var effect_duration: float = 0.0
var hit_sound: String = ""

# Active Shooting (Storm)
var _active_shooting_timer: float = 0.0
var _shooting_range_mult: float = 1.5  # Disparar a 1.5x del radio orbital

var _rotation_angle: float = 0.0
var _last_hit_times: Dictionary = {}
var _hit_cooldown: float = 0.5
var _cleanup_counter: int = 0
var _enhanced_visual: Node2D = null  # OrbitalsVisualContainer
var _use_enhanced: bool = false

# Flag para debug (activar en caso de problemas)
const DEBUG_COLLISIONS: bool = false  # TEMPORAL: Para diagnosticar problema de orbitales

func _ready() -> void:
	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if DEBUG_COLLISIONS:
		print("[OrbitalManager] ✓ _ready() llamado, process_mode=PAUSABLE")

func update_orbitals(data: Dictionary) -> void:
	"""Actualizar o crear orbitales con nuevos datos"""
	var new_weapon_id = data.get("weapon_id", "")
	var new_count = data.get("orbital_count", 3)

	# Si es la misma arma, actualizar stats
	if new_weapon_id == orbital_weapon_id:
		orbital_damage = data.get("damage", orbital_damage)
		orbital_radius = data.get("orbital_radius", orbital_radius)

		if new_count != orbital_count:
			orbital_count = new_count
			_recreate_orbitals()
		return

	# Nueva arma orbital
	orbital_weapon_id = new_weapon_id
	set_meta("weapon_id", orbital_weapon_id)
	orbital_count = new_count
	orbital_radius = data.get("orbital_radius", 120.0)
	orbital_damage = data.get("damage", 8.0)
	orbital_speed = data.get("speed", 200.0)
	color = data.get("color", Color(0.7, 0.3, 1.0))
	crit_chance = data.get("crit_chance", 0.0)
	crit_damage = data.get("crit_damage", 2.0)
	knockback = data.get("knockback", 20.0)
	
	effect = data.get("effect", "none")
	effect_value = data.get("effect_value", 0.0)
	effect_duration = data.get("effect_duration", 0.0)
	hit_sound = data.get("hit_sound", "")
	
	# Detectar si debe disparar activamente (chain effect + orbital)
	if effect == "chain":
		_active_shooting_timer = 0.0
		if DEBUG_COLLISIONS:
			print("[OrbitalManager] Activado modo Shooting para: %s" % orbital_weapon_id)

	_recreate_orbitals()

func _recreate_orbitals() -> void:
	# Limpiar orbitales existentes - desconectar señales primero
	for orbital in orbitals:
		if is_instance_valid(orbital):
			if orbital is Area2D:
				if orbital.body_entered.is_connected(_on_orbital_hit):
					orbital.body_entered.disconnect(_on_orbital_hit)
				if orbital.area_entered.is_connected(_on_orbital_area_hit):
					orbital.area_entered.disconnect(_on_orbital_area_hit)
			orbital.queue_free()
	orbitals.clear()

	# Limpiar visual mejorado anterior
	if _enhanced_visual:
		_enhanced_visual.queue_free()
		_enhanced_visual = null
		_use_enhanced = false

	# Intentar crear visual mejorado
	if orbital_weapon_id != "" and ProjectileVisualManager.instance:
		var weapon_data = WeaponDatabase.get_weapon_data(orbital_weapon_id)
		if not weapon_data.is_empty():
			_enhanced_visual = ProjectileVisualManager.instance.create_orbit_visual(
				orbital_weapon_id, orbital_count, orbital_radius, weapon_data)
			if _enhanced_visual:
				add_child(_enhanced_visual)
				_use_enhanced = true

	# Crear nuevos orbitales (siempre necesarios para detección de colisión)
	# IMPORTANTE: Primero añadirlos al árbol, LUEGO conectar señales
	for i in range(orbital_count):
		var orbital = _create_orbital(i)
		orbitals.append(orbital)
		add_child(orbital)
		# Conectar señales DESPUÉS de añadir al árbol para asegurar que funcionen
		_connect_orbital_signals(orbital)
	
	if DEBUG_COLLISIONS:
		print("[OrbitalManager] ✓ Creados %d orbitales para '%s'" % [orbital_count, orbital_weapon_id])

func _connect_orbital_signals(orbital: Area2D) -> void:
	"""Conectar señales de colisión del orbital.
	Llamar DESPUÉS de add_child() para evitar bugs de detección."""
	if not orbital.body_entered.is_connected(_on_orbital_hit):
		orbital.body_entered.connect(_on_orbital_hit.bind(orbital))
	if not orbital.area_entered.is_connected(_on_orbital_area_hit):
		orbital.area_entered.connect(_on_orbital_area_hit.bind(orbital))
	
	if DEBUG_COLLISIONS:
		print("[OrbitalManager] → Señales conectadas para: %s (layer=%d, mask=%d, monitoring=%s)" % [
			orbital.name, orbital.collision_layer, orbital.collision_mask, orbital.monitoring])

func _create_orbital(index: int) -> Area2D:
	var orbital = Area2D.new()
	orbital.name = "Orbital_%d" % index
	
	# CRÍTICO: Configuración de capas de colisión
	# Layer 4 = Orbitales del jugador
	# Mask 2 = Enemigos (CharacterBody2D)
	orbital.collision_layer = 0
	orbital.set_collision_layer_value(4, true)
	orbital.collision_mask = 0
	orbital.set_collision_mask_value(2, true)  # Detectar enemigos base
	orbital.set_collision_mask_value(3, true)  # Detectar breakables/élites
	
	# CRÍTICO: Habilitar monitoreo para detectar colisiones
	orbital.monitoring = true
	orbital.monitorable = true

	# Crear CollisionShape2D para detección física
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15.0
	shape.shape = circle
	shape.disabled = false  # Asegurar que está habilitado
	orbital.add_child(shape)

	if not _use_enhanced:
		var visual = _create_orbital_visual()
		orbital.add_child(visual)

	# NOTA: Las señales se conectan en _connect_orbital_signals() DESPUÉS de add_child()
	# para asegurar que la detección de colisiones funcione correctamente
	
	if orbital_weapon_id != "":
		orbital.add_to_group("weapon_projectiles_" + orbital_weapon_id)
		orbital.add_to_group("projectiles")

	return orbital

func _create_orbital_visual() -> Node2D:
	var sprite = Sprite2D.new()
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

func _on_orbital_hit(body: Node2D, _orbital: Node2D) -> void:
	"""Callback cuando un orbital colisiona con un CharacterBody2D (enemigo)."""
	if DEBUG_COLLISIONS:
		print("[OrbitalManager] body_entered: %s (in enemies: %s)" % [
			body.name if body else "null", 
			body.is_in_group("enemies") if body else false])
	
	if body and body.is_in_group("enemies"):
		_damage_enemy(body)

func _on_orbital_area_hit(area: Area2D, _orbital: Node2D) -> void:
	"""Callback cuando un orbital colisiona con otra Area2D.
	Verifica si el parent del área es un enemigo (para hitboxes separadas)."""
	var parent = area.get_parent()
	
	if DEBUG_COLLISIONS:
		print("[OrbitalManager] area_entered: %s, parent: %s (in enemies: %s)" % [
			area.name if area else "null",
			parent.name if parent else "null",
			parent.is_in_group("enemies") if parent else false])
	
	if parent and parent.is_in_group("enemies"):
		_damage_enemy(parent)

func _damage_enemy(enemy: Node) -> void:
	"""Aplicar daño a un enemigo con cooldown para evitar spam."""
	if not is_instance_valid(enemy):
		return
		
	var enemy_id = enemy.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0

	# Verificar cooldown por enemigo
	if _last_hit_times.has(enemy_id):
		if current_time - _last_hit_times[enemy_id] < _hit_cooldown:
			return

	_last_hit_times[enemy_id] = current_time
	
	# LOG: Registrar daño orbital
	DamageLogger.log_orbital_damage(orbital_weapon_id, enemy.name, int(orbital_damage), {"effect": effect})

	# Usar DamageCalculator centralizado
	var player = _get_orbital_player()
	var damage_result = DamageCalculator.calculate_final_damage(
		orbital_damage, enemy, player, crit_chance, crit_damage, self
	)

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage_result.get_int_damage(), "physical", self)
		# FIX-R6: Propagar is_crit para feedback visual (texto flotante crit)
		set_meta("last_hit_was_crit", damage_result.is_crit)
		ProjectileFactory.apply_life_steal(get_tree(), damage_result.final_damage)
		ProjectileFactory.check_execute(get_tree(), enemy)
		ProjectileFactory.apply_status_effects_chance(get_tree(), enemy)
		# FIX-R6: Bleed on Hit (upgrade de jugador)
		var ps = get_tree().get_first_node_in_group("player_stats")
		if ps and ps.has_method("get_stat"):
			var bleed_chance = ps.get_stat("bleed_on_hit_chance")
			if bleed_chance > 0 and randf() < bleed_chance:
				if is_instance_valid(enemy) and enemy.has_method("apply_bleed"):
					var bleed_dmg = max(1, damage_result.base_damage * 0.2)
					enemy.apply_bleed(bleed_dmg, 3.0)
		
		# Feedback auditivo distintivo según arma (Fake SevenLabs)
		# Feedback auditivo distintivo según arma
		var hit_sfx = "sfx_hit_ghost"
		
		# 1. Priorizar sonido configurado en metadatos (BaseWeapon -> hit_sound)
		if hit_sound != "":
			hit_sfx = hit_sound
		else:
			# 2. Fallback legacy hardcoded
			match orbital_weapon_id:
				"ice_wand", "glacier": hit_sfx = "sfx_hit_armor" # Sonido seco/cortante
				"fire_wand", "hellfire": hit_sfx = "sfx_hit_flesh" # Sonido impacto orgánico
				"lightning_staff", "storm_caller": hit_sfx = "sfx_hit_bone" # Sonido crujiente
				"nature_staff", "gaia": hit_sfx = "sfx_hit_slime" # Sonido suave
				"void_staff", "void_storm": hit_sfx = "sfx_hit_ghost" # Sonido etéreo
			
		# Solo reproducir si el enemigo sigue siendo válido (evitar ruido extra al morir)
		if is_instance_valid(enemy):
			AudioManager.play(hit_sfx, -0.1)
	
	# Knockback
	var final_knockback = knockback
	if effect == "knockback_bonus":
		final_knockback *= effect_value
	
	if final_knockback != 0 and enemy.has_method("apply_knockback"):
		var kb_dir = (enemy.global_position - global_position).normalized()
		enemy.apply_knockback(kb_dir * final_knockback)
	
	_apply_orbital_effect(enemy)

func _apply_orbital_effect(enemy: Node) -> void:
	"""Aplicar efectos especiales de orbitales"""
	if effect == "none":
		return
	
	var modified_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_duration)
	var modified_value_as_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_value)
	
	match effect:
		"slow":
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(effect_value, modified_duration)
		"burn":
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(effect_value, modified_duration)
		"freeze":
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(effect_value, modified_duration)
			elif enemy.has_method("apply_slow"):
				enemy.apply_slow(effect_value, modified_duration)
		"stun":
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(modified_value_as_duration)
		"pull":
			if enemy.has_method("apply_pull"):
				enemy.apply_pull(global_position, effect_value, modified_duration)
		"blind":
			if enemy.has_method("apply_blind"):
				enemy.apply_blind(modified_value_as_duration)
		"lifesteal":
			var player = _get_orbital_player()
			if player and player.has_method("heal"):
				var heal_amount = roundi(effect_value)
				player.heal(heal_amount)
				FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
				# FIX-VFXPOOL: Spawn lifesteal VFX from pool (was missing)
				if VFXPool.instance and is_instance_valid(enemy):
					VFXPool.instance.get_lifesteal_particles(enemy.global_position, player.global_position)
		"bleed":
			if enemy.has_method("apply_bleed"):
				enemy.apply_bleed(effect_value, modified_duration)
		"shadow_mark":
			if enemy.has_method("apply_shadow_mark"):
				enemy.apply_shadow_mark(effect_value, modified_duration)
		"chain":
			_apply_chain_damage(enemy, roundi(effect_value))

func _apply_chain_damage(first_target: Node, chain_count: int) -> void:
	"""Aplicar daño encadenado a enemigos cercanos"""
	var enemies_hit = [first_target]
	var current_pos = first_target.global_position
	var chain_reduction = 0.6

	# FIX-R6: Chain hits pasan por DamageCalculator (antes era daño crudo)
	var player = _get_orbital_player()

	for i in range(chain_count):
		var next_target = _find_chain_target(current_pos, enemies_hit)
		if next_target == null:
			break

		var chain_base_damage = orbital_damage * chain_reduction
		var chain_result = DamageCalculator.calculate_final_damage(
			chain_base_damage, next_target, player, crit_chance, crit_damage, self
		)
		DamageCalculator.apply_damage_with_effects(
			get_tree(), next_target, chain_result, Vector2.ZERO, 0.0, self, "physical"
		)

		_spawn_chain_lightning_visual(current_pos, next_target.global_position)

		enemies_hit.append(next_target)
		current_pos = next_target.global_position
		chain_reduction *= 0.8

func _find_chain_target(from_pos: Vector2, exclude: Array) -> Node:
	"""Buscar siguiente objetivo para chain"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node = null
	var closest_dist = 200.0
	
	for enemy in enemies:
		if enemy in exclude or not is_instance_valid(enemy):
			continue
		var dist = from_pos.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist
	
	return closest

func _spawn_chain_lightning_visual(from_pos: Vector2, to_pos: Vector2) -> void:
	"""Crear efecto visual de rayo entre posiciones"""
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.8, 0.6, 1.0, 0.9)
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.z_index = 100
	get_tree().current_scene.add_child(line)
	
	var tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func _get_orbital_player() -> Node:
	"""Obtener referencia al jugador"""
	if not get_tree():
		return null
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _process(delta: float) -> void:
	_rotation_angle += orbital_speed * delta * 0.01

	for i in range(orbitals.size()):
		if not is_instance_valid(orbitals[i]):
			continue

		var angle = _rotation_angle + (TAU / orbitals.size()) * i
		var pos = Vector2(
			cos(angle) * orbital_radius,
			sin(angle) * orbital_radius
		)
		orbitals[i].position = pos

	if _use_enhanced and _enhanced_visual:
		var positions: Array[Vector2] = []
		for orbital in orbitals:
			if is_instance_valid(orbital):
				positions.append(orbital.position)
		_enhanced_visual.update_orbital_positions(positions)
	
	_cleanup_counter += 1
	if _cleanup_counter >= 60:
		_cleanup_counter = 0
		_cleanup_invalid_hit_times()

	# Lógica de disparo activo (Arcane Storm)
	if effect == "chain":
		_active_shooting_timer -= delta
		if _active_shooting_timer <= 0:
			_active_shooting_timer = 0.4  # Cooldown base de disparo
			_fire_active_shot()

func _cleanup_invalid_hit_times() -> void:
	"""Eliminar entradas de enemigos que ya no existen"""
	var keys_to_remove: Array = []
	for enemy_id in _last_hit_times.keys():
		if not is_instance_id_valid(enemy_id):
			keys_to_remove.append(enemy_id)
	for key in keys_to_remove:
		_last_hit_times.erase(key)
# ═══════════════════════════════════════════════════════════════════════════════
# DIAGNÓSTICO Y VALIDACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func validate_collision_setup() -> Dictionary:
	"""
	Validar que la configuración de colisiones sea correcta.
	Retorna un diccionario con el estado de validación.
	Útil para debugging y tests automatizados.
	"""
	var result = {
		"valid": true,
		"orbital_count": orbitals.size(),
		"issues": []
	}
	
	for i in range(orbitals.size()):
		var orbital = orbitals[i]
		if not is_instance_valid(orbital):
			result.issues.append("Orbital %d es inválido" % i)
			result.valid = false
			continue
			
		if not orbital is Area2D:
			result.issues.append("Orbital %d no es Area2D" % i)
			result.valid = false
			continue
		
		# Verificar monitoring
		if not orbital.monitoring:
			result.issues.append("Orbital %d: monitoring=false" % i)
			result.valid = false
		
		# Verificar máscara de colisión (debe incluir layer 2 para enemigos)
		if not orbital.get_collision_mask_value(2):
			result.issues.append("Orbital %d: no tiene mask para layer 2 (enemigos)" % i)
			result.valid = false
		
		# Verificar que tiene CollisionShape2D
		var has_shape = false
		for child in orbital.get_children():
			if child is CollisionShape2D:
				has_shape = true
				if child.disabled:
					result.issues.append("Orbital %d: CollisionShape2D deshabilitado" % i)
					result.valid = false
				elif child.shape == null:
					result.issues.append("Orbital %d: CollisionShape2D sin shape" % i)
					result.valid = false
				break
		
		if not has_shape:
			result.issues.append("Orbital %d: no tiene CollisionShape2D" % i)
			result.valid = false
		
		# Verificar conexión de señales
		if not orbital.body_entered.is_connected(_on_orbital_hit):
			result.issues.append("Orbital %d: body_entered no conectado" % i)
			result.valid = false
	
	if DEBUG_COLLISIONS:
		print("[OrbitalManager] Validación: %s" % ("✓ OK" if result.valid else "✗ FALLÓ"))
		for issue in result.issues:
			print("  - %s" % issue)
	
	return result

func _fire_active_shot() -> void:
	"""Disparar un rayo desde un orbital aleatorio a un enemigo cercano"""
	if orbitals.is_empty():
		return
		
	var shooting_radius = orbital_radius * _shooting_range_mult
	var enemies = get_tree().get_nodes_in_group("enemies")
	var target: Node = null
	var min_dist = shooting_radius
	var source_orbital: Node2D = null
	
	# Buscar el enemigo más cercano a cualquiera de los orbitales
	# O simplificado: más cercano al centro pero dentro de rango extendido
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var dist_to_center = global_position.distance_to(enemy.global_position)
		if dist_to_center <= shooting_radius:
			# Priorizar el más cercano
			if dist_to_center < min_dist:
				min_dist = dist_to_center
				target = enemy
	
	if target:
		# Encontrar el orbital más cercano al objetivo para disparar desde ahí
		var closest_orb_dist = 9999.0
		for orb in orbitals:
			if is_instance_valid(orb):
				var d = orb.global_position.distance_to(target.global_position)
				if d < closest_orb_dist:
					closest_orb_dist = d
					source_orbital = orb
		
		if source_orbital:
			# Disparar rayo
			_spawn_chain_lightning_visual(source_orbital.global_position, target.global_position)
			
			# Aplicar daño (usando effect_value como chain count)
			var chain_count = int(effect_value)
			
			# Daño inicial al target (reutilizamos la lógica de chain que aplica daño al primero)
			# Pero _apply_chain_damage inicia el chain DESDE el target.
			# Así que aplicamos daño al target primero y luego chain.
			
			# Calcular daño (quizás un poco menos que el contacto directo?)
			# Usamos el daño base del orbital
			
			# Registrar y aplicar
			DamageLogger.log_orbital_damage(orbital_weapon_id, target.name, int(orbital_damage), {"type": "lightning"})
			
			if target.has_method("take_damage"):
				# Calcular daño completo
				var player = _get_orbital_player()
				var damage_res = DamageCalculator.calculate_final_damage(orbital_damage, target, player, crit_chance, crit_damage, self)
				
				target.take_damage(damage_res.get_int_damage(), "physical", self)
				ProjectileFactory.apply_life_steal(get_tree(), damage_res.final_damage)
				
				# Chain a otros
				_apply_chain_damage(target, chain_count)
			
			# Agregar un pequeño efecto de impacto visual si se quiere
