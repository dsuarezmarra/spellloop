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
# RESET PARA NUEVA PARTIDA
# ═══════════════════════════════════════════════════════════════════════════════

func reset() -> void:
	"""Resetear estado para nueva partida"""
	slots_lost = 0
	fusion_history.clear()

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
	
	# Verificar nivel máximo (Mecánica clave: Solo armas maxeadas evolucionan)
	if weapon_a.level < weapon_a.max_level or weapon_b.level < weapon_b.max_level:
		return {
			"can_fuse": false,
			"reason": "Ambas armas deben estar al Nivel Máximo (%d) para evolucionar" % weapon_a.max_level,
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
	
	# Filtrar solo BaseWeapon (ignorar armas legacy)
	var base_weapons: Array[BaseWeapon] = []
	for w in weapons:
		if w is BaseWeapon:
			base_weapons.append(w)
	
	for i in range(base_weapons.size()):
		for j in range(i + 1, base_weapons.size()):
			var check = can_fuse_weapons(base_weapons[i], base_weapons[j])
			if check.can_fuse:
				available.append({
					"weapon_a": base_weapons[i],
					"weapon_b": base_weapons[j],
					"result": check.result
				})
	
	return available

# ═══════════════════════════════════════════════════════════════════════════════
# EJECUCIÓN DE FUSIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func fuse_weapons(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> BaseWeapon:
	"""
	Fusionar dos armas en una nueva con stats dinámicos mejorados
	"""
	# Verificar que la fusión es válida
	var check = can_fuse_weapons(weapon_a, weapon_b)
	if not check.can_fuse:
		fusion_failed.emit(check.reason)
		push_error("[WeaponFusionManager] Fusión fallida: %s" % check.reason)
		return null
	
	# Calcular stats dinámicos (x2 de la suma de componentes)
	var dynamic_stats = _calculate_dynamic_stats(weapon_a, weapon_b)
	
	# Crear el arma fusionada
	var fused_weapon = _create_fused_weapon(weapon_a, weapon_b, check.result)
	if fused_weapon == null:
		fusion_failed.emit("Error al crear el arma fusionada")
		return null
	
	# APLICAR STATS DINÁMICOS Y RESETEAR A NIVEL 1
	fused_weapon.override_stats(dynamic_stats)
	
	# Registrar en historial
	fusion_history.append({
		"weapon_a_id": weapon_a.id,
		"weapon_b_id": weapon_b.id,
		"result_id": fused_weapon.id,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Incrementar slots perdidos permanentemente
	slots_lost += 1
	
	fusion_completed.emit(fused_weapon, true)
	
	return fused_weapon

func _calculate_dynamic_stats(a: BaseWeapon, b: BaseWeapon) -> Dictionary:
	"""
	Calcula los stats base de la fusión combinando los componentes.
	Lógica: (Stat A + Stat B) * 2.0 (Massive Power Spike)
	"""
	var stats = {}
	
	# Daño
	stats["damage"] = (a.damage + b.damage) * 2.0
	
	# Cooldown: Promedio de velocidad, duplicado (mitad de tiempo)
	var avg_cd = (a.cooldown + b.cooldown) / 2.0
	stats["cooldown"] = avg_cd * 0.5
	
	# Rango: Promedio + 50%
	var avg_range = (a.weapon_range + b.weapon_range) / 2.0
	stats["range"] = avg_range * 1.5
	
	# Velocidad de proyectil
	stats["projectile_speed"] = (a.projectile_speed + b.projectile_speed) * 0.75 # No queremos que sea demasiado rápido (glitchy)
	if stats["projectile_speed"] < 400.0: stats["projectile_speed"] = 400.0
	
	# Cantidad
	stats["projectile_count"] = (a.projectile_count + b.projectile_count) * 2
	
	# Pierce (Cap en 10 para evitar números absurdos si no es infinito)
	if a.pierce >= 99 or b.pierce >= 99:
		stats["pierce"] = 999 
	else:
		stats["pierce"] = min((a.pierce + b.pierce) * 2, 20)
	
	# Área
	stats["area"] = (a.area + b.area) * 2.0
	
	# Duración
	stats["duration"] = (a.duration + b.duration) * 2.0
	
	# Knockback
	stats["knockback"] = (a.knockback + b.knockback) * 2.0
	
	# Effect Value (Burn damage, slow amount, etc)
	stats["effect_value"] = (a.effect_value + b.effect_value) * 1.5
	stats["effect_duration"] = (a.effect_duration + b.effect_duration) * 1.5
	
	return stats

func _create_fused_weapon(weapon_a: BaseWeapon, weapon_b: BaseWeapon, fusion_data: Dictionary) -> BaseWeapon:
	"""Crear el arma fusionada con los datos combinados"""
	# Crear instancia
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

func get_synergy_description(fusion_result) -> String:
	"""Obtener descripción de la sinergia de una fusión"""
	var synergy_descriptions = {
		"steam_cannon": "❄️+🔥 → 💨\nEl vapor congela y quema simultáneamente\n• Enemigos ralentizados reciben daño continuo\n• Explosiones de área ampliadas",
		
		"storm_caller": "⚡+🌪️ → ⛈️\nLa tormenta perfecta\n• Rayos que saltan entre enemigos\n• Mayor área de efecto\n• Empuja enemigos con viento",
		
		"soul_reaper": "🗡️+🌿 → 💀\nCosecha las almas enemigas\n• Dagas que persiguen objetivos\n• Roba vida al eliminar enemigos\n• Atraviesa múltiples objetivos",
		
		"cosmic_barrier": "💜+✨ → 🌟\nBarrera de luz cósmica\n• Orbes brillantes que orbitan\n• Mayor probabilidad de crítico\n• Protección pasiva mejorada",
		
		"rift_quake": "🪨+🕳️ → 🌋\nGrietas sísmicas del vacío\n• Área masiva de daño\n• Atrae y aturde enemigos\n• Abre portales en el suelo",
		
		"frostvine": "❄️+🌿 → 🥶\nEnredaderas de hielo viviente\n• Proyectiles que persiguen\n• Congelación casi total\n• Se propaga entre enemigos cercanos",
		
		"hellfire": "🔥+🗡️ → 👹\nLlamas del infierno\n• Dagas de fuego oscuro\n• Quemadura intensificada\n• Atraviesa y quema todo",
		
		"thunder_spear": "⚡+✨ → 🔱\nLanza divina del trueno\n• Rayo instantáneo devastador\n• Crítico casi garantizado\n• Máximo rango y penetración",
		
		"void_storm": "🕳️+🌪️ → 🌀\nVortex del vacío infinito\n• Tornado que succiona enemigos\n• Daño continuo en área\n• Imposible de escapar",
		
		"crystal_guardian": "🪨+💜 → 💎\nCristales arcanos protectores\n• Cristales que orbitan\n• Explosiones al contacto\n• Aturden brevemente",
		
		# ═══════════════════════════════════════════════════════════════════════
		# FUSIONES ORBITALES
		# ═══════════════════════════════════════════════════════════════════════
		
		"frost_orb": "❄️+🔮 → 🔵\nOrbes gélidos orbitantes\n• Orbitan ralentizando enemigos cercanos\n• Aura de frío constante\n• Congelación progresiva",
		
		"inferno_orb": "🔥+🔮 → 🔴\nOrbes de fuego infernal\n• Orbitan quemando todo a su paso\n• Llamas caóticas y explosivas\n• Daño continuo intenso",
		
		"arcane_storm": "💜+⚡ → 💜⚡\nTormenta arcana orbital\n• Orbes de energía eléctrica\n• Rayos que saltan entre objetivos\n• Campo electromagnético",
		
		"shadow_orbs": "🗡️+🔮 → ⚫\nOrbes de sombra letal\n• Orbitan absorbiendo luz\n• Daño crítico aumentado\n• Atraviesan enemigos",
		
		"life_orbs": "🌿+🔮 → 💚\nOrbes de vida natural\n• Orbitan curando al portador\n• Drenan vida de enemigos\n• Regeneración pasiva",
		
		"wind_orbs": "🌪️+🔮 → 🌬️\nOrbes de viento cortante\n• Orbitan a alta velocidad\n• Empujan enemigos hacia afuera\n• Escudo de aire protector",
		
		"cosmic_void": "🕳️+🔮 → 🌌\nOrbes del vacío cósmico\n• Orbitan distorsionando la realidad\n• Atraen enemigos hacia el centro\n• Daño gravitacional masivo"
	}
	
	var fusion_id = ""
	var default_desc = Localization.L("synergies.unknown")
	
	if fusion_result is BaseWeapon:
		fusion_id = fusion_result.id
		if "description" in fusion_result:
			default_desc = fusion_result.description
	elif fusion_result is Dictionary:
		fusion_id = fusion_result.get("id", "")
		default_desc = fusion_result.get("description", default_desc)
		
	return synergy_descriptions.get(fusion_id, default_desc)

func get_synergy_effects(fused_weapon_id: String) -> Array:
	"""Obtener efectos especiales de sinergia para un arma fusionada"""
	var effects = {
		"steam_cannon": ["slow", "burn", "area_bonus"],
		"storm_caller": ["chain", "knockback_bonus", "multi_target"],
		"soul_reaper": ["lifesteal", "pierce_bonus", "homing"],
		"cosmic_barrier": ["crit_bonus", "orbit", "damage_reduction"],
		"rift_quake": ["stun", "pull", "screen_shake"],
		"frostvine": ["freeze", "spread", "homing"],
		"hellfire": ["burn_intense", "pierce_bonus", "speed_bonus"],
		"thunder_spear": ["crit_massive", "instant", "max_range"],
		"void_storm": ["pull_intense", "damage_aura", "slow"],
		"crystal_guardian": ["orbit", "stun", "explosion"],
		
		# ═══════════════════════════════════════════════════════════════════════
		# FUSIONES ORBITALES
		# ═══════════════════════════════════════════════════════════════════════
		"frost_orb": ["orbit", "slow", "freeze_aura"],
		"inferno_orb": ["orbit", "burn", "explosion_on_hit"],
		"arcane_storm": ["orbit", "chain", "energy_field"],
		"shadow_orbs": ["orbit", "crit_bonus", "pierce_bonus"],
		"life_orbs": ["orbit", "lifesteal", "regen"],
		"wind_orbs": ["orbit", "knockback_bonus", "speed_bonus"],
		"cosmic_void": ["orbit", "pull_intense", "gravity_damage"]
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
	
	# Defensive handling for result type (Dynamic typing to handle BaseWeapon)
	var r_name = "???"
	var r_name_es = "???"
	var r_icon = "❓"
	var r_desc = ""
	
	if result is BaseWeapon:
		r_name = result.weapon_name
		r_name_es = result.weapon_name_es
		r_icon = result.icon
		r_desc = result.description
	elif result is Dictionary:
		r_name = result.get("name", "???")
		r_name_es = result.get("name_es", result.get("name", "???"))
		r_icon = result.get("icon", "❓")
		r_desc = result.get("description", "")
	
	return {
		"available": true,
		"name": r_name,
		"name_es": r_name_es,
		"icon": r_icon,
		"description": r_desc,
		"synergy": get_synergy_description(result),
		"stats_preview": _get_stats_comparison(weapon_a, weapon_b, result),
		"warning": "⚠️ Perderás 1 slot de arma permanentemente"
	}

func _get_stats_comparison(weapon_a: BaseWeapon, weapon_b: BaseWeapon, fusion_result) -> Dictionary:
	"""Comparar stats de las armas originales vs fusionada"""
	var combined_damage = weapon_a.damage + weapon_b.damage
	var fusion_damage = 0
	var fusion_cooldown = 1.0
	
	if fusion_result is BaseWeapon:
		fusion_damage = fusion_result.damage
		fusion_cooldown = fusion_result.cooldown
	elif fusion_result is Dictionary:
		fusion_damage = fusion_result.get("damage", 0)
		fusion_cooldown = fusion_result.get("cooldown", 1.0)
	
	var avg_cooldown = (weapon_a.cooldown + weapon_b.cooldown) / 2.0
	
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
			"gained": get_synergy_effects(fusion_result.id if fusion_result is BaseWeapon else fusion_result.get("id", ""))
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
