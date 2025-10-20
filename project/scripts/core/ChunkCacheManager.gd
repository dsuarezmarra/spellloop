# ChunkCacheManager.gd
# Gestor de caché persistente para chunks
# Guarda estado de chunks en user://chunk_cache/ para recuperación rápida

extends Node
class_name ChunkCacheManager

const CACHE_DIR = "user://chunk_cache/"

func _ready() -> void:
	"""Inicializar gestor de caché"""
	_ensure_cache_dir_exists()
	print("[ChunkCacheManager] ✅ Inicializado (dir: %s)" % CACHE_DIR)

func _ensure_cache_dir_exists() -> void:
	"""Asegurar que existe el directorio de caché"""
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_absolute(CACHE_DIR)
		print("[ChunkCacheManager] 📁 Directorio de caché creado")

func save_chunk(chunk_pos: Vector2i, chunk_data: Dictionary) -> bool:
	"""Guardar estado de un chunk en caché"""
	var filename = _get_cache_filename(chunk_pos)
	
	# Usar var2str para serialización simple
	var data_str = var_to_str(chunk_data)
	
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file == null:
		print("[ChunkCacheManager] ❌ Error guardando chunk %s" % chunk_pos)
		return false
	
	file.store_string(data_str)
	print("[ChunkCacheManager] 💾 Chunk %s guardado en caché" % chunk_pos)
	return true

func load_chunk(chunk_pos: Vector2i) -> Dictionary:
	"""Cargar estado de un chunk desde caché"""
	var filename = _get_cache_filename(chunk_pos)
	
	if not ResourceLoader.exists(filename):
		print("[ChunkCacheManager] ⚠️ Caché no encontrada para %s" % chunk_pos)
		return {}
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		print("[ChunkCacheManager] ❌ Error cargando chunk %s" % chunk_pos)
		return {}
	
	var data_str = file.get_as_text()
	var chunk_data = str_to_var(data_str)
	
	print("[ChunkCacheManager] 📂 Chunk %s cargado del caché" % chunk_pos)
	return chunk_data

func has_cached_chunk(chunk_pos: Vector2i) -> bool:
	"""Verificar si existe caché para un chunk"""
	var filename = _get_cache_filename(chunk_pos)
	return ResourceLoader.exists(filename)

func clear_chunk_cache(chunk_pos: Vector2i) -> bool:
	"""Eliminar caché de un chunk específico"""
	var filename = _get_cache_filename(chunk_pos)
	
	if not ResourceLoader.exists(filename):
		return false
	
	DirAccess.remove_absolute(filename)
	print("[ChunkCacheManager] 🗑️ Caché del chunk %s eliminada" % chunk_pos)
	return true

func clear_all_cache() -> void:
	"""Limpiar todo el caché de chunks"""
	var dir = DirAccess.open(CACHE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".dat"):
				DirAccess.remove_absolute(CACHE_DIR + file_name)
			file_name = dir.get_next()
	
	print("[ChunkCacheManager] 🗑️ Todo el caché de chunks eliminado")

func get_cache_size() -> int:
	"""Obtener tamaño total del caché en bytes"""
	var total_size = 0
	var dir = DirAccess.open(CACHE_DIR)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".dat"):
				var file_path = CACHE_DIR + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					total_size += file.get_length()
			file_name = dir.get_next()
	
	return total_size

func _get_cache_filename(chunk_pos: Vector2i) -> String:
	"""Obtener ruta de archivo de caché para un chunk"""
	return "%s%d_%d.dat" % [CACHE_DIR, chunk_pos.x, chunk_pos.y]

func get_info() -> Dictionary:
	"""Obtener información de caché"""
	return {
		"cache_dir": CACHE_DIR,
		"cache_size_mb": get_cache_size() / (1024.0 * 1024.0),
		"exists": DirAccess.dir_exists_absolute(CACHE_DIR)
	}
