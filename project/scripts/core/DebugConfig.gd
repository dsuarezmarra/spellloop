# DebugConfig.gd
# Configuración centralizada de debug para el juego
# Usar estas constantes para activar/desactivar logs por sistema

extends RefCounted
class_name DebugConfig

# ═══════════════════════════════════════════════════════════════════════════════
# FLAGS GENERALES
# ═══════════════════════════════════════════════════════════════════════════════

## Activar todos los logs de debug (para desarrollo)
const DEBUG_ALL: bool = false

## Mostrar logs solo en builds de debug (usar OS.is_debug_build() en runtime)
const DEBUG_ONLY_IN_EDITOR: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
# FLAGS POR SISTEMA
# ═══════════════════════════════════════════════════════════════════════════════

## Sistema de combate y armas
const DEBUG_WEAPONS: bool = false
const DEBUG_PROJECTILES: bool = false
const DEBUG_AOE: bool = false

## Sistema de enemigos
const DEBUG_ENEMIES: bool = false
const DEBUG_ENEMY_SPAWNS: bool = false
const DEBUG_ENEMY_AI: bool = false

## Sistema de jugador
const DEBUG_PLAYER: bool = false
const DEBUG_PLAYER_STATS: bool = false
const DEBUG_PLAYER_DAMAGE: bool = true  # Mantener para debug de daño

## Sistema de UI
const DEBUG_UI: bool = false
const DEBUG_LEVEL_UP: bool = false

## Sistema de experiencia y monedas
const DEBUG_EXPERIENCE: bool = false
const DEBUG_COINS: bool = false

## Sistema de guardado
const DEBUG_SAVE: bool = false

## Sistema de audio
const DEBUG_AUDIO: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func should_log(flag: bool) -> bool:
	"""Verificar si se debería mostrar un log basado en el flag y configuración"""
	if DEBUG_ALL:
		return true
	if DEBUG_ONLY_IN_EDITOR and not OS.is_debug_build():
		return false
	return flag

static func log_weapon(message: String) -> void:
	if should_log(DEBUG_WEAPONS):
		print("[Weapon] " + message)

static func log_enemy(message: String) -> void:
	if should_log(DEBUG_ENEMIES):
		print("[Enemy] " + message)

static func log_player(message: String) -> void:
	if should_log(DEBUG_PLAYER):
		print("[Player] " + message)

static func log_ui(message: String) -> void:
	if should_log(DEBUG_UI):
		print("[UI] " + message)

static func log_exp(message: String) -> void:
	if should_log(DEBUG_EXPERIENCE):
		print("[EXP] " + message)
