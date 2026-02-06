# LeaderboardService.gd
# Servicio para manejar leaderboards y serialización de builds
# Usado por: RankingScreen, Game (al terminar run)

class_name LeaderboardService
extends RefCounted

# ═══════════════════════════════════════════════════════════════════════════════
# ESTRUCTURA DE DATOS
# ═══════════════════════════════════════════════════════════════════════════════

## Representa una entrada en el ranking
class RankingEntry:
	var rank: int = 0
	var steam_id: int = 0
	var steam_name: String = ""
	var score: int = 0
	var timestamp: int = 0
	var build_data: BuildData = null
	
	func _init(data: Dictionary = {}) -> void:
		rank = data.get("rank", 0)
		steam_id = data.get("steam_id", 0)
		steam_name = data.get("steam_name", "Unknown")
		score = data.get("score", 0)
		timestamp = data.get("timestamp", 0)
		if data.has("build_data"):
			build_data = BuildData.new(data["build_data"])

## Representa la build completa de un jugador
class BuildData:
	var character_id: String = ""
	var character_name: String = ""
	var weapons: Array = []  # Array de WeaponInfo
	var items: Array = []    # Array de ItemInfo
	var stats: Dictionary = {}
	var time_survived: float = 0.0
	var enemies_killed: int = 0
	var level_reached: int = 1
	var gold_collected: int = 0
	
	func _init(data: Dictionary = {}) -> void:
		character_id = data.get("character_id", "")
		character_name = data.get("character_name", "")
		weapons = data.get("weapons", [])
		items = data.get("items", [])
		stats = data.get("stats", {})
		time_survived = data.get("time_survived", 0.0)
		enemies_killed = data.get("enemies_killed", 0)
		level_reached = data.get("level_reached", 1)
		gold_collected = data.get("gold_collected", 0)
	
	func to_dict() -> Dictionary:
		return {
			"character_id": character_id,
			"character_name": character_name,
			"weapons": weapons,
			"items": items,
			"stats": stats,
			"time_survived": time_survived,
			"enemies_killed": enemies_killed,
			"level_reached": level_reached,
			"gold_collected": gold_collected
		}

## Info de un arma para el ranking
class WeaponInfo:
	var id: String = ""
	var name: String = ""
	var level: int = 1
	var icon: String = ""
	var element: String = ""
	var is_fusion: bool = false
	
	func _init(data: Dictionary = {}) -> void:
		id = data.get("id", "")
		name = data.get("name", "")
		level = data.get("level", 1)
		icon = data.get("icon", "")
		element = data.get("element", "")
		is_fusion = data.get("is_fusion", false)

## Info de un item/upgrade para el ranking
class ItemInfo:
	var id: String = ""
	var name: String = ""
	var icon: String = ""
	var tier: int = 1
	var is_cursed: bool = false
	
	func _init(data: Dictionary = {}) -> void:
		id = data.get("id", "")
		name = data.get("name", "")
		icon = data.get("icon", "")
		tier = data.get("tier", 1)
		is_cursed = data.get("is_cursed", false)

# ═══════════════════════════════════════════════════════════════════════════════
# CAPTURA DE BUILD ACTUAL
# ═══════════════════════════════════════════════════════════════════════════════

static func capture_current_build(game_node: Node) -> BuildData:
	"""Capturar la build actual del jugador desde el estado del juego"""
	var build = BuildData.new()
	
	# Obtener player
	var player = game_node.get_tree().get_first_node_in_group("player")
	if player:
		build.character_id = player.get("character_id") if "character_id" in player else ""
		build.character_name = player.get("character_name") if "character_name" in player else ""
		build.stats = _capture_player_stats(player)
	
	# Obtener armas desde AttackManager
	var attack_manager = game_node.get_tree().get_first_node_in_group("attack_manager")
	if attack_manager:
		build.weapons = _capture_weapons(attack_manager)
	
	# Obtener items/upgrades desde UpgradeManager o similar
	var upgrade_manager = game_node.get_tree().root.get_node_or_null("UpgradeManager")
	if upgrade_manager and upgrade_manager.has_method("get_active_upgrades"):
		build.items = _capture_items(upgrade_manager.get_active_upgrades())
	
	# Stats de la run
	if "run_stats" in game_node:
		var rs = game_node.run_stats
		build.time_survived = rs.get("time", 0.0)
		build.enemies_killed = rs.get("kills", 0)
		build.level_reached = rs.get("level", 1)
		build.gold_collected = rs.get("gold", 0)
	
	return build

