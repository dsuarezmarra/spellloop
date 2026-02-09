extends Node2D
class_name Game

## Escena principal del juego
## Coordina todos los sistemas durante una partida

# Nodos principales
@onready var world_root: Node2D = $WorldRoot
@onready var arena_root: Node2D = $WorldRoot/ArenaRoot
@onready var player_container: Node2D = $PlayerContainer
@onready var enemies_root: Node2D = $WorldRoot/EnemiesRoot
@onready var pickups_root: Node2D = $WorldRoot/PickupsRoot
@onready var projectiles_root: Node2D = $WorldRoot/ProjectilesRoot
@onready var ui_layer: CanvasLayer = $UILayer
@onready var camera: Camera2D = $Camera2D

# Referencias a sistemas
var player: CharacterBody2D = null
var player_stats: Node = null  # Sistema de stats del jugador
var arena_manager: Node = null
var enemy_manager: Node = null
var experience_manager: Node = null
var wave_manager: Node = null
var hud: CanvasLayer = null
var pause_menu: Control = null
var game_over_screen: Control = null
var damage_vignette: CanvasLayer = null  # Efecto de daño estilo Binding of Isaac
var chest_spawner: Node = null  # Sistema de spawn de cofres tipo tienda
var ambient_atmosphere: Node = null # Sistema de partículas ambientales

# Estado del juego
var game_running: bool = false
var game_time: float = 0.0
var session_start_time: float = 0.0 # Tiempo de juego al iniciar/resumir esta sesión
var is_paused: bool = false

# Contadores de Reroll/Banish persistentes para toda la partida
# Balance:
# - Reroll (3): permite re-randomizar opciones de level up
# - Banish (2): elimina una opción permanentemente del pool
# - Skip: siempre disponible, sin límite
var remaining_rerolls: int = 3
var remaining_banishes: int = 2

# Cola de level ups pendientes (para manejar múltiples subidas de nivel consecutivas)
var pending_level_ups: Array = []
var level_up_panel_active: bool = false

# Estadísticas de la partida
var run_stats: Dictionary = {
	"time": 0.0,
	"level": 1,
	"kills": 0,
	"xp_total": 0,
	"gold": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"bosses_killed": 0,
	"elites_killed": 0,
	"healing_done": 0
}

# Versión del juego para compatibilidad de datos
const GAME_VERSION = "0.1.0-alpha"

# Flag para saber si estamos reanudando una partida
var _is_resuming: bool = false
var _saved_state: Dictionary = {}

# Flag para saber si la pausa fue por pérdida de foco (auto-pause)
var _paused_by_focus_loss: bool = false

# Telemetría: último minuto registrado
var _last_telemetry_minute: int = -1

func _ready() -> void:
	# Game debe procesar siempre para manejar input de pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

	if OS.is_debug_build():
		pass # _security_scan_tree() # Function not defined - Disabled

	# Verificar si hay una partida guardada para reanudar
	if SessionState and SessionState.can_resume():
		_is_resuming = true
		_saved_state = SessionState.get_saved_state()

	_setup_game()

func _notification(what: int) -> void:
	# Pausar automáticamente cuando el juego pierde el foco
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if game_running and not is_paused and not level_up_panel_active:
				# Solo auto-pausar si NO estaba ya pausado por otro motivo
				if not get_tree().paused:
					_paused_by_focus_loss = true
					_pause_game()
					
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Solo despausar si fue pausado por pérdida de foco Y no hay otro bloqueante (como LevelUp)
			if _paused_by_focus_loss and is_paused:
				# Verificar si algo más ha pausado el juego mientras estábamos fuera (raro pero posible)
				# o si hay menús abiertos que requieran pausa
				var can_resume = true
				
				# Si hay popups abiertos (Cofres, LevelUp, etc), NO despausar
				# Chequear si el árbol sigue pausado por otra razón
				if level_up_panel_active:
					can_resume = false
				
				# Chequear si hay cofres abiertos
				if chest_spawner and chest_spawner.is_chest_open:
					can_resume = false
					
				if can_resume:
					_paused_by_focus_loss = false
					_resume_game()
				else:
					# Si no podemos reanudar, limpiamos el flag para que el usuario deba despausar manual o cerrar el menú
					_paused_by_focus_loss = false

func _setup_game() -> void:
	# Resetear estado de la partida
	remaining_rerolls = 3
	remaining_banishes = 2
	pending_level_ups.clear()
	level_up_panel_active = false
	
	# Crear sistemas CRÍTICOS (Stats) antes que nada
	_create_player_stats()  # IMPORTANTE: Crear antes que el player

	# Crear player
	_create_player()

	# Crear arena (debe ser antes de otros sistemas para que tengan contexto)
	_create_arena_manager()

	# Crear gestores de rendimiento (deben existir antes de otros sistemas)
	_create_spawn_budget_manager()  # Limita spawns por frame
	_create_vfx_pool()              # Pool de partículas

	# Crear otros sistemas
	_create_enemy_manager()
	_create_wave_manager()  # Pasa _is_resuming para skip_auto_init
	_create_experience_manager()
	_create_chest_spawner()  # Sistema de cofres tipo tienda
	_create_pickup_pool()    # Pool de monedas y pickups
	_create_resource_manager() # Carga recursos pesados

	# Crear UI
	_create_ui()

	# Configurar cámara
	_setup_camera()

	# 5. Inicializar sistemas
	_initialize_systems()
	
	# 6. GUARD RAIL: Verificar integridad del runtime (Debug Check)
	if OS.is_debug_build():
		_verify_runtime_integrity()

func _verify_runtime_integrity() -> void:
	# Assert fail si encontramos nodos de QA/Debug en el arbol principal
	# Esto previene regresiones donde el MainMenu o Autoloads cargan tests inadvertidamente.
	var forbidden_nodes = ["ItemTestRunner", "StructureValidator", "TestRunner", "CalibrationSuite"]
	for node_name in forbidden_nodes:
		if get_tree().root.find_child(node_name, true, false):
			push_error("CRITICAL: Forbidden Debug Node '%s' found in Runtime Scene!" % node_name)
			# En un entorno estricto, esto deberia crashear:
			assert(false, "FATAL: Debug/QA dependency leaked into Runtime! Check MainMenu or Autoloads.")


	# Comenzar o reanudar partida
	if _is_resuming:
		_resume_saved_game()
	else:
		_start_game()

func _create_player() -> void:
	var player_scene = load("res://scenes/player/LoopiaLikePlayer.tscn")
	if player_scene:
		player = player_scene.instantiate()
		player_container.add_child(player)

		# Si estamos reanudando, restaurar posición
		if _is_resuming and _saved_state.has("player_position"):
			var pos_data = _saved_state["player_position"]
			# Convertir de diccionario {x, y} a Vector2
			if pos_data is Dictionary:
				player.global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
			elif pos_data is Vector2:
				player.global_position = pos_data
			else:
				player.global_position = Vector2.ZERO
		else:
			player.global_position = Vector2.ZERO

		# Configurar el personaje seleccionado (sprites, etc.)
		_configure_player_character()

		# Debug desactivado: print("🧙 [Game] Player creado")
	else:
		push_error("[Game] No se pudo cargar SpellloopPlayer.tscn")

func _configure_player_character() -> void:
	"""Configurar el player segun el personaje seleccionado"""
	if not player:
		return

	var character_id = "frost_mage"  # Default
	if SessionState:
		character_id = SessionState.get_character()
		# Debug desactivado: print("[Game] SessionState.get_character() returned: '%s'" % character_id)

	# Si esta vacio, usar default
	if character_id.is_empty():
		character_id = "frost_mage"
		# Debug desactivado: print("[Game] Character ID was empty, using default: frost_mage")

	# Debug desactivado: print("[Game] Configuring player with character: %s" % character_id)

	# Obtener datos del personaje
	var char_data = CharacterDatabase.get_character(character_id)
	if char_data.is_empty():
		push_warning("[Game] Character not found: " + character_id)
		return

	var sprite_folder = char_data.get("sprite_folder", "frost_mage")
	# Debug desactivado: print("[Game] Sprite folder for %s: %s" % [character_id, sprite_folder])

	# Configurar la carpeta de sprites si el player tiene el metodo
	if player.has_method("set_character_sprites"):
		# Debug desactivado: print("[Game] Calling player.set_character_sprites('%s')" % sprite_folder)
		player.set_character_sprites(sprite_folder)
	else:
		push_warning("[Game] Player does not have set_character_sprites method!")

	# Guardar el ID del personaje en el player para referencia
	if "character_id" in player:
		player.character_id = character_id

func _create_arena_manager() -> void:
	var am_script = load("res://scripts/core/ArenaManager.gd")
	if am_script:
		arena_manager = am_script.new()
		arena_manager.name = "ArenaManager"
		add_child(arena_manager)

		# Si estamos reanudando, usar el seed guardado
		var seed_to_use: int = -1  # -1 significa generar aleatorio
		if _is_resuming and _saved_state.has("arena_seed"):
			seed_to_use = _saved_state["arena_seed"]

		# Inicializar con player y nodo raíz de arena
		arena_manager.initialize(player, arena_root, seed_to_use)

		# Conectar señales
		if arena_manager.has_signal("player_zone_changed"):
			arena_manager.player_zone_changed.connect(_on_player_zone_changed)
			# Conectar update de atmósfera
			arena_manager.player_zone_changed.connect(_update_atmosphere_biome)
			
		if arena_manager.has_signal("player_hit_boundary"):
			arena_manager.player_hit_boundary.connect(_on_player_hit_boundary)
	else:
		push_error("[Game] No se pudo cargar ArenaManager.gd")

func _create_player_stats() -> void:
	var ps_script = load("res://scripts/core/PlayerStats.gd")
	if ps_script:
		player_stats = ps_script.new()
		player_stats.name = "PlayerStats"
		add_child(player_stats)

		# Inicializar stats desde el personaje seleccionado
		var character_id = "frost_mage"  # Default
		if SessionState:
			character_id = SessionState.get_character()

		if player_stats.has_method("initialize_from_character"):
			player_stats.initialize_from_character(character_id)

		# Conectar señales de stats
		if player_stats.has_signal("stat_changed"):
			player_stats.stat_changed.connect(_on_stat_changed)
		if player_stats.has_signal("level_changed"):
			player_stats.level_changed.connect(_on_player_level_changed)
	else:
		push_error("[Game] No se pudo cargar PlayerStats.gd")

func _create_enemy_manager() -> void:
	var em_script = load("res://scripts/core/EnemyManager.gd")
	if em_script:
		enemy_manager = em_script.new()
		enemy_manager.name = "EnemyManager"
		add_child(enemy_manager)

		# Conectar señales
		if enemy_manager.has_signal("enemy_died"):
			enemy_manager.enemy_died.connect(_on_enemy_died)

