# Informe de Investigación de Bugs — Sistemas Centrales

**Fecha:** Investigación exhaustiva sobre el código fuente  
**Motor:** Godot 4.5.1 / GDScript  
**Alcance:** Upgrades, Efectos de Estado, Fusiones, Cofres/Pickups, Knockback  
**Regla:** Solo lectura — sin cambios de código  

---

## Bugs Excluidos (Ya Corregidos)

Los siguientes bugs ya fueron corregidos previamente y NO se incluyen en este informe:
1. Caos Primordial FAIL al límite de stat
2. `aoe_damage_mult` / `single_target_mult` DEAD_STAT
3. Knockback excesivo en armas fusionadas
4. Inversor / damage-per-coin no funcionaba
5. Cofres fantasma duplicándose

---

## BUG-01 · `gold_mult` nunca es consumido — ~10 upgrades de oro sin efecto

| Campo | Valor |
|---|---|
| **Severidad** | ALTA |
| **Confianza** | ALTA |
| **Riesgo de fix** | BAJO |
| **Sistema** | Upgrades / Pickups |

**Archivos afectados:**
- `scripts/core/ExperienceManager.gd` línea 471
- `scripts/entities/LoopiaLikePlayer.gd` líneas 476–483
- `scripts/data/UpgradeDatabase.gd` (múltiples entradas)

**Descripción:**  
Existen dos stats para bonificar el valor del oro: `coin_value_mult` y `gold_mult`. La función `ExperienceManager._get_player_coin_mult()` SIEMPRE retorna `PlayerStats.get_stat("coin_value_mult")` porque PlayerStats existe en el grupo `"player_stats"` y siempre tiene el método `get_stat()`. El fallback a `LoopiaLikePlayer.get_coin_value_mult()` (que sí multiplica por `gold_mult`) **nunca se ejecuta**.

~10 upgrades en UpgradeDatabase modifican `gold_mult` (ej: `gold_rush_1/2/3`, `unique_gold_rush`, `unique_pacifist`, `cursed_greed_1/2`, etc.) pero solo **1** upgrade modifica `coin_value_mult` (`magnetismo_economico`).

**Comportamiento esperado:** Todas las mejoras de oro deberían incrementar el valor real de las monedas recogidas.

**Comportamiento actual:** Solo `magnetismo_economico` (que modifica `coin_value_mult`) funciona. Todas las demás mejoras de oro no tienen efecto en el valor de monedas.

---

## BUG-02 · `unique_streak_master` — operación `set_flag` no implementada

| Campo | Valor |
|---|---|
| **Severidad** | ALTA |
| **Confianza** | ALTA |
| **Riesgo de fix** | BAJO |
| **Sistema** | Upgrades |

**Archivos afectados:**
- `scripts/data/UpgradeDatabase.gd` línea 2698
- `scripts/core/PlayerStats.gd` línea 1778 (match statement en `apply_upgrade`)
- `scripts/core/ExperienceManager.gd` líneas 418, 482–492

**Descripción:**  
El upgrade `unique_streak_master` ("Maestro de Racha") define su efecto como:
```gdscript
{"stat": "double_coin_streak", "value": true, "operation": "set_flag"}
```
En `PlayerStats.apply_upgrade()`, el match statement solo maneja `"add"`, `"multiply"`, `"set"` y default (`_` → `add_stat`). La operación `"set_flag"` cae en el default, que ejecuta `add_stat("double_coin_streak", true)`.

Problemas encadenados:
1. `add_stat` recibe `true` como float (GDScript convierte a `1.0`), pero `double_coin_streak` no es un WEAPON_STAT, así que se crea en PlayerStats.stats
2. `ExperienceManager._has_flag("double_coin_streak")` busca en `player.active_flags` y `game.player_flags` — **ninguno de los cuales se llena desde `apply_upgrade()`**
3. El flag nunca se activa → el bonus de racha doble no funciona

**Comportamiento esperado:** Al elegir "Maestro de Racha", el bonus de streak de monedas debería duplicarse.

