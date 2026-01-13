# LevelUpPanel.gd
# Panel de selección al subir de nivel
#
# NAVEGACIÓN COMPLETA (WASD y Flechas funcionan igual en todo):
# - ← → o A/D: Navegar horizontalmente (opciones o botones)
# - ↑ ↓ o W/S: Cambiar entre fila de opciones y fila de botones
# - Enter/Espacio: Confirmar acción

extends CanvasLayer
class_name LevelUpPanel

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal option_selected(option: Dictionary)
signal reroll_used()
signal banish_used(option_index: int)
signal skip_used()
signal upgrade_postponed()  # Nueva señal: mejora pospuesta (ESC sin elegir)
signal panel_closed()

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const MAX_OPTIONS: int = 4
const OPTION_TYPES = {
	NEW_WEAPON = "new_weapon",
	LEVEL_UP_WEAPON = "level_up_weapon",
	FUSION = "fusion",
	PLAYER_UPGRADE = "player_upgrade"
}

# Colores por TIER (sistema visual mejorado)
const TIER_COLORS = {
	1: Color(0.9, 0.9, 0.9),      # Tier 1 - Blanco
	2: Color(0.3, 0.9, 0.3),      # Tier 2 - Verde
	3: Color(0.4, 0.6, 1.0),      # Tier 3 - Azul
	4: Color(1.0, 0.85, 0.2),     # Tier 4 - Amarillo
	5: Color(1.0, 0.5, 0.1),      # Tier 5 - Naranja (Legendario)
}

# Colores especiales
const UNIQUE_COLOR = Color(1.0, 0.3, 0.3)     # Rojo para mejoras únicas
const CURSED_COLOR = Color(0.7, 0.2, 0.8)     # Púrpura para mejoras cursed
const WEAPON_COLOR = Color(1.0, 0.5, 0.1)     # Naranja para armas

# Colores legacy por rarity (compatibilidad)
const RARITY_COLORS = {
	"common": Color(0.9, 0.9, 0.9),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.4, 0.6, 1.0),
	"epic": Color(1.0, 0.85, 0.2),
	"legendary": Color(1.0, 0.5, 0.1)
}

const SELECTED_COLOR = Color(1.0, 0.85, 0.3)
const UNSELECTED_COLOR = Color(0.4, 0.4, 0.5)
const DISABLED_COLOR = Color(0.3, 0.3, 0.35)
const BG_COLOR = Color(0.08, 0.08, 0.12, 0.95)
const PANEL_BG = Color(0.12, 0.12, 0.18, 0.98)
const BUTTON_BG = Color(0.18, 0.18, 0.25)
const BUTTON_HOVER = Color(0.25, 0.25, 0.35)

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO DE NAVEGACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

enum Row { OPTIONS, BUTTONS }

var current_row: Row = Row.OPTIONS
var option_index: int = 0      # Índice en fila de opciones (0-3)
var button_index: int = 0      # Índice en fila de botones (0=Reroll, 1=Eliminar, 2=Saltar)
var banish_mode: bool = false  # Modo selección para eliminar

var options: Array = []
var option_panels: Array = []
var button_panels: Array = []
var reroll_count: int = 3
var banish_count: int = 2
var locked: bool = false

# Cache de estilos para evitar memory leaks
var _option_styles: Array[StyleBoxFlat] = []  # Un estilo por panel de opción
var _button_styles: Array[StyleBoxFlat] = []  # Un estilo por botón

# Referencias
var attack_manager: AttackManager = null
var player_stats: PlayerStats = null

# UI Nodes
var title_label: Label = null
var hint_label: Label = null
var options_container: HBoxContainer = null
var buttons_container: HBoxContainer = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()

func initialize(attack_mgr: AttackManager, stats: PlayerStats) -> void:
	attack_manager = attack_mgr
	player_stats = stats
	_sync_counts_from_player_stats()

func _sync_counts_from_player_stats() -> void:
	"""Sincronizar reroll/banish counts con PlayerStats"""
	if player_stats and player_stats.has_method("get_stat"):
		var extra_rerolls = int(player_stats.get_stat("reroll_count"))
		var extra_banishes = int(player_stats.get_stat("banish_count"))
		reroll_count = 2 + extra_rerolls  # Base 2 + mejoras
		banish_count = 2 + extra_banishes  # Base 2 + mejoras

