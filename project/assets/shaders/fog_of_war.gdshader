shader_type canvas_item;

uniform vec2 player_position = vec2(0.5, 0.5); // En UV de pantalla si es CanvasLayer, o mundo si es Node2D
uniform float unlocked_radius = 500.0; // Radio del mundo desbloqueado
uniform float fade_width = 200.0; // Suavizado del borde
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 0.9);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Calcular distancia al centro (asumiendo que el mapa está centrado en 0,0)
	float dist = length(world_pos);
	
	// Calcular alpha del fog
	// Si dist < unlocked_radius -> alpha 0 (transparente)
	// Si dist > unlocked_radius + fade -> alpha 1 (oscuro)
	float alpha = smoothstep(unlocked_radius, unlocked_radius + fade_width, dist);
	
	COLOR = fog_color;
	COLOR.a *= alpha;
}
