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
@onready var shield_bar: ProgressBar = $Control/TopLeft/ShieldBar

# -- Variables internas --
var _weapons_cache: Array = []
var _passives_cache: Array = []
var _current_boss: Node = null

signal upgrade_selected(upgrade_data)

func _ready():
	# Inicializar estado
	boss_bar.visible = false
	
	# Verificar nodos críticos
	_verify_nodes()
	
	# IMPROVE: Estilizar barras programáticamente para asegurar look premium
	_style_hud_elements()

	_style_shield_bar()
	_create_streak_bar()
	
	# Conectar señal de streak
	var exp_manager = get_tree().get_first_node_in_group("experience_manager")
	if exp_manager:
		if exp_manager.has_signal("streak_timer_updated"):
			exp_manager.streak_timer_updated.connect(_update_streak_timer)
		if exp_manager.has_signal("streak_updated"):
			exp_manager.streak_updated.connect(_update_streak_value)
		if exp_manager.has_signal("streak_finished"):
			exp_manager.streak_finished.connect(_on_streak_finished)

func _update_streak_value(count: int, total_value: int, multiplier: float = 1.0):
	"""Actualizar etiqueta de valor de racha y multiplicador"""
	if streak_value_label:
		streak_value_label.text = "+%d" % total_value
		
		# Feedback visual simple para el valor
		var tween = create_tween()
		tween.tween_property(streak_value_label, "scale", Vector2(1.2, 1.2), 0.05)
		tween.tween_property(streak_value_label, "scale", Vector2(1.0, 1.0), 0.1)

	if streak_multiplier_label:
		streak_multiplier_label.text = "x%.2f" % multiplier
		
		# EFECTO HYPE TRAIN: Escala y color según el multiplicador
		var scale_mult = 1.0
		var hype_color = Color(0.8, 0.8, 1.0) # Base (x1.0)
		var rotation_shake = 0.0
		
		if multiplier >= 3.0: # LEGENDARY
			scale_mult = 1.8
			hype_color = Color(1.0, 0.2, 0.8) # Magenta brillante
			rotation_shake = 15.0
		elif multiplier >= 2.0: # EPIC
			scale_mult = 1.5
			hype_color = Color(1.0, 0.5, 0.0) # Naranja intenso
			rotation_shake = 10.0
		elif multiplier >= 1.5: # RARE
			scale_mult = 1.3
			hype_color = Color(0.2, 0.8, 1.0) # Cyan brillante
			rotation_shake = 5.0
		elif multiplier > 1.0: # UNCOMMON
			scale_mult = 1.15
			hype_color = Color(0.5, 1.0, 0.5) # Verde claro
		
		# Aplicar color
		streak_multiplier_label.add_theme_color_override("font_color", hype_color)
		
		# Animación de golpe
		var mtween = create_tween()
		mtween.set_parallel(true)
		mtween.tween_property(streak_multiplier_label, "scale", Vector2(scale_mult, scale_mult), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		mtween.tween_property(streak_multiplier_label, "rotation_degrees", randf_range(-rotation_shake, rotation_shake), 0.05)
		
		mtween.chain().set_parallel(true)
		mtween.tween_property(streak_multiplier_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		mtween.tween_property(streak_multiplier_label, "rotation_degrees", 0.0, 0.2)

var streak_bar_container: HBoxContainer = null
var streak_icon: TextureRect = null
var streak_value_label: Label = null
var streak_multiplier_label: Label = null
var streak_bar: ProgressBar = null

func show_levelup_popup(upgrades: Array) -> void:
	"""Show level up selection screen using UIManager queue"""
	# Instantiate popup
	var popup_scene = load("res://scenes/ui/LevelUpPanel.tscn")
	if not popup_scene:
		push_warning("[GameHUD] Failed to load LevelUpPanel.tscn")
		return

	var popup = popup_scene.instantiate()
	
	# Setup upgrades data
	if popup.has_method("setup_options"):
		popup.setup_options(upgrades)
	
	# Connect signals if needed (though LevelUpPanel usually handles its own logic)
	# e.g. on upgrade selected
	
	# Request via UIManager
	var ui_manager = get_tree().root.get_node_or_null("UIManager")
	if not ui_manager:
		# Fallback if no UIManager (shouldn't happen in normal play)
		add_child(popup)
	else:
		ui_manager.request_popup(popup)

func hide_levelup_popup() -> void:
	# Deprecated/Unused with UIManager handling closing
	pass

func _create_streak_bar():
	# Crear dinámicamente la barra de racha debajo de las monedas
	var coins_container = get_node_or_null("Control/TopRight/CoinsContainer")
	if coins_container:
		var parent_container = coins_container.get_parent()
		if parent_container:
			# Contenedor horizontal para Icono + Barra + Valor
			streak_bar_container = HBoxContainer.new()
			streak_bar_container.alignment = BoxContainer.ALIGNMENT_END
			streak_bar_container.add_theme_constant_override("separation", 5)
			
			# 1. Icono Dinamita (TextureRect)
			streak_icon = TextureRect.new()
			streak_icon.texture = load("res://assets/ui/hud/icon_streak_bomb.png")
			streak_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			streak_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			streak_icon.custom_minimum_size = Vector2(32, 32)
			streak_bar_container.add_child(streak_icon)
			
			# 2. Barra de Mecha (Progreso inverso)
			streak_bar = ProgressBar.new()
			streak_bar.custom_minimum_size = Vector2(80, 10)
			streak_bar.show_percentage = false
			streak_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			# Estilo "Mecha" (Fuse)
			var bg_style = StyleBoxFlat.new()
			bg_style.bg_color = Color(0.2, 0.1, 0, 0.6)
			bg_style.set_corner_radius_all(4)
			
			var fill_style = StyleBoxFlat.new()
			fill_style.bg_color = Color(1.0, 0.4, 0.1) # Naranja fuego
			fill_style.set_corner_radius_all(4)
			
			streak_bar.add_theme_stylebox_override("background", bg_style)
			streak_bar.add_theme_stylebox_override("fill", fill_style)
			
			streak_bar_container.add_child(streak_bar)
			
			# 3. Etiqueta de Valor (+XXX)
			streak_value_label = Label.new()
			streak_value_label.text = "+0"
			streak_value_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4)) # Amarillo oro
			streak_value_label.add_theme_font_size_override("font_size", 16)
			streak_value_label.add_theme_constant_override("outline_size", 4)
			streak_value_label.add_theme_color_override("font_outline_color", Color.BLACK)
			streak_value_label.add_theme_constant_override("outline_size", 4)
			streak_value_label.add_theme_color_override("font_outline_color", Color.BLACK)
			streak_bar_container.add_child(streak_value_label)
			
			# 4. Etiqueta de Multiplicador (HYPE TRAIN)
			streak_multiplier_label = Label.new()
			streak_multiplier_label.text = "x1.0"
			streak_multiplier_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0)) # Azul claro base
			streak_multiplier_label.add_theme_font_size_override("font_size", 14)
			streak_multiplier_label.add_theme_constant_override("outline_size", 4)
			streak_multiplier_label.add_theme_color_override("font_outline_color", Color.BLACK)
			streak_bar_container.add_child(streak_multiplier_label)
			
			# Añadir al padre (TopRight) justo después de CoinsContainer
			parent_container.add_child(streak_bar_container)
			parent_container.move_child(streak_bar_container, coins_container.get_index() + 1)
			
			streak_bar_container.visible = false # Oculto por defecto

