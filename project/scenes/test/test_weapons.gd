# test_weapons.gd
# Escena de prueba para testear todas las armas y fusiones
# Incluye: Player, Dummy targets, UI de selección de armas, estadísticas

extends Node2D

# === REFERENCIAS ===
var player: CharacterBody2D = null
var attack_manager: Node = null
var dummies: Array[Node2D] = []
var selected_weapon_index: int = 0
var current_category: String = "base"  # "base" o "fusion"

# === UI ===
var ui_layer: CanvasLayer = null
var weapon_list: VBoxContainer = null
var stats_label: Label = null
var damage_log: RichTextLabel = null
var category_label: Label = null
var dps_label: Label = null

# === DATOS ===
var base_weapons: Array[String] = [
	"ice_wand", "fire_wand", "lightning_wand", "arcane_orb", "shadow_dagger",
	"nature_staff", "wind_blade", "earth_spike", "light_beam", "void_pulse"
]

var fusion_weapons: Array[String] = [
	# Ice combos
	"steam_cannon", "frozen_thunder", "frost_orb", "frostbite", "blizzard", 
	"glacier", "aurora", "absolute_zero", "frostfire",
	# Fire combos  
	"plasma", "inferno_orb", "wildfire", "firestorm", "volcano", 
	"solar_flare", "dark_flame", "hellfire",
	# Lightning combos
	"storm_caller", "arcane_storm", "dark_lightning", "thunder_bloom", 
	"seismic_bolt", "thunder_spear", "void_bolt",
	# Arcane combos
	"void_orbs", "life_orbs", "wind_orbs", "cosmic_barrier", "cosmic_void",
	# Shadow combos
	"soul_reaper", "phantom_blade", "stone_fang", "twilight", "abyss",
	# Nature combos
	"pollen_storm", "gaia", "solar_bloom", "decay",
	# Wind combos
	"sandstorm", "prism_wind",
	# Earth combos
	"earthquake", "crystal_guardian", "radiant_stone",
	# Light/Void combos
	"void_storm", "eclipse"
]

var total_damage_dealt: int = 0
var hits_count: int = 0
var test_start_time: float = 0.0
var TestDummyScript: Script = null

func _ready() -> void:
	print("🧪 [WeaponTest] Iniciando escena de prueba de armas...")
	
	# Cargar script de TestDummy
	TestDummyScript = load("res://scenes/test/TestDummy.gd")
	
	_setup_scene()
	_create_player()
	_create_dummies()
	_create_ui()
	_select_weapon(0)
	
	test_start_time = Time.get_ticks_msec() / 1000.0
	
	# Esperar a que el AttackManager esté listo y obtener referencia (AWAIT!)
	await _wait_for_attack_manager()
	
	print("🧪 [WeaponTest] ¡Escena lista!")
	print("   ↑↓ = Cambiar arma | TAB = Categoría | SPACE = Equipar")
	print("   R = Reset dummies | WASD = Mover | ESC = Salir")

func _wait_for_attack_manager() -> void:
	"""Esperar a que el AttackManager esté disponible"""
	# Hacer polling hasta que el AttackManager esté disponible (máx 60 frames = 1 segundo)
	var max_attempts = 60
	var attempt = 0
	
	while attempt < max_attempts:
		await get_tree().process_frame
		attempt += 1
		
		# Opción 1: Buscar en el GameManager (fuente primaria)
		var game_manager = get_tree().root.get_node_or_null("GameManager")
		if game_manager:
			var gm_am = game_manager.get_node_or_null("AttackManager")
			if gm_am:
				attack_manager = gm_am
				print("🧪 [WeaponTest] ✓ AttackManager obtenido del GameManager (frame %d)" % attempt)
				return
		
		# Opción 2: Buscar en el player (SpellloopPlayer -> WizardPlayer)
		if player:
			# SpellloopPlayer tiene wizard_player como hijo
			var wizard = player.get("wizard_player")
			if wizard and "attack_manager" in wizard and wizard.attack_manager != null:
				attack_manager = wizard.attack_manager
				print("🧪 [WeaponTest] ✓ AttackManager obtenido del WizardPlayer (frame %d)" % attempt)
				return
			
			# También probar acceso directo por si acaso
			if "attack_manager" in player and player.attack_manager != null:
				attack_manager = player.attack_manager
				print("🧪 [WeaponTest] ✓ AttackManager obtenido del player (frame %d)" % attempt)
				return
		
		# Opción 3: Buscar en el root directamente
		var root_am = get_tree().root.get_node_or_null("AttackManager")
		if root_am:
			attack_manager = root_am
			print("🧪 [WeaponTest] ✓ AttackManager obtenido del root (frame %d)" % attempt)
			return
	
	print("🧪 [WeaponTest] ⚠️ AttackManager no disponible después de %d frames" % max_attempts)

