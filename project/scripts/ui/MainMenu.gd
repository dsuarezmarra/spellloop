extends Control
class_name MainMenu

## Menu principal del juego
## Gestiona: Jugar/Reanudar, Opciones, Creditos, Salir
## NAVEGACION: Solo WASD y gamepad (NO flechas de direccion)

signal play_pressed
signal resume_pressed
signal options_pressed
signal quit_pressed

@onready var play_button: Button = $UILayer/UIContainer/VBoxContainer/PlayButton
@onready var options_button: Button = $UILayer/UIContainer/VBoxContainer/OptionsButton
@onready var quit_button: Button = $UILayer/UIContainer/VBoxContainer/QuitButton
@onready var title_label: Label = $UILayer/UIContainer/TitleLabel
@onready var version_label: Label = $UILayer/UIContainer/VersionLabel
@onready var debug_label: Label = $UILayer/DebugLabel
@onready var background_rect: TextureRect = $BackgroundLayer/BackgroundRect
@onready var ui_container: Control = $UILayer/UIContainer

# Se crea dinámicamente si hay partida activa
var resume_button: Button = null

# Sistema de navegacion WASD
var menu_buttons: Array[Button] = []
var current_button_index: int = 0

const GAME_VERSION = "0.1.0-alpha"

func _ready() -> void:
	_setup_ui()
	_apply_premium_style()
	_connect_signals()
	_play_menu_music()
	_update_resume_button()
	_setup_wasd_navigation()

func _apply_premium_style() -> void:
	# 🎨 ESTILO MAGICAL VOID & GOLD
	
	# Configurar título con Glow
	if title_label:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6)) # Oro pálido
		title_label.add_theme_color_override("font_shadow_color", Color(0.6, 0.2, 0.8, 0.6)) # Sombra púrpura
		title_label.add_theme_constant_override("shadow_offset_x", 0)
		title_label.add_theme_constant_override("shadow_offset_y", 4)
		title_label.add_theme_constant_override("shadow_outline_size", 8)
	
	# Estilo Base de Botones (Glassmorphism Dark)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.05, 0.05, 0.1, 0.80) # Casi negro azulado, semi-transparente
	style_normal.border_color = Color(0.3, 0.2, 0.5, 0.5) # Borde púrpura tenue
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(12)
	style_normal.content_margin_top = 10
	style_normal.content_margin_bottom = 10
	
	# Estilo Hover (Glow Dorado)
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style_hover.border_color = Color(1.0, 0.8, 0.2, 1.0) # Borde Dorado Brillante
	style_hover.set_border_width_all(2)
	style_hover.shadow_color = Color(1.0, 0.8, 0.2, 0.4) # Glow dorado
	style_hover.shadow_size = 8
	
	# Estilo Pressed (Energía contenida)
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	style_pressed.border_color = Color(0.8, 0.4, 1.0, 1.0) # Borde Púrpura intenso
	style_pressed.shadow_size = 2
	
	var buttons = [play_button, options_button, quit_button, resume_button]
	
	for btn in buttons:
		if btn:
			btn.add_theme_stylebox_override("normal", style_normal)
			btn.add_theme_stylebox_override("hover", style_hover)
			btn.add_theme_stylebox_override("pressed", style_pressed)
			btn.add_theme_stylebox_override("focus", style_hover) # Focus usa estilo hover para gamepad
			
			# Force Uppercase
			btn.text = btn.text.to_upper()
			
			# Tipografía
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6)) # Texto dorado al hover
			btn.add_theme_color_override("font_outline_color", Color.BLACK)
			btn.add_theme_constant_override("outline_size", 4)
			btn.add_theme_font_size_override("font_size", 24)
			
			# Conectar animaciones de hover si no están conectadas
			if not btn.mouse_entered.is_connected(_on_button_hover_anim.bind(btn)):
				btn.mouse_entered.connect(_on_button_hover_anim.bind(btn))
			if not btn.mouse_exited.is_connected(_on_button_exit_anim.bind(btn)):
				btn.mouse_exited.connect(_on_button_exit_anim.bind(btn))
			if not btn.focus_entered.is_connected(_on_button_hover_anim.bind(btn)):
				btn.focus_entered.connect(_on_button_hover_anim.bind(btn))
			if not btn.focus_exited.is_connected(_on_button_exit_anim.bind(btn)):
				btn.focus_exited.connect(_on_button_exit_anim.bind(btn))

func _on_button_hover_anim(btn: Button) -> void:
	# Animación de escala sutil "Pop"
	if not btn: return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
	# Sonido UI
	AudioManager.play_fixed("sfx_ui_hover")

