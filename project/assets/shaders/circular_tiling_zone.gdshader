shader_type canvas_item;

// Shader para zonas circulares con tiling perfecto
// Renderiza una textura seamless en un círculo/anillo perfecto con bordes anti-aliased

// TEXTURE es la textura del sprite, se pasa automáticamente
uniform float outer_radius : hint_range(0.0, 1.0) = 0.5;  // Radio exterior normalizado
uniform float inner_radius : hint_range(0.0, 1.0) = 0.0;  // Radio interior (0 = círculo sólido)
uniform float tile_count : hint_range(1.0, 200.0) = 20.0;  // Número de repeticiones de la textura
uniform float edge_smoothness : hint_range(0.0001, 0.05) = 0.005;  // Suavizado del borde

void fragment() {
    // Posición centrada (-0.5 a 0.5 desde el centro del sprite)
    vec2 centered_uv = UV - 0.5;
    
    // Distancia al centro normalizada
    float dist = length(centered_uv);
    
    // UV para tiling - multiplicamos por tile_count para crear repeticiones
    vec2 tile_uv = fract(UV * tile_count);
    
    // Usar TEXTURE (la textura del sprite) en lugar de un uniform separado
    vec4 tex_color = texture(TEXTURE, tile_uv);
    
    // Máscara circular con anti-aliasing perfecto
    float outer_mask = 1.0 - smoothstep(outer_radius - edge_smoothness, outer_radius, dist);
    float inner_mask = smoothstep(inner_radius, inner_radius + edge_smoothness, dist);
    
    // Combinar máscaras para crear anillo o círculo
    float final_mask = outer_mask * inner_mask;
    
    // Aplicar color y máscara
    COLOR = tex_color;
    COLOR.a *= final_mask;
}
