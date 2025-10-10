# SimpleEnemy.gd
# Simple enemy that follows the player with Funko Pop styling and animations
extends CharacterBody2D

var health: int = 30
var speed: float = 150.0
var damage: int = 20
var player_ref: Node2D = null
var attack_range: float = 40.0
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0

# Animation system variables
var enemy_type: FunkoPopEnemy.EnemyType
var current_direction: FunkoPopEnemy.Direction = FunkoPopEnemy.Direction.DOWN
var current_frame: FunkoPopEnemy.AnimFrame = FunkoPopEnemy.AnimFrame.IDLE
var animation_timer: float = 0.0
var animation_speed: float = 3.0  # Frames per second
var sprite_node: Sprite2D

func _ready():
	print("[SimpleEnemy] Creating animated Funko Pop enemy...")
	
	# Randomly choose enemy type
	var types = [FunkoPopEnemy.EnemyType.GOBLIN, FunkoPopEnemy.EnemyType.SKELETON, FunkoPopEnemy.EnemyType.ORC, FunkoPopEnemy.EnemyType.DEMON]
	enemy_type = types[randi() % types.size()]
	
	# Create animated Funko Pop enemy sprite
	sprite_node = Sprite2D.new()
	update_sprite()
	add_child(sprite_node)
	print("[SimpleEnemy] Animated Funko Pop enemy sprite created: ", enemy_type)
	
	# Create collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(22, 22)
	collision.shape = shape
	add_child(collision)
	
	# Set collision layers
	collision_layer = 8  # Enemy layer
	collision_mask = 2 | 1  # Can hit walls (layer 2) and player (layer 1)
	
	# Find player reference
	find_player()
	
	print("Funko Pop enemy created with health: ", health, ", type: ", enemy_type)

func update_sprite():
	"""Actualizar el sprite con la dirección y frame actuales"""
	if sprite_node:
		var texture = FunkoPopEnemy.create_enemy_sprite(enemy_type, current_direction, current_frame)
		sprite_node.texture = texture
		sprite_node.scale = Vector2(0.8, 0.8)  # Escala para el juego

func update_direction_from_movement(movement: Vector2):
	"""Actualizar la dirección basada en el movimiento hacia el jugador"""
	if movement.length() > 0:
		# Determinar la dirección principal basada en el vector de movimiento
		if abs(movement.x) > abs(movement.y):
			# Movimiento horizontal dominante
			if movement.x > 0:
				current_direction = FunkoPopEnemy.Direction.RIGHT
			else:
				current_direction = FunkoPopEnemy.Direction.LEFT
		else:
			# Movimiento vertical dominante
			if movement.y > 0:
				current_direction = FunkoPopEnemy.Direction.DOWN
			else:
				current_direction = FunkoPopEnemy.Direction.UP

func update_animation(delta: float, is_moving: bool):
	"""Actualizar la animación"""
	animation_timer += delta
	
	if is_moving:
		# Alternar entre WALK1 y WALK2
		if animation_timer >= 1.0 / animation_speed:
			animation_timer = 0.0
			if current_frame == FunkoPopEnemy.AnimFrame.WALK1:
				current_frame = FunkoPopEnemy.AnimFrame.WALK2
			else:
				current_frame = FunkoPopEnemy.AnimFrame.WALK1
	else:
		# Estado idle
		current_frame = FunkoPopEnemy.AnimFrame.IDLE
		animation_timer = 0.0
	
	update_sprite()

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta
	
	if not player_ref:
		find_player()
		return
	
	# Move towards player
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Actualizar dirección y animación basada en el movimiento
	var is_moving = direction.length() > 0
	if is_moving:
		update_direction_from_movement(direction)
	
	# Actualizar animación
	update_animation(delta, is_moving)
	
	# Check if close enough to attack
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player <= attack_range and attack_timer <= 0:
		attack_player()
		attack_timer = attack_cooldown
	
	move_and_slide()

func find_player():
	"""Find the player in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		print("Enemy found player: ", player_ref.name)

func attack_player():
	"""Attack the player if in range"""
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)
		print("Enemy attacked player for ", damage, " damage!")

func take_damage(amount: int):
	"""Take damage and die if health reaches 0"""
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health)
	
	if health <= 0:
		die()

func die():
	"""Enemy death"""
	print("Enemy died!")
	queue_free()