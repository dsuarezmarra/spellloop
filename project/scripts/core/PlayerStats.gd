# PlayerStats.gd
# Sistema de estadísticas del jugador
#
# IMPORTANTE: No hay items pasivos separados
# Las mejoras van directamente al jugador o a las armas
#
# STATS DEL JUGADOR:
# - max_health: Vida máxima
# - health_regen: Regeneración de vida por segundo
# - move_speed: Velocidad de movimiento
# - damage_mult: Multiplicador de daño global
# - cooldown_mult: Multiplicador de cooldown (menor = más rápido)
# - crit_chance: Probabilidad de crítico
# - crit_damage: Multiplicador de daño crítico
# - area_mult: Multiplicador de área de efecto
# - pickup_range: Rango de recolección de XP
# - xp_mult: Multiplicador de experiencia
# - armor: Reducción de daño plana
# - luck: Afecta rareza de drops y opciones de level up

extends Node
class_name PlayerStats

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal health_changed(current: float, maximum: float)
signal level_changed(new_level: int)
signal xp_gained(amount: float, total: float)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

# Metadatos de cada stat para UI (descripción, icono, categoría)
const STAT_METADATA: Dictionary = {
	# === STATS DEFENSIVOS ===
	"max_health": {
		"name": "Vida Máxima",
		"icon": "❤️",
		"category": "defensive",
		"description": "La cantidad máxima de puntos de vida que puedes tener.",
		"format": "flat",  # flat, percent, multiplier
		"color": Color(1.0, 0.3, 0.3)
	},
	"health_regen": {
		"name": "Regeneración",
		"icon": "💚",
		"category": "defensive",
		"description": "Puntos de vida recuperados por segundo.",
		"format": "per_second",
		"color": Color(0.3, 1.0, 0.3)
	},
	"armor": {
		"name": "Armadura",
		"icon": "🛡️",
		"category": "defensive",
		"description": "Reduce el daño recibido de forma plana.",
		"format": "flat",
		"color": Color(0.6, 0.6, 0.8)
	},
	"dodge_chance": {
		"name": "Esquivar",
		"icon": "💨",
		"category": "defensive",
		"description": "Probabilidad de evitar completamente un ataque. Máximo 60%.",
		"format": "percent",
		"color": Color(0.5, 0.8, 1.0)
	},
	"life_steal": {
		"name": "Robo de Vida",
		"icon": "🩸",
		"category": "defensive",
		"description": "Porcentaje de daño infligido que recuperas como vida.",
		"format": "percent",
		"color": Color(0.8, 0.2, 0.4)
	},

	# === STATS OFENSIVOS GLOBALES DE ARMAS ===
	# NOTA: Estos stats afectan a TODAS las armas y se muestran en el popup de cada arma
	# NO se muestran en la pestaña de Stats del jugador
	"damage_mult": {
		"name": "Daño",
		"icon": "⚔️",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Multiplicador global de todo el daño que infliges.",
		"format": "multiplier",
		"color": Color(1.0, 0.5, 0.2)
	},
	"cooldown_mult": {
		"name": "Cooldown",
		"icon": "⏱️",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Multiplicador de tiempo entre ataques. Menor es mejor.",
		"format": "multiplier_inverse",
		"color": Color(0.3, 0.7, 1.0)
	},
	"area_mult": {
		"name": "Área de Efecto",
		"icon": "🌀",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Tamaño de todas las áreas de efecto y explosiones.",
		"format": "multiplier",
		"color": Color(0.8, 0.4, 1.0)
	},
	"projectile_speed_mult": {
		"name": "Vel. Proyectiles",
		"icon": "➡️",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Velocidad de todos tus proyectiles.",
		"format": "multiplier",
		"color": Color(0.4, 0.9, 0.6)
	},
	"duration_mult": {
		"name": "Duración",
		"icon": "⌛",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Duración de efectos, proyectiles y habilidades.",
		"format": "multiplier",
		"color": Color(0.9, 0.8, 0.3)
	},
	"extra_projectiles": {
		"name": "Proyectiles Extra",
		"icon": "🎯",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Proyectiles adicionales en cada ataque.",
		"format": "flat",
		"color": Color(1.0, 0.6, 0.8)
	},
	"knockback_mult": {
		"name": "Empuje",
		"icon": "💥",
		"category": "weapon_global",  # Cambiado de "offensive" - ahora se muestra solo en armas
		"description": "Fuerza con la que empujas a los enemigos.",
		"format": "multiplier",
		"color": Color(0.9, 0.5, 0.3)
	},

	# === STATS CRÍTICOS (GLOBALES DE ARMAS) ===
	"crit_chance": {
		"name": "Prob. Crítico",
		"icon": "🎯",
		"category": "weapon_global",  # Movido de 'critical' - ahora se muestra solo en popup de armas
		"description": "Probabilidad de infligir un golpe crítico.",
		"format": "percent",
		"color": Color(1.0, 0.9, 0.2)
	},
	"crit_damage": {
		"name": "Daño Crítico",
		"icon": "💢",
		"category": "weapon_global",  # Movido de 'critical' - ahora se muestra solo en popup de armas
		"description": "Multiplicador de daño en golpes críticos.",
		"format": "multiplier",
		"color": Color(1.0, 0.7, 0.1)
	},

	# === STATS DE UTILIDAD ===
	"move_speed": {
		"name": "Velocidad",
		"icon": "🏃",
		"category": "utility",
		"description": "Velocidad de movimiento del personaje.",
		"format": "multiplier",
		"color": Color(0.4, 0.8, 1.0)
	},
	"pickup_range": {
		"name": "Rango Recogida",
		"icon": "🧲",
		"category": "utility",
		"description": "Distancia a la que atraes XP y objetos.",
		"format": "multiplier",
		"color": Color(0.8, 0.5, 1.0)
	},
	"pickup_range_flat": {
		"name": "Recogida Extra",
		"icon": "🧲",
		"category": "hidden",  # Ocultar - se combina con pickup_range en la UI
		"description": "Bonus plano al rango de recogida (píxeles).",
		"format": "flat",
		"color": Color(0.8, 0.5, 1.0)
	},
	"xp_mult": {
		"name": "Experiencia",
		"icon": "⭐",
		"category": "utility",
		"description": "Multiplicador de experiencia obtenida.",
		"format": "multiplier",
		"color": Color(0.3, 0.9, 0.5)
	},
	"coin_value_mult": {
		"name": "Valor Monedas",
		"icon": "🪙",
		"category": "utility",
		"description": "Multiplicador del valor de las monedas.",
		"format": "multiplier",
		"color": Color(1.0, 0.85, 0.2)
	},
	"luck": {
		"name": "Suerte",
		"icon": "🍀",
		"category": "utility",
		"description": "Afecta la rareza de drops y mejoras ofrecidas.",
		"format": "flat",
		"color": Color(0.2, 0.9, 0.4)
	},
	
	# === NUEVOS STATS DEFENSIVOS ===
	"damage_taken_mult": {
		"name": "Daño Recibido",
		"icon": "💔",
		"category": "defensive",
		"description": "Multiplicador del daño que recibes. Menor es mejor.",
		"format": "multiplier_inverse",
		"color": Color(0.8, 0.3, 0.3)
	},
	"thorns": {
		"name": "Espinas",
		"icon": "🌵",
		"category": "defensive",
		"description": "Daño reflejado a enemigos que te golpean.",
		"format": "flat",
		"color": Color(0.6, 0.4, 0.2)
	},
	"thorns_percent": {
		"name": "Espinas %",
		"icon": "🌵",
		"category": "defensive",
		"description": "% del daño recibido que se refleja.",
		"format": "percent",
		"color": Color(0.6, 0.4, 0.2)
	},
	"shield_amount": {
		"name": "Escudo",
		"icon": "🛡️",
		"category": "defensive",
		"description": "Puntos de escudo que absorben daño.",
		"format": "flat",
		"color": Color(0.3, 0.6, 0.9)
	},
	"shield_regen": {
		"name": "Regen. Escudo",
		"icon": "🔄",
		"category": "defensive",
		"description": "Puntos de escudo regenerados por segundo.",
		"format": "per_second",
		"color": Color(0.3, 0.6, 0.9)
	},
	"revives": {
		"name": "Revivir",
		"icon": "💫",
		"category": "defensive",
		"description": "Veces que puedes revivir al morir.",
		"format": "flat",
		"color": Color(1.0, 0.9, 0.3)
	},
	
	# === NUEVOS STATS OFENSIVOS ===
	"kill_heal": {
		"name": "Curar al Matar",
		"icon": "💀",
		"category": "offensive",
		"description": "HP recuperado por cada enemigo eliminado.",
		"format": "flat",
		"color": Color(0.8, 0.2, 0.4)
	},
	"damage_flat": {
		"name": "Daño Plano",
		"icon": "➕",
		"category": "weapon_global",
		"description": "Daño adicional en cada ataque.",
		"format": "flat",
		"color": Color(1.0, 0.5, 0.2)
	},
	"burn_damage": {
		"name": "Daño Fuego",
		"icon": "🔥",
		"category": "weapon_global",
		"description": "Daño de quemadura adicional por segundo.",
		"format": "flat",
		"color": Color(1.0, 0.4, 0.1)
	},
	"freeze_chance": {
		"name": "Prob. Congelar",
		"icon": "❄️",
		"category": "weapon_global",
		"description": "Probabilidad de congelar enemigos.",
		"format": "percent",
		"color": Color(0.4, 0.8, 1.0)
	},
	"bleed_chance": {
		"name": "Prob. Sangrado",
		"icon": "🩸",
		"category": "weapon_global",
		"description": "Probabilidad de causar sangrado.",
		"format": "percent",
		"color": Color(0.8, 0.2, 0.2)
	},
	"execute_threshold": {
		"name": "Umbral Ejecución",
		"icon": "⚰️",
		"category": "weapon_global",
		"description": "Mata instantáneamente enemigos bajo este % de HP.",
		"format": "percent",
		"color": Color(0.3, 0.1, 0.1)
	},
	"overkill_damage": {
		"name": "Daño Exceso",
		"icon": "💥",
		"category": "weapon_global",
		"description": "% del daño excedente que pasa al siguiente enemigo.",
		"format": "percent",
		"color": Color(1.0, 0.3, 0.1)
	},
	"attack_speed_mult": {
		"name": "Vel. Ataque",
		"icon": "⚡",
		"category": "weapon_global",
		"description": "Multiplicador de velocidad de ataque.",
		"format": "multiplier",
		"color": Color(1.0, 0.8, 0.2)
	},
	"extra_pierce": {
		"name": "Penetración",
		"icon": "🔱",
		"category": "weapon_global",
		"description": "Enemigos adicionales que atraviesan los proyectiles.",
		"format": "flat",
		"color": Color(0.5, 0.5, 0.8)
	},
	"chain_count": {
		"name": "Rebotes",
		"icon": "⚡",
		"category": "weapon_global",
		"description": "Veces que los proyectiles rebotan entre enemigos.",
		"format": "flat",
		"color": Color(0.8, 0.8, 0.2)
	},
	"explosion_chance": {
		"name": "Prob. Explosión",
		"icon": "💣",
		"category": "weapon_global",
		"description": "Probabilidad de causar explosión al matar.",
		"format": "percent",
		"color": Color(1.0, 0.5, 0.1)
	},
	"explosion_damage": {
		"name": "Daño Explosión",
		"icon": "💣",
		"category": "weapon_global",
		"description": "Daño de las explosiones.",
		"format": "flat",
		"color": Color(1.0, 0.5, 0.1)
	},
	"range_mult": {
		"name": "Alcance",
		"icon": "🎯",
		"category": "weapon_global",
		"description": "Multiplicador del alcance de ataques.",
		"format": "multiplier",
		"color": Color(0.4, 0.7, 0.9)
	},
	
	# === NUEVOS STATS DE UTILIDAD ===
	"gold_mult": {
		"name": "Oro",
		"icon": "🪙",
		"category": "utility",
		"description": "Multiplicador del oro obtenido.",
		"format": "multiplier",
		"color": Color(1.0, 0.85, 0.2)
	},
	"reroll_count": {
		"name": "Rerolls Extra",
		"icon": "🔄",
		"category": "utility",
		"description": "Rerolls adicionales en level up.",
		"format": "flat",
		"color": Color(0.5, 0.8, 1.0)
	},
	"banish_count": {
		"name": "Banish Extra",
		"icon": "❌",
		"category": "utility",
		"description": "Banishes adicionales en level up.",
		"format": "flat",
		"color": Color(1.0, 0.4, 0.4)
	},
	"curse": {
		"name": "Maldición",
		"icon": "☠️",
		"category": "utility",
		"description": "Aumenta enemigos y dificultad, pero también recompensas.",
		"format": "percent",
		"color": Color(0.5, 0.1, 0.5)
	},
	"growth": {
		"name": "Crecimiento",
		"icon": "📈",
		"category": "utility",
		"description": "Bonus a TODOS los stats que aumenta con el tiempo.",
		"format": "percent",
		"color": Color(0.3, 0.9, 0.5)
	},
	"magnet_strength": {
		"name": "Fuerza Imán",
		"icon": "🧲",
		"category": "utility",
		"description": "Velocidad a la que se atraen los objetos.",
		"format": "multiplier",
		"color": Color(0.8, 0.5, 1.0)
	},
	"levelup_options": {
		"name": "Opciones Extra",
		"icon": "📋",
		"category": "utility",
		"description": "Opciones adicionales al subir de nivel.",
		"format": "flat",
		"color": Color(0.6, 0.8, 1.0)
	}
}