func _setup_scene() -> void:
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg_layer.add_child(bg)
	
	# Arena visual (círculo de referencia)
	var arena = Node2D.new()
	arena.name = "ArenaVisual"
	add_child(arena)
	arena.draw.connect(_draw_arena.bind(arena))
	arena.queue_redraw()

func _draw_arena(arena: Node2D) -> void:
	# Círculo de arena
	arena.draw_arc(Vector2.ZERO, 400, 0, TAU, 64, Color(0.3, 0.3, 0.4), 2.0)
	arena.draw_arc(Vector2.ZERO, 200, 0, TAU, 32, Color(0.25, 0.25, 0.35), 1.0)
	
	# Cruz central
	arena.draw_line(Vector2(-20, 0), Vector2(20, 0), Color(0.4, 0.4, 0.5), 1.0)
	arena.draw_line(Vector2(0, -20), Vector2(0, 20), Color(0.4, 0.4, 0.5), 1.0)

func _create_player() -> void:
	# Cargar escena del player
	var player_scene = load("res://scenes/player/SpellloopPlayer.tscn")
	if player_scene:
		player = player_scene.instantiate()
		add_child(player)
		player.global_position = Vector2.ZERO
		
		# El AttackManager se inicializa de forma deferred en BasePlayer
		# Necesitamos esperar a que esté listo
		print("🧪 [WeaponTest] Player creado, esperando AttackManager...")
	else:
		push_error("[WeaponTest] No se pudo cargar SpellloopPlayer.tscn")
		_create_fallback_player()

func _create_fallback_player() -> void:
	# Player de fallback simple
	player = CharacterBody2D.new()
	player.name = "TestPlayer"
	add_child(player)
	
	var sprite = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.6, 1.0))
	sprite.texture = ImageTexture.create_from_image(img)
	player.add_child(sprite)
	
	# AttackManager manual
	var am_script = load("res://scripts/core/AttackManager.gd")
	if am_script:
		attack_manager = am_script.new()
		attack_manager.name = "AttackManager"
		player.add_child(attack_manager)
		attack_manager.initialize(player)

func _create_dummies() -> void:
	# Crear varios dummies en diferentes posiciones
	var positions = [
		Vector2(200, 0),    # Derecha cerca
		Vector2(350, 0),    # Derecha lejos
		Vector2(-200, 0),   # Izquierda cerca
		Vector2(-350, 0),   # Izquierda lejos
		Vector2(0, -180),   # Arriba
		Vector2(0, 180),    # Abajo
		Vector2(150, -150), # Diagonal NE
		Vector2(-150, 150), # Diagonal SW
	]
	
	for i in range(positions.size()):
		var dummy = _create_dummy(positions[i], i + 1)
		dummies.append(dummy)
		add_child(dummy)
		
		# Conectar señal de daño
		if dummy.has_signal("damage_received"):
			dummy.damage_received.connect(_on_dummy_damage.bind(dummy))
	
	print("🧪 [WeaponTest] %d dummies creados" % dummies.size())

