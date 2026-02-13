# SteamAchievements.gd
# Sistema de logros para Steam y modo offline
# Autoload: SteamAchievements
#
# Gestiona 20 logros organizados en categorías:
# - Progresión: hitos de partidas y supervivencia
# - Combate: enemigos derrotados y hazañas en combate
# - Personajes: desbloqueo de magos
# - Armas: fusiones y colecciones
# - Desafío: logros de alto nivel de habilidad
#
# Public API:
# - check_and_unlock(achievement_id: String) -> bool
# - increment_stat(stat_name: String, amount: int) -> void
# - get_achievement_progress(achievement_id: String) -> Dictionary
# - get_all_achievements() -> Array
# - reset_all() -> void
#
# Signals:
# - achievement_unlocked(achievement_id: String, achievement_name: String)

extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal achievement_unlocked(achievement_id: String, achievement_name: String)

# ═══════════════════════════════════════════════════════════════════════════════
# CATÁLOGO DE ACHIEVEMENTS
# ═══════════════════════════════════════════════════════════════════════════════

# Cada achievement tiene:
# - id: Identificador interno (debe coincidir con Steamworks)
# - name / name_es: Nombre visible
# - description / description_es: Descripción visible
# - category: Categoría para organización UI
# - hidden: Si es un logro oculto
# - stat_name: (opcional) stat que se trackea para progreso
# - stat_target: (opcional) valor objetivo para desbloquear automáticamente
# - icon: (opcional) path al icono del logro