func _get_max_options() -> int:
	"""Obtener número máximo de opciones (base + mejoras)"""
	var extra = 0
	if player_stats and player_stats.has_method("get_stat"):
		extra = int(player_stats.get_stat("levelup_options"))
	return MAX_OPTIONS + extra

func _create_ui() -> void:
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centro
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Panel principal
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(1100, 580)
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = PANEL_BG
	main_style.border_color = Color(0.3, 0.3, 0.4)
	main_style.set_border_width_all(2)
	main_style.set_corner_radius_all(16)
	main_style.set_content_margin_all(25)
	main_panel.add_theme_stylebox_override("panel", main_style)
	center.add_child(main_panel)

	# Layout vertical
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	# === TÍTULO ===
	title_label = Label.new()
	title_label.text = "⬆️ ¡SUBISTE DE NIVEL! ⬆️"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", SELECTED_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# === INSTRUCCIONES ===
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "Elige una mejora para continuar"
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)

	# === FILA DE OPCIONES ===
	options_container = HBoxContainer.new()
	options_container.add_theme_constant_override("separation", 20)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(options_container)

	for i in range(MAX_OPTIONS):
		var panel = _create_option_panel(i)
		options_container.add_child(panel)
		option_panels.append(panel)

	# === SEPARADOR ===
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator_color", Color(0.3, 0.3, 0.4))
	vbox.add_child(sep)

	# === FILA DE BOTONES ===
	buttons_container = HBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 30)
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_container)

	# Crear los 3 botones de acción
	var btn_reroll = _create_action_button(0, "🎲", "Reroll", "(%d)")
	var btn_banish = _create_action_button(1, "❌", "Eliminar", "(%d)")
	var btn_skip = _create_action_button(2, "⏭️", "Saltar", "")

	buttons_container.add_child(btn_reroll)
	buttons_container.add_child(btn_banish)
	buttons_container.add_child(btn_skip)

	button_panels.append(btn_reroll)
	button_panels.append(btn_banish)
	button_panels.append(btn_skip)

	# === AYUDA DE NAVEGACIÓN ===
	var nav_help = Label.new()
	nav_help.text = "← → Navegar   |   ↑ ↓ Cambiar fila   |   ENTER Confirmar"
	nav_help.add_theme_font_size_override("font_size", 12)
	nav_help.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	nav_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nav_help)

func _create_option_panel(index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 300)
	panel.name = "Option_%d" % index

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.2)
	style.border_color = UNSELECTED_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Tipo
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)

	# Icono
	var icon_center = CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(80, 80)
	vbox.add_child(icon_center)

	var icon_container = Control.new()
	icon_container.name = "IconContainer"
	icon_container.custom_minimum_size = Vector2(64, 64)
	icon_center.add_child(icon_container)

	var icon_label = Label.new()
	icon_label.name = "IconLabel"
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_container.add_child(icon_label)

	var icon_texture = TextureRect.new()
	icon_texture.name = "IconTexture"
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.custom_minimum_size = Vector2(64, 64)
	icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_texture.visible = false
	icon_container.add_child(icon_texture)

	# Nombre
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 50
	vbox.add_child(desc_label)

	# Indicador de selección
	var indicator = Label.new()
	indicator.name = "Indicator"
	indicator.text = "▲ ENTER ▲"
	indicator.add_theme_font_size_override("font_size", 12)
	indicator.add_theme_color_override("font_color", SELECTED_COLOR)
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator.visible = false
	vbox.add_child(indicator)

	return panel

