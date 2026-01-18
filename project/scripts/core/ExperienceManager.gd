extends Node
class_name ExperienceManager

"""
⭐ GESTOR DE EXPERIENCIA Y MONEDAS - ESTILO BROTATO
===================================================

Gestiona:
- XP AUTOMÁTICO: Se obtiene directamente al matar enemigos
- MONEDAS: Caen al suelo, el player las recoge (con atracción)
- Sistema de niveles y selección de mejoras
"""

# === SEÑALES ===
signal coin_created(coin: Node2D)
signal coin_collected(amount: int, total: int)
signal exp_gained(amount: int, total_exp: int)
signal level_up(new_level: int, available_upgrades: Array)
signal streak_updated(count: int)
signal streak_timer_updated(time_left: float, max_time: float) # NUEVO: Para la barra de mecha

# === REFERENCIAS ===
var player: CharacterBody2D

# === SISTEMA DE EXPERIENCIA ===
var current_exp: int = 0
var current_level: int = 1
var exp_to_next_level: int = 10

# === SISTEMA DE MONEDAS ===
var total_coins: int = 0  # Monedas totales de esta partida
var active_coins: Array[Node2D] = []  # Monedas activas en el mundo
var coin_scene: PackedScene = null

# Configuración de drops de monedas
var base_coin_drop_chance: float = 0.7  # 70% de chance de drop
var coin_value_variance: float = 0.3  # ±30% variación en valor

# Streak tracking for coin pickups
var streak_count: int = 0
var last_coin_time: float = 0.0
var streak_timeout: float = 2.0  # Segundos para mantener streak

# === CONFIGURACIÓN DE NIVELES ===
var level_exp_curve: Array[int] = []

func _ready():
	# Asegurar que ExperienceManager respete la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Registrar en grupo para acceso global seguro
	add_to_group("experience_manager")
	
	# Debug desactivado: print("⭐ ExperienceManager inicializado")
	setup_level_curve()
	_load_coin_scene()

	# Debug desactivado: print("💰 ExperienceManager: Añadidas %d monedas (Total: %d)" % [amount, total_coins])

func _process(delta: float) -> void:
	if streak_count > 0:
		var time_since_coin = Time.get_ticks_msec() / 1000.0 - last_coin_time
		var time_left = maxf(0.0, streak_timeout - time_since_coin)
		
		# Emitir señal de actualización de timer
		streak_timer_updated.emit(time_left, streak_timeout)
		
		# Si se acabó el tiempo, resetear streak (la lógica original ya hacía esto al recoger moneda, 
		# pero para la UI necesitamos saber cuando llega a 0 en tiempo real)
		if time_left <= 0:
			streak_count = 0
			streak_updated.emit(0)

func add_coins(base_amount: int) -> void:
	"""Añadir monedas aplicando multiplicadores del jugador (cofres, eventos, etc)"""
	# Aplicar multiplicador de estadísticas del jugador (Greed, etc.)
	var coin_mult = _get_player_coin_mult()
	var final_amount = int(base_amount * coin_mult)
	
	total_coins += final_amount
	coin_collected.emit(final_amount, total_coins)
	_save_coins_to_progression(final_amount)
	_save_coins_to_progression(final_amount)
	# Debug desactivado: print("💰 ExperienceManager: Añadidas %d monedas (Total: %d)" % [final_amount, total_coins])

func spend_coins(amount: int) -> bool:
	"""Gastar monedas y actualizar UI inmediatamente"""
	if total_coins >= amount:
		total_coins -= amount
		# Emitimos coin_collected con valor negativo para actualizar el label del HUD sin animación de ganancia
		coin_collected.emit(-amount, total_coins)
		# Guardar progreso (si es necesario implementar persistencia aquí)
		return true
	return false

func initialize(player_ref: CharacterBody2D):
	"""Inicializar sistema de experiencia"""
	player = player_ref
	current_exp = 0
	current_level = 1
	exp_to_next_level = get_exp_for_level(2)
	total_coins = 0
	active_coins.clear()

	# Debug desactivado: print("⭐ Sistema de experiencia y monedas inicializado")

func _load_coin_scene() -> void:
	"""Cargar la escena de monedas"""
	var coin_path = "res://scenes/pickups/CoinPickup.tscn"
	if ResourceLoader.exists(coin_path):
		coin_scene = load(coin_path)
		# Debug desactivado: print("🪙 Escena de monedas cargada")
	else:
		push_warning("[ExperienceManager] No se encontró CoinPickup.tscn")

