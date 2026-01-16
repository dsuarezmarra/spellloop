# SpawnConfig.gd
# Configuración centralizada del sistema de spawn
# Define oleadas, fases, eventos especiales y toda la progresión del juego
#
# ESTRUCTURA DEL JUEGO (30 minutos base):
# - Fase 1 (0-5 min): Introducción - Solo Tier 1, aprender mecánicas
# - Fase 2 (5-10 min): Escalada - Tier 1-2, primer boss
# - Fase 3 (10-15 min): Desafío - Tier 1-3, segundo boss
# - Fase 4 (15-20 min): Caos - Tier 1-4, tercer boss
# - Fase 5 (20+ min): Infinito - Todo escalado exponencial, bosses rotando

extends RefCounted
class_name SpawnConfig

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES GLOBALES
# ═══════════════════════════════════════════════════════════════════════════════

# Tiempo total del juego "base" antes del escalado infinito
const GAME_BASE_DURATION_MINUTES: float = 20.0

# Distancias de spawn
const SPAWN_DISTANCE_MIN: float = 500.0
const SPAWN_DISTANCE_MAX: float = 700.0
const SPAWN_DISTANCE_BOSS: float = 400.0  # Bosses aparecen más cerca

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE FASES
# ═══════════════════════════════════════════════════════════════════════════════

