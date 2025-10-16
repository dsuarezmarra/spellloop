extends Node
# Test para verificar que la corrección de empty() funciona

func _ready():
	print("🧪 Probando corrección de empty()...")
	
	var test_array = []
	var test_array2 = [1, 2, 3]
	
	# Test usando is_empty() (correcto)
	print("✅ Array vacío is_empty():", test_array.is_empty())
	print("✅ Array con datos is_empty():", test_array2.is_empty())
	
	# Verificar que el SpawnTable funciona
	print("🎯 Testing SpawnTable.get_spawn_pack()...")
	if SpawnTable:
		var pack = SpawnTable.get_spawn_pack(1)
		if pack:
			print("✅ SpawnTable funcionando correctamente")
		else:
			print("⚠️ SpawnTable retornó null (esperado si no hay packs)")
	
	print("🎉 ¡Corrección de empty() completada!")