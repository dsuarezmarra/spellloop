# CombatSystemIntegration.gd
# Script auxiliar para integrar el nuevo sistema de combate en Game.gd
#
# USO:
# 1. En Game.gd, crear una instancia de este script
# 2. Llamar a setup() con referencias al player y otros sistemas
# 3. El sistema manejará automáticamente armas, fusiones, y level ups

extends Node
class_name CombatSystemIntegration

# Referencias
var player: CharacterBody2D = null
var attack_manager: AttackManager = null
var player_stats: PlayerStats = null
var hud: CanvasLayer = null
var game_root: Node = null

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(game: Node, player_ref: CharacterBody2D) -> void:
	"""
	Configurar el sistema de combate completo
	Llamar desde Game._initialize_systems()
	"""
	game_root = game
	player = player_ref
	
	_create_attack_manager()
	_create_player_stats()
	_connect_signals()
	_give_starting_weapon()
	
	# Debug desactivado: print("[CombatSystem] ✅ Sistema de combate inicializado")

func _create_attack_manager() -> void:
	"""Crear y configurar el AttackManager"""
	attack_manager = AttackManager.new()
	attack_manager.name = "AttackManager"
	game_root.add_child(attack_manager)
	attack_manager.initialize(player)
	
	# Debug desactivado: print("[CombatSystem] ⚔️ AttackManager creado")

func _create_player_stats() -> void:
	"""Crear y configurar PlayerStats"""
	player_stats = PlayerStats.new()
	player_stats.name = "PlayerStats"
	game_root.add_child(player_stats)
	player_stats.initialize(attack_manager, player)  # Pasar player para regeneración
	
	# Debug desactivado: print("[CombatSystem] 📊 PlayerStats creado")

func _connect_signals() -> void:
	"""Conectar señales entre sistemas"""
	# AttackManager signals
	attack_manager.weapon_added.connect(_on_weapon_added)
	attack_manager.weapon_removed.connect(_on_weapon_removed)
	attack_manager.weapon_leveled_up.connect(_on_weapon_leveled_up)
	attack_manager.fusion_available.connect(_on_fusion_available)
	attack_manager.slots_updated.connect(_on_slots_updated)
	
	# PlayerStats signals
	player_stats.level_changed.connect(_on_player_level_changed)
	player_stats.health_changed.connect(_on_player_health_changed)
	player_stats.stat_changed.connect(_on_player_stat_changed)

func _give_starting_weapon() -> void:
	"""Dar arma inicial al jugador"""
	# Empezar con Ice Wand como arma por defecto
	attack_manager.add_weapon_by_id("ice_wand")
	
	# Debug desactivado: print("[CombatSystem] 🎁 Arma inicial equipada: Ice Wand")

# ═══════════════════════════════════════════════════════════════════════════════
# LEVEL UP
# ═══════════════════════════════════════════════════════════════════════════════

func trigger_level_up() -> void:
	"""Mostrar panel de level up"""
	var panel_scene = load("res://scenes/ui/LevelUpPanel.tscn")
	if panel_scene == null:
		# Si no hay escena, crear instancia directa
		_show_level_up_panel_direct()
		return
	
	var panel = panel_scene.instantiate() as LevelUpPanel
	panel.initialize(attack_manager, player_stats)
	
	var ui_layer = game_root.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(panel)
	else:
		game_root.add_child(panel)
	
	panel.show_panel()
	
	# Conectar señales
	panel.option_selected.connect(_on_upgrade_selected)
	panel.panel_closed.connect(_on_level_up_panel_closed)

func _show_level_up_panel_direct() -> void:
	"""Crear panel de level up directamente sin escena"""
	var panel = LevelUpPanel.new()
	panel.initialize(attack_manager, player_stats)
	
	var ui_layer = game_root.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(panel)
	else:
		game_root.add_child(panel)
	
	panel.show_panel()
	panel.option_selected.connect(_on_upgrade_selected)
	panel.panel_closed.connect(_on_level_up_panel_closed)

# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIENCIA Y DAÑO
# ═══════════════════════════════════════════════════════════════════════════════

func gain_experience(amount: float) -> void:
	"""Dar experiencia al jugador"""
	var levels = player_stats.gain_xp(amount)
	
	# Mostrar level up por cada nivel ganado
	for i in range(levels):
		# Pequeño delay entre múltiples level ups
		if i > 0:
			await game_root.get_tree().create_timer(0.5).timeout
		trigger_level_up()

