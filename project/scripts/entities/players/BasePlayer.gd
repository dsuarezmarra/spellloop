# BasePlayer.gd
# Clase base genérica para todos los personajes jugables
# Proporciona movimiento, stats, salud, manejo de armas, etc.
# Las clases específicas (Wizard, Rogue, etc.) heredan de aquí

extends CharacterBody2D
class_name BasePlayer
# BasePlayer class definition

# ========== SEÑALES ==========
signal player_damaged(amount: int, current_hp: int)
signal health_changed(current_hp: int, max_hp: int) # REQUIRED by GameHUD
signal player_took_damage(damage: int, element: String)  # Para efectos de feedback visual
signal player_died
signal weapon_equipped(weapon)
signal weapon_unequipped(weapon)

# ========== REFERENCIAS ==========
var health_component = null
var animated_sprite: AnimatedSprite2D = null
var health_bar_container: Node2D = null
var attack_manager = null
var game_manager = null
var _damage_flash_tween: Tween = null

# ========== ESTADÍSTICAS BASE ==========
@export var move_speed: float = 100.0
@export var base_move_speed: float = 100.0  # Velocidad original sin debuffs
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

# I-Frames (Invulnerabilidad temporal post-daño)
var _invulnerability_timer: float = 0.0
var _revive_immunity_timer: float = 0.0  # Added to prevent Nil crash

# ========== REGENERACIÓN ==========
var _regen_accumulator: float = 0.0
var _player_stats_ref: Node = null

# ========== PHASE 11: FAIRNESS OPS ==========
var _damage_queue: Array = []
var _frame_damage_scheduled: bool = false
var _last_hit_context: Dictionary = {}

# Death Tracking: Ring buffer of recent damage events (last 5 seconds)
const DAMAGE_BUFFER_DURATION_S: float = 5.0
var _damage_ring_buffer: Array = []


# ========== SISTEMA VISUAL DE DEBUFFS ==========
var _status_visual_node: Node2D = null
var _status_aura_timer: float = 0.0
var _status_flash_timer: float = 0.0
const STATUS_FLASH_INTERVAL: float = 0.15
const STATUS_AURA_PULSE_SPEED: float = 4.0

# ========== VFX PERSISTENTES (VFXManager) ==========
var _stun_vfx: Node = null
var _slow_vfx: Node = null
var _shield_vfx: Node = null

# ========== SISTEMA DE ICONOS DE ESTADO ==========
var status_icon_display: StatusIconDisplay = null

# ========== CONFIGURACIÓN VISUAL ==========
@export var player_sprite_scale: float = 1.0  # Escala del sprite
var last_dir: String = "down"
var _is_dying: bool = false  # Flag para evitar acciones durante la muerte
var _is_casting: bool = false  # Flag para animación de cast

# ========== CARACTERIZACIÓN (Sobrescribir en subclases) ==========
var character_class: String = "BasePlayer"  # Sobrescribir en subclases: "Wizard", "Rogue", etc.
var character_sprites_key: String = "wizard"  # Sobrescribir en subclases

# ========== CICLO DE VIDA ==========

var _turret_timer: float = 0.0
var _turret_active: bool = false

func _ready() -> void:
	"""Inicialización del personaje"""
	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Debug desactivado: print("[%s] Inicializando %s en posición: %s" % [character_class, character_class, global_position])

	# Añadir al grupo "player" para que otros sistemas puedan encontrarnos
	add_to_group("player")

	# Posicionar en el centro
	global_position = Vector2.ZERO

	# Inicializar componentes
	_initialize_health_component()
	_initialize_visual()
	_initialize_physics()
	_initialize_status_visual()

	# Crear barra de vida
	create_health_bar()

	# Encontrar referencias globales
	_find_global_managers()

	# Conectar armas una vez que todo esté listo
	_setup_weapons_deferred()

	# Sincronizar stats iniciales
	var stats = get_tree().get_first_node_in_group("player_stats")
	if stats and stats.has_method("get_stat"):
		pickup_radius = stats.get_stat("pickup_range")
		_update_pickup_area_size()

	z_index = 50
	# Debug desactivado: print("[%s] ✓ Inicialización completada" % character_class)

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
		if health_component.has_signal("damaged"):
			health_component.damaged.connect(_on_health_damaged)


		# Sincronizar Max HP desde PlayerStats si ya existe y es diferente
		var stats = get_tree().get_first_node_in_group("player_stats")
		if stats and stats.has_method("get_stat"):
			var stats_max = stats.get_stat("max_health")
			if stats_max > 0 and stats_max != max_hp:
				max_hp = maxi(1, int(stats_max))
				health_component.set_max_health(max_hp)
				# Debug desactivado: print("[%s] Sincronizado Max HP con PlayerStats: %d" % [character_class, max_hp])

		# Debug desactivado: print("[%s] ✓ Health component inicializado (HP: %d/%d)" % [character_class, hp, max_hp])
	else:
		push_warning("[%s] No se pudo cargar HealthComponent" % character_class)






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

		# Debug desactivado: print("[%s] ✓ Sprite configurado: escala=%.3f" % [character_class, scale_to_apply])

func _setup_animations() -> void:
	"""Configurar animaciones del personaje - SOBRESCRIBIR EN SUBCLASES"""
	# Implementación por defecto vacía
	# Las subclases deben sobrescribir este método
	# Debug desactivado: print("[%s] ⚠️ _setup_animations() no implementado en subclase" % character_class)

func _initialize_physics() -> void:
	"""Configurar física del personaje"""
	set_physics_process(true)
	set_collision_layer_value(1, true)   # Capa player
	set_collision_mask_value(2, true)    # Enemigos
	set_collision_mask_value(4, true)    # Proyectiles enemigos
	set_collision_mask_value(5, true)    # Pickups
	set_collision_mask_value(8, true)    # Barreras de zona

	# Ajustar Hitbox (Request de usuario: agrandar hitbox)
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape and col_shape.shape:
		if col_shape.shape is CircleShape2D:
			col_shape.shape.radius = 15.0 # Aumentado de default (10) a 15
		elif col_shape.shape is CapsuleShape2D:
			col_shape.shape.radius = 15.0
			col_shape.shape.height = 42.0
		# print("[Player] Hitbox size increased")

	# Debug desactivado: print("[%s] ✓ Física configurada" % character_class)

func _find_global_managers() -> void:
	"""Encontrar referencias a managers globales"""
	var _gt = get_tree()
	if not _gt or not _gt.root:
		push_warning("[%s] No se pudo acceder a tree" % character_class)
		return

	# Buscar GameManager
	game_manager = _gt.root.get_node_or_null("GameManager")
	if not game_manager:
		game_manager = _gt.root.get_node_or_null("LoopiaLikeGame/GameManager")

	# Buscar o crear AttackManager
	attack_manager = _gt.root.get_node_or_null("AttackManager")
	if not attack_manager and game_manager:
		attack_manager = game_manager.get_node_or_null("AttackManager")

	# Conectar señales de PlayerStats para actualizar la barra de vida/escudo
	_player_stats_ref = _gt.get_first_node_in_group("player_stats")
	if _player_stats_ref and _player_stats_ref.has_signal("stat_changed"):
		if not _player_stats_ref.stat_changed.is_connected(_on_stats_changed_signal):
			_player_stats_ref.stat_changed.connect(_on_stats_changed_signal)

	# Debug desactivado: print("[%s] GameManager: %s | AttackManager: %s" % [character_class, "✓" if game_manager else "✗", "✓" if attack_manager else "✗"])

func _on_stats_changed_signal(stat_name, _old, new_val):
	if stat_name == "max_health" and health_component:
		max_hp = int(new_val)
		health_component.set_max_health(max_hp)
		# Emitir cambio para actualizar UI
		health_changed.emit(health_component.current_health, max_hp)

	elif stat_name == "pickup_range":
		pickup_radius = new_val
		_update_pickup_area_size()

	elif stat_name == "shield_amount" or stat_name == "max_shield":
		# Actualizar barra de vida y VFX de escudo
		update_health_bar()
		_update_shield_vfx(new_val if stat_name == "shield_amount" else _old)

func _setup_weapons_deferred() -> void:
	"""Configurar armas después de que todo esté listo"""
	# Verificación de seguridad: el nodo debe estar en el árbol
	if not is_inside_tree():
		return

	var tree = get_tree()
	if not tree:
		return

	# Usar await para asegurar que todo esté inicializado
	await tree.process_frame

	# Verificar de nuevo tras el await (el nodo podría haber sido eliminado)
	if not is_inside_tree() or not attack_manager:
		return

	if attack_manager:
		attack_manager.initialize(self)
		# Debug desactivado: print("[%s] ✓ AttackManager inicializado" % character_class)

		# Las subclases deben sobrescribir _equip_starting_weapons()
		_equip_starting_weapons()
	else:
		push_warning("[%s] AttackManager no disponible" % character_class)

