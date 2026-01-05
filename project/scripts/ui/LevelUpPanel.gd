# LevelUpPanel.gd
# Panel de selección al subir de nivel
#
# NAVEGACIÓN:
# - Flechas izquierda/derecha o joystick para navegar entre opciones
# - Enter/Espacio/A para abrir menú de acciones
# - Escape/B para cerrar menú de acciones o salir (skip)
#
# ACCIONES:
# - Comprar: Adquiere la mejora seleccionada
# - Banish: Elimina la opción del pool (limitado)
# - Cancelar: Vuelve a la selección

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

# Colores por rareza
const RARITY_COLORS = {
	"common": Color(0.8, 0.8, 0.8),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.8, 0.2)
}

# Colores de selección
const SELECTED_BORDER_COLOR = Color(1.0, 0.85, 0.3)  # Dorado
const UNSELECTED_BORDER_COLOR = Color(0.35, 0.35, 0.5)

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var options: Array = []
var option_panels: Array = []

# Navegación
var selected_index: int = 0
var action_menu_open: bool = false

# Balance de Reroll y Banish:
# - Reroll: 3 usos totales (permite re-randomizar opciones)
# - Banish: 2 usos totales (elimina una opción permanentemente del pool)
# - Skip: ILIMITADO (siempre puede cerrar sin elegir nada)
var reroll_count: int = 3
var banish_count: int = 2
var locked: bool = false

# Referencias
var attack_manager: AttackManager = null
var player_stats: PlayerStats = null

# UI Nodes
var main_container: PanelContainer = null
var title_label: Label = null
var subtitle_label: Label = null
var options_container: HBoxContainer = null
var controls_container: HBoxContainer = null
var action_menu_container: PanelContainer = null
var reroll_button: Button = null
var skip_button: Button = null

# Action menu buttons
var buy_button: Button = null
var banish_button: Button = null
var cancel_button: Button = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()

func initialize(attack_mgr: AttackManager, stats: PlayerStats) -> void:
	"""Inicializar con referencias a los sistemas del juego"""
	attack_manager = attack_mgr
	player_stats = stats

func _create_ui() -> void:
	"""Crear la interfaz del panel"""
	# Fondo oscuro que cubre toda la pantalla
	var dark_bg = ColorRect.new()
	dark_bg.color = Color(0, 0, 0, 0.8)
	dark_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dark_bg)

	# CenterContainer para centrar el panel
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Container principal con estilo
	main_container = PanelContainer.new()
	main_container.custom_minimum_size = Vector2(900, 520)

	# Crear StyleBox para el panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.98)
	style.border_color = Color(0.4, 0.35, 0.6)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(15)
	main_container.add_theme_stylebox_override("panel", style)
	center.add_child(main_container)

	# Layout vertical
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	main_container.add_child(vbox)

	# Margen interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 15)
	vbox.add_child(margin)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(inner_vbox)

	# Título
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(title_label)

	# Subtítulo con instrucciones
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.modulate = Color(0.6, 0.6, 0.7)
	inner_vbox.add_child(subtitle_label)

	# Container de opciones
	options_container = HBoxContainer.new()
	options_container.add_theme_constant_override("separation", 15)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(options_container)

	# Crear paneles de opción (sin botones de selección)
	for i in range(MAX_OPTIONS):
		var option_panel = _create_option_panel(i)
		options_container.add_child(option_panel)
		option_panels.append(option_panel)

	# Separador
	var separator = HSeparator.new()
	inner_vbox.add_child(separator)

	# Container de menú de acciones (inicialmente oculto)
	_create_action_menu(inner_vbox)

	# Container de controles inferiores
	controls_container = HBoxContainer.new()
	controls_container.add_theme_constant_override("separation", 20)
	controls_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(controls_container)

	# Botón Reroll
	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(140, 40)
	reroll_button.pressed.connect(_on_reroll_pressed)
	controls_container.add_child(reroll_button)

	# Botón Skip (siempre disponible)
	skip_button = Button.new()
	skip_button.custom_minimum_size = Vector2(140, 40)
	skip_button.pressed.connect(_on_skip_pressed)
	controls_container.add_child(skip_button)

