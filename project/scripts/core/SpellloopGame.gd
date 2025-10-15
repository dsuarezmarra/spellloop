extends Node2D
class_name SpellloopGame

"""
�‍♂️ SPELLLOOP GAME - SISTEMA PRINCIPAL
======================================

Gestiona el juego completo estilo roguelike top-down:
- Player fijo en centro
- Mundo infinito
- Auto-ataque mágico
- Enemigos
- Sistema EXP
"""

# Referencias a subsistemas
@onready var world_manager: InfiniteWorldManager
@onready var player: CharacterBody2D
@onready var enemy_manager: EnemyManager
@onready var weapon_manager: WeaponManager
@onready var experience_manager: ExperienceManager
@onready var item_manager: ItemManager

# Configuración
var game_running: bool = false

func _ready():
	print("�‍♂️ Iniciando Spellloop Game...")
	setup_game()

func setup_game():
	"""Configurar todos los sistemas del juego"""
	
	# Crear player fijo en el centro
	create_player()
	
	# Crear sistemas de gestión
	create_world_manager()
	create_enemy_manager()
	create_weapon_manager()
	create_experience_manager()
	create_item_manager()
	
	# Inicializar sistemas
	initialize_systems()
	
	# Comenzar juego
	start_game()

func create_player():
	"""Crear player centrado en pantalla"""
	player = CharacterBody2D.new()
	player.name = "Player"
	
	# Script del player (versión Spellloop)
	player.script = load("res://scripts/entities/SpellloopPlayer.gd")
	
	# Posicionar en centro de pantalla
	var viewport_size = get_viewport().get_visible_rect().size
	player.position = viewport_size / 2
	
	add_child(player)
	print("🧙‍♂️ Player creado en centro: ", player.position)

func create_world_manager():
	"""Crear gestor de mundo infinito"""
	world_manager = InfiniteWorldManager.new()
	world_manager.name = "WorldManager"
	add_child(world_manager)

func create_enemy_manager():
	"""Crear gestor de enemigos"""
	enemy_manager = EnemyManager.new()
	enemy_manager.name = "EnemyManager"
	add_child(enemy_manager)

func create_weapon_manager():
	"""Crear gestor de armas"""
	weapon_manager = WeaponManager.new()
	weapon_manager.name = "WeaponManager"
	add_child(weapon_manager)

func create_item_manager():
	"""Crear gestor de items"""
	item_manager = ItemManager.new()
	item_manager.name = "ItemManager"
	add_child(item_manager)

func initialize_systems():
	"""Inicializar todos los sistemas"""
	
	# Inicializar mundo infinito
	world_manager.initialize_world(player)
	
	# Inicializar enemigos
	enemy_manager.initialize(player, world_manager)
	
	# Inicializar armas
	weapon_manager.initialize(player)
	
	# Inicializar experiencia
	experience_manager.initialize(player)
	
	# Conectar señales entre sistemas
	connect_systems()

func connect_systems():
	"""Conectar señales entre sistemas"""
	
	# Player movimiento -> World movement
	if player.has_signal("movement_input"):
		player.movement_input.connect(_on_player_movement)
	
	# Enemigos muertos -> EXP
	if enemy_manager.has_signal("enemy_died"):
		enemy_manager.enemy_died.connect(_on_enemy_died)
	
	# EXP -> Level up
	if experience_manager.has_signal("level_up"):
		experience_manager.level_up.connect(_on_level_up)
	
	# Conectar WeaponManager con EnemyManager para targeting
	weapon_manager.set_enemy_manager(enemy_manager)

func start_game():
	"""Iniciar el juego"""
	game_running = true
	print("🎮 ¡Spellloop Game iniciado!")

func _on_player_movement(movement_delta: Vector2):
	"""Manejar movimiento del player (mover mundo)"""
	if world_manager:
		world_manager.update_world(movement_delta)

func _on_enemy_died(enemy_position: Vector2, enemy_type: String, exp_value: int):
	"""Manejar muerte de enemigo"""
	if experience_manager:
		# Crear bolita de EXP en la posición del enemigo
		experience_manager.create_exp_orb(enemy_position, exp_value)

func _on_level_up(new_level: int):
	"""Manejar subida de nivel"""
	print("🆙 ¡Level UP! Nuevo nivel: ", new_level)
	# Aquí se mostraría el menú de selección de armas/upgrades

func _process(delta):
	"""Update principal del juego"""
	if not game_running:
		return
	
	# Los sistemas se actualizan automáticamente
	# Aquí solo manejamos coordinación global

func get_game_stats() -> Dictionary:
	"""Obtener estadísticas del juego"""
	var stats = {
		"running": game_running,
		"player_level": 1,
		"enemies_alive": 0,
		"chunks_loaded": 0
	}
	
	if experience_manager:
		stats.player_level = experience_manager.current_level
	
	if enemy_manager:
		stats.enemies_alive = enemy_manager.get_enemy_count()
	
	if world_manager:
		stats.chunks_loaded = world_manager.get_loaded_chunks_count()
	
	return stats