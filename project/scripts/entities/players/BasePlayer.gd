# BasePlayer.gd
# Clase base genérica para todos los personajes jugables
# Proporciona movimiento, stats, salud, manejo de armas, etc.
# Las clases específicas (Wizard, Rogue, etc.) heredan de aquí

extends CharacterBody2D
class_name BasePlayer

# ========== SEÑALES ==========
signal player_damaged(amount: int, current_hp: int)
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

# ========== SISTEMA VISUAL DE DEBUFFS ==========
var _status_visual_node: Node2D = null
var _status_aura_timer: float = 0.0
var _status_flash_timer: float = 0.0
const STATUS_FLASH_INTERVAL: float = 0.15
const STATUS_AURA_PULSE_SPEED: float = 4.0

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
		game_manager = _gt.root.get_node_or_null("SpellloopGame/GameManager")
	
	# Buscar o crear AttackManager
	attack_manager = _gt.root.get_node_or_null("AttackManager")
	if not attack_manager and game_manager:
		attack_manager = game_manager.get_node_or_null("AttackManager")
	
	# Debug desactivado: print("[%s] GameManager: %s | AttackManager: %s" % [character_class, "✓" if game_manager else "✗", "✓" if attack_manager else "✗"])

func _setup_weapons_deferred() -> void:
	"""Configurar armas después de que todo esté listo"""
	# Usar await para asegurar que todo esté inicializado
	await get_tree().process_frame
	
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

