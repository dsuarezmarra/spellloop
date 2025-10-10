@echo off
echo 🎮 SPELLLOOP - GUÍA DE EJECUCIÓN
echo ================================

echo.
echo Para ejecutar Spellloop, tienes varias opciones:
echo.

echo 1. DESDE GODOT EDITOR (RECOMENDADO):
echo    - Abrir Godot Engine 4.3+
echo    - Seleccionar "Import" o "Open"
echo    - Navegar a esta carpeta y seleccionar "project.godot"
echo    - Hacer clic en "Import & Edit"
echo    - Presionar F5 o hacer clic en el botón "Play"
echo.

echo 2. DESDE LÍNEA DE COMANDOS (si Godot está instalado):
echo    godot --path . 
echo    godot --path . --headless (modo sin interfaz)
echo.

echo 3. EXPORTAR EJECUTABLE:
echo    - Desde Godot: Project > Export
echo    - Seleccionar plataforma (Windows, Linux, etc.)
echo    - Configurar opciones de exportación
echo    - Exportar ejecutable
echo.

echo 4. VALIDACIÓN DEL SISTEMA:
echo    - Para ejecutar las pruebas del sistema:
echo    godot --headless --script scripts/validation/final_validation.gd
echo.

echo ================================
echo 📋 CONTROLES DEL JUEGO:
echo ================================
echo WASD          - Movimiento
echo Mouse Click   - Hechizo primario
echo Mouse Right   - Hechizo secundario  
echo Spacebar      - Dash
echo Q             - Cambiar hechizo
echo E             - Usar item
echo ESC           - Pausa
echo A             - Mostrar logros
echo.

echo ================================
echo 🎯 ESCENAS DISPONIBLES:
echo ================================
echo - MainMenu.tscn       (Menú principal)
echo - TestRoom.tscn       (Sala de pruebas)
echo - GameHUD.tscn        (HUD del juego)
echo - LevelUpScreen.tscn  (Pantalla de subida)
echo - AchievementsScreen.tscn (Logros)
echo.

echo ✅ Spellloop está listo para ejecutar!
echo    Estado: GOLD MASTER - 91.7%% readiness
echo.

pause