func _create_action_button(index: int, icon: String, text: String, count_format: String) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 60)
	panel.name = "Button_%d" % index

	var style = StyleBoxFlat.new()
	style.bg_color = BUTTON_BG
	style.border_color = UNSELECTED_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var icon_label = Label.new()
	icon_label.name = "Icon"
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 24)
	hbox.add_child(icon_label)

	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var text_label = Label.new()
	text_label.name = "Text"
	text_label.text = text
	text_label.add_theme_font_size_override("font_size", 16)
	text_vbox.add_child(text_label)

	if count_format != "":
		var count_label = Label.new()
		count_label.name = "Count"
		count_label.text = count_format % 0
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		text_vbox.add_child(count_label)

	return panel

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT - NAVEGACIÓN COMPLETA
# ═══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if locked or not visible:
		return

	var handled = false

	# === NAVEGACION CON WASD Y FLECHAS ===
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A, KEY_LEFT:
				_navigate_horizontal(-1)
				handled = true
			KEY_D, KEY_RIGHT:
				_navigate_horizontal(1)
				handled = true
			KEY_W, KEY_UP:
				_navigate_vertical(-1)
				handled = true
			KEY_S, KEY_DOWN:
				_navigate_vertical(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_confirm_selection()
				handled = true
			KEY_ESCAPE:
				if banish_mode:
					_cancel_banish_mode()
				else:
					_on_postpone()  # Posponer mejora en vez de saltar
				handled = true

	# === SOPORTE PARA GAMEPAD ===
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_navigate_horizontal(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT:
				_navigate_horizontal(1)
				handled = true
			JOY_BUTTON_DPAD_UP:
				_navigate_vertical(-1)
				handled = true
			JOY_BUTTON_DPAD_DOWN:
				_navigate_vertical(1)
				handled = true
			JOY_BUTTON_A:
				_confirm_selection()
				handled = true
			JOY_BUTTON_B:
				if banish_mode:
					_cancel_banish_mode()
				else:
					_on_postpone()  # Posponer mejora en vez de saltar
				handled = true

	# === SOPORTE PARA JOYSTICK ANALOGICO ===
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_X:
			if event.axis_value < -0.5:
				_navigate_horizontal(-1)
				handled = true
			elif event.axis_value > 0.5:
				_navigate_horizontal(1)
				handled = true
		elif event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate_vertical(-1)
				handled = true
			elif event.axis_value > 0.5:
				_navigate_vertical(1)
				handled = true

	if handled:
		get_viewport().set_input_as_handled()

func _navigate_horizontal(direction: int) -> void:
	# En modo eliminar, solo navegar opciones
	if banish_mode:
		var count = options.size()
		if count == 0:
			return
		option_index = (option_index + direction) % count
		if option_index < 0:
			option_index = count - 1
	elif current_row == Row.OPTIONS:
		var count = options.size()
		if count == 0:
			return
		option_index = (option_index + direction) % count
		if option_index < 0:
			option_index = count - 1
	else:
		# En fila de botones (3 botones)
		button_index = (button_index + direction) % 3
		if button_index < 0:
			button_index = 2

	_update_all_visuals()

func _navigate_vertical(direction: int) -> void:
	# En modo eliminar, no permitir cambiar de fila
	if banish_mode:
		return

	if direction > 0:
		# Bajar a botones
		current_row = Row.BUTTONS
	else:
		# Subir a opciones
		current_row = Row.OPTIONS

	_update_all_visuals()

func _confirm_selection() -> void:
	# En modo eliminar, confirmar = eliminar la opción seleccionada
	if banish_mode:
		_confirm_banish()
		return

	if current_row == Row.OPTIONS:
		# Seleccionar opción actual
		_select_option()
	else:
		# Ejecutar botón actual
		match button_index:
			0: _on_reroll()
			1: _on_banish()
			2: _on_skip()

# ═══════════════════════════════════════════════════════════════════════════════
# ACCIONES
# ═══════════════════════════════════════════════════════════════════════════════

func _select_option() -> void:
	if locked or option_index >= options.size():
		return

	locked = true
	var selected = options[option_index]
	_apply_option(selected)
	option_selected.emit(selected)
	_close_panel()

func _on_reroll() -> void:
	if locked or reroll_count <= 0:
		return

	reroll_count -= 1
	reroll_used.emit()
	generate_options()
	# Volver a opciones después de reroll
	current_row = Row.OPTIONS
	option_index = 0
	_update_all_visuals()

func _on_banish() -> void:
	if locked or banish_count <= 0 or options.size() == 0:
		return

	# Activar modo de selección para eliminar
	banish_mode = true
	current_row = Row.OPTIONS  # Forzar a la fila de opciones
	_update_hint_text()
	_update_all_visuals()

func _confirm_banish() -> void:
	# Verificar que hay opciones para eliminar
	if options.is_empty():
		banish_mode = false
		return
	
	# Ajustar índice si está fuera de rango
	if option_index >= options.size():
		option_index = options.size() - 1

	options.remove_at(option_index)
	banish_count -= 1
	banish_used.emit(option_index)

	# Salir del modo eliminar
	banish_mode = false

	# Ajustar índice
	if option_index >= options.size() and options.size() > 0:
		option_index = options.size() - 1

	_update_hint_text()
	_update_options_ui()
	_update_all_visuals()
	_update_button_counts()

func _cancel_banish_mode() -> void:
	banish_mode = false
	_update_hint_text()
	_update_all_visuals()

func _on_skip() -> void:
	if locked:
		return

	skip_used.emit()
	_close_panel()

func _on_postpone() -> void:
	"""Posponer la mejora para más tarde (accesible desde menú de pausa)"""
	if locked:
		return
	
	upgrade_postponed.emit()
	_close_panel()

func _close_panel() -> void:
	# NOTA: NO despausamos aquí - Game.gd se encarga de eso
	# después de verificar si hay más level ups pendientes
	panel_closed.emit()
	queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN VISUAL
# ═══════════════════════════════════════════════════════════════════════════════

const BANISH_COLOR = Color(1.0, 0.3, 0.3)  # Rojo para modo eliminar

func _update_hint_text() -> void:
	if hint_label:
		if banish_mode:
			hint_label.text = "❌ MODO ELIMINAR: Selecciona qué mejora quitar (ESC para cancelar)"
			hint_label.add_theme_color_override("font_color", BANISH_COLOR)
		else:
			hint_label.text = "Elige una mejora para continuar"
			hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

func _update_all_visuals() -> void:
	# Actualizar opciones
	for i in range(option_panels.size()):
		var panel = option_panels[i]
		var is_selected = ((current_row == Row.OPTIONS or banish_mode) and i == option_index and i < options.size())
		var is_visible = (i < options.size())

		panel.visible = is_visible

		if not is_visible:
			continue

		# Usar estilo cacheado o crear uno nuevo si no existe
		if i >= _option_styles.size():
			var new_style = StyleBoxFlat.new()
			new_style.bg_color = PANEL_BG
			new_style.set_corner_radius_all(8)
			_option_styles.append(new_style)
		
		var style = _option_styles[i]
		if is_selected:
			# En modo eliminar, borde rojo
			style.border_color = BANISH_COLOR if banish_mode else SELECTED_COLOR
			style.set_border_width_all(3)
		else:
			style.border_color = UNSELECTED_COLOR
			style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)

		var indicator = panel.find_child("Indicator", true, false) as Label
		if indicator:
			indicator.visible = is_selected
			if banish_mode:
				indicator.text = "❌ ELIMINAR ❌"
				indicator.add_theme_color_override("font_color", BANISH_COLOR)
			else:
				indicator.text = "▲ ENTER ▲"
				indicator.add_theme_color_override("font_color", SELECTED_COLOR)

	# Actualizar botones (ocultos en modo eliminar)
	for i in range(button_panels.size()):
		var panel = button_panels[i]
		var is_selected = (current_row == Row.BUTTONS and i == button_index and not banish_mode)
		var is_disabled = _is_button_disabled(i)

		# En modo eliminar, atenuar los botones
		if banish_mode:
			panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			panel.modulate = Color.WHITE

		# Usar estilo cacheado o crear uno nuevo si no existe
		if i >= _button_styles.size():
			var new_style = StyleBoxFlat.new()
			new_style.set_corner_radius_all(6)
			_button_styles.append(new_style)
		
		var style = _button_styles[i]
		if is_disabled:
			style.border_color = DISABLED_COLOR
			style.bg_color = Color(0.1, 0.1, 0.12)
			style.set_border_width_all(2)
		elif is_selected:
			style.border_color = SELECTED_COLOR
			style.bg_color = BUTTON_HOVER
			style.set_border_width_all(3)
		else:
			style.border_color = UNSELECTED_COLOR
			style.bg_color = BUTTON_BG
			style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)

		# Actualizar color del texto si está deshabilitado
		var text_label = panel.find_child("Text", true, false) as Label
		if text_label:
			text_label.add_theme_color_override("font_color", DISABLED_COLOR if is_disabled else Color.WHITE)

