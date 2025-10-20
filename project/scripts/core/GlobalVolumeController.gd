# GlobalVolumeController.gd
# Controlador de volumen global persistente
# Guarda y carga preferencias vía SaveManager

extends Node

class_name VolumeController

signal volume_changed(bus_name: String, volume: float)
signal master_volume_changed(volume: float)

# Parámetros de volumen
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var ui_volume: float = 0.7

# Configuración persistente
var config_file_path: String = "user://volume_config.cfg"

func _ready() -> void:
	print("[GlobalVolumeController] Inicializado")
	load_volume_preferences()
	apply_volumes()

func load_volume_preferences() -> void:
	"""Cargar preferencias de volumen guardadas"""
	if ResourceLoader.exists(config_file_path):
		var config = ConfigFile.new()
		var err = config.load(config_file_path)
		if err == OK:
			master_volume = config.get_value("volume", "master", 1.0)
			music_volume = config.get_value("volume", "music", 0.8)
			sfx_volume = config.get_value("volume", "sfx", 0.8)
			ui_volume = config.get_value("volume", "ui", 0.7)
			print("[GlobalVolumeController] Preferencias cargadas")
			return
	
	print("[GlobalVolumeController] Usando valores por defecto")

func save_volume_preferences() -> void:
	"""Guardar preferencias de volumen en archivo"""
	var config = ConfigFile.new()
	config.set_value("volume", "master", master_volume)
	config.set_value("volume", "music", music_volume)
	config.set_value("volume", "sfx", sfx_volume)
	config.set_value("volume", "ui", ui_volume)
	
	var err = config.save(config_file_path)
	if err == OK:
		print("[GlobalVolumeController] Preferencias guardadas")
	else:
		print("[GlobalVolumeController] Error guardando preferencias: %d" % err)

func apply_volumes() -> void:
	"""Aplicar volúmenes a los buses de audio"""
	# Establecer volúmenes de buses si existen
	if AudioServer.get_bus_index("Master") >= 0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		var master_db = _volume_to_db(master_volume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	
	if AudioServer.get_bus_index("Music") >= 0:
		var music_db = _volume_to_db(music_volume * master_volume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_db)
	
	if AudioServer.get_bus_index("SFX") >= 0:
		var sfx_db = _volume_to_db(sfx_volume * master_volume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_db)
	
	if AudioServer.get_bus_index("UI") >= 0:
		var ui_db = _volume_to_db(ui_volume * master_volume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), ui_db)

func _volume_to_db(volume: float) -> float:
	"""Convertir volumen 0-1 a decibeles"""
	if volume <= 0.0:
		return -80.0
	return linear_to_db(volume)

func set_master_volume(volume: float) -> void:
	"""Establecer volumen maestro"""
	master_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_volume_preferences()
	emit_signal("master_volume_changed", master_volume)
	emit_signal("volume_changed", "Master", master_volume)

func set_music_volume(volume: float) -> void:
	"""Establecer volumen de música"""
	music_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_volume_preferences()
	emit_signal("volume_changed", "Music", music_volume)

func set_sfx_volume(volume: float) -> void:
	"""Establecer volumen de efectos de sonido"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_volume_preferences()
	emit_signal("volume_changed", "SFX", sfx_volume)

func set_ui_volume(volume: float) -> void:
	"""Establecer volumen de UI"""
	ui_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_volume_preferences()
	emit_signal("volume_changed", "UI", ui_volume)

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_ui_volume() -> float:
	return ui_volume

func mute_all() -> void:
	"""Silenciar todos los buses"""
	master_volume = 0.0
	apply_volumes()

func unmute_all() -> void:
	"""Desensilenciar todos los buses"""
	master_volume = 1.0
	apply_volumes()
