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

const DecorFactory = preload("res://scripts/utils/DecorFactory.gd")   # Asegurar referencia


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

# Offset para alinear la niebla con el borde visual de las barreras
const FOG_RADIUS_OFFSET: float = 150.0

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
# Nodos visuales
var zone_nodes: Dictionary = {} # ZoneType -> Node2D
var boundary_node: Node2D = null

# Sistema de detección de caminos (para speed buff)
var path_segments: Array[PackedVector2Array] = []  # Lista de todos los segmentos de camino
const PATH_DETECTION_WIDTH: float = 180.0  # Ancho de detección del camino (mitad del ancho visual ~350-420)
const PATH_SPEED_BONUS: float = 0.25  # +25% velocidad en caminos

func _ready() -> void:
	# Añadir al grupo para acceso global
	add_to_group("arena_manager")
	# Asegurar que ArenaManager respete la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Debug desactivado: print("🏟️ [ArenaManager] Inicializando...")

func initialize(player: Node2D, root: Node2D, resume_seed: int = -1) -> void:
	"""Inicializar la arena con un player y nodo raíz
	   resume_seed: -1 = generar nuevo seed, otro valor = usar ese seed (para reanudar partida)"""
	player_ref = player
	arena_root = root
	
	# Generar o usar seed proporcionado
	if resume_seed >= 0:
		# Usar seed de partida guardada
		arena_seed = resume_seed
		# Debug desactivado: print("🏟️ [ArenaManager] Usando seed de partida guardada: %d" % arena_seed)
	elif use_random_seed:
		randomize()
		arena_seed = randi()
	else:
		arena_seed = fixed_seed
	
	rng.seed = arena_seed
	# Debug desactivado: print("🏟️ [ArenaManager] Seed: %d" % arena_seed)
	
	# Seleccionar biomas aleatorios para cada zona
	_select_random_biomes()
	print("DEBUG: BIOMES_BY_ZONE keys: ", BIOMES_BY_ZONE.keys())
	
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
	
	# Debug desactivado: print("🏟️ [ArenaManager] ✅ Arena generada")
	# Debug desactivado: print("   - Safe Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.SAFE], safe_zone_radius])
	# Debug desactivado: print("   - Medium Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.MEDIUM], medium_zone_radius])
	# Debug desactivado: print("   - Danger Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.DANGER], danger_zone_radius])
	# Debug desactivado: print("   - Death Zone: %s (r=%.0f)" % [selected_biomes[ZoneType.DEATH], arena_radius])
	# Debug desactivado: print("   - 🚧 Barreras creadas: MEDIUM, DANGER, DEATH (bloqueadas)")

func _select_random_biomes() -> void:
	"""Seleccionar un bioma aleatorio para cada zona"""
	for zone_type in BIOMES_BY_ZONE.keys():
		var possible_biomes = BIOMES_BY_ZONE[zone_type]
		var selected_index = rng.randi() % possible_biomes.size()
		selected_biomes[zone_type] = possible_biomes[selected_index]
	
	# Debug desactivado: print("🎲 [ArenaManager] Biomas seleccionados:")
	for zone_type in selected_biomes.keys():
		# Debug desactivado: print("   - Zone %d: %s" % [zone_type, selected_biomes[zone_type]])
		pass

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
		# Debug desactivado: print("🔍 [ArenaManager] Intentando cargar %s desde: %s" % [biome_name, abs_path])
		
		var img = Image.new()
		var load_err = img.load(abs_path)
		if load_err == OK:
			# Debug desactivado: print("🔍 [ArenaManager] Image.load() OK para %s (size: %dx%d)" % [biome_name, img.get_width(), img.get_height()])
			base_texture = ImageTexture.create_from_image(img)
			if base_texture:
				# Debug desactivado: print("✅ [ArenaManager] Textura cargada desde archivo: %s" % biome_name)
				pass
			else:
				push_warning("[ArenaManager] ImageTexture.create_from_image falló para %s" % biome_name)
		else:
			push_warning("[ArenaManager] Image.load() falló para %s (error: %d)" % [biome_name, load_err])
			# Fallback: intentar con ResourceLoader (texturas ya importadas correctamente)
			if ResourceLoader.exists(base_path):
				base_texture = load(base_path)
				if base_texture:
					# Debug desactivado: print("📦 [ArenaManager] Textura cargada desde recursos: %s" % biome_name)
					pass
		
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
			# Debug desactivado: print("🖼️ [ArenaManager] Textura seamless: %s (%dx%d, %d decoraciones)" % [biome_name, base_texture.get_width(), base_texture.get_height(), decor_paths.size()])
			pass
		else:
			push_warning("[ArenaManager] Sin textura para: %s (usando color)" % biome_name)