func _equip_starting_weapons() -> void:
	"""Equipar armas iniciales - SOBRESCRIBIR EN SUBCLASES"""
	# Implementación por defecto vacía
	# Debug desactivado: print("[%s] ⚠️ _equip_starting_weapons() no implementado en subclase" % character_class)

# ========== MOVIMIENTO ==========

var _is_moving: bool = false

var _slow_aura_timer: float = 0.0
var _stationary_timer: float = 0.0  # Para la mejora "Torreta"
var _turret_buff_active: bool = false

func _process(delta: float) -> void:
	"""Actualizar lógica por frame (Animación + Regeneración)"""

	# DUPLICATE REGEN LOGIC REMOVED
	# La regeneración ahora es gestionada exclusivamente por PlayerStats.gd para evitar doble curación
	# y asegurar centralización de la lógica.

	# === ENEMY SLOW AURA ===
	# Aplicar ralentización pasiva a enemigos cercanos si tenemos el stat
	_slow_aura_timer -= delta
	if _slow_aura_timer <= 0:
		_apply_enemy_slow_aura()
		_slow_aura_timer = 0.5  # Revisar cada 0.5s



	# === LÓGICA TORRETA (Item 19) ===
	_update_turret_logic(delta, _is_moving)

	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	# NO interrumpir animaciones especiales (cast, hit, death)
	if _is_casting or _is_dying:
		return

	# Obtener input del jugador
	var input_manager = get_tree().root.get_node_or_null("InputManager")
	if not input_manager:
		return

	# Procesar movimiento (input)
	if not _is_dying:
		# IMPORTANTE: El movimiento real se maneja en LoopiaLikePlayer.gd (wrapper)
		# para evitar conflictos de posición física vs visual.
		# BasePlayer solo actualiza su estado interno si es necesario.
		pass

		# NO LLAMAR move_and_slide() AQUÍ si usamos LoopiaLikePlayer wrapper

		# -----------------------------------------------------------

		# -----------------------------------------------------------
		# LÓGICA DE NUEVOS OBJETOS (Phase 4)
		# 19. Torreta (Tower): Buffs si quieto > 2s
		var player_stats = _get_player_stats()
		if player_stats and player_stats.has_method("get_stat") and player_stats.get_stat("turret_mode_enabled") > 0:
			if velocity.length() < 10.0:
				_turret_timer += delta
				if _turret_timer >= 2.0 and not _turret_active:
					_turret_active = true
					# Activar buffs (simulado con modificadores temporales o stats directos)
					# Por ahora solo feedback visual y asumimos que PlayerStats checkea _turret_active
					# O aplicamos buff aquí
					FloatingText.spawn_text(global_position + Vector2(0, -70), "TURRET MODE!", Color.GREEN)
					# Modificar stats dinámicamente si es posible, o usar flag en PlayerStats
					if player_stats.has_method("add_temporary_modifier"):
						# ID, Stat, ValueMs, Duration (0=infinite until removed)
						# Pero temp modifiers suelen tener duración.
						# Mejor: PlayerStats lee una variable nuestra o nosotros seteamos un flag en PlayerStats
						if "is_turret_mode" in player_stats:
							player_stats.is_turret_mode = true
			else:
				_turret_timer = 0.0
				if _turret_active:
					_turret_active = false
					if player_stats and "is_turret_mode" in player_stats:
						player_stats.is_turret_mode = false
		# -----------------------------------------------------------
	var movement_input_vec = input_manager.get_movement_vector()
	var is_moving_now = movement_input_vec.length() > 0.1

	# Determinar dirección basada en input
	var new_dir = last_dir
	if is_moving_now:
		var abs_x = abs(movement_input_vec.x)
		var abs_y = abs(movement_input_vec.y)

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

	# Decidir animación: walk si se mueve, idle si está quieto
	var animation_prefix = "walk_" if is_moving_now else "idle_"
	var animation_name = animation_prefix + new_dir

	# Solo cambiar si la animación es diferente o si el estado de movimiento cambió
	var should_change = (new_dir != last_dir) or (is_moving_now != _is_moving)

	if should_change:
		last_dir = new_dir
		_is_moving = is_moving_now
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.animation = animation_name
			animated_sprite.play()

	"""Actualizar física y debuffs"""
	# Debug LOGS
	# print("DEBUG: _revive_immunity_timer=", _revive_immunity_timer, " type=", typeof(_revive_immunity_timer))

	# Procesar timers de inmunidad (solo _invulnerability_timer aquí,
	# _revive_immunity_timer se gestiona en _update_revive_immunity)
	if _invulnerability_timer > 0:
		_invulnerability_timer -= delta

	# El movimiento se maneja en LoopiaLikePlayer para evitar duplicación
	_process_debuffs(delta)
	_update_status_visuals(delta)
	_update_revive_immunity(delta)

	# Actualizar barras visuales (vida y escudo)
	_update_shield_bar()
	update_health_bar()





func _get_player_stats() -> Node:
	if game_manager and game_manager.player_stats:
		return game_manager.player_stats
	return get_tree().get_first_node_in_group("player_stats")




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

func _initialize_status_visual() -> void:
	"""Inicializar nodo para efectos visuales de estado"""
	_status_visual_node = Node2D.new()
	_status_visual_node.name = "StatusVisuals"
	_status_visual_node.z_index = 5
	add_child(_status_visual_node)
	_status_visual_node.draw.connect(_draw_status_effects)

	# Inicializar sistema de iconos de estado
	_initialize_status_icon_display()

func _initialize_status_icon_display() -> void:
	"""Inicializar display de iconos de estado (buffs/debuffs)"""
	status_icon_display = StatusIconDisplay.new()
	status_icon_display.name = "StatusIconDisplay"
	status_icon_display.is_player = true
	status_icon_display.set_entity_type(true, false)
	add_child(status_icon_display)

	# Posicionar después de que el sprite esté completamente cargado
	call_deferred("_position_player_status_icons")

func _position_player_status_icons() -> void:
	"""Posicionar los iconos de estado encima de la barra de vida del jugador"""
	if not status_icon_display:
		return

	# Obtener la escala del sprite
	var sprite_scale = player_sprite_scale
	var visual_calibrator = get_tree().root.get_node_or_null("VisualCalibrator") if get_tree() else null
	if visual_calibrator and visual_calibrator.has_method("get_player_scale"):
		sprite_scale = visual_calibrator.get_player_scale()

	# Calcular la parte superior del sprite
	var sprite_visual_top: float = -32.0  # Fallback

	if animated_sprite and is_instance_valid(animated_sprite):
		var frame_height: float = 0.0
		# Intentar obtener altura del frame actual
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.get_frame_count("default") > 0:
			var frame_texture = animated_sprite.sprite_frames.get_frame_texture("default", 0)
			if frame_texture:
				frame_height = frame_texture.get_height()
		elif animated_sprite.sprite_frames and animated_sprite.animation:
			var anim = animated_sprite.animation
			if animated_sprite.sprite_frames.get_frame_count(anim) > 0:
				var frame_texture = animated_sprite.sprite_frames.get_frame_texture(anim, 0)
				if frame_texture:
					frame_height = frame_texture.get_height()

		if frame_height > 0:
			var visual_height = frame_height * animated_sprite.scale.y
			sprite_visual_top = -(visual_height / 2.0)
		else:
			# Fallback basado en escala típica
			sprite_visual_top = -40.0 * sprite_scale
	else:
		# Fallback basado en escala
		sprite_visual_top = -40.0 * sprite_scale

	# La barra de vida está en: bar_offset_y = -30.0 - (sprite_scale * 40.0)
	# Los iconos van encima de la barra (4px alto) + margen (4px) + mitad icono (12px)
	var bar_offset_y = -30.0 - (sprite_scale * 40.0)
	# Usar el punto más alto entre el sprite top y la barra
	var icon_top = min(sprite_visual_top, bar_offset_y) - 20.0
	status_icon_display.position.y = icon_top

func _update_status_visuals(delta: float) -> void:
	"""Actualizar efectos visuales de debuffs"""
	_status_aura_timer += delta * STATUS_AURA_PULSE_SPEED
	_status_flash_timer += delta

	# Parpadeo del sprite según estado
	if _status_flash_timer >= STATUS_FLASH_INTERVAL:
		_status_flash_timer = 0.0
		_apply_status_flash()

	# Redibujar auras (incluyendo aura de revive dorada)
	if _status_visual_node and (_has_any_status() or _has_revive_available()):
		_status_visual_node.queue_redraw()

func _has_any_status() -> bool:
	"""Verificar si tiene algún estado activo"""
	return _burn_timer > 0 or _slow_timer > 0 or _poison_timer > 0 or _stun_timer > 0 or _weakness_timer > 0 or _curse_timer > 0

func _has_revive_available() -> bool:
	"""Verificar si tiene revives disponibles (para aura dorada)"""
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		return int(player_stats.get_stat("revives")) > 0
	return false

