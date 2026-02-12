extends CharacterBody2D
class_name EnemyBase

# Señal actualizada: incluye tier, is_elite, is_boss para el sistema de monedas
signal enemy_died(enemy_node, enemy_type_id, exp_value, enemy_tier, is_elite, is_boss)

# Componentes
var health_component = null
var attack_system = null
var animated_sprite = null  # AnimatedEnemySprite component
var aura_sprite = null      # Sprite para élites

var enemy_id: String = "generic"
var enemy_tier: int = 1  # Tier del enemigo (1-4 normal, 5 boss)
var max_hp: int = 10
var hp: int = 10
var speed: float = 30.0  # Base reducida a 50% (era ~60, ahora 30)
var damage: int = 5
var exp_value: int = 1
var player_ref: Node = null

# Datos completos del enemigo (desde EnemyDatabase)
var enemy_data: Dictionary = {}
var archetype: String = "melee"
var special_abilities: Array = []
var modifiers: Dictionary = {}

# Flags especiales
var is_elite: bool = false
var is_boss: bool = false
var aura_color: Color = Color(1.0, 0.8, 0.2, 0.8)
var elite_size_scale: float = 1.5

# Flag para prevenir recursión infinita de overkill
var _receiving_overkill_damage: bool = false

# AI parameters (can be overridden in subclasses)
var attack_range: float = 32.0
var separation_radius: float = 40.0
var attack_cooldown: float = 1.0
var can_attack: bool = true
var attack_timer: float = 0.0

# Comportamiento específico por arquetipo
var preferred_distance: float = 0.0  # Para ranged
var charge_cooldown_timer: float = 0.0
var is_charging: bool = false
var charge_target: Vector2 = Vector2.ZERO
var phase_cooldown_timer: float = 0.0
var is_phased: bool = false
var teleport_cooldown_timer: float = 0.0
var ability_cooldown_timer: float = 0.0
var trail_timer: float = 0.0
var zigzag_timer: float = 0.0
var zigzag_direction: float = 1.0

# Dirección actual del enemigo (para animación)
var current_direction: Vector2 = Vector2.DOWN

# Cache de referencias para evitar lookups de grupo cada frame
var _cached_player_stats: Node = null
var _cached_decor_manager: Node = null

func _enter_tree() -> void:
	var perf_tracker = get_node_or_null("/root/PerfTracker")
	if perf_tracker:
		perf_tracker.track_enemy_spawned()
	
	# Asegurar que está en el grupo para detección de proyectiles
	if not is_in_group("enemies"):
		add_to_group("enemies")

func _ready() -> void:
	"""Inicializar al cargar la escena. Ejecutado ANTES de las subclases."""
	# CRÍTICO: Respetar la pausa del juego (Game.gd tiene ALWAYS, pero enemigos deben pausarse)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Capas/máscaras: layer=2 (Enemy), mask=3 (PlayerProjectiles) y 1 (Player)
	set_collision_layer_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(8, true) # Barrier layer (Decorations)

	# CRÍTICO: Crear CollisionShape2D si no existe
	var collision_shape = _find_collision_shape_node(self)
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.shape = CircleShape2D.new()
		collision_shape.shape.radius = 16.0  # Radio base del enemigo
		add_child(collision_shape)

	# Crear componente de salud
	var hc_script = load("res://scripts/components/HealthComponent.gd")
	if hc_script:
		health_component = hc_script.new()
		health_component.name = "HealthComponent"
		add_child(health_component)
		health_component.initialize(max_hp)
		if health_component.has_signal("died"):
			health_component.died.connect(_on_health_died)

	# Crear sistema de ataque
	var eas_script = load("res://scripts/enemies/EnemyAttackSystem.gd")
	if eas_script:
		attack_system = eas_script.new()
		attack_system.name = "AttackSystem"
		add_child(attack_system)

	# Intentar usar AnimatedEnemySprite con spritesheet
	var spritesheet_loaded = _try_load_animated_sprite()

	# Si no hay spritesheet, usar sprite estático como fallback
	if not spritesheet_loaded:
		_load_static_sprite()
	
	# FIX: Eliminado VisibleOnScreenEnabler2D porque congelaba a los enemigos fuera de pantalla
	# impidiendo que se acercaran al jugador. En este género, los enemigos deben moverse siempre.

	# Configurar z_index
	self.z_index = 0
	
	# 124: Inicializar sistema de iconos de estado
	_initialize_status_icon_display()

	# CRÍTICO: Añadir al grupo "enemies" para que las armas puedan encontrarlos
	add_to_group("enemies")

	# Inicializar sistema de ataque
	if attack_system:
		attack_system.initialize(
			attack_cooldown,
			attack_range,
			damage,
			false,  # is_ranged
			null    # projectile_scene
		)

func _load_static_sprite() -> void:
	var sprite = _find_sprite_node(self)
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	_load_enemy_sprite(sprite)
	
	# Aplicar escala al sprite estático
	var enemy_scale = _get_scale_for_tier()
	if sprite:
		sprite.scale = Vector2(enemy_scale, enemy_scale)
		sprite.centered = true


func _exit_tree() -> void:
	var perf_tracker = get_node_or_null("/root/PerfTracker")
	if perf_tracker:
		perf_tracker.track_enemy_death()

func _initialize_status_icon_display() -> void:
	"""Inicializar display de iconos de estado para enemigos"""
	status_icon_display = StatusIconDisplay.new()
	status_icon_display.name = "StatusIconDisplay"
	status_icon_display.is_player = false
	status_icon_display.set_entity_type(false, is_boss)
	add_child(status_icon_display)
	
	# Calcular posición Y basándose en el tamaño real del sprite
	# Lo hacemos deferred para asegurar que el sprite está cargado
	call_deferred("_position_status_icons")

func _position_status_icons() -> void:
	"""Posicionar los iconos de estado encima del sprite del enemigo"""
	if not status_icon_display:
		return
	
	# Constantes de tamaño de iconos
	const ENEMY_ICON_SIZE: float = 14.0
	const BOSS_ICON_SIZE: float = 18.0
	
	# Calcular el alto visual del sprite en coordenadas locales
	var sprite_visual_top: float = -32.0  # Fallback: 32px encima del centro
	var icon_size: float = ENEMY_ICON_SIZE if not is_boss else BOSS_ICON_SIZE
	
	# Intentar obtener el bounding box real del sprite
	if animated_sprite and is_instance_valid(animated_sprite):
		# AnimatedEnemySprite: usar frame_height y escala
		var base_height: float = 0.0
		if animated_sprite.has_method("get_frame_size"):
			base_height = animated_sprite.get_frame_size().y
		elif "frame_height" in animated_sprite and animated_sprite.frame_height > 0:
			base_height = animated_sprite.frame_height
		elif animated_sprite.texture:
			base_height = animated_sprite.texture.get_height()
		
		if base_height > 0:
			var visual_height = base_height * animated_sprite.scale.y
			# El sprite está centrado, la parte superior es -altura/2
			sprite_visual_top = -(visual_height / 2.0)
	else:
		# Buscar Sprite2D estático
		var sprite = _find_sprite_node(self)
		if sprite and sprite.texture:
			var visual_height = sprite.texture.get_height() * sprite.scale.y
			if sprite.centered:
				sprite_visual_top = -(visual_height / 2.0)
			else:
				sprite_visual_top = -visual_height
		else:
			# Fallback basado en tier
			var scale_factor = _get_scale_for_tier()
			sprite_visual_top = -40.0 * scale_factor
	
	# Posicionar iconos encima del sprite con margen
	# Margen adicional: espacio para barra de vida (10px) + separación (6px)
	status_icon_display.position.y = sprite_visual_top - 16.0 - (icon_size / 2.0)

func _get_scale_for_tier() -> float:
	"""Obtener escala según tier del enemigo"""
	match enemy_tier:
		1: return 0.35
		2: return 0.45
		3: return 0.55
		4: return 0.65
		5: return 1.20  # Boss
		_: return 0.35

func _get_sprite() -> Node2D:
	"""Helper centralizado para obtener el sprite del enemigo (AnimatedEnemySprite o Sprite2D)"""
	if animated_sprite and is_instance_valid(animated_sprite):
		return animated_sprite
	return _find_sprite_node(self)

func _try_load_animated_sprite() -> bool:
	"""Intentar cargar AnimatedEnemySprite con spritesheet. Retorna true si tuvo éxito."""
	var spritesheet_path = _get_spritesheet_path()
	if spritesheet_path.is_empty() or not ResourceLoader.exists(spritesheet_path):
		return false

	# Cargar el script de AnimatedEnemySprite
	var aes_script = load("res://scripts/components/AnimatedEnemySprite.gd")
	if not aes_script:
		push_warning("[EnemyBase] No se pudo cargar AnimatedEnemySprite.gd")
		return false

	# Crear instancia
	animated_sprite = aes_script.new()
	animated_sprite.name = "AnimatedSprite"
	add_child(animated_sprite)

	# Configurar escala según tier
	var enemy_scale = _get_scale_for_tier()
	animated_sprite.sprite_scale = enemy_scale

	# Cargar spritesheet
	if animated_sprite.load_spritesheet(spritesheet_path):
		# Spritesheet cargado exitosamente

		# Eliminar Sprite2D existente si hay
		var old_sprite = _find_sprite_node(self)
		if old_sprite:
			old_sprite.queue_free()

		return true
	else:
		push_warning("[EnemyBase] Error cargando spritesheet: %s" % spritesheet_path)
		animated_sprite.queue_free()
		animated_sprite = null
		return false

