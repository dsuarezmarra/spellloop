# StatResolver.gd
# Sistema centralizado de resolución de stats para QA Automation
#
# PROPÓSITO:
# - Mapea nombres de stats del QA a propiedades reales del runtime
# - Soporta múltiples fuentes: PlayerStats, GlobalWeaponStats, WeaponStats
# - Maneja aliases (ej: damage_mult vs dmg_mult)
# - Distingue entre operaciones ADD vs MULTIPLY
# - Devuelve valores tipados y explicaciones claras cuando una stat no aplica
#
# AUTOR: QA Automation System
# FECHA: 2026-01-29

extends RefCounted
class_name StatResolver

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES - MAPEO COMPLETO DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

# Stats que viven en PlayerStats (PLAYER_ONLY scope)
# Lista completa extraída de PlayerStats.BASE_STATS
const PLAYER_STATS: Array = [
	# Defensivos
	"max_health", "health_regen", "armor", "dodge_chance", "damage_taken_mult",
	"thorns", "thorns_percent", "thorns_slow", "thorns_stun",
	"revive_invuln",
	"shield_amount", "max_shield", "shield_regen", "shield_regen_delay",
	"revives",
	
	# Duración de efectos
	"status_duration_mult",
	
	# Ofensivos - Stats globales de armas
	"damage_mult", "damage_flat",
	"attack_speed_mult", "area_mult", "projectile_speed_mult",
	"duration_mult", "extra_projectiles", "extra_pierce",
	"knockback_mult", "range_mult", "chain_count",
	
	# Efectos especiales de ataque
	"burn_damage", "burn_chance", "freeze_chance", "bleed_chance",
	"explosion_chance", "explosion_damage",
	"execute_threshold", "overkill_damage",
	
	# Daño contra elites/jefes
	"elite_damage_mult",
	
	# Sinergias - Daño condicional
	"damage_vs_slowed", "damage_vs_burning", "damage_vs_frozen",
	"low_hp_damage_bonus", "full_hp_damage_bonus",
	
	# Mejoras de builds específicos
	"orbital_damage_mult", "orbital_count_bonus", "orbital_speed_mult",
	"aoe_damage_mult", "single_target_mult", "kill_damage_scaling",
	"enemy_slow_aura", "hp_cost_per_attack", "infinite_pickup_range",
	
	# Stats únicos
	"is_glass_cannon",
	
	# Críticos
	"crit_chance", "crit_damage",
	
	# Curación
	"kill_heal",
	
	# Utilidad
	"move_speed", "pickup_range", "pickup_range_flat", "magnet_strength",
	"xp_mult", "coin_value_mult", "gold_mult", "luck", "curse",
	"growth", "reroll_count", "banish_count", "levelup_options",
	
	# New Items Phase
	"damage_per_gold", "heal_on_pickup", "xp_on_reroll", "momentum_factor",
	
	# Phase 4: Unique Logic Stats
	"instant_combustion", "instant_bleed", "multicast_chance",
	
	# Phase 5: Defensive Logic Stats
	"frost_nova_on_hit", "grit_active", "turret_bonus", "blood_pact",
	
	# QA Fix Phase - Missing Stats (2026-01-29)
	"bleed_on_hit_chance", "chrono_jump_active", "close_range_damage_bonus",
	"combustion_active", "double_coin_streak", "effect_duration", "effect_value",
	"knockback", "long_range_damage_bonus", "near_sighted_active",
	"plague_bearer_active", "russian_roulette", "soul_link_percent",
	"streak_bonus_mult", "turret_mode_enabled",
]

# Stats que viven en GlobalWeaponStats (GLOBAL_WEAPON scope)
const GLOBAL_WEAPON_STATS: Array = [
	"damage_mult", "damage_flat",
	"attack_speed_mult",
	"projectile_speed_mult",
	"area_mult",
	"range_mult",
	"duration_mult",
	"knockback_mult",
	"extra_projectiles",
	"extra_pierce",
	"chain_count",
	"crit_chance", "crit_damage",
	"life_steal",
]

