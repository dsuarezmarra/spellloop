# test_upgrades.gd - Escena de prueba completa para mejoras y armas
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES DE LAYOUT
# ═══════════════════════════════════════════════════════════════════════════════

# Panel izquierdo - Lista de mejoras
const LEFT_PANEL := Rect2(10, 10, 300, 500)
# Panel descripción mejora
const DESC_PANEL := Rect2(320, 10, 350, 150)
# Panel stats jugador
const STATS_PANEL := Rect2(320, 170, 350, 250)
# Panel armas equipadas
const WEAPONS_PANEL := Rect2(680, 10, 340, 200)
# Panel fusiones
const FUSION_PANEL := Rect2(680, 220, 340, 200)
# Panel aplicadas
const APPLIED_PANEL := Rect2(10, 520, 300, 190)
# Panel log
const LOG_PANEL := Rect2(320, 430, 700, 280)

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS DEL JUEGO
# ═══════════════════════════════════════════════════════════════════════════════

var player: CharacterBody2D = null
var attack_manager = null
var player_stats: PlayerStats = null
var global_weapon_stats: GlobalWeaponStats = null
var dummies: Array[Node2D] = []

# ═══════════════════════════════════════════════════════════════════════════════
# UI REFERENCES
# ═══════════════════════════════════════════════════════════════════════════════

var ui_layer: CanvasLayer = null
var upgrade_list: VBoxContainer = null
var upgrade_items: Array[Control] = []
var desc_label: RichTextLabel = null
var stats_label: RichTextLabel = null
var weapons_container: HBoxContainer = null
var fusion_label: RichTextLabel = null
var applied_label: RichTextLabel = null
var log_label: RichTextLabel = null
var dps_label: Label = null

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

enum UpgradeSource { PLAYER, WEAPON_GLOBAL, WEAPON_SPECIFIC }
var current_category: UpgradeSource = UpgradeSource.PLAYER
var all_player_upgrades: Array[Dictionary] = []
var all_weapon_global_upgrades: Array[Dictionary] = []
var all_weapon_specific_upgrades: Array[Dictionary] = []
var selected_upgrade_idx: int = 0
var applied_upgrades: Array[Dictionary] = []

# Armas
var available_weapons: Array = []
var selected_weapon_slot: int = -1
var fusion_slot_a: int = -1
var fusion_slot_b: int = -1

# Stats de test
var total_damage: int = 0
var hits_count: int = 0
var start_time: float = 0.0
var _key_held: Dictionary = {}

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	print("🧪 [TestUpgrades] Iniciando...")
	_setup_background()
	_load_all_upgrades()
	_load_available_weapons()
	_create_ui()
	_create_player()
	_create_dummies()
	
	start_time = Time.get_ticks_msec() / 1000.0
	await _wait_for_systems()
	
	_update_all_ui()
	_select_upgrade(0)
	_log("[color=green]✓ Test listo. Usa ↑↓ navegar, ENTER aplicar, TAB armas[/color]")

func _setup_background() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg_layer.add_child(bg)

func _create_player() -> void:
	var scene = load("res://scenes/player/SpellloopPlayer.tscn")
	if scene:
		player = scene.instantiate()
		add_child(player)
		player.global_position = Vector2(900, 550)
		call_deferred("_setup_player_for_test")

func _setup_player_for_test() -> void:
	if not player:
		return
	var wizard = player.get("wizard_player") if "wizard_player" in player else null
	if wizard:
		wizard.max_hp = 99999
		wizard.hp = 99999

func _wait_for_systems() -> void:
	for i in range(60):
		await get_tree().process_frame
		
		if player_stats == null:
			if player and "player_stats" in player:
				player_stats = player.player_stats
			else:
				var nodes = get_tree().get_nodes_in_group("player_stats")
				if nodes.size() > 0:
					player_stats = nodes[0]
		
		if attack_manager == null:
			var gm = get_tree().root.get_node_or_null("GameManager")
			if gm:
				attack_manager = gm.get_node_or_null("AttackManager")
			if attack_manager == null and player:
				var wizard = player.get("wizard_player") if "wizard_player" in player else null
				if wizard and "attack_manager" in wizard:
					attack_manager = wizard.attack_manager
		
		if global_weapon_stats == null and attack_manager:
			if attack_manager.has_method("get_global_weapon_stats"):
				global_weapon_stats = attack_manager.get_global_weapon_stats()
			elif "global_weapon_stats" in attack_manager:
				global_weapon_stats = attack_manager.global_weapon_stats
		
		if player_stats and attack_manager:
			print("🧪 [TestUpgrades] ✓ Sistemas listos")
			_connect_damage_signals()
			# Esperar un poco más para que WizardPlayer termine de equipar armas
			await get_tree().create_timer(0.5).timeout
			_replace_legacy_weapons()
			return
	
	# Fallback
	if player_stats == null:
		player_stats = PlayerStats.new()
		add_child(player_stats)
	if global_weapon_stats == null:
		global_weapon_stats = GlobalWeaponStats.new()
		add_child(global_weapon_stats)

