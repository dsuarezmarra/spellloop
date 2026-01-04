# EnemyAttackSystem.gd
# Sistema de ataque para enemigos - Soporta todos los arquetipos
# Gestiona cooldowns, targeting y ejecución de ataques

extends Node
class_name EnemyAttackSystem

signal attacked_player(damage: int, is_melee: bool)

# Propiedades de ataque
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0
var attack_range: float = 32.0
var attack_damage: int = 5
var is_ranged: bool = false
var projectile_scene: PackedScene = null
var projectile_speed: float = 200.0

# Propiedades de ataque especial
var archetype: String = "melee"
var element_type: String = "physical"
var special_abilities: Array = []
var modifiers: Dictionary = {}

# AoE
var aoe_radius: float = 100.0
var aoe_damage_multiplier: float = 0.7

# Breath
var breath_cone_angle: float = 45.0  # grados
var breath_range: float = 150.0

# Multi-attack
var multi_attack_count: int = 3

# Referencias
var enemy: Node = null
var player: Node = null

# Referencia a EnemyProjectile script
var EnemyProjectileScript = null

func _ready() -> void:
	enemy = get_parent()
	# Precargar script de proyectil
	EnemyProjectileScript = load("res://scripts/enemies/EnemyProjectile.gd")
	print("[EnemyAttackSystem] Inicializado para: %s" % enemy.name)

func initialize(p_attack_cooldown: float, p_attack_range: float, p_damage: int, p_is_ranged: bool = false, p_projectile_scene: PackedScene = null) -> void:
	"""Configurar parámetros de ataque"""
	attack_cooldown = p_attack_cooldown
	attack_range = p_attack_range
	attack_damage = p_damage
	is_ranged = p_is_ranged
	projectile_scene = p_projectile_scene
	print("[EnemyAttackSystem] Configurado: cooldown=%.2f, range=%.0f, damage=%d, ranged=%s" % [attack_cooldown, attack_range, attack_damage, is_ranged])

func initialize_full(config: Dictionary) -> void:
	"""Inicialización completa con todos los parámetros"""
	attack_cooldown = config.get("attack_cooldown", 1.5)
	attack_range = config.get("attack_range", 32.0)
	attack_damage = config.get("damage", 5)
	is_ranged = config.get("is_ranged", false)
	archetype = config.get("archetype", "melee")
	element_type = config.get("element_type", "physical")
	special_abilities = config.get("special_abilities", [])
	modifiers = config.get("modifiers", {})
	
	# Configurar según arquetipo
	match archetype:
		"aoe":
			aoe_radius = modifiers.get("aoe_radius", 100.0)
			aoe_damage_multiplier = modifiers.get("aoe_damage_mult", 0.7)
		"breath":
			breath_cone_angle = modifiers.get("breath_angle", 45.0)
			breath_range = modifiers.get("breath_range", 150.0)
		"multi":
			multi_attack_count = modifiers.get("attack_count", 3)
	
	print("[EnemyAttackSystem] Full config: %s (arch=%s, elem=%s)" % [enemy.name, archetype, element_type])

func _process(delta: float) -> void:
	"""Procesar cooldown y ataque automático"""
	if not enemy or not is_instance_valid(enemy):
		return
	
	# Obtener player si no lo tiene
	if not player or not is_instance_valid(player):
		player = _get_player()
		if not player:
			# Solo debug una vez cada 60 frames para no saturar
			if Engine.get_process_frames() % 60 == 0:
				print("[EnemyAttackSystem] ⚠️ No se encontró player para %s" % enemy.name)
			return
	
	# Decrementar cooldown
	if attack_timer > 0:
		attack_timer -= delta
	else:
		# Comprobar si el jugador está en rango
		if _player_in_range():
			_perform_attack()
			attack_timer = attack_cooldown

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	# Método 1: Desde el enemigo padre (más directo y fiable)
	if enemy and enemy.has_method("get") and enemy.get("player_ref"):
		return enemy.player_ref
	
	# Método 2: Buscar en GameManager
	if GameManager and GameManager.player_ref:
		return GameManager.player_ref
	
	# Método 3: Buscar por grupos
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Método 4: Buscar en la estructura del árbol
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		# Buscar Game/PlayerContainer/SpellloopPlayer
		var sp = tree.root.get_node_or_null("Game/PlayerContainer/SpellloopPlayer")
		if sp:
			return sp
	
	return null