func _generate_arena() -> void:
	"""Generar las zonas visuales de la arena"""
	if not arena_root:
		push_error("[ArenaManager] arena_root no asignado")
		return
	
	# Crear contenedor para zonas
	var zones_container = Node2D.new()
	zones_container.name = "ArenaZones"
	zones_container.z_index = 0 # DEJAMOS que cada zona maneje su Z negativo
	arena_root.add_child(zones_container)
	
	# Generar zonas de ADENTRO hacia AFUERA (Safe primero, Death al final)
	_create_zone(zones_container, ZoneType.SAFE, safe_zone_radius)
	_create_zone(zones_container, ZoneType.MEDIUM, medium_zone_radius)
	_create_zone(zones_container, ZoneType.DANGER, danger_zone_radius)
	_create_zone(zones_container, ZoneType.DEATH, arena_radius)

	# Generar caminos procedurales (ahora se añaden como hijos de cada zona)
	_generate_paths(zones_container)
	
	# Fog of War: Inicialmente visible hasta el borde de SAFE
	# Ajuste manual (FOG_RADIUS_OFFSET) para que la niebla empiece justo en la línea azul ("a ras")
	_create_fog_of_war(zones_container, safe_zone_radius - FOG_RADIUS_OFFSET)

func _generate_paths(parent: Node2D) -> void:
	"""Generar caminos procedurales que radian desde el centro y se dividen por zonas"""
	# Usar Node2D simple para evitar problemas con shaders en CanvasGroup
	var path_container = Node2D.new()
	path_container.name = "Paths"
	# ZONA: -200 Global. CAMINOS: -90 Global.
	path_container.z_index = -90 
	parent.add_child(path_container)
	
	# Configurar ruido
	var noise = FastNoiseLite.new()
	noise.seed = arena_seed
	noise.frequency = 0.001 
	noise.fractal_octaves = 2
	
	# Función local para carga robusta (resuelve importaciones pendientes)
	# Función local para carga robusta (resuelve importaciones pendientes)
	var _load_robusta = func(path: String) -> Texture2D:
		# 1. Intentar carga estándar
		if ResourceLoader.exists(path):
			var res = load(path)
			if res: return res
		
		# 2. Fallback: Carga manual
		var global_path = ProjectSettings.globalize_path(path)
		var img = Image.new()
		var err = img.load(global_path)
		
		if err != OK:
			# 3. Nuclear fallback: Leer bytes directamente
			# Sometimes img.load() fails on locked files, reading bytes avoids some locks
			if FileAccess.file_exists(path):
				var buffer = FileAccess.get_file_as_bytes(path)
				var err_buf = img.load_png_from_buffer(buffer) # Asumimos PNG
				if err_buf != OK:
					err_buf = img.load_jpg_from_buffer(buffer) # Try JPG
				err = err_buf
		
		if err == OK:
			return ImageTexture.create_from_image(img)
			
		push_warning("⚠️ [ArenaManager] FAIL LOAD: " + path + " | Global: " + global_path)
		return null
	
	# Cargar texturas de caminos por bioma
	var path_textures = {
		"Grassland": _load_robusta.call("res://assets/textures/paths/path_dirt.png"),
		"Forest": _load_robusta.call("res://assets/textures/paths/path_dirt.png"),
		"Snow": _load_robusta.call("res://assets/textures/paths/path_snow.png"),
		"Desert": _load_robusta.call("res://assets/textures/paths/path_desert.png"),
		"Lava": _load_robusta.call("res://assets/textures/paths/path_lava.jpg"),
		"ArcaneWastes": _load_robusta.call("res://assets/textures/paths/path_arcane.jpg"),
		"Death": _load_robusta.call("res://assets/textures/paths/path_death.jpg")
	}
	
	# Fallback final para Grassland si falla la png
	if not path_textures["Grassland"]:
		path_textures["Grassland"] = _load_robusta.call("res://assets/textures/paths/path_dirt_v2.jpg")
		path_textures["Forest"] = path_textures["Grassland"]
	
	# Fallback robusto: biomas sin textura usan la de Grassland (tierra)
	var fallback_tex = path_textures["Grassland"]
	for biome in path_textures:
		if not path_textures[biome]:
			path_textures[biome] = fallback_tex
			# Solo mostrar warning si es un bioma que debería tener textura propia
			if biome in ["Lava", "ArcaneWastes", "Death"]:
				push_warning("⚠️ [ArenaManager] Textura de camino para '%s' no encontrada, usando fallback" % biome)
	
	# Cantidad de caminos principales
	var main_paths = rng.randi_range(3, 5)
	
	for i in range(main_paths):
		var angle_step = TAU / main_paths
		var base_angle = (i * angle_step) + rng.randf_range(-0.5, 0.5)
		
		# 1. Generar geometría completa
		var full_points = _generate_path_geometry(base_angle, noise, i)
		
		# Calcular ancho CONSISTENTE para todo este camino
		var path_width = rng.randf_range(350.0, 420.0)
		
		# 2. Dibujar troceada por zonas
		if full_points.size() > 1:
			_split_and_draw_path(path_container, full_points, path_textures, path_width)
			
			# Ramificaciones
			if rng.randf() > 0.4:
				_create_branch_path(path_container, full_points, noise, i, path_textures)



