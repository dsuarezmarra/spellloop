shader_type canvas_item;

// Textura seamless del suelo (tierra, nieve, lava, etc.)
uniform sampler2D texture_albedo : source_color, repeat_enable, filter_linear_mipmap;
// Escala de la textura (ajustar para que el tamaño del grano sea correcto)
uniform vec2 texture_scale = vec2(0.003, 0.003);
// Suavizado de los bordes del camino (0.0 a 1.0)
uniform float edge_softness : hint_range(0.0, 1.0) = 0.4;
// Ruido opcional para bordes irregulares
uniform sampler2D noise_texture : repeat_enable, filter_linear;

varying vec2 world_pos;

void vertex() {
	// Calcular posición absoluta en el mundo
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// 1. Muestrear textura usando coordenadas MUNDIALES
	// Esto hace que la textura sea estática (como un suelo real) y el camino
	// solo actúa como una "máscara" que la revela. Cero distorsión en curvas.
	// Mezclar dos muestras de la textura (0° y 90°) para romper la direccionalidad
	// Esto convierte una textura de "franjas" en una de "ruido/tierra" genérica.
	vec2 uv = world_pos * texture_scale;
	vec4 col1 = texture(texture_albedo, uv);
	vec4 col2 = texture(texture_albedo, vec2(uv.y, -uv.x)); // Rotada 90 grados
	vec4 col = mix(col1, col2, 0.5);
	
	// 2. Calcular alpha basado en el ancho de la línea (UV.y)
	// UV.y va de 0 a 1 a lo ancho de la Line2D. 0.5 es el centro.
	float dist_from_center = abs(UV.y - 0.5) * 2.0; // 0 en centro, 1 en bordes
	
	// 3. Aplicar suavizado en los bordes
	float alpha = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist_from_center);
	
	// Aplicar color y transparencia
	COLOR = col * COLOR;
	COLOR.a *= alpha;
}
