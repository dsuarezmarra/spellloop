# EnemyManager.gd
# Gestor de spawn y control de enemigos
# Usa EnemyDatabase para obtener datos de enemigos
#
# Características:
# - Spawn por tiers según tiempo de juego
# - Bosses cada 5 minutos
# - Élites aleatorios con aura
# - Escalado exponencial después del minuto 20

extends Node
class_name EnemyManager

signal boss_spawned(boss_node: Node2D)
signal elite_spawned(elite_node: Node2D)
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy_position: Vector2, enemy_type: String, exp_value: int, enemy_tier: int, is_elite: bool, is_boss: bool)
signal wave_cleared()

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Spawn Settings")
@export var spawn_distance: float = 600.0
@export var max_enemies: int = 80       # AUMENTADO: 50 -> 80 (Más densidad)
@export var base_spawn_rate: float = 2.5  # AUMENTADO: 1.5 -> 2.5 (Más rápido)
@export var debug_spawns: bool = false  # Normal: desactivado

# DEBUG TEMPORAL - Activar para ver spawns de zona
const DEBUG_ZONE_SPAWNS: bool = false

@export_group("Scaling")
@export var spawn_rate_increase_per_minute: float = 0.1  # +10% por minuto
@export var max_enemies_increase_per_minute: int = 4     # AUMENTADO: 2 -> 4

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var player: Node2D = null
var spawn_timer: float = 0.0
var active_enemies: Array = []
var spawning_enabled: bool = true

# Tracking de tiempo
var game_time_seconds: float = 0.0
var last_boss_minute: int = -1
var elites_spawned_this_run: int = 0
var elite_check_timer: float = 0.0

# Script base de enemigos
var EnemyBaseScript: Script = null

# Referencia a DifficultyManager
var difficulty_manager = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Asegurar que EnemyManager respete la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemy_spawner")

	randomize()
	_load_enemy_scripts()
	_find_difficulty_manager()

	if debug_spawns:
		print("👹 [EnemyManager] Inicializado")
		print("   - Max enemigos base: %d" % max_enemies)
		print("   - Spawn rate base: %.1f/s" % base_spawn_rate)

func _load_enemy_scripts() -> void:
	if ResourceLoader.exists("res://scripts/enemies/EnemyBase.gd"):
		EnemyBaseScript = load("res://scripts/enemies/EnemyBase.gd")

func _find_difficulty_manager() -> void:
	var tree = get_tree()
	if tree and tree.root:
		difficulty_manager = tree.root.get_node_or_null("DifficultyManager")

func initialize(player_ref: Node2D, _world_ref: Node = null) -> void:
	player = player_ref
	spawning_enabled = true
	spawn_timer = 0.0
	game_time_seconds = 0.0
	last_boss_minute = -1
	elites_spawned_this_run = 0

	if debug_spawns:
		print("[EnemyManager] Inicializado con player: %s" % player)

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not spawning_enabled or player == null:
		return

	game_time_seconds += delta

	# Procesar cola de spawns pendientes (del frame anterior)
	_process_spawn_queue()

	_update_spawn_timer(delta)
	_check_boss_spawn()
	_check_elite_spawn(delta)
	_cleanup_dead_enemies()
	_process_enemy_despawn(delta)  # Sistema de despawn para rendimiento

func _process_spawn_queue() -> void:
	"""Procesar spawns que fueron demorados por el budget del frame anterior"""
	if _spawn_queue.is_empty():
		return

	# Procesar hasta que se agote el budget o la cola
	while not _spawn_queue.is_empty():
		# Usar consume() que verifica Y consume en una sola llamada
		if not SpawnBudgetManager.consume("enemy"):
			break  # Budget agotado, esperar al siguiente frame

		var queued = _spawn_queue.pop_front()
		spawn_enemy(queued["data"], queued["pos"], true)  # force=true para no re-encolar

func _update_spawn_timer(delta: float) -> void:
	spawn_timer += delta

	var current_spawn_rate = _get_current_spawn_rate()
	var interval = 1.0 / max(0.1, current_spawn_rate)

	if spawn_timer >= interval:
		spawn_timer = 0.0
		_attempt_spawn()

func _get_current_spawn_rate() -> float:
	"""Calcular spawn rate actual basado en tiempo y dificultad"""
	var minute = game_time_seconds / 60.0
	var rate = base_spawn_rate * (1.0 + minute * spawn_rate_increase_per_minute)

	# Aplicar multiplicador de DifficultyManager si existe
	if difficulty_manager:
		rate *= difficulty_manager.enemy_count_multiplier

	return rate

func _get_current_max_enemies() -> int:
	"""Calcular máximo de enemigos actual"""
	var minute = int(game_time_seconds / 60.0)
	var current_max = max_enemies + (minute * max_enemies_increase_per_minute)

	# Después del minuto 20, escala más agresivamente
	if minute > 20:
		var extra_periods = (minute - 20) / 5
		current_max += extra_periods * 10

	return current_max

# ═══════════════════════════════════════════════════════════════════════════════
# SPAWN DE ENEMIGOS NORMALES
# ═══════════════════════════════════════════════════════════════════════════════