func _on_streak_finished(total_value: int, max_multiplier: float):
	"""Mostrar resultado de la racha al finalizar (HYPE COMPLETE)"""
	# REFINAMIENTO: Solo mostrar si el multiplicador llegó a x2.0 (Epic/Hype real)
	if total_value <= 0 or max_multiplier < 2.0: return
	
	# Crear popup temporal
	var popup = VBoxContainer.new()
	popup.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Posicionar debajo de la barra de racha
	if streak_bar_container:
		# Centrado respecto a la barra + offset Y
		var container_center_x = streak_bar_container.global_position.x + (streak_bar_container.size.x / 2)
		popup.size = Vector2(200, 100)
		popup.position = Vector2(container_center_x - (popup.size.x / 2), streak_bar_container.global_position.y + 40)
	else:
		# Fallback al centro
		popup.position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y / 2 - 150)
		popup.size = Vector2(200, 100)
	
	var title = Label.new()
	title.text = Localization.L("ui.hud.hype_complete")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Dorado
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_child(title)
	
	var result = Label.new()
	result.text = Localization.L("ui.hud.hype_results", [total_value, max_multiplier])
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 18)
	result.add_theme_constant_override("outline_size", 4)
	result.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_child(result)
	
	$Control.add_child(popup)
	
	# Animar entrada y salida (Pop In -> Wait -> Fade Out)
	popup.scale = Vector2.ZERO
	popup.pivot_offset = popup.size / 2
	
	var tween = create_tween()
	tween.tween_property(popup, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.5) # Mostrar por 1.5s
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)

