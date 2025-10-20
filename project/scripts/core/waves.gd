extends Node

# Waves manager: pools por segmentos de 5 minutos.
# choose_two_enemies_per_tier(minute) devuelve { "tier_1": [id,id], ... }

var wave_segments: Array = []

func _ready():
	# Definimos segmentos por cada 5 minutos (0..N)
	wave_segments = [
		{ # 0-4
			"tier_1": ["slime", "goblin", "esqueleto_aprendiz"],
			"tier_2": ["slime", "skeleton"],
			"tier_3": ["mago_abismal", "corruptor_alado"],
			"tier_4": ["titan_arcano"]
		},
		{ # 5-9
			"tier_1": ["goblin", "slime"],
			"tier_2": ["goblin", "skeleton"],
			"tier_3": ["elemental_de_hielo", "mago_abismal"],
			"tier_4": ["senor_de_las_llamas"]
		},
		{ # 10-14
			"tier_1": ["slime", "esqueleto_aprendiz"],
			"tier_2": ["lobo_de_cristal", "golem_runico"],
			"tier_3": ["serpiente_de_fuego", "caballero_del_vacio"],
			"tier_4": ["reina_del_hielo"]
		},
		{ # 15-19
			"tier_1": ["goblin", "esqueleto_aprendiz"],
			"tier_2": ["golem_runico", "hechicero_desgastado"],
			"tier_3": ["mago_abismal", "serpiente_de_fuego"],
			"tier_4": ["archimago_perdido"]
		}
	]

func choose_two_enemies_per_tier(minute: int) -> Dictionary:
	var segment_idx = int(floor(float(minute) / 5.0))
	if segment_idx >= wave_segments.size():
		segment_idx = wave_segments.size() - 1
	if segment_idx < 0:
		segment_idx = 0

	var seg = wave_segments[segment_idx]
	var out = {}
	for tier in seg.keys():
		var pool = seg[tier].duplicate()
		pool.shuffle()
		out[tier] = pool.slice(0, min(2, pool.size()))
	return out

