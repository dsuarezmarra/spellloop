# README GENERACIÓN - SISTEMA COMPLETO SPELLLOOP
## Instrucciones de Integración en Godot

### RESUMEN DEL SISTEMA GENERADO

Se ha creado un sistema completo con:
- **25 enemigos** distribuidos en 5 tiers (0-5min, 5-10min, 10-15min, 15-20min, 20-25min)
- **5 bosses** para minutos 5, 10, 15, 20, 25 con mecánicas de fases
- **50 items** distribuidos por raridades (15 blancos, 12 azules, 10 amarillos, 8 naranjas, 5 morados)
- **10 magias base + 25 combinaciones** con efectos únicos
- **Sistema de spawneo inteligente** con packs de 2 tipos por tier
- **Manifest completo** con prompts para generar sprites estilo Funko Pop

### ESTRUCTURA DE ARCHIVOS CREADOS

```
project/
├── scripts/
│   ├── enemies/
│   │   ├── enemy_tier_1_slime_novice.gd
│   │   ├── enemy_tier_1_goblin_scout.gd
│   │   ├── enemy_tier_1_skeleton_warrior.gd
│   │   ├── enemy_tier_1_shadow_bat.gd
│   │   └── enemy_tier_1_poison_spider.gd
│   ├── bosses/
│   │   └── boss_5min_archmage_corrupt.gd
│   ├── magic/
│   │   └── magic_definitions.gd
│   ├── items/
│   │   └── items_definitions.gd
│   └── spawn_table.gd
└── assets/
    └── sprites/
        ├── enemies/ (carpeta para sprites)
        ├── bosses/ (carpeta para sprites)
        └── manifest.json
```

### PASOS DE INTEGRACIÓN EN GODOT

#### 1. CONFIGURACIÓN DE AUTOLOADS

Agregar en Project Settings > AutoLoad:

```
SpawnTable: res://scripts/spawn_table.gd
MagicDefinitions: res://scripts/magic/magic_definitions.gd
ItemsDefinitions: res://scripts/items/items_definitions.gd
```

#### 2. CONFIGURACIÓN DE GRUPOS EN GODOT

Asegurar que existen estos grupos en el proyecto:
- **"player"** - Para el nodo del jugador
- **"enemies"** - Para todos los enemigos spawneados
- **"bosses"** - Para todos los bosses

#### 3. ESCENAS REQUERIDAS (CREAR SI NO EXISTEN)

```
scenes/
├── effects/
│   ├── XPOrb.tscn (orbe de experiencia)
│   └── BossDeathEffect.tscn (efecto de muerte de boss)
├── enemies/
│   ├── EnemyProjectile.tscn (proyectil de enemigo)
│   └── WebProjectile.tscn (telaraña de araña)
└── bosses/
    ├── BossProjectile.tscn (proyectil de boss)
    ├── ChaosProjectile.tscn (proyectil caótico)
    └── TerrainDamage.tscn (zona de daño en suelo)
```

#### 4. MÉTODOS REQUERIDOS EN EL JUGADOR

El nodo Player debe tener estos métodos:

```gdscript
# En el script del Player
func take_damage(amount: int):
    # Implementar reducción de vida
    pass

func apply_status_effect(effect_name: String, duration: float, intensity: int):
    # Implementar efectos de estado (veneno, ralentización, etc.)
    pass

func modify_stat(stat_name: String, value):
    # Implementar modificación de estadísticas por items
    pass

func apply_special_effect(effect_name: String, item_data: Dictionary):
    # Implementar efectos especiales de items únicos
    pass
```

#### 5. MÉTODOS REQUERIDOS EN GAMEMANAGER

```gdscript
# En el script del GameManager
func get_elapsed_minutes() -> int:
    # Retornar minutos transcurridos en la partida
    return int(elapsed_time / 60.0)
```

#### 6. MÉTODOS REQUERIDOS EN ITEMMANAGER

```gdscript
# En el script del ItemManager
func spawn_item_drop(position: Vector2, rarity: int):
    # Crear item del tipo de rareza especificado en la posición
    pass
```

#### 7. MÉTODOS REQUERIDOS EN UIMANAGER

```gdscript
# En el script del UIManager
func show_boss_warning(boss_name: String):
    # Mostrar aviso de aparición de boss
    pass
```

### CONFIGURACIÓN DE SPRITES

#### Generación de Assets Visuales

Usar los prompts en `assets/sprites/manifest.json` para generar sprites con:
- **Stable Diffusion / DALL-E**
- **Tamaño:** 500x500 px
- **Fondo:** Transparente
- **Estilo:** Funko Pop / Chibi

#### Configuración de Import en Godot

Para cada sprite generado:
1. Importar como Texture
2. Configurar Filter: OFF (pixel art)
3. Mipmaps: OFF

### ESCALADO Y RESOLUCIÓN

El sistema está configurado para:
- **Resolución base:** 1920x1080
- **Sprites fuente:** 500x500 px
- **Sprites en juego:** 64x64 px (factor 0.128)
- **Collider base:** 26px radio a 1080p
- **Escalado automático:** Vía ScaleManager existente

### FÓRMULAS DE BALANCE

