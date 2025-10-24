shader_type canvas_item;

// ========== BIOME BLENDING SHADER ==========
// Shader profesional para transiciones orgánicas entre biomas adyacentes
// Implementa efectos de "pintura fluida" con ruido fractal y microoscilaciones

// ========== TEXTURAS DE ENTRADA ==========
uniform sampler2D biome_a_base : source_color, hint_default_white;
uniform sampler2D biome_b_base : source_color, hint_default_white;
uniform sampler2D biome_a_decor : source_color, hint_default_white;
uniform sampler2D biome_b_decor : source_color, hint_default_white;
uniform sampler2D noise_mask : source_color, hint_default_white;

// ========== PARÁMETROS DE CONTROL ==========
uniform float blend_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform float time = 0.0;

// ========== CONFIGURACIÓN DE BLENDING ==========
uniform float noise_scale : hint_range(0.1, 5.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.3;
uniform float decor_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float flow_speed : hint_range(0.0, 0.1) = 0.01;

// ========== CONFIGURACIÓN DE COLORES ==========
uniform vec3 blend_tint : source_color = vec3(1.0);
uniform float contrast : hint_range(0.5, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

// ========== FUNCIÓN DE RUIDO FRACTAL ==========
float fractal_noise(vec2 uv, float octaves) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (float i = 0.0; i < octaves; i += 1.0) {
        value += texture(noise_mask, uv * frequency).r * amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// ========== FUNCIÓN DE SUAVIZADO ORGÁNICO ==========
float organic_smoothstep(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    // Función de suavizado cúbico para transiciones más naturales
    return t * t * (3.0 - 2.0 * t);
}

// ========== FUNCIÓN PRINCIPAL ==========
void fragment() {
    // Coordenadas UV con offset y oscilación temporal sutil
    vec2 base_uv = UV + uv_offset;
    vec2 flow_offset = vec2(sin(time * flow_speed), cos(time * flow_speed * 0.7)) * 0.002;
    vec2 animated_uv = base_uv + flow_offset;
    
    // ========== MUESTREO DE TEXTURAS BASE ==========
    vec4 col_a_base = texture(biome_a_base, animated_uv);
    vec4 col_b_base = texture(biome_b_base, animated_uv);
    
    // ========== MUESTREO DE DECORACIONES ==========
    vec2 decor_uv = animated_uv * 2.0; // Escala mayor para detalles
    vec4 col_a_decor = texture(biome_a_decor, decor_uv);
    vec4 col_b_decor = texture(biome_b_decor, decor_uv);
    
    // ========== GENERACIÓN DE MÁSCARA DE MEZCLA ==========
    // Ruido fractal multi-octava para patrones orgánicos complejos
    vec2 noise_uv = animated_uv * noise_scale;
    float noise_primary = fractal_noise(noise_uv, 4.0);
    float noise_detail = fractal_noise(noise_uv * 3.0 + vec2(100.0), 2.0) * 0.3;
    float combined_noise = noise_primary + noise_detail;
    
    // ========== CÁLCULO DE VALOR DE MEZCLA ==========
    float edge_min = 0.5 - (edge_softness * blend_intensity * 0.5);
    float edge_max = 0.5 + (edge_softness * blend_intensity * 0.5);
    float mix_value = organic_smoothstep(edge_min, edge_max, combined_noise);
    
    // Aplicar intensidad de blending
    mix_value = mix(0.5, mix_value, blend_intensity);
    
    // ========== MEZCLA DE TEXTURAS BASE ==========
    vec4 base_mixed = mix(col_a_base, col_b_base, mix_value);
    
    // ========== MEZCLA DE DECORACIONES ==========
    // Las decoraciones usan un mix_value modificado para variedad
    float decor_mix = mix_value + sin(combined_noise * 6.28318) * 0.1;
    decor_mix = clamp(decor_mix, 0.0, 1.0);
    vec4 decor_mixed = mix(col_a_decor, col_b_decor, decor_mix);
    
    // ========== APLICACIÓN DE DECORACIONES ==========
    // Modulación de opacidad basada en ruido para efectos orgánicos
    float decor_alpha = decor_opacity * (0.8 + 0.4 * sin(combined_noise * 3.14159));
    vec4 final_color = base_mixed + decor_mixed * decor_alpha;
    
    // ========== POST-PROCESADO DE COLOR ==========
    // Aplicar tinte de mezcla
    final_color.rgb *= blend_tint;
    
    // Ajuste de contraste
    final_color.rgb = (final_color.rgb - 0.5) * contrast + 0.5;
    
    // Ajuste de saturación
    float luminance = dot(final_color.rgb, vec3(0.299, 0.587, 0.114));
    final_color.rgb = mix(vec3(luminance), final_color.rgb, saturation);
    
    // ========== EFECTO DE BORDE DINÁMICO ==========
    // Añadir sutil variación en los bordes para simular flujo
    float edge_variation = sin(time * 2.0 + combined_noise * 10.0) * 0.02;
    float edge_mask = smoothstep(0.4, 0.6, combined_noise + edge_variation);
    
    // Mezcla final con variación de borde
    final_color.rgb = mix(final_color.rgb, final_color.rgb * 1.1, edge_mask * 0.1);
    
    // ========== SALIDA FINAL ==========
    COLOR = final_color;
}