func _find_player() -> CharacterBody2D:
	"""Buscar referencia al player"""
	if player and is_instance_valid(player):
		return player
	# Buscar en el árbol si no tenemos referencia
	var tree = get_tree()
	if tree and tree.root:
		var game = tree.root.get_node_or_null("Game")
		if game and "player" in game:
			player = game.player
			return player
	return null

func setup_level_curve():
	"""Configurar curva de experiencia por nivel"""
	# Curva base: xp_to_level = 5 + level * 3
	for level in range(1, 101):
		var exp_required = 5 + level * 3
		level_exp_curve.append(exp_required)

func get_exp_for_level(level: int) -> int:
	"""Obtener EXP requerida para un nivel específico"""
	if level <= 1:
		return 0
	if level - 2 < level_exp_curve.size():
		return level_exp_curve[level - 2]
	return 5 + level * 3

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE XP AUTOMÁTICO
# ═══════════════════════════════════════════════════════════════════════════════

func grant_exp_from_kill(exp_value: int) -> void:
	"""Dar XP directamente al matar un enemigo (sin orbes)"""
	gain_experience(exp_value)
	# Debug desactivado: print("⭐ XP automático: +%d" % exp_value)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE MONEDAS
# ═══════════════════════════════════════════════════════════════════════════════

func create_coin(position: Vector2, base_value: int = 1) -> Node2D:
	"""Crear una moneda en el escenario"""
	var coin: Node2D = null

	# Aplicar variación al valor
	var variance = randf_range(-coin_value_variance, coin_value_variance)
	var final_value = max(1, int(base_value * (1.0 + variance)))

	# Usar escena si está cargada
	if coin_scene:
		coin = coin_scene.instantiate()
	else:
		# Fallback: crear moneda simple
		coin = _create_fallback_coin()

	if coin:
		# Añadir al mundo
		var parent = get_tree().current_scene
		if parent:
			parent.add_child(coin)

		# Inicializar
		if coin.has_method("initialize"):
			coin.initialize(position, final_value, player)
		else:
			coin.global_position = position
			if "coin_value" in coin:
				coin.coin_value = final_value

		# Conectar señal de recolección
		if coin.has_signal("coin_collected"):
			coin.coin_collected.connect(_on_coin_collected)

		active_coins.append(coin)
		coin_created.emit(coin)

	return coin

func spawn_coins_from_enemy(position: Vector2, enemy_tier: int = 1, is_elite: bool = false, is_boss: bool = false) -> void:
	"""Spawnear monedas al morir un enemigo basado en su tier"""
	# Decidir si dropea monedas
	var drop_chance = base_coin_drop_chance
	if is_boss:
		drop_chance = 1.0  # Bosses siempre dropean
	elif is_elite:
		drop_chance = 1.0  # Élites siempre dropean

	if randf() > drop_chance:
		return  # No drop

	# Determinar tipo de moneda según tier/elite/boss
	var coin_type = _get_coin_type_for_enemy(enemy_tier, is_elite, is_boss)

	# Calcular cantidad de monedas
	var coin_count = 1
	match enemy_tier:
		1:
			coin_count = randi_range(1, 2)
		2:
			coin_count = randi_range(1, 3)
		3:
			coin_count = randi_range(2, 3)
		4:
			coin_count = randi_range(2, 4)
		5:  # Boss tier
			coin_count = randi_range(5, 8)

	# Multiplicadores especiales
	if is_elite:
		coin_count = int(coin_count * 2)
	if is_boss:
		coin_count = int(coin_count * 2.5)

	# Crear las monedas con pequeño offset aleatorio
	for i in range(coin_count):
		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		_create_coin_with_type(position + offset, coin_type)

func _get_coin_type_for_enemy(tier: int, is_elite: bool, is_boss: bool) -> int:
	"""Determinar el tipo de moneda según el enemigo"""
	# CoinType enum: BRONZE=0, SILVER=1, GOLD=2, DIAMOND=3, PURPLE=4
	if is_boss:
		return 4  # PURPLE
	elif is_elite:
		return 3  # DIAMOND
	else:
		match tier:
			1:
				return 0  # BRONZE
			2:
				return 1  # SILVER
			3, 4:
				return 2  # GOLD
			5:
				return 3  # DIAMOND
			_:
				return 0  # BRONZE

