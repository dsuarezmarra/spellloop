# RewardRevealSystem.gd
# Sistema espectacular de presentación de recompensas
# Inspirado en Vampire Survivors y slot machines
#
# Modos:
# - SLOT_REEL: Para level up (opciones giran como tragaperras)
# - CHEST_BURST: Para cofres (explosión de luz y partículas)
# - ITEM_SHOWCASE: Para items legendarios (zoom dramático)

extends CanvasLayer
class_name RewardRevealSystem

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal reveal_started()
signal reveal_finished()
signal item_revealed(item: Dictionary, index: int)
signal all_items_revealed(items: Array)
signal selection_ready()  # Player can now select

# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS Y CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

enum RevealMode { SLOT_REEL, CHEST_BURST, ITEM_SHOWCASE }

enum Rarity { COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4, LEGENDARY = 5 }

const RARITY_COLORS: Dictionary = {
	1: Color(0.7, 0.7, 0.7),       # Common - Gray
	2: Color(0.3, 0.8, 0.3),       # Uncommon - Green  
	3: Color(0.3, 0.5, 1.0),       # Rare - Blue
	4: Color(0.7, 0.3, 0.9),       # Epic - Purple
	5: Color(1.0, 0.75, 0.2)       # Legendary - Gold
}

const RARITY_GLOW_INTENSITY: Dictionary = {
	1: 0.0,    # Common - no glow
	2: 0.3,    # Uncommon - subtle
	3: 0.5,    # Rare - moderate
	4: 0.7,    # Epic - strong
	5: 1.0     # Legendary - maximum
}

# Timing (segundos)
const SPIN_DURATION_BASE: float = 0.6      # Duración base por reel
const SPIN_STAGGER_DELAY: float = 0.25     # Delay entre reels
const CHEST_SHAKE_DURATION: float = 0.5    # Tiempo de shake del cofre
const CHEST_BURST_DURATION: float = 0.4    # Duración de la explosión
const ITEM_FLOAT_DURATION: float = 0.6     # Tiempo que el item flota
const LEGENDARY_PAUSE: float = 0.8         # Pausa extra para legendarios

# ═══════════════════════════════════════════════════════════════════════════════
# VARIABLES DE ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var current_mode: RevealMode = RevealMode.SLOT_REEL
var is_revealing: bool = false
var items_to_reveal: Array = []
var revealed_count: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# NODOS UI
# ═══════════════════════════════════════════════════════════════════════════════

var dark_overlay: ColorRect
var main_container: Control
var title_label: Label
var subtitle_label: Label

# Slot Reel específicos
var reels_container: HBoxContainer
var reel_panels: Array[Control] = []
var reel_tweens: Array[Tween] = []

# Chest Burst específicos
var chest_container: Control
var chest_sprite: Control
var light_rays: Control
var sparkle_particles: CPUParticles2D
var item_showcase: Control

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 150  # Por encima de todo
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _build_ui() -> void:
	"""Construir la estructura base de UI"""
	# Overlay oscuro
	dark_overlay = ColorRect.new()
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_overlay.color = Color(0.0, 0.0, 0.0, 0.0)  # Empieza transparente
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dark_overlay)
	
	# Container principal centrado
	main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Título
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_label.position.y = 80
	title_label.modulate.a = 0.0
	main_container.add_child(title_label)
	
	# Subtítulo
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subtitle_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle_label.position.y = 140
	subtitle_label.modulate.a = 0.0
	main_container.add_child(subtitle_label)
	
	# Container de reels (slot machine)
	_build_reels_container()
	
	# Container de cofre (chest burst)
	_build_chest_container()

func _build_reels_container() -> void:
	"""Construir los carretes de tragaperras"""
	reels_container = HBoxContainer.new()
	reels_container.alignment = BoxContainer.ALIGNMENT_CENTER
	reels_container.add_theme_constant_override("separation", 20)
	reels_container.set_anchors_preset(Control.PRESET_CENTER)
	reels_container.visible = false
	main_container.add_child(reels_container)
	
	# Crear 4 paneles de reel (máximo opciones en level up)
	for i in range(4):
		var reel = _create_reel_panel(i)
		reels_container.add_child(reel)
		reel_panels.append(reel)

