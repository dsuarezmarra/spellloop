@echo off
REM Test del sistema de dithering de biomas
REM Ejecuta la escena de prueba test_biome_dithering.tscn

echo ========================================
echo  BIOME DITHERING TEST
echo ========================================
echo.
echo Iniciando Godot con escena de prueba...
echo.
echo Controles:
echo   WASD - Mover camara
echo   Q/E  - Zoom in/out
echo   R    - Regenerar con nuevo seed
echo   ESC  - Salir
echo.
echo ========================================

cd /d "%~dp0"

REM Buscar Godot en rutas comunes
set GODOT_PATH=

if exist "C:\Program Files\Godot\Godot_v4.3-stable_win64.exe" (
    set GODOT_PATH=C:\Program Files\Godot\Godot_v4.3-stable_win64.exe
)

if exist "C:\Godot\Godot_v4.3-stable_win64.exe" (
    set GODOT_PATH=C:\Godot\Godot_v4.3-stable_win64.exe
)

if exist "%USERPROFILE%\Downloads\Godot_v4.3-stable_win64.exe" (
    set GODOT_PATH=%USERPROFILE%\Downloads\Godot_v4.3-stable_win64.exe
)

if "%GODOT_PATH%"=="" (
    echo ERROR: No se encontro Godot en rutas comunes
    echo Por favor edita este archivo y especifica la ruta a Godot.exe
    echo.
    pause
    exit /b 1
)

echo Ejecutando: %GODOT_PATH%
echo.

"%GODOT_PATH%" --path "%~dp0" test_biome_dithering.tscn

pause
