extends CanvasLayer
class_name LevelUpPanel

signal upgrade_selected(upgrade: Dictionary)
signal reroll_used()
signal banish_used()
signal skip_used()

var options: Array = []
var buttons: Array = []
var reroll_count: int = 2
var banish_count: int = 2
var skip_count: int = 1
var locked: bool = false

func _ready():
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	create_ui()

func create_ui():
	var bg = PanelContainer.new()
	bg.anchor_left = 0.1
	bg.anchor_top = 0.2
	bg.anchor_right = 0.9
	bg.anchor_bottom = 0.8
	add_child(bg)
	
	var v = VBoxContainer.new()
	v.anchor_right = 1.0
	v.anchor_bottom = 1.0
	bg.add_child(v)
	
	var title = Label.new()
	title.text = "Level Up! Elige una mejora"
	title.add_theme_font_size_override("font_size", 24)
	v.add_child(title)
	
	var h = HBoxContainer.new()
	h.name = "options"
	v.add_child(h)
	
	# Buttons
	for i in range(4):
		var b = Button.new()
		b.text = "Option %d" % (i+1)
		b.rect_min_size = Vector2(180, 80)
		# Connect using a small helper to avoid confusable local declaration warnings
		b.pressed.connect(_make_on_pressed(i))
		h.add_child(b)
		buttons.append(b)
	
	# Controls
	var controls = HBoxContainer.new()
	v.add_child(controls)
	
	var reroll_b = Button.new()
	reroll_b.text = "Reroll (%d)" % reroll_count
	reroll_b.pressed.connect(_on_reroll)
	controls.add_child(reroll_b)
	
	var banish_b = Button.new()
	banish_b.text = "Banish (%d)" % banish_count
	banish_b.pressed.connect(_on_banish)
	controls.add_child(banish_b)
	
	var skip_b = Button.new()
	skip_b.text = "Skip (%d)" % skip_count
	skip_b.pressed.connect(_on_skip)
	controls.add_child(skip_b)

func setup_options(opts: Array):
	options = opts.duplicate()
	for i in range(buttons.size()):
		if i < options.size():
			buttons[i].text = options[i].get("name", "Option")
			buttons[i].disabled = false
		else:
			buttons[i].text = "-"
			buttons[i].disabled = true

func _on_option_pressed(index: int):
	if locked:
		return
	locked = true
	if index < options.size():
		emit_signal("upgrade_selected", options[index])
		get_tree().paused = false
		queue_free()

func _on_reroll():
	if reroll_count <= 0 or locked:
		return
	reroll_count -= 1
	emit_signal("reroll_used")
	# Request new options from caller

func _on_banish():
	if banish_count <= 0 or locked:
		return
	banish_count -= 1
	emit_signal("banish_used")

func _on_skip():
	if skip_count <= 0 or locked:
		return
	skip_count -= 1
	emit_signal("skip_used")
	get_tree().paused = false
	queue_free()

func _make_on_pressed(index: int) -> Callable:
	return func(): _on_option_pressed(index)

