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
# TAB: STATS DEL JUGADOR (REDISEÑADO)
# ═══════════════════════════════════════════════════════════════════════════════

# Colores por categoría
const CATEGORY_COLORS = {
	"defensive": Color(0.2, 0.7, 0.3),
	"offensive": Color(1.0, 0.4, 0.2),
	"critical": Color(1.0, 0.85, 0.2),
	"utility": Color(0.4, 0.7, 1.0)
}

const CATEGORY_NAMES = {
	"defensive": "🛡️ DEFENSIVO",
	"offensive": "⚔️ OFENSIVO",
	"critical": "💥 CRÍTICOS",
	"utility": "🔧 UTILIDAD"
}

const CATEGORY_ICONS = {
	"defensive": "🛡️",
	"offensive": "⚔️",
	"critical": "💥",
	"utility": "🔧"
}

func _show_stats_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(scroll)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(main_vbox)
	
	# === HEADER CON VIDA Y NIVEL ===
	_create_player_header(main_vbox)
	
	# === GRID DE CATEGORÍAS (2x2) ===
	var categories_grid = GridContainer.new()
	categories_grid.columns = 2
	categories_grid.add_theme_constant_override("h_separation", 15)
	categories_grid.add_theme_constant_override("v_separation", 15)
	main_vbox.add_child(categories_grid)
	
	# Crear panel para cada categoría
	if player_stats and player_stats.has_method("get_stat"):
		for category in ["defensive", "offensive", "critical", "utility"]:
			var category_panel = _create_category_panel(category)
			categories_grid.add_child(category_panel)
	else:
		var no_data = Label.new()
		no_data.text = "No hay datos del jugador disponibles"
		no_data.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5))
		main_vbox.add_child(no_data)
	
	# === BUFFS ACTIVOS ===
	_create_active_buffs_section(main_vbox)

func _create_player_header(parent: VBoxContainer) -> void:
	"""Crear header con vida, nivel y XP"""
	var header_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	header_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(header_panel)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(hbox)
	
	# Obtener datos
	var current_hp = 100
	var max_hp = 100
	var level = 1
	var current_xp = 0.0
	var xp_to_next = 10.0
	
	if player_ref:
		if player_ref.has_method("get_hp"):
			current_hp = player_ref.get_hp()
		elif "hp" in player_ref:
			current_hp = player_ref.hp
		if player_ref.has_method("get_max_hp"):
			max_hp = player_ref.get_max_hp()
		elif "max_hp" in player_ref:
			max_hp = player_ref.max_hp
	
	if player_stats:
		if "level" in player_stats:
			level = player_stats.level
		if "current_xp" in player_stats:
			current_xp = player_stats.current_xp
		if "xp_to_next_level" in player_stats:
			xp_to_next = player_stats.xp_to_next_level
	elif experience_manager_ref:
		if "current_level" in experience_manager_ref:
			level = experience_manager_ref.current_level
		if "current_exp" in experience_manager_ref:
			current_xp = experience_manager_ref.current_exp
		if "exp_to_next_level" in experience_manager_ref:
			xp_to_next = experience_manager_ref.exp_to_next_level
	
	# === VIDA ===
	var hp_vbox = VBoxContainer.new()
	hp_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(hp_vbox)
	
	var hp_label = Label.new()
	hp_label.text = "❤️ VIDA"
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_vbox.add_child(hp_label)
	
	var hp_value = Label.new()
	hp_value.text = "%d / %d" % [current_hp, max_hp]
	hp_value.add_theme_font_size_override("font_size", 20)
	hp_value.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_vbox.add_child(hp_value)
	
	# Barra de vida
	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.custom_minimum_size = Vector2(120, 8)
	hp_bar_bg.color = Color(0.2, 0.15, 0.15)
	hp_vbox.add_child(hp_bar_bg)
	
	var hp_bar = ColorRect.new()
	hp_bar.custom_minimum_size = Vector2(120 * (float(current_hp) / float(max_hp)), 8)
	hp_bar.color = Color(1.0, 0.3, 0.3)
	hp_bar.position = Vector2.ZERO
	hp_bar_bg.add_child(hp_bar)
	
	# === NIVEL ===
	var level_vbox = VBoxContainer.new()
	level_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(level_vbox)
	
	var level_label = Label.new()
	level_label.text = "📈 NIVEL"
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_vbox.add_child(level_label)
	
	var level_value = Label.new()
	level_value.text = "%d" % level
	level_value.add_theme_font_size_override("font_size", 24)
	level_value.add_theme_color_override("font_color", SELECTED_TAB)
	level_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_vbox.add_child(level_value)
	
	# === XP ===
	var xp_vbox = VBoxContainer.new()
	xp_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(xp_vbox)
	
	var xp_label = Label.new()
	xp_label.text = "⭐ EXPERIENCIA"
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_vbox.add_child(xp_label)
	
	var xp_value = Label.new()
	xp_value.text = "%.0f / %.0f" % [current_xp, xp_to_next]
	xp_value.add_theme_font_size_override("font_size", 16)
	xp_value.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	xp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_vbox.add_child(xp_value)
	
	# Barra de XP
	var xp_percent = current_xp / xp_to_next if xp_to_next > 0 else 0
	var xp_bar_bg = ColorRect.new()
	xp_bar_bg.custom_minimum_size = Vector2(150, 6)
	xp_bar_bg.color = Color(0.15, 0.2, 0.15)
	xp_vbox.add_child(xp_bar_bg)
	
	var xp_bar = ColorRect.new()
	xp_bar.custom_minimum_size = Vector2(150 * xp_percent, 6)
	xp_bar.color = Color(0.3, 0.9, 0.4)
	xp_bar.position = Vector2.ZERO
	xp_bar_bg.add_child(xp_bar)

