extends Node

# 🎯 GESTOR DE ESCALAS UNIFICADO (SINGLETON)
# Maneja TODO el escalado del juego de manera uniforme

signal scale_changed(new_scale: float)

# Configuración base
const BASE_RESOLUTION_WIDTH = 1920.0
const BASE_RESOLUTION_HEIGHT = 1080.0
const BASE_WALL_THICKNESS = 32.0
const BASE_DOOR_SIZE = 32.0
const BASE_PLAYER_COLLISION_RADIUS = 26.0  # Radio base del collider del jugador

# Estado actual
var current_scale: float = 1.0
var current_viewport_size: Vector2

func _ready():
	calculate_scale()

func calculate_scale() -> float:
	var viewport = get_viewport()
	current_viewport_size = viewport.get_visible_rect().size
	
	var scale_x = current_viewport_size.x / BASE_RESOLUTION_WIDTH
	var scale_y = current_viewport_size.y / BASE_RESOLUTION_HEIGHT
	current_scale = min(scale_x, scale_y)
	
	print("📐 ScaleManager: ", current_viewport_size, " → escala=", current_scale)
	return current_scale

func get_scale() -> float:
	return current_scale

func get_wall_thickness() -> float:
	return BASE_WALL_THICKNESS * current_scale

func get_door_size() -> Vector2:
	var size = BASE_DOOR_SIZE * current_scale
	return Vector2(size, size)

func get_player_scale() -> float:
	return current_scale

func get_player_collision_radius() -> float:
	return BASE_PLAYER_COLLISION_RADIUS * current_scale

func update_scale():
	calculate_scale()
	scale_changed.emit(current_scale)

func get_room_floor_offset() -> Vector2:
	var thickness = get_wall_thickness()
	return Vector2(thickness, thickness)

func get_room_floor_size(room_size: Vector2) -> Vector2:
	var thickness = get_wall_thickness()
	return Vector2(room_size.x - thickness * 2, room_size.y - thickness * 2)

func debug_info() -> String:
	return "ScaleManager: viewport=%s scale=%.3f wall=%.1f door=%.1f player=%.3f collider=%.1f" % [
		current_viewport_size, current_scale, get_wall_thickness(), 
		get_door_size().x, get_player_scale(), get_player_collision_radius()
	]