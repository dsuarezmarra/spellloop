# Isaac Sprite Viewer - Visualizador de sprites estilo Isaac
extends Control

var wizard_sprites = {}
var enemy_sprites = {}
var current_wizard_dir = WizardSpriteLoader.Direction.DOWN
var current_wizard_frame = WizardSpriteLoader.AnimFrame.IDLE
var current_enemy_type = FunkoPopEnemyIsaac.EnemyType.GOBLIN_MAGE
var current_enemy_dir = FunkoPopEnemyIsaac.Direction.DOWN
var current_enemy_frame = FunkoPopEnemyIsaac.AnimFrame.IDLE

func _ready():
	print("=== VISUALIZADOR DE SPRITES ISAAC + FUNKO POP ===")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Generate all sprites
	generate_all_sprites()
	create_ui()
	
	print("✓ Sprites Isaac-style generados")
	print("✓ UI creada")
	print("Usa las teclas para navegar por los sprites:")
	print("  WASD - Cambiar dirección del mago")
	print("  Space - Cambiar frame del mago")
	print("  1234 - Cambiar tipo de enemigo")
	print("  Flechas - Cambiar dirección del enemigo")
	print("  Enter - Cambiar frame del enemigo")

func generate_all_sprites():
	"""Generate all wizard and enemy sprites"""
	# Generate wizard sprites usando el nuevo sistema
	for dir in WizardSpriteLoader.Direction.values():
		wizard_sprites[dir] = {}
		for frame in WizardSpriteLoader.AnimFrame.values():
			wizard_sprites[dir][frame] = WizardSpriteLoader.create_wizard_sprite(dir, frame)
	
	# Generate enemy sprites (mantenemos el sistema anterior)
	for enemy_type in FunkoPopEnemyIsaac.EnemyType.values():
		enemy_sprites[enemy_type] = {}
		for dir in FunkoPopEnemyIsaac.Direction.values():
			enemy_sprites[enemy_type][dir] = {}
			for frame in FunkoPopEnemyIsaac.AnimFrame.values():
				enemy_sprites[enemy_type][dir][frame] = FunkoPopEnemyIsaac.create_enemy_sprite(enemy_type, dir, frame)

func create_ui():
	"""Create the UI"""
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.25)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "SPRITES ISAAC + FUNKO POP + MAGIA"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.position = Vector2(50, 20)
	add_child(title)
	
	# Wizard section
	create_wizard_section()
	
	# Enemy section
	create_enemy_section()
	
	# Instructions
	create_instructions()

func create_wizard_section():
	"""Create wizard sprite display section"""
	var wizard_label = Label.new()
	wizard_label.text = "🧙 MAGO ESTILO ISAAC"
	wizard_label.add_theme_font_size_override("font_size", 24)
	wizard_label.add_theme_color_override("font_color", Color.CYAN)
	wizard_label.position = Vector2(100, 100)
	add_child(wizard_label)
	
	# Wizard sprite display
	var wizard_sprite = TextureRect.new()
	wizard_sprite.name = "WizardSprite"
	wizard_sprite.texture = wizard_sprites[current_wizard_dir][current_wizard_frame]
	wizard_sprite.position = Vector2(150, 150)
	wizard_sprite.custom_minimum_size = Vector2(96, 128)  # Scale up for visibility
	wizard_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	add_child(wizard_sprite)
	
	# Wizard info
	var wizard_info = Label.new()
	wizard_info.name = "WizardInfo"
	wizard_info.add_theme_font_size_override("font_size", 16)
	wizard_info.add_theme_color_override("font_color", Color.WHITE)
	wizard_info.position = Vector2(100, 290)
	update_wizard_info(wizard_info)
	add_child(wizard_info)

func create_enemy_section():
	"""Create enemy sprite display section"""
	var enemy_label = Label.new()
	enemy_label.text = "👾 ENEMIGOS MÁGICOS"
	enemy_label.add_theme_font_size_override("font_size", 24)
	enemy_label.add_theme_color_override("font_color", Color.RED)
	enemy_label.position = Vector2(400, 100)
	add_child(enemy_label)
	
	# Enemy sprite display
	var enemy_sprite = TextureRect.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.texture = enemy_sprites[current_enemy_type][current_enemy_dir][current_enemy_frame]
	enemy_sprite.position = Vector2(450, 150)
	enemy_sprite.custom_minimum_size = Vector2(96, 128)  # Scale up for visibility
	enemy_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	add_child(enemy_sprite)
	
	# Enemy info
	var enemy_info = Label.new()
	enemy_info.name = "EnemyInfo"
	enemy_info.add_theme_font_size_override("font_size", 16)
	enemy_info.add_theme_color_override("font_color", Color.WHITE)
	enemy_info.position = Vector2(400, 290)
	update_enemy_info(enemy_info)
	add_child(enemy_info)

func create_instructions():
	"""Create instruction panel"""
	var instructions = Label.new()
	instructions.text = """🎮 CONTROLES:

🧙 MAGO:
  WASD - Cambiar dirección
  SPACE - Cambiar frame de animación

👾 ENEMIGOS:
  1234 - Cambiar tipo de enemigo
  ↑↓←→ - Cambiar dirección
  ENTER - Cambiar frame de animación

CARACTERÍSTICAS:
✓ Cabezas grandes estilo Isaac
✓ Características Funko Pop  
✓ Temática mágica completa
✓ 4 tipos de enemigos únicos
✓ Animaciones direccionales

ESC - Salir"""
	
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	instructions.position = Vector2(700, 100)
	add_child(instructions)