func _create_wave_manager() -> void:
	var wm_script = load("res://scripts/managers/WaveManager.gd")
	if wm_script:
		wave_manager = wm_script.new()
		wave_manager.name = "WaveManager"

		# Si estamos reanudando, establecer bandera para saltar inicialización automática
		# El estado será restaurado luego por _resume_saved_game()
		if _is_resuming and _saved_state.has("wave_manager_state"):
			wave_manager.skip_auto_init = true

		add_child(wave_manager)

		# Conectar señales de WaveManager
		if wave_manager.has_signal("phase_changed"):
			wave_manager.phase_changed.connect(_on_phase_changed)
		if wave_manager.has_signal("wave_started"):
			wave_manager.wave_started.connect(_on_wave_started)
		if wave_manager.has_signal("boss_incoming"):
			wave_manager.boss_incoming.connect(_on_boss_incoming)
		if wave_manager.has_signal("boss_spawned"):
			wave_manager.boss_spawned.connect(_on_boss_spawned)
		if wave_manager.has_signal("boss_defeated"):
			wave_manager.boss_defeated.connect(_on_boss_defeated)
		if wave_manager.has_signal("elite_spawned"):
			wave_manager.elite_spawned.connect(_on_elite_spawned)
		if wave_manager.has_signal("special_event_started"):
			wave_manager.special_event_started.connect(_on_special_event_started)
		if wave_manager.has_signal("special_event_ended"):
			wave_manager.special_event_ended.connect(_on_special_event_ended)
		if wave_manager.has_signal("game_phase_infinite"):
			wave_manager.game_phase_infinite.connect(_on_game_phase_infinite)
	else:
		push_warning("[Game] No se pudo cargar WaveManager.gd - usando spawn básico")

func _create_experience_manager() -> void:
	var em_script = load("res://scripts/core/ExperienceManager.gd")
	if em_script:
		experience_manager = em_script.new()
		experience_manager.name = "ExperienceManager"
		add_child(experience_manager)

		# Conectar señales
		if experience_manager.has_signal("level_up"):
			experience_manager.level_up.connect(_on_level_up)
		if experience_manager.has_signal("exp_gained"):
			experience_manager.exp_gained.connect(_on_exp_gained)
		if experience_manager.has_signal("coin_collected"):
			experience_manager.coin_collected.connect(_on_coin_collected)

func _create_chest_spawner() -> void:
	var cs_script = load("res://scripts/managers/ChestSpawner.gd")
	if cs_script:
		chest_spawner = cs_script.new()
		chest_spawner.name = "ChestSpawner"
		add_child(chest_spawner)
		
		# Inicializar con referencias
		if chest_spawner.has_method("initialize"):
			chest_spawner.initialize(player, arena_manager, pickups_root)

func _create_pickup_pool() -> void:
	var pp_script = load("res://scripts/managers/PickupPool.gd")
	if pp_script:
		var pickup_pool = pp_script.new()
		pickup_pool.name = "PickupPool"
		add_child(pickup_pool)
	else:
		push_error("[Game] No se pudo cargar PickupPool.gd")

func _create_resource_manager() -> void:
	var rm_script = load("res://scripts/managers/ResourceManager.gd")
	if rm_script:
		var resource_manager = rm_script.new()
		resource_manager.name = "ResourceManager"
		add_child(resource_manager)
	else:
		push_error("[Game] No se pudo cargar ResourceManager.gd")

func _create_vfx_pool() -> void:
	"""Crear pool de VFX para evitar stutters por partículas"""
	var vfx_script = load("res://scripts/managers/VFXPool.gd")
	if vfx_script:
		var vfx_pool = vfx_script.new()
		vfx_pool.name = "VFXPool"
		add_child(vfx_pool)
	else:
		push_warning("[Game] No se pudo cargar VFXPool.gd - VFX usarán fallback")

func _create_spawn_budget_manager() -> void:
	"""Crear gestor de budget de spawn para limitar instanciación por frame"""
	var sbm_script = load("res://scripts/managers/SpawnBudgetManager.gd")
	if sbm_script:
		var spawn_budget = sbm_script.new()
		spawn_budget.name = "SpawnBudgetManager"
		add_child(spawn_budget)
	else:
		push_warning("[Game] No se pudo cargar SpawnBudgetManager.gd - sin límite de spawn")

func _create_ui() -> void:
	# HUD
	var hud_scene = load("res://scenes/ui/GameHUD.tscn")
	if hud_scene:
		hud = hud_scene.instantiate()
		ui_layer.add_child(hud)

	# Menú de pausa
	var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
	if pause_scene:
		pause_menu = pause_scene.instantiate()
		ui_layer.add_child(pause_menu)
		pause_menu.resume_pressed.connect(_on_resume_game)
		# Las referencias se inicializarán después en _initialize_systems()

	# Pantalla de Game Over
	var gameover_scene = load("res://scenes/ui/GameOverScreen.tscn")
	if gameover_scene:
		game_over_screen = gameover_scene.instantiate()
		ui_layer.add_child(game_over_screen)
		# Conectar señales del game over
		game_over_screen.retry_pressed.connect(_on_game_over_retry)
		game_over_screen.menu_pressed.connect(_on_game_over_menu)

func _setup_camera() -> void:
	if camera:
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0

	# Crear sistema de feedback de daño (vignette + partículas en bordes)
	_setup_damage_feedback()

func _setup_damage_feedback() -> void:
	"""Configurar el sistema de feedback visual de daño estilo Binding of Isaac"""
	# Cargar y crear DamageVignette
	var DamageVignetteScript = load("res://scripts/ui/DamageVignette.gd")
	if DamageVignetteScript:
		damage_vignette = DamageVignetteScript.new()
		damage_vignette.name = "DamageVignette"
		add_child(damage_vignette)

	# Cargar y crear AmbientAtmosphere
	var atmosphere_script = load("res://scripts/visuals/AmbientAtmosphere.gd")
	if atmosphere_script:
		ambient_atmosphere = atmosphere_script.new()
		ambient_atmosphere.name = "AmbientAtmosphere"
		add_child(ambient_atmosphere)
		if player:
			ambient_atmosphere.initialize(player)
	else:
		push_warning("[Game] No se encontró AmbientAtmosphere.gd")

	# Conectar señal de daño del player
	if player:
		# Buscar el BasePlayer dentro de SpellloopPlayer
		var base_player = _get_base_player()
		if base_player and base_player.has_signal("player_took_damage"):
			base_player.player_took_damage.connect(_on_player_took_damage)
		# Conectar señal de muerte del player
		if base_player and base_player.has_signal("player_died"):
			base_player.player_died.connect(_on_player_died)

func _get_base_player() -> Node:
	"""Obtener referencia al BasePlayer (puede estar dentro de SpellloopPlayer)"""
	if player:
		# Si es SpellloopPlayer, el wizard_player es el BasePlayer
		if "wizard_player" in player and player.wizard_player:
			return player.wizard_player
		# Si ya es BasePlayer
		if player.has_signal("player_took_damage"):
			return player
	return null

func _on_player_took_damage(damage: int, element: String) -> void:
	"""Callback cuando el player recibe daño - activa feedback visual"""
	# Trackear daño recibido para estadísticas
	run_stats["damage_taken"] += damage
	
	# Screen shake
	if camera and camera.has_method("damage_shake"):
		camera.damage_shake(damage)
	elif camera:
		# Shake manual si no es GameCamera
		_manual_camera_shake(damage)

	# Vignette y partículas
	if damage_vignette and damage_vignette.has_method("show_damage_effect"):
		damage_vignette.show_damage_effect(damage, element)

func _manual_camera_shake(damage: int) -> void:
	"""Screen shake manual para Camera2D estándar"""
	var intensity = clampf(float(damage) / 30.0, 0.15, 0.6)
	var shake_offset = Vector2(
		randf_range(-12, 12) * intensity,
		randf_range(-12, 12) * intensity
	)

	var original_offset = camera.offset
	camera.offset = shake_offset

	# Crear tween para restaurar
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "offset", original_offset, 0.2)

func _physics_process(_delta: float) -> void:
	# La cámara sigue al player
	if camera and player:
		camera.global_position = player.global_position

func _initialize_systems() -> void:
	# Inicializar PlayerStats primero (otros sistemas pueden depender de el)
	if player_stats:
		# Obtener AttackManager del player si existe
		var attack_mgr = null
		if player and player.has_method("get_attack_manager"):
			attack_mgr = player.get_attack_manager()
		elif player and "wizard_player" in player and player.wizard_player:
			attack_mgr = player.wizard_player.get("attack_manager")

		if player_stats.has_method("initialize"):
			player_stats.initialize(attack_mgr, player)  # Pasar player para que health_regen funcione
		# Debug desactivado: print("📊 [Game] PlayerStats inicializado")

	# Inicializar con referencias
	if enemy_manager and player:
		enemy_manager.initialize(player)

		# Si WaveManager está activo, deshabilitar spawn automático del EnemyManager
		# WaveManager controlará los spawns
		if wave_manager:
			enemy_manager.enable_spawning(false)

	if experience_manager and player:
		experience_manager.initialize(player)

	# Configurar WaveManager con referencias
	if wave_manager:
		wave_manager.enemy_manager = enemy_manager
		wave_manager.player = player

	# Conectar HUD con el player
	_connect_hud_to_player()

	# Debug desactivado: print("✅ [Game] Sistemas inicializados")

func _connect_hud_to_player() -> void:
	## Conectar el HUD para que reciba actualizaciones del player
	if not hud or not player:
		return

	# Conectar señales del player al HUD si existen
	if player.has_signal("health_changed") and hud.has_method("update_health"):
		if not player.health_changed.is_connected(hud.update_health):
			player.health_changed.connect(hud.update_health)
			
	# Conectar AttackManager para actualizar iconos de armas en HUD
	var attack_manager_ref = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager_ref and attack_manager_ref.has_signal("weapon_added"):
		if not attack_manager_ref.weapon_added.is_connected(_on_weapon_changed_update_hud):
			attack_manager_ref.weapon_added.connect(_on_weapon_changed_update_hud)
		if attack_manager_ref.has_signal("weapon_removed"):
			if not attack_manager_ref.weapon_removed.is_connected(_on_weapon_changed_update_hud):
				attack_manager_ref.weapon_removed.connect(_on_weapon_changed_update_hud)
		# Conectar weapon_leveled_up para sincronizar nivel en HUD
		if attack_manager_ref.has_signal("weapon_leveled_up"):
			if not attack_manager_ref.weapon_leveled_up.is_connected(_on_weapon_leveled_up_update_hud):
				attack_manager_ref.weapon_leveled_up.connect(_on_weapon_leveled_up_update_hud)
		# Force initial update
		_update_hud_weapons_from_attack_manager(attack_manager_ref)

	# Conectar Coin updates (ExperienceManager)
	if experience_manager and experience_manager.has_signal("coin_collected"):
		# Check signature: coin_collected(amount, total)
		if not experience_manager.coin_collected.is_connected(hud.update_coins):
			experience_manager.coin_collected.connect(hud.update_coins)

	# Actualización inicial del HUD
	if player.has_method("get_health") and hud.has_method("update_health"):
		var health = player.get_health()
		hud.update_health(health.current, health.max)
	if hud.has_method("update_exp") and experience_manager:
		hud.update_exp(experience_manager.current_exp, experience_manager.exp_to_next_level)

	# Debug desactivado: print("📊 [Game] HUD conectado al player")

