extends Node
class_name ExperienceManager

"""
⭐ GESTOR DE EXPERIENCIA - VAMPIRE SURVIVORS STYLE
================================================

Gestiona el sistema de experiencia:
- Bolitas de EXP que dropean enemigos
- Recolección automática
- Sistema de niveles
- Selección de mejoras al subir nivel
"""

signal exp_orb_created(orb: Node2D)
signal gold_orb_created(orb: Node2D)
signal gold_collected(amount: int)
signal exp_gained(amount: int, total_exp: int)
signal level_up(new_level: int, available_upgrades: Array)
signal streak_updated(count: int)

# Referencias
var player: CharacterBody2D

# Sistema de experiencia
var current_exp: int = 0
var current_level: int = 1
var exp_to_next_level: int = 10

# Configuración de orbes
var orb_collection_range: float = 80.0
var orb_attraction_range: float = 150.0
var orb_movement_speed: float = 200.0

# Orbes activos
var active_orbs: Array[Node2D] = []

# Pool de orbes para optimización
var orb_pool: Array[Node2D] = []
var max_pool_size: int = 50

# Streak tracking for gold pickups
var streak_count: int = 0
var last_gold_time: float = 0.0
var streak_timeout: float = 2.5

# Configuración de niveles
var level_exp_curve: Array[int] = []

func _ready():
	print("⭐ ExperienceManager inicializado")
	setup_level_curve()

func initialize(player_ref: CharacterBody2D):
	"""Inicializar sistema de experiencia"""
	player = player_ref
	current_exp = 0
	current_level = 1
	exp_to_next_level = get_exp_for_level(2)
	
	print("⭐ Sistema de experiencia inicializado")

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

func create_exp_orb(position: Vector2, exp_value: int):
	"""Crear orbe de experiencia en una posición"""
	var fb = load("res://scripts/core/Fallbacks.gd")
	var parent_node = get_tree().current_scene
	var orb = fb.spawn_xp_orb(parent_node, position, exp_value)
	# Try to initialize if the real orb scene was used
	if orb and orb.has_method("initialize"):
		orb.initialize(position, exp_value, player)
		if orb.has_signal("orb_collected"):
			orb.orb_collected.connect(Callable(self, "_on_exp_orb_collected"))
	active_orbs.append(orb)
	exp_orb_created.emit(orb)

func create_gold_orb(position: Vector2, gold_value: int):
	"""Crear orbe de oro (reutiliza la lógica de EXP pero con color distinto)"""
	var fb = load("res://scripts/core/Fallbacks.gd")
	var parent_node = get_tree().current_scene
	var orb = fb.spawn_xp_orb(parent_node, position, gold_value)
	if orb and orb.has_method("initialize"):
		orb.initialize(position, gold_value, player)
	orb.set_meta("is_gold_orb", true)
	orb.set_meta("gold_value", gold_value)
	orb.z_index = 45
	if orb.has_signal("orb_collected"):
		orb.orb_collected.connect(Callable(self, "_on_exp_orb_collected"))
	active_orbs.append(orb)
	gold_orb_created.emit(orb)
	return orb

func get_pooled_orb() -> Node2D:
	"""Obtener orbe del pool si está disponible"""
	if orb_pool.is_empty():
		return null
	
	return orb_pool.pop_back()

func return_orb_to_pool(orb: Node2D):
	"""Devolver orbe al pool"""
	if orb_pool.size() < max_pool_size:
		orb_pool.append(orb)
	else:
		orb.queue_free()

func _process(delta):
	"""Actualizar sistema de experiencia"""
	if not player:
		return
	
	# Actualizar orbes (atracción y recolección)
	update_orbs(delta)

func update_orbs(delta):
	"""Actualizar orbes de experiencia"""
	var orbs_to_remove = []
	
	for orb in active_orbs:
		if not is_instance_valid(orb):
			orbs_to_remove.append(orb)
			continue
		
		# Verificar distancia al player para atracción/recolección
		var distance_to_player = orb.global_position.distance_to(player.global_position)
		
		# Recolección automática
		var player_pickup = orb_collection_range
		var player_magnet = 1.0
		# Acceder a propiedades del player de forma defensiva
		if player:
			if _has_property(player, "pickup_radius"):
				player_pickup = player.pickup_radius
			if _has_property(player, "magnet"):
				player_magnet = player.magnet
		if distance_to_player <= player_pickup:
			collect_orb(orb)
			orbs_to_remove.append(orb)
		# Atracción hacia el player
		elif distance_to_player <= orb_attraction_range * player_magnet:
			attract_orb_to_player(orb, delta)
	
	# Remover orbes recolectados
	for orb in orbs_to_remove:
		active_orbs.erase(orb)

