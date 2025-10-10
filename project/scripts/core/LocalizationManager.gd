# LocalizationManager - Simplified version for minimal project
# A basic localization manager that provides essential text functionality

extends Node

# Basic localization data
var current_language: String = "en"
var translations: Dictionary = {
	"en": {
		"play": "Play",
		"settings": "Settings",
		"exit": "Exit",
		"health": "Health",
		"level": "Level",
		"score": "Score",
		"pause": "Pause",
		"resume": "Resume",
		"main_menu": "Main Menu",
		"game_over": "Game Over",
		"victory": "Victory!",
		"restart": "Restart"
	},
	"es": {
		"play": "Jugar",
		"settings": "Configuración",
		"exit": "Salir",
		"health": "Salud",
		"level": "Nivel",
		"score": "Puntuación",
		"pause": "Pausa",
		"resume": "Continuar",
		"main_menu": "Menú Principal",
		"game_over": "Fin del Juego",
		"victory": "¡Victoria!",
		"restart": "Reiniciar"
	}
}

# Available languages
var available_languages: Array = ["en", "es"]

func _ready():
	# Set default language
	set_language("en")
	print("LocalizationManager: Basic localization system initialized")

# Get localized text
func get_text(key: String, default_value: String = "") -> String:
	if current_language in translations:
		if key in translations[current_language]:
			return translations[current_language][key]
	
	# Fallback to English if current language doesn't have the key
	if "en" in translations and key in translations["en"]:
		return translations["en"][key]
	
	# Return default value or key if not found
	return default_value if default_value != "" else key

# Set the current language
func set_language(language: String) -> void:
	if language in available_languages:
		current_language = language
		print("LocalizationManager: Language set to ", language)
		# Emit signal if other systems need to update
		language_changed.emit(language)
	else:
		print("LocalizationManager: Language '", language, "' not available")

# Get current language
func get_current_language() -> String:
	return current_language

# Get available languages
func get_available_languages() -> Array:
	return available_languages

# Signal for when language changes
signal language_changed(new_language: String)

# Convenience function for common translations
func translate(key: String) -> String:
	return get_text(key)

# Add a new translation key
func add_translation(key: String, language: String, value: String) -> void:
	if not language in translations:
		translations[language] = {}
	translations[language][key] = value

# Check if a translation exists
func has_translation(key: String, language: String = "") -> bool:
	var lang = language if language != "" else current_language
	return lang in translations and key in translations[lang]