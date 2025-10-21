# 🎨 Spellloop - Utilidades de Texturas de Biomas

> 🛠️ Herramientas profesionales para redimensionar y convertir automáticamente las texturas del sistema de biomas procedurales del videojuego **Spellloop**

## 📚 Documentación

| Documento | Descripción |
|-----------|------------|
| **[GUIA_COMPLETA.md](GUIA_COMPLETA.md)** | 📖 Guía detallada con plan de acción completo (LEER PRIMERO) |
| **[README.md](README.md)** | 📋 Resumen de características y opciones de uso |
| **[PYTHON_INSTALLATION.md](PYTHON_INSTALLATION.md)** | 🐍 Instrucciones para instalar Python |

## 🛠️ Herramientas Disponibles

### ⭐ RECOMENDADA: Python Script

**`resample_biome_textures.py`**
- Autodetecta tamaños y redimensiona con alta calidad
- Base (1920×1080) + Decor (256×256)
- Convierte automáticamente a PNG
- Requiere: Python 3.7+, Pillow

```powershell
python resample_biome_textures.py
```

---

### ✅ FUNCIONA: PowerShell Converter

**`convert_textures_to_png.ps1`**
- Convierte JPG/BMP → PNG
- Sin redimensionamiento
- Sin requisitos externos
- Funciona perfectamente

```powershell
.\convert_textures_to_png.ps1
```

---

### 📦 Utilidades Adicionales

| Archivo | Tipo | Propósito |
|---------|------|----------|
| `resample_biome_textures.bat` | Batch | Ejecutor Windows para Python |
| `resample_biome_textures_advanced.ps1` | PowerShell | Redimensionador avanzado (experimental) |

---

## 🚀 Inicio Rápido

### Opción A: Con Python (Recomendado) ⭐

1. **Instala Python** (si no lo tienes):
   - Ve a https://www.python.org/downloads/
   - Descarga Python 3.11+
   - ⚠️ Marca "Add Python to PATH"

2. **Instala Pillow**:
   ```powershell
   pip install Pillow
   ```

3. **Ejecuta el script**:
   ```powershell
   python resample_biome_textures.py
   ```

### Opción B: Solo PowerShell (Sin Python)

```powershell
.\convert_textures_to_png.ps1
```

⚠️ Nota: Solo convierte a PNG, no redimensiona.

---

## 📊 Funcionalidades

### Autodetección

- **"base"** en el nombre → 1920×1080
- **"decor"** en el nombre → 256×256

### Resultados

| Formato | Antes | Después |
|---------|-------|---------|
| JPG | ✓ | ✗ (convertido a PNG) |
| PNG | ✓ | ✓ |
| Tamaño | Variable | 1920×1080 o 256×256 |

---

## 📝 Ejemplo de Ejecución

```
======================================================================
🎨 RESAMPLER DE TEXTURAS DE BIOMAS
======================================================================

📁 Carpeta: C:\...\spellloop\project\assets\textures\biomes
🔍 Encontradas 24 imágenes

📂 Procesando: Grassland/base.jpg
   📏 Tamaño original: 1024x768 (JPEG)
   🎯 Tipo detectado: BASE
   📐 Tamaño objetivo: 1920x1080 (PNG)
   ✅ Guardado como PNG
   💾 Tamaño: 524 KB → 2,097 KB

📂 Procesando: Grassland/decor1.jpg
   📏 Tamaño original: 512x512 (JPEG)
   🎯 Tipo detectado: DECOR
   📐 Tamaño objetivo: 256x256 (PNG)
   ✅ Guardado como PNG
   💾 Tamaño: 128 KB → 65 KB

... (más archivos) ...

======================================================================
📊 RESUMEN
======================================================================
✅ Procesadas: 24 imágenes
⏭️  Omitidas: 0 imágenes
❌ Errores: 0 imágenes

💾 Tamaño original: 12.50 MB
💾 Tamaño nuevo: 8.75 MB
📉 Reducción: 30.0%
======================================================================

✨ ¡Proceso completado exitosamente!
```

---

## ✅ Próximos Pasos

1. ✅ Ejecutar cualquiera de las herramientas
2. ✅ Verificar que todas las imágenes están en PNG
3. ✅ Cerrar y reabrir Godot Editor
4. ✅ Verificar que las texturas se ven correctamente

---

## 🐛 Solución de Problemas

| Problema | Solución |
|----------|----------|
| Python no encontrado | Instala desde python.org, marca "Add to PATH" |
| Pillow no instalado | `pip install Pillow` |
| Acceso denegado .ps1 | `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force` |
| GDI+ Error | Usa script Python o `convert_textures_to_png.ps1` |

Para más ayuda, ver **[GUIA_COMPLETA.md](GUIA_COMPLETA.md)**

---

## 📧 Información

- **Proyecto**: Spellloop
- **Creado**: Octubre 2025
- **Autor**: Equipo de Desarrollo
- **Ubicación**: `C:\Users\dsuarez1\git\spellloop\utils\`

---

**¿Listo?** 👉 Comienza por leer [GUIA_COMPLETA.md](GUIA_COMPLETA.md)
