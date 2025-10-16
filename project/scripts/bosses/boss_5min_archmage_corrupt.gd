extends Node2D
# Boss: Archimago Corrupto
# Aparece en el minuto 5 - Boss con 3 fases

@export var enemy_name = "Archimago Corrupto"
@export var slug = "boss_5min_archmage_corrupt"
@export var difficulty_tier = 1
@export var base_hp = 500
@export var base_speed = 30.0
@export var base_damage = 15
@export var xp_drop = 50
@export var size_px = 128
@export var collider_radius = 45.0
@export var attack_type = "caster"
@export var attack_rate = 1.0
@export var sprite_path = "res://assets/sprites/bosses/boss_5min_archmage_corrupt.png"

# Variables del boss
var current_hp: int
var max_hp: int
var player_reference: Node
var scale_manager: Node
var current_phase: int = 1
var phase_timer: float = 0.0
var attack_timer: float = 0.0
var special_timer: float = 0.0
var minions_spawned: bool = false

# Señales
signal boss_defeated(boss_name)
signal phase_changed(new_phase)

func _ready():
	if has_node("Sprite"):
		$Sprite.texture = load(sprite_path)
		scale = Vector2(2.0, 2.0)  # Bosses son más grandes
	
	scale_manager = get_node("/root/ScaleManager")
	player_reference = get_tree().get_first_node_in_group("player")
	max_hp = calculate_scaled_hp()
	current_hp = max_hp
	
	if has_node("CollisionShape2D"):
		var shape = CircleShape2D.new()
		shape.radius = collider_radius * scale_manager.current_scale
		$CollisionShape2D.shape = shape
	
	# Anunciar aparición del boss
	announce_boss_spawn()

func _physics_process(delta):
	if not player_reference:
		return
	
	update_phase()
	handle_movement(delta)
	handle_attacks(delta)
	handle_special_abilities(delta)

func update_phase():
	var hp_percentage = float(current_hp) / float(max_hp)
	var new_phase = current_phase
	
	if hp_percentage <= 0.33:
		new_phase = 3
	elif hp_percentage <= 0.66:
		new_phase = 2
	else:
		new_phase = 1
	
	if new_phase != current_phase:
		current_phase = new_phase
		emit_signal("phase_changed", current_phase)
		on_phase_change()

func on_phase_change():
	# Efectos visuales de cambio de fase
	modulate = Color.CYAN
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	# Resetear timers
	special_timer = 0.0
	minions_spawned = false
	
	match current_phase:
		2:
			base_speed *= 1.3  # Más rápido en fase 2
			attack_rate *= 0.8  # Ataca más frecuentemente
		3:
			base_speed *= 1.5  # Muy rápido en fase 3
			attack_rate *= 0.6  # Ataques muy frecuentes

func handle_movement(delta):
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	var ideal_distance = 200.0 * scale_manager.current_scale
	var scaled_speed = base_speed * scale_manager.current_scale
	
	match current_phase:
		1:
			# Fase 1: Mantener distancia, movimiento lento
			if distance_to_player < ideal_distance:
				var direction = (global_position - player_reference.global_position).normalized()
				global_position += direction * scaled_speed * delta
			elif distance_to_player > ideal_distance * 1.5:
				var direction = (player_reference.global_position - global_position).normalized()
				global_position += direction * scaled_speed * 0.7 * delta
		
		2:
			# Fase 2: Movimiento circular alrededor del jugador
			phase_timer += delta
			var angle = phase_timer * 2.0  # Velocidad de rotación
			var circle_center = player_reference.global_position
			var target_pos = circle_center + Vector2(cos(angle), sin(angle)) * ideal_distance
			var direction = (target_pos - global_position).normalized()
			global_position += direction * scaled_speed * delta
		
		3:
			# Fase 3: Movimiento errático y teletransporte
			phase_timer += delta
			if phase_timer >= 3.0:  # Teletransporte cada 3 segundos
				teleport_to_random_position()
				phase_timer = 0.0
			else:
				# Movimiento errático
				var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				global_position += random_direction * scaled_speed * delta

func handle_attacks(delta):
	attack_timer -= delta
	if attack_timer <= 0.0:
		match current_phase:
			1:
				fire_basic_projectile()
			2:
				fire_projectile_burst()
			3:
				fire_chaos_spell()
		
		attack_timer = attack_rate

func fire_basic_projectile():
	var projectile_scene = preload("res://scenes/bosses/BossProjectile.tscn")
	if projectile_scene:
		var projectile = projectile_scene.instance()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		var direction = (player_reference.global_position - global_position).normalized()
		projectile.setup(direction, calculate_scaled_damage(), 250.0, "fire")

func fire_projectile_burst():
	# Dispara 5 proyectiles en abanico
	for i in range(5):
		var projectile_scene = preload("res://scenes/bosses/BossProjectile.tscn")
		if projectile_scene:
			var projectile = projectile_scene.instance()
			get_parent().add_child(projectile)
			projectile.global_position = global_position
			
			var base_direction = (player_reference.global_position - global_position).normalized()
			var angle_offset = (i - 2) * 0.3  # Ángulos de -0.6 a 0.6 radianes
			var direction = base_direction.rotated(angle_offset)
			projectile.setup(direction, calculate_scaled_damage(), 300.0, "ice")

