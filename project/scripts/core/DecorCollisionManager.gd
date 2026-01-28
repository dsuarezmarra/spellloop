# DecorCollisionManager.gd
# Singleton que gestiona colisiones con decorados usando Spatial Partitioning (Grid) para O(1) performance.
# Optimizado para evitar iterar miles de objetos.

extends Node

# Almacén maestro
var _collision_points: Array = []

# GRID SYSTEM (Spatial Hashing)
var _grid: Dictionary = {}
const CELL_SIZE: float = 256.0 # Tamaño de celda (ajustar según densidad)

# Distancia mínima de colisión por defecto
const MIN_COLLISION_RADIUS = 20.0

func _ready() -> void:
    add_to_group("decor_collision_manager")

## Registrar un punto de colisión de decorado
func register_collision(pos: Vector2, radius: float) -> void:
    var entry = {
        "position": pos,
        "radius": max(radius, MIN_COLLISION_RADIUS)
    }
    _collision_points.append(entry)
    
    # Añadir al Grid
    var cell_key = _get_cell_key(pos)
    if not _grid.has(cell_key):
        _grid[cell_key] = []
    _grid[cell_key].append(entry)

## Convertir posición a clave de celda
func _get_cell_key(pos: Vector2) -> Vector2i:
    return Vector2i(floor(pos.x / CELL_SIZE), floor(pos.y / CELL_SIZE))

## Limpiar todos los puntos de colisión
func clear_all() -> void:
    _collision_points.clear()
    _grid.clear()

## Obtener número de colisiones registradas (debug)
func get_collision_count() -> int:
    return _collision_points.size()

## Verificar colisión (Optimizado con Grid)
func check_collision(entity_pos: Vector2, entity_radius: float = 15.0) -> Vector2:
    return check_collision_fast(entity_pos, entity_radius)

## Versión optimizada que usa Grid para buscar solo locales
func check_collision_fast(entity_pos: Vector2, entity_radius: float = 15.0, _max_checks: int = 20) -> Vector2:
    var push_vector = Vector2.ZERO
    
    # Calcular celda de la entidad
    var center_cell = _get_cell_key(entity_pos)
    
    # Revisar celda actual y las 8 vecinas (3x3)
    for x in range(center_cell.x - 1, center_cell.x + 2):
        for y in range(center_cell.y - 1, center_cell.y + 2):
            var key = Vector2i(x, y)
            if _grid.has(key):
                for col in _grid[key]:
                    var col_pos: Vector2 = col["position"]
                    var col_radius: float = col["radius"]
                    
                    var dist_sq = entity_pos.distance_squared_to(col_pos)
                    var min_dist = entity_radius + col_radius
                    
                    if dist_sq < min_dist * min_dist:
                        var dist = sqrt(dist_sq)
                        if dist > 0.01: # Evitar división por cero
                            var direction = (entity_pos - col_pos) / dist # Normalized manually
                            var overlap = min_dist - dist
                            push_vector += direction * overlap
                            
                            # Early exit si el empuje es significativo? 
                            # No, mejor acumular para suavidad, pero limitamos iteraciones implícitamente por el grid.
    
    return push_vector # Retorna vector acumulado

## Obtener el decorado más cercano a una posición (para debug)
func get_nearest_collision(pos: Vector2) -> Dictionary:
    # Para esto seguimos iterando todo porque es debug y safety
    var nearest = {}
    var min_dist = INF
    
    for col in _collision_points:
        var dist = pos.distance_to(col["position"])
        if dist < min_dist:
            min_dist = dist
            nearest = col.duplicate()
            nearest["distance"] = dist
    
    return nearest
