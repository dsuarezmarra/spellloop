extends Node2D
# Enemy: Murciélago Sombra
# Tier 1 (0-5 minutos) - Enemigo volador errático

@export var enemy_name = "Murciélago Sombra"
@export var slug = "enemy_tier_1_shadow_bat"
@export var difficulty_tier = 1
@export var base_hp = 22
@export var base_speed = 70.0
@export var base_damage = 3
@export var xp_drop = 2
@export var size_px = 64
@export var collider_radius = 22.0
@export var attack_type = "melee"
@export var attack_rate = 0.8
@export var movement_behavior = "wander_seek"
@export var sprite_path = "res://assets/sprites/enemies/enemy_tier_1_shadow_bat.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var attack_timer: float = 0.0
var scale_manager: Node
var wander_direction: Vector2
var wander_timer: float = 0.0
var swarm_mode: bool = false

func _ready():
	if has_node("Sprite"):
		$Sprite.texture = load(sprite_path)
	scale_manager = get_node("/root/ScaleManager")
	player_reference = get_tree().get_first_node_in_group("player")
	current_hp = calculate_scaled_hp()
	wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	if has_node("CollisionShape2D"):
		var shape = CircleShape2D.new()
		shape.radius = collider_radius * scale_manager.current_scale
		$CollisionShape2D.shape = shape

func _physics_process(delta):
	if not player_reference:
		return
	wander_seek_behavior(delta)
	handle_attack(delta)

func wander_seek_behavior(delta):
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	var scaled_speed = base_speed * scale_manager.current_scale
	wander_timer -= delta
	
	# Cambiar a modo enjambre si está cerca
	swarm_mode = distance_to_player <= 120.0 * scale_manager.current_scale
	
	if swarm_mode:
		# Comportamiento agresivo directo
		var direction = (player_reference.global_position - global_position).normalized()
		global_position += direction * scaled_speed * 1.3 * delta
	else:
		# Comportamiento errático de vagabundeo
		if wander_timer <= 0.0:
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			wander_timer = randf_range(0.5, 1.5)
		
		# Mezclar vagabundeo con búsqueda lenta
		var seek_direction = (player_reference.global_position - global_position).normalized()
		var mixed_direction = (wander_direction * 0.7 + seek_direction * 0.3).normalized()
		global_position += mixed_direction * scaled_speed * delta

func handle_attack(delta):
	attack_timer -= delta
	if attack_timer <= 0.0:
		var distance_to_player = global_position.distance_to(player_reference.global_position)
		var attack_range = collider_radius * 1.3
		
		if distance_to_player <= attack_range:
			perform_swarm_attack()
			attack_timer = attack_rate

func perform_swarm_attack():
	if player_reference.has_method("take_damage"):
		var damage = calculate_scaled_damage()
		player_reference.take_damage(damage)
		# Los murciélagos atacan rápido pero hacen poco daño

func take_damage(amount: int):
	current_hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if current_hp <= 0:
		_on_death()

func _on_death():
	drop_xp(calculate_scaled_xp())
	maybe_drop_item()
	queue_free()

func drop_xp(amount: int):
	var xp_scene = preload("res://scenes/effects/XPOrb.tscn")
	if xp_scene:
		var xp_orb = xp_scene.instance()
		get_parent().add_child(xp_orb)
		xp_orb.global_position = global_position
		xp_orb.xp_value = amount

func maybe_drop_item():
	var drop_chance = 0.03  # Menor probabilidad por ser débil
	if is_special_variant:
		drop_chance = 1.0
	if randf() < drop_chance:
		var item_manager = get_node("/root/ItemManager")
		if item_manager and item_manager.has_method("spawn_item_drop"):
			var rarity = ItemsDefinitions.ItemRarity.WHITE
			if is_special_variant:
				rarity = ItemsDefinitions.ItemRarity.BLUE
			item_manager.spawn_item_drop(global_position, rarity)

func calculate_scaled_hp() -> int:
	var game_manager = get_node("/root/GameManager")
	var minutes_elapsed = 0
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	var hp = base_hp * (1 + 0.12 * minutes_elapsed) * (1 + 0.25 * (difficulty_tier - 1))
	return int(round(hp))

func calculate_scaled_damage() -> int:
	var game_manager = get_node("/root/GameManager")
	var minutes_elapsed = 0
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	var damage = base_damage * (1 + 0.09 * minutes_elapsed)
	return int(round(damage))

func calculate_scaled_xp() -> int:
	var xp = xp_drop * (1 + 0.1 * difficulty_tier)
	if is_special_variant:
		xp *= 2
	return int(round(xp))

func _on_spawn(spawn_position: Vector2):
	global_position = spawn_position
	if is_special_variant:
		name = "Murciélago Vampiro"
		modulate = Color.CRIMSON
		current_hp = int(current_hp * 1.4)
		base_speed *= 1.3
