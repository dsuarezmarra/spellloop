# PROMPT PARA GEMINI - TEXTURAS LAVA SEAMLESS/TILEABLE

## Instrucciones principales:
Genera 8 texturas de lava animadas que sean **perfectamente tileable/seamless** (sin costuras visibles cuando se repiten como azulejos).

## Especificaciones técnicas:
- **Resolución**: 1024x1024 píxeles cada frame
- **Cantidad**: 8 frames de animación
- **Formato**: PNG con transparencia (si hay áreas vacías)
- **Estilo**: Top-down 2D isométrico, vista cenital
- **Paleta de colores**: Rojos intensos, naranjas brillantes, amarillos, negros profundos para contraste

## REQUISITO CRÍTICO - Seamless/Tileable:
**MUY IMPORTANTE**: Los bordes izquierdo-derecho y superior-inferior deben coincidir PERFECTAMENTE píxel a píxel para que la textura se pueda repetir sin costuras visibles.

- El borde izquierdo debe ser IDÉNTICO al borde derecho
- El borde superior debe ser IDÉNTICO al borde inferior
- Cuando se coloquen múltiples copias lado a lado, deben verse como una superficie continua sin líneas de separación

## Contenido visual:
1. **Base**: Roca volcánica oscura agrietada con grietas naranjas/rojas brillantes
2. **Lava líquida**: Charcos y ríos de lava fundida en tonos naranjas/amarillos muy brillantes
3. **Detalles**: 
   - Burbujas de lava que estallan
   - Emanaciones de calor (distorsión sutil)
   - Brasas flotantes pequeñas
   - Textura áspera de roca volcánica
4. **Iluminación**: Resplandor naranja/amarillo desde las grietas, creando efecto de luz ambiente cálida

## Animación (8 frames):
- Frame 1: Inicio del ciclo, lava relativamente calmada
- Frames 2-4: Burbujas creciendo, grietas pulsando más brillantes
- Frames 5-7: Explosiones de burbujas, máxima intensidad lumínica
- Frame 8: Retorno al estado inicial (debe conectar perfectamente con Frame 1)

## Estilo artístico:
- Estilo pixel art de alta resolución / hand-painted digital
- Colores saturados y vibrantes
- Alto contraste entre zonas oscuras (roca) y brillantes (lava)
- Efecto de resplandor/bloom en las áreas más calientes
- Vista cenital (desde arriba) para juego 2D

## Verificación:
Después de generar cada frame, verifica mentalmente que:
- Los 100 píxeles del borde izquierdo sean idénticos a los del borde derecho
- Los 100 píxeles del borde superior sean idénticos a los del borde inferior
- Si colocas 4 copias en una cuadrícula 2x2, no se verían líneas de separación

---

## PROMPT SIMPLIFICADO (USA ESTE):

"Generate 8 seamless/tileable lava texture frames (1024x1024px each) for a top-down 2D game. 

CRITICAL: Left edge must match right edge PERFECTLY. Top edge must match bottom edge PERFECTLY. When tiled, no seams should be visible.

Style: Volcanic dark rock base with bright orange/red/yellow lava cracks and pools. Include bubbling lava, glowing fissures, small embers. High contrast, vibrant colors, warm glow.

Animation: 8 frames showing lava bubbling cycle - calm → bubbles growing → bursting → return to calm. Frame 8 must loop seamlessly to Frame 1.

Format: PNG, 1024x1024px, top-down isometric view, pixel art/hand-painted style."
