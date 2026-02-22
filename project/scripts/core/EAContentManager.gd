# EAContentManager.gd
# Gestor de contenido para Early Access
# Controla qué personajes, armas y contenido están habilitados en cada momento.
# Permite desbloquear contenido progresivamente mediante actualizaciones.
#
# USO:
#   - Los personajes/armas EA_ENABLED están disponibles en el juego
#   - Los personajes/armas NO listados están completamente ocultos
#   - Para habilitar nuevo contenido: añadir IDs a las listas correspondientes
#   - Para desactivar el sistema EA (mostrar todo): poner ea_mode = false

extends Node

# =============================================================================
# CONFIGURACIÓN EARLY ACCESS
# =============================================================================

## Si es true, el sistema EA filtra contenido. Si es false, todo está disponible.
var ea_mode: bool = false

## Versión del contenido EA (incrementar con cada wave de contenido)
var ea_content_version: String = "0.1.0"

# =============================================================================
# WAVE 1 ? LANZAMIENTO EARLY ACCESS
# Personajes iniciales: Frost Mage, Pyromancer, Storm Caller
# Armas: Solo las de los 3 personajes iniciales + sus fusiones entre sí
# =============================================================================

## Personajes habilitados en EA (IDs de CharacterDatabase)
var ea_enabled_characters: Array = [
	"frost_mage",
	"pyromancer",
	"storm_caller",
]

## Armas base habilitadas en EA (IDs de WeaponDatabase)
## Solo las armas iniciales de los personajes habilitados
var ea_enabled_weapons: Array = [
	"ice_wand",
	"fire_wand",
	"lightning_wand",
]

## Fusiones habilitadas en EA
## Solo las combinaciones posibles entre las armas habilitadas
var ea_enabled_fusions: Array = [
	"ice_wand+fire_wand",       # steam_cannon (Ice + Fire)
	"ice_wand+lightning_wand",  # frozen_thunder (Ice + Lightning)
	"fire_wand+lightning_wand", # plasma_bolt (Fire + Lightning)
]

# =============================================================================
# PLANTILLAS PARA FUTURAS WAVES (descomentar cuando se activen)
# =============================================================================

# WAVE 2 ? Ejemplo: Añadir Arcanist y Druid
# Descomentar y añadir a las listas cuando se lance la wave:
#   ea_enabled_characters += ["arcanist", "druid"]
#   ea_enabled_weapons += ["arcane_orb", "nature_staff"]
#   ea_enabled_fusions += [
#       "arcane_orb+ice_wand", "arcane_orb+fire_wand", "arcane_orb+lightning_wand",
#       "nature_staff+ice_wand", "nature_staff+fire_wand", "nature_staff+lightning_wand",
#       "arcane_orb+nature_staff",
#   ]

# WAVE 3 ? Ejemplo: Añadir Shadow Blade y Wind Runner
#   ea_enabled_characters += ["shadow_blade", "wind_runner"]
#   ea_enabled_weapons += ["shadow_dagger", "wind_blade"]
#   ... y sus fusiones correspondientes

# WAVE FINAL ? Todos los personajes
#   ea_mode = false  (o añadir todos los IDs restantes)

# =============================================================================
# FUNCIONES DE CONSULTA
# =============================================================================

func is_character_enabled(character_id: String) -> bool:
	"""Verifica si un personaje está habilitado en la versión actual de EA"""
	if not ea_mode:
		return true
	return character_id in ea_enabled_characters

func is_weapon_enabled(weapon_id: String) -> bool:
	"""Verifica si un arma base está habilitada en EA"""
	if not ea_mode:
		return true
	return weapon_id in ea_enabled_weapons

func is_fusion_enabled(fusion_key: String) -> bool:
	"""Verifica si una fusión está habilitada en EA.
	   Acepta tanto 'arma_a+arma_b' como 'arma_b+arma_a'."""
	if not ea_mode:
		return true
	# Verificar en ambas direcciones
	if fusion_key in ea_enabled_fusions:
		return true
	# Invertir el orden
	var parts = fusion_key.split("+")
	if parts.size() == 2:
		var reversed_key = parts[1] + "+" + parts[0]
		if reversed_key in ea_enabled_fusions:
			return true
	return false