func _generate_path_geometry(base_angle: float, noise: FastNoiseLite, seed_idx: int) -> PackedVector2Array:
	var points = []
	var current_pos = Vector2.ZERO
	var current_dist = 0.0
	var max_dist = arena_radius * 1.1 
	points.append(Vector2.ZERO)
	
	while current_dist < max_dist:
		current_dist += 40.0 
		var noise_val = noise.get_noise_2d(current_dist, seed_idx * 500.0)
		var angle_offset = noise_val * 0.6 
		var current_angle = base_angle + angle_offset
		current_pos = Vector2(cos(current_angle), sin(current_angle)) * current_dist
		points.append(current_pos)
		
	var curve = Curve2D.new()
	for p in points: curve.add_point(p)
	return curve.tessellate(3, 8)

func _split_and_draw_path(container: Node, points: PackedVector2Array, textures: Dictionary, width: float) -> void:
	"""
	Dibuja el camino completo como UNA SOLA geometría continua.
	Se renderiza 4 veces (una por zona) con diferentes texturas,
	usando el shader para mostrar solo la parte visible de cada zona.
	Esto garantiza continuidad perfecta en las fronteras.
	"""
	if points.size() < 2: return
	
	# Almacenar puntos completos para detección de caminos (speed buff)
	path_segments.append(points)
	
	# Dibujar el mismo camino completo para cada zona con su textura correspondiente
	for zone in [ZoneType.SAFE, ZoneType.MEDIUM, ZoneType.DANGER, ZoneType.DEATH]:
		_draw_full_path_for_zone(container, points, zone, textures, width)

