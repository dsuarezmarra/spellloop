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

# Mapping local rarities to UIVisualHelper tiers
func _get_color_by_rarity(rarity_str: String) -> Color:
	var tier_map = {
		"common": 1,
		"uncommon": 2,
		"rare": 3,
		"epic": 4,
		"legendary": 5
	}
	var tier = tier_map.get(rarity_str.to_lower(), 1)
	return UIVisualHelper.get_color_for_tier(tier)

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")  # Para que Game.gd pueda encontrarlo
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
		btn.mouse_entered.connect(_on_element_hover)
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
	resume_btn.mouse_entered.connect(_on_element_hover)
	resume_btn.focus_mode = Control.FOCUS_NONE
	buttons_row.add_child(resume_btn)
	action_buttons.append(resume_btn)

	var options_btn = Button.new()
	options_btn.name = "OptionsButton"
	options_btn.text = "*  Opciones"
	options_btn.custom_minimum_size = Vector2(180, 45)
	options_btn.add_theme_font_size_override("font_size", 18)
	options_btn.pressed.connect(_on_options_pressed)
	options_btn.mouse_entered.connect(_on_element_hover)
	options_btn.focus_mode = Control.FOCUS_NONE
	buttons_row.add_child(options_btn)
	action_buttons.append(options_btn)

	var quit_btn = Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "#  Menu"
	quit_btn.custom_minimum_size = Vector2(180, 45)
	quit_btn.add_theme_font_size_override("font_size", 18)
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.mouse_entered.connect(_on_element_hover)
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
	
	# Verificar si hay otros menús bloqueantes antes de quitar la pausa
	var can_unpause = true
	
	# 1. Comprobar popups de cofres activos
	var chest_popups = get_tree().get_nodes_in_group("chest_popup")
	for popup in chest_popups:
		if is_instance_valid(popup) and popup.visible:
			can_unpause = false
			break
			
	# 2. Comprobar otros menús (como LevelUp)
	if get_tree().get_nodes_in_group("levelup_popup").any(func(x): return x.visible):
		can_unpause = false
		
	if can_unpause:
		get_tree().paused = false

func close() -> void:
	"""Alias para hide_pause_menu - usado por Game.gd"""
	hide_pause_menu()

func _update_time_display() -> void:
	var time_label = main_panel.find_child("TimeLabel", true, false) as Label
	if time_label:
		var minutes = int(floor(game_time / 60.0))
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
	AudioManager.play_fixed("sfx_ui_click")
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

	# Columna izquierda (Defensivo)
	var left_column = VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 8)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(left_column)

	# Columna derecha (Utilidad)
	var right_column = VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 8)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(right_column)

	# Columna izquierda - Stats defensivos del jugador
	_create_stats_section(left_column, "defensive", "Defensivo")

	# Columna derecha - Utilidad del jugador
	_create_stats_section(right_column, "utility", "Utilidad")
	
	# === STATS OFENSIVOS GLOBALES (afectan a todas las armas) ===
	_create_global_weapon_stats_section(main_vbox)

	# === EFECTOS DE ESTADO Y BONUS (Ofensivo) ===
	_create_stats_section(main_vbox, "offensive", "🛡️ EFECTOS Y BONUS")


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
	"""Crear sección de stats compacta (no muestra nada si la categoría está vacía)"""
	# Stats de esta categoría
	var stats_list = _get_stats_for_category(category)
	
	# No mostrar nada si no hay stats en esta categoría
	if stats_list.is_empty():
		return
	
	# Título de sección
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", CATEGORY_COLORS.get(category, Color.WHITE))
	parent.add_child(title_label)

	for stat_name in stats_list:
		var row = _create_compact_stat_row(stat_name)
		parent.add_child(row)

	# Pequeño espaciado entre secciones
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	parent.add_child(spacer)