func _is_button_disabled(index: int) -> bool:
	match index:
		0: return reroll_count <= 0  # Reroll
		1: return banish_count <= 0 or options.size() == 0  # Eliminar
		_: return false  # Saltar siempre disponible

func _update_button_counts() -> void:
	# Actualizar contador de Reroll
	var reroll_count_label = button_panels[0].find_child("Count", true, false) as Label
	if reroll_count_label:
		reroll_count_label.text = "(%d)" % reroll_count

	# Actualizar contador de Banish
	var banish_count_label = button_panels[1].find_child("Count", true, false) as Label
	if banish_count_label:
		banish_count_label.text = "(%d)" % banish_count

func _update_options_ui() -> void:
	for i in range(MAX_OPTIONS):
		var panel = option_panels[i]

		if i < options.size():
			_update_option_panel(panel, options[i])
			panel.visible = true
		else:
			panel.visible = false

func _update_option_panel(panel: Control, option: Dictionary) -> void:
	var type_label = panel.find_child("TypeLabel", true, false) as Label
	var icon_label = panel.find_child("IconLabel", true, false) as Label
	var icon_texture = panel.find_child("IconTexture", true, false) as TextureRect
	var name_label = panel.find_child("NameLabel", true, false) as Label
	var desc_label = panel.find_child("DescLabel", true, false) as Label

	# Tipo
	if type_label:
		type_label.text = _get_type_text(option.get("type", ""))

	# Icono
	var icon_value = option.get("icon", "✨")
	var is_image_path = str(icon_value).begins_with("res://") or str(icon_value).ends_with(".png")

	if icon_label and icon_texture:
		if is_image_path:
			icon_label.visible = false
			icon_texture.visible = true
			var texture = load(str(icon_value))
			if texture:
				icon_texture.texture = texture
			else:
				icon_label.visible = true
				icon_texture.visible = false
				icon_label.text = "✨"
		else:
			icon_label.visible = true
			icon_texture.visible = false
			icon_label.text = str(icon_value)

	# Nombre con color basado en TIER y tipo especial
	if name_label:
		name_label.text = option.get("name", "???")
		var name_color = _get_option_color(option)
		name_label.add_theme_color_override("font_color", name_color)

	# Descripción
	if desc_label:
		desc_label.text = option.get("description", "")

