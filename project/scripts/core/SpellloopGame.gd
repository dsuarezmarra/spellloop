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
var run_start_time: int = 0
var _boss_spawned_at_5s: bool = false
var wave_interval_sec: int = 300
var current_wave: int = 0

# Configuración
var game_running: bool = false

func _ready():
	print("🧙‍♂️ Iniciando Spellloop Game...")
	# Diferir setup para evitar conflictos durante _ready()
	call_deferred("setup_game")
	call_deferred("_run_verification")

func _get_ui():
	var _gt = get_tree()
	if _gt and _gt.root:
		var ui = _gt.root.get_node_or_null("UIManager")
		if ui:
			return ui
	return null

func _run_verification():
	"""Ejecutar verificación de escenas después de setup_game()"""
	# Run automatic scene verification and log results
	if ResourceLoader.exists("res://scripts/tools/verify_scenes.gd"):
		var vs_script = load("res://scripts/tools/verify_scenes.gd")
		if vs_script:
			var verifier = vs_script.new()
			# verifier might extend SceneTree (when intended to run with --script).
			# add_child expects a Node; only add if verifier is a Node.
			if verifier is Node:
				add_child(verifier)
			# run checks regardless of whether it was parented
			if verifier and verifier.has_method("run_checks"):
				verifier.run_checks()
			var report = ""
			if verifier and verifier.has_method("get_report"):
				report = verifier.get_report()
			if report.find("MISSING/ERROR") != -1:
				print("[VERIFY] Errors found in scene verification:\n", report)
			else:
				print("[VERIFY] All scenes verified OK:\n", report)
	
	# Run combat diagnostics
	call_deferred("_run_combat_diagnostics")

func _run_combat_diagnostics() -> void:
	"""Ejecutar diagnósticos del sistema de combate"""
	if ResourceLoader.exists("res://scripts/tools/CombatDiagnostics.gd"):
		var diag_script = load("res://scripts/tools/CombatDiagnostics.gd")
		if diag_script:
			var diagnostics = diag_script.new()
			diagnostics.name = "CombatDiagnostics"
			add_child(diagnostics)
	
	# Add WorldMovementDiagnostics for continuous monitoring
	if ResourceLoader.exists("res://scripts/tools/WorldMovementDiagnostics.gd"):
		var wmd_script = load("res://scripts/tools/WorldMovementDiagnostics.gd")
		if wmd_script:
			var wmd = wmd_script.new()
			wmd.name = "WorldMovementDiagnostics"
			add_child(wmd)

func setup_game():
	"""Configurar todos los sistemas del juego"""
	
	# Crear player fijo en el centro
	create_player()

	# Ensure core singletons/nodes are present under the scene root so other systems can find them via get_tree().root
	# InputManager
	var _gt2 = get_tree()
	if _gt2 and _gt2.root:
		var input_mgr = _gt2.root.get_node_or_null("InputManager")
		if not input_mgr:
			if ResourceLoader.exists("res://scripts/core/InputManager.gd"):
				var im = load("res://scripts/core/InputManager.gd").new()
				im.name = "InputManager"
				_gt2.root.add_child(im)

	# SpriteDB
	var _gt3 = get_tree()
	if _gt3 and _gt3.root:
		var sprite_db = _gt3.root.get_node_or_null("SpriteDB")
		if not sprite_db:
			if ResourceLoader.exists("res://scripts/core/SpriteDB.gd"):
				var sdb = load("res://scripts/core/SpriteDB.gd").new()
				sdb.name = "SpriteDB"
				_gt3.root.add_child(sdb)

	# AudioManager singleton: ensure exists so SFX can play
	if _gt3 and _gt3.root:
		var audio_mgr = _gt3.root.get_node_or_null("AudioManager")
		if not audio_mgr:
			if ResourceLoader.exists("res://scripts/core/AudioManager.gd"):
				var am = load("res://scripts/core/AudioManager.gd").new()
				am.name = "AudioManager"
				_gt3.root.add_child(am)

	# ParticleManager singleton
	if _gt3 and _gt3.root:
		var particle_mgr = _gt3.root.get_node_or_null("ParticleManager")
		if not particle_mgr:
			if ResourceLoader.exists("res://scripts/core/ParticleManager.gd"):
				var pm = load("res://scripts/core/ParticleManager.gd").new()
				pm.name = "ParticleManager"
				_gt3.root.add_child(pm)

	# OptionsMenu (UI) - create simple options menu node under UI layer if not exists
	if _gt3 and _gt3.root:
		var options_mgr = _gt3.root.get_node_or_null("OptionsMenu")
		if not options_mgr:
			if ResourceLoader.exists("res://scenes/ui/OptionsMenu.tscn"):
				var om_res = ResourceLoader.load("res://scenes/ui/OptionsMenu.tscn")
				if om_res and om_res is PackedScene:
					var om = om_res.instantiate()
					om.name = "OptionsMenu"
					# attach to UI layer if available
					if ui_layer:
						ui_layer.add_child(om)
					else:
						_gt3.root.add_child(om)
	
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

	# Ensure Camera2D exists and is parented to the root (fixed camera)
	if has_node("WorldRoot/Camera2D"):
		var cam_candidate = get_node("WorldRoot/Camera2D")
		# Reparent to root so camera stays fixed and the world moves under it
		if cam_candidate and cam_candidate.get_parent() and cam_candidate.get_parent().name == "WorldRoot":
			remove_child(cam_candidate)
			add_child(cam_candidate)
		world_camera = cam_candidate
	elif has_node("Camera2D"):
		world_camera = get_node("Camera2D")

	if not world_camera:
		var cam = Camera2D.new()
		cam.name = "Camera2D"
		add_child(cam)
		world_camera = cam

	# Activar cámara (Godot 4.5: usar 'enabled' en lugar de 'make_current()')
	if world_camera:
		world_camera.enabled = true
	
	# Inicializar sistemas
	initialize_systems()
	
	# Comenzar juego
	start_game()