func _on_button_exit_anim(btn: Button) -> void:
	if not btn: return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _setup_ui() -> void:
	# Asegurar pivotes centrales para animaciones de escala
	var buttons = [play_button, options_button, quit_button, resume_button]
	for btn in buttons:
		if btn:
			btn.pivot_offset = btn.size / 2
			# Note: Button size might not be ready yet if containers haven't sorted.
			# Using call_deferred to update pivot after layout
			btn.call_deferred("set_pivot_offset", btn.size / 2)

	if version_label:
		version_label.text = "v" + GAME_VERSION

	# Cargar Background
	# Prioridad: JPG (nuevo formato 16:9)
	var bg_path = "res://assets/ui/backgrounds/main_menu_bg.jpg"
	if not FileAccess.file_exists(bg_path):
		bg_path = "res://assets/ui/backgrounds/main_menu_bg.png"
		
	var bg_tex = load(bg_path)
	
	var debug_msg = "Path: " + bg_path + "\n"
	
	# Fallback: Carga directa del sistema de archivos (Correcto para Godot 4.x)
	var final_path = bg_path
	if not bg_tex:
		debug_msg += "Resource Load: FAILED\n"
		
		# Intentar convertir res:// a ruta absoluta del sistema
		final_path = ProjectSettings.globalize_path(bg_path)
		debug_msg += "Global Path: " + final_path + "\n"
		
		# Intentar cargar via Image.load_from_file
		var img = Image.load_from_file(final_path)

		# Fallback Nuclear: Leer bytes crudos (si load_from_file falla)
		if not img:

			debug_msg += "Image.load_from_file: NULL. Trying Byte Read...\n"
			if FileAccess.file_exists(final_path):
				var bytes = FileAccess.get_file_as_bytes(final_path)
				if bytes.size() > 0:
					img = Image.new()
					
					# --- FORMAT DETECTIVE ---
					var header = bytes.slice(0, 4)
					debug_msg += "Header: %02X %02X %02X %02X\n" % [header[0], header[1], header[2], header[3]]
					
					var err = ERR_FILE_UNRECOGNIZED
					
					# 1. Try PNG (89 50 4E 47)
					if header[0] == 0x89 and header[1] == 0x50:
						debug_msg += "Format: PNG detected\n"
						err = img.load_png_from_buffer(bytes)
					
					# 2. Try JPG (FF D8)
					elif header[0] == 0xFF and header[1] == 0xD8:
						debug_msg += "Format: Jpeg detected (renamed?)\n"
						err = img.load_jpg_from_buffer(bytes)
						
					# 3. Try WebP (RIFF....WEBP)
					elif header[0] == 0x52 and header[1] == 0x49: # 'R', 'I'
						debug_msg += "Format: WebP detected (renamed?)\n"
						err = img.load_webp_from_buffer(bytes)
						
					# 4. Fallback: Try all in order
						debug_msg += "Format: Unknown. Trying brute force...\n"
						err = img.load_png_from_buffer(bytes)
						if err != OK: err = img.load_jpg_from_buffer(bytes)
						if err != OK: err = img.load_webp_from_buffer(bytes)
					
					if err != OK:
						debug_msg += "Buffer Load: FAILED (Err " + str(err) + ")\n"
						img = null 
					else:
						# SUCCESS! Ocultar debug
						if debug_label: debug_label.visible = false
						debug_msg += "Buffer Load: SUCCESS\n"
				else:
					debug_msg += "FileAccess: ERROR (0 bytes read)\n"
			else:
				debug_msg += "FileAccess: EXISTANCE CHECK FAILED\n"
		
		if img:
			# Confirmar success final
			if debug_label: debug_label.visible = false
			bg_tex = ImageTexture.create_from_image(img)
		else:
			debug_msg += "FATAL: Could not load image in any way.\n"
			if debug_label: 
				debug_label.visible = true
				debug_label.text = debug_msg
	else:
		if debug_label: debug_label.visible = false
		debug_msg += "Resource Load: SUCCESS\n"
		
	if bg_tex and background_rect:
		background_rect.texture = bg_tex
		background_rect.visible = true
	
	if debug_label:
		debug_label.text = debug_msg

	# Animación de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Focus en el botón apropiado
	_set_initial_focus()