func _get_spritesheet_path() -> String:
	"""Obtener la ruta del spritesheet basado en enemy_id y tier"""
	var base_path = "res://assets/sprites/enemies/"
	var tier_folder = ""
	var sprite_name = ""

	match enemy_tier:
		1: tier_folder = "tier_1/"
		2: tier_folder = "tier_2/"
		3: tier_folder = "tier_3/"
		4: tier_folder = "tier_4/"
		5: tier_folder = "bosses/"
		_: tier_folder = "tier_1/"

	# Mapear enemy_id a nombre de archivo de spritesheet
	match enemy_id:
		# Tier 1
		"skeleton", "tier_1_esqueleto_aprendiz": sprite_name = "esqueleto_aprendiz"
		"goblin", "tier_1_duende_sombrio": sprite_name = "duende_sombrio"
		"slime", "tier_1_slime_arcano": sprite_name = "slime_arcano"
		"tier_1_murcielago_etereo": sprite_name = "murcielago_etereo"
		"tier_1_arana_venenosa": sprite_name = "arana_venenosa"
		# Tier 2
		"tier_2_guerrero_espectral": sprite_name = "guerrero_espectral"
		"tier_2_lobo_de_cristal": sprite_name = "lobo_de_cristal"
		"tier_2_golem_runico": sprite_name = "golem_runico"
		"tier_2_hechicero_desgastado": sprite_name = "hechicero_desgastado"
		"tier_2_sombra_flotante": sprite_name = "sombra_flotante"
		# Tier 3
		"tier_3_caballero_del_vacio": sprite_name = "caballero_del_vacio"
		"tier_3_serpiente_de_fuego": sprite_name = "serpiente_de_fuego"
		"tier_3_elemental_de_hielo": sprite_name = "elemental_de_hielo"
		"tier_3_mago_abismal": sprite_name = "mago_abismal"
		"tier_3_corruptor_alado": sprite_name = "corruptor_alado"
		# Tier 4
		"tier_4_titan_arcano": sprite_name = "titan_arcano"
		"tier_4_senor_de_las_llamas": sprite_name = "senor_de_las_llamas"
		"tier_4_reina_del_hielo": sprite_name = "reina_del_hielo"
		"tier_4_archimago_perdido": sprite_name = "archimago_perdido"
		"tier_4_dragon_etereo": sprite_name = "dragon_etereo"
		# Bosses
		"boss_el_conjurador": sprite_name = "el_conjurador_primigenio"
		"boss_el_corazon": sprite_name = "el_corazon_del_vacio"
		"boss_el_guardian": sprite_name = "el_guardian_de_runas"
		"boss_minotauro": sprite_name = "minotauro_de_fuego"
		_: return ""  # No hay mapeo, usar sprite estático

	return base_path + tier_folder + sprite_name + "_spritesheet.png"

func initialize(data: Dictionary, player):
	"""Llamado desde EnemyManager para enemies creados dinámicamente"""
	enemy_id = data.get("id", enemy_id)
	enemy_tier = int(data.get("tier", enemy_tier))  # Obtener tier del diccionario
	max_hp = int(data.get("health", max_hp))
	hp = max_hp
	speed = float(data.get("speed", speed))
	damage = int(data.get("damage", damage))
	exp_value = int(data.get("exp_value", exp_value))
	player_ref = player
	
	# Pasar player al attack_system
	if attack_system:
		attack_system.player = player_ref

	# CRÍTICO: Re-inicializar HealthComponent con el HP correcto
	if health_component:
		health_component.initialize(max_hp)
	else:
		pass  # Bloque else
		# HealthComponent se creará en _ready(), así que diferimos
		call_deferred("_reinitialize_health_component")

	# Intentar usar AnimatedEnemySprite si no está ya cargado
	if not animated_sprite:
		var spritesheet_loaded = _try_load_animated_sprite()

		# Si no hay spritesheet, usar sprite estático como fallback
		if not spritesheet_loaded:
			var sprite = _find_sprite_node(self)
			if not sprite:
				sprite = Sprite2D.new()
				sprite.name = "Sprite2D"
				add_child(sprite)
			_load_enemy_sprite(sprite)

			# Aplicar escala al sprite estático
			var enemy_scale = _get_scale_for_tier()
			if sprite:
				sprite.scale = Vector2(enemy_scale, enemy_scale)
				sprite.centered = true
	else:
		pass  # Bloque else
		# Ya tiene animated_sprite, actualizar escala por si el tier cambió
		animated_sprite.sprite_scale = _get_scale_for_tier()

	# Debug de inicialización (comentado para producción)
	# print("[EnemyBase] ✓ Inicializado %s tier=%d animated=%s" % [enemy_id, enemy_tier, animated_sprite != null])

func initialize_from_database(data: Dictionary, player) -> void:
	"""Inicializar desde EnemyDatabase con todos los datos completos"""
	enemy_data = data.duplicate(true)

	# Datos básicos
	enemy_id = data.get("id", enemy_id)
	enemy_tier = int(data.get("tier", enemy_tier))

	# Stats (usar final_ si están calculados, sino base_)
	# Stats (usar final_ si están calculados, sino base_)
	max_hp = roundi(float(data.get("final_hp", data.get("base_hp", max_hp))))
	hp = max_hp
	speed = float(data.get("final_speed", data.get("base_speed", speed)))
	damage = roundi(float(data.get("final_damage", data.get("base_damage", damage))))
	exp_value = roundi(float(data.get("final_xp", data.get("base_xp", exp_value))))

	# Configuración de combate
	attack_range = float(data.get("attack_range", attack_range))
	attack_cooldown = float(data.get("attack_cooldown", attack_cooldown))

	# Colisión
	var collision_radius = float(data.get("collision_radius", 16.0))
	var collision_shape = _find_collision_shape_node(self)
	
	# FALLBACK: Si no existe collision shape (Headless/Race condition), crearlo ahora.
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		collision_shape.shape = CircleShape2D.new()
		add_child(collision_shape)
		
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = collision_radius

	# Arquetipo y comportamiento
	archetype = data.get("archetype", "melee")
	special_abilities = data.get("special_abilities", [])
	modifiers = data.get("modifiers", {})

	# Configurar comportamiento específico
	_setup_archetype_behavior()

	# Flags especiales
	is_elite = data.get("is_elite", false)
	is_boss = data.get("is_boss", false)

	if data.has("aura_color"):
		aura_color = data.aura_color
	if data.has("size_scale"):
		elite_size_scale = data.size_scale

	player_ref = player

	# Guardar velocidad base para efectos
	_base_speed = speed

	# Configurar visual
	_setup_enemy_visual()

	# Si es élite, crear aura
	if is_elite:
		_create_elite_aura()

	# Actualizar sistema de ataque con configuración completa (especialmente para bosses)
	if attack_system:
		attack_system.initialize_full({
			"attack_cooldown": attack_cooldown,
			"attack_range": attack_range,
			"damage": damage,
			"is_ranged": archetype in ["ranged", "teleporter"],
			"archetype": archetype,
			"element_type": _determine_element_from_id(enemy_id),
			"special_abilities": special_abilities,
			"modifiers": modifiers
		})
		
		# Pasar referencia al player para ataques
		attack_system.player = player_ref

		# Para bosses, pasar también los ability_cooldowns
		if is_boss and data.has("ability_cooldowns"):
			attack_system.modifiers["ability_cooldowns"] = data.ability_cooldowns

	# ═══════════════════════════════════════════════════════════════════════════════
	# CRÍTICO: Re-inicializar HealthComponent con el HP correcto
	# Nota: Si el HealthComponent aún no existe (antes de _ready), se usará call_deferred
	# para reinicializarlo después de que _ready() lo haya creado
	# ═══════════════════════════════════════════════════════════════════════════════
	if health_component:
		health_component.initialize(max_hp)
		# if is_boss:
		#	print("[EnemyBase] 🔥 BOSS HP reinicializado: %d/%d" % [health_component.current_health, health_component.max_health])
	else:
		pass  # Bloque else
		# HealthComponent se creará en _ready(), así que diferimos la reinicialización
		call_deferred("_reinitialize_health_component")

	# print("[EnemyBase] ✓ Inicializado desde DB: %s (T%d, %s) HP:%d SPD:%.0f DMG:%d" % [
	#	data.get("name", enemy_id), enemy_tier, archetype, max_hp, speed, damage
	# ])

func _reinitialize_health_component() -> void:
	"""Reinicializar el HealthComponent con el HP correcto (llamado después de _ready)"""
	if health_component:
		health_component.initialize(max_hp)
		# if is_boss:
		#	print("[EnemyBase] 🔥 BOSS HP reinicializado (deferred): %d/%d" % [health_component.current_health, health_component.max_health])

func _determine_element_from_id(id: String) -> String:
	"""Determinar elemento del enemigo basado en su ID"""
	var lower_id = id.to_lower()
	
	# Casos especiales primero
	if "hechicero" in lower_id:
		return "fire"  # Hechicero Desgastado es mago de fuego corrupto

	if "fuego" in lower_id or "fire" in lower_id or "minotauro" in lower_id:
		return "fire"
	if "hielo" in lower_id or "ice" in lower_id or "frost" in lower_id or "cristal" in lower_id:
		return "ice"
	if "void" in lower_id or "vacio" in lower_id or "shadow" in lower_id or "corazon" in lower_id:
		return "dark"
	if "arcano" in lower_id or "conjurador" in lower_id or "mago" in lower_id or "guardian" in lower_id or "runas" in lower_id:
		return "arcane"
	if "veneno" in lower_id or "poison" in lower_id:
		return "poison"
	if "rayo" in lower_id or "lightning" in lower_id:
		return "lightning"

	return "physical"

func _setup_archetype_behavior() -> void:
	"""Configurar comportamiento específico según arquetipo"""
	match archetype:
		"ranged":
			preferred_distance = modifiers.get("preferred_distance", 180.0)
		"charger":
			charge_cooldown_timer = modifiers.get("charge_cooldown", 4.0)
		"phase":
			phase_cooldown_timer = modifiers.get("phase_cooldown", 6.0)
		"teleporter":
			teleport_cooldown_timer = modifiers.get("teleport_cooldown", 5.0)
		"agile":
			zigzag_timer = 0.0
		"tank":
			# Los tanks tienen reducción de daño
			pass
		"support", "aoe", "breath", "multi":
			ability_cooldown_timer = 0.0

