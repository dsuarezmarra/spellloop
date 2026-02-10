# CharacterSelectScreen.gd
# Character selection screen - Binding of Isaac style
# Circular carousel with animated selected character and stats below

extends Control

signal character_selected(character_id: String)
signal back_pressed

# Reference to Localization autoload
var Localization: Node

# =============================================================================
# CONFIGURATION
# =============================================================================

const CAROUSEL_RADIUS: float = 250.0  # Distance from center to characters
const SELECTED_SCALE: float = 2.5     # Scale of selected character (sprites are now 128x128 like wizard)
const UNSELECTED_SCALE: float = 1.2   # Scale of unselected characters
const ANIMATION_DURATION: float = 0.25 # Transition animation time
const VISIBLE_CHARACTERS: int = 5     # How many characters visible at once

# =============================================================================
# NODES
# =============================================================================

var carousel_center: Control
var stats_panel: Control
var title_label: Label
var character_name_label: Label
var character_title_label: Label

var instructions_label: Label

# Character sprites in carousel
var character_nodes: Array[Control] = []
var character_sprites: Array[AnimatedSprite2D] = []

# =============================================================================
# STATE
# =============================================================================

var all_characters: Array = []
var unlocked_character_ids: Array = []
var current_index: int = 0
var is_transitioning: bool = false
var selected_character_id: String = ""

# Tween for animations
var carousel_tween: Tween

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Get Localization autoload reference
	if get_tree() and get_tree().root:
		Localization = get_tree().root.get_node_or_null("Localization")

	_load_characters()
	_build_ui()
	_create_carousel()
	_update_carousel_positions(false)
	_update_stats_display()
	_setup_ambient_particles()

	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

# Helper function for localization
func L(key: String, args: Array = []) -> String:
	if Localization and Localization.has_method("L"):
		return Localization.L(key, args)
	return key

func _get_lang_suffix() -> String:
	"""Get current language suffix for localized content (e.g., '_es', '_en')"""
	if Localization and Localization.has_method("get_current_language"):
		return "_" + Localization.get_current_language()
	return "_es"  # Default to Spanish

func _get_localized_field(data: Dictionary, field_base: String, fallback: String = "") -> String:
	"""Get a localized field from a dictionary (e.g., 'name_es' or 'name_en')"""
	var lang_suffix = _get_lang_suffix()
	var key = field_base + lang_suffix
	if data.has(key):
		return data[key]
	# Fallback to Spanish
	if data.has(field_base + "_es"):
		return data[field_base + "_es"]
	# Fallback to field without suffix
	if data.has(field_base):
		return data[field_base]
	return fallback

func _load_characters() -> void:
	"""Load all characters from database"""
	all_characters = CharacterDatabase.get_all_characters()

	# For now, unlock all for testing
	unlocked_character_ids = []
	for char_data in all_characters:
		unlocked_character_ids.append(char_data.id)

	# Set initial selection
	if all_characters.size() > 0:
		selected_character_id = all_characters[0].id

