extends CanvasLayer
class_name SimpleChestPopup

# Popup simple para selección de items del cofre - USANDO CANVASLAYER
signal item_selected(item)
signal all_items_claimed(items)

var available_items: Array = []
var main_control: Control
var items_vbox: VBoxContainer
var item_buttons: Array[Control] = [] # Changed to Control to handle buttons or panels
var current_selected_index: int = -1
var popup_locked: bool = false
var is_jackpot_mode: bool = false
var claim_button: Button = null

func _ready():
	# CanvasLayer siempre está al frente (no afectado por cámara)
	layer = 100
	
	# CRUCIAL: Procesar SIEMPRE aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Asegurar que puede recibir input
	set_process_input(true)
	
	# Crear control que cubre toda la pantalla
	main_control = Control.new()
	main_control.anchor_left = 0.0
	main_control.anchor_top = 0.0
	main_control.anchor_right = 1.0
	main_control.anchor_bottom = 1.0
	main_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(main_control)
	
	# Fondo semi-transparente
	var bg_panel = PanelContainer.new()
	bg_panel.anchor_left = 0.0
	bg_panel.anchor_top = 0.0
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.6)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	main_control.add_child(bg_panel)
	
	# Popup centrado (PanelContainer)
	var popup_bg = PanelContainer.new()
	popup_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_bg.add_theme_stylebox_override("panel", create_panel_style())
	popup_bg.custom_minimum_size = Vector2(450, 200) # Slightly wider
	main_control.add_child(popup_bg)
	
	# Contenedor principal (VBoxContainer)
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	popup_bg.add_child(main_vbox)
	
	# Título
	var title = Label.new()
	title.text = "¡Escoge tu recompensa!"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# Lista de items
	items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 5)
	main_vbox.add_child(items_vbox)
	
	# Centrar popup después de un frame
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	popup_bg.position = (screen_size - popup_bg.size) / 2
	
	# Inicializar selección
	current_selected_index = 0

func _input(event: InputEvent) -> void:
	"""Manejar input de teclado para navegación WASD y bloqueo de ESC"""
	if not is_inside_tree():
		return
	
	if popup_locked:
		return
	
	# Bloquear ESC completamente - el usuario debe seleccionar un item
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_viewport().set_input_as_handled()
		# No hacer nada - forzar selección
		return
	
	# Navegación con W/S o flechas
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_navigate_selection(-1)
		return
	
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_navigate_selection(1)
		return
	
	# Selección con Space/Enter
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if is_jackpot_mode and claim_button:
			claim_button.emit_signal("pressed")
		elif current_selected_index >= 0 and current_selected_index < item_buttons.size():
			var item = available_items[current_selected_index]
			_process_item_selection(item, current_selected_index)
		return

func _navigate_selection(direction: int) -> void:
	"""Navegar entre items con W/S"""
	if item_buttons.is_empty():
		return
	
	# En modo jackpot, navegar hasta el botón claim
	var max_index = item_buttons.size() - 1
	if is_jackpot_mode and claim_button:
		max_index = item_buttons.size()  # +1 para incluir claim button
	
	current_selected_index += direction
	current_selected_index = clampi(current_selected_index, 0, max_index)
	
	_update_button_selection()
	
	# Dar foco visual
	if is_jackpot_mode and current_selected_index == item_buttons.size() and claim_button:
		claim_button.grab_focus()
	elif current_selected_index >= 0 and current_selected_index < item_buttons.size():
		if item_buttons[current_selected_index] is Button:
			item_buttons[current_selected_index].grab_focus()