**Comportamiento actual:** El upgrade no tiene efecto alguno.

---

## BUG-03 · `near_sighted` — penalización de rango nunca aplicada (daño gratis)

| Campo | Valor |
|---|---|
| **Severidad** | ALTA |
| **Confianza** | ALTA |
| **Riesgo de fix** | BAJO |
| **Sistema** | Upgrades |

**Archivos afectados:**
- `scripts/data/UpgradeDatabase.gd` líneas 1711–1724

**Descripción:**  
El upgrade cursed `near_sighted` ("Miope") dice: "**-50% Rango, +50% Daño**". Sus efectos son:
```gdscript
{"stat": "near_sighted_active", "value": 1, "operation": "add"},
{"stat": "damage_mult", "value": 0.50, "operation": "add"}
```
- El `damage_mult += 0.50` se enruta correctamente a GlobalWeaponStats → **funciona** (+50% daño).  
- El `near_sighted_active = 1` se almacena en PlayerStats, pero **nunca se consume** en ningún lugar del código. No hay lógica que lea este stat para reducir el rango de las armas.

Búsqueda exhaustiva de `near_sighted_active` → solo aparece en `UpgradeDatabase.gd`.

**Comportamiento esperado:** Las armas deberían tener -50% rango como trade-off por +50% daño.

**Comportamiento actual:** El jugador obtiene +50% daño sin penalización alguna.

---

## BUG-04 · `unique_soy_milk` — stat `"knockback"` incorrecto (debería ser `"knockback_mult"`)

| Campo | Valor |
|---|---|
| **Severidad** | ALTA |
| **Confianza** | ALTA |
| **Riesgo de fix** | BAJO |
| **Sistema** | Upgrades / Knockback |

**Archivos afectados:**
- `scripts/data/UpgradeDatabase.gd` línea 2427
- `scripts/core/PlayerStats.gd` líneas 1222, 1713

**Descripción:**  
El upgrade `unique_soy_milk` ("Leche de Soja") dice: "+50% Vel. Ataque, -40% Daño, **-20% Retroceso**". Su efecto de knockback es:
```gdscript
{"stat": "knockback", "value": 0.8, "operation": "multiply"}
```
- `"knockback"` **no está** en la lista `WEAPON_STATS` (que conteniene `"knockback_mult"`).
- Al no ser WEAPON_STAT, va a la rama local de PlayerStats.
- `multiply_stat("knockback", 0.8)` verifica `if not stats.has("knockback"): return` — y `"knockback"` **no existe** en `BASE_STATS`.
- La función retorna silenciosamente sin hacer nada.

El stat correcto debería ser `"knockback_mult"` (que sí está en WEAPON_STATS y en GlobalWeaponStats.BASE_GLOBAL_STATS).

**Comportamiento esperado:** Retroceso reducido en -20% al elegir este upgrade.

**Comportamiento actual:** El -20% retroceso no se aplica. Solo funcionan +50% vel. ataque y -40% daño.

---

## BUG-05 · `enemy_gold_drop_chance` — stat muerto, drops extra nunca ocurren

| Campo | Valor |
|---|---|
| **Severidad** | ALTA |
| **Confianza** | ALTA |
| **Riesgo de fix** | BAJO |
| **Sistema** | Upgrades / Pickups |

**Archivos afectados:**
- `scripts/data/UpgradeDatabase.gd` línea 2635
- `scripts/core/ExperienceManager.gd` líneas 291–295

**Descripción:**  
El upgrade `unique_gold_rush` ("Fiebre del Oro") dice: "Los enemigos sueltan monedas con 5% chance. +20% oro." Sus efectos:
```gdscript
{"stat": "enemy_gold_drop_chance", "value": 0.05, "operation": "add"},
{"stat": "gold_mult", "value": 1.20, "operation": "multiply"}
```
`ExperienceManager.spawn_coins_from_enemy()` usa un `base_coin_drop_chance` fijo (0.7) y **nunca lee** `enemy_gold_drop_chance` de PlayerStats.

