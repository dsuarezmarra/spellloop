extends Node2D

class_name EnemyTier4SenorDeLasLlamas
@export var enemy_name = "Señor de las Llamas"
@export var slug = "enemy_tier_4_senor_de_las_llamas"
@export var difficulty_tier = 4
@export var base_hp = 460
@export var base_speed = 52.0
@export var base_damage = 62
@export var xp_drop = 90
@export var size_px = 170
@export var collider_radius = 78.0
@export var attack_type = "ranged"
@export var attack_rate = 1.3
@export var movement_behavior = "boss_aggressive"
@export var sprite_path = "res://assets/sprites/enemies/tier_4/senor_de_las_llamas.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var flame_wave_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/flame_wave.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/ChaosProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            flame_wave_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.02:
        cast_flame_wave()

func cast_flame_wave():
    if flame_wave_scene:
        var proj = flame_wave_scene.instantiate()
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
    return int(round(base_damage * 1.18))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 4)
