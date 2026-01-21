extends Node2D
class_name AmbientAtmosphere

# Sistema de partículas ambientales que sigue al jugador
# Cambia según el bioma actual

var particles: CPUParticles2D
var player_ref: Node2D
var current_biome: String = ""

const BIOME_SETTINGS = {
	"Grassland": {
		"color": Color(0.9, 0.9, 0.6, 0.6), # Polen amarillento
		"amount": 30,
		"gravity": Vector2(10, 20),
		"scale": 3.0,
		"speed_scale": 0.5
	},
	"Forest": {
		"color": Color(0.8, 0.9, 0.8, 0.5), # Esporas verdosas
		"amount": 40,
		"gravity": Vector2(5, 10),
		"scale": 2.5,
		"speed_scale": 0.4
	},
	"Desert": {
		"color": Color(0.8, 0.7, 0.5, 0.7), # Arena/Polvo
		"amount": 60,
		"gravity": Vector2(100, 20), # Viento lateral
		"scale": 2.0,
		"speed_scale": 1.2
	},
	"Snow": {
		"color": Color(1.0, 1.0, 1.0, 0.9), # Nieve
		"amount": 80,
		"gravity": Vector2(-20, 150), # Caída rápida
		"scale": 4.0,
		"speed_scale": 1.0
	},
	"Lava": {
		"color": Color(0.3, 0.3, 0.3, 0.8), # Ceniza oscura
		"amount": 50,
		"gravity": Vector2(0, -30), # Sube ligeramente (calor)
		"scale": 3.5,
		"speed_scale": 0.8
	},
	"ArcaneWastes": {
		"color": Color(0.6, 0.2, 0.8, 0.6), # Partículas mágicas
		"amount": 30,
		"gravity": Vector2(0, -10), # Flotando
		"scale": 3.0,
		"speed_scale": 0.3
	},
	"Death": {
		"color": Color(0.1, 0.1, 0.1, 0.9), # Oscuridad
		"amount": 60,
		"gravity": Vector2(0, 50),
		"scale": 4.0,
		"speed_scale": 0.6
	}
}

func _ready():
	z_index = 50 # Encima del suelo, debajo de UI
	
	particles = CPUParticles2D.new()
	add_child(particles)
	
	# Configuración base de partículas
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(600, 400) # Cubrir pantalla
	particles.lifetime = 4.0
	particles.preprocess = 2.0 # Iniciar ya llenas
	particles.direction = Vector2(0, 1)
	particles.spread = 180
	particles.gravity = Vector2(0, 20)
	particles.initial_velocity_min = 10
	particles.initial_velocity_max = 30
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = Color(1, 1, 1, 0.5)

func initialize(player: Node2D):
	player_ref = player

func set_biome(biome_name: String):
	if biome_name == current_biome:
		return
		
	current_biome = biome_name
	var settings = BIOME_SETTINGS.get(biome_name, BIOME_SETTINGS["Grassland"]) # Default
	
	# Transición suave de parámetros si fuera necesario, pero cambio directo por ahora
	particles.color = settings.color
	particles.amount = settings.amount
	particles.gravity = settings.gravity
	particles.scale_amount_max = settings.scale
	particles.speed_scale = settings.speed_scale
	
	# Reiniciar para aplicar amount
	particles.restart()

func _process(_delta):
	if is_instance_valid(player_ref):
		global_position = player_ref.global_position