func _get_option_color(option: Dictionary) -> Color:
	"""Determina el color del nombre basado en tier, tipo especial, etc."""
	var option_type = option.get("type", "")
	
	# Armas nuevas y mejoras de arma tienen color naranja
	if option_type == OPTION_TYPES.NEW_WEAPON or option_type == OPTION_TYPES.LEVEL_UP_WEAPON:
		return WEAPON_COLOR
	
	# Mejoras únicas tienen color rojo
	if option.get("is_unique", false):
		return UNIQUE_COLOR
	
	# Mejoras cursed tienen color púrpura
	if option.get("is_cursed", false):
		return CURSED_COLOR
	
	# Por tier
	var tier = option.get("tier", 1)
	if typeof(tier) == TYPE_STRING:
		# Convertir rarity string a tier number
		match tier:
			"common": tier = 1
			"uncommon": tier = 2
			"rare": tier = 3
			"epic": tier = 4
			"legendary": tier = 5
			_: tier = 1
	
	return TIER_COLORS.get(tier, TIER_COLORS[1])

func _get_type_text(option_type: String) -> String:
	match option_type:
		OPTION_TYPES.NEW_WEAPON: return "🆕 Nueva Arma"
		OPTION_TYPES.LEVEL_UP_WEAPON: return "⬆️ Mejorar"
		OPTION_TYPES.FUSION: return "🔥 Fusión"
		OPTION_TYPES.PLAYER_UPGRADE: return "✨ Mejora"
		_: return "✨ Mejora"

# ═══════════════════════════════════════════════════════════════════════════════
# GENERACIÓN DE OPCIONES
# ═══════════════════════════════════════════════════════════════════════════════

func generate_options() -> void:
	options.clear()
	
	# NOTA: NO sincronizar aquí - Game.gd gestiona los contadores
	# y los incrementa cuando se obtienen mejoras de reroll/banish

	var luck = 0.0
	if player_stats and player_stats.has_method("get_stat"):
		luck = player_stats.get_stat("luck")

	var possible_options: Array = []

	# 1. Nuevas armas
	if attack_manager and attack_manager.has_method("has_available_slot"):
		if attack_manager.has_available_slot:
			possible_options.append_array(_get_new_weapon_options())

	# 2. Subir nivel de armas
	if attack_manager and attack_manager.has_method("get_weapons"):
		possible_options.append_array(_get_weapon_level_up_options())

	# 3. Fusiones
	if attack_manager and attack_manager.has_method("get_available_fusions"):
		possible_options.append_array(_get_fusion_options())

	# 4. Upgrades del jugador
	possible_options.append_array(_get_player_upgrade_options(luck))

	# Fallback
	if possible_options.size() < 2:
		possible_options = _get_fallback_options()

	possible_options.shuffle()
	options = _balance_options(possible_options)
	option_index = 0

	_update_options_ui()
	_update_all_visuals()
	_update_button_counts()

