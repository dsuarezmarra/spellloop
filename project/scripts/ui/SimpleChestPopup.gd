extends CanvasLayer
class_name SimpleChestPopup

# Popup simple para selección de items del cofre - USANDO CANVASLAYER
signal item_selected(item)
signal all_items_claimed(items)
signal skipped

var available_items: Array = []
var main_control: Control
var items_vbox: VBoxContainer
var _main_vbox: VBoxContainer  # Referencia al contenedor principal
var item_buttons: Array[Control] = [] # Changed to Control to handle buttons or panels
var current_selected_index: int = -1
var popup_locked: bool = false
var is_jackpot_mode: bool = false
var claim_button: Button = null
var skip_button: Button = null
var _is_skip_modal_active: bool = false
var _jackpot_claimed_items: Array = []  # Items aceptados en modo jackpot
var _jackpot_pending_items: Array = []  # Items pendientes en modo jackpot

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMACIÓN DE CHEST BURST (Reveal espectacular)
# ═══════════════════════════════════════════════════════════════════════════════

var _enable_burst_animation: bool = true  # Toggle para habilitar/deshabilitar
var _is_animating: bool = false           # Si la animación está en progreso
var _chest_rarity: int = 1                # Rareza del cofre para intensidad visual
var _popup_bg: PanelContainer = null      # Referencia al panel principal

const BURST_RARITY_COLORS: Dictionary = {
	1: Color(0.7, 0.7, 0.7),       # Common - Gray
	2: Color(0.3, 0.8, 0.3),       # Uncommon - Green  
	3: Color(0.3, 0.5, 1.0),       # Rare - Blue
	4: Color(0.7, 0.3, 0.9),       # Epic - Purple
	5: Color(1.0, 0.75, 0.2)       # Legendary - Gold
}
const SHAKE_DURATION: float = 0.4
const BURST_DURATION: float = 0.3
const ITEM_REVEAL_DELAY: float = 0.15

# GESTIÓN DE PAUSA GLOBAL PARA POPUPS APILADOS
static var active_instances: int = 0

func _enter_tree():
	active_instances += 1
	get_tree().paused = true
	# print("[SimpleChestPopup] Popup abierto. Activos: %d" % active_instances)

func _exit_tree():
	active_instances -= 1
	if active_instances <= 0:
		active_instances = 0
		get_tree().paused = false
		# print("[SimpleChestPopup] Todos los popups cerrados. Juego reanudado.")
	else:
		pass
		# print("[SimpleChestPopup] Popup cerrado. Restantes: %d (Juego sigue pausado)" % active_instances)

func _ready():
	# CanvasLayer siempre está al frente (no afectado por cámara)
	layer = 100
	
	# CRUCIAL: Procesar SIEMPRE aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pausar el juego (Manejado por _enter_tree via active_instances)
	# get_tree().paused = true
	
	# Asegurar que puede recibir input
	set_process_input(true)
	
	# Crear control que cubre toda la pantalla
	main_control = Control.new()
	main_control.anchor_left = 0.0
	main_control.anchor_top = 0.0
	main_control.anchor_right = 1.0
	main_control.anchor_bottom = 1.0
	main_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(main_control)
	
	# Fondo semi-transparente
	var bg_panel = PanelContainer.new()
	bg_panel.anchor_left = 0.0
	bg_panel.anchor_top = 0.0
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.6)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	main_control.add_child(bg_panel)
	
	# Popup centrado (PanelContainer)
	var popup_bg = PanelContainer.new()
	popup_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_bg.add_theme_stylebox_override("panel", create_panel_style())
	popup_bg.custom_minimum_size = Vector2(650, 0) # Wider, altura dinámica
	popup_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_control.add_child(popup_bg)
	
	_popup_bg = popup_bg  # Guardar referencia para animaciones y recentrado
	
	# Contenedor principal (VBoxContainer)
	_main_vbox = VBoxContainer.new()
	_main_vbox.add_theme_constant_override("separation", 10)
	popup_bg.add_child(_main_vbox)
	
	# Título
	var title = Label.new()
	title.text = "¡Escoge tu recompensa!"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_vbox.add_child(title)
	
	# WRAPPER con padding para evitar clipping de bordes/glow
	# Este margen garantiza que los efectos visuales nunca se corten
	var items_wrapper = MarginContainer.new()
	items_wrapper.add_theme_constant_override("margin_left", 10)
	items_wrapper.add_theme_constant_override("margin_right", 10)
	items_wrapper.add_theme_constant_override("margin_top", 8)
	items_wrapper.add_theme_constant_override("margin_bottom", 8)
	items_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_vbox.add_child(items_wrapper)
	
	# Lista de items
	items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 10)  # Más espacio entre items
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_wrapper.add_child(items_vbox)
	
	# Centrar popup después de un frame
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	popup_bg.position = (screen_size - popup_bg.size) / 2
	
	# Inicializar selección
	current_selected_index = 0

