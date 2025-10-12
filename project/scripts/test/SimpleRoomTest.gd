extends Node2D

var player: CharacterBody2D

func _ready():
	print("=== TEST SIMPLE ROOM SYSTEM ===")
	create_simple_test()

func create_simple_test():
	# Crear Player
	player = CharacterBody2D.new()
	player.script = preload("res://scripts/entities/Player.gd")
	
	# Sprite del player
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	
	# Colisión del player
	var collision = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 16
	capsule.height = 32
	collision.shape = capsule
	player.add_child(collision)
	
	add_child(player)
	
	# Posicionar jugador
	player.position = Vector2(512, 288)
	
	# Crear room simple
	create_simple_room()
	
	print("✅ Test simple configurado")

func create_simple_room():
	"""Crear una room simple para test"""
	# Crear paredes
	create_test_wall(Vector2(0, 0), Vector2(1024, 64))  # Arriba
	create_test_wall(Vector2(0, 512), Vector2(1024, 64))  # Abajo
	create_test_wall(Vector2(0, 0), Vector2(64, 576))  # Izquierda  
	create_test_wall(Vector2(960, 0), Vector2(64, 576))  # Derecha
	
	# Crear puertas (aberturas en las paredes)
	create_test_door(Vector2(480, 0), "ARRIBA")
	create_test_door(Vector2(480, 512), "ABAJO")

func create_test_wall(pos: Vector2, size: Vector2):
	"""Crear pared de test"""
	var wall = StaticBody2D.new()
	var visual = ColorRect.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Visual
	visual.size = size
	visual.color = Color.GRAY
	wall.add_child(visual)
	
	# Colisión
	shape.size = size
	collision.shape = shape
	collision.position = size / 2
	wall.add_child(collision)
	
	wall.position = pos
	add_child(wall)

func create_test_door(pos: Vector2, label: String):
	"""Crear puerta de test"""
	var door = ColorRect.new()
	door.size = Vector2(64, 64)
	door.color = Color.GREEN
	door.position = pos
	add_child(door)
	
	# Label para la puerta
	var door_label = Label.new()
	door_label.text = label
	door_label.position = Vector2(10, 10)
	door_label.add_theme_color_override("font_color", Color.BLACK)
	door.add_child(door_label)