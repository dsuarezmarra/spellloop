extends CanvasLayer
class_name GameHUD

# Referencias a nodos
var player_stats: Label
var weapon_list: Label
var timer_label: Label
var levelup_popup: Control
var upgrade_buttons: Array
var streak_label: Label
var shop_button: Button
var meta_label: Label
var gold_label: Label
var boss_bar: ProgressBar
var boss_name_label: Label
var boss_target: Node = null
var boss_update_timer: Timer = null

# Señales
signal upgrade_selected(upgrade: Dictionary)

func _ready():
	player_stats = get_node_or_null("HUDPanel/HBox/VBoxLeft/PlayerStats")
	weapon_list = get_node_or_null("HUDPanel/HBox/VBoxLeft/WeaponList")
	timer_label = get_node_or_null("HUDPanel/HBox/VBoxRight/TimerLabel")
	# Añadir dinámicamente label y botón para streak/shop si no existen en escena
	var right_box = get_node_or_null("HUDPanel/HBox/VBoxRight")
	if right_box:
		if not right_box.has_node("StreakLabel"):
			streak_label = Label.new()
			streak_label.name = "StreakLabel"
			streak_label.text = "Streak: 0"
			right_box.add_child(streak_label)
		else:
			streak_label = right_box.get_node("StreakLabel")

		if not right_box.has_node("ShopButton"):
			shop_button = Button.new()
			shop_button.name = "ShopButton"
			shop_button.text = "Meta-Shop"
			right_box.add_child(shop_button)
			shop_button.pressed.connect(_on_shop_pressed)
		else:
			shop_button = right_box.get_node("ShopButton")

		# Meta currency label
		if not right_box.has_node("MetaLabel"):
			meta_label = Label.new()
			meta_label.name = "MetaLabel"
			meta_label.text = "Meta: 0"
			right_box.add_child(meta_label)
		else:
			meta_label = right_box.get_node("MetaLabel")

			# Gold label
			if not right_box.has_node("GoldLabel"):
				gold_label = Label.new()
				gold_label.name = "GoldLabel"
				gold_label.text = "Gold: 0"
				right_box.add_child(gold_label)
			else:
				gold_label = right_box.get_node("GoldLabel")

	# Initialize meta display
	refresh_meta_display()

	# Connect SaveManager meta change signal for live updates
	var _gt = get_tree()
	var sm_node = _gt.root.get_node_or_null("SaveManager") if _gt and _gt.root else null
	if sm_node and sm_node.has_signal("meta_changed"):
		sm_node.connect("meta_changed", Callable(self, "_on_meta_changed"))
	levelup_popup = get_node_or_null("LevelUpPopup")
	upgrade_buttons = []
	if levelup_popup:
		var b1 = levelup_popup.get_node_or_null("LevelUpPanel/LevelUpVBox/UpgradeOptions/UpgradeButton1")
		var b2 = levelup_popup.get_node_or_null("LevelUpPanel/LevelUpVBox/UpgradeOptions/UpgradeButton2")
		var b3 = levelup_popup.get_node_or_null("LevelUpPanel/LevelUpVBox/UpgradeOptions/UpgradeButton3")
		upgrade_buttons = [b1, b2, b3]
		for i in range(upgrade_buttons.size()):
			if upgrade_buttons[i]:
				upgrade_buttons[i].pressed.connect(_on_upgrade_button_pressed.bind(i))
	levelup_popup.visible = false

	# Setup boss bar UI (dynamic safe fallback)
	_setup_boss_bar()

	set_process(true)

func _setup_boss_bar():
	# Create boss name label and progress bar under HUDPanel if not present
	var panel = get_node_or_null("HUDPanel")
	if not panel:
		panel = self
	# Boss name label
	if not panel.has_node("BossNameLabel"):
		boss_name_label = Label.new()
		boss_name_label.name = "BossNameLabel"
		boss_name_label.text = ""
		boss_name_label.visible = false
		boss_name_label.anchor_left = 0.25
		boss_name_label.anchor_right = 0.75
		boss_name_label.anchor_top = 0.0
		boss_name_label.anchor_bottom = 0.0
		boss_name_label.offset_top = 4
		panel.add_child(boss_name_label)
	else:
		boss_name_label = panel.get_node("BossNameLabel")

	# Boss progress bar
	if not panel.has_node("BossHPBar"):
		boss_bar = ProgressBar.new()
		boss_bar.name = "BossHPBar"
		boss_bar.min_value = 0
		boss_bar.max_value = 100
		boss_bar.value = 100
		boss_bar.visible = false
		boss_bar.anchor_left = 0.25
		boss_bar.anchor_right = 0.75
		boss_bar.anchor_top = 0.03
		boss_bar.anchor_bottom = 0.08
		boss_bar.offset_top = 24
		boss_bar.offset_bottom = 44
		panel.add_child(boss_bar)
	else:
		boss_bar = panel.get_node("BossHPBar")

