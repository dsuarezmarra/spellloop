extends Node2D

# Referencias
var player: CharacterBody2D
var ui_layer: CanvasLayer
var debug_panel: PanelContainer

# Configuración
# Estos se llenarán dinámicamente desde las bases de datos
var weapon_ids = []
var fusion_ids = []
var upgrade_ids = []
var is_running_test = false

func _ready():
	# 0. Asegurar Mouse Visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 1. Cargar IDs desde Bases de Datos
	_load_database_ids()
	
	# 2. Configurar Entorno
	setup_environment()
	
	# 3. Spawnear Player
	spawn_player()
	
	# 4. Crear UI de Debug
	_create_debug_ui()
	
	print("[TestGym] Iniciado. Usa el panel para probar TODO.")

func _load_database_ids():
	# Armas Base
	if "WEAPONS" in WeaponDatabase:
		for id in WeaponDatabase.WEAPONS:
			weapon_ids.append(id)
	weapon_ids.sort()
	
	# Fusiones
	if "FUSIONS" in WeaponDatabase:
		for id in WeaponDatabase.FUSIONS:
			fusion_ids.append(WeaponDatabase.FUSIONS[id].id)
	fusion_ids.sort()
	
	# Upgrades (Items)
	# PlayerUpgradeDatabase tiene varias constantes
	if "DEFENSIVE_UPGRADES" in PlayerUpgradeDatabase:
		for id in PlayerUpgradeDatabase.DEFENSIVE_UPGRADES: upgrade_ids.append(id)
	if "UTILITY_UPGRADES" in PlayerUpgradeDatabase:
		for id in PlayerUpgradeDatabase.UTILITY_UPGRADES: upgrade_ids.append(id)
	
	# Load PassiveDatabase IDs (Offensive Passives)
	if "PASSIVES" in PassiveDatabase:
		for id in PassiveDatabase.PASSIVES:
			if not id in upgrade_ids:
				upgrade_ids.append(id)
	if "OFFENSIVE_UPGRADES" in PlayerUpgradeDatabase:
		for id in PlayerUpgradeDatabase.OFFENSIVE_UPGRADES: upgrade_ids.append(id)
	
	if "CURSED_UPGRADES" in PlayerUpgradeDatabase:
		for id in PlayerUpgradeDatabase.CURSED_UPGRADES: upgrade_ids.append(id)
		
	if "UNIQUE_UPGRADES" in PlayerUpgradeDatabase:
		for id in PlayerUpgradeDatabase.UNIQUE_UPGRADES: upgrade_ids.append(id)
		
	upgrade_ids.sort()

func setup_environment():
	# Fondo simple
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15)
	bg.size = Vector2(5000, 5000)
	bg.position = Vector2(-2500, -2500)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

func spawn_player():
	var possible_paths = [
		"res://scenes/player/SpellloopPlayer.tscn",
		"res://scenes/entities/Player.tscn"
	]
	
	var player_scene = null
	for path in possible_paths:
		if ResourceLoader.exists(path):
			player_scene = load(path)
			break
			
	if player_scene:
		player = player_scene.instantiate()
		print("[TestGym] Player scene loaded successfully")
	else:
		printerr("[TestGym] Warn: No se encontró Player.tscn, creando dummy")
		player = CharacterBody2D.new()
		# ... (dummy fallback code omitted for brevity if unchanged, but safely keeping context) ...
		var sprite = Sprite2D.new()
		sprite.texture = PlaceholderTexture2D.new()
		sprite.scale = Vector2(20, 20)
		player.add_child(sprite)
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 10
		collision.shape = shape
		player.add_child(collision)
		if not player.has_node("AttackManager"):
			var am = AttackManager.new()
			am.name = "AttackManager"
			player.add_child(am)
			am.initialize(player)
		player.set_meta("stats", PlayerStats.new())
	
	# SUPER HP FOR TESTING
	if "max_hp" in player: player.max_hp = 10000
	if "hp" in player: player.hp = 10000
	
	player.position = Vector2(640, 360) 
	add_child(player)
	
	# CRITICAL FIX: Ensure Collision Shape exists
	var has_shape = false
	for c in player.get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			has_shape = true
			break
	
	if not has_shape:
		print("[TestGym] ⚠️ PLAYER HAS NO COLLISION SHAPE! Force-adding CircleShape2D...")
		var shape = CollisionShape2D.new()
		shape.name = "DebugCollisionShape"
		var circle = CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		shape.debug_color = Color(0.0, 1.0, 0.0, 0.5)
		player.add_child(shape)
	
	# Force update health component if exists
	if player.has_node("HealthComponent"):
		var hc = player.get_node("HealthComponent")
		if hc.has_method("initialize"): hc.initialize(10000)
	
	var am = _get_attack_manager()
	if am and not am.player:
		am.initialize(player)
	
	var cam = Camera2D.new()
	player.add_child(cam)
	cam.make_current()