func _player_in_range() -> bool:
	"""Comprobar si el jugador está dentro del rango de ataque"""
	if not enemy or not player:
		return false
	
	var distance = enemy.global_position.distance_to(player.global_position)
	var in_range = distance <= attack_range
	
	# Debug ocasional (cada 2 segundos aprox) para ver distancias
	#if Engine.get_process_frames() % 120 == 0:
	#	print("[EnemyAttackSystem] %s: dist=%.1f, range=%.1f, in_range=%s" % [enemy.name, distance, attack_range, in_range])
	
	return in_range

func _perform_attack() -> void:
	"""Ejecutar el ataque según arquetipo"""
	if not enemy or not player:
		return
	
	# Obtener arquetipo del enemigo padre si existe
	if enemy.has_method("get") and "archetype" in enemy:
		archetype = enemy.archetype
	if enemy.has_method("get") and "modifiers" in enemy:
		modifiers = enemy.modifiers
	if enemy.has_method("get") and "special_abilities" in enemy:
		special_abilities = enemy.special_abilities
	
	# Ejecutar ataque según arquetipo
	match archetype:
		"ranged":
			_perform_ranged_attack()
		"aoe":
			_perform_aoe_attack()
		"breath":
			_perform_breath_attack()
		"multi":
			_perform_multi_attack()
		"teleporter":
			_perform_ranged_attack()  # Los teleporters también disparan
		"boss":
			_perform_boss_attack()
		_:
			# Melee por defecto
			if is_ranged:
				_perform_ranged_attack()
			else:
				_perform_melee_attack()

func _perform_melee_attack() -> void:
	"""Ataque melee: daño directo al jugador"""
	if not player.has_method("take_damage"):
		return
	
	player.take_damage(attack_damage)
	print("[EnemyAttackSystem] ⚔️ %s atacó melee a player por %d daño" % [enemy.name, attack_damage])
	
	# Emitir señal
	attacked_player.emit(attack_damage, true)
	
	# Efecto visual
	_emit_melee_effect()

func _perform_ranged_attack() -> void:
	"""Ataque ranged: disparar proyectil al jugador"""
	# Crear proyectil dinámicamente si no hay escena
	if not projectile_scene and EnemyProjectileScript:
		_create_dynamic_projectile()
		return
	
	if not projectile_scene:
		print("[EnemyAttackSystem] Warning: %s no tiene projectile_scene ni script" % enemy.name)
		# Fallback a melee
		_perform_melee_attack()
		return
	
	var projectile = projectile_scene.instantiate()
	if not projectile:
		return
	
	# Posicionar en enemigo
	projectile.global_position = enemy.global_position
	
	# Calcular dirección hacia jugador
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Configurar proyectil
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, element_type)
	else:
		# Asignación directa
		if "direction" in projectile:
			projectile.direction = direction
		if "speed" in projectile:
			projectile.speed = projectile_speed
		if "damage" in projectile:
			projectile.damage = attack_damage
	
	# Añadir al árbol
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	print("[EnemyAttackSystem] 🎯 %s disparó proyectil hacia player" % enemy.name)
	attacked_player.emit(attack_damage, false)

func _create_dynamic_projectile() -> void:
	"""Crear proyectil dinámico usando EnemyProjectile.gd"""
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position
	
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Determinar elemento según enemigo
	var elem = _get_enemy_element()
	
	# Añadir al árbol ANTES de initialize (necesario para _ready)
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	# Inicializar
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, elem)
	
	print("[EnemyAttackSystem] 🎯 %s disparó proyectil dinámico (%s)" % [enemy.name, elem])
	attacked_player.emit(attack_damage, false)

func _perform_aoe_attack() -> void:
	"""Ataque de área: daño en zona alrededor del enemigo o player"""
	if not player:
		return
	
	# Posición del AoE (en el player o en el enemigo)
	var aoe_center = player.global_position
	var radius = modifiers.get("aoe_radius", 100.0)
	var aoe_damage = int(attack_damage * modifiers.get("aoe_damage_mult", 1.0))
	
	# Verificar si player está en rango del AoE
	var dist_to_player = aoe_center.distance_to(player.global_position)
	if dist_to_player <= radius:
		if player.has_method("take_damage"):
			player.take_damage(aoe_damage)
			print("[EnemyAttackSystem] 💥 %s AoE hit player por %d daño (radio=%.0f)" % [enemy.name, aoe_damage, radius])
			attacked_player.emit(aoe_damage, false)
	
	# Efecto visual del AoE
	_spawn_aoe_visual(enemy.global_position, radius)

