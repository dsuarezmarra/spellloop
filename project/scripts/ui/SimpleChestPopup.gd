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
var _did_increment: bool = false

func _enter_tree():
	# Pause is now handled by UIManager if used via request_popup
	# Legacy fallback:
	if not get_tree().root.has_node("UIManager") or not get_tree().root.get_node("UIManager").is_modal_open:
		active_instances += 1
		_did_increment = true
		get_tree().paused = true

func _exit_tree():
	# Solo decrementar si esta instancia incrementó el contador
	if _did_increment:
		active_instances -= 1
		_did_increment = false
		if active_instances <= 0:
			active_instances = 0
			get_tree().paused = false

func _ready():
	add_to_group("chest_popup")
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
	title.text = Localization.L("ui.chest.title")
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
	# Inicializar selección
	current_selected_index = 0

	# Restaurar estado si fue configurado antes de _ready
	if is_jackpot_mode:
		show_as_jackpot(_jackpot_pending_items)
	elif not available_items.is_empty():
		setup_items(available_items)

	_update_jackpot_selection()

func _input(event: InputEvent) -> void:
	"""Manejar input manual para navegación robusta (WASD/Flechas) - Soporta Jackpot y Standard"""
	if not is_inside_tree() or popup_locked or not visible:
		return

	# 1. Logic para Modal de Skip (Legacy)
	if _is_skip_modal_active:
		if _modal_btn_cancel and _modal_btn_confirm and event.is_pressed():
			if event.is_action("ui_left") or (event is InputEventKey and (event.keycode == KEY_A or event.keycode == KEY_LEFT)):
				_modal_btn_cancel.grab_focus()
				AudioManager.play("sfx_ui_navigation")
				get_tree().root.set_input_as_handled()
			elif event.is_action("ui_right") or (event is InputEventKey and (event.keycode == KEY_D or event.keycode == KEY_RIGHT)):
				_modal_btn_confirm.grab_focus()
				AudioManager.play("sfx_ui_navigation")
				get_tree().root.set_input_as_handled()
			elif event.is_action("ui_accept") or (event is InputEventKey and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
				# Activar el botón con focus
				var focused = get_viewport().gui_get_focus_owner()
				if focused == _modal_btn_cancel:
					_modal_btn_cancel.emit_signal("pressed")
				elif focused == _modal_btn_confirm:
					_modal_btn_confirm.emit_signal("pressed")
				get_tree().root.set_input_as_handled()
		return

	# Solo actuar si el input es presionado
	if not event.is_pressed():
		return

	# Detección de acciones de navegación
	var up = event.is_action("ui_up") or event.is_action("move_up") or (event is InputEventKey and event.keycode == KEY_W)
	var down = event.is_action("ui_down") or event.is_action("move_down") or (event is InputEventKey and event.keycode == KEY_S)
	var left = event.is_action("ui_left") or event.is_action("move_left") or (event is InputEventKey and event.keycode == KEY_A)
	var right = event.is_action("ui_right") or event.is_action("move_right") or (event is InputEventKey and event.keycode == KEY_D)
	var accept = event.is_action("ui_accept") or (event is InputEventKey and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER))
	var cancel = event.is_action("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE)

	if not (up or down or left or right or accept or cancel):
		return

	# 2. STANDARD MODE (Legacy logic)
	if not is_jackpot_mode:
		if up:
			_navigate_selection(-1)
			get_tree().root.set_input_as_handled()
		elif down:
			_navigate_selection(1)
			get_tree().root.set_input_as_handled()
		elif accept:
			if current_selected_index >= 0 and current_selected_index < item_buttons.size():
				_select_item_at_index(current_selected_index)
			get_tree().root.set_input_as_handled()
		return

	# 3. JACKPOT MODE (New robust logic)
	# IMPORTANT: Do not consume input immediately if we want to allow child controls to handle it?
	# Acts as filter.

	# === LOGICA DE NAVEGACIÓN JACKPOT ===
	var total_items = item_buttons.size()

	# Determinar si estamos en botones de abajo
	# Definimos indices virtuales para los botones de abajo:
	# N = Claim All, N+1 = Claim Selected (si visible), N+2 = Exit
	var idx_claim = total_items
	var idx_claim_sel = total_items + 1
	var idx_exit = total_items + 2

	# Revisar visibilidad de "Claim Selected" para ajustar navegación
	var claim_sel_btn = get_meta("claim_selected_btn", null)
	var has_claim_sel = (claim_sel_btn and claim_sel_btn.visible)

	var input_handled = false

	# Moverse
	if up:
		AudioManager.play("sfx_ui_navigation")
		if current_selected_index >= idx_claim:
			# Desde botones de abajo -> ir al último item
			current_selected_index = total_items - 1
		else:
			# En lista de items -> mover arriba
			current_selected_index -= 1
			if current_selected_index < 0:
				current_selected_index = 0 # Stay at top
		_update_jackpot_selection()
		input_handled = true

	elif down:
		AudioManager.play("sfx_ui_navigation")
		if current_selected_index < total_items - 1:
			# En lista de items -> mover abajo
			current_selected_index += 1
		elif current_selected_index == total_items - 1:
			# Del último item -> al primer botón de acción (Claim)
			current_selected_index = idx_claim
		else:
			# En botones de abajo -> stay
			pass
		_update_jackpot_selection()
		input_handled = true

	elif left or right:
		AudioManager.play("sfx_ui_navigation")
		# Navegación horizontal SOLO para botones de abajo
		if current_selected_index >= total_items:
			if has_claim_sel:
				# Layout: [Claim All] [Claim Selected] [Exit]
				# indices: idx_claim, idx_claim_sel, idx_exit
				# Haremos ciclico simple entre ellos
				var buttons = [idx_claim, idx_claim_sel, idx_exit]
				var current_pos = buttons.find(current_selected_index)
				if current_pos != -1:
					var dir = -1 if left else 1
					var new_pos = wrapi(current_pos + dir, 0, buttons.size())
					current_selected_index = buttons[new_pos]
			else:
				# Layout: [Claim All] [Exit]
				if current_selected_index == idx_claim:
					current_selected_index = idx_exit
				else:
					current_selected_index = idx_claim
			_update_jackpot_selection()
			input_handled = true

	elif accept:
		AudioManager.play("sfx_ui_confirm")
		_trigger_selection()
		input_handled = true

	elif cancel:
		AudioManager.play("sfx_ui_cancel")
		_on_jackpot_exit_pressed()
		input_handled = true

	if input_handled:
		get_viewport().set_input_as_handled()

func _trigger_selection():
	"""Ejecutar acción del elemento seleccionado"""
	var total_items = item_buttons.size()
	var idx_claim = total_items
	var idx_claim_sel = total_items + 1
	var idx_exit = total_items + 2

	if current_selected_index < total_items:
		# Toggle item selection
		var btn = item_buttons[current_selected_index]
		# Simular logica de toggle
		var item_data = btn.get_meta("item_data")
		_on_jackpot_item_pressed(current_selected_index, item_data)
	elif current_selected_index == idx_claim:
		if claim_button: claim_button.pressed.emit()
	elif current_selected_index == idx_claim_sel:
		var btn = get_meta("claim_selected_btn", null)
		if btn: btn.pressed.emit()
	elif current_selected_index == idx_exit:
		pass # El botón de exit es especial, tiene su referencia local en setup
		# Necesitamos buscarlo o invocar _on_jackpot_exit_pressed directo
		_on_jackpot_exit_pressed()

func _update_jackpot_selection():
	"""Actualizar visuales de selección (Border/Glow)"""
	var total_items = item_buttons.size()

	# 1. Resetear visuales de items
	for i in range(total_items):
		var panel = item_buttons[i]
		if not is_instance_valid(panel): continue

		# Buscar o crear glow visual
		var glow = panel.get_node_or_null("SelectionGlow")
		if not glow:
			glow = _create_glow_panel()
			panel.add_child(glow)

		glow.visible = (i == current_selected_index)
		panel.modulate = Color(1.1, 1.1, 1.1) if (i == current_selected_index) else Color.WHITE
		panel.scale = Vector2(1.02, 1.02) if (i == current_selected_index) else Vector2.ONE

	# 2. Resetear visuales de botones de abajo
	var btns = [claim_button, get_meta("claim_selected_btn", null)]
	# Buscamos el boton Exit en la jerarguia (ultimo hijo de buttons_hbox)
	if _main_vbox.get_child_count() > 0:
		var hbox = _main_vbox.get_child(_main_vbox.get_child_count()-1)
		if hbox is HBoxContainer:
			for child in hbox.get_children():
				if child.text.contains("SALIR"):
					btns.append(child)

	var idx_claim = total_items
	var idx_claim_sel = total_items + 1
	var idx_exit = total_items + 2 # Ojo con logica

	# Mapeo de botones a indices
	var btn_indices = {}
	if claim_button: btn_indices[claim_button] = idx_claim
	var c_sel = get_meta("claim_selected_btn", null)
	if c_sel: btn_indices[c_sel] = idx_claim_sel
	# El de salir es tricky encontrarlo, asumimos que es el ultimo append en btns (index 2 si hay 3, index 1 si hay 2)
	# Mejor logica: iterar btns y checkear indices

	# Simplificacion: comprobar cada caso
	_highlight_button(claim_button, current_selected_index == idx_claim)

	var c_sel_btn = get_meta("claim_selected_btn", null)
	if c_sel_btn:
		_highlight_button(c_sel_btn, current_selected_index == idx_claim_sel)

	# Encontrar exit btn
	var exit_btn = null
	if _main_vbox.get_child_count() > 0:
		var last_child = _main_vbox.get_children().back()
		if last_child is HBoxContainer:
			for c in last_child.get_children():
				if "SALIR" in c.text:
					exit_btn = c
	if exit_btn:
		_highlight_button(exit_btn, current_selected_index == idx_exit)

func _create_glow_panel() -> Panel:
	var p = Panel.new()
	p.name = "SelectionGlow"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(1, 0.8, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.set_expand_margin_all(5)
	p.add_theme_stylebox_override("panel", style)
	return p

func _highlight_button(btn: Button, selected: bool):
	if not btn: return
	var glow = btn.get_node_or_null("SelectionGlow")
	if not glow:
		glow = _create_glow_panel()
		btn.add_child(glow)
	glow.visible = selected
	btn.modulate = Color(1.2, 1.2, 1.2) if selected else Color.WHITE
	btn.scale = Vector2(1.05, 1.05) if selected else Vector2.ONE

func show_as_jackpot(items: Array):
	"""Mostrar modo Jackpot (múltiples premios) - Items seleccionables individualmente"""
	is_jackpot_mode = true
	_jackpot_pending_items = items.duplicate()
	_jackpot_claimed_items = []

	# Si no estamos listos (sin UI), diferir para _ready
	if not _main_vbox:
		return
	for child in _main_vbox.get_children():
		if child is Label:
			child.text = Localization.L("ui.chest.legendary_reward")
			child.modulate = Color(1, 0.8, 0.2) # Dorado
			break

	# Crear items con botones de aceptar/rechazar
	_setup_jackpot_items(items)

	# Contenedor para botones de acción al final
	# Buscar si ya existe para evitar duplicados
	var buttons_hbox = null
	for child in _main_vbox.get_children():
		if child is HBoxContainer and child.get_child_count() > 0 and child.get_child(0) is Button:
			buttons_hbox = child
			# Limpiar botones anteriores si existen
			for btn in buttons_hbox.get_children():
				btn.queue_free()
			break

	if not buttons_hbox:
		buttons_hbox = HBoxContainer.new()
		buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		buttons_hbox.add_theme_constant_override("separation", 20)
		_main_vbox.add_child(buttons_hbox)

	# Botón Reclamar Todo
	claim_button = Button.new()
	var claim_text = Localization.L("ui.chest.claim_all")
	claim_button.text = "✓ " + claim_text.to_upper()
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
	claim_button.focus_mode = Control.FOCUS_NONE # Desactivar foco automático para usar navegación manual
	buttons_hbox.add_child(claim_button)

	# Botón Reclamar Seleccionados (Nuevo)
	var claim_selected_btn = Button.new()
	var claim_sel_text = Localization.L("ui.chest.claim_selected")

	claim_selected_btn.text = "✓ " + claim_sel_text.to_upper()
	claim_selected_btn.custom_minimum_size = Vector2(240, 50)
	claim_selected_btn.add_theme_font_size_override("font_size", 16)
	claim_selected_btn.visible = false # Oculto por defecto, se muestra si hay selección parcial
	claim_selected_btn.focus_mode = Control.FOCUS_NONE # Desactivar foco automático

	var style_sel = StyleBoxFlat.new()
	style_sel.bg_color = Color(0.15, 0.3, 0.4)
	style_sel.border_color = Color(0.4, 0.8, 1.0)
	style_sel.set_border_width_all(2)
	style_sel.set_corner_radius_all(8)
	claim_selected_btn.add_theme_stylebox_override("normal", style_sel)

	var style_sel_hover = style_sel.duplicate()
	style_sel_hover.bg_color = Color(0.2, 0.4, 0.5)
	claim_selected_btn.add_theme_stylebox_override("hover", style_sel_hover)

	# Conectar a función de terminar selección
	claim_selected_btn.pressed.connect(_on_claim_selected_pressed)
	buttons_hbox.add_child(claim_selected_btn)

	# Guardar referencia para actualizar visibilidad
	self.set_meta("claim_selected_btn", claim_selected_btn)

	# Botón Salir (con confirmación)
	var exit_button = Button.new()
	var exit_text = Localization.L("ui.chest.exit") if Localization.has_method("L") else "SALIR"
	exit_button.text = "✕ " + exit_text.to_upper()
	exit_button.custom_minimum_size = Vector2(150, 50)
	exit_button.add_theme_font_size_override("font_size", 16)
	exit_button.focus_mode = Control.FOCUS_ALL  # Permitir focus

	var style_exit = StyleBoxFlat.new()
	style_exit.bg_color = Color(0.3, 0.15, 0.15)
	style_exit.border_color = Color(0.7, 0.3, 0.3)
	style_exit.set_border_width_all(2)
	style_exit.set_corner_radius_all(8)
	exit_button.add_theme_stylebox_override("normal", style_exit)

	var style_exit_hover = style_exit.duplicate()
	style_exit_hover.bg_color = Color(0.5, 0.25, 0.25)
	style_exit_hover.border_color = Color(1.0, 0.5, 0.3)
	style_exit_hover.set_border_width_all(3)
	exit_button.add_theme_stylebox_override("hover", style_exit_hover)
	exit_button.add_theme_stylebox_override("focus", style_exit_hover)

	exit_button.pressed.connect(_on_jackpot_exit_pressed)
	exit_button.mouse_entered.connect(func(): AudioManager.play("sfx_ui_navigation"))
	buttons_hbox.add_child(exit_button)

	# Recentrar popup
	await get_tree().process_frame
	_recenter_popup()

	# Inicializar selección visual en el primer item
	current_selected_index = 0
	if item_buttons.size() > 0:
		_update_jackpot_selection()

func _setup_jackpot_items(items: Array):
	"""Crear items para modo jackpot con botones de aceptar/rechazar"""
	available_items = items
	item_buttons.clear()

	# Limpiar items previos
	for child in items_vbox.get_children():
		child.queue_free()
		items_vbox.remove_child(child) # Force removal from tree immediately

	# Removed dangerous await that caused duplication race conditions
	# await get_tree().process_frame

	for i in range(items.size()):
		var item = items[i]
		var item_panel = _create_jackpot_item_panel(item, i)
		items_vbox.add_child(item_panel)
		item_buttons.append(item_panel)

func _create_jackpot_item_panel(item: Dictionary, index: int) -> Control:
	"""Crear panel de item para jackpot (sin botones individuales, navegación WASD + Space)"""
	var item_name = item.get("name", Localization.L("ui.chest.unknown_item"))
	var item_desc = item.get("description", Localization.L("ui.chest.no_description"))
	var item_icon = item.get("icon", "❓")
	var item_id = item.get("id", "")
	var item_type = item.get("type", "upgrade")
	var item_rarity = item.get("rarity", item.get("tier", 1) - 1)
	var is_weapon = (item_type == "weapon" or item_type == "new_weapon" or item_type == "fusion")

	# Panel contenedor principal
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 80)

	# Guardar datos del item en metadata para referencia
	panel.set_meta("item_data", item.duplicate())
	panel.set_meta("item_index", index)
	panel.set_meta("is_claimed", false)

	var panel_style = UIVisualHelper.get_panel_style(item_rarity + 1, false, is_weapon)
	panel.add_theme_stylebox_override("panel", panel_style)

	if is_weapon:
		UIVisualHelper.apply_tier_glow(panel, item_rarity + 1)

	# HBox principal
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	# Input handling para click de ratón
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("sfx_ui_confirm")
			_on_jackpot_item_pressed(index, item.duplicate())
			# Actualizar selección visual al hacer click también
			current_selected_index = index
			_update_jackpot_selection()
	)
	# Mouse enter para actualizar selección visual (consistencia mouse/teclado)
	panel.mouse_entered.connect(func():
		AudioManager.play("sfx_ui_navigation")
		current_selected_index = index
		_update_jackpot_selection()
	)

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

	# Prioridad 1: Usar item_icon si es un path válido
	if item_icon.begins_with("res://") and ResourceLoader.exists(item_icon):
		icon_tex = load(item_icon)

	# Prioridad 2: Intentar por ID (para armas/fusiones que usan id como nombre de archivo)
	if icon_tex == null and item_id != "":
		var path = "res://assets/icons/%s.png" % item_id
		if ResourceLoader.exists(path):
			icon_tex = load(path)

	if icon_tex:
		icon_rect.texture = icon_tex
	else:
		# Fallback: Mostrar emoji
		var emoji_lbl = Label.new()
		# Mostrar emoji fallback si es una ruta que no existe, no mostrar la ruta como texto
		emoji_lbl.text = "❓" if item_icon.begins_with("res://") else item_icon
		emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji_lbl.add_theme_font_size_override("font_size", 28)
		emoji_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.add_child(emoji_lbl)

	icon_panel.add_child(icon_rect)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Fix: Permitir clicks en el padre
	hbox.add_child(icon_panel)

	# Info (nombre + descripción)
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Fix: Permitir clicks en el padre

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

	# Indicador de estado (reemplaza botones de acción)
	var status_container = CenterContainer.new()
	status_container.custom_minimum_size = Vector2(100, 0)

	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "⬜ " + Localization.L("ui.chest.pending")
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_container.add_child(status_label)
	status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Fix: Permitir clicks en el padre
	hbox.add_child(status_container)

	# Margen derecho
	var margin_right = Control.new()
	margin_right.custom_minimum_size = Vector2(10, 0)
	hbox.add_child(margin_right)

	return panel