func _create_dummy(pos: Vector2, id: int) -> CharacterBody2D:
	var dummy: CharacterBody2D
	
	if TestDummyScript:
		dummy = CharacterBody2D.new()
		dummy.set_script(TestDummyScript)
		dummy.dummy_id = id
	else:
		# Fallback: dummy básico
		dummy = _create_basic_dummy(id)
	
	dummy.name = "Dummy_%d" % id
	dummy.global_position = pos
	
	return dummy

func _create_basic_dummy(id: int) -> CharacterBody2D:
	"""Crear dummy básico sin el script TestDummy"""
	var dummy = CharacterBody2D.new()
	dummy.name = "Dummy_%d" % id
	dummy.add_to_group("enemies")
	
	# Sprite del dummy
	var sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var center = Vector2(24, 24)
	for x in range(48):
		for y in range(48):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 20:
				img.set_pixel(x, y, Color(0.8, 0.2, 0.2))
			elif dist < 22:
				img.set_pixel(x, y, Color(0.5, 0.1, 0.1))
	
	frames.add_frame("idle", ImageTexture.create_from_image(img))
	sprite.sprite_frames = frames
	sprite.play("idle")
	dummy.add_child(sprite)
	
	# Colisión
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	dummy.add_child(collision)
	
	# Capas de colisión (enemies = layer 2)
	dummy.collision_layer = 2
	dummy.collision_mask = 0
	
	# Health Component simulado
	var health = Node.new()
	health.name = "HealthComponent"
	health.set_meta("max_hp", 99999)
	health.set_meta("current_hp", 99999)
	dummy.add_child(health)
	
	# Label de HP
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: 99999"
	hp_label.position = Vector2(-30, -40)
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	dummy.add_child(hp_label)
	
	# ID Label
	var id_label = Label.new()
	id_label.text = "#%d" % id
	id_label.position = Vector2(-10, 25)
	id_label.add_theme_font_size_override("font_size", 10)
	id_label.add_theme_color_override("font_color", Color.YELLOW)
	dummy.add_child(id_label)
	
	# Guardar ID
	dummy.set_meta("dummy_id", id)
	
	return dummy

func _on_dummy_damage(amount: int, _source: String, dummy: Node) -> void:
	"""Callback cuando un dummy recibe daño"""
	total_damage_dealt += amount
	hits_count += 1
	
	var dummy_id = dummy.get("dummy_id") if "dummy_id" in dummy else dummy.get_meta("dummy_id", 0)
	_log_damage("[color=orange]💥 Dummy #%d: -%d (%s)[/color]" % [dummy_id, amount, _source])

