# StringUtils.gd
# Utilidades para manejo de strings
extends RefCounted
class_name StringUtils

static func repeat(text: String, count: int) -> String:
	"""Repetir un string un número específico de veces"""
	var result = ""
	for i in count:
		result += text
	return result

static func center(text: String, width: int, fill_char: String = " ") -> String:
	"""Centrar texto en un ancho específico"""
	var text_length = text.length()
	if text_length >= width:
		return text
	
	var padding = width - text_length
	var left_padding = padding / 2
	var right_padding = padding - left_padding
	
	return repeat(fill_char, left_padding) + text + repeat(fill_char, right_padding)

static func separator(char: String = "=", count: int = 50) -> String:
	"""Crear un separador de línea"""
	return repeat(char, count)