func show_as_jackpot(items: Array):
	"""Mostrar modo Jackpot (múltiples premios) - Items seleccionables individualmente"""
	is_jackpot_mode = true
	_jackpot_pending_items = items.duplicate()
	_jackpot_claimed_items = []
	
	# Actualizar título
	for child in _main_vbox.get_children():
		if child is Label:
			child.text = "¡RECOMPENSA LEGENDARIA!"
			child.modulate = Color(1, 0.8, 0.2) # Dorado
			break
	
	# Crear items con botones de aceptar/rechazar
	_setup_jackpot_items(items)
	
	# Contenedor para botones de acción al final
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_hbox.add_theme_constant_override("separation", 20)
	_main_vbox.add_child(buttons_hbox)
	
	# Botón Reclamar Todo
	claim_button = Button.new()
	claim_button.text = "✓ RECLAMAR TODO"
	claim_button.custom_minimum_size = Vector2(200, 50)
	claim_button.add_theme_font_size_override("font_size", 16)
	
	var style_claim = StyleBoxFlat.new()
	style_claim.bg_color = Color(0.15, 0.4, 0.15)
	style_claim.border_color = Color(0.4, 1.0, 0.4)
	style_claim.set_border_width_all(3)
	style_claim.set_corner_radius_all(8)
	claim_button.add_theme_stylebox_override("normal", style_claim)
	
	var style_claim_hover = style_claim.duplicate()
	style_claim_hover.bg_color = Color(0.2, 0.5, 0.2)
	claim_button.add_theme_stylebox_override("hover", style_claim_hover)
	
	claim_button.pressed.connect(_on_claim_all_pressed)
	buttons_hbox.add_child(claim_button)
	
	# Botón Cerrar (rechazar resto)
	var close_button = Button.new()
	close_button.text = "✕ CERRAR"
	close_button.custom_minimum_size = Vector2(150, 50)
	close_button.add_theme_font_size_override("font_size", 16)
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.3, 0.15, 0.15)
	style_close.border_color = Color(0.7, 0.3, 0.3)
	style_close.set_border_width_all(2)
	style_close.set_corner_radius_all(8)
	close_button.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = style_close.duplicate()
	style_close_hover.bg_color = Color(0.4, 0.2, 0.2)
	close_button.add_theme_stylebox_override("hover", style_close_hover)
	
	close_button.pressed.connect(_on_jackpot_close_pressed)
	buttons_hbox.add_child(close_button)
	
	# Recentrar popup
	await get_tree().process_frame
	_recenter_popup()
	
	# Dar foco al primer item
	if item_buttons.size() > 0:
		item_buttons[0].grab_focus()

func _setup_jackpot_items(items: Array):
	"""Crear items para modo jackpot con botones de aceptar/rechazar"""
	available_items = items
	item_buttons.clear()
	
	# Limpiar items previos
	for child in items_vbox.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	for i in range(items.size()):
		var item = items[i]
		var item_panel = _create_jackpot_item_panel(item, i)
		items_vbox.add_child(item_panel)
		item_buttons.append(item_panel)