func _replace_legacy_weapons() -> void:
	"""Reemplazar armas legacy por BaseWeapon para que funcione la fusión"""
	if not attack_manager:
		print("🧪 [TestUpgrades] ⚠️ No hay AttackManager para reemplazar armas")
		return
	
	# Obtener armas actuales (pueden ser legacy)
	var current_weapons = _get_equipped_weapons().duplicate()
	print("🧪 [TestUpgrades] Verificando %d armas equipadas" % current_weapons.size())
	
	var legacy_weapons: Array = []
	var legacy_ids: Array[String] = []
	
	# Identificar armas legacy (no son BaseWeapon)
	for w in current_weapons:
		if w == null:
			continue
		if not w is BaseWeapon:
			var wid = w.id if "id" in w else ""
			print("🧪 [TestUpgrades] ⚠️ Arma legacy detectada: %s" % wid)
			if wid != "":
				legacy_weapons.append(w)
				legacy_ids.append(wid)
	
	if legacy_weapons.is_empty():
		print("🧪 [TestUpgrades] ✓ No hay armas legacy, todas son BaseWeapon")
		return
	
	# Remover armas legacy
	for w in legacy_weapons:
		if attack_manager.has_method("remove_weapon"):
			attack_manager.remove_weapon(w)
			print("🧪 [TestUpgrades] Removida arma legacy: %s" % (w.id if "id" in w else "?"))
	
	# Re-añadir usando add_weapon_by_id (crea BaseWeapon)
	for wid in legacy_ids:
		if attack_manager.has_method("add_weapon_by_id"):
			var success = attack_manager.add_weapon_by_id(wid)
			if success:
				print("🧪 [TestUpgrades] ✓ Reemplazada %s como BaseWeapon" % wid)
			else:
				print("🧪 [TestUpgrades] ✗ Error al crear BaseWeapon para %s" % wid)
	
	print("🧪 [TestUpgrades] ✓ Armas legacy reemplazadas por BaseWeapon")

func _connect_damage_signals() -> void:
	# Conectar señales de daño del AttackManager si existen
	if attack_manager and attack_manager.has_signal("damage_dealt"):
		if not attack_manager.is_connected("damage_dealt", _on_damage_dealt):
			attack_manager.connect("damage_dealt", _on_damage_dealt)

func _on_damage_dealt(amount: int, target: Node, _weapon = null) -> void:
	total_damage += amount
	hits_count += 1
	var target_name = target.name if target else "?"
	_log("[color=orange]💥 %s recibe %d daño[/color]" % [target_name, amount])
	_spawn_damage_number(target.global_position if target else Vector2.ZERO, amount)

# ═══════════════════════════════════════════════════════════════════════════════
# CARGA DE DATOS
# ═══════════════════════════════════════════════════════════════════════════════

func _load_all_upgrades() -> void:
	# Player upgrades
	for key in PlayerUpgradeDatabase.DEFENSIVE_UPGRADES:
		var u = PlayerUpgradeDatabase.DEFENSIVE_UPGRADES[key].duplicate(true)
		u["source"] = "defensive"
		all_player_upgrades.append(u)
	for key in PlayerUpgradeDatabase.UTILITY_UPGRADES:
		var u = PlayerUpgradeDatabase.UTILITY_UPGRADES[key].duplicate(true)
		u["source"] = "utility"
		all_player_upgrades.append(u)
	for key in PlayerUpgradeDatabase.CURSED_UPGRADES:
		var u = PlayerUpgradeDatabase.CURSED_UPGRADES[key].duplicate(true)
		u["is_cursed"] = true
		all_player_upgrades.append(u)
	for key in PlayerUpgradeDatabase.UNIQUE_UPGRADES:
		var u = PlayerUpgradeDatabase.UNIQUE_UPGRADES[key].duplicate(true)
		u["is_unique"] = true
		all_player_upgrades.append(u)
	
	# Weapon global
	for key in WeaponUpgradeDatabase.GLOBAL_UPGRADES:
		var u = WeaponUpgradeDatabase.GLOBAL_UPGRADES[key].duplicate(true)
		all_weapon_global_upgrades.append(u)
	
	# Weapon specific
	for key in WeaponUpgradeDatabase.SPECIFIC_UPGRADES:
		var u = WeaponUpgradeDatabase.SPECIFIC_UPGRADES[key].duplicate(true)
		all_weapon_specific_upgrades.append(u)
	for key in WeaponUpgradeDatabase.WEAPON_SPECIFIC_UPGRADES:
		var u = WeaponUpgradeDatabase.WEAPON_SPECIFIC_UPGRADES[key].duplicate(true)
		all_weapon_specific_upgrades.append(u)
	
	print("🧪 Mejoras: Player=%d, Global=%d, Specific=%d" % [
		all_player_upgrades.size(), all_weapon_global_upgrades.size(), all_weapon_specific_upgrades.size()])

func _load_available_weapons() -> void:
	# Usar función estática de WeaponDatabase
	available_weapons = WeaponDatabase.get_all_base_weapons()
	if available_weapons.is_empty():
		# Fallback: armas base conocidas
		available_weapons = [
			"ice_wand", "fire_wand", "lightning_wand", "arcane_orb",
			"shadow_dagger", "nature_staff", "wind_blade", "earth_spike",
			"light_beam", "void_pulse"
		]
	print("🧪 Armas disponibles: %d" % available_weapons.size())

# ═══════════════════════════════════════════════════════════════════════════════
# CREACIÓN DE DUMMIES
# ═══════════════════════════════════════════════════════════════════════════════

func _create_dummies() -> void:
	var positions = [
		Vector2(1100, 450), Vector2(1100, 650),
		Vector2(1250, 550), Vector2(950, 550),
	]
	for i in range(positions.size()):
		var d = _make_dummy(positions[i], i + 1)
		dummies.append(d)
		add_child(d)

