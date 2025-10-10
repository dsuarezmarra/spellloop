extends CharacterBody2D

# Simple player implementation without complex dependencies
var health: int = 100
var max_health: int = 100
var speed: float = 300.0
var dash_speed: float = 600.0
var dash_duration: float = 0.2
var dash_cooldown: float = 1.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var movement_input: Vector2 = Vector2.ZERO
var last_movement_direction: Vector2 = Vector2.RIGHT  # Remember last direction for spacebar shooting

# Shooting variables
var shoot_timer: float = 0.0

# Animation system variables
var current_direction: FunkoPopWizard.Direction = FunkoPopWizard.Direction.DOWN
var current_frame: FunkoPopWizard.AnimFrame = FunkoPopWizard.AnimFrame.IDLE
var animation_timer: float = 0.0
var animation_speed: float = 4.0  # Frames per second
var sprite_node: Sprite2D

# Isaac-style stats are now handled by PlayerStats singleton

func _ready():
	print("[SimplePlayer] Creating animated Funko Pop wizard player...")
	
	# Create Funko Pop wizard sprite
	sprite_node = Sprite2D.new()
	update_sprite()
	add_child(sprite_node)
	print("[SimplePlayer] Animated Funko Pop wizard sprite created")
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	collision.shape = shape
	add_child(collision)
	
	# Add camera
	var camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	
	# Ensure mouse input is always captured
	set_process_input(true)
	set_process_unhandled_input(true)
	
	# Set collision layers
	collision_layer = 1  # Player layer
	collision_mask = 2   # Can collide with walls (layer 2)
	
	print("[SimplePlayer] Player created at position: ", position)
	print("[SimplePlayer] Player collision_layer: ", collision_layer, ", collision_mask: ", collision_mask)
	print("[SimplePlayer] Animated player setup complete - should be visible now!")

func update_sprite():
	"""Actualizar el sprite con la dirección y frame actuales"""
	if sprite_node:
		var texture = FunkoPopWizard.create_wizard_sprite(current_direction, current_frame)
		sprite_node.texture = texture
		sprite_node.scale = Vector2(0.6, 0.6)  # Escala para el juego

func update_direction_from_movement(movement: Vector2):
	"""Actualizar la dirección basada en el movimiento"""
	if movement.length() > 0:
		# Determinar la dirección principal basada en el vector de movimiento
		if abs(movement.x) > abs(movement.y):
			# Movimiento horizontal dominante
			if movement.x > 0:
				current_direction = FunkoPopWizard.Direction.RIGHT
			else:
				current_direction = FunkoPopWizard.Direction.LEFT
		else:
			# Movimiento vertical dominante
			if movement.y > 0:
				current_direction = FunkoPopWizard.Direction.DOWN
			else:
				current_direction = FunkoPopWizard.Direction.UP

func update_animation(delta: float, is_moving: bool):
	"""Actualizar la animación"""
	animation_timer += delta
	
	if is_moving:
		# Alternar entre WALK1 y WALK2
		if animation_timer >= 1.0 / animation_speed:
			animation_timer = 0.0
			if current_frame == FunkoPopWizard.AnimFrame.WALK1:
				current_frame = FunkoPopWizard.AnimFrame.WALK2
			else:
				current_frame = FunkoPopWizard.AnimFrame.WALK1
	else:
		# Estado idle
		current_frame = FunkoPopWizard.AnimFrame.IDLE
		animation_timer = 0.0
	
	update_sprite()

func _input(event):
	"""Handle special input events - solo para mouse como backup"""
	# Solo mouse como backup - las flechas se manejan en _physics_process
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if can_shoot():
				var mouse_pos = get_global_mouse_position()
				var direction = (mouse_pos - global_position).normalized()
				shoot_isaac_projectiles(direction)

func _unhandled_input(event):
	"""Handle unprocessed input events"""
	pass  # Keep this simple for now

