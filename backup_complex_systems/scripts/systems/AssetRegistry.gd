# AssetRegistry.gd
# Central registry for all generated assets
# Manages sprites, textures, audio, tilesets, and icons

extends Node

signal asset_registered(asset_type: String, asset_name: String)
signal asset_unregistered(asset_type: String, asset_name: String)

# Asset types
enum AssetType {
	SPRITE,
	TEXTURE,
	AUDIO,
	TILESET,
	ICON,
	FONT,
	SHADER
}

# Asset categories
const ASSET_CATEGORIES = {
	AssetType.SPRITE: "sprites",
	AssetType.TEXTURE: "textures", 
	AssetType.AUDIO: "audio",
	AssetType.TILESET: "tilesets",
	AssetType.ICON: "icons",
	AssetType.FONT: "fonts",
	AssetType.SHADER: "shaders"
}

# Asset registry storage
var asset_registry: Dictionary = {}
var asset_metadata: Dictionary = {}
var asset_dependencies: Dictionary = {}
var asset_tags: Dictionary = {}

# Cache settings
var max_cache_size: int = 1000
var cache_cleanup_threshold: float = 0.8

func _ready() -> void:
	"""Initialize asset registry"""
	print("[AssetRegistry] Asset Registry initialized")
	_initialize_registry()
	
	# Connect to generator signals
	_connect_generator_signals()

func _initialize_registry() -> void:
	"""Initialize registry structure"""
	for asset_type in AssetType.values():
		var category = ASSET_CATEGORIES[asset_type]
		asset_registry[category] = {}
		asset_metadata[category] = {}
		asset_dependencies[category] = {}
		asset_tags[category] = {}

func _connect_generator_signals() -> void:
	"""Connect to all asset generator signals"""
	# Connect SpriteGenerator
	if SpriteGenerator:
		SpriteGenerator.sprite_generated.connect(_on_sprite_generated)
	
	# Connect TextureGenerator
	if TextureGenerator:
		TextureGenerator.texture_generated.connect(_on_texture_generated)
	
	# Connect AudioGenerator
	if AudioGenerator:
		AudioGenerator.audio_generated.connect(_on_audio_generated)
	
	# Connect TilesetGenerator
	if TilesetGenerator:
		TilesetGenerator.tileset_generated.connect(_on_tileset_generated)
	
	# Connect IconGenerator
	if IconGenerator:
		IconGenerator.icon_generated.connect(_on_icon_generated)

# Asset registration methods
func register_asset(asset_type: AssetType, asset_name: String, asset_data, metadata: Dictionary = {}) -> bool:
	"""Register an asset in the registry"""
	var category = ASSET_CATEGORIES[asset_type]
	
	if not asset_registry.has(category):
		print("[AssetRegistry] Warning: Invalid asset category: %s" % category)
		return false
	
	# Store asset
	asset_registry[category][asset_name] = asset_data
	
	# Store metadata
	var asset_meta = {
		"created_at": Time.get_unix_time_from_system(),
		"asset_type": asset_type,
		"category": category,
		"size": _calculate_asset_size(asset_data),
		"format": _detect_asset_format(asset_data),
		"generator": metadata.get("generator", "unknown"),
		"version": metadata.get("version", "1.0")
	}
	asset_meta.merge(metadata)
	asset_metadata[category][asset_name] = asset_meta
	
	# Initialize dependencies and tags
	asset_dependencies[category][asset_name] = metadata.get("dependencies", [])
	asset_tags[category][asset_name] = metadata.get("tags", [])
	
	# Check cache size
	_check_cache_size()
	
	asset_registered.emit(category, asset_name)
	print("[AssetRegistry] Registered %s asset: %s" % [category, asset_name])
	
	return true

func unregister_asset(asset_type: AssetType, asset_name: String) -> bool:
	"""Unregister an asset from the registry"""
	var category = ASSET_CATEGORIES[asset_type]
	
	if not asset_registry[category].has(asset_name):
		print("[AssetRegistry] Warning: Asset not found: %s/%s" % [category, asset_name])
		return false
	
	# Remove from all registries
	asset_registry[category].erase(asset_name)
	asset_metadata[category].erase(asset_name)
	asset_dependencies[category].erase(asset_name)
	asset_tags[category].erase(asset_name)
	
	asset_unregistered.emit(category, asset_name)
	print("[AssetRegistry] Unregistered %s asset: %s" % [category, asset_name])
	
	return true

func get_asset(asset_type: AssetType, asset_name: String):
	"""Get an asset from the registry"""
	var category = ASSET_CATEGORIES[asset_type]
	return asset_registry[category].get(asset_name, null)

func has_asset(asset_type: AssetType, asset_name: String) -> bool:
	"""Check if an asset exists in the registry"""
	var category = ASSET_CATEGORIES[asset_type]
	return asset_registry[category].has(asset_name)

