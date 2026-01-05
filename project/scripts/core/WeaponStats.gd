# WeaponStats.gd
# Sistema de estadísticas individuales por arma
# Cada arma tiene sus propios stats que se pueden mejorar individualmente
#
# Los stats finales de un arma son:
# stat_final = (stat_base + bonus_plano) * (1 + bonus_porcentaje) * multiplicador_global

extends RefCounted
class_name WeaponStats

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal stats_changed(weapon_id: String)
signal upgrade_applied(weapon_id: String, upgrade_id: String)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES - STATS DE ARMAS
# ═══════════════════════════════════════════════════════════════════════════════

# Metadatos de stats de armas para UI
const WEAPON_STAT_METADATA: Dictionary = {
	"damage": {
		"name": "Daño",
		"name_short": "DMG",
		"icon": "⚔️",
		"description": "Daño base del arma por impacto.",
		"format": "flat",
		"color": Color(1.0, 0.4, 0.3)
	},
	"damage_flat": {
		"name": "Daño Plano",
		"name_short": "+DMG",
		"icon": "➕",
		"description": "Daño adicional plano que se suma al base.",
		"format": "flat",
		"color": Color(1.0, 0.5, 0.4)
	},
	"damage_mult": {
		"name": "Daño %",
		"name_short": "DMG%",
		"icon": "📈",
		"description": "Multiplicador porcentual de daño.",
		"format": "percent",
		"color": Color(1.0, 0.6, 0.2)
	},
	"attack_speed": {
		"name": "Vel. Ataque",
		"name_short": "VEL",
		"icon": "⚡",
		"description": "Ataques por segundo. Mayor = más rápido.",
		"format": "attacks_per_second",
		"color": Color(0.3, 0.8, 1.0)
	},
	"attack_speed_mult": {
		"name": "Vel. Ataque %",
		"name_short": "VEL%",
		"icon": "⚡",
		"description": "Multiplicador de velocidad de ataque.",
		"format": "percent",
		"color": Color(0.4, 0.9, 1.0)
	},
	"projectile_speed": {
		"name": "Vel. Proyectil",
		"name_short": "PROY",
		"icon": "➡️",
		"description": "Velocidad de los proyectiles.",
		"format": "flat",
		"color": Color(0.4, 0.9, 0.6)
	},
	"projectile_speed_mult": {
		"name": "Vel. Proyectil %",
		"name_short": "PROY%",
		"icon": "➡️",
		"description": "Multiplicador de velocidad de proyectiles.",
		"format": "percent",
		"color": Color(0.5, 1.0, 0.7)
	},
	"area": {
		"name": "Área",
		"name_short": "AREA",
		"icon": "🌀",
		"description": "Tamaño del área de efecto.",
		"format": "multiplier",
		"color": Color(0.8, 0.4, 1.0)
	},
	"area_mult": {
		"name": "Área %",
		"name_short": "AREA%",
		"icon": "🌀",
		"description": "Multiplicador de área de efecto.",
		"format": "percent",
		"color": Color(0.9, 0.5, 1.0)
	},
	"range": {
		"name": "Alcance",
		"name_short": "RNG",
		"icon": "🎯",
		"description": "Distancia máxima de ataque.",
		"format": "flat",
		"color": Color(0.6, 0.8, 0.4)
	},
	"range_mult": {
		"name": "Alcance %",
		"name_short": "RNG%",
		"icon": "🎯",
		"description": "Multiplicador de alcance.",
		"format": "percent",
		"color": Color(0.7, 0.9, 0.5)
	},
	"projectile_count": {
		"name": "Proyectiles",
		"name_short": "PROY#",
		"icon": "🎯",
		"description": "Número de proyectiles por disparo.",
		"format": "flat",
		"color": Color(1.0, 0.6, 0.8)
	},
	"extra_projectiles": {
		"name": "Proyectiles Extra",
		"name_short": "+PROY",
		"icon": "➕",
		"description": "Proyectiles adicionales por disparo.",
		"format": "flat",
		"color": Color(1.0, 0.7, 0.9)
	},
	"pierce": {
		"name": "Penetración",
		"name_short": "PIERC",
		"icon": "🔱",
		"description": "Enemigos que atraviesa el proyectil.",
		"format": "flat",
		"color": Color(0.9, 0.7, 0.4)
	},
	"extra_pierce": {
		"name": "Penetración Extra",
		"name_short": "+PIERC",
		"icon": "➕",
		"description": "Penetración adicional.",
		"format": "flat",
		"color": Color(1.0, 0.8, 0.5)
	},
	"duration": {
		"name": "Duración",
		"name_short": "DUR",
		"icon": "⌛",
		"description": "Duración de efectos del arma.",
		"format": "seconds",
		"color": Color(0.9, 0.8, 0.3)
	},
	"duration_mult": {
		"name": "Duración %",
		"name_short": "DUR%",
		"icon": "⌛",
		"description": "Multiplicador de duración.",
		"format": "percent",
		"color": Color(1.0, 0.9, 0.4)
	},
	"knockback": {
		"name": "Empuje",
		"name_short": "KB",
		"icon": "💥",
		"description": "Fuerza de empuje al impactar.",
		"format": "flat",
		"color": Color(0.9, 0.5, 0.3)
	},
	"knockback_mult": {
		"name": "Empuje %",
		"name_short": "KB%",
		"icon": "💥",
		"description": "Multiplicador de empuje.",
		"format": "percent",
		"color": Color(1.0, 0.6, 0.4)
	},
	"crit_chance": {
		"name": "Prob. Crítico",
		"name_short": "CRIT%",
		"icon": "🎯",
		"description": "Probabilidad de golpe crítico.",
		"format": "percent",
		"color": Color(1.0, 0.9, 0.2)
	},
	"crit_damage": {
		"name": "Daño Crítico",
		"name_short": "CRITD",
		"icon": "💢",
		"description": "Multiplicador de daño en críticos.",
		"format": "multiplier",
		"color": Color(1.0, 0.7, 0.1)
	},
	"effect_value": {
		"name": "Efecto",
		"name_short": "EFF",
		"icon": "✨",
		"description": "Potencia del efecto especial.",
		"format": "flat",
		"color": Color(0.7, 0.5, 1.0)
	},
	"effect_duration": {
		"name": "Duración Efecto",
		"name_short": "EFF.D",
		"icon": "⏱️",
		"description": "Duración del efecto especial.",
		"format": "seconds",
		"color": Color(0.8, 0.6, 1.0)
	}
}

