extends Node2D
class_name SpellloopGame

"""
�‍♂️ SPELLLOOP GAME - SISTEMA PRINCIPAL
======================================

Gestiona el juego completo estilo roguelike top-down:
- Player fijo en centro
- Mundo infinito
- Auto-ataque mágico
- Enemigos
- Sistema EXP
"""

var world_manager
var player
var enemy_manager
var weapon_manager
var experience_manager
var item_manager
var minimap
var ui_layer
var world_camera: Camera2D = null
var waves_manager: Node = null
var hud_timer: Timer = null

# Configuración
var game_running: bool = false

func _ready():
	print("🧙‍♂️ Iniciando Spellloop Game...")
	setup_game()

	# Run automatic scene verification and log results
	if ResourceLoader.exists("res://scripts/tools/verify_scenes.gd"):
		var vs_script = load("res://scripts/tools/verify_scenes.gd")
		if vs_script:
			var verifier = vs_script.new()
			add_child(verifier)
			verifier.run_checks()
			var report = verifier.get_report()
			if report.find("MISSING/ERROR") != -1:
				print("[VERIFY] Errors found in scene verification:\n", report)
				# Show simple label in UI
				var lbl = Label.new()
				lbl.text = "Scene verification failed. Check output."
				lbl.modulate = Color(1,0.4,0.4)
				lbl.name = "VerifyWarning"
				lbl.z_index = 999
				add_child(lbl)
			else:
				print("[VERIFY] All scenes verified OK:\n", report)

func _get_ui():
	if get_tree() and get_tree().root and get_tree().root.has_node("UIManager"):
		return get_tree().root.get_node("UIManager")
	return null

func setup_game():
	"""Configurar todos los sistemas del juego"""
	
	# Crear player fijo en el centro
	create_player()

	# Ensure core singletons/nodes are present under the scene root so other systems can find them via get_tree().root
	# InputManager
	if get_tree() and get_tree().root and not get_tree().root.has_node("InputManager"):
		if ResourceLoader.exists("res://scripts/core/InputManager.gd"):
			var im = load("res://scripts/core/InputManager.gd").new()
			im.name = "InputManager"
			get_tree().root.add_child(im)

	# SpriteDB
	if get_tree() and get_tree().root and not get_tree().root.has_node("SpriteDB"):
		if ResourceLoader.exists("res://scripts/core/SpriteDB.gd"):
			var sdb = load("res://scripts/core/SpriteDB.gd").new()
			sdb.name = "SpriteDB"
			get_tree().root.add_child(sdb)
	
	# Crear sistemas de gestión
	create_world_manager()
	create_enemy_manager()
	# Create and wire waves manager (choose pools per 5-minute segments)
	if ResourceLoader.exists("res://scripts/core/waves.gd"):
		var wscript = load("res://scripts/core/waves.gd")
		if wscript:
			waves_manager = wscript.new()
			waves_manager.name = "WavesManager"
			add_child(waves_manager)
			# Give to enemy manager
			if enemy_manager:
				enemy_manager.wave_manager = waves_manager
	create_weapon_manager()
	create_experience_manager()
	create_item_manager()
	create_ui_layer()
	create_minimap()
	# Ensure Camera2D follows player if present in scene
	if has_node("WorldRoot/Camera2D"):
		world_camera = get_node("WorldRoot/Camera2D")
	elif has_node("Camera2D"):
		world_camera = get_node("Camera2D")
	if world_camera:
		world_camera.current = true
	else:
		# If there's no Camera2D in the scene, create one and parent it to WorldRoot (or to root)
		var cam = Camera2D.new()
		cam.name = "Camera2D"
		cam.current = true
		# Try to parent under WorldRoot so it moves with world transforms if available
		if has_node("WorldRoot"):
			get_node("WorldRoot").add_child(cam)
		else:
			add_child(cam)
		world_camera = cam
	
	# Inicializar sistemas
	initialize_systems()
	
	# Comenzar juego
	start_game()