func is_fusion_enabled_by_weapons(weapon_a: String, weapon_b: String) -> bool:
	"""Verifica si la fusión entre dos armas está habilitada en EA"""
	if not ea_mode:
		return true
	var key1 = weapon_a + "+" + weapon_b
	var key2 = weapon_b + "+" + weapon_a
	return key1 in ea_enabled_fusions or key2 in ea_enabled_fusions

# =============================================================================
# FUNCIONES DE FILTRADO (para usar desde otros sistemas)
# =============================================================================

func get_enabled_character_ids() -> Array:
	"""Retorna los IDs de personajes habilitados en EA"""
	if not ea_mode:
		return []  # Vacío = sin filtro, usar todos
	return ea_enabled_characters.duplicate()

func get_enabled_weapon_ids() -> Array:
	"""Retorna los IDs de armas base habilitadas en EA"""
	if not ea_mode:
		return []  # Vacío = sin filtro, usar todas
	return ea_enabled_weapons.duplicate()

func get_enabled_fusion_keys() -> Array:
	"""Retorna las claves de fusiones habilitadas en EA"""
	if not ea_mode:
		return []
	return ea_enabled_fusions.duplicate()

# =============================================================================
# FUNCIONES DE ADMINISTRACIÓN (para habilitar contenido en caliente)
# =============================================================================

func enable_character(character_id: String) -> void:
	"""Habilita un personaje en EA"""
	if character_id not in ea_enabled_characters:
		ea_enabled_characters.append(character_id)
		print("[EAContentManager] Personaje habilitado: %s" % character_id)

func enable_weapon(weapon_id: String) -> void:
	"""Habilita un arma base en EA"""
	if weapon_id not in ea_enabled_weapons:
		ea_enabled_weapons.append(weapon_id)
		print("[EAContentManager] Arma habilitada: %s" % weapon_id)

func enable_fusion(weapon_a: String, weapon_b: String) -> void:
	"""Habilita una fusión en EA"""
	var key = weapon_a + "+" + weapon_b
	if key not in ea_enabled_fusions:
		ea_enabled_fusions.append(key)
		print("[EAContentManager] Fusión habilitada: %s" % key)

func enable_wave(wave_characters: Array, wave_weapons: Array, wave_fusions: Array) -> void:
	"""Habilita una wave completa de contenido"""
	for c in wave_characters:
		enable_character(c)
	for w in wave_weapons:
		enable_weapon(w)
	for f in wave_fusions:
		if f is Array and f.size() == 2:
			enable_fusion(f[0], f[1])
		elif f is String:
			if f not in ea_enabled_fusions:
				ea_enabled_fusions.append(f)

func disable_ea_mode() -> void:
	"""Desactiva el modo EA ? todo el contenido disponible"""
	ea_mode = false
	print("[EAContentManager] Modo EA desactivado ? todo el contenido habilitado")

# =============================================================================
# DEBUG
# =============================================================================

func print_ea_status() -> void:
	"""Imprime el estado actual del contenido EA"""
	print("=".repeat(50))
	print("[EAContentManager] Estado EA v%s" % ea_content_version)
	print("  Modo EA: %s" % ("ACTIVO" if ea_mode else "DESACTIVADO"))
	print("  Personajes: %d habilitados" % ea_enabled_characters.size())
	for c in ea_enabled_characters:
		print("    - %s" % c)
	print("  Armas base: %d habilitadas" % ea_enabled_weapons.size())
	for w in ea_enabled_weapons:
		print("    - %s" % w)
	print("  Fusiones: %d habilitadas" % ea_enabled_fusions.size())
	for f in ea_enabled_fusions:
		print("    - %s" % f)
	print("=".repeat(50))

func _ready() -> void:
	if ea_mode:
		print("[EAContentManager] Modo Early Access ACTIVO ? v%s" % ea_content_version)
		print("[EAContentManager] Personajes: %s" % str(ea_enabled_characters))
		print("[EAContentManager] Armas: %s" % str(ea_enabled_weapons))
		print("[EAContentManager] Fusiones: %d habilitadas" % ea_enabled_fusions.size())
	else:
		print("[EAContentManager] Modo EA desactivado ? todo el contenido disponible")
