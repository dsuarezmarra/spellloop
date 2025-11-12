# 🎨 GUÍA RÁPIDA - GENERAR TEXTURAS CON DALL-E 3

## 📋 WORKFLOW OPTIMIZADO

### 1️⃣ GENERAR SPRITESHEET CON DALL-E 3

Ve al archivo `PROMPT_UNIVERSAL_TEXTURAS_BASE_BIOMAS.md` y copia el prompt del bioma que quieras generar.

**Biomas disponibles:**
- 🌿 **GRASSLAND** (Pradera con flores)
- 🔥 **LAVA** (Volcánico)
- ❄️ **SNOW** (Nieve/hielo)
- 🏜️ **DESERT** (Desierto)
- 🌲 **FOREST** (Bosque oscuro)
- 🔮 **ARCANE WASTES** (Mágico/corrupto)

**IMPORTANTE:** 
- El prompt ahora pide **UN SOLO SPRITESHEET de 8192×1024px** (no 8 imágenes separadas)
- DALL-E generará los 8 frames ya unidos horizontalmente
- Esto evita problemas de consistencia entre frames

### 2️⃣ DESCARGAR Y COLOCAR IMAGEN

1. DALL-E te dará **UNA imagen de 8192×1024px** (o similar)
2. Descárgala a tu PC (ej: `dalle_grassland.png`)
3. NO hace falta moverla a ninguna carpeta todavía

### 3️⃣ PROCESAR SPRITESHEET

Ejecuta el script desde la raíz del proyecto:

```powershell
python utils/process_dalle_spritesheet.py <BIOME_NAME> "<RUTA_IMAGEN_DALLE>"
```

**Ejemplos:**

```powershell
# Grassland
python utils/process_dalle_spritesheet.py grassland "C:\Users\TuUsuario\Downloads\dalle_grassland.png"

# Lava
python utils/process_dalle_spritesheet.py lava "C:\Downloads\dalle_lava.png"

# Snow
python utils/process_dalle_spritesheet.py snow "dalle_snow_spritesheet.png"
```

**El script automáticamente:**
- ✅ Divide el spritesheet en 8 frames de 1024×1024
- ✅ Redimensiona cada frame a 512×512
- ✅ Crea spritesheet final de 4124×512px con padding
- ✅ Guarda en `project/assets/textures/biomes/<BIOME>/base/`
- ✅ Nombra correctamente: `<biome>_base_animated_sheet_f8_512.png`

### 4️⃣ CREAR ARCHIVO .import

Si es la primera vez que generas este bioma, crea el archivo `.import`:

```powershell
# Ejemplo para Grassland
Copy-Item "project/assets/textures/biomes/Snow/base/snow_base_animated_sheet_f8_512.png.import" "project/assets/textures/biomes/Grassland/base/grassland_base_animated_sheet_f8_512.png.import"
```

Luego abre el `.import` y cambia la ruta en la última línea:

```ini
path="res://.godot/imported/grassland_base_animated_sheet_f8_512.png-[UID_ALEATORIO].ctex"
```

**O simplemente copia uno existente y edita:**
- La propiedad `path=` al final del archivo
- Debe apuntar al nombre correcto del PNG

### 5️⃣ PROBAR EN GODOT

1. **Cierra Godot** (si estaba abierto) para forzar re-importación
2. Abre el proyecto
3. Abre la escena de test correspondiente:
   - `test_grassland_decorations.tscn`
   - `test_lava_decorations.tscn`
   - `test_snow_decorations.tscn`
   - etc.
4. Ejecuta la escena (F5)

**VERIFICAR:**
- ✅ Animación suave a 5 FPS
- ✅ Loop perfecto (frame 8 → frame 1)
- ✅ **NO hay costuras visibles entre tiles** (CRÍTICO)
- ✅ Colores correctos para el bioma

---

## 🔴 PROBLEMA: COSTURAS VISIBLES

Si ves líneas/cortes entre tiles (como en tu captura), significa que **DALL-E NO respetó el requisito seamless**.

### Soluciones:

**Opción A) Regenerar con prompt más enfático**
- El prompt ya está actualizado con instrucciones MÁS explícitas
- Incluye sección "🔴 CRITICAL SEAMLESS REQUIREMENTS"
- Intenta generar de nuevo

**Opción B) Usar herramienta externa**
- Photoshop: Filtro → Otro → Desplazamiento (Offset) con wrap
- GIMP: Filtros → Mapa → Hacer mosaico sin costuras
- Procesar manualmente cada frame antes de usar el script

**Opción C) Script Python de seamless** (NO recomendado - genera blur)
- `utils/make_seamless.py` - Crea versiones con blend en bordes
- Degrada calidad visual (bordes borrosos)
- Solo usar como último recurso

---

## 📊 COMPARACIÓN DE MÉTODOS

| Método | Ventajas | Desventajas |
|--------|----------|-------------|
| **DALL-E Spritesheet** | Un solo prompt, consistencia perfecta, sin procesamiento manual | Requiere que DALL-E haga seamless correctamente |
| **DALL-E 8 frames** | Más control por frame | Inconsistencia entre frames, más trabajo |
| **Script seamless.py** | Arregla costuras automáticamente | Genera blur, pérdida de detalle |

---

## 🎯 RECOMENDACIÓN FINAL

1. **USA EL NUEVO PROMPT** (spritesheet único 8192×1024)
2. Si DALL-E no hace seamless perfecto, **regenera con énfasis**:
   - Añade al inicio del prompt: "CRITICAL: Use offset/wrap technique to ensure PERFECT seamless/tileable edges"
   - O menciona explícitamente: "Test each frame by tiling 2×2 before generating"
3. Si sigue fallando, considera usar **Midjourney** o **Stable Diffusion** con modelo específico de tiles

---

## 📁 ARCHIVOS DEL SISTEMA

- `PROMPT_UNIVERSAL_TEXTURAS_BASE_BIOMAS.md` - Prompts optimizados para cada bioma
- `utils/process_dalle_spritesheet.py` - Procesador de spritesheet único
- `utils/create_spritesheet_like_snow.py` - Procesador de 8 frames separados (método antiguo)
- `utils/make_seamless.py` - Conversor seamless (último recurso, genera blur)

---

## 💡 TIPS

- **Seamless es CRÍTICO**: Sin esto, el juego se ve horrible
- **Verifica antes de procesar**: Abre el PNG de DALL-E en un visor y mira los bordes
- **Si dudas**: Regenera con DALL-E antes de procesar
- **Prueba en Godot**: Es el único test definitivo del seamless