func create_player():
	"""Crear player centrado en pantalla"""
	# Intentar instanciar la escena del player (contiene AnimatedSprite2D y CollisionShape)
	var player_scene_path = "res://scenes/player/SpellloopPlayer.tscn"
	var player_script = null
	var p_res = null

	if ResourceLoader.exists(player_scene_path):
		p_res = ResourceLoader.load(player_scene_path)
		if p_res and p_res is PackedScene:
			player = p_res.instantiate()
		# Update camera position to follow player if available
		if world_camera and player:
			world_camera.position = player.position
		else:
			# Fallback a cargar el script directamente
			player_script = load("res://scripts/entities/SpellloopPlayer.gd")
			if player_script:
				player = player_script.new()
			else:
				player = CharacterBody2D.new()
	else:
		# Fallback: crear desde script o un CharacterBody2D simple
		player_script = load("res://scripts/entities/SpellloopPlayer.gd")
		if player_script:
			player = player_script.new()
		else:
			player = CharacterBody2D.new()

	player.name = "Player"

	# Posicionar en centro de pantalla
	var viewport_size = get_viewport().get_visible_rect().size
	player.position = viewport_size / 2

	# Parentear el player bajo WorldRoot si existe
	if has_node("WorldRoot"):
		var wr = get_node("WorldRoot")
		wr.add_child(player)
	else:
		add_child(player)
	print("🧙‍♂️ Player creado en centro: ", player.position, " (instanciado desde script: ", player_script != null, ")")

func create_world_manager():
	"""Crear gestor de mundo infinito"""
	world_manager = InfiniteWorldManager.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)

func create_enemy_manager():
	"""Crear gestor de enemigos"""
	enemy_manager = EnemyManager.new()
	enemy_manager.name = "EnemyManager"
	add_child(enemy_manager)

func create_weapon_manager():
	"""Crear gestor de armas"""
	weapon_manager = WeaponManager.new()
	weapon_manager.name = "WeaponManager"
	add_child(weapon_manager)

func create_experience_manager():
	"""Crear gestor de experiencia"""
	experience_manager = ExperienceManager.new()
	experience_manager.name = "ExperienceManager"
	add_child(experience_manager)

func create_item_manager():
	"""Crear gestor de items"""
	item_manager = ItemManager.new()
	item_manager.name = "ItemManager"
	add_child(item_manager)

func create_ui_layer():
	"""Crear capa de UI"""
	# Reuse existing UI node if present (SpellloopMain.tscn created a CanvasLayer named UI)
	if has_node("UI"):
		ui_layer = get_node("UI")
	else:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		ui_layer.layer = 100  # Encima de todo
		add_child(ui_layer)

	# Add DebugOverlay to UI
	var debug_overlay = null
	if ResourceLoader.exists("res://scripts/core/DebugOverlay.gd"):
		var dbg = load("res://scripts/core/DebugOverlay.gd")
		debug_overlay = dbg.new()
		debug_overlay.name = "DebugOverlay"
		ui_layer.add_child(debug_overlay)

func create_minimap():
	"""Crear sistema de minimapa"""
	minimap = MinimapSystem.new()
	minimap.name = "MinimapSystem"
	ui_layer.add_child(minimap)

func initialize_systems():
	"""Inicializar todos los sistemas"""
	
	# Inicializar mundo infinito
	# Asignar referencias a roots si existen
	if has_node("WorldRoot/ChunksRoot"):
		world_manager.chunks_root = get_node("WorldRoot/ChunksRoot")
	world_manager.initialize_world(player)
	# Inicializar enemigos
	enemy_manager.initialize(player, world_manager)
	# Inicializar armas
	weapon_manager.initialize(player)
	# Inicializar experiencia
	experience_manager.initialize(player)
	# Inicializar items
	item_manager.initialize(player, world_manager)
	# Inicializar minimapa
	if minimap and minimap.has_method("setup_references"):
		minimap.setup_references(player, enemy_manager, item_manager)
	# Setup debug overlay references if present
	if ui_layer and ui_layer.has_node("DebugOverlay"):
		var dbg = ui_layer.get_node("DebugOverlay")
		if dbg and dbg.has_method("setup_references"):
			dbg.setup_references(player, enemy_manager, world_manager)
	# Inicializar HUD (acceso seguro al autoload)
	var ui = _get_ui()
	if ui:
		ui.show_game_hud()
		_update_hud_all()
	# Conectar señales entre sistemas
	connect_systems()
	# Setup HUD update timer (1s)
	if not hud_timer:
		hud_timer = Timer.new()
		hud_timer.wait_time = 1.0
		hud_timer.one_shot = false
		hud_timer.autostart = false
		hud_timer.name = "HUDTimer"
		add_child(hud_timer)
		hud_timer.timeout.connect(_on_hud_tick)

