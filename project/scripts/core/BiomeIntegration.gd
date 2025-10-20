extends Node
## 🌍 Biome Integration Entry Point
## Minimal wrapper that loads and initializes the biome system

func _ready():
	print("[BiomeIntegration] Loading biome system...")
	
	# Load the biome system script
	var biome_system_script = load("res://scripts/core/BiomeSystemFinal.gd")
	if biome_system_script == null:
		print("[BiomeIntegration] ❌ ERROR: Could not load BiomeSystemFinal.gd")
		return
	
	# Create instance and add to scene
	var biome_system = biome_system_script.new()
	biome_system.enable_debug = true
	biome_system.player_node_name = "SpellloopPlayer"
	add_child(biome_system)
	
	print("[BiomeIntegration] ✅ Biome system initialized")
