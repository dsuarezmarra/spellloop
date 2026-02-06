# RankingScreen.gd
# Pantalla de ranking mensual con leaderboards de Steam
# Navegación AISLADA: WASD + ESPACIO + ESC (no afecta al MainMenu)

extends CanvasLayer

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal closed

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const GOLD_COLOR = Color(1.0, 0.85, 0.2)
const SILVER_COLOR = Color(0.75, 0.75, 0.8)
const BRONZE_COLOR = Color(0.8, 0.5, 0.2)
const NORMAL_COLOR = Color(0.9, 0.9, 0.95)
const FOCUS_COLOR = Color(0.3, 0.6, 1.0)
const LOAD_TIMEOUT_SECONDS: float = 3.0

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS UI (se crean dinámicamente)
# ═══════════════════════════════════════════════════════════════════════════════

var background: ColorRect
var main_container: VBoxContainer
var title_label: Label
var tabs_container: HBoxContainer
var tab_buttons: Array[Button] = []
var content_panel: PanelContainer
var scroll_container: ScrollContainer
var entries_container: VBoxContainer
var loading_label: Label
var offline_label: Label
var footer_container: HBoxContainer
var month_button: Button
var refresh_button: Button
var back_button: Button

# Popup de selector de mes
var month_popup: PanelContainer
var month_popup_container: VBoxContainer
var month_items: Array[Button] = []
var month_popup_visible: bool = false
var month_popup_index: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

enum Tab { TOP_100, MY_POSITION, FRIENDS }
enum FocusArea { TABS, ENTRIES, FOOTER, MONTH_POPUP, DETAIL_VIEW }
enum DetailNavRow { TABS, CONTENT }
enum DetailTab { STATS, WEAPONS, ITEMS }

var current_tab: Tab = Tab.TOP_100
var current_entries: Array = []
var is_loading: bool = false

# Navegación principal
var focus_area: FocusArea = FocusArea.TABS
var tab_index: int = 0
var footer_index: int = 0  # 0=mes, 1=actualizar, 2=volver
var entry_index: int = 0   # Índice de entry seleccionada
var expanded_entry_index: int = -1  # -1 = ninguna expandida

# Paneles de entries (para actualizar visual)
var entry_panels: Array[Control] = []
var detail_panels: Array[Control] = []

# ═══ ESTADO DEL POPUP DE DETALLE (clon del menú pausa) ═══
var detail_popup: Control = null
var detail_popup_visible: bool = false
var detail_current_tab: DetailTab = DetailTab.STATS
var detail_nav_row: DetailNavRow = DetailNavRow.TABS
var detail_tab_buttons: Array[Button] = []
var detail_content_container: Control = null
var detail_content_scroll: ScrollContainer = null
var detail_current_entry: Dictionary = {}

# Colores (mismos que PauseMenu)
const DETAIL_SELECTED_TAB = Color(1.0, 0.85, 0.3)
const DETAIL_UNSELECTED_TAB = Color(0.5, 0.5, 0.6)
const DETAIL_PANEL_BG = Color(0.1, 0.1, 0.15, 0.98)
const DETAIL_VALUE_COLOR = Color(0.3, 0.9, 0.4)
const DETAIL_STAT_COLOR = Color(0.8, 0.8, 0.9)

# Colores por categoría (igual que PauseMenu)
const CATEGORY_COLORS = {
	"defensive": Color(0.2, 0.7, 0.3),
	"offensive": Color(1.0, 0.4, 0.2),
	"critical": Color(1.0, 0.85, 0.2),
	"utility": Color(0.4, 0.7, 1.0)
}

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
	"ice": "❄️", "fire": "🔥", "lightning": "⚡", "arcane": "💜",
	"shadow": "🗡️", "nature": "🌿", "wind": "🌪️", "earth": "🪨",
	"light": "✨", "void": "🕳️", "physical": "⚔️"
}

# Datos de meses
var month_data: Array = []  # Array de {year, month, display}
var selected_month_index: int = 0

# Timer
var load_timeout_timer: Timer = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Añadir al grupo para que otros scripts puedan detectar si está abierto
	add_to_group("ranking_screen")
	
	# Pausar el árbol de escenas para que el MainMenu no procese input
	# (Alternativa: usar process_mode)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_create_ui()
	_setup_timeout_timer()
	_populate_month_data()
	_update_month_button_text()
	_update_title()
	_update_visual_focus()
	
	# Conectar con SteamManager
	var steam = _get_steam_manager()
	if steam and steam.has_signal("leaderboard_loaded"):
		if not steam.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
			steam.leaderboard_loaded.connect(_on_leaderboard_loaded)
	
	# Cargar ranking inicial
	_request_leaderboard()

func _setup_timeout_timer() -> void:
	load_timeout_timer = Timer.new()
	load_timeout_timer.one_shot = true
	load_timeout_timer.timeout.connect(_on_load_timeout)
	add_child(load_timeout_timer)

func _get_steam_manager() -> Node:
	return get_tree().root.get_node_or_null("SteamManager")

# ═══════════════════════════════════════════════════════════════════════════════
# CREACIÓN DE UI DINÁMICA
# ═══════════════════════════════════════════════════════════════════════════════

func _create_ui() -> void:
	# Fondo oscuro
	background = ColorRect.new()
	background.color = Color(0.05, 0.05, 0.1, 0.98)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Contenedor principal
	main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.offset_left = 80
	main_container.offset_top = 50
	main_container.offset_right = -80
	main_container.offset_bottom = -50
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)
	
	_create_header()
	_create_tabs()
	_create_content()
	_create_footer()
	_create_month_popup()

func _create_header() -> void:
	title_label = Label.new()
	title_label.text = "RANKING GLOBAL"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Usar fuente del juego
	var font_title = load("res://assets/ui/fonts/CinzelDecorative-Bold.ttf")
	if font_title:
		title_label.add_theme_font_override("font", font_title)
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", GOLD_COLOR)
	main_container.add_child(title_label)

func _create_tabs() -> void:
	tabs_container = HBoxContainer.new()
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_container.add_theme_constant_override("separation", 20)
	main_container.add_child(tabs_container)
	
	var font_btn = load("res://assets/ui/fonts/CinzelDecorative-Bold.ttf")
	var tab_names = ["TOP 100", "MI POSICION", "AMIGOS"]
	for i in range(3):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(180, 50)
		btn.focus_mode = Control.FOCUS_NONE  # Navegación manual
		if font_btn:
			btn.add_theme_font_override("font", font_btn)
		btn.add_theme_font_size_override("font_size", 18)
		tabs_container.add_child(btn)
		tab_buttons.append(btn)
	
	_update_tab_styles()