func connect_systems():
	# Player muerte -> Game Over
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
func _on_player_died():
	game_running = false
	var ui = _get_ui()
	if ui:
		ui.show_game_over_menu({"level": experience_manager.current_level})
	"""Conectar señales entre sistemas"""
	
	# Player movimiento -> World movement
	if player.has_signal("movement_input"):
		player.movement_input.connect(_on_player_movement)
	# Enemigos muertos -> EXP
	if enemy_manager.has_signal("enemy_died"):
		enemy_manager.enemy_died.connect(_on_enemy_died)
	# EXP -> Level up
	if experience_manager.has_signal("level_up"):
		experience_manager.level_up.connect(_on_level_up)
	# EXP -> HUD
	if experience_manager.has_signal("exp_gained"):
		experience_manager.exp_gained.connect(_on_exp_gained)
	# WeaponManager -> HUD
	if weapon_manager and weapon_manager.has_signal("weapon_changed"):
		weapon_manager.weapon_changed.connect(_on_weapon_changed)
	# Conectar WeaponManager con EnemyManager para targeting
	if weapon_manager and weapon_manager.has_method("set_enemy_manager"):
		weapon_manager.set_enemy_manager(enemy_manager)

	# Connect boss spawned signal to HUD
	if enemy_manager and enemy_manager.has_signal("boss_spawned"):
		enemy_manager.boss_spawned.connect(_on_boss_spawned)

	# Bind minimap toggle to InputManager action if available
	if get_tree() and get_tree().root and get_tree().root.has_node("InputManager"):
		var im = get_tree().root.get_node("InputManager")
		# InputManager exposes is_action_just_pressed wrapper; we'll poll in _process for toggle
		# Alternatively connect to action_pressed signal
		if im and im.has_signal("action_pressed"):
				im.action_pressed.connect(Callable(self, "_on_input_action_pressed"))

func start_game():
	"""Iniciar el juego"""
	game_running = true
	print("🎮 ¡Spellloop Game iniciado!")
	# Start GameManager run timer if available
	if get_tree() and get_tree().root and get_tree().root.has_node("GameManager"):
		var gm = get_tree().root.get_node("GameManager")
		if gm and not gm.is_run_active and gm.has_method("start_new_run"):
			gm.start_new_run()
	# Start HUD timer
	if hud_timer and not hud_timer.is_stopped():
		hud_timer.start()
	elif hud_timer:
		hud_timer.start()

	# Wire enemy_manager wave manager if not already wired
	if enemy_manager and not enemy_manager.wave_manager and waves_manager:
		enemy_manager.wave_manager = waves_manager


func _on_player_movement(movement_delta: Vector2):
	"""Manejar movimiento del player (mover mundo)"""
	if world_manager:
		world_manager.update_world(movement_delta)

func _on_enemy_died(enemy_position: Vector2, _enemy_type: String, exp_value: int):
	"""Manejar muerte de enemigo"""
	if experience_manager:
		# Crear bolita de EXP en la posición del enemigo
		experience_manager.create_exp_orb(enemy_position, exp_value)
	
	# Crear orbe de oro (valor simple basado en exp_value)
	var gold_amount = max(1, int(float(exp_value) / 2.0))
	if experience_manager and experience_manager.has_method("create_gold_orb"):
		experience_manager.create_gold_orb(enemy_position + Vector2(8, 0), gold_amount)


func _on_hud_tick() -> void:
	# Update HUD timer every second using GameManager's formatted time
	var ui = _get_ui()
	if not ui:
		return
	if get_tree() and get_tree().root and get_tree().root.has_node("GameManager"):
		var gm = get_tree().root.get_node("GameManager")
		if gm and gm.has_method("get_game_time_formatted"):
			var timestr = gm.get_game_time_formatted()
			# Convert MM:SS to seconds for GameHUD.update_timer which expects int seconds
			var parts = timestr.split(":")
			if parts.size() == 2:
				var mins = int(parts[0])
				var secs = int(parts[1])
				var total = mins * 60 + secs
				ui.update_timer(total)