func _create_compact_stat_row(stat_name: String) -> Control:
	"""Fila compacta: icono + nombre + valor - Con indicador de cap"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	# Obtener metadatos (usar fallback si no hay player_stats)
	var meta = _get_stat_metadata_fallback(stat_name)
	if player_stats and player_stats.has_method("get_stat_metadata"):
		var ps_meta = player_stats.get_stat_metadata(stat_name)
		if ps_meta and not ps_meta.is_empty():
			meta = ps_meta

	# Verificar si el stat está al máximo
	var is_capped = false
	if player_stats and player_stats.has_method("is_stat_capped"):
		is_capped = player_stats.is_stat_capped(stat_name)

	# Icono
	var icon = Label.new()
	icon.text = meta.get("icon", "o")
	icon.add_theme_font_size_override("font_size", 12)
	icon.custom_minimum_size = Vector2(18, 0)
	hbox.add_child(icon)

	# Nombre
	var name_label = Label.new()
	name_label.text = meta.get("name", stat_name)
	name_label.add_theme_font_size_override("font_size", 12)
	if is_capped:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))  # Dorado si al cap
	else:
		name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# Valor - obtener de player_stats, GlobalWeaponStats, o usar valor base
	var value = _get_stat_base_value(stat_name)
	
	# life_steal ahora está en GlobalWeaponStats (es un WEAPON_STAT)
	if stat_name == "life_steal":
		if attack_manager and attack_manager.has_method("get_global_stat"):
			value = attack_manager.get_global_stat("life_steal")
	elif player_stats and player_stats.has_method("get_stat"):
		value = player_stats.get_stat(stat_name)

	var value_label = Label.new()
	var value_text = ""
	if player_stats and player_stats.has_method("format_stat_value"):
		value_text = player_stats.format_stat_value(stat_name, value)
	else:
		value_text = _format_stat_value_fallback(stat_name, value)
	
	# Añadir indicador (MAX) si está al cap
	if is_capped:
		value_text += " (MAX)"
	
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 12)
	if is_capped:
		value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))  # Dorado si al cap
	else:
		value_label.add_theme_color_override("font_color", _get_value_color(stat_name, value))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(80, 0)  # Un poco más ancho para (MAX)
	hbox.add_child(value_label)

	# Tooltip
	if meta.has("description") and meta.description != "":
		hbox.tooltip_text = meta.description

	return hbox

# Metadatos por defecto para todos los stats - ACTUALIZADO v2.0
const DEFAULT_STAT_METADATA = {
	# === STATS DEL JUGADOR ===
	"max_health": {"name": "Vida Maxima", "icon": "<3", "description": "Puntos de vida maximos"},
	"health_regen": {"name": "Regeneracion", "icon": "+", "description": "Vida regenerada por segundo"},
	"armor": {"name": "Armadura", "icon": "[=]", "description": "Reduce el danio recibido"},
	"dodge_chance": {"name": "Esquivar", "icon": "~", "description": "Probabilidad de esquivar ataques"},
	"life_steal": {"name": "Robo de Vida", "icon": "<", "description": "Vida robada al atacar"},
	# === STATS GLOBALES DE ARMAS (v2.0) ===
	"damage_mult": {"name": "Danio", "icon": "!", "description": "Multiplicador de danio de armas"},
	"attack_speed_mult": {"name": "Vel. Ataque", "icon": ">>", "description": "Ataques por segundo (mayor = mas rapido)"},

	"area_mult": {"name": "Area", "icon": "O", "description": "Tamanio de area de efecto"},
	"projectile_speed_mult": {"name": "Vel. Proyectil", "icon": "->", "description": "Velocidad de proyectiles"},
	"duration_mult": {"name": "Duracion", "icon": ":", "description": "Duracion de efectos"},
	"extra_projectiles": {"name": "Proyectiles Extra", "icon": "x", "description": "Proyectiles adicionales"},
	"knockback_mult": {"name": "Empuje", "icon": "<-", "description": "Fuerza de empuje"},
	
	# === NUEVOS STATS OFENSIVOS (v3.0) ===
	"elite_damage_mult": {"name": "Daño Elites", "icon": "💀", "description": "Daño extra a elites y jefes"},
	"burn_chance": {"name": "Prob. Quemar", "icon": "🔥", "description": "Probabilidad de quemar enemigos"},
	"freeze_chance": {"name": "Prob. Congelar", "icon": "❄️", "description": "Probabilidad de congelar enemigos"},
	"bleed_chance": {"name": "Prob. Sangrado", "icon": "🩸", "description": "Probabilidad de causar sangrado"},
	"explosion_chance": {"name": "Prob. Explosión", "icon": "💣", "description": "Probabilidad de exploar al matar"},
	"execute_threshold": {"name": "Umbral Ejecución", "icon": "⚰️", "description": "Mata enemigos con poca vida"},
	"status_duration_mult": {"name": "Duración Efectos", "icon": "⏳", "description": "Duración de estados alterados"},
	"kill_heal": {"name": "Curar al Matar", "icon": "💗", "description": "Curación al eliminar enemigos"},
	"burn_damage": {"name": "Daño Fuego", "icon": "🔥", "description": "Daño por quemadura"},
	"explosion_damage": {"name": "Daño Expl.", "icon": "💥", "description": "Daño de explosiones"},
	
	# === DAÑO CONDICIONAL (v4.0) ===
	"close_range_damage_bonus": {"name": "Daño Cercano", "icon": "👊", "description": "Daño extra a enemigos cercanos"},
	"long_range_damage_bonus": {"name": "Daño Lejano", "icon": "🏹", "description": "Daño extra a enemigos lejanos"},
	"damage_vs_slowed": {"name": "vs Lentos", "icon": "🐌", "description": "Daño extra a enemigos ralentizados"},
	"damage_vs_burning": {"name": "vs Quemados", "icon": "🔥", "description": "Daño extra a enemigos quemando"},
	"damage_vs_frozen": {"name": "vs Congelados", "icon": "❄️", "description": "Daño extra a enemigos congelados"},
	"low_hp_damage_bonus": {"name": "vs Heridos", "icon": "💔", "description": "Daño extra a enemigos con baja vida"},
	"full_hp_damage_bonus": {"name": "Daño Full HP", "icon": "💚", "description": "Daño extra si tienes vida completa"},
	
	# === UTILIDAD ===
	"revives": {"name": "Revivir", "icon": "🆙", "description": "Vidas extra"},
	"reroll_count": {"name": "Rerolls Extra", "icon": "🎲", "description": "Cambiar opciones al subir nivel"},
	"banish_count": {"name": "Banish Extra", "icon": "❌", "description": "Bloquear opciones al subir nivel"},
	"magnet_strength": {"name": "Fuerza Imán", "icon": "🧲", "description": "Fuerza de atracción de objetos"},
	"levelup_options": {"name": "Opciones Extra", "icon": "📚", "description": "Opciones extra al elegir mejora"},
	"chain_count": {"name": "Cadenas Extra", "icon": "⚡", "description": "Cadenas adicionales en ataques"},
	"infinite_pickup_range": {"name": "Recogida Infinita", "icon": "🌐", "description": "Recoge items de todo el mapa"},

	# === CRITICOS ===
	"crit_chance": {"name": "Prob. Crítico", "icon": "🎯", "description": "Probabilidad de crítico"},
	"crit_damage": {"name": "Daño Crítico", "icon": "💢", "description": "Multiplicador de daño crítico"},
	
	# === UTILIDAD EXTRA ===
	"move_speed": {"name": "Velocidad", "icon": "🏃", "description": "Velocidad de movimiento"},
	"pickup_range": {"name": "Rango Recogida", "icon": "🧲", "description": "Rango para recoger items"},
	"xp_mult": {"name": "Experiencia", "icon": "⭐", "description": "Experiencia ganada"},
	"coin_value_mult": {"name": "Valor Monedas", "icon": "🪙", "description": "Valor de monedas"},
	"luck": {"name": "Suerte", "icon": "🍀", "description": "Afecta drops y críticos"}
}

# Valores base para stats - ACTUALIZADO v3.0
const DEFAULT_STAT_VALUES = {
	# Jugador - Defensivos
	"max_health": 100.0,
	"health_regen": 0.0,
	"armor": 0.0,
	"dodge_chance": 0.0,
	"life_steal": 0.0,
	"damage_taken_mult": 1.0,
	"thorns": 0.0,
	"thorns_percent": 0.0,
	"thorns_slow": 0.0,
	"thorns_stun": 0.0,
	"shield_amount": 0.0,
	"shield_regen": 0.0,
	"revives": 0.0,
	"revive_invuln": 0.0,
	# Armas globales
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,

	"area_mult": 1.0,
	"projectile_speed_mult": 1.0,
	"duration_mult": 1.0,
	"extra_projectiles": 0.0,
	"knockback_mult": 1.0,
	# Criticos
	"crit_chance": 0.05,
	"crit_damage": 2.0,
	# Utilidad (move_speed y pickup_range son valores ABSOLUTOS, no multiplicadores)
	"move_speed": 100.0,     # Velocidad base en px/s
	"pickup_range": 100.0,    # Rango base de recogida en px
	"xp_mult": 1.0,
	"coin_value_mult": 1.0,
	"luck": 0.0,
	"gold_mult": 1.0,
	"reroll_count": 0.0,
	"banish_count": 0.0,
	"curse": 0.0,
	"growth": 0.0,
	"magnet_strength": 1.0,
	"levelup_options": 0.0
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
	"""Obtener stats de una categoría - ACTUALIZADO v4.0"""
	if player_stats and player_stats.has_method("get_stats_by_category"):
		return player_stats.get_stats_by_category(category)

	# Fallback manual - Solo stats del JUGADOR
	# Los stats de armas (damage_mult, attack_speed, area, etc.) se muestran en el popup de armas
	match category:
		"defensive":
			return ["max_health", "health_regen", "armor", "dodge_chance", "life_steal", 
					"damage_taken_mult", "thorns", "thorns_percent", "shield_amount", 
					"max_shield", "shield_regen", "revives"]
		"offensive":
			# Incluye stats de daño condicional + efectos de estado
			return ["status_duration_mult", "elite_damage_mult", "burn_chance",
					"kill_heal", "burn_damage",
					"freeze_chance", "bleed_chance", "execute_threshold", "explosion_chance",
					# Daño condicional (faltaban en UI)
					"close_range_damage_bonus", "long_range_damage_bonus",
					"damage_vs_slowed", "damage_vs_burning", "damage_vs_frozen",
					"low_hp_damage_bonus", "full_hp_damage_bonus"]
		"critical":
			# Los críticos son stats de ARMAS, se muestran en popup de armas
			return []
		"utility":
			return ["move_speed", "pickup_range", "xp_mult", "coin_value_mult", "luck",
					"gold_mult", "reroll_count", "banish_count", "curse", "growth",
					"magnet_strength", "levelup_options",
					# Faltaban en UI
					"chain_count", "infinite_pickup_range"]
	return []

func _format_stat_value_fallback(stat_name: String, value: float) -> String:
	"""Formatear valor cuando no hay PlayerStats - ACTUALIZADO v4.0"""
	# Stats booleanos
	if stat_name == "infinite_pickup_range":
		return "Sí" if value > 0 else "No"
	
	# Stats porcentuales (0.0 - 1.0 → 0% - 100%)
	if stat_name in ["crit_chance", "dodge_chance", "life_steal", "thorns_percent", "curse", "growth",
					  "burn_chance", "freeze_chance", "bleed_chance", "explosion_chance", "execute_threshold",
					  "close_range_damage_bonus", "long_range_damage_bonus", "damage_vs_slowed",
					  "damage_vs_burning", "damage_vs_frozen", "low_hp_damage_bonus", "full_hp_damage_bonus"]:
		return "+%.0f%%" % (value * 100) if value > 0 else "%.0f%%" % (value * 100)
	
	# Stats de velocidad y rango son valores ABSOLUTOS - mostrar el valor directamente
	if stat_name == "move_speed":
		return "%.0f" % value  # Mostrar valor absoluto (ej: "50")
	
	if stat_name == "pickup_range":
		return "%.0f" % value  # Mostrar valor absoluto (ej: "50")
	
	# Stats multiplicadores (base 1.0)
	if stat_name in ["damage_mult", "attack_speed_mult", "area_mult",
					  "xp_mult", "coin_value_mult", "crit_damage", "projectile_speed_mult", 
					  "duration_mult", "knockback_mult", "gold_mult", "magnet_strength",
					  "status_duration_mult", "elite_damage_mult"]:
		var percent = (value - 1.0) * 100
		if abs(percent) >= 10000:
			if value >= 1.0:
				return "+" + _format_large_number(percent) + "%"
			else:
				return _format_large_number(percent) + "%"
		else:
			if value >= 1.0:
				return "+%.0f%%" % percent
			else:
				return "%.0f%%" % percent
	
	# damage_taken_mult - Caso especial (mostrar como x1.0 o reducción)
	if stat_name == "damage_taken_mult":
		if value == 1.0:
			return "x1.0"
		elif value < 1.0:
			return "-%.0f%%" % ((1.0 - value) * 100)
		else:
			return "+%.0f%%" % ((value - 1.0) * 100)
	
	# Stats enteros
	if stat_name in ["extra_projectiles", "thorns", "revives", "reroll_count", "banish_count", 
					  "levelup_options", "chain_count", "kill_heal", "burn_damage"]:
		if abs(value) >= 10000:
			return ("+" if value > 0 else "") + _format_large_number(value)
		return "+%d" % int(value) if value > 0 else "%d" % int(value)
	
	# Stats con decimales especiales (por segundo)
	if stat_name in ["health_regen", "shield_regen"]:
		if abs(value) >= 10000:
			return _format_large_number(value) + "/s"
		return "%.1f/s" % value
	
	# Default
	if abs(value) >= 10000:
		return _format_large_number(value)
	if value == int(value):
		return "%d" % int(value)
	return "%.1f" % value

func _get_value_color(stat_name: String, value: float) -> Color:
	"""Obtener color según el valor del stat - ACTUALIZADO v3.0
	
	Sistema de colores:
	- Verde: El stat está MEJOR que el valor base (buff)
	- Rojo: El stat está PEOR que el valor base (debuff)
	- Gris: El stat está en su valor base (neutral)
	
	Stats especiales donde MENOS es MEJOR:
	- damage_taken_mult: menor = menos daño recibido
	- curse: mayor es peor (más dificultad)
	"""
	const COLOR_BUFF = Color(0.3, 1.0, 0.4)    # Verde - mejora
	const COLOR_DEBUFF = Color(1.0, 0.4, 0.3)  # Rojo - empeora
	const COLOR_NEUTRAL = Color(0.8, 0.8, 0.8) # Gris - base
	
	# === STATS DONDE MENOS ES MEJOR ===
	var _less_is_better = ["damage_taken_mult", "curse"]
	
	# === STATS DONDE MÁS ES PEOR (pero se muestran como positivos) ===
	# curse es especial: más curse = más dificultad = malo
	if stat_name == "curse":
		if value > 0.0:
			return COLOR_DEBUFF  # Rojo porque curse es malo
		return COLOR_NEUTRAL
	
	# === STATS DE DAÑO RECIBIDO ===
	if stat_name == "damage_taken_mult":
		if value < 1.0:
			return COLOR_BUFF  # Verde - recibes menos daño
		elif value > 1.0:
			return COLOR_DEBUFF  # Rojo - recibes más daño
		return COLOR_NEUTRAL
	

	
	# === OBTENER VALOR BASE DEL STAT ===
	var base_value = _get_stat_base_value(stat_name)
	
	# === STATS CON MULTIPLICADOR (base 1.0) ===
	if stat_name.ends_with("_mult"):
		if value > 1.0:
			return COLOR_BUFF
		elif value < 1.0:
			return COLOR_DEBUFF
		return COLOR_NEUTRAL
	
	# === STATS NORMALES (más es mejor) ===
	if value > base_value:
		return COLOR_BUFF
	elif value < base_value:
		return COLOR_DEBUFF
	return COLOR_NEUTRAL

func _create_global_weapon_stats_section(parent: VBoxContainer) -> void:
	"""Crear sección de stats ofensivos globales que afectan a todas las armas"""
	# Separador
	var sep = HSeparator.new()
	parent.add_child(sep)
	
	# Título
	var title = Label.new()
	title.text = "⚔️ Stats de Armas (Global)"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	parent.add_child(title)
	
	# Obtener stats globales de armas (SOLO de GlobalWeaponStats, NO de PlayerStats)
	var global_stats = {}
	if attack_manager and attack_manager.has_method("_get_combined_global_stats"):
		global_stats = attack_manager._get_combined_global_stats()
	elif attack_manager and "global_weapon_stats" in attack_manager and attack_manager.global_weapon_stats:
		# Fallback: obtener de GlobalWeaponStats directamente
		var gws = attack_manager.global_weapon_stats
		if gws.has_method("get_all_stats"):
			global_stats = gws.get_all_stats()
	
	# Si no hay stats, usar valores base
	if global_stats.is_empty():
		global_stats = {
			"damage_mult": 1.0, "attack_speed_mult": 1.0, "area_mult": 1.0,
			"projectile_speed_mult": 1.0, "duration_mult": 1.0, "knockback_mult": 1.0,
			"range_mult": 1.0, "crit_chance": 0.05, "crit_damage": 2.0,
			"extra_projectiles": 0, "extra_pierce": 0, "damage_flat": 0
		}
	
	# Grid de stats en dos columnas
	var grid = GridContainer.new()
	grid.columns = 4  # icono+nombre, valor, icono+nombre, valor
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)
	
	# Lista de stats a mostrar con sus valores base
	var stats_to_show = [
		{"stat": "damage_mult", "name": "Daño", "icon": "⚔️", "base": 1.0, "format": "mult"},
		{"stat": "attack_speed_mult", "name": "Vel. Ataque", "icon": "⚡", "base": 1.0, "format": "mult"},
		{"stat": "crit_chance", "name": "Prob. Crítico", "icon": "🎯", "base": 0.05, "format": "percent"},
		{"stat": "crit_damage", "name": "Daño Crítico", "icon": "💢", "base": 2.0, "format": "mult_x"},
		{"stat": "area_mult", "name": "Área", "icon": "🌀", "base": 1.0, "format": "mult"},
		{"stat": "duration_mult", "name": "Duración", "icon": "⏳", "base": 1.0, "format": "mult"},
		{"stat": "projectile_speed_mult", "name": "Vel. Proyectil", "icon": "➡️", "base": 1.0, "format": "mult"},
		{"stat": "knockback_mult", "name": "Empuje", "icon": "💥", "base": 1.0, "format": "mult"},
		{"stat": "range_mult", "name": "Alcance", "icon": "📏", "base": 1.0, "format": "mult"},
		{"stat": "extra_projectiles", "name": "Proyectiles+", "icon": "🎯", "base": 0, "format": "int"},
		{"stat": "extra_pierce", "name": "Penetración+", "icon": "🗡️", "base": 0, "format": "int"},
		{"stat": "damage_flat", "name": "Daño Plano", "icon": "➕", "base": 0, "format": "int"},
	]
	
	for stat_info in stats_to_show:
		var stat_name = stat_info.stat
		var base_value = stat_info.base
		var current_value = global_stats.get(stat_name, base_value)
		
		# Verificar si está al límite (Cap)
		var is_capped = false
		if attack_manager and attack_manager.has_method("get_global_weapon_stats"): # O acceder directamente si es variable
			# Intentar acceder al gws para verificar el cap
			var gws = attack_manager.global_weapon_stats if "global_weapon_stats" in attack_manager else null
			if gws and gws.has_method("is_stat_capped"):
				is_capped = gws.is_stat_capped(stat_name)
		
		# Icono + Nombre
		var name_label = Label.new()
		name_label.text = "%s %s" % [stat_info.icon, stat_info.name]
		name_label.add_theme_font_size_override("font_size", 11)
		if is_capped:
			name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Dorado
		else:
			name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		name_label.custom_minimum_size = Vector2(110, 0)
		grid.add_child(name_label)
		
		# Valor
		var value_label = Label.new()
		var value_text = ""
		var value_color = Color(0.9, 0.9, 1.0)
		
		match stat_info.format:
			"mult":
				if abs(current_value - base_value) > 0.001:
					var percent = (current_value - 1.0) * 100
					if abs(percent) >= 10000:
						value_text = ("+" if percent > 0 else "") + _format_large_number(percent) + "%"
					else:
						value_text = "+%.0f%%" % percent if current_value >= 1.0 else "%.0f%%" % percent
					value_color = Color(0.3, 1.0, 0.4) if current_value > base_value else Color(1.0, 0.4, 0.4)
				else:
					value_text = "+0%"
			"mult_x":
				value_text = "x%.1f" % current_value
				if abs(current_value - base_value) > 0.01:
					value_color = Color(0.3, 1.0, 0.4) if current_value > base_value else Color(1.0, 0.4, 0.4)
			"percent":
				var percent = current_value * 100
				if abs(percent) >= 10000:
					value_text = _format_large_number(percent) + "%"
				else:
					value_text = "%.0f%%" % percent
				if abs(current_value - base_value) > 0.001:
					value_color = Color(0.3, 1.0, 0.4) if current_value > base_value else Color(1.0, 0.4, 0.4)
			"int":
				if abs(current_value) >= 10000:
					value_text = ("+" if current_value > 0 else "") + _format_large_number(current_value)
				else:
					value_text = "+%d" % int(current_value) if current_value > 0 else "%d" % int(current_value)
				if current_value != base_value:
					value_color = Color(0.3, 1.0, 0.4) if current_value > base_value else Color(1.0, 0.4, 0.4)
		
		# Override si está al cap
		if is_capped:
			value_text += " (MAX)"
			value_color = Color(1.0, 0.85, 0.2) # Dorado
			
		value_label.text = value_text
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", value_color)
		value_label.custom_minimum_size = Vector2(80, 0) # Un poco más ancho para (MAX)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(value_label)

func _format_large_number(value: float) -> String:
	"""Formatear números grandes con sufijos K, M, B"""
	if value >= 1_000_000_000:
		return "%.1fB" % (value / 1_000_000_000.0)
	if value >= 1_000_000:
		return "%.1fM" % (value / 1_000_000.0)
	if value >= 10_000:
		return "%.1fK" % (value / 1_000.0)
	return "%.0f" % value

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
	buffs_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

	# Usar GridContainer en lugar de HBoxContainer para que haga wrap
	var buffs_grid = GridContainer.new()
	buffs_grid.columns = 6  # Máximo 6 efectos por fila antes de hacer wrap
	buffs_grid.add_theme_constant_override("h_separation", 8)
	buffs_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(buffs_grid)

	# Agrupar efectos por fuente para mostrar condensado
	var effects_by_source: Dictionary = {}
	for stat_name in player_stats.temp_modifiers:
		for mod in player_stats.temp_modifiers[stat_name]:
			var source = mod.get("source", "unknown")
			if not effects_by_source.has(source):
				effects_by_source[source] = []
			effects_by_source[source].append({"stat": stat_name, "mod": mod})

	# Si es growth_bonus, mostrar condensado
	if effects_by_source.has("growth_bonus") and effects_by_source["growth_bonus"].size() > 3:
		# Mostrar un solo chip para growth
		var growth_effects = effects_by_source["growth_bonus"]
		var total_bonus = 0.0
		for effect in growth_effects:
			total_bonus += effect.mod.amount
		var growth_chip = _create_growth_summary_chip(growth_effects.size(), total_bonus)
		buffs_grid.add_child(growth_chip)
		effects_by_source.erase("growth_bonus")

	# Mostrar el resto de efectos normalmente
	# Mostrar el resto de efectos normalmente (CON LÍMITE)
	var max_display_buffs = 24  # Límite para evitar lag con muchos buffs
	var displayed_count = 0
	var hidden_count = 0
	
	for source in effects_by_source:
		for effect in effects_by_source[source]:
			if displayed_count < max_display_buffs:
				var buff_chip = _create_buff_chip(effect.stat, effect.mod)
				buffs_grid.add_child(buff_chip)
				displayed_count += 1
			else:
				hidden_count += 1
	
	# Mostrar chip de resumen si hay ocultos
	if hidden_count > 0:
		var more_chip = PanelContainer.new()
		var m_style = StyleBoxFlat.new()
		m_style.bg_color = Color(0.3, 0.3, 0.4)
		m_style.set_corner_radius_all(12)
		m_style.set_content_margin_all(5)
		more_chip.add_theme_stylebox_override("panel", m_style)
		
		var m_lbl = Label.new()
		m_lbl.text = "+%d más" % hidden_count
		m_lbl.add_theme_font_size_override("font_size", 11)
		more_chip.add_child(m_lbl)
		more_chip.tooltip_text = "%d efectos adicionales activos" % hidden_count
		buffs_grid.add_child(more_chip)

func _create_growth_summary_chip(count: int, _total_bonus: float) -> Control:
	"""Crear chip resumido para efectos de growth"""
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.25, 0.15)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	chip.add_child(hbox)

	var icon = Label.new()
	icon.text = "📈"
	icon.add_theme_font_size_override("font_size", 14)
	hbox.add_child(icon)

	var info = Label.new()
	info.text = "Growth x%d" % count
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	hbox.add_child(info)

	chip.tooltip_text = "📈 Crecimiento: %d stats mejorados\nBonus total acumulado" % count

	return chip

func _create_buff_chip(stat_name: String, mod: Dictionary) -> Control:
	"""Crear chip visual para un buff"""
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	
	# Color diferente para growth vs otros buffs
	var source = mod.get("source", "")
	if source == "growth_bonus":
		style.bg_color = Color(0.15, 0.25, 0.15)
	else:
		style.bg_color = Color(0.2, 0.15, 0.3)
	
	style.set_corner_radius_all(12)
	style.set_content_margin_all(5)
	chip.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	chip.add_child(hbox)

	var meta = {}
	if player_stats and player_stats.has_method("get_stat_metadata"):
		meta = player_stats.get_stat_metadata(stat_name)

	var icon = Label.new()
	icon.text = meta.get("icon", "✨")
	icon.add_theme_font_size_override("font_size", 12)
	hbox.add_child(icon)

	var info = Label.new()
	# Formato más compacto
	var amount_text = ""
	if mod.amount < 1 and mod.amount > 0:
		amount_text = "+%.0f%%" % (mod.amount * 100)
	elif mod.amount >= 1:
		amount_text = "+%.0f" % mod.amount
	else:
		amount_text = "%.0f%%" % (mod.amount * 100)
	
	# Si es growth_bonus (duración > 9000) no mostrar duración
	if mod.duration > 9000:
		info.text = amount_text
	else:
		info.text = "%s %.0fs" % [amount_text, mod.duration]
	
	info.add_theme_font_size_override("font_size", 10)
	info.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	hbox.add_child(info)

	chip.tooltip_text = "%s: %s%s" % [
		meta.get("name", stat_name),
		amount_text,
		"" if mod.duration > 9000 else " (%.0fs)" % mod.duration
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

# Helper para convertir enum de elemento a string
func _element_to_string(element_value) -> String:
	# Si ya es string, retornar en minúsculas
	if element_value is String:
		return element_value.to_lower()
	# Si es int (enum), mapear a nombre
	var element_names = ["ice", "fire", "lightning", "arcane", "shadow", "nature", "wind", "earth", "light", "void", "physical"]
	if element_value is int and element_value >= 0 and element_value < element_names.size():
		return element_names[element_value]
	return "physical"

# Helper para convertir enum de rareza a string
func _rarity_to_string(rarity_value) -> String:
	if rarity_value is String:
		return rarity_value.to_lower()
	var rarity_names = ["common", "uncommon", "rare", "epic", "legendary"]
	if rarity_value is int and rarity_value >= 0 and rarity_value < rarity_names.size():
		return rarity_names[rarity_value]
	return "common"

func _show_weapons_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(scroll)
	
	# Asignar scroll para navegación con teclado
	content_scroll = scroll

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

	# Grid de armas (1 columna para evitar corte)
	var weapons_grid = GridContainer.new()
	weapons_grid.columns = 1
	weapons_grid.add_theme_constant_override("h_separation", 12)
	weapons_grid.add_theme_constant_override("v_separation", 12)
	main_vbox.add_child(weapons_grid)

	for i in range(weapons.size()):
		var weapon = weapons[i]
		var weapon_card = _create_weapon_card(weapon)
		weapons_grid.add_child(weapon_card)

		# Registrar como elemento navegable con callback para mostrar detalles
		content_items.append({
			"panel": weapon_card,
			"type": "weapon",
			"index": i,
			"weapon": weapon,
			"callback": Callable(self, "_show_weapon_details").bind(weapon)
		})

func _create_weapon_card(weapon) -> Control:
	"""Crear tarjeta detallada de arma"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 0)  # Más pequeño para evitar desbordamiento
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Expandir para llenar columna

	# Obtener elemento y rareza (convertir a string si es enum/int)
	var element_raw = weapon.element if "element" in weapon else weapon.element_type if "element_type" in weapon else "physical"
	var element = str(element_raw).to_lower() if element_raw is String else _element_to_string(element_raw)
	var rarity_raw = weapon.rarity if "rarity" in weapon else "common"
	var rarity = str(rarity_raw).to_lower() if rarity_raw is String else _rarity_to_string(rarity_raw)
	var weapon_level = weapon.level if "level" in weapon else 1
	var max_level = weapon.max_level if "max_level" in weapon else 8

	# Mapear rareza a tier int
	var tier_map = {"common":1, "uncommon":2, "rare":3, "epic":4, "legendary":5}
	var tier = tier_map.get(rarity, 1)

	# Estilo usando UIVisualHelper
	# Nota: para armas en el menú de pausa, usamos el estilo "hover false" por defecto, 
	# el sistema de navegación le pondrá borde de selección después.
	var style = UIVisualHelper.get_panel_style(tier, false, true)
	
	# Override manual si queremos borde de ELEMENTO en lugar de TIER (opcional, pero consistente con diseño previo)
	# Decisión: Usar color de TIER para el borde para mantener consistencia visual global
	# El color de elemento se usa en iconos y textos.
	
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	
	# Glow del tier debajo
	UIVisualHelper.apply_tier_glow(card, tier)

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

	# Intentar cargar icono grafico
	var icon_tex: Texture2D = null
	# 1. Por ID si está disponible en el objeto weapon (o pasar id)
	if "id" in weapon:
		var asset_path = "res://assets/icons/%s.png" % weapon.id
		if ResourceLoader.exists(asset_path):
			icon_tex = load(asset_path)
	
	if icon_tex:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_tex
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_container.add_child(icon_rect)
	else:
		# Fallback: Verificar si weapon.icon es un path o un emoji
		var icon_str = weapon.icon if "icon" in weapon else ELEMENT_ICONS.get(element, "🔮")
		
		if icon_str.begins_with("res://"):
			# Es un path que no se cargó por ID, intentar cargar directo
			if ResourceLoader.exists(icon_str):
				var loaded_tex = load(icon_str)
				var icon_rect = TextureRect.new()
				icon_rect.texture = loaded_tex
				icon_rect.custom_minimum_size = Vector2(48, 48)
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_container.add_child(icon_rect)
			else:
				# Path inválido, mostrar emoji default
				var icon_lbl = Label.new()
				icon_lbl.text = ELEMENT_ICONS.get(element, "🔮")
				icon_lbl.add_theme_font_size_override("font_size", 32)
				icon_container.add_child(icon_lbl)
		else:
			# Es texto/emoji
			var icon_lbl = Label.new()
			icon_lbl.text = icon_str
			icon_lbl.add_theme_font_size_override("font_size", 32)
			icon_container.add_child(icon_lbl)

	# Info del nombre
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(info_vbox)

	var weapon_name = weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.weapon_name if "weapon_name" in weapon else "Arma"
	var name_label = Label.new()
	
	# Verificar si es fusión y agregar badge
	var is_fusion = false
	if "id" in weapon and WeaponDatabase.is_fusion_weapon(weapon.id):
		is_fusion = true
		name_label.text = "🔥 " + weapon_name
	else:
		name_label.text = weapon_name
	
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", _get_color_by_rarity(rarity))
	info_vbox.add_child(name_label)

	# Elemento y tipo
	var type_label = Label.new()
	var element_display = ELEMENT_ICONS.get(element, "❓") + " " + element.capitalize()
	if is_fusion:
		element_display = "🔥 FUSIÓN • " + element_display
	type_label.text = element_display
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color.GRAY) if not is_fusion else Color(1.0, 0.7, 0.3))
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

	# === STATS DEL ARMA (con mejoras globales aplicadas) ===
	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(stats_grid)

	# Obtener stats completos con mejoras globales
	var full_stats = {}
	if attack_manager and attack_manager.has_method("get_weapon_full_stats"):
		full_stats = attack_manager.get_weapon_full_stats(weapon)
	
	# Usar full_stats si están disponibles, sino usar valores del weapon directamente
	if not full_stats.is_empty():
		# ═══ DAÑO ═══
		var dmg_base = full_stats.get("damage_base", 0)
		var dmg_final = full_stats.get("damage_final", 0)
		if dmg_final != dmg_base:
			_add_weapon_stat(stats_grid, "⚔️", "Daño", "%s→%s" % [_format_large_number(dmg_base), _format_large_number(dmg_final)], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "⚔️", "Daño", "%s" % _format_large_number(dmg_final))
		
		# ═══ VELOCIDAD DE ATAQUE ═══
		var as_base = full_stats.get("attack_speed_base", 1.0)
		var as_final = full_stats.get("attack_speed_final", 1.0)
		if abs(as_final - as_base) > 0.01:
			_add_weapon_stat(stats_grid, "⚡", "Vel. Ataque", "%.2f→%.2f/s" % [as_base, as_final], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "⚡", "Vel. Ataque", "%.2f/s" % as_final)
		
		# ═══ COOLDOWN ═══
		var cd_base = full_stats.get("cooldown_base", 1.0)
		var cd_final = full_stats.get("cooldown_final", 1.0)
		if abs(cd_final - cd_base) > 0.01:
			_add_weapon_stat(stats_grid, "⏱", "Cooldown", "%.2f→%.2fs" % [cd_base, cd_final], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "⏱", "Cooldown", "%.2fs" % cd_final)
		
		# ═══ PROYECTILES ═══
		var proj_base = full_stats.get("projectile_count_base", 1)
		var proj_final = full_stats.get("projectile_count_final", 1)
		if proj_final != proj_base:
			_add_weapon_stat(stats_grid, "🎯", "Proyectiles", "%d→%d" % [proj_base, proj_final], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "🎯", "Proyectiles", "%d" % proj_final)
		
		# ═══ VELOCIDAD DE PROYECTIL ═══
		var ps_base = full_stats.get("projectile_speed_base", 300.0)
		var ps_final = full_stats.get("projectile_speed_final", 300.0)
		if abs(ps_final - ps_base) > 1:
			_add_weapon_stat(stats_grid, "➡️", "Vel. Proyectil", "%.0f→%.0f" % [ps_base, ps_final], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "➡️", "Vel. Proyectil", "%.0f" % ps_final)
		
		# ═══ ÁREA ═══
		var area_base = full_stats.get("area_base", 1.0)
		var area_final = full_stats.get("area_final", 1.0)
		if abs(area_final - area_base) > 0.01:
			_add_weapon_stat(stats_grid, "🌀", "Área", "%.0f%%→%.0f%%" % [area_base * 100, area_final * 100], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "🌀", "Área", "%.0f%%" % (area_final * 100))
		
		# ═══ ALCANCE ═══
		var range_base = full_stats.get("range_base", 300.0)
		var range_final = full_stats.get("range_final", 300.0)
		if abs(range_final - range_base) > 1:
			_add_weapon_stat(stats_grid, "📏", "Alcance", "%.0f→%.0f" % [range_base, range_final], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "📏", "Alcance", "%.0f" % range_final)
		
		# ═══ EMPUJE ═══
		var kb_base = full_stats.get("knockback_base", 50.0)
		var kb_final = full_stats.get("knockback_final", 50.0)
		if abs(kb_final - kb_base) > 1:
			_add_weapon_stat(stats_grid, "💥", "Empuje", "%.0f→%.0f" % [kb_base, kb_final], Color(0.3, 1.0, 0.4))
		else:
			_add_weapon_stat(stats_grid, "💥", "Empuje", "%.0f" % kb_final)
		
		# ═══ DURACIÓN ═══
		var dur_base = full_stats.get("duration_base", 0.0)
		var dur_final = full_stats.get("duration_final", 0.0)
		if dur_final > 0 or dur_base > 0:
			if abs(dur_final - dur_base) > 0.01:
				_add_weapon_stat(stats_grid, "⏳", "Duración", "%.1f→%.1fs" % [dur_base, dur_final], Color(0.3, 1.0, 0.4))
			else:
				_add_weapon_stat(stats_grid, "⏳", "Duración", "%.1fs" % dur_final)
		
		# ═══ PENETRACIÓN ═══
		var pierce_base = full_stats.get("pierce_base", 0)
		var pierce_final = full_stats.get("pierce_final", 0)
		if pierce_final > 0 or pierce_base > 0:
			if pierce_final != pierce_base:
				_add_weapon_stat(stats_grid, "🗡️", "Atravesar", "%d→%d" % [pierce_base, pierce_final], Color(0.3, 1.0, 0.4))
			else:
				_add_weapon_stat(stats_grid, "🗡️", "Atravesar", "%d" % pierce_final)
	else:
		# Fallback: usar datos del weapon directamente (sin full_stats)
		if "damage" in weapon:
			_add_weapon_stat(stats_grid, "⚔️", "Daño", "%s" % _format_large_number(weapon.damage))
		if "cooldown" in weapon:
			var attack_speed = 1.0 / weapon.cooldown if weapon.cooldown > 0 else 1.0
			_add_weapon_stat(stats_grid, "⚡", "Vel. Ataque", "%.2f/s" % attack_speed)
			_add_weapon_stat(stats_grid, "⏱", "Cooldown", "%.2fs" % weapon.cooldown)
		if "projectile_count" in weapon:
			_add_weapon_stat(stats_grid, "🎯", "Proyectiles", "%d" % weapon.projectile_count)
		if "projectile_speed" in weapon:
			_add_weapon_stat(stats_grid, "➡️", "Vel. Proyectil", "%.0f" % weapon.projectile_speed)
		if "area" in weapon:
			_add_weapon_stat(stats_grid, "🌀", "Área", "%.0f%%" % (weapon.area * 100))
		if "weapon_range" in weapon:
			_add_weapon_stat(stats_grid, "📏", "Alcance", "%.0f" % weapon.weapon_range)
		if "knockback" in weapon:
			_add_weapon_stat(stats_grid, "💥", "Empuje", "%.0f" % weapon.knockback)
		if "duration" in weapon and weapon.duration > 0:
			_add_weapon_stat(stats_grid, "⏳", "Duración", "%.1fs" % weapon.duration)
		if "pierce" in weapon and weapon.pierce > 0:
			_add_weapon_stat(stats_grid, "🗡️", "Atravesar", "%d" % weapon.pierce)

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

	# Conectar señal de hover para sonido
	if not card.mouse_entered.is_connected(_on_element_hover):
		card.mouse_entered.connect(_on_element_hover)

	return card

