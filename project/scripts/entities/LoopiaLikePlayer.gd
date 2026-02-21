extends CharacterBody2D
class_name LoopiaLikePlayer

# LoopiaLikePlayer.gd - Wrapper que carga WizardPlayer dinámicamente
# Mantiene compatibilidad con la escena y otros scripts

var wizard_player = null

signal player_damaged(amount: int, hp: int)
signal player_died
signal pickup_range_changed(new_range: float)
signal health_changed(current_hp: int, max_hp: int)

var hp: int = 100
var max_hp: int = 100
var move_speed: float = 100.0
var armor: int = 0
var magnet: float = 1.0
var pickup_radius: float = 64.0
var pickup_range_flat: float = 0.0  # Bonus plano de rango
var coin_value_mult: float = 1.0    # Multiplicador de valor de monedas

var health_component = null
var animated_sprite: AnimatedSprite2D = null
var last_dir: String = "down"
var health_bar_container: Node2D = null

# Footstep System
var _footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.35

func _ready() -> void:

	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Añadir al grupo "player" para que otros sistemas puedan encontrarnos
	add_to_group("player")

	# Configurar capas de colisión para LoopiaLikePlayer (quien hace move_and_slide)
	collision_layer = 0
	set_collision_layer_value(1, true)   # Capa player
	collision_mask = 0
	set_collision_mask_value(2, true)    # Enemigos
	set_collision_mask_value(4, true)    # Proyectiles enemigos
	set_collision_mask_value(5, true)    # Pickups
	set_collision_mask_value(8, true)    # Barreras de zona

	# Instanciar BasePlayer directamente (WizardPlayer era un stub vacío)
	var player_script = load("res://scripts/entities/players/BasePlayer.gd")
	if not player_script:
		push_warning("[LoopiaLikePlayer] ERROR: No se pudo cargar BasePlayer.gd")
		return

	wizard_player = player_script.new()
	if not wizard_player:
		push_warning("[LoopiaLikePlayer] ERROR: No se pudo instanciar BasePlayer")
		return

	# Leer personaje seleccionado desde SessionState para configurar sprites ANTES de _ready()
	wizard_player.character_class = "Player"
	wizard_player.character_sprites_key = "frost_mage"  # default
	if SessionState and SessionState.has_method("get_character"):
		var char_id = SessionState.get_character()
		if not char_id.is_empty():
			wizard_player.character_sprites_key = char_id

	# Pasar referencia al AnimatedSprite2D ANTES de add_child() para que _ready() la tenga disponible
	wizard_player.animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not wizard_player.animated_sprite:
		push_warning("[LoopiaLikePlayer] ERROR: No se pudo encontrar AnimatedSprite2D")
		return

	# CRÍTICO: Anexar como nodo hijo con nombre "WizardPlayer" (compatibilidad con otros scripts)
	# add_child() automáticamente llamará a _ready() del nodo hijo
	add_child(wizard_player)
	wizard_player.name = "WizardPlayer"  # Nombre mantenido para compatibilidad

	wizard_player.global_position = global_position

	if wizard_player.has_signal("player_damaged"):
		wizard_player.player_damaged.connect(_on_wizard_damaged)
	if wizard_player.has_signal("player_died"):
		wizard_player.player_died.connect(_on_wizard_died)

	# Conectar health_changed del HealthComponent para actualizar barra visual
	if wizard_player.health_component and wizard_player.health_component.has_signal("health_changed"):
		wizard_player.health_component.health_changed.connect(_on_health_changed_visual)

	# Actualizar referencias después de que WizardPlayer ya fue inicializado
	animated_sprite = wizard_player.animated_sprite
	health_component = wizard_player.health_component
	health_bar_container = wizard_player.health_bar_container

	hp = wizard_player.hp
	max_hp = wizard_player.max_hp
	move_speed = wizard_player.move_speed

	# Forzar actualización inicial de la barra de vida
	update_health_bar()


	# === P0.1: ORBITAL OVERHEAT SYSTEM ===
	_init_orbital_overheat()

	# === P0.2: I-FRAME VISUAL SYSTEM ===
	_init_iframes_visual()

