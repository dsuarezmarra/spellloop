extends Node2D

# Test directo del sistema de colisión

const ROOM_WIDTH = 1024.0
const ROOM_HEIGHT = 576.0

func _ready():
	print("🔧 CREANDO TEST DIRECTO DE COLISIÓN")
	create_debug_walls()
	create_debug_player()

func create_debug_walls():
	"""Crear paredes con colisión exacta en borde exterior"""
	
	# Pared superior - colisión en y=0
	var wall_top = StaticBody2D.new()
	var collision_top = CollisionShape2D.new()
	var shape_top = RectangleShape2D.new()
	shape_top.size = Vector2(ROOM_WIDTH, 1.0)  # 1px de altura
	collision_top.shape = shape_top
	collision_top.position = Vector2(ROOM_WIDTH/2, 0.5)  # Centro en y=0.5
	wall_top.add_child(collision_top)
	wall_top.position = Vector2(0, 0)  # Posición absoluta y=0
	add_child(wall_top)
	
	# Visual de pared superior
	var visual_top = ColorRect.new()
	visual_top.size = Vector2(ROOM_WIDTH, 20)
	visual_top.color = Color.RED  # Rojo para debug
	visual_top.position = Vector2(0, 0)
	visual_top.z_index = -10
	add_child(visual_top)
	
	# Pared inferior - colisión en y=575
	var wall_bottom = StaticBody2D.new()
	var collision_bottom = CollisionShape2D.new()
	var shape_bottom = RectangleShape2D.new()
	shape_bottom.size = Vector2(ROOM_WIDTH, 1.0)  # 1px de altura
	collision_bottom.shape = shape_bottom
	collision_bottom.position = Vector2(ROOM_WIDTH/2, 0.5)  # Centro en y=0.5
	wall_bottom.add_child(collision_bottom)
	wall_bottom.position = Vector2(0, ROOM_HEIGHT - 1)  # Posición absoluta y=575
	add_child(wall_bottom)
	
	# Visual de pared inferior
	var visual_bottom = ColorRect.new()
	visual_bottom.size = Vector2(ROOM_WIDTH, 20)
	visual_bottom.color = Color.RED  # Rojo para debug
	visual_bottom.position = Vector2(0, ROOM_HEIGHT - 20)
	visual_bottom.z_index = -10
	add_child(visual_bottom)
	
	# Pared izquierda - colisión en x=0
	var wall_left = StaticBody2D.new()
	var collision_left = CollisionShape2D.new()
	var shape_left = RectangleShape2D.new()
	shape_left.size = Vector2(1.0, ROOM_HEIGHT)  # 1px de ancho
	collision_left.shape = shape_left
	collision_left.position = Vector2(0.5, ROOM_HEIGHT/2)  # Centro en x=0.5
	wall_left.add_child(collision_left)
	wall_left.position = Vector2(0, 0)  # Posición absoluta x=0
	add_child(wall_left)
	
	# Visual de pared izquierda
	var visual_left = ColorRect.new()
	visual_left.size = Vector2(20, ROOM_HEIGHT)
	visual_left.color = Color.RED  # Rojo para debug
	visual_left.position = Vector2(0, 0)
	visual_left.z_index = -10
	add_child(visual_left)
	
	# Pared derecha - colisión en x=1023
	var wall_right = StaticBody2D.new()
	var collision_right = CollisionShape2D.new()
	var shape_right = RectangleShape2D.new()
	shape_right.size = Vector2(1.0, ROOM_HEIGHT)  # 1px de ancho
	collision_right.shape = shape_right
	collision_right.position = Vector2(0.5, ROOM_HEIGHT/2)  # Centro en x=0.5
	wall_right.add_child(collision_right)
	wall_right.position = Vector2(ROOM_WIDTH - 1, 0)  # Posición absoluta x=1023
	add_child(wall_right)
	
	# Visual de pared derecha
	var visual_right = ColorRect.new()
	visual_right.size = Vector2(20, ROOM_HEIGHT)
	visual_right.color = Color.RED  # Rojo para debug
	visual_right.position = Vector2(ROOM_WIDTH - 20, 0)
	visual_right.z_index = -10
	add_child(visual_right)
	
	print("✅ Paredes debug creadas:")
	print("  - Superior: colisión en y=0")
	print("  - Inferior: colisión en y=575")
	print("  - Izquierda: colisión en x=0")
	print("  - Derecha: colisión en x=1023")

func create_debug_player():
	"""Crear player simple para test"""
	var player = CharacterBody2D.new()
	player.name = "DebugPlayer"
	
	# Sprite visual
	var sprite = Sprite2D.new()
	var texture = load("res://sprites/wizard/wizard_down.png")
	sprite.texture = texture
	sprite.scale = Vector2(0.128, 0.128)  # 64x64 píxeles
	sprite.z_index = 15
	player.add_child(sprite)
	
	# Collider
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 26.0
	collision.shape = shape
	player.add_child(collision)
	
	# Posicionar en centro
	player.position = Vector2(ROOM_WIDTH/2, ROOM_HEIGHT/2)
	player.z_index = 10
	
	# Script de movimiento simple
	var script_text = """
extends CharacterBody2D

@export var speed = 200.0

func _physics_process(delta):
	var input_vector = Vector2()
	
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# Debug de posición
	if Input.is_key_pressed(KEY_SPACE):
		print('Posición wizard: ', position)
"""
	
	var script = GDScript.new()
	script.source_code = script_text
	player.set_script(script)
	
	add_child(player)
	print("✅ Player debug creado en centro de sala")
	print("  - Usa WASD para mover")
	print("  - Usa ESPACIO para ver posición")