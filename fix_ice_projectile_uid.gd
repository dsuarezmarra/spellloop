# Script para forzar regeneración del UID de IceProjectile.tscn
# Ejecutar en Godot: Ctrl+Shift+O > New Script > adjuntar a scene root > ejecutar
# Luego borrar el script

extends Node

func _ready():
	# Cargar el archivo TSCN sin parsear (solo texto)
	var tscn_path = "res://scripts/entities/weapons/projectiles/IceProjectile.tscn"
	var content = FileAccess.get_file_as_string(tscn_path)
	
	print("📄 Contenido actual de IceProjectile.tscn:")
	print(content)
	
	# Intentar crear instancia - esto puede forzar regeneración
	var scene = load(tscn_path)
	if scene:
		print("✅ IceProjectile.tscn cargado exitosamente")
		print("   UID en memoria: ", scene.resource_uid)
		
		# Recargar recurso para asegurar que se valida
		scene = load(tscn_path)
		if scene:
			print("✅ Recarga exitosa")
	else:
		print("❌ Fallo al cargar IceProjectile.tscn")
