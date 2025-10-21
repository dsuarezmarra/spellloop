# 🎨 Utilidades de Texturas de Biomas

Herramientas para redimensionar y convertir automáticamente las texturas de biomas del proyecto Spellloop.

## 📦 Archivos Disponibles

### 1. **resample_biome_textures.py** (RECOMENDADO)
- ✅ **La mejor opción** si tienes Python instalado
- Autodetecta tamaños y redimensiona con alta calidad
- Redimensiona "base" → 1920×1080
- Redimensiona "decor" → 256×256
- Convierte a PNG
- **Requisitos**: Python 3.7+, Pillow

### 2. **resample_biome_textures_advanced.ps1**
- Script PowerShell nativo de Windows
- Intenta redimensionar con .NET
- ⚠️ Puede fallar con algunos archivos PNG debido a limitaciones de GDI+
- No requiere instalación externa
- **Para usar**: `.\resample_biome_textures_advanced.ps1`

### 3. **convert_textures_to_png.ps1**
- Script PowerShell nativo
- ✅ **Funciona correctamente** (convertido a PNG solo, sin redimensionar)
- Convierte JPG/JPEG/BMP → PNG
- Mantiene el tamaño original
- **Para usar**: `.\convert_textures_to_png.ps1`

### 4. **resample_biome_textures.bat**
- Ejecutable Windows para el script Python
- Detecta automáticamente si Pillow está instalado
- Instala Pillow automáticamente si falta
- **Para usar**: Haz doble clic o ejecuta desde terminal

## 🚀 Cómo Usar

### Opción A: Python (RECOMENDADO)

```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
python resample_biome_textures.py
```

**Primero instala Python:**
- Ve a https://www.python.org/downloads/
- Descarga Python 3.11 o superior
- **IMPORTANTE**: Marca "Add Python to PATH" durante la instalación
- Reinicia la terminal después de instalar

**Luego instala Pillow:**
```powershell
pip install Pillow
```

### Opción B: PowerShell (Sin dependencias, solo conversión a PNG)

```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\convert_textures_to_png.ps1
```

**⚠️ NOTA**: Este solo convierte a PNG, no redimensiona.

### Opción C: PowerShell Avanzado (Requiere reparación)

```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\resample_biome_textures_advanced.ps1
```

**⚠️ ADVERTENCIA**: Actualmente tiene problemas con algunos PNG debido a limitaciones de .NET/GDI+.

## 📋 Resumen de Funcionalidades

| Herramienta | Autodetecta | Redimensiona | Convierte PNG | Requisitos |
|---|---|---|---|---|
| **Python** | ✅ Sí | ✅ Sí | ✅ Sí | Python 3.7+, Pillow |
| **Advanced PS1** | ✅ Sí | ⚠️ Parcial* | ✅ Sí | Ninguno |
| **Convert PS1** | ✅ Sí | ❌ No | ✅ Sí | Ninguno |
| **Batch** | ✅ Sí | ✅ Sí | ✅ Sí | Python 3.7+, Pillow |

*Problemas conocidos con algunos PNG

## 🎯 Tamaños Aplicados

### Para archivos con "base" en el nombre
- **Tamaño**: 1920×1080 píxeles
- **Formato**: PNG
- **Uso**: Textura base de terreno

### Para archivos con "decor" en el nombre
- **Tamaño**: 256×256 píxeles
- **Formato**: PNG
- **Uso**: Decoraciones superpuestas

## ✅ Verificación del Resultado

Después de ejecutar cualquier herramienta:

1. Verifica que las imágenes están en PNG:
   ```powershell
   Get-ChildItem "assets\textures\biomes" -Recurse -Filter "*.jpg" | Measure-Object
   # Debe mostrar 0 archivos JPG
   ```

2. Verifica que hay archivos PNG:
   ```powershell
   Get-ChildItem "assets\textures\biomes" -Recurse -Filter "*.png" | Measure-Object
   # Debe mostrar 24 (o el número total de texturas)
   ```

3. Abre Godot Editor y recarga el proyecto

## 🐛 Solución de Problemas

### "Python no está instalado"
1. Descarga desde https://www.python.org/downloads/
2. Marca "Add Python to PATH" en el instalador
3. Reinicia la terminal

### "Pillow no está instalado"
```powershell
pip install Pillow
```

### "Acceso denegado" al ejecutar .ps1
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\resample_biome_textures.ps1
```

### Las imágenes no se están procesando
- ¿Están en `assets/textures/biomes/`?
- ¿Tienen "base" o "decor" en el nombre?
- ¿Están en formato JPG/PNG/BMP?

### Error "A generic error occurred in GDI+"
- Usa el script Python en su lugar
- O usa `convert_textures_to_png.ps1` (solo conversión)

## 📝 Recomendación Final

**Para mejores resultados:**
1. Instala Python 3.11+ en tu sistema
2. Ejecuta: `python resample_biome_textures.py`
3. Recarga Godot Editor
4. Verifica que las texturas se ven correctamente

---

**¿Problemas?** Contacta al equipo de desarrollo de Spellloop.