func _create_coin_with_type(pos: Vector2, coin_type: int) -> Node2D:
	"""Crear moneda con tipo específico"""
	var coin: Node2D = null

	# Usar escena si está cargada
	if coin_scene:
		coin = coin_scene.instantiate()
	else:
		# Fallback: crear moneda simple
		coin = _create_fallback_coin()

	if coin:
		# Añadir al mundo
		var parent = get_tree().current_scene
		if parent:
			parent.add_child(coin)

		# Inicializar CON TIPO
		if coin.has_method("initialize"):
			coin.initialize(pos, 1, player, coin_type)
		else:
			coin.global_position = pos
			if "coin_value" in coin:
				coin.coin_value = 1

		# Conectar señal de recolección
		if coin.has_signal("coin_collected"):
			if not coin.coin_collected.is_connected(_on_coin_collected):
				coin.coin_collected.connect(_on_coin_collected)

		active_coins.append(coin)
		coin_created.emit(coin)

	return coin

func _create_fallback_coin() -> Node2D:
	"""Crear moneda simple si no hay escena"""
	var coin = Area2D.new()
	coin.name = "CoinFallback"

	# Colisión
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	coin.add_child(collision)

	# Sprite simple
	var sprite = Sprite2D.new()
	var size = 12
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist < size / 2.0 - 1:
				img.set_pixel(x, y, Color(1.0, 0.84, 0.0))  # Dorado
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	sprite.texture = ImageTexture.create_from_image(img)
	coin.add_child(sprite)

	# Añadir propiedades necesarias
	coin.set_meta("coin_value", 1)

	return coin

func on_coin_collected(value: int, _position: Vector2 = Vector2.ZERO) -> void:
	"""Callback cuando se recoge una moneda (llamado desde CoinPickup)"""
	_on_coin_collected(value)

func _on_coin_collected(value: int) -> void:
	"""Procesar recolección de moneda"""
	# Actualizar streak
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_coin_time <= streak_timeout:
		streak_count += 1
	else:
		streak_count = 1
	last_coin_time = now

	# Aplicar multiplicador de streak (5% por cada streak adicional)
	# El flag "double_coin_streak" duplica este bonus
	var streak_bonus_per = 0.05
	if _has_flag("double_coin_streak"):
		streak_bonus_per = 0.10
	var streak_multiplier = 1.0 + streak_bonus_per * float(max(0, streak_count - 1))

	# Aplicar multiplicador de valor de monedas del player
	var coin_mult = _get_player_coin_mult()

	var final_value = int(ceil(float(value) * streak_multiplier * coin_mult))

	# Añadir al total
	total_coins += final_value

	# Emitir señales
	streak_updated.emit(streak_count)
	coin_collected.emit(final_value, total_coins)

	# Guardar en SaveManager si existe
	_save_coins_to_progression(final_value)

	# --- LÓGICA DE IMÁN VITAL (Item 12: Heal on Pickup) ---
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		var heal_amount = int(player_stats.get_stat("heal_on_pickup"))
		if heal_amount > 0:
			var p = _find_player()
			if p and p.has_method("heal"):
				p.heal(heal_amount)
	# -----------------------------------------------------

	# Debug desactivado: prints de monedas con streak/multiplicadores

func _get_player_coin_mult() -> float:
	"""Obtener multiplicador de monedas desde PlayerStats (Sistema Unificado)"""
	# Prioridad: PlayerStats (grupo global) -> Player methods -> 1.0
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		return player_stats.get_stat("coin_value_mult")
		
	# Fallback a métodos antiguos del player
	var player = _find_player()
	if player and player.has_method("get_coin_value_mult"):
		return player.get_coin_value_mult()
	elif player and "coin_value_mult" in player:
		return player.coin_value_mult
		
	return 1.0

func _has_flag(flag_name: String) -> bool:
	"""Verificar si el player tiene un flag activo (de pasivos especiales)"""
	var player = _find_player()
	if player and "active_flags" in player:
		return flag_name in player.active_flags
	# También verificar en un nodo global de flags si existe
	var tree = get_tree()
	if tree and tree.root:
		var game = tree.root.get_node_or_null("Game")
		if game and "player_flags" in game:
			return flag_name in game.player_flags
	return false

func _save_coins_to_progression(amount: int) -> void:
	"""Guardar monedas en la progresión del jugador"""
	var tree = get_tree()
	if not tree or not tree.root:
		return

	var save_manager = tree.root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("get_player_progression"):
		var progression = save_manager.get_player_progression()
		if progression:
			progression["meta_currency"] = progression.get("meta_currency", 0) + amount
			# No guardar inmediatamente cada moneda, se guarda al final de la partida

func _process(delta):
	"""Actualizar sistema - limpiar monedas inválidas"""
	# Limpiar referencias a monedas destruidas
	var coins_to_remove = []
	for coin in active_coins:
		if not is_instance_valid(coin):
			coins_to_remove.append(coin)

	for coin in coins_to_remove:
		active_coins.erase(coin)

