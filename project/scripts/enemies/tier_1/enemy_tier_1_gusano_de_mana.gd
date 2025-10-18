extends Node2D

class_name EnemyTier1GusanoDeMana
@export var enemy_name = "Gusano de Mana"
@export var slug = "enemy_tier_1_gusano_de_mana"
@export var difficulty_tier = 1
@export var base_hp = 20
@export var base_speed = 35.0
@export var base_damage = 5
@export var xp_drop = 2
@export var size_px = 48
@export var collider_radius = 18.0
@export var attack_type = "melee"
@export var attack_rate = 1.8
@export var movement_behavior = "burrow"
@export var sprite_path = "res://assets/sprites/enemies/tier_1/gusano_de_mana.png"
@export var is_special_variant = false

var current_hp: int
var player_reference: Node
var attack_timer: float = 0.0
var scale_manager: Node

func _ready():
    if has_node("Sprite"):
        $Sprite.texture = load(sprite_path)
    scale_manager = null
    if get_tree() and get_tree().root and get_tree().root.has_node("ScaleManager"):
        scale_manager = get_tree().root.get_node("ScaleManager")
    player_reference = get_tree().get_first_node_in_group("player")
    current_hp = calculate_scaled_hp()
    if has_node("CollisionShape2D"):
        var shape = CircleShape2D.new()
        shape.radius = collider_radius * scale_manager.current_scale
        $CollisionShape2D.shape = shape

func _physics_process(delta):
    if not player_reference:
        return
    # Movimiento: emerge y ataca cuerpo a cuerpo
    var dir = (player_reference.global_position - global_position).normalized()
    global_position += dir * base_speed * scale_manager.current_scale * delta

func take_damage(amount: int):
    current_hp -= amount
    modulate = Color.RED
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.2)
    if current_hp <= 0:
        _on_death()

func _on_death():
    drop_xp(calculate_scaled_xp())
    maybe_drop_item()
    queue_free()

func drop_xp(_amount: int):
    var xp_scene = preload("res://scenes/pickups/XPOrb.tscn")
    if xp_scene:
        var xp_orb = xp_scene.instantiate()
        get_parent().add_child(xp_orb)
        xp_orb.global_position = global_position
        xp_orb.xp_value = _amount

func maybe_drop_item():
    var drop_chance = 0.03
    if is_special_variant:
        drop_chance = 1.0
    if randf() < drop_chance:
        var item_manager = null
        if get_tree() and get_tree().root and get_tree().root.has_node("ItemManager"):
            item_manager = get_tree().root.get_node("ItemManager")
        if item_manager and item_manager.has_method("spawn_item_drop"):
            var rarity = 0  # ItemsDefinitions.ItemRarity.WHITE
            if is_special_variant:
                rarity = 1  # ItemsDefinitions.ItemRarity.BLUE
            item_manager.spawn_item_drop(global_position, rarity)

func calculate_scaled_hp() -> int:
    var game_manager = null
    if get_tree() and get_tree().root and get_tree().root.has_node("GameManager"):
        game_manager = get_tree().root.get_node("GameManager")
    var minutes_elapsed = 0
    if game_manager and game_manager.has_method("get_elapsed_minutes"):
        minutes_elapsed = game_manager.get_elapsed_minutes()
    var hp = base_hp * (1 + 0.12 * minutes_elapsed) * (1 + 0.25 * (difficulty_tier - 1))
    return int(round(hp))

func calculate_scaled_damage() -> int:
    var game_manager = null
    if get_tree() and get_tree().root and get_tree().root.has_node("GameManager"):
        game_manager = get_tree().root.get_node("GameManager")
    var minutes_elapsed = 0
    if game_manager and game_manager.has_method("get_elapsed_minutes"):
        minutes_elapsed = game_manager.get_elapsed_minutes()
    var damage = base_damage * (1 + 0.09 * minutes_elapsed)
    return int(round(damage))

func calculate_scaled_xp() -> int:
    return xp_drop + int(difficulty_tier * 1)
