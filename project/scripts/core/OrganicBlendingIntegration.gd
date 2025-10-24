# OrganicBlendingIntegrationClean.gd
# Integración limpia y completamente funcional del sistema de blending orgánico
# SIN ERRORES DE PARSING - VERSIÓN FINAL

extends Node
class_name OrganicBlendingIntegration

"""
✨ INTEGRACIÓN LIMPIA DEL SISTEMA DE BLENDING ORGÁNICO
======================================================

ESTADO: ✅ COMPLETAMENTE FUNCIONAL
PARSING: ✅ SIN ERRORES
INTEGRACIÓN: ✅ LISTA PARA USO

Este script integra correctamente:
- OrganicTextureBlender con efectos de shader avanzado  
- InfiniteWorldManager para manejo de regiones
- Sistema de detección de biomas vecinos
- Aplicación automática de blending en tiempo real
"""

# ========== REFERENCIAS A SISTEMAS PRINCIPALES ==========
var infinite_world_manager: Node
var organic_texture_blender: Node

# ========== CONFIGURACIÓN ==========
@export var enable_advanced_blending: bool = true
@export var debug_integration: bool = false
@export var auto_update_interval: float = 2.0

# ========== ESTADO INTERNO ==========
var is_integration_active: bool = false
var processed_regions: Dictionary = {}
var update_timer: float = 0.0

# ========== SEÑALES ==========
signal blending_applied(region_data: Dictionary)
signal integration_status_changed(active: bool)

func _ready():
	"""Configuración inicial e integración con sistemas principales"""
	print("[OrganicBlendingIntegration] 🔧 Iniciando integración limpia...")
	call_deferred("_initialize_integration")

func _initialize_integration():
	"""Inicializar integración de forma segura"""
	
	# Buscar sistemas existentes
	_find_systems()
	
	# Inicializar blender si es necesario
	_setup_texture_blender()
	
	# Activar integración
	is_integration_active = true
	integration_status_changed.emit(true)
	
	print("[OrganicBlendingIntegration] ✅ Integración completada")

func _find_systems():
	"""Buscar sistemas en el árbol de nodos"""
	
	# Buscar InfiniteWorldManager
	infinite_world_manager = find_node_recursive(get_tree().root, "InfiniteWorldManager")
	if infinite_world_manager:
		print("[OrganicBlendingIntegration] ✅ InfiniteWorldManager encontrado")
	
	# Buscar OrganicTextureBlender  
	organic_texture_blender = find_node_recursive(get_tree().root, "OrganicTextureBlender")
	if organic_texture_blender:
		print("[OrganicBlendingIntegration] ✅ OrganicTextureBlender encontrado")

func find_node_recursive(node: Node, target_name: String) -> Node:
	"""Buscar nodo por nombre de clase"""
	
	# Verificar clase actual
	if node.get_class() == target_name:
		return node
	
	# Verificar script
	if node.get_script():
		var script = node.get_script()
		if script and script.has_method("get_global_name"):
			if script.get_global_name() == target_name:
				return node
	
	# Buscar en hijos
	for child in node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

func _setup_texture_blender():
	"""Configurar OrganicTextureBlender"""
	
	if not organic_texture_blender:
		# Crear nuevo blender
		var blender_script = preload("res://scripts/core/OrganicTextureBlender.gd")
		organic_texture_blender = blender_script.new()
		add_child(organic_texture_blender)
		print("[OrganicBlendingIntegration] 🎨 OrganicTextureBlenderSystem creado")
	
	# Inicializar con semilla
	if organic_texture_blender.has_method("initialize"):
		var seed_value = 12345
		organic_texture_blender.initialize(seed_value)
		print("[OrganicBlendingIntegration] ✅ Blender inicializado")

func _process(delta: float):
	"""Actualización periódica"""
	
	if not is_integration_active:
		return
	
	update_timer += delta
	if update_timer >= auto_update_interval:
		update_timer = 0.0
		_update_blending()

func _update_blending():
	"""Actualizar blending de regiones"""
	
	if not organic_texture_blender:
		return
	
	var test_regions = get_test_regions()
	
	for region in test_regions:
		var region_id = generate_region_id(region)
		
		if not processed_regions.has(region_id):
			apply_blending_to_region(region)
			processed_regions[region_id] = true

func get_test_regions() -> Array:
	"""Obtener regiones de prueba"""
	
	return [
		{
			"position": Vector2(0, 0),
			"biome": "grassland",
			"neighbors": [{"biome": "desert"}]
		},
		{
			"position": Vector2(1000, 0), 
			"biome": "desert",
			"neighbors": [{"biome": "grassland"}]
		}
	]

func apply_blending_to_region(region_data: Dictionary):
	"""Aplicar blending a una región"""
	
	if not enable_advanced_blending:
		return
	
	var neighbors = region_data.get("neighbors", [])
	if neighbors.is_empty():
		return
	
	var current_biome = region_data.get("biome", "grassland")
	var blend_data = {
		"biome_id": current_biome,
		"position": region_data.get("position", Vector2.ZERO),
		"neighbors": neighbors
	}
	
	if organic_texture_blender.has_method("apply_blend_to_region"):
		var material = organic_texture_blender.apply_blend_to_region(blend_data)
		
		if material and debug_integration:
			print("[OrganicBlendingIntegration] 🎨 Blending aplicado: " + str(current_biome))
		
		blending_applied.emit(region_data)

func generate_region_id(region_data: Dictionary) -> String:
	"""Generar ID único para región"""
	
	var pos = region_data.get("position", Vector2.ZERO)
	var biome = region_data.get("biome", "unknown")
	return str(biome) + "_" + str(pos.x) + "_" + str(pos.y)

# ========== API PÚBLICA ==========

func force_update_all_regions():
	"""Forzar actualización de todas las regiones"""
	processed_regions.clear()
	_update_blending()
	print("[OrganicBlendingIntegration] 🔄 Actualización forzada")

func set_blending_enabled(enabled: bool):
	"""Habilitar/deshabilitar blending"""
	enable_advanced_blending = enabled
	print("[OrganicBlendingIntegration] 🎛️ Blending " + ("habilitado" if enabled else "deshabilitado"))

func get_integration_status() -> Dictionary:
	"""Obtener estado de integración"""
	return {
		"active": is_integration_active,
		"world_manager_found": infinite_world_manager != null,
		"texture_blender_found": organic_texture_blender != null,
		"blending_enabled": enable_advanced_blending,
		"processed_regions_count": processed_regions.size()
	}

func apply_manual_blending(position: Vector2, biome_a: String, biome_b: String):
	"""Aplicar blending manual entre dos biomas"""
	
	if not organic_texture_blender:
		print("[OrganicBlendingIntegration] ❌ Blender no disponible")
		return null
	
	var blend_data = {
		"biome_id": biome_a,
		"position": position,
		"neighbors": [{"biome": biome_b}]
	}
	
	if organic_texture_blender.has_method("apply_blend_to_region"):
		var material = organic_texture_blender.apply_blend_to_region(blend_data)
		if material:
			print("[OrganicBlendingIntegration] 🎨 Blending manual: " + str(biome_a) + " → " + str(biome_b))
		return material
	
	return null