# Localization.gd
# Internationalization and localization system for multi-language support
# Handles text translation, language switching, and locale-specific formatting
#
# Public API:
# - L(key: String, args: Array = []) -> String  # Short alias for get_text (avoids Godot's tr conflict)
# - get_text(key: String, args: Array = []) -> String
# - set_language(language_code: String) -> bool
# - get_current_language() -> String
# - get_available_languages() -> Array[String]
# - is_language_available(language_code: String) -> bool
#
# Signals:
# - language_changed(old_language: String, new_language: String)
# - translation_loaded(language: String)

extends Node

signal language_changed(old_language: String, new_language: String)
signal translation_loaded(language: String)

# Supported languages with display names and native names
const SUPPORTED_LANGUAGES = {
	"en": {"name": "English", "native": "English", "flag": "🇬🇧"},
	"es": {"name": "Spanish", "native": "Español", "flag": "🇪🇸"},
	"fr": {"name": "French", "native": "Français", "flag": "🇫🇷"},
	"pt": {"name": "Portuguese", "native": "Português", "flag": "🇧🇷"},
	"ru": {"name": "Russian", "native": "Русский", "flag": "🇷🇺"},
	"de": {"name": "German", "native": "Deutsch", "flag": "🇩🇪"},
	"it": {"name": "Italian", "native": "Italiano", "flag": "🇮🇹"},
	"zh": {"name": "Chinese", "native": "中文", "flag": "🇨🇳"},
	"ja": {"name": "Japanese", "native": "日本語", "flag": "🇯🇵"},
	"ko": {"name": "Korean", "native": "한국어", "flag": "🇰🇷"}
}

# Translation data
var translations: Dictionary = {}
var current_language: String = "en"

# Translation file paths
const TRANSLATION_DIR = "res://assets/data/localization/"
const FALLBACK_LANGUAGE = "en"

func _ready() -> void:
	print("[Localization] Initializing Localization...")

	# Load translation files
	_load_all_translations()

	# Set initial language from settings
	_load_language_from_settings()

	print("[Localization] Localization initialized with language: ", current_language)

func _load_all_translations() -> void:
	"""Load all available translation files"""
	for lang_code in SUPPORTED_LANGUAGES.keys():
		_load_translation_file(lang_code)

func _load_translation_file(language_code: String) -> bool:
	"""Load translation file for specific language"""
	var file_path = TRANSLATION_DIR + language_code + ".json"

	if not FileAccess.file_exists(file_path):
		print("[Localization] Translation file not found: ", file_path)

		# Create default translation file
		_create_default_translation_file(language_code)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[Localization] Failed to open translation file: ", file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("[Localization] Failed to parse translation file: ", file_path)
		return false

	translations[language_code] = json.data
	print("[Localization] Loaded translations for: ", language_code)
	translation_loaded.emit(language_code)

	return true

func _create_default_translation_file(language_code: String) -> void:
	"""Create a default translation file with base keys"""
	var default_translations = _get_default_translations(language_code)

	# Ensure directory exists
	DirAccess.open("res://").make_dir_recursive("assets/data/localization")

	var file_path = TRANSLATION_DIR + language_code + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(default_translations, "\t"))
		file.close()
		print("[Localization] Created default translation file: ", file_path)

		# Load the created file
		translations[language_code] = default_translations

