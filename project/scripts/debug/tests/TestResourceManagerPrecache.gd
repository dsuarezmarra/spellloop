# TestResourceManagerPrecache.gd
# Tests unitarios para verificar que el precaching de sprites funciona correctamente
# Esto debe eliminar el stutter de ~100ms por enemigo en el primer spawn

extends Node

const TEST_SPRITE_PATH = "res://assets/sprites/enemies/tier_1/esqueleto_aprendiz_spritesheet.png"

var tests_passed: int = 0
var tests_failed: int = 0
var rm: Node = null  # ResourceManager reference

func _ready() -> void:
	print("\n========================================")
	print("🧪 TESTS: ResourceManager Precache")
	print("========================================\n")
	
	# Obtener ResourceManager
	rm = get_tree().get_first_node_in_group("resource_manager")
	if not rm:
		print("❌ ResourceManager no encontrado en grupo 'resource_manager'")
		print("   Asegúrate de que esté en la escena y se agregue al grupo en _ready()")
		return
	
	# Esperar un frame para que el precache haya terminado
	await get_tree().process_frame
	await get_tree().process_frame
	
	run_all_tests()
	
	print("\n========================================")
	print("📊 RESULTADOS: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

func run_all_tests() -> void:
	test_1_precache_stats_populated()
	test_2_tier1_sprites_cached()
	test_3_regions_have_3_elements()
	test_4_cache_hit_tracking()
	test_5_texture_cache_populated()
	test_6_all_enemy_tiers_cached()

func assert_true(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		print("✅ %s" % test_name)
		tests_passed += 1
	else:
		print("❌ %s" % test_name)
		if details:
			print("   → %s" % details)
		tests_failed += 1

func test_1_precache_stats_populated() -> void:
	"""Verificar que las estadísticas de precarga están pobladas"""
	var stats = rm.get_precache_stats()
	var sprites_processed = stats.get("sprites_processed", 0)
	
	assert_true(
		sprites_processed > 0,
		"Test 1: Precache procesó sprites",
		"sprites_processed=%d (esperado >0)" % sprites_processed
	)

func test_2_tier1_sprites_cached() -> void:
	"""Verificar que al menos un sprite de tier 1 está en cache"""
	var regions = rm.get_cached_regions(TEST_SPRITE_PATH)
	
	assert_true(
		regions.size() > 0,
		"Test 2: Sprite tier_1/esqueleto_aprendiz está precacheado",
		"regions.size()=%d (esperado 3)" % regions.size()
	)

func test_3_regions_have_3_elements() -> void:
	"""Verificar que las regiones tienen exactamente 3 elementos (frente, lado, espalda)"""
	var regions = rm.get_cached_regions(TEST_SPRITE_PATH)
	
	assert_true(
		regions.size() == 3,
		"Test 3: Regiones tienen 3 elementos (frente, lado, espalda)",
		"regions.size()=%d" % regions.size()
	)

func test_4_cache_hit_tracking() -> void:
	"""Verificar que el tracking de cache hits funciona"""
	var stats_before = rm.get_precache_stats()
	var hits_before = stats_before.get("cache_hits", 0)
	
	# Hacer un request que debería ser un cache hit
	var _regions = rm.get_cached_regions(TEST_SPRITE_PATH)
	
	var stats_after = rm.get_precache_stats()
	var hits_after = stats_after.get("cache_hits", 0)
	
	assert_true(
		hits_after > hits_before,
		"Test 4: Cache hits se incrementan correctamente",
		"before=%d, after=%d" % [hits_before, hits_after]
	)

func test_5_texture_cache_populated() -> void:
	"""Verificar que las texturas también están en cache (no solo regiones)"""
	var texture = rm.get_resource(TEST_SPRITE_PATH)
	
	assert_true(
		texture != null,
		"Test 5: Textura está en cache",
		"texture=%s" % str(texture)
	)

func test_6_all_enemy_tiers_cached() -> void:
	"""Verificar que hay sprites de todos los tiers (1-4 + bosses)"""
	var tier_paths = [
		"res://assets/sprites/enemies/tier_1/",
		"res://assets/sprites/enemies/tier_2/",
		"res://assets/sprites/enemies/tier_3/",
		"res://assets/sprites/enemies/tier_4/",
		"res://assets/sprites/enemies/bosses/"
	]
	
	var tiers_with_cache = 0
	for tier_path in tier_paths:
		# Buscar cualquier sprite de este tier en el cache
		for path in rm.sprite_region_cache.keys():
			if path.begins_with(tier_path):
				tiers_with_cache += 1
				break
	
	assert_true(
		tiers_with_cache >= 4,  # Al menos 4 de 5 tiers
		"Test 6: Sprites de múltiples tiers están cacheados",
		"tiers_with_cache=%d (esperado >=4)" % tiers_with_cache
	)