const BASE_STATS: Dictionary = {
	# Defensivos
	"max_health": 100.0,
	"health_regen": 0.0,
	"armor": 0.0,
	"dodge_chance": 0.0,           # Probabilidad de esquivar (máx 0.6)
	"life_steal": 0.0,             # % de daño que recupera como vida
	"damage_taken_mult": 1.0,      # Multiplicador de daño recibido (menor = mejor)
	"thorns": 0.0,                 # Daño plano reflejado
	"thorns_percent": 0.0,         # % del daño reflejado
	"shield_amount": 0.0,          # Escudo que absorbe daño
	"shield_regen": 0.0,           # Regeneración de escudo/s
	"revives": 0,                  # Vidas extra

	# Ofensivos - Stats globales de armas
	"damage_mult": 1.0,
	"damage_flat": 0.0,            # Daño plano adicional
	"cooldown_mult": 1.0,
	"attack_speed_mult": 1.0,      # Multiplicador de velocidad de ataque
	"area_mult": 1.0,
	"projectile_speed_mult": 1.0,
	"duration_mult": 1.0,
	"extra_projectiles": 0,        # Proyectiles adicionales
	"extra_pierce": 0,             # Penetración adicional
	"knockback_mult": 1.0,
	"range_mult": 1.0,             # Alcance de ataques
	"chain_count": 0,              # Rebotes entre enemigos
	
	# Efectos especiales de ataque
	"burn_damage": 0.0,            # Daño de quemadura/s
	"freeze_chance": 0.0,          # Prob. de congelar
	"bleed_chance": 0.0,           # Prob. de sangrado
	"explosion_chance": 0.0,       # Prob. de explosión al matar
	"explosion_damage": 0.0,       # Daño de explosiones
	"execute_threshold": 0.0,      # Umbral de ejecución (%)
	"overkill_damage": 0.0,        # % de daño excedente transferido

	# Críticos
	"crit_chance": 0.05,
	"crit_damage": 2.0,
	
	# Curación
	"kill_heal": 0.0,              # HP por kill

	# Utilidad
	"move_speed": 1.0,
	"pickup_range": 1.0,
	"pickup_range_flat": 0.0,
	"magnet_strength": 1.0,        # Velocidad de atracción
	"xp_mult": 1.0,
	"coin_value_mult": 1.0,
	"gold_mult": 1.0,              # Multiplicador de oro
	"luck": 0.0,
	"curse": 0.0,                  # Dificultad extra = más recompensas
	"growth": 0.0,                 # Bonus que escala con tiempo
	"reroll_count": 0,             # Rerolls extra
	"banish_count": 0,             # Banishes extra
	"levelup_options": 0           # Opciones extra en levelup
}

