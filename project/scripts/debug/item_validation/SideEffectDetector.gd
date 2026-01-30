extends Node
class_name SideEffectDetector

# ═══════════════════════════════════════════════════════════════════════════════
# SIDE EFFECT DETECTOR - Anti-Bug System
# ═══════════════════════════════════════════════════════════════════════════════
#
# Este detector captura TODOS los cambios de estado que ocurren durante un test
# y los compara contra los efectos declarados por el item.
# Cualquier efecto que ocurra pero NO esté declarado es un SIDE EFFECT (potencial bug).
#
# Tipos de detección:
# - Modificaciones de stats no declaradas
# - Status effects no declarados
# - Daño no declarado
# - Cambios de posición no esperados
# - Señales emitidas no esperadas

# Usar StatResolver para lista completa de stats
const StatResolverScript = preload("res://scripts/debug/item_validation/StatResolver.gd")

# ═══════════════════════════════════════════════════════════════════════════════
# STATE TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

# Snapshot of player state before test
var player_state_before: Dictionary = {}
# Snapshot of player state after test
var player_state_after: Dictionary = {}
# Snapshot of enemy states before test
var enemy_states_before: Dictionary = {}  # {enemy_id: state}
# Snapshot of enemy states after test
var enemy_states_after: Dictionary = {}

# Tracked events during test
var damage_events: Array = []
var status_events: Array = []
var stat_change_events: Array = []
var spawn_events: Array = []
var other_events: Array = []

# Configuration
var _is_active: bool = false
var _player_ref: Node = null
var _tracked_enemies: Array = []

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func start_monitoring(player: Node) -> void:
	_clear_data()
	_is_active = true
	_player_ref = player
	
	# Take initial player snapshot
	if is_instance_valid(player):
		player_state_before = _capture_player_state(player)
		_connect_player_signals(player)

func stop_monitoring() -> void:
	_is_active = false
	
	# Take final player snapshot
	if is_instance_valid(_player_ref):
		player_state_after = _capture_player_state(_player_ref)
	
	# Take final enemy snapshots
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy):
			enemy_states_after[enemy.get_instance_id()] = _capture_enemy_state(enemy)

func track_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy): return
	if enemy in _tracked_enemies: return
	
	_tracked_enemies.append(enemy)
	enemy_states_before[enemy.get_instance_id()] = _capture_enemy_state(enemy)
	_connect_enemy_signals(enemy)

func _clear_data() -> void:
	player_state_before = {}
	player_state_after = {}
	enemy_states_before = {}
	enemy_states_after = {}
	damage_events = []
	status_events = []
	stat_change_events = []
	spawn_events = []
	other_events = []
	_tracked_enemies = []
	_player_ref = null

# ═══════════════════════════════════════════════════════════════════════════════
# STATE CAPTURE
# ═══════════════════════════════════════════════════════════════════════════════

