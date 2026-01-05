# PlayerStats.gd
# Sistema de estadísticas del JUGADOR (no de armas)
#
# STATS DEL JUGADOR (supervivencia y utilidad):
# - max_health: Vida máxima
# - health_regen: Regeneración de vida por segundo
# - armor: Reducción de daño plana
# - dodge_chance: Probabilidad de esquivar (máx 60%)
# - life_steal: % de daño infligido que recupera como vida
# - move_speed: Velocidad de movimiento
# - pickup_range: Rango de recolección de XP/monedas
# - xp_mult: Multiplicador de experiencia
# - coin_value_mult: Multiplicador del valor de monedas
# - luck: Afecta rareza de drops y mejoras ofrecidas
#
# Los stats de ARMAS (daño, velocidad de ataque, área, etc.) están en:
# - WeaponStats.gd (por arma individual)
# - GlobalWeaponStats.gd (mejoras globales a todas las armas)

extends Node
class_name PlayerStats

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal health_changed(current: float, maximum: float)
signal level_changed(new_level: int)
signal xp_gained(amount: float, total: float)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

# Metadatos de cada stat para UI
const STAT_METADATA: Dictionary = {
	# === STATS DEFENSIVOS ===
	"max_health": {
		"name": "Vida Máxima",
		"icon": "❤️",
		"category": "defensive",
		"description": "La cantidad máxima de puntos de vida.",
		"format": "flat",
		"color": Color(1.0, 0.3, 0.3)
	},
	"health_regen": {
		"name": "Regeneración",
		"icon": "💚",
		"category": "defensive",
		"description": "Puntos de vida recuperados por segundo.",
		"format": "per_second",
		"color": Color(0.3, 1.0, 0.3)
	},
	"armor": {
		"name": "Armadura",
		"icon": "🛡️",
		"category": "defensive",
		"description": "Reduce el daño recibido de forma plana.",
		"format": "flat",
		"color": Color(0.6, 0.6, 0.8)
	},
	"dodge_chance": {
		"name": "Esquivar",
		"icon": "💨",
		"category": "defensive",
		"description": "Probabilidad de evitar un ataque. Máximo 60%.",
		"format": "percent",
		"color": Color(0.5, 0.8, 1.0)
	},
	"life_steal": {
		"name": "Robo de Vida",
		"icon": "🩸",
		"category": "defensive",
		"description": "% de daño infligido que recuperas como vida.",
		"format": "percent",
		"color": Color(0.8, 0.2, 0.4)
	},

	# === STATS DE UTILIDAD ===
	"move_speed": {
		"name": "Velocidad",
		"icon": "🏃",
		"category": "utility",
		"description": "Velocidad de movimiento del personaje.",
		"format": "percent",
		"color": Color(0.4, 0.8, 1.0)
	},
	"pickup_range": {
		"name": "Rango Recogida",
		"icon": "🧲",
		"category": "utility",
		"description": "Distancia a la que atraes XP y monedas.",
		"format": "percent",
		"color": Color(0.8, 0.5, 1.0)
	},
	"xp_mult": {
		"name": "Experiencia",
		"icon": "⭐",
		"category": "utility",
		"description": "Multiplicador de experiencia obtenida.",
		"format": "percent",
		"color": Color(0.3, 0.9, 0.5)
	},
	"coin_value_mult": {
		"name": "Valor Monedas",
		"icon": "🪙",
		"category": "utility",
		"description": "Multiplicador del valor de las monedas.",
		"format": "percent",
		"color": Color(1.0, 0.85, 0.2)
	},
	"luck": {
		"name": "Suerte",
		"icon": "🍀",
		"category": "utility",
		"description": "Mejora la rareza de drops y mejoras ofrecidas.",
		"format": "flat",
		"color": Color(0.2, 0.9, 0.4)
	}
}