func _attempt_spawn() -> void:
	if active_enemies.size() >= _get_current_max_enemies():
		return

	# Obtener posición de spawn primero para determinar la zona
	var pos = _get_spawn_position()

	# Determinar el tier basado en la zona donde va a spawnear
	var selected_tier = _get_tier_for_spawn_position(pos)

	# DEBUG: Siempre mostrar info de spawn por zona
	if DEBUG_ZONE_SPAWNS:
		var arena_manager = _get_arena_manager()
		var zone_name = "UNKNOWN"
		if arena_manager:
			var zone = arena_manager.get_zone_at_position(pos)
			zone_name = str(zone)
		print("[EnemyManager] 🎯 Spawn: pos=%s, zona=%s, tier=%d" % [pos, zone_name, selected_tier])

	# Verificar que tenemos enemigos disponibles para este tier
	var enemy_data = EnemyDatabase.get_random_enemy_for_tier(selected_tier)

	if enemy_data.is_empty():
		# Si no hay enemigos para este tier, intentar con tier 1 como fallback
		enemy_data = EnemyDatabase.get_random_enemy_for_tier(1)
		if enemy_data.is_empty():
			return

	# Aplicar escalado de dificultad
	var minute = game_time_seconds / 60.0
	var difficulty_mult = 1.0
	if difficulty_manager:
		difficulty_mult = difficulty_manager.enemy_health_multiplier

	enemy_data = EnemyDatabase.apply_difficulty_scaling(enemy_data, minute, difficulty_mult)

	spawn_enemy(enemy_data, pos)

func _get_tier_for_spawn_position(pos: Vector2) -> int:
	"""Obtener el tier de enemigo basado en la posición de spawn"""
	var arena_manager = _get_arena_manager()
	if arena_manager and arena_manager.has_method("get_spawn_tier_at_position"):
		var tier = arena_manager.get_spawn_tier_at_position(pos)
		if DEBUG_ZONE_SPAWNS:
			print("[EnemyManager] 📍 Tier para pos %s = %d (ArenaManager OK)" % [pos, tier])
		return tier

	if DEBUG_ZONE_SPAWNS:
		print("[EnemyManager] ⚠️ ArenaManager no encontrado, usando fallback por tiempo")

	# Fallback: usar el sistema basado en tiempo
	var minute = game_time_seconds / 60.0
	var available_tiers = EnemyDatabase.get_available_tiers_for_minute(minute)
	if available_tiers.is_empty():
		return 1
	return _select_weighted_tier(available_tiers, minute)

func _get_arena_manager() -> Node:
	"""Obtener referencia al ArenaManager"""
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("Game/ArenaManager")
	return null

func _select_weighted_tier(available_tiers: Array, minute: float) -> int:
	"""Seleccionar tier con pesos - tiers más altos menos comunes"""
	# Pesos base: tier 1 = 100%, tier 2 = 60%, tier 3 = 35%, tier 4 = 15%
	var weights = {1: 1.0, 2: 0.6, 3: 0.35, 4: 0.15}

	# Después del minuto 20, los tiers altos son más comunes
	if minute > 20:
		var bonus = (minute - 20) / 20.0  # +5% por minuto después del 20
		weights[2] = min(1.0, weights[2] + bonus * 0.5)
		weights[3] = min(0.8, weights[3] + bonus * 0.4)
		weights[4] = min(0.6, weights[4] + bonus * 0.3)

	var total_weight = 0.0
	for tier in available_tiers:
		total_weight += weights.get(tier, 0.1)

	var roll = randf() * total_weight
	var cumulative = 0.0

	for tier in available_tiers:
		cumulative += weights.get(tier, 0.1)
		if roll <= cumulative:
			return tier

	return available_tiers[0]

func _get_spawn_position() -> Vector2:
	var ppos: Vector2 = Vector2.ZERO
	if player and player is Node2D:
		ppos = player.global_position

	# Spawn en un círculo alrededor del jugador
	var angle = randf() * TAU
	var distance = spawn_distance + randf() * 100.0  # Algo de variación

	var spawn_pos = ppos + Vector2(cos(angle), sin(angle)) * distance

	# Verificar que la posición está en una zona desbloqueada
	var arena_manager = _get_arena_manager()
	if arena_manager:
		var max_attempts = 8
		for _i in range(max_attempts):
			var zone_at_pos = arena_manager.get_zone_at_position(spawn_pos)
			if arena_manager.is_zone_unlocked(zone_at_pos):
				return spawn_pos

			# Intentar una nueva posición más cercana al player
			angle = randf() * TAU
			distance = spawn_distance * 0.5 + randf() * (spawn_distance * 0.5)
			spawn_pos = ppos + Vector2(cos(angle), sin(angle)) * distance

		# Si todos los intentos fallan, spawnear cerca del player (zona SAFE)
		return ppos + Vector2(cos(randf() * TAU), sin(randf() * TAU)) * (spawn_distance * 0.3)

	return spawn_pos

# ═══════════════════════════════════════════════════════════════════════════════
# SPAWN DE BOSSES
# ═══════════════════════════════════════════════════════════════════════════════

func _check_boss_spawn() -> void:
	var current_minute = int(game_time_seconds / 60.0)

	# Solo spawn en múltiplos de 5 minutos
	if current_minute > 0 and current_minute % 5 == 0 and current_minute != last_boss_minute:
		last_boss_minute = current_minute
		_spawn_boss(current_minute)

