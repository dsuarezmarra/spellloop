# FloatingText.gd
# Sistema de texto flotante OPTIMIZADO con POOLING para evitar Garbage Collection spikes.

extends Node2D
class_name FloatingText

# Configuración visual
var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 16
var duration: float = 1.0
var rise_speed: float = 50.0
var fade_start: float = 0.5

# Singleton para acceso global
static var instance: FloatingText = null

# ═══════════════════════════════════════════════════════════════════════════════
# POOLING SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
var _pool: Array = []
var _active_instances: Array = []
const MAX_ACTIVE_TEXTS: int = 150 # Límite duro para evitar degradación de FPS
const MAX_POOL_SIZE: int = 200

var _is_headless: bool = false

func _ready() -> void:
	if instance == null:
		instance = self
	z_index = 100
	
	# Check headless using central helper if possible, or robust check here
	if Headless.is_headless():
		_is_headless = true
		return

	# Pre-warm pool
	for i in range(20):
		_create_new_instance_for_pool()

func _create_new_instance_for_pool() -> void:
	var inst = FloatingTextInstance.new()
	inst.visible = false
	_pool.append(inst)

func get_from_pool() -> FloatingTextInstance:
	if _is_headless: return null

	# Si hay límite excedido, reciclar el más viejo activo
	if _active_instances.size() >= MAX_ACTIVE_TEXTS:
		var oldest = _active_instances.pop_front()
		if is_instance_valid(oldest):
			# Resetear y reusar inmediatamente (force finish)
			oldest.force_return()
			# Ahora está en el pool (o deberíamos usarlo directo?)
			# Simplificación: return_instance lo pone en _pool.
			# Así que continuamos abajo.
	
	var inst: FloatingTextInstance
	if _pool.is_empty():
		inst = FloatingTextInstance.new()
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
# ═══════════════════════════════════════════════════════════════════════════════
# API ESTÁTICA
# ═══════════════════════════════════════════════════════════════════════════════

static func spawn_heal(pos: Vector2, amount: int) -> void:
	_spawn_text(pos, "+%d" % amount, Color(0.3, 1.0, 0.3), 18, 1.2)

static func spawn_damage(pos: Vector2, amount: int, is_crit: bool = false) -> void:
	var col = Color(1.0, 0.3, 0.3) if not is_crit else Color(1.0, 0.8, 0.2)
	var size = 16 if not is_crit else 22
	_spawn_text(pos, str(amount), col, size, 0.8)
	
	# === CRIT FEEDBACK ===
	if is_crit:
		_apply_crit_feedback(pos)

static func spawn_player_damage(pos: Vector2, amount: int, element: String = "physical") -> void:
	var col: Color
	var prefix: String = "-"
	match element:
		"fire": col = Color(1.0, 0.5, 0.1)
		"ice": col = Color(0.4, 0.8, 1.0)
		"poison": col = Color(0.6, 0.9, 0.2)
		"dark", "void", "shadow": col = Color(0.6, 0.2, 0.8)
		"arcane": col = Color(0.9, 0.4, 0.9)
		"lightning": col = Color(1.0, 1.0, 0.4)
		_: col = Color(1.0, 0.3, 0.3)
	_spawn_text(pos, "%s%d" % [prefix, amount], col, 20, 1.0)

static func spawn_dot_tick(pos: Vector2, amount: int, dot_type: String) -> void:
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
	_spawn_text(pos, "%s-%d" % [icon, amount], col, 14, 0.8)

static func spawn_status_applied(pos: Vector2, status: String) -> void:
	# Simplificado para brevedad, lógica igual
	_spawn_text(pos, status.to_upper(), Color.WHITE, 14, 1.2)

static func spawn_text(pos: Vector2, txt: String, col: Color = Color.WHITE) -> void:
	_spawn_text(pos, txt, col, 16, 1.0)

static func spawn_custom(pos: Vector2, txt: String, col: Color = Color.WHITE) -> void:
	spawn_text(pos, txt, col)