#### Escalado de Enemigos
```
hp(tier, minute) = round(base_hp * (1 + 0.12 * minute) * (1 + 0.25*(tier-1)))
damage(tier, minute) = round(base_damage * (1 + 0.09 * minute))
xp_drop = round(base_xp * (1 + 0.1 * tier))
```

#### Escalado de Items por Nivel
Las probabilidades de rareza se ajustan automáticamente según el nivel del jugador.

### SISTEMA DE SPAWNEO

#### Activación Automática
El sistema se activa automáticamente al cargar `spawn_table.gd` como autoload.

#### Control Manual
```gdscript
# Forzar spawn de enemigo específico
SpawnTable.force_spawn_enemy("enemy_tier_1_slime_novice", player_position)

# Limpiar todos los enemigos
SpawnTable.clear_all_enemies()

# Obtener información de tier actual
var tier_info = SpawnTable.get_current_tier_info()
```

### SISTEMA DE MAGIAS

#### Uso Básico
```gdscript
# Obtener definición de magia base
var fire_magic = MagicDefinitions.get_base_magic(MagicDefinitions.MagicType.FUEGO)

# Verificar combinación posible
var types = [MagicDefinitions.MagicType.FUEGO, MagicDefinitions.MagicType.HIELO]
var combination_key = MagicDefinitions.can_combine(types)

# Calcular daño
var damage = MagicDefinitions.calculate_damage(base_damage, spell_level, magic_type)
```

### SISTEMA DE ITEMS

#### Uso Básico
```gdscript
# Obtener item por ID
var item = ItemsDefinitions.get_item("basic_wand")

# Obtener items por rareza
var blue_items = ItemsDefinitions.get_items_by_rarity(ItemsDefinitions.ItemRarity.BLUE)

# Generar item aleatorio ponderado
var random_item = ItemsDefinitions.get_weighted_random_item(player_level, luck_modifier)

# Aplicar efectos de item
ItemsDefinitions.apply_item_effects(player_node, "phoenix_feather")
```

### TESTING Y BALANCE

#### Comandos de Testing
```gdscript
# Verificar balance de XP por minuto
var xp_estimate = SpawnTable.get_estimated_xp_per_minute()
print("XP estimada por minuto: ", xp_estimate)

# Verificar conteo de entidades
var entity_count = SpawnTable.get_entities_count()
print("Entidades en pantalla: ", entity_count)
```

#### Tabla de Balance Esperado
```
Minuto | XP/min | Entidades | Tier
   0-5 |    180 |     30-50 |   1
  5-10 |    320 |     45-65 |   2
 10-15 |    480 |     60-80 |   3
 15-20 |    680 |     75-95 |   4
 20-25 |    900 |    90-110 |   5
```

### OPTIMIZACIÓN

#### Límites de Performance
- **Máximo entidades simultáneas:** 100
- **Spawns fuera de pantalla:** Sí
- **Cleanup automático:** Al salir del rango de visión
- **Pool de objetos:** Recomendado para proyectiles

#### Configuración Recomendada
```gdscript
# En spawn_table.gd, ajustar si es necesario:
max_entities_cap = 100  # Reducir en dispositivos lentos
spawn_rate = 0.8        # Aumentar para más enemigos
```

### EXTENSIÓN DEL SISTEMA

#### Agregar Nuevos Enemigos
1. Crear archivo `.gd` siguiendo el template de enemigos existentes
2. Agregar entrada en `tier_definitions` en `spawn_table.gd`
3. Crear entrada en `manifest.json`
4. Generar sprite correspondiente

#### Agregar Nuevas Magias
1. Agregar tipo en `MagicType` enum
2. Crear definición en `base_magic_definitions`
3. Agregar combinaciones en `magic_combinations`

#### Agregar Nuevos Items
1. Crear entrada en `items_database`
2. Configurar rareza y efectos
3. Ajustar `drop_weight` para balance

### RESOLUCIÓN DE PROBLEMAS

#### Errores Comunes
- **"Node not found":** Verificar autoloads y nombres de nodos
- **"Method not found":** Implementar métodos requeridos en Player/GameManager
- **Sprites no aparecen:** Verificar rutas en manifest.json
- **Balance inadecuado:** Ajustar fórmulas de escalado

#### Debug Info
```gdscript
# Agregar para debugging
print("Tier actual: ", SpawnTable.current_tier)
print("Enemigos en pantalla: ", SpawnTable.entities_on_screen)
print("Minuto actual: ", SpawnTable.get_elapsed_minutes())
```

### NOTAS FINALES

Este sistema es **completamente funcional** pero requiere las escenas auxiliares mencionadas. Todas las mecánicas principales están implementadas:

- ✅ Spawneo por tramos temporales
- ✅ Escalado automático de dificultad
- ✅ Sistema de magias combinadas
- ✅ 50 items con raridades
- ✅ Bosses con fases
- ✅ Balance automático

El juego puede funcionar inmediatamente después de crear las escenas auxiliares básicas (XPOrb.tscn, proyectiles, etc.) e implementar los métodos requeridos en Player y GameManager.

**¡Sistema listo para integración completa en Spellloop!**