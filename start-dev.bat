@echo off
echo 🚀 Iniciando entorno de desarrollo Spellloop...

echo 🔧 Iniciando Godot Language Server...
start "Godot LSP" "%USERPROFILE%\Downloads\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64.exe" --headless --lsp-port 6005

echo 💻 Abriendo VS Code...
cd /d "c:\Users\dsuarez1\git\spellloop\project"
code .

echo ✅ Entorno listo! 
echo 💡 Tips:
echo    - Presiona F5 en VS Code para ejecutar el juego
echo    - Ctrl+Shift+P para comandos de Godot
echo    - Los errores aparecerán automáticamente en VS Code
pause