# QuickCombatDebug.gd
# Script rápido para debuggear problema de proyectiles
# Añade acciones de debug al menú de entrada

# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: QuickCombatDebug.gd - Debug rápido para sistema de combate
# Razón: Cargado dinámicamente desde SpellloopGame pero es principalmente para debugging (presionar D/P/L)

extends Node

var debug_enabled: bool = false

func _ready() -> void:
	set_process_input(true)
	print("[QuickCombatDebug] Presiona 'F3' para debug, 'F4' para proyectil test, 'Shift+F5' para árbol")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F3:
				print_full_debug()
				var monitor = get_tree().root.get_node_or_null("SpellloopGame/UI/CombatSystemMonitor")
				if monitor and monitor.has_method("toggle"):
					monitor.toggle()
			KEY_F4:
				spawn_test_projectile()
			KEY_F5:
				if event.shift_pressed:
					list_scene_tree()

func print_full_debug() -> void:
	"""Imprimir debug completo del sistema de combate"""
	var sep = ""
	for i in range(60):
		sep += "="
	
	print("\n" + sep)
	print("🔍 QUICK DEBUG REPORT")
	print(sep)
	
	var gm = get_tree().root.get_node_or_null("GameManager")
	var sg = get_tree().root.get_node_or_null("SpellloopGame")
	var player = null
	
	if sg:
		player = sg.get_node_or_null("WorldRoot/Player")
		if not player:
			player = sg.get_node_or_null("Player")
	
	# 1. GameManager
	print("\n1. GameManager: ", "✓" if gm else "✗")
	if gm:
		print("   - is_run_active:", gm.is_run_active)
		print("   - player_ref:", "✓" if gm.player_ref else "✗")
		print("   - attack_manager:", "✓" if gm.attack_manager else "✗")
		if gm.attack_manager:
			print("   - attack_manager.player:", "✓" if gm.attack_manager.player else "✗")
			print("   - attack_manager.is_active:", gm.attack_manager.is_active)
			print("   - weapons count:", gm.attack_manager.get_weapon_count())
			
			if gm.attack_manager.get_weapon_count() > 0:
				for i in range(gm.attack_manager.get_weapon_count()):
					var w = gm.attack_manager.weapons[i]
					print("     Weapon[%d]: %s" % [i, w.name])
					print("       - id:", w.id)
					print("       - damage:", w.damage)
					print("       - cooldown:", "%.2f/%.2f" % [w.current_cooldown, w.base_cooldown])
					print("       - projectile_scene:", "✓" if w.projectile_scene else "✗")
					if w.has_method("is_ready_to_fire"):
						print("       - is_ready_to_fire():", w.is_ready_to_fire())
					print("       - is_active:", w.is_active)
	
	# 2. SpellloopGame
	print("\n2. SpellloopGame: ", "✓" if sg else "✗")
	
	# 3. Player
	print("\n3. Player: ", "✓" if player else "✗")
	if player:
		print("   - name:", player.name)
		print("   - position:", player.position)
		print("   - HealthComponent:", "✓" if player.has_node("HealthComponent") else "✗")
		if player.has_node("HealthComponent"):
			var hc = player.get_node("HealthComponent")
			if hc.has_method("get_current_health"):
				print("     - current_hp:", hc.get_current_health())
			if hc.has_property("max_health"):
				print("     - max_hp:", hc.max_health)
	
	# 4. Enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	print("\n4. Enemies: %d" % enemies.size())
	for i in range(min(3, enemies.size())):
		var e = enemies[i]
		print("   [%d] %s at %s" % [i, e.name, e.position])
	
	# 5. Projectiles
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	print("\n5. Projectiles: %d" % projectiles.size())
	if projectiles.size() > 0:
		for i in range(min(5, projectiles.size())):
			var p = projectiles[i]
			print("   [%d] %s at %s" % [i, p.name, p.position])
	
	var sep2 = ""
	for i in range(60):
		sep2 += "="
	print("\n" + sep2)

func spawn_test_projectile() -> void:
	"""Generar un proyectil de prueba desde el jugador"""
	var sg = get_tree().root.get_node_or_null("SpellloopGame")
	var player = null
	
	if sg:
		player = sg.get_node_or_null("WorldRoot/Player")
		if not player:
			player = sg.get_node_or_null("Player")
	
	if not player:
		print("[QuickDebug] ✗ Player not found")
		return
	
	# Intentar cargar ProjectileBase
	var proj_scene = load("res://scripts/entities/ProjectileBase.tscn")
	if not proj_scene:
		print("[QuickDebug] ✗ ProjectileBase.tscn no cargó")
		return
	
	var proj = proj_scene.instantiate()
	if not proj:
		print("[QuickDebug] ✗ No se pudo instanciar ProjectileBase")
		return
	
	# Configurar proyectil
	proj.global_position = player.global_position
	proj.direction = Vector2.RIGHT
	proj.speed = 300.0
	proj.damage = 10
	
	# Agregar a la escena
	if sg.has_node("WorldRoot"):
		sg.get_node("WorldRoot").add_child(proj)
	else:
		sg.add_child(proj)
	
	print("[QuickDebug] ✓ Proyectil de prueba creado en:", proj.global_position)

func list_scene_tree() -> void:
	"""Listar árbol de escena para debugging"""
	var sep = ""
	for i in range(60):
		sep += "="
	print("\n" + sep)
	print("📍 SCENE TREE")
	print(sep)
	_print_tree(get_tree().root, 0)
	print(sep)

func _print_tree(node: Node, depth: int) -> void:
	"""Imprimir árbol de forma recursiva"""
	if depth > 3:
		return
	
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	var node_type = node.get_class()
	print("%s%s (%s)" % [indent, node.name, node_type])
	
	for child in node.get_children():
		_print_tree(child, depth + 1)

func has_property(obj: Object, prop: String) -> bool:
	return obj.get_property_list().any(func(p): return p.name == prop)
