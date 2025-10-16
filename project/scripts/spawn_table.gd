extends Node
# Sistema de Spawn por Tramos - Spellloop
# Maneja spawns de enemigos por packs de 2 tipos según minutos transcurridos

# Definición de tiers y sus enemigos
var tier_definitions = {
	1: {  # 0-5 minutos
		"time_range": [0, 5],
		"enemies": [
			"enemy_tier_1_slime_novice",
			"enemy_tier_1_goblin_scout", 
			"enemy_tier_1_skeleton_warrior",
			"enemy_tier_1_shadow_bat",
			"enemy_tier_1_poison_spider"
		],
		"base_spawn_count": 30,
		"spawn_rate": 0.8,
		"special_variant_chance": 0.05
	},
	2: {  # 5-10 minutos
		"time_range": [5, 10],
		"enemies": [
			"enemy_tier_2_fire_imp",
			"enemy_tier_2_ice_golem",
			"enemy_tier_2_shadow_assassin",
			"enemy_tier_2_wind_elemental",
			"enemy_tier_2_earth_guardian"
		],
		"base_spawn_count": 45,
		"spawn_rate": 0.7,
		"special_variant_chance": 0.08
	},
	3: {  # 10-15 minutos
		"time_range": [10, 15],
		"enemies": [
			"enemy_tier_3_demon_warrior",
			"enemy_tier_3_crystal_mage",
			"enemy_tier_3_void_stalker",
			"enemy_tier_3_nature_beast",
			"enemy_tier_3_lightning_wraith"
		],
		"base_spawn_count": 60,
		"spawn_rate": 0.6,
		"special_variant_chance": 0.12
	},
	4: {  # 15-20 minutos
		"time_range": [15, 20],
		"enemies": [
			"enemy_tier_4_chaos_lord",
			"enemy_tier_4_arcane_construct",
			"enemy_tier_4_death_knight",
			"enemy_tier_4_phoenix_rider",
			"enemy_tier_4_time_weaver"
		],
		"base_spawn_count": 75,
		"spawn_rate": 0.5,
		"special_variant_chance": 0.15
	},
	5: {  # 20-25 minutos
		"time_range": [20, 25],
		"enemies": [
			"enemy_tier_5_reality_ripper",
			"enemy_tier_5_cosmic_horror",
			"enemy_tier_5_void_emperor",
			"enemy_tier_5_dimension_lord",
			"enemy_tier_5_existence_ender"
		],
		"base_spawn_count": 90,
		"spawn_rate": 0.4,
		"special_variant_chance": 0.20
	}
}

# Definición de bosses por minuto
var boss_schedule = {
	5: "boss_5min_archmage_corrupt",
	10: "boss_10min_elemental_titan",
	15: "boss_15min_void_overlord",
	20: "boss_20min_chaos_incarnate",
	25: "boss_25min_reality_destroyer"
}

