extends Node2D

class_name EnemyTier3SerpienteDeFuego
@export var enemy_name = "Serpiente de Fuego"
@export var slug = "enemy_tier_3_serpiente_de_fuego"
@export var difficulty_tier = 3
@export var base_hp = 150
@export var base_speed = 88.0
@export var base_damage = 30
@export var xp_drop = 26
@export var size_px = 100
@export var collider_radius = 46.0
@export var attack_type = "ranged"
@export var attack_rate = 1.1
@export var movement_behavior = "serpentine"
@export var sprite_path = "res://assets/sprites/enemies/tier_3/serpiente_de_fuego.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var fire_spit_scene: PackedScene = null
var _tick_counter: float = 0.0

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    var alt_paths = [
        "res://scenes/projectiles/fire_spit.tscn",
        "res://scenes/enemies/EnemyProjectile.tscn",
        "res://scenes/bosses/ChaosProjectile.tscn"
    ]
    for p in alt_paths:
        if ResourceLoader.exists(p):
            fire_spit_scene = load(p)
            break

func _physics_process(delta):
    if not player_reference:
        return
    serpentine_move(delta)
    if randf() < 0.02:
        spit_fire()

func serpentine_move(delta):
    var dir = (player_reference.global_position - global_position).normalized()
    _tick_counter += delta
    var lateral = Vector2(-dir.y, dir.x) * sin(_tick_counter * 3.33)
    global_position += (dir + lateral * 0.25) * base_speed * delta

func spit_fire():
    if fire_spit_scene:
        var proj = fire_spit_scene.instantiate()
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
    return int(round(base_hp * 1.2))

func calculate_scaled_damage() -> int:
    return int(round(base_damage * 1.15))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 3)
