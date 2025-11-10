shader_type canvas_item;

// Shader de cross-fade suave para AnimatedSprite2D
// Suaviza las transiciones entre frames de animación

uniform float transition_smoothness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Obtener el tiempo de la animación dentro del frame actual
	// Esto crea un fade suave en los bordes de cada frame
	float time_in_frame = fract(TIME * 0.5); // 0.5 FPS base
	
	// Crear una curva suave para la transición
	float alpha_mult = 1.0;
	
	// Fade out al final del frame
	if (time_in_frame > (1.0 - transition_smoothness)) {
		float t = (time_in_frame - (1.0 - transition_smoothness)) / transition_smoothness;
		alpha_mult = 1.0 - smoothstep(0.0, 1.0, t);
	}
	// Fade in al principio del frame
	else if (time_in_frame < transition_smoothness) {
		float t = time_in_frame / transition_smoothness;
		alpha_mult = smoothstep(0.0, 1.0, t);
	}
	
	// Aplicar el fade
	COLOR = vec4(tex_color.rgb, tex_color.a * alpha_mult);
}
