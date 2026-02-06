# SteamManager.gd
# Wrapper para GodotSteam - Funciona en modo offline si Steam no está disponible
# Autoload: SteamManager

extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal steam_initialized(success: bool)
signal leaderboard_loaded(leaderboard_name: String, entries: Array)
signal leaderboard_score_uploaded(success: bool, score: int)
signal user_stats_received(success: bool)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const APP_ID: int = 0  # Cambiar al App ID real de Steam cuando se tenga
const LEADERBOARD_PREFIX: String = "monthly_score_"

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var is_steam_available: bool = false
var is_initialized: bool = false
var steam_id: int = 0
var steam_name: String = "Offline Player"
var _steam: Object = null  # Referencia a GodotSteam singleton

# Cache de leaderboards
var _leaderboard_handles: Dictionary = {}  # name -> handle
var _cached_entries: Dictionary = {}  # name -> Array[RankingEntry]

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_try_initialize_steam()

func _try_initialize_steam() -> void:
	"""Intentar inicializar Steam si GodotSteam está disponible"""
	# GDExtension: Verificar si la clase Steam existe
	if ClassDB.class_exists("Steam"):
		_initialize_steam()
	# Módulo compilado: Verificar singleton
	elif Engine.has_singleton("Steam"):
		_steam = Engine.get_singleton("Steam")
		_initialize_steam()
	else:
		print("[SteamManager] ⚠️ GodotSteam no disponible - Modo offline activado")
		is_steam_available = false
		is_initialized = true
		steam_initialized.emit(false)

func _initialize_steam() -> void:
	"""Inicializar Steam SDK"""
	# En GDExtension, Steam es una clase global, no un singleton
	# Usamos call para llamar métodos estáticamente
	var init_result = null
	
	# Intentar usar GDExtension (clase Steam directa)
	if ClassDB.class_exists("Steam"):
		# Crear instancia temporal para acceder a métodos
		var steam_class = ClassDB.instantiate("Steam")
		if steam_class:
			init_result = steam_class.steamInitEx(false, APP_ID)
			_steam = steam_class
	# Fallback a singleton si existe
	elif _steam != null:
		init_result = _steam.steamInitEx(false, APP_ID)
	
	if init_result == null:
		print("[SteamManager] ❌ No se pudo inicializar Steam")
		is_steam_available = false
		is_initialized = true
		steam_initialized.emit(false)
		return
	
	if init_result.status == 0:  # k_ESteamAPIInitResult_OK
		is_steam_available = true
		is_initialized = true
		
		# Obtener información del usuario
		steam_id = _steam.getSteamID()
		steam_name = _steam.getPersonaName()
		
		# Conectar señales de Steam
		_connect_steam_signals()
		
		print("[SteamManager] ✅ Steam inicializado - Usuario: %s (ID: %d)" % [steam_name, steam_id])
		steam_initialized.emit(true)
	else:
		print("[SteamManager] ❌ Error inicializando Steam: %s" % init_result.verbal)
		is_steam_available = false
		is_initialized = true
		steam_initialized.emit(false)

func _connect_steam_signals() -> void:
	"""Conectar señales de Steam para callbacks"""
	if _steam == null:
		return
	
	_steam.leaderboard_find_result.connect(_on_leaderboard_find_result)
	_steam.leaderboard_score_uploaded.connect(_on_leaderboard_score_uploaded)
	_steam.leaderboard_scores_downloaded.connect(_on_leaderboard_scores_downloaded)

func _process(_delta: float) -> void:
	"""Procesar callbacks de Steam"""
	if is_steam_available and _steam != null:
		_steam.run_callbacks()

# ═══════════════════════════════════════════════════════════════════════════════
# LEADERBOARDS
# ═══════════════════════════════════════════════════════════════════════════════

func get_current_month_leaderboard_name() -> String:
	"""Obtener nombre del leaderboard del mes actual"""
	var date = Time.get_datetime_dict_from_system()
	return "%s%04d_%02d" % [LEADERBOARD_PREFIX, date.year, date.month]

func request_leaderboard(leaderboard_name: String = "") -> void:
	"""Solicitar un leaderboard de Steam"""
	if leaderboard_name.is_empty():
		leaderboard_name = get_current_month_leaderboard_name()
	
	if not is_steam_available:
		# Modo offline: Devolver datos de ejemplo
		_emit_offline_leaderboard(leaderboard_name)
		return
	
	if _steam != null:
		_steam.findOrCreateLeaderboard(leaderboard_name, 2, 1)  # Descending, Numeric

func request_top_entries(count: int = 100, leaderboard_name: String = "") -> void:
	"""Solicitar las mejores N entradas del leaderboard"""
	if leaderboard_name.is_empty():
		leaderboard_name = get_current_month_leaderboard_name()
	
	if not is_steam_available:
		_emit_offline_leaderboard(leaderboard_name)
		return
	
	if _leaderboard_handles.has(leaderboard_name):
		var handle = _leaderboard_handles[leaderboard_name]
		if _steam != null:
			_steam.downloadLeaderboardEntries(1, count, 0, handle)  # Global
	else:
		# Primero buscar el leaderboard, luego descargar
		request_leaderboard(leaderboard_name)

