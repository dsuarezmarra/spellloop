# DamageLogger.gd
# Sistema centralizado de logs de daño para diagnóstico
#
# USO:
# - DamageLogger.log_weapon_damage("ice_wand", "Skeleton_0", 25, {"crit": true})
# - DamageLogger.log_player_damage("Skeleton_0", 15, "physical")
#
# Para desactivar todos los logs: cambiar ENABLED = false

extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN GLOBAL
# ═══════════════════════════════════════════════════════════════════════════════

## Toggle global - cambiar a false para desactivar TODOS los logs de daño
const ENABLED: bool = true

## Mostrar logs de daño de armas (OUTPUT)
const LOG_WEAPON_DAMAGE: bool = false

## Mostrar logs de daño al player (INPUT)
const LOG_PLAYER_DAMAGE: bool = false

## Mostrar extras en los logs (crit, effect, etc.)
const SHOW_EXTRAS: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

static func log_weapon_damage(weapon_id: String, target_name: String, damage: int, extras: Dictionary = {}) -> void:
	"""
	Log de daño aplicado por un arma/proyectil a un enemigo.
	
	@param weapon_id: ID del arma (ej: "ice_wand", "arcane_orb")
	@param target_name: Nombre del objetivo (ej: "Skeleton_0")
	@param damage: Daño aplicado
	@param extras: Info adicional {crit: bool, effect: String, tick: String, etc.}
	"""
	if not ENABLED or not LOG_WEAPON_DAMAGE:
		return
	
	var icon = _get_weapon_icon(weapon_id)
	var extras_str = _format_extras(extras)
	
	print("[DAMAGE] %s %s → %s: %d dmg%s" % [icon, weapon_id, target_name, damage, extras_str])

static func log_player_damage(source_name: String, damage: int, damage_type: String = "physical") -> void:
	"""
	Log de daño recibido por el player.
	
	@param source_name: Nombre de la fuente del daño (ej: "Skeleton_0", "fire_trail")
	@param damage: Daño recibido
	@param damage_type: Tipo de daño (physical, fire, ice, etc.)
	"""
	if not ENABLED or not LOG_PLAYER_DAMAGE:
		return
	
	print("[DAMAGE] 🛡️ Player ← %s: %d dmg (%s)" % [source_name, damage, damage_type])

static func log_orbital_damage(weapon_id: String, target_name: String, damage: int, extras: Dictionary = {}) -> void:
	"""Log específico para orbitales"""
	if not ENABLED or not LOG_WEAPON_DAMAGE:
		return
	
	var extras_str = _format_extras(extras)
	print("[DAMAGE] 🔮 %s → %s: %d dmg%s" % [weapon_id, target_name, damage, extras_str])

static func log_aoe_damage(weapon_id: String, target_name: String, damage: int, tick_info: String = "") -> void:
	"""Log específico para AOE con info de ticks"""
	if not ENABLED or not LOG_WEAPON_DAMAGE:
		return
	
	var tick_str = " (%s)" % tick_info if tick_info != "" else ""
	print("[DAMAGE] 💥 %s → %s: %d dmg%s" % [weapon_id, target_name, damage, tick_str])

static func log_beam_damage(weapon_id: String, target_name: String, damage: int, is_crit: bool = false) -> void:
	"""Log específico para beams"""
	if not ENABLED or not LOG_WEAPON_DAMAGE:
		return
	
	var crit_str = " (CRIT!)" if is_crit else ""
	print("[DAMAGE] ⚡ %s → %s: %d dmg%s" % [weapon_id, target_name, damage, crit_str])

static func log_chain_damage(weapon_id: String, target_name: String, damage: int, hop: int, max_hops: int) -> void:
	"""Log específico para daño en cadena"""
	if not ENABLED or not LOG_WEAPON_DAMAGE:
		return
	
	print("[DAMAGE] ⛓️ %s → %s: %d dmg (chain %d/%d)" % [weapon_id, target_name, damage, hop, max_hops])

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS PRIVADOS
# ═══════════════════════════════════════════════════════════════════════════════

static func _get_weapon_icon(weapon_id: String) -> String:
	"""Obtener icono según tipo de arma"""
	if "ice" in weapon_id or "frost" in weapon_id or "glacier" in weapon_id:
		return "❄️"
	elif "fire" in weapon_id or "flame" in weapon_id or "volcano" in weapon_id:
		return "🔥"
	elif "lightning" in weapon_id or "storm" in weapon_id or "thunder" in weapon_id:
		return "⚡"
	elif "arcane" in weapon_id or "void" in weapon_id:
		return "🔮"
	elif "dark" in weapon_id or "shadow" in weapon_id:
		return "🌑"
	elif "nature" in weapon_id or "earth" in weapon_id:
		return "🌿"
	else:
		return "⚔️"

static func _format_extras(extras: Dictionary) -> String:
	"""Formatear extras para el log"""
	if not SHOW_EXTRAS or extras.is_empty():
		return ""
	
	var parts: Array[String] = []
	
	if extras.has("crit") and extras.crit:
		parts.append("CRIT!")
	if extras.has("effect") and extras.effect != "" and extras.effect != "none":
		parts.append("effect: %s" % extras.effect)
	if extras.has("tick"):
		parts.append("tick: %s" % extras.tick)
	
	if parts.is_empty():
		return ""
	
	return " (" + ", ".join(parts) + ")"
