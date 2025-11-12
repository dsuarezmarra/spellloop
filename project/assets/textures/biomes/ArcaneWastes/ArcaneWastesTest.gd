extends Node2D

func _ready():
	print("🎨 Inicializando prueba de texturas de ArcaneWastes")

	# Configurar textura base
	setup_base_texture()

	# Configurar todas las decoraciones
	for i in range(1, 12):  # 1 a 11
		setup_decor_texture(i)

	print("✅ Prueba de texturas configurada correctamente")

func setup_base_texture():
	var base_sprite = $BaseTexture as AnimatedSprite2D
	var sprite_frames = SpriteFrames.new()

	var texture = load("res://assets/textures/biomes/ArcaneWastes/base/arcanewastes_base_animated_sheet_f8_512.png") as Texture2D

	sprite_frames.add_animation("default")

	# 8 frames horizontales, 512x512 cada uno, con 4px de separación
	for i in range(8):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			i * (512 + 4),  # x position (frame width + padding)
			0,              # y position
			512,            # width
			512             # height
		)
		sprite_frames.add_frame("default", atlas)

	base_sprite.sprite_frames = sprite_frames
	base_sprite.animation = "default"
	base_sprite.speed_scale = 10
	base_sprite.play()

	print("✓ Textura base configurada (8 frames, 512×512px)")

func setup_decor_texture(decor_number: int):
	var decor_sprite = get_node("Decor%d" % decor_number) as AnimatedSprite2D
	var sprite_frames = SpriteFrames.new()

	var texture_path = "res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor%d_sheet_f8_256.png" % decor_number
	var texture = load(texture_path) as Texture2D

	sprite_frames.add_animation("default")

	# 8 frames horizontales, 256x256 cada uno, con 4px de separación
	for i in range(8):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			i * (256 + 4),  # x position (frame width + padding)
			0,              # y position
			256,            # width
			256             # height
		)
		sprite_frames.add_frame("default", atlas)

	decor_sprite.sprite_frames = sprite_frames
	decor_sprite.animation = "default"
	decor_sprite.speed_scale = 10
	decor_sprite.play()

	print("✓ Decor %d configurado (8 frames, 256×256px)" % decor_number)
