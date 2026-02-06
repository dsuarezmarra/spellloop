# RankingScreen.gd
# Pantalla de ranking mensual con leaderboards de Steam
# Muestra los 100 mejores jugadores y permite ver sus builds

extends CanvasLayer

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal closed

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS UI
# ═══════════════════════════════════════════════════════════════════════════════

@onready var title_label: Label = $MainContainer/Header/TitleLabel
@onready var close_button: Button = $MainContainer/Header/CloseButton
@onready var tab_top100: Button = $MainContainer/TabContainer/TabTop100
@onready var tab_my_position: Button = $MainContainer/TabContainer/TabMyPosition
@onready var tab_friends: Button = $MainContainer/TabContainer/TabFriends
@onready var scroll_container: ScrollContainer = $MainContainer/ContentPanel/ScrollContainer
@onready var entries_container: VBoxContainer = $MainContainer/ContentPanel/ScrollContainer/EntriesContainer
@onready var loading_label: Label = $MainContainer/ContentPanel/LoadingLabel
@onready var offline_label: Label = $MainContainer/ContentPanel/OfflineLabel
@onready var refresh_button: Button = $MainContainer/Footer/RefreshButton
@onready var month_selector: OptionButton = $MainContainer/Footer/MonthSelector

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

enum Tab { TOP_100, MY_POSITION, FRIENDS }

var current_tab: Tab = Tab.TOP_100
var current_entries: Array = []
var is_loading: bool = false
var build_popup_scene: PackedScene = null

# Colores para posiciones
const GOLD_COLOR = Color(1.0, 0.85, 0.2)
const SILVER_COLOR = Color(0.75, 0.75, 0.8)
const BRONZE_COLOR = Color(0.8, 0.5, 0.2)
const NORMAL_COLOR = Color(0.9, 0.9, 0.95)

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_populate_month_selector()
	_update_title()
	
	# Cargar popup de build
	var popup_path = "res://scenes/ui/BuildPopup.tscn"
	if ResourceLoader.exists(popup_path):
		build_popup_scene = load(popup_path)
	
	# Cargar ranking inicial
	_request_leaderboard()

func _setup_ui() -> void:
	"""Configurar estilos de UI"""
	# Estilo del título
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", GOLD_COLOR)
	
	# Estilo de botones de tab
	for tab in [tab_top100, tab_my_position, tab_friends]:
		tab.add_theme_font_size_override("font_size", 16)
	
	# Marcar tab activo
	_update_tab_styles()
	
	# Ocultar labels de estado
	loading_label.visible = false
	offline_label.visible = false