func _apply_status_flash() -> void:
	"""Aplicar parpadeo al sprite según estados activos"""
	if not animated_sprite:
		return

	# Color base
	var flash_color = Color.WHITE
	var should_flash = false

	# Prioridad de colores (el más reciente se muestra)
	if _stun_timer > 0:
		flash_color = Color(1.0, 1.0, 0.5, 1.0)  # Amarillo stun
		should_flash = true
	elif _burn_timer > 0:
		flash_color = Color(1.0, 0.7, 0.4, 1.0)  # Naranja fuego
		should_flash = true
	elif _poison_timer > 0:
		flash_color = Color(0.7, 1.0, 0.5, 1.0)  # Verde veneno
		should_flash = true
	elif _slow_timer > 0:
		flash_color = Color(0.6, 0.8, 1.0, 1.0)  # Azul hielo
		should_flash = true
	elif _weakness_timer > 0:
		flash_color = Color(0.85, 0.7, 0.9, 1.0)  # Lavanda suave weakness
		should_flash = true
	elif _curse_timer > 0:
		flash_color = Color(0.75, 0.65, 0.8, 1.0)  # Lavanda oscuro curse
		should_flash = true

	if should_flash:
		# Alternar entre color de estado y blanco - flash MÁS corto
		var pulse = sin(_status_aura_timer * 4.0)
		if pulse > 0.3:
			animated_sprite.modulate = flash_color
		else:
			animated_sprite.modulate = Color.WHITE
	else:
		animated_sprite.modulate = Color.WHITE

func _draw_status_effects() -> void:
	"""Dibujar auras y efectos visuales de estado"""
	# Visuales de status se manejan ahora via VFXManager (stun, slow, shield aura).
	pass

# ========== SALUD Y DAÑO ==========

var _last_damage_element: String = "physical"

func take_damage(amount: int, element: String = "physical", attacker: Node = null) -> void:
	"""Recibir daño (aplica inmunidad, shield, dodge, armor, weakness y thorns)"""
	_last_damage_element = element
	if not health_component:
		push_warning("[%s] HealthComponent no disponible" % character_class)
		return

	# No recibir daño si ya está muerto o muriendo
	if not health_component.is_alive or _is_dying:
		return

	# 0. Verificar inmunidad de revive o frames de invulnerabilidad (i-frames)
	if _revive_immunity_timer > 0 or _invulnerability_timer > 0:
		# FloatingText.spawn_text(global_position + Vector2(0, -35), "INMUNE", Color(1.0, 0.9, 0.3, 0.8))
		return

	# Obtener PlayerStats para dodge, armor, shield y thorns
	var player_stats = get_tree().get_first_node_in_group("player_stats")

	# 1. Verificar esquiva (dodge) primero
	if player_stats and player_stats.has_method("get_stat"):
		var dodge_chance = player_stats.get_stat("dodge_chance")  # Already capped in STAT_LIMITS
		if dodge_chance > 0 and randf() < dodge_chance:  # BALANCE: Removed redundant minf() - cap is in STAT_LIMITS
			# ¡Esquivó el daño!
			# Debug desactivado: print("[%s] ✨ ¡ESQUIVADO! (%.0f%% chance)" % [character_class, dodge_chance * 100])
			FloatingText.spawn_text(global_position + Vector2(0, -35), "DODGE!", Color(0.3, 0.9, 1.0))
			# Balance Debug: Log dodge
			# FIX-BT2b: Siempre recopilar datos
			if BalanceDebugger:
				BalanceDebugger.log_damage_taken(amount, 0, true)
			return

	# I-Frames ahora se aplican en _process_frame_damage (Dinámicos)
	# _invulnerability_timer = 0.5

	var final_damage = amount

	# 2. SHIELD - Absorber daño con escudo primero
	if player_stats and player_stats.has_method("get_stat"):
		var current_shield = player_stats.get_stat("shield_amount")
		if current_shield > 0:
			var shield_absorbed = mini(final_damage, int(current_shield))
			final_damage -= shield_absorbed
			player_stats.add_stat("shield_amount", -shield_absorbed)

			# Mostrar texto de escudo
			if shield_absorbed > 0:
				FloatingText.spawn_text(global_position + Vector2(0, -45), "🛡️ -%d" % shield_absorbed, Color(0.3, 0.6, 1.0))

			# Si el escudo absorbió todo el daño, no hay más
			if final_damage <= 0:
				_play_shield_absorb_effect()
				return

	# 3. Aplicar armor (reducción de daño)
	var effective_armor = armor  # Usar armor local primero
	if player_stats and player_stats.has_method("get_stat"):
		effective_armor = player_stats.get_stat("armor")
		# PRINT DEBUG
		# print("🛡️ Armor Check: StatsNode=%s | Armor=%.1f" % [player_stats.name, effective_armor])

	if effective_armor > 0:
		var pre_armor = final_damage
		final_damage = maxi(1, final_damage - int(effective_armor))  # Mínimo 1 de daño
		# print("🛡️ ARMOR APPLIED: %d -> %d (Armor: %d)" % [pre_armor, final_damage, effective_armor])

	# 4. Aplicar damage_taken_mult si existe
	if player_stats and player_stats.has_method("get_stat"):
		var damage_taken_mult = player_stats.get_stat("damage_taken_mult")
		# if damage_taken_mult != 1.0: print("💔 Dmg Mult: x%.2f" % damage_taken_mult)
		if damage_taken_mult != 1.0:
			final_damage = int(final_damage * damage_taken_mult)

	# 5. Aplicar weakness si está activo (multiplicador de daño recibido)
	if _is_weakened:
		final_damage = int(final_damage * (1.0 + _weakness_amount))

	# === PHASE 11: SHOTGUN PREVENTION (QUEUE) ===
	# En lugar de aplicar daño directo, lo encolamos para procesarlo al final del frame.
	# Esto permite agrupar múltiples impactos simultáneos.

	if final_damage > 0:
		_damage_queue.append({
			"amount": final_damage,
			"element": element,
			"attacker": attacker
		})

		if not _frame_damage_scheduled:
			_frame_damage_scheduled = true
			call_deferred("_process_frame_damage")

		# Feedback inmediato parcial (para shield/armor) se mantiene arriba
		# Pero el feedback de HP (flash, texto final) se mueve a _process_frame_damage

	var armor_text = " [ARMOR: -%d]" % (amount - final_damage) if effective_armor > 0 and amount > final_damage else ""
	# Debug desactivado: print("[%s] 💥 Daño recibido: %d → %d (%s) (HP: %d/%d)%s%s" % [character_class, amount, final_damage, element, health_component.current_health, max_hp, " [WEAKENED]" if _is_weakened else "", armor_text])

