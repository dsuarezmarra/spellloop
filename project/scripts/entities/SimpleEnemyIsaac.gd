# SimpleEnemyIsaac.gd - Isaac-style enemies
extends CharacterBody2D

signal enemy_died(enemy: Node)

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

# Visual components
@onready var sprite_node: Sprite2D
@onready var collision_shape: CollisionShape2D

# AI variables
var player_ref: Node2D = null
var detection_range: float = 150.0
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var wander_cooldown: float = 3.0

# Enemy states
enum EnemyState {
	WANDERING,
	CHASING,
	ATTACKING,
	DEAD
}

var current_state: EnemyState = EnemyState.WANDERING

func _ready():
	print("[SimpleEnemyIsaac] Creating Isaac-style enemy...")
	_setup_enemy()
	_setup_visuals()
	_setup_collision()

func _setup_enemy():
	"""Setup enemy type and stats"""
	enemy_type = EnemyType.values()[randi() % EnemyType.size()]
	
	match enemy_type:
		EnemyType.GOBLIN_MAGE:
			health = 25
			speed = 90.0
			attack_damage = 8
		EnemyType.SKELETON_WIZARD:
			health = 35
			speed = 70.0
			attack_damage = 12
		EnemyType.DARK_SPIRIT:
			health = 20
			speed = 120.0
			attack_damage = 6
		EnemyType.FIRE_IMP:
			health = 30
			speed = 100.0
			attack_damage = 10
	
	max_health = health

func _setup_visuals():
	"""Setup visual representation"""
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	
	# Create colored sprite based on enemy type
	var color = Color.RED
	match enemy_type:
		EnemyType.GOBLIN_MAGE:
			color = Color.GREEN
		EnemyType.SKELETON_WIZARD:
			color = Color.WHITE
		EnemyType.DARK_SPIRIT:
			color = Color.PURPLE
		EnemyType.FIRE_IMP:
			color = Color.ORANGE_RED
	
	var image = Image.create(28, 28, false, Image.FORMAT_RGB8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite_node.texture = texture

func _setup_collision():
	"""Setup collision detection"""
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(26, 26)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 8  # Enemy layer
	collision_mask = 2 | 1  # Can hit walls and player

func _physics_process(delta):
	_update_ai(delta)
	_update_attack_timer(delta)
	
	match current_state:
		EnemyState.WANDERING:
			_wander(delta)
		EnemyState.CHASING:
			_chase_player()
		EnemyState.ATTACKING:
			_attack_player()
		EnemyState.DEAD:
			return
	
	move_and_slide()

func _update_ai(delta):
	"""Update AI state machine"""
	_find_player()
	
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		
		if distance_to_player <= detection_range:
			if distance_to_player <= attack_range and _can_attack():
				current_state = EnemyState.ATTACKING
			else:
				current_state = EnemyState.CHASING
		else:
			current_state = EnemyState.WANDERING

func _wander(delta):
	"""Wander behavior"""
	wander_timer -= delta
	
	if wander_timer <= 0:
		# Choose new wander direction
		var angle = randf() * 2 * PI
		wander_direction = Vector2(cos(angle), sin(angle))
		wander_timer = wander_cooldown
	
	velocity = wander_direction * speed * 0.3  # Slower wandering

func _chase_player():
	"""Chase the player"""
	if not player_ref:
		current_state = EnemyState.WANDERING
		return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed

func _attack_player():
	"""Attack the player"""
	if _can_attack():
		print("[SimpleEnemyIsaac] Attacking player for ", attack_damage, " damage")
		last_attack_time = Time.get_time_dict_from_system()["unix"]
		
		# Visual attack feedback
		sprite_node.modulate = Color.YELLOW
		var tween = create_tween()
		tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.3)
		
		# TODO: Deal damage to player
	
	current_state = EnemyState.CHASING

func _find_player():
	"""Find player in the scene"""
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

func _can_attack() -> bool:
	"""Check if enemy can attack"""
	var current_time = Time.get_time_dict_from_system()["unix"]
	return (current_time - last_attack_time) >= attack_cooldown

func _update_attack_timer(delta):
	"""Update attack cooldown"""
	pass  # Already handled in _can_attack()

func take_damage(amount: int):
	"""Take damage and handle death"""
	health -= amount
	print("[SimpleEnemyIsaac] Took ", amount, " damage. Health: ", health, "/", max_health)
	
	# Visual feedback
	sprite_node.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", Color.RED, 0.2)
	
	if health <= 0:
		die()

func die():
	"""Handle enemy death"""
	print("[SimpleEnemyIsaac] Enemy died")
	current_state = EnemyState.DEAD
	enemy_died.emit(self)
	
	# Death animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.tween_callback(queue_free)

func get_damage() -> int:
	"""Get damage this enemy deals"""
	return attack_damage
