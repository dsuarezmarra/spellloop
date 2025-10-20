extends Node

func _ready():
	var textures = [
		"res://assets/textures/biomes/Grassland/base.png",
		"res://assets/textures/biomes/Grassland/decor1.png",
		"res://assets/textures/biomes/ArcaneWastes/base.png",
	]
	
	for tex_path in textures:
		if ResourceLoader.exists(tex_path):
			var texture = load(tex_path) as Texture2D
			if texture:
				print("[DEBUG] %s: %s" % [tex_path.get_file(), texture.get_size()])
		else:
			print("[ERROR] Not found: %s" % tex_path)
	
	get_tree().quit()