Búsqueda exhaustiva de `enemy_gold_drop_chance` → solo aparece en `UpgradeDatabase.gd`.

**Comportamiento esperado:** Enemigos con chance adicional de 5% de soltar monedas.

**Comportamiento actual:** La parte de "5% chance" del upgrade no funciona. (Y por BUG-01, el +20% oro vía `gold_mult` tampoco funciona).

---

## BUG-06 · Modo Torreta — bonuses de armas no llegan a GlobalWeaponStats

| Campo | Valor |
|---|---|
| **Severidad** | ALTA |
| **Confianza** | ALTA |
| **Riesgo de fix** | MEDIO |
| **Sistema** | Upgrades |

**Archivos afectados:**
- `scripts/core/PlayerStats.gd` líneas 1091–1098
- `scripts/core/AttackManager.gd` líneas 150–173 (`_get_combined_global_stats`)
- `scripts/entities/players/BasePlayer.gd` líneas 1975–1978

**Descripción:**  
Cuando el Modo Torreta (`unique_tower`) está activo, `PlayerStats.get_stat()` aplica bonuses:
```gdscript
if is_turret_mode:
    if stat_name == "attack_speed_mult": final_value += 0.5   # +50%
    elif stat_name == "damage_mult": final_value += 0.25      # +25%
    elif stat_name == "damage_taken_mult": final_value -= 0.2  # -20%
```
Sin embargo, las armas obtienen sus stats de `AttackManager._get_combined_global_stats()`, que lee directamente de `GlobalWeaponStats.get_all_stats()` — **no** de `PlayerStats.get_stat()`. Los bonuses de `attack_speed_mult` y `damage_mult` del Modo Torreta **nunca llegan** al sistema de armas.

Solo `damage_taken_mult` funciona correctamente porque `BasePlayer.take_damage()` sí lee de `PlayerStats.get_stat()`.

**Comportamiento esperado:** Modo Torreta: +50% vel. ataque, +25% daño, -20% daño recibido.

**Comportamiento actual:** Solo -20% daño recibido funciona. Los bonuses ofensivos son ignorados.

---

## BUG-07 · Sistema Growth — bonuses de stats de armas se pierden silenciosamente

| Campo | Valor |
|---|---|
| **Severidad** | MEDIA |
| **Confianza** | ALTA |
| **Riesgo de fix** | MEDIO |
| **Sistema** | Upgrades |

**Archivos afectados:**
- `scripts/core/PlayerStats.gd` líneas 1520–1542 (`_apply_growth_bonus`)
- `scripts/core/AttackManager.gd` líneas 150–173 (`_get_combined_global_stats`)

**Descripción:**  
`_apply_growth_bonus()` añade `temp_modifiers` a PlayerStats para stats de armas:
```gdscript
var growth_stats_mult = [
    "damage_mult", "attack_speed_mult", "area_mult",
    "projectile_speed_mult", "duration_mult", "xp_mult"
]
var growth_stats_add = [
    "max_health", "health_regen", "armor", "pickup_range", "move_speed",
    "crit_chance", "crit_damage"
]
```
Los stats de armas (`damage_mult`, `attack_speed_mult`, `area_mult`, `projectile_speed_mult`, `duration_mult`, `crit_chance`, `crit_damage`) se añaden como temp_modifiers a PlayerStats, pero las armas leen desde `GlobalWeaponStats` vía `_get_combined_global_stats()`, que **no incluye temp_modifiers de PlayerStats**.

Los stats de jugador (`max_health`, `health_regen`, `armor`, `pickup_range`, `move_speed`, `xp_mult`) sí funcionan correctamente porque se leen desde `PlayerStats.get_stat()`.

**Comportamiento esperado:** El stat Growth debería incrementar gradualmente daño, velocidad de ataque, área, etc. de todas las armas.

**Comportamiento actual:** Growth solo incrementa stats de jugador (HP, regen, armor, etc.). Todos los bonuses de armas del Growth son ignorados (~7 de 13 stats afectados).