# Packs activos por tier (combinaciones de 2 tipos)
var tier_spawn_packs = {
	1: [
		{"types": ["enemy_tier_1_slime_novice", "enemy_tier_1_goblin_scout"], "weight": 25},
		{"types": ["enemy_tier_1_skeleton_warrior", "enemy_tier_1_shadow_bat"], "weight": 20},
		{"types": ["enemy_tier_1_poison_spider", "enemy_tier_1_slime_novice"], "weight": 18},
		{"types": ["enemy_tier_1_goblin_scout", "enemy_tier_1_skeleton_warrior"], "weight": 22},
		{"types": ["enemy_tier_1_shadow_bat", "enemy_tier_1_poison_spider"], "weight": 15}
	],
	2: [
		{"types": ["enemy_tier_2_fire_imp", "enemy_tier_2_ice_golem"], "weight": 30},
		{"types": ["enemy_tier_2_shadow_assassin", "enemy_tier_2_wind_elemental"], "weight": 25},
		{"types": ["enemy_tier_2_earth_guardian", "enemy_tier_2_fire_imp"], "weight": 20},
		{"types": ["enemy_tier_2_ice_golem", "enemy_tier_2_shadow_assassin"], "weight": 15},
		{"types": ["enemy_tier_2_wind_elemental", "enemy_tier_2_earth_guardian"], "weight": 10}
	],
	3: [
		{"types": ["enemy_tier_3_demon_warrior", "enemy_tier_3_crystal_mage"], "weight": 28},
		{"types": ["enemy_tier_3_void_stalker", "enemy_tier_3_nature_beast"], "weight": 24},
		{"types": ["enemy_tier_3_lightning_wraith", "enemy_tier_3_demon_warrior"], "weight": 22},
		{"types": ["enemy_tier_3_crystal_mage", "enemy_tier_3_void_stalker"], "weight": 16},
		{"types": ["enemy_tier_3_nature_beast", "enemy_tier_3_lightning_wraith"], "weight": 10}
	],
	4: [
		{"types": ["enemy_tier_4_chaos_lord", "enemy_tier_4_arcane_construct"], "weight": 26},
		{"types": ["enemy_tier_4_death_knight", "enemy_tier_4_phoenix_rider"], "weight": 24},
		{"types": ["enemy_tier_4_time_weaver", "enemy_tier_4_chaos_lord"], "weight": 20},
		{"types": ["enemy_tier_4_arcane_construct", "enemy_tier_4_death_knight"], "weight": 18},
		{"types": ["enemy_tier_4_phoenix_rider", "enemy_tier_4_time_weaver"], "weight": 12}
	],
	5: [
		{"types": ["enemy_tier_5_reality_ripper", "enemy_tier_5_cosmic_horror"], "weight": 30},
		{"types": ["enemy_tier_5_void_emperor", "enemy_tier_5_dimension_lord"], "weight": 28},
		{"types": ["enemy_tier_5_existence_ender", "enemy_tier_5_reality_ripper"], "weight": 22},
		{"types": ["enemy_tier_5_cosmic_horror", "enemy_tier_5_void_emperor"], "weight": 12},
		{"types": ["enemy_tier_5_dimension_lord", "enemy_tier_5_existence_ender"], "weight": 8}
	]
}

# Variables de estado
var current_tier: int = 1
var entities_on_screen: int = 0
var max_entities_cap: int = 100
var spawn_timer: float = 0.0
var boss_spawned_minutes: Array = []

# Referencias
var game_manager: Node
var world_manager: Node

func _ready():
	game_manager = get_node("/root/GameManager")
	# Buscar world_manager con más flexibilidad
	world_manager = get_tree().current_scene.get_node_or_null("InfiniteWorldManager")
	if not world_manager:
		world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	if not world_manager:
		push_warning("[SpawnTable] No se encontró InfiniteWorldManager o WorldManager")

func _process(delta):
	spawn_timer += delta
	
	var current_minute = get_elapsed_minutes()
	update_current_tier(current_minute)
	
	# Verificar spawn de boss
	check_boss_spawn(current_minute)
	
	# Gestionar spawn de enemigos regulares
	if spawn_timer >= get_current_spawn_rate():
		spawn_enemy_wave()
		spawn_timer = 0.0

func get_elapsed_minutes() -> int:
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		return game_manager.get_elapsed_minutes()
	return 0

func update_current_tier(minute: int):
	for tier in tier_definitions.keys():
		var time_range = tier_definitions[tier].time_range
		if minute >= time_range[0] and minute < time_range[1]:
			current_tier = tier
			break
	
	# Para minutos 25+, mantener tier 5
	if minute >= 25:
		current_tier = 5

func check_boss_spawn(minute: int):
	if minute in boss_schedule.keys() and not minute in boss_spawned_minutes:
		spawn_boss(boss_schedule[minute])
		boss_spawned_minutes.append(minute)

func spawn_boss(boss_slug: String):
	var boss_script_path = "res://scripts/bosses/" + boss_slug + ".gd"
	var boss_script = load(boss_script_path)
	
	if boss_script:
		var boss = Node2D.new()
		boss.set_script(boss_script)
		
		if world_manager:
			world_manager.add_child(boss)
			
			# Posición aleatoria cerca del jugador pero no muy cerca
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var angle = randf() * 2 * PI
				var distance = randf_range(300.0, 500.0)
				var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
				boss._on_spawn(spawn_pos)

func spawn_enemy_wave():
	if entities_on_screen >= max_entities_cap:
		return
	
	var spawn_pack = get_spawn_pack(current_tier)
	if not spawn_pack:
		return
	
	var tier_def = tier_definitions[current_tier]
	var wave_size = calculate_wave_size(tier_def.base_spawn_count)
	
	# Distribuir spawns entre los 2 tipos del pack
	var type1_count = wave_size / 2
	var type2_count = wave_size - type1_count
	
	# Spawn tipo 1
	spawn_enemies_of_type(spawn_pack.types[0], type1_count, tier_def.special_variant_chance)
	
	# Spawn tipo 2
	spawn_enemies_of_type(spawn_pack.types[1], type2_count, tier_def.special_variant_chance)