func _process_frame_damage() -> void:
	"""Procesa todo el daño acumulado en este frame (Anti-Shotgun)"""
	_frame_damage_scheduled = false
	if _damage_queue.is_empty():
		return

	# 1. Ordenar por daño (Mayor a menor)
	_damage_queue.sort_custom(func(a, b): return a.amount > b.amount)

	# 2. Calcular daño agregado
	# El golpe más fuerte cuenta 100%. Los siguientes cuentan 25%.
	var primary_hit = _damage_queue[0]
	var total_damage = float(primary_hit.amount)

	for i in range(1, _damage_queue.size()):
		total_damage += float(_damage_queue[i].amount) * 0.25

	var final_applied_damage = int(total_damage)

	if final_applied_damage <= 0:
		_damage_queue.clear()
		return

	# 3. Aplicar al componente de salud
	if health_component:
		health_component.take_damage(final_applied_damage)

		# Balance Debug: Log damage taken (raw = queue total, final = applied)
		# FIX-BT2: Eliminar guard 'enabled' — los datos se recopilan SIEMPRE,
		# 'enabled' solo controla el overlay de UI, no el tracking de datos.
		if BalanceDebugger:
			var raw_total = 0
			for hit in _damage_queue:
				raw_total += hit.amount
			BalanceDebugger.log_damage_taken(raw_total, final_applied_damage, false)

		# AUDIT: Report damage to player
		if RunAuditTracker and RunAuditTracker.ENABLE_AUDIT:
			var enemy_id := "unknown"
			var attack_name: String = primary_hit.element if primary_hit.element != "" else "physical"
			if is_instance_valid(primary_hit.attacker):
				if "enemy_id" in primary_hit.attacker:
					enemy_id = primary_hit.attacker.enemy_id
				else:
					enemy_id = primary_hit.attacker.name.get_slice("_", 0)
				if primary_hit.attacker.has_meta("attack_name"):
					attack_name = primary_hit.attacker.get_meta("attack_name")
			var enemy_display_name := enemy_id
			if is_instance_valid(primary_hit.attacker) and "enemy_data" in primary_hit.attacker:
				enemy_display_name = primary_hit.attacker.enemy_data.get("name", enemy_id)
			RunAuditTracker.report_damage_to_player(enemy_id, enemy_display_name, attack_name, final_applied_damage)

		# Notificar estadísticas
		var player_stats = get_tree().get_first_node_in_group("player_stats")
		if player_stats and player_stats.has_method("on_damage_taken"):
			player_stats.on_damage_taken()

	# 4. Registrar contexto para Death Audit
	var _hit_enemy_id := "unknown"
	# FIX-BT4: Usar el elemento como default para attack_id en vez de "unknown"
	# ya que los enemigos no suelen setear meta("attack_name")
	var _hit_attack_id: String = primary_hit.element if primary_hit.element != "" else "physical"
	var _hit_damage_type: String = primary_hit.element if primary_hit.element != "" else "physical"
	var _hit_source_kind := "melee"  # melee, projectile, aoe, dot
	if is_instance_valid(primary_hit.attacker):
		if "enemy_id" in primary_hit.attacker:
			_hit_enemy_id = primary_hit.attacker.enemy_id
		else:
			_hit_enemy_id = primary_hit.attacker.name
		if primary_hit.attacker.has_meta("attack_name"):
			_hit_attack_id = primary_hit.attacker.get_meta("attack_name")
		if primary_hit.attacker.has_meta("source_kind"):
			_hit_source_kind = primary_hit.attacker.get_meta("source_kind")
		elif primary_hit.attacker is CharacterBody2D or primary_hit.attacker is Node2D:
			# Heuristic: projectiles are usually Area2D children
			if primary_hit.attacker.get_parent() and "projectile" in primary_hit.attacker.get_parent().name.to_lower():
				_hit_source_kind = "projectile"

	_last_hit_context = {
		"source": primary_hit.attacker.name if is_instance_valid(primary_hit.attacker) else "Environment",
		"damage": final_applied_damage,
		"element": primary_hit.element,
		"time": Time.get_ticks_msec(),
		"density": _get_enemy_density(),
		"queue_size": _damage_queue.size()
	}

	# 4b. Ring buffer para death tracking (últimos 5s de daño)
	var _hp_after = health_component.current_health if health_component else 0
	var _hp_before = _hp_after + final_applied_damage
	var _now_ms = Time.get_ticks_msec()
	# Capturar si el atacante es elite/boss para death tracking
	var _hit_is_elite := false
	var _hit_is_boss := false
	if is_instance_valid(primary_hit.attacker):
		if "is_elite" in primary_hit.attacker:
			_hit_is_elite = primary_hit.attacker.is_elite
		if "is_boss" in primary_hit.attacker:
			_hit_is_boss = primary_hit.attacker.is_boss

	_damage_ring_buffer.append({
		"timestamp_ms": _now_ms,
		"enemy_id": _hit_enemy_id,
		"is_elite": _hit_is_elite,
		"is_boss": _hit_is_boss,
		"attack_id": _hit_attack_id,
		"damage_type": _hit_damage_type,
		"source_kind": _hit_source_kind,
		"damage": final_applied_damage,
		"element": primary_hit.element,
		"hp_before": _hp_before,
		"hp_after": _hp_after,
		"queue_size": _damage_queue.size()
	})
	# Prune old entries
	var _cutoff_ms = _now_ms - int(DAMAGE_BUFFER_DURATION_S * 1000)
	while _damage_ring_buffer.size() > 0 and _damage_ring_buffer[0].timestamp_ms < _cutoff_ms:
		_damage_ring_buffer.pop_front()

	# 5. Feedback Visual (Solo uno por frame)
	DamageLogger.log_player_damage(_last_hit_context.source, final_applied_damage, primary_hit.element)
	player_took_damage.emit(final_applied_damage, primary_hit.element)
	FloatingText.spawn_player_damage(global_position + Vector2(0, -35), final_applied_damage, primary_hit.element)
	_play_damage_flash(primary_hit.element)

	# 6. I-FRAMES DINÁMICOS
	_apply_dynamic_iframes()

	# 7. Grit / Thorns / Etc (Triggered on 'real' damage)
	_process_post_damage_effects(final_applied_damage, primary_hit.attacker)

	_damage_queue.clear()

func _get_enemy_density() -> int:
	# Buscar EnemyManager
	# O simplemente contar nodos en grupo "enemies" cercanos
	var count = 0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_squared_to(global_position) < 22500: # 150px ^ 2
			count += 1
	return count

func _apply_dynamic_iframes() -> void:
	# Base: 0.4s (NERFED from 0.5s for balance)
	var base_iframe = 0.4

	# Bonus por densidad (Fairness en hordas) - NERFED max from 0.15 to 0.10
	var density = _get_enemy_density()
	var density_bonus = minf(float(density) * 0.02, 0.10)  # Max +0.10s (with ~5 enemies)

	_invulnerability_timer = base_iframe + density_bonus

func _process_post_damage_effects(amount: int, primary_attacker: Node) -> void:
	# Lógica movida de take_damage original para ejecutarse solo una vez por frame

	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if not player_stats: return

	# 1. Grit
	if amount >= max_hp * 0.10: # 10% HP check
		if player_stats.has_method("get_stat") and player_stats.get_stat("grit_active") > 0:
			if health_component.has_method("set_invulnerable"):
				health_component.set_invulnerable(1.0)
				FloatingText.spawn_custom(global_position + Vector2(0, -50), "🛡️ GRIT!", Color.GOLD)

	# 2. Frost Nova
	if player_stats.has_method("get_stat") and player_stats.get_stat("frost_nova_on_hit") > 0:
		_trigger_frost_nova()

	# 3. Soul Link
	if player_stats.has_method("get_stat") and player_stats.get_stat("soul_link_percent") > 0:
		_trigger_soul_link(amount, player_stats)

	# 4. Thorns (Solo al primary attacker para no spamear)
	if is_instance_valid(primary_attacker):
		_apply_thorns_damage(primary_attacker, amount, player_stats)

func _trigger_frost_nova() -> void:
	# Lógica extraída
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < 250:
			if enemy.has_method("apply_freeze"): enemy.apply_freeze(0.9, 2.0)
			if enemy.has_method("apply_knockback"):
				var dir = (enemy.global_position - global_position).normalized()
				enemy.apply_knockback(dir * 300)
	_spawn_nova_effect()

func _trigger_soul_link(amount: int, stats: Node) -> void:
	var soul_link_pct = stats.get_stat("soul_link_percent")
	var link_radius = 400.0
	var damage_to_share = int(amount * soul_link_pct)
	if damage_to_share <= 0: return

	# VFX de soul link via spritesheet
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_soul_link_vfx"):
		vfx_mgr.spawn_soul_link_vfx(global_position)

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < link_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_to_share)
				FloatingText.spawn_custom(enemy.global_position + Vector2(0, -50), "LINK!", Color.MAGENTA)

	# -----------------------------------------------------------
	# LÓGICA DE NUEVOS OBJETOS (Phase 3) - PROCESADA EN _process_post_damage_effects
	# -----------------------------------------------------------
	# -----------------------------------------------------------

func _apply_thorns_damage(attacker: Node, damage_received: int, player_stats: Node) -> void:
	"""Aplicar daño de espinas al atacante"""
	var thorns_flat = player_stats.get_stat("thorns") if player_stats.has_method("get_stat") else 0.0
	var thorns_percent = player_stats.get_stat("thorns_percent") if player_stats.has_method("get_stat") else 0.0
	var thorns_slow = player_stats.get_stat("thorns_slow") if player_stats.has_method("get_stat") else 0.0
	var thorns_stun = player_stats.get_stat("thorns_stun") if player_stats.has_method("get_stat") else 0.0

	# Calcular daño total de espinas
	var thorns_damage = int(thorns_flat + (damage_received * thorns_percent))

	if thorns_damage <= 0:
		return

	# Aplicar daño al atacante
	if attacker.has_method("take_damage"):
		attacker.take_damage(thorns_damage)
		# Debug desactivado: print("[%s] 🌵 THORNS: Reflejado %d daño a %s" % [character_class, thorns_damage, attacker.name])

		# Mostrar texto flotante sobre el enemigo
		if "global_position" in attacker:
			FloatingText.spawn_damage(attacker.global_position + Vector2(0, -20), thorns_damage, false)

		# VFX de thorns en la posición del jugador
		var vfx_mgr = get_node_or_null("/root/VFXManager")
		if vfx_mgr and vfx_mgr.has_method("spawn_thorns_vfx"):
			vfx_mgr.spawn_thorns_vfx(global_position)

		# Aplicar ralentización si hay thorns_slow
		if thorns_slow > 0 and attacker.has_method("apply_slow"):
			attacker.apply_slow(thorns_slow, 1.5)  # 1.5s de duración

		# Aplicar aturdimiento si hay thorns_stun
		if thorns_stun > 0 and attacker.has_method("apply_stun"):
			attacker.apply_stun(thorns_stun)

