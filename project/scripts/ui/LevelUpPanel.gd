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
signal panel_closed()

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const BASE_OPTIONS: int = 4          # Opciones base sin mejoras
const MAX_POSSIBLE_OPTIONS: int = 7  # Máximo posible con mejoras (4 base + 3 max stacks)
const OPTION_TYPES = {
	NEW_WEAPON = "new_weapon",
	LEVEL_UP_WEAPON = "level_up_weapon",
	FUSION = "fusion",
	PLAYER_UPGRADE = "player_upgrade"
}

# Usar colores centralizados de UIVisualHelper
# TIER_COLORS ahora viene de UIVisualHelper.TIER_COLORS

# Colores especiales
const UNIQUE_COLOR = Color(1.0, 0.3, 0.3)     # Rojo para mejoras únicas
const CURSED_COLOR = Color(0.7, 0.2, 0.8)     # Púrpura para mejoras cursed
const WEAPON_COLOR = Color(1.0, 0.5, 0.1)     # Naranja para armas
const FUSION_COLOR = Color(1.0, 0.4, 0.0)     # Naranja intenso base para fusiones
const FUSION_GLOW_COLOR = Color(1.0, 0.85, 0.3)  # Dorado brillante para el glow de fusiones

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
var rerolls_used_this_level: int = 0  # BALANCE: Track rerolls used to calculate cost

# Reroll cost constants (BALANCE — EXPONENTIAL PRICING)
const REROLL_BASE_COST: int = 10     # First paid reroll costs 10 coins
const REROLL_COST_MULT: float = 2.0  # Each reroll doubles in cost (10, 20, 40, 80, 160...)

# Modal de confirmación para cerrar sin elegir
var _confirm_modal: Control = null
var _confirm_modal_visible: bool = false
var _confirm_modal_selection: int = 0  # 0=Volver, 1=Perder
var _confirm_modal_buttons: Array = []  # Referencias a los botones del modal

# Cache de estilos para evitar memory leaks
var _option_styles: Array[StyleBoxFlat] = []  # Un estilo por panel de opción
var _button_styles: Array[StyleBoxFlat] = []  # Un estilo por botón

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMACIÓN DE SLOT REEL (Reveal espectacular)
# ═══════════════════════════════════════════════════════════════════════════════

var _enable_slot_animation: bool = true   # Toggle para habilitar/deshabilitar animación
var _is_animating: bool = false           # Si la animación está en progreso
var _spin_tweens: Array[Tween] = []       # Tweens de animación por panel
var _spin_icons: Array[String] = ["🔥", "⚡", "❄️", "🛡️", "⚔️", "💀", "✨", "🌟", "💎", "🎯", "🏹", "🌿"]
const SPIN_DURATION_PER_REEL: float = 0.5  # Segundos de spin por panel (reducido para fluidez)
const SPIN_STAGGER: float = 0.5            # Delay entre paradas de paneles (reducido)

# Referencias
var attack_manager: AttackManager = null
var player_stats: PlayerStats = null

# UI Nodes
var title_label: Label = null
var hint_label: Label = null
var options_container: HBoxContainer = null
var buttons_container: HBoxContainer = null

# Audio
var _slot_loop_player: AudioStreamPlayer = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_create_ui()

func initialize(attack_mgr: AttackManager, stats: PlayerStats) -> void:
	attack_manager = attack_mgr
	player_stats = stats
	_sync_counts_from_player_stats()

func _sync_counts_from_player_stats() -> void:
	"""Sincronizar reroll/banish counts con PlayerStats"""
	if player_stats:
		# SIEMPRE usar los contadores persistentes de PlayerStats
		# Esto evita que se reseteen al subir de nivel varias veces
		if "current_rerolls" in player_stats:
			reroll_count = player_stats.current_rerolls
		
		if "current_banishes" in player_stats:
			banish_count = player_stats.current_banishes
			
		# Debug
		# print("[LevelUpPanel] Sincronizado: Rerolls=%d, Banishes=%d" % [reroll_count, banish_count])

func _get_max_options() -> int:
	"""Obtener número máximo de opciones (base + mejoras)"""
	var extra = 0
	if player_stats and player_stats.has_method("get_stat"):
		extra = int(player_stats.get_stat("levelup_options"))
	return mini(BASE_OPTIONS + extra, MAX_POSSIBLE_OPTIONS)

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
	title_label.text = Localization.L("ui.level_up.title")
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", SELECTED_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# === INSTRUCCIONES ===
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = Localization.L("ui.level_up.subtitle")
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)

	# === FILA DE OPCIONES ===
	options_container = HBoxContainer.new()
	options_container.add_theme_constant_override("separation", 20)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(options_container)

	# Crear todos los paneles posibles (los extras se ocultan si no se necesitan)
	for i in range(MAX_POSSIBLE_OPTIONS):
		var panel = _create_option_panel(i)
		options_container.add_child(panel)
		option_panels.append(panel)
		# Ocultar paneles extras por defecto (se muestran según levelup_options)
		panel.visible = (i < BASE_OPTIONS)

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
	var btn_reroll = _create_action_button(0, "🎲", Localization.L("ui.level_up.reroll"), "(%d)")
	var btn_banish = _create_action_button(1, "❌", Localization.L("ui.level_up.banish"), "(%d)")
	var btn_skip = _create_action_button(2, "⏭️", Localization.L("ui.level_up.skip"), "")

	buttons_container.add_child(btn_reroll)
	buttons_container.add_child(btn_banish)
	buttons_container.add_child(btn_skip)

	button_panels.append(btn_reroll)
	button_panels.append(btn_banish)
	button_panels.append(btn_skip)

	# === AYUDA DE NAVEGACIÓN ===
	var nav_help = Label.new()
	nav_help.text = Localization.L("ui.level_up.nav_help")
	nav_help.add_theme_font_size_override("font_size", 12)
	nav_help.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	nav_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nav_help)

	# Audio Player dedicado para el loop de slots
	_slot_loop_player = AudioStreamPlayer.new()
	_slot_loop_player.name = "SlotLoopPlayer"
	_slot_loop_player.bus = "SFX" # Use SFX bus for volume control
	add_child(_slot_loop_player)

func _parse_rarity(value) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		match value.to_lower():
			"common": return 1
			"uncommon": return 2
			"rare": return 3
			"epic": return 4
			"legendary": return 5
	return 1

