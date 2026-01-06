# WaveManager.gd
# Sistema de gestión de oleadas y eventos de spawn
# Trabaja en conjunto con EnemyManager para controlar el flujo del juego

extends Node
class_name WaveManager

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal phase_changed(phase_num: int, phase_config: Dictionary)
signal wave_started(wave_type: String, wave_config: Dictionary)
signal wave_completed(wave_type: String)
signal boss_incoming(boss_id: String, seconds_until: float)
signal boss_spawned(boss_id: String)
signal boss_defeated(boss_id: String)
signal elite_spawned(enemy_id: String)
signal special_event_started(event_name: String, event_config: Dictionary)
signal special_event_ended(event_name: String)
signal game_phase_infinite()  # Cuando entramos en fase infinita

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS (asignadas por Game.gd)
# ═══════════════════════════════════════════════════════════════════════════════

var enemy_manager: Node = null
var player: Node2D = null

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO DEL JUEGO
# ═══════════════════════════════════════════════════════════════════════════════

var game_time_seconds: float = 0.0
var game_time_minutes: float = 0.0

# Estado de fases
var current_phase: int = 1
var phase_config: Dictionary = {}

# Estado de oleadas
var current_wave_index: int = 0
var wave_sequence: Array = []
var time_since_last_wave: float = 0.0
var wave_in_progress: bool = false
var enemies_to_spawn_in_wave: int = 0
var wave_spawn_timer: float = 0.0
var current_wave_config: Dictionary = {}

# Estado de bosses
var boss_active: bool = false
var current_boss: Node2D = null
var boss_warning_shown: bool = false
var next_boss_minute: int = 5

# Estado de élites
var elites_spawned_this_game: int = 0
var time_since_last_elite: float = 0.0
var active_elite: Node2D = null

# Estado de eventos especiales
var active_event: String = ""
var event_time_remaining: float = 0.0
var event_config: Dictionary = {}
var last_event_minute: float = -1.0

# Spawn rate actual (puede ser modificado por eventos)
var current_spawn_rate: float = 0.8
var spawn_rate_override: float = -1.0  # -1 significa sin override

# Contadores de escalado infinito
var infinite_scaling_multipliers: Dictionary = {
	"hp": 1.0,
	"damage": 1.0,
	"spawn_rate": 1.0,
	"xp": 1.0
}

# Bandera para saltar inicialización automática (usada cuando restauramos desde guardado)
var skip_auto_init: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Las referencias son asignadas por Game.gd
	# Esperar un frame para que las referencias estén asignadas
	await get_tree().process_frame
	
	# Si no hay referencias asignadas, intentar buscarlas
	if not enemy_manager or not player:
		_find_references()
	
	# Solo inicializar fase si NO estamos restaurando desde un guardado
	# La bandera skip_auto_init es seteada por Game.gd antes de añadir al árbol
	if not skip_auto_init:
		_enter_phase(1)
	else:
		print("🌊 [WaveManager] Skip auto init - será restaurado desde save data")

func _find_references() -> void:
	"""Buscar referencias si no fueron asignadas por Game.gd (fallback)"""
	if not enemy_manager:
		# Buscar EnemyManager como hermano
		enemy_manager = get_node_or_null("../EnemyManager")
		if not enemy_manager:
			enemy_manager = get_tree().get_first_node_in_group("enemy_manager")
	
	if not player:
		# Buscar jugador
		player = get_tree().get_first_node_in_group("player")
		if not player:
			var player_container = get_node_or_null("../PlayerContainer")
			if player_container and player_container.get_child_count() > 0:
				player = player_container.get_child(0)
	
	if not enemy_manager:
		push_warning("WaveManager: No se encontró EnemyManager")
	if not player:
		push_warning("WaveManager: No se encontró Player")

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not enemy_manager or not player:
		_find_references()
		return
	
	# Actualizar tiempo de juego
	game_time_seconds += delta
	game_time_minutes = game_time_seconds / 60.0
	
	# Verificar desbloqueo de zonas en ArenaManager
	_check_zone_unlocks()
	
	# Actualizar fase si es necesario
	_check_phase_transition()
	
	# Actualizar escalado infinito
	_update_infinite_scaling()
	
	# Procesar oleadas
	_process_waves(delta)
	
	# Procesar spawns continuos
	_process_continuous_spawns(delta)
	
	# Verificar eventos de boss
	_check_boss_events()
	
	# Verificar élites
	_check_elite_spawns(delta)
	
	# Procesar eventos especiales activos
	_process_special_events(delta)
	
	# Verificar eventos programados
	_check_timed_events()