func attract_orb_to_player(orb: Node2D, delta: float):
	"""Atraer orbe hacia el player"""
	if orb.has_method("move_towards_player"):
		orb.move_towards_player(player.global_position, orb_movement_speed, delta)

func collect_orb(orb: Node2D):
	"""Recolectar orbe de experiencia"""
	var exp_value = orb.exp_value if orb.has_method("get_exp_value") else 1
	
	gain_experience(exp_value)
	
	# Efecto visual de recolección
	create_collection_effect(orb.global_position)
	
	# Devolver al pool o destruir
	# If this orb is a gold orb, emit a different signal or call a gold handler
	if orb.get_meta("is_gold_orb"):
		var gold = int(orb.get_meta("gold_value")) if orb.has_meta("gold_value") else 1
		# Handle streak: increase if collected quickly
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_gold_time <= streak_timeout:
			streak_count += 1
		else:
			streak_count = 1
		last_gold_time = now
		# Emit and try to update HUD if available
		emit_signal("streak_updated", streak_count)
		var _gt = get_tree()
		var root_scene = _gt.current_scene if _gt else null
		if root_scene and root_scene.has_node("GameHUD"):
			var gh = root_scene.get_node("GameHUD")
			if gh and gh.has_method("set_streak"):
				gh.set_streak(streak_count)
		print("💰 Gold collected: ", gold, " (streak:", streak_count, ")")

		# Apply streak multiplier (10% per extra streak)
		var multiplier = 1.0 + 0.10 * float(max(0, streak_count - 1))
		var gold_awarded = int(round(float(gold) * multiplier))
		# Notify global SaveManager or UI via signals (best-effort runtime lookup)
		var _gt2 = get_tree()
		var sm = _gt2.root.get_node_or_null("SaveManager") if _gt2 and _gt2.root else null
		if sm and sm.has_method("get_player_progression"):
			var pd = sm.get_player_progression()
			if pd:
				pd["meta_currency"] = pd.get("meta_currency", 0) + gold_awarded
				sm.save_game_data()
				# Update HUD if possible
				var ui = _gt2.root.get_node_or_null("UIManager") if _gt2 and _gt2.root else null
				if ui and ui.has_method("show_notification"):
					ui.show_notification("+" + str(gold) + " gold")
				# Emit signal to notify gold collected (amount awarded)
				emit_signal("gold_collected", gold_awarded)
				orb.queue_free()
	else:
		orb.queue_free()

func create_collection_effect(_position: Vector2):
	"""Crear efecto visual de recolección de EXP"""
	# Efecto simple de partículas o brillo
	# Por ahora solo log
	pass

func gain_experience(amount: int):
	"""Ganar experiencia"""
	current_exp += amount
	
	# Emitir señal
	exp_gained.emit(amount, current_exp)
	
	# Verificar subida de nivel
	check_level_up()
	
	print("⭐ EXP ganada: +", amount, " Total: ", current_exp, "/", exp_to_next_level)

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
	
	print("🆙 ¡LEVEL UP! Nuevo nivel: ", current_level)

func generate_upgrade_options() -> Array:
	"""Generar opciones de mejora para selección"""
	var options = []
	
	# Opciones básicas de ejemplo
	options.append({
		"id": "damage_boost",
		"name": "Daño Mágico +",
		"description": "Aumenta el daño de los proyectiles mágicos",
		"icon": "⚡"
	})
	
	options.append({
		"id": "speed_boost", 
		"name": "Velocidad +",
		"description": "Aumenta la velocidad de movimiento",
		"icon": "💨"
	})
	
	options.append({
		"id": "health_boost",
		"name": "Vida Máxima +",
		"description": "Aumenta la vida máxima",
		"icon": "❤️"
	})
	
	options.append({
		"id": "cooldown_reduction",
		"name": "Recarga Rápida",
		"description": "Reduce el tiempo de recarga de armas",
		"icon": "⏰"
	})
	
	# Shuffle y devolver 3-4 opciones aleatorias
	options.shuffle()
	return options.slice(0, min(3, options.size()))

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
		"active_orbs": active_orbs.size()
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