func create_collection_effect(_position: Vector2):
	"""Crear efecto visual de recolección de EXP"""
	# Efecto simple de partículas o brillo
	# Por ahora solo log
	pass

func gain_experience(amount: int):
	"""Ganar experiencia, aplicando multiplicador de PlayerStats"""
	# Aplicar xp_mult de PlayerStats si existe
	var final_amount = amount
	var player_stats = get_tree().get_first_node_in_group("player_stats") if is_inside_tree() else null
	if player_stats and player_stats.has_method("get_stat"):
		var xp_mult = player_stats.get_stat("xp_mult")
		if xp_mult > 0:
			final_amount = int(amount * xp_mult)
	
	current_exp += final_amount

	# Emitir señal
	exp_gained.emit(final_amount, current_exp)

	# Verificar subida de nivel
	check_level_up()

	# Debug desactivado: print("⭐ EXP ganada: +", final_amount)

func check_level_up():
	"""Verificar si el player sube de nivel"""
	while current_exp >= exp_to_next_level:
		level_up_player()

func level_up_player():
	"""Subir nivel del player"""
	current_exp -= exp_to_next_level
	current_level += 1
	exp_to_next_level = get_exp_for_level(current_level + 1)

	# Generar opciones de mejora
	var upgrade_options = generate_upgrade_options()

	# Emitir señal de subida de nivel
	level_up.emit(current_level, upgrade_options)

	# Debug desactivado: print("🆙 ¡LEVEL UP! Nuevo nivel: ", current_level)

func generate_upgrade_options() -> Array:
	"""Generar opciones de mejora para selección usando PassiveDatabase"""
	var options = []

	# Usar UpgradeDatabase (Sistema Unificado)
	var UpgradeDB = load("res://scripts/data/UpgradeDatabase.gd")
	if UpgradeDB:
		# 1. Obtener tags de armas equipadas
		var common_tags = []
		var all_tags = []
		
		var attack_manager_nodes = get_tree().get_nodes_in_group("attack_manager")
		if not attack_manager_nodes.is_empty():
			var am = attack_manager_nodes[0]
			if "weapons" in am:
				var first_weapon = true
				for weapon in am.weapons:
					if weapon == null: continue
					
					var w_tags = weapon.tags if "tags" in weapon else []
					
					# All Tags (Union)
					for t in w_tags:
						if t not in all_tags:
							all_tags.append(t)
					
					# Common Tags (Intersection)
					if first_weapon:
						common_tags = w_tags.duplicate()
						first_weapon = false
					else:
						# Intersección manual
						var new_common = []
						for t in common_tags:
							if t in w_tags:
								new_common.append(t)
						common_tags = new_common
		
		# 2. Obtener Luck y Tiempo
		var luck_bonus = 0.0
		if player and "stats" in player and player.stats and "luck" in player.stats:
			luck_bonus = player.stats.luck
			
		var game_time = 0.0
		# Intentar obtener tiempo de juego (GameManager o similar)
		var gm_nodes = get_tree().get_nodes_in_group("game_manager")
		if not gm_nodes.is_empty() and "game_time" in gm_nodes[0]:
			game_time = gm_nodes[0].game_time / 60.0 # Minutos
		
		# 3. Generar opciones
		options = UpgradeDB.get_random_player_upgrades(4, [], luck_bonus, game_time, [], common_tags, all_tags)
		
		# 4. Filtrar upgrades que solo afectan stats al cap
		var player_stats = get_tree().get_first_node_in_group("player_stats")
		if player_stats and player_stats.has_method("would_upgrade_be_useful"):
			var useful_options = []
			for upgrade in options:
				if player_stats.would_upgrade_be_useful(upgrade):
					useful_options.append(upgrade)
				# else: upgrade is useless because all its effects are capped
			
			# Si quedaron opciones útiles, usarlas
			if useful_options.size() > 0:
				options = useful_options
			# Si no quedó ninguna, usar las originales como fallback
		
		if options.size() > 0:
			return options

	# Fallback: opciones básicas si PassiveDatabase no está disponible
	options.append({
		"id": "damage_boost",
		"name": "Daño Mágico +",
		"description": "Aumenta el daño de los proyectiles mágicos en un 10%",
		"icon": "⚡",
		"type": "PLAYER_UPGRADE",
		"rarity": "common",
		"effects": [{"stat": "damage_multiplier", "value": 0.10, "operation": "add"}]
	})

	options.append({
		"id": "speed_boost",
		"name": "Velocidad +",
		"description": "Aumenta la velocidad de movimiento en un 10%",
		"icon": "💨",
		"type": "PLAYER_UPGRADE",
		"rarity": "common",
		"effects": [{"stat": "speed_multiplier", "value": 0.10, "operation": "add"}]
	})

	options.append({
		"id": "health_boost",
		"name": "Vida Máxima +",
		"description": "Aumenta la vida máxima en 20",
		"icon": "❤️",
		"type": "PLAYER_UPGRADE",
		"rarity": "common",
		"effects": [{"stat": "max_health", "value": 20, "operation": "add"}]
	})

	options.append({
		"id": "cooldown_reduction",
		"name": "Recarga Rápida",
		"description": "Reduce el tiempo de recarga de armas en un 5%",
		"icon": "⏰",
		"type": "PLAYER_UPGRADE",
		"rarity": "uncommon",
		"effects": [{"stat": "cooldown_reduction", "value": 0.05, "operation": "add"}]
	})

	# Shuffle y devolver 3-4 opciones aleatorias
	options.shuffle()
	return options.slice(0, min(4, options.size()))

