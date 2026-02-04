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
	# Asegurar que el control ocupe toda la pantalla pero no bloquee inputs
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_create_slot_ui()
	_load_slot_data()
	_setup_navigation()
	_connect_signals()
	
	# 1. Eliminar botón Volver (Redundante, usar ESC)
	if back_button:
		back_button.visible = false
		back_button.process_mode = Node.PROCESS_MODE_DISABLED
		
	# 2. Hacer panel transparente
	var main_panel = get_node_or_null("Panel")
	if main_panel:
		var transparent_style = StyleBoxFlat.new()
		transparent_style.bg_color = Color(0, 0, 0, 0)
		main_panel.add_theme_stylebox_override("panel", transparent_style)
	
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
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE # NO BLOQUEAR CLICS
		add_child(bg)
		move_child(bg, 0)
		
	# FORCE UPPERCASE TITLE
	if title_label:
		title_label.text = "SELECCIONA TU PARTIDA"

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
	
	# --- NAVIGATION LINKS ---
	# Link vertical manual
	select_btn.focus_neighbor_bottom = delete_btn.get_path()
	delete_btn.focus_neighbor_top = select_btn.get_path()
	
	# Link horizontal manual is done in _setup_navigation
	
	
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
	"""Actualizar la visualización de un slot con contenido dinámico"""
	if slot_index >= slot_panels.size():
		return
	
	var panel = slot_panels[slot_index]
	
	# Buscar nodos clave en la nueva jerarquía
	# Panel -> VBox -> Margin(Info) -> InnerVBox -> InfoContainer
	# Panel -> VBox -> Margin(Actions) -> ActionsVBox
	
	# Acceso seguro via find_child (más robusto que paths hardcodeados)
	var info_container = panel.find_child("InfoContainer", true, false)
	var actions_vbox = panel.find_child("ActionsVBox", true, false)
	
	if not info_container or not actions_vbox:
		return
		
	var select_btn = actions_vbox.get_node_or_null("SelectButton")
	var delete_btn = actions_vbox.get_node_or_null("DeleteButton")
	
	# Limpiar info anterior
	for child in info_container.get_children():
		child.queue_free()
	
	if slot_data == null or slot_data.is_empty():
		# --- SLOT VACÍO ---
		var empty_display = VBoxContainer.new()
		empty_display.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_display.add_theme_constant_override("separation", 10)
		
		var icon = TextureRect.new()
		icon.texture = load("res://assets/icons/ui_new_game_sparkles.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		empty_display.add_child(icon)
		
		var label = Label.new()
		label.text = "NUEVA PARTIDA"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.8))
		empty_display.add_child(label)
		
		info_container.add_child(empty_display)
		
		if select_btn:
			select_btn.text = "CREAR"
			select_btn.modulate = Color(0.8, 1.0, 0.8) # Tinte verdoso
		if delete_btn:
			delete_btn.visible = false # No mostrar borrar si está vacío
			
	else:
		# --- SLOT CON DATOS ---
		var player_data = slot_data.get("player_data", {})
		
		# Avatar / Icono Class (Variado)
		var icons = [
			"res://assets/icons/ui_save_slot_swords.png",
			"res://assets/icons/ui_save_slot_orb.png",
			"res://assets/icons/ui_save_slot_scroll.png",
			"res://assets/icons/ui_save_slot_backpack.png",
			"res://assets/icons/ui_save_slot_potion.png"
		]
		var icon_path = icons[slot_index % icons.size()]
		
		var avatar = TextureRect.new()
		avatar.texture = load(icon_path)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar.custom_minimum_size = Vector2(80, 80)
		info_container.add_child(avatar)
		
		# Stats Grid
		var stats_vbox = VBoxContainer.new()
		stats_vbox.add_theme_constant_override("separation", 5)
		
		# Mejor Puntuación
		var score_hbox = HBoxContainer.new()
		score_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var score_val = player_data.get("best_score", 0)
		var score_lbl = Label.new()
		score_lbl.text = "🏆 %d" % score_val
		score_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Gold
		score_hbox.add_child(score_lbl)
		stats_vbox.add_child(score_hbox)
		
		# Runs
		var runs_val = player_data.get("total_runs", 0)
		var runs_lbl = Label.new()
		runs_lbl.text = "Partidas: %d" % runs_val
		runs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		runs_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		stats_vbox.add_child(runs_lbl)
		
		# Tiempo
		var playtime = player_data.get("total_playtime", 0.0)
		var hours = int(playtime) / 3600
		var mins = (int(playtime) % 3600) / 60
		var time_lbl = Label.new()
		if playtime > 0 and playtime < 60:
			time_lbl.text = "< 1m"
		else:
			time_lbl.text = "%dh %02dm" % [hours, mins]
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_lbl.add_theme_font_size_override("font_size", 12)
		time_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		stats_vbox.add_child(time_lbl)
		
		info_container.add_child(stats_vbox)
		
		if select_btn:
			select_btn.text = "CONTINUAR"
			select_btn.modulate = Color(1.0, 1.0, 1.0)
		if delete_btn:
			delete_btn.visible = true
			delete_btn.disabled = false
			delete_btn.text = "Borrar Progreso"
			delete_btn.icon = load("res://assets/icons/ui_delete_trash.png")
			delete_btn.expand_icon = true
			delete_btn.modulate = Color(1, 1, 1, 0.8)

