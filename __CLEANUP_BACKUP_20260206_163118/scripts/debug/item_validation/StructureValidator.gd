# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# WARNING: DO NOT LOAD THIS SCRIPT IN RUNTIME (RELEASE) BUILDS
# This script is part of the DEBUG/QA Harness.
# Loading it in production will cause crashes or undefined behavior.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

extends Node
class_name StructureValidator

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATOR DE INTEGRIDAD DE DATOS
# ═══════════════════════════════════════════════════════════════════════════════
# Objetivo: Asegurar que no existan IDs duplicados ni definiciones inválidas
# que puedan causar comportamientos silenciosos erróneos (como values incorrectos).
# ═══════════════════════════════════════════════════════════════════════════════

static func validate_integrity() -> Dictionary:
	var result = {
		"passed": true,
		"errors": [],
		"stats": {"total_items": 0, "unique_ids": 0}
	}
	
	var all_ids = {} # ID -> Source location
	
	# 1. Validar UpgradeDatabase
	_check_dictionary(UpgradeDatabase.DEFENSIVE_UPGRADES, "UpgradeDatabase.DEFENSIVE", all_ids, result)
	_check_dictionary(UpgradeDatabase.UTILITY_UPGRADES, "UpgradeDatabase.UTILITY", all_ids, result)
	_check_dictionary(UpgradeDatabase.OFFENSIVE_UPGRADES, "UpgradeDatabase.OFFENSIVE", all_ids, result)
	_check_dictionary(UpgradeDatabase.CURSED_UPGRADES, "UpgradeDatabase.CURSED", all_ids, result)
	_check_dictionary(UpgradeDatabase.UNIQUE_UPGRADES, "UpgradeDatabase.UNIQUE", all_ids, result)
	
	# 2. Validar WeaponUpgradeDatabase
	if WeaponUpgradeDatabase:
		_check_dictionary(WeaponUpgradeDatabase.GLOBAL_UPGRADES, "WeaponUpgradeDatabase.GLOBAL", all_ids, result)
		_check_dictionary(WeaponUpgradeDatabase.SPECIFIC_UPGRADES, "WeaponUpgradeDatabase.SPECIFIC", all_ids, result)
	
	# 3. Validar WeaponDatabase
	if WeaponDatabase:
		_check_dictionary(WeaponDatabase.WEAPONS, "WeaponDatabase.WEAPONS", all_ids, result)
		_check_dictionary(WeaponDatabase.FUSIONS, "WeaponDatabase.FUSIONS", all_ids, result)

	result["stats"]["unique_ids"] = all_ids.size()
	
	if not result["passed"]:
		printerr("[StructureValidator] CRITICAL INTEGRITY ERRORS FOUND:")
		for err in result["errors"]:
			printerr(" - " + err)
			
	return result

static func _check_dictionary(dict: Dictionary, source_name: String, all_ids: Dictionary, result: Dictionary) -> void:
	for key in dict:
		var item = dict[key]
		result["stats"]["total_items"] += 1
		
		# 1. Validar ID Consistency
		if not item.has("id"):
			result["passed"] = false
			result["errors"].append("[%s] Item key '%s' missing 'id' field" % [source_name, key])
			continue
			
		var id = item["id"]
		# Skip Key==ID check for FUSIONS (Key is "w1+w2", ID is "fusion_name")
		if "FUSIONS" not in source_name:
			if id != key:
				result["passed"] = false
				result["errors"].append("[%s] Key/ID mismatch: Key='%s' vs ID='%s'" % [source_name, key, id])
		
		# 2. Validar Duplicados Globales
		if all_ids.has(id):
			result["passed"] = false
			result["errors"].append("DUPLICATE ID DETECTED: '%s' found in '%s' AND '%s'" % [id, all_ids[id], source_name])
		else:
			all_ids[id] = source_name
			
		# 3. Validar Estructura Básica
		if not item.has("effects") and not item.has("effect"):
			# Algunos items (weapons) no tienen effects list, tienen stats directos.
			# Pero upgrades deben tener effects.
			if source_name.begins_with("UpgradeDatabase"):
				result["passed"] = false
				result["errors"].append("[%s] Item '%s' missing 'effects' list" % [source_name, id])
