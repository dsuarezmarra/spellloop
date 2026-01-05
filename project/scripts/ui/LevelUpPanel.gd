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

const MAX_OPTIONS: int = 4
const OPTION_TYPES = {
	NEW_WEAPON = "new_weapon",
	LEVEL_UP_WEAPON = "level_up_weapon",
	FUSION = "fusion",
	PLAYER_UPGRADE = "player_upgrade"
}

# Colores
const RARITY_COLORS = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.4, 0.6, 1.0),
	"epic": Color(0.8, 0.4, 1.0),
	"legendary": Color(1.0, 0.8, 0.2)
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

var options: Array = []
var option_panels: Array = []
var button_panels: Array = []
var reroll_count: int = 3
var banish_count: int = 2
var locked: bool = false

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

	# Navegación IZQUIERDA (← o A)
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_navigate_horizontal(-1)
		handled = true

	# Navegación DERECHA (→ o D)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_navigate_horizontal(1)
		handled = true

	# Navegación ARRIBA (↑ o W)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_navigate_vertical(-1)
		handled = true

	# Navegación ABAJO (↓ o S)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_navigate_vertical(1)
		handled = true

	# CONFIRMAR (Enter/Espacio)
	elif event.is_action_pressed("ui_accept"):
		_confirm_selection()
		handled = true

	# CANCELAR (Escape) - atajo directo para saltar
	elif event.is_action_pressed("ui_cancel"):
		_on_skip()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()

func _navigate_horizontal(direction: int) -> void:
	if current_row == Row.OPTIONS:
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
	if direction > 0:
		# Bajar a botones
		current_row = Row.BUTTONS
	else:
		# Subir a opciones
		current_row = Row.OPTIONS

	_update_all_visuals()

func _confirm_selection() -> void:
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

	# Eliminar la opción actualmente seleccionada en la fila de opciones
	var idx_to_remove = option_index
	if idx_to_remove >= options.size():
		idx_to_remove = options.size() - 1

	options.remove_at(idx_to_remove)
	banish_count -= 1
	banish_used.emit(idx_to_remove)

	# Ajustar índice
	if option_index >= options.size() and options.size() > 0:
		option_index = options.size() - 1

	_update_options_ui()
	_update_all_visuals()
	_update_button_counts()

func _on_skip() -> void:
	if locked:
		return

	skip_used.emit()
	_close_panel()

func _close_panel() -> void:
	get_tree().paused = false
	panel_closed.emit()
	queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN VISUAL
# ═══════════════════════════════════════════════════════════════════════════════

func _update_all_visuals() -> void:
	# Actualizar opciones
	for i in range(option_panels.size()):
		var panel = option_panels[i]
		var is_selected = (current_row == Row.OPTIONS and i == option_index and i < options.size())
		var is_visible = (i < options.size())

		panel.visible = is_visible

		if not is_visible:
			continue

		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if is_selected:
			style.border_color = SELECTED_COLOR
			style.set_border_width_all(3)
		else:
			style.border_color = UNSELECTED_COLOR
			style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)

		var indicator = panel.find_child("Indicator", true, false) as Label
		if indicator:
			indicator.visible = is_selected

	# Actualizar botones
	for i in range(button_panels.size()):
		var panel = button_panels[i]
		var is_selected = (current_row == Row.BUTTONS and i == button_index)
		var is_disabled = _is_button_disabled(i)

		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if is_disabled:
			style.border_color = DISABLED_COLOR
			style.bg_color = Color(0.1, 0.1, 0.12)
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

	# Nombre
	if name_label:
		name_label.text = option.get("name", "???")
		var rarity = option.get("rarity", "common")
		name_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))

	# Descripción
	if desc_label:
		desc_label.text = option.get("description", "")

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
	var upgrade_options: Array = []

	var PassiveDB = load("res://scripts/data/PassiveDatabase.gd")
	if PassiveDB:
		var db = PassiveDB.new()
		if db.has_method("get_random_passives"):
			var passives = db.get_random_passives(6, [], luck)
			for p in passives:
				upgrade_options.append({
					"type": OPTION_TYPES.PLAYER_UPGRADE,
					"upgrade_id": p.get("id", ""),
					"name": p.get("name", "???"),
					"description": p.get("description", ""),
					"icon": p.get("icon", "✨"),
					"rarity": p.get("rarity", "common"),
					"effects": p.get("effects", []),
					"priority": 0.8
				})
			db.queue_free()

	return upgrade_options

func _get_fallback_options() -> Array:
	return [
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "damage_boost",
			"name": "Daño Mágico +",
			"description": "Aumenta el daño en un 10%",
			"icon": "⚡",
			"rarity": "common",
			"effects": [{"stat": "damage_multiplier", "value": 0.10, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "speed_boost",
			"name": "Velocidad +",
			"description": "Aumenta la velocidad en un 10%",
			"icon": "💨",
			"rarity": "common",
			"effects": [{"stat": "speed_multiplier", "value": 0.10, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "health_boost",
			"name": "Vida Máxima +",
			"description": "Aumenta la vida máxima en 20",
			"icon": "❤️",
			"rarity": "common",
			"effects": [{"stat": "max_health", "value": 20, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "cooldown_reduction",
			"name": "Recarga Rápida",
			"description": "Reduce el cooldown en un 5%",
			"icon": "⏰",
			"rarity": "uncommon",
			"effects": [{"stat": "cooldown_reduction", "value": 0.05, "operation": "add"}],
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
		if not weapon.can_level_up():
			continue

		level_options.append({
			"type": OPTION_TYPES.LEVEL_UP_WEAPON,
			"weapon_id": weapon.id,
			"weapon": weapon,
			"name": "%s Nv.%d → %d" % [weapon.weapon_name_es, weapon.level, weapon.level + 1],
			"description": weapon.get_next_upgrade_description(),
			"icon": weapon.icon,
			"rarity": "uncommon" if weapon.level < 5 else "rare",
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

	for opt in all_options:
		var t = opt.type
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(opt)

	for t in by_type:
		by_type[t].sort_custom(func(a, b): return a.priority > b.priority)

	for t in by_type:
		if balanced.size() >= MAX_OPTIONS:
			break
		if not by_type[t].is_empty():
			balanced.append(by_type[t].pop_front())

	var remaining: Array = []
	for t in by_type:
		remaining.append_array(by_type[t])
	remaining.shuffle()

	while balanced.size() < MAX_OPTIONS and not remaining.is_empty():
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
	if option.has("effects") and player_stats:
		for effect in option.effects:
			var stat = effect.get("stat", "")
			var value = effect.get("value", 0)
			var op = effect.get("operation", "add")

			if player_stats.has_method("modify_stat"):
				player_stats.modify_stat(stat, value, op)
			elif stat in player_stats:
				match op:
					"add": player_stats[stat] += value
					"multiply": player_stats[stat] *= value
					"set": player_stats[stat] = value
		return

	if player_stats and player_stats.has_method("apply_upgrade"):
		player_stats.apply_upgrade(option.get("upgrade_id", ""))

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