static func _capture_player_stats(player: Node) -> Dictionary:
	"""Capturar stats del jugador"""
	var stats = {}
	
	# Lista de stats a capturar
	var stat_names = [
		"max_health", "health", "armor", "speed",
		"damage_multiplier", "attack_speed_multiplier",
		"crit_chance", "crit_damage", "lifesteal",
		"pickup_range", "xp_multiplier"
	]
	
	for stat_name in stat_names:
		if stat_name in player:
			stats[stat_name] = player.get(stat_name)
		elif player.has_method("get_stat"):
			stats[stat_name] = player.get_stat(stat_name)
	
	return stats

static func _capture_weapons(attack_manager: Node) -> Array:
	"""Capturar información de armas equipadas"""
	var weapons: Array = []
	
	if not attack_manager.has_method("get_weapons"):
		return weapons
	
	var equipped = attack_manager.get_weapons()
	for weapon in equipped:
		if weapon == null:
			continue
		
		var weapon_info = {
			"id": weapon.id if "id" in weapon else "",
			"name": weapon.weapon_name if "weapon_name" in weapon else "",
			"level": weapon.level if "level" in weapon else 1,
			"icon": weapon.icon if "icon" in weapon else "",
			"element": weapon.element if "element" in weapon else "",
			"is_fusion": weapon.is_fusion if "is_fusion" in weapon else false
		}
		weapons.append(weapon_info)
	
	return weapons

static func _capture_items(upgrades: Array) -> Array:
	"""Capturar información de items/upgrades activos"""
	var items: Array = []
	
	for upgrade in upgrades:
		if upgrade == null:
			continue
		
		var item_info = {
			"id": upgrade.get("id", ""),
			"name": upgrade.get("name", ""),
			"icon": upgrade.get("icon", ""),
			"tier": upgrade.get("tier", 1),
			"is_cursed": upgrade.get("is_cursed", false)
		}
		items.append(item_info)
	
	return items

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN PARA STEAM (256 bytes máx)
# ═══════════════════════════════════════════════════════════════════════════════

static func serialize_build_for_steam(build: BuildData) -> PackedInt32Array:
	"""Serializar build a formato Steam (64 int32 máximo)"""
	var data = PackedInt32Array()
	
	# La serialización completa de build es muy pesada para los 256 bytes
	# Guardamos solo datos esenciales:
	# - 4 bytes: character_id hash
	# - 4 bytes: time_survived (seconds as int)
	# - 4 bytes: enemies_killed
	# - 4 bytes: level_reached
	# - 4 bytes: gold_collected
	# - 4 bytes: weapon_count
	# - N*4 bytes: weapon_id hashes (hasta 8 armas)
	# Total: 6 + 8 = 14 ints = 56 bytes (bien dentro del límite)
	
	data.append(build.character_id.hash())
	data.append(int(build.time_survived))
	data.append(build.enemies_killed)
	data.append(build.level_reached)
	data.append(build.gold_collected)
	data.append(build.weapons.size())
	
	# Añadir hashes de armas (máximo 8)
	for i in range(min(8, build.weapons.size())):
		var weapon = build.weapons[i]
		if weapon is Dictionary:
			data.append(weapon.get("id", "").hash())
		else:
			data.append(0)
	
	return data

static func deserialize_build_from_steam(data: PackedInt32Array) -> Dictionary:
	"""Deserializar build desde formato Steam"""
	if data.size() < 6:
		return {}
	
	var build = {
		"character_id_hash": data[0],
		"time_survived": float(data[1]),
		"enemies_killed": data[2],
		"level_reached": data[3],
		"gold_collected": data[4],
		"weapon_count": data[5],
		"weapon_id_hashes": []
	}
	
	# Leer hashes de armas
	var weapon_count = min(data[5], 8)
	for i in range(weapon_count):
		if 6 + i < data.size():
			build["weapon_id_hashes"].append(data[6 + i])
	
	return build

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

static func format_time(seconds: float) -> String:
	"""Formatear tiempo como MM:SS"""
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

static func get_month_name(month: int, lang: String = "es") -> String:
	"""Obtener nombre del mes"""
	var months_es = ["", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
					 "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
	var months_en = ["", "January", "February", "March", "April", "May", "June",
					 "July", "August", "September", "October", "November", "December"]
	
	if month < 1 or month > 12:
		return ""
	
	if lang == "en":
		return months_en[month]
	return months_es[month]