func _make_dummy(pos: Vector2, id: int) -> CharacterBody2D:
	var dummy = CharacterBody2D.new()
	dummy.name = "Dummy_%d" % id
	dummy.global_position = pos
	dummy.add_to_group("enemies")
	dummy.collision_layer = 2
	dummy.collision_mask = 0
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28
	col.shape = shape
	dummy.add_child(col)
	
	dummy.set_meta("max_hp", 500)
	dummy.set_meta("hp", 500)
	dummy.set_meta("id", id)
	
	# Visual
	var vis = _create_dummy_visual()
	dummy.add_child(vis)
	
	# HP Label
	var hp_lbl = Label.new()
	hp_lbl.name = "HPLabel"
	hp_lbl.text = "500/500"
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.position = Vector2(-25, -55)
	hp_lbl.add_theme_font_size_override("font_size", 10)
	hp_lbl.add_theme_color_override("font_color", Color.WHITE)
	dummy.add_child(hp_lbl)
	
	# Script para take_damage
	var script = GDScript.new()
	script.source_code = _get_dummy_script()
	script.reload()
	dummy.set_script(script)
	dummy.set_meta("test_scene", self)
	dummy.set_meta("max_hp", 500)
	dummy.set_meta("hp", 500)
	dummy.set_meta("id", id)
	
	return dummy

func _create_dummy_visual() -> Node2D:
	var vis = Node2D.new()
	vis.name = "Visual"
	var script = GDScript.new()
	script.source_code = """
extends Node2D
func _process(_d): queue_redraw()
func _draw():
	var p = get_parent()
	var hp = float(p.get_meta("hp", 500))
	var max_hp = float(p.get_meta("max_hp", 500))
	var pct = hp / max_hp
	draw_circle(Vector2.ZERO, 28, Color(0.6, 0.2, 0.2).lerp(Color(0.2, 0.6, 0.2), pct))
	draw_arc(Vector2.ZERO, 28, 0, TAU, 32, Color.WHITE, 2)
	draw_circle(Vector2(-8, -5), 4, Color.WHITE)
	draw_circle(Vector2(8, -5), 4, Color.WHITE)
	var bar_w = 44
	draw_rect(Rect2(-bar_w/2, -42, bar_w, 5), Color(0.2, 0.2, 0.2))
	var c = Color.GREEN if pct > 0.5 else (Color.YELLOW if pct > 0.25 else Color.RED)
	draw_rect(Rect2(-bar_w/2, -42, bar_w * pct, 5), c)
"""
	script.reload()
	vis.set_script(script)
	return vis

func _get_dummy_script() -> String:
	return """
extends CharacterBody2D
signal damage_taken(amount)

func take_damage(amount, _type = "", _attacker = null):
	var old_hp = get_meta("hp", 500)
	var new_hp = maxi(0, old_hp - int(amount))
	set_meta("hp", new_hp)
	
	var lbl = get_node_or_null("HPLabel")
	if lbl: lbl.text = "%d/%d" % [new_hp, get_meta("max_hp", 500)]
	
	var ts = get_meta("test_scene", null)
	if ts and ts.has_method("_on_dummy_hit"):
		ts._on_dummy_hit(self, int(amount))
	
	damage_taken.emit(amount)
	
	if new_hp <= 0:
		_respawn()
	return amount

func _respawn():
	await get_tree().create_timer(1.5).timeout
	set_meta("hp", get_meta("max_hp", 500))
	var lbl = get_node_or_null("HPLabel")
	if lbl: lbl.text = "%d/%d" % [get_meta("hp"), get_meta("max_hp")]

func get_health_component(): return null
"""

func _on_dummy_hit(dummy: Node, amount: int) -> void:
	total_damage += amount
	hits_count += 1
	var did = dummy.get_meta("id", 0)
	_log("[color=orange]💥 Dummy#%d: -%d[/color]" % [did, amount])
	_spawn_damage_number(dummy.global_position, amount)

func _spawn_damage_number(pos: Vector2, amount: int) -> void:
	var lbl = Label.new()
	lbl.text = "-%d" % amount
	lbl.global_position = pos + Vector2(randf_range(-15, 15), -35)
	lbl.z_index = 200
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.ORANGE)
	add_child(lbl)
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 40, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(lbl.queue_free)

# ═══════════════════════════════════════════════════════════════════════════════
# UI - CREACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _create_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)
	
	_create_upgrades_panel()
	_create_desc_panel()
	_create_stats_panel()
	_create_weapons_panel()
	_create_fusion_panel()
	_create_applied_panel()
	_create_log_panel()

func _make_panel(rect: Rect2, title: String, title_color: Color = Color.WHITE) -> Panel:
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	p.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(p)
	
	var t = Label.new()
	t.text = title
	t.position = Vector2(10, 5)
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", title_color)
	p.add_child(t)
	return p

