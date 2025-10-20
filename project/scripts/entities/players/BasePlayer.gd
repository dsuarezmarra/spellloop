# BasePlayer.gd
# Clase base genérica para todos los personajes jugables
# Proporciona movimiento, stats, salud, manejo de armas, etc.
# Las clases específicas (Wizard, Rogue, etc.) heredan de aquí

extends CharacterBody2D
class_name BasePlayer

# ========== SEÑALES ==========
signal player_damaged(amount: int, current_hp: int)
signal player_died
signal weapon_equipped(weapon)
signal weapon_unequipped(weapon)

# ========== REFERENCIAS ==========
var health_component = null
var animated_sprite: AnimatedSprite2D = null
var health_bar_container: Node2D = null
var attack_manager = null
var game_manager = null

# ========== ESTADÍSTICAS BASE ==========
@export var move_speed: float = 220.0
@export var pickup_radius: float = 64.0
@export var hp: int = 100
@export var max_hp: int = 100
@export var armor: int = 0
@export var magnet: float = 1.0

# ========== CONFIGURACIÓN VISUAL ==========
@export var player_sprite_scale: float = 0.25
var last_dir: String = "down"

# ========== CARACTERIZACIÓN (Sobrescribir en subclases) ==========
var character_class: String = "BasePlayer"  # Sobrescribir en subclases: "Wizard", "Rogue", etc.
var character_sprites_key: String = "wizard"  # Sobrescribir en subclases

# ========== CICLO DE VIDA ==========

func _ready() -> void:
	"""Inicialización del personaje"""
	print("[%s] Inicializando %s en posición: %s" % [character_class, character_class, global_position])
	
	# Posicionar en el centro
	global_position = Vector2.ZERO
	
	# Inicializar componentes
	_initialize_health_component()
	_initialize_visual()
	_initialize_physics()
	
	# Crear barra de vida
	create_health_bar()
	
	# Encontrar referencias globales
	_find_global_managers()
	
	# Conectar armas una vez que todo esté listo
	_setup_weapons_deferred()
	
	z_index = 50
	print("[%s] ✓ Inicialización completada" % character_class)

func _initialize_health_component() -> void:
	"""Crear e inicializar componente de salud"""
	var hc_script = load("res://scripts/components/HealthComponent.gd")
	if hc_script:
		health_component = hc_script.new()
		health_component.name = "HealthComponent"
		add_child(health_component)
		health_component.initialize(max_hp)
		
		# Conectar señales
		if health_component.has_signal("health_changed"):
			health_component.health_changed.connect(_on_health_changed)
		if health_component.has_signal("died"):
			health_component.died.connect(_on_health_died)
		
		print("[%s] ✓ Health component inicializado (HP: %d/%d)" % [character_class, hp, max_hp])
	else:
		print("[%s] ⚠️ No se pudo cargar HealthComponent" % character_class)

func _initialize_visual() -> void:
	"""Inicializar sprite y animaciones"""
	# Obtener calibración visual
	var visual_calibrator = null
	var _gt = get_tree()
	if _gt and _gt.root:
		visual_calibrator = _gt.root.get_node_or_null("VisualCalibrator")
	
	var scale_to_apply = player_sprite_scale
	if visual_calibrator:
		scale_to_apply = visual_calibrator.get_player_scale()
	
	# Obtener sprite de la escena o crear uno nuevo
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		add_child(animated_sprite)
	
	# Configurar sprite
	if animated_sprite:
		animated_sprite.scale = Vector2(scale_to_apply, scale_to_apply)
		animated_sprite.centered = true
		animated_sprite.speed_scale = 6.0
		
		# Configurar animaciones (subclases deben sobrescribir _setup_animations)
		_setup_animations()
		
		if animated_sprite.sprite_frames:
			animated_sprite.play()
		
		print("[%s] ✓ Sprite configurado: escala=%.3f" % [character_class, scale_to_apply])

func _setup_animations() -> void:
	"""Configurar animaciones del personaje - SOBRESCRIBIR EN SUBCLASES"""
	# Implementación por defecto vacía
	# Las subclases deben sobrescribir este método
	print("[%s] ⚠️ _setup_animations() no implementado en subclase" % character_class)

func _initialize_physics() -> void:
	"""Configurar física del personaje"""
	set_physics_process(true)
	set_collision_layer_value(1, true)   # Capa player
	set_collision_mask_value(2, true)    # Enemigos
	set_collision_mask_value(4, true)    # Proyectiles enemigos
	set_collision_mask_value(5, true)    # Pickups
	
	print("[%s] ✓ Física configurada" % character_class)

func _find_global_managers() -> void:
	"""Encontrar referencias a managers globales"""
	var _gt = get_tree()
	if not _gt or not _gt.root:
		print("[%s] ⚠️ No se pudo acceder a tree" % character_class)
		return
	
	# Buscar GameManager
	game_manager = _gt.root.get_node_or_null("GameManager")
	if not game_manager:
		game_manager = _gt.root.get_node_or_null("SpellloopGame/GameManager")
	
	# Buscar o crear AttackManager
	attack_manager = _gt.root.get_node_or_null("AttackManager")
	if not attack_manager and game_manager:
		attack_manager = game_manager.get_node_or_null("AttackManager")
	
	print("[%s] GameManager: %s | AttackManager: %s" % [
		character_class,
		"✓" if game_manager else "✗",
		"✓" if attack_manager else "✗"
	])

