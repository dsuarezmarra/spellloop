extends Node2D

class_name EnemyTier2GolemRunico
@export var enemy_name = "Gólem Rúnico"
@export var slug = "enemy_tier_2_golem_runico"
@export var difficulty_tier = 2
@export var base_hp = 120
@export var base_speed = 28.0
@export var base_damage = 18
@export var xp_drop = 12
@export var size_px = 96
@export var collider_radius = 44.0
@export var attack_type = "melee"
@export var attack_rate = 1.8
@export var movement_behavior = "slow"
@export var sprite_path = "res://assets/sprites/enemies/tier_2/golem_runico.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()

func _physics_process(delta):
    if not player_reference:
        return
    if movement_behavior == "slow":
        slow_move_towards_player(delta)

func slow_move_towards_player(delta):
    var direction = (player_reference.global_position - global_position).normalized()
    global_position += direction * base_speed * delta

func perform_attack():
    if player_reference and player_reference.has_method("take_damage"):
        player_reference.take_damage(calculate_scaled_damage())

func take_damage(amount: int):
    current_hp -= amount
    if current_hp <= 0:
        _on_death()

func _on_death():
    drop_xp(calculate_scaled_xp())
    queue_free()

func drop_xp(_amount: int):
    var xp_scene = preload("res://scenes/pickups/XPOrb.tscn")
    if xp_scene:
        var xp_orb = xp_scene.instantiate()
        get_parent().add_child(xp_orb)
        xp_orb.global_position = global_position

func calculate_scaled_hp() -> int:
    return int(round(base_hp * 1.25))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.15))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 2)