func _on_element_hover() -> void:
	AudioManager.play_fixed("sfx_ui_hover")

func _add_weapon_stat(grid: GridContainer, icon: String, stat_name: String, value: String, value_color: Color = Color(0.9, 0.9, 1.0)) -> void:
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
	value_label.add_theme_color_override("font_color", value_color)
	hbox.add_child(value_label)

	grid.add_child(hbox)

func _get_weapon_special_effect(weapon) -> String:
	"""Obtener descripción del efecto especial del arma"""
	var element_raw = weapon.element if "element" in weapon else weapon.element_type if "element_type" in weapon else ""
	var element = str(element_raw).to_lower() if element_raw is String else _element_to_string(element_raw)

	# Efectos por defecto según elemento
	match element:
		"ice":
			var slow = weapon.slow_amount if "slow_amount" in weapon else 0.4
			return "Ralentiza enemigos un %.0f%%" % (slow * 100)
		"fire":
			return "Inflige quemadura (daño continuo)"
		"lightning":
			var chains = weapon.effect_value if "effect_value" in weapon and weapon.effect == "chain" else 2
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
# POPUP: DETALLES DE ARMA
# ═══════════════════════════════════════════════════════════════════════════════

var _weapon_details_popup: Control = null
var _weapon_popup_scroll: ScrollContainer = null  # Scroll del popup para navegación WASD

