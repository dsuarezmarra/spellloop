# 🏗️ ESTRUCTURA DE CÓDIGO - SPELLLOOP

**Última actualización:** 20 Oct 2025  
**Estado:** Limpio y documentado (Post-Fase 1 auditoría)

---

## 📊 VISIÓN GENERAL

```
Spellloop es un roguelike en tiempo real con:
- Sistema de mundo infinito (chunks 5760×3240)
- Sistema de biomas procedurales (6 biomas)
- Combat en tiempo real
- Progresión de experiencia
- Sistema de items
- Audio y efectos visuales
```

### Estadísticas
- **Total Scripts:** 96 archivos GDScript
- **Líneas de código activas:** ~15,000+
- **Última limpieza:** 20 Oct 2025 (removido -1500 líneas de código muerto)

---

## 🎯 ARQUITECTURA MODULAR

### 1. CORE SYSTEMS (Orquestación Principal)

#### SpellloopGame.gd (~400 líneas)
**Punto de entrada principal. Orquesta todo el juego.**

```gdscript
extends Node2D
class_name SpellloopGame

# Responsabilidades:
- Inicializar todos los managers globales
- Crear el jugador
- Conectar señales entre sistemas
- Manejar pausa/resume del juego
- Coordinar transiciones de escena

# Gestiona:
├── GameManager (state machine)
├── InputManager (input handling)
├── AudioManager (sonido)
├── UIManager (interfaz)
├── InfiniteWorldManager (mundo)
├── EnemyManager (enemigos)
├── ParticleManager (efectos)
├── ExperienceManager (experiencia)
├── ItemManager (items)
├── DifficultyManager (dificultad)
└── VisualCalibrator (escalado de resolución)
```

**Punto de entrada:** `scenes/SpellloopMain.tscn` (nodo root)

---

#### GameManager.gd (~300 líneas)
**Máquina de estado del juego.**

```gdscript
# Estados:
enum GameState {
	MENU,
	IN_RUN,
	PAUSED,
	GAME_OVER,
	VICTORY
}

# Responsabilidades:
- Transiciones entre estados
- Gestión de modifiers globales
- Control de pausa
- Estadísticas de la partida
```

---

#### InfiniteWorldManager.gd (~350 líneas)
**Motor de chunks y movimiento del mundo.**

```gdscript
# Responsabilidades:
- Generar chunks 3×3 alrededor del jugador
- Descargar chunks que salen del rango
- Actualizar posición del mundo (ChunksRoot)
- Comunicar cambios a BiomeChunkApplier
- Renderizar el mundo a través de BiomeGenerator

# Flujo:
1. Detectar movimiento del jugador
2. Calcular coordenadas de chunk
3. Generar/descargar chunks según necesidad
4. Mover ChunksRoot (offset negativo del jugador)
5. Emitir señal chunk_changed
6. BiomeChunkApplier aplica texturas al chunk generado

# Comunicaciones:
└─ chunk_generated(coords: Vector2i, biome_data: Dictionary)
   └─ BiomeChunkApplier.apply_biome_to_chunk(...)
```

---

### 2. BIOME SYSTEM (Texturas y Decoraciones)

#### BiomeChunkApplier.gd (422 líneas) ⭐ CRÍTICO
**Aplica texturas y decoraciones a chunks.**

```gdscript
# Arquitectura Opción C (NUEVO - 20 Oct):
BASE (suelo):
  - Tamaño: 1920×1080 (llena exactamente 1 cuadrante)
  - Escala: 1.0 (sin distorsión)
  - Grid: 9 bases de 1920×1080

DECORACIONES:
  - Principales: 256×256 → Escala (3.75, 2.1)
  - Secundarias: 128×128 → Escala (3.75, 2.1)
  - Distribución: 1 decor aleatorio por cuadrante (9 total)

Z-INDEX HIERARCHY:
  -100: Base textures
   -99: Decorations
     0: Enemies, player (default)
    +1: UI elements

# Responsabilidades:
- Cargar configuración JSON
- Seleccionar bioma determinístico (RNG seeded)
- Crear 9 sprites base
- Crear 9 decoraciones aleatorias
- Mantener z-index correcto

# Métodos públicos:
- get_biome_for_position(cx, cy) → Dictionary
- apply_biome_to_chunk(chunk_node, cx, cy) → void
```