func _create_jackpot_item_panel(item: Dictionary, index: int) -> Control:
	"""Crear panel de item para jackpot con botones de acción"""
	var item_name = item.get("name", "Objeto Misterioso")
	var item_desc = item.get("description", "Sin descripción")
	var item_icon = item.get("icon", "❓")
	var item_id = item.get("id", "")
	var item_type = item.get("type", "upgrade")
	var item_rarity = item.get("rarity", item.get("tier", 1) - 1)
	var is_weapon = (item_type == "weapon" or item_type == "new_weapon" or item_type == "fusion")
	
	# Panel contenedor principal
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 80)
	
	var panel_style = UIVisualHelper.get_panel_style(item_rarity + 1, false, is_weapon)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	if is_weapon:
		UIVisualHelper.apply_tier_glow(panel, item_rarity + 1)
	
	# HBox principal
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Margen izquierdo
	var margin_left = Control.new()
	margin_left.custom_minimum_size = Vector2(10, 0)
	hbox.add_child(margin_left)
	
	# Icono
	var icon_panel = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0, 0, 0, 0.3)
	icon_style.border_color = UIVisualHelper.get_color_for_tier(item_rarity + 1)
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(4)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_tex = null
	if item_id != "":
		var path = "res://assets/icons/%s.png" % item_id
		if ResourceLoader.exists(path):
			icon_tex = load(path)
	
	if icon_tex:
		icon_rect.texture = icon_tex
	else:
		var emoji_lbl = Label.new()
		emoji_lbl.text = item_icon
		emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji_lbl.add_theme_font_size_override("font_size", 28)
		emoji_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.add_child(emoji_lbl)
	
	icon_panel.add_child(icon_rect)
	hbox.add_child(icon_panel)
	
	# Info (nombre + descripción)
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var name_lbl = Label.new()
	name_lbl.text = item_name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", UIVisualHelper.get_color_for_tier(item_rarity + 1))
	info_vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = item_desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	info_vbox.add_child(desc_lbl)
	
	hbox.add_child(info_vbox)
	
	# Botones de acción
	var actions_vbox = VBoxContainer.new()
	actions_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_vbox.add_theme_constant_override("separation", 4)
	
	# Botón Aceptar
	var accept_btn = Button.new()
	accept_btn.text = "✓"
	accept_btn.custom_minimum_size = Vector2(40, 30)
	accept_btn.add_theme_font_size_override("font_size", 18)
	accept_btn.tooltip_text = "Aceptar"
	
	var accept_style = StyleBoxFlat.new()
	accept_style.bg_color = Color(0.2, 0.5, 0.2)
	accept_style.set_corner_radius_all(4)
	accept_btn.add_theme_stylebox_override("normal", accept_style)
	var accept_hover = accept_style.duplicate()
	accept_hover.bg_color = Color(0.3, 0.7, 0.3)
	accept_btn.add_theme_stylebox_override("hover", accept_hover)
	
	var item_data = item.duplicate()
	accept_btn.pressed.connect(func(): _on_jackpot_item_accepted(index, item_data, panel))
	actions_vbox.add_child(accept_btn)
	
	# Botón Rechazar
	var reject_btn = Button.new()
	reject_btn.text = "✕"
	reject_btn.custom_minimum_size = Vector2(40, 30)
	reject_btn.add_theme_font_size_override("font_size", 18)
	reject_btn.tooltip_text = "Rechazar"
	
	var reject_style = StyleBoxFlat.new()
	reject_style.bg_color = Color(0.5, 0.2, 0.2)
	reject_style.set_corner_radius_all(4)
	reject_btn.add_theme_stylebox_override("normal", reject_style)
	var reject_hover = reject_style.duplicate()
	reject_hover.bg_color = Color(0.7, 0.3, 0.3)
	reject_btn.add_theme_stylebox_override("hover", reject_hover)
	
	reject_btn.pressed.connect(func(): _on_jackpot_item_rejected(index, panel))
	actions_vbox.add_child(reject_btn)
	
	hbox.add_child(actions_vbox)
	
	# Margen derecho
	var margin_right = Control.new()
	margin_right.custom_minimum_size = Vector2(10, 0)
	hbox.add_child(margin_right)
	
	return panel

func _on_jackpot_item_accepted(index: int, item: Dictionary, panel: Control):
	"""Item aceptado individualmente en jackpot"""
	if popup_locked: return
	
	# Añadir a items reclamados
	_jackpot_claimed_items.append(item)
	
	# Remover de pendientes
	for i in range(_jackpot_pending_items.size()):
		if _jackpot_pending_items[i].get("id", "") == item.get("id", ""):
			_jackpot_pending_items.remove_at(i)
			break
	
	# Animar y remover panel
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(0.5, 1.0, 0.5, 0.5), 0.2)
	tween.tween_property(panel, "custom_minimum_size:y", 0, 0.2)
	tween.tween_callback(func():
		panel.queue_free()
		item_buttons.erase(panel)
		_check_jackpot_complete()
	)
	
	# Emitir señal de item individual
	item_selected.emit(item)