func _show_weapon_details(weapon) -> void:
	"""Mostrar popup con todos los stats detallados del arma"""
	# Cerrar popup anterior si existe
	if _weapon_details_popup and is_instance_valid(_weapon_details_popup):
		_weapon_details_popup.queue_free()
	
	# Crear el popup
	_weapon_details_popup = _create_weapon_details_popup(weapon)
	add_child(_weapon_details_popup)

func _create_weapon_details_popup(weapon) -> Control:
	"""Crear el popup de detalles del arma con TODOS los stats incluidos globales"""
	# Contenedor principal que cubre toda la pantalla
	var overlay = Control.new()
	overlay.name = "WeaponDetailsPopup"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fondo oscuro semi-transparente
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	overlay.add_child(bg)
	
	# Panel central con scroll
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 550)
	
	# Obtener stats completos del arma (con globales aplicados)
	var stats = {}
	if attack_manager and attack_manager.has_method("get_weapon_full_stats"):
		stats = attack_manager.get_weapon_full_stats(weapon)
	
	# Fallback a datos básicos del weapon si no hay stats
	var element_raw = stats.get("element", weapon.element if "element" in weapon else weapon.element_type if "element_type" in weapon else "physical")
	var element = str(element_raw).to_lower() if element_raw is String else _element_to_string(element_raw)
	var element_color = ELEMENT_COLORS.get(element, Color.WHITE)
	
	# Estilo del panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12)
	style.border_color = element_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center_container.add_child(panel)
	
	# Scroll container para contenido largo
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_weapon_popup_scroll = scroll  # Guardar referencia para navegación WASD
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(main_vbox)
	
	# === HEADER ===
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	main_vbox.add_child(header)
	
	# Icono grande
	var icon_container = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = element_color.darkened(0.6)
	icon_style.set_corner_radius_all(10)
	icon_style.set_content_margin_all(12)
	icon_container.add_theme_stylebox_override("panel", icon_style)
	header.add_child(icon_container)
	
	var icon = Label.new()
	icon.text = stats.get("icon", weapon.icon if "icon" in weapon else ELEMENT_ICONS.get(element, "🔮"))
	icon.add_theme_font_size_override("font_size", 48)
	icon_container.add_child(icon)
	
	# Info del nombre
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)
	
	var weapon_name = stats.get("weapon_name_es", weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.weapon_name if "weapon_name" in weapon else "Arma")
	var name_label = Label.new()
	name_label.text = weapon_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", element_color)
	info_vbox.add_child(name_label)
	
	# Nivel y elemento
	var weapon_level = stats.get("level", weapon.level if "level" in weapon else 1)
	var max_level = stats.get("max_level", weapon.max_level if "max_level" in weapon else 8)
	var level_text = "Nivel %d/%d • %s" % [weapon_level, max_level, element.capitalize()]
	var level_label = Label.new()
	level_label.text = level_text
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	info_vbox.add_child(level_label)
	
	# Separador
	var sep1 = HSeparator.new()
	main_vbox.add_child(sep1)
	
	# === ESTADÍSTICAS BASE DEL ARMA ===
	var stats_label = Label.new()
	stats_label.text = "📊 STATS DEL ARMA"
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", SELECTED_TAB)
	main_vbox.add_child(stats_label)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 30)
	stats_grid.add_theme_constant_override("v_separation", 6)
	main_vbox.add_child(stats_grid)
	
	# Usar stats calculados si están disponibles, sino fallback
	if not stats.is_empty():
		# Daño (base → final)
		_add_stat_with_bonus(stats_grid, "⚔️ Daño", 
			stats.get("damage_base", 0), 
			stats.get("damage_final", 0),
			stats.get("damage_mult", 1.0))
		
		# Velocidad de Ataque
		_add_stat_with_bonus(stats_grid, "⚡ Vel. Ataque", 
			stats.get("attack_speed_base", 1.0), 
			stats.get("attack_speed_final", 1.0),
			stats.get("attack_speed_mult", 1.0),
			"/s")
		
		# Cooldown
		_add_detail_stat(stats_grid, "⏱️ Cooldown", "%.2fs" % stats.get("cooldown_final", 1.0))
		
		# Proyectiles
		var _proj_base = stats.get("projectile_count_base", 1)
		var proj_final = stats.get("projectile_count_final", 1)
		var proj_extra = stats.get("extra_projectiles", 0)
		if proj_extra > 0:
			_add_detail_stat(stats_grid, "🎯 Proyectiles", "%d (+%d)" % [proj_final, proj_extra])
		else:
			_add_detail_stat(stats_grid, "🎯 Proyectiles", "%d" % proj_final)
		
		# Velocidad de Proyectil
		_add_stat_with_bonus(stats_grid, "➡️ Vel. Proyectil", 
			stats.get("projectile_speed_base", 400), 
			stats.get("projectile_speed_final", 400),
			stats.get("projectile_speed_mult", 1.0))
		
		# Penetración
		var pierce_final = stats.get("pierce_final", 0)
		var pierce_extra = stats.get("extra_pierce", 0)
		if pierce_final > 0 or pierce_extra > 0:
			if pierce_extra > 0:
				_add_detail_stat(stats_grid, "🗡️ Penetración", "%d (+%d)" % [pierce_final, pierce_extra])
			else:
				_add_detail_stat(stats_grid, "🗡️ Penetración", "%d" % pierce_final)
		
		# Área
		_add_stat_with_bonus(stats_grid, "🌀 Área", 
			stats.get("area_base", 1.0) * 100, 
			stats.get("area_final", 1.0) * 100,
			stats.get("area_mult", 1.0),
			"%")
		
		# Alcance
		_add_stat_with_bonus(stats_grid, "🎯 Alcance", 
			stats.get("range_base", 500), 
			stats.get("range_final", 500),
			stats.get("range_mult", 1.0))
		
		# Empuje
		_add_stat_with_bonus(stats_grid, "💥 Empuje", 
			stats.get("knockback_base", 100), 
			stats.get("knockback_final", 100),
			stats.get("knockback_mult", 1.0))
		
		# Duración
		_add_stat_with_bonus(stats_grid, "⌛ Duración", 
			stats.get("duration_base", 1.0), 
			stats.get("duration_final", 1.0),
			stats.get("duration_mult", 1.0),
			"s")
	else:
		pass  # Bloque else
		# Fallback: mostrar datos básicos del weapon
		if "damage" in weapon:
			_add_detail_stat(stats_grid, "⚔️ Daño Base", "%.0f" % weapon.damage)
		if "cooldown" in weapon or "base_cooldown" in weapon:
			var cd = weapon.cooldown if "cooldown" in weapon else weapon.base_cooldown
			_add_detail_stat(stats_grid, "⏱️ Cooldown", "%.2f s" % cd)
		if "projectile_count" in weapon:
			_add_detail_stat(stats_grid, "🎯 Proyectiles", "%d" % weapon.projectile_count)
		if "projectile_speed" in weapon:
			_add_detail_stat(stats_grid, "➡️ Vel. Proyectil", "%.0f" % weapon.projectile_speed)
	
	# === STATS GLOBALES (CRÍTICOS) ===
	var sep_crit = HSeparator.new()
	main_vbox.add_child(sep_crit)
	
	var crit_label = Label.new()
	crit_label.text = "🎲 CRÍTICOS (Global)"
	crit_label.add_theme_font_size_override("font_size", 16)
	crit_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	main_vbox.add_child(crit_label)
	
	var crit_grid = GridContainer.new()
	crit_grid.columns = 2
	crit_grid.add_theme_constant_override("h_separation", 30)
	crit_grid.add_theme_constant_override("v_separation", 6)
	main_vbox.add_child(crit_grid)
	
	var crit_chance = stats.get("crit_chance", 0.05)
	var crit_damage = stats.get("crit_damage", 2.0)
	_add_detail_stat(crit_grid, "🎲 Prob. Crítico", "%.0f%%" % (crit_chance * 100))
	_add_detail_stat(crit_grid, "💢 Daño Crítico", "x%.1f" % crit_damage)
	
	# === MEJORAS GLOBALES ACTIVAS ===
	var global_upgrades = stats.get("global_upgrades", [])
	if not global_upgrades.is_empty():
		var sep_upgrades = HSeparator.new()
		main_vbox.add_child(sep_upgrades)
		
		var upgrades_title = Label.new()
		upgrades_title.text = "📦 MEJORAS GLOBALES (%d)" % global_upgrades.size()
		upgrades_title.add_theme_font_size_override("font_size", 16)
		upgrades_title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		main_vbox.add_child(upgrades_title)
		
		var upgrades_container = VBoxContainer.new()
		upgrades_container.add_theme_constant_override("separation", 2)
		main_vbox.add_child(upgrades_container)
		
		for upgrade in global_upgrades:
			var upgrade_name = upgrade.get("name", "Mejora")
			var upgrade_label = Label.new()
			upgrade_label.text = "• " + upgrade_name
			upgrade_label.add_theme_font_size_override("font_size", 12)
			upgrade_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			upgrades_container.add_child(upgrade_label)
	
	# === EFECTO ESPECIAL ===
	var special_effect = _get_weapon_special_effect(weapon)
	if special_effect != "":
		var sep2 = HSeparator.new()
		main_vbox.add_child(sep2)
		
		var effect_title = Label.new()
		effect_title.text = "✨ EFECTO ESPECIAL"
		effect_title.add_theme_font_size_override("font_size", 16)
		effect_title.add_theme_color_override("font_color", element_color)
		main_vbox.add_child(effect_title)
		
		var effect_label = Label.new()
		effect_label.text = special_effect
		effect_label.add_theme_font_size_override("font_size", 14)
		effect_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		main_vbox.add_child(effect_label)
	
	# === DESCRIPCIÓN ===
	var description = weapon.description if "description" in weapon else ""
	if description != "":
		var sep3 = HSeparator.new()
		main_vbox.add_child(sep3)
		
		var desc_label = Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		main_vbox.add_child(desc_label)
	
	# === BOTÓN CERRAR ===
	var close_container = CenterContainer.new()
	main_vbox.add_child(close_container)
	
	var close_btn = Button.new()
	close_btn.text = "Cerrar [ESC / Espacio]"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(_close_weapon_details)
	close_container.add_child(close_btn)
	
	# Dar foco al botón
	close_btn.call_deferred("grab_focus")
	
	return overlay

