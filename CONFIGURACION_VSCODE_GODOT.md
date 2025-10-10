# 🔧 Configuración de Godot + VS Code

## Paso 1: Configurar Godot Editor

1. Abre Godot Engine
2. Ve a **Editor > Editor Settings**
3. En la sección **Network > Language Server**:
   - ✅ Marca "Use Language Server"
   - Puerto: `6005` (default)
   - ✅ Marca "Enable Smart Resolve"

4. En **Text Editor > External**:
   - **Use External Editor**: ✅ Activar
   - **Exec Path**: Ruta a VS Code
     ```
     C:\Users\%USERNAME%\AppData\Local\Programs\Microsoft VS Code\Code.exe
     ```
   - **Exec Flags**: 
     ```
     --goto {file}:{line}:{col}
     ```

## Paso 2: Configurar VS Code

### Settings.json (Ctrl+Shift+P > "Open Settings JSON")
```json
{
    "godot_tools.gdscript_lsp_server_port": 6005,
    "godot_tools.scene_file_config": "built-in"
}
```

### launch.json para Debugging
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Play in Editor",
            "type": "godot",
            "request": "launch",
            "project": "${workspaceFolder}",
            "port": 6007,
            "address": "127.0.0.1",
            "launch_game_instance": true,
            "launch_scene": false
        },
        {
            "name": "Launch Scene",
            "type": "godot",
            "request": "launch",
            "project": "${workspaceFolder}",
            "port": 6007,
            "address": "127.0.0.1",
            "launch_game_instance": true,
            "launch_scene": true
        }
    ]
}
```

## Paso 3: Funcionalidades que tendrás disponibles

### ✅ **Desarrollo Completo en VS Code:**
- **Syntax Highlighting** - Coloreado de GDScript
- **IntelliSense** - Autocompletado inteligente
- **Error Detection** - Detección de errores en tiempo real
- **Debugging** - Breakpoints y debug completo
- **Scene Editing** - Edición básica de archivos .tscn
- **Project Management** - Explorador de archivos Godot
- **Integrated Terminal** - Ejecutar Godot desde VS Code

### 🎮 **Comandos disponibles (Ctrl+Shift+P):**
- `Godot Tools: Open workspace with Godot editor`
- `Godot Tools: Run project in Godot editor`
- `Godot Tools: Run current scene`
- `Godot Tools: Open Godot editor`

## Paso 4: Workflow Recomendado

1. **Abrir proyecto**: `File > Open Folder` → Seleccionar carpeta del proyecto Godot
2. **Iniciar Language Server**: Abrir Godot Editor una vez para activar LSP
3. **Desarrollar**: Escribir código en VS Code con autocompletado completo
4. **Testing**: Usar F5 o comandos de Godot Tools para ejecutar
5. **Debugging**: Establecer breakpoints y debuggear directamente en VS Code

---
*¡Con esta configuración tendrás todo centralizado en VS Code!* 🎯