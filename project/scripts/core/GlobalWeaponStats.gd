# GlobalWeaponStats.gd
# Sistema de mejoras globales que afectan a TODAS las armas
# Estas mejoras provienen del LevelUpPanel y objetos pasivos
#
# Cuando un arma calcula su stat final, multiplica por estos valores globales

extends Node
class_name GlobalWeaponStats

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal global_stat_changed(stat_name: String, old_value: float, new_value: float)
signal global_upgrade_applied(upgrade_id: String)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

# Stats globales base (multiplicadores = 1.0, planos = 0)
const BASE_GLOBAL_STATS: Dictionary = {
	# Multiplicadores (afectan a todas las armas)
	"damage_mult": 1.0,           # +X% daño a todas las armas
	"damage_flat": 0,             # +X daño plano a todas las armas
	"attack_speed_mult": 1.0,     # +X% velocidad de ataque global
	"projectile_speed_mult": 1.0, # +X% velocidad de proyectiles
	"area_mult": 1.0,             # +X% área de efecto
	"range_mult": 1.0,            # +X% alcance
	"duration_mult": 1.0,         # +X% duración de efectos
	"knockback_mult": 1.0,        # +X% empuje
	
	# Planos (se suman a todas las armas)
	"extra_projectiles": 0,       # +X proyectiles a todas las armas
	"extra_pierce": 0,            # +X penetración a todas las armas
	
	# Críticos globales
	"crit_chance": 0.05,          # Probabilidad base de crítico (5%)
	"crit_damage": 2.0,           # Multiplicador de daño crítico (2x)
}

