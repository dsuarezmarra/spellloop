# PlayerStats.gd
# Sistema de estadísticas del jugador
# 
# IMPORTANTE: No hay items pasivos separados
# Las mejoras van directamente al jugador o a las armas
#
# STATS DEL JUGADOR:
# - max_health: Vida máxima
# - health_regen: Regeneración de vida por segundo
# - move_speed: Velocidad de movimiento
# - damage_mult: Multiplicador de daño global
# - cooldown_mult: Multiplicador de cooldown (menor = más rápido)
# - crit_chance: Probabilidad de crítico
# - crit_damage: Multiplicador de daño crítico
# - area_mult: Multiplicador de área de efecto
# - pickup_range: Rango de recolección de XP
# - xp_mult: Multiplicador de experiencia
# - armor: Reducción de daño plana
# - luck: Afecta rareza de drops y opciones de level up

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

const BASE_STATS: Dictionary = {
	"max_health": 100.0,
	"health_regen": 0.0,
	"move_speed": 1.0,
	"damage_mult": 1.0,
	"cooldown_mult": 1.0,
	"crit_chance": 0.05,
	"crit_damage": 2.0,
	"area_mult": 1.0,
	"pickup_range": 1.0,
	"xp_mult": 1.0,
	"armor": 0.0,
	"luck": 0.0
}

const MAX_LEVEL: int = 99
const BASE_XP_TO_LEVEL: float = 10.0
const XP_SCALING: float = 1.15  # Cada nivel requiere 15% más XP

# Límites de stats
const STAT_LIMITS: Dictionary = {
	"cooldown_mult": {"min": 0.1, "max": 2.0},  # Mínimo 10% cooldown
	"crit_chance": {"min": 0.0, "max": 1.0},     # Máximo 100%
	"damage_mult": {"min": 0.1, "max": 10.0},   # Máximo 1000% daño
	"move_speed": {"min": 0.3, "max": 3.0},     # Rango de velocidad
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Stats actuales
var stats: Dictionary = {}

# Modificadores temporales (por buffs/debuffs)
var temp_modifiers: Dictionary = {}  # stat_name -> [{amount, duration, source}]

# Vida actual
var current_health: float = 100.0

# Sistema de nivel
var level: int = 1
var current_xp: float = 0.0
var xp_to_next_level: float = BASE_XP_TO_LEVEL

# Referencia al AttackManager para sincronizar stats
var attack_manager: AttackManager = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	_reset_stats()

func _reset_stats() -> void:
	"""Resetear a stats base"""
	stats = BASE_STATS.duplicate()
	temp_modifiers.clear()
	current_health = stats.max_health
	level = 1
	current_xp = 0.0
	xp_to_next_level = BASE_XP_TO_LEVEL

func initialize(attack_mgr: AttackManager = null) -> void:
	"""Inicializar con referencia al AttackManager"""
	attack_manager = attack_mgr
	_sync_with_attack_manager()
	print("[PlayerStats] Inicializado - Nivel %d" % level)

func _sync_with_attack_manager() -> void:
	"""Sincronizar stats relevantes con AttackManager"""
	if attack_manager == null:
		return
	
	attack_manager.set_player_stat("damage_mult", get_stat("damage_mult"))
	attack_manager.set_player_stat("cooldown_mult", get_stat("cooldown_mult"))
	attack_manager.set_player_stat("crit_chance", get_stat("crit_chance"))
	attack_manager.set_player_stat("area_mult", get_stat("area_mult"))

# ═══════════════════════════════════════════════════════════════════════════════
# GETTERS DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat(stat_name: String) -> float:
	"""Obtener valor actual de un stat (base + modificadores temporales)"""
	var base_value = stats.get(stat_name, 0.0)
	var temp_bonus = _get_temp_modifier_total(stat_name)
	var final_value = base_value + temp_bonus
	
	# Aplicar límites si existen
	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		final_value = clampf(final_value, limits.min, limits.max)
	
	return final_value

func get_base_stat(stat_name: String) -> float:
	"""Obtener valor base sin modificadores temporales"""
	return stats.get(stat_name, 0.0)

func _get_temp_modifier_total(stat_name: String) -> float:
	"""Obtener suma de modificadores temporales"""
	if not temp_modifiers.has(stat_name):
		return 0.0
	
	var total = 0.0
	for mod in temp_modifiers[stat_name]:
		total += mod.amount
	return total

# ═══════════════════════════════════════════════════════════════════════════════
# MODIFICACIÓN DE STATS (PERMANENTES)
# ═══════════════════════════════════════════════════════════════════════════════

func add_stat(stat_name: String, amount: float) -> void:
	"""Añadir valor a un stat (permanente)"""
	if not stats.has(stat_name):
		stats[stat_name] = 0.0
	
	var old_value = stats[stat_name]
	stats[stat_name] += amount
	
	# Aplicar límites
	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		stats[stat_name] = clampf(stats[stat_name], limits.min, limits.max)
	
	var new_value = stats[stat_name]
	
	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)
		_on_stat_changed(stat_name, old_value, new_value)
	
	print("[PlayerStats] %s: %.2f → %.2f (+%.2f)" % [stat_name, old_value, new_value, amount])