# Funciones legacy removidas - ahora usamos _claim_selected_jackpot_item()
func _on_jackpot_close_pressed():
	"""Callback cuando se confirma salir del jackpot (descartar todo)"""
	skipped.emit()
	queue_free()

func _on_jackpot_item_pressed(index: int, _item: Dictionary):
	"""Manejar click/selección de item en jackpot"""
	if popup_locked: return

	# Implementación de toggle visual y lógico
	var panel = item_buttons[index]
	var is_claimed = panel.get_meta("is_claimed", false)
	is_claimed = !is_claimed
	panel.set_meta("is_claimed", is_claimed)

	_update_jackpot_item_visual(panel, is_claimed)
	_update_claim_selected_button()

func _update_jackpot_item_visual(panel: Control, is_selected: bool):
	"""Actualizar visual del item"""
	var style = panel.get_theme_stylebox("panel").duplicate()
	if is_selected:
		# Green tint for selected
		style.modulate_color = Color(0.4, 1.0, 0.4)

		var status = panel.find_child("StatusLabel", true, false)
		if status:
			status.text = "✅ " + Localization.L("ui.chest.selected")
			status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		var item_data = panel.get_meta("item_data")
		var rarity = item_data.get("rarity", 0)
		var tier = rarity + 1
		var is_weapon = (item_data.get("type") == "weapon")
		var base_style = UIVisualHelper.get_panel_style(tier, false, is_weapon)

		# Copy modulate color from base
		if "modulate_color" in base_style:
			style.modulate_color = base_style.modulate_color
		else:
			style.modulate_color = Color.WHITE

		var status = panel.find_child("StatusLabel", true, false)
		if status:
			status.text = "⬜ " + Localization.L("ui.chest.pending")
			status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	panel.add_theme_stylebox_override("panel", style)