func update_wizard_info(info_label):
	"""Update wizard information display"""
	var dir_name = WizardSpriteLoader.Direction.keys()[current_wizard_dir]
	var frame_name = WizardSpriteLoader.AnimFrame.keys()[current_wizard_frame]
	
	info_label.text = """Dirección: %s
Frame: %s
Tamaño: 48x64px
Estilo: Isaac + Funko + Magia

Elementos:
• Cabeza ovalada grande
• Sombrero de mago
• Túnica mágica
• Efectos místicos""" % [dir_name, frame_name]

func update_enemy_info(info_label):
	"""Update enemy information display"""
	var type_name = FunkoPopEnemyIsaac.EnemyType.keys()[current_enemy_type]
	var dir_name = FunkoPopEnemyIsaac.Direction.keys()[current_enemy_dir]
	var frame_name = FunkoPopEnemyIsaac.AnimFrame.keys()[current_enemy_frame]
	
	var descriptions = {
		FunkoPopEnemyIsaac.EnemyType.GOBLIN_MAGE: "Magia de naturaleza",
		FunkoPopEnemyIsaac.EnemyType.SKELETON_WIZARD: "Nigromancia",
		FunkoPopEnemyIsaac.EnemyType.DARK_SPIRIT: "Magia sombría",
		FunkoPopEnemyIsaac.EnemyType.FIRE_IMP: "Magia de fuego"
	}
	
	info_label.text = """Tipo: %s
Dirección: %s
Frame: %s
Especialidad: %s

Características Isaac:
• Proporciones 3:1
• Ojos grandes circulares
• Formas simplificadas""" % [type_name, dir_name, frame_name, descriptions[current_enemy_type]]

func _input(event):
	"""Handle input for sprite navigation"""
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()
		return
	
	var changed = false
	
	# Wizard controls
	if event.is_action_pressed("move_up"):  # W
		current_wizard_dir = WizardSpriteLoader.Direction.UP
		changed = true
	elif event.is_action_pressed("move_down"):  # S
		current_wizard_dir = WizardSpriteLoader.Direction.DOWN
		changed = true
	elif event.is_action_pressed("move_left"):  # A
		current_wizard_dir = WizardSpriteLoader.Direction.LEFT
		changed = true
	elif event.is_action_pressed("move_right"):  # D
		current_wizard_dir = WizardSpriteLoader.Direction.RIGHT
		changed = true
	elif event.is_action_pressed("ui_accept"):  # SPACE
		var frames = WizardSpriteLoader.AnimFrame.values()
		var current_idx = frames.find(current_wizard_frame)
		current_wizard_frame = frames[(current_idx + 1) % frames.size()]
		changed = true
	
	# Enemy type controls
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_enemy_type = FunkoPopEnemyIsaac.EnemyType.GOBLIN_MAGE
				changed = true
			KEY_2:
				current_enemy_type = FunkoPopEnemyIsaac.EnemyType.SKELETON_WIZARD
				changed = true
			KEY_3:
				current_enemy_type = FunkoPopEnemyIsaac.EnemyType.DARK_SPIRIT
				changed = true
			KEY_4:
				current_enemy_type = FunkoPopEnemyIsaac.EnemyType.FIRE_IMP
				changed = true
			KEY_UP:
				current_enemy_dir = FunkoPopEnemyIsaac.Direction.UP
				changed = true
			KEY_DOWN:
				current_enemy_dir = FunkoPopEnemyIsaac.Direction.DOWN
				changed = true
			KEY_LEFT:
				current_enemy_dir = FunkoPopEnemyIsaac.Direction.LEFT
				changed = true
			KEY_RIGHT:
				current_enemy_dir = FunkoPopEnemyIsaac.Direction.RIGHT
				changed = true
			KEY_ENTER:
				var frames = FunkoPopEnemyIsaac.AnimFrame.values()
				var current_idx = frames.find(current_enemy_frame)
				current_enemy_frame = frames[(current_idx + 1) % frames.size()]
				changed = true
	
	if changed:
		update_display()

func update_display():
	"""Update the sprite display"""
	# Update wizard sprite
	var wizard_sprite = get_node("WizardSprite")
	wizard_sprite.texture = wizard_sprites[current_wizard_dir][current_wizard_frame]
	
	# Update enemy sprite
	var enemy_sprite = get_node("EnemySprite")
	enemy_sprite.texture = enemy_sprites[current_enemy_type][current_enemy_dir][current_enemy_frame]
	
	# Update info labels
	var wizard_info = get_node("WizardInfo")
	update_wizard_info(wizard_info)
	
	var enemy_info = get_node("EnemyInfo")
	update_enemy_info(enemy_info)
	
	print("🎨 Sprite actualizado - Mago: %s/%s | Enemigo: %s/%s/%s" % [
		WizardSpriteLoader.Direction.keys()[current_wizard_dir],
		WizardSpriteLoader.AnimFrame.keys()[current_wizard_frame],
		FunkoPopEnemyIsaac.EnemyType.keys()[current_enemy_type],
		FunkoPopEnemyIsaac.Direction.keys()[current_enemy_dir],
		FunkoPopEnemyIsaac.AnimFrame.keys()[current_enemy_frame]
	])