func _get_player_upgrade_options(luck: float) -> Array:
	"""
	Obtiene opciones de mejora para el jugador.
	
	SISTEMA v3.0:
	- Mejoras GLOBALES DE ARMAS → WeaponUpgradeDatabase.GLOBAL_UPGRADES (estático)
	- Mejoras DEL JUGADOR → PlayerUpgradeDatabase (defensivas, utilidad, cursed, únicas) (estático)
	"""
	var upgrade_options: Array = []
	var game_time_minutes = _get_game_time_minutes()
	
	# 1. MEJORAS GLOBALES DE ARMAS (WeaponUpgradeDatabase) - Función estática
	var global_upgrades = WeaponUpgradeDatabase.get_random_global_upgrades(3, [], luck, game_time_minutes)
	for upgrade in global_upgrades:
		upgrade_options.append({
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": upgrade.get("id", ""),
			"name": upgrade.get("name", "???"),
			"description": upgrade.get("description", ""),
			"icon": upgrade.get("icon", "⚔️"),
			"tier": upgrade.get("tier", 1),
			"category": "weapon_global",
			"effects": upgrade.get("effects", []),
			"is_cursed": upgrade.get("is_cursed", false),
			"is_unique": upgrade.get("is_unique", false),
			"priority": 0.9
		})
	
	# 2. MEJORAS DEL JUGADOR (PlayerUpgradeDatabase) - Función estática
	var owned_unique_ids = _get_owned_unique_upgrade_ids()
	var player_upgrades = PlayerUpgradeDatabase.get_random_player_upgrades(4, [], luck, game_time_minutes, owned_unique_ids)
	for upgrade in player_upgrades:
		upgrade_options.append({
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": upgrade.get("id", ""),
			"name": upgrade.get("name", "???"),
			"description": upgrade.get("description", ""),
			"icon": upgrade.get("icon", "✨"),
			"tier": upgrade.get("tier", 1),
			"category": upgrade.get("category", "player"),
			"effects": upgrade.get("effects", []),
			"is_cursed": upgrade.get("is_cursed", false),
			"is_unique": upgrade.get("is_unique", false),
			"is_consumable": upgrade.get("is_consumable", false),
			"priority": 0.8
		})

	return upgrade_options

func _get_owned_unique_upgrade_ids() -> Array:
	"""Obtiene IDs de mejoras únicas que el jugador ya posee"""
	if player_stats and player_stats.has_method("get_owned_unique_ids"):
		return player_stats.get_owned_unique_ids()
	return []

func _is_weapon_upgrade(passive: Dictionary) -> bool:
	"""Determina si una mejora es de armas (para filtrarla de PassiveDatabase)"""
	var weapon_stats = [
		"damage_mult", "cooldown_mult", "attack_speed_mult",
		"area_mult", "projectile_speed_mult", "duration_mult",
		"extra_projectiles", "knockback_mult", "crit_chance", "crit_damage"
	]
	
	var effects = passive.get("effects", [])
	if effects.is_empty() and passive.has("effect"):
		var eff = passive.effect
		if eff.get("type", "") == "multi" and eff.has("effects"):
			for sub_eff in eff.effects:
				if sub_eff.get("stat", "") in weapon_stats:
					return true
		elif eff.get("stat", "") in weapon_stats:
			return true
	else:
		for effect in effects:
			if effect.get("stat", "") in weapon_stats:
				return true
	
	return false

func _get_game_time_minutes() -> float:
	"""Obtener tiempo de juego en minutos para el sistema de tiers"""
	# Buscar GameManager para obtener el tiempo
	var game_manager = get_tree().root.get_node_or_null("Game")
	if game_manager and "game_time" in game_manager:
		return game_manager.game_time / 60.0
	
	# Alternativa: buscar por grupo
	var managers = get_tree().get_nodes_in_group("game_manager")
	if not managers.is_empty():
		var gm = managers[0]
		if "game_time" in gm:
			return gm.game_time / 60.0
	
	# Fallback: asumir partida temprana
	return 3.0

