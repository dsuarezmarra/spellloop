extends Node2D
## Test scene for animated enemy sprites
## Muestra todos los enemigos tier_1, tier_2, tier_3, tier_4 con sus spritesheets animados

const ENEMY_BASE = preload("res://scripts/enemies/EnemyBase.gd")

# Escala para visualización en el test (más grande que en juego)
const TEST_SCALE = 0.5

var tier_1_enemies = [
	{"id": "slime", "tier": 1, "name": "Slime"},
	{"id": "tier_1_murcielago_etereo", "tier": 1, "name": "Murciélago"},
	{"id": "skeleton", "tier": 1, "name": "Esqueleto"},
	{"id": "tier_1_arana_venenosa", "tier": 1, "name": "Araña"},
	{"id": "goblin", "tier": 1, "name": "Duende"}
]

var tier_2_enemies = [
	{"id": "tier_2_guerrero_espectral", "tier": 2, "name": "Guerrero"},
	{"id": "tier_2_lobo_de_cristal", "tier": 2, "name": "Lobo"},
	{"id": "tier_2_golem_runico", "tier": 2, "name": "Golem"},
	{"id": "tier_2_hechicero_desgastado", "tier": 2, "name": "Hechicero"},
	{"id": "tier_2_sombra_flotante", "tier": 2, "name": "Sombra"}
]

var tier_3_enemies = [
	{"id": "tier_3_caballero_del_vacio", "tier": 3, "name": "Caballero"},
	{"id": "tier_3_serpiente_de_fuego", "tier": 3, "name": "Serpiente"},
	{"id": "tier_3_elemental_de_hielo", "tier": 3, "name": "Elemental"},
	{"id": "tier_3_mago_abismal", "tier": 3, "name": "Mago"},
	{"id": "tier_3_corruptor_alado", "tier": 3, "name": "Corruptor"}
]

var tier_4_enemies = [
	{"id": "tier_4_titan_arcano", "tier": 4, "name": "Titán"},
	{"id": "tier_4_senor_de_las_llamas", "tier": 4, "name": "Señor Llamas"},
	{"id": "tier_4_reina_del_hielo", "tier": 4, "name": "Reina Hielo"},
	{"id": "tier_4_archimago_perdido", "tier": 4, "name": "Archimago"},
	{"id": "tier_4_dragon_etereo", "tier": 4, "name": "Dragón"}
]

var enemies_spawned = []
var current_direction_idx = 0
var directions = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
var direction_names = ["Abajo", "Izquierda", "Derecha", "Arriba"]
var direction_label: Label

func _ready():
	print("=== TEST: Animated Enemy Sprites ===")
	print("Controles: 1=Abajo, 2=Izq, 3=Der, 4=Arriba")
	
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.size = Vector2(1920, 1080)
	bg.z_index = -10
	add_child(bg)
	
	# Título
	var title = Label.new()
	title.text = "Test: Animated Enemy Sprites"
	title.position = Vector2(700, 20)
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	
	# Subtítulo con efectos
	var subtitle = Label.new()
	subtitle.text = "Efectos: Bobbing + Breathing + Squash/Stretch + Sway"
	subtitle.position = Vector2(620, 60)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(subtitle)
	
	# Spawn por filas con más espacio (4 filas)
	_spawn_row(tier_1_enemies, 140, "TIER 1")
	_spawn_row(tier_2_enemies, 340, "TIER 2")
	_spawn_row(tier_3_enemies, 540, "TIER 3")
	_spawn_row(tier_4_enemies, 740, "TIER 4")
	
	# Label de dirección actual
	direction_label = Label.new()
	direction_label.text = "Dirección: Abajo (1)"
	direction_label.position = Vector2(850, 920)
	direction_label.add_theme_font_size_override("font_size", 24)
	direction_label.add_theme_color_override("font_color", Color(1, 1, 0))
	add_child(direction_label)
	
	# Instrucciones
	var instr = Label.new()
	instr.text = "Teclas: 1=Abajo | 2=Izquierda | 3=Derecha | 4=Arriba"
	instr.position = Vector2(720, 970)
	instr.add_theme_font_size_override("font_size", 20)
	add_child(instr)
	
	print("✓ %d enemigos spawneados" % enemies_spawned.size())
	
	# Forzar dirección inicial DOWN para todos después de un frame
	await get_tree().process_frame
	_force_all_direction(Vector2.DOWN)

func _spawn_row(enemies: Array, y_pos: float, tier_label: String):
	# Label del tier
	var label = Label.new()
	label.text = tier_label
	label.position = Vector2(50, y_pos + 50)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	add_child(label)
	
	# Spawn enemigos con más espacio
	var start_x = 250
	var spacing = 320
	for i in range(enemies.size()):
		var pos = Vector2(start_x + i * spacing, y_pos + 80)
		_spawn_enemy(enemies[i], pos)

func _spawn_enemy(data: Dictionary, pos: Vector2):
	var enemy = CharacterBody2D.new()
	enemy.set_script(ENEMY_BASE)
	enemy.position = pos
	enemy.name = "Enemy_%s" % data.id
	add_child(enemy)
	
	enemy.initialize({
		"id": data.id,
		"tier": data.tier,
		"health": 100,
		"speed": 0,
		"damage": 10,
		"exp_value": 5
	}, null)
	
	# Aplicar escala más grande para el test
	if enemy.animated_sprite:
		enemy.animated_sprite.sprite_scale = TEST_SCALE
	
	# Label con nombre
	var label = Label.new()
	label.text = data.name
	label.position = Vector2(-40, 120)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	enemy.add_child(label)
	
	enemies_spawned.append(enemy)

func _force_all_direction(direction: Vector2):
	"""Forzar dirección en todos los enemigos (con lock para evitar sobrescritura)"""
	for enemy in enemies_spawned:
		if is_instance_valid(enemy) and enemy.animated_sprite:
			enemy.animated_sprite.force_direction(direction, true)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		var new_direction: Vector2 = Vector2.ZERO
		var dir_name: String = ""
		
		match event.keycode:
			KEY_1, KEY_KP_1:
				new_direction = Vector2.DOWN
				dir_name = "Abajo (1)"
			KEY_2, KEY_KP_2:
				new_direction = Vector2.LEFT
				dir_name = "Izquierda (2)"
			KEY_3, KEY_KP_3:
				new_direction = Vector2.RIGHT
				dir_name = "Derecha (3)"
			KEY_4, KEY_KP_4:
				new_direction = Vector2.UP
				dir_name = "Arriba (4)"
		
		if new_direction != Vector2.ZERO:
			print(">>> Cambiando dirección a: %s" % dir_name)
			direction_label.text = "Dirección: %s" % dir_name
			_force_all_direction(new_direction)