func _spawn_boss(minute: int) -> void:
	var boss_data = EnemyDatabase.get_boss_for_minute(minute)

	if boss_data.is_empty():
		if debug_spawns:
			print("[EnemyManager] No hay boss para el minuto %d" % minute)
		return

	# Aplicar escalado
	var difficulty_mult = 1.0
	if difficulty_manager:
		difficulty_mult = difficulty_manager.enemy_health_multiplier

	boss_data = EnemyDatabase.apply_difficulty_scaling(boss_data, float(minute), difficulty_mult)
	boss_data["is_boss"] = true

	var pos = _get_spawn_position()
	var boss = spawn_enemy(boss_data, pos)

	if boss:
		boss_spawned.emit(boss)
		# BALANCE TELEMETRY: Log boss spawn
		if BalanceTelemetry:
			BalanceTelemetry.log_boss_spawned({
				"boss_id": boss_data.get("id", boss_data.get("name", "unknown")),
				"phase": minute,
				"hp": boss_data.get("hp", 0),
				"tier": boss_data.get("tier", "boss")
			})

# ═══════════════════════════════════════════════════════════════════════════════
# SPAWN DE ÉLITES
# ═══════════════════════════════════════════════════════════════════════════════

func _check_elite_spawn(delta: float) -> void:
	elite_check_timer += delta

	# Revisar cada 10 segundos
	if elite_check_timer < 10.0:
		return

	elite_check_timer = 0.0

	# Verificar si ya hay un élite activo
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy.get("is_elite"):
			return  # Ya hay un élite, no spawneamos otro

	var minute = game_time_seconds / 60.0

	# BALANCE PASS 2.5: Obtener multiplicador de frecuencia de elites
	var elite_freq_mult = 1.0
	if difficulty_manager and difficulty_manager.has_method("get_elite_frequency_multiplier"):
		elite_freq_mult = difficulty_manager.get_elite_frequency_multiplier()

	if EnemyDatabase.should_spawn_elite(minute, elites_spawned_this_run, elite_freq_mult):
		_spawn_elite()

func _spawn_elite() -> void:
	var minute = game_time_seconds / 60.0
	var available_tiers = EnemyDatabase.get_available_tiers_for_minute(minute)

	if available_tiers.is_empty():
		return

	# Los élites pueden ser de cualquier tier disponible
	var tier = available_tiers[randi() % available_tiers.size()]
	var base_enemy = EnemyDatabase.get_random_enemy_for_tier(tier)

	if base_enemy.is_empty():
		return

	# Convertir a élite
	var elite_data = EnemyDatabase.create_elite_version(base_enemy)

	# Aplicar escalado normal también
	var difficulty_mult = 1.0
	if difficulty_manager:
		difficulty_mult = difficulty_manager.enemy_health_multiplier

	elite_data = EnemyDatabase.apply_difficulty_scaling(elite_data, minute, difficulty_mult)

	var pos = _get_spawn_position()
	var elite = spawn_enemy(elite_data, pos)

	if elite:
		elites_spawned_this_run += 1
		elite_spawned.emit(elite)
		# print("⭐ [EnemyManager] ¡ÉLITE SPAWNEADO: %s!" % elite_data.name)

		# BALANCE TELEMETRY: Log elite spawn
		if BalanceTelemetry:
			var abilities: Array = []
			if elite_data.has("elite_abilities"):
				abilities = elite_data.elite_abilities
			elif elite_data.has("abilities"):
				abilities = elite_data.abilities
			BalanceTelemetry.log_elite_spawned({
				"enemy_id": elite_data.get("id", elite_data.get("name", "unknown")),
				"tier": tier,
				"abilities": abilities
			})

# Cola de spawns pendientes cuando se excede el budget
var _spawn_queue: Array = []

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL DE SPAWN
# ═══════════════════════════════════════════════════════════════════════════════