func _create_content() -> void:
	content_panel = PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(15)
	content_panel.add_theme_stylebox_override("panel", style)
	main_container.add_child(content_panel)
	
	# Scroll container
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.add_child(scroll_container)
	
	entries_container = VBoxContainer.new()
	entries_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries_container.add_theme_constant_override("separation", 8)
	scroll_container.add_child(entries_container)
	
	# Loading label
	loading_label = Label.new()
	loading_label.text = "Cargando ranking..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_label.add_theme_font_size_override("font_size", 24)
	loading_label.visible = false
	content_panel.add_child(loading_label)
	
	# Offline label
	offline_label = Label.new()
	offline_label.text = "Sin conexion a Steam\n\nEl ranking estara disponible\ncuando Steam este conectado"
	offline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offline_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	offline_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	offline_label.add_theme_font_size_override("font_size", 20)
	offline_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	offline_label.visible = false
	content_panel.add_child(offline_label)

func _create_footer() -> void:
	footer_container = HBoxContainer.new()
	footer_container.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_container.add_theme_constant_override("separation", 30)
	main_container.add_child(footer_container)
	
	var font_btn = load("res://assets/ui/fonts/CinzelDecorative-Bold.ttf")
	
	# Botón selector de mes
	month_button = Button.new()
	month_button.text = "Febrero 2026"
	month_button.custom_minimum_size = Vector2(220, 55)
	month_button.focus_mode = Control.FOCUS_NONE
	if font_btn:
		month_button.add_theme_font_override("font", font_btn)
	month_button.add_theme_font_size_override("font_size", 18)
	footer_container.add_child(month_button)
	
	# Botón actualizar
	refresh_button = Button.new()
	refresh_button.text = "ACTUALIZAR"
	refresh_button.custom_minimum_size = Vector2(180, 55)
	refresh_button.focus_mode = Control.FOCUS_NONE
	if font_btn:
		refresh_button.add_theme_font_override("font", font_btn)
	refresh_button.add_theme_font_size_override("font_size", 18)
	footer_container.add_child(refresh_button)
	
	# Botón volver
	back_button = Button.new()
	back_button.text = "VOLVER"
	back_button.custom_minimum_size = Vector2(180, 55)
	back_button.focus_mode = Control.FOCUS_NONE
	if font_btn:
		back_button.add_theme_font_override("font", font_btn)
	back_button.add_theme_font_size_override("font_size", 18)
	footer_container.add_child(back_button)

