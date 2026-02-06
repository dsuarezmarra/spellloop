# BalanceDebugOverlay.gd
# Overlay visual para mostrar métricas de balance en tiempo real
# Toggle con F10
extends CanvasLayer

var _control: Control
var _panel: PanelContainer
var _label_damage: Label
var _label_mitigation: Label
var _label_sustain: Label
var _label_ttk: Label
var _label_progression: Label  # BALANCE PASS 2
var _label_difficulty: Label   # BALANCE PASS 2

var visible_mode: bool = false
var _debugger: BalanceDebugger = null

func _ready() -> void:
	# Buscar el debugger
	await get_tree().process_frame
	var debuggers = get_tree().get_nodes_in_group("balance_debugger")
	if debuggers.size() > 0:
		_debugger = debuggers[0]
		_debugger.metrics_updated.connect(_on_metrics_updated)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 127  # Just below PerfOverlay
	_setup_ui()
	_update_visibility()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		visible_mode = !visible_mode
		_update_visibility()
		if _debugger:
			_debugger.toggle()

func _setup_ui() -> void:
	_control = Control.new()
	_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_control)
	
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(20, 20)
	_control.add_child(_panel)
	
	# Estilo semi-transparente
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	_panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "⚖️ BALANCE DEBUG (F10)"
	title.add_theme_color_override("font_color", Color.GOLD)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Damage
	_label_damage = Label.new()
	_label_damage.text = "DMG: --"
	_label_damage.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	_label_damage.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label_damage)
	
	# Mitigation
	_label_mitigation = Label.new()
	_label_mitigation.text = "MIT: --"
	_label_mitigation.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	_label_mitigation.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label_mitigation)
	
	# Sustain
	_label_sustain = Label.new()
	_label_sustain.text = "SUS: --"
	_label_sustain.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_label_sustain.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label_sustain)
	
	# TTK
	_label_ttk = Label.new()
	_label_ttk.text = "TTK: --"
	_label_ttk.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_label_ttk.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label_ttk)
	
	# BALANCE PASS 2: Progression
	_label_progression = Label.new()
	_label_progression.text = "LVL: --"
	_label_progression.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	_label_progression.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label_progression)
	
	# BALANCE PASS 2: Difficulty
	_label_difficulty = Label.new()
	_label_difficulty.text = "DIF: --"
	_label_difficulty.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_label_difficulty.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label_difficulty)

func _update_visibility() -> void:
	_control.visible = visible_mode

func _on_metrics_updated(m: Dictionary) -> void:
	if not visible_mode:
		return
	
	# Daño
	_label_damage.text = "⚔️ DMG: %d/%0.f/%d (DPS: %.0f)" % [
		m.damage_dealt.min,
		m.damage_dealt.avg,
		m.damage_dealt.max,
		m.damage_dealt.dps
	]
	
	# Mitigación
	_label_mitigation.text = "🛡️ MIT: %.0f%% | Dodge: %d | Shield: %d" % [
		m.mitigation.mitigation_pct * 100,
		m.mitigation.dodges,
		m.mitigation.shield_absorbed
	]
	
	# Sustain
	_label_sustain.text = "💚 SUS: %.1f HP/s (R:%.0f L:%.0f K:%.0f)" % [
		m.sustain.per_sec,
		m.sustain.regen,
		m.sustain.lifesteal,
		m.sustain.kill_heal
	]
	
	# TTK
	_label_ttk.text = "⏱️ TTK: Elite %.1fs (%d) | Boss %.1fs (%d)" % [
		m.ttk.elite_avg,
		m.ttk.elite_samples,
		m.ttk.boss_avg,
		m.ttk.boss_samples
	]
	
	# BALANCE PASS 2: Progression
	if m.has("progression"):
		_label_progression.text = "📈 LVL %d | XP/min %.0f | Lvl/min %.2f" % [
			m.progression.current_level,
			m.progression.xp_per_min,
			m.progression.levels_per_min
		]
	
	# BALANCE PASS 2: Difficulty
	if m.has("difficulty") and not m.difficulty.is_empty():
		_label_difficulty.text = "🎯 HP:%.1fx DMG:%.1fx SPD:%.1fx" % [
			m.difficulty.get("hp_mult", 1.0),
			m.difficulty.get("dmg_mult", 1.0),
			m.difficulty.get("speed_mult", 1.0)
		]
