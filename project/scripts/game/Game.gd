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
var arena_manager: Node = null
var enemy_manager: Node = null
var weapon_manager: Node = null
var experience_manager: Node = null
var wave_manager: Node = null
var hud: CanvasLayer = null
var pause_menu: Control = null
var game_over_screen: Control = null

# Estado del juego
var game_running: bool = false
var game_time: float = 0.0
var is_paused: bool = false

# Contadores de Reroll/Banish persistentes para toda la partida
# Balance:
# - Reroll (3): permite re-randomizar opciones de level up
# - Banish (2): elimina una opción permanentemente del pool
# - Skip: siempre disponible, sin límite
var remaining_rerolls: int = 3
var remaining_banishes: int = 2

# Estadísticas de la partida
var run_stats: Dictionary = {
	"time": 0.0,
	"level": 1,
	"kills": 0,
	"xp_total": 0,
	"gold": 0,
	"damage_dealt": 0
}

func _ready() -> void:
	print("🎮 [Game] Iniciando partida...")
	_setup_game()

func _setup_game() -> void:
	# Crear player
	_create_player()

	# Crear arena (debe ser antes de otros sistemas para que tengan contexto)
	_create_arena_manager()

	# Crear sistemas
	_create_enemy_manager()
	_create_wave_manager()
	_create_weapon_manager()
	_create_experience_manager()

	# Crear UI
	_create_ui()

	# Configurar cámara
	_setup_camera()

	# Inicializar sistemas
	_initialize_systems()

	# Comenzar partida
	_start_game()

func _create_player() -> void:
	var player_scene = load("res://scenes/player/SpellloopPlayer.tscn")
	if player_scene:
		player = player_scene.instantiate()
		player_container.add_child(player)
		player.global_position = Vector2.ZERO
		print("🧙 [Game] Player creado")
	else:
		push_error("[Game] No se pudo cargar SpellloopPlayer.tscn")

func _create_arena_manager() -> void:
	var am_script = load("res://scripts/core/ArenaManager.gd")
	if am_script:
		arena_manager = am_script.new()
		arena_manager.name = "ArenaManager"
		add_child(arena_manager)

		# Inicializar con player y nodo raíz de arena
		arena_manager.initialize(player, arena_root)

		# Conectar señales
		if arena_manager.has_signal("player_zone_changed"):
			arena_manager.player_zone_changed.connect(_on_player_zone_changed)
		if arena_manager.has_signal("player_hit_boundary"):
			arena_manager.player_hit_boundary.connect(_on_player_hit_boundary)

		print("🏟️ [Game] ArenaManager creado")
	else:
		push_error("[Game] No se pudo cargar ArenaManager.gd")

func _create_enemy_manager() -> void:
	var em_script = load("res://scripts/core/EnemyManager.gd")
	if em_script:
		enemy_manager = em_script.new()
		enemy_manager.name = "EnemyManager"
		add_child(enemy_manager)

		# Conectar señales
		if enemy_manager.has_signal("enemy_died"):
			enemy_manager.enemy_died.connect(_on_enemy_died)

		print("👹 [Game] EnemyManager creado")

func _create_wave_manager() -> void:
	var wm_script = load("res://scripts/managers/WaveManager.gd")
	if wm_script:
		wave_manager = wm_script.new()
		wave_manager.name = "WaveManager"
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

		print("🌊 [Game] WaveManager creado")
	else:
		push_warning("[Game] No se pudo cargar WaveManager.gd - usando spawn básico")

func _create_weapon_manager() -> void:
	var wm_script = load("res://scripts/core/WeaponManager.gd")
	if wm_script:
		weapon_manager = wm_script.new()
		weapon_manager.name = "WeaponManager"
		add_child(weapon_manager)
		print("⚔️ [Game] WeaponManager creado")

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

		print("⭐ [Game] ExperienceManager creado")

func _create_ui() -> void:
	# HUD
	var hud_scene = load("res://scenes/ui/GameHUD.tscn")
	if hud_scene:
		hud = hud_scene.instantiate()
		ui_layer.add_child(hud)
		print("📊 [Game] HUD creado")

	# Menú de pausa
	var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
	if pause_scene:
		pause_menu = pause_scene.instantiate()
		ui_layer.add_child(pause_menu)
		pause_menu.resume_pressed.connect(_on_resume_game)
		print("⏸️ [Game] PauseMenu creado")

	# Pantalla de Game Over
	var gameover_scene = load("res://scenes/ui/GameOverScreen.tscn")
	if gameover_scene:
		game_over_screen = gameover_scene.instantiate()
		ui_layer.add_child(game_over_screen)
		print("💀 [Game] GameOverScreen creado")

