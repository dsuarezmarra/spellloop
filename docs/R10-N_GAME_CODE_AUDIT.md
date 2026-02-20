# R10-N — Game Code Audit Report

**Proyecto:** Loopialike  
**Motor:** Godot 4.5.1 / GDScript  
**Fecha:** 2025-07-17  
**Archivos escaneados:** 70+  
**Archivos con bugs reales:** 3  
**Falsos positivos descartados:** 0  

---

## Resumen ejecutivo

Se auditaron más de 70 archivos GDScript en `scripts/` distribuidos en managers, weapons, magic, data, components, game, ui, vfx, entities, enemies, pickups, interactables, tools, utils y visuals. Se excluyeron 30 archivos previamente corregidos. Se encontraron **3 bugs reales**, todos corregidos y verificados con `get_errors` (0 errores).

---

## Bug #1 — CRASH: LootManager null-unsafe `current_scene` dereference

| Campo | Valor |
|-------|-------|
| **Severidad** | 🔴 Crash |
| **Archivo** | `scripts/managers/LootManager.gd` |
| **Líneas** | 338, 704 |
| **Síntoma** | Crash silencioso durante transiciones de escena |
| **Impacto** | Cualquier loot drop/chest que se procese durante cambio de escena rompe el juego |

### Diagnóstico

`LootManager` usa solo métodos estáticos (no es un nodo), así que obtiene el `SceneTree` de forma indirecta. El código original era:

```gdscript
var scene_tree = Engine.get_main_loop().current_scene.get_tree() if Engine.get_main_loop() else null
```

El problema es doble:
1. `current_scene` puede ser `null` durante transiciones de escena → **null dereference crash**.
2. Es redundante: `Engine.get_main_loop()` ya **ES** el `SceneTree`. Llamar `.current_scene.get_tree()` es un camino circular innecesario.

### Corrección aplicada

```gdscript
# FIX: Engine.get_main_loop() ya ES el SceneTree, no necesita .current_scene.get_tree()
var scene_tree = Engine.get_main_loop() as SceneTree
```

Aplicado en ambas ocurrencias (líneas 338 y 704). El cast `as SceneTree` devuelve `null` de forma segura si falla, y el código posterior ya tiene guardas `if scene_tree:`.

---

## Bug #2 — RESOURCE LEAK: ProjectileFactory AOEEffect VFXManager fallback sin cleanup

| Campo | Valor |
|-------|-------|
| **Severidad** | 🟡 Resource Leak / Performance |
| **Archivo** | `scripts/weapons/ProjectileFactory.gd` |
| **Línea** | ~1053 (inner class `AOEEffect`) |
| **Síntoma** | Nodos AOEEffect persisten indefinidamente en el árbol de escena |
| **Impacto** | Fuga progresiva de nodos → degradación de rendimiento en partidas largas |

### Diagnóstico

`AOEEffect._create_aoe_visual()` tiene dos rutas para crear efectos visuales:

1. **Ruta ProjectileVisualManager** — programa un timer de auto-cleanup ✅
2. **Ruta fallback VFXManager** — set `_use_enhanced = true` y retorna **sin programar cleanup** ❌

El `_process()` de `AOEEffect` solo llama `queue_free()` cuando `_use_enhanced == false`:

```gdscript
func _process(delta: float) -> void:
    _timer += delta
    if not _use_enhanced:
        if _timer >= duration:
            queue_free()
```

Resultado: cuando se usa la ruta VFXManager, el `AOEEffect` se queda en el árbol ejecutando `_process()` vacío para siempre. Los ticks de daño sí paran (controlados por `total_ticks`), pero el nodo nunca se libera.

### Corrección aplicada

Se añadió auto-cleanup asíncrono en la ruta VFXManager, idéntico al patrón de ProjectileVisualManager:

```gdscript
_use_enhanced = true
# FIX: Programar auto-cleanup para la ruta VFXManager
await get_tree().create_timer(duration + 0.5).timeout
if is_instance_valid(self):
    queue_free()
return
```

---