func _capture_player_state(player: Node) -> Dictionary:
	var state = {}
	
	# Try to get PlayerStats component from multiple locations
	var player_stats = null
	
	# 1. Try direct child
	if player.has_node("PlayerStats"):
		player_stats = player.get_node("PlayerStats")
	# 2. Try player's get_stats method
	elif player.has_method("get_stats"):
		player_stats = player.get_stats()
	# 3. Try if player IS PlayerStats
	elif player is PlayerStats:
		player_stats = player
	# 4. Try sibling (TestEnv structure: MockPlayer and PlayerStats are siblings)
	elif player.get_parent() and player.get_parent().has_node("PlayerStats"):
		player_stats = player.get_parent().get_node("PlayerStats")
	# 5. Try global PlayerStats singleton if available
	elif Engine.has_singleton("PlayerStats"):
		player_stats = Engine.get_singleton("PlayerStats")
	# 6. Try finding in tree
	else:
		var nodes = player.get_tree().get_nodes_in_group("player_stats")
		if not nodes.is_empty():
			player_stats = nodes[0]
	
	if player_stats != null:
		# Capture all known stats using StatResolver's comprehensive list
		# This includes PLAYER_STATS + GLOBAL_WEAPON_STATS + all aliases
		var stat_list: Array = []
		stat_list.append_array(StatResolverScript.PLAYER_STATS)
		stat_list.append_array(StatResolverScript.GLOBAL_WEAPON_STATS)
		
		# Also add all alias keys so we can capture them too
		for alias_key in StatResolverScript.STAT_ALIASES.keys():
			if alias_key not in stat_list:
				stat_list.append(alias_key)
		
		for stat_name in stat_list:
			if player_stats.has_method("get_stat"):
				state[stat_name] = player_stats.get_stat(stat_name)
			elif stat_name in player_stats:
				state[stat_name] = player_stats.get(stat_name)
	
	# Also capture GlobalWeaponStats (some stats like life_steal are there)
	var global_weapon_stats = null
	if player.get_tree():
		var gws_nodes = player.get_tree().get_nodes_in_group("global_weapon_stats")
		if not gws_nodes.is_empty():
			global_weapon_stats = gws_nodes[0]
	
	# Fallback: Try to find GlobalWeaponStats as sibling or in parent
	if not global_weapon_stats and player.get_parent():
		global_weapon_stats = player.get_parent().get_node_or_null("GlobalWeaponStats")
	
	if global_weapon_stats:
		# Use StatResolver's GLOBAL_WEAPON_STATS list
		var weapon_stats_list = StatResolverScript.GLOBAL_WEAPON_STATS.duplicate()
		for stat_name in weapon_stats_list:
			if global_weapon_stats.has_method("get_stat"):
				var val = global_weapon_stats.get_stat(stat_name)
				# Only override if not already captured or if this value is non-zero
				if not state.has(stat_name) or (val != 0.0 and state.get(stat_name, 0.0) == 0.0):
					state[stat_name] = val
	
	# Capture position
	if player.has_method("get_global_position"):
		state["position"] = player.global_position
	elif "global_position" in player:
		state["position"] = player.global_position
	
	return state

func _capture_enemy_state(enemy: Node) -> Dictionary:
	var state = {}
	
	# Health
	if enemy.has_node("HealthComponent"):
		var hc = enemy.get_node("HealthComponent")
		state["health"] = hc.current_health if "current_health" in hc else 0
		state["max_health"] = hc.max_health if "max_health" in hc else 0
	
	# Status effects
	if enemy.has_method("get_active_statuses"):
		state["active_statuses"] = enemy.get_active_statuses().duplicate()
	else:
		state["active_statuses"] = {}
	
	# Position
	if "global_position" in enemy:
		state["position"] = enemy.global_position
	
	# Movement/Speed
	if enemy.has_method("get_speed"):
		state["speed"] = enemy.get_speed()
	
	return state

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNAL CONNECTIONS
# ═══════════════════════════════════════════════════════════════════════════════

func _connect_player_signals(player: Node) -> void:
	# Connect to stat change signals if available
	if player.has_signal("stat_changed"):
		if not player.is_connected("stat_changed", _on_player_stat_changed):
			player.connect("stat_changed", _on_player_stat_changed)
	
	# Connect to health component signals
	if player.has_node("HealthComponent"):
		var hc = player.get_node("HealthComponent")
		if hc.has_signal("damaged"):
			if not hc.is_connected("damaged", _on_player_damaged):
				hc.connect("damaged", _on_player_damaged)
		if hc.has_signal("healed"):
			if not hc.is_connected("healed", _on_player_healed):
				hc.connect("healed", _on_player_healed)

func _connect_enemy_signals(enemy: Node) -> void:
	var enemy_id = enemy.get_instance_id()
	
	# Status effect signals
	if enemy.has_signal("status_applied"):
		if not enemy.is_connected("status_applied", _on_enemy_status_applied):
			enemy.connect("status_applied", _on_enemy_status_applied.bind(enemy_id))
	
	# Damage signals
	if enemy.has_node("HealthComponent"):
		var hc = enemy.get_node("HealthComponent")
		if hc.has_signal("damaged"):
			if not hc.is_connected("damaged", _on_enemy_damaged):
				hc.connect("damaged", _on_enemy_damaged.bind(enemy_id))