func fire_chaos_spell():
	# Proyectil que cambia el terreno
	var chaos_scene = preload("res://scenes/bosses/ChaosProjectile.tscn")
	if chaos_scene:
		var chaos_proj = chaos_scene.instance()
		get_parent().add_child(chaos_proj)
		chaos_proj.global_position = global_position
		var direction = (player_reference.global_position - global_position).normalized()
		chaos_proj.setup(direction, calculate_scaled_damage() * 1.5, 200.0, "chaos")

func handle_special_abilities(delta):
	special_timer += delta
	
	match current_phase:
		1:
			# Invocar minions cada 8 segundos
			if special_timer >= 8.0 and not minions_spawned:
				spawn_minions()
				minions_spawned = true
				special_timer = 0.0
		
		2:
			# Crear barrera mágica cada 6 segundos
			if special_timer >= 6.0:
				create_magic_barrier()
				special_timer = 0.0
		
		3:
			# Alterar terreno cada 4 segundos
			if special_timer >= 4.0:
				alter_terrain()
				special_timer = 0.0

func spawn_minions():
	# Spawea 3 esqueletos menores alrededor del boss
	for i in range(3):
		var minion_scene = preload("res://scripts/enemies/enemy_tier_1_skeleton_warrior.gd")
		if minion_scene:
			var minion = Node2D.new()
			minion.set_script(minion_scene)
			get_parent().add_child(minion)
			var angle = (i * 2 * PI) / 3.0  # Distribuir en círculo
			var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * 100.0
			minion._on_spawn(spawn_pos)

func create_magic_barrier():
	# Crear barrera temporal que reduce daño recibido
	modulate = Color.BLUE
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 2.0)
	# Efecto de barrera se implementaría en take_damage()

func alter_terrain():
	# Crear zona de daño en el suelo
	var terrain_scene = preload("res://scenes/bosses/TerrainDamage.tscn")
	if terrain_scene:
		var terrain = terrain_scene.instance()
		get_parent().add_child(terrain)
		terrain.global_position = player_reference.global_position
		terrain.setup(5.0, calculate_scaled_damage() / 2)  # 5 segundos de duración

func teleport_to_random_position():
	# Teletransporte a posición aleatoria cerca del jugador
	var angle = randf() * 2 * PI
	var distance = randf_range(150.0, 300.0) * scale_manager.current_scale
	global_position = player_reference.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Efecto visual de teletransporte
	modulate = Color.PURPLE
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func take_damage(amount: int):
	# Reducir daño en fase 2 por barrera
	if current_phase == 2 and modulate == Color.BLUE:
		amount = int(amount * 0.5)
	
	current_hp -= amount
	
	# Efecto visual de daño
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_hp <= 0:
		_on_death()

func _on_death():
	emit_signal("boss_defeated", name)
	drop_boss_rewards()
	
	# Efecto de muerte épico
	var death_effect_scene = preload("res://scenes/effects/BossDeathEffect.tscn")
	if death_effect_scene:
		var effect = death_effect_scene.instance()
		get_parent().add_child(effect)
		effect.global_position = global_position
	
	queue_free()

func drop_boss_rewards():
	# XP masiva
	drop_xp(calculate_scaled_xp())
	
	# Items garantizados
	var item_manager = get_node("/root/ItemManager")
	if item_manager:
		# Siempre dropea un item azul o mejor
		item_manager.spawn_item_drop(global_position, ItemsDefinitions.ItemRarity.BLUE)
		
		# 30% probabilidad de item amarillo
		if randf() < 0.3:
			item_manager.spawn_item_drop(global_position + Vector2(50, 0), ItemsDefinitions.ItemRarity.YELLOW)

func drop_xp(amount: int):
	# Crear múltiples orbes de XP
	for i in range(5):
		var xp_scene = preload("res://scenes/effects/XPOrb.tscn")
		if xp_scene:
			var xp_orb = xp_scene.instance()
			get_parent().add_child(xp_orb)
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			xp_orb.global_position = global_position + offset
			xp_orb.xp_value = amount / 5

func announce_boss_spawn():
	# Notificar al jugador que apareció un boss
	var ui_manager = get_node("/root/UIManager")
	if ui_manager and ui_manager.has_method("show_boss_warning"):
		ui_manager.show_boss_warning(name)

func calculate_scaled_hp() -> int:
	var game_manager = get_node("/root/GameManager")
	var minutes_elapsed = 5  # Boss de 5 minutos
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	
	var hp = base_hp * (1 + 0.15 * minutes_elapsed) * (1 + 0.4 * (difficulty_tier - 1))
	return int(round(hp))

func calculate_scaled_damage() -> int:
	var game_manager = get_node("/root/GameManager")
	var minutes_elapsed = 5
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	
	var damage = base_damage * (1 + 0.12 * minutes_elapsed)
	return int(round(damage))

func calculate_scaled_xp() -> int:
	var xp = xp_drop * (1 + 0.2 * difficulty_tier)
	return int(round(xp))

func _on_spawn(spawn_position: Vector2):
	global_position = spawn_position