func set_stat(stat_name: String, value: float) -> void:
	"""Establecer valor exacto de un stat"""
	var old_value = stats.get(stat_name, 0.0)
	stats[stat_name] = value
	
	# Aplicar límites
	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		stats[stat_name] = clampf(stats[stat_name], limits.min, limits.max)
	
	var new_value = stats[stat_name]
	
	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)
		_on_stat_changed(stat_name, old_value, new_value)

func multiply_stat(stat_name: String, multiplier: float) -> void:
	"""Multiplicar un stat por un valor"""
	if not stats.has(stat_name):
		return
	add_stat(stat_name, stats[stat_name] * (multiplier - 1.0))

func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	"""Manejar cambios especiales de stats"""
	match stat_name:
		"max_health":
			# Ajustar salud actual proporcionalmente
			var ratio = current_health / old_value if old_value > 0 else 1.0
			current_health = new_value * ratio
			health_changed.emit(current_health, new_value)
		
		"damage_mult", "cooldown_mult", "crit_chance", "area_mult":
			# Sincronizar con AttackManager
			_sync_with_attack_manager()

# ═══════════════════════════════════════════════════════════════════════════════
# MODIFICADORES TEMPORALES (BUFFS/DEBUFFS)
# ═══════════════════════════════════════════════════════════════════════════════

func add_temp_modifier(stat_name: String, amount: float, duration: float, source: String = "") -> void:
	"""Añadir modificador temporal"""
	if not temp_modifiers.has(stat_name):
		temp_modifiers[stat_name] = []
	
	temp_modifiers[stat_name].append({
		"amount": amount,
		"duration": duration,
		"source": source,
		"time_added": Time.get_ticks_msec() / 1000.0
	})
	
	print("[PlayerStats] Buff temporal: %s +%.2f por %.1fs (%s)" % [
		stat_name, amount, duration, source
	])

func remove_temp_modifiers_by_source(source: String) -> void:
	"""Remover todos los modificadores de una fuente específica"""
	for stat_name in temp_modifiers:
		temp_modifiers[stat_name] = temp_modifiers[stat_name].filter(
			func(mod): return mod.source != source
		)

func _process(delta: float) -> void:
	"""Actualizar modificadores temporales y regeneración"""
	_update_temp_modifiers(delta)
	_update_health_regen(delta)

func _update_temp_modifiers(delta: float) -> void:
	"""Reducir duración de modificadores temporales"""
	for stat_name in temp_modifiers.keys():
		var mods = temp_modifiers[stat_name]
		var to_remove = []
		
		for i in range(mods.size()):
			mods[i].duration -= delta
			if mods[i].duration <= 0:
				to_remove.append(i)
		
		# Remover expirados (en orden inverso)
		for i in range(to_remove.size() - 1, -1, -1):
			mods.remove_at(to_remove[i])
		
		# Limpiar array vacío
		if mods.is_empty():
			temp_modifiers.erase(stat_name)