func _draw_full_path_for_zone(container: Node, points: PackedVector2Array, zone: int, textures: Dictionary, width: float) -> void:
	"""
	Dibuja el camino completo pero solo visible dentro de la zona especificada.
	El shader se encarga de ocultar (discard) los píxeles fuera de la zona.
	"""
	if points.size() < 2: return
	
	# Determinar textura correcta para esta zona
	var biome_name = selected_biomes.get(zone, "Grassland")
	var tex = textures.get(biome_name, textures.get("Grassland"))
	
	# Si no hay textura, usar fallback visual
	if not tex: 
		push_warning("⚠️ [ArenaManager] Usando textura fallback para zona %d" % zone)
		var img = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.MAGENTA)
		tex = ImageTexture.create_from_image(img)
	
	var line = Line2D.new()
	line.width = width 
	
	# Configurar Shader
	var shader = load("res://assets/shaders/path_world_uv.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("texture_albedo", tex)
	mat.set_shader_parameter("texture_scale", Vector2(0.002, 0.002)) 
	
	# Calcular límites de visibilidad para esta zona (sin overlap, corte exacto)
	var clip_min = 0.0
	var clip_max = 100000.0
	
	match zone:
		ZoneType.SAFE:
			clip_min = 0.0
			clip_max = safe_zone_radius
		ZoneType.MEDIUM:
			clip_min = safe_zone_radius
			clip_max = medium_zone_radius
		ZoneType.DANGER:
			clip_min = medium_zone_radius
			clip_max = danger_zone_radius
		ZoneType.DEATH:
			clip_min = danger_zone_radius
			clip_max = arena_radius
	
	mat.set_shader_parameter("min_radius", clip_min)
	mat.set_shader_parameter("max_radius", clip_max)
	
	line.material = mat
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH 
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	line.points = points  # MISMOS puntos para todas las zonas = continuidad perfecta
	line.modulate = Color(1, 1, 1, 1)

	# Añadir al nodo de zona correspondiente
	if zone_nodes.has(zone):
		var z_node = zone_nodes[zone]
		z_node.add_child(line)
		line.z_index = 1  # Encima del suelo (0)
	else:
		container.add_child(line)

func _get_boundary_radius(zone_a: int, zone_b: int) -> float:
	# Devuelve el radio frontera entre dos zonas. 
	# Asumimos que zone_b es la siguiente (más lejana) o anterior.
	# La frontera siempre es el radio exterior de la zona más pequeña.
	var min_zone = min(zone_a, zone_b)
	match min_zone:
		ZoneType.SAFE: return safe_zone_radius
		ZoneType.MEDIUM: return medium_zone_radius
		ZoneType.DANGER: return danger_zone_radius
		ZoneType.DEATH: return arena_radius # O danger_zone_radius? La zona DEATH empieza donde acaba DANGER
	return danger_zone_radius # Fallback seguro

func _find_circle_segment_intersection(p1: Vector2, p2: Vector2, r: float) -> Vector2:
	# Resuelve intersección entre segmento P1-P2 y círculo radio R centrado en (0,0)
	# Ecuación: |P1 + t*(P2-P1)| = R
	var d = p2 - p1
	var a = d.dot(d)
	var b = 2.0 * p1.dot(d)
	var c = p1.dot(p1) - (r * r)
	
	var discriminant = b * b - 4 * a * c
	if discriminant < 0: return Vector2.INF
	
	var t = (-b + sqrt(discriminant)) / (2 * a)
	if t >= 0.0 and t <= 1.0:
		return p1 + d * t
		
	# A veces la otra solución es la correcta si vamos 'hacia adentro'
	t = (-b - sqrt(discriminant)) / (2 * a)
	if t >= 0.0 and t <= 1.0:
		return p1 + d * t
		
	return Vector2.INF

func _create_fog_of_war(parent: Node2D, initial_radius: float) -> void:
	var fog = ColorRect.new()
	fog.name = "FogOfWar"
	# Cubrir un área gigante suficiente para todo el mapa
	var huge_size = 50000 
	fog.size = Vector2(huge_size, huge_size)
	fog.position = Vector2(-huge_size/2, -huge_size/2)
	
	# Z-Index CRÍTICO: 
	# Si parent es `zones_container` (-100), poner 100 da Global 0.
	# Si hay cosas en Z > 0 (player, enemigos), la niebla no las tapa.
	# SOLUCIÓN: Usar Z muy alto y asegurar parent global 0.
	fog.z_index = 4000 # Max canvas layerish
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	# Restaurar Shader de Niebla
	var shader = load("res://assets/shaders/fog_of_war.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("unlocked_radius", initial_radius)
	mat.set_shader_parameter("fog_color", Color(0.05, 0.05, 0.08, 0.95)) # Casi negro azulado
	
	fog.material = mat
	
	# Usar arena_root para el z_index correcto
	var target_parent = arena_root if arena_root else parent
	
	# Asegurar que no existe ya
	if target_parent.has_node("FogOfWar"):
		target_parent.get_node("FogOfWar").queue_free()

	target_parent.add_child(fog)
	
	# Debug
	print("🌫️ [ArenaManager] FogOfWar creado en %s con radio inicial %.1f" % [target_parent.name, initial_radius])
	
func update_fog_radius(new_radius: float) -> void:
	# Buscar niebla en arena_root primero (nueva ubicación)
	var fog = arena_root.get_node_or_null("FogOfWar")
	if not fog: fog = get_node_or_null("World/Zones/FogOfWar") 
	if not fog: fog = get_tree().root.find_child("FogOfWar", true, false)
	
	if fog and fog.material is ShaderMaterial:
		print("🌫️ [ArenaManager] Actualizando niebla a radio: %.1f" % new_radius)
		# Tween suave
		var tween = create_tween()
		tween.tween_method(
			func(val): fog.material.set_shader_parameter("unlocked_radius", val),
			fog.material.get_shader_parameter("unlocked_radius"),
			new_radius,
			2.0 
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Función _create_quad_mesh eliminada por no usarse

func _create_branch_path(container: Node2D, parent_points: PackedVector2Array, noise: FastNoiseLite, seed_offset: int, textures: Dictionary) -> void:
	if parent_points.size() < 20: return
	var start_idx = rng.randi_range(parent_points.size() / 4, parent_points.size() / 2)
	var start_pos = parent_points[start_idx]
	
	var branch_points = []
	var current_pos = start_pos
	var current_dist = start_pos.length()
	var branch_angle = start_pos.angle() + (rng.randf_range(0.5, 1.0) * (1 if rng.randf() > 0.5 else -1))
	branch_points.append(start_pos)
	
	for j in range(30): 
		current_dist += 60.0 
		var noise_val = noise.get_noise_2d(current_dist, seed_offset + 999)
		var angle = branch_angle + (noise_val * 0.5)
		current_pos += Vector2(cos(angle), sin(angle)) * 60.0
		branch_points.append(current_pos)
	
	var curve = Curve2D.new()
	for p in branch_points: curve.add_point(p)
	var smoothed = curve.tessellate(3, 8)
	
	# Ancho consistente para la rama (más fino que el principal)
	var branch_width = rng.randf_range(200.0, 300.0)
	
	# Usar texturas pasadas por argumento
	_split_and_draw_path(container, smoothed, textures, branch_width)



func _create_zone(parent: Node2D, zone_type: ZoneType, radius: float) -> void:
	"""Crear una zona circular con su bioma usando textura seamless + shader"""
	var biome_name = selected_biomes[zone_type]
	var biome_data = biome_textures.get(biome_name, {})
	var base_texture = biome_data.get("base", null)
	
	# Contenedor de la zona
	var zone_node = Node2D.new()
	zone_node.name = "Zone_%s" % ZoneType.keys()[zone_type]
	
	# SANDWICH Z-INDEX STRATEGY (NEGATIVE STACK):
	# Queremos que las zonas EXTERIORES cubran a las INTERIORES, pero TODO debajo de Enemigos (Z=0).
	# Safe(0)   -> Ground -400
	# Medium(1) -> Ground -300 (Cubre a Safe Path -390)
	# Danger(2) -> Ground -200 (Cubre a Medium Path -290)
	# Death(3)  -> Ground -100 (Cubre a Danger Path -190)
	
	# Global Z será: 
	var base_z = -400 + (int(zone_type) * 100)
	zone_node.z_index = base_z
	
	parent.add_child(zone_node)
	zone_nodes[zone_type] = zone_node
	
	# Radio interior (para calcular área del anillo)
	var inner_radius = _get_inner_radius(zone_type)
	
	if base_texture:
		# Usar textura seamless con shader de tiling circular
		# IMPORTANTE: El sprite dentro de zone_node debe estar en Z=0 local para respetar el sandwich
		_create_circular_tiled_zone(zone_node, base_texture, radius, inner_radius, zone_type)
	else:
		pass  # Bloque else
		# Fallback: círculo de color sólido
		_create_colored_zone(zone_node, biome_name, radius, inner_radius)
	
	# Añadir decals de suelo (detalles estáticos planos)
	# Desactivado temporalmente por feedback visual (manchas negras)
	# _generate_ground_decals(zone_node, radius, inner_radius, zone_type)

	# Añadir decoraciones (reducidas para mejor rendimiento)
	_add_animated_decorations(zone_node, radius, zone_type)

func _generate_ground_decals(zone_node: Node2D, radius: float, inner_radius: float, zone_type: ZoneType) -> void:
	"""Generar detalles planos en el suelo para romper repetitividad"""
	# Usar una textura procedural simple para manchas/grietas
	var noise_tex = GradientTexture2D.new()
	noise_tex.width = 64
	noise_tex.height = 64
	noise_tex.fill = GradientTexture2D.FILL_RADIAL
	var grad = Gradient.new()
	grad.colors = [Color(0,0,0,0.4), Color(0,0,0,0)] # Mancha oscura difusa
	noise_tex.gradient = grad
	
	# Calcular cantidad basada en área
	var zone_area = PI * (radius * radius - inner_radius * inner_radius)
	var decal_count = int(zone_area / 400000) # ~1 por cada 400k px²
	decal_count = clamp(decal_count, 20, 200)
	
	var decals_container = Node2D.new()
	decals_container.name = "Decals"
	decals_container.z_index = -95 # Entre suelo (-100) y caminos (-90)
	zone_node.add_child(decals_container)
	
	for i in range(decal_count):
		# Posición aleatoria en anillo
		var angle = rng.randf() * TAU
		var min_dist = inner_radius + 50
		var max_dist = radius - 50
		if max_dist <= min_dist: continue
		
		var dist = rng.randf_range(min_dist, max_dist)
		var pos = Vector2(cos(angle), sin(angle)) * dist
		
		var decal = Sprite2D.new()
		decal.texture = noise_tex
		decal.position = pos
		
		# Variación visual
		var scale_val = rng.randf_range(1.0, 3.0)
		decal.scale = Vector2(scale_val, scale_val * rng.randf_range(0.8, 1.2))
		decal.rotation = rng.randf() * TAU
		decal.modulate = Color(1, 1, 1, rng.randf_range(0.3, 0.7)) # Opacidad variable
		
		decals_container.add_child(decal)

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
	sprite.z_index = 0 # Local 0. Hereda el Z de la Zone (0, 10, 20...)
	
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
	
	# Debug desactivado: print("   🎨 [Zone %s] Círculo perfecto (r=%.0f-%.0f, 1 sprite, tiles=%.1f)" % [ZoneType.keys()[zone_type], inner_radius, outer_radius, tile_count])

# Las funciones _create_sprite_frames_from_sheet y _apply_circular_shader_mask
# fueron eliminadas - ahora usamos shaders externos

func _create_colored_zone(zone_node: Node2D, biome_name: String, radius: float, inner_radius: float = 0.0) -> void:
	"""Crear zona con color sólido (fallback) - soporta anillos"""
	var color = BIOME_COLORS.get(biome_name, Color.GRAY)
	
	# Crear un círculo/anillo usando draw
	var circle_drawer = Node2D.new()
	circle_drawer.name = "CircleDrawer"
	circle_drawer.z_index = 0 # Local 0
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
		pass  # Bloque else
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
		# Debug desactivado: print("   🌿 [Zone %s] Sin decoraciones disponibles" % ZoneType.keys()[zone_type])
		return
	
	var decor_container = Node2D.new()
	decor_container.name = "Decorations"
	decor_container.z_index = 0  # CRÍTICO: Global será -100 + 0 = -100 (relativa a zona)
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
		decor_node.z_index = 2 # Encima de camino (1) y suelo (0)
		
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
		
		# TASK C: Añadir colisión usando el helper refactorizado de DecorFactory
		if frame_count > 0:
			var tex = sprite_frames.get_frame_texture("default", 0)
			if tex:
				# Aplicar colisión a la decoración
				# CORRECCIÓN: Pasar tamaño ORIGINAL de la textura.
				# DecorFactory añade el body como hijo, por lo que heredará la escala del nodo padre.
				DecorFactory.add_collision_to_node(decor_node, tex.get_size())
		
		decor_created += 1
	
	# Debug desactivado: print("   🌿 [Zone %s] %d decoraciones" % [ZoneType.keys()[zone_type], decor_created])

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
	"""Crear la barrera visual del borde de la arena usando Shader Volumétrico"""
	boundary_node = Node2D.new()
	boundary_node.name = "ArenaBoundary"
	boundary_node.z_index = -5  # Debajo de enemigos (0) y player, pero encima del suelo (-100)
	arena_root.add_child(boundary_node)
	
	# Radio visual que cubra más allá del límite físico para que no se vea el corte
	# Multiplicamos por 2.5 para tener suficiente margen "infinito"
	var visual_radius = arena_radius * 2.5
	var diameter = visual_radius * 2.0
	
	# Crear Sprite gigante
	var sprite = Sprite2D.new()
	sprite.name = "VoidBorderSprite"
	
	# Usar GradientTexture2D para asegurar UVs correctos
	# Configurar como totalmente transparente por defecto para evitar "pantalla negra" si falla el shader
	var texture = GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	# Configurar gradiente transparente
	var grad = Gradient.new()
	grad.colors = [Color(0,0,0,0), Color(0,0,0,0)] # Todo transparente
	texture.gradient = grad
	sprite.texture = texture
	
	# Escalar para cubrir toda el área deseada
	var scale_factor = diameter / 128.0
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Cargar Shader
	var shader = load("res://assets/shaders/void_border.gdshader")
	if not shader:
		push_error("[ArenaManager] No se pudo cargar void_border.gdshader")
		return
		
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Calcular radio normalizado para el shader
	# El shader usa UV (0 a 1), centro en 0.5
	# Nuestro radio físico es 'arena_radius'
	# El radio visual total es 'visual_radius' = arena_radius * 2.5
	# Ratio = arena_radius / visual_radius = 1 / 2.5 = 0.4
	# En espacio UV (0-0.5 radio), el borde está en 0.5 * Ratio = 0.2
	# Calcular radio normalizado con SAFEGUARDS
	if visual_radius <= 1.0: visual_radius = 10000.0 # Evitar div/0
	var radius_normalized = 0.5 * (arena_radius / visual_radius)
	
	# CLAMP CRÍTICO: Asegurar que el radio nunca sea 0.0 (oscuridad total)
	# Forzamos que al menos el 10% central sea visible siempre
	radius_normalized = clampf(radius_normalized, 0.1, 0.49)
	
	# Debug para verificar que no sea 0
	print("🎨 [ArenaManager] Void Border Shader: Arena R=%.1f, Visual R=%.1f, Norm R=%.3f" % [arena_radius, visual_radius, radius_normalized])
	
	mat.set_shader_parameter("radius", radius_normalized)
	mat.set_shader_parameter("smoothness", 0.02)
	mat.set_shader_parameter("pulse_speed", 1.5)
	mat.set_shader_parameter("chaos_speed", 0.4)
	mat.set_shader_parameter("noise_scale", 10.0) # Más detalle
	
	sprite.material = mat
	boundary_node.add_child(sprite)
	
	# Debug desactivado: print("🎨 [ArenaManager] Void Border shader aplicado. R_norm: %.3f" % radius_normalized)

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
		# Debug desactivado: print("🏟️ [ArenaManager] Player entró en zona: %s (%s)" % [zone_name, selected_biomes[new_zone]])
	
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
	
	# Debug desactivado: print("🚧 [ArenaManager] Contenedor de barreras creado en: %s" % barriers_container.get_path())
	
	# Barrera entre SAFE y MEDIUM (en safe_zone_radius)
	var barrier_medium = _create_circular_barrier(safe_zone_radius, ZoneType.MEDIUM, "BarrierToMedium")
	barriers_container.add_child(barrier_medium)
	zone_barriers[ZoneType.MEDIUM] = barrier_medium
	# Debug desactivado: print("🚧 [ArenaManager] BarrierToMedium path: %s, children: %d" % [barrier_medium.get_path(), barrier_medium.get_child_count()])
	
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
	# Debug desactivado: print("🚧 [ArenaManager] Barrera perimetral permanente creada: r=%.0f" % arena_radius)
	
	# Debug desactivado: print("🚧 [ArenaManager] Barreras de zona creadas")

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
		# Debug desactivado: print("🚧 [ArenaManager] %s primer segmento: pos=%s, size=%s, layer=%d" % [
		#	barrier_name, first_collision.position, s.size, barrier.collision_layer
		# ])
	
	# Añadir visual de la barrera
	var visual = _create_barrier_visual(radius, zone_type)
	barrier.add_child(visual)
	
	# Debug desactivado: print("🚧 [ArenaManager] Barrera %s creada: r=%.0f, %d segmentos, grosor=%.0f" % [barrier_name, radius, segments, barrier_thickness])
	
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
	
	# Calcular nueva visibilidad de niebla - alinear con la siguiente barrera desbloqueada
	# Aplicar FOG_RADIUS_OFFSET para que la niebla empiece justo en el borde visual de la barrera
	var new_fog_radius = safe_zone_radius - FOG_RADIUS_OFFSET
	match zone_type:
		ZoneType.MEDIUM: new_fog_radius = medium_zone_radius - FOG_RADIUS_OFFSET  # Fog hasta la barrera a DANGER
		ZoneType.DANGER: new_fog_radius = danger_zone_radius - FOG_RADIUS_OFFSET  # Fog hasta la barrera a DEATH
		ZoneType.DEATH: new_fog_radius = arena_radius  # Fog hasta el borde del arena (sin offset)
	
	# Actualizar niebla of war
	update_fog_radius(new_fog_radius)
	
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
	# Debug desactivado: print("🔓 [ArenaManager] ¡Zona %s DESBLOQUEADA!" % zone_name)

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
		"player_current_zone": int(player_current_zone),
		"fog_radius": _get_current_fog_radius()
	}

func _get_current_fog_radius() -> float:
	"""Obtener el radio actual del fog desde el shader"""
	var fog = arena_root.get_node_or_null("FogOfWar") if arena_root else null
	if not fog:
		fog = get_tree().root.find_child("FogOfWar", true, false)
	if fog and fog.material is ShaderMaterial:
		return fog.material.get_shader_parameter("unlocked_radius")
	# Fallback basado en zona actual
	match player_current_zone:
		ZoneType.SAFE: return safe_zone_radius - FOG_RADIUS_OFFSET
		ZoneType.MEDIUM: return medium_zone_radius - FOG_RADIUS_OFFSET
		ZoneType.DANGER: return danger_zone_radius - FOG_RADIUS_OFFSET
		ZoneType.DEATH: return arena_radius
	return safe_zone_radius - FOG_RADIUS_OFFSET

func from_save_data(data: Dictionary) -> void:
	"""Restaurar estado del ArenaManager desde datos guardados"""
	if data.is_empty():
		return
	
	# Debug desactivado: print("🏟️ [ArenaManager] Restaurando desde save data...")
	
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
	
	# Restaurar radio del fog de guerra (importante para continuidad visual)
	if data.has("fog_radius"):
		var saved_fog_radius = data["fog_radius"]
		# Usar call_deferred para asegurar que el fog ya esté creado
		call_deferred("_restore_fog_radius", saved_fog_radius)
	
	# Debug desactivado: print("🏟️ [ArenaManager] Estado restaurado:")

func _restore_fog_radius(radius: float) -> void:
	"""Restaurar el radio del fog inmediatamente (sin animación)"""
	var fog = arena_root.get_node_or_null("FogOfWar") if arena_root else null
	if not fog:
		fog = get_tree().root.find_child("FogOfWar", true, false)
	
	if fog and fog.material is ShaderMaterial:
		fog.material.set_shader_parameter("unlocked_radius", radius)
		print("🌫️ [ArenaManager] Fog restaurado a radio: %.1f" % radius)
	# Debug desactivado: print("   - Seed: %d" % arena_seed)
	# Debug desactivado: print("   - Zonas desbloqueadas: SAFE=%s, MEDIUM=%s, DANGER=%s, DEATH=%s" % [
	#	unlocked_zones.get(ZoneType.SAFE, false),
	#	unlocked_zones.get(ZoneType.MEDIUM, false),
	#	unlocked_zones.get(ZoneType.DANGER, false),
	#	unlocked_zones.get(ZoneType.DEATH, false)
	# ])

func _unlock_zone_barrier(zone_type: int) -> void:
	"""Desbloquear la barrera de una zona (si existe)"""
	if zone_barriers.has(zone_type):
		var barrier = zone_barriers[zone_type]
		if is_instance_valid(barrier):
			barrier.queue_free()
			zone_barriers.erase(zone_type)
			# Debug desactivado: print("🏟️ [ArenaManager] Barrera de zona %d removida" % zone_type)

# ═══════════════════════════════════════════════════════════════════════════════
# DETECCIÓN DE CAMINOS (SPEED BUFF)
# ═══════════════════════════════════════════════════════════════════════════════

func is_on_path(position: Vector2) -> bool:
	"""Verificar si una posición está sobre un camino"""
	for segment in path_segments:
		if _is_point_near_polyline(position, segment, PATH_DETECTION_WIDTH):
			return true
	return false

func get_path_speed_bonus() -> float:
	"""Obtener el bonus de velocidad por caminar en un camino"""
	return PATH_SPEED_BONUS

func _is_point_near_polyline(point: Vector2, polyline: PackedVector2Array, max_distance: float) -> bool:
	"""Verificar si un punto está cerca de cualquier segmento de una polilínea"""
	if polyline.size() < 2:
		return false
	
	var max_dist_sq = max_distance * max_distance
	
	for i in range(polyline.size() - 1):
		var a = polyline[i]
		var b = polyline[i + 1]
		
		# Calcular distancia del punto al segmento
		var dist_sq = _point_to_segment_dist_sq(point, a, b)
		if dist_sq <= max_dist_sq:
			return true
	
	return false

func _point_to_segment_dist_sq(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	"""Calcular distancia al cuadrado de un punto a un segmento"""
	var seg = seg_b - seg_a
	var seg_len_sq = seg.length_squared()
	
	if seg_len_sq < 0.0001:
		return (point - seg_a).length_squared()
	
	# Proyectar punto en la línea
	var t = maxf(0.0, minf(1.0, (point - seg_a).dot(seg) / seg_len_sq))
	var projection = seg_a + t * seg
	
	return (point - projection).length_squared()
