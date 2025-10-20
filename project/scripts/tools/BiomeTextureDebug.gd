extends Node
## 🔍 BIOME TEXTURE SIZE DEBUG TOOL
## 
## Verifica los tamaños reales de las texturas de biomas
## Úsalo para validar que las texturas están en los tamaños esperados:
## - Base: 1920×1080
## - Decor principales: 256×256
## - Decor secundarias: 128×128

class_name BiomeTextureDebug

# Tamaños esperados
const EXPECTED_SIZES = {
	"base": Vector2(1920, 1080),
	"decor_main": Vector2(256, 256),
	"decor_secondary": Vector2(128, 128)
}

const BIOMES = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]

func _ready() -> void:
	print("\n" + "="*70)
	print("🔍 BIOME TEXTURE SIZE DEBUG")
	print("="*70 + "\n")
	
	var all_valid = true
	
	for biome in BIOMES:
		print("📁 %s" % biome)
		print("  " + "-"*60)
		
		# Check base
		var base_path = "res://assets/textures/biomes/%s/base.png" % biome
		if not _check_texture(base_path, "base", EXPECTED_SIZES["base"]):
			all_valid = false
		
		# Check decorations (assuming up to 3 decor files)
		for i in range(1, 4):
			var decor_path = "res://assets/textures/biomes/%s/decor%d.png" % [biome, i]
			if ResourceLoader.exists(decor_path):
				var texture = load(decor_path) as Texture2D
				var size = texture.get_size() if texture else Vector2.ZERO
				
				# Infer type from size
				var expected_size: Vector2
				var decor_type = "?"
				
				if size == EXPECTED_SIZES["decor_main"]:
					expected_size = EXPECTED_SIZES["decor_main"]
					decor_type = "MAIN"
				elif size == EXPECTED_SIZES["decor_secondary"]:
					expected_size = EXPECTED_SIZES["decor_secondary"]
					decor_type = "SECONDARY"
				else:
					# Unknown size
					print("  ⚠️  decor%d.png: %s (UNKNOWN TYPE - expected 256×256 or 128×128)" % [i, size])
					all_valid = false
					continue
				
				if _check_texture(decor_path, f"decor{i} ({decor_type})", expected_size):
					pass  # OK
				else:
					all_valid = false
		
		print()
	
	# Summary
	print("="*70)
	if all_valid:
		print("✅ TODOS LOS TAMAÑOS SON CORRECTOS")
	else:
		print("⚠️  ALGUNOS TAMAÑOS REQUIEREN AJUSTE")
	print("="*70 + "\n")
	
	# Don't quit automatically - let user check console
	# get_tree().quit()

func _check_texture(path: String, name: String, expected_size: Vector2) -> bool:
	"""Check if texture exists and has correct size"""
	if not ResourceLoader.exists(path):
		print("  ❌ %s: NO ENCONTRADO" % name)
		return false
	
	var texture = load(path) as Texture2D
	if not texture:
		print("  ❌ %s: ERROR AL CARGAR" % name)
		return false
	
	var actual_size = texture.get_size()
	var is_correct = actual_size == expected_size
	
	if is_correct:
		print("  ✅ %s: %s" % [name, actual_size])
	else:
		print("  ❌ %s: %s (esperado: %s)" % [name, actual_size, expected_size])
	
	return is_correct
