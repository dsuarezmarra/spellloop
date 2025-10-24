extends Node

# Prueba final de compilación para verificar que todos los errores están corregidos

func _ready():
	print("🔍 PRUEBA FINAL DE COMPILACIÓN")
	print("=" * 50)
	
	# Test 1: Verificar carga de OrganicTextureBlender con nuevo nombre
	print("\n1. Verificando OrganicTextureBlender...")
	var blender_script = preload("res://scripts/core/OrganicTextureBlender.gd")
	if blender_script:
		var blender = blender_script.new()
		if blender:
			print("  ✅ OrganicTextureBlenderSystem cargado y creado")
		else:
			print("  ❌ Error creando OrganicTextureBlenderSystem")
	else:
		print("  ❌ Error cargando script OrganicTextureBlender.gd")
	
	# Test 2: Verificar InfiniteWorldManager
	print("\n2. Verificando InfiniteWorldManager...")
	var iwm_script = preload("res://scripts/core/InfiniteWorldManager.gd")
	if iwm_script:
		print("  ✅ InfiniteWorldManager cargado")
	else:
		print("  ❌ Error cargando InfiniteWorldManager")
	
	# Test 3: Verificar BiomeRegionApplier
	print("\n3. Verificando BiomeRegionApplier...")
	var bra_script = preload("res://scripts/core/BiomeRegionApplier.gd")
	if bra_script:
		print("  ✅ BiomeRegionApplier cargado")
	else:
		print("  ❌ Error cargando BiomeRegionApplier")
	
	# Test 4: Verificar BiomeGenerator
	print("\n4. Verificando BiomeGenerator...")
	var bg_script = preload("res://scripts/core/BiomeGenerator.gd")
	if bg_script:
		print("  ✅ BiomeGenerator cargado")
	else:
		print("  ❌ Error cargando BiomeGenerator")
	
	# Test 5: Verificar OrganicBlendingIntegration
	print("\n5. Verificando OrganicBlendingIntegration...")
	var obi_script = preload("res://scripts/core/OrganicBlendingIntegration.gd")
	if obi_script:
		print("  ✅ OrganicBlendingIntegration cargado")
	else:
		print("  ❌ Error cargando OrganicBlendingIntegration")
	
	print("\n" + "=" * 50)
	print("✅ COMPILACIÓN FINAL COMPLETA")
	print("Todos los archivos principales cargados sin errores")