# Stats base que todas las armas tienen
const BASE_WEAPON_STATS: Dictionary = {
	"damage": 10,
	"damage_flat": 0,
	"damage_mult": 1.0,
	"attack_speed": 1.0,        # Ataques por segundo (1/cooldown)
	"attack_speed_mult": 1.0,
	"projectile_speed": 300.0,
	"projectile_speed_mult": 1.0,
	"area": 1.0,
	"area_mult": 1.0,
	"range": 300.0,
	"range_mult": 1.0,
	"projectile_count": 1,
	"extra_projectiles": 0,
	"pierce": 0,
	"extra_pierce": 0,
	"duration": 0.0,
	"duration_mult": 1.0,
	"knockback": 50.0,
	"knockback_mult": 1.0,
	"crit_chance": 0.0,         # Crítico específico del arma (se suma al global)
	"crit_damage": 0.0,         # Bonus al multiplicador de crítico
	"effect_value": 0.0,
	"effect_duration": 0.0
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# ID del arma
var weapon_id: String = ""

# Stats base del arma (desde WeaponDatabase)
var base_stats: Dictionary = {}

# Mejoras específicas aplicadas a esta arma
# Formato: [{id, name, effects: [{stat, value, operation}]}]
var applied_upgrades: Array = []

# Stats modificados (base + mejoras específicas, SIN globales)
var modified_stats: Dictionary = {}

# Es un arma fusionada?
var is_fused: bool = false

# Si es fusión, qué armas la componen
var fused_from: Array = []  # [weapon_id_1, weapon_id_2]

# Multiplicador de fusión (por defecto 2x)
var fusion_multiplier: float = 2.0

# Nivel del arma (para mejoras de nivel)
var weapon_level: int = 1

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _init(p_weapon_id: String = "", p_base_stats: Dictionary = {}) -> void:
	weapon_id = p_weapon_id
	if p_base_stats.is_empty():
		base_stats = BASE_WEAPON_STATS.duplicate()
	else:
		# Empezar con stats por defecto y sobrescribir con los proporcionados
		base_stats = BASE_WEAPON_STATS.duplicate()
		for key in p_base_stats:
			if key in base_stats:
				base_stats[key] = p_base_stats[key]
			# Convertir cooldown a attack_speed
			if key == "cooldown" and p_base_stats[key] > 0:
				base_stats["attack_speed"] = 1.0 / p_base_stats[key]
	
	_recalculate_stats()

static func from_weapon_data(weapon_data: Dictionary) -> WeaponStats:
	"""Crear WeaponStats desde datos de WeaponDatabase"""
	var stats = WeaponStats.new()
	stats.weapon_id = weapon_data.get("id", "unknown")
	
	# Mapear datos del arma a stats
	stats.base_stats = BASE_WEAPON_STATS.duplicate()
	stats.base_stats["damage"] = weapon_data.get("damage", 10)
	
	# Convertir cooldown a attack_speed
	var cooldown = weapon_data.get("cooldown", 1.0)
	stats.base_stats["attack_speed"] = 1.0 / cooldown if cooldown > 0 else 1.0
	
	stats.base_stats["projectile_speed"] = weapon_data.get("projectile_speed", 300.0)
	stats.base_stats["area"] = weapon_data.get("area", 1.0)
	stats.base_stats["range"] = weapon_data.get("range", 300.0)
	stats.base_stats["projectile_count"] = weapon_data.get("projectile_count", 1)
	stats.base_stats["pierce"] = weapon_data.get("pierce", 0)
	stats.base_stats["duration"] = weapon_data.get("duration", 0.0)
	stats.base_stats["knockback"] = weapon_data.get("knockback", 50.0)
	stats.base_stats["effect_value"] = weapon_data.get("effect_value", 0.0)
	stats.base_stats["effect_duration"] = weapon_data.get("effect_duration", 0.0)
	
	stats._recalculate_stats()
	return stats

# ═══════════════════════════════════════════════════════════════════════════════
# CÁLCULO DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

func _recalculate_stats() -> void:
	"""Recalcular stats modificados (base + mejoras específicas)"""
	modified_stats = base_stats.duplicate()
	
	# Aplicar mejoras específicas del arma
	for upgrade in applied_upgrades:
		for effect in upgrade.get("effects", []):
			var stat = effect.get("stat", "")
			var value = effect.get("value", 0)
			var operation = effect.get("operation", "add")
			
			if stat in modified_stats:
				match operation:
					"add":
						modified_stats[stat] += value
					"multiply":
						modified_stats[stat] *= value
					"set":
						modified_stats[stat] = value
	
	# Si es fusión, aplicar multiplicador
	if is_fused:
		_apply_fusion_multiplier()
	
	emit_signal("stats_changed", weapon_id)

func _apply_fusion_multiplier() -> void:
	"""Aplicar multiplicador de fusión a stats relevantes"""
	# Stats que se multiplican en fusión
	var fusion_stats = ["damage", "damage_flat", "projectile_count", "pierce", "knockback"]
	
	for stat in fusion_stats:
		if stat in modified_stats:
			modified_stats[stat] = int(modified_stats[stat] * fusion_multiplier)
	
	# Attack speed también mejora pero menos (1.5x en lugar de 2x)
	modified_stats["attack_speed_mult"] *= 1.5

func get_final_stat(stat_name: String, global_stats: Dictionary = {}) -> float:
	"""
	Obtener stat final incluyendo mejoras globales.
	global_stats viene de GlobalWeaponStats
	
	Fórmula: (base + flat) * (1 + bonus%) * mult_global
	"""
	var base_value = modified_stats.get(stat_name, 0.0)
	
	# Stat plano adicional (ej: damage_flat)
	var flat_stat = stat_name + "_flat"
	var flat_bonus = modified_stats.get(flat_stat, 0.0)
	flat_bonus += global_stats.get(flat_stat, 0.0)
	
	# Multiplicador porcentual (ej: damage_mult)
	var mult_stat = stat_name + "_mult"
	var local_mult = modified_stats.get(mult_stat, 1.0)
	var global_mult = global_stats.get(mult_stat, 1.0)
	
	# Calcular final
	var final_value = (base_value + flat_bonus) * local_mult * global_mult
	
	return final_value

func get_final_damage(global_stats: Dictionary = {}) -> int:
	"""Calcular daño final con mejoras globales"""
	return int(get_final_stat("damage", global_stats))

func get_final_attack_speed(global_stats: Dictionary = {}) -> float:
	"""
	Calcular velocidad de ataque final (ataques por segundo).
	Ejemplo: base 1.0 + 50% = 1.5 ataques/segundo
	"""
	var base_speed = modified_stats.get("attack_speed", 1.0)
	var local_mult = modified_stats.get("attack_speed_mult", 1.0)
	var global_mult = global_stats.get("attack_speed_mult", 1.0)
	
	return base_speed * local_mult * global_mult

func get_final_cooldown(global_stats: Dictionary = {}) -> float:
	"""
	Obtener cooldown real (inverso de attack_speed).
	Para uso interno del sistema de disparo.
	"""
	var attack_speed = get_final_attack_speed(global_stats)
	if attack_speed <= 0:
		return 999.0
	return 1.0 / attack_speed

func get_final_projectile_count(global_stats: Dictionary = {}) -> int:
	"""Calcular proyectiles totales"""
	var base = modified_stats.get("projectile_count", 1)
	var extra_local = modified_stats.get("extra_projectiles", 0)
	var extra_global = global_stats.get("extra_projectiles", 0)
	return base + extra_local + extra_global

func get_final_pierce(global_stats: Dictionary = {}) -> int:
	"""Calcular penetración total"""
	var base = modified_stats.get("pierce", 0)
	var extra_local = modified_stats.get("extra_pierce", 0)
	var extra_global = global_stats.get("extra_pierce", 0)
	return base + extra_local + extra_global

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS
# ═══════════════════════════════════════════════════════════════════════════════

func apply_upgrade(upgrade: Dictionary) -> bool:
	"""
	Aplicar una mejora específica a esta arma.
	upgrade = {id, name, effects: [{stat, value, operation}]}
	"""
	if not upgrade.has("effects"):
		return false
	
	applied_upgrades.append(upgrade.duplicate(true))
	_recalculate_stats()
	
	emit_signal("upgrade_applied", weapon_id, upgrade.get("id", "unknown"))
	print("[WeaponStats] Mejora '%s' aplicada a %s" % [upgrade.get("name", "?"), weapon_id])
	return true

func remove_upgrade(upgrade_id: String) -> bool:
	"""Remover una mejora por ID"""
	for i in range(applied_upgrades.size() - 1, -1, -1):
		if applied_upgrades[i].get("id") == upgrade_id:
			applied_upgrades.remove_at(i)
			_recalculate_stats()
			return true
	return false

func get_upgrades() -> Array:
	"""Obtener lista de mejoras aplicadas"""
	return applied_upgrades.duplicate()

func get_upgrade_count() -> int:
	"""Obtener número de mejoras aplicadas"""
	return applied_upgrades.size()

# ═══════════════════════════════════════════════════════════════════════════════
# FUSIÓN
# ═══════════════════════════════════════════════════════════════════════════════

static func create_fusion(weapon1: WeaponStats, weapon2: WeaponStats, fusion_data: Dictionary) -> WeaponStats:
	"""
	Crear un arma fusionada a partir de dos armas base.
	Combina stats y mejoras de ambas armas con multiplicador.
	"""
	var fused = WeaponStats.new()
	fused.weapon_id = fusion_data.get("id", "fused_weapon")
	fused.is_fused = true
	fused.fused_from = [weapon1.weapon_id, weapon2.weapon_id]
	fused.fusion_multiplier = fusion_data.get("fusion_multiplier", 2.0)
	
	# Usar stats base de la fusión
	fused.base_stats = BASE_WEAPON_STATS.duplicate()
	for key in fusion_data:
		if key in fused.base_stats:
			fused.base_stats[key] = fusion_data[key]
		if key == "cooldown" and fusion_data[key] > 0:
			fused.base_stats["attack_speed"] = 1.0 / fusion_data[key]
	
	# Combinar mejoras de ambas armas
	for upgrade in weapon1.applied_upgrades:
		fused.applied_upgrades.append(upgrade.duplicate(true))
	for upgrade in weapon2.applied_upgrades:
		fused.applied_upgrades.append(upgrade.duplicate(true))
	
	fused._recalculate_stats()
	
	print("[WeaponStats] Fusión creada: %s (de %s + %s) con multiplicador %.1fx" % [
		fused.weapon_id, weapon1.weapon_id, weapon2.weapon_id, fused.fusion_multiplier
	])
	
	return fused

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar para guardado"""
	return {
		"weapon_id": weapon_id,
		"base_stats": base_stats.duplicate(),
		"applied_upgrades": applied_upgrades.duplicate(true),
		"is_fused": is_fused,
		"fused_from": fused_from.duplicate(),
		"fusion_multiplier": fusion_multiplier,
		"weapon_level": weapon_level
	}

static func from_dict(data: Dictionary) -> WeaponStats:
	"""Restaurar desde datos guardados"""
	var stats = WeaponStats.new()
	stats.weapon_id = data.get("weapon_id", "")
	stats.base_stats = data.get("base_stats", BASE_WEAPON_STATS.duplicate())
	stats.applied_upgrades = data.get("applied_upgrades", [])
	stats.is_fused = data.get("is_fused", false)
	stats.fused_from = data.get("fused_from", [])
	stats.fusion_multiplier = data.get("fusion_multiplier", 2.0)
	stats.weapon_level = data.get("weapon_level", 1)
	stats._recalculate_stats()
	return stats

# ═══════════════════════════════════════════════════════════════════════════════
# UI / DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat_display(stat_name: String, global_stats: Dictionary = {}) -> Dictionary:
	"""Obtener información formateada de un stat para UI"""
	var meta = WEAPON_STAT_METADATA.get(stat_name, {})
	var base_value = base_stats.get(stat_name, 0.0)
	var modified_value = modified_stats.get(stat_name, base_value)
	var final_value = get_final_stat(stat_name, global_stats)
	
	return {
		"name": meta.get("name", stat_name),
		"icon": meta.get("icon", "❓"),
		"base": base_value,
		"modified": modified_value,
		"final": final_value,
		"format": meta.get("format", "flat"),
		"color": meta.get("color", Color.WHITE),
		"has_bonus": final_value != base_value
	}

func format_stat_value(stat_name: String, value: float) -> String:
	"""Formatear valor de stat para mostrar"""
	var meta = WEAPON_STAT_METADATA.get(stat_name, {})
	var format_type = meta.get("format", "flat")
	
	match format_type:
		"flat":
			return str(int(value))
		"percent":
			return "%+.0f%%" % ((value - 1.0) * 100) if value != 1.0 else "0%"
		"multiplier":
			return "x%.2f" % value
		"attacks_per_second":
			return "%.2f/s" % value
		"seconds":
			return "%.1fs" % value
		_:
			return str(value)

func get_debug_info() -> String:
	"""Obtener información de debug"""
	var lines = ["=== %s ===" % weapon_id]
	lines.append("Fusionada: %s" % ("Sí" if is_fused else "No"))
	lines.append("Mejoras: %d" % applied_upgrades.size())
	lines.append("")
	lines.append("Stats base → modificados:")
	
	for stat in base_stats:
		var base_val = base_stats[stat]
		var mod_val = modified_stats.get(stat, base_val)
		if base_val != mod_val:
			lines.append("  %s: %.2f → %.2f" % [stat, base_val, mod_val])
		else:
			lines.append("  %s: %.2f" % [stat, base_val])
	
	return "\n".join(lines)
