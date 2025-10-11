extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D

func _ready():
	print("=== SPELLLOOP - JUEGO LIMPIO ===")
	print("Controles: WASD para mover")
	
	# Configurar cámara
	if player:
		camera.position = player.position

func _process(delta):
	# Cámara sigue al jugador
	if player:
		camera.position = camera.position.lerp(player.position, delta * 5.0)