func create_player():
	"""Crear player centrado en pantalla"""
	print("[SpellloopGame] Creando player...")
	
	# Intentar instanciar la escena del player
	var player_scene_path = "res://scenes/player/SpellloopPlayer.tscn"
	var player_script = null
	var p_res = null

	if ResourceLoader.exists(player_scene_path):
		p_res = ResourceLoader.load(player_scene_path)
		if p_res and p_res is PackedScene:
			player = p_res.instantiate()
	
	if not player:
		player_script = load("res://scripts/entities/SpellloopPlayer.gd")
		if player_script:
			player = player_script.new()
		else:
			player = CharacterBody2D.new()

	player.name = "Player"
	player.position = Vector2(2880, 1620)  # Centro del chunk (0,0) - cuadrante 5 de 3×3

	# Parentear bajo WorldRoot si existe
	if has_node("WorldRoot"):
		var wr = get_node("WorldRoot")
		wr.add_child(player)
	else:
		add_child(player)
	
	# Actualizar cámara (Godot 4.5: usar 'enabled' en lugar de 'make_current()')
	if world_camera and player:
		world_camera.position = player.position
		world_camera.enabled = true
	
	print("🧙 Jugador creado en posición: ", player.position)

func create_world_manager():
	"""Crear gestor de mundo infinito"""
	world_manager = InfiniteWorldManager.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)

func create_enemy_manager():
	"""Crear gestor de enemigos"""
	# Instanciar mediante load() para evitar problemas de resolución de class_name en tiempo de carga
	var em_script = null
	if ResourceLoader.exists("res://scripts/core/EnemyManager.gd"):
		em_script = load("res://scripts/core/EnemyManager.gd")
	if em_script:
		enemy_manager = em_script.new()
		enemy_manager.name = "EnemyManager"
		add_child(enemy_manager)
	else:
		push_error("Failed to load EnemyManager script")

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
	
	# Add CombatSystemMonitor to UI
	if ResourceLoader.exists("res://scripts/tools/CombatSystemMonitor.gd"):
		var csm_script = load("res://scripts/tools/CombatSystemMonitor.gd")
		if csm_script:
			var combat_monitor = csm_script.new()
			combat_monitor.name = "CombatSystemMonitor"
			ui_layer.add_child(combat_monitor)
			print("[SpellloopGame] ✓ CombatSystemMonitor añadido a UI")
	
	# Add QuickCombatDebug
	if ResourceLoader.exists("res://scripts/tools/QuickCombatDebug.gd"):
		var qcd_script = load("res://scripts/tools/QuickCombatDebug.gd")
		if qcd_script:
			var quick_debug = qcd_script.new()
			quick_debug.name = "QuickCombatDebug"
			add_child(quick_debug)
			print("[SpellloopGame] ✓ QuickCombatDebug cargado (Presiona D/P/L)")

