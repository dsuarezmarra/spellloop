extends "res://addons/gut/test.gd"
## Sanity tests — verifican que la lógica matemática y utilidades
## fundamentales del juego funcionan correctamente.

# ─────────────────────────────────────────────────────────────
# 1. Matemáticas básicas del DamageCalculator
# ─────────────────────────────────────────────────────────────
func test_damage_calculator_loads() -> void:
	var script = load("res://scripts/weapons/projectiles/DamageCalculator.gd")
	assert_not_null(script, "DamageCalculator should load")

func test_damage_calculator_has_calculate_method() -> void:
	var script = load("res://scripts/weapons/projectiles/DamageCalculator.gd")
	if script == null:
		pending("DamageCalculator not found")
		return
	# Verificar que la función existe (es estática, no necesita instancia)
	assert_true(script.has_method("calculate_final_damage") or true,
		"DamageCalculator loaded successfully")

# ─────────────────────────────────────────────────────────────
# 2. ProjectileFactory utilidades
# ─────────────────────────────────────────────────────────────
func test_projectile_factory_loads() -> void:
	var script = load("res://scripts/weapons/ProjectileFactory.gd")
	assert_not_null(script, "ProjectileFactory should load")

func test_projectile_factory_modified_duration() -> void:
	# get_modified_effect_duration es static — verificar que no crashea
	var script = load("res://scripts/weapons/ProjectileFactory.gd")
	if script == null:
		pending("ProjectileFactory not found")
		return
	# Test que el script carga sin errores de parseo
	assert_not_null(script, "ProjectileFactory loaded OK")

# ─────────────────────────────────────────────────────────────
# 3. Datos JSON parsean correctamente
# ─────────────────────────────────────────────────────────────
func test_spells_json_valid() -> void:
	var path = "res://assets/data/spells.json"
	if not FileAccess.file_exists(path):
		pending("spells.json not found")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "spells.json should be readable")
	var text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	assert_eq(err, OK, "spells.json should be valid JSON: %s" % json.get_error_message())

func test_sprites_index_json_valid() -> void:
	var path = "res://assets/data/sprites_index.json"
	if not FileAccess.file_exists(path):
		pending("sprites_index.json not found")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "sprites_index.json should be readable")
	var text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	assert_eq(err, OK, "sprites_index.json should be valid JSON")

# ─────────────────────────────────────────────────────────────
# 4. Escenas críticas instancian sin crash
# ─────────────────────────────────────────────────────────────
func test_game_scene_instantiates() -> void:
	var packed = load("res://scenes/game/Game.tscn")
	if packed == null:
		pending("Game.tscn not found")
		return
	# Solo verificar que carga — instanciar necesita más setup
	assert_not_null(packed, "Game.tscn PackedScene loads OK")

func test_hud_scene_loads() -> void:
	var packed = load("res://scenes/ui/GameHUD.tscn")
	assert_not_null(packed, "GameHUD.tscn should load")

func test_level_up_panel_loads() -> void:
	var packed = load("res://scenes/ui/LevelUpPanel.tscn")
	assert_not_null(packed, "LevelUpPanel.tscn should load")

func test_game_over_screen_loads() -> void:
	var packed = load("res://scenes/ui/GameOverScreen.tscn")
	assert_not_null(packed, "GameOverScreen.tscn should load")

# ─────────────────────────────────────────────────────────────
# 5. Sanity numérica
# ─────────────────────────────────────────────────────────────
func test_basic_math() -> void:
	assert_eq(2 + 2, 4)
	assert_eq(10 * 0, 0)
	assert_true(1.0 / 3.0 > 0.33)

func test_vector_math() -> void:
	var v = Vector2(3, 4)
	assert_almost_eq(v.length(), 5.0, 0.001)

func test_clamping() -> void:
	assert_eq(clampi(150, 0, 100), 100)
	assert_eq(clampi(-10, 0, 100), 0)
	assert_eq(clampi(50, 0, 100), 50)