func _play_damage_flash(element: String) -> void:
	"""Flash de daño según el elemento - colores suaves para no tapar la pantalla"""
	if not animated_sprite:
		return

	# Colores con valores moderados (sin HDR >1.0) para evitar cubrir la pantalla
	var flash_color: Color
	match element:
		"fire":
			flash_color = Color(1.0, 0.5, 0.3, 1.0)
		"ice":
			flash_color = Color(0.5, 0.7, 1.0, 1.0)
		"poison":
			flash_color = Color(0.5, 1.0, 0.4, 1.0)
		"dark", "void", "shadow":
			flash_color = Color(0.8, 0.6, 0.8, 1.0)  # Lavanda suave, NO magenta
		"lightning":
			flash_color = Color(1.0, 1.0, 0.5, 1.0)
		_:
			flash_color = Color(1.0, 0.4, 0.4, 1.0)  # Rojo suave por defecto

	# Cancelar tween anterior para evitar acumulación de color
	if _damage_flash_tween and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()

	animated_sprite.modulate = flash_color
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.15)

	# Reproducir animación de hit si está disponible
	_play_hit_animation()

func _play_hit_animation() -> void:
	"""Reproduce la animación de recibir daño"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	if animated_sprite.sprite_frames.has_animation("hit"):
		var previous_anim = animated_sprite.animation
		animated_sprite.play("hit")

		# Volver a la animación anterior cuando termine
		if not animated_sprite.animation_finished.is_connected(_on_hit_animation_finished):
			animated_sprite.animation_finished.connect(_on_hit_animation_finished.bind(previous_anim), CONNECT_ONE_SHOT)

func _on_hit_animation_finished(previous_anim: String) -> void:
	"""Callback cuando termina la animación de hit"""
	if animated_sprite and animated_sprite.sprite_frames:
		# Volver a idle en la última dirección
		var idle_anim = "idle_%s" % last_dir
		if animated_sprite.sprite_frames.has_animation(idle_anim):
			animated_sprite.play(idle_anim)

func _play_shield_absorb_effect() -> void:
	"""Efecto visual cuando el escudo absorbe todo el daño — spritesheet + flash"""
	# VFX de absorción de escudo via spritesheet
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_shield_absorb_vfx"):
		vfx_mgr.spawn_shield_absorb_vfx(global_position)

	# Mantener flash azul sutil como complemento
	if not animated_sprite:
		return
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(0.5, 0.8, 2.0, 1.0), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

func _update_shield_vfx(shield_amount: float) -> void:
	"""Spawn/cleanup aura de escudo según shield_amount"""
	if shield_amount > 0 and not (_shield_vfx and is_instance_valid(_shield_vfx)):
		# Spawn aura de escudo
		var vfx_mgr = get_node_or_null("/root/VFXManager")
		if vfx_mgr and vfx_mgr.has_method("spawn_shield_aura"):
			_shield_vfx = vfx_mgr.spawn_shield_aura(self)
	elif shield_amount <= 0 and _shield_vfx and is_instance_valid(_shield_vfx):
		# Escudo agotado — limpiar aura
		_shield_vfx.queue_free()
		_shield_vfx = null

func heal(amount: int) -> int:
	"""Curar al personaje (aplica curse si está activo)"""
	if health_component:
		var old_hp = health_component.current_health
		var final_heal = amount
		# Aplicar curse si está activo
		if _is_cursed:
			final_heal = int(amount * (1.0 - _curse_amount))

		# Blood Pact check: No healing allowed
		var player_stats = get_tree().get_first_node_in_group("player_stats")
		if player_stats and player_stats.has_method("get_stat") and player_stats.get_stat("blood_pact") > 0:
			final_heal = 0

		health_component.heal(final_heal)
		var healed = health_component.current_health - old_hp

		# health_component.heal() ya emite health_changed internamente
		# No re-emitir para evitar doble actualización de UI

		# Debug explícito desactivado por spam:
		# print("[%s] HEAL() llamado. Amount: %.1f -> Healed: %.1f. HP Now: %d/%d" % [character_class, float(amount), float(healed), health_component.current_health, max_hp])

		# Mostrar texto flotante de curación si realmente curó algo
		if healed > 0:
			FloatingText.spawn_heal(global_position + Vector2(0, -30), healed)
			_spawn_heal_particles()
			# Trackear curación para estadísticas
			var game_node = get_tree().root.get_node_or_null("Game")
			if not game_node:
				game_node = get_tree().root.get_node_or_null("LoopiaLikeGame")
			if game_node and game_node.has_method("add_healing_stat"):
				game_node.add_healing_stat(healed)

		# Debug desactivado: print("[%s] Curación: +%d (HP: %d/%d)%s" % [character_class, healed, health_component.current_health, max_hp, " [CURSED]" if _is_cursed else ""])

		return healed
	return 0

func _spawn_heal_particles() -> void:
	"""Efecto visual de curación verde — usa spritesheet via VFXManager"""
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_heal_vfx"):
		vfx_mgr.spawn_heal_vfx(global_position)

func _spawn_nova_effect() -> void:
	"""Efecto visual para Frost Nova — usa spritesheet via VFXManager"""
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_frost_nova_vfx"):
		vfx_mgr.spawn_frost_nova_vfx(global_position)

func _on_health_changed(current: int, max_val: int) -> void:
	"""Callback cuando la salud cambia"""
	hp = current
	max_hp = max_val  # Sincronizar también max_hp
	health_changed.emit(current, max_val)

func _on_health_died() -> void:
	"""Callback cuando el personaje muere - verifica revives primero"""
	# Verificar si tiene revives disponibles
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		var revives = int(player_stats.get_stat("revives"))
		if revives > 0:
			# ¡Tiene revive disponible! Consumir y revivir
			_trigger_revive(player_stats, revives)
			return

	# Sin revives - muerte definitiva
	# Reproducir animación de muerte antes de emitir señal
	_play_death_animation()

func _play_death_animation() -> void:
	"""Reproduce la animación de muerte y luego emite señal de muerte"""
	_is_dying = true

	# Detener cualquier movimiento
	velocity = Vector2.ZERO

	# Desactivar AttackManager para detener auto-ataques
	if attack_manager and attack_manager.has_method("set_active"):
		attack_manager.set_active(false)
	elif attack_manager:
		attack_manager.process_mode = Node.PROCESS_MODE_DISABLED

	# Hacer al jugador invulnerable durante la animación de muerte
	set_collision_layer_value(1, false)

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		# Detener animación actual y preparar la de muerte
		animated_sprite.stop()
		animated_sprite.animation = "death"
		animated_sprite.frame = 0

		# Restaurar escala normal por si estaba casteando
		animated_sprite.scale = Vector2(player_sprite_scale, player_sprite_scale)

		# Efecto de muerte: velocidad normal (ahora controlada por FPS en WizardPlayer)
		# Se removió el 0.3x que causaba demora de 10s
		animated_sprite.speed_scale = 1.0

		animated_sprite.play("death")

		# Conectar señal para emitir player_died cuando termine la animación
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

		# SAFETY TIMER: Forzar muerte si la animación falla o se cuelga
		# 2.0 segundos debería ser suficiente para cualquier animación de muerte razonable
		get_tree().create_timer(2.0).timeout.connect(func():
			if game_manager and game_manager.is_run_active:
				# Si el juego sigue corriendo (no se llamó a player_died), forzarlo
				print("[%s] ⚠️ Safety Timer: Forzando señal player_died" % character_class)
				player_died.emit()
		)
	else:
		# Si no hay animación de muerte, emitir señal directamente
		player_died.emit()

func _on_death_animation_finished() -> void:
	"""Callback cuando termina la animación de muerte"""
	# Death Audit
	if not _last_hit_context.is_empty():
		print("💀 DEATH AUDIT: Source=[%s] Dmg=[%d] Elem=[%s] Density=[%d] QueueSize=[%d]" %
			[_last_hit_context.get("source", "?"), _last_hit_context.get("damage", 0),
			_last_hit_context.get("element", "?"), _last_hit_context.get("density", 0),
			_last_hit_context.get("queue_size", 0)])
	else:
		print("💀 DEATH AUDIT: Source=Unknown (Instant Kill or Logic Error?)")

	player_died.emit()

func get_death_context() -> Dictionary:
	"""Returns structured death context for telemetry (ring buffer of last 5s of damage)."""
	if _damage_ring_buffer.is_empty():
		return {"killer": "unknown", "killer_attack": "unknown", "last_damage_window": [], "window_duration_s": 0.0}

	var last_hit = _damage_ring_buffer[-1]
	var first_hit = _damage_ring_buffer[0]
	var window_ms = last_hit.timestamp_ms - first_hit.timestamp_ms

	# Gather active status effects
	var status_effects: Array = []
	if _is_weakened:
		status_effects.append("weakened (%.0f%%)" % (_weakness_amount * 100))
	if _is_slowed:
		status_effects.append("slowed")
	if _is_stunned:
		status_effects.append("stunned")
	if _is_cursed:
		status_effects.append("cursed")

	# Construir killer ID con prefijo elite/boss si aplica
	var killer_prefix = ""
	if last_hit.get("is_boss", false):
		killer_prefix = "boss_"
	elif last_hit.get("is_elite", false):
		killer_prefix = "elite_"

	return {
		"killer": killer_prefix + last_hit.enemy_id,
		"killer_attack": last_hit.attack_id,
		"killer_damage_type": last_hit.get("damage_type", last_hit.get("element", "physical")),
		"killer_source_kind": last_hit.get("source_kind", "melee"),
		"killing_blow_damage": last_hit.damage,
		"killing_blow_element": last_hit.element,
		"last_damage_window": _damage_ring_buffer.duplicate(),
		"window_duration_s": window_ms / 1000.0,
		"total_damage_in_window": _damage_ring_buffer.reduce(func(acc, e): return acc + e.damage, 0),
		"hits_in_window": _damage_ring_buffer.size(),
		"active_status_effects": status_effects,
		"player_position": global_position if is_inside_tree() else Vector2.ZERO,
		"enemy_density": _get_enemy_density()
	}

func _trigger_revive(player_stats: Node, current_revives: int) -> void:
	"""Activar revive: consumir una vida extra y restaurar HP"""
	# Consumir un revive
	player_stats.add_stat("revives", -1)

	# Determinar cuánto HP restaurar (50% por defecto, 30% si es Segunda Vida)
	var max_health = player_stats.get_stat("max_health")
	var revive_hp_percent = 0.5  # 50% por defecto (Corazón de Fénix)
	if current_revives == 1:
		# Si solo tenía 1, podría ser Segunda Vida (30%)
		revive_hp_percent = 0.3

	var revive_hp = int(max_health * revive_hp_percent)

	# Restaurar vida
	if health_component:
		health_component.current_health = revive_hp
		health_component.is_alive = true
		hp = revive_hp

	# Explosión de Fénix (AoE masivo)
	var explosion_data = {
		"damage": 500.0,
		"area": 4.0,
		"duration": 0.5,
		"effect": "burn",
		"effect_value": 10.0,
		"effect_duration": 5.0,
		"color": Color(1.0, 0.4, 0.1),
		"is_aoe": true,
		"position": global_position
	}
	ProjectileFactory.create_aoe(self, explosion_data)

	# Efectos visuales de revive
	_play_revive_effects()

	# Mostrar mensaje
	FloatingText.spawn_text(global_position + Vector2(0, -50), "¡REVIVE!", Color(1.0, 0.9, 0.3))

	# Inmunidad temporal: base 2s + bonus de revive_invuln
	var base_immunity = 2.0
	var bonus_immunity = player_stats.get_stat("revive_invuln") if player_stats.has_method("get_stat") else 0.0
	_grant_revive_immunity(base_immunity + bonus_immunity)

	# Notificar cambio de salud
	if health_component:
		health_component.health_changed.emit(revive_hp, int(max_health))

	print("[%s] 💫 ¡REVIVIDO! HP: %d/%d (Revives restantes: %d)" % [
		character_class, revive_hp, int(max_health), current_revives - 1
	])

func _play_revive_effects() -> void:
	"""Efectos visuales de revive — spritesheet dorado + flash + audio"""
	# VFX de revive via spritesheet
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_revive_vfx"):
		vfx_mgr.spawn_revive_vfx(global_position)

	# Mantener flash dorado brillante como complemento
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(2.0, 1.8, 0.5, 1.0), 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.5)

	# Sonido de revive
	var audio_manager = get_tree().get_first_node_in_group("audio_manager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("phoenix_resurrection")



func _grant_revive_immunity(duration: float) -> void:
	"""Otorgar inmunidad temporal tras revivir"""
	_revive_immunity_timer = duration

func _update_revive_immunity(delta: float) -> void:
	"""Actualizar timer de inmunidad de revive"""
	if _revive_immunity_timer > 0:
		_revive_immunity_timer -= delta
		# Efecto visual de parpadeo durante inmunidad
		if animated_sprite:
			animated_sprite.modulate.a = 0.5 + 0.5 * sin(_revive_immunity_timer * 10.0)



func _apply_enemy_slow_aura() -> void:
	"""Aplicar ralentización pasiva a enemigos cercanos (stat: enemy_slow_aura)"""
	var player_stats = _get_player_stats()
	if not player_stats or not player_stats.has_method("get_stat"):
		return

	var slow_amount = player_stats.get_stat("enemy_slow_aura")
	if slow_amount <= 0:
		return

	# Obtener todos los enemigos cercanos (radio de 200px)
	var aura_radius = 200.0
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= aura_radius:
			# Aplicar slow corto (se refresca cada 0.5s)
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(slow_amount, 0.6)  # 0.6s para solapar con el check de 0.5s

# ========== ACCESO A COMPONENTES ==========

func get_health_component() -> Node:
	"""Obtener referencia al HealthComponent"""
	return health_component

func is_alive() -> bool:
	"""Verificar si el personaje está vivo"""
	if health_component and "is_alive" in health_component:
		return health_component.is_alive
	return hp > 0

func get_current_health() -> int:
	"""Obtener HP actual"""
	if health_component and "current_health" in health_component:
		return health_component.current_health
	return hp

func get_max_health() -> int:
	"""Obtener HP máximo"""
	if health_component and "max_health" in health_component:
		return health_component.max_health
	return max_hp

# ========== ANIMACIÓN DE CAST ==========

const CAST_ANIMATION_BASE_FPS: float = 2.0  # FPS base lento para que se vea bien
const CAST_SCALE_COMPENSATION: float = 1.15  # El wizard en cast se ve más pequeño por el staff levantado

func play_cast_animation() -> void:
	"""Reproduce la animación de lanzar hechizo (puede ser llamada por armas)"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	if not animated_sprite.sprite_frames.has_animation("cast"):
		return

	# Obtener velocidad de ataque para ajustar la animación
	var attack_speed_mult: float = 1.0
	var player_stats_node = get_tree().get_first_node_in_group("player_stats")
	if player_stats_node and player_stats_node.has_method("get_stat"):
		attack_speed_mult = player_stats_node.get_stat("attack_speed_mult")

	# Ajustar velocidad de animación según attack_speed
	# Base lenta (2 FPS) * multiplicador de velocidad de ataque
	var anim_speed = CAST_ANIMATION_BASE_FPS * attack_speed_mult
	animated_sprite.sprite_frames.set_animation_speed("cast", anim_speed)

	# Si ya está casteando, reiniciar la animación desde el principio
	# para que cada ataque se vea
	_is_casting = true
	animated_sprite.stop()
	animated_sprite.animation = "cast"
	animated_sprite.frame = 0
	animated_sprite.play("cast")

	# Compensar visualmente el tamaño - el wizard en cast parece más pequeño
	var base_scale = player_sprite_scale * CAST_SCALE_COMPENSATION
	animated_sprite.scale = Vector2(base_scale, base_scale)

	# Desconectar señal previa si existe y reconectar
	if animated_sprite.animation_finished.is_connected(_on_cast_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_cast_animation_finished)
	animated_sprite.animation_finished.connect(_on_cast_animation_finished, CONNECT_ONE_SHOT)