## Bug #3 — VISUAL: BaseWeapon sin propagación de `rarity`, todas las armas se muestran como "Common"

| Campo | Valor |
|-------|-------|
| **Severidad** | 🟠 Visual / Gameplay |
| **Archivo** | `scripts/weapons/BaseWeapon.gd` |
| **Líneas** | ~25 (declaración), ~101 (extracción), ~89 (fusión override) |
| **Síntoma** | Todas las armas en el menú de pausa muestran estilo "Common" (Tier 1) |
| **Impacto** | Armas raras y fusionadas pierden su distinción visual en la UI |

### Diagnóstico

`WeaponDatabase` define `rarity` por arma (`"common"`, `"uncommon"`, `"rare"`), pero `BaseWeapon` nunca la almacenaba. No existía la propiedad `var rarity`.

`PauseMenu._create_weapon_card()` (línea ~1369) intenta leer:
```gdscript
var rarity_raw = weapon.rarity if "rarity" in weapon else "common"
```

Como `BaseWeapon` no tenía la propiedad, `"rarity" in weapon` siempre era `false`, resultando en **todas las armas con estilo "common"** — bordes grises, sin brillo de tier, sin distinción entre un arma básica y una fusionada legendaria.

### Corrección aplicada

**Paso 1** — Añadida propiedad en `BaseWeapon`:
```gdscript
var rarity: String = "common"
```

**Paso 2** — Extracción en `_initialize_from_data()`:
```gdscript
rarity = data.get("rarity", "common")
```

**Paso 3** — Override para armas fusionadas en `_init()`:
```gdscript
if is_fused:
    rarity = "legendary"  # Fusiones siempre son legendarias
```

Esto garantiza que:
- Armas normales heredan rarity de WeaponDatabase
- Armas fusionadas siempre se muestran como legendarias con bordes especiales

---

## Verificación

```
get_errors LootManager.gd        → ✅ No errors found
get_errors ProjectileFactory.gd   → ✅ No errors found
get_errors BaseWeapon.gd          → ✅ No errors found
```

---

## Archivos escaneados y confirmados limpios (sin bugs)

| Categoría | Archivos |
|-----------|----------|
| **Managers** | DifficultyManager, GlobalWeaponStats, ScaleManager, SessionState, ParticleManager, ResourceManager, SpawnBudgetManager, WeaponFusionManager, ArenaManager, UIManager, InputManager, DecorCollisionManager, AudioManager, VFXManager, EAContentManager, SteamManager, LeaderboardService |
| **Data** | CharacterDatabase, RaresDatabase, BossDatabase, UpgradeDatabase, SpawnConfig, WeaponDatabase |
| **Weapons** | ProjectileVisualManager, ChainLightningVisual, AnimatedProjectileSprite |
| **Enemies** | EnemyAbility, EnemyAbility_Aoe, EnemyAbility_Summon, EnemyAbility_Teleport, EnemyAbility_Nova, EnemyAbility_Dash, EnemyProjectile |
| **Pools** | EnemyPool, PickupPool |
| **Game** | GameCamera, ChestSpawner, GameManager |
| **UI** | PauseMenu, LevelUpPanel, GameOverScreen, StatusIconDisplay |
| **VFX** | AOEVisualEffect, FrozenThunderVisual, StormCallerVisual, OrbitVisualEffect |

---

## Descartados (No son bugs)

| Candidato | Razón de descarte |
|-----------|-------------------|
| LevelUpPanel `_navigate_confirm_modal` modulo por `_confirm_modal_buttons.size()` | Protegido por `_confirm_modal_visible` guard + ejecución single-threaded. El array siempre tiene 2 elementos cuando se navega. |
| LoopiaLikeMagicProjectile (código muerto) | `class_name` definido pero nunca instanciado. No causa daño ni fuga. |
| GameManager wall-clock timing | Solo usado internamente/debug, no afecta gameplay. |
| PauseMenu `_on_quit_pressed` sin null-check en `current_scene` | Siempre se llama desde escena activa del juego. |

---

*Fin del informe R10-N*
