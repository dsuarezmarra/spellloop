shader_type canvas_item;

// Uniforms para controlar el efecto
uniform float radius = 0.5; // Radio normalizado (0.0 a 0.5) donde empieza el borde
uniform float smoothness = 0.02; // Suavizado del borde interior
uniform float pulse_speed = 1.0; // Velocidad del latido
uniform float noise_scale = 4.0; // Escala del ruido
uniform float chaos_speed = 0.5; // Velocidad de movimiento del "humo"

// Colores
uniform vec4 color_edge : source_color = vec4(1.0, 0.2, 0.1, 1.0); // Rojo neón (borde interior)
uniform vec4 color_mid : source_color = vec4(0.5, 0.0, 0.2, 0.8);  // Púrpura oscuro (medio)
uniform vec4 color_void : source_color = vec4(0.1, 0.05, 0.1, 0.9); // Casi negro (lejano)

// Función de ruido simple (pseudo-random)
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Ruido 2D
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Cubic interpolation
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a) * u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

// Fractal Brownian Motion para humo detallado
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    // Coordenadas UV centradas (-0.5 a 0.5)
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    // Si estamos DENTRO de la arena (antes del radio), ser transparente
    // Usamos smoothstep para un borde suave pero definido
    float border_mask = smoothstep(radius, radius + smoothness, dist);
    
    // Si la máscara es 0 (dentro del radio seguro), descartar o alpha 0
    if (border_mask <= 0.001) {
        COLOR = vec4(0.0);
    } else {
        // --- EFERVECENCIA DEL VACÍO ---
        
        // Coordenadas polares para que el ruido fluya radialmente o en espiral
        float angle = atan(uv.y, uv.x);
        
        // Animación dinámica
        float time = TIME * chaos_speed;
        
        // Distorsión UV basada en ruido para efecto "líquido/humo"
        vec2 noise_uv = uv * noise_scale;
        
        // Añadir movimiento espiral
        noise_uv.x += cos(time) * 0.5;
        noise_uv.y += sin(time) * 0.5;
        
        // Obtener valor de ruido fractal
        float noise_val = fbm(noise_uv + vec2(time * 0.2));
        
        // --- PULSACIÓN ---
        float pulse = sin(TIME * pulse_speed) * 0.05 + 0.95; // 0.9 a 1.0
        
        // --- COLOREADO ---
        
        // Gradiente basado en distancia desde el borde
        // normalizamos la distancia "fuera" del radio
        float dist_beyond = (dist - radius) * (1.0 / (0.5 - radius)); // 0.0 en borde, 1.0 en esquina
        
        // Mezclar con el ruido
        float final_intensity = dist_beyond + (noise_val * 0.3);
        
        vec4 final_color;
        
        if (dist_beyond < 0.1) {
            // Borde inmediato: Rojo neón brillante + pulsación
            final_color = mix(color_edge, color_mid, dist_beyond * 10.0);
            final_color.rgb *= pulse * 1.5; // Brillo extra (HDR fake)
        } else {
            // Zona media y lejana: Transición a Void
            final_color = mix(color_mid, color_void, smoothstep(0.1, 0.6, dist_beyond));
            // Añadir "venas" oscuras usando el ruido invertido
            final_color.rgb *= (0.5 + 0.5 * noise_val);
        }
        
        // Alpha basado en la máscara del borde
        final_color.a *= border_mask;
        
        COLOR = final_color;
    }
}