# ═══════════════════════════════════════════════════════════════════════════════
# DESBLOQUEO DE ZONAS
# ═══════════════════════════════════════════════════════════════════════════════

func _check_zone_unlocks() -> void:
	"""Verificar si hay zonas para desbloquear basándose en el tiempo"""
	var arena_manager = _get_arena_manager()
	if arena_manager and arena_manager.has_method("check_zone_unlocks"):
		arena_manager.check_zone_unlocks(game_time_seconds)

func _get_arena_manager() -> Node:
	"""Obtener referencia al ArenaManager"""
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("Game/ArenaManager")
	return null

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIÓN DE FASES
# ═══════════════════════════════════════════════════════════════════════════════

func _check_phase_transition() -> void:
	var new_phase = SpawnConfig.get_phase_for_minute(game_time_minutes)
	if new_phase != current_phase:
		_enter_phase(new_phase)

func _enter_phase(phase_num: int) -> void:
	current_phase = phase_num
	phase_config = SpawnConfig.get_phase_config(phase_num)
	
	# Actualizar configuración de spawn
	current_spawn_rate = phase_config.spawn_rate
	
	# Reiniciar secuencia de oleadas
	wave_sequence = SpawnConfig.get_wave_sequence_for_phase(phase_num)
	current_wave_index = 0
	
	# Actualizar EnemyManager
	if enemy_manager:
		enemy_manager.max_enemies = phase_config.max_enemies
	
	# Emitir señal
	phase_changed.emit(phase_num, phase_config)
	
	# Notificar fase infinita
	if phase_num == 5:
		game_phase_infinite.emit()
	
	print("WaveManager: Entrando en Fase %d - %s" % [phase_num, phase_config.name])

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIÓN DE OLEADAS
# ═══════════════════════════════════════════════════════════════════════════════

func _process_waves(delta: float) -> void:
	if wave_in_progress:
		_process_active_wave(delta)
	else:
		time_since_last_wave += delta
		if time_since_last_wave >= SpawnConfig.WAVE_INTERVAL_SECONDS:
			_start_next_wave()

func _start_next_wave() -> void:
	if wave_sequence.size() == 0:
		return
	
	var wave_type = wave_sequence[current_wave_index]
	current_wave_config = SpawnConfig.get_wave_config(wave_type)
	
	# Calcular enemigos a spawnear
	enemies_to_spawn_in_wave = current_wave_config.spawn_count
	
	# Aplicar escalado infinito al número de enemigos
	if current_phase == 5:
		enemies_to_spawn_in_wave = int(enemies_to_spawn_in_wave * infinite_scaling_multipliers.spawn_rate)
	
	wave_in_progress = true
	wave_spawn_timer = 0.0
	time_since_last_wave = 0.0
	
	# Anuncio de oleada si lo tiene
	if current_wave_config.announcement != "":
		_show_wave_announcement(current_wave_config.announcement)
	
	wave_started.emit(wave_type, current_wave_config)
	
	# Avanzar índice para siguiente oleada
	current_wave_index = (current_wave_index + 1) % wave_sequence.size()

func _process_active_wave(delta: float) -> void:
	if enemies_to_spawn_in_wave <= 0:
		_complete_wave()
		return
	
	wave_spawn_timer -= delta
	if wave_spawn_timer <= 0:
		_spawn_wave_enemy()
		wave_spawn_timer = current_wave_config.spawn_delay

func _spawn_wave_enemy() -> void:
	if not enemy_manager:
		return
	
	# PRIMERO: Determinar posición de spawn
	var spawn_pos = _calculate_wave_spawn_position()
	
	# SEGUNDO: Determinar tier basado en la ZONA donde va a spawnear
	var tier = _get_tier_for_position(spawn_pos)
	
	# Solicitar spawn al EnemyManager
	var enemy_id = _select_enemy_for_tier(tier)
	if enemy_id != "":
		enemy_manager.spawn_specific_enemy(enemy_id, spawn_pos)
	
	enemies_to_spawn_in_wave -= 1

