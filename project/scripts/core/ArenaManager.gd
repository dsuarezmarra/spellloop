# ArenaManager.gd
# Sistema de arena acotada con zonas de dificultad y biomas aleatorios
# Diseñado para juegos estilo Vampire Survivors / Brotato
#
# Características:
# - Mapa circular acotado con límites físicos
# - 4 zonas concéntricas de dificultad creciente
# - Biomas aleatorios por zona (se eligen al inicio de cada partida)
# - Barrera visual y daño al salir del área
# - Seed aleatorio para reproducibilidad

extends Node2D
class_name ArenaManager

# === SIGNALS ===
signal arena_ready(arena_data: Dictionary)
signal player_zone_changed(zone_id: int, zone_name: String)
signal player_hit_boundary(damage: float)

# === ENUMS ===
enum ZoneType {
	SAFE,       # Centro - spawn del player, enemigos débiles
	MEDIUM,     # Anillo medio - enemigos normales
	DANGER,     # Anillo exterior - enemigos fuertes
	DEATH       # Borde - daño al player, spawns de élite
}

# === CONFIGURACIÓN DE ARENA ===
@export_group("Arena Size")
@export var arena_radius: float = 10000.0  # Radio total del mapa (20,000 px diámetro)
@export var safe_zone_radius: float = 2500.0  # Radio de zona segura (25% del total)
@export var medium_zone_radius: float = 5500.0  # Radio de zona media (55% del total)
@export var danger_zone_radius: float = 8500.0  # Radio de zona peligrosa (85% del total)
# Death zone: desde danger_zone_radius hasta arena_radius

@export_group("Boundary")
@export var boundary_thickness: float = 200.0  # Grosor de la barrera visual
@export var boundary_damage_per_second: float = 10.0  # Daño por segundo fuera del área
@export var boundary_push_force: float = 500.0  # Fuerza para empujar al player hacia dentro

@export_group("Visuals")
@export var draw_zone_boundaries: bool = true  # Dibujar límites de zonas (debug)
@export var zone_alpha: float = 0.15  # Transparencia de las zonas

@export_group("Seed")
@export var use_random_seed: bool = true
@export var fixed_seed: int = 0  # Solo si use_random_seed = false

# === BIOMAS POR ZONA ===
# Cada zona puede tener varios biomas posibles (se elige 1 al azar por partida)
const BIOMES_BY_ZONE = {
	ZoneType.SAFE: ["Grassland", "Forest"],
	ZoneType.MEDIUM: ["Desert", "Snow"],
	ZoneType.DANGER: ["Lava", "ArcaneWastes"],
	ZoneType.DEATH: ["Death"]  # Siempre Death para el borde
}

# Colores de fallback por bioma (si no hay textura)
const BIOME_COLORS = {
	"Grassland": Color(0.34, 0.68, 0.35),
	"Forest": Color(0.15, 0.35, 0.15),
	"Desert": Color(0.87, 0.78, 0.6),
	"Snow": Color(0.9, 0.92, 0.95),
	"Lava": Color(0.4, 0.1, 0.05),
	"ArcaneWastes": Color(0.4, 0.2, 0.5),
	"Death": Color(0.1, 0.08, 0.08)
}

# === ESTADO ===
var arena_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Biomas seleccionados para esta partida
var selected_biomes: Dictionary = {}  # ZoneType -> String (biome name)

# Referencias
var player_ref: Node2D = null
var arena_root: Node2D = null  # Nodo donde se renderizan las zonas

# Estado del player
var player_current_zone: ZoneType = ZoneType.SAFE
var player_outside_arena: bool = false

# === SISTEMA DE BARRERAS ENTRE ZONAS ===
# Zonas desbloqueadas (SAFE siempre desbloqueada)
var unlocked_zones: Dictionary = {
	ZoneType.SAFE: true,
	ZoneType.MEDIUM: false,
	ZoneType.DANGER: false,
	ZoneType.DEATH: false
}

# Tiempo de juego para desbloquear cada zona (en segundos)
const ZONE_UNLOCK_TIMES: Dictionary = {
	ZoneType.MEDIUM: 300.0,  # 5 minutos
	ZoneType.DANGER: 600.0,  # 10 minutos
	ZoneType.DEATH: 900.0    # 15 minutos
}

# Nodos de barreras físicas
var zone_barriers: Dictionary = {}  # ZoneType -> StaticBody2D

# Señales adicionales
signal zone_unlocked(zone_type: int, zone_name: String)

# Texturas cargadas
var biome_textures: Dictionary = {}  # biome_name -> {base: Texture, decor: [Texture]}

# Nodos visuales
var zone_sprites: Array[Node2D] = []
var boundary_node: Node2D = null

func _ready() -> void:
	print("🏟️ [ArenaManager] Inicializando...")

