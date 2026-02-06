# FASE 1 - REBALANCE PROPOSAL: Loopialike
## Lead Systems Designer + Gameplay Balance Engineer Analysis

---

# A) MAPA DE RUPTURA (Top 10)

## 1. 🔴 damage_mult SIN CAP
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | Upgrades de daño stacking: damage_1 (+10%), damage_2 (+20%), damage_3 (+35%), damage_4 (+50%), más multiplicadores de personaje y condicionales |
| **Por qué rompe** | `damage_mult` no tiene cap en STAT_LIMITS. Comentario explícito: "SIN CAP - el daño puede crecer infinitamente". Con 10+ stacks → 5x+ daño base |
| **Minuto que rompe** | Min 8-12 (mid-game, ~Level 15+) |
| **Métricas** | DPS = base × 5.0+ × crit × conditionals. One-shot elites en min 15 |

## 2. 🔴 Fusion Power Spike 4x+
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | Dos armas nivel 8 fusionadas (`WeaponFusionManager._calculate_dynamic_stats`) |
| **Por qué rompe** | `damage = (A + B) × 2.0`, `cooldown = avg × 0.5`, `projectile_count = (A + B) × 2`. Matemáticamente: 4x DPS mínimo, hasta 8x+ con sinergias |
| **Minuto que rompe** | Min 12-15 (primera fusión posible) |
| **Métricas** | Pre-fusion: 500 DPS → Post-fusion: 2000-4000 DPS |

## 3. 🔴 Defensive Stacking Immortality
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | dodge_chance 75% + damage_taken_mult 0.1 + armor + shield + life_steal 30% + regen |
| **Por qué rompe** | Capas multiplicativas: 75% esquiva × 90% DR × armor reduce = ~99.5% daño evitado. Shield regenera, life steal sana, regen constante |
| **Minuto que rompe** | Min 15-17 (con build enfocado en defensa) |
| **Métricas** | EHP efectivo: Infinito. Daño efectivo recibido/s: 0-2 vs sustain de 15+ HP/s |

## 4. 🟠 Life Steal + Kill Heal Stack
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | `life_steal` 30% cap + `kill_heal` (hasta +20 HP/kill con max stacks) |
| **Por qué rompe** | En oleadas densas (20+ kills/min), kill_heal = 400+ HP/min. Life steal con 2000 DPS = 600 HP/min. Total: 1000+ HP/min sustain |
| **Minuto que rompe** | Min 10+ |
| **Métricas** | Sustain/s: 15-25 HP/s en combate activo vs daño recibido de 5-10/s |

## 5. 🟠 I-Frames + Shotgun Prevention Stack
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | I-frames dinámicos (0.5s base + 0.15s density) + Anti-shotgun (25% daño secundario) |
| **Por qué rompe** | Con densidad alta: 0.65s inmune cada hit. En swarms, solo 1 hit real por ~0.7s window. Combinado con dodge = rarísimo recibir daño |
| **Minuto que rompe** | Min 12+ (swarm phases) |
| **Métricas** | Hits efectivos/segundo: 0.5-1.5 vs teóricos 5-10 |

## 6. 🟠 Execute Threshold Trivializa
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | `execute_threshold` hasta 70% en STAT_LIMITS |
| **Por qué rompe** | Enemigos mueren automáticamente al 70% HP. Reduce TTK a ~30% del esperado |
| **Minuto que rompe** | Min 8+ con upgrades de execute |
| **Métricas** | TTK reducido 50-70% |

## 7. 🟡 XP Streak Multiplier Snowball
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | `streak_multiplier = pow(1.05, streak-1)` con cap 10x en ExperienceManager |
| **Por qué rompe** | Streak de 20 monedas = 2.5x valor. Con pickup masivo = niveles muy rápidos en early |
| **Minuto que rompe** | Min 5-8 (snowball de XP) |
| **Métricas** | Coins efectivos: 2-3x del valor base con streaks |

