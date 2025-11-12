# TODO: Decoraciones Grassland

## Estado actual
✅ Spritesheet de textura base generado: `grassland_base_animated_sheet_f8_512.png`
✅ Escena de test creada: `test_grassland_decorations.tscn`
✅ Script de test funcional (solo muestra el mosaico base)

## Pendiente
⏳ **Decoraciones animadas** - Frames individuales no disponibles aún

### Cuando estén disponibles los frames de decoraciones:
1. Colocar los frames en: `project/assets/textures/biomes/Grassland/decor/`
2. Generar spritesheets con el script de Python
3. Actualizar `test_grassland_decorations.gd` para incluir las decoraciones
   - Seguir el patrón de `test_lava_decorations.gd` o `test_snow_decorations.gd`
   - Usar `DecorFactory.make_decor()` para crear las decoraciones
   - Configurar biome_name como "Grassland" para el shader apropiado

### Estructura esperada de decoraciones:
```
Grassland/decor/
  ├── grassland_decor1_sheet_f8_256.png
  ├── grassland_decor2_sheet_f8_256.png
  ├── grassland_decor3_sheet_f8_256.png
  └── ... (más decoraciones según disponibilidad)
```

### Shader de integración configurado:
El `DecorFactory` ya tiene configuración para Grassland:
- Tinte: Verde natural (0.8, 0.95, 0.8)
- Sombra: Intensidad 0.35
- Fundido base: 0.1