func show_as_jackpot(items: Array):
	"""Mostrar modo Jackpot (múltiples premios)"""
	is_jackpot_mode = true
	setup_items(items)
	
	# Actualizar título
	var main_vbox = items_vbox.get_parent()
	for child in main_vbox.get_children():
		if child is Label:
			child.text = "¡RECOMPENSA LEGENDARIA!"
			child.modulate = Color(1, 0.8, 0.2) # Dorado
			break
			
	# Añadir botón de reclamar todo
	claim_button = Button.new()
	claim_button.text = "¡RECLAMAR TODO!"
	claim_button.custom_minimum_size = Vector2(350, 60)
	claim_button.add_theme_font_size_override("font_size", 20)
	
	# Estilo dorado para el botón
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.2)
	style.border_color = Color(1, 0.8, 0.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	claim_button.add_theme_stylebox_override("normal", style)
	
	claim_button.pressed.connect(_on_claim_all_pressed)
	main_vbox.add_child(claim_button)

func setup_items(items: Array):
	"""Configurar los items disponibles"""
	available_items = items
	item_buttons.clear() 
	
	# Limpiar items previos
	for child in items_vbox.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear botones complejos
	for i in range(items.size()):
		var item = items[i]
		var item_name = item.get("name", "Objeto Misterioso")
		var item_desc = item.get("description", "Sin descripción")
		var item_icon = item.get("icon", "❓") # Emoji fallback
		var item_id = item.get("id", "")
		
		var item_type = item.get("type", "upgrade")
		var item_rarity = item.get("rarity", item.get("tier", 1) - 1)  # tier-1 = rarity index
		
		# Contenedor principal del botón
		var button = Button.new()
		button.custom_minimum_size = Vector2(400, 80)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		apply_button_style(button, i, item_type, item_rarity)
		
		# Layout interno (HBox)
		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Dejar pasar clicks al botón
		hbox.add_theme_constant_override("separation", 15)
		
		# Margen interno
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 5)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Icono
		var icon_tex = null
		# Intentar cargar textura real
		if item_id != "":
			var path = "res://assets/icons/%s.png" % item_id
			if ResourceLoader.exists(path):
				icon_tex = load(path)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if icon_tex:
			icon_rect.texture = icon_tex
		else:
			# Fallback emoji Label
			var emoji_lbl = Label.new()
			emoji_lbl.text = item_icon
			emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			emoji_lbl.add_theme_font_size_override("font_size", 32)
			emoji_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.add_child(emoji_lbl)
			
		hbox.add_child(icon_rect)
		
		# Textos (Nombre + Descripción)
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var name_lbl = Label.new()
		name_lbl.text = item_name
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4)) # Dorado pálido
		
		var desc_lbl = Label.new()
		desc_lbl.text = item_desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		
		text_vbox.add_child(name_lbl)
		text_vbox.add_child(desc_lbl)
		
		hbox.add_child(text_vbox)
		margin.add_child(hbox)
		button.add_child(margin)
		
		# Conectar señales
		var item_index = i
		var item_data = item.duplicate()
		button.pressed.connect(func(): _on_button_pressed(item_index, item_data))
		button.mouse_entered.connect(func(): _on_button_hover(item_index))
		
		items_vbox.add_child(button)
		item_buttons.append(button)
	
	# Doble await para renderizado
	await get_tree().process_frame
	await get_tree().process_frame

func _on_claim_all_pressed():
	if popup_locked: return
	popup_locked = true
	all_items_claimed.emit(available_items)
	get_tree().paused = false
	queue_free()

func _on_button_pressed(button_index: int, item_data: Dictionary):
	"""Callback cuando se presiona un botón"""
	if popup_locked or is_jackpot_mode:
		return
	
	_process_item_selection(item_data, button_index)

func _on_button_hover(button_index: int):
	"""Callback cuando el mouse entra en un botón"""
	if is_jackpot_mode: return
	current_selected_index = button_index
	_update_button_selection()

func _process_item_selection(item: Dictionary, button_index: int):
	"""Procesar la selección de item"""
	if popup_locked:
		return
	
	popup_locked = true
	
	current_selected_index = button_index
	_update_button_selection()
	
	# Pequeño delay para ver la selección
	await get_tree().create_timer(0.2).timeout
	
	item_selected.emit(item)
	
	get_tree().paused = false
	
	queue_free()

func _update_button_selection():
	"""Actualizar estilos visuales según selección"""
	if is_jackpot_mode: return
	for i in range(item_buttons.size()):
		if item_buttons[i] is Button:
			var is_selected = (i == current_selected_index)
			if is_selected:
				item_buttons[i].modulate = Color(1.5, 1.5, 1.0, 1.0)
			else:
				item_buttons[i].modulate = Color.WHITE

