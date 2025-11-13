# 🎨 PROMPT PROFESIONAL PARA GEMINI - DECORACIONES ANIMADAS GRASSLAND

## 📋 CONTEXTO DEL PROYECTO

Este prompt está diseñado para generar **spritesheets horizontales de 8 frames** para decoraciones animadas del bioma Grassland en el videojuego Spellloop, utilizando Gemini como herramienta de generación de imágenes.

---

## ✅ PROMPT PARA GEMINI (Copiar y Pegar)

```
Create a variation of the attached image for game asset animation sequence.

Image size: 256×256 pixels
Background: transparent
Viewing angle: overhead

[COPIAR LA DESCRIPCIÓN DEL FRAME QUE NECESITES:]

FRAME 1:
Show the image as provided.

FRAME 2:
Tilt elements slightly rightward. Increase color saturation by 10%.

FRAME 3:
Tilt elements more rightward. Increase color saturation by 20%.

FRAME 4:
Tilt elements rightward. Increase color saturation by 50%. Add slight luminosity.

FRAME 5:
Tilt elements rightward. Increase color saturation by 30%.

FRAME 6:
Tilt elements slightly rightward. Increase color saturation by 15%.

FRAME 7:
Minimal rightward tilt. Increase color saturation by 5%.

FRAME 8:
Return to original appearance from frame 1.
```C:\Users\dsuarez1\Downloads\biomes\Death\base

---

## 📋 PROCESO PASO A PASO

### Para generar los 8 frames individuales:

1. **Adjunta tu imagen estática** en Gemini
2. **Copia el prompt** y reemplaza `[N]` con el número de frame (1-8)
3. **Copia la descripción** del frame correspondiente
4. **Genera la imagen**
5. **Guarda como:** `frame_N.png` (donde N = 1-8)
6. **Repite** para los 8 frames

### Ejemplo para Frame 1:
```
Create a variation of the attached image for game asset animation sequence.

Image size: 256×256 pixels
Background: transparent
Viewing angle: overhead

Show the image as provided.
```

### Ejemplo para Frame 4:
```
Create a variation of the attached image for game asset animation sequence.

Image size: 256×256 pixels
Background: transparent
Viewing angle: overhead

Tilt elements rightward. Increase color saturation by 50%. Add slight luminosity.
```

---

## 🎯 CÓMO USAR ESTE PROMPT

### Paso 1: Preparar la Imagen de Referencia
- Adjunta la imagen estática del decor de Grassland que quieres animar
- Asegúrate de que tenga fondo transparente
- Idealmente 256×256 o similar

### Paso 2: Ejecutar en Gemini
1. Abre Gemini (Google AI Studio o interfaz web)
2. Adjunta la imagen de referencia
3. Copia y pega el prompt completo
4. Genera la imagen

### Paso 3: Verificar el Resultado
- Verificar que la imagen resultante sea 2076×256 pixels
- Confirmar que hay exactamente 8 frames con 4px de padding
- Comprobar que el fondo sea transparente
- Validar que la animación tenga sentido visual (progresión suave)

### Paso 4: Generar Spritesheet
Una vez tengas los 8 frames individuales (`frame_1.png` a `frame_8.png`), usa el script de Python del proyecto para combinarlos:

```powershell
python utils/create_base_spritesheet_with_padding.py
```

Esto generará: `grassland_decor1_sheet_f8_256.png`

### Paso 5: Ubicar en el Proyecto
Colocar el archivo en:
```
project/assets/textures/biomes/Grassland/decor/
```

### Paso 6: Importar en Godot
1. Abrir el PNG en Godot FileSystem
2. Click derecho → "Edit Import..."
3. Configurar:
   - **Compress Mode:** VRAM Compressed
   - **Repeat:** Disabled (IMPORTANTE para decoraciones)
   - **Filter:** Enabled
   - **Mipmaps:** Enabled
   - **sRGB:** On
   - **Fix Alpha Border:** On