func show_boss_bar(boss_node: Node, display_name: String = "BOSS") -> void:
	# Start showing boss HP bar and polling
	if not boss_node:
		return
	boss_target = boss_node
	boss_name_label.text = str(display_name)
	boss_name_label.visible = true
	boss_bar.visible = true
	# Initialize values if possible
	if boss_target.has_method("get_info"):
		var info = boss_target.get_info()
		boss_bar.max_value = int(info.get("max_hp", boss_bar.max_value))
		boss_bar.value = int(info.get("hp", boss_bar.max_value))

	# Connect to death signal if available
	if boss_target.has_signal("enemy_died"):
		# connect to hide the bar on death
		boss_target.connect("enemy_died", Callable(self, "_on_boss_died"))

	# Start or create update timer
	if not boss_update_timer:
		boss_update_timer = Timer.new()
		boss_update_timer.name = "BossUpdateTimer"
		boss_update_timer.wait_time = 0.15
		boss_update_timer.one_shot = false
		add_child(boss_update_timer)
		boss_update_timer.timeout.connect(Callable(self, "_update_boss_bar"))
	boss_update_timer.start()

func hide_boss_bar() -> void:
	if boss_update_timer and boss_update_timer.is_stopped() == false:
		boss_update_timer.stop()
	boss_target = null
	boss_name_label.visible = false
	boss_bar.visible = false

func _update_boss_bar() -> void:
	if not boss_target or not is_instance_valid(boss_target):
		hide_boss_bar()
		return
	if boss_target.has_method("get_info"):
		var info = boss_target.get_info()
		boss_bar.max_value = int(info.get("max_hp", boss_bar.max_value))
		boss_bar.value = int(info.get("hp", boss_bar.max_value))

func _on_boss_died(_enemy_node = null, _enemy_type = "", _exp_value = 0) -> void:
	# Boss died; hide UI
	hide_boss_bar()

func update_stats(hp: int, max_hp: int, xp: int, xp_to_level: int, level: int):
	player_stats.text = "HP: %d/%d  XP: %d/%d  LVL: %d" % [hp, max_hp, xp, xp_to_level, level]

func update_weapons(weapons: Array):
	var names = []
	for w in weapons:
		if typeof(w) == TYPE_DICTIONARY:
			names.append(w.get("name", "?"))
		else:
			names.append(str(w))
	weapon_list.text = "Armas: %s" % ", ".join(names)

func update_timer(seconds: int):
	var mins = int(float(seconds) / 60.0)
	var sec = int(seconds) % 60
	timer_label.text = "Tiempo: %02d:%02d" % [mins, sec]

func show_levelup_popup(upgrades: Array):
	levelup_popup.visible = true
	for i in range(3):
		if i < upgrades.size():
			upgrade_buttons[i].text = upgrades[i].get("name", "Mejora")
			upgrade_buttons[i].set_meta("upgrade_data", upgrades[i])
			upgrade_buttons[i].visible = true
		else:
			upgrade_buttons[i].visible = false

func hide_levelup_popup():
	levelup_popup.visible = false

func _on_upgrade_button_pressed(idx):
	var upgrade = upgrade_buttons[idx].get_meta("upgrade_data")
	hide_levelup_popup()
	upgrade_selected.emit(upgrade)

func set_streak(count: int):
	if streak_label:
		streak_label.text = "Streak: %d" % [count]

func _on_shop_pressed():
	# Open MetaShop scene (instanced on demand) if it exists
	var shop_path = "res://scenes/ui/MetaShop.tscn"
	if ResourceLoader.exists(shop_path):
		var shop_scene = ResourceLoader.load(shop_path)
		var inst = shop_scene.instantiate() if shop_scene else null
		if inst:
			get_tree().current_scene.add_child(inst)
			# connect purchase signal to update HUD
			if inst.has_signal("purchase_made"):
				inst.connect("purchase_made", Callable(self, "_on_purchase_made"))
	else:
		print("[GameHUD] MetaShop scene not found: ", shop_path)

