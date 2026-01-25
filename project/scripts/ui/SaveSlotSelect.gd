# SaveSlotSelect.gd
# Pantalla de selección de slot de guardado (estilo The Binding of Isaac)
# 3 slots independientes, cada uno con su propio progreso

extends Control
class_name SaveSlotSelect

signal slot_selected(slot_index: int)
signal back_pressed

# Referencias UI
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var slots_container: HBoxContainer = $Panel/VBoxContainer/SlotsContainer
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

# Slots
var slot_buttons: Array[Button] = []
var slot_panels: Array[PanelContainer] = []
var current_slot_index: int = 0

const NUM_SLOTS = 3

# Helper para localización
func _L(key: String, fallback: String = "") -> String:
	var loc = get_tree().root.get_node_or_null("Localization")
	if loc and loc.has_method("L"):
		var result = loc.L(key)
		# Si el resultado es la key misma, usar fallback
		if result == key and fallback != "":
			return fallback
		return result
	return fallback if fallback != "" else key

func _ready() -> void:
	_create_slot_ui()
	_load_slot_data()
	_setup_navigation()
	_connect_signals()
	
	# Focus en el primer slot
	if slot_buttons.size() > 0:
		slot_buttons[0].grab_focus()

	# Añadir fondo si no existe
	var bg_tex = load("res://assets/ui/backgrounds/main_menu_bg.png")
	
	# Fallback de carga directa
	if not bg_tex:
		var global_path = ProjectSettings.globalize_path("res://assets/ui/backgrounds/main_menu_bg.png")
		var img = Image.load_from_file(global_path)
		# Fallback bytes
		if not img and FileAccess.file_exists(global_path):
			var bytes = FileAccess.get_file_as_bytes(global_path)
			if bytes.size() > 0:
				img = Image.new()
				# Deteccion automatica
				var h = bytes.slice(0, 4)
				var err = ERR_FILE_UNRECOGNIZED
				
				if h[0] == 0xFF and h[1] == 0xD8: # JPG
					err = img.load_jpg_from_buffer(bytes)
				elif h[0] == 0x89 and h[1] == 0x50: # PNG
					err = img.load_png_from_buffer(bytes)
				elif h[0] == 0x52: # WebP (RIFF)
					err = img.load_webp_from_buffer(bytes)
				else:
					# Brute force
					err = img.load_png_from_buffer(bytes)
					if err != OK: err = img.load_jpg_from_buffer(bytes)
					if err != OK: err = img.load_webp_from_buffer(bytes)
				
				if err != OK: img = null
				
		if img:
			bg_tex = ImageTexture.create_from_image(img)
	
	if bg_tex and not has_node("BackgroundRect"):
		var bg = TextureRect.new()
		bg.name = "BackgroundRect"
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -10 # Al fondo
		add_child(bg)
		move_child(bg, 0)

func _create_slot_ui() -> void:
	"""Crear los 3 slots de guardado visualmente"""
	if not slots_container:
		return
	
	# Limpiar slots existentes
	for child in slots_container.get_children():
		child.queue_free()
	
	slot_buttons.clear()
	slot_panels.clear()
	
	for i in range(NUM_SLOTS):
		var slot_panel = _create_slot_panel(i)
		slots_container.add_child(slot_panel)
		slot_panels.append(slot_panel)