4. Click "Reimport"

### Paso 7: Probar en Godot
El sistema `AutoFrames.gd` detectará automáticamente el spritesheet por la convención de nombres y lo cargará con:
- 8 frames extraídos automáticamente
- Padding de 4px manejado correctamente
- Animación a 10 FPS por defecto
- Loop seamless habilitado

---

## 🔧 ESPECIFICACIONES TÉCNICAS DEL SISTEMA

### Convención de Nombres
El sistema `AutoFrames.gd` requiere esta estructura exacta:
```
{biome}_decor{N}_sheet_f{frames}_{size}.png
```

Donde:
- `{biome}`: grassland, snow, lava, etc.
- `{N}`: número de decoración (1, 2, 3...)
- `{frames}`: número de frames (8 en este caso)
- `{size}`: tamaño por frame (256)

### Detección Automática de Padding
El sistema detecta automáticamente si el spritesheet tiene padding:
- **Con padding:** (256 + 4) × 8 - 4 = 2076 pixels de ancho
- **Sin padding:** 256 × 8 = 2048 pixels de ancho

### Configuración del Shader
Las decoraciones de Grassland usan estos valores en `DecorFactory`:
- **Tinte del bioma:** Color(0.8, 0.95, 0.8, 1.0) - Verde natural
- **Intensidad de sombra:** 0.35 - Sombra media
- **Altura de sombra:** 0.22 - 22% inferior
- **Fundido base:** 0.1 - 10% fundido

### Integración en el Juego
1. `BiomeChunkApplierOrganic.gd` carga las decoraciones automáticamente
2. `DecorFactory.make_decor()` crea el nodo AnimatedSprite2D
3. `AutoFrames.from_sheet()` extrae los 8 frames del spritesheet
4. El shader de integración se aplica automáticamente
5. La animación se inicia con frame aleatorio (desincronización)
6. Z-index configurado en -99 (encima de base, debajo de entidades)

---

## 📊 TIPOS DE DECORACIONES SUGERIDAS PARA GRASSLAND

### Decor 1: Roca con Musgo y Flores (ACTUAL)
- Roca gris con musgo verde en la parte superior
- Flores amarillas y blancas alrededor
- Animación: flores balanceándose y brillando

### Decor 2: Arbusto de Flores Silvestres
- Arbusto denso con múltiples flores coloridas
- Mezcla de amarillo, naranja, rosa
- Animación: flores abriéndose/cerrándose, sutil movimiento del follaje

### Decor 3: Tronco Caído con Plantas
- Tronco marrón cubierto de musgo
- Setas pequeñas y plantas creciendo en él
- Animación: setas pulsando, plantas meciéndose

### Decor 4: Conjunto de Flores de Pradera
- Grupo denso de flores silvestres altas
- Vista desde arriba mostrando pétalos
- Animación: rotación sutil de pétalos, cambio de brillo

### Decor 5: Piedra Plana con Líquenes
- Piedra plana con líquenes coloridos (verde, amarillo)
- Pequeñas flores brotando alrededor
- Animación: líquenes pulsando suavemente, flores balanceándose

---

## ⚠️ PROBLEMAS COMUNES Y SOLUCIONES

### Problema 1: Gemini No Respeta las Dimensiones Exactas
**Solución:** Especificar múltiples veces las dimensiones críticas. Si aún falla, usar herramientas de post-procesado (Python scripts en `utils/`) para ajustar.

### Problema 2: Frames No Tienen Padding Consistente
**Solución:** El sistema `AutoFrames.gd` tolera variaciones pequeñas (±4 pixels). Si es necesario, usar `create_base_spritesheet_with_padding.py` para normalizar.

### Problema 3: Fondo No Es Transparente
**Solución:** Procesar con Python PIL:
```python
from PIL import Image
img = Image.open("input.png").convert("RGBA")
# Hacer blanco transparente
data = img.getdata()
newData = []
for item in data:
    if item[0] > 250 and item[1] > 250 and item[2] > 250:
        newData.append((255, 255, 255, 0))
    else:
        newData.append(item)
img.putdata(newData)
img.save("output.png")
```

