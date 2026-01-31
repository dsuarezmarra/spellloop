extends SceneTree

# Performance Stress Test
# Spawns 200 projectiles to verify pool degradation and lack of crashes.

func _init():
    var timer = Timer.new()
    timer.wait_time = 0.5
    timer.one_shot = false
    timer.timeout.connect(_on_timer)
    root.add_child(timer)
    timer.start()
    print("Starting Stress Test...")

func _on_timer():
    var pool_node = get_tree().root.get_node_or_null("ProjectilePool")
    # If using main loop manually, autoloads might differ. 
    # Let's try to find it or load it.
    if not pool_node:
        # Manually load logic for test isolation
        # This is tricky because ProjectilePool expects to be a singleton.
        print("ProjectilePool autoload not found. This test requires full engine run or mocking.")
        quit()
        return

    print("Pool Stats: ", pool_node.get_stats())
    
    # Simulate high load
    for i in range(50):
        var p = pool_node.get_projectile()
        if p:
             # Basic setup to mimic gameplay
            p.global_position = Vector2(randf()*1000, randf()*1000)
            p.direction = Vector2.RIGHT.rotated(randf() * TAU)
            p.speed = 300
            p.lifetime = 2.0
            root.add_child(p)
            p.set_process(true) # Ensure process is on if it was off
            p.set_physics_process(true)
    
    if pool.get_stats().total_created > 300:
        print("Stress test saturated. Quitting.")
        quit()
