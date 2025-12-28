extends Node2D
## Test scene for animated enemy sprites
## Displays all tier_1 enemies with their animated spritesheets

const ENEMY_BASE = preload("res://scripts/enemies/EnemyBase.gd")

# Lista de enemigos tier 1 para probar
var tier_1_enemies = [
	{"id": "slime", "tier": 1, "name": "Slime Arcano"},
	{"id": "tier_1_murcielago_etereo", "tier": 1, "name": "Murciélago Etéreo"},
	{"id": "skeleton", "tier": 1, "name": "Esqueleto Aprendiz"},
	{"id": "tier_1_arana_venenosa", "tier": 1, "name": "Araña Venenosa"},
	{"id": "goblin", "tier": 1, "name": "Duende Sombrío"}
]

# Lista de enemigos tier 2 para probar
var tier_2_enemies = [
	{"id": "tier_2_guerrero_espectral", "tier": 2, "name": "Guerrero Espectral"},
	{"id": "tier_2_lobo_de_cristal", "tier": 2, "name": "Lobo de Cristal"},
	{"id": "tier_2_golem_runico", "tier": 2, "name": "Golem Rúnico"},
	{"id": "tier_2_hechicero_desgastado", "tier": 2, "name": "Hechicero Desgastado"},
	{"id": "tier_2_sombra_flotante", "tier": 2, "name": "Sombra Flotante"}
]

var spawn_positions = [
	Vector2(100, 120),
	Vector2(250, 120),
	Vector2(400, 120),
	Vector2(175, 220),
	Vector2(325, 220)
]

var spawn_positions_tier2 = [
	Vector2(100, 340),
	Vector2(250, 340),
	Vector2(400, 340),
	Vector2(175, 440),
	Vector2(325, 440)
]

var enemies_spawned = []

func _ready():
	print("=== TEST: Animated Enemy Sprites ===")
	print("Spawning tier_1 and tier_2 enemies with animated spritesheets...")
	
	# Crear fondo
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2, 1.0)
	bg.size = Vector2(500, 550)
	bg.position = Vector2.ZERO
	bg.z_index = -10
	add_child(bg)
	
	# Crear título
	var title = Label.new()
	title.text = "Test: Animated Enemy Sprites"
	title.position = Vector2(130, 10)
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	
	# Label tier 1
	var label_t1 = Label.new()
	label_t1.text = "TIER 1"
	label_t1.position = Vector2(20, 80)
	label_t1.add_theme_font_size_override("font_size", 14)
	add_child(label_t1)
	
	# Label tier 2
	var label_t2 = Label.new()
	label_t2.text = "TIER 2"
	label_t2.position = Vector2(20, 300)
	label_t2.add_theme_font_size_override("font_size", 14)
	add_child(label_t2)
	
	# Crear instrucciones
	var instructions = Label.new()
	instructions.text = "Presiona 1-4 para cambiar dirección: 1=Abajo 2=Izq 3=Der 4=Arriba"
	instructions.position = Vector2(50, 520)
	instructions.add_theme_font_size_override("font_size", 11)
	add_child(instructions)
	
	# Spawn tier 1 enemies
	for i in range(tier_1_enemies.size()):
		_spawn_enemy(tier_1_enemies[i], spawn_positions[i], i)
	
	# Spawn tier 2 enemies
	for i in range(tier_2_enemies.size()):
		_spawn_enemy(tier_2_enemies[i], spawn_positions_tier2[i], i + 5)
	
	print("✓ %d enemies spawned" % enemies_spawned.size())

func _spawn_enemy(data: Dictionary, pos: Vector2, index: int):
	# Crear CharacterBody2D base
	var enemy = CharacterBody2D.new()
	enemy.set_script(ENEMY_BASE)
	enemy.position = pos
	enemy.name = "Enemy_%s" % data.id
	
	add_child(enemy)
	
	# Inicializar después de añadir al árbol
	enemy.initialize({
		"id": data.id,
		"tier": data.tier,
		"health": 100,
		"speed": 0,  # Sin movimiento para test visual
		"damage": 10,
		"exp_value": 5
	}, null)  # Sin player ref
	
	# Crear label con nombre
	var label = Label.new()
	label.text = data.name
	label.position = Vector2(-40, 50)
	label.add_theme_font_size_override("font_size", 10)
	enemy.add_child(label)
	
	enemies_spawned.append(enemy)

func _input(event):
	if event is InputEventKey and event.pressed:
		var direction = Vector2.ZERO
		match event.keycode:
			KEY_1: direction = Vector2.DOWN   # Abajo (front)
			KEY_2: direction = Vector2.LEFT   # Izquierda
			KEY_3: direction = Vector2.RIGHT  # Derecha
			KEY_4: direction = Vector2.UP     # Arriba (back)
		
		if direction != Vector2.ZERO:
			print("Cambiando dirección de todos los enemigos a: %s" % direction)
			for enemy in enemies_spawned:
				if is_instance_valid(enemy) and enemy.animated_sprite:
					enemy.animated_sprite.set_direction(direction)