func _setup_camera() -> void:
	if camera:
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		print("📷 [Game] Cámara configurada")

func _physics_process(_delta: float) -> void:
	# La cámara sigue al player
	if camera and player:
		camera.global_position = player.global_position

func _initialize_systems() -> void:
	# Inicializar con referencias
	if enemy_manager and player:
		enemy_manager.initialize(player)

		# Si WaveManager está activo, deshabilitar spawn automático del EnemyManager
		# WaveManager controlará los spawns
		if wave_manager:
			enemy_manager.enable_spawning(false)

	if weapon_manager and player:
		weapon_manager.initialize(player)
		weapon_manager.enemy_manager = enemy_manager

	if experience_manager and player:
		experience_manager.initialize(player)

	# Configurar WaveManager con referencias
	if wave_manager:
		wave_manager.enemy_manager = enemy_manager
		wave_manager.player = player

	# Conectar HUD con el player
	_connect_hud_to_player()

	print("✅ [Game] Sistemas inicializados")

func _connect_hud_to_player() -> void:
	## Conectar el HUD para que reciba actualizaciones del player
	if not hud or not player:
		return

	# Conectar señales del player al HUD si existen
	if player.has_signal("health_changed") and hud.has_method("update_health"):
		if not player.health_changed.is_connected(hud.update_health):
			player.health_changed.connect(hud.update_health)

	# Actualización inicial del HUD
	if player.has_method("get_health") and hud.has_method("update_stats"):
		var health = player.get_health()
		var exp_data = {"current": 0, "max": 10, "level": 1}
		if experience_manager:
			exp_data.current = experience_manager.current_exp
			exp_data.max = experience_manager.exp_to_next_level
			exp_data.level = experience_manager.current_level
		hud.update_stats(health.current, health.max, exp_data.current, exp_data.max, exp_data.level)

	print("📊 [Game] HUD conectado al player")

func _start_game() -> void:
	game_running = true
	game_time = 0.0
	is_paused = false

	# Resetear stats
	run_stats = {
		"time": 0.0,
		"level": 1,
		"kills": 0,
		"xp_total": 0,
		"gold": 0,
		"damage_dealt": 0
	}

	print("🚀 [Game] ¡Partida iniciada!")

func _process(delta: float) -> void:
	if not game_running or is_paused:
		return

	# Actualizar tiempo
	game_time += delta
	run_stats["time"] = game_time

	# Actualizar HUD
	_update_hud()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if game_running and not is_paused:
			_pause_game()

func _pause_game() -> void:
	is_paused = true
	if pause_menu:
		pause_menu.show_pause_menu(game_time)

func _on_resume_game() -> void:
	is_paused = false

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

func _on_enemy_died(position: Vector2, enemy_type: String, exp_value: int, enemy_tier: int = 1, is_elite: bool = false, is_boss: bool = false) -> void:
	run_stats["kills"] += 1

	# XP AUTOMÁTICO - Se da directamente al matar
	if experience_manager:
		experience_manager.grant_exp_from_kill(exp_value)

	# MONEDAS - Caen al suelo para que el player las recoja
	if experience_manager:
		experience_manager.spawn_coins_from_enemy(position, enemy_tier, is_elite, is_boss)

func _on_exp_gained(amount: int, total: int) -> void:
	run_stats["xp_total"] = total

func _on_level_up(new_level: int, _upgrades: Array) -> void:
	run_stats["level"] = new_level

	# Mostrar panel de level up
	_show_level_up_panel(new_level)

func _show_level_up_panel(level: int) -> void:
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

	var stats = null
	if player and player.has_method("get_stats"):
		stats = player.get_stats()
	elif player and "stats" in player:
		stats = player.stats

	if panel.has_method("initialize"):
		panel.initialize(attack_mgr, stats)

	# Configurar contadores de reroll/banish (persistentes entre level ups)
	if panel.has_method("set_reroll_count"):
		panel.set_reroll_count(remaining_rerolls)
	if panel.has_method("set_banish_count"):
		panel.set_banish_count(remaining_banishes)

	# Conectar señales
	if panel.has_signal("option_selected"):
		panel.option_selected.connect(_on_level_up_option_selected)
	if panel.has_signal("panel_closed"):
		panel.panel_closed.connect(_on_level_up_panel_closed)
	if panel.has_signal("reroll_used"):
		panel.reroll_used.connect(_on_reroll_used)
	if panel.has_signal("banish_used"):
		panel.banish_used.connect(_on_banish_used)

	# Mostrar panel (pausa el juego internamente)
	if panel.has_method("show_panel"):
		panel.show_panel()

	print("🆙 [Game] Panel de level up mostrado (nivel %d)" % level)

