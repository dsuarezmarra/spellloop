# FloatingText.gd
# Sistema de texto flotante REDISEÑADO — estilo Vampire Survivors / Brotato
# Pooling integrado, fuente custom, animaciones juicy, escala por magnitud de daño.

extends Node2D
class_name FloatingText

# Singleton para acceso global
static var instance: FloatingText = null

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN VISUAL — DESIGN PASS
# ═══════════════════════════════════════════════════════════════════════════════

# Colores principales
const COLOR_DAMAGE_NORMAL := Color(1.0, 1.0, 1.0)         # Blanco puro
const COLOR_DAMAGE_CRIT := Color(1.0, 0.85, 0.1)          # Dorado brillante
const COLOR_HEAL := Color(0.2, 1.0, 0.4)                  # Verde vivo
const COLOR_PLAYER_DAMAGE := Color(1.0, 0.15, 0.15)       # Rojo intenso
const COLOR_GOLD := Color(1.0, 0.85, 0.3)                 # Dorado moneda
const COLOR_STATUS := Color(0.9, 0.9, 1.0)                # Blanco azulado

# Colores elementales
const ELEMENT_COLORS := {
	"physical": Color(1.0, 0.3, 0.3),
	"fire": Color(1.0, 0.45, 0.05),
	"ice": Color(0.3, 0.75, 1.0),
	"poison": Color(0.5, 0.9, 0.15),
	"dark": Color(0.6, 0.15, 0.85),
	"void": Color(0.5, 0.1, 0.8),
	"shadow": Color(0.55, 0.15, 0.75),
	"arcane": Color(0.85, 0.35, 0.95),
	"lightning": Color(1.0, 0.95, 0.3),
	"nature": Color(0.3, 0.85, 0.3),
	"earth": Color(0.7, 0.55, 0.25),
	"wind": Color(0.6, 0.9, 0.8),
	"light": Color(1.0, 0.95, 0.75),
}

# Tamaños base (escalados por magnitud) — CARTOON: más grandes y gordos
const SIZE_DAMAGE_NORMAL: int = 24
const SIZE_DAMAGE_CRIT: int = 38
const SIZE_HEAL: int = 26
const SIZE_PLAYER_DAMAGE: int = 28
const SIZE_DOT: int = 18
const SIZE_STATUS: int = 20
const SIZE_CUSTOM: int = 24

# Escala por magnitud — números más grandes = texto más grande
const MAGNITUDE_SCALE_MIN: float = 0.85
const MAGNITUDE_SCALE_MAX: float = 1.7
const MAGNITUDE_DAMAGE_LOW: float = 10.0
const MAGNITUDE_DAMAGE_HIGH: float = 500.0

# Outline — más grueso para estilo cartoon
const OUTLINE_SIZE_NORMAL: int = 6
const OUTLINE_SIZE_CRIT: int = 9

# ═══════════════════════════════════════════════════════════════════════════════
# POOLING SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
var _pool: Array = []
var _active_instances: Array = []
const MAX_ACTIVE_TEXTS: int = 150
const MAX_POOL_SIZE: int = 200

var _is_headless: bool = false
var _font: Font = null
var _font_bold: Font = null

func _ready() -> void:
	if instance == null:
		instance = self
	z_index = 100

	if Headless.is_headless():
		_is_headless = true
		return

	# Cargar fuentes custom — Fredoka Bold (mágica, rounded, cartoon) como fuente principal
	var fredoka_base = load("res://assets/ui/fonts/Fredoka-Variable.ttf") as Font
	if fredoka_base:
		# Crear variación en Bold (weight 700) para look cartoon/grueso
		var bold_variation = FontVariation.new()
		bold_variation.base_font = fredoka_base
		bold_variation.variation_opentype = {"wght": 700}
		_font = bold_variation
	else:
		# Fallback a Fredoka Medium si la variación bold falla
		var fredoka_fallback = load("res://assets/ui/fonts/Fredoka-Variable.ttf") as Font
		if fredoka_fallback:
			var medium_variation = FontVariation.new()
			medium_variation.base_font = fredoka_fallback
			medium_variation.variation_opentype = {"wght": 500}
			_font = medium_variation
	# Fuente para crits/títulos — Fredoka SemiBold más grande, o LilitaOne como fallback
	if fredoka_base:
		var semi_bold_var = FontVariation.new()
		semi_bold_var.base_font = fredoka_base
		semi_bold_var.variation_opentype = {"wght": 600}
		_font_bold = semi_bold_var
	else:
		_font_bold = load("res://assets/ui/fonts/LilitaOne-Regular.ttf") as Font

	# Pre-warm pool
	for i in range(25):
		_create_new_instance_for_pool()

