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
	if BOSS_LOOT_TABLE.has(boss_id):
		return BOSS_LOOT_TABLE[boss_id]
	return BOSS_LOOT_TABLE["default"]
