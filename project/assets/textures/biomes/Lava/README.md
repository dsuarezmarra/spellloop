# 🌋 LAVA BIOME TEXTURES

## Especificación
- **Color Base:** `#F55A33` (Rojo-naranja)
- **Tipo:** Lava con grietas oscuras
- **Estilo:** Cartoon/Funko Pop

## Archivos Requeridos
- `base.png` - Textura base de lava (512×512, seamless)
- `decor1.png` - Charcos de lava hirviendo (512×512, seamless)
- `decor2.png` - Rocas de lava congelada (512×512, seamless)
- `decor3.png` - Vapor/humo (512×512, seamless, semi-transparente)

## Instrucciones
1. Crear 4 archivos PNG de 512×512 px
2. `base.png`: grietas entrelazadas negro oscuro (#2A1A0A), zonas naranja incandescente
3. `decor1.png`: charcos activos de lava, tonos naranja-amarillo (#FF9500, #FFCC00)
4. `decor2.png`: rocas oscuras de lava solidificada
5. `decor3.png`: vapor/humo subiendo (con transparencia ~60%)

## Tiling
- Seamless/tileable
- Líneas de grietas deben conectar perfectamente entre tiles
- Efecto de temperatura visual

## Notas
- Potencial para animación (shader o overlay pulsante)
- decor3.png debe tener canal alpha

## Importar en Godot
- Filter: Linear
- Mipmaps: ON
- Compress: VRAM Compressed