func _create_slot_panel(slot_index: int) -> PanelContainer:
	"""Crear un panel individual de slot con estilo mejorado"""
	var panel = PanelContainer.new()
	panel.name = "Slot%d" % (slot_index + 1)
	panel.custom_minimum_size = Vector2(280, 340)  # Ligeramente más grande
	
	# Estilo del panel mejorado (Premium Dark/Gold)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95) # Dark Blue/Purple background
	style.border_color = Color(1.0, 0.84, 0.0) # Gold Border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	
	# Sombra elegante
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# Margen interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(inner_vbox)
	
	# Título del slot
	var slot_title = Label.new()
	slot_title.name = "SlotTitle"
	slot_title.text = "Slot %d" % (slot_index + 1)
	slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_title.add_theme_font_size_override("font_size", 28)
	slot_title.add_theme_color_override("font_color", Color(1, 0.9, 0.6)) # Light Gold
	inner_vbox.add_child(slot_title)
	
	# Separador dorado
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 20)
	# (Opcional: Estilar el separador si fuera necesario, pero por defecto vale)
	inner_vbox.add_child(sep)
	
	# Info del slot
	var info_container = VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.add_theme_constant_override("separation", 8)
	info_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(info_container)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(spacer)
	
	# Botonera acciones
	var actions_vbox = VBoxContainer.new()
	actions_vbox.add_theme_constant_override("separation", 10)
	inner_vbox.add_child(actions_vbox)

	# Botón de seleccionar (Principal)
	var select_btn = Button.new()
	select_btn.name = "SelectButton"
	select_btn.text = "JUGAR"
	select_btn.custom_minimum_size = Vector2(0, 50)
	select_btn.add_theme_font_size_override("font_size", 20)
	# Estilo botón normal
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
	btn_style.border_color = Color(0.4, 0.4, 0.6)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	select_btn.add_theme_stylebox_override("normal", btn_style)
	
	select_btn.pressed.connect(_on_slot_selected.bind(slot_index))
	actions_vbox.add_child(select_btn)
	slot_buttons.append(select_btn)
	
	# Botón de borrar (Rojo / Danger)
	var delete_btn = Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "BORRAR / REINICIAR"
	delete_btn.custom_minimum_size = Vector2(0, 35)
	delete_btn.add_theme_font_size_override("font_size", 14)
	delete_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	
	var del_style = StyleBoxFlat.new()
	del_style.bg_color = Color(0.2, 0.05, 0.05, 0.8)
	del_style.border_color = Color(0.5, 0.1, 0.1)
	del_style.set_border_width_all(1)
	del_style.set_corner_radius_all(4)
	delete_btn.add_theme_stylebox_override("normal", del_style)

	delete_btn.pressed.connect(_on_delete_slot.bind(slot_index))
	# Inicialmente oculto, se gestiona en update
	delete_btn.visible = false 
	actions_vbox.add_child(delete_btn)
	
	# Añadir el margin container al vbox principal
	vbox.add_child(margin)
	
	return panel

func _load_slot_data() -> void:
	"""Cargar y mostrar datos de cada slot"""
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	
	for i in range(NUM_SLOTS):
		var slot_data = null
		if save_manager and save_manager.has_method("get_slot_data"):
			slot_data = save_manager.get_slot_data(i)
		
		_update_slot_display(i, slot_data)

func _update_slot_display(slot_index: int, slot_data) -> void:
	"""Actualizar la visualización de un slot"""
	if slot_index >= slot_panels.size():
		return
	
	var panel = slot_panels[slot_index]
	# Update these paths to match new hierarchy
	var info_container = panel.get_node_or_null("VBoxContainer/MarginContainer/VBoxContainer/InfoContainer")
	# The buttons are now in an actions VBox at the end of inner_vbox
	# Structure: Panel -> VBox -> Margin -> InnerVBox -> ActionsVBox (Child index 4?)
	var inner_vbox = panel.get_node_or_null("VBoxContainer/MarginContainer/VBoxContainer")
	if not inner_vbox: return
	
	var actions_vbox = inner_vbox.get_child(inner_vbox.get_child_count() - 1)
	var select_btn = actions_vbox.get_node_or_null("SelectButton")
	var delete_btn = actions_vbox.get_node_or_null("DeleteButton")
	
	if not info_container:
		return
	
	# Limpiar info anterior
	for child in info_container.get_children():
		child.queue_free()
	
	if slot_data == null or slot_data.is_empty():
		# Slot vacío
		var empty_label = Label.new()
		empty_label.text = "NUEVA PARTIDA"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6)) # Greenish for new
		info_container.add_child(empty_label)
		
		var hint_label = Label.new()
		hint_label.text = "¡Tu leyenda comienza aquí!"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		info_container.add_child(hint_label)
		
		if select_btn:
			select_btn.text = "CREAR PARTIDA"
		if delete_btn:
			delete_btn.visible = false
	else:
		# Slot con datos
		var player_data = slot_data.get("player_data", {})
		
		# Mejor puntuación
		var score_label = Label.new()
		score_label.text = "🏆 %d" % player_data.get("best_score", 0)
		score_label.add_theme_font_size_override("font_size", 20)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Gold
		info_container.add_child(score_label)
		
		# Runs e Info
		var stats_info = Label.new()
		var playtime = player_data.get("total_playtime", 0.0)
		var hours = int(playtime) / 3600
		var runs = player_data.get("total_runs", 0)
		stats_info.text = "Runs: %d | Tiempo: %dh" % [runs, hours]
		stats_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_info.add_theme_font_size_override("font_size", 14)
		stats_info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		info_container.add_child(stats_info)
		
		if select_btn:
			select_btn.text = "CONTINUAR"
		if delete_btn:
			delete_btn.visible = true