func _perform_breath_attack() -> void:
	"""Ataque de aliento: daño en cono hacia el player"""
	if not player:
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var cone_angle = deg_to_rad(modifiers.get("breath_angle", 45.0))
	var cone_range = modifiers.get("breath_range", 150.0)
	var breath_damage = int(attack_damage * modifiers.get("breath_damage_mult", 1.2))
	
	# Verificar si player está en el cono
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var angle_to_player = direction.angle_to(to_player.normalized())
	
	if dist <= cone_range and abs(angle_to_player) <= cone_angle / 2:
		if player.has_method("take_damage"):
			player.take_damage(breath_damage)
			print("[EnemyAttackSystem] 🐉 %s Breath hit player por %d daño" % [enemy.name, breath_damage])
			attacked_player.emit(breath_damage, false)
	
	# Efecto visual del breath
	_spawn_breath_visual(enemy.global_position, direction, cone_range)

func _perform_multi_attack() -> void:
	"""Ataque múltiple: varios proyectiles o ataques en secuencia"""
	var count = modifiers.get("attack_count", 3)
	var spread_angle = deg_to_rad(modifiers.get("spread_angle", 30.0))
	var base_direction = (player.global_position - enemy.global_position).normalized()
	
	for i in range(count):
		# Calcular ángulo para este proyectil
		var angle_offset = spread_angle * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var direction = base_direction.rotated(angle_offset)
		
		# Crear proyectil con delay visual
		_spawn_multi_projectile(direction, i * 0.1)
	
	print("[EnemyAttackSystem] 🔥 %s Multi-attack: %d proyectiles" % [enemy.name, count])
	attacked_player.emit(attack_damage, false)

func _perform_boss_attack() -> void:
	"""Ataque de boss: combina varios tipos según habilidades"""
	# Bosses tienen ataques variados basados en sus habilidades
	
	# Elegir ataque basado en habilidades disponibles y azar
	var attack_roll = randf()
	
	# El Conjurador Primigenio - ranged_attack, summon
	if "ranged_attack" in special_abilities:
		if attack_roll < 0.6:
			_perform_multi_attack()
			print("[EnemyAttackSystem] 👹 %s (Boss) multi-attack!" % enemy.name)
			return
	
	# El Corazón del Vacío - void_explosion, damage_aura
	if "void_explosion" in special_abilities:
		if attack_roll < 0.5:
			_perform_boss_void_explosion()
			return
	
	# El Guardián de Runas - rune_blast
	if "rune_blast" in special_abilities:
		if attack_roll < 0.5:
			_perform_boss_rune_blast()
			return
	
	# Minotauro de Fuego - fire_stomp, charge_attack
	if "fire_stomp" in special_abilities:
		if attack_roll < 0.4:
			_perform_boss_fire_stomp()
			return
	
	# Si tiene AoE general
	if "aoe_attack" in special_abilities:
		_perform_aoe_attack()
		return
	
	# Default para bosses: ataque melee poderoso con efecto visual especial
	_perform_boss_melee_attack()

func _perform_boss_melee_attack() -> void:
	"""Ataque melee especial de boss con efecto visual grande"""
	if not player or not player.has_method("take_damage"):
		return
	
	var boss_damage = int(attack_damage * 1.2)  # Bosses hacen más daño
	player.take_damage(boss_damage)
	print("[EnemyAttackSystem] 👹 %s (Boss) melee devastador por %d daño" % [enemy.name, boss_damage])
	
	attacked_player.emit(boss_damage, true)
	
	# Efecto visual de impacto de boss (más grande)
	_spawn_boss_impact_effect()

func _perform_boss_void_explosion() -> void:
	"""El Corazón del Vacío - explosión de vacío"""
	if not player:
		return
	
	var explosion_radius = modifiers.get("explosion_radius", 150.0)
	var explosion_damage = modifiers.get("explosion_damage", 60)
	
	# Verificar si player está en rango
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= explosion_radius:
		if player.has_method("take_damage"):
			player.take_damage(explosion_damage)
			print("[EnemyAttackSystem] 💜 %s Void Explosion por %d daño!" % [enemy.name, explosion_damage])
			attacked_player.emit(explosion_damage, false)
	
	# Visual de explosión de vacío
	_spawn_void_explosion_visual(enemy.global_position, explosion_radius)