func _add_detail_stat(grid: GridContainer, stat_name: String, value: String) -> void:
	"""Añadir stat al grid de detalles"""
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	grid.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_label)

func _add_stat_with_bonus(grid: GridContainer, stat_name: String, base_value: float, final_value: float, _multiplier: float, suffix: String = "") -> void:
	"""Añadir stat al grid mostrando valor base y final si hay bonus"""
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	grid.add_child(name_label)
	
	var value_label = Label.new()
	# Detectar bonus: comparar directamente base vs final, o si hay multiplicador global
	var threshold = 0.01 if (suffix == "/s" or suffix == "s") else 0.5
	var has_bonus = abs(final_value - base_value) > threshold
	
	if has_bonus:
		# Mostrar base → final en verde
		if suffix == "/s":
			value_label.text = "%.2f→%.2f%s" % [base_value, final_value, suffix]
		elif suffix == "s":
			value_label.text = "%.1f→%.1f%s" % [base_value, final_value, suffix]
		elif suffix == "%":
			value_label.text = "%.0f%%→%.0f%%" % [base_value, final_value]
		else:
			value_label.text = "%.0f→%.0f" % [base_value, final_value]
		value_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))  # Verde
	else:
		# Sin bonus, mostrar solo valor final
		if suffix == "/s":
			value_label.text = "%.2f%s" % [final_value, suffix]
		elif suffix == "s":
			value_label.text = "%.1f%s" % [final_value, suffix]
		elif suffix == "%":
			value_label.text = "%.0f%%" % final_value
		else:
			value_label.text = "%.0f" % final_value
		value_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_label)