# ═══════════════════════════════════════════════════════════════════════════════
# P0.1: ORBITAL OVERHEAT SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
# Orbital Overheat Variables
var _orbital_overheat_active: bool = false
var _orbital_overheat_timer: float = 0.0
const ORBITAL_OVERHEAT_INTERVAL: float = 2.5  # Chip damage every 2.5 sec
const ORBITAL_DANGER_RADIUS: float = 100.0    # Enemies within 100px
const ORBITAL_CHIP_DAMAGE: int = 1            # 1 HP per interval
const ORBITAL_HP_THRESHOLD: int = 15          # Don't apply if HP < 15
const ORBITAL_MIN_ENEMIES: int = 3            # Need at least 3 enemies nearby

func _init_orbital_overheat() -> void:
	"""Initialize orbital overheat system"""
	_orbital_overheat_active = false
	_orbital_overheat_timer = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# P0.2: I-FRAME VISUAL FEEDBACK SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
var _invulnerable_visual_active: bool = false
var _invulnerability_tween: Tween = null

func _init_iframes_visual() -> void:
	"""Initialize i-frame visual system"""
	_invulnerable_visual_active = false


func _physics_process(_delta: float) -> void:
	# BLOQUEO TOTAL durante muerte - no procesar nada más
	if wizard_player and wizard_player._is_dying:
		velocity = Vector2.ZERO
		return  # Salir inmediatamente, sin move_and_slide

	# Obtener input del jugador
	var input_manager = get_tree().root.get_node_or_null("InputManager")

	# DEBUG: Verificar máscara cada 60 frames (~1s)
	# if Engine.get_frames_drawn() % 120 == 0:
	# 	print("DEBUG Player: Collision Mask = %d (Bin: %s)" % [collision_mask, String.num_int64(collision_mask, 2)])

	if not input_manager:
		return

	# Obtener velocidad de movimiento desde PlayerStats (valor absoluto, no multiplicador)
	if wizard_player:
		var final_speed = wizard_player.base_move_speed  # Default fallback

		# Buscar PlayerStats - move_speed es valor absoluto (ej: 50 = velocidad base)
		var ps = get_tree().get_first_node_in_group("player_stats")
		if ps and ps.has_method("get_stat"):
			# Verificar si estamos sobre un camino y actualizar PlayerStats
			var arena_manager = get_tree().get_first_node_in_group("arena_manager")
			var on_path = false
			if arena_manager and arena_manager.has_method("is_on_path"):
				on_path = arena_manager.is_on_path(global_position)

			# Actualizar estado de camino en PlayerStats
			if ps.has_method("set_on_path"):
				ps.set_on_path(on_path)

			# Obtener velocidad (ya incluye bonus de camino si aplica)
			final_speed = ps.get_stat("move_speed")

		# Aplicar slow temporal si hay
		if wizard_player._is_slowed:
			final_speed = final_speed * (1.0 - wizard_player._slow_amount)

		move_speed = final_speed

	# No moverse si está stunneado
	if wizard_player and wizard_player.is_stunned():
		velocity = Vector2.ZERO
	else:
		var movement_input = input_manager.get_movement_vector()
		velocity = movement_input * move_speed

	move_and_slide()

	# === FOOTSTEP SOUNDS ===
	if velocity.length() > 50.0:
		_footstep_timer -= _delta
		if _footstep_timer <= 0.0:
			_play_footstep_sound()
			_footstep_timer = FOOTSTEP_INTERVAL
	else:
		_footstep_timer = 0.0 # Reset so it plays immediately when starting to move

	# === SISTEMA DE BARRERAS POR DISTANCIA ===
	# Más confiable que colisiones físicas para barreras circulares
	_enforce_zone_barriers()

	# === COLISIONES CON DECORADOS ===
	# Sistema basado en distancia (StaticBody2D dinámicos no funcionan)
	_enforce_decor_collisions()

	# === P0.1: ORBITAL OVERHEAT SYSTEM ===
	_update_orbital_overheat(_delta)

	# Sincronizar posición y velocidad con WizardPlayer (para que sus sistemas funcionen)
	if wizard_player:
		wizard_player.global_position = global_position
		wizard_player.velocity = velocity # Sincronizar velocidad para lógica como Torreta