func _on_level_up_option_selected(option: Dictionary) -> void:
	"""Callback cuando se selecciona una mejora en el level up"""
	print("🆙 [Game] Mejora seleccionada: %s" % option.get("name", "???"))

func _on_level_up_panel_closed() -> void:
	"""Callback cuando se cierra el panel de level up"""
	print("🆙 [Game] Panel de level up cerrado")

func _on_reroll_used() -> void:
	"""Callback cuando se usa un reroll"""
	remaining_rerolls = maxi(0, remaining_rerolls - 1)
	print("🎲 [Game] Reroll usado (restantes: %d)" % remaining_rerolls)

func _on_banish_used(_option_index: int) -> void:
	"""Callback cuando se usa un banish"""
	remaining_banishes = maxi(0, remaining_banishes - 1)
	print("🚫 [Game] Banish usado (restantes: %d)" % remaining_banishes)

func _on_coin_collected(value: int, total: int) -> void:
	## Callback cuando se recoge una moneda
	run_stats["coins"] = total

	# Actualizar HUD
	if hud and hud.has_method("update_coins"):
		hud.update_coins(value, total)

func _on_player_zone_changed(zone_id: int, zone_name: String) -> void:
	## Callback cuando el player cambia de zona
	print("🏟️ [Game] Player cambió a zona: %s (id=%d)" % [zone_name, zone_id])

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

func player_died() -> void:
	## Llamar cuando el player muere
	game_running = false

	if game_over_screen:
		game_over_screen.show_game_over(run_stats)

func add_damage_stat(amount: int) -> void:
	run_stats["damage_dealt"] += amount

func add_gold_stat(amount: int) -> void:
	run_stats["gold"] += amount

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS DE WAVEMANAGER
# ═══════════════════════════════════════════════════════════════════════════════

func _on_phase_changed(phase_num: int, phase_config: Dictionary) -> void:
	"""Callback cuando cambia la fase del juego"""
	var phase_name = phase_config.get("name", "Fase %d" % phase_num)
	print("🌊 [Game] Fase cambiada: %s" % phase_name)

	if hud and hud.has_method("show_wave_message"):
		var msg = "═══ FASE %d: %s ═══" % [phase_num, phase_name.to_upper()]
		hud.show_wave_message(msg, 5.0)

func _on_wave_started(wave_type: String, wave_config: Dictionary) -> void:
	"""Callback cuando inicia una oleada"""
	var announcement = wave_config.get("announcement", "")
	if announcement != "" and hud and hud.has_method("show_wave_message"):
		hud.show_wave_message(announcement, 3.0)

func _on_boss_incoming(boss_id: String, seconds_until: float) -> void:
	"""Callback de advertencia de boss"""
	print("⚠️ [Game] ¡Boss %s llegando en %.1f segundos!" % [boss_id, seconds_until])

	if hud and hud.has_method("show_wave_message"):
		var boss_name = _get_boss_display_name(boss_id)
		hud.show_wave_message("⚠️ ¡%s SE APROXIMA!" % boss_name.to_upper(), 5.0)

func _on_boss_spawned(boss_id: String) -> void:
	"""Callback cuando aparece un boss"""
	print("👹 [Game] ¡BOSS SPAWNEADO: %s!" % boss_id)

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
	print("🏆 [Game] ¡BOSS DERROTADO: %s!" % boss_id)

	var boss_name = _get_boss_display_name(boss_id)

	if hud and hud.has_method("show_wave_message"):
		hud.show_wave_message("🏆 ¡%s DERROTADO!" % boss_name.to_upper(), 4.0)

	if hud and hud.has_method("hide_boss_bar"):
		hud.hide_boss_bar()

func _on_elite_spawned(enemy_id: String) -> void:
	"""Callback cuando aparece un élite"""
	print("⭐ [Game] ¡ÉLITE SPAWNEADO: %s!" % enemy_id)

	if hud and hud.has_method("show_wave_message"):
		hud.show_wave_message("⭐ ¡ENEMIGO LEGENDARIO!", 3.0)

func _on_special_event_started(event_name: String, event_config: Dictionary) -> void:
	"""Callback cuando inicia un evento especial"""
	print("🎪 [Game] Evento especial: %s" % event_name)

	var announcement = event_config.get("announcement", "")
	if announcement != "" and hud and hud.has_method("show_wave_message"):
		hud.show_wave_message(announcement, 4.0)

func _on_special_event_ended(event_name: String) -> void:
	"""Callback cuando termina un evento especial"""
	print("🎪 [Game] Evento terminado: %s" % event_name)

func _on_game_phase_infinite() -> void:
	"""Callback cuando entramos en fase infinita"""
	print("♾️ [Game] ¡MODO INFINITO ACTIVADO!")

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