func _close_weapon_details() -> void:
	"""Cerrar el popup de detalles del arma"""
	if _weapon_details_popup and is_instance_valid(_weapon_details_popup):
		_weapon_details_popup.queue_free()
		_weapon_details_popup = null
		_weapon_popup_scroll = null  # Limpiar referencia del scroll

func _handle_weapon_popup_input(event: InputEvent) -> bool:
	"""Manejar input cuando el popup está abierto (incluye WASD scroll)"""
	if not _weapon_details_popup or not is_instance_valid(_weapon_details_popup):
		return false
	
	# Cerrar con ESC, Enter, Space, Pause o cast_spell
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause") or event.is_action_pressed("cast_spell"):
		_close_weapon_details()
		return true
	
	# Scroll con W/S o flechas arriba/abajo
	if _weapon_popup_scroll and is_instance_valid(_weapon_popup_scroll):
		var scroll_amount = 50  # Píxeles por pulsación
		if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
			_weapon_popup_scroll.scroll_vertical -= scroll_amount
			return true
		if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
			_weapon_popup_scroll.scroll_vertical += scroll_amount
			return true
	
	return false

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

	# Agrupar items duplicados
	var grouped_upgrades = {}
	var upgrade_order = []  # Para mantener orden de aparición
	
	for upgrade in upgrades:
		var u_name = upgrade.get("name", "Unknown")
		if not grouped_upgrades.has(u_name):
			grouped_upgrades[u_name] = {"data": upgrade, "count": 0}
			upgrade_order.append(u_name)
		grouped_upgrades[u_name].count += 1

	for i in range(upgrade_order.size()):
		var u_name = upgrade_order[i]
		var info = grouped_upgrades[u_name]
		var upgrade_panel = _create_upgrade_panel(info.data, info.count)
		grid.add_child(upgrade_panel)

		# Registrar como elemento navegable
		content_items.append({
			"panel": upgrade_panel,
			"type": "upgrade",
			"index": i,
			"upgrade": info.data,
			"callback": Callable()
		})