const MAX_LEVEL: int = 99
const BASE_XP_TO_LEVEL: float = 10.0
const XP_SCALING: float = 1.15  # Cada nivel requiere 15% más XP

# Límites de stats
const STAT_LIMITS: Dictionary = {
	# Multiplicadores
	"cooldown_mult": {"min": 0.1, "max": 2.0},
	"damage_mult": {"min": 0.1, "max": 10.0},
	"damage_taken_mult": {"min": 0.1, "max": 3.0},
	"move_speed": {"min": 0.3, "max": 3.0},
	"pickup_range": {"min": 0.5, "max": 5.0},
	"area_mult": {"min": 0.5, "max": 3.0},
	"projectile_speed_mult": {"min": 0.5, "max": 3.0},
	"duration_mult": {"min": 0.5, "max": 3.0},
	"knockback_mult": {"min": 0.0, "max": 5.0},
	"attack_speed_mult": {"min": 0.1, "max": 5.0},
	"range_mult": {"min": 0.5, "max": 3.0},
	"magnet_strength": {"min": 0.5, "max": 5.0},
	"xp_mult": {"min": 0.5, "max": 5.0},
	"gold_mult": {"min": 0.5, "max": 5.0},
	
	# Probabilidades (0-100%)
	"crit_chance": {"min": 0.0, "max": 1.0},
	"dodge_chance": {"min": 0.0, "max": 0.75},      # Máximo 75%
	"life_steal": {"min": 0.0, "max": 0.5},          # Máximo 50%
	"freeze_chance": {"min": 0.0, "max": 0.5},       # Máximo 50%
	"bleed_chance": {"min": 0.0, "max": 0.5},        # Máximo 50%
	"explosion_chance": {"min": 0.0, "max": 0.5},    # Máximo 50%
	"execute_threshold": {"min": 0.0, "max": 0.15},  # Máximo 15% HP
	"overkill_damage": {"min": 0.0, "max": 1.0},     # Máximo 100%
	"thorns_percent": {"min": 0.0, "max": 2.0},      # Máximo 200%
	"curse": {"min": 0.0, "max": 2.0},               # Máximo 200%
	"growth": {"min": 0.0, "max": 1.0},              # Máximo 100%
	
	# Valores planos con límite
	"extra_projectiles": {"min": 0, "max": 10},
	"extra_pierce": {"min": 0, "max": 20},
	"chain_count": {"min": 0, "max": 10},
	"revives": {"min": 0, "max": 3},
	"levelup_options": {"min": 0, "max": 3},
	"reroll_count": {"min": 0, "max": 5},
	"banish_count": {"min": 0, "max": 5},
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Stats actuales
var stats: Dictionary = {}

# Modificadores temporales (por buffs/debuffs)
var temp_modifiers: Dictionary = {}  # stat_name -> [{amount, duration, source}]

# Historial de mejoras aplicadas (para mostrar en pausa)
var collected_upgrades: Array = []  # [{id, name, icon, description, effects}]

# IDs de mejoras ÚNICAS obtenidas (para evitar duplicados)
var owned_unique_ids: Array = []  # ["phoenix_heart", "critical_mastery", ...]

# Vida actual
var current_health: float = 100.0

# Acumulador de regeneración para aplicar HP enteros
var _regen_accumulator: float = 0.0

# Acumulador de regeneración de escudo
var _shield_regen_accumulator: float = 0.0

# Sistema de Growth - tiempo acumulado en minutos
var _game_time_minutes: float = 0.0
var _last_growth_minute: int = 0

# Sistema de nivel
var level: int = 1
var current_xp: float = 0.0
var xp_to_next_level: float = BASE_XP_TO_LEVEL

# Referencia al AttackManager para sincronizar stats
var attack_manager: AttackManager = null

# Referencia al player para sincronizar vida
var player_ref: Node = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	_reset_stats()

func _reset_stats() -> void:
	"""Resetear a stats base"""
	stats = BASE_STATS.duplicate()
	temp_modifiers.clear()
	collected_upgrades.clear()
	owned_unique_ids.clear()
	current_health = stats.max_health
	level = 1
	current_xp = 0.0
	xp_to_next_level = BASE_XP_TO_LEVEL
	_regen_accumulator = 0.0
	_shield_regen_accumulator = 0.0
	_game_time_minutes = 0.0
	_last_growth_minute = 0

func _ready() -> void:
	# Asegurar que PlayerStats respete la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE

func initialize(attack_mgr: AttackManager = null, player: Node = null) -> void:
	"""Inicializar con referencia al AttackManager y al player"""
	attack_manager = attack_mgr
	player_ref = player
	# Agregar a grupo para facilitar busqueda desde PauseMenu
	add_to_group("player_stats")
	_sync_with_attack_manager()
	
	# Conectar a la señal de salud del player para mantener sincronizado
	_connect_to_player_health()
	
	# print("[PlayerStats] Inicializado - Nivel %d, Player: %s" % [level, player_ref != null])

func _connect_to_player_health() -> void:
	"""Conectar a la señal de salud del player para sincronizar current_health"""
	if not player_ref:
		return
	
	var hc = _get_health_component()
	if hc and hc.has_signal("health_changed"):
		if not hc.health_changed.is_connected(_on_player_health_changed):
			hc.health_changed.connect(_on_player_health_changed)
			# Sincronizar HP inicial
			if "current_health" in hc:
				current_health = hc.current_health
			# print("[PlayerStats] Conectado a HealthComponent del player")

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	"""Callback cuando la salud del player cambia - mantener sincronizado"""
	current_health = new_health
	# Emitir nuestra propia señal para que otros sistemas se enteren
	health_changed.emit(new_health, max_health)

func _sync_with_attack_manager() -> void:
	"""
	Sincronizar stats relevantes con AttackManager.
	
	NOTA (v2.0): Los stats de armas (damage_mult, cooldown_mult, area_mult, etc.)
	ahora se manejan directamente en GlobalWeaponStats dentro de AttackManager.
	Solo sincronizamos stats que son tanto del jugador como de las armas.
	
	Para mejoras de armas, usar:
	- attack_manager.apply_global_upgrade() para mejoras globales
	- attack_manager.apply_weapon_upgrade() para mejoras específicas
	"""
	if attack_manager == null:
		return

	# Solo sincronizar stats que pertenecen a AMBOS sistemas
	# life_steal afecta tanto la supervivencia del jugador como el combate
	attack_manager.set_player_stat("life_steal", get_stat("life_steal"))
	
	# DEPRECADO: Estos stats ahora viven en GlobalWeaponStats
	# Las mejoras genéricas del LevelUpPanel deben llamar a 
	# attack_manager.apply_global_upgrade() directamente
	#
	# Por compatibilidad temporal, seguimos sincronizando:
	if stats.has("damage_mult"):
		attack_manager.set_player_stat("damage_mult", get_stat("damage_mult"))
	if stats.has("cooldown_mult"):
		attack_manager.set_player_stat("cooldown_mult", get_stat("cooldown_mult"))
	if stats.has("crit_chance"):
		attack_manager.set_player_stat("crit_chance", get_stat("crit_chance"))
	if stats.has("crit_damage"):
		attack_manager.set_player_stat("crit_damage", get_stat("crit_damage"))
	if stats.has("area_mult"):
		attack_manager.set_player_stat("area_mult", get_stat("area_mult"))
	if stats.has("projectile_speed_mult"):
		attack_manager.set_player_stat("projectile_speed_mult", get_stat("projectile_speed_mult"))
	if stats.has("duration_mult"):
		attack_manager.set_player_stat("duration_mult", get_stat("duration_mult"))
	if stats.has("extra_projectiles"):
		attack_manager.set_player_stat("extra_projectiles", get_stat("extra_projectiles"))
	if stats.has("knockback_mult"):
		attack_manager.set_player_stat("knockback_mult", get_stat("knockback_mult"))

# ═══════════════════════════════════════════════════════════════════════════════
# MÉTODOS DE METADATOS (PARA UI)
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat_metadata(stat_name: String) -> Dictionary:
	"""Obtener metadatos de un stat para mostrar en UI"""
	return STAT_METADATA.get(stat_name, {
		"name": stat_name,
		"icon": "❓",
		"category": "other",
		"description": "Sin descripción.",
		"format": "flat",
		"color": Color.WHITE
	})

func get_stats_by_category(category: String) -> Array:
	"""Obtener lista de stats de una categoría específica"""
	var result = []
	for stat_name in STAT_METADATA:
		if STAT_METADATA[stat_name].get("category") == category:
			result.append(stat_name)
	return result

func get_all_categories() -> Array:
	"""Obtener todas las categorías de stats"""
	return ["defensive", "offensive", "critical", "utility"]

func format_stat_value(stat_name: String, value: float) -> String:
	"""Formatear el valor de un stat para mostrar en UI"""
	var meta = get_stat_metadata(stat_name)
	var format_type = meta.get("format", "flat")

	match format_type:
		"percent":
			return "%.0f%%" % (value * 100)
		"multiplier":
			if value >= 1.0:
				return "+%.0f%%" % ((value - 1.0) * 100)
			else:
				return "%.0f%%" % ((value - 1.0) * 100)
		"multiplier_inverse":
			# Para cooldown, menos es mejor
			if value <= 1.0:
				return "-%.0f%%" % ((1.0 - value) * 100)
			else:
				return "+%.0f%%" % ((value - 1.0) * 100)
		"per_second":
			return "%.1f/s" % value
		_:  # flat
			if value == int(value):
				return "%d" % int(value)
			else:
				return "%.1f" % value

# ═══════════════════════════════════════════════════════════════════════════════
# GETTERS DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat(stat_name: String) -> float:
	"""Obtener valor actual de un stat (base + modificadores temporales)"""
	var base_value = stats.get(stat_name, 0.0)
	var temp_bonus = _get_temp_modifier_total(stat_name)
	var final_value = base_value + temp_bonus

	# Aplicar límites si existen
	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		final_value = clampf(final_value, limits.min, limits.max)

	return final_value

func get_base_stat(stat_name: String) -> float:
	"""Obtener valor base sin modificadores temporales"""
	return stats.get(stat_name, 0.0)

func _get_temp_modifier_total(stat_name: String) -> float:
	"""Obtener suma de modificadores temporales"""
	if not temp_modifiers.has(stat_name):
		return 0.0

	var total = 0.0
	for mod in temp_modifiers[stat_name]:
		total += mod.amount
	return total

# ═══════════════════════════════════════════════════════════════════════════════
# MODIFICACIÓN DE STATS (PERMANENTES)
# ═══════════════════════════════════════════════════════════════════════════════

func add_stat(stat_name: String, amount: float) -> void:
	"""Añadir valor a un stat (permanente)"""
	if not stats.has(stat_name):
		stats[stat_name] = 0.0

	var old_value = stats[stat_name]
	stats[stat_name] += amount

	# Aplicar límites
	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		stats[stat_name] = clampf(stats[stat_name], limits.min, limits.max)

	var new_value = stats[stat_name]

	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)
		_on_stat_changed(stat_name, old_value, new_value)

	# print("[PlayerStats] %s: %.2f → %.2f (+%.2f)" % [stat_name, old_value, new_value, amount])

