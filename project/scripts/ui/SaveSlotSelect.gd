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
	var bg_path = "res://assets/ui/backgrounds/main_menu_bg.jpg"
	if not FileAccess.file_exists(bg_path):
		bg_path = "res://assets/ui/backgrounds/main_menu_bg.png"
		
	var bg_tex = load(bg_path)
	
	# Fallback de carga directa
	if not bg_tex:
		var global_path = ProjectSettings.globalize_path(bg_path)
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
	"""Crear un panel individual de slot con estilo CARTA ARCANA"""
	var panel = PanelContainer.new()
	panel.name = "Slot%d" % (slot_index + 1)
	panel.custom_minimum_size = Vector2(300, 420)  # Formato carta vertical
	panel.pivot_offset = Vector2(150, 210) # Centro para animaciones
	
	# 🎨 ESTILO CARTA ARCANA
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.9) # Fondo oscuro púrpura
	style.border_color = Color(0.4, 0.3, 0.6, 1.0) # Borde inactivo (púrpura apagado)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 15
	style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", style)
	
	# Contenedor Vertical Principal
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0) # Control manual con spacers
	panel.add_child(vbox)
	
	# --- HEADER (Número de Slot) ---
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 15)
	header_margin.add_theme_constant_override("margin_bottom", 15)
	vbox.add_child(header_margin)
	
	var slot_title = Label.new()
	slot_title.name = "SlotTitle"
	slot_title.text = "SLOT %d" % (slot_index + 1)
	slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_title.add_theme_font_size_override("font_size", 20)
	slot_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7)) # Texto grisáceo
	slot_title.add_theme_constant_override("letter_spacing", 4)
	header_margin.add_child(slot_title)
	
	# Separator visual
	var sep_line = ColorRect.new()
	sep_line.custom_minimum_size = Vector2(0, 2)
	sep_line.color = Color(0.2, 0.2, 0.3)
	vbox.add_child(sep_line)
	
	# --- BODY (Info del save) ---
	var info_margin = MarginContainer.new()
	info_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_margin.add_theme_constant_override("margin_left", 20)
	info_margin.add_theme_constant_override("margin_right", 20)
	info_margin.add_theme_constant_override("margin_top", 30)
	info_margin.add_theme_constant_override("margin_bottom", 30)
	vbox.add_child(info_margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.name = "InnerVBox" # Necesario para buscarlo luego
	inner_vbox.add_theme_constant_override("separation", 15)
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_margin.add_child(inner_vbox)
	
	# Contenedor específico para la info dinámica (Stats, "Vacio", etc)
	var info_container = VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.alignment = BoxContainer.ALIGNMENT_CENTER 
	inner_vbox.add_child(info_container)
	
	# --- FOOTER (Acciones) ---
	var actions_margin = MarginContainer.new()
	actions_margin.add_theme_constant_override("margin_left", 20)
	actions_margin.add_theme_constant_override("margin_right", 20)
	actions_margin.add_theme_constant_override("margin_bottom", 25)
	vbox.add_child(actions_margin)
	
	var actions_vbox = VBoxContainer.new()
	actions_vbox.name = "ActionsVBox"
	actions_vbox.add_theme_constant_override("separation", 12)
	actions_margin.add_child(actions_vbox)

	# 1. Botón JUGAR (Grande, Dorado)
	var select_btn = Button.new()
	select_btn.name = "SelectButton"
	select_btn.text = "JUGAR"
	select_btn.custom_minimum_size = Vector2(0, 55)
	select_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Estilo Base Botón Jugar
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	btn_style.border_color = Color(0.6, 0.5, 0.3) # Oro apagado
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(8)
	
	# Estilo Hover Botón Jugar
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.2, 0.35, 1.0)
	btn_hover.border_color = Color(1.0, 0.8, 0.2) # Oro brillante
	btn_hover.set_border_width_all(2)
	btn_hover.shadow_color = Color(1, 0.8, 0.2, 0.3)
	btn_hover.shadow_size = 8
	
	select_btn.add_theme_stylebox_override("normal", btn_style)
	select_btn.add_theme_stylebox_override("hover", btn_hover)
	select_btn.add_theme_stylebox_override("pressed", btn_style)
	select_btn.add_theme_stylebox_override("focus", btn_hover)
	select_btn.add_theme_font_size_override("font_size", 22)
	select_btn.add_theme_color_override("font_color", Color.WHITE)
	select_btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.5))
	
	select_btn.pressed.connect(_on_slot_selected.bind(slot_index))
	
	# Animaciones Hover Botón
	select_btn.mouse_entered.connect(_anim_btn_scale.bind(select_btn, 1.02))
	select_btn.mouse_exited.connect(_anim_btn_scale.bind(select_btn, 1.0))
	select_btn.focus_entered.connect(_anim_btn_scale.bind(select_btn, 1.02))
	select_btn.focus_exited.connect(_anim_btn_scale.bind(select_btn, 1.0))
	
	actions_vbox.add_child(select_btn)
	slot_buttons.append(select_btn)
	
	# 2. Botón BORRAR (Discreto, Texto Rojo)
	var delete_btn = Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "Borrar Partida"
	delete_btn.flat = true # Estilo solo texto para no ensuciar
	delete_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	delete_btn.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3, 0.6)) # Rojo apagado
	delete_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.3, 1.0)) # Rojo vivo
	delete_btn.add_theme_color_override("font_focus_color", Color(1.0, 0.3, 0.3, 1.0))
	delete_btn.add_theme_font_size_override("font_size", 12)
	
	delete_btn.pressed.connect(_on_delete_slot.bind(slot_index))
	delete_btn.visible = false 
	actions_vbox.add_child(delete_btn)
	
	# TRACKING para animaciones del panel completo
	# Usamos el focus signal del botón PRINCIPAL para animar el panel padre
	select_btn.focus_entered.connect(_highlight_panel.bind(panel, true))
	select_btn.focus_exited.connect(_highlight_panel.bind(panel, false))
	select_btn.mouse_entered.connect(_highlight_panel.bind(panel, true))
	select_btn.mouse_exited.connect(_highlight_panel.bind(panel, false))
	
	return panel

