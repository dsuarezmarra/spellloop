extends Node
## Grid hash espacial centralizado para consultas de proximidad O(1) en vez de O(N).
## Se actualiza 1 vez por _physics_process frame.
## Los enemigos consultan get_nearby() en vez de iterar get_nodes_in_group("enemies").

const CELL_SIZE: float = 64.0

var _grid: Dictionary = {}  # Vector2i -> Array[Node]
var _last_update_frame: int = -1

func _physics_process(_delta: float) -> void:
	_update_grid()

func _update_grid() -> void:
	"""Reconstruir el grid una vez por frame."""
	var frame = Engine.get_physics_frames()
	if frame == _last_update_frame:
		return
	_last_update_frame = frame
	
	_grid.clear()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var cell = Vector2i(
			int(floorf(enemy.global_position.x / CELL_SIZE)),
			int(floorf(enemy.global_position.y / CELL_SIZE))
		)
		if not _grid.has(cell):
			_grid[cell] = []
		_grid[cell].append(enemy)

func get_nearby(pos: Vector2, radius: float) -> Array:
	"""Obtener nodos cercanos a una posición dentro de un radio.
	Mucho más eficiente que iterar todos los enemigos."""
	var results: Array = []
	var cell = Vector2i(
		int(floorf(pos.x / CELL_SIZE)),
		int(floorf(pos.y / CELL_SIZE))
	)
	var r = ceili(radius / CELL_SIZE)
	var radius_sq = radius * radius
	
	for x in range(cell.x - r, cell.x + r + 1):
		for y in range(cell.y - r, cell.y + r + 1):
			var key = Vector2i(x, y)
			if _grid.has(key):
				for enemy in _grid[key]:
					if is_instance_valid(enemy) and pos.distance_squared_to(enemy.global_position) <= radius_sq:
						results.append(enemy)
	return results

func get_nearby_excluding(pos: Vector2, radius: float, exclude: Node) -> Array:
	"""Igual que get_nearby pero excluye un nodo específico (típicamente self)."""
	var results: Array = []
	var cell = Vector2i(
		int(floorf(pos.x / CELL_SIZE)),
		int(floorf(pos.y / CELL_SIZE))
	)
	var r = ceili(radius / CELL_SIZE)
	var radius_sq = radius * radius
	
	for x in range(cell.x - r, cell.x + r + 1):
		for y in range(cell.y - r, cell.y + r + 1):
			var key = Vector2i(x, y)
			if _grid.has(key):
				for enemy in _grid[key]:
					if enemy != exclude and is_instance_valid(enemy) and pos.distance_squared_to(enemy.global_position) <= radius_sq:
						results.append(enemy)
	return results