## 8. 🟡 Conditional Damage Stacking
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | Brawler (+30% near) + Executioner (+50% low HP) + damage_vs_slowed (+200%) + damage_vs_frozen (+300%) |
| **Por qué rompe** | Multiplicadores son ADITIVOS primero, luego multiplicativos. Enemigo slowed + frozen + low HP = (1 + 2.0 + 3.0 + 0.5) × base = 7.5x |
| **Minuto que rompe** | Min 10+ con status + conditional builds |
| **Métricas** | Damage final = base × 7.5 × damage_mult × crit |

## 9. 🟡 Crit + Attack Speed Cap Too High
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | `crit_chance` cap 100% + `attack_speed_mult` cap 3.0x |
| **Por qué rompe** | 100% crit + 2.0x crit_damage = siempre 2x daño. 3x attack speed = 3x DPS. Combined = 6x DPS base |
| **Minuto que rompe** | Min 12+ |
| **Métricas** | DPS multiplicador de crit+speed: 4-6x |

## 10. 🟡 Shield Regen Delay Reduction
| Aspecto | Detalle |
|---------|---------|
| **Qué lo activa** | `shield_regen_delay` base 3s, reducible con upgrades (-0.5s/-1s) hasta ~0s |
| **Por qué rompe** | Con delay 0-1s y regen 20+/s (max stacks shield), el escudo regenera entre cada hit |
| **Minuto que rompe** | Min 12+ |
| **Métricas** | Shield uptime: 80-95% |

---

# B) ANÁLISIS NUMÉRICO

## DPS Efectivo por Build (Estimaciones)

| Build | Early (Min 5) | Mid (Min 12) | Late (Min 18) | Post-Fusion |
|-------|--------------|--------------|---------------|-------------|
| **Balanced** | 80-120 | 300-500 | 800-1200 | 2000-3000 |
| **Glass Cannon** | 150-200 | 600-1000 | 1500-2500 | 4000-6000 |
| **Tank** | 50-80 | 200-300 | 400-600 | 1000-1500 |
| **Status Focus** | 60-100 | 400-700 (con condicionales) | 1000-1800 | 3000-5000 |
| **Orbital** | 100-150 | 500-800 | 1200-1800 | 2500-4000 |

### Fórmula DPS:
```
DPS = (base_damage × damage_mult × [1 + conditionals]) 
    × (1 + crit_chance × (crit_damage - 1)) 
    × attack_speed_mult 
    × projectile_count 
    / cooldown
```

## EHP Efectivo (Effective Health Points)

| Build | HP Base | Con Defensa Min 12 | Con Defensa Min 18 |
|-------|---------|-------------------|-------------------|
| **Balanced** | 100-150 | 300-500 EHP | 600-1000 EHP |
| **Glass Cannon** | 1 (is_glass_cannon) | 1-50 EHP | 1-100 EHP |
| **Tank** | 200-400 | 2000-5000 EHP | 10000+ EHP (infinito) |
| **Status Focus** | 100-150 | 400-700 EHP | 1000-1500 EHP |

### Fórmula EHP:
```
EHP = (HP + Shield) / (1 - dodge_chance) / damage_taken_mult
    + sustain_per_second × average_combat_duration
```

### EHP Tank Build (Worst Case):
- HP: 300 + Shield: 250 = 550 raw
- Dodge 75%: 550 / 0.25 = 2200 vs attacks
- DR 90%: 2200 / 0.1 = 22000 EHP
- + Regen 20/s + Life Steal 30% = **Efectivamente Inmortal**

## TTK (Time To Kill) por Tier y Fase

### Enemy HP por Tier:
| Tier | Base HP | Min 5 | Min 10 | Min 15 | Min 20 |
|------|---------|-------|--------|--------|--------|
| T1 | 20 | 20 | 26 | 34 | 44 |
| T2 | 50 | - | 65 | 85 | 110 |
| T3 | 100 | - | - | 130 | 169 |
| T4 | 180 | - | - | - | 234 |
| Elite | 300 (15x) | 300 | 390 | 507 | 660 |
| Boss | 2000 | 2000 | 2600 | 3380 | 4400 |