func _create_option_panel(index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 320)
	panel.name = "Option_%d" % index
	
	# Valores default para creación inicial (se actualizan en _update_panel_style)
	var type = "upgrade"
	var rarity = 1
	
	# Estilo inicial default (gris oscuro)
	# Los colores finales se aplican en _update_panel_style() cuando llegan las opciones
	var style = StyleBoxFlat.new()
	var default_color = Color(0.3, 0.3, 0.35)
	style.bg_color = Color(default_color.r, default_color.g, default_color.b, 0.5)
	style.border_color = default_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	
	panel.add_theme_stylebox_override("panel", style)
	_option_styles.append(style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Tipo
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = type.capitalize().replace("_", " ")
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)

	# Icono
	var icon_center = CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(90, 90)
	vbox.add_child(icon_center)

	var icon_container = Control.new()
	icon_container.name = "IconContainer"
	icon_container.custom_minimum_size = Vector2(72, 72)
	icon_center.add_child(icon_container)
	
	# Fondo del icono
	var icon_bg = Panel.new()
	icon_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.3)
	bg_style.border_color = UIVisualHelper.get_color_for_tier(rarity)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(36) # Circular
	icon_bg.add_theme_stylebox_override("panel", bg_style)
	icon_container.add_child(icon_bg)

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
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", UIVisualHelper.get_color_for_tier(rarity))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 40
	vbox.add_child(name_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 60
	vbox.add_child(desc_label)

	# Indicador de selección
	var indicator = Panel.new()
	indicator.name = "SelectionIndicator"
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ind_style = StyleBoxFlat.new()
	ind_style.bg_color = Color(0,0,0,0)
	ind_style.border_color = Color(1, 1, 1, 0.8)
	ind_style.set_border_width_all(3)
	ind_style.set_corner_radius_all(12)
	indicator.add_theme_stylebox_override("panel", ind_style)
	panel.add_child(indicator)
	indicator.visible = false
	
	# Audio: Conectar señal de hover
	if not panel.mouse_entered.is_connected(_on_element_hover):
		panel.mouse_entered.connect(_on_element_hover)

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
	
	# Audio: Conectar señal de hover
	if not panel.mouse_entered.is_connected(_on_element_hover):
		panel.mouse_entered.connect(_on_element_hover)

	return panel

func _on_element_hover() -> void:
	AudioManager.play_fixed("sfx_ui_hover")

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
				if _confirm_modal_visible:
					_navigate_confirm_modal(-1)
				else:
					_navigate_horizontal(-1)
				handled = true
			KEY_D, KEY_RIGHT:
				if _confirm_modal_visible:
					_navigate_confirm_modal(1)
				else:
					_navigate_horizontal(1)
				handled = true
			KEY_W, KEY_UP:
				if not _confirm_modal_visible:
					_navigate_vertical(-1)
					handled = true
			KEY_S, KEY_DOWN:
				if not _confirm_modal_visible:
					_navigate_vertical(1)
					handled = true
			KEY_SPACE, KEY_ENTER:
				if _confirm_modal_visible:
					_activate_confirm_modal_selection()
				else:
					_confirm_selection()
				handled = true
			KEY_ESCAPE:
				if _confirm_modal_visible:
					_on_confirm_modal_cancel()
				elif banish_mode:
					_cancel_banish_mode()
				else:
					_on_try_close()  # Mostrar modal de confirmación
				handled = true

	# === SOPORTE PARA GAMEPAD ===
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				if _confirm_modal_visible:
					_navigate_confirm_modal(-1)
				else:
					_navigate_horizontal(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT:
				if _confirm_modal_visible:
					_navigate_confirm_modal(1)
				else:
					_navigate_horizontal(1)
				handled = true
			JOY_BUTTON_DPAD_UP:
				if not _confirm_modal_visible:
					_navigate_vertical(-1)
					handled = true
			JOY_BUTTON_DPAD_DOWN:
				if not _confirm_modal_visible:
					_navigate_vertical(1)
					handled = true
			JOY_BUTTON_A:
				if _confirm_modal_visible:
					_activate_confirm_modal_selection()
				else:
					_confirm_selection()
				handled = true
			JOY_BUTTON_B:
				if _confirm_modal_visible:
					_on_confirm_modal_cancel()
				elif banish_mode:
					_cancel_banish_mode()
				else:
					_on_try_close()  # Mostrar modal de confirmación
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
	AudioManager.play_fixed("sfx_ui_hover")

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
	AudioManager.play_fixed("sfx_ui_hover")

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
	AudioManager.play_fixed("sfx_ui_confirm")
	
	# BALANCE TELEMETRY: Log upgrade pick
	if BalanceTelemetry:
		var option_ids: Array = []
		for opt in options:
			option_ids.append(opt.get("id", opt.get("name", "unknown")))
		
		var picked_type = "upgrade"
		if selected.get("type", -1) == OPTION_TYPES.NEW_WEAPON or selected.get("type", -1) == OPTION_TYPES.LEVEL_UP_WEAPON:
			picked_type = "weapon"
		elif selected.get("type", -1) == OPTION_TYPES.FUSION:
			picked_type = "fusion"
		
		BalanceTelemetry.log_upgrade_pick({
			"source": "levelup",
			"options_shown": option_ids,
			"picked_id": selected.get("id", selected.get("name", "unknown")),
			"picked_type": picked_type,
			"reroll_count": rerolls_used_this_level
		})
		BalanceTelemetry.add_level_up()
		
		# AUDIT: Report upgrade pick
		if RunAuditTracker and RunAuditTracker.ENABLE_AUDIT:
			RunAuditTracker.report_upgrade_pick({
				"picked_id": selected.get("id", selected.get("name", "unknown")),
				"picked_type": picked_type,
				"options_shown": option_ids,
				"reroll_count": rerolls_used_this_level
			})
	
	_apply_option(selected)
	option_selected.emit(selected)
	_close_panel()

func _on_reroll() -> void:
	if locked:
		return
	
	# BALANCE: Exponential reroll cost — first free rerolls are free, then 10, 20, 40, 80...
	var has_free_rerolls = reroll_count > 0
	var paid_rerolls = maxi(0, rerolls_used_this_level - (reroll_count if has_free_rerolls else 0))
	var reroll_cost: int = 0

	if not has_free_rerolls:
		# All free rerolls exhausted — exponential cost
		reroll_cost = int(REROLL_BASE_COST * pow(REROLL_COST_MULT, paid_rerolls))
		reroll_cost = maxi(reroll_cost, REROLL_BASE_COST)
		
		var exp_mgr = get_tree().get_first_node_in_group("experience_manager")
		if not exp_mgr or not "total_coins" in exp_mgr or exp_mgr.total_coins < reroll_cost:
			# No tiene rerolls ni monedas suficientes
			FloatingText.spawn_text(get_viewport().get_visible_rect().size / 2, Localization.L("ui.level_up.need_coins").replace("{cost}", str(reroll_cost)), Color.RED)
			return
		# Pagar con monedas
		exp_mgr.total_coins -= reroll_cost
		if exp_mgr.has_signal("coin_collected"):
			exp_mgr.coin_collected.emit(-reroll_cost, exp_mgr.total_coins)
	
	AudioManager.play_fixed("sfx_ui_click")
	rerolls_used_this_level += 1  # Track for next cost calculation
	
	# BALANCE TELEMETRY: Track reroll
	if BalanceTelemetry:
		BalanceTelemetry.add_reroll()

	# Consumir reroll gratuito en PlayerStats solo si tenía disponibles
	if has_free_rerolls:
		if player_stats and player_stats.has_method("consume_reroll"):
			player_stats.consume_reroll()
			reroll_count = player_stats.current_rerolls
		else:
			reroll_count -= 1
	
	# -----------------------------------------------------------
	# LÓGICA DE NUEVOS OBJETOS (Phase 3)
	# 3. Reciclaje (Recycling): XP al hacer reroll
	if player_stats and player_stats.has_method("get_stat"):
		var xp_fraction = player_stats.get_stat("xp_on_reroll")
		var exp_mgr_node = get_tree().get_first_node_in_group("experience_manager")
		if xp_fraction > 0 and exp_mgr_node:
			# Obtener xp_to_next_level desde el manager
			var needed_xp = 100 # Fallback
			if "experience_required" in exp_mgr_node:
				needed_xp = exp_mgr_node.experience_required
			
			var xp_amount = needed_xp * xp_fraction
			# Otorgar XP a través del manager o directamente
			# Mejor usar ExperienceManager si es posible, o player_stats.gain_xp
			var exp_mgr = get_tree().get_first_node_in_group("experience_manager")
			if exp_mgr and exp_mgr.has_method("gain_experience"):
				if xp_amount > 0:
					exp_mgr.gain_experience(int(xp_amount))
					# El texto flotante lo maneja gain_experience o lo añadimos aquí
					# FloatingText.spawn_text(global_position, "+%d XP" % int(xp_amount), Color.PURPLE)
	# -----------------------------------------------

	# Volver a opciones después de reroll
	current_row = Row.OPTIONS
	option_index = 0
	
	# Actualizar contador de rerolls antes de generar opciones
	_update_button_counts()
	
	# Forzar fin de animación anterior si estaba en curso
	if _is_animating:
		skip_slot_animation()
	
	# Generar nuevas opciones (esto incluye la animación de tragaperras)
	generate_options()

func _on_banish() -> void:
	if locked or banish_count <= 0 or options.size() == 0:
		return
	AudioManager.play_fixed("sfx_ui_click")

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
	
	# Consumir banish
	if player_stats and player_stats.has_method("consume_banish"):
		player_stats.consume_banish()
		banish_count = player_stats.current_banishes
	else:
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
	AudioManager.play_fixed("sfx_ui_click")

	skip_used.emit()
	_close_panel()

func _on_try_close() -> void:
	"""Intentar cerrar sin elegir - muestra modal de confirmación"""
	if locked or _confirm_modal_visible:
		return
	
	_show_confirm_modal()

func _show_confirm_modal() -> void:
	"""Mostrar modal de confirmación para perder la mejora"""
	if _confirm_modal:
		_confirm_modal.queue_free()
	
	_confirm_modal_visible = true
	_confirm_modal_selection = 0  # Empezar en "Volver a elegir"
	_confirm_modal_buttons.clear()
	
	# Fondo semitransparente del modal
	_confirm_modal = Control.new()
	_confirm_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm_modal)
	
	var modal_bg = ColorRect.new()
	modal_bg.color = Color(0, 0, 0, 0.7)
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_modal.add_child(modal_bg)
	
	# Panel central
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 160)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.18, 0.98)
	panel_style.border_color = Color(1.0, 0.4, 0.4)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Centrar panel
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_modal.add_child(center)
	center.add_child(panel)
	
	# Contenido
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# Margen interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(inner_vbox)
	
	# Icono y título
	var title_label = Label.new()
	title_label.text = "⚠️ " + Localization.L("ui.level_up.skip_confirm_title")
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(title_label)
	
	# Mensaje
	var msg_label = Label.new()
	msg_label.text = Localization.L("ui.level_up.skip_confirm_message")
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(msg_label)
	
	# Botones
	var btn_container = HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 30)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(btn_container)
	
	# Botón Cancelar (volver a elegir)
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelBtn"
	cancel_btn.text = Localization.L("ui.level_up.back_to_choose")
	cancel_btn.custom_minimum_size = Vector2(150, 45)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.pressed.connect(_on_confirm_modal_cancel)
	cancel_btn.mouse_entered.connect(_on_element_hover)
	btn_container.add_child(cancel_btn)
	_confirm_modal_buttons.append(cancel_btn)
	
	# Botón Confirmar (perder mejora)
	var confirm_btn = Button.new()
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.text = Localization.L("ui.level_up.lose_upgrade")
	confirm_btn.custom_minimum_size = Vector2(150, 45)
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.focus_mode = Control.FOCUS_NONE
	confirm_btn.pressed.connect(_on_confirm_modal_confirm)
	confirm_btn.mouse_entered.connect(_on_element_hover)
	btn_container.add_child(confirm_btn)
	_confirm_modal_buttons.append(confirm_btn)
	
	# Actualizar visual inicial
	_update_confirm_modal_visuals()

