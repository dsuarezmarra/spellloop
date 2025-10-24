# TEST: Verificación simple de sintaxis para InfiniteWorldManager
# Este archivo sirve solo para verificar que la sintaxis es correcta

extends Node

func test_loading():
	# Este método no se ejecutará, solo verifica parsing
	var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	var osg_script = load("res://scripts/core/OrganicShapeGenerator.gd")
	var bra_script = load("res://scripts/core/BiomeRegionApplier.gd")
	var otb_script = load("res://scripts/core/OrganicTextureBlender.gd")
	print("All scripts loaded successfully if this prints")