func _update_resume_button() -> void:
	"""Mostrar u ocultar el boton de reanudar segun el estado del juego"""
	# Crear boton de reanudar si no existe
	if not resume_button:
		_create_resume_button()

	# Verificar si hay partida activa que se pueda reanudar
	var can_resume_game = SessionState.can_resume() if SessionState else false

	if resume_button:
		resume_button.visible = can_resume_game
		if can_resume_game and SessionState:
			resume_button.text = ">> REANUDAR (%s)" % SessionState.get_paused_time_formatted()

	# Actualizar texto del botón de jugar
	if play_button:
		if can_resume_game:
			play_button.text = "🎮 NUEVA PARTIDA"
		else:
			play_button.text = "🎮 JUGAR"

func _create_resume_button() -> void:
	"""Crear el boton de reanudar dinamicamente si no existe en la escena"""
	if play_button and play_button.get_parent():
		var parent = play_button.get_parent()
		resume_button = Button.new()
		resume_button.name = "ResumeButton"
		resume_button.text = ">> REANUDAR"
		resume_button.custom_minimum_size = play_button.custom_minimum_size
		resume_button.visible = false

		# Copiar tamanio de fuente del boton de jugar
		if play_button.has_theme_font_size_override("font_size"):
			resume_button.add_theme_font_size_override("font_size", play_button.get_theme_font_size("font_size"))
		else:
			resume_button.add_theme_font_size_override("font_size", 24)

		# Add to VBox at index 0 (top)
		$UILayer/UIContainer/VBoxContainer.add_child(resume_button)
		$UILayer/UIContainer/VBoxContainer.move_child(resume_button, 0)
		
		# Apply style
		_apply_premium_style()

		resume_button.pressed.connect(_on_resume_pressed)


	# --- BACKGROUND BOX ADJUSTMENT ---
	# Crear el panel background si no existe
	var vbox = $UILayer/UIContainer/VBoxContainer
	if vbox:
		var bg_panel = vbox.get_node_or_null("MenuBackground")
		if not bg_panel:
			bg_panel = PanelContainer.new()
			bg_panel.name = "MenuBackground"
			
			# Configurar Estilo
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.6)
			style.set_corner_radius_all(16)
			style.content_margin_top = 30
			style.content_margin_bottom = 30
			style.content_margin_left = 40
			style.content_margin_right = 40
			bg_panel.add_theme_stylebox_override("panel", style)
			
			# REPARENTING ROBUSTO
			# 1. Obtener padre actual
			var parent = vbox.get_parent()
			# 2. Reemplazar VBox con Panel en el arbol
			parent.remove_child(vbox)
			parent.add_child(bg_panel)
			# 3. Meter VBox dentro del Panel
			bg_panel.add_child(vbox)
			
			# 4. CONFIGURAR ANCHORS PARA CENTRADO PERFECTO
			bg_panel.set_anchors_preset(Control.PRESET_CENTER)
			bg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
			bg_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
			# Resetear offsets para evitar desplazamiento
			bg_panel.offset_left = 0
			bg_panel.offset_top = 0
			bg_panel.offset_right = 0
			bg_panel.offset_bottom = 0
			
	# Quitar textos no deseados
	if title_label: title_label.visible = false
	if version_label: version_label.visible = false
	
	# Buscar el subtitulo perdido
	var labels = find_children("*", "Label", true)
	for l in labels:
		if l.text == "Roguelike Bullet Heaven":
			l.visible = false
			break

func _set_initial_focus() -> void:
	"""Establecer foco en el boton apropiado"""
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_update_button_list()
	_highlight_current_button()

func _setup_wasd_navigation() -> void:
	"""Configurar navegacion WASD y desactivar flechas"""
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_update_button_list()

	# Desactivar navegacion por flechas en todos los botones
	for btn in menu_buttons:
		if btn and is_instance_valid(btn):
			btn.focus_neighbor_top = btn.get_path()
			btn.focus_neighbor_bottom = btn.get_path()
			btn.focus_neighbor_left = btn.get_path()
			btn.focus_neighbor_right = btn.get_path()

	_highlight_current_button()

func _update_button_list() -> void:
	"""Actualizar lista de botones navegables"""
	menu_buttons.clear()

	# Agregar botones en orden (verificar que existan y sean validos)
	if resume_button and is_instance_valid(resume_button) and resume_button.visible:
		menu_buttons.append(resume_button)
	if play_button and is_instance_valid(play_button):
		menu_buttons.append(play_button)
	if options_button and is_instance_valid(options_button):
		menu_buttons.append(options_button)
	if quit_button and is_instance_valid(quit_button):
		menu_buttons.append(quit_button)

	# Resetear indice si es necesario
	if current_button_index >= menu_buttons.size():
		current_button_index = 0

func _highlight_current_button() -> void:
	"""Dar foco al boton actual"""
	if menu_buttons.size() > 0 and current_button_index < menu_buttons.size():
		var btn = menu_buttons[current_button_index]
		if btn and is_instance_valid(btn):
			btn.grab_focus()