func _update_streak_timer(time_left: float, max_time: float):
	if streak_bar_container:
		if time_left > 0:
			streak_bar_container.visible = true
			if streak_bar:
				streak_bar.max_value = max_time
				streak_bar.value = time_left
				
				# Efecto de parpadeo de la mecha
				if time_left < max_time * 0.3:
					streak_icon.modulate = Color(1, 0.5, 0.5) if (int(Time.get_ticks_msec() / 100) % 2 == 0) else Color.WHITE
				else:
					streak_icon.modulate = Color.WHITE
		else:
			streak_bar_container.visible = false
	if hp_bar:
		var sb_bg = StyleBoxFlat.new()
		sb_bg.bg_color = Color(0.1, 0.0, 0.0, 0.8)
		sb_bg.border_width_left = 2
		sb_bg.border_width_top = 2
		sb_bg.border_width_right = 2
		sb_bg.border_width_bottom = 2
		sb_bg.border_color = Color(0,0,0)
		
		var sb_fill = StyleBoxFlat.new()
		sb_fill.bg_color = Color(0.8, 0.1, 0.1, 1.0) # Rojo intenso
		sb_fill.border_width_left = 2
		sb_fill.border_width_top = 2
		sb_fill.border_width_right = 2
		sb_fill.border_width_bottom = 2
		sb_fill.border_color = Color(0,0,0,0) # Transparente para ver el bg border
		
		hp_bar.add_theme_stylebox_override("background", sb_bg)
		hp_bar.add_theme_stylebox_override("fill", sb_fill)
	
	if xp_bar:
		var sb_fill_xp = StyleBoxFlat.new()
		sb_fill_xp.bg_color = Color(0.2, 0.6, 1.0, 1.0) # Azul brillante
		xp_bar.add_theme_stylebox_override("fill", sb_fill_xp)


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
		# VISUAL FIX: Clampear valores para evitar negativos (caso Blood Pact -133/1)
		var display_current = clampi(current, 0, max_val)
		if max_val == 1: # Caso especial Blood Pact/Glass Cannon
			display_current = current if current > 0 else 0
			# Si por alguna razón el current real es mayor a 1 (sync lag), lo mostramos como 1
			if current >= 1: display_current = 1
			
		hp_bar.max_value = max_val
		hp_bar.value = display_current
		# Actualizar texto dentro de la barra si existe
		var lbl = hp_bar.get_node_or_null("Label")
		if lbl: lbl.text = "%d / %d" % [display_current, max_val]

func update_shield(current: int, max_val: int):
	if shield_bar:
		shield_bar.max_value = maxi(max_val, 1)
		shield_bar.value = current
		# Actualizar texto
		var lbl = shield_bar.get_node_or_null("Label")
		if lbl:
			if max_val > 0:
				lbl.text = "%d / %d" % [current, max_val]
			else:
				lbl.text = "0"
		
		# Cambiar color según si tiene escudo
		_update_shield_bar_color(current, max_val)

func update_exp(current: int, max_val: int):
	if xp_bar:
		xp_bar.max_value = max_val
		xp_bar.value = current

func update_level(level: int):
	if level_label:
		level_label.text = Localization.L("ui.hud.level", [level])

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
	# DEBUG desactivado: Ver qué datos llegan
	# if weapons.size() > 0:
	#	print("[GameHUD] 🗡️ update_weapons llamado con %d armas:" % weapons.size())
	#	for i in range(min(weapons.size(), 3)):
	#		var w = weapons[i]
	#		print("   - Arma %d: %s" % [i, w])
	
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


		


