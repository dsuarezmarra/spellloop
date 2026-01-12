# CharacterSelectScreen.gd
# Pantalla de selección de personaje
# Muestra los 10 personajes con sus stats, arma inicial y estado de desbloqueo

extends Control
class_name CharacterSelectScreen

signal character_selected(character_id: String)
signal back_pressed

# Referencias UI principales
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var characters_grid: GridContainer = $Panel/VBoxContainer/HBoxMain/CharactersScroll/CharactersGrid
@onready var character_preview: Control = $Panel/VBoxContainer/HBoxMain/CharacterPreview
@onready var back_button: Button = $Panel/VBoxContainer/BackButton
@onready var play_button: Button = $Panel/VBoxContainer/PlayButton

# Preview elements
@onready var preview_portrait: TextureRect = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/Portrait
@onready var preview_name: Label = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/NameLabel
@onready var preview_title: Label = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/TitleLabel
@onready var preview_description: Label = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/DescriptionLabel
@onready var preview_weapon: Label = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/WeaponLabel
@onready var preview_passive: Label = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/PassiveLabel
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/HBoxMain/CharacterPreview/VBoxContainer/StatsContainer

# Estado
var character_buttons: Array[Button] = []
var current_character_index: int = 0
var selected_character_id: String = ""
var all_characters: Array = []
var unlocked_character_ids: Array = []

# Navegación WASD
var grid_columns: int = 5  # Personajes por fila

func _ready() -> void:
	_load_characters()
	_create_character_grid()
	_setup_navigation()
	_connect_signals()

	# Seleccionar primer personaje desbloqueado
	_select_first_unlocked()

	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _load_characters() -> void:
	"""Cargar datos de personajes"""
	all_characters = CharacterDatabase.get_all_characters()

	# TODO: Cargar personajes desbloqueados del SaveManager
	# Por ahora, solo los starters + para testing todos desbloqueados
	unlocked_character_ids = []
	for char_data in all_characters:
		# Para testing: todos desbloqueados
		# En producción: verificar save data
		unlocked_character_ids.append(char_data.id)

func _create_character_grid() -> void:
	"""Crear grid de personajes"""
	if not characters_grid:
		return

	# Limpiar grid existente
	for child in characters_grid.get_children():
		child.queue_free()

	character_buttons.clear()

	# Configurar grid
	characters_grid.columns = grid_columns

	for i in range(all_characters.size()):
		var char_data = all_characters[i]
		var btn = _create_character_button(char_data, i)
		characters_grid.add_child(btn)
		character_buttons.append(btn)

func _create_character_button(char_data: Dictionary, index: int) -> Button:
	"""Crear botón de personaje"""
	var btn = Button.new()
	btn.name = "Char_" + char_data.id
	btn.custom_minimum_size = Vector2(120, 140)
	btn.focus_mode = Control.FOCUS_ALL

	var is_unlocked = char_data.id in unlocked_character_ids

	# Contenido del botón
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)

	# Icono/Emoji grande
	var icon_label = Label.new()
	icon_label.name = "Icon"
	icon_label.text = char_data.icon if is_unlocked else "??"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	# Nombre
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.text = char_data.name_es if is_unlocked else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	vbox.add_child(name_label)

	# Elemento
	var element_label = Label.new()
	element_label.name = "Element"
	element_label.text = _get_element_name(char_data.element) if is_unlocked else ""
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", 11)
	element_label.add_theme_color_override("font_color", char_data.color_primary if is_unlocked else Color(0.4, 0.4, 0.4))
	element_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(element_label)

	btn.add_child(vbox)

	# Estilo según estado
	if is_unlocked:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		style.border_color = char_data.color_primary
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", style)

		var style_hover = style.duplicate()
		style_hover.bg_color = Color(0.2, 0.2, 0.3, 0.95)
		style_hover.border_color = char_data.color_primary.lightened(0.3)
		btn.add_theme_stylebox_override("hover", style_hover)

		var style_focus = style.duplicate()
		style_focus.bg_color = Color(0.25, 0.25, 0.35, 1.0)
		style_focus.border_color = Color(1.0, 0.9, 0.5)
		style_focus.set_border_width_all(3)
		btn.add_theme_stylebox_override("focus", style_focus)
	else:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style.border_color = Color(0.3, 0.3, 0.3)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("focus", style)
		btn.disabled = true

	# Conectar señales
	btn.pressed.connect(_on_character_pressed.bind(index))
	btn.focus_entered.connect(_on_character_focused.bind(index))
	btn.mouse_entered.connect(_on_character_hovered.bind(index))

	return btn

