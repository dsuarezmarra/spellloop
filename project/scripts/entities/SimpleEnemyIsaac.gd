# SimpleEnemyIsaac.gd - Isaac-style enemies with Funko Pop characteristics
extends CharacterBody2D

enum EnemyType {
	GOBLIN_MAGE,
	SKELETON_WIZARD,
	DARK_SPIRIT,
	FIRE_IMP
}

var enemy_type: EnemyType = EnemyType.GOBLIN_MAGE
var health: int = 30
var max_health: int = 30
var speed: float = 80.0
var attack_damage: int = 10
var attack_range: float = 120.0
var attack_cooldown: float = 2.0
var last_attack_time: float = 0.0

# Animation variables
var current_direction = FunkoPopEnemyIsaac.Direction.DOWN
var current_frame = FunkoPopEnemyIsaac.AnimFrame.IDLE
var animation_timer = 0.0
var animation_speed = 3.0  # 3 FPS for enemies

# AI variables
var player_ref: Node2D = null
var detection_range: float = 150.0
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var wander_change_time: float = 2.0

# Death flag
var is_dead: bool = false

func _ready() -> void:
	# Randomize enemy type
	enemy_type = EnemyType.values()[randi() % EnemyType.size()]
	print("[SimpleEnemy] Isaac-style enemy created: ", EnemyType.keys()[enemy_type])
	
	# Set health based on enemy type
	match enemy_type:
		EnemyType.GOBLIN_MAGE:
			max_health = 25
			speed = 90.0
			attack_damage = 8
		EnemyType.SKELETON_WIZARD:
			max_health = 35
			speed = 70.0
			attack_damage = 12
		EnemyType.DARK_SPIRIT:
			max_health = 20
			speed = 110.0
			attack_damage = 15
		EnemyType.FIRE_IMP:
			max_health = 30
			speed = 100.0
			attack_damage = 10
	
	health = max_health
	
	# Create collision shape (Isaac-style smaller hitbox)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)  # Smaller Isaac-style hitbox
	collision.shape = shape
	add_child(collision)
	
	# Create sprite node
	var sprite = Sprite2D.new()
	sprite.name = "EnemySprite"
	add_child(sprite)
	
	# Set collision properties
	collision_layer = 4  # Enemy layer
	collision_mask = 3   # Collide with player (1) and walls (2)
	
	# Initialize random wander direction
	_change_wander_direction()
	
	# Update sprite
	update_sprite()
	
	print("[SimpleEnemy] Isaac-style enemy setup complete")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Find player if not found
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
	
	# Update wander timer
	wander_timer += delta
	if wander_timer >= wander_change_time:
		_change_wander_direction()
		wander_timer = 0.0
	
	# Check if player is in detection range
	var target_velocity = Vector2.ZERO
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		
		if distance_to_player <= detection_range:
			# Chase player
			var direction_to_player = (player_ref.global_position - global_position).normalized()
			target_velocity = direction_to_player * speed
			update_direction_from_movement(direction_to_player)
			
			# Try to attack if in range
			if distance_to_player <= attack_range:
				attempt_attack()
		else:
			# Wander around
			target_velocity = wander_direction * speed * 0.5  # Slower wandering
			if wander_direction.length() > 0:
				update_direction_from_movement(wander_direction)
	
	# Apply movement
	velocity = target_velocity
	move_and_slide()
	
	# Update animation
	update_animation(delta, velocity.length() > 0)

func _change_wander_direction():
	"""Change wander direction randomly"""
	var angle = randf() * TAU  # Random angle
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_change_time = randf_range(1.5, 3.0)  # Random time between direction changes

func update_direction_from_movement(movement: Vector2):
	"""Update direction based on movement vector"""
	if movement.length() > 0:
		# Determine primary direction based on movement vector
		if abs(movement.x) > abs(movement.y):
			# Horizontal movement dominant
			if movement.x > 0:
				current_direction = FunkoPopEnemyIsaac.Direction.RIGHT
			else:
				current_direction = FunkoPopEnemyIsaac.Direction.LEFT
		else:
			# Vertical movement dominant
			if movement.y > 0:
				current_direction = FunkoPopEnemyIsaac.Direction.DOWN
			else:
				current_direction = FunkoPopEnemyIsaac.Direction.UP