func _create_category_panel(category: String) -> Control:
	"""Crear panel para una categoría de stats"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14)
	style.border_color = CATEGORY_COLORS.get(category, Color.WHITE).darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Header de categoría
	var header = Label.new()
	header.text = CATEGORY_NAMES.get(category, category.to_upper())
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", CATEGORY_COLORS.get(category, Color.WHITE))
	vbox.add_child(header)
	
	# Separador
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", CATEGORY_COLORS.get(category, Color.WHITE).darkened(0.5))
	vbox.add_child(sep)
	
	# Stats de esta categoría
	var stats_in_category = _get_stats_for_category(category)
	
	for stat_name in stats_in_category:
		var stat_row = _create_stat_row_visual(stat_name)
		vbox.add_child(stat_row)
	
	return panel

func _get_stats_for_category(category: String) -> Array:
	"""Obtener stats de una categoría"""
	if player_stats and player_stats.has_method("get_stats_by_category"):
		return player_stats.get_stats_by_category(category)
	
	# Fallback manual
	match category:
		"defensive":
			return ["max_health", "health_regen", "armor", "dodge_chance", "life_steal"]
		"offensive":
			return ["damage_mult", "cooldown_mult", "area_mult", "projectile_speed_mult", "duration_mult", "extra_projectiles", "knockback_mult"]
		"critical":
			return ["crit_chance", "crit_damage"]
		"utility":
			return ["move_speed", "pickup_range", "xp_mult", "coin_value_mult", "luck"]
	return []

func _create_stat_row_visual(stat_name: String) -> Control:
	"""Crear una fila visual para un stat con tooltip"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	
	# Obtener metadatos
	var meta = {}
	if player_stats and player_stats.has_method("get_stat_metadata"):
		meta = player_stats.get_stat_metadata(stat_name)
	else:
		meta = {
			"name": stat_name,
			"icon": "❓",
			"color": Color.WHITE,
			"description": ""
		}
	
	# Icono
	var icon = Label.new()
	icon.text = meta.get("icon", "❓")
	icon.add_theme_font_size_override("font_size", 16)
	icon.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(icon)
	
	# Nombre
	var name_label = Label.new()
	name_label.text = meta.get("name", stat_name)
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Valor
	var value = 0.0
	if player_stats and player_stats.has_method("get_stat"):
		value = player_stats.get_stat(stat_name)
	
	var value_label = Label.new()
	if player_stats and player_stats.has_method("format_stat_value"):
		value_label.text = player_stats.format_stat_value(stat_name, value)
	else:
		value_label.text = _format_stat_value_fallback(stat_name, value)
	
	value_label.add_theme_font_size_override("font_size", 13)
	
	# Color según si es positivo/negativo
	var stat_color = _get_value_color(stat_name, value)
	value_label.add_theme_color_override("font_color", stat_color)
	hbox.add_child(value_label)
	
	# Tooltip con descripción
	if meta.has("description") and meta.description != "":
		hbox.tooltip_text = meta.description
	
	return hbox