func _setup_navigation() -> void:
	"""Configurar navegación WASD"""
	# Desactivar navegación por flechas en botones
	for btn in character_buttons:
		btn.focus_neighbor_top = btn.get_path()
		btn.focus_neighbor_bottom = btn.get_path()
		btn.focus_neighbor_left = btn.get_path()
		btn.focus_neighbor_right = btn.get_path()

func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

func _select_first_unlocked() -> void:
	"""Seleccionar el primer personaje desbloqueado"""
	for i in range(all_characters.size()):
		if all_characters[i].id in unlocked_character_ids:
			_select_character(i)
			break

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var handled = false

	# Navegación WASD
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_navigate_grid(0, -1)
				handled = true
			KEY_S:
				_navigate_grid(0, 1)
				handled = true
			KEY_A:
				_navigate_grid(-1, 0)
				handled = true
			KEY_D:
				_navigate_grid(1, 0)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_on_play_pressed()
				handled = true
			KEY_ESCAPE:
				_on_back_pressed()
				handled = true

	# Gamepad
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate_grid(0, -1)
				handled = true
			JOY_BUTTON_DPAD_DOWN:
				_navigate_grid(0, 1)
				handled = true
			JOY_BUTTON_DPAD_LEFT:
				_navigate_grid(-1, 0)
				handled = true
			JOY_BUTTON_DPAD_RIGHT:
				_navigate_grid(1, 0)
				handled = true
			JOY_BUTTON_A:
				_on_play_pressed()
				handled = true
			JOY_BUTTON_B:
				_on_back_pressed()
				handled = true

	if handled:
		var vp = get_viewport()
		if vp:
			vp.set_input_as_handled()

func _navigate_grid(dx: int, dy: int) -> void:
	"""Navegar en el grid de personajes"""
	var current_row = current_character_index / grid_columns
	var current_col = current_character_index % grid_columns

	var new_col = clampi(current_col + dx, 0, grid_columns - 1)
	var new_row = clampi(current_row + dy, 0, (all_characters.size() - 1) / grid_columns)

	var new_index = new_row * grid_columns + new_col
	new_index = clampi(new_index, 0, all_characters.size() - 1)

	# Solo navegar a personajes desbloqueados
	if all_characters[new_index].id in unlocked_character_ids:
		_select_character(new_index)
	else:
		# Buscar el siguiente desbloqueado en la dirección
		var search_dir = 1 if (dx > 0 or dy > 0) else -1
		for i in range(1, all_characters.size()):
			var check_index = (new_index + i * search_dir) % all_characters.size()
			if check_index < 0:
				check_index += all_characters.size()
			if all_characters[check_index].id in unlocked_character_ids:
				_select_character(check_index)
				break

func _select_character(index: int) -> void:
	"""Seleccionar un personaje"""
	if index < 0 or index >= all_characters.size():
		return

	current_character_index = index
	selected_character_id = all_characters[index].id

	# Actualizar focus visual
	if index < character_buttons.size():
		character_buttons[index].grab_focus()

	# Actualizar preview
	_update_preview(all_characters[index])

