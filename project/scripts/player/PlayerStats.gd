# PlayerStats.gd
# Sistema de estadísticas del jugador estilo Isaac/Hades
extends Node

# Estadísticas base del jugador
var damage: float = 10.0
var fire_rate: float = 0.2  # Cooldown entre disparos
var shot_speed: float = 500.0
var range_multiplier: float = 1.0  # Afecta el lifetime de proyectiles
var luck: float = 0.0

# Efectos especiales activos
var has_fire_effect: bool = false
var has_ice_effect: bool = false
var has_lightning_effect: bool = false
var piercing_shots: bool = false
var multi_shot: int = 1  # Número de proyectiles por disparo

# Colores de proyectiles según efectos
var projectile_color: Color = Color.YELLOW

# Modificadores de disparo
var spread_angle: float = 0.0  # Para multi-shot

func _ready():
	print("[PlayerStats] Player stats initialized")
	update_projectile_appearance()

func add_fire_effect():
	"""Añadir efecto de fuego"""
	has_fire_effect = true
	damage += 5.0
	print("[PlayerStats] Fire effect added! Damage increased to: ", damage)
	update_projectile_appearance()

func add_ice_effect():
	"""Añadir efecto de hielo"""
	has_ice_effect = true
	fire_rate = max(0.1, fire_rate - 0.05)  # Disparo más rápido
	print("[PlayerStats] Ice effect added! Fire rate improved to: ", fire_rate)
	update_projectile_appearance()

func add_lightning_effect():
	"""Añadir efecto de rayo"""
	has_lightning_effect = true
	piercing_shots = true
	shot_speed += 100.0
	print("[PlayerStats] Lightning effect added! Piercing shots enabled!")
	update_projectile_appearance()

func increase_multi_shot():
	"""Aumentar número de proyectiles"""
	multi_shot += 1
	if multi_shot > 1:
		spread_angle = 15.0 * (multi_shot - 1)  # Más spread con más proyectiles
	print("[PlayerStats] Multi-shot increased to: ", multi_shot)

func increase_damage(amount: float):
	"""Aumentar daño base"""
	damage += amount
	print("[PlayerStats] Damage increased by ", amount, " to: ", damage)

func increase_fire_rate(improvement: float):
	"""Mejorar velocidad de disparo (menor cooldown)"""
	fire_rate = max(0.05, fire_rate - improvement)
	print("[PlayerStats] Fire rate improved to: ", fire_rate)

func update_projectile_appearance():
	"""Actualizar apariencia de proyectiles según efectos activos"""
	if has_fire_effect and has_ice_effect and has_lightning_effect:
		projectile_color = Color.WHITE  # Todos los efectos = blanco
	elif has_fire_effect and has_ice_effect:
		projectile_color = Color.MAGENTA  # Fuego + hielo = magenta
	elif has_fire_effect and has_lightning_effect:
		projectile_color = Color.ORANGE  # Fuego + rayo = naranja
	elif has_ice_effect and has_lightning_effect:
		projectile_color = Color.CYAN  # Hielo + rayo = cyan
	elif has_fire_effect:
		projectile_color = Color.RED
	elif has_ice_effect:
		projectile_color = Color.BLUE
	elif has_lightning_effect:
		projectile_color = Color.YELLOW
	else:
		projectile_color = Color.YELLOW  # Básico

func get_projectile_effects() -> Array:
	"""Obtener lista de efectos activos para aplicar a proyectiles"""
	var effects = []
	if has_fire_effect:
		effects.append("burn")
	if has_ice_effect:
		effects.append("slow")
	if has_lightning_effect:
		effects.append("pierce")
	return effects

func get_stats_summary() -> String:
	"""Obtener resumen de estadísticas para UI"""
	var summary = "DMG:%.1f SPD:%.2f SHOTS:%d" % [damage, fire_rate, multi_shot]
	var effects = []
	if has_fire_effect:
		effects.append("🔥")
	if has_ice_effect:
		effects.append("❄️")
	if has_lightning_effect:
		effects.append("⚡")
	if effects.size() > 0:
		summary += " " + " ".join(effects)
	return summary