#### BiomeGenerator.gd (~280 líneas)
**Genera la geometría del chunk (base).**

```gdscript
# Responsabilidades:
- Crear nodo ChunkBody (Node2D vacío como contenedor)
- Recibir chunks desde InfiniteWorldManager
- Pasarlos a BiomeChunkApplier para texturas
- Gestionar cache local

# Flujo de integración:
InfiniteWorldManager → chunk_generated
              ↓
BiomeChunkApplier → aplica texturas/decor
              ↓
BiomeGenerator → (nodo ChunkBody ya preparado)
```

---

### 3. ENTITY SYSTEMS

#### Player System

```
SpellloopPlayer.gd
  ├─ WizardPlayer.gd (personaje específico)
  │   ├─ animaciones
  │   └─ ataques
  │
  ├─ HealthComponent.gd (vida)
  ├─ InputManager.gd (movimiento)
  └─ AttackManager.gd (combate)
```

#### Enemy System

```
EnemyManager.gd (spawn control)
  ├─ EnemyBase.gd (clase base)
  │   ├─ HealthComponent
  │   ├─ EnemyAttackSystem
  │   └─ EnemyStats
  │
  ├─ Tier 1 (weak)
  │   ├─ EnemyGoblin.gd
  │   ├─ EnemySkeleton.gd
  │   └─ EnemySlime.gd
  │
  ├─ Tier 2-4 (progressively stronger)
  │
  └─ Bosses
      └─ EnemyBoss.gd (base)
          ├─ boss_el_corazon_del_vacio.gd
          ├─ boss_el_conjurador_primigenio.gd
          └─ etc...
```

---

### 4. COMBAT SYSTEM

#### AttackManager.gd (~250 líneas)
**Gestiona ataques del jugador.**

```gdscript
# Responsabilidades:
- Mantener lista de armas equipadas
- Ejecutar cooldowns
- Spawner proyectiles
- Comunicar con enemigos

# Armas soportadas:
├─ IceWand (proyectiles de hielo)
│   └─ IceProjectile.gd
└─ (extensible a más armas)
```

#### EnemyAttackSystem.gd (~200 líneas)
**Gestiona ataques de enemigos.**

```gdscript
# Responsabilidades:
- Detectar rango de ataque
- Cooldown entre ataques
- Infligir daño al jugador
- Knockback
```

---

### 5. PROGRESSION SYSTEMS

#### ExperienceManager.gd
**Gestiona XP y level up del jugador.**

#### ItemManager.gd
**Gestiona items, cofres, drops.**

#### SaveManager.gd
**Persiste estado del juego.**

---

### 6. UI SYSTEM

```
UIManager.gd (orquestación)
  ├─ GameHUD.gd
  │   ├─ health display
  │   ├─ wave indicator
  │   └─ wave timer
  │
  ├─ MinimapSystem.gd
  │   └─ renderiza mundo en miniatura
  │
  ├─ LevelUpPanel.gd
  ├─ MetaShop.gd
  ├─ OptionsMenu.gd
  └─ SimpleChestPopup.gd
```

---

### 7. AUDIO & VISUAL

#### AudioManager.gd (~300 líneas)
**Sistema de sonido.**

#### VisualCalibrator.gd (~200 líneas)
**Escala automática según resolución.**

#### ScaleManager.gd
**Gestiona escalas de UI.**

#### ParticleManager.gd
**Efectos visuales.**

---

### 8. UTILITY SYSTEMS

#### InputManager.gd
**Centraliza entrada del usuario.**

#### Localization.gd
**Soporte multiidioma (EN, ES).**

#### SaveManager.gd
**Persiste datos de configuración.**

---

## 🔄 FLUJOS DE DATOS PRINCIPALES

### Flujo 1: Movimiento del Jugador