func _perform_boss_rune_blast() -> void:
	"""El Guardián de Runas - explosión de runas"""
	if not player:
		return
	
	var blast_radius = modifiers.get("blast_radius", 100.0)
	var blast_damage = modifiers.get("blast_damage", 45)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= blast_radius:
		if player.has_method("take_damage"):
			player.take_damage(blast_damage)
			print("[EnemyAttackSystem] ✨ %s Rune Blast por %d daño!" % [enemy.name, blast_damage])
			attacked_player.emit(blast_damage, false)
	
	# Visual de runas
	_spawn_rune_blast_visual(enemy.global_position, blast_radius)

func _perform_boss_fire_stomp() -> void:
	"""Minotauro de Fuego - pisotón de fuego"""
	if not player:
		return
	
	var stomp_radius = modifiers.get("stomp_radius", 120.0)
	var stomp_damage = modifiers.get("stomp_damage", 50)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= stomp_radius:
		if player.has_method("take_damage"):
			player.take_damage(stomp_damage)
			print("[EnemyAttackSystem] 🔥 %s Fire Stomp por %d daño!" % [enemy.name, stomp_damage])
			attacked_player.emit(stomp_damage, false)
	
	# Visual de pisotón de fuego
	_spawn_fire_stomp_visual(enemy.global_position, stomp_radius)