func _get_wave_enemy_tier() -> int:
	# Si la oleada tiene tier override
	if current_wave_config.has("tier_override") and current_wave_config.tier_override != null:
		return current_wave_config.tier_override
	
	# Si tiene bonus de tier
	var tier_bonus = current_wave_config.get("tier_bonus", 0)
	
	# Seleccionar tier basado en pesos de la fase
	var tier = _select_weighted_tier(phase_config.tier_weights)
	tier = min(tier + tier_bonus, 4)
	
	# Asegurar que el tier esté disponible en esta fase
	if not tier in phase_config.available_tiers:
		tier = phase_config.available_tiers.max()
	
	return tier

func _get_tier_for_position(pos: Vector2) -> int:
	"""Obtener el tier de enemigo basado en la zona de la posición de spawn.
	   Las zonas bloqueadas fuerzan el spawn hacia la zona SAFE (tier 1).
	"""
	var arena_manager = _get_arena_manager()
	if arena_manager and arena_manager.has_method("get_spawn_tier_at_position"):
		var tier = arena_manager.get_spawn_tier_at_position(pos)
		print("[WaveManager] 🎯 Spawn en pos=%s → Tier %d (zona)" % [pos, tier])
		return tier
	
	# Fallback: usar sistema basado en fase
	print("[WaveManager] ⚠️ Sin ArenaManager, usando tier por fase")
	return _get_wave_enemy_tier()

func _select_weighted_tier(weights: Dictionary) -> int:
	var total_weight = 0.0
	for tier in weights:
		total_weight += weights[tier]
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for tier in weights:
		cumulative += weights[tier]
		if roll <= cumulative:
			return tier
	
	return 1  # Fallback

func _select_enemy_for_tier(tier: int) -> String:
	if not EnemyDatabase:
		return ""
	
	var enemies = EnemyDatabase.get_enemies_by_tier(tier)
	if enemies.size() == 0:
		return ""
	
	# Si la oleada fuerza variedad, usar rotación
	if current_wave_config.get("force_variety", false):
		# Implementación simple: aleatorio
		pass
	
	return enemies[randi() % enemies.size()]

func _calculate_wave_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var pattern = current_wave_config.get("spawn_pattern", "random")
	var player_pos = player.global_position
	var raw_pos: Vector2
	
	match pattern:
		"surround":
			# Distribuir equidistantemente
			var total = current_wave_config.spawn_count
			var spawned = current_wave_config.spawn_count - enemies_to_spawn_in_wave
			var angle = (TAU / total) * spawned
			var distance = randf_range(SpawnConfig.SPAWN_DISTANCE_MIN, SpawnConfig.SPAWN_DISTANCE_MAX)
			raw_pos = player_pos + Vector2.from_angle(angle) * distance
		
		"directional":
			# Desde una dirección fija con algo de varianza
			var base_angle = randf() * TAU  # Podría ser fijo por oleada
			var variance = deg_to_rad(22.5)
			var angle = base_angle + randf_range(-variance, variance)
			var distance = randf_range(SpawnConfig.SPAWN_DISTANCE_MIN, SpawnConfig.SPAWN_DISTANCE_MAX)
			raw_pos = player_pos + Vector2.from_angle(angle) * distance
		
		"cluster":
			# Grupo compacto
			var cluster_center = player_pos + Vector2.from_angle(randf() * TAU) * SpawnConfig.SPAWN_DISTANCE_MIN
			var cluster_radius = 100.0
			raw_pos = cluster_center + Vector2.from_angle(randf() * TAU) * randf() * cluster_radius
		
		_:  # "random"
			var angle = randf() * TAU
			var distance = randf_range(SpawnConfig.SPAWN_DISTANCE_MIN, SpawnConfig.SPAWN_DISTANCE_MAX)
			raw_pos = player_pos + Vector2.from_angle(angle) * distance
	
	# Limitar posición a zonas desbloqueadas
	return _clamp_spawn_to_unlocked_zones(raw_pos)