# Stats base del jugador
const BASE_STATS: Dictionary = {
	# Defensivos
	"max_health": 100.0,
	"health_regen": 0.0,
	"armor": 0.0,
	"dodge_chance": 0.0,
	"life_steal": 0.0,

	# Utilidad
	"move_speed": 1.0,
	"pickup_range": 1.0,
	"xp_mult": 1.0,
	"coin_value_mult": 1.0,
	"luck": 0.0
}

const MAX_LEVEL: int = 99
const BASE_XP_TO_LEVEL: float = 10.0
const XP_SCALING: float = 1.15

# Límites de stats
const STAT_LIMITS: Dictionary = {
	"dodge_chance": {"min": 0.0, "max": 0.6},
	"life_steal": {"min": 0.0, "max": 0.5},
	"move_speed": {"min": 0.3, "max": 3.0},
	"pickup_range": {"min": 0.5, "max": 5.0},
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var stats: Dictionary = {}
var temp_modifiers: Dictionary = {}
var collected_upgrades: Array = []
var current_health: float = 100.0
var level: int = 1
var current_xp: float = 0.0
var xp_to_next_level: float = BASE_XP_TO_LEVEL

# Referencia a GlobalWeaponStats para sincronizar vida robada
var global_weapon_stats: GlobalWeaponStats = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	_reset_stats()

func _reset_stats() -> void:
	stats = BASE_STATS.duplicate()
	temp_modifiers.clear()
	collected_upgrades.clear()
	current_health = stats.max_health
	level = 1
	current_xp = 0.0
	xp_to_next_level = BASE_XP_TO_LEVEL

func initialize(p_global_weapon_stats: GlobalWeaponStats = null) -> void:
	global_weapon_stats = p_global_weapon_stats
	add_to_group("player_stats")
	print("[PlayerStats] Inicializado - Nivel %d" % level)

# ═══════════════════════════════════════════════════════════════════════════════
# METADATOS PARA UI
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat_metadata(stat_name: String) -> Dictionary:
	return STAT_METADATA.get(stat_name, {
		"name": stat_name,
		"icon": "❓",
		"category": "other",
		"description": "Sin descripción.",
		"format": "flat",
		"color": Color.WHITE
	})

func get_stats_by_category(category: String) -> Array:
	var result = []
	for stat_name in STAT_METADATA:
		if STAT_METADATA[stat_name].get("category") == category:
			result.append(stat_name)
	return result

func get_all_categories() -> Array:
	return ["defensive", "utility"]

func format_stat_value(stat_name: String, value: float) -> String:
	var meta = get_stat_metadata(stat_name)
	var format_type = meta.get("format", "flat")

	match format_type:
		"percent":
			if value >= 1.0:
				return "+%.0f%%" % ((value - 1.0) * 100) if value > 1.0 else "0%"
			else:
				return "%.0f%%" % (value * 100)
		"per_second":
			return "%.1f/s" % value
		_:
			if value == int(value):
				return "%d" % int(value)
			else:
				return "%.1f" % value

# ═══════════════════════════════════════════════════════════════════════════════
# GETTERS DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat(stat_name: String) -> float:
	var base_value = stats.get(stat_name, 0.0)
	var temp_bonus = _get_temp_modifier_total(stat_name)
	var final_value = base_value + temp_bonus

	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		final_value = clampf(final_value, limits.min, limits.max)

	return final_value

func get_base_stat(stat_name: String) -> float:
	return stats.get(stat_name, 0.0)

func _get_temp_modifier_total(stat_name: String) -> float:
	if not temp_modifiers.has(stat_name):
		return 0.0
	var total = 0.0
	for mod in temp_modifiers[stat_name]:
		total += mod.amount
	return total

# ═══════════════════════════════════════════════════════════════════════════════
# MODIFICACIÓN DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

func add_stat(stat_name: String, amount: float) -> void:
	if not stats.has(stat_name):
		stats[stat_name] = 0.0

	var old_value = stats[stat_name]
	stats[stat_name] += amount

	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		stats[stat_name] = clampf(stats[stat_name], limits.min, limits.max)

	var new_value = stats[stat_name]

	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)
		_on_stat_changed(stat_name, old_value, new_value)

	print("[PlayerStats] %s: %.2f → %.2f (+%.2f)" % [stat_name, old_value, new_value, amount])

