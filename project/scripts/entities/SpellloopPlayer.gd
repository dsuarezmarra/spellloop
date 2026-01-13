extends CharacterBody2D
class_name SpellloopPlayer

# SpellloopPlayer.gd - Wrapper que carga WizardPlayer dinámicamente
# Mantiene compatibilidad con la escena y otros scripts

var wizard_player = null

signal player_damaged(amount: int, hp: int)
signal player_died
signal pickup_range_changed(new_range: float)

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

func _ready() -> void:
	# print("\n[SpellloopPlayer] ===== INICIANDO SPELLLOOP PLAYER =====")

	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Añadir al grupo "player" para que otros sistemas puedan encontrarnos
	add_to_group("player")

	# Configurar capas de colisión para SpellloopPlayer (quien hace move_and_slide)
	collision_layer = 0
	set_collision_layer_value(1, true)   # Capa player
	collision_mask = 0
	set_collision_mask_value(2, true)    # Enemigos
	set_collision_mask_value(4, true)    # Proyectiles enemigos
	set_collision_mask_value(5, true)    # Pickups
	set_collision_mask_value(8, true)    # Barreras de zona

	var wizard_script = load("res://scripts/entities/players/WizardPlayer.gd")
	if not wizard_script:
		push_warning("[SpellloopPlayer] ERROR: No se pudo cargar WizardPlayer.gd")
		return

	# print("[SpellloopPlayer] OK: WizardPlayer.gd cargado")

	wizard_player = wizard_script.new()
	if not wizard_player:
		push_warning("[SpellloopPlayer] ERROR: No se pudo instanciar WizardPlayer")
		return

	# Pasar referencia al AnimatedSprite2D ANTES de add_child() para que _ready() la tenga disponible
	wizard_player.animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not wizard_player.animated_sprite:
		push_warning("[SpellloopPlayer] ERROR: No se pudo encontrar AnimatedSprite2D")
		return

	# CRÍTICO: Anexar WizardPlayer como nodo hijo
	# add_child() automáticamente llamará a _ready() del nodo hijo
	# NO llamar explícitamente a wizard_player._ready() para evitar inicialización duplicada
	add_child(wizard_player)
	wizard_player.name = "WizardPlayer"

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

	# print("[SpellloopPlayer] ===== OK: SPELLLOOP PLAYER LISTO =====\n")

func _physics_process(_delta: float) -> void:
	# Obtener input del jugador
	var input_manager = get_tree().root.get_node_or_null("InputManager")
	if not input_manager:
		return

	# Obtener velocidad de movimiento desde PlayerStats (valor absoluto, no multiplicador)
	if wizard_player:
		var final_speed = wizard_player.base_move_speed  # Default fallback

		# Buscar PlayerStats - move_speed es valor absoluto (ej: 50 = velocidad base)
		var ps = get_tree().get_first_node_in_group("player_stats")
		if ps and ps.has_method("get_stat"):
			final_speed = ps.get_stat("move_speed")  # Valor directo, no multiplicador

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

	# === SISTEMA DE BARRERAS POR DISTANCIA ===
	# Más confiable que colisiones físicas para barreras circulares
	_enforce_zone_barriers()

	# Sincronizar posición con WizardPlayer (para que sus sistemas funcionen)
	if wizard_player:
		wizard_player.global_position = global_position

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
			# print("🚧 [Player] Barrera de zona! Radio actual: %.0f, máximo permitido: %.0f" % [dist_from_center, max_allowed_radius])
			# Pequeño efecto de rebote
			velocity = direction_to_center * 100.0
			# Reset cooldown después de 0.5s
			get_tree().create_timer(0.5).timeout.connect(func(): _barrier_hit_cooldown = false)

var _barrier_hit_cooldown: bool = false

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
	hp = wizard_player.hp if wizard_player else hp

func heal(amount: int) -> void:
	if wizard_player:
		wizard_player.heal(amount)
		_play_heal_animation()

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
		print("[SpellloopPlayer] Sprites changed to: %s" % sprite_folder)

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
	# print("🧲 [Player] Pickup range: %.0f (base: %.0f, mult: %.2fx, flat: +%.0f)" % [get_pickup_range(), pickup_radius, magnet, pickup_range_flat])

func multiply_pickup_range(multiplier: float) -> void:
	"""Multiplica el rango de recolección"""
	magnet *= multiplier
	pickup_range_changed.emit(get_pickup_range())
	# print("🧲 [Player] Pickup range: %.0f (base: %.0f, mult: %.2fx, flat: +%.0f)" % [get_pickup_range(), pickup_radius, magnet, pickup_range_flat])

func add_pickup_range_flat(amount: float) -> void:
	"""Añade bonus plano de rango de recolección"""
	pickup_range_flat += amount
	pickup_range_changed.emit(get_pickup_range())
	# print("🧲 [Player] Pickup range: %.0f (base: %.0f, mult: %.2fx, flat: +%.0f)" % [get_pickup_range(), pickup_radius, magnet, pickup_range_flat])

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
		var bar_offset_y = -30.0 - (sprite_scale * 40.0)

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