func _complete_wave() -> void:
	wave_in_progress = false
	var wave_type = wave_sequence[(current_wave_index - 1 + wave_sequence.size()) % wave_sequence.size()]
	wave_completed.emit(wave_type)

# ═══════════════════════════════════════════════════════════════════════════════
# SPAWN CONTINUO (entre oleadas)
# ═══════════════════════════════════════════════════════════════════════════════

var continuous_spawn_accumulator: float = 0.0

func _process_continuous_spawns(delta: float) -> void:
	if not enemy_manager:
		return
	
	# Reducir spawns durante boss
	var effective_spawn_rate = _get_effective_spawn_rate()
	
	# Si hay override de evento
	if spawn_rate_override >= 0:
		effective_spawn_rate = spawn_rate_override
	
	continuous_spawn_accumulator += effective_spawn_rate * delta
	
	while continuous_spawn_accumulator >= 1.0:
		continuous_spawn_accumulator -= 1.0
		_spawn_continuous_enemy()

func _get_effective_spawn_rate() -> float:
	var rate = current_spawn_rate
	
	# Reducir durante boss si está configurado
	if boss_active and SpawnConfig.BOSS_CONFIG.reduce_spawns_during_boss:
		rate *= SpawnConfig.BOSS_CONFIG.spawn_rate_during_boss
	
	# Aplicar escalado infinito
	rate *= infinite_scaling_multipliers.spawn_rate
	
	# Aplicar cap
	rate = min(rate, SpawnConfig.INFINITE_SCALING.max_spawn_rate)
	
	return rate

func _spawn_continuous_enemy() -> void:
	if not enemy_manager:
		return
	
	# Verificar límite de enemigos
	if enemy_manager.get_enemy_count() >= enemy_manager.max_enemies:
		return
	
	if not player:
		return
	
	# PRIMERO: Calcular posición de spawn
	var spawn_pos = _get_random_spawn_position()
	
	# SEGUNDO: Determinar tier basado en la ZONA de spawn
	var tier = _get_tier_for_position(spawn_pos)
	
	var enemy_id = _select_enemy_for_tier(tier)
	if enemy_id != "":
		enemy_manager.spawn_specific_enemy(enemy_id, spawn_pos)

func _get_random_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var angle = randf() * TAU
	var distance = randf_range(SpawnConfig.SPAWN_DISTANCE_MIN, SpawnConfig.SPAWN_DISTANCE_MAX)
	var raw_pos = player.global_position + Vector2.from_angle(angle) * distance
	
	# Limitar posición a zonas desbloqueadas
	return _clamp_spawn_to_unlocked_zones(raw_pos)

func _clamp_spawn_to_unlocked_zones(pos: Vector2) -> Vector2:
	"""Limitar posición de spawn al radio máximo de zonas desbloqueadas.
	   Si la posición está más allá de la zona desbloqueada más externa,
	   se mueve hacia adentro manteniendo la dirección."""
	var arena_manager = _get_arena_manager()
	if not arena_manager:
		return pos
	
	# Obtener el radio máximo permitido
	var max_radius = arena_manager.get_max_allowed_radius()
	var dist_from_center = pos.length()
	
	# Si está dentro del radio permitido, no hacer nada
	if dist_from_center <= max_radius:
		return pos
	
	# Si está fuera, mover hacia el borde de la zona desbloqueada
	# Mantener un margen de 50 pixels para no spawnear justo en el borde
	var clamped_radius = max_radius - 50.0
	var direction = pos.normalized()
	var clamped_pos = direction * clamped_radius
	
	print("[WaveManager] 🚧 Spawn clampado: %s → %s (radio %d → %d)" % [
		pos, clamped_pos, int(dist_from_center), int(clamped_radius)])
	
	return clamped_pos

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIÓN DE BOSSES
# ═══════════════════════════════════════════════════════════════════════════════

