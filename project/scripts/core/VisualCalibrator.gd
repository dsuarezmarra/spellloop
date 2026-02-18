# VisualCalibrator.gd
# Rutina de calibración visual automática en el primer arranque
# Detecta resolución del viewport y ajusta escala de sprites
# Guarda valores en visual_calibration.cfg

extends Node

class_name VisualCalibrator

var calibration_file_path: String = "user://visual_calibration.cfg"
var calibration_data: Dictionary = {}
var is_calibrated: bool = false

func _ready() -> void:
	print("[VisualCalibrator] Inicializando calibrador visual...")
	load_calibration()
	if not is_calibrated:
		run_calibration()
		save_calibration()
	else:
		apply_calibration()

func load_calibration() -> void:
	"""Cargar calibración guardada si existe"""
	if FileAccess.file_exists(calibration_file_path):
		var config = ConfigFile.new()
		var err = config.load(calibration_file_path)
		if err == OK:
			calibration_data = {
				"player_scale": config.get_value("calibration", "player_scale", 0.25),
				"enemy_scale": config.get_value("calibration", "enemy_scale", 0.2),
				"projectile_scale": config.get_value("calibration", "projectile_scale", 0.15),
				"viewport_width": config.get_value("calibration", "viewport_width", 1920),
				"viewport_height": config.get_value("calibration", "viewport_height", 1080),
				"max_sprite_height_percent": config.get_value("calibration", "max_sprite_height_percent", 0.1)
			}
			is_calibrated = true
			print("[VisualCalibrator] Calibración cargada desde archivo")
			return
	
	is_calibrated = false

func run_calibration() -> void:
	"""Ejecutar calibración automática al primer inicio"""
	print("[VisualCalibrator] Ejecutando calibración visual automática...")
	
	var viewport_size = get_viewport().get_visible_rect().size
	var viewport_height = viewport_size.y
	var max_sprite_height_percent = 0.1  # 10% de altura del viewport
	
	# Estimación de escalas basadas en sprites estándar (512px)
	var standard_sprite_size = 512.0
	
	# Player: más grande, ~8% de altura del viewport
	var player_height_ratio = 0.08
	var player_scale = (viewport_height * player_height_ratio) / standard_sprite_size
	player_scale = clamp(player_scale, 0.15, 0.35)
	
	# Enemigos: más pequeños, ~6% de altura
	var enemy_height_ratio = 0.06
	var enemy_scale = (viewport_height * enemy_height_ratio) / standard_sprite_size
	enemy_scale = clamp(enemy_scale, 0.1, 0.25)
	
	# Proyectiles: muy pequeños, ~3% de altura
	var projectile_height_ratio = 0.03
	var projectile_scale = (viewport_height * projectile_height_ratio) / standard_sprite_size
	projectile_scale = clamp(projectile_scale, 0.1, 0.2)
	
	calibration_data = {
		"player_scale": player_scale,
		"enemy_scale": enemy_scale,
		"projectile_scale": projectile_scale,
		"viewport_width": int(viewport_size.x),
		"viewport_height": int(viewport_size.y),
		"max_sprite_height_percent": max_sprite_height_percent
	}
	
	print("[VisualCalibrator] Calibración completada:")
	print("  - Resolución: %dx%d" % [calibration_data["viewport_width"], calibration_data["viewport_height"]])
	print("  - Escala player: %.3f" % calibration_data["player_scale"])
	print("  - Escala enemigos: %.3f" % calibration_data["enemy_scale"])
	print("  - Escala proyectiles: %.3f" % calibration_data["projectile_scale"])

func save_calibration() -> void:
	"""Guardar calibración en archivo"""
	var config = ConfigFile.new()
	
	for key in calibration_data.keys():
		config.set_value("calibration", key, calibration_data[key])
	
	var err = config.save(calibration_file_path)
	if err == OK:
		print("[VisualCalibrator] Calibración guardada en: %s" % calibration_file_path)
		is_calibrated = true
	else:
		print("[VisualCalibrator] Error guardando calibración: %d" % err)

func apply_calibration() -> void:
	"""Aplicar calibración guardada al player, enemigos y proyectiles"""
	if not is_calibrated or calibration_data.is_empty():
		print("[VisualCalibrator] No hay calibración disponible")
		return
	
	# El player se calibrará automáticamente al instanciarse
	# Los enemigos se calibrarán cuando se spawneen
	# Los proyectiles se calibrarán cuando se lancen
	print("[VisualCalibrator] Calibración aplicada")

func get_player_scale() -> float:
	if calibration_data.has("player_scale"):
		return calibration_data["player_scale"]
	return 0.25

func get_enemy_scale() -> float:
	if calibration_data.has("enemy_scale"):
		return calibration_data["enemy_scale"]
	return 0.2

func get_enemy_scale_for_tier(tier: int) -> float:
	"""Obtener escala de enemigo según su tier - TAMAÑO COMPARABLE AL PLAYER"""
	# Escala muy reducida para que los enemigos sean del tamaño del player o menores
	match tier:
		1: return 0.035  # Tier 1: más pequeño que el player
		2: return 0.04   # Tier 2: ligeramente más grande
		3: return 0.05   # Tier 3: similar al player
		4: return 0.06   # Tier 4: un poco más grande
		5: return 0.08   # Boss: notablemente más grande
		_: return 0.035

func get_projectile_scale() -> float:
	if calibration_data.has("projectile_scale"):
		return calibration_data["projectile_scale"]
	return 0.15

func get_calibration() -> Dictionary:
	return calibration_data.duplicate()