func _on_jackpot_item_rejected(index: int, panel: Control):
	"""Item rechazado en jackpot"""
	if popup_locked: return
	
	# Remover de pendientes sin añadir a reclamados
	if index < _jackpot_pending_items.size():
		_jackpot_pending_items.remove_at(index)
	
	# Animar y remover panel
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1.0, 0.5, 0.5, 0.3), 0.2)
	tween.tween_property(panel, "custom_minimum_size:y", 0, 0.2)
	tween.tween_callback(func():
		panel.queue_free()
		item_buttons.erase(panel)
		_check_jackpot_complete()
	)

func _check_jackpot_complete():
	"""Verificar si todos los items han sido procesados"""
	await get_tree().process_frame
	_recenter_popup()
	
	# Si no quedan items pendientes, cerrar
	if items_vbox.get_child_count() == 0:
		popup_locked = true
		if _jackpot_claimed_items.size() > 0:
			all_items_claimed.emit(_jackpot_claimed_items)
		else:
			skipped.emit()
		queue_free()

func _on_jackpot_close_pressed():
	"""Cerrar jackpot reclamando solo los ya aceptados"""
	if popup_locked: return
	popup_locked = true
	
	if _jackpot_claimed_items.size() > 0:
		all_items_claimed.emit(_jackpot_claimed_items)
	else:
		skipped.emit()
	queue_free()

func _recenter_popup() -> void:
	"""Recentrar el popup después de cambios de contenido"""
	if _popup_bg and is_instance_valid(_popup_bg):
		await get_tree().process_frame
		var screen_size = get_viewport().get_visible_rect().size
		_popup_bg.position = (screen_size - _popup_bg.size) / 2

func setup_items(items: Array):
	"""Configurar los items disponibles"""
	available_items = items
	item_buttons.clear() 
	
	# Limpiar items previos
	for child in items_vbox.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear botones complejos
	for i in range(items.size()):
		var item = items[i]
		var item_name = item.get("name", "Objeto Misterioso")
		var item_desc = item.get("description", "Sin descripción")
		var item_icon = item.get("icon", "❓") # Emoji fallback
		var item_id = item.get("id", "")
		
		var item_type = item.get("type", "upgrade")
		var item_rarity = item.get("rarity", item.get("tier", 1) - 1)  # tier-1 = rarity index
		
		# Contenedor principal del botón
		var button = Button.new()
		button.custom_minimum_size = Vector2(600, 90)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Determinar si es arma para tratamiento especial
		var is_weapon = (item_type == "weapon" or item_type == "new_weapon" or item_type == "fusion")
		
		# Aplicar estilo inicial usando Helper
		var style_normal = UIVisualHelper.get_panel_style(item_rarity + 1, false, is_weapon)
		var style_hover = UIVisualHelper.get_panel_style(item_rarity + 1, true, is_weapon)
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_hover)
		
		# Si es arma, añadir efecto visual potente
		if is_weapon:
			UIVisualHelper.apply_tier_glow(button, item_rarity + 1)
		
		# Layout interno (HBox)
		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Dejar pasar clicks al botón
		hbox.add_theme_constant_override("separation", 15)
		
		# Margen interno
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 5)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Icono con borde de rareza
		var icon_container_panel = PanelContainer.new()
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = Color(0, 0, 0, 0.3)
		icon_style.border_color = UIVisualHelper.get_color_for_tier(item_rarity + 1)
		icon_style.set_border_width_all(2)
		icon_style.set_corner_radius_all(4)
		icon_container_panel.add_theme_stylebox_override("panel", icon_style)
		
		var icon_tex = null
		if item_id != "":
			var path = "res://assets/icons/%s.png" % item_id
			if ResourceLoader.exists(path):
				icon_tex = load(path)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if icon_tex:
			icon_rect.texture = icon_tex
		else:
			var emoji_lbl = Label.new()
			emoji_lbl.text = item_icon
			emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			emoji_lbl.add_theme_font_size_override("font_size", 32)
			emoji_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.add_child(emoji_lbl)
			
		icon_container_panel.add_child(icon_rect)
		hbox.add_child(icon_container_panel)
		
		# Textos (Nombre + Descripción)
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var name_lbl = Label.new()
		name_lbl.text = item_name
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", UIVisualHelper.get_color_for_tier(item_rarity + 1))
		
		var desc_lbl = Label.new()
		desc_lbl.text = item_desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		
		text_vbox.add_child(name_lbl)
		text_vbox.add_child(desc_lbl)
		
		hbox.add_child(text_vbox)
		margin.add_child(hbox)
		button.add_child(margin)
		
		# Conectar señales
		var item_index = i
		var item_data = item.duplicate()
		button.pressed.connect(func(): _on_button_pressed(item_index, item_data))
		button.mouse_entered.connect(func(): _on_button_hover(item_index))
		
		items_vbox.add_child(button)
		item_buttons.append(button)
	
	# Doble await para renderizado
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Agregar botón de Skip si no es Jackpot
	if not is_jackpot_mode:
		_add_skip_button()
	
	# Inicializar selección visual (mostrar borde en el primer item)
	current_selected_index = 0
	_update_button_selection()
	
	# Reproducir animación de burst si está habilitada
	if _enable_burst_animation and available_items.size() > 0:
		await _play_chest_burst_animation()

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMACIÓN DE CHEST BURST
# ═══════════════════════════════════════════════════════════════════════════════