func _check_boss_events() -> void:
	var current_minute = int(game_time_minutes)
	
	# Verificar si debemos mostrar advertencia de boss
	if not boss_warning_shown and current_minute >= next_boss_minute - 1:
		var time_to_boss = (next_boss_minute * 60.0) - game_time_seconds
		if time_to_boss <= SpawnConfig.BOSS_CONFIG.pre_spawn_warning_seconds and time_to_boss > 0:
			var boss_id = SpawnConfig.get_boss_for_minute(next_boss_minute)
			if boss_id != "":
				boss_warning_shown = true
				boss_incoming.emit(boss_id, time_to_boss)
				_show_boss_warning(boss_id)
	
	# Verificar si es momento de spawnear boss
	if not boss_active and current_minute >= next_boss_minute:
		var boss_id = SpawnConfig.get_boss_for_minute(next_boss_minute)
		if boss_id != "":
			_spawn_boss(boss_id)
			
			# Calcular siguiente boss
			if next_boss_minute <= 20:
				next_boss_minute += 5
			else:
				# En fase infinita, cada 5 minutos
				next_boss_minute = (int(game_time_minutes / 5) + 1) * 5

func _spawn_boss(boss_id: String) -> void:
	if not enemy_manager or not player:
		return
	
	boss_active = true
	boss_warning_shown = false
	
	# Posición de spawn del boss
	var spawn_pos = player.global_position + Vector2.from_angle(randf() * TAU) * SpawnConfig.SPAWN_DISTANCE_BOSS
	
	# Aplicar escalado infinito al boss
	var scale_multipliers = {
		"hp_multiplier": infinite_scaling_multipliers.hp,
		"damage_multiplier": infinite_scaling_multipliers.damage
	}
	
	current_boss = enemy_manager.spawn_boss(boss_id, spawn_pos, scale_multipliers)
	
	if current_boss:
		# Conectar señal de muerte
		if current_boss.has_signal("died"):
			current_boss.died.connect(_on_boss_died.bind(boss_id))
		
		boss_spawned.emit(boss_id)
		_show_boss_spawn_announcement(boss_id)

func _on_boss_died(boss_id: String) -> void:
	boss_active = false
	current_boss = null
	boss_defeated.emit(boss_id)
	print("WaveManager: Boss derrotado - %s" % boss_id)

func _show_boss_warning(boss_id: String) -> void:
	print("⚠️ ¡BOSS INCOMING: %s!" % boss_id)
	# Aquí se conectaría con el sistema de UI

func _show_boss_spawn_announcement(boss_id: String) -> void:
	print("👹 ¡BOSS APARECIÓ: %s!" % boss_id)
	# Aquí se conectaría con el sistema de UI

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIÓN DE ÉLITES
# ═══════════════════════════════════════════════════════════════════════════════

func _check_elite_spawns(delta: float) -> void:
	# No spawnear élites antes del tiempo mínimo
	if game_time_minutes < SpawnConfig.ELITE_CONFIG.first_spawn_minute:
		return
	
	# Ya hay un élite activo
	if active_elite and is_instance_valid(active_elite):
		return
	else:
		active_elite = null
	
	# Verificar límite de élites por partida
	var max_elites = SpawnConfig.ELITE_CONFIG.max_per_game_base
	if current_phase == 5:
		# En fase infinita, añadir más
		var intervals = (game_time_minutes - 20) / 5
		max_elites += int(intervals * SpawnConfig.ELITE_CONFIG.elite_per_5min_infinite)
	
	if elites_spawned_this_game >= max_elites:
		return
	
	# Calcular intervalo de spawn
	time_since_last_elite += delta
	var interval = SpawnConfig.ELITE_CONFIG.spawn_interval_base
	interval += randf_range(-SpawnConfig.ELITE_CONFIG.spawn_interval_variance, 
						   SpawnConfig.ELITE_CONFIG.spawn_interval_variance)
	
	# En fase infinita, élites más frecuentes
	if current_phase == 5:
		interval *= 0.7
	
	if time_since_last_elite >= interval:
		_spawn_elite()
		time_since_last_elite = 0.0