func _create_option_panel(index: int) -> Control:
	"""Crear un panel de opción individual (sin botón de selección)"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 280)
	panel.name = "Option_%d" % index

	# Estilo del panel de opción (se actualiza según selección)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.22, 0.95)
	style.border_color = UNSELECTED_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Margen
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(margin_container)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 6)
	margin_container.add_child(inner_vbox)

	# Tipo (pequeño)
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.modulate = Color(0.7, 0.7, 0.8)
	inner_vbox.add_child(type_label)

	# Container de icono (centrado)
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(64, 64)
	inner_vbox.add_child(icon_container)

	# Icono como TextureRect
	var icon_texture = TextureRect.new()
	icon_texture.name = "IconTexture"
	icon_texture.custom_minimum_size = Vector2(64, 64)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_container.add_child(icon_texture)

	# Label de icono como fallback (para emojis)
	var icon_label = Label.new()
	icon_label.name = "IconLabel"
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.visible = false
	icon_container.add_child(icon_label)

	# Nombre
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 70
	inner_vbox.add_child(desc_label)

	# Indicador de selección (flecha)
	var selection_indicator = Label.new()
	selection_indicator.name = "SelectionIndicator"
	selection_indicator.text = "▲"
	selection_indicator.add_theme_font_size_override("font_size", 20)
	selection_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_indicator.modulate = SELECTED_BORDER_COLOR
	selection_indicator.visible = false
	inner_vbox.add_child(selection_indicator)

	return panel

func _create_action_menu(parent: VBoxContainer) -> void:
	"""Crear el menú de acciones (Comprar, Banish, Cancelar)"""
	action_menu_container = PanelContainer.new()
	action_menu_container.name = "ActionMenu"
	action_menu_container.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.25, 0.98)
	style.border_color = SELECTED_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	action_menu_container.add_theme_stylebox_override("panel", style)
	parent.add_child(action_menu_container)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_menu_container.add_child(hbox)

	# Botón Comprar
	buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.custom_minimum_size = Vector2(140, 45)
	buy_button.pressed.connect(_on_buy_pressed)
	hbox.add_child(buy_button)

	# Botón Banish
	banish_button = Button.new()
	banish_button.name = "BanishButton"
	banish_button.custom_minimum_size = Vector2(140, 45)
	banish_button.pressed.connect(_on_banish_option_pressed)
	hbox.add_child(banish_button)

	# Botón Cancelar
	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.custom_minimum_size = Vector2(140, 45)
	cancel_button.pressed.connect(_on_cancel_action_pressed)
	hbox.add_child(cancel_button)

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT - Navegación con teclado/gamepad
# ═══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if locked or not visible:
		return

	# Navegación con flechas/joystick
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):  # Enter/Espacio/A
		if action_menu_open:
			# Si el menú está abierto, comprar por defecto
			_on_buy_pressed()
		else:
			_open_action_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):  # Escape/B
		if action_menu_open:
			_close_action_menu()
		else:
			_on_skip_pressed()
		get_viewport().set_input_as_handled()

func _navigate(direction: int) -> void:
	"""Navegar entre opciones"""
	if action_menu_open:
		return

	var visible_count = 0
	for i in range(options.size()):
		if i < option_panels.size() and option_panels[i].visible:
			visible_count += 1

	if visible_count == 0:
		return

	selected_index = (selected_index + direction) % visible_count
	if selected_index < 0:
		selected_index = visible_count - 1

	_update_selection_visual()

func _update_selection_visual() -> void:
	"""Actualizar indicador visual de selección"""
	for i in range(option_panels.size()):
		var panel = option_panels[i]
		var indicator = panel.find_child("SelectionIndicator", true, false) as Label
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

		if i == selected_index and i < options.size():
			# Seleccionado
			style.border_color = SELECTED_BORDER_COLOR
			style.set_border_width_all(3)
			if indicator:
				indicator.visible = true
		else:
			# No seleccionado
			style.border_color = UNSELECTED_BORDER_COLOR
			style.set_border_width_all(2)
			if indicator:
				indicator.visible = false

		panel.add_theme_stylebox_override("panel", style)

func _open_action_menu() -> void:
	"""Abrir menú de acciones para la opción seleccionada"""
	if selected_index >= options.size():
		return

	action_menu_open = true
	action_menu_container.visible = true
	_update_action_menu_buttons()

	# Enfocar botón comprar
	buy_button.grab_focus()

func _close_action_menu() -> void:
	"""Cerrar menú de acciones"""
	action_menu_open = false
	action_menu_container.visible = false

func _update_action_menu_buttons() -> void:
	"""Actualizar textos y estado de botones del menú de acciones"""
	var buy_text = _get_localized("ui.level_up.buy", "Comprar")
	var banish_text = _get_localized("ui.level_up.banish", "Eliminar")
	var cancel_text = _get_localized("ui.level_up.cancel", "Cancelar")

	buy_button.text = "✅ " + buy_text
	banish_button.text = "🚫 %s (%d)" % [banish_text, banish_count]
	cancel_button.text = "❌ " + cancel_text

	banish_button.disabled = banish_count <= 0

# ═══════════════════════════════════════════════════════════════════════════════
# GENERACIÓN DE OPCIONES
# ═══════════════════════════════════════════════════════════════════════════════

func generate_options() -> void:
	"""Generar opciones aleatorias basadas en el estado del juego"""
	options.clear()

	var luck = 0.0
	if player_stats and player_stats.has_method("get_stat"):
		luck = player_stats.get_stat("luck")

	# Pool de opciones posibles
	var possible_options: Array = []

	# 1. Nuevas armas (si hay slots)
	if attack_manager and attack_manager.has_method("has_available_slot"):
		if attack_manager.has_available_slot:
			var new_weapons = _get_new_weapon_options()
			possible_options.append_array(new_weapons)

	# 2. Subir nivel de armas existentes
	if attack_manager and attack_manager.has_method("get_weapons"):
		var level_up_options = _get_weapon_level_up_options()
		possible_options.append_array(level_up_options)

	# 3. Fusiones disponibles
	if attack_manager and attack_manager.has_method("get_available_fusions"):
		var fusion_options = _get_fusion_options()
		possible_options.append_array(fusion_options)

	# 4. Upgrades de stats del jugador (desde PassiveDatabase)
	var player_upgrades = _get_player_upgrade_options_from_database(luck)
	possible_options.append_array(player_upgrades)

	# Si no hay opciones suficientes, usar fallback
	if possible_options.size() < 2:
		possible_options = _get_fallback_options()

	# Mezclar y seleccionar
	possible_options.shuffle()

	# Balancear tipos de opciones
	options = _balance_options(possible_options)

	# Reset selección
	selected_index = 0

	# Actualizar UI
	_update_options_ui()
	_update_selection_visual()

func _get_player_upgrade_options_from_database(luck: float) -> Array:
	"""Obtener opciones de mejora usando PassiveDatabase directamente"""
	var upgrade_options: Array = []

	# Intentar cargar PassiveDatabase
	var PassiveDB = load("res://scripts/data/PassiveDatabase.gd")
	if PassiveDB:
		var db_instance = PassiveDB.new()
		if db_instance.has_method("get_random_passives"):
			var passives = db_instance.get_random_passives(6, [], luck)
			for passive in passives:
				upgrade_options.append({
					"type": OPTION_TYPES.PLAYER_UPGRADE,
					"upgrade_id": passive.get("id", ""),
					"name": passive.get("name", "???"),
					"description": passive.get("description", ""),
					"icon": passive.get("icon", "✨"),
					"rarity": passive.get("rarity", "common"),
					"effects": passive.get("effects", []),
					"priority": 0.8
				})
			db_instance.queue_free()
			return upgrade_options

	# Fallback: usar PlayerStats si tiene el método
	if player_stats and player_stats.has_method("get_random_upgrades"):
		var upgrades = player_stats.get_random_upgrades(6, luck)
		for upgrade in upgrades:
			upgrade_options.append({
				"type": OPTION_TYPES.PLAYER_UPGRADE,
				"upgrade_id": upgrade.id,
				"name": upgrade.name,
				"description": upgrade.description,
				"icon": upgrade.icon,
				"rarity": upgrade.rarity,
				"priority": 0.8
			})

	return upgrade_options

func _get_fallback_options() -> Array:
	"""Opciones de fallback si no hay otras disponibles"""
	return [
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "damage_boost",
			"name": _get_localized("gameplay.passives.damage_boost", "Daño Mágico +"),
			"description": _get_localized("gameplay.passives.damage_boost_desc", "Aumenta el daño de los proyectiles mágicos en un 10%"),
			"icon": "⚡",
			"rarity": "common",
			"effects": [{"stat": "damage_multiplier", "value": 0.10, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "speed_boost",
			"name": _get_localized("gameplay.passives.speed_boost", "Velocidad +"),
			"description": _get_localized("gameplay.passives.speed_boost_desc", "Aumenta la velocidad de movimiento en un 10%"),
			"icon": "💨",
			"rarity": "common",
			"effects": [{"stat": "speed_multiplier", "value": 0.10, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "health_boost",
			"name": _get_localized("gameplay.passives.health_boost", "Vida Máxima +"),
			"description": _get_localized("gameplay.passives.health_boost_desc", "Aumenta la vida máxima en 20"),
			"icon": "❤️",
			"rarity": "common",
			"effects": [{"stat": "max_health", "value": 20, "operation": "add"}],
			"priority": 0.8
		},
		{
			"type": OPTION_TYPES.PLAYER_UPGRADE,
			"upgrade_id": "cooldown_reduction",
			"name": _get_localized("gameplay.passives.cooldown_reduction", "Recarga Rápida"),
			"description": _get_localized("gameplay.passives.cooldown_reduction_desc", "Reduce el tiempo de recarga de armas en un 5%"),
			"icon": "⏰",
			"rarity": "uncommon",
			"effects": [{"stat": "cooldown_reduction", "value": 0.05, "operation": "add"}],
			"priority": 0.8
		}
	]

func _get_new_weapon_options() -> Array:
	"""Obtener opciones de armas nuevas"""
	var new_options: Array = []
	var current_weapon_ids = []

	for weapon in attack_manager.get_weapons():
		current_weapon_ids.append(weapon.id)

	# Obtener armas que no tenemos
	var all_weapons = WeaponDatabase.get_all_base_weapons()
	for weapon_id in all_weapons:
		if weapon_id in current_weapon_ids:
			continue

		var weapon_data = WeaponDatabase.get_weapon_data(weapon_id)
		if weapon_data.is_empty():
			continue

		new_options.append({
			"type": OPTION_TYPES.NEW_WEAPON,
			"weapon_id": weapon_id,
			"name": weapon_data.get("name_es", weapon_data.get("name", "?")),
			"description": weapon_data.get("description", ""),
			"icon": weapon_data.get("icon", "🔮"),
			"rarity": weapon_data.get("rarity", "common"),
			"priority": 1.0
		})

	return new_options

func _get_weapon_level_up_options() -> Array:
	"""Obtener opciones para subir nivel de armas"""
	var level_options: Array = []

	for weapon in attack_manager.get_weapons():
		if not weapon.can_level_up():
			continue

		level_options.append({
			"type": OPTION_TYPES.LEVEL_UP_WEAPON,
			"weapon_id": weapon.id,
			"weapon": weapon,
			"name": "%s Lv.%d → %d" % [weapon.weapon_name_es, weapon.level, weapon.level + 1],
			"description": weapon.get_next_upgrade_description(),
			"icon": weapon.icon,
			"rarity": "uncommon" if weapon.level < 5 else "rare",
			"priority": 1.5
		})

	return level_options

func _get_fusion_options() -> Array:
	"""Obtener opciones de fusión"""
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
			"description": "Fusión: %s + %s\n⚠️ -1 slot permanente" % [
				fusion.weapon_a.weapon_name_es, fusion.weapon_b.weapon_name_es
			],
			"icon": preview.get("icon", "⚡"),
			"rarity": "epic",
			"priority": 2.0
		})

	return fusion_options

func _balance_options(all_options: Array) -> Array:
	"""Balancear tipos de opciones para que haya variedad"""
	var balanced: Array = []
	var by_type: Dictionary = {}

	# Agrupar por tipo
	for opt in all_options:
		var t = opt.type
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(opt)

	# Ordenar cada grupo por prioridad
	for t in by_type:
		by_type[t].sort_custom(func(a, b): return a.priority > b.priority)

	# Intentar incluir al menos 1 de cada tipo disponible
	for t in by_type:
		if balanced.size() >= MAX_OPTIONS:
			break
		if not by_type[t].is_empty():
			balanced.append(by_type[t].pop_front())

	# Llenar el resto
	var remaining: Array = []
	for t in by_type:
		remaining.append_array(by_type[t])
	remaining.shuffle()

	while balanced.size() < MAX_OPTIONS and not remaining.is_empty():
		balanced.append(remaining.pop_front())

	return balanced

# ═══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN DE UI
# ═══════════════════════════════════════════════════════════════════════════════

func _update_options_ui() -> void:
	"""Actualizar la UI con las opciones actuales"""
	for i in range(MAX_OPTIONS):
		var panel = option_panels[i]

		if i < options.size():
			_update_option_panel(panel, options[i])
			panel.visible = true
		else:
			panel.visible = false

	_update_control_buttons()

func _update_option_panel(panel: Control, option: Dictionary) -> void:
	"""Actualizar un panel de opción con datos"""
	var type_label = panel.find_child("TypeLabel", true, false) as Label
	var icon_texture = panel.find_child("IconTexture", true, false) as TextureRect
	var icon_label = panel.find_child("IconLabel", true, false) as Label
	var name_label = panel.find_child("NameLabel", true, false) as Label
	var desc_label = panel.find_child("DescLabel", true, false) as Label

	# Tipo (usando localización)
	var type_text = _get_option_type_text(option.get("type", OPTION_TYPES.PLAYER_UPGRADE))
	if type_label:
		type_label.text = type_text

	# Icono - intentar cargar imagen, fallback a emoji
	var icon_value = option.get("icon", "✨")
	var loaded_texture = false

	if icon_texture:
		icon_texture.texture = null
		icon_texture.visible = false
	if icon_label:
		icon_label.visible = false

	# Si el icono es una ruta de archivo, cargar textura
	if icon_value is String and icon_value.begins_with("res://"):
		var tex = load(icon_value)
		if tex and icon_texture:
			icon_texture.texture = tex
			icon_texture.visible = true
			loaded_texture = true

	# Si no se cargó textura, usar emoji
	if not loaded_texture and icon_label:
		if icon_value is String and icon_value.begins_with("res://"):
			icon_label.text = "✨"
		else:
			icon_label.text = str(icon_value)
		icon_label.visible = true

	# Nombre con color de rareza
	if name_label:
		name_label.text = option.get("name", "???")
		var rarity = option.get("rarity", "common")
		name_label.modulate = RARITY_COLORS.get(rarity, Color.WHITE)

	# Descripción
	if desc_label:
		desc_label.text = option.get("description", "")

func _update_control_buttons() -> void:
	"""Actualizar estados de los botones de control con localización"""
	var reroll_text = _get_localized("ui.level_up.reroll", "Reroll")
	var skip_text = _get_localized("ui.level_up.skip", "Salir")

	if reroll_button:
		reroll_button.text = "🎲 %s (%d)" % [reroll_text, reroll_count]
		reroll_button.disabled = reroll_count <= 0

	if skip_button:
		skip_button.text = "⏭️ %s" % skip_text
		skip_button.disabled = false

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS - Acciones
# ═══════════════════════════════════════════════════════════════════════════════

func _on_buy_pressed() -> void:
	"""Comprar/Seleccionar la opción actual"""
	if locked or selected_index >= options.size():
		return

	locked = true
	var selected = options[selected_index]

	# Aplicar la opción seleccionada
	_apply_option(selected)

	# Emitir señal y cerrar
	option_selected.emit(selected)
	_close_panel()

func _on_banish_option_pressed() -> void:
	"""Banish la opción seleccionada"""
	if locked or banish_count <= 0 or selected_index >= options.size():
		return

	var banished = options[selected_index]
	options.remove_at(selected_index)
	banish_count -= 1

	banish_used.emit(selected_index)
	print("[LevelUpPanel] Banish usado: %s (restantes: %d)" % [banished.name, banish_count])

	# Ajustar selección si es necesario
	if selected_index >= options.size() and options.size() > 0:
		selected_index = options.size() - 1

	# Cerrar menú de acciones y actualizar
	_close_action_menu()
	_update_options_ui()
	_update_selection_visual()

func _on_cancel_action_pressed() -> void:
	"""Cancelar acción y volver a selección"""
	_close_action_menu()

func _on_reroll_pressed() -> void:
	"""Manejar reroll"""
	if locked or reroll_count <= 0:
		return

	reroll_count -= 1
	reroll_used.emit()
	generate_options()
	print("[LevelUpPanel] Reroll usado (restantes: %d)" % reroll_count)

func _on_skip_pressed() -> void:
	"""Manejar skip (siempre disponible, sin límite)"""
	if locked:
		return

	skip_used.emit()
	_close_panel()
	print("[LevelUpPanel] Skip usado")

func _apply_option(option: Dictionary) -> void:
	"""Aplicar la opción seleccionada"""
	match option.type:
		OPTION_TYPES.NEW_WEAPON:
			if attack_manager and attack_manager.has_method("add_weapon_by_id"):
				attack_manager.add_weapon_by_id(option.weapon_id)
				print("[LevelUpPanel] Nueva arma: %s" % option.name)

		OPTION_TYPES.LEVEL_UP_WEAPON:
			if attack_manager and attack_manager.has_method("level_up_weapon_by_id"):
				attack_manager.level_up_weapon_by_id(option.weapon_id)
				print("[LevelUpPanel] Arma mejorada: %s" % option.name)

		OPTION_TYPES.FUSION:
			if attack_manager and attack_manager.has_method("fuse_weapons"):
				attack_manager.fuse_weapons(option.weapon_a, option.weapon_b)
				print("[LevelUpPanel] Fusión realizada: %s" % option.name)

		OPTION_TYPES.PLAYER_UPGRADE:
			_apply_player_upgrade(option)
			print("[LevelUpPanel] Upgrade aplicado: %s" % option.name)

func _apply_player_upgrade(option: Dictionary) -> void:
	"""Aplicar upgrade de jugador"""
	# Intentar aplicar efectos directamente
	if option.has("effects") and player_stats:
		for effect in option.effects:
			var stat_name = effect.get("stat", "")
			var value = effect.get("value", 0)
			var operation = effect.get("operation", "add")

			if player_stats.has_method("modify_stat"):
				player_stats.modify_stat(stat_name, value, operation)
			elif stat_name in player_stats:
				match operation:
					"add":
						player_stats[stat_name] += value
					"multiply":
						player_stats[stat_name] *= value
					"set":
						player_stats[stat_name] = value
		return

	# Fallback: usar método apply_upgrade de PlayerStats
	if player_stats and player_stats.has_method("apply_upgrade"):
		player_stats.apply_upgrade(option.get("upgrade_id", ""))

func _close_panel() -> void:
	"""Cerrar el panel"""
	get_tree().paused = false
	panel_closed.emit()
	queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func show_panel() -> void:
	"""Mostrar el panel y generar opciones"""
	visible = true
	get_tree().paused = true
	locked = false
	action_menu_open = false
	action_menu_container.visible = false
	_update_localized_texts()
	generate_options()

func setup_options(opts: Array) -> void:
	"""Configurar opciones manualmente (para compatibilidad)"""
	options = opts.duplicate()
	selected_index = 0
	_update_options_ui()
	_update_selection_visual()

func set_reroll_count(count: int) -> void:
	reroll_count = count
	_update_control_buttons()

func set_banish_count(count: int) -> void:
	banish_count = count
	_update_action_menu_buttons()

# ═══════════════════════════════════════════════════════════════════════════════
# LOCALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _get_localized(key: String, fallback: String) -> String:
	"""Obtener texto localizado con fallback"""
	var loc = get_node_or_null("/root/Localization")
	if loc:
		if loc.has_method("L"):
			var result = loc.L(key)
			if result != key:
				return result
		elif loc.has_method("get_text"):
			var result = loc.get_text(key)
			if result != key:
				return result

	return fallback

func _update_localized_texts() -> void:
	"""Actualizar todos los textos con localización"""
	# Título
	if title_label:
		title_label.text = "⬆️ %s ⬆️" % _get_localized("ui.level_up.title", "¡SUBISTE DE NIVEL!")

	# Subtítulo con instrucciones
	if subtitle_label:
		var nav_hint = _get_localized("ui.level_up.nav_hint", "◀ ▶ Navegar  |  Enter/A Seleccionar  |  Esc/B Salir")
		subtitle_label.text = nav_hint

	# Botones de control
	_update_control_buttons()
	_update_action_menu_buttons()

func _get_option_type_text(option_type: String) -> String:
	"""Obtener texto localizado para tipo de opción"""
	match option_type:
		OPTION_TYPES.NEW_WEAPON:
			return "🆕 " + _get_localized("ui.level_up.new_weapon", "Nueva Arma")
		OPTION_TYPES.LEVEL_UP_WEAPON:
			return "⬆️ " + _get_localized("ui.level_up.upgrade_weapon", "Mejorar")
		OPTION_TYPES.FUSION:
			return "🔥 " + _get_localized("ui.level_up.fusion", "Fusión")
		OPTION_TYPES.PLAYER_UPGRADE:
			return "✨ " + _get_localized("ui.level_up.upgrade", "Mejora")
		_:
			return "✨ " + _get_localized("ui.level_up.upgrade", "Mejora")
