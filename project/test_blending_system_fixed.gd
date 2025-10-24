extends Node

# Script de prueba corregido para el sistema de blending
func _ready():
	print("=== INICIANDO PRUEBAS DEL SISTEMA DE BLENDING CORREGIDO ===")
	
	# Verificar que el shader existe y es válido
	test_shader_availability()
	
	# Verificar OrganicTextureBlender
	test_texture_blender()
	
	# Verificar integración completa
	test_integration_system()
	
	print("=== PRUEBAS COMPLETADAS ===")
	
	# Esperar un poco antes de cerrar
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func test_shader_availability():
	print("\n🔍 PRUEBA 1: Disponibilidad del Shader")
	
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	
	if ResourceLoader.exists(shader_path):
		print("✅ Shader encontrado: " + shader_path)
		
		var shader = load(shader_path)
		if shader is Shader:
			print("✅ Shader cargado correctamente")
		else:
			print("❌ Error cargando shader")
	else:
		print("❌ Shader no encontrado en: " + shader_path)

func test_texture_blender():
	print("\n🔍 PRUEBA 2: OrganicTextureBlender")
	
	var blender_script = load("res://scripts/core/OrganicTextureBlenderFixed.gd")
	
	if blender_script:
		print("✅ Script encontrado")
		
		var blender = blender_script.new()
		if blender:
			print("✅ OrganicTextureBlender instanciado")
			
			# Probar inicialización
			blender.initialize(12345)
			
			if blender.is_initialized:
				print("✅ TextureBlender inicializado correctamente")
				
				# Obtener estadísticas
				var stats = blender.get_performance_stats()
				print("📊 Estadísticas iniciales:")
				for key in stats:
					print("   - " + str(key) + ": " + str(stats[key]))
					
			else:
				print("❌ Error inicializando TextureBlender")
		else:
			print("❌ Error instanciando blender")
	else:
		print("❌ No se pudo cargar OrganicTextureBlender")

func test_integration_system():
	print("\n🔍 PRUEBA 3: Sistema de Integración")
	
	var integration_script = load("res://scripts/core/OrganicBlendingIntegrationFixed.gd")
	
	if integration_script:
		print("✅ Script de integración encontrado")
		
		var integration = integration_script.new()
		add_child(integration)
		
		if integration:
			print("✅ OrganicBlendingIntegration instanciado")
			
			# Esperar inicialización
			await get_tree().create_timer(0.5).timeout
			
			var status = integration.get_integration_status()
			print("📊 Estado de integración:")
			for key in status:
				print("   - " + str(key) + ": " + str(status[key]))
		else:
			print("❌ Error instanciando integración")
	else:
		print("❌ No se pudo cargar script de integración")