# Ayudantes de Animación
func _anim_btn_scale(btn: Control, scale_val: float) -> void:
	var t = create_tween()
	t.tween_property(btn, "scale", Vector2(scale_val, scale_val), 0.1)
	if scale_val > 1.0:
		AudioManager.play_fixed("sfx_ui_hover")

func _highlight_panel(panel: PanelContainer, highlighted: bool) -> void:
	var sb = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not sb: return
	
	var t = create_tween()
	t.set_parallel(true)
	
	if highlighted:
		# Glow Activo
		t.tween_property(sb, "border_color", Color(1.0, 0.8, 0.2, 1.0), 0.2) # Dorado
		t.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Título color
		var lbl = panel.find_child("SlotTitle")
		if lbl: lbl.modulate = Color(1, 0.9, 0.5)
	else:
		# Reposo
		t.tween_property(sb, "border_color", Color(0.4, 0.3, 0.6, 1.0), 0.2) # Púrpura
		t.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2)
		var lbl = panel.find_child("SlotTitle")
		if lbl: lbl.modulate = Color(1, 1, 1)

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
			delete_btn.disabled = false
			delete_btn.modulate = Color(1, 1, 1, 1)

	# Lógica para mostrar siempre el botón de borrado pero desactivado si está vacío
	# Esto ayuda a que el usuario vea dónde está la funcionalidad
	if (slot_data == null or slot_data.is_empty()) and delete_btn:
		delete_btn.visible = true
		delete_btn.disabled = true
		delete_btn.modulate = Color(1, 1, 1, 0.3) # Semi-transparent

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