# Metadatos para UI
const GLOBAL_STAT_METADATA: Dictionary = {
	"damage_mult": {
		"name": "Daño Global",
		"icon": "⚔️",
		"description": "Multiplicador de daño para todas las armas.",
		"format": "percent",
		"color": Color(1.0, 0.5, 0.2)
	},
	"damage_flat": {
		"name": "Daño Plano Global",
		"icon": "➕",
		"description": "Daño adicional para todas las armas.",
		"format": "flat",
		"color": Color(1.0, 0.6, 0.3)
	},
	"attack_speed_mult": {
		"name": "Vel. Ataque Global",
		"icon": "⚡",
		"description": "Multiplicador de velocidad de ataque para todas las armas.",
		"format": "percent",
		"color": Color(0.3, 0.8, 1.0)
	},
	"projectile_speed_mult": {
		"name": "Vel. Proyectil Global",
		"icon": "➡️",
		"description": "Multiplicador de velocidad de proyectiles.",
		"format": "percent",
		"color": Color(0.5, 0.9, 0.6)
	},
	"area_mult": {
		"name": "Área Global",
		"icon": "🌀",
		"description": "Multiplicador de área de efecto.",
		"format": "percent",
		"color": Color(0.8, 0.4, 1.0)
	},
	"range_mult": {
		"name": "Alcance Global",
		"icon": "🎯",
		"description": "Multiplicador de alcance.",
		"format": "percent",
		"color": Color(0.6, 0.8, 0.4)
	},
	"duration_mult": {
		"name": "Duración Global",
		"icon": "⌛",
		"description": "Multiplicador de duración de efectos.",
		"format": "percent",
		"color": Color(0.9, 0.8, 0.3)
	},
	"knockback_mult": {
		"name": "Empuje Global",
		"icon": "💥",
		"description": "Multiplicador de fuerza de empuje.",
		"format": "percent",
		"color": Color(0.9, 0.5, 0.3)
	},
	"extra_projectiles": {
		"name": "Proyectiles Extra",
		"icon": "🎯",
		"description": "Proyectiles adicionales para todas las armas.",
		"format": "flat",
		"color": Color(1.0, 0.6, 0.8)
	},
	"extra_pierce": {
		"name": "Penetración Extra",
		"icon": "🔱",
		"description": "Penetración adicional para todas las armas.",
		"format": "flat",
		"color": Color(0.9, 0.7, 0.4)
	},
	"crit_chance": {
		"name": "Prob. Crítico",
		"icon": "🎯",
		"description": "Probabilidad de golpe crítico.",
		"format": "percent_raw",
		"color": Color(1.0, 0.9, 0.2)
	},
	"crit_damage": {
		"name": "Daño Crítico",
		"icon": "💢",
		"description": "Multiplicador de daño en críticos.",
		"format": "multiplier",
		"color": Color(1.0, 0.7, 0.1)
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Stats globales actuales
var stats: Dictionary = {}

# Historial de mejoras globales aplicadas
var applied_upgrades: Array = []  # [{id, name, effects}]

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	reset()

func reset() -> void:
	"""Resetear a valores base"""
	stats = BASE_GLOBAL_STATS.duplicate()
	applied_upgrades.clear()

func _ready() -> void:
	add_to_group("global_weapon_stats")

# ═══════════════════════════════════════════════════════════════════════════════
# GETTERS
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat(stat_name: String) -> float:
	"""Obtener valor de un stat global"""
	return stats.get(stat_name, BASE_GLOBAL_STATS.get(stat_name, 0.0))

func get_all_stats() -> Dictionary:
	"""Obtener todos los stats globales (para pasar a WeaponStats)"""
	return stats.duplicate()

func get_crit_chance() -> float:
	"""Obtener probabilidad de crítico"""
	return clampf(stats.get("crit_chance", 0.05), 0.0, 1.0)

func get_crit_damage() -> float:
	"""Obtener multiplicador de crítico"""
	return maxf(stats.get("crit_damage", 2.0), 1.0)

# ═══════════════════════════════════════════════════════════════════════════════
# SETTERS / MODIFICADORES
# ═══════════════════════════════════════════════════════════════════════════════

func add_stat(stat_name: String, value: float) -> void:
	"""Añadir valor a un stat (para stats planos)"""
	if stat_name in stats:
		var old_value = stats[stat_name]
		stats[stat_name] += value
		global_stat_changed.emit(stat_name, old_value, stats[stat_name])

func multiply_stat(stat_name: String, value: float) -> void:
	"""Multiplicar un stat (para multiplicadores)"""
	if stat_name in stats:
		var old_value = stats[stat_name]
		stats[stat_name] *= value
		global_stat_changed.emit(stat_name, old_value, stats[stat_name])

func set_stat(stat_name: String, value: float) -> void:
	"""Establecer valor directo de un stat"""
	if stat_name in stats:
		var old_value = stats[stat_name]
		stats[stat_name] = value
		global_stat_changed.emit(stat_name, old_value, stats[stat_name])

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS GLOBALES
# ═══════════════════════════════════════════════════════════════════════════════

func apply_upgrade(upgrade: Dictionary) -> bool:
	"""
	Aplicar una mejora global a todas las armas.
	upgrade = {id, name, effects: [{stat, value, operation}]}
	"""
	if not upgrade.has("effects"):
		return false
	
	for effect in upgrade.effects:
		var stat = effect.get("stat", "")
		var value = effect.get("value", 0)
		var operation = effect.get("operation", "add")
		
		# Convertir cooldown_mult → attack_speed_mult
		# cooldown_mult 0.90 (10% menos cooldown) = attack_speed_mult 1/0.90 = 1.11
		if stat == "cooldown_mult":
			stat = "attack_speed_mult"
			if operation == "multiply" and value > 0:
				value = 1.0 / value  # Invertir: menos cooldown = más velocidad
		
		if stat in stats:
			match operation:
				"add":
					add_stat(stat, value)
				"multiply":
					multiply_stat(stat, value)
				"set":
					set_stat(stat, value)
	
	applied_upgrades.append(upgrade.duplicate(true))
	global_upgrade_applied.emit(upgrade.get("id", "unknown"))
	
	# Debug desactivado: print("[GlobalWeaponStats] Mejora global aplicada")
	return true

func get_upgrades() -> Array:
	"""Obtener lista de mejoras globales aplicadas"""
	return applied_upgrades.duplicate()

func get_upgrade_count() -> int:
	"""Obtener número de mejoras globales"""
	return applied_upgrades.size()

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar para guardado"""
	return {
		"stats": stats.duplicate(),
		"applied_upgrades": applied_upgrades.duplicate(true)
	}

func from_dict(data: Dictionary) -> void:
	"""Restaurar desde datos guardados"""
	stats = data.get("stats", BASE_GLOBAL_STATS.duplicate())
	applied_upgrades = data.get("applied_upgrades", [])

# ═══════════════════════════════════════════════════════════════════════════════
# UI / FORMATEO
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat_display(stat_name: String) -> Dictionary:
	"""Obtener información formateada de un stat para UI"""
	var meta = GLOBAL_STAT_METADATA.get(stat_name, {})
	var value = get_stat(stat_name)
	var base_value = BASE_GLOBAL_STATS.get(stat_name, 0.0)
	
	return {
		"name": meta.get("name", stat_name),
		"icon": meta.get("icon", "❓"),
		"value": value,
		"base": base_value,
		"format": meta.get("format", "flat"),
		"color": meta.get("color", Color.WHITE),
		"has_bonus": value != base_value
	}

func format_stat_value(stat_name: String, value: float) -> String:
	"""Formatear valor de stat para mostrar"""
	var meta = GLOBAL_STAT_METADATA.get(stat_name, {})
	var format_type = meta.get("format", "flat")
	
	match format_type:
		"flat":
			return str(int(value))
		"percent":
			# Para multiplicadores: 1.2 -> +20%
			return "%+.0f%%" % ((value - 1.0) * 100)
		"percent_raw":
			# Para probabilidades: 0.15 -> 15%
			return "%.0f%%" % (value * 100)
		"multiplier":
			return "x%.2f" % value
		_:
			return str(value)

func get_display_stats() -> Array:
	"""Obtener lista de stats para mostrar en UI (solo los modificados)"""
	var display_stats = []
	
	for stat_name in stats:
		var value = stats[stat_name]
		var base_value = BASE_GLOBAL_STATS.get(stat_name, 0.0)
		
		# Solo mostrar si hay cambio respecto a base
		if value != base_value or stat_name in ["crit_chance", "crit_damage"]:
			display_stats.append(get_stat_display(stat_name))
	
	return display_stats

func get_debug_info() -> String:
	"""Obtener información de debug"""
	var lines = ["=== GLOBAL WEAPON STATS ==="]
	lines.append("Mejoras aplicadas: %d" % applied_upgrades.size())
	lines.append("")
	
	for stat_name in stats:
		var value = stats[stat_name]
		var base = BASE_GLOBAL_STATS.get(stat_name, 0.0)
		var formatted = format_stat_value(stat_name, value)
		
		if value != base:
			lines.append("  %s: %s (base: %s)" % [stat_name, formatted, format_stat_value(stat_name, base)])
		else:
			lines.append("  %s: %s" % [stat_name, formatted])
	
	return "\n".join(lines)