func set_stat(stat_name: String, value: float) -> void:
	"""Establecer valor exacto de un stat"""
	var old_value = stats.get(stat_name, 0.0)
	stats[stat_name] = value

	# Aplicar límites
	if STAT_LIMITS.has(stat_name):
		var limits = STAT_LIMITS[stat_name]
		stats[stat_name] = clampf(stats[stat_name], limits.min, limits.max)

	var new_value = stats[stat_name]

	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)
		_on_stat_changed(stat_name, old_value, new_value)

func multiply_stat(stat_name: String, multiplier: float) -> void:
	"""Multiplicar un stat por un valor"""
	if not stats.has(stat_name):
		return
	add_stat(stat_name, stats[stat_name] * (multiplier - 1.0))

func _on_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
	"""Manejar cambios especiales de stats"""
	match stat_name:
		"max_health":
			# Ajustar salud actual proporcionalmente
			var ratio = current_health / old_value if old_value > 0 else 1.0
			current_health = new_value * ratio
			health_changed.emit(current_health, new_value)

		"damage_mult", "cooldown_mult", "crit_chance", "area_mult":
			# Sincronizar con AttackManager
			_sync_with_attack_manager()

# ═══════════════════════════════════════════════════════════════════════════════
# MODIFICADORES TEMPORALES (BUFFS/DEBUFFS)
# ═══════════════════════════════════════════════════════════════════════════════