func _create_new_instance_for_pool() -> void:
	var inst = FloatingTextInstance.new()
	inst.visible = false
	if _font:
		inst._font = _font
	if _font_bold:
		inst._font_bold = _font_bold
	_pool.append(inst)

func get_from_pool() -> FloatingTextInstance:
	if _is_headless:
		return null

	if _active_instances.size() >= MAX_ACTIVE_TEXTS:
		var oldest = _active_instances.pop_front()
		if is_instance_valid(oldest):
			oldest.force_return()

	var inst: FloatingTextInstance
	if _pool.is_empty():
		inst = FloatingTextInstance.new()
		if _font:
			inst._font = _font
		if _font_bold:
			inst._font_bold = _font_bold
	else:
		inst = _pool.pop_back()

	_active_instances.append(inst)
	return inst

func return_to_pool(inst: FloatingTextInstance) -> void:
	_active_instances.erase(inst)
	if _pool.size() < MAX_POOL_SIZE:
		_pool.append(inst)
		if inst.get_parent():
			inst.get_parent().remove_child(inst)
	else:
		inst.queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func _magnitude_scale(amount: int) -> float:
	"""Escala logarítmica: daño mayor = texto más grande."""
	if amount <= MAGNITUDE_DAMAGE_LOW:
		return MAGNITUDE_SCALE_MIN
	if amount >= MAGNITUDE_DAMAGE_HIGH:
		return MAGNITUDE_SCALE_MAX
	var t = log(float(amount) / MAGNITUDE_DAMAGE_LOW) / log(MAGNITUDE_DAMAGE_HIGH / MAGNITUDE_DAMAGE_LOW)
	return lerpf(MAGNITUDE_SCALE_MIN, MAGNITUDE_SCALE_MAX, clampf(t, 0.0, 1.0))

# ═══════════════════════════════════════════════════════════════════════════════
# API ESTÁTICA
# ═══════════════════════════════════════════════════════════════════════════════

static func spawn_heal(pos: Vector2, amount: int) -> void:
	var mag = _magnitude_scale(amount)
	_spawn_text(pos, "+%d" % amount, COLOR_HEAL, int(SIZE_HEAL * mag), 1.0, {
		"outline_color": Color(0.0, 0.3, 0.05, 0.9),
		"outline_size": OUTLINE_SIZE_NORMAL,
		"rise_type": "gentle",
	})

static func spawn_damage(pos: Vector2, amount: int, is_crit: bool = false) -> void:
	var mag = _magnitude_scale(amount)
	if is_crit:
		_spawn_text(pos, "%d!" % amount, COLOR_DAMAGE_CRIT, int(SIZE_DAMAGE_CRIT * mag), 0.9, {
			"outline_color": Color(0.5, 0.2, 0.0, 0.95),
			"outline_size": OUTLINE_SIZE_CRIT,
			"rise_type": "crit_bounce",
			"use_bold_font": true,
			"rotation_deg": randf_range(-12.0, 12.0),
		})
		_apply_crit_feedback(pos)
	else:
		_spawn_text(pos, str(amount), COLOR_DAMAGE_NORMAL, int(SIZE_DAMAGE_NORMAL * mag), 0.7, {
			"outline_color": Color(0.3, 0.0, 0.0, 0.85),
			"outline_size": OUTLINE_SIZE_NORMAL,
			"rise_type": "bounce",
		})

static func spawn_player_damage(pos: Vector2, amount: int, element: String = "physical") -> void:
	var col = ELEMENT_COLORS.get(element, COLOR_PLAYER_DAMAGE)
	var mag = _magnitude_scale(amount)
	_spawn_text(pos, "-%d" % amount, col, int(SIZE_PLAYER_DAMAGE * mag), 0.9, {
		"outline_color": Color(0.15, 0.0, 0.0, 0.9),
		"outline_size": OUTLINE_SIZE_NORMAL + 1,
		"rise_type": "drop",
	})