func _get_default_translations(language_code: String) -> Dictionary:
	"""Get default translations for a language"""
	match language_code:
		"en":
			return {
				"ui": {
					"main_menu": {
						"title": "SPELLLOOP",
						"new_run": "New Run",
						"continue": "Continue",
						"settings": "Settings",
						"quit": "Quit"
					},
					"pause_menu": {
						"title": "PAUSED",
						"resume": "Resume",
						"settings": "Settings",
						"main_menu": "Main Menu",
						"quit": "Quit Game"
					},
					"settings": {
						"title": "Settings",
						"audio": "Audio",
						"video": "Video",
						"controls": "Controls",
						"language": "Language",
						"back": "Back",
						"reset": "Reset to Defaults"
					},
					"game_over": {
						"title": "Run Complete",
						"score": "Score",
						"time": "Time",
						"rooms": "Rooms Cleared",
						"enemies": "Enemies Defeated",
						"continue": "Continue",
						"retry": "Try Again"
					}
				},
				"gameplay": {
					"spells": {
						"fireball": "Fireball",
						"ice_shard": "Ice Shard",
						"lightning_bolt": "Lightning Bolt",
						"healing_light": "Healing Light"
					},
					"enemies": {
						"basic_slime": "Slime",
						"fire_imp": "Fire Imp",
						"ice_golem": "Ice Golem",
						"shadow_wraith": "Shadow Wraith"
					},
					"biomes": {
						"fire_caverns": "Fire Caverns",
						"ice_peaks": "Frozen Peaks",
						"shadow_realm": "Shadow Realm",
						"crystal_gardens": "Crystal Gardens"
					}
				},
				"messages": {
					"game_saved": "Game saved successfully",
					"game_loaded": "Game loaded successfully",
					"spell_unlocked": "New spell unlocked: {0}",
					"mage_unlocked": "New mage unlocked: {0}",
					"achievement_unlocked": "Achievement unlocked: {0}"
				}
			}
		"es":
			return {
				"ui": {
					"main_menu": {
						"title": "SPELLLOOP",
						"new_run": "Nueva Partida",
						"continue": "Continuar",
						"settings": "Configuración",
						"quit": "Salir"
					},
					"pause_menu": {
						"title": "PAUSADO",
						"resume": "Reanudar",
						"settings": "Configuración",
						"main_menu": "Menú Principal",
						"quit": "Salir del Juego"
					},
					"settings": {
						"title": "Configuración",
						"audio": "Audio",
						"video": "Video",
						"controls": "Controles",
						"language": "Idioma",
						"back": "Atrás",
						"reset": "Restablecer"
					},
					"game_over": {
						"title": "Partida Completada",
						"score": "Puntuación",
						"time": "Tiempo",
						"rooms": "Salas Completadas",
						"enemies": "Enemigos Derrotados",
						"continue": "Continuar",
						"retry": "Intentar de Nuevo"
					}
				},
				"gameplay": {
					"spells": {
						"fireball": "Bola de Fuego",
						"ice_shard": "Fragmento de Hielo",
						"lightning_bolt": "Rayo",
						"healing_light": "Luz Curativa"
					},
					"enemies": {
						"basic_slime": "Slime",
						"fire_imp": "Diablillo de Fuego",
						"ice_golem": "Gólem de Hielo",
						"shadow_wraith": "Espectro Sombra"
					},
					"biomes": {
						"fire_caverns": "Cavernas de Fuego",
						"ice_peaks": "Picos Helados",
						"shadow_realm": "Reino de las Sombras",
						"crystal_gardens": "Jardines de Cristal"
					}
				},
				"messages": {
					"game_saved": "Juego guardado exitosamente",
					"game_loaded": "Juego cargado exitosamente",
					"spell_unlocked": "Nuevo hechizo desbloqueado: {0}",
					"mage_unlocked": "Nuevo mago desbloqueado: {0}",
					"achievement_unlocked": "Logro desbloqueado: {0}"
				}
			}
		_:
			return {}

func get_text(key: String, args: Array = []) -> String:
	"""Get localized text for a key with optional arguments"""
	var text = _get_text_recursive(key, translations.get(current_language, {}))

	# Fallback to English if not found
	if text == key and current_language != FALLBACK_LANGUAGE:
		text = _get_text_recursive(key, translations.get(FALLBACK_LANGUAGE, {}))

	# Apply string formatting if args provided
	if args.size() > 0:
		text = _format_string(text, args)

	return text

func _get_text_recursive(key: String, dict: Dictionary) -> String:
	"""Recursively get text from nested dictionary using dot notation"""
	var keys = key.split(".")
	var current = dict

	for k in keys:
		if current is Dictionary and current.has(k):
			current = current[k]
		else:
			return key  # Return key if not found

	if current is String:
		return current
	else:
		return key  # Return key if final value is not string

