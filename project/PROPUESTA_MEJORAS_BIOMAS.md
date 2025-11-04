# 🎨 Propuesta de Mejoras para Sistema de Biomas

## 📊 Análisis de la Situación Actual

### Configuración Actual
```
Chunk Size: 5760×3240 px (ratio 16:9)
Base Texture: 1920×1080 px
Sprites por chunk: 9 (grid 3×3)
Escala base: 1.00 (sin zoom)
Decoraciones: 9 instancias, escala fija (3.75, 2.11)
```

### Problemas Identificados
1. ❌ **Chunks demasiado grandes** → Menos chunks visibles, más memoria por chunk
2. ❌ **Texturas muy pequeñas para el chunk** → Se estiran/repiten mucho
3. ❌ **Transiciones bruscas** → Sin blending entre biomas
4. ❌ **Decoraciones uniformes** → Sin variación de tamaño/rotación
5. ❌ **Patrón visible de 3×3** → Se nota la cuadrícula

---

## 🎯 MEJORA 1: Optimizar Tamaños de Chunks y Texturas

### Propuesta
```gdscript
# Tamaño de chunk MÁS PEQUEÑO (más manejable)
export var chunk_size := Vector2(3840, 2160)  # 2x viewport (16:9)

# Texturas base MÁS GRANDES (menos repetición)
Tamaño recomendado: 2048×2048 px (potencia de 2)

# Grid de sprites: 2×2 en lugar de 3×3
Sprites por chunk: 4 (más simples de manejar)
Tamaño por sprite: 1920×1080 (match viewport)
```

### Ventajas
✅ Chunks más pequeños = mejor performance
✅ Más chunks visibles a la vez = mundo más "vivo"
✅ Texturas más grandes = menos repetición
✅ Menos sprites = menos draw calls

### Implementación
```gdscript
# En InfiniteWorldManager.gd
export var chunk_size := Vector2(3840, 2160)  # Reducir de 5760×3240
export var sprites_per_chunk := Vector2i(2, 2)  # Cambiar de 3×3 a 2×2

# En BiomeChunkApplier.gd
const SPRITE_SIZE = Vector2(1920, 1080)  # Tamaño por sprite
const SPRITES_PER_ROW = 2
const SPRITES_PER_COL = 2
```

---

## 🎯 MEJORA 2: Sistema de Dithering en Bordes

### Concepto
Aplicar un patrón de dithering en los bordes de cada chunk para suavizar la transición entre biomas.

### Implementación Propuesta

#### Opción A: Shader de Dithering
```gdscript
shader_type canvas_item;

uniform sampler2D dither_pattern; // Texture de 8×8 o 16×16
uniform float border_width = 100.0; // Píxeles de borde para dither
uniform vec4 chunk_bounds; // (min_x, min_y, max_x, max_y)

void fragment() {
    vec2 pos = UV * chunk_bounds.zw;
    
    // Calcular distancia al borde más cercano
    float dist_to_edge = min(
        min(pos.x - chunk_bounds.x, chunk_bounds.z - pos.x),
        min(pos.y - chunk_bounds.y, chunk_bounds.w - pos.y)
    );
    
    // Aplicar dithering cerca del borde
    if (dist_to_edge < border_width) {
        float alpha = dist_to_edge / border_width;
        
        // Sample dither pattern
        vec2 dither_uv = fract(pos / 8.0);
        float dither_value = texture(dither_pattern, dither_uv).r;
        
        // Aplicar dithering al alpha
        if (alpha < dither_value) {
            COLOR.a *= alpha;
        }
    }
}
```

#### Opción B: Blending por Software (Más Simple)
```gdscript
# En BiomeChunkApplier.gd

func _apply_edge_blending(chunk_container: Node2D, chunk_pos: Vector2i):
    # Crear máscara de gradiente en los bordes
    var mask = Image.create(int(chunk_size.x), int(chunk_size.y), false, Image.FORMAT_RGBA8)
    
    var border_width = 200  # Píxeles de transición
    
    for y in range(mask.get_height()):
        for x in range(mask.get_width()):
            var dist_to_edge = _distance_to_edge(x, y, mask.get_width(), mask.get_height())
            
            if dist_to_edge < border_width:
                # Alpha basado en distancia
                var alpha = dist_to_edge / border_width
                
                # Aplicar dithering pattern
                var dither = _get_dither_value(x, y)
                if alpha < dither:
                    alpha = 0.0
                
                mask.set_pixel(x, y, Color(1, 1, 1, alpha))
            else:
                mask.set_pixel(x, y, Color.WHITE)
    
    # Aplicar máscara a los sprites del chunk
    var mask_texture = ImageTexture.create_from_image(mask)
    for sprite in chunk_container.get_children():
        if sprite is Sprite2D:
            sprite.material = _create_mask_material(mask_texture)

func _get_dither_value(x: int, y: int) -> float:
    # Patrón Bayer 8×8
    const BAYER_MATRIX = [
        [0, 32, 8, 40, 2, 34, 10, 42],
        [48, 16, 56, 24, 50, 18, 58, 26],
        [12, 44, 4, 36, 14, 46, 6, 38],
        [60, 28, 52, 20, 62, 30, 54, 22],
        [3, 35, 11, 43, 1, 33, 9, 41],
        [51, 19, 59, 27, 49, 17, 57, 25],
        [15, 47, 7, 39, 13, 45, 5, 37],
        [63, 31, 55, 23, 61, 29, 53, 21]
    ]
    
    var bayer_x = x % 8
    var bayer_y = y % 8
    return BAYER_MATRIX[bayer_y][bayer_x] / 64.0

func _distance_to_edge(x: int, y: int, width: int, height: int) -> float:
    return min(
        min(x, width - x),
        min(y, height - y)
    )
```