func _on_cast_animation_finished() -> void:
	"""Callback cuando termina la animación de cast"""
	_is_casting = false

	# Restaurar escala normal
	if animated_sprite:
		animated_sprite.scale = Vector2(player_sprite_scale, player_sprite_scale)

	if animated_sprite and animated_sprite.sprite_frames:
		# Volver a la animación apropiada según estado de movimiento
		var anim_prefix = "walk_" if _is_moving else "idle_"
		var anim_name = anim_prefix + last_dir
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)

# ========== EQUIPAMIENTO DE ARMAS ==========

func equip_weapon(weapon) -> bool:
	"""Equipar un arma"""
	if not attack_manager:
		push_warning("[%s] AttackManager no disponible" % character_class)
		return false

	if not weapon:
		push_warning("[%s] Intento de equipar arma nula" % character_class)
		return false

	attack_manager.add_weapon(weapon)
	weapon_equipped.emit(weapon)
	# Debug desactivado: print("[%s] ⚔️ Arma equipada: %s" % [character_class, weapon.name])
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
	"""Crear barra de vida y escudo - SOBRESCRIBIR EN SUBCLASES SI NECESARIO"""
	if not health_bar_container:
		health_bar_container = Node2D.new()
		health_bar_container.name = "HealthBarContainer"
		health_bar_container.z_index = 100 # Asegurar visibilidad encima de todo
		add_child(health_bar_container)

		# Calcular offset Y basado en la escala del sprite
		# La barra debe estar justo encima de la cabeza con un pequeño margen
		var sprite_scale = player_sprite_scale
		var visual_calibrator = get_tree().root.get_node_or_null("VisualCalibrator") if get_tree() else null
		if visual_calibrator and visual_calibrator.has_method("get_player_scale"):
			sprite_scale = visual_calibrator.get_player_scale()

		# Fórmula equilibrada: base + ajuste por escala
		# Con escala 0.25 -> -65px (bien por encima de la cabeza)
		# Con escala 0.35 -> -69px (se adapta a sprites más grandes)
		var bar_offset_y = -55.0 - (sprite_scale * 40.0)

		# ════════════════════════════════════════════════════════════════════
		# BARRA DE VIDA (Verde)
		# ════════════════════════════════════════════════════════════════════
		var bg_bar = ColorRect.new()
		bg_bar.name = "HealthBarBG"
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

		# ════════════════════════════════════════════════════════════════════
		# BARRA DE ESCUDO (Azul - encima de la vida)
		# Solo se muestra si el jugador tiene escudo
		# ════════════════════════════════════════════════════════════════════
		var shield_bar_offset_y = bar_offset_y - 6  # 6px encima de la barra de vida

		var shield_bg_bar = ColorRect.new()
		shield_bg_bar.name = "ShieldBarBG"
		shield_bg_bar.size = Vector2(40, 4)
		shield_bg_bar.color = Color(0.1, 0.2, 0.4, 0.8)  # Fondo azul oscuro
		shield_bg_bar.position = Vector2(-20, shield_bar_offset_y)
		shield_bg_bar.visible = false  # Oculta hasta que haya escudo
		health_bar_container.add_child(shield_bg_bar)

		var shield_bar = ColorRect.new()
		shield_bar.name = "ShieldBar"
		shield_bar.size = Vector2(40, 4)
		shield_bar.color = Color(0.2, 0.6, 1.0, 0.95)  # Azul brillante
		shield_bar.position = Vector2(-20, shield_bar_offset_y)
		shield_bar.visible = false  # Oculta hasta que haya escudo
		health_bar_container.add_child(shield_bar)

	update_health_bar()