func _spawn_boss_impact_effect() -> void:
	"""Efecto de impacto de ataque de boss"""
	if not enemy or not player:
		return
	
	var impact_pos = player.global_position
	var effect = Node2D.new()
	effect.global_position = impact_pos
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# Impacto masivo
		var radius = 50 * anim_progress
		
		# Ondas de choque
		for i in range(3):
			var wave_radius = radius * (1.0 + i * 0.3)
			var wave_alpha = (1.0 - anim_progress) * (0.6 - i * 0.15)
			visual.draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 32, Color(color.r, color.g, color.b, wave_alpha), 4.0 - i)
		
		# Cruz de impacto
		var cross_size = radius * 1.5
		var cross_alpha = (1.0 - anim_progress) * 0.7
		visual.draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color(1, 1, 1, cross_alpha), 3.0)
		visual.draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color(1, 1, 1, cross_alpha), 3.0)
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_void_explosion_visual(center: Vector2, radius: float) -> void:
	"""Visual de explosión de vacío - púrpura con absorción"""
	var effect = Node2D.new()
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# Explosión inversa (desde fuera hacia dentro, luego explota)
		var phase = anim_progress
		
		if phase < 0.4:
			# Fase de absorción
			var absorb_phase = phase / 0.4
			var absorb_radius = radius * (1.0 - absorb_phase * 0.7)
			visual.draw_circle(Vector2.ZERO, absorb_radius, Color(0.5, 0.1, 0.8, 0.4 * absorb_phase))
			
			# Partículas siendo absorbidas
			var particle_count = 12
			for i in range(particle_count):
				var angle = (TAU / particle_count) * i + phase * PI
				var dist = absorb_radius * (1.2 - absorb_phase * 0.5)
				var pos = Vector2(cos(angle), sin(angle)) * dist
				visual.draw_circle(pos, 4, Color(0.8, 0.3, 1.0, 0.8))
		else:
			# Fase de explosión
			var explode_phase = (phase - 0.4) / 0.6
			var explode_radius = radius * explode_phase
			
			# Ondas de vacío
			for i in range(4):
				var wave_r = explode_radius * (0.3 + i * 0.2)
				var wave_alpha = (1.0 - explode_phase) * (0.5 - i * 0.1)
				visual.draw_arc(Vector2.ZERO, wave_r, 0, TAU, 32, Color(0.6, 0.15, 0.9, wave_alpha), 3.0)
			
			# Centro oscuro
			visual.draw_circle(Vector2.ZERO, 20 * (1.0 - explode_phase), Color(0.2, 0, 0.3, 0.8))
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.6)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_rune_blast_visual(center: Vector2, radius: float) -> void:
	"""Visual de explosión de runas - símbolos brillantes"""
	var effect = Node2D.new()
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var rune_count = 6
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		var expand = radius * anim_progress
		
		# Círculo central de runas
		visual.draw_arc(Vector2.ZERO, expand * 0.5, 0, TAU, 32, Color(0.9, 0.8, 0.2, 0.6 * (1.0 - anim_progress)), 2.0)
		
		# Runas individuales que se expanden
		for i in range(rune_count):
			var angle = (TAU / rune_count) * i + anim_progress * PI * 0.5
			var dist = expand * (0.5 + anim_progress * 0.5)
			var pos = Vector2(cos(angle), sin(angle)) * dist
			
			# Dibujar runa como forma geométrica
			var rune_size = 10 * (1.0 - anim_progress * 0.5)
			var rune_points = PackedVector2Array([
				pos + Vector2(0, -rune_size),
				pos + Vector2(rune_size * 0.7, rune_size * 0.5),
				pos + Vector2(-rune_size * 0.7, rune_size * 0.5)
			])
			visual.draw_colored_polygon(rune_points, Color(1, 0.9, 0.3, 0.8 * (1.0 - anim_progress)))
			
			# Brillo alrededor
			visual.draw_circle(pos, rune_size * 1.5, Color(1, 1, 0.5, 0.3 * (1.0 - anim_progress)))
		
		# Onda de expansión final
		visual.draw_arc(Vector2.ZERO, expand, 0, TAU, 48, Color(1, 1, 1, 0.5 * (1.0 - anim_progress)), 3.0)
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_fire_stomp_visual(center: Vector2, radius: float) -> void:
	"""Visual de pisotón de fuego - onda de fuego expansiva"""
	var effect = Node2D.new()
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		var expand = radius * anim_progress
		
		# Cráter central
		visual.draw_circle(Vector2.ZERO, expand * 0.3, Color(0.3, 0.1, 0, 0.7 * (1.0 - anim_progress)))
		
		# Anillos de fuego
		for i in range(4):
			var ring_r = expand * (0.4 + i * 0.2)
			var ring_alpha = (1.0 - anim_progress) * (0.7 - i * 0.15)
			var ring_color = Color(1.0 - i * 0.1, 0.4 - i * 0.1, 0.05, ring_alpha)
			visual.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32, ring_color, 4.0 - i)
		
		# Llamas alrededor
		var flame_count = 12
		for i in range(flame_count):
			var angle = (TAU / flame_count) * i
			var flame_dist = expand * 0.8
			var flame_base = Vector2(cos(angle), sin(angle)) * flame_dist
			
			# Altura de llama animada
			var flame_height = 15 * (1.0 - anim_progress) * (0.8 + sin(anim_progress * PI * 4 + i) * 0.2)
			var flame_width = 6
			
			var flame_tip = flame_base + Vector2(0, -flame_height)
			var flame_left = flame_base + Vector2(-flame_width, 0)
			var flame_right = flame_base + Vector2(flame_width, 0)
			
			visual.draw_colored_polygon(
				PackedVector2Array([flame_tip, flame_left, flame_right]),
				Color(1, 0.5, 0.1, 0.8 * (1.0 - anim_progress))
			)
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_multi_projectile(direction: Vector2, delay: float) -> void:
	"""Crear un proyectil del multi-attack con delay"""
	if delay > 0:
		get_tree().create_timer(delay).timeout.connect(func(): _create_single_projectile(direction))
	else:
		_create_single_projectile(direction)

func _create_single_projectile(direction: Vector2) -> void:
	"""Crear un único proyectil"""
	if not EnemyProjectileScript or not is_instance_valid(enemy):
		return
	
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position
	
	var elem = _get_enemy_element()
	var proj_damage = int(attack_damage * 0.7)  # Multi tiene menos daño por proyectil
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, proj_damage, 5.0, elem)

func _get_enemy_element() -> String:
	"""Obtener elemento del enemigo basado en su ID o archetype"""
	if not enemy:
		return "physical"
	
	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""
	var name_lower = enemy_id.to_lower()
	
	if "fuego" in name_lower or "llamas" in name_lower or "fire" in name_lower:
		return "fire"
	if "hielo" in name_lower or "ice" in name_lower or "frost" in name_lower or "cristal" in name_lower:
		return "ice"
	if "void" in name_lower or "vacio" in name_lower or "shadow" in name_lower or "sombra" in name_lower:
		return "dark"
	if "arcano" in name_lower or "arcane" in name_lower or "mago" in name_lower:
		return "arcane"
	if "veneno" in name_lower or "poison" in name_lower:
		return "poison"
	if "rayo" in name_lower or "lightning" in name_lower or "thunder" in name_lower:
		return "lightning"
	
	return "physical"