func _build_ui() -> void:
	"""Build the UI programmatically"""
	
	# Background (Wallpaper)
	# Buscar si ya existe un fondo en la escena y eliminarlo
	var existing_bg = get_node_or_null("Background")
	if existing_bg:
		existing_bg.queue_free()

	var bg = TextureRect.new()
	bg.name = "Background"
	
	# Intentar cargar la textura
	# Usar el nuevo fondo procesado
	var bg_path = "res://assets/ui/backgrounds/character_select_bg_new.png"
	if not FileAccess.file_exists(bg_path):
		bg_path = "res://assets/ui/backgrounds/character_select_bg.png"
		
	var bg_tex = null
	
	var global_path = ProjectSettings.globalize_path(bg_path)
	var img = Image.load_from_file(global_path)
	
	# Fallback bytes si load_from_file falla (para formatos raros)
	if not img and FileAccess.file_exists(global_path):
		var bytes = FileAccess.get_file_as_bytes(global_path)
		if bytes.size() > 0:
			img = Image.new()
			# Format Detective
			var h = bytes.slice(0, 4)
			var err = ERR_FILE_UNRECOGNIZED
			
			if h[0] == 0xFF and h[1] == 0xD8: # JPG
				err = img.load_jpg_from_buffer(bytes)
			elif h[0] == 0x89 and h[1] == 0x50: # PNG
				err = img.load_png_from_buffer(bytes)
			elif h[0] == 0x52: # WebP (RIFF)
				err = img.load_webp_from_buffer(bytes)
			else:
				# Brute force
				err = img.load_png_from_buffer(bytes)
				if err != OK: err = img.load_jpg_from_buffer(bytes)
				if err != OK: err = img.load_webp_from_buffer(bytes)
			
			if err != OK: img = null
			
	if img:
		bg_tex = ImageTexture.create_from_image(img)
	else:
		# Fallback final a load() normal
		bg_tex = load(bg_path)

	if bg_tex:
		bg.texture = bg_tex
	else:
		push_error("No se pudo cargar el fondo desde: " + bg_path)
		# Fallback visual claro (Rojo oscuro) para debug
		var placeholder = GradientTexture2D.new()
		placeholder.fill_from = Vector2(0, 0)
		placeholder.fill_to = Vector2(1, 1)
		placeholder.gradient = Gradient.new()
		placeholder.gradient.add_point(0.0, Color(0.2, 0.0, 0.0)) # ROJO para indicar error
		placeholder.gradient.add_point(1.0, Color(0.1, 0.0, 0.0))
		bg.texture = placeholder
		
	# Contenedor con clip para permitir desplazamiento
	var bg_container = Control.new()
	bg_container.name = "BackgroundContainer"
	bg_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_container.clip_contents = true
	bg_container.z_index = -100
	bg_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_container)
	move_child(bg_container, 0)
	
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Tamaño ligeramente mayor para permitir desplazar sin bordes negros
	var screen_size = get_viewport().get_visible_rect().size
	var extra = 200  # Margen para desplazamiento
	bg.custom_minimum_size = screen_size + Vector2(extra, extra)
	bg.size = screen_size + Vector2(extra, extra)
	# Centrar base (-extra/2) y luego ajustar: +X=derecha, -Y=arriba
	bg.position = Vector2(-extra/2 + 75, -extra/2 - 40)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_container.add_child(bg)

	# Vignette effect (darker edges) - Asegurar que esté SOBRE el fondo pero BAJO la UI
	var vignette = ColorRect.new()
	vignette.name = "Vignette"
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.3) # Un poco más oscuro para que el texto resalte
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# Title at top - Con fuente personalizada
	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = L("ui.character_select.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 30
	title_label.offset_bottom = 90
	# Cargar fuente de título
	var font_title = load("res://assets/ui/fonts/LilitaOne-Regular.ttf")
	if font_title:
		title_label.add_theme_font_override("font", font_title)
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title_label)

	# Carousel center point - Ajustado para coincidir con la plataforma del fondo
	# La plataforma está en la parte central-inferior de la imagen
	carousel_center = Control.new()
	carousel_center.name = "CarouselCenter"
	carousel_center.set_anchors_preset(Control.PRESET_CENTER)
	carousel_center.position = Vector2(0, 30)  # Bajar para que coincida con la plataforma
	add_child(carousel_center)

	# Character name (above carousel) - Con fuente personalizada
	character_name_label = Label.new()
	character_name_label.name = "CharacterName"
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_name_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	character_name_label.anchor_top = 0.14
	character_name_label.anchor_bottom = 0.14
	character_name_label.offset_top = 0
	character_name_label.offset_bottom = 45
	character_name_label.offset_left = -400
	character_name_label.offset_right = 400
	# Fuente personalizada para nombre
	var font_name = load("res://assets/ui/fonts/LilitaOne-Regular.ttf")
	if font_name:
		character_name_label.add_theme_font_override("font", font_name)
	character_name_label.add_theme_font_size_override("font_size", 32)
	character_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	character_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	character_name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(character_name_label)

	# Character title (below name)
	character_title_label = Label.new()
	character_title_label.name = "CharacterTitle"
	character_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	character_title_label.anchor_top = 0.19
	character_title_label.anchor_bottom = 0.19
	character_title_label.offset_top = 0
	character_title_label.offset_bottom = 30
	character_title_label.offset_left = -400
	character_title_label.offset_right = 400
	# Fuente Fredoka para subtítulo
	var font_body = load("res://assets/ui/fonts/Fredoka-Variable.ttf")
	if font_body:
		character_title_label.add_theme_font_override("font", font_body)
	character_title_label.add_theme_font_size_override("font_size", 22)
	# Sombra para mejor legibilidad
	character_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	character_title_label.add_theme_constant_override("shadow_offset_x", 2)
	character_title_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(character_title_label)

	# Stats panel (below carousel) - Posición ajustada para no pisar al personaje
	_build_stats_panel()

	# Navigation instructions
	instructions_label = Label.new()
	instructions_label.name = "Instructions"
	instructions_label.text = L("ui.character_select.instructions")
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	instructions_label.offset_top = -50
	instructions_label.offset_bottom = -20
	instructions_label.add_theme_font_size_override("font_size", 16)
	instructions_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(instructions_label)