func update_health_bar() -> void:
	"""Actualizar la barra de vida y escudo"""
	if not health_bar_container:
		return

	# Actualizar barra de vida
	var health_bar = health_bar_container.get_node_or_null("HealthBar")
	if health_bar:
		var health_percent = float(hp) / float(max_hp)
		health_bar.size.x = 40.0 * health_percent

	# Actualizar barra de escudo
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and player_stats.has_method("get_stat"):
		var current_shield = player_stats.get_stat("shield_amount")
		var max_shield = player_stats.get_stat("max_shield")

		var shield_bar = health_bar_container.get_node_or_null("ShieldBar")
		var shield_bg = health_bar_container.get_node_or_null("ShieldBarBG")

		if shield_bar and shield_bg:
			# Mostrar barra de escudo solo si el jugador tiene escudo máximo > 0
			if max_shield > 0:
				shield_bar.visible = true
				shield_bg.visible = true
				var shield_percent = current_shield / max_shield if max_shield > 0 else 0.0
				shield_bar.size.x = 40.0 * shield_percent

				# Efecto de parpadeo cuando el escudo se está regenerando
				var time_since_damage = player_stats._time_since_damage if "_time_since_damage" in player_stats else 999.0
				var regen_delay = player_stats.get_stat("shield_regen_delay")

				if time_since_damage < regen_delay and current_shield < max_shield:
					# Parpadeo mientras espera regeneración
					var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
					shield_bar.color = Color(0.2, 0.6, 1.0, pulse)
				else:
					shield_bar.color = Color(0.2, 0.6, 1.0, 0.95)
			else:
				shield_bar.visible = false
				shield_bg.visible = false

func _update_shield_bar() -> void:
	"""Actualizar solo la barra de escudo (llamado cada frame para animación)"""
	if not health_bar_container:
		return

	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if not player_stats or not player_stats.has_method("get_stat"):
		return

	var current_shield = player_stats.get_stat("shield_amount")
	var max_shield = player_stats.get_stat("max_shield")

	var shield_bar = health_bar_container.get_node_or_null("ShieldBar")
	var shield_bg = health_bar_container.get_node_or_null("ShieldBarBG")

	if not shield_bar or not shield_bg:
		return

	# Mostrar barra de escudo solo si el jugador tiene escudo máximo > 0
	if max_shield > 0:
		shield_bar.visible = true
		shield_bg.visible = true
		var shield_percent = current_shield / max_shield if max_shield > 0 else 0.0
		shield_bar.size.x = 40.0 * shield_percent

		# Efecto de parpadeo cuando el escudo está esperando regeneración
		var time_since_damage = player_stats._time_since_damage if "_time_since_damage" in player_stats else 999.0
		var regen_delay = player_stats.get_stat("shield_regen_delay")

		if time_since_damage < regen_delay and current_shield < max_shield:
			# Parpadeo mientras espera regeneración (indica que no regenera aún)
			var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			shield_bar.color = Color(0.4, 0.4, 0.8, pulse)
			shield_bg.color = Color(0.1, 0.1, 0.3, 0.6 + pulse * 0.2)
		elif current_shield < max_shield:
			# Regenerando: brillo pulsante azul claro
			var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.008)
			shield_bar.color = Color(0.3 * pulse, 0.7 * pulse, 1.0, 0.95)
			shield_bg.color = Color(0.1, 0.2, 0.4, 0.8)
		else:
			# Lleno: azul brillante sólido
			shield_bar.color = Color(0.2, 0.6, 1.0, 0.95)
			shield_bg.color = Color(0.1, 0.2, 0.4, 0.8)
	else:
		shield_bar.visible = false
		shield_bg.visible = false

# ========== SISTEMA DE DEBUFFS - APLICACIÓN ==========

func apply_slow(amount: float, duration: float) -> void:
	"""Aplicar slow al jugador (reduce velocidad)"""
	var was_slowed = _is_slowed
	_slow_amount = clamp(amount, 0.0, 0.8)  # Máximo 80% slow
	_slow_timer = max(_slow_timer, duration)
	_is_slowed = true
	move_speed = base_move_speed * (1.0 - _slow_amount)

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("slow", _slow_timer)

	# Mostrar notificación solo si es nuevo
	if not was_slowed:
		FloatingText.spawn_status_applied(global_position + Vector2(0, -40), "slow")
		# VFX de slow (hielo en los pies)
		var vfx_mgr = get_node_or_null("/root/VFXManager")
		if vfx_mgr and vfx_mgr.has_method("spawn_slow_vfx"):
			if _slow_vfx and is_instance_valid(_slow_vfx):
				_slow_vfx.queue_free()
			_slow_vfx = vfx_mgr.spawn_slow_vfx(self)

	# Debug desactivado: print("[%s] ❄️ Ralentizado %.0f%% por %.1fs" % [character_class, _slow_amount * 100, duration])

func _clear_slow() -> void:
	_is_slowed = false
	_slow_amount = 0.0
	move_speed = base_move_speed
	# Limpiar VFX de slow
	if _slow_vfx and is_instance_valid(_slow_vfx):
		_slow_vfx.queue_free()
		_slow_vfx = null
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	# Eliminar icono
	if status_icon_display:
		status_icon_display.remove_effect("slow")
	# Debug desactivado: print("[%s] ❄️ Slow terminado" % character_class)

func apply_burn(damage_per_tick: float, duration: float) -> void:
	"""Aplicar burn al jugador (DoT de fuego)"""
	var was_burning = _burn_timer > 0
	_burn_damage = damage_per_tick
	_burn_timer = max(_burn_timer, duration)
	_burn_tick_timer = BURN_TICK_INTERVAL

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("burn", _burn_timer)

	# Mostrar notificación solo si es nuevo
	if not was_burning:
		FloatingText.spawn_status_applied(global_position + Vector2(0, -40), "burn")

	# Debug desactivado: print("[%s] 🔥 Quemándose por %.1f daño/tick durante %.1fs" % [character_class, damage_per_tick, duration])

func _apply_burn_tick() -> void:
	if health_component:
		var dmg = int(_burn_damage)
		health_component.take_damage(dmg)
		# Mostrar daño de tick flotante
		FloatingText.spawn_dot_tick(global_position + Vector2(randf_range(-15, 15), -30), dmg, "burn")
		# Efecto visual de burn
		_spawn_burn_particle()

func _clear_burn() -> void:
	_burn_damage = 0.0
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	# Eliminar icono
	if status_icon_display:
		status_icon_display.remove_effect("burn")
	# Debug desactivado: print("[%s] 🔥 Burn terminado" % character_class)

func _spawn_burn_particle() -> void:
	"""Partícula de fuego cuando está quemándose"""
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.one_shot = true
	particle.amount = 6
	particle.lifetime = 0.5
	particle.direction = Vector2(0, -1)
	particle.spread = 40.0
	particle.gravity = Vector2(0, -60)
	particle.initial_velocity_min = 25.0
	particle.initial_velocity_max = 50.0
	particle.scale_amount_min = 2.5
	particle.scale_amount_max = 5.0
	particle.color = Color(1.0, 0.5, 0.1, 0.9)
	add_child(particle)
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(particle): particle.queue_free()
	)

func apply_poison(damage_per_tick: float, duration: float) -> void:
	"""Aplicar poison al jugador (DoT más lento pero más largo)"""
	var was_poisoned = _poison_timer > 0
	_poison_damage = damage_per_tick
	_poison_timer = max(_poison_timer, duration)
	_poison_tick_timer = POISON_TICK_INTERVAL

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("poison", _poison_timer)

	# Mostrar notificación solo si es nuevo
	if not was_poisoned:
		FloatingText.spawn_status_applied(global_position + Vector2(0, -40), "poison")

	# Debug desactivado: print("[%s] ☠️ Envenenado por %.1f daño/tick durante %.1fs" % [character_class, damage_per_tick, duration])