func _format_stat_value_fallback(stat_name: String, value: float) -> String:
	"""Formatear valor cuando no hay PlayerStats"""
	if stat_name in ["crit_chance", "dodge_chance", "life_steal"]:
		return "%.0f%%" % (value * 100)
	elif stat_name in ["damage_mult", "cooldown_mult", "area_mult", "move_speed", "pickup_range", "xp_mult", "coin_value_mult", "crit_damage", "projectile_speed_mult", "duration_mult", "knockback_mult"]:
		if value >= 1.0:
			return "+%.0f%%" % ((value - 1.0) * 100)
		else:
			return "%.0f%%" % ((value - 1.0) * 100)
	elif stat_name == "extra_projectiles":
		return "+%d" % int(value)
	else:
		if value == int(value):
			return "%d" % int(value)
		return "%.1f" % value

func _get_value_color(stat_name: String, value: float) -> Color:
	"""Obtener color según el valor del stat"""
	# Para cooldown, menos es mejor
	if stat_name == "cooldown_mult":
		if value < 1.0:
			return Color(0.3, 1.0, 0.4)  # Verde si es menor
		elif value > 1.0:
			return Color(1.0, 0.4, 0.3)  # Rojo si es mayor
		return Color(0.8, 0.8, 0.8)
	
	# Para el resto, más es mejor
	var base_value = 1.0 if stat_name.ends_with("_mult") else 0.0
	if stat_name == "crit_chance":
		base_value = 0.05
	elif stat_name == "crit_damage":
		base_value = 2.0
	elif stat_name == "max_health":
		base_value = 100.0
	
	if value > base_value:
		return Color(0.3, 1.0, 0.4)  # Verde
	elif value < base_value:
		return Color(1.0, 0.4, 0.3)  # Rojo
	return Color(0.8, 0.8, 0.8)  # Gris neutro