func _start_game() -> void:
	game_running = true
	game_time = 0.0
	session_start_time = 0.0
	is_paused = false
	
	# Iniciar música de gameplay
	AudioManager.play_music("music_gameplay_loop")

	# CRÍTICO: Resetear AttackManager para nueva partida
	# Esto limpia armas, stats y mejoras de la partida anterior
	var attack_manager = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager and attack_manager.has_method("reset_for_new_game"):
		attack_manager.reset_for_new_game()

	# Resetear stats
	run_stats = {
		"time": 0.0,
		"level": 1,
		"kills": 0,
		"xp_total": 0,
		"gold": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"bosses_killed": 0,
		"elites_killed": 0,
		"healing_done": 0
	}

	# Debug desactivado: print("🚀 [Game] ¡Partida iniciada!")
	
	# Forzar actualización del HUD de armas después de que todo esté inicializado
	call_deferred("_deferred_weapon_hud_update")
	
	# BALANCE TELEMETRY: Start run logging
	_start_balance_telemetry()

func _resume_saved_game() -> void:
	"""Restaurar el estado de una partida guardada"""
	game_running = true
	is_paused = false

	# Restaurar tiempo de juego
	game_time = _saved_state.get("game_time", 0.0)
	session_start_time = game_time # Marcar incio de esta sesión de juego

	# Restaurar tiempo en WaveManager para que la dificultad sea correcta
	if wave_manager:
		wave_manager.game_time_seconds = game_time
		wave_manager.game_time_minutes = game_time / 60.0

	# Restaurar stats de la partida
	run_stats["time"] = game_time
	run_stats["level"] = _saved_state.get("player_level", 1)
	
	# Restaurar run_stats completo si existe (kills, damage, etc)
	if _saved_state.has("run_stats"):
		var saved_run_stats = _saved_state["run_stats"]
		run_stats["kills"] = saved_run_stats.get("kills", 0)
		run_stats["xp_total"] = saved_run_stats.get("xp_total", 0)
		run_stats["gold"] = saved_run_stats.get("gold", 0)
		run_stats["damage_dealt"] = saved_run_stats.get("damage_dealt", 0)
		run_stats["damage_taken"] = saved_run_stats.get("damage_taken", 0)
		run_stats["bosses_killed"] = saved_run_stats.get("bosses_killed", 0)
		run_stats["elites_killed"] = saved_run_stats.get("elites_killed", 0)
		run_stats["healing_done"] = saved_run_stats.get("healing_done", 0)

	# IMPORTANTE: Esperar un frame para que HealthComponent._ready() ya haya ejecutado
	# antes de restaurar el HP (evita que _ready() sobrescriba nuestro valor)
	call_deferred("_restore_player_hp_deferred")

	# Restaurar stats del jugador
	if player_stats and _saved_state.has("player_stats"):
		var saved_stats = _saved_state.get("player_stats", {})

		# Usar from_dict() si está disponible (método preferido)
		if player_stats.has_method("from_dict"):
			player_stats.from_dict(saved_stats)
			# Debug desactivado: print("🎒 [Game] PlayerStats restaurado via from_dict()")
		else:
			pass  # Bloque else
			# Fallback: restaurar manualmente
			# Restaurar historial de mejoras PRIMERO
			if saved_stats.has("collected_upgrades") and "collected_upgrades" in player_stats:
				player_stats.collected_upgrades = saved_stats.get("collected_upgrades", []).duplicate(true)
				# Debug desactivado: print("🎒 [Game] Mejoras coleccionadas restauradas: %d items" % player_stats.collected_upgrades.size())

			# Restaurar stats desde el sub-diccionario "stats" si existe
			var actual_stats = saved_stats.get("stats", saved_stats)
			for stat_name in actual_stats:
				var value = actual_stats[stat_name]
				# Solo procesar valores numéricos
				if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
					if player_stats.has_method("set_stat"):
						player_stats.set_stat(stat_name, value)
					elif "stats" in player_stats and stat_name in player_stats.stats:
						player_stats.stats[stat_name] = value

		# Restaurar nivel (siempre, desde el estado principal)
		if "level" in player_stats:
			player_stats.level = _saved_state.get("player_level", 1)

	# Restaurar experiencia
	if experience_manager and _saved_state.has("current_exp"):
		experience_manager.current_exp = _saved_state.get("current_exp", 0)
		experience_manager.exp_to_next_level = _saved_state.get("exp_to_next_level", 10)
		if "total_exp" in experience_manager:
			experience_manager.total_exp = _saved_state.get("total_exp", 0)
		if "current_level" in experience_manager:
			experience_manager.current_level = _saved_state.get("player_level", 1)

	# Restaurar monedas - ExperienceManager usa total_coins
	if experience_manager and _saved_state.has("coins"):
		var saved_coins = _saved_state.get("coins", 0)
		if "total_coins" in experience_manager:
			experience_manager.total_coins = saved_coins
			# Debug desactivado: print("🪙 [Game] Monedas restauradas: %d" % saved_coins)

	# Restaurar mejoras globales de armas (GlobalWeaponStats)
	var attack_manager = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager and _saved_state.has("global_weapon_stats"):
		if "global_weapon_stats" in attack_manager and attack_manager.global_weapon_stats:
			if attack_manager.global_weapon_stats.has_method("from_dict"):
				attack_manager.global_weapon_stats.from_dict(_saved_state.get("global_weapon_stats", {}))
				# Debug desactivado: print("⚔️ [Game] Mejoras globales restauradas")

	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Restaurar estado del EnemyManager PRIMERO (todos los enemigos activos)
	# Esto debe hacerse antes de WaveManager para que el boss esté disponible
	# ═══════════════════════════════════════════════════════════════════════════════
	if enemy_manager and _saved_state.has("enemy_manager_state"):
		if enemy_manager.has_method("from_save_data"):
			enemy_manager.from_save_data(_saved_state.get("enemy_manager_state", {}))
			# Debug desactivado: print("👹 [Game] Estado de EnemyManager restaurado")
		else:
			push_warning("[Game] EnemyManager no tiene método from_save_data")

	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Restaurar estado del WaveManager (fase, oleadas, boss, elites, eventos)
	# Debe hacerse DESPUÉS de EnemyManager para encontrar el boss restaurado
	# ═══════════════════════════════════════════════════════════════════════════════
	if wave_manager and _saved_state.has("wave_manager_state"):
		if wave_manager.has_method("from_save_data"):
			wave_manager.from_save_data(_saved_state.get("wave_manager_state", {}))
			# Debug desactivado: print("🌊 [Game] Estado de WaveManager restaurado")
		else:
			push_warning("[Game] WaveManager no tiene método from_save_data")

	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Restaurar estado del ArenaManager (zonas desbloqueadas, biomas)
	# ═══════════════════════════════════════════════════════════════════════════════
	if arena_manager and _saved_state.has("arena_manager_state"):
		if arena_manager.has_method("from_save_data"):
			arena_manager.from_save_data(_saved_state.get("arena_manager_state", {}))
			# Debug desactivado: print("🏟️ [Game] Estado de ArenaManager restaurado")
		else:
			push_warning("[Game] ArenaManager no tiene método from_save_data")

	# ═══════════════════════════════════════════════════════════════════════════════
	# Restaurar contadores de Reroll y Banish del LevelUpPanel
	# ═══════════════════════════════════════════════════════════════════════════════
	if _saved_state.has("remaining_rerolls"):
		remaining_rerolls = _saved_state.get("remaining_rerolls", 3)
	if _saved_state.has("remaining_banishes"):
		remaining_banishes = _saved_state.get("remaining_banishes", 2)
	# Debug desactivado: print("🎲 [Game] Rerolls/Banishes restaurados: %d/%d" % [remaining_rerolls, remaining_banishes])

	# TODO: Si queremos restaurar armas adicionales más allá de la inicial, se haría aquí

	# Actualizar HUD con los valores restaurados
	call_deferred("_update_hud_after_restore")

	# Limpiar el estado guardado DESPUÉS de restaurar todo (diferido)
	# No lo limpiamos aquí porque _restore_player_hp_deferred necesita _saved_state
	call_deferred("_clear_saved_state_deferred")

	# Debug desactivado: print("🔄 [Game] ¡Partida reanudada!")
	# Debug desactivado: print("   - Tiempo: %.1f segundos" % game_time)
	# Debug desactivado: print("   - Nivel: %d" % _saved_state.get("player_level", 1))
	# Debug desactivado: print("   - HP: %d/%d" % [_saved_state.get("player_hp", 100), _saved_state.get("player_max_hp", 100)])
	# Debug desactivado: print("   - Monedas: %d" % _saved_state.get("coins", 0))
	# Debug desactivado: print("   - XP: %d/%d" % [_saved_state.get("current_exp", 0), _saved_state.get("exp_to_next_level", 10)])

func _restore_player_hp_deferred() -> void:
	"""
	Restaurar HP del jugador de forma diferida.
	Se llama después de que HealthComponent._ready() haya ejecutado.
	"""
	if not player or _saved_state.is_empty():
		return

	if not _saved_state.has("player_hp"):
		return

	var saved_hp = _saved_state.get("player_hp", 100)
	var saved_max_hp = _saved_state.get("player_max_hp", 100)

	# Debug desactivado: print("🔄 [Game] _restore_player_hp_deferred() - Restaurando HP: %d/%d" % [saved_hp, saved_max_hp])

	# Buscar HealthComponent en las ubicaciones posibles
	var health_component = null

	# 1. En SpellloopPlayer.health_component (referencia directa)
	if "health_component" in player and player.health_component:
		health_component = player.health_component

	# 2. En wizard_player
	if not health_component and "wizard_player" in player and player.wizard_player:
		if "health_component" in player.wizard_player:
			health_component = player.wizard_player.health_component
		else:
			health_component = player.wizard_player.get_node_or_null("HealthComponent")

	# 3. Como nodo hijo directo
	if not health_component:
		health_component = player.get_node_or_null("HealthComponent")

	# 4. Dentro de WizardPlayer como nodo
	if not health_component:
		var wp = player.get_node_or_null("WizardPlayer")
		if wp:
			health_component = wp.get_node_or_null("HealthComponent")

	if health_component:
		# HealthComponent usa current_health/max_health, NO current_hp/max_hp
		if health_component.has_method("set_health"):
			health_component.set_health(saved_hp, saved_max_hp)
		else:
			if "max_health" in health_component:
				health_component.max_health = saved_max_hp
			elif "max_hp" in health_component:
				health_component.max_hp = saved_max_hp

			if "current_health" in health_component:
				health_component.current_health = saved_hp
			elif "current_hp" in health_component:
				health_component.current_hp = saved_hp

		# Emitir señal de cambio de salud para actualizar UI
		if health_component.has_signal("health_changed"):
			health_component.health_changed.emit(saved_hp, saved_max_hp)

		# Debug desactivado: print("✅ [Game] HP restaurado correctamente: %d/%d" % [health_component.current_health, health_component.max_health])
	else:
		push_warning("[Game] WARNING - No se pudo encontrar HealthComponent para restaurar HP")