func set_chest_rarity(rarity: int) -> void:
	"""Establecer rareza del cofre para ajustar intensidad visual"""
	_chest_rarity = clampi(rarity, 1, 5)

func _play_chest_burst_animation() -> void:
	"""Reproducir animación de apertura de cofre espectacular"""
	if _is_animating:
		return
	
	_is_animating = true
	popup_locked = true
	
	var color = BURST_RARITY_COLORS.get(_chest_rarity, Color.WHITE)
	
	# Ocultar todos los items inicialmente
	for btn in item_buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0
			btn.scale = Vector2(0.8, 0.8)
	
	# Fase 1: Shake del popup
	await _shake_popup()
	
	# Fase 2: Flash de luz
	await _flash_screen(color)
	
	# Fase 3: Revelar items secuencialmente
	for i in range(item_buttons.size()):
		if is_instance_valid(item_buttons[i]):
			await _reveal_item_animated(item_buttons[i], i)
	
	_is_animating = false
	popup_locked = false

func _shake_popup() -> void:
	"""Hacer que el popup tiemble antes de revelar"""
	if not _popup_bg:
		_popup_bg = main_control.get_child(1) if main_control.get_child_count() > 1 else null
	
	if not _popup_bg:
		return
	
	var original_pos = _popup_bg.position
	var intensity = 2.0
	
	for i in range(6):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		_popup_bg.position = original_pos + offset
		intensity += 1.0
		await get_tree().create_timer(0.04).timeout
		if not is_instance_valid(self):
			return
	
	_popup_bg.position = original_pos

func _flash_screen(color: Color) -> void:
	"""Crear flash de luz del color de rareza"""
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(color.r, color.g, color.b, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_control.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.5 + (_chest_rarity * 0.1), 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)
	
	await get_tree().create_timer(BURST_DURATION).timeout

func _reveal_item_animated(btn: Control, index: int) -> void:
	"""Revelar un item con animación de entrada"""
	if not is_instance_valid(btn):
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Fade in + scale up con bounce
	tween.tween_property(btn, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.2)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	
	await get_tree().create_timer(ITEM_REVEAL_DELAY).timeout

func _add_skip_button():
	"""Agregar botón de Skip al final de la lista"""
	skip_button = Button.new()
	skip_button.text = "Saltar (Sin Recompensa)"
	skip_button.custom_minimum_size = Vector2(250, 45)
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Estilo sutil/advertencia
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.1, 0.1, 0.8) # Rojo oscuro
	style.border_color = Color(0.8, 0.4, 0.4, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	
	var style_hover = style.duplicate()
	style_hover.bg_color = Color(0.4, 0.15, 0.15, 0.9)
	style_hover.border_color = Color(1.0, 0.5, 0.5, 0.8)
	
	skip_button.add_theme_stylebox_override("normal", style)
	skip_button.add_theme_stylebox_override("hover", style_hover)
	skip_button.add_theme_font_size_override("font_size", 16)
	skip_button.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7))
	
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Añadir un separador antes
	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 10)
	items_vbox.add_child(sep)
	items_vbox.add_child(skip_button)
	
	# Añadir a la lista de navegación
	item_buttons.append(skip_button)

