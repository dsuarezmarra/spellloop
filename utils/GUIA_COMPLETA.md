# 🎨 HERRAMIENTAS DE TEXTURAS - GUÍA COMPLETA

## 📂 Ubicación
```
C:\Users\dsuarez1\git\spellloop\utils\
```

## 🛠️ Herramientas Disponibles

### 1. **resample_biome_textures.py** ⭐ RECOMENDADA

**Descripción**: Script Python profesional que redimensiona automáticamente todas las texturas.

**Características**:
- ✅ Autodetecta "base" y "decor" en nombres de archivos
- ✅ Redimensiona automáticamente a los tamaños correctos
- ✅ Base: 1920×1080 PNG
- ✅ Decor: 256×256 PNG
- ✅ Alta calidad con interpolación LANCZOS
- ✅ Reportes detallados del progreso
- ✅ Reemplaza archivos originales automáticamente

**Requisitos**:
- Python 3.7 o superior
- Librería Pillow (`pip install Pillow`)

**Uso**:
```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
python resample_biome_textures.py
```

---

### 2. **convert_textures_to_png.ps1** ✅ FUNCIONA

**Descripción**: Script PowerShell nativo que convierte todas las texturas a PNG.

**Características**:
- ✅ Convierte JPG → PNG
- ✅ Convierte BMP → PNG
- ✅ Omite archivos que ya son PNG
- ✅ No redimensiona (mantiene tamaño original)
- ✅ Sin requisitos externos
- ✅ Funciona perfectamente

**Uso**:
```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\convert_textures_to_png.ps1
```

**Salida Esperada**:
```
🔍 Encontradas 24 imágenes
✅ Convertidas: 20 imágenes
⏭️  Omitidas: 2 imágenes (ya son PNG)
❌ Errores: 0 imágenes
✨ ¡Proceso completado exitosamente!
```

---

### 3. **resample_biome_textures_advanced.ps1** ⚠️ EN DESARROLLO

**Descripción**: Script PowerShell que intenta redimensionar usando .NET nativo.

**Estado**: 
- ⚠️ Tiene problemas con GDI+ al guardar algunos PNG
- ❌ No se recomienda en este momento

**Nota**: Si necesitas redimensionar sin Python, espera a que se corrija este script o instala Python.

---

### 4. **resample_biome_textures.bat**

**Descripción**: Script ejecutable Windows para el script Python.

**Características**:
- Detecta si Python está instalado
- Instala Pillow automáticamente si falta
- Interfaz gráfica amigable

**Uso**:
- Doble clic en el archivo
- O desde terminal: `resample_biome_textures.bat`

---

## 📊 Estado Actual del Proyecto

### Texturas Actuales
```
Ubicación: C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes\

Total de texturas: 24 archivos PNG
- 6 biomas
- 4 archivos por bioma (1 base + 3 decor)

Biomas:
  ✅ Grassland (4 archivos)
  ✅ Desert (4 archivos)
  ✅ Snow (4 archivos)
  ✅ Lava (4 archivos)
  ✅ ArcaneWastes (4 archivos)
  ✅ Forest (4 archivos)
```

### Tamaños Detectados
```
Grassland:
  - base.png: 1920×1024 (debería ser 1920×1080)
  - decor1.png: 1024×1024 (debería ser 256×256)
  - decor2.png: 512×512 (debería ser 256×256)
  - decor3.png: 512×512 (debería ser 256×256)

Desert: Similar
Snow: Similar
Lava: Similar
ArcaneWastes: Similar
Forest:
  - base.png: 1920×1080 ✅ (correcto)
  - decor1.png: 1024×1024 (debería ser 256×256)
  - decor2.png: 1024×1024 (debería ser 256×256)
  - decor3.png: 1024×1024 (debería ser 256×256)
```

---

## 🚀 PLAN DE ACCIÓN RECOMENDADO

### Paso 1: Instalar Python (Si no lo tienes)

1. Ve a https://www.python.org/downloads/
2. Descarga **Python 3.11** o superior
3. Ejecuta el instalador
4. ⚠️ **IMPORTANTE**: Marca la casilla "Add Python to PATH"
5. Completa la instalación
6. Abre una terminal nueva y verifica:
   ```powershell
   python --version
   ```

### Paso 2: Instalar Pillow

```powershell
pip install Pillow
```

### Paso 3: Ejecutar el Resampler

```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
python resample_biome_textures.py
```

### Paso 4: Verificar Resultados

```powershell
cd C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes

# Verificar que todas son PNG
Get-ChildItem -Recurse -Filter "*.png" | Measure-Object
# Debe mostrar: 24 archivos

# Verificar que no quedan JPG
Get-ChildItem -Recurse -Filter "*.jpg" | Measure-Object
# Debe mostrar: 0 archivos

# Ver tamaños
Get-ChildItem -Recurse | Format-Table Name, Length
```

### Paso 5: Recargar Godot

1. Cierra el Editor de Godot
2. Abre Godot nuevamente
3. Carga tu proyecto
4. Espera a que Godot reimporte las texturas
5. Verifica en el juego que las texturas se ven correctamente

---

## 📝 Alternativa Si No Quieres Instalar Python

Si **no quieres instalar Python**, puedes usar:

```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\convert_textures_to_png.ps1
```

**⚠️ Limitación**: Solo convierte a PNG, pero NO redimensiona automáticamente.

En ese caso, necesitarías redimensionar manualmente en Godot o usar otra herramienta como:
- Photoshop
- GIMP (gratis)
- ImageMagick
- Online image resizer

---

## 🔧 Configuración Avanzada

### Cambiar Tamaños en el Script Python

Edita `resample_biome_textures.py` y busca:

```python
TEXTURE_SIZES = {
    "base": (1920, 1080),      # ← Cambiar aquí
    "decor": (256, 256)        # ← Cambiar aquí
}
```

### Cambiar Ruta de Biomas

```python
# Por defecto detecta automáticamente:
default_path = r"C:\Users\dsuarez1\git\spellloop\project\assets\textures\biomes"

# O pasar por argumento:
python resample_biome_textures.py "C:/ruta/personalizada/biomes"
```

---

## 📧 Soporte

Si tienes problemas:

1. **Error "Python no encontrado"**: 
   - Instala Python desde python.org
   - Marca "Add Python to PATH"
   - Reinicia la terminal

2. **Error "Pillow no instalado"**:
   - `pip install Pillow`

3. **Archivos no se procesan**:
   - Verifica que están en `assets/textures/biomes/biome_name/`
   - Verifica que tienen "base" o "decor" en el nombre
   - Verifica que están en JPG, PNG, BMP o TIFF

4. **Error GDI+ en PowerShell**:
   - Usa el script Python en su lugar
   - O contacta al equipo de desarrollo

---

## ✅ Checklist Final

- [ ] He instalado Python 3.7+
- [ ] He instalado Pillow (`pip install Pillow`)
- [ ] He ejecutado `python resample_biome_textures.py`
- [ ] Todas las imágenes están en PNG
- [ ] He recargar Godot Editor
- [ ] Las texturas se ven en el juego

---

**¡Listo!** Las texturas deberían estar redimensionadas y funcionando correctamente en Godot.