func spawn_enemy(enemy_data: Dictionary, world_pos: Vector2, force: bool = false) -> Node:
	if not EnemyBaseScript:
		push_warning("⚠️ [EnemyManager] EnemyBaseScript no cargado")
		return null

	# SPAWN BUDGET CHECK (skip para bosses/élites que son críticos)
	var is_critical = enemy_data.get("is_boss", false) or enemy_data.get("is_elite", false)
	if not force and not is_critical:
		if not SpawnBudgetManager.consume("enemy"):
			# Encolar para siguiente frame
			_spawn_queue.append({"data": enemy_data, "pos": world_pos})
			return null

	var type_id = str(enemy_data.get("id", "unknown"))

	# POOLING OPTIMIZATION
	var enemy = null
	var enemy_pool = get_tree().get_first_node_in_group("enemy_pool")
	if enemy_pool and enemy_pool.has_method("get_enemy"):
		enemy = enemy_pool.get_enemy()
	else:
		# Fallback
		enemy = CharacterBody2D.new()
		enemy.set_script(EnemyBaseScript)

	enemy.name = "Enemy_%s" % type_id

	# Asegurar modo de procesamiento activo (por si viene del pool disabled)
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.set_physics_process(true)
	enemy.set_process(true)
	enemy.visible = true

	# Inicializar con datos de la base de datos
	# Añadir al árbol de escena PRIMERO para que get_tree() funcione en initialize()
	# Esto permite que AnimatedEnemySprite acceda al ResourceManager y use el caché
	enemy.visible = false # Ocultar mientras se inicializa
	var root_scene = get_tree().current_scene if get_tree() else null
	if root_scene and root_scene.has_node("WorldRoot/EnemiesRoot"):
		var er = root_scene.get_node("WorldRoot/EnemiesRoot")
		if enemy.get_parent() != er:
			er.add_child(enemy)
		enemy.position = er.to_local(world_pos)
	else:
		if not enemy.get_parent():
			add_child(enemy)
		enemy.global_position = world_pos

	# Inicializar con datos de la base de datos (Ahora get_tree() es válido)
	if enemy.has_method("initialize_from_database"):
		enemy.initialize_from_database(enemy_data, player)
	elif enemy.has_method("initialize"):
		# Fallback al método antiguo
		var legacy_data = {
			"id": enemy_data.get("id", "unknown"),
			"name": enemy_data.get("name", "Enemigo"),
			"health": enemy_data.get("final_hp", enemy_data.get("base_hp", 20)),
			"speed": enemy_data.get("final_speed", enemy_data.get("base_speed", 40.0)),
			"exp_value": enemy_data.get("final_xp", enemy_data.get("base_xp", 1)),
			"tier": enemy_data.get("tier", 1),
			"damage": enemy_data.get("final_damage", enemy_data.get("base_damage", 5))
		}
		enemy.initialize(legacy_data, player)

	# Configurar propiedades adicionales desde enemy_data
	if enemy_data.get("is_elite", false):
		enemy.set("is_elite", true)
		if enemy_data.has("aura_color"):
			enemy.set("aura_color", enemy_data.aura_color)
		if enemy_data.has("size_scale"):
			enemy.set("elite_size_scale", enemy_data.size_scale)

	if enemy_data.get("is_boss", false):
		enemy.set("is_boss", true)

	# Conectar señal de muerte (SOLO SI NO ESTA CONECTADA)
	if enemy.has_signal("enemy_died"):
		if not enemy.enemy_died.is_connected(_on_enemy_died):
			enemy.enemy_died.connect(_on_enemy_died)

	# Asegurar visibilidad y z-index FINAL
	enemy.visible = true
	enemy.z_index = 0

	active_enemies.append(enemy)
	enemy_spawned.emit(enemy)

	# Audit: Report enemy spawn for per-type spawn tracking
	var _audit = get_node_or_null("/root/RunAuditTracker")
	if _audit and _audit.ENABLE_AUDIT:
		_audit.report_enemy_spawn(
			type_id,
			enemy_data.get("name", type_id),
			enemy_data.get("is_elite", false),
			enemy_data.get("special_abilities", [])
		)

	# Emitir señal de boss si aplica
	if enemy_data.get("is_boss", false) or type_id.find("boss") != -1:
		boss_spawned.emit(enemy)
		# Balance Debug: Log boss spawn for TTK tracking
		# FIX-BT2b: Siempre recopilar datos
		if BalanceDebugger:
			BalanceDebugger.log_elite_spawn(enemy.get_instance_id(), true)
	elif enemy_data.get("is_elite", false):
		# Balance Debug: Log elite spawn for TTK tracking
		# FIX-BT2b: Siempre recopilar datos
		if BalanceDebugger:
			BalanceDebugger.log_elite_spawn(enemy.get_instance_id(), false)

	# Efecto visual de spawn (humo/puff)
	_spawn_puff_effect(world_pos, _get_spawn_puff_color(enemy_data))

	if debug_spawns:
		var tier = enemy_data.get("tier", 1)
		var hp = enemy_data.get("final_hp", enemy_data.get("base_hp", 0))
		print("[EnemyManager] Spawned T%d %s (HP:%d) at %s POOL:%s" % [tier, enemy_data.get("name", "?"), hp, world_pos, str(enemy_pool != null)])

	return enemy

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

# Referencia a la escena del cofre
var chest_scene: PackedScene = preload("res://scenes/interactables/TreasureChest.tscn")

func _on_enemy_died(enemy: Node, type_id: String = "", exp_value: int = 0, enemy_tier: int = 1, is_elite: bool = false, is_boss: bool = false) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)

	# Balance Debug: Log elite/boss death for TTK tracking
	# FIX-BT2b: Siempre recopilar datos
	if BalanceDebugger:
		if is_boss:
			BalanceDebugger.log_elite_death(enemy.get_instance_id(), true)
		elif is_elite:
			BalanceDebugger.log_elite_death(enemy.get_instance_id(), false)

	var pos = Vector2.ZERO
	if is_instance_valid(enemy) and enemy is Node2D:
		pos = enemy.global_position

	# Enemy death sounds removed - user preference for minimal audio

	# SPAWN COFRES PARA ÉLITES Y BOSSES
	if (is_elite or is_boss) and chest_scene:
		_spawn_reward_chest_deferred.call_deferred(pos, is_elite, is_boss)

	enemy_died.emit(pos, type_id, exp_value, enemy_tier, is_elite, is_boss)

	if debug_spawns:
		var elite_str = " [ELITE]" if is_elite else ""
		var boss_str = " [BOSS]" if is_boss else ""
		print("[EnemyManager] Enemy died: T%d %s%s%s XP:%d" % [enemy_tier, type_id, elite_str, boss_str, exp_value])

