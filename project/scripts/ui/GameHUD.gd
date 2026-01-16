extends CanvasLayer
class_name GameHUD

# ═══════════════════════════════════════════════════════════════════════════════
# HUD REDISEÑADO - ESTILO MINIMALISTA (Vampire Survivors / Brotato)
# ═══════════════════════════════════════════════════════════════════════════════

# -- Referencias UI --
@onready var hp_bar: ProgressBar = $Control/TopLeft/HPBar
@onready var xp_bar: ProgressBar = $Control/TopLeft/XPContainer/XPBar
@onready var level_label: Label = $Control/TopLeft/XPContainer/LevelLabel

@onready var time_label: Label = $Control/TopCenter/TimeLabel
@onready var kill_label: Label = $Control/TopRight/KillsContainer/KillLabel
@onready var coin_label: Label = $Control/TopRight/CoinsContainer/CoinLabel

@onready var weapon_container: HBoxContainer = $Control/BottomLeft/WeaponsContainer
@onready var passive_container: HBoxContainer = $Control/BottomLeft/PassivesContainer

@onready var boss_bar: ProgressBar = $Control/TopCenter/BossHPBar
@onready var boss_label: Label = $Control/TopCenter/BossHPBar/BossNameLabel

# -- Variables internas --
var _weapons_cache: Array = []
var _passives_cache: Array = []
var _current_boss: Node = null

signal upgrade_selected(upgrade_data)

func _ready():
	# Inicializar estado
	boss_bar.visible = false
	
	# Verificar nodos críticos (fallback para evitar crash si el tscn no está actualizado aun)
	_verify_nodes()

func _verify_nodes():
	# Si algun nodo vital es null (porque el tscn aun no se actualizó), buscarlos dinámicamente o ignorar
	if not hp_bar: hp_bar = get_node_or_null("Control/TopLeft/HPBar")
	if not xp_bar: xp_bar = get_node_or_null("Control/TopLeft/XPContainer/XPBar")
	# ... otros nudos
	
# ═══════════════════════════════════════════════════════════════════════════════
# UPDATERS (Llamados desde Game.gd)
# ═══════════════════════════════════════════════════════════════════════════════

func update_health(current: int, max_val: int):
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
		# Actualizar texto dentro de la barra si existe
		var lbl = hp_bar.get_node_or_null("Label")
		if lbl: lbl.text = "%d / %d" % [current, max_val]

func update_exp(current: int, max_val: int):
	if xp_bar:
		xp_bar.max_value = max_val
		xp_bar.value = current

func update_level(level: int):
	if level_label:
		level_label.text = "LVL %d" % level

func update_time(seconds: float):
	if time_label:
		var mins = int(seconds / 60)
		var secs = int(seconds) % 60
		time_label.text = "%02d:%02d" % [mins, secs]

func update_coins(amount_added: int, total_coins: int):
	if coin_label:
		coin_label.text = str(total_coins)
		if amount_added > 0:
			_animate_coin_gain()

func update_kills(kill_count: int):
	if kill_label:
		kill_label.text = str(kill_count)

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIÓN DE ARMAS E ITEMS (Slots)
# ═══════════════════════════════════════════════════════════════════════════════

func update_weapons(weapons: Array):
	# Reconstruir slots
	if not weapon_container: return
	
	for child in weapon_container.get_children():
		child.queue_free()
	
	var max_slots = 6 
	
	for i in range(max_slots):
		if i < weapons.size():
			var slot = _create_slot(weapons[i], true)
			weapon_container.add_child(slot)
		else:
			var empty = _create_empty_slot()
			weapon_container.add_child(empty)

func update_passives(passives: Array):
	if not passive_container: return
	
	for child in passive_container.get_children():
		child.queue_free()
		
	var max_slots = 6
	for i in range(max_slots):
		if i < passives.size():
			var slot = _create_slot(passives[i], false)
			passive_container.add_child(slot)
		else:
			var empty = _create_empty_slot()
			passive_container.add_child(empty)

