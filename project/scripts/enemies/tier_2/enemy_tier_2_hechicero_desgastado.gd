extends Node2D

class_name EnemyTier2HechiceroDesgastado
@export var enemy_name = "Hechicero Desgastado"
@export var slug = "enemy_tier_2_hechicero_desgastado"
@export var difficulty_tier = 2
@export var base_hp = 45
@export var base_speed = 56.0
@export var base_damage = 20
@export var xp_drop = 10
@export var size_px = 64
@export var collider_radius = 28.0
@export var attack_type = "ranged"
@export var attack_rate = 2.2
@export var movement_behavior = "kiting"
@export var sprite_path = "res://assets/sprites/enemies/tier_2/hechicero_desgastado.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var spell_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    # Load projectile scene safely if it exists
    var alt_paths = [
        "res://scenes/projectiles/basic_spell.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/ChaosProjectile.tscn",
        "res://scenes/effects/EnemyProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            spell_scene = load(p)
            break

func _physics_process(delta):
    if not player_reference:
        return
    kite_around_player(delta)
    attempt_cast(delta)

func kite_around_player(delta):
    var dir = (global_position - player_reference.global_position).normalized()
    global_position += dir * base_speed * delta

func attempt_cast(_delta):
    if randf() < 0.02:
        cast_spell()

func cast_spell():
    if spell_scene:
        var spell = spell_scene.instantiate()
        get_parent().add_child(spell)
        spell.global_position = global_position
        spell.direction = (player_reference.global_position - global_position).normalized()

func drop_xp(_amount: int):
    var xp_scene = preload("res://scenes/pickups/XPOrb.tscn")
    if xp_scene:
        var xp_orb = xp_scene.instantiate()
        get_parent().add_child(xp_orb)
        xp_orb.global_position = global_position

func take_damage(amount: int):
    current_hp -= amount
    if current_hp <= 0:
        _on_death()

func _on_death():
    drop_xp(calculate_scaled_xp())
    queue_free()

func calculate_scaled_hp() -> int:
    return int(round(base_hp * 1.12))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.08))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 2)
