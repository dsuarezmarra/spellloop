extends Node2D

class_name EnemyTier2LoboDeCristal
@export var enemy_name = "Lobo de Cristal"
@export var slug = "enemy_tier_2_lobo_de_cristal"
@export var difficulty_tier = 2
@export var base_hp = 70
@export var base_speed = 72.0
@export var base_damage = 14
@export var xp_drop = 9
@export var size_px = 64
@export var collider_radius = 30.0
@export var attack_type = "melee"
@export var attack_rate = 1.0
@export var movement_behavior = "pack"
@export var sprite_path = "res://assets/sprites/enemies/tier_2/lobo_de_cristal.png"
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
    var dir = (player_reference.global_position - global_position).normalized()
    global_position += dir * base_speed * delta

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
    return int(round(base_hp * 1.2))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.1))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 2)