func _update_health_regen(delta: float) -> void:
	"""Aplicar regeneración de vida"""
	var regen = get_stat("health_regen")
	if regen > 0 and current_health < get_stat("max_health"):
		heal(regen * delta)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE VIDA
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage(amount: float) -> float:
	"""
	Recibir daño (aplicando armor)
	Retorna: daño efectivo recibido
	"""
	var armor = get_stat("armor")
	var effective_damage = maxf(1.0, amount - armor)  # Mínimo 1 de daño
	
	current_health -= effective_damage
	current_health = maxf(0.0, current_health)
	
	health_changed.emit(current_health, get_stat("max_health"))
	
	return effective_damage

func heal(amount: float) -> float:
	"""
	Curar vida
	Retorna: cantidad efectiva curada
	"""
	var max_hp = get_stat("max_health")
	var old_health = current_health
	
	current_health = minf(current_health + amount, max_hp)
	var healed = current_health - old_health
	
	if healed > 0:
		health_changed.emit(current_health, max_hp)
	
	return healed

func is_dead() -> bool:
	"""Verificar si el jugador está muerto"""
	return current_health <= 0

func get_health_percent() -> float:
	"""Obtener porcentaje de vida"""
	return current_health / get_stat("max_health")

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE NIVELES
# ═══════════════════════════════════════════════════════════════════════════════

func gain_xp(amount: float) -> int:
	"""
	Ganar experiencia
	Retorna: número de niveles subidos
	"""
	var xp_bonus = get_stat("xp_mult")
	var effective_xp = amount * xp_bonus
	
	current_xp += effective_xp
	xp_gained.emit(effective_xp, current_xp)
	
	var levels_gained = 0
	
	# Subir niveles mientras haya suficiente XP
	while current_xp >= xp_to_next_level and level < MAX_LEVEL:
		current_xp -= xp_to_next_level
		level += 1
		levels_gained += 1
		
		# Calcular XP para siguiente nivel
		xp_to_next_level = BASE_XP_TO_LEVEL * pow(XP_SCALING, level - 1)
		
		print("[PlayerStats] ⬆️ ¡Nivel %d alcanzado!" % level)
		level_changed.emit(level)
	
	return levels_gained

func get_xp_progress() -> float:
	"""Obtener progreso hacia el siguiente nivel (0.0 - 1.0)"""
	return current_xp / xp_to_next_level

# ═══════════════════════════════════════════════════════════════════════════════
# UPGRADES DISPONIBLES (para Level Up Panel)
# ═══════════════════════════════════════════════════════════════════════════════

# Definición de upgrades disponibles para el jugador
const PLAYER_UPGRADES: Dictionary = {
	"max_health_small": {
		"name": "Vitalidad I",
		"description": "+10 Vida máxima",
		"stat": "max_health",
		"amount": 10.0,
		"icon": "❤️",
		"rarity": "common"
	},
	"max_health_large": {
		"name": "Vitalidad II",
		"description": "+25 Vida máxima",
		"stat": "max_health",
		"amount": 25.0,
		"icon": "❤️",
		"rarity": "uncommon"
	},
	"health_regen": {
		"name": "Regeneración",
		"description": "+0.5 HP/s",
		"stat": "health_regen",
		"amount": 0.5,
		"icon": "💚",
		"rarity": "uncommon"
	},
	"damage_small": {
		"name": "Poder I",
		"description": "+10% Daño",
		"stat": "damage_mult",
		"amount": 0.10,
		"icon": "⚔️",
		"rarity": "common"
	},
	"damage_large": {
		"name": "Poder II",
		"description": "+20% Daño",
		"stat": "damage_mult",
		"amount": 0.20,
		"icon": "⚔️",
		"rarity": "uncommon"
	},
	"cooldown": {
		"name": "Celeridad",
		"description": "-10% Cooldown de armas",
		"stat": "cooldown_mult",
		"amount": -0.10,
		"icon": "⏱️",
		"rarity": "uncommon"
	},
	"crit_chance": {
		"name": "Precisión",
		"description": "+5% Probabilidad de crítico",
		"stat": "crit_chance",
		"amount": 0.05,
		"icon": "🎯",
		"rarity": "uncommon"
	},
	"crit_damage": {
		"name": "Devastación",
		"description": "+25% Daño crítico",
		"stat": "crit_damage",
		"amount": 0.25,
		"icon": "💥",
		"rarity": "rare"
	},
	"area": {
		"name": "Expansión",
		"description": "+15% Área de efecto",
		"stat": "area_mult",
		"amount": 0.15,
		"icon": "🔵",
		"rarity": "uncommon"
	},
	"move_speed": {
		"name": "Velocidad",
		"description": "+10% Velocidad de movimiento",
		"stat": "move_speed",
		"amount": 0.10,
		"icon": "👟",
		"rarity": "common"
	},
	"pickup_range": {
		"name": "Magnetismo",
		"description": "+25% Rango de recolección",
		"stat": "pickup_range",
		"amount": 0.25,
		"icon": "🧲",
		"rarity": "common"
	},
	"xp_mult": {
		"name": "Sabiduría",
		"description": "+15% Experiencia ganada",
		"stat": "xp_mult",
		"amount": 0.15,
		"icon": "📚",
		"rarity": "uncommon"
	},
	"armor": {
		"name": "Armadura",
		"description": "+3 Reducción de daño",
		"stat": "armor",
		"amount": 3.0,
		"icon": "🛡️",
		"rarity": "uncommon"
	},
	"luck": {
		"name": "Fortuna",
		"description": "+10% Suerte",
		"stat": "luck",
		"amount": 0.10,
		"icon": "🍀",
		"rarity": "rare"
	}
}

