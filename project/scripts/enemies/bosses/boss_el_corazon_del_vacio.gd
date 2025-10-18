extends Node2D

class_name BossElCorazonDelVacio
@export var boss_name = "El Corazón del Vacío"
@export var slug = "boss_el_corazon_del_vacio"
@export var base_hp = 2200
@export var base_damage = 140
@export var xp_drop = 1500
@export var sprite_path = "res://assets/sprites/enemies/bosses/el_corazon_del_vacio.png"

var current_hp: int
var player_reference: Node
var void_pulse_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = base_hp
    var path = "res://scenes/projectiles/void_pulse.tscn"
    if ResourceLoader.exists(path):
        void_pulse_scene = load(path)

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.025:
        pulse_void_energy()

func pulse_void_energy():
    if void_pulse_scene:
        var proj = void_pulse_scene.instantiate()
        get_parent().add_child(proj)
        proj.global_position = global_position
        proj.direction = (player_reference.global_position - global_position).normalized()
        proj.damage = base_damage

func take_damage(amount: int):
    current_hp -= amount
    if current_hp <= 0:
        _on_defeat()

func _on_defeat():
    drop_xp(xp_drop)
    queue_free()

func drop_xp(_amount: int):
    var xp_scene = preload("res://scenes/pickups/XPOrb.tscn")
    if xp_scene:
        var xp_orb = xp_scene.instantiate()
        get_parent().add_child(xp_orb)
        xp_orb.global_position = global_position

func calculate_scaled_hp() -> int:
    return base_hp

func calculate_scaled_damage() -> int:
    return base_damage

func calculate_scaled_xp() -> int:
    return xp_drop
