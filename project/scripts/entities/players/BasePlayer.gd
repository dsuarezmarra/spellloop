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
@export var base_move_speed: float = 220.0  # Velocidad original sin debuffs
@export var pickup_radius: float = 64.0
@export var hp: int = 100
@export var max_hp: int = 100
@export var armor: int = 0
@export var magnet: float = 1.0

# ========== SISTEMA DE DEBUFFS ==========
# Slow
var _slow_timer: float = 0.0
var _slow_amount: float = 0.0  # 0.0 - 1.0 (porcentaje de reducción)
var _is_slowed: bool = false

# Burn (DoT de fuego)
var _burn_timer: float = 0.0
var _burn_damage: float = 0.0
var _burn_tick_timer: float = 0.0
const BURN_TICK_INTERVAL: float = 0.5

# Poison (DoT veneno, menor daño pero más duración)
var _poison_timer: float = 0.0
var _poison_damage: float = 0.0
var _poison_tick_timer: float = 0.0
const POISON_TICK_INTERVAL: float = 1.0

# Stun (paralizado)
var _stun_timer: float = 0.0
var _is_stunned: bool = false

# Weakness (más daño recibido)
var _weakness_timer: float = 0.0
var _weakness_amount: float = 0.0  # % extra de daño recibido
var _is_weakened: bool = false

# Curse (reduce curación)
var _curse_timer: float = 0.0
var _curse_amount: float = 0.0  # % reducción de curación
var _is_cursed: bool = false

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
	
	# Añadir al grupo "player" para que otros sistemas puedan encontrarnos
	add_to_group("player")
	
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
	set_collision_mask_value(8, true)    # Barreras de zona
	
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
	"""Actualizar física y debuffs"""
	# El movimiento se maneja en SpellloopPlayer para evitar duplicación
	_process_debuffs(delta)

func _process_debuffs(delta: float) -> void:
	"""Procesar todos los debuffs activos"""
	# Slow
	if _slow_timer > 0:
		_slow_timer -= delta
		if _slow_timer <= 0:
			_clear_slow()
	
	# Burn (daño por tick)
	if _burn_timer > 0:
		_burn_timer -= delta
		_burn_tick_timer -= delta
		if _burn_tick_timer <= 0:
			_apply_burn_tick()
			_burn_tick_timer = BURN_TICK_INTERVAL
		if _burn_timer <= 0:
			_clear_burn()
	
	# Poison (daño por tick)
	if _poison_timer > 0:
		_poison_timer -= delta
		_poison_tick_timer -= delta
		if _poison_tick_timer <= 0:
			_apply_poison_tick()
			_poison_tick_timer = POISON_TICK_INTERVAL
		if _poison_timer <= 0:
			_clear_poison()
	
	# Stun
	if _stun_timer > 0:
		_stun_timer -= delta
		if _stun_timer <= 0:
			_clear_stun()
	
	# Weakness
	if _weakness_timer > 0:
		_weakness_timer -= delta
		if _weakness_timer <= 0:
			_clear_weakness()
	
	# Curse
	if _curse_timer > 0:
		_curse_timer -= delta
		if _curse_timer <= 0:
			_clear_curse()

# ========== SALUD Y DAÑO ==========

func take_damage(amount: int) -> void:
	"""Recibir daño (aplica weakness si está activo)"""
	if health_component:
		var final_damage = amount
		# Aplicar weakness si está activo
		if _is_weakened:
			final_damage = int(amount * (1.0 + _weakness_amount))
		health_component.take_damage(final_damage)
		print("[%s] Daño recibido: %d (HP: %d/%d)%s" % [character_class, final_damage, health_component.current_health, max_hp, " [WEAKENED]" if _is_weakened else ""])
	else:
		print("[%s] ⚠️ HealthComponent no disponible" % character_class)

func heal(amount: int) -> void:
	"""Curar al personaje (aplica curse si está activo)"""
	if health_component:
		var old_hp = health_component.current_health
		var final_heal = amount
		# Aplicar curse si está activo
		if _is_cursed:
			final_heal = int(amount * (1.0 - _curse_amount))
		health_component.heal(final_heal)
		var healed = health_component.current_health - old_hp
		
		# Mostrar texto flotante de curación si realmente curó algo
		if healed > 0:
			FloatingText.spawn_heal(global_position + Vector2(0, -30), healed)
			_spawn_heal_particles()
		
		print("[%s] Curación: +%d (HP: %d/%d)%s" % [character_class, healed, health_component.current_health, max_hp, " [CURSED]" if _is_cursed else ""])