func get_asset_metadata(asset_type: AssetType, asset_name: String) -> Dictionary:
	"""Get metadata for an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	return asset_metadata[category].get(asset_name, {})

func get_asset_dependencies(asset_type: AssetType, asset_name: String) -> Array:
	"""Get dependencies for an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	return asset_dependencies[category].get(asset_name, [])

func get_asset_tags(asset_type: AssetType, asset_name: String) -> Array:
	"""Get tags for an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	return asset_tags[category].get(asset_name, [])

# Asset search and filtering
func find_assets_by_tag(tag: String) -> Array:
	"""Find all assets with a specific tag"""
	var results = []
	
	for category in asset_tags:
		for asset_name in asset_tags[category]:
			var tags = asset_tags[category][asset_name]
			if tag in tags:
				results.append({
					"category": category,
					"name": asset_name,
					"asset": asset_registry[category][asset_name],
					"metadata": asset_metadata[category][asset_name]
				})
	
	return results

func find_assets_by_type(asset_type: AssetType) -> Array:
	"""Find all assets of a specific type"""
	var category = ASSET_CATEGORIES[asset_type]
	var results = []
	
	for asset_name in asset_registry[category]:
		results.append({
			"name": asset_name,
			"asset": asset_registry[category][asset_name],
			"metadata": asset_metadata[category][asset_name]
		})
	
	return results

func find_assets_by_generator(generator_name: String) -> Array:
	"""Find all assets created by a specific generator"""
	var results = []
	
	for category in asset_metadata:
		for asset_name in asset_metadata[category]:
			var metadata = asset_metadata[category][asset_name]
			if metadata.get("generator", "") == generator_name:
				results.append({
					"category": category,
					"name": asset_name,
					"asset": asset_registry[category][asset_name],
					"metadata": metadata
				})
	
	return results

func search_assets(query: String) -> Array:
	"""Search assets by name or tags"""
	var results = []
	var query_lower = query.to_lower()
	
	for category in asset_registry:
		for asset_name in asset_registry[category]:
			var match_found = false
			
			# Check name
			if asset_name.to_lower().contains(query_lower):
				match_found = true
			
			# Check tags
			if not match_found:
				var tags = asset_tags[category].get(asset_name, [])
				for tag in tags:
					if tag.to_lower().contains(query_lower):
						match_found = true
						break
			
			if match_found:
				results.append({
					"category": category,
					"name": asset_name,
					"asset": asset_registry[category][asset_name],
					"metadata": asset_metadata[category][asset_name]
				})
	
	return results

# Asset management
func add_asset_tag(asset_type: AssetType, asset_name: String, tag: String) -> bool:
	"""Add a tag to an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	
	if not asset_registry[category].has(asset_name):
		return false
	
	var tags = asset_tags[category].get(asset_name, [])
	if not tag in tags:
		tags.append(tag)
		asset_tags[category][asset_name] = tags
	
	return true

func remove_asset_tag(asset_type: AssetType, asset_name: String, tag: String) -> bool:
	"""Remove a tag from an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	
	if not asset_registry[category].has(asset_name):
		return false
	
	var tags = asset_tags[category].get(asset_name, [])
	if tag in tags:
		tags.erase(tag)
		asset_tags[category][asset_name] = tags
	
	return true

func add_asset_dependency(asset_type: AssetType, asset_name: String, dependency: String) -> bool:
	"""Add a dependency to an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	
	if not asset_registry[category].has(asset_name):
		return false
	
	var dependencies = asset_dependencies[category].get(asset_name, [])
	if not dependency in dependencies:
		dependencies.append(dependency)
		asset_dependencies[category][asset_name] = dependencies
	
	return true

func update_asset_metadata(asset_type: AssetType, asset_name: String, metadata: Dictionary) -> bool:
	"""Update metadata for an asset"""
	var category = ASSET_CATEGORIES[asset_type]
	
	if not asset_registry[category].has(asset_name):
		return false
	
	var current_metadata = asset_metadata[category].get(asset_name, {})
	current_metadata.merge(metadata)
	current_metadata["modified_at"] = Time.get_unix_time_from_system()
	asset_metadata[category][asset_name] = current_metadata
	
	return true