func _spawn_aoe_visual(center: Vector2, radius: float) -> void:
	"""Crear efecto visual de AoE mejorado con animación de expansión"""
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(base_color.r + 0.3, base_color.g + 0.3, base_color.b + 0.3, 0.9)
	
	# Crear contenedor principal
	var container = Node2D.new()
	container.name = "AoE_Visual"
	container.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)
	
	# Variables de animación
	var anim_progress = 0.0
	var ring_count = 3
	
	# Nodo visual para dibujar
	var visual = Node2D.new()
	container.add_child(visual)
	
	visual.draw.connect(func():
		# Círculo de impacto central que se expande
		var expand_radius = radius * anim_progress
		
		# Círculo exterior con gradiente simulado (múltiples capas)
		for i in range(5):
			var layer_radius = expand_radius * (1.0 - i * 0.15)
			var layer_alpha = (0.4 - i * 0.08) * (1.0 - anim_progress * 0.5)
			if layer_radius > 0:
				visual.draw_circle(Vector2.ZERO, layer_radius, Color(base_color.r, base_color.g, base_color.b, layer_alpha))
		
		# Anillos de onda expansiva
		for i in range(ring_count):
			var ring_phase = fmod(anim_progress * 2 + i * 0.3, 1.0)
			var ring_radius = radius * ring_phase
			var ring_alpha = (1.0 - ring_phase) * 0.8
			if ring_radius > 0:
				visual.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(bright_color.r, bright_color.g, bright_color.b, ring_alpha), 2.0)
		
		# Partículas decorativas alrededor
		var particle_count = 8
		for i in range(particle_count):
			var angle = (TAU / particle_count) * i + anim_progress * PI
			var dist = expand_radius * 0.8
			var particle_pos = Vector2(cos(angle), sin(angle)) * dist
			var particle_size = 3.0 + sin(anim_progress * PI * 4 + i) * 2.0
			visual.draw_circle(particle_pos, particle_size, bright_color)
		
		# Borde exterior final
		if expand_radius > 0:
			visual.draw_arc(Vector2.ZERO, expand_radius, 0, TAU, 48, Color(1, 1, 1, 0.6 * (1.0 - anim_progress)), 3.0)
	)
	
	# Animación de expansión
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	
	# Fade out y destruir
	tween.tween_property(container, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _spawn_breath_visual(origin: Vector2, direction: Vector2, range_dist: float) -> void:
	"""Crear efecto visual de breath attack mejorado con animación de expansión"""
	var container = Node2D.new()
	container.name = "Breath_Visual"
	container.global_position = origin
	container.rotation = direction.angle()
	
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(base_color.r + 0.4, base_color.g + 0.4, base_color.b + 0.2, 0.9)
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	container.add_child(visual)
	
	visual.draw.connect(func():
		var current_range = range_dist * anim_progress
		var cone_width = 0.35  # Ancho del cono (porcentaje del rango)
		
		if current_range < 5:
			return
		
		# Múltiples capas del cono para efecto de gradiente
		for i in range(5):
			var layer_mult = 1.0 - i * 0.15
			var layer_range = current_range * layer_mult
			var layer_width = cone_width * (1.0 + i * 0.1)
			var layer_alpha = (0.5 - i * 0.08) * (1.0 - anim_progress * 0.3)
			
			var cone_points = PackedVector2Array([
				Vector2.ZERO,
				Vector2(layer_range, -layer_range * layer_width),
				Vector2(layer_range * 1.1, 0),
				Vector2(layer_range, layer_range * layer_width)
			])
			visual.draw_colored_polygon(cone_points, Color(base_color.r, base_color.g, base_color.b, layer_alpha))
		
		# Núcleo brillante central
		var core_points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(current_range * 0.9, -current_range * cone_width * 0.3),
			Vector2(current_range * 0.95, 0),
			Vector2(current_range * 0.9, current_range * cone_width * 0.3)
		])
		visual.draw_colored_polygon(core_points, Color(bright_color.r, bright_color.g, bright_color.b, 0.7))
		
		# Partículas a lo largo del breath
		var particle_count = int(8 * anim_progress)
		for i in range(particle_count):
			var t = float(i) / max(particle_count, 1)
			var particle_dist = current_range * t
			var wobble = sin(anim_progress * PI * 4 + i * 0.8) * cone_width * particle_dist * 0.3
			var particle_pos = Vector2(particle_dist, wobble)
			var particle_size = 4.0 * (1.0 - t * 0.5)
			visual.draw_circle(particle_pos, particle_size, bright_color)
		
		# Borde brillante del cono
		visual.draw_line(Vector2.ZERO, Vector2(current_range, -current_range * cone_width), Color(1, 1, 1, 0.5), 2.0)
		visual.draw_line(Vector2.ZERO, Vector2(current_range, current_range * cone_width), Color(1, 1, 1, 0.5), 2.0)
	)
	
	# Animación de expansión rápida
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.3)
	
	# Mantener un momento y fade out
	tween.tween_interval(0.15)
	tween.tween_property(container, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _get_element_color(elem: String) -> Color:
	"""Obtener color según elemento - Colores más vibrantes y atractivos"""
	match elem:
		"fire": return Color(1.0, 0.3, 0.05, 0.8)      # Rojo fuego brillante
		"ice": return Color(0.2, 0.7, 1.0, 0.8)        # Azul hielo claro
		"dark": return Color(0.6, 0.1, 0.9, 0.8)       # Púrpura oscuro
		"arcane": return Color(0.9, 0.3, 1.0, 0.8)     # Magenta arcano
		"poison": return Color(0.2, 0.9, 0.2, 0.8)     # Verde venenoso
		"lightning": return Color(1.0, 1.0, 0.2, 0.8)  # Amarillo eléctrico
		_: return Color(0.9, 0.9, 0.9, 0.8)            # Blanco físico

func _emit_melee_effect() -> void:
	"""Emitir efecto visual de ataque melee con slash animado"""
	if not enemy or not player:
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var slash_pos = enemy.global_position + direction * 25
	
	# Crear visual de slash
	var slash = Node2D.new()
	slash.name = "MeleeSlash"
	slash.global_position = slash_pos
	slash.rotation = direction.angle()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(slash)
	
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var anim_progress = 0.0
	
	var visual = Node2D.new()
	slash.add_child(visual)
	
	visual.draw.connect(func():
		var arc_angle = PI * 0.7  # Ángulo del arco de slash
		var arc_radius = 30.0 * (0.5 + anim_progress * 0.5)
		var arc_start = -arc_angle / 2 + (1.0 - anim_progress) * arc_angle * 0.3
		var arc_end = arc_angle / 2 - (1.0 - anim_progress) * arc_angle * 0.3
		
		# Múltiples arcos para efecto de estela
		for i in range(4):
			var layer_radius = arc_radius * (1.0 - i * 0.15)
			var layer_alpha = (0.9 - i * 0.2) * (1.0 - anim_progress * 0.7)
			var layer_width = (5.0 - i * 1.0) * (1.0 - anim_progress * 0.5)
			if layer_width > 0:
				visual.draw_arc(Vector2.ZERO, layer_radius, arc_start, arc_end, 16, Color(base_color.r, base_color.g, base_color.b, layer_alpha), layer_width)
		
		# Destello en el borde del slash
		var flash_pos = Vector2(cos(arc_end), sin(arc_end)) * arc_radius
		var flash_size = 6.0 * (1.0 - anim_progress)
		visual.draw_circle(flash_pos, flash_size, Color(1, 1, 1, 0.8 * (1.0 - anim_progress)))
		
		# Chispas
		var spark_count = 4
		for i in range(spark_count):
			var spark_angle = arc_start + (arc_end - arc_start) * (float(i) / spark_count)
			var spark_dist = arc_radius * (0.7 + anim_progress * 0.5)
			var spark_pos = Vector2(cos(spark_angle), sin(spark_angle)) * spark_dist
			var spark_size = 2.0 * (1.0 - anim_progress)
			visual.draw_circle(spark_pos, spark_size, Color(1, 1, 0.8, 0.7 * (1.0 - anim_progress)))
	)
	
	# Animación rápida
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.15)
	
	tween.tween_callback(func():
		if is_instance_valid(slash):
			slash.queue_free()
	)

func _get_particle_manager() -> Node:
	"""Obtener ParticleManager"""
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		return tree.root.get_node_or_null("ParticleManager")
	return null

func set_attack_enabled(enabled: bool) -> void:
	"""Habilitar/deshabilitar ataques"""
	set_process(enabled)

func reset_cooldown() -> void:
	"""Resetear el cooldown de ataque"""
	attack_timer = attack_cooldown