func _on_exp_orb_collected(_orb: Node2D, exp_value: int):
	"""Manejar recolección de orbe (señal desde el orbe)"""
	gain_experience(exp_value)

func _has_property(obj: Object, prop_name: String) -> bool:
	"""Helper: comprobar si un objeto expone una propiedad con nombre prop_name.
	Usa get_property_list() para evitar accesos directos que provoquen excepciones.
	"""
	if not obj:
		return false
	# Algunos objetos pueden no exponer get_property_list; comprobar existencia
	if not obj.get_property_list:
		return false
	var plist = obj.get_property_list()
	for p in plist:
		if typeof(p) == TYPE_DICTIONARY and p.has("name") and p.name == prop_name:
			return true
	return false

func get_level_progress() -> float:
	"""Obtener progreso hacia el siguiente nivel (0.0 - 1.0)"""
	if exp_to_next_level <= 0:
		return 1.0
	return float(current_exp) / float(exp_to_next_level)

func get_stats() -> Dictionary:
	"""Obtener estadísticas de experiencia"""
	return {
		"level": current_level,
		"current_exp": current_exp,
		"exp_to_next": exp_to_next_level,
		"progress": get_level_progress(),
		"active_coins": active_coins.size()
	}

# Clase para orbes de experiencia
class ExpOrb:
	extends Node2D

	var exp_value: int = 1
	var lifetime: float = 30.0
	var life_timer: float = 0.0

	var sprite: Sprite2D
	var player_ref: CharacterBody2D

	func initialize(orb_position: Vector2, exp_val: int, player: CharacterBody2D) -> void:
		global_position = orb_position
		exp_value = exp_val
		player_ref = player

		setup_visual()
		z_index = 40

	func setup_visual() -> void:
		sprite = Sprite2D.new()
		add_child(sprite)
		create_exp_orb_texture()
		# apply scale from ScaleManager if available
		var scale_factor = 0.8
		if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ScaleManager"):
			var sm = get_tree().root.get_node("ScaleManager")
			if sm and sm.has_method("get_scale"):
				scale_factor = sm.get_scale()
		sprite.scale = Vector2(scale_factor, scale_factor)
		start_floating_effect()

	func create_exp_orb_texture() -> void:
		var size = 12
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(int(size / 2.0), int(size / 2.0))
		var radius = int(size / 2.0) - 1
		for x in range(size):
			for y in range(size):
				var pos = Vector2(x, y)
				var distance = pos.distance_to(center)
				if distance <= radius:
					var intensity = 1.0 - (distance / radius)
					var color = Color(0.2 + intensity * 0.8, 0.8 + intensity * 0.2, 0.2, 0.9)
					image.set_pixel(x, y, color)
				else:
					image.set_pixel(x, y, Color.TRANSPARENT)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture

	func start_floating_effect() -> void:
		var tween = create_tween()
		tween.tween_property(sprite, "position", Vector2(0, -5), 1.0)
		tween.tween_property(sprite, "position", Vector2(0, 5), 1.0)
		tween.set_loops()

	func move_towards_player(player_position: Vector2, speed: float, delta: float) -> void:
		var direction = (player_position - global_position).normalized()
		global_position += direction * speed * delta

	func _process(delta: float) -> void:
		life_timer += delta
		if life_timer >= lifetime:
			queue_free()

	func get_exp_value() -> int:
		return exp_value