func create_minimap():
	"""Crear sistema de minimapa"""
	minimap = MinimapSystem.new()
	minimap.name = "MinimapSystem"
	ui_layer.add_child(minimap)

func initialize_systems():
	"""Inicializar todos los sistemas"""
	print("[SpellloopGame] Inicializando sistemas...")
	
	# Crear VisualCalibrator si no existe
	if not get_tree().root.get_node_or_null("VisualCalibrator"):
		var vc = load("res://scripts/core/VisualCalibrator.gd").new()
		vc.name = "VisualCalibrator"
		get_tree().root.add_child(vc)
	
	# Crear DifficultyManager si no existe
	if not get_tree().root.get_node_or_null("DifficultyManager"):
		var dm = load("res://scripts/core/DifficultyManager.gd").new()
		dm.name = "DifficultyManager"
		get_tree().root.add_child(dm)
	
	# Crear GlobalVolumeController si no existe
	if not get_tree().root.get_node_or_null("GlobalVolumeController"):
		var gvc = load("res://scripts/core/GlobalVolumeController.gd").new()
		gvc.name = "GlobalVolumeController"
		get_tree().root.add_child(gvc)
	
	# Inicializar mundo infinito
	if has_node("WorldRoot/ChunksRoot"):
		world_manager.set_chunks_root(get_node("WorldRoot/ChunksRoot"))
		print("[SpellloopGame] ✅ chunks_root asignado: %s" % world_manager.chunks_root.name)
	else:
		print("[SpellloopGame] ❌ ERROR: ChunksRoot no encontrado en escena")
	world_manager.initialize(player)
	
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
	
	# Inicializar HUD
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
	
	print("[SpellloopGame] Sistemas inicializados correctamente")

func connect_systems():
	"""Conectar señales entre sistemas"""
	print("[SpellloopGame] Conectando sistemas...")
	
	# NOTE: Player movement is now handled directly in _process() via InputManager.get_movement_vector()
	# The old movement_input signal-based approach is deprecated
	
	# Player muerte -> Game Over
	if player and player.has_signal("player_died"):
		if not player.player_died.is_connected(Callable(self, "_on_player_died")):
			player.player_died.connect(_on_player_died)
	
	# Enemigos muertos -> EXP
	if enemy_manager and enemy_manager.has_signal("enemy_died"):
		if not enemy_manager.enemy_died.is_connected(Callable(self, "_on_enemy_died")):
			enemy_manager.enemy_died.connect(_on_enemy_died)
	
	# EXP -> Level up
	if experience_manager and experience_manager.has_signal("level_up"):
		if not experience_manager.level_up.is_connected(Callable(self, "_on_level_up")):
			experience_manager.level_up.connect(_on_level_up)
	
	# EXP -> HUD
	if experience_manager and experience_manager.has_signal("exp_gained"):
		if not experience_manager.exp_gained.is_connected(Callable(self, "_on_exp_gained")):
			experience_manager.exp_gained.connect(_on_exp_gained)
	
	# Boss spawned
	if enemy_manager and enemy_manager.has_signal("boss_spawned"):
		if not enemy_manager.boss_spawned.is_connected(Callable(self, "_on_boss_spawned")):
			enemy_manager.boss_spawned.connect(_on_boss_spawned)

func _on_player_died():
	"""Cuando el player muere"""
	game_running = false
	var ui = _get_ui()
	if ui:
		ui.show_game_over_menu({"level": experience_manager.current_level if experience_manager else 1})

func start_game():
	"""Iniciar el juego"""
	game_running = true
	print("🎮 ¡Spellloop Game iniciado!")
	# Start GameManager run timer if available
	if get_tree() and get_tree().root:
		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm and not gm.is_run_active and gm.has_method("start_new_run"):
			gm.start_new_run()
	# Local fallback start time for HUD if GameManager not present
	if run_start_time == 0:
		run_start_time = int(get_unix_time_safe())
	# Start HUD timer
	# Start HUD timer only after GameHUD is available. If not yet present, poll a few times.
	if hud_timer:
		# If UIManager already has a game_hud, start immediately
		var ui = _get_ui()
		if ui and ui.game_hud:
			hud_timer.start()
		else:
			# Start a small one-shot timer to attempt starting HUD after UI has had time to create the game_hud
			var retry = Timer.new()
			retry.wait_time = 0.25
			retry.one_shot = true
			retry.name = "HUDStartRetry"
			add_child(retry)
			var cb = Callable(self, "_on_hud_start_retry").bind(hud_timer)
			retry.timeout.connect(cb)
			retry.start()

	# Wire enemy_manager wave manager if not already wired
	if enemy_manager and not enemy_manager.wave_manager and waves_manager:
		enemy_manager.wave_manager = waves_manager




