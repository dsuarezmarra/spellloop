shader_type canvas_item;

// Textura seamless del suelo (tierra, nieve, lava, etc.)
uniform sampler2D texture_albedo : source_color, repeat_enable, filter_linear_mipmap;
// Escala de la textura (ajustar para que el tamaño del grano sea correcto)
uniform vec2 texture_scale = vec2(0.003, 0.003);
// Suavizado de los bordes del camino (0.0 a 1.0)
uniform float edge_softness : hint_range(0.0, 1.0) = 0.4;
// Ruido opcional para bordes irregulares
uniform sampler2D noise_texture : repeat_enable, filter_linear;

// Radio mínimo (para hacer clip en zonas interiores)
uniform float min_radius = 0.0;
// Radio máximo (para hacer clip en zonas exteriores)
uniform float max_radius = 100000.0;

varying vec2 world_pos;

void vertex() {
	// Calcular posición absoluta en el mundo
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// 1. Muestrear textura usando coordenadas MUNDIALES
	// Esto hace que la textura sea estática (como un suelo real) y el camino
	// solo actúa como una "máscara" que la revela. Cero distorsión en curvas.
	// Rotar UVs 45 grados para evitar alineación con la retícula de píxeles
	float angle = 0.785398;
	mat2 rot = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	vec2 uv = (rot * world_pos) * texture_scale;
	
	vec4 col = texture(texture_albedo, uv);
	
	// 2. Calcular alpha basado en el ancho de la línea (UV.y)
	// UV.y va de 0 a 1 a lo ancho de la Line2D. 0.5 es el centro.
	float dist_from_center = abs(UV.y - 0.5) * 2.0; // 0 en centro, 1 en bordes
	
	// 3. Aplicar suavizado en los bordes
	float alpha = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist_from_center);
	
	// 4. CLIPPING CIRCULAR (Standard)
	// Usamos discard para asegurar corte limpio y evitar problemas de alpha/blending
	float dist_to_center = length(world_pos);
	
	if (dist_to_center < min_radius || dist_to_center > max_radius) {
		discard;
	}
	
	// Aplicar color y transparencia
	COLOR = col * COLOR;
	COLOR.a *= alpha;
}