func _play_menu_music() -> void:
	AudioManager.play_music("music_intro_theme")

func _connect_signals() -> void:
	if play_button:
		if not play_button.pressed.is_connected(_on_play_pressed):
			play_button.pressed.connect(_on_play_pressed)
		if not play_button.mouse_entered.is_connected(_on_button_hover):
			play_button.mouse_entered.connect(_on_button_hover)

	if resume_button:
		if not resume_button.pressed.is_connected(_on_resume_pressed):
			resume_button.pressed.connect(_on_resume_pressed)
		if not resume_button.mouse_entered.is_connected(_on_button_hover):
			resume_button.mouse_entered.connect(_on_button_hover)
			
	if options_button:
		if not options_button.pressed.is_connected(_on_options_pressed):
			options_button.pressed.connect(_on_options_pressed)
		if not options_button.mouse_entered.is_connected(_on_button_hover):
			options_button.mouse_entered.connect(_on_button_hover)

	if quit_button:
		if not quit_button.pressed.is_connected(_on_quit_pressed):
			quit_button.pressed.connect(_on_quit_pressed)
		if not quit_button.mouse_entered.is_connected(_on_button_hover):
			quit_button.mouse_entered.connect(_on_button_hover)

func _on_button_hover() -> void:
	AudioManager.play_fixed("sfx_ui_hover")

func _get_audio_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("AudioManager")
	return null

# Referencia a la pantalla de selección de slot
var slot_select_screen: Control = null
var character_select_screen: Control = null
var _pending_slot_index: int = 0

enum Screen { MAIN_MENU, SLOTS, CHARACTERS, OPTIONS }
var current_screen: int = Screen.MAIN_MENU

func _change_screen(target: int) -> void:
	"""Centralized function to switch screens and prevent overlaps"""
	print("[MainMenu] Switching to screen: ", target)
	current_screen = target
	
	# 1. HIDE EVERYTHING FIRST
	if has_node("UILayer"): $UILayer.visible = false
	if ui_container: ui_container.visible = false
	
	if slot_select_screen and is_instance_valid(slot_select_screen):
		slot_select_screen.visible = false
		
	if character_select_screen and is_instance_valid(character_select_screen):
		character_select_screen.visible = false
		
	var options_menu = get_node_or_null("OptionsMenu")
	if options_menu and is_instance_valid(options_menu):
		options_menu.visible = false
		
	# 2. SHOW TARGET
	match target:
		Screen.MAIN_MENU:
			if has_node("UILayer"): $UILayer.visible = true
			elif ui_container: ui_container.visible = true
			# Restore focus
			_update_button_list()
			_highlight_current_button()
			
		Screen.SLOTS:
			if not slot_select_screen or not is_instance_valid(slot_select_screen):
				_load_slot_screen() # Helper to instantiate
			
			if slot_select_screen:
				slot_select_screen.visible = true
				slot_select_screen.z_index = 100
				slot_select_screen.refresh()
				
		Screen.CHARACTERS:
			if not character_select_screen or not is_instance_valid(character_select_screen):
				_load_character_screen() # Helper to instantiate
				
			if character_select_screen:
				character_select_screen.visible = true
				character_select_screen.z_index = 200
				if character_select_screen.has_method("show_screen"):
					character_select_screen.show_screen()
					
		Screen.OPTIONS:
			_show_options_internal()

func _on_play_pressed() -> void:
	_play_button_sound()
	play_pressed.emit()
	_change_screen(Screen.SLOTS)

# Helper: Load OR Reuse Slot Screen
func _load_slot_screen() -> void:
	if slot_select_screen and is_instance_valid(slot_select_screen):
		return # Already loaded
		
	var slot_scene = load("res://scenes/ui/SaveSlotSelect.tscn")
	if not slot_scene:
		_start_game_with_default_slot() # Fallback
		return

	slot_select_screen = slot_scene.instantiate()
	add_child(slot_select_screen)
	move_child(slot_select_screen, -1)
	
	slot_select_screen.slot_selected.connect(_on_slot_selected)
	slot_select_screen.back_pressed.connect(_on_slot_back)

# Compatibility wrapper if needed, or remove
func _show_slot_select() -> void:
	_change_screen(Screen.SLOTS)

func _on_slot_selected(slot_index: int) -> void:
	_pending_slot_index = slot_index
	_change_screen(Screen.CHARACTERS)

