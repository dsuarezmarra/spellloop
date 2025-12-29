# WeaponFusionManager.gd
# Gestiona el sistema de fusión de armas
# 
# MECÁNICA DE FUSIÓN:
# - Combinar 2 armas = 1 arma fusionada más poderosa
# - Al fusionar, el jugador PIERDE 1 slot de arma permanentemente
# - Ejemplo: 6 armas base → máximo 3 armas fusionadas (3 slots ocupados permanentemente)
#
# SINERGIAS:
# - Cada fusión combina los elementos y efectos de ambas armas
# - Genera mecánicas únicas (Steam = Ice+Fire = slow + DoT)
# - Efectos visuales combinados

extends Node
class_name WeaponFusionManager

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal fusion_available(weapon_a: BaseWeapon, weapon_b: BaseWeapon, result: Dictionary)
signal fusion_completed(fused_weapon: BaseWeapon, lost_slot: bool)
signal fusion_failed(reason: String)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const MIN_LEVEL_TO_FUSE: int = 1  # Nivel mínimo de cada arma para fusionar
const STARTING_MAX_SLOTS: int = 6

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Número de slots perdidos por fusiones (empieza en 0)
var slots_lost: int = 0

# Historial de fusiones realizadas
var fusion_history: Array = []

# ═══════════════════════════════════════════════════════════════════════════════
# PROPIEDADES CALCULADAS
# ═══════════════════════════════════════════════════════════════════════════════

var current_max_slots: int:
	get:
		return STARTING_MAX_SLOTS - slots_lost

# ═══════════════════════════════════════════════════════════════════════════════
# VERIFICACIÓN DE FUSIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func can_fuse_weapons(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> Dictionary:
	"""
	Verificar si dos armas pueden fusionarse
	Retorna: {can_fuse: bool, reason: String, result: Dictionary}
	"""
	# Verificar que ambas armas existen
	if weapon_a == null or weapon_b == null:
		return {
			"can_fuse": false,
			"reason": "Una o ambas armas no existen",
			"result": {}
		}
	
	# Verificar que no son la misma arma
	if weapon_a.id == weapon_b.id:
		return {
			"can_fuse": false,
			"reason": "No puedes fusionar un arma consigo misma",
			"result": {}
		}
	
	# Verificar que no son armas ya fusionadas
	if weapon_a.is_fused or weapon_b.is_fused:
		return {
			"can_fuse": false,
			"reason": "No puedes fusionar armas que ya están fusionadas",
			"result": {}
		}
	
	# Verificar nivel mínimo
	if weapon_a.level < MIN_LEVEL_TO_FUSE or weapon_b.level < MIN_LEVEL_TO_FUSE:
		return {
			"can_fuse": false,
			"reason": "Ambas armas deben ser nivel %d o superior" % MIN_LEVEL_TO_FUSE,
			"result": {}
		}
	
	# Verificar si existe una fusión para estas armas
	var fusion_result = WeaponDatabase.get_fusion_result(weapon_a.id, weapon_b.id)
	if fusion_result.is_empty():
		return {
			"can_fuse": false,
			"reason": "Estas armas no pueden fusionarse",
			"result": {}
		}
	
	return {
		"can_fuse": true,
		"reason": "Fusión disponible",
		"result": fusion_result
	}

func get_available_fusions(weapons: Array) -> Array:
	"""
	Obtener todas las fusiones disponibles para un conjunto de armas
	Retorna array de {weapon_a, weapon_b, result}
	"""
	var available = []
	
	for i in range(weapons.size()):
		for j in range(i + 1, weapons.size()):
			var check = can_fuse_weapons(weapons[i], weapons[j])
			if check.can_fuse:
				available.append({
					"weapon_a": weapons[i],
					"weapon_b": weapons[j],
					"result": check.result
				})
	
	return available