### TTK con DPS típico:
| Target | DPS 200 | DPS 500 | DPS 1500 | DPS 3000 |
|--------|---------|---------|----------|----------|
| T1 (20) | 0.1s | 0.04s | 0.01s | 0.01s |
| T3 (100) | 0.5s | 0.2s | 0.07s | 0.03s |
| Elite (300) | 1.5s | 0.6s | 0.2s | 0.1s |
| Boss (2000) | 10s | 4s | 1.3s | 0.7s |

**Problema**: Con fusión (3000+ DPS), bosses mueren en <1s en min 15.

## Daño Recibido vs Sustain

| Fase | Daño Enemigo/Hit | Hits/Segundo (teórico) | Daño/s Bruto | Con DR+Dodge | Sustain Típico |
|------|-----------------|----------------------|--------------|--------------|----------------|
| Min 5 | 6-10 | 2-4 | 24-40 | 8-15 | 5-10 HP/s |
| Min 10 | 10-16 | 3-6 | 40-96 | 12-30 | 10-20 HP/s |
| Min 15 | 16-25 | 4-8 | 80-200 | 20-50 | 15-30 HP/s |
| Min 20 | 25-40 | 5-10 | 150-400 | 35-80 | 20-40 HP/s |

**Problema**: Tank builds con 50+ HP/s sustain y 90%+ mitigation = inmortales.

---

# C) PROPUESTA DE CAMBIOS CON VALORES

## P0: Eliminar Inmortalidad

### C.1: damage_mult SOFT CAP
**Antes:** Sin cap (puede crecer infinitamente)
**Después:** Soft cap en 3.0x con diminishing returns

```gdscript
# PlayerStats.gd - Añadir a STAT_LIMITS
"damage_mult": {"min": 0.5, "max": 5.0, "soft_cap": 3.0, "diminishing_rate": 0.5}

# En get_stat() - aplicar diminishing:
if stat_name == "damage_mult":
    var raw = stats[stat_name]
    if raw > 3.0:
        var excess = raw - 3.0
        return 3.0 + (excess * 0.5)  # 50% eficiencia sobre el soft cap
    return raw
```

**Justificación**: 3x es suficiente para sentirse poderoso. Más allá, 50% eficiencia mantiene progresión sin romper.
**Efecto esperado**: DPS máximo reducido ~30% en late game.
**Riesgo**: Builds ofensivos pueden sentirse "capped". Mitigar con mensajes UI.

### C.2: Fusion Power Spike Reducido
**Antes:** damage × 2.0, cooldown × 0.5, projectiles × 2
**Después:** damage × 1.5, cooldown × 0.7, projectiles × 1.5 (round down)

```gdscript
# WeaponFusionManager.gd - _calculate_dynamic_stats
func _calculate_dynamic_stats(a: BaseWeapon, b: BaseWeapon) -> Dictionary:
    var stats = {}
    
    # Daño: de 2.0 a 1.5
    stats["damage"] = (a.damage + b.damage) * 1.5
    
    # Cooldown: de 0.5 a 0.7 (menos rápido)
    var avg_cd = (a.cooldown + b.cooldown) / 2.0
    stats["cooldown"] = avg_cd * 0.7
    
    # Projectiles: de 2.0 a 1.5 (floor)
    stats["projectile_count"] = int((a.projectile_count + b.projectile_count) * 1.5)
    
    # ... resto igual
```

**Justificación**: Reduce spike de 4x a ~2.3x DPS. Sigue siendo reward significativo.
**Efecto esperado**: Fusión sigue siendo deseable pero no rompe el juego.
**Riesgo**: Jugadores acostumbrados a fusión poderosa pueden quejarse.

### C.3: Defensive Stacking Diminishing Returns
**Antes:** dodge 75%, damage_taken_mult 0.1, ambos independientes
**Después:** Combined DR cap 92%, dodge funciona después de DR

