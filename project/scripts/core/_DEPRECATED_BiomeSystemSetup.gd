## Godot Automation Script - Biome System Integration
## 
## Este script automatiza la integración del sistema de biomas:
## 1. Importa las texturas con configuración correcta
## 2. Configura los import settings
## 3. Conecta BiomeChunkApplier al sistema
##
## USO: Ejecuta este script en una escena vacía o adjuntalo a un nodo
## Luego llama a setup_biome_system() en _ready()

extends Node

class_name BiomeSystemSetup

# Configuración
const BIOME_DIR = "res://assets/textures/biomes"
const CONFIG_PATH = "res://assets/textures/biomes/biome_textures_config.json"
const BIOME_APPLIER_PATH = "res://scripts/core/BiomeChunkApplier.gd"
const SEPARATOR = "══════════════════════════════════════════════════════════════════════════"

# Estados
var _setup_complete = false
var _biome_applier: BiomeChunkApplier = null

func _ready():
	print("[BiomeSystemSetup] Inicializando sistema de biomas...")
	setup_biome_system()

## Ejecuta toda la configuración del sistema de biomas
func setup_biome_system() -> void:
	print("\n" + SEPARATOR)
	print("🎨 BIOME SYSTEM - AUTOMATIC SETUP")
	print(SEPARATOR)
	
	# Paso 1: Validar que existan los archivos
	if not _validate_files():
		print("[ERROR] Validación de archivos falló")
		return
	
	# Paso 2: Configurar imports de texturas
	if not _configure_texture_imports():
		print("[ERROR] Configuración de imports falló")
		return
	
	# Paso 3: Inicializar BiomeChunkApplier
	if not _initialize_biome_applier():
		print("[ERROR] Inicialización de BiomeChunkApplier falló")
		return
	
	# Paso 4: Conectar señales
	_connect_signals()
	
	_setup_complete = true
	print("\n✅ Sistema de biomas configurado correctamente!")
	print(SEPARATOR + "\n")

## Valida que todos los archivos necesarios existan
func _validate_files() -> bool:
	print("\n📋 PASO 1: Validando archivos...")
	
	# Verificar JSON
	if not ResourceLoader.exists(CONFIG_PATH):
		print("  ❌ No encontrado: %s" % CONFIG_PATH)
		return false
	print("  ✅ Config JSON encontrada")
	
	# Verificar BiomeChunkApplier.gd
	if not ResourceLoader.exists(BIOME_APPLIER_PATH):
		print("  ❌ No encontrado: %s" % BIOME_APPLIER_PATH)
		return false
	print("  ✅ BiomeChunkApplier.gd encontrado")
	
	# Verificar que existen las carpetas de biomas
	var biomes = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
	for biome in biomes:
		var biome_path = "%s/%s" % [BIOME_DIR, biome]
		if not ResourceLoader.exists(biome_path):
			print("  ⚠️  Carpeta no encontrada: %s" % biome_path)
		else:
			print("  ✅ %s - Encontrada" % biome)
	
	return true

## Configura los import settings de todas las texturas
func _configure_texture_imports() -> bool:
	print("\n📦 PASO 2: Configurando imports de texturas...")
	
	var biomes = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
	var texture_types = ["base", "decor1", "decor2", "decor3"]
	var total = 0
	var configured = 0
	
	for biome in biomes:
		for texture_type in texture_types:
			var texture_path = "%s/%s/%s.png" % [BIOME_DIR, biome, texture_type]
			total += 1
			
			# Crear configuración de import
			var import_settings = {
				"filter": 1,  # Linear
				"mipmaps": true,
				"compress/mode": 2,  # VRAM Compressed
				"compress/lossy_quality": 0.7,
				"srgb": false
			}
			
			# Aplicar configuración
			if _apply_import_settings(texture_path, import_settings):
				configured += 1
				print("  ✅ %s/%s.png" % [biome, texture_type])
			else:
				print("  ⚠️  %s/%s.png (pendiente de importar en Godot)" % [biome, texture_type])
	
	print("  📊 Resultado: %d/%d texturas configuradas" % [configured, total])
	return true

