# BuildPopup.gd
# Popup para mostrar la build de un jugador del ranking
# Muestra estadísticas, armas y objetos como el menú de pausa

extends CanvasLayer

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS UI
# ═══════════════════════════════════════════════════════════════════════════════

@onready var title_label: Label = $MainPanel/VBoxContainer/Header/TitleLabel
@onready var close_button: Button = $MainPanel/VBoxContainer/Header/CloseButton
@onready var player_name_label: Label = $MainPanel/VBoxContainer/PlayerName
@onready var tab_stats: Button = $MainPanel/VBoxContainer/TabContainer/TabStats
@onready var tab_weapons: Button = $MainPanel/VBoxContainer/TabContainer/TabWeapons
@onready var tab_items: Button = $MainPanel/VBoxContainer/TabContainer/TabItems
@onready var content_vbox: VBoxContainer = $MainPanel/VBoxContainer/ContentPanel/MarginContainer/ScrollContainer/ContentVBox

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

enum Tab { STATS, WEAPONS, ITEMS }

var current_tab: Tab = Tab.STATS
var build_data: Dictionary = {}
var player_name: String = ""

# Colores
const LABEL_COLOR = Color(0.7, 0.7, 0.8)
const VALUE_COLOR = Color(1.0, 0.9, 0.5)
const HEADER_COLOR = Color(0.9, 0.8, 0.4)

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_connect_signals()
	_update_tab_styles()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	tab_stats.pressed.connect(_on_tab_stats_pressed)
	tab_weapons.pressed.connect(_on_tab_weapons_pressed)
	tab_items.pressed.connect(_on_tab_items_pressed)

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func show_build(p_name: String, data: Dictionary) -> void:
	"""Mostrar la build de un jugador"""
	player_name = p_name
	build_data = data
	
	player_name_label.text = p_name
	player_name_label.add_theme_font_size_override("font_size", 22)
	player_name_label.add_theme_color_override("font_color", HEADER_COLOR)
	
	_populate_current_tab()

# ═══════════════════════════════════════════════════════════════════════════════
# CONTENIDO DE TABS
# ═══════════════════════════════════════════════════════════════════════════════

func _populate_current_tab() -> void:
	"""Poblar contenido según tab actual"""
	_clear_content()
	
	match current_tab:
		Tab.STATS:
			_populate_stats()
		Tab.WEAPONS:
			_populate_weapons()
		Tab.ITEMS:
			_populate_items()

func _clear_content() -> void:
	"""Limpiar contenido actual"""
	for child in content_vbox.get_children():
		child.queue_free()

func _populate_stats() -> void:
	"""Mostrar estadísticas de la partida"""
	var stats = build_data.get("stats", {})
	
	# Estadísticas principales
	_add_section_header("📊 ESTADÍSTICAS DE PARTIDA")
	_add_stat_row("Puntuación", str(stats.get("score", 0)))
	_add_stat_row("Tiempo", _format_time(stats.get("time_played", 0)))
	_add_stat_row("Nivel alcanzado", str(stats.get("level_reached", 0)))
	_add_stat_row("Enemigos derrotados", str(stats.get("kills", 0)))
	_add_stat_row("Oro recolectado", str(stats.get("gold", 0)))
	
	_add_spacer()
	
	# Estadísticas del personaje
	_add_section_header("⚔️ ESTADÍSTICAS DEL PERSONAJE")
	_add_stat_row("Clase", stats.get("character_class", "Desconocida"))
	_add_stat_row("HP máximo", str(stats.get("max_hp", 100)))
	_add_stat_row("Daño base", "%.1f" % stats.get("damage", 1.0))
	_add_stat_row("Velocidad", "%.0f%%" % (stats.get("speed", 1.0) * 100))
	_add_stat_row("Enfriamiento", "%.0f%%" % (stats.get("cooldown", 1.0) * 100))

func _populate_weapons() -> void:
	"""Mostrar armas del jugador"""
	var weapons = build_data.get("weapons", [])
	
	if weapons.is_empty():
		_add_empty_message("No hay información de armas")
		return
	
	_add_section_header("⚔️ ARMAS EQUIPADAS (%d)" % weapons.size())
	
	for weapon in weapons:
		_add_weapon_row(weapon)

func _populate_items() -> void:
	"""Mostrar objetos del jugador"""
	var items = build_data.get("items", [])
	
	if items.is_empty():
		_add_empty_message("No hay información de objetos")
		return
	
	_add_section_header("🎒 OBJETOS RECOLECTADOS (%d)" % items.size())
	
	for item in items:
		_add_item_row(item)

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS DE UI
# ═══════════════════════════════════════════════════════════════════════════════

func _add_section_header(text: String) -> void:
	"""Añadir cabecera de sección"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", HEADER_COLOR)
	content_vbox.add_child(label)

func _add_stat_row(label_text: String, value_text: String) -> void:
	"""Añadir fila de estadística"""
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", LABEL_COLOR)
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", VALUE_COLOR)
	value.add_theme_font_size_override("font_size", 16)
	hbox.add_child(value)
	
	content_vbox.add_child(hbox)

func _add_weapon_row(weapon: Dictionary) -> void:
	"""Añadir fila de arma"""
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Icono (placeholder si no está disponible)
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = weapon.get("icon", "")
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	
	hbox.add_child(icon_rect)
	
	# Nombre y nivel
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = weapon.get("name", "Arma desconocida")
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(name_label)
	
	var level_label = Label.new()
	level_label.text = "Nivel %d" % weapon.get("level", 1)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	level_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(level_label)
	
	hbox.add_child(info_vbox)
	
	content_vbox.add_child(panel)

func _add_item_row(item: Dictionary) -> void:
	"""Añadir fila de objeto"""
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.18, 0.15, 0.8)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Icono
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = item.get("icon", "")
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	
	hbox.add_child(icon_rect)
	
	# Nombre y cantidad
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = item.get("name", "Objeto desconocido")
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(name_label)
	
	var count = item.get("count", 1)
	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.5))
		count_label.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(count_label)
	
	hbox.add_child(info_vbox)
	
	content_vbox.add_child(panel)

func _add_empty_message(text: String) -> void:
	"""Añadir mensaje cuando no hay contenido"""
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	content_vbox.add_child(label)

func _add_spacer() -> void:
	"""Añadir espaciador"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	content_vbox.add_child(spacer)

func _format_time(seconds: float) -> String:
	"""Formatear tiempo en mm:ss"""
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# ═══════════════════════════════════════════════════════════════════════════════
# TABS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_tab_stats_pressed() -> void:
	current_tab = Tab.STATS
	_update_tab_styles()
	_populate_current_tab()

func _on_tab_weapons_pressed() -> void:
	current_tab = Tab.WEAPONS
	_update_tab_styles()
	_populate_current_tab()

func _on_tab_items_pressed() -> void:
	current_tab = Tab.ITEMS
	_update_tab_styles()
	_populate_current_tab()

func _update_tab_styles() -> void:
	"""Actualizar estilos de tabs"""
	var tabs = [tab_stats, tab_weapons, tab_items]
	var tab_values = [Tab.STATS, Tab.WEAPONS, Tab.ITEMS]
	
	for i in range(tabs.size()):
		var is_active = current_tab == tab_values[i]
		tabs[i].modulate = Color.WHITE if is_active else Color(0.6, 0.6, 0.7)

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_close_pressed() -> void:
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