```gdscript
# BasePlayer.gd - take_damage()
# Nuevo orden: Armor → DR → Dodge (no shield primero)

# CAMBIO: DR y Dodge combinados con cap
var combined_mitigation = damage_taken_mult * (1.0 - dodge_chance)
combined_mitigation = maxf(combined_mitigation, 0.08)  # Mínimo 8% daño pasa siempre

final_damage = int(amount * combined_mitigation)
final_damage = maxi(final_damage, 1)  # Mínimo 1 de daño siempre
```

```gdscript
# PlayerStats.gd - STAT_LIMITS cambios
"dodge_chance": {"min": 0.0, "max": 0.60},  # NERF: 75% → 60%
"damage_taken_mult": {"min": 0.15, "max": 3.0},  # NERF: 0.1 → 0.15
```

**Justificación**: 92% mitigation cap = siempre mueres si cometes errores. 60% dodge + 85% DR = ~94% → capped a 92% = 8% pasa.
**Efecto esperado**: Tank builds sobreviven bien pero pueden morir.
**Riesgo**: Tank fantasy reducida. Compensar con shield mejorado.

### C.4: Life Steal + Regen Hard Caps
**Antes:** life_steal 30%, regen sin cap
**Después:** life_steal 20%, regen cap 15/s

```gdscript
# GlobalWeaponStats.gd - GLOBAL_STAT_LIMITS
"life_steal": {"min": 0.0, "max": 0.20},  # NERF: 30% → 20%

# PlayerStats.gd - STAT_LIMITS (añadir)
"health_regen": {"min": 0.0, "max": 15.0},  # NEW CAP: 15/s
```

**Justificación**: 20% life steal con 2000 DPS = 400 HP/min = 6.6 HP/s. Con 15 regen cap = 21.6 HP/s max sustain (manejable).
**Efecto esperado**: Sustain suficiente para sobrevivir, no para ser inmortal.

### C.5: I-Frame Base Reducido
**Antes:** 0.5s base + 0.15s density bonus
**Después:** 0.3s base + 0.1s density bonus (max 0.05s per enemy, up to 2)

```gdscript
# BasePlayer.gd - _apply_dynamic_iframes
func _apply_dynamic_iframes() -> void:
    var base_iframe = 0.3  # NERF: 0.5 → 0.3
    
    var density = _get_enemy_density()
    var density_bonus = minf(float(density) * 0.05, 0.1)  # NERF: 0.02→0.05, max 0.15→0.1
    
    _invulnerability_timer = base_iframe + density_bonus
```

**Justificación**: 0.4s max i-frames mantiene protección anti-shotgun sin inmunidad extendida.
**Efecto esperado**: Más hits efectivos, más presión.

## P1: Eliminar DPS Infinito/One-Shot

### C.6: Execute Threshold Cap Reducido
**Antes:** execute_threshold max 70%
**Después:** max 25%

```gdscript
# PlayerStats.gd - STAT_LIMITS
"execute_threshold": {"min": 0.0, "max": 0.25},  # NERF: 70% → 25%
```

**Justificación**: 25% execute = último cuarto gratis, no "70% del trabajo evitado".
**Efecto esperado**: Execute sigue siendo útil clutch, no trivializa.

### C.7: Conditional Damage Caps
**Antes:** damage_vs_slowed 200%, damage_vs_frozen 300%
**Después:** Ambos max 100%

```gdscript
# PlayerStats.gd - STAT_LIMITS
"damage_vs_slowed": {"min": 0.0, "max": 1.0},   # NERF: 200% → 100%
"damage_vs_burning": {"min": 0.0, "max": 1.0}, # NERF: 200% → 100%
"damage_vs_frozen": {"min": 0.0, "max": 1.0},  # NERF: 300% → 100%
```

**Justificación**: 100% bonus es significativo. 200-300% era excesivo.
**Efecto esperado**: Builds de status siguen siendo buenos, no dominantes.

### C.8: Crit Chance Cap Reducido
**Antes:** crit_chance max 100%
**Después:** max 75%