func update_animation(delta: float, is_moving: bool):
	"""Update animation"""
	animation_timer += delta
	
	if is_moving:
		# Alternate between WALK1 and WALK2
		if animation_timer >= 1.0 / animation_speed:
			animation_timer = 0.0
			if current_frame == FunkoPopEnemyIsaac.AnimFrame.WALK1:
				current_frame = FunkoPopEnemyIsaac.AnimFrame.WALK2
			else:
				current_frame = FunkoPopEnemyIsaac.AnimFrame.WALK1
	else:
		# Idle state
		current_frame = FunkoPopEnemyIsaac.AnimFrame.IDLE
		animation_timer = 0.0
	
	update_sprite()

func update_sprite():
	"""Update sprite based on current direction and frame"""
	var sprite_node = get_node_or_null("EnemySprite")
	if sprite_node:
		# Convertir el tipo de enemigo local al tipo esperado por FunkoPopEnemyIsaac
		var funko_enemy_type = _convert_enemy_type_to_funko(enemy_type)
		var texture = FunkoPopEnemyIsaac.create_enemy_sprite(funko_enemy_type, current_direction, current_frame)
		sprite_node.texture = texture

func _convert_enemy_type_to_funko(local_enemy_type: EnemyType) -> FunkoPopEnemyIsaac.EnemyType:
	"""Convert local EnemyType to FunkoPopEnemyIsaac.EnemyType"""
	match local_enemy_type:
		EnemyType.GOBLIN_MAGE:
			return FunkoPopEnemyIsaac.EnemyType.GOBLIN_MAGE
		EnemyType.SKELETON_WIZARD:
			return FunkoPopEnemyIsaac.EnemyType.SKELETON_WIZARD
		EnemyType.DARK_SPIRIT:
			return FunkoPopEnemyIsaac.EnemyType.DARK_SPIRIT
		EnemyType.FIRE_IMP:
			return FunkoPopEnemyIsaac.EnemyType.FIRE_IMP
		_:
			return FunkoPopEnemyIsaac.EnemyType.GOBLIN_MAGE

func attempt_attack():
	"""Try to attack the player"""
	var current_time = Time.get_ticks_msec() / 1000.0  # Convertir milisegundos a segundos
	
	if current_time - last_attack_time >= attack_cooldown:
		last_attack_time = current_time
		attack_player()

func attack_player():
	"""Attack the player"""
	if not player_ref:
		return
	
	print("[SimpleEnemy] ", EnemyType.keys()[enemy_type], " attacking player!")
	
	# Create attack effect based on enemy type
	match enemy_type:
		EnemyType.GOBLIN_MAGE:
			_create_magic_projectile(Color.GREEN)
		EnemyType.SKELETON_WIZARD:
			_create_magic_projectile(Color.PURPLE)
		EnemyType.DARK_SPIRIT:
			_create_magic_projectile(Color.BLACK)
		EnemyType.FIRE_IMP:
			_create_magic_projectile(Color.RED)

func _create_magic_projectile(color: Color):
	"""Create a simple magic projectile"""
	var projectile = Area2D.new()
	projectile.name = "EnemyProjectile"
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6
	collision.shape = shape
	projectile.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	projectile.add_child(sprite)
	
	# Calculate direction to player
	var direction = (player_ref.global_position - global_position).normalized()
	
	# Set position and add to scene
	projectile.global_position = global_position + direction * 25
	get_parent().add_child(projectile)
	
	# Add simple movement without dynamic script
	var tween = create_tween()
	var target_pos = projectile.global_position + direction * 800
	tween.tween_property(projectile, "global_position", target_pos, 4.0)
	tween.tween_callback(projectile.queue_free)
	
	print("[SimpleEnemy] Magic projectile created")

func take_damage(amount: int):
	"""Take damage"""
	if is_dead:
		return
	
	health -= amount
	print("[SimpleEnemy] ", EnemyType.keys()[enemy_type], " took ", amount, " damage. Health: ", health, "/", max_health)
	
	if health <= 0:
		die()

func die():
	"""Handle death"""
	if is_dead:
		return
	
	is_dead = true
	print("[SimpleEnemy] ", EnemyType.keys()[enemy_type], " died!")
	
	# Create death effect
	_create_death_effect()
	
	# Remove after short delay
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	# Make semi-transparent
	modulate = Color(1, 1, 1, 0.5)

func _create_death_effect():
	"""Create a simple death effect"""
	print("[SimpleEnemy] Creating death effect")
	
	# Could add particle effects or animations here
	# For now, just log the death