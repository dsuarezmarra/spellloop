extends Node2D
class_name SimpleProjectileAudit

# AUDIT SAFE V3 - TEMP FILE

@export var damage: int = 10
@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var knockback_force: float = 150.0
@export var pierce_count: int = 0
@export var hit_vfx_scene: PackedScene
@export var element_type: String = "ice"

var start_pos: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var current_lifetime: float = 0.0
var enemies_hit: Array[Node] = []
var pierces_remaining: int = 0

var _player: Node = null
var _player_stats: Node = null

const ELEMENT_COLORS = { "ice": Color.BLUE }

func _trace(msg):
	var f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_string("PROJ: " + msg + "\n")
		f.close()

func _ready() -> void: pass

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
    current_lifetime += delta
    if current_lifetime >= lifetime: queue_free()

func configure_and_launch(data: Dictionary, start_pos_: Vector2, target_vec: Vector2, is_direction: bool = true) -> void:
    damage = int(data.get("damage", 10))
    speed = data.get("speed", 400.0)
    lifetime = data.get("range", 300.0) / maxf(speed, 1.0)
    knockback_force = data.get("knockback", 150.0)
    pierce_count = data.get("pierce", 0)
    pierces_remaining = pierce_count
    
    element_type = "ice"
        
    set_meta("effect", data.get("effect", "none"))
    set_meta("effect_value", data.get("effect_value", 0.0))
    set_meta("effect_duration", data.get("effect_duration", 0.0))
    set_meta("crit_chance", data.get("crit_chance", 0.0))
    set_meta("crit_damage", data.get("crit_damage", 2.0))
    set_meta("weapon_id", data.get("weapon_id", ""))
    
    global_position = start_pos_
    if is_direction: direction = target_vec
    else: direction = (target_vec - start_pos_).normalized()
        
    current_lifetime = 0.0
    enemies_hit.clear()
    set_process(true)

func _handle_hit(target):
    _trace("Handle Hit Start. Target: " + str(target))
    enemies_hit.append(target)
    
    if not is_instance_valid(_player): _player = _get_player()
    
    var final_damage = float(damage)
    _trace("Base Damage: " + str(final_damage))
    
    # Bypass player stats for basic audit
    
    # Apply Damage
    var applied = false
    var has_method = target.has_method("take_damage")
    _trace("Target has take_damage? " + str(has_method))
    
    if has_method:
        target.take_damage(int(final_damage))
        applied = true
        _trace("Called take_damage")
    elif target.has_node("HealthComponent"):
        target.get_node("HealthComponent").take_damage(int(final_damage), "physical")
        applied = true
        _trace("Called HC take_damage")
        
    if applied:
        pass

    # Knockback
    var final_knockback = knockback_force
    if get_meta("effect") == "knockback_bonus": final_knockback *= get_meta("effect_value", 0.0)
    if final_knockback > 0 and target.has_method("apply_knockback"):
        target.apply_knockback(direction * final_knockback)
        
    _apply_effect(target)
    # emit_signal("hit_enemy", target, final_damage) # Signal call
    
    if pierces_remaining > 0: pierces_remaining -= 1
    else: queue_free()
    _trace("Handle Hit Done")

func _apply_effect(target: Node) -> void:
    var effect = get_meta("effect", "none")
    var val = get_meta("effect_value", 0.0)
    var dur = get_meta("effect_duration", 0.0)
    if effect == "none": return
    
    match effect:
        "slow": if target.has_method("apply_slow"): target.apply_slow(val, dur)
        "burn": if target.has_method("apply_burn"): target.apply_burn(val, dur)
        "freeze": if target.has_method("apply_freeze"): target.apply_freeze(val, dur)
        "chain": _apply_chain_damage(target, roundi(val))

func _apply_chain_damage(first_target: Node, chain_count: int) -> void:
    var enemies_hit = [first_target]
    var current_pos = first_target.global_position
    var chain_damage = damage * 0.6 
    
    for i in range(chain_count):
        var next_target = _find_chain_target(current_pos, enemies_hit)
        if next_target == null: break
        if next_target.has_method("take_damage"): next_target.take_damage(int(chain_damage))
        current_pos = next_target.global_position
        enemies_hit.append(next_target)

func _find_chain_target(pos: Vector2, exclude_list: Array) -> Node:
    var range_radius = 200.0
    var best_target = null
    var best_dist = range_radius * range_radius
    var candidates = get_tree().get_nodes_in_group("enemies")
    for enemy in candidates:
        if enemy in exclude_list or not is_instance_valid(enemy): continue
        var d = pos.distance_squared_to(enemy.global_position)
        if d < best_dist: best_dist = d; best_target = enemy
    return best_target

func _get_player() -> Node:
    if is_instance_valid(_player): return _player
    if get_tree():
        var p = get_tree().get_first_node_in_group("player")
        if p: _player = p; return p
    return null