const ACHIEVEMENTS: Dictionary = {
	# ═══════════════════════════════════════════════════════════════════════════
	# 🏃 PROGRESIÓN
	# ═══════════════════════════════════════════════════════════════════════════
	"ACH_FIRST_RUN": {
		"id": "ACH_FIRST_RUN",
		"name": "First Steps",
		"name_es": "Primeros Pasos",
		"description": "Complete your first run.",
		"description_es": "Completa tu primera partida.",
		"category": "progression",
		"hidden": false,
		"icon": "res://assets/icons/achievement_first_run.png"
	},
	"ACH_FIRST_BOSS": {
		"id": "ACH_FIRST_BOSS",
		"name": "Boss Slayer",
		"name_es": "Cazador de Jefes",
		"description": "Defeat your first boss.",
		"description_es": "Derrota a tu primer jefe.",
		"category": "progression",
		"hidden": false,
		"icon": "res://assets/icons/achievement_first_boss.png"
	},
	"ACH_SURVIVE_10": {
		"id": "ACH_SURVIVE_10",
		"name": "Getting Warmed Up",
		"name_es": "Entrando en Calor",
		"description": "Survive for 10 minutes in a single run.",
		"description_es": "Sobrevive 10 minutos en una sola partida.",
		"category": "progression",
		"hidden": false,
		"stat_name": "longest_run_minutes",
		"stat_target": 10,
		"icon": "res://assets/icons/achievement_survive_10.png"
	},
	"ACH_SURVIVE_20": {
		"id": "ACH_SURVIVE_20",
		"name": "Endurance",
		"name_es": "Resistencia",
		"description": "Survive for 20 minutes in a single run.",
		"description_es": "Sobrevive 20 minutos en una sola partida.",
		"category": "progression",
		"hidden": false,
		"stat_name": "longest_run_minutes",
		"stat_target": 20,
		"icon": "res://assets/icons/achievement_survive_20.png"
	},
	"ACH_SURVIVE_30": {
		"id": "ACH_SURVIVE_30",
		"name": "Infinite Loop",
		"name_es": "Bucle Infinito",
		"description": "Survive for 30 minutes in a single run.",
		"description_es": "Sobrevive 30 minutos en una sola partida.",
		"category": "progression",
		"hidden": false,
		"stat_name": "longest_run_minutes",
		"stat_target": 30,
		"icon": "res://assets/icons/achievement_survive_30.png"
	},
	"ACH_10_RUNS": {
		"id": "ACH_10_RUNS",
		"name": "Persistent",
		"name_es": "Persistente",
		"description": "Complete 10 runs.",
		"description_es": "Completa 10 partidas.",
		"category": "progression",
		"hidden": false,
		"stat_name": "total_runs",
		"stat_target": 10,
		"icon": "res://assets/icons/achievement_10_runs.png"
	},
	"ACH_50_RUNS": {
		"id": "ACH_50_RUNS",
		"name": "Veteran",
		"name_es": "Veterano",
		"description": "Complete 50 runs.",
		"description_es": "Completa 50 partidas.",
		"category": "progression",
		"hidden": false,
		"stat_name": "total_runs",
		"stat_target": 50,
		"icon": "res://assets/icons/achievement_50_runs.png"
	},

	# ═══════════════════════════════════════════════════════════════════════════
	# ⚔️ COMBATE
	# ═══════════════════════════════════════════════════════════════════════════
	"ACH_KILL_100": {
		"id": "ACH_KILL_100",
		"name": "Century",
		"name_es": "Centenario",
		"description": "Defeat 100 enemies in a single run.",
		"description_es": "Derrota a 100 enemigos en una sola partida.",
		"category": "combat",
		"hidden": false,
		"stat_name": "run_enemies_killed",
		"stat_target": 100,
		"icon": "res://assets/icons/achievement_kill_100.png"
	},
	"ACH_KILL_500": {
		"id": "ACH_KILL_500",
		"name": "Slaughter",
		"name_es": "Masacre",
		"description": "Defeat 500 enemies in a single run.",
		"description_es": "Derrota a 500 enemigos en una sola partida.",
		"category": "combat",
		"hidden": false,
		"stat_name": "run_enemies_killed",
		"stat_target": 500,
		"icon": "res://assets/icons/achievement_kill_500.png"
	},
	"ACH_KILL_1000": {
		"id": "ACH_KILL_1000",
		"name": "Arcane Apocalypse",
		"name_es": "Apocalipsis Arcano",
		"description": "Defeat 1000 enemies in a single run.",
		"description_es": "Derrota a 1000 enemigos en una sola partida.",
		"category": "combat",
		"hidden": false,
		"stat_name": "run_enemies_killed",
		"stat_target": 1000,
		"icon": "res://assets/icons/achievement_kill_1000.png"
	},
	"ACH_TOTAL_KILLS_5000": {
		"id": "ACH_TOTAL_KILLS_5000",
		"name": "Exterminator",
		"name_es": "Exterminador",
		"description": "Defeat 5000 enemies across all runs.",
		"description_es": "Derrota a 5000 enemigos entre todas tus partidas.",
		"category": "combat",
		"hidden": false,
		"stat_name": "total_enemies_killed",
		"stat_target": 5000,
		"icon": "res://assets/icons/achievement_total_kills.png"
	},
	"ACH_BOSS_FAST_KILL": {
		"id": "ACH_BOSS_FAST_KILL",
		"name": "Speed Kill",
		"name_es": "Ejecución Rápida",
		"description": "Defeat a boss in under 30 seconds.",
		"description_es": "Derrota a un jefe en menos de 30 segundos.",
		"category": "combat",
		"hidden": true,
		"icon": "res://assets/icons/achievement_boss_fast.png"
	},
	"ACH_ALL_BOSSES": {
		"id": "ACH_ALL_BOSSES",
		"name": "Boss Hunter",
		"name_es": "Cazador de Jefes",
		"description": "Defeat all 4 unique bosses.",
		"description_es": "Derrota a los 4 jefes únicos.",
		"category": "combat",
		"hidden": false,
		"stat_name": "unique_bosses_defeated",
		"stat_target": 4,
		"icon": "res://assets/icons/achievement_all_bosses.png"
	},

	# ═══════════════════════════════════════════════════════════════════════════
	# 🧙 PERSONAJES
	# ═══════════════════════════════════════════════════════════════════════════
	"ACH_UNLOCK_3_MAGES": {
		"id": "ACH_UNLOCK_3_MAGES",
		"name": "Expanding the Circle",
		"name_es": "Ampliando el Círculo",
		"description": "Unlock 3 different mages.",
		"description_es": "Desbloquea 3 magos diferentes.",
		"category": "characters",
		"hidden": false,
		"stat_name": "mages_unlocked",
		"stat_target": 3,
		"icon": "res://assets/icons/achievement_3_mages.png"
	},
	"ACH_UNLOCK_ALL_MAGES": {
		"id": "ACH_UNLOCK_ALL_MAGES",
		"name": "Full Roster",
		"name_es": "Plantilla Completa",
		"description": "Unlock all 10 mages.",
		"description_es": "Desbloquea los 10 magos.",
		"category": "characters",
		"hidden": false,
		"stat_name": "mages_unlocked",
		"stat_target": 10,
		"icon": "res://assets/icons/achievement_all_mages.png"
	},

	# ═══════════════════════════════════════════════════════════════════════════
	# 🔮 ARMAS
	# ═══════════════════════════════════════════════════════════════════════════
	"ACH_FIRST_FUSION": {
		"id": "ACH_FIRST_FUSION",
		"name": "Spell Fusion",
		"name_es": "Fusión de Hechizos",
		"description": "Create your first weapon fusion.",
		"description_es": "Crea tu primera fusión de arma.",
		"category": "weapons",
		"hidden": false,
		"icon": "res://assets/icons/achievement_first_fusion.png"
	},
	"ACH_MAX_WEAPONS": {
		"id": "ACH_MAX_WEAPONS",
		"name": "Full Arsenal",
		"name_es": "Arsenal Completo",
		"description": "Have 6 weapons equipped at the same time.",
		"description_es": "Ten 6 armas equipadas al mismo tiempo.",
		"category": "weapons",
		"hidden": false,
		"icon": "res://assets/icons/achievement_max_weapons.png"
	},

	# ═══════════════════════════════════════════════════════════════════════════
	# 🎯 DESAFÍO
	# ═══════════════════════════════════════════════════════════════════════════
	"ACH_LEVEL_50": {
		"id": "ACH_LEVEL_50",
		"name": "Archmage",
		"name_es": "Archimago",
		"description": "Reach level 50 in a single run.",
		"description_es": "Alcanza el nivel 50 en una sola partida.",
		"category": "challenge",
		"hidden": false,
		"stat_name": "max_level_reached",
		"stat_target": 50,
		"icon": "res://assets/icons/achievement_level_50.png"
	},
	"ACH_NO_HIT_BOSS": {
		"id": "ACH_NO_HIT_BOSS",
		"name": "Untouchable",
		"name_es": "Intocable",
		"description": "Defeat a boss without taking any damage.",
		"description_es": "Derrota a un jefe sin recibir daño.",
		"category": "challenge",
		"hidden": true,
		"icon": "res://assets/icons/achievement_no_hit.png"
	}
}

