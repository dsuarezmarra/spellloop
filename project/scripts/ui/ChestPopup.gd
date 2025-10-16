extends AcceptDialog
class_name ChestPopup

# Popup para selección de items del cofre
signal item_selected(item)

var available_items: Array = []

func _ready():
	# Configurar popup
	set_flag(Window.FLAG_RESIZE_DISABLED, true)
	
func setup_items(items: Array):
	"""Configurar los items disponibles para selección"""
	available_items = items
	
	var items_list = $VBoxContainer/ItemsList
	
	# Limpiar items previos
	for child in items_list.get_children():
		child.queue_free()
	
	# Crear botones para cada item
	for item in items:
		var button = Button.new()
		button.text = str(item.get("name", "Item Desconocido"))
		button.custom_minimum_size = Vector2(350, 40)
		
		# Conectar señal del botón
		button.pressed.connect(_on_item_selected.bind(item))
		
		items_list.add_child(button)

func _on_item_selected(item):
	"""Callback cuando se selecciona un item"""
	item_selected.emit(item)
	queue_free()

func _on_confirmed():
	"""Callback cuando se cierra el popup sin seleccionar"""
	queue_free()