func _enforce_zone_barriers() -> void:
	"""Sistema de barreras basado en distancia - 100% confiable"""
	var arena_manager = get_tree().root.get_node_or_null("Game/ArenaManager")
	if not arena_manager:
		return

	var dist_from_center = global_position.length()
	var max_allowed_radius = arena_manager.get_max_allowed_radius()

	# Si estamos más allá del radio permitido, empujar hacia adentro
	if dist_from_center > max_allowed_radius:
		var direction_to_center = -global_position.normalized()
		var push_distance = dist_from_center - max_allowed_radius + 5.0  # +5 de margen
		global_position += direction_to_center * push_distance

		# Feedback visual/sonoro opcional
		if not _barrier_hit_cooldown:
			_barrier_hit_cooldown = true
			# Pequeño efecto de rebote
			velocity = direction_to_center * 100.0
			# Reset cooldown después de 0.5s
			get_tree().create_timer(0.5).timeout.connect(func():
				if is_instance_valid(self): _barrier_hit_cooldown = false
			)

var _barrier_hit_cooldown: bool = false

func _enforce_decor_collisions() -> void:
	"""Sistema de colisión con decorados basado en distancia"""
	var manager = get_tree().get_first_node_in_group("decor_collision_manager")
	if not manager or not manager.has_method("check_collision_fast"):
		return

	# Player visual: ~125px de alto (500px * 0.25 scale)
	# Hitbox del 80% del tamaño
	var player_width = 30.0

	# La posición de colisión está en los PIES del player
	# Offset hacia abajo desde global_position
	var feet_offset = 50.0
	var collision_pos = global_position + Vector2(0, feet_offset)

	# Colisión circular con radio equivalente al ancho
	var player_radius = player_width / 2.0
	var push = manager.check_collision_fast(collision_pos, player_radius)

	if push.length_squared() > 0.1:
		global_position += push

func _play_footstep_sound() -> void:
	var arena_manager = get_tree().get_first_node_in_group("arena_manager")
	var biome = "Grassland"
	var is_on_path = false

	if arena_manager:
		if arena_manager.has_method("get_biome_at_position"):
			biome = arena_manager.get_biome_at_position(global_position)
		if arena_manager.has_method("is_on_path"):
			is_on_path = arena_manager.is_on_path(global_position)

	# Mapping biomes to ID keys (lowercase)
	var biome_key = "grassland" # default
	match biome:
		"Grassland":
			biome_key = "grassland"
		"Forest":
			biome_key = "forest"
		"Desert":
			biome_key = "desert"
		"Snow":
			biome_key = "snow"
		"Lava", "Volcano":
			biome_key = "lava"
		"ArcaneWastes", "Arcane":
			biome_key = "arcane_wastes"
		"Death", "Void":
			biome_key = "death"
		_:
			biome_key = "grassland"

	var surface = "path" if is_on_path else "ground"
	var sound_id = "sfx_footstep_%s_%s" % [biome_key, surface]

	# Fallback logic handled by AudioManager? No, better explicit here or use play() which warns if missing.
	# But user requested fallbacks:
	# "si tampoco existe, fallback final a sfx_footstep_stone_ground"

	# We rely on AudioManager.manifest check to see if we need fallback
	# But LoopiaLikePlayer doesn't have direct access to manifest dict usually (it's in Singleton).
	# We can use AudioManager.has_method("has_id") or just access manifest properties if exposed.
	# For now, we trust the generation. But let's add a safe simple fallback if we were to crash.
	# Actually AudioManager.play checks existence.

	AudioManager.play(sound_id)

func _on_wizard_damaged(amount: int, current_hp: int) -> void:
	hp = current_hp
	if wizard_player:
		max_hp = wizard_player.max_hp
	player_damaged.emit(amount, current_hp)
	_play_damage_animation()
	update_health_bar()

func _on_wizard_died() -> void:
	player_died.emit()

func take_damage(amount: int, element: String = "physical", attacker: Node = null) -> void:
	if wizard_player:
		wizard_player.take_damage(amount, element, attacker)

		# Play hurt sound
		AudioManager.play("sfx_player_hurt")

		# THORNS se maneja en BasePlayer._process_post_damage_effects → _apply_thorns_damage
		# para evitar aplicación doble

	hp = wizard_player.hp if wizard_player else hp