# Aliases - mapea nombres alternativos a nombres canónicos
const STAT_ALIASES: Dictionary = {
	# Health aliases
	"max_hp": "max_health",
	"health_max": "max_health",
	"hp_regen": "health_regen",
	"regen": "health_regen",
	# Defense aliases
	"defence": "armor",
	"evasion": "dodge_chance",
	"lifesteal": "life_steal",
	# Movement aliases
	"speed": "move_speed",
	"movement_speed": "move_speed",
	# Weapon stat aliases
	"dmg_mult": "damage_mult",
	"damage_multiplier": "damage_mult",
	"atk_speed": "attack_speed_mult",
	"attack_speed": "attack_speed_mult",
	"proj_speed": "projectile_speed_mult",
	"projectile_speed": "projectile_speed_mult",
	"cooldown_mult": "duration_mult",  # Often confused
	"cooldown_reduction": "duration_mult",
	# Projectile aliases
	"projectile_count": "extra_projectiles",
	"pierce": "extra_pierce",
	"piercing": "extra_pierce",
	"pierce_final": "extra_pierce",
	# Critical aliases
	"critical_chance": "crit_chance",
	"critical_damage": "crit_damage",
	# Status aliases
	"burn_damage": "burn_chance",  # Sometimes confused
	# Shield aliases
	"shield": "shield_amount",
	"barrier": "shield_amount",
}

# Semántica de operaciones por stat
# "add" = se suma al valor base
# "multiply" = se multiplica por el valor base
# "set" = reemplaza el valor base
const STAT_OPERATIONS: Dictionary = {
	# Multiplicadores (multiply)
	"damage_mult": "multiply",
	"attack_speed_mult": "multiply",
	"projectile_speed_mult": "multiply",
	"area_mult": "multiply",
	"range_mult": "multiply",
	"duration_mult": "multiply",
	"knockback_mult": "multiply",
	"xp_mult": "multiply",
	"gold_mult": "multiply",
	"coin_value_mult": "multiply",
	"damage_taken_mult": "multiply",
	"status_duration_mult": "multiply",
	"crit_damage": "multiply",  # Es un multiplicador pero se suma al base 2.0
	"magnet_strength": "multiply",
	"orbital_speed_mult": "multiply",
	"single_target_mult": "multiply",
	
	# Aditivos (add)
	"max_health": "add",
	"health_regen": "add",
	"armor": "add",
	"dodge_chance": "add",
	"thorns": "add",
	"thorns_percent": "add",
	"thorns_slow": "add",
	"thorns_stun": "add",
	"shield_amount": "add",
	"max_shield": "add",
	"shield_regen": "add",
	"shield_regen_delay": "add",
	"revives": "add",
	"revive_invuln": "add",
	"extra_projectiles": "add",
	"extra_pierce": "add",
	"chain_count": "add",
	"crit_chance": "add",
	"life_steal": "add",
	"damage_flat": "add",
	"move_speed": "add",
	"pickup_range": "add",
	"pickup_range_flat": "add",
	"luck": "add",
	"curse": "add",
	"growth": "add",
	"kill_heal": "add",
	"burn_chance": "add",
	"burn_damage": "add",
	"freeze_chance": "add",
	"bleed_chance": "add",
	"explosion_chance": "add",
	"explosion_damage": "add",
	"execute_threshold": "add",
	"overkill_damage": "add",
	"elite_damage_mult": "add",
	"damage_vs_slowed": "add",
	"damage_vs_burning": "add",
	"damage_vs_frozen": "add",
	"low_hp_damage_bonus": "add",
	"full_hp_damage_bonus": "add",
	"reroll_count": "add",
	"banish_count": "add",
	"levelup_options": "add",
	"orbital_damage_mult": "add",
	"orbital_count_bonus": "add",
	"aoe_damage_mult": "add",
	"kill_damage_scaling": "add",
	"enemy_slow_aura": "add",
	"hp_cost_per_attack": "add",
	"damage_per_gold": "add",
	"heal_on_pickup": "add",
	"xp_on_reroll": "add",
	"momentum_factor": "add",
	"multicast_chance": "add",
	
	# Flags (set)
	"is_glass_cannon": "set",
	"blood_pact": "set",
	"infinite_pickup_range": "set",
	"instant_combustion": "set",
	"instant_bleed": "set",
	"frost_nova_on_hit": "set",
	"grit_active": "set",
	"turret_bonus": "set",
}

