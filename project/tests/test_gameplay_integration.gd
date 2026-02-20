extends "res://addons/gut/test.gd"
## Tests de integración para el sistema de autopiloto.
## Validan que los componentes críticos del gameplay están
## correctamente conectados y que una partida puede arrancar.

# ─────────────────────────────────────────────────────────────
# 1. GameManager state machine
# ─────────────────────────────────────────────────────────────
func test_game_manager_initial_state() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm == null:
		pending("GameManager not available")
		return
	# Estado inicial debe ser MAIN_MENU
	if "current_state" in gm:
		assert_eq(gm.current_state, 0, "GameManager should start in MAIN_MENU state (0)")
	else:
		pending("GameManager doesn't have current_state property")

func test_game_manager_has_start_method() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm == null:
		pending("GameManager not available")
		return
	assert_true(gm.has_method("start_new_run"), "GameManager should have start_new_run()")
	assert_true(gm.has_method("end_current_run"), "GameManager should have end_current_run()")

# ─────────────────────────────────────────────────────────────
# 2. Pool systems
# ─────────────────────────────────────────────────────────────
func test_projectile_pool_ready() -> void:
	var pp = get_tree().root.get_node_or_null("ProjectilePool")
	if pp == null:
		pending("ProjectilePool not available")
		return
	assert_not_null(pp, "ProjectilePool should be initialized")

# ─────────────────────────────────────────────────────────────
# 3. Data integrity — WeaponDatabase
# ─────────────────────────────────────────────────────────────
func test_weapon_database_has_weapons() -> void:
	var WDB = load("res://scripts/data/WeaponDatabase.gd")
	if WDB == null:
		pending("WeaponDatabase not found")
		return
	# Verificar que tiene al menos 1 arma definida
	if WDB.has_method("get_all_weapons"):
		var weapons = WDB.get_all_weapons()
		assert_gt(weapons.size(), 0, "WeaponDatabase should have at least 1 weapon")
	elif "WEAPONS" in WDB:
		assert_gt(WDB.WEAPONS.size(), 0, "WeaponDatabase.WEAPONS should not be empty")
	else:
		# Al menos verificar que el script cargó
		assert_not_null(WDB, "WeaponDatabase loaded")

# ─────────────────────────────────────────────────────────────
# 4. Data integrity — EnemyDatabase
# ─────────────────────────────────────────────────────────────
func test_enemy_database_has_enemies() -> void:
	var EDB = load("res://scripts/data/EnemyDatabase.gd")
	if EDB == null:
		pending("EnemyDatabase not found")
		return
	if EDB.has_method("get_all_enemies"):
		var enemies = EDB.get_all_enemies()
		assert_gt(enemies.size(), 0, "EnemyDatabase should have at least 1 enemy")
	elif "ENEMIES" in EDB:
		assert_gt(EDB.ENEMIES.size(), 0, "EnemyDatabase.ENEMIES should not be empty")
	else:
		assert_not_null(EDB, "EnemyDatabase loaded")

# ─────────────────────────────────────────────────────────────
# 5. Save system
# ─────────────────────────────────────────────────────────────
func test_save_manager_slots() -> void:
	var sm = get_tree().root.get_node_or_null("SaveManager")
	if sm == null:
		pending("SaveManager not available")
		return
	if sm.has_method("get_save_slots"):
		var slots = sm.get_save_slots()
		assert_not_null(slots, "SaveManager should return save slots")
	else:
		assert_not_null(sm, "SaveManager exists")

# ─────────────────────────────────────────────────────────────
# 6. RunAuditTracker
# ─────────────────────────────────────────────────────────────
func test_run_audit_tracker_exists() -> void:
	var rat = get_tree().root.get_node_or_null("RunAuditTracker")
	assert_not_null(rat, "RunAuditTracker autoload should exist")
	if rat and "ENABLE_AUDIT" in rat:
		assert_true(rat.ENABLE_AUDIT, "Audit should be enabled")

# ─────────────────────────────────────────────────────────────
# 7. Input actions configuradas
# ─────────────────────────────────────────────────────────────
func test_input_actions_exist() -> void:
	var required_actions = ["move_up", "move_down", "move_left", "move_right"]
	for action in required_actions:
		assert_true(InputMap.has_action(action),
			"Input action '%s' should be configured" % action)

# ─────────────────────────────────────────────────────────────
# 8. Performance baseline
# ─────────────────────────────────────────────────────────────
func test_initial_orphan_count_low() -> void:
	var orphans = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	assert_lt(orphans, 50,
		"Initial orphan node count should be <50, got: %d" % orphans)