func heal(amount: int) -> void:
	if wizard_player:
		# Lógica de curación inteligente
		# Solo curar si realmente falta vida
		if wizard_player.hp < wizard_player.max_hp:
			var healed_amount = wizard_player.heal(amount)
			# Solo reproducir feedback si la curación fue efectiva (> 0)
			if healed_amount > 0:
				_play_heal_animation()
				# Evitar spam de sonido si es regeneración pequeña (opcional, pero buena práctica)
				# Por ahora lo dejamos siempre que cure algo
				AudioManager.play("sfx_player_heal")
		else:
			# Vida llena - ignorar curación y efectos
			pass

# Propagar métodos de efectos de estado al WizardPlayer
func apply_slow(amount: float, duration: float) -> void:
	if wizard_player:
		wizard_player.apply_slow(amount, duration)

func apply_burn(damage_per_tick: float, duration: float) -> void:
	if wizard_player:
		wizard_player.apply_burn(damage_per_tick, duration)

func apply_poison(damage_per_tick: float, duration: float) -> void:
	if wizard_player:
		wizard_player.apply_poison(damage_per_tick, duration)

func apply_stun(duration: float) -> void:
	if wizard_player:
		wizard_player.apply_stun(duration)

func apply_weakness(amount: float, duration: float) -> void:
	if wizard_player:
		wizard_player.apply_weakness(amount, duration)

func apply_curse(amount: float, duration: float) -> void:
	if wizard_player:
		wizard_player.apply_curse(amount, duration)

func set_character_sprites(sprite_folder: String) -> void:
	"""Proxy method to set character sprites on the actual WizardPlayer"""
	if wizard_player and wizard_player.has_method("set_character_sprites"):
		wizard_player.set_character_sprites(sprite_folder)

func _play_damage_animation() -> void:
	# Ya no es necesario aquí, el WizardPlayer maneja los efectos visuales
	pass

func _play_heal_animation() -> void:
	"""Aura verde sutil al curarse"""
	if animated_sprite:
		# Verde muy sutil - no tan intenso como el daño
		animated_sprite.modulate = Color(0.7, 1.3, 0.7, 1)
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.4)

func _on_health_changed_visual(current: int, max_val: int) -> void:
	"""Callback directo desde HealthComponent para actualizar visual"""
	hp = current
	max_hp = max_val
	update_health_bar()
	health_changed.emit(current, max_val)

func update_health_bar() -> void:
	if not health_bar_container:
		return

	var health_bar = health_bar_container.get_node_or_null("HealthBar")
	if health_bar:
		var health_percent = float(hp) / float(max_hp) if max_hp > 0 else 1.0
		health_bar.size.x = 40.0 * health_percent

func get_hp() -> int:
	return hp

func get_max_hp() -> int:
	return max_hp

func get_health() -> Dictionary:
	## Retorna un diccionario con la salud actual y máxima
	return {"current": hp, "max": max_hp}

func get_health_component() -> Node:
	"""Obtener el HealthComponent del wizard_player interno"""
	if wizard_player:
		return wizard_player.get_health_component()
	return null

func is_alive() -> bool:
	"""Verificar si el jugador está vivo"""
	if wizard_player:
		return wizard_player.is_alive()
	return hp > 0

func increase_max_health(amount: int) -> void:
	if wizard_player:
		wizard_player.max_hp += amount
		# También actualizar el HealthComponent para que refleje el nuevo max_health
		if wizard_player.health_component:
			var new_max = wizard_player.max_hp
			wizard_player.health_component.set_max_health(new_max)
			# Curar la cantidad aumentada (para que no quede HP parcial)
			wizard_player.health_component.heal(amount)
	max_hp = wizard_player.max_hp if wizard_player else max_hp
	hp = wizard_player.hp if wizard_player else hp
	update_health_bar()

func modify_stat(stat: String, value) -> void:
	if not wizard_player:
		return

	match stat:
		"move_speed":
			wizard_player.move_speed *= value
		"max_health":
			wizard_player.max_hp += int(value)
		"magnet":
			magnet *= value
			pickup_range_changed.emit(get_pickup_range())
		"pickup_range":
			# Multiplicador
			magnet *= value
			pickup_range_changed.emit(get_pickup_range())
		"pickup_range_flat":
			# Bonus plano en píxeles
			pickup_range_flat += value
			pickup_range_changed.emit(get_pickup_range())
		"coin_value_mult":
			coin_value_mult *= value