func _on_input_action_pressed(action: String) -> void:
	if action == "toggle_minimap":
		if minimap and minimap.has_method("toggle_visibility"):
			minimap.toggle_visibility()

func _on_boss_spawned(boss_node: Node2D) -> void:
	# Notify HUD to show boss HP bar and telegraph
	var ui = _get_ui()
	if ui and ui.has_method("show_boss_bar"):
		# Best-effort: pass boss_node and a display name if present
		var bname: String = "BOSS"
		if boss_node:
			if boss_node.has_method("get_name"):
				bname = boss_node.get_name()
			elif "name" in boss_node:
				bname = str(boss_node.name)
		ui.show_boss_bar(boss_node, bname)
	else:
		print("[SpellloopGame] Boss spawned but no UIManager.show_boss_bar available")


func _on_level_up(new_level: int, upgrades: Array):
	"""Manejar subida de nivel"""
	print("🆙 ¡Level UP! Nuevo nivel: ", new_level)
	get_tree().paused = true
	var ui = _get_ui()
	if ui:
		ui.show_levelup_popup(upgrades)
		if ui.game_hud:
			if not ui.game_hud.upgrade_selected.is_connected(_on_upgrade_selected):
				ui.game_hud.upgrade_selected.connect(_on_upgrade_selected)

func _on_upgrade_selected(upgrade: Dictionary):
	print("[SpellloopGame] Upgrade seleccionado: ", upgrade)
	var ui = _get_ui()
	if ui:
		ui.hide_levelup_popup()
	get_tree().paused = false
	# Aplicar efectos simples (delegar a item_manager o weapon_manager según tipo)
	if item_manager and item_manager.has_method("apply_item_effect"):
		item_manager.apply_item_effect(upgrade.get("id", ""), upgrade)
func _on_exp_gained(_amount: int, _total_exp: int):
	_update_hud_all()

func _on_weapon_changed():
	_update_hud_all()

func _update_hud_all():
	var ui = _get_ui()
	if not ui:
		return
	# Actualizar stats
	var hp = 100
	var max_hp = 100
	if player and player.has_method("get_hp"):
		hp = player.get_hp()
		max_hp = player.get_max_hp()
	var xp = 0
	var xp_to_level = 10
	var level = 1
	if experience_manager:
		xp = experience_manager.current_exp
		xp_to_level = experience_manager.exp_to_next_level
		level = experience_manager.current_level
	ui.update_hud_stats(hp, max_hp, xp, xp_to_level, level)
	# Actualizar armas
	var weapons = []
	if weapon_manager and weapon_manager.has_method("get_equipped_weapons"):
		weapons = weapon_manager.get_equipped_weapons()
	ui.update_hud_weapons(weapons)
	# Actualizar timer (placeholder: segundos desde inicio)
	var seconds = int(Time.get_ticks_msec() / 1000.0)
	ui.update_hud_timer(seconds)

func _process(_delta):
	"""Update principal del juego"""
	if not game_running:
		return
	
	# Los sistemas se actualizan automáticamente
	# Aquí solo manejamos coordinación global
	# Keep camera centered on player if available
	if world_camera and player:
		# If player has a global position, use it; otherwise use local position
		if player.has_method("get_global_position"):
			world_camera.position = player.get_global_position()
		else:
			world_camera.position = player.position

func get_game_stats() -> Dictionary:
	"""Obtener estadísticas del juego"""
	var stats = {
		"running": game_running,
		"player_level": 1,
		"enemies_alive": 0,
		"chunks_loaded": 0
	}
	
	if experience_manager:
		stats.player_level = experience_manager.current_level
	
	if enemy_manager:
		stats.enemies_alive = enemy_manager.get_enemy_count()
	
	if world_manager:
		stats.chunks_loaded = world_manager.get_loaded_chunks_count()
	
	return stats

func _input(event):
	"""Manejar input del juego"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:
				# Toggle minimapa
				if minimap:
					minimap.toggle_visibility()
					print("🗺️ Minimapa: ", "ON" if minimap.visible else "OFF")