# Valores base por defecto (para stats que no tienen valor en el sistema)
# Extraído de PlayerStats.BASE_STATS y GlobalWeaponStats.BASE_GLOBAL_STATS
const DEFAULT_VALUES: Dictionary = {
	# Multiplicadores (base 1.0)
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,
	"projectile_speed_mult": 1.0,
	"area_mult": 1.0,
	"range_mult": 1.0,
	"duration_mult": 1.0,
	"knockback_mult": 1.0,
	"damage_taken_mult": 1.0,
	"status_duration_mult": 1.0,
	"xp_mult": 1.0,
	"gold_mult": 1.0,
	"coin_value_mult": 1.0,
	"orbital_speed_mult": 1.0,
	"single_target_mult": 1.0,
	"magnet_strength": 1.0,
	
	# Críticos
	"crit_chance": 0.05,
	"crit_damage": 2.0,
	
	# Aditivos (base 0)
	"life_steal": 0.0,
	"extra_projectiles": 0,
	"extra_pierce": 0,
	"chain_count": 0,
	"health_regen": 0.0,
	"armor": 0.0,
	"dodge_chance": 0.0,
	"thorns": 0.0,
	"thorns_percent": 0.0,
	"thorns_slow": 0.0,
	"thorns_stun": 0.0,
	"shield_amount": 0.0,
	"max_shield": 0.0,
	"shield_regen": 0.0,
	"revives": 0,
	"revive_invuln": 0.0,
	"damage_flat": 0.0,
	"kill_heal": 0.0,
	"burn_chance": 0.0,
	"burn_damage": 0.0,
	"freeze_chance": 0.0,
	"bleed_chance": 0.0,
	"explosion_chance": 0.0,
	"explosion_damage": 0.0,
	"execute_threshold": 0.0,
	"overkill_damage": 0.0,
	"elite_damage_mult": 0.0,
	"damage_vs_slowed": 0.0,
	"damage_vs_burning": 0.0,
	"damage_vs_frozen": 0.0,
	"low_hp_damage_bonus": 0.0,
	"full_hp_damage_bonus": 0.0,
	"luck": 0.0,
	"curse": 0.0,
	"growth": 0.0,
	"reroll_count": 0,
	"banish_count": 0,
	"levelup_options": 0,
	"pickup_range_flat": 0.0,
	"orbital_damage_mult": 0.0,
	"orbital_count_bonus": 0,
	"aoe_damage_mult": 0.0,
	"kill_damage_scaling": 0.0,
	"enemy_slow_aura": 0.0,
	"hp_cost_per_attack": 0.0,
	"infinite_pickup_range": 0,
	"is_glass_cannon": 0,
	"damage_per_gold": 0.0,
	"heal_on_pickup": 0,
	"xp_on_reroll": 0.0,
	"momentum_factor": 0.0,
	"instant_combustion": 0,
	"instant_bleed": 0,
	"multicast_chance": 0.0,
	"frost_nova_on_hit": 0,
	"grit_active": 0,
	"turret_bonus": 0,
	"blood_pact": 0,
	
	# QA Fix Phase - Missing Stats Defaults (2026-01-29)
	"bleed_on_hit_chance": 0.0,
	"chrono_jump_active": 0,
	"close_range_damage_bonus": 0.0,
	"combustion_active": 0,
	"double_coin_streak": 0,
	"effect_duration": 0.0,
	"effect_value": 0.0,
	"knockback": 0.0,
	"long_range_damage_bonus": 0.0,
	"near_sighted_active": 0,
	"plague_bearer_active": 0,
	"russian_roulette": 0,
	"soul_link_percent": 0.0,
	"streak_bonus_mult": 1.0,
	"turret_mode_enabled": 0,
	
	# Valores absolutos
	"max_health": 100.0,
	"move_speed": 100.0,
	"pickup_range": 100.0,
	"shield_regen_delay": 3.0,
}

