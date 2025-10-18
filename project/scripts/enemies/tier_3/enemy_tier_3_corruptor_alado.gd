extends Node2D

class_name EnemyTier3CorruptorAlado
@export var enemy_name = "Corruptor Alado"
@export var slug = "enemy_tier_3_corruptor_alado"
@export var difficulty_tier = 3
@export var base_hp = 160
@export var base_speed = 84.0
@export var base_damage = 24
@export var xp_drop = 24
@export var size_px = 96
@export var collider_radius = 40.0
@export var attack_type = "ranged"
@export var attack_rate = 1.3
@export var movement_behavior = "flyer"
@export var sprite_path = "res://assets/sprites/enemies/tier_3/corruptor_alado.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node

func _physics_process(delta):
    if not player_reference:
        return
    var dir = (player_reference.global_position - global_position).normalized()
    global_position += dir * base_speed * delta
    if randf() < 0.01:
        cast_corrupting_bolt()

var corruption_bolt_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/corruption_bolt.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/ChaosProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            corruption_bolt_scene = load(p)
            break

func cast_corrupting_bolt():
    if corruption_bolt_scene:
        var proj = corruption_bolt_scene.instantiate()
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
    return int(round(base_hp * 1.25))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.18))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 3)