func _create_upgrades_panel() -> void:
	var p = _make_panel(LEFT_PANEL, "🧪 MEJORAS", Color.GOLD)
	
	# Botones categoría
	var btns = HBoxContainer.new()
	btns.position = Vector2(8, 28)
	p.add_child(btns)
	var cats = [["1", UpgradeSource.PLAYER], ["2", UpgradeSource.WEAPON_GLOBAL], ["3", UpgradeSource.WEAPON_SPECIFIC]]
	for c in cats:
		var b = Button.new()
		b.text = c[0]
		b.custom_minimum_size = Vector2(30, 22)
		b.add_theme_font_size_override("font_size", 10)
		b.pressed.connect(_on_category.bind(c[1]))
		btns.add_child(b)
	
	var cat_lbl = Label.new()
	cat_lbl.name = "CatLabel"
	cat_lbl.text = "Jugador (%d)" % all_player_upgrades.size()
	cat_lbl.position = Vector2(110, 30)
	cat_lbl.add_theme_font_size_override("font_size", 11)
	cat_lbl.add_theme_color_override("font_color", Color.CYAN)
	p.add_child(cat_lbl)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(5, 55)
	scroll.size = Vector2(LEFT_PANEL.size.x - 10, LEFT_PANEL.size.y - 60)
	p.add_child(scroll)
	
	upgrade_list = VBoxContainer.new()
	upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(upgrade_list)
	
	_populate_upgrade_list()

func _create_desc_panel() -> void:
	var p = _make_panel(DESC_PANEL, "📋 MEJORA SELECCIONADA", Color.CYAN)
	desc_label = RichTextLabel.new()
	desc_label.position = Vector2(8, 25)
	desc_label.size = Vector2(DESC_PANEL.size.x - 16, DESC_PANEL.size.y - 30)
	desc_label.bbcode_enabled = true
	desc_label.scroll_active = false
	p.add_child(desc_label)

func _create_stats_panel() -> void:
	var p = _make_panel(STATS_PANEL, "📊 STATS DEL JUGADOR", Color.YELLOW)
	stats_label = RichTextLabel.new()
	stats_label.position = Vector2(8, 25)
	stats_label.size = Vector2(STATS_PANEL.size.x - 16, STATS_PANEL.size.y - 30)
	stats_label.bbcode_enabled = true
	p.add_child(stats_label)

func _create_weapons_panel() -> void:
	var p = _make_panel(WEAPONS_PANEL, "⚔️ ARMAS EQUIPADAS (TAB añadir, DEL quitar)", Color.ORANGE)
	
	weapons_container = HBoxContainer.new()
	weapons_container.position = Vector2(10, 30)
	p.add_child(weapons_container)
	
	# Crear 6 slots
	for i in range(6):
		var slot = _create_weapon_slot(i)
		weapons_container.add_child(slot)
	
	# Lista de armas disponibles
	var avail_lbl = Label.new()
	avail_lbl.text = "Armas: " + ", ".join(available_weapons.slice(0, 5)) + "..."
	avail_lbl.position = Vector2(10, 110)
	avail_lbl.add_theme_font_size_override("font_size", 9)
	avail_lbl.add_theme_color_override("font_color", Color.GRAY)
	p.add_child(avail_lbl)
	
	# Instrucciones
	var help = Label.new()
	help.text = "← → seleccionar slot | F1-F10 equipar arma"
	help.position = Vector2(10, 130)
	help.add_theme_font_size_override("font_size", 9)
	help.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	p.add_child(help)

func _create_weapon_slot(idx: int) -> Panel:
	var slot = Panel.new()
	slot.name = "Slot_%d" % idx
	slot.custom_minimum_size = Vector2(50, 70)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(1)
	slot.add_theme_stylebox_override("panel", style)
	
	var icon = Label.new()
	icon.name = "Icon"
	icon.text = "—"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.position = Vector2(0, 10)
	icon.size = Vector2(50, 30)
	icon.add_theme_font_size_override("font_size", 20)
	slot.add_child(icon)
	
	var name_lbl = Label.new()
	name_lbl.name = "Name"
	name_lbl.text = "vacío"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0, 45)
	name_lbl.size = Vector2(50, 20)
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", Color.GRAY)
	slot.add_child(name_lbl)
	
	return slot

func _create_fusion_panel() -> void:
	var p = _make_panel(FUSION_PANEL, "🔥 FUSIÓN (F para fusionar slots)", Color.MAGENTA)
	
	fusion_label = RichTextLabel.new()
	fusion_label.position = Vector2(8, 25)
	fusion_label.size = Vector2(FUSION_PANEL.size.x - 16, FUSION_PANEL.size.y - 30)
	fusion_label.bbcode_enabled = true
	fusion_label.text = "[color=gray]Selecciona 2 armas con SHIFT+←→\npara ver fusiones disponibles[/color]"
	p.add_child(fusion_label)

func _create_applied_panel() -> void:
	var p = _make_panel(APPLIED_PANEL, "✅ MEJORAS APLICADAS", Color.GREEN)
	applied_label = RichTextLabel.new()
	applied_label.position = Vector2(8, 25)
	applied_label.size = Vector2(APPLIED_PANEL.size.x - 16, APPLIED_PANEL.size.y - 30)
	applied_label.bbcode_enabled = true
	applied_label.text = "[color=gray]Ninguna[/color]"
	p.add_child(applied_label)

func _create_log_panel() -> void:
	var p = _make_panel(LOG_PANEL, "📝 LOG DE DAÑO", Color.ORANGE)
	
	dps_label = Label.new()
	dps_label.name = "DPS"
	dps_label.text = "DPS: 0 | Hits: 0 | Total: 0"
	dps_label.position = Vector2(150, 5)
	dps_label.add_theme_font_size_override("font_size", 10)
	dps_label.add_theme_color_override("font_color", Color.CYAN)
	p.add_child(dps_label)
	
	log_label = RichTextLabel.new()
	log_label.position = Vector2(8, 25)
	log_label.size = Vector2(LOG_PANEL.size.x - 16, LOG_PANEL.size.y - 30)
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	p.add_child(log_label)

