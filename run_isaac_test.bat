@echo off
echo === EJECUTANDO GODOT ISAAC TEST ===
echo.

cd /d "C:\Users\dsuarez1\git\spellloop\project"

echo Ejecutando Godot con tus sprites integrados...
echo.
echo CONTROLES:
echo   WASD - Mover el mago
echo   Shift - Dash magico
echo   Flechas - Disparar hechizos
echo   Enter - Generar enemigo aleatorio
echo   ESC - Salir
echo.

"C:\Users\dsuarez1\Downloads\Godot_v4.5-stable_win64.exe" "project.godot"

echo.
echo Prueba completada!
pause