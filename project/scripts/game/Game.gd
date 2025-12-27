extends Node2D
class_name Game

## Escena principal del juego
## Coordina todos los sistemas durante una partida

# Nodos principales
@onready var world_root: Node2D = $WorldRoot
@onready var chunks_root: Node2D = $WorldRoot/ChunksRoot
@onready var player_container: Node2D = $PlayerContainer
@onready var enemies_root: Node2D = $WorldRoot/EnemiesRoot
@onready var pickups_root: Node2D = $WorldRoot/PickupsRoot
@onready var projectiles_root: Node2D = $WorldRoot/ProjectilesRoot
@onready var ui_layer: CanvasLayer = $UILayer
@onready var camera: Camera2D = $Camera2D

# Referencias a sistemas
var player: CharacterBody2D = null
var world_manager: Node = null
var enemy_manager: Node = null
var weapon_manager: Node = null
var experience_manager: Node = null
var hud: CanvasLayer = null
var pause_menu: Control = null
var game_over_screen: Control = null

# Estado del juego
var game_running: bool = false
var game_time: float = 0.0
var is_paused: bool = false

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
	
	# Crear sistemas (WorldManager desactivado temporalmente por rendimiento)
	# _create_world_manager()
	_create_enemy_manager()
	_create_weapon_manager()
	_create_experience_manager()
	
	# Crear UI
	_create_ui()
	
	# Configurar cámara
	_setup_camera()
	
	# Inicializar sistemas
	_initialize_systems()
	
	# Crear suelo de fallback (siempre, ya que WorldManager está desactivado)
	_create_fallback_ground()
	
	# Comenzar partida
	_start_game()

func _create_fallback_ground() -> void:
	## Crear un suelo simple como fallback - MUY GRANDE para que no se acabe
	var ground = ColorRect.new()
	ground.name = "FallbackGround"
	ground.color = Color(0.2, 0.35, 0.2)  # Verde oscuro para hierba
	ground.size = Vector2(50000, 50000)
	ground.position = Vector2(-25000, -25000)  # Centrado en el origen
	ground.z_index = -200  # Muy atrás
	world_root.add_child(ground)
	print("🌿 [Game] Suelo de fallback creado")

func _create_player() -> void:
	var player_scene = load("res://scenes/player/SpellloopPlayer.tscn")
	if player_scene:
		player = player_scene.instantiate()
		player_container.add_child(player)
		player.global_position = Vector2.ZERO
		print("🧙 [Game] Player creado")
	else:
		push_error("[Game] No se pudo cargar SpellloopPlayer.tscn")

func _create_world_manager() -> void:
	var wm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if wm_script:
		world_manager = wm_script.new()
		world_manager.name = "WorldManager"
		add_child(world_manager)
		print("🌍 [Game] WorldManager creado")

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
		enemy_manager.initialize(player, null)  # null porque WorldManager está desactivado
	
	if weapon_manager and player:
		weapon_manager.initialize(player)
		weapon_manager.enemy_manager = enemy_manager
	
	if experience_manager and player:
		experience_manager.initialize(player)
	
	# WorldManager desactivado temporalmente
	# if world_manager:
	# 	world_manager.chunks_root = chunks_root
	# 	world_manager.call_deferred("initialize", player)
	
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

func _on_enemy_died(position: Vector2, enemy_type: String, exp_value: int) -> void:
	run_stats["kills"] += 1
	
	# Crear orbe de XP
	if experience_manager:
		experience_manager.create_exp_orb(position, exp_value)

func _on_exp_gained(amount: int, total: int) -> void:
	run_stats["xp_total"] = total

func _on_level_up(new_level: int, upgrades: Array) -> void:
	run_stats["level"] = new_level
	
	# Mostrar panel de level up
	# TODO: Implementar selección de mejoras

func player_died() -> void:
	## Llamar cuando el player muere
	game_running = false
	
	if game_over_screen:
		game_over_screen.show_game_over(run_stats)

func add_damage_stat(amount: int) -> void:
	run_stats["damage_dealt"] += amount

func add_gold_stat(amount: int) -> void:
	run_stats["gold"] += amount