func _create_month_popup() -> void:
	"""Crear popup de selección de mes (inicialmente oculto)"""
	month_popup = PanelContainer.new()
	month_popup.visible = false
	month_popup.z_index = 100
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	style.set_corner_radius_all(8)
	style.border_color = FOCUS_COLOR
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	month_popup.add_theme_stylebox_override("panel", style)
	add_child(month_popup)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(220, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	month_popup.add_child(scroll)
	
	month_popup_container = VBoxContainer.new()
	month_popup_container.add_theme_constant_override("separation", 5)
	scroll.add_child(month_popup_container)

# ═══════════════════════════════════════════════════════════════════════════════
# SELECTOR DE MES
# ═══════════════════════════════════════════════════════════════════════════════

func _populate_month_data() -> void:
	"""Generar datos de los últimos 12 meses"""
	month_data.clear()
	
	var current_date = Time.get_datetime_dict_from_system()
	var year = current_date.year
	var month = current_date.month
	
	for i in range(12):
		var month_name = _get_month_name(month)
		month_data.append({
			"year": year,
			"month": month,
			"display": "%s %d" % [month_name, year]
		})
		
		month -= 1
		if month <= 0:
			month = 12
			year -= 1

func _get_month_name(month_num: int) -> String:
	var months = ["", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
				  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
	if month_num >= 1 and month_num <= 12:
		return months[month_num]
	return "Mes"

func _update_month_button_text() -> void:
	if selected_month_index < month_data.size():
		month_button.text = month_data[selected_month_index].display

func _show_month_popup() -> void:
	"""Mostrar popup de selección de mes"""
	month_popup_visible = true
	month_popup_index = selected_month_index
	
	# Limpiar items anteriores
	for child in month_popup_container.get_children():
		child.queue_free()
	month_items.clear()
	
	var font_btn = load("res://assets/ui/fonts/CinzelDecorative-Bold.ttf")
	
	# Crear items de mes
	for i in range(month_data.size()):
		var btn = Button.new()
		btn.text = month_data[i].display
		btn.custom_minimum_size = Vector2(200, 40)
		btn.focus_mode = Control.FOCUS_NONE
		if font_btn:
			btn.add_theme_font_override("font", font_btn)
		btn.add_theme_font_size_override("font_size", 16)
		month_popup_container.add_child(btn)
		month_items.append(btn)
	
	# Posicionar popup encima del botón de mes
	await get_tree().process_frame
	var btn_rect = month_button.get_global_rect()
	month_popup.position = Vector2(btn_rect.position.x, btn_rect.position.y - 320)
	month_popup.visible = true
	
	_update_month_popup_visual()

func _hide_month_popup() -> void:
	month_popup_visible = false
	month_popup.visible = false

func _update_month_popup_visual() -> void:
	"""Actualizar visual de items del popup"""
	for i in range(month_items.size()):
		var btn = month_items[i]
		if i == month_popup_index:
			btn.modulate = Color(1.2, 1.2, 1.5)
			# Hacer scroll al item
			var scroll = month_popup.get_child(0) as ScrollContainer
			if scroll:
				scroll.scroll_vertical = max(0, i * 45 - 130)
		else:
			btn.modulate = Color.WHITE

func _select_month_from_popup() -> void:
	"""Confirmar selección de mes"""
	selected_month_index = month_popup_index
	_update_month_button_text()
	_hide_month_popup()
	_update_title()
	_request_leaderboard()

# ═══════════════════════════════════════════════════════════════════════════════
# NAVEGACIÓN VISUAL
# ═══════════════════════════════════════════════════════════════════════════════

func _update_visual_focus() -> void:
	"""Actualizar indicadores visuales de foco"""
	# Reset todos los botones
	for btn in tab_buttons:
		btn.modulate = Color.WHITE
	month_button.modulate = Color.WHITE
	refresh_button.modulate = Color.WHITE
	back_button.modulate = Color.WHITE
	
	# Reset visual de entries
	_update_entries_visual()
	
	# Aplicar estilo de foco según área
	match focus_area:
		FocusArea.TABS:
			if tab_index < tab_buttons.size():
				tab_buttons[tab_index].modulate = Color(1.2, 1.2, 1.5)
		FocusArea.ENTRIES:
			_highlight_entry(entry_index)
		FocusArea.FOOTER:
			match footer_index:
				0: month_button.modulate = Color(1.2, 1.2, 1.5)
				1: refresh_button.modulate = Color(1.2, 1.2, 1.5)
				2: back_button.modulate = Color(1.2, 1.2, 1.5)
	
	# Actualizar estilos de tabs (activo vs inactivo)
	_update_tab_styles()

func _update_entries_visual() -> void:
	"""Resetear visual de todas las entries"""
	for i in range(entry_panels.size()):
		var panel = entry_panels[i]
		if panel and is_instance_valid(panel):
			panel.modulate = Color.WHITE

func _highlight_entry(index: int) -> void:
	"""Destacar la entry seleccionada"""
	if index >= 0 and index < entry_panels.size():
		var panel = entry_panels[index]
		if panel and is_instance_valid(panel):
			panel.modulate = Color(1.1, 1.1, 1.3)

func _update_tab_styles() -> void:
	var tab_values = [Tab.TOP_100, Tab.MY_POSITION, Tab.FRIENDS]
	for i in range(tab_buttons.size()):
		var is_active = current_tab == tab_values[i]
		var is_focused = focus_area == FocusArea.TABS and tab_index == i
		
		if is_focused:
			tab_buttons[i].modulate = Color(1.2, 1.2, 1.5)
		elif is_active:
			tab_buttons[i].modulate = Color(1.0, 1.0, 1.0)
		else:
			tab_buttons[i].modulate = Color(0.6, 0.6, 0.7)

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT - CAPTURA TODO para aislar del MainMenu
# ═══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	# IMPORTANTE: Consumir TODOS los eventos de navegación para que no lleguen al MainMenu
	var consumed = false
	
	# Si el popup de detalle está abierto, manejar su input
	if detail_popup_visible:
		consumed = _handle_detail_popup_input(event)
	# Si el popup de mes está abierto
	elif month_popup_visible:
		consumed = _handle_month_popup_input(event)
	else:
		consumed = _handle_main_input(event)
	
	# Consumir el evento para aislarlo del MainMenu
	if consumed:
		get_viewport().set_input_as_handled()

func _handle_main_input(event: InputEvent) -> bool:
	"""Manejar input en el menú principal"""
	
	# ESC - Cerrar
	if event.is_action_pressed("ui_cancel"):
		_close()
		return true
	
	# W - Arriba (cambiar de área)
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_navigate_up()
		return true
	
	# S - Abajo (cambiar de área)
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_navigate_down()
		return true
	
	# A - Izquierda
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_navigate_left()
		return true
	
	# D - Derecha
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_navigate_right()
		return true
	
	# ESPACIO o ENTER - Seleccionar
	if event.is_action_pressed("ui_accept") or _is_space_pressed(event):
		_activate_current()
		return true
	
	# Consumir también eventos de teclado relevantes para evitar propagación
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		if key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_ENTER, KEY_ESCAPE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			return true
	
	return false

func _handle_month_popup_input(event: InputEvent) -> bool:
	"""Manejar input cuando el popup de mes está abierto"""
	
	# ESC - Cerrar popup
	if event.is_action_pressed("ui_cancel"):
		_hide_month_popup()
		return true
	
	# W - Arriba en lista
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		month_popup_index = maxi(0, month_popup_index - 1)
		_update_month_popup_visual()
		_play_hover_sound()
		return true
	
	# S - Abajo en lista
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		month_popup_index = mini(month_data.size() - 1, month_popup_index + 1)
		_update_month_popup_visual()
		_play_hover_sound()
		return true
	
	# ESPACIO o ENTER - Seleccionar mes
	if event.is_action_pressed("ui_accept") or _is_space_pressed(event):
		_select_month_from_popup()
		_play_click_sound()
		return true
	
	# Consumir eventos de teclado
	if event is InputEventKey and event.pressed:
		return true
	
	return false

func _is_space_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and event.keycode == KEY_SPACE

func _navigate_up() -> void:
	"""Navegar hacia arriba entre áreas o dentro de entries"""
	match focus_area:
		FocusArea.FOOTER:
			# De footer a entries (si hay) o a tabs
			if current_entries.size() > 0:
				focus_area = FocusArea.ENTRIES
				entry_index = current_entries.size() - 1  # Última entry
			else:
				focus_area = FocusArea.TABS
		FocusArea.ENTRIES:
			if entry_index > 0:
				entry_index -= 1
				_scroll_to_entry(entry_index)
			else:
				focus_area = FocusArea.TABS
		FocusArea.TABS:
			pass  # Ya está arriba
	_update_visual_focus()
	_play_hover_sound()

func _navigate_down() -> void:
	"""Navegar hacia abajo entre áreas o dentro de entries"""
	match focus_area:
		FocusArea.TABS:
			# De tabs a entries (si hay) o a footer
			if current_entries.size() > 0:
				focus_area = FocusArea.ENTRIES
				entry_index = 0
			else:
				focus_area = FocusArea.FOOTER
		FocusArea.ENTRIES:
			if entry_index < current_entries.size() - 1:
				entry_index += 1
				_scroll_to_entry(entry_index)
			else:
				focus_area = FocusArea.FOOTER
		FocusArea.FOOTER:
			pass  # Ya está abajo
	_update_visual_focus()
	_play_hover_sound()

func _scroll_to_entry(index: int) -> void:
	"""Hacer scroll para que la entry sea visible"""
	if index < entry_panels.size() and scroll_container:
		var panel = entry_panels[index]
		if panel:
			var panel_pos = panel.position.y
			var panel_height = panel.size.y
			var scroll_pos = scroll_container.scroll_vertical
			var visible_height = scroll_container.size.y
			
			# Si está arriba del viewport
			if panel_pos < scroll_pos:
				scroll_container.scroll_vertical = int(panel_pos)
			# Si está abajo del viewport
			elif panel_pos + panel_height > scroll_pos + visible_height:
				scroll_container.scroll_vertical = int(panel_pos + panel_height - visible_height + 20)

func _navigate_left() -> void:
	"""Navegar hacia la izquierda dentro del área actual"""
	match focus_area:
		FocusArea.TABS:
			tab_index = maxi(0, tab_index - 1)
		FocusArea.FOOTER:
			footer_index = maxi(0, footer_index - 1)
		FocusArea.ENTRIES:
			pass  # No hay navegación horizontal en entries
	_update_visual_focus()
	_play_hover_sound()

func _navigate_right() -> void:
	"""Navegar hacia la derecha dentro del área actual"""
	match focus_area:
		FocusArea.TABS:
			tab_index = mini(2, tab_index + 1)
		FocusArea.FOOTER:
			footer_index = mini(2, footer_index + 1)
		FocusArea.ENTRIES:
			pass  # No hay navegación horizontal en entries
	_update_visual_focus()
	_play_hover_sound()

func _activate_current() -> void:
	"""Activar el elemento con foco actual"""
	_play_click_sound()
	
	match focus_area:
		FocusArea.TABS:
			_select_tab(tab_index)
		FocusArea.ENTRIES:
			_toggle_entry_details(entry_index)
		FocusArea.FOOTER:
			match footer_index:
				0: _show_month_popup()
				1: _refresh()
				2: _close()

func _select_tab(index: int) -> void:
	"""Seleccionar un tab"""
	var tabs = [Tab.TOP_100, Tab.MY_POSITION, Tab.FRIENDS]
	if index < tabs.size():
		current_tab = tabs[index]
		_update_tab_styles()
		_request_leaderboard()

func _refresh() -> void:
	offline_label.visible = false
	_request_leaderboard()

func _close() -> void:
	closed.emit()
	queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# AUDIO
# ═══════════════════════════════════════════════════════════════════════════════

func _play_hover_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		if audio.has_method("play_fixed"):
			audio.play_fixed("sfx_ui_hover")

func _play_click_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		if audio.has_method("play_fixed"):
			audio.play_fixed("sfx_ui_click")

# ═══════════════════════════════════════════════════════════════════════════════
# TÍTULO
# ═══════════════════════════════════════════════════════════════════════════════

func _update_title() -> void:
	if selected_month_index < month_data.size():
		var data = month_data[selected_month_index]
		var month_name = _get_month_name(data.month).to_upper()
		title_label.text = "RANKING GLOBAL - %s %d" % [month_name, data.year]

# ═══════════════════════════════════════════════════════════════════════════════
# CARGA DE LEADERBOARD
# ═══════════════════════════════════════════════════════════════════════════════

func _get_selected_leaderboard_name() -> String:
	if selected_month_index >= month_data.size():
		return ""
	var data = month_data[selected_month_index]
	return "monthly_score_%04d_%02d" % [data.year, data.month]

func _request_leaderboard() -> void:
	is_loading = true
	offline_label.visible = false
	_update_loading_state()
	
	load_timeout_timer.start(LOAD_TIMEOUT_SECONDS)
	
	var steam = _get_steam_manager()
	if steam == null or not steam.get("is_steam_available"):
		_show_offline_message()
		return
	
	var leaderboard_name = _get_selected_leaderboard_name()
	if steam.has_method("request_top_entries"):
		steam.request_top_entries(100, leaderboard_name)
	else:
		_show_offline_message()

func _on_load_timeout() -> void:
	if is_loading:
		_show_offline_message()

func _on_leaderboard_loaded(leaderboard_name: String, entries: Array) -> void:
	load_timeout_timer.stop()
	is_loading = false
	current_entries = entries
	_update_loading_state()
	_populate_entries()

func _show_offline_message() -> void:
	load_timeout_timer.stop()
	is_loading = false
	loading_label.visible = false
	offline_label.visible = false
	scroll_container.visible = true
	
	# Cargar datos del historial local
	current_entries = _load_local_run_history()
	_populate_entries()

func _load_local_run_history() -> Array:
	"""Cargar historial de partidas desde el archivo local, filtrado por mes"""
	const RUN_HISTORY_FILE = "user://saves/run_history.json"
	
	if not FileAccess.file_exists(RUN_HISTORY_FILE):
		return []
	
	var file = FileAccess.open(RUN_HISTORY_FILE, FileAccess.READ)
	if file == null:
		return []
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK or not (json.data is Array):
		return []
	
	var history: Array = json.data
	
	# Obtener mes seleccionado
	var target_year: int = 0
	var target_month: int = 0
	if selected_month_index < month_data.size():
		target_year = month_data[selected_month_index].year
		target_month = month_data[selected_month_index].month
	else:
		# Mes actual por defecto
		var now = Time.get_datetime_dict_from_system()
		target_year = now.year
		target_month = now.month
	
	# Filtrar partidas del mes seleccionado
	var filtered_runs: Array = []
	var now = Time.get_datetime_dict_from_system()
	var is_current_month = (target_year == now.year and target_month == now.month)
	
	for run in history:
		var timestamp = run.get("timestamp", 0)
		var run_year: int = 0
		var run_month: int = 0
		
		if timestamp > 0:
			var run_date = Time.get_datetime_dict_from_unix_time(int(timestamp))
			run_year = run_date.year
			run_month = run_date.month
		else:
			# Si no hay timestamp, usar end_time o start_time
			var end_time = run.get("end_time", run.get("start_time", 0))
			if end_time > 0:
				var run_date = Time.get_datetime_dict_from_unix_time(int(end_time))
				run_year = run_date.year
				run_month = run_date.month
			elif is_current_month:
				# Partidas sin fecha van al mes actual
				run_year = target_year
				run_month = target_month
		
		if run_year == target_year and run_month == target_month:
			filtered_runs.append(run)
	
	# Ordenar por puntuación (mayor primero)
	filtered_runs.sort_custom(_compare_runs_by_score)
	
	# Convertir al formato esperado por el ranking
	var entries: Array = []
	for i in range(filtered_runs.size()):
		var run = filtered_runs[i]
		var entry = _convert_run_to_entry(run, i + 1)  # Rank basado en posición ordenada
		entries.append(entry)
	
	return entries

func _compare_runs_by_score(a: Dictionary, b: Dictionary) -> bool:
	"""Comparador para ordenar runs por score (mayor primero)"""
	var score_a = _calculate_run_score(a)
	var score_b = _calculate_run_score(b)
	return score_a > score_b

func _calculate_run_score(run: Dictionary) -> int:
	"""Calcular puntuación de una partida"""
	# Si ya tiene score calculado, usarlo
	var score = run.get("score", 0)
	if score > 0:
		return score
	
	# Calcular score basado en datos disponibles (formatos antiguo y nuevo)
	var enemies = run.get("enemies_defeated", 0)
	var final_stats = run.get("final_stats", {})
	var level = final_stats.get("level", run.get("player_level", run.get("level_reached", 1)))
	var duration = run.get("duration", run.get("time_survived", 0.0))
	var phase = run.get("phase", 1)
	
	# Sistema de puntuación:
	# - Enemigos derrotados: 10 pts cada uno
	# - Nivel alcanzado: 100 pts por nivel
	# - Tiempo sobrevivido: 1 pt por segundo
	# - Fase alcanzada: 500 pts por fase
	score = (enemies * 10) + (level * 100) + int(duration) + (phase * 500)
	
	return score

func _convert_run_to_entry(run: Dictionary, rank: int) -> Dictionary:
	"""Convertir datos de una partida al formato de entrada del ranking"""
	# Soportar formato antiguo y nuevo
	
	# Obtener nombre del personaje legible
	var character_id = run.get("character_id", "unknown")
	var character_name = _get_character_display_name(character_id)
	
	# Calcular tiempo formateado (soportar ambos formatos)
	var duration = run.get("duration", run.get("time_survived", 0.0))
	var game_minutes = run.get("game_time_minutes", 0.0)
	var game_seconds = run.get("game_time_seconds", 0.0)
	var time_str = ""
	if game_minutes > 0 or game_seconds > 0:
		time_str = "%02d:%02d" % [int(game_minutes), int(game_seconds) % 60]
	elif duration > 0:
		time_str = "%02d:%02d" % [int(duration) / 60, int(duration) % 60]
	else:
		time_str = "00:00"
	
	# Obtener stats finales completos (formato nuevo o calcular desde formato antiguo)
	var final_stats = run.get("final_stats", {})
	var level = 1
	if final_stats.has("level"):
		level = final_stats.get("level", 1)
	elif run.has("player_level"):
		level = run.get("player_level", 1)
	elif run.has("level_reached"):
		level = run.get("level_reached", 1)
	
	# Stats básicos para display en la lista
	var stats_dict = {
		"hp": int(final_stats.get("max_health", 100)),
		"damage": final_stats.get("damage_mult", 1.0),
		"speed": final_stats.get("move_speed", 100),
		"crit": int(final_stats.get("crit_chance", 0.05) * 100),
		"armor": int(final_stats.get("armor", 0))
	}
	
	# Obtener armas (nombres en español si disponible)
	var weapons_raw = run.get("weapons", [])
	var weapons: Array = []
	var weapons_data: Array = []  # Datos completos de armas
	for w in weapons_raw:
		if w is Dictionary:
			weapons.append(w.get("name_es", w.get("name", "Unknown")))
			weapons_data.append({
				"element": w.get("element", w.get("element_type", "physical")),
				"level": w.get("level", 1),
				"damage": w.get("damage", 0),
				"rarity": w.get("rarity", "common")
			})
		elif w is String:
			weapons.append(w)
			weapons_data.append({})
	
	# Obtener mejoras/objetos con datos completos
	var upgrades_raw = run.get("upgrades", [])
	var items: Array = []
	var items_data: Array = []
	for u in upgrades_raw:
		if u is Dictionary:
			items.append(u.get("name", "Unknown"))
			items_data.append({
				"icon": u.get("icon", "✨"),
				"tier": u.get("tier", u.get("rarity", 1)),
				"description": u.get("description", ""),
				"category": u.get("category", "")
			})
		elif u is String:
			items.append(u)
			items_data.append({"icon": "✨"})
	
	# Calcular score usando la función centralizada
	var score = _calculate_run_score(run)
	
	return {
		"rank": rank,
		"steam_name": "Tu Partida",  # Sin Steam, usar texto genérico
		"score": score,
		"character": character_name,
		"level": final_stats.get("level", run.get("player_level", 1)),
		"time": time_str,
		"wave": run.get("phase", 1),  # Usamos phase como "oleada" visual
		"stats": stats_dict,
		"final_stats": final_stats,  # Stats completos para el popup de detalle
		"weapons": weapons,
		"weapons_data": weapons_data,  # Datos completos de armas
		"items": items,
		"items_data": items_data,  # Datos completos de items
		"timestamp": run.get("timestamp", 0),
		"end_reason": run.get("end_reason", "unknown")
	}

func _get_character_display_name(character_id: String) -> String:
	"""Obtener nombre legible del personaje desde su ID"""
	var names = {
		"frost_mage": "Mago de Hielo",
		"fire_mage": "Piromante",
		"pyromancer": "Piromante",
		"shadow_blade": "Sombra",
		"arcanist": "Arcanista",
		"void_walker": "Caminante del Vacío",
		"storm_caller": "Invocador de Tormentas",
		"geomancer": "Geomante",
		"paladin": "Paladín",
		"druid": "Druida",
		"wind_runner": "Corredor del Viento"
	}
	return names.get(character_id, character_id.capitalize().replace("_", " "))

func _update_loading_state() -> void:
	loading_label.visible = is_loading
	if is_loading:
		scroll_container.visible = false
		offline_label.visible = false
	else:
		scroll_container.visible = not offline_label.visible

# ═══════════════════════════════════════════════════════════════════════════════
# ENTRIES
# ═══════════════════════════════════════════════════════════════════════════════

func _populate_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()
	
	# Limpiar arrays
	entry_panels.clear()
	detail_panels.clear()
	expanded_entry_index = -1
	entry_index = 0
	
	if current_entries.is_empty():
		var empty_container = VBoxContainer.new()
		empty_container.add_theme_constant_override("separation", 15)
		entries_container.add_child(empty_container)
		
		var empty_label = Label.new()
		empty_label.text = "No hay partidas registradas"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		empty_container.add_child(empty_label)
		
		var hint_label = Label.new()
		hint_label.text = "¡Juega para registrar tus mejores partidas aquí!"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.add_theme_font_size_override("font_size", 16)
		hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		empty_container.add_child(hint_label)
		return
	
	for i in range(current_entries.size()):
		var entry = current_entries[i]
		
		# Contenedor para entry + detalles
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 0)
		entries_container.add_child(container)
		
		# Panel de la entry
		var entry_panel = _create_entry_panel(entry, i)
		container.add_child(entry_panel)
		entry_panels.append(entry_panel)
		
		# Panel de detalles (inicialmente oculto)
		var detail_panel = _create_detail_panel(entry)
		detail_panel.visible = false
		container.add_child(detail_panel)
		detail_panels.append(detail_panel)

func _toggle_entry_details(index: int) -> void:
	"""Abrir popup de detalle con 3 pestañas (clon del menú pausa)"""
	if index < 0 or index >= current_entries.size():
		return
	
	# Mostrar el popup de detalle completo
	_show_detail_popup(current_entries[index])

func _create_entry_panel(entry: Dictionary, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
	style.set_corner_radius_all(6)
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
	
	var font_entry = load("res://assets/ui/fonts/Quicksand-Variable.ttf")
	var font_bold = load("res://assets/ui/fonts/CinzelDecorative-Bold.ttf")
	
	# Posición
	var rank_label = Label.new()
	rank_label.custom_minimum_size = Vector2(50, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		rank_label.add_theme_font_override("font", font_bold)
	rank_label.add_theme_font_size_override("font_size", 20)
	
	if rank == 1:
		rank_label.text = "#1"
		rank_label.add_theme_color_override("font_color", GOLD_COLOR)
	elif rank == 2:
		rank_label.text = "#2"
		rank_label.add_theme_color_override("font_color", SILVER_COLOR)
	elif rank == 3:
		rank_label.text = "#3"
		rank_label.add_theme_color_override("font_color", BRONZE_COLOR)
	else:
		rank_label.text = "#%d" % rank
		rank_label.add_theme_color_override("font_color", NORMAL_COLOR)
	
	hbox.add_child(rank_label)
	
	# Nombre + Personaje
	var name_container = VBoxContainer.new()
	name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_container)
	
	var name_label = Label.new()
	name_label.text = entry.get("steam_name", "Unknown")
	if font_entry:
		name_label.add_theme_font_override("font", font_entry)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", NORMAL_COLOR)
	name_container.add_child(name_label)
	
	var char_label = Label.new()
	char_label.text = entry.get("character", "Unknown") + " - Nivel " + str(entry.get("level", 1))
	if font_entry:
		char_label.add_theme_font_override("font", font_entry)
	char_label.add_theme_font_size_override("font_size", 12)
	char_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	name_container.add_child(char_label)
	
	# Indicador de expandible
	var expand_label = Label.new()
	expand_label.text = "[ESPACIO]"
	if font_entry:
		expand_label.add_theme_font_override("font", font_entry)
	expand_label.add_theme_font_size_override("font_size", 12)
	expand_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hbox.add_child(expand_label)
	
	# Puntuación
	var score_label = Label.new()
	score_label.custom_minimum_size = Vector2(130, 0)
	score_label.text = "%d PTS" % entry.get("score", 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if font_bold:
		score_label.add_theme_font_override("font", font_bold)
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	hbox.add_child(score_label)
	
	return panel

func _create_detail_panel(entry: Dictionary) -> Control:
	"""Crear panel de detalles de la build"""
	var panel = PanelContainer.new()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.set_corner_radius_all(0)
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(15)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	panel.add_child(main_vbox)
	
	var font_entry = load("res://assets/ui/fonts/Quicksand-Variable.ttf")
	var font_bold = load("res://assets/ui/fonts/CinzelDecorative-Bold.ttf")
	
	# ═══════════════════════════════════════════════════════════════════════
	# FILA 1: Info de run
	# ═══════════════════════════════════════════════════════════════════════
	var run_info = HBoxContainer.new()
	run_info.add_theme_constant_override("separation", 40)
	main_vbox.add_child(run_info)
	
	_add_info_item(run_info, "OLEADA", str(entry.get("wave", 0)), font_bold, font_entry)
	_add_info_item(run_info, "TIEMPO", entry.get("time", "00:00"), font_bold, font_entry)
	_add_info_item(run_info, "NIVEL", str(entry.get("level", 1)), font_bold, font_entry)
	
	# ═══════════════════════════════════════════════════════════════════════
	# FILA 2: Stats
	# ═══════════════════════════════════════════════════════════════════════
	var stats_title = Label.new()
	stats_title.text = "ESTADISTICAS"
	if font_bold:
		stats_title.add_theme_font_override("font", font_bold)
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", GOLD_COLOR)
	main_vbox.add_child(stats_title)
	
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 30)
	main_vbox.add_child(stats_row)
	
	var stats = entry.get("stats", {})
	_add_stat_item(stats_row, "HP", str(stats.get("hp", 0)), Color(0.3, 0.9, 0.3), font_entry)
	
	# Daño: mostrar como multiplicador (x1.0) o porcentaje bonus (+50%)
	var damage_val = stats.get("damage", 1.0)
	var damage_str = ""
	if damage_val is float:
		if damage_val >= 1.0:
			damage_str = "x%.1f" % damage_val
		else:
			damage_str = "x%.2f" % damage_val
	else:
		damage_str = str(damage_val)
	_add_stat_item(stats_row, "DAÑO", damage_str, Color(0.9, 0.3, 0.3), font_entry)
	
	# Velocidad: valor absoluto (px/s)
	var speed_val = stats.get("speed", 100)
	_add_stat_item(stats_row, "VEL", str(int(speed_val)), Color(0.3, 0.7, 0.9), font_entry)
	
	_add_stat_item(stats_row, "CRIT", "%d%%" % stats.get("crit", 0), Color(0.9, 0.6, 0.2), font_entry)
	_add_stat_item(stats_row, "ARM", str(stats.get("armor", 0)), Color(0.6, 0.6, 0.8), font_entry)
	
	# ═══════════════════════════════════════════════════════════════════════
	# FILA 3: Armas (solo si hay)
	# ═══════════════════════════════════════════════════════════════════════
	var weapons = entry.get("weapons", [])
	if weapons.size() > 0:
		var weapons_title = Label.new()
		weapons_title.text = "ARMAS"
		if font_bold:
			weapons_title.add_theme_font_override("font", font_bold)
		weapons_title.add_theme_font_size_override("font_size", 16)
		weapons_title.add_theme_color_override("font_color", Color(0.8, 0.5, 0.9))
		main_vbox.add_child(weapons_title)
		
		var weapons_row = HBoxContainer.new()
		weapons_row.add_theme_constant_override("separation", 15)
		main_vbox.add_child(weapons_row)
		
		for weapon_name in weapons:
			var weapon_box = _create_item_box(weapon_name, Color(0.6, 0.3, 0.8), font_entry)
			weapons_row.add_child(weapon_box)
	
	# ═══════════════════════════════════════════════════════════════════════
	# FILA 4: Objetos/Mejoras (solo si hay)
	# ═══════════════════════════════════════════════════════════════════════
	var items = entry.get("items", [])
	if items.size() > 0:
		var items_title = Label.new()
		items_title.text = "MEJORAS"
		if font_bold:
			items_title.add_theme_font_override("font", font_bold)
		items_title.add_theme_font_size_override("font_size", 16)
		items_title.add_theme_color_override("font_color", Color(0.3, 0.8, 0.6))
		main_vbox.add_child(items_title)
		
		var items_row = HBoxContainer.new()
		items_row.add_theme_constant_override("separation", 10)
		main_vbox.add_child(items_row)
		
		for item_name in items:
			var item_box = _create_item_box(item_name, Color(0.2, 0.5, 0.4), font_entry)
			items_row.add_child(item_box)
	
	return panel

func _add_info_item(parent: Control, label_text: String, value_text: String, font_bold: Font, font_entry: Font) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	parent.add_child(container)
	
	var label = Label.new()
	label.text = label_text
	if font_bold:
		label.add_theme_font_override("font", font_bold)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	container.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	if font_entry:
		value.add_theme_font_override("font", font_entry)
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(value)

func _add_stat_item(parent: Control, label_text: String, value_text: String, color: Color, font: Font) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	parent.add_child(container)
	
	var label = Label.new()
	label.text = label_text
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	container.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	if font:
		value.add_theme_font_override("font", font)
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", color)
	container.add_child(value)

func _create_item_box(item_name: String, bg_color: Color, font: Font) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 35)
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.5)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	style.border_color = bg_color
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = item_name
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	
	return panel