func _apply_poison_tick() -> void:
	if health_component:
		var dmg = int(_poison_damage)
		health_component.take_damage(dmg)
		# Mostrar daño de tick flotante
		FloatingText.spawn_dot_tick(global_position + Vector2(randf_range(-15, 15), -30), dmg, "poison")
		_spawn_poison_particle()

func _clear_poison() -> void:
	_poison_damage = 0.0
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	# Eliminar icono
	if status_icon_display:
		status_icon_display.remove_effect("poison")
	# Debug desactivado: print("[%s] ☠️ Poison terminado" % character_class)

func _spawn_poison_particle() -> void:
	"""Partícula de veneno"""
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.one_shot = true
	particle.amount = 5
	particle.lifetime = 0.6
	particle.direction = Vector2(0, -1)
	particle.spread = 50.0
	particle.gravity = Vector2(0, -25)
	particle.initial_velocity_min = 20.0
	particle.initial_velocity_max = 35.0
	particle.scale_amount_min = 2.5
	particle.scale_amount_max = 4.0
	particle.color = Color(0.5, 0.9, 0.3, 0.85)  # Verde venenoso
	add_child(particle)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(particle): particle.queue_free()
	)

func _spawn_weakness_particle() -> void:
	"""Partícula de weakness (púrpura oscuro descendente)"""
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.one_shot = true
	particle.amount = 8
	particle.lifetime = 0.7
	particle.direction = Vector2(0, 1)
	particle.spread = 60.0
	particle.gravity = Vector2(0, 40)
	particle.initial_velocity_min = 15.0
	particle.initial_velocity_max = 30.0
	particle.scale_amount_min = 2.0
	particle.scale_amount_max = 4.0
	particle.color = Color(0.6, 0.15, 0.9, 0.85)  # Púrpura oscuro
	add_child(particle)
	get_tree().create_timer(0.9).timeout.connect(func():
		if is_instance_valid(particle): particle.queue_free()
	)

func _spawn_curse_particle() -> void:
	"""Partícula de curse (púrpura oscuro con espiral)"""
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.one_shot = true
	particle.amount = 6
	particle.lifetime = 0.8
	particle.direction = Vector2(0, -1)
	particle.spread = 45.0
	particle.gravity = Vector2(0, -20)
	particle.initial_velocity_min = 10.0
	particle.initial_velocity_max = 25.0
	particle.scale_amount_min = 2.0
	particle.scale_amount_max = 3.5
	particle.color = Color(0.4, 0.1, 0.5, 0.85)  # Púrpura muy oscuro
	add_child(particle)
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(particle): particle.queue_free()
	)

func apply_stun(duration: float) -> void:
	"""Aplicar stun al jugador (paralizado)"""
	var was_stunned = _is_stunned
	_stun_timer = max(_stun_timer, duration)
	_is_stunned = true

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("stun", _stun_timer)

	# Mostrar notificación solo si es nuevo
	if not was_stunned:
		FloatingText.spawn_status_applied(global_position + Vector2(0, -40), "stun")
		# VFX de stun (estrellas orbitando)
		var vfx_mgr = get_node_or_null("/root/VFXManager")
		if vfx_mgr and vfx_mgr.has_method("spawn_stun_vfx"):
			if _stun_vfx and is_instance_valid(_stun_vfx):
				_stun_vfx.queue_free()
			_stun_vfx = vfx_mgr.spawn_stun_vfx(self)

	# Debug desactivado: print("[%s] ⚡ Aturdido por %.1fs" % [character_class, duration])

func _clear_stun() -> void:
	_is_stunned = false
	# Limpiar VFX de stun
	if _stun_vfx and is_instance_valid(_stun_vfx):
		_stun_vfx.queue_free()
		_stun_vfx = null
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	# Eliminar icono
	if status_icon_display:
		status_icon_display.remove_effect("stun")
	# Debug desactivado: print("[%s] ⚡ Stun terminado" % character_class)

func apply_weakness(amount: float, duration: float) -> void:
	"""Aplicar weakness al jugador (recibe más daño)"""
	var was_weakened = _is_weakened
	_weakness_amount = clamp(amount, 0.0, 1.0)  # Máximo +100% daño
	_weakness_timer = max(_weakness_timer, duration)
	_is_weakened = true

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("weakness", _weakness_timer)

	# Mostrar notificación solo si es nuevo
	if not was_weakened:
		FloatingText.spawn_status_applied(global_position + Vector2(0, -40), "weakness")
		_spawn_weakness_particle()

	# Debug desactivado: print("[%s] 💀 Debilitado +%.0f%% daño recibido por %.1fs" % [character_class, _weakness_amount * 100, duration])

func _clear_weakness() -> void:
	_is_weakened = false
	_weakness_amount = 0.0
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	# Eliminar icono
	if status_icon_display:
		status_icon_display.remove_effect("weakness")
	# Debug desactivado: print("[%s] 💀 Weakness terminado" % character_class)

func apply_curse(amount: float, duration: float) -> void:
	"""Aplicar curse al jugador (reduce curación)"""
	var was_cursed = _is_cursed
	_curse_amount = clamp(amount, 0.0, 0.9)  # Máximo -90% curación
	_curse_timer = max(_curse_timer, duration)
	_is_cursed = true

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("curse", _curse_timer)

	# Mostrar notificación solo si es nuevo
	if not was_cursed:
		FloatingText.spawn_status_applied(global_position + Vector2(0, -40), "curse")
		_spawn_curse_particle()

	# Debug desactivado: print("[%s] 👻 Maldito -%.0f%% curación por %.1fs" % [character_class, _curse_amount * 100, duration])

func _clear_curse() -> void:
	_is_cursed = false
	_curse_amount = 0.0
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	# Eliminar icono
	if status_icon_display:
		status_icon_display.remove_effect("curse")
	# Debug desactivado: print("[%s] 👻 Curse terminado" % character_class)

func is_stunned() -> bool:
	return _is_stunned

func is_slowed() -> bool:
	return _is_slowed

func get_current_speed() -> float:
	"""Devuelve la velocidad actual considerando debuffs"""
	return move_speed


## DEPRECATED: Lógica migrada a _on_stats_changed_signal() que SÍ está conectada
## a PlayerStats.stat_changed. Esta función NO se conecta a ninguna señal.
## Se conserva como referencia pero nunca se invoca.
#func _on_stat_changed(stat_name: String, _old_value: float, _new_value: float) -> void:
#	if stat_name == 'shield_amount' or stat_name == 'max_shield':
#		update_health_bar()
#		_update_shield_vfx(_new_value if stat_name == 'shield_amount' else _old_value)
#	elif stat_name == 'pickup_range':
#		pickup_radius = _new_value
#		_update_pickup_area_size()

func _update_pickup_area_size() -> void:
	"""Actualizar el tamaño del área de recolección"""
	var pickup_area = get_node_or_null("PickupArea")
	if pickup_area:
		var collision = pickup_area.get_node_or_null("CollisionShape2D")
		if collision and collision.shape is CircleShape2D:
			var final_radius = pickup_radius
			var player_stats = get_tree().get_first_node_in_group("player_stats")
			if player_stats and player_stats.has_method("get_stat"):
				if player_stats.get_stat("infinite_pickup_range") > 0:
					final_radius = 10000.0
			collision.shape.radius = final_radius

func _on_health_damaged(amount: int, _element: String) -> void:
	# NOTE: Post-damage effects (grit, frost_nova, soul_link, thorns) are handled
	# exclusively in _process_post_damage_effects() via the anti-shotgun damage queue.
	# Do NOT duplicate that logic here to avoid double-processing.
	pass

func _update_turret_logic(delta: float, is_moving: bool) -> void:
	if is_moving:
		_stationary_timer = 0.0
		if _turret_buff_active:
			_remove_turret_buff()
	else:
		_stationary_timer += delta
		if not _turret_buff_active and _stationary_timer >= 2.0:
			var player_stats = get_tree().get_first_node_in_group("player_stats")
			if player_stats and player_stats.has_method("get_stat") and player_stats.get_stat("turret_bonus") > 0:
				_apply_turret_buff()

func _apply_turret_buff() -> void:
	_turret_buff_active = true
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats:
		# +50% Daño, +25% Ataque, +10 HP regen/s
		player_stats.add_temp_modifier("damage_mult", 0.5, 9999.0, "turret_bonus")
		player_stats.add_temp_modifier("attack_speed_mult", 0.25, 9999.0, "turret_bonus")
		player_stats.add_temp_modifier("health_regen", 10.0, 9999.0, "turret_bonus")

	FloatingText.spawn_text(global_position + Vector2(0, -80), "TURRET MODE!", Color.YELLOW)

	# Visual effect (Escudo visual o algo)
	modulate = Color(1.5, 1.2, 0.8) # Brillo dorado

func _remove_turret_buff() -> void:
	_turret_buff_active = false
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats:
		player_stats.remove_temp_modifiers_by_source("turret_bonus")

	modulate = Color.WHITE
