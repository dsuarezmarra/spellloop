# FloatingText.gd
# Sistema de texto flotante para mostrar daño, curación, etc.

extends Node2D
class_name FloatingText

# Configuración visual
var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 16
var duration: float = 1.0
var rise_speed: float = 50.0
var fade_start: float = 0.5  # Cuando empieza a desvanecerse (% de duration)

# Estado interno
var _timer: float = 0.0
var _label: Label = null
var _initial_y: float = 0.0

# Singleton para acceso global
static var instance: FloatingText = null

func _ready() -> void:
	# Registrar como singleton si no existe
	if instance == null:
		instance = self
	
	# Crear un CanvasLayer para que los textos aparezcan sobre todo
	z_index = 100

func _process(delta: float) -> void:
	# Procesar hijos (textos flotantes activos)
	pass

# ═══════════════════════════════════════════════════════════════════════════════
# API ESTÁTICA PARA CREAR TEXTOS FLOTANTES
# ═══════════════════════════════════════════════════════════════════════════════

static func spawn_heal(pos: Vector2, amount: int) -> void:
	"""Mostrar texto de curación verde"""
	_spawn_text(pos, "+%d" % amount, Color(0.3, 1.0, 0.3), 18, 1.2)

static func spawn_damage(pos: Vector2, amount: int, is_crit: bool = false) -> void:
	"""Mostrar texto de daño (enemigo recibe)"""
	var col = Color(1.0, 0.3, 0.3) if not is_crit else Color(1.0, 0.8, 0.2)
	var size = 16 if not is_crit else 22
	_spawn_text(pos, str(amount), col, size, 0.8)

static func spawn_player_damage(pos: Vector2, amount: int, element: String = "physical") -> void:
	"""Mostrar daño recibido por el player (formato -X con color según elemento)"""
	var col: Color
	var prefix: String = "-"
	
	match element:
		"fire":
			col = Color(1.0, 0.5, 0.1)  # Naranja fuego
		"ice":
			col = Color(0.4, 0.8, 1.0)  # Cyan hielo
		"poison":
			col = Color(0.6, 0.9, 0.2)  # Verde veneno
		"dark", "void", "shadow":
			col = Color(0.6, 0.2, 0.8)  # Morado oscuro
		"arcane":
			col = Color(0.9, 0.4, 0.9)  # Rosa arcano
		"lightning":
			col = Color(1.0, 1.0, 0.4)  # Amarillo eléctrico
		_:
			col = Color(1.0, 0.3, 0.3)  # Rojo por defecto
	
	_spawn_text(pos, "%s%d" % [prefix, amount], col, 20, 1.0)

static func spawn_dot_tick(pos: Vector2, amount: int, dot_type: String) -> void:
	"""Mostrar tick de DoT (burn/poison) - más pequeño y sutil"""
	var col: Color
	var icon: String = ""
	
	match dot_type:
		"burn":
			col = Color(1.0, 0.6, 0.2, 0.9)
			icon = "🔥"
		"poison":
			col = Color(0.5, 0.8, 0.3, 0.9)
			icon = "☠️"
		"bleed":
			col = Color(0.8, 0.2, 0.2, 0.9)
			icon = "🩸"
		_:
			col = Color(0.8, 0.3, 0.3, 0.9)
			icon = ""
	
	_spawn_text(pos, "%s-%d" % [icon, amount], col, 14, 0.8)

static func spawn_status_applied(pos: Vector2, status: String) -> void:
	"""Mostrar cuando se aplica un estado al player"""
	var col: Color
	var text: String
	
	match status:
		"slow":
			col = Color(0.4, 0.7, 1.0)
			text = "❄️ SLOW"
		"burn":
			col = Color(1.0, 0.5, 0.2)
			text = "🔥 BURN"
		"poison":
			col = Color(0.5, 0.9, 0.3)
			text = "☠️ POISON"
		"weakness":
			col = Color(0.6, 0.2, 0.6)
			text = "💀 WEAK"
		"curse":
			col = Color(0.5, 0.3, 0.6)
			text = "👻 CURSE"
		"stun":
			col = Color(1.0, 1.0, 0.4)
			text = "⚡ STUN"
		_:
			col = Color(0.8, 0.8, 0.8)
			text = status.to_upper()
	
	_spawn_text(pos, text, col, 14, 1.2)

static func spawn_text(pos: Vector2, txt: String, col: Color = Color.WHITE) -> void:
	"""Mostrar texto personalizado"""
	_spawn_text(pos, txt, col, 16, 1.0)

static func spawn_custom(pos: Vector2, txt: String, col: Color = Color.WHITE) -> void:
	"""Alias para spawn_text (para compatibilidad)"""
	spawn_text(pos, txt, col)

static func _spawn_text(pos: Vector2, txt: String, col: Color, size: int, dur: float) -> void:
	"""Crear un texto flotante en la posición indicada"""
	var tree = Engine.get_main_loop()
	if not tree:
		return
	
	var root = tree.current_scene
	if not root:
		return
	
	# Crear el nodo de texto flotante
	var floating = FloatingTextInstance.new()
	floating.setup(txt, col, size, dur)
	floating.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
	
	root.add_child(floating)


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: FloatingTextInstance
# Un texto flotante individual
# ═══════════════════════════════════════════════════════════════════════════════

class FloatingTextInstance extends Node2D:
	var _label: Label = null
	var _timer: float = 0.0
	var _duration: float = 1.0
	var _rise_speed: float = 60.0
	var _start_scale: float = 1.0
	
	func setup(txt: String, col: Color, size: int, dur: float) -> void:
		_duration = dur
		
		# Crear label
		_label = Label.new()
		_label.text = txt
		_label.add_theme_font_size_override("font_size", size)
		_label.add_theme_color_override("font_color", col)
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		_label.add_theme_constant_override("outline_size", 3)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Centrar el label
		_label.position = Vector2(-50, -15)
		_label.custom_minimum_size = Vector2(100, 30)
		
		add_child(_label)
		
		# Escala inicial con "pop"
		scale = Vector2(0.5, 0.5)
		_start_scale = 1.0 + (size - 16) * 0.02  # Más grande si el font es más grande
	
	func _ready() -> void:
		# Animación de aparición
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(_start_scale, _start_scale), 0.15)
	
	func _process(delta: float) -> void:
		_timer += delta
		
		# Subir
		position.y -= _rise_speed * delta
		
		# Desacelerar el movimiento
		_rise_speed = max(10.0, _rise_speed - 80.0 * delta)
		
		# Fade out en la segunda mitad
		var progress = _timer / _duration
		if progress > 0.5:
			var fade_progress = (progress - 0.5) / 0.5
			modulate.a = 1.0 - fade_progress
		
		# Destruir cuando termine
		if _timer >= _duration:
			queue_free()
