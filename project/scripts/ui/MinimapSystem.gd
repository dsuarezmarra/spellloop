extends Control
class_name MinimapSystem

"""
🗺️ SISTEMA DE MINIMAPA - SPELLLOOP
=================================

Minimapa en tiempo real que muestra:
- Posición del player (centro)
- Enemigos cercanos
- Cofres y objetos
- Área explorada
- Zoom y escala configurables
"""

signal minimap_clicked(world_position: Vector2)

# Configuración del minimapa
@export var minimap_size: Vector2 = Vector2(200, 200)
@export var chunk_size: float = 1024.0  # Tamaño de chunk del mundo
@export var view_chunks: int = 2  # Mostrar 2 chunks de distancia
@export var circular_view: bool = true  # Visión circular

# Calcular view_range basado en chunks
var view_range: float = chunk_size * view_chunks  # 2048 unidades
var world_scale: float = minimap_size.x / (view_range * 2)  # Escala fija

# Referencias
var player_reference: Node2D
var enemy_manager: EnemyManager
var item_manager: ItemManager

# Componentes UI
var background: ColorRect
var player_dot: ColorRect
var enemy_dots: Array[ColorRect] = []
var item_dots: Array[Control] = []  # Cambiar a Control para estrellas
var chest_dots: Array[Control] = []  # Cambiar a Control para cofres

# Colors
var bg_color: Color = Color(0.1, 0.1, 0.1, 0.8)
var player_color: Color = Color(0.2, 0.8, 0.2, 1.0)
var enemy_color: Color = Color(0.8, 0.2, 0.2, 1.0)

func _ready():
	setup_minimap()
	visible = true  # Asegurar que esté visible
	print("🗺️ Minimapa inicializado y visible")

func setup_minimap():
	"""Configurar el minimapa inicial"""
	# Posicionar en esquina superior derecha
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	position.x -= minimap_size.x + 20  # Margen de 20px
	position.y += 20
	size = minimap_size
	
	print("🗺️ Configurando minimapa en posición: ", position, " tamaño: ", size)
	
	# Fondo del minimapa (circular)
	background = ColorRect.new()
	background.color = bg_color
	background.size = minimap_size
	add_child(background)
	
	# Aplicar máscara circular al fondo
	if circular_view:
		apply_circular_mask()
		add_circular_border()
	
	# Dot del player (centro)
	player_dot = ColorRect.new()
	player_dot.color = player_color
	player_dot.size = Vector2(6, 6)  # Hacer el player un poco más visible
	player_dot.position = minimap_size / 2 - Vector2(3, 3)
	add_child(player_dot)
	
	print("🗺️ Minimapa configurado con fondo y player dot")

func create_circular_border_style() -> StyleBoxFlat:
	"""Crear borde circular para el minimapa"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.6, 0.6, 0.6, 1.0)
	
	# Hacer circular
	var radius = minimap_size.x / 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	
	return style

func apply_circular_mask():
	"""Aplicar máscara circular al minimapa"""
	# Crear un panel de fondo con bordes circulares
	var panel = Panel.new()
	panel.size = minimap_size
	panel.position = Vector2.ZERO
	
	# Aplicar estilo circular
	var radius = minimap_size.x / 2
	var style = StyleBoxFlat.new()
	style.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, 0.7)  # 70% transparencia
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	
	# Añadir el panel como fondo
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.z_index = -1  # Ponerlo detrás
	
	# Hacer el background original transparente
	background.color = Color.TRANSPARENT
	
	print("🗺️ Máscara circular aplicada con radio: ", radius)
	
	# Habilitar recorte para elementos hijos
	clip_contents = true

func add_circular_border():
	"""Agregar borde circular visible"""
	var border = ColorRect.new()
	border.color = Color.TRANSPARENT
	border.size = minimap_size
	border.add_theme_stylebox_override("normal", create_circular_border_style())
	add_child(border)

func create_circular_background() -> StyleBoxFlat:
	"""Crear fondo circular"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	
	var radius = minimap_size.x / 2 - 2  # Ligeramente más pequeño para el borde
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	
	return style

func setup_references(player: Node2D, enemies: EnemyManager, items: ItemManager):
	"""Configurar referencias a los sistemas del juego"""
	player_reference = player
	enemy_manager = enemies
	item_manager = items
	
	# Conectar señales para actualización en tiempo real
	if enemy_manager:
		enemy_manager.enemy_spawned.connect(_on_enemy_spawned)
	
	print("🗺️ Referencias del minimapa configuradas")

