# Respuestas para Implementación de Telemetría

## Preguntas Respondidas

### 1. ¿Dónde está el "run loop" principal?

**Archivo:** `project/scripts/game/Game.gd` (1882 líneas)

Este archivo controla todo el ciclo de vida de una partida:

- **Inicio de run:** `_ready()` → `_initialize_game()` → `start_game()`
- **Loop principal:** `_process(delta)` actualiza `game_time` y estadísticas
- **Fin de run:** `end_game()` o `game_over()` cuando el jugador muere

**run_stats ya existentes** (líneas 49-61):
```gdscript
var run_stats: Dictionary = {
    "time": 0.0,
    "level": 1,
    "kills": 0,
    "xp_total": 0,
    "gold": 0,
    "damage_dealt": 0,
    "damage_taken": 0,
    "bosses_killed": 0,
    "elites_killed": 0,
    "healing_done": 0
}
```

**Señales conectadas para eventos:**
- `wave_manager.boss_spawned.connect(_on_boss_spawned)` (línea 322)
- `wave_manager.elite_spawned.connect(_on_elite_spawned)` (línea 326)

---

### 2. ¿Dónde se guardan logs ahora mismo?

**Sistema actual:** `PerfTracker.gd` (autoload singleton)

**Path de logs:** `user://perf_logs/`
- Formato: `perf_session_{timestamp}.jsonl`
- Ya usa JSONL (1 evento por línea)
- Schema version: 2

**Inicialización (líneas 59-66):**
```gdscript
const LOG_DIR = "user://perf_logs"

func _init_logs() -> void:
    if not DirAccess.dir_exists_absolute(LOG_DIR):
        DirAccess.make_dir_absolute(LOG_DIR)
    
    var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
    _current_log_file = LOG_DIR.path_join("perf_session_%s.jsonl" % timestamp)
```

**Path sugerido para telemetría de balance:**
```
user://balance_logs/run_{run_id}_{timestamp}.jsonl
```

O si se prefiere agregar a PerfTracker:
```
user://perf_logs/balance_session_{timestamp}.jsonl
```

---

### 3. ¿Preferencia de flag activar/desactivar?

**Recomendación: SÍ, con flag.**

Ya existe patrón en `PerfTracker.gd`:
```gdscript
var enabled: bool = true
```

Sugerencia para telemetría de balance:
```gdscript
var telemetry_enabled: bool = true  # En BalanceDebugger o nuevo TelemetryLogger
```

Puede togglearse via:
- Flag en código
- Argumento de línea de comandos: `--enable-balance-telemetry`
- Menú de debug (F10 activa BalanceDebugger)

---

### 4. ¿1 archivo por run o todas las runs en el mismo JSONL?

**Recomendación: 1 archivo por run**

Razones:
- Más fácil de analizar individualmente
- Evita archivos gigantes en sesiones largas
- Permite compartir runs específicas
- Coincide con el patrón actual de `run_id` incremental

**Formato sugerido:**
```
user://balance_logs/
├── run_0001_2026-02-06T14-30-00.jsonl
├── run_0002_2026-02-06T15-45-22.jsonl
└── run_0003_2026-02-06T17-00-15.jsonl
```

---

## Mapeo de Eventos a Archivos Existentes

| Evento | Archivo Principal | Función/Señal |
|--------|-------------------|---------------|
| `run_start` | `Game.gd` | `start_game()`, `_initialize_game()` |
| `minute_snapshot` | `Game.gd` | Nuevo en `_process()` cada 60s |
| `upgrade_pick` | `LevelUpPanel.gd` | `_apply_option()` (línea ~2115) |
| `weapon_level_up` | `BaseWeapon.gd` o `WeaponDatabase.gd` | Cuando sube nivel de arma |
| `chest_opened` | `ChestSpawner.gd` / `LootManager.gd` | Al abrir cofre |
| `elite_spawned` | `EnemyManager.gd` | `elite_spawned.emit()` (línea 377) |
| `boss_spawned` | `WaveManager.gd` | `boss_spawned.emit()` (línea 550) |
| `run_end` | `Game.gd` | `end_game()`, `game_over()` |

---

## Datos Ya Disponibles (No requieren cálculo nuevo)

### En `run_stats` (Game.gd):
- ✅ time, level, kills, xp_total, gold
- ✅ damage_dealt, damage_taken, healing_done
- ✅ bosses_killed, elites_killed

### En `DifficultyManager.gd`:
- ✅ difficulty_phase (1/2/3)
- ✅ enemy_hp_mult, enemy_dmg_mult, spawn_mult, elite_mult, speed_mult

