# PauseMenu.gd
# Menú de pausa con información completa del jugador
#
# Muestra:
# - Stats del jugador
# - Armas equipadas con sus stats
# - Objetos/items pasivos recolectados

extends Control
class_name PauseMenu

signal resume_pressed
signal options_pressed
signal quit_to_menu_pressed

# Referencias externas (se obtienen automáticamente)
var player_stats: Node = null  # Tipo Node para evitar errores de asignacion
var attack_manager: Node = null  # Tipo Node para evitar errores de asignacion
var player_ref: Node = null
var experience_manager_ref: Node = null

# Estado
var game_time: float = 0.0
var current_tab: int = 0  # 0=Stats, 1=Armas, 2=Objetos
var _options_open: bool = false  # Bloquear input cuando opciones esta abierto

# Sistema de navegacion mejorado
enum NavRow { TABS, CONTENT, ACTIONS }
var current_nav_row: NavRow = NavRow.TABS
var content_selection: int = 0  # Indice del elemento seleccionado en el contenido
var action_selection: int = 0   # 0=Continuar, 1=Opciones, 2=Menu
var content_items: Array = []   # Array de elementos navegables en el contenido
var action_buttons: Array = []  # Array de botones de accion
var content_scroll: ScrollContainer = null  # Referencia al scroll del contenido actual

# UI Nodes creados dinamicamente
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
const HIGHLIGHT_COLOR = Color(0.3, 0.5, 0.8, 0.3)
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

	var tab_names = ["📊 Stats", "⚔️ Armas", "🎒 Objetos"]
	for i in range(tab_names.size()):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(150, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		btn.focus_mode = Control.FOCUS_NONE  # Desactivar foco nativo, usamos manual
		tabs_container.add_child(btn)
		tab_buttons.append(btn)

	# Separador
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# === CONTENIDO ===
	content_container = Control.new()
	content_container.custom_minimum_size = Vector2(860, 380)
	vbox.add_child(content_container)

	# === BOTONES DE ACCION ===
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	var buttons_row = HBoxContainer.new()
	buttons_row.name = "ActionsRow"
	buttons_row.add_theme_constant_override("separation", 20)
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_row)

	var resume_btn = Button.new()
	resume_btn.name = "ResumeButton"
	resume_btn.text = ">  Continuar"
	resume_btn.custom_minimum_size = Vector2(180, 45)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.pressed.connect(_on_resume_pressed)
	resume_btn.focus_mode = Control.FOCUS_NONE
	buttons_row.add_child(resume_btn)
	action_buttons.append(resume_btn)

	var options_btn = Button.new()
	options_btn.name = "OptionsButton"
	options_btn.text = "*  Opciones"
	options_btn.custom_minimum_size = Vector2(180, 45)
	options_btn.add_theme_font_size_override("font_size", 18)
	options_btn.pressed.connect(_on_options_pressed)
	options_btn.focus_mode = Control.FOCUS_NONE
	buttons_row.add_child(options_btn)
	action_buttons.append(options_btn)

	var quit_btn = Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "#  Menu"
	quit_btn.custom_minimum_size = Vector2(180, 45)
	quit_btn.add_theme_font_size_override("font_size", 18)
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.focus_mode = Control.FOCUS_NONE
	buttons_row.add_child(quit_btn)
	action_buttons.append(quit_btn)

	# Help text
	var help = Label.new()
	help.name = "HelpLabel"
	help.text = "WASD: Navegar  |  ESPACIO: Seleccionar  |  ESC: Continuar"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(help)

func initialize(stats: PlayerStats, attack_mgr: AttackManager) -> void:
	player_stats = stats
	attack_manager = attack_mgr