func _create_upgrade_panel(upgrade: Dictionary, count: int = 1) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 100)
	
	# Obtener tier para colores
	var item_tier = upgrade.get("tier", upgrade.get("rarity", 1))
	if item_tier is String:
		var tier_map = {"common": 1, "uncommon": 2, "rare": 3, "epic": 4, "legendary": 5}
		item_tier = tier_map.get(item_tier.to_lower(), 1)
	
	var tier_color = UIVisualHelper.get_color_for_tier(item_tier)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = tier_color.darkened(0.3)  # Borde del color del tier
	style.set_border_width_all(2)
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
	name_label.add_theme_color_override("font_color", tier_color)  # Usar tier_color ya calculado
	header.add_child(name_label)
	
	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))  # Dorado
		header.add_child(count_label)

	# Descripción
	var desc = Label.new()
	desc.text = upgrade.get("description", "")
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Conectar señal de hover para sonido
	if not panel.mouse_entered.is_connected(_on_element_hover):
		panel.mouse_entered.connect(_on_element_hover)

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

	# Si el popup de detalles de arma está abierto, manejar su input primero
	if _weapon_details_popup and is_instance_valid(_weapon_details_popup):
		# Usar la función dedicada para manejar el input del popup
		if _handle_weapon_popup_input(event):
			_safe_handle_input()
			return
		# Bloquear cualquier otro input mientras el popup está abierto
		_safe_handle_input()
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

	# Si estamos en CONTENT y hay scroll
	if current_nav_row == NavRow.CONTENT:
		# CASO ESPECIAL: Tab de Armas (1) es una lista vertical.
		# W/S debe cambiar la selección de item, no solo scrollear.
		if current_tab == 1 and content_items.size() > 0:
			# Manejo de navegación con salida del grid
			if direction > 0: # Abajo
				if content_selection >= content_items.size() - 1:
					# Estamos al final, salir a acciones
					current_nav_row = NavRow.ACTIONS
					_update_navigation_visuals()
					return
				else:
					content_selection += 1
			else: # Arriba
				if content_selection <= 0:
					# Estamos al inicio, salir a tabs
					current_nav_row = NavRow.TABS
					_update_navigation_visuals()
					return
				else:
					content_selection -= 1
					
			_update_content_selection_visual()
			
			# Auto-scroll para seguir la selección
			if content_scroll and content_items[content_selection].has("panel"):
				var item_panel = content_items[content_selection].panel
				if item_panel:
					# Calcular posición relativa básica para scroll
					var item_y = item_panel.position.y
					var scroll_y = content_scroll.scroll_vertical
					var view_h = content_scroll.size.y
					
					if item_y < scroll_y:
						content_scroll.scroll_vertical = int(item_y)
					elif item_y + item_panel.size.y > scroll_y + view_h:
						content_scroll.scroll_vertical = int(item_y + item_panel.size.y - view_h)
			return

		# Para otros tabs (Stats, Objetos) mantener comportamiento de scroll/salir normal
		if content_scroll:
			var scroll_amount = 60  # Pixeles a scrollear por pulsacion
			var current_v = content_scroll.scroll_vertical
			var max_v = content_scroll.get_v_scroll_bar().max_value - content_scroll.size.y

			if direction < 0:  # W - Scroll arriba
				if current_v > 0:
					content_scroll.scroll_vertical = maxi(0, current_v - scroll_amount)
					return
				else:
					pass  # Bloque else
					# Ya estamos arriba, ir a tabs
					current_nav_row = NavRow.TABS
			else:  # S - Scroll abajo
				if current_v < max_v:
					content_scroll.scroll_vertical = mini(int(max_v), current_v + scroll_amount)
					return
				else:
					pass  # Bloque else
					# Ya estamos abajo, ir a actions
					current_nav_row = NavRow.ACTIONS
	elif direction < 0:  # Arriba (W) desde ACTIONS
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
		AudioManager.play_fixed("sfx_ui_hover")
	elif content_scroll and content_items.size() > 0 and direction != 0:
		# Si hubo scroll o cambio de selección
		AudioManager.play_fixed("sfx_ui_hover")