# ═══════════════════════════════════════════════════════════════════════════════
# LISTA DE MEJORAS
# ═══════════════════════════════════════════════════════════════════════════════

func _populate_upgrade_list() -> void:
	for c in upgrade_list.get_children():
		c.queue_free()
	upgrade_items.clear()
	
	var upgrades = _get_current_upgrades()
	for i in range(upgrades.size()):
		var item = _create_upgrade_item(upgrades[i], i)
		upgrade_list.add_child(item)
		upgrade_items.append(item)
	
	# Update category label
	var cat_lbl = ui_layer.get_node_or_null("Panel/CatLabel")
	if cat_lbl:
		var names = {
			UpgradeSource.PLAYER: "Jugador",
			UpgradeSource.WEAPON_GLOBAL: "Armas Global",
			UpgradeSource.WEAPON_SPECIFIC: "Específicas"
		}
		cat_lbl.text = "%s (%d)" % [names.get(current_category, "?"), upgrades.size()]

func _create_upgrade_item(upgrade: Dictionary, idx: int) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.name = "Item_%d" % idx
	h.custom_minimum_size = Vector2(280, 22)
	
	var arrow = Label.new()
	arrow.name = "Arrow"
	arrow.text = "  "
	arrow.custom_minimum_size = Vector2(18, 0)
	arrow.add_theme_font_size_override("font_size", 11)
	arrow.add_theme_color_override("font_color", Color.YELLOW)
	h.add_child(arrow)
	
	var icon = Label.new()
	icon.text = upgrade.get("icon", "?")
	icon.custom_minimum_size = Vector2(20, 0)
	h.add_child(icon)
	
	var nm = Label.new()
	nm.name = "Name"
	nm.text = upgrade.get("name", "???")
	nm.custom_minimum_size = Vector2(180, 0)
	nm.clip_text = true
	nm.add_theme_font_size_override("font_size", 11)
	var tier = upgrade.get("tier", 1)
	nm.add_theme_color_override("font_color", _tier_color(tier, upgrade))
	h.add_child(nm)
	
	var t = Label.new()
	t.text = "T%d" % tier
	t.add_theme_font_size_override("font_size", 9)
	t.add_theme_color_override("font_color", _tier_color(tier, upgrade))
	h.add_child(t)
	
	return h

func _tier_color(tier: int, upgrade: Dictionary = {}) -> Color:
	if upgrade.get("is_cursed", false): return Color(0.7, 0.2, 0.8)
	if upgrade.get("is_unique", false): return Color(1.0, 0.3, 0.3)
	match tier:
		1: return Color(0.8, 0.8, 0.8)
		2: return Color(0.3, 0.9, 0.3)
		3: return Color(0.4, 0.6, 1.0)
		4: return Color(1.0, 0.85, 0.2)
		5: return Color(1.0, 0.5, 0.1)
	return Color.WHITE

func _get_current_upgrades() -> Array:
	match current_category:
		UpgradeSource.PLAYER: return all_player_upgrades
		UpgradeSource.WEAPON_GLOBAL: return all_weapon_global_upgrades
		UpgradeSource.WEAPON_SPECIFIC: return all_weapon_specific_upgrades
	return []

func _select_upgrade(idx: int) -> void:
	var upgrades = _get_current_upgrades()
	if upgrades.is_empty(): return
	selected_upgrade_idx = clampi(idx, 0, upgrades.size() - 1)
	
	# Update arrows
	for i in range(upgrade_items.size()):
		var arr = upgrade_items[i].get_node_or_null("Arrow")
		if arr:
			arr.text = "▶" if i == selected_upgrade_idx else "  "
	
	_update_description()

func _on_category(cat: UpgradeSource) -> void:
	current_category = cat
	selected_upgrade_idx = 0
	_populate_upgrade_list()
	_select_upgrade(0)
	_log("[color=cyan]Categoría cambiada[/color]")

# ═══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN DE UI
# ═══════════════════════════════════════════════════════════════════════════════

func _update_all_ui() -> void:
	_update_description()
	_update_stats_display()
	_update_weapons_display()
	_update_applied_display()

func _update_description() -> void:
	var upgrades = _get_current_upgrades()
	if upgrades.is_empty() or selected_upgrade_idx >= upgrades.size():
		desc_label.text = "[color=gray]Sin mejoras[/color]"
		return
	
	var u = upgrades[selected_upgrade_idx]
	var txt = "[b]%s %s[/b]\n" % [u.get("icon", ""), u.get("name", "?")]
	txt += "%s\n" % u.get("description", "")
	txt += "[color=cyan]Efectos:[/color] "
	var effs = []
	for e in u.get("effects", []):
		var op = "+" if e.get("operation", "add") == "add" else "×"
		effs.append("%s%s%.2f" % [e.get("stat", "?"), op, e.get("value", 0)])
	txt += "[color=gray]%s[/color]" % ", ".join(effs)
	desc_label.text = txt