func add_temp_modifier(stat_name: String, amount: float, duration: float, source: String = "") -> void:
	"""Añadir modificador temporal"""
	if not temp_modifiers.has(stat_name):
		temp_modifiers[stat_name] = []

	temp_modifiers[stat_name].append({
		"amount": amount,
		"duration": duration,
		"source": source,
		"time_added": Time.get_ticks_msec() / 1000.0
	})

	# print("[PlayerStats] Buff temporal: %s +%.2f por %.1fs (%s)" % [
	#	stat_name, amount, duration, source
	# ])

func remove_temp_modifiers_by_source(source: String) -> void:
	"""Remover todos los modificadores de una fuente específica"""
	for stat_name in temp_modifiers:
		temp_modifiers[stat_name] = temp_modifiers[stat_name].filter(
			func(mod): return mod.source != source
		)

func _process(delta: float) -> void:
	"""Actualizar modificadores temporales, regeneración, growth y shield"""
	_update_temp_modifiers(delta)
	_update_health_regen(delta)
	_update_shield_regen(delta)
	_update_growth(delta)

func _update_temp_modifiers(delta: float) -> void:
	"""Reducir duración de modificadores temporales"""
	for stat_name in temp_modifiers.keys():
		var mods = temp_modifiers[stat_name]
		var to_remove = []

		for i in range(mods.size()):
			mods[i].duration -= delta
			if mods[i].duration <= 0:
				to_remove.append(i)

		# Remover expirados (en orden inverso)
		for i in range(to_remove.size() - 1, -1, -1):
			mods.remove_at(to_remove[i])

		# Limpiar array vacío
		if mods.is_empty():
			temp_modifiers.erase(stat_name)

func _update_health_regen(delta: float) -> void:
	"""Aplicar regeneración de vida al player real - acumula hasta 1 HP entero"""
	var regen = get_stat("health_regen")
	if regen <= 0:
		return
	
	# Acumular regeneración parcial
	_regen_accumulator += regen * delta
	
	# Solo curar cuando tengamos al menos 1 HP completo
	if _regen_accumulator < 1.0:
		return
	
	var heal_int = int(_regen_accumulator)
	_regen_accumulator -= heal_int  # Guardar el residuo para el siguiente tick
	
	# Si tenemos referencia al player, curar directamente
	if player_ref and player_ref.has_method("heal"):
		# IMPORTANTE: Verificar que el jugador esté vivo antes de regenerar
		var is_alive = true
		if player_ref.has_method("is_alive"):
			is_alive = player_ref.is_alive()
		elif "is_alive" in player_ref:
			is_alive = player_ref.is_alive
		elif player_ref.has_method("get_health_component"):
			var hc = player_ref.get_health_component()
			if hc and "is_alive" in hc:
				is_alive = hc.is_alive
		
		if not is_alive:
			_regen_accumulator = 0.0  # Reset al morir
			return  # No regenerar si el jugador está muerto
		
		var player_hp = _get_player_current_health()
		var max_hp = get_stat("max_health")
		if player_hp < max_hp and player_hp > 0:
			player_ref.heal(heal_int)
	else:
		pass  # Bloque else
		# Fallback: curar el current_health local (para compatibilidad)
		if current_health < get_stat("max_health") and current_health > 0:
			heal(float(heal_int))