func _create_slot(item_data, is_weapon: bool) -> Control:
	# Crear un TextureRect simple para el icono
	var slot = TextureRect.new()
	slot.custom_minimum_size = Vector2(40, 40) # Slightly bigger
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Fondo del slot (Marco)
	var bg = Panel.new()
	bg.show_behind_parent = true
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Estilo Premium
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.7, 0.2) # Dorado
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	
	bg.add_theme_stylebox_override("panel", style)
	slot.add_child(bg)
	
	# Cargar Icono
	var icon_path = ""
	
	# Manejo de diccionarios (Legacy/Loot)
	if typeof(item_data) == TYPE_DICTIONARY:
		# 1. Prioridad: Usar campo "icon" si es un path válido
		if item_data.has("icon") and typeof(item_data.icon) == TYPE_STRING:
			if item_data.icon.begins_with("res://") and ResourceLoader.exists(item_data.icon):
				icon_path = item_data.icon
		
		# 2. Intentar con prefijo weapon_ + id
		if icon_path == "" and item_data.has("id"):
			var asset_path = "res://assets/icons/weapon_%s.png" % item_data.id
			if ResourceLoader.exists(asset_path):
				icon_path = asset_path
		
		# 3. Intentar solo con id
		if icon_path == "" and item_data.has("id"):
			var asset_path = "res://assets/icons/%s.png" % item_data.id
			if ResourceLoader.exists(asset_path):
				icon_path = asset_path
			
	# Manejo de Objetos (BaseWeapon / RefCounted)
	elif typeof(item_data) == TYPE_OBJECT:
		# 1. Usar campo icon del objeto si es path válido
		if "icon" in item_data and typeof(item_data.icon) == TYPE_STRING:
			if item_data.icon.begins_with("res://") and ResourceLoader.exists(item_data.icon):
				icon_path = item_data.icon
		
		# 2. Intentar por id
		if icon_path == "":
			var w_id = ""
			if "id" in item_data: w_id = item_data.id
			elif item_data.has_method("get_id"): w_id = item_data.get_id()
			
			if w_id != "":
				var asset_path = "res://assets/icons/weapon_%s.png" % w_id
				if ResourceLoader.exists(asset_path):
					icon_path = asset_path
				else:
					asset_path = "res://assets/icons/%s.png" % w_id
					if ResourceLoader.exists(asset_path):
						icon_path = asset_path
	
	if icon_path != "":
		slot.texture = load(icon_path)
	
	# Fallback a emoji si no hay textura
	if slot.texture == null: 
		var text_fallback = "❓"
		if typeof(item_data) == TYPE_DICTIONARY and item_data.has("icon"):
			var icon_val = item_data.icon
			# Si es emoji (no path), usarlo
			if typeof(icon_val) == TYPE_STRING and not icon_val.begins_with("res://"):
				text_fallback = icon_val
		elif typeof(item_data) == TYPE_OBJECT and "icon" in item_data:
			var icon_val = item_data.icon
			if typeof(icon_val) == TYPE_STRING and not icon_val.begins_with("res://"):
				text_fallback = icon_val
			
		var lbl = Label.new()
		lbl.text = text_fallback
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.add_theme_font_size_override("font_size", 20)
		slot.add_child(lbl)

	# Nivel (si aplica)
	if typeof(item_data) == TYPE_DICTIONARY and item_data.has("level"):
		var lvl_lbl = Label.new()
		lvl_lbl.text = str(item_data.level)
		lvl_lbl.position = Vector2(4, 4)
		lvl_lbl.add_theme_font_size_override("font_size", 10)
		lvl_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lvl_lbl.add_theme_constant_override("outline_size", 4)
		slot.add_child(lvl_lbl)
		
	return slot

func _create_empty_slot() -> Control:
	var slot = TextureRect.new()
	slot.custom_minimum_size = Vector2(40, 40)
	
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.3)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.3) # Gris oscuro
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	bg.add_theme_stylebox_override("panel", style)
	slot.add_child(bg)
	
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
	
	# Centrar en pantalla pero arriba (debajo del timer) - Estilo WARNING
	$Control.add_child(msg_label)
	# Usar TOP_WIDE para asegurar que el centro es el centro de la pantalla
	msg_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	msg_label.position.y = 90 # Debajo del timer (que suele estar en 0-60)
	msg_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2)) # Rojo Alerta
	msg_label.add_theme_font_size_override("font_size", 48) # Más grande
	
	# Animación
	msg_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(msg_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(duration)
	tween.tween_property(msg_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(msg_label.queue_free)

# ═══════════════════════════════════════════════════════════════════════════════
# SHIELD BAR
# ═══════════════════════════════════════════════════════════════════════════════

func _update_shield_bar_color(current: int, max_val: int):
	"""Actualizar color del shield bar según si tiene escudo"""
	if not shield_bar:
		return
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.set_corner_radius_all(2)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.set_corner_radius_all(2)
	
	if max_val > 0 and current > 0:
		# Tiene escudo - Azul brillante
		sb_bg.bg_color = Color(0.05, 0.1, 0.2, 0.8)
		sb_bg.border_color = Color(0.2, 0.4, 0.6)
		sb_bg.set_border_width_all(1)
		
		sb_fill.bg_color = Color(0.2, 0.5, 0.9, 1.0)
	else:
		# Sin escudo - Gris azulado
		sb_bg.bg_color = Color(0.08, 0.08, 0.1, 0.6)
		sb_bg.border_color = Color(0.15, 0.15, 0.2)
		sb_bg.set_border_width_all(1)
		
		sb_fill.bg_color = Color(0.2, 0.2, 0.3, 0.5)
	
	shield_bar.add_theme_stylebox_override("background", sb_bg)
	shield_bar.add_theme_stylebox_override("fill", sb_fill)

func _style_shield_bar():
	"""Inicializar estilo de shield bar al crearse"""
	if shield_bar:
		# Empezar con estilo gris (sin escudo)
		_update_shield_bar_color(0, 0)

func _style_hud_elements() -> void:
	# Estilos adicionales si fueran necesarios (placeholder)
	pass
