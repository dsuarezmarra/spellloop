# ProjectileVisualData.gd
# Resource que define la apariencia visual de un proyectil
# Estilo: Cartoon/Funko Pop con animaciones completas

class_name ProjectileVisualData
extends Resource

# ═══════════════════════════════════════════════════════════════════════════════
# IDENTIFICACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

@export var id: String = ""  # Ej: "ice_wand", "frozen_thunder"
@export var display_name: String = ""

# ═══════════════════════════════════════════════════════════════════════════════
# COLORES BASE (Estilo Cartoon)
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Colors")
@export var primary_color: Color = Color(0.4, 0.8, 1.0)    # Color principal
@export var secondary_color: Color = Color(0.2, 0.5, 0.9)  # Color secundario
@export var accent_color: Color = Color(1.0, 1.0, 1.0)     # Brillos/highlights
@export var outline_color: Color = Color(0.1, 0.2, 0.4)    # Contorno cartoon
@export var glow_color: Color = Color(0.6, 0.9, 1.0, 0.5)  # Resplandor

# ═══════════════════════════════════════════════════════════════════════════════
# TIPO DE PROYECTIL
# ═══════════════════════════════════════════════════════════════════════════════

enum ProjectileStyle {
	SINGLE,    # Proyectil único (ice shard, fireball)
	MULTI,     # Múltiples proyectiles
	CHAIN,     # Rayo que salta entre enemigos
	BEAM,      # Rayo continuo
	AOE,       # Área de efecto
	ORBIT      # Orbitales alrededor del jugador
}

@export_group("Type")
@export var style: ProjectileStyle = ProjectileStyle.SINGLE
@export var shape: String = "orb"  # Forma procedural: orb, shard, bolt, fireball, etc.

# ═══════════════════════════════════════════════════════════════════════════════
# SPRITES Y ANIMACIONES
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Sprites - Launch")
@export var launch_spritesheet: Texture2D  # Spritesheet de lanzamiento
@export var launch_frames: int = 4         # Número de frames
@export var launch_fps: float = 12.0       # Velocidad de animación
@export var launch_loop: bool = false      # ¿Loopear?

@export_group("Sprites - InFlight")
@export var flight_spritesheet: Texture2D  # Spritesheet en vuelo
@export var flight_frames: int = 6
@export var flight_fps: float = 12.0
@export var flight_loop: bool = true

@export_group("Sprites - Impact")
@export var impact_spritesheet: Texture2D  # Spritesheet de impacto
@export var impact_frames: int = 6
@export var impact_fps: float = 15.0
@export var impact_loop: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# SPRITES AOE (Solo para ProjectileStyle.AOE)
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("AOE Sprites")
@export var aoe_appear_spritesheet: Texture2D   # Aparición
@export var aoe_appear_frames: int = 4
@export var aoe_active_spritesheet: Texture2D   # Activo (loop)
@export var aoe_active_frames: int = 6
@export var aoe_fade_spritesheet: Texture2D     # Desvanecimiento
@export var aoe_fade_frames: int = 4
@export var aoe_fps: float = 12.0

# ═══════════════════════════════════════════════════════════════════════════════
# SPRITES BEAM (Solo para ProjectileStyle.BEAM)
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Beam Sprites")
@export var beam_start_spritesheet: Texture2D   # Origen del rayo
@export var beam_body_spritesheet: Texture2D    # Cuerpo (tileable)
@export var beam_tip_spritesheet: Texture2D     # Punta del rayo
@export var beam_frames: int = 4
@export var beam_fps: float = 15.0

# ═══════════════════════════════════════════════════════════════════════════════
# SPRITES CHAIN (Solo para ProjectileStyle.CHAIN)
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Chain Sprites")
@export var chain_start_spritesheet: Texture2D  # Efecto en origen
@export var chain_bolt_spritesheet: Texture2D   # Rayo entre enemigos
@export var chain_zap_spritesheet: Texture2D    # Efecto en objetivo
@export var chain_frames: int = 4
@export var chain_fps: float = 20.0

# ═══════════════════════════════════════════════════════════════════════════════
# SPRITES ORBIT (Solo para ProjectileStyle.ORBIT)
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Orbit Sprites")
@export var orbit_spawn_spritesheet: Texture2D  # Aparición del orbital
@export var orbit_idle_spritesheet: Texture2D   # Orbital rotando (loop)
@export var orbit_spawn_frames: int = 4
@export var orbit_idle_frames: int = 8
@export var orbit_fps: float = 12.0
@export var orbit_squash_stretch: bool = true   # Efecto cartoon al rotar

# ═══════════════════════════════════════════════════════════════════════════════
# EFECTOS ADICIONALES
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Effects")
@export var trail_enabled: bool = true          # ¿Tiene estela?
@export var trail_color: Color = Color(1, 1, 1, 0.5)
@export var trail_length: float = 0.3           # Duración de partículas
@export var glow_enabled: bool = true           # ¿Tiene resplandor?
@export var glow_intensity: float = 1.0
@export var screen_shake_on_impact: bool = false
@export var screen_shake_intensity: float = 2.0

# ═══════════════════════════════════════════════════════════════════════════════
# SONIDOS
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Audio")
@export var launch_sound: AudioStream
@export var flight_sound: AudioStream           # Loop mientras vuela
@export var impact_sound: AudioStream

# ═══════════════════════════════════════════════════════════════════════════════
# ESCALA Y TAMAÑO
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Size")
@export var base_scale: float = 1.0             # Escala base del sprite
@export var frame_size: Vector2i = Vector2i(64, 64)  # Tamaño de cada frame
@export var impact_scale_multiplier: float = 1.5  # El impacto es más grande

# ═══════════════════════════════════════════════════════════════════════════════
# MÉTODOS HELPER
# ═══════════════════════════════════════════════════════════════════════════════

func get_launch_duration() -> float:
	if launch_frames <= 0 or launch_fps <= 0:
		return 0.0
	return launch_frames / launch_fps

func get_impact_duration() -> float:
	if impact_frames <= 0 or impact_fps <= 0:
		return 0.0
	return impact_frames / impact_fps

func has_custom_sprites() -> bool:
	"""Verificar si tiene sprites personalizados o usa procedural"""
	return flight_spritesheet != null

func get_style_name() -> String:
	match style:
		ProjectileStyle.SINGLE: return "single"
		ProjectileStyle.MULTI: return "multi"
		ProjectileStyle.CHAIN: return "chain"
		ProjectileStyle.BEAM: return "beam"
		ProjectileStyle.AOE: return "aoe"
		ProjectileStyle.ORBIT: return "orbit"
		_: return "unknown"
