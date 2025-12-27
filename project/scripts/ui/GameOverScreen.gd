extends Control
class_name GameOverScreen

## Pantalla de Game Over
## Muestra estadísticas de la partida y opciones

signal retry_pressed
signal menu_pressed

@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/StatsContainer
@onready var retry_button: Button = $Panel/VBoxContainer/ButtonsContainer/RetryButton
@onready var menu_button: Button = $Panel/VBoxContainer/ButtonsContainer/MenuButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

# Stats de la partida
var final_stats: Dictionary = {}

func _ready() -> void:
	_connect_signals()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _connect_signals() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func show_game_over(stats: Dictionary = {}) -> void:
	final_stats = stats
	visible = true
	get_tree().paused = true
	
	_display_stats()
	
	if retry_button:
		retry_button.grab_focus()
	
	# Animación de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	_play_game_over_sound()

func _display_stats() -> void:
	if not stats_container:
		return
	
	# Limpiar stats anteriores
	for child in stats_container.get_children():
		child.queue_free()
	
	# Tiempo sobrevivido
	var time_survived = final_stats.get("time", 0.0)
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	_add_stat_line("⏱️ Tiempo", "%02d:%02d" % [minutes, seconds])
	
	# Nivel alcanzado
	var level = final_stats.get("level", 1)
	_add_stat_line("⭐ Nivel", str(level))
	
	# Enemigos eliminados
	var kills = final_stats.get("kills", 0)
	_add_stat_line("💀 Enemigos", str(kills))
	
	# XP total obtenida
	var xp = final_stats.get("xp_total", 0)
	_add_stat_line("✨ XP Total", str(xp))
	
	# Oro recogido
	var gold = final_stats.get("gold", 0)
	if gold > 0:
		_add_stat_line("🪙 Oro", str(gold))
	
	# Daño total
	var damage = final_stats.get("damage_dealt", 0)
	if damage > 0:
		_add_stat_line("⚔️ Daño Total", str(damage))

func _add_stat_line(label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	
	hbox.add_child(label)
	hbox.add_child(value)
	stats_container.add_child(hbox)

func _on_retry_pressed() -> void:
	_play_button_sound()
	retry_pressed.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_menu_pressed() -> void:
	_play_button_sound()
	menu_pressed.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _play_button_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")

func _play_game_over_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("game_over")