func _on_purchase_made(_cost: int, _luck_points: int):
	# Refresh HUD values (simple approach: if UIManager provides metadata refresh it, otherwise no-op)
	refresh_meta_display()
	var _gt2 = get_tree()
	var ui = _gt2.root.get_node_or_null("UIManager") if _gt2 and _gt2.root else null
	if ui and ui.has_method("refresh_meta_display"):
		ui.refresh_meta_display()

func refresh_meta_display():
	var currency = 0
	var _gt3 = get_tree()
	var sm = _gt3.root.get_node_or_null("SaveManager") if _gt3 and _gt3.root else null
	if sm and sm.has_method("get_player_progression"):
		var pd = sm.get_player_progression()
		currency = int(pd.get("meta_currency", 0))
	if meta_label:
		meta_label.text = "Meta: %d" % [currency]

 	# Refresh gold display from SaveManager (authoritative)
	var gold_val = 0
	var _gt4 = get_tree()
	var sm2 = _gt4.root.get_node_or_null("SaveManager") if _gt4 and _gt4.root else null
	if sm2 and sm2.has_method("get_player_progression"):
		var pd2 = sm2.get_player_progression()
		gold_val = int(pd2.get("meta_currency", 0))
	if gold_label:
		gold_label.text = "Gold: %d" % [gold_val]

func add_gold(_amount: int):
	# Update gold display after collection (best-effort, authoritative value read from SaveManager)
	refresh_meta_display()

func _on_meta_changed(key: String, _value) -> void:
	# Update HUD elements based on meta changes
	if key == "luck_points":
		# Optionally reflect luck in HUD tooltip later
		return
	# Full meta update or currency change
	refresh_meta_display()

func show_wave_message(text: String, duration: float = 4.0) -> void:
	# Create a temporary label at top-center to show wave/boss messages
	var existing = get_node_or_null("WaveMessage")
	if existing:
		existing.queue_free()
	var lbl = Label.new()
	lbl.name = "WaveMessage"
	lbl.text = text
	lbl.anchor_left = 0.3
	lbl.anchor_right = 0.7
	lbl.anchor_top = 0.0
	lbl.anchor_bottom = 0.0
	lbl.offset_top = 6
	lbl.add_theme_color_override("font_color", Color(1,0.6,0.2))
	add_child(lbl)
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = duration
	add_child(t)
	t.timeout.connect(func():
		if lbl and lbl.is_inside_tree():
			lbl.queue_free()
		if t and t.is_inside_tree():
			t.queue_free()
	)
	t.start()

## Métodos de actualización para Game.gd

func update_time(game_time: float) -> void:
	if timer_label:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]

func update_level(level: int) -> void:
	_update_player_stats_display()

func update_exp(current_exp: int, exp_to_next: int) -> void:
	_update_player_stats_display()

func update_health(current_hp: int, max_hp: int) -> void:
	_update_player_stats_display()

func _update_player_stats_display() -> void:
	# Actualizar display de stats basado en fuentes disponibles
	if not player_stats:
		return
	
	var hp_str = "HP: ???"
	var xp_str = "XP: ???"
	var lvl_str = "LVL: 1"
	
	# Intentar obtener datos del ExperienceManager y Player
	var tree = get_tree()
	if tree and tree.current_scene:
		# Obtener referencia al player
		var player_container = tree.current_scene.get_node_or_null("PlayerContainer")
		if player_container and player_container.get_child_count() > 0:
			var player = player_container.get_child(0)
			if player and player.has_method("get_health"):
				var health = player.get_health()
				hp_str = "HP: %d/%d" % [health.current, health.max]
			elif player:
				# Fallback: intentar acceso directo a propiedades
				var hp = player.get("hp") if player.get("hp") != null else player.get("health")
				var max_hp = player.get("max_hp") if player.get("max_hp") != null else player.get("max_health")
				if hp != null and max_hp != null:
					hp_str = "HP: %d/%d" % [hp, max_hp]
		
		# Obtener datos del ExperienceManager
		var exp_mgr = tree.current_scene.get_node_or_null("ExperienceManager")
		if exp_mgr:
			var lvl = exp_mgr.get("current_level") if exp_mgr.get("current_level") else 1
			var exp = exp_mgr.get("current_exp") if exp_mgr.get("current_exp") else 0
			var exp_next = exp_mgr.get("exp_to_next_level") if exp_mgr.get("exp_to_next_level") else 10
			xp_str = "XP: %d/%d" % [exp, exp_next]
			lvl_str = "LVL: %d" % lvl
	
	player_stats.text = "%s  %s  %s" % [hp_str, xp_str, lvl_str]