func _setup_navigation() -> void:
	"""Configurar navegación WASD"""
	# Desactivar navegación por flechas y configurar vecinos manualmente
	var num_active = slot_buttons.size()
	
	for i in range(num_active):
		var btn = slot_buttons[i]
		# Get panels to find inner buttons
		var panel = slot_panels[i]
		var select_btn = btn # This is the select button from slot_buttons array
		var delete_btn = panel.find_child("DeleteButton", true, false)
		
		var prev_idx = (i - 1 + num_active) % num_active
		var next_idx = (i + 1) % num_active
		
		# Select Button Horizontal Links
		select_btn.focus_neighbor_left = slot_buttons[prev_idx].get_path()
		select_btn.focus_neighbor_right = slot_buttons[next_idx].get_path()
		
		# Delete Button Horizontal Links (if visible)
		if delete_btn:
			var prev_del = slot_panels[prev_idx].find_child("DeleteButton", true, false)
			var next_del = slot_panels[next_idx].find_child("DeleteButton", true, false)
			
			# Si el vecino no tiene delete button (vacio), ir al select del vecino
			if prev_del and prev_del.visible:
				delete_btn.focus_neighbor_left = prev_del.get_path()
			else:
				delete_btn.focus_neighbor_left = slot_buttons[prev_idx].get_path() # Fallback to select
				
			if next_del and next_del.visible:
				delete_btn.focus_neighbor_right = next_del.get_path()
			else:
				delete_btn.focus_neighbor_right = slot_buttons[next_idx].get_path() # Fallback to select
				
			# Vertical down (ciclado o nada)
			delete_btn.focus_neighbor_bottom = delete_btn.get_path() # Stay on delete

	# (Back Button logic removed)

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
	
	# Usar sistema de foco nativo para WASD simulando UI actions
	if event is InputEventKey and event.pressed:
		var ev_up = InputEventAction.new(); ev_up.action = "ui_up"; ev_up.pressed = true
		var ev_down = InputEventAction.new(); ev_down.action = "ui_down"; ev_down.pressed = true
		var ev_left = InputEventAction.new(); ev_left.action = "ui_left"; ev_left.pressed = true
		var ev_right = InputEventAction.new(); ev_right.action = "ui_right"; ev_right.pressed = true
		
		match event.keycode:
			KEY_W: get_viewport().push_input(ev_up)
			KEY_S: get_viewport().push_input(ev_down)
			KEY_A: get_viewport().push_input(ev_left)
			KEY_D: get_viewport().push_input(ev_right)
			KEY_ESCAPE:
				# Manejo especial para Overlay
				var overlay = get_node_or_null("DeleteOverlay")
				if overlay:
					overlay.queue_free()
					take_focus()
				else:
					_on_back_pressed()
			KEY_SPACE, KEY_ENTER:
				# Manually trigger press if ui_accept is failing
				var focus = get_viewport().gui_get_focus_owner()
				if focus and focus is Button:
					focus.pressed.emit()
			
	# Space/Enter handled natively by buttons if focused

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
	"""Callback para borrar un slot - Abre Popup Personalizado"""
	_create_delete_popup(slot_index)

func _create_delete_popup(slot_index: int) -> void:
	# Fondo oscuro bloqueante
	var overlay = Panel.new()
	overlay.name = "DeleteOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Bloquear clics detrás
	
	# Stylebox transparente oscuro
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)
	
	# Panel Central
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.05, 0.15)
	panel_style.border_color = Color(0.8, 0.2, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_child(vbox)
	panel.add_child(margin)
	
	# Texto
	var lbl = Label.new()
	lbl.text = "¿BORRAR SLOT %d?" % (slot_index + 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	vbox.add_child(lbl)
	
	var sub = Label.new()
	sub.text = "Esta acción es irreversible.\nTu mago perderá todo su poder."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(sub)
	
	# Botones
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "CANCELAR"
	btn_cancel.custom_minimum_size = Vector2(120, 40)
	btn_cancel.pressed.connect(overlay.queue_free)
	btn_cancel.pressed.connect(_play_button_sound)
	# Restaurar foco al cerrar
	btn_cancel.tree_exiting.connect(func(): slot_buttons[current_slot_index].grab_focus())
	hbox.add_child(btn_cancel)
	
	var btn_delete = Button.new()
	btn_delete.text = "BORRAR"
	btn_delete.custom_minimum_size = Vector2(120, 40)
	var del_style = StyleBoxFlat.new()
	del_style.bg_color = Color(0.6, 0.2, 0.2)
	btn_delete.add_theme_stylebox_override("normal", del_style)
	btn_delete.pressed.connect(_confirm_delete_slot.bind(slot_index, overlay))
	btn_delete.pressed.connect(_play_button_sound)
	hbox.add_child(btn_delete)
	
	# Neighbors
	btn_cancel.focus_neighbor_right = btn_delete.get_path()
	btn_delete.focus_neighbor_left = btn_cancel.get_path()
	
	# Focus start (Wait for frame to ensure validity)
	if is_inside_tree():
		await get_tree().process_frame
		btn_cancel.grab_focus()

func _confirm_delete_slot(slot_index: int, overlay: Control) -> void:
	"""Confirmar borrado de slot"""
	if overlay: overlay.queue_free()
	
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
	
func take_focus() -> void:
	"""Forzar foco en el slot actual (usado al volver de otros menús)"""
	if slot_buttons.size() > 0:
		# Asegurar que el indice es valido
		current_slot_index = clampi(current_slot_index, 0, slot_buttons.size() - 1)
		# Pequeña espera para que el motor procese la visibilidad
		if is_inside_tree():
			await get_tree().process_frame
		slot_buttons[current_slot_index].grab_focus()