func _create_reel_panel(index: int) -> Control:
	"""Crear un panel de reel individual"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 260)
	panel.name = "Reel_%d" % index
	
	# Estilo del panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	
	# Container interno con clip (para efecto de scroll)
	var clip = Control.new()
	clip.clip_contents = true
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.custom_minimum_size = Vector2(180, 260)
	panel.add_child(clip)
	
	# VBox para los items que "giran"
	var items_strip = VBoxContainer.new()
	items_strip.name = "ItemsStrip"
	items_strip.add_theme_constant_override("separation", 10)
	items_strip.position = Vector2(0, 0)
	clip.add_child(items_strip)
	
	# Indicador de selección (aparece después del spin)
	var indicator = Label.new()
	indicator.name = "Indicator"
	indicator.text = "▲"
	indicator.add_theme_font_size_override("font_size", 20)
	indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	indicator.position.y = -10
	indicator.visible = false
	panel.add_child(indicator)
	
	return panel

func _build_chest_container() -> void:
	"""Construir el container para animación de cofre"""
	chest_container = Control.new()
	chest_container.set_anchors_preset(Control.PRESET_CENTER)
	chest_container.custom_minimum_size = Vector2(400, 400)
	chest_container.visible = false
	main_container.add_child(chest_container)
	
	# Rayos de luz (se crean dinámicamente)
	light_rays = Control.new()
	light_rays.name = "LightRays"
	light_rays.set_anchors_preset(Control.PRESET_CENTER)
	light_rays.modulate.a = 0.0
	chest_container.add_child(light_rays)
	
	# Representación visual del cofre
	chest_sprite = ColorRect.new()  # Placeholder - reemplazar con sprite real
	chest_sprite.name = "ChestSprite"
	chest_sprite.custom_minimum_size = Vector2(80, 60)
	chest_sprite.color = Color(0.6, 0.4, 0.2)
	chest_sprite.set_anchors_preset(Control.PRESET_CENTER)
	chest_sprite.position = Vector2(-40, -30)
	chest_container.add_child(chest_sprite)
	
	# Partículas de brillo
	sparkle_particles = CPUParticles2D.new()
	sparkle_particles.name = "Sparkles"
	sparkle_particles.emitting = false
	sparkle_particles.amount = 30
	sparkle_particles.lifetime = 0.8
	sparkle_particles.explosiveness = 0.9
	sparkle_particles.spread = 180.0
	sparkle_particles.gravity = Vector2(0, 100)
	sparkle_particles.initial_velocity_min = 100.0
	sparkle_particles.initial_velocity_max = 250.0
	sparkle_particles.scale_amount_min = 3.0
	sparkle_particles.scale_amount_max = 6.0
	sparkle_particles.color = Color(1.0, 0.9, 0.5)
	chest_container.add_child(sparkle_particles)
	
	# Showcase del item revelado
	item_showcase = Control.new()
	item_showcase.name = "ItemShowcase"
	item_showcase.set_anchors_preset(Control.PRESET_CENTER)
	item_showcase.position.y = -80
	item_showcase.modulate.a = 0.0
	chest_container.add_child(item_showcase)

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func reveal_level_up_options(options: Array, title: String = "⬆ LEVEL UP! ⬆") -> void:
	"""Iniciar reveal estilo slot machine para opciones de level up"""
	current_mode = RevealMode.SLOT_REEL
	items_to_reveal = options
	title_label.text = title
	subtitle_label.text = "Las opciones se están revelando..."
	
	_start_reveal()
	await _animate_slot_reels(options)
	selection_ready.emit()

func reveal_chest_items(items: Array, chest_rarity: int = 1, title: String = "🎁 ¡TESORO!") -> void:
	"""Iniciar reveal con explosión de cofre"""
	current_mode = RevealMode.CHEST_BURST
	items_to_reveal = items
	title_label.text = title
	subtitle_label.text = ""
	
	_start_reveal()
	await _animate_chest_burst(items, chest_rarity)
	selection_ready.emit()

func reveal_single_item(item: Dictionary, rarity: int = 1) -> void:
	"""Reveal dramático para un solo item (legendarios, boss drops)"""
	current_mode = RevealMode.ITEM_SHOWCASE
	items_to_reveal = [item]
	
	_start_reveal()
	await _animate_item_showcase(item, rarity)
	selection_ready.emit()

func skip_animation() -> void:
	"""Saltar animación actual (para speedrunners)"""
	if not is_revealing:
		return
	
	# Cancelar todos los tweens activos
	for tween in reel_tweens:
		if tween and tween.is_valid():
			tween.kill()
	reel_tweens.clear()
	
	# Mostrar todo inmediatamente
	_show_all_items_instantly()
	
	is_revealing = false
	all_items_revealed.emit(items_to_reveal)
	selection_ready.emit()

func close() -> void:
	"""Cerrar el sistema de reveal"""
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.0, 0.2)
	tween.parallel().tween_property(main_container, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		reels_container.visible = false
		chest_container.visible = false
		reveal_finished.emit()
	)

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMACIONES INTERNAS
# ═══════════════════════════════════════════════════════════════════════════════

func _start_reveal() -> void:
	"""Preparar y mostrar el sistema"""
	visible = true
	is_revealing = true
	revealed_count = 0
	main_container.modulate.a = 1.0
	
	reveal_started.emit()
	
	# Fade in del overlay
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.85, 0.3)
	
	# Mostrar título con bounce
	await get_tree().create_timer(0.1).timeout
	_animate_title_entrance()

func _animate_title_entrance() -> void:
	"""Animación de entrada del título"""
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.4)
	
	# Subtítulo fade in
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.2)

func _animate_slot_reels(options: Array) -> void:
	"""Animación de carretes girando y deteniéndose"""
	reels_container.visible = true
	
	# Ocultar reels no usados
	for i in range(reel_panels.size()):
		reel_panels[i].visible = i < options.size()
	
	# Preparar cada reel con items "ficticios" para el spin
	for i in range(options.size()):
		_prepare_reel_for_spin(i, options[i])
	
	# Esperar un momento antes de empezar
	await get_tree().create_timer(0.3).timeout
	
	# Iniciar spin de todos los reels
	for i in range(options.size()):
		_start_reel_spin(i)
	
	# Detener reels secuencialmente
	for i in range(options.size()):
		await get_tree().create_timer(SPIN_DURATION_BASE).timeout
		await _stop_reel(i, options[i])
		item_revealed.emit(options[i], i)
		revealed_count += 1
	
	# Animación final de "todas reveladas"
	await get_tree().create_timer(0.2).timeout
	_pulse_all_reels()
	
	subtitle_label.text = "¡Elige tu mejora!"
	is_revealing = false
	all_items_revealed.emit(options)

func _prepare_reel_for_spin(index: int, _final_item: Dictionary) -> void:
	"""Preparar un reel con items aleatorios para el efecto de spin"""
	var panel = reel_panels[index]
	var strip = panel.get_node("ItemsStrip") if panel.has_node("ItemsStrip") else null
	if not strip:
		return
	
	# Limpiar strip
	for child in strip.get_children():
		child.queue_free()
	
	# Crear múltiples items ficticios para el scroll
	var fake_icons = ["🔥", "⚡", "❄️", "🛡️", "⚔️", "💀", "✨", "🌟", "💎", "🎯"]
	for i in range(15):  # Suficientes para el efecto de scroll
		var fake_item = _create_reel_item_display(fake_icons[i % fake_icons.size()], "???", Color.WHITE)
		strip.add_child(fake_item)

func _start_reel_spin(index: int) -> void:
	"""Iniciar animación de spin para un reel"""
	var panel = reel_panels[index]
	var strip = panel.get_node("ItemsStrip") if panel.has_node("ItemsStrip") else null
	if not strip:
		return
	
	# Animación de scroll continuo
	var tween = create_tween()
	tween.set_loops()  # Loop infinito hasta que paremos
	tween.tween_property(strip, "position:y", -500.0, 0.15)
	tween.tween_callback(func(): strip.position.y = 0)
	
	reel_tweens.append(tween)

func _stop_reel(index: int, final_item: Dictionary) -> void:
	"""Detener un reel mostrando el item final"""
	# Cancelar tween de spin
	if index < reel_tweens.size() and reel_tweens[index]:
		reel_tweens[index].kill()
	
	var panel = reel_panels[index]
	var strip = panel.get_node("ItemsStrip") if panel.has_node("ItemsStrip") else null
	if not strip:
		return
	
	# Limpiar y mostrar item final
	for child in strip.get_children():
		child.queue_free()
	
	var tree = get_tree()
	if tree:
		await tree.process_frame
	
	# Crear display del item real
	var icon = final_item.get("icon", "❓")
	var item_name = final_item.get("name", "???")
	var rarity = final_item.get("tier", 1)
	var color = RARITY_COLORS.get(rarity, Color.WHITE)
	
	var item_display = _create_reel_item_display(icon, item_name, color)
	item_display.position.y = -300  # Empieza arriba
	strip.add_child(item_display)
	
	# Animación de llegada con bounce
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(item_display, "position:y", 50.0, 0.4)
	
	# Screen shake pequeño
	_do_screen_shake(2.0)
	
	# Mostrar indicador
	var indicator = panel.get_node_or_null("Indicator")
	if indicator:
		indicator.visible = true
	
	await tween.finished

func _create_reel_item_display(icon: String, item_name: String, color: Color) -> Control:
	"""Crear un display de item para el reel"""
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.custom_minimum_size = Vector2(160, 200)
	
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(80, 80)
	container.add_child(icon_container)

	if icon.begins_with("res://") and ResourceLoader.exists(icon):
		var tex_rect = TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(80, 80)
		tex_rect.texture = load(icon)
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(tex_rect)
	else:
		var icon_label = Label.new()
		# Mostrar emoji fallback si es una ruta que no existe, no mostrar la ruta como texto
		icon_label.text = "❓" if icon.begins_with("res://") else icon
		icon_label.add_theme_font_size_override("font_size", 56)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(icon_label)
	
	# Separador
	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 10)
	container.add_child(sep)
	
	# Nombre
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(name_label)
	
	return container

func _pulse_all_reels() -> void:
	"""Pulso visual cuando todos los reels están revelados"""
	for panel in reel_panels:
		if not panel.visible:
			continue
		var tween = create_tween()
		tween.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.1)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)

func _animate_chest_burst(items: Array, rarity: int) -> void:
	"""Animación de explosión de cofre"""
	chest_container.visible = true
	chest_container.modulate.a = 1.0
	
	var color = RARITY_COLORS.get(rarity, Color.WHITE)
	
	# Fase 1: Shake del cofre
	await _shake_chest()
	
	# Fase 2: Explosión
	await _burst_chest(color, rarity)
	
	# Fase 3: Revelar items flotando
	for i in range(items.size()):
		await _float_item_from_chest(items[i], i)
		item_revealed.emit(items[i], i)
		revealed_count += 1
	
	is_revealing = false
	all_items_revealed.emit(items)

func _shake_chest() -> void:
	"""Hacer que el cofre tiemble antes de abrirse"""
	var original_pos = chest_sprite.position
	var intensity = 3.0
	
	for i in range(8):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		chest_sprite.position = original_pos + offset
		intensity += 1.0
		await get_tree().create_timer(0.05).timeout
	
	chest_sprite.position = original_pos

func _burst_chest(color: Color, rarity: int) -> void:
	"""Explosión de luz del cofre"""
	# Flash de pantalla
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(color.r, color.g, color.b, 0.0)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.6, 0.1)
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
	
	# Partículas
	sparkle_particles.color = color
	sparkle_particles.amount = 20 + (rarity * 15)
	sparkle_particles.emitting = true
	
	# Rayos de luz (simplificado - solo glow)
	light_rays.modulate = color
	var ray_tween = create_tween()
	ray_tween.tween_property(light_rays, "modulate:a", 0.8, 0.1)
	ray_tween.tween_property(light_rays, "modulate:a", 0.0, 0.5)
	
	# Screen shake según rareza
	_do_screen_shake(2.0 + rarity * 1.5)
	
	# Ocultar cofre
	chest_sprite.visible = false
	
	await get_tree().create_timer(CHEST_BURST_DURATION).timeout

func _float_item_from_chest(item: Dictionary, _index: int) -> void:
	"""Hacer que un item flote desde el cofre"""
	var icon = item.get("icon", "❓")
	var item_name = item.get("name", "???")
	var rarity = item.get("tier", 1)
	var color = RARITY_COLORS.get(rarity, Color.WHITE)
	
	# Crear display del item
	var item_node = _create_floating_item(icon, item_name, color)
	item_showcase.add_child(item_node)
	
	item_node.position.y = 100  # Empieza abajo
	item_node.modulate.a = 0.0
	item_node.scale = Vector2(0.3, 0.3)
	
	# Animación de flotación
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(item_node, "position:y", -50.0, ITEM_FLOAT_DURATION)
	tween.parallel().tween_property(item_node, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(item_node, "scale", Vector2(1.2, 1.2), ITEM_FLOAT_DURATION)
	
	# Pausa extra para legendarios
	if rarity >= 5:
		await get_tree().create_timer(LEGENDARY_PAUSE).timeout
	
	await tween.finished

func _create_floating_item(icon: String, item_name: String, color: Color) -> Control:
	"""Crear item flotante para showcase"""
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Icono
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(100, 100)
	container.add_child(icon_container)

	if icon.begins_with("res://") and ResourceLoader.exists(icon):
		var tex_rect = TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(100, 100)
		tex_rect.texture = load(icon)
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(tex_rect)
	else:
		var icon_label = Label.new()
		# Mostrar emoji fallback si es una ruta que no existe, no mostrar la ruta como texto
		icon_label.text = "❓" if icon.begins_with("res://") else icon
		icon_label.add_theme_font_size_override("font_size", 72)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(icon_label)
	
	# Nombre con glow
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_label)
	
	return container

func _animate_item_showcase(item: Dictionary, rarity: int) -> void:
	"""Reveal dramático de un solo item"""
	chest_container.visible = true
	chest_sprite.visible = false
	
	var color = RARITY_COLORS.get(rarity, Color.WHITE)
	
	# Partículas según rareza
	sparkle_particles.color = color
	sparkle_particles.amount = 30 + (rarity * 20)
	sparkle_particles.emitting = true
	
	# Flash de pantalla para legendarios
	if rarity >= 5:
		_do_legendary_flash(color)
		_do_screen_shake(5.0)
	
	await _float_item_from_chest(item, 0)
	
	is_revealing = false
	all_items_revealed.emit([item])

func _do_legendary_flash(color: Color) -> void:
	"""Flash especial para items legendarios"""
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(color.r, color.g, color.b, 0.0)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.9, 0.05)
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func _do_screen_shake(intensity: float) -> void:
	"""Aplicar screen shake a la cámara"""
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(intensity)
	else:
		# Fallback: shake del container
		var original_pos = main_container.position
		for i in range(5):
			main_container.position = original_pos + Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			await get_tree().create_timer(0.03).timeout
		main_container.position = original_pos

func _show_all_items_instantly() -> void:
	"""Mostrar todos los items sin animación (para skip)"""
	match current_mode:
		RevealMode.SLOT_REEL:
			reels_container.visible = true
			for i in range(items_to_reveal.size()):
				if i < reel_panels.size():
					var panel = reel_panels[i]
					panel.visible = true
					var strip = panel.get_node_or_null("ItemsStrip")
					if strip:
						for child in strip.get_children():
							child.queue_free()
						var item = items_to_reveal[i]
						var icon = item.get("icon", "❓")
						var item_name = item.get("name", "???")
						var rarity = item.get("tier", 1)
						var color = RARITY_COLORS.get(rarity, Color.WHITE)
						var display = _create_reel_item_display(icon, item_name, color)
						display.position.y = 50
						strip.add_child(display)
		
		RevealMode.CHEST_BURST, RevealMode.ITEM_SHOWCASE:
			chest_container.visible = true
			chest_sprite.visible = false
			for item in items_to_reveal:
				var icon = item.get("icon", "❓")
				var item_name = item.get("name", "???")
				var rarity = item.get("tier", 1)
				var color = RARITY_COLORS.get(rarity, Color.WHITE)
				var display = _create_floating_item(icon, item_name, color)
				display.modulate.a = 1.0
				item_showcase.add_child(display)
