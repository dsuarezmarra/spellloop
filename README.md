# Spellloop

**Un rogue-lite 2D de vista cenital con sistema de hechizos combinables inspirado en Binding of Isaac**

Spellloop es un juego desarrollado en **Godot 4** con **GDScript**, diseñado para **Steam** (Windows, Linux y Steam Deck).

## 🎮 Características Principales

- **3-5 Magos jugables** con habilidades únicas y árboles de desbloqueo
- **4-6 Biomas distintos** con generación procedural de salas
- **12-20 tipos de enemigos** y **4-6 jefes finales** 
- **Sistema de hechizos combinables** con elementos que se fusionan
- **Progresión permanente** entre runs (talentos, runas, mejoras)
- **Combate manual** con soporte completo para gamepad
- **Guardado local** + integración Steam Cloud
- **Localización**: Inglés y Español
- **Logros de Steam** integrados

## 🚀 Inicio Rápido

### Requisitos
- **Godot 4.3+** 
- **Git**
- **Sistema operativo**: Windows 10/11, Linux, o Steam Deck

### Instalación y Ejecución

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/your-username/spellloop.git
   cd spellloop
   ```

2. **Abrir en Godot:**
   - Abrir Godot 4.3+
   - Seleccionar "Import" y navegar hasta `spellloop/project/`
   - Seleccionar `project.godot`
   - Hacer clic en "Import & Edit"

3. **Ejecutar el juego:**
   - Presionar **F5** en Godot o hacer clic en el botón "Play"
   - Seleccionar `MainMenu.tscn` como escena principal si se solicita

### Controles por Defecto

**Teclado + Mouse:**
- **WASD**: Movimiento
- **Click Izquierdo**: Hechizo primario
- **Click Derecho**: Hechizo secundario
- **Espacio**: Dash/esquivar
- **Q**: Cambiar hechizo
- **E**: Usar objeto
- **ESC**: Pausa

**Gamepad:**
- **Stick Izquierdo**: Movimiento
- **A (Xbox) / X (PlayStation)**: Hechizo primario
- **B (Xbox) / O (PlayStation)**: Hechizo secundario
- **X (Xbox) / Cuadrado (PlayStation)**: Dash
- **Y (Xbox) / Triángulo (PlayStation)**: Cambiar hechizo
- **Bumper izquierdo**: Usar objeto
- **Start/Options**: Pausa

## 🛠️ Desarrollo

### Estructura del Proyecto

```
spellloop/
├── project/                 # Proyecto Godot
│   ├── scenes/             # Escenas .tscn
│   │   ├── levels/         # Biomas, salas, jefes
│   │   ├── ui/             # Interfaces de usuario
│   │   └── characters/     # Personajes jugables
│   ├── scripts/            # Scripts GDScript
│   │   ├── core/           # Managers principales
│   │   ├── systems/        # Sistemas de juego
│   │   └── entities/       # Entidades del juego
│   └── assets/             # Recursos del juego
│       ├── sprites/        # Imágenes PNG
│       ├── audio/          # Música y SFX OGG
│       └── data/           # Datos JSON
├── docs/                   # Documentación
├── qa/                     # Testing y QA
└── .github/workflows/      # CI/CD GitHub Actions
```

### Exportar Builds

**Para Windows:**
```bash
# Desde línea de comandos con Godot CLI
godot --headless --export "Windows Desktop" "build/Spellloop-Windows.exe"
```

**Para Linux:**
```bash
godot --headless --export "Linux/X11" "build/Spellloop-Linux.x86_64"
```

### CI/CD Local

Para probar los workflows de GitHub Actions localmente:

```bash
# Instalar act (https://github.com/nektos/act)
# Windows (con Chocolatey):
choco install act-cli

# Ejecutar workflow localmente:
act -j build-windows
act -j build-linux
```

## 📋 Integración con Steam

### Configurar Steam AppID

1. **Obtener Steam AppID** de tu página de desarrollador en Steamworks
2. **Reemplazar placeholders** en los siguientes archivos:
   - `docs/steam/steam_appid.txt` → Tu AppID real
   - `scripts/core/GameManager.gd` → Buscar `PLACEHOLDER_STEAM_APPID`
   - `assets/data/achievements.json` → Configurar logros reales

3. **Descargar Steamworks SDK:**
   - Descargar desde Steamworks Partner site
   - Copiar `steam_api.dll` (Windows) o `libsteam_api.so` (Linux) a la carpeta del ejecutable

Ver documentación completa en [`docs/steam/README.md`](docs/steam/README.md)

### Steam Cloud Save

Los archivos de guardado se sincronizan automáticamente con Steam Cloud una vez configurado el AppID.

## 🎯 Roadmap y Estado Actual

**✅ Implementado:**
- [x] Estructura del proyecto y scaffold
- [x] Sistema de input y controles
- [x] Managers principales (Game, Save, Audio, etc.)

**🔄 En Desarrollo:**
- [ ] Sistema de hechizos combinables
- [ ] Controlador del jugador y movimiento
- [ ] Generación procedural de niveles
- [ ] Sistema de enemigos básicos

**📋 Próximas Características:**
- [ ] Progresión permanente entre runs
- [ ] Sistema de logros
- [ ] Interfaz de usuario completa
- [ ] Audio y efectos visuales

Ver roadmap completo en [`TODO.md`](TODO.md)

## 🤝 Contribuir

Por favor lee [`CONTRIBUTING.md`](CONTRIBUTING.md) para detalles sobre nuestro código de conducta y el proceso para enviar pull requests.

### Estilo de Código

- **Convención de nombres**: `snake_case` para variables y funciones, `PascalCase` para clases
- **Indentación**: Tabs (configuración por defecto de Godot)
- **Métodos**: Máximo 200 líneas
- **Documentación**: Cada clase debe tener comentarios explicando su propósito

### Testing

```bash
# Ejecutar tests unitarios (cuando estén implementados)
godot --headless -s scripts/tests/run_tests.gd
```

## 📖 Documentación

- **[GDD.md](docs/GDD.md)**: Game Design Document completo
- **[TODO.md](TODO.md)**: Lista de tareas y roadmap
- **[CHANGELOG.md](CHANGELOG.md)**: Historial de cambios
- **[Steam Integration](docs/steam/README.md)**: Guía de integración con Steam

## 📝 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🎵 Assets y Créditos

Todos los assets incluidos son libres de derechos o generados proceduralmente. Ver [`assets/credits.md`](assets/credits.md) para detalles completos.

## 📞 Soporte

Para reportar bugs o solicitar características, por favor usa los [GitHub Issues](https://github.com/your-username/spellloop/issues).

---

**Desarrollado con ❤️ usando Godot 4**