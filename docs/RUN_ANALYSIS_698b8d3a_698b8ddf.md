# Análisis de Runs — 10 Feb 2026

**Runs analizadas:** `698b8d3a-435b` y `698b8ddf-82b9`  
**Fecha:** 2026-02-10, 20:55 – 21:07  
**Versión:** Loopialike v0.1.0-alpha (post-fixes de sesión anterior)

---

## Resumen Ejecutivo

| Métrica | Run 1 (`698b8d3a`) | Run 2 (`698b8ddf`) |
|---------|--------------------|--------------------|
| Duración | 2:32 min | 8:41 min |
| Personaje | storm_caller | storm_caller |
| Nivel final | 6 | 18 |
| Kills | 137 | 651 |
| Élites matados | 0 | 3 |
| Bosses matados | 0 | 1 |
| Daño infligido | 4,069 | 61,477 |
| Daño recibido (summary) | 96 | 710 |
| Curación | 0 | 565 |
| Oro final | 89 | 2,040 |
| Score | 4,964 | 20,221 |
| Armas finales | lightning_wand lv4 | lightning_wand lv6, arcane_orb lv3, void_pulse lv2, fire_wand lv1 |
| Killed by | elite_tier_1_esqueleto_aprendiz | elite_tier_2_guerrero_espectral |
| Upgrades elegidos | 7 (2 attack_speed, 1 poder menor, 1 agilidad) | 30 (projectile_2 x2, damage_2, gold_bag, lifesteal_tier3, shield_2...) |

### Progresión Run 2 (minuto a minuto)

| Min | Nivel | Kills | Daño Total | DPS Est. | Daño Recibido |
|-----|-------|-------|------------|----------|---------------|
| 0 | 1 | 0 | 4,069* | 68 | 0 |
| 1 | 3 | 53 | 5,246 | 20 | 0 |
| 2 | 6 | 135 | 8,101 | 48 | 0 |
| 3 | 8 | 225 | 12,244 | 69 | 0 |
| 4 | 10 | 308 | 16,416 | 70 | 0 |
| 5 | 11 | 396 | 19,530 | 52 | 0 |
| 6 | 15 | 487 | 31,126 | 193 | 0 |
| 7 | 18 | 634 | 60,975 | 497 | 0 |

> *`damage_dealt_total` en min 0 = 4,069 → **BUG-BT3** (carryover del run anterior)  
> `damage_taken` siempre 0 → **BUG-BT2** (guards de `.enabled`)  
> Spike DPS min 6-7 (52→193→497) = adquisición de arcane_orb + void_pulse + fire_wand

---

## Hallazgos: Bugs de Telemetría

### BUG-BT1: `starting_weapons` vacío en `run_start`

**Evidencia:** En ambos runs, el evento `run_start` tiene `starting_weapons: []`.  
**Causa raíz:** `call_deferred("_start_balance_telemetry")` se ejecutaba antes de que las armas se equipasen tras `reset_for_new_game()`. `call_deferred` solo espera al siguiente frame, pero las armas se equipan asíncronamente.  
**Fix:** Cambiado a `get_tree().create_timer(0.2).timeout.connect(_start_balance_telemetry)` — da 200ms para que las armas estén listas.  
**Archivo:** `scripts/game/Game.gd` L646

---

### BUG-BT2: `damage_taken` siempre 0 en balance.jsonl

**Evidencia:** En TODOS los minute_snapshots y en `run_end.final_stats.damage_taken = 0`, pese a que `summary.stats.damage_taken` sí tiene valores correctos (96 y 710).  
**Causa raíz:** `BalanceDebugger.enabled = false` por defecto (L24). Los **call sites** externos (11 en total, distribuidos en 7 archivos) tenían guardas `if BalanceDebugger.enabled:` que prevenían las llamadas.  

> **Nota:** En la sesión anterior se eliminaron las guardas DENTRO de los métodos de BalanceDebugger, pero se dejaron las guardas en los call sites externos. Este es el bug residual.