func _create_empty_slot() -> Control:
	var slot = TextureRect.new()
	slot.custom_minimum_size = Vector2(32, 32)
	
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.2, 0.2)
	bg.add_theme_stylebox_override("panel", style)
	slot.add_child(bg)
	
	return slot
		


func _create_slot(item_data, is_weapon: bool) -> Control:
	# Crear un TextureRect simple para el icono
	var slot = TextureRect.new()
	slot.custom_minimum_size = Vector2(32, 32)
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Fondo del slot
	var bg = Panel.new()
	bg.show_behind_parent = true
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Estilo básico
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.3)
	bg.add_theme_stylebox_override("panel", style)
	slot.add_child(bg)
	
	# Icono
	var icon_path = ""
	if typeof(item_data) == TYPE_DICTIONARY:
		icon_path = item_data.get("icon_path", "")
		if icon_path == "" and item_data.has("id"):
			# Fallback a buscar por ID
			pass # TODO: Implement icon lookup
	
	if icon_path != "":
		slot.texture = load(icon_path)
	
	# Nivel (si aplica)
	if typeof(item_data) == TYPE_DICTIONARY and item_data.has("level"):
		var lvl_lbl = Label.new()
		lvl_lbl.text = str(item_data.level)
		lvl_lbl.position = Vector2(2, 2)
		lvl_lbl.add_theme_font_size_override("font_size", 10)
		slot.add_child(lvl_lbl)
		
	return slot


# ═══════════════════════════════════════════════════════════════════════════════
# BOSS BAR
# ═══════════════════════════════════════════════════════════════════════════════

func show_boss_bar(boss_node: Node, boss_name: String):
	_current_boss = boss_node
	boss_bar.visible = true
	if boss_label: boss_label.text = boss_name
	
	# Conectar muerte
	if _current_boss.has_signal("tree_exited"):
		if not _current_boss.tree_exited.is_connected(hide_boss_bar):
			_current_boss.tree_exited.connect(hide_boss_bar)
	
	set_process(true)

func hide_boss_bar():
	boss_bar.visible = false
	_current_boss = null

func _process(_delta):
	# Actualizar boss bar
	if _current_boss and is_instance_valid(_current_boss) and boss_bar.visible:
		if _current_boss.has_method("get_hp_percent"): # Si tiene metodo helper
			boss_bar.value = _current_boss.get_hp_percent() * boss_bar.max_value
		elif "health_component" in _current_boss and _current_boss.health_component:
			var hc = _current_boss.health_component
			boss_bar.max_value = hc.max_health
			boss_bar.value = hc.current_health
		elif "hp" in _current_boss and "max_hp" in _current_boss: # Legacy fallbacks
			boss_bar.max_value = _current_boss.max_hp
			boss_bar.value = _current_boss.hp

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMACIONES / UX
# ═══════════════════════════════════════════════════════════════════════════════

func _animate_coin_gain():
	if not coin_label: return
	var tween = create_tween()
	tween.tween_property(coin_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(coin_label, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Color flash dorado
	tween.parallel().tween_property(coin_label, "modulate", Color(1, 1, 0.5), 0.1)
	tween.parallel().tween_property(coin_label, "modulate", Color.WHITE, 0.1)

func show_wave_message(text: String, duration: float = 3.0):
	# Mostrar mensaje grande en el centro (ej: "WAVE 5", "BOSS SPAWNED")
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 32)
	msg_label.add_theme_color_override("font_color", Color.GOLD)
	msg_label.add_theme_constant_override("outline_size", 4)
	msg_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Centrar en pantalla
	$Control.add_child(msg_label)
	msg_label.set_anchors_preset(Control.PRESET_CENTER)
	
	# Animación
	msg_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(msg_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(duration)
	tween.tween_property(msg_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(msg_label.queue_free)
