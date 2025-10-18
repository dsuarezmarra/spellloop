extends Node2D

class_name EnemyTier4ArchimagoPerdido
@export var enemy_name = "Archimago Perdido"
@export var slug = "enemy_tier_4_archimago_perdido"
@export var difficulty_tier = 4
@export var base_hp = 380
@export var base_speed = 48.0
@export var base_damage = 48
@export var xp_drop = 60
@export var size_px = 140
@export var collider_radius = 64.0
@export var attack_type = "ranged"
@export var attack_rate = 1.8
@export var movement_behavior = "caster"
@export var sprite_path = "res://assets/sprites/enemies/tier_4/archimago_perdido.png"
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
        "res://scenes/projectiles/arcane_blast.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/ChaosProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            spell_scene = load(p)
            break

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.025:
        cast_arcane_blast()

func cast_arcane_blast():
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
    return int(round(base_hp * 1.4))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.25))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 4)