func _on_confirm_modal_cancel() -> void:
	"""Cerrar modal y volver a elegir"""
	AudioManager.play_fixed("sfx_ui_back")
	_hide_confirm_modal()

func _on_confirm_modal_confirm() -> void:
	"""Confirmar pérdida de mejora y cerrar panel"""
	AudioManager.play_fixed("sfx_ui_confirm")
	_hide_confirm_modal()
	_close_panel()

func _hide_confirm_modal() -> void:
	"""Ocultar y destruir el modal"""
	if _confirm_modal:
		_confirm_modal.queue_free()
		_confirm_modal = null
	_confirm_modal_visible = false
	_confirm_modal_buttons.clear()

func _navigate_confirm_modal(direction: int) -> void:
	"""Navegar entre botones del modal"""
	_confirm_modal_selection = (_confirm_modal_selection + direction) % _confirm_modal_buttons.size()
	if _confirm_modal_selection < 0:
		_confirm_modal_selection = _confirm_modal_buttons.size() - 1
	_update_confirm_modal_visuals()
	AudioManager.play_fixed("sfx_ui_hover")

func _activate_confirm_modal_selection() -> void:
	"""Activar el botón seleccionado del modal"""
	match _confirm_modal_selection:
		0: _on_confirm_modal_cancel()
		1: _on_confirm_modal_confirm()

func _update_confirm_modal_visuals() -> void:
	"""Actualizar estilos visuales de los botones del modal"""
	for i in range(_confirm_modal_buttons.size()):
		var btn = _confirm_modal_buttons[i] as Button
		if not btn:
			continue
		
		var is_selected = (i == _confirm_modal_selection)
		var style = StyleBoxFlat.new()
		var hover_style = StyleBoxFlat.new()
		
		if i == 0:  # Botón "Volver a elegir" (verde)
			if is_selected:
				style.bg_color = Color(0.25, 0.6, 0.35)
				style.border_color = Color(0.4, 1.0, 0.5)
				style.set_border_width_all(3)
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			else:
				style.bg_color = Color(0.15, 0.35, 0.2)
				style.border_color = Color(0.2, 0.4, 0.25)
				style.set_border_width_all(1)
				btn.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
			hover_style.bg_color = Color(0.3, 0.65, 0.4)
		else:  # Botón "Perder mejora" (rojo)
			if is_selected:
				style.bg_color = Color(0.7, 0.25, 0.25)
				style.border_color = Color(1.0, 0.5, 0.5)
				style.set_border_width_all(3)
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			else:
				style.bg_color = Color(0.4, 0.15, 0.15)
				style.border_color = Color(0.5, 0.2, 0.2)
				style.set_border_width_all(1)
				btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.6))
			hover_style.bg_color = Color(0.75, 0.3, 0.3)
		
		style.set_corner_radius_all(8)
		hover_style.set_corner_radius_all(8)
		hover_style.border_color = style.border_color
		hover_style.set_border_width_all(style.border_width_left)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover_style)

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
			hint_label.text = "❌ " + Localization.L("ui.level_up.banish_mode_hint")
			hint_label.add_theme_color_override("font_color", BANISH_COLOR)
		else:
			hint_label.text = Localization.L("ui.level_up.choose_upgrade")
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

		var indicator = panel.get_node_or_null("SelectionIndicator")
		if indicator:
			indicator.visible = is_selected

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
		0:  # Reroll: habilitado si tiene rerolls gratuitos O monedas suficientes
			if reroll_count > 0:
				return false
			# Sin rerolls gratuitos: verificar si puede pagar con monedas (exponencial)
			var paid_so_far = maxi(0, rerolls_used_this_level)
			var next_cost = int(REROLL_BASE_COST * pow(REROLL_COST_MULT, paid_so_far))
			var exp_mgr = get_tree().get_first_node_in_group("experience_manager")
			if exp_mgr and "total_coins" in exp_mgr and exp_mgr.total_coins >= next_cost:
				return false
			return true
		1: return banish_count <= 0 or options.size() == 0  # Eliminar
		_: return false  # Saltar siempre disponible