func _spawn_elite() -> void:
	if not enemy_manager or not player:
		return
	
	# Seleccionar un enemigo aleatorio de los tiers disponibles
	var available_tiers = phase_config.available_tiers.duplicate()
	# Élites son preferiblemente de tiers altos
	if available_tiers.size() > 1:
		available_tiers.sort()
		available_tiers = available_tiers.slice(-2)  # Los 2 tiers más altos
	
	var tier = available_tiers[randi() % available_tiers.size()]
	var enemy_id = _select_enemy_for_tier(tier)
	
	if enemy_id == "":
		return
	
	var spawn_pos = _get_random_spawn_position()
	
	# Crear élite con escalado
	var elite_multipliers = {
		"hp_multiplier": infinite_scaling_multipliers.hp,
		"damage_multiplier": infinite_scaling_multipliers.damage
	}
	
	active_elite = enemy_manager.spawn_elite(enemy_id, spawn_pos, elite_multipliers)
	
	if active_elite:
		elites_spawned_this_game += 1
		elite_spawned.emit(enemy_id)
		_show_wave_announcement(SpawnConfig.ELITE_CONFIG.spawn_announcement)
		
		# Conectar señal de muerte
		if active_elite.has_signal("died"):
			active_elite.died.connect(_on_elite_died)

func _on_elite_died() -> void:
	active_elite = null

# ═══════════════════════════════════════════════════════════════════════════════
# EVENTOS ESPECIALES
# ═══════════════════════════════════════════════════════════════════════════════

func _check_timed_events() -> void:
	if active_event != "":
		return  # Ya hay un evento activo
	
	var event_name = SpawnConfig.should_trigger_event(game_time_minutes, last_event_minute)
	if event_name != "":
		_start_special_event(event_name)
		last_event_minute = game_time_minutes

func _start_special_event(event_name: String) -> void:
	if not SpawnConfig.SPECIAL_EVENTS.has(event_name):
		return
	
	active_event = event_name
	event_config = SpawnConfig.SPECIAL_EVENTS[event_name]
	event_time_remaining = event_config.duration_seconds
	
	# Aplicar efectos del evento
	if event_config.has("spawn_multiplier"):
		if event_config.spawn_multiplier == 0.0:
			spawn_rate_override = 0.0
		else:
			spawn_rate_override = current_spawn_rate * event_config.spawn_multiplier
	
	# Mostrar anuncio
	if event_config.has("announcement"):
		_show_wave_announcement(event_config.announcement)
	
	special_event_started.emit(event_name, event_config)
	print("WaveManager: Evento especial iniciado - %s" % event_name)

func _process_special_events(delta: float) -> void:
	if active_event == "":
		return
	
	event_time_remaining -= delta
	
	# Procesar efectos específicos del evento
	match active_event:
		"elite_surge":
			# Spawn de élites durante el evento
			pass  # Ya manejado por el sistema de élites
		"breather":
			# Curar al jugador durante el respiro
			if player and player.has_method("heal"):
				var heal_per_second = (event_config.get("heal_player_percent", 0.1) * player.max_hp) / event_config.duration_seconds
				player.heal(heal_per_second * delta)
	
	if event_time_remaining <= 0:
		_end_special_event()

func _end_special_event() -> void:
	spawn_rate_override = -1.0  # Restaurar spawn rate normal
	
	special_event_ended.emit(active_event)
	print("WaveManager: Evento especial terminado - %s" % active_event)
	
	active_event = ""
	event_config = {}

func _show_wave_announcement(text: String) -> void:
	print("📢 %s" % text)
	# Aquí se conectaría con el sistema de UI para mostrar el anuncio

# ═══════════════════════════════════════════════════════════════════════════════
# ESCALADO INFINITO
# ═══════════════════════════════════════════════════════════════════════════════

func _update_infinite_scaling() -> void:
	infinite_scaling_multipliers = SpawnConfig.get_infinite_scaling_multiplier(game_time_minutes)
	
	# Actualizar max_enemies en fase infinita
	if current_phase == 5:
		var intervals = int((game_time_minutes - 20) / SpawnConfig.INFINITE_SCALING.scaling_interval_minutes)
		var additional_enemies = intervals * SpawnConfig.INFINITE_SCALING.max_enemies_increase_per_interval
		var new_max = phase_config.max_enemies + additional_enemies
		new_max = min(new_max, SpawnConfig.INFINITE_SCALING.max_enemies_cap)
		
		if enemy_manager:
			enemy_manager.max_enemies = new_max

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func get_current_phase() -> int:
	return current_phase

