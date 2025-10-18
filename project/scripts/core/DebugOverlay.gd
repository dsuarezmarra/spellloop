extends Node2D
class_name DebugOverlay

var visible_debug: bool = false
var player_ref: Node2D = null
var enemy_manager: Node = null
var world_manager: Node = null
var telemetry_visible: bool = false
var _world_print_timer: float = 0.0
var _world_print_interval: float = 1.0

func _ready():
	set_process(true)
	visible = false

func setup_references(player: Node2D, enemy_mgr: Node, world_mgr: Node):
	player_ref = player
	enemy_manager = enemy_mgr
	world_manager = world_mgr

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			visible_debug = not visible_debug
			visible = visible_debug
		elif event.keycode == KEY_F4:
			if player_ref:
				print("[DEBUG F4] Player tree: ", player_ref.get_path())
				for c in player_ref.get_children():
					print(" - ", c.name, " (", c.get_class(), ")")
		elif event.keycode == KEY_F5:
			# spawn test: ask EnemyManager to spawn four enemies around player
			if enemy_manager and player_ref:
				var ppos = player_ref.global_position
				var offs = [Vector2(0, -400), Vector2(400, 0), Vector2(0, 400), Vector2(-400, 0)]
				for i in range(4):
					if enemy_manager.has_method("spawn_enemy"):
						var et = null
						if enemy_manager.enemy_types.size() > 0:
							et = enemy_manager.enemy_types[0]
						var sp = ppos + offs[i]
						enemy_manager.spawn_enemy(et, sp)
		# QA hotkeys: Ctrl+1 toggle telemetry, Ctrl+2 print world_offset, Ctrl+3 list EnemiesRoot children
	elif event.ctrl_pressed and event.keycode == KEY_1:
			telemetry_visible = not telemetry_visible
			print("[QA] Telemetry: ", telemetry_visible)
			queue_redraw()
	elif event.ctrl_pressed and event.keycode == KEY_2:
			if world_manager:
				print("[QA] world_offset = ", world_manager.world_offset)
			else:
				print("[QA] world_manager not available")
	elif event.ctrl_pressed and event.keycode == KEY_3:
			# List EnemiesRoot children if present in current scene
			var root_scene = get_tree().current_scene
			if root_scene and root_scene.has_node("WorldRoot/EnemiesRoot"):
				var er = root_scene.get_node("WorldRoot/EnemiesRoot")
				print("[QA] EnemiesRoot children (", er.get_child_count(), "):")
				for c in er.get_children():
					print(" - ", c.name, " @ ", c.global_position)
			else:
				print("[QA] EnemiesRoot not found in current scene")

func _process(_delta):
	if visible_debug:
		queue_redraw()
	# Telemetry toggle exists but rendering is intentionally minimal to avoid font issues
	# Rate-limit world offset console prints so we don't spam logs every frame.
	_world_print_timer += _delta
	if _world_print_timer >= _world_print_interval:
		_world_print_timer = 0.0
		if visible_debug and world_manager:
			print("[DEBUG] world_offset=", world_manager.world_offset)

func _draw():
	if not visible_debug:
		return
	# Draw player indicator
	if player_ref and is_instance_valid(player_ref):
		var local_pos = to_local(player_ref.global_position)
		draw_circle(local_pos, 20, Color(0,1,0,0.6))
	# Draw enemies
	if enemy_manager and enemy_manager.has_method("get_active_enemies"):
		var eps = enemy_manager.get_active_enemies()
		for epos in eps:
			var lp = to_local(epos)
			draw_circle(lp, 8, Color(1,0,0,0.6))
	# Note: world_offset logging moved to _process() and is rate-limited.
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