func _update_claim_selected_button():
	var count = 0
	for p in item_buttons:
		if p.get_meta("is_claimed", false):
			count += 1
	var btn = get_meta("claim_selected_btn", null)
	if btn:
		# Mostrar siempre que haya algo seleccionado (incluso si es todo)
		btn.visible = (count > 0)

		# Opcional: Ocultar "Claim All" si ya mostramos "Claim Selected" para evitar redundancia
		if claim_button:
			claim_button.visible = (count == 0)



func _on_claim_selected_pressed():
	if popup_locked: return
	popup_locked = true
	var selected_items = []
	for p in item_buttons:
		if p.get_meta("is_claimed", false):
			selected_items.append(p.get_meta("item_data"))

	# Si no hay seleccionados, preguntar o asumir skip?
	# El botón solo aparece si hay > 0, así que seguro hay items.
	if selected_items.size() > 0:
		all_items_claimed.emit(selected_items)
	else:
		skipped.emit()
	queue_free()

func _on_jackpot_exit_pressed():
	"""Mostrar modal de confirmación antes de salir del jackpot"""
	if popup_locked: return
	_show_jackpot_exit_confirm_modal()

func _show_jackpot_exit_confirm_modal():
	"""Mostrar modal de confirmación para salir del jackpot"""
	_is_skip_modal_active = true

	var confirm_modal = Control.new()
	confirm_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.z_index = 10
	add_child(confirm_modal)

	# Bloquear input del fondo
	var blocker = ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.8)
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.add_child(blocker)

	# Panel del modal
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 220)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.12, 1.0)
	style.border_color = Color(1.0, 0.6, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_modal.add_child(center)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_child(vbox)
	panel.add_child(margin)

	var label_title = Label.new()
	label_title.text = "⚠️ " + Localization.L("ui.chest.exit_confirm_title")
	label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_title.add_theme_font_size_override("font_size", 22)
	label_title.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	vbox.add_child(label_title)

	# Contar items pendientes
	var pending_count = 0
	for panel_item in item_buttons:
		if is_instance_valid(panel_item) and panel_item.has_meta("is_claimed"):
			if not panel_item.get_meta("is_claimed"):
				pending_count += 1

	var label_desc = Label.new()
	if pending_count > 0:
		label_desc.text = Localization.L("ui.chest.pending_items", [pending_count])
	else:
		label_desc.text = Localization.L("ui.chest.all_claimed")
	label_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(label_desc)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)

	var btn_cancel = Button.new()
	btn_cancel.text = Localization.L("common.back")
	btn_cancel.custom_minimum_size = Vector2(120, 45)
	btn_cancel.focus_mode = Control.FOCUS_ALL
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.25, 0.25, 0.25)
	cancel_style.border_color = Color(0.5, 0.5, 0.5)
	cancel_style.set_border_width_all(2)
	cancel_style.set_corner_radius_all(6)
	btn_cancel.add_theme_stylebox_override("normal", cancel_style)

	var cancel_style_focus = cancel_style.duplicate()
	cancel_style_focus.bg_color = Color(0.35, 0.35, 0.35)
	cancel_style_focus.border_color = Color(1.0, 0.8, 0.3)
	cancel_style_focus.set_border_width_all(3)
	btn_cancel.add_theme_stylebox_override("hover", cancel_style_focus)
	btn_cancel.add_theme_stylebox_override("focus", cancel_style_focus)

	btn_cancel.pressed.connect(func():
		AudioManager.play("sfx_ui_cancel")
		_is_skip_modal_active = false
		_modal_btn_cancel = null
		_modal_btn_confirm = null
		confirm_modal.queue_free()
	)
	btn_cancel.mouse_entered.connect(func(): AudioManager.play("sfx_ui_navigation"))
	hbox.add_child(btn_cancel)
	_modal_btn_cancel = btn_cancel

	var btn_confirm = Button.new()
	btn_confirm.text = Localization.L("ui.chest.confirm_exit")
	btn_confirm.custom_minimum_size = Vector2(150, 45)
	btn_confirm.focus_mode = Control.FOCUS_ALL
	var style_confirm = StyleBoxFlat.new()
	style_confirm.bg_color = Color(0.5, 0.25, 0.15)
	style_confirm.border_color = Color(0.7, 0.4, 0.3)
	style_confirm.set_border_width_all(2)
	style_confirm.set_corner_radius_all(6)
	btn_confirm.add_theme_stylebox_override("normal", style_confirm)

	var confirm_style_focus = style_confirm.duplicate()
	confirm_style_focus.bg_color = Color(0.6, 0.3, 0.2)
	confirm_style_focus.border_color = Color(1.0, 0.6, 0.3)
	confirm_style_focus.set_border_width_all(3)
	btn_confirm.add_theme_stylebox_override("hover", confirm_style_focus)
	btn_confirm.add_theme_stylebox_override("focus", confirm_style_focus)

	btn_confirm.pressed.connect(func():
		AudioManager.play("sfx_ui_confirm")
		_is_skip_modal_active = false
		_modal_btn_cancel = null
		_modal_btn_confirm = null
		_on_jackpot_close_pressed()
	)
	btn_confirm.mouse_entered.connect(func(): AudioManager.play("sfx_ui_navigation"))
	hbox.add_child(btn_confirm)
	_modal_btn_confirm = btn_confirm

	# Navegación entre botones
	btn_cancel.focus_neighbor_right = btn_confirm.get_path()
	btn_cancel.focus_neighbor_left = btn_confirm.get_path()
	btn_confirm.focus_neighbor_left = btn_cancel.get_path()
	btn_confirm.focus_neighbor_right = btn_cancel.get_path()

	# Foco inicial en "Volver"
	await get_tree().process_frame
	if is_instance_valid(btn_cancel):
		btn_cancel.grab_focus()