func _build_stats_panel() -> void:
	"""Build the stats display panel"""
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.set_anchors_preset(Control.PRESET_CENTER)
	# Posicionar más abajo para no pisar al personaje
	stats_panel.anchor_top = 0.72
	stats_panel.anchor_bottom = 0.72
	stats_panel.offset_left = -380
	stats_panel.offset_right = 380
	stats_panel.offset_top = 0
	stats_panel.offset_bottom = 200

	# Style - Intentar usar el frame decorativo
	var frame_tex = load("res://assets/ui/frames/stats_panel_frame.png")
	if frame_tex:
		var panel_style = StyleBoxTexture.new()
		panel_style.texture = frame_tex
		panel_style.content_margin_left = 40
		panel_style.content_margin_right = 40
		panel_style.content_margin_top = 45
		panel_style.content_margin_bottom = 30
		stats_panel.add_theme_stylebox_override("panel", panel_style)
	else:
		# Fallback programático
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
		panel_style.border_color = Color(0.3, 0.3, 0.4)
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(10)
		stats_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(stats_panel)

	# Content - Márgenes reducidos
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stats_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "StatsVBox"
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

func _create_carousel() -> void:
	"""Create character sprites for the carousel"""
	character_nodes.clear()
	character_sprites.clear()

	for i in range(all_characters.size()):
		var char_data = all_characters[i]

		# Container for each character
		var char_container = Control.new()
		char_container.name = "Char_" + char_data.id
		char_container.z_index = 0
		carousel_center.add_child(char_container)

		# Animated sprite
		var sprite = AnimatedSprite2D.new()
		sprite.name = "Sprite"
		sprite.centered = true

		# Load walk_down animation
		var frames = _create_character_frames(char_data)
		sprite.sprite_frames = frames
		sprite.animation = "idle"
		sprite.play()

		char_container.add_child(sprite)

		# Glow effect for selected (initially invisible)
		var glow = Sprite2D.new()
		glow.name = "Glow"
		glow.modulate = Color(char_data.color_primary.r, char_data.color_primary.g, char_data.color_primary.b, 0)
		glow.z_index = -1
		char_container.add_child(glow)

		character_nodes.append(char_container)
		character_sprites.append(sprite)

