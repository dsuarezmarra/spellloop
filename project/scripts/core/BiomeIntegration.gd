extends Node
## Script de Integración Automática de Biomas
## Se ejecuta al iniciar la escena y configura todo

@onready var game_manager = get_tree().root.find_child("GameManager", true, false)
@onready var player = get_tree().root.find_child("SpellloopPlayer", true, false)

var _biome_loader: BiomeLoaderSimple = null

func _ready():
	print("[BiomeIntegration] Inicializando sistema de biomas...")
	
	# Crear nodo cargador de biomas
	_biome_loader = BiomeLoaderSimple.new()
	_biome_loader.enable_debug = true
	_biome_loader.player_node_name = "SpellloopPlayer"
	add_child(_biome_loader)
	
	print("[BiomeIntegration] ✅ Sistema de biomas listo")
	print("[BiomeIntegration] Los biomas se actualizarán automáticamente")
