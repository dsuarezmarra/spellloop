# LevelUpPanel.gd
# Panel de selección al subir de nivel - DISEÑO SIMPLIFICADO
#
# NAVEGACIÓN UNIFICADA (WASD o Flechas funcionan igual):
# - ← → o A/D: Navegar entre opciones
# - Enter/Espacio: Seleccionar (comprar) la opción actual
# - R: Reroll (regenerar opciones)
# - X: Eliminar opción seleccionada (banish)
# - Escape: Saltar/Salir sin elegir

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
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.4, 0.6, 1.0),
	"epic": Color(0.8, 0.4, 1.0),
	"legendary": Color(1.0, 0.8, 0.2)
}

# Colores UI
const SELECTED_COLOR = Color(1.0, 0.85, 0.3)  # Dorado
const UNSELECTED_COLOR = Color(0.4, 0.4, 0.5)
const BG_COLOR = Color(0.08, 0.08, 0.12, 0.95)
const PANEL_BG = Color(0.12, 0.12, 0.18, 0.98)

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var options: Array = []
var option_panels: Array = []
var selected_index: int = 0
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
var controls_label: Label = null

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
	# Fondo oscuro semi-transparente
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
	main_panel.custom_minimum_size = Vector2(850, 480)
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = PANEL_BG
	main_style.border_color = Color(0.3, 0.3, 0.4)
	main_style.set_border_width_all(2)
	main_style.set_corner_radius_all(16)
	main_style.set_content_margin_all(20)
	main_panel.add_theme_stylebox_override("panel", main_style)
	center.add_child(main_panel)

	# Layout vertical
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	# === TÍTULO ===
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", SELECTED_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# === INSTRUCCIONES ===
	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)

	# === OPCIONES ===
	options_container = HBoxContainer.new()
	options_container.add_theme_constant_override("separation", 20)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(options_container)

	# Crear paneles de opción
	for i in range(MAX_OPTIONS):
		var panel = _create_option_panel(i)
		options_container.add_child(panel)
		option_panels.append(panel)

	# === CONTROLES (texto informativo) ===
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator_color", Color(0.3, 0.3, 0.4))
	vbox.add_child(separator)

	controls_label = Label.new()
	controls_label.add_theme_font_size_override("font_size", 16)
	controls_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(controls_label)

func _create_option_panel(index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 300)
	panel.name = "Option_%d" % index

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.2)
	style.border_color = UNSELECTED_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Tipo
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)

	# Icono centrado
	var icon_center = CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(64, 64)
	vbox.add_child(icon_center)

	var icon_label = Label.new()
	icon_label.name = "IconLabel"
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_center.add_child(icon_label)

	# Nombre
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 16)
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
	desc_label.custom_minimum_size.y = 60
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

# ═══════════════════════════════════════════════════════════════════════════════
# INPUT - Navegación unificada (WASD + Flechas)
# ═══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if locked or not visible:
		return

	# Navegación izquierda (← o A)
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	# Navegación derecha (→ o D)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	# Seleccionar/Comprar (Enter/Espacio)
	elif event.is_action_pressed("ui_accept"):
		_select_current()
		get_viewport().set_input_as_handled()
	# Salir (Escape)
	elif event.is_action_pressed("ui_cancel"):
		_on_skip()
		get_viewport().set_input_as_handled()
	# Reroll (R)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_on_reroll()
		get_viewport().set_input_as_handled()
	# Banish/Eliminar (X)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_X:
		_on_banish()
		get_viewport().set_input_as_handled()

func _navigate(direction: int) -> void:
	var count = options.size()
	if count == 0:
		return

	selected_index = (selected_index + direction) % count
	if selected_index < 0:
		selected_index = count - 1

	_update_visuals()

func _update_visuals() -> void:
	for i in range(option_panels.size()):
		var panel = option_panels[i]
		var is_selected = (i == selected_index and i < options.size())
		var is_visible = (i < options.size())

		panel.visible = is_visible

		if not is_visible:
			continue

		# Actualizar estilo del borde
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if is_selected:
			style.border_color = SELECTED_COLOR
			style.set_border_width_all(3)
		else:
			style.border_color = UNSELECTED_COLOR
			style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)

		# Indicador
		var indicator = panel.find_child("Indicator", true, false) as Label
		if indicator:
			indicator.visible = is_selected

# ═══════════════════════════════════════════════════════════════════════════════
# ACCIONES
# ═══════════════════════════════════════════════════════════════════════════════

func _select_current() -> void:
	if locked or selected_index >= options.size():
		return

	locked = true
	var selected = options[selected_index]
	_apply_option(selected)
	option_selected.emit(selected)
	_close_panel()

func _on_reroll() -> void:
	if locked or reroll_count <= 0:
		return

	reroll_count -= 1
	reroll_used.emit()
	generate_options()

func _on_banish() -> void:
	if locked or banish_count <= 0 or selected_index >= options.size():
		return

	var banished = options[selected_index]
	options.remove_at(selected_index)
	banish_count -= 1
	banish_used.emit(selected_index)

	# Ajustar selección
	if selected_index >= options.size() and options.size() > 0:
		selected_index = options.size() - 1

	_update_options_ui()
	_update_visuals()
	_update_controls_text()

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
	selected_index = 0

	_update_options_ui()
	_update_visuals()
	_update_controls_text()

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
# UI UPDATE
# ═══════════════════════════════════════════════════════════════════════════════

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
	var name_label = panel.find_child("NameLabel", true, false) as Label
	var desc_label = panel.find_child("DescLabel", true, false) as Label

	# Tipo
	if type_label:
		type_label.text = _get_type_text(option.get("type", ""))

	# Icono
	if icon_label:
		icon_label.text = str(option.get("icon", "✨"))

	# Nombre con color de rareza
	if name_label:
		name_label.text = option.get("name", "???")
		var rarity = option.get("rarity", "common")
		name_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))

	# Descripción
	if desc_label:
		desc_label.text = option.get("description", "")

func _update_controls_text() -> void:
	if controls_label:
		# Texto de controles en español, siempre actualizado con contadores
		var text = "⬅️ A/D ➡️ Navegar   |   ⏎ ENTER Seleccionar   |   🎲 R Reroll (%d)   |   ❌ X Eliminar (%d)   |   ⏭️ ESC Saltar" % [reroll_count, banish_count]
		controls_label.text = text

func _get_type_text(option_type: String) -> String:
	match option_type:
		OPTION_TYPES.NEW_WEAPON:
			return "🆕 Nueva Arma"
		OPTION_TYPES.LEVEL_UP_WEAPON:
			return "⬆️ Mejorar"
		OPTION_TYPES.FUSION:
			return "🔥 Fusión"
		OPTION_TYPES.PLAYER_UPGRADE:
			return "✨ Mejora"
		_:
			return "✨ Mejora"

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
					"add":
						player_stats[stat] += value
					"multiply":
						player_stats[stat] *= value
					"set":
						player_stats[stat] = value
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
	_update_texts()
	generate_options()

func setup_options(opts: Array) -> void:
	options = opts.duplicate()
	selected_index = 0
	_update_options_ui()
	_update_visuals()

func set_reroll_count(count: int) -> void:
	reroll_count = count
	_update_controls_text()

func set_banish_count(count: int) -> void:
	banish_count = count
	_update_controls_text()

func _update_texts() -> void:
	# Título siempre en español
	if title_label:
		title_label.text = "⬆️ ¡SUBISTE DE NIVEL! ⬆️"

	# Instrucciones
	if hint_label:
		hint_label.text = "Elige una mejora para continuar"

	_update_controls_text()
