## BiomeRenderingDebug.gd
## Verificar que los biomas se están renderizando correctamente y no hay conflictos

extends Node

var frame_count: int = 0

func _ready() -> void:
	set_process(true)
	print("🔍 BIOME RENDERING DEBUG INITIALIZED")

func _process(_delta: float) -> void:
	frame_count += 1
	
	# Cada 60 frames, hacer dump
	if frame_count % 120 == 0:
		_debug_dump()

func _debug_dump() -> void:
	print("\n" + ("="*70))
	print("[FRAME %d] 🔍 BIOME RENDERING DEBUG" % frame_count)
	print(("="*70))
	
	var spellloop = get_tree().root.get_child(0)
	if not spellloop:
		print("❌ SpellloopMain not found")
		return
	
	# Verificar WorldRoot
	if spellloop.has_node("WorldRoot"):
		var world_root = spellloop.get_node("WorldRoot")
		print("\n✅ WorldRoot found")
		
		# Verificar ChunksRoot
		if world_root.has_node("ChunksRoot"):
			var chunks_root = world_root.get_node("ChunksRoot")
			print("  ✅ ChunksRoot found")
			print("    Children count: %d" % chunks_root.get_child_count())
			
			# Enumerar chunks y sus biomas
			for chunk_node in chunks_root.get_children():
				var biome_name = chunk_node.get_meta("biome_name", "?") if chunk_node.has_meta("biome_name") else "?"
				var has_biome_layer = chunk_node.find_child("BiomeLayer", true, false) != null
				print("    - Chunk: %s | Bioma: %s | BiomeLayer: %s" % [
					chunk_node.name, 
					biome_name,
					"✅" if has_biome_layer else "❌"
				])
				
				# Verificar sprites en BiomeLayer
				if has_biome_layer:
					var biome_layer = chunk_node.find_child("BiomeLayer", true, false)
					var sprite_count = 0
					for sprite in biome_layer.get_children():
						if sprite is Sprite2D:
							sprite_count += 1
					print("      └─ BiomeLayer sprites: %d" % sprite_count)
		else:
			print("  ❌ ChunksRoot NOT found")
		
		# Verificar si Ground sigue existiendo (debería NO)
		if world_root.has_node("Ground"):
			print("  ⚠️  WARNING: Old Ground node still exists! Should be removed!")
		else:
			print("  ✅ Old Ground node properly removed")
	else:
		print("❌ WorldRoot not found")
	
	# Verificar que BiomeChunkApplier está en InfiniteWorldManager
	if spellloop.has_node("WorldRoot"):
		var world_root = spellloop.get_node("WorldRoot")
		if world_root.find_child("BiomeChunkApplier", true, false):
			print("\n✅ BiomeChunkApplier found in hierarchy")
		else:
			print("\n❌ BiomeChunkApplier NOT found in hierarchy")
	
	print(("="*70) + "\n")