func _spawn_reward_chest_deferred(pos: Vector2, is_elite: bool, is_boss: bool) -> void:
	"""Spawnear cofre de recompensa de forma segura"""
	var chest_type = 1 # ELITE default (ChestType.ELITE)
	if is_boss:
		chest_type = 2 # BOSS (ChestType.BOSS)

	var chest = chest_scene.instantiate()

	# Añadir a la escena
	var root = get_tree().current_scene
	if root:
		# Intentar ponerlo en una capa de items si existe (PickupsRoot)
		if root.has_node("WorldRoot/PickupsRoot"):
			root.get_node("WorldRoot/PickupsRoot").add_child(chest)
		elif root.has_node("WorldRoot/ItemsRoot"):
			root.get_node("WorldRoot/ItemsRoot").add_child(chest)
		else:
			root.add_child(chest)

		# Inicializar
		if chest.has_method("initialize"):
			chest.initialize(pos, chest_type, player)

		# Debug
		print("🎁 [EnemyManager] Cofre spawneado: %s en %s" % ["BOSS" if is_boss else "ELITE", pos])

func _cleanup_dead_enemies() -> void:
	var to_remove = []
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			to_remove.append(enemy)

	for e in to_remove:
		active_enemies.erase(e)

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func get_enemy_count() -> int:
	return active_enemies.size()

func get_active_enemies() -> Array:
	"""Retornar posiciones de enemigos activos"""
	var positions = []
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy is Node2D:
			positions.append(enemy.global_position)
	return positions

func get_active_enemy_nodes() -> Array:
	"""Retornar nodos de enemigos activos"""
	var nodes = []
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			nodes.append(enemy)
	return nodes

func get_enemies_in_range(center: Vector2, radius: float) -> Array:
	var found = []
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy is Node2D:
			if enemy.global_position.distance_to(center) <= radius:
				found.append(enemy)
	return found

func enable_spawning(enabled: bool) -> void:
	spawning_enabled = enabled

func clear_all_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

func force_spawn_boss() -> void:
	"""Forzar spawn de boss (para testing)"""
	var minute = max(5, int(game_time_seconds / 60.0))
	if minute % 5 != 0:
		minute = ((minute / 5) + 1) * 5
	_spawn_boss(minute)

func force_spawn_elite() -> void:
	"""Forzar spawn de élite (para testing)"""
	_spawn_elite()

func get_game_time_minutes() -> float:
	return game_time_seconds / 60.0

func get_elites_spawned() -> int:
	return elites_spawned_this_run

func set_game_time(seconds: float) -> void:
	"""Para testing - establecer tiempo de juego"""
	game_time_seconds = seconds

func set_spawn_rate(new_rate: float) -> void:
	base_spawn_rate = max(0.1, new_rate)

func set_max_enemies(new_max: int) -> void:
	max_enemies = max(1, new_max)

# ═══════════════════════════════════════════════════════════════════════════════
# API PARA WAVEMANAGER
# ═══════════════════════════════════════════════════════════════════════════════

func spawn_specific_enemy(enemy_id: String, world_pos: Vector2, multipliers: Dictionary = {}) -> Node:
	"""Spawnear un enemigo específico por su ID en una posición dada"""
	var enemy_data = EnemyDatabase.get_enemy_by_id(enemy_id)

	if enemy_data.is_empty():
		push_warning("[EnemyManager] No se encontró enemigo con ID: %s" % enemy_id)
		return null

	# Aplicar escalado base
	var minute = game_time_seconds / 60.0
	var difficulty_mult = 1.0
	if difficulty_manager:
		difficulty_mult = difficulty_manager.enemy_health_multiplier

	enemy_data = EnemyDatabase.apply_difficulty_scaling(enemy_data, minute, difficulty_mult)

	# Aplicar multiplicadores adicionales del WaveManager (escalado infinito)
	if multipliers.has("hp_multiplier"):
		enemy_data["final_hp"] = int(enemy_data.get("final_hp", enemy_data.get("base_hp", 20)) * multipliers.hp_multiplier)
	if multipliers.has("damage_multiplier"):
		enemy_data["final_damage"] = int(enemy_data.get("final_damage", enemy_data.get("base_damage", 5)) * multipliers.damage_multiplier)

	return spawn_enemy(enemy_data, world_pos)

func spawn_minions_around(origin: Vector2, count: int, tier: int = 1) -> Array:
	"""Spawnear minions alrededor de una posición (usado por bosses y split-on-death)"""
	var spawned: Array = []
	var tier_enemies = EnemyDatabase.get_enemies_for_tier(tier)

	for i in range(count):
		var angle = (TAU / count) * i + randf_range(-0.3, 0.3)
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(40.0, 80.0)
		var spawn_pos = origin + offset

		var enemy_id: String = ""
		if tier_enemies.size() > 0:
			enemy_id = tier_enemies[randi() % tier_enemies.size()].get("id", "")

		var minion: Node = null
		if enemy_id != "":
			minion = spawn_specific_enemy(enemy_id, spawn_pos)
		else:
			# Fallback: spawn genérico de tier bajo
			var fallback_data = {
				"id": "minion_t%d" % tier,
				"base_hp": 10 * tier,
				"base_damage": 3 * tier,
				"speed": 60.0,
				"tier": tier,
				"xp_value": 2 * tier
			}
			minion = spawn_enemy(fallback_data, spawn_pos, true)

		if minion:
			spawned.append(minion)

	return spawned