func _update_button_counts() -> void:
	# Actualizar contador de Reroll (with cost if applicable)
	var reroll_count_label = button_panels[0].find_child("Count", true, false) as Label
	if reroll_count_label:
		var paid_so_far = maxi(0, rerolls_used_this_level)
		var next_cost = int(REROLL_BASE_COST * pow(REROLL_COST_MULT, paid_so_far))
		if reroll_count <= 0:
			# Sin rerolls gratuitos: mostrar solo costo en monedas (exponencial)
			reroll_count_label.text = "🪙%d" % next_cost
		else:
			reroll_count_label.text = "(%d)" % reroll_count

	# Actualizar contador de Banish
	var banish_count_label = button_panels[1].find_child("Count", true, false) as Label
	if banish_count_label:
		banish_count_label.text = "(%d)" % banish_count

func _update_options_ui() -> void:
	var max_opts = _get_max_options()
	for i in range(option_panels.size()):
		var panel = option_panels[i]

		if i < options.size() and i < max_opts:
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

	# ═══════════════════════════════════════════════════════════════════════════
	# ACTUALIZAR ESTILO DEL PANEL (Colores por tier/tipo)
	# ═══════════════════════════════════════════════════════════════════════════
	_update_panel_style(panel, option)

	# Tipo - con color especial para fusiones
	var option_type = option.get("type", "")
	if type_label:
		type_label.text = _get_type_text(option_type)
		# Fusiones: Ocultar el label de tipo porque ya tenemos el badge épico
		if option_type == OPTION_TYPES.FUSION:
			type_label.visible = false
		else:
			type_label.visible = true
			type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

	# Icono
	var icon_value = option.get("icon", "✨")
	var icon_str = str(icon_value).strip_edges()
	var is_image_path = icon_str.begins_with("res://") or icon_str.ends_with(".png")

	if icon_label and icon_texture:
		if is_image_path:
			icon_label.visible = false
			icon_texture.visible = true
			
			if ResourceLoader.exists(icon_str):
				var texture = load(icon_str)
				if texture:
					icon_texture.texture = texture
				else:
					_set_fallback_icon(icon_label, icon_texture)
			else:
				_set_fallback_icon(icon_label, icon_texture)
		else:
			icon_label.visible = true
			icon_texture.visible = false
			icon_label.text = icon_str
	
	# Actualizar estilo del fondo del icono
	var icon_container = panel.find_child("IconContainer", true, false)
	if icon_container:
		var icon_bg = icon_container.get_node_or_null("Panel")
		if not icon_bg:
			# Buscar el primer Panel hijo
			for child in icon_container.get_children():
				if child is Panel:
					icon_bg = child
					break
		
		if icon_bg:
			var bg_style = StyleBoxFlat.new()
			bg_style.set_corner_radius_all(36)  # Circular
			
			if option_type == OPTION_TYPES.FUSION:
				# Estilo épico para fusiones
				bg_style.bg_color = Color(0.2, 0.1, 0.0, 0.8)
				bg_style.border_color = Color(1.0, 0.7, 0.2)  # Dorado
				bg_style.set_border_width_all(3)
				bg_style.shadow_color = Color(1.0, 0.5, 0.1, 0.6)
				bg_style.shadow_size = 6
			else:
				# Estilo normal
				bg_style.bg_color = Color(0, 0, 0, 0.3)
				var tier_color = _get_option_color(option)
				bg_style.border_color = tier_color
				bg_style.set_border_width_all(2)
			
			icon_bg.add_theme_stylebox_override("panel", bg_style)

	# Nombre con color basado en TIER y tipo especial
	if name_label:
		# Para fusiones, ocultar el name_label porque el badge épico ya muestra el nombre
		if option_type == OPTION_TYPES.FUSION:
			name_label.visible = false
		else:
			name_label.visible = true
			name_label.text = option.get("name", "???")
			var name_color = _get_option_color(option)
			name_label.add_theme_color_override("font_color", name_color)

	# Descripción
	if desc_label:
		desc_label.text = option.get("description", "")

func _update_panel_style(panel: Control, option: Dictionary) -> void:
	"""Actualiza el estilo visual del panel basándose en tier y tipo."""
	var option_type = option.get("type", "")
	var is_fusion = (option_type == OPTION_TYPES.FUSION)
	var is_weapon = (option_type == OPTION_TYPES.NEW_WEAPON or 
					 option_type == OPTION_TYPES.LEVEL_UP_WEAPON)
	
	# Determinar el color a usar
	var panel_color: Color
	var glow_color: Color = Color.TRANSPARENT
	
	if is_fusion:
		# ═══════════════════════════════════════════════════════════════════════
		# 🔥 FUSIÓN: ESTILO ÉPICO ESPECTACULAR 🔥
		# ═══════════════════════════════════════════════════════════════════════
		panel_color = FUSION_COLOR
		glow_color = FUSION_GLOW_COLOR
		_apply_fusion_epic_style(panel, option)
		return  # El estilo épico se maneja completamente en la función dedicada
	elif is_weapon:
		# Armas normales: Color naranja
		panel_color = WEAPON_COLOR
	elif option.get("is_cursed", false):
		# Mejoras cursed: Púrpura
		panel_color = CURSED_COLOR
	elif option.get("is_unique", false):
		# Mejoras únicas: Rojo
		panel_color = UNIQUE_COLOR
	else:
		# Por tier: Usar rarity o tier de la opción
		var raw_tier = option.get("rarity", option.get("tier", 1))
		var tier = _parse_rarity(raw_tier)
		panel_color = UIVisualHelper.get_color_for_tier(tier)
	
	# Crear nuevo estilo
	var style = StyleBoxFlat.new()
	
	# Fondo: Color del panel con transparencia
	style.bg_color = Color(panel_color.r, panel_color.g, panel_color.b, 0.5)
	
	# Borde: Color sólido
	style.border_color = panel_color
	style.set_corner_radius_all(8)
	
	if is_weapon:
		# Armas: Más intenso
		style.bg_color.a = 0.6
		style.set_border_width_all(4)
	else:
		style.set_border_width_all(2)
	
	panel.add_theme_stylebox_override("panel", style)
	
	# Limpiar efectos de fusión si existían
	_cleanup_fusion_effects(panel)