func upload_score(score: int, build_data: Dictionary = {}, leaderboard_name: String = "") -> void:
	"""Subir puntuación al leaderboard de Steam"""
	if leaderboard_name.is_empty():
		leaderboard_name = get_current_month_leaderboard_name()
	
	if not is_steam_available:
		print("[SteamManager] ⚠️ Modo offline - Score no subido: %d" % score)
		leaderboard_score_uploaded.emit(false, score)
		return
	
	if _leaderboard_handles.has(leaderboard_name):
		var handle = _leaderboard_handles[leaderboard_name]
		
		# Serializar build data para los detalles (máximo 64 int32)
		var details = _serialize_build_data(build_data)
		
		if _steam != null:
			_steam.uploadLeaderboardScore(score, true, details, handle)
	else:
		# Guardar score pendiente y buscar leaderboard primero
		# Por simplicidad, solo log
		print("[SteamManager] ⚠️ Leaderboard no encontrado, solicitando...")
		request_leaderboard(leaderboard_name)

func _serialize_build_data(build_data: Dictionary) -> PackedInt32Array:
	"""Serializar build data a int32 array para Steam (máx 64 ints = 256 bytes)"""
	# Por ahora, retornar array vacío
	# TODO: Implementar serialización comprimida de la build
	return PackedInt32Array()

func _deserialize_build_data(_details: PackedInt32Array) -> Dictionary:
	"""Deserializar build data desde int32 array"""
	# TODO: Implementar deserialización
	return {}

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS DE STEAM
# ═══════════════════════════════════════════════════════════════════════════════

func _on_leaderboard_find_result(handle: int, found: int) -> void:
	"""Callback cuando se encuentra/crea un leaderboard"""
	if found == 1 and handle != 0:
		var leaderboard_name = get_current_month_leaderboard_name()
		_leaderboard_handles[leaderboard_name] = handle
		print("[SteamManager] ✅ Leaderboard encontrado: %s (handle: %d)" % [leaderboard_name, handle])

func _on_leaderboard_score_uploaded(success: int, _score: int, score_changed: int, _rank: int, _rank_prev: int) -> void:
	"""Callback cuando se sube un score"""
	var uploaded = success == 1
	print("[SteamManager] Score uploaded: %s (changed: %s)" % [uploaded, score_changed == 1])
	leaderboard_score_uploaded.emit(uploaded, _score)

func _on_leaderboard_scores_downloaded(message: String, entries: Array) -> void:
	"""Callback cuando se descargan entries del leaderboard"""
	var leaderboard_name = get_current_month_leaderboard_name()
	
	var parsed_entries: Array = []
	for entry in entries:
		parsed_entries.append({
			"rank": entry.get("global_rank", 0),
			"steam_id": entry.get("steam_id", 0),
			"steam_name": _get_player_name(entry.get("steam_id", 0)),
			"score": entry.get("score", 0),
			"build_data": _deserialize_build_data(entry.get("details", PackedInt32Array()))
		})
	
	_cached_entries[leaderboard_name] = parsed_entries
	print("[SteamManager] ✅ Descargadas %d entradas del leaderboard" % parsed_entries.size())
	leaderboard_loaded.emit(leaderboard_name, parsed_entries)

func _get_player_name(player_steam_id: int) -> String:
	"""Obtener nombre de un jugador por su Steam ID"""
	if _steam != null and player_steam_id > 0:
		return _steam.getFriendPersonaName(player_steam_id)
	return "Player_%d" % player_steam_id

# ═══════════════════════════════════════════════════════════════════════════════
# MODO OFFLINE (DATOS DE EJEMPLO)
# ═══════════════════════════════════════════════════════════════════════════════

func _emit_offline_leaderboard(leaderboard_name: String) -> void:
	"""Emitir leaderboard vacío para modo offline"""
	var offline_entries: Array = []
	
	# Nota: No generamos datos falsos - solo mostramos que está offline
	# Cuando Steam esté conectado, se cargarán los datos reales
	
	_cached_entries[leaderboard_name] = offline_entries
	leaderboard_loaded.emit(leaderboard_name, offline_entries)

func get_cached_entries(leaderboard_name: String = "") -> Array:
	"""Obtener entries cacheadas de un leaderboard"""
	if leaderboard_name.is_empty():
		leaderboard_name = get_current_month_leaderboard_name()
	
	return _cached_entries.get(leaderboard_name, [])

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

func get_current_player_info() -> Dictionary:
	"""Obtener información del jugador actual"""
	return {
		"steam_id": steam_id,
		"steam_name": steam_name,
		"is_online": is_steam_available
	}

func format_score(score: int) -> String:
	"""Formatear score con separadores de miles"""
	var score_str = str(score)
	var formatted = ""
	var count = 0
	
	for i in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = score_str[i] + formatted
		count += 1
	
	return formatted