**Fix:** Eliminadas las 11+1 guardas de `.enabled` en los call sites:
| Archivo | Método protegido | Línea aprox. |
|---------|-----------------|-------------|
| `BasePlayer.gd` | `log_damage_taken()` (combat) | L769 |
| `BasePlayer.gd` | `log_damage_taken()` (dodge) | L671 |
| `ExperienceManager.gd` | `log_level_up()` | L552 |
| `DamageCalculator.gd` | `log_damage_dealt()` | L184 |
| `ProjectileFactory.gd` | `log_heal("lifesteal")` ×2 | L170, L178 |
| `PlayerStats.gd` | `log_heal("regen")` ×2 | L1372, L1380 |
| `EnemyManager.gd` | `log_elite_spawn/death/ttk` ×3 | L501, L505, L530 |
| `DifficultyManager.gd` | `log_difficulty_scaling()` | L268 |

---

### BUG-BT3: Estado no reseteado entre runs

**Evidencia:** Run 2, min 0 muestra `damage_dealt_total: 4,069` — exactamente el daño total de Run 1.  
**Causa raíz:** `BalanceDebugger.reset_metrics()` existía pero **nunca se llamaba** entre runs.  
**Fix:** Añadida llamada a `BalanceDebugger.reset_metrics()` al inicio de `_start_balance_telemetry()`.  
**Archivo:** `scripts/game/Game.gd` L1871

---

### BUG-BT4: `killer_attack` siempre "unknown"

**Evidencia:** En ambos runs: `death_context.killer_attack = "unknown"`.  
**Causa raíz:** El ring buffer de hits en `BasePlayer._process_frame_damage()` inicializaba `attack_id = "unknown"`. Los enemigos melee no setean `meta("attack_name")` en sus ataques.  
**Fix:** Cambiado el default de `"unknown"` a `primary_hit.element` (ej: "physical", "fire", "lightning"). Si `element` es vacío, usa "physical".  
**Archivo:** `scripts/entities/players/BasePlayer.gd` L800

---

### BUG-BT5: `player_stats` sin cambios *(No es bug — diseño correcto)*

**Observación:** Los `player_stats` en `build_final` muestran los mismos valores base en ambos runs (attack_speed_mult=1.0, damage_mult=1.0, etc.), pese a tener upgrades como "attack_speed_2", "damage_2".  
**Análisis:** `get_stat()` reporta stats globales del jugador. Los upgrades como "attack_speed_2" modifican parámetros **por arma** (weapon-specific), no stats globales. El cambio `move_speed: 174→116` confirma que `get_stat()` funciona (speed path bonus perdido). **No requiere fix.**

---

### BUG-BT6: Weapon "unknown" con daño significativo

**Evidencia (Run 2, audit_report):** Arma "unknown" registra 992 daño, 362 hits, 7 kills — una fuente de daño no trivial.  
**Causa raíz:** 9+ fuentes de daño no setean `meta("weapon_id")`:
- Burn DOT (tick de fuego)
- Overkill transfer (daño excedente trasladado)
- Explosiones
- Execute (ejecución)
- Soul Link reflect
- Thorns (espinas)
- Counter stance

**Fix:** En `EnemyBase.take_damage()`, añadida cadena de fallback:
1. Si attacker tiene `meta("weapon_id")` → usarla
2. Si weapon_id es string vacío → `"effect_" + element` (ej: "effect_fire")
3. Si attacker es null → `"passive_effect"`

**Archivo:** `scripts/enemies/EnemyBase.gd` L1436-1448

---

### BUG-BT7: `score_snapshots` siempre 0

**Evidencia:** Los score_snapshots del RunAuditTracker reportaban `score_total: 0` para todos los minutos.  
**Causa raíz:** `_calculate_run_score()` no se pasaba en el contexto a `minute_tick()`.  
**Fix:** Añadidos al contexto de snapshot: `score_total`, `damage_dealt`, `damage_taken`, `elites_killed`, `bosses_killed`, `healing_done`.  
**Archivo:** `scripts/game/Game.gd` L1944

---

## Observaciones de Balance

### Curva de DPS

El spike de DPS entre min 5→7 es dramático (52 → 497, ×9.5 en 2 minutos). Esto coincide con:
- Adquisición de `arcane_orb` y `void_pulse`
- Subida de nivel 11→18 (7 niveles en 2 min)
- Entrada en "late early game" donde la densidad de enemigos sube

Esto sugiere que la curva de poder del jugador escala más rápido que la dificultad en este rango, creando un "power trough" antes de min 5 seguido de un "power spike" explosivo.

### Muertes (siempre por élites)

- Run 1: `elite_tier_1_esqueleto_aprendiz` (64 dmg en 0.49s, 2 hits) → muerte rápida a nivel 6.
- Run 2: `elite_tier_2_guerrero_espectral` (223 dmg en 3.67s, 2 hits) → muerte más lenta, el jugador tuvo oportunidad de esquivar.

