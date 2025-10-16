extends Node2D
# Enemy: Esqueleto Guerrero
# Tier 1 (0-5 minutos) - Enemigo melee agresivo

@export var enemy_name = "Esqueleto Guerrero"
@export var slug = "enemy_tier_1_skeleton_warrior"
@export var difficulty_tier = 1
@export var base_hp = 42
@export var base_speed = 50.0
@export var base_damage = 8
@export var xp_drop = 5
@export var size_px = 64
@export var collider_radius = 26.0
@export var attack_type = "melee"
@export var attack_rate = 1.8
@export var movement_behavior = "charge"
@export var sprite_path = "res://assets/sprites/enemies/enemy_tier_1_skeleton_warrior.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var attack_timer: float = 0.0
var scale_manager: Node
var charge_cooldown: float = 0.0
var is_charging: bool = false

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
	charge_behavior(delta)
	handle_attack(delta)

func charge_behavior(delta):
	charge_cooldown -= delta
	var scaled_speed = base_speed * scale_manager.current_scale
	
	if charge_cooldown <= 0.0 and not is_charging:
		var distance = global_position.distance_to(player_reference.global_position)
		if distance <= 200.0 * scale_manager.current_scale and distance >= 80.0 * scale_manager.current_scale:
			is_charging = true
			charge_cooldown = 3.0  # Cooldown de carga
	
	if is_charging:
		var direction = (player_reference.global_position - global_position).normalized()
		global_position += direction * scaled_speed * 2.0 * delta  # Velocidad doble al cargar
		# Terminar carga si está muy cerca
		if global_position.distance_to(player_reference.global_position) <= 40.0:
			is_charging = false
	else:
		# Movimiento normal de búsqueda
		var direction = (player_reference.global_position - global_position).normalized()
		global_position += direction * scaled_speed * delta

func handle_attack(delta):
	attack_timer -= delta
	if attack_timer <= 0.0:
		var distance_to_player = global_position.distance_to(player_reference.global_position)
		var attack_range = collider_radius * 1.8
		
		if distance_to_player <= attack_range:
			perform_attack()
			attack_timer = attack_rate

func perform_attack():
	if player_reference.has_method("take_damage"):
		var damage = calculate_scaled_damage()
		if is_charging:
			damage = int(damage * 1.5)  # Más daño al cargar
		player_reference.take_damage(damage)

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
		var xp_orb = xp_scene.instantiate()
		get_parent().add_child(xp_orb)
		xp_orb.global_position = global_position
		xp_orb.xp_value = amount

func maybe_drop_item():
	var drop_chance = 0.07
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
		name = "Esqueleto Capitán"
		modulate = Color.GOLD
		current_hp = int(current_hp * 1.7)
		scale *= 1.25