func set_stat(stat_name: String, value: float) -> void:
	var old_value = stats.get(stat_name, 0.0)
	stats[stat_name] = value

	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		stats[stat_name] = clampf(stats[stat_name], limits.min, limits.max)

	var new_value = stats[stat_name]

	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)
		_on_stat_changed(stat_name, old_value, new_value)

func multiply_stat(stat_name: String, multiplier: float) -> void:
	if not stats.has(stat_name):
		return
	add_stat(stat_name, stats[stat_name] * (multiplier - 1.0))

func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	match stat_name:
		"max_health":
			var ratio = current_health / old_value if old_value > 0 else 1.0
			current_health = new_value * ratio
			health_changed.emit(current_health, new_value)

# ═══════════════════════════════════════════════════════════════════════════════
# MODIFICADORES TEMPORALES
# ═══════════════════════════════════════════════════════════════════════════════

func add_temp_modifier(stat_name: String, amount: float, duration: float, source: String = "") -> void:
	if not temp_modifiers.has(stat_name):
		temp_modifiers[stat_name] = []

	temp_modifiers[stat_name].append({
		"amount": amount,
		"duration": duration,
		"source": source,
		"time_added": Time.get_ticks_msec() / 1000.0
	})

func remove_temp_modifiers_by_source(source: String) -> void:
	for stat_name in temp_modifiers:
		temp_modifiers[stat_name] = temp_modifiers[stat_name].filter(
			func(mod): return mod.source != source
		)

func _process(delta: float) -> void:
	_update_temp_modifiers(delta)
	_update_health_regen(delta)

func _update_temp_modifiers(delta: float) -> void:
	for stat_name in temp_modifiers.keys():
		var mods = temp_modifiers[stat_name]
		var to_remove = []

		for i in range(mods.size()):
			mods[i].duration -= delta
			if mods[i].duration <= 0:
				to_remove.append(i)

		for i in range(to_remove.size() - 1, -1, -1):
			mods.remove_at(to_remove[i])

		if mods.is_empty():
			temp_modifiers.erase(stat_name)

func _update_health_regen(delta: float) -> void:
	var regen = get_stat("health_regen")
	if regen > 0 and current_health < get_stat("max_health"):
		heal(regen * delta)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE VIDA
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage(amount: float) -> float:
	# Verificar esquivar
	var dodge = get_stat("dodge_chance")
	if dodge > 0 and randf() < dodge:
		print("[PlayerStats] ¡Esquivado!")
		return 0.0

	var armor = get_stat("armor")
	var effective_damage = maxf(1.0, amount - armor)

	current_health -= effective_damage
	current_health = maxf(0.0, current_health)

	health_changed.emit(current_health, get_stat("max_health"))
	return effective_damage

func heal(amount: float) -> float:
	var max_hp = get_stat("max_health")
	var old_health = current_health

	current_health = minf(current_health + amount, max_hp)
	var healed = current_health - old_health

	if healed > 0:
		health_changed.emit(current_health, max_hp)

	return healed

func apply_life_steal(damage_dealt: float) -> float:
	"""Aplicar robo de vida basado en daño infligido"""
	var life_steal_percent = get_stat("life_steal")
	if life_steal_percent <= 0:
		return 0.0

	var heal_amount = damage_dealt * life_steal_percent
	return heal(heal_amount)

func is_dead() -> bool:
	return current_health <= 0

func get_health_percent() -> float:
	return current_health / get_stat("max_health")

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE NIVELES
# ═══════════════════════════════════════════════════════════════════════════════