func _apply_fusion_epic_style(panel: Control, option: Dictionary) -> void:
	"""Aplicar estilo épico espectacular para tarjetas de FUSIÓN."""
	# Limpiar efectos anteriores
	_cleanup_fusion_effects(panel)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# ASEGURAR QUE EL CONTENIDO (VBoxContainer) ESTÉ VISIBLE POR ENCIMA
	# ═══════════════════════════════════════════════════════════════════════════
	var content_vbox: VBoxContainer = null
	for child in panel.get_children():
		if child is VBoxContainer:
			content_vbox = child
			child.z_index = 5  # Por encima del glow_panel (-1), debajo de decoraciones (10)
			# IMPORTANTE: Asegurar que todos los hijos del VBoxContainer sean visibles
			for vbox_child in child.get_children():
				if vbox_child is Control:
					vbox_child.z_index = 5
					vbox_child.show_behind_parent = false
			break
	
	# ═══════════════════════════════════════════════════════════════════════════
	# COLORES ÉPICOS DE FUSIÓN - Gradiente de fuego dorado a naranja intenso
	# ═══════════════════════════════════════════════════════════════════════════
	var primary_color = Color(1.0, 0.6, 0.1)      # Naranja dorado intenso
	var secondary_color = Color(1.0, 0.35, 0.0)   # Naranja fuego
	var glow_color = Color(1.0, 0.85, 0.3)        # Dorado brillante
	var inner_glow = Color(1.0, 0.95, 0.6)        # Amarillo casi blanco
	
	# ═══════════════════════════════════════════════════════════════════════════
	# ESTILO PRINCIPAL DEL PANEL
	# ═══════════════════════════════════════════════════════════════════════════
	var style = StyleBoxFlat.new()
	
	# Fondo: Gradiente simulado con color intenso
	style.bg_color = Color(0.15, 0.08, 0.02, 0.95)  # Fondo oscuro cálido
	
	# Borde grueso dorado brillante
	style.border_color = glow_color
	style.set_border_width_all(5)
	style.set_corner_radius_all(12)
	
	# Shadow/Glow exterior
	style.shadow_color = Color(primary_color.r, primary_color.g, primary_color.b, 0.8)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 0)  # Glow centrado (no sombra direccional)
	
	panel.add_theme_stylebox_override("panel", style)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# CAPA DE GLOW INTERIOR (Panel superpuesto) - z_index bajo para no cubrir contenido
	# ═══════════════════════════════════════════════════════════════════════════
	var glow_panel = Panel.new()
	glow_panel.name = "FusionGlowPanel"
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_panel.z_index = -1  # DETRÁS del contenido
	glow_panel.show_behind_parent = true
	glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_panel.offset_left = 3
	glow_panel.offset_top = 3
	glow_panel.offset_right = -3
	glow_panel.offset_bottom = -3
	
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color(0, 0, 0, 0)  # Transparente
	inner_style.border_color = inner_glow
	inner_style.set_border_width_all(2)
	inner_style.set_corner_radius_all(10)
	glow_panel.add_theme_stylebox_override("panel", inner_style)
	panel.add_child(glow_panel)
	panel.move_child(glow_panel, 0)  # Mover al fondo para que esté DETRÁS del VBoxContainer
	
	# IMPORTANTE: Mover el VBoxContainer al final para asegurar que se dibuje encima
	if content_vbox:
		panel.move_child(content_vbox, -1)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# PARTÍCULAS/ESTRELLAS DECORATIVAS (Esquinas) - z_index alto para estar encima del borde
	# ═══════════════════════════════════════════════════════════════════════════
	var corners_container = Control.new()
	corners_container.name = "FusionCornersContainer"
	corners_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corners_container.z_index = 10  # Encima del contenido (solo decoración pequeña)
	corners_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(corners_container)
	
	# Agregar iconos de fuego/estrella en las esquinas
	var corner_icons = ["🔥", "✨", "🔥", "✨"]
	var corner_positions = [
		Vector2(8, 8),      # Top-left
		Vector2(-24, 8),    # Top-right (offset negativo para ancla derecha)
		Vector2(8, -24),    # Bottom-left
		Vector2(-24, -24)   # Bottom-right
	]
	var corner_anchors = [
		[0.0, 0.0],  # Top-left
		[1.0, 0.0],  # Top-right
		[0.0, 1.0],  # Bottom-left
		[1.0, 1.0]   # Bottom-right
	]
	
	for i in range(4):
		var star = Label.new()
		star.text = corner_icons[i]
		star.add_theme_font_size_override("font_size", 16)
		star.anchor_left = corner_anchors[i][0]
		star.anchor_top = corner_anchors[i][1]
		star.anchor_right = corner_anchors[i][0]
		star.anchor_bottom = corner_anchors[i][1]
		star.offset_left = corner_positions[i].x
		star.offset_top = corner_positions[i].y
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		corners_container.add_child(star)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# BADGE CON NOMBRE DE LA FUSIÓN EN LA PARTE SUPERIOR
	# ═══════════════════════════════════════════════════════════════════════════
	var fusion_name = option.get("name", "FUSIÓN")
	# Limpiar el emoji de fuego si ya está en el nombre para evitar duplicación
	if fusion_name.begins_with("🔥 "):
		fusion_name = fusion_name.substr(3)
	
	var badge = PanelContainer.new()
	badge.name = "FusionBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 10  # Encima del contenido
	badge.anchor_left = 0.5
	badge.anchor_right = 0.5
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = -90  # Más ancho para nombres largos
	badge.offset_right = 90
	badge.offset_top = -14
	badge.offset_bottom = 10
	
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.9, 0.4, 0.0, 1.0)  # Naranja sólido
	badge_style.border_color = glow_color
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(4)
	badge_style.shadow_color = Color(0, 0, 0, 0.5)
	badge_style.shadow_size = 4
	badge.add_theme_stylebox_override("panel", badge_style)
	
	var badge_label = Label.new()
	badge_label.text = "🔥 " + fusion_name + " 🔥"
	badge_label.add_theme_font_size_override("font_size", 12)
	badge_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_label)
	panel.add_child(badge)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# ANIMACIÓN DE PULSO BRILLANTE
	# ═══════════════════════════════════════════════════════════════════════════
	_start_fusion_pulse_animation(panel, glow_panel, style, inner_style)

