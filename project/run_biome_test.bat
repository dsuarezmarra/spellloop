@echo off
REM Script para ejecutar Godot y capturar testing automático

cd /d "c:\git\spellloop\project"

echo Iniciando Godot con testing de biomas...
echo.

"C:\Program Files\Godot\Godot.exe" . --headless --windowed --resolution 1280x720

echo.
echo Testing completado. Revisa la consola de Godot arriba para los resultados.
pause
