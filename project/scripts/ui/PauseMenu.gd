# PauseMenu.gd
# Menú de pausa con información completa del jugador
#
# Muestra:
# - Stats del jugador
# - Armas equipadas con sus stats
# - Mejoras recolectadas

extends Control
class_name PauseMenu

signal resume_pressed
signal options_pressed
signal quit_to_menu_pressed

# Referencias externas (se obtienen automáticamente)
var player_stats: PlayerStats = null
var attack_manager: AttackManager = null
var player_ref: Node = null
var experience_manager_ref: Node = null

# Estado
var game_time: float = 0.0
var current_tab: int = 0  # 0=Stats, 1=Armas, 2=Mejoras

# UI Nodes creados dinámicamente
var main_panel: PanelContainer = null
var tabs_container: HBoxContainer = null
var content_container: Control = null
var tab_buttons: Array = []

# Colores
const BG_COLOR = Color(0.0, 0.0, 0.0, 0.85)
const PANEL_BG = Color(0.1, 0.1, 0.15, 0.98)
const SELECTED_TAB = Color(1.0, 0.85, 0.3)
const UNSELECTED_TAB = Color(0.5, 0.5, 0.6)
const STAT_COLOR = Color(0.8, 0.8, 0.9)
const VALUE_COLOR = Color(0.3, 0.9, 0.4)
const RARITY_COLORS = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.4, 0.6, 1.0),
	"epic": Color(0.8, 0.4, 1.0),
	"legendary": Color(1.0, 0.8, 0.2)
}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()

func _create_ui() -> void:
	# Fondo oscuro
	var overlay = ColorRect.new()
	overlay.color = BG_COLOR
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Centro
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Panel principal
	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(900, 600)
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	main_panel.add_theme_stylebox_override("panel", style)
	center.add_child(main_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)

	# === HEADER ===
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var title = Label.new()
	title.text = "⏸️ PAUSA"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", SELECTED_TAB)
	header.add_child(title)

	# Time display
	var time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	header.add_child(time_label)

	# === TABS ===
	tabs_container = HBoxContainer.new()
	tabs_container.add_theme_constant_override("separation", 10)
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(tabs_container)

	var tab_names = ["📊 Stats", "⚔️ Armas", "✨ Mejoras"]
	for i in range(tab_names.size()):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(150, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		btn.focus_mode = Control.FOCUS_ALL
		tabs_container.add_child(btn)
		tab_buttons.append(btn)

	# Separador
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# === CONTENIDO ===
	content_container = Control.new()
	content_container.custom_minimum_size = Vector2(860, 380)
	vbox.add_child(content_container)

	# === BOTONES DE ACCIÓN ===
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	var buttons_row = HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 20)
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_row)

	var resume_btn = Button.new()
	resume_btn.name = "ResumeButton"
	resume_btn.text = "▶️  Continuar"
	resume_btn.custom_minimum_size = Vector2(180, 45)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.pressed.connect(_on_resume_pressed)
	resume_btn.focus_mode = Control.FOCUS_ALL
	buttons_row.add_child(resume_btn)

	var options_btn = Button.new()
	options_btn.text = "⚙️  Opciones"
	options_btn.custom_minimum_size = Vector2(180, 45)
	options_btn.add_theme_font_size_override("font_size", 18)
	options_btn.pressed.connect(_on_options_pressed)
	options_btn.focus_mode = Control.FOCUS_ALL
	buttons_row.add_child(options_btn)

	var quit_btn = Button.new()
	quit_btn.text = "🏠  Menú"
	quit_btn.custom_minimum_size = Vector2(180, 45)
	quit_btn.add_theme_font_size_override("font_size", 18)
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.focus_mode = Control.FOCUS_ALL
	buttons_row.add_child(quit_btn)

	# Help text
	var help = Label.new()
	help.text = "ESC para continuar  |  ← → Cambiar pestaña"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(help)

func initialize(stats: PlayerStats, attack_mgr: AttackManager) -> void:
	player_stats = stats
	attack_manager = attack_mgr