func get_random_upgrades(count: int = 3, luck_bonus: float = 0.0) -> Array:
	"""
	Obtener upgrades aleatorios para el panel de level up
	luck_bonus aumenta probabilidad de upgrades raros
	"""
	var upgrades_list = PLAYER_UPGRADES.keys()
	upgrades_list.shuffle()
	
	var selected = []
	var actual_luck = get_stat("luck") + luck_bonus
	
	for upgrade_id in upgrades_list:
		if selected.size() >= count:
			break
		
		var upgrade = PLAYER_UPGRADES[upgrade_id].duplicate()
		upgrade["id"] = upgrade_id
		
		# Filtrar por rareza según luck
		var rarity_roll = randf()
		match upgrade.rarity:
			"common":
				selected.append(upgrade)
			"uncommon":
				if rarity_roll < 0.5 + actual_luck * 0.3:
					selected.append(upgrade)
			"rare":
				if rarity_roll < 0.2 + actual_luck * 0.4:
					selected.append(upgrade)
	
	# Si no hay suficientes, llenar con comunes
	while selected.size() < count:
		for upgrade_id in upgrades_list:
			var upgrade = PLAYER_UPGRADES[upgrade_id]
			if upgrade.rarity == "common":
				var dup = upgrade.duplicate()
				dup["id"] = upgrade_id
				if dup not in selected:
					selected.append(dup)
					break
		
		# Prevenir loop infinito
		if selected.size() < count:
			break
	
	return selected.slice(0, count)

func apply_upgrade(upgrade_id: String) -> bool:
	"""Aplicar un upgrade del jugador"""
	if not PLAYER_UPGRADES.has(upgrade_id):
		push_error("[PlayerStats] Upgrade no encontrado: %s" % upgrade_id)
		return false
	
	var upgrade = PLAYER_UPGRADES[upgrade_id]
	add_stat(upgrade.stat, upgrade.amount)
	
	print("[PlayerStats] ✨ Upgrade aplicado: %s (%s)" % [upgrade.name, upgrade.description])
	return true

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar para guardado"""
	return {
		"stats": stats.duplicate(),
		"current_health": current_health,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level
	}

func from_dict(data: Dictionary) -> void:
	"""Restaurar desde datos guardados"""
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
	
	_sync_with_attack_manager()

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
		var base = stats[stat_name]
		var final = get_stat(stat_name)
		var temp = _get_temp_modifier_total(stat_name)
		
		if temp != 0:
			lines.append("  %s: %.2f (base: %.2f, temp: %+.2f)" % [stat_name, final, base, temp])
		else:
			lines.append("  %s: %.2f" % [stat_name, final])
	
	if not temp_modifiers.is_empty():
		lines.append("")
		lines.append("Buffs activos:")
		for stat_name in temp_modifiers:
			for mod in temp_modifiers[stat_name]:
				lines.append("  %s: %+.2f (%.1fs restantes) [%s]" % [
					stat_name, mod.amount, mod.duration, mod.source
				])
	
	return "\n".join(lines)