static func _apply_crit_feedback(_pos: Vector2) -> void:
	"""Apply screen shake and sound on critical hit"""
	if Headless.is_headless():
		return
	
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	# Screen shake (micro-shake for crits)
	var camera = tree.get_first_node_in_group("camera")
	if not camera:
		camera = tree.get_first_node_in_group("game_camera")
	
	if camera:
		if camera.has_method("minor_shake"):
			camera.minor_shake()
		elif camera.has_method("shake"):
			camera.shake(0.15, 0.08)  # Very subtle shake for crits
	
	# Crit sound effect
	var audio_manager = tree.root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_fixed("sfx_crit_hit")



static func _spawn_text(pos: Vector2, txt: String, col: Color, size: int, dur: float) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	
	# DIAGNOSTICS HOOK (Moved up for Headless Audit support)
	if tree and tree.has_group("diagnostics"):
		tree.call_group("diagnostics", "track_feedback", "text", txt)

	# HEADLESS GUARD: Critical - prevents ALL visual operations in headless mode
	if Headless.is_headless():
		return
	
	if not tree:
		return
	
	if not tree.current_scene:
		return
	
	# LAZY INITIALIZATION: Si no es Autoload, crearlo manualmente
	if not instance:
		var root = tree.current_scene
		if root:
			# Buscar si ya existe uno en la escena (revive tras reload)
			var existing = root.find_child("FloatingTextManager", true, false)
			if existing:
				instance = existing
			else:
				instance = FloatingText.new()
				instance.name = "FloatingTextManager"
				root.call_deferred("add_child", instance)
				# Esperar un frame o forzar setup? 
				# call_deferred significa que no estará listo AHORA.
				# Hack: si no está en el tree, no podemos usarlo este frame para pooling.
				# Fallback: instanciar directo sin pool por este frame.
	
	if not instance or not instance.is_inside_tree():
		# Fallback de emergencia si no está listo el singleton
		var temp = FloatingTextInstance.new()
		if tree.current_scene:
			tree.current_scene.add_child(temp)
			temp.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
			temp.setup(txt, col, size, dur)
			temp.visible = true
		return

	# Usar Singleton (Pool)
	var floating = instance.get_from_pool()
	if not floating:
		return
	
	# Añadir a la escena SI NO ESTÁ YA
	if floating.get_parent() != tree.current_scene:
		if floating.get_parent(): floating.get_parent().remove_child(floating)
		tree.current_scene.add_child(floating)
	
	floating.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
	floating.setup(txt, col, size, dur)
	floating.visible = true

# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: FloatingTextInstance (Pooled)
# ═══════════════════════════════════════════════════════════════════════════════

class FloatingTextInstance extends Node2D:
	var _label: Label = null
	var _timer: float = 0.0
	var _duration: float = 1.0
	var _rise_speed: float = 60.0
	var _active: bool = false
	
	func _init() -> void:
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.position = Vector2(-50, -15)
		_label.custom_minimum_size = Vector2(100, 30)
		# Sombra común
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		_label.add_theme_constant_override("outline_size", 3)
		add_child(_label)
		
		# Asegurar que se ve por encima de todo
		z_index = 100
		z_as_relative = false

	func setup(txt: String, col: Color, size: int, dur: float) -> void:
		_duration = dur
		_timer = 0.0
		_rise_speed = 60.0
		_active = true
		modulate.a = 1.0
		scale = Vector2(1.0, 1.0)
		
		_label.text = txt
		_label.add_theme_font_size_override("font_size", size)
		_label.add_theme_color_override("font_color", col)
		
		# Animación "pop" manual sin Tweens (más barato)
		scale = Vector2(0.5, 0.5)
		
		# Opcional: Usar Tween solo para el pop inicial si es crítico, 
		# pero para optimización extrema, hacerlo en _process es mejor.
		# Por ahora mantenemos Tween simple solo de escala.
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)
	
	func _process(delta: float) -> void:
		if not _active: return
		
		_timer += delta
		position.y -= _rise_speed * delta
		_rise_speed = max(10.0, _rise_speed - 80.0 * delta)
		
		var progress = _timer / _duration
		if progress > 0.5:
			modulate.a = 1.0 - (progress - 0.5) * 2.0
		
		if _timer >= _duration:
			_finish()

	func force_return() -> void:
		_active = false
		if FloatingText.instance:
			FloatingText.instance.return_to_pool(self)

	func _finish() -> void:
		visible = false
		_active = false
		# Devolver al pool singleton
		if FloatingText.instance:
			FloatingText.instance.return_to_pool(self)
		else:
			queue_free()
