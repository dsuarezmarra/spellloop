extends Control
class_name ChestSelectionPopup

signal item_selected(item: Dictionary)

var chest_items: Array = []
var selected_item: Dictionary

# Referencias UI
var background: ColorRect
var title_label: Label
var buttons_container: VBoxContainer
var item_buttons: Array[Button] = []

func _ready():
	setup_ui()
	
func setup_ui():
	"""Configurar interfaz del popup"""
	# Tamaño completo de pantalla
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Fondo semi-transparente
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Contenedor principal centrado
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(400, 300)
	add_child(main_container)
	
	# Fondo del panel
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	main_container.add_child(panel)
	
	# Configurar el panel para que ocupe todo el container
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Contenedor interno con márgenes
	var inner_container = VBoxContainer.new()
	inner_container.add_theme_constant_override("separation", 20)
	panel.add_child(inner_container)
	inner_container.position = Vector2(20, 20)
	inner_container.size = Vector2(360, 260)
	
	# Título
	title_label = Label.new()
	title_label.text = "📦 ¡Cofre Encontrado!"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_container.add_child(title_label)
	
	# Subtítulo
	var subtitle = Label.new()
	subtitle.text = "Elige una mejora:"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_container.add_child(subtitle)
	
	# Contenedor de botones
	buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 10)
	inner_container.add_child(buttons_container)

func setup_chest(chest: TreasureChest, items: Array):
	"""Configurar popup con items del cofre"""
	chest_items = items
	create_item_buttons()

func create_item_buttons():
	"""Crear botones para cada item"""
	# Limitar a 3 opciones máximo
	var options_count = min(3, chest_items.size())
	var selected_items = []
	
	# Seleccionar items aleatorios si hay más de 3
	if chest_items.size() > 3:
		var available_items = chest_items.duplicate()
		for i in range(3):
			var random_index = randi() % available_items.size()
			selected_items.append(available_items[random_index])
			available_items.remove_at(random_index)
	else:
		selected_items = chest_items.duplicate()
	
	# Crear botón para cada item
	for i in range(selected_items.size()):
		var item = selected_items[i]
		var button = create_item_button(item, i)
		buttons_container.add_child(button)
		item_buttons.append(button)

func create_item_button(item: Dictionary, index: int) -> Button:
	"""Crear botón para un item específico"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(360, 60)
	
	# Estilo del botón
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()
	
	# Colores basados en rareza
	var rarity = item.get("rarity", ItemsDefinitions.ItemRarity.WHITE)
	var rarity_color = ItemsDefinitions.get_rarity_color(rarity)
	
	style_normal.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	style_hover.bg_color = rarity_color * 0.3
	style_pressed.bg_color = rarity_color * 0.5
	
	# Aplicar bordes de rareza
	for style in [style_normal, style_hover, style_pressed]:
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = rarity_color
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Texto del botón
	var item_name = get_item_display_name(item.get("type", "unknown"))
	var rarity_name = ItemsDefinitions.get_rarity_name(rarity)
	button.text = "%s\n%s" % [item_name, rarity_name]
	button.add_theme_font_size_override("font_size", 14)
	
	# Conectar señal
	button.pressed.connect(func(): _on_item_button_pressed(item))
	
	return button

func get_item_display_name(item_type: String) -> String:
	"""Obtener nombre legible del item"""
	match item_type:
		"weapon_damage": return "⚡ Cristal de Poder"
		"weapon_speed": return "⚡ Cristal de Velocidad"
		"health_boost": return "❤️ Poción de Vida"
		"speed_boost": return "👢 Botas Élficas"
		"new_weapon": return "⚔️ Arma Nueva"
		"heal_full": return "🧪 Elixir de Curación"
		"shield_boost": return "🛡️ Amuleto de Protección"
		"crit_chance": return "💥 Gema de Crítico"
		"mana_boost": return "🔮 Cristal de Maná"
		_: return "🎁 Item Misterioso"

func _on_item_button_pressed(item: Dictionary):
	"""Manejar selección de item"""
	selected_item = item
	item_selected.emit(item)
	queue_free()

func _input(event):
	"""Manejar input del teclado"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_KP_1:
				if item_buttons.size() >= 1:
					_on_item_button_pressed(chest_items[0])
			KEY_2, KEY_KP_2:
				if item_buttons.size() >= 2:
					_on_item_button_pressed(chest_items[1])
			KEY_3, KEY_KP_3:
				if item_buttons.size() >= 3:
					_on_item_button_pressed(chest_items[2])
			KEY_ESCAPE:
				# Cancelar - seleccionar el primer item por defecto
				if chest_items.size() > 0:
					_on_item_button_pressed(chest_items[0])
