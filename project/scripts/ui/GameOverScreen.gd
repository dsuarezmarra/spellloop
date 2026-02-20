extends Control
class_name GameOverScreen

## Pantalla de Game Over
## Muestra estadísticas de la partida y opciones
## NAVEGACION: Solo WASD y gamepad (NO flechas de direccion)

signal retry_pressed
signal menu_pressed

@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/StatsContainer
@onready var retry_button: Button = $Panel/VBoxContainer/ButtonsContainer/RetryButton
@onready var menu_button: Button = $Panel/VBoxContainer/ButtonsContainer/MenuButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

# Colores de UI
const HEADER_COLOR = Color(1.0, 0.85, 0.3)
const VALUE_COLOR = Color(1, 0.9, 0.5)
const WEAPON_NAME_COLOR = Color(0.85, 0.85, 0.95)
const WEAPON_VALUE_COLOR = Color(0.3, 0.9, 0.4)
const SEPARATOR_COLOR = Color(0.3, 0.3, 0.4, 0.6)
const ELEMENT_COLORS = {
	"ice": Color(0.4, 0.8, 1.0), "fire": Color(1.0, 0.5, 0.2),
	"lightning": Color(1.0, 1.0, 0.3), "arcane": Color(0.7, 0.4, 1.0),
	"shadow": Color(0.5, 0.3, 0.7), "nature": Color(0.3, 0.9, 0.4),
	"wind": Color(0.6, 0.9, 0.8), "earth": Color(0.7, 0.5, 0.3),
	"light": Color(1.0, 1.0, 0.9), "void": Color(0.3, 0.2, 0.5),
	"physical": Color(0.7, 0.7, 0.7)
}

# Stats de la partida
var final_stats: Dictionary = {}

# Sistema de navegacion WASD
var buttons: Array[Button] = []
var current_button_index: int = 0

func _ready() -> void:
	_connect_signals()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _connect_signals() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func show_game_over(stats: Dictionary = {}) -> void:
	final_stats = stats
	visible = true
	get_tree().paused = true

	_display_stats()
	_setup_wasd_navigation()

	# Animacion de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	_play_game_over_sound()