# Statistics and reporting
func get_registry_stats() -> Dictionary:
	"""Get statistics about the asset registry"""
	var stats = {
		"total_assets": 0,
		"total_size": 0,
		"categories": {},
		"generators": {},
		"most_used_tags": {},
		"creation_timeline": []
	}
	
	for category in asset_registry:
		var category_count = asset_registry[category].size()
		var category_size = 0
		
		stats["categories"][category] = {
			"count": category_count,
			"size": 0
		}
		
		stats["total_assets"] += category_count
		
		for asset_name in asset_registry[category]:
			var metadata = asset_metadata[category].get(asset_name, {})
			var asset_size = metadata.get("size", 0)
			category_size += asset_size
			stats["total_size"] += asset_size
			
			# Generator stats
			var generator = metadata.get("generator", "unknown")
			if not stats["generators"].has(generator):
				stats["generators"][generator] = 0
			stats["generators"][generator] += 1
			
			# Tag stats
			var tags = asset_tags[category].get(asset_name, [])
			for tag in tags:
				if not stats["most_used_tags"].has(tag):
					stats["most_used_tags"][tag] = 0
				stats["most_used_tags"][tag] += 1
			
			# Timeline
			var created_at = metadata.get("created_at", 0)
			stats["creation_timeline"].append({
				"time": created_at,
				"category": category,
				"name": asset_name
			})
		
		stats["categories"][category]["size"] = category_size
	
	# Sort timeline
	stats["creation_timeline"].sort_custom(func(a, b): return a["time"] < b["time"])
	
	return stats

func get_category_list() -> Array:
	"""Get list of all asset categories"""
	return asset_registry.keys()

func get_assets_in_category(category: String) -> Array:
	"""Get all asset names in a category"""
	return asset_registry.get(category, {}).keys()

# Cache management
func _check_cache_size() -> void:
	"""Check if cache cleanup is needed"""
	var total_assets = 0
	for category in asset_registry:
		total_assets += asset_registry[category].size()
	
	if total_assets > max_cache_size * cache_cleanup_threshold:
		_cleanup_cache()

func _cleanup_cache() -> void:
	"""Clean up old or unused assets"""
	print("[AssetRegistry] Starting cache cleanup...")
	
	var assets_to_remove = []
	var current_time = Time.get_unix_time_from_system()
	var max_age = 3600  # 1 hour
	
	for category in asset_metadata:
		for asset_name in asset_metadata[category]:
			var metadata = asset_metadata[category][asset_name]
			var created_at = metadata.get("created_at", current_time)
			var last_accessed = metadata.get("last_accessed", created_at)
			
			# Remove old unused assets
			if current_time - last_accessed > max_age:
				assets_to_remove.append({
					"category": category,
					"name": asset_name
				})
	
	# Remove old assets
	for asset_info in assets_to_remove:
		var asset_type = _category_to_asset_type(asset_info["category"])
		if asset_type != -1:
			unregister_asset(asset_type, asset_info["name"])
	
	print("[AssetRegistry] Cache cleanup completed. Removed %d assets" % assets_to_remove.size())

func clear_cache() -> void:
	"""Clear all cached assets"""
	print("[AssetRegistry] Clearing all cached assets...")
	
	for category in asset_registry:
		asset_registry[category].clear()
		asset_metadata[category].clear()
		asset_dependencies[category].clear()
		asset_tags[category].clear()
	
	print("[AssetRegistry] Asset cache cleared")

func set_cache_settings(max_size: int, cleanup_threshold: float) -> void:
	"""Configure cache settings"""
	max_cache_size = max_size
	cache_cleanup_threshold = clamp(cleanup_threshold, 0.1, 1.0)
	print("[AssetRegistry] Cache settings updated: max_size=%d, threshold=%.2f" % [max_size, cleanup_threshold])

# Asset export/import
func export_asset_catalog() -> Dictionary:
	"""Export asset catalog for saving"""
	return {
		"version": "1.0",
		"exported_at": Time.get_unix_time_from_system(),
		"metadata": asset_metadata,
		"dependencies": asset_dependencies,
		"tags": asset_tags,
		"stats": get_registry_stats()
	}

func import_asset_catalog(catalog: Dictionary) -> bool:
	"""Import asset catalog from saved data"""
	if not catalog.has("metadata"):
		print("[AssetRegistry] Error: Invalid catalog format")
		return false
	
	# Import metadata
	for category in catalog["metadata"]:
		if asset_metadata.has(category):
			asset_metadata[category].merge(catalog["metadata"][category])
	
	# Import dependencies
	if catalog.has("dependencies"):
		for category in catalog["dependencies"]:
			if asset_dependencies.has(category):
				asset_dependencies[category].merge(catalog["dependencies"][category])
	
	# Import tags
	if catalog.has("tags"):
		for category in catalog["tags"]:
			if asset_tags.has(category):
				asset_tags[category].merge(catalog["tags"][category])
	
	print("[AssetRegistry] Asset catalog imported successfully")
	return true

# Signal handlers
func _on_sprite_generated(sprite_name: String, sprite_texture: ImageTexture) -> void:
	"""Handle sprite generation"""
	register_asset(AssetType.SPRITE, sprite_name, sprite_texture, {
		"generator": "SpriteGenerator",
		"tags": ["procedural", "sprite"]
	})