func _setup_weapons_deferred() -> void:
	"""Configurar armas después de que todo esté listo"""
	# Usar await para asegurar que todo esté inicializado
	await get_tree().process_frame
	
	if attack_manager:
		attack_manager.initialize(self)
		print("[%s] ✓ AttackManager inicializado" % character_class)
		
		# Las subclases deben sobrescribir _equip_starting_weapons()
		_equip_starting_weapons()
	else:
		print("[%s] ⚠️ AttackManager no disponible" % character_class)

func _equip_starting_weapons() -> void:
	"""Equipar armas iniciales - SOBRESCRIBIR EN SUBCLASES"""
	# Implementación por defecto vacía
	print("[%s] ⚠️ _equip_starting_weapons() no implementado en subclase" % character_class)

# ========== MOVIMIENTO ==========

func _process(delta: float) -> void:
	"""Actualizar animación según dirección de movimiento"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	# Obtener input del jugador
	var input_manager = get_tree().root.get_node_or_null("InputManager")
	if not input_manager:
		return
	
	var movement_input_vec = input_manager.get_movement_vector()
	
	# Si no hay movimiento, mantener la dirección anterior
	if movement_input_vec.length() == 0:
		return
	
	# Determinar dirección basada en input
	var abs_x = abs(movement_input_vec.x)
	var abs_y = abs(movement_input_vec.y)
	var new_dir = last_dir
	
	# Priorizar input en Y si es significativo
	if abs_y > abs_x * 0.5:
		if movement_input_vec.y < 0:
			new_dir = "up"
		elif movement_input_vec.y > 0:
			new_dir = "down"
	else:
		if movement_input_vec.x < 0:
			new_dir = "left"
		elif movement_input_vec.x > 0:
			new_dir = "right"
	
	# Solo cambiar animación si es diferente
	if new_dir != last_dir:
		last_dir = new_dir
		var animation_name = "idle_%s" % last_dir
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.animation = animation_name
			animated_sprite.play()

func _physics_process(delta: float) -> void:
	"""Actualizar física y movimiento"""
	if not is_instance_valid(self):
		return
	
	# El mundo se mueve, el player queda centrado
	velocity = Vector2.ZERO
	move_and_slide()

# ========== SALUD Y DAÑO ==========

func take_damage(amount: int) -> void:
	"""Recibir daño"""
	if health_component:
		health_component.take_damage(amount)
		print("[%s] Daño recibido: %d (HP: %d/%d)" % [character_class, amount, health_component.current_health, max_hp])
	else:
		print("[%s] ⚠️ HealthComponent no disponible" % character_class)

func heal(amount: int) -> void:
	"""Curar al personaje"""
	if health_component:
		health_component.heal(amount)
		print("[%s] Curación: +%d (HP: %d/%d)" % [character_class, amount, health_component.current_health, max_hp])

func _on_health_changed(current: int, max_val: int) -> void:
	"""Callback cuando la salud cambia"""
	hp = current
	player_damaged.emit(current, max_val)

func _on_health_died() -> void:
	"""Callback cuando el personaje muere"""
	print("[%s] ✗ Personaje muerto" % character_class)
	player_died.emit()

# ========== EQUIPAMIENTO DE ARMAS ==========

func equip_weapon(weapon) -> bool:
	"""Equipar un arma"""
	if not attack_manager:
		print("[%s] ⚠️ AttackManager no disponible" % character_class)
		return false
	
	if not weapon:
		print("[%s] ⚠️ Intento de equipar arma nula" % character_class)
		return false
	
	attack_manager.add_weapon(weapon)
	weapon_equipped.emit(weapon)
	print("[%s] ⚔️ Arma equipada: %s" % [character_class, weapon.name])
	return true

func unequip_weapon(weapon) -> bool:
	"""Desequipar un arma"""
	if not attack_manager:
		return false
	
	attack_manager.remove_weapon(weapon)
	weapon_unequipped.emit(weapon)
	return true

# ========== INFORMACIÓN Y ESTADÍSTICAS ==========

func get_stats() -> Dictionary:
	"""Obtener estadísticas del personaje"""
	return {
		"class": character_class,
		"hp": hp,
		"max_hp": max_hp,
		"armor": armor,
		"move_speed": move_speed,
		"pickup_radius": pickup_radius,
		"magnet": magnet,
		"weapons": attack_manager.get_weapon_count() if attack_manager else 0
	}

func get_info() -> Dictionary:
	"""Obtener información completa del personaje"""
	return {
		"class": character_class,
		"position": global_position,
		"hp": hp,
		"max_hp": max_hp,
		"armor": armor,
		"move_speed": move_speed,
		"stats": get_stats()
	}

func create_health_bar() -> void:
	"""Crear barra de vida - SOBRESCRIBIR EN SUBCLASES SI NECESARIO"""
	if not health_bar_container:
		health_bar_container = Node2D.new()
		health_bar_container.name = "HealthBarContainer"
		add_child(health_bar_container)
		
		var bg_bar = ColorRect.new()
		bg_bar.size = Vector2(40, 4)
		bg_bar.color = Color(0.3, 0.3, 0.3, 0.8)
		bg_bar.position = Vector2(-20, -35)
		health_bar_container.add_child(bg_bar)
		
		var health_bar = ColorRect.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(40, 4)
		health_bar.color = Color(0.0, 1.0, 0.0, 0.9)
		health_bar.position = Vector2(-20, -35)
		health_bar_container.add_child(health_bar)
	
	update_health_bar()

func update_health_bar() -> void:
	"""Actualizar la barra de vida"""
	if not health_bar_container:
		return
	
	var health_bar = health_bar_container.get_node_or_null("HealthBar")
	if health_bar:
		var health_percent = float(hp) / float(max_hp)
		health_bar.size.x = 40.0 * health_percent