#### Opción C: Overlap de Chunks (MÁS SIMPLE)
```gdscript
# Hacer que los chunks se solapen ligeramente
export var chunk_overlap := 200  # Píxeles de overlap

# Al generar chunks
var chunk_actual_size = chunk_size + Vector2(chunk_overlap * 2, chunk_overlap * 2)
var chunk_offset = Vector2(chunk_overlap, chunk_overlap)

# Aplicar alpha gradient en el área de overlap
```

---

## 🎯 MEJORA 3: Decoraciones Variables

### Propuesta
```gdscript
# En BiomeChunkApplier.gd

func _add_decorations(chunk_container: Node2D, biome_config: Dictionary, chunk_seed: int):
    var decor_list = biome_config.get("decorations", [])
    if decor_list.is_empty():
        return
    
    var rng = RandomNumberGenerator.new()
    rng.seed = chunk_seed
    
    # VARIACIÓN 1: Diferentes densidades por bioma
    var density = biome_config.get("decor_density", 1.0)  # 0.5 a 2.0
    var num_decors = int(9 * density)
    
    for i in range(num_decors):
        var decor_path = decor_list[rng.randi() % decor_list.size()]
        var decor_tex = load(decor_path) as Texture2D
        if not decor_tex:
            continue
        
        var sprite = Sprite2D.new()
        sprite.texture = decor_tex
        
        # VARIACIÓN 2: Posición más orgánica (no grid)
        var rand_x = rng.randf_range(0, chunk_size.x)
        var rand_y = rng.randf_range(0, chunk_size.y)
        sprite.position = Vector2(rand_x, rand_y)
        
        # VARIACIÓN 3: Escala variable por tipo de objeto
        var base_scale = Vector2(
            chunk_size.x / (SPRITE_SIZE.x * SPRITES_PER_ROW),
            chunk_size.y / (SPRITE_SIZE.y * SPRITES_PER_COL)
        )
        
        # Diferentes escalas según tipo
        var scale_multiplier = _get_decor_scale_multiplier(decor_path, rng)
        sprite.scale = base_scale * scale_multiplier
        
        # VARIACIÓN 4: Rotación aleatoria
        if _should_rotate_decor(decor_path):
            sprite.rotation = rng.randf_range(0, TAU)
        
        # VARIACIÓN 5: Modulate para variación de color
        sprite.modulate = Color(
            rng.randf_range(0.9, 1.1),
            rng.randf_range(0.9, 1.1),
            rng.randf_range(0.9, 1.1),
            1.0
        )
        
        chunk_container.add_child(sprite)

func _get_decor_scale_multiplier(decor_path: String, rng: RandomNumberGenerator) -> float:
    # Árboles: 0.8 - 1.2
    if "tree" in decor_path:
        return rng.randf_range(0.8, 1.2)
    
    # Rocas: 0.5 - 1.5
    if "rock" in decor_path or "stone" in decor_path:
        return rng.randf_range(0.5, 1.5)
    
    # Arbustos/plantas: 0.6 - 1.0
    if "bush" in decor_path or "plant" in decor_path:
        return rng.randf_range(0.6, 1.0)
    
    # Default
    return rng.randf_range(0.8, 1.2)

func _should_rotate_decor(decor_path: String) -> bool:
    # Rocas y algunos objetos sí, árboles no
    return "rock" in decor_path or "crystal" in decor_path
```

---

## 🎯 MEJORA 4: Texturas Base Mejoradas

### Recomendaciones para las Texturas PNG

#### Tamaño Recomendado
```
2048×2048 px (potencia de 2)
- Mejor para GPU
- Sin repetición visible
- 4 sprites por chunk (1024×1024 cada uno)
```