func spawn_boss(boss_id: String, world_pos: Vector2, multipliers: Dictionary = {}) -> Node:
	"""Spawnear un boss específico - usado por WaveManager"""
	var boss_data = EnemyDatabase.get_enemy_by_id(boss_id)

	if boss_data.is_empty():
		push_warning("[EnemyManager] No se encontró boss con ID: %s" % boss_id)
		return null

	# Aplicar escalado
	var minute = game_time_seconds / 60.0
	var difficulty_mult = 1.0
	if difficulty_manager:
		difficulty_mult = difficulty_manager.enemy_health_multiplier

	boss_data = EnemyDatabase.apply_difficulty_scaling(boss_data, minute, difficulty_mult)
	boss_data["is_boss"] = true

	# Aplicar multiplicadores adicionales (escalado infinito)
	if multipliers.has("hp_multiplier"):
		boss_data["final_hp"] = int(boss_data.get("final_hp", boss_data.get("base_hp", 100)) * multipliers.hp_multiplier)
	if multipliers.has("damage_multiplier"):
		boss_data["final_damage"] = int(boss_data.get("final_damage", boss_data.get("base_damage", 20)) * multipliers.damage_multiplier)

	var boss = spawn_enemy(boss_data, world_pos)

	if boss:
		boss_spawned.emit(boss)
		# Debug desactivado: print("[EnemyManager] BOSS SPAWNEADO")

	return boss

func spawn_elite(enemy_id: String, world_pos: Vector2, multipliers: Dictionary = {}) -> Node:
	"""Spawnear un élite de un tipo específico - usado por WaveManager"""
	var base_enemy = EnemyDatabase.get_enemy_by_id(enemy_id)

	if base_enemy.is_empty():
		push_warning("[EnemyManager] No se encontró enemigo para élite con ID: %s" % enemy_id)
		return null

	# Convertir a élite
	var elite_data = EnemyDatabase.create_elite_version(base_enemy)

	# Aplicar escalado normal
	var minute = game_time_seconds / 60.0
	var difficulty_mult = 1.0
	if difficulty_manager:
		difficulty_mult = difficulty_manager.enemy_health_multiplier

	elite_data = EnemyDatabase.apply_difficulty_scaling(elite_data, minute, difficulty_mult)

	# Aplicar multiplicadores adicionales (escalado infinito)
	if multipliers.has("hp_multiplier"):
		elite_data["final_hp"] = int(elite_data.get("final_hp", elite_data.get("base_hp", 50)) * multipliers.hp_multiplier)
	if multipliers.has("damage_multiplier"):
		elite_data["final_damage"] = int(elite_data.get("final_damage", elite_data.get("base_damage", 10)) * multipliers.damage_multiplier)

	var elite = spawn_enemy(elite_data, world_pos)

	if elite:
		elites_spawned_this_run += 1
		elite_spawned.emit(elite)
		# Debug desactivado: print("[EnemyManager] ÉLITE SPAWNEADO")

		# BALANCE TELEMETRY: Log elite spawn (WaveManager path)
		if BalanceTelemetry:
			var abilities: Array = []
			if elite_data.has("elite_abilities"):
				abilities = elite_data.elite_abilities
			elif elite_data.has("abilities"):
				abilities = elite_data.abilities
			var tier: int = elite_data.get("tier", base_enemy.get("tier", 1))
			BalanceTelemetry.log_elite_spawned({
				"enemy_id": enemy_id,
				"tier": tier,
				"abilities": abilities
			})

	return elite

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN PARA GUARDADO/REANUDACIÓN DE PARTIDA
# ═══════════════════════════════════════════════════════════════════════════════

func to_save_data() -> Dictionary:
	"""Serializar estado completo del EnemyManager para guardado"""
	var data: Dictionary = {
		"game_time_seconds": game_time_seconds,
		"last_boss_minute": last_boss_minute,
		"elites_spawned_this_run": elites_spawned_this_run,
		"spawn_timer": spawn_timer,
		"elite_check_timer": elite_check_timer,
		"spawning_enabled": spawning_enabled,
		"enemies": []
	}

	# Serializar todos los enemigos activos
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue

		var enemy_data: Dictionary = {
			"enemy_id": enemy.enemy_id if "enemy_id" in enemy else "",
			"position": {
				"x": enemy.global_position.x,
				"y": enemy.global_position.y
			},
			"is_elite": enemy.is_elite if "is_elite" in enemy else false,
			"is_boss": enemy.is_boss if "is_boss" in enemy else false,
			"tier": enemy.enemy_tier if "enemy_tier" in enemy else 1
		}

		# Guardar HP si tiene HealthComponent
		if "health_component" in enemy and enemy.health_component:
			enemy_data["current_hp"] = enemy.health_component.current_health
			enemy_data["max_hp"] = enemy.health_component.max_health
		elif enemy.has_method("get_health"):
			enemy_data["current_hp"] = enemy.get_health()
			enemy_data["max_hp"] = enemy.max_health if "max_health" in enemy else 100

		# Guardar stats escalados si existen
		if "final_hp" in enemy:
			enemy_data["final_hp"] = enemy.final_hp
		if "final_damage" in enemy:
			enemy_data["final_damage"] = enemy.final_damage
		if "final_speed" in enemy:
			enemy_data["final_speed"] = enemy.final_speed

		data["enemies"].append(enemy_data)

	print("👹 [EnemyManager] Guardados %d enemigos" % data["enemies"].size())
	return data

