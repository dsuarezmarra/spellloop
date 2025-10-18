extends Node2D

class_name EnemyTier3CaballeroDelVacio
@export var enemy_name = "Caballero del Vacío"
@export var slug = "enemy_tier_3_caballero_del_vacio"
@export var difficulty_tier = 3
@export var base_hp = 220
@export var base_speed = 36.0
@export var base_damage = 28
@export var xp_drop = 30
@export var size_px = 120
@export var collider_radius = 54.0
@export var attack_type = "melee"
@export var attack_rate = 1.6
@export var movement_behavior = "tank"
@export var sprite_path = "res://assets/sprites/enemies/tier_3/caballero_del_vacio.png"
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
    return int(round(base_hp * 1.35))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.2))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 3)
