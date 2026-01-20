# ShopChestPopup.gd
# UI para cofres tipo tienda - muestra items con precios y permite comprar
# Incluye sistema de descuentos, validación de monedas, y modal de confirmación

extends CanvasLayer
class_name ShopChestPopup

signal item_purchased(item: Dictionary, final_price: int)
signal popup_closed(purchased: bool)

# === ESTADO ===
var available_items: Array = []
var player_coins: int = 0
var current_selected_index: int = -1
var popup_locked: bool = false
var showing_confirm_modal: bool = false

# === REFERENCIAS UI ===
var main_control: Control
var items_container: VBoxContainer
var coins_label: Label
var exit_button: Button
var confirm_modal: Control
var item_buttons: Array[Control] = []

# Modal navigation
var modal_cancel_btn: Button = null
var modal_confirm_btn: Button = null
var modal_selected_index: int = 0  # 0 = Cancel, 1 = Confirm

# === COLORES POR TIER ===
const TIER_COLORS = {
	1: Color(0.7, 0.7, 0.7),      # Gris (Común)
	2: Color(0.3, 0.7, 0.3),      # Verde (Poco común)
	3: Color(0.3, 0.5, 0.9),      # Azul (Raro)
	4: Color(0.7, 0.3, 0.9),      # Púrpura (Épico)
	5: Color(1.0, 0.7, 0.2)       # Dorado (Legendario)
}

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true  # Pausar juego
	set_process_input(true)
	
	_build_ui()

func _input(event: InputEvent) -> void:
	"""Manejar input de teclado para navegación WASD y bloqueo de ESC"""
	if not is_inside_tree():
		return
	
	if popup_locked:
		return
	
	# Si el modal de confirmación está visible, manejar navegación del modal
	if showing_confirm_modal:
		if event.is_action_pressed("ui_cancel"):  # ESC
			# Cancelar y cerrar modal
			get_viewport().set_input_as_handled()
			_on_confirm_cancel()
			return
		
		if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
			get_viewport().set_input_as_handled()
			modal_selected_index = 0
			_update_modal_selection()
			return
		
		if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			modal_selected_index = 1
			_update_modal_selection()
			return
		
		if event.is_action_pressed("ui_accept"):  # Space/Enter
			get_viewport().set_input_as_handled()
			if modal_selected_index == 0:
				_on_confirm_cancel()
			else:
				_on_confirm_exit()
			return
		return  # Block all other input while modal shown
	
	# Navegación normal del popup de tienda
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_viewport().set_input_as_handled()
		_on_exit_pressed()  # Mostrar modal de confirmación
		return
	
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_navigate_selection(-1)
		return
	
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_navigate_selection(1)
		return
	
	if event.is_action_pressed("ui_accept"):  # Space/Enter
		get_viewport().set_input_as_handled()
		_activate_selection()
		return

func _update_modal_selection() -> void:
	"""Actualizar visual de selección en modal"""
	var buttons = [modal_cancel_btn, modal_confirm_btn]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn == null:
			continue
		
		if i == modal_selected_index:
			btn.modulate = Color(1.2, 1.2, 1.2)
			
			# Añadir borde brillante
			var style = StyleBoxFlat.new()
			style.set_corner_radius_all(4) # Use 4 for consistency with other buttons
			style.set_border_width_all(2)
			
			# Usar color distintivo para confirmar (verde) vs cancelar (rojo)
			if btn == modal_confirm_btn:
				style.bg_color = Color(0.2, 0.5, 0.2) # Darker green background
				style.border_color = Color(0.4, 1.0, 0.4) # Bright green border
			else: # modal_cancel_btn
				style.bg_color = Color(0.5, 0.2, 0.2) # Darker red background
				style.border_color = Color(1.0, 0.4, 0.4) # Bright red border
				
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)
			btn.remove_theme_stylebox_override("normal")