func gain_xp(amount: float) -> int:
	var xp_bonus = get_stat("xp_mult")
	var effective_xp = amount * xp_bonus

	current_xp += effective_xp
	xp_gained.emit(effective_xp, current_xp)

	var levels_gained = 0

	while current_xp >= xp_to_next_level and level < MAX_LEVEL:
		current_xp -= xp_to_next_level
		level += 1
		levels_gained += 1
		xp_to_next_level = BASE_XP_TO_LEVEL * pow(XP_SCALING, level - 1)

		print("[PlayerStats] ⬆️ ¡Nivel %d alcanzado!" % level)
		level_changed.emit(level)

	return levels_gained

func get_xp_progress() -> float:
	return current_xp / xp_to_next_level

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS DEL JUGADOR (solo stats del player, no de armas)
# ═══════════════════════════════════════════════════════════════════════════════

const PLAYER_UPGRADES: Dictionary = {
	# === DEFENSIVOS ===
	"max_health_1": {
		"name": "Vitalidad I",
		"description": "+15 Vida máxima",
		"stat": "max_health",
		"amount": 15.0,
		"icon": "❤️",
		"rarity": "common",
		"tier": 1
	},
	"max_health_2": {
		"name": "Vitalidad II",
		"description": "+30 Vida máxima",
		"stat": "max_health",
		"amount": 30.0,
		"icon": "❤️",
		"rarity": "uncommon",
		"tier": 2
	},
	"max_health_3": {
		"name": "Vitalidad III",
		"description": "+50 Vida máxima",
		"stat": "max_health",
		"amount": 50.0,
		"icon": "❤️",
		"rarity": "rare",
		"tier": 3
	},
	"health_regen_1": {
		"name": "Regeneración I",
		"description": "+0.5 HP/s",
		"stat": "health_regen",
		"amount": 0.5,
		"icon": "💚",
		"rarity": "common",
		"tier": 1
	},
	"health_regen_2": {
		"name": "Regeneración II",
		"description": "+1.5 HP/s",
		"stat": "health_regen",
		"amount": 1.5,
		"icon": "💚",
		"rarity": "uncommon",
		"tier": 2
	},
	"armor_1": {
		"name": "Armadura I",
		"description": "+2 Armadura",
		"stat": "armor",
		"amount": 2.0,
		"icon": "🛡️",
		"rarity": "common",
		"tier": 1
	},
	"armor_2": {
		"name": "Armadura II",
		"description": "+5 Armadura",
		"stat": "armor",
		"amount": 5.0,
		"icon": "🛡️",
		"rarity": "uncommon",
		"tier": 2
	},
	"dodge_1": {
		"name": "Evasión I",
		"description": "+5% Esquivar",
		"stat": "dodge_chance",
		"amount": 0.05,
		"icon": "💨",
		"rarity": "uncommon",
		"tier": 2
	},
	"dodge_2": {
		"name": "Evasión II",
		"description": "+10% Esquivar",
		"stat": "dodge_chance",
		"amount": 0.10,
		"icon": "💨",
		"rarity": "rare",
		"tier": 3
	},
	"life_steal_1": {
		"name": "Vampirismo I",
		"description": "+3% Robo de vida",
		"stat": "life_steal",
		"amount": 0.03,
		"icon": "🩸",
		"rarity": "uncommon",
		"tier": 2
	},
	"life_steal_2": {
		"name": "Vampirismo II",
		"description": "+7% Robo de vida",
		"stat": "life_steal",
		"amount": 0.07,
		"icon": "🩸",
		"rarity": "rare",
		"tier": 3
	},

	# === UTILIDAD ===
	"move_speed_1": {
		"name": "Velocidad I",
		"description": "+10% Vel. movimiento",
		"stat": "move_speed",
		"amount": 0.10,
		"icon": "🏃",
		"rarity": "common",
		"tier": 1
	},
	"move_speed_2": {
		"name": "Velocidad II",
		"description": "+20% Vel. movimiento",
		"stat": "move_speed",
		"amount": 0.20,
		"icon": "🏃",
		"rarity": "uncommon",
		"tier": 2
	},
	"pickup_range_1": {
		"name": "Magnetismo I",
		"description": "+25% Rango recogida",
		"stat": "pickup_range",
		"amount": 0.25,
		"icon": "🧲",
		"rarity": "common",
		"tier": 1
	},
	"pickup_range_2": {
		"name": "Magnetismo II",
		"description": "+50% Rango recogida",
		"stat": "pickup_range",
		"amount": 0.50,
		"icon": "🧲",
		"rarity": "uncommon",
		"tier": 2
	},
	"xp_mult_1": {
		"name": "Sabiduría I",
		"description": "+15% Experiencia",
		"stat": "xp_mult",
		"amount": 0.15,
		"icon": "⭐",
		"rarity": "common",
		"tier": 1
	},
	"xp_mult_2": {
		"name": "Sabiduría II",
		"description": "+30% Experiencia",
		"stat": "xp_mult",
		"amount": 0.30,
		"icon": "⭐",
		"rarity": "uncommon",
		"tier": 2
	},
	"coin_value_1": {
		"name": "Avaricia I",
		"description": "+20% Valor monedas",
		"stat": "coin_value_mult",
		"amount": 0.20,
		"icon": "🪙",
		"rarity": "common",
		"tier": 1
	},
	"coin_value_2": {
		"name": "Avaricia II",
		"description": "+40% Valor monedas",
		"stat": "coin_value_mult",
		"amount": 0.40,
		"icon": "🪙",
		"rarity": "uncommon",
		"tier": 2
	},
	"luck_1": {
		"name": "Fortuna I",
		"description": "+5 Suerte",
		"stat": "luck",
		"amount": 5.0,
		"icon": "🍀",
		"rarity": "uncommon",
		"tier": 2
	},
	"luck_2": {
		"name": "Fortuna II",
		"description": "+15 Suerte",
		"stat": "luck",
		"amount": 15.0,
		"icon": "🍀",
		"rarity": "rare",
		"tier": 3
	}
}

