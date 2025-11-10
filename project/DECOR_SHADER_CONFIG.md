# Configuración del Shader de Integración de Decoraciones

## Descripción General

El sistema de decoraciones ahora incluye un **shader de integración** que fusiona visualmente las decoraciones con el suelo del bioma mediante:

1. **Tinte del Bioma**: Color que unifica la decoración con el entorno
2. **Sombra en la Base**: Oscurecimiento gradual donde la decoración "toca" el suelo
3. **Fundido Alpha**: Transparencia gradual en la parte inferior para suavizar el contacto

## Arquitectura

### Archivos Clave

- **Shader**: `assets/shaders/decor_integration.gdshader`
- **Factory**: `scripts/utils/DecorFactory.gd`
- **Aplicador**: `scripts/core/BiomeChunkApplierOrganic.gd`

### Flujo de Integración

```
BiomeChunkApplierOrganic._create_random_biome_decor_node()
  └─> DecorFactory.make_decor(tex_path, fps, use_shader, biome_name)
      └─> DecorFactory._apply_integration_shader(node, biome_name)
          └─> Configura shader según bioma (match statement)
```

## Configuraciones por Bioma

### 🔥 Lava
```gdscript
biome_tint:        Color(1.0, 0.85, 0.6, 1.0)   # Naranja cálido
shadow_intensity:  0.4                          # Sombra moderada
shadow_height:     0.25                         # 25% inferior
base_fade:         0.12                         # 12% fundido
```
**Efecto**: Decoraciones con tinte naranja cálido, sombras moderadas, fundido sutil.

---

### ❄️ Snow / Ice
```gdscript
biome_tint:        Color(0.85, 0.9, 1.0, 1.0)   # Azul frío
shadow_intensity:  0.25                         # Sombra suave (reflejo de nieve)
shadow_height:     0.2                          # 20% inferior
base_fade:         0.15                         # 15% fundido (más suave)
```
**Efecto**: Tinte azul frío, sombras sutiles (la nieve refleja luz), fundido más pronunciado.

---

### 🌲 Forest / Grass
```gdscript
biome_tint:        Color(0.8, 0.95, 0.8, 1.0)   # Verde natural
shadow_intensity:  0.35                         # Sombra media
shadow_height:     0.22                         # 22% inferior
base_fade:         0.1                          # 10% fundido
```
**Efecto**: Tinte verde natural, sombras medias, fundido moderado para hierba/hojas.

---

### 🏜️ Desert / Sand
```gdscript
biome_tint:        Color(1.0, 0.95, 0.7, 1.0)   # Amarillo arena
shadow_intensity:  0.45                         # Sombra fuerte (sol intenso)
shadow_height:     0.2                          # 20% inferior
base_fade:         0.08                         # 8% fundido (arena dura)
```
**Efecto**: Tinte amarillo cálido, sombras marcadas (sol del desierto), fundido sutil.

---

### 🪨 Cave / Stone
```gdscript
biome_tint:        Color(0.7, 0.7, 0.75, 1.0)   # Gris piedra
shadow_intensity:  0.5                          # Sombra muy oscura
shadow_height:     0.3                          # 30% inferior
base_fade:         0.1                          # 10% fundido
```
**Efecto**: Tinte gris frío, sombras muy marcadas (cueva oscura), fundido moderado.

---

### ⚪ Default (Desconocido)
```gdscript
biome_tint:        Color(1.0, 1.0, 1.0, 1.0)    # Blanco neutro
shadow_intensity:  0.3                          # Sombra ligera
shadow_height:     0.2                          # 20% inferior
base_fade:         0.12                         # 12% fundido
```
**Efecto**: Sin alteración de color, sombra genérica, fundido estándar.

---

## Uso en Código

### Crear Decoración con Shader (Automático)