func _get_fallback_options() -> Array:
	"""Opciones de respaldo si no hay suficientes mejoras disponibles"""
	return [
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "damage_boost",
			"name": "Daño Mágico +",
			"description": "Aumenta el daño de todas las armas en un 10%",
			"icon": "⚡",
			"rarity": "common",
			"category": "weapon_global",  # Va a GlobalWeaponStats
			"effects": [{"stat": "damage_mult", "value": 1.10, "operation": "multiply"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "attack_speed_boost",
			"name": "Velocidad de Ataque +",
			"description": "Aumenta la velocidad de ataque en un 10%",
			"icon": "⚡",
			"rarity": "common",
			"category": "weapon_global",  # Va a GlobalWeaponStats
			"effects": [{"stat": "attack_speed_mult", "value": 1.10, "operation": "multiply"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "speed_boost",
			"name": "Velocidad +",
			"description": "Aumenta tu velocidad de movimiento en un 10%",
			"icon": "💨",
			"rarity": "common",
			"category": "player",  # Va a PlayerStats
			"effects": [{"stat": "move_speed", "value": 0.10, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "health_boost",
			"name": "Vida Máxima +",
			"description": "Aumenta tu vida máxima en 20",
			"icon": "❤️",
			"rarity": "common",
			"category": "player",  # Va a PlayerStats
			"effects": [{"stat": "max_health", "value": 20, "operation": "add"}],
			"priority": 0.8
		}
	]

func _get_new_weapon_options() -> Array:
	var new_options: Array = []
	var current_ids = []

	for weapon in attack_manager.get_weapons():
		current_ids.append(weapon.id)

	var all_weapons = WeaponDatabase.get_all_base_weapons()
	for weapon_id in all_weapons:
		if weapon_id in current_ids:
			continue

		var data = WeaponDatabase.get_weapon_data(weapon_id)
		if data.is_empty():
			continue

		new_options.append({
			"type": OPTION_TYPES.NEW_WEAPON,
			"weapon_id": weapon_id,
			"name": data.get("name_es", data.get("name", "?")),
			"description": data.get("description", ""),
			"icon": data.get("icon", "🔮"),
			"rarity": data.get("rarity", "common"),
			"priority": 1.0
		})

	return new_options

func _get_weapon_level_up_options() -> Array:
	var level_options: Array = []

	for weapon in attack_manager.get_weapons():
		# Verificar que el arma tenga el metodo can_level_up
		if not weapon.has_method("can_level_up"):
			continue
		if not weapon.can_level_up():
			continue

		var weapon_name = weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.get("name", "???")
		var weapon_level = weapon.level if "level" in weapon else 1
		var weapon_icon = weapon.icon if "icon" in weapon else "⚔️"
		var next_desc = ""
		if weapon.has_method("get_next_upgrade_description"):
			next_desc = weapon.get_next_upgrade_description()

		level_options.append({
			"type": OPTION_TYPES.LEVEL_UP_WEAPON,
			"weapon_id": weapon.id if "id" in weapon else "",
			"weapon": weapon,
			"name": "%s Nv.%d → %d" % [weapon_name, weapon_level, weapon_level + 1],
			"description": next_desc,
			"icon": weapon_icon,
			"rarity": "uncommon" if weapon_level < 5 else "rare",
			"priority": 1.5
		})

	return level_options

func _get_fusion_options() -> Array:
	var fusion_options: Array = []
	var available = attack_manager.get_available_fusions()

	for fusion in available:
		var preview = attack_manager.get_fusion_preview(fusion.weapon_a, fusion.weapon_b)

		fusion_options.append({
			"type": OPTION_TYPES.FUSION,
			"weapon_a": fusion.weapon_a,
			"weapon_b": fusion.weapon_b,
			"result": fusion.result,
			"name": "🔥 %s" % preview.get("name_es", preview.get("name", "???")),
			"description": "Fusión: %s + %s" % [
				fusion.weapon_a.weapon_name_es, fusion.weapon_b.weapon_name_es
			],
			"icon": preview.get("icon", "⚡"),
			"rarity": "epic",
			"priority": 2.0
		})

	return fusion_options

func _balance_options(all_options: Array) -> Array:
	var balanced: Array = []
	var by_type: Dictionary = {}
	var max_opts = _get_max_options()

	for opt in all_options:
		var t = opt.type
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(opt)

	for t in by_type:
		by_type[t].sort_custom(func(a, b): return a.priority > b.priority)

	for t in by_type:
		if balanced.size() >= max_opts:
			break
		if not by_type[t].is_empty():
			balanced.append(by_type[t].pop_front())

	var remaining: Array = []
	for t in by_type:
		remaining.append_array(by_type[t])
	remaining.shuffle()

	while balanced.size() < max_opts and not remaining.is_empty():
		balanced.append(remaining.pop_front())

	return balanced

# ═══════════════════════════════════════════════════════════════════════════════
# APLICAR OPCIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _apply_option(option: Dictionary) -> void:
	match option.type:
		OPTION_TYPES.NEW_WEAPON:
			if attack_manager and attack_manager.has_method("add_weapon_by_id"):
				attack_manager.add_weapon_by_id(option.weapon_id)

		OPTION_TYPES.LEVEL_UP_WEAPON:
			if attack_manager and attack_manager.has_method("level_up_weapon_by_id"):
				attack_manager.level_up_weapon_by_id(option.weapon_id)

		OPTION_TYPES.FUSION:
			if attack_manager and attack_manager.has_method("fuse_weapons"):
				attack_manager.fuse_weapons(option.weapon_a, option.weapon_b)

		OPTION_TYPES.PLAYER_UPGRADE:
			_apply_player_upgrade(option)

func _apply_player_upgrade(option: Dictionary) -> void:
	"""
	Aplicar mejora seleccionada.
	
	SISTEMA v3.0:
	- Efectos de armas (damage_mult, attack_speed_mult, etc.) → AttackManager.apply_global_upgrade()
	- Efectos del jugador (max_health, armor, etc.) → PlayerStats.apply_upgrade()
	- Las mejoras CURSED pueden tener AMBOS tipos de efectos
	"""
	var is_unique = option.get("is_unique", false)
	var is_cursed = option.get("is_cursed", false)
	var is_consumable = option.get("is_consumable", false)
	var upgrade_name = option.get("name", "???")
	var category = option.get("category", "player")
	var effects = option.get("effects", [])
	
	# Log especial para mejoras especiales
	if is_unique:
		# print("[LevelUpPanel] 🔴 MEJORA ÚNICA obtenida: %s" % upgrade_name)
		pass
	if is_cursed:
		# print("[LevelUpPanel] 💜 Mejora CURSED aplicada: %s" % upgrade_name)
		pass
	if is_consumable:
		# print("[LevelUpPanel] 🟡 Mejora CONSUMIBLE usada: %s" % upgrade_name)
		pass
	
	# Stats que van a GlobalWeaponStats (armas) - NO incluye crit porque está en PlayerStats
	var weapon_stats = [
		"damage_mult", "damage_flat", "attack_speed_mult", "cooldown_mult",
		"area_mult", "projectile_speed_mult", "duration_mult", "knockback_mult",
		"extra_projectiles", "extra_pierce", "range_mult"
	]
	# NOTA: crit_chance y crit_damage van a PlayerStats y se sincronizan al AttackManager
	
	# Separar efectos en dos grupos
	var weapon_effects = []
	var player_effects = []
	
	for effect in effects:
		var stat = effect.get("stat", "")
		if stat in weapon_stats:
			weapon_effects.append(effect)
		else:
			player_effects.append(effect)
	
	# Aplicar efectos de ARMAS a GlobalWeaponStats
	if not weapon_effects.is_empty():
		if attack_manager and attack_manager.has_method("apply_global_upgrade"):
			var weapon_option = option.duplicate()
			weapon_option["effects"] = weapon_effects
			attack_manager.apply_global_upgrade(weapon_option)
			# print("[LevelUpPanel] ⚔️ Efectos de armas aplicados (%d): %s" % [weapon_effects.size(), upgrade_name])
	
	# Aplicar efectos de JUGADOR a PlayerStats
	if not player_effects.is_empty():
		if player_stats and player_stats.has_method("apply_upgrade"):
			var player_option = option.duplicate()
			player_option["effects"] = player_effects
			var success = player_stats.apply_upgrade(player_option)
			if success:
				# print("[LevelUpPanel] 🛡️ Efectos de jugador aplicados (%d): %s" % [player_effects.size(), upgrade_name])
				pass
			else:
				push_warning("[LevelUpPanel] No se pudo aplicar mejora: %s" % upgrade_name)
	
	# Registrar mejora única para evitar duplicados
	if is_unique and player_stats and player_stats.has_method("register_unique_upgrade"):
		player_stats.register_unique_upgrade(option.get("upgrade_id", ""))

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func show_panel() -> void:
	visible = true
	get_tree().paused = true
	locked = false
	current_row = Row.OPTIONS
	option_index = 0
	button_index = 0
	generate_options()

func setup_options(opts: Array) -> void:
	options = opts.duplicate()
	option_index = 0
	_update_options_ui()
	_update_all_visuals()

func set_reroll_count(count: int) -> void:
	reroll_count = count
	_update_button_counts()
	_update_all_visuals()

func set_banish_count(count: int) -> void:
	banish_count = count
	_update_button_counts()
	_update_all_visuals()
