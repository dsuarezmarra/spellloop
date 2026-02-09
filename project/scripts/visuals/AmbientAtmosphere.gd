# AmbientAtmosphere.gd
# Sistema de partículas ambientales para gameplay — réplica del sistema de MainMenu/CharacterSelect.
# Usa GPUParticles2D con sparkle sheet, emisión BOX anclada al viewport (NO sigue al player).
# Adapta colores según fase de dificultad.

extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

const SPARKLE_TEXTURE_PATH := "res://assets/ui/particles/particle_magic_sparkle.png"
const SPARKLE_FRAME_WIDTH: int = 304
const SPARKLE_FRAME_HEIGHT: int = 222
const SPARKLE_FRAMES: int = 4

## Número de sistemas GPUParticles2D a crear
const NUM_SYSTEMS: int = 4
## Partículas por sistema
const PARTICLES_PER_SYSTEM: int = 30
## Vida de cada partícula
const PARTICLE_LIFETIME: float = 6.0

# Paletas por fase — array de hues (HSV)
const PHASE_HUES := {
	1: [0.12, 0.14],            # Dorado suave — calma (forest/plains)
	2: [0.12, 0.08, 0.55],     # Dorado + naranja + cyan — tensión
	3: [0.08, 0.02, 0.12],     # Naranja + rojo + dorado — peligro
	4: [0.75, 0.85, 0.02],     # Púrpura + magenta + rojo — caos
	5: [0.75, 0.80, 0.55, 0.12], # Void: púrpura + cyan + dorado
}

const PHASE_SATURATION := {1: 0.25, 2: 0.35, 3: 0.45, 4: 0.50, 5: 0.55}
const PHASE_ALPHA := {1: 0.35, 2: 0.40, 3: 0.45, 4: 0.50, 5: 0.55}
const PHASE_SCALE_MIN := {1: 0.02, 2: 0.02, 3: 0.03, 4: 0.03, 5: 0.03}
const PHASE_SCALE_MAX := {1: 0.06, 2: 0.07, 3: 0.08, 4: 0.09, 5: 0.10}
const PHASE_VELOCITY := {1: [4.0, 15.0], 2: [6.0, 20.0], 3: [8.0, 25.0], 4: [10.0, 30.0], 5: [12.0, 35.0]}

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _player: Node2D = null
var _camera: Camera2D = null
var _particle_systems: Array[GPUParticles2D] = []
var _atlas_textures: Array[AtlasTexture] = []
var _current_phase: int = 1
var _initialized: bool = false
var _phase_poll_timer: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func initialize(player: Node) -> void:
	if player is Node2D:
		_player = player as Node2D
	# Buscar cámara
	_camera = get_viewport().get_camera_2d()
	if not _camera and _player:
		# Fallback: buscar en el árbol
		var tree = get_tree()
		if tree:
			_camera = tree.get_first_node_in_group("camera") as Camera2D
			if not _camera:
				_camera = tree.get_first_node_in_group("game_camera") as Camera2D
	_setup_particles()
	_initialized = true

func set_phase(phase: int) -> void:
	if phase != _current_phase:
		_current_phase = clampi(phase, 1, 5)
		_update_particle_colors()

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if Headless.is_headless():
		set_process(false)
		return
	z_index = -5
	z_as_relative = false

func _process(delta: float) -> void:
	if not _initialized:
		return

	# Anclar posición al centro de la cámara (las partículas flotan en world space
	# pero la emisión siempre cubre el viewport visible)
	if is_instance_valid(_camera):
		global_position = _camera.get_screen_center_position()
	elif is_instance_valid(_player):
		global_position = _player.global_position

	# Poll fase de dificultad cada 3 segundos
	_phase_poll_timer += delta
	if _phase_poll_timer >= 3.0:
		_phase_poll_timer = 0.0
		_poll_difficulty_phase()

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL — Setup partículas replicando MainMenu
# ═══════════════════════════════════════════════════════════════════════════════