func _get_player_current_health() -> float:
	"""Obtener HP actual del player real"""
	if player_ref == null:
		return current_health
	
	# Intentar obtener del wizard_player interno
	var wizard = player_ref.get_node_or_null("WizardPlayer")
	if wizard and wizard.has_node("HealthComponent"):
		var hc = wizard.get_node("HealthComponent")
		return hc.current_health
	
	# Fallback directo
	if player_ref.has_method("get_health_component"):
		var hc = player_ref.get_health_component()
		if hc:
			return hc.current_health
	
	return current_health

func _update_shield_regen(delta: float) -> void:
	"""Regenerar escudo con el tiempo"""
	var shield_regen = get_stat("shield_regen")
	if shield_regen <= 0:
		return
	
	# No regenerar escudo si no tiene max_shield definido o está lleno
	var current_shield = get_stat("shield_amount")
	var max_shield = get_base_stat("shield_amount")  # El máximo es el valor base + mejoras
	
	# Si no hay escudo definido, no regenerar
	if max_shield <= 0:
		return
	
	# Acumular regeneración parcial
	_shield_regen_accumulator += shield_regen * delta
	
	# Solo regenerar cuando tengamos al menos 1 punto de escudo
	if _shield_regen_accumulator < 1.0:
		return
	
	var regen_int = int(_shield_regen_accumulator)
	_shield_regen_accumulator -= regen_int
	
	# No exceder el máximo de escudo
	var new_shield = mini(int(current_shield) + regen_int, int(max_shield))
	if new_shield > current_shield:
		set_stat("shield_amount", new_shield)

func _update_growth(delta: float) -> void:
	"""Aplicar bonus de Growth por minuto de juego"""
	var growth_rate = get_stat("growth")
	if growth_rate <= 0:
		return
	
	# Actualizar tiempo de juego
	_game_time_minutes += delta / 60.0
	
	# Cada minuto completo, aplicar bonus de growth
	var current_minute = int(_game_time_minutes)
	if current_minute > _last_growth_minute:
		_apply_growth_bonus(growth_rate, current_minute - _last_growth_minute)
		_last_growth_minute = current_minute

func _apply_growth_bonus(growth_rate: float, minutes: int) -> void:
	"""Aplicar bonus de growth a todos los stats relevantes"""
	# Stats que escalan con growth (no aplicar a stats negativos como damage_taken_mult)
	var growth_stats = [
		"max_health", "damage_mult", "attack_speed_mult", "area_mult",
		"projectile_speed_mult", "duration_mult", "crit_chance", "crit_damage",
		"health_regen", "armor", "pickup_range", "move_speed", "xp_mult"
	]
	
	# Calcular multiplicador acumulativo
	var multiplier = 1.0 + (growth_rate * minutes)
	
	for stat_name in growth_stats:
		var base_value = get_base_stat(stat_name)
		if base_value > 0:
			# Solo aplicar a stats positivos
			var bonus = base_value * (multiplier - 1.0) * 0.01  # 1% por growth por minuto
			add_temp_modifier(stat_name, bonus, 9999.0, "growth_bonus")
	
	# Mostrar notificación visual si tenemos player
	if player_ref and is_instance_valid(player_ref):
		if "global_position" in player_ref:
			FloatingText.spawn_text(
				player_ref.global_position + Vector2(0, -60),
				"📈 GROWTH +%d%%" % int(growth_rate * 100 * _game_time_minutes),
				Color(0.3, 1.0, 0.5)
			)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE VIDA
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage(amount: float) -> float:
	"""
	Recibir daño (aplicando dodge y armor)
	Retorna: daño efectivo recibido (0 si esquivó)
	"""
	# Verificar esquiva primero
	var dodge = get_stat("dodge_chance")
	if dodge > 0 and randf() < minf(dodge, 0.6):  # Máximo 60% de esquiva
		# print("[PlayerStats] ¡ESQUIVADO! (%.0f%% chance)" % (dodge * 100))
		# Emitir señal de esquiva (la UI puede mostrar "DODGE!")
		return 0.0
	
	var armor = get_stat("armor")
	var effective_damage = maxf(1.0, amount - armor)  # Mínimo 1 de daño

	current_health -= effective_damage
	current_health = maxf(0.0, current_health)

	health_changed.emit(current_health, get_stat("max_health"))

	return effective_damage

func heal(amount: float) -> float:
	"""
	Curar vida
	Retorna: cantidad efectiva curada
	"""
	var max_hp = get_stat("max_health")
	var old_health = current_health

	current_health = minf(current_health + amount, max_hp)
	var healed = current_health - old_health

	if healed > 0:
		health_changed.emit(current_health, max_hp)

	return healed

func is_dead() -> bool:
	"""Verificar si el jugador está muerto - usa HealthComponent como fuente de verdad"""
	# Primero intentar obtener del HealthComponent real
	if player_ref:
		var hc = _get_health_component()
		if hc and "is_alive" in hc:
			return not hc.is_alive
	# Fallback a variable local
	return current_health <= 0

func _get_health_component() -> Node:
	"""Obtener el HealthComponent del player real"""
	if not player_ref:
		return null
	
	# Buscar en el wizard_player interno
	var wizard = player_ref.get_node_or_null("WizardPlayer")
	if wizard and wizard.has_node("HealthComponent"):
		return wizard.get_node("HealthComponent")
	
	# Buscar directamente en player_ref
	if player_ref.has_node("HealthComponent"):
		return player_ref.get_node("HealthComponent")
	
	# Buscar con método
	if player_ref.has_method("get_health_component"):
		return player_ref.get_health_component()
	
	return null

func get_health_percent() -> float:
	"""Obtener porcentaje de vida - usa HealthComponent como fuente de verdad"""
	var max_hp = get_stat("max_health")
	if max_hp <= 0:
		return 0.0
	
	# Intentar obtener HP actual del HealthComponent real
	var current_hp = current_health
	if player_ref:
		var hc = _get_health_component()
		if hc and "current_health" in hc:
			current_hp = hc.current_health
	
	return current_hp / max_hp

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE NIVELES
# ═══════════════════════════════════════════════════════════════════════════════

func gain_xp(amount: float) -> int:
	"""
	Ganar experiencia
	Retorna: número de niveles subidos
	"""
	var xp_bonus = get_stat("xp_mult")
	var effective_xp = amount * xp_bonus

	current_xp += effective_xp
	xp_gained.emit(effective_xp, current_xp)

	var levels_gained = 0

	# Subir niveles mientras haya suficiente XP
	while current_xp >= xp_to_next_level and level < MAX_LEVEL:
		current_xp -= xp_to_next_level
		level += 1
		levels_gained += 1

		# Calcular XP para siguiente nivel
		xp_to_next_level = BASE_XP_TO_LEVEL * pow(XP_SCALING, level - 1)

		# print("[PlayerStats] ⬆️ ¡Nivel %d alcanzado!" % level)
		level_changed.emit(level)

	return levels_gained

