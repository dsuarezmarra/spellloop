# CombatSystemMonitor.gd
# Monitorea el sistema de combate en tiempo real
# Muestra información de armas, proyectiles, etc.

# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: CombatSystemMonitor.gd - Monitor del sistema de combate en UI
# Razón: Cargado dinámicamente desde SpellloopGame pero es principalmente para debugging

extends CanvasLayer
class_name CombatSystemMonitor

var enabled: bool = true
var font: Font = null
var update_interval: float = 0.1
var time_since_update: float = 0.0

var label: Label = null

func _ready() -> void:
	name = "CombatSystemMonitor"
	layer = 150  # Encima de todo
	
	# Crear label
	label = Label.new()
	label.name = "MonitorLabel"
	add_child(label)
	
	# Configurar posición y estilo
	label.anchor_left = 1.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 0.0
	label.offset_left = -400
	label.offset_top = 10
	label.offset_right = -10
	label.offset_bottom = 300
	
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.custom_minimum_size = Vector2(400, 300)
	label.modulate = Color.WHITE
	
	set_process(true)

func _process(delta: float) -> void:
	if not enabled or not label:
		return
	
	time_since_update += delta
	if time_since_update < update_interval:
		return
	
	time_since_update = 0.0
	update_monitor()

func update_monitor() -> void:
	"""Actualizar la información del monitor"""
	var text = ""
	
	# Obtener GameManager
	var gm = get_tree().root.get_node_or_null("GameManager")
	if not gm:
		label.text = "⚠️ GameManager not found"
		return
	
	text += "🎮 COMBAT MONITOR\n"
	var sep = ""
	for i in range(30):
		sep += "─"
	text += sep + "\n"
	
	# Estado del juego
	text += "Run Active: %s\n" % ("✓" if gm.is_run_active else "✗")
	
	# AttackManager info
	if gm.attack_manager:
		text += "AttackManager: ✓\n"
		text += "  Active: %s\n" % ("✓" if gm.attack_manager.is_active else "✗")
		text += "  Player: %s\n" % ("✓" if gm.attack_manager.player else "✗")
		text += "  Weapons: %d\n" % gm.attack_manager.get_weapon_count()
		
		# Detalles de armas
		if gm.attack_manager.get_weapon_count() > 0:
			for weapon in gm.attack_manager.get_weapons():
				text += "\n  🗡️ %s\n" % weapon.name
				text += "    Damage: %d\n" % weapon.damage
				text += "    Cooldown: %.2f/%.2f\n" % [weapon.current_cooldown, weapon.base_cooldown]
				text += "    Ready: %s\n" % ("✓" if weapon.is_ready_to_fire() else "✗")
				text += "    Projectile: %s\n" % ("✓" if weapon.projectile_scene else "✗")
		else:
			text += "\n  ⚠️  NO WEAPONS EQUIPPED!\n"
	else:
		text += "AttackManager: ✗\n"
	
	label.text = text

func toggle() -> void:
	"""Alternar monitor on/off"""
	enabled = not enabled
	if label:
		label.visible = enabled