func _setup_particles() -> void:
	# Cargar sparkle sheet
	var sparkle_tex = load(SPARKLE_TEXTURE_PATH)
	if not sparkle_tex:
		push_warning("[AmbientAtmosphere] No se encontró %s" % SPARKLE_TEXTURE_PATH)
		return

	# Crear atlas textures (4 frames del sprite sheet)
	_atlas_textures.clear()
	for i in range(SPARKLE_FRAMES):
		var atlas = AtlasTexture.new()
		atlas.atlas = sparkle_tex
		atlas.region = Rect2(i * SPARKLE_FRAME_WIDTH, 0, SPARKLE_FRAME_WIDTH, SPARKLE_FRAME_HEIGHT)
		_atlas_textures.append(atlas)

	# Obtener tamaño del viewport para la caja de emisión
	var vp_size = get_viewport().get_visible_rect().size
	var half_w = vp_size.x * 0.55  # Un poco más grande que el viewport para cubrir bordes
	var half_h = vp_size.y * 0.55

	# Crear sistemas de partículas
	_particle_systems.clear()
	for i in range(NUM_SYSTEMS):
		var particles = GPUParticles2D.new()
		particles.name = "AmbientSparkle_%d" % i
		particles.amount = PARTICLES_PER_SYSTEM
		particles.lifetime = PARTICLE_LIFETIME
		particles.randomness = 1.0
		particles.texture = _atlas_textures[i % SPARKLE_FRAMES]

		var mat = ParticleProcessMaterial.new()

		# Emisión en caja que cubre el viewport
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(half_w, half_h, 0)

		# Movimiento: flotan suavemente hacia arriba con spread omnidireccional
		mat.direction = Vector3(0, -0.5, 0)
		mat.spread = 180.0
		var vel = PHASE_VELOCITY.get(_current_phase, [5.0, 18.0])
		mat.initial_velocity_min = vel[0]
		mat.initial_velocity_max = vel[1]
		mat.gravity = Vector3(0, -3, 0)  # Gravedad negativa → flotan arriba

		# Escala
		mat.scale_min = PHASE_SCALE_MIN.get(_current_phase, 0.03)
		mat.scale_max = PHASE_SCALE_MAX.get(_current_phase, 0.07)

		# Color según fase
		var hues = PHASE_HUES.get(_current_phase, [0.12])
		var hue = hues[i % hues.size()] + randf() * 0.03
		var sat = PHASE_SATURATION.get(_current_phase, 0.3)
		var alp = PHASE_ALPHA.get(_current_phase, 0.4)
		mat.color = Color.from_hsv(hue, sat, 1.0, alp)

		# Rotación lenta
		mat.angular_velocity_min = -20.0
		mat.angular_velocity_max = 20.0

		# Curva de fade in/out suave
		var curve = Curve.new()
		curve.add_point(Vector2(0.0, 0.0))
		curve.add_point(Vector2(0.15, 1.0))
		curve.add_point(Vector2(0.85, 1.0))
		curve.add_point(Vector2(1.0, 0.0))
		var alpha_curve_tex = CurveTexture.new()
		alpha_curve_tex.curve = curve
		mat.alpha_curve = alpha_curve_tex

		particles.process_material = mat
		particles.position = Vector2.ZERO  # Relativo al nodo padre (que sigue a cámara)
		particles.z_index = -5
		particles.preprocess = i * 1.5  # Stagger para que no arranquen vacíos

		add_child(particles)
		_particle_systems.append(particles)

func _update_particle_colors() -> void:
	"""Actualiza colores y parámetros de partículas cuando cambia la fase."""
	var hues = PHASE_HUES.get(_current_phase, [0.12])
	var sat = PHASE_SATURATION.get(_current_phase, 0.3)
	var alp = PHASE_ALPHA.get(_current_phase, 0.4)
	var vel = PHASE_VELOCITY.get(_current_phase, [5.0, 18.0])
	var sc_min = PHASE_SCALE_MIN.get(_current_phase, 0.03)
	var sc_max = PHASE_SCALE_MAX.get(_current_phase, 0.07)

	for i in range(_particle_systems.size()):
		var p = _particle_systems[i]
		var mat = p.process_material as ParticleProcessMaterial
		if not mat:
			continue
		var hue = hues[i % hues.size()] + randf() * 0.03
		mat.color = Color.from_hsv(hue, sat, 1.0, alp)
		mat.initial_velocity_min = vel[0]
		mat.initial_velocity_max = vel[1]
		mat.scale_min = sc_min
		mat.scale_max = sc_max

func _poll_difficulty_phase() -> void:
	var dm = get_node_or_null("/root/DifficultyManager")
	if dm and dm.has_method("get_current_phase"):
		var p = dm.get_current_phase()
		if p is int or p is float:
			set_phase(int(p))
