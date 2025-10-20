# ✨ ARCANE WASTES BIOME TEXTURES

## Especificación
- **Color Base:** `#B56DDC` (Violeta)
- **Tipo:** Ruinas arcanas con símbolos brillantes
- **Estilo:** Cartoon/Funko Pop

## Archivos Requeridos
- `base.png` - Textura base de suelo arcano (512×512, seamless)
- `decor1.png` - Runas flotantes (512×512, seamless)
- `decor2.png` - Cristales arcanos (512×512, seamless)
- `decor3.png` - Energía mágica/auras (512×512, seamless, semi-transparente)

## Instrucciones
1. Crear 4 archivos PNG de 512×512 px
2. `base.png`: suelo violeta mullido, runas claras (#E0B0FF, #C099FF) esparcidas, patrón mágico
3. `decor1.png`: runas brillantes flotando, símbolos mágicos con contorno
4. `decor2.png`: cristales violeta-claros, tonos luminosos
5. `decor3.png`: auras/partículas de energía mágica (con transparencia)

## Tiling
- Seamless/tileable
- Runas deben alinearse con patrón base
- Efecto mágico coherente

## Notas
- Potencial para efecto de luz/brillo (shader)
- decor3.png debe tener canal alpha para partículas

## Importar en Godot
- Filter: Linear
- Mipmaps: ON
- Compress: VRAM Compressed