func _build_ui():
	"""Construir toda la interfaz"""
	# Control principal
	main_control = Control.new()
	main_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(main_control)
	
	# Fondo oscuro
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.7)
	bg.add_theme_stylebox_override("panel", bg_style)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_control.add_child(bg)
	
	# Panel principal centrado
	var popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(500, 400)
	popup_panel.set_anchors_preset(Control.PRESET_CENTER)
	popup_panel.add_theme_stylebox_override("panel", _create_panel_style())
	main_control.add_child(popup_panel)
	
	# Layout vertical
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	popup_panel.add_child(vbox)
	
	# Margen
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(inner_vbox)
	
	# Header con título y monedas
	var header = HBoxContainer.new()
	inner_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "🎁 COFRE DE TESOROS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	coins_label = Label.new()
	coins_label.text = "🪙 0"
	coins_label.add_theme_font_size_override("font_size", 20)
	coins_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	header.add_child(coins_label)
	
	# Separador
	var sep = HSeparator.new()
	inner_vbox.add_child(sep)
	
	# Contenedor de items (scrollable)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(scroll)
	
	# WRAPPER con padding para evitar clipping de bordes/glow
	# Este margen garantiza que los efectos visuales (bordes, glows, sombras)
	# nunca se corten independientemente del tamaño del contenido
	var items_wrapper = MarginContainer.new()
	items_wrapper.add_theme_constant_override("margin_left", 8)
	items_wrapper.add_theme_constant_override("margin_right", 8)
	items_wrapper.add_theme_constant_override("margin_top", 6)
	items_wrapper.add_theme_constant_override("margin_bottom", 6)
	items_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_wrapper)
	
	items_container = VBoxContainer.new()
	items_container.add_theme_constant_override("separation", 12)  # Más espacio entre items
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_wrapper.add_child(items_container)
	
	# Botón salir
	exit_button = Button.new()
	exit_button.text = "❌ Salir sin comprar"
	exit_button.custom_minimum_size = Vector2(0, 45)
	exit_button.pressed.connect(_on_exit_pressed)
	_style_exit_button(exit_button)
	inner_vbox.add_child(exit_button)
	
	# Modal de confirmación (oculto inicialmente)
	_build_confirm_modal()
	
	# Centrar popup después de un frame
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	popup_panel.position = (screen_size - popup_panel.size) / 2

func _build_confirm_modal():
	"""Construir modal de confirmación para salir"""
	confirm_modal = Control.new()
	confirm_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.visible = false
	confirm_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirm_modal)
	
	# Fondo más oscuro
	var modal_bg = PanelContainer.new()
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	modal_bg.add_theme_stylebox_override("panel", style)
	confirm_modal.add_child(modal_bg)
	
	# Panel del modal
	var modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(350, 150)
	modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.1, 0.1, 0.98)
	panel_style.border_color = Color(0.8, 0.3, 0.2)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	modal_panel.add_theme_stylebox_override("panel", panel_style)
	confirm_modal.add_child(modal_panel)
	
	var modal_vbox = VBoxContainer.new()
	modal_vbox.add_theme_constant_override("separation", 20)
	modal_panel.add_child(modal_vbox)
	
	var modal_margin = MarginContainer.new()
	modal_margin.add_theme_constant_override("margin_left", 20)
	modal_margin.add_theme_constant_override("margin_right", 20)
	modal_margin.add_theme_constant_override("margin_top", 20)
	modal_margin.add_theme_constant_override("margin_bottom", 20)
	modal_vbox.add_child(modal_margin)
	
	var modal_inner = VBoxContainer.new()
	modal_inner.add_theme_constant_override("separation", 15)
	modal_margin.add_child(modal_inner)
	
	var warn_label = Label.new()
	warn_label.text = "⚠️ ¿Seguro que quieres salir?\nEl cofre desaparecerá."
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.add_theme_font_size_override("font_size", 16)
	modal_inner.add_child(warn_label)
	
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 20)
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_inner.add_child(buttons_hbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(100, 35)
	cancel_btn.pressed.connect(_on_confirm_cancel)
	buttons_hbox.add_child(cancel_btn)
	modal_cancel_btn = cancel_btn  # Store reference
	
	var confirm_btn = Button.new()
	confirm_btn.text = "Salir"
	confirm_btn.custom_minimum_size = Vector2(100, 35)
	confirm_btn.pressed.connect(_on_confirm_exit)
	var confirm_style = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.6, 0.2, 0.2)
	confirm_style.set_corner_radius_all(4)
	confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	buttons_hbox.add_child(confirm_btn)
	modal_confirm_btn = confirm_btn  # Store reference

func setup_shop(items: Array, coins: int):
	"""Configurar la tienda con items y monedas del jugador"""
	available_items = items
	player_coins = coins
	
	coins_label.text = "🪙 %d" % coins
	
	# Limpiar items previos
	for child in items_container.get_children():
		child.queue_free()
	item_buttons.clear()
	
	await get_tree().process_frame
	
	# Crear botones de items
	for i in range(items.size()):
		var item = items[i]
		var item_btn = _create_item_button(item, i)
		items_container.add_child(item_btn)
		item_buttons.append(item_btn)
	
	await get_tree().process_frame
	
	# Inicializar selección visual (mostrar borde en el primer item)
	current_selected_index = 0
	if item_buttons.size() > 0:
		item_buttons[0].grab_focus()
	_update_selection_visuals()

