# AmbientAtmosphere.gd
# Sistema de partículas ambientales sutiles (motas de polvo, luz, ceniza).
# Sigue al jugador. Adapta cantidad y color según la fase de dificultad.

extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

## Cantidad base de partículas (fase 1)
const BASE_AMOUNT: int = 35
## Radio de emisión alrededor del jugador
const EMISSION_RADIUS: float = 350.0
## Velocidad de caída / deriva vertical
const DRIFT_SPEED_MIN: float = 4.0
const DRIFT_SPEED_MAX: float = 18.0
## Velocidad lateral sutil
const LATERAL_SPEED: float = 6.0
## Tamaño de partículas
const PARTICLE_SIZE_MIN: float = 1.0
const PARTICLE_SIZE_MAX: float = 2.8
## Vida de cada partícula (segundos)
const LIFETIME_MIN: float = 3.0
const LIFETIME_MAX: float = 7.0
## Opacidad máxima
const ALPHA_MAX: float = 0.35

# Paletas por fase de dificultad
const PHASE_PALETTES := {
	1: [Color(1.0, 0.98, 0.85, 0.3), Color(0.85, 0.9, 1.0, 0.25)],       # Dust/light motes — sereno
	2: [Color(1.0, 0.9, 0.7, 0.3), Color(0.95, 0.85, 0.6, 0.28)],         # Golden warmth — tensión
	3: [Color(1.0, 0.6, 0.3, 0.3), Color(0.9, 0.4, 0.15, 0.25)],          # Ember hints — peligro
	4: [Color(0.7, 0.2, 0.4, 0.35), Color(0.5, 0.1, 0.3, 0.3)],           # Dark crimson — caos
	5: [Color(0.6, 0.15, 0.8, 0.35), Color(0.3, 0.05, 0.5, 0.3)],         # Void purple — fase final
}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _player: Node2D = null
var _particles: Array = []
var _current_phase: int = 1
var _target_amount: int = BASE_AMOUNT
var _spawn_timer: float = 0.0
var _initialized: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func initialize(player: Node) -> void:
	if not player is Node2D:
		push_warning("[AmbientAtmosphere] Player no es Node2D, deshabilitando.")
		return
	_player = player as Node2D
	_initialized = true
	_update_phase(1)
	# Seed inicial
	for i in range(mini(15, _target_amount)):
		_spawn_particle(true)

func set_phase(phase: int) -> void:
	if phase != _current_phase:
		_update_phase(phase)

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if Headless.is_headless():
		set_process(false)
		return
	z_index = -5  # Detrás de entidades
	z_as_relative = false

func _process(delta: float) -> void:
	if not _initialized or not is_instance_valid(_player):
		return

	# Seguir al jugador (posición global)
	global_position = _player.global_position

	# Obtener fase del DifficultyManager periódicamente
	_spawn_timer += delta
	if _spawn_timer > 2.0:
		_spawn_timer = 0.0
		_poll_difficulty_phase()

	# Spawn si faltan partículas
	if _particles.size() < _target_amount and randf() < delta * 5.0:
		_spawn_particle(false)

	# Actualizar partículas existentes
	var to_remove: Array[int] = []
	for i in range(_particles.size() - 1, -1, -1):
		var p = _particles[i]
		p.timer += delta
		var life_ratio = p.timer / p.lifetime

		if life_ratio >= 1.0:
			to_remove.append(i)
			continue

		# Movimiento
		p.pos.y += p.drift_y * delta
		p.pos.x += sin(p.timer * p.sway_freq) * LATERAL_SPEED * delta

		# Alpha: fade-in / fade-out suave
		if life_ratio < 0.15:
			p.alpha = lerpf(0.0, p.max_alpha, life_ratio / 0.15)
		elif life_ratio > 0.7:
			p.alpha = lerpf(p.max_alpha, 0.0, (life_ratio - 0.7) / 0.3)
		else:
			p.alpha = p.max_alpha

	for idx in to_remove:
		_particles.remove_at(idx)

	queue_redraw()

func _draw() -> void:
	if not _initialized:
		return
	for p in _particles:
		var col = p.color
		col.a = p.alpha
		draw_circle(p.pos, p.size, col)

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

func _update_phase(phase: int) -> void:
	_current_phase = clampi(phase, 1, 5)
	# Más partículas en fases altas (más caóticas)
	_target_amount = BASE_AMOUNT + (_current_phase - 1) * 10

func _poll_difficulty_phase() -> void:
	var dm = get_node_or_null("/root/DifficultyManager")
	if dm and dm.has_method("get_current_phase"):
		var p = dm.get_current_phase()
		if p is int or p is float:
			set_phase(int(p))

func _spawn_particle(instant: bool) -> void:
	var p = {}
	# Posición aleatoria en radio
	var angle = randf() * TAU
	var dist = randf() * EMISSION_RADIUS
	p.pos = Vector2(cos(angle) * dist, sin(angle) * dist)
	p.drift_y = randf_range(DRIFT_SPEED_MIN, DRIFT_SPEED_MAX) * [-1.0, 1.0].pick_random()
	p.sway_freq = randf_range(0.4, 1.5)
	p.size = randf_range(PARTICLE_SIZE_MIN, PARTICLE_SIZE_MAX)
	p.lifetime = randf_range(LIFETIME_MIN, LIFETIME_MAX)
	p.timer = randf_range(0.0, p.lifetime * 0.5) if instant else 0.0

	# Color de la paleta de la fase actual
	var palette = PHASE_PALETTES.get(_current_phase, PHASE_PALETTES[1])
	p.color = palette.pick_random() as Color
	p.max_alpha = randf_range(ALPHA_MAX * 0.5, ALPHA_MAX)
	p.alpha = 0.0

	_particles.append(p)
