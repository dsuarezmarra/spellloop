extends CanvasLayer

# --- UI NODES ---
var _control: Control
var _label_stats: Label
var _label_counters: Label
var _btn_toggle: Button

var visible_mode: bool = false # Starts hidden or false

func _ready() -> void:
	if Headless.is_headless():
		queue_free()
		return

	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128 # Very high layer to be on top of everything
	
	_setup_ui()
	_update_visibility()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		visible_mode = !visible_mode
		_update_visibility()

func _setup_ui() -> void:
	_control = Control.new()
	_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_control)
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Manual position adjustment if needed, but anchor works
	panel.position = Vector2(-20, 20) 
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_control.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "PERF MONITOR (F9)"
	title.add_theme_color_override("font_color", Color.ORANGE)
	vbox.add_child(title)
	
	# FPS / Frame Time
	_label_stats = Label.new()
	_label_stats.text = "FPS: -- | FT: --ms"
	vbox.add_child(_label_stats)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Counters
	_label_counters = Label.new()
	_label_counters.text = "Initializing..."
	vbox.add_child(_label_counters)

func _update_visibility() -> void:
	_control.visible = visible_mode

func _process(delta: float) -> void:
	if not visible_mode: return
	
	# Ensure PerfTracker exists
	if not get_tree().root.has_node("PerfTracker"):
		_label_stats.text = "PerfTracker not found (Autoload missing?)"
		return
		
	var tracker = get_tree().root.get_node("PerfTracker")
	var metrics = tracker.get_current_metrics()
	if metrics.is_empty(): return
	
	var fps = metrics.get("fps", 0)
	var ft = metrics.get("ft_ms", 0.0)
	var counters = metrics.get("counters", {})
	
	# Colorize FPS
	var fps_color = Color.GREEN
	if fps < 30: fps_color = Color.RED
	elif fps < 55: fps_color = Color.YELLOW
	
	_label_stats.text = "FPS: %d  (%.1f ms)" % [fps, ft]
	_label_stats.modulate = fps_color
	
	var enm = counters.get("enemies_alive", 0)
	var proj = counters.get("projectiles_alive", 0)
	var pick = counters.get("pickups_alive", 0)
	var draw = counters.get("draw_calls", 0)
	var mem = counters.get("memory_static_mb", 0)
	var phys = counters.get("physics_time_ms", 0.0)
	
	var txt = ""
	txt += "Enemies:   %d\n" % enm
	txt += "Projectiles: %d\n" % proj
	txt += "Pickups:     %d\n" % pick
	txt += "Draw Calls:  %d\n" % draw
	txt += "Memory:      %.1f MB\n" % mem
	txt += "Phys Time:   %.2f ms" % phys
	
	_label_counters.text = txt