func _start_fusion_pulse_animation(panel: Control, glow_panel: Panel, main_style: StyleBoxFlat, inner_style: StyleBoxFlat) -> void:
	"""Iniciar animación de pulso brillante para la tarjeta de fusión."""
	# Crear un tween de pulso que se repite
	var tween = create_tween()
	tween.set_loops()  # Loop infinito
	
	# Guardar referencia al tween para poder cancelarlo
	panel.set_meta("fusion_tween", tween)
	
	# Colores para el pulso
	var bright_border = Color(1.0, 0.95, 0.6)  # Dorado brillante
	var normal_border = Color(1.0, 0.7, 0.2)   # Dorado normal
	var bright_shadow = Color(1.0, 0.6, 0.1, 1.0)
	var dim_shadow = Color(1.0, 0.6, 0.1, 0.5)
	
	# Secuencia de pulso
	tween.tween_method(
		func(t: float):
			if not is_instance_valid(panel) or not is_instance_valid(glow_panel):
				return
			# Interpolar colores
			var border_color = bright_border.lerp(normal_border, t)
			var shadow_alpha = lerpf(1.0, 0.4, t)
			var shadow_size = lerpf(16, 8, t)
			
			main_style.border_color = border_color
			main_style.shadow_color.a = shadow_alpha
			main_style.shadow_size = int(shadow_size)
			
			# También pulsar el borde interior
			inner_style.border_color = bright_border.lerp(Color(1.0, 0.85, 0.4), t)
	, 0.0, 1.0, 0.8  # De 0 a 1 en 0.8 segundos
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_method(
		func(t: float):
			if not is_instance_valid(panel) or not is_instance_valid(glow_panel):
				return
			var border_color = normal_border.lerp(bright_border, t)
			var shadow_alpha = lerpf(0.4, 1.0, t)
			var shadow_size = lerpf(8, 16, t)
			
			main_style.border_color = border_color
			main_style.shadow_color.a = shadow_alpha
			main_style.shadow_size = int(shadow_size)
			
			inner_style.border_color = Color(1.0, 0.85, 0.4).lerp(bright_border, t)
	, 0.0, 1.0, 0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _cleanup_fusion_effects(panel: Control) -> void:
	"""Limpiar todos los efectos visuales de fusión de un panel."""
	# Cancelar tween de animación si existe
	if panel.has_meta("fusion_tween"):
		var tween = panel.get_meta("fusion_tween")
		if tween and tween is Tween and tween.is_valid():
			tween.kill()
		panel.remove_meta("fusion_tween")
	
	# Eliminar nodos de efectos
	var glow_panel = panel.get_node_or_null("FusionGlowPanel")
	if glow_panel:
		glow_panel.queue_free()
	
	var corners = panel.get_node_or_null("FusionCornersContainer")
	if corners:
		corners.queue_free()
	
	var badge = panel.get_node_or_null("FusionBadge")
	if badge:
		badge.queue_free()

func _set_fallback_icon(label: Label, texture: TextureRect) -> void:
	"""Muestra un icono de fallback cuando falla la carga de imagen"""
	label.visible = true
	texture.visible = false
	label.text = "❓" # Placeholder
	label.add_theme_color_override("font_color", Color(1, 0, 1))

func _get_option_color(option: Dictionary) -> Color:
	"""Determina el color del nombre basado en tier, tipo especial, etc."""
	var option_type = option.get("type", "")
	
	# Fusiones: Color dorado brillante épico
	if option_type == OPTION_TYPES.FUSION:
		return Color(1.0, 0.85, 0.3)  # Dorado brillante para fusiones
	
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
	
	return UIVisualHelper.get_color_for_tier(tier)

func _get_type_text(option_type: String) -> String:
	match option_type:
		OPTION_TYPES.NEW_WEAPON: return Localization.L("option_types.new_weapon")
		OPTION_TYPES.LEVEL_UP_WEAPON: return Localization.L("option_types.level_up_weapon")
		OPTION_TYPES.FUSION: return Localization.L("option_types.fusion")
		OPTION_TYPES.PLAYER_UPGRADE: return Localization.L("option_types.player_upgrade")
		_: return Localization.L("option_types.player_upgrade")

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMACIÓN DE SLOT REEL
# ═══════════════════════════════════════════════════════════════════════════════

func _play_slot_reel_animation() -> void:
	"""Reproducir animación de carretes girando antes de mostrar opciones"""
	if _is_animating or options.size() == 0:
		_update_options_ui()
		_update_all_visuals()
		_update_button_counts()
		return
	
	_is_animating = true
	locked = true  # Bloquear input durante animación
	
	# Cancelar tweens anteriores
	for tween in _spin_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_spin_tweens.clear()
	
	var max_opts = _get_max_options()
	var visible_count = mini(options.size(), max_opts)
	
	# Resetear escala de todos los paneles (por si hay tweens de bounce residuales)
	for panel in option_panels:
		panel.scale = Vector2.ONE
	
	# Mostrar todos los paneles con icono spinning
	for i in range(option_panels.size()):
		var panel = option_panels[i]
		if i < visible_count:
			panel.visible = true
			_start_panel_spin(panel, i)
		else:
			panel.visible = false
	
	# INICIO SONIDO LOOP
	if _slot_loop_player:
		# Cargar resource directamente (o buscar en AudioManager si tuviera API para obtener path/stream)
		# Asumimos path conocido por audio_manifest.json
		var stream = load("res://audio/sfx/ui/sfx_slot_spin_loop.mp3")
		if stream:
			_slot_loop_player.stream = stream
			_slot_loop_player.pitch_scale = 1.0
			# Ajuste de volumen: Reducido drásticamente (-12dB) por feedback de usuario
			_slot_loop_player.volume_db = -12.0
			_slot_loop_player.bus = "SFX" # Ensure SFX bus
			_slot_loop_player.play()
	
	# Esperar tiempo base de spin
	await get_tree().create_timer(SPIN_DURATION_PER_REEL).timeout
	if not is_instance_valid(self):
		return
	
	# Revelar reels secuencialmente (sin await en cada uno para ser más rápido)
	for i in range(visible_count):
		if not is_instance_valid(self):
			return
		# Iniciar reveal del panel (no bloquea)
		_stop_panel_spin_fast(i, options[i])
		
		# SONIDO STOP (Golpe seco al parar cada uno)
		AudioManager.play_fixed("sfx_slot_stop")
		
		# Pequeño delay entre reveals
		if i < visible_count - 1:
			await get_tree().create_timer(SPIN_STAGGER).timeout
	
	# DETENER SONIDO LOOP
	if _slot_loop_player:
		_slot_loop_player.stop()
	
	# DESBLOQUEAR INMEDIATAMENTE después del último reveal
	# Las animaciones de bounce continúan en segundo plano
	_is_animating = false
	locked = false
	_update_all_visuals()
	_update_button_counts()

func _stop_panel_spin_fast(index: int, option: Dictionary) -> void:
	"""Detener spin y mostrar opción real (versión rápida sin await)"""
	if index >= option_panels.size():
		return
	
	var panel = option_panels[index]
	
	# Cancelar tween de spin si existe
	if index < _spin_tweens.size() and _spin_tweens[index]:
		_spin_tweens[index].kill()
	
	# Actualizar con opción real
	_update_option_panel(panel, option)
	
	# Restaurar alpha
	var name_label = panel.find_child("NameLabel", true, false) as Label
	var desc_label = panel.find_child("DescLabel", true, false) as Label
	if name_label:
		name_label.modulate.a = 1.0
	if desc_label:
		desc_label.modulate.a = 1.0
	
	# Animación de bounce (no bloqueante)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.1)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.08)

func _start_panel_spin(panel: Control, _index: int) -> void:
	"""Iniciar efecto de spin en un panel"""
	var icon_label = panel.find_child("IconLabel", true, false) as Label
	var name_label = panel.find_child("NameLabel", true, false) as Label
	var desc_label = panel.find_child("DescLabel", true, false) as Label
	var type_label = panel.find_child("TypeLabel", true, false) as Label
	
	if name_label:
		name_label.text = "???"
		name_label.modulate.a = 0.5
	if desc_label:
		desc_label.text = Localization.L("ui.level_up.spinning")
		desc_label.modulate.a = 0.3
	if type_label:
		type_label.text = "🎰"
	
	# Crear tween para ciclar iconos
	if icon_label:
		var tween = create_tween()
		tween.set_loops()
		
		for j in range(_spin_icons.size()):
			var icon = _spin_icons[j]
			tween.tween_callback(func(): 
				if is_instance_valid(icon_label):
					icon_label.text = icon
			)
			tween.tween_interval(0.05)
		
		_spin_tweens.append(tween)
	
	# Escala inicial pequeña
	panel.scale = Vector2(0.95, 0.95)

func _stop_panel_spin(index: int, option: Dictionary) -> void:
	"""Detener spin y mostrar opción real con bounce"""
	if index >= option_panels.size():
		return
	
	var panel = option_panels[index]
	
	# Cancelar tween de spin si existe
	if index < _spin_tweens.size() and _spin_tweens[index]:
		_spin_tweens[index].kill()
	
	# Actualizar con opción real
	_update_option_panel(panel, option)
	
	# Restaurar alpha
	var name_label = panel.find_child("NameLabel", true, false) as Label
	var desc_label = panel.find_child("DescLabel", true, false) as Label
	if name_label:
		name_label.modulate.a = 1.0
	if desc_label:
		desc_label.modulate.a = 1.0
	
	# Animación de bounce
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.15)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
	
	await tween.finished

func skip_slot_animation() -> void:
	"""Saltar la animación y mostrar opciones inmediatamente"""
	if not _is_animating:
		return
	
	# Cancelar todos los tweens
	for tween in _spin_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_spin_tweens.clear()
	
	# Detener sonido
	if _slot_loop_player:
		_slot_loop_player.stop()
	
	# Mostrar opciones finales
	_is_animating = false
	locked = false
	_update_options_ui()
	_update_all_visuals()
	_update_button_counts()

# ═══════════════════════════════════════════════════════════════════════════════
# GENERACIÓN DE OPCIONES
# ═══════════════════════════════════════════════════════════════════════════════

func generate_options() -> void:
	options.clear()
	
	# NOTA: NO sincronizar aquí - Game.gd gestiona los contadores
	# y los incrementa cuando se obtienen mejoras de reroll/banish

	var luck = 0.0
	if player_stats and player_stats.has_method("get_stat"):
		var luck_stat = player_stats.get_stat("luck")
		if luck_stat != null:
			luck = float(luck_stat)

	var possible_options: Array = []

	# 1. Nuevas armas
	if attack_manager and attack_manager.has_method("has_available_slot"):
		if attack_manager.has_available_slot:
			possible_options.append_array(_get_new_weapon_options())

	# 2. Subir nivel de armas (con probabilidad basada en tiempo y suerte)
	# Para evitar que SIEMPRE aparezca una mejora de arma
	if attack_manager and attack_manager.has_method("get_weapons"):
		var weapon_upgrade_chance = _calculate_weapon_upgrade_chance(luck)
		if randf() < weapon_upgrade_chance:
			possible_options.append_array(_get_weapon_level_up_options())

	# 3. BALANCE PASS 2: Fusiones ELIMINADAS del LevelUpPanel
	# Las fusiones ahora solo aparecen en cofres de elites (baja prob) y bosses (alta prob)
	# Ver LootManager._generate_boss_loot() y _generate_elite_loot()

	# 4. Upgrades del jugador
	possible_options.append_array(_get_player_upgrade_options(luck))

	# Fallback
	if possible_options.size() < 2:
		possible_options = _get_fallback_options()

	possible_options.shuffle()
	options = _balance_options(possible_options)
	option_index = 0

	# Usar animación de slot reel si está habilitada
	if _enable_slot_animation and options.size() > 0:
		_play_slot_reel_animation()
	else:
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
	
	# Obtener tags de armas para filtrado
	var common_tags = []
	var all_tags = []
	
	if attack_manager and attack_manager.has_method("get_weapon_tags"):
		var tags = attack_manager.get_weapon_tags()
		common_tags = tags.get("common", [])
		all_tags = tags.get("all", [])
	
	var player_upgrades = UpgradeDatabase.get_random_player_upgrades(4, [], luck, game_time_minutes, owned_unique_ids, common_tags, all_tags)
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
	
	# 3. FILTRADO: Eliminar attack_speed si solo usa orbitales (no se benefician)
	if _are_all_weapons_orbital():
		var filtered = []
		for opt in upgrade_options:
			var keep = true
			for eff in opt.get("effects", []):
				if eff.get("stat") == "attack_speed_mult":
					keep = false
					break
			if keep:
				filtered.append(opt)
		upgrade_options = filtered

	# 4. FILTRADO POR CAPS: Eliminar mejoras si TODOS los stats están al máximo
	# Solo filtramos si la mejora NO tiene ningún efecto útil
	var unmaxed_options = []
	for opt in upgrade_options:
		var has_useful_effect = false
		var effects = opt.get("effects", [])
		
		# Si no tiene efectos (raro) o es otro tipo, la dejamos
		if effects.is_empty():
			has_useful_effect = true
			
		for eff in effects:
			var stat = eff.get("stat", "")
			if stat == "":
				continue
			
			# Verificar en PlayerStats primero
			var is_capped = false
			if player_stats and player_stats.has_method("is_stat_capped"):
				is_capped = player_stats.is_stat_capped(stat)
			
			# Si no está en PlayerStats, verificar en GlobalWeaponStats
			if not is_capped and attack_manager:
				var gws = attack_manager.get("global_weapon_stats")
				if gws and gws.has_method("is_stat_capped"):
					is_capped = gws.is_stat_capped(stat)
			
			# Si encontramos al menos un stat NO capeado, la opción sirve
			if not is_capped:
				has_useful_effect = true
				break
		
		if has_useful_effect:
			unmaxed_options.append(opt)
	
	upgrade_options = unmaxed_options

	return upgrade_options

func _get_owned_unique_upgrade_ids() -> Array:
	"""Obtiene IDs de mejoras únicas que el jugador ya posee"""
	if player_stats and player_stats.has_method("get_owned_unique_ids"):
		return player_stats.get_owned_unique_ids()
	return []

func _is_weapon_upgrade(passive: Dictionary) -> bool:
	"""Determina si una mejora es de armas (para filtrarla de PassiveDatabase)"""
	# SINCRONIZADO con PlayerStats.WEAPON_STATS
	var weapon_stats = [
		"damage_mult", "damage_flat", "attack_speed_mult", "cooldown_mult",
		"area_mult", "projectile_speed_mult", "duration_mult", "extra_projectiles",
		"extra_pierce", "knockback_mult", "range_mult", "crit_chance", "crit_damage",
		"chain_count", "life_steal"
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

func _calculate_weapon_upgrade_chance(luck: float) -> float:
	"""
	Calcula la probabilidad de que aparezcan mejoras de nivel de arma.
	
	SISTEMA DE BALANCEO:
	- Base: 40% de probabilidad de que aparezcan mejoras de arma
	- Tiempo de juego: +5% por cada 5 minutos (hasta +15% en 15 min)
	- Suerte: +10% por cada punto de suerte (máx +20%)
	- Después de minuto 10: las armas son más valiosas, +10% adicional
	- Máximo: 75% (siempre hay posibilidad de NO ver mejoras de arma)
	
	Esto balancea el juego para que el jugador vea más variedad de mejoras.
	"""
	var base_chance = 0.40  # 40% base
	
	# Bonus por tiempo de juego
	var time_minutes = _get_game_time_minutes()
	var time_bonus = minf(time_minutes / 5.0 * 0.05, 0.15)  # +5% por cada 5 min, máx +15%
	
	# Bonus extra después del minuto 10 (las armas de alto nivel son valiosas)
	var late_game_bonus = 0.10 if time_minutes >= 10.0 else 0.0
	
	# Bonus por suerte (máximo +20%)
	var luck_bonus = minf(luck * 0.10, 0.20)
	
	var total_chance = base_chance + time_bonus + late_game_bonus + luck_bonus
	return minf(total_chance, 0.75)  # Máximo 75%

func _get_fallback_options() -> Array:
	"""Opciones de respaldo si no hay suficientes mejoras disponibles"""
	var fallback = [
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "damage_boost",
			"name": Localization.L("fallback_upgrades.damage_boost.name"),
			"description": Localization.L("fallback_upgrades.damage_boost.desc"),
			"icon": "⚡",
			"rarity": "common",
			"category": "weapon_global",  # Va a GlobalWeaponStats
			"effects": [{"stat": "damage_mult", "value": 1.10, "operation": "multiply"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "attack_speed_boost",
			"name": Localization.L("fallback_upgrades.attack_speed_boost.name"),
			"description": Localization.L("fallback_upgrades.attack_speed_boost.desc"),
			"icon": "⚡",
			"rarity": "common",
			"category": "weapon_global",  # Va a GlobalWeaponStats
			"effects": [{"stat": "attack_speed_mult", "value": 1.10, "operation": "multiply"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "speed_boost",
			"name": Localization.L("fallback_upgrades.speed_boost.name"),
			"description": Localization.L("fallback_upgrades.speed_boost.desc"),
			"icon": "💨",
			"rarity": "common",
			"category": "player",  # Va a PlayerStats
			"effects": [{"stat": "move_speed", "value": 0.10, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "health_boost",
			"name": Localization.L("fallback_upgrades.health_boost.name"),
			"description": Localization.L("fallback_upgrades.health_boost.desc"),
			"icon": "❤️",
			"rarity": "common",
			"category": "player",  # Va a PlayerStats
			"effects": [{"stat": "max_health", "value": 20, "operation": "add"}],
			"priority": 0.8
		}
	]
	
	if _are_all_weapons_orbital():
		var filtered = []
		for opt in fallback:
			if opt.upgrade_id != "attack_speed_boost":
				filtered.append(opt)
		return filtered
		
	return fallback

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

		# Try to get weapon name in current language first
		var lang = Localization.get_current_language()
		var weapon_name = weapon.get("weapon_name_" + lang) if ("weapon_name_" + lang) in weapon else (weapon.weapon_name_es if "weapon_name_es" in weapon else weapon.get("name", "???"))
		var weapon_level = weapon.level if "level" in weapon else 1
		var weapon_icon = weapon.icon if "icon" in weapon else "⚔️"
		var next_desc = ""
		if weapon.has_method("get_next_upgrade_description"):
			next_desc = weapon.get_next_upgrade_description()

		level_options.append({
			"type": OPTION_TYPES.LEVEL_UP_WEAPON,
			"weapon_id": weapon.id if "id" in weapon else "",
			"weapon": weapon,
			"name": Localization.L("weapon_level_format", [weapon_name, weapon_level, weapon_level + 1]),
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
		var fusion_name = preview.get("name_" + Localization.get_current_language(), preview.get("name_es", preview.get("name", "???")))
		var lang_key = "weapon_name_" + Localization.get_current_language()
		var weapon_a_name = fusion.weapon_a.get(lang_key) if lang_key in fusion.weapon_a else fusion.weapon_a.weapon_name_es
		var weapon_b_name = fusion.weapon_b.get(lang_key) if lang_key in fusion.weapon_b else fusion.weapon_b.weapon_name_es

		fusion_options.append({
			"type": OPTION_TYPES.FUSION,
			"weapon_a": fusion.weapon_a,
			"weapon_b": fusion.weapon_b,
			"result": fusion.result,
			"name": fusion_name,  # Nombre limpio para el badge
			"description": "%s + %s → ⚠️ -1 slot" % [weapon_a_name, weapon_b_name],
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
	var _auditor = get_node_or_null("/root/UpgradeAuditor")
	match option.type:
		OPTION_TYPES.NEW_WEAPON:
			if attack_manager and attack_manager.has_method("add_weapon_by_id"):
				attack_manager.add_weapon_by_id(option.weapon_id)
				# Audit: verificar que el arma se registró
				if _auditor and _auditor.has_method("audit_weapon_pickup"):
					_auditor.call_deferred("audit_weapon_pickup", {"id": option.weapon_id, "name": option.get("name", option.weapon_id)}, "new_weapon")

		OPTION_TYPES.LEVEL_UP_WEAPON:
			if attack_manager and attack_manager.has_method("level_up_weapon_by_id"):
				attack_manager.level_up_weapon_by_id(option.weapon_id)
				# Audit: verificar level up
				if _auditor and _auditor.has_method("audit_weapon_pickup"):
					_auditor.call_deferred("audit_weapon_pickup", {"id": option.weapon_id, "name": option.get("name", option.weapon_id)}, "level_up")

		OPTION_TYPES.FUSION:
			if attack_manager and attack_manager.has_method("fuse_weapons"):
				attack_manager.fuse_weapons(option.weapon_a, option.weapon_b)
				# Audit: verificar fusión
				if _auditor and _auditor.has_method("audit_weapon_pickup"):
					_auditor.call_deferred("audit_weapon_pickup", {
						"id": option.get("fusion_id", option.get("weapon_id", "unknown")),
						"name": option.get("name", "fusion"),
						"source_a": option.get("weapon_a", ""),
						"source_b": option.get("weapon_b", "")
					}, "fusion")

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
	
	# Stats que van a GlobalWeaponStats (armas)
	# IMPORTANTE: Estos stats SOLO van a GlobalWeaponStats, NO a PlayerStats
	# para evitar duplicación cuando se combinan en AttackManager
	# SINCRONIZADO con PlayerStats.WEAPON_STATS
	var weapon_stats = [
		"damage_mult", "damage_flat", "attack_speed_mult",
		"area_mult", "projectile_speed_mult", "duration_mult", "extra_projectiles",
		"extra_pierce", "knockback_mult", "range_mult", "crit_chance", "crit_damage",
		"chain_count", "life_steal"  # chain_count y life_steal son stats de combate
	]
	
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
			# UpgradeAuditor: snapshot GWS ANTES
			var _auditor = get_node_or_null("/root/UpgradeAuditor")
			var _gws_before := {}
			if _auditor and _auditor.has_method("get_gws_snapshot"):
				_gws_before = _auditor.get_gws_snapshot()
			
			var weapon_option = option.duplicate()
			weapon_option["effects"] = weapon_effects
			attack_manager.apply_global_upgrade(weapon_option)
			
			# UpgradeAuditor: snapshot GWS DESPUÉS y auditar
			if _auditor and _auditor.has_method("audit_global_weapon_upgrade"):
				var _gws_after = _auditor.get_gws_snapshot()
				_auditor.audit_global_weapon_upgrade(option, _gws_before, _gws_after)
	
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
	
	# Sincronizar contadores con PlayerStats al abrir el panel
	_sync_counts_from_player_stats()
	
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

func _are_all_weapons_orbital() -> bool:
	"""Verifica si todas las armas equipadas son orbitales (tags: orbital)"""
	if not attack_manager or not attack_manager.has_method("get_weapons"):
		return false
		
	var weapons = attack_manager.get_weapons()
	if weapons.is_empty():
		return false
		
	for weapon in weapons:
		# Verificar si el arma tiene el tag "orbital"
		var tags = []
		if weapon is BaseWeapon:
			tags = weapon.tags
		elif weapon is Dictionary:
			tags = weapon.get("tags", [])
			
		if not "orbital" in tags:
			return false
			
	return true