# ═══════════════════════════════════════════════════════════════════════════════
# POPUP DE DETALLE (CLON DEL MENÚ DE PAUSA)
# ═══════════════════════════════════════════════════════════════════════════════

func _show_detail_popup(entry: Dictionary) -> void:
	"""Mostrar popup de detalle con 3 pestañas igual que el menú de pausa"""
	detail_current_entry = entry
	detail_popup_visible = true
	detail_current_tab = DetailTab.STATS
	detail_nav_row = DetailNavRow.TABS
	focus_area = FocusArea.DETAIL_VIEW
	
	# Cerrar popup anterior si existe
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
	
	# Crear popup
	detail_popup = Control.new()
	detail_popup.name = "DetailPopup"
	detail_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_popup.z_index = 200
	add_child(detail_popup)
	
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	detail_popup.add_child(bg)
	
	# Centro
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_popup.add_child(center)
	
	# Panel principal
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(900, 600)
	var style = StyleBoxFlat.new()
	style.bg_color = DETAIL_PANEL_BG
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
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = entry.get("steam_name", "Partida") + " - " + entry.get("character", "")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DETAIL_SELECTED_TAB)
	header.add_child(title)
	
	var score_label = Label.new()
	score_label.text = "%d PTS" % entry.get("score", 0)
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	header.add_child(score_label)
	
	# === TABS ===
	var tabs_container = HBoxContainer.new()
	tabs_container.add_theme_constant_override("separation", 10)
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(tabs_container)
	
	detail_tab_buttons.clear()
	var tab_names = ["ESTADÍSTICAS", "ARMAS", "OBJETOS"]
	for i in range(3):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(150, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.focus_mode = Control.FOCUS_NONE
		tabs_container.add_child(btn)
		detail_tab_buttons.append(btn)
	
	# Separador
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# === CONTENIDO ===
	detail_content_container = Control.new()
	detail_content_container.custom_minimum_size = Vector2(860, 400)
	detail_content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(detail_content_container)
	
	# === FOOTER ===
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var help = Label.new()
	help.text = "W/S: Scroll | A/D: Cambiar pestaña | ESC/ESPACIO: Cerrar"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(help)
	
	# Mostrar pestaña inicial
	_update_detail_tabs_visual()
	_show_detail_tab_content()

func _close_detail_popup() -> void:
	"""Cerrar el popup de detalle"""
	detail_popup_visible = false
	focus_area = FocusArea.ENTRIES
	
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	
	detail_tab_buttons.clear()
	detail_content_container = null
	detail_content_scroll = null
	
	_update_visual_focus()

func _handle_detail_popup_input(event: InputEvent) -> bool:
	"""Manejar input en el popup de detalle"""
	
	# ESC o ESPACIO - Cerrar
	if event.is_action_pressed("ui_cancel") or _is_space_pressed(event):
		_close_detail_popup()
		_play_click_sound()
		return true
	
	# A/D - Cambiar pestaña
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_detail_navigate_tab(-1)
		return true
	
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_detail_navigate_tab(1)
		return true
	
	# W/S - Scroll en contenido
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_detail_scroll(-60)
		return true
	
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_detail_scroll(60)
		return true
	
	# Consumir eventos de teclado relevantes
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		if key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_ESCAPE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			return true
	
	return false

func _detail_navigate_tab(direction: int) -> void:
	"""Navegar entre pestañas del popup de detalle"""
	var new_tab = (int(detail_current_tab) + direction) % 3
	if new_tab < 0:
		new_tab = 2
	detail_current_tab = new_tab as DetailTab
	_update_detail_tabs_visual()
	_show_detail_tab_content()
	_play_hover_sound()

func _detail_scroll(amount: int) -> void:
	"""Hacer scroll en el contenido del popup"""
	if detail_content_scroll and is_instance_valid(detail_content_scroll):
		detail_content_scroll.scroll_vertical += amount
		_play_hover_sound()

func _update_detail_tabs_visual() -> void:
	"""Actualizar visual de las pestañas del popup"""
	for i in range(detail_tab_buttons.size()):
		var btn = detail_tab_buttons[i]
		var is_selected = (i == int(detail_current_tab))
		
		if is_selected:
			btn.add_theme_color_override("font_color", DETAIL_SELECTED_TAB)
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.3, 0.4)
			style.border_color = DETAIL_SELECTED_TAB
			style.set_border_width_all(2)
			style.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
		else:
			btn.add_theme_color_override("font_color", DETAIL_UNSELECTED_TAB)
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")

