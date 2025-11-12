// tile_blend.gdshader
// Shader sutil para suavizar ligeramente las uniones entre tiles
shader_type canvas_item;

uniform float blend_strength : hint_range(0.0, 1.0) = 0.15;  // Muy sutil

void fragment() {
	vec2 uv = UV;
	vec4 color = texture(TEXTURE, uv);
	
	// Detectar si estamos cerca de un borde de tile (cada 512px)
	vec2 screen_pos = FRAGCOORD.xy;
	vec2 tile_pos = mod(screen_pos, 512.0);
	
	// Distancia al borde más cercano (horizontal y vertical)
	float dist_to_edge_x = min(tile_pos.x, 512.0 - tile_pos.x);
	float dist_to_edge_y = min(tile_pos.y, 512.0 - tile_pos.y);
	float dist_to_edge = min(dist_to_edge_x, dist_to_edge_y);
	
	// Aplicar blur muy sutil solo en los primeros 2 píxeles del borde
	if (dist_to_edge < 2.0) {
		vec4 blur = vec4(0.0);
		float total = 0.0;
		
		// Micro-blur de 3x3 muy ligero
		for (float x = -1.0; x <= 1.0; x += 1.0) {
			for (float y = -1.0; y <= 1.0; y += 1.0) {
				vec2 offset = vec2(x, y) * (1.0 / 1920.0); // Normalizado al viewport
				blur += texture(TEXTURE, uv + offset);
				total += 1.0;
			}
		}
		blur /= total;
		
		// Factor de mezcla: máximo en el borde, se desvanece en 2px
		float edge_factor = (2.0 - dist_to_edge) / 2.0;
		edge_factor *= blend_strength;
		
		color = mix(color, blur, edge_factor);
	}
	
	COLOR = color;
}