# ═══════════════════════════════════════════════════════════════════════════════
# RESOLUCIÓN DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

static func resolve_stat_name(stat_name: String) -> String:
	"""Convierte un alias a nombre canónico."""
	return STAT_ALIASES.get(stat_name, stat_name)

static func get_stat_source(stat_name: String) -> String:
	"""Determina de qué fuente viene un stat."""
	var canonical = resolve_stat_name(stat_name)
	if canonical in GLOBAL_WEAPON_STATS:
		return "GlobalWeaponStats"
	elif canonical in PLAYER_STATS:
		return "PlayerStats"
	else:
		return "Unknown"

static func get_stat_operation(stat_name: String) -> String:
	"""Retorna la semántica de operación para un stat."""
	var canonical = resolve_stat_name(stat_name)
	return STAT_OPERATIONS.get(canonical, "add")

static func get_default_value(stat_name: String) -> float:
	"""Retorna el valor base por defecto para un stat."""
	var canonical = resolve_stat_name(stat_name)
	return DEFAULT_VALUES.get(canonical, 0.0)

# ═══════════════════════════════════════════════════════════════════════════════
# CAPTURA COMPLETA DE ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

static func capture_full_state(player: Node) -> Dictionary:
	"""
	Captura el estado completo de stats desde todas las fuentes.
	Retorna un diccionario con todos los stats resueltos.
	"""
	var state: Dictionary = {}
	var tree = player.get_tree() if player else null
	
	if not tree:
		push_warning("[StatResolver] No scene tree available")
		return state
	
	# 1. Capturar de PlayerStats
	var player_stats = _find_player_stats(player)
	if player_stats:
		for stat_name in PLAYER_STATS:
			var value = _get_stat_from_node(player_stats, stat_name)
			if value != null:
				state[stat_name] = value
	
	# 2. Capturar de GlobalWeaponStats
	var global_weapon_stats = _find_global_weapon_stats(tree)
	if global_weapon_stats:
		for stat_name in GLOBAL_WEAPON_STATS:
			var value = _get_stat_from_node(global_weapon_stats, stat_name)
			if value != null:
				state[stat_name] = value
	
	# 3. Agregar valores por defecto para stats no encontrados
	for stat_name in DEFAULT_VALUES:
		if not state.has(stat_name):
			state[stat_name] = DEFAULT_VALUES[stat_name]
	
	# 4. Agregar metadatos
	state["_capture_time"] = Time.get_unix_time_from_system()
	state["_sources"] = {
		"player_stats_found": player_stats != null,
		"global_weapon_stats_found": global_weapon_stats != null
	}
	
	return state

static func capture_stat(player: Node, stat_name: String) -> Variant:
	"""
	Captura un stat específico.
	Retorna el valor o null si no se encuentra.
	"""
	var canonical = resolve_stat_name(stat_name)
	var source = get_stat_source(canonical)
	var tree = player.get_tree() if player else null
	
	match source:
		"PlayerStats":
			var ps = _find_player_stats(player)
			if ps:
				return _get_stat_from_node(ps, canonical)
		"GlobalWeaponStats":
			if tree:
				var gws = _find_global_weapon_stats(tree)
				if gws:
					return _get_stat_from_node(gws, canonical)
	
	# Fallback a valor por defecto
	return DEFAULT_VALUES.get(canonical, null)

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS PRIVADOS
# ═══════════════════════════════════════════════════════════════════════════════

