shader_type canvas_item;

// === ARENA ZONE SHADER ===
// Maneja tiling seamless, animación sincronizada y máscara circular
// para las zonas de la arena

// Configuración de animación
uniform int frame_count = 8;
uniform float animation_speed = 8.0; // FPS

// Configuración de tiling
uniform float tile_size = 512.0; // Tamaño de un tile en pixels del mundo
uniform vec2 tile_offset = vec2(0.0); // Offset aleatorio para variar patrón

// Configuración de máscara circular
uniform float outer_radius = 5000.0;
uniform float inner_radius = 0.0;
uniform float fade_width = 150.0;

// Tamaño real del sprite en el mundo (outer_radius * 2)
uniform float sprite_world_size = 10000.0;

void fragment() {
	// === POSICIÓN EN EL MUNDO ===
	// UV va de 0 a 1 a través del sprite
	// Convertir a posición en el mundo relativa al centro (sprite está centrado)
	vec2 world_pos = (UV - 0.5) * sprite_world_size;
	float dist_from_center = length(world_pos);
	
	// === CALCULAR FRAME DE ANIMACIÓN ===
	// TIME es global - todos los sprites animarán sincronizados
	float anim_time = TIME * animation_speed;
	int current_frame = int(mod(anim_time, float(frame_count)));
	
	// === CALCULAR TILING ===
	// Convertir posición del mundo a coordenadas de tile
	vec2 tile_pos = (world_pos + tile_offset * tile_size) / tile_size;
	
	// Obtener la parte fraccionaria para el tiling (repetición seamless)
	vec2 tiled_uv = fract(tile_pos);
	
	// === CALCULAR UV EN EL SPRITESHEET ===
	// El spritesheet tiene todos los frames horizontalmente
	float frame_width = 1.0 / float(frame_count);
	float frame_start = float(current_frame) * frame_width;
	
	vec2 sheet_uv = vec2(
		frame_start + tiled_uv.x * frame_width,
		tiled_uv.y
	);
	
	// === MUESTREAR TEXTURA ===
	vec4 tex_color = texture(TEXTURE, sheet_uv);
	
	// === MÁSCARA CIRCULAR ===
	float mask_alpha = 1.0;
	
	// Fade en borde exterior
	if (dist_from_center > outer_radius - fade_width) {
		mask_alpha *= 1.0 - smoothstep(outer_radius - fade_width, outer_radius, dist_from_center);
	}
	
	// Fade en borde interior (para anillos)
	if (inner_radius > 0.0 && dist_from_center < inner_radius + fade_width) {
		mask_alpha *= smoothstep(inner_radius, inner_radius + fade_width, dist_from_center);
	}
	
	// === OUTPUT ===
	COLOR = tex_color;
	COLOR.a *= mask_alpha;
}