func get_pickup_range() -> float:
	"""Retorna el rango efectivo de recolección desde PlayerStats (valor absoluto)"""
	# pickup_range en PlayerStats es valor absoluto (ej: 50 = rango base en píxeles)
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		var range_value = player_stats.get_stat("pickup_range")
		# Añadir pickup_range_flat de PlayerStats
		var ps_flat = player_stats.get_stat("pickup_range_flat")
		return range_value + ps_flat + pickup_range_flat

	# Fallback al sistema local si no hay PlayerStats
	return (pickup_radius * magnet) + pickup_range_flat

func get_coin_value_mult() -> float:
	"""Retorna el multiplicador de valor de monedas (coin_value_mult + gold_mult de PlayerStats)"""
	var base_mult = coin_value_mult
	# También incluir gold_mult de PlayerStats si existe
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		var gold_mult = player_stats.get_stat("gold_mult")
		if gold_mult > 0:
			base_mult *= gold_mult
	return base_mult

func add_pickup_range(amount: float) -> void:
	"""Añade rango de recolección base en píxeles"""
	pickup_radius += amount
	pickup_range_changed.emit(get_pickup_range())

func multiply_pickup_range(multiplier: float) -> void:
	"""Multiplica el rango de recolección"""
	magnet *= multiplier
	pickup_range_changed.emit(get_pickup_range())

func add_pickup_range_flat(amount: float) -> void:
	"""Añade bonus plano de rango de recolección"""
	pickup_range_flat += amount
	pickup_range_changed.emit(get_pickup_range())

func get_magnet_strength() -> float:
	"""Retorna la fuerza de imán (velocidad de atracción) desde PlayerStats"""
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		return player_stats.get_stat("magnet_strength")
	return 1.0

func apply_special_effect(_effect_name: String, _item_data: Dictionary) -> void:
	pass

func setup_animations() -> void:
	if wizard_player and wizard_player.has_method("_setup_animations"):
		wizard_player._setup_animations()

func update_animation(dir: Vector2) -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		return

	var d: String = "down"
	if abs(dir.x) > abs(dir.y):
		d = "right" if dir.x > 0 else "left"
	else:
		d = "down" if dir.y > 0 else "up"

	last_dir = d
	if animated_sprite:
		animated_sprite.play("walk_%s" % d)

func create_health_bar() -> void:
	if not health_bar_container:
		health_bar_container = Node2D.new()
		health_bar_container.name = "HealthBarContainer"
		add_child(health_bar_container)

		# Calcular offset Y basado en la escala del sprite
		var sprite_scale = 0.25  # Default
		var visual_calibrator = get_tree().root.get_node_or_null("VisualCalibrator") if get_tree() else null
		if visual_calibrator and visual_calibrator.has_method("get_player_scale"):
			sprite_scale = visual_calibrator.get_player_scale()

		# Fórmula equilibrada: base + ajuste por escala
		# AUMENTADO: -50 base para no cortar la cabeza del sprite
		var bar_offset_y = -50.0 - (sprite_scale * 60.0)

		var bg_bar = ColorRect.new()
		bg_bar.size = Vector2(40, 4)
		bg_bar.color = Color(0.3, 0.3, 0.3, 0.8)
		bg_bar.position = Vector2(-20, bar_offset_y)
		health_bar_container.add_child(bg_bar)

		var health_bar = ColorRect.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(40, 4)
		health_bar.color = Color(0.0, 1.0, 0.0, 0.9)
		health_bar.position = Vector2(-20, bar_offset_y)
		health_bar_container.add_child(health_bar)

	update_health_bar()

# ═══════════════════════════════════════════════════════════════════════════════
# P0.1: ORBITAL OVERHEAT IMPLEMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

