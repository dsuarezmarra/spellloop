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
	"damage_mult": 1.0,           # +X% daño a todas las armas - SIN CAP
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
	"chain_count": 0,             # +X saltos de cadena
	
	# Críticos globales
	"crit_chance": 0.05,          # Probabilidad base de crítico (5%)
	"crit_damage": 2.0,           # Multiplicador de daño crítico (2x)
	
	# Efectos de combate
	"life_steal": 0.0,            # % del daño convertido en curación
}

# Límites de stats globales de armas (compartidos con PlayerStats donde aplique)
# Los stats aquí se aplican con clampf() en get_stat()
# NOTA: damage_mult NO tiene cap (puede crecer infinitamente)
const GLOBAL_STAT_LIMITS: Dictionary = {
	# Multiplicadores con límite
	"attack_speed_mult": {"min": 0.1, "max": 3.0}, # Max 300% vel ataque
	"projectile_speed_mult": {"min": 0.5, "max": 2.5},
	"area_mult": {"min": 0.5, "max": 3.0}, # Max 300% mult (antes 2.0 pero ignorado)
	"range_mult": {"min": 0.5, "max": 3.0},  
	"duration_mult": {"min": 0.5, "max": 3.0},
	"knockback_mult": {"min": 0.0, "max": 5.0},
	
	# Planos con límite (Bonos globales)
	"extra_projectiles": {"min": 0, "max": 5}, # Max +5 global
	"extra_pierce": {"min": 0, "max": 10},
	"chain_count": {"min": 0, "max": 8},
	
	# Límites Absolutos (Usados por WeaponStats.get_final_stat)
	"area": {"min": 0.1, "max": 4.0}, # Max Area absoluta 400%
	"projectile_count": {"min": 1, "max": 10}, # Max 10 proyectiles totales por arma
	"damage": {"min": 1, "max": 99999},
	
	# Probabilidades
	"crit_chance": {"min": 0.0, "max": 1.0},  # Máximo 100%
	
	# Efectos
	"life_steal": {"min": 0.0, "max": 0.3},   # Máximo 30%
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
	"""Obtener valor de un stat global (con caps aplicados)"""
	var default_val = BASE_GLOBAL_STATS.get(stat_name, 0.0)
	var val = stats.get(stat_name, default_val)
	var raw_value: float = float(val) if val != null else float(default_val)
	
	# Aplicar límites si existen
	if GLOBAL_STAT_LIMITS.has(stat_name):
		var limits = GLOBAL_STAT_LIMITS[stat_name]
		raw_value = clampf(raw_value, limits.min, limits.max)
	
	return raw_value

func get_raw_stat(stat_name: String) -> float:
	"""Obtener valor sin aplicar cap (para mostrar valor real acumulado)"""
	var default_val = BASE_GLOBAL_STATS.get(stat_name, 0.0)
	var val = stats.get(stat_name, default_val)
	return float(val) if val != null else float(default_val)

func is_stat_capped(stat_name: String) -> bool:
	"""Verificar si un stat global ha alcanzado su límite máximo"""
	if not GLOBAL_STAT_LIMITS.has(stat_name):
		return false  # Sin límite = nunca al cap
	
	var limits = GLOBAL_STAT_LIMITS[stat_name]
	var raw_value = get_raw_stat(stat_name)
	return raw_value >= limits.max - 0.001

func get_all_stats() -> Dictionary:
	"""Obtener todos los stats globales (con caps aplicados)"""
	var capped_stats = {}
	for stat_name in stats:
		capped_stats[stat_name] = get_stat(stat_name)
	return capped_stats

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
	"""
	Multiplicar un stat CORRECTAMENTE.
	
	Para evitar escalado exponencial descontrolado, usamos un sistema de 
	acumulación de bonos que luego se aplica como multiplicador final:
	- Base = 1.0
	- +10% daño → bonus = 0.10 → resultado = base + bonus = 1.10
	- +20% daño → bonus = 0.30 → resultado = base + bonus = 1.30
	- -10% daño (debuff) → multiplicar directamente el resultado
	
	Esto evita 1.1 * 1.2 = 1.32 exponencial, a favor de 1.0 + 0.1 + 0.2 = 1.30 lineal.
	Los debuffs (< 1.0) SÍ multiplican para que reduzcan correctamente.
	"""
	if stat_name not in stats:
		return
		
	var old_value = stats[stat_name]
	
	# Stats que usan acumulación aditiva de bonus (evita exponencial)
	const ADDITIVE_BONUS_STATS = [
		"damage_mult", "area_mult", "projectile_speed_mult", 
		"duration_mult", "knockback_mult", "attack_speed_mult", "range_mult"
	]
	
	var is_buff = value > 1.0
	var is_debuff = value < 1.0 and value > 0.0
	var uses_additive_bonus = stat_name in ADDITIVE_BONUS_STATS
	
	if uses_additive_bonus and is_buff:
		# BUFF: Acumular bonus aditivamente (1.1 → +0.1 bonus)
		var bonus = value - 1.0
		stats[stat_name] += bonus
	elif is_debuff:
		# DEBUFF: Multiplicar para reducir correctamente
		# Ejemplo: damage_mult = 1.3, aplicar 0.9 → 1.3 * 0.9 = 1.17
		stats[stat_name] *= value
	else:
		# Caso especial (value == 1.0, value <= 0, etc): multiplicar normal
		stats[stat_name] *= value
	
	# DEBUG: Solo en builds de desarrollo y con verbose enabled (opcional)
	if OS.is_debug_build() and stat_name == "damage_mult":
		# Solo loguear si hay un cambio significativo para reducir spam
		if abs(stats[stat_name] - old_value) > 0.001:
			var op_type = "ADDITIVE_STACK" if (uses_additive_bonus and is_buff) else "MULTIPLY"
			print("[GlobalWeaponStats] damage_mult: %.3f -> %.3f (%s, raw_val=%.3f)" % [
				old_value, stats[stat_name], op_type, value
			])
			
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