func apply_button_style(button: Button, index: int, item_type: String = "upgrade", rarity: int = 0):
	"""Aplicar estilos a los botones según tipo de item"""
	
	# Colores según tipo de item
	var border_color: Color
	var bg_color: Color = Color(0.2, 0.2, 0.2, 1.0)
	var hover_border_color: Color
	var pressed_border_color: Color
	var border_width: int = 2
	
	if item_type == "weapon":
		# ⚔️ ARMAS: Borde cyan/azul brillante con brillo especial
		border_color = Color(0.0, 0.8, 1.0, 1.0)  # Cyan brillante
		hover_border_color = Color(0.2, 1.0, 1.0, 1.0)  # Cyan más brillante
		pressed_border_color = Color(0.5, 1.0, 1.0, 1.0)  # Cyan muy brillante
		bg_color = Color(0.1, 0.15, 0.2, 1.0)  # Fondo azulado oscuro
		border_width = 3  # Borde más grueso para destacar
	else:
		# 📈 UPGRADES: Borde según tier/rareza
		match rarity:
			0:  # Común - Blanco/gris
				border_color = Color(0.6, 0.6, 0.6, 1.0)
				hover_border_color = Color(0.8, 0.8, 0.8, 1.0)
				pressed_border_color = Color(1.0, 1.0, 1.0, 1.0)
			1:  # Raro - Verde
				border_color = Color(0.2, 0.8, 0.2, 1.0)
				hover_border_color = Color(0.3, 1.0, 0.3, 1.0)
				pressed_border_color = Color(0.5, 1.0, 0.5, 1.0)
			2:  # Épico - Púrpura
				border_color = Color(0.6, 0.2, 0.8, 1.0)
				hover_border_color = Color(0.8, 0.4, 1.0, 1.0)
				pressed_border_color = Color(1.0, 0.6, 1.0, 1.0)
			3, 4:  # Legendario/Único - Dorado
				border_color = Color(1.0, 0.8, 0.0, 1.0)
				hover_border_color = Color(1.0, 0.9, 0.3, 1.0)
				pressed_border_color = Color(1.0, 1.0, 0.5, 1.0)
			_:  # Default - Dorado suave
				border_color = Color(0.6, 0.4, 0.1, 1.0)
				hover_border_color = Color(1.0, 0.7, 0.0, 1.0)
				pressed_border_color = Color(1.0, 1.0, 0.0, 1.0)
	
	# Estilo normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.border_color = border_color
	style_normal.set_border_width_all(border_width)
	style_normal.set_corner_radius_all(6)
	
	# Estilo hover
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(bg_color.r + 0.1, bg_color.g + 0.1, bg_color.b + 0.1, 1.0)
	style_hover.border_color = hover_border_color
	style_hover.set_border_width_all(border_width)
	style_hover.set_corner_radius_all(6)
	
	# Estilo pressed
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(bg_color.r + 0.2, bg_color.g + 0.2, bg_color.b + 0.1, 1.0)
	style_pressed.border_color = pressed_border_color
	style_pressed.set_border_width_all(border_width)
	style_pressed.set_corner_radius_all(6)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

func create_panel_style() -> StyleBox:
	"""Crear estilo para el fondo del popup"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.98)
	style.border_color = Color(0.8, 0.5, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style

func _input(event: InputEvent):
	"""Capturar input para navegación con WASD/Joystick y selección con Space/X"""
	if popup_locked:
		return
	
	# === INPUT DE TECLADO Y ACCIONES (WASD / Flechas / Gamepad) ===
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_navigate_selection(-1)
		get_tree().root.set_input_as_handled()
		return
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		_navigate_selection(1)
		get_tree().root.set_input_as_handled()
		return
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if current_selected_index >= 0 and current_selected_index < available_items.size():
			_select_item_at_index(current_selected_index)
		get_tree().root.set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Números 1-3 para selección directa
			KEY_1:
				if item_buttons.size() >= 1:
					_select_item_at_index(0)
					get_tree().root.set_input_as_handled()
					return
			KEY_2:
				if item_buttons.size() >= 2:
					_select_item_at_index(1)
					get_tree().root.set_input_as_handled()
					return
			KEY_3:
				if item_buttons.size() >= 3:
					_select_item_at_index(2)
					get_tree().root.set_input_as_handled()
					return
			
			# Space / Enter para confirmar selección
			KEY_SPACE, KEY_ENTER:
				if current_selected_index >= 0 and current_selected_index < available_items.size():
					_select_item_at_index(current_selected_index)
				get_tree().root.set_input_as_handled()
				return
			
			KEY_ESCAPE:
				if item_buttons.size() > 0:
					_select_item_at_index(0)
				get_tree().root.set_input_as_handled()
				return
	
	# === INPUT DE GAMEPAD (Joystick / Botones) ===
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate_selection(-1)
				get_tree().root.set_input_as_handled()
				return
			JOY_BUTTON_DPAD_DOWN:
				_navigate_selection(1)
				get_tree().root.set_input_as_handled()
				return
			JOY_BUTTON_A:  # X en PlayStation / A en Xbox
				if current_selected_index >= 0 and current_selected_index < available_items.size():
					_select_item_at_index(current_selected_index)
				get_tree().root.set_input_as_handled()
				return
	
	# === JOYSTICK ANALÓGICO ===
	if event is InputEventJoypadMotion:
		# Eje Y del stick izquierdo
		if event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate_selection(-1)
				get_tree().root.set_input_as_handled()
			elif event.axis_value > 0.5:
				_navigate_selection(1)
				get_tree().root.set_input_as_handled()

func _navigate_selection(direction: int):
	"""Navegar la selección arriba (-1) o abajo (+1)"""
	if item_buttons.is_empty():
		return
	
	# Si no hay selección, empezar en el primero
	if current_selected_index < 0:
		current_selected_index = 0 if direction > 0 else item_buttons.size() - 1
	else:
		current_selected_index += direction
	
	# Wrap around
	if current_selected_index < 0:
		current_selected_index = item_buttons.size() - 1
	elif current_selected_index >= item_buttons.size():
		current_selected_index = 0
	
	_update_button_selection()

func _select_item_at_index(index: int):
	"""Seleccionar un item por índice (desde teclado/gamepad)"""
	if popup_locked:
		return
	
	if index >= 0 and index < available_items.size():
		var selected_item = available_items[index]
		_process_item_selection(selected_item, index)


