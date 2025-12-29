shader_type canvas_item;

// === DECORATION ANIMATION SHADER ===
// Shader para decoraciones animadas desde spritesheet horizontal

uniform sampler2D spritesheet : source_color, filter_nearest;
uniform int frame_count = 8;
uniform float animation_speed = 8.0;
uniform float time_offset = 0.0; // Offset para variación entre decoraciones

void fragment() {
	// Calcular frame actual (sincronizado globalmente + offset individual)
	float anim_time = TIME * animation_speed + time_offset;
	int current_frame = int(mod(anim_time, float(frame_count)));
	
	// Calcular UV en el spritesheet
	float frame_width = 1.0 / float(frame_count);
	float frame_start = float(current_frame) * frame_width;
	
	vec2 sheet_uv = vec2(
		frame_start + UV.x * frame_width,
		UV.y
	);
	
	COLOR = texture(spritesheet, sheet_uv);
}
