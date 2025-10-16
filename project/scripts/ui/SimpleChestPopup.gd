extends Control
class_name SimpleChestPopup

# Popup simple para selección de items del cofre
signal item_selected(item)

var available_items: Array = []
var popup_bg: PanelContainer
var items_vbox: VBoxContainer

func _ready():
	print("[SimpleChestPopup] _ready() llamado")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP  # ✅ Permitir que este Control reciba input
	
	# Configurar el Control para que sea fullscreen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Crear fondo semi-transparente detrás del popup
	var bg_panel = PanelContainer.new()
	bg_panel.anchor_left = 0.0
	bg_panel.anchor_top = 0.0
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	bg_panel.mouse_filter = MOUSE_FILTER_IGNORE  # Permite clicks en el popup
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.3)  # Fondo oscuro semi-transparente
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)
	
	# Crear popup centrado
	popup_bg = PanelContainer.new()
	popup_bg.mouse_filter = MOUSE_FILTER_STOP  # ✅ Este si recibe input
	popup_bg.add_theme_stylebox_override("panel", create_panel_style())
	add_child(popup_bg)
	
	# Crear contenedor principal
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
	
	print("[SimpleChestPopup] _ready() completado")

func setup_items(items: Array):
	"""Configurar los items disponibles para selección"""
	print("[SimpleChestPopup] setup_items() llamado con ", items.size(), " items")
	available_items = items
	
	# Limpiar items previos
	for child in items_vbox.get_children():
		child.queue_free()
	
	# Esperar a que se hayan eliminado
	await get_tree().process_frame
	
	# Crear botones para cada item
	for i in range(items.size()):
		var item = items[i]
		var button = Button.new()
		
		# Obtener nombre del item
		var item_name = item.get("name", "Item Desconocido")
		if item_name == "Item Desconocido":
			item_name = item.get("type", "Item") + " #%d" % (i + 1)
		
		button.text = item_name
		button.custom_minimum_size = Vector2(350, 50)
		button.mouse_filter = MOUSE_FILTER_STOP  # ✅ Botón recibe input
		
		print("[SimpleChestPopup] Creando botón para: ", item_name)
		
		# Conectar señal del botón
		button.pressed.connect(_on_item_selected.bind(item))
		
		items_vbox.add_child(button)
		print("[SimpleChestPopup] Botón añadido, ahora hay: ", items_vbox.get_child_count(), " botones")
	
	print("[SimpleChestPopup] Se crearon ", items_vbox.get_child_count(), " botones")
	
	# Esperar a que se rendericen los botones
	await get_tree().process_frame
	await get_tree().process_frame  # Doble await para asegurar
	
	# Centrar popup en pantalla
	var viewport_size = get_viewport().get_visible_rect().size
	var popup_width = 420
	var popup_height = 150 + (items.size() * 60)
	
	popup_bg.size = Vector2(popup_width, popup_height)
	popup_bg.position = (viewport_size - popup_bg.size) / 2
	
	print("[SimpleChestPopup] Popup centrado en pantalla - Size: ", popup_bg.size, " Pos: ", popup_bg.position)

func _on_item_selected(item):
	"""Callback cuando se selecciona un item"""
	print("[SimpleChestPopup] ¡¡¡ ITEM SELECCIONADO !!! ", item)
	item_selected.emit(item)
	print("[SimpleChestPopup] Señal emitida, reanudando juego...")
	# Reanudar juego antes de cerrar
	get_tree().paused = false
	print("[SimpleChestPopup] Juego reanudado, cerrando popup...")
	queue_free()

func create_panel_style() -> StyleBox:
	"""Crear estilo para el fondo del popup"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.98)
	style.border_color = Color(0.8, 0.5, 0.2, 1.0)  # Color dorado
	style.set_border_width_all(3)  # Grosor de borde más visible
	style.set_corner_radius_all(8)  # Esquinas redondeadas
	return style

func _input(event):
	"""Capturar ESC para cerrar"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("[SimpleChestPopup] ESC presionado, cerrando...")
		get_tree().paused = false
		queue_free()
		get_tree().root.set_input_as_handled()