# Stats que se trackean para achievements con progreso
# Estos se sincronizan con Steam Stats cuando está disponible
const TRACKED_STATS: Dictionary = {
	"total_runs": 0,
	"total_enemies_killed": 0,
	"longest_run_minutes": 0,
	"run_enemies_killed": 0,       # Se resetea cada run
	"max_level_reached": 0,        # Se resetea cada run
	"mages_unlocked": 3,           # Empieza con 3 starter mages
	"unique_bosses_defeated": 0,   # Acumulativo, se trackea en save
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var _unlocked: Dictionary = {}        # achievement_id -> bool
var _stats: Dictionary = {}           # stat_name -> value
var _pending_sync: Array = []         # IDs pendientes de sincronizar con Steam
var _boss_kill_tracker: Dictionary = {} # boss_id -> bool (para ACH_ALL_BOSSES)
var _boss_fight_start_time: float = 0.0
var _boss_fight_hp_at_start: int = 0   # HP del jugador al iniciar boss fight
var _is_ready: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Inicializar stats con valores por defecto
	_stats = TRACKED_STATS.duplicate(true)
	
	# Cargar estado de achievements desde SaveManager
	_load_from_save()
	
	# Conectar con SteamManager cuando esté listo
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if steam_mgr:
		if steam_mgr.is_initialized:
			_on_steam_ready(steam_mgr.is_steam_available)
		else:
			steam_mgr.steam_initialized.connect(_on_steam_ready)
		
		# Conectar callback de stats recibidos
		if steam_mgr.has_signal("user_stats_received"):
			steam_mgr.user_stats_received.connect(_on_user_stats_received)
	
	_is_ready = true

func _on_steam_ready(success: bool) -> void:
	"""Cuando Steam se inicializa, sincronizar achievements"""
	if success:
		# Solicitar stats del usuario desde Steam
		var steam_mgr = get_node_or_null("/root/SteamManager")
		if steam_mgr:
			steam_mgr.request_user_stats()
		
		# Sincronizar achievements pendientes
		_sync_pending_achievements()

func _on_user_stats_received(success: bool) -> void:
	"""Callback cuando se reciben los stats del usuario desde Steam"""
	if success:
		print("[SteamAchievements] ✅ User stats received from Steam")
		# Los stats de Steam son la fuente de verdad si están disponibles
		_pull_stats_from_steam()

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func check_and_unlock(achievement_id: String) -> bool:
	"""Intentar desbloquear un logro. Retorna true si se desbloqueó ahora."""
	if not ACHIEVEMENTS.has(achievement_id):
		push_warning("[SteamAchievements] Achievement desconocido: %s" % achievement_id)
		return false
	
	# Ya desbloqueado
	if _unlocked.get(achievement_id, false):
		return false
	
	# Desbloquear
	_unlocked[achievement_id] = true
	var ach = ACHIEVEMENTS[achievement_id]
	var ach_name = ach.get("name", achievement_id)
	
	print("[SteamAchievements] 🏆 Achievement desbloqueado: %s (%s)" % [ach_name, achievement_id])
	achievement_unlocked.emit(achievement_id, ach_name)
	
	# Intentar sincronizar con Steam
	_set_steam_achievement(achievement_id)
	
	# Guardar localmente
	_save_to_save_manager()
	
	return true

func increment_stat(stat_name: String, amount: int = 1) -> void:
	"""Incrementar un stat y verificar si desbloquea algún achievement"""
	if not _stats.has(stat_name):
		_stats[stat_name] = 0
	
	_stats[stat_name] += amount
	
	# Verificar achievements que dependen de este stat
	_check_stat_achievements(stat_name)
	
	# Sincronizar stat con Steam
	_set_steam_stat(stat_name, _stats[stat_name])

func set_stat(stat_name: String, value: int) -> void:
	"""Establecer un stat a un valor específico (usa el mayor entre actual y nuevo)"""
	if not _stats.has(stat_name):
		_stats[stat_name] = 0
	
	# Solo actualizar si el nuevo valor es mayor (para stats tipo "best")
	if value > _stats[stat_name]:
		_stats[stat_name] = value
		_check_stat_achievements(stat_name)
		_set_steam_stat(stat_name, _stats[stat_name])

func get_stat(stat_name: String) -> int:
	"""Obtener el valor actual de un stat"""
	return _stats.get(stat_name, 0)

func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""Obtener progreso de un achievement"""
	if not ACHIEVEMENTS.has(achievement_id):
		return {}
	
	var ach = ACHIEVEMENTS[achievement_id]
	var is_unlocked = _unlocked.get(achievement_id, false)
	
	var result = {
		"id": achievement_id,
		"name": ach.get("name", ""),
		"name_es": ach.get("name_es", ""),
		"description": ach.get("description", ""),
		"description_es": ach.get("description_es", ""),
		"category": ach.get("category", ""),
		"hidden": ach.get("hidden", false),
		"unlocked": is_unlocked
	}
	
	# Añadir progreso si tiene stat tracking
	if ach.has("stat_name") and ach.has("stat_target"):
		var current = _stats.get(ach.stat_name, 0)
		var target = ach.stat_target
		result["current"] = current
		result["target"] = target
		result["progress"] = minf(1.0, float(current) / float(target)) if target > 0 else 0.0
	
	return result

func get_all_achievements() -> Array:
	"""Obtener todos los achievements con su estado"""
	var result: Array = []
	for ach_id in ACHIEVEMENTS:
		result.append(get_achievement_progress(ach_id))
	return result

func get_unlocked_count() -> int:
	"""Obtener número de logros desbloqueados"""
	var count = 0
	for ach_id in _unlocked:
		if _unlocked[ach_id]:
			count += 1
	return count

func get_total_count() -> int:
	"""Obtener número total de logros"""
	return ACHIEVEMENTS.size()

func is_unlocked(achievement_id: String) -> bool:
	"""Verificar si un logro está desbloqueado"""
	return _unlocked.get(achievement_id, false)

func reset_all() -> void:
	"""Resetear todos los logros (solo para debug)"""
	if not OS.is_debug_build():
		push_warning("[SteamAchievements] reset_all() solo funciona en debug builds")
		return
	
	_unlocked.clear()
	_stats = TRACKED_STATS.duplicate(true)
	_boss_kill_tracker.clear()
	
	# Resetear en Steam
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if steam_mgr and steam_mgr.is_steam_available:
		steam_mgr.clear_all_achievements()
	
	_save_to_save_manager()
	print("[SteamAchievements] ⚠️ Todos los logros reseteados")

# ═══════════════════════════════════════════════════════════════════════════════
# TRACKING DE EVENTOS DE JUEGO
# ═══════════════════════════════════════════════════════════════════════════════

func on_run_started() -> void:
	"""Llamar al inicio de cada run"""
	# Resetear stats per-run
	_stats["run_enemies_killed"] = 0
	_stats["max_level_reached"] = 0

func on_run_ended(run_data: Dictionary) -> void:
	"""Llamar al final de cada run con los datos de la partida"""
	# ACH_FIRST_RUN
	check_and_unlock("ACH_FIRST_RUN")
	
	# Incrementar total runs
	increment_stat("total_runs", 1)
	
	# Actualizar mayor duración
	var duration_minutes = run_data.get("duration", 0.0) / 60.0
	set_stat("longest_run_minutes", int(duration_minutes))
	
	# Actualizar total de enemigos globales
	var enemies = run_data.get("enemies_defeated", 0)
	increment_stat("total_enemies_killed", enemies)
	
	# Guardar stats
	_save_to_save_manager()

func on_enemy_killed(_enemy_id: String, _enemy_tier: int, is_boss: bool, boss_id: String = "") -> void:
	"""Llamar cuando un enemigo es derrotado"""
	increment_stat("run_enemies_killed", 1)
	
	if is_boss:
		# ACH_FIRST_BOSS
		check_and_unlock("ACH_FIRST_BOSS")
		
		# Trackear boss fast kill
		if _boss_fight_start_time > 0.0:
			var fight_duration = (Time.get_ticks_msec() / 1000.0) - _boss_fight_start_time
			if fight_duration < 30.0:
				check_and_unlock("ACH_BOSS_FAST_KILL")
			_boss_fight_start_time = 0.0
		
		# Trackear no-hit boss
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and _boss_fight_hp_at_start > 0:
			var current_hp = 0
			if player_node.has_method("get_current_health"):
				current_hp = player_node.get_current_health()
			elif player_node.get("health_component"):
				current_hp = player_node.health_component.current_health
			
			if current_hp >= _boss_fight_hp_at_start:
				check_and_unlock("ACH_NO_HIT_BOSS")
		
		# Track unique bosses
		if not boss_id.is_empty():
			_boss_kill_tracker[boss_id] = true
			set_stat("unique_bosses_defeated", _boss_kill_tracker.size())
			_save_to_save_manager()

func on_boss_spawned() -> void:
	"""Llamar cuando aparece un boss"""
	_boss_fight_start_time = Time.get_ticks_msec() / 1000.0
	
	# Capturar HP del jugador al iniciar boss fight
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		if player_node.has_method("get_current_health"):
			_boss_fight_hp_at_start = player_node.get_current_health()
		elif player_node.get("health_component"):
			_boss_fight_hp_at_start = player_node.health_component.current_health

func on_level_up(new_level: int) -> void:
	"""Llamar cuando el jugador sube de nivel"""
	set_stat("max_level_reached", new_level)

func on_mage_unlocked(total_unlocked: int) -> void:
	"""Llamar cuando se desbloquea un mago"""
	set_stat("mages_unlocked", total_unlocked)

func on_fusion_created() -> void:
	"""Llamar cuando se crea una fusión de armas"""
	check_and_unlock("ACH_FIRST_FUSION")

func on_weapons_equipped(weapon_count: int) -> void:
	"""Llamar cuando cambia el número de armas equipadas"""
	if weapon_count >= 6:
		check_and_unlock("ACH_MAX_WEAPONS")

# ═══════════════════════════════════════════════════════════════════════════════
# PERSISTENCIA LOCAL
# ═══════════════════════════════════════════════════════════════════════════════

func _load_from_save() -> void:
	"""Cargar estado de achievements desde SaveManager"""
	var save_mgr = get_node_or_null("/root/SaveManager")
	if not save_mgr:
		return
	
	var save_data = save_mgr.current_save_data
	if save_data.is_empty():
		return
	
	var ach_data = save_data.get("achievements", {})
	
	# Cargar unlocked
	_unlocked = ach_data.get("unlocked", {}).duplicate(true)
	
	# Cargar stats
	var saved_stats = ach_data.get("stats", {})
	for stat_name in saved_stats:
		if _stats.has(stat_name):
			_stats[stat_name] = saved_stats[stat_name]
	
	# Cargar boss tracker
	_boss_kill_tracker = ach_data.get("boss_tracker", {}).duplicate(true)
	
	# Cargar pendientes
	_pending_sync = ach_data.get("pending_sync", []).duplicate()

func _save_to_save_manager() -> void:
	"""Guardar estado de achievements en SaveManager"""
	var save_mgr = get_node_or_null("/root/SaveManager")
	if not save_mgr:
		return
	
	if save_mgr.current_save_data.is_empty():
		return
	
	save_mgr.current_save_data["achievements"] = {
		"unlocked": _unlocked.duplicate(true),
		"stats": _stats.duplicate(true),
		"boss_tracker": _boss_kill_tracker.duplicate(true),
		"pending_sync": _pending_sync.duplicate()
	}
	
	# No llamar save_game_data aquí para evitar recursión
	# El SaveManager guardará en la próxima oportunidad

# ═══════════════════════════════════════════════════════════════════════════════
# INTEGRACIÓN STEAM
# ═══════════════════════════════════════════════════════════════════════════════

func _set_steam_achievement(achievement_id: String) -> void:
	"""Establecer achievement en Steam"""
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if not steam_mgr or not steam_mgr.is_steam_available:
		# Guardar para sincronizar después
		if achievement_id not in _pending_sync:
			_pending_sync.append(achievement_id)
		return
	
	steam_mgr.set_achievement(achievement_id)

func _set_steam_stat(stat_name: String, value: int) -> void:
	"""Establecer stat en Steam"""
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if not steam_mgr or not steam_mgr.is_steam_available:
		return
	
	steam_mgr.set_stat(stat_name, value)

func _pull_stats_from_steam() -> void:
	"""Obtener stats desde Steam (fuente de verdad si disponible)"""
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if not steam_mgr or not steam_mgr.is_steam_available:
		return
	
	for stat_name in _stats:
		var steam_value = steam_mgr.get_stat(stat_name)
		if steam_value > _stats[stat_name]:
			_stats[stat_name] = steam_value
	
	# Verificar achievements desde Steam
	for ach_id in ACHIEVEMENTS:
		if not _unlocked.get(ach_id, false):
			var steam_unlocked = steam_mgr.get_achievement(ach_id)
			if steam_unlocked:
				_unlocked[ach_id] = true
	
	_save_to_save_manager()

func _sync_pending_achievements() -> void:
	"""Sincronizar achievements pendientes cuando Steam vuelve a estar disponible"""
	if _pending_sync.is_empty():
		return
	
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if not steam_mgr or not steam_mgr.is_steam_available:
		return
	
	print("[SteamAchievements] Sincronizando %d achievements pendientes..." % _pending_sync.size())
	for ach_id in _pending_sync:
		steam_mgr.set_achievement(ach_id)
	
	_pending_sync.clear()
	_save_to_save_manager()

func _check_stat_achievements(stat_name: String) -> void:
	"""Verificar si algún achievement se desbloquea por este stat"""
	for ach_id in ACHIEVEMENTS:
		var ach = ACHIEVEMENTS[ach_id]
		if ach.get("stat_name", "") == stat_name:
			var target = ach.get("stat_target", 0)
			if _stats.get(stat_name, 0) >= target:
				check_and_unlock(ach_id)