static func _find_player_stats(player: Node) -> Node:
	"""Encuentra el nodo PlayerStats desde múltiples ubicaciones."""
	if not player:
		return null
	
	# 1. Hijo directo
	if player.has_node("PlayerStats"):
		return player.get_node("PlayerStats")
	
	# 2. Método get_stats
	if player.has_method("get_stats"):
		return player.get_stats()
	
	# 3. El player ES PlayerStats
	if player is PlayerStats:
		return player
	
	# 4. Hermano en el padre
	if player.get_parent() and player.get_parent().has_node("PlayerStats"):
		return player.get_parent().get_node("PlayerStats")
	
	# 5. Buscar en grupo
	if player.get_tree():
		var nodes = player.get_tree().get_nodes_in_group("player_stats")
		if not nodes.is_empty():
			return nodes[0]
	
	return null

static func _find_global_weapon_stats(tree: SceneTree) -> Node:
	"""Encuentra el nodo GlobalWeaponStats."""
	if not tree:
		return null
	
	# Buscar en grupo
	var nodes = tree.get_nodes_in_group("global_weapon_stats")
	if not nodes.is_empty():
		return nodes[0]
	
	# Buscar en escena actual
	var root = tree.current_scene
	if root and root.has_node("GlobalWeaponStats"):
		return root.get_node("GlobalWeaponStats")
	
	return null

static func _get_stat_from_node(node: Node, stat_name: String) -> Variant:
	"""Obtiene un stat de un nodo usando múltiples métodos."""
	# 1. Método get_stat
	if node.has_method("get_stat"):
		var result = node.get_stat(stat_name)
		if result != null:
			return result
	
	# 2. Diccionario stats
	if "stats" in node:
		var stats_dict = node.get("stats")
		if stats_dict is Dictionary and stats_dict.has(stat_name):
			return stats_dict[stat_name]
	
	# 3. Propiedad directa
	if stat_name in node:
		return node.get(stat_name)
	
	return null

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES PARA QA
# ═══════════════════════════════════════════════════════════════════════════════

static func compare_states(before: Dictionary, after: Dictionary) -> Dictionary:
	"""
	Compara dos estados y retorna las diferencias.
	"""
	var changes: Dictionary = {}
	
	# Encontrar stats que cambiaron
	for stat_name in after:
		if stat_name.begins_with("_"):
			continue  # Skip metadata
		
		var before_val = before.get(stat_name, get_default_value(stat_name))
		var after_val = after.get(stat_name, get_default_value(stat_name))
		
		if before_val != after_val:
			changes[stat_name] = {
				"before": before_val,
				"after": after_val,
				"delta": after_val - before_val if typeof(after_val) in [TYPE_FLOAT, TYPE_INT] else null,
				"operation": get_stat_operation(stat_name)
			}
	
	return changes

static func get_all_supported_stats() -> Array:
	"""Retorna lista de todos los stats soportados."""
	var all_stats: Array = []
	all_stats.append_array(PLAYER_STATS)
	all_stats.append_array(GLOBAL_WEAPON_STATS)
	return all_stats

static func get_stat_info(stat_name: String) -> Dictionary:
	"""Retorna información completa sobre un stat."""
	var canonical = resolve_stat_name(stat_name)
	return {
		"canonical_name": canonical,
		"aliases": _get_aliases_for_stat(canonical),
		"source": get_stat_source(canonical),
		"operation": get_stat_operation(canonical),
		"default_value": get_default_value(canonical),
		"is_known": canonical in PLAYER_STATS or canonical in GLOBAL_WEAPON_STATS
	}

static func _get_aliases_for_stat(canonical: String) -> Array:
	"""Retorna todos los aliases que mapean a un nombre canónico."""
	var aliases: Array = []
	for alias in STAT_ALIASES:
		if STAT_ALIASES[alias] == canonical:
			aliases.append(alias)
	return aliases