func _on_texture_generated(texture_name: String, texture: ImageTexture) -> void:
	"""Handle texture generation"""
	register_asset(AssetType.TEXTURE, texture_name, texture, {
		"generator": "TextureGenerator",
		"tags": ["procedural", "texture"]
	})

func _on_audio_generated(audio_name: String, audio_stream: AudioStream) -> void:
	"""Handle audio generation"""
	register_asset(AssetType.AUDIO, audio_name, audio_stream, {
		"generator": "AudioGenerator",
		"tags": ["procedural", "audio"]
	})

func _on_tileset_generated(biome: String, tileset: TileSet) -> void:
	"""Handle tileset generation"""
	register_asset(AssetType.TILESET, "tileset_" + biome, tileset, {
		"generator": "TilesetGenerator",
		"biome": biome,
		"tags": ["procedural", "tileset", biome]
	})

func _on_icon_generated(icon_name: String, texture: ImageTexture) -> void:
	"""Handle icon generation"""
	register_asset(AssetType.ICON, icon_name, texture, {
		"generator": "IconGenerator",
		"tags": ["procedural", "icon", "ui"]
	})

# Utility methods
func _calculate_asset_size(asset_data) -> int:
	"""Calculate approximate size of asset"""
	if asset_data is ImageTexture:
		var image = asset_data.get_image()
		if image:
			return image.get_width() * image.get_height() * 4  # RGBA
	elif asset_data is AudioStream:
		return 1024  # Rough estimate
	elif asset_data is TileSet:
		return 4096  # Rough estimate
	
	return 0

func _detect_asset_format(asset_data) -> String:
	"""Detect the format of an asset"""
	if asset_data is ImageTexture:
		return "ImageTexture"
	elif asset_data is AudioStream:
		return "AudioStream"
	elif asset_data is TileSet:
		return "TileSet"
	elif asset_data is Font:
		return "Font"
	elif asset_data is Shader:
		return "Shader"
	else:
		return "Unknown"

func _category_to_asset_type(category: String) -> AssetType:
	"""Convert category string to AssetType enum"""
	for asset_type in ASSET_CATEGORIES:
		if ASSET_CATEGORIES[asset_type] == category:
			return asset_type
	return -1

# Asset access tracking
func _track_asset_access(asset_type: AssetType, asset_name: String) -> void:
	"""Track when an asset is accessed"""
	var category = ASSET_CATEGORIES[asset_type]
	if asset_metadata[category].has(asset_name):
		asset_metadata[category][asset_name]["last_accessed"] = Time.get_unix_time_from_system()
		
		var access_count = asset_metadata[category][asset_name].get("access_count", 0)
		asset_metadata[category][asset_name]["access_count"] = access_count + 1

# Debug and utility functions
func print_registry_summary() -> void:
	"""Print a summary of the asset registry"""
	var stats = get_registry_stats()
	
	print("\n=== Asset Registry Summary ===")
	print("Total Assets: %d" % stats["total_assets"])
	print("Total Size: %d bytes" % stats["total_size"])
	
	print("\nBy Category:")
	for category in stats["categories"]:
		var cat_stats = stats["categories"][category]
		print("  %s: %d assets (%d bytes)" % [category, cat_stats["count"], cat_stats["size"]])
	
	print("\nBy Generator:")
	for generator in stats["generators"]:
		print("  %s: %d assets" % [generator, stats["generators"][generator]])
	
	print("\nMost Used Tags:")
	var sorted_tags = []
	for tag in stats["most_used_tags"]:
		sorted_tags.append([tag, stats["most_used_tags"][tag]])
	sorted_tags.sort_custom(func(a, b): return a[1] > b[1])
	
	for i in range(min(5, sorted_tags.size())):
		print("  %s: %d uses" % [sorted_tags[i][0], sorted_tags[i][1]])
	
	print("================================\n")

func validate_registry() -> Dictionary:
	"""Validate the registry for consistency"""
	var issues = {
		"missing_metadata": [],
		"orphaned_dependencies": [],
		"invalid_assets": []
	}
	
	for category in asset_registry:
		for asset_name in asset_registry[category]:
			# Check metadata
			if not asset_metadata[category].has(asset_name):
				issues["missing_metadata"].append(category + "/" + asset_name)
			
			# Check dependencies
			var dependencies = asset_dependencies[category].get(asset_name, [])
			for dep in dependencies:
				var dep_found = false
				for check_category in asset_registry:
					if asset_registry[check_category].has(dep):
						dep_found = true
						break
				if not dep_found:
					issues["orphaned_dependencies"].append(category + "/" + asset_name + " -> " + dep)
			
			# Check asset validity
			var asset = asset_registry[category][asset_name]
			if asset == null:
				issues["invalid_assets"].append(category + "/" + asset_name)
	
	return issues