# Cada fase define cómo se comporta el spawn durante ese período
# REBALANCEADO: Mayor densidad de enemigos, spawn más agresivo
const PHASES = {
	1: {
		"name": "",
		"start_minute": 0,
		"end_minute": 5,
		"description": "",
		"available_tiers": [1],
		"max_enemies": 35,        # AUMENTADO: 25→35
		"spawn_rate": 1.2,        # AUMENTADO: 0.8→1.2 enemigos/segundo
		"tier_weights": {1: 1.0},
		"special_events": [],
		"music_intensity": "calm"
	},
	2: {
		"name": "",
		"start_minute": 5,
		"end_minute": 10,
		"description": "",
		"available_tiers": [1, 2],
		"max_enemies": 55,        # AUMENTADO: 40→55
		"spawn_rate": 1.8,        # AUMENTADO: 1.2→1.8
		"tier_weights": {1: 0.7, 2: 0.3},
		"special_events": ["first_boss"],
		"music_intensity": "medium"
	},
	3: {
		"name": "Desafío",
		"start_minute": 10,
		"end_minute": 15,
		"description": "Enemigos más peligrosos aparecen",
		"available_tiers": [1, 2, 3],
		"max_enemies": 75,        # AUMENTADO: 55→75
		"spawn_rate": 2.2,        # AUMENTADO: 1.6→2.2
		"tier_weights": {1: 0.5, 2: 0.35, 3: 0.15},
		"special_events": ["second_boss", "elite_surge"],
		"music_intensity": "high"
	},
	4: {
		"name": "Caos",
		"start_minute": 15,
		"end_minute": 20,
		"description": "Todos los enemigos pueden aparecer",
		"available_tiers": [1, 2, 3, 4],
		"max_enemies": 100,       # AUMENTADO: 70→100
		"spawn_rate": 2.8,        # AUMENTADO: 2.0→2.8
		"tier_weights": {1: 0.35, 2: 0.30, 3: 0.25, 4: 0.10},
		"special_events": ["third_boss", "swarm_event"],
		"music_intensity": "intense"
	},
	5: {
		"name": "Infinito",
		"start_minute": 20,
		"end_minute": -1,  # Sin fin
		"description": "Sobrevive todo lo que puedas",
		"available_tiers": [1, 2, 3, 4],
		"max_enemies": 150,       # AUMENTADO: 100→150
		"spawn_rate": 3.5,        # AUMENTADO: 2.5→3.5
		"tier_weights": {1: 0.25, 2: 0.30, 3: 0.30, 4: 0.15},
		"special_events": ["rotating_bosses", "death_wave"],
		"music_intensity": "epic"
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE OLEADAS (WAVES) DENTRO DE CADA FASE
# ═══════════════════════════════════════════════════════════════════════════════

# Oleadas son micro-eventos que ocurren cada X segundos
const WAVE_INTERVAL_SECONDS: float = 30.0  # Una oleada cada 30 segundos

# Tipos de oleadas
const WAVE_TYPES = {
	"normal": {
		"spawn_count": 5,
		"spawn_delay": 0.3,  # Tiempo entre cada spawn de la oleada
		"tier_override": null,  # Usa tier de la fase
		"announcement": ""
	},
	"swarm": {
		"spawn_count": 15,
		"spawn_delay": 0.1,
		"tier_override": 1,  # Solo tier 1 pero muchos
		"announcement": "¡Enjambre!"
	},
	"heavy": {
		"spawn_count": 3,
		"spawn_delay": 0.5,
		"tier_override": null,  # Usa tier+1 de la fase
		"tier_bonus": 1,
		"announcement": "¡Enemigos pesados!"
	},
	"mixed": {
		"spawn_count": 8,
		"spawn_delay": 0.2,
		"tier_override": null,
		"force_variety": true,  # Fuerza diferentes tipos
		"announcement": ""
	},
	"ambush": {
		"spawn_count": 10,
		"spawn_delay": 0.05,  # Muy rápido
		"spawn_pattern": "surround",  # Aparecen rodeando al jugador
		"announcement": "¡Emboscada!"
	}
}

# Secuencia de oleadas por fase (se repite en loop)
const PHASE_WAVE_SEQUENCES = {
	1: ["normal", "normal", "normal", "mixed"],  # Fase 1: Simple
	2: ["normal", "mixed", "normal", "swarm", "heavy"],  # Fase 2: Más variedad
	3: ["mixed", "heavy", "swarm", "normal", "ambush", "heavy"],  # Fase 3: Intenso
	4: ["heavy", "swarm", "ambush", "mixed", "heavy", "swarm", "ambush"],  # Fase 4: Caótico
	5: ["ambush", "heavy", "swarm", "heavy", "ambush", "swarm", "heavy", "ambush"]  # Fase 5: Brutal
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE BOSSES
# ═══════════════════════════════════════════════════════════════════════════════

# Pool de todos los bosses disponibles (aparecen aleatoriamente)
const BOSS_POOL = [
	"el_conjurador_primigenio",
	"el_corazon_del_vacio",
	"el_guardian_de_runas",
	"minotauro_de_fuego"
]

# Escalado de dificultad según el minuto de aparición
# BOSSES PROGRESIVOS - Dificultad escalada gradualmente
# BALANCEADO: Intervalos aumentados para dar más tiempo de reacción al jugador (100 px/s)
const BOSS_MINUTE_SCALING = {
	5: {
		"hp_mult": 1.0,
		"damage_mult": 1.0,
		"cooldown_mult": 1.0,             # Cooldowns normales
		"abilities_unlocked": 2,          # Solo 2 habilidades básicas
		"max_combo": 2,                   # Combos de 2 habilidades
		"combo_delay": 2.0,               # AUMENTADO de 1.5 a 2.0s entre habilidades
		"phase_threshold_mult": 0.9,
		"attack_interval": 1.5,           # AUMENTADO de 1.2 a 1.5s (más lento)
		"aoe_spawn_interval": 6.0,        # AUMENTADO de 5 a 6s
		"homing_interval": 8.0,           # AUMENTADO de 6 a 8s
		"spread_interval": 10.0,          # AUMENTADO de 8 a 10s
		"orbital_count": 2,               # Solo 2 orbitales
		"enable_homing": false,           # Sin homing al principio
		"enable_spread": false            # Sin spread al principio
	},
	10: {
		"hp_mult": 1.4,
		"damage_mult": 1.1,               # REDUCIDO de 1.2
		"cooldown_mult": 0.85,            # AUMENTADO de 0.8 (cooldowns más largos)
		"abilities_unlocked": 3,          # 3 habilidades
		"max_combo": 2,                   # REDUCIDO de 3 a 2
		"combo_delay": 1.5,               # AUMENTADO de 1.2 a 1.5s
		"phase_threshold_mult": 1.0,
		"attack_interval": 1.3,           # AUMENTADO de 1.0 a 1.3s
		"aoe_spawn_interval": 5.0,        # AUMENTADO de 4 a 5s
		"homing_interval": 6.0,           # AUMENTADO de 5 a 6s
		"spread_interval": 8.0,           # AUMENTADO de 7 a 8s
		"orbital_count": 2,               # REDUCIDO de 3 a 2
		"enable_homing": true,            # Habilitar homing
		"enable_spread": false            # Sin spread todavía
	},
	15: {
		"hp_mult": 1.8,
		"damage_mult": 1.3,               # REDUCIDO de 1.5
		"cooldown_mult": 0.7,             # AUMENTADO de 0.6
		"abilities_unlocked": 4,          # 4 habilidades
		"max_combo": 3,                   # REDUCIDO de 4 a 3
		"combo_delay": 1.2,               # AUMENTADO de 0.8 a 1.2s
		"phase_threshold_mult": 1.2,
		"attack_interval": 1.1,           # AUMENTADO de 0.8 a 1.1s
		"aoe_spawn_interval": 4.0,        # AUMENTADO de 3 a 4s
		"homing_interval": 5.0,           # AUMENTADO de 4 a 5s
		"spread_interval": 6.0,           # AUMENTADO de 5 a 6s
		"orbital_count": 3,               # REDUCIDO de 4 a 3
		"enable_homing": true,
		"enable_spread": true             # Habilitar spread
	},
	20: {
		"hp_mult": 2.2,
		"damage_mult": 1.5,               # REDUCIDO de 1.8
		"cooldown_mult": 0.5,             # AUMENTADO de 0.4
		"abilities_unlocked": 5,          # REDUCIDO de 6 a 5
		"max_combo": 4,                   # REDUCIDO de 5 a 4
		"combo_delay": 0.8,               # AUMENTADO de 0.5 a 0.8s
		"phase_threshold_mult": 1.5,
		"attack_interval": 0.9,           # AUMENTADO de 0.6 a 0.9s
		"aoe_spawn_interval": 3.0,        # AUMENTADO de 2 a 3s
		"homing_interval": 4.0,           # AUMENTADO de 3 a 4s
		"spread_interval": 5.0,           # AUMENTADO de 4 a 5s
		"orbital_count": 4,               # REDUCIDO de 5 a 4
		"enable_homing": true,
		"enable_spread": true
	}
}

# Tracking del último boss para no repetir
static var last_boss_spawned: String = ""

# Configuración de spawn de boss
const BOSS_CONFIG = {
	"pre_spawn_warning_seconds": 5.0,  # Aviso antes de que aparezca
	"spawn_invulnerability_seconds": 2.0,  # Boss invulnerable al aparecer
	"clear_enemies_on_spawn": false,  # No limpiar enemigos al aparecer boss
	"reduce_spawns_during_boss": true,  # Reducir spawn rate durante pelea
	"spawn_rate_during_boss": 0.3  # 30% del spawn rate normal
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE ÉLITES
# ═══════════════════════════════════════════════════════════════════════════════

const ELITE_CONFIG = {
	"first_spawn_minute": 1.0,  # Aparecen antes (minuto 1)
	"spawn_interval_base": 60.0,  # Cada 1 minuto (mucho más frecuente)
	"spawn_interval_variance": 15.0,  # ±15 segundos
	"max_active": 2,  # Hasta 2 élites simultáneos
	"max_per_game_base": 15,  # Más oportunidades de loot raro
	"elite_per_5min_infinite": 3,  # En fase infinita, 3 cada 5 min
	"guaranteed_drop": true,  # Siempre dropean algo especial
	"spawn_announcement": "⭐ ¡Enemigo Legendario!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# EVENTOS ESPECIALES
# ═══════════════════════════════════════════════════════════════════════════════

const SPECIAL_EVENTS = {
	"swarm_event": {
		"duration_seconds": 20.0,
		"spawn_multiplier": 3.0,
		"tier_override": 1,
		"announcement": "🐜 ¡ENJAMBRE! ¡Oleada masiva de enemigos débiles!",
		"music_override": "swarm"
	},
	"elite_surge": {
		"duration_seconds": 30.0,
		"elite_spawn_count": 2,
		"elite_spawn_delay": 10.0,
		"announcement": "⭐ ¡SURGIMIENTO ÉLITE! ¡Múltiples legendarios!",
		"music_override": "elite"
	},
	"death_wave": {
		"duration_seconds": 15.0,
		"spawn_multiplier": 5.0,
		"all_tiers": true,
		"announcement": "💀 ¡OLEADA DE MUERTE!",
		"music_override": "death"
	},
	"breather": {
		"duration_seconds": 10.0,
		"spawn_multiplier": 0.0,  # Sin spawns
		"heal_player_percent": 0.1,  # Cura 10% HP
		"announcement": "",
		"music_override": "calm"
	}
}

# Eventos programados por minuto (además de los de fase)
const TIMED_EVENTS = {
	3.0: "breather",      # Minuto 3: pequeño respiro
	7.5: "swarm_event",   # Minuto 7:30: primer enjambre
	12.0: "elite_surge",  # Minuto 12: élites
	17.0: "swarm_event",  # Minuto 17: otro enjambre
	19.0: "breather",     # Minuto 19: respiro antes del infinito
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESCALADO INFINITO (POST MINUTO 20)
# ═══════════════════════════════════════════════════════════════════════════════

const INFINITE_SCALING = {
	"scaling_interval_minutes": 5.0,  # Escala cada 5 minutos
	"hp_multiplier_per_interval": 1.5,  # +50% HP cada 5 min
	"damage_multiplier_per_interval": 1.3,  # +30% daño cada 5 min
	"spawn_rate_multiplier_per_interval": 1.2,  # +20% spawn rate
	"max_enemies_increase_per_interval": 15,
	"xp_multiplier_per_interval": 1.4,  # +40% XP (recompensa)
	
	# Caps para evitar que sea imposible
	"max_hp_multiplier": 10.0,  # Máximo x10 HP
	"max_damage_multiplier": 5.0,  # Máximo x5 daño
	"max_spawn_rate": 8.0,  # Máximo 8 enemigos/segundo
	"max_enemies_cap": 200  # Máximo 200 enemigos simultáneos
}

# ═══════════════════════════════════════════════════════════════════════════════
# PATRONES DE SPAWN
# ═══════════════════════════════════════════════════════════════════════════════

const SPAWN_PATTERNS = {
	"random": {
		"description": "Spawn aleatorio alrededor del jugador",
		"angle_variance": 360.0
	},
	"directional": {
		"description": "Spawn desde una dirección específica",
		"angle_variance": 45.0
	},
	"surround": {
		"description": "Enemigos rodean al jugador equidistantes",
		"angle_variance": 0.0  # Posiciones exactas
	},
	"line": {
		"description": "Enemigos en línea desde un punto",
		"spacing": 50.0
	},
	"cluster": {
		"description": "Grupo compacto de enemigos",
		"cluster_radius": 100.0
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES HELPER
# ═══════════════════════════════════════════════════════════════════════════════

static func get_phase_for_minute(minute: float) -> int:
	"""Obtener el número de fase para un minuto dado"""
	for phase_num in range(5, 0, -1):  # Buscar de mayor a menor
		var phase = PHASES[phase_num]
		if minute >= phase.start_minute:
			if phase.end_minute < 0 or minute < phase.end_minute:
				return phase_num
	return 1

static func get_phase_config(phase_num: int) -> Dictionary:
	"""Obtener configuración de una fase"""
	return PHASES.get(phase_num, PHASES[1])

static func get_wave_sequence_for_phase(phase_num: int) -> Array:
	"""Obtener secuencia de oleadas para una fase"""
	return PHASE_WAVE_SEQUENCES.get(phase_num, PHASE_WAVE_SEQUENCES[1])

static func get_wave_config(wave_type: String) -> Dictionary:
	"""Obtener configuración de un tipo de oleada"""
	return WAVE_TYPES.get(wave_type, WAVE_TYPES["normal"])

static func get_boss_for_minute(minute: int) -> String:
	"""Obtener un boss aleatorio (sin repetir el anterior)"""
	if minute % 5 != 0 or minute < 5:
		return ""
	
	# Crear lista de bosses disponibles (excluyendo el último)
	var available_bosses = BOSS_POOL.duplicate()
	if last_boss_spawned != "" and available_bosses.size() > 1:
		available_bosses.erase(last_boss_spawned)
	
	# Seleccionar aleatorio
	var selected = available_bosses[randi() % available_bosses.size()]
	last_boss_spawned = selected
	
	return selected

static func get_boss_scaling_for_minute(minute: int) -> Dictionary:
	"""Obtener multiplicadores de dificultad según el minuto"""
	if BOSS_MINUTE_SCALING.has(minute):
		return BOSS_MINUTE_SCALING[minute].duplicate()
	
	# Para minutos > 20, escalar progresivamente
	var intervals = (minute - 20) / 5
	return {
		"hp_mult": 2.2 + intervals * 0.4,
		"damage_mult": 1.8 + intervals * 0.2,
		"cooldown_mult": max(0.3, 0.4 - intervals * 0.02),
		"abilities_unlocked": min(8, 6 + intervals),
		"max_combo": min(6, 5 + intervals),
		"combo_delay": max(0.3, 0.5 - intervals * 0.05),
		"phase_threshold_mult": 1.5 + intervals * 0.1,
		"attack_interval": max(0.4, 0.6 - intervals * 0.05),
		"aoe_spawn_interval": max(1.5, 2.0 - intervals * 0.1),
		"homing_interval": max(2.0, 3.0 - intervals * 0.2),
		"spread_interval": max(3.0, 4.0 - intervals * 0.2),
		"orbital_count": min(6, 5 + intervals),
		"enable_homing": true,
		"enable_spread": true
	}

static func reset_boss_tracking() -> void:
	"""Resetear tracking de bosses (llamar al inicio de partida)"""
	last_boss_spawned = ""

static func get_infinite_scaling_multiplier(minute: float) -> Dictionary:
	"""Calcular multiplicadores de escalado infinito"""
	if minute <= GAME_BASE_DURATION_MINUTES:
		return {"hp": 1.0, "damage": 1.0, "spawn_rate": 1.0, "xp": 1.0}
	
	var intervals_past = (minute - GAME_BASE_DURATION_MINUTES) / INFINITE_SCALING.scaling_interval_minutes
	
	var hp_mult = pow(INFINITE_SCALING.hp_multiplier_per_interval, intervals_past)
	var dmg_mult = pow(INFINITE_SCALING.damage_multiplier_per_interval, intervals_past)
	var spawn_mult = pow(INFINITE_SCALING.spawn_rate_multiplier_per_interval, intervals_past)
	var xp_mult = pow(INFINITE_SCALING.xp_multiplier_per_interval, intervals_past)
	
	# Aplicar caps
	hp_mult = min(hp_mult, INFINITE_SCALING.max_hp_multiplier)
	dmg_mult = min(dmg_mult, INFINITE_SCALING.max_damage_multiplier)
	
	return {
		"hp": hp_mult,
		"damage": dmg_mult,
		"spawn_rate": spawn_mult,
		"xp": xp_mult
	}

static func should_trigger_event(minute: float, last_event_minute: float) -> String:
	"""Verificar si hay un evento programado para este minuto"""
	for event_minute in TIMED_EVENTS:
		if minute >= event_minute and last_event_minute < event_minute:
			return TIMED_EVENTS[event_minute]
	return ""

static func get_spawn_pattern_config(pattern_name: String) -> Dictionary:
	"""Obtener configuración de un patrón de spawn"""
	return SPAWN_PATTERNS.get(pattern_name, SPAWN_PATTERNS["random"])