func from_save_data(data: Dictionary) -> void:
	"""Restaurar estado del EnemyManager desde datos guardados"""
	if data.is_empty():
		return

	print("👹 [EnemyManager] Restaurando desde save data...")

	# Restaurar estado interno
	game_time_seconds = data.get("game_time_seconds", 0.0)
	last_boss_minute = data.get("last_boss_minute", -1)
	elites_spawned_this_run = data.get("elites_spawned_this_run", 0)
	spawn_timer = data.get("spawn_timer", 0.0)
	elite_check_timer = data.get("elite_check_timer", 0.0)
	spawning_enabled = data.get("spawning_enabled", true)

	# Limpiar enemigos existentes
	clear_all_enemies()

	# Restaurar enemigos guardados
	var enemies_data = data.get("enemies", [])
	var restored_count = 0
	var boss_restored = false

	for enemy_info in enemies_data:
		var enemy_id = enemy_info.get("enemy_id", "")
		if enemy_id == "":
			continue

		# Obtener datos base del enemigo de la base de datos
		var base_data = EnemyDatabase.get_enemy_by_id(enemy_id)
		if base_data.is_empty():
			print("⚠️ [EnemyManager] No se encontró enemigo con ID: %s" % enemy_id)
			continue

		# Sobrescribir con valores guardados
		if enemy_info.has("final_hp"):
			base_data["final_hp"] = enemy_info.get("final_hp")
		if enemy_info.has("final_damage"):
			base_data["final_damage"] = enemy_info.get("final_damage")
		if enemy_info.has("final_speed"):
			base_data["final_speed"] = enemy_info.get("final_speed")

		base_data["is_elite"] = enemy_info.get("is_elite", false)
		base_data["is_boss"] = enemy_info.get("is_boss", false)

		# Si es élite, aplicar modificadores de élite
		if base_data["is_elite"] and not base_data["is_boss"]:
			base_data = EnemyDatabase.create_elite_version(base_data)

		# Restaurar posición
		var pos_data = enemy_info.get("position", {"x": 0, "y": 0})
		var position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

		# Crear el enemigo
		var enemy = spawn_enemy(base_data, position)

		if enemy:
			# Restaurar HP específico
			var saved_hp = enemy_info.get("current_hp", -1)
			var saved_max_hp = enemy_info.get("max_hp", -1)

			if saved_hp > 0:
				if "health_component" in enemy and enemy.health_component:
					if saved_max_hp > 0:
						enemy.health_component.max_health = saved_max_hp
					enemy.health_component.current_health = min(saved_hp, enemy.health_component.max_health)

			restored_count += 1

			if base_data["is_boss"]:
				boss_restored = true
				print("🔥 [EnemyManager] Boss restaurado: %s (HP: %d)" % [enemy_id, saved_hp])

	print("👹 [EnemyManager] Estado restaurado:")
	print("   - Enemigos restaurados: %d / %d" % [restored_count, enemies_data.size()])
	print("   - Élites spawneados total: %d" % elites_spawned_this_run)
	print("   - Boss restaurado: %s" % boss_restored)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE DESPAWN/RESPAWN PARA RENDIMIENTO
# ═══════════════════════════════════════════════════════════════════════════════

const DESPAWN_DISTANCE: float = 900.0        # Distancia máxima antes de eliminar
const TELEPORT_DISTANCE: float = 750.0       # Distancia para teleportar enemigos atascados
const DESPAWN_CHECK_INTERVAL: float = 0.5    # Chequear cada 0.5s para respuesta rápida
const STUCK_VELOCITY_THRESHOLD: float = 10.0 # Velocidad mínima hacia el jugador
var despawn_check_timer: float = 0.0
var _enemy_last_positions: Dictionary = {}  # Para detectar enemigos atascados

func _process_enemy_despawn(delta: float) -> void:
	"""
	Sistema mejorado de despawn/teleport:
	- Enemigos a más de DESPAWN_DISTANCE: eliminados
	- Enemigos a más de TELEPORT_DISTANCE que estén atascados: teleportados cerca
	- Excluye bosses y élites
	"""
	if not player:
		return

	despawn_check_timer += delta
	if despawn_check_timer < DESPAWN_CHECK_INTERVAL:
		return
	despawn_check_timer = 0.0

	var player_pos = player.global_position
	var to_despawn: Array = []
	var to_teleport: Array = []

	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue

		# No tocar bosses ni élites
		if enemy.get("is_boss") or enemy.get("is_elite"):
			continue

		var enemy_id = enemy.get_instance_id()
		var enemy_pos = enemy.global_position
		var dist = enemy_pos.distance_to(player_pos)

		# Caso 1: Muy lejos -> despawnear
		if dist > DESPAWN_DISTANCE:
			to_despawn.append(enemy)
			_enemy_last_positions.erase(enemy_id)
			continue

		# Caso 2: En zona de teleport -> verificar si está atascado
		if dist > TELEPORT_DISTANCE:
			var is_stuck = false

			# Verificar si apenas se ha movido desde el último check
			if _enemy_last_positions.has(enemy_id):
				var last_pos = _enemy_last_positions[enemy_id]
				var moved = enemy_pos.distance_to(last_pos)
				var dir_to_player = (player_pos - enemy_pos).normalized()
				var movement_dir = (enemy_pos - last_pos).normalized() if moved > 0.1 else Vector2.ZERO

				# Atascado si: apenas se movió O se movió alejándose del jugador
				if moved < STUCK_VELOCITY_THRESHOLD * DESPAWN_CHECK_INTERVAL:
					is_stuck = true
				elif movement_dir.dot(dir_to_player) < -0.3:  # Se aleja del jugador
					is_stuck = true

			_enemy_last_positions[enemy_id] = enemy_pos

			if is_stuck:
				to_teleport.append(enemy)
		else:
			# Limpiar tracking si está en rango normal
			_enemy_last_positions.erase(enemy_id)

	# Procesar teleports
	for enemy in to_teleport:
		if is_instance_valid(enemy):
			_teleport_enemy_near_player(enemy, player_pos)

	# Procesar eliminaciones
	for enemy in to_despawn:
		if is_instance_valid(enemy):
			active_enemies.erase(enemy)
			# Retornar al pool si es posible
			if enemy.has_meta("pooled"):
				var pool = get_tree().get_first_node_in_group("enemy_pool")
				if pool and pool.has_method("return_enemy"):
					pool.return_enemy(enemy)
					continue
			enemy.queue_free()

	if debug_spawns and (not to_despawn.is_empty() or not to_teleport.is_empty()):
		print("[EnemyManager] Despawn: %d | Teleport: %d" % [to_despawn.size(), to_teleport.size()])

