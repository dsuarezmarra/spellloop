class_name BossDatabase
extends Node

# Base de datos específica para recompensas de Jefes
# Contiene tablas de loot para cofres de jefe

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const BOSS_LOOT_TABLE = {
	"boss_1": {
		"guaranteed": ["gold_large"],
		"chance_for_extra": 0.5,
		"pool": ["weapon_upgrade", "stat_upgrade_tier_3", "stat_upgrade_tier_4"]
	},
	"default": {
		"guaranteed": ["gold_large", "stat_upgrade_tier_3"],
		"chance_for_extra": 0.3,
		"pool": ["weapon_upgrade", "stat_upgrade_tier_4", "unique_upgrade"]
	}
}

static func get_boss_loot(boss_id: String) -> Dictionary:
	"""Devuelve la configuración de loot para un jefe específico"""
	var base_loot = {}
	if BOSS_LOOT_TABLE.has(boss_id):
		base_loot = BOSS_LOOT_TABLE[boss_id].duplicate()
	else:
		base_loot = BOSS_LOOT_TABLE["default"].duplicate()
	
	# FIX: Asegurar que los bosses siempre sueltan cofre.
	# Antes, solo EnemyManager spawneaba cofres de boss (eliminado por causar duplicados).
	# Ahora Game._on_enemy_died es el único punto de spawn, necesita estos campos.
	if not base_loot.has("guaranteed_chest"):
		base_loot["guaranteed_chest"] = true
	if not base_loot.has("chest_type"):
		base_loot["chest_type"] = "boss"
	return base_loot