func _find_references() -> void:
	"""Busca referencias a sistemas del juego automaticamente"""
	var tree = get_tree()
	if not tree:
		return

	# Buscar PlayerStats en el arbol
	if not player_stats:
		# Buscar en rutas comunes (nodo con nombre exacto)
		var found = tree.root.get_node_or_null("Game/PlayerStats")
		if found and _is_player_stats(found):
			player_stats = found
		if not player_stats:
			found = tree.root.get_node_or_null("PlayerStats")
			if found and _is_player_stats(found):
				player_stats = found
		if not player_stats:
			# Buscar en grupo
			var nodes = tree.get_nodes_in_group("player_stats")
			for n in nodes:
				if _is_player_stats(n):
					player_stats = n
					break

	# Buscar AttackManager
	if not attack_manager:
		var found = tree.root.get_node_or_null("Game/AttackManager")
		if found and _is_attack_manager(found):
			attack_manager = found
		if not attack_manager:
			found = tree.root.get_node_or_null("AttackManager")
			if found and _is_attack_manager(found):
				attack_manager = found

	# Buscar Player para obtener stats directamente
	if not player_ref:
		var players = tree.get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
			# Intentar obtener attack_manager del player
			if not attack_manager and player_ref:
				if "wizard_player" in player_ref and player_ref.wizard_player:
					var am = player_ref.wizard_player.get("attack_manager")
					if am and _is_attack_manager(am):
						attack_manager = am
				# Tambien intentar obtener player_stats del player
				if not player_stats and player_ref:
					if "player_stats" in player_ref:
						var ps = player_ref.get("player_stats")
						if ps and _is_player_stats(ps):
							player_stats = ps

	# Buscar ExperienceManager para nivel/XP
	if not experience_manager_ref:
		experience_manager_ref = tree.root.get_node_or_null("Game/ExperienceManager")
		if not experience_manager_ref:
			experience_manager_ref = tree.root.get_node_or_null("ExperienceManager")

	# Debug
	print("[PauseMenu] Referencias encontradas:")
	print("  - player_stats: ", player_stats != null, " (", player_stats.get_class() if player_stats else "null", ")")
	print("  - attack_manager: ", attack_manager != null)
	print("  - player_ref: ", player_ref != null)
	print("  - experience_manager: ", experience_manager_ref != null)

func _is_player_stats(node: Node) -> bool:
	"""Verificar si un nodo es realmente un PlayerStats"""
	if node == null:
		return false
	# Verificar por script
	var script = node.get_script()
	if script:
		var path = script.resource_path if script.resource_path else ""
		if path.ends_with("PlayerStats.gd"):
			return true
	# Verificar por metodos caracteristicos
	if node.has_method("get_stat") and node.has_method("get_stat_metadata"):
		return true
	return false

func _is_attack_manager(node: Node) -> bool:
	"""Verificar si un nodo es realmente un AttackManager"""
	if node == null:
		return false
	# Verificar por script
	var script = node.get_script()
	if script:
		var path = script.resource_path if script.resource_path else ""
		if path.ends_with("AttackManager.gd"):
			return true
	# Verificar por metodos caracteristicos
	if node.has_method("get_equipped_weapons"):
		return true
	return false

func show_pause_menu(current_time: float = 0.0) -> void:
	game_time = current_time
	visible = true
	get_tree().paused = true
	current_tab = 0

	# Inicializar navegacion
	current_nav_row = NavRow.TABS
	content_selection = 0
	action_selection = 0
	content_items.clear()

	# Obtener referencias automaticamente si no se inicializo
	_find_references()

	_update_time_display()
	_update_tabs_visual()
	_show_tab_content()
	_update_navigation_visuals()

	# Animacion
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
		var is_selected = (i == current_tab)
		var is_focused = (current_nav_row == NavRow.TABS and is_selected)

		if is_selected:
			btn.add_theme_color_override("font_color", SELECTED_TAB)
			btn.add_theme_color_override("font_hover_color", SELECTED_TAB)
		else:
			btn.add_theme_color_override("font_color", UNSELECTED_TAB)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)

		# Estilo visual para indicar foco
		if is_focused:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.3, 0.4)
			style.border_color = SELECTED_TAB
			style.set_border_width_all(2)
			style.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
		else:
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")

