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

	# Initialize meta display
	refresh_meta_display()
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
	if get_tree() and get_tree().root and get_tree().root.has_node("UIManager"):
		var ui = get_tree().root.get_node("UIManager")
		if ui and ui.has_method("refresh_meta_display"):
			ui.refresh_meta_display()

func refresh_meta_display():
	var currency = 0
	if get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		var sm = get_tree().root.get_node("SaveManager")
		if sm and sm.has_method("get_player_progression"):
			var pd = sm.get_player_progression()
			currency = int(pd.get("meta_currency", 0))
	if meta_label:
		meta_label.text = "Meta: %d" % [currency]
