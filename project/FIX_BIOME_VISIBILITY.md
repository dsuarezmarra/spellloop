# 🔧 FIX: Biome Texture Visibility Issue (Commit cb42d02)

## Problema Identificado

**Síntoma**: Las texturas de biomas se estaban cargando correctamente (confirmado por logs), pero **NO eran visibles** en el juego. En su lugar se veían los símbolos morados antiguos.

**Root Cause**: Dos problemas de capas/layers en Godot 4:

1. **`CanvasLayer` con `layer = -10`**: 
   - Los biomas se renderizaban en la capa -10 (negativa)
   - Esto es válido, pero causaba que quedaran "detrás" del sistema de capas

2. **`visible_layers = 1` en nodos de WorldRoot**:
   - `visible_layers` es una máscara de capas visibles (bits)
   - Valor `1` = `0b0000001` = solo muestra la capa 0
   - Valor `-1` = `0b1111111...` = muestra TODAS las capas
   - Los nodos WorldRoot, ChunksRoot, EnemiesRoot, PickupsRoot tenían `visible_layers = 1`
   - Esto bloqueaba la visualización de cualquier capa que no fuera la 0

## Solución Aplicada

### Cambio 1: BiomeChunkApplier.gd
```gdscript
# ANTES (INCORRECTO):
canvas_layer.layer = -10  # Detrás de todo

# DESPUÉS (CORRECTO):
canvas_layer.layer = 0    # Capa visible normal
```

**Razón**: Cambiar a la capa 0 asegura que sea visible con los `visible_layers` por defecto.

### Cambio 2: SpellloopMain.tscn
```tscn
# ANTES (INCORRECTO):
visible_layers = 1   # Solo muestra capa 0

# DESPUÉS (CORRECTO):
visible_layers = -1  # Muestra TODAS las capas
```

**Nodos afectados**:
- WorldRoot
- EnemiesRoot  
- ChunksRoot
- PickupsRoot

**Razón**: `-1` es una máscara que activa todos los bits, mostrando todas las capas (0-31).

## Verificación

Después de estos cambios:
1. **Biomas visibles**: Las texturas de ArcaneWastes, Grassland, Snow, Lava, Forest deben aparecer
2. **Movimiento correcto**: Los chunks deben moverse suavemente cuando se mueve el personaje con WASD
3. **Sin símbolos morados**: No debe haberUI vieja visible como fondo

## Logs Esperados

```
[BiomeChunkApplier] Chunk (0, 0) → Bioma: ArcaneWastes (seed: 516917320)
✓ Base aplicada: res://assets/textures/biomes/ArcaneWastes/base.png
✓ Decor 1/2/3...
✓ Bioma 'ArcaneWastes' aplicado a chunk (0, 0)
```

Y los biomas DEBEN ser visibles en la pantalla.

## Arquitectura Resultante

```
SpellloopMain (Node2D)
├─ UI (CanvasLayer, layer=default)
└─ WorldRoot (Node2D, visible_layers=-1) ← MUESTRA TODAS LAS CAPAS
   ├─ ChunksRoot (visible_layers=-1)
   │  └─ Chunk(0, 0) (Node2D)
   │     └─ BiomeLayer (CanvasLayer, layer=0) ← VISIBLE
   │        ├─ BiomeBase (Sprite2D, z_index=0)
   │        └─ BiomeDecor1/2/3 (Sprite2D, z_index=1,2,3)
   ├─ EnemiesRoot (visible_layers=-1)
   └─ PickupsRoot (visible_layers=-1)
```

## Notas Técnicas

- **GDScript 4.x Godot**: `visible_layers` es una propiedad que controla qué capas (0-31) son visibles
- **CanvasLayer `layer`**: Define a qué capa pertenece el CanvasLayer (-128 a 127)
- **Rendering Order**: Los elementos de capas negativas renderean detrás; 0 es normal; positivas delante
- **Máscara binaria**: `visible_layers = 1` = solo bit 0 = capa 0; `-1` = todos los bits = todas las capas

## Commit

```
Commit: cb42d02
Message: Fix: Cambiar layer de biomas a 0 y visible_layers a -1 para mostrar todas las capas
Files:
  - scripts/core/BiomeChunkApplier.gd (layer = -10 → layer = 0)
  - scenes/SpellloopMain.tscn (visible_layers = 1 → visible_layers = -1 en 4 nodos)
```

## Testing

✅ Reiniciar Godot y cargar SpellloopMain
✅ Presionar Play (F5)
✅ Mover jugador con WASD
✅ Verificar que los biomas cambian (colores diferentes por región)
✅ Verificar que NO hay símbolos morados visibles
✅ Verificar que los chunks se mueven suavemente
