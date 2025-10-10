# Minimap.gd
# Simple minimap system showing room layout and player position
# Displays visited/unvisited rooms, current location, and special rooms

extends Control
class_name Minimap

@onready var minimap_grid: GridContainer = $MinimapGrid
@onready var legend: VBoxContainer = $Legend

# Minimap settings
var cell_size: Vector2 = Vector2(20, 20)
var grid_size: Vector2i = Vector2i(15, 15)
var room_cells: Dictionary = {}  # grid_pos -> minimap_cell

# Colors for different room types
var colors = {
	"unvisited": Color.DARK_GRAY,
	"visited": Color.GRAY,
	"current": Color.YELLOW,
	"entrance": Color.GREEN,
	"boss": Color.RED,
	"treasure": Color.GOLD,
	"cleared": Color.LIGHT_GRAY
}

var level_manager: LevelManager

func _ready() -> void:
	# Setup grid
	_setup_minimap_grid()
	_setup_legend()
	
	# Find level manager
	await get_tree().process_frame
	level_manager = get_tree().get_first_node_in_group("level_manager")
	
	print("[Minimap] Minimap initialized")

func _setup_minimap_grid() -> void:
	"""Create grid container for minimap cells"""
	if not minimap_grid:
		minimap_grid = GridContainer.new()
		minimap_grid.name = "MinimapGrid"
		add_child(minimap_grid)
	
	minimap_grid.columns = grid_size.x
	minimap_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _setup_legend() -> void:
	"""Create legend for minimap colors"""
	if not legend:
		legend = VBoxContainer.new()
		legend.name = "Legend"
		add_child(legend)
	
	# Position legend at bottom
	legend.anchors_preset = Control.PRESET_BOTTOM_WIDE
	legend.offset_top = -100
	
	# Add legend items
	_add_legend_item("Current", colors.current)
	_add_legend_item("Visited", colors.visited)
	_add_legend_item("Boss", colors.boss)
	_add_legend_item("Treasure", colors.treasure)

func _add_legend_item(text: String, color: Color) -> void:
	"""Add item to legend"""
	var item = HBoxContainer.new()
	
	var color_rect = ColorRect.new()
	color_rect.color = color
	color_rect.custom_minimum_size = Vector2(10, 10)
	
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.WHITE)
	
	item.add_child(color_rect)
	item.add_child(label)
	legend.add_child(item)

func update_minimap(level_data: Dictionary, current_room_id: String) -> void:
	"""Update minimap with current level data"""
	if not level_data or not level_manager:
		return
	
	# Clear existing cells
	_clear_minimap()
	
	# Create cells for each room
	for room_id in level_data.rooms:
		var room_data = level_data.rooms[room_id]
		_create_room_cell(room_data, room_id == current_room_id)
	
	print("[Minimap] Minimap updated with ", level_data.rooms.size(), " rooms")

func _clear_minimap() -> void:
	"""Clear all minimap cells"""
	for child in minimap_grid.get_children():
		child.queue_free()
	
	room_cells.clear()
	
	# Create empty grid
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var empty_cell = _create_empty_cell()
			minimap_grid.add_child(empty_cell)

func _create_empty_cell() -> Control:
	"""Create empty minimap cell"""
	var cell = ColorRect.new()
	cell.color = Color.TRANSPARENT
	cell.custom_minimum_size = cell_size
	return cell

func _create_room_cell(room_data: Dictionary, is_current: bool) -> void:
	"""Create minimap cell for a room"""
	var grid_pos = room_data.grid_position
	var cell_index = grid_pos.y * grid_size.x + grid_pos.x
	
	# Get the cell at this position
	var children = minimap_grid.get_children()
	if cell_index >= 0 and cell_index < children.size():
		var cell = children[cell_index] as ColorRect
		
		if cell:
			# Set color based on room state
			cell.color = _get_room_color(room_data, is_current)
			
			# Add border for current room
			if is_current:
				_add_current_room_indicator(cell)
			
			# Store reference
			room_cells[grid_pos] = cell

func _get_room_color(room_data: Dictionary, is_current: bool) -> Color:
	"""Get appropriate color for room based on its state"""
	if is_current:
		return colors.current
	
	match room_data.get("type", 0):
		LevelGenerator.RoomType.ENTRANCE:
			return colors.entrance
		LevelGenerator.RoomType.BOSS:
			return colors.boss
		LevelGenerator.RoomType.TREASURE:
			return colors.treasure
		_:
			if room_data.get("cleared", false):
				return colors.cleared
			elif room_data.get("visited", false):
				return colors.visited
			else:
				return colors.unvisited

func _add_current_room_indicator(cell: ColorRect) -> void:
	"""Add visual indicator for current room"""
	# Add border
	var border = StyleBoxFlat.new()
	border.bg_color = cell.color
	border.border_color = Color.WHITE
	border.border_width_left = 2
	border.border_width_right = 2
	border.border_width_top = 2
	border.border_width_bottom = 2
	
	cell.add_theme_stylebox_override("normal", border)

func update_current_room(new_room_id: String) -> void:
	"""Update minimap when player changes rooms"""
	if not level_manager:
		return
	
	var level_data = level_manager.get_current_level_data()
	update_minimap(level_data, new_room_id)

func mark_room_visited(room_id: String) -> void:
	"""Mark a room as visited on the minimap"""
	if not level_manager:
		return
	
	var room_data = level_manager.level_generator.get_room_data(room_id)
	if room_data.is_empty():
		return
	
	var grid_pos = room_data.grid_position
	if room_cells.has(grid_pos):
		var cell = room_cells[grid_pos]
		cell.color = _get_room_color(room_data, false)

func mark_room_cleared(room_id: String) -> void:
	"""Mark a room as cleared on the minimap"""
	if not level_manager:
		return
	
	var room_data = level_manager.level_generator.get_room_data(room_id)
	if room_data.is_empty():
		return
	
	var grid_pos = room_data.grid_position
	if room_cells.has(grid_pos):
		var cell = room_cells[grid_pos]
		cell.color = colors.cleared