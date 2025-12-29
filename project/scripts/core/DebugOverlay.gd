extends Node2D
class_name DebugOverlay

var visible_debug: bool = false
var player_ref: Node2D = null
var enemy_manager: Node = null
var arena_manager: Node = null  # Reemplaza a world_manager
var telemetry_visible: bool = false
var _world_print_timer: float = 0.0
var _world_print_interval: float = 1.0
var fps_counter: int = 0
var current_fps: int = 0
var fps_update_timer: float = 0.0

# Debug overlay node
var debug_label: Label = null

func _ready():
	set_process(true)
	set_process_unhandled_input(true)
	visible = false
	create_debug_label()

func create_debug_label() -> void:
	"""Crear etiqueta para mostrar debug info"""
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.text = "FPS: 0\nEnemies: 0"
	debug_label.position = Vector2(10, 10)
	debug_label.z_index = 9999
	add_child(debug_label)

func setup_references(player: Node2D, enemy_mgr: Node, arena_mgr: Node = null):
	player_ref = player
	enemy_manager = enemy_mgr
	arena_manager = arena_mgr

func _unhandled_input(event):
	# Handle debug hotkeys
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			visible_debug = not visible_debug
			visible = visible_debug
			if visible_debug and debug_label:
				debug_label.show()
			elif not visible_debug and debug_label:
				debug_label.hide()
		elif event.keycode == KEY_F4:
			# Información detallada de debug
			if player_ref:
				print("[DEBUG F4] Player tree: ", player_ref.get_path())
				for c in player_ref.get_children():
					print(" - ", c.name, " (", c.get_class(), ")")
			if arena_manager and arena_manager.has_method("get_info"):
				print("[DEBUG F4] arena_manager info: ", arena_manager.get_info())
		elif event.keycode == KEY_F5:
			# Spawn test enemies
			if enemy_manager and player_ref:
				var ppos = player_ref.global_position
				var offs = [Vector2(0, -400), Vector2(400, 0), Vector2(0, 400), Vector2(-400, 0)]
				for i in range(4):
					if enemy_manager.has_method("spawn_enemy"):
						var et = null
						if enemy_manager.enemy_types and enemy_manager.enemy_types.size() > 0:
							et = enemy_manager.enemy_types[0]
						var sp = ppos + offs[i]
						enemy_manager.spawn_enemy(et, sp)
		
		# QA hotkeys
		if event.ctrl_pressed:
			if event.keycode == KEY_1:
				telemetry_visible = not telemetry_visible
				print("[QA] Telemetry: ", telemetry_visible)
			elif event.keycode == KEY_2:
				if arena_manager and arena_manager.has_method("get_info"):
					print("[QA] arena_manager info: ", arena_manager.get_info())
			elif event.keycode == KEY_3:
				var root_scene = get_tree().current_scene
				if root_scene and root_scene.has_node("WorldRoot/EnemiesRoot"):
					var er = root_scene.get_node("WorldRoot/EnemiesRoot")
					print("[QA] EnemiesRoot children (", er.get_child_count(), "):")
					for c in er.get_children():
						print(" - ", c.name, " @ ", c.global_position)

func _process(delta):
	# Actualizar FPS
	fps_counter += 1
	fps_update_timer += delta
	if fps_update_timer >= 0.5:
		current_fps = int(fps_counter / fps_update_timer)
		fps_counter = 0
		fps_update_timer = 0.0
		_update_debug_label()
	
	if visible_debug:
		queue_redraw()

func _update_debug_label() -> void:
	"""Actualizar etiqueta de debug con información actual"""
	if not debug_label:
		return
	
	var enemies_count = 0
	if enemy_manager and enemy_manager.has_method("get_enemy_count"):
		enemies_count = enemy_manager.get_enemy_count()
	
	var text = "FPS: %d\n" % current_fps
	text += "Enemies: %d\n" % enemies_count
	
	if player_ref:
		text += "Player: (%.0f, %.0f)\n" % [player_ref.global_position.x, player_ref.global_position.y]
	
	debug_label.text = text

func _draw():
	if not visible_debug:
		return
	
	# Draw player indicator
	if player_ref and is_instance_valid(player_ref):
		var local_pos = to_local(player_ref.global_position)
		draw_circle(local_pos, 20, Color(0, 1, 0, 0.6))
	
	# Draw enemies
	if enemy_manager and enemy_manager.has_method("get_active_enemy_positions"):
		var eps = enemy_manager.get_active_enemy_positions()
		for epos in eps:
			var lp = to_local(epos)
			draw_circle(lp, 8, Color(1, 0, 0, 0.6))
	
	# TODO: Draw arena bounds when ArenaManager is implemented

	# Optionally draw enemy hitboxes if they expose collision shapes
	if visible_debug and enemy_manager and enemy_manager.get_enemy_count and enemy_manager.get_enemy_count() > 0:
		for e in enemy_manager.get_enemies_in_range(player_ref.global_position, 2000):
			if is_instance_valid(e) and e.has_method("get_shape_owner_count"):
				# Try to draw approximate bounding circle
				var lp = to_local(e.global_position)
				draw_circle(lp, 12, Color(1,0.2,0.2,0.25))
	# Draw telemetry overlay (console fallback)
	if telemetry_visible:
		var box_pos = Vector2(8, 8)
		var box_size = Vector2(360, 60)
		draw_rect(Rect2(box_pos, box_size), Color(0,0,0,0.5))
		# Instead of relying on DynamicFont/draw_text (which may not be available in static analysis),
		# print telemetry to the console for QA inspection.
		var player_name = "-"
		if player_ref and player_ref.has_method("get_name"):
			player_name = player_ref.name
		elif player_ref and "name" in player_ref:
			player_name = str(player_ref.name)

		var enemy_count = 0
		if enemy_manager and enemy_manager.has_method("get_active_enemies"):
			enemy_count = enemy_manager.get_active_enemies().size()

		var telemetry_text = "Telemetry: player=%s, enemies=%d" % [player_name, enemy_count]
		print("[Telemetry] ", telemetry_text)