func _recenter_popup() -> void:
	"""Recentrar el popup después de cambios de contenido"""
	if _popup_bg and is_instance_valid(_popup_bg):
		await get_tree().process_frame
		var screen_size = get_viewport().get_visible_rect().size
		_popup_bg.position = (screen_size - _popup_bg.size) / 2

func setup_items(items: Array):
	"""Configurar los items disponibles"""
	available_items = items

	# Si no estamos listos, esperar a _ready
	if not items_vbox:
		return

	item_buttons.clear()

	# Limpiar items previos (Inmediatamente para evitar duplicados visuales)
	for child in items_vbox.get_children():
		items_vbox.remove_child(child)
		child.queue_free()

	# Resetear referencias
	item_buttons.clear()
	skip_button = null

	# NO usar await aquí, causa duplicados si se llama dos veces rápido
	# await get_tree().process_frame

	# Crear botones complejos
	for i in range(items.size()):
		var item = items[i]
		var item_name = item.get("name", Localization.L("ui.chest.unknown_item"))
		var item_desc = item.get("description", Localization.L("ui.chest.no_description"))
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

		# Prioridad 1: Usar item_icon si es un path válido
		if item_icon.begins_with("res://") and ResourceLoader.exists(item_icon):
			icon_tex = load(item_icon)

		# Prioridad 2: Intentar por ID (para armas/fusiones)
		if icon_tex == null and item_id != "":
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
			# Mostrar emoji fallback si es una ruta que no existe, no mostrar la ruta como texto
			emoji_lbl.text = "❓" if item_icon.begins_with("res://") else item_icon
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
		button.pressed.connect(func():
			AudioManager.play("sfx_ui_confirm")
			_on_button_pressed(item_index, item_data)
		)
		button.mouse_entered.connect(func():
			AudioManager.play("sfx_ui_navigation")
			_on_button_hover(item_index)
		)
		button.focus_entered.connect(func():
			AudioManager.play("sfx_ui_navigation")
			# _on_button_hover(item_index) # Opcional: sincronizar hover visual con foco
		)

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
		var anim_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		_popup_bg.position = original_pos + anim_offset
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