func _physics_process(delta):
	# Update timers
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if shoot_timer > 0:
		shoot_timer -= delta
	
	# Movement input processing (WASD) - SIEMPRE procesamos esto primero
	movement_input = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1
	if Input.is_action_pressed("move_up"):
		movement_input.y -= 1
	if Input.is_action_pressed("move_down"):
		movement_input.y += 1
	movement_input = movement_input.normalized()
	
	# Actualizar dirección y animación basada en el movimiento
	var is_moving = movement_input.length() > 0
	if is_moving:
		update_direction_from_movement(movement_input)
		last_movement_direction = movement_input
	
	# Actualizar animación
	update_animation(delta, is_moving)
	
	# Handle directional shooting (Isaac-style) - SEPARADO del movimiento
	if can_shoot():
		var shoot_direction = Vector2.ZERO
		
		# Check directional shooting (arrow keys solamente)
		if Input.is_action_pressed("ui_up"):  # Flecha arriba
			shoot_direction.y -= 1
		if Input.is_action_pressed("ui_down"):  # Flecha abajo
			shoot_direction.y += 1
		if Input.is_action_pressed("ui_left"):  # Flecha izquierda
			shoot_direction.x -= 1
		if Input.is_action_pressed("ui_right"):  # Flecha derecha
			shoot_direction.x += 1
			
		# Check right joystick for shooting
		var joy_shoot_x = 0.0
		var joy_shoot_y = 0.0
		
		# Get actual joystick values
		if Input.get_connected_joypads().size() > 0:
			joy_shoot_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
			joy_shoot_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		
		# Use joystick if it's being moved significantly
		if abs(joy_shoot_x) > 0.3 or abs(joy_shoot_y) > 0.3:
			shoot_direction = Vector2(joy_shoot_x, joy_shoot_y)
		
		# Shoot if there's a direction
		if shoot_direction.length() > 0:
			shoot_isaac_projectiles(shoot_direction.normalized())
	
	# Dash
	if Input.is_action_just_pressed("dash") and can_dash():
		print("Dash activated with Shift!")
		start_dash()
	
	# Exit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# Handle dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	
	# Movement
	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = movement_input * speed
	
	move_and_slide()

func can_shoot() -> bool:
	return shoot_timer <= 0

func shoot_isaac_projectiles(direction: Vector2):
	"""Disparar proyectiles estilo Isaac usando PlayerStats"""
	# Set cooldown based on player stats
	shoot_timer = PlayerStats.fire_rate
	
	# Create multiple projectiles if multi-shot is active
	for i in range(PlayerStats.multi_shot):
		var projectile_scene = preload("res://scripts/projectiles/IsaacProjectile.gd")
		var projectile = CharacterBody2D.new()
		projectile.set_script(projectile_scene)
		
		# Calculate direction with spread for multi-shot
		var shoot_direction = direction
		if PlayerStats.multi_shot > 1:
			var angle_offset = (i - (PlayerStats.multi_shot - 1) / 2.0) * deg_to_rad(15.0)  # 15 degree spread
			shoot_direction = direction.rotated(angle_offset)
		
		# Configure projectile
		projectile.global_position = global_position
		projectile.set_direction(shoot_direction)
		
		# Add to scene
		get_parent().add_child(projectile)
	
	print("Shot ", PlayerStats.multi_shot, " projectile(s) - ", PlayerStats.get_stats_summary())

func take_damage(amount: int):
	"""Take damage and handle death"""
	health -= amount
	print("Player took ", amount, " damage! Health: ", health, "/", max_health)
	
	if health <= 0:
		die()

func die():
	"""Player death"""
	print("Player died! Game Over!")
	# For now, just restart the scene
	get_tree().reload_current_scene()

func can_dash() -> bool:
	return not is_dashing and dash_cooldown_timer <= 0 and movement_input.length() > 0

func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = movement_input.normalized()

func end_dash():
	is_dashing = false
	dash_direction = Vector2.ZERO

# ================================================
# ISAAC-STYLE ITEM COLLECTION
# ================================================

func collect_item(item):
	"""Collect an Isaac-style item and apply its effects"""
	print("[SimplePlayer] Collecting item: ", item.get_item_name())
	# The item handles its own stat application in pickup_item()
	# We just need to have this method so the item can detect us as a valid collector