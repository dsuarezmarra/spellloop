# ⚠️ INSTALACIÓN DE PYTHON REQUERIDA

## Problema

El script `resample_biome_textures.py` requiere Python 3.7+ instalado en tu sistema.

## Soluciones

### Opción 1: Instalar Python desde Microsoft Store (Recomendado)

1. Abre **Microsoft Store**
2. Busca "Python"
3. Elige **Python 3.11** (o la versión más reciente)
4. Haz clic en **Instalar**
5. Espera a que se complete la instalación
6. Abre una nueva terminal PowerShell
7. Verifica que funciona: `python --version`

### Opción 2: Instalar desde python.org

1. Ve a https://www.python.org/downloads/
2. Descarga **Python 3.11** (o más reciente)
3. Ejecuta el instalador
4. ⚠️ **IMPORTANTE**: Marca la opción "Add Python to PATH"
5. Completa la instalación
6. Reinicia tu terminal PowerShell
7. Verifica: `python --version`

### Opción 3: Usar Chocolatey (si está instalado)

```powershell
choco install python
```

## Después de Instalar Python

1. Instala Pillow (biblioteca requerida):

```powershell
pip install Pillow
```

2. Verifica la instalación:

```powershell
python -c "from PIL import Image; print('✅ Pillow instalado correctamente')"
```

3. Ejecuta el script:

```powershell
cd C:\Users\dsuarez1\git\spellloop\utils
python resample_biome_textures.py
```

## Alternativa Temporal: Script PowerShell

Si tienes problemas instalando Python, hay una alternativa más limitada disponible:

```powershell
.\convert_textures_to_png.ps1
```

⚠️ Esta opción solo convierte a PNG pero no redimensiona.

## Soporte

Si tienes problemas:
- Asegúrate de que Python está en el PATH: `echo $env:PATH`
- Verifica la instalación de Pillow: `pip list | grep Pillow`
- Contacta al equipo de desarrollo de Spellloop
