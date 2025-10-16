# 📏 Dimensiones del Sistema Isaac-Style (Sistema de Paredes Optimizado)

## 🏠 Salas (RoomScene)
- **Ancho de Sala**: 1024 píxeles
- **Alto de Sala**: 576 píxeles
- **Zona de Pared**: 64 píxeles (espacio reservado para paredes)
- **Grosor Visual**: 16 píxeles (lo que se ve en pantalla)
- **Grosor Colisión**: 8 píxeles (solo en borde exterior)
- **Área Jugable**: ~960x512 píxeles (accesible para el wizard)

## 🚪 Puertas
- **Tamaño**: 60x60 píxeles
- **Posición**: Centradas en cada lado de la sala
- **Colores**: 
  - Rojo: Puerta bloqueada
  - Verde: Puerta desbloqueada

## 🧙‍♂️ Player (Wizard)
- **Sprite Original**: 500x500 píxeles
- **Sprite Escalado**: 64x64 píxeles (factor: 0.128)
- **Collider**: Radio de 26 píxeles (CircleShape2D)
- **Velocidad**: 200 píxeles/segundo

## 🎯 Sistema de Colisión Optimizado
- **Zona Total Pared**: 64px (espacio reservado)
- **Visual de Pared**: 16px (lo que se renderiza)
- **Colisión**: 8px (solo en el borde exterior)
- **Beneficio**: Wizard puede acercarse mucho al límite
- **Ventaja**: Puede "entrar" ligeramente en la pared para disparar

## 🔧 Configuración Técnica
### RoomScene.gd
```gdscript
const WALL_THICKNESS = 64.0        # Zona reservada para pared
var visual_thickness = 16.0        # Grosor visual
var collision_thickness = 8.0      # Grosor de colisión
var door_size = 60.0               # Tamaño de puertas
```

### Player.gd
```gdscript
var target_size = 64.0
var scale_factor = target_size / original_size  # 0.128
sprite.scale = Vector2(scale_factor, scale_factor)
```

### Player.tscn
```gdscript
[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 26.0
```

## 📊 Comparación Visual vs Colisión

| Elemento | Zona Reservada | Visual | Colisión | Posición Colisión |
|----------|---------------|--------|----------|------------------|
| Pared Superior | 64px | 16px | 8px | Borde superior |
| Pared Inferior | 64px | 16px | 8px | Borde inferior |
| Pared Izquierda | 64px | 16px | 8px | Borde izquierdo |
| Pared Derecha | 64px | 16px | 8px | Borde derecho |

## 🎮 Ventajas del Nuevo Sistema

### Para el Jugador:
- ✅ **Máxima movilidad**: Puede moverse hasta casi el borde absoluto
- ✅ **Mejor puntería**: Puede disparar desde cualquier píxel de la sala
- ✅ **Visual limpio**: Paredes finas y elegantes
- ✅ **Sensación fluida**: No se siente limitado por paredes gruesas

### Para el Gameplay:
- ✅ **Mejor esquiva**: Más espacio para evitar enemigos
- ✅ **Disparos precisos**: Acceso completo a los bordes
- ✅ **Estética Isaac**: Mantiene el estilo de salas definidas
- ✅ **Rendimiento**: Colisiones simples y eficientes

Este sistema permite que el wizard tenga acceso prácticamente completo a toda la sala, manteniendo los límites visuales claros pero sin restricciones de jugabilidad! 🧙‍♂️✨