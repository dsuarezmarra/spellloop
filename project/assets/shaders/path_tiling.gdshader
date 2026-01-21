shader_type canvas_item;

uniform sampler2D path_texture : filter_linear_mipmap, repeat_enable;
uniform float tiling_factor = 0.2; // Valor bajo para estirar la textura (reducir repeticiones)
uniform float brightness = 1.0;

void fragment() {
	// UV.x sigue la longitud de la línea
	// UV.y va de 0 a 1 a lo ancho
	
	// Ajustamos la repetición en X para estirar la textura
	// Si tiling_factor < 1.0, la textura se "estira" (menos repeticiones por metro)
	vec2 uv = UV;
	uv.x = uv.x * tiling_factor;
	
	vec4 tex_color = texture(path_texture, uv);
	
	// Aplicar brillo/color
	COLOR = tex_color * MODULATE * vec4(brightness, brightness, brightness, 1.0);
}