### Problema 4: Animación No Loop Suavemente
**Solución:** Asegurarse de que Frame 8 sea idéntico a Frame 1. Si no, duplicar Frame 1 como Frame 8 manualmente.

### Problema 5: Decoración Se Mueve de Posición Entre Frames
**Solución:** Enfatizar en el prompt "Maintain exact same decoration position" y "no drift". Si persiste, usar Python para alinear frames por centro de masa.

---

## 🎨 VARIACIONES DEL PROMPT

### Para Decoraciones MÁS SUTILES (poco movimiento):
Cambiar las rotaciones a valores más bajos:
- Frame 2: +1 degree
- Frame 3: +3 degrees
- Frame 4: +5 degrees (pico)

### Para Decoraciones MÁS DRAMÁTICAS (mucho movimiento):
Aumentar rotaciones y brillo:
- Frame 2: +10 degrees
- Frame 3: +20 degrees
- Frame 4: +30 degrees, +100% brightness

### Para Decoraciones CON EFECTOS ESPECIALES:
Añadir al prompt de Frame 4:
```
- Add particle effects: small glowing motes floating up
- Add magical sparkles around flowers
- Add subtle color shift to warmer tones
```

---

## 📚 REFERENCIAS DEL PROYECTO

- **Guía de Decoraciones:** `project/DECORACIONES_ANIMADAS_GUIA.md`
- **Configuración de Shader:** `project/DECOR_SHADER_CONFIG.md`
- **Sistema AutoFrames:** `project/scripts/utils/AutoFrames.gd`
- **Factory de Decor:** `project/scripts/utils/DecorFactory.gd`
- **Ejemplo de Test:** `project/test_grassland_decorations.gd`
- **Guía de Grassland Original:** `GRASSLAND_8_FRAMES_INDIVIDUALES.md`

---

## ✅ CHECKLIST PRE-GENERACIÓN

Antes de generar, verificar:

- [ ] Imagen de referencia adjuntada
- [ ] Fondo de referencia es transparente
- [ ] Prompt completo copiado
- [ ] Dimensiones especificadas: 2076×256
- [ ] 8 frames con 4px padding mencionado
- [ ] Animación loop especificada (Frame 8 = Frame 1)
- [ ] Vista top-down enfatizada
- [ ] Transparencia de fondo requerida
- [ ] Estilo artístico mencionado

## ✅ CHECKLIST POST-GENERACIÓN

Después de recibir el resultado:

- [ ] Verificar dimensiones: 2076×256 pixels
- [ ] Contar frames: exactamente 8
- [ ] Comprobar padding: 4px entre frames
- [ ] Validar transparencia de fondo
- [ ] Revisar progresión de animación (suave, sin saltos)
- [ ] Verificar que Frame 8 ≈ Frame 1 (loop)
- [ ] Nombrar correctamente: `grassland_decor{N}_sheet_f8_256.png`
- [ ] Colocar en: `project/assets/textures/biomes/Grassland/decor/`
- [ ] Importar en Godot con configuración correcta
- [ ] Probar en escena de test

---

## 🚀 PRÓXIMOS PASOS

Una vez generados múltiples decorados animados:

1. **Generar 3-5 decoraciones variadas** (rocas, arbustos, flores, troncos, etc.)
2. **Probar en `test_grassland_decorations.tscn`** para verificar visualización
3. **Ajustar shader si es necesario** (tinte, sombras, fundido)
4. **Integrar en generación procedural** de chunks del juego
5. **Replicar proceso para otros biomas** (Snow, Lava, Desert, Forest, ArcaneWastes)

---

**Fecha de Creación:** 13 de noviembre de 2025
**Versión:** 1.0
**Autor:** GitHub Copilot (basado en especificaciones del proyecto Spellloop)