func _create_active_buffs_section(parent: VBoxContainer) -> void:
	"""Crear sección de buffs/debuffs activos"""
	if not player_stats:
		return
	
	# Verificar si hay buffs temporales
	var has_temp_modifiers = false
	if "temp_modifiers" in player_stats and not player_stats.temp_modifiers.is_empty():
		has_temp_modifiers = true
	
	if not has_temp_modifiers:
		return
	
	var buffs_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.2)
	style.border_color = Color(0.6, 0.4, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	buffs_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(buffs_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	buffs_panel.add_child(vbox)
	
	var header = Label.new()
	header.text = "✨ EFECTOS ACTIVOS"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	vbox.add_child(header)
	
	var buffs_hbox = HBoxContainer.new()
	buffs_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(buffs_hbox)
	
	for stat_name in player_stats.temp_modifiers:
		for mod in player_stats.temp_modifiers[stat_name]:
			var buff_chip = _create_buff_chip(stat_name, mod)
			buffs_hbox.add_child(buff_chip)

func _create_buff_chip(stat_name: String, mod: Dictionary) -> Control:
	"""Crear chip visual para un buff"""
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	chip.add_child(hbox)
	
	var meta = {}
	if player_stats and player_stats.has_method("get_stat_metadata"):
		meta = player_stats.get_stat_metadata(stat_name)
	
	var icon = Label.new()
	icon.text = meta.get("icon", "✨")
	icon.add_theme_font_size_override("font_size", 14)
	hbox.add_child(icon)
	
	var info = Label.new()
	var amount_text = "+%.0f%%" % (mod.amount * 100) if mod.amount < 1 else "+%.0f" % mod.amount
	info.text = "%s %.1fs" % [amount_text, mod.duration]
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	hbox.add_child(info)
	
	chip.tooltip_text = "%s: %s durante %.1f segundos" % [
		meta.get("name", stat_name),
		amount_text,
		mod.duration
	]
	
	return chip

# ═══════════════════════════════════════════════════════════════════════════════
# TAB: ARMAS (MEJORADO)
# ═══════════════════════════════════════════════════════════════════════════════

# Colores por elemento
const ELEMENT_COLORS = {
	"ice": Color(0.4, 0.8, 1.0),
	"fire": Color(1.0, 0.5, 0.2),
	"lightning": Color(1.0, 1.0, 0.3),
	"arcane": Color(0.7, 0.4, 1.0),
	"shadow": Color(0.5, 0.3, 0.7),
	"nature": Color(0.3, 0.9, 0.4),
	"wind": Color(0.6, 0.9, 0.8),
	"earth": Color(0.7, 0.5, 0.3),
	"light": Color(1.0, 1.0, 0.9),
	"void": Color(0.3, 0.2, 0.5),
	"physical": Color(0.7, 0.7, 0.7)
}

const ELEMENT_ICONS = {
	"ice": "❄️",
	"fire": "🔥",
	"lightning": "⚡",
	"arcane": "💜",
	"shadow": "🗡️",
	"nature": "🌿",
	"wind": "🌪️",
	"earth": "🪨",
	"light": "✨",
	"void": "🕳️",
	"physical": "⚔️"
}

func _show_weapons_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)
	
	# Header con contador de armas
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "⚔️ ARSENAL"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", SELECTED_TAB)
	header.add_child(title)

	if not attack_manager or not attack_manager.has_method("get_weapons"):
		var no_data = Label.new()
		no_data.text = "Sistema de armas no disponible"
		no_data.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
		main_vbox.add_child(no_data)
		return

	var weapons = attack_manager.get_weapons()
	
	# Contador de slots
	var max_slots = attack_manager.max_weapon_slots if "max_weapon_slots" in attack_manager else 6
	var slots_label = Label.new()
	slots_label.text = "(%d / %d slots)" % [weapons.size(), max_slots]
	slots_label.add_theme_font_size_override("font_size", 14)
	slots_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	header.add_child(slots_label)

	if weapons.is_empty():
		var no_weapons = Label.new()
		no_weapons.text = "🎮 Aún no has obtenido ningún arma.\n¡Sube de nivel para conseguir tu primera arma!"
		no_weapons.add_theme_font_size_override("font_size", 16)
		no_weapons.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		no_weapons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main_vbox.add_child(no_weapons)
		return

	# Grid de armas (2 columnas)
	var weapons_grid = GridContainer.new()
	weapons_grid.columns = 2
	weapons_grid.add_theme_constant_override("h_separation", 12)
	weapons_grid.add_theme_constant_override("v_separation", 12)
	main_vbox.add_child(weapons_grid)

	for weapon in weapons:
		var weapon_card = _create_weapon_card(weapon)
		weapons_grid.add_child(weapon_card)

func _create_weapon_card(weapon) -> Control:
	"""Crear tarjeta detallada de arma"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 0)
	
	# Obtener elemento y rareza
	var element = str(weapon.element if "element" in weapon else weapon.element_type if "element_type" in weapon else "physical").to_lower()
	var rarity = str(weapon.rarity if "rarity" in weapon else "common").to_lower()
	var weapon_level = weapon.level if "level" in weapon else 1
	var max_level = weapon.max_level if "max_level" in weapon else 8
	
	# Estilo con borde del elemento
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14)
	style.border_color = ELEMENT_COLORS.get(element, RARITY_COLORS.get(rarity, Color.WHITE))
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	# === HEADER: Icono + Nombre + Nivel ===
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)
	
	# Icono grande
	var icon_container = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = ELEMENT_COLORS.get(element, Color.GRAY).darkened(0.6)
	icon_style.set_corner_radius_all(8)
	icon_style.set_content_margin_all(8)
	icon_container.add_theme_stylebox_override("panel", icon_style)
	header_hbox.add_child(icon_container)
	
	var icon = Label.new()
	icon.text = weapon.icon if "icon" in weapon else ELEMENT_ICONS.get(element, "🔮")
	icon.add_theme_font_size_override("font_size", 32)
	icon_container.add_child(icon)
	
	# Info del nombre
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(info_vbox)
	
	var weapon_name = weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.weapon_name if "weapon_name" in weapon else "Arma"
	var name_label = Label.new()
	name_label.text = weapon_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
	info_vbox.add_child(name_label)
	
	# Elemento y tipo
	var type_label = Label.new()
	var element_display = ELEMENT_ICONS.get(element, "❓") + " " + element.capitalize()
	type_label.text = element_display
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color.GRAY))
	info_vbox.add_child(type_label)
	
	# === NIVEL Y BARRA DE PROGRESO ===
	var level_hbox = HBoxContainer.new()
	level_hbox.add_theme_constant_override("separation", 8)
	header_hbox.add_child(level_hbox)
	
	var level_vbox = VBoxContainer.new()
	level_vbox.add_theme_constant_override("separation", 2)
	level_hbox.add_child(level_vbox)
	
	var level_label = Label.new()
	level_label.text = "Nv.%d" % weapon_level
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", SELECTED_TAB if weapon_level >= max_level else Color.WHITE)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_vbox.add_child(level_label)
	
	# Indicador de nivel máximo o estrellas
	var stars = ""
	for i in range(max_level):
		if i < weapon_level:
			stars += "★"
		else:
			stars += "☆"
	
	var stars_label = Label.new()
	stars_label.text = stars.substr(0, 8)  # Mostrar máximo 8 estrellas
	stars_label.add_theme_font_size_override("font_size", 8)
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if weapon_level > 0 else Color(0.4, 0.4, 0.4))
	level_vbox.add_child(stars_label)
	
	# === STATS DEL ARMA ===
	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(stats_grid)
	
	# Daño
	if "damage" in weapon:
		_add_weapon_stat(stats_grid, "⚔️", "Daño", "%.0f" % weapon.damage)
	
	# Cooldown
	if "cooldown" in weapon:
		_add_weapon_stat(stats_grid, "⏱️", "Cooldown", "%.2fs" % weapon.cooldown)
	
	# Proyectiles
	if "projectile_count" in weapon and weapon.projectile_count > 0:
		_add_weapon_stat(stats_grid, "🎯", "Proyectiles", "x%d" % weapon.projectile_count)
	
	# Pierce
	if "pierce" in weapon and weapon.pierce > 0:
		_add_weapon_stat(stats_grid, "🗡️", "Atravesar", "%d" % weapon.pierce)
	
	# Área
	if "area" in weapon and weapon.area != 1.0:
		_add_weapon_stat(stats_grid, "🌀", "Área", "%.0f%%" % (weapon.area * 100))
	
	# Velocidad de proyectil
	if "projectile_speed" in weapon:
		_add_weapon_stat(stats_grid, "➡️", "Velocidad", "%.0f" % weapon.projectile_speed)
	
	# Knockback
	if "knockback" in weapon and weapon.knockback > 0:
		_add_weapon_stat(stats_grid, "💥", "Empuje", "%.0f" % weapon.knockback)
	
	# === EFECTO ESPECIAL ===
	var special_effect = _get_weapon_special_effect(weapon)
	if special_effect != "":
		var sep = HSeparator.new()
		vbox.add_child(sep)
		
		var effect_label = Label.new()
		effect_label.text = "✨ " + special_effect
		effect_label.add_theme_font_size_override("font_size", 11)
		effect_label.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color(0.7, 0.9, 0.7)))
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(effect_label)
	
	# Tooltip con descripción completa
	var description = weapon.description if "description" in weapon else ""
	if description != "":
		card.tooltip_text = description
	
	return card

func _add_weapon_stat(grid: GridContainer, icon: String, stat_name: String, value: String) -> void:
	"""Añadir stat de arma al grid"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	hbox.add_child(value_label)
	
	grid.add_child(hbox)

func _get_weapon_special_effect(weapon) -> String:
	"""Obtener descripción del efecto especial del arma"""
	var element = str(weapon.element if "element" in weapon else weapon.element_type if "element_type" in weapon else "").to_lower()
	
	# Efectos por defecto según elemento
	match element:
		"ice":
			var slow = weapon.slow_amount if "slow_amount" in weapon else 0.4
			return "Ralentiza enemigos un %.0f%%" % (slow * 100)
		"fire":
			return "Inflige quemadura (daño continuo)"
		"lightning":
			var chains = weapon.chain_count if "chain_count" in weapon else 2
			return "Salta a %d enemigos cercanos" % chains
		"nature":
			return "Persigue enemigos y roba vida"
		"shadow":
			var pierce = weapon.pierce if "pierce" in weapon else 2
			return "Atraviesa %d enemigos" % pierce
		"arcane":
			return "Orbita alrededor del jugador"
		"earth":
			return "Aturde enemigos en el área"
		"light":
			return "Daño instantáneo con bonus crítico"
		"void":
			return "Atrae enemigos hacia el impacto"
		"wind":
			return "Gran empuje a los enemigos"
	
	return ""

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
	_show_options()

func _show_options() -> void:
	# Buscar o crear el menú de opciones
	var options_menu = get_node_or_null("OptionsMenu")
	if not options_menu:
		var options_scene = load("res://scenes/ui/OptionsMenu.tscn")
		if options_scene:
			options_menu = options_scene.instantiate()
			options_menu.name = "OptionsMenu"
			add_child(options_menu)
	
	if options_menu:
		options_menu.visible = true
		if options_menu.has_signal("closed"):
			if not options_menu.closed.is_connected(_on_options_closed):
				options_menu.closed.connect(_on_options_closed)

func _on_options_closed() -> void:
	# Volver el foco al botón de continuar
	var resume_btn = main_panel.find_child("ResumeButton", true, false)
	if resume_btn:
		resume_btn.grab_focus()

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
