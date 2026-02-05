# Loopialike - Sistema de Biomas con Dithering Orgánico

## 📁 Estructura del Proyecto

```
project/
├── scripts/
│   └── core/
│       ├── BiomeGeneratorOrganic.gd    ← Generador Voronoi de biomas
│       └── BiomeChunkApplierOrganic.gd ← Aplicador con dithering integrado
├── scenes/                              ← Escenas del juego
├── assets/
│   └── textures/biomes/                 ← Texturas de 6 biomas
├── test_biome_dithering.tscn           ← Test de visualización
└── docs/
    ├── README_BIOMES.md                 ← Documentación de biomas
    ├── SISTEMA_ORGANICO_VORONOI_COMPLETO.md  ← Sistema Voronoi
    ├── TESTING_GUIDE.md                 ← Guía de testing
    └── NEXT_STEPS.md                    ← Próximos pasos
```

## 🎨 Sistema de Biomas

### Tecnología Actual

- **Generación:** Voronoi cellular noise (`FastNoiseLite.TYPE_CELLULAR`)
- **Transiciones:** Dithering Bayer 4×4 integrado en tiles de 64×64 px
- **Chunks:** 15000×15000 px con múltiples biomas por chunk
- **Biomas:** 6 tipos (Grassland, Desert, Snow, Lava, ArcaneWastes, Forest)

### Características

✅ Bordes orgánicos entre biomas usando patrón Bayer  
✅ Multi-bioma por chunk (1-4 biomas típicamente)  
✅ Decoraciones específicas por bioma  
✅ Sistema determinístico con seeds  
✅ Mundo infinito con carga dinámica de chunks  

## 🚀 Cómo Ejecutar

### Escena Principal
```bash
# Desde Godot Editor
F5 o Play button
```

### Test de Dithering
```bash
# Abrir: test_biome_dithering.tscn
# Presionar F5

Controles:
- WASD: Mover cámara
- Q/E: Zoom
- R: Regenerar con nuevo seed
```

## 🔧 Configuración

### Ajustar Dithering

En `scripts/core/BiomeChunkApplierOrganic.gd` línea ~28:

```gdscript
@export var dithering_enabled: bool = true  # Activar/desactivar
@export var debug_mode: bool = true          # Logs detallados
```

Tamaño de tiles (línea ~130):
```gdscript
var sub_tile_size = 64  # Cambiar: 32 (más fino) - 128 (más grueso)
```

### Ajustar Frecuencia de Biomas

En `scripts/core/BiomeGeneratorOrganic.gd` línea ~40:

```gdscript
@export var cellular_frequency: float = 0.00001  # Menor = regiones más grandes
@export var cellular_jitter: float = 1.0         # 1.0 = máxima irregularidad
```

## 📚 Documentación

- **README_BIOMES.md**: Detalles de cada bioma (texturas, decoraciones)
- **SISTEMA_ORGANICO_VORONOI_COMPLETO.md**: Arquitectura del sistema Voronoi
- **TESTING_GUIDE.md**: Cómo hacer testing del sistema
- **NEXT_STEPS.md**: Roadmap y mejoras futuras

## 🐛 Solución de Problemas

### Bordes todavía muy duros
- Reducir `sub_tile_size` a 32 en `BiomeChunkApplierOrganic.gd`
- Aumentar `border_detection_radius` multiplicador

### Performance lento
- Revisar logs de `dithered_count` (debe ser <20% de tiles totales)
- Aumentar `sub_tile_size` a 128
- Desactivar `debug_mode`

### Biomas no se ven
- Verificar que texturas existen en `assets/textures/biomes/[BiomeName]/`
- Verificar que `BiomeGeneratorOrganic` está en el árbol de escena
- Revisar consola para errores de carga

## 🎯 Estado Actual (Nov 2025)

✅ Sistema Voronoi completo y funcional  
✅ Dithering Bayer integrado en aplicación de tiles  
✅ 6 biomas con texturas y decoraciones  
✅ Mundo infinito con chunks dinámicos  
✅ Proyecto limpio (81 archivos obsoletos eliminados)  

## 📝 Próximos Pasos

1. Testing visual del dithering en juego real
2. Ajuste fino de parámetros según feedback
3. Considerar shader blending para transiciones más suaves (opcional)
4. Añadir más biomas si es necesario

## 📞 Soporte

Ver documentación en `/docs` o revisar código en `/scripts/core/Biome*.gd`

---

**Última actualización:** 9 de noviembre de 2025  
**Versión:** 1.0 - Sistema de dithering integrado