func _on_tab_pressed(tab_index: int) -> void:
	current_tab = tab_index
	current_nav_row = NavRow.TABS
	_update_tabs_visual()
	_show_tab_content()

func _show_tab_content() -> void:
	# Limpiar contenido anterior y items navegables
	content_items.clear()
	for child in content_container.get_children():
		child.queue_free()

	match current_tab:
		0: _show_stats_tab()
		1: _show_weapons_tab()
		2: _show_upgrades_tab()

	# Resetear seleccion de contenido
	content_selection = 0
	_update_content_selection_visual()

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
	scroll.name = "StatsScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(scroll)
	content_scroll = scroll  # Guardar referencia para scroll con WASD

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)

	# === HEADER COMPACTO CON VIDA Y NIVEL ===
	_create_player_header_compact(main_vbox)

	# === STATS EN DOS COLUMNAS SIMPLES ===
	var columns_hbox = HBoxContainer.new()
	columns_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(columns_hbox)

	# Columna izquierda (Defensivo + Criticos)
	var left_column = VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 8)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(left_column)

	# Columna derecha (Ofensivo + Utilidad)
	var right_column = VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 8)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(right_column)

	# SIEMPRE mostrar los stats (con valores por defecto si no hay player_stats)
	# Columna izquierda
	_create_stats_section(left_column, "defensive", "Defensivo")
	_create_stats_section(left_column, "critical", "Criticos")

	# Columna derecha
	_create_stats_section(right_column, "offensive", "Ofensivo")
	_create_stats_section(right_column, "utility", "Utilidad")

	# === BUFFS ACTIVOS (si los hay) ===
	_create_active_buffs_section(main_vbox)

func _create_player_header_compact(parent: VBoxContainer) -> void:
	"""Header compacto con vida, nivel y XP en una sola línea"""
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 40)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(header_hbox)

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

	# Vida
	var hp_label = Label.new()
	hp_label.text = "❤️ %d/%d" % [current_hp, max_hp]
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	header_hbox.add_child(hp_label)

	# Nivel
	var level_label = Label.new()
	level_label.text = "📈 Nivel %d" % level
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", SELECTED_TAB)
	header_hbox.add_child(level_label)

	# XP
	var xp_label = Label.new()
	xp_label.text = "⭐ %.0f/%.0f XP" % [current_xp, xp_to_next]
	xp_label.add_theme_font_size_override("font_size", 18)
	xp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	header_hbox.add_child(xp_label)

	# Separador
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	parent.add_child(sep)

func _create_stats_section(parent: VBoxContainer, category: String, title: String) -> void:
	"""Crear sección de stats compacta"""
	# Título de sección
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", CATEGORY_COLORS.get(category, Color.WHITE))
	parent.add_child(title_label)

	# Stats de esta categoría
	var stats_list = _get_stats_for_category(category)

	for stat_name in stats_list:
		var row = _create_compact_stat_row(stat_name)
		parent.add_child(row)

	# Pequeño espaciado entre secciones
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	parent.add_child(spacer)

