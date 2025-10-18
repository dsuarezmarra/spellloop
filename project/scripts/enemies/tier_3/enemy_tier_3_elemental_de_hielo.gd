extends Node2D

class_name EnemyTier3ElementalDeHielo
@export var enemy_name = "Elemental de Hielo"
@export var slug = "enemy_tier_3_elemental_de_hielo"
@export var difficulty_tier = 3
@export var base_hp = 180
@export var base_speed = 34.0
@export var base_damage = 26
@export var xp_drop = 26
@export var size_px = 110
@export var collider_radius = 48.0
@export var attack_type = "ranged"
@export var attack_rate = 1.9
@export var movement_behavior = "slow_float"
@export var sprite_path = "res://assets/sprites/enemies/tier_3/elemental_de_hielo.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var frost_shard_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/frost_shard.tscn",
    "res://scenes/pickups/XPOrb.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            frost_shard_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.015:
        cast_frost_shard()

func cast_frost_shard():
    if frost_shard_scene:
        var proj = frost_shard_scene.instantiate()
        get_parent().add_child(proj)
        proj.global_position = global_position
        proj.direction = (player_reference.global_position - global_position).normalized()
        proj.damage = calculate_scaled_damage()

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
    return int(round(base_hp * 1.28))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.15))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 3)
