
extends "res://scripts/enemies/EnemyBase.gd"
class_name SpellloopEnemy

var contact_damage: int = 10
func _physics_process(_delta):
	# Daño por contacto al jugador
	if player_ref and is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) < 18:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(contact_damage)

# Implementación mínima de compatibilidad para resolver Parser Error cuando
# el código llama a SpellloopEnemy.new().
# Esta clase intenta instanciar una escena de enemigo basada en enemy_type.id
# si existe, o usa un fallback genérico.

var enemy_type_id: String = ""

func _get_prop(obj, prop_name: String, default_value = null):
	# Safe property accessor: supports Dictionary or scripted objects
	if obj == null:
		return default_value
	if obj is Dictionary:
		return obj.get(prop_name, default_value)
	# For script instances / Resources, use Object.get(prop_name) which returns null if missing
	# Protect with has_method just in case
	if obj.has_method("get"):
		var v = obj.get(prop_name)
		return v if v != null else default_value
	return default_value

func _ready():
	# Asegurar que el enemigo está en el grupo 'enemies' para interacción con otros sistemas
	if not is_in_group("enemies"):
		add_to_group("enemies")

func initialize(enemy_type, player):
	# Guardar referencias mínimas (usar acceso seguro a propiedades)
	var id_val = _get_prop(enemy_type, "id", null)
	enemy_type_id = id_val if id_val != null else str(enemy_type)
	player_ref = player
	# Assign base fields directly (avoid calling parent initialize)
	enemy_id = enemy_type_id
	max_hp = int(_get_prop(enemy_type, "health", max_hp))
	hp = max_hp
	speed = float(_get_prop(enemy_type, "speed", speed))
	damage = int(_get_prop(enemy_type, "damage", damage))
	exp_value = int(_get_prop(enemy_type, "exp_value", exp_value))
	# Asignar hp si existe
	var health_val = _get_prop(enemy_type, "health", null)
	if health_val != null:
		hp = int(health_val)
	else:
		hp = 10

	# Intentar cargar una escena concreta para este tipo (convention)
	var scene_path = "res://scenes/enemies/%s.tscn" % enemy_type_id
	if ResourceLoader.exists(scene_path):
		var packed = ResourceLoader.load(scene_path)
		if packed and packed is PackedScene:
			var node = packed.instantiate()
			# transferir propiedades al nodo instanciado si es necesario
			if is_instance_valid(node):
				get_parent().add_child(node)
				node.global_position = global_position
				queue_free()
				return

	# Fallback: configurar un sprite/colisión simple si no existe escena
	var color_val = _get_prop(enemy_type, "color", null)
	# Si hay un Sprite2D hijo, aplicar modulate o intentar cargar textura desde SpriteDB
	var sprite_node = get_node_or_null("Sprite2D")
	var anim_node = get_node_or_null("AnimatedSprite2D")
	if sprite_node and color_val != null:
		sprite_node.modulate = color_val
	elif anim_node and color_val != null:
		anim_node.modulate = color_val
	else:
		# Si no hay nodo visual, crear un marcador rojo pequeño (punto)
		var size = 8
		var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(size/2.0, size/2.0)
		for x in range(size):
			for y in range(size):
				var d = Vector2(x,y).distance_to(center)
				if d <= size/2.0:
					img.set_pixel(x,y, Color(0.8, 0.1, 0.1, 1.0))
				else:
					img.set_pixel(x,y, Color(0,0,0,0))
		var tex = ImageTexture.new()
		tex.set_image(img)
		var s = Sprite2D.new()
		s.texture = tex
		add_child(s)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		die()

func die():
	queue_free()

func _on_die_emit():
	emit_signal("enemy_died", self, enemy_type_id, 0)