func _create_character_frames(char_data: Dictionary) -> SpriteFrames:
	"""Create SpriteFrames for a character with idle and walk animations"""
	var frames = SpriteFrames.new()
	var sprite_folder = char_data.get("sprite_folder", "frost_mage")
	var base_path = "res://assets/sprites/players/" + sprite_folder
	const FRAME_SIZE = 208  # Each frame is 208x208

	# Load the walk_down strip
	var strip_path = "%s/walk/walk_down_strip.png" % base_path
	var strip_tex = load(strip_path) as Texture2D
	
	if not strip_tex:
		# Fallback to frost_mage
		strip_path = "res://assets/sprites/players/frost_mage/walk/walk_down_strip.png"
		strip_tex = load(strip_path) as Texture2D
	
	if strip_tex:
		var strip_image = strip_tex.get_image()
		
		# IDLE animation (first frame from strip)
		frames.add_animation("idle")
		frames.set_animation_speed("idle", 1.0)
		frames.set_animation_loop("idle", true)
		
		var idle_region = Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE)
		var idle_image = strip_image.get_region(idle_region)
		frames.add_frame("idle", ImageTexture.create_from_image(idle_image))
		
		# WALK animation (3 frames from strip)
		frames.add_animation("walk")
		frames.set_animation_speed("walk", 6.0)
		frames.set_animation_loop("walk", true)
		
		for i in range(3):
			var frame_region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			var frame_image = strip_image.get_region(frame_region)
			frames.add_frame("walk", ImageTexture.create_from_image(frame_image))

	return frames

# =============================================================================
# CAROUSEL LOGIC
# =============================================================================

func _update_carousel_positions(animate: bool = true) -> void:
	"""Update positions of all characters in the carousel"""
	if is_transitioning and animate:
		return

	var total = character_nodes.size()
	if total == 0:
		return

	if animate:
		is_transitioning = true
		if carousel_tween:
			carousel_tween.kill()
		carousel_tween = create_tween()
		carousel_tween.set_parallel(true)
		carousel_tween.set_ease(Tween.EASE_OUT)
		carousel_tween.set_trans(Tween.TRANS_CUBIC)

	for i in range(total):
		var node = character_nodes[i]
		var sprite = character_sprites[i]

		# Calculate position in carousel (relative to current_index)
		var offset = i - current_index

		# Wrap around for circular effect
		while offset > total / 2:
			offset -= total
		while offset < -total / 2:
			offset += total

		# Calculate target position and properties
		var target_pos: Vector2
		var target_scale: float
		var target_alpha: float
		var target_z: int

		if offset == 0:
			# Selected character - center, large, fully visible
			target_pos = Vector2(0, 0)
			target_scale = SELECTED_SCALE
			target_alpha = 1.0
			target_z = 10

			# Play walk animation
			if sprite.animation != "walk":
				sprite.animation = "walk"
				sprite.play()
		else:
			# Calculate position on arc
			var angle = offset * 0.4  # Spacing between characters
			var distance = CAROUSEL_RADIUS * (1.0 + abs(offset) * 0.1)

			target_pos = Vector2(
				sin(angle) * distance,
				abs(offset) * 30 - 20  # Slight vertical offset
			)

			# Scale and fade based on distance from center
			var distance_factor = 1.0 - (abs(offset) * 0.25)
			target_scale = UNSELECTED_SCALE * max(distance_factor, 0.5)
			target_alpha = max(1.0 - abs(offset) * 0.3, 0.2)
			target_z = 5 - abs(offset)

			# Play idle animation
			if sprite.animation != "idle":
				sprite.animation = "idle"
				sprite.play()

		# Apply visibility for far characters
		var is_visible = abs(offset) <= (VISIBLE_CHARACTERS / 2 + 1)

		if animate:
			carousel_tween.tween_property(node, "position", target_pos, ANIMATION_DURATION)
			carousel_tween.tween_property(sprite, "scale", Vector2(target_scale, target_scale), ANIMATION_DURATION)
			carousel_tween.tween_property(sprite, "modulate:a", target_alpha if is_visible else 0.0, ANIMATION_DURATION)
			# Z-index doesn't tween well, set directly
			node.z_index = target_z
		else:
			node.position = target_pos
			sprite.scale = Vector2(target_scale, target_scale)
			sprite.modulate.a = target_alpha if is_visible else 0.0
			node.z_index = target_z

	if animate:
		carousel_tween.tween_callback(_on_transition_complete).set_delay(ANIMATION_DURATION)

	# Update selected character
	if current_index >= 0 and current_index < all_characters.size():
		selected_character_id = all_characters[current_index].id

	_update_stats_display()