---

## BUG-08 · Inconsistencia DoT: Burn amplificado por Shadow Mark, Bleed no

| Campo | Valor |
|---|---|
| **Severidad** | BAJA |
| **Confianza** | MEDIA |
| **Riesgo de fix** | BAJO |
| **Sistema** | Efectos de Estado |

**Archivos afectados:**
- `scripts/enemies/EnemyBase.gd` líneas 1976–1977 (Burn DoT)
- `scripts/enemies/EnemyBase.gd` líneas 2003–2006 (Bleed DoT)

**Descripción:**  
El procesamiento de DoT tiene una inconsistencia entre Burn y Bleed:

- **Burn** llama a `take_damage(int(_burn_damage))` → pasa por el pipeline completo de `take_damage()`, incluyendo el bonus de Shadow Mark (+X% daño), reducción de bloqueadores, escudo de hielo, etc.
- **Bleed** llama directamente a `health_component.take_damage(int(_bleed_damage), "bleed")` → bypasea todos los modificadores de daño para "evitar loop infinito" según el comentario.

Consecuencias:
1. Un enemigo con Shadow Mark recibe daño de Burn amplificado, pero daño de Bleed sin amplificar.
2. Burn DoT puede ser mitigado por escudos de bloqueador/hielo del enemigo; Bleed no.
3. Burn DoT registra kills correctamente vía `take_damage()`; Bleed podría fallar en edge cases.

**Nota:** El comentario "Bypass shadow_mark para evitar loop infinito" sugiere que es parcialmente intencional, pero la inconsistencia puede confundir al jugador.

---

## Tabla Resumen

| ID | Bug | Severidad | Confianza | Riesgo | Sistema |
|---|---|---|---|---|---|
| BUG-01 | `gold_mult` nunca consumido (~10 upgrades) | ALTA | ALTA | BAJO | Upgrades/Pickups |
| BUG-02 | `set_flag` no implementado en apply_upgrade | ALTA | ALTA | BAJO | Upgrades |
| BUG-03 | `near_sighted` sin penalización de rango | ALTA | ALTA | BAJO | Upgrades |
| BUG-04 | `unique_soy_milk` stat "knockback" incorrecto | ALTA | ALTA | BAJO | Upgrades/Knockback |
| BUG-05 | `enemy_gold_drop_chance` dead stat | ALTA | ALTA | BAJO | Upgrades/Pickups |
| BUG-06 | Modo Torreta bonuses ofensivos perdidos | ALTA | ALTA | MEDIO | Upgrades |
| BUG-07 | Growth weapon stats no llegan a armas | MEDIA | ALTA | MEDIO | Upgrades |
| BUG-08 | Burn/Bleed DoT inconsistencia Shadow Mark | BAJA | MEDIA | BAJO | Status Effects |

---

## Notas Adicionales

### Fusion Synergy Tags (Informativo, no bug)
`WeaponFusionManager.get_synergy_effects()` retorna tags descriptivos (ej: "orbit", "homing", "freeze_aura") que son **puramente cosméticos/UI**. No hay código que aplique estos efectos mecánicamente a las armas fusionadas. Las armas fusionadas obtienen sus stats de `_calculate_dynamic_stats()` y su comportamiento del arma base definida en WeaponDatabase. Esto puede ser intencional (las sinergias son solo flavour text), pero si se esperaba que las sinergias otorguen efectos especiales, faltaría implementación.

### Arquitectura v3.0 — Fuente de Verdad Dual
La raíz de BUG-06 y BUG-07 es que PlayerStats todavía contiene WEAPON_STATS en su `BASE_STATS` (`damage_mult`, `attack_speed_mult`, etc.) desde la arquitectura legacy. Aunque la v3.0 establece que estas stats "solo viven en GlobalWeaponStats", subsistemas como Growth y Turret Mode aún las modifican en PlayerStats sin que lleguen a GlobalWeaponStats.
