# Spellloop - Guía de Desarrollo

## Configuración del Entorno

### Prerrequisitos
- Godot 4.3+ (recomendado 4.3.1)
- Git para control de versiones
- Editor de código (VS Code recomendado)

### Instalación
1. Clonar el repositorio
2. Abrir `project.godot` en Godot
3. Verificar que todos los autoloads estén configurados
4. Ejecutar el juego para verificar funcionamiento

## Estructura del Proyecto

### Directorios Principales
```
project/
├── scenes/             # Escenas principales del juego
├── scripts/            # Scripts organizados por categoría
│   ├── core/          # Sistemas fundamentales
│   ├── gameplay/      # Mecánicas de juego
│   ├── ai/            # Inteligencia artificial
│   ├── procedural/    # Generación procedural
│   ├── ui/            # Interfaz de usuario
│   ├── effects/       # Efectos visuales/audio
│   ├── assets/        # Generación de assets
│   ├── testing/       # Sistemas de pruebas
│   └── systems/       # Sistemas de alto nivel
├── assets/            # Assets del juego
├── docs/              # Documentación
└── tests/             # Archivos de pruebas
```

### Autoloads (Sistemas Principales)
El juego utiliza 34 sistemas autoload para gestión modular:

#### Sistemas Core (8)
- **GameManager**: Gestión principal del estado del juego
- **SaveSystem**: Persistencia de datos y guardado
- **LocalizationManager**: Soporte multi-idioma
- **AudioManager**: Gestión de audio global
- **UIManager**: Control de interfaz de usuario
- **InputManager**: Manejo de entrada del usuario
- **SettingsManager**: Configuración del juego
- **SceneManager**: Transiciones entre escenas

#### Sistemas de Magia (4)
- **SpellCore**: Motor principal de hechizos
- **SpellCombinator**: Combinación de hechizos
- **SpellGenerator**: Generación procedural de hechizos
- **ElementalManager**: Sistema de elementos mágicos

#### Sistemas de IA (4)
- **EnemyAI**: Inteligencia artificial de enemigos
- **BehaviorTreeManager**: Gestión de árboles de comportamiento
- **PatrolSystem**: Sistema de patrullaje
- **CombatAI**: IA específica de combate

#### Sistemas Procedurales (4)
- **ProceduralLevelGenerator**: Generación de niveles
- **BiomeSystem**: Sistema de biomas
- **DungeonArchitect**: Arquitectura de mazmorras
- **TerrainGenerator**: Generación de terreno

#### Sistemas de Progresión (4)
- **AchievementManager**: Gestión de logros
- **ProgressionSystem**: Progresión del jugador
- **StatsTracker**: Seguimiento de estadísticas
- **RewardSystem**: Sistema de recompensas

#### Sistemas de Efectos (4)
- **EffectsManager**: Efectos visuales
- **ParticleManager**: Sistema de partículas
- **LightingManager**: Gestión de iluminación
- **CameraController**: Control de cámara

#### Sistemas de Audio/Assets (3)
- **MusicGenerator**: Generación procedural de música
- **SFXManager**: Efectos de sonido
- **AssetGenerator**: Generación de assets

#### Sistemas de Testing/QA (3)
- **TestManager**: Pruebas automatizadas
- **PerformanceOptimizer**: Optimización de rendimiento
- **IntegrationValidator**: Validación de integración
- **GameTestSuite**: Suite completa de pruebas

#### Sistemas de Release (4)
- **ReleaseManager**: Gestión de release
- **QualityAssurance**: Aseguramiento de calidad
- **FinalPolish**: Pulido final
- **MasterController**: Control maestro del release

## Flujo de Desarrollo

### 1. Sistemas Core
Los sistemas fundamentales proporcionan la base para todo el juego:
- GameManager coordina el estado global
- SaveSystem maneja la persistencia
- UIManager controla toda la interfaz

### 2. Sistemas de Gameplay
Los sistemas de juego implementan las mecánicas principales:
- SpellCore y relacionados manejan la magia
- Sistemas de IA controlan enemigos
- Sistemas procedurales generan contenido

### 3. Sistemas de Soporte
Los sistemas de soporte mejoran la experiencia:
- Efectos visuales y audio
- Testing y optimización
- Calidad y release

## Patrones de Código

