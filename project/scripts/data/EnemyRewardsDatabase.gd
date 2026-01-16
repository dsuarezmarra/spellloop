class_name EnemyRewardsDatabase
extends Node

# Configuración centralizada de recompensas por tipo de enemigo

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE DROPS
# ═══════════════════════════════════════════════════════════════════════════════

const RARE_REWARDS = {
	"guaranteed_coins": {"min": 8, "max": 15, "type": "silver"},
	"chest_chance": 0.10,          # 10% probabilidad de cofre
	"chest_type": "normal",
	"upgrade_chance": 0.05,        # 5% de soltar orbe de mejora directa
	"xp_multiplier": 5.0           # XP base x5
}

const ELITE_REWARDS = {
	"guaranteed_coins": {"min": 25, "max": 50, "type": "gold"},
	"chest_chance": 0.40,          # 40% probabilidad de cofre
	"chest_type": "elite",
	"chest_rarity_boost": 1,       # +1 rareza mínima (ej: Blue garantizado)
	"upgrade_chance": 0.20,        # 20% orbe de mejora
	"xp_multiplier": 20.0          # XP base x20
}

const BOSS_REWARDS = {
	"guaranteed_coins": {"min": 100, "max": 200, "type": "purple"},
	"guaranteed_chest": true,      # 100% cofre
	"chest_type": "boss",
	"chest_rarity_min": 3,         # Mínimo Legendario (Orange)
	"relic_chance": 1.0,           # Garantiza reliquia/item especial si existen
	"xp_multiplier": 100.0,        # Gran cantidad de XP
	"clear_screen": true           # Limpia enemigos cercanos al morir
}

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE UTILIDAD
# ═══════════════════════════════════════════════════════════════════════════════

static func get_rewards_for_enemy(enemy_data: Dictionary) -> Dictionary:
	"""Determina las recompensas basadas en los datos del enemigo"""
	
	# Verificar flags en enemy_data
	# Nota: EnemyDatabase usa 'tier' para bosses (5) y flags para elites
	
	var tier = enemy_data.get("tier", 1)
	var is_boss = tier >= 5 or enemy_data.get("is_boss", false)
	# Suponemos que el sistema de spawneo marca elites con 'is_elite' o checking modifiers
	var is_elite = enemy_data.get("is_elite", false) 
	var is_rare = enemy_data.get("is_rare", false) # Quizás definido por probabilidad baja
	
	if is_boss:
		return BOSS_REWARDS
	elif is_elite:
		return ELITE_REWARDS
	elif is_rare:
		return RARE_REWARDS
	
	# Enemigos normales: RNG básico muy bajo
	return {
		"coin_chance": 0.05, # 5% de soltar moneda básica
		"chest_chance": 0.001 # 0.1% muy raro
	}