func _process(_delta):
	"""Actualizar minimapa cada frame"""
	if player_reference and enemy_manager:
		update_minimap()

func update_minimap():
	"""Actualizar posiciones en el minimapa"""
	update_enemies()
	update_items()
	update_chests()

func update_enemies():
	"""Actualizar posiciones de enemigos en minimapa"""
	if not enemy_manager:
		return
	
	# Limpiar dots antiguos
	for dot in enemy_dots:
		if dot and is_instance_valid(dot):
			dot.queue_free()
	enemy_dots.clear()
	
	# Obtener posiciones de enemigos activos
	var enemy_positions = enemy_manager.get_active_enemies()
	for enemy_pos in enemy_positions:
		var distance = player_reference.global_position.distance_to(enemy_pos)
		if distance <= view_range:
			create_enemy_dot(enemy_pos)

func update_items():
	"""Actualizar items en minimapa"""
	if not item_manager:
		return
	
	# Limpiar dots antiguos
	for dot in item_dots:
		if dot and is_instance_valid(dot):
			dot.queue_free()
	item_dots.clear()
	
	# Obtener data de items activos con rareza
	var item_data = item_manager.get_active_items()
	for item_info in item_data:
		var item_pos = item_info.position
		var distance = player_reference.global_position.distance_to(item_pos)
		if distance <= view_range:
			create_item_star(item_pos, item_info.rarity)

func update_chests():
	"""Actualizar cofres en minimapa"""
	if not item_manager:
		return
	
	# Limpiar dots antiguos
	for dot in chest_dots:
		if dot and is_instance_valid(dot):
			dot.queue_free()
	chest_dots.clear()
	
	# Obtener data de cofres activos con rareza
	var chest_data = item_manager.get_active_chests()
	for chest_info in chest_data:
		var chest_pos = chest_info.position
		var distance = player_reference.global_position.distance_to(chest_pos)
		if distance <= view_range:
			create_chest_icon(chest_pos, chest_info.rarity)

func create_enemy_dot(world_pos: Vector2):
	"""Crear dot para enemigo en minimapa"""
	var minimap_pos = world_to_minimap(world_pos)
	if is_position_in_circular_minimap(minimap_pos):
		var dot = ColorRect.new()
		dot.color = enemy_color
		dot.size = Vector2(3, 3)
		dot.position = minimap_pos - Vector2(1.5, 1.5)
		add_child(dot)
		enemy_dots.append(dot)

func create_item_star(world_pos: Vector2, rarity: int):
	"""Crear estrella para item en minimapa según rareza"""
	var minimap_pos = world_to_minimap(world_pos)
	if is_position_in_circular_minimap(minimap_pos):
		var star = Control.new()
		star.size = Vector2(8, 8)
		star.position = minimap_pos - Vector2(4, 4)
		
		# Crear textura de estrella
		var sprite = Sprite2D.new()
		sprite.texture = create_star_texture(rarity)
		sprite.position = Vector2(4, 4)  # Centrar en el control
		star.add_child(sprite)
		
		add_child(star)
		item_dots.append(star)

func create_chest_icon(world_pos: Vector2, rarity: int):
	"""Crear icono de cofre en minimapa según rareza"""
	var minimap_pos = world_to_minimap(world_pos)
	if is_position_in_circular_minimap(minimap_pos):
		var chest = Control.new()
		chest.size = Vector2(6, 6)
		chest.position = minimap_pos - Vector2(3, 3)
		
		# Crear textura de cofre
		var sprite = Sprite2D.new()
		sprite.texture = create_chest_minimap_texture(rarity)
		sprite.position = Vector2(3, 3)  # Centrar en el control
		chest.add_child(sprite)
		
		add_child(chest)
		chest_dots.append(chest)

func world_to_minimap(world_pos: Vector2) -> Vector2:
	"""Convertir posición del mundo a posición del minimapa"""
	if not player_reference:
		return Vector2.ZERO
	
	# Posición relativa al player
	var relative_pos = world_pos - player_reference.global_position
	
	# Escalar al tamaño del minimapa
	var minimap_pos = relative_pos * world_scale
	
	# Centrar en el minimapa (player está en el centro)
	minimap_pos += minimap_size / 2
	
	return minimap_pos