func _on_skip_pressed():
	if popup_locked: return
	_show_confirm_skip_modal()

func _show_confirm_skip_modal():
	"""Mostrar modal de confirmación para saltar recompensa"""
	_is_skip_modal_active = true
	
	var confirm_modal = Control.new()
	confirm_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.z_index = 10 # Encima de todo
	add_child(confirm_modal)
	
	# Bloquear input del fondo
	var blocker = ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.8)
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.add_child(blocker)
	
	# Panel del modal
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 180)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.12, 1.0)
	style.border_color = Color(1.0, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.add_child(center)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_child(vbox)
	panel.add_child(margin)
	
	var label_title = Label.new()
	label_title.text = "⚠️ ¿Saltar Recompensa?"
	label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_title.add_theme_font_size_override("font_size", 22)
	label_title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	vbox.add_child(label_title)
	
	var label_desc = Label.new()
	label_desc.text = "Perderás esta oportunidad de obtener un objeto.\nEl cofre desaparecerá."
	label_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(label_desc)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "Volver"
	btn_cancel.custom_minimum_size = Vector2(100, 40)
	btn_cancel.pressed.connect(func(): 
		_is_skip_modal_active = false
		confirm_modal.queue_free()
	)
	hbox.add_child(btn_cancel)
	
	var btn_confirm = Button.new()
	btn_confirm.text = "Confirmar Salto"
	btn_confirm.custom_minimum_size = Vector2(140, 40)
	var style_confirm = StyleBoxFlat.new()
	style_confirm.bg_color = Color(0.6, 0.2, 0.2)
	style_confirm.set_corner_radius_all(4)
	btn_confirm.add_theme_stylebox_override("normal", style_confirm)
	btn_confirm.pressed.connect(func(): 
		_is_skip_modal_active = false
		skipped.emit()
		queue_free()
	)
	hbox.add_child(btn_confirm)
	
	# Foco inicial
	btn_cancel.grab_focus()

func _on_claim_all_pressed():
	if popup_locked: return
	popup_locked = true
	
	if is_jackpot_mode:
		# En modo jackpot, reclamar todos los pendientes + ya aceptados
		var all_items = _jackpot_claimed_items.duplicate()
		for item in _jackpot_pending_items:
			all_items.append(item)
		all_items_claimed.emit(all_items)
	else:
		all_items_claimed.emit(available_items)
	
	queue_free()

func _on_button_pressed(button_index: int, item_data: Dictionary):
	"""Callback cuando se presiona un botón"""
	if popup_locked or is_jackpot_mode:
		return
	
	# Verificar si es el botón de skip (si se llegara a llamar así, aunque tiene su propio callback)
	if item_buttons[button_index] == skip_button:
		_on_skip_pressed()
		return
		
	_process_item_selection(item_data, button_index)

func _on_button_hover(button_index: int):
	"""Callback cuando el mouse entra en un botón"""
	if is_jackpot_mode: return
	current_selected_index = button_index
	_update_button_selection()

func _process_item_selection(item: Dictionary, button_index: int):
	"""Procesar la selección de item"""
	if popup_locked:
		return
	
	popup_locked = true
	
	current_selected_index = button_index
	_update_button_selection()
	
	# Pequeño delay para ver la selección
	await get_tree().create_timer(0.2).timeout
	
	item_selected.emit(item)
	
	# get_tree().paused = false (Manejado por _exit_tree)
	
	queue_free()



func create_panel_style() -> StyleBox:
	"""Crear estilo para el fondo del popup"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.98)
	style.border_color = Color(0.8, 0.5, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style

func _input(event: InputEvent):
	"""Capturar input para navegación con WASD/Joystick y selección con Space/X"""
	if popup_locked:
		return
		
	if _is_skip_modal_active:
		return

	# En modo jackpot, también permitir navegación WASD para ver items antes de reclamar
	if is_jackpot_mode:
		# Manejar navegación W/S para explorar items (sin seleccionar)
		if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
			_navigate_selection(-1)
			get_tree().root.set_input_as_handled()
			return
		elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
			_navigate_selection(1)
			get_tree().root.set_input_as_handled()
			return
		# Space/Enter activa el botón Claim All
		elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			if claim_button:
				_on_claim_all_pressed()
			get_tree().root.set_input_as_handled()
			return
		return
	
	# === INPUT DE TECLADO Y ACCIONES (WASD / Flechas / Gamepad) ===
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_navigate_selection(-1)
		get_tree().root.set_input_as_handled()
		return
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		_navigate_selection(1)
		get_tree().root.set_input_as_handled()
		return
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if current_selected_index >= 0 and current_selected_index < item_buttons.size():
			_select_item_at_index(current_selected_index)
		get_tree().root.set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				var idx = event.keycode - KEY_1
				if idx < item_buttons.size() - 1: # Excluir skip button si es el ultimo
					_select_item_at_index(idx)
					get_tree().root.set_input_as_handled()
			
			KEY_ENTER:
				if current_selected_index >= 0 and current_selected_index < item_buttons.size():
					_select_item_at_index(current_selected_index)
				get_tree().root.set_input_as_handled()
			
			KEY_ESCAPE:
				get_tree().root.set_input_as_handled()
	
	# === INPUT DE GAMEPAD (Joystick / Botones) ===
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate_selection(-1)
				get_tree().root.set_input_as_handled()
			JOY_BUTTON_DPAD_DOWN:
				_navigate_selection(1)
				get_tree().root.set_input_as_handled()
			JOY_BUTTON_A:
				if current_selected_index >= 0 and current_selected_index < item_buttons.size():
					_select_item_at_index(current_selected_index)
				get_tree().root.set_input_as_handled()
	
	# === JOYSTICK ANALÓGICO ===
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate_selection(-1)
				get_tree().root.set_input_as_handled()
			elif event.axis_value > 0.5:
				_navigate_selection(1)
				get_tree().root.set_input_as_handled()

func _navigate_selection(direction: int):
	"""Navegar la selección arriba (-1) o abajo (+1)"""
	if item_buttons.is_empty():
		return
	
	current_selected_index += direction
	
	# Wrap around
	if current_selected_index < 0:
		current_selected_index = item_buttons.size() - 1
	elif current_selected_index >= item_buttons.size():
		current_selected_index = 0
	
	_update_button_selection()

func _select_item_at_index(index: int):
	"""Seleccionar un item por índice (desde teclado/gamepad)"""
	if popup_locked: return
	
	if index >= 0 and index < item_buttons.size():
		var btn = item_buttons[index]
		
		# Simular click visual
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.05)
		
		if btn == skip_button:
			_on_skip_pressed()
			return
			
		if index < available_items.size():
			var selected_item = available_items[index]
			_process_item_selection(selected_item, index)

func _update_button_selection():
	"""Actualizar estilos visuales según selección con aura brillante"""
	if is_jackpot_mode: return
	for i in range(item_buttons.size()):
		var btn = item_buttons[i]
		if not is_instance_valid(btn): continue
			
		var is_selected = (i == current_selected_index)
		
		# Escala suave
		var target_scale = Vector2(1.02, 1.02) if is_selected else Vector2(1.0, 1.0)
		var tween = create_tween()
		tween.tween_property(btn, "scale", target_scale, 0.1)
		
		# Borde brillante (Glow)
		var glow_panel = btn.get_node_or_null("SelectionGlow")
		if not glow_panel:
			glow_panel = Panel.new()
			glow_panel.name = "SelectionGlow"
			glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			var glow_style = StyleBoxFlat.new()
			glow_style.bg_color = Color(0, 0, 0, 0)
			glow_style.border_color = Color(1.0, 0.9, 0.4, 1.0) # Dorado
			glow_style.set_border_width_all(4)
			glow_style.set_corner_radius_all(8)
			glow_style.set_expand_margin_all(4)
			glow_panel.add_theme_stylebox_override("panel", glow_style)
			btn.add_child(glow_panel)
			btn.move_child(glow_panel, 0)
		
		glow_panel.visible = is_selected


