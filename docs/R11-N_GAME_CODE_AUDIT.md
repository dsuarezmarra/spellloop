# R11-N — Game Code Audit Round 11

**Fecha**: 2025-01-28  
**Motor**: Godot 4.5.1 / GDScript  
**Proyecto**: Loopialike (vampire-survivors-like)  
**Auditor**: Copilot (Claude Opus 4.6)  
**Criterio**: Scan de archivos NO auditados previamente; bugs reales con fix minimal y seguro.

---

## Resumen

| Métrica              | Valor |
|----------------------|-------|
| Archivos escaneados  | 38+   |
| Bugs encontrados     | 3     |
| Fixes aplicados      | 3     |
| Errores post-fix     | 0     |

---

## Bugs Encontrados y Corregidos

### BUG R11-1 — `DEBUG_VFX` dejado en `true` en producción

| Campo       | Valor |
|-------------|-------|
| **Archivo** | `scripts/core/VFXManager.gd` línea 305 |
| **Severidad** | P1 — Performance |
| **Patrón** | Debug flag left on |
| **Impacto** | `print()` ejecutado en **cada spawn de VFX** (líneas 323 y 397). En un vampire-survivors con cientos de efectos/segundo, genera spam masivo en consola y degrada FPS significativamente. |

**Antes:**
```gdscript
var DEBUG_VFX: bool = true # ENABLED FOR DIAGNOSTICS
```

**Después:**
```gdscript
var DEBUG_VFX: bool = false # FIX-R11: Disabled — was left on, causing print() spam every VFX spawn
```

**Verificación:** `get_errors` → 0 errores.

---

### BUG R11-2 — `_process` corre cada frame sin boss activo

| Campo       | Valor |
|-------------|-------|
| **Archivo** | `scripts/ui/GameHUD.gd` líneas 29, 519-520 |
| **Severidad** | P2 — Resource waste |
| **Patrón** | Missing `set_process(false)` |
| **Impacto** | `show_boss_bar()` llama `set_process(true)` pero `hide_boss_bar()` nunca llama `set_process(false)`. `_ready()` tampoco lo desactiva. Resultado: `_process()` corre **cada frame durante toda la partida** haciendo checks de null/valid/boss_bar innecesarios. |

**Fix (2 puntos):**

1. En `_ready()` — añadido `set_process(false)` tras ocultar la barra:
```gdscript
func _ready():
    boss_bar.visible = false
    set_process(false)  # FIX-R11: Only process when boss bar is active
```

2. En `hide_boss_bar()` — añadido `set_process(false)`:
```gdscript
func hide_boss_bar():
    boss_bar.visible = false
    _current_boss = null
    set_process(false)  # FIX-R11: Stop processing when no boss is active
```

**Verificación:** `get_errors` → 0 errores.

---

### BUG R11-3 — `_enter_phase()` no resetea estado de oleada activa

| Campo       | Valor |
|-------------|-------|
| **Archivo** | `scripts/managers/WaveManager.gd` línea 202 |
| **Severidad** | P3 — Logic / Data integrity |
| **Patrón** | Incomplete state reset |
| **Impacto** | Al transicionar de fase, `_enter_phase()` reasigna `wave_sequence` y resetea `current_wave_index = 0` pero **no** resetea `wave_in_progress` ni `enemies_to_spawn_in_wave`. Si la transición ocurre durante una oleada activa: (1) la oleada vieja sigue procesándose con su spawn count original, (2) al completarse, `_complete_wave()` calcula `wave_type` usando `wave_sequence[(0 - 1 + new_size) % new_size]` — el **último** elemento de la secuencia de la **nueva** fase, no el tipo real de la oleada completada. Esto corrompe datos de telemetría (PerfTracker) y la señal `wave_completed`. |

**Antes:**
```gdscript
wave_sequence = SpawnConfig.get_wave_sequence_for_phase(phase_num)
current_wave_index = 0
```

**Después:**
```gdscript
wave_sequence = SpawnConfig.get_wave_sequence_for_phase(phase_num)
current_wave_index = 0
wave_in_progress = false  # FIX-R11: Reset mid-wave state to prevent stale data on phase transition
enemies_to_spawn_in_wave = 0
```

**Verificación:** `get_errors` → 0 errores.

---

## Archivos Escaneados (sin bugs)

Los siguientes archivos fueron leídos y analizados completamente sin encontrar bugs:

| Directorio | Archivos |
|-----------|----------|
| `scripts/core/` | AudioManager.gd, GameManager.gd, SpatialGrid.gd, GlobalWeaponStats.gd, DifficultyManager.gd, ParticleManager.gd, ScaleManager.gd, InputManager.gd, ArenaManager.gd, AttackManager.gd, ExperienceManager.gd, ItemManager.gd, PlayerStats.gd, SaveManager.gd, DamageLogger.gd, DebugConfig.gd, EAContentManager.gd |
| `scripts/managers/` | VFXPool.gd, EnemyPool.gd, PickupPool.gd, SpawnBudgetManager.gd, ChestSpawner.gd, ResourceManager.gd, LootManager.gd |
| `scripts/ui/` | UIManager.gd, GameOverScreen.gd, OptionsMenu.gd, UIVisualHelper.gd, CinematicIntro.gd, FloatingText.gd, ShopChestPopup.gd, SimpleChestPopup.gd, PauseMenu.gd |
| `scripts/game/` | GameCamera.gd, SessionState.gd |
| `scripts/vfx/` | VFX_AOE_Impact.gd, WarningIndicator.gd |
| `scripts/magic/` | LoopiaLikeMagicProjectile.gd, magic_definitions.gd |
| `scripts/interactables/` | TreasureChest.gd |
| `scripts/pickups/` | CoinPickup.gd |
| `scripts/utils/` | DecorFactory.gd |

---

## Patrones Buscados

- [x] Pool reset incompleto (señales, colisiones, flags)
- [x] `is_instance_valid` faltante antes de acceso
- [x] Señales duplicadas (connect sin guard)
- [x] División por cero
- [x] Null guards faltantes
- [x] Variables incorrectas / typos
- [x] Errores lógicos (estados, match sin default)
- [x] Resource leaks (tweens, timers, nodos huérfanos)
- [x] Type mismatches
- [x] Missing break/return
- [x] Array out of bounds
- [x] **Debug flags left on** ← encontrado (R11-1)
- [x] **set_process sin pareja** ← encontrado (R11-2)
- [x] **Reset incompleto en transición de estado** ← encontrado (R11-3)

---

## Notas

- El codebase está generalmente bien escrito con guards apropiados (`is_instance_valid`, empty checks, signal connection guards).
- `DebugConfig.gd` usa `should_log()` con `OS.is_debug_build()` guard — correcto. Pero `VFXManager.DEBUG_VFX` no va por ese sistema, por lo que su `true` era un problema real.
- `EnemyManager._process` contiene inline GDScript strings para efectos de puff (no son funciones duplicadas del manager).