```gdscript
# PlayerStats.gd & GlobalWeaponStats.gd - STAT_LIMITS
"crit_chance": {"min": 0.0, "max": 0.75},  # NERF: 100% → 75%
```

**Justificación**: 75% crit = muy consistente pero no garantizado.
**Efecto esperado**: Varianza en daño mantiene engagement.

## P2: Ajustar Economía/Snowball

### C.9: XP Streak Cap Reducido
**Antes:** streak multiplier cap 10x
**Después:** cap 3x, formula más suave

```gdscript
# ExperienceManager.gd - _on_coin_collected
var streak_bonus_per = 0.03  # NERF: 0.05 → 0.03
# ...
streak_multiplier = minf(streak_multiplier, 3.0)  # NERF: 10.0 → 3.0
```

**Justificación**: 3x max mantiene reward por streaks sin snowball.
**Efecto esperado**: Progresión más lineal, menos spikes.

### C.10: Reroll Cost Aumentado Progresivamente
**Antes:** Rerolls gratis (solo limitados por count)
**Después:** Cada reroll cuesta 10 × nivel de monedas

```gdscript
# LevelUpPanel.gd - _do_reroll
func _do_reroll() -> void:
    var reroll_cost = player_stats.level * 10
    var exp_manager = get_tree().get_first_node_in_group("experience_manager")
    
    if exp_manager and exp_manager.total_coins >= reroll_cost:
        exp_manager.spend_coins(reroll_cost)
        # ... resto de lógica
    else:
        # No puede pagar, mostrar mensaje
        _show_insufficient_coins()
```

**Justificación**: Rerolls tienen costo real, evita buscar la build perfecta gratis.
**Efecto esperado**: Decisiones más significativas en level up.

## P3: Ajustar Escalado Enemigo

### C.11: Elite Config Buff
**Antes:** Elite HP 15x, damage 4x
**Después:** Elite HP 20x, damage 5x, ability_use_chance 80%

```gdscript
# EnemyDatabase.gd - ELITE_CONFIG
const ELITE_CONFIG = {
    "hp_multiplier": 20.0,          # BUFF: 15 → 20
    "damage_multiplier": 5.0,       # BUFF: 4 → 5
    "ability_use_chance": 0.80,     # BUFF: 70% → 80%
    # ... resto igual
}
```

**Justificación**: Elites deben ser amenaza real incluso con DPS nerfeado.
**Efecto esperado**: Elites requieren atención, no son "normal+ enemies".

### C.12: Boss HP Scaling Buff
**Antes:** Boss tier 5 HP mult 1.0 (mismo que T1), XP 3.0
**Después:** HP 25.0, XP 10.0

```gdscript
# EnemyDatabase.gd - TIER_SCALING
5: {"hp": 25.0, "damage": 8.0, "speed": 1.0, "xp": 10.0}  # BOSS TIER BUFFED
```

**Justificación**: Bosses deben ser eventos significativos, no speed bumps.
**Efecto esperado**: Boss fights duran 15-30s en late game.

### C.13: DifficultyManager Scaling Buff
**Antes:** damage +3%/min, health +4%/min
**Después:** damage +5%/min, health +6%/min

```gdscript
# DifficultyManager.gd
var damage_increase_per_minute: float = 0.05  # BUFF: 0.03 → 0.05
var health_increase_per_minute: float = 0.06  # BUFF: 0.04 → 0.06
```

**Justificación**: Compensar nerfs al jugador con enemigos más escalados.
**Efecto esperado**: Late game sigue siendo challenge.

---

# D) PATCH NOTES TÉCNICO