### Singleton Pattern
Todos los autoloads siguen el patrón singleton para acceso global:
```gdscript
# Acceso a sistemas
GameManager.start_game()
SpellCore.cast_spell(spell_data)
EnemyAI.update_behavior(enemy)
```

### Signals para Comunicación
Los sistemas se comunican via signals para bajo acoplamiento:
```gdscript
# Emisión de señales
signal spell_cast(spell_data)
signal enemy_defeated(enemy_data)
signal level_completed()

# Conexión de señales
SpellCore.spell_cast.connect(_on_spell_cast)
```

### Factory Pattern para Generación
Los sistemas procedurales usan factory pattern:
```gdscript
# Generación de contenido
var spell = SpellGenerator.generate_spell(element, power)
var level = ProceduralLevelGenerator.generate_level(seed, difficulty)
```

## Testing y Calidad

### Pruebas Automatizadas
El sistema de testing incluye múltiples niveles:

#### TestManager
- 30 pruebas core del sistema
- Validación de funcionalidad básica
- Pruebas de integridad de datos

#### GameTestSuite
- Pruebas de gameplay completo
- Validación de progresión
- Tests de balance

#### PerformanceOptimizer
- Monitoreo de rendimiento
- Optimización automática
- Validación de targets de FPS

### Validación de Calidad
El sistema QA incluye:

#### QualityAssurance
- 6 categorías de testing
- Puntuación automática
- Reportes detallados

#### ReleaseManager
- 7 puertas de calidad
- Validación pre-release
- Preparación de distribución

### Ejecutar Pruebas
```gdscript
# Pruebas individuales
TestManager.run_all_tests()
GameTestSuite.run_full_suite()

# Validación completa
MasterController.execute_master_validation()
```

## Optimización

### Rendimiento
El juego incluye optimización automática:
- 3 modos de calidad (Quality/Balanced/Performance)
- Ajuste dinámico según hardware
- Monitoreo continuo de FPS

### Memoria
Gestión eficiente de recursos:
- Object pooling para objetos frecuentes
- Carga asíncrona de assets
- Liberación automática de memoria

### GPU
Optimización gráfica:
- LOD automático para modelos
- Culling frustum y occlusion
- Batching de draw calls

## Debug y Profiling

### Herramientas de Debug
- Inspector de sistemas en tiempo real
- Visualización de árboles de comportamiento
- Monitor de rendimiento integrado

### Profiling
- Análisis de CPU por sistema
- Monitoreo de memoria heap
- Profiling de GPU y draw calls

## Guías Específicas

### Añadir Nuevo Sistema
1. Crear script en `scripts/systems/`
2. Heredar de Node o clase base apropiada
3. Añadir a autoloads en project.godot
4. Implementar interfaces requeridas
5. Añadir pruebas correspondientes

### Modificar Sistema Existente
1. Verificar dependencias en otros sistemas
2. Ejecutar pruebas antes de modificar
3. Implementar cambios
4. Actualizar pruebas si es necesario
5. Ejecutar validación completa

### Añadir Contenido
1. Usar sistemas de generación procedural
2. Mantener balance establecido
3. Añadir validación de calidad
4. Documentar nuevas características

## Troubleshooting

### Problemas Comunes
- **Autoloads no cargan**: Verificar project.godot
- **Pruebas fallan**: Revisar dependencias de sistemas
- **Rendimiento bajo**: Ejecutar PerformanceOptimizer
- **Errores de guardado**: Validar SaveSystem

### Logs y Debugging
El juego incluye logging comprehensivo:
```gdscript
# Niveles de log
GameManager.log_info("Información general")
GameManager.log_warning("Advertencia")
GameManager.log_error("Error crítico")
```

## Contribución

### Estándares de Código
- Usar snake_case para variables y funciones
- PascalCase para clases y enums
- Comentarios claros y concisos
- Documentación de APIs públicas

### Workflow de Git
1. Crear branch para feature/bugfix
2. Implementar cambios con commits descriptivos
3. Ejecutar suite completa de pruebas
4. Crear pull request con descripción detallada
5. Code review antes de merge

### Testing Requerido
- Todas las nuevas funciones deben tener pruebas
- Cobertura mínima del 80%
- Validación de rendimiento si aplica
- Documentación actualizada

---

Esta guía proporciona la base para desarrollar y mantener Spellloop de manera efectiva, asegurando calidad y consistencia en todo el proyecto.