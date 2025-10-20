extends Node2D
class_name ItemDrop

signal item_collected(item_drop: Node2D, item_type: String)

var item_type: String
var item_rarity: int = 0  # ItemsDefinitions.ItemRarity.WHITE (numeric fallback)
var collection_range: float = 40.0
var lifetime: float = 60.0
var life_timer: float = 0.0

var sprite: Sprite2D
var player_ref: CharacterBody2D
var aura: Node2D

func initialize(drop_position: Vector2, type: String, player: CharacterBody2D, rarity: int = 0):
	global_position = drop_position
	item_type = type
	item_rarity = rarity
	player_ref = player
	z_index = 45
	
	setup_visual()

func setup_visual():
	"""Configurar apariencia del item"""
	sprite = Sprite2D.new()
	add_child(sprite)
	
	create_item_texture()
	
	var scale_factor = 0.8
	var sm = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ScaleManager"):
		sm = get_tree().root.get_node("ScaleManager")
	if sm and sm.has_method("get_scale"):
		scale_factor *= sm.get_scale()
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# ✨ Agregar aura según rareza del item (proteger en caso de falta de recursos)
	var AuraClass = load("res://scripts/effects/AuraEffect.gd")
	if AuraClass:
		aura = AuraClass.new()
		if aura:
			add_child(aura)
			if aura.has_method("initialize"):
				aura.initialize(sprite, item_rarity, false)  # false = usar color según rareza

			# Aplicar configuración si existe
			var AuraConfig = load("res://scripts/effects/AuraConfiguration.gd")
			if AuraConfig and AuraConfig.has("CHEST_AURA_RADIUS") == false:
				# Algunos shims pueden exponer constantes de forma distinta; protegemos por si acaso
				pass
			if AuraConfig and aura:
				if AuraConfig.has("ITEM_AURA_RADIUS"):
					aura.set_aura_radius(AuraConfig.ITEM_AURA_RADIUS)
				if AuraConfig.has("ITEM_PULSE_INTENSITY"):
					aura.set_pulse_intensity(AuraConfig.ITEM_PULSE_INTENSITY)
	
	# Efecto de flotación
	start_floating_effect()

func create_item_texture():
	"""Crear textura del item como estrella con color de rareza"""
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Color basado en rareza
	var rarity_color = Color(1,1,1)
	var items_defs = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ItemsDefinitions"):
		items_defs = get_tree().root.get_node("ItemsDefinitions")
	if items_defs and items_defs.has_method("get_rarity_color"):
		rarity_color = items_defs.get_rarity_color(item_rarity)
	
	# Crear forma de estrella
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# Puntos de la estrella (5 puntas)
	var star_points = []
	for i in range(10):  # 5 puntas exteriores + 5 interiores
		var angle = (i * PI / 5) - PI / 2  # Empezar desde arriba
		var radius = 6 if i % 2 == 0 else 3  # Alternar radio grande/pequeño
		var point = center + Vector2(cos(angle) * radius, sin(angle) * radius)
		star_points.append(point)
	
	# Rellenar la estrella
	for x in range(size):
		for y in range(size):
			var point = Vector2(x, y)
			if is_point_in_star(point, star_points):
				# Efecto de degradado desde el centro
				var distance_from_center = point.distance_to(center)
				var intensity = 1.0 - (distance_from_center / 7.0)
				intensity = max(0.3, intensity)
				
				var color = rarity_color * intensity
				color.a = 0.9
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func is_point_in_star(point: Vector2, star_points: Array) -> bool:
	"""Verificar si un punto está dentro de la estrella"""
	# Algoritmo simple de ray casting para polígono
	var intersections = 0
	var n = star_points.size()
	
	for i in range(n):
		var p1 = star_points[i]
		var p2 = star_points[(i + 1) % n]
		
		if ((p1.y > point.y) != (p2.y > point.y)) and \
		   (point.x < (p2.x - p1.x) * (point.y - p1.y) / (p2.y - p1.y) + p1.x):
			intersections += 1
	
	return intersections % 2 == 1

func start_floating_effect():
	"""Efecto de flotación"""
	var tween = create_tween()
	
	tween.tween_property(sprite, "position", Vector2(0, -8), 1.5)
	tween.tween_property(sprite, "position", Vector2(0, 8), 1.5)
	tween.set_loops()

func _process(delta):
	life_timer += delta
	
	# Verificar recolección
	if player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		if distance <= collection_range:
			collect_item()
	
	# Desaparecer después del tiempo de vida
	if life_timer >= lifetime:
		queue_free()

func collect_item():
	"""Recolectar item"""
	item_collected.emit(self, item_type)
	queue_free()