func get_phase_name() -> String:
	return phase_config.get("name", "Unknown")

func get_game_time() -> float:
	return game_time_seconds

func get_game_time_formatted() -> String:
	var minutes = int(game_time_seconds / 60)
	var seconds = int(game_time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

func is_boss_active() -> bool:
	return boss_active

func get_current_boss() -> Node2D:
	return current_boss

func get_scaling_multipliers() -> Dictionary:
	return infinite_scaling_multipliers.duplicate()

func force_spawn_wave(wave_type: String) -> void:
	"""Forzar una oleada específica (para testing/debug)"""
	if SpawnConfig.WAVE_TYPES.has(wave_type):
		current_wave_config = SpawnConfig.get_wave_config(wave_type)
		enemies_to_spawn_in_wave = current_wave_config.spawn_count
		wave_in_progress = true
		wave_spawn_timer = 0.0
		wave_started.emit(wave_type, current_wave_config)

func force_spawn_boss(boss_id: String) -> void:
	"""Forzar spawn de un boss (para testing/debug)"""
	_spawn_boss(boss_id)

func force_spawn_elite() -> void:
	"""Forzar spawn de un élite (para testing/debug)"""
	_spawn_elite()

func skip_to_phase(phase_num: int) -> void:
	"""Saltar a una fase específica (para testing/debug)"""
	if phase_num >= 1 and phase_num <= 5:
		var phase_cfg = SpawnConfig.get_phase_config(phase_num)
		game_time_seconds = phase_cfg.start_minute * 60.0
		game_time_minutes = phase_cfg.start_minute
		_enter_phase(phase_num)

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN PARA GUARDADO/REANUDACIÓN DE PARTIDA
# ═══════════════════════════════════════════════════════════════════════════════

func to_save_data() -> Dictionary:
	"""Serializar estado completo del WaveManager para guardado"""
	var data: Dictionary = {
		# Tiempo
		"game_time_seconds": game_time_seconds,
		"game_time_minutes": game_time_minutes,
		
		# Estado de fases
		"current_phase": current_phase,
		
		# Estado de oleadas
		"current_wave_index": current_wave_index,
		"time_since_last_wave": time_since_last_wave,
		"wave_in_progress": wave_in_progress,
		"enemies_to_spawn_in_wave": enemies_to_spawn_in_wave,
		"wave_spawn_timer": wave_spawn_timer,
		
		# Estado de bosses
		"boss_active": boss_active,
		"boss_warning_shown": boss_warning_shown,
		"next_boss_minute": next_boss_minute,
		
		# Estado de élites
		"elites_spawned_this_game": elites_spawned_this_game,
		"time_since_last_elite": time_since_last_elite,
		
		# Estado de eventos especiales
		"active_event": active_event,
		"event_time_remaining": event_time_remaining,
		"last_event_minute": last_event_minute,
		
		# Spawn rates
		"current_spawn_rate": current_spawn_rate,
		"spawn_rate_override": spawn_rate_override,
		"continuous_spawn_accumulator": continuous_spawn_accumulator,
		
		# Escalado infinito
		"infinite_scaling_multipliers": infinite_scaling_multipliers.duplicate()
	}
	
	# Guardar boss actual si existe
	if boss_active and current_boss and is_instance_valid(current_boss):
		data["current_boss_data"] = {
			"enemy_id": current_boss.enemy_id if "enemy_id" in current_boss else "",
			"position": {"x": current_boss.global_position.x, "y": current_boss.global_position.y},
			"current_hp": current_boss.health_component.current_health if current_boss.get("health_component") else 0,
			"max_hp": current_boss.health_component.max_health if current_boss.get("health_component") else 0
		}
	
	return data

func from_save_data(data: Dictionary) -> void:
	"""Restaurar estado del WaveManager desde datos guardados"""
	if data.is_empty():
		return
	
	print("🌊 [WaveManager] Restaurando desde save data...")
	
	# Tiempo
	game_time_seconds = data.get("game_time_seconds", 0.0)
	game_time_minutes = data.get("game_time_minutes", 0.0)
	
	# Estado de fases - entrar a la fase guardada sin reiniciar oleadas
	current_phase = data.get("current_phase", 1)
	phase_config = SpawnConfig.get_phase_config(current_phase)
	wave_sequence = SpawnConfig.get_wave_sequence_for_phase(current_phase)
	
	# Estado de oleadas
	current_wave_index = data.get("current_wave_index", 0)
	time_since_last_wave = data.get("time_since_last_wave", 0.0)
	wave_in_progress = data.get("wave_in_progress", false)
	enemies_to_spawn_in_wave = data.get("enemies_to_spawn_in_wave", 0)
	wave_spawn_timer = data.get("wave_spawn_timer", 0.0)
	
	if wave_in_progress and wave_sequence.size() > 0:
		# Restaurar la configuración de la oleada actual
		var wave_idx = (current_wave_index - 1 + wave_sequence.size()) % wave_sequence.size()
		var wave_type = wave_sequence[wave_idx]
		current_wave_config = SpawnConfig.get_wave_config(wave_type)
	
	# Estado de bosses
	boss_active = data.get("boss_active", false)
	boss_warning_shown = data.get("boss_warning_shown", false)
	next_boss_minute = data.get("next_boss_minute", 5)
	
	# Estado de élites
	elites_spawned_this_game = data.get("elites_spawned_this_game", 0)
	time_since_last_elite = data.get("time_since_last_elite", 0.0)
	
	# Estado de eventos especiales
	active_event = data.get("active_event", "")
	event_time_remaining = data.get("event_time_remaining", 0.0)
	last_event_minute = data.get("last_event_minute", -1.0)
	
	if active_event != "" and SpawnConfig.SPECIAL_EVENTS.has(active_event):
		event_config = SpawnConfig.SPECIAL_EVENTS[active_event]
	
	# Spawn rates
	current_spawn_rate = data.get("current_spawn_rate", 0.8)
	spawn_rate_override = data.get("spawn_rate_override", -1.0)
	continuous_spawn_accumulator = data.get("continuous_spawn_accumulator", 0.0)
	
	# Escalado infinito
	if data.has("infinite_scaling_multipliers"):
		infinite_scaling_multipliers = data.get("infinite_scaling_multipliers", {
			"hp": 1.0,
			"damage": 1.0,
			"spawn_rate": 1.0,
			"xp": 1.0
		})
	
	# Actualizar max_enemies en EnemyManager
	if enemy_manager:
		enemy_manager.max_enemies = phase_config.max_enemies
	
	# Buscar el boss restaurado en los enemigos (si boss_active)
	# Esto se hace DESPUÉS de que EnemyManager haya restaurado los enemigos
	# Por eso usamos call_deferred
	if boss_active:
		call_deferred("_find_restored_boss")
	
	print("🌊 [WaveManager] Estado restaurado:")
	print("   - Fase: %d" % current_phase)
	print("   - Tiempo: %.1f seg (%.1f min)" % [game_time_seconds, game_time_minutes])
	print("   - Boss activo: %s" % boss_active)
	print("   - Próximo boss: minuto %d" % next_boss_minute)
	print("   - Evento activo: %s" % active_event)

func _find_restored_boss() -> void:
	"""Buscar el boss restaurado en active_enemies de EnemyManager"""
	if not enemy_manager:
		return
	
	for enemy in enemy_manager.active_enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_boss" in enemy and enemy.is_boss:
			current_boss = enemy
			# Conectar señal de muerte
			if current_boss.has_signal("died") and not current_boss.died.is_connected(_on_boss_died):
				var boss_id = current_boss.enemy_id if "enemy_id" in current_boss else "unknown_boss"
				current_boss.died.connect(_on_boss_died.bind(boss_id))
			print("🔥 [WaveManager] Boss restaurado encontrado: %s" % current_boss.name)
			return
	
	# Si no encontramos el boss pero boss_active es true, algo falló
	if boss_active:
		print("⚠️ [WaveManager] boss_active=true pero no se encontró boss en enemigos")
		boss_active = false