func _update_hud_after_restore() -> void:
	"""Actualizar HUD después de restaurar partida guardada"""
	if not hud:
		return

	# Actualizar nivel
	var level = _saved_state.get("player_level", 1)
	if hud.has_method("update_level"):
		hud.update_level(level)
	elif "level_label" in hud and hud.level_label:
		hud.level_label.text = "Lv. %d" % level

	# Actualizar XP
	var current_exp = _saved_state.get("current_exp", 0)
	var exp_to_next = _saved_state.get("exp_to_next_level", 10)
	if hud.has_method("update_exp"):
		hud.update_exp(current_exp, exp_to_next)
	elif "exp_bar" in hud and hud.exp_bar:
		hud.exp_bar.value = float(current_exp) / maxf(float(exp_to_next), 1.0) * 100.0

	# Actualizar monedas - update_coins(amount, total)
	var coins = _saved_state.get("coins", 0)
	if hud.has_method("update_coins"):
		hud.update_coins(0, coins)  # amount=0 porque no es una moneda nueva, solo actualizar total
	elif "coins_label" in hud and hud.coins_label:
		hud.coins_label.text = str(coins)

	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Actualizar barra de vida
	# ═══════════════════════════════════════════════════════════════════════════════
	var saved_hp = _saved_state.get("player_hp", 100)
	var saved_max_hp = _saved_state.get("player_max_hp", 100)
	if hud.has_method("update_health"):
		hud.update_health(saved_hp, saved_max_hp)

	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Actualizar barra de escudo
	# ═══════════════════════════════════════════════════════════════════════════════
	if player_stats and hud.has_method("update_shield"):
		var current_shield = int(player_stats.get_stat("shield_amount"))
		var max_shield = int(player_stats.get_stat("max_shield"))
		hud.update_shield(current_shield, max_shield)

	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Actualizar contador de enemigos
	# ═══════════════════════════════════════════════════════════════════════════════
	if enemy_manager and hud.has_method("update_kills"):
		var kill_count = 0
		if "enemies_killed" in enemy_manager:
			kill_count = enemy_manager.enemies_killed
		elif enemy_manager.has_method("get_kill_count"):
			kill_count = enemy_manager.get_kill_count()
		hud.update_kills(kill_count)

	# Debug desactivado: print("📊 [Game] HUD actualizado después de restaurar")

func _clear_saved_state_deferred() -> void:
	"""Limpiar estado guardado después de que todo se haya restaurado"""
	SessionState.clear_game_state()

func _process(delta: float) -> void:
	# Sistema de prioridad de popups:
	# Si ya no estamos pausados (ej. cofre cerrado) y hay level ups pendientes, mostrarlos
	if not get_tree().paused and not level_up_panel_active and not pending_level_ups.is_empty():
		_process_next_level_up()

	# Si el juego está pausado (por menú o por popups externos), no avanzar tiempo
	if not game_running or is_paused or get_tree().paused:
		return

	# Actualizar tiempo
	game_time += delta
	run_stats["time"] = game_time

	# Actualizar HUD
	_update_hud()
	
	# BALANCE TELEMETRY: Check for minute snapshot
	_check_telemetry_minute_snapshot()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if game_running and not is_paused:
			_pause_game()

func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true  # Pausar el árbol del juego
	AudioManager.pause_music(true)
	# Debug desactivado: print("⏸️ [Game] Juego pausado - is_paused=%s, tree.paused=%s" % [is_paused, get_tree().paused])
	if pause_menu and not _paused_by_focus_loss:
		pause_menu.show_pause_menu(game_time)

func _resume_game() -> void:
	"""Reanudar el juego (usado por auto-pause al recuperar foco)"""
	if level_up_panel_active:
		return
	is_paused = false
	get_tree().paused = false
	AudioManager.pause_music(false)

func _on_resume_game() -> void:
	# Solo reanudar si no hay level up activo
	if level_up_panel_active:
		return
	is_paused = false
	get_tree().paused = false  # Reanudar el árbol del juego
	AudioManager.pause_music(false)
	# Debug desactivado: print("▶️ [Game] Juego reanudado - is_paused=%s, tree.paused=%s" % [is_paused, get_tree().paused])

func _update_hud() -> void:
	if not hud:
		return

	# Actualizar stats en el HUD
	if hud.has_method("update_time"):
		hud.update_time(game_time)

	if hud.has_method("update_level") and experience_manager:
		hud.update_level(experience_manager.current_level)

	if hud.has_method("update_exp") and experience_manager:
		hud.update_exp(experience_manager.current_exp, experience_manager.exp_to_next_level)

	if hud.has_method("update_health") and player and player.has_method("get_health"):
		var health_data = player.get_health()
		hud.update_health(health_data.current, health_data.max)

func _on_enemy_died(death_position: Vector2, enemy_type: String, exp_value: int, enemy_tier: int = 1, is_elite: bool = false, is_boss: bool = false) -> void:
	run_stats["kills"] += 1
	
	# Trackear elites y bosses por separado
	if is_elite:
		run_stats["elites_killed"] += 1
	if is_boss:
		run_stats["bosses_killed"] += 1
	
	if hud and hud.has_method("update_kills"):
		hud.update_kills(run_stats["kills"])

	# XP AUTOMÁTICO - Se da con un pequeño delay para mejor feedback visual
	# BALANCE PASS 3: Bonus XP para elites/bosses en Phase 3 (+25%)
	var final_exp = exp_value
	if (is_elite or is_boss) and exp_value > 0:
		var difficulty_manager = get_node_or_null("/root/DifficultyManager")
		if not difficulty_manager:
			var managers = get_tree().get_nodes_in_group("difficulty_manager")
			if managers.size() > 0:
				difficulty_manager = managers[0]
		if difficulty_manager and difficulty_manager.has_method("get_current_phase"):
			var current_phase = difficulty_manager.get_current_phase()
			if current_phase >= 3:
				final_exp = int(exp_value * 1.25)  # +25% XP en Phase 3
	
	if experience_manager and final_exp > 0:
		_grant_exp_delayed(final_exp)

	# MONEDAS - Caen al suelo para que el player las recoja
	if experience_manager:
		experience_manager.spawn_coins_from_enemy(death_position, enemy_tier, is_elite, is_boss)

	# ═══════════════════════════════════════════════════════════════════════════
	# SISTEMA DE RECOMPENSAS (Nuevo)
	# ═══════════════════════════════════════════════════════════════════════════
	var enemy_info = {"tier": enemy_tier, "is_elite": is_elite, "is_boss": is_boss, "id": enemy_type}
	# Determinar recompensas
	var rewards = {}
	if is_boss:
		# Los jefes usan su propia base de datos de loot
		var boss_id = enemy_info.get("id", "default")
		rewards = BossDatabase.get_boss_loot(boss_id)
	else:
		# Enemigos normales/elites/raros usan RaresDatabase
		rewards = RaresDatabase.get_rewards_for_enemy(enemy_info)
	
	# 1. Cofres
	var spawn_chest = false
	if rewards.get("guaranteed_chest", false):
		spawn_chest = true
	elif randf() < rewards.get("chest_chance", 0.0):
		spawn_chest = true
		
	if spawn_chest:
		_spawn_reward_chest(position, rewards)
	
	# 2. Orbes de Mejora (Items directos)
	if randf() < rewards.get("upgrade_chance", 0.0):
		# TODO: Implementar orbe visual, por ahora damos cofre extra de menor calidad o moneda especial
		# _spawn_upgrade_orb(position)
		pass

	# ═══════════════════════════════════════════════════════════════════════════
	# EFECTOS ESPECIALES DE KILL
	# ═══════════════════════════════════════════════════════════════════════════

	# KILL HEAL - Curar al matar enemigos
	if player_stats and player:
		var kill_heal_amount = player_stats.get_stat("kill_heal") if player_stats.has_method("get_stat") else 0
		if kill_heal_amount > 0 and player.has_method("heal"):
			player.heal(int(kill_heal_amount))
			# Mostrar texto flotante de curación (usar class_name FloatingText)
			FloatingText.spawn_heal(player.global_position + Vector2(0, -30), int(kill_heal_amount))

	# EXPLOSION ON KILL - Explosión al matar
	if player_stats and is_instance_valid(player):
		var explosion_chance = player_stats.get_stat("explosion_chance") if player_stats.has_method("get_stat") else 0.0
		if explosion_chance > 0.0 and randf() < explosion_chance:
			var explosion_damage = player_stats.get_stat("explosion_damage") if player_stats.has_method("get_stat") else 50.0
			_trigger_kill_explosion(position, explosion_damage)

func _grant_exp_delayed(exp_value: int) -> void:
	"""Otorgar experiencia con un pequeño delay para mejor feedback visual.
	   Permite ver la muerte del enemigo antes de que aparezca el panel de level up."""
	const EXP_DELAY := 0.5  # Segundos de delay antes de dar XP
	
	# Usar SceneTreeTimer: process_always=false para respetar la pausa del juego
	var timer = get_tree().create_timer(EXP_DELAY, false)
	timer.timeout.connect(
		func(): 
			if experience_manager and is_instance_valid(experience_manager):
				experience_manager.grant_exp_from_kill(exp_value)
	)

func _spawn_reward_chest(pos: Vector2, rewards_config: Dictionary) -> void:
	"""Spawnear un cofre de recompensa"""
	var chest_scene = load("res://scenes/interactables/TreasureChest.tscn")
	if not chest_scene:
		push_warning("⚠️ No se encontró TreasureChest.tscn")
		return

	var chest = chest_scene.instantiate()
	
	# Determinar tipo
	var type_str = rewards_config.get("chest_type", "normal")
	var type_enum = TreasureChest.ChestType.NORMAL
	match type_str:
		"elite": type_enum = TreasureChest.ChestType.ELITE
		"boss": type_enum = TreasureChest.ChestType.BOSS
		"weapon": type_enum = TreasureChest.ChestType.WEAPON
	
	# Añadir a la escena (PickupsRoot si existe, sino root)
	if pickups_root:
		pickups_root.add_child(chest)
	else:
		world_root.add_child(chest)
	
	# Inicializar
	# rarity_boost: aumenta la rareza mínima
	var rarity_min = -1
	if rewards_config.has("chest_rarity_min"):
		rarity_min = rewards_config.chest_rarity_min
	elif rewards_config.has("chest_rarity_boost"):
		# Lógica simple: boost = rareza mínima 1 (azul)
		rarity_min = 1 
		
	chest.initialize(pos, type_enum, player, rarity_min)