func get_xp_progress() -> float:
	"""Obtener progreso hacia el siguiente nivel (0.0 - 1.0)"""
	return current_xp / xp_to_next_level

# ═══════════════════════════════════════════════════════════════════════════════
# UPGRADES DISPONIBLES (para Level Up Panel)
# ═══════════════════════════════════════════════════════════════════════════════

# Definición de upgrades disponibles para el jugador
const PLAYER_UPGRADES: Dictionary = {
	"max_health_small": {
		"name": "Vitalidad I",
		"description": "+10 Vida máxima",
		"stat": "max_health",
		"amount": 10.0,
		"icon": "❤️",
		"rarity": "common"
	},
	"max_health_large": {
		"name": "Vitalidad II",
		"description": "+25 Vida máxima",
		"stat": "max_health",
		"amount": 25.0,
		"icon": "❤️",
		"rarity": "uncommon"
	},
	"health_regen": {
		"name": "Regeneración",
		"description": "+0.5 HP/s",
		"stat": "health_regen",
		"amount": 0.5,
		"icon": "💚",
		"rarity": "uncommon"
	},
	"damage_small": {
		"name": "Poder I",
		"description": "+10% Daño",
		"stat": "damage_mult",
		"amount": 0.10,
		"icon": "⚔️",
		"rarity": "common"
	},
	"damage_large": {
		"name": "Poder II",
		"description": "+20% Daño",
		"stat": "damage_mult",
		"amount": 0.20,
		"icon": "⚔️",
		"rarity": "uncommon"
	},
	"cooldown": {
		"name": "Celeridad",
		"description": "-10% Cooldown de armas",
		"stat": "cooldown_mult",
		"amount": -0.10,
		"icon": "⏱️",
		"rarity": "uncommon"
	},
	"crit_chance": {
		"name": "Precisión",
		"description": "+5% Probabilidad de crítico",
		"stat": "crit_chance",
		"amount": 0.05,
		"icon": "🎯",
		"rarity": "uncommon"
	},
	"crit_damage": {
		"name": "Devastación",
		"description": "+25% Daño crítico",
		"stat": "crit_damage",
		"amount": 0.25,
		"icon": "💥",
		"rarity": "rare"
	},
	"area": {
		"name": "Expansión",
		"description": "+15% Área de efecto",
		"stat": "area_mult",
		"amount": 0.15,
		"icon": "🔵",
		"rarity": "uncommon"
	},
	"move_speed": {
		"name": "Velocidad",
		"description": "+10% Velocidad de movimiento",
		"stat": "move_speed",
		"amount": 0.10,
		"icon": "👟",
		"rarity": "common"
	},
	"pickup_range": {
		"name": "Magnetismo",
		"description": "+25% Rango de recolección",
		"stat": "pickup_range",
		"amount": 0.25,
		"icon": "🧲",
		"rarity": "common"
	},
	"xp_mult": {
		"name": "Sabiduría",
		"description": "+15% Experiencia ganada",
		"stat": "xp_mult",
		"amount": 0.15,
		"icon": "📚",
		"rarity": "uncommon"
	},
	"armor": {
		"name": "Armadura",
		"description": "+3 Reducción de daño",
		"stat": "armor",
		"amount": 3.0,
		"icon": "🛡️",
		"rarity": "uncommon"
	},
	"luck": {
		"name": "Fortuna",
		"description": "+10% Suerte",
		"stat": "luck",
		"amount": 0.10,
		"icon": "🍀",
		"rarity": "rare"
	},
	# === NUEVOS STATS ===
	"dodge_small": {
		"name": "Evasión I",
		"description": "+5% Esquivar ataques",
		"stat": "dodge_chance",
		"amount": 0.05,
		"icon": "💨",
		"rarity": "uncommon"
	},
	"dodge_large": {
		"name": "Evasión II",
		"description": "+10% Esquivar ataques",
		"stat": "dodge_chance",
		"amount": 0.10,
		"icon": "💨",
		"rarity": "rare"
	},
	"life_steal_small": {
		"name": "Vampirismo I",
		"description": "+3% Robo de vida",
		"stat": "life_steal",
		"amount": 0.03,
		"icon": "🩸",
		"rarity": "uncommon"
	},
	"life_steal_large": {
		"name": "Vampirismo II",
		"description": "+7% Robo de vida",
		"stat": "life_steal",
		"amount": 0.07,
		"icon": "🩸",
		"rarity": "rare"
	},
	"projectile_speed": {
		"name": "Velocidad Proyectil",
		"description": "+15% Vel. proyectiles",
		"stat": "projectile_speed_mult",
		"amount": 0.15,
		"icon": "➡️",
		"rarity": "common"
	},
	"duration": {
		"name": "Persistencia",
		"description": "+15% Duración efectos",
		"stat": "duration_mult",
		"amount": 0.15,
		"icon": "⌛",
		"rarity": "common"
	},
	"extra_projectile": {
		"name": "Proyectil Extra",
		"description": "+1 Proyectil adicional",
		"stat": "extra_projectiles",
		"amount": 1,
		"icon": "🎯",
		"rarity": "rare"
	},
	"knockback": {
		"name": "Empuje",
		"description": "+25% Fuerza de empuje",
		"stat": "knockback_mult",
		"amount": 0.25,
		"icon": "💥",
		"rarity": "common"
	}
}

func get_random_upgrades(count: int = 3, luck_bonus: float = 0.0) -> Array:
	"""
	Obtener upgrades aleatorios para el panel de level up
	luck_bonus aumenta probabilidad de upgrades raros
	"""
	var upgrades_list = PLAYER_UPGRADES.keys()
	upgrades_list.shuffle()

	var selected = []
	var actual_luck = get_stat("luck") + luck_bonus

	for upgrade_id in upgrades_list:
		if selected.size() >= count:
			break

		var upgrade = PLAYER_UPGRADES[upgrade_id].duplicate()
		upgrade["id"] = upgrade_id

		# Filtrar por rareza según luck
		var rarity_roll = randf()
		match upgrade.rarity:
			"common":
				selected.append(upgrade)
			"uncommon":
				if rarity_roll < 0.5 + actual_luck * 0.3:
					selected.append(upgrade)
			"rare":
				if rarity_roll < 0.2 + actual_luck * 0.4:
					selected.append(upgrade)

	# Si no hay suficientes, llenar con comunes
	while selected.size() < count:
		for upgrade_id in upgrades_list:
			var upgrade = PLAYER_UPGRADES[upgrade_id]
			if upgrade.rarity == "common":
				var dup = upgrade.duplicate()
				dup["id"] = upgrade_id
				if dup not in selected:
					selected.append(dup)
					break

		# Prevenir loop infinito
		if selected.size() < count:
			break

	return selected.slice(0, count)