func _update_stats_display() -> void:
	var txt = "[color=cyan]═ JUGADOR ═[/color]\n"
	
	var p_stats = [
		["max_health", "❤️ Vida"],
		["health_regen", "💚 Regen"],
		["armor", "🛡️ Armadura"],
		["damage_taken_mult", "📉 Daño Recib×"],
		["dodge_chance", "💨 Esquivar"],
		["life_steal", "🩸 Robo"],
		["thorns", "🌵 Espinas+"],
		["thorns_percent", "🌵 Espinas%"],
		["move_speed", "🏃 Velocidad"],
		["pickup_range", "🧲 Recogida"],
		["xp_mult", "⭐ XP"],
		["luck", "🍀 Suerte"],
		["growth", "📈 Crecimiento"],
	]
	for s in p_stats:
		var val = _get_player_stat(s[0])
		txt += "%s: [color=white]%.2f[/color]\n" % [s[1], val]
	
	# Mostrar tiempo de juego para Growth
	if player_stats and "_game_time_minutes" in player_stats:
		var mins = player_stats._game_time_minutes
		txt += "[color=gray]⏱️ Tiempo: %.1f min[/color]\n" % mins
	
	txt += "\n[color=yellow]═ OFENSIVO (PlayerStats) ═[/color]\n"
	var offensive_stats = [
		["damage_mult", "⚔️ Daño×"],
		["damage_flat", "➕ Daño+"],
		["attack_speed_mult", "⚡ Vel.Atq"],
		["area_mult", "🌀 Área"],
		["crit_chance", "🎯 Crit%"],
		["crit_damage", "💢 CritDmg"],
		["extra_projectiles", "🎯 Proyec+"],
		["chain_count", "⛓️ Cadena"],
		["execute_threshold", "⚰️ Ejecutar%"],
		["explosion_chance", "💣 Explos%"],
	]
	for s in offensive_stats:
		var val = _get_player_stat(s[0])
		txt += "%s: [color=white]%.2f[/color]\n" % [s[1], val]
	
	stats_label.text = txt

func _update_weapons_display() -> void:
	var weapons = _get_equipped_weapons()
	for i in range(6):
		var slot = weapons_container.get_node_or_null("Slot_%d" % i)
		if not slot: continue
		
		var icon_lbl = slot.get_node_or_null("Icon")
		var name_lbl = slot.get_node_or_null("Name")
		var style = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		
		if i < weapons.size() and weapons[i] != null:
			var w = weapons[i]
			var wdata = WeaponDatabase.get_weapon_data(w.id)
			icon_lbl.text = wdata.get("icon", "⚔")
			name_lbl.text = w.id.substr(0, 6)
			name_lbl.add_theme_color_override("font_color", Color.WHITE)
			style.bg_color = Color(0.2, 0.25, 0.3)
		else:
			icon_lbl.text = "—"
			name_lbl.text = "vacío"
			name_lbl.add_theme_color_override("font_color", Color.GRAY)
			style.bg_color = Color(0.15, 0.15, 0.2)
		
		# Highlight selected slot
		if i == selected_weapon_slot:
			style.border_color = Color.YELLOW
			style.set_border_width_all(2)
		else:
			style.border_color = Color(0.4, 0.4, 0.5)
			style.set_border_width_all(1)
		
		slot.add_theme_stylebox_override("panel", style)
	
	_update_fusion_display()

func _update_fusion_display() -> void:
	var weapons = _get_equipped_weapons()
	if fusion_slot_a < 0 or fusion_slot_b < 0:
		fusion_label.text = "[color=gray]Selecciona slot con ← →\nMarca para fusión con SHIFT+← o SHIFT+→[/color]"
		return
	
	if fusion_slot_a >= weapons.size() or fusion_slot_b >= weapons.size():
		fusion_label.text = "[color=red]Slots vacíos seleccionados[/color]"
		return
	
	var wa = weapons[fusion_slot_a]
	var wb = weapons[fusion_slot_b]
	if wa == null or wb == null:
		fusion_label.text = "[color=red]Armas no válidas[/color]"
		return
	
	var result = WeaponDatabase.get_fusion_result(wa.id, wb.id)
	if not result.is_empty():
		var result_id = result.get("id", "")
		fusion_label.text = "[color=green]✓ Fusión disponible:[/color]\n"
		fusion_label.text += "%s + %s = [color=yellow]%s %s[/color]\n" % [wa.id, wb.id, result.get("icon", "?"), result_id]
		fusion_label.text += "[color=cyan]Presiona F para fusionar[/color]"
	else:
		fusion_label.text = "[color=red]✗ No se pueden fusionar[/color]\n%s + %s" % [wa.id, wb.id]

func _update_applied_display() -> void:
	if applied_upgrades.is_empty():
		applied_label.text = "[color=gray]Ninguna[/color]"
		return
	var txt = ""
	for i in range(mini(applied_upgrades.size(), 8)):
		var u = applied_upgrades[i]
		txt += "%s %s\n" % [u.get("icon", ""), u.get("name", "?")]
	if applied_upgrades.size() > 8:
		txt += "[color=gray]+%d más[/color]" % (applied_upgrades.size() - 8)
	applied_label.text = txt

func _get_player_stat(stat: String) -> float:
	if player_stats and player_stats.has_method("get_stat"):
		return player_stats.get_stat(stat)
	return 0.0

func _get_weapon_stat(stat: String) -> float:
	if global_weapon_stats and global_weapon_stats.has_method("get_stat"):
		return global_weapon_stats.get_stat(stat)
	return 0.0

func _log(msg: String) -> void:
	if log_label:
		var t = "%.1f" % (Time.get_ticks_msec() / 1000.0 - start_time)
		log_label.append_text("[%s] %s\n" % [t, msg])

# ═══════════════════════════════════════════════════════════════════════════════
# APLICACIÓN DE MEJORAS
# ═══════════════════════════════════════════════════════════════════════════════