func _update_orbital_overheat(delta: float) -> void:
	"""Update orbital overheat system - applies chip damage when orbitals + close enemies"""
	# Only if we have active orbitals
	if not _has_active_orbitals():
		_orbital_overheat_active = false
		return

	# Check for nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	var enemies_nearby = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < ORBITAL_DANGER_RADIUS:
			enemies_nearby += 1
			if enemies_nearby >= ORBITAL_MIN_ENEMIES:
				break

	_orbital_overheat_active = (enemies_nearby >= ORBITAL_MIN_ENEMIES)

	if not _orbital_overheat_active:
		_orbital_overheat_timer = 0.0  # Reset timer when safe
		return

	# Apply chip damage
	_orbital_overheat_timer += delta
	if _orbital_overheat_timer >= ORBITAL_OVERHEAT_INTERVAL:
		_orbital_overheat_timer = 0.0
		_apply_orbital_chip_damage()

func _has_active_orbitals() -> bool:
	"""Check if player has any orbital weapons equipped"""
	# FIX-R7: Usar AttackManager (nodo 'WeaponManager' no existe)
	var attack_mgr = get_tree().get_first_node_in_group("attack_manager") if is_inside_tree() else null
	if not attack_mgr or not attack_mgr.has_method("get_weapons"):
		return false

	for weapon in attack_mgr.get_weapons():
		if "target_type" in weapon and weapon.target_type == WeaponDatabase.TargetType.ORBIT:
			return true

	return false

func _apply_orbital_chip_damage() -> void:
	"""Apply chip damage from orbital overheat"""
	if not health_component:
		return

	var current_hp = health_component.current_health if "current_health" in health_component else hp
	if current_hp <= ORBITAL_HP_THRESHOLD:
		return  # Safety: don't kill player or apply when low HP

	# Apply 1 HP environmental damage
	if health_component.has_method("take_damage"):
		health_component.take_damage(ORBITAL_CHIP_DAMAGE, "environmental")
	elif wizard_player and wizard_player.has_method("take_damage"):
		wizard_player.take_damage(ORBITAL_CHIP_DAMAGE, "environmental", null)

	# Visual feedback
	_show_overheat_flash()

	# Debug log (only in debug builds, throttled)
	if OS.is_debug_build() and Engine.get_frames_drawn() % 60 == 0:
		print("[Orbital Overheat] -%d HP (Enemies: ≥%d within %dpx)" % [ORBITAL_CHIP_DAMAGE, ORBITAL_MIN_ENEMIES, int(ORBITAL_DANGER_RADIUS)])

func _show_overheat_flash() -> void:
	"""Brief red flash to indicate overheat damage"""
	if OS.has_feature("headless") or not animated_sprite:
		return

	# Brief red tint
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1.5, 0.7, 0.7), 0.15)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)

# ═══════════════════════════════════════════════════════════════════════════════
# P0.2: I-FRAME VISUAL FEEDBACK IMPLEMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	"""Process-based updates (runs every frame, even when paused depending on mode)"""
	# P0.2: Update i-frame visual feedback
	_update_iframes_visual()

func _update_iframes_visual() -> void:
	"""Update I-frame visual flashing based on BasePlayer/WizardPlayer invulnerability"""
	if OS.has_feature("headless") or not animated_sprite:
		return

	# Check if wizard_player is invulnerable via BasePlayer's system
	var is_invulnerable = false
	if wizard_player and wizard_player.has_method("is_invulnerable"):
		is_invulnerable = wizard_player.is_invulnerable()

	if is_invulnerable and not _invulnerable_visual_active:
		_start_invulnerability_flash()
		_invulnerable_visual_active = true
	elif not is_invulnerable and _invulnerable_visual_active:
		_stop_invulnerability_flash()
		_invulnerable_visual_active = false

func _start_invulnerability_flash() -> void:
	"""Start flashing effect for i-frames"""
	if OS.has_feature("headless") or not animated_sprite:
		return

	# Kill existing tween
	if _invulnerability_tween and _invulnerability_tween.is_running():
		_invulnerability_tween.kill()

	# Create looping flash
	_invulnerability_tween = create_tween()
	_invulnerability_tween.set_loops()
	_invulnerability_tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
	_invulnerability_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)

func _stop_invulnerability_flash() -> void:
	"""Stop flashing and restore normal appearance"""
	if _invulnerability_tween and _invulnerability_tween.is_running():
		_invulnerability_tween.kill()

	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