func _create_compact_stat_row(stat_name: String) -> Control:
	"""Fila compacta: icono + nombre + valor"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	# Obtener metadatos (usar fallback si no hay player_stats)
	var meta = _get_stat_metadata_fallback(stat_name)
	if player_stats and player_stats.has_method("get_stat_metadata"):
		var ps_meta = player_stats.get_stat_metadata(stat_name)
		if ps_meta and not ps_meta.is_empty():
			meta = ps_meta

	# Icono pequenio
	var icon = Label.new()
	icon.text = meta.get("icon", "o")
	icon.add_theme_font_size_override("font_size", 12)
	icon.custom_minimum_size = Vector2(18, 0)
	hbox.add_child(icon)

	# Nombre
	var name_label = Label.new()
	name_label.text = meta.get("name", stat_name)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# Valor - obtener de player_stats o usar valor base
	var value = _get_stat_base_value(stat_name)
	if player_stats and player_stats.has_method("get_stat"):
		value = player_stats.get_stat(stat_name)

	var value_label = Label.new()
	if player_stats and player_stats.has_method("format_stat_value"):
		value_label.text = player_stats.format_stat_value(stat_name, value)
	else:
		value_label.text = _format_stat_value_fallback(stat_name, value)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", _get_value_color(stat_name, value))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(value_label)

	# Tooltip
	if meta.has("description") and meta.description != "":
		hbox.tooltip_text = meta.description

	return hbox

# Metadatos por defecto para todos los stats
const DEFAULT_STAT_METADATA = {
	# Defensivos
	"max_health": {"name": "Vida Maxima", "icon": "<3", "description": "Puntos de vida maximos"},
	"health_regen": {"name": "Regeneracion", "icon": "+", "description": "Vida regenerada por segundo"},
	"armor": {"name": "Armadura", "icon": "[=]", "description": "Reduce el danio recibido"},
	"dodge_chance": {"name": "Esquivar", "icon": "~", "description": "Probabilidad de esquivar ataques"},
	"life_steal": {"name": "Robo de Vida", "icon": "<", "description": "Vida robada al atacar"},
	# Ofensivos
	"damage_mult": {"name": "Danio", "icon": "!", "description": "Multiplicador de danio"},
	"cooldown_mult": {"name": "Enfriamiento", "icon": "o", "description": "Velocidad de recarga"},
	"area_mult": {"name": "Area", "icon": "O", "description": "Tamanio de area de efecto"},
	"projectile_speed_mult": {"name": "Vel. Proyectil", "icon": ">>", "description": "Velocidad de proyectiles"},
	"duration_mult": {"name": "Duracion", "icon": ":", "description": "Duracion de efectos"},
	"extra_projectiles": {"name": "Proyectiles Extra", "icon": "x", "description": "Proyectiles adicionales"},
	"knockback_mult": {"name": "Empuje", "icon": "<-", "description": "Fuerza de empuje"},
	# Criticos
	"crit_chance": {"name": "Prob. Critico", "icon": "*", "description": "Probabilidad de critico"},
	"crit_damage": {"name": "Danio Critico", "icon": "**", "description": "Multiplicador de danio critico"},
	# Utilidad
	"move_speed": {"name": "Velocidad", "icon": "->", "description": "Velocidad de movimiento"},
	"pickup_range": {"name": "Rango Recogida", "icon": "()", "description": "Rango para recoger items"},
	"xp_mult": {"name": "Experiencia", "icon": "^", "description": "Experiencia ganada"},
	"coin_value_mult": {"name": "Valor Monedas", "icon": "$", "description": "Valor de monedas"},
	"luck": {"name": "Suerte", "icon": "?", "description": "Afecta drops y criticos"}
}

# Valores base para stats
const DEFAULT_STAT_VALUES = {
	"max_health": 100.0,
	"health_regen": 0.0,
	"armor": 0.0,
	"dodge_chance": 0.0,
	"life_steal": 0.0,
	"damage_mult": 1.0,
	"cooldown_mult": 1.0,
	"area_mult": 1.0,
	"projectile_speed_mult": 1.0,
	"duration_mult": 1.0,
	"extra_projectiles": 0.0,
	"knockback_mult": 1.0,
	"crit_chance": 0.05,
	"crit_damage": 2.0,
	"move_speed": 1.0,
	"pickup_range": 1.0,
	"xp_mult": 1.0,
	"coin_value_mult": 1.0,
	"luck": 0.0
}

func _get_stat_metadata_fallback(stat_name: String) -> Dictionary:
	"""Obtener metadatos de un stat"""
	if DEFAULT_STAT_METADATA.has(stat_name):
		return DEFAULT_STAT_METADATA[stat_name]
	return {"name": stat_name, "icon": "o", "description": ""}

func _get_stat_base_value(stat_name: String) -> float:
	"""Obtener valor base de un stat"""
	if DEFAULT_STAT_VALUES.has(stat_name):
		return DEFAULT_STAT_VALUES[stat_name]
	return 0.0

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

	for i in range(weapons.size()):
		var weapon = weapons[i]
		var weapon_card = _create_weapon_card(weapon)
		weapons_grid.add_child(weapon_card)

		# Registrar como elemento navegable
		content_items.append({
			"panel": weapon_card,
			"type": "weapon",
			"index": i,
			"weapon": weapon,
			"callback": Callable()  # Sin callback por ahora
		})

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
# TAB: OBJETOS (Items pasivos recolectados)
# ═══════════════════════════════════════════════════════════════════════════════

func _show_upgrades_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "UpgradesScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.add_child(scroll)
	content_scroll = scroll  # Guardar referencia para scroll con WASD

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(grid)

	if not player_stats:
		var no_data = Label.new()
		no_data.text = "No hay objetos"
		grid.add_child(no_data)
		return

	var upgrades = player_stats.get_collected_upgrades()

	if upgrades.is_empty():
		var no_upgrades = Label.new()
		no_upgrades.text = "Sube de nivel para obtener objetos"
		no_upgrades.add_theme_font_size_override("font_size", 16)
		no_upgrades.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		grid.add_child(no_upgrades)
		return

	for i in range(upgrades.size()):
		var upgrade = upgrades[i]
		var upgrade_panel = _create_upgrade_panel(upgrade)
		grid.add_child(upgrade_panel)

		# Registrar como elemento navegable
		content_items.append({
			"panel": upgrade_panel,
			"type": "upgrade",
			"index": i,
			"upgrade": upgrade,
			"callback": Callable()
		})

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

	# Icono: cargar textura si existe, o usar emoji de categoria/fallback
	var icon_path = str(upgrade.get("icon", "✨"))
	var texture_loaded = false
	if icon_path.begins_with("res://") and ResourceLoader.exists(icon_path):
		var tex = load(icon_path)
		if tex:
			var tex_rect = TextureRect.new()
			tex_rect.texture = tex
			tex_rect.custom_minimum_size = Vector2(32, 32)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			header.add_child(tex_rect)
			texture_loaded = true
	
	if not texture_loaded:
		# Fallback a emoji segun categoria o un emoji generico
		var icon = Label.new()
		var emoji = "✨"
		var category = upgrade.get("category", "")
		match category:
			"combat": emoji = "⚔️"
			"defense": emoji = "🛡️"
			"utility": emoji = "🔧"
			"special": emoji = "⭐"
			_:
				# Si no es ruta, usar el icono directamente (emoji)
				if not icon_path.begins_with("res://"):
					emoji = icon_path
		icon.text = emoji
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

# ===============================================================================
# SISTEMA DE NAVEGACION CON WASD
# ===============================================================================

func _safe_handle_input() -> void:
	"""Marcar input como manejado de forma segura"""
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Si el menu de opciones esta abierto, no procesar input del menu de pausa
	if _options_open:
		return

	# ESC o Pause para cerrar
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_resume_pressed()
		_safe_handle_input()
		return

	# Navegacion con WASD
	if event.is_action_pressed("move_up"):
		_navigate_vertical(-1)
		_safe_handle_input()
	elif event.is_action_pressed("move_down"):
		_navigate_vertical(1)
		_safe_handle_input()
	elif event.is_action_pressed("move_left"):
		_navigate_horizontal(-1)
		_safe_handle_input()
	elif event.is_action_pressed("move_right"):
		_navigate_horizontal(1)
		_safe_handle_input()

	# Seleccionar con espacio o enter
	if event.is_action_pressed("cast_spell") or event.is_action_pressed("ui_accept"):
		_activate_current_selection()
		_safe_handle_input()

func _navigate_vertical(direction: int) -> void:
	"""Navegar arriba/abajo entre filas (tabs, contenido, acciones) o hacer scroll"""
	var old_row = current_nav_row

	# Si estamos en CONTENT y hay scroll, hacer scroll con W/S
	if current_nav_row == NavRow.CONTENT and content_scroll:
		var scroll_amount = 60  # Pixeles a scrollear por pulsacion
		var current_v = content_scroll.scroll_vertical
		var max_v = content_scroll.get_v_scroll_bar().max_value - content_scroll.size.y

		if direction < 0:  # W - Scroll arriba
			if current_v > 0:
				content_scroll.scroll_vertical = maxi(0, current_v - scroll_amount)
				return
			else:
				# Ya estamos arriba, ir a tabs
				current_nav_row = NavRow.TABS
		else:  # S - Scroll abajo
			if current_v < max_v:
				content_scroll.scroll_vertical = mini(int(max_v), current_v + scroll_amount)
				return
			else:
				# Ya estamos abajo, ir a actions
				current_nav_row = NavRow.ACTIONS
	elif direction < 0:  # Arriba (W)
		match current_nav_row:
			NavRow.ACTIONS:
				if content_scroll or content_items.size() > 0:
					current_nav_row = NavRow.CONTENT
					content_selection = mini(content_selection, maxi(0, content_items.size() - 1))
					# Ir al final del scroll
					if content_scroll:
						await get_tree().process_frame
						content_scroll.scroll_vertical = int(content_scroll.get_v_scroll_bar().max_value)
				else:
					current_nav_row = NavRow.TABS
			NavRow.CONTENT:
				current_nav_row = NavRow.TABS
			NavRow.TABS:
				# Ya estamos arriba, ir a acciones (wrap)
				current_nav_row = NavRow.ACTIONS
	else:  # Abajo (S)
		match current_nav_row:
			NavRow.TABS:
				if content_scroll or content_items.size() > 0:
					current_nav_row = NavRow.CONTENT
					content_selection = mini(content_selection, maxi(0, content_items.size() - 1))
					# Ir al inicio del scroll
					if content_scroll:
						content_scroll.scroll_vertical = 0
				else:
					current_nav_row = NavRow.ACTIONS
			NavRow.CONTENT:
				current_nav_row = NavRow.ACTIONS
			NavRow.ACTIONS:
				# Ya estamos abajo, ir a tabs (wrap)
				current_nav_row = NavRow.TABS

	if old_row != current_nav_row:
		_update_navigation_visuals()

func _navigate_horizontal(direction: int) -> void:
	"""Navegar izquierda/derecha dentro de la fila actual"""
	match current_nav_row:
		NavRow.TABS:
			current_tab = (current_tab + direction) % tab_buttons.size()
			if current_tab < 0:
				current_tab = tab_buttons.size() - 1
			_update_tabs_visual()
			_show_tab_content()
		NavRow.CONTENT:
			if content_items.size() > 0:
				content_selection = (content_selection + direction) % content_items.size()
				if content_selection < 0:
					content_selection = content_items.size() - 1
				_update_content_selection_visual()
		NavRow.ACTIONS:
			action_selection = (action_selection + direction) % action_buttons.size()
			if action_selection < 0:
				action_selection = action_buttons.size() - 1
			_update_action_buttons_visual()

func _activate_current_selection() -> void:
	"""Activar el elemento seleccionado actualmente"""
	match current_nav_row:
		NavRow.TABS:
			# Ya esta seleccionado, no hacer nada especial
			pass
		NavRow.CONTENT:
			if content_items.size() > content_selection:
				var item = content_items[content_selection]
				if item.has("callback") and item.callback:
					item.callback.call()
		NavRow.ACTIONS:
			match action_selection:
				0: _on_resume_pressed()
				1: _on_options_pressed()
				2: _on_quit_pressed()

func _update_navigation_visuals() -> void:
	"""Actualizar todos los visuales de navegacion"""
	_update_tabs_visual()
	_update_content_selection_visual()
	_update_action_buttons_visual()

func _update_content_selection_visual() -> void:
	"""Actualizar visual del contenido seleccionado"""
	for i in range(content_items.size()):
		var item = content_items[i]
		if item.has("panel") and item.panel:
			var panel = item.panel as PanelContainer
			if panel:
				var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
				if i == content_selection and current_nav_row == NavRow.CONTENT:
					style.border_color = SELECTED_TAB
					style.set_border_width_all(3)
				else:
					style.border_color = Color(0.3, 0.3, 0.4)
					style.set_border_width_all(1)
				panel.add_theme_stylebox_override("panel", style)

func _update_action_buttons_visual() -> void:
	"""Actualizar visual de los botones de accion"""
	for i in range(action_buttons.size()):
		var btn = action_buttons[i] as Button
		if btn:
			if i == action_selection and current_nav_row == NavRow.ACTIONS:
				btn.add_theme_color_override("font_color", SELECTED_TAB)
				btn.add_theme_color_override("font_hover_color", SELECTED_TAB)
				# Agregar indicador visual de seleccion
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.2, 0.3, 0.4)
				style.border_color = SELECTED_TAB
				style.set_border_width_all(2)
				style.set_corner_radius_all(8)
				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
			else:
				btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
				btn.add_theme_color_override("font_hover_color", Color.WHITE)
				btn.remove_theme_stylebox_override("normal")
				btn.remove_theme_stylebox_override("hover")

func _change_tab(direction: int) -> void:
	current_tab = (current_tab + direction) % tab_buttons.size()
	if current_tab < 0:
		current_tab = tab_buttons.size() - 1
	_update_tabs_visual()
	_show_tab_content()

# ===============================================================================
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
	# Marcar que opciones está abierto para bloquear input
	_options_open = true

	# Deshabilitar todos los botones del menú de pausa
	_set_pause_menu_buttons_enabled(false)

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
		# Dar foco al primer elemento del menú de opciones
		var close_btn = options_menu.get_node_or_null("Panel/VBox/CloseButton")
		if close_btn:
			close_btn.grab_focus()
		if options_menu.has_signal("closed"):
			if not options_menu.closed.is_connected(_on_options_closed):
				options_menu.closed.connect(_on_options_closed)

func _on_options_closed() -> void:
	# Marcar que opciones está cerrado
	_options_open = false

	# Rehabilitar todos los botones del menú de pausa
	_set_pause_menu_buttons_enabled(true)

	# Volver el foco al botón de continuar
	var resume_btn = main_panel.find_child("ResumeButton", true, false)
	if resume_btn:
		resume_btn.grab_focus()

func _set_pause_menu_buttons_enabled(enabled: bool) -> void:
	"""Habilitar o deshabilitar los botones del menú de pausa"""
	for btn in tab_buttons:
		btn.disabled = not enabled
		btn.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE

	# También los botones de acción
	var resume_btn = main_panel.find_child("ResumeButton", true, false)
	if resume_btn:
		resume_btn.disabled = not enabled
		resume_btn.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE

	# Buscar todos los botones en buttons_row
	for child in main_panel.get_children():
		_disable_buttons_recursive(child, not enabled)

func _on_quit_pressed() -> void:
	_play_button_sound()
	quit_to_menu_pressed.emit()

	# Guardar que hay una partida en curso para poder reanudar
	SessionState.has_active_game = true
	SessionState.paused_game_time = game_time

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _disable_buttons_recursive(node: Node, disabled: bool) -> void:
	"""Deshabilitar/habilitar botones recursivamente"""
	if node is Button:
		node.disabled = disabled
		node.focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	for child in node.get_children():
		_disable_buttons_recursive(child, disabled)

func _play_button_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")