func _find_references() -> void:
	"""Busca referencias a sistemas del juego automáticamente"""
	var tree = get_tree()
	if not tree:
		return

	# Buscar PlayerStats en el árbol
	if not player_stats:
		player_stats = tree.root.get_node_or_null("Game/PlayerStats")
		if not player_stats:
			# Buscar en cualquier lugar
			var nodes = tree.get_nodes_in_group("player_stats")
			if nodes.size() > 0:
				player_stats = nodes[0]

	# Buscar AttackManager
	if not attack_manager:
		attack_manager = tree.root.get_node_or_null("Game/AttackManager")
		if not attack_manager:
			attack_manager = tree.root.get_node_or_null("AttackManager")

	# Buscar Player para obtener stats directamente
	if not player_ref:
		var players = tree.get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
			# Intentar obtener attack_manager del player
			if not attack_manager and player_ref:
				if "wizard_player" in player_ref and player_ref.wizard_player:
					attack_manager = player_ref.wizard_player.attack_manager

	# Buscar ExperienceManager para nivel/XP
	if not experience_manager_ref:
		experience_manager_ref = tree.root.get_node_or_null("Game/ExperienceManager")
		if not experience_manager_ref:
			experience_manager_ref = tree.root.get_node_or_null("ExperienceManager")

func show_pause_menu(current_time: float = 0.0) -> void:
	game_time = current_time
	visible = true
	get_tree().paused = true
	current_tab = 0

	# Obtener referencias automáticamente si no se inicializó
	_find_references()

	_update_time_display()
	_update_tabs_visual()
	_show_tab_content()

	# Focus en primer tab
	if tab_buttons.size() > 0:
		tab_buttons[0].grab_focus()

	# Animación
	modulate.a = 0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_pause_menu() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished

	visible = false
	get_tree().paused = false

func _update_time_display() -> void:
	var time_label = main_panel.find_child("TimeLabel", true, false) as Label
	if time_label:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		time_label.text = "    Tiempo: %02d:%02d" % [minutes, seconds]

func _update_tabs_visual() -> void:
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as Button
		if i == current_tab:
			btn.add_theme_color_override("font_color", SELECTED_TAB)
			btn.add_theme_color_override("font_hover_color", SELECTED_TAB)
		else:
			btn.add_theme_color_override("font_color", UNSELECTED_TAB)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _on_tab_pressed(tab_index: int) -> void:
	current_tab = tab_index
	_update_tabs_visual()
	_show_tab_content()

func _show_tab_content() -> void:
	# Limpiar contenido anterior
	for child in content_container.get_children():
		child.queue_free()

	match current_tab:
		0: _show_stats_tab()
		1: _show_weapons_tab()
		2: _show_upgrades_tab()

# ═══════════════════════════════════════════════════════════════════════════════
# TAB: STATS DEL JUGADOR
# ═══════════════════════════════════════════════════════════════════════════════

func _show_stats_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	# Header
	var header_name = Label.new()
	header_name.text = "ESTADÍSTICA"
	header_name.add_theme_font_size_override("font_size", 14)
	header_name.add_theme_color_override("font_color", SELECTED_TAB)
	grid.add_child(header_name)

	var header_value = Label.new()
	header_value.text = "VALOR"
	header_value.add_theme_font_size_override("font_size", 14)
	header_value.add_theme_color_override("font_color", SELECTED_TAB)
	grid.add_child(header_value)

	# Intentar obtener stats de PlayerStats primero, sino del player directamente
	if player_stats and player_stats.has_method("get_stat"):
		_show_stats_from_player_stats(grid)
	elif player_ref:
		_show_stats_from_player(grid)
	else:
		var no_data = Label.new()
		no_data.text = "No hay datos del jugador disponibles"
		no_data.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5))
		grid.add_child(no_data)
		grid.add_child(Label.new())

	# Nivel y XP (siempre mostrar si hay ExperienceManager)
	_show_level_and_xp(grid)

func _show_stats_from_player_stats(grid: GridContainer) -> void:
	"""Mostrar stats desde PlayerStats (sistema nuevo)"""
	var stats_display = [
		["max_health", "❤️ Vida Máxima", ""],
		["health_regen", "💚 Regeneración", "/s"],
		["move_speed", "🏃 Velocidad", "x"],
		["damage_mult", "⚔️ Daño", "x"],
		["cooldown_mult", "⏱️ Cooldown", "x"],
		["crit_chance", "🎯 Prob. Crítico", "%"],
		["crit_damage", "💥 Daño Crítico", "x"],
		["area_mult", "🌀 Área", "x"],
		["pickup_range", "🧲 Rango Recogida", "x"],
		["xp_mult", "⭐ Multiplicador XP", "x"],
		["coin_value_mult", "🪙 Valor Monedas", "x"],
		["armor", "🛡️ Armadura", ""],
		["luck", "🍀 Suerte", ""]
	]

	for stat_info in stats_display:
		var stat_name = stat_info[0]
		var display_name = stat_info[1]
		var suffix = stat_info[2]

		_add_stat_row(grid, display_name, player_stats.get_stat(stat_name), suffix)

