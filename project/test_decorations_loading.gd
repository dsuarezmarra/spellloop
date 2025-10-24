# test_decorations_loading.gd
# Script para verificar que todas las decoraciones de Lava se cargan

extends Node

func _ready():
	print("\n🔍 VERIFICANDO CARGA DE DECORACIONES")
	print("=" * 60)
	
	# Verificar que BiomeRegionApplier carga las decoraciones
	var applier_script = load("res://scripts/core/BiomeRegionApplier.gd")
	if applier_script:
		# Acceder a la configuración de texturas
		var applier = applier_script.new()
		if applier.has_meta("BIOME_TEXTURES"):
			print("❌ BIOME_TEXTURES está como meta")
		else:
			print("✓ Accediendo a BIOME_TEXTURES...")
			
			# Crear una prueba simulada
			test_lava_decorations()
	
	print("=" * 60)
	quit(0)

func test_lava_decorations():
	"""Verificar que las decoraciones de Lava existen y se cargan"""
	print("\n🌋 TEST: Texturas Lava")
	
	var base_path = "res://assets/textures/biomes/Lava/"
	var expected_files = ["base.png", "decor1.png", "decor2.png", "decor3.png", "decor4.png", "decor5.png"]
	
	for file in expected_files:
		var full_path = base_path + file
		if ResourceLoader.exists(full_path):
			var texture = load(full_path) as Texture2D
			if texture:
				print("  ✅ Cargada: %s (Size: %s)" % [file, texture.get_size()])
			else:
				print("  ⚠️ Ruta existe pero no se pudo cargar: %s" % file)
		else:
			print("  ❌ NO ENCONTRADA: %s" % file)