func _create_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)
	
	# Panel izquierdo - Lista de armas
	var left_panel = Panel.new()
	left_panel.position = Vector2(10, 10)
	left_panel.size = Vector2(280, 600)
	ui_layer.add_child(left_panel)
	
	# Título categoría
	category_label = Label.new()
	category_label.text = "⚔️ ARMAS BASE (10)"
	category_label.position = Vector2(20, 20)
	category_label.add_theme_font_size_override("font_size", 18)
	category_label.add_theme_color_override("font_color", Color.GOLD)
	left_panel.add_child(category_label)
	
	# Instrucciones
	var help_label = Label.new()
	help_label.text = "↑↓ Cambiar | TAB Categoría | SPACE Equipar"
	help_label.position = Vector2(20, 45)
	help_label.add_theme_font_size_override("font_size", 10)
	help_label.add_theme_color_override("font_color", Color.GRAY)
	left_panel.add_child(help_label)
	
	# ScrollContainer para la lista
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 70)
	scroll.size = Vector2(260, 520)
	left_panel.add_child(scroll)
	
	weapon_list = VBoxContainer.new()
	weapon_list.name = "WeaponList"
	scroll.add_child(weapon_list)
	
	_populate_weapon_list()
	
	# Panel derecho - Stats del arma seleccionada
	var right_panel = Panel.new()
	right_panel.position = Vector2(1650, 10)
	right_panel.size = Vector2(380, 400)
	ui_layer.add_child(right_panel)
	
	var stats_title = Label.new()
	stats_title.text = "📊 ESTADÍSTICAS"
	stats_title.position = Vector2(20, 15)
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", Color.CYAN)
	right_panel.add_child(stats_title)
	
	stats_label = Label.new()
	stats_label.position = Vector2(20, 45)
	stats_label.size = Vector2(340, 340)
	stats_label.add_theme_font_size_override("font_size", 12)
	right_panel.add_child(stats_label)
	
	# Panel inferior - Log de daño
	var bottom_panel = Panel.new()
	bottom_panel.position = Vector2(1650, 420)
	bottom_panel.size = Vector2(380, 300)
	ui_layer.add_child(bottom_panel)
	
	var log_title = Label.new()
	log_title.text = "💥 LOG DE DAÑO"
	log_title.position = Vector2(20, 15)
	log_title.add_theme_font_size_override("font_size", 16)
	log_title.add_theme_color_override("font_color", Color.ORANGE_RED)
	bottom_panel.add_child(log_title)
	
	damage_log = RichTextLabel.new()
	damage_log.position = Vector2(10, 45)
	damage_log.size = Vector2(360, 245)
	damage_log.bbcode_enabled = true
	damage_log.scroll_following = true
	bottom_panel.add_child(damage_log)
	
	# Info panel (centro superior)
	var info_panel = Panel.new()
	info_panel.position = Vector2(600, 10)
	info_panel.size = Vector2(500, 80)
	ui_layer.add_child(info_panel)
	
	var info_label = Label.new()
	info_label.text = "🧪 WEAPON TEST ARENA"
	info_label.position = Vector2(20, 10)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color.GOLD)
	info_panel.add_child(info_label)
	
	var controls_label = Label.new()
	controls_label.text = "WASD=Mover | ↑↓=Armas | TAB=Categoría | SPACE=Equipar | R=Reset | ESC=Salir"
	controls_label.position = Vector2(20, 35)
	controls_label.add_theme_font_size_override("font_size", 11)
	controls_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_panel.add_child(controls_label)
	
	# DPS Label
	dps_label = Label.new()
	dps_label.name = "DPSLabel"
	dps_label.text = "DPS: 0 | Hits: 0 | Total: 0"
	dps_label.position = Vector2(20, 55)
	dps_label.add_theme_font_size_override("font_size", 12)
	dps_label.add_theme_color_override("font_color", Color.CYAN)
	info_panel.add_child(dps_label)

func _populate_weapon_list() -> void:
	# Limpiar lista actual
	for child in weapon_list.get_children():
		child.queue_free()
	
	var weapons_to_show = base_weapons if current_category == "base" else fusion_weapons
	
	for i in range(weapons_to_show.size()):
		var weapon_id = weapons_to_show[i]
		var data = WeaponDatabase.get_weapon_data(weapon_id)
		
		var item = HBoxContainer.new()
		item.name = "Item_%d" % i
		
		# Indicador de selección
		var selector = Label.new()
		selector.name = "Selector"
		selector.text = "► " if i == selected_weapon_index else "   "
		selector.add_theme_color_override("font_color", Color.YELLOW)
		selector.custom_minimum_size.x = 25
		item.add_child(selector)
		
		# Icono del elemento
		var icon = Label.new()
		icon.text = data.get("icon", "🔮")
		icon.custom_minimum_size.x = 25
		item.add_child(icon)
		
		# Nombre del arma
		var name_label = Label.new()
		name_label.text = data.get("name_es", data.get("name", weapon_id))
		name_label.add_theme_font_size_override("font_size", 12)
		
		# Color según si es fusión
		if current_category == "fusion":
			name_label.add_theme_color_override("font_color", Color.MEDIUM_PURPLE)
		
		item.add_child(name_label)
		
		weapon_list.add_child(item)

