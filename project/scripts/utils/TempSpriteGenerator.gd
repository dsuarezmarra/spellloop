extends Node
# Generador de sprites temporales para testing
# Crea imágenes simples de colores sólidos para probar el sistema

func _ready():
	generate_temp_sprites()

func generate_temp_sprites():
	print("Generando sprites temporales para testing...")
	
	# Crear directorio si no existe
	var dir = DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("assets/sprites/temp")
	
	# Generar sprites de enemigos Tier 1
	create_simple_sprite("enemy_tier_1_slime_novice", Color.PURPLE, 64)
	create_simple_sprite("enemy_tier_1_goblin_scout", Color.GREEN, 64) 
	create_simple_sprite("enemy_tier_1_skeleton_warrior", Color.WHITE, 64)
	create_simple_sprite("enemy_tier_1_shadow_bat", Color.DARK_GRAY, 64)
	create_simple_sprite("enemy_tier_1_poison_spider", Color.DARK_GREEN, 64)
	
	# Generar sprite de boss
	create_simple_sprite("boss_5min_archmage_corrupt", Color.RED, 96)
	
	# Generar sprites de efectos
	create_simple_sprite("xp_orb", Color.YELLOW, 24)
	create_simple_sprite("enemy_projectile", Color.ORANGE, 16)
	create_simple_sprite("boss_projectile", Color.MAGENTA, 20)
	
	# Generar sprites de items
	create_simple_sprite("treasure_chest", Color.BROWN, 48)
	create_simple_sprite("item_drop", Color.CYAN, 32)
	
	print("Sprites temporales generados en assets/sprites/temp/")

func create_simple_sprite(name: String, color: Color, size: int):
	# Crear imagen simple de color sólido
	var image = Image.new()
	image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Crear borde negro para visibilidad
	for x in range(size):
		image.set_pixel(x, 0, Color.BLACK)
		image.set_pixel(x, size-1, Color.BLACK)
	for y in range(size):
		image.set_pixel(0, y, Color.BLACK)
		image.set_pixel(size-1, y, Color.BLACK)
	
	# Crear textura
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	# Guardar como resource
	var path = "res://assets/sprites/temp/" + name + ".tres"
	ResourceSaver.save(path, texture)