func _setup_navigation() -> void:
	"""Configurar navegación WASD"""
	# Desactivar navegación por flechas
	for btn in slot_buttons:
		btn.focus_neighbor_top = btn.get_path()
		btn.focus_neighbor_bottom = btn.get_path()
		btn.focus_neighbor_left = btn.get_path()
		btn.focus_neighbor_right = btn.get_path()
	
	if back_button:
		back_button.focus_neighbor_top = back_button.get_path()
		back_button.focus_neighbor_bottom = back_button.get_path()
		back_button.focus_neighbor_left = back_button.get_path()
		back_button.focus_neighbor_right = back_button.get_path()

func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		if not back_button.mouse_entered.is_connected(_on_element_hover):
			back_button.mouse_entered.connect(_on_element_hover)

func _on_element_hover() -> void:
	AudioManager.play_fixed("sfx_ui_hover")





func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	var handled = false
	
	# Navegación con WASD
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A:
				_navigate_slots(-1)
				handled = true
			KEY_D:
				_navigate_slots(1)
				handled = true
			KEY_W:
				_navigate_to_slots()
				handled = true
			KEY_S:
				_navigate_to_back()
				handled = true
			KEY_SPACE, KEY_ENTER:
				_activate_current()
				handled = true
			KEY_ESCAPE:
				_on_back_pressed()
				handled = true
	
	if handled:
		get_viewport().set_input_as_handled()

func _navigate_slots(direction: int) -> void:
	"""Navegar entre slots"""
	if slot_buttons.is_empty():
		return
	
	current_slot_index = wrapi(current_slot_index + direction, 0, slot_buttons.size())
	slot_buttons[current_slot_index].grab_focus()
	AudioManager.play_fixed("sfx_ui_hover")





func _navigate_to_slots() -> void:
	"""Mover focus a los slots"""
	if slot_buttons.size() > 0:
		slot_buttons[current_slot_index].grab_focus()

func _navigate_to_back() -> void:
	"""Mover focus al botón de volver"""
	if back_button:
		back_button.grab_focus()

func _activate_current() -> void:
	"""Activar el elemento con focus"""
	var focused = get_viewport().gui_get_focus_owner()
	if focused and focused is Button:
		focused.pressed.emit()

func _on_slot_selected(slot_index: int) -> void:
	"""Callback cuando se selecciona un slot"""
	_play_button_sound()
	
	# Guardar el slot seleccionado en SaveManager
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("set_active_slot"):
		save_manager.set_active_slot(slot_index)
	
	slot_selected.emit(slot_index)

func _on_delete_slot(slot_index: int) -> void:
	"""Callback para borrar un slot"""
	# Mostrar confirmación
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "¿Borrar Slot %d?\n\nEsto eliminará TODO el progreso\nde esta partida permanentemente." % (slot_index + 1)
	confirm_dialog.ok_button_text = "Borrar"
	confirm_dialog.cancel_button_text = "Cancelar"
	confirm_dialog.confirmed.connect(_confirm_delete_slot.bind(slot_index))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _confirm_delete_slot(slot_index: int) -> void:
	"""Confirmar borrado de slot"""
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("delete_slot"):
		save_manager.delete_slot(slot_index)
	
	# Recargar datos
	_load_slot_data()

func _on_back_pressed() -> void:
	"""Volver atrás"""
	_play_button_sound()
	back_pressed.emit()

func _play_button_sound() -> void:
	AudioManager.play_fixed("sfx_ui_click")

func refresh() -> void:
	"""Refrescar los datos de los slots"""
	_load_slot_data()