# ═══════════════════════════════════════════════════════════════════════════════
# EJECUCIÓN DE FUSIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func fuse_weapons(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> BaseWeapon:
	"""
	Fusionar dos armas en una nueva
	IMPORTANTE: Esto NO modifica el array de armas del jugador
	El sistema de slots debe manejarse externamente
	
	Retorna: El arma fusionada, o null si falló
	"""
	# Verificar que la fusión es válida
	var check = can_fuse_weapons(weapon_a, weapon_b)
	if not check.can_fuse:
		fusion_failed.emit(check.reason)
		push_error("[WeaponFusionManager] Fusión fallida: %s" % check.reason)
		return null
	
	# Crear el arma fusionada
	var fused_weapon = _create_fused_weapon(weapon_a, weapon_b, check.result)
	if fused_weapon == null:
		fusion_failed.emit("Error al crear el arma fusionada")
		return null
	
	# Calcular nivel inicial del arma fusionada
	# Hereda parte del nivel de las armas componentes
	var inherited_levels = int((weapon_a.level + weapon_b.level) / 3.0)
	for i in range(inherited_levels):
		fused_weapon.level_up()
	
	# Registrar en historial
	fusion_history.append({
		"weapon_a_id": weapon_a.id,
		"weapon_b_id": weapon_b.id,
		"result_id": fused_weapon.id,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Incrementar slots perdidos
	slots_lost += 1
	
	print("[WeaponFusionManager] ¡Fusión exitosa! %s + %s = %s" % [
		weapon_a.weapon_name, weapon_b.weapon_name, fused_weapon.weapon_name
	])
	print("[WeaponFusionManager] Slots actuales: %d/%d" % [current_max_slots, STARTING_MAX_SLOTS])
	
	fusion_completed.emit(fused_weapon, true)
	
	return fused_weapon

func _create_fused_weapon(weapon_a: BaseWeapon, weapon_b: BaseWeapon, fusion_data: Dictionary) -> BaseWeapon:
	"""Crear el arma fusionada con los datos combinados"""
	var fused = BaseWeapon.new(fusion_data.id, true)  # from_fusion = true
	
	if fused.id.is_empty():
		push_error("[WeaponFusionManager] Error al crear arma fusionada: %s" % fusion_data.id)
		return null
	
	# Guardar componentes originales
	fused.fusion_components = [weapon_a.id, weapon_b.id]
	
	return fused

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE SINERGIAS
# ═══════════════════════════════════════════════════════════════════════════════

func get_synergy_description(fusion_result: Dictionary) -> String:
	"""Obtener descripción de la sinergia de una fusión"""
	var synergy_descriptions = {
		"steam_cannon": "❄️+🔥 → 💨\nEl vapor congela y quema simultáneamente\n• Enemigos ralentizados reciben daño continuo\n• Explosiones de área ampliadas",
		
		"storm_caller": "⚡+🌪️ → ⛈️\nLa tormenta perfecta\n• Rayos que saltan entre enemigos\n• Mayor área de efecto\n• Empuja enemigos con viento",
		
		"soul_reaper": "🗡️+🌿 → 💀\nCosecha las almas enemigas\n• Dagas que persiguen objetivos\n• Roba vida al eliminar enemigos\n• Atraviesa múltiples objetivos",
		
		"cosmic_barrier": "💜+✨ → 🌟\nBarrera de luz cósmica\n• Orbes brillantes que orbitan\n• Mayor probabilidad de crítico\n• Protección pasiva mejorada",
		
		"earthquake": "🪨+🕳️ → 🌋\nDestrucción total del terreno\n• Área masiva de daño\n• Atrae y aturde enemigos\n• El suelo tiembla continuamente",
		
		"frostfire": "❄️+🌿 → 🥶\nHielo viviente que congela todo\n• Proyectiles que persiguen\n• Congelación casi total\n• Se propaga entre enemigos cercanos",
		
		"hellfire": "🔥+🗡️ → 👹\nLlamas del infierno\n• Dagas de fuego oscuro\n• Quemadura intensificada\n• Atraviesa y quema todo",
		
		"thunder_spear": "⚡+✨ → 🔱\nLanza divina del trueno\n• Rayo instantáneo devastador\n• Crítico casi garantizado\n• Máximo rango y penetración",
		
		"void_storm": "🕳️+🌪️ → 🌀\nVortex del vacío infinito\n• Tornado que succiona enemigos\n• Daño continuo en área\n• Imposible de escapar",
		
		"crystal_guardian": "🪨+💜 → 💎\nCristales arcanos protectores\n• Cristales que orbitan\n• Explosiones al contacto\n• Aturden brevemente"
	}
	
	var fusion_id = fusion_result.get("id", "")
	return synergy_descriptions.get(fusion_id, fusion_result.get("description", "Sinergia desconocida"))

func get_synergy_effects(fused_weapon_id: String) -> Array:
	"""Obtener efectos especiales de sinergia para un arma fusionada"""
	var effects = {
		"steam_cannon": ["slow", "burn", "area_bonus"],
		"storm_caller": ["chain", "knockback_bonus", "multi_target"],
		"soul_reaper": ["lifesteal", "pierce_bonus", "homing"],
		"cosmic_barrier": ["crit_bonus", "orbit", "damage_reduction"],
		"earthquake": ["stun", "pull", "screen_shake"],
		"frostfire": ["freeze", "spread", "homing"],
		"hellfire": ["burn_intense", "pierce_bonus", "speed_bonus"],
		"thunder_spear": ["crit_massive", "instant", "max_range"],
		"void_storm": ["pull_intense", "damage_aura", "slow"],
		"crystal_guardian": ["orbit", "stun", "explosion"]
	}
	
	return effects.get(fused_weapon_id, [])

# ═══════════════════════════════════════════════════════════════════════════════
# UI HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func get_fusion_preview(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> Dictionary:
	"""
	Obtener información de preview para mostrar en UI
	"""
	var check = can_fuse_weapons(weapon_a, weapon_b)
	
	if not check.can_fuse:
		return {
			"available": false,
			"reason": check.reason
		}
	
	var result = check.result
	return {
		"available": true,
		"name": result.get("name", "???"),
		"name_es": result.get("name_es", result.get("name", "???")),
		"icon": result.get("icon", "❓"),
		"description": result.get("description", ""),
		"synergy": get_synergy_description(result),
		"stats_preview": _get_stats_comparison(weapon_a, weapon_b, result),
		"warning": "⚠️ Perderás 1 slot de arma permanentemente"
	}

func _get_stats_comparison(weapon_a: BaseWeapon, weapon_b: BaseWeapon, fusion_result: Dictionary) -> Dictionary:
	"""Comparar stats de las armas originales vs fusionada"""
	var combined_damage = weapon_a.damage + weapon_b.damage
	var fusion_damage = fusion_result.get("damage", 0)
	
	var avg_cooldown = (weapon_a.cooldown + weapon_b.cooldown) / 2.0
	var fusion_cooldown = fusion_result.get("cooldown", 1.0)
	
	return {
		"damage": {
			"before": "%.0f + %.0f" % [weapon_a.damage, weapon_b.damage],
			"after": "%.0f" % fusion_damage,
			"change": "%.0f%%" % ((fusion_damage / combined_damage - 1.0) * 100) if combined_damage > 0 else "N/A"
		},
		"cooldown": {
			"before": "%.2fs / %.2fs" % [weapon_a.cooldown, weapon_b.cooldown],
			"after": "%.2fs" % fusion_cooldown,
			"better": fusion_cooldown < avg_cooldown
		},
		"effects": {
			"lost": [],  # Las armas originales se pierden
			"gained": get_synergy_effects(fusion_result.get("id", ""))
		}
	}

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar estado para guardado"""
	return {
		"slots_lost": slots_lost,
		"fusion_history": fusion_history.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	"""Restaurar estado desde datos guardados"""
	slots_lost = data.get("slots_lost", 0)
	fusion_history = data.get("fusion_history", []).duplicate()

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	return """
=== WEAPON FUSION MANAGER ===
Slots disponibles: %d / %d
Slots perdidos: %d
Fusiones realizadas: %d

Historial:
%s
""" % [
		current_max_slots,
		STARTING_MAX_SLOTS,
		slots_lost,
		fusion_history.size(),
		_format_history()
	]

func _format_history() -> String:
	if fusion_history.is_empty():
		return "  (ninguna)"
	
	var lines = []
	for entry in fusion_history:
		lines.append("  • %s + %s → %s" % [
			entry.weapon_a_id, entry.weapon_b_id, entry.result_id
		])
	return "\n".join(lines)