func _update_preview(char_data: Dictionary) -> void:
	"""Actualizar panel de preview con datos del personaje"""
	if preview_name:
		preview_name.text = char_data.name_es

	if preview_title:
		preview_title.text = char_data.title_es
		preview_title.add_theme_color_override("font_color", char_data.color_primary)

	if preview_description:
		preview_description.text = char_data.description_es

	if preview_weapon:
		var weapon_data = WeaponDatabase.WEAPONS.get(char_data.starting_weapon, {})
		var weapon_name = weapon_data.get("name_es", char_data.starting_weapon)
		preview_weapon.text = "??? Arma inicial: " + weapon_name

	if preview_passive:
		var passive = char_data.get("passive", {})
		preview_passive.text = "? Pasiva: " + passive.get("name_es", "None")
		preview_passive.tooltip_text = passive.get("description_es", "")

	# Actualizar stats
	_update_stats_display(char_data.stats)

	# Cargar portrait si existe
	if preview_portrait:
		var portrait_path = char_data.get("portrait", "")
		if ResourceLoader.exists(portrait_path):
			preview_portrait.texture = load(portrait_path)
		else:
			preview_portrait.texture = null

func _update_stats_display(stats: Dictionary) -> void:
	"""Actualizar display de stats"""
	if not stats_container:
		return

	# Limpiar stats anteriores
	for child in stats_container.get_children():
		child.queue_free()

	# Stats a mostrar con formato
	var stat_display = [
		{"key": "max_health", "name": "?? Vida", "format": "%d", "base": 100},
		{"key": "move_speed", "name": "?? Velocidad", "format": "%.0f", "base": 200},
		{"key": "armor", "name": "??? Armadura", "format": "%d", "base": 0},
		{"key": "damage_mult", "name": "?? Daño", "format": "x%.2f", "base": 1.0},
		{"key": "cooldown_mult", "name": "?? Cooldown", "format": "x%.2f", "base": 1.0},
		{"key": "pickup_range", "name": "?? Rango", "format": "%.0f", "base": 50},
	]

	for stat_info in stat_display:
		var value = stats.get(stat_info.key, stat_info.base)
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label = Label.new()
		name_label.text = stat_info.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 14)

		var value_label = Label.new()
		value_label.text = stat_info.format % value
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 14)

		# Colorear según si es mejor o peor que base
		if value > stat_info.base:
			value_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))  # Verde
		elif value < stat_info.base:
			value_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Rojo
		else:
			value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))  # Gris

		hbox.add_child(name_label)
		hbox.add_child(value_label)
		stats_container.add_child(hbox)

func _get_element_name(element: int) -> String:
	"""Obtener nombre del elemento"""
	match element:
		CharacterDatabase.Element.ICE: return "Hielo"
		CharacterDatabase.Element.FIRE: return "Fuego"
		CharacterDatabase.Element.LIGHTNING: return "Rayo"
		CharacterDatabase.Element.ARCANE: return "Arcano"
		CharacterDatabase.Element.SHADOW: return "Sombra"
		CharacterDatabase.Element.NATURE: return "Naturaleza"
		CharacterDatabase.Element.WIND: return "Viento"
		CharacterDatabase.Element.EARTH: return "Tierra"
		CharacterDatabase.Element.LIGHT: return "Luz"
		CharacterDatabase.Element.VOID: return "Vacío"
		_: return "???"

# ???????????????????????????????????????????????????????????????????????????????
# CALLBACKS
# ???????????????????????????????????????????????????????????????????????????????

func _on_character_pressed(index: int) -> void:
	_select_character(index)
	_on_play_pressed()

func _on_character_focused(index: int) -> void:
	_select_character(index)

func _on_character_hovered(index: int) -> void:
	if all_characters[index].id in unlocked_character_ids:
		_update_preview(all_characters[index])

func _on_play_pressed() -> void:
	if selected_character_id.is_empty():
		return

	_play_button_sound()
	character_selected.emit(selected_character_id)

func _on_back_pressed() -> void:
	_play_button_sound()
	back_pressed.emit()

func _play_button_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")

# ???????????????????????????????????????????????????????????????????????????????
# API PÚBLICA
# ???????????????????????????????????????????????????????????????????????????????

func show_screen() -> void:
	"""Mostrar la pantalla de selección"""
	visible = true
	_load_characters()  # Recargar por si hay nuevos desbloqueos
	_select_first_unlocked()

func hide_screen() -> void:
	"""Ocultar la pantalla"""
	visible = false

func get_selected_character() -> String:
	"""Obtener ID del personaje seleccionado"""
	return selected_character_id