func _create_debug_ui():
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 128
	add_child(ui_layer)
	
	debug_panel = PanelContainer.new()
	debug_panel.position = Vector2(20, 20)
	debug_panel.size = Vector2(300, 600) # Más alto para tabs
	ui_layer.add_child(debug_panel)
	
	var vbox = VBoxContainer.new()
	debug_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🧪 SUPER TEST GYM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Tabs
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)
	
	# Tab 1: Armas Base
	var weapons_scroll = ScrollContainer.new()
	weapons_scroll.name = "Weapons"
	var weapons_grid = GridContainer.new()
	weapons_grid.columns = 2
	weapons_scroll.add_child(weapons_grid)
	tabs.add_child(weapons_scroll)
	
	for wid in weapon_ids:
		var btn = Button.new()
		btn.text = "+ " + wid.capitalize()
		btn.pressed.connect(_on_add_weapon.bind(wid))
		weapons_grid.add_child(btn)
		
	# Tab 2: Fusiones
	var fusions_scroll = ScrollContainer.new()
	fusions_scroll.name = "Fusions"
	var fusions_grid = GridContainer.new()
	fusions_grid.columns = 1
	fusions_scroll.add_child(fusions_grid)
	tabs.add_child(fusions_scroll)
	
	for fid in fusion_ids:
		var btn = Button.new()
		btn.text = "⚡ " + fid.capitalize()
		btn.pressed.connect(_on_add_weapon.bind(fid)) # AttackManager maneja fusiones como armas normales
		fusions_grid.add_child(btn)

	# Tab 3: Items (Upgrades)
	var items_scroll = ScrollContainer.new()
	items_scroll.name = "Items"
	var items_grid = GridContainer.new()
	items_grid.columns = 2
	items_scroll.add_child(items_grid)
	tabs.add_child(items_scroll)
	
	for uid in upgrade_ids:
		var btn = Button.new()
		var data = _get_upgrade_data(uid)
		var icon = data.get("icon", "📦")
		btn.text = icon + " " + data.get("name", uid)
		btn.tooltip_text = data.get("description", "")
		btn.pressed.connect(_on_add_upgrade.bind(uid))
		items_grid.add_child(btn)
		
	# Tab 4: Utils
	var utils_vbox = VBoxContainer.new()
	utils_vbox.name = "Utils"
	tabs.add_child(utils_vbox)
	
	var btn_dummy = Button.new()
	btn_dummy.text = "Spawn Dummy Target"
	btn_dummy.pressed.connect(_spawn_dummy)
	utils_vbox.add_child(btn_dummy)
	
	var btn_clear = Button.new()
	btn_clear.text = "🗑️ CLEAR ALL WEAPONS"
	btn_clear.modulate = Color(1, 0.5, 0.5)
	btn_clear.pressed.connect(_clear_weapons)
	utils_vbox.add_child(btn_clear)
	
	var btn_heal = Button.new()
	btn_heal.text = "Heal Player"
	btn_heal.pressed.connect(func(): if player.has_method("heal"): player.heal(100))
	utils_vbox.add_child(btn_heal)

	var btn_auto = Button.new()
	btn_auto.text = "▶ RUN AUTO-TEST"
	btn_auto.modulate = Color(0.5, 1, 0.5)
	btn_auto.pressed.connect(_run_auto_test_sequence)
	utils_vbox.add_child(btn_auto)
	
	var btn_inc = Button.new()
	btn_inc.text = "▶ RUN INC. TEST"
	btn_inc.modulate = Color(0.5, 0.5, 1)
	btn_inc.pressed.connect(_run_incremental_test)
	utils_vbox.add_child(btn_inc)

	# Tab 5: Solo Tests
	var solo_scroll = ScrollContainer.new()
	solo_scroll.name = "Solo Tests"
	var solo_grid = GridContainer.new()
	solo_grid.columns = 1
	solo_scroll.add_child(solo_grid)
	tabs.add_child(solo_scroll)

	for wid in weapon_ids:
		var btn = Button.new()
		btn.text = "🧪 Test Full Cycle: " + wid
		btn.pressed.connect(_run_full_cycle_test.bind(wid))
		solo_grid.add_child(btn)
	
	for fid in fusion_ids:
		var btn = Button.new()
		btn.text = "🧪 Test Full Cycle: " + fid
		btn.pressed.connect(_run_full_cycle_test.bind(fid))
		solo_grid.add_child(btn)