func _update_weapon_list_selection() -> void:
	var weapons_to_show = base_weapons if current_category == "base" else fusion_weapons
	
	for i in range(weapon_list.get_child_count()):
		var item = weapon_list.get_child(i)
		var selector = item.get_node_or_null("Selector")
		if selector:
			selector.text = "► " if i == selected_weapon_index else "   "

func _select_weapon(index: int) -> void:
	var weapons_to_show = base_weapons if current_category == "base" else fusion_weapons
	
	if index < 0:
		index = weapons_to_show.size() - 1
	elif index >= weapons_to_show.size():
		index = 0
	
	selected_weapon_index = index
	_update_weapon_list_selection()
	_update_stats_display()

func _equip_selected_weapon() -> void:
	if not attack_manager:
		_log_damage("[color=red]❌ AttackManager no disponible[/color]")
		print("🧪 [WeaponTest] ❌ AttackManager es null, no se puede equipar")
		return
	
	var weapons_to_show = base_weapons if current_category == "base" else fusion_weapons
	var weapon_id = weapons_to_show[selected_weapon_index]
	
	print("🧪 [WeaponTest] Intentando equipar: %s" % weapon_id)
	print("🧪 [WeaponTest] Armas antes de limpiar: %d" % attack_manager.weapons.size())
	
	# Limpiar armas actuales
	if attack_manager.has_method("clear_weapons"):
		attack_manager.clear_weapons()
		print("🧪 [WeaponTest] Armas después de limpiar: %d" % attack_manager.weapons.size())
	else:
		print("🧪 [WeaponTest] ⚠️ AttackManager no tiene clear_weapons()")
	
	# Equipar nueva arma usando BaseWeapon
	var BaseWeaponClass = load("res://scripts/weapons/BaseWeapon.gd")
	if BaseWeaponClass:
		var weapon = BaseWeaponClass.new(weapon_id)
		if weapon.id.is_empty():
			_log_damage("[color=red]❌ Error creando arma: %s[/color]" % weapon_id)
			print("🧪 [WeaponTest] ❌ Arma creada con ID vacío")
			return
		
		print("🧪 [WeaponTest] Arma creada: %s (id: %s)" % [weapon.weapon_name, weapon.id])
		
		if attack_manager.has_method("add_weapon"):
			var success = attack_manager.add_weapon(weapon)
			if success:
				_log_damage("[color=green]✅ Equipada: %s[/color]" % weapon.weapon_name)
				print("🧪 [WeaponTest] ✓ Arma añadida exitosamente. Total armas: %d" % attack_manager.weapons.size())
			else:
				_log_damage("[color=red]❌ Error al añadir arma[/color]")
				print("🧪 [WeaponTest] ❌ add_weapon() retornó false")
		else:
			_log_damage("[color=red]❌ AttackManager sin add_weapon()[/color]")
	else:
		_log_damage("[color=red]❌ No se pudo cargar BaseWeapon.gd[/color]")

