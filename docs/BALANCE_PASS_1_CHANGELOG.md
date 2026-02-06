# Balance Pass 1 - Changelog Detallado

**Fecha:** 6 de febrero de 2026  
**Rama:** `main` (mergeado desde `balance-pass-1`)  
**Objetivo:** Eliminar builds "inmortales" y one-shots triviales, mantener el juego divertido con builds poderosos pero no infinitos.

---

## Índice

1. [Sistema de Debug](#1-sistema-de-debug)
2. [Cambios de Sustain/Defensa](#2-cambios-de-sustaindefensa)
3. [Cambios de Daño](#3-cambios-de-daño)
4. [Cambios de Economía](#4-cambios-de-economía)
5. [Cambios de Enemigos/Dificultad](#5-cambios-de-enemigosdificultad)
6. [Archivos Modificados](#6-archivos-modificados)
7. [Notas de Validación](#7-notas-de-validación)

---

## 1. Sistema de Debug

### Nuevos Archivos

#### `BalanceDebugger.gd` (Autoload)
Sistema de tracking de métricas de balance durante gameplay.

**Funcionalidad:**
- Trackea daño infligido por el jugador (min/avg/max, DPS total)
- Trackea mitigación efectiva (dodges, shield absorbed, armor reduced)
- Trackea sustain por segundo (regen, lifesteal, kill heal)
- Trackea TTK (Time To Kill) de elites y bosses
- Toggle con tecla **F10**
- Al desactivar, imprime resumen completo de la sesión

**Métricas disponibles:**
```gdscript
{
    "damage_dealt": { "min", "max", "avg", "total", "dps" },
    "mitigation": { "dodges", "shield_absorbed", "armor_reduced", "damage_raw", "damage_final", "mitigation_pct" },
    "sustain": { "regen", "lifesteal", "kill_heal", "total", "per_sec" },
    "ttk": { "elite_avg", "elite_samples", "boss_avg", "boss_samples" },
    "elapsed_sec": float
}
```

#### `BalanceDebugOverlay.gd` (Autoload)
Overlay visual que muestra las métricas en tiempo real.

**Funcionalidad:**
- Panel semi-transparente en esquina superior izquierda
- Se actualiza cada 0.5 segundos
- Muestra: DPS, mitigación %, sustain HP/s, TTK elites/bosses
- Mismo toggle con **F10**

**Hooks añadidos en:**
- `BasePlayer.gd`: Log de dodge y daño recibido
- `DamageCalculator.gd`: Log de daño infligido
- `ProjectileFactory.gd`: Log de life steal heal
- `PlayerStats.gd`: Log de health regen
- `EnemyManager.gd`: Log de elite/boss spawn y death para TTK

---

## 2. Cambios de Sustain/Defensa

### 2.1 Dodge Chance Cap Unificado

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `PlayerStats.gd`, `BasePlayer.gd` | `PlayerStats.gd` (único lugar) |
| **Cap en STAT_LIMITS** | 75% | **60%** |
| **Cap hardcoded en take_damage** | 60% (minf) | Eliminado (usa STAT_LIMITS) |

**Por qué:**
- Había inconsistencia: STAT_LIMITS decía 75%, pero take_damage hacía `minf(dodge, 0.6)`
- Unificado a 60% en un solo lugar para evitar confusión
- 60% dodge es suficiente para sentirse evasivo sin ser inmune

**Código cambiado:**
```gdscript
# PlayerStats.gd - STAT_LIMITS
"dodge_chance": {"min": 0.0, "max": 0.60},  # Era 0.75

# BasePlayer.gd - take_damage
if dodge_chance > 0 and randf() < dodge_chance:  # Era minf(dodge_chance, 0.6)
```

---

### 2.2 Life Steal Cap Reducido

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `GlobalWeaponStats.gd` | `GlobalWeaponStats.gd` |
| **Cap** | 30% | **20%** |

**Por qué:**
- 30% life steal con 2000+ DPS = 600+ HP/min = 10 HP/s constante
- Combinado con otros sustain, hacía al jugador inmortal
- 20% mantiene la fantasía de vampirismo sin trivializar

**Código cambiado:**
```gdscript
# GlobalWeaponStats.gd - GLOBAL_STAT_LIMITS
"life_steal": {"min": 0.0, "max": 0.2},  # Era 0.3
```

---

### 2.3 Health Regen Cap (NUEVO)

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `PlayerStats.gd` | `PlayerStats.gd` |
| **Cap** | Sin límite (∞) | **15 HP/s** |

**Por qué:**
- Con múltiples upgrades de regen (1 + 2.5 + 3 + 5 = 11.5/s base), más multiplicadores, podía llegar a 30+ HP/s
- Esto compensaba casi cualquier daño recibido
- 15 HP/s es suficiente para recuperarse entre combates, no para ignorar el daño

**Código cambiado:**
```gdscript
# PlayerStats.gd - STAT_LIMITS (nuevo entry)
"health_regen": {"min": 0.0, "max": 15.0},
```

---

### 2.4 Shield Regen Delay Mínimo (NUEVO)

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `PlayerStats.gd` | `PlayerStats.gd` |
| **Mínimo** | 0s (podía llegar con upgrades) | **1.0s** |

**Por qué:**
- Con upgrades de reducción de delay (-0.5s, -1.0s), podía llegar a 0s
- Delay 0s = escudo regenera instantáneamente entre hits = escudo infinito
- 1s mínimo asegura ventana de vulnerabilidad

**Código cambiado:**
```gdscript
# PlayerStats.gd - STAT_LIMITS (nuevo entry)
"shield_regen_delay": {"min": 1.0, "max": 10.0},
```

---

### 2.5 I-Frames Reducidos

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `BasePlayer.gd` | `BasePlayer.gd` |
| **Base** | 0.5s | **0.4s** |
| **Density bonus max** | 0.15s | **0.10s** |
| **Total máximo** | 0.65s | **0.50s** |

**Por qué:**
- I-frames largos + sistema anti-shotgun = muy pocos hits efectivos/segundo
- Con 0.65s de i-frames en hordas densas, el jugador era casi invulnerable
- 0.50s máximo mantiene fairness en hordas sin protección excesiva

**Código cambiado:**
```gdscript
# BasePlayer.gd - _apply_dynamic_iframes
var base_iframe = 0.4  # Era 0.5
var density_bonus = minf(float(density) * 0.02, 0.10)  # Era 0.15
```

---

## 3. Cambios de Daño

### 3.1 Damage Mult Soft-Cap (NUEVO)

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `PlayerStats.gd` | `PlayerStats.gd` |
| **Cap** | Sin límite (∞) | **Soft 3.0x, Hard 5.0x** |
| **Eficiencia sobre soft cap** | N/A | **50%** |

**Por qué:**
- Comentario explícito en código: "damage_mult: SIN CAP - el daño puede crecer infinitamente"
- Con 10+ stacks de upgrades de daño, podía llegar a 8x+ sin esfuerzo
- Soft cap permite seguir creciendo pero con rendimientos decrecientes

**Ejemplo de cálculo:**
- Raw 4.0x → Efectivo: 3.0 + (1.0 × 0.5) = **3.5x**
- Raw 5.0x → Efectivo: 3.0 + (2.0 × 0.5) = **4.0x**
- Raw 7.0x → Efectivo: 3.0 + (4.0 × 0.5) = **5.0x** (hard cap)

**Código cambiado:**
```gdscript
# PlayerStats.gd - get_stat()
if stat_name == "damage_mult":
    const DAMAGE_SOFT_CAP: float = 3.0
    const DAMAGE_HARD_CAP: float = 5.0
    const DIMINISHING_RATE: float = 0.5
    
    if final_value > DAMAGE_SOFT_CAP:
        var excess = final_value - DAMAGE_SOFT_CAP
        final_value = DAMAGE_SOFT_CAP + (excess * DIMINISHING_RATE)
        final_value = minf(final_value, DAMAGE_HARD_CAP)
```

---

### 3.2 Fusion Power Spike Reducido

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `WeaponFusionManager.gd` | `WeaponFusionManager.gd` |
| **Damage mult** | 2.0x | **1.5x** |
| **Cooldown mult** | 0.5x (el doble de rápido) | **0.7x** |
| **Projectile mult** | 2.0x | **1.5x (cap 8)** |
| **Pierce cap** | 20 | **15** |
| **DPS spike aproximado** | ~4-6x | **~2.2-2.5x** |

**Por qué:**
- Fusionar dos armas lvl 8 daba: (damage×2) × (1/cooldown×2) × (projectiles×2) = **8x DPS mínimo**
- Esto trivializaba el late game inmediatamente después de la primera fusión
- 2.2x spike sigue siendo muy rewarding pero no rompe el juego

**Código cambiado:**
```gdscript
# WeaponFusionManager.gd - _calculate_dynamic_stats
stats["damage"] = (a.damage + b.damage) * 1.5        # Era 2.0
stats["cooldown"] = avg_cd * 0.7                     # Era 0.5
var raw_proj = int((a.projectile_count + b.projectile_count) * 1.5)  # Era 2.0
stats["projectile_count"] = mini(raw_proj, 8)        # Cap nuevo
stats["pierce"] = min((a.pierce + b.pierce) * 2, 15) # Era 20
```

---

### 3.3 Execute Threshold Reducido

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `PlayerStats.gd` | `PlayerStats.gd` |
| **Cap** | 70% | **40%** |

**Por qué:**
- 70% execute = enemigos mueren automáticamente cuando les queda 70% de vida
- Esto reducía el TTK efectivo un ~70% (solo necesitabas hacer 30% de daño)
- 40% sigue siendo útil pero no trivializa tanto

**Código cambiado:**
```gdscript
# PlayerStats.gd - STAT_LIMITS
"execute_threshold": {"min": 0.0, "max": 0.40},  # Era 0.70
```

---

### 3.4 Conditional Damage Caps Reducidos

| Stat | Antes | Después |
|------|-------|---------|
| `damage_vs_slowed` | 200% | **100%** |
| `damage_vs_burning` | 200% | **100%** |
| `damage_vs_frozen` | 300% | **100%** |

**Por qué:**
- Con múltiples conditionals activos: base × (1 + 2.0 + 2.0 + 3.0) = **8x daño**
- Combinado con status effects fáciles de aplicar, era un multiplicador trivial
- 100% cada uno sigue siendo significativo pero controlado

**Código cambiado:**
```gdscript
# PlayerStats.gd - STAT_LIMITS
"damage_vs_slowed": {"min": 0.0, "max": 1.0},   # Era 2.0
"damage_vs_burning": {"min": 0.0, "max": 1.0},  # Era 2.0
"damage_vs_frozen": {"min": 0.0, "max": 1.0},   # Era 3.0
```

---

## 4. Cambios de Economía

### 4.1 Streak Multiplier Reducido

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `ExperienceManager.gd` | `ExperienceManager.gd` |
| **Bonus por coin** | 5% | **3%** |
| **Cap** | 10x | **3x** |

**Nuevo comportamiento:**
- Streak 5: 1.03^4 ≈ **1.13x** (+13%) - Era 1.22x
- Streak 10: 1.03^9 ≈ **1.30x** (+30%) - Era 1.55x
- Streak 20: 1.03^19 ≈ **1.75x** (+75%) - Era 2.53x

**Por qué:**
- Streak de 10x permitía snowball masivo en early game
- Un pickup de 20 monedas en streak podía dar 2.5x el valor normal
- Esto aceleraba la progresión de manera no lineal y desbalanceada

**Código cambiado:**
```gdscript
# ExperienceManager.gd - _on_coin_collected
var streak_bonus_per = 0.03  # Era 0.05
streak_multiplier = minf(streak_multiplier, 3.0)  # Era 10.0
```

---

### 4.2 Rerolls con Coste Progresivo (NUEVO)

| Reroll # | Coste |
|----------|-------|
| 1er | **Gratis** |
| 2do | **15 coins** |
| 3er | **30 coins** |
| 4to | **45 coins** |
| ... | +15 cada uno |

**Por qué:**
- Rerolls infinitos gratis permitían buscar la build perfecta sin coste
- Ahora hay decisión económica: ¿vale la pena gastar coins en reroll?
- El primer reroll sigue gratis para no frustrar

**Variables añadidas:**
```gdscript
# LevelUpPanel.gd
var rerolls_used_this_level: int = 0
const REROLL_BASE_COST: int = 0
const REROLL_COST_STEP: int = 15
```

**UI actualizado:**
- El botón de reroll ahora muestra el coste: `(3) 🪙15`
- Si no hay suficientes coins, muestra mensaje "Need X coins!"

---

## 5. Cambios de Enemigos/Dificultad

### 5.1 Elites Buffed

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `EnemyDatabase.gd` | `EnemyDatabase.gd` |
| **HP Multiplier** | 15x | **18x** |
| **Damage Multiplier** | 4x | **4.5x** |

**Por qué:**
- Con los nerfs al jugador, los elites serían demasiado fáciles
- Buff compensatorio para mantener la amenaza
- Elites deben requerir atención y no ser "speedbumps"

**Código cambiado:**
```gdscript
# EnemyDatabase.gd - ELITE_CONFIG
"hp_multiplier": 18.0,      # Era 15.0
"damage_multiplier": 4.5,   # Era 4.0
```

---

### 5.2 Difficulty Scaling Buffed

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivo** | `DifficultyManager.gd` | `DifficultyManager.gd` |
| **Damage per minute** | 3% | **4%** |
| **Health per minute** | 4% | **5%** |

**Efecto en min 20:**
- Antes: Damage ×1.60, Health ×1.80
- Después: Damage ×1.80, Health ×2.00

**Por qué:**
- Compensar los nerfs al jugador con enemigos más escalados
- Mantener la presión en late game
- El juego no debería volverse trivial después de cierto punto

**Código cambiado:**
```gdscript
# DifficultyManager.gd
var damage_increase_per_minute: float = 0.04  # Era 0.03
var health_increase_per_minute: float = 0.05  # Era 0.04
```

---

## 6. Archivos Modificados

| Archivo | Tipo | Cambios |
|---------|------|---------|
| `scripts/debug/BalanceDebugger.gd` | **Nuevo** | Sistema de tracking |
| `scripts/debug/BalanceDebugOverlay.gd` | **Nuevo** | UI de debug |
| `project.godot` | Modificado | Añadidos autoloads |
| `scripts/core/PlayerStats.gd` | Modificado | STAT_LIMITS, soft-cap damage_mult |
| `scripts/core/GlobalWeaponStats.gd` | Modificado | life_steal cap |
| `scripts/entities/players/BasePlayer.gd` | Modificado | dodge, i-frames, hooks debug |
| `scripts/weapons/WeaponFusionManager.gd` | Modificado | Fusion stats |
| `scripts/weapons/projectiles/DamageCalculator.gd` | Modificado | Hook debug |
| `scripts/weapons/ProjectileFactory.gd` | Modificado | Hook debug |
| `scripts/core/ExperienceManager.gd` | Modificado | Streak |
| `scripts/ui/LevelUpPanel.gd` | Modificado | Reroll cost |
| `scripts/data/EnemyDatabase.gd` | Modificado | Elite config |
| `scripts/core/DifficultyManager.gd` | Modificado | Scaling |
| `scripts/core/EnemyManager.gd` | Modificado | Hooks debug |

---

## 7. Notas de Validación

### Tests Recomendados

#### Build "Tank Vampírico" (Rogue + dodge + lifesteal + shield)
- **Esperado antes:** Inmortal en min 15+
- **Esperado después:** Muere a boss min 15 si no tiene cuidado, no puede AFK

#### Build "Glass Cannon Fusion" (Mage + damage + fusion + glass_cannon)
- **Esperado antes:** One-shot bosses en min 15
- **Esperado después:** Boss min 15 toma 10-20s

#### Build Promedio (cualquier clase, mix offense/defense)
- **Esperado winrate min 20:** 40-55% (era 60-70%)

### Métricas a Observar (F10)

| Métrica | Antes (estimado) | Target |
|---------|------------------|--------|
| Sustain max (HP/s) | 40-60 | 15-25 |
| DPS max post-fusion | 4000-6000 | 2000-2500 |
| Mitigation % (tank) | 95%+ | 85-92% |
| Elite TTK min 12 | <1s | 3-8s |
| Boss TTK min 15 | 1-3s | 10-20s |

---

## Notas Adicionales

### Lo que NO se tocó (para iteraciones futuras)

1. **Boss Tier Scaling** - El tier 5 tiene valores bajos (1.0x) que requieren investigación
2. **Crit Chance Cap** - Sigue en 100%, podría bajarse a 75-85%
3. **Attack Speed Cap** - Sigue en 3.0x, evaluación pendiente
4. **Personajes individuales** - Pasivas no fueron ajustadas
5. **Armas individuales** - Stats base no modificados

### Filosofía de Balance Aplicada

- ✅ Builds poderosos: SÍ, pero con trade-offs claros
- ✅ Inmortalidad: NO bajo ninguna combinación
- ✅ One-shot trivial: NO en mid-game
- ✅ Fusión: Reward significativo, no requisito
- ✅ Late game: Siempre presión, muerte posible