func _run_full_cycle_test(weapon_id: String):
	if is_running_test: return
	is_running_test = true
	
	_show_toast("🚀 FULL CYCLE: " + weapon_id)
	print("\n🚀 INICIANDO TEST CICLO COMPLETO: " + weapon_id)
	print("📋 Total Upgrades a aplicar: ", upgrade_ids.size())
	
	# 1. Setup Environment
	_clear_weapons()
	get_tree().call_group("enemies", "queue_free")
	await get_tree().create_timer(0.2).timeout
	_spawn_dummy()
	
	# 2. Add Target Weapon
	_on_add_weapon(weapon_id)
	
	# 3. Clean Utils
	var am = _get_attack_manager()
	if am and am.global_weapon_stats: am.global_weapon_stats.reset()
	
	# 4. Loop Logic
	var count = 0
	var total = upgrade_ids.size()
	
	# Base Stats
	print("   📊 Stats Base:")
	_print_stats_report()
	
	for uid in upgrade_ids:
		count += 1
		var u_data = _get_upgrade_data(uid)
		var u_name = u_data.get("name", uid)
		
		print("\n   ➕ [%d/%d] Adding: %s (%s)" % [count, total, u_name, uid])
		_show_toast("[%d/%d] +%s" % [count, total, u_name])
		
		# Apply Upgrade
		_on_add_upgrade(uid)
		
		# Wait 1s and Log
		var dummy = get_tree().get_first_node_in_group("enemies")
		
		# Measure Player Health
		var p_start_hp = 0
		if player and player.get("health_component"):
			p_start_hp = player.health_component.current_health
		elif player and "hp" in player:
			p_start_hp = player.hp
			
		if is_instance_valid(dummy):
			var start_dmg = dummy.get("total_damage")
			if start_dmg == null: start_dmg = 0
			
			await get_tree().create_timer(1.0).timeout
			
			if is_instance_valid(dummy):
				var end_dmg = dummy.get("total_damage")
				if end_dmg == null: end_dmg = 0
				var dps = end_dmg - start_dmg
				
				# Calc Player Dmg
				var p_end_hp = 0
				if player and player.get("health_component"):
					p_end_hp = player.health_component.current_health
				elif player and "hp" in player:
					p_end_hp = player.hp
				
				var p_dmg_taken = p_start_hp - p_end_hp
				
				print("      💥 DPS (1s): %d | 🛡️ Player Hit Dmg: %d" % [dps, p_dmg_taken])
			else:
				print("      ❌ Dummy Lost")
				break
		else:
			print("      ❌ No Dummy")
			break
			
	print("\n✅✅ CICLO COMPLETO FINALIZADO PARA: " + weapon_id)
	_show_toast("✅ TEST FINISHED: " + weapon_id)
	is_running_test = false