### En `PlayerStats.gd`:
- ✅ hp_max, regen (hp_regen), armor, dodge_chance
- ✅ attack_speed, damage_mult, crit_chance, crit_mult, move_speed
- ✅ lifesteal

### En `BalanceDebugger.gd` (ya existe):
- ✅ damage_dealt_samples, damage_taken, dodges_count
- ✅ heal_from_regen, heal_from_lifesteal, heal_from_kill
- ✅ elite_ttk_samples, boss_ttk_samples

---

## Datos que Requieren Tracking Nuevo

| Campo | Dónde implementar |
|-------|-------------------|
| `xp_per_min` (rolling) | `ExperienceManager.gd` o `minute_snapshot` |
| `dps_est` (últimos 30s) | `BalanceDebugger.gd` (agregar buffer) |
| `rerolls_used_last_60s` | `LevelUpPanel.gd` + contador en Game |
| `chests_opened_last_60s` | `ChestSpawner.gd` + contador en Game |
| `fusions_obtained_total` | `LootManager.gd` (ya trackea fusiones) |
| `options_shown` en upgrade_pick | `LevelUpPanel.gd` antes de mostrar |
| `killed_by` en run_end | `Game.gd` al recibir señal de muerte |

---

## Resumen Ejecutivo para Claude

```
TELEMETRY_CONFIG = {
    "run_loop": "project/scripts/game/Game.gd",
    "log_path": "user://balance_logs/",
    "log_format": "run_{run_id}_{timestamp}.jsonl",
    "enable_flag": true,  # toggleable
    "one_file_per_run": true,
    
    "existing_systems": {
        "perf_tracker": "project/scripts/debug/PerfTracker.gd",
        "balance_debugger": "project/scripts/debug/BalanceDebugger.gd",
        "run_stats": "Game.gd:run_stats dictionary"
    },
    
    "key_files": {
        "upgrade_pick": "project/scripts/ui/LevelUpPanel.gd",
        "chest_opened": "project/scripts/managers/ChestSpawner.gd",
        "elite_spawn": "project/scripts/core/EnemyManager.gd",
        "boss_spawn": "project/scripts/managers/WaveManager.gd",
        "xp_level": "project/scripts/core/ExperienceManager.gd",
        "difficulty": "project/scripts/core/DifficultyManager.gd",
        "player_stats": "project/scripts/core/PlayerStats.gd"
    }
}
```

---

## Ejemplo de Evento minute_snapshot (propuesta)

```json
{
    "event": "minute_snapshot",
    "session_id": "abc-123-def",
    "run_id": 42,
    "timestamp_ms": 1707234567890,
    "t_min": 15,
    "seed": 12345678,
    "difficulty_phase": 1,
    "player_level": 12,
    "score_current": 15420,
    
    "progression": {
        "xp_total": 8500,
        "xp_to_next": 450,
        "xp_per_min": 566,
        "level": 12,
        "levels_per_min": 0.8
    },
    
    "combat": {
        "dps_est": 245,
        "damage_done_last_60s": 14700,
        "damage_taken_last_60s": 320,
        "healing_done_last_60s": 180,
        "kills_last_60s": 78,
        "elites_killed_last_60s": 1,
        "bosses_killed_last_60s": 0
    },
    
    "economy": {
        "gold_total": 450,
        "gold_gained_last_60s": 85,
        "rerolls_used_last_60s": 1,
        "rerolls_total": 2,
        "chests_opened_last_60s": 1,
        "fusions_obtained_total": 0
    },
    
    "difficulty": {
        "enemy_hp_mult": 1.2,
        "enemy_dmg_mult": 1.15,
        "spawn_mult": 1.1,
        "elite_mult": 1.0,
        "speed_mult": 1.05
    },
    
    "build": {
        "weapons": [
            {"id": "magic_wand", "lvl": 3},
            {"id": "shadow_dagger", "lvl": 2}
        ],
        "top_upgrades": [
            {"id": "damage_1", "stacks": 3},
            {"id": "regen_1", "stacks": 2}
        ],
        "stats": {
            "hp_max": 120,
            "regen": 2.5,
            "lifesteal": 0.03,
            "armor": 5,
            "dodge": 0.08,
            "attack_speed": 1.15,
            "damage_mult": 1.25,
            "crit_chance": 0.10,
            "crit_mult": 1.5,
            "move_speed": 1.0
        }
    }
}
```

---

## Próximos Pasos

1. Crear `TelemetryLogger.gd` como autoload (o extender `BalanceDebugger.gd`)
2. Implementar los 8 eventos MVP
3. Hook en los archivos listados arriba
4. Testear con 2-3 runs manuales
5. Analizar JSONL con script Python o herramienta de visualización