# ═══════════════════════════════════════════════════════════════════════════════
# EVENT CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_player_stat_changed(stat_name: String, old_value, new_value) -> void:
	if not _is_active: return
	
	stat_change_events.append({
		"timestamp_ms": Time.get_ticks_msec(),
		"target": "player",
		"stat": stat_name,
		"old_value": old_value,
		"new_value": new_value,
		"delta": new_value - old_value if typeof(new_value) in [TYPE_INT, TYPE_FLOAT] else null
	})

func _on_player_damaged(amount: int, source: String) -> void:
	if not _is_active: return
	
	damage_events.append({
		"timestamp_ms": Time.get_ticks_msec(),
		"target": "player",
		"amount": amount,
		"source": source
	})

func _on_player_healed(amount: int) -> void:
	if not _is_active: return
	
	other_events.append({
		"timestamp_ms": Time.get_ticks_msec(),
		"type": "heal",
		"target": "player",
		"amount": amount
	})

func _on_enemy_status_applied(status_name: String, duration: float, params: Dictionary, enemy_id: int) -> void:
	if not _is_active: return
	
	status_events.append({
		"timestamp_ms": Time.get_ticks_msec(),
		"enemy_id": enemy_id,
		"status": status_name,
		"duration": duration,
		"params": params.duplicate()
	})

func _on_enemy_damaged(amount: int, element: String, enemy_id: int) -> void:
	if not _is_active: return
	
	damage_events.append({
		"timestamp_ms": Time.get_ticks_msec(),
		"target": "enemy",
		"enemy_id": enemy_id,
		"amount": amount,
		"element": element
	})

# ═══════════════════════════════════════════════════════════════════════════════
# DETECTION ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════

func detect_side_effects(declared_effects: Dictionary) -> Dictionary:
	"""
	Compares all observed changes against declared effects.
	Returns a report of undeclared side effects.
	
	declared_effects = {
		"stats": ["damage_mult", "max_hp"],  # Stats that SHOULD change
		"statuses": ["burn", "freeze"],       # Status effects that SHOULD apply
		"damage_types": ["fire", "normal"],   # Damage types expected
		"affects_player": true,               # Whether player stats should change
		"affects_enemies": true               # Whether enemies should be affected
	}
	"""
	var report = {
		"has_side_effects": false,
		"undeclared_stat_changes": [],
		"undeclared_status_effects": [],
		"undeclared_damage": [],
		"undeclared_events": [],
		"severity": "none",
		"summary": ""
	}
	
	var declared_stats = declared_effects.get("stats", [])
	var declared_statuses = declared_effects.get("statuses", [])
	var declared_damage_types = declared_effects.get("damage_types", ["normal"])
	var affects_player = declared_effects.get("affects_player", false)
	var affects_enemies = declared_effects.get("affects_enemies", true)
	
	# Check 1: Undeclared stat changes on player
	if not declared_stats.is_empty() or affects_player:
		var player_deltas = _compute_player_deltas()
		for stat in player_deltas:
			if stat not in declared_stats and player_deltas[stat] != 0:
				report["has_side_effects"] = true
				report["undeclared_stat_changes"].append({
					"stat": stat,
					"delta": player_deltas[stat],
					"severity": _rate_stat_severity(stat, player_deltas[stat])
				})
	
	# Check 2: Undeclared status effects
	for event in status_events:
		if event["status"] not in declared_statuses:
			report["has_side_effects"] = true
			report["undeclared_status_effects"].append({
				"status": event["status"],
				"enemy_id": event["enemy_id"],
				"params": event["params"],
				"severity": "major"
			})
	
	# Check 3: Undeclared damage types
	for event in damage_events:
		if event.get("target") == "enemy":
			var elem = event.get("element", "normal")
			if elem not in declared_damage_types and elem != "normal":
				report["has_side_effects"] = true
				report["undeclared_damage"].append({
					"element": elem,
					"amount": event["amount"],
					"enemy_id": event["enemy_id"],
					"severity": "major"
				})
	
	# Check 4: Player damage when not expected
	if not affects_player:
		for event in damage_events:
			if event.get("target") == "player":
				report["has_side_effects"] = true
				report["undeclared_events"].append({
					"type": "player_damage",
					"amount": event["amount"],
					"source": event.get("source", "unknown"),
					"severity": "critical"
				})
	
	# Compute overall severity
	report["severity"] = _compute_overall_severity(report)
	
	# Build summary
	var side_effect_count = (
		report["undeclared_stat_changes"].size() +
		report["undeclared_status_effects"].size() +
		report["undeclared_damage"].size() +
		report["undeclared_events"].size()
	)
	
	if side_effect_count == 0:
		report["summary"] = "No side effects detected - item behaves as declared"
	else:
		report["summary"] = "%d undeclared side effects detected (severity: %s)" % [side_effect_count, report["severity"]]
	
	return report