func _run_incremental_test():
	if is_running_test: return
	is_running_test = true
	
	_show_toast("🚀 STARTING INCREMENTAL TEST 🚀")
	print("\n🚀 INICIANDO TEST INCREMENTAL DE MEJORAS 🚀")
	
	var all_weapons = weapon_ids + fusion_ids
	var total_weapons = all_weapons.size()
	print("📋 Armas a testear: ", total_weapons)
	
	for i in range(total_weapons):
		var weapon_id = all_weapons[i]
		print("\n🔹 WEAPON %d/%d: %s" % [i+1, total_weapons, weapon_id])
		
		# Limpiar todo
		_clear_weapons()
		# Limpiar enemigos
		get_tree().call_group("enemies", "queue_free")
		await get_tree().create_timer(0.1).timeout
		
		# Spawn dummy fresco
		_spawn_dummy()
		
		# Añadir arma
		_on_add_weapon(weapon_id)
		
		# Resetear stats globales para empezar limpio
		var am = _get_attack_manager()
		if am and "global_weapon_stats" in am and am.global_weapon_stats:
			am.global_weapon_stats.reset()
		
		# Secuencia de pasos
		var steps = [
			{"name": "BASE", "upgrade": ""},
			{"name": "+DAMAGE", "upgrade": "damage_1"},
			{"name": "+CRIT", "upgrade": "crit_chance_1"},
			{"name": "+SPEED", "upgrade": "attack_speed_1"},
			{"name": "+AREA", "upgrade": "area_1"},
			{"name": "+PROJ SPEED", "upgrade": "projectile_speed_1"},
			{"name": "+EXTRA PROJ", "upgrade": "extra_projectiles_1"},
		]
		
		for step in steps:
			if step.upgrade != "":
				_on_add_upgrade(step.upgrade) # Usamos _on_add_upgrade para log visual también
				await get_tree().create_timer(0.2).timeout # Pequeña pausa para aplicar
			
			await _measure_step(step.name)
		
		await get_tree().create_timer(0.5).timeout
	
	_show_toast("✅ INCREMENTAL TEST COMPLETED")
	print("\n✅ TEST INCREMENTAL FINALIZADO")
	is_running_test = false

func _measure_step(step_name: String):
	print("   👉 Estado: %s" % step_name)
	
	var dummy = get_tree().get_first_node_in_group("enemies")
	if not is_instance_valid(dummy):
		print("      ❌ Error: No dummy found")
		return
	
	# Imprimir stats actuales (usando helper existente)
	_print_stats_report() 
	
	# Medir daño
	var start_damage = 0
	if dummy.get("total_damage") != null:
		start_damage = dummy.get("total_damage")
		
	print("      ⏱️ Midiendo 2s...")
	await get_tree().create_timer(2.0).timeout
	
	if not is_instance_valid(dummy):
		print("      ❌ Error: Dummy died or lost")
		return

	var end_damage = 0
	if dummy.get("total_damage") != null:
		end_damage = dummy.get("total_damage")
	
	var damage_diff = end_damage - start_damage
	var dps = damage_diff / 2.0
	print("      💥 DPS: %.1f (Total en 2s: %d)" % [dps, damage_diff])

# --- Helpers ---

func _get_attack_manager():
	var am = player.get_node_or_null("AttackManager")
	if am: return am
	if get_tree().root.has_node("GameManager"):
		var gm = get_tree().root.get_node("GameManager")
		if gm.attack_manager: return gm.attack_manager
	return null

func _get_player_stats():
	# Buscar stats en metadata o variable global
	if player.has_meta("stats"):
		return player.get_meta("stats")
	# Alternativa: Global stats si es Singleton (PlayerStats suele ser instanciado, no singleton)
	# Si GameManager tiene referencia:
	if get_tree().root.has_node("GameManager"):
		var gm = get_tree().root.get_node("GameManager")
		if "player_stats" in gm: return gm.player_stats
	return null

