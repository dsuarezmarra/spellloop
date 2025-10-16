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
signal exp_gained(amount: int, total_exp: int)
signal level_up(new_level: int, available_upgrades: Array)

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
	# Curva exponencial similar a Vampire Survivors
	for level in range(1, 101):  # Hasta nivel 100
		var base_exp = 10
		var exp_required = int(base_exp * pow(level, 1.5))
		level_exp_curve.append(exp_required)
	
	print("⭐ Curva de experiencia configurada para ", level_exp_curve.size(), " niveles")

func get_exp_for_level(level: int) -> int:
	"""Obtener EXP requerida para un nivel específico"""
	if level <= 1:
		return 0
	if level - 2 < level_exp_curve.size():
		return level_exp_curve[level - 2]
	
	# Para niveles muy altos, usar fórmula
	return int(10 * pow(level, 1.5))

func create_exp_orb(position: Vector2, exp_value: int):
	"""Crear orbe de experiencia en una posición"""
	var orb = get_pooled_orb()
	if not orb:
		orb = ExpOrb.new()
	
	orb.initialize(position, exp_value, player)
	orb.orb_collected.connect(_on_exp_orb_collected)
	
	# Añadir al árbol de escena
	get_tree().current_scene.add_child(orb)
	active_orbs.append(orb)
	
	# Emitir señal
	exp_orb_created.emit(orb)
	
	#print("⭐ Orbe de EXP creado: ", exp_value, " en ", position)

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
		if distance_to_player <= orb_collection_range:
			collect_orb(orb)
			orbs_to_remove.append(orb)
		# Atracción hacia el player
		elif distance_to_player <= orb_attraction_range:
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
	orb.queue_free()

func create_collection_effect(position: Vector2):
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

func _on_exp_orb_collected(orb: Node2D, exp_value: int):
	"""Manejar recolección de orbe (señal desde el orbe)"""
	gain_experience(exp_value)

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
class ExpOrb extends Node2D:
	
	signal orb_collected(orb: Node2D, exp_value: int)
	
	var exp_value: int = 1
	var lifetime: float = 30.0  # Duración antes de desaparecer
	var life_timer: float = 0.0
	
	var sprite: Sprite2D
	var player_ref: CharacterBody2D
	
	func initialize(position: Vector2, exp_val: int, player: CharacterBody2D):
		global_position = position
		exp_value = exp_val
		player_ref = player
		
		setup_visual()
		z_index = 40  # Encima de enemigos, debajo del player
	
	func setup_visual():
		"""Configurar apariencia del orbe"""
		sprite = Sprite2D.new()
		add_child(sprite)
		
		# Crear textura de orbe de EXP
		create_exp_orb_texture()
		
		# Aplicar escala
		var scale_factor = 0.8
		if ScaleManager:
			scale_factor *= ScaleManager.get_scale()
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Efecto de flotación
		start_floating_effect()
	
	func create_exp_orb_texture():
		"""Crear textura del orbe de EXP"""
		var size = 12
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		
		var center = Vector2(size / 2, size / 2)
		var radius = size / 2 - 1
		
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
	
	func start_floating_effect():
		"""Iniciar efecto de flotación"""
		var tween = create_tween()
		# add_child(tween)  # Ya no es necesario con create_tween()
		
		tween.tween_property(sprite, "position", Vector2(0, -5), 1.0)
		tween.tween_property(sprite, "position", Vector2(0, 5), 1.0)
		tween.set_loops()
	
	func move_towards_player(player_position: Vector2, speed: float, delta: float):
		"""Mover hacia el player cuando está en rango de atracción"""
		var direction = (player_position - global_position).normalized()
		global_position += direction * speed * delta
	
	func _process(delta):
		life_timer += delta
		
		# Desaparecer después del tiempo de vida
		if life_timer >= lifetime:
			queue_free()
	
	func get_exp_value() -> int:
		return exp_value