```gdscript
# El shader se aplica automáticamente cuando se crea la decoración
var decor = DecorFactory.make_decor(
    "res://assets/textures/biomes/Lava/decor/lava_decor1_sheet_f8_256.png",
    5.0,           # FPS
    true,          # use_integration_shader
    "Lava"         # biome_name
)
```

### Desactivar Shader (Opcional)

```gdscript
# Para decoraciones que NO deben fusionarse con el suelo
var decor = DecorFactory.make_decor(
    tex_path,
    5.0,
    false,         # Desactivar shader
    ""
)
```

### Decoración con Estilo Personalizado

```gdscript
var decor = DecorFactory.make_decor_styled(
    tex_path,
    Vector2(1.5, 1.5),              # Escala
    Color(1.0, 0.8, 0.8, 1.0),      # Modulación
    5.0,                            # FPS
    true,                           # use_integration_shader
    "Snow"                          # biome_name
)
```

## Parámetros del Shader

El shader `decor_integration.gdshader` acepta los siguientes uniformes:

| Parámetro | Tipo | Rango | Descripción |
|-----------|------|-------|-------------|
| `biome_tint` | `vec4` (Color) | 0.0-1.0 | Color de modulación para unificar con bioma |
| `shadow_intensity` | `float` | 0.0-1.0 | Intensidad del oscurecimiento (0=sin sombra, 1=negro) |
| `shadow_height` | `float` | 0.0-1.0 | Altura de la zona de sombra (% del sprite desde abajo) |
| `base_fade` | `float` | 0.0-1.0 | Altura de la zona de fundido alpha (% del sprite) |

## Ajuste Manual (Avanzado)

Si necesitas ajustar valores para un bioma específico:

1. Abre `scripts/utils/DecorFactory.gd`
2. Localiza el `match biome_name.to_lower():`
3. Modifica los valores del case correspondiente
4. Guarda y prueba en el juego

### Ejemplo: Aumentar sombra en Desert

```gdscript
"desert", "sand":
    tint_color = Color(1.0, 0.95, 0.7, 1.0)
    shadow_intensity = 0.6   # ← Cambiado de 0.45 a 0.6 (más oscuro)
    shadow_height = 0.25     # ← Cambiado de 0.2 a 0.25 (más alto)
    base_fade = 0.08
```

## Troubleshooting

### Decoraciones sin shader visible
- Verifica que `use_integration_shader=true` en la llamada
- Verifica que el shader existe en `assets/shaders/decor_integration.gdshader`
- Comprueba que `biome_name` coincide con los cases del match (case-insensitive)

### Sombra demasiado fuerte/débil
- Ajusta `shadow_intensity` en el rango 0.0-1.0
- Valores típicos: 0.2 (muy suave) → 0.5 (muy marcada)

### Fundido demasiado brusco/gradual
- Ajusta `base_fade` en el rango 0.0-0.3
- Valores típicos: 0.05 (fundido corto) → 0.2 (fundido largo)

### Color no coincide con bioma
- Ajusta `biome_tint` usando colores RGB normalizados (0.0-1.0)
- Usa el editor de Godot para extraer colores del bioma base

---

## Extensión Futura

### Añadir Nuevo Bioma

1. Abre `DecorFactory.gd`
2. Añade un nuevo case en el match:

```gdscript
"swamp", "marsh":
    tint_color = Color(0.6, 0.8, 0.5, 1.0)  # Verde oscuro pantanoso
    shadow_intensity = 0.4
    shadow_height = 0.3  # Sombras más altas en agua
    base_fade = 0.2      # Fundido largo en superficie líquida
```

3. Guarda y prueba

### Shader Alternativo

Si necesitas efectos más complejos (ej: reflejos, distorsión), puedes:

1. Crear nuevo shader en `assets/shaders/`
2. Modificar `_apply_integration_shader()` para cargar shader diferente según caso
3. Pasar parámetro adicional `shader_variant: String` en `make_decor()`

---

**Última actualización**: 10 de noviembre de 2025  
**Versión**: 1.0