func _show_stats_from_player(grid: GridContainer) -> void:
	"""Mostrar stats directamente desde el player (sistema antiguo)"""
	# Stats disponibles en SpellloopPlayer/WizardPlayer
	var stats_to_show = []

	# HP
	if player_ref.has_method("get_max_hp"):
		stats_to_show.append(["❤️ Vida Máxima", player_ref.get_max_hp(), ""])
	elif "max_hp" in player_ref:
		stats_to_show.append(["❤️ Vida Máxima", player_ref.max_hp, ""])

	if player_ref.has_method("get_hp"):
		stats_to_show.append(["💓 Vida Actual", player_ref.get_hp(), ""])
	elif "hp" in player_ref:
		stats_to_show.append(["💓 Vida Actual", player_ref.hp, ""])

	# Move speed
	if "move_speed" in player_ref:
		stats_to_show.append(["🏃 Velocidad", player_ref.move_speed, ""])

	# Armor
	if "armor" in player_ref:
		stats_to_show.append(["🛡️ Armadura", player_ref.armor, ""])

	# Magnet/Pickup range
	if player_ref.has_method("get_pickup_range"):
		stats_to_show.append(["🧲 Rango Recogida", player_ref.get_pickup_range(), " px"])
	elif "pickup_radius" in player_ref:
		stats_to_show.append(["🧲 Rango Recogida", player_ref.pickup_radius, " px"])

	# Coin value mult
	if player_ref.has_method("get_coin_value_mult"):
		stats_to_show.append(["🪙 Valor Monedas", player_ref.get_coin_value_mult(), "x"])
	elif "coin_value_mult" in player_ref:
		stats_to_show.append(["🪙 Valor Monedas", player_ref.coin_value_mult, "x"])

	for stat in stats_to_show:
		_add_stat_row(grid, stat[0], stat[1], stat[2])

func _add_stat_row(grid: GridContainer, display_name: String, value, suffix: String) -> void:
	"""Añade una fila de stat al grid"""
	var name_label = Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", STAT_COLOR)
	grid.add_child(name_label)

	var value_text = ""
	if suffix == "%":
		value_text = "%.0f%%" % (float(value) * 100)
	elif suffix == "x":
		value_text = "%.2fx" % float(value)
	elif suffix == "/s":
		value_text = "%.1f/s" % float(value)
	else:
		value_text = "%.0f%s" % [value, suffix] if value == int(value) else "%.2f%s" % [value, suffix]

	var value_label = Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", VALUE_COLOR)
	grid.add_child(value_label)

func _show_level_and_xp(grid: GridContainer) -> void:
	"""Mostrar nivel y XP"""
	# Separador
	var sep = HSeparator.new()
	grid.add_child(sep)
	grid.add_child(HSeparator.new())

	var level = 1
	var current_xp = 0.0
	var xp_to_next = 10.0

	# Intentar obtener de PlayerStats
	if player_stats and "level" in player_stats:
		level = player_stats.level
		current_xp = player_stats.current_xp if "current_xp" in player_stats else 0
		xp_to_next = player_stats.xp_to_next_level if "xp_to_next_level" in player_stats else 10
	# O de ExperienceManager
	elif experience_manager_ref:
		level = experience_manager_ref.current_level if "current_level" in experience_manager_ref else 1
		current_xp = experience_manager_ref.current_exp if "current_exp" in experience_manager_ref else 0
		xp_to_next = experience_manager_ref.exp_to_next_level if "exp_to_next_level" in experience_manager_ref else 10

	var level_label = Label.new()
	level_label.text = "📈 Nivel"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", STAT_COLOR)
	grid.add_child(level_label)

	var level_value = Label.new()
	level_value.text = "%d" % level
	level_value.add_theme_font_size_override("font_size", 16)
	level_value.add_theme_color_override("font_color", SELECTED_TAB)
	grid.add_child(level_value)

	var xp_label = Label.new()
	xp_label.text = "⭐ Experiencia"
	xp_label.add_theme_font_size_override("font_size", 16)
	xp_label.add_theme_color_override("font_color", STAT_COLOR)
	grid.add_child(xp_label)

	var xp_value = Label.new()
	xp_value.text = "%.0f / %.0f" % [current_xp, xp_to_next]
	xp_value.add_theme_font_size_override("font_size", 16)
	xp_value.add_theme_color_override("font_color", VALUE_COLOR)
	grid.add_child(xp_value)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB: ARMAS