func _load_character_screen() -> void:
	if character_select_screen and is_instance_valid(character_select_screen):
		return # Already loaded
		
	var char_scene = load("res://scenes/ui/CharacterSelectScreen.tscn")
	if not char_scene:
		_start_game_with_default_character()
		return
		
	character_select_screen = char_scene.instantiate()
	add_child(character_select_screen)
	move_child(character_select_screen, -1)
	
	character_select_screen.character_selected.connect(_on_character_selected)
	character_select_screen.back_pressed.connect(_on_character_back)

func _show_character_select() -> void:
	_change_screen(Screen.CHARACTERS)

func _on_character_back() -> void:
	_change_screen(Screen.SLOTS)
	
func _on_slot_back() -> void:
	_change_screen(Screen.MAIN_MENU)
	
func _on_options_pressed() -> void:
	_play_button_sound()
	options_pressed.emit()
	_change_screen(Screen.OPTIONS)
	
func _show_options() -> void:
	_change_screen(Screen.OPTIONS)

func _show_options_internal() -> void:
	var options_menu = get_node_or_null("OptionsMenu")
	if not options_menu:
		var scene = load("res://scenes/ui/OptionsMenu.tscn")
		if scene:
			options_menu = scene.instantiate()
			options_menu.name = "OptionsMenu"
			if has_node("UILayer"): $UILayer.add_child(options_menu)
			else: add_child(options_menu)
			options_menu.z_index = 300
			
	if options_menu:
		options_menu.visible = true
		if options_menu.has_signal("closed") and not options_menu.closed.is_connected(_on_options_closed):
			options_menu.closed.connect(_on_options_closed)

func _on_options_closed() -> void:
	_change_screen(Screen.MAIN_MENU)

func _on_resume_pressed() -> void:
	_play_button_sound()
	resume_pressed.emit()
	_resume_game()

func _resume_game() -> void:
	"""Reanudar la partida guardada"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	var scene_path = "res://scenes/game/Game.tscn"
	if SessionState and SessionState.game_scene_path:
		scene_path = SessionState.game_scene_path
	get_tree().change_scene_to_file(scene_path)

func _on_quit_pressed() -> void:
	_play_button_sound()
	quit_pressed.emit()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _play_button_sound() -> void:
	AudioManager.play_fixed("sfx_ui_click")

func _start_game() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _start_game_with_default_slot() -> void:
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("set_active_slot"):
		save_manager.set_active_slot(0)
	_start_game()

func _start_game_with_default_character() -> void:
	if SessionState:
		SessionState.start_new_game(_pending_slot_index, "frost_mage")
	_start_game()

func _on_character_selected(character_id: String) -> void:
	if SessionState:
		SessionState.start_new_game(_pending_slot_index, character_id)
	_start_game()


func _input(event: InputEvent) -> void:
	# Si hay subscreens visibles, ignorar input del menu principal
	if slot_select_screen and slot_select_screen.visible: return
	if character_select_screen and character_select_screen.visible: return

	# Si hay un submenu de opciones abierto, no procesar
	var options_menu = get_node_or_null("OptionsMenu")
	if options_menu and options_menu.visible:
		return

	# Navegacion con teclado WASD
	if event is InputEventKey and event.pressed:
		var handled = false

		match event.keycode:
			KEY_W:
				_navigate_menu(-1)
				handled = true
			KEY_S:
				_navigate_menu(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_activate_current_button()
				handled = true
			KEY_ESCAPE:
				if quit_button:
					current_button_index = menu_buttons.find(quit_button)
					_highlight_current_button()
				handled = true

		if handled:
			get_viewport().set_input_as_handled()

	# Soporte para gamepad - botones
	if event is InputEventJoypadButton and event.pressed:
		var handled = false

		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate_menu(-1)
				handled = true
			JOY_BUTTON_DPAD_DOWN:
				_navigate_menu(1)
				handled = true
			JOY_BUTTON_A:
				_activate_current_button()
				handled = true

		if handled:
			get_viewport().set_input_as_handled()

	# Soporte para joystick analogico
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate_menu(-1)
				get_viewport().set_input_as_handled()
			elif event.axis_value > 0.5:
				_navigate_menu(1)
				get_viewport().set_input_as_handled()

func _navigate_menu(direction: int) -> void:
	"""Navegar entre botones del menu"""
	if menu_buttons.is_empty():
		return

	current_button_index = wrapi(current_button_index + direction, 0, menu_buttons.size())
	AudioManager.play_fixed("sfx_ui_hover")
	_highlight_current_button()

func _activate_current_button() -> void:
	"""Activar el boton actualmente seleccionado"""
	if menu_buttons.is_empty():
		return

	var current = menu_buttons[current_button_index]
	if current:
		current.pressed.emit()