func _create_item_button(item: Dictionary, index: int) -> Control:
	"""Crear botón de item con icono, nombre, descripción y precio"""
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(380, 70) # Reducido para evitar recorte en margen derecho
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_ALL # Permitir foco por teclado/gamepad
	
	var price = item.get("price", 100)
	var original_price = item.get("original_price", price)
	var discount = item.get("discount_percent", 0)
	var tier = item.get("tier", 1)
	var can_afford = player_coins >= price
	
	# Estilo según asequibilidad
	_style_item_button(btn, tier, can_afford, discount > 0)
	
	# Layout interno
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Icono
	var icon_container = TextureRect.new()
	icon_container.custom_minimum_size = Vector2(48, 48)
	icon_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_str = item.get("icon", "❓")
	var icon_lbl = Label.new()
	icon_lbl.text = icon_str
	icon_lbl.add_theme_font_size_override("font_size", 32)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_container.add_child(icon_lbl)
	hbox.add_child(icon_container)
	
	# Info (nombre + descripción)
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var name_lbl = Label.new()
	name_lbl.text = item.get("name", "Item Desconocido")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", TIER_COLORS.get(tier, Color.WHITE))
	info_vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = item.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_lbl)
	
	hbox.add_child(info_vbox)
	
	# Precio
	var price_vbox = VBoxContainer.new()
	price_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	price_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if discount > 0:
		# Precio original tachado
		var orig_lbl = Label.new()
		orig_lbl.text = "🪙 %d" % original_price
		orig_lbl.add_theme_font_size_override("font_size", 12)
		orig_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		# Simular tachado con strikethrough
		orig_lbl.modulate.a = 0.6
		price_vbox.add_child(orig_lbl)
		
		# Descuento label
		var disc_lbl = Label.new()
		disc_lbl.text = "-%d%%" % discount
		disc_lbl.add_theme_font_size_override("font_size", 10)
		disc_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		price_vbox.add_child(disc_lbl)
	
	var price_lbl = Label.new()
	price_lbl.text = "🪙 %d" % price
	price_lbl.add_theme_font_size_override("font_size", 16)
	if can_afford:
		price_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	else:
		price_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	price_vbox.add_child(price_lbl)
	
	hbox.add_child(price_vbox)
	margin.add_child(hbox)
	btn.add_child(margin)
	
	# Conectar señal
	var item_data = item.duplicate()
	btn.pressed.connect(func(): _on_item_pressed(index, item_data))
	
	# Conectar señales de foco para feedback visual
	btn.focus_entered.connect(func(): _on_item_focus_entered(btn))
	btn.focus_exited.connect(func(): _on_item_focus_exited(btn))
	
	return btn

func _on_item_focus_entered(btn: Button) -> void:
	"""Feedback visual cuando el botón recibe foco"""
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
	btn.modulate = Color(1.2, 1.2, 1.2) # Brillo extra

func _on_item_focus_exited(btn: Button) -> void:
	"""Restaurar estado cuando pierde foco"""
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	btn.modulate = Color.WHITE

func _on_item_pressed(index: int, item: Dictionary):
	"""Usuario presionó un item"""
	if popup_locked or showing_confirm_modal:
		return
	
	var price = item.get("price", 100)
	
	if player_coins < price:
		# No tiene suficientes monedas - feedback visual
		_show_insufficient_funds_feedback(index)
		return
	
	# Compra exitosa
	popup_locked = true
	player_coins -= price
	coins_label.text = "🪙 %d" % player_coins
	
	# Efecto visual de compra
	if index < item_buttons.size():
		var btn = item_buttons[index]
		var tween = create_tween()
		tween.tween_property(btn, "modulate", Color(0.2, 1.0, 0.2), 0.2)
		tween.tween_property(btn, "modulate", Color.WHITE, 0.2)
	
	await get_tree().create_timer(0.4).timeout
	
	item_purchased.emit(item, price)
	_close_popup(true)

func _show_insufficient_funds_feedback(index: int):
	"""Mostrar feedback de fondos insuficientes"""
	if index >= item_buttons.size():
		return
	
	var btn = item_buttons[index]
	var tween = create_tween()
	tween.tween_property(btn, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.1)
	tween.tween_property(btn, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.1)

func _on_exit_pressed():
	"""Usuario quiere salir"""
	if popup_locked:
		return
	
	# Mostrar modal de confirmación
	showing_confirm_modal = true
	confirm_modal.visible = true

func _on_confirm_cancel():
	"""Cancelar salida"""
	showing_confirm_modal = false
	confirm_modal.visible = false

func _on_confirm_exit():
	"""Confirmar salida sin comprar"""
	_close_popup(false)

func _close_popup(purchased: bool):
	"""Cerrar popup y notificar"""
	get_tree().paused = false
	popup_closed.emit(purchased)
	queue_free()



# === ESTILOS ===