func get_random_upgrades(count: int = 3, game_time_minutes: float = 0.0) -> Array:
	"""Obtener mejoras aleatorias del jugador con sistema de tiers por tiempo"""
	var luck = get_stat("luck")
	var tier_weights = _calculate_tier_weights(game_time_minutes, luck)

	var selected = []
	var attempts = 0
	var max_attempts = count * 10

	while selected.size() < count and attempts < max_attempts:
		attempts += 1

		var selected_tier = _weighted_random_tier(tier_weights)
		var tier_upgrades = []

		for upgrade_id in PLAYER_UPGRADES:
			var upgrade = PLAYER_UPGRADES[upgrade_id]
			if upgrade.get("tier", 1) == selected_tier:
				tier_upgrades.append(upgrade_id)

		if tier_upgrades.is_empty():
			continue

		var upgrade_id = tier_upgrades[randi() % tier_upgrades.size()]

		# Evitar duplicados
		var already_selected = false
		for s in selected:
			if s.get("id") == upgrade_id:
				already_selected = true
				break

		if not already_selected:
			var upgrade = PLAYER_UPGRADES[upgrade_id].duplicate()
			upgrade["id"] = upgrade_id
			selected.append(upgrade)

	return selected

func _calculate_tier_weights(game_time_minutes: float, luck: float) -> Dictionary:
	var weights = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}

	if game_time_minutes < 3.0:
		weights = {1: 0.80, 2: 0.18, 3: 0.02, 4: 0.0}
	elif game_time_minutes < 8.0:
		weights = {1: 0.50, 2: 0.35, 3: 0.13, 4: 0.02}
	elif game_time_minutes < 15.0:
		weights = {1: 0.25, 2: 0.35, 3: 0.30, 4: 0.10}
	else:
		weights = {1: 0.10, 2: 0.30, 3: 0.35, 4: 0.25}

	# Aplicar suerte
	if luck > 0:
		var luck_factor = clampf(luck * 0.01, 0.0, 0.25)
		var shift = (weights[1] + weights[2]) * luck_factor
		weights[1] *= (1.0 - luck_factor)
		weights[2] *= (1.0 - luck_factor * 0.5)
		weights[3] += shift * 0.6
		weights[4] += shift * 0.4

	return weights

