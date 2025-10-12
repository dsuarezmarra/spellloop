# SimpleEnemy.gd
# Simple enemy that follows the player
extends CharacterBody2D

signal enemy_died(enemy: Node)

var health: int = 30
var max_health: int = 30
var speed: float = 150.0
var damage: int = 20
var player_ref: Node2D = null
var attack_range: float = 40.0
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0

# Visual components
@onready var sprite_node: Sprite2D
@onready var collision_shape: CollisionShape2D

# Enemy state
enum EnemyState {
	IDLE,
	CHASING,
	ATTACKING,
	DEAD
}

var current_state: EnemyState = EnemyState.IDLE

func _ready():
	print("[SimpleEnemy] Creating simple enemy...")
	_setup_visuals()
	_setup_collision()
	_find_player()

func _setup_visuals():
	"""Setup basic visual representation"""
	sprite_node = Sprite2D.new()
	sprite_node.modulate = Color.RED
	add_child(sprite_node)
	
	# Create a simple colored rectangle as placeholder
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite_node.texture = texture

func _setup_collision():
	"""Setup collision detection"""
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(30, 30)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 8  # Enemy layer
	collision_mask = 2 | 1  # Can hit walls (layer 2) and player (layer 1)

func _find_player():
	"""Find player reference in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		current_state = EnemyState.CHASING
		print("[SimpleEnemy] Player found, starting chase")

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta
	
	match current_state:
		EnemyState.IDLE:
			_find_player()
		
		EnemyState.CHASING:
			_chase_player()
		
		EnemyState.ATTACKING:
			_attack_player()
		
		EnemyState.DEAD:
			return
	
	move_and_slide()

func _chase_player():
	"""Chase the player"""
	if not player_ref:
		current_state = EnemyState.IDLE
		return
	
	# Move towards player
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Check if close enough to attack
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player <= attack_range and attack_timer <= 0:
		current_state = EnemyState.ATTACKING

func _attack_player():
	"""Attack the player"""
	if attack_timer <= 0:
		print("[SimpleEnemy] Attacking player for ", damage, " damage")
		# TODO: Deal damage to player
		attack_timer = attack_cooldown
		current_state = EnemyState.CHASING

func take_damage(amount: int):
	"""Take damage and handle death"""
	health -= amount
	print("[SimpleEnemy] Took ", amount, " damage. Health: ", health, "/", max_health)
	
	# Visual feedback
	sprite_node.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", Color.RED, 0.2)
	
	if health <= 0:
		die()

func die():
	"""Handle enemy death"""
	print("[SimpleEnemy] Enemy died")
	current_state = EnemyState.DEAD
	enemy_died.emit(self)
	
	# Death animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.tween_callback(queue_free)

func get_damage() -> int:
	"""Get damage this enemy deals"""
	return damage