func _create_panel_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.98)
	style.border_color = Color(0.7, 0.5, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	return style

func _style_item_button(btn: Button, tier: int, can_afford: bool, has_discount: bool):
	var style_normal = StyleBoxFlat.new()
	var base_color = Color(0.15, 0.15, 0.15) if can_afford else Color(0.1, 0.08, 0.08)
	style_normal.bg_color = base_color
	style_normal.border_color = TIER_COLORS.get(tier, Color.WHITE) * (1.0 if can_afford else 0.5)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(6)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = base_color.lightened(0.1)
	style_hover.border_color = style_normal.border_color.lightened(0.2)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = base_color.lightened(0.2)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	if not can_afford:
		btn.modulate = Color(0.7, 0.7, 0.7)

func _style_exit_button(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.15, 0.15)
	style.border_color = Color(0.6, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.4, 0.2, 0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
# ═══════════════════════════════════════════════════════════════════════════════
# NAVEGACIÓN HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _navigate_selection(direction: int):
	"""Navegar selección (incluye botón de salir como última opción)"""
	var total_items = item_buttons.size()
	# exit_button es el índice 'total_items'
	var max_index = total_items # (items 0..n-1 + exit n)
	
	if current_selected_index < 0:
		current_selected_index = 0
	else:
		current_selected_index += direction
	
	# Wrap around
	if current_selected_index < 0:
		current_selected_index = max_index
	elif current_selected_index > max_index:
		current_selected_index = 0
		
	_update_selection_visuals()
	
	# Scroll automático
	if current_selected_index < total_items:
		_ensure_visible(item_buttons[current_selected_index])
	else:
		_ensure_visible(exit_button)

func _activate_selection():
	"""Activar elemento seleccionado"""
	var total_items = item_buttons.size()
	
	if current_selected_index == total_items:
		# Botón salir
		_on_exit_pressed()
	elif current_selected_index >= 0 and current_selected_index < total_items:
		# Item
		# Simular click en el botón (que llama a _on_item_pressed)
		item_buttons[current_selected_index].pressed.emit()

func _update_selection_visuals():
	"""Actualizar feedback visual de selección con aura brillante"""
	for i in range(item_buttons.size()):
		var btn = item_buttons[i]
		var is_selected = (i == current_selected_index)
		
		# Buscar o crear el panel de glow
		var glow_panel = btn.get_node_or_null("SelectionGlow")
		if not glow_panel:
			glow_panel = Panel.new()
			glow_panel.name = "SelectionGlow"
			glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			# Estilo del glow dorado brillante
			var glow_style = StyleBoxFlat.new()
			glow_style.bg_color = Color(0, 0, 0, 0)  # Transparente
			glow_style.border_color = Color(1.0, 0.85, 0.2, 1.0)  # Dorado brillante
			glow_style.set_border_width_all(5)  # Borde grueso
			glow_style.set_corner_radius_all(10)
			glow_style.set_expand_margin_all(4)  # Expande hacia afuera
			glow_panel.add_theme_stylebox_override("panel", glow_style)
			btn.add_child(glow_panel)
			btn.move_child(glow_panel, 0)  # Mover al fondo
		
		# Mostrar u ocultar
		glow_panel.visible = is_selected
		btn.modulate = Color(1.15, 1.15, 1.05) if is_selected else Color.WHITE
		btn.scale = Vector2(1.02, 1.02) if is_selected else Vector2(1.0, 1.0)
			
	# Botón salir
	var exit_selected = (current_selected_index == item_buttons.size())
	
	# Buscar o crear glow del botón exit
	var exit_glow = exit_button.get_node_or_null("SelectionGlow")
	if not exit_glow:
		exit_glow = Panel.new()
		exit_glow.name = "SelectionGlow"
		exit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		exit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		var exit_style = StyleBoxFlat.new()
		exit_style.bg_color = Color(0, 0, 0, 0)
		exit_style.border_color = Color(1.0, 0.4, 0.2, 1.0)  # Naranja-rojo
		exit_style.set_border_width_all(5)
		exit_style.set_corner_radius_all(8)
		exit_style.set_expand_margin_all(4)
		exit_glow.add_theme_stylebox_override("panel", exit_style)
		exit_button.add_child(exit_glow)
		exit_button.move_child(exit_glow, 0)
	
	exit_glow.visible = exit_selected
	exit_button.modulate = Color(1.2, 1.1, 1.0) if exit_selected else Color.WHITE
	exit_button.scale = Vector2(1.02, 1.02) if exit_selected else Vector2(1.0, 1.0)

func _ensure_visible(control: Control):
	"""Asegurar que el control es visible en el scroll"""
	# Implementación simple: si está muy abajo/arriba, ajustar scroll_vertical
	# TODO: Mejorar lógica de scroll
	pass
