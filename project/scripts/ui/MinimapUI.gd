extends Control
class_name MinimapUI

# Configuración del minimap
const ROOM_SIZE: Vector2 = Vector2(20, 20)
const ROOM_SPACING: Vector2 = Vector2(25, 25)

# Referencias
var background: ColorRect
var room_nodes: Dictionary = {}

# Datos del dungeon
var dungeon_data: Dictionary
var current_room_position: Vector2

func _ready():
	setup_minimap()
	print("🗺️ Minimap UI configurado")

func setup_minimap():
	# Configurar el control principal
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	size = Vector2(200, 200)
	position.x -= 220  # Margen desde el borde derecho
	position.y += 20   # Margen desde el borde superior
	
	# Crear fondo
	background = ColorRect.new()
	background.size = size
	background.color = Color(0, 0, 0, 0.7)  # Fondo semi-transparente
	add_child(background)

func update_minimap():
	"""Update the minimap display"""
	clear_minimap()
	
	# Sistema de mazmorra desactivado temporalmente
	print("[MinimapUI] Minimapa desactivado")
	return
	if dungeon_data.is_empty():
		return
	
	current_room_position = dungeon_data.get("current_position", Vector2.ZERO)
	draw_minimap()

func draw_minimap():
	# Limpiar nodos existentes
	clear_minimap()
	
	if not dungeon_data.has("rooms"):
		return
	
	var rooms = dungeon_data["rooms"]
	
	# Calcular centro del minimap
	var center = size / 2
	
	# Dibujar rooms
	draw_rooms(rooms, center)

func clear_minimap():
	# Remover rooms anteriores
	for pos in room_nodes:
		if room_nodes[pos] and is_instance_valid(room_nodes[pos]):
			room_nodes[pos].queue_free()
	room_nodes.clear()

func draw_rooms(rooms: Dictionary, center: Vector2):
	for pos in rooms:
		var room_data = rooms[pos]
		var room_node = create_room_node(room_data, pos)
		
		# Calcular posición en el minimap
		var minimap_pos = center + Vector2(pos.x * ROOM_SPACING.x, pos.y * ROOM_SPACING.y)
		minimap_pos -= ROOM_SIZE / 2  # Centrar
		
		room_node.position = minimap_pos
		add_child(room_node)
		room_nodes[pos] = room_node

func create_room_node(room_data, pos: Vector2) -> Control:
	var room_control = Control.new()
	room_control.size = ROOM_SIZE
	
	# Crear el fondo de la room
	var room_rect = ColorRect.new()
	room_rect.size = ROOM_SIZE
	room_rect.color = get_room_color(room_data, pos)
	room_control.add_child(room_rect)
	
	# Agregar borde si es la room actual
	if pos == current_room_position:
		var border = ColorRect.new()
		border.size = ROOM_SIZE + Vector2(4, 4)
		border.position = Vector2(-2, -2)
		border.color = Color.WHITE
		room_control.add_child(border)
		room_control.move_child(border, 0)  # Mover al fondo
	
	return room_control

func get_room_color(room_data, pos: Vector2) -> Color:
	# Determinar color basado en tipo y estado
	var base_color = Color.GRAY
	
	# Color por tipo usando el enum
	if room_data and room_data.has("room_type"):
		match room_data.room_type:
			RoomData.RoomType.NORMAL:
				base_color = Color.WHITE
			RoomData.RoomType.TREASURE:
				base_color = Color.YELLOW
			RoomData.RoomType.BOSS:
				base_color = Color.RED
			RoomData.RoomType.SECRET:
				base_color = Color.BLUE
			RoomData.RoomType.SHOP:
				base_color = Color.GREEN
	elif pos in dungeon_data.get("treasure_rooms", []):
		base_color = Color.YELLOW
	elif pos in dungeon_data.get("end_rooms", []):
		base_color = Color.RED
	
	# Modificar color por estado
	if room_data and room_data.has("is_cleared") and room_data.is_cleared:
		base_color = base_color.darkened(0.4)
	elif room_data and room_data.has("is_visited") and not room_data.is_visited:
		base_color = base_color.darkened(0.6)
	
	return base_color

func _on_room_entered(room_data):
	# Actualizar posición actual y redibujar
	update_minimap_data()
