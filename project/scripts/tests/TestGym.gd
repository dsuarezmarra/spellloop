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
	create_debug_ui()
	
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
	if "OFFENSIVE_UPGRADES" in PlayerUpgradeDatabase:
		for id in PlayerUpgradeDatabase.OFFENSIVE_UPGRADES: upgrade_ids.append(id)
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
	
	player.position = Vector2(640, 360) 
	add_child(player)
	
	var am = _get_attack_manager()
	if am and not am.player:
		am.initialize(player)
	
	var cam = Camera2D.new()
	player.add_child(cam)
	cam.make_current()

func create_debug_ui():
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

func _on_add_upgrade(id: String):
	print("[TestGym] Adding upgrade: ", id)
	var stats = _get_player_stats()
	var data = _get_upgrade_data(id)
	
	if not stats:
		_show_toast("Error: No PlayerStats found")
		return
		
	if data.is_empty():
		_show_toast("Error: Unknown Upgrade")
		return
		
	# Aplicar efectos
	if "effects" in data:
		for effect in data.effects:
			var stat = effect.stat
			var val = effect.value
			var op = effect.operation
			
			if op == "add":
				if stats.has_method("add_stat"):
					stats.add_stat(stat, val)
			elif op == "multiply":
				if stats.has_method("multiply_stat"):
					stats.multiply_stat(stat, val)
					
	_show_toast("Upgrade Added: " + data.get("name", id))

func _spawn_dummy():
	var dummy = Node2D.new()
	dummy.name = "DummyTarget"
	var sprite = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	sprite.texture = ImageTexture.create_from_image(img)
	dummy.add_child(sprite)
	dummy.add_to_group("enemies")
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	dummy.position = player.position + offset
	
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
	var damage_log = {} # id_arma -> daño_total
	
	func take_damage(amount, _source=null):
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
		
		# Log extra para debug (opcional)
		# print("Dummy tomó ", amount, " de daño")
	"""
	dummy.set_script(script)
	add_child(dummy)
	_show_toast("Dummy Spawned (Layer 2)")

func _clear_weapons():
	var am = _get_attack_manager()
	if am and "weapons" in am:
		am.weapons.clear()
		am.current_weapon_count = 0 
		am.weapon_stats_map.clear() # Limpiar stats también
		
	# CLEANUP AGRESIVO DE PROYECTILES/ORBITALES
	print("[TestGym] Cleaning up logic entities...")
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
			
	_show_toast("Weapons Cleared & Cleaned")

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
	# Ejecutar test complejo en una cor rutina separada para no bloquear
	_run_complex_test()

func _run_complex_test() -> void:
	print("🚀 INICIANDO SUPER MEGA AUTO-TEST 🚀")
	_show_toast("🚀 STARTING COMPLEX TEST 🚀")
	
	# Asegurar dummy
	if not get_tree().has_group("enemies"):
		_spawn_dummy()
	
	# Combinar armas y fusiones para probar todo
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
		
		# 1. Limpiar
		_clear_weapons()
		await get_tree().create_timer(0.5).timeout
		
		# 2. Equipar Batch
		for wid in batch:
			_on_add_weapon(wid)
			await get_tree().create_timer(0.1).timeout
			
		# 3. Probar TODOS los upgrades con este setup
		print("   🔼 Aplicando ALL Upgrades...")
		_show_toast("Applying Upgrades...")
		
		# Agrupar upgrades para no tardar 100 años (aplicar 5 por frame)
		var upg_count = 0
		for uid in upgrade_ids:
			_apply_upgrade_silent(uid)
			upg_count += 1
			if upg_count % 5 == 0:
				await get_tree().process_frame
		
		print("   ✅ Upgrades aplicados. Esperando daño...")
		_show_toast("Wait for Damage...")
		
		# 4. Esperar y observar daño (3 segundos)
		await get_tree().create_timer(3.0).timeout
		
	print("\n✅✅✅ TEST COMPLETO: Todas las combinaciones probadas ✅✅✅")
	_show_toast("✅✅✅ TEST COMPLETE ✅✅✅")

func _apply_upgrade_silent(id: String):
	# Versión silenciosa de _on_add_upgrade para no spammear toasts
	var stats = _get_player_stats()
	var data = _get_upgrade_data(id)
	
	if not stats or data.is_empty(): return
		
	if "effects" in data:
		for effect in data.effects:
			var stat = effect.stat
			var val = effect.value
			var op = effect.operation
			
			if op == "add":
				if stats.has_method("add_stat"):
					stats.add_stat(stat, val)
			elif op == "multiply":
				if stats.has_method("multiply_stat"):
					stats.multiply_stat(stat, val)
