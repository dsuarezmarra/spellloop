# SimpleTestRoom.gd
# Versión simplificada del TestRoom que funciona sin dependencias complejas
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	print("[SimpleTestRoom] Test room inicializado")
	
	# Setup básico de cámara
	if camera:
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
	
	print("[SimpleTestRoom] Listo para testing básico!")

func _input(event: InputEvent) -> void:
	"""Handle input básico"""
	# Press Enter para recargar escena
	if event.is_action_pressed("ui_accept"):  # Enter
		get_tree().reload_current_scene()
	
	# Press ESC para salir
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()
	
	# Press Tab para debug info
	if event.is_action_pressed("ui_focus_next"):  # Tab
		print("[SimpleTestRoom] Player position: ", player.global_position if player else "No player")