func _compute_player_deltas() -> Dictionary:
	"""Computes the delta for each stat between before and after"""
	var deltas = {}
	
	for stat in player_state_before:
		if stat == "position": continue  # Skip position
		
		var before_val = player_state_before.get(stat, 0)
		var after_val = player_state_after.get(stat, 0)
		
		if typeof(before_val) in [TYPE_INT, TYPE_FLOAT] and typeof(after_val) in [TYPE_INT, TYPE_FLOAT]:
			deltas[stat] = after_val - before_val
	
	return deltas

func _rate_stat_severity(stat_name: String, delta) -> String:
	"""Rates the severity of an undeclared stat change"""
	# Critical stats that could indicate serious bugs
	var critical_stats = ["max_hp", "current_hp", "shield", "armor"]
	# Major stats that affect gameplay significantly
	var major_stats = ["damage_mult", "crit_chance", "crit_damage", "cooldown_mult"]
	# Minor stats
	var minor_stats = ["pickup_range", "xp_mult", "gold_mult", "luck"]
	
	if stat_name in critical_stats:
		return "critical" if abs(delta) > 1 else "major"
	elif stat_name in major_stats:
		return "major"
	elif stat_name in minor_stats:
		return "minor"
	else:
		return "major"  # Unknown stat = major by default

func _compute_overall_severity(report: Dictionary) -> String:
	"""Computes overall severity from all side effects"""
	var severities = []
	
	for item in report["undeclared_stat_changes"]:
		severities.append(item["severity"])
	for item in report["undeclared_status_effects"]:
		severities.append(item["severity"])
	for item in report["undeclared_damage"]:
		severities.append(item["severity"])
	for item in report["undeclared_events"]:
		severities.append(item["severity"])
	
	if "critical" in severities:
		return "critical"
	elif "major" in severities:
		return "major"
	elif "minor" in severities:
		return "minor"
	else:
		return "none"

# ═══════════════════════════════════════════════════════════════════════════════
# REPORTING
# ═══════════════════════════════════════════════════════════════════════════════

func get_all_events() -> Dictionary:
	"""Returns all captured events for debugging"""
	return {
		"damage_events": damage_events.duplicate(),
		"status_events": status_events.duplicate(),
		"stat_change_events": stat_change_events.duplicate(),
		"spawn_events": spawn_events.duplicate(),
		"other_events": other_events.duplicate(),
		"player_state_before": player_state_before.duplicate(),
		"player_state_after": player_state_after.duplicate(),
		"enemy_count": _tracked_enemies.size()
	}

func get_summary() -> Dictionary:
	"""Returns a summary of all activity"""
	return {
		"total_damage_events": damage_events.size(),
		"total_status_events": status_events.size(),
		"total_stat_changes": stat_change_events.size(),
		"enemies_tracked": _tracked_enemies.size(),
		"player_tracked": _player_ref != null
	}
