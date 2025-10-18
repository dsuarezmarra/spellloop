extends Node2D

class_name EnemyTier4TitanArcano
@export var enemy_name = "Titán Arcano"
@export var slug = "enemy_tier_4_titan_arcano"
@export var difficulty_tier = 4
@export var base_hp = 600
@export var base_speed = 30.0
@export var base_damage = 72
@export var xp_drop = 120
@export var size_px = 220
@export var collider_radius = 110.0
@export var attack_type = "melee"
@export var attack_rate = 2.2
@export var movement_behavior = "brute"
@export var sprite_path = "res://assets/sprites/enemies/tier_4/titan_arcano.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var earth_slam_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/earth_slam.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/TerrainDamage.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            earth_slam_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    charge_towards_player(_delta)

func charge_towards_player(delta):
    var dir = (player_reference.global_position - global_position).normalized()
    global_position += dir * base_speed * delta
    if randf() < 0.01:
        slam_ground()

func slam_ground():
    if earth_slam_scene:
        var proj = earth_slam_scene.instantiate()
        get_parent().add_child(proj)
        proj.global_position = global_position
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
    return int(round(base_hp * 1.3))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.22))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 4)
