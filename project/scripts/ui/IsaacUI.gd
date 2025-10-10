# IsaacUI.gd
# UI para mostrar estadísticas del jugador estilo Isaac
extends Control

@onready var stats_label: Label
@onready var health_label: Label

var player: CharacterBody2D

func _ready():
	# Crear la UI
	setup_ui()
	
	# Buscar el jugador
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[IsaacUI] Player not found!")

func setup_ui():
	# Configurar el control principal
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(20, 80)
	size = Vector2(400, 100)
	
	# Label para mostrar vida
	health_label = Label.new()
	health_label.text = "❤️ 100/100"
	health_label.position = Vector2(0, 0)
	health_label.size = Vector2(150, 25)
	health_label.add_theme_font_size_override("font_size", 18)
	add_child(health_label)
	
	# Label para estadísticas
	stats_label = Label.new()
	stats_label.text = "DMG:10.0 SPD:0.20 SHOTS:1"
	stats_label.position = Vector2(0, 30)
	stats_label.size = Vector2(400, 25)
	stats_label.add_theme_font_size_override("font_size", 14)
	add_child(stats_label)
	
	# Instrucciones
	var instructions = Label.new()
	instructions.text = "Usa las flechas para disparar • Los items aparecerán pronto"
	instructions.position = Vector2(0, 55)
	instructions.size = Vector2(400, 20)
	instructions.add_theme_font_size_override("font_size", 12)
	add_child(instructions)
	
	print("[IsaacUI] Isaac-style UI created")

func _process(_delta):
	if player:
		update_ui()

func update_ui():
	# Actualizar vida
	health_label.text = "❤️ %d/%d" % [player.health, player.max_health]
	
	# Actualizar estadísticas
	stats_label.text = PlayerStats.get_stats_summary()
	
	# Cambiar color de la vida según el estado
	if player.health < 25:
		health_label.modulate = Color.RED
	elif player.health < 50:
		health_label.modulate = Color.ORANGE
	else:
		health_label.modulate = Color.WHITE