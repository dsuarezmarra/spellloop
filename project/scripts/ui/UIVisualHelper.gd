extends Node
class_name UIVisualHelper

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES DE COLOR
# ═══════════════════════════════════════════════════════════════════════════════

# Colores por Tier (1-5)
const TIER_COLORS = {
	1: Color(0.85, 0.85, 0.9),      # Común (Blanco/Gris)
	2: Color(0.2, 0.9, 0.4),        # Poco Común (Verde neón)
	3: Color(0.1, 0.6, 1.0),        # Raro (Azul eléctrico)
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

static func get_panel_style(tier: int, is_hover: bool = false, is_weapon: bool = false) -> StyleBoxFlat:
	var tier_color = get_color_for_tier(tier)
	var style = StyleBoxFlat.new()
	
	# Color de fondo base oscuro (Gris oscuro/negro)
	var base_bg = Color(0.08, 0.08, 0.12)
	
	if is_weapon:
		# Armas: Fondo más agresivo y saturado
		# Mezclar base oscura con un 25% del color del tier
		style.bg_color = base_bg.lerp(tier_color, 0.25)
		style.bg_color.a = 0.95
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
	else:
		# Items normales: Fondo sutil
		# Mezclar base oscura con un 15% del color del tier
		style.bg_color = base_bg.lerp(tier_color, 0.15)
		style.bg_color.a = 0.9
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		
	if is_hover:
		# Al hacer hover, aclarar ligeramente el fondo y el borde
		style.bg_color = style.bg_color.lightened(0.15)
		style.border_color = tier_color.lightened(0.2)
	else:
		style.border_color = tier_color
		
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	
	return style

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
	timer.timeout.connect(particles.queue_free)
