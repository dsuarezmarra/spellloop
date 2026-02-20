extends Node
class_name UIVisualHelper

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES DE COLOR
# ═══════════════════════════════════════════════════════════════════════════════

# Colores por Tier (1-5)
const TIER_COLORS = {
	1: Color(0.6, 0.6, 0.65),       # Común (Gris plateado - distintivo)
	2: Color(0.2, 0.85, 0.35),      # Poco Común (Verde brillante)
	3: Color(0.2, 0.5, 1.0),        # Raro (Azul eléctrico)
	4: Color(0.7, 0.2, 1.0),        # Épico (Púrpura)
	5: Color(1.0, 0.7, 0.1),        # Legendario (Dorado/Naranja)
}

# Colores por Tipo
const TYPE_COLORS = {
	"weapon": Color(1.0, 0.3, 0.2), # Rojo intenso (Armas)
	"upgrade": Color(0.4, 0.8, 1.0),# Azul claro (Mejoras)
	"item": Color(0.9, 0.9, 0.5),   # Amarillo pálido (Items)
	"special": Color(1.0, 0.2, 0.8) # Rosa (Especial)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTILOS
# ═══════════════════════════════════════════════════════════════════════════════

static func get_color_for_tier(tier: int) -> Color:
	return TIER_COLORS.get(tier, TIER_COLORS[1])

static func get_panel_style(tier: int, is_hover: bool = false, is_weapon: bool = false) -> StyleBox:
	var tier_color = get_color_for_tier(tier)
	var style_tex = StyleBoxTexture.new()
	var base_bg = Color(0.08, 0.08, 0.12)
	
	# Load panel texture
	if is_weapon:
		# Could have a specific weapon panel variants, for now reuse with tint or just standard
		style_tex.texture = load("res://assets/ui/skins/panel_stone_9slice.png")
		style_tex.modulate_color = base_bg.lerp(tier_color, 0.3) # Tint it
	else:
		style_tex.texture = load("res://assets/ui/skins/panel_stone_9slice.png")
		if tier > 1:
			style_tex.modulate_color = Color.WHITE.lerp(tier_color, 0.1)
		
	# 9-Slice Margins (Based on the generated image usually ~32px-40px for 128px image)
	# The prompt asked for thick golden ornate frame. Let's precise 32.
	style_tex.texture_margin_left = 32
	style_tex.texture_margin_top = 32
	style_tex.texture_margin_right = 32
	style_tex.texture_margin_bottom = 32
	
	if is_hover:
		style_tex.modulate_color = style_tex.modulate_color.lightened(0.2)
		
	return style_tex

# ═══════════════════════════════════════════════════════════════════════════════
# EFECTOS VISUALES
# ═══════════════════════════════════════════════════════════════════════════════

static func apply_tier_glow(control: Control, tier: int):
	"""Añade un nodo ColorRect detrás para simular glow"""
	var color = get_color_for_tier(tier)
	var glow = Control.new()
	glow.name = "TierGlow"
	glow.show_behind_parent = true
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Usar drawing personalizado para el glow difuso
	var canvas_item = Node2D.new()
	canvas_item.position = control.size / 2
	
	canvas_item.draw.connect(func():
		var radius = max(control.size.x, control.size.y) * 0.7
		# Glow central intenso
		canvas_item.draw_circle(Vector2.ZERO, radius * 0.5, Color(color.r, color.g, color.b, 0.2))
		# Glow exterior difuso
		for i in range(3):
			canvas_item.draw_circle(Vector2.ZERO, radius * (0.8 + i*0.2), Color(color.r, color.g, color.b, 0.1 - i*0.02))
	)
	
	glow.add_child(canvas_item)
	control.add_child(glow)
	control.move_child(glow, 0) # Al fondo

static func spawn_confetti(parent: Node, position: Vector2, color: Color = Color.WHITE):
	"""Crea una explosión de partículas de UI"""
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 30
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 1.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 400)
	particles.initial_velocity_min = 200
	particles.initial_velocity_max = 400
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = color
	
	parent.add_child(particles)
	
	# Auto-borrado
	var timer = parent.get_tree().create_timer(2.0)
	timer.timeout.connect(func(): if is_instance_valid(particles): particles.queue_free())

# ═══════════════════════════════════════════════════════════════════════════════
# ICONOS
# ═══════════════════════════════════════════════════════════════════════════════

static func load_icon_or_fallback(icon_path: String, fallback_emoji: String = "❓") -> Variant:
	"""
	Intenta cargar una textura de icono. Si falla, devuelve null.
	Uso: var tex = UIVisualHelper.load_icon_or_fallback(path)
	     if tex: icon_rect.texture = tex else: mostrar fallback
	"""
	if icon_path.begins_with("res://") and ResourceLoader.exists(icon_path):
		return load(icon_path)
	return null

static func get_safe_icon_text(icon: String, fallback: String = "❓") -> String:
	"""
	Si el icono es una ruta (res://...), devuelve el fallback en vez de mostrar la ruta.
	Si es un emoji/texto normal, lo devuelve tal cual.
	"""
	if icon.begins_with("res://"):
		return fallback
	return icon

static func setup_icon_display(container: Control, icon_path: String, size: Vector2 = Vector2(48, 48), fallback_emoji: String = "❓") -> void:
	"""
	Configura un container con TextureRect si la imagen existe,
	o Label con emoji fallback si no.
	"""
	# Limpiar hijos previos
	for child in container.get_children():
		child.queue_free()
	
	if icon_path.begins_with("res://") and ResourceLoader.exists(icon_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(icon_path)
		tex_rect.custom_minimum_size = size
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(tex_rect)
	else:
		var icon_label = Label.new()
		# Si es ruta que no existe, mostrar fallback; si no es ruta, mostrar el texto original
		icon_label.text = fallback_emoji if icon_path.begins_with("res://") else icon_path
		icon_label.add_theme_font_size_override("font_size", int(size.x * 0.7))
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(icon_label)