func _setup_enemy_visual() -> void:
	"""Configurar sprites y escala"""
	# Intentar usar AnimatedEnemySprite si no está ya cargado
	if not animated_sprite:
		var spritesheet_loaded = _try_load_animated_sprite()

		if not spritesheet_loaded:
			var sprite = _find_sprite_node(self)
			if not sprite:
				sprite = Sprite2D.new()
				sprite.name = "Sprite2D"
				add_child(sprite)
			_load_enemy_sprite(sprite)

			var enemy_scale = _get_scale_for_tier()
			if is_boss:
				enemy_scale *= 2.5  # Los bosses son 2.5x más grandes
			elif is_elite:
				enemy_scale *= elite_size_scale
			if sprite:
				sprite.scale = Vector2(enemy_scale, enemy_scale)
				sprite.centered = true
	else:
		var enemy_scale = _get_scale_for_tier()
		if is_boss:
			enemy_scale *= 2.5  # Los bosses son 2.5x más grandes
		elif is_elite:
			enemy_scale *= elite_size_scale
		animated_sprite.sprite_scale = enemy_scale

func _create_elite_aura() -> void:
	"""Crear efecto visual para enemigos élite: shader de glow"""
	_apply_elite_glow_shader()

func _apply_elite_glow_shader() -> void:
	"""Aplica un shader de glow RGB cycling al sprite del enemigo élite"""
	# Buscar el sprite principal del enemigo
	var target_sprite: Node = null
	if animated_sprite:
		target_sprite = animated_sprite
	else:
		target_sprite = _find_sprite_node(self)
	
	if not target_sprite:
		return
	
	# Shader con glow reducido + transición RGB gaming keyboard "breath"
	var shader_code = """
shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 5.0) = 2.5;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.5;
uniform float glow_size : hint_range(0.0, 50.0) = 8.0;
uniform float tint_strength : hint_range(0.0, 0.6) = 0.25;
uniform float color_cycle_speed : hint_range(0.0, 3.0) = 0.4;
uniform float hue_offset : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 1.0) = 0.85;

// HSV → RGB conversion
vec3 hsv2rgb(float h, float s, float v) {
	vec3 c = vec3(h, s, v);
	vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec2 ps = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
	
	// Hue cycling — smooth rainbow transition
	float hue = fract(TIME * color_cycle_speed + hue_offset);
	vec3 glow_rgb = hsv2rgb(hue, saturation, 1.0);
	
	// Pulse breathing
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	float gs = glow_size * pulse;
	
	// Dos anillos de muestreo (8 muestras cada uno) — más eficiente y compacto
	float ring_outer = 0.0;
	float ring_inner = 0.0;
	
	for (float a = 0.0; a < 6.28; a += 0.785) {
		vec2 dir = vec2(cos(a), sin(a));
		ring_outer = max(ring_outer, texture(TEXTURE, UV + dir * ps * gs).a);
		ring_inner = max(ring_inner, texture(TEXTURE, UV + dir * ps * gs * 0.4).a);
	}
	
	float glow = ring_inner * 1.0 + ring_outer * 0.6;
	glow = clamp(glow, 0.0, 1.0);
	
	if (original.a < 0.1 && glow > 0.05) {
		float ga = glow * glow_intensity * pulse * 0.65;
		COLOR = vec4(glow_rgb, clamp(ga, 0.0, 0.9));
	} else if (original.a >= 0.1) {
		vec3 tinted = mix(original.rgb, glow_rgb, tint_strength * pulse);
		COLOR = vec4(tinted, original.a);
	} else {
		COLOR = original;
	}
}
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Cada tier tiene un offset de hue diferente + velocidad de ciclo, pero TODOS hacen rainbow
	var tier_configs = [
		{"hue_offset": 0.0, "cycle_speed": 0.35, "saturation": 0.80, "glow_size": 7.0},   # Tier 1: RGB suave
		{"hue_offset": 0.33, "cycle_speed": 0.50, "saturation": 0.85, "glow_size": 8.0},  # Tier 2: RGB medio
		{"hue_offset": 0.66, "cycle_speed": 0.70, "saturation": 0.90, "glow_size": 9.0},  # Tier 3: RGB intenso + rápido
	]
	var config_index = (enemy_tier - 1) % tier_configs.size()
	var cfg = tier_configs[config_index]
	
	material.set_shader_parameter("glow_intensity", 2.5)
	material.set_shader_parameter("pulse_speed", 2.5)
	material.set_shader_parameter("glow_size", cfg["glow_size"])
	material.set_shader_parameter("tint_strength", 0.25)
	material.set_shader_parameter("color_cycle_speed", cfg["cycle_speed"])
	material.set_shader_parameter("hue_offset", cfg["hue_offset"])
	material.set_shader_parameter("saturation", cfg["saturation"])
	
	target_sprite.material = material

func _find_sprite_node(node: Node) -> Sprite2D:
	"""Buscar el primer Sprite2D en el árbol del nodo"""
	for child in node.get_children():
		if child is Sprite2D:
			return child
	return null

func _find_collision_shape_node(node: Node) -> CollisionShape2D:
	"""Buscar el primer CollisionShape2D en el árbol del nodo"""
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null

func _load_enemy_sprite(sprite: Sprite2D) -> void:
	"""Cargar la textura del sprite según enemy_id y enemy_tier"""
	if not sprite:
		return

	# Mapeo de enemy_id a índice en sprites_index.json
	var sprite_paths = []
	match enemy_tier:
		1:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_1/slime_arcano.png",
				"res://assets/sprites/enemies/tier_1/murcielago_etereo.png",
				"res://assets/sprites/enemies/tier_1/esqueleto_aprendiz.png",
				"res://assets/sprites/enemies/tier_1/arana_venenosa.png",
				"res://assets/sprites/enemies/tier_1/duende_sombrio.png"
			]
		2:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_2/guerrero_espectral.png",
				"res://assets/sprites/enemies/tier_2/lobo_de_cristal.png",
				"res://assets/sprites/enemies/tier_2/golem_runico.png",
				"res://assets/sprites/enemies/tier_2/hechicero_desgastado.png",
				"res://assets/sprites/enemies/tier_2/sombra_flotante.png"
			]
		3:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_3/caballero_del_vacio.png",
				"res://assets/sprites/enemies/tier_3/serpiente_de_fuego.png",
				"res://assets/sprites/enemies/tier_3/elemental_de_hielo.png",
				"res://assets/sprites/enemies/tier_3/mago_abismal.png",
				"res://assets/sprites/enemies/tier_3/corruptor_alado.png"
			]
		4:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_4/titan_arcano.png",
				"res://assets/sprites/enemies/tier_4/senor_de_las_llamas.png",
				"res://assets/sprites/enemies/tier_4/reina_del_hielo.png",
				"res://assets/sprites/enemies/tier_4/archimago_perdido.png",
				"res://assets/sprites/enemies/tier_4/dragon_etereo.png"
			]
		5:  # Boss
			sprite_paths = [
				"res://assets/sprites/enemies/bosses/el_conjurador_primigenio.png",
				"res://assets/sprites/enemies/bosses/el_corazon_del_vacio.png",
				"res://assets/sprites/enemies/bosses/el_guardian_de_runas.png",
				"res://assets/sprites/enemies/bosses/minotauro_de_fuego.png"
			]

	# Mapeo de enemy_id a índice
	var sprite_index = 0
	match enemy_id:
		# Tier 1
		"skeleton": sprite_index = 2  # esqueleto_aprendiz
		"goblin": sprite_index = 4    # duende_sombrio
		"slime": sprite_index = 0     # slime_arcano
		"tier_1_murcielago_etereo": sprite_index = 1
		"tier_1_arana_venenosa": sprite_index = 3
		# Tier 2
		"tier_2_guerrero_espectral": sprite_index = 0
		"tier_2_lobo_de_cristal": sprite_index = 1
		"tier_2_golem_runico": sprite_index = 2
		"tier_2_hechicero_desgastado": sprite_index = 3
		"tier_2_sombra_flotante": sprite_index = 4
		# Tier 3
		"tier_3_caballero_del_vacio": sprite_index = 0
		"tier_3_serpiente_de_fuego": sprite_index = 1
		"tier_3_elemental_de_hielo": sprite_index = 2
		"tier_3_mago_abismal": sprite_index = 3
		"tier_3_corruptor_alado": sprite_index = 4
		# Tier 4
		"tier_4_titan_arcano": sprite_index = 0
		"tier_4_senor_de_las_llamas": sprite_index = 1
		"tier_4_reina_del_hielo": sprite_index = 2
		"tier_4_archimago_perdido": sprite_index = 3
		"tier_4_dragon_etereo": sprite_index = 4
		# Bosses
		"boss_el_conjurador": sprite_index = 0
		"boss_el_corazon": sprite_index = 1
		"boss_el_guardian": sprite_index = 2
		"boss_minotauro": sprite_index = 3

	# Cargar la textura
	if sprite_index < sprite_paths.size():
		var sprite_path = sprite_paths[sprite_index]
		if ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			if texture:
				sprite.texture = texture
			else:
				push_warning("[EnemyBase] Error cargando textura: %s" % sprite_path)
		else:
			push_warning("[EnemyBase] Ruta de sprite no existe: %s" % sprite_path)

func _physics_process(delta: float) -> void:
	# Procesar efectos de estado primero
	_process_status_effects(delta)

	# FIX FASE 2: Burn aura pasiva (Señor de las Llamas y similares)
	if has_meta("burn_aura") and get_meta("burn_aura"):
		_process_burn_aura(delta)

	# Actualizar cooldowns de habilidades
	_update_ability_cooldowns(delta)

	# Si está stunneado, no moverse
	if _is_stunned:
		return

	# Si está en fase (intangible), comportamiento especial
	if is_phased:
		_process_phase_movement(delta)
		return

	# Si está cargando, continuar carga
	if is_charging:
		_process_charge(delta)
		return

	# Usar GLOBAL_POSITION para ignorar que el parent se mueve
	var player_global_pos = Vector2.ZERO
	if player_ref and is_instance_valid(player_ref):
		player_global_pos = player_ref.global_position

	var distance_to_player = global_position.distance_to(player_global_pos)

	# Calcular dirección hacia el player en coordenadas GLOBALES
	var direction = (player_global_pos - global_position).normalized() if global_position != player_global_pos else Vector2.ZERO

	# Actualizar dirección del sprite animado si existe
	if animated_sprite and direction.length() > 0.1:
		current_direction = direction
		animated_sprite.set_direction(direction)

	# Si está siendo atraído (pull), no calcular movimiento normal
	if _is_pulled:
		return

	# Calcular movimiento según arquetipo
	var movement = _calculate_archetype_movement(direction, distance_to_player, delta)

	# -----------------------------------------------------------
	# LÓGICA DE NUEVOS OBJETOS (Phase 4)
	# 8. Crono-Salto (Chrono Jump): Enemigos 50% más lentos
	# Cachear referencia a PlayerStats
	if not is_instance_valid(_cached_player_stats):
		_cached_player_stats = get_tree().get_first_node_in_group("player_stats")
	if _cached_player_stats and _cached_player_stats.has_method("get_stat") and _cached_player_stats.get_stat("chrono_jump_active") > 0:
		movement *= 0.5
	# -----------------------------------------------------------

	# Calcular separación de otros enemigos
	var separation = _calculate_separation()

	# Combinar movimiento
	movement = movement + separation

	# Si hay movimiento, aplicar
	if movement.length() > 0.1:
		global_position += movement * delta
		
		# Aplicar colisión con decorados
		# Usar offset hacia los pies del enemigo (similar a player pero más pequeño)
		if not is_instance_valid(_cached_decor_manager):
			_cached_decor_manager = get_tree().get_first_node_in_group("decor_collision_manager")
		if _cached_decor_manager and _cached_decor_manager.has_method("check_collision_fast"):
			var feet_offset = 25.0  # Enemigos son más pequeños que el player
			var collision_pos = global_position + Vector2(0, feet_offset)
			var push = _cached_decor_manager.check_collision_fast(collision_pos, 12.0)
			if push.length_squared() > 0.1:
				global_position += push

	# Ejecutar habilidades especiales si aplica
	_try_special_abilities(distance_to_player, delta)

	# NOTA: El ataque ahora lo maneja EnemyAttackSystem para evitar daño duplicado
	# La lógica legacy de _attempt_attack() está deshabilitada
	# if distance_to_player <= attack_range:
	#	if can_attack:
	#		_attempt_attack()

	# Actualizar cooldown de ataque (legacy, ya no se usa)
	# if not can_attack:
	#	attack_timer -= delta
	#	if attack_timer <= 0:
	#		can_attack = true
	#		attack_timer = 0.0

func _update_ability_cooldowns(delta: float) -> void:
	"""Actualizar cooldowns de habilidades especiales"""
	if charge_cooldown_timer > 0:
		charge_cooldown_timer -= delta
	if phase_cooldown_timer > 0:
		phase_cooldown_timer -= delta
	if teleport_cooldown_timer > 0:
		teleport_cooldown_timer -= delta
	if ability_cooldown_timer > 0:
		ability_cooldown_timer -= delta
	if trail_timer > 0:
		trail_timer -= delta

func _calculate_archetype_movement(direction: Vector2, distance: float, delta: float) -> Vector2:
	"""Calcular movimiento según el arquetipo del enemigo"""
	var movement = Vector2.ZERO

	match archetype:
		"melee", "tank", "blocker", "debuffer":
			# Movimiento directo hacia el jugador
			movement = direction * speed

		"agile":
			# Movimiento en zigzag
			zigzag_timer += delta
			if zigzag_timer > 0.3:
				zigzag_timer = 0.0
				zigzag_direction *= -1

			var perpendicular = Vector2(-direction.y, direction.x)
			movement = (direction + perpendicular * zigzag_direction * 0.5).normalized() * speed * 1.2

		"flying":
			# Movimiento errático
			var noise_offset = sin(Time.get_ticks_msec() * 0.005) * 0.3
			var perpendicular = Vector2(-direction.y, direction.x)
			movement = (direction + perpendicular * noise_offset).normalized() * speed

		"ranged", "teleporter":
			# Mantener distancia
			if distance < preferred_distance * 0.8:
				# Alejarse
				movement = -direction * speed * 0.7
			elif distance > preferred_distance * 1.2:
				# Acercarse
				movement = direction * speed * 0.5
			else:
				pass  # Bloque else
				# Movimiento lateral para esquivar
				var perpendicular = Vector2(-direction.y, direction.x)
				movement = perpendicular * sin(Time.get_ticks_msec() * 0.003) * speed * 0.3

		"pack":
			# Movimiento normal pero buscar otros lobos
			movement = direction * speed
			# Bonus de velocidad si hay pack cerca
			var pack_count = _count_nearby_pack_members()
			var speed_bonus = modifiers.get("pack_speed_bonus", 0.05)
			movement *= (1.0 + pack_count * speed_bonus)

		"charger":
			# Movimiento normal, la carga se maneja en _try_special_abilities
			movement = direction * speed

		"phase":
			# Movimiento normal cuando no está en fase
			movement = direction * speed

		"trail":
			# Movimiento normal, dejar trail
			movement = direction * speed

		"support":
			# Mantenerse cerca de aliados
			var ally_center = _get_nearby_allies_center()
			if ally_center != Vector2.ZERO:
				var to_allies = (ally_center - global_position).normalized()
				movement = (direction * 0.5 + to_allies * 0.5).normalized() * speed
			else:
				movement = direction * speed

		"aoe", "breath", "multi":
			# Movimiento moderado, prefiere rango medio
			if distance < 100:
				movement = -direction * speed * 0.5
			else:
				movement = direction * speed * 0.7

		"boss":
			# Los bosses tienen patrones especiales
			movement = direction * speed

		_:
			movement = direction * speed

	return movement

func _try_special_abilities(distance: float, _delta: float) -> void:
	"""Intentar usar habilidades especiales según arquetipo"""

	# CHARGER: Carga hacia el jugador
	if archetype == "charger" and charge_cooldown_timer <= 0 and not is_charging:
		var charge_distance = modifiers.get("charge_distance", 200.0)
		if distance > 80 and distance < charge_distance:
			_start_charge()

	# PHASE: Volverse intangible
	if archetype == "phase" and phase_cooldown_timer <= 0 and not is_phased:
		# Activar fase si recibió daño recientemente o está en peligro
		if hp < max_hp * 0.7:
			_start_phase()

	# TELEPORTER: Teletransportarse
	if archetype == "teleporter" and teleport_cooldown_timer <= 0:
		var threshold = modifiers.get("teleport_health_threshold", 0.4)
		if hp < max_hp * threshold:
			_do_teleport()

	# TRAIL: Dejar rastro de fuego
	if archetype == "trail" and trail_timer <= 0:
		trail_timer = modifiers.get("trail_interval", 0.2)
		_spawn_fire_trail()

	# SUPPORT: Buff a aliados
	if archetype == "support" and ability_cooldown_timer <= 0:
		ability_cooldown_timer = modifiers.get("buff_cooldown", 8.0)
		_buff_nearby_allies()

	# PACK: Daño bonus por aliados cercanos (pasivo, se aplica en ataque)

func _start_charge() -> void:
	"""Iniciar carga hacia el jugador"""
	if not player_ref or not is_instance_valid(player_ref):
		return

	is_charging = true
	charge_target = player_ref.global_position
	charge_cooldown_timer = modifiers.get("charge_cooldown", 4.0)

	# Visual: cambiar color brevemente
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.2)

	# print("[EnemyBase] ⚡ %s inicia carga!" % enemy_id)

func _process_charge(delta: float) -> void:
	"""Procesar movimiento de carga"""
	var charge_speed = modifiers.get("charge_speed", 300.0)
	var direction = (charge_target - global_position).normalized()

	global_position += direction * charge_speed * delta

	# Verificar si llegamos al destino o pasamos
	if global_position.distance_to(charge_target) < 20:
		_end_charge()

	# Verificar colisión con jugador durante carga
	if player_ref and is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) < attack_range:
			# Aplicar daño de carga
			var charge_damage_mult = modifiers.get("charge_damage_mult", 2.0)
			var charge_damage = int(damage * charge_damage_mult)
			if player_ref.has_method("take_damage"):
				var elem = _determine_element_from_id(enemy_id)
				player_ref.call("take_damage", charge_damage, elem)
				# print("[EnemyBase] ⚡ %s impacta carga por %d daño!" % [enemy_id, charge_damage])
				# Aplicar stun en carga
				if player_ref.has_method("apply_stun"):
					player_ref.apply_stun(0.5)  # 0.5s stun
					# print("[EnemyBase] ⚡ Carga aplica Stun!")
			_end_charge()

func _end_charge() -> void:
	"""Terminar carga"""
	is_charging = false

	# Restaurar color
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", _current_status_color, 0.2)

func _start_phase() -> void:
	"""Activar modo fase (intangible)"""
	is_phased = true
	phase_cooldown_timer = modifiers.get("phase_cooldown", 6.0)

	# Visual: semi-transparente
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.3)

	# Desactivar colisión temporalmente
	set_collision_layer_value(2, false)

	# Timer para terminar fase (con verificación de validez)
	var phase_duration = modifiers.get("phase_duration", 1.5)
	get_tree().create_timer(phase_duration).timeout.connect(func():
		if is_instance_valid(self):
			_end_phase()
	)

	# print("[EnemyBase] 👻 %s entra en fase!" % enemy_id)

func _process_phase_movement(delta: float) -> void:
	"""Movimiento durante fase (más rápido, atraviesa)"""
	if not player_ref or not is_instance_valid(player_ref):
		return

	var direction = (player_ref.global_position - global_position).normalized()
	var phase_speed = speed * modifiers.get("phase_speed_bonus", 1.5)
	global_position += direction * phase_speed * delta

func _end_phase() -> void:
	"""Terminar modo fase"""
	is_phased = false

	# Restaurar visual
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

	# Reactivar colisión
	set_collision_layer_value(2, true)

func _do_teleport() -> void:
	"""Teletransportarse a una posición segura"""
	teleport_cooldown_timer = modifiers.get("teleport_cooldown", 5.0)

	var teleport_range = modifiers.get("teleport_range", 150.0)

	# Calcular posición de teleport (lejos del jugador)
	var player_pos = Vector2.ZERO
	if player_ref and is_instance_valid(player_ref):
		player_pos = player_ref.global_position

	var away_direction = (global_position - player_pos).normalized()
	var new_pos = global_position + away_direction * teleport_range

	# Añadir algo de variación
	new_pos += Vector2(randf_range(-50, 50), randf_range(-50, 50))

	# Visual de teleport
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): global_position = new_pos)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.15)
	else:
		global_position = new_pos

	# print("[EnemyBase] ✨ %s se teletransporta!" % enemy_id)

func _spawn_fire_trail() -> void:
	"""Crear una zona de fuego en la posición actual que daña al player"""
	var trail_damage = modifiers.get("trail_damage", 5)
	var trail_duration = modifiers.get("trail_duration", 2.0)
	var trail_radius = modifiers.get("trail_radius", 30.0)

	# print("[EnemyBase] 🔥 %s crea fire trail (damage=%d, dur=%.1fs, radius=%.0f)" % [enemy_id, trail_damage, trail_duration, trail_radius])

	# Crear nodo de trail
	var trail = Area2D.new()
	trail.name = "FireTrail"
	trail.global_position = global_position

	# Configurar colisión
	trail.collision_layer = 0
	trail.set_collision_layer_value(4, true)  # EnemyProjectile layer
	trail.collision_mask = 0
	trail.set_collision_mask_value(1, true)  # Player layer

	# Añadir collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = trail_radius
	collision.shape = shape
	trail.add_child(collision)

	# Visual mejorado del trail - Múltiples capas para efecto de fuego
	var visual = Node2D.new()
	visual.name = "Visual"
	trail.add_child(visual)

	# Variables para animación
	var time_offset = randf() * TAU
	var flame_count = 6

	visual.draw.connect(func():
		var time = Time.get_ticks_msec() * 0.004 + time_offset

		# Capa base - núcleo amarillo
		visual.draw_circle(Vector2.ZERO, trail_radius * 0.3, Color(1, 0.9, 0.3, 0.8))

		# Capa media - naranja pulsante
		var pulse = 0.9 + sin(time * 3) * 0.1
		visual.draw_circle(Vector2.ZERO, trail_radius * 0.6 * pulse, Color(1, 0.5, 0.1, 0.5))

		# Capa exterior - rojo translúcido
		visual.draw_circle(Vector2.ZERO, trail_radius * 0.9, Color(1, 0.2, 0.0, 0.3))

		# Llamas individuales animadas
		for i in range(flame_count):
			var angle = (TAU / flame_count) * i + time * 0.5
			var flame_dist = trail_radius * (0.4 + sin(time * 2 + i) * 0.2)
			var flame_pos = Vector2(cos(angle), sin(angle)) * flame_dist
			var flame_size = trail_radius * (0.15 + sin(time * 4 + i * 2) * 0.05)

			# Dibujar llama como triángulo hacia arriba
			var flame_tip = flame_pos + Vector2(0, -flame_size * 2)
			var flame_left = flame_pos + Vector2(-flame_size, flame_size * 0.5)
			var flame_right = flame_pos + Vector2(flame_size, flame_size * 0.5)
			var flame_points = PackedVector2Array([flame_tip, flame_left, flame_right])
			visual.draw_colored_polygon(flame_points, Color(1, 0.6, 0.1, 0.7))

		# Borde exterior brillante
		visual.draw_arc(Vector2.ZERO, trail_radius, 0, TAU, 24, Color(1, 0.4, 0.0, 0.9), 3.0)
	)
	visual.queue_redraw()

	# Timer para actualizar animación (150ms = 6.7 FPS, suficiente para fuego ambiental)
	var anim_timer = Timer.new()
	anim_timer.wait_time = 0.15
	anim_timer.autostart = true
	trail.add_child(anim_timer)
	anim_timer.timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_redraw()
	)

	# Añadir al mundo
	var parent = get_parent()
	if parent:
		parent.add_child(trail)

	# Timer de daño periódico
	var damage_interval = 0.5
	var damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.autostart = true
	trail.add_child(damage_timer)

	# Cachear referencia al player para evitar lookup cada 0.5s
	var _trail_player_ref = get_tree().get_first_node_in_group("player")
	damage_timer.timeout.connect(func():
		if not is_instance_valid(trail):
			return
		# Verificar player cacheado
		if not is_instance_valid(_trail_player_ref):
			_trail_player_ref = get_tree().get_first_node_in_group("player")
		if _trail_player_ref:
			var dist = _trail_player_ref.global_position.distance_to(trail.global_position)
			if dist <= trail_radius:
				if _trail_player_ref.has_method("take_damage"):
					_trail_player_ref.call("take_damage", trail_damage, "fire")
	)

	# Auto-destruir después de duration
	get_tree().create_timer(trail_duration).timeout.connect(func():
		if is_instance_valid(trail):
			trail.queue_free()
	)

	# Fade out visual
	var tween = create_tween()
	tween.tween_interval(trail_duration * 0.7)
	tween.tween_property(visual, "modulate:a", 0.0, trail_duration * 0.3)

func _buff_nearby_allies() -> void:
	"""Buffear aliados cercanos"""
	var buff_radius = modifiers.get("buff_radius", 150.0)

	var nearby = SpatialGrid.get_nearby_excluding(global_position, buff_radius, self)
	for enemy in nearby:
		# Aplicar buff de velocidad temporal
		var speed_bonus = modifiers.get("buff_speed_bonus", 0.15)
		if enemy.has_method("apply_speed_buff"):
			enemy.apply_speed_buff(speed_bonus, modifiers.get("buff_duration", 5.0))

	# print("[EnemyBase] 💪 %s buffea aliados cercanos!" % enemy_id)

func apply_speed_buff(amount: float, duration: float) -> void:
	"""Recibir buff de velocidad de un support"""
	if _base_speed == 0:
		_base_speed = speed

	speed = _base_speed * (1.0 + amount)

	# Mostrar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("speed_buff", duration)

	# Timer para quitar el buff (con verificación de validez)
	get_tree().create_timer(duration).timeout.connect(func():
		if not is_instance_valid(self):
			return
		if _base_speed > 0:
			speed = _base_speed * (1.0 - _slow_amount if _is_slowed else 1.0)
		if status_icon_display:
			status_icon_display.remove_effect("speed_buff")
	)

func _count_nearby_pack_members() -> int:
	"""Contar aliados del mismo tipo cercanos (para pack bonus)"""
	var count = 0
	var pack_radius = modifiers.get("pack_radius", 200.0)
	var max_pack = modifiers.get("max_pack_bonus", 3)

	var nearby = SpatialGrid.get_nearby_excluding(global_position, pack_radius, self)
	for enemy in nearby:
		# Solo contar si es del mismo tipo
		if enemy.get("archetype") == "pack":
			count += 1
			if count >= max_pack:
				break

	return count

func _get_nearby_allies_center() -> Vector2:
	"""Obtener centro de aliados cercanos (para support)"""
	var center = Vector2.ZERO
	var count = 0
	var buff_radius = modifiers.get("buff_radius", 150.0)

	var nearby = SpatialGrid.get_nearby_excluding(global_position, buff_radius, self)
	for enemy in nearby:
		center += enemy.global_position
		count += 1

	if count > 0:
		center /= count

	return center

func _calculate_separation() -> Vector2:
	"""Calcular vector de separación respecto a otros enemigos cercanos"""
	var separation = Vector2.ZERO
	var nearby_enemies = 0

	if not get_tree():
		return separation

	var nearby = SpatialGrid.get_nearby_excluding(global_position, separation_radius, self)
	for other in nearby:
		var dist = global_position.distance_to(other.global_position)
		if dist > 0:
			# Empujar lejos del otro enemigo
			var push_direction = (global_position - other.global_position).normalized()
			var push_strength = (separation_radius - dist) / separation_radius
			separation += push_direction * push_strength * speed * 0.3
			nearby_enemies += 1

	# Promediar si hay múltiples enemigos
	if nearby_enemies > 0:
		separation = separation / nearby_enemies

	return separation

func _attempt_attack() -> void:
	"""Intentar atacar al player. Puede ser sobrescrito en subclases"""
	can_attack = false
	attack_timer = attack_cooldown

	# Verificar que tenemos referencia al jugador
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	# Verificar precisión (afectada por ceguera)
	var accuracy = get_attack_accuracy()
	if accuracy < 1.0 and randf() > accuracy:
		# ¡Falló el ataque debido a ceguera!
		# print("[EnemyBase] 👁️ %s falló ataque (cegado, %.0f%% precisión)" % [enemy_id, accuracy * 100])
		return

	# Calcular daño según arquetipo
	var final_damage = damage

	# PACK: Bonus de daño por aliados cercanos
	if archetype == "pack":
		var pack_count = _count_nearby_pack_members()
		var damage_bonus = modifiers.get("pack_damage_bonus", 0.15)
		final_damage = int(damage * (1.0 + pack_count * damage_bonus))

	# BLOCKER: Chance de contraataque
	if archetype == "blocker":
		var counter_damage = modifiers.get("counter_damage", 1.5)
		# El contraataque se aplicaría aquí si el jugador acaba de atacar

	# Determinar elemento del ataque
	var attack_element = _determine_element_from_id(enemy_id)

	# Aplicar daño al jugador (pasando self para thorns)
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(final_damage, attack_element, self)
		# print("[EnemyBase] ⚔️ %s ataca al jugador: %d daño (%s)" % [enemy_id, final_damage, attack_element])

		# Efecto visual de ataque en el enemigo
		_play_attack_animation()

func take_damage(amount: int, _element: String = "physical", _attacker: Node = null) -> void:
	"""Recibir daño del enemigo"""
	var final_damage = amount
	var is_blocked = false

	# Debug para bosses
	if is_boss:
		var current_hp = health_component.current_health if health_component else hp
		# print("[Boss] Daño recibido: %d (HP actual: %d)" % [amount, current_hp])

	# BLOCKER: Chance de bloquear
	if archetype == "blocker":
		var block_chance = modifiers.get("block_chance", 0.25)
		if randf() < block_chance:
			var block_reduction = modifiers.get("block_reduction", 0.7)
			final_damage = int(amount * (1.0 - block_reduction))
			is_blocked = true
			# Visual de bloqueo
			_flash_block()

	# FIX FASE 2/3: Evasion check (Murciélago Etéreo y otros con meta evasion_chance)
	if has_meta("evasion_chance"):
		var evasion_chance = get_meta("evasion_chance")
		if randf() < evasion_chance:
			# Esquivó el ataque
			FloatingText.spawn_damage(global_position + Vector2(0, -20), 0, false) if FloatingText else null
			return

	# FIX FASE 3: Shield charges (boss rune_shield y elite_shield)
	if has_meta("shield_active") and get_meta("shield_active"):
		var charges = get_meta("shield_charges")
		if charges > 0:
			set_meta("shield_charges", charges - 1)
			final_damage = int(final_damage * 0.1)  # Escudo absorbe 90%
			if charges - 1 <= 0:
				set_meta("shield_active", false)
	
	# FIX FASE 3: Elite shield charges
	var _attack_sys = get_node_or_null("EnemyAttackSystem")
	if _attack_sys and "elite_shield_charges" in _attack_sys and _attack_sys.elite_shield_charges > 0:
		_attack_sys.elite_shield_charges -= 1
		final_damage = int(final_damage * 0.15)  # Elite shield absorbe 85%

	# FIX FASE 2: Ice armor (Reina del Hielo - reducción de daño pasiva)
	if has_meta("ice_armor") and get_meta("ice_armor"):
		var ice_reduction = get_meta("ice_armor_reduction") if has_meta("ice_armor_reduction") else 0.2
		final_damage = int(final_damage * (1.0 - ice_reduction))

	# TANK: Reducción de daño pasiva
	if archetype == "tank" or modifiers.has("damage_reduction"):
		var reduction = modifiers.get("damage_reduction", 0.0)
		final_damage = int(final_damage * (1.0 - reduction))

	# FIX FASE 3: Counter stance reflection (Guardián de Runas boss)
	if has_meta("counter_stance_active") and get_meta("counter_stance_active"):
		var counter_mult = get_meta("counter_damage_mult") if has_meta("counter_damage_mult") else 2.0
		var counter_damage = int(amount * counter_mult)
		if _attacker and _attacker.has_method("take_damage"):
			_attacker.take_damage(counter_damage, "arcane", self)

	# Aplicar bonus de shadow_mark si está marcado
	if _is_shadow_marked:
		final_damage = int(final_damage * (1.0 + _shadow_mark_bonus))

	# Mostrar texto flotante de daño
	# REMOVED: Now handled by HealthComponent to avoid duplicates
	# if final_damage > 0:
	#	var is_crit = final_damage >= amount * 1.5  # Detectar crítico
	#	FloatingText.spawn_damage(global_position + Vector2(0, -20), final_damage, is_crit)


	# Calcular HP actual antes del daño para overkill
	var hp_before = health_component.current_health if health_component else hp

	# TELEMETRY: Log damage dealt to enemies (source of truth)
	if final_damage > 0 and BalanceDebugger:
		BalanceDebugger.log_damage_dealt(final_damage)
	
	# STATS: Incrementar damage_dealt en run_stats de Game
	if final_damage > 0:
		var game_node = get_tree().root.get_node_or_null("Game")
		if not game_node:
			game_node = get_tree().root.get_node_or_null("LoopiaLikeGame")
		if game_node and game_node.has_method("add_damage_stat"):
			game_node.add_damage_stat(final_damage)
	
	# AUDIT: Preparar tracking para RunAuditTracker
	# FIX-BT6: Cadena de fallback para weapon_id en vez de solo "unknown"
	var _audit_weapon_id := "unknown"
	var _audit_is_crit: bool = false
	if final_damage > 0 and RunAuditTracker and RunAuditTracker.ENABLE_AUDIT:
		_audit_is_crit = final_damage >= int(amount * 1.5)
		if _attacker and is_instance_valid(_attacker) and _attacker.has_meta("weapon_id"):
			var wid = _attacker.get_meta("weapon_id")
			if wid != "" and wid != null:
				_audit_weapon_id = wid
		# Fallback: usar elemento del daño para categorizar fuentes sin weapon_id
		if _audit_weapon_id == "unknown":
			if _element != "" and _element != "physical":
				_audit_weapon_id = "effect_" + _element  # e.g. "effect_fire", "effect_explosion"
			elif _attacker == null:
				_audit_weapon_id = "passive_effect"  # DOTs, overkill, etc.

	# Aplicar daño a través del HealthComponent
	if health_component:
		health_component.take_damage(final_damage, _element)
	else:
		pass  # Bloque else
		# Fallback si no hay HealthComponent (no debería pasar)
		hp -= final_damage
		if hp <= 0:
			die()
	
	# AUDIT: Report damage + kill DESPUÉS de aplicar daño (para saber si murió)
	if final_damage > 0 and RunAuditTracker and RunAuditTracker.ENABLE_AUDIT:
		var hp_now = health_component.current_health if health_component else hp
		var was_killed = hp_now <= 0
		RunAuditTracker.report_damage_dealt(_audit_weapon_id, _audit_weapon_id, final_damage, _audit_is_crit, [], was_killed)

	# Sistema de OVERKILL: Transferir daño excedente a enemigos cercanos
	# PERO NO si este daño vino de otro overkill (prevenir recursión infinita)
	var hp_after = health_component.current_health if health_component else hp
	if hp_after <= 0 and final_damage > hp_before and not _receiving_overkill_damage:
		var excess = final_damage - hp_before
		_apply_overkill_damage(excess)

func _apply_overkill_damage(excess_damage: int) -> void:
	"""Transferir daño excedente a enemigos cercanos según overkill_damage stat"""
	# Obtener el stat overkill_damage del PlayerStats
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if not player_stats or not player_stats.has_method("get_stat"):
		return
	
	var overkill_percent = player_stats.get_stat("overkill_damage")
	if overkill_percent <= 0:
		return
	
	# Calcular daño a transferir (% del exceso)
	var transfer_damage = int(excess_damage * overkill_percent)
	if transfer_damage <= 0:
		return
	
	# Buscar enemigos cercanos (excluyéndonos) usando SpatialGrid
	const OVERKILL_RANGE: float = 150.0
	var nearby_enemies: Array = []
	
	for enemy in SpatialGrid.get_nearby_excluding(global_position, OVERKILL_RANGE, self):
		if enemy.has_method("take_damage"):
			nearby_enemies.append(enemy)
	
	if nearby_enemies.is_empty():
		return
	
	# Aplicar daño a todos los enemigos cercanos
	# Marcar que el daño es de overkill para prevenir recursión
	for enemy in nearby_enemies:
		if "_receiving_overkill_damage" in enemy:
			enemy._receiving_overkill_damage = true
		enemy.take_damage(transfer_damage, "physical", null)
		if "_receiving_overkill_damage" in enemy:
			enemy._receiving_overkill_damage = false
		# Efecto visual de overkill
		FloatingText.spawn_text(enemy.global_position + Vector2(0, -30), "OVERKILL", Color(1.0, 0.5, 0.0))

func _flash_block() -> void:
	"""Flash visual cuando bloquea un ataque"""
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var original = sprite.modulate
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 0.7, 1.0), 0.05)
		tween.tween_property(sprite, "modulate", original, 0.15)

func _play_attack_animation() -> void:
	"""Efecto visual cuando el enemigo ataca"""
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if not sprite:
		return

	# Color del flash según elemento
	var attack_element = _determine_element_from_id(enemy_id)
	var flash_color: Color
	match attack_element:
		"fire":
			flash_color = Color(1.5, 0.5, 0.2)
		"ice":
			flash_color = Color(0.5, 0.8, 1.5)
		"dark", "void", "shadow":
			flash_color = Color(0.8, 0.3, 1.2)
		"poison":
			flash_color = Color(0.5, 1.2, 0.3)
		"lightning":
			flash_color = Color(1.5, 1.5, 0.4)
		"arcane":
			flash_color = Color(0.8, 0.5, 1.5)
		_:
			flash_color = Color(1.3, 0.3, 0.3)  # Rojo por defecto

	# Animación de ataque: escala y flash
	var original_scale = sprite.scale
	var attack_scale = original_scale * 1.15

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", attack_scale, 0.08)
	tween.tween_property(sprite, "modulate", flash_color, 0.08)
	tween.set_parallel(false)
	tween.tween_property(sprite, "scale", original_scale, 0.12)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func apply_knockback(knockback_force: Vector2) -> void:
	"""Aplicar knockback (empujón) al enemigo desde un impacto"""
	# El knockback es un impulso instantáneo que aleja al enemigo
	# Se aplica solo una vez y se disipa gradualmente
	# Debug de knockback (comentado para producción)
	# print("[EnemyBase] 💨 Knockback recibido: %s por %.1f" % [name, knockback_force.length()])

	# Aplicar el knockback directamente a la posición
	# (alternativa: usar una velocidad temporal)
	global_position += knockback_force * 0.1  # Escalar para que no sea demasiado agresivo

	# Reproducir efecto visual: hacer parpadear el sprite
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		# OPTIMIZACIÓN: Matar tween anterior para evitar conflicto y overhead
		if _knockback_tween and _knockback_tween.is_valid():
			_knockback_tween.kill()
			
		_knockback_tween = create_tween()
		_knockback_tween.set_trans(Tween.TRANS_QUAD)
		_knockback_tween.set_ease(Tween.EASE_OUT)
		var original_color = sprite.modulate
		_knockback_tween.tween_property(sprite, "modulate", Color.WHITE.lightened(0.2), 0.05)
		_knockback_tween.tween_property(sprite, "modulate", original_color, 0.05)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE EFECTOS DE ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

# Variables de estado
var _is_stunned: bool = false
var _is_slowed: bool = false
var _is_burning: bool = false
var _is_blinded: bool = false
var _is_pulled: bool = false
var _is_frozen: bool = false  # Separado de slow para visual diferente
var _is_bleeding: bool = false  # Efecto bleed (DoT) - phantom_blade
var _is_shadow_marked: bool = false  # Marca de sombra - shadow_orbs (daño extra)

# Test Hooks Signals
signal status_applied(name, duration, params)
signal status_removed(name)

# Sistema de iconos de estado
var status_icon_display: StatusIconDisplay = null

var _base_speed: float = 0.0  # Velocidad original antes de efectos
var _slow_amount: float = 0.0
var _burn_damage: float = 0.0
var _burn_timer: float = 0.0
var _burn_tick_timer: float = 0.0
var _stun_timer: float = 0.0
var _stun_flash_timer: float = 0.0  # Timer para parpadeo de stun
var _slow_timer: float = 0.0
var _blind_timer: float = 0.0
var _freeze_timer: float = 0.0
var _pull_target: Vector2 = Vector2.ZERO
var _pull_force: float = 0.0
var _pull_timer: float = 0.0

# Bleed effect (DoT separado del burn, color diferente)
var _bleed_damage: float = 0.0
var _bleed_timer: float = 0.0
var _bleed_tick_timer: float = 0.0
const BLEED_TICK_INTERVAL: float = 0.5  # Daño de sangrado cada 0.5s

# Shadow Mark effect (enemigos marcados reciben daño extra)
var _shadow_mark_timer: float = 0.0
var _shadow_mark_bonus: float = 0.0  # % de daño extra (ej: 0.25 = 25%)

# Para el efecto visual persistente
var _status_tween: Tween = null
var _knockback_tween: Tween = null # Tween dedicado para efectos visuales de knockback
var _current_status_color: Color = Color.WHITE

const BURN_TICK_INTERVAL: float = 0.5  # Daño de quemadura cada 0.5s

func apply_slow(amount: float, duration: float) -> void:
	"""Aplicar efecto de ralentización
	amount: porcentaje de reducción de velocidad (0.0 - 1.0)
	duration: duración del efecto en segundos
	"""
	if _is_stunned:
		return  # No aplicar slow si está stunneado

	# Guardar velocidad base si no está guardada
	if _base_speed == 0.0:
		_base_speed = speed

	# Aplicar el slow más fuerte si ya hay uno activo
	if _is_slowed:
		_slow_amount = max(_slow_amount, amount)
		_slow_timer = max(_slow_timer, duration)
	else:
		_slow_amount = clamp(amount, 0.0, 0.95)  # Máximo 95% slow
		_slow_timer = duration
		_is_slowed = true

	status_applied.emit("slow", _slow_timer, {"amount": _slow_amount})

	# Aplicar reducción de velocidad
	speed = _base_speed * (1.0 - _slow_amount)

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("slow", _slow_timer)

	_update_status_visual()

func apply_freeze(amount: float, duration: float) -> void:
	"""Aplicar efecto de congelación (slow extremo)
	amount: porcentaje de reducción (típicamente 0.7-0.9)
	duration: duración del efecto
	"""
	# Guardar velocidad base si no está guardada
	if _base_speed == 0.0:
		_base_speed = speed

	_is_frozen = true
	_freeze_timer = max(_freeze_timer, duration)
	_slow_amount = max(_slow_amount, amount)
	_is_slowed = true
	_slow_timer = max(_slow_timer, duration)

	status_applied.emit("freeze", _freeze_timer, {"amount": amount})

	# Aplicar reducción de velocidad
	speed = _base_speed * (1.0 - _slow_amount)

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("freeze", _freeze_timer)

	_update_status_visual()
	# print("[EnemyBase] Congelado %.0f%% por %.1fs" % [amount * 100, duration])

func apply_burn(damage_per_tick: float, duration: float) -> void:
	"""Aplicar efecto de quemadura (DoT)
	damage_per_tick: daño por cada tick
	duration: duración total del efecto
	"""
	# Si ya está quemando, refrescar/apilar
	if _is_burning:
		# Aplicar el daño más alto y refrescar duración
		_burn_damage = max(_burn_damage, damage_per_tick)
		_burn_timer = max(_burn_timer, duration)
	else:
		_burn_damage = damage_per_tick
		_burn_timer = duration
		_burn_tick_timer = 0.0
		_is_burning = true

	status_applied.emit("burn", _burn_timer, {"damage": _burn_damage})

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("burn", _burn_timer)

	_update_status_visual()

func apply_stun(duration: float) -> void:
	"""Aplicar efecto de aturdimiento (paraliza completamente)
	duration: duración del stun
	"""
	# Guardar velocidad base
	if _base_speed == 0.0:
		_base_speed = speed

	# Aplicar o refrescar stun
	_stun_timer = max(_stun_timer, duration)

	if not _is_stunned:
		_is_stunned = true
		speed = 0.0  # Paralizar
		can_attack = false  # No puede atacar

	status_applied.emit("stun", _stun_timer, {})

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("stun", _stun_timer)

	_update_status_visual()
	# print("[EnemyBase] ⭐ %s aturdido por %.1fs" % [name, duration])

func apply_pull(target_position: Vector2, force: float, duration: float) -> void:
	"""Aplicar efecto de atracción hacia un punto
	target_position: posición hacia donde atraer
	force: fuerza de atracción (velocidad)
	duration: duración del efecto
	"""
	_pull_target = target_position
	_pull_force = force
	_pull_timer = duration
	_is_pulled = true

	status_applied.emit("pull", _pull_timer, {"force": force})

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("pull", _pull_timer)

	_update_status_visual()
	# print("[EnemyBase] 🌀 %s atraído hacia %s por %.1fs" % [name, target_position, duration])

func apply_blind(duration: float) -> void:
	"""Aplicar efecto de ceguera (reduce precisión de ataques)
	duration: duración del efecto
	"""
	_blind_timer = max(_blind_timer, duration)
	_is_blinded = true

	status_applied.emit("blind", _blind_timer, {})

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("blind", _blind_timer)

	_update_status_visual()
	# print("[EnemyBase] 👁️ %s cegado por %.1fs" % [name, duration])

func apply_bleed(damage_per_tick: float, duration: float) -> void:
	"""Aplicar efecto de sangrado (DoT diferente al burn)
	damage_per_tick: daño por cada tick
	duration: duración total del efecto
	"""
	# Si ya está sangrando, refrescar/apilar
	if _is_bleeding:
		_bleed_damage = max(_bleed_damage, damage_per_tick)
		_bleed_timer = max(_bleed_timer, duration)
	else:
		_bleed_damage = damage_per_tick
		_bleed_timer = duration
		_bleed_tick_timer = 0.0
		_is_bleeding = true

	status_applied.emit("bleed", _bleed_timer, {"damage": _bleed_damage})

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("bleed", _bleed_timer)

	_update_status_visual()
	# print("[EnemyBase] 🩸 %s sangrando %.1f daño/tick por %.1fs" % [name, damage_per_tick, duration])

func apply_shadow_mark(bonus_damage: float, duration: float) -> void:
	"""Aplicar marca de sombra (enemigos marcados reciben daño extra)
	bonus_damage: porcentaje de daño extra (ej: 0.25 = 25%)
	duration: duración del efecto
	"""
	# Refrescar si ya está marcado
	if _is_shadow_marked:
		_shadow_mark_bonus = max(_shadow_mark_bonus, bonus_damage)
		_shadow_mark_timer = max(_shadow_mark_timer, duration)
	else:
		_shadow_mark_bonus = bonus_damage
		_shadow_mark_timer = duration
		_is_shadow_marked = true

	status_applied.emit("shadow_mark", _shadow_mark_timer, {"bonus": _shadow_mark_bonus})

	# Actualizar icono de estado
	if status_icon_display:
		status_icon_display.add_effect("shadow_mark", _shadow_mark_timer)

	_update_status_visual()
	# print("[EnemyBase] 👤 %s marcado! +%.0f%% daño por %.1fs" % [name, bonus_damage * 100, duration])

func _update_status_visual() -> void:
	"""Actualizar el color del sprite según los efectos activos (prioridad)"""
	var target_color: Color = Color.WHITE

	# Prioridad de colores (el más importante se muestra)
	if _is_stunned:
		target_color = Color(1.0, 1.0, 1.0, 1.0)  # Blanco brillante (stun)
	elif _is_frozen:
		target_color = Color(0.4, 0.9, 1.0, 1.0)  # Cyan hielo
	elif _is_burning:
		target_color = Color(1.0, 0.5, 0.2, 1.0)  # Naranja fuego
	elif _is_bleeding:
		target_color = Color(0.8, 0.2, 0.3, 1.0)  # Rojo sangre
	elif _is_shadow_marked:
		target_color = Color(0.5, 0.3, 0.7, 1.0)  # Púrpura oscuro (marca)
	elif _is_slowed:
		target_color = Color(0.6, 0.8, 1.0, 1.0)  # Azul claro
	elif _is_pulled:
		target_color = Color(0.8, 0.5, 1.0, 1.0)  # Púrpura
	elif _is_blinded:
		target_color = Color(0.4, 0.4, 0.4, 1.0)  # Gris oscuro

	# Solo actualizar si el color cambió
	if target_color != _current_status_color:
		_current_status_color = target_color
		_apply_persistent_color(target_color)

func _apply_persistent_color(color: Color) -> void:
	"""Aplicar color persistente al sprite"""
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		# Cancelar tween anterior si existe
		if _status_tween and _status_tween.is_valid():
			_status_tween.kill()

		# Aplicar color con transición suave
		_status_tween = create_tween()
		_status_tween.tween_property(sprite, "modulate", color, 0.15)

func _flash_damage() -> void:
	"""Flash rápido cuando recibe daño de burn"""
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var original = _current_status_color
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.0), 0.05)
		flash_tween.tween_property(sprite, "modulate", original, 0.1)

func _flash_stun(delta: float) -> void:
	"""Parpadeo continuo mientras está stuneado - alterna entre blanco y amarillo"""
	_stun_flash_timer += delta
	if _stun_flash_timer >= 0.15:  # Parpadeo cada 0.15s
		_stun_flash_timer = 0.0
		var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
		if sprite:
			# Alternar entre blanco brillante y amarillo dorado
			var is_white = sprite.modulate.g > 0.9 and sprite.modulate.b > 0.9
			if is_white:
				sprite.modulate = Color(1.0, 0.9, 0.2, 1.0)  # Amarillo dorado
			else:
				sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Blanco brillante

func _flash_bleed() -> void:
	"""Flash rápido cuando recibe daño de bleed (color rojo sangre)"""
	var sprite = animated_sprite if animated_sprite else _find_sprite_node(self)
	if sprite:
		var original = _current_status_color
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color(0.9, 0.1, 0.2), 0.05)
		flash_tween.tween_property(sprite, "modulate", original, 0.1)

var _burn_aura_accumulator: float = 0.0

func _process_burn_aura(delta: float) -> void:
	"""FIX FASE 2: Aura de fuego pasiva - daño a player por proximidad"""
	if not player_ref or not is_instance_valid(player_ref):
		return
	var aura_radius = get_meta("burn_aura_radius") if has_meta("burn_aura_radius") else 60.0
	var aura_dps = get_meta("burn_aura_dps") if has_meta("burn_aura_dps") else 5
	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= aura_radius:
		_burn_aura_accumulator += aura_dps * delta
		if _burn_aura_accumulator >= 1.0 and player_ref.has_method("take_damage"):
			var int_dmg = int(_burn_aura_accumulator)
			player_ref.take_damage(int_dmg, "fire", self)
			_burn_aura_accumulator -= int_dmg
	else:
		_burn_aura_accumulator = 0.0

func _process_status_effects(delta: float) -> void:
	"""Procesar todos los efectos de estado activos"""
	var status_changed: bool = false

	# Procesar STUN - con efecto de parpadeo
	if _is_stunned:
		_stun_timer -= delta
		# Parpadeo visual mientras está stuneado
		_flash_stun(delta)
		if _stun_timer <= 0:
			_is_stunned = false
			can_attack = true
			status_changed = true
			status_removed.emit("stun")
			if status_icon_display:
				status_icon_display.remove_effect("stun")
			if _base_speed > 0:
				speed = _base_speed * (1.0 - _slow_amount if _is_slowed else 1.0)

	# Procesar FREEZE (separado de slow para el visual)
	if _is_frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0:
			_is_frozen = false
			status_changed = true
			status_removed.emit("freeze")
			if status_icon_display:
				status_icon_display.remove_effect("freeze")

	# Procesar SLOW
	if _is_slowed and not _is_stunned:
		_slow_timer -= delta
		if _slow_timer <= 0:
			_is_slowed = false
			_slow_amount = 0.0
			status_changed = true
			status_removed.emit("slow")
			if status_icon_display:
				status_icon_display.remove_effect("slow")
			if _base_speed > 0:
				speed = _base_speed

	# Procesar BURN (DoT)
	if _is_burning:
		_burn_timer -= delta
		_burn_tick_timer += delta

		# Aplicar daño cada tick
		if _burn_tick_timer >= BURN_TICK_INTERVAL:
			_burn_tick_timer = 0.0
			take_damage(int(_burn_damage))
			_flash_damage()  # Flash visual de daño

		if _burn_timer <= 0:
			_is_burning = false
			_burn_damage = 0.0
			status_changed = true
			status_removed.emit("burn")
			if status_icon_display:
				status_icon_display.remove_effect("burn")

	# Procesar BLIND
	if _is_blinded:
		_blind_timer -= delta
		if _blind_timer <= 0:
			_is_blinded = false
			status_changed = true
			status_removed.emit("blind")
			if status_icon_display:
				status_icon_display.remove_effect("blind")

	# Procesar BLEED (DoT separado del burn)
	if _is_bleeding:
		_bleed_timer -= delta
		_bleed_tick_timer += delta

		# Aplicar daño cada tick
		if _bleed_tick_timer >= BLEED_TICK_INTERVAL:
			_bleed_tick_timer = 0.0
			# Bypass shadow_mark para evitar loop infinito (daño directo)
			if health_component:
				health_component.take_damage(int(_bleed_damage), "bleed")
			else:
				hp -= int(_bleed_damage)
				if hp <= 0:
					die()
			_flash_bleed()  # Flash visual de sangrado

		if _bleed_timer <= 0:
			_is_bleeding = false
			_bleed_damage = 0.0
			status_changed = true
			status_removed.emit("bleed")
			if status_icon_display:
				status_icon_display.remove_effect("bleed")

	# Procesar SHADOW MARK
	if _is_shadow_marked:
		_shadow_mark_timer -= delta
		if _shadow_mark_timer <= 0:
			_is_shadow_marked = false
			_shadow_mark_bonus = 0.0
			status_changed = true
			status_removed.emit("shadow_mark")
			if status_icon_display:
				status_icon_display.remove_effect("shadow_mark")

	# Procesar PULL
	if _is_pulled:
		_pull_timer -= delta
		# Mover hacia el objetivo
		var pull_direction = (_pull_target - global_position).normalized()
		global_position += pull_direction * _pull_force * delta

		if _pull_timer <= 0:
			_is_pulled = false
			status_changed = true
			status_removed.emit("pull")
			if status_icon_display:
				status_icon_display.remove_effect("pull")

	# Actualizar visual si algún estado cambió
	if status_changed:
		_update_status_visual()

func is_stunned() -> bool:
	"""Verificar si el enemigo está aturdido"""
	return _is_stunned

func is_blinded() -> bool:
	"""Verificar si el enemigo está cegado"""
	return _is_blinded

func get_attack_accuracy() -> float:
	"""Obtener precisión de ataque (afectada por ceguera)"""
	if _is_blinded:
		return 0.3  # 30% precisión cuando está cegado
	return 1.0  # 100% precisión normal

# ═══════════════════════════════════════════════════════════════════════════════
# MUERTE Y LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func die() -> void:
	if is_boss:
		# Solo limpiar efectos de boss si ES un boss
		if attack_system and attack_system.has_method("cleanup_boss"):
			attack_system.cleanup_boss()
	
	enemy_died.emit(self, enemy_id, exp_value, enemy_tier, is_elite, is_boss)
	
	if has_meta("pooled"):
		var pool = get_tree().get_first_node_in_group("enemy_pool")
		if pool and pool.has_method("return_enemy"):
			pool.return_enemy(self)
			return

	queue_free()

func _on_health_died() -> void:
	"""Manejar muerte desde HealthComponent"""
	
	# -----------------------------------------------------------
	# LÓGICA DE NUEVOS OBJETOS (Phase 4)
	# 10. Portadores de Plaga (Plague Bearer): Spread debuffs on death
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("get_player_stats"):
		# Try to access global player stats
		var ps = get_tree().get_first_node_in_group("player_stats")
		if ps and ps.has_method("get_stat"):
			var plague_active = ps.get_stat("plague_bearer_active")
			if plague_active > 0:
				# Check active debuffs
				var debuffs_to_spread = []
				var spread_timers = []
				
				if _is_burning: debuffs_to_spread.append("burn"); spread_timers.append(_burn_timer)
				if _is_slowed: debuffs_to_spread.append("slow"); spread_timers.append(_slow_timer)
				if _is_blinded: debuffs_to_spread.append("blind"); spread_timers.append(_blind_timer)
				if _is_bleeding: debuffs_to_spread.append("bleed"); spread_timers.append(_bleed_timer)
				if _is_frozen: debuffs_to_spread.append("freeze"); spread_timers.append(_freeze_timer)
				
				if not debuffs_to_spread.is_empty():
					# Find nearby enemies
					var enemies = get_tree().get_nodes_in_group("enemies")
					var spread_radius = 250.0
					for enemy in enemies:
						if enemy != self and global_position.distance_to(enemy.global_position) < spread_radius:
							# Apply debuffs
							for i in range(debuffs_to_spread.size()):
								var debuff = debuffs_to_spread[i]
								var duration = spread_timers[i]
								
								match debuff:
									"burn": if enemy.has_method("apply_burn"): enemy.apply_burn(_burn_damage, duration)
									"slow": if enemy.has_method("apply_slow"): enemy.apply_slow(_slow_amount, duration)
									"blind": if enemy.has_method("apply_blind"): enemy.apply_blind(duration)
									"bleed": if enemy.has_method("apply_bleed"): enemy.apply_bleed(_bleed_damage, duration)
									"freeze": if enemy.has_method("apply_freeze"): enemy.apply_freeze(duration)
					
					# Visual feedback
					# FloatingText.spawn_custom(global_position, "SPREAD!", Color.GREEN)
	# -----------------------------------------------------------
	
	# FIX FASE 2: Split on death (Slime Arcano - spawna 2 slimes menores al morir)
	if has_meta("split_on_death") and get_meta("split_on_death"):
		_perform_split_on_death()
	
	die()

func _perform_split_on_death() -> void:
	"""Spawnar copias menores al morir (Slime Arcano)"""
	var spawn_count = 2
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# Buscar spawner para crear slimes menores
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("spawn_minions_around"):
		spawner.spawn_minions_around(global_position, spawn_count, max(enemy_tier - 1, 1))
	else:
		# Fallback: crear nodos simples que se comporten como enemigos debiles
		for i in range(spawn_count):
			var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
			# Intentar duplicar pero con stats reducidos
			if has_method("get_info"):
				var info = get_info()
				# Solo crear visual simple como indicador
				var split_visual = Node2D.new()
				split_visual.global_position = global_position + offset
				parent_node.add_child(split_visual)
				# Auto-destruir visual tras un momento
				get_tree().create_timer(0.5).timeout.connect(func():
					if is_instance_valid(split_visual):
						split_visual.queue_free()
				)

func get_info() -> Dictionary:
	return {"id": enemy_id, "hp": hp, "max_hp": max_hp}