func _reveal_item_animated(btn: Control, _index: int) -> void:
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
	# Fix duplicados: Checkear si ya existe un botón de skip
	if is_instance_valid(skip_button) and skip_button.get_parent() == items_vbox:
		return

	for child in items_vbox.get_children():
		if child is Button and Localization.L("ui.chest.skip") in child.text:
			# Ya existe, actualizar referencia y salir
			skip_button = child
			return

	skip_button = Button.new()
	skip_button.text = Localization.L("ui.chest.skip_no_reward")
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

var _modal_btn_cancel: Button = null
var _modal_btn_confirm: Button = null

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
	label_title.text = "⚠️ " + Localization.L("ui.chest.skip_confirm_title")
	label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_title.add_theme_font_size_override("font_size", 22)
	label_title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	vbox.add_child(label_title)

	var label_desc = Label.new()
	label_desc.text = Localization.L("ui.chest.skip_confirm_message")
	label_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(label_desc)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)

	var btn_cancel = Button.new()
	btn_cancel.text = Localization.L("common.back")
	btn_cancel.custom_minimum_size = Vector2(100, 40)
	btn_cancel.focus_mode = Control.FOCUS_ALL

	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.25, 0.25, 0.25)
	cancel_style.border_color = Color(0.5, 0.5, 0.5)
	cancel_style.set_border_width_all(2)
	cancel_style.set_corner_radius_all(6)
	btn_cancel.add_theme_stylebox_override("normal", cancel_style)

	var cancel_style_focus = cancel_style.duplicate()
	cancel_style_focus.bg_color = Color(0.35, 0.35, 0.35)
	cancel_style_focus.border_color = Color(1.0, 0.8, 0.3)
	cancel_style_focus.set_border_width_all(3)
	btn_cancel.add_theme_stylebox_override("hover", cancel_style_focus)
	btn_cancel.add_theme_stylebox_override("focus", cancel_style_focus)

	btn_cancel.pressed.connect(func():
		AudioManager.play("sfx_ui_cancel")
		_is_skip_modal_active = false
		confirm_modal.queue_free()
		_modal_btn_cancel = null
		_modal_btn_confirm = null
	)
	btn_cancel.mouse_entered.connect(func(): AudioManager.play("sfx_ui_navigation"))
	hbox.add_child(btn_cancel)
	_modal_btn_cancel = btn_cancel

	var btn_confirm = Button.new()
	btn_confirm.text = Localization.L("ui.chest.skip")
	btn_confirm.custom_minimum_size = Vector2(100, 40)
	btn_confirm.focus_mode = Control.FOCUS_ALL

	var style_confirm = StyleBoxFlat.new()
	style_confirm.bg_color = Color(0.6, 0.2, 0.2)
	style_confirm.border_color = Color(0.7, 0.4, 0.4)
	style_confirm.set_border_width_all(2)
	style_confirm.set_corner_radius_all(6)
	btn_confirm.add_theme_stylebox_override("normal", style_confirm)

	var confirm_style_focus = style_confirm.duplicate()
	confirm_style_focus.bg_color = Color(0.7, 0.3, 0.3)
	confirm_style_focus.border_color = Color(1.0, 0.6, 0.3)
	confirm_style_focus.set_border_width_all(3)
	btn_confirm.add_theme_stylebox_override("hover", confirm_style_focus)
	btn_confirm.add_theme_stylebox_override("focus", confirm_style_focus)

	btn_confirm.pressed.connect(func():
		AudioManager.play("sfx_ui_confirm")
		_is_skip_modal_active = false
		skipped.emit()
		queue_free()
	)
	btn_confirm.mouse_entered.connect(func(): AudioManager.play("sfx_ui_navigation"))
	hbox.add_child(btn_confirm)
	_modal_btn_confirm = btn_confirm

	# Navegación entre botones
	btn_cancel.focus_neighbor_right = btn_confirm.get_path()
	btn_cancel.focus_neighbor_left = btn_confirm.get_path()
	btn_confirm.focus_neighbor_left = btn_cancel.get_path()
	btn_confirm.focus_neighbor_right = btn_cancel.get_path()

	# Foco inicial
	await get_tree().process_frame
	if is_instance_valid(btn_cancel):
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

	# Support for Jackpot Mode toggling (Keyboard/Gamepad)
	if is_jackpot_mode:
		_on_jackpot_item_pressed(button_index, item)
		return

	popup_locked = true

	current_selected_index = button_index
	_update_button_selection()

	# Pequeño delay para ver la selección
	await get_tree().create_timer(0.2).timeout

	# FIX-P0: Guard contra freed instance (scene change durante el await)
	if not is_instance_valid(self):
		return

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
