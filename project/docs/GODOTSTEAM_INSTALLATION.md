# Instalación de GodotSteam para el Sistema de Ranking

## Estado: ✅ INSTALADO

GodotSteam GDExtension v4.17.1 está instalado en el proyecto.

### Archivos instalados:
- `addons/godotsteam/` - Plugin GDExtension completo
- `steam_appid.txt` - APP ID de prueba (480 = Spacewar)
- `SteamManager` autoload configurado en project.godot

## Requisitos para funcionar
- Godot 4.5+ (la versión instalada actualmente)
- Cuenta de Steamworks Developer (para obtener el APP ID)
- Steamworks SDK

## Método 1: Descarga de GodotSteam Pre-compilado (Recomendado)

### Paso 1: Descargar GodotSteam
1. Ir a https://godotsteam.com/howto/getting_started/
2. Seleccionar la versión que corresponde a Godot 4.5
3. Descargar el paquete pre-compilado para Windows

### Paso 2: Reemplazar el ejecutable de Godot
El paquete descargado contiene un ejecutable de Godot con Steam integrado. Puedes:
- **Opción A**: Reemplazar tu godot.exe actual
- **Opción B**: Usar el ejecutable descargado solo para este proyecto

### Paso 3: Copiar archivos de Steam
Copiar los siguientes archivos a la carpeta del proyecto (`project/`):
- `steam_api64.dll` (incluido en el paquete de GodotSteam)

### Paso 4: Configurar el APP ID
Crear un archivo `steam_appid.txt` en la carpeta `project/` con tu APP ID:
```
480
```
(480 es el APP ID de prueba de Valve. Reemplazar con tu APP ID real al publicar)

## Método 2: GDExtension (Alternativo)

### Paso 1: Instalar el addon
1. Descargar desde https://godotsteam.com/
2. Extraer la carpeta `addons/godotsteam` en `project/addons/`

### Paso 2: Habilitar en el editor
1. Ir a Proyecto → Configuración del Proyecto → Plugins
2. Activar "GodotSteam"

### Paso 3: Archivos requeridos
Copiar `steam_api64.dll` a la carpeta del proyecto

## Configuración del Proyecto

### Añadir SteamManager como Autoload
1. Ir a Proyecto → Configuración del Proyecto → Autoload
2. Añadir `res://scripts/autoloads/SteamManager.gd` con nombre `SteamManager`

### Orden de Autoloads recomendado
```
1. SaveManager
2. AudioManager  
3. SteamManager  ← Nuevo
4. ... otros
```

## Configuración de Leaderboards en Steamworks

### Crear los Leaderboards mensuales
En el panel de Steamworks (partner.steamgames.com):

1. Ir a **App Admin** → Tu juego → **Stats & Achievements** → **Leaderboards**

2. Crear leaderboards con el formato:
   - **Name**: `monthly_score_2025_01` (Enero 2025)
   - **Sort Method**: Descending (puntuación más alta primero)
   - **Display Type**: Numeric
   - **Writes**: Trusted (recomendado para evitar trampas)

3. Los leaderboards soportan hasta 64 bytes de datos adicionales (UGC), que usamos para guardar la build del jugador

### Script para crear leaderboards automáticamente
GodotSteam puede crear leaderboards dinámicamente si no existen:
```gdscript
Steam.createLeaderboard("monthly_score_2025_01", 2, 1)  # 2=Descending, 1=Numeric
```

## Verificar la Instalación

### Test básico
Añade este código temporalmente en algún `_ready()`:
```gdscript
func _ready():
    if Engine.has_singleton("Steam"):
        var steam = Engine.get_singleton("Steam")
        if steam.steamInit():
            print("Steam inicializado correctamente!")
            print("Steam ID: ", steam.getSteamID())
        else:
            print("Error al inicializar Steam")
    else:
        print("GodotSteam no está instalado")
```

### Log esperado si funciona:
```
[SteamManager] ✅ Steam inicializado correctamente - User: TuNombreDeUsuario
```

### Log si Steam no está disponible pero el código es correcto:
```
[SteamManager] ℹ️ GodotSteam no disponible - Modo offline
```

## Modo Offline

El sistema está diseñado para funcionar en modo offline:
- `SteamManager.is_steam_available` será `false`
- `RankingScreen` mostrará un mensaje indicando que no hay conexión
- El juego funcionará normalmente sin features de Steam

## Notas Importantes

1. **Para desarrollo**: Puedes usar el APP ID 480 (Spacewar) para pruebas
2. **Para producción**: Necesitas tu propio APP ID de Steamworks
3. **El cliente de Steam debe estar corriendo** para que GodotSteam funcione
4. **Los datos de leaderboard** se sincronizan automáticamente con Steam

## Archivos creados para el sistema de ranking

| Archivo | Propósito |
|---------|-----------|
| `scripts/autoloads/SteamManager.gd` | Wrapper para GodotSteam |
| `scripts/managers/LeaderboardService.gd` | Serialización de builds |
| `scenes/ui/RankingScreen.tscn` | Escena UI del ranking |
| `scripts/ui/RankingScreen.gd` | Lógica del ranking |
| `scenes/ui/BuildPopup.tscn` | Popup para ver builds |
| `scripts/ui/BuildPopup.gd` | Lógica del popup |

## Troubleshooting

### "Steam not running"
- Asegúrate de que el cliente de Steam esté abierto
- Verifica que `steam_appid.txt` existe en la carpeta del proyecto

### "Leaderboard not found"
- El leaderboard debe existir en Steamworks
- O usar `createLeaderboard()` para crearlo dinámicamente

### "Score upload failed"
- Verificar conexión a internet
- El usuario debe tener el juego en su biblioteca de Steam
