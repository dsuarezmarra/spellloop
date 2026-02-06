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
enum FocusArea { TABS, ENTRIES, FOOTER, MONTH_POPUP }

var current_tab: Tab = Tab.TOP_100
var current_entries: Array = []
var is_loading: bool = false

# Navegación
var focus_area: FocusArea = FocusArea.TABS
var tab_index: int = 0
var footer_index: int = 0  # 0=mes, 1=actualizar, 2=volver
var entry_index: int = 0   # Índice de entry seleccionada
var expanded_entry_index: int = -1  # -1 = ninguna expandida

# Paneles de entries (para actualizar visual)
var entry_panels: Array[Control] = []
var detail_panels: Array[Control] = []

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
	
	# Si el popup de mes está abierto
	if month_popup_visible:
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
	
	# Obtener stats finales (formato nuevo o calcular desde formato antiguo)
	var final_stats = run.get("final_stats", {})
	var level = 1
	if final_stats.has("level"):
		level = final_stats.get("level", 1)
	elif run.has("player_level"):
		level = run.get("player_level", 1)
	elif run.has("level_reached"):
		level = run.get("level_reached", 1)
	
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
	for w in weapons_raw:
		if w is Dictionary:
			weapons.append(w.get("name_es", w.get("name", "Unknown")))
		elif w is String:
			weapons.append(w)
	
	# Obtener mejoras/objetos
	var upgrades_raw = run.get("upgrades", [])
	var items: Array = []
	for u in upgrades_raw:
		if u is Dictionary:
			items.append(u.get("name", "Unknown"))
		elif u is String:
			items.append(u)
	
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
		"weapons": weapons,
		"items": items,
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
	"""Expandir o colapsar los detalles de una entry"""
	if index < 0 or index >= detail_panels.size():
		return
	
	# Si ya está expandida esta, colapsar
	if expanded_entry_index == index:
		detail_panels[index].visible = false
		expanded_entry_index = -1
	else:
		# Colapsar la anterior si había una
		if expanded_entry_index >= 0 and expanded_entry_index < detail_panels.size():
			detail_panels[expanded_entry_index].visible = false
		
		# Expandir la nueva
		detail_panels[index].visible = true
		expanded_entry_index = index

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