func _apply_selected_upgrade() -> void:
	var upgrades = _get_current_upgrades()
	if upgrades.is_empty() or selected_upgrade_idx >= upgrades.size():
		return
	
	var u = upgrades[selected_upgrade_idx]
	_log("[color=yellow]▶ Aplicando: %s %s[/color]" % [u.get("icon", ""), u.get("name", "?")])
	
	var ok = false
	match current_category:
		UpgradeSource.PLAYER:
			if player_stats and player_stats.has_method("apply_upgrade"):
				ok = player_stats.apply_upgrade(u)
		UpgradeSource.WEAPON_GLOBAL:
			if attack_manager and attack_manager.has_method("apply_global_upgrade"):
				attack_manager.apply_global_upgrade(u)
				ok = true
			elif global_weapon_stats and global_weapon_stats.has_method("apply_upgrade"):
				ok = global_weapon_stats.apply_upgrade(u)
		UpgradeSource.WEAPON_SPECIFIC:
			var weaps = _get_equipped_weapons()
			if selected_weapon_slot >= 0 and selected_weapon_slot < weaps.size():
				var w = weaps[selected_weapon_slot]
				if w and w.has_method("apply_upgrade"):
					w.apply_upgrade(u)
					ok = true
					_log("[color=green]  ✓ Aplicada a %s[/color]" % w.id)
			else:
				_log("[color=red]  ✗ Selecciona un slot de arma primero[/color]")
				return
	
	if ok:
		applied_upgrades.append(u)
		_log("[color=green]  ✓ Aplicada[/color]")
	else:
		_log("[color=red]  ✗ Error al aplicar[/color]")
	
	_update_all_ui()

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE ARMAS
# ═══════════════════════════════════════════════════════════════════════════════

func _get_equipped_weapons() -> Array:
	"""Obtener armas del AttackManager (fuente única de verdad)"""
	if attack_manager and attack_manager.has_method("get_weapons"):
		return attack_manager.get_weapons()
	return []

func _equip_weapon(weapon_id: String) -> void:
	var current = _get_equipped_weapons()
	if current.size() >= 6:
		_log("[color=red]✗ Sin slots disponibles[/color]")
		return
	
	# Check if already equipped
	for w in current:
		if w and w.id == weapon_id:
			_log("[color=yellow]⚠ %s ya está equipada[/color]" % weapon_id)
			return
	
	# Usar AttackManager para crear y añadir
	if attack_manager and attack_manager.has_method("add_weapon_by_id"):
		var success = attack_manager.add_weapon_by_id(weapon_id)
		if success:
			selected_weapon_slot = _get_equipped_weapons().size() - 1
			_log("[color=green]✓ Equipada: %s[/color]" % weapon_id)
		else:
			_log("[color=red]✗ No se pudo equipar arma[/color]")
	else:
		_log("[color=red]✗ AttackManager no disponible[/color]")
	
	_update_weapons_display()

func _unequip_weapon(slot: int) -> void:
	var weapons = _get_equipped_weapons()
	if slot < 0 or slot >= weapons.size():
		return
	var w = weapons[slot]
	if attack_manager and attack_manager.has_method("remove_weapon"):
		attack_manager.remove_weapon(w)
	_log("[color=orange]✗ Desequipada: %s[/color]" % (w.id if w else "?"))
	
	var new_weapons = _get_equipped_weapons()
	if selected_weapon_slot >= new_weapons.size():
		selected_weapon_slot = new_weapons.size() - 1
	
	_update_weapons_display()

func _fuse_weapons() -> void:
	var weapons = _get_equipped_weapons()
	
	if fusion_slot_a < 0 or fusion_slot_b < 0:
		_log("[color=red]✗ Selecciona 2 armas para fusionar[/color]")
		return
	
	if fusion_slot_a >= weapons.size() or fusion_slot_b >= weapons.size():
		_log("[color=red]✗ Slots inválidos[/color]")
		return
	
	if fusion_slot_a == fusion_slot_b:
		_log("[color=red]✗ Selecciona 2 armas diferentes[/color]")
		return
	
	var wa = weapons[fusion_slot_a]
	var wb = weapons[fusion_slot_b]
	
	if wa == null or wb == null:
		_log("[color=red]✗ Armas no válidas[/color]")
		return
	
	# Verificar tipos antes de fusionar
	if not wa is BaseWeapon:
		_log("[color=red]✗ %s no es BaseWeapon (legacy)[/color]" % wa.id)
		return
	if not wb is BaseWeapon:
		_log("[color=red]✗ %s no es BaseWeapon (legacy)[/color]" % wb.id)
		return
	
	var fusion_data = WeaponDatabase.get_fusion_result(wa.id, wb.id)
	if fusion_data.is_empty():
		_log("[color=red]✗ No existe fusión para %s + %s[/color]" % [wa.id, wb.id])
		return
	var result_id = fusion_data.get("id", "")
	
	# Perform fusion via AttackManager usando IDs (evita problemas de tipos)
	if attack_manager and attack_manager.has_method("fuse_weapons_by_ids"):
		var fused = attack_manager.fuse_weapons_by_ids(wa.id, wb.id)
		if fused:
			_log("[color=magenta]🔥 FUSIÓN: %s + %s = %s[/color]" % [wa.id, wb.id, fused.id])
		else:
			_log("[color=red]✗ Fusión falló[/color]")
	else:
		_log("[color=red]✗ AttackManager no disponible[/color]")
	
	fusion_slot_a = -1
	fusion_slot_b = -1
	_update_weapons_display()

