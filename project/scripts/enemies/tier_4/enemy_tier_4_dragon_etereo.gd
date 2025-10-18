extends Node2D

class_name EnemyTier4DragonEtereo
@export var enemy_name = "Dragón Etéreo"
@export var slug = "enemy_tier_4_dragon_etereo"
@export var difficulty_tier = 4
@export var base_hp = 520
@export var base_speed = 56.0
@export var base_damage = 64
@export var xp_drop = 100
@export var size_px = 200
@export var collider_radius = 96.0
@export var attack_type = "ranged"
@export var attack_rate = 1.4
@export var movement_behavior = "flying_boss_like"
@export var sprite_path = "res://assets/sprites/enemies/tier_4/dragon_etereo.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var arcane_fire_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/arcane_fire.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/ChaosProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            arcane_fire_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    fly_behavior(_delta)
    if randf() < 0.015:
        breathe_arcane_fire()

func fly_behavior(delta):
    var dir = (player_reference.global_position - global_position).normalized()
    global_position += dir * base_speed * delta

func breathe_arcane_fire():
    if arcane_fire_scene:
        var proj = arcane_fire_scene.instantiate()
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
    return int(round(base_hp * 1.35))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.2))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 4)