## Player/Sustain
| Cambio | Archivo | Línea/Constante | Antes | Después |
|--------|---------|-----------------|-------|---------|
| dodge_chance cap | PlayerStats.gd | STAT_LIMITS["dodge_chance"] | 0.75 | 0.60 |
| damage_taken_mult floor | PlayerStats.gd | STAT_LIMITS["damage_taken_mult"] | 0.1 | 0.15 |
| life_steal cap | GlobalWeaponStats.gd | GLOBAL_STAT_LIMITS["life_steal"] | 0.30 | 0.20 |
| health_regen cap | PlayerStats.gd | STAT_LIMITS (nuevo) | N/A | 15.0 |
| I-frame base | BasePlayer.gd | _apply_dynamic_iframes | 0.5s | 0.3s |
| I-frame density bonus | BasePlayer.gd | _apply_dynamic_iframes | 0.15s max | 0.1s max |
| Minimum damage through | BasePlayer.gd | take_damage | 0 | 1 (siempre) |
| Combined DR cap | BasePlayer.gd | take_damage | N/A | 92% max mitigation |

## Damage/Weapons
| Cambio | Archivo | Línea/Constante | Antes | Después |
|--------|---------|-----------------|-------|---------|
| damage_mult soft cap | PlayerStats.gd | STAT_LIMITS (nuevo) | ∞ | 3.0 soft, 5.0 hard |
| damage_mult diminishing | PlayerStats.gd | get_stat() | N/A | 50% efficiency over 3.0 |
| Fusion damage mult | WeaponFusionManager.gd | _calculate_dynamic_stats | 2.0 | 1.5 |
| Fusion cooldown mult | WeaponFusionManager.gd | _calculate_dynamic_stats | 0.5 | 0.7 |
| Fusion projectile mult | WeaponFusionManager.gd | _calculate_dynamic_stats | 2.0 | 1.5 |
| execute_threshold cap | PlayerStats.gd | STAT_LIMITS | 0.70 | 0.25 |
| damage_vs_slowed cap | PlayerStats.gd | STAT_LIMITS | 2.0 | 1.0 |
| damage_vs_burning cap | PlayerStats.gd | STAT_LIMITS | 2.0 | 1.0 |
| damage_vs_frozen cap | PlayerStats.gd | STAT_LIMITS | 3.0 | 1.0 |
| crit_chance cap | PlayerStats.gd, GlobalWeaponStats.gd | STAT_LIMITS | 1.0 | 0.75 |

## Economy/RNG
| Cambio | Archivo | Línea/Constante | Antes | Después |
|--------|---------|-----------------|-------|---------|
| Streak bonus per coin | ExperienceManager.gd | _on_coin_collected | 0.05 | 0.03 |
| Streak multiplier cap | ExperienceManager.gd | _on_coin_collected | 10.0 | 3.0 |
| Reroll cost | LevelUpPanel.gd | _do_reroll | Free | level × 10 coins |

## Enemies/Difficulty
| Cambio | Archivo | Línea/Constante | Antes | Después |
|--------|---------|-----------------|-------|---------|
| Elite HP mult | EnemyDatabase.gd | ELITE_CONFIG | 15.0 | 20.0 |
| Elite damage mult | EnemyDatabase.gd | ELITE_CONFIG | 4.0 | 5.0 |
| Elite ability chance | EnemyDatabase.gd | ELITE_CONFIG | 0.70 | 0.80 |
| Boss tier HP | EnemyDatabase.gd | TIER_SCALING[5] | 1.0 | 25.0 |
| Boss tier damage | EnemyDatabase.gd | TIER_SCALING[5] | 1.0 | 8.0 |
| Boss tier XP | EnemyDatabase.gd | TIER_SCALING[5] | 3.0 | 10.0 |
| Damage/min scaling | DifficultyManager.gd | damage_increase_per_minute | 0.03 | 0.05 |
| Health/min scaling | DifficultyManager.gd | health_increase_per_minute | 0.04 | 0.06 |

---

# E) PLAN DE VALIDACIÓN

## Escenarios de Test Manual

### 1. Build Rota Actual: "Tank Vampírico"
**Setup**: Rogue + dodge stacking + lifesteal max + shield build
**Pre-cambios**: Inmortal en min 15+
**Post-cambios esperados**: 
- Muere a boss min 15 si no tiene cuidado
- Sobrevive min 12 elites con esfuerzo
- No puede AFK en swarms min 17+