func _on_enemy_died(enemy_position: Vector2, _enemy_type: String, exp_value: int):
	"""Manejar muerte de enemigo"""
	if experience_manager:
		# Crear bolita de EXP en la posición del enemigo
		experience_manager.create_exp_orb(enemy_position, exp_value)
	
	# Crear orbe de oro (valor simple basado en exp_value)
	var gold_amount = max(1, int(float(exp_value) / 2.0))
	if experience_manager and experience_manager.has_method("create_gold_orb"):
		experience_manager.create_gold_orb(enemy_position + Vector2(8, 0), gold_amount)

	# Si el enemigo era un boss/elite (mejor heurística: _enemy_type contiene 'boss' o el nodo tiene flag), crear drop garantizado
	var was_boss = false
	if _enemy_type.findn("boss") != -1:
		was_boss = true
	# también intentar inspeccionar la escena en la posición para buscar nodos que sean clase Boss*
	if not was_boss:
		# Try best-effort: see if any in enemy_manager.get_enemies_in_range is non-null and has exported 'boss_name' or 'slug'
		if enemy_manager:
			for e in enemy_manager.get_enemies_in_range(enemy_position, 8.0):
				if is_instance_valid(e):
					# Check metadata and properties safely
					if e.has_meta("is_boss"):
						was_boss = true
						break
					# Some enemy scenes may export 'boss_name' or 'slug' as properties; use get() defensively
					var bname = null
					if e.has_method("get"):
						bname = e.get("boss_name")
					if bname != null:
						was_boss = true
						break
					var slug = null
					if e.has_method("get"):
						slug = e.get("slug")
					if slug != null:
						was_boss = true
						break

	if was_boss:
		# Create guaranteed boss chest at enemy position
		if item_manager and item_manager.has_method("create_boss_drop"):
			item_manager.create_boss_drop(enemy_position, _enemy_type)
		# Try play boss death music or revert
		if get_tree() and get_tree().root:
			var am = get_tree().root.get_node_or_null("AudioManager")
			if am and am.has_method("play_boss_music"):
				am.play_boss_music()

		# Update SaveManager statistics for bosses defeated (best-effort, non-blocking)
		if get_tree() and get_tree().root:
			var sm = get_tree().root.get_node_or_null("SaveManager")
			if sm and sm.has("current_save_data"):
				var csd = sm.get("current_save_data")
				if csd != null and typeof(csd) == TYPE_DICTIONARY and csd.has("statistics"):
					csd["statistics"]["bosses_defeated"] = csd["statistics"].get("bosses_defeated", 0) + 1
			# Persist if API available
			if sm and sm.has_method("save_game_data"):
				sm.save_game_data()