static func spawn_dot_tick(pos: Vector2, amount: int, dot_type: String) -> void:
	var col: Color
	var icon: String = ""
	match dot_type:
		"burn":
			col = Color(1.0, 0.55, 0.15, 0.95)
			icon = "🔥"
		"poison":
			col = Color(0.45, 0.85, 0.2, 0.95)
			icon = "☠"
		"bleed":
			col = Color(0.85, 0.15, 0.15, 0.95)
			icon = "🩸"
		_:
			col = Color(0.8, 0.3, 0.3, 0.9)
	_spawn_text(pos, "%s%d" % [icon, amount], col, SIZE_DOT, 0.6, {
		"outline_size": 3,
		"rise_type": "drift",
	})

static func spawn_status_applied(pos: Vector2, status: String) -> void:
	var display = status.to_upper()
	var col := COLOR_STATUS
	match status:
		"slow", "frozen", "freeze": col = Color(0.4, 0.8, 1.0)
		"burn", "ignite": col = Color(1.0, 0.5, 0.1)
		"poison": col = Color(0.5, 0.9, 0.2)
		"stun": col = Color(1.0, 1.0, 0.3)
		"weakness", "curse": col = Color(0.7, 0.2, 0.9)
	_spawn_text(pos, display, col, SIZE_STATUS, 1.0, {
		"outline_size": 4,
		"rise_type": "gentle",
	})

static func spawn_text(pos: Vector2, txt: String, col: Color = Color.WHITE) -> void:
	_spawn_text(pos, txt, col, SIZE_CUSTOM, 0.9, {
		"outline_size": OUTLINE_SIZE_NORMAL,
		"rise_type": "bounce",
	})

static func spawn_custom(pos: Vector2, txt: String, col: Color = Color.WHITE) -> void:
	spawn_text(pos, txt, col)

static func _apply_crit_feedback(_pos: Vector2) -> void:
	"""Screen shake + sound on critical hit."""
	if Headless.is_headless():
		return
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return

	var camera = tree.get_first_node_in_group("camera")
	if not camera:
		camera = tree.get_first_node_in_group("game_camera")
	if camera:
		if camera.has_method("minor_shake"):
			camera.minor_shake()
		elif camera.has_method("shake"):
			camera.shake(0.15, 0.08)

	var audio_manager = tree.root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_fixed("sfx_crit_hit")


static func _spawn_text(pos: Vector2, txt: String, col: Color, size: int, dur: float, opts: Dictionary = {}) -> void:
	var tree = Engine.get_main_loop() as SceneTree

	# DIAGNOSTICS HOOK
	if tree and tree.has_group("diagnostics"):
		tree.call_group("diagnostics", "track_feedback", "text", txt)

	# AUDIT HOOK
	if tree:
		var logger = tree.root.get_node_or_null("DamageDeliveryLogger")
		if logger:
			var is_crit = (col == COLOR_DAMAGE_CRIT)
			var amt = txt.to_int()
			logger.log_feedback(amt, is_crit, pos)

	# HEADLESS GUARD
	if Headless.is_headless():
		return
	if not tree or not tree.current_scene:
		return

	# LAZY INITIALIZATION
	if not instance:
		var root = tree.current_scene
		if root:
			var existing = root.find_child("FloatingTextManager", true, false)
			if existing:
				instance = existing
			else:
				instance = FloatingText.new()
				instance.name = "FloatingTextManager"
				# FIX-R8: add_child directo para que esté en el tree en este mismo frame
				root.add_child(instance)

	if not instance or not instance.is_inside_tree():
		# Fallback de emergencia
		var temp = FloatingTextInstance.new()
		if tree.current_scene:
			tree.current_scene.add_child(temp)
			temp.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-8, 8))
			temp.setup(txt, col, size, dur, opts)
			temp.visible = true
		return

	# Usar Singleton (Pool)
	var floating = instance.get_from_pool()
	if not floating:
		return

	if floating.get_parent() != tree.current_scene:
		if floating.get_parent():
			floating.get_parent().remove_child(floating)
		tree.current_scene.add_child(floating)

	# Spread mejorado
	var spread_x = randf_range(-18, 18)
	var spread_y = randf_range(-10, 6)
	floating.global_position = pos + Vector2(spread_x, spread_y)
	floating.setup(txt, col, size, dur, opts)
	floating.visible = true

# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: FloatingTextInstance (Pooled, Rediseñada)
# ═══════════════════════════════════════════════════════════════════════════════