func _format_string(text: String, args: Array) -> String:
	"""Format string with arguments using {0}, {1}, etc. placeholders"""
	var formatted = text

	for i in range(args.size()):
		var placeholder = "{" + str(i) + "}"
		formatted = formatted.replace(placeholder, str(args[i]))

	return formatted

func set_language(language_code: String) -> bool:
	"""Set the current language"""
	if not is_language_available(language_code):
		print("[Localization] Language not available: ", language_code)
		return false

	var old_language = current_language
	current_language = language_code

	# Save to settings
	_save_language_to_settings()

	language_changed.emit(old_language, current_language)
	print("[Localization] Language changed from '", old_language, "' to '", current_language, "'")

	return true

func get_current_language() -> String:
	"""Get the current language code"""
	return current_language

func get_available_languages() -> Array[String]:
	"""Get list of available language codes"""
	var langs: Array[String] = []
	for key in SUPPORTED_LANGUAGES.keys():
		langs.append(key)
	return langs

func get_language_display_name(language_code: String) -> String:
	"""Get display name for a language code"""
	if SUPPORTED_LANGUAGES.has(language_code):
		return SUPPORTED_LANGUAGES[language_code].get("name", language_code)
	return language_code

func get_language_native_name(language_code: String) -> String:
	"""Get native name for a language code (e.g., 'Español' for 'es')"""
	if SUPPORTED_LANGUAGES.has(language_code):
		return SUPPORTED_LANGUAGES[language_code].get("native", language_code)
	return language_code

func get_language_flag(language_code: String) -> String:
	"""Get flag emoji for a language code"""
	if SUPPORTED_LANGUAGES.has(language_code):
		return SUPPORTED_LANGUAGES[language_code].get("flag", "🏳️")
	return "🏳️"

func is_language_available(language_code: String) -> bool:
	"""Check if a language is available"""
	return language_code in SUPPORTED_LANGUAGES

# ═══════════════════════════════════════════════════════════════════════════════
# SHORT ALIAS - Use L() for convenience (tr is reserved by Godot's Object class)
# ═══════════════════════════════════════════════════════════════════════════════

func L(key: String, args: Array = []) -> String:
	"""Short alias for get_text() - Use this in UI code
	Named 'L' to avoid conflict with Godot's native tr() method"""
	return get_text(key, args)

func _load_language_from_settings() -> void:
	"""Load language setting from SaveManager"""
	# Use runtime lookup for SaveManager autoload to avoid parse-time identifier issues
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("SaveManager"):
		var sm = get_tree().root.get_node("SaveManager")
		if sm and sm.is_data_loaded:
			var settings = sm.current_settings
			if settings.has("language"):
				var saved_language = settings["language"]
				if is_language_available(saved_language):
					current_language = saved_language
				else:
					print("[Localization] Invalid language in settings: ", saved_language, ", using default")

func _save_language_to_settings() -> void:
	"""Save current language to settings"""
	# Use runtime lookup for SaveManager autoload to avoid parse-time identifier issues
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("SaveManager"):
		var sm = get_tree().root.get_node("SaveManager")
		if sm:
			var settings = sm.current_settings
			settings["language"] = current_language
			if sm.has_method("save_settings"):
				sm.save_settings(settings)

# Convenience methods for common UI text
func get_ui_text(key: String, args: Array = []) -> String:
	"""Get UI text with 'ui.' prefix"""
	return get_text("ui." + key, args)

func get_gameplay_text(key: String, args: Array = []) -> String:
	"""Get gameplay text with 'gameplay.' prefix"""
	return get_text("gameplay." + key, args)

func get_message(key: String, args: Array = []) -> String:
	"""Get message text with 'messages.' prefix"""
	return get_text("messages." + key, args)

# Auto-detection helpers
func detect_system_language() -> String:
	"""Detect system language and return supported language code"""
	var system_locale = OS.get_locale()
	var language_code = system_locale.split("_")[0]  # Get language part (e.g., "en" from "en_US")

	if is_language_available(language_code):
		return language_code
	else:
		return FALLBACK_LANGUAGE