func _trigger_kill_explosion(pos: Vector2, damage: float) -> void:
	"""Explosión al matar enemigos (kill_explosion effect)"""
	var explosion_radius = 100.0  # Radio de explosión fijo

	# --- EFECTO VISUAL ---
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color_ramp = Gradient.new()
	particles.color_ramp.add_point(0.0, Color(1, 0.5, 0)) # Naranja
	particles.color_ramp.add_point(0.5, Color(1, 0, 0))   # Rojo
	particles.color_ramp.add_point(1.0, Color(0.2, 0, 0, 0)) # Fade out
	particles.global_position = pos
	particles.z_index = 20 # Sobre enemigos
	
	# Auto-destrucción visual
	add_child(particles) # Add to Game node/scene
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)
	
	# --- LÓGICA DE DAÑO ---
	# Encontrar enemigos cercanos
	if enemy_manager and enemy_manager.has_method("get_enemies_in_range"):
		var enemies_hit = enemy_manager.get_enemies_in_range(pos, explosion_radius)
		for enemy in enemies_hit:
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				enemy.take_damage(int(damage), "explosion", null)

	# Crear efecto visual de explosión
	var explosion = Node2D.new()
	explosion.name = "KillExplosion"
	explosion.top_level = true
	explosion.z_index = 50
	explosion.global_position = pos

	var root_scene = get_tree().current_scene
	if root_scene:
		root_scene.add_child(explosion)
	else:
		add_child(explosion)

	# Crear sprite visual
	var visual = Sprite2D.new()
	visual.name = "ExplosionVisual"
	var texture_path = "res://assets/sprites/effects/explosion_effect.png"
	if ResourceLoader.exists(texture_path):
		visual.texture = load(texture_path)
	else:
		pass  # Bloque else
		# Crear un círculo simple si no hay textura
		var circle = CircleShape2D.new()
		circle.radius = explosion_radius
	explosion.add_child(visual)

	# Animación de expansión y desvanecimiento
	var tween = explosion.create_tween()
	explosion.scale = Vector2(0.3, 0.3)
	explosion.modulate = Color(1.0, 0.5, 0.0, 1.0)  # Naranja
	tween.tween_property(explosion, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(explosion, "modulate", Color(1.0, 0.3, 0.0, 0.0), 0.3)
	tween.tween_callback(explosion.queue_free)

func _on_exp_gained(_amount: int, total: int) -> void:
	run_stats["xp_total"] = total

func _on_level_up(new_level: int, _upgrades: Array) -> void:
	run_stats["level"] = new_level

	# Añadir a la cola de level ups pendientes
	pending_level_ups.append(new_level)

	# Solo mostrar panel si no hay uno activo Y no hay pausa externa (ej. cofres)
	if not level_up_panel_active and not get_tree().paused:
		_process_next_level_up()

func _process_next_level_up() -> void:
	"""Procesar el siguiente level up de la cola"""
	if pending_level_ups.is_empty():
		# No hay más level ups pendientes - reanudar juego
		level_up_panel_active = false
		is_paused = false
		get_tree().paused = false
		return

	# Tomar el siguiente nivel de la cola
	var level = pending_level_ups.pop_front()
	level_up_panel_active = true
	_show_level_up_panel(level)

func _show_level_up_panel(_level: int) -> void:
	"""Mostrar el panel de selección de mejoras al subir nivel"""
	var panel_scene = load("res://scenes/ui/LevelUpPanel.tscn")
	if not panel_scene:
		push_error("[Game] No se pudo cargar LevelUpPanel.tscn")
		return

	var panel = panel_scene.instantiate()
	ui_layer.add_child(panel)

	# Inicializar con referencias
	var attack_mgr = null
	if player and player.has_method("get_attack_manager"):
		attack_mgr = player.get_attack_manager()
	elif player and "attack_manager" in player:
		attack_mgr = player.attack_manager
	elif player and "wizard_player" in player and player.wizard_player:
		attack_mgr = player.wizard_player.get("attack_manager")

	# Usar el PlayerStats de Game (no del player)
	var stats = player_stats

	if panel.has_method("initialize"):
		panel.initialize(attack_mgr, stats)

	# Configurar contadores de reroll/banish desde PlayerStats (fuente única de verdad)
	# Game.gd ahora solo observa pero no mantiene contadores paralelos
	if stats and panel.has_method("set_reroll_count"):
		panel.set_reroll_count(stats.current_rerolls)
	if stats and panel.has_method("set_banish_count"):
		panel.set_banish_count(stats.current_banishes)

	# Conectar señales
	if panel.has_signal("option_selected"):
		panel.option_selected.connect(_on_level_up_option_selected)
	if panel.has_signal("panel_closed"):
		panel.panel_closed.connect(_on_level_up_panel_closed)
	if panel.has_signal("reroll_used"):
		panel.reroll_used.connect(_on_reroll_used)
	if panel.has_signal("banish_used"):
		panel.banish_used.connect(_on_banish_used)

	# Pausar el juego y actualizar estado interno
	is_paused = true
	get_tree().paused = true

	# Mostrar panel
	if panel.has_method("show_panel"):
		panel.show_panel()

	# Debug desactivado: print("🆙 [Game] Panel de level up mostrado (nivel %d)" % level)

func _on_level_up_option_selected(_option: Dictionary) -> void:
	"""Callback cuando se selecciona una mejora en el level up"""
	# Debug desactivado: print("🆙 [Game] Mejora seleccionada: %s" % option.get("name", "???"))
	# Nota: La mejora ya se aplica en LevelUpPanel._apply_option()
	pass

func _on_level_up_panel_closed() -> void:
	"""Callback cuando se cierra el panel de level up"""
	# Debug desactivado: print("🆙 [Game] Panel de level up cerrado")

	# Procesar el siguiente level up de la cola (si hay)
	# Esto también reanudará el juego si no hay más pendientes
	_process_next_level_up()

func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	"""Callback cuando cambia un stat del jugador - propagar al player"""
	# Debug desactivado: print("📊 [Game] Stat cambiado: %s = %.2f" % [stat_name, new_value])

	# Manejar mejoras de reroll/banish - PlayerStats ya maneja esto internamente
	# Solo logueamos si es necesario
	if stat_name == "reroll_count":
		var diff = int(new_value) - int(old_value)
		if diff > 0:
			# PlayerStats.apply_upgrade_effect() ya incrementa current_rerolls
			# Debug desactivado: print("🎲 [Game] +%d rerolls por mejora" % diff)
			pass
		return
	elif stat_name == "banish_count":
		var diff = int(new_value) - int(old_value)
		if diff > 0:
			# PlayerStats.apply_upgrade_effect() ya incrementa current_banishes
			# Debug desactivado: print("🚫 [Game] +%d banishes por mejora" % diff)
			pass
		return

	# Propagar cambios relevantes al player
	if player and player.has_method("modify_stat"):
		match stat_name:
			"move_speed":
				# PlayerStats usa multiplicador relativo al base (1.0), convertir a absoluto
				var base_speed = 220.0
				player.wizard_player.move_speed = base_speed * new_value
				player.move_speed = player.wizard_player.move_speed
				# Debug desactivado: print("📊 [Game] Velocidad del player actualizada: %.1f" % player.move_speed)
			"max_health":
				if player.has_method("increase_max_health"):
					var diff = new_value - player.wizard_player.max_hp
					if diff != 0:
						player.increase_max_health(int(diff))
			"pickup_range":
				player.modify_stat("pickup_range", new_value)
			"pickup_range_flat":
				player.modify_stat("pickup_range_flat", new_value)
			"shield_amount", "max_shield":
				if hud and hud.has_method("update_shield"):
					# Obtener ambos valores para actualizar la barra correctamente
					var current = player_stats.get_stat("shield_amount")
					var max_s = player_stats.get_stat("max_shield")
					hud.update_shield(int(current), int(max_s))

func _on_player_level_changed(new_level: int) -> void:
	"""Callback cuando sube el nivel del jugador (desde PlayerStats)"""
	run_stats["level"] = new_level
	# Debug desactivado: print("📊 [Game] Nivel del jugador: %d" % new_level)

func _on_reroll_used() -> void:
	"""Callback cuando se usa un reroll - PlayerStats ya lo decrementó"""
	# remaining_rerolls ya no se usa, PlayerStats.current_rerolls es la fuente de verdad
	pass

func _on_banish_used(_option_index: int) -> void:
	"""Callback cuando se usa un banish - PlayerStats ya lo decrementó"""
	# remaining_banishes ya no se usa, PlayerStats.current_banishes es la fuente de verdad
	pass

func _on_coin_collected(value: int, total: int) -> void:
	## Callback cuando se recoge una moneda
	run_stats["coins"] = total

	# Actualizar HUD
	if hud and hud.has_method("update_coins"):
		hud.update_coins(value, total)

func _on_player_zone_changed(_zone_id: int, zone_name: String) -> void:
	## Callback cuando el player cambia de zona
	# Debug desactivado: print("🏟️ [Game] Player cambió a zona: %s (id=%d)" % [zone_name, zone_id])

	# Actualizar UI si es necesario
	if hud and hud.has_method("update_zone"):
		var biome_name = ""
		if arena_manager:
			biome_name = arena_manager.get_biome_at_position(player.global_position)
		hud.update_zone(zone_name, biome_name)

func _on_player_hit_boundary(damage: float) -> void:
	## Callback cuando el player toca el borde de la arena
	if player and player.has_method("take_damage"):
		player.take_damage(damage)

func _on_player_died() -> void:
	"""Callback cuando el player muere - después de la animación de muerte"""
	player_died()

func player_died() -> void:
	"""Llamar cuando el player muere - Game Over"""
	if not game_running:
		return  # Evitar múltiples llamadas

	# Guardar tiempo jugado en esta sesión
	save_session_playtime()

	game_running = false
	
	# BALANCE TELEMETRY: End run logging
	_end_balance_telemetry("death")

	# Guardar estadísticas finales de la run
	_save_run_stats()

	# Pausar el spawn de enemigos
	if wave_manager and wave_manager.has_method("stop"):
		wave_manager.stop()

	# Detener la música y reproducir sonido de game over
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		if audio_manager.has_method("stop_music"):
			audio_manager.stop_music()

	# La animación de muerte es manejada por BasePlayer, que emite la señal AL TERMINAR.
	# Así que ya no esperamos aquí, mostramos Game Over inmediatamente.
	# await get_tree().create_timer(2.0).timeout

	# Mostrar pantalla de game over
	if game_over_screen:
		game_over_screen.show_game_over(run_stats)

func _save_run_stats() -> void:
	"""Guardar estadísticas completas de la run para persistencia y ranking"""
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("save_run_data"):
		# Recopilar TODOS los datos de la partida para el ranking
		var run_data = _collect_complete_run_data()
		save_manager.save_run_data(run_data)

func _collect_complete_run_data() -> Dictionary:
	"""Recopilar datos completos de la partida para ranking y estadísticas"""
	var run_data: Dictionary = {}
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 1. METADATOS Y VERSIÓN
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["game_version"] = GAME_VERSION
	run_data["timestamp"] = Time.get_unix_time_from_system()
	
	# Fecha formateada para filtros (año, mes, día)
	var datetime = Time.get_datetime_dict_from_system()
	run_data["date"] = {
		"year": datetime.get("year", 2026),
		"month": datetime.get("month", 1),
		"day": datetime.get("day", 1),
		"hour": datetime.get("hour", 0),
		"minute": datetime.get("minute", 0)
	}
	
	# Razón de fin de partida (muerte por defecto, puede sobrescribirse)
	run_data["end_reason"] = "death"
	
	# RunBundle: incluir run_id unificado y referencia al bundle
	var run_ctx = get_node_or_null("/root/RunContext")
	if run_ctx and run_ctx.run_id != "":
		run_data["run_id"] = run_ctx.run_id
	var bundle_mgr = get_node_or_null("/root/RunBundleManager")
	if bundle_mgr and bundle_mgr.has_method("get_bundle_path") and run_ctx:
		run_data["bundle_path"] = bundle_mgr.get_bundle_path(run_ctx.run_id)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 2. DATOS BÁSICOS DE LA PARTIDA
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["time_survived"] = run_stats.get("time", 0.0)
	run_data["duration"] = run_stats.get("time", 0.0)
	run_data["level_reached"] = run_stats.get("level", 1)
	run_data["enemies_defeated"] = run_stats.get("kills", 0)
	run_data["bosses_killed"] = run_stats.get("bosses_killed", 0)
	run_data["elites_killed"] = run_stats.get("elites_killed", 0)
	run_data["gold_collected"] = run_stats.get("gold", 0)
	run_data["damage_dealt"] = run_stats.get("damage_dealt", 0)
	run_data["damage_taken"] = run_stats.get("damage_taken", 0)
	run_data["healing_done"] = run_stats.get("healing_done", 0)
	run_data["xp_total"] = run_stats.get("xp_total", 0)
	run_data["score"] = _calculate_run_score()
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 2. PERSONAJE
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["character_id"] = _get_character_id()
	run_data["character_name"] = _get_character_display_name(run_data["character_id"])
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 3. ARMAS EQUIPADAS (con niveles y estado de fusión)
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["weapons"] = _collect_weapons_data()
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 4. ITEMS/UPGRADES OBTENIDOS
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["upgrades"] = _collect_upgrades_data()
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 5. STATS FINALES DEL JUGADOR
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["final_stats"] = _collect_final_stats()
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 6. DATOS DEL WAVE MANAGER (fase, tiempo de juego)
	# ═══════════════════════════════════════════════════════════════════════════
	if wave_manager:
		run_data["phase"] = wave_manager.get("current_phase") if "current_phase" in wave_manager else 1
		run_data["game_time_minutes"] = wave_manager.get("game_time_minutes") if "game_time_minutes" in wave_manager else 0.0
		run_data["game_time_seconds"] = wave_manager.get("game_time_seconds") if "game_time_seconds" in wave_manager else 0.0
	else:
		run_data["phase"] = 1
		run_data["game_time_minutes"] = 0.0
		run_data["game_time_seconds"] = 0.0
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 7. MECÁNICAS DE JUEGO (rerolls, banishes usados)
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["rerolls_used"] = 3 - remaining_rerolls
	run_data["banishes_used"] = 2 - remaining_banishes
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 8. DATOS DE AUDITORÍA DE COMBATE (RunAuditTracker)
	# ═══════════════════════════════════════════════════════════════════════════
	run_data["weapon_audit"] = _collect_weapon_audit_data()
	run_data["enemy_audit"] = _collect_enemy_audit_data()
	run_data["economy_audit"] = _collect_economy_audit_data()
	
	return run_data

func _collect_weapon_audit_data() -> Array:
	"""Recopilar datos de auditoría de armas desde RunAuditTracker"""
	var weapon_audit: Array = []
	if not RunAuditTracker or not RunAuditTracker.ENABLE_AUDIT:
		return weapon_audit
	
	for weapon_id in RunAuditTracker._weapon_stats:
		var ws = RunAuditTracker._weapon_stats[weapon_id]
		weapon_audit.append(ws.to_dict())
	
	# Ordenar por daño total descendente
	weapon_audit.sort_custom(func(a, b): return a.get("damage_total", 0) > b.get("damage_total", 0))
	return weapon_audit

func _collect_enemy_audit_data() -> Array:
	"""Recopilar datos de auditoría de enemigos desde RunAuditTracker"""
	var enemy_audit: Array = []
	if not RunAuditTracker or not RunAuditTracker.ENABLE_AUDIT:
		return enemy_audit
	
	for enemy_id in RunAuditTracker._enemy_damage_stats:
		var es = RunAuditTracker._enemy_damage_stats[enemy_id]
		enemy_audit.append(es.to_dict())
	
	# Ordenar por daño al jugador descendente
	enemy_audit.sort_custom(func(a, b): return a.get("damage_to_player", 0) > b.get("damage_to_player", 0))
	return enemy_audit

func _collect_economy_audit_data() -> Dictionary:
	"""Recopilar datos de economía desde RunAuditTracker"""
	if not RunAuditTracker or not RunAuditTracker.ENABLE_AUDIT:
		return {}
	
	return {
		"chests_opened": RunAuditTracker._chests_opened.duplicate(),
		"fusions_obtained": RunAuditTracker._fusions_obtained.size(),
		"rerolls_used": RunAuditTracker._rerolls_used,
		"gold_spent": RunAuditTracker._gold_spent,
	}

func _get_character_id() -> String:
	"""Obtener ID del personaje actual"""
	if SessionState and SessionState.has_method("get_character"):
		return SessionState.get_character()
	elif player and "character_id" in player:
		return player.character_id
	return "frost_mage"  # Default

func _get_character_display_name(character_id: String) -> String:
	"""Obtener nombre legible del personaje"""
	var names = {
		"frost_mage": "Mago de Hielo",
		"pyromancer": "Piromante",
		"arcanist": "Arcanista",
		"storm_caller": "Invocador de Tormentas",
		"shadow_blade": "Hoja Sombría",
		"wind_runner": "Corredor del Viento",
		"geomancer": "Geomante",
		"druid": "Druida",
		"void_walker": "Caminante del Vacío",
		"paladin": "Paladín"
	}
	return names.get(character_id, character_id.capitalize())

func _element_int_to_string(element_val: int) -> String:
	"""Convert element enum int to string for JSON serialization"""
	var element_names = ["ice", "fire", "lightning", "arcane", "shadow", "nature", "wind", "earth", "light", "void"]
	if element_val >= 0 and element_val < element_names.size():
		return element_names[element_val]
	return "physical"

func _collect_weapons_data() -> Array:
	"""Recopilar datos de armas equipadas con stats completos"""
	var weapons_data: Array = []
	var attack_manager = get_tree().get_first_node_in_group("attack_manager")
	
	if attack_manager and attack_manager.has_method("get_weapons"):
		var weapons_list = attack_manager.get_weapons()
		for weapon in weapons_list:
			var weapon_info: Dictionary = {}
			if weapon is BaseWeapon:
				# Convert element int to string for JSON serialization
				var element_str := _element_int_to_string(weapon.element if "element" in weapon else 0)
				weapon_info = {
					"id": weapon.id,
					"name": weapon.weapon_name,
					"name_es": weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.weapon_name,
					"level": weapon.level,
					"max_level": weapon.max_level if "max_level" in weapon else 8,
					"is_fused": weapon.is_fused if "is_fused" in weapon else false,
					"element": element_str,
					"icon": weapon.icon_path if "icon_path" in weapon else "",
					# Stats del arma
					"damage": weapon.damage if "damage" in weapon else 0,
					"cooldown": weapon.cooldown if "cooldown" in weapon else 1.0,
					"projectile_count": weapon.projectile_count if "projectile_count" in weapon else 1,
					"projectile_speed": weapon.projectile_speed if "projectile_speed" in weapon else 200,
					"area": weapon.area if "area" in weapon else 1.0,
					"weapon_range": weapon.weapon_range if "weapon_range" in weapon else 100,
					"knockback": weapon.knockback if "knockback" in weapon else 0,
					"duration": weapon.duration if "duration" in weapon else 0,
					"pierce": weapon.pierce if "pierce" in weapon else 0,
					"description": weapon.description if "description" in weapon else ""
				}
			elif weapon is Dictionary:
				# Convert element int/float to string for JSON serialization
				var raw_element = weapon.get("element", "")
				var element_str_dict := str(raw_element)
				if raw_element is int or raw_element is float:
					element_str_dict = _element_int_to_string(int(raw_element))
				weapon_info = {
					"id": weapon.get("id", weapon.get("weapon_id", "unknown")),
					"name": weapon.get("weapon_name", "Unknown"),
					"name_es": weapon.get("weapon_name_es", weapon.get("weapon_name", "Unknown")),
					"level": weapon.get("level", 1),
					"max_level": weapon.get("max_level", 8),
					"is_fused": weapon.get("is_fused", false),
					"element": element_str_dict,
					"icon": weapon.get("icon_path", ""),
					# Stats del arma
					"damage": weapon.get("damage", 0),
					"cooldown": weapon.get("cooldown", 1.0),
					"projectile_count": weapon.get("projectile_count", 1),
					"projectile_speed": weapon.get("projectile_speed", 200),
					"area": weapon.get("area", 1.0),
					"weapon_range": weapon.get("weapon_range", 100),
					"knockback": weapon.get("knockback", 0),
					"duration": weapon.get("duration", 0),
					"pierce": weapon.get("pierce", 0),
					"description": weapon.get("description", "")
				}
			if not weapon_info.is_empty():
				weapons_data.append(weapon_info)
	
	return weapons_data

func _collect_upgrades_data() -> Array:
	"""Recopilar datos de upgrades/items obtenidos"""
	var upgrades_data: Array = []
	
	if player_stats and player_stats.has_method("get_collected_upgrades"):
		var upgrades = player_stats.get_collected_upgrades()
		for upgrade in upgrades:
			var upgrade_info: Dictionary = {
				"id": upgrade.get("id", "unknown"),
				"name": upgrade.get("name", "Unknown"),
				"name_es": upgrade.get("name_es", upgrade.get("name", "Unknown")),
				"icon": upgrade.get("icon", ""),
				"tier": upgrade.get("tier", 1),
				"is_unique": upgrade.get("is_unique", false),
				"is_cursed": upgrade.get("is_cursed", false),
				"stacks": upgrade.get("stacks", 1),
				"description": upgrade.get("description", ""),
				"description_es": upgrade.get("description_es", upgrade.get("description", ""))
			}
			upgrades_data.append(upgrade_info)
	
	return upgrades_data

func _collect_final_stats() -> Dictionary:
	"""Recopilar stats finales del jugador"""
	var final_stats: Dictionary = {}
	
	if player_stats:
		# Stats principales
		if "max_health" in player_stats:
			final_stats["max_health"] = player_stats.max_health
		if "current_health" in player_stats:
			final_stats["current_health"] = player_stats.current_health
		if "level" in player_stats:
			final_stats["level"] = player_stats.level
		if "armor" in player_stats:
			final_stats["armor"] = player_stats.armor
		
		# Stats mediante get_stat()
		if player_stats.has_method("get_stat"):
			var stat_names = [
				"damage_mult", "attack_speed_mult", "move_speed",
				"crit_chance", "crit_damage", "life_steal",
				"pickup_range", "xp_mult", "cooldown_reduction",
				"projectile_speed", "projectile_count", "area_size"
			]
			for stat_name in stat_names:
				var value = player_stats.get_stat(stat_name)
				if value != null:
					final_stats[stat_name] = value
	
	return final_stats

func _calculate_run_score() -> int:
	"""
	BALANCE PASS 3: Scoring competitivo para ranking
	
	Fórmula diseñada para:
	- Premiar acción y riesgo, no solo supervivencia
	- Evitar estrategias AFK/tank que sobreviven sin matar
	- Escalar con tiempo pero con diminishing returns
	- Penalizar daño excesivo recibido
	
	Componentes:
	- Tiempo: 8 pts/seg (base, diminishing en ultra-late)
	- Kills: sqrt(kills) * 100 (evita farm infinito)
	- Elites: 750 pts cada uno
	- Bosses: 3000 pts cada uno
	- Level: 400 pts por nivel
	- Daño recibido: -1 pt por cada 20 HP
	- Kill rate bonus: si kills/min > 30, bonus +10%
	"""
	var time_seconds = run_stats.get("time", 0.0)
	var kills = run_stats.get("kills", 0)
	var elites = run_stats.get("elites_killed", 0)
	var bosses = run_stats.get("bosses_killed", 0)
	var level = run_stats.get("level", 1)
	var damage_taken = run_stats.get("damage_taken", 0)
	var gold = run_stats.get("gold", 0)
	
	var score: float = 0.0
	
	# Tiempo con soft diminishing después de 1 hora
	var time_minutes = time_seconds / 60.0
	if time_minutes <= 60:
		score += time_seconds * 8.0  # 8 pts/seg normal
	else:
		# Primeros 60 min a rate normal, después 50% rate
		score += 60.0 * 60.0 * 8.0  # 60 min a 8 pts/seg
		score += (time_seconds - 3600.0) * 4.0  # resto a 4 pts/seg
	
	# Kills con diminishing returns (sqrt) - premia matar pero no farm infinito
	score += sqrt(float(kills)) * 100.0
	
	# Bonus por elites (objetivo de alto valor)
	score += float(elites) * 750.0
	
	# Bonus por bosses (logro principal)
	score += float(bosses) * 3000.0
	
	# Nivel alcanzado
	score += float(level) * 400.0
	
	# Gold como bonus menor
	score += float(gold) * 0.5
	
	# Penalización por daño recibido (evita tank AFK)
	# -1 punto por cada 20 HP de daño recibido
	var damage_penalty = float(damage_taken) / 20.0
	score -= damage_penalty
	
	# Bonus por kill rate (incentiva acción constante)
	if time_minutes > 1.0:
		var kills_per_min = float(kills) / time_minutes
		if kills_per_min > 30.0:
			score *= 1.10  # +10% bonus por alta actividad
	
	return int(maxf(0.0, score))

func _on_game_over_retry() -> void:
	"""Reintentar partida desde el game over"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_game_over_menu() -> void:
	"""Volver al menú desde el game over"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func add_damage_stat(amount: int) -> void:
	run_stats["damage_dealt"] += amount

func add_gold_stat(amount: int) -> void:
	run_stats["gold"] += amount

func add_healing_stat(amount: int) -> void:
	"""Trackear curación para estadísticas"""
	run_stats["healing_done"] += amount

# ═══════════════════════════════════════════════════════════════════════════════
# BALANCE TELEMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _start_balance_telemetry() -> void:
	"""Initialize balance telemetry for this run"""
	var starting_weapons: Array = []
	var attack_manager = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager and attack_manager.has_method("get_weapons"):
		for w in attack_manager.get_weapons():
			starting_weapons.append({"id": w.id if "id" in w else "unknown", "lvl": w.level if "level" in w else 1})
	
	var seed_val = 0
	if arena_manager and "current_seed" in arena_manager:
		seed_val = arena_manager.current_seed
	
	var context = {
		"character_id": _get_character_id(),
		"starting_weapons": starting_weapons,
		"game_version": GAME_VERSION,
		"seed": seed_val
	}
	
	# RunContext: iniciar run unificada (ANTES de trackers)
	var run_ctx = get_node_or_null("/root/RunContext")
	if run_ctx:
		run_ctx.start_run(context)
	
	# RunBundleManager: crear bundle (ANTES de trackers para que redirijan)
	var bundle_mgr = get_node_or_null("/root/RunBundleManager")
	if bundle_mgr and bundle_mgr.has_method("begin_bundle"):
		bundle_mgr.begin_bundle(context)
	
	# BalanceTelemetry (existing)
	if BalanceTelemetry:
		BalanceTelemetry.start_run(context)
	
	# RunAuditTracker (new full audit system)
	var audit_tracker = get_node_or_null("/root/RunAuditTracker")
	if audit_tracker:
		audit_tracker.start_run(context)
	
	# UpgradeAuditor: iniciar auditoría de pickups
	var upgrade_auditor = get_node_or_null("/root/UpgradeAuditor")
	if upgrade_auditor and upgrade_auditor.has_method("start_run"):
		upgrade_auditor.start_run()

	# PerfTracker: iniciar contexto de run
	var perf_tracker = get_node_or_null("/root/PerfTracker")
	if perf_tracker and perf_tracker.has_method("start_run"):
		perf_tracker.start_run()

func _check_telemetry_minute_snapshot() -> void:
	"""Check if we should log a minute snapshot"""
	# Build context for snapshots
	var context = {
		"xp_total": run_stats.get("xp_total", 0),
		"xp_to_next": experience_manager.exp_to_next_level if experience_manager else 0,
		"level": run_stats.get("level", 1),
		"t_min": game_time / 60.0,
		"gold": run_stats.get("gold", 0),
		"kills": run_stats.get("kills", 0),
		"difficulty": {},
		"weapons": [],
		"player_stats": {}
	}
	
	# Get difficulty snapshot
	if BalanceTelemetry:
		context["difficulty"] = BalanceTelemetry.get_difficulty_snapshot()
		context["weapons"] = BalanceTelemetry.get_current_weapons_snapshot()
		context["top_upgrades"] = BalanceTelemetry.get_top_upgrades_snapshot()
		context["player_stats"] = BalanceTelemetry.get_player_stats_snapshot()
	# Fallback: read difficulty via RunContext (single entry point)
	if context["difficulty"].is_empty() or context["difficulty"].get("_warning", "") != "":
		var run_ctx = get_node_or_null("/root/RunContext")
		if run_ctx and run_ctx.has_method("get_difficulty_snapshot"):
			var snap = run_ctx.get_difficulty_snapshot()
			if snap.get("status", "") != "not_available":
				context["difficulty"] = snap
	
	# BalanceTelemetry minute snapshot
	if BalanceTelemetry and BalanceTelemetry.check_minute_snapshot(game_time):
		BalanceTelemetry.log_minute_snapshot(context)
	
	# RunAuditTracker minute tick (checks internally)
	var audit_tracker = get_node_or_null("/root/RunAuditTracker")
	if audit_tracker and audit_tracker.ENABLE_AUDIT:
		# Check if a minute has passed
		var current_minute = int(game_time / 60.0)
		if current_minute > audit_tracker._current_minute:
			audit_tracker.minute_tick(context)

func _end_balance_telemetry(reason: String = "death") -> void:
	"""Finalize balance telemetry for this run"""
	# ═══════════════════════════════════════════════════════════════════════════
	# 1. DEATH CONTEXT — ¿Qué mató al jugador?
	# ═══════════════════════════════════════════════════════════════════════════
	var killed_by := "unknown"
	var death_context := {}
	if player and player.has_method("get_death_context"):
		death_context = player.get_death_context()
		killed_by = death_context.get("killer", "unknown")

	# ═══════════════════════════════════════════════════════════════════════════
	# 2. DURATION — Del RunContext (ticks-precise)
	# ═══════════════════════════════════════════════════════════════════════════
	var run_ctx = get_node_or_null("/root/RunContext")
	var duration_s: float = 0.0
	if run_ctx:
		duration_s = run_ctx.get_elapsed_seconds()
	if duration_s <= 0.0:
		duration_s = game_time  # Fallback a game_time

	# ═══════════════════════════════════════════════════════════════════════════
	# 3. AUTHORITATIVE STATS — Fuentes correctas, no run_stats
	# ═══════════════════════════════════════════════════════════════════════════
	var debugger_metrics = BalanceDebugger.get_current_metrics() if BalanceDebugger else {}
	var damage_dealt = debugger_metrics.get("damage_dealt", {}).get("total", run_stats.get("damage_dealt", 0))
	var damage_taken = debugger_metrics.get("mitigation", {}).get("damage_final", run_stats.get("damage_taken", 0))
	var healing_done = int(debugger_metrics.get("sustain", {}).get("total", float(run_stats.get("healing_done", 0))))
	var xp_total = debugger_metrics.get("progression", {}).get("xp_total", run_stats.get("xp_total", 0))

	# Gold from ExperienceManager (authoritative)
	var gold: int = 0
	var exp_mgr = get_tree().get_first_node_in_group("experience_manager")
	if exp_mgr and "total_coins" in exp_mgr:
		gold = exp_mgr.total_coins
	else:
		gold = run_stats.get("gold", 0)

	# Difficulty snapshot via RunContext (single entry point)
	var difficulty_final := {}
	if run_ctx and run_ctx.has_method("get_difficulty_snapshot"):
		difficulty_final = run_ctx.get_difficulty_snapshot()
		if difficulty_final.get("status", "") == "not_available":
			difficulty_final = {}
	if difficulty_final.is_empty() and BalanceTelemetry:
		difficulty_final = BalanceTelemetry.get_difficulty_snapshot()

	# ═══════════════════════════════════════════════════════════════════════════
	# 4. BUILD CONTEXT
	# ═══════════════════════════════════════════════════════════════════════════
	var context = {
		"time_survived": game_time,
		"duration_s": duration_s,
		"score_total": _calculate_run_score(),
		"end_reason": reason,
		"killed_by": killed_by,
		"death_context": death_context,
		"level": run_stats.get("level", 1),
		"phase": _get_current_phase(),
		"kills": run_stats.get("kills", 0),
		"elites_killed": run_stats.get("elites_killed", 0),
		"bosses_killed": run_stats.get("bosses_killed", 0),
		"gold": gold,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"healing_done": healing_done,
		"xp_total": xp_total,
		"difficulty_final": difficulty_final,
		"weapons": [],
		"upgrades": [],
		"player_stats": {}
	}

	# Get weapon/upgrade/stats snapshots
	if BalanceTelemetry:
		context["weapons"] = BalanceTelemetry.get_current_weapons_snapshot()
		context["upgrades"] = BalanceTelemetry.get_top_upgrades_snapshot(20)
		context["player_stats"] = BalanceTelemetry.get_player_stats_snapshot()
		# Also log to BalanceTelemetry
		BalanceTelemetry.end_run(context)

	# RunAuditTracker end run (generates report)
	var audit_tracker = get_node_or_null("/root/RunAuditTracker")
	if audit_tracker:
		audit_tracker.end_run(context)

	# UpgradeAuditor: finalizar auditoría y generar reporte
	var upgrade_auditor = get_node_or_null("/root/UpgradeAuditor")
	if upgrade_auditor and upgrade_auditor.has_method("end_run"):
		upgrade_auditor.end_run()

	# PerfTracker: end run context
	var perf_tracker = get_node_or_null("/root/PerfTracker")
	if perf_tracker and perf_tracker.has_method("end_run"):
		perf_tracker.end_run()

	# RunBundleManager: finalizar bundle (DESPUÉS de trackers)
	var bundle_mgr = get_node_or_null("/root/RunBundleManager")
	if bundle_mgr and bundle_mgr.has_method("finalize_bundle"):
		bundle_mgr.finalize_bundle(context)

	# RunContext: cerrar run unificada (último)
	if run_ctx:
		run_ctx.end_run(context)

func _get_current_phase() -> int:
	"""Helper to get current game phase"""
	if wave_manager and "current_phase" in wave_manager:
		return wave_manager.current_phase
	return 1

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS DE WAVEMANAGER
# ═══════════════════════════════════════════════════════════════════════════════

func _on_phase_changed(phase_num: int, phase_config: Dictionary) -> void:
	"""Callback cuando cambia la fase del juego"""
	var _phase_name = phase_config.get("name", "Fase %d" % phase_num)
	# Debug desactivado: print("🌊 [Game] Fase cambiada: %s" % phase_name)

	# DESACTIVADO: Ya no mostramos mensajes de fase, solo eventos importantes
	# if hud and hud.has_method("show_wave_message"):
	# 	var msg = "═══ FASE %d: %s ═══" % [phase_num, phase_name.to_upper()]
	# 	hud.show_wave_message(msg, 5.0)
	pass

func _on_wave_started(_wave_type: String, wave_config: Dictionary) -> void:
	"""Callback cuando inicia una oleada"""
	var announcement = wave_config.get("announcement", "")
	if announcement != "" and hud and hud.has_method("show_wave_message"):
		hud.show_wave_message(announcement, 3.0)

func _on_boss_incoming(boss_id: String, _seconds_until: float) -> void:
	"""Callback de advertencia de boss"""
	# Debug desactivado: print("⚠️ [Game] ¡Boss %s llegando en %.1f segundos!" % [boss_id, seconds_until])

	if hud and hud.has_method("show_wave_message"):
		var boss_name = _get_boss_display_name(boss_id)
		hud.show_wave_message("⚠️ ¡%s SE APROXIMA!" % boss_name.to_upper(), 5.0)

func _on_boss_spawned(boss_id: String) -> void:
	"""Callback cuando aparece un boss"""
	# Debug desactivado: print("👹 [Game] ¡BOSS SPAWNEADO: %s!" % boss_id)

	var boss_name = _get_boss_display_name(boss_id)

	if hud and hud.has_method("show_wave_message"):
		hud.show_wave_message("👹 ¡%s HA APARECIDO!" % boss_name.to_upper(), 4.0)

	# Mostrar barra de HP del boss
	if hud and hud.has_method("show_boss_bar") and wave_manager:
		var boss_node = wave_manager.get_current_boss()
		if boss_node:
			hud.show_boss_bar(boss_node, boss_name)

func _on_boss_defeated(boss_id: String) -> void:
	"""Callback cuando se derrota a un boss"""
	# Debug desactivado: print("🏆 [Game] ¡BOSS DERROTADO: %s!" % boss_id)

	var boss_name = _get_boss_display_name(boss_id)

	if hud and hud.has_method("show_wave_message"):
		hud.show_wave_message("🏆 ¡%s DERROTADO!" % boss_name.to_upper(), 4.0)

	if hud and hud.has_method("hide_boss_bar"):
		hud.hide_boss_bar()

func _on_elite_spawned(_enemy_id: String) -> void:
	"""Callback cuando aparece un élite"""
	# Debug desactivado: print("⭐ [Game] ¡ÉLITE SPAWNEADO: %s!" % enemy_id)

	if hud and hud.has_method("show_wave_message"):
		hud.show_wave_message("⭐ ¡ENEMIGO LEGENDARIO!", 3.0)

func _on_special_event_started(_event_name: String, event_config: Dictionary) -> void:
	"""Callback cuando inicia un evento especial"""
	# Debug desactivado: print("🎪 [Game] Evento especial: %s" % event_name)

	var announcement = event_config.get("announcement", "")
	if announcement != "" and hud and hud.has_method("show_wave_message"):
		hud.show_wave_message(announcement, 4.0)

func _on_special_event_ended(_event_name: String) -> void:
	"""Callback cuando termina un evento especial"""
	# Debug desactivado: print("🎪 [Game] Evento terminado: %s" % event_name)

func _on_game_phase_infinite() -> void:
	"""Callback cuando entramos en fase infinita"""
	# Debug desactivado: print("♾️ [Game] ¡MODO INFINITO ACTIVADO!")

	if hud and hud.has_method("show_wave_message"):
		hud.show_wave_message("♾️ ═══ MODO INFINITO ═══ ♾️\n¡Sobrevive todo lo que puedas!", 6.0)

func _get_boss_display_name(boss_id: String) -> String:
	"""Obtener nombre legible del boss"""
	var names = {
		"el_conjurador_primigenio": "El Conjurador Primigenio",
		"el_corazon_del_vacio": "El Corazón del Vacío",
		"el_guardian_de_runas": "El Guardián de Runas",
		"minotauro_de_fuego": "Minotauro de Fuego"
	}
	return names.get(boss_id, boss_id.replace("_", " ").capitalize())

func _deferred_weapon_hud_update() -> void:
	"""Actualizar HUD de armas de forma diferida para capturar arma inicial"""
	var attack_manager_ref = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager_ref:
		_update_hud_weapons_from_attack_manager(attack_manager_ref)

func _on_weapon_changed_update_hud(_weapon, _slot_index: int) -> void:
	"""Callback cuando se añade/remueve un arma - actualizar HUD"""
	var attack_manager_ref = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager_ref:
		_update_hud_weapons_from_attack_manager(attack_manager_ref)

func _on_weapon_leveled_up_update_hud(_weapon, _new_level: int) -> void:
	"""Callback cuando un arma sube de nivel - actualizar HUD"""
	var attack_manager_ref = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager_ref:
		_update_hud_weapons_from_attack_manager(attack_manager_ref)

func _update_hud_weapons_from_attack_manager(attack_mgr) -> void:
	"""Actualizar iconos de armas en HUD desde AttackManager"""
	if not hud or not hud.has_method("update_weapons"):
		return
	
	var weapons_info: Array = []
	if attack_mgr.has_method("get_weapons"):
		for weapon in attack_mgr.get_weapons():
			var info = {}
			if weapon.has_method("get_info"):
				info = weapon.get_info()
			elif "id" in weapon:
				info = {
					"id": weapon.id,
					"name": weapon.weapon_name if "weapon_name" in weapon else weapon.id,
					"level": weapon.level if "level" in weapon else 1,
					"icon_path": "res://assets/icons/%s.png" % weapon.id
				}
			if not info.is_empty():
				weapons_info.append(info)
	
	hud.update_weapons(weapons_info)

func _update_atmosphere_biome(zone_id: int, _zone_name: String) -> void:
	"""Actualizar partículas ambientales cuando cambia la zona"""
	if not ambient_atmosphere or not arena_manager:
		return
		
	# Obtener nombre del bioma desde ArenaManager
	if "selected_biomes" in arena_manager:
		var biome = arena_manager.selected_biomes.get(zone_id, "Grassland")
		ambient_atmosphere.set_biome(biome)

func save_session_playtime() -> void:
	"""Guardar el tiempo jugado en esta sesión específica"""
	var delta_time = game_time - session_start_time
	if delta_time > 0:
		SaveManager.add_playtime(delta_time)
		# Avanzar el start time para no contar doble si se llama de nuevo sin salir
		session_start_time = game_time
 
 #   � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " �  
 #   S E C U R I T Y   ( R U N T I M E   G U A R D R A I L S )  
 #   � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " � � " �  
  
 v a r   _ f o r b i d d e n _ r u n t i m e _ t y p e s   =   [  
 	 " I t e m T e s t R u n n e r " ,  
 	 " S t r u c t u r e V a l i d a t o r " ,  
 	 " T e s t R u n n e r " ,  
 	 " C a l i b r a t i o n S u i t e " ,  
 	 " S t r e s s T e s t "  
 ]  
  
 f u n c   _ s e c u r i t y _ s c a n _ t r e e ( )   - >   v o i d :  
 	 " " "  
 	 E s c a n e a   e l   � � r b o l   d e   e s c e n a   e n   b u s c a   d e   n o d o s   d e   d e b u g   p r o h i b i d o s   e n   r u n t i m e .  
 	 S o l o   a c t i v o   e n   d e b u g   b u i l d s .   A b o r t a   s i   e n c u e n t r a   v i o l a c i o n e s .  
 	 " " "  
 	 p r i n t ( " [ S E C U R I T Y ]   S c a n n i n g   r u n t i m e   s c e n e   t r e e . . . " )  
 	  
 	 v a r   v i o l a t i o n s   =   [ ]  
 	 v a r   s t a c k   =   [ s e l f ]  
 	  
 	 w h i l e   s t a c k . s i z e ( )   >   0 :  
 	 	 v a r   c u r r e n t   =   s t a c k . p o p _ b a c k ( )  
 	 	  
 	 	 #   C h e c k   C l a s s   N a m e   ( i f   s c r i p t   a t t a c h e d )  
 	 	 i f   c u r r e n t . g e t _ s c r i p t ( ) :  
 	 	 	 v a r   s c r i p t _ p a t h   =   c u r r e n t . g e t _ s c r i p t ( ) . r e s o u r c e _ p a t h  
 	 	 	 #   C h e c k   f o r b i d d e n   p a t h s  
 	 	 	 i f   s c r i p t _ p a t h . c o n t a i n s ( " r e s : / / s c r i p t s / t e s t s " )   o r   s c r i p t _ p a t h . c o n t a i n s ( " r e s : / / t e s t s " ) :  
 	 	 	 	 v i o l a t i o n s . a p p e n d ( " % s   ( S c r i p t :   % s ) "   %   [ c u r r e n t . n a m e ,   s c r i p t _ p a t h ] )  
 	 	 	 	  
 	 	 	 #   C h e c k   f o r b i d d e n   c l a s s   n a m e s   ( h e u r i s t i c :   f i l e n a m e   o r   i n t e r n a l   c l a s s )  
 	 	 	 f o r   t y p e   i n   _ f o r b i d d e n _ r u n t i m e _ t y p e s :  
 	 	 	 	 i f   s c r i p t _ p a t h . c o n t a i n s ( t y p e ) :  
 	 	 	 	 	 v i o l a t i o n s . a p p e n d ( " % s   ( F o r b i d d e n   T y p e :   % s ) "   %   [ c u r r e n t . n a m e ,   t y p e ] )  
 	 	  
 	 	 #   A d d   c h i l d r e n  
 	 	 s t a c k . a p p e n d _ a r r a y ( c u r r e n t . g e t _ c h i l d r e n ( ) )  
 	  
 	 i f   v i o l a t i o n s . s i z e ( )   >   0 :  
 	 	 p r i n t e r r ( " � � R  [ S E C U R I T Y   V I O L A T I O N ]   R u n t i m e   s c e n e   c o n t a i n s   f o r b i d d e n   d e b u g   n o d e s : " )  
 	 	 f o r   v   i n   v i o l a t i o n s :  
 	 	 	 p r i n t e r r ( "     -   " ,   v )  
 	 	  
 	 	 O S . a l e r t ( " S e c u r i t y   V i o l a t i o n :   R u n t i m e   s c e n e   c o n t a i n s   d e b u g   n o d e s .   S e e   c o n s o l e . " ,   " S E C U R I T Y   E R R O R " )  
 	 	 g e t _ t r e e ( ) . q u i t ( 1 )  
 	 e l s e :  
 	 	 p r i n t ( " [ S E C U R I T Y ]   � S&   R u n t i m e   t r e e   c l e a n . " )  
 