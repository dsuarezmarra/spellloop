extends Node2D

class_name EnemyTier4ReinaDelHielo
@export var enemy_name = "Reina del Hielo"
@export var slug = "enemy_tier_4_reina_del_hielo"
@export var difficulty_tier = 4
@export var base_hp = 420
@export var base_speed = 44.0
@export var base_damage = 56
@export var xp_drop = 80
@export var size_px = 160
@export var collider_radius = 72.0
@export var attack_type = "ranged"
@export var attack_rate = 2.0
@export var movement_behavior = "boss"
@export var sprite_path = "res://assets/sprites/enemies/tier_4/reina_del_hielo.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var frost_nova_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/frost_nova.tscn",
        "res://scenes/effects/BossDeathEffect.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            frost_nova_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.02:
        cast_frost_nova()

func cast_frost_nova():
    if frost_nova_scene:
        var proj = frost_nova_scene.instantiate()
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
    return int(round(base_damage * 1.18))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 4)