func _update_stats_display() -> void:
	var weapons_to_show = base_weapons if current_category == "base" else fusion_weapons
	var weapon_id = weapons_to_show[selected_weapon_index]
	var data = WeaponDatabase.get_weapon_data(weapon_id)
	
	if data.is_empty():
		stats_label.text = "No hay datos para: %s" % weapon_id
		return
	
	var element_names = ["ICE", "FIRE", "LIGHTNING", "ARCANE", "SHADOW", 
						  "NATURE", "WIND", "EARTH", "LIGHT", "VOID"]
	var proj_types = ["SINGLE", "MULTI", "BEAM", "AOE", "ORBIT", "CHAIN"]
	var target_types = ["NEAREST", "RANDOM", "AREA", "ORBIT", "DIRECTION", "HOMING"]
	
	var element_idx = data.get("element", 0)
	var proj_idx = data.get("projectile_type", 0)
	var target_idx = data.get("target_type", 0)
	
	var stats_text = """[%s] %s
%s

━━━━ STATS ━━━━
⚔️ Daño: %d
⏱️ Cooldown: %.2fs
📏 Rango: %.0f
🚀 Velocidad Proy: %.0f
🔢 Proyectiles: %d
↗️ Pierce: %d
🔘 Área: %.1f
⏳ Duración: %.1fs
💨 Knockback: %.0f

━━━━ TIPO ━━━━
🎯 Target: %s
💫 Proyectil: %s
🔥 Elemento: %s

━━━━ EFECTO ━━━━
✨ %s: %.1f (%.1fs)
""" % [
		data.get("icon", "🔮"),
		data.get("name_es", data.get("name", weapon_id)),
		data.get("description", "Sin descripción"),
		data.get("damage", 0),
		data.get("cooldown", 1.0),
		data.get("range", 0),
		data.get("projectile_speed", 0),
		data.get("projectile_count", 1),
		data.get("pierce", 0),
		data.get("area", 1.0),
		data.get("duration", 0.0),
		data.get("knockback", 0),
		target_types[target_idx] if target_idx < target_types.size() else "?",
		proj_types[proj_idx] if proj_idx < proj_types.size() else "?",
		element_names[element_idx] if element_idx < element_names.size() else "?",
		data.get("effect", "none"),
		data.get("effect_value", 0),
		data.get("effect_duration", 0)
	]
	
	# Si es fusión, mostrar componentes
	if data.has("components"):
		stats_text += "\n━━━━ FUSIÓN ━━━━\n🔗 %s" % " + ".join(data.components)
	
	stats_label.text = stats_text

func _log_damage(message: String) -> void:
	if damage_log:
		damage_log.append_text(message + "\n")

func _reset_dummies() -> void:
	total_damage_dealt = 0
	hits_count = 0
	test_start_time = Time.get_ticks_msec() / 1000.0
	
	for dummy in dummies:
		if is_instance_valid(dummy):
			if dummy.has_method("reset"):
				dummy.reset()
			else:
				# Fallback para dummy básico
				var health = dummy.get_node_or_null("HealthComponent")
				if health:
					health.set_meta("current_hp", 99999)
				var hp_label = dummy.get_node_or_null("HPLabel")
				if hp_label:
					hp_label.text = "HP: 99999"
	
	_log_damage("[color=yellow]🔄 Dummies reseteados - Contador reiniciado[/color]")
	_update_dps_display()

func _toggle_category() -> void:
	current_category = "fusion" if current_category == "base" else "base"
	selected_weapon_index = 0
	
	if current_category == "base":
		category_label.text = "⚔️ ARMAS BASE (10)"
	else:
		category_label.text = "🔮 FUSIONES (%d)" % fusion_weapons.size()
	
	_populate_weapon_list()
	_update_stats_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_select_weapon(selected_weapon_index - 1)
	elif event.is_action_pressed("ui_down"):
		_select_weapon(selected_weapon_index + 1)
	elif event.is_action_pressed("ui_focus_next"):  # TAB
		_toggle_category()
	elif event.is_action_pressed("ui_accept"):  # SPACE/ENTER
		_equip_selected_weapon()
	elif event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_reset_dummies()
		elif event.keycode == KEY_PAGEUP:
			_select_weapon(selected_weapon_index - 10)
		elif event.keycode == KEY_PAGEDOWN:
			_select_weapon(selected_weapon_index + 10)

func _process(_delta: float) -> void:
	_update_dps_display()

func _update_dps_display() -> void:
	if not dps_label:
		return
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - test_start_time
	var dps = total_damage_dealt / max(1.0, elapsed)
	
	dps_label.text = "⚡ DPS: %.1f | 💥 Hits: %d | 📊 Total: %d | ⏱️ %.1fs" % [
		dps, hits_count, total_damage_dealt, elapsed
	]