```
Input (WASD/Joystick)
    ↓
InputManager.movement_vector
    ↓
WizardPlayer._physics_process()
    ├─ Aplica velocidad
    └─ Reporta posición global
    ↓
InfiniteWorldManager._process()
    ├─ Detecta cambio de chunk
    └─ Emite chunk_generated(coords, biome_data)
    ↓
BiomeChunkApplier.apply_biome_to_chunk()
    ├─ Carga texturas base
    ├─ Genera decoraciones
    └─ Asigna z-index
```

### Flujo 2: Combate

```
AttackManager._process()
    ├─ Detecta enemigos en rango
    └─ Spawna proyectiles (si cooldown OK)
    ↓
Projectile (IceProjectile.gd)
    ├─ Movimiento automático hacia enemigo
    ├─ Detección de colisión
    └─ Impacto → HealthComponent.take_damage()
    ↓
Enemy.take_damage()
    ├─ Reduce HP
    ├─ Aplica knockback
    └─ Emite signal death si HP = 0
    ↓
EnemyManager
    └─ Remueve enemigo del spawn
    ↓
ExperienceManager.add_experience()
    └─ Suma XP y chequea level up
```

### Flujo 3: Generación de Chunks

```
InfiniteWorldManager._update_chunks()
    ├─ for each new chunk coordinate
    └─ BiomeGenerator.request_chunk(cx, cy)
    ↓
BiomeGenerator.generate_chunk()
    ├─ Crea Node2D (ChunkBody)
    ├─ Emite signal chunk_generated
    └─ Retorna referencia
    ↓
InfiniteWorldManager (señal chunk_generated)
    └─ Emite chunk_generated(coords, biome_data)
    ↓
BiomeChunkApplier.apply_biome_to_chunk()
    ├─ Carga config JSON
    ├─ Selecciona bioma (RNG seeded)
    ├─ Crea 9 sprites base (1920×1080 cada uno)
    ├─ Crea 9 decoraciones (256×256 o 128×128)
    └─ Asigna z-index (-100 base, -99 decor)
```

---

## 🗂️ DISPOSICIÓN DE ARCHIVOS

```
scripts/
├── components/
│   └─ HealthComponent.gd           (compartido por player + enemies)
│
├── core/
│   ├─ SpellloopGame.gd             (MAIN ORCHESTRATOR)
│   ├─ GameManager.gd               (state machine)
│   ├─ InfiniteWorldManager.gd      (chunk generation)
│   ├─ BiomeChunkApplier.gd         (texture application) ⭐
│   ├─ BiomeGenerator.gd            (geometry)
│   ├─ AttackManager.gd             (combat)
│   ├─ AudioManager.gd
│   ├─ InputManager.gd
│   ├─ EnemyManager.gd
│   ├─ ExperienceManager.gd
│   ├─ ItemManager.gd
│   ├─ DifficultyManager.gd
│   ├─ SaveManager.gd
│   ├─ VisualCalibrator.gd
│   ├─ UIManager.gd
│   ├─ ScaleManager.gd
│   ├─ ParticleManager.gd
│   ├─ ChunkCacheManager.gd
│   ├─ Localization.gd
│   ├─ SpriteDB.gd
│   └─ ... (otros managers)
│
├── effects/
│   ├─ BossTelegraph.gd
│   └─ XPOrb.gd
│
├── enemies/
│   ├─ EnemyBase.gd                 (clase base)
│   ├─ EnemyStats.gd
│   ├─ EnemyAttackSystem.gd
│   ├─ tier_1/                      (Goblin, Skeleton, Slime)
│   ├─ tier_2/                      (Golem, Ghost, etc.)
│   ├─ tier_3/                      (Mago, etc.)
│   ├─ tier_4/                      (Dragon, etc.)
│   └─ bosses/                      (EnemyBoss + jefes específicos)
│
├── entities/
│   ├─ players/
│   │   ├─ SpellloopPlayer.gd       (controller)
│   │   ├─ BasePlayer.gd            (clase base)
│   │   └─ WizardPlayer.gd          (personaje específico)
│   │
│   ├─ weapons/
│   │   ├─ wands/
│   │   │   └─ IceWand.gd           (arma 1)
│   │   │
│   │   └─ projectiles/
│   │       └─ IceProjectile.gd     (proyectil de hielo)
│
├── items/
│   ├─ items_definitions.gd
│   └─ ItemDrop.gd
│
├── magic/
│   ├─ magic_definitions.gd
│   ├─ MagicProjectile.gd
│   ├─ SpellloopMagicProjectile.gd
│   └─ SpellSystem.gd
│
├── tools/                          (TESTING & DEBUG)
│   ├─ BiomeTextureDebug.gd         ✨ (nuevo - Phase 2)
│   ├─ BiomeIntegrationTest.gd      (revisar antes de usar)
│   ├─ AutoTestBiomes.gd            (revisar antes de usar)
│   ├─ CombatSystemMonitor.gd       (✅ en uso)
│   ├─ CombatDiagnostics.gd         (✅ en uso)
│   ├─ WorldMovementDiagnostics.gd  (✅ en uso)
│   ├─ BiomeRenderingDebug.gd       (✅ en uso)
│   ├─ QuickCombatDebug.gd          (✅ en uso)
│   └─ ... (más tools)
│
├── ui/
│   ├─ GameHUD.gd
│   ├─ UIManager.gd
│   ├─ MinimapSystem.gd
│   ├─ LevelUpPanel.gd
│   ├─ MetaShop.gd
│   ├─ OptionsMenu.gd
│   └─ SimpleChestPopup.gd
│
└── utils/
    └─ RoomData.gd
```