class FloatingTextInstance extends Node2D:
	var _label: Label = null
	var _timer: float = 0.0
	var _duration: float = 1.0
	var _rise_speed: float = 70.0
	var _drift_x: float = 0.0
	var _active: bool = false
	var _rise_type: String = "bounce"
	var _font: Font = null
	var _font_bold: Font = null
	var _initial_rise: float = 70.0
	var _decel: float = 90.0
	var _gravity: float = 0.0

	func _init() -> void:
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.position = Vector2(-60, -18)
		_label.custom_minimum_size = Vector2(120, 36)
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_label.add_theme_constant_override("outline_size", 5)
		_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		_label.add_theme_constant_override("shadow_offset_x", 2)
		_label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(_label)
		z_index = 100
		z_as_relative = false

	func setup(txt: String, col: Color, size: int, dur: float, opts: Dictionary = {}) -> void:
		_duration = dur
		_timer = 0.0
		_active = true
		modulate.a = 1.0
		rotation = 0.0

		_rise_type = opts.get("rise_type", "bounce")
		match _rise_type:
			"bounce":
				_initial_rise = 70.0; _decel = 100.0
				_drift_x = randf_range(-8, 8); _gravity = 0.0
			"crit_bounce":
				_initial_rise = 100.0; _decel = 80.0
				_drift_x = randf_range(-12, 12); _gravity = 0.0
			"gentle":
				_initial_rise = 40.0; _decel = 30.0
				_drift_x = randf_range(-5, 5); _gravity = 0.0
			"drop":
				_initial_rise = -20.0; _decel = -60.0
				_drift_x = randf_range(-6, 6); _gravity = 120.0
			"drift":
				_initial_rise = 30.0; _decel = 40.0
				_drift_x = randf_range(-25, 25); _gravity = 0.0
			_:
				_initial_rise = 60.0; _decel = 80.0
				_drift_x = 0.0; _gravity = 0.0
		_rise_speed = _initial_rise

		_label.text = txt
		_label.add_theme_font_size_override("font_size", size)
		_label.add_theme_color_override("font_color", col)

		# Font selection
		var use_bold = opts.get("use_bold_font", false)
		if use_bold and _font_bold:
			_label.add_theme_font_override("font", _font_bold)
		elif _font:
			_label.add_theme_font_override("font", _font)

		# Outline
		var outline_col = opts.get("outline_color", Color(0, 0, 0, 0.9))
		var outline_sz = opts.get("outline_size", 5)
		_label.add_theme_color_override("font_outline_color", outline_col)
		_label.add_theme_constant_override("outline_size", outline_sz)

		# Rotation for crits
		rotation = deg_to_rad(opts.get("rotation_deg", 0.0))

		# Pop animation
		scale = Vector2(0.3, 0.3)
		var tween = create_tween()
		if _rise_type == "crit_bounce":
			tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.06)
			tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.04)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.04)
		elif _rise_type == "drop":
			tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.07).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
		else:
			tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)

	func _process(delta: float) -> void:
		if not _active:
			return

		_timer += delta
		var progress = _timer / _duration

		match _rise_type:
			"drop":
				_rise_speed += _gravity * delta
				position.y += _rise_speed * delta
				position.x += _drift_x * delta
			"drift":
				position.y -= _rise_speed * delta
				_rise_speed = maxf(5.0, _rise_speed - _decel * delta)
				position.x += _drift_x * delta
				_drift_x *= 0.97
			_:
				position.y -= _rise_speed * delta
				_rise_speed = maxf(8.0, _rise_speed - _decel * delta)
				position.x += _drift_x * delta * (1.0 - progress)

		# Fade out
		if progress > 0.55:
			var fade_progress = (progress - 0.55) / 0.45
			modulate.a = 1.0 - fade_progress * fade_progress

		# Shrink al final
		if progress > 0.7:
			var shrink = 1.0 - (progress - 0.7) * 0.5
			scale = Vector2(shrink, shrink)

		if _timer >= _duration:
			_finish()

	func force_return() -> void:
		_active = false
		if FloatingText.instance:
			FloatingText.instance.return_to_pool(self)

	func _finish() -> void:
		visible = false
		_active = false
		rotation = 0.0
		if FloatingText.instance:
			FloatingText.instance.return_to_pool(self)
		else:
			queue_free()