func _teleport_enemy_near_player(enemy: Node2D, player_pos: Vector2) -> void:
	"""Teleporta un enemigo atascado cerca del jugador con efecto visual"""
	# Calcular nueva posición cerca del jugador
	var angle = randf() * TAU
	var distance = spawn_distance + randf_range(-50, 50)
	var new_pos = player_pos + Vector2.from_angle(angle) * distance

	# Crear efecto de humo en posición antigua
	_spawn_puff_effect(enemy.global_position, Color(0.5, 0.5, 0.5, 0.7))

	# Mover enemigo
	enemy.global_position = new_pos

	# Crear efecto de humo en nueva posición
	_spawn_puff_effect(new_pos, Color(0.6, 0.6, 0.6, 0.8))

	# Actualizar posición de tracking
	_enemy_last_positions[enemy.get_instance_id()] = new_pos

# ═══════════════════════════════════════════════════════════════════════════════
# EFECTOS VISUALES DE SPAWN
# ═══════════════════════════════════════════════════════════════════════════════

func _get_spawn_puff_color(enemy_data: Dictionary) -> Color:
	"""Determina el color del efecto de spawn según el tipo de enemigo"""
	if enemy_data.get("is_boss", false):
		return Color(0.8, 0.2, 0.2, 0.9)  # Rojo para bosses
	elif enemy_data.get("is_elite", false):
		return Color(1.0, 0.8, 0.2, 0.9)  # Dorado para élites
	else:
		var tier = enemy_data.get("tier", 1)
		match tier:
			1: return Color(0.7, 0.7, 0.7, 0.7)  # Gris claro
			2: return Color(0.5, 0.7, 0.5, 0.7)  # Verde suave
			3: return Color(0.5, 0.5, 0.8, 0.7)  # Azul suave
			4: return Color(0.7, 0.5, 0.8, 0.7)  # Púrpura suave
			_: return Color(0.6, 0.6, 0.6, 0.7)

func _spawn_puff_effect(pos: Vector2, color: Color) -> void:
	"""Crea un efecto de humo/puff en la posición dada"""
	var root = get_tree().current_scene if get_tree() else null
	if not root:
		return

	# Crear nodo para el efecto
	var puff = Node2D.new()
	puff.global_position = pos
	puff.z_index = 10

	# Añadir script inline para la animación
	var puff_script = GDScript.new()
	puff_script.source_code = """
extends Node2D

var lifetime: float = 0.4
var elapsed: float = 0.0
var puff_color: Color = Color.WHITE
var particles: Array = []
const PARTICLE_COUNT: int = 8

func _ready():
	# Crear partículas de humo
	for i in range(PARTICLE_COUNT):
		var angle = (TAU / PARTICLE_COUNT) * i + randf() * 0.3
		var speed = randf_range(30, 60)
		particles.append({
			"offset": Vector2.ZERO,
			"velocity": Vector2.from_angle(angle) * speed,
			"size": randf_range(8, 16),
			"alpha": 1.0
		})

func _process(delta):
	elapsed += delta
	var progress = elapsed / lifetime

	if progress >= 1.0:
		queue_free()
		return

	# Actualizar partículas
	for p in particles:
		p.offset += p.velocity * delta
		p.velocity *= 0.92  # Fricción
		p.alpha = 1.0 - progress
		p.size *= 1.02  # Expandir

	queue_redraw()

func _draw():
	for p in particles:
		var c = puff_color
		c.a = p.alpha * puff_color.a
		draw_circle(p.offset, p.size, c)
		# Borde más claro
		var border_c = Color(1, 1, 1, c.a * 0.3)
		draw_arc(p.offset, p.size, 0, TAU, 12, border_c, 1.5)
"""
	puff_script.reload()
	puff.set_script(puff_script)
	puff.set("puff_color", color)

	# Añadir al árbol
	if root.has_node("WorldRoot"):
		root.get_node("WorldRoot").add_child(puff)
	else:
		root.add_child(puff)
