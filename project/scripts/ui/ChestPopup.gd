extends AcceptDialog
class_name ChestPopup

# Popup para selección de items del cofre
signal item_selected(item)

var available_items: Array = []

func _ready():
	print("[ChestPopup] _ready() llamado")
	# Configurar popup
	set_flag(Window.FLAG_RESIZE_DISABLED, true)
	
	# CRÍTICO: El popup debe seguir funcionando cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("[ChestPopup] process_mode configurado a ALWAYS")
	
	# Mostrar el popup
	popup_centered_ratio(0.5)
	print("[ChestPopup] popup_centered_ratio() ejecutado")
	
func setup_items(items: Array):
	"""Configurar los items disponibles para selección"""
	print("[ChestPopup] setup_items() llamado con ", items.size(), " items")
	available_items = items
	
	var items_list = $VBoxContainer/ItemsList
	if not items_list:
		push_error("[ChestPopup] No se encontró $VBoxContainer/ItemsList")
		return
	
	# Limpiar items previos
	for child in items_list.get_children():
		child.queue_free()
	
	# Crear botones para cada item
	for i in range(items.size()):
		var item = items[i]
		var button = Button.new()
		
		# Obtener nombre del item
		var item_name = item.get("name", "Item Desconocido")
		if item_name == "Item Desconocido":
			# Si no tiene nombre, usar el tipo
			item_name = item.get("type", "Item") + " #%d" % (i + 1)
		
		button.text = item_name
		button.custom_minimum_size = Vector2(350, 40)
		
		print("[ChestPopup] Creando botón para: ", item_name)
		
		# Conectar señal del botón
		button.pressed.connect(_on_item_selected.bind(item))
		
		items_list.add_child(button)
	
	print("[ChestPopup] Se crearon ", items_list.get_child_count(), " botones")

func _on_item_selected(item):
	"""Callback cuando se selecciona un item"""
	print("[ChestPopup] Item seleccionado: ", item)
	item_selected.emit(item)
	print("[ChestPopup] Señal emitida, reanudando juego...")
	# Reanudar juego antes de cerrar
	get_tree().paused = false
	print("[ChestPopup] Juego reanudado, cerrando popup...")
	queue_free()

func _on_confirmed():
	"""Callback cuando se cierra el popup sin seleccionar"""
	print("[ChestPopup] Popup cerrado sin seleccionar")
	# Reanudar juego antes de cerrar
	get_tree().paused = false
	queue_free()
