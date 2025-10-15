@echo off
echo 🎮 SPELLLOOP - EJECUTOR DIRECTO
echo ===============================

echo Ejecutando Spellloop con Godot 4.5...
echo.

REM Ruta al ejecutable de Godot
set GODOT_PATH="C:\Users\dsuarez1\Downloads\Godot\Godot_v4.5-stable_win64.exe"

REM Verificar si existe el ejecutable
if exist %GODOT_PATH% (
    echo ✅ Godot encontrado en: %GODOT_PATH%
    echo 🚀 Iniciando juego...
    echo.
    
    REM Ejecutar el juego
    start "" %GODOT_PATH% "C:\Users\dsuarez1\git\spellloop\project\project.godot"
    
    echo ✅ Juego iniciado correctamente!
    echo.
    echo 🎮 CONTROLES:
    echo    WASD - Mover mago
    echo    Flechas - Disparar hechizos  
    echo    Shift - Dash
    echo    ESC - Salir
    echo.
    echo Disfruta de tus sprites Funko Pop! 🎉
) else (
    echo ❌ Error: No se encontró Godot en la ruta especificada
    echo Ubicación esperada: %GODOT_PATH%
    echo.
    echo 📋 Instrucciones manuales:
    echo 1. Descargar Godot 4.5 desde godotengine.org
    echo 2. Extraer en Downloads
    echo 3. Abrir project.godot desde Godot
    echo 4. Presionar F5 para jugar
)

echo.
pause