func apply_upgrade(upgrade_data) -> bool:
	"""Aplicar un upgrade del jugador. Acepta String (ID) o Dictionary (datos completos)"""
	var upgrade_id: String = ""
	var upgrade_dict: Dictionary = {}

	# Determinar si es un ID o un Dictionary completo
	if upgrade_data is String:
		upgrade_id = upgrade_data
	elif upgrade_data is Dictionary:
		upgrade_id = upgrade_data.get("upgrade_id", upgrade_data.get("id", ""))
		upgrade_dict = upgrade_data
	else:
		push_error("[PlayerStats] apply_upgrade: tipo invalido %s" % typeof(upgrade_data))
		return false

	# Si tenemos un ID valido, buscar en PLAYER_UPGRADES
	if upgrade_id != "" and PLAYER_UPGRADES.has(upgrade_id):
		var upgrade = PLAYER_UPGRADES[upgrade_id]
		add_stat(upgrade.stat, upgrade.amount)

		# Registrar la mejora en el historial
		add_upgrade({
			"id": upgrade_id,
			"name": upgrade.name,
			"icon": upgrade.get("icon", ""),
			"description": upgrade.description,
			"effects": [{"stat": upgrade.stat, "value": upgrade.amount, "operation": "add"}]
		})

		# print("[PlayerStats] Upgrade aplicado (por ID): %s" % upgrade.name)
		return true

	# Fallback: aplicar efectos directamente desde el Dictionary
	if upgrade_dict.has("effects"):
		for effect in upgrade_dict.effects:
			var stat = effect.get("stat", "")
			var value = effect.get("value", 0)
			var op = effect.get("operation", "add")
			if stat != "":
				match op:
					"add": add_stat(stat, value)
					"multiply": multiply_stat(stat, value)
					"set": set_stat(stat, value)
					_: add_stat(stat, value)

		add_upgrade(upgrade_dict)
		# print("[PlayerStats] Upgrade aplicado (por efectos): %s" % upgrade_dict.get("name", "???"))
		return true

	# Fallback: stat y amount directamente
	if upgrade_dict.has("stat") and upgrade_dict.has("amount"):
		add_stat(upgrade_dict.stat, upgrade_dict.amount)
		add_upgrade(upgrade_dict)
		# print("[PlayerStats] Upgrade aplicado (stat+amount): %s" % upgrade_dict.get("name", "???"))
		return true

	push_warning("[PlayerStats] No se pudo aplicar upgrade: %s" % str(upgrade_data))
	return false

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar para guardado"""
	return {
		"stats": stats.duplicate(),
		"current_health": current_health,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level,
		"collected_upgrades": collected_upgrades.duplicate(true)  # Historial de mejoras para pestaña Objetos
	}

func from_dict(data: Dictionary) -> void:
	"""Restaurar desde datos guardados"""
	if data.has("stats"):
		stats = data.stats.duplicate()
	if data.has("current_health"):
		current_health = data.current_health
	if data.has("level"):
		level = data.level
	if data.has("current_xp"):
		current_xp = data.current_xp
	if data.has("xp_to_next_level"):
		xp_to_next_level = data.xp_to_next_level
	if data.has("collected_upgrades"):
		collected_upgrades = data.collected_upgrades.duplicate(true)

	_sync_with_attack_manager()

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	var lines = [
		"=== PLAYER STATS ===",
		"Nivel: %d (XP: %.0f/%.0f)" % [level, current_xp, xp_to_next_level],
		"Vida: %.0f/%.0f (%.0f%%)" % [current_health, get_stat("max_health"), get_health_percent() * 100],
		"",
		"Stats:"
	]

	for stat_name in stats:
		var base = stats[stat_name]
		var final = get_stat(stat_name)
		var temp = _get_temp_modifier_total(stat_name)

		if temp != 0:
			lines.append("  %s: %.2f (base: %.2f, temp: %+.2f)" % [stat_name, final, base, temp])
		else:
			lines.append("  %s: %.2f" % [stat_name, final])

	if not temp_modifiers.is_empty():
		lines.append("")
		lines.append("Buffs activos:")
		for stat_name in temp_modifiers:
			for mod in temp_modifiers[stat_name]:
				lines.append("  %s: %+.2f (%.1fs restantes) [%s]" % [
					stat_name, mod.amount, mod.duration, mod.source
				])

	return "\n".join(lines)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE MEJORAS
# ═══════════════════════════════════════════════════════════════════════════════

func add_upgrade(upgrade_data: Dictionary) -> void:
	"""Registrar una mejora aplicada"""
	collected_upgrades.append({
		"id": upgrade_data.get("upgrade_id", upgrade_data.get("id", "")),
		"name": upgrade_data.get("name", "???"),
		"icon": upgrade_data.get("icon", "✨"),
		"description": upgrade_data.get("description", ""),
		"effects": upgrade_data.get("effects", [])
	})
	# print("[PlayerStats] Mejora añadida: %s" % upgrade_data.get("name", "???"))

func get_collected_upgrades() -> Array:
	"""Obtener lista de mejoras recolectadas"""
	return collected_upgrades.duplicate()

func register_unique_upgrade(upgrade_id: String) -> void:
	"""Registrar una mejora única como obtenida (para evitar duplicados)"""
	if upgrade_id.is_empty():
		return
	if upgrade_id not in owned_unique_ids:
		owned_unique_ids.append(upgrade_id)
		# print("[PlayerStats] 🔴 Mejora única registrada: %s" % upgrade_id)

func get_owned_unique_ids() -> Array:
	"""Obtener IDs de mejoras únicas obtenidas"""
	return owned_unique_ids.duplicate()

func has_unique_upgrade(upgrade_id: String) -> bool:
	"""Verificar si ya tiene una mejora única"""
	return upgrade_id in owned_unique_ids

func modify_stat(stat_name: String, value: float, operation: String = "add") -> void:
	"""Modificar un stat con operación específica"""
	match operation:
		"add":
			add_stat(stat_name, value)
		"multiply":
			multiply_stat(stat_name, value)
		"set":
			set_stat(stat_name, value)
		_:
			add_stat(stat_name, value)
