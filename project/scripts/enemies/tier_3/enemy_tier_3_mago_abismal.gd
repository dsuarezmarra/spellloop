extends Node2D

class_name EnemyTier3MagoAbismal
@export var enemy_name = "Mago Abismal"
@export var slug = "enemy_tier_3_mago_abismal"
@export var difficulty_tier = 3
@export var base_hp = 140
@export var base_speed = 46.0
@export var base_damage = 32
@export var xp_drop = 28
@export var size_px = 96
@export var collider_radius = 42.0
@export var attack_type = "ranged"
@export var attack_rate = 2.0
@export var movement_behavior = "kiting"
@export var sprite_path = "res://assets/sprites/enemies/tier_3/mago_abismal.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var spell_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/abyss_spell.tscn",
        "res://scenes/effects/EnemyProjectile.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            spell_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.02:
        cast_abyss_spell()

func cast_abyss_spell():
    if spell_scene:
        var s = spell_scene.instantiate()
        get_parent().add_child(s)
        s.global_position = global_position
        s.direction = (player_reference.global_position - global_position).normalized()
        s.damage = calculate_scaled_damage()

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
    return int(round(base_hp * 1.22))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.2))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 3)