func initialize(player: Node2D, root: Node2D, resume_seed: int = -1) -> void:
	"""Inicializar la arena con un player y nodo raíz
	   resume_seed: -1 = generar nuevo seed, otro valor = usar ese seed (para reanudar partida)"""
	player_ref = player
	arena_root = root
	
	# Generar o usar seed proporcionado
	if resume_seed >= 0:
		# Usar seed de partida guardada
		arena_seed = resume_seed
		print("🏟️ [ArenaManager] Usando seed de partida guardada: %d" % arena_seed)
	elif use_random_seed:
		randomize()
		arena_seed = randi()
	else:
		arena_seed = fixed_seed
	
	rng.seed = arena_seed
	print("🏟️ [ArenaManager] Seed: %d" % arena_seed)
	
	# Seleccionar biomas aleatorios para cada zona
	_select_random_biomes()
	
	# Cargar texturas de biomas
	_load_biome_textures()
	
	# Generar la arena visual
	_generate_arena()
	
	# Crear barrera del borde
	_create_boundary()
	
	# Crear barreras físicas entre zonas
	_create_zone_barriers()
	
	# Emitir señal de arena lista
	var arena_data = get_arena_info()
	arena_ready.emit(arena_data)
	
	print("🏟️ [ArenaManager] ✅ Arena generada")
	print("   - Safe Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.SAFE], safe_zone_radius])
	print("   - Medium Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.MEDIUM], medium_zone_radius])
	print("   - Danger Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.DANGER], danger_zone_radius])
	print("   - Death Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.DEATH], arena_radius])
	print("   - 🚧 Barreras creadas: MEDIUM, DANGER, DEATH (bloqueadas)")

func _select_random_biomes() -> void:
	"""Seleccionar un bioma aleatorio para cada zona"""
	for zone_type in BIOMES_BY_ZONE.keys():
		var possible_biomes = BIOMES_BY_ZONE[zone_type]
		var selected_index = rng.randi() % possible_biomes.size()
		selected_biomes[zone_type] = possible_biomes[selected_index]
	
	print("🎲 [ArenaManager] Biomas seleccionados:")
	for zone_type in selected_biomes.keys():
		print("   - Zone %d: %s" % [zone_type, selected_biomes[zone_type]])

func _load_biome_textures() -> void:
	"""Cargar texturas estáticas seamless para los biomas seleccionados"""
	for zone_type in selected_biomes.keys():
		var biome_name = selected_biomes[zone_type]
		if biome_textures.has(biome_name):
			continue  # Ya cargado
		
		# === CARGAR TEXTURA BASE ESTÁTICA (seamless) ===
		var base_texture: Texture2D = null
		var biome_lower = biome_name.to_lower()
		var base_path = "res://assets/textures/biomes/%s/base/%s_base_seamless.png" % [biome_name, biome_lower]
		
		# Primero intentar carga manual directa con Image (evita problemas de .import corruptos)
		var abs_path = ProjectSettings.globalize_path(base_path)
		print("🔍 [ArenaManager] Intentando cargar %s desde: %s" % [biome_name, abs_path])
		
		var img = Image.new()
		var load_err = img.load(abs_path)
		if load_err == OK:
			print("🔍 [ArenaManager] Image.load() OK para %s (size: %dx%d)" % [biome_name, img.get_width(), img.get_height()])
			base_texture = ImageTexture.create_from_image(img)
			if base_texture:
				print("✅ [ArenaManager] Textura cargada desde archivo: %s" % biome_name)
			else:
				print("❌ [ArenaManager] ImageTexture.create_from_image falló para %s" % biome_name)
		else:
			print("❌ [ArenaManager] Image.load() falló para %s (error: %d)" % [biome_name, load_err])
			# Fallback: intentar con ResourceLoader (texturas ya importadas correctamente)
			if ResourceLoader.exists(base_path):
				base_texture = load(base_path)
				if base_texture:
					print("📦 [ArenaManager] Textura cargada desde recursos: %s" % biome_name)
		
		# === CARGAR DECORACIONES ANIMADAS ===
		var decor_paths: Array[String] = []
		
		# Guardar paths COMPLETOS de los spritesheets de decoraciones
		for i in range(1, 12):  # decor1 a decor11
			var decor_path = "res://assets/textures/biomes/%s/decor/%s_decor%d_sheet_f8_256.png" % [biome_name, biome_lower, i]
			if ResourceLoader.exists(decor_path):
				decor_paths.append(decor_path)
		
		biome_textures[biome_name] = {
			"base": base_texture,
			"decor_paths": decor_paths
		}
		
		if base_texture:
			print("🖼️ [ArenaManager] Textura seamless: %s (%dx%d, %d decoraciones)" % [biome_name, base_texture.get_width(), base_texture.get_height(), decor_paths.size()])
		else:
			print("⚠️ [ArenaManager] Sin textura para: %s (usando color)" % biome_name)

func _generate_arena() -> void:
	"""Generar las zonas visuales de la arena"""
	if not arena_root:
		push_error("[ArenaManager] arena_root no asignado")
		return
	
	# Crear contenedor para zonas
	var zones_container = Node2D.new()
	zones_container.name = "ArenaZones"
	zones_container.z_index = -100  # Muy atrás
	arena_root.add_child(zones_container)
	
	# Generar zonas de afuera hacia adentro (para que las interiores se dibujen encima)
	_create_zone(zones_container, ZoneType.DEATH, arena_radius)
	_create_zone(zones_container, ZoneType.DANGER, danger_zone_radius)
	_create_zone(zones_container, ZoneType.MEDIUM, medium_zone_radius)
	_create_zone(zones_container, ZoneType.SAFE, safe_zone_radius)

func _create_zone(parent: Node2D, zone_type: ZoneType, radius: float) -> void:
	"""Crear una zona circular con su bioma usando textura seamless + shader"""
	var biome_name = selected_biomes[zone_type]
	var biome_data = biome_textures.get(biome_name, {})
	var base_texture = biome_data.get("base", null)
	
	# Contenedor de la zona
	var zone_node = Node2D.new()
	zone_node.name = "Zone_%s" % ZoneType.keys()[zone_type]
	parent.add_child(zone_node)
	zone_sprites.append(zone_node)
	
	# Radio interior (para calcular área del anillo)
	var inner_radius = _get_inner_radius(zone_type)
	
	if base_texture:
		# Usar textura seamless con shader de tiling circular
		_create_circular_tiled_zone(zone_node, base_texture, radius, inner_radius, zone_type)
	else:
		# Fallback: círculo de color sólido
		_create_colored_zone(zone_node, biome_name, radius, inner_radius)
	
	# Añadir decoraciones (reducidas para mejor rendimiento)
	_add_animated_decorations(zone_node, radius, zone_type)

func _create_circular_tiled_zone(zone_node: Node2D, texture: Texture2D, outer_radius: float, inner_radius: float, zone_type: ZoneType) -> void:
	"""Crear zona circular perfecta con UN SOLO sprite + shader de tiling"""
	
	# Cargar shader
	var shader = load("res://assets/shaders/circular_tiling_zone.gdshader")
	if not shader:
		push_error("[ArenaManager] No se pudo cargar circular_tiling_zone.gdshader")
		return
	
	# Crear un único Sprite2D que cubra toda el área
	var sprite = Sprite2D.new()
	sprite.name = "TiledCircle"
	sprite.texture = texture  # La textura base para el tamaño del sprite
	sprite.z_index = -100
	
	# Escalar el sprite para cubrir el diámetro completo de la zona
	var diameter = outer_radius * 2.0
	var tex_size = texture.get_size()
	var scale_factor = diameter / tex_size.x
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Crear material con shader
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Configurar uniforms del shader (todo normalizado 0-0.5 porque UV va de 0-1)
	mat.set_shader_parameter("outer_radius", 0.5)  # Círculo llega al borde del sprite
	
	# Inner radius normalizado respecto al outer
	var inner_normalized = 0.0
	if outer_radius > 0 and inner_radius > 0:
		inner_normalized = (inner_radius / outer_radius) * 0.5
	mat.set_shader_parameter("inner_radius", inner_normalized)
	
	# Número de repeticiones de la textura
	# Tiles más grandes (256px) para mejor visibilidad a diferentes zooms
	var desired_tile_world_size = 256.0  # Tamaño de cada tile en píxeles del mundo
	var tile_count = diameter / desired_tile_world_size
	mat.set_shader_parameter("tile_count", tile_count)
	
	# Suavizado del borde proporcional al tamaño
	mat.set_shader_parameter("edge_smoothness", 0.002)
	
	sprite.material = mat
	zone_node.add_child(sprite)
	
	print("   🎨 [Zone %s] Círculo perfecto (r=%.0f-%.0f, 1 sprite, tiles=%.1f)" % [ZoneType.keys()[zone_type], inner_radius, outer_radius, tile_count])

# Las funciones _create_sprite_frames_from_sheet y _apply_circular_shader_mask
# fueron eliminadas - ahora usamos shaders externos

func _create_colored_zone(zone_node: Node2D, biome_name: String, radius: float, inner_radius: float = 0.0) -> void:
	"""Crear zona con color sólido (fallback) - soporta anillos"""
	var color = BIOME_COLORS.get(biome_name, Color.GRAY)
	
	# Crear un círculo/anillo usando draw
	var circle_drawer = Node2D.new()
	circle_drawer.name = "CircleDrawer"
	circle_drawer.z_index = -100  # Muy atrás para no tapar decoraciones
	zone_node.add_child(circle_drawer)
	
	# Añadir script para dibujar círculo o anillo
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var outer_radius: float = 1000.0
var inner_radius: float = 0.0
var circle_color: Color = Color.WHITE
var segments: int = 128

func _draw():
	if inner_radius <= 0:
		# Círculo sólido
		var points = PackedVector2Array()
		for i in range(segments + 1):
			var angle = i * TAU / segments
			points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
		draw_colored_polygon(points, circle_color)
	else:
		# Anillo (dibujar como triángulos)
		for i in range(segments):
			var angle1 = i * TAU / segments
			var angle2 = (i + 1) * TAU / segments
			var p1_out = Vector2(cos(angle1), sin(angle1)) * outer_radius
			var p2_out = Vector2(cos(angle2), sin(angle2)) * outer_radius
			var p1_in = Vector2(cos(angle1), sin(angle1)) * inner_radius
			var p2_in = Vector2(cos(angle2), sin(angle2)) * inner_radius
			var quad = PackedVector2Array([p1_in, p2_in, p2_out, p1_out])
			draw_colored_polygon(quad, circle_color)
"""
	script.reload()
	circle_drawer.set_script(script)
	circle_drawer.set("outer_radius", radius)
	circle_drawer.set("inner_radius", inner_radius)
	circle_drawer.set("circle_color", color)
	circle_drawer.queue_redraw()

func _add_animated_decorations(zone_node: Node2D, radius: float, zone_type: ZoneType) -> void:
	"""Añadir decoraciones animadas a una zona usando AutoFrames"""
	# Número de decoraciones - balance entre visual y rendimiento
	var inner_radius = _get_inner_radius(zone_type)
	var zone_area = PI * (radius * radius - inner_radius * inner_radius)
	var decor_count = int(zone_area / 800000)  # ~1 decoración por cada 800k px²
	decor_count = clamp(decor_count, 10, 150)  # Entre 10 y 150 por zona
	
	# Obtener paths de las decoraciones del bioma
	var biome_name = selected_biomes[zone_type]
	var biome_data = biome_textures.get(biome_name, {})
	var decor_paths = biome_data.get("decor_paths", [])
	
	if decor_paths.size() == 0:
		print("   🌿 [Zone %s] Sin decoraciones disponibles" % ZoneType.keys()[zone_type])
		return
	
	var decor_container = Node2D.new()
	decor_container.name = "Decorations"
	decor_container.z_index = -99  # Encima del suelo, debajo de entidades
	zone_node.add_child(decor_container)
	
	var decor_created = 0
	for i in range(decor_count):
		# Posición aleatoria dentro del anillo de la zona
		var angle = rng.randf() * TAU
		var min_dist = inner_radius + 100 if inner_radius > 0 else 50
		var max_dist = radius - 100
		if max_dist <= min_dist:
			continue
		var dist = rng.randf_range(min_dist, max_dist)
		var pos = Vector2(cos(angle), sin(angle)) * dist
		
		# Seleccionar una decoración aleatoria
		var decor_path = decor_paths[rng.randi() % decor_paths.size()]
		
		# Crear decoración animada usando AutoFrames.from_sheet directamente (5 FPS)
		var sprite_frames = AutoFrames.from_sheet(decor_path, 5.0, 1)
		
		if sprite_frames == null:
			if i == 0:  # Solo debug la primera
				push_warning("[ArenaManager] AutoFrames.from_sheet devolvió null para: %s" % decor_path)
			continue
		
		var decor_node = AnimatedSprite2D.new()
		decor_node.sprite_frames = sprite_frames
		decor_node.animation = "default"
		decor_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		decor_node.position = pos
		decor_node.z_index = 10  # Por ENCIMA de las texturas base (-100)
		
		# Escala variable basada en el tamaño del player
		# Player: 500px × 0.25 = 125px visual
		# Decor: 256px × escala
		# Para igualar al player: 256 × escala = 125 → escala = 0.49
		# Máximo: 0.5 (igual al player), Mínimo: 0.25 (1/2 del player)
		var final_scale = rng.randf_range(0.25, 0.5)
		
		# Mirror horizontal (50% probabilidad)
		if rng.randf() > 0.5:
			decor_node.scale = Vector2(-final_scale, final_scale)
		else:
			decor_node.scale = Vector2(final_scale, final_scale)
		
		# Iniciar animación con frame aleatorio
		decor_node.play("default")
		var frame_count = sprite_frames.get_frame_count("default")
		if frame_count > 0:
			decor_node.frame = rng.randi() % frame_count
		
		decor_container.add_child(decor_node)
		decor_created += 1
	
	print("   🌿 [Zone %s] %d decoraciones" % [ZoneType.keys()[zone_type], decor_created])

func _get_inner_radius(zone_type: ZoneType) -> float:
	"""Obtener el radio interior de una zona"""
	match zone_type:
		ZoneType.SAFE:
			return 0.0
		ZoneType.MEDIUM:
			return safe_zone_radius
		ZoneType.DANGER:
			return medium_zone_radius
		ZoneType.DEATH:
			return danger_zone_radius
	return 0.0

func _create_boundary() -> void:
	"""Crear la barrera visual del borde de la arena"""
	boundary_node = Node2D.new()
	boundary_node.name = "ArenaBoundary"
	boundary_node.z_index = 50  # Encima de casi todo
	arena_root.add_child(boundary_node)
	
	# Script para dibujar el borde
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var arena_radius: float = 10000.0
var boundary_thickness: float = 200.0
var segments: int = 128
var pulse_speed: float = 2.0
var time: float = 0.0

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	# Borde exterior pulsante
	var pulse = 0.5 + 0.5 * sin(time * pulse_speed)
	var outer_color = Color(0.8, 0.2, 0.1, 0.3 + pulse * 0.2)
	var inner_color = Color(0.6, 0.1, 0.05, 0.1)
	
	# Dibujar anillo exterior (zona de muerte)
	var outer_points = PackedVector2Array()
	var inner_points = PackedVector2Array()
	
	for i in range(segments + 1):
		var angle = i * TAU / segments
		var dir = Vector2(cos(angle), sin(angle))
		outer_points.append(dir * (arena_radius + boundary_thickness))
		inner_points.append(dir * arena_radius)
	
	# Dibujar como líneas gruesas
	for i in range(segments):
		var p1_out = outer_points[i]
		var p2_out = outer_points[i + 1]
		var p1_in = inner_points[i]
		var p2_in = inner_points[i + 1]
		
		# Cuadrilátero para el borde
		var quad = PackedVector2Array([p1_in, p2_in, p2_out, p1_out])
		draw_colored_polygon(quad, outer_color)
	
	# Línea brillante en el borde exacto
	draw_arc(Vector2.ZERO, arena_radius, 0, TAU, segments, Color(1, 0.3, 0.1, 0.5 + pulse * 0.3), 4.0)
"""
	script.reload()
	boundary_node.set_script(script)
	boundary_node.set("arena_radius", arena_radius)
	boundary_node.set("boundary_thickness", boundary_thickness)

func _physics_process(delta: float) -> void:
	"""Actualizar estado del player respecto a la arena"""
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	var player_pos = player_ref.global_position
	var distance_from_center = player_pos.length()
	
	# Detectar zona actual
	var new_zone = _get_zone_at_distance(distance_from_center)
	if new_zone != player_current_zone:
		player_current_zone = new_zone
		var zone_name = ZoneType.keys()[new_zone]
		player_zone_changed.emit(new_zone, zone_name)
		print("🏟️ [ArenaManager] Player entró en zona: %s (%s)" % [zone_name, selected_biomes[new_zone]])
	
	# Verificar si está fuera del arena
	if distance_from_center > arena_radius:
		player_outside_arena = true
		_handle_player_outside_arena(delta, player_pos, distance_from_center)
	else:
		player_outside_arena = false

func _get_zone_at_distance(distance: float) -> ZoneType:
	"""Determinar en qué zona está basándose en la distancia al centro"""
	if distance <= safe_zone_radius:
		return ZoneType.SAFE
	elif distance <= medium_zone_radius:
		return ZoneType.MEDIUM
	elif distance <= danger_zone_radius:
		return ZoneType.DANGER
	else:
		return ZoneType.DEATH

func _handle_player_outside_arena(delta: float, player_pos: Vector2, distance: float) -> void:
	"""Manejar cuando el player está fuera del arena"""
	# Aplicar daño
	var damage = boundary_damage_per_second * delta
	player_hit_boundary.emit(damage)
	
	# Aplicar fuerza hacia el centro
	if player_ref.has_method("apply_knockback"):
		var push_direction = -player_pos.normalized()
		player_ref.apply_knockback(push_direction * boundary_push_force * delta)
	elif player_ref is CharacterBody2D:
		# Forzar movimiento hacia el centro
		var push_direction = -player_pos.normalized()
		player_ref.velocity += push_direction * boundary_push_force * delta

# === API PÚBLICA ===

func get_max_allowed_radius() -> float:
	"""Obtener el radio máximo al que el player puede llegar.
	   Basado en qué zonas están desbloqueadas."""
	# Si DEATH está desbloqueada, puede ir hasta el borde de la arena
	if unlocked_zones.get(ZoneType.DEATH, false):
		return arena_radius - 50.0  # Pequeño margen del borde
	# Si DANGER está desbloqueada, puede ir hasta DANGER
	if unlocked_zones.get(ZoneType.DANGER, false):
		return danger_zone_radius - 10.0
	# Si MEDIUM está desbloqueada, puede ir hasta MEDIUM
	if unlocked_zones.get(ZoneType.MEDIUM, false):
		return medium_zone_radius - 10.0
	# Solo SAFE desbloqueada
	return safe_zone_radius - 10.0

func get_arena_info() -> Dictionary:
	"""Obtener información completa de la arena"""
	return {
		"seed": arena_seed,
		"radius": arena_radius,
		"zones": {
			"safe": {
				"radius": safe_zone_radius,
				"biome": selected_biomes.get(ZoneType.SAFE, "unknown")
			},
			"medium": {
				"radius": medium_zone_radius,
				"biome": selected_biomes.get(ZoneType.MEDIUM, "unknown")
			},
			"danger": {
				"radius": danger_zone_radius,
				"biome": selected_biomes.get(ZoneType.DANGER, "unknown")
			},
			"death": {
				"radius": arena_radius,
				"biome": selected_biomes.get(ZoneType.DEATH, "unknown")
			}
		},
		"biomes": selected_biomes.duplicate()
	}

func get_zone_at_position(pos: Vector2) -> ZoneType:
	"""Obtener la zona en una posición específica"""
	return _get_zone_at_distance(pos.length())

func get_biome_at_position(pos: Vector2) -> String:
	"""Obtener el nombre del bioma en una posición"""
	var zone = get_zone_at_position(pos)
	return selected_biomes.get(zone, "unknown")

func get_random_position_in_zone(zone_type: ZoneType) -> Vector2:
	"""Obtener una posición aleatoria dentro de una zona específica"""
	var inner_r = _get_inner_radius(zone_type)
	var outer_r = _get_outer_radius(zone_type)
	
	var angle = randf() * TAU
	var dist = randf_range(inner_r + 50, outer_r - 50)
	
	return Vector2(cos(angle), sin(angle)) * dist

func _get_outer_radius(zone_type: ZoneType) -> float:
	"""Obtener el radio exterior de una zona"""
	match zone_type:
		ZoneType.SAFE:
			return safe_zone_radius
		ZoneType.MEDIUM:
			return medium_zone_radius
		ZoneType.DANGER:
			return danger_zone_radius
		ZoneType.DEATH:
			return arena_radius
	return arena_radius

func get_spawn_position_for_enemy(difficulty_tier: int) -> Vector2:
	"""Obtener posición de spawn para un enemigo según su tier de dificultad"""
	# Tier 1: Safe zone edges / Medium zone
	# Tier 2: Medium zone
	# Tier 3: Danger zone
	# Tier 4+: Death zone edges
	
	var zone: ZoneType
	match difficulty_tier:
		1:
			zone = ZoneType.MEDIUM if randf() > 0.3 else ZoneType.SAFE
		2:
			zone = ZoneType.MEDIUM
		3:
			zone = ZoneType.DANGER
		_:
			zone = ZoneType.DEATH
	
	return get_random_position_in_zone(zone)

func is_position_valid(pos: Vector2) -> bool:
	"""Verificar si una posición está dentro del arena"""
	return pos.length() <= arena_radius

func get_player_zone() -> ZoneType:
	"""Obtener la zona actual del player"""
	return player_current_zone

func get_player_zone_name() -> String:
	"""Obtener el nombre de la zona actual del player"""
	return ZoneType.keys()[player_current_zone]

func get_difficulty_multiplier_at_position(pos: Vector2) -> float:
	"""Obtener multiplicador de dificultad basado en la posición"""
	var zone = get_zone_at_position(pos)
	match zone:
		ZoneType.SAFE:
			return 1.0
		ZoneType.MEDIUM:
			return 1.5
		ZoneType.DANGER:
			return 2.5
		ZoneType.DEATH:
			return 4.0
	return 1.0

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE BARRERAS ENTRE ZONAS
# ═══════════════════════════════════════════════════════════════════════════════

func _create_zone_barriers() -> void:
	"""Crear barreras físicas circulares entre zonas"""
	# IMPORTANTE: Las barreras deben estar en el mismo espacio que el player
	# Usar get_tree().root para añadirlas al nivel superior
	var game_node = get_tree().root.get_node_or_null("Game")
	if not game_node:
		push_error("🚧 [ArenaManager] ERROR: No se encontró nodo Game")
		return
	
	# Crear contenedor para barreras como hijo directo de Game
	var barriers_container = Node2D.new()
	barriers_container.name = "ZoneBarriers"
	game_node.add_child(barriers_container)
	
	print("🚧 [ArenaManager] Contenedor de barreras creado en: %s" % barriers_container.get_path())
	
	# Barrera entre SAFE y MEDIUM (en safe_zone_radius)
	var barrier_medium = _create_circular_barrier(safe_zone_radius, ZoneType.MEDIUM, "BarrierToMedium")
	barriers_container.add_child(barrier_medium)
	zone_barriers[ZoneType.MEDIUM] = barrier_medium
	print("🚧 [ArenaManager] BarrierToMedium path: %s, children: %d" % [barrier_medium.get_path(), barrier_medium.get_child_count()])
	
	# Barrera entre MEDIUM y DANGER (en medium_zone_radius)
	var barrier_danger = _create_circular_barrier(medium_zone_radius, ZoneType.DANGER, "BarrierToDanger")
	barriers_container.add_child(barrier_danger)
	zone_barriers[ZoneType.DANGER] = barrier_danger
	
	# Barrera entre DANGER y DEATH (en danger_zone_radius)
	var barrier_death = _create_circular_barrier(danger_zone_radius, ZoneType.DEATH, "BarrierToDeath")
	barriers_container.add_child(barrier_death)
	zone_barriers[ZoneType.DEATH] = barrier_death
	
	# === BARRERA PERIMETRAL PERMANENTE ===
	# Esta barrera rodea todo el mapa y NUNCA se desbloquea
	var barrier_perimeter = _create_circular_barrier(arena_radius, ZoneType.SAFE, "BarrierPerimeter")
	barriers_container.add_child(barrier_perimeter)
	# Nota: No añadimos esta barrera a zone_barriers porque nunca se desbloquea
	print("🚧 [ArenaManager] Barrera perimetral permanente creada: r=%.0f" % arena_radius)
	
	print("🚧 [ArenaManager] Barreras de zona creadas")

func _create_circular_barrier(radius: float, zone_type: ZoneType, barrier_name: String) -> StaticBody2D:
	"""Crear una barrera circular física en el radio especificado"""
	var barrier = StaticBody2D.new()
	barrier.name = barrier_name
	barrier.collision_layer = 0
	barrier.set_collision_layer_value(8, true)  # Layer 8 para barreras de zona
	barrier.collision_mask = 0   # No detecta nada, solo bloquea
	
	# Grosor de la barrera - debe ser suficiente para no ser atravesada
	var barrier_thickness: float = 100.0
	
	# Crear múltiples rectángulos para formar un anillo sólido
	# Usamos RectangleShape2D en lugar de SegmentShape2D para colisiones sólidas
	var segments = 64  # Más segmentos = círculo más suave
	var angle_step = TAU / segments
	
	# Calcular el ancho de cada segmento basado en el perímetro
	var segment_width = (2.0 * PI * radius) / segments * 1.2  # 1.2 para overlap
	
	for i in range(segments):
		var angle = i * angle_step + (angle_step / 2.0)  # Centro del segmento
		
		# Crear un CollisionShape2D con forma de rectángulo
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		
		# Tamaño del rectángulo: ancho del segmento x grosor de la barrera
		shape.size = Vector2(segment_width, barrier_thickness)
		
		collision.shape = shape
		collision.name = "Segment_%d" % i
		
		# Posicionar en el perímetro y rotar para que sea tangente
		collision.position = Vector2(cos(angle), sin(angle)) * radius
		collision.rotation = angle + PI/2  # Rotar 90° para que sea tangente al círculo
		
		barrier.add_child(collision)
	
	# DEBUG: Verificar primer segmento
	var first_collision = barrier.get_child(0) as CollisionShape2D
	if first_collision and first_collision.shape:
		var s = first_collision.shape as RectangleShape2D
		print("🚧 [ArenaManager] %s primer segmento: pos=%s, size=%s, layer=%d" % [
			barrier_name, first_collision.position, s.size, barrier.collision_layer
		])
	
	# Añadir visual de la barrera
	var visual = _create_barrier_visual(radius, zone_type)
	barrier.add_child(visual)
	
	print("🚧 [ArenaManager] Barrera %s creada: r=%.0f, %d segmentos, grosor=%.0f" % [barrier_name, radius, segments, barrier_thickness])
	
	return barrier

func _create_barrier_visual(radius: float, zone_type: ZoneType) -> Node2D:
	"""Crear el efecto visual de la barrera (un anillo brillante)"""
	var visual = Node2D.new()
	visual.name = "BarrierVisual"
	
	# Color según la zona
	var color: Color
	match zone_type:
		ZoneType.MEDIUM:
			color = Color(0.2, 0.6, 1.0, 0.7)  # Azul
		ZoneType.DANGER:
			color = Color(1.0, 0.5, 0.0, 0.7)  # Naranja
		ZoneType.DEATH:
			color = Color(1.0, 0.1, 0.1, 0.8)  # Rojo
		ZoneType.SAFE:
			# Barrera perimetral permanente - color púrpura oscuro
			color = Color(0.5, 0.0, 0.8, 0.9)  # Púrpura
		_:
			color = Color(1.0, 1.0, 1.0, 0.5)
	
	# Crear un script inline para dibujar el anillo
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var radius: float = 1000.0
var ring_color: Color = Color.WHITE
var thickness: float = 8.0
var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta * 2.0
	queue_redraw()

func _draw() -> void:
	var pulse = (sin(pulse_time) + 1.0) / 2.0  # 0 a 1
	var alpha = ring_color.a * (0.5 + pulse * 0.5)
	var draw_color = Color(ring_color.r, ring_color.g, ring_color.b, alpha)
	
	# Dibujar anillo exterior
	draw_arc(Vector2.ZERO, radius, 0, TAU, 128, draw_color, thickness)
	
	# Dibujar línea interior más fina
	var inner_color = Color(ring_color.r, ring_color.g, ring_color.b, alpha * 0.3)
	draw_arc(Vector2.ZERO, radius - thickness, 0, TAU, 128, inner_color, 2.0)
"""
	script.reload()
	visual.set_script(script)
	visual.set("radius", radius)
	visual.set("ring_color", color)
	
	return visual

func unlock_zone(zone_type: ZoneType) -> void:
	"""Desbloquear una zona y eliminar su barrera"""
	if zone_type == ZoneType.SAFE:
		return  # SAFE siempre está desbloqueada
	
	if unlocked_zones.get(zone_type, false):
		return  # Ya desbloqueada
	
	unlocked_zones[zone_type] = true
	
	# Eliminar barrera física
	if zone_barriers.has(zone_type):
		var barrier = zone_barriers[zone_type]
		if is_instance_valid(barrier):
			# Animación de desvanecimiento
			var tween = create_tween()
			var visual = barrier.get_node_or_null("BarrierVisual")
			if visual:
				tween.tween_property(visual, "modulate:a", 0.0, 1.0)
				tween.tween_callback(barrier.queue_free)
			else:
				barrier.queue_free()
		zone_barriers.erase(zone_type)
	
	var zone_name = ZoneType.keys()[zone_type]
	zone_unlocked.emit(zone_type, zone_name)
	print("🔓 [ArenaManager] ¡Zona %s DESBLOQUEADA!" % zone_name)

func check_zone_unlocks(game_time_seconds: float) -> void:
	"""Verificar si alguna zona debe desbloquearse basándose en el tiempo de juego"""
	for zone_type in ZONE_UNLOCK_TIMES.keys():
		var unlock_time = ZONE_UNLOCK_TIMES[zone_type]
		if game_time_seconds >= unlock_time and not unlocked_zones.get(zone_type, false):
			unlock_zone(zone_type)

func is_zone_unlocked(zone_type: ZoneType) -> bool:
	"""Verificar si una zona está desbloqueada"""
	return unlocked_zones.get(zone_type, false)

func get_tier_for_zone(zone_type: ZoneType) -> int:
	"""Obtener el tier de enemigos que corresponde a una zona"""
	match zone_type:
		ZoneType.SAFE:
			return 1
		ZoneType.MEDIUM:
			return 2
		ZoneType.DANGER:
			return 3
		ZoneType.DEATH:
			return 4
	return 1

func get_spawn_tier_at_position(pos: Vector2) -> int:
	"""Obtener el tier de enemigo que debe spawnear en una posición.
	   Si la zona está bloqueada, devuelve tier 1 (zona SAFE)."""
	var zone = get_zone_at_position(pos)
	
	# Si la zona está bloqueada, forzar tier 1
	if not unlocked_zones.get(zone, false):
		return 1
	
	return get_tier_for_zone(zone)

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN PARA GUARDADO/REANUDACIÓN DE PARTIDA
# ═══════════════════════════════════════════════════════════════════════════════

func to_save_data() -> Dictionary:
	"""Serializar estado del ArenaManager para guardado"""
	# Convertir unlocked_zones a formato serializable (ZoneType enum a int)
	var unlocked_zones_serialized: Dictionary = {}
	for zone_type in unlocked_zones.keys():
		unlocked_zones_serialized[int(zone_type)] = unlocked_zones[zone_type]
	
	# Convertir selected_biomes a formato serializable
	var selected_biomes_serialized: Dictionary = {}
	for zone_type in selected_biomes.keys():
		selected_biomes_serialized[int(zone_type)] = selected_biomes[zone_type]
	
	return {
		"arena_seed": arena_seed,
		"unlocked_zones": unlocked_zones_serialized,
		"selected_biomes": selected_biomes_serialized,
		"player_current_zone": int(player_current_zone)
	}

func from_save_data(data: Dictionary) -> void:
	"""Restaurar estado del ArenaManager desde datos guardados"""
	if data.is_empty():
		return
	
	print("🏟️ [ArenaManager] Restaurando desde save data...")
	
	# Restaurar zonas desbloqueadas
	if data.has("unlocked_zones"):
		var saved_zones = data["unlocked_zones"]
		for zone_type_str in saved_zones.keys():
			var zone_type = int(zone_type_str)
			unlocked_zones[zone_type] = saved_zones[zone_type_str]
			# Actualizar barreras según estado
			if saved_zones[zone_type_str]:
				_unlock_zone_barrier(zone_type)
	
	# Restaurar zona actual del jugador
	if data.has("player_current_zone"):
		player_current_zone = data["player_current_zone"]
	
	print("🏟️ [ArenaManager] Estado restaurado:")
	print("   - Seed: %d" % arena_seed)
	print("   - Zonas desbloqueadas: SAFE=%s, MEDIUM=%s, DANGER=%s, DEATH=%s" % [
		unlocked_zones.get(ZoneType.SAFE, false),
		unlocked_zones.get(ZoneType.MEDIUM, false),
		unlocked_zones.get(ZoneType.DANGER, false),
		unlocked_zones.get(ZoneType.DEATH, false)
	])

func _unlock_zone_barrier(zone_type: int) -> void:
	"""Desbloquear la barrera de una zona (si existe)"""
	if zone_barriers.has(zone_type):
		var barrier = zone_barriers[zone_type]
		if is_instance_valid(barrier):
			barrier.queue_free()
			zone_barriers.erase(zone_type)
			print("🏟️ [ArenaManager] Barrera de zona %d removida" % zone_type)