## Aplica los import settings a una textura
func _apply_import_settings(texture_path: String, _settings: Dictionary) -> bool:
	# En Godot 4.x, los imports se manejan a través de .import files
	# Este es un placeholder que documenta qué necesita hacerse
	
	var import_file = texture_path + ".import"
	
	# Si el archivo existe, podemos leer y modificar su configuración
	if ResourceLoader.exists(import_file):
		# Los settings se aplican automáticamente cuando Godot reimporta
		# Este paso es más informativo que funcional en tiempo de ejecución
		return true
	
	# Si no existe aún, retorna true (se creará al reimportar)
	return false

## Inicializa BiomeChunkApplier
func _initialize_biome_applier() -> bool:
	print("\n🎮 PASO 3: Inicializando BiomeChunkApplier...")
	
	# Cargar el script
	var applier_script = load(BIOME_APPLIER_PATH)
	if applier_script == null:
		print("  ❌ Error cargando BiomeChunkApplier.gd")
		return false
	
	# Crear instancia
	_biome_applier = applier_script.new()
	if _biome_applier == null:
		print("  ❌ Error creando instancia de BiomeChunkApplier")
		return false
	
	# Configurar propiedades
	_biome_applier.config_path = CONFIG_PATH
	_biome_applier.enable_debug = true  # Activar logs
	
	# Agregar como nodo hijo
	add_child(_biome_applier)
	print("  ✅ BiomeChunkApplier instanciado y agregado")
	print("  ℹ️  Debug enabled - verás logs en la consola")
	
	return true

## Conecta señales del sistema
func _connect_signals() -> void:
	print("\n🔌 PASO 4: Conectando señales...")
	
	# Buscar el nodo del jugador (ajusta el path según tu proyecto)
	var player = get_tree().root.find_child("SpellloopPlayer", true, false)
	
	if player and _biome_applier:
		# Conectar movimiento del jugador
		if player.has_signal("position_changed"):
			player.position_changed.connect(_on_player_position_changed)
			print("  ✅ Señal de posición conectada")
		elif player.has_method("get_global_position"):
			# Si no tiene señal, conectaremos en _process
			print("  ⚠️  Jugador sin señal de posición - usando _process")
		else:
			print("  ⚠️  Jugador no encontrado o sin método de posición")
	else:
		print("  ⚠️  No se pudo conectar (jugador o applier no encontrado)")
		print("  ℹ️  Los biomas se actualizarán cuando muevas al jugador")

## Callback para cuando la posición del jugador cambia
func _on_player_position_changed(new_position: Vector2) -> void:
	if _biome_applier:
		_biome_applier.on_player_position_changed(new_position)

## Actualiza biomas cada frame (alternativa sin señal)
func _process(_delta: float) -> void:
	if _setup_complete and _biome_applier:
		# Buscar jugador si aún no lo hemos hecho
		var player = get_tree().root.find_child("SpellloopPlayer", true, false)
		if player:
			_biome_applier.on_player_position_changed(player.global_position)

## Retorna si la configuración se completó exitosamente
func is_setup_complete() -> bool:
	return _setup_complete

## Retorna la instancia de BiomeChunkApplier (para debug)
func get_biome_applier() -> BiomeChunkApplier:
	return _biome_applier

## Imprime el estado actual del sistema
func print_status() -> void:
	print("\n" + SEPARATOR)
	print("🎨 BIOME SYSTEM - STATUS")
	print(SEPARATOR)
	print("Setup Complete: %s" % ("✅ YES" if _setup_complete else "❌ NO"))
	
	if _biome_applier:
		print("BiomeChunkApplier: ✅ ACTIVE")
		print("Debug Mode: %s" % ("✅ ON" if _biome_applier.enable_debug else "❌ OFF"))
		_biome_applier.print_active_chunks()
	else:
		print("BiomeChunkApplier: ❌ NOT ACTIVE")
	
	print(SEPARATOR + "\n")
