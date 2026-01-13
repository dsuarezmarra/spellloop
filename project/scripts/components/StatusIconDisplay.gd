# StatusIconDisplay.gd
# Componente para mostrar iconos de buffs/debuffs encima de entidades
# Incluye cuenta atrás y borde circular que se vacía al estilo WoW
#
# Uso: Añadir como hijo de una entidad (jugador/enemigo)
# Los iconos se posicionan automáticamente encima de la barra de vida

extends Node2D
class_name StatusIconDisplay

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

@export var is_player: bool = false  # True = iconos grandes, False = discretos
@export var icon_size: float = 20.0  # Tamaño base del icono
@export var icon_spacing: float = 2.0  # Espacio entre iconos
@export var offset_y: float = -8.0  # Offset encima de la barra de vida

# Tamaños diferenciados
const PLAYER_ICON_SIZE: float = 24.0
const ENEMY_ICON_SIZE: float = 14.0
const BOSS_ICON_SIZE: float = 18.0

# ═══════════════════════════════════════════════════════════════════════════════
# DEFINICIÓN DE EFECTOS DE ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Definición de todos los efectos posibles con sus iconos y colores
const STATUS_DEFINITIONS = {
	# === DEBUFFS PARA JUGADOR ===
	"slow": {
		"icon": "❄️",
		"color": Color(0.4, 0.7, 1.0),
		"bg_color": Color(0.2, 0.3, 0.5),
		"name": "Ralentizado",
		"is_debuff": true
	},
	"burn": {
		"icon": "🔥",
		"color": Color(1.0, 0.5, 0.1),
		"bg_color": Color(0.4, 0.2, 0.1),
		"name": "Quemadura",
		"is_debuff": true
	},
	"poison": {
		"icon": "☠️",
		"color": Color(0.5, 0.9, 0.3),
		"bg_color": Color(0.2, 0.3, 0.1),
		"name": "Veneno",
		"is_debuff": true
	},
	"stun": {
		"icon": "⭐",
		"color": Color(1.0, 1.0, 0.3),
		"bg_color": Color(0.4, 0.4, 0.1),
		"name": "Aturdido",
		"is_debuff": true
	},
	"weakness": {
		"icon": "💔",
		"color": Color(0.8, 0.3, 0.5),
		"bg_color": Color(0.3, 0.1, 0.2),
		"name": "Debilidad",
		"is_debuff": true
	},
	"curse": {
		"icon": "👁️",
		"color": Color(0.6, 0.3, 0.8),
		"bg_color": Color(0.2, 0.1, 0.3),
		"name": "Maldición",
		"is_debuff": true
	},
	"root": {
		"icon": "🌿",
		"color": Color(0.4, 0.6, 0.2),
		"bg_color": Color(0.2, 0.3, 0.1),
		"name": "Enraizado",
		"is_debuff": true
	},
	"pull": {
		"icon": "🌀",
		"color": Color(0.5, 0.3, 0.7),
		"bg_color": Color(0.2, 0.1, 0.3),
		"name": "Atraído",
		"is_debuff": true
	},
	
	# === DEBUFFS PARA ENEMIGOS ===
	"freeze": {
		"icon": "🧊",
		"color": Color(0.6, 0.9, 1.0),
		"bg_color": Color(0.2, 0.4, 0.5),
		"name": "Congelado",
		"is_debuff": true
	},
	"bleed": {
		"icon": "🩸",
		"color": Color(0.9, 0.2, 0.2),
		"bg_color": Color(0.4, 0.1, 0.1),
		"name": "Sangrado",
		"is_debuff": true
	},
	"shadow_mark": {
		"icon": "👤",
		"color": Color(0.3, 0.2, 0.4),
		"bg_color": Color(0.1, 0.1, 0.2),
		"name": "Marcado",
		"is_debuff": true
	},
	"blind": {
		"icon": "😵",
		"color": Color(0.7, 0.7, 0.7),
		"bg_color": Color(0.3, 0.3, 0.3),
		"name": "Cegado",
		"is_debuff": true
	},
	
	# === BUFFS PARA JUGADOR ===
	"speed_boost": {
		"icon": "⚡",
		"color": Color(1.0, 1.0, 0.4),
		"bg_color": Color(0.3, 0.3, 0.1),
		"name": "Velocidad",
		"is_debuff": false
	},
	"shield": {
		"icon": "🛡️",
		"color": Color(0.3, 0.7, 1.0),
		"bg_color": Color(0.1, 0.3, 0.4),
		"name": "Escudo",
		"is_debuff": false
	},
	"damage_boost": {
		"icon": "⚔️",
		"color": Color(1.0, 0.4, 0.3),
		"bg_color": Color(0.4, 0.1, 0.1),
		"name": "Poder",
		"is_debuff": false
	},
	"regen": {
		"icon": "💚",
		"color": Color(0.3, 1.0, 0.4),
		"bg_color": Color(0.1, 0.4, 0.1),
		"name": "Regeneración",
		"is_debuff": false
	},
	"invulnerable": {
		"icon": "✨",
		"color": Color(1.0, 0.9, 0.5),
		"bg_color": Color(0.4, 0.3, 0.1),
		"name": "Invulnerable",
		"is_debuff": false
	},
	
	# === BUFFS PARA ENEMIGOS ===
	"enraged": {
		"icon": "💢",
		"color": Color(1.0, 0.3, 0.3),
		"bg_color": Color(0.4, 0.1, 0.1),
		"name": "Enfurecido",
		"is_debuff": false
	},
	"speed_buff": {
		"icon": "💨",
		"color": Color(0.7, 0.9, 1.0),
		"bg_color": Color(0.2, 0.3, 0.4),
		"name": "Acelerado",
		"is_debuff": false
	},
	"shielded": {
		"icon": "🔰",
		"color": Color(0.9, 0.8, 0.3),
		"bg_color": Color(0.3, 0.3, 0.1),
		"name": "Protegido",
		"is_debuff": false
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Diccionario de efectos activos: {status_id: {timer, max_duration, icon_node}}
var active_effects: Dictionary = {}

# Referencia al contenedor de iconos
var icon_container: Node2D = null

# Nodo visual para dibujar
var visual_node: Node2D = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# CRÍTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Crear contenedor de iconos
	icon_container = Node2D.new()
	icon_container.name = "IconContainer"
	add_child(icon_container)
	
	# Ajustar tamaño según tipo de entidad
	if is_player:
		icon_size = PLAYER_ICON_SIZE
	else:
		icon_size = ENEMY_ICON_SIZE
	
	# NOTA: La posición Y se establece externamente por BasePlayer/EnemyBase
	# No sobreescribir aquí para permitir posicionamiento personalizado

func _process(delta: float) -> void:
	_update_effects(delta)
	_reposition_icons()

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func add_effect(status_id: String, duration: float) -> void:
	"""Añadir o refrescar un efecto de estado"""
	if not STATUS_DEFINITIONS.has(status_id):
		push_warning("[StatusIconDisplay] Efecto desconocido: %s" % status_id)
		return
	
	# Si ya existe, solo refrescar duración
	if active_effects.has(status_id):
		active_effects[status_id].timer = duration
		active_effects[status_id].max_duration = duration
		return
	
	# Crear nuevo icono
	var icon_node = _create_icon_node(status_id, duration)
	icon_container.add_child(icon_node)
	
	active_effects[status_id] = {
		"timer": duration,
		"max_duration": duration,
		"icon_node": icon_node
	}

func remove_effect(status_id: String) -> void:
	"""Eliminar un efecto de estado"""
	if not active_effects.has(status_id):
		return
	
	var effect = active_effects[status_id]
	if is_instance_valid(effect.icon_node):
		effect.icon_node.queue_free()
	
	active_effects.erase(status_id)

func clear_all_effects() -> void:
	"""Eliminar todos los efectos"""
	for status_id in active_effects.keys():
		remove_effect(status_id)

func has_effect(status_id: String) -> bool:
	"""Verificar si tiene un efecto activo"""
	return active_effects.has(status_id)

func get_effect_time_remaining(status_id: String) -> float:
	"""Obtener tiempo restante de un efecto"""
	if active_effects.has(status_id):
		return active_effects[status_id].timer
	return 0.0

func set_entity_type(entity_is_player: bool, is_boss: bool = false) -> void:
	"""Configurar tipo de entidad para ajustar tamaño de iconos"""
	is_player = entity_is_player
	if is_player:
		icon_size = PLAYER_ICON_SIZE
	elif is_boss:
		icon_size = BOSS_ICON_SIZE
	else:
		icon_size = ENEMY_ICON_SIZE

# ═══════════════════════════════════════════════════════════════════════════════
# LÓGICA INTERNA
# ═══════════════════════════════════════════════════════════════════════════════

func _update_effects(delta: float) -> void:
	"""Actualizar temporizadores y eliminar efectos expirados"""
	var to_remove: Array = []
	
	for status_id in active_effects:
		var effect = active_effects[status_id]
		effect.timer -= delta
		
		if effect.timer <= 0:
			to_remove.append(status_id)
		elif is_instance_valid(effect.icon_node):
			# Forzar redibujado para actualizar cuenta atrás
			effect.icon_node.queue_redraw()
	
	# Eliminar efectos expirados
	for status_id in to_remove:
		remove_effect(status_id)

func _reposition_icons() -> void:
	"""Reposicionar iconos para que estén centrados"""
	var count = active_effects.size()
	if count == 0:
		return
	
	var total_width = count * icon_size + (count - 1) * icon_spacing
	var start_x = -total_width / 2.0
	
	var idx = 0
	for status_id in active_effects:
		var effect = active_effects[status_id]
		if is_instance_valid(effect.icon_node):
			effect.icon_node.position.x = start_x + idx * (icon_size + icon_spacing) + icon_size / 2.0
			effect.icon_node.position.y = 0
		idx += 1

func _create_icon_node(status_id: String, duration: float) -> Node2D:
	"""Crear nodo visual para un icono de estado"""
	var def = STATUS_DEFINITIONS[status_id]
	var node = Node2D.new()
	node.name = "Icon_" + status_id
	
	# Guardar datos para el dibujado
	node.set_meta("status_id", status_id)
	node.set_meta("max_duration", duration)
	node.set_meta("icon_size", icon_size)
	node.set_meta("is_player", is_player)
	
	# Conectar señal de dibujado
	node.draw.connect(_draw_icon.bind(node))
	node.queue_redraw()
	
	return node

func _draw_icon(node: Node2D) -> void:
	"""Dibujar un icono de estado con cuenta atrás y borde circular"""
	var status_id = node.get_meta("status_id")
	if not STATUS_DEFINITIONS.has(status_id):
		return
	
	if not active_effects.has(status_id):
		return
	
	var def = STATUS_DEFINITIONS[status_id]
	var effect = active_effects[status_id]
	var size = node.get_meta("icon_size")
	var entity_is_player = node.get_meta("is_player")
	var max_dur = effect.max_duration
	var current_time = effect.timer
	var progress = current_time / max_dur if max_dur > 0 else 0.0
	
	var half_size = size / 2.0
	var center = Vector2.ZERO
	
	# === FONDO DEL ICONO ===
	# Círculo de fondo
	node.draw_circle(center, half_size, def.bg_color)
	
	# === BORDE CIRCULAR DE PROGRESO (estilo WoW) ===
	# Borde de fondo (completo, oscuro)
	var border_width = 3.0 if entity_is_player else 2.0
	node.draw_arc(center, half_size - border_width / 2.0, 0, TAU, 32, Color(0.2, 0.2, 0.2, 0.8), border_width)
	
	# Borde de progreso (se vacía en sentido horario desde arriba)
	if progress > 0.01:
		var start_angle = -PI / 2.0  # Empezar desde arriba
		var end_angle = start_angle + TAU * progress
		var border_color = def.color
		if def.is_debuff:
			border_color = Color(border_color.r * 0.8, border_color.g * 0.8, border_color.b * 0.8, 1.0)
		node.draw_arc(center, half_size - border_width / 2.0, start_angle, end_angle, 32, border_color, border_width)
	
	# === ICONO EMOJI ===
	# Para el jugador: icono grande y visible
	# Para enemigos: icono más pequeño
	var font = ThemeDB.fallback_font
	var font_size = int(size * 0.6) if entity_is_player else int(size * 0.5)
	
	# Calcular posición para centrar el emoji
	var icon_text = def.icon
	var text_size = font.get_string_size(icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center - text_size / 2.0 + Vector2(0, text_size.y * 0.3)
	
	node.draw_string(font, text_pos, icon_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# === CUENTA ATRÁS NUMÉRICA ===
	if entity_is_player or current_time > 1.0:
		var time_text = ""
		if current_time >= 10.0:
			time_text = "%d" % int(current_time)
		elif current_time >= 1.0:
			time_text = "%.0f" % current_time
		else:
			time_text = ".%d" % int(current_time * 10)
		
		var time_font_size = int(size * 0.35) if entity_is_player else int(size * 0.3)
		var time_size = font.get_string_size(time_text, HORIZONTAL_ALIGNMENT_CENTER, -1, time_font_size)
		
		# Posicionar en la esquina inferior derecha del icono
		var time_pos = center + Vector2(half_size * 0.3, half_size * 0.6)
		
		# Fondo para el número
		var bg_rect = Rect2(time_pos - Vector2(2, time_size.y * 0.8), time_size + Vector2(4, 4))
		node.draw_rect(bg_rect, Color(0, 0, 0, 0.7), true)
		
		# Número
		var time_color = Color.WHITE
		if current_time <= 2.0:
			time_color = Color(1.0, 0.5, 0.5)  # Rojo cuando queda poco
		node.draw_string(font, time_pos, time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, time_font_size, time_color)
	
	# === INDICADOR DE DEBUFF/BUFF ===
	if entity_is_player:
		# Pequeño triángulo indicando si es buff (arriba) o debuff (abajo)
		var indicator_size = 4.0
		var indicator_pos = center + Vector2(-half_size * 0.7, -half_size * 0.5)
		
		if def.is_debuff:
			# Triángulo rojo apuntando abajo
			var points = PackedVector2Array([
				indicator_pos + Vector2(0, -indicator_size),
				indicator_pos + Vector2(-indicator_size, indicator_size),
				indicator_pos + Vector2(indicator_size, indicator_size)
			])
			node.draw_colored_polygon(points, Color(1.0, 0.3, 0.3, 0.9))
		else:
			# Triángulo verde apuntando arriba
			var points = PackedVector2Array([
				indicator_pos + Vector2(0, indicator_size),
				indicator_pos + Vector2(-indicator_size, -indicator_size),
				indicator_pos + Vector2(indicator_size, -indicator_size)
			])
			node.draw_colored_polygon(points, Color(0.3, 1.0, 0.3, 0.9))