func _setup_wasd_navigation() -> void:
	"""Configurar navegacion WASD"""
	buttons.clear()

	if retry_button:
		buttons.append(retry_button)
		# Desactivar navegacion por flechas
		retry_button.focus_neighbor_top = retry_button.get_path()
		retry_button.focus_neighbor_bottom = retry_button.get_path()
		retry_button.focus_neighbor_left = retry_button.get_path()
		retry_button.focus_neighbor_right = retry_button.get_path()

	if menu_button:
		buttons.append(menu_button)
		menu_button.focus_neighbor_top = menu_button.get_path()
		menu_button.focus_neighbor_bottom = menu_button.get_path()
		menu_button.focus_neighbor_left = menu_button.get_path()
		menu_button.focus_neighbor_right = menu_button.get_path()

	current_button_index = 0
	if buttons.size() > 0:
		buttons[0].grab_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var handled = false

	# Navegacion con teclado WASD + Flechas
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A, KEY_W, KEY_LEFT, KEY_UP:
				_navigate(-1)
				handled = true
			KEY_D, KEY_S, KEY_RIGHT, KEY_DOWN:
				_navigate(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_activate_current()
				handled = true

	# Soporte para gamepad
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP:
				_navigate(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN:
				_navigate(1)
				handled = true
			JOY_BUTTON_A:
				_activate_current()
				handled = true

	# Soporte para joystick analogico
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate(-1)
				handled = true
			elif event.axis_value > 0.5:
				_navigate(1)
				handled = true

	if handled:
		var vp = get_viewport()
		if vp:
			vp.set_input_as_handled()

func _navigate(direction: int) -> void:
	if buttons.is_empty():
		return

	current_button_index = wrapi(current_button_index + direction, 0, buttons.size())
	buttons[current_button_index].grab_focus()

func _activate_current() -> void:
	if buttons.is_empty():
		return

	var current = buttons[current_button_index]
	if current:
		current.pressed.emit()

func _display_stats() -> void:
	if not stats_container:
		return

	# Limpiar stats anteriores
	for child in stats_container.get_children():
		child.queue_free()

	# ═══════════════════════════════════════════════════════════════════════════
	# SECCIÓN 1: ESTADÍSTICAS BÁSICAS DE LA PARTIDA
	# ═══════════════════════════════════════════════════════════════════════════

	# Tiempo sobrevivido
	var time_survived = final_stats.get("time", 0.0)
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	_add_stat_line(Localization.L("ui.game_over.time"), "%02d:%02d" % [minutes, seconds])

	# Nivel alcanzado
	var level = final_stats.get("level", 1)
	_add_stat_line(Localization.L("ui.game_over.level"), str(level))

	# Enemigos eliminados
	var kills = final_stats.get("kills", 0)
	_add_stat_line(Localization.L("ui.game_over.enemies"), _format_number(kills))

	# XP total obtenida
	var xp = final_stats.get("xp_total", 0)
	_add_stat_line(Localization.L("ui.game_over.xp_total"), _format_number(xp))

	# Oro recogido
	var gold = final_stats.get("gold", 0)
	if gold > 0:
		_add_stat_line(Localization.L("ui.game_over.gold"), _format_number(gold))

	# ═══════════════════════════════════════════════════════════════════════════
	# SECCIÓN 2: ESTADÍSTICAS DE COMBATE
	# ═══════════════════════════════════════════════════════════════════════════
	_add_section_separator()

	# Daño total infligido (desde RunAuditTracker si disponible, sino de run_stats)
	var total_damage_dealt = _get_total_damage_dealt()
	if total_damage_dealt > 0:
		_add_stat_line(Localization.L("ui.game_over.damage_total"), _format_number(total_damage_dealt))

	# Daño recibido
	var damage_taken = final_stats.get("damage_taken", 0)
	if damage_taken > 0:
		_add_stat_line(Localization.L("ui.game_over.damage_taken"), _format_number(damage_taken))

	# DPS medio (si hay tiempo y daño)
	if total_damage_dealt > 0 and time_survived > 0:
		var avg_dps = total_damage_dealt / time_survived
		_add_stat_line(Localization.L("ui.game_over.avg_dps"), _format_number(int(avg_dps)))

	# Curación realizada
	var healing = final_stats.get("healing_done", 0)
	if healing > 0:
		_add_stat_line(Localization.L("ui.game_over.healing"), _format_number(healing))

	# Bosses y Elites
	var bosses = final_stats.get("bosses_killed", 0)
	if bosses > 0:
		_add_stat_line(Localization.L("ui.game_over.bosses"), str(bosses))

	var elites = final_stats.get("elites_killed", 0)
	if elites > 0:
		_add_stat_line(Localization.L("ui.game_over.elites"), str(elites))

	# ═══════════════════════════════════════════════════════════════════════════
	# SECCIÓN 3: DESGLOSE DE ARMAS (datos de RunAuditTracker)
	# ═══════════════════════════════════════════════════════════════════════════
	var weapon_stats = _get_weapon_audit_stats()
	if weapon_stats.size() > 0:
		_add_section_separator()
		_add_section_header(Localization.L("ui.game_over.weapon_breakdown"))
		_display_weapon_breakdown(weapon_stats, total_damage_dealt)

func _get_total_damage_dealt() -> int:
	"""Obtener daño total: prefiere datos de RunAuditTracker (más precisos)"""
	if RunAuditTracker and RunAuditTracker.ENABLE_AUDIT:
		var total: int = 0
		for weapon_id in RunAuditTracker._weapon_stats:
			total += RunAuditTracker._weapon_stats[weapon_id].damage_total
		if total > 0:
			return total
	return final_stats.get("damage_dealt", 0)

func _get_weapon_audit_stats() -> Array:
	"""Obtener stats de armas ordenados por daño (desde RunAuditTracker)"""
	if not RunAuditTracker or not RunAuditTracker.ENABLE_AUDIT:
		return []

	var weapons: Array = []
	for weapon_id in RunAuditTracker._weapon_stats:
		var ws = RunAuditTracker._weapon_stats[weapon_id]
		weapons.append({
			"weapon_id": ws.weapon_id,
			"weapon_name": ws.weapon_name,
			"damage_total": ws.damage_total,
			"hits_total": ws.hits_total,
			"crits_total": ws.crits_total,
			"crit_rate": ws.get_crit_rate(),
			"kills": ws.kills,
		})

	# Ordenar por daño descendente
	weapons.sort_custom(func(a, b): return a.damage_total > b.damage_total)
	return weapons

func _display_weapon_breakdown(weapon_stats: Array, total_damage: int) -> void:
	"""Mostrar desglose de daño por arma con barra visual"""
	var max_weapons = mini(weapon_stats.size(), 6)  # Máximo 6 armas

	for i in range(max_weapons):
		var ws = weapon_stats[i]
		if ws.damage_total <= 0:
			continue

		var weapon_row = VBoxContainer.new()
		weapon_row.add_theme_constant_override("separation", 2)
		stats_container.add_child(weapon_row)

		# Fila superior: nombre + daño
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weapon_row.add_child(hbox)

		# Nombre del arma
		var name_label = Label.new()
		var display_name = _format_weapon_name(ws.weapon_name)
		name_label.text = display_name
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", WEAPON_NAME_COLOR)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hbox.add_child(name_label)

		# Daño + porcentaje
		var pct = (float(ws.damage_total) / float(total_damage) * 100.0) if total_damage > 0 else 0.0
		var value_label = Label.new()
		value_label.text = "%s (%d%%)" % [_format_number(ws.damage_total), int(pct)]
		value_label.add_theme_font_size_override("font_size", 15)
		value_label.add_theme_color_override("font_color", WEAPON_VALUE_COLOR)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(value_label)

		# Barra de progreso visual
		var bar_container = HBoxContainer.new()
		bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weapon_row.add_child(bar_container)

		var progress = ProgressBar.new()
		progress.custom_minimum_size = Vector2(0, 6)
		progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.max_value = 100.0
		progress.value = pct
		progress.show_percentage = false

		# Estilo de la barra
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = Color(0.2, 0.6, 0.3, 0.8)
		bar_style.set_corner_radius_all(3)
		progress.add_theme_stylebox_override("fill", bar_style)

		var bar_bg = StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.15, 0.15, 0.2, 0.5)
		bar_bg.set_corner_radius_all(3)
		progress.add_theme_stylebox_override("background", bar_bg)

		bar_container.add_child(progress)

		# Sub-stats: kills + crit rate
		if ws.kills > 0 or ws.crit_rate > 0:
			var sub_hbox = HBoxContainer.new()
			sub_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			weapon_row.add_child(sub_hbox)

			var sub_text = ""
			if ws.kills > 0:
				sub_text += "💀 %d kills" % ws.kills
			if ws.crit_rate > 0:
				if sub_text != "":
					sub_text += "  •  "
				sub_text += "🎯 %d%% crit" % int(ws.crit_rate * 100)

			var sub_label = Label.new()
			sub_label.text = sub_text
			sub_label.add_theme_font_size_override("font_size", 12)
			sub_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			sub_hbox.add_child(sub_label)

func _format_weapon_name(raw_name: String) -> String:
	"""Intentar obtener nombre legible del arma"""
	# Si el nombre es un ID técnico, formatearlo
	if "_" in raw_name and raw_name == raw_name.to_lower():
		return raw_name.replace("_", " ").capitalize()
	return raw_name

func _format_number(value: int) -> String:
	"""Formatear número grande con separadores de miles"""
	if value < 1000:
		return str(value)
	elif value < 1000000:
		if value % 1000 == 0:
			return "%dk" % (value / 1000)
		return "%s" % _add_thousands_separator(value)
	else:
		return "%.1fM" % (float(value) / 1000000.0)

func _add_thousands_separator(value: int) -> String:
	"""Añadir separador de miles a un número"""
	var s = str(value)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result

func _add_section_separator() -> void:
	"""Añadir separador visual entre secciones"""
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	sep.add_theme_color_override("separator", SEPARATOR_COLOR)
	stats_container.add_child(sep)

func _add_section_header(text: String) -> void:
	"""Añadir cabecera de sección"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", HEADER_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(label)

func _add_stat_line(label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)

	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(1, 0.9, 0.5))

	hbox.add_child(label)
	hbox.add_child(value)
	stats_container.add_child(hbox)

func _on_retry_pressed() -> void:
	_play_button_sound()
	retry_pressed.emit()
	# La transición de escena se maneja en Game.gd

func _on_menu_pressed() -> void:
	_play_button_sound()
	menu_pressed.emit()
	# La transición de escena se maneja en Game.gd

func _play_button_sound() -> void:
	AudioManager.play_fixed("sfx_ui_click")

func _play_game_over_sound() -> void:
	# Game over sound not generated yet
	pass