func _reset_all() -> void:
	_log("[color=red]🔄 RESET[/color]")
	
	if player_stats and player_stats.has_method("_reset_stats"):
		player_stats._reset_stats()
	if global_weapon_stats and global_weapon_stats.has_method("reset"):
		global_weapon_stats.reset()
	
	# Quitar todas las armas del AttackManager
	var weaps = _get_equipped_weapons().duplicate()
	for w in weaps:
		if attack_manager and attack_manager.has_method("remove_weapon"):
			attack_manager.remove_weapon(w)
	
	applied_upgrades.clear()
	total_damage = 0
	hits_count = 0
	fusion_slot_a = -1
	fusion_slot_b = -1
	selected_weapon_slot = -1
	
	for d in dummies:
		if is_instance_valid(d):
			d.set_meta("hp", d.get_meta("max_hp", 500))
			var lbl = d.get_node_or_null("HPLabel")
			if lbl: lbl.text = "%d/%d" % [d.get_meta("hp"), d.get_meta("max_hp")]
	
	_update_all_ui()
	_log("[color=green]✓ Reset completado[/color]")

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_handle_input()
	_update_dps(delta)

var _dps_timer: float = 0.0
func _update_dps(delta: float) -> void:
	_dps_timer += delta
	if _dps_timer >= 0.5:
		_dps_timer = 0.0
		var elapsed = maxf(1.0, Time.get_ticks_msec() / 1000.0 - start_time)
		var dps = total_damage / elapsed
		if dps_label:
			dps_label.text = "DPS: %.0f | Hits: %d | Total: %d" % [dps, hits_count, total_damage]

func _handle_input() -> void:
	# Navigation
	if Input.is_action_just_pressed("ui_up"):
		_select_upgrade(selected_upgrade_idx - 1)
	if Input.is_action_just_pressed("ui_down"):
		_select_upgrade(selected_upgrade_idx + 1)
	if Input.is_action_just_pressed("ui_page_up"):
		_select_upgrade(selected_upgrade_idx - 10)
	if Input.is_action_just_pressed("ui_page_down"):
		_select_upgrade(selected_upgrade_idx + 10)
	
	# Apply upgrade
	if Input.is_action_just_pressed("ui_accept"):
		_apply_selected_upgrade()
	
	# Categories
	if _just_pressed(KEY_1): _on_category(UpgradeSource.PLAYER)
	if _just_pressed(KEY_2): _on_category(UpgradeSource.WEAPON_GLOBAL)
	if _just_pressed(KEY_3): _on_category(UpgradeSource.WEAPON_SPECIFIC)
	
	# Weapon slot selection
	if Input.is_action_just_pressed("ui_left"):
		if Input.is_key_pressed(KEY_SHIFT):
			fusion_slot_a = maxi(0, selected_weapon_slot)
			_log("[color=magenta]Fusión A: slot %d[/color]" % fusion_slot_a)
		else:
			selected_weapon_slot = maxi(0, selected_weapon_slot - 1)
		_update_weapons_display()
	if Input.is_action_just_pressed("ui_right"):
		if Input.is_key_pressed(KEY_SHIFT):
			fusion_slot_b = mini(5, selected_weapon_slot)
			_log("[color=magenta]Fusión B: slot %d[/color]" % fusion_slot_b)
		else:
			selected_weapon_slot = mini(5, selected_weapon_slot + 1)
		_update_weapons_display()
	
	# Equip weapons F1-F10
	if _just_pressed(KEY_F1) and available_weapons.size() > 0: _equip_weapon(available_weapons[0])
	if _just_pressed(KEY_F2) and available_weapons.size() > 1: _equip_weapon(available_weapons[1])
	if _just_pressed(KEY_F3) and available_weapons.size() > 2: _equip_weapon(available_weapons[2])
	if _just_pressed(KEY_F4) and available_weapons.size() > 3: _equip_weapon(available_weapons[3])
	if _just_pressed(KEY_F5) and available_weapons.size() > 4: _equip_weapon(available_weapons[4])
	if _just_pressed(KEY_F6) and available_weapons.size() > 5: _equip_weapon(available_weapons[5])
	if _just_pressed(KEY_F7) and available_weapons.size() > 6: _equip_weapon(available_weapons[6])
	if _just_pressed(KEY_F8) and available_weapons.size() > 7: _equip_weapon(available_weapons[7])
	if _just_pressed(KEY_F9) and available_weapons.size() > 8: _equip_weapon(available_weapons[8])
	if _just_pressed(KEY_F10) and available_weapons.size() > 9: _equip_weapon(available_weapons[9])
	
	# TAB to cycle through weapons
	if _just_pressed(KEY_TAB):
		var current_count = _get_equipped_weapons().size()
		if current_count < available_weapons.size():
			_equip_weapon(available_weapons[current_count % available_weapons.size()])
	
	# Delete to remove weapon
	if _just_pressed(KEY_DELETE) or _just_pressed(KEY_BACKSPACE):
		if selected_weapon_slot >= 0:
			_unequip_weapon(selected_weapon_slot)
	
	# F to fuse
	if _just_pressed(KEY_F):
		_fuse_weapons()
	
	# R to reset
	if _just_pressed(KEY_R):
		_reset_all()
	
	# ESC to exit
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _just_pressed(key: int) -> bool:
	var pressed = Input.is_key_pressed(key)
	var was = _key_held.get(key, false)
	_key_held[key] = pressed
	return pressed and not was
