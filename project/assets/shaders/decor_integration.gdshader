shader_type canvas_item;

// Shader para integrar decoraciones con el suelo
// Añade sombra suave y fundido en la base

uniform vec4 biome_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float shadow_height : hint_range(0.0, 1.0) = 0.2;
uniform float base_fade : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Calcular distancia desde la base (UV.y = 1.0 es la base)
	float dist_from_base = 1.0 - UV.y;
	
	// Fade out en la base para fundirse con el suelo
	float base_alpha = 1.0;
	if (dist_from_base < base_fade) {
		base_alpha = smoothstep(0.0, base_fade, dist_from_base);
	}
	
	// Sombra sutil en la parte inferior
	float shadow = 1.0;
	if (dist_from_base < shadow_height) {
		float shadow_factor = 1.0 - (dist_from_base / shadow_height);
		shadow = 1.0 - (shadow_factor * shadow_intensity);
	}
	
	// Aplicar tinte del bioma
	vec3 final_color = tex_color.rgb * biome_tint.rgb * shadow;
	float final_alpha = tex_color.a * base_alpha;
	
	COLOR = vec4(final_color, final_alpha);
}
