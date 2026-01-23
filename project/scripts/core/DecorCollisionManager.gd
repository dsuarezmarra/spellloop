# DecorCollisionManager.gd
# Singleton que gestiona colisiones con decorados basadas en distancia
# Este enfoque replica el sistema de barreras de zona que SÍ funciona
# NOTA: No usar class_name ya que está registrado como autoload

extends Node

# Almacén de colisiones de decorados
# Cada entrada: { "position": Vector2, "radius": float }
var _collision_points: Array = []

# Distancia mínima de colisión por defecto
const MIN_COLLISION_RADIUS = 20.0

# Radio de búsqueda para optimización (solo verificar decorados cercanos)
const SEARCH_RADIUS = 500.0

func _ready() -> void:
	add_to_group("decor_collision_manager")

## Registrar un punto de colisión de decorado
func register_collision(pos: Vector2, radius: float) -> void:
	_collision_points.append({
		"position": pos,
		"radius": max(radius, MIN_COLLISION_RADIUS)
	})
	# Debug: Log solo los primeros 5 registros
	if _collision_points.size() <= 5:
		print("[DecorCollisionManager] Registrado: pos=%s, radius=%.1f (total: %d)" % [pos, radius, _collision_points.size()])

## Limpiar todos los puntos de colisión (para resetear entre partidas)
func clear_all() -> void:
	_collision_points.clear()

## Obtener número de colisiones registradas (debug)
func get_collision_count() -> int:
	return _collision_points.size()

## Verificar colisión y obtener vector de corrección
## Retorna Vector2.ZERO si no hay colisión, o un vector de empuje si la hay
func check_collision(entity_pos: Vector2, entity_radius: float = 15.0) -> Vector2:
	var push_vector = Vector2.ZERO
	
	for col in _collision_points:
		var col_pos: Vector2 = col["position"]
		var col_radius: float = col["radius"]
		
		# Optimización: saltar si está muy lejos
		var dist_sq = entity_pos.distance_squared_to(col_pos)
		if dist_sq > SEARCH_RADIUS * SEARCH_RADIUS:
			continue
		
		# Distancia de separación requerida
		var min_dist = entity_radius + col_radius
		var dist = sqrt(dist_sq)
		
		# Si está dentro del radio de colisión, calcular empuje
		if dist < min_dist and dist > 0.01:
			var direction = (entity_pos - col_pos).normalized()
			var overlap = min_dist - dist
			push_vector += direction * overlap
	
	return push_vector

## Versión optimizada que solo verifica los N decorados más cercanos
func check_collision_fast(entity_pos: Vector2, entity_radius: float = 15.0, max_checks: int = 20) -> Vector2:
	var push_vector = Vector2.ZERO
	var checks_done = 0
	
	for col in _collision_points:
		var col_pos: Vector2 = col["position"]
		var col_radius: float = col["radius"]
		
		var dist_sq = entity_pos.distance_squared_to(col_pos)
		
		# Solo verificar si está relativamente cerca
		var check_dist = entity_radius + col_radius + 50.0  # 50px margen
		if dist_sq > check_dist * check_dist:
			continue
		
		checks_done += 1
		
		var dist = sqrt(dist_sq)
		var min_dist = entity_radius + col_radius
		
		if dist < min_dist and dist > 0.01:
			var direction = (entity_pos - col_pos).normalized()
			var overlap = min_dist - dist
			push_vector += direction * overlap
		
		if checks_done >= max_checks:
			break
	
	return push_vector

## Obtener el decorado más cercano a una posición (para debug)
func get_nearest_collision(pos: Vector2) -> Dictionary:
	var nearest = {}
	var min_dist = INF
	
	for col in _collision_points:
		var dist = pos.distance_to(col["position"])
		if dist < min_dist:
			min_dist = dist
			nearest = col.duplicate()
			nearest["distance"] = dist
	
	return nearest