**Criterio éxito**: ≥3 muertes en 10 runs de 20 min con este build

### 2. Build Rota Actual: "Glass Cannon Fusion"
**Setup**: Mage + damage stacking + early fusion + glass_cannon
**Pre-cambios**: One-shot bosses min 15, muere a 1 error
**Post-cambios esperados**:
- Boss min 15 toma 8-15s (no instant)
- Sigue siendo viable con skill
- Elite min 12 no es instant kill

**Criterio éxito**: Boss fights ≥10s promedio

### 3. Build Promedio: "Balanced Mage"
**Setup**: Frost Mage + mix offense/defense + 1-2 fusions
**Pre-cambios**: Cómodo pero puede morir ocasionalmente
**Post-cambios esperados**:
- Similar dificultad
- Fusions se sienten reward (pero no broken)
- Late game (min 18+) desafiante pero winnable

**Criterio éxito**: 40-60% winrate en runs de 20 min

### 4. Build Promedio: "AoE Cleric"
**Setup**: Priest + regen focus + AoE weapons
**Pre-cambios**: Sustain alto, clear speed medio
**Post-cambios esperados**:
- Regen capped se nota pero no destruye el build
- Necesita jugar más activamente
- Sigue siendo identity "sustain"

**Criterio éxito**: Build sigue siendo top 5 más jugado

### 5. Build Débil: "Pure Melee Tank"
**Setup**: Paladin + armor stacking + melee weapons
**Pre-cambios**: Lucha en late game, clear lento
**Post-cambios esperados**:
- Armor reduction menos penalizado (enemies do more = armor scales better)
- Elite/Boss focus viable con elite_damage_mult

**Criterio éxito**: Mejora de 1-2 minutos en tiempo promedio de muerte

### 6. Build Débil: "Status Debuffer"
**Setup**: Necromancer + status effects + low direct damage
**Pre-cambios**: Dependiente de condicionales altos
**Post-cambios esperados**:
- Condicionales más bajos pero más consistentes
- Base damage de enemies buffado = más oportunidades de aplicar status

**Criterio éxito**: No empeora significativamente (±10% performance)

## Métricas de Éxito Globales

| Métrica | Actual (Estimado) | Target Post-Balance |
|---------|-------------------|---------------------|
| % Runs con "inmortalidad" (0 muertes min 20+) | 30-40% | <10% |
| TTK Boss min 15 | 1-3s | 10-20s |
| Sustain máximo posible (HP/s) | 40-60 | 15-25 |
| Damage mult máximo efectivo | 8-12x | 3-4x |
| Fusion DPS spike | 4-6x | 2-2.5x |
| Winrate build promedio min 20 | 60-70% | 40-50% |
| Diversidad de builds viables | 3-4 meta | 6-8 viables |

## Timeline de Implementación Sugerido

1. **Semana 1**: Implementar cambios P0 (defensivos) - Hotfix urgente
2. **Semana 2**: Implementar cambios P1 (daño) - Balancing pass
3. **Semana 3**: Implementar cambios P2+P3 (economía + enemigos) - Full patch
4. **Semana 4**: Monitoring + hotfixes según telemetría

---

## NOTAS FINALES

### Filosofía de Balance
- **Builds poderosos**: SÍ, pero con trade-offs claros
- **Inmortalidad**: NO bajo ninguna combinación
- **One-shot trivial**: NO en mid-game
- **Fusion**: Reward, no requirement
- **Late game**: Siempre presión, muerte posible

### Bugs Lógicos Detectados
1. **dodge_chance inconsistencia**: STAT_LIMITS dice 75%, código en take_damage dice 60%. Unificar a 60%.
2. **shield absorbe antes de dodge**: Orden incorrecto (gasta shield incluso si habría esquivado). Fix: Dodge primero.

### Próximos Pasos Post-Balance
1. Añadir telemetría de muertes/builds
2. Implementar "modo difícil" con caps más estrictos
3. Revisar personajes individuales para pasivas únicas