func player_take_damage(amount: float) -> void:
	"""El jugador recibe daño"""
	var effective = player_stats.take_damage(amount)
	
	if player_stats.is_dead():
		_on_player_died()
	
	return effective

func player_heal(amount: float) -> void:
	"""Curar al jugador"""
	player_stats.heal(amount)

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_weapon_added(weapon: BaseWeapon, slot: int) -> void:
	# Debug desactivado: print("[CombatSystem] 🆕 Arma añadida: %s (slot %d)" % [weapon.weapon_name, slot])
	_update_hud_weapons()

func _on_weapon_removed(weapon: BaseWeapon, slot: int) -> void:
	# Debug desactivado: print("[CombatSystem] ❌ Arma removida: %s" % weapon.weapon_name)
	_update_hud_weapons()

func _on_weapon_leveled_up(weapon: BaseWeapon, new_level: int) -> void:
	# Debug desactivado: print("[CombatSystem] ⬆️ %s subió a nivel %d" % [weapon.weapon_name, new_level])
	_update_hud_weapons()

func _on_fusion_available(weapon_a: BaseWeapon, weapon_b: BaseWeapon, result: Dictionary) -> void:
	# Debug desactivado: print("[CombatSystem] 🔥 Fusión disponible: %s + %s = %s" % [
	# Debug desactivado: 	weapon_a.weapon_name, weapon_b.weapon_name, result.get("name", "???")
	# Debug desactivado: ])
	pass

func _on_slots_updated(current: int, max_slots: int) -> void:
	# Debug desactivado: print("[CombatSystem] 📦 Slots: %d/%d" % [current, max_slots])
	_update_hud_slots()

func _on_player_level_changed(new_level: int) -> void:
	# Debug desactivado: print("[CombatSystem] 🎉 ¡Nivel %d alcanzado!" % new_level)
	pass

func _on_player_health_changed(current: float, maximum: float) -> void:
	_update_hud_health(current, maximum)

func _on_player_stat_changed(stat: String, old_val: float, new_val: float) -> void:
	# Debug desactivado: print("[CombatSystem] 📈 %s: %.2f → %.2f" % [stat, old_val, new_val])
	pass

func _on_upgrade_selected(option: Dictionary) -> void:
	# Debug desactivado: print("[CombatSystem] Upgrade seleccionado")
	pass

func _on_level_up_panel_closed() -> void:
	# Debug desactivado: print("[CombatSystem] Panel de level up cerrado")
	pass

func _on_player_died() -> void:
	# Debug desactivado: print("[CombatSystem] Player murió")
	# Emitir señal al Game para game over
	if game_root.has_signal("game_over"):
		game_root.game_over.emit()

# ═══════════════════════════════════════════════════════════════════════════════
# HUD UPDATES
# ═══════════════════════════════════════════════════════════════════════════════

func set_hud(hud_ref: CanvasLayer) -> void:
	"""Establecer referencia al HUD"""
	hud = hud_ref

func _update_hud_health(current: float, maximum: float) -> void:
	if hud and hud.has_method("update_health"):
		hud.update_health(current, maximum)

func _update_hud_weapons() -> void:
	if hud and hud.has_method("update_weapons"):
		var info = attack_manager.get_info()
		hud.update_weapons(info)

func _update_hud_slots() -> void:
	if hud and hud.has_method("update_weapon_slots"):
		hud.update_weapon_slots(attack_manager.current_weapon_count, attack_manager.max_weapon_slots)

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

func get_attack_manager() -> AttackManager:
	return attack_manager

func get_player_stats() -> PlayerStats:
	return player_stats

func print_debug_info() -> void:
	"""Imprimir información de debug de todos los sistemas"""
	# print("\n" + "=" * 60)
	# print(attack_manager.get_debug_info())
	# print("")
	# print(player_stats.get_debug_info())
	# print("=" * 60 + "\n")

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func save_state() -> Dictionary:
	"""Guardar estado del sistema de combate"""
	return {
		"attack_manager": attack_manager.to_dict(),
		"player_stats": player_stats.to_dict()
	}

func load_state(data: Dictionary) -> void:
	"""Restaurar estado del sistema de combate"""
	if data.has("attack_manager"):
		attack_manager.from_dict(data.attack_manager)
	if data.has("player_stats"):
		player_stats.from_dict(data.player_stats)