func is_position_in_circular_minimap(minimap_pos: Vector2) -> bool:
	"""Verificar si posición está dentro del minimapa circular"""
	if not circular_view:
		return is_position_in_minimap(minimap_pos)
	
	# Calcular distancia al centro del minimapa
	var center = minimap_size / 2
	var distance = minimap_pos.distance_to(center)
	var radius = minimap_size.x / 2
	
	return distance <= radius

func is_position_in_minimap(minimap_pos: Vector2) -> bool:
	"""Verificar si posición está dentro del minimapa (rectangular)"""
	return minimap_pos.x >= 0 and minimap_pos.x <= minimap_size.x and \
		   minimap_pos.y >= 0 and minimap_pos.y <= minimap_size.y

func _on_enemy_spawned(enemy: Node2D):
	"""Callback cuando se genera un nuevo enemigo"""
	# La actualización se hace en _process, no necesitamos hacer nada específico aquí
	pass

func _gui_input(event):
	"""Manejar clicks en el minimapa"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var minimap_click_pos = event.position
			var world_click_pos = minimap_to_world(minimap_click_pos)
			minimap_clicked.emit(world_click_pos)

func minimap_to_world(minimap_pos: Vector2) -> Vector2:
	"""Convertir posición del minimapa a posición del mundo"""
	if not player_reference:
		return Vector2.ZERO
	
	# Posición relativa al centro del minimapa
	var relative_pos = minimap_pos - minimap_size / 2
	
	# Escalar al mundo
	var world_offset = relative_pos / world_scale
	
	# Posición absoluta en el mundo
	return player_reference.global_position + world_offset

func toggle_visibility():
	"""Alternar visibilidad del minimapa"""
	visible = not visible

func get_chunk_info() -> String:
	"""Obtener información de chunks visibles"""
	var chunks_in_view = (view_range * 2) / chunk_size
	return "Minimapa: %.1f chunks de radio" % (chunks_in_view / 2)

func create_star_texture(rarity: int) -> ImageTexture:
	"""Crear textura de estrella para item en minimapa"""
	var size = 8
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var rarity_color = Color.WHITE  # Simplificado por ahora
	var center = Vector2(size / 2, size / 2)
	
	# Crear estrella simple de 5 puntas
	var star_points = []
	for i in range(10):
		var angle = (i * PI / 5) - PI / 2
		var radius = 3 if i % 2 == 0 else 1.5
		var point = center + Vector2(cos(angle) * radius, sin(angle) * radius)
		star_points.append(point)
	
	# Rellenar estrella
	for x in range(size):
		for y in range(size):
			var point = Vector2(x, y)
			if is_point_in_star_minimap(point, star_points):
				image.set_pixel(x, y, rarity_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_chest_minimap_texture(rarity: int) -> ImageTexture:
	"""Crear textura de mini-cofre para minimapa"""
	var size = 6
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var rarity_color = Color.YELLOW  # Simplificado por ahora
	var base_color = Color(0.4, 0.2, 0.1, 1.0)  # Marrón base
	
	# Cuerpo del cofre (más pequeño)
	for x in range(1, size - 1):
		for y in range(2, size - 1):
			image.set_pixel(x, y, base_color)
	
	# Borde de rareza
	for x in range(1, size - 1):
		image.set_pixel(x, 1, rarity_color)  # Borde superior
		image.set_pixel(x, size - 2, rarity_color)  # Borde inferior
	
	for y in range(1, size - 1):
		image.set_pixel(0, y, rarity_color)  # Borde izquierdo
		image.set_pixel(size - 1, y, rarity_color)  # Borde derecho
	
	# Cerradura central
	image.set_pixel(size / 2, size / 2, rarity_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func is_point_in_star_minimap(point: Vector2, star_points: Array) -> bool:
	"""Verificar si un punto está dentro de la estrella (versión minimap)"""
	var intersections = 0
	var n = star_points.size()
	
	for i in range(n):
		var p1 = star_points[i]
		var p2 = star_points[(i + 1) % n]
		
		if ((p1.y > point.y) != (p2.y > point.y)) and \
		   (point.x < (p2.x - p1.x) * (point.y - p1.y) / (p2.y - p1.y) + p1.x):
			intersections += 1
	
	return intersections % 2 == 1