func _process(delta: float) -> void:
	"""Actualizar animación según dirección de movimiento"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	# NO interrumpir animaciones especiales (cast, hit, death)
	if _is_casting or _is_dying:
		return
	
	# Obtener input del jugador
	var input_manager = get_tree().root.get_node_or_null("InputManager")
	if not input_manager:
		return
	
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

func _physics_process(delta: float) -> void:
	"""Actualizar física y debuffs"""
	# El movimiento se maneja en SpellloopPlayer para evitar duplicación
	_process_debuffs(delta)
	_update_status_visuals(delta)
	_update_revive_immunity(delta)

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
	
	# Redibujar auras
	if _status_visual_node and _has_any_status():
		_status_visual_node.queue_redraw()

func _has_any_status() -> bool:
	"""Verificar si tiene algún estado activo"""
	return _burn_timer > 0 or _slow_timer > 0 or _poison_timer > 0 or _stun_timer > 0 or _weakness_timer > 0 or _curse_timer > 0

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
		flash_color = Color(0.8, 0.5, 0.9, 1.0)  # Morado weakness
		should_flash = true
	elif _curse_timer > 0:
		flash_color = Color(0.6, 0.4, 0.7, 1.0)  # Morado oscuro curse
		should_flash = true
	
	if should_flash:
		# Alternar entre color de estado y blanco
		var pulse = sin(_status_aura_timer * 3.0)
		if pulse > 0:
			animated_sprite.modulate = flash_color
		else:
			animated_sprite.modulate = Color.WHITE
	else:
		animated_sprite.modulate = Color.WHITE

func _draw_status_effects() -> void:
	"""Dibujar auras y efectos visuales de estado"""
	if not _status_visual_node:
		return
	
	var pulse = (sin(_status_aura_timer) + 1.0) / 2.0  # 0.0 - 1.0
	
	# === AURA DE FUEGO (Burn) ===
	if _burn_timer > 0:
		var fire_alpha = 0.3 + pulse * 0.2
		var fire_radius = 20.0 + pulse * 5.0
		# Aura exterior
		_status_visual_node.draw_circle(Vector2.ZERO, fire_radius, Color(1.0, 0.5, 0.1, fire_alpha * 0.5))
		# Anillo interior
		_status_visual_node.draw_arc(Vector2.ZERO, fire_radius * 0.7, 0, TAU, 16, Color(1.0, 0.3, 0.0, fire_alpha), 2.0)
		# Pequeñas llamas
		for i in range(4):
			var angle = _status_aura_timer + i * TAU / 4.0
			var flame_pos = Vector2(cos(angle), sin(angle)) * (fire_radius * 0.6)
			var flame_size = 3.0 + pulse * 2.0
			_status_visual_node.draw_circle(flame_pos, flame_size, Color(1.0, 0.6, 0.2, fire_alpha))
	
	# === AURA DE HIELO (Slow) ===
	if _slow_timer > 0:
		var ice_alpha = 0.25 + pulse * 0.15
		var ice_radius = 22.0 + pulse * 3.0
		# Aura exterior azulada
		_status_visual_node.draw_circle(Vector2.ZERO, ice_radius, Color(0.4, 0.7, 1.0, ice_alpha * 0.4))
		# Cristales de hielo giratorios
		for i in range(6):
			var angle = _status_aura_timer * 0.5 + i * TAU / 6.0
			var crystal_pos = Vector2(cos(angle), sin(angle)) * (ice_radius * 0.7)
			# Dibujar cristal como rombo pequeño
			var crystal_size = 4.0
			var points = PackedVector2Array([
				crystal_pos + Vector2(0, -crystal_size),
				crystal_pos + Vector2(crystal_size * 0.5, 0),
				crystal_pos + Vector2(0, crystal_size),
				crystal_pos + Vector2(-crystal_size * 0.5, 0)
			])
			_status_visual_node.draw_colored_polygon(points, Color(0.6, 0.9, 1.0, ice_alpha))
	
	# === AURA DE VENENO (Poison) ===
	if _poison_timer > 0:
		var poison_alpha = 0.2 + pulse * 0.15
		var poison_radius = 18.0 + pulse * 4.0
		# Aura verde tóxica
		_status_visual_node.draw_circle(Vector2.ZERO, poison_radius, Color(0.4, 0.8, 0.2, poison_alpha * 0.4))
		# Burbujas de veneno
		for i in range(5):
			var bubble_angle = _status_aura_timer * 0.8 + i * TAU / 5.0
			var bubble_offset = sin(_status_aura_timer * 2.0 + i) * 3.0
			var bubble_pos = Vector2(cos(bubble_angle), sin(bubble_angle)) * (poison_radius * 0.5 + bubble_offset)
			var bubble_size = 2.0 + sin(_status_aura_timer * 3.0 + i * 1.5) * 1.0
			_status_visual_node.draw_circle(bubble_pos, bubble_size, Color(0.5, 0.9, 0.3, poison_alpha))
	
	# === AURA DE STUN ===
	if _stun_timer > 0:
		var stun_alpha = 0.4 + pulse * 0.3
		# Estrellas giratorias de stun
		for i in range(3):
			var star_angle = _status_aura_timer * 2.0 + i * TAU / 3.0
			var star_pos = Vector2(cos(star_angle), sin(star_angle)) * 15.0 + Vector2(0, -20)
			_draw_star(star_pos, 5.0, Color(1.0, 1.0, 0.3, stun_alpha))
	
	# === AURA DE WEAKNESS ===
	if _weakness_timer > 0:
		var weak_alpha = 0.15 + pulse * 0.1
		var weak_radius = 24.0
		# Aura morada débil
		_status_visual_node.draw_arc(Vector2.ZERO, weak_radius, 0, TAU, 16, Color(0.6, 0.2, 0.6, weak_alpha), 3.0)
		# Flechas hacia abajo
		for i in range(3):
			var arrow_x = (i - 1) * 15.0
			var arrow_y = -25.0 + sin(_status_aura_timer * 2.0 + i) * 3.0
			_draw_down_arrow(Vector2(arrow_x, arrow_y), Color(0.7, 0.3, 0.7, weak_alpha * 2.0))
	
	# === AURA DE CURSE ===
	if _curse_timer > 0:
		var curse_alpha = 0.2 + pulse * 0.15
		var curse_radius = 20.0
		# Símbolos de maldición giratorios
		_status_visual_node.draw_arc(Vector2.ZERO, curse_radius, 0, TAU, 12, Color(0.4, 0.2, 0.5, curse_alpha), 2.0)
		# Runas pequeñas
		for i in range(4):
			var rune_angle = _status_aura_timer * 0.3 + i * TAU / 4.0
			var rune_pos = Vector2(cos(rune_angle), sin(rune_angle)) * (curse_radius * 0.8)
			_status_visual_node.draw_rect(Rect2(rune_pos - Vector2(2, 2), Vector2(4, 4)), Color(0.5, 0.2, 0.6, curse_alpha))

func _draw_star(pos: Vector2, size: float, col: Color) -> void:
	"""Dibujar una estrella de 4 puntas"""
	var points = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8.0 - TAU / 16.0
		var r = size if i % 2 == 0 else size * 0.4
		points.append(pos + Vector2(cos(angle), sin(angle)) * r)
	_status_visual_node.draw_colored_polygon(points, col)

func _draw_down_arrow(pos: Vector2, col: Color) -> void:
	"""Dibujar una flecha hacia abajo (weakness)"""
	var points = PackedVector2Array([
		pos + Vector2(-4, -4),
		pos + Vector2(4, -4),
		pos + Vector2(0, 4)
	])
	_status_visual_node.draw_colored_polygon(points, col)

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
	
	# 0. Verificar inmunidad de revive
	if _revive_immunity_timer > 0:
		FloatingText.spawn_text(global_position + Vector2(0, -35), "INMUNE", Color(1.0, 0.9, 0.3, 0.8))
		return
	
	# Obtener PlayerStats para dodge, armor, shield y thorns
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	
	# 1. Verificar esquiva (dodge) primero
	if player_stats and player_stats.has_method("get_stat"):
		var dodge_chance = player_stats.get_stat("dodge_chance")
		if dodge_chance > 0 and randf() < minf(dodge_chance, 0.6):  # Máximo 60% de esquiva
			# ¡Esquivó el daño!
			# Debug desactivado: print("[%s] ✨ ¡ESQUIVADO! (%.0f%% chance)" % [character_class, dodge_chance * 100])
			FloatingText.spawn_text(global_position + Vector2(0, -35), "DODGE!", Color(0.3, 0.9, 1.0))
			return
	
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
	
	if effective_armor > 0:
		final_damage = maxi(1, final_damage - int(effective_armor))  # Mínimo 1 de daño
	
	# 4. Aplicar damage_taken_mult si existe
	if player_stats and player_stats.has_method("get_stat"):
		var damage_taken_mult = player_stats.get_stat("damage_taken_mult")
		if damage_taken_mult != 1.0:
			final_damage = int(final_damage * damage_taken_mult)
	
	# 5. Aplicar weakness si está activo (multiplicador de daño recibido)
	if _is_weakened:
		final_damage = int(final_damage * (1.0 + _weakness_amount))
	
	# Aplicar daño al HealthComponent
	health_component.take_damage(final_damage)
	
	# 6. THORNS - Reflejar daño al atacante
	if attacker and is_instance_valid(attacker) and player_stats:
		_apply_thorns_damage(attacker, amount, player_stats)
	
	# Emitir señal para feedback visual (screen shake, vignette, etc.)
	player_took_damage.emit(final_damage, element)
	
	# Mostrar texto flotante de daño sobre el player
	FloatingText.spawn_player_damage(global_position + Vector2(0, -35), final_damage, element)
	
	# Efecto visual de impacto
	_play_damage_flash(element)
	
	var armor_text = " [ARMOR: -%d]" % (amount - final_damage) if effective_armor > 0 and amount > final_damage else ""
	# Debug desactivado: print("[%s] 💥 Daño recibido: %d → %d (%s) (HP: %d/%d)%s%s" % [character_class, amount, final_damage, element, health_component.current_health, max_hp, " [WEAKENED]" if _is_weakened else "", armor_text])

func _apply_thorns_damage(attacker: Node, damage_received: int, player_stats: Node) -> void:
	"""Aplicar daño de espinas al atacante"""
	var thorns_flat = player_stats.get_stat("thorns") if player_stats.has_method("get_stat") else 0.0
	var thorns_percent = player_stats.get_stat("thorns_percent") if player_stats.has_method("get_stat") else 0.0
	
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

func _play_damage_flash(element: String) -> void:
	"""Flash de daño según el elemento"""
	if not animated_sprite:
		return
	
	var flash_color: Color
	match element:
		"fire":
			flash_color = Color(2.0, 0.6, 0.2, 1.0)
		"ice":
			flash_color = Color(0.6, 0.9, 2.0, 1.0)
		"poison":
			flash_color = Color(0.6, 2.0, 0.4, 1.0)
		"dark", "void", "shadow":
			flash_color = Color(1.2, 0.4, 1.5, 1.0)
		"lightning":
			flash_color = Color(2.0, 2.0, 0.5, 1.0)
		_:
			flash_color = Color(2.0, 0.3, 0.3, 1.0)  # Rojo por defecto
	
	animated_sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
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
	"""Efecto visual cuando el escudo absorbe todo el daño"""
	if not animated_sprite:
		return
	
	# Flash azul de escudo
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(0.5, 0.8, 2.0, 1.0), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

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
		
		# Debug desactivado: print("[%s] Curación: +%d (HP: %d/%d)%s" % [character_class, healed, health_component.current_health, max_hp, " [CURSED]" if _is_cursed else ""])

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
	max_hp = max_val  # Sincronizar también max_hp
	player_damaged.emit(current, max_val)

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
	
	# Hacer al jugador invulnerable durante la animación de muerte
	set_collision_layer_value(1, false)
	
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		# Detener animación actual y preparar la de muerte
		animated_sprite.stop()
		animated_sprite.animation = "death"
		animated_sprite.frame = 0
		
		# Restaurar escala normal por si estaba casteando
		animated_sprite.scale = Vector2(player_sprite_scale, player_sprite_scale)
		
		animated_sprite.play("death")
		# Conectar señal para emitir player_died cuando termine la animación
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	else:
		# Si no hay animación de muerte, emitir señal directamente
		player_died.emit()

func _on_death_animation_finished() -> void:
	"""Callback cuando termina la animación de muerte"""
	player_died.emit()

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
	
	# Efectos visuales de revive
	_play_revive_effects()
	
	# Mostrar mensaje
	FloatingText.spawn_text(global_position + Vector2(0, -50), "¡REVIVE!", Color(1.0, 0.9, 0.3))
	
	# Inmunidad temporal (2 segundos)
	_grant_revive_immunity(2.0)
	
	# Notificar cambio de salud
	if health_component:
		health_component.health_changed.emit(revive_hp, int(max_health))
	
	print("[%s] 💫 ¡REVIVIDO! HP: %d/%d (Revives restantes: %d)" % [
		character_class, revive_hp, int(max_health), current_revives - 1
	])

func _play_revive_effects() -> void:
	"""Efectos visuales de revive"""
	if not animated_sprite:
		return
	
	# Flash dorado brillante
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 1.8, 0.5, 1.0), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.5)
	
	# Partículas de resurrección
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 20
	particles.lifetime = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color(1.0, 0.9, 0.3, 1.0)
	add_child(particles)
	
	# Auto-destruir partículas
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)
	
	# Sonido de revive
	var audio_manager = get_tree().get_first_node_in_group("audio_manager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("phoenix_resurrection")

var _revive_immunity_timer: float = 0.0

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
	"""Crear barra de vida - SOBRESCRIBIR EN SUBCLASES SI NECESARIO"""
	if not health_bar_container:
		health_bar_container = Node2D.new()
		health_bar_container.name = "HealthBarContainer"
		add_child(health_bar_container)
		
		# Calcular offset Y basado en la escala del sprite
		# La barra debe estar justo encima de la cabeza con un pequeño margen
		var sprite_scale = player_sprite_scale
		var visual_calibrator = get_tree().root.get_node_or_null("VisualCalibrator") if get_tree() else null
		if visual_calibrator and visual_calibrator.has_method("get_player_scale"):
			sprite_scale = visual_calibrator.get_player_scale()
		
		# Fórmula equilibrada: base + ajuste por escala
		# Con escala 0.25 -> -40px (justo sobre la cabeza)
		# Con escala 0.35 -> -44px (se adapta a sprites más grandes)
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
	
	# Debug desactivado: print("[%s] ❄️ Ralentizado %.0f%% por %.1fs" % [character_class, _slow_amount * 100, duration])

func _clear_slow() -> void:
	_is_slowed = false
	_slow_amount = 0.0
	move_speed = base_move_speed
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
	
	# Debug desactivado: print("[%s] ⚡ Aturdido por %.1fs" % [character_class, duration])

func _clear_stun() -> void:
	_is_stunned = false
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
