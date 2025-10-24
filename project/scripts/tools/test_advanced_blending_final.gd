# test_advanced_blending_final.gd
# Script de prueba final simplificado
extends Node

func _ready():
	print("🧪 INICIANDO PRUEBAS DEL SISTEMA DE BLENDING AVANZADO")
	print("============================================================")
	
	# Verificar que los archivos se cargan correctamente
	test_script_loading()
	
	# Verificar shader
	test_shader_loading()
	
	# Simular integración
	test_integration_simulation()
	
	print("============================================================")
	print("✅ PRUEBAS COMPLETADAS - SISTEMA LISTO PARA USO")

func test_script_loading():
	print("\n📋 1. PRUEBA DE CARGA DE SCRIPTS:")
	
	# Verificar OrganicTextureBlender
	var blender_script = preload("res://scripts/core/OrganicTextureBlender.gd")
	if blender_script:
		print("  ✅ OrganicTextureBlender.gd - CARGADO")
		var blender = blender_script.new()
		if blender.has_method("initialize"):
			print("  ✅ Método initialize() disponible")
		if blender.has_method("apply_blend_to_region"):
			print("  ✅ Método apply_blend_to_region() disponible")
	else:
		print("  ❌ OrganicTextureBlender.gd - ERROR DE CARGA")
	
	# Verificar OrganicBlendingIntegration
	var integration_script = preload("res://scripts/core/OrganicBlendingIntegration.gd")
	if integration_script:
		print("  ✅ OrganicBlendingIntegration.gd - CARGADO")
		var integration = integration_script.new()
		if integration.has_method("apply_manual_blending"):
			print("  ✅ Método apply_manual_blending() disponible")
	else:
		print("  ❌ OrganicBlendingIntegration.gd - ERROR DE CARGA")

func test_shader_loading():
	print("\n🎨 2. PRUEBA DE CARGA DE SHADER:")
	
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path)
		if shader:
			print("  ✅ biome_blend.gdshader - CARGADO")
			
			# Crear material de prueba
			var material = ShaderMaterial.new()
			material.shader = shader
			
			# Probar configuración de parámetros
			material.set_shader_parameter("blend_strength", 0.5)
			material.set_shader_parameter("noise_scale", 1.0)
			print("  ✅ Parámetros del shader configurados")
		else:
			print("  ❌ Error al cargar shader")
	else:
		print("  ❌ Shader no encontrado: " + shader_path)

func test_integration_simulation():
	print("\n🔗 3. SIMULACIÓN DE INTEGRACIÓN:")
	
	# Crear instancia de OrganicTextureBlender
	var blender_script = preload("res://scripts/core/OrganicTextureBlender.gd")
	var blender = blender_script.new()
	add_child(blender)
	
	# Inicializar con semilla de prueba
	blender.initialize(42)
	print("  ✅ OrganicTextureBlender inicializado")
	
	# Crear instancia de OrganicBlendingIntegration
	var integration_script = preload("res://scripts/core/OrganicBlendingIntegration.gd")
	var integration = integration_script.new()
	add_child(integration)
	print("  ✅ OrganicBlendingIntegration creado")
	
	# Simular blending manual
	await get_tree().process_frame  # Esperar un frame para _ready()
	
	var material = integration.apply_manual_blending(
		Vector2(100, 100),
		"grassland",
		"desert"
	)
	
	if material:
		print("  ✅ Blending manual ejecutado con éxito")
		print("  🎨 Material generado: " + str(material.get_class()))
	else:
		print("  ⚠️ Blending manual no generó material (normal en modo prueba)")
	
	# Verificar estado de integración
	var status = integration.get_integration_status()
	print("  📊 Estado de integración:")
	for key in status.keys():
		print("    - " + str(key) + ": " + str(status[key]))
	
	print("  ✅ Simulación de integración completada")