extends "res://addons/gut/test.gd"
## Smoke tests — verifican que el proyecto arranca sin crashear
## y que los sistemas fundamentales cargan correctamente.

# ─────────────────────────────────────────────────────────────
# 1. Bootstrap mínimo
# ─────────────────────────────────────────────────────────────
func test_project_bootstrap() -> void:
	# Si llegamos aquí sin crash, los autoloads cargaron correctamente
	assert_true(true, "Project bootstrapped without crash")

func test_can_load_main_scene() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if typeof(path) != TYPE_STRING or path.is_empty():
		pending("No main_scene configured")
		return
	var res = load(path)
	assert_not_null(res, "Main scene should load: %s" % path)

func test_can_load_game_scene() -> void:
	var res = load("res://scenes/game/Game.tscn")
	assert_not_null(res, "Game.tscn should load without errors")

# ─────────────────────────────────────────────────────────────
# 2. Autoloads existen y son accesibles
# ─────────────────────────────────────────────────────────────
func test_autoload_game_manager() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	assert_not_null(gm, "GameManager autoload should exist")

func test_autoload_save_manager() -> void:
	var sm = get_tree().root.get_node_or_null("SaveManager")
	assert_not_null(sm, "SaveManager autoload should exist")

func test_autoload_audio_manager() -> void:
	var am = get_tree().root.get_node_or_null("AudioManager")
	assert_not_null(am, "AudioManager autoload should exist")

func test_autoload_ui_manager() -> void:
	var um = get_tree().root.get_node_or_null("UIManager")
	assert_not_null(um, "UIManager autoload should exist")

func test_autoload_vfx_manager() -> void:
	var vm = get_tree().root.get_node_or_null("VFXManager")
	assert_not_null(vm, "VFXManager autoload should exist")

func test_autoload_projectile_pool() -> void:
	var pp = get_tree().root.get_node_or_null("ProjectilePool")
	assert_not_null(pp, "ProjectilePool autoload should exist")

func test_autoload_difficulty_manager() -> void:
	var dm = get_tree().root.get_node_or_null("DifficultyManager")
	assert_not_null(dm, "DifficultyManager autoload should exist")

func test_autoload_spatial_grid() -> void:
	var sg = get_tree().root.get_node_or_null("SpatialGrid")
	assert_not_null(sg, "SpatialGrid autoload should exist")

# ─────────────────────────────────────────────────────────────
# 3. Datos críticos cargan
# ─────────────────────────────────────────────────────────────
func test_spells_json_exists() -> void:
	assert_true(FileAccess.file_exists("res://assets/data/spells.json"),
		"spells.json should exist")

func test_sprites_index_exists() -> void:
	assert_true(FileAccess.file_exists("res://assets/data/sprites_index.json"),
		"sprites_index.json should exist")

func test_weapon_database_loads() -> void:
	# WeaponDatabase es una clase estática/autoload — verificar que se puede referenciar
	var script = load("res://scripts/data/WeaponDatabase.gd")
	assert_not_null(script, "WeaponDatabase.gd should load")

func test_enemy_database_loads() -> void:
	var script = load("res://scripts/data/EnemyDatabase.gd")
	assert_not_null(script, "EnemyDatabase.gd should load")

func test_upgrade_database_loads() -> void:
	var script = load("res://scripts/data/UpgradeDatabase.gd")
	assert_not_null(script, "UpgradeDatabase.gd should load")