func _connect_signals() -> void:
	"""Conectar señales de botones"""
	close_button.pressed.connect(_on_close_pressed)
	tab_top100.pressed.connect(_on_tab_top100_pressed)
	tab_my_position.pressed.connect(_on_tab_my_position_pressed)
	tab_friends.pressed.connect(_on_tab_friends_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	month_selector.item_selected.connect(_on_month_selected)
	
	# Conectar con SteamManager si está disponible
	var steam = _get_steam_manager()
	if steam:
		if not steam.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
			steam.leaderboard_loaded.connect(_on_leaderboard_loaded)

func _get_steam_manager() -> Node:
	"""Obtener referencia al SteamManager"""
	return get_tree().root.get_node_or_null("SteamManager")

# ═══════════════════════════════════════════════════════════════════════════════
# SELECTOR DE MES
# ═══════════════════════════════════════════════════════════════════════════════

func _populate_month_selector() -> void:
	"""Llenar selector con los últimos 6 meses"""
	month_selector.clear()
	
	var current_date = Time.get_datetime_dict_from_system()
	var year = current_date.year
	var month = current_date.month
	
	for i in range(6):  # Últimos 6 meses
		var month_name = LeaderboardService.get_month_name(month)
		var display_text = "%s %d" % [month_name, year]
		month_selector.add_item(display_text, i)
		month_selector.set_item_metadata(i, {"year": year, "month": month})
		
		# Retroceder un mes
		month -= 1
		if month <= 0:
			month = 12
			year -= 1
	
	month_selector.select(0)

func _get_selected_leaderboard_name() -> String:
	"""Obtener nombre del leaderboard seleccionado"""
	var idx = month_selector.selected
	if idx < 0:
		return ""
	
	var meta = month_selector.get_item_metadata(idx)
	if meta == null:
		return ""
	
	return "monthly_score_%04d_%02d" % [meta.year, meta.month]

# ═══════════════════════════════════════════════════════════════════════════════
# CARGA DE LEADERBOARD
# ═══════════════════════════════════════════════════════════════════════════════

func _request_leaderboard() -> void:
	"""Solicitar datos del leaderboard"""
	is_loading = true
	_update_loading_state()
	
	var steam = _get_steam_manager()
	if steam == null or not steam.is_steam_available:
		# Modo offline
		_show_offline_message()
		return
	
	var leaderboard_name = _get_selected_leaderboard_name()
	steam.request_top_entries(100, leaderboard_name)

func _on_leaderboard_loaded(leaderboard_name: String, entries: Array) -> void:
	"""Callback cuando se cargan los datos del leaderboard"""
	is_loading = false
	current_entries = entries
	_update_loading_state()
	_populate_entries()

func _show_offline_message() -> void:
	"""Mostrar mensaje de modo offline"""
	is_loading = false
	_update_loading_state()
	
	scroll_container.visible = false
	offline_label.visible = true

func _update_loading_state() -> void:
	"""Actualizar estado visual de carga"""
	loading_label.visible = is_loading
	scroll_container.visible = not is_loading and not offline_label.visible

# ═══════════════════════════════════════════════════════════════════════════════
# POBLACIÓN DE ENTRIES
# ═══════════════════════════════════════════════════════════════════════════════

func _populate_entries() -> void:
	"""Poblar la lista con las entries del leaderboard"""
	# Limpiar entries anteriores
	for child in entries_container.get_children():
		child.queue_free()
	
	if current_entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay entradas en el ranking de este mes"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		entries_container.add_child(empty_label)
		return
	
	# Crear entries
	for entry in current_entries:
		var entry_panel = _create_entry_panel(entry)
		entries_container.add_child(entry_panel)

func _create_entry_panel(entry: Dictionary) -> Control:
	"""Crear panel visual para una entry del ranking"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	
	# Estilo del panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	
	var rank = entry.get("rank", 0)
	if rank == 1:
		style.border_color = GOLD_COLOR
		style.set_border_width_all(2)
	elif rank == 2:
		style.border_color = SILVER_COLOR
		style.set_border_width_all(2)
	elif rank == 3:
		style.border_color = BRONZE_COLOR
		style.set_border_width_all(2)
	
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)
	
	# Posición
	var rank_label = Label.new()
	rank_label.custom_minimum_size = Vector2(60, 0)
	rank_label.text = "#%d" % rank
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 24)
	
	if rank == 1:
		rank_label.text = "🥇"
	elif rank == 2:
		rank_label.text = "🥈"
	elif rank == 3:
		rank_label.text = "🥉"
	
	var rank_color = GOLD_COLOR if rank == 1 else (SILVER_COLOR if rank == 2 else (BRONZE_COLOR if rank == 3 else NORMAL_COLOR))
	rank_label.add_theme_color_override("font_color", rank_color)
	hbox.add_child(rank_label)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = entry.get("steam_name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", NORMAL_COLOR)
	hbox.add_child(name_label)
	
	# Puntuación
	var score_label = Label.new()
	score_label.custom_minimum_size = Vector2(150, 0)
	var steam = _get_steam_manager()
	var formatted_score = str(entry.get("score", 0))
	if steam and steam.has_method("format_score"):
		formatted_score = steam.format_score(entry.get("score", 0))
	score_label.text = "%s pts" % formatted_score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	hbox.add_child(score_label)
	
	# Botón ver build
	var build_button = Button.new()
	build_button.text = "VER BUILD"
	build_button.custom_minimum_size = Vector2(120, 40)
	build_button.pressed.connect(_on_view_build_pressed.bind(entry))
	hbox.add_child(build_button)
	
	return panel

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD POPUP
# ═══════════════════════════════════════════════════════════════════════════════

func _on_view_build_pressed(entry: Dictionary) -> void:
	"""Abrir popup con la build del jugador"""
	if build_popup_scene == null:
		print("[RankingScreen] ⚠️ BuildPopup.tscn no encontrado")
		return
	
	var popup = build_popup_scene.instantiate()
	add_child(popup)
	
	var build_data = entry.get("build_data", {})
	if popup.has_method("show_build"):
		popup.show_build(entry.get("steam_name", "Unknown"), build_data)

# ═══════════════════════════════════════════════════════════════════════════════
# TABS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_tab_top100_pressed() -> void:
	current_tab = Tab.TOP_100
	_update_tab_styles()
	_request_leaderboard()

func _on_tab_my_position_pressed() -> void:
	current_tab = Tab.MY_POSITION
	_update_tab_styles()
	# TODO: Implementar búsqueda de posición propia
	_request_leaderboard()

func _on_tab_friends_pressed() -> void:
	current_tab = Tab.FRIENDS
	_update_tab_styles()
	# TODO: Implementar filtro de amigos
	_request_leaderboard()

func _update_tab_styles() -> void:
	"""Actualizar estilos de tabs según el seleccionado"""
	var tabs = [tab_top100, tab_my_position, tab_friends]
	var tab_values = [Tab.TOP_100, Tab.MY_POSITION, Tab.FRIENDS]
	
	for i in range(tabs.size()):
		var is_active = current_tab == tab_values[i]
		tabs[i].modulate = Color.WHITE if is_active else Color(0.6, 0.6, 0.7)

func _update_title() -> void:
	"""Actualizar título con el mes actual"""
	var date = Time.get_datetime_dict_from_system()
	var month_name = LeaderboardService.get_month_name(date.month).to_upper()
	title_label.text = "🏆 RANKING GLOBAL - %s %d" % [month_name, date.year]

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()

func _on_refresh_pressed() -> void:
	offline_label.visible = false
	_request_leaderboard()

func _on_month_selected(index: int) -> void:
	_update_title_for_selected_month()
	_request_leaderboard()

func _update_title_for_selected_month() -> void:
	"""Actualizar título según mes seleccionado"""
	var idx = month_selector.selected
	if idx >= 0:
		var meta = month_selector.get_item_metadata(idx)
		if meta:
			var month_name = LeaderboardService.get_month_name(meta.month).to_upper()
			title_label.text = "🏆 RANKING GLOBAL - %s %d" % [month_name, meta.year]

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