func _spawn_heal_particles() -> void:
	"""Crear partículas de curación verde"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 8
	particles.lifetime = 0.6
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, -20)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.3, 1.0, 0.4, 0.9)
	
	add_child(particles)
	
	# Auto-destruir después de que terminen las partículas
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
	)

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

# ========== SISTEMA DE DEBUFFS - APLICACIÓN ==========

func apply_slow(amount: float, duration: float) -> void:
	"""Aplicar slow al jugador (reduce velocidad)"""
	_slow_amount = clamp(amount, 0.0, 0.8)  # Máximo 80% slow
	_slow_timer = max(_slow_timer, duration)
	_is_slowed = true
	move_speed = base_move_speed * (1.0 - _slow_amount)
	print("[%s] ❄️ Ralentizado %.0f%% por %.1fs" % [character_class, _slow_amount * 100, duration])

func _clear_slow() -> void:
	_is_slowed = false
	_slow_amount = 0.0
	move_speed = base_move_speed
	print("[%s] ❄️ Slow terminado" % character_class)

func apply_burn(damage_per_tick: float, duration: float) -> void:
	"""Aplicar burn al jugador (DoT de fuego)"""
	_burn_damage = damage_per_tick
	_burn_timer = max(_burn_timer, duration)
	_burn_tick_timer = BURN_TICK_INTERVAL
	print("[%s] 🔥 Quemándose por %.1f daño/tick durante %.1fs" % [character_class, damage_per_tick, duration])

func _apply_burn_tick() -> void:
	if health_component:
		var dmg = int(_burn_damage)
		health_component.take_damage(dmg)
		# Efecto visual de burn
		_spawn_burn_particle()

func _clear_burn() -> void:
	_burn_damage = 0.0
	print("[%s] 🔥 Burn terminado" % character_class)

func _spawn_burn_particle() -> void:
	"""Partícula de fuego cuando está quemándose"""
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.one_shot = true
	particle.amount = 4
	particle.lifetime = 0.4
	particle.direction = Vector2(0, -1)
	particle.spread = 30.0
	particle.gravity = Vector2(0, -50)
	particle.initial_velocity_min = 20.0
	particle.initial_velocity_max = 40.0
	particle.scale_amount_min = 2.0
	particle.scale_amount_max = 4.0
	particle.color = Color(1.0, 0.4, 0.1, 0.9)
	add_child(particle)
	get_tree().create_timer(0.6).timeout.connect(func():
		if is_instance_valid(particle): particle.queue_free()
	)

func apply_poison(damage_per_tick: float, duration: float) -> void:
	"""Aplicar poison al jugador (DoT más lento pero más largo)"""
	_poison_damage = damage_per_tick
	_poison_timer = max(_poison_timer, duration)
	_poison_tick_timer = POISON_TICK_INTERVAL
	print("[%s] ☠️ Envenenado por %.1f daño/tick durante %.1fs" % [character_class, damage_per_tick, duration])

func _apply_poison_tick() -> void:
	if health_component:
		var dmg = int(_poison_damage)
		health_component.take_damage(dmg)
		_spawn_poison_particle()

func _clear_poison() -> void:
	_poison_damage = 0.0
	print("[%s] ☠️ Poison terminado" % character_class)

func _spawn_poison_particle() -> void:
	"""Partícula de veneno"""
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.one_shot = true
	particle.amount = 3
	particle.lifetime = 0.5
	particle.direction = Vector2(0, -1)
	particle.spread = 45.0
	particle.gravity = Vector2(0, -20)
	particle.initial_velocity_min = 15.0
	particle.initial_velocity_max = 30.0
	particle.scale_amount_min = 2.0
	particle.scale_amount_max = 3.0
	particle.color = Color(0.6, 0.2, 0.8, 0.8)  # Morado para no confundir con lifesteal
	add_child(particle)
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(particle): particle.queue_free()
	)

func apply_stun(duration: float) -> void:
	"""Aplicar stun al jugador (paralizado)"""
	_stun_timer = max(_stun_timer, duration)
	_is_stunned = true
	print("[%s] ⚡ Aturdido por %.1fs" % [character_class, duration])

func _clear_stun() -> void:
	_is_stunned = false
	print("[%s] ⚡ Stun terminado" % character_class)

func apply_weakness(amount: float, duration: float) -> void:
	"""Aplicar weakness al jugador (recibe más daño)"""
	_weakness_amount = clamp(amount, 0.0, 1.0)  # Máximo +100% daño
	_weakness_timer = max(_weakness_timer, duration)
	_is_weakened = true
	print("[%s] 💀 Debilitado +%.0f%% daño recibido por %.1fs" % [character_class, _weakness_amount * 100, duration])

func _clear_weakness() -> void:
	_is_weakened = false
	_weakness_amount = 0.0
	print("[%s] 💀 Weakness terminado" % character_class)

func apply_curse(amount: float, duration: float) -> void:
	"""Aplicar curse al jugador (reduce curación)"""
	_curse_amount = clamp(amount, 0.0, 0.9)  # Máximo -90% curación
	_curse_timer = max(_curse_timer, duration)
	_is_cursed = true
	print("[%s] 👻 Maldito -%.0f%% curación por %.1fs" % [character_class, _curse_amount * 100, duration])

func _clear_curse() -> void:
	_is_cursed = false
	_curse_amount = 0.0
	print("[%s] 👻 Curse terminado" % character_class)

func is_stunned() -> bool:
	return _is_stunned

func is_slowed() -> bool:
	return _is_slowed

func get_current_speed() -> float:
	"""Devuelve la velocidad actual considerando debuffs"""
	return move_speed