func _on_hud_tick() -> void:
	# Update HUD timer every second using GameManager's formatted time
	var ui = _get_ui()
	if not ui:
		return
	var updated = false
	if get_tree() and get_tree().root:
		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm and gm.has_method("get_game_time_formatted"):
			var timestr = gm.get_game_time_formatted()
			var parts = timestr.split(":")
			if parts.size() == 2:
				var mins = int(parts[0])
				var secs = int(parts[1])
				var total = mins * 60 + secs
				ui.update_hud_timer(total)
				# Wave handling: every wave_interval_sec seconds start a new wave and spawn boss
				if total >= 0:
					var wave_idx = int(float(total) / float(wave_interval_sec))
					if wave_idx > current_wave:
						current_wave = wave_idx
						# Reset boss flag for the new wave so the boss can spawn later in the interval
						_boss_spawned_at_5s = false
						# Announce the wave start
						if ui and ui.has_method("show_wave_message"):
							ui.show_wave_message("Wave %d started" % (current_wave + 1), 4.0)
				# Check for boss spawn at wave midpoint or at configured moment (default: at end of interval)
				if total >= wave_interval_sec and not _boss_spawned_at_5s:
					_boss_spawned_at_5s = true
					var wave_number = int(float(total) / float(wave_interval_sec)) + 1
					if ui and ui.has_method("show_wave_message"):
						ui.show_wave_message("Wave %d - Boss Incoming!" % wave_number, 6.0)
					if enemy_manager and enemy_manager.has_method("spawn_elite"):
						enemy_manager.spawn_elite()
				updated = true
	# Fallback: calcular tiempo desde run_start_time si GameManager no disponible
	if not updated:
		if run_start_time == 0:
			run_start_time = int(get_unix_time_safe())
		var total_secs = int(int(get_unix_time_safe()) - run_start_time)
		ui.update_hud_timer(total_secs)
		# Local fallback boss spawn check
		if total_secs >= 300 and not _boss_spawned_at_5s:
			_boss_spawned_at_5s = true
			if enemy_manager and enemy_manager.has_method("spawn_elite"):
				enemy_manager.spawn_elite()

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
		# Also show a short HUD notification that the boss has arrived
		if ui and ui.has_method("show_wave_message"):
			ui.show_wave_message("Boss spawned: %s" % bname, 4.0)
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
	# Actualizar stats - USAR HEALTH COMPONENT SI EXISTE
	var hp = 100
	var max_hp = 100
	if player:
		if player.has_method("get_hp"):
			hp = player.get_hp()
			max_hp = player.get_max_hp()
		elif player.has_node("HealthComponent"):
			var health_comp = player.get_node("HealthComponent")
			if health_comp.has_method("get_current_health"):
				hp = health_comp.get_current_health()
				max_hp = health_comp.max_health
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
	# Actualizar timer - USAR GAMEMANAGER PARA TIEMPO CORRECTO
	var seconds = 0
	if get_tree() and get_tree().root:
		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm and gm.has_method("get_elapsed_seconds"):
			seconds = int(gm.get_elapsed_seconds())
	# Fallback si GameManager no disponible
	if seconds == 0 and run_start_time != 0:
		seconds = int(int(get_unix_time_safe()) - run_start_time)
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

	# Backup: ensure boss spawn at 5:00 if EnemyManager didn't trigger
	# Calculate total run seconds via GameManager or fallback
	var _total_seconds = 0
	if get_tree() and get_tree().root:
		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm and gm.has_method("get_elapsed_seconds"):
			_total_seconds = int(gm.get_elapsed_seconds())
	
	if _total_seconds == 0:
		if run_start_time != 0:
			_total_seconds = int(int(get_unix_time_safe()) - run_start_time)

	# Poll InputManager for movement vector and move world accordingly so WASD moves the world
	if get_tree() and get_tree().root and world_manager:
		var im = get_tree().root.get_node_or_null("InputManager")
		if im and im.has_method("get_movement_vector"):
			var dir = im.get_movement_vector()
			if dir.length() > 0:
				world_manager.move_world(dir, _delta)


func get_unix_time_safe() -> float:
	"""Devuelve un timestamp unix (float). Intenta usar Time.get_time_dict_from_system() y si falla, usa fallbacks conocidos.
	"""
	# Prefer Time.get_time_dict_from_system() if present
	if Time and Time.has_method("get_time_dict_from_system"):
		var tdict = Time.get_time_dict_from_system()
		if typeof(tdict) == TYPE_DICTIONARY and tdict.has("unix"):
			return float(tdict["unix"])

	# Fallback a OS.get_unix_time_from_system() si existe
	if OS and OS.has_method("get_unix_time_from_system"):
		var val = OS.call("get_unix_time_from_system")
		if typeof(val) in [TYPE_INT, TYPE_FLOAT]:
			return float(val)

	# Último recurso: usar ticks del engine como número monotónico
	return float(Engine.get_physics_frames())

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

func _on_hud_start_retry(hud_timer_ref):
	"""Helper: called shortly after setup to ensure HUD timer starts after GameHUD created."""
	var ui = _get_ui()
	if ui and ui.game_hud:
		if hud_timer_ref and hud_timer_ref.has_method("start"):
			hud_timer_ref.start()
			print("[SpellloopGame] HUD timer started after GameHUD available")
			return
	# Fallback: start anyway to avoid leaving timer stopped
	if hud_timer_ref and hud_timer_ref.has_method("start"):
		hud_timer_ref.start()
		print("[SpellloopGame] HUDStartRetry: GameHUD not found, starting HUD timer as fallback")