func _show_detail_tab_content() -> void:
	"""Mostrar contenido de la pestaña seleccionada"""
	if not detail_content_container:
		return
	
	# Limpiar contenido anterior
	for child in detail_content_container.get_children():
		child.queue_free()
	
	match detail_current_tab:
		DetailTab.STATS:
			_show_detail_stats_tab()
		DetailTab.WEAPONS:
			_show_detail_weapons_tab()
		DetailTab.ITEMS:
			_show_detail_items_tab()

func _show_detail_stats_tab() -> void:
	"""Mostrar pestaña de estadísticas (igual que PauseMenu)"""
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content_container.add_child(scroll)
	detail_content_scroll = scroll
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)
	
	var entry = detail_current_entry
	var stats = entry.get("stats", {})
	var final_stats = entry.get("final_stats", stats)
	
	# === HEADER COMPACTO ===
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 40)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(header_hbox)
	
	# HP
	var hp = final_stats.get("max_health", stats.get("hp", 100))
	var hp_label = Label.new()
	hp_label.text = "❤️ %d" % int(hp)
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	header_hbox.add_child(hp_label)
	
	# Nivel
	var level = entry.get("level", 1)
	var level_label = Label.new()
	level_label.text = "📈 Nivel %d" % level
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", DETAIL_SELECTED_TAB)
	header_hbox.add_child(level_label)
	
	# Tiempo
	var time_str = entry.get("time", "00:00")
	var time_label = Label.new()
	time_label.text = "⏱️ %s" % time_str
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	header_hbox.add_child(time_label)
	
	# Separador
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	# === STATS EN DOS COLUMNAS ===
	var columns_hbox = HBoxContainer.new()
	columns_hbox.add_theme_constant_override("separation", 40)
	main_vbox.add_child(columns_hbox)
	
	# Columna izquierda (Defensivo)
	var left_column = VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 8)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(left_column)
	
	# Columna derecha (Ofensivo)
	var right_column = VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 8)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(right_column)
	
	# === DEFENSIVO ===
	var def_title = Label.new()
	def_title.text = "🛡️ DEFENSIVO"
	def_title.add_theme_font_size_override("font_size", 14)
	def_title.add_theme_color_override("font_color", CATEGORY_COLORS["defensive"])
	left_column.add_child(def_title)
	
	_add_detail_stat_row(left_column, "❤️", "Vida Máxima", str(int(final_stats.get("max_health", stats.get("hp", 100)))))
	_add_detail_stat_row(left_column, "🛡️", "Armadura", str(int(final_stats.get("armor", stats.get("armor", 0)))))
	_add_detail_stat_row(left_column, "~", "Esquivar", "%.0f%%" % (final_stats.get("dodge_chance", 0) * 100))
	_add_detail_stat_row(left_column, "+", "Regeneración", "%.1f/s" % final_stats.get("health_regen", 0))
	_add_detail_stat_row(left_column, "🩸", "Robo Vida", "%.0f%%" % (final_stats.get("life_steal", 0) * 100))
	
	# === OFENSIVO ===
	var off_title = Label.new()
	off_title.text = "⚔️ OFENSIVO"
	off_title.add_theme_font_size_override("font_size", 14)
	off_title.add_theme_color_override("font_color", CATEGORY_COLORS["offensive"])
	right_column.add_child(off_title)
	
	var damage_mult = final_stats.get("damage_mult", stats.get("damage", 1.0))
	_add_detail_stat_row(right_column, "⚔️", "Daño", _format_multiplier(damage_mult))
	
	var attack_speed = final_stats.get("attack_speed_mult", 1.0)
	_add_detail_stat_row(right_column, "⚡", "Vel. Ataque", _format_multiplier(attack_speed))
	
	var crit_chance = final_stats.get("crit_chance", stats.get("crit", 5) / 100.0)
	_add_detail_stat_row(right_column, "🎯", "Crítico", "%.0f%%" % (crit_chance * 100))
	
	var crit_damage = final_stats.get("crit_damage", 2.0)
	_add_detail_stat_row(right_column, "💢", "Daño Crítico", "x%.1f" % crit_damage)
	
	var area_mult = final_stats.get("area_mult", 1.0)
	_add_detail_stat_row(right_column, "🌀", "Área", _format_multiplier(area_mult))
	
	# === UTILIDAD ===
	var sep2 = HSeparator.new()
	main_vbox.add_child(sep2)
	
	var util_title = Label.new()
	util_title.text = "🔧 UTILIDAD"
	util_title.add_theme_font_size_override("font_size", 14)
	util_title.add_theme_color_override("font_color", CATEGORY_COLORS["utility"])
	main_vbox.add_child(util_title)
	
	var util_grid = GridContainer.new()
	util_grid.columns = 4
	util_grid.add_theme_constant_override("h_separation", 20)
	util_grid.add_theme_constant_override("v_separation", 6)
	main_vbox.add_child(util_grid)
	
	var move_speed = final_stats.get("move_speed", stats.get("speed", 100))
	_add_detail_stat_to_grid(util_grid, "🏃", "Velocidad", str(int(move_speed)))
	
	var pickup = final_stats.get("pickup_range", 100)
	_add_detail_stat_to_grid(util_grid, "🧲", "Recogida", str(int(pickup)))
	
	var xp_mult = final_stats.get("xp_mult", 1.0)
	_add_detail_stat_to_grid(util_grid, "⭐", "XP", _format_multiplier(xp_mult))
	
	var luck = final_stats.get("luck", 0)
	_add_detail_stat_to_grid(util_grid, "🍀", "Suerte", "%.0f%%" % (luck * 100))
	
	var cooldown = final_stats.get("cooldown_mult", 1.0)
	_add_detail_stat_to_grid(util_grid, "⏰", "Cooldown", _format_multiplier(cooldown))
	
	var proj_count = final_stats.get("extra_projectiles", 0)
	_add_detail_stat_to_grid(util_grid, "🎯", "Proyectiles+", "+%d" % int(proj_count))

