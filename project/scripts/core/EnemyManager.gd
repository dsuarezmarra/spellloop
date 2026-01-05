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
@export var max_enemies: int = 50
@export var base_spawn_rate: float = 1.5  # Enemigos por segundo base
@export var debug_spawns: bool = false  # Normal: desactivado

# DEBUG TEMPORAL - Activar para ver spawns de zona
const DEBUG_ZONE_SPAWNS: bool = true

@export_group("Scaling")
@export var spawn_rate_increase_per_minute: float = 0.1  # +10% por minuto
@export var max_enemies_increase_per_minute: int = 2

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

	_update_spawn_timer(delta)
	_check_boss_spawn()
	_check_elite_spawn(delta)
	_cleanup_dead_enemies()

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
		emit_signal("boss_spawned", boss)
		print("🔥 [EnemyManager] ¡BOSS SPAWNEADO: %s (Minuto %d)!" % [boss_data.name, minute])

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

	if EnemyDatabase.should_spawn_elite(minute, elites_spawned_this_run):
		_spawn_elite()

func _spawn_elite() -> void:
	var minute = game_time_seconds / 60.0
	var available_tiers = EnemyDatabase.get_available_tiers_for_minute(minute)

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
		emit_signal("elite_spawned", elite)
		print("⭐ [EnemyManager] ¡ÉLITE SPAWNEADO: %s!" % elite_data.name)

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL DE SPAWN
# ═══════════════════════════════════════════════════════════════════════════════

func spawn_enemy(enemy_data: Dictionary, world_pos: Vector2) -> Node:
	if not EnemyBaseScript:
		push_warning("⚠️ [EnemyManager] EnemyBaseScript no cargado")
		return null

	var type_id = str(enemy_data.get("id", "unknown"))

	# Crear CharacterBody2D con script EnemyBase
	var enemy = CharacterBody2D.new()
	enemy.set_script(EnemyBaseScript)
	enemy.name = "Enemy_%s" % type_id

	# Inicializar con datos de la base de datos
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

	# Conectar señal de muerte
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)

	# Asegurar visibilidad
	enemy.visible = true
	enemy.z_index = 0

	# Añadir al árbol de escena
	var root_scene = get_tree().current_scene if get_tree() else null
	if root_scene and root_scene.has_node("WorldRoot/EnemiesRoot"):
		var er = root_scene.get_node("WorldRoot/EnemiesRoot")
		er.add_child(enemy)
		enemy.position = er.to_local(world_pos)
	else:
		add_child(enemy)
		enemy.global_position = world_pos

	active_enemies.append(enemy)
	emit_signal("enemy_spawned", enemy)

	# Emitir señal de boss si aplica
	if enemy_data.get("is_boss", false) or type_id.find("boss") != -1:
		emit_signal("boss_spawned", enemy)

	if debug_spawns:
		var tier = enemy_data.get("tier", 1)
		var hp = enemy_data.get("final_hp", enemy_data.get("base_hp", 0))
		print("[EnemyManager] Spawned T%d %s (HP:%d) at %s" % [tier, enemy_data.get("name", "?"), hp, world_pos])

	return enemy

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_enemy_died(enemy: Node, type_id: String = "", exp_value: int = 0, enemy_tier: int = 1, is_elite: bool = false, is_boss: bool = false) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)

	var pos = Vector2.ZERO
	if is_instance_valid(enemy) and enemy is Node2D:
		pos = enemy.global_position

	emit_signal("enemy_died", pos, type_id, exp_value, enemy_tier, is_elite, is_boss)

	if debug_spawns:
		var elite_str = " [ELITE]" if is_elite else ""
		var boss_str = " [BOSS]" if is_boss else ""
		print("[EnemyManager] Enemy died: T%d %s%s%s XP:%d" % [enemy_tier, type_id, elite_str, boss_str, exp_value])

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
		emit_signal("boss_spawned", boss)
		print("🔥 [EnemyManager] ¡BOSS SPAWNEADO: %s!" % boss_data.name)

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
		emit_signal("elite_spawned", elite)
		print("⭐ [EnemyManager] ¡ÉLITE SPAWNEADO: %s!" % elite_data.name)

	return elite