func _navigate_horizontal(direction: int) -> void:
	"""Navegar izquierda/derecha dentro de la fila actual"""
	var changed = false
	match current_nav_row:
		NavRow.TABS:
			current_tab = (current_tab + direction) % tab_buttons.size()
			if current_tab < 0:
				current_tab = tab_buttons.size() - 1
			_update_tabs_visual()
			_show_tab_content()
			changed = true
		NavRow.CONTENT:
			if content_items.size() > 0:
				content_selection = (content_selection + direction) % content_items.size()
				if content_selection < 0:
					content_selection = content_items.size() - 1
				_update_content_selection_visual()
				changed = true
		NavRow.ACTIONS:
			action_selection = (action_selection + direction) % action_buttons.size()
			if action_selection < 0:
				action_selection = action_buttons.size() - 1
			_update_action_buttons_visual()
			changed = true
			
	if changed:
		AudioManager.play_fixed("sfx_ui_hover")

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
				var style = panel.get_theme_stylebox("panel").duplicate()
				
				# Determinar si está seleccionado
				var is_selected = (i == content_selection and current_nav_row == NavRow.CONTENT)
				
				if style is StyleBoxFlat:
					if is_selected:
						style.border_color = SELECTED_TAB
						style.set_border_width_all(3)
					else:
						style.border_color = Color(0.3, 0.3, 0.4)
						style.set_border_width_all(1)
				elif style is StyleBoxTexture:
					# Para texturas, usaremos tinte (modulate_color)
					if is_selected:
						style.modulate_color = SELECTED_TAB
					else:
						# Mantener color original del helper o resetear
						# Asumimos que el helper devuelve blanco o un tinte base. 
						# Si queremos ser precisos, deberíamos leer el base_style nuevamente
						# pero por ahora resetear a blanco es seguro.
						style.modulate_color = Color.WHITE
						
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

	# Nuevo: Guardar tiempo de juego acumulado en esta sesión (para estadísticas globales)
	if get_tree().current_scene.has_method("save_session_playtime"):
		get_tree().current_scene.save_session_playtime()

	# Guardar el estado completo del juego para poder reanudarlo
	_save_game_state_for_resume()

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _save_game_state_for_resume() -> void:
	"""Guardar todo el estado necesario para reanudar la partida"""
	# Actualizar referencias antes de guardar
	_find_references()
	
	var game_state: Dictionary = {}
	
	# Tiempo de juego
	game_state["game_time"] = game_time
	
	# Arena seed y estado completo - IMPORTANTE para mantener el mismo mapa y zonas desbloqueadas
	var game_node = get_tree().current_scene
	if game_node and game_node.has_node("ArenaManager"):
		var arena_mgr = game_node.get_node("ArenaManager")
		if "arena_seed" in arena_mgr:
			game_state["arena_seed"] = arena_mgr.arena_seed
		# Guardar estado completo del ArenaManager (zonas desbloqueadas, biomas)
		if arena_mgr.has_method("to_save_data"):
			game_state["arena_manager_state"] = arena_mgr.to_save_data()
	
	# Estado del jugador
	if player_ref:
		# Convertir Vector2 a diccionario para serialización JSON
		var pos = player_ref.global_position
		game_state["player_position"] = {"x": pos.x, "y": pos.y}
		
		# HP del jugador - buscar en varias ubicaciones posibles
		var health_component = null
		
		# 1. Propiedad directa en player_ref (LoopiaLikePlayer guarda referencia)
		if "health_component" in player_ref and player_ref.health_component:
			health_component = player_ref.health_component
		
		# 2. Buscar en wizard_player
		if not health_component and "wizard_player" in player_ref and player_ref.wizard_player:
			if "health_component" in player_ref.wizard_player:
				health_component = player_ref.wizard_player.health_component
			else:
				health_component = player_ref.wizard_player.get_node_or_null("HealthComponent")
		
		# 3. Buscar como nodo hijo directo
		if not health_component:
			health_component = player_ref.get_node_or_null("HealthComponent")
		
		# 4. Buscar en WizardPlayer como nodo
		if not health_component:
			var wp = player_ref.get_node_or_null("WizardPlayer")
			if wp:
				health_component = wp.get_node_or_null("HealthComponent")
		
		if health_component:
			# HealthComponent usa current_health/max_health, NO current_hp/max_hp
			var hp_val = 100
			var max_hp_val = 100
			if "current_health" in health_component:
				hp_val = health_component.current_health
			elif "current_hp" in health_component:
				hp_val = health_component.current_hp
			if "max_health" in health_component:
				max_hp_val = health_component.max_health
			elif "max_hp" in health_component:
				max_hp_val = health_component.max_hp
			game_state["player_hp"] = hp_val
			game_state["player_max_hp"] = max_hp_val
		else:
			game_state["player_hp"] = 100
			game_state["player_max_hp"] = 100
	
	# Nivel del jugador - obtener de ExperienceManager primero (fuente de verdad)
	var player_level: int = 1
	if experience_manager_ref:
		if "current_level" in experience_manager_ref:
			player_level = experience_manager_ref.current_level
		elif "level" in experience_manager_ref:
			player_level = experience_manager_ref.level
	elif player_stats and "level" in player_stats:
		player_level = player_stats.level
	
	game_state["player_level"] = player_level
	
	# Stats del jugador
	if player_stats:
		# Guardar todos los stats usando to_dict() que incluye collected_upgrades
		if player_stats.has_method("to_dict"):
			game_state["player_stats"] = player_stats.to_dict()
		elif player_stats.has_method("get_all_stats"):
			game_state["player_stats"] = player_stats.get_all_stats()
			# También guardar collected_upgrades si existe
			if "collected_upgrades" in player_stats:
				game_state["player_stats"]["collected_upgrades"] = player_stats.collected_upgrades.duplicate(true)
		elif "stats" in player_stats:
			game_state["player_stats"] = player_stats.stats.duplicate()
			# También guardar collected_upgrades si existe
			if "collected_upgrades" in player_stats:
				game_state["player_stats"]["collected_upgrades"] = player_stats.collected_upgrades.duplicate(true)
	
	# Mejoras globales de armas (GlobalWeaponStats)
	if attack_manager and "global_weapon_stats" in attack_manager and attack_manager.global_weapon_stats:
		if attack_manager.global_weapon_stats.has_method("to_dict"):
			game_state["global_weapon_stats"] = attack_manager.global_weapon_stats.to_dict()
	
	# Armas equipadas
	if attack_manager and attack_manager.has_method("get_weapons"):
		var weapons_data: Array = []
		for weapon in attack_manager.get_weapons():
			var weapon_info = {
				"weapon_id": weapon.weapon_id if "weapon_id" in weapon else "",
				"level": weapon.level if "level" in weapon else 1,
			}
			# Guardar stats del arma si existen
			if weapon.has_method("get_stats"):
				weapon_info["stats"] = weapon.get_stats()
			weapons_data.append(weapon_info)
		game_state["weapons"] = weapons_data
	
	# Experiencia
	if experience_manager_ref:
		game_state["current_exp"] = experience_manager_ref.current_exp if "current_exp" in experience_manager_ref else 0
		game_state["exp_to_next_level"] = experience_manager_ref.exp_to_next_level if "exp_to_next_level" in experience_manager_ref else 10
		game_state["total_exp"] = experience_manager_ref.total_exp if "total_exp" in experience_manager_ref else 0
		# IMPORTANTE: ExperienceManager usa total_coins, no coins
		var saved_coins = experience_manager_ref.total_coins if "total_coins" in experience_manager_ref else 0
		game_state["coins"] = saved_coins
	
	# ═══════════════════════════════════════════════════════════════════════════════
	# Guardar contadores de Reroll y Banish del LevelUpPanel
	# ═══════════════════════════════════════════════════════════════════════════════
	if game_node and "remaining_rerolls" in game_node:
		game_state["remaining_rerolls"] = game_node.remaining_rerolls
	if game_node and "remaining_banishes" in game_node:
		game_state["remaining_banishes"] = game_node.remaining_banishes
	
	# ═══════════════════════════════════════════════════════════════════════════════
	# Guardar run_stats (kills, damage, etc) para restaurar el contador de enemigos
	# ═══════════════════════════════════════════════════════════════════════════════
	if game_node and "run_stats" in game_node:
		game_state["run_stats"] = game_node.run_stats.duplicate()
	
	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Guardar estado del WaveManager (fase, oleadas, boss, elites, eventos)
	# ═══════════════════════════════════════════════════════════════════════════════
	if game_node and game_node.has_node("WaveManager"):
		var wave_mgr = game_node.get_node("WaveManager")
		if wave_mgr.has_method("to_save_data"):
			game_state["wave_manager_state"] = wave_mgr.to_save_data()
	
	# ═══════════════════════════════════════════════════════════════════════════════
	# NUEVO: Guardar estado del EnemyManager (todos los enemigos activos)
	# ═══════════════════════════════════════════════════════════════════════════════
	if game_node and game_node.has_node("EnemyManager"):
		var enemy_mgr = game_node.get_node("EnemyManager")
		if enemy_mgr.has_method("to_save_data"):
			game_state["enemy_manager_state"] = enemy_mgr.to_save_data()
	
	# Guardar en SessionState
	SessionState.save_full_game_state(game_state)

func _disable_buttons_recursive(node: Node, disabled: bool) -> void:
	"""Deshabilitar/habilitar botones recursivamente"""
	if node is Button:
		node.disabled = disabled
		node.focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	for child in node.get_children():
		_disable_buttons_recursive(child, disabled)

func _play_button_sound() -> void:
	AudioManager.play_fixed("sfx_ui_click")