func get_spawn_pack(tier: int):
	var packs = tier_spawn_packs.get(tier, [])
	if packs.is_empty():
		return null
	
	var total_weight = 0.0
	for pack in packs:
		total_weight += pack.weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for pack in packs:
		current_weight += pack.weight
		if random_value <= current_weight:
			return pack
	
	return packs[0]  # Fallback

func spawn_enemies_of_type(enemy_slug: String, count: int, special_chance: float):
	for i in range(count):
		if entities_on_screen >= max_entities_cap:
			break
		
		var is_special = randf() < special_chance
		spawn_single_enemy(enemy_slug, is_special)

func spawn_single_enemy(enemy_slug: String, is_special_variant: bool = false):
	var enemy_script_path = "res://scripts/enemies/" + enemy_slug + ".gd"
	var enemy_script = load(enemy_script_path)
	
	if enemy_script and world_manager:
		var enemy = Node2D.new()
		enemy.set_script(enemy_script)
		enemy.is_special_variant = is_special_variant
		
		world_manager.add_child(enemy)
		
		# Posición de spawn aleatoria fuera de la pantalla
		var spawn_pos = get_random_spawn_position()
		enemy._on_spawn(spawn_pos)
		
		entities_on_screen += 1
		
		# Conectar señal de muerte para decrementar contador
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)

func get_random_spawn_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return Vector2.ZERO
	
	var screen_size = get_viewport().size
	var spawn_distance = max(screen_size.x, screen_size.y) * 0.6
	
	# Elegir lado aleatorio (arriba, abajo, izquierda, derecha)
	var side = randi() % 4
	var spawn_pos = player.global_position
	
	match side:
		0:  # Arriba
			spawn_pos += Vector2(randf_range(-spawn_distance, spawn_distance), -spawn_distance)
		1:  # Derecha
			spawn_pos += Vector2(spawn_distance, randf_range(-spawn_distance, spawn_distance))
		2:  # Abajo
			spawn_pos += Vector2(randf_range(-spawn_distance, spawn_distance), spawn_distance)
		3:  # Izquierda
			spawn_pos += Vector2(-spawn_distance, randf_range(-spawn_distance, spawn_distance))
	
	return spawn_pos

func calculate_wave_size(base_count: int) -> int:
	var minute = get_elapsed_minutes()
	var scale_factor = 1.0 + (minute * 0.1)  # 10% más enemigos por minuto
	var wave_size = int(base_count * scale_factor)
	
	# Limitar para no sobrecargar
	return min(wave_size, max_entities_cap - entities_on_screen)

func get_current_spawn_rate() -> float:
	var tier_def = tier_definitions.get(current_tier, tier_definitions[1])
	return tier_def.spawn_rate

func _on_enemy_died():
	entities_on_screen = max(0, entities_on_screen - 1)

# Funciones públicas para obtener información
func get_enemy_list_for_tier(tier: int) -> Array:
	var tier_def = tier_definitions.get(tier, {})
	return tier_def.get("enemies", [])

func get_current_tier_info() -> Dictionary:
	return tier_definitions.get(current_tier, {})

func get_entities_count() -> int:
	return entities_on_screen

func force_spawn_enemy(enemy_slug: String, position: Vector2):
	"""Función para forzar spawn de enemigo específico (para testing)"""
	spawn_single_enemy(enemy_slug, false)

func clear_all_enemies():
	"""Limpia todos los enemigos de la pantalla"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("queue_free"):
			enemy.queue_free()
	entities_on_screen = 0

# Balance testing functions
func get_estimated_xp_per_minute() -> int:
	var tier_def = tier_definitions.get(current_tier, {})
	var base_count = tier_def.get("base_spawn_count", 30)
	var spawn_rate = tier_def.get("spawn_rate", 1.0)
	
	# Estimación: enemigos por minuto * XP promedio por enemigo
	var enemies_per_minute = (60.0 / spawn_rate) * (base_count / 60.0)
	var avg_xp_per_enemy = 3 + (current_tier * 2)  # Estimación
	
	return int(enemies_per_minute * avg_xp_per_enemy)

func get_expected_entity_count() -> int:
	return min(max_entities_cap, entities_on_screen + 20)  # Estimación conservadora
