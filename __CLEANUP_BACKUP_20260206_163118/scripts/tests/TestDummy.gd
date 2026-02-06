extends EnemyBase
class_name TestDummy

var total_damage = 0.0
var attack_proj_timer = 0.0

func _ready() -> void:
    # Set stats suitable for a dummy
    max_hp = 9999999
    hp = 9999999
    speed = 0.0
    damage = 0 # Base collision damage is 0, we use projectiles
    enemy_tier = 1
    
    super._ready()
    
    # Ensure status icon display is ready (called in super._ready but good to be sure)
    if not status_icon_display:
        _initialize_status_icon_display()

func _physics_process(delta: float) -> void:
    # Override movement to stand still
    velocity = Vector2.ZERO
    
    # Handle status effects from base class
    _process_status_effects(delta)
    
    # Process projectile attack logic
    attack_proj_timer += delta
    if attack_proj_timer >= 1.0:
        attack_proj_timer = 0.0
        _shoot_projectile()

    # We do NOT call move_and_slide() to save physics processing and keep it static
    
func _shoot_projectile():
    var player = get_tree().get_first_node_in_group("player")
    if not player: return
    
    var proj = Area2D.new()
    proj.name = "EnemyProj"
    proj.position = global_position
    
    # Visual simple
    var vis = ColorRect.new()
    vis.color = Color.MAGENTA
    vis.size = Vector2(10, 10)
    vis.position = Vector2(-5, -5)
    proj.add_child(vis)
    
    # Colisión
    var col = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 6
    col.shape = shape
    proj.add_child(col)
    
    # Layer 4: Enemy Projectile
    proj.set_collision_layer_value(1, false)
    proj.set_collision_layer_value(4, true)
    
    # Mask 1: Player
    proj.set_collision_mask_value(1, true)
    
    # Script de movimiento y daño
    # IMPORTANT: We pass 'self' (the shooter) to take_damage if needed, 
    # but based on audit we know thorns on projectiles is ignored.
    # We still want standard projectile behavior.
    var ps = GDScript.new()
    ps.source_code = "extends Area2D\\n" + \
    "var dir = Vector2.ZERO\\n" + \
    "var speed = 250\\n" + \
    "var shooter = null\\n" + \
    "func _process(delta):\\n" + \
    "	position += dir * speed * delta\\n" + \
    "func _ready():\\n" + \
    "	body_entered.connect(_on_hit)\\n" + \
    "	get_tree().create_timer(4.0).timeout.connect(queue_free)\\n" + \
    "func _on_hit(body):\\n" + \
    "	if body.is_in_group('player'):\\n" + \
    "		if body.has_method('take_damage'):\\n" + \
    "			body.take_damage(500, 'physical', shooter)\\n" + \
    "		queue_free()"
    
    proj.set_script(ps)
    
    # Add to scene
    get_parent().add_child(proj)
    
    var script_inst = proj as Area2D
    if "shooter" in script_inst:
        script_inst.shooter = self
        
    if "dir" in script_inst:
        var dir = (player.global_position - global_position).normalized()
        script_inst.dir = dir

# Override take_damage to track total damage for checking
func take_damage(amount: int, type: String = "physical", attacker: Node = null) -> void:
    # Log damage for verification
    # print("[TestDummy] Took %d damage (%s)" % [amount, type])
    total_damage += amount
    super.take_damage(amount, type, attacker)