---

## 🔧 CONVENCIONES DE CÓDIGO

### Nomenclatura
- **Clases (extends Node):** PascalCase → `EnemyBase`, `HealthComponent`
- **Variables privadas:** `_snake_case` → `_active_chunks`, `_rng`
- **Variables públicas:** `snake_case` → `health`, `position`
- **Señales:** `snake_case` → `chunk_generated`, `enemy_died`
- **Enums:** `SCREAMING_SNAKE_CASE` → `GameState.IN_RUN`

### Estructura de archivo
```gdscript
extends Node
class_name NombreClase

"""Docstring de clase detallado"""

# Exportables
@export var config_path: String = "res://..."

# Privadas
var _cached_data: Dictionary = {}

# Señales
signal important_event(data: Dictionary)

func _ready() -> void:
    pass

func public_method() -> void:
    pass

func _private_helper() -> void:
    pass
```

### Debugging
- **Prefix:** `[ClassName]` para identificar origen
- **Niveles:**
  - `✅` = éxito
  - `⚠️` = aviso
  - `❌` = error
  - `🔍` = debug info

---

## 📊 TABLA DE DEPENDENCIAS

```
SpellloopGame
  ├─ GameManager
  ├─ InputManager
  ├─ AudioManager
  ├─ UIManager
  ├─ InfiniteWorldManager
  │   ├─ BiomeGenerator
  │   ├─ BiomeChunkApplier   ← CRÍTICO
  │   ├─ ChunkCacheManager
  │   └─ EnemyManager
  │
  ├─ EnemyManager
  ├─ AttackManager
  ├─ ParticleManager
  ├─ ExperienceManager
  ├─ ItemManager
  ├─ DifficultyManager
  └─ VisualCalibrator

BiomeChunkApplier (DEPENDE DE)
  ├─ biome_textures_config.json
  ├─ Texture2D resources
  └─ (INDEPENDIENTE - no depende de otros scripts)

BiomeGenerator (DEPENDE DE)
  ├─ BiomeChunkApplier
  └─ (solo genera geometría vacía)
```

---

## ✅ CHECKLIST DE INTEGRIDAD

Después de cualquier cambio importante:

- [ ] `BiomeChunkApplier.gd` compila sin errores
- [ ] `InfiniteWorldManager.gd` emite señal `chunk_generated`
- [ ] F5 en Godot: biomas se renderizan correctamente
- [ ] F5 en Godot: jugador puede moverse entre chunks
- [ ] Console log: sin errores de bioma
- [ ] Console log: debug prints de texture sizes correctos

---

**Última revisión:** 20 Oct 2025 Post-Cleanup Phase 1  
**Mantenido por:** Automated Code Audit System  
**Próxima auditoría:** Después de cambios importantes