#### Contenido de las Texturas
```
✅ Variación de colores (no color plano)
✅ Noise/grano sutil
✅ Detalles pequeños (piedras, hierba)
✅ Seamless tiles (bordes sin costuras)
✅ Capas de detalle (base + overlay)
```

#### Ejemplo de Generación
```python
# generate_improved_textures.py
from PIL import Image, ImageFilter, ImageDraw
import random
import numpy as np

def generate_biome_texture(biome_name, base_color, size=2048):
    img = Image.new('RGB', (size, size), base_color)
    pixels = img.load()
    
    # Añadir noise
    for y in range(size):
        for x in range(size):
            noise = random.randint(-20, 20)
            r, g, b = pixels[x, y]
            pixels[x, y] = (
                max(0, min(255, r + noise)),
                max(0, min(255, g + noise)),
                max(0, min(255, b + noise))
            )
    
    # Aplicar blur sutil
    img = img.filter(ImageFilter.GaussianBlur(radius=1))
    
    # Añadir detalles orgánicos
    draw = ImageDraw.Draw(img)
    for _ in range(500):
        x = random.randint(0, size)
        y = random.randint(0, size)
        r = random.randint(2, 8)
        color = (
            base_color[0] + random.randint(-30, 30),
            base_color[1] + random.randint(-30, 30),
            base_color[2] + random.randint(-30, 30)
        )
        draw.ellipse([x-r, y-r, x+r, y+r], fill=color)
    
    img.save(f'biomes/{biome_name}/base_2048.png')

# Generar para cada bioma
generate_biome_texture('Grassland', (100, 180, 80))
generate_biome_texture('Forest', (60, 120, 60))
generate_biome_texture('Snow', (240, 250, 255))
# etc...
```

---

## 🎯 MEJORA 5: Configuración por Bioma

### Archivo JSON Mejorado
```json
{
  "Grassland": {
    "base_texture": "res://assets/textures/biomes/Grassland/base_2048.png",
    "decorations": [
      "res://assets/textures/biomes/Grassland/decor_flower_01.png",
      "res://assets/textures/biomes/Grassland/decor_rock_01.png",
      "res://assets/textures/biomes/Grassland/decor_bush_01.png"
    ],
    "decor_density": 1.2,
    "decor_scale_range": [0.6, 1.4],
    "color_variation": 0.1,
    "edge_blend_width": 150
  },
  "Forest": {
    "base_texture": "res://assets/textures/biomes/Forest/base_2048.png",
    "decorations": [
      "res://assets/textures/biomes/Forest/decor_tree_01.png",
      "res://assets/textures/biomes/Forest/decor_tree_02.png",
      "res://assets/textures/biomes/Forest/decor_rock_01.png"
    ],
    "decor_density": 1.5,
    "decor_scale_range": [0.8, 1.5],
    "color_variation": 0.05,
    "edge_blend_width": 200
  }
}
```

---

## 📋 Plan de Implementación

### Fase 1: Optimización Básica (30 min)
1. ✅ Reducir chunk_size a 3840×2160
2. ✅ Cambiar grid a 2×2 sprites
3. ✅ Actualizar configuración en InfiniteWorldManager

### Fase 2: Texturas Mejoradas (1 hora)
1. ✅ Generar texturas 2048×2048 para cada bioma
2. ✅ Actualizar paths en biomes_config.json
3. ✅ Ajustar escalas en BiomeChunkApplier

### Fase 3: Decoraciones Variables (45 min)
1. ✅ Implementar posicionamiento no-grid
2. ✅ Añadir variación de escala
3. ✅ Añadir rotación aleatoria
4. ✅ Añadir color variation

### Fase 4: Dithering (1 hora)
1. ✅ Implementar Opción B (software blending)
2. ✅ Crear patrón Bayer 8×8
3. ✅ Aplicar a bordes de chunks
4. ✅ Ajustar border_width por bioma

---

## 🎨 Resultado Esperado

### Antes
```
❌ Chunks grandes (5760×3240)
❌ Texturas pequeñas (1920×1080)
❌ Grid 3×3 visible
❌ Bordes duros entre chunks
❌ Decoraciones uniformes
```

### Después
```
✅ Chunks optimizados (3840×2160)
✅ Texturas grandes (2048×2048)
✅ Grid 2×2 menos visible
✅ Bordes con dithering suave
✅ Decoraciones orgánicas y variadas
✅ Color variation sutil
✅ Mejor performance
```

---

## 🔧 Código de Ejemplo Completo

Ver archivos adjuntos:
- `BiomeChunkApplier_IMPROVED.gd`
- `InfiniteWorldManager_IMPROVED.gd`
- `generate_improved_textures.py`
- `edge_dithering_shader.gdshader`