func _show_detail_weapons_tab() -> void:
	"""Mostrar pestaña de armas (igual que PauseMenu)"""
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content_container.add_child(scroll)
	detail_content_scroll = scroll
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)
	
	var weapons = detail_current_entry.get("weapons", [])
	var weapons_data = detail_current_entry.get("weapons_data", [])
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "⚔️ ARSENAL (%d armas)" % weapons.size()
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", DETAIL_SELECTED_TAB)
	header.add_child(title)
	
	if weapons.is_empty():
		var empty = Label.new()
		empty.text = "🎮 No hay armas registradas en esta partida"
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		main_vbox.add_child(empty)
		return
	
	# Grid de armas
	var weapons_grid = VBoxContainer.new()
	weapons_grid.add_theme_constant_override("separation", 12)
	main_vbox.add_child(weapons_grid)
	
	for i in range(weapons.size()):
		var weapon_name = weapons[i]
		var weapon_data = weapons_data[i] if i < weapons_data.size() else {}
		var weapon_card = _create_detail_weapon_card(weapon_name, weapon_data)
		weapons_grid.add_child(weapon_card)

func _show_detail_items_tab() -> void:
	"""Mostrar pestaña de objetos (igual que PauseMenu)"""
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content_container.add_child(scroll)
	detail_content_scroll = scroll
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(grid)
	
	var items = detail_current_entry.get("items", [])
	var items_data = detail_current_entry.get("items_data", [])
	
	if items.is_empty():
		var empty = Label.new()
		empty.text = "📦 No hay objetos registrados en esta partida"
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		grid.add_child(empty)
		return
	
	# Agrupar items duplicados
	var grouped_items: Dictionary = {}
	var item_order: Array = []
	
	for i in range(items.size()):
		var item_name = items[i]
		var item_data = items_data[i] if i < items_data.size() else {}
		if not grouped_items.has(item_name):
			grouped_items[item_name] = {"data": item_data, "count": 0}
			item_order.append(item_name)
		grouped_items[item_name].count += 1
	
	for item_name in item_order:
		var info = grouped_items[item_name]
		var item_panel = _create_detail_item_panel(item_name, info.data, info.count)
		grid.add_child(item_panel)