# ═══════════════════════════════════════════════════════════════════════════════

func _show_weapons_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	if not attack_manager or not attack_manager.has_method("get_weapons"):
		var no_data = Label.new()
		no_data.text = "No hay armas equipadas"
		vbox.add_child(no_data)
		return

	var weapons = attack_manager.get_weapons()

	if weapons.is_empty():
		var no_weapons = Label.new()
		no_weapons.text = "No hay armas equipadas"
		no_weapons.add_theme_font_size_override("font_size", 16)
		no_weapons.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		vbox.add_child(no_weapons)
		return

	for weapon in weapons:
		var weapon_panel = _create_weapon_panel(weapon)
		vbox.add_child(weapon_panel)

func _create_weapon_panel(weapon) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = RARITY_COLORS.get(weapon.rarity if "rarity" in weapon else "common", Color.WHITE)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# Icono
	var icon = Label.new()
	icon.text = weapon.icon if "icon" in weapon else "🔮"
	icon.add_theme_font_size_override("font_size", 36)
	hbox.add_child(icon)

	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	# Nombre y nivel
	var name_label = Label.new()
	var weapon_name = weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.weapon_name if "weapon_name" in weapon else "Arma"
	name_label.text = "%s  Nv.%d" % [weapon_name, weapon.level if "level" in weapon else 1]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", RARITY_COLORS.get(weapon.rarity if "rarity" in weapon else "common", Color.WHITE))
	info_vbox.add_child(name_label)

	# Stats del arma
	var stats_text = ""
	if "damage" in weapon:
		stats_text += "⚔️%.0f  " % weapon.damage
	if "cooldown" in weapon:
		stats_text += "⏱️%.2fs  " % weapon.cooldown
	if "projectile_count" in weapon and weapon.projectile_count > 1:
		stats_text += "🎯x%d  " % weapon.projectile_count
	if "pierce" in weapon and weapon.pierce > 0:
		stats_text += "🗡️+%d  " % weapon.pierce

	var stats_label = Label.new()
	stats_label.text = stats_text if stats_text != "" else "Sin stats"
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(stats_label)

	return panel

# ═══════════════════════════════════════════════════════════════════════════════
# TAB: MEJORAS
# ═══════════════════════════════════════════════════════════════════════════════

func _show_upgrades_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(grid)

	if not player_stats:
		var no_data = Label.new()
		no_data.text = "No hay mejoras"
		grid.add_child(no_data)
		return

	var upgrades = player_stats.get_collected_upgrades()

	if upgrades.is_empty():
		var no_upgrades = Label.new()
		no_upgrades.text = "Aún no has recogido ninguna mejora"
		no_upgrades.add_theme_font_size_override("font_size", 16)
		no_upgrades.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		grid.add_child(no_upgrades)
		return

	for upgrade in upgrades:
		var upgrade_panel = _create_upgrade_panel(upgrade)
		grid.add_child(upgrade_panel)

func _create_upgrade_panel(upgrade: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 100)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Header con icono y nombre
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var icon = Label.new()
	icon.text = str(upgrade.get("icon", "✨"))
	icon.add_theme_font_size_override("font_size", 24)
	header.add_child(icon)

	var name_label = Label.new()
	name_label.text = upgrade.get("name", "???")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", VALUE_COLOR)
	header.add_child(name_label)

	# Descripción
	var desc = Label.new()
	desc.text = upgrade.get("description", "")
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC o Pause para cerrar
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
		return

	# Navegación de tabs con flechas
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_change_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_change_tab(1)
		get_viewport().set_input_as_handled()

func _change_tab(direction: int) -> void:
	current_tab = (current_tab + direction) % tab_buttons.size()
	if current_tab < 0:
		current_tab = tab_buttons.size() - 1
	_update_tabs_visual()
	_show_tab_content()
	if tab_buttons.size() > current_tab:
		tab_buttons[current_tab].grab_focus()

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS DE BOTONES
# ═══════════════════════════════════════════════════════════════════════════════

func _on_resume_pressed() -> void:
	_play_button_sound()
	resume_pressed.emit()
	hide_pause_menu()

func _on_options_pressed() -> void:
	_play_button_sound()
	options_pressed.emit()
	# TODO: Mostrar opciones

func _on_quit_pressed() -> void:
	_play_button_sound()
	quit_to_menu_pressed.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _play_button_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")
