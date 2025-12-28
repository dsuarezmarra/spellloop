extends Node2D
## Test scene for animated enemy sprites
## Muestra todos los enemigos tier_1, tier_2, tier_3, tier_4 con sus spritesheets animados

const ENEMY_BASE = preload("res://scripts/enemies/EnemyBase.gd")

# Escala para visualización en el test (más grande que en juego)
const TEST_SCALE = 0.4

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
	title.position = Vector2(700, 10)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	
	# Subtítulo con efectos
	var subtitle = Label.new()
	subtitle.text = "Efectos: Bobbing + Breathing + Squash/Stretch + Sway"
	subtitle.position = Vector2(620, 40)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(subtitle)
	
	# Spawn por filas - ajustado para 4 tiers
	_spawn_row(tier_1_enemies, 100, "TIER 1")
	_spawn_row(tier_2_enemies, 310, "TIER 2")
	_spawn_row(tier_3_enemies, 520, "TIER 3")
	_spawn_row(tier_4_enemies, 730, "TIER 4")
	
	# Label de dirección actual
	direction_label = Label.new()
	direction_label.text = "Dirección: Abajo (1)"
	direction_label.position = Vector2(850, 950)
	direction_label.add_theme_font_size_override("font_size", 24)
	direction_label.add_theme_color_override("font_color", Color(1, 1, 0))
	add_child(direction_label)
	
	# Instrucciones
	var instr = Label.new()
	instr.text = "Teclas: 1=Abajo | 2=Izquierda | 3=Derecha | 4=Arriba"
	instr.position = Vector2(720, 1000)
	instr.add_theme_font_size_override("font_size", 20)
	add_child(instr)
	
	print("✓ %d enemigos spawneados" % enemies_spawned.size())

func _spawn_row(enemies: Array, y_pos: float, tier_label: String):
	# Label del tier
	var label = Label.new()
	label.text = tier_label
	label.position = Vector2(50, y_pos + 40)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	add_child(label)
	
	# Spawn enemigos con más espacio
	var start_x = 230
	var spacing = 300
	for i in range(enemies.size()):
		var pos = Vector2(start_x + i * spacing, y_pos + 70)
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
		enemy.animated_sprite.set_sprite_scale(TEST_SCALE)
		# Forzar dirección inicial hacia abajo
		enemy.animated_sprite.force_direction("down")
	
	# Label con nombre
	var label = Label.new()
	label.text = data.name
	label.position = Vector2(-40, 120)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	enemy.add_child(label)
	
	enemies_spawned.append(enemy)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		var dir_string: String = ""
		var dir_name: String = ""
		
		match event.keycode:
			KEY_1, KEY_KP_1:
				dir_string = "down"
				dir_name = "Abajo (1)"
			KEY_2, KEY_KP_2:
				dir_string = "left"
				dir_name = "Izquierda (2)"
			KEY_3, KEY_KP_3:
				dir_string = "right"
				dir_name = "Derecha (3)"
			KEY_4, KEY_KP_4:
				dir_string = "up"
				dir_name = "Arriba (4)"
		
		if dir_string != "":
			print("Cambiando dirección a: %s" % dir_name)
			direction_label.text = "Dirección: %s" % dir_name
			
			for enemy in enemies_spawned:
				if is_instance_valid(enemy) and enemy.animated_sprite:
					enemy.animated_sprite.force_direction(dir_string)