func _add_detail_stat_row(parent: VBoxContainer, icon: String, stat_name: String, value: String) -> void:
	"""Añadir fila de stat al panel de detalle"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 12)
	icon_label.custom_minimum_size = Vector2(18, 0)
	hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", DETAIL_VALUE_COLOR)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(value_label)

func _add_detail_stat_to_grid(grid: GridContainer, icon: String, stat_name: String, value: String) -> void:
	"""Añadir stat al grid de utilidad"""
	var name_label = Label.new()
	name_label.text = "%s %s" % [icon, stat_name]
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	grid.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", DETAIL_VALUE_COLOR)
	grid.add_child(value_label)

func _format_multiplier(value: float) -> String:
	"""Formatear valor multiplicador como porcentaje"""
	var percent = (value - 1.0) * 100
	if percent >= 0:
		return "+%.0f%%" % percent
	return "%.0f%%" % percent

func _create_detail_weapon_card(weapon_name: String, weapon_data: Dictionary) -> Control:
	"""Crear tarjeta de arma para el popup de detalle"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var element = weapon_data.get("element", "physical")
	if element is int:
		var element_names = ["ice", "fire", "lightning", "arcane", "shadow", "nature", "wind", "earth", "light", "void", "physical"]
		element = element_names[element] if element < element_names.size() else "physical"
	element = str(element).to_lower()
	
	var element_color = ELEMENT_COLORS.get(element, Color.GRAY)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.border_color = element_color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	# Icono
	var icon_container = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = element_color.darkened(0.6)
	icon_style.set_corner_radius_all(6)
	icon_style.set_content_margin_all(6)
	icon_container.add_theme_stylebox_override("panel", icon_style)
	hbox.add_child(icon_container)
	
	var icon = Label.new()
	icon.text = ELEMENT_ICONS.get(element, "🔮")
	icon.add_theme_font_size_override("font_size", 24)
	icon_container.add_child(icon)
	
	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = weapon_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", element_color)
	info_vbox.add_child(name_label)
	
	var element_label = Label.new()
	element_label.text = ELEMENT_ICONS.get(element, "") + " " + element.capitalize()
	element_label.add_theme_font_size_override("font_size", 11)
	element_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(element_label)
	
	# Nivel si disponible
	var level = weapon_data.get("level", 0)
	if level > 0:
		var level_label = Label.new()
		level_label.text = "Nv.%d" % level
		level_label.add_theme_font_size_override("font_size", 16)
		level_label.add_theme_color_override("font_color", DETAIL_SELECTED_TAB)
		hbox.add_child(level_label)
	
	return card