func _weighted_random_tier(weights: Dictionary) -> int:
	var total = 0.0
	for w in weights.values():
		total += w

	var roll = randf() * total
	var cumulative = 0.0

	for tier in weights:
		cumulative += weights[tier]
		if roll <= cumulative:
			return tier

	return 1

func apply_upgrade(upgrade_data) -> bool:
	var upgrade_id: String = ""
	var upgrade_dict: Dictionary = {}

	if upgrade_data is String:
		upgrade_id = upgrade_data
	elif upgrade_data is Dictionary:
		upgrade_id = upgrade_data.get("upgrade_id", upgrade_data.get("id", ""))
		upgrade_dict = upgrade_data
	else:
		push_error("[PlayerStats] apply_upgrade: tipo invalido")
		return false

	if upgrade_id != "" and PLAYER_UPGRADES.has(upgrade_id):
		var upgrade = PLAYER_UPGRADES[upgrade_id]
		add_stat(upgrade.stat, upgrade.amount)
		add_upgrade({
			"id": upgrade_id,
			"name": upgrade.name,
			"icon": upgrade.get("icon", ""),
			"description": upgrade.description,
			"effects": [{"stat": upgrade.stat, "value": upgrade.amount, "operation": "add"}]
		})
		print("[PlayerStats] Upgrade aplicado: %s" % upgrade.name)
		return true

	if upgrade_dict.has("effects"):
		for effect in upgrade_dict.effects:
			var stat = effect.get("stat", "")
			var value = effect.get("value", 0)
			var op = effect.get("operation", "add")
			if stat != "" and stat in stats:
				match op:
					"add": add_stat(stat, value)
					"multiply": multiply_stat(stat, value)
					"set": set_stat(stat, value)
		add_upgrade(upgrade_dict)
		return true

	if upgrade_dict.has("stat") and upgrade_dict.has("amount"):
		if upgrade_dict.stat in stats:
			add_stat(upgrade_dict.stat, upgrade_dict.amount)
			add_upgrade(upgrade_dict)
			return true

	return false

func add_upgrade(upgrade_dict: Dictionary) -> void:
	collected_upgrades.append(upgrade_dict)

func get_collected_upgrades() -> Array:
	return collected_upgrades.duplicate()

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	return {
		"stats": stats.duplicate(),
		"current_health": current_health,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level,
		"collected_upgrades": collected_upgrades.duplicate(true)
	}

func from_dict(data: Dictionary) -> void:
	if data.has("stats"):
		stats = data.stats.duplicate()
	if data.has("current_health"):
		current_health = data.current_health
	if data.has("level"):
		level = data.level
	if data.has("current_xp"):
		current_xp = data.current_xp
	if data.has("xp_to_next_level"):
		xp_to_next_level = data.xp_to_next_level
	if data.has("collected_upgrades"):
		collected_upgrades = data.collected_upgrades.duplicate(true)

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	var lines = [
		"=== PLAYER STATS ===",
		"Nivel: %d (XP: %.0f/%.0f)" % [level, current_xp, xp_to_next_level],
		"Vida: %.0f/%.0f (%.0f%%)" % [current_health, get_stat("max_health"), get_health_percent() * 100],
		"",
		"Stats:"
	]

	for stat_name in stats:
		var value = get_stat(stat_name)
		lines.append("  %s: %s" % [stat_name, format_stat_value(stat_name, value)])

	return "\n".join(lines)