El tracking de élite/raro como killer funciona correctamente (prefijo `elite_` presente).

### Chests

Ningún cofre abierto en ninguna run (chests_opened=0). Puede ser:
1. Los cofres no spawnearon (runs cortas, especialmente run 1)
2. El jugador no recogió los cofres
3. Aún hay un bug de tracking

---

## Mejoras de Telemetría Aplicadas

### Nuevos Eventos en balance.jsonl

| Evento | Descripción | Datos incluidos |
|--------|-------------|-----------------|
| `elite_killed` | Cada élite eliminado | enemy_id, tier, t_min, player_level, kills_total |
| `boss_killed` | Cada boss eliminado | enemy_id, tier, t_min, player_level, kills_total |
| `significant_hit` | Golpes >15% HP max | damage, element, hp_after, hp_max, hp_pct, t_min |
| `boss_spawned` | Boss aparece (nuevo) | boss_id, phase, hp, tier |

### Datos Nuevos en `minute_snapshot`

| Campo | Ubicación | Descripción |
|-------|-----------|-------------|
| `hp_current` | raíz | HP actual del jugador al tomar el snapshot |
| `hp_max` | raíz | HP máximo del jugador |
| `dodges_total` | combat | Total de esquivas acumuladas (desde BalanceDebugger) |
| `active_enemies` | combat | Número de enemigos activos en el momento del snapshot |

### Correlación Perf ↔ Game

Se añadieron `t_min` y `player_level` a dos tipos de evento en `perf.jsonl`:
- `perf_spike` — ahora incluye tiempo de juego y nivel para correlacionar spikes de rendimiento con momentos del juego
- `minute_report` — mismos campos para correlación temporal fácil

---

## Archivos Modificados (esta sesión)

| Archivo | Cambios |
|---------|---------|
| `scripts/game/Game.gd` | FIX-BT1 (timer 0.2s), FIX-BT3 (reset_metrics), FIX-BT7 (score context), +HP/dodges/enemies en snapshot, +elite/boss killed events, +significant_hit events |
| `scripts/entities/players/BasePlayer.gd` | FIX-BT2 (guard removed), FIX-BT4 (element fallback) |
| `scripts/debug/BalanceTelemetry.gd` | +HP en minute_snapshot, +dodges_total, +active_enemies |
| `scripts/debug/BalanceDebugger.gd` | Sin cambios directos (guards removidos en call sites) |
| `scripts/debug/PerfTracker.gd` | +t_min y player_level en perf_spike y minute_report |
| `scripts/enemies/EnemyBase.gd` | FIX-BT6 (weapon_id fallback chain) |
| `scripts/core/ExperienceManager.gd` | FIX-BT2b (guard removed) |
| `scripts/core/EnemyManager.gd` | FIX-BT2b (guards removed), +boss_spawned telemetry |
| `scripts/components/DamageCalculator.gd` | FIX-BT2b (guard removed) |
| `scripts/weapons/ProjectileFactory.gd` | FIX-BT2b (guards removed) |
| `scripts/entities/players/PlayerStats.gd` | FIX-BT2b (guards removed) |
| `scripts/core/DifficultyManager.gd` | FIX-BT2b (guard removed) |

**Total:** 12 archivos modificados, 7 bugs corregidos, 8 mejoras de telemetría añadidas.

---

## Verificación Post-Fix

Para verificar que los fixes funcionan, en la siguiente partida comprobar:

- [ ] `run_start.starting_weapons` NO está vacío
- [ ] `minute_snapshot.combat.damage_taken_total` > 0 cuando el jugador recibe daño
- [ ] `minute_snapshot` en min 0 muestra `damage_dealt_total: 0` (no carryover)
- [ ] `death_context.killer_attack` NO es "unknown" (debería ser "physical", "fire", etc.)
- [ ] No hay weapon "unknown" con daño significativo en `audit_report`
- [ ] `score_snapshots` en audit_report muestra scores > 0
- [ ] `minute_snapshot` incluye `hp_current`, `hp_max`, `dodges_total`, `active_enemies`
- [ ] `perf_spike` y `minute_report` incluyen `t_min` y `player_level`
- [ ] Eventos `elite_killed` y `boss_killed` aparecen en balance.jsonl
- [ ] Evento `significant_hit` aparece cuando el jugador recibe un golpe fuerte
