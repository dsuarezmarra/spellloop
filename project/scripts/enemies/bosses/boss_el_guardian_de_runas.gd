extends Node2D

class_name BossElGuardianDeRunas
@export var boss_name = "El Guardián de Runas"
@export var slug = "boss_el_guardian_de_runas"
@export var base_hp = 2000
@export var base_damage = 130
@export var xp_drop = 1400
@export var sprite_path = "res://assets/sprites/enemies/bosses/el_guardian_de_runas.png"

var current_hp: int
var player_reference: Node
var rune_shard_scene: PackedScene = null

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = base_hp
    var path = "res://scenes/projectiles/rune_shard.tscn"
    if ResourceLoader.exists(path):
        rune_shard_scene = load(path)

func _physics_process(_delta):
    if not player_reference:
        return
    if randf() < 0.02:
        summon_rune_shards()

func summon_rune_shards():
    if rune_shard_scene:
        var proj = rune_shard_scene.instantiate()
        get_parent().add_child(proj)
        proj.global_position = global_position
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
