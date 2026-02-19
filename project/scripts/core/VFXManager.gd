# VFXManager.gd
# Sistema centralizado de efectos visuales
# Gestiona carga, instanciación y reproducción de todos los VFX del juego
#
# Uso: VFXManager.spawn_aoe("fire_stomp", position, radius)
#      VFXManager.spawn_projectile("fire", position, direction)

extends Node

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE SPRITESHEETS
# ══════════════════════════════════════════════════════════════════════════════

# Rutas base
const VFX_BASE_PATH = "res://assets/vfx/abilities/"

# Configuración de AOE spritesheets
# Formato: { id: { path, hframes, vframes, frame_size, duration } }
var AOE_CONFIG = {
	"fire_stomp": {
		"path": VFX_BASE_PATH + "aoe/fire/aoe_fire_stomp_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	},
	"fire_zone": {
		"path": VFX_BASE_PATH + "aoe/fire/aoe_fire_zone_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256), "duration": 0.6
	},
	"meteor_impact": {
		"path": VFX_BASE_PATH + "aoe/fire/aoe_meteor_impact_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256), "duration": 0.7
	},
	"arcane_nova": {
		"path": VFX_BASE_PATH + "aoe/arcane/aoe_arcane_nova_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.4
	},
	"freeze_zone": {
		"path": VFX_BASE_PATH + "aoe/ice/aoe_freeze_zone_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256), "duration": 0.6
	},
	"void_explosion": {
		"path": VFX_BASE_PATH + "aoe/void/aoe_void_explosion_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	},
	"ground_slam": {
		"path": VFX_BASE_PATH + "aoe/earth/aoe_ground_slam_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	},
	"rune_blast": {
		"path": VFX_BASE_PATH + "aoe/rune/aoe_rune_blast_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.4
	},
	"damage_zone_fire": {
		"path": VFX_BASE_PATH + "aoe/fire/aoe_damage_zone_fire_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256), "duration": 0.8
	},
	"damage_zone_void": {
		"path": VFX_BASE_PATH + "aoe/void/aoe_damage_zone_void_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256), "duration": 0.8
	},
	"elite_slam": {
		"path": VFX_BASE_PATH + "aoe/earth/aoe_elite_slam_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	},
	"elite_dash_trail": {
		"path": VFX_BASE_PATH + "aoe/elite/vfx_elite_dash_trail_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 64), "duration": 0.3
	},
	"boss_melee_impact": {
		"path": VFX_BASE_PATH + "aoe/boss/vfx_boss_melee_impact_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.3
	},
	"orb_impact": {
		"path": VFX_BASE_PATH + "aoe/void/vfx_orb_impact_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.3
	},
	"melee_slash": {
		"path": VFX_BASE_PATH + "aoe/elite/vfx_melee_slash_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.25
	}
}

# Configuración de Projectile spritesheets
var PROJECTILE_CONFIG = {
	"fire": {
		"path": VFX_BASE_PATH + "projectiles/fire/projectile_fire_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"ice": {
		"path": VFX_BASE_PATH + "projectiles/ice/projectile_ice_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"arcane": {
		"path": VFX_BASE_PATH + "projectiles/arcane/projectile_arcane_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"void": {
		"path": VFX_BASE_PATH + "projectiles/void/projectile_void_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"void_homing": {
		"path": VFX_BASE_PATH + "projectiles/void/projectile_void_homing_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"poison": {
		"path": VFX_BASE_PATH + "projectiles/poison/projectile_poison_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"lightning": {
		"path": VFX_BASE_PATH + "projectiles/lightning/projectile_lightning_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(64, 64), "duration": 0.4
	},
	"homing_orb": {
		"path": VFX_BASE_PATH + "projectiles/void/projectile_homing_orb_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	}
}

# Configuración de Aura spritesheets
var AURA_CONFIG = {
	"buff_corruption": {
		"path": VFX_BASE_PATH + "auras/aura_buff_corruption_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	},
	"damage_void": {
		"path": VFX_BASE_PATH + "auras/aura_damage_void_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	},
	"elite_floor": {
		"path": VFX_BASE_PATH + "auras/aura_elite_floor_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 1.0
	},
	"elite_rare": {
		"path": VFX_BASE_PATH + "auras/aura_elite_rare_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	},
	"enrage": {
		"path": VFX_BASE_PATH + "auras/aura_enrage_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.6
	},
	"elite_rage": {
		"path": VFX_BASE_PATH + "auras/aura_elite_rage_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.7
	},
	"elite_shield": {
		"path": VFX_BASE_PATH + "auras/aura_elite_shield_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	}
}

# ══════════════════════════════════════════════════════════════════════════════
# PLAYER VFX CONFIG
# ══════════════════════════════════════════════════════════════════════════════

var PLAYER_VFX_CONFIG = {
	"thorns": {
		"path": VFX_BASE_PATH + "player/thorns/vfx_player_thorns_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.3
	},
	"stun": {
		"path": VFX_BASE_PATH + "player/debuffs/vfx_player_stun_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	},
	"slow": {
		"path": VFX_BASE_PATH + "player/debuffs/vfx_player_slow_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	},
	"frost_nova": {
		"path": VFX_BASE_PATH + "player/buffs/vfx_player_frost_nova_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	},
	"heal": {
		"path": VFX_BASE_PATH + "player/heal/vfx_player_heal_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.5
	},
	"revive": {
		"path": VFX_BASE_PATH + "player/revive/vfx_player_revive_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.8
	},
	"soul_link": {
		"path": VFX_BASE_PATH + "player/soul_link/vfx_player_soul_link_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.4
	}
}

# Configuración de Beam spritesheets
var BEAM_CONFIG = {
	"flame_breath": {
		"path": VFX_BASE_PATH + "beams/beam_flame_breath_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(192, 64), "duration": 0.5
	},
	"void_beam": {
		"path": VFX_BASE_PATH + "beams/beam_void_beam_spritesheet.png",
		"hframes": 6, "vframes": 2, "frame_size": Vector2(192, 64), "duration": 0.5
	}
}

# Configuración de Telegraph spritesheets
var TELEGRAPH_CONFIG = {
	"circle_warning": {
		"path": VFX_BASE_PATH + "telegraphs/telegraph_circle_warning_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 1.0
	},
	"meteor_warning": {
		"path": VFX_BASE_PATH + "telegraphs/telegraph_meteor_warning_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 1.5
	},
	"charge_line": {
		"path": VFX_BASE_PATH + "telegraphs/telegraph_charge_line_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 0.8
	},
	"rune_prison": {
		"path": VFX_BASE_PATH + "telegraphs/telegraph_rune_prison_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128), "duration": 1.2
	}
}

# Configuración de Boss VFX spritesheets
var BOSS_CONFIG = {
	"summon_circle": {
		"path": VFX_BASE_PATH + "boss_specific/conjurador/boss_summon_circle_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.8
	},
	"reality_tear": {
		"path": VFX_BASE_PATH + "boss_specific/corazon_vacio/boss_reality_tear_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.6
	},
	"void_pull": {
		"path": VFX_BASE_PATH + "boss_specific/corazon_vacio/boss_void_pull_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.7
	},
	"rune_shield": {
		"path": VFX_BASE_PATH + "boss_specific/guardian_runas/boss_rune_shield_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.5
	},
	"teleport": {
		"path": VFX_BASE_PATH + "boss_specific/conjurador/vfx_boss_teleport_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.5
	},
	"counter_stance": {
		"path": VFX_BASE_PATH + "boss_specific/guardian_runas/vfx_boss_counter_stance_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.8
	},
	"orbital": {
		"path": VFX_BASE_PATH + "boss_specific/minotauro/boss_orbital_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 0.6
	},
	"phase_change": {
		"path": VFX_BASE_PATH + "boss_specific/minotauro/boss_phase_change_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(192, 192), "duration": 1.0
	}
}

# Mapeo de elementos a projectile types
var ELEMENT_TO_PROJECTILE = {
	"fire": "fire",
	"ice": "ice",
	"arcane": "arcane",
	"void": "void",
	"dark": "void",
	"shadow": "void",
	"poison": "poison",
	"nature": "poison",
	"lightning": "lightning",
	"physical": "arcane"    # Fallback
}

# Mapeo de habilidades a AOE types
var ABILITY_TO_AOE = {
	"fire_stomp": "fire_stomp",
	"fire_zone": "fire_zone",
	"meteor_call": "meteor_impact",
	"meteor_impact": "meteor_impact",
	"arcane_nova": "arcane_nova",
	"freeze_zone": "freeze_zone",
	"void_explosion": "void_explosion",
	"ground_slam": "ground_slam",
	"rune_blast": "rune_blast",
	# Mapeos adicionales para evitar fallbacks
	"elite_slam": "elite_slam",
	"damage_zone_fire": "damage_zone_fire",
	"damage_zone_void": "damage_zone_void",
	"elite_nova": "arcane_nova",  # Usar arcane_nova como base
	"poison_nova": "arcane_nova",  # TODO: crear poison_nova
	"lightning_strike": "arcane_nova"  # TODO: crear lightning_strike
}

# Cache de texturas cargadas
var _texture_cache: Dictionary = {}

func _get_beam_color(beam_type: String) -> Color:
	"""Obtener color apropiado para beam fallback según su tipo"""
	match beam_type:
		"flame_breath", "fire": return Color(1.0, 0.35, 0.1)
		"void_beam", "void", "dark": return Color(0.5, 0.25, 0.7)  # Púrpura suave
		"ice", "frost": return Color(0.2, 0.75, 1.0)
		"lightning": return Color(1.0, 1.0, 0.25)
		"arcane": return Color(0.7, 0.35, 0.9)  # Magenta suave
		"poison", "nature": return Color(0.25, 0.9, 0.2)
		_: return Color(0.85, 0.85, 0.9)

# ══════════════════════════════════════════════════════════════════════════════
# VFX DEBUG MODE
# ══════════════════════════════════════════════════════════════════════════════
## Activar con: VFXManager.DEBUG_VFX = true  (desde consola o código)
var DEBUG_VFX: bool = false
var _vfx_log: Array = []  # Historial de spawns recientes
const MAX_VFX_LOG: int = 50

func _log_vfx_spawn(category: String, vfx_type: String, asset_path: String, is_fallback: bool = false) -> void:
	if not DEBUG_VFX:
		return
	var entry = {
		"time": Time.get_ticks_msec(),
		"category": category,
		"type": vfx_type,
		"asset": asset_path.get_file() if asset_path else "PROCEDURAL",
		"fallback": is_fallback
	}
	_vfx_log.append(entry)
	if _vfx_log.size() > MAX_VFX_LOG:
		_vfx_log.pop_front()
	var tag = " (FALLBACK)" if is_fallback else ""
	print("[VFX] %s:%s → %s%s" % [category, vfx_type, entry["asset"], tag])

func get_vfx_log() -> Array:
	"""Obtener historial de spawns VFX recientes"""
	return _vfx_log.duplicate()

func clear_vfx_log() -> void:
	_vfx_log.clear()

# ══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Precargar texturas más comunes
	_preload_common_textures()

func _preload_common_textures() -> void:
	# Precargar AOE más usados
	for key in ["fire_stomp", "arcane_nova", "void_explosion"]:
		if AOE_CONFIG.has(key):
			_get_texture(AOE_CONFIG[key]["path"])
	
	# Precargar proyectiles
	for key in PROJECTILE_CONFIG:
		_get_texture(PROJECTILE_CONFIG[key]["path"])

func _get_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	
	if ResourceLoader.exists(path):
		var tex = load(path)
		_texture_cache[path] = tex
		return tex
	else:
		push_warning("[VFXManager] Textura no encontrada: %s" % path)
		return null

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - AOE
# ══════════════════════════════════════════════════════════════════════════════

func spawn_aoe(aoe_type: String, position: Vector2, radius: float = 100.0, duration_override: float = -1.0) -> Node2D:
	"""Spawn un efecto AOE animado en la posición dada"""
	var config = AOE_CONFIG.get(aoe_type)
	if not config:
		# Intentar mapear desde nombre de habilidad
		var mapped = ABILITY_TO_AOE.get(aoe_type, "")
		config = AOE_CONFIG.get(mapped)
	
	if not config:
		push_warning("[VFXManager] AOE type desconocido: %s" % aoe_type)
		_log_vfx_spawn("AOE", aoe_type, "", true)
		return _spawn_fallback_aoe(position, radius)
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("AOE", aoe_type, config["path"], true)
		return _spawn_fallback_aoe(position, radius)
	
	_log_vfx_spawn("AOE", aoe_type, config["path"])
	
	# FIX: Calculate proper scale factor from radius
	# radius is in pixels, we need to convert to scale factor
	# The sprite should have diameter = radius * 2
	var frame_size = config["frame_size"]
	var diameter = radius * 2.0
	var actual_scale_factor = diameter / frame_size.x
	# Clamp to reasonable values to prevent screen-covering effects
	actual_scale_factor = clampf(actual_scale_factor, 0.1, 3.0)
	
	return _create_animated_vfx(tex, config, position, actual_scale_factor, duration_override)

func spawn_aoe_by_ability(ability_name: String, position: Vector2, radius: float = 100.0) -> Node2D:
	"""Spawn AOE basado en nombre de habilidad (mapeo automático)"""
	var aoe_type = ABILITY_TO_AOE.get(ability_name, ability_name)
	return spawn_aoe(aoe_type, position, radius)

func _spawn_fallback_aoe(position: Vector2, radius: float) -> Node2D:
	"""Fallback: usar AOE genérico (fire_stomp) en lugar de dibujo procedural"""
	# Evitar recursividad si fire_stomp también falla
	var config = AOE_CONFIG.get("fire_stomp")
	if config:
		# Si tenemos el asset genérico, lo usamos
		var tex = _get_texture(config["path"])
		if tex:
			var frame_size = config["frame_size"]
			var diameter = radius * 2.0
			var scale_factor = clampf(diameter / frame_size.x, 0.1, 3.0)
			return _create_animated_vfx(tex, config, position, scale_factor, -1.0)

	# Si incluso el genérico falla, no dibujamos nada (mejor que círculo debug feo en release)
	return null

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - PROJECTILES
# ══════════════════════════════════════════════════════════════════════════════

func get_projectile_texture(element: String) -> Texture2D:
	"""Obtener textura de proyectil por elemento"""
	var proj_type = ELEMENT_TO_PROJECTILE.get(element, "arcane")
	var config = PROJECTILE_CONFIG.get(proj_type)
	if config:
		return _get_texture(config["path"])
	return null

func get_projectile_config(element: String) -> Dictionary:
	"""Obtener configuración completa de proyectil por elemento"""
	var proj_type = ELEMENT_TO_PROJECTILE.get(element, "arcane")
	return PROJECTILE_CONFIG.get(proj_type, {})

func spawn_projectile_impact(element: String, position: Vector2) -> Node2D:
	"""Spawn efecto de impacto de proyectil"""
	var config = get_projectile_config(element)
	if config.is_empty():
		_log_vfx_spawn("PROJECTILE", element, "", true)
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("PROJECTILE", element, config["path"], true)
		return null
	
	_log_vfx_spawn("PROJECTILE", element, config["path"])
	return _create_animated_vfx(tex, config, position, 1.0, 0.3)

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - AURAS
# ══════════════════════════════════════════════════════════════════════════════

func spawn_aura(aura_type: String, parent: Node2D, loop: bool = true) -> AnimatedSprite2D:
	"""Spawn un aura que sigue a un nodo padre"""
	var config = AURA_CONFIG.get(aura_type)
	if not config:
		push_warning("[VFXManager] Aura type desconocido: %s" % aura_type)
		_log_vfx_spawn("AURA", aura_type, "", true)
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("AURA", aura_type, config["path"], true)
		return null
	
	_log_vfx_spawn("AURA", aura_type, config["path"])
	
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _create_sprite_frames_from_sheet(tex, config, "aura_" + aura_type, loop)
	sprite.z_index = -1  # Debajo del personaje
	sprite.play("default")
	
	parent.add_child(sprite)
	return sprite

func spawn_elite_aura(parent: Node2D) -> AnimatedSprite2D:
	"""Spawn aura de élite debajo de un enemigo"""
	return spawn_aura("elite_floor", parent, true)

func spawn_enrage_aura(parent: Node2D) -> AnimatedSprite2D:
	"""Spawn aura de enrage"""
	return spawn_aura("enrage", parent, true)

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - BEAMS
# ══════════════════════════════════════════════════════════════════════════════

func spawn_beam(beam_type: String, origin: Vector2, direction: Vector2, length: float, duration: float = 1.0) -> Node2D:
	"""Spawn un beam desde origin en direction"""
	var config = BEAM_CONFIG.get(beam_type)
	if not config:
		push_warning("[VFXManager] Beam type desconocido: %s" % beam_type)
		_log_vfx_spawn("BEAM", beam_type, "", true)
		# Determinar color por tipo de beam
		var beam_color = _get_beam_color(beam_type)
		return _spawn_fallback_beam(origin, direction, length, duration, beam_color)
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("BEAM", beam_type, config["path"], true)
		var beam_color = _get_beam_color(beam_type)
		return _spawn_fallback_beam(origin, direction, length, duration, beam_color)
	
	_log_vfx_spawn("BEAM", beam_type, config["path"])
	
	var effect = Node2D.new()
	effect.global_position = origin
	effect.rotation = direction.angle()
	effect.z_index = 8
	
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.hframes = config["hframes"]
	sprite.vframes = config["vframes"]
	sprite.centered = false
	sprite.offset = Vector2(0, -config["frame_size"].y / 2)
	
	# Escalar al tamaño del beam
	var scale_x = length / config["frame_size"].x
	sprite.scale = Vector2(scale_x, 1.0)
	
	effect.add_child(sprite)
	
	var tree = Engine.get_main_loop()
	if tree:
		tree.root.add_child(effect)
		
		# Animar frames
		var total_frames = config["hframes"] * config["vframes"]
		var tween = effect.create_tween()
		tween.tween_property(sprite, "frame", total_frames - 1, duration).from(0)
		tween.tween_callback(effect.queue_free)
	
	return effect

func _spawn_fallback_beam(origin: Vector2, direction: Vector2, length: float, duration: float, beam_color: Color = Color(1.0, 0.6, 0.2)) -> Node2D:
	"""Fallback: usar Beam genérico (flame_breath) si no hay específico"""
	# Intentar usar flame_breath como genérico
	var config = BEAM_CONFIG.get("flame_breath")
	if config:
		var tex = _get_texture(config["path"])
		if tex:
			var effect = Node2D.new()
			effect.global_position = origin
			effect.rotation = direction.angle()
			effect.z_index = 8
			
			var sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.hframes = config["hframes"]
			sprite.vframes = config["vframes"]
			sprite.centered = false
			sprite.offset = Vector2(0, -config["frame_size"].y / 2)
			
			# Escalar y Colorear
			var scale_x = length / config["frame_size"].x
			sprite.scale = Vector2(scale_x, 1.0)
			sprite.modulate = beam_color # Teñir con el color deseado
			
			effect.add_child(sprite)
			
			var tree = Engine.get_main_loop()
			if tree:
				tree.root.add_child(effect)
				var total_frames = config["hframes"] * config["vframes"]
				var tween = effect.create_tween()
				tween.tween_property(sprite, "frame", total_frames - 1, duration).from(0)
				tween.tween_callback(effect.queue_free)
			return effect

	return null

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - TELEGRAPHS (Warnings)
# ══════════════════════════════════════════════════════════════════════════════

func spawn_telegraph(telegraph_type: String, position: Vector2, radius: float, duration: float) -> Node2D:
	"""Spawn un telegraph/warning indicator"""
	var config = TELEGRAPH_CONFIG.get(telegraph_type)
	if not config:
		push_warning("[VFXManager] Telegraph type desconocido: %s" % telegraph_type)
		_log_vfx_spawn("TELEGRAPH", telegraph_type, "", true)
		return _spawn_fallback_telegraph(position, radius, duration)
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("TELEGRAPH", telegraph_type, config["path"], true)
		return _spawn_fallback_telegraph(position, radius, duration)
	
	_log_vfx_spawn("TELEGRAPH", telegraph_type, config["path"])
	
	var effect = Node2D.new()
	effect.global_position = position
	effect.z_index = -1
	
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.hframes = config["hframes"]
	sprite.vframes = config["vframes"]
	sprite.centered = true
	
	# Escalar al radio
	var frame_size = config["frame_size"]
	var scale_factor = (radius * 2) / frame_size.x
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = Color(1, 0.3, 0.3, 0.7)
	
	effect.add_child(sprite)
	
	var tree = Engine.get_main_loop()
	if tree:
		tree.root.add_child(effect)
		
		var total_frames = config["hframes"] * config["vframes"]
		var tween = effect.create_tween()
		
		# Animar frames durante la duración
		tween.tween_property(sprite, "frame", total_frames - 1, duration).from(0)
		
		# Pulsar el alpha
		tween.parallel().tween_method(func(t):
			if is_instance_valid(sprite):
				sprite.modulate.a = 0.5 + 0.3 * sin(t * PI * 6)
		, 0.0, 1.0, duration)
		
		tween.tween_callback(effect.queue_free)
	
	return effect

func spawn_circle_warning(position: Vector2, radius: float, duration: float) -> Node2D:
	"""Shortcut para circle warning"""
	return spawn_telegraph("circle_warning", position, radius, duration)

func spawn_meteor_warning(position: Vector2, radius: float, duration: float) -> Node2D:
	"""Shortcut para meteor warning"""
	return spawn_telegraph("meteor_warning", position, radius, duration)

func _spawn_fallback_telegraph(position: Vector2, radius: float, duration: float) -> Node2D:
	"""Fallback: círculo rojo pulsante"""
	var effect = Node2D.new()
	effect.global_position = position
	effect.z_index = -1
	
	var visual = Node2D.new()
	effect.add_child(visual)
	
	var progress = 0.0
	visual.draw.connect(func():
		var pulse = 0.7 + 0.3 * sin(progress * PI * 8)
		visual.draw_circle(Vector2.ZERO, radius, Color(1, 0.2, 0.2, 0.3 * pulse))
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 0.3, 0.3, 0.6 * pulse), 2.0)
		# Fill que crece
		visual.draw_circle(Vector2.ZERO, radius * progress, Color(1, 0.2, 0.2, 0.5 * (1.0 - progress * 0.5)))
	)
	
	var tree = Engine.get_main_loop()
	if tree:
		tree.root.add_child(effect)
		var tween = effect.create_tween()
		tween.tween_method(func(v): 
			progress = v
			if is_instance_valid(visual): visual.queue_redraw()
		, 0.0, 1.0, duration)
		tween.tween_callback(effect.queue_free)
	
	return effect

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - BOSS SPECIFIC
# ══════════════════════════════════════════════════════════════════════════════

func spawn_boss_vfx(boss_vfx_type: String, position: Vector2, scale: float = 1.0) -> Node2D:
	"""Spawn VFX específico de boss"""
	var config = BOSS_CONFIG.get(boss_vfx_type)
	if not config:
		push_warning("[VFXManager] Boss VFX type desconocido: %s" % boss_vfx_type)
		_log_vfx_spawn("BOSS", boss_vfx_type, "", true)
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("BOSS", boss_vfx_type, config["path"], true)
		return null
	
	_log_vfx_spawn("BOSS", boss_vfx_type, config["path"])
	return _create_animated_vfx(tex, config, position, scale, config["duration"])

func spawn_summon_circle(position: Vector2, scale: float = 1.0) -> Node2D:
	return spawn_boss_vfx("summon_circle", position, scale)

func spawn_reality_tear(position: Vector2, scale: float = 1.0) -> Node2D:
	return spawn_boss_vfx("reality_tear", position, scale)

func spawn_void_pull_effect(position: Vector2, radius: float) -> Node2D:
	var scale = radius / 100.0  # Normalizar
	return spawn_boss_vfx("void_pull", position, scale)

func spawn_rune_shield(position: Vector2, scale: float = 1.0) -> Node2D:
	return spawn_boss_vfx("rune_shield", position, scale)

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN DE VFX - PLAYER
# ══════════════════════════════════════════════════════════════════════════════

func spawn_player_vfx(vfx_type: String, position: Vector2, scale_factor: float = 1.0, duration_override: float = -1.0) -> Node2D:
	"""Spawn VFX de jugador (one-shot)"""
	var config = PLAYER_VFX_CONFIG.get(vfx_type)
	if not config:
		push_warning("[VFXManager] Player VFX type desconocido: %s" % vfx_type)
		_log_vfx_spawn("PLAYER", vfx_type, "", true)
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("PLAYER", vfx_type, config["path"], true)
		return null
	
	_log_vfx_spawn("PLAYER", vfx_type, config["path"])
	return _create_animated_vfx(tex, config, position, scale_factor, duration_override)

func spawn_player_aura(vfx_type: String, parent: Node2D, loop: bool = true) -> AnimatedSprite2D:
	"""Spawn aura de jugador que sigue al nodo padre (loop)"""
	var config = PLAYER_VFX_CONFIG.get(vfx_type)
	if not config:
		push_warning("[VFXManager] Player aura type desconocido: %s" % vfx_type)
		_log_vfx_spawn("PLAYER_AURA", vfx_type, "", true)
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		_log_vfx_spawn("PLAYER_AURA", vfx_type, config["path"], true)
		return null
	
	_log_vfx_spawn("PLAYER_AURA", vfx_type, config["path"])
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _create_sprite_frames_from_sheet(tex, config, "player_" + vfx_type, loop)
	sprite.z_index = 5
	sprite.play("default")
	parent.add_child(sprite)
	return sprite

func spawn_thorns_vfx(position: Vector2) -> Node2D:
	"""Spawn efecto de thorns (one-shot en posición del jugador)"""
	return spawn_player_vfx("thorns", position, 1.0, 0.3)

func spawn_shield_aura(parent: Node2D) -> AnimatedSprite2D:
	"""Spawn aura de escudo persistente - DESACTIVADO POR PETICIÓN DE USUARIO"""
	return null

func spawn_stun_vfx(parent: Node2D) -> AnimatedSprite2D:
	"""Spawn estrellas de stun orbitando (loop)"""
	var sprite = spawn_player_aura("stun", parent, true)
	if sprite:
		sprite.z_index = 10  # Encima del personaje
		sprite.position = Vector2(0, -16)  # Sobre la cabeza
	return sprite

func spawn_slow_vfx(parent: Node2D) -> AnimatedSprite2D:
	"""Spawn hielo de slow en los pies (loop)"""
	var sprite = spawn_player_aura("slow", parent, true)
	if sprite:
		sprite.z_index = -1  # Debajo del personaje
	return sprite

func spawn_frost_nova_vfx(position: Vector2, scale_factor: float = 1.5) -> Node2D:
	"""Spawn efecto de frost nova (one-shot, explosión de hielo)"""
	return spawn_player_vfx("frost_nova", position, scale_factor, 0.5)

func spawn_heal_vfx(position: Vector2) -> Node2D:
	"""Spawn efecto de curación (one-shot, partículas verdes)"""
	return spawn_player_vfx("heal", position, 1.0, 0.5)

func spawn_revive_vfx(position: Vector2) -> Node2D:
	"""Spawn efecto de revive (one-shot, explosión dorada)"""
	return spawn_player_vfx("revive", position, 1.5, 0.8)

func spawn_soul_link_vfx(position: Vector2) -> Node2D:
	"""Spawn efecto de soul link (one-shot, cadenas púrpura)"""
	return spawn_player_vfx("soul_link", position, 1.2, 0.4)

func spawn_shield_absorb_vfx(position: Vector2) -> Node2D:
	"""Spawn efecto de absorción de escudo - DESACTIVADO POR PETICIÓN DE USUARIO"""
	return null

# ══════════════════════════════════════════════════════════════════════════════
# UTILIDADES INTERNAS
# ══════════════════════════════════════════════════════════════════════════════

func _create_animated_vfx(tex: Texture2D, config: Dictionary, position: Vector2, scale_factor: float, duration_override: float) -> Node2D:
	"""Crear un VFX animado genérico"""
	var effect = Node2D.new()
	effect.global_position = position
	effect.z_index = 5
	
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.hframes = config["hframes"]
	sprite.vframes = config["vframes"]
	sprite.centered = true
	
	# Aplicar escala (clamped to prevent screen-covering effects)
	var clamped_scale = clampf(scale_factor, 0.1, 3.0)
	if clamped_scale != 1.0:
		sprite.scale = Vector2(clamped_scale, clamped_scale)
	
	effect.add_child(sprite)
	
	var tree = Engine.get_main_loop()
	if tree:
		tree.root.add_child(effect)
		
		var total_frames = config["hframes"] * config["vframes"]
		var duration = duration_override if duration_override > 0 else config.get("duration", 0.5)
		
		var tween = effect.create_tween()
		tween.tween_property(sprite, "frame", total_frames - 1, duration).from(0)
		tween.tween_callback(effect.queue_free)
	
	return effect

func _create_sprite_frames_from_sheet(tex: Texture2D, config: Dictionary, anim_name: String, loop: bool) -> SpriteFrames:
	"""Crear SpriteFrames desde un spritesheet"""
	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_loop("default", loop)
	
	var hframes = config["hframes"]
	var vframes = config["vframes"]
	var frame_size = config["frame_size"]
	var duration = config.get("duration", 0.5)
	var total_frames = hframes * vframes
	var fps = total_frames / duration
	
	frames.set_animation_speed("default", fps)
	
	# Crear AtlasTextures para cada frame
	for row in range(vframes):
		for col in range(hframes):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
			frames.add_frame("default", atlas)
	
	return frames

# ══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA - MÉTODOS DE CONVENIENCIA
# ══════════════════════════════════════════════════════════════════════════════

func has_aoe_type(aoe_type: String) -> bool:
	return AOE_CONFIG.has(aoe_type) or ABILITY_TO_AOE.has(aoe_type)

func has_projectile_type(element: String) -> bool:
	return PROJECTILE_CONFIG.has(ELEMENT_TO_PROJECTILE.get(element, ""))

func has_aura_type(aura_type: String) -> bool:
	return AURA_CONFIG.has(aura_type)

func has_beam_type(beam_type: String) -> bool:
	return BEAM_CONFIG.has(beam_type)

func has_telegraph_type(telegraph_type: String) -> bool:
	return TELEGRAPH_CONFIG.has(telegraph_type)

func has_boss_vfx_type(boss_type: String) -> bool:
	return BOSS_CONFIG.has(boss_type)

func get_all_aoe_types() -> Array:
	return AOE_CONFIG.keys()

func get_all_projectile_elements() -> Array:
	return ELEMENT_TO_PROJECTILE.keys()

func clear_cache() -> void:
	"""Limpiar cache de texturas (para hot-reload)"""
	_texture_cache.clear()

# ══════════════════════════════════════════════════════════════════════════════
# MÉTODOS PARA SPRITES ADJUNTOS A NODOS
# ══════════════════════════════════════════════════════════════════════════════

func create_animated_sprite(vfx_type: String, category: String) -> AnimatedSprite2D:
	"""Crear un AnimatedSprite2D que puede adjuntarse a cualquier nodo"""
	var config: Dictionary = {}
	
	match category:
		"aoe":
			config = AOE_CONFIG.get(vfx_type, {})
		"projectile":
			config = PROJECTILE_CONFIG.get(vfx_type, {})
		"aura":
			config = AURA_CONFIG.get(vfx_type, {})
		"boss":
			config = BOSS_CONFIG.get(vfx_type, {})
		"telegraph":
			config = TELEGRAPH_CONFIG.get(vfx_type, {})
		"beam":
			config = BEAM_CONFIG.get(vfx_type, {})
	
	if config.is_empty():
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		return null
	
	var sprite_frames = _create_sprite_frames_from_sheet(tex, config, "default", true)
	
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = sprite_frames
	sprite.play("default")
	sprite.centered = true
	
	return sprite

func spawn_projectile_attached(projectile_type: String, parent: Node2D) -> AnimatedSprite2D:
	"""Crear sprite de proyectil y adjuntarlo a un nodo padre"""
	var config = PROJECTILE_CONFIG.get(projectile_type, {})
	if config.is_empty():
		return null
	
	var tex = _get_texture(config["path"])
	if not tex:
		return null
	
	var sprite_frames = _create_sprite_frames_from_sheet(tex, config, "default", true)
	
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = sprite_frames
	sprite.play("default")
	sprite.centered = true
	
	parent.add_child(sprite)
	return sprite