func _on_transition_complete() -> void:
	is_transitioning = false

func _navigate(direction: int) -> void:
	"""Navigate carousel left or right"""
	if is_transitioning:
		return

	var total = all_characters.size()
	if total == 0:
		return

	# Find next unlocked character
	var new_index = current_index
	var attempts = 0

	while attempts < total:
		new_index = (new_index + direction + total) % total
		if all_characters[new_index].id in unlocked_character_ids:
			break
		attempts += 1

	if new_index != current_index:
		current_index = new_index
		_update_carousel_positions(true)
		_play_navigate_sound()

func _update_stats_display() -> void:
	"""Update the stats panel with current character info"""
	if current_index < 0 or current_index >= all_characters.size():
		return

	var char_data = all_characters[current_index]
	var is_unlocked = char_data.id in unlocked_character_ids

	# Update name and title (use localized versions)
	if character_name_label:
		character_name_label.text = L("characters.%s.name" % char_data.id) if is_unlocked else "???"

	if character_title_label:
		character_title_label.text = L("characters.%s.title" % char_data.id) if is_unlocked else L("ui.character_select.locked")
		character_title_label.add_theme_color_override("font_color", char_data.color_primary if is_unlocked else Color(0.5, 0.5, 0.5))

	# Update stats panel
	if not stats_panel:
		return

	var margin = stats_panel.get_node_or_null("MarginContainer")
	if not margin:
		margin = stats_panel.get_child(0) if stats_panel.get_child_count() > 0 else null
	if not margin:
		return

	var vbox = margin.get_node_or_null("StatsVBox")
	if not vbox:
		vbox = margin.get_child(0) if margin.get_child_count() > 0 else null
	if not vbox:
		return

	# Clear previous stats
	for child in vbox.get_children():
		child.queue_free()

	if not is_unlocked:
		var locked_label = Label.new()
		locked_label.text = L("ui.character_select.unlock_hint")
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(locked_label)
		return

	# Description (localized) - Texto más compacto
	var desc_label = Label.new()
	desc_label.text = L("characters.%s.description" % char_data.id)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(desc_label)

	# Separator sutil
	var sep1 = HSeparator.new()
	sep1.add_theme_constant_override("separation", 4)
	vbox.add_child(sep1)

	# Weapon and Passive (localized) - En una sola línea horizontal
	var weapon_passive_hbox = HBoxContainer.new()
	weapon_passive_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_passive_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(weapon_passive_hbox)

	var weapon_data = WeaponDatabase.WEAPONS.get(char_data.starting_weapon, {})
	var weapon_name = L("weapons.%s.name" % char_data.starting_weapon)
	var weapon_label_text = L("ui.character_select.weapon")

	var weapon_label = Label.new()
	weapon_label.text = weapon_label_text + ": " + weapon_name
	weapon_label.add_theme_font_size_override("font_size", 13)
	weapon_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	weapon_passive_hbox.add_child(weapon_label)

	var passive = char_data.get("passive", {})
	var passive_name = L("characters.%s.passive_name" % char_data.id)
	var passive_label_text = L("ui.character_select.passive")
	var passive_label = Label.new()
	passive_label.text = passive_label_text + ": " + passive_name
	passive_label.add_theme_font_size_override("font_size", 13)
	passive_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	weapon_passive_hbox.add_child(passive_label)

	# Separator sutil
	var sep2 = HSeparator.new()
	sep2.add_theme_constant_override("separation", 4)
	vbox.add_child(sep2)

	# Stats grid - 3x3 compacto, centrado horizontalmente
	var stats_center = HBoxContainer.new()
	stats_center.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_center)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 40)  # Más separación horizontal
	stats_grid.add_theme_constant_override("v_separation", 4)
	stats_center.add_child(stats_grid)

	var stats = char_data.get("stats", {})

	# Stats reducidos para encajar en el panel (3x3 = 9 stats)
	var stat_display = [
		# Row 1: Core stats
		{"key": "max_health", "name": "HP", "base": 100, "format": "%.0f", "invert": false},
		{"key": "move_speed", "name": "SPD", "base": 100, "format": "%.0f", "invert": false},
		{"key": "armor", "name": "ARM", "base": 0, "format": "%.0f", "invert": false},
		# Row 2: Combat stats
		{"key": "damage_mult", "name": "DMG", "base": 1.0, "format": "x%.2f", "invert": false},
		{"key": "attack_speed_mult", "name": "SPD", "base": 1.0, "format": "x%.2f", "invert": false},
		{"key": "area_mult", "name": "AREA", "base": 1.0, "format": "x%.2f", "invert": false},
		# Row 3: Utility stats
		{"key": "pickup_range", "name": "RNG", "base": 100, "format": "%.0f", "invert": false},
		{"key": "health_regen", "name": "REGEN", "base": 0.0, "format": "%.1f", "invert": false},
		{"key": "luck", "name": "LUCK", "base": 0.0, "format": "%.0f%%", "invert": false},
	]

	for stat_info in stat_display:
		var value = stats.get(stat_info.key, stat_info.base)
		var is_better = value > stat_info.base if not stat_info.invert else value < stat_info.base
		var is_worse = value < stat_info.base if not stat_info.invert else value > stat_info.base

		var stat_label = Label.new()
		stat_label.text = stat_info.name + ": " + (stat_info.format % value)
		stat_label.add_theme_font_size_override("font_size", 13)
		stat_label.custom_minimum_size = Vector2(100, 0)  # Ancho mínimo para columnas uniformes
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if is_better:
			stat_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		elif is_worse:
			stat_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		else:
			stat_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

		stats_grid.add_child(stat_label)

# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var handled = false

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A, KEY_LEFT:
				_navigate(-1)
				handled = true
			KEY_D, KEY_RIGHT:
				_navigate(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_on_play_pressed()
				handled = true
			KEY_ESCAPE:
				_on_back_pressed()
				handled = true

	# Gamepad
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_navigate(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT:
				_navigate(1)
				handled = true
			JOY_BUTTON_A:
				_on_play_pressed()
				handled = true
			JOY_BUTTON_B:
				_on_back_pressed()
				handled = true

	if handled:
		get_viewport().set_input_as_handled()

# =============================================================================
# CALLBACKS
# =============================================================================

func _on_play_pressed() -> void:
	if selected_character_id.is_empty():
		return

	if not (selected_character_id in unlocked_character_ids):
		return

	AudioManager.play_fixed("sfx_ui_character_select")
	character_selected.emit(selected_character_id)

func _on_back_pressed() -> void:
	AudioManager.play_fixed("sfx_ui_back")
	back_pressed.emit()

func _on_back_button_pressed():
	AudioManager.play_fixed("sfx_ui_back")
	# ... back logic ...
	hide()

func _on_confirm_button_pressed():
	AudioManager.play_fixed("sfx_ui_confirm")
	# ... confirm logic ...

func _on_character_hovered():
	AudioManager.play_fixed("sfx_ui_character_select") # Or navigation/hover

func _play_button_sound() -> void:
	AudioManager.play_fixed("sfx_ui_click")

func _play_navigate_sound() -> void:
	AudioManager.play_fixed("sfx_ui_hover")

# =============================================================================
# AMBIENT PARTICLES
# =============================================================================

func _setup_ambient_particles() -> void:
	"""Crea partículas de ambiente (sparkles mágicos) - más densas que en MainMenu"""
	var sparkle_tex = load("res://assets/ui/particles/particle_magic_sparkle.png")
	if not sparkle_tex:
		return
	
	# La textura tiene 4 sparkles en horizontal (1216x222, cada uno ~304px)
	var atlas_textures: Array[AtlasTexture] = []
	var sparkle_width = 304
	var sparkle_height = 222
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = sparkle_tex
		atlas.region = Rect2(i * sparkle_width, 0, sparkle_width, sparkle_height)
		atlas_textures.append(atlas)
	
	# Crear múltiples sistemas de partículas para mayor densidad
	# 8 sistemas en lugar de 4, cada uno con más partículas
	for i in range(8):
		var particles = GPUParticles2D.new()
		particles.name = "AmbientSparkle_%d" % i
		particles.amount = 60  # 60 partículas x 8 tipos = 480 total (mucho más que MainMenu)
		particles.lifetime = 6.0
		particles.randomness = 1.0
		particles.texture = atlas_textures[i % 4]  # Ciclar entre los 4 sprites
		
		# Crear material de partículas
		var mat = ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(960, 540, 0)  # Cubrir toda la pantalla
		
		# Movimiento suave en múltiples direcciones
		mat.direction = Vector3(0, -0.5, 0)
		mat.spread = 180.0  # Esférico para flotar en todas direcciones
		mat.initial_velocity_min = 8.0
		mat.initial_velocity_max = 30.0
		mat.gravity = Vector3(0, -5, 0)  # Flotar suavemente hacia arriba
		
		# Escala PEQUEÑA para que sean puntos individuales
		mat.scale_min = 0.02
		mat.scale_max = 0.10
		
		# Colores variados: dorado, púrpura, cyan para efecto mágico
		var hue_options = [0.12, 0.75, 0.55, 0.08]  # Dorado, púrpura, cyan, naranja
		var base_hue = hue_options[i % 4] + randf() * 0.05
		mat.color = Color.from_hsv(base_hue, 0.4, 1.0, 0.6)
		
		# Rotación lenta
		mat.angular_velocity_min = -30.0
		mat.angular_velocity_max = 30.0
		
		# Fade: Aparecer y desaparecer suavemente
		var color_curve = Curve.new()
		color_curve.add_point(Vector2(0.0, 0.0))
		color_curve.add_point(Vector2(0.15, 1.0))
		color_curve.add_point(Vector2(0.85, 1.0))
		color_curve.add_point(Vector2(1.0, 0.0))
		var alpha_curve = CurveTexture.new()
		alpha_curve.curve = color_curve
		mat.alpha_curve = alpha_curve
		
		particles.process_material = mat
		particles.position = Vector2(960, 540)  # Centro de la pantalla 1920x1080
		particles.z_index = 5  # Encima del fondo pero debajo de UI
		
		# Delay inicial diferente para cada sistema
		particles.preprocess = i * 0.75
		
		add_child(particles)

# =============================================================================
# PUBLIC API
# =============================================================================

func show_screen() -> void:
	"""Show the selection screen"""
	visible = true
	_load_characters()

	# Reset to first unlocked
	for i in range(all_characters.size()):
		if all_characters[i].id in unlocked_character_ids:
			current_index = i
			break

	_update_carousel_positions(false)
	_update_stats_display()

func hide_screen() -> void:
	"""Hide the screen"""
	visible = false

func get_selected_character() -> String:
	"""Get selected character ID"""
	return selected_character_id

func take_focus() -> void:
	"""Force focus to enable input processing"""
	visible = true
	# Give the engine a frame to process visibility before grabbing focus
	if is_inside_tree():
		await get_tree().process_frame
	
	# Since this screen handles input via _input(event), 
	# we just need to make sure we are the focus owner to receive GUI events if needed,
	# or simply ensure no other control is stealing focus.
	grab_focus()