func _create_detail_item_panel(item_name: String, item_data: Dictionary, count: int) -> Control:
	"""Crear panel de item para el popup de detalle"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 80)
	
	var tier = item_data.get("tier", 1)
	if tier is String:
		var tier_map = {"common": 1, "uncommon": 2, "rare": 3, "epic": 4, "legendary": 5}
		tier = tier_map.get(tier.to_lower(), 1)
	
	# Colores por tier
	var tier_colors = [
		Color(0.5, 0.5, 0.5),    # 0 - fallback
		Color(0.6, 0.6, 0.6),    # 1 - common
		Color(0.2, 0.8, 0.2),    # 2 - uncommon
		Color(0.2, 0.4, 1.0),    # 3 - rare
		Color(0.6, 0.2, 0.8),    # 4 - epic
		Color(1.0, 0.6, 0.1)     # 5 - legendary
	]
	var tier_color = tier_colors[clampi(tier, 0, 5)]
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = tier_color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	
	var icon = Label.new()
	icon.text = item_data.get("icon", "✨")
	icon.add_theme_font_size_override("font_size", 20)
	header.add_child(icon)
	
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", tier_color)
	header.add_child(name_label)
	
	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.add_theme_font_size_override("font_size", 13)
		count_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		header.add_child(count_label)
	
	# Descripción
	var desc = Label.new()
	desc.text = item_data.get("description", "")
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	return panel