func _get_upgrade_data(id: String) -> Dictionary:
	if id in PlayerUpgradeDatabase.DEFENSIVE_UPGRADES: return PlayerUpgradeDatabase.DEFENSIVE_UPGRADES[id]
	if id in PlayerUpgradeDatabase.UTILITY_UPGRADES: return PlayerUpgradeDatabase.UTILITY_UPGRADES[id]
	if id in PlayerUpgradeDatabase.OFFENSIVE_UPGRADES: return PlayerUpgradeDatabase.OFFENSIVE_UPGRADES[id]
	if "CURSED_UPGRADES" in PlayerUpgradeDatabase and id in PlayerUpgradeDatabase.CURSED_UPGRADES: return PlayerUpgradeDatabase.CURSED_UPGRADES[id]
	if "UNIQUE_UPGRADES" in PlayerUpgradeDatabase and id in PlayerUpgradeDatabase.UNIQUE_UPGRADES: return PlayerUpgradeDatabase.UNIQUE_UPGRADES[id]
	if "PASSIVES" in PassiveDatabase and id in PassiveDatabase.PASSIVES: return PassiveDatabase.PASSIVES[id]
	return {}

# --- Acciones ---

func _on_add_weapon(id: String):
	print("[TestGym] Adding weapon/fusion: ", id)
	var am = _get_attack_manager()
	if am and am.has_method("add_weapon_by_id"):
		if am.add_weapon_by_id(id):
			_show_toast("Added: " + id)
		else:
			_show_toast("Failed: " + id)
	else:
		printerr("[TestGym] No AttackManager found")



func _spawn_dummy():
	var dummy = Node2D.new()
	dummy.name = "DummyTarget"
	var sprite = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	sprite.texture = ImageTexture.create_from_image(img)
	dummy.add_child(sprite)
	dummy.add_to_group("enemies")
	
	# POSICIÓN FIJA: A la derecha del player para asegurar hit
	dummy.position = player.position + Vector2(150, 0)
	
	var area = Area2D.new()
	# IMPORTANTE: Layer 2 para enemigos (según SimpleProjectile)
	area.set_collision_layer_value(2, true)
	area.set_collision_mask_value(4, true) # Escuchar proyectiles de layer 4 (opcional para area)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	col.shape = shape
	area.add_child(col)
	dummy.add_child(area)
	
	var script = GDScript.new()
	script.source_code = """
extends Node2D
var health = 999999
var total_damage = 0
var attack_timer = 0.0

func _process(delta):
	# Ataque automático cada 1 segundo
	attack_timer += delta
	if attack_timer >= 1.0:
		attack_timer = 0.0
		_shoot_projectile()

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
	var ps = GDScript.new()
	ps.source_code = "extends Area2D\\n" + \
	"var dir = Vector2.ZERO\\n" + \
	"var speed = 250\\n" + \
	"func _process(delta):\\n" + \
	"	position += dir * speed * delta\\n" + \
	"func _ready():\\n" + \
	"	body_entered.connect(_on_hit)\\n" + \
	"	get_tree().create_timer(4.0).timeout.connect(queue_free)\\n" + \
	"func _on_hit(body):\\n" + \
	"	print('PROJ HIT: ', body.name, ' | Groups: ', body.get_groups())\\n" + \
	"	if body.is_in_group('player'):\\n" + \
	"		print('🎯 ENEMY PROJ HIT PLAYER!')\\n" + \
	"		if body.has_method('take_damage'):\\n" + \
	"			body.take_damage(10, 'physical', self)\\n" + \
	"		queue_free()"
	
	ps.reload()
	proj.set_script(ps)
	
	# DEBUG PLAYER COLLISION
	if player:
		print("🔍 PLAYER COLLISION CHECK:")
		print("   Layer: %d (Bit 1: %s)" % [player.collision_layer, player.get_collision_layer_value(1)])
		print("   Mask:  %d (Bit 4: %s)" % [player.collision_mask, player.get_collision_mask_value(4)])
		var has_shape = false
		for c in player.get_children():
			if c is CollisionShape2D or c is CollisionPolygon2D:
				has_shape = true
				print("   Found Shape: ", c.name)
		if not has_shape:
			print("   ⚠️ NO COLLISION SHAPE FOUND ON PLAYER!")
	
	# Calcular dirección hacia el player
	var dir = (player.global_position - global_position).normalized()
	proj.set("dir", dir)
	
	get_parent().add_child(proj)

func take_damage(data, _source=null):
	var amount = 0
	if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
		amount = data
	elif typeof(data) == TYPE_DICTIONARY and data.has("amount"):
		amount = data.amount
	elif typeof(data) == TYPE_OBJECT and data.has_method("get_amount"):
		amount = data.get_amount()
	elif typeof(data) == TYPE_OBJECT and "amount" in data:
		amount = data.amount
	elif typeof(data) == TYPE_OBJECT and "damage" in data:
		amount = data.damage
	
	total_damage += amount
	
	# Efecto visual
	var label = Label.new()
	label.text = str(int(amount))
	label.modulate = Color(1, 0.3, 0.3)
	label.z_index = 100
	label.position = Vector2(randf_range(-10, 10), randf_range(-20, -40))
	add_child(label)
	
	# Animar
	var tw = create_tween()
	tw.tween_property(label, "position", label.position + Vector2(0, -30), 0.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).from(1.0)
	tw.tween_callback(label.queue_free)
	"""
	script.reload() # IMPORTANT: Compile the script
	dummy.set_script(script)
	add_child(dummy)
	_show_toast("Dummy Spawned (Fixed Pos)")

