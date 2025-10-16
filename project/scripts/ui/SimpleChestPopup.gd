extends CanvasLayer
class_name SimpleChestPopup

# Popup simple para selección de items del cofre - USANDO CANVASLAYER
signal item_selected(item)

var available_items: Array = []
var main_control: Control
var items_vbox: VBoxContainer
var item_buttons: Array[Button] = []
var current_selected_index: int = -1
var popup_locked: bool = false  # Evitar múltiples selecciones

func _ready():
	print("[SimpleChestPopup] _ready() llamado - CanvasLayer")
	
	# CanvasLayer siempre está al frente (no afectado por cámara)
	layer = 100
	
	# CRUCIAL: Procesar SIEMPRE aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[SimpleChestPopup] process_mode = ALWAYS configurado")
	
	# Asegurar que puede recibir input
	set_process_input(true)
	print("[SimpleChestPopup] set_process_input(true) configurado")
	
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
	popup_bg.custom_minimum_size = Vector2(420, 200)
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
	
	print("[SimpleChestPopup] _ready() completado")

func setup_items(items: Array):
	"""Configurar los items disponibles para selección"""
	print("[SimpleChestPopup] setup_items() llamado con ", items.size(), " items")
	available_items = items
	
	# Limpiar items previos
	for child in items_vbox.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear botones
	for i in range(items.size()):
		var item = items[i]
		var button = Button.new()
		
		var item_name = item.get("name", "Item Desconocido")
		if item_name == "Item Desconocido":
			item_name = item.get("type", "Item Desconocido")
		
		button.text = item_name
		button.custom_minimum_size = Vector2(350, 50)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.process_mode = Node.PROCESS_MODE_ALWAYS  # IMPORTANTE: procesar siempre
		
		# Aplicar estilos
		apply_button_style(button, i)
		
		print("[SimpleChestPopup] Creando botón para: ", item_name)
		
		# Guardar índice y item en metadatos del botón
		button.set_meta("item_index", i)
		button.set_meta("item_data", item.duplicate())
		
		# Conectar pressed signal de forma directa con lambda
		var item_index = i
		var item_data = item.duplicate()
		button.pressed.connect(func(): _on_button_pressed(item_index, item_data))
		button.mouse_entered.connect(func(): _on_button_hover(item_index))
		
		items_vbox.add_child(button)
		item_buttons.append(button)
	
	print("[SimpleChestPopup] Se crearon ", items_vbox.get_child_count(), " botones - LISTO PARA SELECCIONAR")
	
	# Doble await para renderizado
	await get_tree().process_frame
	await get_tree().process_frame

func _on_button_pressed(button_index: int, item_data: Dictionary):
	"""Callback cuando se presiona un botón"""
	print("[SimpleChestPopup] *** BOTÓN PRESIONADO - INDEX: ", button_index, " ITEM: ", item_data.get("type"), " ***")
	
	if popup_locked:
		print("[SimpleChestPopup] ⚠️ Popup bloqueado, ignorando selección")
		return
	
	print("[SimpleChestPopup] Procesando selección...")
	_process_item_selection(item_data, button_index)

func _on_button_hover(button_index: int):
	"""Callback cuando el mouse entra en un botón"""
	current_selected_index = button_index
	_update_button_selection()

func _process_item_selection(item: Dictionary, button_index: int):
	"""Procesar la selección de item"""
	if popup_locked:
		return
	
	popup_locked = true
	
	print("[SimpleChestPopup] ¡¡¡ SELECCIONANDO ITEM !!! Index: ", button_index)
	current_selected_index = button_index
	_update_button_selection()
	
	# Pequeño delay para ver la selección
	await get_tree().create_timer(0.2).timeout
	
	print("[SimpleChestPopup] Emitiendo señal item_selected...")
	item_selected.emit(item)
	
	print("[SimpleChestPopup] Reanudando juego...")
	get_tree().paused = false
	
	print("[SimpleChestPopup] Cerrando popup...")
	queue_free()

func _update_button_selection():
	"""Actualizar estilos visuales según selección"""
	for i in range(item_buttons.size()):
		var is_selected = (i == current_selected_index)
		if is_selected:
			item_buttons[i].modulate = Color(1.5, 1.5, 1.0, 1.0)  # Más brillante
		else:
			item_buttons[i].modulate = Color.WHITE

func apply_button_style(button: Button, index: int):
	"""Aplicar estilos a los botones"""
	# Estilo normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	style_normal.border_color = Color(0.6, 0.4, 0.1, 1.0)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(4)
	
	# Estilo hover
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	style_hover.border_color = Color(1.0, 0.7, 0.0, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	
	# Estilo pressed
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.4, 0.4, 0.2, 1.0)
	style_pressed.border_color = Color(1.0, 1.0, 0.0, 1.0)
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(4)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Añadir número de opción al texto
	var original_text = button.text
	button.text = "[%d] %s" % [index + 1, original_text]

func create_panel_style() -> StyleBox:
	"""Crear estilo para el fondo del popup"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.98)
	style.border_color = Color(0.8, 0.5, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style

func _input(event: InputEvent):
	"""Capturar ESC o números para seleccionar items"""
	print("[SimpleChestPopup] _input() llamado con evento: ", event.get_class())
	
	if event is InputEventKey and event.pressed:
		print("[SimpleChestPopup] InputEventKey detectado - keycode: ", event.keycode)
		
		match event.keycode:
			KEY_1:
				if item_buttons.size() >= 1:
					print("[SimpleChestPopup] ✓ Tecla 1 presionada - Seleccionando item 0")
					_select_item_at_index(0)
					get_tree().root.set_input_as_handled()
					return
			KEY_2:
				if item_buttons.size() >= 2:
					print("[SimpleChestPopup] ✓ Tecla 2 presionada - Seleccionando item 1")
					_select_item_at_index(1)
					get_tree().root.set_input_as_handled()
					return
			KEY_3:
				if item_buttons.size() >= 3:
					print("[SimpleChestPopup] ✓ Tecla 3 presionada - Seleccionando item 2")
					_select_item_at_index(2)
					get_tree().root.set_input_as_handled()
					return
			KEY_ESCAPE:
				print("[SimpleChestPopup] ESC presionado - Seleccionando primer item...")
				if item_buttons.size() > 0:
					_select_item_at_index(0)
				get_tree().root.set_input_as_handled()
				return
			KEY_ENTER:
				print("[SimpleChestPopup] ENTER presionado - Seleccionando item seleccionado")
				if current_selected_index >= 0 and current_selected_index < available_items.size():
					_select_item_at_index(current_selected_index)
				get_tree().root.set_input_as_handled()
				return

func _select_item_at_index(index: int):
	"""Seleccionar un item por índice (desde teclado)"""
	if popup_locked:
		print("[SimpleChestPopup] ⚠️ Popup bloqueado, ignorando tecla")
		return
	
	if index >= 0 and index < available_items.size():
		print("[SimpleChestPopup] *** SELECCIONADO POR TECLADO - INDEX ", index, " ***")
		var selected_item = available_items[index]
		_process_item_selection(selected_item, index)
	else:
		print("[SimpleChestPopup] ⚠️ Índice fuera de rango: ", index)
