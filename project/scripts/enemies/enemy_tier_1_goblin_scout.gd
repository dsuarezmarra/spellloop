extends Node2D
# Enemy: Goblin Explorador
# Tier 1 (0-5 minutos) - Enemigo a distancia básico

@export var name = "Goblin Explorador"
@export var slug = "enemy_tier_1_goblin_scout"
@export var difficulty_tier = 1
@export var base_hp = 28
@export var base_speed = 55.0
@export var base_damage = 6
@export var xp_drop = 4
@export var size_px = 64
@export var collider_radius = 26.0
@export var attack_type = "ranged"
@export var attack_rate = 2.0
@export var movement_behavior = "kite"
@export var sprite_path = "res://assets/sprites/enemies/enemy_tier_1_goblin_scout.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var attack_timer: float = 0.0
var scale_manager: Node
var kite_direction: Vector2
var kite_timer: float = 0.0

func _ready():
	if has_node("Sprite"):
		$Sprite.texture = load(sprite_path)
	
	scale_manager = get_node("/root/ScaleManager")
	player_reference = get_tree().get_first_node_in_group("player")
	current_hp = calculate_scaled_hp()
	
	if has_node("CollisionShape2D"):
		var shape = CircleShape2D.new()
		shape.radius = collider_radius * scale_manager.current_scale
		$CollisionShape2D.shape = shape

func _physics_process(delta):
	if not player_reference:
		return
	
	kite_behavior(delta)
	handle_attack(delta)

func kite_behavior(delta):
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	var ideal_distance = 150.0 * scale_manager.current_scale
	var scaled_speed = base_speed * scale_manager.current_scale
	
	kite_timer -= delta
	
	if distance_to_player < ideal_distance:
		# Alejarse del jugador
		var direction = (global_position - player_reference.global_position).normalized()
		global_position += direction * scaled_speed * delta
	elif distance_to_player > ideal_distance * 1.5:
		# Acercarse al jugador
		var direction = (player_reference.global_position - global_position).normalized()
		global_position += direction * scaled_speed * 0.7 * delta
	else:
		# Movimiento lateral
		if kite_timer <= 0.0:
			kite_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			kite_timer = randf_range(1.0, 2.5)
		global_position += kite_direction * scaled_speed * 0.5 * delta

func handle_attack(delta):
	attack_timer -= delta
	
	if attack_timer <= 0.0:
		var distance_to_player = global_position.distance_to(player_reference.global_position)
		var attack_range = 200.0 * scale_manager.current_scale
		
		if distance_to_player <= attack_range:
			perform_ranged_attack()
			attack_timer = attack_rate

func perform_ranged_attack():
	# Crear proyectil simple
	var projectile_scene = preload("res://scenes/enemies/EnemyProjectile.tscn")
	if projectile_scene:
		var projectile = projectile_scene.instance()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		
		var direction = (player_reference.global_position - global_position).normalized()
		projectile.setup(direction, calculate_scaled_damage(), 300.0)

func take_damage(amount: int):
	current_hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
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
	var drop_chance = 0.06  # 6% para ranged
	if is_special_variant:
		drop_chance = 1.0
	
	if randf() < drop_chance:
		var item_manager = get_node("/root/ItemManager")
		if item_manager and item_manager.has_method("spawn_item_drop"):
			var rarity = ItemManager.ItemRarity.WHITE
			if is_special_variant:
				rarity = ItemManager.ItemRarity.BLUE
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
		name = "Goblin Élite"
		modulate = Color.ORANGE  # Color opuesto
		current_hp = int(current_hp * 1.6)
		scale *= 1.15