func _clear_weapons():
	var am = _get_attack_manager()
	if am and "weapons" in am:
		am.weapons.clear()
		am.current_weapon_count = 0 
		if "weapon_stats_map" in am:
			am.weapon_stats_map.clear()
		
		# Resetear GlobalWeaponStats también
		if am.global_weapon_stats:
			am.global_weapon_stats.reset()
		
	# CLEANUP AGRESIVO DE PROYECTILES/ORBITALES
	# print("[TestGym] Cleaning up logic entities...")
	get_tree().call_group("projectiles", "queue_free")
	
	var root = get_tree().current_scene
	for child in root.get_children():
		if child.has_method("despawn"): 
			child.despawn()
		elif "projectile" in child.name.to_lower() or "orb" in child.name.to_lower():
			child.queue_free()
			
	for child in player.get_children():
		if child.name.contains("Orb") or child.name.contains("Barrier") or child.name.contains("Shield"):
			child.queue_free()
			
	# _show_toast("Weapons Cleared & Cleaned")

func _process(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _show_toast(msg: String):
	var label = Label.new()
	label.text = msg
	label.position = Vector2(player.position.x - 50, player.position.y - 120)
	label.z_index = 200
	label.modulate = Color(1.0, 1.0, 0.0) # Yellow
	add_child(label)
	var tw = create_tween()
	tw.tween_property(label, "position", Vector2(label.position.x, label.position.y - 80), 1.5)
	tw.tween_property(label, "modulate:a", 0.0, 1.5)
	tw.tween_callback(label.queue_free)

func _run_auto_test_sequence():
	_run_complex_test()

func _run_complex_test() -> void:
	print("🚀 INICIANDO SUPER MEGA AUTO-TEST 🚀")
	_show_toast("🚀 STARTING COMPLEX TEST 🚀")
	
	var dummy = null
	if not get_tree().has_group("enemies"):
		_spawn_dummy()
	
	# Esperar a que dummy exista
	await get_tree().process_frame
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		dummy = enemies[0]
	
	var all_weapons = weapon_ids + fusion_ids
	var batch_size = 6
	var batches = []
	
	var current_batch = []
	for wid in all_weapons:
		current_batch.append(wid)
		if current_batch.size() >= batch_size:
			batches.append(current_batch.duplicate())
			current_batch.clear()
	if not current_batch.is_empty():
		batches.append(current_batch)
		
	print("📋 Total Batches: %d" % batches.size())
	
	for i in range(batches.size()):
		var batch = batches[i]
		print("\n🔹 BATCH %d/%d: %s" % [i+1, batches.size(), batch])
		_show_toast("Testing Batch %d/%d" % [i+1, batches.size()])
		
		_clear_weapons()
		await get_tree().create_timer(0.2).timeout
		
		# --- BASELINE REPORT ---
		print("   📊 Stats Base (Pre-Upgrades):")
		_print_stats_report()
		
		for wid in batch:
			_on_add_weapon(wid)
		
		await get_tree().create_timer(0.2).timeout
			
		print("   🔼 Aplicando ALL Upgrades...")
		_show_toast("Applying Upgrades...")
		
		for uid in upgrade_ids:
			_apply_upgrade_silent(uid)
		
		# --- UPGRADED REPORT ---
		print("   📊 Stats Mejorados (Post-Upgrades):")
		_print_stats_report()
		
		# Reset damage tracking for this batch
		var initial_dmg = 0
		if is_instance_valid(dummy):
			initial_dmg = dummy.get("total_damage")
			if initial_dmg == null: initial_dmg = 0
		
		print("   ⚔️ Midiendo daño (3s)...")
		_show_toast("Measuring Damage...")
		
		await get_tree().create_timer(3.0).timeout
		
		if is_instance_valid(dummy):
			var final_dmg = dummy.get("total_damage")
			if final_dmg == null: final_dmg = 0
			var batch_dmg = final_dmg - initial_dmg
			print("   💥 BATCH TOTAL DAMAGE: %d" % batch_dmg)
			_show_toast("Batch Dmg: %d" % batch_dmg)
		else:
			print("   ❌ Dummy lost!")
		
	print("\n✅✅✅ TEST COMPLETO: Todas las combinaciones probadas ✅✅✅")
	_show_toast("✅✅✅ TEST COMPLETE ✅✅✅")

func _print_stats_report():
	var am = _get_attack_manager()
	if am and am.global_weapon_stats:
		var gws = am.global_weapon_stats
		print("      > Dmg Mult: x%.2f" % gws.get_stat("damage_mult"))
		print("      > Speed Mult: x%.2f" % gws.get_stat("projectile_speed_mult"))
		print("      > Area Mult: x%.2f" % gws.get_stat("area_mult"))
		print("      > Extra Proj: +%d" % gws.get_stat("extra_projectiles"))
		print("      > Crit Chance: %.0f%%" % (gws.get_stat("crit_chance") * 100))

# Stats que pertenecen a GlobalWeaponStats
const WEAPON_STATS = [
	"damage_mult", "attack_speed_mult", "crit_chance", "crit_damage",
	"area_mult", "projectile_speed_mult", "duration_mult", "knockback_mult",
	"extra_projectiles", "extra_pierce", "damage_flat", "cooldown_mult"
]

func _apply_stat_change(stat: String, val: float, op: String, silent: bool = false):
	# Determinar destino
	var target_obj = null
	var is_weapon_stat = stat in WEAPON_STATS
	
	if is_weapon_stat:
		var am = _get_attack_manager()
		if am and am.global_weapon_stats:
			target_obj = am.global_weapon_stats
	else:
		target_obj = _get_player_stats()
		
	if not target_obj: return
	
	# Aplicar cambio
	if op == "add":
		if target_obj.has_method("add_stat"):
			target_obj.add_stat(stat, val)
	elif op == "multiply":
		if target_obj.has_method("multiply_stat"):
			target_obj.multiply_stat(stat, val)
			
	# if not silent:
	#	print("[TestGym] Stat '%s' %s %.2f applied" % [stat, op, val])

func _apply_upgrade_silent(id: String):
	var data = _get_upgrade_data(id)
	if data.is_empty(): return
	if "effects" in data:
		for effect in data.effects:
			_apply_stat_change(effect.stat, effect.value, effect.operation, true)

func _on_add_upgrade(id: String):
	print("[TestGym] Adding upgrade: ", id)
	var data = _get_upgrade_data(id)
	if data.is_empty():
		_show_toast("Error: Unknown Upgrade")
		return
	if "effects" in data:
		for effect in data.effects:
			_apply_stat_change(effect.stat, effect.value, effect.operation, false)
	_show_toast("Upgrade Added: " + data.get("name", id))
