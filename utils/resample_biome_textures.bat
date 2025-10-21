@echo off
REM 🎨 BIOME TEXTURE RESAMPLER BATCH SCRIPT
REM Ejecuta el resampler de texturas de biomas

setlocal enabledelayedexpansion

echo.
echo ======================================================================
echo 🎨 RESAMPLER DE TEXTURAS DE BIOMAS
echo ======================================================================
echo.

REM Cambiar a la carpeta del script
cd /d "%~dp0"

REM Verificar si Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Python no está instalado o no está en el PATH
    echo.
    echo Por favor, instala Python desde: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Verificar si PIL está instalado
python -c "from PIL import Image" >nul 2>&1
if errorlevel 1 (
    echo ⚠️  PIL (Pillow) no está instalado. Instalando...
    pip install Pillow
    if errorlevel 1 (
        echo ❌ ERROR: No se pudo instalar Pillow
        pause
        exit /b 1
    )
)

REM Ejecutar el script
echo 📂 Iniciando resampler...
echo.

python resample_biome_textures.py "%~1"

if errorlevel 1 (
    echo.
    echo ❌ El resampler encontró un error
    pause
    exit /b 1
)

echo.
pause
